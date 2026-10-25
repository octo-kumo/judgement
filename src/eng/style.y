
import canvas;

const MAX = 64;
let NAME: [str; 64] = [""; 64];
let FG: [long; 64] = [0xe8e0d0; 64];
let BG: [long; 64] = [-3; 64];
let AT: [long; 64] = [0; 64];
let FX: [long; 64] = [0; 64];
let COUNT = 0;

let RUNE: [long; 16] = [0; 16];
let RUNIC: [long; 16] = [
    0x16A0, 0x16A2, 0x16A6, 0x16A8, 0x16B1, 0x16B2, 0x16B7, 0x16B9,
    0x16BA, 0x16BE, 0x16C1, 0x16C3, 0x16C7, 0x16C8, 0x16C9, 0x16CA
];
let ASCII_RUNES: [long; 16] = [
    'o', '-', '=', '^', '+', 'x', '#', '*', '%', '&', '$', '~', '!', '?', '/', '|'
];

let SYMBOLS: [long; 16] = [
    0x25D0, 0x25D1, 0x25D2, 0x25D3, 0x263D, 0x263E, 0x263C, 0x25C8,
    0x2726, 0x2727, 0x2736, 0x2737, 0x2738, 0x2739, 0x273A, 0x273B
];

def use_set(mode: long) -> void {
    for i in 0..16 {
        RUNE[i] = if (mode == 0) { RUNIC[i] } else if (mode == 1) { SYMBOLS[i] } else { ASCII_RUNES[i] };
    };
}

def use_runic(on: bool) -> void {
    for i in 0..16 {
        RUNE[i] = if (on) { RUNIC[i] } else { ASCII_RUNES[i] };
    };
}

def rune_value(cp: long) -> long {
    for i in 0..16 {
        if (RUNE[i] == cp) { return i; };
    };
    -1
}

def def_style(name: str, fg: long, bg: long, at: long, fx: long) -> long {
    let id = find(name);
    if (id < 0) {
        if (COUNT >= MAX) { return 0; };
        id = COUNT;
        COUNT += 1;
    };
    NAME[id] = name;
    FG[id] = fg;
    BG[id] = bg;
    AT[id] = at;
    FX[id] = fx;
    id
}

def find(name: str) -> long {
    for i in 0..COUNT {
        if (NAME[i] == name) { return i; };
    };
    -1
}

def find_range(s: str, from: long, to: long) -> long {
    let n = to - from;
    for i in 0..COUNT {
        let nm = NAME[i];
        if (len(nm) != n) { continue; };
        let ok = true;
        for k in 0..n {
            if (nm[k] != s[from + k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return i; };
    };
    -1
}

const TEXT = 0;
const DIMT = 1;
const GOLD = 2;
const RUNE_S = 3;
const DANGER = 4;
const NAME_S = 5;
const HOLY = 6;
const GLITCH = 7;
const FAINT = 8;
const GOOD = 9;
const BOX = 10;
const BOX_EDGE = 11;
const HILITE = 12;
const TITLE = 13;
const WATER = 14;
const ASH = 15;

def init() -> void {
    COUNT = 0;
    def_style("text", 0xece4d4, canvas.KEEP, 0, 0);
    def_style("dim", 0x9a917f, canvas.KEEP, 0, 0);
    def_style("gold", 0xf2c55c, canvas.KEEP, canvas.BOLD, 0);
    def_style("rune", 0x9fd8ff, canvas.KEEP, canvas.BOLD, 1);
    def_style("red", 0xff6a5a, canvas.KEEP, canvas.BOLD, 0);
    def_style("name", 0xffd9a0, canvas.KEEP, canvas.BOLD, 0);
    def_style("holy", 0xffffff, canvas.KEEP, canvas.BOLD, 1);
    def_style("glitch", 0xffffff, canvas.KEEP, canvas.BOLD, 2);
    def_style("faint", 0x8a8478, canvas.KEEP, canvas.ITALIC, 3);
    def_style("green", 0x9be08a, canvas.KEEP, 0, 0);
    def_style("box", 0xece4d4, 0x2a2219, 0, 0);
    def_style("edge", 0xb89a6a, 0x2a2219, 0, 0);
    def_style("hi", 0x1c140c, 0xf2c55c, canvas.BOLD, 0);
    def_style("title", 0xfff4dc, canvas.KEEP, canvas.BOLD, 0);
    def_style("water", 0x7fc4e8, canvas.KEEP, 0, 0);
    def_style("ash", 0x6f6a64, canvas.KEEP, canvas.ITALIC, 0);
    def_style("i", 0xece4d4, canvas.KEEP, canvas.ITALIC, 0);
    def_style("b", 0xffffff, canvas.KEEP, canvas.BOLD, 0);

    def_style("kw", 0xd49bf0, canvas.KEEP, canvas.BOLD, 0);
    def_style("fn", 0x6fc0ff, canvas.KEEP, 0, 0);
    def_style("str", 0xa6e08a, canvas.KEEP, 0, 0);
    def_style("num", 0xf0a868, canvas.KEEP, 0, 0);
    def_style("cm", 0x7f8a8e, canvas.KEEP, canvas.ITALIC, 0);
    def_style("op", 0x8a94a8, canvas.KEEP, 0, 0);
    use_runic(true);
}

export {
    init, def_style, find, find_range, use_runic, use_set, rune_value,
    NAME, FG, BG, AT, FX, RUNE, COUNT,
    TEXT, DIMT, GOLD, RUNE_S, DANGER, NAME_S, HOLY, GLITCH, FAINT, GOOD, BOX,
    BOX_EDGE, HILITE, TITLE, WATER, ASH
};
