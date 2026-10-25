
import canvas;

let GLYPH: [str; 24] = [
    "  #", "  #", "^^^",
    "# #", "# #", "^^^",
    "##_", "# #", "##^",
    "#^^", "# _", "^^^",
    "#^^", "##^", "#__",
    "#_#", "#^#", "# #",
    "#^_", "# #", "# #",
    "^#^", " # ", " # "
];

let DIG: [str; 33] = [
    "###", "# #", "###",
    "_#_", " # ", "_#_",
    "##^", "_^^", "###",
    "##^", " ^#", "##_",
    "# #", "###", "  #",
    "###", "##_", "__#",
    "#^^", "###", "###",
    "###", "  #", "  #",
    "###", "^#^", "###",
    "###", "###", "  #",
    "   ", " ^ ", " ^ "
];

let ORDER: [long; 9] = [0, 1, 2, 3, 4, 5, 4, 6, 7];

const TOP = 0xffe9a0;
const MID = 0xf2a04a;
const LOW = 0xc04a3a;

def width() -> long { 35 }

def block(c: long) -> long {
    if (c == '#') { return 0x2588; };
    if (c == '^') { return 0x2580; };
    if (c == '_') { return 0x2584; };
    32
}

def draw(x: long, y: long) -> void {
    for l in 0..9 {
        let g = ORDER[l] * 3;
        for r in 0..3 {
            let base = if (r == 0) { TOP } else if (r == 1) { MID } else { LOW };
            let col = canvas.mixc(base, LOW, l * 10);
            let s = GLYPH[g + r];
            for c in 0..3 {
                let cp = block(s[c]);
                if (cp != 32) { canvas.put(x + l * 4 + c, y + r, cp, col, canvas.KEEP, canvas.BOLD); };
            };
        };
    };
}

def digit(x: long, y: long, d: long, col: long) -> void {
    for r in 0..3 {
        let s = DIG[d * 3 + r];
        for c in 0..3 {
            let cp = block(s[c]);
            if (cp != 32) { canvas.put(x + c, y + r, cp, col, canvas.KEEP, canvas.BOLD); };
        };
    };
}

export { draw, width, digit };
