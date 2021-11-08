[CInputOutputModel::] C Input-Output Model.

How C programs print text out, really.

@h Setting up the model.

=
void CInputOutputModel::initialise(code_generator *cgt) {
}

void CInputOutputModel::initialise_data(code_generation *gen) {
}

void CInputOutputModel::begin(code_generation *gen) {
}

void CInputOutputModel::end(code_generation *gen) {
}

@ By input/output, we mean printing text, receiving textual commands, or reading
or writing files. Inter can do this in one of two ways: either

(a) With one of the following primitives, or
(b) With an assembly-language opcode, and in particular |@glk|.

=
int CInputOutputModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case SPACES_BIP:
			WRITE("for (int j = "); VNODE_1C;
			WRITE("; j > 0; j--) i7_print_char(proc, 32);"); break;
		case FONT_BIP:
			WRITE("i7_styling(proc, 1, "); VNODE_1C; WRITE(")"); break;
		case STYLE_BIP:
			WRITE("i7_styling(proc, 2, "); VNODE_1C; WRITE(")"); break;
		case PRINT_BIP:
			WRITE("i7_print_C_string(proc, ");
			CodeGen::lt_mode(gen, PRINTING_LTM); VNODE_1C;
			CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		case PRINTCHAR_BIP:
			WRITE("i7_print_char(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINTNL_BIP:
			WRITE("i7_print_char(proc, '\\n')"); break;
		case PRINTOBJ_BIP:
			WRITE("i7_print_object(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINTNUMBER_BIP:
			WRITE("i7_print_decimal(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINTSTRING_BIP:
			WRITE("i7_print_C_string(proc, i7_text_to_C_string("); VNODE_1C;
			WRITE("))"); break;
		case PRINTDWORD_BIP:
			WRITE("i7_print_dword(proc, "); VNODE_1C; WRITE(")"); break;
		case BOX_BIP:
			WRITE("i7_print_box(proc, "); CodeGen::lt_mode(gen, BOX_LTM); VNODE_1C;
			CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@ See //C Literals// for the implementation of |i7_print_dword|: it funnels
through to |i7_print_char|, and so do all of these:

= (text to inform7_clib.h)
void i7_print_C_string(i7process_t *proc, char *c_string);
void i7_print_decimal(i7process_t *proc, i7word_t x);
void i7_print_object(i7process_t *proc, i7word_t x);
void i7_print_box(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
void i7_print_C_string(i7process_t *proc, char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char(proc, (i7word_t) c_string[i]);
}

void i7_print_decimal(i7process_t *proc, i7word_t x) {
	char room[32];
	sprintf(room, "%d", (int) x);
	i7_print_C_string(proc, room);
}

void i7_print_object(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void i7_print_box(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit(proc);
}
=

@ Which in turn uses the |@glk| opcode:

= (text to inform7_clib.h)
void i7_print_char(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
void i7_print_char(i7process_t *proc, i7word_t x) {
	if (x == 13) x = 10;
	i7_push(proc, x);
	i7word_t current = 0;
	i7_opcode_glk(proc, i7_glk_stream_get_current, 0, &current);
	i7_push(proc, current);
	i7_opcode_glk(proc, i7_glk_put_char_stream, 2, NULL);
}
=

@ At this point, then, all of our I/O needs will be handled if we can just
define two functions: |i7_styling|, for setting the font style, and |i7_opcode_glk|.
So we're nearly done, right? Right?

But in fact we route both of these functions through hooks which the user can
provide, so that the user can change the entire I/O model (if she is willing to
code up an alternative):

= (text to inform7_clib.h)
void i7_styling(i7process_t *proc, i7word_t which, i7word_t what);
void i7_default_stylist(i7process_t *proc, i7word_t which, i7word_t what);
void i7_opcode_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z);
void i7_default_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z);
=

= (text to inform7_clib.c)
void i7_styling(i7process_t *proc, i7word_t which, i7word_t what) {
	(proc->stylist)(proc, which, what);
}
void i7_opcode_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z) {
	(proc->glk_implementation)(proc, glk_api_selector, varargc, z);
}
=

@ What makes this more burdensome is that |@glk| is not so much a single opcode
as an entire instruction set: it is an compendium of over 120 disparate operations.
Indeed, the |glk_api_selector| argument to |i7_opcode_glk| chooses which one is
being used. For convenience, we define a set of names for them all -- which does
not imply any commitment to implement them all.

= (text to inform7_clib.h)
#define i7_glk_exit 0x0001
#define i7_glk_set_interrupt_handler 0x0002
#define i7_glk_tick 0x0003
#define i7_glk_gestalt 0x0004
#define i7_glk_gestalt_ext 0x0005
#define i7_glk_window_iterate 0x0020
#define i7_glk_window_get_rock 0x0021
#define i7_glk_window_get_root 0x0022
#define i7_glk_window_open 0x0023
#define i7_glk_window_close 0x0024
#define i7_glk_window_get_size 0x0025
#define i7_glk_window_set_arrangement 0x0026
#define i7_glk_window_get_arrangement 0x0027
#define i7_glk_window_get_type 0x0028
#define i7_glk_window_get_parent 0x0029
#define i7_glk_window_clear 0x002A
#define i7_glk_window_move_cursor 0x002B
#define i7_glk_window_get_stream 0x002C
#define i7_glk_window_set_echo_stream 0x002D
#define i7_glk_window_get_echo_stream 0x002E
#define i7_glk_set_window 0x002F
#define i7_glk_window_get_sibling 0x0030
#define i7_glk_stream_iterate 0x0040
#define i7_glk_stream_get_rock 0x0041
#define i7_glk_stream_open_file 0x0042
#define i7_glk_stream_open_memory 0x0043
#define i7_glk_stream_close 0x0044
#define i7_glk_stream_set_position 0x0045
#define i7_glk_stream_get_position 0x0046
#define i7_glk_stream_set_current 0x0047
#define i7_glk_stream_get_current 0x0048
#define i7_glk_stream_open_resource 0x0049
#define i7_glk_fileref_create_temp 0x0060
#define i7_glk_fileref_create_by_name 0x0061
#define i7_glk_fileref_create_by_prompt 0x0062
#define i7_glk_fileref_destroy 0x0063
#define i7_glk_fileref_iterate 0x0064
#define i7_glk_fileref_get_rock 0x0065
#define i7_glk_fileref_delete_file 0x0066
#define i7_glk_fileref_does_file_exist 0x0067
#define i7_glk_fileref_create_from_fileref 0x0068
#define i7_glk_put_char 0x0080
#define i7_glk_put_char_stream 0x0081
#define i7_glk_put_string 0x0082
#define i7_glk_put_string_stream 0x0083
#define i7_glk_put_buffer 0x0084
#define i7_glk_put_buffer_stream 0x0085
#define i7_glk_set_style 0x0086
#define i7_glk_set_style_stream 0x0087
#define i7_glk_get_char_stream 0x0090
#define i7_glk_get_line_stream 0x0091
#define i7_glk_get_buffer_stream 0x0092
#define i7_glk_char_to_lower 0x00A0
#define i7_glk_char_to_upper 0x00A1
#define i7_glk_stylehint_set 0x00B0
#define i7_glk_stylehint_clear 0x00B1
#define i7_glk_style_distinguish 0x00B2
#define i7_glk_style_measure 0x00B3
#define i7_glk_select 0x00C0
#define i7_glk_select_poll 0x00C1
#define i7_glk_request_line_event 0x00D0
#define i7_glk_cancel_line_event 0x00D1
#define i7_glk_request_char_event 0x00D2
#define i7_glk_cancel_char_event 0x00D3
#define i7_glk_request_mouse_event 0x00D4
#define i7_glk_cancel_mouse_event 0x00D5
#define i7_glk_request_timer_events 0x00D6
#define i7_glk_image_get_info 0x00E0
#define i7_glk_image_draw 0x00E1
#define i7_glk_image_draw_scaled 0x00E2
#define i7_glk_window_flow_break 0x00E8
#define i7_glk_window_erase_rect 0x00E9
#define i7_glk_window_fill_rect 0x00EA
#define i7_glk_window_set_background_color 0x00EB
#define i7_glk_schannel_iterate 0x00F0
#define i7_glk_schannel_get_rock 0x00F1
#define i7_glk_schannel_create 0x00F2
#define i7_glk_schannel_destroy 0x00F3
#define i7_glk_schannel_create_ext 0x00F4
#define i7_glk_schannel_play_multi 0x00F7
#define i7_glk_schannel_play 0x00F8
#define i7_glk_schannel_play_ext 0x00F9
#define i7_glk_schannel_stop 0x00FA
#define i7_glk_schannel_set_volume 0x00FB
#define i7_glk_sound_load_hint 0x00FC
#define i7_glk_schannel_set_volume_ext 0x00FD
#define i7_glk_schannel_pause 0x00FE
#define i7_glk_schannel_unpause 0x00FF
#define i7_glk_set_hyperlink 0x0100
#define i7_glk_set_hyperlink_stream 0x0101
#define i7_glk_request_hyperlink_event 0x0102
#define i7_glk_cancel_hyperlink_event 0x0103
#define i7_glk_buffer_to_lower_case_uni 0x0120
#define i7_glk_buffer_to_upper_case_uni 0x0121
#define i7_glk_buffer_to_title_case_uni 0x0122
#define i7_glk_buffer_canon_decompose_uni 0x0123
#define i7_glk_buffer_canon_normalize_uni 0x0124
#define i7_glk_put_char_uni 0x0128
#define i7_glk_put_string_uni 0x0129
#define i7_glk_put_buffer_uni 0x012A
#define i7_glk_put_char_stream_uni 0x012B
#define i7_glk_put_string_stream_uni 0x012C
#define i7_glk_put_buffer_stream_uni 0x012D
#define i7_glk_get_char_stream_uni 0x0130
#define i7_glk_get_buffer_stream_uni 0x0131
#define i7_glk_get_line_stream_uni 0x0132
#define i7_glk_stream_open_file_uni 0x0138
#define i7_glk_stream_open_memory_uni 0x0139
#define i7_glk_stream_open_resource_uni 0x013A
#define i7_glk_request_char_event_uni 0x0140
#define i7_glk_request_line_event_uni 0x0141
#define i7_glk_set_echo_line_event 0x0150
#define i7_glk_set_terminators_line_event 0x0151
#define i7_glk_current_time 0x0160
#define i7_glk_current_simple_time 0x0161
#define i7_glk_time_to_date_utc 0x0168
#define i7_glk_time_to_date_local 0x0169
#define i7_glk_simple_time_to_date_utc 0x016A
#define i7_glk_simple_time_to_date_local 0x016B
#define i7_glk_date_to_time_utc 0x016C
#define i7_glk_date_to_time_local 0x016D
#define i7_glk_date_to_simple_time_utc 0x016E
#define i7_glk_date_to_simple_time_local 0x016F
=

A few other constants will also be useful. These are the window IDs for the
three Glk windows used by the standard Inform 7 kits: |I7_BODY_TEXT_ID| is
where text is regularly printed; |I7_STATUS_TEXT_ID| is for the "status line"
at the top of a traditional interactive fiction display, but can simply be
ignored for non-IF purposes; and |I7_BOX_TEXT_ID| is where box quotations
would be displayed over the top of text, though C projects probably should
not use this, and the default Glk implementation here ignores it.

= (text to inform7_clib.h)
#define I7_BODY_TEXT_ID          201
#define I7_STATUS_TEXT_ID        202
#define I7_BOX_TEXT_ID           203
=

These are needed for different forms of file I/O:

= (text to inform7_clib.h)
#define i7_fileusage_Data        0x00
#define i7_fileusage_SavedGame   0x01
#define i7_fileusage_Transcript  0x02
#define i7_fileusage_InputRecord 0x03
#define i7_fileusage_TypeMask    0x0f
#define i7_fileusage_TextMode    0x100
#define i7_fileusage_BinaryMode  0x000

#define i7_filemode_Write        0x01
#define i7_filemode_Read         0x02
#define i7_filemode_ReadWrite    0x03
#define i7_filemode_WriteAppend  0x05
=

And these are modes for seeking a position in a file:

= (text to inform7_clib.h)
#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)
=

And these are "event types":

= (text to inform7_clib.h)
#define i7_evtype_None           0
#define i7_evtype_Timer          1
#define i7_evtype_CharInput      2
#define i7_evtype_LineInput      3
#define i7_evtype_MouseInput     4
#define i7_evtype_Arrange        5
#define i7_evtype_Redraw         6
#define i7_evtype_SoundNotify    7
#define i7_evtype_Hyperlink      8
#define i7_evtype_VolumeNotify   9
=
