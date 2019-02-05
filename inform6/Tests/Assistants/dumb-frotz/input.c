/*
 * input.c
 *
 * High level input functions
 *
 */

#include "frotz.h"

extern int save_undo (void);

extern zchar stream_read_key (zword, zword, bool);
extern zchar stream_read_input (int, zchar *, zword, zword, bool, bool);

extern void tokenise_line (zword, zword, zword, bool);

/*
 * is_terminator
 *
 * Check if the given key is an input terminator.
 *
 */

bool is_terminator (zchar key)
{

    if (key == ZC_TIME_OUT)
	return TRUE;
    if (key == ZC_RETURN)
	return TRUE;
    if (key >= ZC_HKEY_MIN && key <= ZC_HKEY_MAX)
	return TRUE;

    if (h_terminating_keys != 0)

	if (key >= ZC_ARROW_MIN && key <= ZC_MENU_CLICK) {

	    zword addr = h_terminating_keys;
	    zbyte c;

	    do {
		LOW_BYTE (addr, c)
		if (c == 255 || key == translate_from_zscii (c))
		    return TRUE;
		addr++;
	    } while (c != 0);

	}

    return FALSE;

}/* is_terminator */

/*
 * z_make_menu, add or remove a menu and branch if successful.
 *
 * 	zargs[0] = number of menu
 *	zargs[1] = table of menu entries or 0 to remove menu
 *
 */

void z_make_menu (void)
{

    /* This opcode was only used for the Macintosh version of Journey.
       It controls menus with numbers greater than 2 (menus 0, 1 and 2
       are system menus). Frotz doesn't implement menus yet. */

    branch (FALSE);

}/* z_make_menu */

/*
 * read_yes_or_no
 *
 * Ask the user a question; return true if the answer is yes.
 *
 */

bool read_yes_or_no (const char *s)
{
    zchar key;

    print_string (s);
    print_string ("? (y/n) >");

    key = stream_read_key (0, 0, FALSE);

    if (key == 'y' || key == 'Y') {
	print_string ("y\n");
	return TRUE;
    } else {
	print_string ("n\n");
	return FALSE;
    }

}/* read_yes_or_no */

/*
 * read_string
 *
 * Read a string from the current input stream.
 *
 */

void read_string (int max, zchar *buffer)
{
    zchar key;

    buffer[0] = 0;

    do {

	key = stream_read_input (max, buffer, 0, 0, FALSE, FALSE);

    } while (key != ZC_RETURN);

}/* read_string */

/*
 * read_number
 *
 * Ask the user to type in a number and return it.
 *
 */

int read_number (void)
{
    zchar buffer[6];
    int value = 0;
    int i;

    read_string (5, buffer);

    for (i = 0; buffer[i] != 0; i++)
	if (buffer[i] >= '0' && buffer[i] <= '9')
	    value = 10 * value + buffer[i] - '0';

    return value;

}/* read_number */

/*
 * z_read, read a line of input and (in V5+) store the terminating key.
 *
 *	zargs[0] = address of text buffer
 *	zargs[1] = address of token buffer
 *	zargs[2] = timeout in tenths of a second (optional)
 *	zargs[3] = packed address of routine to be called on timeout
 *
 */

void z_read (void)
{
    zchar buffer[INPUT_BUFFER_SIZE];
    zword addr;
    zchar key;
    zbyte max, size;
    zbyte c;
    int i;

    /* Supply default arguments */

    if (zargc < 3)
	zargs[2] = 0;

    /* Get maximum input size */

    addr = zargs[0];

    LOW_BYTE (addr, max)

    if (h_version <= V4)
	max--;

    if (max >= INPUT_BUFFER_SIZE)
	max = INPUT_BUFFER_SIZE - 1;

    /* Get initial input size */

    if (h_version >= V5) {
	addr++;
	LOW_BYTE (addr, size)
    } else size = 0;

    /* Copy initial input to local buffer */

    for (i = 0; i < size; i++) {
	addr++;
	LOW_BYTE (addr, c)
	buffer[i] = translate_from_zscii (c);
    }

    buffer[i] = 0;

    /* Draw status line for V1 to V3 games */

    if (h_version <= V3)
	z_show_status ();

    /* Read input from current input stream */

    key = stream_read_input (
	max, buffer,		/* buffer and size */
	zargs[2],		/* timeout value   */
	zargs[3],		/* timeout routine */
	TRUE,	        	/* enable hot keys */
	h_version == V6);	/* no script in V6 */

    if (key == ZC_BAD)
	return;

    /* Perform save_undo for V1 to V4 games */

    if (h_version <= V4)
	save_undo ();

    /* Copy local buffer back to dynamic memory */

    for (i = 0; buffer[i] != 0; i++) {

	if (key == ZC_RETURN) {

	    if (buffer[i] >= 'A' && buffer[i] <= 'Z')
		buffer[i] += 'a' - 'A';
	    if (buffer[i] >= 0xc0 && buffer[i] <= 0xde && buffer[i] != 0xd7)
		buffer[i] += 0x20;

	}

	storeb ((zword) (zargs[0] + ((h_version <= V4) ? 1 : 2) + i), translate_to_zscii (buffer[i]));

    }

    /* Add null character (V1-V4) or write input length into 2nd byte */

    if (h_version <= V4)
	storeb ((zword) (zargs[0] + 1 + i), 0);
    else
	storeb ((zword) (zargs[0] + 1), i);

    /* Tokenise line if a token buffer is present */

    if (key == ZC_RETURN && zargs[1] != 0)
	tokenise_line (zargs[0], zargs[1], 0, FALSE);

    /* Store key */

    if (h_version >= V5)
	store (translate_to_zscii (key));

}/* z_read */

/*
 * z_read_char, read and store a key.
 *
 *	zargs[0] = input device (must be 1)
 *	zargs[1] = timeout in tenths of a second (optional)
 *	zargs[2] = packed address of routine to be called on timeout
 *
 */

void z_read_char (void)
{
    zchar key;

    /* Supply default arguments */

    if (zargc < 2)
	zargs[1] = 0;

    /* Read input from the current input stream */

    key = stream_read_key (
	zargs[1],	/* timeout value   */
	zargs[2],	/* timeout routine */
	TRUE);  	/* enable hot keys */

    if (key == ZC_BAD)
	return;

    /* Store key */

    store (translate_to_zscii (key));

}/* z_read_char */

/*
 * z_read_mouse, write the current mouse status into a table.
 *
 *	zargs[0] = address of table
 *
 */

void z_read_mouse (void)
{

    storew ((zword) (zargs[0] + 0), hx_mouse_y);
    storew ((zword) (zargs[0] + 2), hx_mouse_x);
    storew ((zword) (zargs[0] + 4), 1);		/* mouse button bits */
    storew ((zword) (zargs[0] + 6), 0);		/* menu selection */

}/* z_read_mouse */
