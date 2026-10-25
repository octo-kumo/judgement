
let NONCE: [long; 3] = [0; 3];
let ST: [long; 16] = [0; 16];
let X: [long; 16] = [0; 16];
let BLK: [byte; 64] = [0; 64];
let READY = false;

let KW: [long; 8] = [0; 8];
let KN: [long; 3] = [0; 3];
let MODE = 0;

def rotl32(x: long, n: long) -> long { ((x << n) | (x >>> (32 - n))) & 0xffffffff }

def qr(a: long, b: long, c: long, d: long) -> void {
    X[a] = (X[a] + X[b]) & 0xffffffff;
    X[d] = rotl32(X[d] ^ X[a], 16);
    X[c] = (X[c] + X[d]) & 0xffffffff;
    X[b] = rotl32(X[b] ^ X[c], 12);
    X[a] = (X[a] + X[b]) & 0xffffffff;
    X[d] = rotl32(X[d] ^ X[a], 8);
    X[c] = (X[c] + X[d]) & 0xffffffff;
    X[b] = rotl32(X[b] ^ X[c], 7);
}

def key_word(i: long) -> long {
    let x = (0x9e3779b9 * (i + 1) + 0x243f6a88) & 0xffffffff;
    x = ((x ^ (x >>> 16)) * 0x85ebca6b) & 0xffffffff;
    x = ((x ^ (x >>> 13)) * 0xc2b2ae35) & 0xffffffff;
    (x ^ (x >>> 16)) & 0xffffffff
}

def block(counter: long) -> void {
    ST[0] = 0x61707865;
    ST[1] = 0x3320646e;
    ST[2] = 0x79622d32;
    ST[3] = 0x6b206574;
    if (MODE == 1) {
        for i in 0..8 { ST[4 + i] = KW[i]; };
        ST[13] = KN[0];
        ST[14] = KN[1];
        ST[15] = KN[2];
    } else {
        for i in 0..8 { ST[4 + i] = key_word(i); };
        ST[13] = NONCE[0];
        ST[14] = NONCE[1];
        ST[15] = NONCE[2];
    };
    ST[12] = counter & 0xffffffff;
    for i in 0..16 { X[i] = ST[i]; };
    for r in 0..10 {
        qr(0, 4, 8, 12);
        qr(1, 5, 9, 13);
        qr(2, 6, 10, 14);
        qr(3, 7, 11, 15);
        qr(0, 5, 10, 15);
        qr(1, 6, 11, 12);
        qr(2, 7, 8, 13);
        qr(3, 4, 9, 14);
    };
    for i in 0..16 {
        let v = (X[i] + ST[i]) & 0xffffffff;
        BLK[i * 4] = v & 255;
        BLK[i * 4 + 1] = (v >> 8) & 255;
        BLK[i * 4 + 2] = (v >> 16) & 255;
        BLK[i * 4 + 3] = (v >> 24) & 255;
    };
}

def begin() -> void {
    if (READY) { return; };
    let t = clock_us();
    NONCE[0] = t & 0xffffffff;
    NONCE[1] = (t >>> 32) & 0xffffffff;
    NONCE[2] = 0x6a09e667 ^ ((t >>> 7) & 0xffffffff);
    READY = true;
}

def seed(key: [byte], nonce: [byte]) -> void {
    if (len(key) != 32 || len(nonce) != 12) { return; };
    for i in 0..8 {
        KW[i] = key[i * 4] | (key[i * 4 + 1] << 8) | (key[i * 4 + 2] << 16) | (key[i * 4 + 3] << 24);
    };
    for i in 0..3 {
        KN[i] = nonce[i * 4] | (nonce[i * 4 + 1] << 8) | (nonce[i * 4 + 2] << 16) | (nonce[i * 4 + 3] << 24);
    };
    MODE = 1;
}

def ks(counter: long, out: [byte; 64]) -> void {
    block(counter);
    for i in 0..64 { out[i] = BLK[i]; };
}

def otk() -> [byte] {
    block(0);
    BLK[0:32]
}

def seal(src: str) -> void {
    MODE = 0;
    begin();
    let n = len(src);
    let p: *byte = ptr_from(ptr_addr(src));
    let i = 0;
    while (i < n) {
        block(i >>> 6);
        let k = i & 63;
        while (i < n && k < 64) {
            *(p + i) = *(p + i) ^ BLK[k];
            i += 1;
            k += 1;
        };
    };
}

def open(src: str, from: long, to: long, out: str) -> long {
    MODE = 0;
    begin();
    let n = to - from;
    if (n <= 0) { return 0; };
    let sp: *byte = ptr_from(ptr_addr(src));
    let op: *byte = ptr_from(ptr_addr(out));
    let i = 0;
    let at = from;
    while (i < n) {
        block(at >>> 6);
        let k = at & 63;
        while (i < n && k < 64) {
            *(op + i) = *(sp + at) ^ BLK[k];
            i += 1;
            at += 1;
            k += 1;
        };
    };
    n
}

def wipe(src: str) -> void {
    let n = len(src);
    let p: *byte = ptr_from(ptr_addr(src));
    for i in 0..n { *(p + i) = 0; };
}

export { begin, seed, ks, otk, seal, open, wipe };
