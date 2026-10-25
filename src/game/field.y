
import mem;
import g;
import canvas;
import style;
import text;
import ui;
import input;
import sfx;

let MAXN = 64;
let BUF: [byte; 64] = [0; 64];
let N = 0;

let OPEN = false;
let KIND = 0;
let TARGET = -1;
let CAP = 0;
let PRICE = 0;
let TITLE = "";
let HINT = "";
let SEL = 0;
let PAL = false;
let PSEL = 0;
let RESULT = 0;

const K_BOARD = 0;
const K_SEAL = 1;

const HIT_PAL = 7000;
const HIT_OK = 7100;
const HIT_CANCEL = 7101;
const HIT_SEAL = 7200;

def open_board(target: long, price: long, title: str, hint: str, keep: bool) -> void {
    KIND = K_BOARD;
    TARGET = target;
    CAP = mem.CAP[target];
    PRICE = price;
    TITLE = title;
    HINT = hint;
    N = 0;

    if (keep) {
        let n = mem.text_len(target);
        for i in 0..n {
            if (N < MAXN) {
                BUF[N] = mem.byte_at(target, i);
                N += 1;
            };
        };
    };
    PAL = false;
    PSEL = 0;
    RESULT = 0;
    OPEN = true;
}

def open_seal(cur: long) -> void {
    KIND = K_SEAL;
    TARGET = -1;
    CAP = 2;
    PRICE = 0;
    TITLE = "{holy}The Seal{/}";
    HINT = "Two runes name what Judgment frees.";
    let v = if (cur < 0) { 0 } else { cur & 255 };
    BUF[0] = mem.rune(v >> 4);
    BUF[1] = mem.rune(v);
    N = 2;
    SEL = 0;
    PAL = false;
    RESULT = 0;
    OPEN = true;
}

def close() -> void { OPEN = false; }

def cost() -> long { N * PRICE }

def value() -> long {
    mem.rune_val(BUF[0]) * 16 + mem.rune_val(BUF[1])
}

def can_commit() -> bool {
    if (KIND == K_SEAL) { return true; };
    N > 0 && cost() <= g.COINS
}

def add(b: long) -> void {
    if (N < MAXN) {
        BUF[N] = b;
        N += 1;
        sfx.play(sfx.CHIME, b & 15);
    };
}

def commit() -> void {
    if (!can_commit()) {
        sfx.play(sfx.BLIP, 0);
        return;
    };
    RESULT = 1;
}

def hex_of(k: long) -> long {
    if (k >= '0' && k <= '9') { return k - '0'; };
    if (k >= 'a' && k <= 'f') { return k - 'a' + 10; };
    if (k >= 'A' && k <= 'F') { return k - 'A' + 10; };
    -1
}

def seal_step(d: long) -> void {
    BUF[SEL] = mem.rune(mem.rune_val(BUF[SEL]) + d + 16);
    sfx.play(sfx.CHIME, mem.rune_val(BUF[SEL]));
}

def key(k: long) -> void {
    if (k == input.K_ESC) {
        RESULT = 2;
        return;
    };
    if (KIND == K_SEAL) {
        if (k == input.K_UP || k == 'w') { seal_step(1); return; };
        if (k == input.K_DOWN || k == 's') { seal_step(-1); return; };
        if (k == input.K_LEFT) { SEL = 0; return; };
        if (k == input.K_RIGHT || k == input.K_TAB) { SEL = 1; return; };
        if (k == input.K_ENTER) { commit(); return; };
        let h = hex_of(k);
        if (h >= 0) {
            BUF[SEL] = mem.rune(h);
            sfx.play(sfx.CHIME, h);
            if (SEL == 0) { SEL = 1; };
        };
        return;
    };
    if (k == input.K_TAB) {
        PAL = !PAL;
        return;
    };
    if (k == input.K_BACKSPACE) {
        if (N > 0) { N -= 1; };
        return;
    };
    if (PAL) {
        if (k == input.K_LEFT) { PSEL = (PSEL + 15) & 15; return; };
        if (k == input.K_RIGHT) { PSEL = (PSEL + 1) & 15; return; };
        if (k == input.K_ENTER) { add(mem.rune(PSEL)); return; };
        let h = hex_of(k);
        if (h >= 0) { add(mem.rune(h)); };
        return;
    };
    if (k == input.K_ENTER) {
        commit();
        return;
    };
    if (k >= 32 && k <= 126) { add(k); };
}

def click(id: long) -> void {
    if (id >= HIT_PAL && id < HIT_PAL + 16 && KIND == K_BOARD) {
        PSEL = id - HIT_PAL;
        add(mem.rune(PSEL));
        return;
    };
    if (id >= HIT_PAL && id < HIT_PAL + 16 && KIND == K_SEAL) {
        BUF[SEL] = mem.rune(id - HIT_PAL);
        sfx.play(sfx.CHIME, id - HIT_PAL);
        if (SEL == 0) { SEL = 1; };
        return;
    };
    if (id >= HIT_SEAL && id < HIT_SEAL + 2) { SEL = id - HIT_SEAL; return; };
    if (id == HIT_OK) { commit(); return; };
    if (id == HIT_CANCEL) { RESULT = 2; };
}

def wheel(down: bool) -> void {
    if (KIND == K_SEAL) { seal_step(if (down) { -1 } else { 1 }); };
}

def glyph(b: long) -> long {
    if (mem.is_rune(b)) { return style.RUNE[mem.rune_val(b)]; };
    b
}

def draw_board(x: long, y: long) -> void {
    let wood = 0x7a5a36;
    let ink = 0x1a1208;
    let edge = style.FG[style.GOLD];

    canvas.fill(x, y, CAP, 1, 32, ink, wood, 0);
    for i in 0..N {
        let g1 = glyph(BUF[i]);
        if (i < CAP) {
            canvas.put(x + i, y, g1, ink, wood, canvas.BOLD);
        } else {
            let fg = if (i < CAP + 2) { 0xffb040 } else { 0xff5a4a };
            canvas.put(x + i + 1, y, g1, fg, 0x2a1210, canvas.BOLD);
        };
    };
    canvas.put(x + CAP, y, 0x2503, edge, 0x2a1210, 0);
    if ((text.TIME / 10) % 2 == 0 && N < MAXN) {
        let cx = x + N + (if (N >= CAP) { 1 } else { 0 });
        canvas.put(cx, y, 0x2581, if (N >= CAP) { edge } else { ink }, canvas.KEEP, 0);
    };
}

def draw_palette(x: long, y: long) -> void {
    for i in 0..16 {
        let hot = (PAL && i == PSEL) || ui.HOVER == HIT_PAL + i;
        let st = if (hot) { style.HILITE } else { style.RUNE_S };
        canvas.fill(x + i * 3, y, 3, 1, 32, style.FG[st], style.BG[st], 0);
        canvas.put(x + i * 3 + 1, y, style.RUNE[i], style.FG[st], style.BG[st], 0);
        ui.region(HIT_PAL + i, x + i * 3, y, 3, 1);
    };
}

def draw() -> void {
    if (!OPEN) { return; };
    let w = canvas.W - 4;
    if (w > 72) { w = 72; };
    let h = if (KIND == K_SEAL) { 11 } else { 10 };
    let x = (canvas.W - w) / 2;
    let y = canvas.H - h - 2;
    if (y < 1) { y = 1; };
    ui.shadow(x, y, w, h);
    ui.frame(x, y, w, h, ui.ROUND, style.BOX, style.BOX_EDGE, TITLE);
    text.print(x + 2, y + 1, HINT, style.DIMT);
    if (KIND == K_BOARD) {
        text.VAR_N[5] = CAP;
        text.VAR_N[6] = N;
        text.print(x + 2, y + 3, "{dim}the board holds{/} {n 5}{dim}, you have written{/} {n 6}", style.TEXT);
        draw_board(x + 2, y + 4);
        if (PRICE > 0) {
            text.VAR_N[5] = cost();
            text.VAR_N[6] = g.COINS;
            if (cost() > g.COINS) {
                text.print(x + 2, y + 5, "{red}●{/} {n 5} {dim}coins -- you carry{/} {n 6}", style.TEXT);
            } else {
                text.print(x + 2, y + 5, "{gold}●{/} {n 5} {dim}coins; you carry{/} {n 6}", style.TEXT);
            };
        };
        draw_palette(x + 2, y + 7);
        text.print(x + 2, y + 8, if (PAL) { "{dim}Left/Right choose, Enter writes it, Tab back{/}" } else { "{dim}Tab: runes. Enter: write. Esc: leave it.{/}" }, style.TEXT);
    } else {

        for i in 0..2 {
            let rx = x + w / 2 - 7 + i * 8;
            let hot = SEL == i;
            let st = if (hot) { style.HILITE } else { style.RUNE_S };
            canvas.fill(rx, y + 3, 6, 3, 32, style.FG[st], style.BG[st], 0);
            canvas.put(rx + 2, y + 4, glyph(BUF[i]), style.FG[st], style.BG[st], canvas.BOLD);
            canvas.put(rx + 3, y + 4, 32, style.FG[st], style.BG[st], 0);
            if (hot) {
                canvas.put(rx + 2, y + 3, 0x25B2, style.FG[st], style.BG[st], 0);
                canvas.put(rx + 2, y + 5, 0x25BC, style.FG[st], style.BG[st], 0);
            };
            ui.region(HIT_SEAL + i, rx, y + 3, 6, 3);
        };
        draw_palette(x + 2, y + 7);
        text.print(x + 2, y + 8, "{dim}Up/Down or wheel: change. Left/Right: switch. Enter: cast.{/}", style.TEXT);
    };
    let by = y + h - 2;
    ui.button(HIT_OK, x + w - 22, by, if (KIND == K_SEAL) { "Cast" } else { "Write" }, if (can_commit()) { style.HILITE } else { style.DIMT }, style.GOLD);
    ui.button(HIT_CANCEL, x + w - 11, by, "Cancel", style.TEXT, style.GOLD);
}

export {
    open_board, open_seal, close, key, click, wheel, draw, value, cost,
    BUF, N, OPEN, KIND, TARGET, CAP, RESULT, K_BOARD, K_SEAL
};
