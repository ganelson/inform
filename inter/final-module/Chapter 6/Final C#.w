[CSTarget::] Final C#.

To generate C# code from intermediate code.

@h Target.
This generator produces C# source code, using the Vanilla algorithm.

=
void CSTarget::create_generator() {
	code_generator *CS_generator = Generators::new(I"C#");

	METHOD_ADD(CS_generator, BEGIN_GENERATION_MTID, CSTarget::begin_generation);
	METHOD_ADD(CS_generator, END_GENERATION_MTID, CSTarget::end_generation);

	CSProgramControl::initialise(CS_generator);
	CSNamespace::initialise(CS_generator);
	CSMemoryModel::initialise(CS_generator);
	CSFunctionModel::initialise(CS_generator);
	CSObjectModel::initialise(CS_generator);
	CSLiteralsModel::initialise(CS_generator);
	CSGlobals::initialise(CS_generator);
	CSAssembly::initialise(CS_generator);
	CSInputOutputModel::initialise(CS_generator);
}

@h Segmentation.
This generator produces two files: a primary one implementing the Inter program
in C#, and TODO a secondary header file defining certain constants so that external
code can interface with it. Both are divided into segments. The main file thus:

@e cs_header_inclusion_I7CGS
@e cs_ids_and_maxima_I7CGS
@e cs_function_predeclarations_I7CGS
@e cs_library_inclusion_I7CGS
@e cs_predeclarations_I7CGS
@e cs_actions_I7CGS
@e cs_quoted_text_I7CGS
@e cs_constants_I7CGS
@e cs_text_literals_code_I7CGS
@e cs_arrays_I7CGS
@e cs_function_declarations_I7CGS
@e cs_verb_arrays_I7CGS
@e cs_function_callers_I7CGS
@e cs_globals_array_I7CGS
@e cs_memory_array_I7CGS
@e cs_initialiser_I7CGS
@e cs_constructor_I7CGS

=
int CS_target_segments[] = {
	cs_header_inclusion_I7CGS,
	cs_ids_and_maxima_I7CGS,
	cs_function_predeclarations_I7CGS,
	cs_library_inclusion_I7CGS,
	cs_predeclarations_I7CGS,
	cs_actions_I7CGS,
	cs_quoted_text_I7CGS,
	cs_constants_I7CGS,
	cs_text_literals_code_I7CGS,
	cs_arrays_I7CGS,
	cs_function_declarations_I7CGS,
	cs_verb_arrays_I7CGS,
	cs_function_callers_I7CGS,
	cs_globals_array_I7CGS,
	cs_memory_array_I7CGS,
	cs_initialiser_I7CGS,
	cs_constructor_I7CGS,
	-1
};

@ And TODO the header file thus:

@e cs_instances_symbols_I7CGS
@e cs_enum_symbols_I7CGS
@e cs_kinds_symbols_I7CGS
@e cs_actions_symbols_I7CGS
@e cs_property_symbols_I7CGS
@e cs_variable_symbols_I7CGS
@e cs_function_symbols_I7CGS

=
int CS_symbols_header_segments[] = {
	cs_instances_symbols_I7CGS,
	cs_enum_symbols_I7CGS,
	cs_kinds_symbols_I7CGS,
	cs_actions_symbols_I7CGS,
	cs_property_symbols_I7CGS,
	cs_variable_symbols_I7CGS,
	cs_function_symbols_I7CGS,
	-1
};

@ This generator uses the following state data while it works:

@d CS_GEN_DATA(x) ((CS_generation_data *) (gen->generator_private_data))->x

=
typedef struct CS_generation_data {
	int compile_main;
	int compile_symbols;
	struct dictionary *symbols_header_identifiers;
	struct CS_generation_assembly_data asmdata;
	struct CS_generation_memory_model_data memdata;
	struct CS_generation_function_model_data fndata;
	struct CS_generation_object_model_data objdata;
	struct CS_generation_literals_model_data litdata;
	struct CS_generation_variables_data vardata;
	CLASS_DEFINITION
} CS_generation_data;

void CSTarget::initialise_data(code_generation *gen) {
	CS_GEN_DATA(compile_main) = TRUE;
	CS_GEN_DATA(compile_symbols) = FALSE;
	CS_GEN_DATA(symbols_header_identifiers) = Dictionaries::new(1024, TRUE);
	CSMemoryModel::initialise_data(gen);
	CSFunctionModel::initialise_data(gen);
	CSObjectModel::initialise_data(gen);
	CSLiteralsModel::initialise_data(gen);
	CSGlobals::initialise_data(gen);
	CSAssembly::initialise_data(gen);
	CSInputOutputModel::initialise_data(gen);
}

@h Begin and end.
We return |FALSE| here to signal that we want the Vanilla algorithm to
manage the process.

=
int CSTarget::begin_generation(code_generator *gtr, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(CS_generation_data), CS_target_segments);
	CodeGen::additional_segments(gen, CS_symbols_header_segments);
	CSTarget::initialise_data(gen);

	@<Parse the CS compilation options@>;
	@<Compile the CSlib header inclusion and some cslang pragmas@>;
	@<Default the dictionary resolution@>;

	CSNamespace::fix_locals(gen);
	CSMemoryModel::begin(gen);
	CSFunctionModel::begin(gen);
	CSObjectModel::begin(gen);
	CSLiteralsModel::begin(gen);
	CSGlobals::begin(gen);
	CSAssembly::begin(gen);
	CSInputOutputModel::begin(gen);
	return FALSE;
}

@<Parse the CS compilation options@> =
	linked_list *opts = TargetVMs::option_list(gen->for_VM);
	text_stream *opt;
	LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
		if (Str::eq_insensitive(opt, I"main")) CS_GEN_DATA(compile_main) = TRUE;
		else if (Str::eq_insensitive(opt, I"no-main")) CS_GEN_DATA(compile_main) = FALSE;
		else if (Str::eq_insensitive(opt, I"symbols-header")) CS_GEN_DATA(compile_symbols) = TRUE;
		else if (Str::eq_insensitive(opt, I"no-symbols-header")) CS_GEN_DATA(compile_symbols) = FALSE;
		else {
			#ifdef PROBLEMS_MODULE
			Problems::fatal("Unknown compilation format option");
			#endif
			#ifndef PROBLEMS_MODULE
			Errors::fatal("Unknown compilation format option");
			exit(1);
			#endif
		}
	}

@<Compile the CSlib header inclusion and some cslang pragmas@> =
	segmentation_pos saved = CodeGen::select(gen, cs_header_inclusion_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (Architectures::debug_enabled(TargetVMs::get_architecture(gen->for_VM)))
		WRITE("#define DEBUG\n");
	WRITE("public class i7 : Inform.Story {\n");
	if (CS_GEN_DATA(compile_main))
		WRITE("static void Main(string[] args) { Inform.Defaults.i7_default_main(args, new i7()); }\n");
	WRITE("/*#pragma clang diagnostic push\n");
	WRITE("#pragma clang diagnostic ignored \"-Wunused-value\"\n");
	WRITE("#pragma clang diagnostic ignored \"-Wparentheses-equality\"*/\n");
	CodeGen::deselect(gen, saved);
	saved = CodeGen::select(gen, cs_constructor_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("\tpublic i7() {\n");
	CodeGen::deselect(gen, saved);

@<Default the dictionary resolution@> =
	if (gen->dictionary_resolution < 0) {
		segmentation_pos saved = CodeGen::select(gen, cs_ids_and_maxima_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("const int ");
		CNamespace::mangle(gtr, OUT, I"DICT_WORD_SIZE");
		WRITE(" = 9;\n");
		CodeGen::deselect(gen, saved);
	}


@ The Inform 6 compiler automatically generates the dictionary, verb and actions
tables, but other compilers do not, of course, so generators for other languages
(such as this one) must ask Vanilla to make those tables for it.

=
int CSTarget::end_generation(code_generator *gtr, code_generation *gen) {
	VanillaIF::compile_dictionary_table(gen);
	VanillaIF::compile_verb_table(gen);
	VanillaIF::compile_actions_table(gen);
	CSFunctionModel::end(gen);
	CSObjectModel::end(gen);
	CSLiteralsModel::end(gen);
	CSGlobals::end(gen);
	CSAssembly::end(gen);
	CSInputOutputModel::end(gen);
	CSMemoryModel::end(gen); /* must be last to end */
	@<Compile end@>;
	filename *F = gen->to_file;
	if ((F) && (CS_GEN_DATA(compile_symbols))) @<String the symbols header target together@>;
	return FALSE;
}

@<Compile end@> =
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\t}\n}\n");
	CodeGen::deselect(gen, saved);

@<String the symbols header target together@> =
	filename *G = Filenames::in(Filenames::up(F), I"inform7_symbols.h");
	text_stream HF;
	if (STREAM_OPEN_TO_FILE(&HF, G, ISO_ENC) == FALSE) {
		#ifdef PROBLEMS_MODULE
		Problems::fatal_on_file("Can't open output file", G);
		#endif
		#ifndef PROBLEMS_MODULE
		Errors::fatal_with_file("Can't open output file", G);
		exit(1);
		#endif
	}
	WRITE_TO(&HF, "/* Symbols derived mechanically from Inform 7 source: do not edit */\n\n");
	WRITE_TO(&HF, "/* (1) Instance IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_instances_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (2) Values of enumerated kinds */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_enum_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (3) Kind IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_kinds_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (4) Action IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_actions_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (5) Property IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_property_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (6) Variable IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_variable_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (7) Function IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[cs_function_symbols_I7CGS]);
	STREAM_CLOSE(&HF);

@ When defining constants to be defined in the symbols header, the following
function is a convenience, automatically ensuring that names never clash:

=
text_stream *CSTarget::symbols_header_identifier(code_generation *gen,
	text_stream *prefix, text_stream *raw) {
	dictionary *D = CS_GEN_DATA(symbols_header_identifiers);
	text_stream *key = Str::new();
	WRITE_TO(key, "i7_%S_", prefix);
	LOOP_THROUGH_TEXT(pos, raw)
		if (Characters::isalnum(Str::get(pos)))
			PUT_TO(key, Str::get(pos));
		else
			PUT_TO(key, '_');
	text_stream *dv = Dictionaries::get_text(D, key);
	if (dv) {
		TEMPORARY_TEXT(keyx)
		int n = 2;
		while (TRUE) {
			Str::clear(keyx);
			WRITE_TO(keyx, "%S_%d", key, n);
			if (Dictionaries::get_text(D, keyx) == NULL) break;
			n++;
		}
		DISCARD_TEXT(keyx)
		WRITE_TO(key, "_%d", n);
	}
	Dictionaries::create_text(D, key);
	return key;
}

@h Static supporting code.
The C# code generated here would not compile as a stand-alone file. It needs
to use variables and functions from a small unchanging library called 
|inform7_cslib.cs|, which TODO has an associated header file |inform7_cslib.h| of
declarations so that code can be linked to it. (See the test makes |Eg1-CS|,
|Eg2-CS| and so on for demonstrations of this.)

Those two files are presented throughout this chapter, because the implementation
of the I7 C# library is so closely tied to the code we compile: they can only
really be understood jointly.

And similarly for |inform7_cslib.cs|:

= (text to inform7_cslib.cs)
/* This is a library of C# code to support Inter code compiled to C#. It was
   generated mechanically from the Inter source code, so to change this material,
   edit that and not this file. */

using System;
using System.IO;

namespace Inform {
=

@ TODO Now we need four fundamental types. |int| is a type which can hold any
Inter word value: since we do not support C# for 16-bit Inter code, we can
safely make this a 32-bit integer. |unsigned_int| will be used very little,
but is an unsigned version of the same. (It must be the case that an |int|
can survive being cast to |unsigned_int| and back again intact.)

|byte| holds an Inter byte value, and must be unsigned.

It must unfortunately be the case that |float| values can be stored in
|int| containers at runtime, which is why they are only |float| and not
|double| precision.

Our library is going to be able to manage multiple independently-running
"processes", storage for each of which is a single |Process| structure.
Within that, the current execution state is an |State|, which we now define.

The most important thing here is |memory|: the byte-addressable space
holding arrays and property values. (Note that, unlike the memory architecture
for the Z-machine or Glulx VMs, this memory space contains no program code. If
the same Inter code is compiled once to C, and then also to Glulx via Inform 6,
there will be some similarities between the C |memory| contents and the RAM-like
parts of the Glulx VM's memory, but only some. Addresses will be quite different
between the two.)

The valid range of memory addresses is between 0 and |himem| minus 1.

There is also a stack, but only a small one. Note that this does not contain
return addresses, in the way a traditional stack might: it simply holds values
which have explicitly been pushed by the Inter opcode |@push| and not yet pulled.
It doesn't live in memory, and cannot otherwise be read or written by the Inter
program; it is empty when |stack_pointer| is zero.

The object containment tree is also stored outside of memory; that's a choice
on our part, and makes it slightly faster to access. The same applies to the
array of global |variables|. (Again, this is a point of difference with the
traditional IF virtual machines, which put all of this in memory.)

The temporary value |tmp| holds data only fleetingly, during the execution of
a single Inter primitive or assembly opcode.

= (text to inform7_cslib.cs)
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
=

A "snapshot" is basically a saved state.
= (text to inform7_cslib.cs)
class Snapshot {
	internal bool valid;
	internal State then;

	internal Snapshot() {
		then = new State();
	}
}
=

Okay then: a "process". This contains not only the current state but snapshots
of 10 recent states, in order to facilitate the UNDO operation. Snapshots are
stored in a form of ring buffer, to avoid ever copying them in memory.
= (text to inform7_cslib.cs)
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
=

@ Creator functions for each of the above:

Note that a |State| begins with its potentially large arrays unallocated,
so it initially consumes very little memory.

The receiver and sender functions allow our textual I/O to be managed by external
CLR code: see TODO //inform7: Calling Inform from C//.

The receiver is sent every character printed out; by default, it prints every
character sent to the body text window, while suppressing all others (for example,
those printed to the "status line" used by IF games).

The sender supplies us with textual commands. By default, it takes a typed (or
of course piped) single line of text from the C |stdin| stream.

.NET's |ReadLine| method returns null on EOF, but we expect an empty string in this case.

= (text to inform7_cslib.cs)
public static partial class Defaults {
	public static void i7_default_receiver(int id, char c, string style) {
		if (id == Process.I7_BODY_TEXT_ID) Console.Write(c);
	}

	static readonly char[] i7_default_sender_buffer = new char[256];
	public static string i7_default_sender(int count) {
		string rv = Console.ReadLine();
		return rv != null ? rv : "";
	}
=

@ The C# generator can produce either a stand-alone C# program, including a |main|,
or else a file of C# code intended to be linked into something larger. If it does
provide a |main|, then that function simply calls the following; it it does not,
then the following is never used.

= (text to inform7_cslib.cs)
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
=

If external code is managing the process, and |i7_default_main| is not used,
then that external code will still call |new Process| and then |i7_run_process|,
but may in between the two supply its own receiver or sender:


= (text to inform7_cslib.cs)

partial class Process {
	public void i7_set_process_receiver(Action<int, char, string> receiver, int UTF8) {
		this.receiver = receiver;
		use_UTF8 = UTF8;
	}
	public void i7_set_process_sender(Func<int, string> sender) {
		this.sender = sender;
	}
=

Similarly, ambitious projects which want their own complete I/O systems can
set the following:

= (text to inform7_cslib.cs)
	public void i7_set_process_stylist(Action<Process, int, int> stylist) {
		this.stylist = stylist;
	}
	public void i7_set_process_glk_implementation(Func<Process, int, int, int> glk_implementation) {
		this.glk_implementation = glk_implementation;
	}
}
=

In all cases, execution is kicked off when |i7_run_process| is called on a process.
Ordinarily, that will execute the entire Inform 7 program and then come back to us;
but we need to cope with a sudden halt during execution, either through a fatal
error or through a use of the |@quit| opcode.

We do that with the |setjmp| and |longjmp| mechanism of C. This is a very limited
sort of exception-handling will a well deserved reputation for crankiness, and we
will use it with due caution. It is essential that the underlying |jmp_buf| data
not move in memory for any reason between the setting and the jumping. (This is
why there is no mechanism to copy or fork an |i7_process_t|.)

Note that the |i7_initialiser| function is compiled and is not pre-written
like these other functions: see //C# Object Model// for what it does.

= (text to inform7_cslib.cs)
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
=
