/* This is a library of C# code to support Inter code compiled to C#. It was
   generated mechanically from the Inter source code, so to change this material,
   edit that and not this file. */

using System;
using System.IO;

namespace Inform {
struct RngSeed {
	internal uint A;
	internal uint interval;
	internal uint counter;

	public static RngSeed i7_initial_rng_seed() {
		RngSeed seed = new RngSeed();
		seed.A = 1;
		return seed;
	}
}

class State {
	internal const int I7_ASM_STACK_CAPACITY   = 128;
	internal const int I7_TMP_STORAGE_CAPACITY = 128;

	internal byte[] memory;
	internal int himem;
	internal readonly int[] stack = new int[I7_ASM_STACK_CAPACITY];
	internal int stack_pointer;
	internal int[] object_tree_parent;
	internal int[] object_tree_child;
	internal int[] object_tree_sibling;
	internal int[] variables;
	internal readonly int[] tmp = new int[I7_TMP_STORAGE_CAPACITY];
	internal int current_output_stream_ID;
	internal RngSeed seed = RngSeed.i7_initial_rng_seed();
}
class Snapshot {
	internal bool valid;
	internal State then;

	internal Snapshot() {
		then = new State();
	}
}
public partial class Process {
	const int I7_MAX_SNAPSHOTS = 10;

	readonly Story story;
	internal State state = new State();
	Snapshot[] snapshots = new Snapshot[I7_MAX_SNAPSHOTS];
	int snapshot_pos;
	public int termination_code;
	public Action<int, char, string> receiver = Defaults.i7_default_receiver;
	int send_count;
	public Func<int, string> sender = Defaults.i7_default_sender;
	public Action<Process, int, int> stylist = Defaults.i7_default_stylist;
	public Func<Process, int, int, int> glk_implementation = Defaults.i7_default_glk;
	internal MiniGlkData miniglk;
	int /*TODO: bool */ use_UTF8 = 1;

	public Process(Story story) {
		this.story = story;
		i7_max_objects = story.i7_max_objects;
		for (int i=0; i<I7_MAX_SNAPSHOTS; i++) snapshots[i] = new Snapshot();
		i7_properties = new PropertySet[i7_max_objects];
		miniglk = new MiniGlkData(this);
	}
}

public abstract partial class Story {
}
public static partial class Defaults {
	public static void i7_default_receiver(int id, char c, string style) {
		if (id == Process.I7_BODY_TEXT_ID) Console.Write(c);
	}

	static readonly char[] i7_default_sender_buffer = new char[256];
	public static string i7_default_sender(int count) {
		string rv = Console.ReadLine();
		return rv != null ? rv : "";
	}
	public static int i7_default_main(string[] args, Inform.Story story) {
		Process proc = new Process(story);
		proc.i7_run_process();
		if (proc.termination_code == 1) {
			Console.Write("*** Fatal error: halted ***\n");
			Console.Out.Flush(); Console.Error.Flush();
		}
		return proc.termination_code;
	}
}

partial class Process {
	public void i7_set_process_receiver(Action<int, char, string> receiver, int UTF8) {
		this.receiver = receiver;
		use_UTF8 = UTF8;
	}
	public void i7_set_process_sender(Func<int, string> sender) {
		this.sender = sender;
	}
	public void i7_set_process_stylist(Action<Process, int, int> stylist) {
		this.stylist = stylist;
	}
	public void i7_set_process_glk_implementation(Func<Process, int, int, int> glk_implementation) {
		this.glk_implementation = glk_implementation;
	}
}
class ProcessTerminationException : Exception {
    public int return_code;
    public ProcessTerminationException(int returnCode) => this.return_code = returnCode;
}

partial class Story {
	public abstract int i7_fn_Main(Process proc);
}

partial class Process {
	public int i7_run_process() {
		try {
			i7_initialise_memory_and_stack();
			i7_initialise_variables();
			i7_empty_object_tree();
			story.i7_initialiser(this);
			story.i7_initialise_object_tree(this);
			story.i7_fn_Main(this);
			termination_code = 0; /* terminated because the program completed */
		} catch (ProcessTerminationException termination) {
			termination_code = termination.return_code; /* terminated mid-stream */
		}
		return termination_code;
	}

	public void i7_fatal_exit() {
	//  Uncomment the next line to force a crash so that the stack can be inspected in a debugger
	//	int x = 0; Console.Write("{0:D}", 1/x);
		throw new ProcessTerminationException(1);
	}

	public void i7_benign_exit() {
		throw new ProcessTerminationException(0);
	}
}
partial class Process {
	public const int i7_lvalue_SET = 1;
	public const int i7_lvalue_PREDEC = 2;
	public const int i7_lvalue_POSTDEC = 3;
	public const int i7_lvalue_PREINC = 4;
	public const int i7_lvalue_POSTINC = 5;
	public const int i7_lvalue_SETBIT = 6;
	public const int i7_lvalue_CLEARBIT = 7;
}
partial class Story {
	protected internal int i7_no_variables;
	protected internal int[] i7_initial_variable_values;
}
partial class Process {
	void i7_initialise_variables() {
		// TODO: use array copy method instead
		state.variables = new int[story.i7_no_variables];
		for (int i=0; i<story.i7_no_variables; i++)
			state.variables[i] = story.i7_initial_variable_values[i];
	}
}
partial class Story {
	protected internal int i7_static_himem;
}
partial class Story {
	internal byte[] i7_initial_memory;
}

partial class Process {
	internal int i7_static_himem;
	void i7_initialise_memory_and_stack() {
		i7_static_himem = story.i7_static_himem;
		byte[] mem = new byte[i7_static_himem];
		// TODO: we should use a copy method instead.
		for (int i=0; i<i7_static_himem; i++) mem[i] = story.i7_initial_memory[i];
		#if i7_mgl_Release
		mem[0x34] = I7BYTE_2(i7_mgl_Release); mem[0x35] = I7BYTE_3(i7_mgl_Release);
		#else
		mem[0x34] = I7BYTE_2(1); mem[0x35] = I7BYTE_3(1);
		#endif
		#if i7_mgl_Serial
		string p = i7_text_to_CLR_string(i7_mgl_Serial);
		for (int i=0; i<6; i++) mem[0x36 + i] = p[i];
		#else
		for (int i=0; i<6; i++) mem[0x36 + i] = (byte) '0';
		#endif

		state.memory = mem;
		state.himem = i7_static_himem;
		state.stack_pointer = 0;
	}
	public byte i7_read_byte(int address) {
		return state.memory[address];
	}

	public short i7_read_sword(int array_address, int array_index) {
		byte[] data = state.memory;
		int byte_position = array_address + 2*array_index;
		if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
			Console.Write("Memory access out of range: "); Console.WriteLine(byte_position);
			//TODO use native exception?
			i7_fatal_exit();
		}
		return     (short) (data[byte_position + 1]  +
					  0x1000*data[byte_position + 0]);
	}

	public int i7_read_word(int array_address, int array_index) {
		byte[] data = state.memory;
		int byte_position = array_address + 4*array_index;
		if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
			Console.Write("Memory access out of range: "); Console.WriteLine(byte_position);
			i7_fatal_exit();
		}
		return             (int) data[byte_position + 3]  +
					0x1000*((int) data[byte_position + 2]) +
				0x10000*((int) data[byte_position + 1]) +
				0x1000000*((int) data[byte_position + 0]);
	}
	public static byte I7BYTE_0(int V) => (byte) ((V & 0xFF000000) >> 24);
	public static byte I7BYTE_1(int V) => (byte) ((V & 0x00FF0000) >> 16);
	public static byte I7BYTE_2(int V) => (byte) ((V & 0x0000FF00) >> 8);
	public static byte I7BYTE_3(int V) => (byte)  (V & 0x000000FF);

	void i7_write_byte(int address, byte new_val) {
		state.memory[address] = new_val;
	}

	void i7_write_word(int address, int array_index,int new_val) {
		int byte_position = address + 4*array_index;
		if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
			Console.Write("Memory access out of range: "); Console.WriteLine(byte_position);
			i7_fatal_exit();
		}
		state.memory[byte_position]   = I7BYTE_0(new_val);
		state.memory[byte_position+1] = I7BYTE_1(new_val);
		state.memory[byte_position+2] = I7BYTE_2(new_val);
		state.memory[byte_position+3] = I7BYTE_3(new_val);
	}
	public byte i7_change_byte(int address, byte new_val, int way) {
		byte old_val = i7_read_byte(address);
		byte return_val = new_val;
		switch (way) {
			case i7_lvalue_PREDEC:   return_val = (byte)(old_val-1);   new_val = (byte)(old_val-1); break;
			case i7_lvalue_POSTDEC:  return_val = old_val;             new_val = (byte)(old_val-1); break;
			case i7_lvalue_PREINC:   return_val = (byte)(old_val+1);   new_val = (byte)(old_val+1); break;
			case i7_lvalue_POSTINC:  return_val = old_val;             new_val = (byte)(old_val+1); break;
			case i7_lvalue_SETBIT:   new_val = (byte)(old_val | new_val);   return_val = new_val; break;
			case i7_lvalue_CLEARBIT: new_val = (byte)(old_val &(~new_val)); return_val = new_val; break;
		}
		i7_write_byte(address, new_val);
		return return_val;
	}

	public int i7_change_word(int array_address, int array_index,
		int new_val, int way) {
		byte[] data = state.memory;
		int old_val = i7_read_word(array_address, array_index);
		int return_val = new_val;
		switch (way) {
			case i7_lvalue_PREDEC:   return_val = old_val-1;   new_val = old_val-1; break;
			case i7_lvalue_POSTDEC:  return_val = old_val; new_val = old_val-1; break;
			case i7_lvalue_PREINC:   return_val = old_val+1;   new_val = old_val+1; break;
			case i7_lvalue_POSTINC:  return_val = old_val; new_val = old_val+1; break;
			case i7_lvalue_SETBIT:   new_val = old_val | new_val; return_val = new_val; break;
			case i7_lvalue_CLEARBIT: new_val = old_val &(~new_val); return_val = new_val; break;
		}
		i7_write_word(array_address, array_index, new_val);
		return return_val;
	}
	internal void i7_debug_stack(string N) {
		#if I7_LOG_STACK_STATE
		Console.WriteLine("Called {0}: stack {1} ", N, state.stack_pointer);
		for (int i=0; i<state.stack_pointer; i++)
			Console.Write("{0:D} -> ", state.stack[i]);
		Console.WriteLine();
		#endif
	}

	internal int i7_pull() {
		if (state.stack_pointer <= 0) {
			Console.WriteLine("Stack underflow");
			i7_fatal_exit();
		}
		return state.stack[--(state.stack_pointer)];
	}

	internal void i7_push(int x) {
		if (state.stack_pointer >= State.I7_ASM_STACK_CAPACITY) {
			Console.WriteLine("Stack overflow");
			i7_fatal_exit();
		}
		state.stack[state.stack_pointer++] = x;
	}
	void i7_copy_state(State to, State from) {
		//TODO move these to State
		to.himem = from.himem;
		to.memory = new byte[i7_static_himem];
		//TODO copyarray
		for (int i=0; i<i7_static_himem; i++) to.memory[i] = from.memory[i];
		for (int i=0; i<State.I7_TMP_STORAGE_CAPACITY; i++) to.tmp[i] = from.tmp[i];
		to.stack_pointer = from.stack_pointer;
		for (int i=0; i<from.stack_pointer; i++) to.stack[i] = from.stack[i];
		to.object_tree_parent  = new int[i7_max_objects];
		to.object_tree_child   = new int[i7_max_objects];
		to.object_tree_sibling = new int[i7_max_objects];

		for (int i=0; i<i7_max_objects; i++) {
			to.object_tree_parent[i] = from.object_tree_parent[i];
			to.object_tree_child[i] = from.object_tree_child[i];
			to.object_tree_sibling[i] = from.object_tree_sibling[i];
		}
		to.variables = new int[story.i7_no_variables];
		for (int i=0; i<story.i7_no_variables; i++) to.variables[i] = from.variables[i];
		to.current_output_stream_ID = from.current_output_stream_ID;
	}

	void i7_destroy_state(State s) {
		s.memory = null;
		s.himem = 0;
		s.stack_pointer = 0;
		s.object_tree_parent = null;
		s.object_tree_child = null;
		s.object_tree_sibling = null;
		s.variables = null;
	}
	void i7_destroy_snapshot(Snapshot unwanted) {
		i7_destroy_state(unwanted.then);
		unwanted.valid = false;
	}

	void i7_destroy_latest_snapshot() {
		int will_be = snapshot_pos - 1;
		if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
		if (snapshots[will_be].valid)
			i7_destroy_snapshot(snapshots[will_be]);
		snapshot_pos = will_be;
	}
	void i7_save_snapshot() {
		if (snapshots[snapshot_pos].valid)
			i7_destroy_snapshot(snapshots[snapshot_pos]);
		snapshots[snapshot_pos] = new Snapshot();
		snapshots[snapshot_pos].valid = true;
		i7_copy_state(snapshots[snapshot_pos].then, state);
		int was = snapshot_pos;
		snapshot_pos++;
		if (snapshot_pos == I7_MAX_SNAPSHOTS) snapshot_pos = 0;
	}
	bool i7_has_snapshot() {
		int will_be = snapshot_pos - 1;
		if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
		return snapshots[will_be].valid;
	}
	void i7_restore_snapshot() {
		int will_be = snapshot_pos - 1;
		if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
		if (!snapshots[will_be].valid) {
			Console.WriteLine("Restore impossible");
			i7_fatal_exit();
		}
		i7_destroy_state(state);
		i7_copy_state(state, snapshots[will_be].then);
		i7_destroy_snapshot(snapshots[will_be]);
		int was = snapshot_pos;
		snapshot_pos = will_be;
	}
}
partial class Process {
	internal void i7_opcode_call(int fn_ref, int varargc, out int z) {
		int[] args = new int[varargc];
		for (int i=0; i<varargc; i++) args[i] = i7_pull();
		z = i7_gen_call(fn_ref, args);
	}
	internal void i7_opcode_copy(int x, out int y) {
		y = x;
	}
	internal void i7_opcode_aload(int x, int y, out int z) {
		z = i7_read_word(x, y);
	}

	internal void i7_opcode_aloads(int x, int y, out int z) {
		z = i7_read_sword(x, y);
	}

	internal void i7_opcode_aloadb(int x, int y, out int z) {
		z = i7_read_byte(x+y);
	}
	internal void i7_opcode_shiftl(int x, int y, out int z) {
		int value = 0;
		if ((y >= 0) && (y < 32)) value = (x << y);
		z = value;
	}

	internal void i7_opcode_ushiftr(int x, int y, out int z) {
		int value = 0;
		if ((y >= 0) && (y < 32)) value = (x >> y);
		z = value;
	}
	internal int i7_opcode_jeq(int x, int y) {
		if (x == y) return 1;
		return 0;
	}

	internal int i7_opcode_jleu(int x, int y) {
		uint ux, uy;
		ux = unchecked((uint) x); uy = unchecked((uint) y);
		if (ux <= uy) return 1;
		return 0;
	}

	internal int i7_opcode_jnz(int x) {
		if (x != 0) return 1;
		return 0;
	}

	internal int i7_opcode_jz(int x) {
		if (x == 0) return 1;
		return 0;
	}
	internal void i7_opcode_nop() {
	}

	internal void i7_opcode_quit() {
		i7_fatal_exit();
	}

	internal void i7_opcode_verify(out int z) {
		z = 0;
	}
	internal void i7_opcode_restoreundo(out int x) {
		if (i7_has_snapshot()) {
			i7_restore_snapshot();
			x = 0;
			#if i7_mgl_DealWithUndo
			i7_fn_DealWithUndo(this);
			#endif
		} else {
			x = 1;
		}
	}

	internal void i7_opcode_saveundo(out int x) {
		i7_save_snapshot();
		x = 0;
	}

	internal void i7_opcode_hasundo(out int x) {
		int rv = 0; if (i7_has_snapshot()) rv = 1;
		x = rv;
	}

	internal void i7_opcode_discardundo() {
		i7_destroy_latest_snapshot();
	}
	internal void i7_opcode_restart() {
		Console.WriteLine("(RESTART is not implemented on this C# program.)");
	}

	internal void i7_opcode_restore(int x, out int y) {
		Console.WriteLine("(RESTORE is not implemented on this C# program.)");
		y = 1;
	}

	internal void i7_opcode_save(int x, out int y) {
		Console.WriteLine("(SAVE is not implemented on this C# program.)");
		y = 1;
	}
	internal void i7_opcode_streamnum(int x) {
		i7_print_decimal(x);
	}

	internal void i7_opcode_streamchar(int x) {
		i7_print_char(x);
	}

	internal void i7_opcode_streamunichar(int x) {
		i7_print_char(x);
	}
	const int serop_KeyIndirect       = 1;
	const int serop_ZeroKeyTerminates = 2;
	const int serop_ReturnIndex       = 4;

	internal void i7_opcode_binarysearch(int key, int keysize,
		int start, int structsize, int numstructs, int keyoffset,
		int options, out int s1) {

		/* If the key size is 4 or fewer, copy it directly into the keybuf array */
		byte[] keybuf = new byte[4];
		if ((options & serop_KeyIndirect) != 0) {
			if (keysize <= 4)
				for (int ix=0; ix<keysize; ix++)
					keybuf[ix] = i7_read_byte(key + ix);
		} else {
			switch (keysize) {
				case 4:
					keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key);
					keybuf[2] = I7BYTE_2(key); keybuf[3] = I7BYTE_3(key); break;
				case 2:
					keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key); break;
				case 1:
					keybuf[0] = (byte) key; break;
			}
		}

		int bot = 0, top = numstructs; /* Initial search range, including bot but not top */
		while (bot < top) { /* I.e., while the search range is not empty */
			/* Find the structure at the midpoint of the search range */
			int val = (top+bot) / 2;
			int addr = start + val * structsize;

			/* Compute cmp = 0 if the key matches this, -1 if it precedes, 1 if it follows */
			int cmp = 0;
			if (keysize <= 4) {
				for (int ix=0; (cmp == 0) && ix<keysize; ix++) {
					byte byte_ = i7_read_byte(addr + keyoffset + ix);
					byte byte2 = keybuf[ix];
					if (byte_ < byte2) cmp = -1;
					else if (byte_ > byte2) cmp = 1;
				}
			} else {
				for (int ix=0; (cmp == 0) && ix<keysize; ix++) {
					byte byte_  = i7_read_byte(addr + keyoffset + ix);
					byte byte2 = i7_read_byte(key + ix);
					if (byte_ < byte2) cmp = -1;
					else if (byte_ > byte2) cmp = 1;
				}
			}

			if (cmp == 0) {
				/* Success! */
				if ((options & serop_ReturnIndex) != 0) s1 = val; else s1 = addr;
				return;
			}

			if (cmp < 0) bot = val+1; /* Chop search range to the second half */
			else top = val; /* Chop search range to the first half */
		}

		/* Failure! */
		if ((options & serop_ReturnIndex) != 0) s1 = -1; else s1 = 0;
	}
	internal void i7_opcode_mcopy(int x, int y, int z) {
		if (z < y)
			for (int i=0; i<x; i++)
				i7_write_byte(z+i, i7_read_byte(y+i));
		else
			for (int i=x-1; i>=0; i--)
				i7_write_byte(z+i, i7_read_byte(y+i));
	}

	internal void i7_opcode_mzero(int x, int y) {
		for (int i=0; i<x; i++) i7_write_byte(y+i, 0);
	}

	internal void i7_opcode_malloc(int x, int y) {
		Console.WriteLine("Unimplemented: i7_opcode_malloc.");
		i7_fatal_exit();
	}

	internal void i7_opcode_mfree(int x) {
		Console.WriteLine("Unimplemented: i7_opcode_mfree.");
		i7_fatal_exit();
	}
	internal void i7_opcode_random(int x, out int y) {
		uint rawvalue = 0;
		if (state.seed.interval != 0) {
			rawvalue = state.seed.counter++;
			if (state.seed.counter == state.seed.interval) state.seed.counter = 0;
		} else {
			state.seed.A = (uint)(0x015a4e35L * state.seed.A + 1);;
			rawvalue = (state.seed.A >> 16) & 0x7fff;
		}
		uint value;
		if (x == 0) value = rawvalue;
		else if (x >= 1) value = rawvalue % (uint) (x);
		else value = (uint) -(rawvalue % (uint) (-x));
		y = (int) value;
	}

	internal void i7_opcode_setrandom(int s) {
		if (s == 0) {
			state.seed.A = (uint) DateTime.Now.Ticks;
			state.seed.interval = 0;
		} else if (s < 1000) {
			state.seed.interval = (uint) s;
			state.seed.counter = 0;
		} else {
			state.seed.A = (uint) s;
			state.seed.interval = 0;
		}
	}

	internal int i7_random(int x) {
		int r;
		i7_opcode_random(x, out r);
		return r+1;
	}
	internal void i7_opcode_setiosys(int x, int y) {
	}
	internal void i7_opcode_gestalt(int x, int y, out int z) {
		int r = 0;
		switch (x) {
			case 0: r = 0x00030103; break; /* Say that the Glulx version is v3.1.3 */
			case 1: r = 1;          break; /* Say that the interpreter version is 1 */
			case 2: r = 0;          break; /* We do not (yet) support @setmemsize */
			case 3: r = 1;          break; /* We do support UNDO */
			case 4: if (y == 2) r = 1;     /* We do support Glk */
						else r = 0;     /* But not any other I/O system */
					break;
			case 5: r = 1;          break; /* We do support Unicode operations */
			case 6: r = 1;          break; /* We do support @mzero and @mcopy */
			case 7: r = 0;          break; /* We do not (yet) support @malloc or @mfree */
			case 8: r = 0;          break; /* Since we do not support @malloc */
			case 9: r = 0;          break; /* We do not support @accelfunc pr @accelparam */
			case 10: r = 0;         break; /* And therefore provide none of their accelerants */
			case 11: r = 1;         break; /* We do support floating-point maths operations */
			case 12: r = 1;         break; /* We do support @hasundo and @discardundo */
		}
		z = r;
	}
}
partial class Process {
	internal void i7_opcode_add(int x, int y, out int z) {
		z = x + y;
	}
	internal void i7_opcode_sub(int x, int y, out int z) {
		z = x - y;
	}
	internal void i7_opcode_neg(int x, out int y) {
		y = -x;
	}
	internal void i7_opcode_mul(int x, int y, out int z) {
		z = x * y;
	}

	internal void i7_opcode_div(int x, int y, out int z) {
		if (y == 0) { Console.WriteLine("Division of {0:D} by 0", x); i7_fatal_exit(); z=0; return; }
		int result, ax, ay;
		if (x < 0) {
			ax = (-x);
			if (y < 0) {
				ay = (-y);
				result = ax / ay;
			} else {
				ay = y;
				result = -(ax / ay);
			}
		} else {
			ax = x;
			if (y < 0) {
				ay = (-y);
				result = -(ax / ay);
			} else {
				ay = y;
				result = ax / ay;
			}
		}
		z = result;
	}

	internal void i7_opcode_mod(int x, int y, out int z) {
		if (y == 0) { Console.WriteLine("Division of {0:D} by 0", x); z=0; i7_fatal_exit(); return; }
		int result, ax, ay = (y < 0)?(-y):y;
		if (x < 0) {
			ax = (-x);
			result = -(ax % ay);
		} else {
			ax = x;
			result = ax % ay;
		}
		z = result;
	}

	internal int i7_div(int x, int y) {
		int z;
		i7_opcode_div(x, y, out z);
		return z;
	}

	internal int i7_mod(int x, int y) {
		int z;
		i7_opcode_mod(x, y, out z);
		return z;
	}
	internal void i7_opcode_fadd(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) + i7_decode_float(y));
	}
	internal void i7_opcode_fsub(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) - i7_decode_float(y));
	}
	internal void i7_opcode_fmul(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) * i7_decode_float(y));
	}
	internal void i7_opcode_fdiv(int x, int y, out int z) {
		z = i7_encode_float(i7_decode_float(x) / i7_decode_float(y));
	}
	internal void i7_opcode_fmod(int x, int y, out int z, out int w) {
		float fx = i7_decode_float(x), fy = i7_decode_float(y);
		float fquot = fx % fy;
		int quot = i7_encode_float(fquot);
		int rem = i7_encode_float((fx-fquot) / fy);
		if (rem == 0x0 || rem == unchecked((int)0x80000000)) {
			/* When the quotient is zero, the sign has been lost in the
			shuffle. We'll set that by hand, based on the original arguments. */
			rem = (x ^ y) & unchecked((int)0x80000000);
		}
		z = quot;
		w = rem;
	}

	internal void i7_opcode_floor(int x, out int y) {
		y = i7_encode_float((float)Math.Floor(i7_decode_float(x)));
	}
	internal void i7_opcode_ceil(int x, out int y) {
		y = i7_encode_float((float)Math.Ceiling(i7_decode_float(x)));
	}

	internal void i7_opcode_ftonumn(int x, out int y) {
		float fx = i7_decode_float(x);
		int result;
		if (Math.Sign(fx) > 1) {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx > 2147483647.0))
				result = 0x7FFFFFFF;
			else
				result = (int) (Math.Round(fx));
		}
		else {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx < -2147483647.0))
				result = unchecked((int)0x80000000);
			else
				result = (int) (Math.Round(fx));
		}
		y = result;
	}

	internal void i7_opcode_ftonumz(int x, out int y) {
		float fx = i7_decode_float(x);
		int result;
		if (Math.Sign(fx) > 1) {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx > 2147483647.0))
				result = 0x7FFFFFFF;
			else
				result = (int) (Math.Truncate(fx));
		}
		else {
			if (float.IsNaN(fx) || float.IsInfinity(fx) || (fx < -2147483647.0))
				result = unchecked((int)0x80000000);
			else
				result = (int) (Math.Truncate(fx));
		}
		y = result;
	}

	internal void i7_opcode_numtof(int x, out int y) {
		y = i7_encode_float((float) x);
	}
	internal void i7_opcode_exp(int x, out int y) {
		y = i7_encode_float((float)Math.Exp(i7_decode_float(x)));
	}
	internal void i7_opcode_log(int x, out int y) {
		y = i7_encode_float((float)Math.Log(i7_decode_float(x)));
	}
	internal void i7_opcode_pow(int x, int y, out int z) {
		if (i7_decode_float(x) == 1.0f)
			z = i7_encode_float(1.0f);
		else if ((i7_decode_float(y) == 0.0f) || (i7_decode_float(y) == -0.0f))
			z = i7_encode_float(1.0f);
		else if ((i7_decode_float(x) == -1.0f) && float.IsInfinity(i7_decode_float(y)))
			z = i7_encode_float(1.0f);
		else
			z = i7_encode_float((float)Math.Pow(i7_decode_float(x), i7_decode_float(y)));
	}
	internal void i7_opcode_sqrt(int x, out int y) {
		y = i7_encode_float((float)Math.Sqrt(i7_decode_float(x)));
	}
	internal void i7_opcode_sin(int x, out int y) {
		y = i7_encode_float((float)Math.Sin(i7_decode_float(x)));
	}
	internal void i7_opcode_cos(int x, out int y) {
		y = i7_encode_float((float)Math.Cos(i7_decode_float(x)));
	}
	internal void i7_opcode_tan(int x, out int y) {
		y = i7_encode_float((float)Math.Tan(i7_decode_float(x)));
	}

	internal void i7_opcode_asin(int x, out int y) {
		y = i7_encode_float((float)Math.Asin(i7_decode_float(x)));
	}
	internal void i7_opcode_acos(int x, out int y) {
		y = i7_encode_float((float)Math.Acos(i7_decode_float(x)));
	}
	internal void i7_opcode_atan(int x, out int y) {
		y = i7_encode_float((float)Math.Atan(i7_decode_float(x)));
	}

	internal int i7_opcode_jfeq(int x, int y, int z) {
		int result;
		if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
			/* The delta is NaN, which can never match. */
			result = 0;
		} else if ((x == 0x7F800000 || (uint) x == 0xFF800000)
				&& (y == 0x7F800000 || (uint) y == 0xFF800000)) {
			/* Both are infinite. Opposite infinities are never equal,
			even if the difference is infinite, so this is easy. */
			result = (x == y) ? 1 : 0;
		} else {
			float fx = i7_decode_float(y) - i7_decode_float(x);
			float fy = System.Math.Abs(i7_decode_float(z));
			result = (fx <= fy && fx >= -fy) ? 1 : 0;
		}
		return result;
	}

	internal int i7_opcode_jfne(int x, int y, int z) {
		int result;
		if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
			/* The delta is NaN, which can never match. */
			result = 0;
		} else if ((x == 0x7F800000 || (uint) x == 0xFF800000)
				&& (y == 0x7F800000 || (uint) y == 0xFF800000)) {
			/* Both are infinite. Opposite infinities are never equal,
			even if the difference is infinite, so this is easy. */
			result = (x == y) ? 1 : 0;
		} else {
			float fx = i7_decode_float(y) - i7_decode_float(x);
			float fy = System.Math.Abs(i7_decode_float(z));
			result = (fx <= fy && fx >= -fy) ? 1 : 0;
		}
		return result;
	}

	internal int i7_opcode_jfge(int x, int y) {
		if (i7_decode_float(x) >= i7_decode_float(y)) return 1;
		return 0;
	}

	internal int i7_opcode_jflt(int x, int y) {
		if (i7_decode_float(x) < i7_decode_float(y)) return 1;
		return 0;
	}

	internal int i7_opcode_jisinf(int x) {
		if (x == 0x7F800000 || (uint) x == 0xFF800000) return 1;
		return 0;
	}

	internal int i7_opcode_jisnan(int x) {
		if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
		return 0;
	}
}
partial class Story {
	internal int i7_strings_base;
	internal string[] i7_texts;
}

partial class Process {
	public string i7_text_to_CLR_string(int str) {
		return story.i7_texts[str - story.i7_strings_base];
	}
}
partial class Process {
	public void i7_print_dword(int at) {
		for (byte i=1; i<=i7_mgl_DICT_WORD_SIZE; i++) {
			int c = i7_read_word(at, i);
			if (c == 0) break;
			i7_print_char(c);
		}
	}
}
partial class Story {
	protected internal int i7_max_objects;
	protected internal int i7_no_property_ids;
	protected internal int i7_functions_base;
	protected internal int[] i7_metaclass_of;
	protected internal int[] i7_class_of;
	protected internal readonly int i7_special_class_Routine;
	protected internal readonly int i7_special_class_String;
	protected internal readonly int i7_special_class_Class;
	protected internal readonly int i7_special_class_Object;
	protected internal int i7_metaclass(int id) {
		if (id <= 0) return 0;
		if (id >= i7_functions_base) return i7_special_class_Routine;
		if (id >= i7_strings_base) return i7_special_class_String;
		return i7_metaclass_of[id];
	}
}
partial class Process {
	internal int i7_ofclass(int id, int cl_id) {
		if ((id <= 0) || (cl_id <= 0)) return 0;
		if (id >= story.i7_functions_base) {
			if (cl_id == story.i7_special_class_Routine) return 1;
			return 0;
		}
		if (id >= story.i7_strings_base) {
			if (cl_id == story.i7_special_class_String) return 1;
			return 0;
		}
		if (id == story.i7_special_class_Class) {
			if (cl_id == story.i7_special_class_Class) return 1;
			return 0;
		}
		if (cl_id == story.i7_special_class_Object) {
			if (story.i7_metaclass_of[id] == story.i7_special_class_Object) return 1;
			return 0;
		}
		int cl_found = story.i7_class_of[id];
		while (cl_found != story.i7_special_class_Class) {
			if (cl_id == cl_found) return 1;
			cl_found = story.i7_class_of[cl_found];
		}
		return 0;
	}
	int i7_max_objects;
	int i7_no_property_ids;
	void i7_empty_object_tree() {
		//TODO: move to State?
		i7_max_objects = story.i7_max_objects;
		i7_no_property_ids = story.i7_no_property_ids;
		state.object_tree_parent  = new int[i7_max_objects];
		state.object_tree_child   = new int[i7_max_objects];
		state.object_tree_sibling = new int[i7_max_objects];
		for (int i=0; i<i7_max_objects; i++) {
			state.object_tree_parent[i] = 0;
			state.object_tree_child[i] = 0;
			state.object_tree_sibling[i] = 0;
		}
	}
}
partial class Story {
	public abstract void i7_initialise_object_tree(Process proc);
}
partial class Story {
	public abstract void i7_initialiser(Process proc);
}

class PropertySet {
	const int I7_MAX_PROPERTY_IDS = 1000;

	internal readonly int[] address = new int[I7_MAX_PROPERTY_IDS];
	internal readonly int[] len = new int[I7_MAX_PROPERTY_IDS];
}

partial class Process {
	internal readonly PropertySet[] i7_properties;

	internal int i7_prop_len(int K, int obj, int pr_array) {
		int pr = i7_read_word(pr_array, 1);
		if ((obj <= 0) || (obj >= i7_max_objects) ||
			(pr < 0) || (pr >= i7_no_property_ids)) return 0;
		return 4*i7_properties[(int) obj].len[(int) pr];
	}

	internal int i7_prop_addr(int K, int obj, int pr_array) {
		int pr = i7_read_word(pr_array, 1);
		if ((obj <= 0) || (obj >= i7_max_objects) ||
			(pr < 0) || (pr >= i7_no_property_ids)) return 0;
		return i7_properties[(int) obj].address[(int) pr];
	}

	internal bool i7_provides(int owner_id, int pr_array) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) return false;
		while (owner_id != 1) {
			if (i7_properties[(int) owner_id].address[(int) prop_id] != 0) return true;
			owner_id = story.i7_class_of[owner_id];
		}
		return false;
	}
	internal void i7_move(int obj, int to) {
		if ((obj <= 0) || (obj >= i7_max_objects)) return;
		int p = state.object_tree_parent[obj];
		if (p != 0) {
			if (state.object_tree_child[p] == obj) {
				state.object_tree_child[p] = state.object_tree_sibling[obj];
			} else {
				int c = state.object_tree_child[p];
				while (c != 0) {
					if (state.object_tree_sibling[c] == obj) {
						state.object_tree_sibling[c] = state.object_tree_sibling[obj];
						break;
					}
					c = state.object_tree_sibling[c];
				}
			}
		}
		state.object_tree_parent[obj] = to;
		state.object_tree_sibling[obj] = 0;
		if (to != 0) {
			state.object_tree_sibling[obj] = state.object_tree_child[to];
			state.object_tree_child[to] = obj;
		}
	}
	int i7_parent(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_parent[id];
	}
	int i7_child(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_child[id];
	}
	int i7_children(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		int c=0;
		for (int i=0; i<i7_max_objects; i++)
			if (state.object_tree_parent[i] == id)
				c++;
		return c;
	}
	int i7_sibling(int id) {
		if (story.i7_metaclass( id) != story.i7_special_class_Object) return 0;
		return state.object_tree_sibling[id];
	}
	int i7_in(int obj1, int obj2) {
		if (story.i7_metaclass(obj1) != story.i7_special_class_Object) return 0;
		if (obj2 == 0) return 0;
		if (state.object_tree_parent[obj1] == obj2) return 1;
		return 0;
	}
	int i7_read_prop_value(int owner_id, int pr_array) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
		while (i7_properties[(int) owner_id].address[(int) prop_id] == 0) {
			owner_id = story.i7_class_of[owner_id];
			if (owner_id == story.i7_special_class_Class) return 0;
		}
		int address = i7_properties[(int)owner_id].address[(int)prop_id];
		return i7_read_word(address, 0);
	}

	void i7_write_prop_value(int owner_id, int pr_array, int val) {
		int prop_id = i7_read_word(pr_array, 1);
		if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
			(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
			Console.WriteLine("impossible property write ({0:D}, {1:D})", owner_id, prop_id);
			i7_fatal_exit();
		}
		int address = i7_properties[(int) owner_id].address[(int) prop_id];
		if (address != 0) i7_write_word(address, 0, val);
		else {
			Console.WriteLine("impossible property write ({0:D}, {1:D})", owner_id, prop_id);
			i7_fatal_exit();
		}
	}

	int i7_change_prop_value(int obj, int pr,
		int to, int way) {
		int val = i7_read_prop_value(obj, pr), new_val = val;
		switch (way) {
			case i7_lvalue_SET:
				i7_write_prop_value(obj, pr, to); new_val = to; break;
			case i7_lvalue_PREDEC:
				new_val = val-1; i7_write_prop_value(obj, pr, val-1); break;
			case i7_lvalue_POSTDEC:
				new_val = val; i7_write_prop_value(obj, pr, val-1); break;
			case i7_lvalue_PREINC:
				new_val = val+1; i7_write_prop_value(obj, pr, val+1); break;
			case i7_lvalue_POSTINC:
				new_val = val; i7_write_prop_value(obj, pr, val+1); break;
			case i7_lvalue_SETBIT:
				new_val = val | new_val; i7_write_prop_value(obj, pr, new_val); break;
			case i7_lvalue_CLEARBIT:
				new_val = val &(~new_val); i7_write_prop_value(obj, pr, new_val); break;
		}
		return new_val;
	}
}
partial class Process {
	internal bool i7_provides_gprop_inner(int K, int obj, int pr,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if (K == i7_mgl_OBJECT_TY) {
			if ((((obj != 0) && ((story.i7_metaclass( obj) == story.i7_special_class_Object)))) &&
				(((i7_read_word(pr, 0) == 2) || (i7_provides(obj, pr)))))
				return true;
		} else {
			if ((((obj >= 1)) && ((obj <= i7_read_word(i7_mgl_value_ranges, K))))) {
				int holder = i7_read_word(i7_mgl_value_property_holders, K);
				if (((holder !=0) && ((i7_provides(holder, pr))))) return true;
			}
		}
		return false;
	}

	internal int i7_read_gprop_value_inner(int K, int obj, int pr,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		int val = 0;
		if ((K == i7_mgl_OBJECT_TY)) {
			return (int) i7_read_prop_value(obj, pr);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			return (int) i7_read_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE));
		}
		return val;
	}

	internal void i7_write_gprop_value_inner(int K, int obj, int pr,
		int val, int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if ((K == i7_mgl_OBJECT_TY)) {
			i7_write_prop_value(obj, pr, val);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			i7_write_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE), val);
		}
	}

	internal void i7_change_gprop_value_inner(int K, int obj, int pr,
		int val, int form,
		int i7_mgl_OBJECT_TY, int i7_mgl_value_ranges,
		int i7_mgl_value_property_holders, int i7_mgl_COL_HSIZE) {
		if ((K == i7_mgl_OBJECT_TY)) {
			i7_change_prop_value(obj, pr, val, form);
		} else {
			int holder = i7_read_word(i7_mgl_value_property_holders, K);
			i7_change_word(
				i7_read_prop_value(holder, pr), (obj + i7_mgl_COL_HSIZE), val, form);
		}
	}
}
partial class Story {
	public abstract int i7_gen_call(Inform.Process proc, int id, int[] args);
}

partial class Process {
	int i7_gen_call(int id, int[] args) {
		return story.i7_gen_call(this, id, args);
	}
}
partial class Process {
	public int i7_call_0(int id) {
		int[] args = new int[10];
		return i7_gen_call(id, args);
	}
	public int i7_call_1(int id, int v) {
		int[] args = new int[10];
		args[0] = v;
		return i7_gen_call(id, args);
	}
	public int i7_call_2(int id, int v, int v2) {
		int[] args = new int[10];
		args[0] = v; args[1] = v2;
		return i7_gen_call(id, args);
	}
	public int i7_call_3(int id, int v, int v2,
		int v3) {
		int[] args = new int[10];
		args[0] = v; args[1] = v2; args[2] = v3;
		return i7_gen_call(id, args);
	}
	public int i7_call_4(int id, int v, int v2,
		int v3, int v4) {
		int[] args = new int[10];
		args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
		return i7_gen_call(id, args);
	}
	public int i7_call_5(int id, int v, int v2,
		int v3, int v4, int v5) {
		int[] args = new int[10];
		args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
		return i7_gen_call(id, args);
	}
}
partial class Story {
	protected internal int i7_var_self;
}

partial class Process {
	int i7_mcall_0(int to, int prop) {
		int[] args = new int[0];
		int saved = state.variables[story.i7_var_self];
		state.variables[story.i7_var_self] = to;
		int id = i7_read_prop_value(to, prop);
		int rv = i7_gen_call(id, args);
		state.variables[story.i7_var_self] = saved;
		return rv;
	}

	int i7_mcall_1(int to, int prop, int v) {
		int[] args = new int[1];
		args[0] = v;
		int saved = state.variables[story.i7_var_self];
		state.variables[story.i7_var_self] = to;
		int id = i7_read_prop_value(to, prop);
		int rv = i7_gen_call(id, args);
		state.variables[story.i7_var_self] = saved;
		return rv;
	}

	int i7_mcall_2(int to, int prop, int v,
		int v2) {
		int[] args = new int[2];
		args[0] = v; args[1] = v2;
		int saved = state.variables[story.i7_var_self];
		state.variables[story.i7_var_self] = to;
		int id = i7_read_prop_value(to, prop);
		int rv = i7_gen_call(id, args);
		state.variables[story.i7_var_self] = saved;
		return rv;
	}

	int i7_mcall_3(int to, int prop, int v,
		int v2, int v3) {
		int[] args = new int[3];
		args[0] = v; args[1] = v2; args[2] = v3;
		int saved = state.variables[story.i7_var_self];
		state.variables[story.i7_var_self] = to;
		int id = i7_read_prop_value(to, prop);
		int rv = i7_gen_call(id, args);
		state.variables[story.i7_var_self] = saved;
		return rv;
	}
}
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
	internal void i7_print_char(int x) {
		if (x == 13) x = 10;
		i7_push(x);
		int current = 0;
		i7_opcode_glk(GlkOpcodes.i7_glk_stream_get_current, 0, out current);
		i7_push(current);
		i7_opcode_glk(GlkOpcodes.i7_glk_put_char_stream, 2, out int _);
	}
	internal void i7_styling(int which, int what) {
		stylist(this, which, what);
	}
	internal void i7_opcode_glk(int glk_api_selector, int varargc,
		out int z) {
		z = glk_implementation(this, glk_api_selector, varargc);
	}
}
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
partial class Process {
	public const int I7_BODY_TEXT_ID         = 201;
	public const int I7_STATUS_TEXT_ID       = 202;
	public const int I7_BOX_TEXT_ID          = 203;
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
	public const int i7_seekmode_Start = (0);
	public const int i7_seekmode_Current = (1);
	public const int i7_seekmode_End = (2);
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
	internal int i7_miniglk_stream_get_current() {
		return state.current_output_stream_ID;
	}

	internal void i7_miniglk_stream_set_current(int id) {
		if ((id < 0) || (id >= MiniGlkData.I7_MINIGLK_MAX_STREAMS)) {
			Console.Error.WriteLine("Stream ID {0} out of range", id); i7_fatal_exit();
		}
		state.current_output_stream_ID = id;
	}
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

	internal int i7_miniglk_get_char_stream(int stream_id) {
		if (miniglk.memory_streams[stream_id].to_file_id >= 0) {
			miniglk.memory_streams[stream_id].chars_read++;
			return i7_mg_fgetc( miniglk.memory_streams[stream_id].to_file_id);
		}
		return 0;
	}

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
partial class Process {
	static int i7_encode_float(float val) {
		return BitConverter.SingleToInt32Bits(val);
	}

	static float i7_decode_float(int val) {
		return BitConverter.Int32BitsToSingle(val);
	}
	int i7_read_variable(int var_id) {
		return state.variables[var_id];
	}
	void i7_write_variable(int var_id, int val) {
		state.variables[var_id] = val;
	}

	string i7_read_string(int S) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_TEXT_TY_Transmute(proc, S);
		int L = i7_fn_TEXT_TY_CharacterLength(proc, S, 0, 0, 0, 0, 0, 0);
		string A = malloc(L + 1);
		if (A == NULL) {
			Console.Error.WriteLine("Out of memory"); i7_fatal_exit();
		}
		for (int i=0; i<L; i++)
			A[i] = i7_fn_BlkValueRead(proc, S, i, 0);
		A[L] = 0;
		return A;
		#endif
		#if !i7_mgl_BASICINFORMKIT
		return null;
		#endif
	}

	void i7_write_string(int S, string A) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_TEXT_TY_Transmute(proc, S);
		i7_fn_BlkValueWrite(proc, S, 0, 0, 0);
		if (A) {
			int L = strlen(A);
			for (int i=0; i<L; i++)
				i7_fn_BlkValueWrite(proc, S, i, A[i], 0);
		}
		#endif
	}
	int[] i7_read_list(int S, out int N) {
		#if i7_mgl_BASICINFORMKIT
		int L = i7_fn_LIST_OF_TY_GetLength(proc, S);
		int *A = calloc(L + 1, sizeof(int));
		if (A == NULL) {
			Console.Error.WriteLine("Out of memory"); i7_fatal_exit();
		}
		for (int i=0; i<L; i++) A[i] = i7_fn_LIST_OF_TY_GetItem(proc, S, i+1, 0, 0);
		A[L] = 0;
		N = L;
		return A;
		#endif
		#if !i7_mgl_BASICINFORMKIT
		N = 0;
		return null;
		#endif

	}

	void i7_write_list(int S, out int A, int L) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_LIST_OF_TY_SetLength(proc, S, L, 0, 0, 0, 0, 0, 0);
		if (A) {
			for (int i=0; i<L; i++)
				i7_fn_LIST_OF_TY_PutItem(proc, S, i+1, A[i], 0, 0);
		}
		#endif
		#if !i7_mgl_BASICINFORMKIT
		A = 0;
		#endif

	}
#if i7_mgl_TryAction
	int i7_fn_TryAction(int i7_mgl_local_req,
		int i7_mgl_local_by, int i7_mgl_local_ac, int i7_mgl_local_n,
		int i7_mgl_local_s, int i7_mgl_local_stora, int i7_mgl_local_smeta,
		int i7_mgl_local_tbits, int i7_mgl_local_saved_command,
		int i7_mgl_local_text_of_command);
	int i7_try(int action_id, int n, int s) {
		return i7_fn_TryAction(proc, 0, 0, action_id, n, s, 0, 0, 0, 0, 0);
	}
#endif
}
}
