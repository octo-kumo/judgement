
import fs;
import term;

let ARMED = false;
let HEALTH = 0x9e3779b9;
let BAD = 0;
let WHEN = 0;
let FRAME = 0;
let LAST_US = 0;
let NOW = 0;

def trap() -> void {
    let a: [long; 2] = [0; 2];
    print(a[2 + (HEALTH & 15)]);
}

def tamper() -> void {
    BAD += 1;
    trap();
}

def find_at(hay: str, needle: str) -> long {
    let n = len(needle);
    if (n == 0 || n > len(hay)) { return -1; };
    let i = 0;
    while (i + n <= len(hay)) {
        let k = 0;
        while (k < n && hay[i + k] == needle[k]) { k += 1; };
        if (k == n) { return i; };
        i += 1;
    };
    -1
}

def find(hay: str, needle: str) -> bool { find_at(hay, needle) >= 0 }

let TOK: [str; 20] = [
    "gdb", "frida", "radare", "rizin", "valgrind", "dynamorio", "drrun",
    "ltrace", "libasan", "libtsan", "libubsan", "libSegFault", "sdbg",
    "x64dbg", "plthook", "libhook", "libinject", "librr", "libcapstone",
    "libunicorn"
];

def line_bad(l: str) -> bool {
    if (find(l, "/dev/shm/") && find(l, "r-xp")) { return true; };
    if (!find(l, ".so")) { return false; };
    for t in 0..20 { if (find(l, TOK[t])) { return true; }; };
    false
}

def maps_bad(m: str) -> bool {
    let i = 0;
    while (i < len(m)) {
        let e = i;
        while (e < len(m) && m[e] != 10) { e += 1; };
        if (line_bad(m[i:e])) { return true; };
        i = e + 1;
    };
    false
}

def tracer_pid(st: str) -> long {
    let i = find_at(st, "TracerPid:");
    if (i < 0) { return 0; };
    let j = i + 10;
    while (j < len(st) && (st[j] == ' ' || st[j] == 9)) { j += 1; };
    let v = 0;
    while (j < len(st) && st[j] >= '0' && st[j] <= '9') {
        v = v * 10 + (st[j] - '0');
        j += 1;
    };
    v
}

def read(path: str) -> str {
    let t = fs.read_file(path);
    if (t == none) { return ""; };
    t!
}

def env_set(name: str) -> bool {
    if let str v = fs.getenv(name) { return len(v.trim()) > 0; };
    false
}

let PARENTS: [str; 10] = ["gdb", "gdbserver", "strace", "ltrace", "rr", "valgrind", "radare2", "r2", "rizin", "frida-server"];

def parent_bad(st: str) -> bool {
    let pp = 0;
    let at = find_at(st, "PPid:");
    if (at < 0) { return false; };
    let j = at + 5;
    while (j < len(st) && (st[j] == ' ' || st[j] == 9)) { j += 1; };
    while (j < len(st) && st[j] >= '0' && st[j] <= '9') { pp = pp * 10 + (st[j] - '0'); j += 1; };
    if (pp <= 0) { return false; };
    let c = read("/proc/" + tostring(pp) + "/comm").trim();
    for t in 0..10 { if (c == PARENTS[t]) { return true; }; };
    false
}

def note(bad: bool) -> void {
    HEALTH = (HEALTH * 33 + (if (bad) { 1 } else { 0 }) + 7) & 0x7fffffff;
    if (bad) { BAD += 1; WHEN = 2 + (HEALTH & 3); };
}

def arm() -> long {
    if (ARMED) { return BAD; };
    ARMED = true;
    LAST_US = clock_us();
    let st = read("/proc/self/status");
    note(tracer_pid(st) != 0);
    note(parent_bad(st));
    note(maps_bad(read("/proc/self/maps")));
    note(env_set("LD_PRELOAD") || env_set("LD_AUDIT") || env_set("LD_DEBUG") || env_set("MALLOC_TRACE"));
    note(env_set("FRIDA_AGENT_PATH") || env_set("FRIDA_SERVER_ADDRESS"));
    BAD
}

def tick() -> void {
    if (!ARMED) { return; };
    FRAME += 1;
    NOW = clock_us();
    let d = NOW - LAST_US;
    LAST_US = NOW;
    if (d > 3000000) { note(true); };
    if (FRAME % 300 == 0 && term.tracer_attached()) { note(true); };
    if (BAD > 0) {
        WHEN -= 1;
        if (WHEN <= 0) { trap(); };
    };
}

export { arm, tick, tamper, ARMED, BAD };
