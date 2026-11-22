#!/usr/bin/env python3
"""
The A/K screen, beneath the FR screen: A on the left half, K on the right. The route comes in at
the K's top right (beneath the R's leg), down the K's upper arm (single-block steps) to its
middle, down the K's stem (a ladder) to the floor, then left to the A, where Trogg is drawn.

Uses fr_screen.py's model, scheduler and checks with this screen's layout:

    python3 atarivcs/test/ak_screen.py [OUT_DIR]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fr_screen as fr  # noqa: E402
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

fr.PLATFORMS = [
    (24, 24, 59),      # A top bar
    (104, 24, 59),     # A crossbar
    (176, 16, 67),     # A floor (Trogg ends here)
    (24, 84, 103),     # K stem top
    (88, 92, 119),     # K middle (where the arm and leg meet the stem)
    (176, 84, 107),    # K floor under the stem
    (176, 140, 155),   # K floor at the bottom right (end of the leg)
]
fr.STEPS = [
    (40, 145), (56, 136), (72, 127),                   # K upper arm: in from the top right
    (120, 130), (136, 139), (152, 148),                # K lower leg: down to the right
]
fr.LADDERS = [(28, 32, 176), (55, 32, 176), (88, 32, 176)]   # A's two legs, K's stem
fr.ITEMS = [('gem', 40, 17), ('gem', 112, 81), ('gem', 148, 169)]


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'ak_screen')
    lines, nruns, worst = fr.build(base)
    print('%d runs, busiest line ends at cycle %d' % (nruns, worst))
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
    fr.compare(base + '.png', lines)
