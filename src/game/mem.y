
let N = 256;
const ARENA_N = 16384;
let ARENA: [byte; 16384] = [0; 16384];
let OFF: [long; 256] = [0; 256];
let CAP: [long; 256] = [0; 256];
let TAG: [long; 256] = [0; 256];
let REF: [long; 256] = [-1; 256];
let LIVE: [bool; 256] = [false; 256];

let FREE: [long; 256] = [0; 256];
let FREE_N = 0;

const T_NONE = 0;
const T_WATCHER = 1;
const T_CONST = 2;
const T_CODE = 3;
const T_GLOBAL = 4;
const T_HUD = 5;
const T_PLAYER = 6;
const T_NPC = 7;
const T_ITEM = 8;
const T_VESSEL = 9;
const T_SIGN = 10;
const T_STELE = 11;
const T_RULE = 12;
const T_LETTER = 13;
const T_MONSTER = 14;
const T_GRAVE = 15;
const T_BLADE = 16;
const T_FINGER = 17;

const A_WATCHER = 0x07;
const A_HAND = 0x13;
const A_WEIGHT = 0x21;
const A_BELL = 0x22;
const A_HOURS = 0x23;
const A_HP = 0x40;
const A_MAP = 0x41;
const A_DIALOG = 0x42;
const A_PLAYER = 0x60;
const A_BLADE = 0x9E;
const A_SHOPSIGN = 0x9F;
const A_STELE = 0xA0;
const A_RULE1 = 0xA1;
const A_LETTER = 0xC0;

const R_TOWNS_LO = 0x61;
const R_TOWNS_HI = 0x7F;
const R_ITEMS_LO = 0x80;
const R_ITEMS_HI = 0x8F;
const R_MON_LO = 0xE0;
const R_MON_HI = 0xFF;

const CODE_LEN = 32;
let CODE: [byte; 32] = [0; 32];

def rune(v: long) -> long { 16 + (v & 15) }
def is_rune(b: long) -> bool { b >= 16 && b < 32 }
def rune_val(b: long) -> long { b - 16 }

def layout() -> void {
    for a in 0..N { CAP[a] = 0; };
    CAP[A_HAND] = 32;
    for a in 0x00..0x10 { CAP[a] = 4; };
    CAP[A_WATCHER] = 8;
    for a in 0x20..0x40 { CAP[a] = 4; };
    for a in 0x40..0x60 { CAP[a] = 4; };
    for a in 0x60..0x80 { CAP[a] = 12; };
    for a in 0x80..0x9E { CAP[a] = 12; };
    CAP[A_BLADE] = 12;
    CAP[A_SHOPSIGN] = 16;
    CAP[A_STELE] = 8;
    CAP[0xA1] = 24;
    CAP[0xA2] = 28;
    CAP[0xA3] = 32;
    CAP[0xA4] = 24;
    for a in 0xA5..0xC0 { CAP[a] = 16; };
    CAP[A_LETTER] = 32;
    for a in 0xC1..0xE0 { CAP[a] = 8; };
    for a in 0xE0..0x100 { CAP[a] = 8; };
    let off = 0;
    for a in 0..N {
        OFF[a] = off;
        off += CAP[a] + 2;
    };

    for i in 0..CODE_LEN {
        CODE[i] = rune(((i * 7 + 3) ^ (i >> 1) ^ (i * i)) & 15);
    };
}

def reset() -> void {
    for i in 0..ARENA_N { ARENA[i] = 0; };
    for a in 0..N {
        TAG[a] = T_NONE;
        REF[a] = -1;
        LIVE[a] = false;
    };
    FREE_N = 0;
    let a = N - 1;
    while (a >= 0) {
        FREE[FREE_N] = a;
        FREE_N += 1;
        a -= 1;
    };
}

def remove_free(a: long) -> bool {
    let k = FREE_N - 1;
    while (k >= 0) {
        if (FREE[k] == a) {
            for j in k..(FREE_N - 1) { FREE[j] = FREE[j + 1]; };
            FREE_N -= 1;
            return true;
        };
        k -= 1;
    };
    false
}

def alloc(lo: long, hi: long, tag: long, ref: long) -> long {
    let k = FREE_N - 1;
    while (k >= 0) {
        let a = FREE[k];
        if (a >= lo && a <= hi) {
            for j in k..(FREE_N - 1) { FREE[j] = FREE[j + 1]; };
            FREE_N -= 1;
            LIVE[a] = true;
            TAG[a] = tag;
            REF[a] = ref;
            return a;
        };
        k -= 1;
    };
    -1
}

def alloc_at(a: long, tag: long, ref: long) -> long {
    if (a < 0 || a >= N) { return -1; };
    if (!LIVE[a]) { remove_free(a); };
    LIVE[a] = true;
    TAG[a] = tag;
    REF[a] = ref;
    a
}

def free(a: long) -> bool {
    if (a < 0 || a >= N || !LIVE[a]) { return false; };
    LIVE[a] = false;
    FREE[FREE_N] = a;
    FREE_N += 1;
    true
}

def peek(lo: long, hi: long) -> long {
    let k = FREE_N - 1;
    while (k >= 0) {
        let a = FREE[k];
        if (a >= lo && a <= hi) { return a; };
        k -= 1;
    };
    -1
}

let WB: [byte; 256] = [0; 256];
let WB_N = 0;

def wb_clear() -> void { WB_N = 0; }
def wb_add(b: long) -> void {
    if (WB_N < 256) {
        WB[WB_N] = b;
        WB_N += 1;
    };
}
def wb_str(s: str) -> void {
    foreach (b in s) { wb_add(b); };
}

def write(a: long) -> long {
    let base = OFF[a];
    for i in 0..WB_N {
        if (base + i < ARENA_N) { ARENA[base + i] = WB[i]; };
    };
    for i in WB_N..CAP[a] { ARENA[base + i] = 0; };
    if (WB_N > CAP[a]) { WB_N - CAP[a] } else { 0 }
}

def set_text(a: long, s: str) -> void {
    wb_clear();
    wb_str(s);
    if (WB_N > CAP[a]) { WB_N = CAP[a]; };
    write(a);
}

def byte_at(a: long, i: long) -> long {
    let p = OFF[a] + i;
    if (p < 0 || p >= ARENA_N) { return 0; };
    ARENA[p]
}

def text_len(a: long) -> long {
    let n = 0;
    while (n < CAP[a] && byte_at(a, n) != 0) { n += 1; };
    n
}

def link(a: long) -> long {
    let b0 = byte_at(a, CAP[a]);
    let b1 = byte_at(a, CAP[a] + 1);
    if (!is_rune(b0) || !is_rune(b1)) { return -1; };
    rune_val(b0) * 16 + rune_val(b1)
}

def set_link(a: long, to: long) -> void {
    let p = OFF[a] + CAP[a];
    ARENA[p] = rune(to >> 4);
    ARENA[p + 1] = rune(to);
}

def is_code(a: long) -> bool {
    if (a < 0 || a >= N || !LIVE[a]) { return false; };
    for i in 0..CODE_LEN {
        if (byte_at(a, i) != CODE[i]) { return false; };
    };
    true
}

def exec(h: long, target: long) -> bool {
    if (h < 0) { return false; };
    is_code(h)
}

let SB: [byte; 128] = [0; 128];
let SB_N = 0;
def scrape(a: long, extra: long) -> long {
    SB_N = 0;
    let n = CAP[a] + 2 + extra;
    if (n > 128) { n = 128; };
    for i in 0..n {
        SB[SB_N] = byte_at(a, i);
        SB_N += 1;
    };
    SB_N
}

export {
    layout, reset, alloc, alloc_at, free, peek, write, set_text, byte_at,
    text_len, link, set_link, is_code, exec, scrape, rune, is_rune, rune_val,
    wb_clear, wb_add, wb_str, remove_free,
    ARENA, OFF, CAP, TAG, REF, LIVE, FREE, FREE_N, WB, WB_N, SB, SB_N, CODE,
    CODE_LEN, N, ARENA_N,
    T_NONE, T_WATCHER, T_CONST, T_CODE, T_GLOBAL, T_HUD, T_PLAYER, T_NPC,
    T_ITEM, T_VESSEL, T_SIGN, T_STELE, T_RULE, T_LETTER, T_MONSTER, T_GRAVE,
    T_BLADE, T_FINGER,
    A_WATCHER, A_HAND, A_WEIGHT, A_BELL, A_HOURS, A_HP, A_MAP, A_DIALOG,
    A_PLAYER, A_BLADE, A_SHOPSIGN, A_STELE, A_RULE1, A_LETTER,
    R_TOWNS_LO, R_TOWNS_HI, R_ITEMS_LO, R_ITEMS_HI, R_MON_LO, R_MON_HI
};
