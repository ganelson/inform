[CSInputOutputModel::] C# Input-Output Model.

How C# programs print text out, really.

@h Setting up the model.

=
void CSInputOutputModel::initialise(code_generator *gtr) {
}

void CSInputOutputModel::initialise_data(code_generation *gen) {
}

void CSInputOutputModel::begin(code_generation *gen) {
}

void CSInputOutputModel::end(code_generation *gen) {
}

@ By input/output, we mean printing text, receiving textual commands, or reading
or writing files. Inter can do this in one of two ways: either

(a) With one of the following primitives, or
(b) With an assembly-language opcode, and in particular |@glk|.

=
int CSInputOutputModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case SPACES_BIP:
			WRITE("for (int j = "); VNODE_1C;
			WRITE("; j > 0; j--) proc.i7_print_char(32);"); break;
		case FONT_BIP:
			WRITE("proc.i7_styling(1, "); VNODE_1C; WRITE(")"); break;
		case STYLE_BIP:
			WRITE("proc.i7_styling(2, "); VNODE_1C; WRITE(")"); break;
		case PRINT_BIP:
			WRITE("proc.i7_print_CLR_string(");
			CodeGen::lt_mode(gen, PRINTING_LTM); VNODE_1C;
			CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		case PRINTCHAR_BIP:
			WRITE("proc.i7_print_char("); VNODE_1C; WRITE(")"); break;
		case PRINTNL_BIP:
			WRITE("proc.i7_print_char('\\n')"); break;
		case PRINTOBJ_BIP:
			WRITE("proc.i7_print_object("); VNODE_1C; WRITE(")"); break;
		case PRINTNUMBER_BIP:
			WRITE("proc.i7_print_decimal("); VNODE_1C; WRITE(")"); break;
		case PRINTSTRING_BIP:
			WRITE("proc.i7_print_CLR_string(proc.i7_text_to_CLR_string("); VNODE_1C;
			WRITE("))"); break;
		case PRINTDWORD_BIP:
			WRITE("proc.i7_print_dword("); VNODE_1C; WRITE(")"); break;
		case BOX_BIP:
			WRITE("proc.i7_print_box("); CodeGen::lt_mode(gen, BOX_LTM); VNODE_1C;
			CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		case ENABLEPRINTING_BIP:
			WRITE("{ int window_id;\n");
			WRITE("proc.i7_opcode_setiosys(2, 0); // Set to use Glk\n");
			WRITE("proc.i7_push(201); // = GG_MAINWIN_ROCK;\n");
			WRITE("proc.i7_push(3); // = wintype_TextBuffer;\n");
			WRITE("proc.i7_push(0);\n");
			WRITE("proc.i7_push(0);\n");
			WRITE("proc.i7_push(0);\n");
			WRITE("proc.i7_opcode_glk(35, 5, out window_id); // glk_window_open, pushing a window ID\n");
			WRITE("proc.i7_push(window_id);\n");
			WRITE("proc.i7_opcode_glk(47, 1, out int _); // glk_set_window to that window ID\n");
			WRITE("}\n");
			break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@ See //C# Literals// for the implementation of |i7_print_dword|: it funnels
through to |i7_print_char|, and so do all of these:


= (text to inform7_cslib.cs)
partial class Process {
	public void i7_print_CLR_string(string clr_string) {
		if (clr_string != null)
			for (int i=0; i < clr_string.Length; i++)
				i7_print_char((int) clr_string[i]);
	}

	public void i7_print_decimal(int x) {
        i7_print_CLR_string(x.ToString());
	}

	public void i7_print_object(int x) {
		i7_print_decimal(x);
	}

	public void i7_print_box(int x) {
		Console.WriteLine("Unimplemented: i7_print_box.");
		i7_fatal_exit();
	}
=

@ Which in turn uses the |@glk| opcode:
= (text to inform7_cslib.cs)
	internal void i7_print_char(int x) {
		if (x == 13) x = 10;
		i7_push(x);
		int current = 0;
		i7_opcode_glk(GlkOpcodes.i7_glk_stream_get_current, 0, out current);
		i7_push(current);
		i7_opcode_glk(GlkOpcodes.i7_glk_put_char_stream, 2, out int _);
	}
=

@ At this point, then, all of our I/O needs will be handled if we can just
define two functions: |i7_styling|, for setting the font style, and |i7_opcode_glk|.
So we're nearly done, right? Right?

But in fact we route both of these functions through hooks which the user can
provide, so that the user can change the entire I/O model (if she is willing to
code up an alternative):

= (text to inform7_cslib.cs)
	internal void i7_styling(int which, int what) {
		stylist(this, which, what);
	}
	internal void i7_opcode_glk(int glk_api_selector, int varargc,
		out int z) {
		z = glk_implementation(this, glk_api_selector, varargc);
	}
}
=

@ What makes this more burdensome is that |@glk| is not so much a single opcode
as an entire instruction set: it is an compendium of over 120 disparate operations.
Indeed, the |glk_api_selector| argument to |i7_opcode_glk| chooses which one is
being used. For convenience, we define a set of names for them all -- which does
not imply any commitment to implement them all.

= (text to inform7_cslib.cs)
public static class GlkOpcodes {
	public const int i7_glk_exit = 0x0001;
	public const int i7_glk_set_interrupt_handler = 0x0002;
	public const int i7_glk_tick = 0x0003;
	public const int i7_glk_gestalt = 0x0004;
	public const int i7_glk_gestalt_ext = 0x0005;
	public const int i7_glk_window_iterate = 0x0020;
	public const int i7_glk_window_get_rock = 0x0021;
	public const int i7_glk_window_get_root = 0x0022;
	public const int i7_glk_window_open = 0x0023;
	public const int i7_glk_window_close = 0x0024;
	public const int i7_glk_window_get_size = 0x0025;
	public const int i7_glk_window_set_arrangement = 0x0026;
	public const int i7_glk_window_get_arrangement = 0x0027;
	public const int i7_glk_window_get_type = 0x0028;
	public const int i7_glk_window_get_parent = 0x0029;
	public const int i7_glk_window_clear = 0x002A;
	public const int i7_glk_window_move_cursor = 0x002B;
	public const int i7_glk_window_get_stream = 0x002C;
	public const int i7_glk_window_set_echo_stream = 0x002D;
	public const int i7_glk_window_get_echo_stream = 0x002E;
	public const int i7_glk_set_window = 0x002F;
	public const int i7_glk_window_get_sibling = 0x0030;
	public const int i7_glk_stream_iterate = 0x0040;
	public const int i7_glk_stream_get_rock = 0x0041;
	public const int i7_glk_stream_open_file = 0x0042;
	public const int i7_glk_stream_open_memory = 0x0043;
	public const int i7_glk_stream_close = 0x0044;
	public const int i7_glk_stream_set_position = 0x0045;
	public const int i7_glk_stream_get_position = 0x0046;
	public const int i7_glk_stream_set_current = 0x0047;
	public const int i7_glk_stream_get_current = 0x0048;
	public const int i7_glk_stream_open_resource = 0x0049;
	public const int i7_glk_fileref_create_temp = 0x0060;
	public const int i7_glk_fileref_create_by_name = 0x0061;
	public const int i7_glk_fileref_create_by_prompt = 0x0062;
	public const int i7_glk_fileref_destroy = 0x0063;
	public const int i7_glk_fileref_iterate = 0x0064;
	public const int i7_glk_fileref_get_rock = 0x0065;
	public const int i7_glk_fileref_delete_file = 0x0066;
	public const int i7_glk_fileref_does_file_exist = 0x0067;
	public const int i7_glk_fileref_create_from_fileref = 0x0068;
	public const int i7_glk_put_char = 0x0080;
	public const int i7_glk_put_char_stream = 0x0081;
	public const int i7_glk_put_string = 0x0082;
	public const int i7_glk_put_string_stream = 0x0083;
	public const int i7_glk_put_buffer = 0x0084;
	public const int i7_glk_put_buffer_stream = 0x0085;
	public const int i7_glk_set_style = 0x0086;
	public const int i7_glk_set_style_stream = 0x0087;
	public const int i7_glk_get_char_stream = 0x0090;
	public const int i7_glk_get_line_stream = 0x0091;
	public const int i7_glk_get_buffer_stream = 0x0092;
	public const int i7_glk_char_to_lower = 0x00A0;
	public const int i7_glk_char_to_upper = 0x00A1;
	public const int i7_glk_stylehint_set = 0x00B0;
	public const int i7_glk_stylehint_clear = 0x00B1;
	public const int i7_glk_style_distinguish = 0x00B2;
	public const int i7_glk_style_measure = 0x00B3;
	public const int i7_glk_select = 0x00C0;
	public const int i7_glk_select_poll = 0x00C1;
	public const int i7_glk_request_line_event = 0x00D0;
	public const int i7_glk_cancel_line_event = 0x00D1;
	public const int i7_glk_request_char_event = 0x00D2;
	public const int i7_glk_cancel_char_event = 0x00D3;
	public const int i7_glk_request_mouse_event = 0x00D4;
	public const int i7_glk_cancel_mouse_event = 0x00D5;
	public const int i7_glk_request_timer_events = 0x00D6;
	public const int i7_glk_image_get_info = 0x00E0;
	public const int i7_glk_image_draw = 0x00E1;
	public const int i7_glk_image_draw_scaled = 0x00E2;
	public const int i7_glk_window_flow_break = 0x00E8;
	public const int i7_glk_window_erase_rect = 0x00E9;
	public const int i7_glk_window_fill_rect = 0x00EA;
	public const int i7_glk_window_set_background_color = 0x00EB;
	public const int i7_glk_schannel_iterate = 0x00F0;
	public const int i7_glk_schannel_get_rock = 0x00F1;
	public const int i7_glk_schannel_create = 0x00F2;
	public const int i7_glk_schannel_destroy = 0x00F3;
	public const int i7_glk_schannel_create_ext = 0x00F4;
	public const int i7_glk_schannel_play_multi = 0x00F7;
	public const int i7_glk_schannel_play = 0x00F8;
	public const int i7_glk_schannel_play_ext = 0x00F9;
	public const int i7_glk_schannel_stop = 0x00FA;
	public const int i7_glk_schannel_set_volume = 0x00FB;
	public const int i7_glk_sound_load_hint = 0x00FC;
	public const int i7_glk_schannel_set_volume_ext = 0x00FD;
	public const int i7_glk_schannel_pause = 0x00FE;
	public const int i7_glk_schannel_unpause = 0x00FF;
	public const int i7_glk_set_hyperlink = 0x0100;
	public const int i7_glk_set_hyperlink_stream = 0x0101;
	public const int i7_glk_request_hyperlink_event = 0x0102;
	public const int i7_glk_cancel_hyperlink_event = 0x0103;
	public const int i7_glk_buffer_to_lower_case_uni = 0x0120;
	public const int i7_glk_buffer_to_upper_case_uni = 0x0121;
	public const int i7_glk_buffer_to_title_case_uni = 0x0122;
	public const int i7_glk_buffer_canon_decompose_uni = 0x0123;
	public const int i7_glk_buffer_canon_normalize_uni = 0x0124;
	public const int i7_glk_put_char_uni = 0x0128;
	public const int i7_glk_put_string_uni = 0x0129;
	public const int i7_glk_put_buffer_uni = 0x012A;
	public const int i7_glk_put_char_stream_uni = 0x012B;
	public const int i7_glk_put_string_stream_uni = 0x012C;
	public const int i7_glk_put_buffer_stream_uni = 0x012D;
	public const int i7_glk_get_char_stream_uni = 0x0130;
	public const int i7_glk_get_buffer_stream_uni = 0x0131;
	public const int i7_glk_get_line_stream_uni = 0x0132;
	public const int i7_glk_stream_open_file_uni = 0x0138;
	public const int i7_glk_stream_open_memory_uni = 0x0139;
	public const int i7_glk_stream_open_resource_uni = 0x013A;
	public const int i7_glk_request_char_event_uni = 0x0140;
	public const int i7_glk_request_line_event_uni = 0x0141;
	public const int i7_glk_set_echo_line_event = 0x0150;
	public const int i7_glk_set_terminators_line_event = 0x0151;
	public const int i7_glk_current_time = 0x0160;
	public const int i7_glk_current_simple_time = 0x0161;
	public const int i7_glk_time_to_date_utc = 0x0168;
	public const int i7_glk_time_to_date_local = 0x0169;
	public const int i7_glk_simple_time_to_date_utc = 0x016A;
	public const int i7_glk_simple_time_to_date_local = 0x016B;
	public const int i7_glk_date_to_time_utc = 0x016C;
	public const int i7_glk_date_to_time_local = 0x016D;
	public const int i7_glk_date_to_simple_time_utc = 0x016E;
	public const int i7_glk_date_to_simple_time_local = 0x016F;
}
=

A few other constants will also be useful. These are the window IDs for the
three Glk windows used by the standard Inform 7 kits: |I7_BODY_TEXT_ID| is
where text is regularly printed; |I7_STATUS_TEXT_ID| is for the "status line"
at the top of a traditional interactive fiction display, but can simply be
ignored for non-IF purposes; and |I7_BOX_TEXT_ID| is where box quotations
would be displayed over the top of text, though C projects probably should
not use this, and the default Glk implementation here ignores it.

= (text to inform7_cslib.cs)
partial class Process {
	public const int I7_BODY_TEXT_ID         = 201;
	public const int I7_STATUS_TEXT_ID       = 202;
	public const int I7_BOX_TEXT_ID          = 203;
=

These are needed for different forms of file I/O:

= (text to inform7_cslib.cs)
	public const int i7_fileusage_Data        = 0x00;
	public const int i7_fileusage_SavedGame   = 0x01;
	public const int i7_fileusage_Transcript  = 0x02;
	public const int i7_fileusage_InputRecord = 0x03;
	public const int i7_fileusage_TypeMask    = 0x0f;
	public const int i7_fileusage_TextMode    = 0x100;
	public const int i7_fileusage_BinaryMode  = 0x000;

	public const int i7_filemode_Write        = 0x01;
	public const int i7_filemode_Read         = 0x02;
	public const int i7_filemode_ReadWrite    = 0x03;
	public const int i7_filemode_WriteAppend  = 0x05;
=

And these are modes for seeking a position in a file:

= (text to inform7_cslib.cs)
	public const int i7_seekmode_Start = (0);
	public const int i7_seekmode_Current = (1);
	public const int i7_seekmode_End = (2);
=

And these are "event types":

= (text to inform7_cslib.cs)
	public const int i7_evtype_None           = 0;
	public const int i7_evtype_Timer          = 1;
	public const int i7_evtype_CharInput      = 2;
	public const int i7_evtype_LineInput      = 3;
	public const int i7_evtype_MouseInput     = 4;
	public const int i7_evtype_Arrange        = 5;
	public const int i7_evtype_Redraw         = 6;
	public const int i7_evtype_SoundNotify    = 7;
	public const int i7_evtype_Hyperlink      = 8;
	public const int i7_evtype_VolumeNotify   = 9;
}
=

Finally, these are the gestalt values: that is, the selection of bells and
whistles which a Glk implementation can offer --

= (text to inform7_cslib.cs)
public static class GlkGestalts {
	public const int i7_gestalt_Version						= 0;
	public const int i7_gestalt_CharInput					= 1;
	public const int i7_gestalt_LineInput					= 2;
	public const int i7_gestalt_CharOutput					= 3;
		public const int i7_gestalt_CharOutput_ApproxPrint	= 1;
		public const int i7_gestalt_CharOutput_CannotPrint	= 0;
		public const int i7_gestalt_CharOutput_ExactPrint	= 2;
	public const int i7_gestalt_MouseInput					= 4;
	public const int i7_gestalt_Timer						= 5;
	public const int i7_gestalt_Graphics					= 6;
	public const int i7_gestalt_DrawImage					= 7;
	public const int i7_gestalt_Sound						= 8;
	public const int i7_gestalt_SoundVolume					= 9;
	public const int i7_gestalt_SoundNotify					= 10;
	public const int i7_gestalt_Hyperlinks					= 11;
	public const int i7_gestalt_HyperlinkInput				= 12;
	public const int i7_gestalt_SoundMusic					= 13;
	public const int i7_gestalt_GraphicsTransparency		= 14;
	public const int i7_gestalt_Unicode						= 15;
	public const int i7_gestalt_UnicodeNorm					= 16;
	public const int i7_gestalt_LineInputEcho				= 17;
	public const int i7_gestalt_LineTerminators				= 18;
	public const int i7_gestalt_LineTerminatorKey			= 19;
	public const int i7_gestalt_DateTime					= 20;
	public const int i7_gestalt_Sound2						= 21;
	public const int i7_gestalt_ResourceStream				= 22;
	public const int i7_gestalt_GraphicsCharInput			= 23;
}