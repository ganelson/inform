/*
 * screen.c
 *
 * Generic screen manipulation
 *
 */

#include "frotz.h"

extern void set_header_extension (int, zword);

extern int direct_call (zword);

static struct {
    enum story story_id;
    int pic;
    int pic1;
    int pic2;
} mapper[] = {
    { ZORK_ZERO,  5, 497, 498 },
    { ZORK_ZERO,  6, 501, 502 },
    { ZORK_ZERO,  7, 499, 500 },
    { ZORK_ZERO,  8, 503, 504 },
    {    ARTHUR, 54, 170, 171 },
    {    SHOGUN, 50,  61,  62 },
    {   UNKNOWN,  0,   0,   0 }
};

static font_height = 1;
static font_width = 1;

static bool input_redraw = FALSE;
static bool more_prompts = TRUE;
static bool discarding = FALSE;
static bool cursor = TRUE;

static input_window = 0;

static struct {
    zword y_pos;
    zword x_pos;
    zword y_size;
    zword x_size;
    zword y_cursor;
    zword x_cursor;
    zword left;
    zword right;
    zword nl_routine;
    zword nl_countdown;
    zword style;
    zword colour;
    zword font;
    zword font_size;
    zword attribute;
    zword line_count;
} wp[8], *cwp;

/*
 * winarg0
 *
 * Return the window number in zargs[0]. In V6 only, -3 refers to the
 * current window.
 *
 */

static zword winarg0 (void)
{

    if (h_version == V6 && (short) zargs[0] == -3)
	return cwin;

    if (zargs[0] >= ((h_version == V6) ? 8 : 2))
	runtime_error ("Illegal window");

    return zargs[0];

}/* winarg0 */

/*
 * winarg2
 *
 * Return the (optional) window number in zargs[2]. -3 refers to the
 * current window. This optional window number was only used by some
 * V6 opcodes: set_cursor, set_margins, set_colour.
 *
 */

static zword winarg2 (void)
{

    if (zargc < 3 || (short) zargs[2] == -3)
	return cwin;

    if (zargs[2] >= 8)
	runtime_error ("Illegal window");

    return zargs[2];

}/* winarg2 */

/*
 * update_cursor
 *
 * Move the hardware cursor to make it match the window properties.
 *
 */

static void update_cursor (void)
{

    os_set_cursor (
	cwp->y_pos + cwp->y_cursor - 1,
	cwp->x_pos + cwp->x_cursor - 1);

}/* update_cursor */

/*
 * reset_cursor
 *
 * Reset the cursor of a given window to its initial position.
 *
 */

static void reset_cursor (zword win)
{
    int lines = 0;

    if (h_version <= V4 && win == 0)
	lines = wp[0].y_size / hi (wp[0].font_size) - 1;

    wp[win].y_cursor = hi (wp[0].font_size) * lines + 1;
    wp[win].x_cursor = wp[win].left + 1;

    if (win == cwin)
	update_cursor ();

}/* reset_cursor */

/*
 * set_more_prompts
 *
 * Turn more prompts on/off.
 *
 */

void set_more_prompts (bool flag)
{

    if (flag && !more_prompts)
	cwp->line_count = 0;

    more_prompts = flag;

}/* set_more_prompts */

/*
 * units_left
 *
 * Return the #screen units from the cursor to the end of the line.
 *
 */

static int units_left (void)
{

    return cwp->x_size - cwp->right - cwp->x_cursor + 1;

}/* units_left */

/*
 * get_max_width
 *
 * Return maximum width of a line in the given window. This is used in
 * connection with the extended output stream #3 call in V6.
 *
 */

zword get_max_width (zword win)
{

    if (h_version == V6) {

	if (win >= 8)
	    runtime_error ("Illegal window");

	return wp[win].x_size - wp[win].left - wp[win].right;

    } else return 0xffff;

}/* get_max_width */

/*
 * countdown
 *
 * Decrement the newline counter. Call the newline interrupt when the
 * counter hits zero. This is a helper function for screen_new_line.
 *
 */

static void countdown (void)
{

    if (cwp->nl_countdown != 0)
	if (--cwp->nl_countdown == 0)
	    direct_call (cwp->nl_routine);

}/* countdown */

/*
 * screen_new_line
 *
 * Print a newline to the screen.
 *
 */

void screen_new_line (void)
{

    if (discarding) return;

    /* Handle newline interrupts at the start (for most cases) */

    if (h_interpreter_number != INTERP_MSDOS || story_id != ZORK_ZERO || h_release != 393)
	countdown ();

    /* Check whether the last input line gets destroyed */

    if (input_window == cwin)
	input_redraw = TRUE;

    /* If the cursor has not reached the bottom line, then move it to
       the next line; otherwise scroll the window or reset the cursor
       to the top left. */

    cwp->x_cursor = cwp->left + 1;

    if (cwp->y_cursor + 2 * font_height - 1 > cwp->y_size)

	if (enable_scrolling) {

	    zword y = cwp->y_pos;
	    zword x = cwp->x_pos;

	    os_scroll_area (y,
			    x,
			    y + cwp->y_size - 1,
			    x + cwp->x_size - 1,
			    font_height);

	} else cwp->y_cursor = 1;

    else cwp->y_cursor += font_height;

    update_cursor ();

    /* See if we need to print a more prompt (unless the game has set
       the line counter to -999 in order to suppress more prompts). */

    if (enable_scrolling && (short) cwp->line_count != -999) {

	zword above = (cwp->y_cursor - 1) / font_height;
	zword below = (cwp->y_size - cwp->y_cursor + 1) / font_height;

	cwp->line_count++;

	if ((short) cwp->line_count >= (short) above + below - 1) {

	    if (more_prompts)
		os_more_prompt ();

	    cwp->line_count = option_context_lines;

	}

    }

    /* Handle newline interrupts at the end for Zork Zero under DOS */

    if (h_interpreter_number == INTERP_MSDOS && story_id == ZORK_ZERO && h_release == 393)
	countdown ();

}/* screen_new_line */

/*
 * screen_char
 *
 * Display a single character on the screen.
 *
 */

void screen_char (zchar c)
{
    int width;

    if (discarding) return;

    if (c == ZC_INDENT && cwp->x_cursor != cwp->left + 1)
	c = ' ';

    if (units_left () < (width = os_char_width (c))) {

	if (!enable_wrapping)
	    { cwp->x_cursor = cwp->x_size - cwp->right; return; }

	screen_new_line ();

    }

    os_display_char (c); cwp->x_cursor += width;

}/* screen_char */

/*
 * screen_word
 *
 * Display a string of characters on the screen. If the word doesn't fit
 * then use wrapping or clipping depending on the current setting of the
 * enable_wrapping flag.
 *
 */

void screen_word (const zchar *s)
{
    int width;

    if (discarding) return;

    if (*s == ZC_INDENT && cwp->x_cursor != cwp->left + 1)
	screen_char (*s++);

    if (units_left () < (width = os_string_width (s))) {

	if (!enable_wrapping) {

	    zchar c;

	    while ((c = *s++) != 0)

		if (c == ZC_NEW_FONT || c == ZC_NEW_STYLE) {

		    int arg = (int) *s++;

		    if (c == ZC_NEW_FONT)
			os_set_font (arg);
		    if (c == ZC_NEW_STYLE)
			os_set_text_style (arg);

		} else screen_char (c);

	    return;

	}

	if (*s == ' ' || *s == ZC_INDENT || *s == ZC_GAP)
	    width = os_string_width (++s);

#ifdef AMIGA
	if (cwin == 0) Justifiable ();
#endif

	screen_new_line ();

    }

    os_display_string (s); cwp->x_cursor += width;

}/* screen_word */

/*
 * screen_write_input
 *
 * Display an input line on the screen. This is required during playback.
 *
 */

void screen_write_input (const zchar *buf, zchar key)
{
    int width;

    if (units_left () < (width = os_string_width (buf)))
	screen_new_line ();

    os_display_string (buf); cwp->x_cursor += width;

    if (key == ZC_RETURN)
	screen_new_line ();

}/* screen_write_input */

/*
 * screen_erase_input
 *
 * Remove an input line that has already been printed from the screen
 * as if it was deleted by the player. This could be necessary during
 * playback.
 *
 */

void screen_erase_input (const zchar *buf)
{

    if (buf[0] != 0) {

	int width = os_string_width (buf);

	zword y;
	zword x;

	cwp->x_cursor -= width;

	y = cwp->y_pos + cwp->y_cursor - 1;
	x = cwp->x_pos + cwp->x_cursor - 1;

	os_erase_area (y, x, y + font_height - 1, x + width - 1);
	os_set_cursor (y, x);

    }

}/* screen_erase_input */

/*
 * console_read_input
 *
 * Read an input line from the keyboard and return the terminating key.
 *
 */

zchar console_read_input (int max, zchar *buf, zword timeout, bool continued)
{
    zchar key;
    int i;

    /* Make sure there is some space for input */

    if (cwin == 0 && units_left () + os_string_width (buf) < 10 * font_width)
	screen_new_line ();

    /* Make sure the input line is visible */

    if (continued && input_redraw)
	screen_write_input (buf, -1);

    input_window = cwin;
    input_redraw = FALSE;

    /* Get input line from IO interface */

    cwp->x_cursor -= os_string_width (buf);
    key = os_read_line (max, buf, timeout, units_left (), continued);
    cwp->x_cursor += os_string_width (buf);

    if (key != ZC_TIME_OUT)
	for (i = 0; i < 8; i++)
	    wp[i].line_count = 0;

    /* Add a newline if the input was terminated normally */

    if (key == ZC_RETURN)
	screen_new_line ();

    return key;

}/* console_read_input */

/*
 * console_read_key
 *
 * Read a single keystroke and return it.
 *
 */

zchar console_read_key (zword timeout)
{
    zchar key;
    int i;

    key = os_read_key (timeout, cursor);

    if (key != ZC_TIME_OUT)
	for (i = 0; i < 8; i++)
	    wp[i].line_count = 0;

    return key;

}/* console_read_key */

/*
 * update_attributes
 *
 * Set the three enable_*** variables to make them match the attributes
 * of the current window.
 *
 */

static void update_attributes (void)
{
    zword attr = cwp->attribute;

    enable_wrapping = attr & 1;
    enable_scrolling = attr & 2;
    enable_scripting = attr & 4;
    enable_buffering = attr & 8;

    /* Some story files forget to select wrapping for printing hints */

    if (story_id == ZORK_ZERO && h_release == 366)
	if (cwin == 0)
	    enable_wrapping = TRUE;
    if (story_id == SHOGUN && h_release <= 295)
	if (cwin == 0)
	    enable_wrapping = TRUE;

}/* update_attributes */

/*
 * refresh_text_style
 *
 * Set the right text style. This can be necessary when the fixed font
 * flag is changed, or when a new window is selected, or when the game
 * uses the set_text_style opcode.
 *
 */

void refresh_text_style (void)
{
    zword style;

    if (h_version != V6) {

	style = wp[0].style;

	if (cwin != 0 || h_flags & FIXED_FONT_FLAG)
	    style |= FIXED_WIDTH_STYLE;

    } else style = cwp->style;

    if (!ostream_memory && ostream_screen && enable_buffering) {

	print_char (ZC_NEW_STYLE);
	print_char (style);

    } else os_set_text_style (style);

}/* refresh_text_style */

/*
 * set_window
 *
 * Set the current window. In V6 every window has its own set of window
 * properties such as colours, text style, cursor position and size.
 *
 */

static void set_window (zword win)
{

    flush_buffer ();

    cwin = win; cwp = wp + win;

    update_attributes ();

    if (h_version == V6) {

	os_set_colour (lo (cwp->colour), hi (cwp->colour));

	if (os_font_data (cwp->font, &font_height, &font_width))
	    os_set_font (cwp->font);

	os_set_text_style (cwp->style);

    } else refresh_text_style ();

    if (h_version != V6 && win != 0) {
	wp[win].y_cursor = 1;
	wp[win].x_cursor = 1;
    }

    update_cursor ();

}/* set_window */

/*
 * erase_window
 *
 * Erase a window to background colour.
 *
 */

static void erase_window (zword win)
{
    zword y = wp[win].y_pos;
    zword x = wp[win].x_pos;

    if (h_version == V6 && win != cwin && h_interpreter_number != INTERP_AMIGA)
	os_set_colour (lo (wp[win].colour), hi (wp[win].colour));

    os_erase_area (y,
		   x,
		   y + wp[win].y_size - 1,
		   x + wp[win].x_size - 1);

    if (h_version == V6 && win != cwin && h_interpreter_number != INTERP_AMIGA)
	os_set_colour (lo (cwp->colour), hi (cwp->colour));

    reset_cursor (win);

    wp[win].line_count = 0;

}/* erase_window */

/*
 * split_window
 *
 * Divide the screen into upper (1) and lower (0) windows. In V3 the upper
 * window appears below the status line.
 *
 */

void split_window (zword height)
{
    zword stat_height = 0;

    flush_buffer ();

    /* Calculate height of status line and upper window */

    if (h_version != V6)
	height *= hi (wp[1].font_size);

    if (h_version <= V3)
	stat_height = hi (wp[7].font_size);

    /* Cursor of upper window mustn't be swallowed by the lower window */

    wp[1].y_cursor += wp[1].y_pos - 1 - stat_height;

    wp[1].y_pos = 1 + stat_height;
    wp[1].y_size = height;

    if ((short) wp[1].y_cursor > (short) wp[1].y_size)
	reset_cursor (1);

    /* Cursor of lower window mustn't be swallowed by the upper window */

    wp[0].y_cursor += wp[0].y_pos - 1 - stat_height - height;

    wp[0].y_pos = 1 + stat_height + height;
    wp[0].y_size = h_screen_height - stat_height - height;

    if ((short) wp[0].y_cursor < 1)
	reset_cursor (0);

    /* Erase the upper window in V3 only */

    if (h_version == V3 && height != 0)
	erase_window (1);

}/* split_window */

/*
 * erase_screen
 *
 * Erase the entire screen to background colour.
 *
 */

static void erase_screen (zword win)
{
    int i;

    os_erase_area (1, 1, h_screen_height, h_screen_width);

    if ((short) win == -1) {
	split_window (0);
	set_window (0);
	reset_cursor (0);
    }

    for (i = 0; i < 8; i++)
	wp[i].line_count = 0;

}/* erase_screen */

#ifdef AMIGA

/*
 * resize_screen
 *
 * Try to adapt the window properties to a new screen size.
 *
 */

void resize_screen (void)
{

    if (h_version != V6) {

	wp[0].x_size = h_screen_width;
	wp[1].x_size = h_screen_width;
	wp[7].x_size = h_screen_width;

	wp[0].y_size = h_screen_height - wp[1].y_size - wp[7].y_size;

    }

}/* resize_screen */

#endif

/*
 * restart_screen
 *
 * Prepare the screen for a new game.
 *
 */

void restart_screen (void)
{

    /* Use default settings */

    os_set_colour (h_default_foreground, h_default_background);

    if (os_font_data (TEXT_FONT, &font_height, &font_width))
	os_set_font (TEXT_FONT);

    os_set_text_style (0);

    cursor = TRUE;

    /* Initialise window properties */

    mwin = 1;

    for (cwp = wp; cwp < wp + 8; cwp++) {
	cwp->y_pos = 1;
	cwp->x_pos = 1;
	cwp->y_size = 0;
	cwp->x_size = 0;
	cwp->y_cursor = 1;
	cwp->x_cursor = 1;
	cwp->left = 0;
	cwp->right = 0;
	cwp->nl_routine = 0;
	cwp->nl_countdown = 0;
	cwp->style = 0;
	cwp->colour = (h_default_background << 8) | h_default_foreground;
	cwp->font = TEXT_FONT;
	cwp->font_size = (font_height << 8) | font_width;
	cwp->attribute = 8;
    }

    /* Prepare lower/upper windows and status line */

    wp[0].attribute = 15;

    wp[0].left = option_left_margin;
    wp[0].right = option_right_margin;

    wp[0].x_size = h_screen_width;
    wp[1].x_size = h_screen_width;

    if (h_version <= V3)
	wp[7].x_size = h_screen_width;

    os_restart_game (RESTART_WPROP_SET);

    /* Clear the screen, unsplit it and select window 0 */

    erase_screen ((zword) (-1));

}/* restart_screen */

/*
 * validate_click
 *
 * Return false if the last mouse click occured outside the current
 * mouse window; otherwise write the mouse arrow coordinates to the
 * memory of the header extension table and return true.
 *
 */

bool validate_click (void)
{

    if (mwin >= 0) {

	if (mouse_y < wp[mwin].y_pos || mouse_y >= wp[mwin].y_pos + wp[mwin].y_size)
	    return FALSE;
	if (mouse_x < wp[mwin].x_pos || mouse_x >= wp[mwin].x_pos + wp[mwin].x_size)
	    return FALSE;

	hx_mouse_y = mouse_y - wp[mwin].y_pos + 1;
	hx_mouse_x = mouse_x - wp[mwin].x_pos + 1;

    } else {

	if (mouse_y < 1 || mouse_y > h_screen_height)
	    return FALSE;
	if (mouse_x < 1 || mouse_x > h_screen_width)
	    return FALSE;

	hx_mouse_y = mouse_y;
	hx_mouse_x = mouse_x;

    }

    if (h_version != V6) {
	hx_mouse_y = (hx_mouse_y - 1) / h_font_height + 1;
	hx_mouse_x = (hx_mouse_x - 1) / h_font_width + 1;
    }

    set_header_extension (HX_MOUSE_Y, hx_mouse_y);
    set_header_extension (HX_MOUSE_X, hx_mouse_x);

    return TRUE;

}/* validate_click */

/*
 * screen_mssg_on
 *
 * Start printing a so-called debugging message. The contents of the
 * message are passed to the message stream, a Frotz specific output
 * stream with maximum priority.
 *
 */

void screen_mssg_on (void)
{

    if (cwin == 0) {		/* messages in window 0 only */

	os_set_text_style (0);

	if (cwp->x_cursor != cwp->left + 1)
	    screen_new_line ();

	screen_char (ZC_INDENT);

    } else discarding = TRUE; 	/* discard messages in other windows */

}/* screen_mssg_on */

/*
 * screen_mssg_off
 *
 * Stop printing a "debugging" message.
 *
 */

void screen_mssg_off (void)
{

    if (cwin == 0) {		/* messages in window 0 only */

	screen_new_line ();

	refresh_text_style ();

    } else discarding = FALSE; 	/* message has been discarded */

}/* screen_mssg_off */

/*
 * z_buffer_mode, turn text buffering on/off.
 *
 *	zargs[0] = new text buffering flag (0 or 1)
 *
 */

void z_buffer_mode (void)
{

    /* Infocom's V6 games rarely use the buffer_mode opcode. If they do
       then only to print text immediately, without any delay. This was
       used to give the player some sign of life while the game was
       spending much time on parsing a complicated input line. (To turn
       off word wrapping, V6 games use the window_style opcode instead.)
       Today we can afford to ignore buffer_mode in V6. */

    if (h_version != V6) {

	flush_buffer ();

	wp[0].attribute &= ~8;

	if (zargs[0] != 0)
	    wp[0].attribute |= 8;

	update_attributes ();

    }

}/* z_buffer_mode */

/*
 * z_draw_picture, draw a picture.
 *
 *	zargs[0] = number of picture to draw
 *	zargs[1] = y-coordinate of top left corner
 *	zargs[2] = x-coordinate of top left corner
 *
 */

void z_draw_picture (void)
{
    zword pic = zargs[0];

    zword y = zargs[1];
    zword x = zargs[2];

    int i;

    flush_buffer ();

    if (y == 0)			/* use cursor line if y-coordinate is 0 */
	y = cwp->y_cursor;
    if (x == 0)    		/* use cursor column if x-coordinate is 0 */
	x = cwp->x_cursor;

    y += cwp->y_pos - 1;
    x += cwp->x_pos - 1;

    /* The following is necessary to make Amiga and Macintosh story
       files work with MCGA graphics files.  Some screen-filling
       pictures of the original Amiga release like the borders of
       Zork Zero were split into several MCGA pictures (left, right
       and top borders).  We pretend this has not happened. */

    for (i = 0; mapper[i].story_id != UNKNOWN; i++)

	if (story_id == mapper[i].story_id && pic == mapper[i].pic) {

	    int height1, width1;
	    int height2, width2;

	    int delta = 0;

	    os_picture_data (pic, &height1, &width1);
	    os_picture_data (mapper[i].pic2, &height2, &width2);

	    if (story_id == ARTHUR && pic == 54)
		delta = h_screen_width / 160;

	    os_draw_picture (mapper[i].pic1, y + height1, x + delta);
	    os_draw_picture (mapper[i].pic2, y + height1, x + width1 - width2 - delta);

	}

    os_draw_picture (pic, y, x);

    if (story_id == SHOGUN)

	if (pic == 3) {

	    int height, width;

	    os_picture_data (59, &height, &width);
	    os_draw_picture (59, y, h_screen_width - width + 1);

	}

}/* z_draw_picture */

/*
 * z_erase_line, erase the line starting at the cursor position.
 *
 *	zargs[0] = 1 + #units to erase (1 clears to the end of the line)
 *
 */

void z_erase_line (void)
{
    zword pixels = zargs[0];
    zword y, x;

    flush_buffer ();

    /* Clipping at the right margin of the current window */

    if (--pixels == 0 || pixels > units_left ())
	pixels = units_left ();

    /* Erase from cursor position */

    y = cwp->y_pos + cwp->y_cursor - 1;
    x = cwp->x_pos + cwp->x_cursor - 1;

    os_erase_area (y, x, y + font_height - 1, x + pixels - 1);

}/* z_erase_line */

/*
 * z_erase_picture, erase a picture with background colour.
 *
 *	zargs[0] = number of picture to erase
 *	zargs[1] = y-coordinate of top left corner (optional)
 *	zargs[2] = x-coordinate of top left corner (optional)
 *
 */

void z_erase_picture (void)
{
    int height, width;

    zword y = zargs[1];
    zword x = zargs[2];

    flush_buffer ();

    if (y == 0)		/* use cursor line if y-coordinate is 0 */
	y = cwp->y_cursor;
    if (x == 0)    	/* use cursor column if x-coordinate is 0 */
	x = cwp->x_cursor;

    os_picture_data (zargs[0], &height, &width);

    y += cwp->y_pos - 1;
    x += cwp->x_pos - 1;

    os_erase_area (y, x, y + height - 1, x + width - 1);

}/* z_erase_picture */

/*
 * z_erase_window, erase a window or the screen to background colour.
 *
 *	zargs[0] = window (-3 current, -2 screen, -1 screen & unsplit)
 *
 */

void z_erase_window (void)
{

    flush_buffer ();

    if ((short) zargs[0] == -1 || (short) zargs[0] == -2)
	erase_screen (zargs[0]);
    else
	erase_window (winarg0 ());

}/* z_erase_window */

/*
 * z_get_cursor, write the cursor coordinates into a table.
 *
 *	zargs[0] = address to write information to
 *
 */

void z_get_cursor (void)
{
    zword y, x;

    flush_buffer ();

    y = cwp->y_cursor;
    x = cwp->x_cursor;

    if (h_version != V6) {	/* convert to grid positions */
	y = (y - 1) / h_font_height + 1;
	x = (x - 1) / h_font_width + 1;
    }

    storew ((zword) (zargs[0] + 0), y);
    storew ((zword) (zargs[0] + 2), x);

}/* z_get_cursor */

/*
 * z_get_wind_prop, store the value of a window property.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = number of window property to be stored
 *
 */

void z_get_wind_prop (void)
{

    flush_buffer ();

    if (zargs[1] >= 16)
	runtime_error ("Illegal window property");

    store (((zword *) (wp + winarg0 ())) [zargs[1]]);

}/* z_get_wind_prop */

/*
 * z_mouse_window, select a window as mouse window.
 *
 *	zargs[0] = window number (-3 is the current) or -1 for the screen
 *
 */

void z_mouse_window (void)
{

    mwin = ((short) zargs[0] == -1) ? -1 : winarg0 ();

}/* z_mouse_window */

/*
 * z_move_window, place a window on the screen.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = y-coordinate
 *	zargs[2] = x-coordinate
 *
 */

void z_move_window (void)
{
    zword win = winarg0 ();

    flush_buffer ();

    wp[win].y_pos = zargs[1];
    wp[win].x_pos = zargs[2];

    if (win == cwin)
	update_cursor ();

}/* z_move_window */

/*
 * z_picture_data, get information on a picture or the graphics file.
 *
 *	zargs[0] = number of picture or 0 for the graphics file
 *	zargs[1] = address to write information to
 *
 */

void z_picture_data (void)
{
    zword pic = zargs[0];
    zword table = zargs[1];

    int height, width;
    int i;

    bool avail = os_picture_data (pic, &height, &width);

    for (i = 0; mapper[i].story_id != UNKNOWN; i++)

	if (story_id == mapper[i].story_id)

	    if (pic == mapper[i].pic) {

		int height2, width2;

		avail &= os_picture_data (mapper[i].pic1, &height2, &width2);
		avail &= os_picture_data (mapper[i].pic2, &height2, &width2);

		height += height2;

	    } else if (pic == mapper[i].pic1 || pic == mapper[i].pic2)

		avail = FALSE;

    storew ((zword) (table + 0), (zword) (height));
    storew ((zword) (table + 2), (zword) (width));

    branch (avail);

}/* z_picture_data */

/*
 * z_picture_table, prepare a group of pictures for faster display.
 *
 *	zargs[0] = address of table holding the picture numbers
 *
 */

void z_picture_table (void)
{

    /* This opcode is used by Shogun and Zork Zero when the player
       encounters built-in games such as Peggleboz. Nowadays it is
       not very helpful to hold the picture data in memory because
       even a small disk cache avoids re-loading of data. */

}/* z_picture_table */

/*
 * z_print_table, print ASCII text in a rectangular area.
 *
 *	zargs[0] = address of text to be printed
 *	zargs[1] = width of rectangular area
 *	zargs[2] = height of rectangular area (optional)
 *	zargs[3] = number of char's to skip between lines (optional)
 *
 */

void z_print_table (void)
{
    zword addr = zargs[0];
    zword x;
    int i, j;

    flush_buffer ();

    /* Supply default arguments */

    if (zargc < 3)
	zargs[2] = 1;
    if (zargc < 4)
	zargs[3] = 0;

    /* Write text in width x height rectangle */

    x = cwp->x_cursor;

    for (i = 0; i < zargs[2]; i++) {

	if (i != 0) {

	    flush_buffer ();

	    cwp->y_cursor += font_height;
	    cwp->x_cursor = x;

	    update_cursor ();

	}

	for (j = 0; j < zargs[1]; j++) {

	    zbyte c;

	    LOW_BYTE (addr, c)
	    addr++;

	    print_char (c);

	}

	addr += zargs[3];

    }

}/* z_print_table */

/*
 * z_put_wind_prop, set the value of a window property.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = number of window property to set
 *	zargs[2] = value to set window property to
 *
 */

void z_put_wind_prop (void)
{

    flush_buffer ();

    if (zargs[1] >= 16)
	runtime_error ("Illegal window property");

    ((zword *) (wp + winarg0 ())) [zargs[1]] = zargs[2];

}/* z_put_wind_prop */

/*
 * z_scroll_window, scroll a window up or down.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = #screen units to scroll up (positive) or down (negative)
 *
 */

void z_scroll_window (void)
{
    zword win = winarg0 ();
    zword y, x;

    flush_buffer ();

    /* Use the correct set of colours when scrolling the window */

    if (win != cwin && h_interpreter_number != INTERP_AMIGA)
	os_set_colour (lo (wp[win].colour), hi (wp[win].colour));

    y = wp[win].y_pos;
    x = wp[win].x_pos;

    os_scroll_area (y,
		    x,
		    y + wp[win].y_size - 1,
		    x + wp[win].x_size - 1,
		    (short) zargs[1]);

    if (win != cwin && h_interpreter_number != INTERP_AMIGA)
	os_set_colour (lo (cwp->colour), hi (cwp->colour));

}/* z_scroll_window */

/*
 * z_set_colour, set the foreground and background colours.
 *
 *	zargs[0] = foreground colour
 *	zargs[1] = background colour
 *	zargs[2] = window (-3 is the current one, optional)
 *
 */

void z_set_colour (void)
{
    zword win = (h_version == V6) ? winarg2 () : 0;

    zword fg = zargs[0];
    zword bg = zargs[1];

    flush_buffer ();

    if ((short) fg == -1)	/* colour -1 is the colour at the cursor */
	fg = os_peek_colour ();
    if ((short) bg == -1)
	bg = os_peek_colour ();

    if (fg == 0)		/* colour 0 means keep current colour */
	fg = lo (wp[win].colour);
    if (bg == 0)
	bg = hi (wp[win].colour);

    if (fg == 1)		/* colour 1 is the system default colour */
	fg = h_default_foreground;
    if (bg == 1)
	bg = h_default_background;

    if (h_version == V6 && h_interpreter_number == INTERP_AMIGA)

	/* Changing colours of window 0 affects the entire screen */

	if (win == 0) {

	    int i;

	    for (i = 1; i < 8; i++) {

		zword bg2 = hi (wp[i].colour);
		zword fg2 = lo (wp[i].colour);

		if (bg2 < 16)
		    bg2 = (bg2 == lo (wp[0].colour)) ? fg : bg;
		if (fg2 < 16)
		    fg2 = (fg2 == lo (wp[0].colour)) ? fg : bg;

		wp[i].colour = (bg2 << 8) | fg2;

	    }

	}

    wp[win].colour = (bg << 8) | fg;

    if (win == cwin || h_version != V6)
	os_set_colour (fg, bg);

}/* z_set_colour */

/*
 * z_set_font, set the font for text output and store the previous font.
 *
 * 	zargs[0] = number of font or 0 to keep current font
 *
 */

void z_set_font (void)
{
    zword win = (h_version == V6) ? cwin : 0;
    zword font = zargs[0];

    if (font != 0) {

	if (story_id == JOURNEY && font == 4)	/* Journey uses fixed fonts */
	    font = 1;				/* for most interpreter #'s */

	if (os_font_data (font, &font_height, &font_width)) {

	    store (wp[win].font);

	    wp[win].font = font;
	    wp[win].font_size = (font_height << 8) | font_width;

	    if (!ostream_memory && ostream_screen && enable_buffering) {

		print_char (ZC_NEW_FONT);
		print_char (font);

	    } else os_set_font (font);

	} else store (0);

    } else store (wp[win].font);

}/* z_set_font */

/*
 * z_set_cursor, set the cursor position or turn the cursor on/off.
 *
 *	zargs[0] = y-coordinate or -2/-1 for cursor on/off
 *	zargs[1] = x-coordinate
 *	zargs[2] = window (-3 is the current one, optional)
 *
 */

void z_set_cursor (void)
{
    zword win = (h_version == V6) ? winarg2 () : 1;

    zword y = zargs[0];
    zword x = zargs[1];

    flush_buffer ();

    /* Supply default arguments */

    if (zargc < 3)
	zargs[2] = -3;

    /* Handle cursor on/off */

    if ((short) y < 0) {

	if ((short) y == -2)
	    cursor = TRUE;
	if ((short) y == -1)
	    cursor = FALSE;

	return;

    }

    /* Convert grid positions to screen units if this is not V6 */

    if (h_version != V6) {

	if (cwin == 0)
	    return;

	y = (y - 1) * h_font_height + 1;
	x = (x - 1) * h_font_width + 1;

    }

    /* Protect the margins */

    if (x <= wp[win].left || x > wp[win].x_size - wp[win].right)
	x = wp[win].left + 1;

    /* Move the cursor */

    wp[win].y_cursor = y;
    wp[win].x_cursor = x;

    if (win == cwin)
	update_cursor ();

}/* z_set_cursor */

/*
 * z_set_margins, set the left and right margins of a window.
 *
 *	zargs[0] = left margin in pixels
 *	zargs[1] = right margin in pixels
 *	zargs[2] = window (-3 is the current one, optional)
 *
 */

void z_set_margins (void)
{
    zword win = winarg2 ();

    flush_buffer ();

    wp[win].left = zargs[0];
    wp[win].right = zargs[1];

    /* Protect the margins */

    if (wp[win].x_cursor <= zargs[0] || wp[win].x_cursor > wp[win].x_size - zargs[1]) {

	wp[win].x_cursor = zargs[0] + 1;

	if (win == cwin)
	    update_cursor ();

    }

}/* z_set_margins */

/*
 * z_set_text_style, set the style for text output.
 *
 * 	zargs[0] = style flags to set or 0 to reset text style
 *
 */

void z_set_text_style (void)
{
    zword win = (h_version == V6) ? cwin : 0;
    zword style = zargs[0];

    wp[win].style |= style;

    if (style == 0)
	wp[win].style = 0;

    refresh_text_style ();

}/* z_set_text_style */

/*
 * z_set_window, select the current window.
 *
 *	zargs[0] = window to be selected (-3 is the current one)
 *
 */

void z_set_window (void)
{

    set_window (winarg0 ());

}/* z_set_window */

/*
 * pad_status_line
 *
 * Pad the status line with spaces up to the given position.
 *
 */

static void pad_status_line (int column)
{
    int spaces;

    flush_buffer ();

    spaces = units_left () / os_char_width (' ') - column;

    while (spaces--)
	screen_char (' ');

}/* pad_status_line */

/*
 * z_show_status, display the status line for V1 to V3 games.
 *
 *	no zargs used
 *
 */

void z_show_status (void)
{
    zword global0;
    zword global1;
    zword global2;
    zword addr;

    bool brief = FALSE;

    /* One V5 game (Wishbringer Solid Gold) contains this opcode by
       accident, so just return if the version number does not fit */

    if (h_version >= V4)
	return;

    /* Read all relevant global variables from the memory of the
       Z-machine into local variables */

    addr = h_globals;
    LOW_WORD (addr, global0)
    addr += 2;
    LOW_WORD (addr, global1)
    addr += 2;
    LOW_WORD (addr, global2)

    /* Frotz uses window 7 for the status line. Don't forget to select
       reverse and fixed width text style */

    set_window (7);

    print_char (ZC_NEW_STYLE);
    print_char (REVERSE_STYLE | FIXED_WIDTH_STYLE);

    /* If the screen width is below 55 characters then we have to use
       the brief status line format */

    if (h_screen_cols < 55)
	brief = TRUE;

    /* Print the object description for the global variable 0 */

    print_char (' ');
    print_object (global0);

    /* A header flag tells us whether we have to display the current
       time or the score/moves information */

    if (h_config & CONFIG_TIME) {	/* print hours and minutes */

	zword hours = (global1 + 11) % 12 + 1;

	pad_status_line (brief ? 15 : 20);

	print_string ("Time: ");

	if (hours < 10)
	    print_char (' ');
	print_num (hours);

	print_char (':');

	if (global2 < 10)
	    print_char ('0');
	print_num (global2);

	print_char (' ');

	print_char ((global1 >= 12) ? 'p' : 'a');
	print_char ('m');

    } else {				/* print score and moves */

	pad_status_line (brief ? 15 : 30);

	print_string (brief ? "S: " : "Score: ");
	print_num (global1);

	pad_status_line (brief ? 8 : 14);

	print_string (brief ? "M: " : "Moves: ");
	print_num (global2);

    }

    /* Pad the end of the status line with spaces */

    pad_status_line (0);

    /* Return to the lower window */

    set_window (0);

}/* z_show_status */

/*
 * z_split_window, split the screen into an upper (1) and lower (0) window.
 *
 *	zargs[0] = height of upper window in screen units (V6) or #lines
 *
 */

void z_split_window (void)
{

    split_window (zargs[0]);

}/* z_split_window */

/*
 * z_window_size, change the width and height of a window.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = new height in screen units
 *	zargs[2] = new width in screen units
 *
 */

void z_window_size (void)
{
    zword win = winarg0 ();

    flush_buffer ();

    wp[win].y_size = zargs[1];
    wp[win].x_size = zargs[2];

    /* Keep the cursor within the window */

    if (wp[win].y_cursor > zargs[1] || wp[win].x_cursor > zargs[2])
	reset_cursor (win);

}/* z_window_size */

/*
 * z_window_style, set / clear / toggle window attributes.
 *
 *	zargs[0] = window (-3 is the current one)
 *	zargs[1] = window attribute flags
 *	zargs[2] = operation to perform (optional, defaults to 0)
 *
 */

void z_window_style (void)
{
    zword win = winarg0 ();
    zword flags = zargs[1];

    flush_buffer ();

    /* Supply default arguments */

    if (zargc < 3)
	zargs[2] = 0;

    /* Set window style */

    switch (zargs[2]) {
	case 0: wp[win].attribute = flags; break;
	case 1: wp[win].attribute |= flags; break;
	case 2: wp[win].attribute &= ~flags; break;
	case 3: wp[win].attribute ^= flags; break;
    }

    if (cwin == win)
	update_attributes ();

}/* z_window_style */
