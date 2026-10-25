
import ipc;
import fs;
import audio;

export {
    Stream, server_path, available, open, write, drain, close, play, warm_env,
    auth_packet, create_packet, name_packet, TLEN, PREBUF, MINREQ
};

let TLEN = 4294967295;
let PREBUF = 4294967295;
let MINREQ = 4294967295;

type Stream = { fd: long, chan: long, avail: long, tag: long, ok: bool, rate: long, channels: long };

def be32(d: [byte], p: long) -> long {
    (d[p] << 24) | (d[p + 1] << 16) | (d[p + 2] << 8) | d[p + 3]
};

def u32(o: [byte], v: long) -> long {
    o += (v >> 24) & 255;
    o += (v >> 16) & 255;
    o += (v >> 8) & 255;
    o += v & 255;
    0
};

def t_u32(o: [byte], v: long) -> long { o += 76; u32(o, v) };
def t_str(o: [byte], s: str) -> long {
    o += 116;
    o += bytes(s);
    o += 0;
    0
};
def t_null(o: [byte]) -> long { o += 78; 0 };
def t_bool(o: [byte], b: bool) -> long { o += (if (b) { 49 } else { 48 }); 0 };
def t_u8(o: [byte], v: long) -> long { o += 66; o += v; 0 };
def t_arb(o: [byte], d: [byte]) -> long { o += 120; u32(o, d.length); o += d; 0 };
def t_prop(o: [byte], key: str, val: str) -> long {
    t_str(o, key);
    t_u32(o, len(val) + 1);
    let v = bytes(val);
    v += 0;
    t_arb(o, v)
};

def packet(payload: [byte]) -> [byte] {
    let o: [byte] = [];
    u32(o, payload.length);
    u32(o, 4294967295);
    u32(o, 0);
    u32(o, 0);
    u32(o, 0);
    o += payload;
    o
};

def auth_packet(cookie: [byte]) -> [byte] {
    let p: [byte] = [];
    t_u32(p, 8);
    t_u32(p, 0);
    t_u32(p, 35);
    t_arb(p, cookie);
    packet(p)
};

def name_packet(tag: long, name: str) -> [byte] {
    let p: [byte] = [];
    t_u32(p, 9);
    t_u32(p, tag);
    p += 80;
    t_prop(p, "application.name", name);
    t_null(p);
    packet(p)
};

def channel_map(p: [byte], ch: long) -> bool {
    p += 109;
    p += ch;
    if (ch == 1) { p += 0; }
    else if (ch == 2) { p += 1; p += 2; }
    else if (ch == 6) { p += 1; p += 2; p += 3; p += 7; p += 5; p += 6; }
    else { return false; };
    true
};

def create_packet(tag: long, rate: long, channels: long, name: str) -> [byte] {
    let p: [byte] = [];
    t_u32(p, 3);
    t_u32(p, tag);
    p += 97;
    p += 3;
    p += channels;
    u32(p, rate);
    if (!channel_map(p, channels)) { let none_: [byte] = []; return none_; };
    t_u32(p, 4294967295);
    t_null(p);
    t_u32(p, 4294967295);
    t_bool(p, false);
    t_u32(p, TLEN);
    t_u32(p, PREBUF);
    t_u32(p, MINREQ);
    t_u32(p, 0);
    p += 118;
    p += channels;
    let c = 0;
    while (c < channels) { u32(p, 65536); c = c + 1; };
    let k = 0;
    while (k < 9) { t_bool(p, false); k = k + 1; };
    p += 80;
    t_prop(p, "media.name", name);
    t_null(p);
    k = 0;
    while (k < 7) { t_bool(p, false); k = k + 1; };
    t_u8(p, 0);
    packet(p)
};

let ENV_SERVER = "";
let ENV_RUNTIME = "";
let ENV_COOKIE = "";
let ENV_HOME = "";
let ENV_GOT = false;

def warm_env() -> void {
    if (ENV_GOT) { return; };
    ENV_GOT = true;
    if let str v = fs.getenv("PULSE_SERVER") { ENV_SERVER = v; };
    if let str v = fs.getenv("XDG_RUNTIME_DIR") { ENV_RUNTIME = v; };
    if let str v = fs.getenv("PULSE_COOKIE") { ENV_COOKIE = v; };
    if let str v = fs.getenv("HOME") { ENV_HOME = v; };
}

def server_path() -> str {
    warm_env();
    if (ENV_SERVER != "") {
        let v = ENV_SERVER;
        if (v.starts_with("unix:")) { return v[5:v.length]; };
        if (v.starts_with("/")) { return v; };
    };
    let path = "";
    if (ENV_RUNTIME != "") { path = ENV_RUNTIME + "/pulse/native"; }
    else { path = "/run/user/" + tostring(os_call("y_os_getuid")) + "/pulse/native"; };
    if (fs.exists(path)) { path } else { "" }
};

def available() -> bool { os_call("y_os_audio_devs") > 0 || server_path() != "" };

def cookie() -> [byte] {
    warm_env();
    let paths: [str] = [];
    if (ENV_COOKIE != "") { paths += ENV_COOKIE; };
    if (ENV_HOME != "") {
        paths += ENV_HOME + "/.config/pulse/cookie";
        paths += ENV_HOME + "/.pulse-cookie";
    };
    foreach (p in paths) {
        let b = fs.read_bytes(p);
        if (b != none && b!.length >= 256) { return b![0:256]; };
    };
    let z: [byte] = [];
    let i = 0;
    while (i < 256) { z += 0; i = i + 1; };
    z
};

def read_packet(fd: long) -> { chan: long, body: [byte] }? {
    let h = ipc.recv_exact(fd, 20);
    if (h == none) { return none; };
    let n = be32(h!, 0);
    if (n > 67108864) { return none; };
    let body: [byte] = [];
    if (n > 0) {
        let b = ipc.recv_exact(fd, n);
        if (b == none) { return none; };
        body = b!;
    };
    some({ chan: be32(h!, 4), body: body })
};

def handle(s: Stream, body: [byte]) -> long {
    if (body.length < 5 || body[0] != 76) { return -1; };
    let cmd = be32(body, 1);
    if (cmd == 2 || cmd == 0) {
        if (body.length < 10) { return -1; };
        let tag = be32(body, 6);
        if (cmd == 0) { s.ok = false; };
        return tag;
    };
    if (cmd == 61 && body.length >= 20) {

        s.avail = s.avail + be32(body, 16);
        return -1;
    };
    if (cmd == 64 || cmd == 65) { s.ok = false; };
    -1
};

def call(s: Stream, pkt: [byte], tag: long) -> [byte]? {
    if (!ipc.send(s.fd, pkt)) { return none; };
    while (true) {
        let r = read_packet(s.fd);
        if (r == none) { return none; };
        if (r!.chan != 4294967295) { continue; };
        let got = handle(s, r!.body);
        if (got == tag) {
            if (r!.body.length >= 5 && be32(r!.body, 1) == 0) { return none; };
            return some(r!.body);
        };
    };
    none
};

def open(rate: long, channels: long, name: str = "y") -> Stream? {

    if (os_call("y_os_audio_devs") > 0) {
        if (channels != 1 && channels != 2 && channels != 6) { return none; };
        let h = os_call("y_os_audio_open", rate, channels);
        if (h <= 0) { return none; };
        return some({ fd: h, chan: -1, avail: 0, tag: 0, ok: true, rate: rate, channels: channels });
    };
    let path = server_path();
    if (path == "") { return none; };
    let fd = ipc.connect_unix(path);
    if (fd < 0) { return none; };
    let s: Stream = { fd: fd, chan: 0, avail: 0, tag: 1, ok: true, rate: rate, channels: channels };
    let cp = create_packet(2, rate, channels, name);
    if (cp.length == 0 || call(s, auth_packet(cookie()), 0) == none || call(s, name_packet(1, name), 1) == none) {
        ipc.close(fd);
        return none;
    };
    let r = call(s, cp, 2);
    if (r == none || r!.length < 15) {
        ipc.close(fd);
        return none;
    };
    s.chan = be32(r!, 11);
    s.tag = 3;

    if (r!.length >= 25) { s.avail = be32(r!, 21); };
    some(s)
};

def write(s: Stream, pcm: [byte]) -> bool {
    if (s.chan == -1) {
        if (!s.ok) { return false; };
        if (pcm.length == 0) { return true; };
        let n = os_call("y_os_audio_write", s.fd, &pcm[0], pcm.length);
        if (n != pcm.length) { s.ok = false; return false; };
        return true;
    };
    let off = 0;
    let frame = 2 * s.channels;
    while (off < pcm.length) {
        if (!s.ok) { return false; };
        if (s.avail <= 0) {
            let r = read_packet(s.fd);
            if (r == none) { s.ok = false; return false; };
            if (r!.chan == 4294967295) { handle(s, r!.body); };
            continue;
        };
        let n = pcm.length - off;
        if (n > s.avail) { n = s.avail; };
        if (n > 65536) { n = 65536; };
        n = n - n % frame;
        if (n == 0) { n = frame; };
        let o: [byte] = [];
        u32(o, n);
        u32(o, s.chan);
        u32(o, 0);
        u32(o, 0);
        u32(o, 0);
        o += pcm[off:off + n];
        if (!ipc.send(s.fd, o)) { s.ok = false; return false; };
        s.avail = s.avail - n;
        off = off + n;
    };
    true
};

def drain(s: Stream) -> bool {
    if (s.chan == -1) { return s.ok; };
    if (!s.ok) { return false; }
    let p: [byte] = [];
    t_u32(p, 12);
    t_u32(p, s.tag);
    t_u32(p, s.chan);
    let tag = s.tag;
    s.tag = s.tag + 1;
    call(s, packet(p), tag) != none
};

def close(s: Stream) -> long {
    s.ok = false;
    if (s.chan == -1) { return os_call("y_os_audio_close", s.fd); };
    ipc.close(s.fd)
};

def play(snd: audio.Sound) -> bool {
    let st = open(snd.rate, snd.channels, "y");
    if (st == none) { return false; };
    let ok = write(st!, snd.pcm) && drain(st!);
    close(st!);
    ok
};
