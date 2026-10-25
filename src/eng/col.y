
def rgb(r: long, g: long, b: long) -> long {
    (clamp(r) << 16) | (clamp(g) << 8) | clamp(b)
}

def clamp(v: long) -> long {
    if (v < 0) { return 0; };
    if (v > 255) { return 255; };
    v
}

def r(c: long) -> long { (c >> 16) & 255 }
def g(c: long) -> long { (c >> 8) & 255 }
def b(c: long) -> long { c & 255 }

def mix(a: long, b2: long, t: long) -> long {
    if (t <= 0) { return a; };
    if (t >= 256) { return b2; };
    let u = 256 - t;
    rgb((r(a) * u + r(b2) * t) >> 8, (g(a) * u + g(b2) * t) >> 8, (b(a) * u + b(b2) * t) >> 8)
}

def mul(a: long, m: long) -> long {
    rgb((r(a) * r(m)) / 255, (g(a) * g(m)) / 255, (b(a) * b(m)) / 255)
}

def scale(a: long, s: long) -> long {
    rgb((r(a) * s) >> 8, (g(a) * s) >> 8, (b(a) * s) >> 8)
}

def add(a: long, b2: long) -> long {
    rgb(r(a) + r(b2), g(a) + g(b2), b(a) + b(b2))
}

def luma(c: long) -> long {
    (r(c) * 77 + g(c) * 150 + b(c) * 29) >> 8
}

def grey(v: long) -> long { rgb(v, v, v) }

def desat(c: long, t: long) -> long {
    mix(c, grey(luma(c)), t)
}

export { rgb, clamp, r, g, b, mix, mul, scale, add, luma, grey, desat };
