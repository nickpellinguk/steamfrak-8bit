/*
 * beamshot: run vecx without a window and write down every line the beam draws.
 *
 *     beamshot ROM CART|- SKIP FRAMES OUT
 *
 * Runs the Vectrex (BIOS ROM, and the cartridge CART unless it's "-") for SKIP frames of 30000
 * cycles (50 Hz), then records the lines drawn in the next FRAMES frames to OUT, one a line:
 *
 *     cycle x0 y0 x1 y1 intensity cycles
 *
 * in vecx's beam units (the screen is 33000 x 41000, y down), the intensity (0-127) and how long
 * the beam took to draw it, in cycles. A line with the same start and end is the beam standing
 * still with the beam on. render.py turns this into a picture, the brightness of each line
 * coming from intensity x time / length (the beam's speed), as on a real Vectrex.
 *
 * It's linked with vecx's emulation (vecx.c, e6809.c, with beam.patch applied) in place of vecx's
 * SDL front end (osint.c) and sound (e8910.c), so it needs no SDL.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vecx.h"
#include "osint.h"

#define FRAME_CYCLES 30000

static FILE *out;
static long long now;                   /* cycles since the start of recording */

void beam_line (long x0, long y0, long x1, long y1, unsigned char color, long cycles)
{
	if (out && color > 0)
		fprintf (out, "%llu %ld %ld %ld %ld %d %ld\n", alg_cycles, x0, y0, x1, y1, color, cycles);
}

void osint_render (void) {}
void e8910_write (int r, int v) { (void) r; (void) v; }

static void load (const char *name, unsigned char *buf, size_t size, int exact)
{
	FILE *f = fopen (name, "rb");
	size_t n;
	if (!f) { perror (name); exit (1); }
	n = fread (buf, 1, size, f);
	fclose (f);
	if (exact && n != size) { fprintf (stderr, "%s: expected %zu bytes\n", name, size); exit (1); }
}

int main (int argc, char *argv[])
{
	long skip, frames, i;
	if (argc != 6) {
		fprintf (stderr, "usage: beamshot ROM CART|- SKIP FRAMES OUT\n");
		return 2;
	}
	load (argv[1], rom, sizeof rom, 1);
	memset (cart, 0, sizeof cart);
	if (strcmp (argv[2], "-") != 0)
		load (argv[2], cart, sizeof cart, 0);
	skip = atol (argv[3]);
	frames = atol (argv[4]);

	vecx_reset ();
	/* (no buttons pressed: vecx's inputs read 1 for "up") */
	snd_regs[14] = 0xff;
	for (i = 0; i < skip; i++)
		vecx_emu (FRAME_CYCLES);
	out = fopen (argv[5], "w");
	if (!out) { perror (argv[5]); return 1; }
	for (i = 0; i < frames * FRAME_CYCLES; i += 100) {
		vecx_emu (100);
		now = i;
	}
	fclose (out);
	return 0;
}
