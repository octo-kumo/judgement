"""A tiny VT emulator for the subset the engine emits, plus a pty driver.

Handles: CUP (H), SGR (m, 24-bit), ED 2J, DEC private modes (h/l, recorded),
UTF-8 text with wide-glyph awareness kept simple (every glyph is one cell
here; the engine writes the SKIP half itself).
"""
import os, pty, select, struct, fcntl, termios, time, signal, re

class Screen:
    def __init__(self, rows, cols):
        self.rows, self.cols = rows, cols
        self.ch = [[' '] * cols for _ in range(rows)]
        self.fg = [[None] * cols for _ in range(rows)]
        self.bg = [[None] * cols for _ in range(rows)]
        self.r = self.c = 0
        self.cur_fg = self.cur_bg = None
        self.modes = {}
        self.buf = b''

    def resize(self, rows, cols):
        self.__init__(rows, cols)

    def dump_cells(self, path):
        with open(path, 'w') as f:
            for y in range(self.rows):
                out = []
                for x in range(self.cols):
                    cp = ord(self.ch[y][x][0]) if self.ch[y][x] else 32
                    fg = self.fg[y][x] if self.fg[y][x] is not None else 0xcccccc
                    bg = self.bg[y][x] if self.bg[y][x] is not None else 0
                    out.append('%06x %06x %06x' % (cp, fg, bg))
                f.write(','.join(out) + '\n')

    def text(self):
        return '\n'.join(''.join(r).rstrip() for r in self.ch)

    def row(self, y):
        return ''.join(self.ch[y])

    def find(self, s):
        for y in range(self.rows):
            x = self.row(y).find(s)
            if x >= 0:
                return (x, y)
        return None

    def feed(self, data):
        self.buf += data
        s = self.buf
        i = 0
        n = len(s)
        while i < n:
            b = s[i]
            if b == 0x1b:
                if i + 1 >= n:
                    break
                if s[i + 1] == ord('['):
                    m = re.compile(rb'\x1b\[([0-9;?<]*)([@-~])').match(s, i)
                    if not m:
                        if n - i < 64:
                            break
                        i += 1
                        continue
                    self.csi(m.group(1).decode(), chr(m.group(2)[0]))
                    i = m.end()
                    continue
                i += 2
                continue
            if b < 0x20:
                if b == 10:
                    self.r = min(self.r + 1, self.rows - 1)
                elif b == 13:
                    self.c = 0
                i += 1
                continue
            ln = 1 if b < 0x80 else 2 if b < 0xe0 else 3 if b < 0xf0 else 4
            if i + ln > n:
                break
            chs = s[i:i + ln].decode('utf-8', 'replace')
            if 0 <= self.r < self.rows and 0 <= self.c < self.cols:
                self.ch[self.r][self.c] = chs
                self.fg[self.r][self.c] = self.cur_fg
                self.bg[self.r][self.c] = self.cur_bg
            self.c += 1
            i += ln
        self.buf = s[i:]

    def csi(self, p, f):
        if f == 'H':
            parts = [int(x) if x else 1 for x in p.split(';')] if p else [1, 1]
            while len(parts) < 2:
                parts.append(1)
            self.r, self.c = parts[0] - 1, parts[1] - 1
        elif f == 'J':
            if p == '2':
                for y in range(self.rows):
                    for x in range(self.cols):
                        self.ch[y][x] = ' '
                        self.bg[y][x] = self.cur_bg
        elif f == 'm':
            vals = [int(x) if x else 0 for x in p.split(';')] if p else [0]
            k = 0
            while k < len(vals):
                v = vals[k]
                if v == 0:
                    self.cur_fg = self.cur_bg = None
                elif v in (38, 48) and k + 4 < len(vals) + 0 and vals[k + 1] == 2:
                    col = (vals[k + 2] << 16) | (vals[k + 3] << 8) | vals[k + 4]
                    if v == 38:
                        self.cur_fg = col
                    else:
                        self.cur_bg = col
                    k += 4
                elif v == 39:
                    self.cur_fg = None
                elif v == 49:
                    self.cur_bg = None
                k += 1
        elif f in 'hl' and p.startswith('?'):
            for m in p[1:].split(';'):
                self.modes[m] = (f == 'h')

class Pty:
    def __init__(self, argv, rows=40, cols=120, env=None):
        self.rows, self.cols = rows, cols
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            e = dict(os.environ)
            e['TERM'] = 'xterm-256color'
            if env:
                e.update(env)
            os.execve(argv[0], argv, e)
        self.set_size(rows, cols)
        self.screen = Screen(rows, cols)
        self.raw = b''

    def set_size(self, rows, cols):
        self.rows, self.cols = rows, cols
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack('HHHH', rows, cols, 0, 0))
        if hasattr(self, 'screen'):
            self.screen.resize(rows, cols)

    def pump(self, secs=0.3):
        end = time.time() + secs
        while True:
            left = end - time.time()
            if left <= 0:
                break
            r, _, _ = select.select([self.fd], [], [], left)
            if not r:
                continue
            try:
                d = os.read(self.fd, 65536)
            except OSError:
                break
            if not d:
                break
            self.raw += d
            self.screen.feed(d)

    def send(self, data, wait=0.25):
        if isinstance(data, str):
            data = data.encode()
        os.write(self.fd, data)
        self.pump(wait)

    def click(self, x, y, btn=0, wait=0.25):
        self.send(f'\x1b[<{btn};{x + 1};{y + 1}M'.encode(), 0.05)
        self.send(f'\x1b[<{btn};{x + 1};{y + 1}m'.encode(), wait)

    def move(self, x, y, wait=0.15):
        self.send(f'\x1b[<35;{x + 1};{y + 1}M'.encode(), wait)

    def wait_exit(self, secs=3.0):
        end = time.time() + secs
        while time.time() < end:
            self.pump(0.1)
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                return os.waitstatus_to_exitcode(status)
        os.kill(self.pid, signal.SIGKILL)
        os.waitpid(self.pid, 0)
        return None
