
import r3d;
import pix;
import fx;
import canvas;

let SRC = "";

const MAXZ = 16;
let Z_W: [long; 16] = [0; 16];
let Z_H: [long; 16] = [0; 16];
let Z_T0: [long; 16] = [0; 16];
let Z_INDOOR: [bool; 16] = [false; 16];
let Z_NS: [long; 16] = [0; 16];
let Z_NE: [long; 16] = [0; 16];
let NZ = 0;
let TILES: [byte; 24576] = [0; 24576];
let NT = 0;

const OK_MESH = 1;
const OK_SOLID = 2;
const OK_DOOR = 3;
const OK_THING = 4;
const OK_HOME = 5;
const OK_SPOT = 6;
const OK_LAMP = 7;
const OK_SPAWN = 8;

const MAXO = 512;
let O_KIND: [long; 512] = [0; 512];
let O_ZONE: [long; 512] = [0; 512];
let O_X: [long; 512] = [0; 512];
let O_Z: [long; 512] = [0; 512];
let O_W: [long; 512] = [0; 512];
let O_H: [long; 512] = [0; 512];
let O_ARG: [long; 512] = [0; 512];
let O_ROT: [long; 512] = [0; 512];
let O_NS: [long; 512] = [0; 512];
let O_NE: [long; 512] = [0; 512];
let NO = 0;

let MAXP = 24;
let P_ID_S: [long; 24] = [0; 24];
let P_ID_E: [long; 24] = [0; 24];
let P_SPR_S: [long; 24] = [0; 24];
let P_SPR_E: [long; 24] = [0; 24];
let P_NAME: [str; 24] = [""; 24];
let NPEOPLE = 0;

const MAXSC = 128;
let SC_WHO: [long; 128] = [0; 128];
let SC_MIN: [long; 128] = [0; 128];
let SC_SPOT: [long; 128] = [0; 128];
let SC_NS: [long; 128] = [0; 128];
let SC_NE: [long; 128] = [0; 128];
let NSC = 0;

const MAXPAINT = 96;
let PT_ADDR: [long; 96] = [0; 96];
let PT_S: [long; 96] = [0; 96];
let PT_E: [long; 96] = [0; 96];
let NPAINT = 0;

let RP = 0;
let WS = 0;
let WE = 0;

def eol() -> bool {
    while (RP < len(SRC) && (SRC[RP] == ' ' || SRC[RP] == 9)) { RP += 1; };
    RP >= len(SRC) || SRC[RP] == 10 || SRC[RP] == 13 || SRC[RP] == '#'
}

def word() -> bool {
    if (eol()) {
        WS = RP;
        WE = RP;
        return false;
    };
    WS = RP;
    if (SRC[RP] == 34) {
        RP += 1;
        WS = RP;
        while (RP < len(SRC) && SRC[RP] != 34 && SRC[RP] != 10) { RP += 1; };
        WE = RP;
        if (RP < len(SRC) && SRC[RP] == 34) { RP += 1; };
        return true;
    };
    while (RP < len(SRC) && SRC[RP] > 32) { RP += 1; };
    WE = RP;
    true
}

def next_line() -> void {
    while (RP < len(SRC) && SRC[RP] != 10) { RP += 1; };
    if (RP < len(SRC)) { RP += 1; };
}

def is(s: str) -> bool {
    if (WE - WS != len(s)) { return false; };
    for k in 0..len(s) {
        if (SRC[WS + k] != s[k]) { return false; };
    };
    true
}

def num() -> long {
    word();
    let v = 0;
    let neg = false;
    for i in WS..WE {
        let c = SRC[i];
        if (c == '-') { neg = true; };
        if (c >= '0' && c <= '9') { v = v * 10 + c - '0'; };
    };
    if (neg) { 0 - v } else { v }
}

def hexnum() -> long {
    word();
    let v = 0;
    for i in WS..WE {
        let c = SRC[i];
        if (c >= '0' && c <= '9') { v = v * 16 + c - '0'; };
        if (c >= 'A' && c <= 'F') { v = v * 16 + c - 'A' + 10; };
        if (c >= 'a' && c <= 'f') { v = v * 16 + c - 'a' + 10; };
    };
    v
}

def range_eq(a0: long, a1: long, s: str) -> bool {
    if (a1 - a0 != len(s)) { return false; };
    for k in 0..len(s) {
        if (SRC[a0 + k] != s[k]) { return false; };
    };
    true
}

def ranges_eq(a0: long, a1: long, b0: long, b1: long) -> bool {
    if (a1 - a0 != b1 - b0) { return false; };
    for k in 0..(a1 - a0) {
        if (SRC[a0 + k] != SRC[b0 + k]) { return false; };
    };
    true
}

def zone_by_range(a0: long, a1: long) -> long {
    for z in 0..NZ {
        if (ranges_eq(Z_NS[z], Z_NE[z], a0, a1)) { return z; };
    };
    -1
}

def zone_id(name: str) -> long {
    for z in 0..NZ {
        if (range_eq(Z_NS[z], Z_NE[z], name)) { return z; };
    };
    -1
}

def person_id(name: str) -> long {
    for p in 0..NPEOPLE {
        if (range_eq(P_ID_S[p], P_ID_E[p], name)) { return p; };
    };
    -1
}

def add_obj(kind: long, zone: long, x: long, z: long) -> long {
    if (NO >= MAXO) { return MAXO - 1; };
    let o = NO;
    NO += 1;
    O_KIND[o] = kind;
    O_ZONE[o] = zone;
    O_X[o] = x;
    O_Z[o] = z;
    O_W[o] = 0;
    O_H[o] = 0;
    O_ARG[o] = -1;
    O_ROT[o] = 0;
    O_NS[o] = 0;
    O_NE[o] = 0;
    o
}

def load(src: str) -> void {
    SRC = src;
    RP = 0;
    NZ = 0;
    NT = 0;
    NO = 0;
    NPEOPLE = 0;
    let cur = -1;
    while (RP < len(SRC)) {
        if (!word()) {
            next_line();
            continue;
        };
        if (is("zone")) {
            word();
            cur = NZ;
            NZ += 1;
            Z_NS[cur] = WS;
            Z_NE[cur] = WE;
            Z_W[cur] = num();
            Z_H[cur] = num();
            Z_INDOOR[cur] = false;
            while (word()) {
                if (is("indoor")) { Z_INDOOR[cur] = true; };
            };
            Z_T0[cur] = NT;
            next_line();
        } else if (is("tiles")) {
            next_line();
            for row in 0..Z_H[cur] {
                for col in 0..Z_W[cur] {
                    let c: long = 32;
                    if (RP + col < len(SRC)) { c = SRC[RP + col]; };
                    if (c == 10) { c = 32; };
                    TILES[NT + row * Z_W[cur] + col] = c;
                };
                next_line();
            };
            NT += Z_W[cur] * Z_H[cur];
        } else if (is("who")) {
            if (NPEOPLE < MAXP) {
                let p = NPEOPLE;
                NPEOPLE += 1;
                word();
                P_ID_S[p] = WS;
                P_ID_E[p] = WE;
                word();
                P_SPR_S[p] = WS;
                P_SPR_E[p] = WE;
                word();
                P_NAME[p] = SRC[WS:WE];
            };
            next_line();
        } else if (is("mesh")) {
            word();
            let mid = r3d.mesh_id(SRC[WS:WE]);
            let x = num();
            let z = num();
            let o = add_obj(OK_MESH, cur, x, z);
            O_ARG[o] = mid;
            O_ROT[o] = num();
            next_line();
        } else if (is("solid")) {
            let x = num();
            let z = num();
            let o = add_obj(OK_SOLID, cur, x, z);
            O_W[o] = num();
            O_H[o] = num();
            next_line();
        } else if (is("door")) {
            let x = num();
            let z = num();
            let o = add_obj(OK_DOOR, cur, x, z);
            word();
            O_NS[o] = WS;
            O_NE[o] = WE;
            O_W[o] = num();
            O_H[o] = num();
            if (word() && is("gate")) { O_ROT[o] = 1; };
            next_line();
        } else if (is("thing")) {
            word();
            let ns = WS;
            let ne = WE;
            let x = num();
            let z = num();
            let o = add_obj(OK_THING, cur, x, z);
            O_NS[o] = ns;
            O_NE[o] = ne;
            if (word()) {
                RP = WS;
                O_ARG[o] = hexnum();
            };
            next_line();
        } else if (is("home") || is("spot") || is("spawn")) {
            let kind = if (is("home")) { OK_HOME } else if (is("spot")) { OK_SPOT } else { OK_SPAWN };
            word();
            let ns = WS;
            let ne = WE;
            let x = num();
            let z = num();
            let o = add_obj(kind, cur, x, z);
            O_NS[o] = ns;
            O_NE[o] = ne;
            next_line();
        } else if (is("sched")) {
            if (NSC < MAXSC) {
                word();
                let ws = WS;
                let we = WE;
                word();
                let hh = 0;
                let mm = 0;
                if (WE - WS >= 5) {
                    hh = (SRC[WS] - '0') * 10 + SRC[WS + 1] - '0';
                    mm = (SRC[WS + 3] - '0') * 10 + SRC[WS + 4] - '0';
                };
                word();
                SC_NS[NSC] = WS;
                SC_NE[NSC] = WE;
                SC_MIN[NSC] = hh * 60 + mm;
                SC_WHO[NSC] = -1;

                SC_SPOT[NSC] = ws * 65536 + we;
                NSC += 1;
            };
            next_line();
        } else if (is("paint")) {
            if (NPAINT < MAXPAINT) {
                PT_ADDR[NPAINT] = hexnum();
                word();
                PT_S[NPAINT] = WS;
                PT_E[NPAINT] = WE;
                NPAINT += 1;
            };
            next_line();
        } else if (is("lamp")) {
            let x = num();
            let z = num();
            add_obj(OK_LAMP, cur, x, z);
            next_line();
        } else {
            next_line();
        };
    };

    for i in 0..NSC {
        let ws = SC_SPOT[i] / 65536;
        let we = SC_SPOT[i] % 65536;
        SC_WHO[i] = -1;
        for p in 0..NPEOPLE {
            if (ranges_eq(P_ID_S[p], P_ID_E[p], ws, we)) { SC_WHO[i] = p; };
        };
        SC_SPOT[i] = -1;
        for o in 0..NO {
            if (O_KIND[o] == OK_SPOT && ranges_eq(O_NS[o], O_NE[o], SC_NS[i], SC_NE[i])) { SC_SPOT[i] = o; };
        };
    };

    for o in 0..NO {
        if (O_KIND[o] == OK_DOOR) { O_ARG[o] = zone_by_range(O_NS[o], O_NE[o]); };
    };
    link_neighbours();
    build_cast();
}

let CAST: [byte; 24576] = [0; 24576];
let SUN_A = 0;
let SUN_N = 0;
let SUN_SX = 0;
let SUN_SZ = 0;
let SUN_U = 0;
let SUN_V = 0;
let SUN_LEN = 0;
let SUN_WX = 0;
let SUN_WZ = 0;

def build_cast() -> void {
    for z in 0..NZ {
        for y in 0..Z_H[z] {
            for x in 0..Z_W[z] {
                let c = TILES[Z_T0[z] + y * Z_W[z] + x];
                let v = 0;
                if (c == 'T') { v = 2; };
                if (c == 'b' || c == 'r') { v = 1; };
                CAST[Z_T0[z] + y * Z_W[z] + x] = v;
            };
        };
    };
    for o in 0..NO {
        if (O_KIND[o] != OK_SOLID) { continue; };
        let v = if (O_W[o] * O_H[o] >= 2) { 2 } else { 1 };
        for y in O_Z[o]..(O_Z[o] + O_H[o]) {
            for x in O_X[o]..(O_X[o] + O_W[o]) {
                if (x < 0 || y < 0 || x >= Z_W[O_ZONE[o]] || y >= Z_H[O_ZONE[o]]) { continue; };
                let i = Z_T0[O_ZONE[o]] + y * Z_W[O_ZONE[o]] + x;
                if (CAST[i] < v) { CAST[i] = v; };
            };
        };
    };
}

def set_sun(m: long, indoor: bool) -> void {
    SUN_A = 0;
    if (indoor || m < 360 || m >= 1140) { return; };
    let ang = (m - 360) * 512 / 720;
    if (ang > 512) { ang = 512; };
    let u = fx.cos(ang);
    let v = fx.sin(ang);
    SUN_U = u;
    SUN_V = v;
    let wx = ((u + v) * 46341) >> 16;
    let wz = ((v - u) * 46341) >> 16;
    SUN_WX = wx;
    SUN_WZ = wz;

    SUN_LEN = 666 - ((512 * v) >> 16);
    SUN_N = 1;
    if (SUN_LEN > 300) { SUN_N = 2; };
    if (SUN_LEN > 520) { SUN_N = 3; };
    SUN_SX = 0 - ((wx * SUN_LEN / SUN_N) >> 8);
    SUN_SZ = 0 - ((wz * SUN_LEN / SUN_N) >> 8);
    let a = 40 + ((v * 50) >> 16);
    if (m < 390) { a = a * (m - 360) / 30; };
    if (m >= 1080) { a = a * (1140 - m) / 60; };
    SUN_A = a;
}

def cast_at(zone: long, x: long, z: long) -> long {
    if (x < 0 || z < 0 || x >= Z_W[zone] || z >= Z_H[zone]) { return 0; };
    CAST[Z_T0[zone] + z * Z_W[zone] + x]
}

def shadowed(zone: long, lx: long, lz: long) -> bool {
    for k in 1..(SUN_N + 1) {
        let sx = (lx * 65536 + 32768 + k * SUN_SX) >> 16;
        let sz = (lz * 65536 + 32768 + k * SUN_SZ) >> 16;
        if (sx == lx && sz == lz) { continue; };
        let c = cast_at(zone, sx, sz);
        if (c == 2 || (c == 1 && k == 1)) { return true; };
    };
    false
}

let NB_N: [long; 16] = [0; 16];
let NB_ZONE: [long; 64] = [-1; 64];
let NB_OX: [long; 64] = [0; 64];
let NB_OZ: [long; 64] = [0; 64];

def link_neighbours() -> void {
    for a in 0..NZ { NB_N[a] = 0; };
    for a in 0..NZ {
        if (Z_INDOOR[a]) { continue; };
        for d in 0..NO {
            if (O_ZONE[d] != a || O_KIND[d] != OK_DOOR || O_ARG[d] < 0) { continue; };
            let b = O_ARG[d];
            if (Z_INDOOR[b] || NB_N[a] >= 4) { continue; };
            let have = false;
            for k in 0..NB_N[a] { if (NB_ZONE[a * 4 + k] == b) { have = true; }; };
            if (have) { continue; };

            let dx = 0;
            let dz = 0;
            if (O_X[d] == 0) { dx = -1; }
            else if (O_X[d] == Z_W[a] - 1) { dx = 1; }
            else if (O_Z[d] == 0) { dz = -1; }
            else if (O_Z[d] == Z_H[a] - 1) { dz = 1; };
            if (dx == 0 && dz == 0) { continue; };

            let be = -1;
            let bd = 99;
            for e in 0..NO {
                if (O_ZONE[e] != b || O_KIND[e] != OK_DOOR || O_ARG[e] != a) { continue; };
                let ax = O_W[e] - (O_X[d] - dx);
                let az = O_H[e] - (O_Z[d] - dz);
                let m = (if (ax < 0) { 0 - ax } else { ax }) + (if (az < 0) { 0 - az } else { az });
                if (m < bd) {
                    bd = m;
                    be = e;
                };
            };
            if (be >= 0 && bd <= 4) {
                let k = NB_N[a];
                NB_ZONE[a * 4 + k] = b;
                NB_OX[a * 4 + k] = O_X[d] + dx - O_X[be];
                NB_OZ[a * 4 + k] = O_Z[d] + dz - O_Z[be];
                NB_N[a] = k + 1;
            };
        };
    };
}

def tile(zone: long, x: long, z: long) -> long {
    if (zone < 0 || x < 0 || z < 0 || x >= Z_W[zone] || z >= Z_H[zone]) { return 32; };
    TILES[Z_T0[zone] + z * Z_W[zone] + x]
}

def tile_blocks(c: long) -> bool {
    c == '~' || c == '#' || c == 'H' || c == 'h' || c == 'T' || c == 'b' || c == 'r' || c == 32
}

def free_tile(zone: long, x: long, z: long) -> bool {
    if (tile_blocks(tile(zone, x, z))) { return false; };
    for o in 0..NO {
        if (O_ZONE[o] != zone || O_KIND[o] != OK_SOLID) { continue; };
        if (x >= O_X[o] && x < O_X[o] + O_W[o] && z >= O_Z[o] && z < O_Z[o] + O_H[o]) { return false; };
    };
    true
}

def free_at(zone: long, px: long, pz: long) -> bool {
    let r = 16384;
    free_tile(zone, (px - r) >> 16, (pz - r) >> 16) &&
    free_tile(zone, (px + r) >> 16, (pz - r) >> 16) &&
    free_tile(zone, (px - r) >> 16, (pz + r) >> 16) &&
    free_tile(zone, (px + r) >> 16, (pz + r) >> 16)
}

def is_water(zone: long, x: long, z: long) -> bool { tile(zone, x, z) == '~' }
def is_passage(zone: long, px: long, pz: long) -> bool { tile(zone, px >> 16, pz >> 16) == 'P' }

def door_at(zone: long, x: long, z: long) -> long {
    for o in 0..NO {
        if (O_ZONE[o] == zone && O_KIND[o] == OK_DOOR && O_X[o] == x && O_Z[o] == z) { return o; };
    };
    -1
}

def nearest_door(zone: long, x: long, z: long, r: long) -> long {
    let best = -1;
    let bd = r * r + 1;
    for o in 0..NO {
        if (O_ZONE[o] != zone || O_KIND[o] != OK_DOOR || O_ARG[o] < 0) { continue; };
        let dx = O_X[o] - x;
        let dz = O_Z[o] - z;
        if (dx * dx + dz * dz < bd) {
            bd = dx * dx + dz * dz;
            best = o;
        };
    };
    best
}

def find(kind: long, zone: long, name: str) -> long {
    for o in 0..NO {
        if (O_KIND[o] != kind) { continue; };
        if (zone >= 0 && O_ZONE[o] != zone) { continue; };
        if (range_eq(O_NS[o], O_NE[o], name)) { return o; };
    };
    -1
}

def obj_is(o: long, name: str) -> bool { range_eq(O_NS[o], O_NE[o], name) }

def door_to(zone: long, dest: long) -> long {
    for o in 0..NO {
        if (O_ZONE[o] == zone && O_KIND[o] == OK_DOOR && O_ARG[o] == dest) { return o; };
    };
    -1
}

def spot_of(who: long, m: long) -> long {
    let best = -1;
    let best_min = -1;
    for i in 0..NSC {
        if (SC_WHO[i] != who) { continue; };
        if (SC_MIN[i] <= m && SC_MIN[i] >= best_min) {
            best = SC_SPOT[i];
            best_min = SC_MIN[i];
        };
    };
    best
}

let TIME = 0;
let NIGHT = 0;

def tile_color(c: long, x: long, z: long) -> long {
    let n = fx.noise(x, z, 7) & 15;
    if (c == '.') { return canvas.mixc(0x6aa152, 0x7bb35c, n * 12); };
    if (c == ',') { return canvas.mixc(0xb08a5a, 0xa07c50, n * 12); };
    if (c == ':') {
        let m = (x * 3 + z * 5) & 3;
        return if (m == 0) { 0xa9a296 } else if (m == 1) { 0xb4ad9f } else { 0x9f988c };
    };
    if (c == '~') {
        let w = fx.noise(x, z, TIME / 12) & 31;
        return canvas.mixc(0x3f7fb5, 0x6aa8d8, w * 5);
    };
    if (c == '=') { return if ((x & 1) == 0) { 0x8a6238 } else { 0x7d5832 }; };
    if (c == 'w') { return if (((x + z) & 1) == 0) { 0x9c7448 } else { 0x8f6a42 }; };
    if (c == 'f') { return if ((x & 1) == 0) { 0x8a7a3a } else { 0x6f8a3a }; };
    if (c == 's') { return canvas.mixc(0xd8c792, 0xcbb985, n * 12); };
    if (c == 'x') { return canvas.mixc(0x6d5a44, 0x5e4d3a, n * 12); };
    if (c == 'P') { return 0x8c8478; };
    if (c == 'T' || c == 'b' || c == 'r') { return canvas.mixc(0x5d9147, 0x6aa152, n * 12); };
    if (c == '#' || c == 'H' || c == 'h') { return 0x8d877c; };
    0x6aa152
}

let M_TREE = -1;
let M_TREE2 = -1;
let M_BUSH = -1;
let M_ROCK = -1;
const M_WALL = -1;
let M_CROP = -1;

def halo_line(x0: long, y0: long, x1: long, y1: long, a: long) -> void {
    let dx = x1 - x0;
    let dy = y1 - y0;
    let n = if (dx < 0) { 0 - dx } else { dx };
    let m = if (dy < 0) { 0 - dy } else { dy };
    if (m > n) { n = m; };
    if (n < 1) { n = 1; };
    for i in 0..(n + 1) { pix.blend(x0 + dx * i / n, y0 + dy * i / n, 0xffffff, a); };
}

def halo_tile(o: long, a: long) -> void {
    let x = O_X[o] * 65536;
    let z = O_Z[o] * 65536;
    r3d.project(x, 0, z);
    let ax = r3d.PX;
    let ay = r3d.PY;
    r3d.project(x + 65536, 0, z);
    let bx = r3d.PX;
    let by = r3d.PY;
    r3d.project(x + 65536, 0, z + 65536);
    let cx = r3d.PX;
    let cy = r3d.PY;
    r3d.project(x, 0, z + 65536);
    halo_line(ax, ay, bx, by, a);
    halo_line(bx, by, cx, cy, a);
    halo_line(cx, cy, r3d.PX, r3d.PY, a);
    halo_line(r3d.PX, r3d.PY, ax, ay, a);
}

def bind_meshes() -> void {
    M_TREE = r3d.mesh_id("tree");
    M_TREE2 = r3d.mesh_id("tree2");
    M_BUSH = r3d.mesh_id("bush");
    M_ROCK = r3d.mesh_id("rock");
    M_CROP = r3d.mesh_id("crop");
}

let FLOAT = false;
let FP = 0;
let FR = 0;
let FY = 0;
def float_at(x: long, z: long) -> void {
    if (!FLOAT) {
        FP = 0;
        FR = 0;
        FY = 0;
        return;
    };
    let k = fx.noise(x, z, 11);
    FP = (fx.sin(TIME * 2 + k * 40) >> 11) & 1023;
    FR = (fx.sin(TIME * 3 + k * 70 + 300) >> 11) & 1023;
    FY = 50000 + (fx.sin(TIME * 4 + k * 90) >> 2);
}

let DZ: [long; 16] = [0; 16];
let DOX: [long; 16] = [0; 16];
let DOZ: [long; 16] = [0; 16];
let ND = 0;

def drawn(z: long) -> bool {
    for i in 0..ND { if (DZ[i] == z) { return true; }; };
    false
}

def add_drawn(z: long, ox: long, oz: long) -> void {
    if (ND >= 16 || drawn(z)) { return; };
    DZ[ND] = z;
    DOX[ND] = ox;
    DOZ[ND] = oz;
    ND += 1;
}

def draw(zone: long) -> void {
    ND = 0;
    add_drawn(zone, 0, 0);
    if (!Z_INDOOR[zone]) {
        for k in 0..NB_N[zone] {
            add_drawn(NB_ZONE[zone * 4 + k], NB_OX[zone * 4 + k], NB_OZ[zone * 4 + k]);
        };

        let n1 = ND;
        for i in 1..n1 {
            let b = DZ[i];
            for k in 0..NB_N[b] {
                add_drawn(NB_ZONE[b * 4 + k], DOX[i] + NB_OX[b * 4 + k], DOZ[i] + NB_OZ[b * 4 + k]);
            };
        };
    };
    for i in 0..ND { draw_zone(i); };
    draw_shadows();
}

def claimed(x: long, z: long, upto: long) -> bool {
    for j in 0..upto {
        let lx = x - DOX[j];
        let lz = z - DOZ[j];
        if (lx >= 0 && lz >= 0 && lx < Z_W[DZ[j]] && lz < Z_H[DZ[j]]) { return true; };
    };
    false
}

def draw_zone(n: long) -> void {
    let zone = DZ[n];
    let ox = DOX[n];
    let oz = DOZ[n];
    let cx = r3d.CAM_X >> 16;
    let cz = r3d.CAM_Z >> 16;
    let rad = pix.PW / r3d.SCALE + 3;

    let x0 = fx.max(cx - rad, ox);
    let z0 = fx.max(cz - rad, oz);
    let x1 = fx.min(cx + rad, ox + Z_W[zone]);
    let z1 = fx.min(cz + rad, oz + Z_H[zone]);
    if (x0 >= x1 || z0 >= z1) { return; };
    let indoor = Z_INDOOR[zone];
    for z in z0..z1 {
        for x in x0..x1 {
            if (n > 0 && claimed(x, z, n)) { continue; };

            r3d.project(x * 65536 + 32768, 0, z * 65536 + 32768);
            if (r3d.PX < -2 * r3d.SCALE || r3d.PX > pix.PW + 2 * r3d.SCALE || r3d.PY < -6 * r3d.SCALE || r3d.PY > pix.PH + 2 * r3d.SCALE) { continue; };
            let lx = x - ox;
            let lz = z - oz;
            let c = tile(zone, lx, lz);
            if (c == 32 || c == 'v') { continue; };
            let col = r3d.lit(tile_color(c, lx, lz));
            let fx0 = x * 65536;
            let fz0 = z * 65536;
            if (c == '~') {
                r3d.ground_bias(fx0, fz0, fx0 + 65536, fz0 + 65536, -9000, col, 200);

                if (tile(zone, lx + 1, lz) != '~') { r3d.wall(fx0 + 65536, fz0 + 65536, fx0 + 65536, fz0, -9000, 0, r3d.lit(0x7a6a4c)); };
                if (tile(zone, lx, lz + 1) != '~') { r3d.wall(fx0, fz0 + 65536, fx0 + 65536, fz0 + 65536, -9000, 0, r3d.lit(0x6a5c42)); };
                continue;
            };
            if (c == '#' || c == 'H' || c == 'h') {
                let ht = if (c == 'H') { 98304 } else if (c == 'h') { 9000 } else { 30000 };
                draw_block(fx0, fz0, ht, tile_color(c, lx, lz), indoor);
                continue;
            };
            r3d.ground_bias(fx0, fz0, fx0 + 65536, fz0 + 65536, 0, col, 200);
            if (c == 'T') {
                let m = if ((fx.noise(lx, lz, 3) & 3) == 0 && M_TREE2 >= 0) { M_TREE2 } else { M_TREE };
                float_at(lx, lz);
                r3d.draw(m, fx0 + 32768, FY, fz0 + 32768, fx.noise(lx, lz, 5) * 4, 65536 + (fx.noise(lx, lz, 9) & 63) * 300, FP, FR, -1);
            } else if (c == 'b') {
                float_at(lx, lz);
                r3d.draw(M_BUSH, fx0 + 32768, FY, fz0 + 32768, 0, 65536, FP, FR, -1);
            } else if (c == 'r') {
                float_at(lx, lz);
                r3d.draw(M_ROCK, fx0 + 32768, FY, fz0 + 32768, fx.noise(lx, lz, 1) * 4, 65536, FP, FR, -1);
            } else if (c == 'f') {
                r3d.draw(M_CROP, fx0 + 32768, 0, fz0 + 32768, 0, 65536, 0, 0, -1);
            };
        };
    };

    for o in 0..NO {
        if (O_ZONE[o] != zone || O_KIND[o] != OK_MESH) { continue; };
        let px = O_X[o] + ox;
        let pz = O_Z[o] + oz;
        if (px < x0 - 4 || px > x1 + 4 || pz < z0 - 4 || pz > z1 + 4) { continue; };
        if (n > 0 && claimed(px, pz, n)) { continue; };
        float_at(O_X[o], O_Z[o]);
        r3d.draw(O_ARG[o], px * 65536 + 32768, FY, pz * 65536 + 32768, O_ROT[o] * 256, 65536, FP, FR, -1);
    };
}

let THING_MESH: [long; 512] = [-1; 512];
let TH_X0: [long; 512] = [0; 512];
let TH_X1: [long; 512] = [0; 512];
let TH_Z0: [long; 512] = [0; 512];
let TH_Z1: [long; 512] = [0; 512];

let MB_X0: [long; 512] = [0; 512];
let MB_X1: [long; 512] = [0; 512];
let MB_Z0: [long; 512] = [0; 512];
let MB_Z1: [long; 512] = [0; 512];
let MB_H: [long; 512] = [0; 512];

def bind_things() -> void {
    for mo in 0..NO {
        if (O_KIND[mo] != OK_MESH) { continue; };
        r3d.bbox(O_ARG[mo], O_X[mo] * 65536 + 32768, 0, O_Z[mo] * 65536 + 32768, O_ROT[mo] * 256);
        MB_X0[mo] = r3d.BW_X0;
        MB_X1[mo] = r3d.BW_X1;
        MB_Z0[mo] = r3d.BW_Z0;
        MB_Z1[mo] = r3d.BW_Z1;
        MB_H[mo] = r3d.BH;
    };
    for o in 0..NO {
        THING_MESH[o] = -1;
        if (O_KIND[o] != OK_THING) { continue; };
        let cx = O_X[o] * 65536 + 32768;
        let cz = O_Z[o] * 65536 + 32768;
        let best = -1;
        let barea = 1 << 50;
        for mo in 0..NO {
            if (O_ZONE[mo] != O_ZONE[o] || O_KIND[mo] != OK_MESH) { continue; };
            r3d.bbox(O_ARG[mo], O_X[mo] * 65536 + 32768, 0, O_Z[mo] * 65536 + 32768, O_ROT[mo] * 256);

            let nx = fx.max(r3d.BW_X0, fx.min(cx, r3d.BW_X1));
            let nz = fx.max(r3d.BW_Z0, fx.min(cz, r3d.BW_Z1));
            let dd = fx.len2((nx - cx) >> 4, (nz - cz) >> 4) << 4;
            if (dd > 144000) { continue; };
            let area = dd * 4096 + (((r3d.BW_X1 - r3d.BW_X0) >> 8) * ((r3d.BW_Z1 - r3d.BW_Z0) >> 8) >> 6);
            if (area < barea) {
                barea = area;
                best = mo;
                TH_X0[o] = r3d.BW_X0;
                TH_X1[o] = r3d.BW_X1;
                TH_Z0[o] = r3d.BW_Z0;
                TH_Z1[o] = r3d.BW_Z1;
            };
        };
        THING_MESH[o] = best;
    };
}

def stairs_door(zone: long, x: long, z: long) -> long {
    let up = r3d.mesh_id("stairs_up");
    let dn = r3d.mesh_id("stairs_down");
    let px = x * 65536 + 32768;
    let pz = z * 65536 + 32768;
    for o in 0..NO {
        if (O_ZONE[o] != zone || O_KIND[o] != OK_MESH || (O_ARG[o] != up && O_ARG[o] != dn)) { continue; };
        if (px >= MB_X0[o] && px <= MB_X1[o] && pz >= MB_Z0[o] && pz <= MB_Z1[o]) {
            return nearest_door(zone, x, z, 8);
        };
    };
    -1
}

def halo_thing(o: long, strength: long) -> bool {
    let mo = THING_MESH[o];
    if (mo < 0) { return false; };
    let x = O_X[mo] * 65536 + 32768;
    let z = O_Z[mo] * 65536 + 32768;
    float_at(O_X[mo], O_Z[mo]);
    let yaw = O_ROT[mo] * 256;
    r3d.bbox(O_ARG[mo], x, FY, z, yaw);
    let x0 = fx.max(r3d.BX0 - 1, 0);
    let x1 = fx.min(r3d.BX1 + 1, pix.PW - 1);
    let y0 = fx.max(r3d.BY0 - 1, 0);
    let y1 = fx.min(r3d.BY1 + 1, pix.PH - 1);
    pix.MASK_ON = true;
    r3d.draw(O_ARG[mo], x, FY, z, yaw, 65536, FP, FR, 0);
    pix.MASK_ON = false;
    for py in y0..(y1 + 1) {
        for px in x0..(x1 + 1) {
            let i = py * pix.MAXW + px;
            if (pix.MASK[i] != 0) { continue; };
            let near = (px > 0 && pix.MASK[i - 1] != 0) || (px + 1 < pix.PW && pix.MASK[i + 1] != 0) ||
                       (py > 0 && pix.MASK[i - pix.MAXW] != 0) || (py + 1 < pix.PH && pix.MASK[i + pix.MAXW] != 0);
            if (near) { pix.blend(px, py, 0xffffff, strength); };
        };
    };
    for py in y0..(y1 + 1) {
        for px in x0..(x1 + 1) { pix.MASK[py * pix.MAXW + px] = 0; };
    };
    true
}

def sh_tri(ax: long, az: long, bx: long, bz: long, cx: long, cz: long) -> void {
    r3d.project(ax, 0, az);
    let a0 = r3d.PSX;
    let a1 = r3d.PSY;
    let a2 = r3d.PD;
    r3d.project(bx, 0, bz);
    let b0 = r3d.PSX;
    let b1 = r3d.PSY;
    let b2 = r3d.PD;
    r3d.project(cx, 0, cz);
    pix.tri(a0, a1, a2, b0, b1, b2, r3d.PSX, r3d.PSY, r3d.PD, 0);
}

def sh_quad(ax: long, az: long, bx: long, bz: long, cx: long, cz: long, dx: long, dz: long) -> void {
    sh_tri(ax, az, bx, bz, cx, cz);
    sh_tri(ax, az, cx, cz, dx, dz);
}

def sh_sweep(x0: long, z0: long, x1: long, z1: long, vx: long, vz: long) -> void {
    sh_quad(x0, z0, x1, z0, x1 + vx, z0 + vz, x0 + vx, z0 + vz);
    sh_quad(x1, z0, x1, z1, x1 + vx, z1 + vz, x1 + vx, z0 + vz);
    sh_quad(x1, z1, x0, z1, x0 + vx, z1 + vz, x1 + vx, z1 + vz);
    sh_quad(x0, z1, x0, z0, x0 + vx, z0 + vz, x0 + vx, z1 + vz);
    sh_quad(x0 + vx, z0 + vz, x1 + vx, z0 + vz, x1 + vx, z1 + vz, x0 + vx, z1 + vz);
}

def sh_blob(cx: long, cz: long, rl: long, rp: long) -> void {
    let dx = SUN_WX;
    let dz = SUN_WZ;
    let px = 0 - SUN_WZ;
    let pz = SUN_WX;
    let lx = 0;
    let lz = 0;
    for k in 0..9 {
        let a = k * 128;
        let c = fx.cos(a);
        let s = fx.sin(a);
        let x = cx + ((c * rl >> 16) * dx >> 16) + ((s * rp >> 16) * px >> 16);
        let z = cz + ((c * rl >> 16) * dz >> 16) + ((s * rp >> 16) * pz >> 16);
        if (k > 0) { sh_tri(cx, cz, lx, lz, x, z); };
        lx = x;
        lz = z;
    };
}

def sh_len(h: long) -> long { (SUN_LEN * h) >> 8 }

def sh_tree(cx: long, cz: long) -> void {
    let l = sh_len(98304);
    let vx = (SUN_WX * (l * 6 / 10)) >> 16;
    let vz = (SUN_WZ * (l * 6 / 10)) >> 16;
    sh_sweep(cx - 4500, cz - 4500, cx + 4500, cz + 4500, vx, vz);
    let ex = (SUN_WX * (l * 8 / 10)) >> 16;
    let ez = (SUN_WZ * (l * 8 / 10)) >> 16;
    sh_blob(cx + ex, cz + ez, 30000 + (l >> 3), 30000);
}

def sh_small(cx: long, cz: long, h: long, r: long) -> void {
    let l = sh_len(h);
    sh_blob(cx + ((SUN_WX * (l / 2)) >> 16), cz + ((SUN_WZ * (l / 2)) >> 16), r + (l / 3), r);
}

def shadows_zone(n: long) -> void {
    let zone = DZ[n];
    let ox = DOX[n];
    let oz = DOZ[n];
    let cx = r3d.CAM_X >> 16;
    let cz = r3d.CAM_Z >> 16;
    let rad = pix.PW / r3d.SCALE + 3;
    let x0 = fx.max(cx - rad, ox);
    let z0 = fx.max(cz - rad, oz);
    let x1 = fx.min(cx + rad, ox + Z_W[zone]);
    let z1 = fx.min(cz + rad, oz + Z_H[zone]);
    if (x0 >= x1 || z0 >= z1) { return; };
    for z in z0..z1 {
        for x in x0..x1 {
            let c = tile(zone, x - ox, z - oz);
            if (c != 'T' && c != 'b' && c != 'r') { continue; };
            if (n > 0 && claimed(x, z, n)) { continue; };
            let px = x * 65536 + 32768;
            let pz = z * 65536 + 32768;
            if (c == 'T') {
                sh_tree(px, pz);
            } else if (c == 'b') {
                sh_small(px, pz, 36000, 22000);
            } else {
                sh_small(px, pz, 30000, 20000);
            };
        };
    };
    for o in 0..NO {
        if (O_ZONE[o] != zone || O_KIND[o] != OK_MESH || MB_H[o] < 26000) { continue; };
        let mx = O_X[o] + ox;
        let mz = O_Z[o] + oz;
        if (mx < x0 - 4 || mx > x1 + 4 || mz < z0 - 4 || mz > z1 + 4) { continue; };
        if (n > 0 && claimed(mx, mz, n)) { continue; };
        let l = sh_len(MB_H[o]);
        sh_sweep(MB_X0[o] + ox * 65536, MB_Z0[o] + oz * 65536, MB_X1[o] + ox * 65536, MB_Z1[o] + oz * 65536, (SUN_WX * l) >> 16, (SUN_WZ * l) >> 16);
    };
}

def draw_shadows() -> void {
    if (SUN_A <= 0) { return; };
    pix.MASK_ON = true;
    pix.MASK_BIAS = 900;
    for n in 0..ND { shadows_zone(n); };
    pix.MASK_ON = false;
    pix.MASK_BIAS = 0;
    let shade = 0x161a38;
    for y in 0..pix.PH {
        let row = y * pix.MAXW;
        for x in 0..pix.PW {
            if (pix.MASK[row + x] != 0) {
                pix.PC[row + x] = canvas.mixc(pix.PC[row + x], shade, SUN_A);
                pix.MASK[row + x] = 0;
            };
        };
    };
}

def draw_block(fx0: long, fz0: long, ht: long, base: long, indoor: bool) -> void {
    let top = r3d.lit(canvas.mixc(base, 0xffffff, 40));
    let side_x = r3d.shade(base, 65536, 0, 0, false);
    let side_z = r3d.shade(base, 0, 0, 65536, false);
    r3d.ground(fx0, fz0, fx0 + 65536, fz0 + 65536, ht, top);
    r3d.wall(fx0 + 65536, fz0 + 65536, fx0 + 65536, fz0, 0, ht, side_x);
    r3d.wall(fx0, fz0 + 65536, fx0 + 65536, fz0 + 65536, 0, ht, side_z);
}

export {
    load, bind_meshes, bind_things, halo_thing, halo_tile, THING_MESH, TH_X0, TH_X1, TH_Z0, TH_Z1, draw, tile, free_tile, free_at, is_water, is_passage,
    door_at, door_to, find, obj_is, zone_id, person_id, range_eq,
    Z_W, Z_H, Z_INDOOR, NZ, O_KIND, O_ZONE, O_X, O_Z, O_W, O_H, O_ARG, O_ROT,
    O_NS, O_NE, NO, P_NAME, P_SPR_S, P_SPR_E, P_ID_S, P_ID_E, NPEOPLE, SRC,
    OK_MESH, OK_SOLID, OK_DOOR, OK_THING, OK_HOME, OK_SPOT, OK_LAMP, OK_SPAWN,
    TIME, NIGHT, FLOAT, SUN_A, SUN_U, SUN_V, SUN_LEN, set_sun, PT_ADDR, PT_S, PT_E, NPAINT, SC_WHO, SC_MIN, SC_SPOT, NSC, spot_of
};
