# build_page.py A8JS: the web page (build/frak800.html): web/page.html with the emulator (the
# single-file a8.js that emcc makes from web/web.c and libatari800: see README.md) and the
# programs (build/*.xex, made by build.sh and below) put in.
import base64, os, subprocess, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, '..'); B = os.path.join(ROOT, 'build')
a8js = open(sys.argv[1]).read()
def xex(level):
    subprocess.run(['./build.sh'], cwd=ROOT, env={**os.environ, 'LEVEL': level}, check=True, capture_output=True)
    return open(os.path.join(B, 'screen8x4.xex'), 'rb').read()
progs = {}
subprocess.run(['./build.sh'], cwd=ROOT, check=True, capture_output=True)
progs['trogg8x4_A_1.xex'] = {'label': 'Frak! A_1: Trogg, gems and keys (stand-in balloons and daggers)', 'data': base64.b64encode(open(os.path.join(B, 'trogg8x4.xex'), 'rb').read()).decode()}
for lv, what in (('A_1', 'Scrubblies'), ('A_2', 'Poglets'), ('A_3', 'Hooters')):
    progs[f'screen8x4_{lv}.xex'] = {'label': f'8x4 screen: {lv} ({what})', 'data': base64.b64encode(xex(lv)).decode()}
subprocess.run(['./build.sh'], cwd=ROOT, check=True, capture_output=True)    # (A_1 left built)
progs['rows4.xex'] = {'label': '4-line row test', 'data': base64.b64encode(open(os.path.join(B, 'rows4.xex'), 'rb').read()).decode()}
page = open(os.path.join(HERE, 'page.html')).read()
page = page.replace('/*A8JS*/', a8js.replace('</script', '<\\/script')).replace('/*PROGRAMS*/', json.dumps(progs))
open(os.path.join(B, 'frak800.html'), 'w').write(page)
print(f'build/frak800.html: {len(page) // 1024}KB')
