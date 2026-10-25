
let MIN = 360;
let SUB = 0;
let DAY = 1;
const BELL_MIN = 1080;
const NIGHT_END = 1440;
let CLOCK_RUN = true;
let NIGHT = false;

def hour() -> long { MIN / 60 }
def minute() -> long { MIN % 60 }

let LOOP = 1;
let BOOTS = 0;
let RETRIES = 0;
let HAND_FREED = false;
let HANDLESS = false;
let VOID_LAUNCHES = 0;
let ADVICE = 0;

const NFLAG = 128;
let FLAG: [bool; 128] = [false; 128];
const FIRST_WORLD_FLAG = 64;

const F_RHYME = 1;
const F_BOOK = 2;
const F_RULES_SEEN = 3;
const F_ELDER_HALF = 4;
const F_RITE = 5;
const F_REALLOC = 6;
const F_OVERFLOW = 7;
const F_LEAK = 8;
const F_SCRAPER = 9;
const F_FOUND13 = 10;
const F_HAND_READ = 11;
const F_SEAL_EDIT = 12;
const F_BOTCHED = 13;
const F_STRUCK_ONCE = 14;
const F_LETTER_HINT = 15;
const F_FISHER_DIED = 16;
const F_BOAR = 17;
const F_WARDEN = 18;
const F_LEAK_BEAT = 19;
const F_VOID_SEEN = 30;
const F_TRUE_END = 29;
const F_SATCHEL = 20;
const F_GRAVITY = 21;
const F_LEVEL_WRAP = 22;
const F_APPLES = 23;
const F_HUD_STRUCK = 24;
const F_FIRE_SEEN = 25;
const F_TORII = 26;
const F_BOOK_LENT = 27;
const F_SAW13 = 28;

const W_SCRAPER = 64;
const W_FIRE = 65;
const W_FIRE_OUT = 66;
const W_ELDER_DEAD = 67;
const W_BRAM_GONE = 68;
const W_LARK_GONE = 69;
const W_CORIN_SINNED = 70;
const W_GATE_NIGHT = 71;
const W_BUCKET = 72;
const W_BLADE_RENAMED = 73;
const W_BOAR = 74;
const W_WARDEN = 75;
const W_LEAK = 76;
const W_RULES_GONE = 77;
const W_BELL_GONE = 78;
const W_WEIGHT_GONE = 79;
const W_LOST_CHILD = 80;
const W_LOST_DONE = 81;
const W_APPLES_QUEST = 82;
const W_GREETED = 83;
const W_INTRO = 84;
const W_FISH_TAKEN = 85;
const W_PRAYED = 86;
const W_RITE_DONE_TODAY = 87;

const W_B_BOTTLE = 88;
const W_FIRE_LOST = 89;
const W_B_NET = 90;
const W_B_RITE = 91;
const W_B_BELL = 92;
const W_GHOST_UP = 93;
const W_SEEN_BOAR = 94;
const W_SEEN_WARDEN = 95;
const W_B_NIGHTGATE = 96;
const W_B_FIRE = 97;
const W_B_LARK = 98;
const W_SEEN_LEAK = 123;
const W_LEAK_ITEMS = 124;
const W_B_SEAL = 125;
const W_B_HEAVEN = 126;
const W_B_ENDING = 99;
const W_B_ASK = 100;
const W_STUCK = 101;

def set(f: long) -> void { FLAG[f] = true; }
def has(f: long) -> bool { FLAG[f] }
def clear_world() -> void {
    for f in FIRST_WORLD_FLAG..NFLAG { FLAG[f] = false; };
}

let FLAG_NAME: [str; 128] = [""; 128];

def init_names() -> void {
    FLAG_NAME[F_RHYME] = "rhyme";
    FLAG_NAME[F_BOOK] = "book";
    FLAG_NAME[F_RULES_SEEN] = "rules_seen";
    FLAG_NAME[F_ELDER_HALF] = "elder_half";
    FLAG_NAME[F_RITE] = "rite";
    FLAG_NAME[F_REALLOC] = "realloc";
    FLAG_NAME[F_OVERFLOW] = "overflow";
    FLAG_NAME[F_LEAK] = "leak";
    FLAG_NAME[F_SCRAPER] = "scraper";
    FLAG_NAME[F_FOUND13] = "found13";
    FLAG_NAME[F_HAND_READ] = "hand_read";
    FLAG_NAME[F_SEAL_EDIT] = "seal_edit";
    FLAG_NAME[F_BOTCHED] = "botched";
    FLAG_NAME[F_STRUCK_ONCE] = "struck_once";
    FLAG_NAME[F_LETTER_HINT] = "letter_hint";
    FLAG_NAME[F_FISHER_DIED] = "fisher_died";
    FLAG_NAME[F_BOAR] = "boar";
    FLAG_NAME[F_WARDEN] = "warden";
    FLAG_NAME[F_LEAK_BEAT] = "leak_beat";
    FLAG_NAME[F_SATCHEL] = "satchel";
    FLAG_NAME[F_TRUE_END] = "true_end";
    FLAG_NAME[F_VOID_SEEN] = "void_seen";
    FLAG_NAME[F_GRAVITY] = "gravity";
    FLAG_NAME[F_LEVEL_WRAP] = "level_wrap";
    FLAG_NAME[F_APPLES] = "apples";
    FLAG_NAME[F_HUD_STRUCK] = "hud_struck";
    FLAG_NAME[F_FIRE_SEEN] = "fire_seen";
    FLAG_NAME[F_TORII] = "torii";
    FLAG_NAME[F_BOOK_LENT] = "book_lent";
    FLAG_NAME[F_SAW13] = "saw13";
    FLAG_NAME[W_SCRAPER] = "w.scraper";
    FLAG_NAME[W_FIRE] = "w.fire";
    FLAG_NAME[W_FIRE_OUT] = "w.fire_out";
    FLAG_NAME[W_ELDER_DEAD] = "w.elder_dead";
    FLAG_NAME[W_BRAM_GONE] = "w.bram_gone";
    FLAG_NAME[W_LARK_GONE] = "w.lark_gone";
    FLAG_NAME[W_CORIN_SINNED] = "w.corin_sinned";
    FLAG_NAME[W_GATE_NIGHT] = "w.gate_night";
    FLAG_NAME[W_BUCKET] = "w.bucket";
    FLAG_NAME[W_BLADE_RENAMED] = "w.blade_renamed";
    FLAG_NAME[W_BOAR] = "w.boar";
    FLAG_NAME[W_WARDEN] = "w.warden";
    FLAG_NAME[W_LEAK] = "w.leak";
    FLAG_NAME[W_RULES_GONE] = "w.rules_gone";
    FLAG_NAME[W_BELL_GONE] = "w.bell_gone";
    FLAG_NAME[W_WEIGHT_GONE] = "w.weight_gone";
    FLAG_NAME[W_LOST_CHILD] = "w.lost_child";
    FLAG_NAME[W_LOST_DONE] = "w.lost_done";
    FLAG_NAME[W_APPLES_QUEST] = "w.apples_quest";
    FLAG_NAME[W_GREETED] = "w.greeted";
    FLAG_NAME[W_INTRO] = "w.intro";
    FLAG_NAME[W_FISH_TAKEN] = "w.fish_taken";
    FLAG_NAME[W_PRAYED] = "w.prayed";
    FLAG_NAME[W_RITE_DONE_TODAY] = "w.rite_done_today";
    FLAG_NAME[W_FIRE_LOST] = "w.fire_lost";
    FLAG_NAME[W_SEEN_LEAK] = "w.seen_leak";
    FLAG_NAME[W_LEAK_ITEMS] = "w.leak_items";
    FLAG_NAME[W_B_SEAL] = "w.b_seal";
    FLAG_NAME[W_B_HEAVEN] = "w.b_heaven";
    FLAG_NAME[W_B_ASK] = "w.b_ask";
    FLAG_NAME[W_STUCK] = "w.stuck";
    FLAG_NAME[W_B_BOTTLE] = "w.b_bottle";
    FLAG_NAME[W_B_NET] = "w.b_net";
    FLAG_NAME[W_B_RITE] = "w.b_rite";
    FLAG_NAME[W_B_BELL] = "w.b_bell";
    FLAG_NAME[W_GHOST_UP] = "w.ghost_up";
    FLAG_NAME[W_SEEN_BOAR] = "w.seen_boar";
    FLAG_NAME[W_SEEN_WARDEN] = "w.seen_warden";
    FLAG_NAME[W_B_NIGHTGATE] = "w.b_nightgate";
    FLAG_NAME[W_B_FIRE] = "w.b_fire";
    FLAG_NAME[W_B_LARK] = "w.b_lark";
    FLAG_NAME[W_B_ENDING] = "w.b_ending";
}

def flag_id(name: str) -> long {
    for i in 0..NFLAG {
        if (FLAG_NAME[i] == name) { return i; };
    };
    let world_flag = len(name) > 2 && name[0] == 'w' && name[1] == '.';
    let lo = if (world_flag) { 100 } else { 30 };
    let hi = if (world_flag) { 128 } else { 64 };
    for i in lo..hi {
        if (FLAG_NAME[i] == "") {
            FLAG_NAME[i] = name;
            return i;
        };
    };
    127
}

let COINS = 0;
let XP = 0;
let LEVEL = 1;
let HP = 20;
let HP_MAX = 20;
let ATK = 3;
let APPLES = 0;
let EFFIGIES = 0;
const HAS_BUCKET = true;

const EV_RULE = 1;
const EV_STRIKE = 2;
const EV_SAY = 3;
const EV_TOAST = 4;
const EV_SCRIPT = 5;

let EQ_K: [long; 64] = [0; 64];
let EQ_A: [long; 64] = [0; 64];
let EQ_B: [long; 64] = [0; 64];
let EQ_N = 0;

def emit(k: long, a: long, b: long) -> void {
    if (EQ_N >= 64) { return; };
    EQ_K[EQ_N] = k;
    EQ_A[EQ_N] = a;
    EQ_B[EQ_N] = b;
    EQ_N += 1;
}

let ASCII_RUNES = false;
let RUNE_MODE = 0;
let MUTE = false;

export {
    MIN, SUB, DAY, BELL_MIN, NIGHT_END, CLOCK_RUN, NIGHT, hour, minute,
    LOOP, BOOTS, RETRIES, HAND_FREED, HANDLESS, VOID_LAUNCHES, ADVICE,
    FLAG, NFLAG, FIRST_WORLD_FLAG, set, has, clear_world, FLAG_NAME, init_names, flag_id,
    F_RHYME, F_BOOK, F_RULES_SEEN, F_ELDER_HALF, F_RITE, F_REALLOC, F_OVERFLOW,
    F_LEAK, F_SCRAPER, F_FOUND13, F_HAND_READ, F_SEAL_EDIT, F_BOTCHED,
    F_STRUCK_ONCE, F_LETTER_HINT, F_FISHER_DIED, F_BOAR, F_WARDEN, F_LEAK_BEAT,
    F_TRUE_END, F_VOID_SEEN, F_SATCHEL, F_GRAVITY, F_LEVEL_WRAP, F_APPLES, F_HUD_STRUCK, F_FIRE_SEEN,
    F_TORII, F_BOOK_LENT, F_SAW13,
    W_SCRAPER, W_FIRE, W_FIRE_OUT, W_ELDER_DEAD, W_BRAM_GONE, W_LARK_GONE,
    W_CORIN_SINNED, W_GATE_NIGHT, W_BUCKET, W_BLADE_RENAMED, W_BOAR, W_WARDEN,
    W_LEAK, W_RULES_GONE, W_BELL_GONE, W_WEIGHT_GONE, W_LOST_CHILD,
    W_LOST_DONE, W_APPLES_QUEST, W_GREETED, W_INTRO, W_FISH_TAKEN, W_PRAYED,
    W_RITE_DONE_TODAY, W_B_BOTTLE, W_FIRE_LOST, W_B_NET, W_B_RITE, W_B_BELL,
    W_GHOST_UP, W_SEEN_BOAR, W_SEEN_WARDEN, W_B_NIGHTGATE, W_B_FIRE, W_B_LARK,
    W_B_ENDING, W_B_ASK, W_STUCK, W_B_HEAVEN, W_B_SEAL, W_SEEN_LEAK, W_LEAK_ITEMS,
    COINS, XP, LEVEL, HP, HP_MAX, ATK, APPLES, EFFIGIES, HAS_BUCKET,
    EV_RULE, EV_STRIKE, EV_SAY, EV_TOAST, EV_SCRIPT, EQ_K, EQ_A, EQ_B, EQ_N, emit,
    ASCII_RUNES, RUNE_MODE, MUTE
};
