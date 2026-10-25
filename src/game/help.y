
import g;
import canvas;
import style;
import text;
import ui;
import input;
import sfx;
import dlg;
import logo;

let OPEN = false;
let N_DESC = -1;
let HIT_CLOSE = 8100;
let LINE = "";

def bind() -> void {
    N_DESC = dlg.node_id("help.desc");
    LINE = " ".repeat(dlg.span_cap());
}

def open() -> void {
    OPEN = true;
    sfx.play(sfx.BLIP, 0);
}

def close() -> void { OPEN = false; }

def key(k: long) -> void {
    if (k == 'h' || k == 'H' || k == input.K_ESC || k == input.K_ENTER || k == ' ') {
        close();
    };
}

def click(id: long) -> void { close(); }

def desc(cx: long, y: long) -> void {
    let n = dlg.pick(N_DESC);
    if (n < 0) { return; };
    for i in 0..dlg.N_LN[n] {
        let l = dlg.N_L0[n] + i;
        let len = dlg.open_span(dlg.L_S[l], dlg.L_E[l], LINE);
        let w = text.width_range(LINE, 0, len);
        text.print_range(cx - w / 2, y + i, LINE, 0, len, style.DIMT);
    };
}

def row(x: long, y: long, keys: str, what: str) -> void {
    text.print(x, y, keys, style.TEXT);
    text.print(x + 16, y, what, style.TEXT);
}

def draw() -> void {
    if (!OPEN) { return; };
    canvas.fade_all(0x000000, 150);
    let w = 56;
    let h = 25;
    if (w > canvas.W - 2) { w = canvas.W - 2; };
    if (h > canvas.H - 1) { h = canvas.H - 1; };
    let x = (canvas.W - w) / 2;
    let y = (canvas.H - h) / 2;
    ui.shadow(x, y, w, h);
    ui.frame(x, y, w, h, ui.ROUND, style.BOX, style.BOX_EDGE, "");
    let cx = x + w / 2;
    logo.draw(cx - logo.width() / 2, y + 2);
    desc(cx, y + 6);
    let ky = y + 9;
    let kx = x + 5;
    row(kx, ky, "{gold}arrows  WASD{/}", "walk (or click the ground)");
    row(kx, ky + 1, "{gold}E  Enter{/}", "talk, use, look");
    row(kx, ky + 2, "{gold}Space{/}", "swing your blade");
    row(kx, ky + 3, "{gold}C{/}", "dodge");
    row(kx, ky + 10, "{gold}F{/}", "hold: hurry the day along");
    row(kx, ky + 4, "{gold}J{/}", "Judgment (or right-click)");
    if (g.has(g.F_SEAL_EDIT) && g.LOOP >= 2) { row(kx, ky + 5, "{gold}K{/}", "change the seal"); };
    if (g.has(g.F_BOOK_LENT)) { row(kx, ky + 6, "{gold}B{/}", "the Book of Names"); };
    row(kx, ky + 7, "{gold}Tab{/}", "in a writing field: the runes");
    row(kx, ky + 8, "{gold}H{/}", "this page");
    row(kx, ky + 9, "{gold}Q{/}", "quit");
    text.print(cx - 12, y + h - 2, "{dim}press H to go back{/}", style.TEXT);
    ui.region(HIT_CLOSE, x, y, w, h);
}

export { open, close, key, click, draw, bind, OPEN };
