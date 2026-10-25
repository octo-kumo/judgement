
import g;
import world;
import canvas;
import style;
import text;
import ui;
import sfx;
import input;
import mem;
import term;
import veil;

let SRC = "";

let LBUF = "";
let CBUF = "";
let LBUF_N = 0;
let CBUF_N = 0;
let SPAN_CAP = 0;
let NAMES = "";
let N_MS: [long; 768] = [0; 768];
let N_ME: [long; 768] = [0; 768];

const ABUF_N = 98304;
let ABUF: [byte; 98304] = [0; 98304];

let MAXN = 768;
let N_NS: [long; 768] = [0; 768];
let N_NE: [long; 768] = [0; 768];
let N_SAME: [long; 768] = [-1; 768];
let N_C0: [long; 768] = [0; 768];
let N_CN: [long; 768] = [0; 768];
let N_E0: [long; 768] = [0; 768];
let N_EN: [long; 768] = [0; 768];
let N_L0: [long; 768] = [0; 768];
let N_LN: [long; 768] = [0; 768];
let N_K0: [long; 768] = [0; 768];
let N_KN: [long; 768] = [0; 768];
let N_GOTO: [long; 768] = [-1; 768];
let NN = 0;

let MAXL = 2048;
let L_SPK: [long; 2048] = [0; 2048];
let L_S: [long; 2048] = [0; 2048];
let L_E: [long; 2048] = [0; 2048];
let NL = 0;

const MAXK = 1024;
let K_S: [long; 1024] = [0; 1024];
let K_E: [long; 1024] = [0; 1024];
let K_TGT: [long; 1024] = [-1; 1024];
let K_C0: [long; 1024] = [0; 1024];
let K_CN: [long; 1024] = [0; 1024];
let K_TS: [long; 1024] = [0; 1024];
let K_TE: [long; 1024] = [0; 1024];
let NK = 0;

const MAXOP = 4096;
let OP_K: [long; 4096] = [0; 4096];
let OP_A: [long; 4096] = [0; 4096];
let OP_B: [long; 4096] = [0; 4096];
let NOP = 0;

const C_FLAG = 1;
const C_LOOP = 2;
const C_DAY = 3;
const C_MIN = 4;
const C_COINS = 5;
const C_EFFIGY = 6;
const C_APPLES = 7;
const C_LIVE = 8;
const C_LINK = 9;
const C_CODE = 10;
const C_RAND = 11;
const C_RETRY = 12;
const C_HANDLESS = 13;
const C_VOIDN = 14;
const C_ADVICE = 15;
const C_VOID = 16;

const CMP_EQ = 0;
const CMP_LT = 1;
const CMP_GT = 2;
const CMP_LE = 3;
const CMP_GE = 4;
const CMP_NE = 5;

const X_SET = 1;
const X_CLEAR = 2;
const X_COINS = 3;
const X_XP = 4;
const X_EVENT = 5;
const X_EFFIGY = 6;
const X_APPLES = 7;
const X_SFX = 8;
const X_HP = 9;

const MAXEV = 96;
let EV_NAME: [str; 96] = [""; 96];
let NEV = 0;

let RP = 0;
let WS = 0;
let WE = 0;

def line_end(i: long) -> long {
    let j = i;
    while (j < len(SRC) && SRC[j] != 10) { j += 1; };
    j
}

def skip_sp(i: long, e: long) -> long {
    let j = i;
    while (j < e && (SRC[j] == ' ' || SRC[j] == 9)) { j += 1; };
    j
}

def tok_end(i: long, e: long) -> long {
    let j = i;
    while (j < e && SRC[j] > 32) { j += 1; };
    j
}

def eq(a0: long, a1: long, s: str) -> bool {
    if (a1 - a0 != len(s)) { return false; };
    for k in 0..len(s) {
        if (SRC[a0 + k] != s[k]) { return false; };
    };
    true
}

def eqr(a0: long, a1: long, b0: long, b1: long) -> bool {
    if (a1 - a0 != b1 - b0) { return false; };
    for k in 0..(a1 - a0) {
        if (SRC[a0 + k] != SRC[b0 + k]) { return false; };
    };
    true
}

def int_in(a0: long, a1: long) -> long {
    let v = 0;
    let neg = false;
    for i in a0..a1 {
        let c = SRC[i];
        if (c == '-') { neg = true; };
        if (c >= '0' && c <= '9') { v = v * 10 + c - '0'; };
    };
    if (neg) { 0 - v } else { v }
}

def hex_in(a0: long, a1: long) -> long {
    let v = 0;
    for i in a0..a1 {
        let c = SRC[i];
        if (c >= '0' && c <= '9') { v = v * 16 + c - '0'; };
        if (c >= 'A' && c <= 'F') { v = v * 16 + c - 'A' + 10; };
        if (c >= 'a' && c <= 'f') { v = v * 16 + c - 'a' + 10; };
    };
    v
}

def add_op(k: long, a: long, b: long) -> void {
    if (NOP >= MAXOP) { return; };
    OP_K[NOP] = k;
    OP_A[NOP] = a;
    OP_B[NOP] = b;
    NOP += 1;
}

def event_index(a0: long, a1: long) -> long {
    let nm = SRC[a0:a1];
    for i in 0..NEV {
        if (EV_NAME[i] == nm) { return i; };
    };
    if (NEV >= MAXEV) { return 0; };
    EV_NAME[NEV] = nm;
    NEV += 1;
    NEV - 1
}

def event_id(name: str) -> long {
    for i in 0..NEV {
        if (EV_NAME[i] == name) { return i; };
    };
    if (NEV >= MAXEV) { return 0; };
    EV_NAME[NEV] = name;
    NEV += 1;
    NEV - 1
}

def compile_cond(a0: long, a1: long) -> void {
    let i = a0 + 1;
    let neg = false;
    if (i < a1 && SRC[i] == '!') {
        neg = true;
        i += 1;
    };

    let j = i;
    while (j < a1 && SRC[j] != '<' && SRC[j] != '>' && SRC[j] != '=' && SRC[j] != ':') { j += 1; };
    if (j < a1 && SRC[j] == ':') {

        let v0 = j + 1;
        let v1 = v0;
        while (v1 < a1 && SRC[v1] != '=') { v1 += 1; };
        let addr = hex_in(v0, v1);
        if (eq(i, j, "live")) { add_op(C_LIVE, addr, if (neg) { 0 } else { 1 }); };
        if (eq(i, j, "code")) { add_op(C_CODE, addr, if (neg) { 0 } else { 1 }); };
        if (eq(i, j, "link")) { add_op(C_LINK, addr, hex_in(v1 + 1, a1)); };
        if (eq(i, j, "rand")) { add_op(C_RAND, int_in(v0, a1), 0); };
        return;
    };
    if (j >= a1 && eq(i, a1, "void")) {
        add_op(C_VOID, 0, if (neg) { 0 } else { 1 });
        return;
    };
    if (j >= a1 && eq(i, a1, "handless")) {
        add_op(C_HANDLESS, 0, if (neg) { 0 } else { 1 });
        return;
    };
    if (j >= a1) {
        add_op(C_FLAG, g.flag_id(SRC[i:a1]), if (neg) { 0 } else { 1 });
        return;
    };
    let cmp = CMP_EQ;
    let k = j;
    if (SRC[k] == '<' && k + 1 < a1 && SRC[k + 1] == '=') { cmp = CMP_LE; k += 2; }
    else if (SRC[k] == '>' && k + 1 < a1 && SRC[k + 1] == '=') { cmp = CMP_GE; k += 2; }
    else if (SRC[k] == '<') { cmp = CMP_LT; k += 1; }
    else if (SRC[k] == '>') { cmp = CMP_GT; k += 1; }
    else { k += 1; };

    let v = 0;
    let colon = k;
    while (colon < a1 && SRC[colon] != ':') { colon += 1; };
    if (colon < a1) { v = int_in(k, colon) * 60 + int_in(colon + 1, a1); } else { v = int_in(k, a1); };
    let what = 0;
    if (eq(i, j, "loop")) { what = C_LOOP; };
    if (eq(i, j, "day")) { what = C_DAY; };
    if (eq(i, j, "time")) { what = C_MIN; };
    if (eq(i, j, "coins")) { what = C_COINS; };
    if (eq(i, j, "effigies")) { what = C_EFFIGY; };
    if (eq(i, j, "apples")) { what = C_APPLES; };
    if (eq(i, j, "retries")) { what = C_RETRY; };
    if (eq(i, j, "voids")) { what = C_VOIDN; };
    if (eq(i, j, "advice")) { what = C_ADVICE; };
    if (what != 0) { add_op(what, cmp, v); };
}

def compile_effect(a0: long, a1: long, b0: long, b1: long) -> void {
    let i = a0 + 1;
    if (eq(i, a1, "set")) { add_op(X_SET, g.flag_id(SRC[b0:b1]), 0); };
    if (eq(i, a1, "clear")) { add_op(X_CLEAR, g.flag_id(SRC[b0:b1]), 0); };
    if (eq(i, a1, "coins")) { add_op(X_COINS, int_in(b0, b1), 0); };
    if (eq(i, a1, "xp")) { add_op(X_XP, int_in(b0, b1), 0); };
    if (eq(i, a1, "event")) { add_op(X_EVENT, event_index(b0, b1), 0); };
    if (eq(i, a1, "effigy")) { add_op(X_EFFIGY, int_in(b0, b1), 0); };
    if (eq(i, a1, "apples")) { add_op(X_APPLES, int_in(b0, b1), 0); };
    if (eq(i, a1, "hp")) { add_op(X_HP, int_in(b0, b1), 0); };
    if (eq(i, a1, "sfx")) {
        let k = 0;
        if (eq(b0, b1, "bell")) { k = sfx.BELL; };
        if (eq(b0, b1, "chime")) { k = sfx.CHIME; };
        if (eq(b0, b1, "pickup")) { k = sfx.PICKUP; };
        if (eq(b0, b1, "splash")) { k = sfx.SPLASH; };
        if (eq(b0, b1, "crack")) { k = sfx.CRACK; };
        add_op(X_SFX, k, 0);
    };
}

let SPK_TEXT = 0;
def speaker(i: long, e: long) -> long {
    SPK_TEXT = i;
    let c = i;
    while (c < e && c - i < 16 && SRC[c] != ':') { c += 1; };
    if (c >= e || SRC[c] != ':' || c == i) { return -1; };
    let found = -1;
    if (eq(i, c, "Peecy") || eq(i, c, "You")) { found = -2; };
    for p in 0..world.NPEOPLE {
        let nm = world.P_NAME[p];
        if (len(nm) == c - i) {
            let ok = true;
            for k in 0..len(nm) {
                if (SRC[i + k] != nm[k]) { ok = false; break; };
            };
            if (ok) { found = p; };
        };
    };
    if (eq(i, c, "Sign") || eq(i, c, "Note") || eq(i, c, "Stele") || eq(i, c, "Book") || eq(i, c, "Plaque")) { found = -3; };
    if (found != -1 || eq(i, c, "Voice")) {
        SPK_TEXT = skip_sp(c + 1, e);
        if (found == -1) { found = -4; };
    };
    found
}

def load(src: str) -> void {
    SRC = src;
    NN = 0;
    NL = 0;
    NK = 0;
    NOP = 0;
    let i = 0;
    let cur = -1;
    while (i < len(SRC)) {
        let e = line_end(i);
        let s = skip_sp(i, e);
        if (s >= e || SRC[s] == '#') {
            i = e + 1;
            continue;
        };
        let c = SRC[s];
        if (c == '@' && NN < MAXN) {
            cur = NN;
            NN += 1;
            let ne = tok_end(s + 1, e);
            N_NS[cur] = s + 1;
            N_NE[cur] = ne;
            N_SAME[cur] = -1;
            N_GOTO[cur] = -1;

            let k = cur - 1;
            while (k >= 0) {
                if (eqr(N_NS[k], N_NE[k], s + 1, ne)) {
                    if (N_SAME[k] == -1) { N_SAME[k] = cur; };
                    break;
                };
                k -= 1;
            };

            N_C0[cur] = NOP;
            let t = skip_sp(ne, e);
            while (t < e) {
                let te = tok_end(t, e);
                if (SRC[t] == '?') { compile_cond(t, te); };
                t = skip_sp(te, e);
            };
            N_CN[cur] = NOP - N_C0[cur];
            N_E0[cur] = NOP;
            t = skip_sp(ne, e);
            while (t < e) {
                let te = tok_end(t, e);
                if (SRC[t] == '!') {
                    let b0 = skip_sp(te, e);
                    let b1 = tok_end(b0, e);
                    compile_effect(t, te, b0, b1);
                    te = b1;
                };
                t = skip_sp(te, e);
            };
            N_EN[cur] = NOP - N_E0[cur];
            N_L0[cur] = NL;
            N_LN[cur] = 0;
            N_K0[cur] = NK;
            N_KN[cur] = 0;
        } else if (cur >= 0 && c == '>' && NK < MAXK) {

            let arrow = s + 1;
            while (arrow + 1 < e && !(SRC[arrow] == '-' && SRC[arrow + 1] == '>')) { arrow += 1; };
            let ts = skip_sp(s + 1, e);
            let te = arrow;
            while (te > ts && SRC[te - 1] == ' ') { te -= 1; };
            K_S[NK] = ts;
            K_E[NK] = te;
            let gs = skip_sp(arrow + 2, e);
            let ge = tok_end(gs, e);
            K_TS[NK] = gs;
            K_TE[NK] = ge;
            K_C0[NK] = NOP;
            let t = skip_sp(ge, e);
            while (t < e) {
                let tt = tok_end(t, e);
                if (SRC[t] == '?') { compile_cond(t, tt); };
                t = skip_sp(tt, e);
            };
            K_CN[NK] = NOP - K_C0[NK];
            NK += 1;
            N_KN[cur] += 1;
        } else if (cur >= 0 && c == '-' && s + 1 < e && SRC[s + 1] == '>') {
            let gs = skip_sp(s + 2, e);
            N_GOTO[cur] = gs * 65536 + tok_end(gs, e);
        } else if (cur >= 0 && NL < MAXL) {
            let sp = speaker(s, e);
            L_SPK[NL] = sp;
            L_S[NL] = SPK_TEXT;
            let le = e;
            while (le > SPK_TEXT && (SRC[le - 1] == ' ' || SRC[le - 1] == 13)) { le -= 1; };
            L_E[NL] = le;
            NL += 1;
            N_LN[cur] += 1;
        };
        i = e + 1;
    };

    for k in 0..NK { K_TGT[k] = first_named(K_TS[k], K_TE[k]); };
    for n in 0..NN {
        if (N_GOTO[n] >= 0) {
            let gs = N_GOTO[n] / 65536;
            let ge = N_GOTO[n] % 65536;
            N_GOTO[n] = first_named(gs, ge);
        };
    };
    colour_isa();
    build_names();

    SPAN_CAP = span_max();
    LBUF = " ".repeat(SPAN_CAP);
    CBUF = " ".repeat(SPAN_CAP);
    LBUF_N = 0;
    CBUF_N = 0;

    term.lock_pages(ptr_addr(LBUF), len(LBUF));
    term.lock_pages(ptr_addr(CBUF), len(CBUF));
    veil.begin();
    veil.seal(SRC);

    term.dont_dump(ptr_addr(SRC), len(SRC));
}

def span_max() -> long {
    let m = 0;
    for l in 0..NL {
        let n = L_E[l] - L_S[l];
        if (n > m) { m = n; };
    };
    for k in 0..NK {
        let n = K_E[k] - K_S[k];
        if (n > m) { m = n; };
    };
    m
}

def span_cap() -> long { SPAN_CAP }

def open_span(from: long, to: long, out: str) -> long {
    let n = to - from;
    if (n < 0) { n = 0; };
    if (n > len(out)) { n = len(out); };
    veil.wipe(out);
    veil.open(SRC, from, from + n, out);
    n
}

def wipe_spans() -> void {
    veil.wipe(LBUF);
    veil.wipe(CBUF);
    LBUF_N = 0;
    CBUF_N = 0;
}

def is_ident_start(c: long) -> bool {
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

def is_ident(c: long) -> bool {
    is_ident_start(c) || (c >= '0' && c <= '9')
}

def is_keyword(w: str) -> bool {
    w == "if" || w == "else" || w == "let" || w == "def" || w == "assert" || w == "return" ||
    w == "while" || w == "for" || w == "in" || w == "true" || w == "false" || w == "none"
}

def lit_is(t: str, a: long, b: long, s: str) -> bool {
    if (b - a != len(s)) { return false; };
    for k in 0..len(s) { if (t[a + k] != s[k]) { return false; }; };
    true
}

def is_keyword_at(t: str, a: long, b: long) -> bool {
    lit_is(t, a, b, "if") || lit_is(t, a, b, "else") || lit_is(t, a, b, "let") || lit_is(t, a, b, "def") ||
    lit_is(t, a, b, "assert") || lit_is(t, a, b, "return") || lit_is(t, a, b, "while") || lit_is(t, a, b, "for") ||
    lit_is(t, a, b, "in") || lit_is(t, a, b, "true") || lit_is(t, a, b, "false") || lit_is(t, a, b, "none")
}

def put_at(out: [byte; 98304], at: long, c: long) -> long {
    out[at] = c & 255;
    at + 1
}

def put_tag(out: [byte; 98304], at: long, s: str) -> long {
    for k in 0..len(s) { out[at] = s[k]; at += 1; };
    at
}

def put_range(out: [byte; 98304], at: long, t: str, a: long, b: long) -> long {
    for k in a..b { out[at] = t[k]; at += 1; };
    at
}

def highlight_into(out: [byte; 98304], at: long, t: str, a0: long, a1: long) -> long {
    let i = a0;
    let n = a1;
    while (i < n) {
        let c = t[i];
        if (c == '{' && i + 1 < n && t[i + 1] == '{') {
            at = put_tag(out, at, "{op}{{{/}");
            i += 2;
        } else if (c == '{') {

            let j = i;
            while (j < n && t[j] != '}') { j += 1; };
            at = put_range(out, at, t, i, j + 1);
            i = j + 1;
        } else if (c == '/' && i + 1 < n && t[i + 1] == '/') {

            let j = i;
            while (j < n && !(t[j] == '{' && j + 2 < n && t[j + 1] == '/' && t[j + 2] == '}')) { j += 1; };
            at = put_tag(out, at, "{cm}");
            at = put_range(out, at, t, i, j);
            at = put_tag(out, at, "{/}");
            i = j;
        } else if (c == '"' || c == 39) {
            let j = i + 1;
            while (j < n && t[j] != c) { j += 1; };
            at = put_tag(out, at, "{str}");
            at = put_range(out, at, t, i, j + 1);
            at = put_tag(out, at, "{/}");
            i = j + 1;
        } else if (c >= '0' && c <= '9') {
            let j = i;
            while (j < n && t[j] >= '0' && t[j] <= '9') { j += 1; };
            at = put_tag(out, at, "{num}");
            at = put_range(out, at, t, i, j);
            at = put_tag(out, at, "{/}");
            i = j;
        } else if (is_ident_start(c)) {
            let j = i;
            while (j < n && is_ident(t[j])) { j += 1; };
            if (is_keyword_at(t, i, j)) {
                at = put_tag(out, at, "{kw}");
                at = put_range(out, at, t, i, j);
                at = put_tag(out, at, "{/}");
            } else if (j < n && t[j] == '(') {
                at = put_tag(out, at, "{fn}");
                at = put_range(out, at, t, i, j);
                at = put_tag(out, at, "{/}");
            } else {
                at = put_range(out, at, t, i, j);
            };
            i = j;
        } else if (c == '(' || c == ')' || c == ';' || c == '}' || c == '=' || c == '<' || c == '>' || c == '.' || c == ',' || c == '!' || c == '&' || c == '|') {
            at = put_tag(out, at, "{op}");
            at = put_at(out, at, c);
            at = put_tag(out, at, "{/}");
            i += 1;
        } else {
            at = put_at(out, at, c);
            i += 1;
        };
    };
    at
}

def colour_isa() -> void {
    let isa = world.person_id("isa");
    if (isa < 0) { return; };

    let n = len(SRC);
    if (n + 64 > ABUF_N) { return; };
    let at = 0;
    for i in 0..n { ABUF[at] = SRC[i]; at += 1; };
    for l in 0..NL {
        if (L_SPK[l] != isa) { continue; };
        let s0 = L_S[l];
        let e0 = L_E[l];

        if (at + (e0 - s0) * 4 + 64 > ABUF_N) { break; };
        L_S[l] = at;
        at = highlight_into(ABUF, at, SRC, s0, e0);
        L_E[l] = at;
        at = put_at(ABUF, at, 10);
    };
    let old = SRC;

    SRC = (" ").repeat(at);
    let dp: *byte = ptr_from(ptr_addr(SRC));
    for i in 0..at { *(dp + i) = ABUF[i]; };

    veil.wipe(old);
    for i in 0..at { ABUF[i] = 0; };
}

def first_named(a0: long, a1: long) -> long {
    for n in 0..NN {
        if (eqr(N_NS[n], N_NE[n], a0, a1)) { return n; };
    };
    -1
}

def build_names() -> void {
    let b: [byte] = [];
    for n in 0..NN {
        N_MS[n] = len(b);
        for k in N_NS[n]..N_NE[n] { b += SRC[k]; };
        N_ME[n] = len(b);
    };
    NAMES = from_bytes(b);
    for i in 0..len(b) { b[i] = 0; };
}

def node_id(name: str) -> long {
    for n in 0..NN {
        if (name_is(n, name)) { return n; };
    };
    -1
}

def name_is(n: long, s: str) -> bool {
    let a0 = N_MS[n];
    if (N_ME[n] - a0 != len(s)) { return false; };
    for k in 0..len(s) {
        if (NAMES[a0 + k] != s[k]) { return false; };
    };
    true
}

def has_node(name: str) -> bool { node_id(name) >= 0 }

def cmp(v: long, how: long, w: long) -> bool {
    if (how == CMP_EQ) { return v == w; };
    if (how == CMP_LT) { return v < w; };
    if (how == CMP_GT) { return v > w; };
    if (how == CMP_LE) { return v <= w; };
    if (how == CMP_GE) { return v >= w; };
    v != w
}

let RNG = 7;
def ops_pass(o0: long, on: long) -> bool {
    for o in o0..(o0 + on) {
        let k = OP_K[o];
        let a = OP_A[o];
        let b = OP_B[o];
        let ok = true;
        if (k == C_FLAG) { ok = g.FLAG[a] == (b == 1); };
        if (k == C_LOOP) { ok = cmp(g.LOOP, a, b); };
        if (k == C_DAY) { ok = cmp(g.DAY, a, b); };
        if (k == C_MIN) { ok = cmp(g.MIN, a, b); };
        if (k == C_COINS) { ok = cmp(g.COINS, a, b); };
        if (k == C_EFFIGY) { ok = cmp(g.EFFIGIES, a, b); };
        if (k == C_APPLES) { ok = cmp(g.APPLES, a, b); };
        if (k == C_LIVE) { ok = mem.LIVE[a & 255] == (b == 1); };
        if (k == C_LINK) { ok = mem.link(a & 255) == b; };
        if (k == C_CODE) { ok = mem.is_code(a & 255) == (b == 1); };
        if (k == C_RETRY) { ok = cmp(g.RETRIES, a, b); };
        if (k == C_VOIDN) { ok = cmp(g.VOID_LAUNCHES, a, b); };
        if (k == C_ADVICE) { ok = cmp(g.ADVICE, a, b); };
        if (k == C_VOID) { ok = (g.FLAG[g.F_VOID_SEEN] || g.RETRIES > 0 || g.HANDLESS) == (b == 1); };
        if (k == C_HANDLESS) { ok = g.HANDLESS == (b == 1); };
        if (k == C_RAND) {
            RNG = (RNG * 1103515245 + 12345) & 0x7fffffff;
            ok = (RNG >> 8) % (if (a < 1) { 1 } else { a }) == 0;
        };
        if (!ok) { return false; };
    };
    true
}

def pick(n0: long) -> long {
    let n = n0;
    while (n >= 0) {
        if (ops_pass(N_C0[n], N_CN[n])) { return n; };
        n = N_SAME[n];
    };
    -1
}

def apply_effects(n: long) -> void {
    for o in N_E0[n]..(N_E0[n] + N_EN[n]) {
        let k = OP_K[o];
        let a = OP_A[o];
        if (k == X_SET) { g.FLAG[a] = true; };
        if (k == X_CLEAR) { g.FLAG[a] = false; };
        if (k == X_COINS) { g.COINS += a; if (g.COINS < 0) { g.COINS = 0; }; };
        if (k == X_XP) { g.XP += a; };
        if (k == X_EVENT) { g.emit(g.EV_SCRIPT, a, 0); };
        if (k == X_EFFIGY) { g.EFFIGIES += a; if (g.EFFIGIES < 0) { g.EFFIGIES = 0; }; };
        if (k == X_APPLES) { g.APPLES = (g.APPLES + a) & 255; };
        if (k == X_SFX) { sfx.play(a, 0); };
        if (k == X_HP) { g.HP += a; if (g.HP > g.HP_MAX) { g.HP = g.HP_MAX; }; };
    };
}

let OPEN = false;
let NODE = -1;
let LINE = 0;
let REVEAL = 0;
let TOTAL = 0;
let CHOOSING = false;
let SEL = 0;
let CH_IDX: [long; 12] = [0; 12];
let CH_N = 0;
let SPEAKER_ENT = -1;
let FLOATING = false;
const AUTO_CLOSE = 0;

def start(name: str, who: long) -> bool {
    let n0 = node_id(name);
    if (n0 < 0) { return false; };
    let n = pick(n0);
    if (n < 0) { return false; };
    SPEAKER_ENT = who;
    enter(n);
    true
}

def start_node(n0: long, who: long) -> bool {
    let n = pick(n0);
    if (n < 0) { return false; };
    SPEAKER_ENT = who;
    enter(n);
    true
}

def enter(n: long) -> void {
    OPEN = true;
    NODE = n;
    LINE = 0;
    CHOOSING = false;
    apply_effects(n);
    begin_line();
    if (N_LN[n] == 0) { after_lines(); };
}

def begin_line() -> void {
    REVEAL = 0;

    wipe_spans();
    if (NODE < 0 || LINE >= N_LN[NODE]) {
        TOTAL = 0;
        return;
    };
    let l = N_L0[NODE] + LINE;
    LBUF_N = open_span(L_S[l], L_E[l], LBUF);
    TOTAL = text.glyphs(LBUF, 0, LBUF_N);
}

def restart_line() -> void { begin_line(); }

def close() -> void {
    OPEN = false;
    NODE = -1;
    CHOOSING = false;
    wipe_spans();
}

def after_lines() -> void {
    CH_N = 0;
    for k in N_K0[NODE]..(N_K0[NODE] + N_KN[NODE]) {
        if (CH_N < 12 && ops_pass(K_C0[k], K_CN[k])) {
            CH_IDX[CH_N] = k;
            CH_N += 1;
        };
    };
    if (CH_N > 0) {
        CHOOSING = true;
        SEL = 0;
        return;
    };
    if (N_GOTO[NODE] >= 0) {
        let n = pick(N_GOTO[NODE]);
        if (n >= 0) {
            enter(n);
            return;
        };
    };
    close();
}

def advance() -> void {
    if (!OPEN) { return; };
    if (CHOOSING) {
        choose(SEL);
        return;
    };
    if (REVEAL < TOTAL * 2) {
        REVEAL = TOTAL * 2;
        return;
    };
    LINE += 1;
    if (LINE >= N_LN[NODE]) {
        after_lines();
        return;
    };
    begin_line();
}

def choose(i: long) -> void {
    if (i < 0 || i >= CH_N) { return; };
    let k = CH_IDX[i];
    sfx.play(sfx.BLIP, 0);
    CHOOSING = false;
    if (K_TGT[k] < 0) {
        close();
        return;
    };
    let n = pick(K_TGT[k]);
    if (n < 0) {
        close();
        return;
    };
    enter(n);
}

def tick() -> void {
    if (!OPEN || CHOOSING) { return; };
    if (REVEAL < TOTAL * 2) {
        REVEAL += 3;
        if ((REVEAL / 3) % 4 == 0) { sfx.play(sfx.BLIP, 0); };
    };
}

def key(k: long) -> bool {
    if (!OPEN) { return false; };
    if (CHOOSING) {
        if (k == input.K_UP || k == 'w') { SEL = (SEL + CH_N - 1) % CH_N; return true; };
        if (k == input.K_DOWN || k == 's') { SEL = (SEL + 1) % CH_N; return true; };
        if (k >= '1' && k <= '9' && k - '1' < CH_N) { choose(k - '1'); return true; };
    };
    if (k == input.K_ENTER || k == ' ' || k == 'e' || k == 'E') {
        advance();
        return true;
    };
    if (k == input.K_ESC) {
        close();
        return true;
    };
    true
}

let BOX_X = 0;
let BOX_Y = 0;
let BOX_W = 0;
let BOX_H = 0;
const HIT_BASE = 9000;
let SPK_X = 0;
let SPK_Y = 0;

def speaker_name(sp: long) -> str {
    if (sp >= 0) { return world.P_NAME[sp]; };
    if (sp == -2) { return "Peecy"; };
    ""
}

def draw() -> void {
    if (!OPEN || NODE < 0) { return; };
    if (FLOATING) {
        draw_floating();
        return;
    };
    let w = canvas.W - 4;
    if (w > 78) { w = 78; };
    let h = 7;
    let x = (canvas.W - w) / 2;
    let y = canvas.H - h - 1;
    BOX_X = x;
    BOX_Y = y;
    BOX_W = w;
    BOX_H = h;
    let shown_line = LINE;
    if (shown_line >= N_LN[NODE]) { shown_line = N_LN[NODE] - 1; };
    ui.shadow(x, y, w, h);
    ui.frame(x, y, w, h, ui.ROUND, style.BOX, style.BOX_EDGE, "");
    if (shown_line >= 0 && N_LN[NODE] > 0) {
        let l = N_L0[NODE] + shown_line;
        let sp = L_SPK[l];
        let nm = speaker_name(sp);
        if (len(nm) > 0) {
            let tw = len(nm) + 2;
            canvas.fill(x + 2, y, tw, 1, 32, style.FG[style.HILITE], style.BG[style.HILITE], 0);
            text.print(x + 3, y, nm, style.HILITE);
        };
        let base = if (sp == -2) { style.find("i") } else if (sp == -1 || sp == -3) { style.DIMT } else { style.TEXT };
        if (sp == -3) { base = style.find("b"); };
        let rev = if (CHOOSING) { -1 } else { REVEAL / 2 };
        if (!CHOOSING || N_LN[NODE] > 0) {
            text.box(x + 2, y + 1, w - 4, if (CHOOSING) { 2 } else { h - 2 }, LBUF, 0, LBUF_N, base, rev);
        };
        if (!CHOOSING && REVEAL >= TOTAL * 2 && (text.TIME / 12) % 2 == 0) {
            canvas.put(x + w - 3, y + h - 2, 0x25BC, style.FG[style.GOLD], canvas.KEEP, 0);
        };
    };
    if (CHOOSING) { draw_choices(x + 2, y + h - 1 - CH_N, w - 4); };
}

def draw_choices(x: long, y: long, w: long) -> void {

    let top = if (y < BOX_Y + 1) { y } else { y };
    if (top < BOX_Y + 1) {
        let extra = BOX_Y + 1 - top;
        ui.frame(BOX_X, BOX_Y - extra, BOX_W, BOX_H + extra, ui.ROUND, style.BOX, style.BOX_EDGE, "");
    };
    for i in 0..CH_N {
        let k = CH_IDX[i];
        let yy = top + i;
        let hot = i == SEL || ui.HOVER == HIT_BASE + i;
        if (hot) {
            canvas.fill(x, yy, w, 1, 32, style.FG[style.HILITE], style.BG[style.HILITE], 0);
            canvas.put(x, yy, 0x25B8, style.FG[style.HILITE], canvas.KEEP, 0);
        };
        CBUF_N = open_span(K_S[k], K_E[k], CBUF);
        text.print_range(x + 2, yy, CBUF, 0, CBUF_N, if (hot) { style.HILITE } else { style.TEXT });
        ui.region(HIT_BASE + i, x, yy, w, 1);
    };
}

def draw_floating() -> void {
    let shown_line = LINE;
    if (shown_line >= N_LN[NODE]) { shown_line = N_LN[NODE] - 1; };
    if (shown_line >= 0 && N_LN[NODE] > 0) {
        let rev = if (CHOOSING) { -1 } else { REVEAL / 2 };
        ui.floating(SPK_X, SPK_Y, 30, LBUF, 0, LBUF_N, rev);
    };
    if (CHOOSING) {
        for i in 0..CH_N {
            let k = CH_IDX[i];
            let hot = i == SEL || ui.HOVER == HIT_BASE + i;
            let yy = SPK_Y + 2 + i;
            CBUF_N = open_span(K_S[k], K_E[k], CBUF);
            let w = text.width_range(CBUF, 0, CBUF_N);
            let xx = SPK_X - w / 2;
            text.print_range(xx, yy, CBUF, 0, CBUF_N,  if (hot) { style.GOLD } else { style.DIMT });
            ui.region(HIT_BASE + i, xx, yy, w, 1);
        };
    };
}

def click(id: long) -> bool {
    if (!OPEN) { return false; };
    if (CHOOSING && id >= HIT_BASE && id < HIT_BASE + CH_N) {
        choose(id - HIT_BASE);
        return true;
    };
    advance();
    true
}

def hover(id: long) -> void {
    if (CHOOSING && id >= HIT_BASE && id < HIT_BASE + CH_N) { SEL = id - HIT_BASE; };
}

export {
    load, start, start_node, restart_line, node_id, has_node, event_id, close, advance, tick,
    key, draw, click, hover, pick, ops_pass, open_span, span_cap, OPEN, NODE, NN, REVEAL, TOTAL, CHOOSING, FLOATING,
    SPEAKER_ENT, SPK_X, SPK_Y, EV_NAME, NEV, SRC, N_LN, N_L0, L_S, L_E, L_SPK
};
