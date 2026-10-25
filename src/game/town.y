
import mem;
import world;
import ent;
import g;

def paint_all() -> void {
    for i in 0..world.NPAINT {
        let a = world.PT_ADDR[i] & 255;
        if (!mem.LIVE[a]) { continue; };
        mem.wb_clear();
        let k = world.PT_S[i];
        let e = world.PT_E[i];
        while (k < e) {
            let c = world.SRC[k];
            if (c == '[' && k + 3 < e && world.SRC[k + 3] == ']') {
                mem.wb_add(mem.rune(hexd(world.SRC[k + 1])));
                mem.wb_add(mem.rune(hexd(world.SRC[k + 2])));
                k += 4;
            } else {
                mem.wb_add(c);
                k += 1;
            };
        };
        if (mem.WB_N > mem.CAP[a]) { mem.WB_N = mem.CAP[a]; };
        mem.write(a);
    };
}

def hexd(c: long) -> long {
    if (c >= '0' && c <= '9') { return c - '0'; };
    if (c >= 'A' && c <= 'F') { return c - 'A' + 10; };
    if (c >= 'a' && c <= 'f') { return c - 'a' + 10; };
    0
}

def write_code(a: long) -> void {
    mem.wb_clear();
    for i in 0..mem.CODE_LEN { mem.wb_add(mem.CODE[i]); };
    mem.write(a);
}

def build() -> void {
    mem.reset();
    ent.clear_all();
    for a in 0..4 { mem.alloc_at(a, mem.T_CONST, a); };
    mem.alloc_at(mem.A_WATCHER, mem.T_WATCHER, 0);
    if (!g.HANDLESS) {
        mem.alloc_at(mem.A_HAND, mem.T_CODE, 0);
        write_code(mem.A_HAND);
    };
    mem.alloc_at(mem.A_WEIGHT, mem.T_GLOBAL, 0);
    mem.alloc_at(mem.A_BELL, mem.T_GLOBAL, 1);
    mem.alloc_at(mem.A_HOURS, mem.T_GLOBAL, 2);
    mem.alloc_at(mem.A_HP, mem.T_HUD, 0);
    mem.alloc_at(mem.A_MAP, mem.T_HUD, 1);
    mem.alloc_at(mem.A_DIALOG, mem.T_HUD, 2);

    mem.alloc_at(0x90, mem.T_SIGN, 0);
    mem.alloc_at(0x91, mem.T_SIGN, 1);
    mem.alloc_at(0x93, mem.T_SIGN, 3);
    mem.alloc_at(0x94, mem.T_SIGN, 4);
    mem.alloc_at(mem.A_BLADE, mem.T_BLADE, 0);
    mem.alloc_at(mem.A_SHOPSIGN, mem.T_SIGN, 5);
    mem.alloc_at(mem.A_STELE, mem.T_STELE, 0);
    for r in 0..4 {
        let a = mem.A_RULE1 + r;
        mem.alloc_at(a, mem.T_RULE, r);
    };
    for a in 0xA5..0xB0 { mem.alloc_at(a, mem.T_GRAVE, a - 0xA5); };
    mem.alloc_at(mem.A_LETTER, mem.T_LETTER, 0);
    paint_all();
    for r in 0..4 { mem.set_link(mem.A_RULE1 + r, mem.A_HAND); };

    let sq = world.zone_id("square");
    ent.place_player(sq, 16, 15);
    ent.E_SLOT[0] = mem.alloc_at(mem.A_PLAYER, mem.T_PLAYER, 0);
    mem.set_text(mem.A_PLAYER, "Peecy");
    for p in 1..world.NPEOPLE {
        let goal = world.spot_of(p, g.MIN);
        if (goal < 0) { continue; };
        ent.spawn_person(p, world.O_ZONE[goal], world.O_X[goal], world.O_Z[goal]);
    };
}

def bury(a: long, name: str) -> void {
    if (mem.LIVE[a]) { return; };
    mem.alloc_at(a, mem.T_GRAVE, 0);
    mem.set_text(a, name);
}

export { build, paint_all, write_code, bury };
