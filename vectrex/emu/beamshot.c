/*
 * beamshot: run vecx without a window and write down every line the beam draws.
 *
 *     beamshot [-d CYCLES] [-s CYCLES] [-m ADDR] [-p ADDR,...] ROM CART|- SKIP FRAMES OUT
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
 * -d sets how many cycles the analogue side (ramp, DAC values, zeroing, intensity) lags the VIA,
 * while the spot's on/off doesn't: 13 by default, MAME's 8.5 microseconds; 0 for vecx as it was.
 *
 * -s sets how many cycles each bit takes when the shift register shifts out under the system
 * clock, the mode the BIOS uses for the spot: 2 by default, as a 6522 (and MAME) does; 1 for
 * vecx as it was.
 *
 * -m ADDR (hex, $C800-$CBFF) prints the 16-bit word in RAM there at the end (high byte first).
 * -p ADDR,ADDR,... (hex) prints "p ADDR CYCLE" whenever the 6809 is about to run the instruction
 * at one of them, while recording: for timing code.
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
static unsigned watch[32];
static int nwatch;

static void on_instruction (unsigned long long cycles)
{
	int i;
	if (!out)
		return;
	for (i = 0; i < nwatch; i++)
		if (reg_pc == watch[i])
			printf ("p %04x %llu\n", watch[i], cycles);
}
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
	long mem = -1;
	alg_delay = 13;
	via_o2_div = 2;
	while (argc > 2 && (strcmp (argv[1], "-d") == 0 || strcmp (argv[1], "-s") == 0 ||
	                    strcmp (argv[1], "-m") == 0 || strcmp (argv[1], "-p") == 0)) {
		if (argv[1][1] == 'd')
			alg_delay = atoi (argv[2]);
		else if (argv[1][1] == 's')
			via_o2_div = atoi (argv[2]);
		else if (argv[1][1] == 'm')
			mem = strtol (argv[2], NULL, 16);
		else {
			char *p = argv[2];
			while (*p && nwatch < 32) {
				watch[nwatch++] = (unsigned) strtol (p, &p, 16);
				if (*p == ',')
					p++;
			}
			beam_watch = on_instruction;
		}
		argc -= 2;
		argv += 2;
	}
	if (argc != 6 || alg_delay < 0 || alg_delay >= 64 || via_o2_div < 1) {
		fprintf (stderr, "usage: beamshot [-d CYCLES (0-63)] [-s CYCLES] [-m ADDR] ROM CART|- SKIP FRAMES OUT\n");
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
	if (mem >= 0)
		printf ("%04lx: %u\n", mem, (unsigned) ram[mem & 0x3ff] << 8 | ram[(mem + 1) & 0x3ff]);
	return 0;
}
