
import world;
import fx;

const STRIDE = 40;
let NT = 1600;
let G: [long; 1600] = [0; 1600];
let FROM: [long; 1600] = [-1; 1600];
let STATE: [byte; 1600] = [0; 1600];
let BLK: [byte; 1600] = [0; 1600];
let OPEN: [long; 1600] = [0; 1600];
let NOPEN = 0;

let MAXP = 64;
let PX: [long; 64] = [0; 64];
let PZ: [long; 64] = [0; 64];
let N = 0;

let ZONE = 0;
let GOAL_X = -1;
let GOAL_Z = -1;

def tile_cost(zone: long, x: long, z: long) -> long {
    let c = world.tile(zone, x, z);
    if (c == ',' || c == ':' || c == '=') { return 8; };

    if (c == 'P') { return 40; };
    if (c == 'w') { return 9; };
    if (c == 'f') { return 18; };
    if (c == 's') { return 12; };
    if (c == 'x') { return 14; };
    11
}

def free(x: long, z: long) -> bool {
    if (x < 0 || z < 0 || x >= world.Z_W[ZONE] || z >= world.Z_H[ZONE]) { return false; };
    let i = z * STRIDE + x;
    if (BLK[i] == 0) {
        BLK[i] = if (world.free_tile(ZONE, x, z) && (world.door_at(ZONE, x, z) < 0 || (x == GOAL_X && z == GOAL_Z))) { 1 } else { 2 };
    };
    BLK[i] == 1
}

def abs(v: long) -> long { if (v < 0) { 0 - v } else { v } }

def heur(x: long, z: long, gx: long, gz: long) -> long {
    let dx = abs(x - gx);
    let dz = abs(z - gz);
    let lo = if (dx < dz) { dx } else { dz };
    8 * (dx + dz) - 3 * lo
}

def push_open(i: long) -> void {
    OPEN[NOPEN] = i;
    NOPEN += 1;
}

def pop_best(gx: long, gz: long) -> long {
    let bk = 0;
    let bf = 1 << 40;
    for k in 0..NOPEN {
        let i = OPEN[k];
        let f = G[i] + heur(i % STRIDE, i / STRIDE, gx, gz);
        if (f < bf) {
            bf = f;
            bk = k;
        };
    };
    let r = OPEN[bk];
    NOPEN -= 1;
    OPEN[bk] = OPEN[NOPEN];
    r
}

def clear_line(ax: long, az: long, bx: long, bz: long) -> bool {
    let dx = bx - ax;
    let dz = bz - az;
    let len = fx.len2(dx >> 4, dz >> 4) << 4;
    let n = len / 16384 + 1;
    for k in 0..(n + 1) {
        let x = ax + dx * k / n;
        let z = az + dz * k / n;
        if (!world.free_at(ZONE, x, z)) { return false; };
        let tx = x >> 16;
        let tz = z >> 16;
        if (world.door_at(ZONE, tx, tz) >= 0 && !(tx == GOAL_X && tz == GOAL_Z)) { return false; };
    };
    true
}

def line_cost(ax: long, az: long, bx: long, bz: long) -> long {
    let dx = bx - ax;
    let dz = bz - az;
    let len = fx.len2(dx >> 4, dz >> 4) << 4;
    let n = len / 32768 + 1;
    let total = 0;
    for k in 0..n {
        let x = ax + dx * (2 * k + 1) / (2 * n);
        let z = az + dz * (2 * k + 1) / (2 * n);
        total += tile_cost(ZONE, x >> 16, z >> 16) * (len / n) / 65536;
    };
    total
}

def plan(zone: long, sx: long, sz: long, gx: long, gz: long) -> long {
    ZONE = zone;
    N = 0;
    if (world.Z_W[zone] > STRIDE || world.Z_H[zone] > STRIDE) { return 0; };
    for i in 0..NT {
        STATE[i] = 0;
        BLK[i] = 0;
    };
    let stx = sx >> 16;
    let stz = sz >> 16;
    let gtx = gx >> 16;
    let gtz = gz >> 16;
    GOAL_X = gtx;
    GOAL_Z = gtz;
    if (stx == gtx && stz == gtz) {
        PX[0] = gx;
        PZ[0] = gz;
        N = 1;
        return 1;
    };

    BLK[stz * STRIDE + stx] = 1;
    let s = stz * STRIDE + stx;
    G[s] = 0;
    FROM[s] = -1;
    STATE[s] = 1;
    NOPEN = 0;
    push_open(s);
    let goal = gtz * STRIDE + gtx;
    let best = s;
    let best_h = heur(stx, stz, gtx, gtz);
    let found = false;
    let goal_free = free(gtx, gtz);
    while (NOPEN > 0) {
        let i = pop_best(gtx, gtz);
        STATE[i] = 2;
        let x = i % STRIDE;
        let z = i / STRIDE;
        let h = heur(x, z, gtx, gtz);
        if (h < best_h) {
            best_h = h;
            best = i;
        };
        if (i == goal) {
            found = true;
            break;
        };
        for d in 0..8 {
            let ox = if (d == 0 || d == 4 || d == 5) { 1 } else if (d == 1 || d == 6 || d == 7) { -1 } else { 0 };
            let oz = if (d == 2 || d == 4 || d == 6) { 1 } else if (d == 3 || d == 5 || d == 7) { -1 } else { 0 };
            if (ox == 0 && oz == 0) { continue; };
            let nx = x + ox;
            let nz = z + oz;
            if (!free(nx, nz)) { continue; };

            if (ox != 0 && oz != 0 && (!free(x + ox, z) || !free(x, z + oz))) { continue; };
            let j = nz * STRIDE + nx;
            if (STATE[j] == 2) { continue; };
            let step = tile_cost(zone, nx, nz) * (if (ox != 0 && oz != 0) { 14 } else { 10 }) / 10;
            let ng = G[i] + step;
            if (STATE[j] == 0 || ng < G[j]) {
                G[j] = ng;
                FROM[j] = i;
                if (STATE[j] == 0) { push_open(j); };
                STATE[j] = 1;
            };
        };
    };
    let end = if (found) { goal } else { best };

    let cnt = 0;
    let k = end;
    while (k >= 0 && cnt < 200) {
        OPEN[cnt] = k;
        cnt += 1;
        k = FROM[k];
    };
    if (cnt <= 1 && !found) { return 0; };

    let m = 0;
    let t = cnt - 1;
    while (t >= 0) {
        let tile = OPEN[t];
        if (m < MAXP) {
            PX[m] = (tile % STRIDE) * 65536 + 32768;
            PZ[m] = (tile / STRIDE) * 65536 + 32768;

            m += 1;
        };
        t -= 1;
    };
    if (found && goal_free && m > 0 && world.free_at(zone, gx, gz)) {
        PX[m - 1] = gx;
        PZ[m - 1] = gz;
    };

    let outn = 0;
    let i = 0;
    let ox = sx;
    let oz = sz;

    while (i < m && outn < MAXP) {
        let jbest = i;
        let j = m - 1;
        while (j > i) {
            if (clear_line(ox, oz, PX[j], PZ[j])) {

                let way = 0;
                let px = ox;
                let pz = oz;
                for q in i..(j + 1) {
                    way += line_cost(px, pz, PX[q], PZ[q]);
                    px = PX[q];
                    pz = PZ[q];
                };
                if (line_cost(ox, oz, PX[j], PZ[j]) * 100 <= way * 108) {
                    jbest = j;
                    break;
                };
            };
            j -= 1;
        };

        let kx = PX[jbest];
        let kz = PZ[jbest];
        PX[outn] = kx;
        PZ[outn] = kz;
        outn += 1;
        ox = kx;
        oz = kz;
        i = jbest + 1;
    };
    N = outn;
    N
}

export { plan, PX, PZ, N };
