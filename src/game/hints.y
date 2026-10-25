
import g;
import mem;
import dlg;
import world;
import story;

const NSTAGE = 9;
const TIER2_AT = 9000;
const TIER3_AT = 18000;

let STAGE = -1;
let STUCK = 0;
let SHOWN2 = false;
let SHOWN3 = false;

let N2: [long; 9] = [-1; 9];
let N3: [long; 9] = [-1; 9];
let WHO: [long; 9] = [-1; 9];

def bind() -> void {
    N2[0] = dlg.node_id("hint.L1-a.2");
    N2[1] = dlg.node_id("hint.L1-b.2");
    N2[2] = dlg.node_id("hint.L2-a.2");
    N2[3] = dlg.node_id("hint.L2-b.2");
    N2[4] = dlg.node_id("hint.L2-c.2");
    N2[5] = dlg.node_id("hint.L2-d.2");
    N2[6] = dlg.node_id("hint.L2-e.2");
    N2[7] = dlg.node_id("hint.L2-f.2");
    N2[8] = dlg.node_id("hint.L2-g.2");
    N3[0] = dlg.node_id("hint.L1-a.3");
    N3[1] = dlg.node_id("hint.L1-b.3");
    N3[2] = dlg.node_id("hint.L2-a.3");
    N3[3] = dlg.node_id("hint.L2-b.3");
    N3[4] = dlg.node_id("hint.L2-c.3");
    N3[5] = dlg.node_id("hint.L2-d.3");
    N3[6] = dlg.node_id("hint.L2-e.3");
    N3[7] = dlg.node_id("hint.L2-f.3");
    N3[8] = dlg.node_id("hint.L2-g.3");
    WHO[0] = world.person_id("nib");
    WHO[1] = world.person_id("effie");
    WHO[2] = world.person_id("isa");
    WHO[3] = world.person_id("elf");
    WHO[4] = world.person_id("cass");
    WHO[5] = world.person_id("edi");
    WHO[6] = world.person_id("isa");
    WHO[7] = world.person_id("rama");
    WHO[8] = world.person_id("edi");
}

def stage_now() -> long {
    if (g.HAND_FREED || g.HANDLESS) { return -1; };
    if (!g.has(g.F_RHYME)) { return 0; };
    if (!g.has(g.F_RULES_SEEN) && !g.has(g.F_FISHER_DIED)) { return 1; };
    if (g.LOOP < 2) { return -1; };

    if (mem.link(mem.A_RULE1 + 3) == mem.A_LETTER && mem.is_code(mem.A_LETTER)) { return -1; };
    if (mem.is_code(mem.A_LETTER)) { return 8; };
    if (g.has(g.F_FOUND13)) { return 7; };
    if (g.has(g.F_LEAK)) { return 6; };
    if (!g.has(g.F_RITE)) { return 2; };
    if (!g.has(g.F_REALLOC)) { return 3; };
    if (!g.has(g.F_OVERFLOW)) { return 4; };
    5
}

def tick(counting: bool) -> void {
    let s = stage_now();
    if (s != STAGE) {
        STAGE = s;
        STUCK = 0;
        SHOWN2 = false;
        SHOWN3 = false;
        return;
    };
    if (s < 0 || !counting) { return; };
    STUCK += 1;

    if (STUCK >= TIER2_AT && !g.has(g.W_STUCK)) { g.set(g.W_STUCK); };
    if (STUCK >= TIER3_AT && !SHOWN3 && g.LOOP >= 2) {
        SHOWN3 = true;
        story.say_node(N3[s]);
    };
}

def talk_hint(p: long) -> long {
    if (STAGE < 0 || SHOWN2 || STUCK < TIER2_AT || WHO[STAGE] != p) { return -1; };
    SHOWN2 = true;
    N2[STAGE]
}

def reset() -> void {
    STAGE = -1;
    STUCK = 0;
    SHOWN2 = false;
    SHOWN3 = false;
}

def advice_stage() -> long {
    if (g.HAND_FREED || g.HANDLESS) { return 11; };
    let s = stage_now();
    if (s >= 0) { return s; };
    if (g.LOOP < 2) { return 10; };
    9
}

def update_advice() -> void { g.ADVICE = advice_stage(); }

export { update_advice, advice_stage, bind, tick, talk_hint, reset, stage_now, STAGE, STUCK };
