#include <stdio.h>
#include <stdlib.h>
#include "glk.h"
#include "cheapglk.h"

/* Since we're not using any kind of cursor movement or terminal 
    emulation, we're dreadfully limited in what kind of windows we
    support. In fact, we can only support one window at a time,
    and that must be a wintype_TextBuffer. Printing to this window
    simply means printing to stdout, and reading from it means
    reading from stdin. (The input code is in glk_select(), and
    the output is in glk_put_char() etc.) */

static window_t *mainwin = NULL;

window_t *gli_new_window(glui32 rock)
{
    window_t *win = (window_t *)malloc(sizeof(window_t));
    if (!win)
        return NULL;
    
    win->magicnum = MAGIC_WINDOW_NUM;
    win->rock = rock;
    
    win->str = gli_new_stream(strtype_Window, FALSE, TRUE, 0);
    win->str->win = win;
    win->echostr = NULL;
    
    win->line_request = FALSE;
    win->char_request = FALSE;
    win->line_request_uni = FALSE;
    win->char_request_uni = FALSE;
    win->linebuf = NULL;
    win->linebuflen = 0;
    
    if (gli_register_obj)
        win->disprock = (*gli_register_obj)(win, gidisp_Class_Window);
    else
        win->disprock.ptr = NULL;
    
    return win;
}

void gli_delete_window(window_t *win)
{
    if (win->linebuf) {
        if (gli_unregister_arr) {
            (*gli_unregister_arr)(win->linebuf, win->linebuflen, "&+#!Cn", 
                win->inarrayrock);
        }
        win->linebuf = NULL;
    }

    if (gli_unregister_obj) {
        (*gli_unregister_obj)(win, gidisp_Class_Window, win->disprock);
        win->disprock.ptr = NULL;
    }
        
    win->magicnum = 0;
    
    /* Close window's stream. */
    gli_delete_stream(mainwin->str);
    mainwin->str = NULL;

    /* The window doesn't own its echostr; closing the window doesn't close
        the echostr. */
    win->echostr = NULL;
    
    free(win);
}

winid_t glk_window_open(winid_t split, glui32 method, glui32 size, 
    glui32 wintype, glui32 rock)
{
    window_t *win;
    
    if (mainwin || split) {
        /* This cheap library only allows you to open a window if there
            aren't any other windows. But it's legal for the program to
            ask for multiple windows. So we don't print a warning; we just
            return NULL. */
        return NULL;
    }
    
    if (wintype != wintype_TextBuffer) {
        /* This cheap library only allows you to open text buffer windows. 
            Again, don't print a warning. */
        return NULL;
    }
    
    win = gli_new_window(rock);
    if (!win) {
        gli_strict_warning("window_open: unable to create window.");
        return NULL;
    }
    
    mainwin = win;
    return mainwin;
}

void glk_window_close(window_t *win, stream_result_t *result)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_close: invalid id.");
        return;
    }
    
    gli_stream_fill_result(mainwin->str, result);
    
    gli_delete_window(mainwin);
    mainwin = NULL;
}

window_t *gli_window_get()
{
    return mainwin;
}

winid_t glk_window_get_root()
{
    /* If there's a window, it's the root window. */
    if (mainwin)
        return mainwin;
    else
        return NULL;
}

winid_t glk_window_iterate(window_t *win, glui32 *rockptr)
{
    /* Iteration is really simple when there can only be one window. */
    
    if (!win) {
        /* They're asking for the first window. Return the main window 
            if it exists, or 0 if there is none. */
        if (!mainwin) {
            if (rockptr)
                *rockptr = 0;
            return NULL;
        }
        
        if (rockptr)
            *rockptr = mainwin->rock;
        return mainwin;
    }
    else if (win == mainwin) {
        /* They're asking for the next window. There is none. */
        if (rockptr)
            *rockptr = 0;
        return NULL;
    }
    else {
        gli_strict_warning("window_iterate: invalid id.");
        return NULL;
    }
}

glui32 glk_window_get_rock(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_rock: invalid id.");
        return 0;
    }
    
    return mainwin->rock;
}

glui32 glk_window_get_type(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_type: invalid id.");
        return 0;
    }
    
    return wintype_TextBuffer;
}

winid_t glk_window_get_parent(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_parent: invalid id.");
        return NULL;
    }
    
    return NULL;
}

winid_t glk_window_get_sibling(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_sibling: invalid id.");
        return NULL;
    }
    
    return NULL;
}

strid_t glk_window_get_stream(window_t *win)
{
    stream_t *str;
    
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_stream: invalid id.");
        return NULL;
    }
    
    str = mainwin->str;
    
    return str;
}

void glk_window_set_echo_stream(window_t *win, stream_t *str)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_set_echo_stream: invalid window id.");
        return;
    }

    mainwin->echostr = str;
}

strid_t glk_window_get_echo_stream(window_t *win)
{
    stream_t *str;
    
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_echo_stream: invalid id.");
        return NULL;
    }
    
    str = mainwin->echostr;
    
    if (str)
        return str;
    else
        return NULL;
}

void glk_set_window(window_t *win)
{
    if (!win) {
        gli_stream_set_current(NULL);
    }
    else {
        if (win != mainwin) {
            gli_strict_warning("set_window: invalid id.");
            return;
        }
        gli_stream_set_current(mainwin->str);
    }
}

void glk_request_char_event(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("request_char_event: invalid id");
        return;
    }
    
    if (mainwin->char_request || mainwin->line_request) {
        gli_strict_warning("request_char_event: window already has keyboard request");
        return;
    }
    
    mainwin->char_request = TRUE;
    mainwin->char_request_uni = FALSE;
}

void glk_request_line_event(window_t *win, char *buf, glui32 maxlen, 
    glui32 initlen)
{
    if (!win || win != mainwin) {
        gli_strict_warning("request_line_event: invalid id");
        return;
    }
    
    if (mainwin->char_request || mainwin->line_request) {
        gli_strict_warning("request_line_event: window already has keyboard request");
        return;
    }
    
    mainwin->line_request = TRUE;
    mainwin->line_request_uni = FALSE;
    mainwin->linebuf = buf;
    mainwin->linebuflen = maxlen;

    if (gli_register_arr) {
        win->inarrayrock = (*gli_register_arr)(buf, maxlen, "&+#!Cn");
    }
}

#ifdef GLK_MODULE_UNICODE

void glk_request_char_event_uni(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("request_char_event: invalid id");
        return;
    }
    
    if (mainwin->char_request || mainwin->line_request) {
        gli_strict_warning("request_char_event: window already has keyboard request");
        return;
    }
    
    mainwin->char_request = TRUE;
    mainwin->char_request_uni = TRUE;
}

void glk_request_line_event_uni(window_t *win, glui32 *buf, glui32 maxlen, 
    glui32 initlen)
{
    if (!win || win != mainwin) {
        gli_strict_warning("request_line_event: invalid id");
        return;
    }
    
    if (mainwin->char_request || mainwin->line_request) {
        gli_strict_warning("request_line_event: window already has keyboard request");
        return;
    }
    
    mainwin->line_request = TRUE;
    mainwin->line_request_uni = TRUE;
    mainwin->linebuf = buf;
    mainwin->linebuflen = maxlen;

    if (gli_register_arr) {
        win->inarrayrock = (*gli_register_arr)(buf, maxlen, "&+#!Iu");
    }
}

#endif /* GLK_MODULE_UNICODE */

void glk_request_mouse_event(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("request_mouse_event: invalid id");
        return;
    }
    /* Yeah, right */
    return;
}

void glk_cancel_char_event(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("cancel_char_event: invalid id");
        return;
    }
    
    mainwin->char_request = FALSE;
}

void glk_cancel_line_event(window_t *win, event_t *ev)
{
    event_t dummyev;
    
    if (!ev) {
        ev = &dummyev;
    }

    gli_event_clearevent(ev);
    
    if (!win || win != mainwin) {
        gli_strict_warning("cancel_line_event: invalid id");
        return;
    }
    
    if (mainwin->line_request) {
        if (gli_unregister_arr) {
            /* This could be a char array or a glui32 array. */
            char *typedesc = (mainwin->line_request_uni ? "&+#!Iu" : "&+#!Cn");
            (*gli_unregister_arr)(mainwin->linebuf, mainwin->linebuflen, 
                typedesc, mainwin->inarrayrock);
        }

        mainwin->line_request = FALSE;
        mainwin->linebuf = NULL;
        mainwin->linebuflen = 0;
        
        /* Since there's only one window and no arrangement events,
            once a glk_select() starts, it can only end with actual
            line or character input. But it's possible that the
            program will set a line input request and then immediately
            cancel it. In that case, no input has occurred, so we
            set val1 to zero. */
        
        ev->type = evtype_LineInput;
        ev->val1 = 0;
        ev->val2 = 0;
        ev->win = mainwin;
    }
}

void glk_cancel_mouse_event(window_t *win)
{
    if (!win || win != mainwin) {
        gli_strict_warning("cancel_mouse_event: invalid id");
        return;
    }
    /* Yeah, right */
    return;
}

void glk_window_clear(window_t *win)
{
    int ix;
    
    if (!win || win != mainwin) {
        gli_strict_warning("window_clear: invalid id.");
        return;
    }
    
    if (mainwin->line_request) {
        gli_strict_warning("window_clear: window has pending line request");
        return;
    }

    for (ix=0; ix<gli_screenheight; ix++) {
        putc('\n', stdout);
    }
}

void glk_window_move_cursor(window_t *win, glui32 xpos, glui32 ypos)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_move_cursor: invalid id.");
        return;
    }
    
    gli_strict_warning("window_move_cursor: cannot move cursor in a TextBuffer window.");
}

void glk_window_get_size(window_t *win, glui32 *widthptr, 
    glui32 *heightptr)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_size: invalid id.");
        return;
    }
    
    if (widthptr)
        *widthptr = gli_screenwidth;
    if (heightptr)
        *heightptr = gli_screenheight;
}

void glk_window_get_arrangement(window_t *win, glui32 *methodptr,
    glui32 *sizeptr, winid_t *keywinptr)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_get_arrangement: invalid id.");
        return;
    }
    
    gli_strict_warning("window_get_arrangement: not a Pair window.");
}

void glk_window_set_arrangement(window_t *win, glui32 method,
    glui32 size, winid_t keywin)
{
    if (!win || win != mainwin) {
        gli_strict_warning("window_set_arrangement: invalid id.");
        return;
    }
    
    gli_strict_warning("window_set_arrangement: not a Pair window.");
}

#ifdef GLK_MODULE_IMAGE

glui32 glk_image_draw(winid_t win, glui32 image, glsi32 val1, glsi32 val2)
{
    gli_strict_warning("image_draw: graphics not supported.");
    return FALSE;
}

glui32 glk_image_draw_scaled(winid_t win, glui32 image, 
    glsi32 val1, glsi32 val2, glui32 width, glui32 height)
{
    gli_strict_warning("image_draw_scaled: graphics not supported.");
    return FALSE;
}

glui32 glk_image_get_info(glui32 image, glui32 *width, glui32 *height)
{
    gli_strict_warning("image_get_info: graphics not supported.");
    return FALSE;
}

void glk_window_flow_break(winid_t win)
{
    gli_strict_warning("window_flow_break: graphics not supported.");
}

void glk_window_erase_rect(winid_t win, 
    glsi32 left, glsi32 top, glui32 width, glui32 height)
{
    gli_strict_warning("window_erase_rect: graphics not supported.");
}

void glk_window_fill_rect(winid_t win, glui32 color, 
    glsi32 left, glsi32 top, glui32 width, glui32 height)
{
    gli_strict_warning("window_fill_rect: graphics not supported.");
}

void glk_window_set_background_color(winid_t win, glui32 color)
{
    gli_strict_warning("window_set_background_color: graphics not supported.");
}

#endif /* GLK_MODULE_IMAGE */

#ifdef GLK_MODULE_HYPERLINKS

void glk_set_hyperlink(glui32 linkval)
{
    gli_strict_warning("set_hyperlink: hyperlinks not supported.");
}

void glk_set_hyperlink_stream(strid_t str, glui32 linkval)
{
    gli_strict_warning("set_hyperlink_stream: hyperlinks not supported.");
}

void glk_request_hyperlink_event(winid_t win)
{
    gli_strict_warning("request_hyperlink_event: hyperlinks not supported.");
}

void glk_cancel_hyperlink_event(winid_t win)
{
    gli_strict_warning("cancel_hyperlink_event: hyperlinks not supported.");
}

#endif /* GLK_MODULE_HYPERLINKS */
