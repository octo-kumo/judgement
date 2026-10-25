
import canvas;

const MAXW = 256;
const MAXH = 256;
let PC: [long; 65536] = [0; 65536];
let PZ: [long; 65536] = [0; 65536];
let PW = 80;
let PH = 48;
const FAR = 0x3fffffffffff;
let SUB = 16;

let MASK: [byte; 65536] = [0; 65536];
let MASK_ON = false;
let MASK_BIAS = 0;

def resize() -> void {
    PW = canvas.W;
    PH = canvas.H * 2;
}

def clear(c: long) -> void {
    for y in 0..PH {
        let row = y * MAXW;
        for x in 0..PW {
            PC[row + x] = c;
            PZ[row + x] = FAR;
        };
    };
}

def clear_grad(top: long, bot: long) -> void {
    for y in 0..PH {
        let t = if (PH > 1) { y * 256 / (PH - 1) } else { 0 };
        let c = canvas.mixc(top, bot, t);
        let row = y * MAXW;
        for x in 0..PW {
            PC[row + x] = c;
            PZ[row + x] = FAR;
        };
    };
}

def pset(x: long, y: long, z: long, c: long) -> void {
    if (x < 0 || y < 0 || x >= PW || y >= PH) { return; };
    let i = y * MAXW + x;
    if (z <= PZ[i]) {
        PZ[i] = z;
        PC[i] = c;
    };
}

def pover(x: long, y: long, c: long) -> void {
    if (x < 0 || y < 0 || x >= PW || y >= PH) { return; };
    PC[y * MAXW + x] = c;
}

def blend(x: long, y: long, c: long, t: long) -> void {
    if (x < 0 || y < 0 || x >= PW || y >= PH) { return; };
    let i = y * MAXW + x;
    PC[i] = canvas.mixc(PC[i], c, t);
}

def get(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= PW || y >= PH) { return 0; };
    PC[y * MAXW + x]
}

def depth(x: long, y: long) -> long {
    if (x < 0 || y < 0 || x >= PW || y >= PH) { return FAR; };
    PZ[y * MAXW + x]
}

def fill_rect(x: long, y: long, w: long, h: long, z: long, c: long) -> void {
    for yy in y..(y + h) {
        for xx in x..(x + w) { pset(xx, yy, z, c); };
    };
}

def line(x0: long, y0: long, z0: long, x1: long, y1: long, z1: long, c: long) -> void {
    let dx = if (x1 > x0) { x1 - x0 } else { x0 - x1 };
    let dy = if (y1 > y0) { y0 - y1 } else { y1 - y0 };
    let sx = if (x0 < x1) { 1 } else { -1 };
    let sy = if (y0 < y1) { 1 } else { -1 };
    let err = dx + dy;
    let x = x0;
    let y = y0;
    let n = if (dx > 0 - dy) { dx } else { 0 - dy };
    let k = 0;
    while (true) {
        let z = if (n > 0) { z0 + (z1 - z0) * k / n } else { z0 };
        pset(x, y, z, c);
        if (x == x1 && y == y1) { break; };
        let e2 = 2 * err;
        if (e2 >= dy) { err += dy; x += sx; };
        if (e2 <= dx) { err += dx; y += sy; };
        k += 1;
        if (k > 4096) { break; };
    };
}

def tri(ax: long, ay: long, az: long, bx: long, by: long, bz: long, cx: long, cy: long, cz: long, c: long) -> void {
    let area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    if (area == 0) { return; };
    let x0 = ax;
    let x1 = ax;
    let y0 = ay;
    let y1 = ay;
    if (bx < x0) { x0 = bx; };
    if (cx < x0) { x0 = cx; };
    if (bx > x1) { x1 = bx; };
    if (cx > x1) { x1 = cx; };
    if (by < y0) { y0 = by; };
    if (cy < y0) { y0 = cy; };
    if (by > y1) { y1 = by; };
    if (cy > y1) { y1 = cy; };

    let px0 = x0 / SUB;
    let px1 = (x1 + SUB - 1) / SUB;
    let py0 = y0 / SUB;
    let py1 = (y1 + SUB - 1) / SUB;
    if (px0 < 0) { px0 = 0; };
    if (py0 < 0) { py0 = 0; };
    if (px1 > PW) { px1 = PW; };
    if (py1 > PH) { py1 = PH; };
    if (px0 >= px1 || py0 >= py1) { return; };

    let bxx = bx;
    let byy = by;
    let bzz = bz;
    let cxx = cx;
    let cyy = cy;
    let czz = cz;
    if (area < 0) {
        bxx = cx;
        byy = cy;
        bzz = cz;
        cxx = bx;
        cyy = by;
        czz = bz;
        area = 0 - area;
    };

    let sx0 = px0 * SUB + SUB / 2;
    let sy0 = py0 * SUB + SUB / 2;

    let a0 = byy - cyy;
    let b0 = cxx - bxx;
    let a1 = cyy - ay;
    let b1 = ax - cxx;
    let a2 = ay - byy;
    let b2 = bxx - ax;
    let r0 = (cxx - bxx) * (sy0 - byy) - (cyy - byy) * (sx0 - bxx);
    let r1 = (ax - cxx) * (sy0 - cyy) - (ay - cyy) * (sx0 - cxx);
    let r2 = (bxx - ax) * (sy0 - ay) - (byy - ay) * (sx0 - ax);

    let bias0 = if (a0 > 0 || (a0 == 0 && b0 < 0)) { 0 } else { -1 };
    let bias1 = if (a1 > 0 || (a1 == 0 && b1 < 0)) { 0 } else { -1 };
    let bias2 = if (a2 > 0 || (a2 == 0 && b2 < 0)) { 0 } else { -1 };
    let sa0 = a0 * SUB;
    let sa1 = a1 * SUB;
    let sa2 = a2 * SUB;
    let sb0 = b0 * SUB;
    let sb1 = b1 * SUB;
    let sb2 = b2 * SUB;
    let flat = az == bzz && az == czz;
    for py in py0..py1 {

        let lo = px0;
        let hi = px1 - 1;
        let ok = true;

        let t0 = r0 + bias0;
        if (sa0 > 0) {
            let need = ceil_div(0 - t0, sa0);
            if (need > lo - px0) { lo = px0 + need; };
        } else if (sa0 < 0) {
            let top = floor_div(t0, 0 - sa0);
            if (px0 + top < hi) { hi = px0 + top; };
        } else if (t0 < 0) {
            ok = false;
        };
        let t1 = r1 + bias1;
        if (sa1 > 0) {
            let need = ceil_div(0 - t1, sa1);
            if (need > lo - px0) { lo = px0 + need; };
        } else if (sa1 < 0) {
            let top = floor_div(t1, 0 - sa1);
            if (px0 + top < hi) { hi = px0 + top; };
        } else if (t1 < 0) {
            ok = false;
        };
        let t2 = r2 + bias2;
        if (sa2 > 0) {
            let need = ceil_div(0 - t2, sa2);
            if (need > lo - px0) { lo = px0 + need; };
        } else if (sa2 < 0) {
            let top = floor_div(t2, 0 - sa2);
            if (px0 + top < hi) { hi = px0 + top; };
        } else if (t2 < 0) {
            ok = false;
        };
        if (ok && lo <= hi) {
            let row = py * MAXW;
            let k = lo - px0;
            let w0 = r0 + sa0 * k;
            let w1 = r1 + sa1 * k;
            let w2 = r2 + sa2 * k;
            for px in lo..(hi + 1) {
                let z = if (flat) { az } else { (w0 * az + w1 * bzz + w2 * czz) / area };
                let i = row + px;
                if (MASK_ON) {
                    if (z <= PZ[i] + MASK_BIAS) { MASK[i] = 1; };
                } else if (z <= PZ[i]) {
                    PZ[i] = z;
                    PC[i] = c;
                };
                w0 += sa0;
                w1 += sa1;
                w2 += sa2;
            };
        };
        r0 += sb0;
        r1 += sb1;
        r2 += sb2;
    };
}

def ceil_div(n: long, d: long) -> long {
    if (n >= 0) { (n + d - 1) / d } else { 0 - ((0 - n) / d) }
}

def floor_div(n: long, d: long) -> long {
    if (n >= 0) { n / d } else { 0 - ((0 - n + d - 1) / d) }
}

def compose() -> void {
    let rows = PH / 2;
    for cy in 0..rows {
        let top = cy * 2 * MAXW;
        let bot = top + MAXW;
        let crow = cy * canvas.MAXC;
        for x in 0..PW {
            let a = PC[top + x];
            let b = PC[bot + x];
            let i = crow + x;
            if (a == b) {
                canvas.CH[i] = 32;
                canvas.FG[i] = a;
                canvas.BG[i] = a;
            } else {
                canvas.CH[i] = 0x2580;
                canvas.FG[i] = a;
                canvas.BG[i] = b;
            };
            canvas.AT[i] = 0;
        };
    };
}

def cell_depth(cx: long, cy: long) -> long {
    let a = depth(cx, cy * 2);
    let b = depth(cx, cy * 2 + 1);
    if (a < b) { a } else { b }
}

def cell_depth_far(cx: long, cy: long) -> long {
    let a = depth(cx, cy * 2);
    let b = depth(cx, cy * 2 + 1);
    if (a > b) { a } else { b }
}

def cell_color(cx: long, cy: long) -> long {
    canvas.mixc(get(cx, cy * 2), get(cx, cy * 2 + 1), 128)
}

export {
    resize, clear, clear_grad, pset, pover, blend, get, depth, fill_rect, line,
    tri, compose, cell_depth, cell_depth_far, cell_color, PW, PH, PC, PZ, FAR,
    SUB, MAXW, MASK, MASK_ON, MASK_BIAS
};
