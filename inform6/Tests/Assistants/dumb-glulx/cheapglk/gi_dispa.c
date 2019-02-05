/* gi_dispa.c: Dispatch layer for Glk API, version 0.7.0.
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

/* This code should be linked into every Glk library, without change. 
    Get the latest version from the URL above. */

#include "glk.h"
#include "gi_dispa.h"

#ifndef NULL
#define NULL 0
#endif

#define NUMCLASSES   \
    (sizeof(class_table) / sizeof(gidispatch_intconst_t))

#define NUMINTCONSTANTS   \
    (sizeof(intconstant_table) / sizeof(gidispatch_intconst_t))

#define NUMFUNCTIONS   \
    (sizeof(function_table) / sizeof(gidispatch_function_t))

/* The constants in this table must be ordered alphabetically. */
static gidispatch_intconst_t class_table[] = {
    { "fileref", (2) },   /* "Qc" */
    { "schannel", (3) },  /* "Qd" */
    { "stream", (1) },    /* "Qb" */
    { "window", (0) },    /* "Qa" */
};

/* The constants in this table must be ordered alphabetically. */
static gidispatch_intconst_t intconstant_table[] = {
    { "evtype_Arrange", (5)  },
    { "evtype_CharInput", (2) },
    { "evtype_Hyperlink", (8) },
    { "evtype_LineInput", (3) },
    { "evtype_MouseInput", (4) },
    { "evtype_None", (0) },
    { "evtype_Redraw", (6) },
    { "evtype_SoundNotify", (7) },
    { "evtype_Timer", (1) },
    { "filemode_Read", (0x02) },
    { "filemode_ReadWrite", (0x03) },
    { "filemode_Write", (0x01) },
    { "filemode_WriteAppend", (0x05) },
    { "fileusage_BinaryMode", (0x000) },
    { "fileusage_Data", (0x00) },
    { "fileusage_InputRecord", (0x03) },
    { "fileusage_SavedGame", (0x01) },
    { "fileusage_TextMode",   (0x100) },
    { "fileusage_Transcript", (0x02) },
    { "fileusage_TypeMask", (0x0f) },
    { "gestalt_CharInput", (1) },
    { "gestalt_CharOutput", (3) },
    { "gestalt_CharOutput_ApproxPrint", (1) },
    { "gestalt_CharOutput_CannotPrint", (0) },
    { "gestalt_CharOutput_ExactPrint", (2) },
    { "gestalt_DrawImage", (7) },
    { "gestalt_Graphics", (6) },
    { "gestalt_GraphicsTransparency", (14) },
    { "gestalt_HyperlinkInput", (12) },
    { "gestalt_Hyperlinks", (11) },
    { "gestalt_LineInput", (2) },
    { "gestalt_MouseInput", (4) },
    { "gestalt_Sound", (8) },
    { "gestalt_SoundMusic", (13) },
    { "gestalt_SoundNotify", (10) },
    { "gestalt_SoundVolume", (9) },
    { "gestalt_Timer", (5) },
    { "gestalt_Unicode", (15) },
    { "gestalt_Version", (0) },
#ifdef GLK_MODULE_IMAGE
    { "imagealign_InlineCenter",  (0x03) },
    { "imagealign_InlineDown",  (0x02) },
    { "imagealign_MarginLeft",  (0x04) },
    { "imagealign_MarginRight",  (0x05) },
    { "imagealign_InlineUp",  (0x01) },
#endif /* GLK_MODULE_IMAGE */
    { "keycode_Delete",   (0xfffffff9) },
    { "keycode_Down",     (0xfffffffb) },
    { "keycode_End",      (0xfffffff3) },
    { "keycode_Escape",   (0xfffffff8) },
    { "keycode_Func1",    (0xffffffef) },
    { "keycode_Func10",   (0xffffffe6) },
    { "keycode_Func11",   (0xffffffe5) },
    { "keycode_Func12",   (0xffffffe4) },
    { "keycode_Func2",    (0xffffffee) },
    { "keycode_Func3",    (0xffffffed) },
    { "keycode_Func4",    (0xffffffec) },
    { "keycode_Func5",    (0xffffffeb) },
    { "keycode_Func6",    (0xffffffea) },
    { "keycode_Func7",    (0xffffffe9) },
    { "keycode_Func8",    (0xffffffe8) },
    { "keycode_Func9",    (0xffffffe7) },
    { "keycode_Home",     (0xfffffff4) },
    { "keycode_Left",     (0xfffffffe) },
    { "keycode_MAXVAL",   (28)  },
    { "keycode_PageDown", (0xfffffff5) },
    { "keycode_PageUp",   (0xfffffff6) },
    { "keycode_Return",   (0xfffffffa) },
    { "keycode_Right",    (0xfffffffd) },
    { "keycode_Tab",      (0xfffffff7) },
    { "keycode_Unknown",  (0xffffffff) },
    { "keycode_Up",       (0xfffffffc) },
    { "seekmode_Current", (1) },
    { "seekmode_End", (2) },
    { "seekmode_Start", (0) },
    { "style_Alert", (5) },
    { "style_BlockQuote", (7) },
    { "style_Emphasized", (1) },
    { "style_Header", (3) },
    { "style_Input", (8) },
    { "style_NUMSTYLES", (11) },
    { "style_Normal", (0) },
    { "style_Note", (6) },
    { "style_Preformatted", (2) },
    { "style_Subheader", (4) },
    { "style_User1", (9) },
    { "style_User2", (10) },
    { "stylehint_BackColor", (8) },
    { "stylehint_Indentation", (0) },
    { "stylehint_Justification", (2)  },
    { "stylehint_NUMHINTS", (10) },
    { "stylehint_Oblique", (5) },
    { "stylehint_ParaIndentation", (1) },
    { "stylehint_Proportional", (6) },
    { "stylehint_ReverseColor", (9) },
    { "stylehint_Size", (3) },
    { "stylehint_TextColor", (7) },
    { "stylehint_Weight", (4) },
    { "stylehint_just_Centered", (2) },
    { "stylehint_just_LeftFlush", (0) },
    { "stylehint_just_LeftRight", (1) },
    { "stylehint_just_RightFlush", (3) },
    { "winmethod_Above", (0x02)  },
    { "winmethod_Below", (0x03)  },
    { "winmethod_DirMask", (0x0f) },
    { "winmethod_DivisionMask", (0xf0) },
    { "winmethod_Fixed", (0x10) },
    { "winmethod_Left",  (0x00)  },
    { "winmethod_Proportional", (0x20) },
    { "winmethod_Right", (0x01)  },
    { "wintype_AllTypes", (0)  },
    { "wintype_Blank", (2)  },
    { "wintype_Graphics", (5)  },
    { "wintype_Pair", (1)  },
    { "wintype_TextBuffer", (3) },
    { "wintype_TextGrid", (4) },
};

/* The functions in this table must be ordered by id. */
static gidispatch_function_t function_table[] = {
    { 0x0001, glk_exit, "exit" },
    { 0x0002, glk_set_interrupt_handler, "set_interrupt_handler" },
    { 0x0003, glk_tick, "tick" },
    { 0x0004, glk_gestalt, "gestalt" },
    { 0x0005, glk_gestalt_ext, "gestalt_ext" },
    { 0x0020, glk_window_iterate, "window_iterate" },
    { 0x0021, glk_window_get_rock, "window_get_rock" },
    { 0x0022, glk_window_get_root, "window_get_root" },
    { 0x0023, glk_window_open, "window_open" },
    { 0x0024, glk_window_close, "window_close" },
    { 0x0025, glk_window_get_size, "window_get_size" },
    { 0x0026, glk_window_set_arrangement, "window_set_arrangement" },
    { 0x0027, glk_window_get_arrangement, "window_get_arrangement" },
    { 0x0028, glk_window_get_type, "window_get_type" },
    { 0x0029, glk_window_get_parent, "window_get_parent" },
    { 0x002A, glk_window_clear, "window_clear" },
    { 0x002B, glk_window_move_cursor, "window_move_cursor" },
    { 0x002C, glk_window_get_stream, "window_get_stream" },
    { 0x002D, glk_window_set_echo_stream, "window_set_echo_stream" },
    { 0x002E, glk_window_get_echo_stream, "window_get_echo_stream" },
    { 0x002F, glk_set_window, "set_window" },
    { 0x0030, glk_window_get_sibling, "window_get_sibling" },
    { 0x0040, glk_stream_iterate, "stream_iterate" },
    { 0x0041, glk_stream_get_rock, "stream_get_rock" },
    { 0x0042, glk_stream_open_file, "stream_open_file" },
    { 0x0043, glk_stream_open_memory, "stream_open_memory" },
    { 0x0044, glk_stream_close, "stream_close" },
    { 0x0045, glk_stream_set_position, "stream_set_position" },
    { 0x0046, glk_stream_get_position, "stream_get_position" },
    { 0x0047, glk_stream_set_current, "stream_set_current" },
    { 0x0048, glk_stream_get_current, "stream_get_current" },
    { 0x0060, glk_fileref_create_temp, "fileref_create_temp" },
    { 0x0061, glk_fileref_create_by_name, "fileref_create_by_name" },
    { 0x0062, glk_fileref_create_by_prompt, "fileref_create_by_prompt" },
    { 0x0063, glk_fileref_destroy, "fileref_destroy" },
    { 0x0064, glk_fileref_iterate, "fileref_iterate" },
    { 0x0065, glk_fileref_get_rock, "fileref_get_rock" },
    { 0x0066, glk_fileref_delete_file, "fileref_delete_file" },
    { 0x0067, glk_fileref_does_file_exist, "fileref_does_file_exist" },
    { 0x0068, glk_fileref_create_from_fileref, "fileref_create_from_fileref" },
    { 0x0080, glk_put_char, "put_char" },
    { 0x0081, glk_put_char_stream, "put_char_stream" },
    { 0x0082, glk_put_string, "put_string" },
    { 0x0083, glk_put_string_stream, "put_string_stream" },
    { 0x0084, glk_put_buffer, "put_buffer" },
    { 0x0085, glk_put_buffer_stream, "put_buffer_stream" },
    { 0x0086, glk_set_style, "set_style" },
    { 0x0087, glk_set_style_stream, "set_style_stream" },
    { 0x0090, glk_get_char_stream, "get_char_stream" },
    { 0x0091, glk_get_line_stream, "get_line_stream" },
    { 0x0092, glk_get_buffer_stream, "get_buffer_stream" },
    { 0x00A0, glk_char_to_lower, "char_to_lower" },
    { 0x00A1, glk_char_to_upper, "char_to_upper" },
    { 0x00B0, glk_stylehint_set, "stylehint_set" },
    { 0x00B1, glk_stylehint_clear, "stylehint_clear" },
    { 0x00B2, glk_style_distinguish, "style_distinguish" },
    { 0x00B3, glk_style_measure, "style_measure" },
    { 0x00C0, glk_select, "select" },
    { 0x00C1, glk_select_poll, "select_poll" },
    { 0x00D0, glk_request_line_event, "request_line_event" },
    { 0x00D1, glk_cancel_line_event, "cancel_line_event" },
    { 0x00D2, glk_request_char_event, "request_char_event" },
    { 0x00D3, glk_cancel_char_event, "cancel_char_event" },
    { 0x00D4, glk_request_mouse_event, "request_mouse_event" },
    { 0x00D5, glk_cancel_mouse_event, "cancel_mouse_event" },
    { 0x00D6, glk_request_timer_events, "request_timer_events" },
#ifdef GLK_MODULE_IMAGE
    { 0x00E0, glk_image_get_info, "image_get_info" },
    { 0x00E1, glk_image_draw, "image_draw" },
    { 0x00E2, glk_image_draw_scaled, "image_draw_scaled" },
    { 0x00E8, glk_window_flow_break, "window_flow_break" },
    { 0x00E9, glk_window_erase_rect, "window_erase_rect" },
    { 0x00EA, glk_window_fill_rect, "window_fill_rect" },
    { 0x00EB, glk_window_set_background_color, "window_set_background_color" },
#endif /* GLK_MODULE_IMAGE */
#ifdef GLK_MODULE_SOUND
    { 0x00F0, glk_schannel_iterate, "schannel_iterate" },
    { 0x00F1, glk_schannel_get_rock, "schannel_get_rock" },
    { 0x00F2, glk_schannel_create, "schannel_create" },
    { 0x00F3, glk_schannel_destroy, "schannel_destroy" },
    { 0x00F8, glk_schannel_play, "schannel_play" },
    { 0x00F9, glk_schannel_play_ext, "schannel_play_ext" },
    { 0x00FA, glk_schannel_stop, "schannel_stop" },
    { 0x00FB, glk_schannel_set_volume, "schannel_set_volume" },
    { 0x00FC, glk_sound_load_hint, "sound_load_hint" },
#endif /* GLK_MODULE_SOUND */
#ifdef GLK_MODULE_HYPERLINKS
    { 0x0100, glk_set_hyperlink, "set_hyperlink" },
    { 0x0101, glk_set_hyperlink_stream, "set_hyperlink_stream" },
    { 0x0102, glk_request_hyperlink_event, "request_hyperlink_event" },
    { 0x0103, glk_cancel_hyperlink_event, "cancel_hyperlink_event" },
#endif /* GLK_MODULE_HYPERLINKS */
#ifdef GLK_MODULE_UNICODE
    { 0x0120, glk_buffer_to_lower_case_uni, "buffer_to_lower_case_uni" },
    { 0x0121, glk_buffer_to_upper_case_uni, "buffer_to_upper_case_uni" },
    { 0x0122, glk_buffer_to_title_case_uni, "buffer_to_title_case_uni" },
    { 0x0128, glk_put_char_uni, "put_char_uni" },
    { 0x0129, glk_put_string_uni, "put_string_uni" },
    { 0x012A, glk_put_buffer_uni, "put_buffer_uni" },
    { 0x012B, glk_put_char_stream_uni, "put_char_stream_uni" },
    { 0x012C, glk_put_string_stream_uni, "put_string_stream_uni" },
    { 0x012D, glk_put_buffer_stream_uni, "put_buffer_stream_uni" },
    { 0x0130, glk_get_char_stream_uni, "get_char_stream_uni" },
    { 0x0131, glk_get_buffer_stream_uni, "get_buffer_stream_uni" },
    { 0x0132, glk_get_line_stream_uni, "get_line_stream_uni" },
    { 0x0138, glk_stream_open_file_uni, "stream_open_file_uni" },
    { 0x0139, glk_stream_open_memory_uni, "stream_open_memory_uni" },
    { 0x0140, glk_request_char_event_uni, "request_char_event_uni" },
    { 0x0141, glk_request_line_event_uni, "request_line_event_uni" },
#endif /* GLK_MODULE_UNICODE */
};

glui32 gidispatch_count_classes()
{
    return NUMCLASSES;
}

gidispatch_intconst_t *gidispatch_get_class(glui32 index)
{
    if (index < 0 || index >= NUMCLASSES)
        return NULL;
    return &(class_table[index]);
}

glui32 gidispatch_count_intconst()
{
    return NUMINTCONSTANTS;
}

gidispatch_intconst_t *gidispatch_get_intconst(glui32 index)
{
    if (index < 0 || index >= NUMINTCONSTANTS)
        return NULL;
    return &(intconstant_table[index]);
}

glui32 gidispatch_count_functions()
{
    return NUMFUNCTIONS;
}

gidispatch_function_t *gidispatch_get_function(glui32 index)
{
    if (index < 0 || index >= NUMFUNCTIONS)
        return NULL;
    return &(function_table[index]);
}

gidispatch_function_t *gidispatch_get_function_by_id(glui32 id)
{
    int top, bot, val;
    gidispatch_function_t *func;
    
    bot = 0;
    top = NUMFUNCTIONS;
    
    while (1) {
        val = (top+bot) / 2;
        func = &(function_table[val]);
        if (func->id == id)
            return func;
        if (bot >= top-1)
            break;
        if (func->id < id) {
            bot = val+1;
        }
        else {
            top = val;
        }
    }
    
    return NULL;
}

char *gidispatch_prototype(glui32 funcnum)
{
    switch (funcnum) {
        case 0x0001: /* exit */
            return "0:";
        case 0x0002: /* set_interrupt_handler */
            /* cannot be invoked through dispatch layer */
            return NULL;
        case 0x0003: /* tick */
            return "0:";
        case 0x0004: /* gestalt */
            return "3IuIu:Iu";
        case 0x0005: /* gestalt_ext */
            return "4IuIu&#Iu:Iu";
        case 0x0020: /* window_iterate */
            return "3Qa<Iu:Qa";
        case 0x0021: /* window_get_rock */
            return "2Qa:Iu";
        case 0x0022: /* window_get_root */
            return "1:Qa";
        case 0x0023: /* window_open */
            return "6QaIuIuIuIu:Qa";
        case 0x0024: /* window_close */
            return "2Qa<[2IuIu]:";
        case 0x0025: /* window_get_size */
            return "3Qa<Iu<Iu:";
        case 0x0026: /* window_set_arrangement */
            return "4QaIuIuQa:";
        case 0x0027: /* window_get_arrangement */
            return "4Qa<Iu<Iu<Qa:";
        case 0x0028: /* window_get_type */
            return "2Qa:Iu";
        case 0x0029: /* window_get_parent */
            return "2Qa:Qa";
        case 0x002A: /* window_clear */
            return "1Qa:";
        case 0x002B: /* window_move_cursor */
            return "3QaIuIu:";
        case 0x002C: /* window_get_stream */
            return "2Qa:Qb";
        case 0x002D: /* window_set_echo_stream */
            return "2QaQb:";
        case 0x002E: /* window_get_echo_stream */
            return "2Qa:Qb";
        case 0x002F: /* set_window */
            return "1Qa:";
        case 0x0030: /* window_get_sibling */
            return "2Qa:Qa";
        case 0x0040: /* stream_iterate */
            return "3Qb<Iu:Qb";
        case 0x0041: /* stream_get_rock */
            return "2Qb:Iu";
        case 0x0042: /* stream_open_file */
            return "4QcIuIu:Qb";
        case 0x0043: /* stream_open_memory */
            return "4&+#!CnIuIu:Qb";
        case 0x0044: /* stream_close */
            return "2Qb<[2IuIu]:";
        case 0x0045: /* stream_set_position */
            return "3QbIsIu:";
        case 0x0046: /* stream_get_position */
            return "2Qb:Iu";
        case 0x0047: /* stream_set_current */
            return "1Qb:";
        case 0x0048: /* stream_get_current */
            return "1:Qb";
        case 0x0060: /* fileref_create_temp */
            return "3IuIu:Qc";
        case 0x0061: /* fileref_create_by_name */
            return "4IuSIu:Qc";
        case 0x0062: /* fileref_create_by_prompt */
            return "4IuIuIu:Qc";
        case 0x0063: /* fileref_destroy */
            return "1Qc:";
        case 0x0064: /* fileref_iterate */
            return "3Qc<Iu:Qc";
        case 0x0065: /* fileref_get_rock */
            return "2Qc:Iu";
        case 0x0066: /* fileref_delete_file */
            return "1Qc:";
        case 0x0067: /* fileref_does_file_exist */
            return "2Qc:Iu";
        case 0x0068: /* fileref_create_from_fileref */
            return "4IuQcIu:Qc";
        case 0x0080: /* put_char */
            return "1Cu:";
        case 0x0081: /* put_char_stream */
            return "2QbCu:";
        case 0x0082: /* put_string */
            return "1S:";
        case 0x0083: /* put_string_stream */
            return "2QbS:";
        case 0x0084: /* put_buffer */
            return "1>+#Cn:";
        case 0x0085: /* put_buffer_stream */
            return "2Qb>+#Cn:"; 
        case 0x0086: /* set_style */
            return "1Iu:";
        case 0x0087: /* set_style_stream */
            return "2QbIu:";
        case 0x0090: /* get_char_stream */
            return "2Qb:Is";
        case 0x0091: /* get_line_stream */
            return "3Qb<+#Cn:Iu"; 
        case 0x0092: /* get_buffer_stream */
            return "3Qb<+#Cn:Iu"; 
        case 0x00A0: /* char_to_lower */
            return "2Cu:Cu";
        case 0x00A1: /* char_to_upper */
            return "2Cu:Cu";
        case 0x00B0: /* stylehint_set */
            return "4IuIuIuIs:";
        case 0x00B1: /* stylehint_clear */
            return "3IuIuIu:";
        case 0x00B2: /* style_distinguish */
            return "4QaIuIu:Iu";
        case 0x00B3: /* style_measure */
            return "5QaIuIu<Iu:Iu";
        case 0x00C0: /* select */
            return "1<+[4IuQaIuIu]:";
        case 0x00C1: /* select_poll */
            return "1<+[4IuQaIuIu]:";
        case 0x00D0: /* request_line_event */
            return "3Qa&+#!CnIu:";
        case 0x00D1: /* cancel_line_event */
            return "2Qa<[4IuQaIuIu]:";
        case 0x00D2: /* request_char_event */
            return "1Qa:";
        case 0x00D3: /* cancel_char_event */
            return "1Qa:";
        case 0x00D4: /* request_mouse_event */
            return "1Qa:";
        case 0x00D5: /* cancel_mouse_event */
            return "1Qa:";
        case 0x00D6: /* request_timer_events */
            return "1Iu:";

#ifdef GLK_MODULE_IMAGE
        case 0x00E0: /* image_get_info */
            return "4Iu<Iu<Iu:Iu";
        case 0x00E1: /* image_draw */
            return "5QaIuIsIs:Iu";
        case 0x00E2: /* image_draw_scaled */
            return "7QaIuIsIsIuIu:Iu";
        case 0x00E8: /* window_flow_break */
            return "1Qa:";
        case 0x00E9: /* window_erase_rect */
            return "5QaIsIsIuIu:";
        case 0x00EA: /* window_fill_rect */
            return "6QaIuIsIsIuIu:";
        case 0x00EB: /* window_set_background_color */
            return "2QaIu:";
#endif /* GLK_MODULE_IMAGE */

#ifdef GLK_MODULE_SOUND
        case 0x00F0: /* schannel_iterate */
            return "3Qd<Iu:Qd";
        case 0x00F1: /* schannel_get_rock */
            return "2Qd:Iu";
        case 0x00F2: /* schannel_create */
            return "2Iu:Qd";
        case 0x00F3: /* schannel_destroy */
            return "1Qd:";
        case 0x00F8: /* schannel_play */
            return "3QdIu:Iu";
        case 0x00F9: /* schannel_play_ext */
            return "5QdIuIuIu:Iu";
        case 0x00FA: /* schannel_stop */
            return "1Qd:";
        case 0x00FB: /* schannel_set_volume */
            return "2QdIu:";
        case 0x00FC: /* sound_load_hint */
            return "2IuIu:";
#endif /* GLK_MODULE_SOUND */

#ifdef GLK_MODULE_HYPERLINKS
        case 0x0100: /* set_hyperlink */
            return "1Iu:";
        case 0x0101: /* set_hyperlink_stream */
            return "2QbIu:";
        case 0x0102: /* request_hyperlink_event */
            return "1Qa:";
        case 0x0103: /* cancel_hyperlink_event */
            return "1Qa:";
#endif /* GLK_MODULE_HYPERLINKS */

#ifdef GLK_MODULE_UNICODE
        case 0x0120: /* buffer_to_lower_case_uni */
            return "3&+#IuIu:Iu";
        case 0x0121: /* buffer_to_upper_case_uni */
            return "3&+#IuIu:Iu";
        case 0x0122: /* buffer_to_title_case_uni */
            return "4&+#IuIuIu:Iu";
        case 0x0128: /* put_char_uni */
            return "1Iu:";
        case 0x0129: /* put_string_uni */
            return "1U:";
        case 0x012A: /* put_buffer_uni */
            return "1>+#Iu:";
        case 0x012B: /* put_char_stream_uni */
            return "2QbIu:";
        case 0x012C: /* put_string_stream_uni */
            return "2QbU:";
        case 0x012D: /* put_buffer_stream_uni */
            return "2Qb>+#Iu:"; 
        case 0x0130: /* get_char_stream_uni */
            return "2Qb:Is";
        case 0x0131: /* get_buffer_stream_uni */
            return "3Qb<+#Iu:Iu"; 
        case 0x0132: /* get_line_stream_uni */
            return "3Qb<+#Iu:Iu"; 
        case 0x0138: /* stream_open_file_uni */
            return "4QcIuIu:Qb";
        case 0x0139: /* stream_open_memory_uni */
            return "4&+#!IuIuIu:Qb";
        case 0x0140: /* request_char_event_uni */
            return "1Qa:";
        case 0x0141: /* request_line_event_uni */
            return "3Qa&+#!IuIu:";
#endif /* GLK_MODULE_UNICODE */
            
        default:
            return NULL;
    }
}

void gidispatch_call(glui32 funcnum, glui32 numargs, gluniversal_t *arglist)
{
    switch (funcnum) {
        case 0x0001: /* exit */
            glk_exit();
            break;
        case 0x0002: /* set_interrupt_handler */
            /* cannot be invoked through dispatch layer */
            break;
        case 0x0003: /* tick */
            glk_tick();
            break;
        case 0x0004: /* gestalt */
            arglist[3].uint = glk_gestalt(arglist[0].uint, arglist[1].uint);
            break;
        case 0x0005: /* gestalt_ext */
            if (arglist[2].ptrflag) {
                arglist[6].uint = glk_gestalt_ext(arglist[0].uint, arglist[1].uint,
                    arglist[3].array, arglist[4].uint);
            }
            else {
                arglist[4].uint = glk_gestalt_ext(arglist[0].uint, arglist[1].uint,
                    NULL, 0);
            }
            break;
        case 0x0020: /* window_iterate */
            if (arglist[1].ptrflag) 
                arglist[4].opaqueref = glk_window_iterate(arglist[0].opaqueref, &arglist[2].uint);
            else
                arglist[3].opaqueref = glk_window_iterate(arglist[0].opaqueref, NULL);
            break;
        case 0x0021: /* window_get_rock */
            arglist[2].uint = glk_window_get_rock(arglist[0].opaqueref);
            break;
        case 0x0022: /* window_get_root */
            arglist[1].opaqueref = glk_window_get_root();
            break;
        case 0x0023: /* window_open */
            arglist[6].opaqueref = glk_window_open(arglist[0].opaqueref, arglist[1].uint, 
                arglist[2].uint, arglist[3].uint, arglist[4].uint);
            break;
        case 0x0024: /* window_close */
            if (arglist[1].ptrflag) {
                stream_result_t dat;
                glk_window_close(arglist[0].opaqueref, &dat);
                arglist[2].uint = dat.readcount;
                arglist[3].uint = dat.writecount;
            }
            else {
                glk_window_close(arglist[0].opaqueref, NULL);
            }
            break;
        case 0x0025: /* window_get_size */
            {
                int ix = 1;
                glui32 *ptr1, *ptr2;
                if (!arglist[ix].ptrflag) {
                    ptr1 = NULL;
                }
                else {
                    ix++;
                    ptr1 = &(arglist[ix].uint);
                }
                ix++;
                if (!arglist[ix].ptrflag) {
                    ptr2 = NULL;
                }
                else {
                    ix++;
                    ptr2 = &(arglist[ix].uint);
                }
                ix++;
                glk_window_get_size(arglist[0].opaqueref, ptr1, ptr2);
            }
            break;
        case 0x0026: /* window_set_arrangement */
            glk_window_set_arrangement(arglist[0].opaqueref, arglist[1].uint, 
                arglist[2].uint, arglist[3].opaqueref);
            break;
        case 0x0027: /* window_get_arrangement */
            {
                int ix = 1;
                glui32 *ptr1, *ptr2;
                winid_t *ptr3;
                if (!arglist[ix].ptrflag) {
                    ptr1 = NULL;
                }
                else {
                    ix++;
                    ptr1 = &(arglist[ix].uint);
                }
                ix++;
                if (!arglist[ix].ptrflag) {
                    ptr2 = NULL;
                }
                else {
                    ix++;
                    ptr2 = &(arglist[ix].uint);
                }
                ix++;
                if (!arglist[ix].ptrflag) {
                    ptr3 = NULL;
                }
                else {
                    ix++;
                    ptr3 = (winid_t *)(&(arglist[ix].opaqueref));
                }
                ix++;
                glk_window_get_arrangement(arglist[0].opaqueref, ptr1, ptr2, ptr3);
            }
            break;
        case 0x0028: /* window_get_type */
            arglist[2].uint = glk_window_get_type(arglist[0].opaqueref);
            break;
        case 0x0029: /* window_get_parent */
            arglist[2].opaqueref = glk_window_get_parent(arglist[0].opaqueref);
            break;
        case 0x002A: /* window_clear */
            glk_window_clear(arglist[0].opaqueref);
            break;
        case 0x002B: /* window_move_cursor */
            glk_window_move_cursor(arglist[0].opaqueref, arglist[1].uint, 
                arglist[2].uint);
            break;
        case 0x002C: /* window_get_stream */
            arglist[2].opaqueref = glk_window_get_stream(arglist[0].opaqueref);
            break;
        case 0x002D: /* window_set_echo_stream */
            glk_window_set_echo_stream(arglist[0].opaqueref, arglist[1].opaqueref);
            break;
        case 0x002E: /* window_get_echo_stream */
            arglist[2].opaqueref = glk_window_get_echo_stream(arglist[0].opaqueref);
            break;
        case 0x002F: /* set_window */
            glk_set_window(arglist[0].opaqueref);
            break;
        case 0x0030: /* window_get_sibling */
            arglist[2].opaqueref = glk_window_get_sibling(arglist[0].opaqueref);
            break;
        case 0x0040: /* stream_iterate */
            if (arglist[1].ptrflag) 
                arglist[4].opaqueref = glk_stream_iterate(arglist[0].opaqueref, &arglist[2].uint);
            else
                arglist[3].opaqueref = glk_stream_iterate(arglist[0].opaqueref, NULL);
            break;
        case 0x0041: /* stream_get_rock */
            arglist[2].uint = glk_stream_get_rock(arglist[0].opaqueref);
            break;
        case 0x0042: /* stream_open_file */
            arglist[4].opaqueref = glk_stream_open_file(arglist[0].opaqueref, arglist[1].uint, 
                arglist[2].uint);
            break;
        case 0x0043: /* stream_open_memory */
            if (arglist[0].ptrflag) 
                arglist[6].opaqueref = glk_stream_open_memory(arglist[1].array, 
                    arglist[2].uint, arglist[3].uint, arglist[4].uint);
            else
                arglist[4].opaqueref = glk_stream_open_memory(NULL, 
                    0, arglist[1].uint, arglist[2].uint);
            break;
        case 0x0044: /* stream_close */
            if (arglist[1].ptrflag) {
                stream_result_t dat;
                glk_stream_close(arglist[0].opaqueref, &dat);
                arglist[2].uint = dat.readcount;
                arglist[3].uint = dat.writecount;
            }
            else {
                glk_stream_close(arglist[0].opaqueref, NULL);
            }
            break;
        case 0x0045: /* stream_set_position */
            glk_stream_set_position(arglist[0].opaqueref, arglist[1].sint,
                arglist[2].uint);
            break;
        case 0x0046: /* stream_get_position */
            arglist[2].uint = glk_stream_get_position(arglist[0].opaqueref);
            break;
        case 0x0047: /* stream_set_current */
            glk_stream_set_current(arglist[0].opaqueref);
            break;
        case 0x0048: /* stream_get_current */
            arglist[1].opaqueref = glk_stream_get_current();
            break;
        case 0x0060: /* fileref_create_temp */
            arglist[3].opaqueref = glk_fileref_create_temp(arglist[0].uint, 
                arglist[1].uint);
            break;
        case 0x0061: /* fileref_create_by_name */
            arglist[4].opaqueref = glk_fileref_create_by_name(arglist[0].uint, 
                arglist[1].charstr, arglist[2].uint);
            break;
        case 0x0062: /* fileref_create_by_prompt */
            arglist[4].opaqueref = glk_fileref_create_by_prompt(arglist[0].uint, 
                arglist[1].uint, arglist[2].uint);
            break;
        case 0x0063: /* fileref_destroy */
            glk_fileref_destroy(arglist[0].opaqueref);
            break;
        case 0x0064: /* fileref_iterate */
            if (arglist[1].ptrflag) 
                arglist[4].opaqueref = glk_fileref_iterate(arglist[0].opaqueref, &arglist[2].uint);
            else
                arglist[3].opaqueref = glk_fileref_iterate(arglist[0].opaqueref, NULL);
            break;
        case 0x0065: /* fileref_get_rock */
            arglist[2].uint = glk_fileref_get_rock(arglist[0].opaqueref);
            break;
        case 0x0066: /* fileref_delete_file */
            glk_fileref_delete_file(arglist[0].opaqueref);
            break;
        case 0x0067: /* fileref_does_file_exist */
            arglist[2].uint = glk_fileref_does_file_exist(arglist[0].opaqueref);
            break;
        case 0x0068: /* fileref_create_from_fileref */
            arglist[4].opaqueref = glk_fileref_create_from_fileref(arglist[0].uint, 
                arglist[1].opaqueref, arglist[2].uint);
            break;
        case 0x0080: /* put_char */
            glk_put_char(arglist[0].uch);
            break;
        case 0x0081: /* put_char_stream */
            glk_put_char_stream(arglist[0].opaqueref, arglist[1].uch);
            break;
        case 0x0082: /* put_string */
            glk_put_string(arglist[0].charstr);
            break;
        case 0x0083: /* put_string_stream */
            glk_put_string_stream(arglist[0].opaqueref, arglist[1].charstr);
            break;
        case 0x0084: /* put_buffer */
            if (arglist[0].ptrflag) 
                glk_put_buffer(arglist[1].array, arglist[2].uint);
            else
                glk_put_buffer(NULL, 0);
            break;
        case 0x0085: /* put_buffer_stream */
            if (arglist[1].ptrflag) 
                glk_put_buffer_stream(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                glk_put_buffer_stream(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x0086: /* set_style */
            glk_set_style(arglist[0].uint);
            break;
        case 0x0087: /* set_style_stream */
            glk_set_style_stream(arglist[0].opaqueref, arglist[1].uint);
            break;
        case 0x0090: /* get_char_stream */
            arglist[2].sint = glk_get_char_stream(arglist[0].opaqueref);
            break;
        case 0x0091: /* get_line_stream */
            if (arglist[1].ptrflag) 
                arglist[5].uint = glk_get_line_stream(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                arglist[3].uint = glk_get_line_stream(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x0092: /* get_buffer_stream */
            if (arglist[1].ptrflag) 
                arglist[5].uint = glk_get_buffer_stream(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                arglist[3].uint = glk_get_buffer_stream(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x00A0: /* char_to_lower */
            arglist[2].uch = glk_char_to_lower(arglist[0].uch);
            break;
        case 0x00A1: /* char_to_upper */
            arglist[2].uch = glk_char_to_upper(arglist[0].uch);
            break;
        case 0x00B0: /* stylehint_set */
            glk_stylehint_set(arglist[0].uint, arglist[1].uint,
                arglist[2].uint, arglist[3].sint);
            break;
        case 0x00B1: /* stylehint_clear */
            glk_stylehint_clear(arglist[0].uint, arglist[1].uint,
                arglist[2].uint);
            break;
        case 0x00B2: /* style_distinguish */
            arglist[4].uint = glk_style_distinguish(arglist[0].opaqueref, arglist[1].uint,
                arglist[2].uint);
            break;
        case 0x00B3: /* style_measure */
            if (arglist[3].ptrflag)
                arglist[6].uint = glk_style_measure(arglist[0].opaqueref, arglist[1].uint,
                    arglist[2].uint, &(arglist[4].uint));
            else
                arglist[5].uint = glk_style_measure(arglist[0].opaqueref, arglist[1].uint,
                    arglist[2].uint, NULL);
            break;
        case 0x00C0: /* select */
            if (arglist[0].ptrflag) {
                event_t dat;
                glk_select(&dat);
                arglist[1].uint = dat.type;
                arglist[2].opaqueref = dat.win;
                arglist[3].uint = dat.val1;
                arglist[4].uint = dat.val2;
            }
            else {
                glk_select(NULL);
            }
            break;
        case 0x00C1: /* select_poll */
            if (arglist[0].ptrflag) {
                event_t dat;
                glk_select_poll(&dat);
                arglist[1].uint = dat.type;
                arglist[2].opaqueref = dat.win;
                arglist[3].uint = dat.val1;
                arglist[4].uint = dat.val2;
            }
            else {
                glk_select_poll(NULL);
            }
            break;
        case 0x00D0: /* request_line_event */
            if (arglist[1].ptrflag)
                glk_request_line_event(arglist[0].opaqueref, arglist[2].array,
                    arglist[3].uint, arglist[4].uint);
            else
                glk_request_line_event(arglist[0].opaqueref, NULL,
                    0, arglist[2].uint);
            break;
        case 0x00D1: /* cancel_line_event */
            if (arglist[1].ptrflag) {
                event_t dat;
                glk_cancel_line_event(arglist[0].opaqueref, &dat);
                arglist[2].uint = dat.type;
                arglist[3].opaqueref = dat.win;
                arglist[4].uint = dat.val1;
                arglist[5].uint = dat.val2;
            }
            else {
                glk_cancel_line_event(arglist[0].opaqueref, NULL);
            }
            break;
        case 0x00D2: /* request_char_event */
            glk_request_char_event(arglist[0].opaqueref);
            break;
        case 0x00D3: /* cancel_char_event */
            glk_cancel_char_event(arglist[0].opaqueref);
            break;
        case 0x00D4: /* request_mouse_event */
            glk_request_mouse_event(arglist[0].opaqueref);
            break;
        case 0x00D5: /* cancel_mouse_event */
            glk_cancel_mouse_event(arglist[0].opaqueref);
            break;
        case 0x00D6: /* request_timer_events */
            glk_request_timer_events(arglist[0].uint);
            break;

#ifdef GLK_MODULE_IMAGE
        case 0x00E0: /* image_get_info */
            {
                int ix = 1;
                glui32 *ptr1, *ptr2;
                if (!arglist[ix].ptrflag) {
                    ptr1 = NULL;
                }
                else {
                    ix++;
                    ptr1 = &(arglist[ix].uint);
                }
                ix++;
                if (!arglist[ix].ptrflag) {
                    ptr2 = NULL;
                }
                else {
                    ix++;
                    ptr2 = &(arglist[ix].uint);
                }
                ix++;
                ix++;
                arglist[ix].uint = glk_image_get_info(arglist[0].uint, ptr1, ptr2);
            }
            break;
        case 0x00E1: /* image_draw */
            arglist[5].uint = glk_image_draw(arglist[0].opaqueref, 
                arglist[1].uint,
                arglist[2].sint, arglist[3].sint);
            break;
        case 0x00E2: /* image_draw_scaled */
            arglist[7].uint = glk_image_draw_scaled(arglist[0].opaqueref, 
                arglist[1].uint,
                arglist[2].sint, arglist[3].sint,
                arglist[4].uint, arglist[5].uint);
            break;
        case 0x00E8: /* window_flow_break */
            glk_window_flow_break(arglist[0].opaqueref);
            break;
        case 0x00E9: /* window_erase_rect */
            glk_window_erase_rect(arglist[0].opaqueref,
                arglist[1].sint, arglist[2].sint,
                arglist[3].uint, arglist[4].uint);
            break;
        case 0x00EA: /* window_fill_rect */
            glk_window_fill_rect(arglist[0].opaqueref, arglist[1].uint,
                arglist[2].sint, arglist[3].sint,
                arglist[4].uint, arglist[5].uint);
            break;
        case 0x00EB: /* window_set_background_color */
            glk_window_set_background_color(arglist[0].opaqueref, arglist[1].uint);
            break;
#endif /* GLK_MODULE_IMAGE */

#ifdef GLK_MODULE_SOUND
        case 0x00F0: /* schannel_iterate */
            if (arglist[1].ptrflag) 
                arglist[4].opaqueref = glk_schannel_iterate(arglist[0].opaqueref, &arglist[2].uint);
            else
                arglist[3].opaqueref = glk_schannel_iterate(arglist[0].opaqueref, NULL);
            break;
        case 0x00F1: /* schannel_get_rock */
            arglist[2].uint = glk_schannel_get_rock(arglist[0].opaqueref);
            break;
        case 0x00F2: /* schannel_create */
            arglist[2].opaqueref = glk_schannel_create(arglist[0].uint);
            break;
        case 0x00F3: /* schannel_destroy */
            glk_schannel_destroy(arglist[0].opaqueref);
            break;
        case 0x00F8: /* schannel_play */
            arglist[3].uint = glk_schannel_play(arglist[0].opaqueref, arglist[1].uint);
            break;
        case 0x00F9: /* schannel_play_ext */
            arglist[5].uint = glk_schannel_play_ext(arglist[0].opaqueref, 
                arglist[1].uint, arglist[2].uint, arglist[3].uint);
            break;
        case 0x00FA: /* schannel_stop */
            glk_schannel_stop(arglist[0].opaqueref);
            break;
        case 0x00FB: /* schannel_set_volume */
            glk_schannel_set_volume(arglist[0].opaqueref, arglist[1].uint);
            break;
        case 0x00FC: /* sound_load_hint */
            glk_sound_load_hint(arglist[0].uint, arglist[1].uint);
            break;
#endif /* GLK_MODULE_SOUND */

#ifdef GLK_MODULE_HYPERLINKS
        case 0x0100: /* set_hyperlink */
            glk_set_hyperlink(arglist[0].uint);
            break;
        case 0x0101: /* set_hyperlink_stream */
            glk_set_hyperlink_stream(arglist[0].opaqueref, arglist[1].uint);
            break;
        case 0x0102: /* request_hyperlink_event */
            glk_request_hyperlink_event(arglist[0].opaqueref);
            break;
        case 0x0103: /* cancel_hyperlink_event */
            glk_cancel_hyperlink_event(arglist[0].opaqueref);
            break;
#endif /* GLK_MODULE_HYPERLINKS */
            
#ifdef GLK_MODULE_UNICODE
        case 0x0120: /* buffer_to_lower_case_uni */
            if (arglist[0].ptrflag) 
                arglist[5].uint = glk_buffer_to_lower_case_uni(arglist[1].array, arglist[2].uint, arglist[3].uint);
            else
                arglist[3].uint = glk_buffer_to_lower_case_uni(NULL, 0, arglist[1].uint);
            break;
        case 0x0121: /* buffer_to_upper_case_uni */
            if (arglist[0].ptrflag) 
                arglist[5].uint = glk_buffer_to_upper_case_uni(arglist[1].array, arglist[2].uint, arglist[3].uint);
            else
                arglist[3].uint = glk_buffer_to_upper_case_uni(NULL, 0, arglist[1].uint);
            break;
        case 0x0122: /* buffer_to_title_case_uni */
            if (arglist[0].ptrflag) 
                arglist[6].uint = glk_buffer_to_title_case_uni(arglist[1].array, arglist[2].uint, arglist[3].uint, arglist[4].uint);
            else
                arglist[4].uint = glk_buffer_to_title_case_uni(NULL, 0, arglist[1].uint, arglist[2].uint);
            break;
        case 0x0128: /* put_char_uni */
            glk_put_char_uni(arglist[0].uint);
            break;
        case 0x0129: /* put_string_uni */
            glk_put_string_uni(arglist[0].unicharstr);
            break;
        case 0x012A: /* put_buffer_uni */
            if (arglist[0].ptrflag) 
                glk_put_buffer_uni(arglist[1].array, arglist[2].uint);
            else
                glk_put_buffer_uni(NULL, 0);
            break;
        case 0x012B: /* put_char_stream_uni */
            glk_put_char_stream_uni(arglist[0].opaqueref, arglist[1].uint);
            break;
        case 0x012C: /* put_string_stream_uni */
            glk_put_string_stream_uni(arglist[0].opaqueref, arglist[1].unicharstr);
            break;
        case 0x012D: /* put_buffer_stream_uni */
            if (arglist[1].ptrflag) 
                glk_put_buffer_stream_uni(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                glk_put_buffer_stream_uni(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x0130: /* get_char_stream_uni */
            arglist[2].sint = glk_get_char_stream_uni(arglist[0].opaqueref);
            break;
        case 0x0131: /* get_buffer_stream_uni */
            if (arglist[1].ptrflag) 
                arglist[5].uint = glk_get_buffer_stream_uni(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                arglist[3].uint = glk_get_buffer_stream_uni(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x0132: /* get_line_stream_uni */
            if (arglist[1].ptrflag) 
                arglist[5].uint = glk_get_line_stream_uni(arglist[0].opaqueref, 
                    arglist[2].array, arglist[3].uint);
            else
                arglist[3].uint = glk_get_line_stream_uni(arglist[0].opaqueref, 
                    NULL, 0);
            break;
        case 0x0138: /* stream_open_file_uni */
            arglist[4].opaqueref = glk_stream_open_file_uni(arglist[0].opaqueref, arglist[1].uint, 
                arglist[2].uint);
            break;
        case 0x0139: /* stream_open_memory_uni */
            if (arglist[0].ptrflag) 
                arglist[6].opaqueref = glk_stream_open_memory_uni(arglist[1].array, 
                    arglist[2].uint, arglist[3].uint, arglist[4].uint);
            else
                arglist[4].opaqueref = glk_stream_open_memory_uni(NULL, 
                    0, arglist[1].uint, arglist[2].uint);
            break;
        case 0x0140: /* request_char_event_uni */
            glk_request_char_event_uni(arglist[0].opaqueref);
            break;
        case 0x0141: /* request_line_event_uni */
            if (arglist[1].ptrflag)
                glk_request_line_event_uni(arglist[0].opaqueref, arglist[2].array,
                    arglist[3].uint, arglist[4].uint);
            else
                glk_request_line_event_uni(arglist[0].opaqueref, NULL,
                    0, arglist[2].uint);
            break;
#endif /* GLK_MODULE_UNICODE */
            
        default:
            /* do nothing */
            break;
    }
}

