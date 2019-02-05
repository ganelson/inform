/*
 * buffer.c
 *
 * Text buffering and word wrapping
 *
 */

#include "frotz.h"

extern void stream_char (zchar);
extern void stream_word (const zchar *);
extern void stream_new_line (void);

static zchar buffer[TEXT_BUFFER_SIZE];
static bufpos = 0;

static zchar prev_c = 0;

/*
 * flush_buffer
 *
 * Copy the contents of the text buffer to the output streams.
 *
 */

void flush_buffer (void)
{
    static bool locked = FALSE;

    /* Make sure we stop when flush_buffer is called from flush_buffer.
       Note that this is difficult to avoid as we might print a newline
       during flush_buffer, which might cause a newline interrupt, that
       might execute any arbitrary opcode, which might flush the buffer. */

    if (locked || bufpos == 0)
	return;

    /* Send the buffer to the output streams */

    buffer[bufpos] = 0;

    locked = TRUE; stream_word (buffer); locked = FALSE;

    /* Reset the buffer */

    bufpos = 0;
    prev_c = 0;

}/* flush_buffer */

/*
 * print_char
 *
 * High level output function.
 *
 */

void print_char (zchar c)
{
    static bool flag = FALSE;

    if (message || ostream_memory || enable_buffering) {

	if (!flag) {

	    /* Characters 0 and ZC_RETURN are special cases */

	    if (c == ZC_RETURN)
		{ new_line (); return; }
	    if (c == 0)
		return;

	    /* Flush the buffer before a whitespace or after a hyphen */

	    if (c == ' ' || c == ZC_INDENT || c == ZC_GAP || prev_c == '-' && c != '-')
		flush_buffer ();

	    /* Set the flag if this is part one of a style or font change */

	    if (c == ZC_NEW_FONT || c == ZC_NEW_STYLE)
		flag = TRUE;

	    /* Remember the current character code */

	    prev_c = c;

	} else flag = FALSE;

	/* Insert the character into the buffer */

	buffer[bufpos++] = c;

	if (bufpos == TEXT_BUFFER_SIZE)
	    runtime_error ("Text buffer overflow");

    } else stream_char (c);

}/* print_char */

/*
 * new_line
 *
 * High level newline function.
 *
 */

void new_line (void)
{

    flush_buffer (); stream_new_line ();

}/* new_line */
