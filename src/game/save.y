
import fs;
import crypto;
import g;
import mem;
import guard;

let DIR = "";
let PATH = "";
let RETRY_PATH = "";
let BASE = "";

def seal_key() -> [byte] {
    let s: [byte] = [];
    let x = 0x1f83d9ab;
    for i in 0..40 {
        x = (x * 69069 + 7 + i * 2654435761) & 0x7fffffff;
        s += (x >> 9) & 255;
    };
    let tag: [byte] = [0x48, 0x52, 0x53, 0x56, 0x32];
    crypto.sha256(s + tag)
}

def seal_nonce() -> [byte] {
    let tag: [byte] = [0x73, 0x61, 0x76, 0x65];
    crypto.sha256(seal_key() + tag)[0:12]
}

def warm() -> void { paths(); }

def paths() -> void {
    if (len(BASE) == 0) {
        let base = "";
        if let str x = fs.getenv("XDG_DATA_HOME") { base = x; };
        if (len(base) == 0) {
            if let str h = fs.getenv("HOME") { base = h + "/.local/share"; };
        };
        if (len(base) == 0) {
            if let str a = fs.getenv("APPDATA") { base = a; };
        };
        if (len(base) == 0) { base = "."; };
        BASE = base;
    };
    DIR = BASE + "/heavenly-rules";
    PATH = DIR + "/save.bin";
    RETRY_PATH = DIR + "/retries";
}

def put32(b: [byte], v: long) -> void {
    b += v & 255;
    b += (v >> 8) & 255;
    b += (v >> 16) & 255;
    b += (v >> 24) & 255;
}

def get32(b: [byte], at: long) -> long {
    b[at] | (b[at + 1] << 8) | (b[at + 2] << 16) | (b[at + 3] << 24)
}

def write() -> bool {
    paths();
    fs.make_dirs(DIR);
    let p: [byte] = bytes("HRSV2");
    put32(p, g.LOOP);
    put32(p, g.DAY);
    put32(p, if (g.HAND_FREED) { 1 } else { 0 });
    put32(p, if (g.HANDLESS) { 1 } else { 0 });
    put32(p, g.VOID_LAUNCHES);
    put32(p, g.LEVEL);
    put32(p, g.XP);
    put32(p, g.HP_MAX);
    put32(p, g.ATK);
    put32(p, g.COINS);
    put32(p, g.BOOTS);
    for f in 0..64 { p += if (g.FLAG[f]) { 1 } else { 0 }; };
    for a in 0..256 {
        p += if (mem.LIVE[a]) { 1 } else { 0 };
        p += mem.TAG[a] & 255;
    };
    for i in 0..mem.ARENA_N { p += mem.ARENA[i]; };

    let aad: [byte] = [0x48, 0x52, 0x53, 0x56, 0x32];
    let body = crypto.chacha_seal(seal_key(), seal_nonce(), aad, p[5:len(p)]);
    let out: [byte] = aad;
    out += body;
    fs.write_bytes(PATH, out)
}

def read(heap: bool) -> bool {
    paths();
    let r = fs.read_bytes(PATH);
    if (r == none) { return false; };
    let raw = r!;
    if (len(raw) < 5 || raw[0] != 'H' || raw[1] != 'R' || raw[2] != 'S' || raw[3] != 'V') { return false; };
    if (raw[4] != '2') { guard.tamper(); };
    let aad: [byte] = [0x48, 0x52, 0x53, 0x56, 0x32];
    let open_ = crypto.chacha_open(seal_key(), seal_nonce(), aad, raw[5:len(raw)]);
    if (open_ == none) { guard.tamper(); };
    let b = open_!;
    let need = 11 * 4 + 64 + 512 + mem.ARENA_N;
    if (len(b) < need) { guard.tamper(); };
    let p = 0;
    g.LOOP = get32(b, p); p += 4;
    g.DAY = get32(b, p); p += 4;
    g.HAND_FREED = get32(b, p) == 1; p += 4;
    g.HANDLESS = get32(b, p) == 1; p += 4;
    g.VOID_LAUNCHES = get32(b, p); p += 4;
    g.LEVEL = get32(b, p); p += 4;
    g.XP = get32(b, p); p += 4;
    g.HP_MAX = get32(b, p); p += 4;
    g.ATK = get32(b, p); p += 4;
    g.COINS = get32(b, p); p += 4;
    g.BOOTS = get32(b, p); p += 4;
    for f in 0..64 { g.FLAG[f] = b[p + f] == 1; };
    p += 64;
    if (heap) {
        for a in 0..256 {
            mem.LIVE[a] = b[p + a * 2] == 1;
            mem.TAG[a] = b[p + a * 2 + 1];
        };
        p += 512;
        for i in 0..mem.ARENA_N { mem.ARENA[i] = b[p + i]; };

        mem.FREE_N = 0;
        let a = 255;
        while (a >= 0) {
            if (!mem.LIVE[a]) {
                mem.FREE[mem.FREE_N] = a;
                mem.FREE_N += 1;
            };
            a -= 1;
        };
    };
    true
}

def exists() -> bool {
    paths();
    fs.exists(PATH)
}

def delete_save() -> void {
    paths();
    fs.remove_file(PATH);
    let n = read_retries() + 1;
    fs.make_dirs(DIR);
    fs.write_file(RETRY_PATH, tostring(n));
}

def read_setting(name: str) -> str {
    paths();
    let r = fs.read_file(DIR + "/" + name);
    if (r == none) { return ""; };
    r!.trim()
}

def write_setting(name: str, value: str) -> void {
    paths();
    fs.make_dirs(DIR);
    fs.write_file(DIR + "/" + name, value);
}

def read_retries() -> long {
    paths();
    let r = fs.read_file(RETRY_PATH);
    if (r == none) { return 0; };
    if let long v = tolong(r!) { return v; };
    0
}

export { write, read, exists, delete_save, read_retries, read_setting, write_setting, warm, PATH };
