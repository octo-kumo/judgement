"""Drive the real binary in a pty: boot, dialogue, mouse, resize, walk, quit,
and check the terminal is put back (alt screen and mouse modes off).

Usage: python3 tests/pty_test.py [build/judgement]
"""
import os, sys, tempfile, time
sys.path.insert(0, os.path.dirname(__file__))
from vt import Pty

def main(binary):
    data = tempfile.mkdtemp(prefix='hr-pty-')
    env = {'XDG_DATA_HOME': data, 'HOME': data}
    p = Pty([os.path.abspath(binary), '--mute'], rows=40, cols=120, env=env)
    fails = []

    def check(ok, what):
        if not ok:
            fails.append(what)
            print('FAIL:', what)

    p.pump(1.5)
    check(p.screen.find('Can you read the runes') is not None, 'the first screen asks about the runes')
    p.send('y', 1.2)
    check(p.screen.modes.get('1049') is True, 'alt screen entered')
    check(any(m in p.screen.modes and p.screen.modes[m] for m in ('1000', '1002', '1003', '1006')),
          'mouse reporting on')
    check(p.screen.find('I am back') is not None, 'the first line shows on boot')

    if os.geteuid() != 0:
        def denied(path, read=True):
            try:
                with open(path, 'rb') as f:
                    if read:
                        f.read(64)
            except OSError:
                return True
            return False
        check(denied('/proc/%d/mem' % p.pid), 'a memory dump of the game is refused')
        check(denied('/proc/%d/maps' % p.pid), '/proc/<pid>/maps is refused')
        core = [l.split()[4] for l in open('/proc/%d/limits' % p.pid) if 'core' in l.lower()]
        check(core == ['0'], 'core dumps are off (got %r)' % (core,))

    p.set_size(30, 100)
    p.send('', 0.6)
    import fcntl, termios, signal
    os.kill(p.pid, signal.SIGWINCH)
    p.pump(0.8)
    check(p.screen.find('I am back') is not None, 'dialogue survives a resize')

    pos = p.screen.find('I am back')
    if pos:
        p.click(pos[0] + 2, pos[1], wait=0.5)
    p.send('\r', 0.4)
    before = p.screen.text()
    for _ in range(6):
        p.send('s', 0.12)
    for _ in range(4):
        p.send('d', 0.12)
    p.pump(0.5)
    check(p.screen.text() != before, 'walking changes the frame')

    p.click(60, 14, wait=0.8)
    p.send('b', 0.3)

    p.send('q', 0.3)
    code = p.wait_exit(4.0)
    p.pump(0.3)
    check(code == 0, 'clean exit (got %r)' % (code,))
    check(p.screen.modes.get('1049') is False, 'alt screen left')
    for m in ('1000', '1002', '1003', '1006'):
        check(p.screen.modes.get(m) in (None, False), 'mouse mode %s off' % m)

    p2 = Pty([os.path.abspath(binary), '--mute'], rows=40, cols=120, env=env)
    p2.pump(1.5)
    check(p2.screen.find('Continue') is not None, 'a later boot shows the title card')
    p2.send('s', 0.3)
    p2.send('\r', 0.4)
    check(p2.screen.find('Sound') is not None, 'settings opens from the title')
    p2.send('\x1b', 0.5)
    p2.send('\x1b', 0.5)
    p2.send('\r', 0.5)
    check(p2.screen.find('Continue') is None, 'Continue leaves the card')
    p2.send('\r', 0.3)
    p2.send('q', 0.3)
    code2 = p2.wait_exit(4.0)
    check(code2 == 0, 'second boot exits cleanly (got %r)' % (code2,))

    p3 = Pty([os.path.abspath(binary), '--mute'], rows=40, cols=120, env=env)
    p3.pump(1.2)
    p3.send('q', 0.3)
    check(p3.wait_exit(4.0) == 0, 'q on the title card quits')

    print('pty_test: %s' % ('ok' if not fails else '%d failed' % len(fails)))
    return 1 if fails else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else './build/judgement'))
