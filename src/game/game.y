
import vault;
import term;
import input;
import canvas;
import style;
import text;
import ui;
import fx;
import pix;
import r3d;
import sprite;
import pxsprite;
import sfx;
import clock;
import mem;
import g;
import world;
import ent;
import dlg;
import act;
import town;
import book;
import rules;
import vfx;
import combat;
import save;
import story;
import hints;
import field;
import title;
import path;
import help;
import guard;
import logo;

embed PACK from "../../build/data.pack";

let RUNNING = true;

const M_PLAY = 0;
const M_STRUCK = 1;
const M_CASCADE = 2;
const M_VOID = 3;
const M_WAKE = 4;
const M_CARD = 5;
const M_TITLE = 6;
const M_ASK = 8;
let ASK_PREV = 0;
const HIT_ASK_YES = 8200;
const HIT_ASK_NO = 8201;
let ASK_SEL = 0;
let ASK_STAGE = 0;
const M_WITNESS = 7;
let TITLE_PREV = 0;
let MODE = 0;
let MODE_T = 0;
let STRUCK_BOLT = -1;
let TOAST_T = 0;
let TOAST_ID = 0;
let TOAST_A = 0;
let GONE: [bool; 24] = [false; 24];
let PERSON_NODE: [long; 24] = [-1; 24];

def SPECIAL_THING(o: long) -> bool {
    world.obj_is(o, "painter") || world.obj_is(o, "desk") || world.obj_is(o, "book") ||
    world.obj_is(o, "stele") || world.obj_is(o, "shop") || world.obj_is(o, "effigies") ||
    world.obj_is(o, "bench") || world.obj_is(o, "bed") || world.obj_is(o, "elder_grave")
}
let THING_NODE: [long; 512] = [-1; 512];
let ZONE = 0;
let TICK = 0;
let NYAN_T = 0;
let BANNER_T = 23;
let BANNER_ON = false;
let FAST_T = 0;
let NYAN_I = 0;
let PS_NYAN = -1;
let NYAN_COLS: [long; 6] = [0xff2a2a, 0xff9a2a, 0xffe82a, 0x2aff4a, 0x2a8aff, 0x8a4aff];
let MOVE_T = 0;
let MOVE_DX = 0;
let MOVE_DY = 0;
let CLICK_GO = false;
let CLICK_X = 0;
let CLICK_Z = 0;
let PATH_I = 0;
let REPLANS = 0;
const HIT_MINIMAP = 8300;
let MM_X0 = 0;
let MM_W = 1;
let CAM_X = 0;
let CAM_Z = 0;
const SPEED = 7800;
let TALK_TO = -1;
let START_OVER_WAIT = false;

def part(i: long) -> str {
    let t = vault.get(i);
    if (t == none) { guard.tamper(); };
    t!
}

def load_all() -> void {
    if (!vault.open(PACK)) { guard.tamper(); };
    style.init();
    style.use_set(g.RUNE_MODE);
    fx.init();
    r3d.load(part(0));
    sprite.load(part(1));
    pxsprite.load(part(2));
    g.init_names();
    world.load(part(3));
    world.bind_meshes();
    world.bind_things();
    ent.bind_sprites();
    mem.layout();
    dlg.load(part(4));
    bind_events();
    story.bind();
    bind_music();
    PS_NYAN = pxsprite.id("nyan");
    hints.bind();
    help.bind();

    for p in 0..world.NPEOPLE {
        PERSON_NODE[p] = dlg.node_id(world.SRC[world.P_ID_S[p]:world.P_ID_E[p]]);
        act.TALKS[p] = PERSON_NODE[p] >= 0;
    };
    for o in 0..world.NO {
        THING_NODE[o] = -1;
        if (world.O_KIND[o] == world.OK_THING) {
            THING_NODE[o] = dlg.node_id("thing." + world.SRC[world.O_NS[o]:world.O_NE[o]]);
        };
        act.USABLE[o] = THING_NODE[o] >= 0 || SPECIAL_THING(o);
    };

    term.dont_dump(ptr_addr(&mem.ARENA[0]), mem.ARENA_N);
    term.dont_dump(ptr_addr(world.SRC), len(world.SRC));
}

def build_world() -> void {
    town.build();
    ZONE = ent.E_ZONE[0];
    snap_camera();
}

def snap_camera() -> void {
    CAM_X = ent.E_X[0];
    CAM_Z = ent.E_Z[0];
}

def nyan_key(k: long) -> void {
    let want = if (NYAN_I == 0) { 'n' } else if (NYAN_I == 1) { 'y' } else if (NYAN_I == 2) { 'a' } else { 'n' };
    let c = if (k >= 'A' && k <= 'Z') { k + 32 } else { k };
    if (c == want) {
        NYAN_I += 1;
        if (NYAN_I == 4) {
            NYAN_I = 0;
            NYAN_T = 420;
        };
    } else {
        NYAN_I = if (c == 'n') { 1 } else { 0 };
    };
}

def draw_nyan() -> void {
    if (NYAN_T <= 0) { return; };
    let span = canvas.W + 40;
    let age = 420 - NYAN_T;
    let cx = age * span / 420 - 20;
    let wob = fx.sin(age * 14) >> 14;
    let cy = canvas.H / 3 + wob / 2;

    for x in 0..(cx - 5) {
        let k = cx - 5 - x;
        if (x < 0 || x >= canvas.W || k > 70) { continue; };
        let w2 = fx.sin((x + age) * 40) >> 15;
        for band in 0..6 {
            let py = (cy - 1) * 2 + band + w2 + (if (wob > 0) { 0 } else { 0 });
            let col = NYAN_COLS[band];
            let cell = py / 2;
            if (!canvas.inside(x, cell)) { continue; };
            if ((py & 1) == 0) {
                canvas.put(x, cell, 0x2580, col, canvas.KEEP, 0);
            } else {
                canvas.put(x, cell, 0x2584, col, canvas.KEEP, 0);
            };
        };
    };
    pxsprite.cells_at(PS_NYAN, 0, (age / 6) & 1, false, cx, (cy + 3) * 2);
}

def handle_key(k: long) -> void {
    if (k == input.K_CTRL_C) {
        RUNNING = false;
        return;
    };
    if (MODE == M_ASK) {

        if (k == 'y' || k == 'Y') { ask_answer(true); return; };
        if (k == 'n' || k == 'N') { ask_answer(false); return; };
        if (k == input.K_LEFT || k == input.K_RIGHT || k == 'a' || k == 'd' || k == input.K_TAB) { ASK_SEL = 1 - ASK_SEL; return; };
        if (k == input.K_ENTER || k == ' ') { ask_answer(ASK_SEL == 0); };
        return;
    };
    if (MODE == M_TITLE) {
        title.key(k);
        settle_title();
        return;
    };
    if (help.OPEN) {
        help.key(k);
        return;
    };
    if (field.OPEN) {
        field.key(k);
        settle_field();
        return;
    };
    if (book.OPEN) {
        book.key(k);
        return;
    };
    if (dlg.OPEN) {
        dlg.key(k);
        return;
    };
    nyan_key(k);
    if ((k == 'b' || k == 'B') && g.has(g.F_BOOK_LENT)) {
        book.open_book();
        return;
    };
    if (k == 'q') {
        RUNNING = false;
        return;
    };
    if (k == 'e' || k == 'E' || k == input.K_ENTER) {
        interact();
        return;
    };
    if (MODE == M_VOID && k == input.K_ESC) {
        dlg.start("void.menu", -1);
        return;
    };
    if ((MODE == M_PLAY || MODE == M_VOID) && (k == 'h' || k == 'H')) {
        help.open();
        return;
    };
    if (MODE != M_PLAY && MODE != M_VOID) { return; };
    let walk_key = k == input.K_UP || k == 'w' || k == 'W' || k == input.K_DOWN || k == 's' || k == 'S' || k == input.K_LEFT || k == 'a' || k == 'A' || k == input.K_RIGHT || k == 'd' || k == 'D';
    if (MODE == M_VOID && !walk_key) { return; };

    if ((k == 'k' || k == 'K') && g.has(g.F_SEAL_EDIT) && g.LOOP >= 2) {
        field.open_seal(combat.SEAL);
        return;
    };
    if ((k == 'f' || k == 'F') && MODE == M_PLAY) {

        FAST_T = 16;
        return;
    };
    if (k == ' ') {
        combat.swing();
        return;
    };
    if (k == 'c' || k == 'C') {
        ent.screen_dir(0, 0);
        let d = ent.E_DIR[0];
        combat.dodge(fx.cos(d * 128) >> 16, fx.sin(d * 128) >> 16);
        return;
    };
    if (k == 'j' || k == 'J') {
        cast_judgment();
        return;
    };
    let dx = 0;
    let dy = 0;
    if (k == input.K_UP || k == 'w' || k == 'W') { dy = -1; };
    if (k == input.K_DOWN || k == 's' || k == 'S') { dy = 1; };
    if (k == input.K_LEFT || k == 'a' || k == 'A') { dx = -1; };
    if (k == input.K_RIGHT || k == 'd' || k == 'D') { dx = 1; };
    if (dx != 0 || dy != 0) {
        MOVE_DX = dx;
        MOVE_DY = dy;
        MOVE_T = 9;
        CLICK_GO = false;
        return;
    };

    toast(7, 0);
}

let GX = 0;
let GZ = 0;
def ground_at(cx: long, cy: long) -> void {
    let px = cx * 16 + 8 - r3d.CXP * 16;
    let py = (cy * 2 + 1) * 16 - r3d.CYP * 16;

    let u = (px << 16) / (r3d.SCALE * 16);
    let sy = (py << 16) / (r3d.SCALE * 16);
    let v = (sy << 16) / r3d.SINP;
    let dx = (((u + v) / 2) << 16) / r3d.C45;
    let dz = (((v - u) / 2) << 16) / r3d.C45;
    GX = r3d.CAM_X + dx;
    GZ = r3d.CAM_Z + dz;
}

def handle_mouse() -> void {
    let mx = input.EV_X - canvas.OX;
    let my = input.EV_Y - canvas.OY;
    if (input.EV_KEY == input.M_MOVE || input.EV_KEY == input.M_DRAG) {
        let id = ui.hover(mx, my);
        dlg.hover(id);
        return;
    };
    if (field.OPEN && (input.EV_KEY == input.M_WHEEL_UP || input.EV_KEY == input.M_WHEEL_DOWN)) {
        field.wheel(input.EV_KEY == input.M_WHEEL_DOWN);
        return;
    };
    if (book.OPEN && (input.EV_KEY == input.M_WHEEL_UP || input.EV_KEY == input.M_WHEEL_DOWN)) {
        book.wheel(input.EV_KEY == input.M_WHEEL_DOWN);
        return;
    };
    if (input.EV_KEY == input.M_PRESS && input.EV_BTN == 2 && MODE == M_PLAY && !field.OPEN && !dlg.OPEN && !book.OPEN && !help.OPEN) {
        let e = ent.at_cell(ZONE, mx, my);
        if (e > 0 && ent.E_KIND[e] == ent.K_MON && combat.SEAL_AUTO) { combat.SEAL = ent.E_SLOT[e]; };
        cast_judgment();
        return;
    };
    if (input.EV_KEY != input.M_PRESS || input.EV_BTN != 0) { return; };
    if (help.OPEN) {
        help.close();
        return;
    };
    if (MODE == M_ASK) {
        let id = ui.hit(mx, my);
        if (id == HIT_ASK_YES) { ask_answer(true); };
        if (id == HIT_ASK_NO) { ask_answer(false); };
        return;
    };
    if (MODE == M_TITLE) {
        title.click(ui.hit(mx, my));
        settle_title();
        return;
    };
    if (field.OPEN) {
        field.click(ui.hit(mx, my));
        settle_field();
        return;
    };
    if (book.OPEN) {
        book.click(ui.hit(mx, my));
        return;
    };
    if (dlg.OPEN) {
        dlg.click(ui.hit(mx, my));
        return;
    };
    let who = ent.at_cell(ZONE, mx, my);
    if (who > 0) {
        TALK_TO = who;
        start_walk(ent.E_X[who], ent.E_Z[who]);
        return;
    };
    TALK_TO = -1;

    if (ui.hit(mx, my) == HIT_MINIMAP && MM_W > 0) {
        let tx = (mx - MM_X0) * world.Z_W[ZONE] / MM_W;
        let tz = (my - 1) * 2;
        start_walk(tx * 65536 + 32768, tz * 65536 + 32768);
        return;
    };
    ground_at(mx, my);
    start_walk(GX, GZ);
}

def start_walk(gx: long, gz: long) -> void {

    let tx = gx >> 16;
    let tz = gz >> 16;
    let w = world.Z_W[ZONE];
    let h = world.Z_H[ZONE];
    if (tx < 0 || tz < 0 || tx >= w || tz >= h) {
        let cx = fx.max(0, fx.min(tx, w - 1));
        let cz = fx.max(0, fx.min(tz, h - 1));
        let d = world.nearest_door(ZONE, cx, cz, 7);
        if (d >= 0) {
            gx = world.O_X[d] * 65536 + 32768;
            gz = world.O_Z[d] * 65536 + 32768;
        } else {
            gx = cx * 65536 + 32768;
            gz = cz * 65536 + 32768;
        };
    } else {
        let d = world.stairs_door(ZONE, tx, tz);
        if (d >= 0) {
            gx = world.O_X[d] * 65536 + 32768;
            gz = world.O_Z[d] * 65536 + 32768;
        };
    };
    CLICK_X = gx;
    CLICK_Z = gz;
    PATH_I = 0;
    CLICK_GO = path.plan(ZONE, ent.E_X[0], ent.E_Z[0], gx, gz) > 0;
}

def poll_input() -> void {
    input.poll();
    while (input.next()) {
        if (input.EV_TYPE == input.KEY) {
            handle_key(input.EV_KEY);
        } else if (input.EV_TYPE == input.MOUSE) {
            handle_mouse();
        } else if (input.EV_TYPE == input.RESIZE) {
            relayout();
        };
    };
}

def relayout() -> void {
    canvas.fit();
    pix.resize();
    r3d.set_view();
}

def toast(id: long, a: long) -> void {
    TOAST_ID = id;
    TOAST_A = a;
    TOAST_T = 150;
}

def set_mode(m: long) -> void {
    MODE = m;
    MODE_T = 0;
}

def resolve_strike(addr: long, by_bell: bool) -> void {
    let a = addr & 255;
    if (a < 0x10) {
        toast(2, a);
        if (!g.has(g.W_B_HEAVEN)) {
            g.set(g.W_B_HEAVEN);
            story.say("beat.heaven");
        };
        return;
    };
    sfx.play(sfx.CRACK, 0);
    if (!mem.LIVE[a]) {

        vfx.add(canvas.W / 2 + fx.rnd(9) - 4, canvas.H / 2, 12, a);
        return;
    };
    let t = mem.TAG[a];
    let e = ent.by_slot(a);

    if (e > 0 && by_bell && MODE == M_PLAY && ent.E_KIND[e] == ent.K_NPC && ent.E_ZONE[e] != ZONE && !g.has(g.F_FISHER_DIED)) {
        ZONE = ent.E_ZONE[e];
        CAM_X = ent.E_X[e];
        CAM_Z = ent.E_Z[e];
        dlg.close();
        book.close();
        MOVE_T = 0;
        CLICK_GO = false;
        set_mode(M_WITNESS);
    };
    if (e >= 0 && ent.E_ZONE[e] == ZONE) {
        let b = vfx.strike_world(ent.E_X[e], ent.E_Y[e], ent.E_Z[e], a);
        if (e == 0) { STRUCK_BOLT = b; };
    } else if (e < 0) {
        vfx.add(canvas.W / 2, canvas.H / 3, 12, a);
    };
    if (t == mem.T_PLAYER) {
        mem.free(a);
        ent.E_SLOT[0] = -1;
        player_struck();
        return;
    };
    if (t == mem.T_CODE && a == mem.A_HAND) {
        mem.free(a);
        g.HAND_FREED = true;
        start_cascade();
        return;
    };
    if (e > 0) {
        strike_entity(e);
        return;
    };
    mem.free(a);
    if (t == mem.T_HUD) {
        if (!g.has(g.F_HUD_STRUCK)) { story.say("beat.hud"); };
        g.set(g.F_HUD_STRUCK);
        g.set(g.F_SEAL_EDIT);
    };
    if (a == mem.A_WEIGHT) {
        g.set(g.F_GRAVITY);
        g.set(g.W_WEIGHT_GONE);
        story.say("beat.weight");
    };
    if (a == mem.A_BELL) { g.set(g.W_BELL_GONE); };
    if (a == mem.A_STELE) { g.set(g.W_RULES_GONE); };
}

def strike_entity(e: long) -> void {
    let k = ent.E_KIND[e];
    if (k == ent.K_NPC) {
        let p = ent.E_WHO[e];
        GONE[p] = true;
        story_person_gone(p);
    };
    if (k == ent.K_MON) { monster_died(e, false); };

    let p = if (k == ent.K_NPC) { ent.E_WHO[e] } else { -1 };
    let zone = ent.E_ZONE[e];
    let x = ent.E_X[e];
    let z = ent.E_Z[e];
    ent.remove(e);
    if (p >= 0) {
        let m = ent.new_ent(ent.K_MEMORIAL, zone, x, z);
        if (m >= 0) {
            ent.E_WHO[m] = p;
            ent.E_SPR[m] = -1;
            ent.E_PS[m] = ent.PS_MARKER;
        };
    };
}

def player_struck() -> void {
    set_mode(M_STRUCK);
    g.set(g.F_STRUCK_ONCE);
    MOVE_T = 0;
    CLICK_GO = false;
    dlg.close();
    book.close();
    sfx.play(sfx.SWELL, 0);
    if (STRUCK_BOLT >= 0) { vfx.hold(STRUCK_BOLT, true); };
}

def ring_bell() -> void {
    g.NIGHT = true;
    sfx.play(sfx.DRONE_ON, 0);
    if (!mem.LIVE[mem.A_BELL]) { return; };
    sfx.play(sfx.BELL, 0);
    toast(3, 0);
    rules.bell();
}

def new_loop() -> void {
    story.clear_queue();
    hints.reset();
    g.DAY = 1;
    g.MIN = 360;
    g.SUB = 0;
    g.NIGHT = false;
    g.clear_world();
    g.HP = g.HP_MAX;
    g.EFFIGIES = 0;
    rules.clear();
    vfx.clear();
    combat.reset();
    for p in 0..24 { GONE[p] = false; };
    town.build();
    wake_in_bed();
}

def wake_in_bed() -> void {
    let inn = world.zone_id("loft");
    ent.unname(0);
    ZONE = inn;
    ent.E_ZONE[0] = inn;
    ent.E_X[0] = 4 * 65536 + 32768;
    ent.E_Z[0] = 8 * 65536 + 32768;
    ent.E_ALIVE[0] = true;
    if (ent.E_SLOT[0] < 0) { ent.name_it(0); };
    snap_camera();
    set_mode(M_WAKE);
    save.write();
}

def next_day() -> void {
    story.next_day();
    g.DAY += 1;
    g.MIN = 360;
    g.SUB = 0;
    g.NIGHT = false;
    g.FLAG[g.W_RITE_DONE_TODAY] = false;
    for e in 1..ent.NE {
        let k = ent.E_KIND[e];
        if (k == ent.K_MON || k == ent.K_VESSEL || k == ent.K_ITEM) {
            ent.remove(e);
            continue;
        };
        if (k == ent.K_NPC && ent.E_ALIVE[e]) {
            let goal = world.spot_of(ent.E_WHO[e], g.MIN);
            if (goal >= 0) {
                if (ent.E_TRANSIT[e] > 0) {
                    ent.E_TRANSIT[e] = 0;
                    ent.name_it(e);
                };
                ent.E_ZONE[e] = world.O_ZONE[goal];
                ent.E_X[e] = world.O_X[goal] * 65536 + 32768;
                ent.E_Z[e] = world.O_Z[goal] * 65536 + 32768;
            };
        };
    };
    wake_in_bed();
}

def process_events() -> void {
    let n = g.EQ_N;
    g.EQ_N = 0;
    for i in 0..n {
        let k = g.EQ_K[i];
        if (k == g.EV_STRIKE) { resolve_strike(g.EQ_A[i], g.EQ_B[i] == 1); };
        if (k == g.EV_TOAST) {
            toast(g.EQ_A[i], g.EQ_B[i]);
            if (g.EQ_A[i] == 1) { story.realloc(); };
        };
        if (k == g.EV_SCRIPT) { script_event(g.EQ_A[i]); };
    };

    if (START_OVER_WAIT && !dlg.OPEN) {
        START_OVER_WAIT = false;
        rules.record(4, player_addr());
    };
}

def mode_tick() -> void {
    MODE_T += 1;
    if (MODE == M_STRUCK) {

        ent.E_FLASH[0] = if (MODE_T < 45) { MODE_T } else { 0 };
        if (MODE_T == 150) {
            vfx.clear();
            STRUCK_BOLT = -1;
            if (g.HAND_FREED) {

                g.HAND_FREED = false;
                g.HANDLESS = true;
                leave_void();
            };
            g.LOOP += 1;
            new_loop();
        };
        return;
    };
    if (MODE == M_WITNESS) {

        if (MODE_T >= 120) {
            ZONE = ent.E_ZONE[0];
            snap_camera();
            vfx.clear();
            set_mode(M_PLAY);
        };
        return;
    };
    if (MODE == M_WAKE) {
        if (MODE_T == 1 && g.DAY == 1) { wake_line(); };
        if (MODE_T >= 45) { set_mode(M_PLAY); };
        return;
    };
    if (MODE == M_CASCADE) {
        cascade_tick();
        return;
    };
    if (MODE == M_VOID) {
        void_tick();
        return;
    };
    if (MODE == M_CARD) {
        dlg.tick();
        if (!dlg.OPEN && MODE_T > 20) { new_loop(); };
        return;
    };
}

let EVT_TAKE_WATER = -1;
let EVT_FOUL_LAKE = -1;
let EVT_FISH = -1;
let EVT_START_OVER = -1;
let EVT_SLEEP = -1;
let EVT_LEND_BOOK = -1;
let EVT_EFFIGY = -1;
let EVT_LET_GO = -1;
let EVT_VOID_MENU = -1;
let EVT_FIRE_OUT = -1;
let EVT_WAIT_HOUR = -1;
let EVT_SCRAPE = -1;
const PAINT_N = 11;
let PAINT_EV: [long; 11] = [-1; 11];
let PAINT_AT: [long; 11] = [0x90, 0x91, 0x93, 0x94, 0x9E, 0x9F, 0xA1, 0xA2, 0xA3, 0xA4, 0x60];
let LAST_USED = -1;

def bind_events() -> void {
    EVT_TAKE_WATER = dlg.event_id("take_water");
    EVT_FOUL_LAKE = dlg.event_id("foul_lake");
    EVT_FISH = dlg.event_id("fish");
    EVT_START_OVER = dlg.event_id("start_over");
    EVT_SLEEP = dlg.event_id("sleep");
    EVT_LEND_BOOK = dlg.event_id("lend_book");
    EVT_EFFIGY = dlg.event_id("effigy");
    EVT_LET_GO = dlg.event_id("let_go");
    EVT_VOID_MENU = dlg.event_id("void_menu");
    EVT_FIRE_OUT = dlg.event_id("fire_out");
    EVT_WAIT_HOUR = dlg.event_id("wait_hour");
    EVT_SCRAPE = dlg.event_id("scrape");
    PAINT_EV[0] = dlg.event_id("paint_90");
    PAINT_EV[1] = dlg.event_id("paint_91");
    PAINT_EV[2] = dlg.event_id("paint_93");
    PAINT_EV[3] = dlg.event_id("paint_94");
    PAINT_EV[4] = dlg.event_id("paint_9E");
    PAINT_EV[5] = dlg.event_id("paint_9F");
    PAINT_EV[6] = dlg.event_id("paint_A1");
    PAINT_EV[7] = dlg.event_id("paint_A2");
    PAINT_EV[8] = dlg.event_id("paint_A3");
    PAINT_EV[9] = dlg.event_id("paint_A4");
    PAINT_EV[10] = dlg.event_id("paint_60");
}

def player_addr() -> long { ent.E_SLOT[0] }

def script_event(id: long) -> void {
    if (id == EVT_TAKE_WATER) {
        g.set(g.W_BUCKET);
        sfx.play(sfx.SPLASH, 0);
        rules.record(2, player_addr());
    };
    if (id == EVT_FISH) {
        g.set(g.W_FISH_TAKEN);
        rules.record(2, player_addr());
    };
    if (id == EVT_FOUL_LAKE) {
        sfx.play(sfx.SPLASH, 0);
        rules.record(1, player_addr());
    };
    if (id == EVT_START_OVER) { START_OVER_WAIT = true; };
    if (id == EVT_SLEEP) {
        if (g.NIGHT) { next_day(); } else { toast(4, 0); };
    };
    if (id == EVT_LEND_BOOK) { g.set(g.F_BOOK_LENT); };
    if (id == EVT_LET_GO) { let_go(); };
    for i in 0..PAINT_N {
        if (id == PAINT_EV[i]) { open_brush(PAINT_AT[i]); };
    };
    if (id == EVT_SCRAPE && LAST_USED >= 0) {

        act.stage_scrape(world.O_ARG[LAST_USED], 6);
        dlg.restart_line();
    };
    if (id == EVT_FIRE_OUT) {

        g.set(g.W_FIRE_OUT);
        g.FLAG[g.W_BUCKET] = false;
        sfx.play(sfx.SPLASH, 0);
    };
    if (id == EVT_WAIT_HOUR) {

        if (g.MIN < g.BELL_MIN) {
            g.MIN += 60;
            if (g.MIN > g.BELL_MIN) { g.MIN = g.BELL_MIN; };
            g.SUB = 0;
        };
    };
    if (id == EVT_EFFIGY) {
        if (g.EFFIGIES < (if (g.has(g.F_SATCHEL)) { 5 } else { 3 })) {
            g.EFFIGIES += 1;
            sfx.play(sfx.PICKUP, 0);
        };
    };
}

def open_brush(addr: long) -> void {
    if (addr == mem.A_BLADE) {
        field.open_board(addr, 1, "{gold}Edi's brush: your blade{/}", "The blade's name is a board like any other.", false);
    } else if (addr == mem.A_PLAYER) {
        field.open_board(addr, 1, "{gold}Edi's brush: your name{/}", "A name is a board too.", false);
    } else {
        field.open_board(addr, 1, "{gold}Edi's brush{/}", "A coin a letter. Past the board's edge, the paint runs on.", false);
    };
}

def settle_field() -> void {
    if (field.RESULT == 0) { return; };
    let done = field.RESULT == 1;
    field.close();
    if (!done) { return; };
    if (field.KIND == field.K_SEAL) {
        combat.SEAL = field.value();
        cast_judgment();
        return;
    };

    mem.wb_clear();
    for i in 0..field.N { mem.wb_add(field.BUF[i]); };
    let t = field.TARGET;
    mem.write(t);
    g.COINS -= field.cost();
    sfx.play(sfx.PICKUP, 0);

    if (t == mem.A_BLADE && field.N > mem.CAP[t] + 2) { g.set(g.W_BLADE_RENAMED); };
}

def story_person_gone(p: long) -> void {
    if (p == world.person_id("rax")) {
        g.set(g.W_BRAM_GONE);
        if (ZONE == ent.E_ZONE[ent.PERSON_ENT[p]]) { g.set(g.F_FISHER_DIED); };
    };
    if (p == world.person_id("bus")) {
        g.set(g.W_LARK_GONE);
        g.set(g.F_BOTCHED);
    };
}

def monster_died(e: long, judged: bool) -> void {
    let t = ent.E_WHO[e];
    combat.gain_xp(ent.MT_XP[t]);
    g.COINS += ent.MT_COINS[t];
    sfx.play(sfx.PICKUP, 0);
    if (t == ent.MT_BOAR) {
        g.set(g.W_BOAR);
        g.set(g.F_BOAR);
    };
    if (t == ent.MT_WARDEN) {
        g.set(g.W_WARDEN);
        g.set(g.F_WARDEN);
    };
    if (t == ent.MT_LEAK) {
        g.set(g.W_LEAK);
        g.set(g.F_LEAK_BEAT);
        g.set(g.F_SATCHEL);
        story.say("beat.satchel");
    };
}

def cast_judgment() -> void {
    if (!combat.judge()) {
        if (!combat.judge_ready()) { toast(6, 0); };
        return;
    };
    resolve_strike(combat.SEAL, false);
}

def combat_tick() -> void {
    combat.tick();
    for i in 0..combat.NKILLED {
        let e = combat.KILLED[i];
        if (ent.E_KIND[e] == ent.K_MON) {
            monster_died(e, false);
            ent.remove(e);
        };
    };
    combat.NKILLED = 0;
    if (g.HP <= 0 && MODE == M_PLAY) {
        g.HP = 0;
        player_struck();
    };
}

def wake_line() -> void { dlg.start("wake", -1); }

const CASCADE_LEN = 600;
const VOID_LINE_AT = 5400;
let VOID_SAID = 0;

def start_cascade() -> void {
    set_mode(M_CASCADE);
    dlg.close();
    book.close();
    MOVE_T = 0;
    CLICK_GO = false;
    sfx.play(sfx.CASCADE, 0);
}

def cascade_tick() -> void {

    let rate = 2 + MODE_T * 24 / CASCADE_LEN;
    for i in 0..rate {
        if (fx.rnd(8) != 0) { continue; };
        if (vfx.NB > 0 && fx.rnd(2) == 0) {
            let j = fx.rnd(vfx.NB);
            vfx.add(vfx.B_X[j] + fx.rnd(7) - 3, vfx.B_Y[j] + fx.rnd(3) - 1, 20, -1);
        } else {
            vfx.add(fx.rnd(canvas.W), fx.rnd(canvas.H), 20, -1);
        };
    };
    if (MODE_T % 20 == 0) { sfx.play(sfx.CRACK, 0); };
    if (MODE_T >= CASCADE_LEN) {
        enter_void();
    };
}

def enter_void() -> void {
    g.set(g.F_VOID_SEEN);
    set_mode(M_VOID);
    vfx.clear();
    vfx.ash_init();
    ent.NOCLIP = true;
    sfx.play(sfx.DRONE_ON, 1);
    VOID_SAID = 0;
    g.CLOCK_RUN = false;
    save.write();
}

def leave_void() -> void {
    ent.NOCLIP = false;
    vfx.ASH_ON = false;
    g.CLOCK_RUN = true;
    sfx.play(sfx.DRONE_ON, 0);
}

def let_go() -> void {
    save.delete_save();
    g.RETRIES = save.read_retries();
    for f in 0..g.NFLAG { g.FLAG[f] = false; };
    g.HAND_FREED = false;
    g.HANDLESS = false;
    g.VOID_LAUNCHES = 0;
    g.LOOP = 1;
    g.LEVEL = 1;
    g.XP = 0;
    g.HP_MAX = 20;
    g.ATK = 3;
    g.COINS = 0;
    leave_void();
    dlg.close();
    vfx.clear();

    set_mode(M_CARD);
    dlg.start("ending.retry", -1);
}

def void_tick() -> void {
    if (dlg.OPEN) { return; };
    if (MODE_T >= VOID_LINE_AT * (VOID_SAID + 1)) {
        VOID_SAID += 1;

        dlg.start("void.line", -1);
        rules.record(4, player_addr());
    };
}

def interact() -> void {
    if (push_vessel()) { return; };
    act.find_target(ZONE);
    if (act.T_ENT > 0) {
        talk_to(act.T_ENT);
        return;
    };
    if (act.T_OBJ >= 0) {
        use_thing(act.T_OBJ);
        return;
    };
    if (near_water()) { dlg.start("lake", -1); };
}

def near_water() -> bool {
    let tx = ent.E_X[0] >> 16;
    let tz = ent.E_Z[0] >> 16;
    for dz in -1..2 {
        for dx in -1..2 {
            if (world.is_water(ZONE, tx + dx, tz + dz)) { return true; };
        };
    };
    false
}

def talk_to(e: long) -> void {
    if (ent.E_KIND[e] == ent.K_NPC) {
        let n = PERSON_NODE[ent.E_WHO[e]];
        ent.E_HOLD[e] = true;
        ent.face(e, 0);
        ent.face(0, e);
        let h = hints.talk_hint(ent.E_WHO[e]);
        if (h >= 0) { n = h; };
        if (ent.E_WHO[e] == world.person_id("deepseek")) { hints.update_advice(); };
        if (n < 0 || !dlg.start_node(n, e)) { ent.E_HOLD[e] = false; };
    } else if (ent.E_KIND[e] == ent.K_GHOST) {
        dlg.start("ghost", e);
    } else if (ent.E_KIND[e] == ent.K_MEMORIAL) {
        text.VAR_S[1] = world.P_NAME[ent.E_WHO[e]];
        dlg.start("memorial", e);
    };
}

def use_thing(o: long) -> void {
    let a = world.O_ARG[o];
    LAST_USED = o;
    if (world.obj_is(o, "desk")) {
        field.open_board(mem.A_LETTER, 0, "{gold}The Letter{/}", "One sheet of paper. Whatever you write stays on it.", true);
        return;
    };
    if (world.obj_is(o, "sign") || world.obj_is(o, "plaque") || world.obj_is(o, "rhyme") || world.obj_is(o, "grave")) {
        act.stage_text(a);
    };
    if (world.obj_is(o, "book")) {
        book.open_book();
        return;
    };
    if (world.obj_is(o, "effigies")) {
        script_event(EVT_EFFIGY);
        return;
    };
    if (world.obj_is(o, "bed")) {
        script_event(EVT_SLEEP);
        return;
    };
    if (THING_NODE[o] >= 0) { dlg.start_node(THING_NODE[o], -1); };
}

def player_tick() -> void {
    let moved = false;
    if (MOVE_T > 0) {
        MOVE_T -= 1;
        ent.screen_dir(MOVE_DX, MOVE_DY);
        let sx = ent.STEP_X;
        let sz = ent.STEP_Z;
        let len = if (sx != 0 && sz != 0) { 46341 } else { 65536 };
        let mx = sx * SPEED * len >> 16;
        let mz = sz * SPEED * len >> 16;

        if ((sx == 0) != (sz == 0)) {
            mx = sx * SPEED;
            mz = sz * SPEED;
        };
        let d = ent.dir_of(sx, sz);
        if (d >= 0) { ent.E_DIR[0] = d; };
        moved = ent.try_move(0, mx, mz);
    } else if (CLICK_GO) {
        let wx = path.PX[PATH_I];
        let wz = path.PZ[PATH_I];
        if (ent.walk_to(0, wx, wz, SPEED)) {
            let ex = ent.E_X[0] - wx;
            let ez = ent.E_Z[0] - wz;
            if (ex > -20000 && ex < 20000 && ez > -20000 && ez < 20000) {
                PATH_I += 1;
                if (PATH_I >= path.N) { CLICK_GO = false; };
            } else if (REPLANS < 3) {

                REPLANS += 1;
                let tries = REPLANS;
                start_walk(CLICK_X, CLICK_Z);
                REPLANS = tries;
            } else {
                CLICK_GO = false;
            };
        };
        moved = true;
    };
    stair_lift();
    if (moved) { check_door(); };
}

let Z_INN = -2;
let Z_LOFT = -2;
def stair_lift() -> void {
    if (Z_INN == -2) {
        Z_INN = world.zone_id("inn");
        Z_LOFT = world.zone_id("loft");
    };
    let lift = 0;
    let tx = ent.E_X[0] >> 16;
    let tz = ent.E_Z[0] >> 16;
    if ((ZONE == Z_INN || ZONE == Z_LOFT) && tx >= 9 && tx <= 10 && tz >= 4 && tz <= 8) {

        let zu = ((ent.E_Z[0] - 6 * 65536 - 32768) * 16) >> 16;
        if (ZONE == Z_INN) {
            lift = (40 - zu) * 20 / 80;
        } else {
            lift = 0 - (zu + 40) * 20 / 80;
        };
        lift = lift * 4096;
    };
    ent.E_Y[0] = lift;
}

def check_door() -> void {
    let d = world.door_at(ZONE, ent.E_X[0] >> 16, ent.E_Z[0] >> 16);
    if (d < 0) { return; };
    go_through(d);
}

def go_through(d: long) -> void {
    let dest = world.O_ARG[d];
    if (dest < 0) { return; };

    if (world.O_ROT[d] == 1 && g.NIGHT) {
        g.set(g.W_GATE_NIGHT);
        rules.record(3, ent.E_SLOT[0]);
        story.night_gate();
    };
    combat.leave_zone(ZONE);
    story.leave_zone(ZONE);
    ent.unname(0);
    ZONE = dest;
    ent.E_ZONE[0] = dest;
    ent.E_X[0] = world.O_W[d] * 65536 + 32768;
    ent.E_Z[0] = world.O_H[d] * 65536 + 32768;
    ent.name_it(0);
    ent.spread_from(0);
    stair_lift();
    MOVE_T = 0;
    CLICK_GO = false;
    snap_camera();
    sfx.play(sfx.STEP, 0);
    combat.enter_zone(ZONE);
    story.enter_zone(ZONE);
}

def clock_tick() -> void {
    if (!g.CLOCK_RUN) { return; };

    if (g.has(g.W_BELL_GONE) && !g.NIGHT && g.MIN >= g.BELL_MIN - 1) {
        g.MIN = g.BELL_MIN - 1;
        g.SUB = 0;
        return;
    };

    g.SUB += if (FAST_T > 0) { 30 } else { 1 };
    while (g.SUB >= 30) {
        g.SUB -= 30;
        g.MIN += 1;
        bell_pulse();
        if (g.has(g.W_BELL_GONE) && !g.NIGHT && g.MIN >= g.BELL_MIN - 1) {
            g.MIN = g.BELL_MIN - 1;
            g.SUB = 0;
        };
    };
    if (FAST_T == 0 && g.SUB == 15 && bell_secs() >= 0 && bell_secs() <= 5) { sfx.play(sfx.HEART, 0); };
}

let MUSIC_NOW = -1;
let ZONE_MUSIC: [long; 16] = [1; 16];

def bind_music() -> void {
    for z in 0..world.NZ { ZONE_MUSIC[z] = 1; };
    let inn = world.zone_id("inn");
    let loft = world.zone_id("loft");
    let shop = world.zone_id("shop");
    let elder = world.zone_id("elder");
    if (inn >= 0) { ZONE_MUSIC[inn] = 4; };
    if (loft >= 0) { ZONE_MUSIC[loft] = 4; };
    if (shop >= 0) { ZONE_MUSIC[shop] = 4; };
    if (elder >= 0) { ZONE_MUSIC[elder] = 4; };
    ZONE_MUSIC[world.zone_id("shrine")] = 5;
    ZONE_MUSIC[world.zone_id("lake")] = 6;
    ZONE_MUSIC[world.zone_id("fields")] = 7;
    ZONE_MUSIC[world.zone_id("wood")] = 8;
    ZONE_MUSIC[world.zone_id("graveyard")] = 9;
}

def in_combat() -> bool {
    if (ent.E_SLOT[0] < 0) { return false; };
    for e in 1..ent.NE {
        if (ent.E_KIND[e] == ent.K_MON && ent.E_ALIVE[e] && ent.E_ZONE[e] == ent.E_ZONE[0] && ent.dist(e, 0) < 6 * 65536) { return true; };
    };
    false
}

def music_track() -> long {
    if (MODE == M_VOID) { return 10; };
    if (MODE == M_STRUCK || MODE == M_CASCADE || MODE == M_CARD) { return 0; };
    if (MODE == M_ASK) { return 0; };
    if (MODE == M_TITLE) { return 4; };
    if (NYAN_T > 0) { return 14; };
    if (g.HANDLESS) { return 3; };
    if (MODE == M_PLAY && in_combat()) { return 11; };
    let secs = bell_secs();
    if (secs >= 0 && secs <= 180) { return 12; };
    if (g.has(g.W_FIRE) && !g.has(g.W_FIRE_OUT) && !g.has(g.W_FIRE_LOST)) { return 12; };
    let t = ZONE_MUSIC[ZONE];
    if (g.NIGHT) { return if (t == 9) { 9 } else { 2 }; };
    if (t == 1 && g.LOOP >= 2) { return 13; };
    t
}

def music_tick() -> void {
    let t = music_track();
    if (t != MUSIC_NOW) {
        MUSIC_NOW = t;
        sfx.play(sfx.MUSIC, t);
    };
}

def update() -> void {
    TICK += 1;
    guard.tick();
    if (NYAN_T > 0) { NYAN_T -= 1; };
    if (FAST_T > 0) { FAST_T -= 1; };

    if (FAST_T > 0 && !BANNER_ON) {
        BANNER_ON = true;
        BANNER_T = 0;
    };
    if (FAST_T == 0 && BANNER_ON) {
        BANNER_ON = false;
        BANNER_T = 0;
    };
    BANNER_T += 1;
    if (TICK % 10 == 0) { music_tick(); };
    text.VAR_N[7] = g.APPLES;
    world.TIME = TICK;
    text.TIME = TICK;
    vfx.tick();
    mode_tick();
    if (TOAST_T > 0) { TOAST_T -= 1; };
    if (MODE == M_TITLE || MODE == M_ASK) { return; };
    if (MODE == M_STRUCK || MODE == M_CASCADE || MODE == M_CARD || MODE == M_WITNESS) {

        process_events();
        return;
    };
    let busy = dlg.OPEN || book.OPEN || field.OPEN || help.OPEN || MODE == M_WAKE;
    if (!busy) {
        if (MODE == M_PLAY) { clock_tick(); };
        player_tick();
    } else {
        dlg.tick();
    };
    if (!dlg.OPEN) {
        for e in 1..ent.NE {
            if (ent.E_KIND[e] == ent.K_NPC) { ent.E_HOLD[e] = false; };
        };
    };

    if (TALK_TO > 0 && CLICK_GO && TICK % 20 == 0) { start_walk(ent.E_X[TALK_TO], ent.E_Z[TALK_TO]); };
    if (TALK_TO > 0 && !CLICK_GO) {
        let t = TALK_TO;
        TALK_TO = -1;
        if (ent.dist(0, t) < 2 * act.REACH) { talk_to(t); };
    };
    if (TALK_TO > 0 && CLICK_GO && ent.dist(0, TALK_TO) < act.REACH) {
        CLICK_GO = false;
    };
    if (MODE == M_PLAY && !busy) { combat_tick(); };
    if (MODE == M_PLAY) {

        for k in 0..(if (FAST_T > 0) { 12 } else { 1 }) { ent.update_people(); };
        torii_check();
        if (g.MIN >= g.BELL_MIN && !g.NIGHT) { ring_bell(); };
        if (g.MIN >= g.NIGHT_END) { next_day(); };
    };
    process_events();
    if (MODE == M_PLAY) {
        story.tick(!dlg.OPEN && !book.OPEN && !field.OPEN && !help.OPEN);
        hints.tick(!busy);
    };

    if (MODE == M_WITNESS) { return; };
    CAM_X += (ent.E_X[0] - CAM_X) / 6;
    CAM_Z += (ent.E_Z[0] - CAM_Z) / 6;
}

def torii_check() -> void {
    let inside = world.is_passage(ZONE, ent.E_X[0], ent.E_Z[0]);
    if (inside && ent.E_SLOT[0] >= 0) {
        story.unnamed();
        ent.unname(0);
        g.set(g.F_TORII);
    } else if (!inside && ent.E_SLOT[0] < 0 && MODE == M_PLAY) {
        ent.name_it(0);
    };
}

def push_vessel() -> bool {
    if (!world.is_passage(ZONE, ent.E_X[0], ent.E_Z[0]) || g.EFFIGIES <= 0) { return false; };

    let north = ent.E_DIR[0] >= 4;
    let z = ent.E_Z[0] >> 16;
    while (world.tile(ZONE, ent.E_X[0] >> 16, z) == 'P') {
        z = if (north) { z - 1 } else { z + 1 };
    };
    let v = ent.spawn_vessel(ZONE, ent.E_X[0], z * 65536 + 32768);
    if (v < 0) { return false; };
    g.EFFIGIES -= 1;
    sfx.play(sfx.PICKUP, 0);
    true
}

def sky_tint() -> void {

    let m = g.MIN;
    let t = 0xffffff;
    if (m < 420) { t = canvas.mixc(0xd0d4ec, 0xffffff, fx.max(0, (m - 360) * 256 / 60)); };
    if (m >= 960 && m < 1080) { t = canvas.mixc(0xffffff, 0xffb890, (m - 960) * 256 / 120); };
    if (m >= 1080) { t = canvas.mixc(0xffb890, 0x46507a, fx.min(256, (m - 1080) * 256 / 90)); };
    if (world.Z_INDOOR[ZONE]) { t = canvas.mixc(t, 0xffe0b0, 160); };
    r3d.TINT = t;
}

def draw_banner() -> void {
    let w = 34;
    if (w > canvas.W - 4) { w = canvas.W - 4; };
    let x = (canvas.W - w) / 2;
    let y = canvas.H - 10;
    let shown = w;
    let gone = 0;
    if (BANNER_ON) {
        if (BANNER_T < 10) { shown = w * (BANNER_T + 1) / 10; };
    } else {
        if (BANNER_T > 22) { return; };
        gone = BANNER_T * 32 / 22;
        if (FAST_T > 0) { return; };
    };

    let hx = x + (w - shown) / 2;
    for i in 0..shown {
        let cx = hx + i;

        let luck = (fx.noise(cx, y, 4) & 31);
        for r in 0..3 {
            if (!BANNER_ON && luck + (r * 5) < gone) { continue; };
            let ph = (i * 3 + BANNER_T * 2 + r * 2) % 12;
            let hot = ph < 4;
            let col = if (hot) { 0xffd870 } else { 0xff9a3a };
            canvas.put(cx, y + r, 0x2593 - (if (hot) { 0 } else { 1 }), canvas.mixc(col, 0x601810, 90 + r * 40), 0x1a0c08, 0);
        };
    };

    if (shown > 26 && (BANNER_ON || gone < 18)) {
        text.print(x + (w - 18) / 2, y + 1, "{b}» TIME HURRIES «{/}", style.TEXT);
    };
}

def draw_arrow(tx: long, tz: long, ring: long, dark: long, bright: long) -> void {
    r3d.project(ent.E_X[0], 52000, ent.E_Z[0]);
    let px = r3d.PSX;
    let py = r3d.PSY;

    let dx = tx - ent.E_X[0];
    let dz = tz - ent.E_Z[0];
    let u = (dx - dz) >> 4;
    let v = ((dx + dz) >> 4) * 46341 >> 16;
    let a = fx.atan2(v, u);
    let c = fx.cos(a);
    let s = fx.sin(a);

    let r = ring * 16 + (fx.sin(TICK * 7) >> 12);
    let size = 16 + (fx.sin(TICK * 11) >> 13);
    let cx = px + (c * r >> 16);
    let cy = py + (s * r >> 16);

    for k in 0..2 {
        let grow = if (k == 0) { 22 } else { 0 };
        let col = if (k == 0) { dark } else { bright };
        let tip = (6 * 16 + size / 2 + grow);
        let back = (3 * 16 + grow);
        let wide = (4 * 16 + grow);
        let ax = cx + (c * tip >> 16);
        let ay = cy + (s * tip >> 16);
        let bx = cx - (c * back >> 16) - (s * wide >> 16);
        let by = cy - (s * back >> 16) + (c * wide >> 16);
        let ex = cx - (c * back >> 16) + (s * wide >> 16);
        let ey = cy - (s * back >> 16) - (c * wide >> 16);
        pix.tri(ax, ay, 0, bx, by, 0, ex, ey, 0, col);
    };
}

def draw_pointer() -> void {
    story.pointer_update(ZONE);
    if (story.PT_ON) { draw_arrow(story.PT_X, story.PT_Z, 14, 0x5a0a10, 0xff3a3a); };
    if (story.WT_ON) { draw_arrow(story.WT_X, story.WT_Z, 22, 0x0a2a5a, 0x4aa8ff); };
}

def render() -> void {
    ui.begin();
    if (MODE == M_ASK) {
        ask_draw();
        return;
    };
    if (MODE == M_TITLE) {
        title.draw();
        return;
    };
    if (MODE == M_VOID) {
        render_void();
        return;
    };
    if (MODE == M_CARD) {
        render_card();
        return;
    };
    world.FLOAT = g.has(g.W_WEIGHT_GONE);
    world.set_sun(g.MIN, world.Z_INDOOR[ZONE]);

    pxsprite.SH_A = world.SUN_A * 2;
    pxsprite.SH_X = (world.SUN_U * world.SUN_LEN * r3d.SCALE) >> 24;
    pxsprite.SH_Y = ((world.SUN_V * world.SUN_LEN * r3d.SCALE >> 8) * 46341) >> 32;
    r3d.CAM_X = CAM_X;
    r3d.CAM_Z = CAM_Z;
    sky_tint();
    let sky_top = canvas.mixc(0x7fb0d8, 0x101830, if (g.MIN >= 1080) { 200 } else if (world.FLOAT) { 150 } else { 0 });
    if (world.Z_INDOOR[ZONE]) { sky_top = 0x15100c; };
    pix.clear_grad(sky_top, canvas.mixc(sky_top, 0x000000, 80));
    world.draw(ZONE);

    let use_t = -1;
    if (!dlg.OPEN && !book.OPEN && !field.OPEN && !help.OPEN && MODE == M_PLAY) {
        act.find_target(ZONE);
        use_t = act.T_ENT;
    };
    if (use_t <= 0 && act.T_OBJ >= 0) {
        let pulse = 90 + (fx.sin(TICK * 9) >> 11);
        if (!world.halo_thing(act.T_OBJ, pulse)) { world.halo_tile(act.T_OBJ, pulse); };
    };
    ent.draw_px(ZONE, TICK, combat.SWING_T > 0, use_t);
    if (MODE == M_PLAY) { draw_pointer(); };
    pix.compose();
    ent.draw(ZONE, TICK);
    story.draw_fire(ZONE, TICK);
    vfx.draw();
    if (MODE == M_CASCADE) {
        canvas.fade_all(0xffffff, MODE_T * 240 / CASCADE_LEN);
        draw_player_only();
        return;
    };
    if (MODE == M_STRUCK) {
        render_struck();
        return;
    };
    if (MODE == M_WITNESS) {

        canvas.fill(0, 0, canvas.W, 3, 32, 0, 0x000000, 0);
        canvas.fill(0, canvas.H - 3, canvas.W, 3, 32, 0, 0x000000, 0);
        return;
    };
    draw_hud();
    dlg.FLOATING = !mem.LIVE[mem.A_DIALOG];
    if (dlg.FLOATING && dlg.OPEN) { place_floating(); };
    if (dlg.OPEN) {
        dlg.draw();
    } else if (!book.OPEN && !field.OPEN && MODE == M_PLAY) {
        draw_prompt();
    };
    book.draw();
    field.draw();
    draw_nyan();
    draw_toast();
    help.draw();
    if (MODE == M_WAKE) { canvas.fade_all(0, 256 - MODE_T * 256 / 45); };
}

def draw_player_only() -> void {
    pxsprite.draw_cells(ent.E_PS[0], ent.px_view(0), ent.px_frame(0, TICK, false), ent.px_mirror(0), ent.E_X[0], 0, ent.E_Z[0]);
}

def render_struck() -> void {
    let t = MODE_T;
    if (t < 45) { return; };
    if (t < 90) {
        canvas.fade_all(0xffffff, (t - 45) * 256 / 45);
        return;
    };
    canvas.fade_all(0xffffff, 256);
    canvas.fade_all(0x000000, fx.min(256, (t - 95) * 256 / 45));
}

def render_card() -> void {
    canvas.fill(0, 0, canvas.W, canvas.H, 32, 0xffffff, 0x000000, 0);
    if (dlg.OPEN) {
        dlg.FLOATING = true;
        dlg.SPK_X = canvas.W / 2;
        dlg.SPK_Y = canvas.H / 2 - 2;
        dlg.draw();
    };
}

let VOID_PX = 0;
let VOID_PZ = 0;

def render_void() -> void {

    r3d.CAM_X = ent.E_X[0];
    r3d.CAM_Z = ent.E_Z[0];
    r3d.TINT = 0xffffff;
    pix.clear(0xf2f0ec);
    pix.compose();
    let dx = (ent.E_X[0] - VOID_PX) >> 12;
    let dz = (ent.E_Z[0] - VOID_PZ) >> 12;
    VOID_PX = ent.E_X[0];
    VOID_PZ = ent.E_Z[0];
    vfx.ash_draw(dx - dz, dx + dz);
    draw_player_only();
    if (dlg.OPEN) {
        dlg.FLOATING = true;
        dlg.SPK_X = canvas.W / 2;
        dlg.SPK_Y = canvas.H / 2 - 3;
        dlg.draw();
    };
    draw_toast();
    help.draw();
}

def place_floating() -> void {
    let e = dlg.SPEAKER_ENT;
    if (e < 0) { e = 0; };
    dlg.SPK_X = ent.E_SCR_X[e] + ent.E_SCR_W[e] / 2;
    dlg.SPK_Y = ent.E_SCR_Y[e] - 1;
}

def toast_text(id: long) -> str {
    if (id == 1) { return "{gold}The names have moved.{/}"; };
    if (id == 2) { return "{faint}The heavens do not answer.{/}"; };
    if (id == 3) { return "{holy}The bell.{/}"; };
    if (id == 4) { return "{dim}You are not tired. Not until the bell.{/}"; };
    if (id == 5) { return "{dim}Nothing happens.{/}"; };
    if (id == 6) { return "{dim}Judgment gathers. Not yet.{/}"; };
    if (id == 7) { return "{dim}Press {gold}H{/}{dim} for help.{/}"; };
    ""
}

def draw_toast() -> void {
    if (TOAST_T <= 0) { return; };
    ui.toast(2, toast_text(TOAST_ID), style.TEXT);
}

def bell_secs() -> long {
    if (g.NIGHT || g.HANDLESS || g.has(g.W_BELL_GONE) || !mem.LIVE[mem.A_BELL]) { return -1; };
    let ticks = (g.BELL_MIN - g.MIN) * 30 - g.SUB;
    if (ticks < 0) { return -1; };
    (ticks + 29) / 30
}

def draw_bell_dread() -> void {
    let s = bell_secs();
    if (s < 0 || s > 60) {
        r3d.SHAKE_X = 0;
        r3d.SHAKE_Y = 0;
        return;
    };

    let fear = (60 - s) * 256 / 60;
    let beat = fx.sin(TICK * (8 + fear / 12)) >> 9;
    let rim = canvas.mixc(0x000000, 0x6a0010, fear);
    let depth = 1 + fear * 9 / 256;
    let alpha = (fear * 150 / 256) + beat * fear / 2000;
    for k in 0..depth {
        let a = alpha * (depth - k) / depth;
        canvas.fade_rect(0, k, canvas.W, 1, rim, a);
        canvas.fade_rect(0, canvas.H - 1 - k, canvas.W, 1, rim, a);
        canvas.fade_rect(k * 2, 0, 1, canvas.H, rim, a);
        canvas.fade_rect(canvas.W - 1 - k * 2, 0, 1, canvas.H, rim, a);
    };
    let col = canvas.mixc(0xf2c55c, 0xff2a2a, fear);
    if (s <= 10) {

        let x = canvas.W / 2 - 6;
        logo.digit(x, 2, 0, col);
        logo.digit(x + 4, 2, 0, col);
        logo.digit(x + 7, 2, 10, col);
        logo.digit(x + 9, 2, s / 10, col);
        logo.digit(x + 13, 2, s % 10, col);
        r3d.SHAKE_X = fx.rnd(7 + (10 - s) * 3) - 3 - (10 - s);
        r3d.SHAKE_Y = fx.rnd(5 + (10 - s) * 2) - 2 - (10 - s) / 2;
    } else {
        let x = canvas.W / 2 - 6;
        text.VAR_N[8] = s / 10;
        text.VAR_N[9] = s % 10;
        if (s > 30) {
            text.print(x, 1, "{gold}the bell{/} {n 8}{n 9}{dim}s{/}", style.TEXT);
        } else {
            text.print(x, 1, "{red}THE BELL{/} {n 8}{n 9}{dim}s{/}", style.TEXT);
        };
        r3d.SHAKE_X = 0;
        r3d.SHAKE_Y = 0;
    };
}

def bell_pulse() -> void {
    let s = bell_secs();
    if (s < 0 || s > 40) { return; };
    if (s == 20) { sfx.play(sfx.DRONE_ON, 1); };
    if (s > 20 && (s % 2) != 0) { return; };
    sfx.play(sfx.HEART, 0);
}

def draw_bell_focus() -> void {
    let s = bell_secs();
    if (s < 0 || s > 60) { return; };
    let wide = s * 14 / 60;
    let col = canvas.mixc(0xff8a6a, 0xff2020, (60 - s) * 256 / 60);
    for i in 0..rules.NREC {
        let e = ent.by_slot(rules.REC_ADDR[i]);
        if (e < 0 || ent.E_ZONE[e] != ZONE || ent.E_SCR_W[e] <= 0) { continue; };
        let cx = ent.E_SCR_X[e] + ent.E_SCR_W[e] / 2;
        let cy = ent.E_SCR_Y[e] + ent.E_SCR_H[e] / 2;
        let hw = ent.E_SCR_W[e] / 2 + 1 + wide;
        let hh = ent.E_SCR_H[e] / 2 + 1 + wide / 2;

        let sway = (fx.sin(TICK * 12) >> 14) * wide / 14;
        hw += sway;
        for k in 0..3 {

            canvas.put(cx - hw + k, cy - hh, 0x2500, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx + hw - k, cy - hh, 0x2500, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx - hw + k, cy + hh, 0x2500, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx + hw - k, cy + hh, 0x2500, col, canvas.KEEP, canvas.BOLD);
        };
        for k in 0..2 {
            canvas.put(cx - hw, cy - hh + k, 0x2502, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx + hw, cy - hh + k, 0x2502, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx - hw, cy + hh - k, 0x2502, col, canvas.KEEP, canvas.BOLD);
            canvas.put(cx + hw, cy + hh - k, 0x2502, col, canvas.KEEP, canvas.BOLD);
        };
        canvas.put(cx - hw, cy - hh, 0x250C, col, canvas.KEEP, canvas.BOLD);
        canvas.put(cx + hw, cy - hh, 0x2510, col, canvas.KEEP, canvas.BOLD);
        canvas.put(cx - hw, cy + hh, 0x2514, col, canvas.KEEP, canvas.BOLD);
        canvas.put(cx + hw, cy + hh, 0x2518, col, canvas.KEEP, canvas.BOLD);

        canvas.put(cx, cy - hh, 0x25BC, col, canvas.KEEP, canvas.BOLD);
        canvas.put(cx, cy + hh, 0x25B2, col, canvas.KEEP, canvas.BOLD);
    };
}

def draw_hud() -> void {
    let panel = 0x2a2219;

    let h = g.hour();
    let m = g.minute();
    let cx = canvas.W - 7;
    canvas.fill(cx - 1, 0, 8, 1, 32, 0xfff4dc, panel, 0);
    canvas.put(cx, 0, '0' + (h / 10) % 10, 0xfff4dc, panel, canvas.BOLD);
    canvas.put(cx + 1, 0, '0' + h % 10, 0xfff4dc, panel, canvas.BOLD);
    canvas.put(cx + 2, 0, ':', 0xfff4dc, panel, 0);
    canvas.put(cx + 3, 0, '0' + m / 10, 0xfff4dc, panel, canvas.BOLD);
    canvas.put(cx + 4, 0, '0' + m % 10, 0xfff4dc, panel, canvas.BOLD);
    if (FAST_T > 0) { canvas.put(cx - 3, 0, 0x00BB, 0xf2c55c, panel, canvas.BOLD); canvas.put(cx - 2, 0, 0x00BB, 0xf2c55c, panel, canvas.BOLD); };

    if (mem.LIVE[mem.A_HP]) {
        canvas.fill(0, 0, 14, 1, 32, 0xff6a5a, panel, 0);
        canvas.put(1, 0, 0x2665, 0xff6a5a, panel, 0);
        ui.meter(3, 0, 10, g.HP, g.HP_MAX, 0xd84a3a, 0x3a2420);
    };

    if (mem.LIVE[mem.A_MAP]) { draw_minimap(); };
    text.VAR_N[2] = g.COINS;
    text.VAR_N[3] = g.EFFIGIES;
    let y = canvas.H - 1;
    canvas.fill(0, y, 9, 1, 32, 0xf2c55c, panel, 0);
    text.print(1, y, "{gold}●{/} {n 2}", style.TEXT);
    if (g.EFFIGIES > 0) { text.print(10, y, "{gold}✶{/}{n 3}", style.TEXT); };
    if (ent.E_SLOT[0] < 0) { text.print(canvas.W / 2 - 5, 1, "{faint}(unnamed){/}", style.TEXT); };
    draw_seal();
    draw_bell_dread();
    draw_bell_focus();
    draw_banner();
    if (FAST_T > 0) {

        r3d.SHAKE_X += fx.rnd(25) - 12;
        r3d.SHAKE_Y += fx.rnd(17) - 8;
    };
    text.VAR_N[4] = if (combat.LEVEL_FLASH > 0) { 0 } else { g.LEVEL };
    text.print(15, 0, "{dim}Lv{/}{n 4}", style.TEXT);
}

def draw_seal() -> void {
    let x = canvas.W - 12;
    let y = canvas.H - 1;
    let panel = 0x2a2219;
    canvas.fill(x, y, 12, 1, 32, 0xffffff, panel, 0);
    canvas.put(x + 1, y, 0x03DF, 0xffffff, panel, canvas.BOLD);
    if (combat.SEAL >= 0) {
        text.runes(x + 3, y, combat.SEAL, style.RUNE_S);
    } else {
        text.print(x + 3, y, "{dim}··{/}", style.TEXT);
    };
    let ready = combat.JUDGE_COOLDOWN - combat.JUDGE_CD;
    ui.meter(x + 6, y, 5, ready, combat.JUDGE_COOLDOWN, if (combat.JUDGE_CD == 0) { 0xffffff } else { 0x7a8aa8 }, 0x1a1a22);
}

def draw_minimap() -> void {
    let zw = world.Z_W[ZONE];
    let zh = world.Z_H[ZONE];
    let mw = zw;
    let mh = (zh + 1) / 2;
    if (mw > 32) { mw = 32; };
    let x0 = canvas.W - mw - 1;
    MM_X0 = x0;
    MM_W = mw;
    ui.region(HIT_MINIMAP, x0, 1, mw, mh);
    let px = ent.E_X[0] >> 16;
    let pz = ent.E_Z[0] >> 16;
    for cy in 0..mh {
        for cx in 0..mw {
            let tx = cx * zw / mw;
            let a = mini_color(world.tile(ZONE, tx, cy * 2), tx, cy * 2, px, pz);
            let b = mini_color(world.tile(ZONE, tx, cy * 2 + 1), tx, cy * 2 + 1, px, pz);
            canvas.put(x0 + cx, 1 + cy, 0x2580, a, b, 0);
        };
    };
}

def mini_color(c: long, x: long, z: long, px: long, pz: long) -> long {
    if (x == px && z == pz) { return 0xfff060; };
    if (c == '~') { return 0x2f5f8a; };
    if (c == 'T' || c == 'b') { return 0x2f5a2a; };
    if (c == '#' || c == 'H' || c == 'h' || c == 32) { return 0x3a3630; };
    if (c == ',' || c == ':' || c == 'P' || c == '=') { return 0x8a7a5a; };
    if (c == 'w') { return 0x6a5038; };
    0x4a7a3a
}

def draw_ring(x: long, y: long, w: long, h: long) -> void {
    let a = 62 + (fx.sin(TICK * 9) >> 11);
    canvas.fade_rect(x, y, w, 1, 0xffffff, a);
    canvas.fade_rect(x, y + h - 1, w, 1, 0xffffff, a);
    canvas.fade_rect(x, y + 1, 1, h - 2, 0xffffff, a);
    canvas.fade_rect(x + w - 1, y + 1, 1, h - 2, 0xffffff, a);
}

def draw_prompt() -> void {
    act.find_target(ZONE);
    let y = canvas.H - 2;

    if (act.T_ENT > 0 && ent.E_KIND[act.T_ENT] == ent.K_MEMORIAL) {
        ui.toast(y, "{gold}E{/} Read the note", style.TEXT);
    } else if (act.T_ENT > 0 && (ent.E_KIND[act.T_ENT] == ent.K_NPC || ent.E_KIND[act.T_ENT] == ent.K_GHOST)) {
        text.VAR_S[1] = world.P_NAME[ent.E_WHO[act.T_ENT]];
        ui.toast(y, "{gold}E{/} Talk to {name}{v 1}{/}", style.TEXT);
    } else if (act.T_OBJ >= 0) {
        ui.toast(y, "{gold}E{/} Look", style.TEXT);
    };
}

def frame() -> void {
    poll_input();
    update();
    render();
    canvas.flush();
}

def boot() -> void {
    g.RETRIES = save.read_retries();
    if (save.read(false) && g.HAND_FREED) {
        save.read(true);

        ent.clear_all();
        ent.place_player(world.zone_id("square"), 16, 15);
        ent.E_SLOT[0] = -1;
        for a in 0..256 {
            if (mem.LIVE[a] && mem.TAG[a] == mem.T_PLAYER) { ent.E_SLOT[0] = a; };
        };
        g.VOID_LAUNCHES += 1;
        ZONE = ent.E_ZONE[0];
        enter_void();
        return;
    };
    g.BOOTS += 1;
    let day = g.DAY;
    new_loop();
    g.DAY = if (day < 1) { 1 } else { day };
}

let ASK_WORD: [long; 8] = [13, 14, 10, 13, 11, 14, 14, 15];
let ASK_REST: [long; 11] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12];

def ask_answer(readable: bool) -> void {
    if (ASK_STAGE == 0 && !readable) {

        ASK_STAGE = 1;
        ASK_SEL = 0;
        style.use_set(1);
        return;
    };
    g.RUNE_MODE = if (ASK_STAGE == 0) { 0 } else if (readable) { 1 } else { 2 };
    g.ASCII_RUNES = g.RUNE_MODE == 2;
    style.use_set(g.RUNE_MODE);
    save.write_setting("runes", if (g.RUNE_MODE == 0) { "runic" } else if (g.RUNE_MODE == 1) { "symbols" } else { "ascii" });
    set_mode(ASK_PREV);
}

def ask_draw() -> void {
    canvas.fill(0, 0, canvas.W, canvas.H, 32, 0xffffff, 0x000000, 0);
    let cx = canvas.W / 2;
    let y = canvas.H / 2 - 6;
    if (ASK_STAGE == 0) {
        text.print(cx - 12, y, "{gold}Can you read the runes?{/}", style.TEXT);
    } else {
        text.print(cx - 8, y, "{gold}What about now?{/}", style.TEXT);
    };

    for i in 0..8 {
        canvas.put(cx - 8 + i * 2, y + 3, style.RUNE[ASK_WORD[i]], 0x9fd8ff, canvas.KEEP, canvas.BOLD);
    };
    for i in 0..11 {
        canvas.put(cx - 11 + i * 2, y + 5, style.RUNE[ASK_REST[i]], 0x6fb0e0, canvas.KEEP, 0);
    };
    if (ASK_STAGE == 0) {
        text.print(cx - 20, y + 7, "{dim}If those show as boxes or blanks, choose No.{/}", style.TEXT);
    } else {
        text.print(cx - 21, y + 7, "{dim}Still wrong? Choose No, and plain marks it is.{/}", style.TEXT);
    };
    ui.button(HIT_ASK_YES, cx - 10, y + 10, "  Yes  ", if (ASK_SEL == 0) { style.HILITE } else { style.TEXT }, style.GOLD);
    ui.button(HIT_ASK_NO, cx + 3, y + 10, "  No  ", if (ASK_SEL == 1) { style.HILITE } else { style.TEXT }, style.GOLD);
}

def settle_title() -> void {
    if (title.RESULT == 0) { return; };
    title.ACTIVE = false;
    if (title.RESULT == 2) {
        RUNNING = false;
        return;
    };
    set_mode(TITLE_PREV);
}

def run() -> long {

    save.warm();

    guard.arm();
    load_all();
    sfx.start(!g.MUTE);

    term.lock_dumps();

    let forced = g.ASCII_RUNES;
    let known = save.read_setting("runes");
    if (forced) { g.RUNE_MODE = 2; };
    if (known == "ascii") { g.RUNE_MODE = 2; };
    if (known == "symbols") { g.RUNE_MODE = 1; };
    if (known == "runic") { g.RUNE_MODE = 0; };
    g.ASCII_RUNES = g.RUNE_MODE == 2;
    style.use_set(g.RUNE_MODE);
    let need_ask = len(known) == 0 && !forced;
    let had_save = save.exists();
    boot();
    if (had_save) {

        TITLE_PREV = MODE;
        set_mode(M_TITLE);
        title.open();
    };
    if (need_ask) {
        ASK_PREV = MODE;
        ASK_SEL = 0;
        ASK_STAGE = 0;
        style.use_set(0);
        set_mode(M_ASK);
    };
    relayout();
    clock.begin();
    while (RUNNING) {
        poll_input();
        let n = clock.wait();
        for i in 0..n { update(); };
        render();
        canvas.flush();
    };
    0
}

export {
    run, frame, load_all, build_world, render, update, relayout,
    ZONE, TICK, MODE, RUNNING, GONE, PERSON_NODE, TALK_TO, CLICK_GO,
    M_PLAY, M_STRUCK, M_CASCADE, M_VOID, M_WAKE, M_CARD, M_TITLE, M_ASK, M_WITNESS,
    start_walk, snap_camera, handle_key, handle_mouse, set_mode, cast_judgment, boot
};
