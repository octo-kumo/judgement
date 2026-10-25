
import math;

const ONE = 65536;
const HALF = 32768;
const ANG = 1024;
let SIN: [long; 1024] = [0; 1024];

def init() -> void {
    for i in 0..1024 {
        let a = math.pi * 2.0 * tofloat(i)! / 1024.0;
        SIN[i] = tolong(math.sin(a) * 65536.0)!;
    };
}

def sin(a: long) -> long { SIN[a & 1023] }
def cos(a: long) -> long { SIN[(a + 256) & 1023] }

def mul(a: long, b: long) -> long { (a * b) >> 16 }

def div(a: long, b: long) -> long {
    if (b == 0) { return 0; };
    (a << 16) / b
}

def from_int(v: long) -> long { v << 16 }
def to_int(v: long) -> long { v >> 16 }

def round(v: long) -> long { (v + HALF) >> 16 }

def lerp(a: long, b: long, t: long) -> long { a + (((b - a) * t) >> 16) }

def abs(v: long) -> long { if (v < 0) { 0 - v } else { v } }
def min(a: long, b: long) -> long { if (a < b) { a } else { b } }
def max(a: long, b: long) -> long { if (a > b) { a } else { b } }
def clamp(v: long, lo: long, hi: long) -> long {
    if (v < lo) { return lo; };
    if (v > hi) { return hi; };
    v
}

def isqrt(n: long) -> long {
    if (n <= 0) { return 0; };
    let x = n;
    let y = (x + 1) / 2;
    while (y < x) {
        x = y;
        y = (x + n / x) / 2;
    };
    x
}

def len2(x: long, y: long) -> long { isqrt(x * x + y * y) }

def atan2(y: long, x: long) -> long {
    if (x == 0 && y == 0) { return 0; };
    let ax = abs(x);
    let ay = abs(y);

    let a = 0;
    if (ax >= ay) {
        let t = (ay << 16) / ax;
        a = (t * 128) >> 16;
        a = a + (((t * (65536 - t)) >> 16) * 22 >> 16);
    } else {
        let t = (ax << 16) / ay;
        a = 256 - ((t * 128) >> 16) - (((t * (65536 - t)) >> 16) * 22 >> 16);
    };
    if (x < 0) { a = 512 - a; };
    if (y < 0) { a = 1024 - a; };
    a & 1023
}

let SEED = 88172645463325252;

def seed(s: long) -> void {
    SEED = if (s == 0) { 88172645463325252 } else { s };
}

def rand() -> long {
    let x = SEED;
    x = x ^ (x >> 12);
    x = x ^ (x << 25);
    x = x ^ (x >> 27);
    SEED = x;
    ((x * 2685821657736338717) >> 33) & 0x7fffffff
}

def rnd(n: long) -> long {
    if (n <= 1) { return 0; };
    rand() % n
}

def noise(x: long, y: long, t: long) -> long {
    let h = (x * 374761393 + y * 668265263 + t * 2246822519) & 0xffffffff;
    h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff;
    (h ^ (h >> 16)) & 255
}

export {
    init, sin, cos, mul, div, from_int, to_int, round, lerp, abs, min, max, clamp,
    isqrt, len2, atan2, seed, rand, rnd, noise, ONE, HALF, ANG
};
