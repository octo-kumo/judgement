
import canvas;
import pix;
import r3d;

let MAXP = 64;
let P_NS: [long; 64] = [0; 64];
let P_NE: [long; 64] = [0; 64];
let P_W: [long; 64] = [0; 64];
let P_H: [long; 64] = [0; 64];
let P_NV: [long; 64] = [1; 64];
let P_NF: [long; 64] = [1; 64];
let P_C0: [long; 64] = [0; 64];
let P_ACTOR: [bool; 64] = [false; 64];
let P_SK: [long; 64] = [0; 64];
let P_HA: [long; 64] = [0; 64];
let P_CO: [long; 64] = [0; 64];
let P_TR: [long; 64] = [0; 64];
let P_LE: [long; 64] = [0; 64];
let P_FL: [long; 64] = [0; 64];
let P_OUT: [long; 64] = [0; 64];
let NP = 0;

let STORE: [long; 400000] = [-1; 400000];
let NSTORE = 0;

let KEYC: [long; 128] = [-1; 128];
let SRC = "";
let NUM_END = 0;

const F_LONG = 1;
const F_BUN = 2;
const F_BALD = 4;
const F_HOOD = 8;
const F_CAP = 16;
const F_STRAW = 32;
const F_BEARD = 64;
const F_APRON = 128;
const F_CLOAK = 256;
const F_CHILD = 512;
const F_STOOP = 1024;
const F_STAFF = 2048;
const F_BAND = 4096;

const OUTLINE = 0x1d1a22;
const SHOE = 0x2a2018;
const EYE = 0x2a2030;

let WORK: [long; 1024] = [-1; 1024];
let WAW = 8;
let WAH = 12;

let LAST_X = 0;
let LAST_Y = 0;
let LAST_W = 0;
let LAST_H = 0;
let LAST_VIS = false;

def hexd(c: long) -> long {
    if (c >= '0' && c <= '9') { return c - '0'; };
    if (c >= 'a' && c <= 'f') { return c - 'a' + 10; };
    if (c >= 'A' && c <= 'F') { return c - 'A' + 10; };
    0
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

def word_end(i: long, e: long) -> long {
    let j = i;
    while (j < e && SRC[j] > 32) { j += 1; };
    j
}

def skip_sp(i: long, e: long) -> long {
    let j = i;
    while (j < e && (SRC[j] == ' ' || SRC[j] == 9)) { j += 1; };
    j
}

def word_is(a: long, b: long, s: str) -> bool {
    if (b - a != len(s)) { return false; };
    for k in 0..len(s) {
        if (SRC[a + k] != s[k]) { return false; };
    };
    true
}

def key_col(c: long) -> long { KEYC[c & 127] }

def work_clear() -> void {
    for i in 0..1024 { WORK[i] = -1; };
}

def work_at(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= WAW || y >= WAH) { return -1; };
    WORK[y * 32 + x]
}

def wpx(x: long, y: long, c: long) -> void {
    if (x < 0 || y < 0 || x >= WAW || y >= WAH) { return; };
    WORK[y * 32 + x] = c;
}

def wrect(x: long, y: long, w: long, h: long, c: long) -> void {
    for yy in y..(y + h) {
        for xx in x..(x + w) { wpx(xx, yy, c); };
    };
}

def commit(base: long, outline: long) -> void {
    let w = WAW + 2;
    let h = WAH + 2;
    for y in 0..h {
        for x in 0..w {
            let c = work_at(x - 1, y - 1);
            if (c < 0 && outline >= 0) {
                if (work_at(x - 2, y - 1) >= 0 || work_at(x, y - 1) >= 0 || work_at(x - 1, y - 2) >= 0 || work_at(x - 1, y) >= 0) {
                    c = outline;
                };
            };
            if (base + y * w + x < 400000) { STORE[base + y * w + x] = c; };
        };
    };
}

let D_SK = 0;
let D_HA = 0;
let D_CO = 0;
let D_TR = 0;
let D_LE = 0;
let D_FL = 0;

def hasf(f: long) -> bool { (D_FL & f) != 0 }

def dark(c: long, t: long) -> long { canvas.mixc(c, 0x000000, t) }
def pale(c: long, t: long) -> long { canvas.mixc(c, 0xffffff, t) }

def doll_legs(view: long, frame: long, top: long) -> void {
    let le = D_LE;
    let lift_r = frame == 1;
    let lift_l = frame == 3;
    if (view == 2) {

        if (frame == 1) {
            wrect(2, top, 2, 11 - top, le);
            wpx(2, 10, SHOE);
            wpx(3, 10, SHOE);
            wrect(4, top, 2, 12 - top, le);
            wrect(4, 11, 3, 1, SHOE);
        } else if (frame == 3) {
            wrect(4, top, 2, 11 - top, le);
            wpx(4, 10, SHOE);
            wpx(5, 10, SHOE);
            wrect(2, top, 2, 12 - top, le);
            wrect(2, 11, 2, 1, SHOE);
        } else {
            wrect(3, top, 2, 12 - top, le);
            wrect(3, 11, 3, 1, SHOE);
        };
        return;
    };
    let last_l = if (lift_l) { 10 } else { 11 };
    let last_r = if (lift_r) { 10 } else { 11 };
    wrect(2, top, 2, last_l + 1 - top, le);
    wrect(4, top, 2, last_r + 1 - top, le);
    if (last_l >= top) { wrect(2, last_l, 2, 1, SHOE); };
    if (last_r >= top) { wrect(4, last_r, 2, 1, SHOE); };
}

def doll_torso(view: long, frame: long, ty: long, th: long) -> void {
    let co = D_CO;
    let back = view == 3 || view == 4;
    for r in 0..th {
        wrect(2, ty + r, 4, 1, if (r < 2) { co } else { dark(co, 22) });
    };
    if (hasf(F_CLOAK)) {

        for y in (ty + th)..11 { wrect(1, y, 6, 1, if (y < 10) { dark(co, 22) } else { D_TR }); };
        if (view == 2) {
            for y in (ty + th)..11 { wpx(1, y, -1); wpx(6, y, -1); };
        };
        if (frame == 1 || frame == 3) { wrect(if (frame == 1) { 4 } else { 2 }, 11, 2, 1, SHOE); } else { wrect(2, 11, 4, 1, SHOE); };
        wpx(3, 11, SHOE);
        wpx(4, 11, SHOE);
    };
    if (back) { return; };
    if (hasf(F_APRON)) {
        let ax = if (view == 2) { 4 } else { 2 };
        let aw = if (view == 2) { 2 } else { 4 };
        wrect(ax, ty + th - 2, aw, 2, D_TR);
        if (!hasf(F_CLOAK)) { wrect(ax, ty + th, aw, 1, pale(D_TR, 20)); };
    } else if (D_TR != D_CO && view != 2) {
        wrect(2, ty + th - 1, 4, 1, D_TR);
    };
    if (view != 2) { wrect(3, ty, 2, 1, D_TR); };
}

def doll_arms(view: long, frame: long, ty: long, th: long, swing: bool) -> void {
    let sleeve = dark(D_CO, 30);
    if (view == 2) {
        let ax = if (frame == 1) { 4 } else if (frame == 3) { 2 } else { 3 };
        wrect(ax, ty + 1, 2, th - 2, sleeve);
        wpx(ax, ty + th - 1, D_SK);
        wpx(ax + 1, ty + th - 1, D_SK);
        if (swing) {
            wrect(5, ty - 1, 2, 2, sleeve);
            wpx(6, ty - 2, D_SK);
        };
    } else {
        let off_l = if (frame == 1) { -1 } else if (frame == 3) { 1 } else { 0 };
        let off_r = 0 - off_l;
        wrect(1, ty + 1 + off_l, 1, th - 2, sleeve);
        wpx(1, ty + th - 1 + off_l, D_SK);
        if (swing) {
            wrect(6, ty, 1, 2, sleeve);
            wpx(6, ty - 1, D_SK);
        } else {
            wrect(6, ty + 1 + off_r, 1, th - 2, sleeve);
            wpx(6, ty + th - 1 + off_r, D_SK);
        };
    };
    if (swing) {

        wpx(7, ty - 1, 0xe8c45a);
        wrect(7, ty - 4, 1, 3, 0xe6e8f0);
        if (view == 2) { wpx(7, ty - 2, 0xe8c45a); };
    };
}

def doll_head(view: long, hy: long) -> void {
    let sk = D_SK;
    let ha = D_HA;
    let bald = hasf(F_BALD);
    let hood = hasf(F_HOOD);
    let long_hair = hasf(F_LONG);
    let face_x = if (hood) { 2 } else { 1 };
    let face_w = if (hood) { 4 } else { 6 };

    wrect(face_x, hy + 1, face_w, 4, sk);
    if (view == 2) { wrect(1, hy + 1, 6, 4, sk); };
    if (hood) {

        let hc = D_CO;
        wrect(2, hy, 4, 1, hc);
        wrect(1, hy + 1, 6, 1, hc);
        wrect(1, hy + 2, 1, 3, hc);
        wrect(6, hy + 2, 1, 3, hc);
        if (view == 3 || view == 4) { wrect(1, hy + 1, 6, 4, hc); };
        if (view == 2) { wrect(1, hy + 1, 3, 4, hc); wrect(4, hy + 1, 3, 1, hc); };
    };

    if (!hood) {
        if (view == 0) {
            if (!bald) { wrect(1, hy + 1, 6, 1, ha); };
            wpx(1, hy + 2, ha);
            wpx(6, hy + 2, ha);
            if (long_hair) { wrect(1, hy + 3, 1, 3, ha); wrect(6, hy + 3, 1, 3, ha); };
        } else if (view == 1) {
            if (!bald) { wrect(1, hy + 1, 6, 1, ha); };
            wrect(1, hy + 2, 2, 3, ha);
            wpx(6, hy + 2, ha);
            if (long_hair) { wrect(1, hy + 3, 2, 3, ha); };
        } else if (view == 2) {
            if (!bald) { wrect(1, hy + 1, 6, 1, ha); };
            wrect(1, hy + 2, 3, 3, ha);
            if (long_hair) { wrect(1, hy + 2, 2, 5, ha); };
        } else if (view == 3) {
            wrect(1, hy + 1, 6, 4, if (bald) { sk } else { ha });
            wrect(6, hy + 3, 1, 2, sk);
            if (long_hair) { wrect(1, hy + 5, 5, 2, ha); };
        } else {
            wrect(1, hy + 1, 6, 4, if (bald) { sk } else { ha });
            if (bald) { wrect(1, hy + 2, 1, 2, ha); wrect(6, hy + 2, 1, 2, ha); };
            if (long_hair) { wrect(1, hy + 5, 6, 2, ha); };
        };
    };

    if (view == 0) {
        if (hood) { wpx(3, hy + 3, EYE); wpx(4, hy + 3, EYE); } else { wpx(2, hy + 3, EYE); wpx(5, hy + 3, EYE); };
    } else if (view == 1) {
        wpx(4, hy + 3, EYE);
        wpx(6, hy + 3, EYE);
    } else if (view == 2) {
        wpx(5, hy + 3, EYE);
        wpx(7, hy + 3, sk);
    };

    if (hasf(F_BEARD) && view < 3) {
        let bc = if (D_HA == 0xf4efe6 || D_HA == 0x9a9a9a) { pale(D_HA, 10) } else { dark(D_HA, 10) };
        if (view == 2) {
            wrect(4, hy + 4, 3, 1, bc);
            wpx(5, hy + 5, bc);
        } else {
            wrect(2, hy + 4, 4, 1, bc);
            wrect(3, hy + 5, 2, 1, bc);
        };
    };

    if (hasf(F_BUN)) {
        if (view == 2) { wrect(2, hy, 2, 1, ha); } else { wrect(3, hy, 2, 1, ha); };
    };
    if (hasf(F_CAP)) {
        wrect(2, hy, 4, 1, D_TR);
        wrect(1, hy + 1, 6, 1, D_TR);
        if (view == 1 || view == 2) { wpx(7, hy + 1, D_TR); };
        if (view == 0) { wrect(2, hy + 2, 4, 1, dark(D_TR, 35)); };
    };
    if (hasf(F_STRAW)) {
        wrect(2, hy, 4, 1, 0xe0c070);
        wrect(0, hy + 1, 8, 1, 0xe0c070);
        wrect(2, hy, 4, 1, 0xc8a850);
    };
    if (hasf(F_BAND)) {
        wrect(1, hy + 1, 6, 1, D_TR);
        if (view == 2 || view == 3 || view == 4) { wpx(0, hy + 2, D_TR); wpx(0, hy + 3, D_TR); };
        if (view == 0 || view == 1) { wpx(0, hy + 2, D_TR); };
    };
}

def doll_staff(hy: long) -> void {
    wrect(7, hy + 2, 1, 10 - hy, 0x7a5a38);
    wpx(7, hy + 1, 0xe8c45a);
}

def doll_build(s: long, view: long, frame: long) -> void {
    D_SK = P_SK[s];
    D_HA = P_HA[s];
    D_CO = P_CO[s];
    D_TR = P_TR[s];
    D_LE = P_LE[s];
    D_FL = P_FL[s];
    WAW = 8;
    WAH = 12;
    work_clear();
    let child = hasf(F_CHILD);
    let oy = if (child) { 2 } else { 0 };
    let dip = if (frame == 2 || frame == 4) { 1 } else { 0 };
    let ty = oy + 5 + dip;
    let th = if (child) { 3 } else { 4 };
    let hy = oy + dip + (if (hasf(F_STOOP)) { 1 } else { 0 });
    if (hasf(F_STAFF)) { doll_staff(hy); };
    if (!hasf(F_CLOAK)) { doll_legs(view, frame, ty + th); };
    doll_torso(view, frame, ty, th);
    doll_arms(view, frame, ty, th, frame == 5);
    doll_head(view, hy);
}

def find_by(name_a: long, name_b: long) -> long {
    for s in 0..NP {
        if (P_NE[s] - P_NS[s] != name_b - name_a) { continue; };
        let ok = true;
        for k in 0..(name_b - name_a) {
            if (SRC[P_NS[s] + k] != SRC[name_a + k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return s; };
    };
    -1
}

def flag_of(a: long, b: long) -> long {
    if (word_is(a, b, "long")) { return F_LONG; };
    if (word_is(a, b, "bun")) { return F_BUN; };
    if (word_is(a, b, "bald")) { return F_BALD; };
    if (word_is(a, b, "hood")) { return F_HOOD; };
    if (word_is(a, b, "cap")) { return F_CAP; };
    if (word_is(a, b, "straw")) { return F_STRAW; };
    if (word_is(a, b, "beard")) { return F_BEARD; };
    if (word_is(a, b, "apron")) { return F_APRON; };
    if (word_is(a, b, "cloak")) { return F_CLOAK; };
    if (word_is(a, b, "child")) { return F_CHILD; };
    if (word_is(a, b, "stoop")) { return F_STOOP; };
    if (word_is(a, b, "staff")) { return F_STAFF; };
    if (word_is(a, b, "band")) { return F_BAND; };
    0
}

def load_actor(i: long, e: long) -> void {
    if (NP >= MAXP) { return; };
    let s = NP;
    NP += 1;
    let a = skip_sp(i + 6, e);
    let b = word_end(a, e);
    P_NS[s] = a;
    P_NE[s] = b;
    P_ACTOR[s] = true;
    a = skip_sp(b, e);
    P_SK[s] = key_col(SRC[a]);
    a = skip_sp(a + 1, e);
    P_HA[s] = key_col(SRC[a]);
    a = skip_sp(a + 1, e);
    P_CO[s] = key_col(SRC[a]);
    a = skip_sp(a + 1, e);
    P_TR[s] = key_col(SRC[a]);
    a = skip_sp(a + 1, e);
    P_LE[s] = key_col(SRC[a]);
    a = skip_sp(a + 1, e);
    let fl = 0;
    while (a < e) {
        b = word_end(a, e);
        fl = fl | flag_of(a, b);
        a = skip_sp(b, e);
    };
    P_FL[s] = fl;
    P_OUT[s] = OUTLINE;
    P_NV[s] = 5;
    P_NF[s] = 6;
    P_W[s] = 10;
    P_H[s] = 14;
    P_C0[s] = NSTORE;
    for v in 0..5 {
        for f in 0..6 {
            doll_build(s, v, f);
            commit(NSTORE, OUTLINE);
            NSTORE += 140;
        };
    };
}

def load(src: str) -> void {
    SRC = src;
    NP = 0;
    NSTORE = 0;
    let i = 0;
    let cur = -1;
    let row = 0;
    let frame = 0;
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
        } else if (starts(i, "actor ")) {
            load_actor(i, e);
        } else if (starts(i, "sprite ")) {
            if (NP < MAXP) {
                cur = NP;
                NP += 1;
                let j = i + 7;
                P_NS[cur] = j;
                while (SRC[j] != ' ') { j += 1; };
                P_NE[cur] = j;
                WAW = int_at(j + 1);
                WAH = int_at(NUM_END + 1);
                P_W[cur] = WAW + 2;
                P_H[cur] = WAH + 2;
                P_NF[cur] = 1;
                P_NV[cur] = 1;
                P_ACTOR[cur] = false;
                P_C0[cur] = NSTORE;
                P_OUT[cur] = OUTLINE;

                let w = skip_sp(NUM_END, e);
                w = word_end(w, e);
                w = skip_sp(w, e);
                if (w + 2 < e && SRC[w] == 'o' && SRC[w + 1] == ':') { P_OUT[cur] = key_col(SRC[w + 2]); };
                work_clear();
                row = 0;
                frame = 0;
            };
        } else if (starts(i, "frame")) {
            if (cur >= 0) {
                commit(P_C0[cur] + frame * P_W[cur] * P_H[cur], P_OUT[cur]);
                frame += 1;
                P_NF[cur] = frame + 1;
                work_clear();
                row = 0;
            };
        } else if (starts(i, "end")) {
            if (cur >= 0) {
                commit(P_C0[cur] + frame * P_W[cur] * P_H[cur], P_OUT[cur]);
                NSTORE = P_C0[cur] + P_NF[cur] * P_W[cur] * P_H[cur];
                cur = -1;
            };
        } else if (cur >= 0 && row < WAH) {
            for x in 0..WAW {
                let k = if (i + x < e) { SRC[i + x] } else { '.' };
                WORK[row * 32 + x] = if (k == '.' || k == ' ') { -1 } else { key_col(k) };
            };
            row += 1;
        };
        i = e + 1;
    };
}

def id(name: str) -> long {
    for s in 0..NP {
        if (P_NE[s] - P_NS[s] != len(name)) { continue; };
        let ok = true;
        for k in 0..len(name) {
            if (SRC[P_NS[s] + k] != name[k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return s; };
    };
    -1
}

def is_actor(s: long) -> bool { s >= 0 && s < NP && P_ACTOR[s] }

let VIEW_OF: [long; 8] = [1, 0, 1, 2, 3, 4, 3, 2];
let MIRROR_OF: [bool; 8] = [false, false, true, true, true, false, false, false];

const SHADOW = 0x101018;

let SH_X = 0;
let SH_Y = 0;
let SH_A = 0;

let HALO = 0;

def opaque(base: long, w: long, h: long, r: long, c: long, mirror: bool) -> bool {
    if (r < 0 || r >= h || c < 0 || c >= w) { return false; };
    let sc = if (mirror) { w - 1 - c } else { c };
    STORE[base + r * w + sc] >= 0
}

def draw(s: long, view: long, frame: long, mirror: bool, x: long, y: long, z: long, flash: long) -> bool {
    LAST_VIS = false;
    if (s < 0 || s >= NP) { return false; };
    let w = P_W[s];
    let h = P_H[s];
    let v = if (view >= P_NV[s]) { 0 } else { view };
    let f = frame % P_NF[s];
    let base = P_C0[s] + (v * P_NF[s] + f) * w * h;
    r3d.project(x, y, z);
    let px = r3d.PX;
    let py = r3d.PY;
    let zf = r3d.PD - 1500;
    let ox = px - w / 2;
    let oy = py - (h - 2);

    let kd = (((92682 / r3d.SCALE) * r3d.SINP) >> 16) >> 4;

    for sx in -2..3 {
        let d = pix.depth(px + sx, py + 1);
        if (d < pix.FAR && d > zf - 3000) { pix.blend(px + sx, py + 1, SHADOW, 90); };
    };
    for sx in -1..2 {
        let d = pix.depth(px + sx, py);
        if (d < pix.FAR && d > zf - 3000) { pix.blend(px + sx, py, SHADOW, 60); };
    };
    if (SH_A > 0) {
        let n = if (SH_X > 0) { SH_X } else { 0 - SH_X };
        let ay = if (SH_Y > 0) { SH_Y } else { 0 - SH_Y };
        if (ay > n) { n = ay; };
        if (n < 1) { n = 1; };
        if (n > 16) { n = 16; };

        let across_y = n == (if (SH_X > 0) { SH_X } else { 0 - SH_X });
        for i in 1..(n + 1) {
            let x = px + SH_X * i / n;
            let y = py + SH_Y * i / n;
            let thick = 1 + 2 * (n - i) / n;
            let a = SH_A * (2 * n - i) / (2 * n);
            for k in 0..thick {
                let ox = if (across_y) { 0 } else { k - thick / 2 };
                let oy = if (across_y) { k - thick / 2 } else { 0 };
                let d = pix.depth(x + ox, y + oy);
                if (d < pix.FAR && d > zf - 6000) { pix.blend(x + ox, y + oy, SHADOW, a); };
            };
        };
    };
    let any = false;
    for r in 0..h {
        let zr = zf - ((h - 2) - r) * kd;
        for c in 0..w {
            let sc = if (mirror) { w - 1 - c } else { c };
            let col = STORE[base + r * w + sc];
            if (col < 0) { continue; };
            let out = if (flash >= 0) { flash } else { r3d.lit_sprite(col) };
            pix.pset(ox + c, oy + r, zr, out);
            any = true;
        };
    };
    if (HALO > 0) {

        for r in -1..(h + 1) {
            for c in -1..(w + 1) {
                if (opaque(base, w, h, r, c, mirror)) { continue; };
                if (opaque(base, w, h, r - 1, c, mirror) || opaque(base, w, h, r + 1, c, mirror) || opaque(base, w, h, r, c - 1, mirror) || opaque(base, w, h, r, c + 1, mirror)) {
                    let zr = zf - ((h - 2) - r) * kd;
                    let d = pix.depth(ox + c, oy + r);
                    if (d >= zr - 2000) { pix.blend(ox + c, oy + r, 0xffffff, HALO); };
                };
            };
        };
    };
    LAST_X = ox;
    LAST_Y = oy / 2;
    LAST_W = w;
    LAST_H = (h + 1) / 2 + 1;
    LAST_VIS = any;
    any
}

def draw_cells(s: long, view: long, frame: long, mirror: bool, x: long, y: long, z: long) -> void {
    r3d.project(x, y, z);
    cells_at(s, view, frame, mirror, r3d.PX, r3d.PY);
}

def cells_at(s: long, view: long, frame: long, mirror: bool, fx: long, fy: long) -> void {
    if (s < 0 || s >= NP) { return; };
    let w = P_W[s];
    let h = P_H[s];
    let v = if (view >= P_NV[s]) { 0 } else { view };
    let f = frame % P_NF[s];
    let base = P_C0[s] + (v * P_NF[s] + f) * w * h;
    let ox = fx - w / 2;
    let oy = fy - (h - 2);

    let cy0 = oy / 2;
    if (oy < 0) { cy0 = 0 - ((1 - oy) / 2); };
    let cy1 = (oy + h - 1) / 2;
    for cy in cy0..(cy1 + 1) {
        for c in 0..w {
            let sc = if (mirror) { w - 1 - c } else { c };
            let top_r = cy * 2 - oy;
            let top = if (top_r >= 0 && top_r < h) { STORE[base + top_r * w + sc] } else { -1 };
            let bot = if (top_r + 1 >= 0 && top_r + 1 < h) { STORE[base + (top_r + 1) * w + sc] } else { -1 };
            if (top < 0 && bot < 0) { continue; };
            let cx = ox + c;
            if (!canvas.inside(cx, cy)) { continue; };
            if (top >= 0 && bot >= 0) {
                canvas.put(cx, cy, 0x2580, top, bot, 0);
            } else if (top >= 0) {
                canvas.put(cx, cy, 0x2580, top, canvas.KEEP, 0);
            } else {
                canvas.put(cx, cy, 0x2584, bot, canvas.KEEP, 0);
            };
        };
    };
}

def frames(s: long) -> long { if (s >= 0 && s < NP) { P_NF[s] } else { 1 } }

export {
    load, id, is_actor, draw, draw_cells, cells_at, frames, VIEW_OF, MIRROR_OF, NP, LAST_X, LAST_Y,
    LAST_W, LAST_H, LAST_VIS, SH_X, SH_Y, SH_A, HALO
};
