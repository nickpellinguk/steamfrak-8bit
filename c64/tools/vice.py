# Runs VICE (x64sc, headless) on the stand-in ROMs and talks to it through its remote monitor:
#   python3 vice.py SECONDS "cmd1" "cmd2" ...   (each command's reply printed)
# The machine runs for SECONDS of real time first. A command "wait N" lets it run N seconds more.
# VICEARGS: more options for x64sc (say "-initbreak reset", with NOX=1 so it isn't set going).
import socket, subprocess, sys, time, os
DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')   # (the ROMs: build.mjs)
PORT = 6510 + os.getpid() % 1000
p = subprocess.Popen(['xvfb-run', '-a', 'x64sc', '-default', '-kernal', 'kernal.rom', '-basic', 'basic.rom', '-chargen', 'chargen.rom', '-cartcrt', 'frak64.crt',
                      '-drive8type', '0', '-sounddev', 'dummy', '-VICIIfilter', '0', '-jamaction', '2'] + os.environ.get('VICEARGS', '').split() + ['-remotemonitor', '-remotemonitoraddress', f'ip4://127.0.0.1:{PORT}'],
                     cwd=DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    s = None
    for _ in range(100):
        try:
            s = socket.create_connection(('127.0.0.1', PORT)); break
        except OSError:
            time.sleep(0.2)
    if not s: sys.exit('no monitor')
    s.settimeout(2)
    def talk(cmd):
        s.sendall((cmd + '\n').encode())
        out = b''
        try:
            while True:
                d = s.recv(65536)
                if not d: break
                out += d
                if out.rstrip().endswith(b')'): pass
        except socket.timeout:
            pass
        return out.decode(errors='replace')
    if not os.environ.get('NOX'): talk('x')   # (connecting stops the machine: go on)
    time.sleep(float(sys.argv[1]))
    for c in sys.argv[2:]:
        if c.startswith('wait '):
            talk('x'); time.sleep(float(c[5:])); continue
        print('>', c); print(talk(c))
    talk('quit')
finally:
    time.sleep(0.5)
    p.terminate()
    try: p.wait(5)
    except Exception: p.kill()
