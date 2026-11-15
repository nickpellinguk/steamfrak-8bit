/* The browser's side of atari800 (libatari800, compiled with emscripten): a PAL 800XL with
   AltirraOS (built in: no Atari ROMs needed), started with a program, run a frame at a time. */
#include <string.h>
#include "libatari800/libatari800.h"
#include "colours.h"

static input_template_t in;

int web_start(const char *path)
{
	static char *argv[] = { "atari800", "-xl", "-pal", "-nobasic", "-audio16", "-dsprate", "44100", "-run", NULL };
	argv[8] = (char *) path;
	libatari800_clear_input_array(&in);
	return libatari800_init(9, argv);
}

int web_reboot(const char *path) { return libatari800_reboot_with_file(path); }

/* joy: bits up 1, down 2, left 4, right 8 (set when pushed); trig 1 when pressed;
   keychar: an ASCII key this frame or 0; console: bits start 1, select 2, option 4 */
int web_frame(int joy, int trig, int keychar, int console)
{
	in.joy0 = joy; in.trig0 = trig; in.keychar = keychar;
	in.start = console & 1; in.select = (console >> 1) & 1; in.option = (console >> 2) & 1;
	return libatari800_next_frame(&in);
}

unsigned char *web_screen(void) { return libatari800_get_screen_ptr(); }   /* 384 x 240 colour indices */
int *web_palette(void) { return Colours_table; }                          /* 256 x 0xRRGGBB */
unsigned char *web_sound(void) { return libatari800_get_sound_buffer(); }
int web_sound_len(void) { return libatari800_get_sound_buffer_len(); }
unsigned char *web_memory(void) { return libatari800_get_main_memory_ptr(); }
