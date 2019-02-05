/*
 * redirect.c
 *
 * Output redirection to Z-machine memory
 *
 */

#include "frotz.h"

#define MAX_NESTING 16

extern zword get_max_width (zword);

static depth = -1;

static struct {
    zword xsize;
    zword table;
    zword width;
    zword total;
} redirect[MAX_NESTING];

/*
 * memory_open
 *
 * Begin output redirection to the memory of the Z-machine.
 *
 */

void memory_open (zword table, zword xsize, bool buffering)
{

    if (++depth < MAX_NESTING) {

	if (!buffering)
	    xsize = 0xffff;
	if (buffering && (short) xsize <= 0)
	    xsize = get_max_width ((zword) (- (short) xsize));

	storew (table, 0);

	redirect[depth].table = table;
	redirect[depth].width = 0;
	redirect[depth].total = 0;
	redirect[depth].xsize = xsize;

	ostream_memory = TRUE;

   } else runtime_error ("Nesting stream #3 too deep");

}/* memory_open */

/*
 * memory_new_line
 *
 * Redirect a newline to the memory of the Z-machine.
 *
 */

void memory_new_line (void)
{
    zword size;
    zword addr;

    redirect[depth].total += redirect[depth].width;
    redirect[depth].width = 0;

    addr = redirect[depth].table;

    LOW_WORD (addr, size)
    addr += 2;

    if (redirect[depth].xsize != 0xffff) {

	redirect[depth].table = addr + size;
	size = 0;

    } else storeb ((zword) (addr + (size++)), 13);

    storew (redirect[depth].table, size);

}/* memory_new_line */

/*
 * memory_word
 *
 * Redirect a string of characters to the memory of the Z-machine.
 *
 */

void memory_word (const zchar *s)
{
    zword size;
    zword addr;
    zchar c;

    if (h_version == V6) {

	int width = os_string_width (s);

	if (redirect[depth].xsize != 0xffff)

	    if (redirect[depth].width + width > redirect[depth].xsize) {

		if (*s == ' ' || *s == ZC_INDENT || *s == ZC_GAP)
		    width = os_string_width (++s);

		memory_new_line ();

	    }

	redirect[depth].width += width;

    }

    addr = redirect[depth].table;

    LOW_WORD (addr, size)
    addr += 2;

    while ((c = *s++) != 0)
	storeb ((zword) (addr + (size++)), translate_to_zscii (c));

    storew (redirect[depth].table, size);

}/* memory_word */

/*
 * memory_close
 *
 * End of output redirection.
 *
 */

void memory_close (void)
{

    if (depth >= 0) {

	if (redirect[depth].xsize != 0xffff)
	    memory_new_line ();

	if (h_version == V6) {

	    h_line_width = (redirect[depth].xsize != 0xffff) ?
		redirect[depth].total : redirect[depth].width;

	    SET_WORD (H_LINE_WIDTH, h_line_width)

	}

	if (depth == 0)
	    ostream_memory = FALSE;

	depth--;

    }

}/* memory_close */
