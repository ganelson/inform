[CInputOutputModel::] C Input-Output Model.

How C programs print text out, really.

@h Setting up the model.

=
void CInputOutputModel::initialise(code_generation_target *cgt) {
}

void CInputOutputModel::initialise_data(code_generation *gen) {
}

void CInputOutputModel::begin(code_generation *gen) {
}

void CInputOutputModel::end(code_generation *gen) {
}

@

=
int CInputOutputModel::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case INVERSION_BIP:	     break; /* we won't support this in C */
		case SPACES_BIP:		 WRITE("for (int j = "); INV_A1; WRITE("; j >= 0; j--) i7_print_char(32);"); break;
		case FONT_BIP:           WRITE("i7_font("); INV_A1; WRITE(")"); break;
		case STYLEROMAN_BIP:     WRITE("i7_style(i7_roman)"); break;
		case STYLEBOLD_BIP:      WRITE("i7_style(i7_bold)"); break;
		case STYLEUNDERLINE_BIP: WRITE("i7_style(i7_underline)"); break;
		case STYLEREVERSE_BIP:   WRITE("i7_style(i7_reverse)"); break;
		case PRINT_BIP:          WRITE("i7_print_C_string("); INV_A1_PRINTMODE; WRITE(")"); break;
		case PRINTRET_BIP:       WRITE("i7_print_C_string("); INV_A1_PRINTMODE; WRITE("); return 1"); break;
		case PRINTCHAR_BIP:      WRITE("i7_print_char("); INV_A1; WRITE(")"); break;
		case PRINTOBJ_BIP:       WRITE("i7_print_object("); INV_A1; WRITE(")"); break;
		case PRINTNUMBER_BIP:    WRITE("i7_print_decimal("); INV_A1; WRITE(")"); break;
		case BOX_BIP:            WRITE("i7_print_box("); INV_A1_BOXMODE; WRITE(")"); break;
		case READ_BIP:           WRITE("i7_read("); INV_A1; WRITE(", "); INV_A2; WRITE(")"); break;

		default: 				 return NOT_APPLICABLE;
	}
	return FALSE;
}

@

= (text to inform7_clib.h)
#define i7_bold 1
#define i7_roman 2
#define i7_underline 3
#define i7_reverse 4

void i7_style(int what) {
}

void i7_font(int what) {
}

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

typedef struct i7_fileref {
	i7val usage;
	i7val name;
	i7val rock;
	char leafname[128];
	FILE *handle;
} i7_fileref;

i7_fileref filerefs[128 + 32];
int i7_no_filerefs = 0;

i7val i7_do_glk_fileref_create_by_name(i7val usage, i7val name, i7val rock) {
	if (i7_no_filerefs >= 128) {
		fprintf(stderr, "Out of streams\n"); i7_fatal_exit();
	}
	int id = i7_no_filerefs++;
	filerefs[id].usage = usage;
	filerefs[id].name = name;
	filerefs[id].rock = rock;
	filerefs[id].handle = NULL;
	for (int i=0; i<128; i++) {
		i7byte c = i7mem[name+1+i];
		filerefs[id].leafname[i] = c;
		if (c == 0) break;
	}
	filerefs[id].leafname[127] = 0;
	sprintf(filerefs[id].leafname + strlen(filerefs[id].leafname), ".glkdata");
	return id;
}

int i7_fseek(int id, int pos, int origin) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
// printf("Seek to %d wrt %d\n", pos, origin);
	return fseek(filerefs[id].handle, pos, origin);
}

int i7_ftell(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	int t = ftell(filerefs[id].handle);
// printf("Tell gives %d\n", t);
	return t;
}

int i7_fopen(int id, int mode) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle) { fprintf(stderr, "File already open\n"); i7_fatal_exit(); }
	char *c_mode = "r";
	switch (mode) {
		case filemode_Write: c_mode = "w"; break;
		case filemode_Read: c_mode = "r"; break;
		case filemode_ReadWrite: c_mode = "r+"; break;
		case filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen(filerefs[id].leafname, c_mode);
	if (h == NULL) return 0;
	filerefs[id].handle = h;
// printf("Open mode %s\n", c_mode);
	if (mode == filemode_WriteAppend) i7_fseek(id, 0, SEEK_END);
	return 1;
}

void i7_fclose(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	fclose(filerefs[id].handle);
	filerefs[id].handle = NULL;
// printf("Close\n");
}

i7val i7_do_glk_fileref_does_file_exist(i7val id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle) return 1;
	if (i7_fopen(id, filemode_Read)) {
		i7_fclose(id); return 1;
	}
	return 0;
}

void i7_fputc(int c, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	fputc(c, filerefs[id].handle);
// printf("Put %c\n", c);
}

int i7_fgetc(int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(); }
	int c = fgetc(filerefs[id].handle);
// printf("Get %c\n", c);
	return c;
}

typedef struct i7_stream {
	FILE *to_file;
	i7val to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7val previous_id;
	i7val write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
} i7_stream;

#define I7_MAX_STREAMS 128

i7_stream i7_memory_streams[I7_MAX_STREAMS];

i7val i7_stdout_id = 0, i7_stderr_id = 1, i7_str_id = 0;

i7val i7_do_glk_stream_get_current(void) {
	return i7_str_id;
}

void i7_do_glk_stream_set_current(i7val id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_str_id = id;
}

i7_stream i7_new_stream(FILE *F) {
	i7_stream S;
	S.to_file = F;
	S.to_file_id = -1;
	S.to_memory = NULL;
	S.memory_used = 0;
	S.memory_capacity = 0;
	S.write_here_on_closure = 0;
	S.write_limit = 0;
	S.previous_id = 0;
	S.active = 0;
	S.encode_UTF8 = 0;
	S.char_size = 4;
	S.chars_read = 0;
	S.read_position = 0;
	S.end_position = 0;
	return S;
}

void i7_initialise_streams(void) {
	for (int i=0; i<I7_MAX_STREAMS; i++) i7_memory_streams[i] = i7_new_stream(NULL);
	i7_memory_streams[i7_stdout_id] = i7_new_stream(stdout);
	i7_memory_streams[i7_stdout_id].active = 1;
	i7_memory_streams[i7_stdout_id].encode_UTF8 = 1;
	i7_memory_streams[i7_stderr_id] = i7_new_stream(stderr);
	i7_memory_streams[i7_stderr_id].active = 1;
	i7_memory_streams[i7_stderr_id].encode_UTF8 = 1;
	i7_do_glk_stream_set_current(i7_stdout_id);
}

i7val i7_open_stream(FILE *F) {
	for (int i=0; i<I7_MAX_STREAMS; i++)
		if (i7_memory_streams[i].active == 0) {
			i7_memory_streams[i] = i7_new_stream(F);
			i7_memory_streams[i].active = 1;
			i7_memory_streams[i].previous_id = i7_str_id;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit();
	return 0;
}

i7val i7_do_glk_stream_open_memory(i7val buffer, i7val len, i7val fmode, i7val rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(); }
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 1;
			i7_str_id = id;
	return id;
}

i7val i7_do_glk_stream_open_memory_uni(i7val buffer, i7val len, i7val fmode, i7val rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(); }
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 4;
			i7_str_id = id;
	return id;
}

i7val i7_do_glk_stream_open_file(i7val fileref, i7val usage, i7val rock) {
	i7val id = i7_open_stream(NULL);
	i7_memory_streams[id].to_file_id = fileref;
	if (i7_fopen(fileref, usage) == 0) return 0;
	return id;
}

#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)

void i7_do_glk_stream_set_position(i7val id, i7val pos, i7val seekmode) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case seekmode_Start: origin = SEEK_SET; break;
			case seekmode_Current: origin = SEEK_CUR; break;
			case seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit();
		}
		i7_fseek(S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n"); i7_fatal_exit();
	}
}

i7val i7_do_glk_stream_get_position(i7val id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7val) i7_ftell(S->to_file_id);
	}
	return (i7val) S->memory_used;
}

void i7_do_glk_stream_close(i7val id, i7val result) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(); }
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->active == 0) { fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(); }
	if (i7_str_id == id) i7_str_id = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(i7mem, S->write_here_on_closure, i, S->to_memory[i], i7_lvalue_SET);
				else
					i7_write_word(i7mem, S->write_here_on_closure, i, 0, i7_lvalue_SET);
		} else {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7mem[S->write_here_on_closure + i] = S->to_memory[i];
				else
					i7mem[S->write_here_on_closure + i] = 0;
		}
	}
	if (result == -1) {
		i7_push(S->chars_read);
		i7_push(S->memory_used);
	} else if (result != 0) {
		i7_write_word(i7mem, result, 0, S->chars_read, i7_lvalue_SET);
		i7_write_word(i7mem, result, 1, S->memory_used, i7_lvalue_SET);
	}
	if (S->to_file_id >= 0) i7_fclose(S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

void i7_do_glk_put_char_stream(i7val stream_id, i7val x) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file) {
		unsigned int c = (unsigned int) x;
		if (S->encode_UTF8) {
			if (c >= 0x800) {
				fputc(0xE0 + (c >> 12), S->to_file);
				fputc(0x80 + ((c >> 6) & 0x3f), S->to_file);
				fputc(0x80 + (c & 0x3f), S->to_file);
			} else if (c >= 0x80) {
				fputc(0xC0 + (c >> 6), S->to_file);
				fputc(0x80 + (c & 0x3f), S->to_file);
			} else fputc((int) c, S->to_file);
		} else {
			fputc((int) c, S->to_file);
		}
	} else if (S->to_file_id >= 0) {
		i7_fputc((int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) { fprintf(stderr, "Out of memory\n"); i7_fatal_exit(); }
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

i7val i7_do_glk_get_char_stream(i7val stream_id) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_fgetc(S->to_file_id);
	}
	return 0;
}

void i7_print_char(i7val x) {
	i7_do_glk_put_char_stream(i7_str_id, x);
}

void i7_print_C_string(char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char((i7val) c_string[i]);
}

void i7_print_decimal(i7val x) {
	char room[32];
	sprintf(room, "%d", (int) x);
	i7_print_C_string(room);
}

#define evtype_None (0)
#define evtype_Timer (1)
#define evtype_CharInput (2)
#define evtype_LineInput (3)
#define evtype_MouseInput (4)
#define evtype_Arrange (5)
#define evtype_Redraw (6)
#define evtype_SoundNotify (7)
#define evtype_Hyperlink (8)
#define evtype_VolumeNotify (9)

typedef struct i7_glk_event {
	i7val type;
	i7val win_id;
	i7val val1;
	i7val val2;
} i7_glk_event;

i7_glk_event i7_events_ring_buffer[32];
int i7_rb_back = 0, i7_rb_front = 0;

i7_glk_event *i7_next_event(void) {
	if (i7_rb_front == i7_rb_back) return NULL;
	i7_glk_event *e = &(i7_events_ring_buffer[i7_rb_back]);
	i7_rb_back++; if (i7_rb_back == 32) i7_rb_back = 0;
	return e;
}

void i7_make_event(i7_glk_event e) {
	i7_events_ring_buffer[i7_rb_front] = e;
	i7_rb_front++; if (i7_rb_front == 32) i7_rb_front = 0;
}

i7val i7_do_glk_select(i7val structure) {
	i7_glk_event *e = i7_next_event();
	if (e == NULL) {
		fprintf(stderr, "No events available to select\n"); i7_fatal_exit();
	}
	if (structure == -1) {
		i7_push(e->type);
		i7_push(e->win_id);
		i7_push(e->val1);
		i7_push(e->val2);
	} else {
		if (structure) {
			i7_write_word(i7mem, structure, 0, e->type, i7_lvalue_SET);
			i7_write_word(i7mem, structure, 1, e->win_id, i7_lvalue_SET);
			i7_write_word(i7mem, structure, 2, e->val1, i7_lvalue_SET);
			i7_write_word(i7mem, structure, 3, e->val2, i7_lvalue_SET);
		}
	}
	return 0;
}

int i7_no_lr = 0;
i7val i7_do_glk_request_line_event(i7val window_id, i7val buffer, i7val max_len, i7val init_len) {
	i7_glk_event e;
	e.type = evtype_LineInput;
	e.win_id = window_id;
	e.val1 = 1;
	e.val2 = 0;
	wchar_t c; int pos = init_len;
	while (1) {
		c = getchar();
		if ((c == EOF) || (c == '\n') || (c == '\r')) break;
		if (pos < max_len) i7mem[buffer + pos++] = c;
	}
	if (pos < max_len) i7mem[buffer + pos++] = 0; else i7mem[buffer + max_len-1] = 0;
	e.val1 = pos;
	i7_print_C_string((char *) (i7mem + buffer));
	i7_print_char('\n');
	i7_make_event(e);
	if (i7_no_lr++ == 10) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n"); exit(0);
	}
	return 0;
}

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

void glulx_glk(i7val glk_api_selector, i7val varargc, i7val *z) {
	i7_debug_stack("glulx_glk");
	i7val args[4] = { 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7val v = i7_pull();
		if (argc < 4) args[argc++] = v;
		varargc--;
	}
	
	int rv = 0;
	switch (glk_api_selector) {
		case i7_glk_gestalt:
			rv = 1; break;
		case i7_glk_window_iterate:
			rv = 0; break;
		case i7_glk_window_open:
			rv = 1; break;
		case i7_glk_set_window:
			rv = 0; break;
		case i7_glk_stream_iterate:
			rv = 0; break;
		case i7_glk_fileref_iterate:
			rv = 0; break;
		case i7_glk_stylehint_set:
			rv = 0; break;
		case i7_glk_schannel_iterate:
			rv = 0; break;
		case i7_glk_schannel_create:
			rv = 0; break;
		case i7_glk_set_style:
			rv = 0; break;
		case i7_glk_window_move_cursor:
			rv = 0; break;
		case i7_glk_stream_get_position:
			rv = i7_do_glk_stream_get_position(args[0]); break;
		case i7_glk_window_get_size:
			if (args[0]) i7_write_word(i7mem, args[0], 0, 80, i7_lvalue_SET);
			if (args[1]) i7_write_word(i7mem, args[1], 0, 8, i7_lvalue_SET);
			rv = 0; break;
		case i7_glk_request_line_event:
			rv = i7_do_glk_request_line_event(args[0], args[1], args[2], args[3]); break;
		case i7_glk_select:
			rv = i7_do_glk_select(args[0]); break;
		case i7_glk_stream_close:
			i7_do_glk_stream_close(args[0], args[1]); break;
		case i7_glk_stream_set_current:
			i7_do_glk_stream_set_current(args[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_do_glk_stream_get_current(); break;
		case i7_glk_stream_open_memory:
			rv = i7_do_glk_stream_open_memory(args[0], args[1], args[2], args[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_do_glk_stream_open_memory_uni(args[0], args[1], args[2], args[3]); break;
		case i7_glk_fileref_create_by_name:
			rv = i7_do_glk_fileref_create_by_name(args[0], args[1], args[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_do_glk_fileref_does_file_exist(args[0]); break;
		case i7_glk_stream_open_file:
			rv = i7_do_glk_stream_open_file(args[0], args[1], args[2]); break;
		case i7_glk_fileref_destroy:
			rv = 0; break;
		case i7_glk_char_to_lower:
			rv = args[0];
			if (((rv >= 0x41) && (rv <= 0x5A)) ||
				((rv >= 0xC0) && (rv <= 0xD6)) ||
				((rv >= 0xD8) && (rv <= 0xDE))) rv += 32;
			break;
		case i7_glk_char_to_upper:
			rv = args[0];
			if (((rv >= 0x61) && (rv <= 0x7A)) ||
				((rv >= 0xE0) && (rv <= 0xF6)) ||
				((rv >= 0xF8) && (rv <= 0xFE))) rv -= 32;
			break;
		case i7_glk_stream_set_position:
			i7_do_glk_stream_set_position(args[0], args[1], args[2]); break;
		case i7_glk_put_char_stream:
			i7_do_glk_put_char_stream(args[0], args[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_do_glk_get_char_stream(args[0]); break;
		default:
			printf("Unimplemented: glulx_glk %d.\n", glk_api_selector); i7_fatal_exit();
			break;
	}
	if (z) *z = rv;
}

i7val fn_i7_mgl_IndefArt(int __argc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_DefArt(int __argc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_CIndefArt(int __argc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_CDefArt(int __argc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);
i7val fn_i7_mgl_PrintShortName(int __argc, i7val i7_mgl_local_obj, i7val i7_mgl_local_i);

void i7_print_name(i7val x) {
	fn_i7_mgl_PrintShortName(1, x, 0);
}

void i7_print_object(i7val x) {
	printf("Unimplemented: i7_print_object.\n");
	i7_fatal_exit();
}

void i7_print_box(i7val x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit();
}

void i7_read(i7val x) {
	printf("Unimplemented: i7_read.\n");
	i7_fatal_exit();
}

i7val fn_i7_mgl_pending_boxed_quotation(int __argc) {
	return 0;
}
=
