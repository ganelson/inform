#ifndef GLK_H
#define GLK_H

/* glk.h: Header file for Glk API, version 0.7.0.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/glk/index.html

    This file is copyright 1998-2004 by Andrew Plotkin. You may copy,
    distribute, and incorporate it into your own programs, by any means
    and under any conditions, as long as you do not modify it. You may
    also modify this file, incorporate it into your own programs,
    and distribute the modified version, as long as you retain a notice
    in your program or documentation which mentions my name and the URL
    shown above.
*/

/* You may have to edit the definition of glui32 to make sure it's really a
    32-bit unsigned integer type, and glsi32 to make sure it's really a
    32-bit signed integer type. If they're not, horrible things will happen. */
typedef unsigned long glui32;
typedef signed long glsi32;

/* These are the compile-time conditionals that reveal various Glk optional
    modules. */
#define GLK_MODULE_UNICODE
#define GLK_MODULE_IMAGE
#define GLK_MODULE_SOUND
#define GLK_MODULE_HYPERLINKS

/* These types are opaque object identifiers. They're pointers to opaque
    C structures, which are defined differently by each library. */
typedef struct glk_window_struct  *winid_t;
typedef struct glk_stream_struct  *strid_t;
typedef struct glk_fileref_struct *frefid_t;
typedef struct glk_schannel_struct *schanid_t;

#define gestalt_Version (0)
#define gestalt_CharInput (1)
#define gestalt_LineInput (2)
#define gestalt_CharOutput (3)
#define   gestalt_CharOutput_CannotPrint (0)
#define   gestalt_CharOutput_ApproxPrint (1)
#define   gestalt_CharOutput_ExactPrint (2)
#define gestalt_MouseInput (4)
#define gestalt_Timer (5)
#define gestalt_Graphics (6)
#define gestalt_DrawImage (7)
#define gestalt_Sound (8)
#define gestalt_SoundVolume (9)
#define gestalt_SoundNotify (10)
#define gestalt_Hyperlinks (11)
#define gestalt_HyperlinkInput (12)
#define gestalt_SoundMusic (13)
#define gestalt_GraphicsTransparency (14)
#define gestalt_Unicode (15)

#define evtype_None (0)
#define evtype_Timer (1)
#define evtype_CharInput (2)
#define evtype_LineInput (3)
#define evtype_MouseInput (4)
#define evtype_Arrange (5)
#define evtype_Redraw (6)
#define evtype_SoundNotify (7)
#define evtype_Hyperlink (8)

typedef struct event_struct {
    glui32 type;
    winid_t win;
    glui32 val1, val2;
} event_t;

#define keycode_Unknown  (0xffffffff)
#define keycode_Left     (0xfffffffe)
#define keycode_Right    (0xfffffffd)
#define keycode_Up       (0xfffffffc)
#define keycode_Down     (0xfffffffb)
#define keycode_Return   (0xfffffffa)
#define keycode_Delete   (0xfffffff9)
#define keycode_Escape   (0xfffffff8)
#define keycode_Tab      (0xfffffff7)
#define keycode_PageUp   (0xfffffff6)
#define keycode_PageDown (0xfffffff5)
#define keycode_Home     (0xfffffff4)
#define keycode_End      (0xfffffff3)
#define keycode_Func1    (0xffffffef)
#define keycode_Func2    (0xffffffee)
#define keycode_Func3    (0xffffffed)
#define keycode_Func4    (0xffffffec)
#define keycode_Func5    (0xffffffeb)
#define keycode_Func6    (0xffffffea)
#define keycode_Func7    (0xffffffe9)
#define keycode_Func8    (0xffffffe8)
#define keycode_Func9    (0xffffffe7)
#define keycode_Func10   (0xffffffe6)
#define keycode_Func11   (0xffffffe5)
#define keycode_Func12   (0xffffffe4)
/* The last keycode is always (0x100000000 - keycode_MAXVAL) */
#define keycode_MAXVAL   (28)

#define style_Normal (0)
#define style_Emphasized (1)
#define style_Preformatted (2)
#define style_Header (3)
#define style_Subheader (4)
#define style_Alert (5)
#define style_Note (6)
#define style_BlockQuote (7)
#define style_Input (8)
#define style_User1 (9)
#define style_User2 (10)
#define style_NUMSTYLES (11)

typedef struct stream_result_struct {
    glui32 readcount;
    glui32 writecount;
} stream_result_t;

#define wintype_AllTypes (0)
#define wintype_Pair (1)
#define wintype_Blank (2)
#define wintype_TextBuffer (3)
#define wintype_TextGrid (4)
#define wintype_Graphics (5)

#define winmethod_Left  (0x00)
#define winmethod_Right (0x01)
#define winmethod_Above (0x02)
#define winmethod_Below (0x03)
#define winmethod_DirMask (0x0f)

#define winmethod_Fixed (0x10)
#define winmethod_Proportional (0x20)
#define winmethod_DivisionMask (0xf0)

#define fileusage_Data (0x00)
#define fileusage_SavedGame (0x01)
#define fileusage_Transcript (0x02)
#define fileusage_InputRecord (0x03)
#define fileusage_TypeMask (0x0f)

#define fileusage_TextMode   (0x100)
#define fileusage_BinaryMode (0x000)

#define filemode_Write (0x01)
#define filemode_Read (0x02)
#define filemode_ReadWrite (0x03)
#define filemode_WriteAppend (0x05)

#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)

#define stylehint_Indentation (0)
#define stylehint_ParaIndentation (1)
#define stylehint_Justification (2)
#define stylehint_Size (3)
#define stylehint_Weight (4)
#define stylehint_Oblique (5)
#define stylehint_Proportional (6)
#define stylehint_TextColor (7)
#define stylehint_BackColor (8)
#define stylehint_ReverseColor (9)
#define stylehint_NUMHINTS (10)

#define   stylehint_just_LeftFlush (0)
#define   stylehint_just_LeftRight (1)
#define   stylehint_just_Centered (2)
#define   stylehint_just_RightFlush (3)

/* glk_main() is the top-level function which you define. The Glk library
    calls it. */
extern void glk_main(void);

extern void glk_exit(void);
extern void glk_set_interrupt_handler(void (*func)(void));
extern void glk_tick(void);

extern glui32 glk_gestalt(glui32 sel, glui32 val);
extern glui32 glk_gestalt_ext(glui32 sel, glui32 val, glui32 *arr,
    glui32 arrlen);

extern unsigned char glk_char_to_lower(unsigned char ch);
extern unsigned char glk_char_to_upper(unsigned char ch);

extern winid_t glk_window_get_root(void);
extern winid_t glk_window_open(winid_t split, glui32 method, glui32 size,
    glui32 wintype, glui32 rock);
extern void glk_window_close(winid_t win, stream_result_t *result);
extern void glk_window_get_size(winid_t win, glui32 *widthptr,
    glui32 *heightptr);
extern void glk_window_set_arrangement(winid_t win, glui32 method,
    glui32 size, winid_t keywin);
extern void glk_window_get_arrangement(winid_t win, glui32 *methodptr,
    glui32 *sizeptr, winid_t *keywinptr);
extern winid_t glk_window_iterate(winid_t win, glui32 *rockptr);
extern glui32 glk_window_get_rock(winid_t win);
extern glui32 glk_window_get_type(winid_t win);
extern winid_t glk_window_get_parent(winid_t win);
extern winid_t glk_window_get_sibling(winid_t win);
extern void glk_window_clear(winid_t win);
extern void glk_window_move_cursor(winid_t win, glui32 xpos, glui32 ypos);

extern strid_t glk_window_get_stream(winid_t win);
extern void glk_window_set_echo_stream(winid_t win, strid_t str);
extern strid_t glk_window_get_echo_stream(winid_t win);
extern void glk_set_window(winid_t win);

extern strid_t glk_stream_open_file(frefid_t fileref, glui32 fmode,
    glui32 rock);
extern strid_t glk_stream_open_memory(char *buf, glui32 buflen, glui32 fmode,
    glui32 rock);
extern void glk_stream_close(strid_t str, stream_result_t *result);
extern strid_t glk_stream_iterate(strid_t str, glui32 *rockptr);
extern glui32 glk_stream_get_rock(strid_t str);
extern void glk_stream_set_position(strid_t str, glsi32 pos, glui32 seekmode);
extern glui32 glk_stream_get_position(strid_t str);
extern void glk_stream_set_current(strid_t str);
extern strid_t glk_stream_get_current(void);

extern void glk_put_char(unsigned char ch);
extern void glk_put_char_stream(strid_t str, unsigned char ch);
extern void glk_put_string(char *s);
extern void glk_put_string_stream(strid_t str, char *s);
extern void glk_put_buffer(char *buf, glui32 len);
extern void glk_put_buffer_stream(strid_t str, char *buf, glui32 len);
extern void glk_set_style(glui32 styl);
extern void glk_set_style_stream(strid_t str, glui32 styl);

extern glsi32 glk_get_char_stream(strid_t str);
extern glui32 glk_get_line_stream(strid_t str, char *buf, glui32 len);
extern glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len);

extern void glk_stylehint_set(glui32 wintype, glui32 styl, glui32 hint,
    glsi32 val);
extern void glk_stylehint_clear(glui32 wintype, glui32 styl, glui32 hint);
extern glui32 glk_style_distinguish(winid_t win, glui32 styl1, glui32 styl2);
extern glui32 glk_style_measure(winid_t win, glui32 styl, glui32 hint,
    glui32 *result);

extern frefid_t glk_fileref_create_temp(glui32 usage, glui32 rock);
extern frefid_t glk_fileref_create_by_name(glui32 usage, char *name,
    glui32 rock);
extern frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode,
    glui32 rock);
extern frefid_t glk_fileref_create_from_fileref(glui32 usage, frefid_t fref,
    glui32 rock);
extern void glk_fileref_destroy(frefid_t fref);
extern frefid_t glk_fileref_iterate(frefid_t fref, glui32 *rockptr);
extern glui32 glk_fileref_get_rock(frefid_t fref);
extern void glk_fileref_delete_file(frefid_t fref);
extern glui32 glk_fileref_does_file_exist(frefid_t fref);

extern void glk_select(event_t *event);
extern void glk_select_poll(event_t *event);

extern void glk_request_timer_events(glui32 millisecs);

extern void glk_request_line_event(winid_t win, char *buf, glui32 maxlen,
    glui32 initlen);
extern void glk_request_char_event(winid_t win);
extern void glk_request_mouse_event(winid_t win);

extern void glk_cancel_line_event(winid_t win, event_t *event);
extern void glk_cancel_char_event(winid_t win);
extern void glk_cancel_mouse_event(winid_t win);

#ifdef GLK_MODULE_UNICODE

extern glui32 glk_buffer_to_lower_case_uni(glui32 *buf, glui32 len,
    glui32 numchars);
extern glui32 glk_buffer_to_upper_case_uni(glui32 *buf, glui32 len,
    glui32 numchars);
extern glui32 glk_buffer_to_title_case_uni(glui32 *buf, glui32 len,
    glui32 numchars, glui32 lowerrest);

extern void glk_put_char_uni(glui32 ch);
extern void glk_put_string_uni(glui32 *s);
extern void glk_put_buffer_uni(glui32 *buf, glui32 len);
extern void glk_put_char_stream_uni(strid_t str, glui32 ch);
extern void glk_put_string_stream_uni(strid_t str, glui32 *s);
extern void glk_put_buffer_stream_uni(strid_t str, glui32 *buf, glui32 len);

extern glsi32 glk_get_char_stream_uni(strid_t str);
extern glui32 glk_get_buffer_stream_uni(strid_t str, glui32 *buf, glui32 len);
extern glui32 glk_get_line_stream_uni(strid_t str, glui32 *buf, glui32 len);

extern strid_t glk_stream_open_file_uni(frefid_t fileref, glui32 fmode,
    glui32 rock);
extern strid_t glk_stream_open_memory_uni(glui32 *buf, glui32 buflen,
    glui32 fmode, glui32 rock);

extern void glk_request_char_event_uni(winid_t win);
extern void glk_request_line_event_uni(winid_t win, glui32 *buf,
    glui32 maxlen, glui32 initlen);

#endif /* GLK_MODULE_UNICODE */

#ifdef GLK_MODULE_IMAGE

#define imagealign_InlineUp (0x01)
#define imagealign_InlineDown (0x02)
#define imagealign_InlineCenter (0x03)
#define imagealign_MarginLeft (0x04)
#define imagealign_MarginRight (0x05)

extern glui32 glk_image_draw(winid_t win, glui32 image, glsi32 val1, glsi32 val2);
extern glui32 glk_image_draw_scaled(winid_t win, glui32 image,
    glsi32 val1, glsi32 val2, glui32 width, glui32 height);
extern glui32 glk_image_get_info(glui32 image, glui32 *width, glui32 *height);

extern void glk_window_flow_break(winid_t win);

extern void glk_window_erase_rect(winid_t win,
    glsi32 left, glsi32 top, glui32 width, glui32 height);
extern void glk_window_fill_rect(winid_t win, glui32 color,
    glsi32 left, glsi32 top, glui32 width, glui32 height);
extern void glk_window_set_background_color(winid_t win, glui32 color);

#endif /* GLK_MODULE_IMAGE */

#ifdef GLK_MODULE_SOUND

extern schanid_t glk_schannel_create(glui32 rock);
extern void glk_schannel_destroy(schanid_t chan);
extern schanid_t glk_schannel_iterate(schanid_t chan, glui32 *rockptr);
extern glui32 glk_schannel_get_rock(schanid_t chan);

extern glui32 glk_schannel_play(schanid_t chan, glui32 snd);
extern glui32 glk_schannel_play_ext(schanid_t chan, glui32 snd, glui32 repeats,
    glui32 notify);
extern void glk_schannel_stop(schanid_t chan);
extern void glk_schannel_set_volume(schanid_t chan, glui32 vol);

extern void glk_sound_load_hint(glui32 snd, glui32 flag);

#endif /* GLK_MODULE_SOUND */

#ifdef GLK_MODULE_HYPERLINKS

extern void glk_set_hyperlink(glui32 linkval);
extern void glk_set_hyperlink_stream(strid_t str, glui32 linkval);
extern void glk_request_hyperlink_event(winid_t win);
extern void glk_cancel_hyperlink_event(winid_t win);

#endif /* GLK_MODULE_HYPERLINKS */

#endif /* GLK_H */
