
import crypto;
import veil;

let CHUNK = 32768;
const MAXPARTS = 8;
const MAXCHUNKS = 128;
const SALT_N = 16;
const TAG_N = 16;
const PART_MAX = 65536;
const VERSION = 3;

let READY = false;
let NPARTS = 0;
let NCHUNK: [long; 8] = [0; 8];
let RAWLEN: [long; 8] = [0; 8];
let CH0: [long; 8] = [0; 8];
let CTLEN: [long; 128] = [0; 128];
let COFF: [long; 128] = [0; 128];
let BLOB = "";
let BB: [byte] = [];
let SALT: [byte] = [];
let SKEY: [byte] = [];
let KS: [byte; 64] = [0; 64];

def secret() -> [byte] {
    let s: [byte] = [];
    let x = 0x2f6b9c31;
    for i in 0..48 {
        x = (x * 1103515245 + 12345 + i * 7919) & 0x7fffffff;
        s += (x >> 11) & 255;
    };
    s
}

let SECRET: [byte] = secret();

def master(salt: [byte]) -> [byte] {
    let tag: [byte] = [0x76, 0x33, 0x03];
    crypto.sha256(SECRET + salt + tag)
}

def piece_key(i: long, k: long) -> [byte] {
    let t: [byte] = [0x63, i & 255, (k >> 8) & 255, k & 255, 0x03];
    crypto.sha256(SKEY + t)
}

def piece_nonce(i: long, k: long) -> [byte] {
    let t: [byte] = [0x6e, i & 255, (k >> 8) & 255, k & 255, 0x03];
    crypto.sha256(SKEY + t)[0:12]
}

def hdr_nonce() -> [byte] {
    let t: [byte] = [0x68, 0x03];
    crypto.sha256(SKEY + t)[0:12]
}

def put16(b: [byte], v: long) -> void {
    b += v & 255;
    b += (v >> 8) & 255;
}

def put32(b: [byte], v: long) -> void {
    b += v & 255;
    b += (v >> 8) & 255;
    b += (v >> 16) & 255;
    b += (v >> 24) & 255;
}

def get16(b: str, at: long) -> long {
    let x: long = b[at];
    x | (b[at + 1] << 8)
}

def get32(b: str, at: long) -> long {
    let x: long = b[at];
    x | (b[at + 1] << 8) | (b[at + 2] << 16) | (b[at + 3] << 24)
}

def cipher_piece(i: long, k: long, piece: [byte]) -> [byte] {
    veil.seed(piece_key(i, k), piece_nonce(i, k));
    let otk = veil.otk();
    let n = len(piece);
    let j = 0;
    while (j < n) {
        veil.ks(1 + (j >>> 6), KS);
        let b = j & 63;
        while (j < n && b < 64) { piece[j] = piece[j] ^ KS[b]; j += 1; b += 1; };
    };
    let out: [byte] = [];
    out += piece;
    out += crypto.poly1305(otk, piece);
    for a in 0..64 { KS[a] = 0; };
    for a in 0..len(otk) { otk[a] = 0; };
    out
}

def seal(parts: [str]) -> str {
    let salt = crypto.random_bytes(SALT_N);
    SALT = salt;
    SKEY = master(salt);
    let n = len(parts);
    let nch: [long; 8] = [0; 8];
    let raw: [long; 8] = [0; 8];
    for i in 0..n {
        raw[i] = len(parts[i]);
        nch[i] = (raw[i] + CHUNK - 1) / CHUNK;
        if (nch[i] < 1) { nch[i] = 1; };
    };

    let hdr: [byte] = [VERSION, n];
    for i in 0..n { put16(hdr, nch[i]); put32(hdr, raw[i]); };
    let body: [byte] = [];
    for i in 0..n {
        let b = bytes(parts[i]);
        for k in 0..nch[i] {
            let a = k * CHUNK;
            let z = a + CHUNK;
            if (z > raw[i]) { z = raw[i]; };
            let piece: [byte] = [];
            if (a < z) { piece = b[a:z]; };
            let sealed = cipher_piece(i, k, piece);
            put32(hdr, len(sealed));
            body += sealed;
        };
    };
    let hs = crypto.chacha_seal(SKEY, hdr_nonce(), salt, hdr);
    let out: [byte] = [];
    out += salt;
    put32(out, len(hs));
    out += hs;
    out += body;
    from_bytes(out)
}

def open(blob: str) -> bool {
    if (READY) { return true; };
    BLOB = blob;
    if (len(blob) < SALT_N + 4) { return false; };
    BB = bytes(blob);
    let b = BB;
    SALT = b[0:SALT_N];
    SKEY = master(SALT);
    let hl = get32(blob, SALT_N);
    if (hl < 1 || SALT_N + 4 + hl > len(blob)) { return false; };
    let hdr = crypto.chacha_open(SKEY, hdr_nonce(), SALT, b[SALT_N + 4:SALT_N + 4 + hl]);
    if (hdr == none) { return false; };
    let h = from_bytes(hdr!);
    if (len(h) < 2 || h[0] != VERSION) { return false; };
    NPARTS = h[1];
    if (NPARTS < 1 || NPARTS > MAXPARTS) { return false; };
    let at = 2;
    let total = 0;
    for i in 0..NPARTS {
        if (at + 6 > len(h)) { return false; };
        NCHUNK[i] = get16(h, at);
        RAWLEN[i] = get32(h, at + 2);
        at += 6;
        if (RAWLEN[i] < 0 || RAWLEN[i] > PART_MAX) { return false; };

        let want = (RAWLEN[i] + CHUNK - 1) / CHUNK;
        if (want < 1) { want = 1; };
        if (NCHUNK[i] != want || total + NCHUNK[i] > MAXCHUNKS) { return false; };
        CH0[i] = total;
        total += NCHUNK[i];
    };
    if (at + total * 4 > len(h)) { return false; };
    let o = SALT_N + 4 + hl;
    for k in 0..total {
        CTLEN[k] = get32(h, at);
        at += 4;

        if (CTLEN[k] < TAG_N || CTLEN[k] - TAG_N > CHUNK) { return false; };
        if (o + CTLEN[k] > len(blob)) { return false; };
        COFF[k] = o;
        o += CTLEN[k];
    };

    if (o != len(blob)) { return false; };
    READY = true;
    true
}

def nparts() -> long { NPARTS }

def part_len(i: long) -> long {
    if (i < 0 || i >= NPARTS) { return -1; };
    RAWLEN[i]
}

def nchunks(i: long) -> long {
    if (i < 0 || i >= NPARTS) { return 0; };
    NCHUNK[i]
}

def piece_into(i: long, k: long, dst: *byte, at: long, want: long) -> bool {
    if (!READY || i < 0 || i >= NPARTS || k < 0 || k >= NCHUNK[i]) { return false; };
    let c = CH0[i] + k;
    let clen = CTLEN[c] - TAG_N;
    if (clen != want || clen < 0 || clen > CHUNK) { return false; };
    let o = COFF[c];

    for a in 0..64 { KS[a] = 0; };
    veil.seed(piece_key(i, k), piece_nonce(i, k));
    let otk = veil.otk();
    let tag = crypto.poly1305(otk, BB[o:o + clen]);
    let good = crypto.bytes_eq(tag, BB[o + clen:o + clen + TAG_N]);
    for a in 0..len(otk) { otk[a] = 0; };
    if (!good) { return false; };
    let j = 0;
    while (j < clen) {
        veil.ks(1 + (j >>> 6), KS);
        let b = j & 63;
        while (j < clen && b < 64) { *(dst + at + j) = BB[o + j] ^ KS[b]; j += 1; b += 1; };
    };
    for a in 0..64 { KS[a] = 0; };
    true
}

def get(i: long) -> str? {
    if (!READY || i < 0 || i >= NPARTS) { return none; };
    let total = RAWLEN[i];
    if (total < 0 || total > PART_MAX) { return none; };

    let s = (" ").repeat(total);
    let p: *byte = ptr_from(ptr_addr(s));
    let at = 0;
    for k in 0..NCHUNK[i] {
        let want = CHUNK;
        if (at + want > total) { want = total - at; };
        if (!piece_into(i, k, p, at, want)) { veil.wipe(s); return none; };
        at += want;
    };
    if (at != total) { veil.wipe(s); return none; };
    some(s)
}

def ok() -> bool { READY }

def forget() -> void {
    READY = false;
    NPARTS = 0;
    BLOB = "";
    BB = [];
    SALT = [];
    SKEY = [];
    for k in 0..MAXCHUNKS { CTLEN[k] = 0; COFF[k] = 0; };
    for i in 0..MAXPARTS { NCHUNK[i] = 0; RAWLEN[i] = 0; CH0[i] = 0; };
}

export {
    seal, open, ok, get, nparts, nchunks, part_len, forget, CHUNK
};
