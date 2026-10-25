
import g;
import canvas;
import style;
import text;
import ui;
import input;
import sfx;
import logo;
import save;

let ACTIVE = false;
let SCREEN = 0;
let SEL = 0;
let RESULT = 0;

const HIT_MAIN = 8000;
const HIT_SET = 8010;

def open() -> void {
    ACTIVE = true;
    SCREEN = 0;
    SEL = 0;
    RESULT = 0;
}

def count() -> long {
    if (SCREEN == 0) { return 3; };
    if (SCREEN == 1) { return 4; };
    0
}

def toggle_sound() -> void {
    g.MUTE = !g.MUTE;

    if (!g.MUTE) { sfx.start(true); };
    sfx.mute(g.MUTE);
}

def toggle_runes() -> void {
    g.RUNE_MODE = (g.RUNE_MODE + 1) % 3;
    g.ASCII_RUNES = g.RUNE_MODE == 2;
    style.use_set(g.RUNE_MODE);
    save.write_setting("runes", if (g.RUNE_MODE == 0) { "runic" } else if (g.RUNE_MODE == 1) { "symbols" } else { "ascii" });
}

def pick(i: long) -> void {
    sfx.play(sfx.BLIP, 0);
    if (SCREEN == 0) {
        if (i == 0) { RESULT = 1; };
        if (i == 1) {
            SCREEN = 1;
            SEL = 0;
        };
        if (i == 2) { RESULT = 2; };
        return;
    };
    if (SCREEN == 1) {
        if (i == 0) { toggle_sound(); };
        if (i == 1) { toggle_runes(); };
        if (i == 2) { SCREEN = 2; };
        if (i == 3) {
            SCREEN = 0;
            SEL = 1;
        };
    };
}

def key(k: long) -> void {
    if (SCREEN == 2) {
        SCREEN = 1;
        SEL = 2;
        return;
    };
    let n = count();
    if (k == input.K_UP || k == 'w' || k == 'W') { SEL = (SEL + n - 1) % n; return; };
    if (k == input.K_DOWN || k == 's' || k == 'S') { SEL = (SEL + 1) % n; return; };
    if (k == input.K_ENTER || k == ' ' || k == 'e' || k == 'E') { pick(SEL); return; };
    if (k == input.K_ESC) {
        if (SCREEN == 0) { RESULT = 1; } else { SCREEN = 0; SEL = 1; };
        return;
    };
    if (k == 'q' && SCREEN == 0) { RESULT = 2; };
}

def click(id: long) -> void {
    if (SCREEN == 2) {
        SCREEN = 1;
        return;
    };
    if (SCREEN == 0 && id >= HIT_MAIN && id < HIT_MAIN + 3) { pick(id - HIT_MAIN); };
    if (SCREEN == 1 && id >= HIT_SET && id < HIT_SET + 4) { pick(id - HIT_SET); };
}

def item(id: long, x: long, y: long, w: long, label: str, hot: bool) -> void {
    let st = if (hot || ui.HOVER == id) { style.HILITE } else { style.TEXT };
    canvas.fill(x, y, w, 1, 32, style.FG[st], style.BG[st], 0);
    text.print(x + 2, y, label, st);
    ui.region(id, x, y, w, 1);
}

def draw() -> void {
    if (!ACTIVE) { return; };
    canvas.fill(0, 0, canvas.W, canvas.H, 32, 0xffffff, 0x000000, 0);
    let w = 41;
    let h = 13;
    let x = (canvas.W - w) / 2;
    let y = (canvas.H - h) / 2;
    ui.frame(x, y, w, h, ui.ROUND, style.BOX, style.BOX_EDGE, "");
    logo.draw(x + (w - logo.width()) / 2, y + 1);
    if (SCREEN == 0) {
        text.print(x + 3, y + 5, "{dim}The bell will ring at six.{/}", style.TEXT);
        item(HIT_MAIN, x + 3, y + 7, w - 6, "Continue", SEL == 0);
        item(HIT_MAIN + 1, x + 3, y + 8, w - 6, "Settings", SEL == 1);
        item(HIT_MAIN + 2, x + 3, y + 9, w - 6, "Quit", SEL == 2);
    } else if (SCREEN == 1) {
        item(HIT_SET, x + 3, y + 5, w - 6, if (g.MUTE) { "Sound: off" } else { "Sound: on" }, SEL == 0);
        item(HIT_SET + 1, x + 3, y + 6, w - 6, if (g.RUNE_MODE == 2) { "Runes: ASCII" } else if (g.RUNE_MODE == 1) { "Runes: moons and stars" } else { "Runes: runic" }, SEL == 1);
        item(HIT_SET + 2, x + 3, y + 7, w - 6, "The keys", SEL == 2);
        item(HIT_SET + 3, x + 3, y + 9, w - 6, "Back", SEL == 3);
    } else {
        text.print(x + 3, y + 5, "{gold}Arrows / WASD{/}  walk", style.TEXT);
        text.print(x + 3, y + 6, "{gold}E / Enter{/}      talk, use", style.TEXT);
        text.print(x + 3, y + 7, "{gold}Space{/}  swing   {gold}C{/}  dodge", style.TEXT);
        text.print(x + 3, y + 8, "{gold}J{/}  Judgment    {gold}K{/}  the seal", style.TEXT);
        text.print(x + 3, y + 9, "{gold}B{/}  the Book    {gold}Q{/}  quit", style.TEXT);
        text.print(x + 3, y + 10, "{dim}Or click: ground, people, choices.{/}", style.TEXT);
        text.print(x + 3, y + 11, "{dim}any key: back{/}", style.TEXT);
    };
}

export { open, key, click, draw, ACTIVE, RESULT };
