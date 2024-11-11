[CSMiniglk::] C# Miniglk.

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

= (text to inform7_cslib.cs)
partial class Defaults {
	public static int i7_default_glk(Process proc, int selector, int varargc) {
		proc.i7_debug_stack("i7_opcode_glk");
		int[] a = { 0, 0, 0, 0, 0 };
        int argc = 0;
		while (varargc > 0) {
			int v = proc.i7_pull();
			if (argc < 5) a[argc++] = v;
			varargc--;
		}

		int rv = 0;
		switch (selector) {
			case GlkOpcodes.i7_glk_gestalt:
				rv = proc.i7_miniglk_gestalt(a[0]); break;

			/* Characters */
			case GlkOpcodes.i7_glk_char_to_lower:
				rv = proc.i7_miniglk_char_to_lower(a[0]); break;
			case GlkOpcodes.i7_glk_char_to_upper:
				rv = proc.i7_miniglk_char_to_upper(a[0]); break;
			case i7_glk_buffer_to_lower_case_uni:
				for (int pos=0; pos<a[2]; pos++) {
					int c = proc.i7_read_word(a[0], pos);
					proc.i7_write_word(a[0], pos, i7_miniglk_char_to_lower(proc, c));
				}
				rv = a[2]; break;
			case i7_glk_buffer_canon_normalize_uni:
    			rv = a[2]; break; /* Ignore this one */


			/* File handling */
			case GlkOpcodes.i7_glk_fileref_create_by_name:
				rv = proc.i7_miniglk_fileref_create_by_name(a[0], a[1], a[2]); break;
			case GlkOpcodes.i7_glk_fileref_does_file_exist:
				rv = proc.i7_miniglk_fileref_does_file_exist(a[0]); break;
			/* And we ignore: */
			case GlkOpcodes.i7_glk_fileref_destroy: rv = 0; break;
			case GlkOpcodes.i7_glk_fileref_iterate: rv = 0; break;

			/* Stream handling */
			case GlkOpcodes.i7_glk_stream_get_position:
				rv = proc.i7_miniglk_stream_get_position(a[0]); break;
			case GlkOpcodes.i7_glk_stream_close:
				proc.i7_miniglk_stream_close(a[0], a[1]); break;
			case GlkOpcodes.i7_glk_stream_set_current:
				proc.i7_miniglk_stream_set_current(a[0]); break;
			case GlkOpcodes.i7_glk_stream_get_current:
				rv = proc.i7_miniglk_stream_get_current(); break;
			case GlkOpcodes.i7_glk_stream_open_memory:
				rv = proc.i7_miniglk_stream_open_memory(a[0], a[1], a[2], a[3]); break;
			case GlkOpcodes.i7_glk_stream_open_memory_uni:
				rv = proc.i7_miniglk_stream_open_memory_uni(a[0], a[1], a[2], a[3]); break;
			case GlkOpcodes.i7_glk_stream_open_file:
				rv = proc.i7_miniglk_stream_open_file(a[0], a[1], a[2]); break;
			case GlkOpcodes.i7_glk_stream_set_position:
				proc.i7_miniglk_stream_set_position(a[0], a[1], a[2]); break;
			case GlkOpcodes.i7_glk_put_char_stream:
				proc.i7_miniglk_put_char_stream(a[0], a[1]); break;
			case GlkOpcodes.i7_glk_get_char_stream:
				rv = proc.i7_miniglk_get_char_stream(a[0]); break;
			case i7_glk_put_buffer_uni:
				{
					int str = proc.i7_miniglk_stream_get_current();
					for (int pos=0; pos<a[1]; pos++) {
						int c = proc.i7_read_word(a[0], pos);
						proc.i7_miniglk_put_char_stream(str, c);
					}
				}
				rv = 0; break;
			/* And we ignore: */
			case GlkOpcodes.i7_glk_stream_iterate: rv = 0; break;

			/* Window handling */
			case GlkOpcodes.i7_glk_window_open:
				rv = proc.i7_miniglk_window_open(a[0], a[1], a[2], a[3], a[4]); break;
			case GlkOpcodes.i7_glk_set_window:
				rv = proc.i7_miniglk_set_window(a[0]); break;
			case GlkOpcodes.i7_glk_window_get_size:
				rv = proc.i7_miniglk_window_get_size(a[0], a[1], a[2]); break;
			/* And we ignore: */
			case GlkOpcodes.i7_glk_window_iterate: rv = 0; break;
			case GlkOpcodes.i7_glk_window_move_cursor: rv = 0; break;

			/* Event handling */
			case GlkOpcodes.i7_glk_request_line_event:
				rv = proc.i7_miniglk_request_line_event(a[0], a[1], a[2], a[3]); break;
			case i7_glk_request_line_event_uni:
				rv = proc.i7_miniglk_request_line_event_uni(a[0], a[1], a[2], a[3]); break;
			case GlkOpcodes.i7_glk_select:
				rv = proc.i7_miniglk_select(a[0]); break;

			/* Other selectors we recognise, but then ignore: */
			case GlkOpcodes.i7_glk_set_style: rv = 0; break;
			case GlkOpcodes.i7_glk_stylehint_set: rv = 0; break;
			case GlkOpcodes.i7_glk_schannel_create: rv = 0; break;
			case GlkOpcodes.i7_glk_schannel_iterate: rv = 0; break;

			default:
				Console.WriteLine("Unimplemented Glk selector: {0:D}.", selector);
				proc.i7_fatal_exit();
				break;
		}
		return rv;
	}
}

@h Gestalt.
The following is overdone, really: the standard Inform kits ask only about
|i7_gestalt_Unicode|, |i7_gestalt_Sound| and |i7_gestalt_Graphics|.

= (text to inform7_cslib.cs)
partial class Process {
	internal int i7_miniglk_gestalt(int g) {
		switch (g) {
			case GlkGestalts.i7_gestalt_Version:
			case GlkGestalts.i7_gestalt_CharInput:
			case GlkGestalts.i7_gestalt_LineInput:
			case GlkGestalts.i7_gestalt_Unicode:
			case GlkGestalts.i7_gestalt_UnicodeNorm:
				return 1;
			case GlkGestalts.i7_gestalt_CharOutput:
				return GlkGestalts.i7_gestalt_CharOutput_CannotPrint;
			case GlkGestalts.i7_gestalt_MouseInput:
			case GlkGestalts.i7_gestalt_Timer:
			case GlkGestalts.i7_gestalt_Graphics:
			case GlkGestalts.i7_gestalt_DrawImage:
			case GlkGestalts.i7_gestalt_Sound:
			case GlkGestalts.i7_gestalt_SoundVolume:
			case GlkGestalts.i7_gestalt_SoundNotify:
			case GlkGestalts.i7_gestalt_Hyperlinks:
			case GlkGestalts.i7_gestalt_HyperlinkInput:
			case GlkGestalts.i7_gestalt_SoundMusic:
			case GlkGestalts.i7_gestalt_GraphicsTransparency:
			case GlkGestalts.i7_gestalt_LineInputEcho:
			case GlkGestalts.i7_gestalt_LineTerminators:
			case GlkGestalts.i7_gestalt_LineTerminatorKey:
			case GlkGestalts.i7_gestalt_DateTime:
			case GlkGestalts.i7_gestalt_Sound2:
			case GlkGestalts.i7_gestalt_ResourceStream:
			case GlkGestalts.i7_gestalt_GraphicsCharInput:
				return 0;
		}
		return 0;
	}

@h Characters.
These need only be performed on the ISO Latin-1 range, so are easy.

= (text to inform7_cslib.cs)
	internal int i7_miniglk_char_to_lower(int c) {
		if (((c >= 0x41) && (c <= 0x5A)) ||
			((c >= 0xC0) && (c <= 0xD6)) ||
			((c >= 0xD8) && (c <= 0xDE))) c += 32;
		return c;
	}

	internal int i7_miniglk_char_to_upper(int c) {
		if (((c >= 0x61) && (c <= 0x7A)) ||
			((c >= 0xE0) && (c <= 0xF6)) ||
			((c >= 0xF8) && (c <= 0xFE))) c -= 32;
		return c;
	}
}
=

@h Miniglk data.
Each ss needs to keep track of its own files, streams, windows and events,
which are wrapped up in a |MiniGlkData| class as follows:

= (text to inform7_cslib.cs)
class MiniGlkData {
	internal const int I7_MINIGLK_MAX_FILES = 128;
	internal const int I7_MINIGLK_MAX_STREAMS = 128;
	internal const int I7_MINIGLK_MAX_WINDOWS = 128;
	internal const int I7_MINIGLK_RING_BUFFER_SIZE = 32;
	/* streams */
	internal MgStream[] memory_streams;
	int stdout_stream_id, stderr_stream_id;
	/* files */
	internal MgFile[] files;
	internal int no_files;
	/* windows */
	internal MgWindow[] windows;
	internal int no_windows;
	/* events */
	internal MgEvent[] events_ring_buffer;
	internal int rb_back, rb_front;
	internal int no_line_events;

	internal MiniGlkData(Process proc) {
		memory_streams = new MgStream[MiniGlkData.I7_MINIGLK_MAX_STREAMS];
		for (int i=0; i<MiniGlkData.I7_MINIGLK_MAX_STREAMS; i++)
			memory_streams[i] = Process.i7_mg_new_stream(null, 0);

		files = new MgFile[I7_MINIGLK_MAX_FILES + 32];
		windows = new MgWindow[I7_MINIGLK_MAX_WINDOWS];
		events_ring_buffer = new MgEvent[I7_MINIGLK_RING_BUFFER_SIZE];

		stderr_stream_id = 1;
		no_windows = 1;



		MgStream stdout_stream = Process.i7_mg_new_stream( Console.OpenStandardOutput(), 0);
		stdout_stream.active = 1;
		stdout_stream.encode_UTF8 = 1;

		memory_streams[stdout_stream_id] = stdout_stream;
		MgStream stderr_stream = Process.i7_mg_new_stream( Console.OpenStandardError(), 0);
		stderr_stream.active = 1;
		stderr_stream.encode_UTF8 = 1;

		memory_streams[stderr_stream_id] = stderr_stream;
		proc.i7_miniglk_stream_set_current(stdout_stream_id);
	}
}

struct MgFile {
	internal int usage;
	internal int name;
	internal int rock;
	internal string leafname;
	internal FileStream handle;
}

struct MgStream {
	internal Stream to_file;
	internal int to_file_id;
	internal byte[] to_memory;
	internal int memory_used;
	internal int memory_capacity;
	internal int previous_id;
	internal int write_here_on_closure;
	internal long write_limit;
	internal int active;
	internal int encode_UTF8;
	internal int char_size;
	internal int chars_read;
	internal int read_position;
	internal int end_position;
	internal int owned_by_window_id;
	internal int fixed_pitch;
	internal string style;
	internal string composite_style;
}

struct MgWindow {
	internal int type;
	internal int stream_id;
	internal int rock;
} 

class MgEvent {
	internal int type;
	internal int win_id;
	internal int val1;
	internal int val2;
}

@ Each ss starts with two streams already open for text output: |stdout|
and |stderr|, and the former is selected as current.

@h File-handling.

= (text to inform7_cslib.cs)
partial class Process {
	int i7_mg_new_file() {
		if (miniglk.no_files >= MiniGlkData.I7_MINIGLK_MAX_FILES) {
			Console.Error.WriteLine("Out of files"); i7_fatal_exit();
		}
		int id = miniglk.no_files++;
		miniglk.files[id].usage = 0;
		miniglk.files[id].name = 0;
		miniglk.files[id].rock = 0;
		miniglk.files[id].handle = null;
		miniglk.files[id].leafname = null;
		return id;
	}

	long i7_mg_fseek(int id, int pos, int origin) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle == null) {
			Console.Error.WriteLine("File not open"); i7_fatal_exit();
		}
		return miniglk.files[id].handle.Seek(pos, (SeekOrigin)origin);
	}

	long i7_mg_ftell(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle == null) {
			Console.Error.WriteLine("File not open"); i7_fatal_exit();
		}
		long t = miniglk.files[id].handle.Position;
		return t;
	}

	int i7_mg_fopen(int id, int mode) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle != null) {
			Console.Error.WriteLine("File already open"); i7_fatal_exit();
		}
		FileAccess access = FileAccess.Read;
		FileMode n_mode = FileMode.Open;
		switch (mode) {
			case Process.i7_filemode_Write: access = FileAccess.Write; n_mode = FileMode.Create; break;
			case Process.i7_filemode_Read: access = FileAccess.Read; n_mode = FileMode.Open; break;
			case Process.i7_filemode_ReadWrite: access = FileAccess.ReadWrite; n_mode = FileMode.OpenOrCreate; break;
			case Process.i7_filemode_WriteAppend: access = FileAccess.Write; n_mode = FileMode.OpenOrCreate; break;
		}
		FileStream h = File.Open(miniglk.files[id].leafname, n_mode, access);
		if (h == null) return 0;
		miniglk.files[id].handle = h;
		if (mode == Process.i7_filemode_WriteAppend) i7_mg_fseek( id, 0, (int)SeekOrigin.End);
		return 1;
	}

	void i7_mg_fclose(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle == null) {
			Console.Error.WriteLine("File not open"); i7_fatal_exit();
		}
		miniglk.files[id].handle.Close();
		miniglk.files[id].handle = null;
	}


	void i7_mg_fputc(int c, int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle == null) {
			Console.Error.WriteLine("File not open"); i7_fatal_exit();
		}
		miniglk.files[id].handle.WriteByte((byte)c);
	}

	int i7_mg_fgetc(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle == null) {
			Console.Error.WriteLine("File not open"); i7_fatal_exit();
		}
		int c = miniglk.files[id].handle.ReadByte();
		return c;
	}
=

@ This allows us to implement |glk_fileref_create_by_name| and |glk_fileref_does_file_exist|.


= (text to inform7_cslib.cs)
	internal int i7_miniglk_fileref_create_by_name(int usage,
		int name, int rock) {
		int id = i7_mg_new_file();
		miniglk.files[id].usage = usage;
		miniglk.files[id].name = name;
		miniglk.files[id].rock = rock;

		var L = new System.Text.StringBuilder();

		for (int i=0; i < 127; i++) {
			//FIXME: not unicode safe
			 char b = (char) i7_read_byte(name+1+i);
			if (b == 0) break;
			L.Append(b);
		}
		
		L.Append(".glkdata");
		miniglk.files[id].leafname = L.ToString();
		return id;
	}

	internal int i7_miniglk_fileref_does_file_exist(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_FILES)) {
			Console.Error.WriteLine("Bad file ID"); i7_fatal_exit();
		}
		if (miniglk.files[id].handle != null) return 1;
		if (i7_mg_fopen( id, Process.i7_filemode_Read) != 0) {
			i7_mg_fclose( id); return 1;
		}
		return 0;
	}
=

@h Streams.
These are channels for input/output, carrying bytes (which are usually characters).

= (text to inform7_cslib.cs)
	internal static MgStream i7_mg_new_stream(Stream F, int win_id) {
		MgStream S = new MgStream();
		S.to_file = F;
		S.to_file_id = -1;
		S.to_memory = null;
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
		S.style = null;
		S.fixed_pitch = 0;
		S.composite_style = null;
		return S;
	}

	internal int i7_mg_open_stream(Stream F, int win_id) {
		for (int i=0; i<MiniGlkData.I7_MINIGLK_MAX_STREAMS; i++)
			if (miniglk.memory_streams[i].active == 0) {
				miniglk.memory_streams[i] = i7_mg_new_stream( F, win_id);
				miniglk.memory_streams[i].active = 1;
				miniglk.memory_streams[i].previous_id =
					state.current_output_stream_ID;
				return i;
			}
		Console.Error.WriteLine("Out of streams"); i7_fatal_exit();
		return 0;
	}
=

@ This allows us to implement |glk_stream_open_memory| and its Unicode-text
analogue |glk_stream_open_memory_uni|, and |glk_stream_open_file|.

= (text to inform7_cslib.cs)
	internal int i7_miniglk_stream_open_memory(int buffer,
		int len, int fmode, int rock) {
		if (fmode != Process.i7_filemode_Write) {
			Console.Error.WriteLine("Only file mode Write supported, not {0}", fmode);
			i7_fatal_exit();
		}
		int id = i7_mg_open_stream( null, 0);
		miniglk.memory_streams[id].write_here_on_closure = buffer;
		miniglk.memory_streams[id].write_limit = (long) len;
		miniglk.memory_streams[id].char_size = 1;
		state.current_output_stream_ID = id;
		return id;
	}

	internal int i7_miniglk_stream_open_memory_uni(int buffer,
		int len, int fmode, int rock) {
		if (fmode != Process.i7_filemode_Write) {
			Console.Error.WriteLine("Only file mode Write supported, not {0}", fmode);
			i7_fatal_exit();
		}
		int id = i7_mg_open_stream( null, 0);
		miniglk.memory_streams[id].write_here_on_closure = buffer;
		miniglk.memory_streams[id].write_limit = (long) len;
		miniglk.memory_streams[id].char_size = 4;
		state.current_output_stream_ID = id;
		return id;
	}

	internal int i7_miniglk_stream_open_file(int fileref,
		int usage, int rock) {
		int id = i7_mg_open_stream( null, 0);
		miniglk.memory_streams[id].to_file_id = fileref;
		if (i7_mg_fopen( fileref, usage) == 0) return 0;
		return id;
	}

@ |glk_stream_set_position| and |glk_stream_get_position| are essentially for
moving to the start or end of a file, at least for our purposes.

= (text to inform7_cslib.cs)
	internal void i7_miniglk_stream_set_position(int id, int pos,
		int seekmode) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_STREAMS)) {
			Console.Error.WriteLine("Stream ID {0} out of range", id); i7_fatal_exit();
		}

		if (miniglk.memory_streams[id].to_file_id >= 0) {
			int origin = 0;
			switch (seekmode) {
				case i7_seekmode_Start: origin = (int)SeekOrigin.Begin; break;
				case i7_seekmode_Current: origin = (int)SeekOrigin.Current; break;
				case i7_seekmode_End: origin = (int)SeekOrigin.End; break;
				default: Console.Error.WriteLine("Unknown seekmode"); i7_fatal_exit(); break;
			}
			i7_mg_fseek( miniglk.memory_streams[id].to_file_id, pos, origin);
		} else {
			Console.Error.WriteLine("glk_stream_set_position supported only for file streams");
			i7_fatal_exit();
		}
	}

	internal int i7_miniglk_stream_get_position(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_STREAMS)) {
			Console.Error.WriteLine("Stream ID {0} out of range", id); i7_fatal_exit();
		}

		if (miniglk.memory_streams[id].to_file_id >= 0) {
			return (int) i7_mg_ftell( miniglk.memory_streams[id].to_file_id);
		}
		return (int) miniglk.memory_streams[id].memory_used;
	}
=

@ Each ss has a current stream, and |glk_stream_get_current| and
|glk_stream_set_current| give access to this.


= (text to inform7_cslib.cs)
	internal int i7_miniglk_stream_get_current() {
		return state.current_output_stream_ID;
	}

	internal void i7_miniglk_stream_set_current(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_STREAMS)) {
			Console.Error.WriteLine("Stream ID {0} out of range", id); i7_fatal_exit();
		}
		state.current_output_stream_ID = id;
	}
=

@ The thing which is "current" about the current stream is that this is where
characters are written to. The following implements |glk_put_char_stream|.

= (text to inform7_cslib.cs)
	internal void i7_mg_put_to_stream(int rock, char c) {

		if (receiver == null) Console.OpenStandardOutput().WriteByte((byte) c);
		else receiver(rock, c, miniglk.memory_streams[state.current_output_stream_ID].composite_style);
	}

	internal void i7_miniglk_put_char_stream(int stream_id, int x) {
		if (miniglk.memory_streams[stream_id].to_file != null) {
			int win_id = miniglk.memory_streams[stream_id].owned_by_window_id;
			int rock = -1;
			if (win_id >= 1) rock = i7_mg_get_window_rock( win_id);
			uint c = (uint) x;
			if (use_UTF8 != 0) {
				if (c >= 0x200000) { /* invalid Unicode */
					i7_mg_put_to_stream(rock, '?');
				} else if (c >= 0x10000) {
					i7_mg_put_to_stream(rock, 0xF0 + (c >> 18));
					i7_mg_put_to_stream(rock, 0x80 + ((c >> 12) & 0x3f));
					i7_mg_put_to_stream(rock, 0x80 + ((c >> 6) & 0x3f));
					i7_mg_put_to_stream(rock, 0x80 + (c & 0x3f));
				}
				if (c >= 0x800) {
					i7_mg_put_to_stream( rock, (char) (0xE0 + (c >> 12)));
					i7_mg_put_to_stream( rock, (char) (0x80 + ((c >> 6) & 0x3f)));
					i7_mg_put_to_stream( rock, (char) (0x80 + (c & 0x3f)));
				} else if (c >= 0x80) {
					i7_mg_put_to_stream( rock, (char) (0xC0 + (c >> 6)));
					i7_mg_put_to_stream( rock, (char) (0x80 + (c & 0x3f)));
				} else i7_mg_put_to_stream( rock, (char) c);
			} else {
				i7_mg_put_to_stream( rock, (char) c);
			}
		} else if (miniglk.memory_streams[stream_id].to_file_id >= 0) {
			i7_mg_fputc( (int) x, miniglk.memory_streams[stream_id].to_file_id);
			miniglk.memory_streams[stream_id].end_position++;
		} else {
			if (miniglk.memory_streams[stream_id].memory_used >= miniglk.memory_streams[stream_id].memory_capacity) {
				long needed = 4*miniglk.memory_streams[stream_id].memory_capacity;
				if (needed == 0) needed = 1024;
				byte[] new_data = new byte[needed];
				if (new_data == null) {
					Console.Error.WriteLine("Out of memory"); i7_fatal_exit();
				}
				for (long i=0; i<miniglk.memory_streams[stream_id].memory_used; i++) new_data[i] = miniglk.memory_streams[stream_id].to_memory[i];
				miniglk.memory_streams[stream_id].to_memory = new_data;
			}
			miniglk.memory_streams[stream_id].to_memory[miniglk.memory_streams[stream_id].memory_used++] = (byte) x;
		}
	}

@ Note that the current stream is irrelevant to reading characters, where we
have to specify exactly which stream is intended. Here's |glk_get_char_stream|:

= (text to inform7_cslib.cs)
	internal int i7_miniglk_get_char_stream(int stream_id) {
		if (miniglk.memory_streams[stream_id].to_file_id >= 0) {
			miniglk.memory_streams[stream_id].chars_read++;
			return i7_mg_fgetc( miniglk.memory_streams[stream_id].to_file_id);
		}
		return 0;
	}

@ And finally |glk_stream_close|, which is far from being an empty courtesy:
we may have to close a file on disc, or we may have to copy a memory buffer into
ss memory.

= (text to inform7_cslib.cs)
	internal void i7_miniglk_stream_close(int id, int result) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_STREAMS)) {
			Console.Error.WriteLine("Stream ID {0} out of range", id); i7_fatal_exit();
		}
		if (id == 0) { Console.Error.WriteLine("Cannot close stdout"); i7_fatal_exit(); }
		if (id == 1) { Console.Error.WriteLine("Cannot close stderr"); i7_fatal_exit(); }
		if (miniglk.memory_streams[id].active == 0) {
			Console.Error.WriteLine("Stream {0} already closed", id); i7_fatal_exit();
		}
		if (state.current_output_stream_ID == id)
			state.current_output_stream_ID = miniglk.memory_streams[id].previous_id;
		if (miniglk.memory_streams[id].write_here_on_closure != 0) {
			if (miniglk.memory_streams[id].char_size == 4) {
				for (int i = 0; i < miniglk.memory_streams[id].write_limit; i++)
					if (i < miniglk.memory_streams[id].memory_used)
						i7_write_word(miniglk.memory_streams[id].write_here_on_closure, i, miniglk.memory_streams[id].to_memory[i]);
					else
						i7_write_word(miniglk.memory_streams[id].write_here_on_closure, i, 0);
			} else {
				for (int i = 0; i < miniglk.memory_streams[id].write_limit; i++)
					if (i < miniglk.memory_streams[id].memory_used)
						i7_write_byte(miniglk.memory_streams[id].write_here_on_closure + i, miniglk.memory_streams[id].to_memory[i]);
					else
						i7_write_byte(miniglk.memory_streams[id].write_here_on_closure + i, 0);
			}
		}
		if (result == -1) {
			i7_push(miniglk.memory_streams[id].chars_read);
			i7_push(miniglk.memory_streams[id].memory_used);
		} else if (result != 0) {
			i7_write_word(result, 0, miniglk.memory_streams[id].chars_read);
			i7_write_word(result, 1, miniglk.memory_streams[id].memory_used);
		}
		if (miniglk.memory_streams[id].to_file_id >= 0) i7_mg_fclose( miniglk.memory_streams[id].to_file_id);
		miniglk.memory_streams[id].active = 0;
		miniglk.memory_streams[id].memory_used = 0;
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

= (text to inform7_cslib.cs)
	internal int i7_miniglk_window_open(int split, int method,
		int size, int wintype, int rock) {
		if (miniglk.no_windows >= 128) {
			Console.Error.WriteLine("Out of windows"); i7_fatal_exit();
		}
		int id = miniglk.no_windows++;
		miniglk.windows[id].type = wintype;
		miniglk.windows[id].stream_id = i7_mg_open_stream( Console.OpenStandardOutput(), id);
		miniglk.windows[id].rock = rock;
		return id;
	}

	internal int i7_miniglk_set_window(int id) {
		if ((id < 0) || (id >= miniglk.no_windows)) {
			Console.Error.WriteLine("Window ID {0} out of range", id); i7_fatal_exit();
		}
		i7_miniglk_stream_set_current( miniglk.windows[id].stream_id);
		return 0;
	}

	internal int i7_mg_get_window_rock(int id) {
		if ((id < 0) || (id >= miniglk.no_windows)) {
			Console.Error.WriteLine("Window ID {0} out of range", id); i7_fatal_exit();
		}
		return miniglk.windows[id].rock;
	}

	internal int i7_miniglk_window_get_size(int id, int a1,
		int a2) {
		if (a1 != 0) i7_write_word(a1, 0, 80);
		if (a2 != 0) i7_write_word(a2, 0, 8);
		return 0;
	}
=

@h Events.
Pending events are stored in a ring buffer, where the valid pending events are
those between the |rb_back| and |rb_front| markers, modulo |I7_MINIGLK_RING_BUFFER_SIZE|.
(In practice, this is more than we need for the very simple use that the standard
I7 kits make of events. Still, it does no harm.)

= (text to inform7_cslib.cs)
	void i7_mg_add_event_to_buffer(MgEvent e) {
		miniglk.events_ring_buffer[miniglk.rb_front] = e;
		miniglk.rb_front++;
		if (miniglk.rb_front == MiniGlkData.I7_MINIGLK_RING_BUFFER_SIZE)
			miniglk.rb_front = 0;
	}

	MgEvent i7_mg_get_event_from_buffer() {
		if (miniglk.rb_front == miniglk.rb_back) return null;
		MgEvent e = miniglk.events_ring_buffer[miniglk.rb_back];
		miniglk.rb_back++;
		if (miniglk.rb_back == MiniGlkData.I7_MINIGLK_RING_BUFFER_SIZE)
			miniglk.rb_back = 0;
		return e;
	}
=

@ That enables |glk_select|, an operation by which the caller can choose to
pull an event from the buffer and (optionally) copy its data ihto ss
memory.

= (text to inform7_cslib.cs)
	internal int i7_miniglk_select(int/* TODO bool*/ structure) {
		MgEvent e = i7_mg_get_event_from_buffer();
		if (e == null) {
			Console.Error.WriteLine("No events available to select"); i7_fatal_exit();
		}
		if (structure == -1) {
			i7_push(e.type);
			i7_push(e.win_id);
			i7_push(e.val1);
			i7_push(e.val2);
		} else {
			if (structure != 0) {
				i7_write_word(structure, 0, e.type);
				i7_write_word(structure, 1, e.win_id);
				i7_write_word(structure, 2, e.val1);
				i7_write_word(structure, 3, e.val2);
			}
		}
		return 0;
	}

@ And also |glk_request_line_event|. This asks the ss's sender function to
compose a command (terminated by 0 or a newline), then makes that it into a
line event and pushes it to the event buffer. The caller can then use |glk_select|
to find out what the command was.

= (text to inform7_cslib.cs)
	internal int i7_miniglk_request_line_event(int window_id,
		int buffer, int max_len, int init_len) {
		MgEvent e = new MgEvent();
		e.type = Process.i7_evtype_LineInput;
		e.win_id = window_id;
		e.val1 = 1;
		e.val2 = 0;
		char c; int pos = init_len;
		if (sender == null) i7_benign_exit();
		string s = sender(send_count++);
		int i = 0;
		while (true) {
			c = s[i++];
			if ((c == -1) || (c == 0) || (c == '\n') || (c == '\r')) break;
			if (pos < max_len) i7_write_byte(buffer + pos++, (byte) c);
		}
		if (pos < max_len) i7_write_byte(buffer + pos, 0);
		else i7_write_byte(buffer + max_len-1, 0);
		e.val1 = pos;
		i7_mg_add_event_to_buffer(e);
		if (miniglk.no_line_events++ == 1000) {
			Console.WriteLine("[Too many line events: terminating to prevent hang]");
			i7_benign_exit();
		}
		return 0;
	}

	internal int i7_miniglk_request_line_event_uni(int window_id,
		int buffer, int max_len, int init_len) {
		MgEvent e = new MgEvent();
		e.type = Process.i7_evtype_LineInput;
		e.win_id = window_id;
		e.val1 = 1;
		e.val2 = 0;
		char c; int pos = init_len;
		if (sender == null) i7_benign_exit();
		string s = sender(send_count++);
		int i = 0;
		while (1) {
			c = s[i++];
			if ((c == EOF) || (c == 0) || (c == '\n') || (c == '\r')) break;
			if (pos < max_len) i7_write_word(buffer, pos++, c);
		}
		if (pos < max_len) i7_write_word(buffer, pos, 0);
		else i7_write_word(proc, buffer, max_len-1, 0);
		e.val1 = pos;
		i7_mg_add_event_to_buffer(e);
		if (pminiglk.no_line_events++ == 1000) {
			Console.WriteLine("[Too many line events: terminating to prevent hang]\n");
			i7_benign_exit();
		}
		return 0;
	}
}

@h Styling.
This happens outside of miniglk. Glk does have a concept of text styles, but one
which is difficult to marry to CSS-esque styles in the way we might want here.
So we provide this additional styling functionality outside of the Glk specification.
When |which| is 1, we're essentially emulating Inform 6's |font| statement; when
it is 2, we're emulation |style|, though an enhanced version capable of more than
the three built-in styles |bold|, |italic| and |reverse|.

= (text to inform7_cslib.cs)
partial class Defaults {
	public static void i7_default_stylist(Process proc, int which, int what) {
		if (which == 1) {
			proc.miniglk.memory_streams[proc.state.current_output_stream_ID].fixed_pitch = what;
		} else {
			proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style = null;
			switch (what) {
				case 0: break;
				case 1: proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style = "bold"; break;
				case 2: proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style = "italic"; break;
				case 3: proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style = "reverse"; break;
				default: {
					#if i7_mgl_BASICINFORMKIT
					int L =
						i7_fn_TEXT_TY_CharacterLength( what, 0, 0, 0, 0, 0, 0);
					if (L > 127) L = 127;
					for (int i=0; i<L; i++) miniglk.memory_streams[proc.state.current_output_stream_ID].style[i] =
						i7_fn_BlkValueRead( what, i, 0);
					proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style[L] = 0;
					#endif
				} break;
			}
		}
		proc.miniglk.memory_streams[proc.state.current_output_stream_ID].composite_style = proc.miniglk.memory_streams[proc.state.current_output_stream_ID].style;
		if (proc.miniglk.memory_streams[proc.state.current_output_stream_ID].fixed_pitch != 0) {
			if (proc.miniglk.memory_streams[proc.state.current_output_stream_ID].composite_style != null)
				proc.miniglk.memory_streams[proc.state.current_output_stream_ID].composite_style += ",";
			proc.miniglk.memory_streams[proc.state.current_output_stream_ID].composite_style += "fixedpitch";
		}
	}
}
=
