[CMiniglk::] C Miniglk.

Just enough of the Glk input/output interface to allow simple console text in
and out, and no more.

@h Glk - an apology.
The code below is in no way a proper implementation of the Glk input/output
system, which was developed as an interactive fiction standard by Andrew Plotkin,
and which has served us well and will continue to do so. It is not even a full
implementation of basic console I/O via Glk, for which see the |cheapglk|
C library.

Instead, our aim is to do the absolute minimum possible in simple self-contained
C code, and to impose as few restrictions as possible beyond that. The flip side
of Glk's gilt-edged engineering quality is that it can be a gilded cage: for some
imaginable uses of Inform 7-via-C, say based on Unity or in an iOS app, strict
use of Glk would be constraining.

In an attempt to have the best of both worlds, the code below is only the
default Glk implementation for an Inform 7-via-C project, and the user can
duck out of it by providing an implementation of her own. (Indeed, this could
even be |cheapglk|, as mentioned above.)

This section of code therefore defines just two functions, |i7_default_stylist|
and |i7_default_glk|, plus their supporting code -- which turns out to be quite
a lot, but there are only those two points of entry.

@h The Glk handler.
The |@glk selector varargc s1| opcode performs some I/O function indexed by the
|selector| value, taking some number of arguments which have been placed on the
stack: |varargc| is the number of these, which may be anything from 0 to 5.
Some functions return a value which is stored in |s1|, others do not; as with
all assembly store operands, though, supplying 0 as the store location causes
no store to take place.

The code below can only be understood with the Glk reference documentation to
hand, and we won't try to duplicate that here.

= (text to inform7_clib.c)
void i7_default_glk(i7process_t *proc, i7word_t selector, i7word_t varargc, i7word_t *z) {
	i7_debug_stack("i7_opcode_glk");
	i7word_t a[5] = { 0, 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7word_t v = i7_pull(proc);
		if (argc < 5) a[argc++] = v;
		varargc--;
	}
	
	int rv = 0;
	switch (selector) {
		case i7_glk_gestalt:
			rv = i7_miniglk_gestalt(proc, a[0]); break;

		/* Characters */
		case i7_glk_char_to_lower:
			rv = i7_miniglk_char_to_lower(proc, a[0]); break;
		case i7_glk_char_to_upper:
			rv = i7_miniglk_char_to_upper(proc, a[0]); break;
		case i7_glk_buffer_to_lower_case_uni:
			for (int pos=0; pos<a[2]; pos++) {
				i7word_t c = i7_read_word(proc, a[0], pos);
				i7_write_word(proc, a[0], pos, i7_miniglk_char_to_lower(proc, c));
			}
			rv = a[2]; break;
		case i7_glk_buffer_canon_normalize_uni:
			rv = a[2]; break; /* Ignore this one */

		/* File handling */
		case i7_glk_fileref_create_by_name:
			rv = i7_miniglk_fileref_create_by_name(proc, a[0], a[1], a[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_miniglk_fileref_does_file_exist(proc, a[0]); break;
		/* And we ignore: */
		case i7_glk_fileref_destroy: rv = 0; break;
		case i7_glk_fileref_iterate: rv = 0; break;

		/* Stream handling */
		case i7_glk_stream_get_position:
			rv = i7_miniglk_stream_get_position(proc, a[0]); break;
		case i7_glk_stream_close:
			i7_miniglk_stream_close(proc, a[0], a[1]); break;
		case i7_glk_stream_set_current:
			i7_miniglk_stream_set_current(proc, a[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_miniglk_stream_get_current(proc); break;
		case i7_glk_stream_open_memory:
			rv = i7_miniglk_stream_open_memory(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_miniglk_stream_open_memory_uni(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_stream_open_file:
			rv = i7_miniglk_stream_open_file(proc, a[0], a[1], a[2]); break;
		case i7_glk_stream_set_position:
			i7_miniglk_stream_set_position(proc, a[0], a[1], a[2]); break;
		case i7_glk_put_char_stream:
			i7_miniglk_put_char_stream(proc, a[0], a[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_miniglk_get_char_stream(proc, a[0]); break;
		case i7_glk_put_buffer_uni:
			{
				i7word_t str = i7_miniglk_stream_get_current(proc);
				for (int pos=0; pos<a[1]; pos++) {
					i7word_t c = i7_read_word(proc, a[0], pos);
					i7_miniglk_put_char_stream(proc, str, c);
				}
			}
			rv = 0; break;
		/* And we ignore: */
		case i7_glk_stream_iterate: rv = 0; break;

		/* Window handling */
		case i7_glk_window_open:
			rv = i7_miniglk_window_open(proc, a[0], a[1], a[2], a[3], a[4]); break;
		case i7_glk_set_window:
			rv = i7_miniglk_set_window(proc, a[0]); break;
		case i7_glk_window_get_size:
			rv = i7_miniglk_window_get_size(proc, a[0], a[1], a[2]); break;
		/* And we ignore: */
		case i7_glk_window_iterate: rv = 0; break;
		case i7_glk_window_move_cursor: rv = 0; break;

		/* Event handling */
		case i7_glk_request_line_event:
			rv = i7_miniglk_request_line_event(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_request_line_event_uni:
			rv = i7_miniglk_request_line_event_uni(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_select:
			rv = i7_miniglk_select(proc, a[0]); break;

		/* Other selectors we recognise, but then ignore: */
		case i7_glk_set_style: rv = 0; break;
		case i7_glk_stylehint_set: rv = 0; break;
		case i7_glk_schannel_create: rv = 0; break;
		case i7_glk_schannel_iterate: rv = 0; break;

		default:
			printf("Unimplemented Glk selector: %d.\n", selector);
			i7_fatal_exit(proc);
			break;
	}
	if (z) *z = rv;
}

@h Gestalt.
The following is overdone, really: the standard Inform kits ask only about
|i7_gestalt_Unicode|, |i7_gestalt_Sound| and |i7_gestalt_Graphics|.

= (text to inform7_clib.h)
i7word_t i7_miniglk_gestalt(i7process_t *proc, i7word_t g);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_gestalt(i7process_t *proc, i7word_t g) {
	switch (g) {
		case i7_gestalt_Version:
		case i7_gestalt_CharInput:
		case i7_gestalt_LineInput:
		case i7_gestalt_Unicode:
		case i7_gestalt_UnicodeNorm:
			return 1;
		case i7_gestalt_CharOutput:
			return i7_gestalt_CharOutput_CannotPrint;
		case i7_gestalt_MouseInput:
		case i7_gestalt_Timer:
		case i7_gestalt_Graphics:
		case i7_gestalt_DrawImage:
		case i7_gestalt_Sound:
		case i7_gestalt_SoundVolume:
		case i7_gestalt_SoundNotify:
		case i7_gestalt_Hyperlinks:
		case i7_gestalt_HyperlinkInput:
		case i7_gestalt_SoundMusic:
		case i7_gestalt_GraphicsTransparency:
		case i7_gestalt_LineInputEcho:
		case i7_gestalt_LineTerminators:
		case i7_gestalt_LineTerminatorKey:
		case i7_gestalt_DateTime:
		case i7_gestalt_Sound2:
		case i7_gestalt_ResourceStream:
		case i7_gestalt_GraphicsCharInput:
			return 0;
	}
	return 0;
}

@h Characters.
These need only be performed on the ISO Latin-1 range, so are easy.

= (text to inform7_clib.h)
i7word_t i7_miniglk_char_to_lower(i7process_t *proc, i7word_t c);
i7word_t i7_miniglk_char_to_upper(i7process_t *proc, i7word_t c);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_char_to_lower(i7process_t *proc, i7word_t c) {
	if (((c >= 0x41) && (c <= 0x5A)) ||
		((c >= 0xC0) && (c <= 0xD6)) ||
		((c >= 0xD8) && (c <= 0xDE))) c += 32;
	return c;
}

i7word_t i7_miniglk_char_to_upper(i7process_t *proc, i7word_t c) {
	if (((c >= 0x61) && (c <= 0x7A)) ||
		((c >= 0xE0) && (c <= 0xF6)) ||
		((c >= 0xF8) && (c <= 0xFE))) c -= 32;
	return c;
}
=

@h Miniglk data.
Each process needs to keep track of its own files, streams, windows and events,
which are wrapped up in a |miniglk_data| structure as follows:

= (text to inform7_clib.h)
#define I7_MINIGLK_LEAFNAME_LENGTH 128

typedef struct i7_mg_file_t {
	i7word_t usage;
	i7word_t name;
	i7word_t rock;
	char leafname[I7_MINIGLK_LEAFNAME_LENGTH + 32];
	FILE *handle;
} i7_mg_file_t;

typedef struct i7_mg_stream_t {
	FILE *to_file;
	i7word_t to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7word_t previous_id;
	i7word_t write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
	int owned_by_window_id;
	int fixed_pitch;
	char style[128];
	char composite_style[300];
} i7_mg_stream_t;

typedef struct i7_mg_window_t {
	i7word_t type;
	i7word_t stream_id;
	i7word_t rock;
} i7_mg_window_t;

typedef struct i7_mg_event_t {
	i7word_t type;
	i7word_t win_id;
	i7word_t val1;
	i7word_t val2;
} i7_mg_event_t;

#define I7_MINIGLK_MAX_FILES 128
#define I7_MINIGLK_MAX_STREAMS 128
#define I7_MINIGLK_MAX_WINDOWS 128
#define I7_MINIGLK_RING_BUFFER_SIZE 32

typedef struct miniglk_data {
	/* streams */
	i7_mg_stream_t memory_streams[I7_MINIGLK_MAX_STREAMS];
	i7word_t stdout_stream_id, stderr_stream_id;
	/* files */
	i7_mg_file_t files[I7_MINIGLK_MAX_FILES + 32];
	int no_files;
	/* windows */
	i7_mg_window_t windows[I7_MINIGLK_MAX_WINDOWS];
	int no_windows;
	/* events */
	i7_mg_event_t events_ring_buffer[I7_MINIGLK_RING_BUFFER_SIZE];
	int rb_back, rb_front;
	int no_line_events;
} miniglk_data;

void i7_initialise_miniglk_data(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_initialise_miniglk_data(i7process_t *proc) {
	proc->miniglk = malloc(sizeof(miniglk_data));
	if (proc->miniglk == NULL) {
		printf("Memory allocation failed\n");
		exit(1);
	}
	proc->miniglk->no_files = 0;
	proc->miniglk->stdout_stream_id = 0;
	proc->miniglk->stderr_stream_id = 1;
	proc->miniglk->no_windows = 1;
	proc->miniglk->rb_back = 0;
	proc->miniglk->rb_front = 0;
	proc->miniglk->no_line_events = 0;
}

@ Each process starts with two streams already open for text output: |stdout|
and |stderr|, and the former is selected as current.

= (text to inform7_clib.h)
void i7_initialise_miniglk(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_initialise_miniglk(i7process_t *proc) {
	for (int i=0; i<I7_MINIGLK_MAX_STREAMS; i++)
		proc->miniglk->memory_streams[i] = i7_mg_new_stream(proc, NULL, 0);
	i7_mg_stream_t stdout_stream = i7_mg_new_stream(proc, stdout, 0);
	stdout_stream.active = 1;
	stdout_stream.encode_UTF8 = 1;
	proc->miniglk->memory_streams[proc->miniglk->stdout_stream_id] = stdout_stream;
	i7_mg_stream_t stderr_stream = i7_mg_new_stream(proc, stderr, 0);
	stderr_stream.active = 1;
	stderr_stream.encode_UTF8 = 1;
	proc->miniglk->memory_streams[proc->miniglk->stderr_stream_id] = stderr_stream;
	i7_miniglk_stream_set_current(proc, proc->miniglk->stdout_stream_id);
}
=

@h File-handling.

= (text to inform7_clib.h)
int i7_mg_new_file(i7process_t *proc);
int i7_mg_fseek(i7process_t *proc, int id, int pos, int origin);
int i7_mg_ftell(i7process_t *proc, int id);
int i7_mg_fopen(i7process_t *proc, int id, int mode);
void i7_mg_fclose(i7process_t *proc, int id);
void i7_mg_fputc(i7process_t *proc, int c, int id);
int i7_mg_fgetc(i7process_t *proc, int id);
=

= (text to inform7_clib.c)
int i7_mg_new_file(i7process_t *proc) {
	if (proc->miniglk->no_files >= I7_MINIGLK_MAX_FILES) {
		fprintf(stderr, "Out of files\n"); i7_fatal_exit(proc);
	}
	int id = proc->miniglk->no_files++;
	proc->miniglk->files[id].usage = 0;
	proc->miniglk->files[id].name = 0;
	proc->miniglk->files[id].rock = 0;
	proc->miniglk->files[id].handle = NULL;
	proc->miniglk->files[id].leafname[0] = 0;
	return id;
}

int i7_mg_fseek(i7process_t *proc, int id, int pos, int origin) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	return fseek(proc->miniglk->files[id].handle, pos, origin);
}

int i7_mg_ftell(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	int t = ftell(proc->miniglk->files[id].handle);
	return t;
}

int i7_mg_fopen(i7process_t *proc, int id, int mode) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle) {
		fprintf(stderr, "File already open\n"); i7_fatal_exit(proc);
	}
	char *c_mode = "r";
	switch (mode) {
		case i7_filemode_Write: c_mode = "w"; break;
		case i7_filemode_Read: c_mode = "r"; break;
		case i7_filemode_ReadWrite: c_mode = "r+"; break;
		case i7_filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen(proc->miniglk->files[id].leafname, c_mode);
	if (h == NULL) return 0;
	proc->miniglk->files[id].handle = h;
	if (mode == i7_filemode_WriteAppend) i7_mg_fseek(proc, id, 0, SEEK_END);
	return 1;
}

void i7_mg_fclose(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	fclose(proc->miniglk->files[id].handle);
	proc->miniglk->files[id].handle = NULL;
}


void i7_mg_fputc(i7process_t *proc, int c, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	fputc(c, proc->miniglk->files[id].handle);
}

int i7_mg_fgetc(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	int c = fgetc(proc->miniglk->files[id].handle);
	return c;
}
=

@ This allows us to implement |glk_fileref_create_by_name| and |glk_fileref_does_file_exist|.

= (text to inform7_clib.h)
i7word_t i7_miniglk_fileref_create_by_name(i7process_t *proc, i7word_t usage,
	i7word_t name, i7word_t rock);
i7word_t i7_miniglk_fileref_does_file_exist(i7process_t *proc, i7word_t id);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_fileref_create_by_name(i7process_t *proc, i7word_t usage,
	i7word_t name, i7word_t rock) {
	int id = i7_mg_new_file(proc);
	proc->miniglk->files[id].usage = usage;
	proc->miniglk->files[id].name = name;
	proc->miniglk->files[id].rock = rock;
	char *L = proc->miniglk->files[id].leafname;
	for (int i=0; i<I7_MINIGLK_LEAFNAME_LENGTH; i++) {
		L[i] = i7_read_byte(proc, name+1+i);
		if (L[i] == 0) break;
	}
	L[127] = 0;
	sprintf(L + strlen(L), ".glkdata");
	return id;
}

i7word_t i7_miniglk_fileref_does_file_exist(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle) return 1;
	if (i7_mg_fopen(proc, id, i7_filemode_Read)) {
		i7_mg_fclose(proc, id); return 1;
	}
	return 0;
}
=

@h Streams.
These are channels for input/output, carrying bytes (which are usually characters).

= (text to inform7_clib.h)
i7_mg_stream_t i7_mg_new_stream(i7process_t *proc, FILE *F, int win_id);
i7word_t i7_mg_open_stream(i7process_t *proc, FILE *F, int win_id);
=

= (text to inform7_clib.c)
i7_mg_stream_t i7_mg_new_stream(i7process_t *proc, FILE *F, int win_id) {
	i7_mg_stream_t S;
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
	S.owned_by_window_id = win_id;
	S.style[0] = 0;
	S.fixed_pitch = 0;
	S.composite_style[0] = 0;
	return S;
}

i7word_t i7_mg_open_stream(i7process_t *proc, FILE *F, int win_id) {
	for (int i=0; i<I7_MINIGLK_MAX_STREAMS; i++)
		if (proc->miniglk->memory_streams[i].active == 0) {
			proc->miniglk->memory_streams[i] = i7_mg_new_stream(proc, F, win_id);
			proc->miniglk->memory_streams[i].active = 1;
			proc->miniglk->memory_streams[i].previous_id =
				proc->state.current_output_stream_ID;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	return 0;
}
=

@ This allows us to implement |glk_stream_open_memory| and its Unicode-text
analogue |glk_stream_open_memory_uni|, and |glk_stream_open_file|.

= (text to inform7_clib.h)
i7word_t i7_miniglk_stream_open_memory(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_miniglk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_miniglk_stream_open_file(i7process_t *proc, i7word_t fileref,
	i7word_t usage, i7word_t rock);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_stream_open_memory(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != i7_filemode_Write) {
		fprintf(stderr, "Only file mode Write supported, not %d\n", fmode);
		i7_fatal_exit(proc);
	}
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].write_here_on_closure = buffer;
	proc->miniglk->memory_streams[id].write_limit = (size_t) len;
	proc->miniglk->memory_streams[id].char_size = 1;
	proc->state.current_output_stream_ID = id;
	return id;
}

i7word_t i7_miniglk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != i7_filemode_Write) {
		fprintf(stderr, "Only file mode Write supported, not %d\n", fmode);
		i7_fatal_exit(proc);
	}
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].write_here_on_closure = buffer;
	proc->miniglk->memory_streams[id].write_limit = (size_t) len;
	proc->miniglk->memory_streams[id].char_size = 4;
	proc->state.current_output_stream_ID = id;
	return id;
}

i7word_t i7_miniglk_stream_open_file(i7process_t *proc, i7word_t fileref,
	i7word_t usage, i7word_t rock) {
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].to_file_id = fileref;
	if (i7_mg_fopen(proc, fileref, usage) == 0) return 0;
	return id;
}

@ |glk_stream_set_position| and |glk_stream_get_position| are essentially for
moving to the start or end of a file, at least for our purposes.

= (text to inform7_clib.h)
void i7_miniglk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos,
	i7word_t seekmode);
i7word_t i7_miniglk_stream_get_position(i7process_t *proc, i7word_t id);
=

= (text to inform7_clib.c)
void i7_miniglk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos,
	i7word_t seekmode) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case i7_seekmode_Start: origin = SEEK_SET; break;
			case i7_seekmode_Current: origin = SEEK_CUR; break;
			case i7_seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit(proc);
		}
		i7_mg_fseek(proc, S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n");
		i7_fatal_exit(proc);
	}
}

i7word_t i7_miniglk_stream_get_position(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7word_t) i7_mg_ftell(proc, S->to_file_id);
	}
	return (i7word_t) S->memory_used;
}
=

@ Each process has a current stream, and |glk_stream_get_current| and
|glk_stream_set_current| give access to this.

= (text to inform7_clib.h)
i7word_t i7_miniglk_stream_get_current(i7process_t *proc);
void i7_miniglk_stream_set_current(i7process_t *proc, i7word_t id);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_stream_get_current(i7process_t *proc) {
	return proc->state.current_output_stream_ID;
}

void i7_miniglk_stream_set_current(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	proc->state.current_output_stream_ID = id;
}
=

@ The thing which is "current" about the current stream is that this is where
characters are written to. The following implements |glk_put_char_stream|.

= (text to inform7_clib.h)
void i7_mg_put_to_stream(i7process_t *proc, i7word_t rock, wchar_t c);
void i7_miniglk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x);
=

= (text to inform7_clib.c)
void i7_mg_put_to_stream(i7process_t *proc, i7word_t rock, wchar_t c) {
	i7_mg_stream_t *S =
		&(proc->miniglk->memory_streams[proc->state.current_output_stream_ID]);
	if (proc->receiver == NULL) fputc(c, stdout);
	(proc->receiver)(rock, c, S->composite_style);
}

void i7_miniglk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x) {
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[stream_id]);
	if (S->to_file) {
		int win_id = S->owned_by_window_id;
		int rock = -1;
		if (win_id >= 1) rock = i7_mg_get_window_rock(proc, win_id);
		unsigned int c = (unsigned int) x;
		if (proc->use_UTF8) {
			if (c >= 0x200000) { /* invalid Unicode */
				i7_mg_put_to_stream(proc, rock, '?');
			} else if (c >= 0x10000) {
				i7_mg_put_to_stream(proc, rock, 0xF0 + (c >> 18));
				i7_mg_put_to_stream(proc, rock, 0x80 + ((c >> 12) & 0x3f));
				i7_mg_put_to_stream(proc, rock, 0x80 + ((c >> 6) & 0x3f));
				i7_mg_put_to_stream(proc, rock, 0x80 + (c & 0x3f));
			} else if (c >= 0x800) {
				i7_mg_put_to_stream(proc, rock, 0xE0 + (c >> 12));
				i7_mg_put_to_stream(proc, rock, 0x80 + ((c >> 6) & 0x3f));
				i7_mg_put_to_stream(proc, rock, 0x80 + (c & 0x3f));
			} else if (c >= 0x80) {
				i7_mg_put_to_stream(proc, rock, 0xC0 + (c >> 6));
				i7_mg_put_to_stream(proc, rock, 0x80 + (c & 0x3f));
			} else i7_mg_put_to_stream(proc, rock, (int) c);
		} else {
			i7_mg_put_to_stream(proc, rock, (int) c);
		}
	} else if (S->to_file_id >= 0) {
		i7_mg_fputc(proc, (int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) {
				fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
			}
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

@ Note that the current stream is irrelevant to reading characters, where we
have to specify exactly which stream is intended. Here's |glk_get_char_stream|:

= (text to inform7_clib.h)
i7word_t i7_miniglk_get_char_stream(i7process_t *proc, i7word_t stream_id);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_get_char_stream(i7process_t *proc, i7word_t stream_id) {
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_mg_fgetc(proc, S->to_file_id);
	}
	return 0;
}

@ And finally |glk_stream_close|, which is far from being an empty courtesy:
we may have to close a file on disc, or we may have to copy a memory buffer into
process memory.

= (text to inform7_clib.h)
void i7_miniglk_stream_close(i7process_t *proc, i7word_t id, i7word_t result);
=

= (text to inform7_clib.c)
void i7_miniglk_stream_close(i7process_t *proc, i7word_t id, i7word_t result) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(proc); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(proc); }
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->active == 0) {
		fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(proc);
	}
	if (proc->state.current_output_stream_ID == id)
		proc->state.current_output_stream_ID = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(proc, S->write_here_on_closure, i, S->to_memory[i]);
				else
					i7_write_word(proc, S->write_here_on_closure, i, 0);
		} else {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_byte(proc, S->write_here_on_closure + i, S->to_memory[i]);
				else
					i7_write_byte(proc, S->write_here_on_closure + i, 0);
		}
	}
	if (result == -1) {
		i7_push(proc, S->chars_read);
		i7_push(proc, S->memory_used);
	} else if (result != 0) {
		i7_write_word(proc, result, 0, S->chars_read);
		i7_write_word(proc, result, 1, S->memory_used);
	}
	if (S->to_file_id >= 0) i7_mg_fclose(proc, S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

@h Windows.
Even a proper Glk implementation isn't presenting any kind of window manager in
the style of Xerox or early Macs: these windows are (borderless, invisible)
rectangles on a plain text grid.

And in this miniglk, a window is really just a receptacle for a stream of text.
We make no attempt to model how multiple windows might sit, because we're
assuming that either (i) we are being used for a command-line console app which
doesn't treat the Terminal window as two-dimensional, or (ii) we are being linked
into some bigger GUI app which is going to handle everything visual in its own
way anyway.

Note that we shamelessly claim that all windows are 80 x 8 characters.

= (text to inform7_clib.h)
i7word_t i7_miniglk_window_open(i7process_t *proc, i7word_t split, i7word_t method,
	i7word_t size, i7word_t wintype, i7word_t rock);
i7word_t i7_miniglk_set_window(i7process_t *proc, i7word_t id);
i7word_t i7_mg_get_window_rock(i7process_t *proc, i7word_t id);
i7word_t i7_miniglk_window_get_size(i7process_t *proc, i7word_t id, i7word_t a1,
	i7word_t a2);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_window_open(i7process_t *proc, i7word_t split, i7word_t method,
	i7word_t size, i7word_t wintype, i7word_t rock) {
	if (proc->miniglk->no_windows >= 128) {
		fprintf(stderr, "Out of windows\n"); i7_fatal_exit(proc);
	}
	int id = proc->miniglk->no_windows++;
	proc->miniglk->windows[id].type = wintype;
	proc->miniglk->windows[id].stream_id = i7_mg_open_stream(proc, stdout, id);
	proc->miniglk->windows[id].rock = rock;
	return id;
}

i7word_t i7_miniglk_set_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= proc->miniglk->no_windows)) {
		fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_miniglk_stream_set_current(proc, proc->miniglk->windows[id].stream_id);
	return 0;
}

i7word_t i7_mg_get_window_rock(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= proc->miniglk->no_windows)) {
		fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	return proc->miniglk->windows[id].rock;
}

i7word_t i7_miniglk_window_get_size(i7process_t *proc, i7word_t id, i7word_t a1,
	i7word_t a2) {
	if (a1) i7_write_word(proc, a1, 0, 80);
	if (a2) i7_write_word(proc, a2, 0, 8);
	return 0;
}
=

@h Events.
Pending events are stored in a ring buffer, where the valid pending events are
those between the |rb_back| and |rb_front| markers, modulo |I7_MINIGLK_RING_BUFFER_SIZE|.
(In practice, this is more than we need for the very simple use that the standard
I7 kits make of events. Still, it does no harm.)

= (text to inform7_clib.h)
void i7_mg_add_event_to_buffer(i7process_t *proc, i7_mg_event_t e);
i7_mg_event_t *i7_mg_get_event_from_buffer(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_mg_add_event_to_buffer(i7process_t *proc, i7_mg_event_t e) {
	proc->miniglk->events_ring_buffer[proc->miniglk->rb_front] = e;
	proc->miniglk->rb_front++;
	if (proc->miniglk->rb_front == I7_MINIGLK_RING_BUFFER_SIZE)
		proc->miniglk->rb_front = 0;
}

i7_mg_event_t *i7_mg_get_event_from_buffer(i7process_t *proc) {
	if (proc->miniglk->rb_front == proc->miniglk->rb_back) return NULL;
	i7_mg_event_t *e = &(proc->miniglk->events_ring_buffer[proc->miniglk->rb_back]);
	proc->miniglk->rb_back++;
	if (proc->miniglk->rb_back == I7_MINIGLK_RING_BUFFER_SIZE)
		proc->miniglk->rb_back = 0;
	return e;
}
=

@ That enables |glk_select|, an operation by which the caller can choose to
pull an event from the buffer and (optionally) copy its data ihto process
memory.

= (text to inform7_clib.h)
i7word_t i7_miniglk_select(i7process_t *proc, i7word_t structure);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_select(i7process_t *proc, i7word_t structure) {
	i7_mg_event_t *e = i7_mg_get_event_from_buffer(proc);
	if (e == NULL) {
		fprintf(stderr, "No events available to select\n"); i7_fatal_exit(proc);
	}
	if (structure == -1) {
		i7_push(proc, e->type);
		i7_push(proc, e->win_id);
		i7_push(proc, e->val1);
		i7_push(proc, e->val2);
	} else {
		if (structure) {
			i7_write_word(proc, structure, 0, e->type);
			i7_write_word(proc, structure, 1, e->win_id);
			i7_write_word(proc, structure, 2, e->val1);
			i7_write_word(proc, structure, 3, e->val2);
		}
	}
	return 0;
}

@ And also |glk_request_line_event|. This asks the process's sender function to
compose a command (terminated by 0 or a newline), then makes that it into a
line event and pushes it to the event buffer. The caller can then use |glk_select|
to find out what the command was.

= (text to inform7_clib.h)
i7word_t i7_miniglk_request_line_event(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len);
i7word_t i7_miniglk_request_line_event_uni(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len);
=

= (text to inform7_clib.c)
i7word_t i7_miniglk_request_line_event(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len) {
	i7_mg_event_t e;
	e.type = i7_evtype_LineInput;
	e.win_id = window_id;
	e.val1 = 1;
	e.val2 = 0;
	wchar_t c; int pos = init_len;
	if (proc->sender == NULL) i7_benign_exit(proc);
	char *s = (proc->sender)(proc->send_count++);
	int i = 0;
	while (1) {
		c = s[i++];
		if ((c == EOF) || (c == 0) || (c == '\n') || (c == '\r')) break;
		if (pos < max_len) i7_write_byte(proc, buffer + pos++, c);
	}
	if (pos < max_len) i7_write_byte(proc, buffer + pos, 0);
	else i7_write_byte(proc, buffer + max_len-1, 0);
	e.val1 = pos;
	i7_mg_add_event_to_buffer(proc, e);
	if (proc->miniglk->no_line_events++ == 1000) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n");
		exit(0);
	}
	return 0;
}

i7word_t i7_miniglk_request_line_event_uni(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len) {
	i7_mg_event_t e;
	e.type = i7_evtype_LineInput;
	e.win_id = window_id;
	e.val1 = 1;
	e.val2 = 0;
	wchar_t c; int pos = init_len;
	if (proc->sender == NULL) i7_benign_exit(proc);
	char *s = (proc->sender)(proc->send_count++);
	int i = 0;
	while (1) {
		c = s[i++];
		if ((c == EOF) || (c == 0) || (c == '\n') || (c == '\r')) break;
		if (pos < max_len) i7_write_word(proc, buffer, pos++, c);
	}
	if (pos < max_len) i7_write_word(proc, buffer, pos, 0);
	else i7_write_word(proc, buffer, max_len-1, 0);
	e.val1 = pos;
	i7_mg_add_event_to_buffer(proc, e);
	if (proc->miniglk->no_line_events++ == 1000) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n");
		exit(0);
	}
	return 0;
}

@h Styling.
This happens outside of miniglk. Glk does have a concept of text styles, but one
which is difficult to marry to CSS-esque styles in the way we might want here.
So we provide this additional styling functionality outside of the Glk specification.
When |which| is 1, we're essentially emulating Inform 6's |font| statement; when
it is 2, we're emulation |style|, though an enhanced version capable of more than
the three built-in styles |bold|, |italic| and |reverse|.

= (text to inform7_clib.c)
i7word_t i7_fn_TEXT_TY_CharacterLength(i7process_t *proc, i7word_t i7_mgl_local_txt,
	i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dsize,
	i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp, i7word_t i7_mgl_local_r);
i7word_t i7_fn_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect,
	i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes,
	i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags,
	i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
void i7_default_stylist(i7process_t *proc, i7word_t which, i7word_t what) {
	i7_mg_stream_t *S =
		&(proc->miniglk->memory_streams[proc->state.current_output_stream_ID]);
	if (which == 1) {
		S->fixed_pitch = what;
	} else {
		S->style[0] = 0;
		switch (what) {
			case 0: break;
			case 1: sprintf(S->style, "bold"); break;
			case 2: sprintf(S->style, "italic"); break;
			case 3: sprintf(S->style, "reverse"); break;
			default: {
			    #ifdef i7_mgl_BASICINFORMKIT
				int L =
					i7_fn_TEXT_TY_CharacterLength(proc, what, 0, 0, 0, 0, 0, 0);
				if (L > 127) L = 127;
				for (int i=0; i<L; i++) S->style[i] =
					i7_fn_BlkValueRead(proc, what, i, 0, 0, 0, 0, 0, 0, 0);
				S->style[L] = 0;
				#endif
			}
		}
	}
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (S->composite_style[0])
			sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}
=
