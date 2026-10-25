
import canvas;
import fx;
import r3d;
import style;
import text;

const MAXB = 64;
let B_X: [long; 64] = [0; 64];
let B_Y: [long; 64] = [0; 64];
let B_T: [long; 64] = [0; 64];
let B_LIFE: [long; 64] = [0; 64];
let B_SEED: [long; 64] = [0; 64];
let B_ADDR: [long; 64] = [-1; 64];
let B_HOLD: [bool; 64] = [false; 64];
let NB = 0;
let FLASH = 0;

def clear() -> void {
    NB = 0;
    FLASH = 0;
}

def add(cx: long, cy: long, life: long, addr: long) -> long {
    if (NB >= MAXB) {

        for i in 1..NB {
            B_X[i - 1] = B_X[i];
            B_Y[i - 1] = B_Y[i];
            B_T[i - 1] = B_T[i];
            B_LIFE[i - 1] = B_LIFE[i];
            B_SEED[i - 1] = B_SEED[i];
            B_ADDR[i - 1] = B_ADDR[i];
            B_HOLD[i - 1] = B_HOLD[i];
        };
        NB -= 1;
    };
    let i = NB;
    NB += 1;
    B_X[i] = cx;
    B_Y[i] = cy;
    B_T[i] = 0;
    B_LIFE[i] = life;
    B_SEED[i] = fx.rand();
    B_ADDR[i] = addr;
    B_HOLD[i] = false;
    if (FLASH < 150) { FLASH = 150; };
    i
}

def strike_world(x: long, y: long, z: long, addr: long) -> long {
    r3d.project(x, y, z);
    add(r3d.PX, r3d.PY / 2, 16, addr)
}

def tick() -> void {
    let k = 0;
    for i in 0..NB {
        B_T[i] += 1;
        if (B_T[i] < B_LIFE[i] || B_HOLD[i]) {
            if (k != i) {
                B_X[k] = B_X[i];
                B_Y[k] = B_Y[i];
                B_T[k] = B_T[i];
                B_LIFE[k] = B_LIFE[i];
                B_SEED[k] = B_SEED[i];
                B_ADDR[k] = B_ADDR[i];
                B_HOLD[k] = B_HOLD[i];
            };
            k += 1;
        };
    };
    NB = k;
    if (FLASH > 0) { FLASH -= 12; };
    if (FLASH < 0) { FLASH = 0; };
}

def bolt_glyph(dx: long) -> long {
    if (dx < 0) { return 0x2571; };
    if (dx > 0) { return 0x2572; };
    0x2502
}

let TR_CH: [long; 256] = [0; 256];
let TR_FG: [long; 256] = [0; 256];
let TR_BG: [long; 256] = [0; 256];
def tear(y: long, h: long, dx: long) -> void {
    for r in y..(y + h) {
        if (r < 0 || r >= canvas.H) { continue; };
        let row = r * canvas.MAXC;
        for x in 0..canvas.W {
            TR_CH[x] = canvas.CH[row + x];
            TR_FG[x] = canvas.FG[row + x];
            TR_BG[x] = canvas.BG[row + x];
        };
        for x in 0..canvas.W {
            let sx = x - dx;
            if (sx < 0) { sx += canvas.W; };
            if (sx >= canvas.W) { sx -= canvas.W; };
            canvas.CH[row + x] = TR_CH[sx];
            canvas.FG[row + x] = TR_FG[sx];
            canvas.BG[row + x] = TR_BG[sx];
        };
    };
}

def split_cell(x: long, y: long, g: long, col: long, bright: long) -> void {
    if (!canvas.inside(x, y)) { return; };
    canvas.put(x, y, g, canvas.mixc(canvas.get_bg(x, y), col, bright * 3 / 4), canvas.KEEP, 0);
}

def draw_path(i: long, sx: long, top: long, tx: long, ty: long, bright: long) -> void {
    let x = sx;
    let s = B_SEED[i];
    let white = canvas.mixc(0x9fb8ff, 0xffffff, bright);
    let wide = 1 + bright / 128;
    for y in top..(ty + 1) {
        s = (s * 1103515245 + 12345) & 0x7fffffff;
        let left = ty - y;
        let want = tx - x;
        let dx = 0;
        if (left > 0 && (want * 2 > left || want * 2 < 0 - left)) {
            dx = if (want > 0) { 1 } else { -1 };
        } else {
            let r = (s >> 9) % 5;
            if (r == 0) { dx = -1; };
            if (r == 1) { dx = 1; };
            if (left < 2) { dx = 0; };
        };
        x += dx;
        let jr = ((s >> 12) & 3);
        let jc = ((s >> 14) & 3);

        for k in 0..(2 + wide) {
            split_cell(x - 2 - k - jr, y, 0x2588, 0xff2a48, bright - k * 50);
            split_cell(x + 2 + k + jc, y, 0x2588, 0x20e8ff, bright - k * 50);
        };

        if (((s >> 5) & 7) == 0) {
            let dir = if (((s >> 8) & 1) == 0) { -1 } else { 1 };
            let n = 3 + ((s >> 9) & 7);
            let shade = 0x2591 + ((s >> 13) % 3);
            for k in 0..n {
                canvas.put(x + dir * (4 + k), y, shade, if (dir < 0) { 0xff4060 } else { 0x40f0ff }, canvas.KEEP, 0);
            };
        };

        for k in -1..2 {
            let g: long = 0x2588;
            if (((s >> 4) & 31) == 0 && k != 0) { g = style.RUNE[(s >> 8) & 15]; };
            canvas.put(x + k, y, g, white, canvas.mixc(canvas.get_bg(x + k, y), 0xffffff, bright / 2), canvas.BOLD);
        };

        if (((s >> 16) & 15) == 0 && left > 6) {
            let d2 = if (((s >> 20) & 1) == 0) { -1 } else { 1 };
            for k in 1..(4 + ((s >> 21) & 3)) {
                canvas.put(x + d2 * k, y + k, bolt_glyph(d2), white, canvas.KEEP, canvas.BOLD);
                canvas.put(x + d2 * k + 1, y + k, 0x2588, canvas.mixc(white, 0xff3050, 120), canvas.KEEP, 0);
            };
        };
    };
}

def draw() -> void {
    for i in 0..NB {
        let t = B_T[i];
        let life = B_LIFE[i];
        let bright = if (B_HOLD[i]) { 256 } else { 256 - t * 256 / (life + 1) };
        if (bright < 0) { bright = 0; };

        let top = if (t == 0) { B_Y[i] / 2 } else { 0 };
        let sx = B_X[i] + ((B_SEED[i] >> 3) % 9) - 4;
        draw_path(i, sx, top, B_X[i], B_Y[i], bright);

        if (bright > 90) {
            let n = 2 + bright / 70;
            for k in 0..n {
                let y = (B_Y[i] + fx.rnd(11) - 6);
                tear(y, 1 + fx.rnd(2), fx.rnd(9) - 4);
            };
        };

        if (t == 1 && B_ADDR[i] >= 0) {
            text.runes(B_X[i] + 2, B_Y[i], B_ADDR[i], style.GLITCH);
        };
    };
    if (FLASH > 0) { canvas.fade_all(0xffffff, FLASH / 2); };
}

def hold(i: long, on: bool) -> void {
    if (i >= 0 && i < NB) { B_HOLD[i] = on; };
}

const MAXA = 160;
let A_X: [long; 160] = [0; 160];
let A_Y: [long; 160] = [0; 160];
let A_V: [long; 160] = [0; 160];
let A_D: [long; 160] = [0; 160];
let ASH_ON = false;

def ash_init() -> void {
    for i in 0..MAXA {
        A_X[i] = fx.rnd(canvas.W * 256);
        A_Y[i] = fx.rnd(canvas.H * 256);
        A_V[i] = 20 + fx.rnd(40);
        A_D[i] = fx.rnd(3);
    };
    ASH_ON = true;
}

def ash_draw(cam_dx: long, cam_dy: long) -> void {
    if (!ASH_ON) { return; };
    let w = canvas.W * 256;
    let h = canvas.H * 256;
    for i in 0..MAXA {
        let d = A_D[i] + 1;
        A_Y[i] += A_V[i] / d;
        A_X[i] += (fx.sin(A_Y[i] / 64 + i * 40) >> 12) / d - cam_dx * d / 3;
        A_Y[i] -= cam_dy * d / 3;
        if (A_Y[i] >= h) { A_Y[i] -= h; };
        if (A_Y[i] < 0) { A_Y[i] += h; };
        if (A_X[i] >= w) { A_X[i] -= w; };
        if (A_X[i] < 0) { A_X[i] += w; };
        let c = if (A_D[i] == 0) { 0x8a8580 } else if (A_D[i] == 1) { 0xa8a49e } else { 0xc8c4be };
        let g: long = 46;
        if (A_D[i] == 0) { g = 0x2219; };
        if (A_D[i] == 1) { g = 0x00B7; };
        canvas.put(A_X[i] / 256, A_Y[i] / 256, g, c, canvas.KEEP, 0);
    };
}

export {
    clear, add, strike_world, tick, draw, hold, ash_init, ash_draw,
    NB, FLASH, B_HOLD, ASH_ON
};
