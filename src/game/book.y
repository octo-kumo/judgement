
import mem;
import g;
import canvas;
import style;
import text;
import ui;
import input;
import act;
import sfx;

let OPEN = false;
let PAGE = 0;
const NPAGES = 6;
let SCROLL = 0;

let SEEN_REF: [long; 256] = [-1; 256];
let SEEN_TAG: [long; 256] = [0; 256];
let MOVED: [long; 256] = [0; 256];

def page_title(p: long) -> str {
    if (p == 0) { return "The First Page"; };
    if (p == 1) { return "The Living"; };
    if (p == 2) { return "Those Who Hold"; };
    if (p == 3) { return "The Sight"; };
    if (p == 4) { return "Things Written"; };
    "Those Who Act"
}

def page_lo(p: long) -> long {
    if (p == 0) { return 0x60; };
    if (p == 1) { return 0x60; };
    if (p == 2) { return 0x20; };
    if (p == 3) { return 0x40; };
    if (p == 4) { return 0x80; };
    0x10
}

def page_hi(p: long) -> long {
    if (p == 0) { return 0x60; };
    if (p == 1) { return 0x8F; };
    if (p == 2) { return 0x3F; };
    if (p == 3) { return 0x5F; };
    if (p == 4) { return 0xDF; };
    0x1F
}

def open_book() -> void {
    OPEN = true;
    SCROLL = 0;
    g.set(g.F_BOOK);
    sfx.play(sfx.CHIME, 3);
}

def close() -> void { OPEN = false; }

def watch() -> void {
    for a in 0x60..0x80 {
        let live = mem.LIVE[a];
        let t = mem.TAG[a];
        let r = mem.REF[a];
        if (live && t == mem.T_NPC) {

            for b in 0x60..0x80 {
                if (b != a && SEEN_TAG[b] == mem.T_NPC && SEEN_REF[b] == r) {
                    MOVED[a] = 90;
                    SEEN_TAG[b] = 0;
                    SEEN_REF[b] = -1;
                    if (!g.has(g.F_REALLOC)) {
                        g.set(g.F_REALLOC);
                        g.emit(g.EV_TOAST, 1, a);
                    };
                };
            };
        };
    };
    for a in 0x60..0x80 {
        if (mem.LIVE[a]) {
            SEEN_TAG[a] = mem.TAG[a];
            SEEN_REF[a] = mem.REF[a];
        };
        if (MOVED[a] > 0) { MOVED[a] -= 1; };
    };
}

def key(k: long) -> bool {
    if (!OPEN) { return false; };
    if (k == input.K_ESC || k == 'b' || k == 'B' || k == 'q') {
        close();
        return true;
    };
    if (k == input.K_RIGHT || k == 'd' || k == input.K_TAB) {
        PAGE = (PAGE + 1) % NPAGES;
        SCROLL = 0;
        sfx.play(sfx.BLIP, 0);
    };
    if (k == input.K_LEFT || k == 'a' || k == input.K_BACKTAB) {
        PAGE = (PAGE + NPAGES - 1) % NPAGES;
        SCROLL = 0;
        sfx.play(sfx.BLIP, 0);
    };
    if (k == input.K_DOWN || k == 's') { SCROLL += 1; };
    if (k == input.K_UP || k == 'w') { if (SCROLL > 0) { SCROLL -= 1; }; };
    true
}

const HIT_TAB = 6000;
let HIT_CLOSE = 6100;

def click(id: long) -> void {
    if (id >= HIT_TAB && id < HIT_TAB + NPAGES) {
        PAGE = id - HIT_TAB;
        SCROLL = 0;
        sfx.play(sfx.BLIP, 0);
    };
    if (id == HIT_CLOSE) { close(); };
}

def wheel(down: bool) -> void {
    if (down) { SCROLL += 1; } else if (SCROLL > 0) { SCROLL -= 1; };
}

def entry(x: long, y: long, a: long, w: long) -> void {
    let st = if (MOVED[a] > 0) { style.GOLD } else { style.TEXT };
    text.runes(x, y, a, style.RUNE_S);
    canvas.put(x + 2, y, 0x2500, style.FG[style.DIMT], canvas.KEEP, 0);
    act.stage_text(a);
    if (text.XB_N == 0) {
        text.print(x + 4, y, "{dim}(blank){/}", st);
    } else {
        text.print(x + 4, y, "{x}", st);
    };
}

def draw() -> void {
    if (!OPEN) { return; };
    watch();
    let w = 56;
    if (w > canvas.W - 4) { w = canvas.W - 4; };
    let h = canvas.H - 4;
    if (h > 26) { h = 26; };
    let x = (canvas.W - w) / 2;
    let y = (canvas.H - h) / 2;
    ui.shadow(x, y, w, h);
    ui.frame(x, y, w, h, ui.DOUBLE, style.BOX, style.BOX_EDGE, "{gold}The Book of Names{/}");

    let tx = x + 2;
    for p in 0..NPAGES {
        let hot = p == PAGE;
        let st = if (hot) { style.HILITE } else { style.DIMT };
        canvas.fill(tx, y + 1, 3, 1, 32, style.FG[st], if (hot) { style.BG[style.HILITE] } else { canvas.KEEP }, 0);
        canvas.put(tx + 1, y + 1, '1' + p, style.FG[st], canvas.KEEP, canvas.BOLD);
        ui.region(HIT_TAB + p, tx, y + 1, 3, 1);
        tx += 4;
    };
    text.print(tx + 1, y + 1, page_title(PAGE), style.TITLE);
    let row = y + 3;
    let bottom = y + h - 2;
    if (PAGE == 0) {
        text.print(x + 3, row, "{dim}Every name the heavens hold begins here.{/}", style.TEXT);
        row += 2;
        entry(x + 3, row, mem.A_PLAYER, w);
        row += 2;
        text.print(x + 3, row, "{dim}Count the apples to read the numbers.{/}", style.TEXT);
    } else if (PAGE == 5 && !g.has(g.F_SAW13)) {

        text.print(x + 3, row, "{faint}The ink on this page will not settle.{/}", style.TEXT);
    } else {
        let lo = page_lo(PAGE);
        let hi = page_hi(PAGE);
        let shown = 0;
        let skipped = 0;
        for a in lo..(hi + 1) {
            if (!mem.LIVE[a]) { continue; };
            if (a == mem.A_PLAYER && PAGE == 1) { continue; };
            if (skipped < SCROLL) {
                skipped += 1;
                continue;
            };
            if (row >= bottom) { break; };
            entry(x + 3, row, a, w);
            if (PAGE == 5 && a == mem.A_HAND) {

                row += 1;
                act.stage_slot(a, mem.CODE_LEN, true);
                text.print(x + 7, row, "{x}", style.RUNE_S);
                g.set(g.F_HAND_READ);
                g.set(g.F_FOUND13);
                g.set(g.F_SEAL_EDIT);
            };
            row += 1;
            shown += 1;
        };
        if (shown == 0) {
            text.print(x + 3, row, "{dim}(nothing is written here){/}", style.TEXT);
        };
    };
    text.print(x + 2, y + h - 1, " {gold}A{/}/{gold}D{/} pages  {gold}Esc{/} close ", style.DIMT);
    ui.region(HIT_CLOSE, x + w - 4, y, 3, 1);
    canvas.put(x + w - 3, y, 'x', style.FG[style.GOLD], canvas.KEEP, canvas.BOLD);
}

export { open_book, close, key, click, wheel, draw, watch, OPEN, PAGE };
