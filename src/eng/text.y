
import canvas;
import style;

let TIME = 0;
let ALIGN_W = 0;

let VAR_S: [str; 16] = [""; 16];
let VAR_N: [long; 16] = [0; 16];

let XB: [long; 256] = [0; 256];
let XB_N = 0;
def x_clear() -> void { XB_N = 0; }
def x_add(cp: long) -> void {
    if (XB_N < 256) {
        XB[XB_N] = cp;
        XB_N += 1;
    };
}

let SRC = "";
let POS = 0;
let END = 0;
let OUTER = "";
let OUTER_POS = 0;
let OUTER_END = 0;
let IN_VAR = false;

let STK: [long; 16] = [0; 16];
let SP = 0;
let CUR = 0;

let PQ: [long; 300] = [0; 300];
let PQ_N = 0;
let PQ_I = 0;

let G_CP = 0;
let G_ST = 0;
let G_KIND = 0;

def it_begin(s: str, from: long, to: long, base: long) -> void {
    SRC = s;
    POS = from;
    END = if (to > len(s)) { len(s) } else { to };
    IN_VAR = false;
    SP = 0;
    CUR = base;
    PQ_N = 0;
    PQ_I = 0;
}

def hexval(c: long) -> long {
    if (c >= '0' && c <= '9') { return c - '0'; };
    if (c >= 'a' && c <= 'f') { return c - 'a' + 10; };
    if (c >= 'A' && c <= 'F') { return c - 'A' + 10; };
    -1
}

def dec_range(i: long, j: long) -> long {
    let v = 0;
    for k in i..j {
        let d = SRC[k] - '0';
        if (d >= 0 && d <= 9) { v = v * 10 + d; };
    };
    v
}

def queue_num(v: long) -> void {
    PQ_N = 0;
    PQ_I = 0;
    let x = v;
    if (x < 0) {
        PQ[0] = '-';
        PQ_N = 1;
        x = 0 - x;
    };
    let start = PQ_N;
    if (x == 0) {
        PQ[PQ_N] = '0';
        PQ_N += 1;
    };
    while (x > 0 && PQ_N < 40) {
        PQ[PQ_N] = '0' + x % 10;
        PQ_N += 1;
        x = x / 10;
    };

    let a = start;
    let b = PQ_N - 1;
    while (a < b) {
        let t = PQ[a];
        PQ[a] = PQ[b];
        PQ[b] = t;
        a += 1;
        b -= 1;
    };
}

def tag(i: long, j: long) -> void {
    if (j - i == 1 && SRC[i] == '/') {
        if (SP > 0) {
            SP -= 1;
            CUR = STK[SP];
        };
        return;
    };

    let sp = i;
    while (sp < j && SRC[sp] != ' ') { sp += 1; };
    if (sp < j) {
        let w0 = SRC[i];
        let wl = sp - i;
        if (wl == 4 && w0 == 'r') {
            let hi = hexval(SRC[sp + 1]);
            let lo = if (sp + 2 < j) { hexval(SRC[sp + 2]) } else { -1 };
            PQ_N = 0;
            PQ_I = 0;
            if (hi >= 0) { PQ[0] = style.RUNE[hi]; PQ_N = 1; };
            if (lo >= 0) { PQ[PQ_N] = style.RUNE[lo]; PQ_N += 1; };
            return;
        };
        if (wl == 1 && w0 == 'r') {
            let v = dec_range(sp + 1, j) & 15;
            PQ[0] = style.RUNE[v];
            PQ_N = 1;
            PQ_I = 0;
            return;
        };
        if (wl == 1 && w0 == 'n') {
            queue_num(VAR_N[dec_range(sp + 1, j) & 15]);
            return;
        };
        if (wl == 1 && w0 == 'v') {
            if (!IN_VAR) {
                OUTER = SRC;
                OUTER_POS = POS;
                OUTER_END = END;
                IN_VAR = true;
                SRC = VAR_S[dec_range(sp + 1, j) & 15];
                POS = 0;
                END = len(SRC);
            };
            return;
        };
    };
    if (j - i == 1 && SRC[i] == 'x') {
        PQ_N = 0;
        PQ_I = 0;
        for k in 0..XB_N {
            PQ[PQ_N] = XB[k];
            PQ_N += 1;
        };
        return;
    };
    let id = style.find_range(SRC, i, j);
    if (id >= 0) {
        if (SP < 16) {
            STK[SP] = CUR;
            SP += 1;
        };
        CUR = id;
    };
}

def it_next() -> bool {
    while (true) {
        if (PQ_I < PQ_N) {
            G_CP = PQ[PQ_I];
            PQ_I += 1;
            G_ST = CUR;
            G_KIND = if (G_CP == 32) { 1 } else { 0 };
            return true;
        };
        if (POS >= END) {
            if (IN_VAR) {
                SRC = OUTER;
                POS = OUTER_POS;
                END = OUTER_END;
                IN_VAR = false;
                continue;
            };
            return false;
        };
        let b = SRC[POS];
        if (b == '{') {
            if (POS + 1 < END && SRC[POS + 1] == '{') {
                POS += 2;
                G_CP = '{';
                G_ST = CUR;
                G_KIND = 0;
                return true;
            };
            let j = POS + 1;
            while (j < END && SRC[j] != '}') { j += 1; };
            let start = POS + 1;
            POS = j + 1;
            tag(start, j);
            continue;
        };
        if (b == 10) {
            POS += 1;
            G_CP = 32;
            G_ST = CUR;
            G_KIND = 2;
            return true;
        };
        if (b == 13) {
            POS += 1;
            continue;
        };
        let n = if (b < 128) { 1 } else if (b < 224) { 2 } else if (b < 240) { 3 } else { 4 };
        let cp = b;
        if (n == 2 && POS + 1 < END) { cp = ((b & 31) << 6) | (SRC[POS + 1] & 63); };
        if (n == 3 && POS + 2 < END) {
            cp = ((b & 15) << 12) | ((SRC[POS + 1] & 63) << 6) | (SRC[POS + 2] & 63);
        };
        if (n == 4 && POS + 3 < END) {
            cp = ((b & 7) << 18) | ((SRC[POS + 1] & 63) << 12) | ((SRC[POS + 2] & 63) << 6) | (SRC[POS + 3] & 63);
        };
        POS += n;
        G_CP = cp;
        G_ST = CUR;
        G_KIND = if (cp == 32) { 1 } else { 0 };
        return true;
    };
    false
}

const MAXG = 4096;
let GW: [long; 4096] = [0; 4096];
let GK: [long; 4096] = [0; 4096];
let NG = 0;

let MAXL = 128;
let L_START: [long; 128] = [0; 128];
let L_LEN: [long; 128] = [0; 128];
let L_W: [long; 128] = [0; 128];
let NL = 0;

def collect(s: str, from: long, to: long) -> void {
    it_begin(s, from, to, 0);
    NG = 0;
    while (NG < MAXG && it_next()) {
        GW[NG] = if (G_KIND == 2) { 0 } else { canvas.width_of(G_CP) };
        GK[NG] = G_KIND;
        NG += 1;
    };
}

def add_line(start: long, n: long, w: long) -> void {
    if (NL >= MAXL) { return; };
    L_START[NL] = start;
    L_LEN[NL] = n;
    L_W[NL] = w;
    NL += 1;
}

def layout(s: str, from: long, to: long, width: long) -> long {
    collect(s, from, to);
    NL = 0;
    if (width < 1) { return 0; };
    let i = 0;
    let ls = 0;
    let lw = 0;
    let last_end = -1;
    let last_w = 0;
    while (i < NG) {
        if (GK[i] == 2) {
            add_line(ls, i - ls, lw);
            i += 1;
            ls = i;
            lw = 0;
            last_end = -1;
            continue;
        };
        if (GK[i] == 1) {
            if (lw == 0) {

                i += 1;
                ls = i;
                continue;
            };
            last_end = i;
            last_w = lw;
            lw += GW[i];
            i += 1;
            continue;
        };

        let j = i;
        let ww = 0;
        while (j < NG && GK[j] == 0) {
            ww += GW[j];
            j += 1;
        };
        if (lw + ww <= width) {
            lw += ww;
            i = j;
            last_end = j;
            last_w = lw;
            continue;
        };
        if (lw == 0 || last_end < 0) {

            let k = i;
            let kw = lw;
            while (k < j && kw + GW[k] <= width) {
                kw += GW[k];
                k += 1;
            };
            if (k == i) { k = i + 1; kw += GW[i]; };
            add_line(ls, k - ls, kw);
            i = k;
            ls = k;
            lw = 0;
            last_end = -1;
            continue;
        };

        add_line(ls, last_end - ls, last_w);
        ls = last_end;
        while (ls < NG && GK[ls] == 1) { ls += 1; };
        i = ls;
        lw = 0;
        last_end = -1;
    };
    if (lw > 0 || ls < NG) { add_line(ls, NG - ls, lw); };
    NL
}

def wave(t: long) -> long {
    let p = t & 63;
    if (p < 32) { return p * 8; };
    (63 - p) * 8
}

def mix(a: long, b: long, t: long) -> long {
    let u = 256 - t;
    let r = (((a >> 16) & 255) * u + ((b >> 16) & 255) * t) >> 8;
    let g = (((a >> 8) & 255) * u + ((b >> 8) & 255) * t) >> 8;
    let bl = ((a & 255) * u + (b & 255) * t) >> 8;
    (r << 16) | (g << 8) | bl
}

const HASH = 12345;
def jitter(n: long) -> long {
    let h = (n * 2654435761 + TIME * 40503) & 0xffffffff;
    h = ((h >> 13) ^ h) * 1274126177 & 0xffffffff;
    (h >> 8) & 255
}

def put_glyph(x: long, y: long, cp: long, st: long, gi: long) -> long {
    let fg = style.FG[st];
    let bg = style.BG[st];
    let fx = style.FX[st];
    let ch = cp;
    if (fx == 1) {
        fg = mix(fg, 0xffffff, wave(TIME * 2 + gi * 5) / 2);
    } else if (fx == 2) {
        let j = jitter(gi);
        if (j < 24) { ch = style.RUNE[j & 15]; };
        if (j > 230) { fg = 0xff4060; } else if (j > 205) { fg = 0x40e0ff; };
    } else if (fx == 3) {
        let under = if (bg == canvas.KEEP) { canvas.get_bg(x, y) } else { bg };
        fg = mix(fg, under, wave(TIME + gi * 3) / 2);
    };
    canvas.put(x, y, ch, fg, bg, style.AT[st])
}

def draw_layout(x: long, y: long, s: str, from: long, to: long, base: long, first: long, maxl: long, reveal: long, align: long) -> long {
    it_begin(s, from, to, base);
    let gi = 0;
    let shown = 0;
    let line = 0;
    while (line < NL && it_next()) {

        if (gi < L_START[line]) {
            gi += 1;
            continue;
        };
        if (gi >= L_START[line] + L_LEN[line]) {
            line += 1;
            if (line >= NL) { break; };
            if (gi < L_START[line]) {
                gi += 1;
                continue;
            };
        };
        if (reveal >= 0 && shown >= reveal) { break; };
        if (line >= first && line < first + maxl) {

            let cx = 0;
            for k in L_START[line]..gi { cx += GW[k]; };
            let ox = 0;
            if (align == 1) { ox = (ALIGN_W - L_W[line]) / 2; };
            if (align == 2) { ox = ALIGN_W - L_W[line]; };
            if (GK[gi] != 2) {
                put_glyph(x + ox + cx, y + line - first, G_CP, G_ST, gi);
            };
        };
        shown += 1;
        gi += 1;
    };
    NG
}

def box(x: long, y: long, w: long, h: long, s: str, from: long, to: long, base: long, reveal: long) -> long {
    let n = layout(s, from, to, w);
    ALIGN_W = w;
    draw_layout(x, y, s, from, to, base, 0, h, reveal, 0);
    n
}

def box_center(x: long, y: long, w: long, h: long, s: str, base: long) -> long {
    let n = layout(s, 0, len(s), w);
    ALIGN_W = w;
    draw_layout(x, y, s, 0, len(s), base, 0, h, -1, 1);
    n
}

def print(x: long, y: long, s: str, base: long) -> long {
    print_range(x, y, s, 0, len(s), base)
}

def print_range(x: long, y: long, s: str, from: long, to: long, base: long) -> long {
    it_begin(s, from, to, base);
    let cx = 0;
    let gi = 0;
    while (it_next()) {
        if (G_KIND == 2) { continue; };
        put_glyph(x + cx, y, G_CP, G_ST, gi);
        cx += canvas.width_of(G_CP);
        gi += 1;
    };
    cx
}

def width(s: str) -> long { width_range(s, 0, len(s)) }

def width_range(s: str, from: long, to: long) -> long {
    it_begin(s, from, to, 0);
    let w = 0;
    while (it_next()) {
        if (G_KIND != 2) { w += canvas.width_of(G_CP); };
    };
    w
}

def glyphs(s: str, from: long, to: long) -> long {
    it_begin(s, from, to, 0);
    let n = 0;
    while (it_next()) { n += 1; };
    n
}

let DIG: [long; 24] = [0; 24];
def num(x: long, y: long, v: long, w: long, st: long) -> long {
    let n = 0;
    let neg = v < 0;
    let a = if (neg) { 0 - v } else { v };
    if (a == 0) { DIG[0] = '0'; n = 1; };
    while (a > 0 && n < 22) {
        DIG[n] = '0' + a % 10;
        n += 1;
        a = a / 10;
    };
    if (neg) { DIG[n] = '-'; n += 1; };
    let cx = x;
    if (w > n) { cx = x + w - n; };
    let k = n - 1;
    while (k >= 0) {
        canvas.put(cx, y, DIG[k], style.FG[st], style.BG[st], style.AT[st]);
        cx += 1;
        k -= 1;
    };
    n
}

def runes(x: long, y: long, v: long, st: long) -> void {
    put_glyph(x, y, style.RUNE[(v >> 4) & 15], st, 0);
    put_glyph(x + 1, y, style.RUNE[v & 15], st, 1);
}

export {
    TIME, VAR_S, VAR_N, XB, XB_N, x_clear, x_add, layout, draw_layout, box, box_center, print, print_range,
    width, width_range, glyphs, num, runes, NL, L_W, NG, ALIGN_W
};
