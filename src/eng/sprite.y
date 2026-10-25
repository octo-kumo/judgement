
import canvas;
import pix;
import r3d;
import style;
import text;

const MAXS = 96;
let S_W: [long; 96] = [0; 96];
let S_H: [long; 96] = [0; 96];
let S_FR: [long; 96] = [0; 96];
let S_C0: [long; 96] = [0; 96];
let S_NS: [long; 96] = [0; 96];
let S_NE: [long; 96] = [0; 96];
let NS = 0;

const MAXCELL = 16384;
let C_CP: [long; 16384] = [0; 16384];
let C_COL: [long; 16384] = [0; 16384];
let NC = 0;

let KEYC: [long; 128] = [-1; 128];
let SRC = "";
let NUM_END = 0;

let LAST_X = 0;
let LAST_Y = 0;
let LAST_W = 0;
let LAST_H = 0;
let LAST_VIS = false;
let LAST_D = 0;

def hexd(c: long) -> long {
    if (c >= '0' && c <= '9') { return c - '0'; };
    if (c >= 'a' && c <= 'f') { return c - 'a' + 10; };
    if (c >= 'A' && c <= 'F') { return c - 'A' + 10; };
    0
}

let DL = 1;
def cp_at(i: long) -> long {
    let b = SRC[i];
    if (b < 128) { DL = 1; return b; };
    if (b < 224) { DL = 2; return ((b & 31) << 6) | (SRC[i + 1] & 63); };
    if (b < 240) {
        DL = 3;
        return ((b & 15) << 12) | ((SRC[i + 1] & 63) << 6) | (SRC[i + 2] & 63);
    };
    DL = 4;
    ((b & 7) << 18) | ((SRC[i + 1] & 63) << 12) | ((SRC[i + 2] & 63) << 6) | (SRC[i + 3] & 63)
}

def line_end(i: long) -> long {
    let j = i;
    while (j < len(SRC) && SRC[j] != 10) { j += 1; };
    j
}

def starts(i: long, s: str) -> bool {
    if (i + len(s) > len(SRC)) { return false; };
    for k in 0..len(s) {
        if (SRC[i + k] != s[k]) { return false; };
    };
    true
}

def int_at(i: long) -> long {
    let j = i;
    let v = 0;
    while (j < len(SRC) && SRC[j] >= '0' && SRC[j] <= '9') {
        v = v * 10 + (SRC[j] - '0');
        j += 1;
    };
    NUM_END = j;
    v
}

def load(src: str) -> void {
    SRC = src;
    NS = 0;
    NC = 0;
    let i = 0;
    let cur = -1;
    let row = 0;
    while (i < len(SRC)) {
        let e = line_end(i);
        if (e == i || SRC[i] == '#') {
            i = e + 1;
            continue;
        };
        if (starts(i, "key ")) {
            let k = SRC[i + 4];
            let v = 0;
            for j in (i + 6)..(i + 12) { v = v * 16 + hexd(SRC[j]); };
            KEYC[k & 127] = v;
        } else if (starts(i, "sprite ")) {
            if (NS < MAXS) {
                cur = NS;
                NS += 1;
                let j = i + 7;
                S_NS[cur] = j;
                while (SRC[j] != ' ') { j += 1; };
                S_NE[cur] = j;
                S_W[cur] = int_at(j + 1);
                S_H[cur] = int_at(NUM_END + 1);
                S_FR[cur] = 1;
                S_C0[cur] = NC;
                row = 0;
            };
        } else if (starts(i, "frame")) {
            if (cur >= 0) {
                S_FR[cur] += 1;
                row = 0;
            };
        } else if (starts(i, "end")) {
            cur = -1;
        } else if (cur >= 0 && row < S_H[cur]) {

            let w = S_W[cur];
            let base = S_C0[cur] + ((S_FR[cur] - 1) * S_H[cur] + row) * w;
            let j = i;
            for x in 0..w {
                if (base + x < MAXCELL) { C_CP[base + x] = cp_at(j); };
                j += DL;
            };
            while (j < e && SRC[j] != '|') { j += 1; };
            j += 1;
            for x in 0..w {
                let k = if (j < e) { SRC[j] } else { '.' };
                if (base + x < MAXCELL) {
                    C_COL[base + x] = if (k == '.') { -1 } else { KEYC[k & 127] };
                };
                j += 1;
            };
            row += 1;
            let used = base + w;
            if (used > NC) { NC = used; };
        };
        i = e + 1;
    };
}

def id(name: str) -> long {
    for s in 0..NS {
        let n = S_NE[s] - S_NS[s];
        if (n != len(name)) { continue; };
        let ok = true;
        for k in 0..n {
            if (SRC[S_NS[s] + k] != name[k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return s; };
    };
    -1
}

const DEPTH_BIAS = 1500;

def draw(s: long, f: long, x: long, y: long, z: long, recol: long, fade: long) -> bool {
    LAST_VIS = false;
    if (s < 0 || s >= NS) { return false; };
    r3d.project(x, y, z);
    let d = r3d.PD - DEPTH_BIAS;
    LAST_D = d;
    let w = S_W[s];
    let h = S_H[s];
    let cx = r3d.PX - w / 2;
    let cy = r3d.PY / 2 - h + 1;
    LAST_X = cx;
    LAST_Y = cy;
    LAST_W = w;
    LAST_H = h;
    let fr = f % S_FR[s];
    let base = S_C0[s] + fr * h * w;
    let any = false;
    for row in 0..h {
        for col in 0..w {
            let k = base + row * w + col;
            let c = C_COL[k];
            if (c < 0) { continue; };
            let px = cx + col;
            let py = cy + row;
            if (!canvas.inside(px, py)) { continue; };
            if (d > pix.cell_depth(px, py)) { continue; };
            let bg = pix.cell_color(px, py);
            let fg = if (recol >= 0) { recol } else { r3d.lit_sprite(c) };
            if (fade > 0) { fg = canvas.mixc(fg, bg, fade); };
            canvas.put(px, py, C_CP[k], fg, bg, canvas.BOLD);
            any = true;
        };
    };
    LAST_VIS = any;
    any
}

def label(x: long, y: long, z: long, up: long, s: str, st: long, occlude: bool) -> void {
    r3d.project(x, y, z);
    let w = text.width(s);
    let cx = r3d.PX - w / 2;
    let cy = r3d.PY / 2 - up;
    if (occlude && r3d.PD - DEPTH_BIAS > pix.cell_depth(r3d.PX, r3d.PY / 2)) { return; };
    text.print(cx, cy, s, st);
}

def width(s: long) -> long { if (s >= 0 && s < NS) { S_W[s] } else { 0 } }
def height(s: long) -> long { if (s >= 0 && s < NS) { S_H[s] } else { 0 } }
def frames(s: long) -> long { if (s >= 0 && s < NS) { S_FR[s] } else { 1 } }

export {
    load, id, draw, label, width, height, frames, DEPTH_BIAS,
    LAST_X, LAST_Y, LAST_W, LAST_H, LAST_VIS, LAST_D
};
