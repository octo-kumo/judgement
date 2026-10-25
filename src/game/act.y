
import ent;
import world;
import mem;
import text;
import style;
import fx;

let T_ENT = -1;
let T_OBJ = -1;
const REACH = 98304;
let USABLE: [bool; 512] = [true; 512];
let TALKS: [bool; 24] = [true; 24];

def find_target(zone: long) -> void {
    T_ENT = -1;
    T_OBJ = -1;
    let best = REACH;
    let px = ent.E_X[0];
    let pz = ent.E_Z[0];
    for e in 1..ent.NE {
        let k = ent.E_KIND[e];
        if (k == ent.K_NONE || !ent.E_ALIVE[e] || ent.E_ZONE[e] != zone || ent.E_TRANSIT[e] > 0) { continue; };
        if (k != ent.K_NPC && k != ent.K_ITEM && k != ent.K_VESSEL && k != ent.K_GHOST && k != ent.K_MEMORIAL) { continue; };
        if (k == ent.K_NPC && !TALKS[ent.E_WHO[e]]) { continue; };
        let d = fx.len2((ent.E_X[e] - px) >> 4, (ent.E_Z[e] - pz) >> 4) << 4;
        if (d < best) {
            best = d;
            T_ENT = e;
        };
    };

    if (T_ENT > 0) { best = best - 40000; };
    for o in 0..world.NO {
        if (world.O_ZONE[o] != zone || world.O_KIND[o] != world.OK_THING || !USABLE[o]) { continue; };
        let ox = world.O_X[o] * 65536 + 32768;
        let oz = world.O_Z[o] * 65536 + 32768;
        let d = fx.len2((ox - px) >> 4, (oz - pz) >> 4) << 4;
        if (world.THING_MESH[o] >= 0) {

            let nx = fx.max(world.TH_X0[o], fx.min(px, world.TH_X1[o]));
            let nz = fx.max(world.TH_Z0[o], fx.min(pz, world.TH_Z1[o]));
            let dr = fx.len2((nx - px) >> 4, (nz - pz) >> 4) << 4;

            if (d >= REACH && dr < REACH) { d = REACH - 2000 + (dr >> 6); };
        };
        if (d < best) {
            best = d;
            T_OBJ = o;
            T_ENT = -1;
        };
    };
}

def stage_slot(a: long, n: long, show_empty: bool) -> void {
    text.x_clear();
    for i in 0..n {
        let b = mem.byte_at(a, i);
        if (mem.is_rune(b)) {
            text.x_add(style.RUNE[mem.rune_val(b)]);
        } else if (b >= 32 && b < 127) {
            text.x_add(b);
        } else if (show_empty) {
            text.x_add(0x00B7);
        };
    };
}

def stage_text(a: long) -> void {
    stage_slot(a, mem.text_len(a), false);
}

def stage_scrape(a: long, extra: long) -> void {
    text.x_clear();
    let n = mem.CAP[a] + 2 + extra;
    for i in 0..n {
        if (i == mem.CAP[a]) { text.x_add(0x2502); };
        let b = mem.byte_at(a, i);
        if (mem.is_rune(b)) {
            text.x_add(style.RUNE[mem.rune_val(b)]);
        } else if (b >= 32 && b < 127) {
            text.x_add(b);
        } else {
            text.x_add(0x00B7);
        };
    };
}

export { find_target, stage_slot, stage_text, stage_scrape, T_ENT, T_OBJ, REACH, USABLE, TALKS };
