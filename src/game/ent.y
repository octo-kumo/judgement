
import mem;
import world;
import g;
import fx;
import r3d;
import sprite;
import pix;
import canvas;
import pxsprite;

const MAXE = 96;
const K_NONE = 0;
const K_PLAYER = 1;
const K_NPC = 2;
const K_MON = 3;
const K_VESSEL = 4;
const K_ITEM = 5;
const K_GHOST = 6;
const K_MEMORIAL = 7;

let E_KIND: [long; 96] = [0; 96];
let E_WHO: [long; 96] = [0; 96];
let E_ZONE: [long; 96] = [0; 96];
let E_X: [long; 96] = [0; 96];
let E_Z: [long; 96] = [0; 96];
let E_Y: [long; 96] = [0; 96];
let E_DIR: [long; 96] = [0; 96];
let E_WALK: [long; 96] = [0; 96];
let E_SLOT: [long; 96] = [-1; 96];
let E_ALIVE: [bool; 96] = [false; 96];
let E_HP: [long; 96] = [0; 96];
let E_HPMAX: [long; 96] = [0; 96];
let E_STATE: [long; 96] = [0; 96];
let E_T: [long; 96] = [0; 96];
let E_TX: [long; 96] = [0; 96];
let E_TZ: [long; 96] = [0; 96];
let E_GOAL: [long; 96] = [-1; 96];
let E_HOLD: [bool; 96] = [false; 96];
let E_TRANSIT: [long; 96] = [0; 96];
let E_TR_ZONE: [long; 96] = [0; 96];
let E_TR_X: [long; 96] = [0; 96];
let E_TR_Z: [long; 96] = [0; 96];
let E_SPR: [long; 96] = [-1; 96];
let E_FLASH: [long; 96] = [0; 96];
let E_CD: [long; 96] = [0; 96];
let E_SPAWN: [long; 96] = [-1; 96];
let E_PS: [long; 96] = [-1; 96];
let E_LW: [long; 96] = [0; 96];
let E_AN: [long; 96] = [0; 96];
let NE = 0;

const PLAYER = 0;
let PERSON_ENT: [long; 24] = [-1; 24];

const MT_MUDLING = 0;
const MT_CROW = 1;
const MT_HUSK = 2;
const MT_BOAR = 3;
const MT_WARDEN = 4;
const MT_LEAK = 5;
let MT_HP: [long; 6] = [6, 4, 12, 40, 50, 30];
let MT_ATK: [long; 6] = [2, 1, 3, 5, 6, 4];
let MT_SPEED: [long; 6] = [2200, 5200, 1700, 3000, 2600, 3200];
let MT_XP: [long; 6] = [3, 3, 6, 40, 60, 30];
let MT_COINS: [long; 6] = [1, 2, 2, 25, 30, 20];
let MT_SPR: [long; 6] = [-1; 6];
let MT_NAMES: [str; 6] = ["mudling", "rookcrow", "thornhusk", "Grey Boar", "Husk Warden", "the Leak"];

let SPR_EFFIGY = -1;
let SPR_ITEM = -1;
let SPR_GHOST = -1;

const IT_BOTTLE = 0;
const IT_NET = 1;
const IT_FISH = 2;
const IT_SCRAPER = 3;

let PERSON_SPR: [long; 24] = [-1; 24];
let PERSON_PS: [long; 24] = [-1; 24];
let MT_PS: [long; 6] = [-1; 6];
let PS_GHOST = -1;
let PS_EFFIGY = -1;
let PS_MARKER = -1;

def bind_sprites() -> void {
    for p in 0..world.NPEOPLE {
        PERSON_SPR[p] = sprite.id(world.SRC[world.P_SPR_S[p]:world.P_SPR_E[p]]);
    };
    MT_SPR[MT_MUDLING] = sprite.id("mudling");
    MT_SPR[MT_CROW] = sprite.id("crow");
    MT_SPR[MT_HUSK] = sprite.id("husk");
    MT_SPR[MT_BOAR] = sprite.id("boar");
    MT_SPR[MT_WARDEN] = sprite.id("warden");
    MT_SPR[MT_LEAK] = sprite.id("leak");
    SPR_EFFIGY = sprite.id("effigy");
    SPR_ITEM = sprite.id("item");
    SPR_GHOST = sprite.id("ghost");
    for p in 0..world.NPEOPLE {
        PERSON_PS[p] = pxsprite.id(world.SRC[world.P_SPR_S[p]:world.P_SPR_E[p]]);
    };
    MT_PS[MT_MUDLING] = pxsprite.id("mudling");
    MT_PS[MT_CROW] = pxsprite.id("crow");
    MT_PS[MT_HUSK] = pxsprite.id("husk");
    MT_PS[MT_BOAR] = pxsprite.id("boar");
    MT_PS[MT_WARDEN] = pxsprite.id("warden");
    MT_PS[MT_LEAK] = pxsprite.id("leak");
    PS_GHOST = pxsprite.id("ghost");
    PS_EFFIGY = pxsprite.id("effigy");
    PS_MARKER = pxsprite.id("marker");
}

def new_ent(kind: long, zone: long, x: long, z: long) -> long {
    let e = -1;
    for i in 1..MAXE {
        if (E_KIND[i] == K_NONE) {
            e = i;
            break;
        };
    };
    if (e < 0) { return -1; };
    if (e >= NE) { NE = e + 1; };
    E_KIND[e] = kind;
    E_ZONE[e] = zone;
    E_X[e] = x;
    E_Z[e] = z;
    E_Y[e] = 0;
    E_DIR[e] = 2;
    E_WALK[e] = 0;
    E_SLOT[e] = -1;
    E_ALIVE[e] = true;
    E_STATE[e] = 0;
    E_T[e] = 0;
    E_TX[e] = x;
    E_TZ[e] = z;
    E_GOAL[e] = -1;
    E_HOLD[e] = false;
    E_TRANSIT[e] = 0;
    E_FLASH[e] = 0;
    E_CD[e] = 0;
    E_SPAWN[e] = -1;
    E_PS[e] = -1;
    E_AN[e] = 0;
    E_LW[e] = 0;
    e
}

def remove(e: long) -> void {
    if (e <= 0 || e >= MAXE) { return; };
    if (E_SLOT[e] >= 0) {
        mem.free(E_SLOT[e]);
        E_SLOT[e] = -1;
    };
    if (E_KIND[e] == K_NPC && E_WHO[e] >= 0) { PERSON_ENT[E_WHO[e]] = -1; };
    E_KIND[e] = K_NONE;
    E_ALIVE[e] = false;
}

def clear_all() -> void {
    for e in 0..MAXE {
        E_KIND[e] = K_NONE;
        E_ALIVE[e] = false;
        E_SLOT[e] = -1;
    };
    for p in 0..24 { PERSON_ENT[p] = -1; };
    NE = 1;
}

def tag_of(kind: long) -> long {
    if (kind == K_PLAYER) { return mem.T_PLAYER; };
    if (kind == K_NPC) { return mem.T_NPC; };
    if (kind == K_MON) { return mem.T_MONSTER; };
    if (kind == K_VESSEL) { return mem.T_VESSEL; };
    mem.T_ITEM
}

def name_it(e: long) -> long {
    if (E_SLOT[e] >= 0) { return E_SLOT[e]; };
    let k = E_KIND[e];
    let a = -1;
    if (k == K_PLAYER || k == K_NPC || k == K_VESSEL) {
        a = mem.alloc(0x60, 0x7F, tag_of(k), e);
    } else if (k == K_MON) {
        a = mem.alloc(mem.R_MON_LO, mem.R_MON_HI, mem.T_MONSTER, e);
    } else {
        a = mem.alloc(mem.R_ITEMS_LO, mem.R_ITEMS_HI, mem.T_ITEM, e);
    };
    E_SLOT[e] = a;
    if (a >= 0) { write_name(e, a); };
    a
}

def write_name(e: long, a: long) -> void {
    let k = E_KIND[e];
    if (k == K_PLAYER) {
        mem.set_text(a, "Peecy");
    } else if (k == K_NPC) {
        mem.set_text(a, world.P_NAME[E_WHO[e]]);
    } else if (k == K_MON) {
        mem.set_text(a, MT_NAMES[E_WHO[e]]);
    } else if (k == K_VESSEL) {
        mem.set_text(a, "vessel");
    } else {
        mem.set_text(a, "a thing");
    };
}

def unname(e: long) -> void {
    if (E_SLOT[e] >= 0) {
        mem.free(E_SLOT[e]);
        E_SLOT[e] = -1;
    };
}

def spawn_person(p: long, zone: long, tx: long, tz: long) -> long {
    let e = new_ent(K_NPC, zone, tx * 65536 + 32768, tz * 65536 + 32768);
    if (e < 0) { return -1; };
    E_WHO[e] = p;
    E_SPR[e] = PERSON_SPR[p];
    E_PS[e] = PERSON_PS[p];
    PERSON_ENT[p] = e;
    name_it(e);
    e
}

def spawn_monster(t: long, zone: long, tx: long, tz: long) -> long {
    let e = new_ent(K_MON, zone, tx * 65536 + 32768, tz * 65536 + 32768);
    if (e < 0) { return -1; };
    E_WHO[e] = t;
    E_SPR[e] = MT_SPR[t];
    E_PS[e] = MT_PS[t];
    E_HP[e] = MT_HP[t];
    E_HPMAX[e] = MT_HP[t];
    name_it(e);
    e
}

def spawn_vessel(zone: long, x: long, z: long) -> long {
    let e = new_ent(K_VESSEL, zone, x, z);
    if (e < 0) { return -1; };
    E_WHO[e] = 0;
    E_SPR[e] = SPR_EFFIGY;
    E_PS[e] = PS_EFFIGY;
    name_it(e);
    e
}

def spawn_item(t: long, zone: long, x: long, z: long) -> long {
    let e = new_ent(K_ITEM, zone, x, z);
    if (e < 0) { return -1; };
    E_WHO[e] = t;
    E_SPR[e] = SPR_ITEM;
    name_it(e);
    e
}

def place_player(zone: long, tx: long, tz: long) -> void {
    E_KIND[0] = K_PLAYER;
    E_ZONE[0] = zone;
    E_X[0] = tx * 65536 + 32768;
    E_Z[0] = tz * 65536 + 32768;
    E_Y[0] = 0;
    E_ALIVE[0] = true;
    E_DIR[0] = 2;
    E_TRANSIT[0] = 0;
    E_SPR[0] = PERSON_SPR[0];
    E_PS[0] = PERSON_PS[0];
    E_FLASH[0] = 0;
    if (NE < 1) { NE = 1; };
}

def by_slot(a: long) -> long {
    if (a < 0 || a >= 256 || !mem.LIVE[a]) { return -1; };
    let t = mem.TAG[a];
    if (t == mem.T_PLAYER || t == mem.T_NPC || t == mem.T_MONSTER || t == mem.T_VESSEL || t == mem.T_ITEM) {
        let e = mem.REF[a];
        if (e >= 0 && e < MAXE && E_SLOT[e] == a) { return e; };
    };
    -1
}

let STEP_X = 0;
let STEP_Z = 0;
def screen_dir(dx: long, dy: long) -> void {

    STEP_X = dx + dy;
    STEP_Z = dy - dx;
}

def dir_of(sx: long, sz: long) -> long {
    if (sx == 0 && sz == 0) { return -1; };
    (fx.atan2(sz, sx) + 64) / 128 & 7
}

def try_move(e: long, dx: long, dz: long) -> bool {
    let z = E_ZONE[e];
    let moved = false;
    if (dx != 0 && free_for(e, z, E_X[e] + dx, E_Z[e])) {
        E_X[e] += dx;
        moved = true;
    };
    if (dz != 0 && free_for(e, z, E_X[e], E_Z[e] + dz)) {
        E_Z[e] += dz;
        moved = true;
    };
    if (moved) { E_WALK[e] += 1; };
    moved
}

let NOCLIP = false;

const CROWD = 36000;
def crowded(e: long, x: long, z: long) -> bool {
    let lim = (CROWD >> 4) * (CROWD >> 4);
    for o in 0..NE {
        if (o == e || !E_ALIVE[o] || E_ZONE[o] != E_ZONE[e] || E_TRANSIT[o] > 0) { continue; };
        if (E_KIND[o] != K_NPC && o != 0) { continue; };
        let dx = (x - E_X[o]) >> 4;
        let dz = (z - E_Z[o]) >> 4;
        let d2 = dx * dx + dz * dz;
        if (d2 >= lim) { continue; };
        let cx = (E_X[e] - E_X[o]) >> 4;
        let cz = (E_Z[e] - E_Z[o]) >> 4;
        if (d2 < cx * cx + cz * cz) { return true; };
    };
    false
}

def free_for(e: long, zone: long, x: long, z: long) -> bool {
    if (NOCLIP && e == 0) { return true; };
    if (E_KIND[e] == K_MON && world.tile(zone, x >> 16, z >> 16) == 'P') { return false; };
    if (E_KIND[e] == K_NPC && crowded(e, x, z)) { return false; };
    world.free_at(zone, x, z)
}

def occupied(zone: long, x: long, z: long, skip: long) -> bool {
    let lim = (CROWD >> 4) * (CROWD >> 4);
    for o in 0..NE {
        if (o == skip || !E_ALIVE[o] || E_ZONE[o] != zone || E_TRANSIT[o] > 0) { continue; };
        if (E_KIND[o] != K_NPC && o != 0) { continue; };
        let dx = (x - E_X[o]) >> 4;
        let dz = (z - E_Z[o]) >> 4;
        if (dx * dx + dz * dz < lim) { return true; };
    };
    false
}

def spread_from(c: long) -> void {
    let lim = 52000 >> 4;
    for o in 1..NE {
        if (o == c || E_KIND[o] != K_NPC || !E_ALIVE[o] || E_ZONE[o] != E_ZONE[c] || E_TRANSIT[o] > 0) { continue; };
        let dx = (E_X[o] - E_X[c]) >> 4;
        let dz = (E_Z[o] - E_Z[c]) >> 4;
        if (dx * dx + dz * dz >= lim * lim) { continue; };
        let done = false;
        for ring in 1..4 {
            if (done) { break; };
            for k in 0..8 {
                if (done) { break; };
                let ox = if (k == 0 || k == 4 || k == 5) { 1 } else if (k == 1 || k == 6 || k == 7) { -1 } else { 0 };
                let oz = if (k == 2 || k == 4 || k == 6) { 1 } else if (k == 3 || k == 5 || k == 7) { -1 } else { 0 };
                let nx = E_X[c] + ox * ring * 49152;
                let nz = E_Z[c] + oz * ring * 49152;
                if (!world.free_at(E_ZONE[o], nx, nz) || world.door_at(E_ZONE[o], nx >> 16, nz >> 16) >= 0) { continue; };
                if (occupied(E_ZONE[o], nx, nz, o)) { continue; };
                E_X[o] = nx;
                E_Z[o] = nz;
                done = true;
            };
        };
    };
}

def walk_to(e: long, tx: long, tz: long, speed: long) -> bool {
    let dx = tx - E_X[e];
    let dz = tz - E_Z[e];

    let qx = dx >> 4;
    let qz = dz >> 4;
    let qs = (speed >> 4) + 1;
    let arrived = qx * qx + qz * qz <= qs * qs;
    let d = if (arrived) { 0 } else { fx.len2(qx, qz) << 4 };
    if (arrived || d <= speed) {
        if (free_for(e, E_ZONE[e], tx, tz)) {
            E_X[e] = tx;
            E_Z[e] = tz;
        };
        return true;
    };
    let sx = dx * speed / d;
    let sz = dz * speed / d;
    let dir = dir_of(sx, sz);
    if (dir >= 0) { E_DIR[e] = dir; };
    if (!try_move(e, sx, sz)) {

        if (E_KIND[e] == K_NPC && d < 98304 && crowded(e, E_X[e] + sx, E_Z[e] + sz)) {
            E_T[e] = 0;
            return true;
        };

        E_T[e] += 1;
        if (E_T[e] > 45) {
            E_T[e] = 0;
            return true;
        };
        try_move(e, sz / 2, 0 - sx / 2);
    };
    false
}

def dist(a: long, b: long) -> long {
    if (E_ZONE[a] != E_ZONE[b]) { return 1 << 40; };
    let dx = (E_X[a] - E_X[b]) >> 4;
    let dz = (E_Z[a] - E_Z[b]) >> 4;
    fx.len2(dx, dz) << 4
}

def person_think(e: long) -> void {
    if (E_HOLD[e] || E_TRANSIT[e] > 0) { return; };
    let p = E_WHO[e];
    let goal = world.spot_of(p, g.MIN);
    if (goal < 0) { return; };
    E_GOAL[e] = goal;
    let gz = world.O_ZONE[goal];
    let here = E_ZONE[e];
    let tx = 0;
    let tz = 0;
    if (gz == here) {
        tx = world.O_X[goal] * 65536 + 32768;
        tz = world.O_Z[goal] * 65536 + 32768;
    } else {
        let d = world.door_to(here, gz);
        if (d < 0) { d = world.door_to(here, world.zone_id("square")); };
        if (d < 0) { return; };
        tx = world.O_X[d] * 65536 + 32768;
        tz = world.O_Z[d] * 65536 + 32768;
    };
    if (walk_to(e, tx, tz, 2600)) {

        let d = world.door_at(here, E_X[e] >> 16, E_Z[e] >> 16);
        if (d >= 0 && gz != here) { enter_door(e, d, 60); };
    };
}

def enter_door(e: long, d: long, ticks: long) -> void {
    unname(e);
    E_TRANSIT[e] = ticks;
    E_TR_ZONE[e] = world.O_ARG[d];
    E_TR_X[e] = world.O_W[d] * 65536 + 32768;
    E_TR_Z[e] = world.O_H[d] * 65536 + 32768;
}

def transit_tick(e: long) -> void {
    E_TRANSIT[e] -= 1;
    if (E_TRANSIT[e] > 0) { return; };
    E_ZONE[e] = E_TR_ZONE[e];
    E_X[e] = E_TR_X[e];
    E_Z[e] = E_TR_Z[e];

    name_it(e);
    spread_from(e);
}

const PLAYER_ZONE_CHANGED = false;

def update_people() -> void {
    for e in 1..NE {
        if (E_KIND[e] != K_NPC || !E_ALIVE[e]) { continue; };
        if (E_TRANSIT[e] > 0) {
            transit_tick(e);
            continue;
        };
        person_think(e);
    };
}

let E_SCR_X: [long; 96] = [-99; 96];
let E_SCR_Y: [long; 96] = [-99; 96];
let E_SCR_W: [long; 96] = [0; 96];
let E_SCR_H: [long; 96] = [0; 96];

def px_frame(e: long, tick: long, swing: bool) -> long {
    let s = E_PS[e];
    if (pxsprite.is_actor(s)) {
        if (swing && e == 0) { return 5; };
        if (E_WALK[e] != E_LW[e]) {
            E_LW[e] = E_WALK[e];
            E_AN[e] = 8;
        } else if (E_AN[e] > 0) {
            E_AN[e] -= 1;
        };
        if (E_AN[e] > 0) { return (E_WALK[e] / 4) & 3; };
        return if (((tick + e * 11) / 26) % 2 == 1) { 4 } else { 0 };
    };
    (tick / 9 + e) & 1
}

def px_view(e: long) -> long {
    let d = E_DIR[e] & 7;
    if (pxsprite.is_actor(E_PS[e])) { return pxsprite.VIEW_OF[d]; };
    0
}

def px_mirror(e: long) -> bool {
    let d = E_DIR[e] & 7;
    pxsprite.MIRROR_OF[d]
}

def face(e: long, f: long) -> void {
    let d = dir_of(E_X[f] - E_X[e], E_Z[f] - E_Z[e]);
    if (d >= 0) { E_DIR[e] = d; };
}

def draw_px(zone: long, tick: long, swing: bool, target: long) -> void {
    for e in 0..NE {
        if (E_KIND[e] == K_NONE || !E_ALIVE[e] || E_ZONE[e] != zone || E_TRANSIT[e] > 0) { continue; };
        if (E_PS[e] < 0) { continue; };
        let lift = E_Y[e];
        if (world.FLOAT) { lift += 40000 + (fx.sin(world.TIME * 4 + e * 83) >> 3); };
        let rec = -1;
        if (E_FLASH[e] > 0) {
            rec = if ((E_FLASH[e] & 2) != 0) { 0xffffff } else { 0xff5040 };
        };
        pxsprite.HALO = if (e == target) { 90 + (fx.sin(tick * 9) >> 11) } else { 0 };
        pxsprite.draw(E_PS[e], px_view(e), px_frame(e, tick, swing), px_mirror(e), E_X[e], lift, E_Z[e], rec);
        pxsprite.HALO = 0;
        E_SCR_X[e] = pxsprite.LAST_X;
        E_SCR_Y[e] = pxsprite.LAST_Y;
        E_SCR_W[e] = pxsprite.LAST_W;
        E_SCR_H[e] = pxsprite.LAST_H;
    };
}

def draw(zone: long, tick: long) -> void {
    for e in 0..NE {
        if (E_KIND[e] == K_NONE || !E_ALIVE[e] || E_ZONE[e] != zone || E_TRANSIT[e] > 0) { continue; };
        if (E_PS[e] >= 0) { continue; };
        let s = E_SPR[e];
        if (s < 0) { continue; };
        let fr = if (E_KIND[e] == K_MON) { (tick / 8) & 1 } else { (E_WALK[e] / 6) & 1 };
        let rec = -1;
        if (E_FLASH[e] > 0) {
            rec = if ((E_FLASH[e] & 2) != 0) { 0xffffff } else { 0xff5040 };
        };
        let lift = E_Y[e];
        if (world.FLOAT) { lift += 40000 + (fx.sin(world.TIME * 4 + e * 83) >> 3); };
        sprite.draw(s, fr, E_X[e], lift, E_Z[e], rec, 0);
        E_SCR_X[e] = sprite.LAST_X;
        E_SCR_Y[e] = sprite.LAST_Y;
        E_SCR_W[e] = sprite.LAST_W;
        E_SCR_H[e] = sprite.LAST_H;
    };
}

def at_cell(zone: long, cx: long, cy: long) -> long {
    let best = -1;
    let k = NE - 1;
    while (k >= 0) {
        let e = k;
        k -= 1;
        if (E_KIND[e] == K_NONE || !E_ALIVE[e] || E_ZONE[e] != zone || E_TRANSIT[e] > 0) { continue; };
        if (cx >= E_SCR_X[e] && cx < E_SCR_X[e] + E_SCR_W[e] && cy >= E_SCR_Y[e] && cy < E_SCR_Y[e] + E_SCR_H[e]) {
            best = e;
            break;
        };
    };
    best
}

export {
    new_ent, remove, clear_all, name_it, unname, spawn_person, spawn_monster,
    spawn_vessel, spawn_item, place_player, by_slot, screen_dir, try_move,
    walk_to, dist, dir_of, enter_door, update_people, draw, draw_px, face, px_view, px_mirror, px_frame, at_cell,
    bind_sprites, transit_tick, write_name, free_for,
    E_KIND, E_WHO, E_ZONE, E_X, E_Z, E_Y, E_DIR, E_WALK, E_SLOT, E_ALIVE, E_HP,
    E_HPMAX, E_STATE, E_T, E_TX, E_TZ, E_GOAL, E_HOLD, E_TRANSIT, E_SPR,
    E_FLASH, E_CD, E_SPAWN, E_PS, PS_GHOST, E_TR_ZONE, E_TR_X, E_TR_Z, NE, MAXE, PERSON_ENT, PERSON_SPR, STEP_X, STEP_Z,
    E_SCR_X, E_SCR_Y, E_SCR_W, E_SCR_H, NOCLIP,
    K_NONE, K_PLAYER, K_NPC, K_MON, K_VESSEL, K_ITEM, K_GHOST, K_MEMORIAL, PS_MARKER,
    MT_MUDLING, MT_CROW, MT_HUSK, MT_BOAR, MT_WARDEN, MT_LEAK, MT_HP,
    MT_ATK, MT_SPEED, MT_XP, MT_COINS, MT_SPR, MT_NAMES, SPR_EFFIGY, SPR_ITEM,
    SPR_GHOST, IT_BOTTLE, IT_NET, IT_FISH, IT_SCRAPER
};
