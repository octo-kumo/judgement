
import term;

const NONE = 0;
const KEY = 1;
const MOUSE = 2;
const RESIZE = 3;

const M_PRESS = 1;
const M_RELEASE = 2;
const M_DRAG = 3;
const M_MOVE = 4;
const M_WHEEL_UP = 5;
const M_WHEEL_DOWN = 6;

const K_BASE = 2097152;
const K_UP = 2097153;
const K_DOWN = 2097154;
const K_LEFT = 2097155;
const K_RIGHT = 2097156;
const K_ENTER = 2097157;
const K_ESC = 2097158;
const K_BACKSPACE = 2097159;
const K_TAB = 2097160;
const K_HOME = 2097161;
const K_END = 2097162;
const K_PGUP = 2097163;
const K_PGDN = 2097164;
const K_DELETE = 2097165;
const K_INSERT = 2097166;
const K_CTRL_C = 2097167;
const K_BACKTAB = 2097168;
const K_F1 = 2097169;

const QCAP = 256;
let Q_T: [long; 256] = [0; 256];
let Q_A: [long; 256] = [0; 256];
let Q_X: [long; 256] = [0; 256];
let Q_Y: [long; 256] = [0; 256];
let Q_HEAD = 0;
let Q_LEN = 0;

let EV_TYPE = 0;
let EV_KEY = 0;
let EV_BTN = 0;
let EV_X = 0;
let EV_Y = 0;

let MOUSE_X = -1;
let MOUSE_Y = -1;
let MOUSE_DOWN = false;

let PEND: [byte; 64] = [0; 64];
let PEND_N = 0;
let PEND_AGE = 0;

let BUF: [byte; 4160] = [0; 4160];
let BUF_N = 0;

def push(t: long, a: long, x: long, y: long) -> void {
    if (Q_LEN >= QCAP) { return; };
    let i = (Q_HEAD + Q_LEN) % QCAP;
    Q_T[i] = t;
    Q_A[i] = a;
    Q_X[i] = x;
    Q_Y[i] = y;
    Q_LEN += 1;
}

def push_key(k: long) -> void { push(KEY, k, 0, 0); }

def push_mouse(action: long, btn: long, x: long, y: long) -> void {
    push(MOUSE, action * 256 + btn, x, y);
}

def push_resize() -> void { push(RESIZE, 0, 0, 0); }

def clear() -> void {
    Q_LEN = 0;
    Q_HEAD = 0;
}

def next() -> bool {
    if (Q_LEN == 0) {
        EV_TYPE = NONE;
        return false;
    };
    EV_TYPE = Q_T[Q_HEAD];
    let a = Q_A[Q_HEAD];
    EV_X = Q_X[Q_HEAD];
    EV_Y = Q_Y[Q_HEAD];
    Q_HEAD = (Q_HEAD + 1) % QCAP;
    Q_LEN -= 1;
    if (EV_TYPE == MOUSE) {
        EV_KEY = a / 256;
        EV_BTN = a % 256;
        MOUSE_X = EV_X;
        MOUSE_Y = EV_Y;
        if (EV_KEY == M_PRESS) { MOUSE_DOWN = true; };
        if (EV_KEY == M_RELEASE) { MOUSE_DOWN = false; };
    } else {
        EV_KEY = a;
        EV_BTN = 0;
    };
    true
}

let NUM = 0;
def num_at(i: long, end: long) -> long {
    let j = i;
    NUM = 0;
    while (j < end && BUF[j] >= '0' && BUF[j] <= '9') {
        NUM = NUM * 10 + (BUF[j] - '0');
        j += 1;
    };
    j
}

def tilde_key(n: long) -> long {
    if (n == 1 || n == 7) { return K_HOME; };
    if (n == 2) { return K_INSERT; };
    if (n == 3) { return K_DELETE; };
    if (n == 4 || n == 8) { return K_END; };
    if (n == 5) { return K_PGUP; };
    if (n == 6) { return K_PGDN; };
    if (n >= 11 && n <= 15) { return K_F1 + n - 11; };
    if (n >= 17 && n <= 21) { return K_F1 + 5 + n - 17; };
    if (n == 23 || n == 24) { return K_F1 + 10 + n - 23; };
    0
}

def letter_key(c: long) -> long {
    if (c == 'A') { return K_UP; };
    if (c == 'B') { return K_DOWN; };
    if (c == 'C') { return K_RIGHT; };
    if (c == 'D') { return K_LEFT; };
    if (c == 'H') { return K_HOME; };
    if (c == 'F') { return K_END; };
    if (c == 'Z') { return K_BACKTAB; };
    if (c >= 'P' && c <= 'S') { return K_F1 + c - 'P'; };
    0
}

def sgr_mouse(i: long, end: long) -> long {
    let j = num_at(i + 1, end);
    let b = NUM;
    if (j >= end || BUF[j] != ';') { return -1; };
    j = num_at(j + 1, end);
    let x = NUM - 1;
    if (j >= end || BUF[j] != ';') { return -1; };
    j = num_at(j + 1, end);
    let y = NUM - 1;
    if (j >= end) { return -1; };
    let fin = BUF[j];
    let btn = b & 3;
    let action = M_PRESS;
    if ((b & 64) != 0) {
        action = if (btn == 0) { M_WHEEL_UP } else { M_WHEEL_DOWN };
        btn = 0;
    } else if ((b & 32) != 0) {
        action = if (btn == 3) { M_MOVE } else { M_DRAG };
    } else if (fin == 'm') {
        action = M_RELEASE;
    };
    if (btn == 3) { btn = 0; };
    push_mouse(action, btn, x, y);
    j + 1
}

def escape(i: long, end: long) -> long {
    if (i + 1 >= end) { return -1; };
    let c = BUF[i + 1];
    if (c == '[') {
        if (i + 2 >= end) { return -1; };
        if (BUF[i + 2] == '<') { return sgr_mouse(i + 2, end); };

        let j = i + 2;
        while (j < end && (BUF[j] < 64 || BUF[j] > 126)) { j += 1; };
        if (j >= end) { return -1; };
        let fin = BUF[j];
        if (fin == '~') {
            num_at(i + 2, end);
            let k = tilde_key(NUM);
            if (k != 0) { push_key(k); };
        } else {
            let k = letter_key(fin);
            if (k != 0) { push_key(k); };
        };
        return j + 1;
    };
    if (c == 'O') {
        if (i + 2 >= end) { return -1; };
        let k = letter_key(BUF[i + 2]);
        if (k != 0) { push_key(k); };
        return i + 3;
    };
    if (c == 27) {
        push_key(K_ESC);
        return i + 1;
    };

    i + 1
}

def utf8_len(b: long) -> long {
    if (b < 128) { return 1; };
    if (b < 224) { return 2; };
    if (b < 240) { return 3; };
    4
}

def decode() -> void {
    let i = 0;
    let end = BUF_N;
    PEND_N = 0;
    while (i < end) {
        let b = BUF[i];
        if (b == 27) {
            let j = escape(i, end);
            if (j < 0) {

                let n = end - i;
                if (n > 64) { n = 64; };
                for k in 0..n { PEND[k] = BUF[i + k]; };
                PEND_N = n;
                return;
            };
            i = j;
        } else if (b == 13 || b == 10) {
            push_key(K_ENTER);
            i += 1;
        } else if (b == 127 || b == 8) {
            push_key(K_BACKSPACE);
            i += 1;
        } else if (b == 9) {
            push_key(K_TAB);
            i += 1;
        } else if (b == 3) {
            push_key(K_CTRL_C);
            i += 1;
        } else if (b < 32) {
            push_key(b);
            i += 1;
        } else {
            let n = utf8_len(b);
            if (i + n > end) {
                for k in 0..(end - i) { PEND[k] = BUF[i + k]; };
                PEND_N = end - i;
                return;
            };
            let cp: long = b;
            if (n == 2) { cp = ((b & 31) << 6) | (BUF[i + 1] & 63); };
            if (n == 3) { cp = ((b & 15) << 12) | ((BUF[i + 1] & 63) << 6) | (BUF[i + 2] & 63); };
            if (n == 4) {
                cp = ((b & 7) << 18) | ((BUF[i + 1] & 63) << 12) | ((BUF[i + 2] & 63) << 6) | (BUF[i + 3] & 63);
            };
            push_key(cp);
            i += n;
        };
    };
}

def feed_from_term() -> void {
    BUF_N = 0;
    for k in 0..PEND_N { BUF[k] = PEND[k]; };
    BUF_N = PEND_N;
    let had_pend = PEND_N > 0;
    for k in 0..term.IN_N {
        if (BUF_N < 4160) {
            BUF[BUF_N] = term.IN[k];
            BUF_N += 1;
        };
    };
    if (BUF_N == 0) { return; };
    decode();
    if (PEND_N > 0 && had_pend && term.IN_N == 0) {
        PEND_AGE += 1;
        if (PEND_AGE >= 2) {

            if (PEND[0] == 27) { push_key(K_ESC); };
            PEND_N = 0;
            PEND_AGE = 0;
        };
    } else {
        PEND_AGE = 0;
    };
}

def feed_str(s: str) -> void {
    BUF_N = 0;
    for k in 0..len(s) {
        BUF[k] = s[k];
        BUF_N += 1;
    };
    decode();
    if (PEND_N > 0 && PEND[0] == 27 && PEND_N == 1) {
        push_key(K_ESC);
        PEND_N = 0;
    };
}

def poll() -> void {
    term.read_in();
    feed_from_term();
    if (term.poll_size()) { push_resize(); };
}

export {
    poll, next, clear, push_key, push_mouse, push_resize, feed_str,
    NONE, KEY, MOUSE, RESIZE,
    M_PRESS, M_RELEASE, M_DRAG, M_MOVE, M_WHEEL_UP, M_WHEEL_DOWN,
    K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ENTER, K_ESC, K_BACKSPACE, K_TAB, K_HOME,
    K_END, K_PGUP, K_PGDN, K_DELETE, K_INSERT, K_CTRL_C, K_BACKTAB, K_F1, K_BASE,
    EV_TYPE, EV_KEY, EV_BTN, EV_X, EV_Y, MOUSE_X, MOUSE_Y, MOUSE_DOWN
};
