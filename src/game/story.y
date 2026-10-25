
import g;
import mem;
import ent;
import world;
import rules;
import dlg;
import town;
import sprite;
import sfx;

let QN = 0;
let Q_NODE: [long; 8] = [0; 8];

let P_RAX = -1;
let P_CY = -1;
let P_BUS = -1;
let P_BIOS = -1;
let Z_LAKE = -1;
let Z_FIELDS = -1;
let Z_GRAVE = -1;
let O_FIRE = -1;
let O_GRAVE = -1;
let SPR_FIRE = -1;
let O_SHORE = -1;

let N_BOTTLE = -1;
let N_BELL = -1;
let N_FIRE = -1;
let N_FIRE_LOST = -1;
let N_LARK = -1;
let N_NIGHT_GATE = -1;
let N_UNNAMED = -1;
let N_REALLOC = -1;
let N_BOAR = -1;
let N_WARDEN = -1;
let N_TRUE = -1;
let N_SEAL = -1;
let N_LEAK = -1;
let N_ASK = -1;
let O_LEAK = -1;

def bind() -> void {
    P_RAX = world.person_id("rax");
    P_CY = world.person_id("cy");
    P_BUS = world.person_id("bus");
    P_BIOS = world.person_id("bios");
    Z_LAKE = world.zone_id("lake");
    Z_FIELDS = world.zone_id("fields");
    Z_GRAVE = world.zone_id("graveyard");
    O_FIRE = world.find(world.OK_SPOT, Z_FIELDS, "granary");
    O_GRAVE = world.find(world.OK_SPOT, Z_GRAVE, "eldergrave");
    O_SHORE = world.find(world.OK_SPOT, Z_LAKE, "shore");
    SPR_FIRE = sprite.id("fire");
    N_BOTTLE = dlg.node_id("beat.bottle");
    N_BELL = dlg.node_id("beat.bell");
    N_FIRE = dlg.node_id("beat.fire");
    N_FIRE_LOST = dlg.node_id("beat.fire_lost");
    N_LARK = dlg.node_id("beat.lark");
    N_NIGHT_GATE = dlg.node_id("beat.night_gate");
    N_UNNAMED = dlg.node_id("beat.unnamed");
    N_REALLOC = dlg.node_id("beat.realloc");
    N_BOAR = dlg.node_id("beat.boar");
    N_WARDEN = dlg.node_id("beat.warden");
    N_TRUE = dlg.node_id("ending.true");
    N_SEAL = dlg.node_id("beat.seal");
    N_LEAK = dlg.node_id("leak");
    N_ASK = dlg.node_id("beat.ask");
    O_LEAK = world.find(world.OK_SPAWN, Z_FIELDS, "leak");
}

def say_node(n: long) -> void {
    if (n < 0 || QN >= 8) { return; };
    Q_NODE[QN] = n;
    QN += 1;
}

def say(name: str) -> void { say_node(dlg.node_id(name)); }

def clear_queue() -> void { QN = 0; }

def show(can_show: bool) -> void {
    if (!can_show || QN == 0) { return; };
    let n = Q_NODE[0];
    for i in 1..QN { Q_NODE[i - 1] = Q_NODE[i]; };
    QN -= 1;
    dlg.start_node(n, -1);
}

def unnamed() -> void {
    if (!g.has(g.F_TORII)) { say_node(N_UNNAMED); };
}

def realloc() -> void { say_node(N_REALLOC); }

def night_gate() -> void {
    if (g.has(g.W_B_NIGHTGATE)) { return; };
    g.set(g.W_B_NIGHTGATE);
    say_node(N_NIGHT_GATE);
}

def scatter_lost(zone: long) -> void {
    if (zone != Z_FIELDS || O_LEAK < 0 || g.LOOP < 2 || g.NIGHT || g.has(g.W_LEAK) || g.has(g.W_LEAK_ITEMS)) { return; };
    g.set(g.W_LEAK_ITEMS);
    let x = world.O_X[O_LEAK];
    let z = world.O_Z[O_LEAK];
    ent.spawn_item(ent.IT_BOTTLE, zone, (x - 3) * 65536 + 32768, (z + 2) * 65536 + 32768);
    ent.spawn_item(ent.IT_NET, zone, (x - 4) * 65536 + 32768, (z + 1) * 65536 + 32768);
    ent.spawn_item(ent.IT_FISH, zone, (x - 2) * 65536 + 32768, (z + 4) * 65536 + 32768);
}

def enter_zone(zone: long) -> void {
    scatter_lost(zone);
    if (zone == Z_GRAVE && g.NIGHT && g.has(g.W_ELDER_DEAD)) { raise_ghost(); };
}

def leave_zone(zone: long) -> void {
    if (zone != Z_GRAVE) { return; };
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_GHOST) { ent.remove(e); };
    };
    g.FLAG[g.W_GHOST_UP] = false;
}

def next_day() -> void {
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_GHOST) { ent.remove(e); };
    };
    g.FLAG[g.W_GHOST_UP] = false;
    g.FLAG[g.W_B_BELL] = false;
}

def raise_ghost() -> void {
    if (g.has(g.W_GHOST_UP) || O_GRAVE < 0) { return; };
    let e = ent.new_ent(ent.K_GHOST, Z_GRAVE, (world.O_X[O_GRAVE] + 1) * 65536 + 32768, world.O_Z[O_GRAVE] * 65536 + 32768);
    if (e < 0) { return; };
    ent.E_SPR[e] = ent.SPR_GHOST;
    ent.E_PS[e] = ent.PS_GHOST;
    ent.E_WHO[e] = P_BIOS;
    g.set(g.W_GHOST_UP);
}

def person_ok(p: long) -> long {
    if (p < 0) { return -1; };
    let e = ent.PERSON_ENT[p];
    if (e < 0 || !ent.E_ALIVE[e]) { return -1; };
    e
}

def door_in(zone: long) -> long {
    for o in 0..world.NO {
        if (world.O_ZONE[o] == zone && world.O_KIND[o] == world.OK_DOOR && world.O_ARG[o] >= 0) { return o; };
    };
    -1
}

def zees_rite() -> void {
    let b = person_ok(P_BUS);
    let c = person_ok(P_CY);
    if (b < 0 || c < 0 || ent.E_TRANSIT[b] > 0 || ent.E_SLOT[b] < 0 || ent.E_SLOT[c] < 0) { return; };

    ent.unname(b);
    ent.E_TRANSIT[b] = 1;
    ent.E_TR_ZONE[b] = ent.E_ZONE[b];
    ent.E_TR_X[b] = ent.E_X[b];
    ent.E_TR_Z[b] = ent.E_Z[b];
    ent.unname(c);
    ent.transit_tick(b);

    let vx = ent.E_X[c] + 56000;
    if (!world.free_at(ent.E_ZONE[c], vx, ent.E_Z[c])) { vx = ent.E_X[c] - 56000; };
    if (!world.free_at(ent.E_ZONE[c], vx, ent.E_Z[c])) { vx = ent.E_X[c]; };
    ent.spawn_vessel(ent.E_ZONE[c], vx, ent.E_Z[c]);
    ent.name_it(c);
    g.set(g.W_B_RITE);
}

def boss_near(t: long) -> bool {
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_MON && ent.E_WHO[e] == t && ent.E_ALIVE[e] && ent.dist(e, 0) < 6 * 65536) { return true; };
    };
    false
}

def tick(can_show: bool) -> void {
    let m = g.MIN;
    if (!g.HANDLESS) {
        if (g.DAY == 1 && m >= 480 && !g.has(g.W_B_BOTTLE)) {

            g.set(g.W_B_BOTTLE);
            let r = person_ok(P_RAX);
            if (r >= 0) {
                rules.record(1, ent.E_SLOT[r]);
                if (ent.E_ZONE[0] == Z_LAKE) { say_node(N_BOTTLE); };
            };
        };
        if (g.LOOP >= 2 && g.DAY == 1 && m >= 540 && !g.has(g.W_B_NET)) {

            let c = person_ok(P_CY);
            if (c >= 0 && ent.E_ZONE[c] == Z_LAKE && ent.E_TRANSIT[c] == 0 && ent.E_SLOT[c] >= 0) {
                g.set(g.W_B_NET);
                g.set(g.W_CORIN_SINNED);
                rules.record(1, ent.E_SLOT[c]);
            };
        };
        if (g.LOOP >= 2 && g.DAY == 1 && g.has(g.W_CORIN_SINNED) && !g.has(g.W_B_RITE) && m >= 1050 && m < 1078) {
            zees_rite();
        };
        if (g.DAY >= 2 && !g.has(g.W_ELDER_DEAD)) {

            let b = person_ok(P_BIOS);
            if (b >= 0) { ent.remove(b); };
            g.set(g.W_ELDER_DEAD);
            town.bury(0xB0, "BIOS");
        };
        if (g.DAY == 2 && m >= 900 && !g.has(g.W_B_FIRE)) {
            g.set(g.W_B_FIRE);
            g.set(g.W_FIRE);
            g.set(g.F_FIRE_SEEN);
            sfx.play(sfx.FIRE, 0);
            say_node(N_FIRE);
        };
        if (g.has(g.W_FIRE) && !g.has(g.W_FIRE_OUT) && !g.has(g.W_FIRE_LOST) && m >= 1020) {
            g.set(g.W_FIRE_LOST);
            say_node(N_FIRE_LOST);
        };
        if (g.has(g.W_LARK_GONE) && !g.has(g.W_B_LARK)) {
            g.set(g.W_B_LARK);
            say_node(N_LARK);
        };
        if (g.NIGHT && !g.has(g.W_B_BELL)) {
            g.set(g.W_B_BELL);
            say_node(N_BELL);
        };
        if (g.NIGHT && g.has(g.W_ELDER_DEAD) && ent.E_ZONE[0] == Z_GRAVE) { raise_ghost(); };
        if (g.LOOP == 1 && g.DAY >= 3 && m >= 375 && !g.has(g.W_B_ASK)) {

            g.set(g.W_B_ASK);
            say_node(N_ASK);
        };
    } else if (g.NIGHT && !g.has(g.W_B_ENDING)) {

        g.set(g.W_B_ENDING);
        if (!g.has(g.F_TRUE_END)) {
            g.set(g.F_TRUE_END);
            say_node(N_TRUE);
        };
    };

    if (g.LOOP >= 2 && g.has(g.F_SEAL_EDIT) && !g.has(g.W_B_SEAL)) {
        g.set(g.W_B_SEAL);
        say_node(N_SEAL);
    };
    if (!g.has(g.W_SEEN_BOAR) && boss_near(ent.MT_BOAR)) {
        g.set(g.W_SEEN_BOAR);
        say_node(N_BOAR);
    };
    if (!g.has(g.W_SEEN_LEAK) && boss_near(ent.MT_LEAK)) {
        g.set(g.W_SEEN_LEAK);
        say_node(N_LEAK);
    };
    if (!g.has(g.W_SEEN_WARDEN) && boss_near(ent.MT_WARDEN)) {
        g.set(g.W_SEEN_WARDEN);
        say_node(N_WARDEN);
    };
    show(can_show);
}

let PT_ON = false;
let PT_X = 0;
let PT_Z = 0;
let WT_ON = false;
let WT_X = 0;
let WT_Z = 0;

let AIM_X = 0;
let AIM_Z = 0;

def aim(zone: long, tz: long, o: long) -> bool {
    if (o < 0) { return false; };
    if (zone == tz) {
        AIM_X = world.O_X[o] * 65536 + 32768;
        AIM_Z = world.O_Z[o] * 65536 + 32768;
        let dx = ent.E_X[0] - AIM_X;
        let dz = ent.E_Z[0] - AIM_Z;
        return fx.len2(dx >> 4, dz >> 4) >= 8192;
    };
    let d = world.door_to(zone, tz);
    if (d < 0) { d = world.door_to(zone, world.zone_id("square")); };
    if (d < 0) { return false; };
    AIM_X = world.O_X[d] * 65536 + 32768;
    AIM_Z = world.O_Z[d] * 65536 + 32768;
    true
}

def pointer_update(zone: long) -> void {
    PT_ON = false;
    WT_ON = false;
    if (!g.has(g.W_FIRE) || g.has(g.W_FIRE_OUT) || g.has(g.W_FIRE_LOST)) { return; };
    if (aim(zone, Z_FIELDS, O_FIRE)) {
        PT_ON = true;
        PT_X = AIM_X;
        PT_Z = AIM_Z;
    };
    if (!g.has(g.W_BUCKET) && aim(zone, Z_LAKE, O_SHORE)) {
        WT_ON = true;
        WT_X = AIM_X;
        WT_Z = AIM_Z;
    };
}

def draw_fire(zone: long, tick: long) -> void {
    if (zone != Z_FIELDS || O_FIRE < 0 || SPR_FIRE < 0) { return; };
    if (!g.has(g.W_FIRE) || g.has(g.W_FIRE_OUT) || g.has(g.W_FIRE_LOST)) { return; };

    let bx = world.O_X[O_FIRE] * 65536;
    let bz = world.O_Z[O_FIRE] * 65536;
    for i in 0..4 {
        let f = ((tick / 6) + i) & 1;
        sprite.draw(SPR_FIRE, f, bx + (i - 1) * 65536 - 12000, 0, bz + 4000, -1, 0);
    };
    sprite.draw(SPR_FIRE, (tick / 5) & 1, bx - 20000, 30000, bz + 4000, -1, 0);
    sprite.draw(SPR_FIRE, (tick / 7) & 1, bx + 40000, 30000, bz + 4000, -1, 0);
}

export {
    bind, say, say_node, show, tick, clear_queue, unnamed, realloc, night_gate,
    enter_zone, leave_zone, next_day, draw_fire, pointer_update, PT_ON, PT_X, PT_Z, WT_ON, WT_X, WT_Z, QN
};
