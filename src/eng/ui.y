
import canvas;
import style;
import text;

let MAXR = 128;
let R_ID: [long; 128] = [0; 128];
let R_X: [long; 128] = [0; 128];
let R_Y: [long; 128] = [0; 128];
let R_W: [long; 128] = [0; 128];
let R_H: [long; 128] = [0; 128];
let NR = 0;
let HOVER = -1;

def begin() -> void {
    NR = 0;
}

def region(id: long, x: long, y: long, w: long, h: long) -> void {
    if (NR >= MAXR) { return; };
    R_ID[NR] = id;
    R_X[NR] = x;
    R_Y[NR] = y;
    R_W[NR] = w;
    R_H[NR] = h;
    NR += 1;
}

def hit(x: long, y: long) -> long {
    let k = NR - 1;
    while (k >= 0) {
        if (x >= R_X[k] && x < R_X[k] + R_W[k] && y >= R_Y[k] && y < R_Y[k] + R_H[k]) {
            return R_ID[k];
        };
        k -= 1;
    };
    -1
}

def hover(x: long, y: long) -> long {
    HOVER = hit(x, y);
    HOVER
}

const ROUND = 0;
const SQUARE = 1;
const DOUBLE = 2;
const HEAVY = 3;

def corner(kind: long, which: long) -> long {
    if (kind == ROUND) {
        if (which == 0) { return 0x256D; };
        if (which == 1) { return 0x256E; };
        if (which == 2) { return 0x2570; };
        return 0x256F;
    };
    if (kind == DOUBLE) {
        if (which == 0) { return 0x2554; };
        if (which == 1) { return 0x2557; };
        if (which == 2) { return 0x255A; };
        return 0x255D;
    };
    if (kind == HEAVY) {
        if (which == 0) { return 0x250F; };
        if (which == 1) { return 0x2513; };
        if (which == 2) { return 0x2517; };
        return 0x251B;
    };
    if (which == 0) { return 0x250C; };
    if (which == 1) { return 0x2510; };
    if (which == 2) { return 0x2514; };
    0x2518
}

def hbar(kind: long) -> long {
    if (kind == DOUBLE) { return 0x2550; };
    if (kind == HEAVY) { return 0x2501; };
    0x2500
}

def vbar(kind: long) -> long {
    if (kind == DOUBLE) { return 0x2551; };
    if (kind == HEAVY) { return 0x2503; };
    0x2502
}

def frame(x: long, y: long, w: long, h: long, kind: long, body: long, edge: long, title: str) -> void {
    if (w < 2 || h < 2) { return; };
    let fg = style.FG[edge];
    let bg = style.BG[body];
    canvas.fill(x + 1, y + 1, w - 2, h - 2, 32, style.FG[body], bg, 0);
    canvas.put(x, y, corner(kind, 0), fg, bg, 0);
    canvas.put(x + w - 1, y, corner(kind, 1), fg, bg, 0);
    canvas.put(x, y + h - 1, corner(kind, 2), fg, bg, 0);
    canvas.put(x + w - 1, y + h - 1, corner(kind, 3), fg, bg, 0);
    for i in 1..(w - 1) {
        canvas.put(x + i, y, hbar(kind), fg, bg, 0);
        canvas.put(x + i, y + h - 1, hbar(kind), fg, bg, 0);
    };
    for j in 1..(h - 1) {
        canvas.put(x, y + j, vbar(kind), fg, bg, 0);
        canvas.put(x + w - 1, y + j, vbar(kind), fg, bg, 0);
    };
    if (len(title) > 0) {
        let tw = text.width(title);
        let tx = x + 2;
        canvas.put(tx - 1, y, 32, fg, bg, 0);
        text.print(tx, y, title, style.TITLE);
        canvas.put(tx + tw, y, 32, fg, bg, 0);
    };
}

def shadow(x: long, y: long, w: long, h: long) -> void {
    for j in (y + 1)..(y + h + 1) {
        shade_cell(x + w, j);
    };
    for i in (x + 1)..(x + w + 1) {
        shade_cell(i, y + h);
    };
}

def shade_cell(x: long, y: long) -> void {
    if (!canvas.inside(x, y)) { return; };
    let i = y * canvas.MAXC + x;
    canvas.BG[i] = canvas.mixc(canvas.BG[i], 0, 140);
    canvas.FG[i] = canvas.mixc(canvas.FG[i], 0, 140);
}

def button(id: long, x: long, y: long, label: str, normal: long, hot: long) -> long {
    let w = text.width(label) + 2;
    let st = if (HOVER == id) { hot } else { normal };
    canvas.fill(x, y, w, 1, 32, style.FG[st], style.BG[st], 0);
    text.print(x + 1, y, label, st);
    region(id, x, y, w, 1);
    w
}

def meter(x: long, y: long, w: long, v: long, max: long, fg: long, bg: long) -> void {
    if (max <= 0 || w <= 0) { return; };
    let vv = if (v < 0) { 0 } else if (v > max) { max } else { v };
    let eighths = vv * w * 8 / max;
    for i in 0..w {
        let e = eighths - i * 8;
        let cp = 32;
        if (e >= 8) { cp = 0x2588; } else if (e > 0) { cp = 0x2590 - e; };
        canvas.put(x + i, y, cp, fg, bg, 0);
    };
}

def toast(y: long, s: str, st: long) -> void {
    let w = text.width(s) + 4;
    let x = (canvas.W - w) / 2;
    canvas.fill(x, y, w, 1, 32, style.FG[style.BOX], style.BG[style.BOX], 0);
    text.print(x + 2, y, s, st);
}

def floating(cx: long, by: long, w: long, s: str, from: long, to: long, reveal: long) -> long {
    let n = text.layout(s, from, to, w);
    let maxw = 0;
    for k in 0..n {
        if (text.L_W[k] > maxw) { maxw = text.L_W[k]; };
    };
    let x = cx - maxw / 2;
    if (x < 0) { x = 0; };
    if (x + maxw > canvas.W) { x = canvas.W - maxw; };
    let y = by - n;
    if (y < 0) { y = 0; };
    text.ALIGN_W = maxw;
    text.draw_layout(x, y, s, from, to, style.TEXT, 0, n, reveal, 1);
    n
}

export {
    begin, region, hit, hover, frame, shadow, shade_cell, button, meter, toast,
    floating, HOVER, ROUND, SQUARE, DOUBLE, HEAVY
};
