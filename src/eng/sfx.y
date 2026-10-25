
import fx;
import pulse;

const RATE = 22050;
let CHUNK = 441;

const BELL = 1;
const CRACK = 2;
const CHIME = 3;
const STEP = 4;
const SWING = 5;
const HIT = 6;
const HURT = 7;
const BLIP = 8;
const FIRE = 9;
const SPLASH = 10;
const PICKUP = 11;
const DRONE_ON = 12;
const MUSIC = 13;
const CASCADE = 14;
const SWELL = 15;
const VOLUME = 16;
const HEART = 17;

let ENABLED = false;
let MUTED = false;
let STARTED = false;

let CQ_K: [long; 64] = [0; 64];
let CQ_A: [long; 64] = [0; 64];
let CQ_W = 0;
let CQ_R = 0;

const NVO = 20;
let V_KIND: [long; 20] = [0; 20];
let V_T: [long; 20] = [0; 20];
let V_DUR: [long; 20] = [0; 20];
let V_F: [long; 20] = [0; 20];
let V_PH: [long; 20] = [0; 20];
let V_PH2: [long; 20] = [0; 20];
let V_PH3: [long; 20] = [0; 20];
let V_VOL: [long; 20] = [0; 20];

let DRONE = false;
let DRONE_PH = 0;
let DRONE_PH2 = 0;
let MUS = 0;
let MUS_T = 0;
let MUS_I = 0;
let GAIN = 200;
let NOISE = 12345;

let TRK: [long; 964] = [
    7, 2, 12, 2, 11, 2, 7, 2, 9, 4, 4, 4, 5, 2, 9, 2, 7, 2, 4, 2,
    2, 8, 7, 2, 12, 2, 14, 2, 12, 2, 11, 4, 7, 4, 9, 2, 7, 2, 5, 2,
    4, 2, 0, 8, -1, 4, 4, 2, 5, 2, 7, 4, 4, 4, 2, 4, 0, 8, -1, 8,
    12, 2, 11, 2, 9, 2, 11, 2, 12, 4, 7, 4, 9, 2, 7, 2, 5, 2, 4, 2,
    2, 6, -1, 2, 4, 2, 7, 2, 9, 2, 12, 4, 11, 2, 9, 2, 7, 4, 5, 2,
    4, 2, 2, 2, 0, 6, 0, 6, 3, 6, 7, 6, 3, 6, -1, 4, 0, 6, 2, 6,
    3, 10, -1, 6, 7, 6, 5, 6, 3, 6, 2, 10, -1, 8, 7, 6, 5, 6, 3, 6,
    2, 6, 0, 10, -1, 6, 3, 6, 0, 6, 2, 6, 3, 10, -1, 8, 12, 2, 16, 2,
    19, 2, 16, 2, 14, 2, 17, 2, 21, 2, 17, 2, 12, 2, 16, 2, 19, 2, 24, 2,
    21, 4, 19, 4, 16, 8, -1, 4, 24, 2, 21, 2, 19, 2, 16, 2, 14, 2, 16, 2,
    17, 2, 19, 2, 21, 6, -1, 2, 12, 2, 14, 2, 16, 4, 19, 4, 21, 8, -1, 4,
    0, 2, 4, 2, 7, 2, 12, 2, 11, 2, 7, 2, 4, 2, 7, 2, 5, 2, 9, 2,
    12, 2, 14, 2, 12, 2, 9, 2, 5, 2, 9, 2, 4, 2, 7, 2, 11, 2, 12, 2,
    14, 2, 11, 2, 7, 2, 4, 2, 2, 4, 0, 4, -1, 4, 9, 2, 12, 2, 11, 2,
    9, 2, 7, 4, 4, 4, 2, 2, 4, 2, 5, 2, 7, 2, 9, 8, -1, 4, 12, 2,
    9, 2, 7, 2, 4, 2, 5, 2, 7, 2, 9, 2, 7, 2, 4, 6, -1, 2, 0, 8,
    7, 8, 12, 8, 11, 8, 9, 8, 7, 8, 4, 8, 2, 8, 0, 16, -1, 8, 12, 8,
    11, 8, 7, 8, 9, 8, 4, 16, -1, 8, 0, 8, 7, 8, 2, 8, 4, 8, 0, 16,
    -1, 8, 0, 1, 4, 1, 7, 1, 9, 1, 12, 1, 9, 1, 7, 1, 4, 1, 2, 1,
    5, 1, 9, 1, 11, 1, 14, 1, 11, 1, 9, 1, 5, 1, 0, 1, 4, 1, 7, 1,
    9, 1, 12, 1, 16, 2, 12, 2, 9, 2, -1, 4, 16, 1, 12, 1, 9, 1, 7, 1,
    4, 1, 7, 1, 9, 1, 12, 1, 14, 1, 11, 1, 7, 1, 5, 1, 2, 1, 5, 1,
    7, 1, 11, 1, 9, 1, 12, 1, 16, 1, 12, 1, 9, 1, 7, 1, 4, 2, -1, 6,
    7, 2, 9, 1, 7, 1, 4, 2, 0, 2, 2, 2, 4, 2, 7, 4, 9, 2, 11, 1,
    9, 1, 7, 2, 4, 2, 5, 2, 4, 2, 2, 2, 0, 4, -1, 2, 4, 2, 7, 2,
    9, 2, 7, 2, 4, 4, 2, 2, 4, 2, 5, 2, 4, 2, 2, 2, 0, 4, -1, 2,
    12, 2, 11, 1, 9, 1, 7, 2, 9, 2, 11, 2, 12, 4, -1, 4, 7, 2, 5, 2,
    4, 2, 2, 2, 0, 6, 0, 4, -1, 2, 3, 2, 7, 6, -1, 2, 5, 4, 3, 4,
    2, 6, -1, 4, 0, 8, -1, 4, 3, 4, 2, 2, 0, 2, 3, 6, -1, 2, 7, 4,
    5, 4, 3, 8, -1, 4, 7, 4, -1, 4, 8, 2, 7, 2, 5, 6, -1, 4, 3, 4,
    2, 4, 0, 10, -1, 6, 0, 12, 1, 10, -1, 6, 6, 12, 5, 10, -1, 8, 3, 10,
    2, 10, -1, 6, 8, 12, 7, 8, -1, 10, 0, 8, -1, 8, 1, 8, -1, 10, 6, 10,
    -1, 12, 19, 6, -1, 12, 24, 8, -1, 16, 17, 6, -1, 20, 22, 10, -1, 24, 24, 8,
    -1, 14, 19, 6, 22, 6, -1, 18, 17, 10, -1, 22, 15, 8, -1, 30, 22, 6, -1, 10,
    19, 4, 17, 4, -1, 26, 0, 1, 0, 1, 7, 1, 0, 1, 3, 1, 0, 1, 8, 1,
    0, 1, 0, 1, 0, 1, 7, 1, 0, 1, 5, 1, 0, 1, 3, 1, 2, 1, 0, 1,
    0, 1, 7, 1, 0, 1, 3, 1, 0, 1, 10, 1, 8, 1, 7, 2, 5, 1, 3, 1,
    2, 2, 0, 2, 0, 1, 3, 1, 0, 1, 5, 1, 0, 1, 7, 1, 0, 1, 8, 1,
    12, 2, 10, 2, 8, 2, 7, 2, 0, 2, -1, 2, 0, 2, 1, 2, 0, 2, -1, 2,
    0, 1, 1, 1, 0, 2, -1, 2, 0, 1, -1, 1, 0, 1, -1, 1, 1, 2, 0, 2,
    -1, 2, 0, 2, 0, 2, 1, 2, 0, 2, -1, 2, 6, 2, 5, 2, -1, 2, 7, 2,
    12, 2, 10, 2, 7, 2, 8, 4, 3, 4, 5, 2, 8, 2, 7, 2, 3, 2, 2, 8,
    7, 2, 12, 2, 14, 2, 12, 2, 10, 4, 7, 4, 8, 2, 7, 2, 5, 2, 3, 2,
    0, 8, -1, 8, 12, 2, 10, 2, 8, 2, 10, 2, 12, 4, 7, 4, 8, 2, 7, 2,
    5, 2, 3, 2, 2, 6, -1, 2, 3, 2, 7, 2, 8, 2, 12, 4, 10, 2, 8, 2,
    7, 4, 5, 2, 3, 2, 2, 2, 0, 6, 3, 1, 4, 1, 6, 2, 11, 2, 3, 1,
    4, 1, 6, 1, 11, 1, 13, 1, 15, 1, 13, 1, 9, 1, 11, 2, 6, 2, 4, 1,
    3, 1, 4, 2, 6, 2, 11, 2, 13, 1, 9, 1, 11, 1, 13, 1, 15, 2, 11, 1,
    13, 1, -1, 2
];
let T_OFF: [long; 16] = [0, 0, 53, 78, 110, 159, 181, 230, 273, 303, 321, 343, 384, 409, 455, 0];
let T_N: [long; 16] = [0, 53, 25, 32, 49, 22, 49, 43, 30, 18, 22, 41, 25, 46, 27, 0];

let T_BEAT: [long; 16] = [0, 6, 6, 6, 5, 4, 7, 6, 6, 6, 5, 9, 8, 6, 10, 0];
let T_FM: [long; 16] = [0, 2, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 1, 2, 4, 0];
let T_VOL: [long; 16] = [0, 55, 45, 50, 48, 48, 40, 50, 50, 60, 55, 62, 80, 52, 50, 0];
let T_HARM: [long; 16] = [0, 0, 0, 7, 0, 7, 12, 0, 6, 1, 12, 0, 6, 0, 0, 0];
let T_VOL2: [long; 16] = [0, 0, 0, 26, 0, 30, 22, 0, 24, 40, 28, 0, 40, 0, 0, 0];
let T_TAIL: [long; 16] = [0, 3, 3, 3, 2, 1, 2, 3, 2, 1, 1, 4, 3, 3, 5, 0];

let T_SC: [long; 16] = [0, 0, 1, 0, 0, 2, 2, 0, 1, 1, 2, 1, 1, 1, 0, 0];
let T_PADV: [long; 16] = [0, 30, 34, 30, 28, 36, 24, 26, 34, 40, 24, 0, 0, 30, 0, 0];
let T_SPKV: [long; 16] = [0, 22, 20, 26, 0, 24, 28, 18, 16, 14, 34, 0, 0, 18, 0, 0];
let T_REST: [long; 16] = [0, 8, 16, 6, 10, 20, 6, 8, 18, 26, 40, 0, 0, 10, 0, 0];
let SC_N: [long; 3] = [7, 7, 5];
let SC: [long; 21] = [0, 2, 4, 5, 7, 9, 11,  0, 2, 3, 5, 7, 8, 10,  0, 2, 4, 7, 9, 0, 0];
let CH: [long; 15] = [0, 5, 7, 9, 4,  0, 3, 5, 7, 8,  0, 4, 7, 9, 2];

let SEMI: [long; 25] = [
    3520, 3729, 3951, 4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645,
    7040, 7459, 7902, 8372, 8870, 9397, 9956, 10548, 11175, 11840, 12544, 13290, 14080
];

def play(kind: long, arg: long) -> void {
    if (!ENABLED || MUTED) { return; };
    let next = (CQ_W + 1) & 63;
    if (next == CQ_R) { return; };
    CQ_K[CQ_W] = kind;
    CQ_A[CQ_W] = arg;
    CQ_W = next;
}

def mute(on: bool) -> void {
    if (on && ENABLED) {

        play(MUSIC, 0);
        play(DRONE_ON, 0);
    };
    MUTED = on;
}

def start_voice(kind: long, f16: long, dur: long, vol: long) -> void {
    let best = 0;
    let oldest = -1;
    for i in 0..NVO {
        if (V_KIND[i] == 0) {
            best = i;
            oldest = 1 << 40;
            break;
        };
        if (V_T[i] > oldest) {
            oldest = V_T[i];
            best = i;
        };
    };
    V_KIND[best] = kind;
    V_T[best] = 0;
    V_DUR[best] = dur;
    V_F[best] = f16;
    V_PH[best] = 0;
    V_PH2[best] = 0;
    V_PH3[best] = 0;
    V_VOL[best] = vol;
}

def command(k: long, a: long) -> void {
    if (k == BELL) { start_voice(BELL, 16 * 196, RATE * 4, 230); };
    if (k == CRACK) { start_voice(CRACK, 16 * 2400, RATE / 3, 256); };
    if (k == CHIME) { start_voice(CHIME, SEMI[12 + (a & 7)] * 2, RATE / 5, 90); };
    if (k == STEP) { start_voice(STEP, 0, RATE / 25, 50); };
    if (k == SWING) { start_voice(SWING, 0, RATE / 8, 70); };
    if (k == HIT) { start_voice(HIT, 16 * 110, RATE / 8, 180); };
    if (k == HURT) { start_voice(HURT, 16 * 220, RATE / 5, 160); };
    if (k == BLIP) { start_voice(BLIP, 16 * 880, RATE / 30, 60); };
    if (k == HEART) {

        start_voice(HIT, 16 * 52, RATE / 7, 230);
        start_voice(HIT, 16 * 64, RATE / 9, 150);
    };
    if (k == FIRE) { start_voice(FIRE, 0, RATE * 2, 90); };
    if (k == SPLASH) { start_voice(SPLASH, 0, RATE / 3, 110); };
    if (k == PICKUP) { start_voice(PICKUP, 16 * 660, RATE / 6, 90); };
    if (k == DRONE_ON) { DRONE = a != 0; };
    if (k == MUSIC) { music_start(a); };
    if (k == CASCADE) { start_voice(CASCADE, 16 * 3000, RATE / 2, 200); };
    if (k == SWELL) { start_voice(SWELL, 16 * 440, RATE * 3, 160); };
    if (k == VOLUME) { GAIN = a; };
}

def noise() -> long {
    NOISE = (NOISE * 1103515245 + 12345) & 0x7fffffff;
    ((NOISE >> 8) & 65535) - 32768
}

def osc(ph: long) -> long { fx.SIN[(ph >> 6) & 1023] }

def env(t: long, dur: long) -> long {
    if (t >= dur) { return 0; };
    let x = 256 - t * 256 / dur;
    (x * x) >> 8
}

def voice_sample(i: long) -> long {
    let k = V_KIND[i];
    let t = V_T[i];
    let dur = V_DUR[i];
    if (t >= dur) {
        V_KIND[i] = 0;
        return 0;
    };
    let e = env(t, dur);
    let s = 0;
    if (k == BELL) {

        V_PH[i] += V_F[i] * 65536 / 16 / RATE;
        V_PH2[i] += V_F[i] * 2756 / 1000 * 65536 / 16 / RATE;
        V_PH3[i] += V_F[i] * 5404 / 1000 * 65536 / 16 / RATE;
        s = (osc(V_PH[i]) * 3 + osc(V_PH2[i]) * 2 + osc(V_PH3[i])) / 6;
        if (t < 300) { s += noise() * (300 - t) / 600; };
    } else if (k == CRACK) {

        let f = V_F[i] - t * 4;
        if (f < 1600) { f = 1600; };
        V_PH[i] += f * 65536 / 16 / RATE;
        let sq = if ((V_PH[i] & 32768) != 0) { 20000 } else { -20000 };
        s = (noise() + sq) / 2;
        e = env(t, dur);
        e = (e * e) >> 8;
    } else if (k == CHIME || k == BLIP || k == PICKUP) {
        let f = V_F[i];
        if (k == PICKUP && t > dur / 2) { f = f * 3 / 2; };
        V_PH[i] += f * 65536 / 16 / RATE;
        V_PH2[i] += f * 2 * 65536 / 16 / RATE;
        s = (osc(V_PH[i]) * 3 + osc(V_PH2[i])) / 4;
    } else if (k == STEP) {
        s = noise() / 3;
    } else if (k == SWING) {
        let w = if (t < dur / 2) { t * 512 / dur } else { (dur - t) * 512 / dur };
        s = (noise() * w) >> 9;
        e = 256;
    } else if (k == HIT || k == HURT) {
        let f = V_F[i] - t * 3;
        if (f < 400) { f = 400; };
        V_PH[i] += f * 65536 / 16 / RATE;
        s = osc(V_PH[i]) / 2 + noise() / 4;
    } else if (k == FIRE) {
        s = (noise() * (fx.noise(t / 300, 0, 0) + 40)) >> 9;
        e = 256 - t * 256 / dur;
    } else if (k == SPLASH) {
        s = noise() / 2;
    } else if (k == CASCADE) {
        V_PH[i] += (V_F[i] + (noise() >> 4)) * 65536 / 16 / RATE;
        s = (osc(V_PH[i]) + noise()) / 2;
    } else if (k == SWELL) {
        let f = V_F[i] + t * 16 * 4 / 100;
        V_PH[i] += f * 65536 / 16 / RATE;
        s = osc(V_PH[i]) / 2;
        e = if (t < dur * 3 / 4) { t * 256 / (dur * 3 / 4) } else { (dur - t) * 1024 / dur };
    };
    V_T[i] = t + 1;
    (s * e >> 8) * V_VOL[i] >> 8
}

let LT: [long; 3] = [0, 0, 0];
let PH_START: [long; 256] = [0; 256];
let PH_CNT: [long; 16] = [0; 16];
let PH_BUILT = false;
let L0_PH = 0;
let L0_K = 0;
let L0_END = 0;
let MEL_REST = false;
let PAD_DUE = false;
let MR = 12345;

def mrnd(n: long) -> long {
    MR = (MR * 1103515245 + 12345) & 0x7fffffff;
    ((MR >> 8) & 0xffffff) % n
}

def build_phrases() -> void {
    for t in 1..16 {
        PH_CNT[t] = 0;
        if (T_N[t] == 0) { continue; };
        let acc = 0;
        PH_START[t * 16] = 0;
        PH_CNT[t] = 1;
        for k in 0..T_N[t] {
            acc += TRK[(T_OFF[t] + k) * 2 + 1];
            if (acc >= 16 && k + 1 < T_N[t] && PH_CNT[t] < 16) {
                PH_START[t * 16 + PH_CNT[t]] = k + 1;
                PH_CNT[t] += 1;
                acc = 0;
            };
        };
    };
    PH_BUILT = true;
}

def pick_phrase() -> void {
    let cnt = PH_CNT[MUS];
    if (cnt > 1) {

        if (mrnd(100) < 55) { L0_PH = (L0_PH + 1) % cnt; } else { L0_PH = mrnd(cnt); };
    } else {
        L0_PH = 0;
    };
    L0_K = PH_START[MUS * 16 + L0_PH];
    PAD_DUE = true;
    L0_END = if (L0_PH + 1 < cnt) { PH_START[MUS * 16 + L0_PH + 1] } else { T_N[MUS] };
}

def music_start(id: long) -> void {
    MUS = id;
    MUS_T = 0;
    MUS_I = 0;
    if (!PH_BUILT) { build_phrases(); };
    if (id <= 0 || id >= 16 || T_N[id] == 0) { return; };
    let beat = RATE / T_BEAT[id];
    L0_PH = mrnd(PH_CNT[id]);
    pick_phrase();
    LT[0] = 1;
    LT[1] = beat * 64;
    LT[2] = beat * 8;
    MEL_REST = false;
}

def layer_melody(beat: long) -> void {
    if (L0_K >= L0_END) {

        let r = 0;
        if (T_REST[MUS] > 0 && mrnd(3) != 0) { r = 4 + mrnd(T_REST[MUS]); };
        pick_phrase();
        MEL_REST = r > 0;
        LT[0] = beat * r + 1;
        return;
    };
    MEL_REST = false;
    let k = (T_OFF[MUS] + L0_K) * 2;
    let note = TRK[k];
    let len8 = TRK[k + 1];
    L0_K += 1;
    LT[0] = beat * len8;
    if (note < 0) { return; };

    if (T_REST[MUS] > 0 && note + 12 <= 24 && mrnd(9) == 0) { note += 12; };
    let dur = beat * len8 + RATE / T_TAIL[MUS];
    start_voice(CHIME, SEMI[note % 25] * T_FM[MUS], dur, T_VOL[MUS]);
    if (T_HARM[MUS] != 0 && note + T_HARM[MUS] >= 0 && note + T_HARM[MUS] < 25) {
        start_voice(CHIME, SEMI[note + T_HARM[MUS]] * T_FM[MUS], dur, T_VOL2[MUS]);
    };

    if (PAD_DUE && T_PADV[MUS] > 0) {
        PAD_DUE = false;
        let root = note % 12;
        start_voice(CHIME, SEMI[root] * T_FM[MUS] / 2, beat * 14 + RATE / 2, T_PADV[MUS]);
        start_voice(CHIME, SEMI[root + 7] * T_FM[MUS] / 2, beat * 14 + RATE / 2, T_PADV[MUS] * 2 / 3);
    };
}

def layer_pad(beat: long) -> void {
    if (T_PADV[MUS] == 0) {
        LT[1] = beat * 64;
        return;
    };
    if (mrnd(5) == 0) {
        LT[1] = beat * (6 + mrnd(10));
        return;
    };
    let sc = T_SC[MUS];
    let root = CH[sc * 5 + mrnd(5)];
    let dur = beat * 14 + RATE;
    start_voice(CHIME, SEMI[root] * T_FM[MUS] / 2, dur, T_PADV[MUS]);
    if (mrnd(2) == 0) { start_voice(CHIME, SEMI[root + 7] * T_FM[MUS] / 2, dur, T_PADV[MUS] * 2 / 3); };
    LT[1] = beat * (10 + mrnd(12));
}

def layer_spark(beat: long) -> void {
    if (T_SPKV[MUS] == 0) {
        LT[2] = beat * 64;
        return;
    };

    if (!MEL_REST || LT[0] < beat * 8) {
        LT[2] = beat * 2;
        return;
    };
    if (mrnd(2) == 0) {
        LT[2] = beat * 3;
        return;
    };
    let sc = T_SC[MUS];
    let note = SC[sc * 7 + mrnd(SC_N[sc])] + 12;
    if (mrnd(3) == 0 && note + 12 <= 24) { note += 12; };
    start_voice(CHIME, SEMI[note] * T_FM[MUS], beat * 3 + RATE / 3, T_SPKV[MUS]);
    LT[2] = beat * (6 + mrnd(6));
}

def music_sample() -> long {
    if (MUS <= 0 || MUS >= 16 || T_N[MUS] == 0) { return 0; };
    let beat = RATE / T_BEAT[MUS];
    LT[0] -= 1;
    LT[1] -= 1;
    LT[2] -= 1;
    if (LT[0] <= 0) { layer_melody(beat); };
    LT[1] = beat * 64;
    if (LT[2] <= 0) { layer_spark(beat); };
    0
}

def thread_main() -> long {
    pulse.TLEN = RATE * 2 / 8;
    pulse.PREBUF = RATE * 2 / 40;
    pulse.MINREQ = RATE * 2 / 100;
    let st = pulse.open(RATE, 1, "heavenly rules");
    if (st == none) {
        ENABLED = false;
        return 0;
    };
    let buf: [byte] = [];
    for i in 0..(CHUNK * 2) { buf += 0; };
    while (true) {
        while (CQ_R != CQ_W) {
            command(CQ_K[CQ_R], CQ_A[CQ_R]);
            CQ_R = (CQ_R + 1) & 63;
        };
        for n in 0..CHUNK {
            music_sample();
            let s = 0;
            for i in 0..NVO {
                if (V_KIND[i] != 0) { s += voice_sample(i); };
            };
            if (DRONE) {
                DRONE_PH += 55 * 65536 / RATE;
                DRONE_PH2 += 82 * 65536 / RATE;
                s += (osc(DRONE_PH) + osc(DRONE_PH2) / 2) / 8;
            };
            s = (s * GAIN) >> 8;
            if (MUTED) { s = 0; };
            if (s > 32767) { s = 32767; };
            if (s < -32768) { s = -32768; };
            buf[n * 2] = s & 255;
            buf[n * 2 + 1] = (s >> 8) & 255;
        };
        if (!pulse.write(st!, buf)) { break; };
    };
    ENABLED = false;
    0
}

def start(want: bool) -> void {
    if (!want || STARTED) { return; };
    pulse.warm_env();
    if (!pulse.available()) { return; };
    STARTED = true;
    ENABLED = true;
    spawn { thread_main() };
}

def music_probe(id: long, secs: long) -> long {
    music_start(id);
    let notes = 0;
    for n in 0..(secs * RATE) {
        music_sample();
        for i in 0..NVO { if (V_KIND[i] != 0) { V_KIND[i] = 0; notes += 1; }; };
    };
    MUS = 0;
    notes
}

export {
    start, play, mute, music_probe, ENABLED, MUTED,
    BELL, CRACK, CHIME, STEP, SWING, HIT, HURT, BLIP, FIRE, SPLASH, PICKUP,
    DRONE_ON, MUSIC, CASCADE, SWELL, VOLUME, HEART
};
