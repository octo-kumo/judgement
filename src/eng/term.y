
import gui;

const TCGETS = 0x5401;
const TCSETS = 0x5402;
const TIOCGWINSZ = 0x5413;

const LFLAG_RAW = 1 | 2 | 8 | 16 | 64 | 32768;

const IFLAG_RAW = 2 | 16 | 32 | 256 | 1024;

let TM: [byte; 64] = [0; 64];
let SAVED: [byte; 64] = [0; 64];
let WS: [byte; 16] = [0; 16];
let PIPE_BUF: [byte; 8] = [0; 8];
let ONE: [byte; 1] = [0; 1];
let TS: [long; 2] = [0; 2];
let PATHB: [byte; 256] = [0; 256];

let IN: [byte; 4096] = [0; 4096];
let IN_N = 0;

let IS_RAW = false;
let HAVE_SAVED = false;
let ARMED = false;
let STARTED = false;
let ROWS = 24;
let COLS = 80;

let WINDOW = false;
let WIN: gui.Window? = none;
let WIN_SCALE = 1;
let WIN_COLS = 120;
let WIN_ROWS = 40;
let WIN_EV: gui.Event = gui.new_event();
let WIN_SIZE = false;
let WIN_CX = -1;
let WIN_CY = -1;
let WIN_SWALLOW = 0;
let WP: [byte; 4096] = [0; 4096];
let WP_N = 0;

const RESET_SEQ = "\x1b[?1006l\x1b[?1003l\x1b[?1002l\x1b[?1000l\x1b[?7h\x1b[0m\x1b[?25h\x1b[?1049l";
const START_SEQ = "\x1b[?1049h\x1b[?25l\x1b[?7l\x1b[?1000h\x1b[?1003h\x1b[?1006h\x1b[2J";

def rd32(at: long) -> long {
    TM[at] | (TM[at + 1] << 8) | (TM[at + 2] << 16) | (TM[at + 3] << 24)
}

def wr32(at: long, v: long) -> void {
    TM[at] = v & 255;
    TM[at + 1] = (v >> 8) & 255;
    TM[at + 2] = (v >> 16) & 255;
    TM[at + 3] = (v >> 24) & 255;
}

def write_str(s: str) -> void {
    let n = len(s);
    let off = 0;
    while (off < n) {

        let w = os_call("y_os_write", 1, ptr_addr(s) + off, n - off);
        if (w <= 0) { return; };
        off += w;
    };
}

def write_raw(p: long, n: long) -> void {
    let off = 0;
    while (off < n) {
        let w = os_call("y_os_write", 1, p + off, n - off);
        if (w <= 0) { return; };
        off += w;
    };
}

def is_tty() -> bool {
    syscall(16, 0, TCGETS, &TM[0]) >= 0 && syscall(16, 1, TCGETS, &TM[0]) >= 0
}

let RL: [long; 2] = [0, 0];
def lock_dumps() -> void {
    if (gui.on_windows()) { return; };
    RL[0] = 0;
    RL[1] = 0;
    syscall(160, 4, &RL[0], 0, 0, 0);
    syscall(157, 4, 0, 0, 0, 0);
}

def dont_dump(p: long, n: long) -> void {
    if (gui.on_windows() || n <= 0 || p <= 0) { return; };
    let a = p - (p % 4096);
    let e = ((p + n + 4095) / 4096) * 4096;
    syscall(28, a, e - a, 16, 0, 0, 0);
}

def lock_pages(p: long, n: long) -> void {
    if (gui.on_windows() || n <= 0 || p <= 0) { return; };
    let a = p - (p % 4096);
    let e = ((p + n + 4095) / 4096) * 4096;
    syscall(149, a, e - a, 0, 0, 0, 0);
}

let PST: [byte; 32] = [47, 112, 114, 111, 99, 47, 115, 101, 108, 102, 47, 115, 116, 97, 116, 117, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
let PBUF: [byte; 2048] = [0; 2048];

def tracer_attached() -> bool {
    if (gui.on_windows()) { return false; };
    let fd = syscall(2, &PST[0], 0, 0);
    if (fd < 0) { return false; };
    let n = syscall(0, fd, &PBUF[0], 2048);
    syscall(3, fd);
    if (n <= 0) { return false; };
    let i = 0;
    let v = 0;
    while (i + 10 <= n) {
        if (PBUF[i] == 'T' && PBUF[i + 1] == 'r' && PBUF[i + 2] == 'a' && PBUF[i + 3] == 'c' &&
            PBUF[i + 4] == 'e' && PBUF[i + 5] == 'r' && PBUF[i + 6] == 'P' && PBUF[i + 7] == 'i' &&
            PBUF[i + 8] == 'd' && PBUF[i + 9] == ':') {
            let j = i + 10;
            while (j < n && (PBUF[j] == ' ' || PBUF[j] == 9)) { j += 1; };
            while (j < n && PBUF[j] >= '0' && PBUF[j] <= '9') { v = v * 10 + (PBUF[j] - '0'); j += 1; };
            return v != 0;
        };
        i += 1;
    };
    false
}

def raw_mode() -> bool {
    if (syscall(16, 0, TCGETS, &TM[0]) < 0) { return false; };
    for i in 0..64 { SAVED[i] = TM[i]; };
    HAVE_SAVED = true;
    wr32(12, rd32(12) & ~LFLAG_RAW);
    wr32(0, rd32(0) & ~IFLAG_RAW);
    TM[22] = 0;
    TM[23] = 0;
    if (syscall(16, 0, TCSETS, &TM[0]) < 0) { return false; };
    IS_RAW = true;
    true
}

def arm_watchdog() -> bool {
    if (!IS_RAW || ARMED) { return false; };
    if (syscall(22, &PIPE_BUF[0]) != 0) { return false; };
    let rfd = PIPE_BUF[0] | (PIPE_BUF[1] << 8) | (PIPE_BUF[2] << 16) | (PIPE_BUF[3] << 24);
    let wfd = PIPE_BUF[4] | (PIPE_BUF[5] << 8) | (PIPE_BUF[6] << 16) | (PIPE_BUF[7] << 24);
    let pid = syscall(57);
    if (pid < 0) {
        syscall(3, rfd);
        syscall(3, wfd);
        return false;
    };
    if (pid == 0) {
        syscall(112);
        syscall(3, wfd);
        syscall(0, rfd, &ONE[0], 1);
        write_str(RESET_SEQ);
        syscall(16, 0, TCSETS, &SAVED[0]);
        syscall(231, 0);
    };
    syscall(3, rfd);
    ARMED = true;
    true
}

def poll_size() -> bool {
    if (WINDOW) {
        let ch = WIN_SIZE;
        WIN_SIZE = false;
        return ch;
    };
    let r = 0;
    let c = 0;
    if (syscall(16, 1, TIOCGWINSZ, &WS[0]) >= 0) {
        r = WS[0] | (WS[1] << 8);
        c = WS[2] | (WS[3] << 8);
    };
    if (r < 1) { r = 24; };
    if (c < 1) { c = 80; };
    if (r == ROWS && c == COLS) { return false; };
    ROWS = r;
    COLS = c;
    true
}

def start() -> bool {
    if (WINDOW) { return start_window(); };
    if (!is_tty()) { return false; };
    if (!raw_mode()) { return false; };
    arm_watchdog();
    write_str(START_SEQ);
    poll_size();
    STARTED = true;
    true
}

def shutdown() -> void {
    if (!STARTED) { return; };
    STARTED = false;
    if (WINDOW) {
        if (WIN != none) { gui.close(WIN!); };
        return;
    };
    write_str(RESET_SEQ);
    if (HAVE_SAVED) { syscall(16, 0, TCSETS, &SAVED[0]); };
    IS_RAW = false;
}

def start_window() -> bool {
    let w = WIN_COLS * gui.CELL_W * WIN_SCALE;
    let h = WIN_ROWS * gui.CELL_H * WIN_SCALE;
    WIN = gui.open("Heavenly Rules", w, h);
    if (WIN == none) { return false; };
    gui.set_scale(WIN!, WIN_SCALE);
    win_fit();
    STARTED = true;
    true
}

def win_fit() -> void {
    COLS = gui.cols(WIN!);
    ROWS = gui.rows(WIN!);
    if (COLS < 1) { COLS = 1; };
    if (ROWS < 1) { ROWS = 1; };
}

def put_in(b: long) -> void {
    if (WP_N < 4096) {
        WP[WP_N] = b;
        WP_N += 1;
    };
}

def put_cp(cp: long) -> void {
    if (cp < 128) {
        put_in(cp);
    } else if (cp < 2048) {
        put_in(192 | (cp >> 6));
        put_in(128 | (cp & 63));
    } else if (cp < 65536) {
        put_in(224 | (cp >> 12));
        put_in(128 | ((cp >> 6) & 63));
        put_in(128 | (cp & 63));
    } else {
        put_in(240 | (cp >> 18));
        put_in(128 | ((cp >> 12) & 63));
        put_in(128 | ((cp >> 6) & 63));
        put_in(128 | (cp & 63));
    };
}

def put_num(v: long) -> void {
    if (v >= 100) { put_in('0' + (v / 100) % 10); };
    if (v >= 10) { put_in('0' + (v / 10) % 10); };
    put_in('0' + v % 10);
}

def put_tilde(n: long) -> void {
    put_in(27);
    put_in('[');
    put_num(n);
    put_in('~');
}

def put_mouse(b: long, px: long, py: long, press: bool) -> void {
    let cw = gui.CELL_W * WIN_SCALE;
    let ch = gui.CELL_H * WIN_SCALE;
    let cx = px / cw;
    let cy = py / ch;
    if (px < 0) { cx = 0; };
    if (py < 0) { cy = 0; };
    if (cx >= COLS) { cx = COLS - 1; };
    if (cy >= ROWS) { cy = ROWS - 1; };
    put_in(27);
    put_in('[');
    put_in('<');
    put_num(b);
    put_in(';');
    put_num(cx + 1);
    put_in(';');
    put_num(cy + 1);
    put_in(if (press) { 'M' } else { 'm' });
}

def put_key_seq(vk: long, mods: long) -> void {
    if (vk == gui.K_UP) { put_in(27); put_in('['); put_in('A'); }
    else if (vk == gui.K_DOWN) { put_in(27); put_in('['); put_in('B'); }
    else if (vk == gui.K_RIGHT) { put_in(27); put_in('['); put_in('C'); }
    else if (vk == gui.K_LEFT) { put_in(27); put_in('['); put_in('D'); }
    else if (vk == gui.K_HOME) { put_in(27); put_in('['); put_in('H'); }
    else if (vk == gui.K_END) { put_in(27); put_in('['); put_in('F'); }
    else if (vk == gui.K_INS) { put_tilde(2); }
    else if (vk == gui.K_DEL) { put_tilde(3); }
    else if (vk == gui.K_PGUP) { put_tilde(5); }
    else if (vk == gui.K_PGDN) { put_tilde(6); }
    else if (vk >= gui.K_F1 && vk < gui.K_F1 + 4) { put_in(27); put_in('O'); put_in('P' + vk - gui.K_F1); }
    else if (vk >= gui.K_F1 + 4 && vk < gui.K_F1 + 12) {
        let n = vk - gui.K_F1;

        let code = 15;
        if (n == 5) { code = 17; } else if (n == 6) { code = 18; } else if (n == 7) { code = 19; }
        else if (n == 8) { code = 20; } else if (n == 9) { code = 21; } else if (n == 10) { code = 23; }
        else if (n == 11) { code = 24; };
        put_tilde(code);
    } else if (vk == gui.K_TAB && (mods & gui.MOD_SHIFT) != 0) {
        put_in(27);
        put_in('[');
        put_in('Z');
        WIN_SWALLOW = 9;
    };
}

def win_pump() -> void {
    if (WIN == none) { return; };
    let w = WIN!;
    let ev = WIN_EV;
    let guard = 0;
    while (guard < 512 && gui.poll(w, ev)) {
        guard += 1;
        let k = ev.kind;
        if (k == gui.EV_CHAR) {
            let cp = ev.a;
            if (cp == WIN_SWALLOW && cp != 0) {
                WIN_SWALLOW = 0;
            } else if (cp == 8) {
                put_in(127);
            } else if (cp > 0) {
                put_cp(cp);
            };
        } else if (k == gui.EV_KEY) {
            if (ev.b == 1) { put_key_seq(ev.a, ev.c); };
        } else if (k == gui.EV_BUTTON) {
            let b = 0;
            if (ev.c == 2) { b = 1; } else if (ev.c == 3) { b = 2; };
            put_mouse(b, ev.a, ev.b, ev.d == 1);
        } else if (k == gui.EV_MOVE) {
            let cw = gui.CELL_W * WIN_SCALE;
            let ch = gui.CELL_H * WIN_SCALE;
            let cx = ev.a / cw;
            let cy = ev.b / ch;
            if (cx != WIN_CX || cy != WIN_CY) {
                WIN_CX = cx;
                WIN_CY = cy;
                let b = 35;
                if ((ev.c & gui.BTN_LEFT) != 0) { b = 32; }
                else if ((ev.c & gui.BTN_MIDDLE) != 0) { b = 33; }
                else if ((ev.c & gui.BTN_RIGHT) != 0) { b = 34; };
                put_mouse(b, ev.a, ev.b, true);
            };
        } else if (k == gui.EV_WHEEL) {
            let n = ev.c;
            while (n > 0) { put_mouse(64, ev.a, ev.b, true); n -= 1; };
            while (n < 0) { put_mouse(65, ev.a, ev.b, true); n += 1; };
        } else if (k == gui.EV_RESIZE) {
            win_fit();
            WIN_SIZE = true;
        } else if (k == gui.EV_CLOSE) {
            put_in(3);
        };
    };
}

def quit(code: long) -> void {
    shutdown();
    exit(code);
}

def read_in() -> long {
    IN_N = 0;
    if (WINDOW) {
        win_pump();
        for i in 0..WP_N { IN[i] = WP[i]; };
        IN_N = WP_N;
        WP_N = 0;
        return IN_N;
    };
    if (!IS_RAW) { return 0; };
    let n = syscall(0, 0, &IN[0], 4096);
    if (n > 0) { IN_N = n; };
    IN_N
}

def stderr_to(path: str) -> void {
    if (WINDOW) {

        gui.redirect_stderr(path);
        return;
    };
    let n = len(path);
    if (n > 250) { return; };
    for i in 0..n { PATHB[i] = path[i]; };
    PATHB[n] = 0;
    let fd = syscall(2, &PATHB[0], 577, 420);
    if (fd >= 0) {
        syscall(33, fd, 2);
        syscall(3, fd);
    };
}

def sleep_us(us: long) -> void {
    if (us <= 0) { return; };
    if (WINDOW) {

        if (WIN == none) { return; };
        let end = clock_us() + us;
        let now = clock_us();
        while (now < end) {
            gui.wait(WIN!, (end - now + 999) / 1000);
            win_pump();
            now = clock_us();
        };
        return;
    };
    TS[0] = us / 1000000;
    TS[1] = (us % 1000000) * 1000;
    os_call("y_os_nanosleep", &TS[0]);
}

export {
    start, shutdown, quit, read_in, poll_size, write_str, write_raw,
    stderr_to, sleep_us, IN, IN_N, ROWS, COLS, tracer_attached,
    lock_dumps, dont_dump, lock_pages,
    WINDOW, WIN, WIN_SCALE, WIN_COLS, WIN_ROWS, win_fit, is_tty
};
