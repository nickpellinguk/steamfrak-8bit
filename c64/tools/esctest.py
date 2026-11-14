# Checks Escape (Run/Stop or the left arrow) in the game: a key script (build.mjs --keys, E for
# Escape) knocks the Scrubbly off the A's right leg (Trogg put on its left leg), then presses
# Escape; in a test build that restarts the game at once (the attract screen is left out), so then
# the level must be as at the start: Trogg at his start, no Scrubbly knocked off, the timer
# restarted, and Trogg drawn where he should be (troggshot.py). Then the same script without the
# Escape, to show the knock-off happened.
#   python3 esctest.py
import os, re, subprocess, sys
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
KNOCK = '60:-,10:Y,30:-,120:Y,200:-'
def run(keys, secs):
    subprocess.run(['node', os.path.join(DIR, 'build.mjs'), '--nopack', *os.environ.get('LV', '').split(), '--invincible', '--keys', keys, '--troggx', '345', '--troggy', '207'],
                   check=True, capture_output=True)
    L = {}
    for line in open(os.path.join(B, 'frak64.lbl')):
        m = re.match(r'(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
        if m: L[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
    shot = os.path.join(B, 'esctest.png')
    out = subprocess.run(['python3', os.path.join(DIR, 'vice.py'), str(secs), f'screenshot "{shot}" 2',
                          'm %04x %04x' % (L['tx'], L['tx'] + 3), 'm %04x %04x' % (L['knocked'], L['knocked'] + 4),
                          'm %04x %04x' % (L['tmf'], L['tmf'] + 3), 'm %04x %04x' % (L['tfr'], L['tfr'])], capture_output=True, text=True).stdout
    v = [[int(x, 16) for x in m.split()] for m in re.findall(r'>C:[0-9a-f]{4}\s+((?:[0-9a-f]{2}\s+)+)', out)]
    tx, ty = v[0][0] | v[0][1] << 8, v[0][2] | v[0][3] << 8
    secs_shown = v[2][3] * 60 + v[2][2] * 10 + v[2][1]
    return dict(tx=tx, ty=ty, knocked=v[1], timer=secs_shown, tfr=v[3][0], start=tuple(int(re.search(rf'^{n}\s*=\s*(\d+)', open(os.path.join(DIR, '..', 'build', 'lvtab.inc')).read(), re.M).group(1)) for n in ('TSTARTX', 'TSTARTY')), shot=shot)
probs = 0
a = run(KNOCK, 9)
print(f'without Escape: Trogg at {a["tx"]},{a["ty"]}, knocked off {a["knocked"]}, timer {a["timer"]} s')
if not any(a['knocked']): print('  the Scrubbly wasn\'t knocked off: the test proves nothing'); probs += 1
e = run(KNOCK + ',1:E,100:-', 13)      # (13 s: the level unpacked again after Escape, about a second)
print(f'with Escape:    Trogg at {e["tx"]},{e["ty"]}, knocked off {e["knocked"]}, timer {e["timer"]} s')
if (e['tx'], e['ty']) != e['start']: print(f'  Trogg not at his start {e["start"]}'); probs += 1
if any(e['knocked']): print('  a Scrubbly still knocked off'); probs += 1
if e['timer'] > 3: print('  the timer not restarted'); probs += 1
ts = subprocess.run(['python3', os.path.join(DIR, 'troggshot.py'), e['shot'], str(e['tx']), str(e['ty']), str(e['tfr'])], capture_output=True, text=True).stdout.strip()
print('  screenshot:', ts)
if ' 0 of his pixels differ' not in ts or 'Trogg found +0 across, +0 down' not in ts: probs += 1
print('problems:', probs)
sys.exit(1 if probs else 0)
