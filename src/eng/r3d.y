
import fx;
import pix;
import canvas;

const MAXM = 96;
const MAXV = 8192;
const MAXF = 8192;
let M_NAME_S: [long; 96] = [0; 96];
let M_NAME_E: [long; 96] = [0; 96];
let M_V0: [long; 96] = [0; 96];
let M_NV: [long; 96] = [0; 96];
let M_F0: [long; 96] = [0; 96];
let M_NF: [long; 96] = [0; 96];
let NM = 0;
let VX: [long; 8192] = [0; 8192];
let VY: [long; 8192] = [0; 8192];
let VZ: [long; 8192] = [0; 8192];
let NV = 0;
let FA: [long; 8192] = [0; 8192];
let FB: [long; 8192] = [0; 8192];
let FC: [long; 8192] = [0; 8192];
let FD: [long; 8192] = [0; 8192];
let FCOL: [long; 8192] = [0; 8192];
let NF = 0;

let MAXP = 128;
let P_NAME_S: [long; 128] = [0; 128];
let P_NAME_E: [long; 128] = [0; 128];
let PAL: [long; 128] = [0; 128];
let PAL_GLOW: [long; 128] = [0; 128];
let NP = 0;

let SRC = "";

let TX: [long; 1024] = [0; 1024];
let TY: [long; 1024] = [0; 1024];
let TD: [long; 1024] = [0; 1024];
let WX: [long; 1024] = [0; 1024];
let WY: [long; 1024] = [0; 1024];
let WZ: [long; 1024] = [0; 1024];

let CAM_X = 0;
let CAM_Z = 0;
const CAM_Y = 0;
let SCALE = 7;
const C45 = 46341;
const SINP = 46341;
const COSP = 46341;
let CXP = 40;
let CYP = 24;
let SHAKE_X = 0;
let SHAKE_Y = 0;

const LX = -24000;
const LY = 52000;
const LZ = 30000;
const AMBIENT = 110;
const DIFFUSE = 170;
let TINT = 0xffffff;
let FLASH = 0;

def set_view() -> void {
    CXP = pix.PW / 2;
    CYP = pix.PH / 2;

    SCALE = pix.PW / 14;
    if (SCALE < 5) { SCALE = 5; };
    if (SCALE > 12) { SCALE = 12; };
}

let PX = 0;
let PY = 0;
let PSX = 0;
let PSY = 0;
let PD = 0;

def project(x: long, y: long, z: long) -> void {
    let dx = x - CAM_X;
    let dz = z - CAM_Z;
    let dy = y - CAM_Y;
    let u = ((dx - dz) * C45) >> 16;
    let v = ((dx + dz) * C45) >> 16;
    let sy = ((v * SINP) >> 16) - ((dy * COSP) >> 16);
    PSX = CXP * 16 + ((u * SCALE * 16) >> 16) + SHAKE_X;
    PSY = CYP * 16 + ((sy * SCALE * 16) >> 16) + SHAKE_Y;
    PX = floor16(PSX);
    PY = floor16(PSY);

    PD = 8388608 - ((((v * COSP) >> 16) + ((dy * SINP) >> 16)) >> 4);
}

def floor16(v: long) -> long {
    if (v >= 0) { return v / 16; };
    0 - ((15 - v) / 16)
}

def cell_x(x: long, y: long, z: long) -> long {
    project(x, y, z);
    PX
}

let RP = 0;

def skip_ws() -> void {
    while (RP < len(SRC)) {
        let c = SRC[RP];
        if (c == '#') {
            while (RP < len(SRC) && SRC[RP] != 10) { RP += 1; };
        } else if (c == ' ' || c == 9 || c == 13 || c == 10) {
            RP += 1;
        } else {
            return;
        };
    };
}

let WS = 0;
let WE = 0;
def word() -> bool {
    skip_ws();
    if (RP >= len(SRC)) { return false; };
    WS = RP;
    while (RP < len(SRC) && SRC[RP] > 32) { RP += 1; };
    WE = RP;
    true
}

def word_is(s: str) -> bool {
    if (WE - WS != len(s)) { return false; };
    for k in 0..len(s) {
        if (SRC[WS + k] != s[k]) { return false; };
    };
    true
}

def word_int() -> long {
    word();
    let v = 0;
    let neg = false;
    let i = WS;
    if (i < WE && SRC[i] == '-') {
        neg = true;
        i += 1;
    };
    while (i < WE) {
        let d = SRC[i] - '0';
        if (d >= 0 && d <= 9) { v = v * 10 + d; };
        i += 1;
    };
    if (neg) { 0 - v } else { v }
}

def word_hex() -> long {
    word();
    let v = 0;
    for i in WS..WE {
        let c = SRC[i];
        let d = -1;
        if (c >= '0' && c <= '9') { d = c - '0'; };
        if (c >= 'a' && c <= 'f') { d = c - 'a' + 10; };
        if (c >= 'A' && c <= 'F') { d = c - 'A' + 10; };
        if (d >= 0) { v = v * 16 + d; };
    };
    v
}

def same_range(a0: long, a1: long, b0: long, b1: long) -> bool {
    if (a1 - a0 != b1 - b0) { return false; };
    for k in 0..(a1 - a0) {
        if (SRC[a0 + k] != SRC[b0 + k]) { return false; };
    };
    true
}

def pal_find(s0: long, s1: long) -> long {
    for i in 0..NP {
        if (same_range(P_NAME_S[i], P_NAME_E[i], s0, s1)) { return i; };
    };
    0
}

def load(src: str) -> void {
    SRC = src;
    RP = 0;
    NM = 0;
    NV = 0;
    NF = 0;
    NP = 0;
    let cur = -1;
    while (word()) {
        if (word_is("col")) {
            word();
            if (NP < MAXP) {
                P_NAME_S[NP] = WS;
                P_NAME_E[NP] = WE;
                PAL[NP] = word_hex();
                PAL_GLOW[NP] = 0;

                let save = RP;
                skip_inline();
                if (RP < len(SRC) && SRC[RP] == 'g') {
                    word();
                    PAL_GLOW[NP] = 1;
                } else {
                    RP = save;
                };
                NP += 1;
            };
        } else if (word_is("mesh")) {
            word();
            if (NM < MAXM) {
                cur = NM;
                M_NAME_S[cur] = WS;
                M_NAME_E[cur] = WE;
                M_V0[cur] = NV;
                M_NV[cur] = 0;
                M_F0[cur] = NF;
                M_NF[cur] = 0;
                NM += 1;
            };
        } else if (word_is("v")) {
            let x = word_int();
            let y = word_int();
            let z = word_int();
            if (cur >= 0 && NV < MAXV) {
                VX[NV] = x * 4096;
                VY[NV] = y * 4096;
                VZ[NV] = z * 4096;
                NV += 1;
                M_NV[cur] += 1;
            };
        } else if (word_is("f")) {
            word();
            let c = pal_find(WS, WE);
            let a = word_int();
            let b = word_int();
            let cc = word_int();
            let d = -1;
            let save = RP;
            skip_inline();
            if (RP < len(SRC) && (SRC[RP] == '-' || (SRC[RP] >= '0' && SRC[RP] <= '9'))) {
                d = word_int();
            } else {
                RP = save;
            };
            add_face(cur, c, a, b, cc, d);
        } else if (word_is("box")) {
            word();
            let c = pal_find(WS, WE);
            let x0 = word_int();
            let y0 = word_int();
            let z0 = word_int();
            let x1 = word_int();
            let y1 = word_int();
            let z1 = word_int();
            add_box(cur, c, x0, y0, z0, x1, y1, z1);
        } else if (word_is("roof")) {

            word();
            let c = pal_find(WS, WE);
            let x0 = word_int();
            let y0 = word_int();
            let z0 = word_int();
            let x1 = word_int();
            let y1 = word_int();
            let z1 = word_int();
            let ax = word_int();
            add_roof(cur, c, x0, y0, z0, x1, y1, z1, ax);
        } else if (word_is("cyl") || word_is("cone")) {

            let is_cone = word_is("cone");
            word();
            let c = pal_find(WS, WE);
            let cx = word_int();
            let cz = word_int();
            let r = word_int();
            let y0 = word_int();
            let y1 = word_int();
            let sides = word_int();
            add_cyl(cur, c, cx, cz, r, y0, y1, sides, is_cone);
        } else if (word_is("end")) {
            cur = -1;
        };
    };
}

def skip_inline() -> void {
    while (RP < len(SRC) && (SRC[RP] == ' ' || SRC[RP] == 9)) { RP += 1; };
}

def add_face(m: long, c: long, a: long, b: long, cc: long, d: long) -> void {
    if (m < 0 || NF >= MAXF) { return; };
    let base = M_V0[m];
    FA[NF] = base + a;
    FB[NF] = base + b;
    FC[NF] = base + cc;
    FD[NF] = if (d >= 0) { base + d } else { -1 };
    FCOL[NF] = c;
    NF += 1;
    M_NF[m] += 1;
}

def add_vert(m: long, x: long, y: long, z: long) -> long {
    if (NV >= MAXV) { return 0; };
    VX[NV] = x * 4096;
    VY[NV] = y * 4096;
    VZ[NV] = z * 4096;
    NV += 1;
    M_NV[m] += 1;
    M_NV[m] - 1
}

def add_box(m: long, c: long, x0: long, y0: long, z0: long, x1: long, y1: long, z1: long) -> void {
    if (m < 0) { return; };
    let v0 = add_vert(m, x0, y0, z0);
    add_vert(m, x1, y0, z0);
    add_vert(m, x1, y0, z1);
    add_vert(m, x0, y0, z1);
    add_vert(m, x0, y1, z0);
    add_vert(m, x1, y1, z0);
    add_vert(m, x1, y1, z1);
    add_vert(m, x0, y1, z1);

    add_face(m, c, v0 + 4, v0 + 7, v0 + 6, v0 + 5);
    add_face(m, c, v0 + 0, v0 + 1, v0 + 2, v0 + 3);
    add_face(m, c, v0 + 3, v0 + 2, v0 + 6, v0 + 7);
    add_face(m, c, v0 + 1, v0 + 0, v0 + 4, v0 + 5);
    add_face(m, c, v0 + 2, v0 + 1, v0 + 5, v0 + 6);
    add_face(m, c, v0 + 0, v0 + 3, v0 + 7, v0 + 4);
}

def add_roof(m: long, c: long, x0: long, y0: long, z0: long, x1: long, y1: long, z1: long, axis: long) -> void {
    if (m < 0) { return; };
    let a = add_vert(m, x0, y0, z0);
    add_vert(m, x1, y0, z0);
    add_vert(m, x1, y0, z1);
    add_vert(m, x0, y0, z1);
    if (axis == 0) {
        let mz = (z0 + z1) / 2;
        let r0 = add_vert(m, x0, y1, mz);
        add_vert(m, x1, y1, mz);
        add_face(m, c, a + 0, r0, r0 + 1, a + 1);
        add_face(m, c, a + 2, r0 + 1, r0, a + 3);
        add_face(m, c, a + 3, r0, a + 0, -1);
        add_face(m, c, a + 1, r0 + 1, a + 2, -1);
    } else {
        let mx = (x0 + x1) / 2;
        let r0 = add_vert(m, mx, y1, z0);
        add_vert(m, mx, y1, z1);
        add_face(m, c, a + 0, a + 3, r0 + 1, r0);
        add_face(m, c, a + 2, a + 1, r0, r0 + 1);
        add_face(m, c, a + 0, r0, a + 1, -1);
        add_face(m, c, a + 2, r0 + 1, a + 3, -1);
    };
}

def add_cyl(m: long, c: long, cx: long, cz: long, r: long, y0: long, y1: long, sides: long, cone: bool) -> void {
    if (m < 0 || sides < 3) { return; };
    let base = M_NV[m];
    for i in 0..sides {
        let a = i * 1024 / sides;
        let x = cx * 4096 + ((r * 4096 * fx.cos(a)) >> 16);
        let z = cz * 4096 + ((r * 4096 * fx.sin(a)) >> 16);
        add_vert_q(m, x, y0 * 4096, z);
        if (!cone) { add_vert_q(m, x, y1 * 4096, z); };
    };
    let tip = -1;
    if (cone) { tip = add_vert(m, cx, y1, cz); };
    let step = if (cone) { 1 } else { 2 };
    for i in 0..sides {
        let j = (i + 1) % sides;
        let b0 = base + i * step;
        let b1 = base + j * step;
        if (cone) {
            add_face(m, c, b1, b0, tip, -1);
        } else {
            add_face(m, c, b1, b0, b0 + 1, b1 + 1);
        };
    };
    if (!cone) {

        for i in 1..(sides - 1) {
            add_face(m, c, base + 1, base + (i + 1) * 2 + 1, base + i * 2 + 1, -1);
        };
    };
}

def add_vert_q(m: long, x: long, y: long, z: long) -> long {
    if (NV >= MAXV) { return 0; };
    VX[NV] = x;
    VY[NV] = y;
    VZ[NV] = z;
    NV += 1;
    M_NV[m] += 1;
    M_NV[m] - 1
}

def mesh_id(name: str) -> long {
    for i in 0..NM {
        let n = M_NAME_E[i] - M_NAME_S[i];
        if (n != len(name)) { continue; };
        let ok = true;
        for k in 0..n {
            if (SRC[M_NAME_S[i] + k] != name[k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return i; };
    };
    -1
}

def color_id(name: str) -> long {
    for i in 0..NP {
        let n = P_NAME_E[i] - P_NAME_S[i];
        if (n != len(name)) { continue; };
        let ok = true;
        for k in 0..n {
            if (SRC[P_NAME_S[i] + k] != name[k]) {
                ok = false;
                break;
            };
        };
        if (ok) { return i; };
    };
    0
}

def shade(c: long, nx: long, ny: long, nz: long, glow: bool) -> long {
    if (glow) { return c; };

    let n = 0;
    if (nx == 0 && nz == 0) { n = if (ny < 0) { 0 - ny } else { ny }; }
    else if (nx == 0 && ny == 0) { n = if (nz < 0) { 0 - nz } else { nz }; }
    else if (ny == 0 && nz == 0) { n = if (nx < 0) { 0 - nx } else { nx }; }
    else { n = fx.isqrt(nx * nx + ny * ny + nz * nz); };
    let d = 0;
    if (n > 0) {
        d = (nx * LX + ny * LY + nz * LZ) / n;
    };
    if (d < 0) { d = 0; };
    let k = AMBIENT + ((DIFFUSE * d) >> 16);
    let r = (((c >> 16) & 255) * k) >> 8;
    let g = (((c >> 8) & 255) * k) >> 8;
    let b = ((c & 255) * k) >> 8;
    r = (r * ((TINT >> 16) & 255)) / 255;
    g = (g * ((TINT >> 8) & 255)) / 255;
    b = (b * (TINT & 255)) / 255;
    if (r > 255) { r = 255; };
    if (g > 255) { g = 255; };
    if (b > 255) { b = 255; };
    let out = (r << 16) | (g << 8) | b;
    if (FLASH > 0) { out = canvas.mixc(out, 0xffffff, FLASH); };
    out
}

let BX0 = 0;
let BX1 = 0;
let BY0 = 0;
let BY1 = 0;
let BW_X0 = 0;
let BW_X1 = 0;
let BW_Z0 = 0;
let BW_Z1 = 0;
let BH = 0;

def bbox(m: long, x: long, y: long, z: long, yaw: long) -> void {
    BX0 = 1 << 30;
    BX1 = 0 - (1 << 30);
    BY0 = 1 << 30;
    BY1 = 0 - (1 << 30);
    BW_X0 = 1 << 40;
    BW_X1 = 0 - (1 << 40);
    BW_Z0 = 1 << 40;
    BW_Z1 = 0 - (1 << 40);
    BH = 0;
    if (m < 0 || m >= NM) { return; };
    let cy = fx.cos(yaw);
    let sy = fx.sin(yaw);
    let v0 = M_V0[m];
    for k in 0..M_NV[m] {
        let px = VX[v0 + k];
        let pz = VZ[v0 + k];
        let rx = (px * cy - pz * sy) >> 16;
        let rz = (px * sy + pz * cy) >> 16;
        project(x + rx, y + VY[v0 + k], z + rz);
        if (PX < BX0) { BX0 = PX; };
        if (PX > BX1) { BX1 = PX; };
        if (PY < BY0) { BY0 = PY; };
        if (PY > BY1) { BY1 = PY; };
        if (x + rx < BW_X0) { BW_X0 = x + rx; };
        if (x + rx > BW_X1) { BW_X1 = x + rx; };
        if (z + rz < BW_Z0) { BW_Z0 = z + rz; };
        if (z + rz > BW_Z1) { BW_Z1 = z + rz; };
        if (VY[v0 + k] > BH) { BH = VY[v0 + k]; };
    };
}

def lit_sprite(c: long) -> long {
    let r = (((c >> 16) & 255) * ((TINT >> 16) & 255)) / 255;
    let g = (((c >> 8) & 255) * ((TINT >> 8) & 255)) / 255;
    let b = ((c & 255) * (TINT & 255)) / 255;
    let out = (r << 16) | (g << 8) | b;
    if (FLASH > 0) { out = canvas.mixc(out, 0xffffff, FLASH); };
    out
}

def lit(c: long) -> long { shade(c, 0, 65536, 0, false) }

def draw(m: long, x: long, y: long, z: long, yaw: long, sc: long, pitch: long, roll: long, recol: long) -> void {
    if (m < 0 || m >= NM) { return; };
    let n = M_NV[m];
    if (n > 1024) { n = 1024; };
    let v0 = M_V0[m];
    let cy = fx.cos(yaw);
    let sy = fx.sin(yaw);
    let cp = fx.cos(pitch);
    let sp = fx.sin(pitch);
    let cr = fx.cos(roll);
    let sr = fx.sin(roll);
    let tilt = pitch != 0 || roll != 0;
    for k in 0..n {
        let px = (VX[v0 + k] * sc) >> 16;
        let py = (VY[v0 + k] * sc) >> 16;
        let pz = (VZ[v0 + k] * sc) >> 16;
        if (tilt) {

            let ym = py - 32768;
            let y1 = (ym * cp - pz * sp) >> 16;
            let z1 = (ym * sp + pz * cp) >> 16;
            let x2 = (px * cr - y1 * sr) >> 16;
            let y2 = (px * sr + y1 * cr) >> 16;
            px = x2;
            py = y2 + 32768;
            pz = z1;
        };
        let rx = (px * cy - pz * sy) >> 16;
        let rz = (px * sy + pz * cy) >> 16;
        WX[k] = rx;
        WY[k] = py;
        WZ[k] = rz;
        project(x + rx, y + py, z + rz);
        TX[k] = PSX;
        TY[k] = PSY;
        TD[k] = PD;
    };
    let f0 = M_F0[m];
    let vx = (C45 * COSP) >> 16;
    let vy = SINP;
    let vz = vx;
    for f in f0..(f0 + M_NF[m]) {
        let a = FA[f] - v0;
        let b = FB[f] - v0;
        let c = FC[f] - v0;

        let ux = WX[b] - WX[a];
        let uy = WY[b] - WY[a];
        let uz = WZ[b] - WZ[a];
        let wx = WX[c] - WX[a];
        let wy = WY[c] - WY[a];
        let wz = WZ[c] - WZ[a];
        let nx = ((uy * wz) >> 16) - ((uz * wy) >> 16);
        let ny = ((uz * wx) >> 16) - ((ux * wz) >> 16);
        let nz = ((ux * wy) >> 16) - ((uy * wx) >> 16);
        if (((nx * vx) >> 16) + ((ny * vy) >> 16) + ((nz * vz) >> 16) <= 0) { continue; };
        let pc = FCOL[f];
        let base = if (recol >= 0) { recol } else { PAL[pc] };
        let col = shade(base, nx, ny, nz, PAL_GLOW[pc] == 1 && recol < 0);
        pix.tri(TX[a], TY[a], TD[a], TX[b], TY[b], TD[b], TX[c], TY[c], TD[c], col);
        let d = FD[f];
        if (d >= 0) {
            let dd = d - v0;
            pix.tri(TX[a], TY[a], TD[a], TX[c], TY[c], TD[c], TX[dd], TY[dd], TD[dd], col);
        };
    };
}

def ground(x0: long, z0: long, x1: long, z1: long, y: long, col: long) -> void {
    project(x0, y, z0);
    let ax = PSX;
    let ay = PSY;
    let ad = PD;
    project(x1, y, z0);
    let bx = PSX;
    let by = PSY;
    let bd = PD;
    project(x1, y, z1);
    let cx = PSX;
    let cy = PSY;
    let cd = PD;
    project(x0, y, z1);
    pix.tri(ax, ay, ad, bx, by, bd, cx, cy, cd, col);
    pix.tri(ax, ay, ad, cx, cy, cd, PSX, PSY, PD, col);
}

def ground_bias(x0: long, z0: long, x1: long, z1: long, y: long, col: long, bias: long) -> void {
    project(x0, y, z0);
    let ax = PSX;
    let ay = PSY;
    let ad = PD + bias;
    project(x1, y, z0);
    let bx = PSX;
    let by = PSY;
    let bd = PD + bias;
    project(x1, y, z1);
    let cx = PSX;
    let cy = PSY;
    let cd = PD + bias;
    project(x0, y, z1);
    pix.tri(ax, ay, ad, bx, by, bd, cx, cy, cd, col);
    pix.tri(ax, ay, ad, cx, cy, cd, PSX, PSY, PD + bias, col);
}

def wall(x0: long, z0: long, x1: long, z1: long, y0: long, y1: long, col: long) -> void {
    project(x0, y0, z0);
    let ax = PSX;
    let ay = PSY;
    let ad = PD;
    project(x1, y0, z1);
    let bx = PSX;
    let by = PSY;
    let bd = PD;
    project(x1, y1, z1);
    let cx = PSX;
    let cy = PSY;
    let cd = PD;
    project(x0, y1, z0);
    pix.tri(ax, ay, ad, bx, by, bd, cx, cy, cd, col);
    pix.tri(ax, ay, ad, cx, cy, cd, PSX, PSY, PD, col);
}

export {
    load, mesh_id, color_id, draw, ground, ground_bias, wall, project, set_view,
    shade, lit, lit_sprite, bbox, BH, BX0, BX1, BY0, BY1, BW_X0, BW_X1, BW_Z0, BW_Z1, cell_x, PX, PY, PSX, PSY, PD, CAM_X, CAM_Y, CAM_Z, SCALE, TINT,
    FLASH, AMBIENT, DIFFUSE, LX, LY, LZ, SHAKE_X, SHAKE_Y, PAL, NM, NF, NV
};
