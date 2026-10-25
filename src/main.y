
import term;
import gui;
import game;
import g;
import web;

let av = argv();
let gui_mode = 0;
let want_tty = false;
let i = 1;
while (i < len(av)) {
    let a = av[i];
    if (a == "--window") { gui_mode = 1; };
    if (a == "--tty") { want_tty = true; };
    if (a == "--mute") { g.MUTE = true; };
    if (a == "--ascii-runes") { g.ASCII_RUNES = true; };
    if (a == "--scale" && i + 1 < len(av)) {
        if let long sc = tolong(av[i + 1]) { if (sc >= 1 && sc <= 8) { term.WIN_SCALE = sc; }; };
        i += 1;
    };
    if (a == "--size" && i + 1 < len(av)) {

        let p = av[i + 1].split("x");
        if (len(p) == 2) {
            if let long c = tolong(p[0]) { if (c >= 20 && c <= 256) { term.WIN_COLS = c; }; };
            if let long r = tolong(p[1]) { if (r >= 8 && r <= 128) { term.WIN_ROWS = r; }; };
        };
        i += 1;
    };
    i += 1;
};

if (gui.on_windows()) {
    want_tty = false;
    if (gui_mode == 0) { gui_mode = 1; };
};
if (gui_mode != 0) { term.WINDOW = true; };
if (gui_mode == 0 && !want_tty && !term.is_tty()) {
    gui_mode = 1;
    term.WINDOW = true;
};
term.stderr_to("judgement.log");
if (!term.start()) {
    print("Heavenly Rules needs a terminal or a display.");
    exit(1);
};
// The web page is 100%; let a large window use bigger cells so the title and
// the book stay legible without asking the page to scale pixels.  The game
// keeps at least an 80x24 grid at whatever scale it picks.
if (web.available() && term.WINDOW && term.WIN != none) {
    let c = gui.cols(term.WIN!);
    let r = gui.rows(term.WIN!);
    let s = c / 80;
    if (r / 24 < s) { s = r / 24; };
    if (s > 4) { s = 4; };
    if (s > term.WIN_SCALE) {
        term.WIN_SCALE = s;
        gui.set_scale(term.WIN!, s);
        term.win_fit();
    };
};
gui.set_hard(true);
let code = game.run();
term.quit(code);
