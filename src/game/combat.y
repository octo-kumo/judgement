
import ent;
import world;
import g;
import mem;
import fx;
import sfx;

let SWING_T = 0;
let SWING_CD = 0;
let DODGE_T = 0;
let DODGE_CD = 0;
let HURT_T = 0;
let JUDGE_CD = 0;
const JUDGE_COOLDOWN = 1800;
let SEAL = -1;
const SEAL_AUTO = true;
let LEVEL_FLASH = 0;

def spawn_kind(o: long) -> long {
    if (world.obj_is(o, "mudling")) { return ent.MT_MUDLING; };
    if (world.obj_is(o, "crow")) { return ent.MT_CROW; };
    if (world.obj_is(o, "husk")) { return ent.MT_HUSK; };
    if (world.obj_is(o, "boar")) { return ent.MT_BOAR; };
    if (world.obj_is(o, "warden")) { return ent.MT_WARDEN; };
    if (world.obj_is(o, "leak")) { return ent.MT_LEAK; };
    -1
}

def enter_zone(zone: long) -> void {
    for o in 0..world.NO {
        if (world.O_ZONE[o] != zone || world.O_KIND[o] != world.OK_SPAWN) { continue; };
        let t = spawn_kind(o);
        if (t < 0) { continue; };
        if (t == ent.MT_WARDEN && (!g.NIGHT || g.has(g.W_WARDEN))) { continue; };
        if (t != ent.MT_WARDEN && g.NIGHT) { continue; };
        if (t == ent.MT_BOAR && g.has(g.W_BOAR)) { continue; };

        if (t == ent.MT_LEAK && (g.LOOP < 2 || g.has(g.W_LEAK))) { continue; };
        let e = ent.spawn_monster(t, zone, world.O_X[o], world.O_Z[o]);
        if (e >= 0) { ent.E_SPAWN[e] = o; };
    };
}

def leave_zone(zone: long) -> void {
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_MON && ent.E_ZONE[e] == zone) { ent.remove(e); };
    };
}

def boar_tick(e: long, d: long) -> bool {
    let st = ent.E_STATE[e];
    if (st > 0) {
        ent.E_STATE[e] = st - 1;
        if (st > 20) {
            ent.E_FLASH[e] = 3;
            if (st == 21) {
                let dx = ent.E_X[0] - ent.E_X[e];
                let dz = ent.E_Z[0] - ent.E_Z[e];
                let l = fx.len2(dx >> 4, dz >> 4) << 4;
                if (l < 1) { l = 1; };
                let sp = ent.MT_SPEED[ent.MT_BOAR] * 3;
                ent.E_TX[e] = dx * sp / l;
                ent.E_TZ[e] = dz * sp / l;
            };
            return true;
        };
        let dir = ent.dir_of(ent.E_TX[e], ent.E_TZ[e]);
        if (dir >= 0) { ent.E_DIR[e] = dir; };
        let moved = ent.try_move(e, ent.E_TX[e], ent.E_TZ[e]);
        if (d < 55000 && ent.E_CD[e] == 0) {
            ent.E_CD[e] = 40;
            hurt_player(ent.MT_ATK[ent.MT_BOAR] + 2);
            ent.E_STATE[e] = 0;
        };
        if (!moved) { ent.E_STATE[e] = 0; };
        return true;
    };
    if (ent.E_GOAL[e] < 0) { ent.E_GOAL[e] = 0; };
    ent.E_GOAL[e] += 1;
    if (ent.E_GOAL[e] >= 150 && d < 8 * 65536 && d > 2 * 65536) {
        ent.E_GOAL[e] = 0;
        ent.E_STATE[e] = 32;
    };
    false
}

def warden_tick(e: long, d: long) -> void {
    if (ent.E_GOAL[e] < 0) { ent.E_GOAL[e] = 0; };
    ent.E_GOAL[e] += 1;
    if (ent.E_GOAL[e] < 240 || d > 10 * 65536) { return; };
    ent.E_GOAL[e] = 0;
    let n = 0;
    for k in 1..ent.NE {
        if (ent.E_KIND[k] == ent.K_MON && ent.E_WHO[k] == ent.MT_HUSK && ent.E_ZONE[k] == ent.E_ZONE[e]) { n += 1; };
    };
    if (n < 2) { ent.spawn_monster(ent.MT_HUSK, ent.E_ZONE[e], (ent.E_X[e] >> 16) + 1, (ent.E_Z[e] >> 16) + 1); };
}

def leak_tick(e: long) -> bool {
    let best = -1;
    let bd = 9 * 65536;
    for k in 1..ent.NE {
        if (ent.E_KIND[k] != ent.K_ITEM || ent.E_ZONE[k] != ent.E_ZONE[e]) { continue; };
        let dd = ent.dist(e, k);
        if (dd < bd) {
            bd = dd;
            best = k;
        };
    };
    if (best < 0) { return false; };
    if (bd < 45000) {
        ent.remove(best);
        ent.E_STATE[e] += 1;
        return true;
    };
    ent.walk_to(e, ent.E_X[best], ent.E_Z[best], ent.MT_SPEED[ent.MT_LEAK]);
    true
}

def monster_tick(e: long) -> void {
    let t = ent.E_WHO[e];
    if (ent.E_FLASH[e] > 0) { ent.E_FLASH[e] -= 1; };
    if (ent.E_CD[e] > 0) { ent.E_CD[e] -= 1; };
    let d = ent.dist(e, 0);
    let sp = ent.MT_SPEED[t];
    if (t == ent.MT_LEAK && leak_tick(e)) { return; };
    if (d < 10 * 65536 && ent.E_SLOT[0] >= 0) {
        if (t == ent.MT_BOAR && boar_tick(e, d)) { return; };
        if (t == ent.MT_WARDEN) { warden_tick(e, d); };
    };
    if (d < 6 * 65536 && ent.E_SLOT[0] >= 0) {
        if (d > 45000) {
            ent.walk_to(e, ent.E_X[0], ent.E_Z[0], sp);
        } else if (ent.E_CD[e] == 0) {
            ent.E_CD[e] = 40;
            hurt_player(ent.MT_ATK[t]);
        };
    } else {

        if (ent.E_T[e] <= 0) {
            ent.E_TX[e] = ent.E_X[e] + (fx.rnd(5) - 2) * 32768;
            ent.E_TZ[e] = ent.E_Z[e] + (fx.rnd(5) - 2) * 32768;
            ent.E_T[e] = 60 + fx.rnd(60);
        };
        ent.E_T[e] -= 1;
        ent.walk_to(e, ent.E_TX[e], ent.E_TZ[e], sp / 2);
    };
}

def hurt_player(n: long) -> void {
    if (DODGE_T > 0 || HURT_T > 0) { return; };
    g.HP -= n;
    HURT_T = 20;
    ent.E_FLASH[0] = 8;
    sfx.play(sfx.HURT, 0);
}

def tick() -> void {
    if (SWING_T > 0) { SWING_T -= 1; };
    if (SWING_CD > 0) { SWING_CD -= 1; };
    if (DODGE_T > 0) { DODGE_T -= 1; };
    if (DODGE_CD > 0) { DODGE_CD -= 1; };
    if (HURT_T > 0) { HURT_T -= 1; };
    if (JUDGE_CD > 0) { JUDGE_CD -= 1; };
    if (LEVEL_FLASH > 0) { LEVEL_FLASH -= 1; };
    if (ent.E_FLASH[0] > 0 && HURT_T == 0) { ent.E_FLASH[0] = 0; };
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_MON && ent.E_ALIVE[e] && ent.E_ZONE[e] == ent.E_ZONE[0]) { monster_tick(e); };
    };
    if (SEAL_AUTO) { SEAL = nearest_beast_addr(); };
}

def nearest_beast() -> long {
    let best = -1;
    let bd = 8 * 65536;
    for e in 1..ent.NE {
        if (ent.E_KIND[e] != ent.K_MON || !ent.E_ALIVE[e] || ent.E_ZONE[e] != ent.E_ZONE[0]) { continue; };
        let d = ent.dist(e, 0);
        if (d < bd) {
            bd = d;
            best = e;
        };
    };
    best
}

def nearest_beast_addr() -> long {
    let e = nearest_beast();
    if (e < 0) { -1 } else { ent.E_SLOT[e] }
}

let KILLED: [long; 16] = [0; 16];
let NKILLED = 0;
def swing() -> long {
    NKILLED = 0;
    if (SWING_CD > 0) { return 0; };
    SWING_T = 8;
    SWING_CD = 14;
    sfx.play(sfx.SWING, 0);
    for e in 1..ent.NE {
        if (ent.E_KIND[e] != ent.K_MON || !ent.E_ALIVE[e] || ent.E_ZONE[e] != ent.E_ZONE[0]) { continue; };
        if (ent.dist(e, 0) > 90000) { continue; };
        ent.E_HP[e] -= g.ATK;
        ent.E_FLASH[e] = 8;
        sfx.play(sfx.HIT, 0);

        let dx = (ent.E_X[e] - ent.E_X[0]) / 3;
        let dz = (ent.E_Z[e] - ent.E_Z[0]) / 3;
        ent.try_move(e, dx, dz);
        if (ent.E_HP[e] <= 0 && NKILLED < 16) {
            KILLED[NKILLED] = e;
            NKILLED += 1;
        };
    };
    NKILLED
}

def dodge(dx: long, dz: long) -> void {
    if (DODGE_CD > 0) { return; };
    DODGE_T = 10;
    DODGE_CD = 30;
    for i in 0..6 { ent.try_move(0, dx * 6000, dz * 6000); };
}

def gain_xp(n: long) -> void {
    g.XP += n;
    while (g.XP >= g.LEVEL * 10 && g.LEVEL < 255) {
        g.XP -= g.LEVEL * 10;
        g.LEVEL += 1;
        g.HP_MAX += 2;
        g.HP = g.HP_MAX;
        g.ATK += 1;
        sfx.play(sfx.PICKUP, 0);
        if (g.LEVEL == 255) {
            LEVEL_FLASH = 2;
            g.set(g.F_LEVEL_WRAP);
        };
    };
}

def judge_ready() -> bool { JUDGE_CD == 0 }

def judge() -> bool {
    if (JUDGE_CD > 0 || SEAL < 0) { return false; };
    JUDGE_CD = JUDGE_COOLDOWN;
    true
}

def reset() -> void {
    SWING_T = 0;
    DODGE_T = 0;
    HURT_T = 0;
    JUDGE_CD = 0;
    SEAL = -1;
}

export {
    enter_zone, leave_zone, tick, swing, dodge, gain_xp, judge, judge_ready,
    nearest_beast, hurt_player, reset, KILLED, NKILLED, SEAL, SEAL_AUTO,
    JUDGE_CD, JUDGE_COOLDOWN, SWING_T, DODGE_T, LEVEL_FLASH
};
