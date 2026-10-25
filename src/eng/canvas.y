
import term;
import gui;

const MAXC = 256;
let MAXR = 128;
let N = 32768;
const KEEP = -3;
const SKIP = -1;

let BOLD = 1;
let DIM = 2;
let ITALIC = 4;
let UNDER = 8;
let REVERSE = 16;

let CH: [long; 32768] = [32; 32768];
let FG: [long; 32768] = [0; 32768];
let BG: [long; 32768] = [0; 32768];
let AT: [long; 32768] = [0; 32768];
let FCH: [long; 32768] = [-2; 32768];
let FFG: [long; 32768] = [0; 32768];
let FBG: [long; 32768] = [0; 32768];
let FAT: [long; 32768] = [0; 32768];

let W = 80;
let H = 24;
let OX = 0;
let OY = 0;
let FULL = true;

let CX0: [long; 16] = [0; 16];
let CY0: [long; 16] = [0; 16];
let CX1: [long; 16] = [0; 16];
let CY1: [long; 16] = [0; 16];
let CSP = 0;
let X0 = 0;
let Y0 = 0;
let X1 = 80;
let Y1 = 24;

let OB: [byte; 65536] = [0; 65536];
let OBN = 0;
let BYTES_LAST = 0;

def fit() -> bool {
    let w = term.COLS;
    let h = term.ROWS;
    if (w > MAXC) { w = MAXC; };
    if (h > MAXR) { h = MAXR; };
    let ox = (term.COLS - w) / 2;
    let oy = (term.ROWS - h) / 2;
    if (w == W && h == H && ox == OX && oy == OY) { return false; };
    W = w;
    H = h;
    OX = ox;
    OY = oy;
    FULL = true;
    reset_clip();
    true
}

def reset_clip() -> void {
    CSP = 0;
    X0 = 0;
    Y0 = 0;
    X1 = W;
    Y1 = H;
}

def push_clip(x: long, y: long, w: long, h: long) -> void {
    if (CSP < 16) {
        CX0[CSP] = X0;
        CY0[CSP] = Y0;
        CX1[CSP] = X1;
        CY1[CSP] = Y1;
        CSP += 1;
    };
    let nx0 = if (x > X0) { x } else { X0 };
    let ny0 = if (y > Y0) { y } else { Y0 };
    let nx1 = if (x + w < X1) { x + w } else { X1 };
    let ny1 = if (y + h < Y1) { y + h } else { Y1 };
    X0 = nx0;
    Y0 = ny0;
    X1 = if (nx1 < nx0) { nx0 } else { nx1 };
    Y1 = if (ny1 < ny0) { ny0 } else { ny1 };
}

def pop_clip() -> void {
    if (CSP == 0) { return; };
    CSP -= 1;
    X0 = CX0[CSP];
    Y0 = CY0[CSP];
    X1 = CX1[CSP];
    Y1 = CY1[CSP];
}

def clear(bg: long) -> void {
    for y in 0..H {
        let row = y * MAXC;
        for x in 0..W {
            let i = row + x;
            CH[i] = 32;
            FG[i] = bg;
            BG[i] = bg;
            AT[i] = 0;
        };
    };
}

def inside(x: long, y: long) -> bool {
    x >= X0 && x < X1 && y >= Y0 && y < Y1
}

def width_of(cp: long) -> long {
    if (cp < 32) { return 0; };
    if (cp >= 768 && cp <= 879) { return 0; };
    if (cp >= 8203 && cp <= 8207) { return 0; };
    if (cp >= 65024 && cp <= 65039) { return 0; };
    if (cp >= 4352 && cp <= 4447) { return 2; };
    if (cp >= 11904 && cp <= 42191) { return 2; };
    if (cp >= 44032 && cp <= 55203) { return 2; };
    if (cp >= 63744 && cp <= 64255) { return 2; };
    if (cp >= 65280 && cp <= 65376) { return 2; };
    if (cp >= 127744 && cp <= 129535) { return 2; };
    if (cp >= 131072 && cp <= 262141) { return 2; };
    1
}

def set_cell(i: long, cp: long, fg: long, bg: long, at: long) -> void {
    CH[i] = cp;
    if (fg != KEEP) { FG[i] = fg; };
    if (bg != KEEP) { BG[i] = bg; };
    AT[i] = at;
}

def put(x: long, y: long, cp: long, fg: long, bg: long, at: long) -> long {
    if (!inside(x, y)) { return 0; };
    let w = width_of(cp);
    if (w == 0) { return 0; };
    let i = y * MAXC + x;

    if (CH[i] == SKIP && x > 0) { CH[i - 1] = 32; };
    if (w == 2) {
        if (x + 1 >= X1) {
            set_cell(i, 32, fg, bg, at);
            return 1;
        };
        set_cell(i, cp, fg, bg, at);
        set_cell(i + 1, SKIP, fg, bg, at);
        return 2;
    };
    set_cell(i, cp, fg, bg, at);
    1
}

def fill(x: long, y: long, w: long, h: long, cp: long, fg: long, bg: long, at: long) -> void {
    for yy in y..(y + h) {
        for xx in x..(x + w) {
            put(xx, yy, cp, fg, bg, at);
        };
    };
}

def fill_bg(x: long, y: long, w: long, h: long, bg: long) -> void {
    for yy in y..(y + h) {
        for xx in x..(x + w) {
            if (inside(xx, yy)) { BG[yy * MAXC + xx] = bg; };
        };
    };
}

def get_ch(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= W || y >= H) { return 32; };
    CH[y * MAXC + x]
}
def get_fg(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= W || y >= H) { return 0; };
    FG[y * MAXC + x]
}
def get_bg(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= W || y >= H) { return 0; };
    BG[y * MAXC + x]
}

def fade_rect(x: long, y: long, w: long, h: long, c: long, t: long) -> void {
    if (t <= 0) { return; };
    let x0 = if (x < 0) { 0 } else { x };
    let y0 = if (y < 0) { 0 } else { y };
    let x1 = if (x + w > W) { W } else { x + w };
    let y1 = if (y + h > H) { H } else { y + h };
    for yy in y0..y1 {
        for xx in x0..x1 {
            let i = yy * MAXC + xx;
            FG[i] = mixc(FG[i], c, t);
            BG[i] = mixc(BG[i], c, t);
        };
    };
}

def fade_all(c: long, t: long) -> void { fade_rect(0, 0, W, H, c, t); }

def mixc(a: long, b: long, t: long) -> long {
    if (t >= 256) { return b; };
    let u = 256 - t;
    let r = (((a >> 16) & 255) * u + ((b >> 16) & 255) * t) >> 8;
    let g = (((a >> 8) & 255) * u + ((b >> 8) & 255) * t) >> 8;
    let bl = ((a & 255) * u + (b & 255) * t) >> 8;
    (r << 16) | (g << 8) | bl
}

def ob_flush() -> void {
    if (OBN > 0) { term.write_raw(ptr_addr(&OB[0]), OBN); };
    BYTES_LAST += OBN;
    OBN = 0;
}

def ob(b: long) -> void {
    if (OBN >= 65536) { ob_flush(); };
    OB[OBN] = b;
    OBN += 1;
}

def ob_str(s: str) -> void {
    foreach (b in s) { ob(b); };
}

def ob_num(v: long) -> void {
    if (v >= 1000) { ob('0' + (v / 1000) % 10); };
    if (v >= 100) { ob('0' + (v / 100) % 10); };
    if (v >= 10) { ob('0' + (v / 10) % 10); };
    ob('0' + v % 10);
}

def ob_cp(cp: long) -> void {
    if (cp < 128) {
        ob(cp);
    } else if (cp < 2048) {
        ob(192 | (cp >> 6));
        ob(128 | (cp & 63));
    } else if (cp < 65536) {
        ob(224 | (cp >> 12));
        ob(128 | ((cp >> 6) & 63));
        ob(128 | (cp & 63));
    } else {
        ob(240 | (cp >> 18));
        ob(128 | ((cp >> 12) & 63));
        ob(128 | ((cp >> 6) & 63));
        ob(128 | (cp & 63));
    };
}

def ob_cup(row: long, col: long) -> void {
    ob(27);
    ob('[');
    ob_num(row + 1);
    ob(';');
    ob_num(col + 1);
    ob('H');
}

let CUR_FG = -2;
let CUR_BG = -2;
let CUR_AT = -2;

def ob_color(fgbg: long, c: long) -> void {
    if (c < 0) {
        ob(27); ob('['); ob(if (fgbg == 0) { '3' } else { '4' }); ob('9'); ob('m');
        return;
    };
    ob(27); ob('['); ob(if (fgbg == 0) { '3' } else { '4' }); ob('8'); ob(';'); ob('2'); ob(';');
    ob_num((c >> 16) & 255); ob(';');
    ob_num((c >> 8) & 255); ob(';');
    ob_num(c & 255); ob('m');
}

def ob_style(fg: long, bg: long, at: long) -> void {
    if (at != CUR_AT) {
        ob_str("\x1b[0");
        if ((at & BOLD) != 0) { ob_str(";1"); };
        if ((at & DIM) != 0) { ob_str(";2"); };
        if ((at & ITALIC) != 0) { ob_str(";3"); };
        if ((at & UNDER) != 0) { ob_str(";4"); };
        if ((at & REVERSE) != 0) { ob_str(";7"); };
        ob('m');
        CUR_AT = at;
        CUR_FG = -2;
        CUR_BG = -2;
    };
    if (fg != CUR_FG) { ob_color(0, fg); CUR_FG = fg; };
    if (bg != CUR_BG) { ob_color(1, bg); CUR_BG = bg; };
}

def flush_window() -> long {
    let w = term.WIN!;
    if (FULL) {
        gui.clear(w, 0);
        for i in 0..N { FCH[i] = -2; };
        FULL = false;
    };
    let n = 0;
    for y in 0..H {
        let row = y * MAXC;
        for x in 0..W {
            let i = row + x;
            let ch = CH[i];
            if (ch == FCH[i] && FG[i] == FFG[i] && BG[i] == FBG[i] && AT[i] == FAT[i]) { continue; };
            FCH[i] = ch;
            FFG[i] = FG[i];
            FBG[i] = BG[i];
            FAT[i] = AT[i];
            if (ch == SKIP) { continue; };
            let fg = FG[i];
            let bg = BG[i];
            if (fg < 0) { fg = 0xc8c8c8; };
            if (bg < 0) { bg = 0; };
            let cp = ch;
            if (width_of(ch) == 0) { cp = 32; };
            gui.cell(w, OX + x, OY + y, cp, fg, bg, AT[i] & ~ITALIC);
            n += 1;

            if (width_of(ch) == 2 && x + 1 < W) {
                FCH[i + 1] = SKIP;
                FFG[i + 1] = FG[i + 1];
                FBG[i + 1] = BG[i + 1];
                FAT[i + 1] = AT[i + 1];
                gui.cell(w, OX + x + 1, OY + y, 32, fg, bg, 0);
            };
        };
    };
    gui.present(w);
    BYTES_LAST = n;
    n
}

def flush() -> long {
    if (term.WINDOW && term.WIN != none) { return flush_window(); };
    BYTES_LAST = 0;
    CUR_FG = -2;
    CUR_BG = -2;
    CUR_AT = -2;
    if (FULL) {
        ob_str("\x1b[0m\x1b[48;2;0;0;0m\x1b[2J");
        for i in 0..N { FCH[i] = -2; };
        FULL = false;
    };
    let cx = -1;
    let cy = -1;
    for y in 0..H {
        let row = y * MAXC;
        for x in 0..W {
            let i = row + x;
            let ch = CH[i];
            if (ch == FCH[i] && FG[i] == FFG[i] && BG[i] == FBG[i] && AT[i] == FAT[i]) { continue; };
            FCH[i] = ch;
            FFG[i] = FG[i];
            FBG[i] = BG[i];
            FAT[i] = AT[i];
            if (ch == SKIP) { continue; };
            if (cx != x || cy != y) {
                ob_cup(OY + y, OX + x);
                cx = x;
                cy = y;
            };
            ob_style(FG[i], BG[i], AT[i]);
            let w = width_of(ch);
            if (w == 0 || ch < 32) {
                ob(32);
                w = 1;
            } else {
                ob_cp(ch);
            };

            if (w == 2 && x + 1 < W) {
                FCH[i + 1] = SKIP;
                FFG[i + 1] = FG[i + 1];
                FBG[i + 1] = BG[i + 1];
                FAT[i + 1] = AT[i + 1];
            };
            cx += w;
        };
    };
    ob_flush();
    BYTES_LAST
}


export {
    fit, clear, put, fill, fill_bg, get_ch, get_fg, get_bg, inside, width_of,
    push_clip, pop_clip, reset_clip, fade_rect, fade_all, flush,
    W, H, OX, OY, FULL, MAXC, KEEP, SKIP, BOLD, DIM, ITALIC, UNDER, REVERSE,
    CH, FG, BG, AT, BYTES_LAST
};
