
import mem;
import g;

let MAXR = 32;
let REC_RULE: [long; 32] = [0; 32];
let REC_ADDR: [long; 32] = [0; 32];
let NREC = 0;

def in_force(r: long) -> bool {
    mem.LIVE[mem.A_STELE] && mem.LIVE[mem.A_RULE1 + r - 1]
}

def record(r: long, addr: long) -> bool {
    if (addr < 0 || !in_force(r)) { return false; };
    if (r == 4) {

        call(4, addr);
        return true;
    };
    for i in 0..NREC {
        if (REC_RULE[i] == r && REC_ADDR[i] == addr) { return true; };
    };
    if (NREC >= MAXR) { return false; };
    REC_RULE[NREC] = r;
    REC_ADDR[NREC] = addr;
    NREC += 1;
    g.emit(g.EV_RULE, r, addr);
    true
}

def noted(addr: long) -> bool {
    for i in 0..NREC {
        if (REC_ADDR[i] == addr) { return true; };
    };
    false
}

def call(r: long, addr: long) -> bool {
    let h = mem.link(mem.A_RULE1 + r - 1);
    if (mem.exec(h, addr)) {
        g.emit(g.EV_STRIKE, addr, 1);
        return true;
    };
    false
}

def bell() -> long {
    let n = 0;
    if (mem.LIVE[mem.A_BELL]) {
        for i in 0..NREC {
            if (call(REC_RULE[i], REC_ADDR[i])) { n += 1; };
        };
    };
    NREC = 0;
    n
}

def clear() -> void { NREC = 0; }

export { record, bell, call, clear, in_force, noted, REC_RULE, REC_ADDR, NREC };
