[CTarget::] Final C.

To generate ANSI C-99 code from intermediate code.

@h Target.
This generator produces C source code, using the Vanilla algorithm.

=
void CTarget::create_generator(void) {
	code_generator *C_generator = Generators::new(I"c");

	METHOD_ADD(C_generator, BEGIN_GENERATION_MTID, CTarget::begin_generation);
	METHOD_ADD(C_generator, END_GENERATION_MTID, CTarget::end_generation);

	CProgramControl::initialise(C_generator);
	CNamespace::initialise(C_generator);
	CMemoryModel::initialise(C_generator);
	CFunctionModel::initialise(C_generator);
	CObjectModel::initialise(C_generator);
	CLiteralsModel::initialise(C_generator);
	CGlobals::initialise(C_generator);
	CAssembly::initialise(C_generator);
	CInputOutputModel::initialise(C_generator);
}

@h Segmentation.
This generator produces two files: a primary one implementing the Inter program
in C, and a secondary header file defining certain constants so that external
code can interface with it. Both are divided into segments. The main file thus:

@e c_header_inclusion_I7CGS
@e c_ids_and_maxima_I7CGS
@e c_function_predeclarations_I7CGS
@e c_library_inclusion_I7CGS
@e c_predeclarations_I7CGS
@e c_actions_I7CGS
@e c_quoted_text_I7CGS
@e c_constants_I7CGS
@e c_text_literals_code_I7CGS
@e c_arrays_I7CGS
@e c_function_declarations_I7CGS
@e c_verb_arrays_I7CGS
@e c_function_callers_I7CGS
@e c_memory_array_I7CGS
@e c_globals_array_I7CGS
@e c_initialiser_I7CGS

=
int C_target_segments[] = {
	c_header_inclusion_I7CGS,
	c_ids_and_maxima_I7CGS,
	c_function_predeclarations_I7CGS,
	c_library_inclusion_I7CGS,
	c_predeclarations_I7CGS,
	c_actions_I7CGS,
	c_quoted_text_I7CGS,
	c_constants_I7CGS,
	c_text_literals_code_I7CGS,
	c_arrays_I7CGS,
	c_function_declarations_I7CGS,
	c_verb_arrays_I7CGS,
	c_function_callers_I7CGS,
	c_memory_array_I7CGS,
	c_globals_array_I7CGS,
	c_initialiser_I7CGS,
	-1
};

@ And the header file thus:

@e c_instances_symbols_I7CGS
@e c_enum_symbols_I7CGS
@e c_kinds_symbols_I7CGS
@e c_actions_symbols_I7CGS
@e c_property_symbols_I7CGS
@e c_variable_symbols_I7CGS
@e c_function_symbols_I7CGS

=
int C_symbols_header_segments[] = {
	c_instances_symbols_I7CGS,
	c_enum_symbols_I7CGS,
	c_kinds_symbols_I7CGS,
	c_actions_symbols_I7CGS,
	c_property_symbols_I7CGS,
	c_variable_symbols_I7CGS,
	c_function_symbols_I7CGS,
	-1
};

@ This generator uses the following state data while it works:

@d C_GEN_DATA(x) ((C_generation_data *) (gen->generator_private_data))->x

=
typedef struct C_generation_data {
	int compile_main;
	int compile_symbols;
	struct dictionary *symbols_header_identifiers;
	struct C_generation_assembly_data asmdata;
	struct C_generation_memory_model_data memdata;
	struct C_generation_function_model_data fndata;
	struct C_generation_object_model_data objdata;
	struct C_generation_literals_model_data litdata;
	struct C_generation_variables_data vardata;
	CLASS_DEFINITION
} C_generation_data;

void CTarget::initialise_data(code_generation *gen) {
	C_GEN_DATA(compile_main) = TRUE;
	C_GEN_DATA(compile_symbols) = FALSE;
	C_GEN_DATA(symbols_header_identifiers) = Dictionaries::new(1024, TRUE);
	CMemoryModel::initialise_data(gen);
	CFunctionModel::initialise_data(gen);
	CObjectModel::initialise_data(gen);
	CLiteralsModel::initialise_data(gen);
	CGlobals::initialise_data(gen);
	CAssembly::initialise_data(gen);
	CInputOutputModel::initialise_data(gen);
}

@h Begin and end.
We return |FALSE| here to signal that we want the Vanilla algorithm to
manage the process.

=
int CTarget::begin_generation(code_generator *gtr, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(C_generation_data), C_target_segments);
	CodeGen::additional_segments(gen, C_symbols_header_segments);
	CTarget::initialise_data(gen);

	@<Parse the C compilation options@>;
	@<Compile the Clib header inclusion and some clang pragmas@>;
	@<Compile the Clib code inclusion@>;
	@<Default the dictionary resolution@>;

	CNamespace::fix_locals(gen);
	CMemoryModel::begin(gen);
	CFunctionModel::begin(gen);
	CObjectModel::begin(gen);
	CLiteralsModel::begin(gen);
	CGlobals::begin(gen);
	CAssembly::begin(gen);
	CInputOutputModel::begin(gen);
	return FALSE;
}

@<Parse the C compilation options@> =
	linked_list *opts = TargetVMs::option_list(gen->for_VM);
	text_stream *opt;
	LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
		if (Str::eq_insensitive(opt, I"main")) C_GEN_DATA(compile_main) = TRUE;
		else if (Str::eq_insensitive(opt, I"no-main")) C_GEN_DATA(compile_main) = FALSE;
		else if (Str::eq_insensitive(opt, I"symbols-header")) C_GEN_DATA(compile_symbols) = TRUE;
		else if (Str::eq_insensitive(opt, I"no-symbols-header")) C_GEN_DATA(compile_symbols) = FALSE;
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

@<Compile the Clib header inclusion and some clang pragmas@> =
	segmentation_pos saved = CodeGen::select(gen, c_header_inclusion_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if (Architectures::debug_enabled(TargetVMs::get_architecture(gen->for_VM)))
		WRITE("#define DEBUG\n");
	WRITE("#include \"inform7_clib.h\"\n");
	if (C_GEN_DATA(compile_main))
		WRITE("int main(int argc, char **argv) { return i7_default_main(argc, argv); }\n");
	WRITE("#pragma clang diagnostic push\n");
	WRITE("#pragma clang diagnostic ignored \"-Wunused-value\"\n");
	WRITE("#pragma clang diagnostic ignored \"-Wparentheses-equality\"\n");
	CodeGen::deselect(gen, saved);

@<Compile the Clib code inclusion@> =
	segmentation_pos saved = CodeGen::select(gen, c_library_inclusion_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.c\"\n");
	CodeGen::deselect(gen, saved);

@<Default the dictionary resolution@> =
	if (gen->dictionary_resolution < 0) {
		segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("#define ");
		CNamespace::mangle(gtr, OUT, I"DICT_WORD_SIZE");
		WRITE(" 9\n");
		CodeGen::deselect(gen, saved);
	}

@ The Inform 6 compiler automatically generates the dictionary, verb and actions
tables, but other compilers do not, of course, so generators for other languages
(such as this one) must ask Vanilla to make those tables for it.

=
int CTarget::end_generation(code_generator *gtr, code_generation *gen) {
	VanillaIF::compile_dictionary_table(gen);
	VanillaIF::compile_verb_table(gen);
	VanillaIF::compile_actions_table(gen);
	CFunctionModel::end(gen);
	CObjectModel::end(gen);
	CLiteralsModel::end(gen);
	CGlobals::end(gen);
	CAssembly::end(gen);
	CInputOutputModel::end(gen);
	CMemoryModel::end(gen); /* must be last to end */
	@<Compile end to clang pragmas@>;
	filename *F = gen->to_file;
	if ((F) && (C_GEN_DATA(compile_symbols))) @<String the symbols header target together@>;
	return FALSE;
}

@<Compile end to clang pragmas@> =
	segmentation_pos saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#pragma clang diagnostic pop\n");
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
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_instances_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (2) Values of enumerated kinds */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_enum_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (3) Kind IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_kinds_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (4) Action IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_actions_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (5) Property IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_property_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (6) Variable IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_variable_symbols_I7CGS]);
	WRITE_TO(&HF, "\n/* (7) Function IDs */\n\n");
	CodeGen::write_segment(&HF, gen->segmentation.segments[c_function_symbols_I7CGS]);
	STREAM_CLOSE(&HF);

@ When defining constants to be defined in the symbols header, the following
function is a convenience, automatically ensuring that names never clash:

=
text_stream *CTarget::symbols_header_identifier(code_generation *gen,
	text_stream *prefix, text_stream *raw) {
	dictionary *D = C_GEN_DATA(symbols_header_identifiers);
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
The C code generated here would not compile as a stand-alone file. It needs
to use variables and functions from a small unchanging library called 
|inform7_clib.c|, which has an associated header file |inform7_clib.h| of
declarations so that code can be linked to it. (See the test makes |Eg1-C|,
|Eg2-C| and so on for demonstrations of this.)

Those two files are presented throughout this chapter, because the implementation
of the I7 C library is so closely tied to the code we compile: they can only
really be understood jointly.

Here is the beginning of the header file |inform7_clib.h|:

= (text to inform7_clib.h)
/* This is a header file for using a library of C code to support Inter code
   compiled to ANSI C. It was generated mechanically from the Inter source code,
   so to change this material, edit that and not this file. */

#ifndef I7_CLIB_H_INCLUDED
#define I7_CLIB_H_INCLUDED 1

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <ctype.h>
#include <stdint.h>
#include <setjmp.h>
=

And similarly for |inform7_clib.c|:

= (text to inform7_clib.c)
/* This is a library of C code to support Inter code compiled to ANSI C. It was
   generated mechanically from the Inter source code, so to change this material,
   edit that and not this file. */

#ifndef I7_CLIB_C_INCLUDED
#define I7_CLIB_C_INCLUDED 1
=

@ Now we need four fundamental types. |i7word_t| is a type which can hold any
Inter word value: since we do not support C for 16-bit Inter code, we can
safely make this a 32-bit integer. |unsigned_i7word_t| will be used very little,
but is an unsigned version of the same. (It must be the case that an |i7word_t|
can survive being cast to |unsigned_i7word_t| and back again intact.)

|i7byte_t| holds an Inter byte value, and must be unsigned.

It must unfortunately be the case that |i7float_t| values can be stored in
|i7word_t| containers at runtime, which is why they are only |float| and not
|double| precision.

= (text to inform7_clib.h)
typedef int32_t i7word_t;
typedef uint32_t unsigned_i7word_t;
typedef unsigned char i7byte_t;
typedef float i7float_t;
=

Our library is going to be able to manage multiple independently-running
"processes", storage for each of which is a single |i7process_t| structure.
Within that, the current execution state is an |i7state_t|, which we now define.

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

= (text to inform7_clib.h)
#define I7_ASM_STACK_CAPACITY 128
#define I7_TMP_STORAGE_CAPACITY 128

typedef struct i7rngseed_t {
	uint32_t A;
	uint32_t interval;
	uint32_t counter;
} i7rngseed_t;

typedef struct i7state_t {
	i7byte_t *memory;
	i7word_t himem;
	i7word_t stack[I7_ASM_STACK_CAPACITY];
	int stack_pointer;
	i7word_t *object_tree_parent;
	i7word_t *object_tree_child;
	i7word_t *object_tree_sibling;
	i7word_t *variables;
	i7word_t tmp[I7_TMP_STORAGE_CAPACITY];
	i7word_t current_output_stream_ID;
	struct i7rngseed_t seed;
} i7state_t;
=

A "snapshot" is basically a saved state. At present, in fact, it is only that:
at one time this included a |jmp_buf| to preserve C stack state too, but that
turned out to be troublesome and unnecessary.
= (text to inform7_clib.h)
typedef struct i7snapshot_t {
	int valid;
	struct i7state_t then;
} i7snapshot_t;
=

Okay then: a "process". This contains not only the current state but snapshots
of 10 recent states, in order to facilitate the UNDO operation. Snapshots are
stored in a form of ring buffer, to avoid ever copying them in memory: this
is because there is no remotely safe way to copy a |jmp_buf|, which (see above)
was at one time part of a snapshot.
= (text to inform7_clib.h)
#define I7_MAX_SNAPSHOTS 10
typedef struct i7process_t {
	i7state_t state;
	i7snapshot_t snapshots[I7_MAX_SNAPSHOTS];
	int snapshot_pos;
	jmp_buf execution_env;
	int termination_code;
	void (*receiver)(int id, wchar_t c, char *style);
	int send_count;
	char *(*sender)(int count);
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what);
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z);
	struct miniglk_data *miniglk;
	int use_UTF8;
} i7process_t;
=

@ Creator functions for each of the above:

= (text to inform7_clib.h)
i7state_t i7_new_state(void);
i7snapshot_t i7_new_snapshot(void);
i7process_t i7_new_process(void);
=

Note that an |i7state_t| begins with its potentially large arrays unallocated,
so it initially consumes very little memory.
= (text to inform7_clib.c)
i7state_t i7_new_state(void) {
	i7state_t S;
	S.memory = NULL;
	S.himem = 0;
	S.stack_pointer = 0;
	S.object_tree_parent = NULL; S.object_tree_child = NULL; S.object_tree_sibling = NULL;
	S.variables = NULL;
	S.seed = i7_initial_rng_seed();
	return S;
}

i7snapshot_t i7_new_snapshot(void) {
	i7snapshot_t SS;
	SS.valid = 0;
	SS.then = i7_new_state();
	return SS;
}

i7process_t i7_new_process(void) {
	i7process_t proc;
	proc.state = i7_new_state();
	for (int i=0; i<I7_MAX_SNAPSHOTS; i++) proc.snapshots[i] = i7_new_snapshot();
	proc.snapshot_pos = 0;
	proc.receiver = i7_default_receiver;
	proc.send_count = 0;
	proc.sender = i7_default_sender;
	proc.stylist = i7_default_stylist;
	proc.glk_implementation = i7_default_glk;
	proc.use_UTF8 = 1;
	i7_initialise_miniglk_data(&proc);
	return proc;
}
=

@ The |i7_new_process| function refers to two default functions attached to
a new process, so we must define those:

= (text to inform7_clib.h)
char *i7_default_sender(int count);
void i7_default_receiver(int id, wchar_t c, char *style);
=

The receiver and sender functions allow our textual I/O to be managed by external
C code: see //inform7: Calling Inform from C//.

The receiver is sent every character printed out; by default, it prints every
character sent to the body text window, while suppressing all others (for example,
those printed to the "status line" used by IF games).

The sender supplies us with textual commands. By default, it takes a typed (or
of course piped) single line of text from the C |stdin| stream.

= (text to inform7_clib.c)
void i7_default_receiver(int id, wchar_t c, char *style) {
	if (id == I7_BODY_TEXT_ID) fputc(c, stdout);
}

char i7_default_sender_buffer[256];
char *i7_default_sender(int count) {
	int pos = 0;
	while (1) {
		int c = getchar();
		if ((c == EOF) || (c == '\n') || (c == '\r')) break;
		if (pos < 255) i7_default_sender_buffer[pos++] = c;
	}
	i7_default_sender_buffer[pos++] = 0;
	return i7_default_sender_buffer;
}
=

@ The C generator can produce either a stand-alone C program, including a |main|,
or else a file of C code intended to be linked into something larger. If it does
provide a |main|, then that function simply calls the following; it it does not,
then the following is never used.

= (text to inform7_clib.h)
int i7_default_main(int argc, char **argv);
=

= (text to inform7_clib.c)
int i7_default_main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_run_process(&proc);
	if (proc.termination_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return proc.termination_code;
}
=

If external code is managing the process, and |i7_default_main| is not used,
then that external code will still call |i7_new_process| and then |i7_run_process|,
but may in between the two supply its own receiver or sender:

= (text to inform7_clib.h)
void i7_set_process_receiver(i7process_t *proc,
	void (*receiver)(int id, wchar_t c, char *style), int UTF8);
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count));
=

= (text to inform7_clib.c)
void i7_set_process_receiver(i7process_t *proc,
	void (*receiver)(int id, wchar_t c, char *style), int UTF8) {
	proc->receiver = receiver;
	proc->use_UTF8 = UTF8;
}
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count)) {
	proc->sender = sender;
}
=

Similarly, ambitious projects which want their own complete I/O systems can
set the following:

= (text to inform7_clib.h)
void i7_set_process_stylist(i7process_t *proc,
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what));
void i7_set_process_glk_implementation(i7process_t *proc,
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z));
=

= (text to inform7_clib.c)
void i7_set_process_stylist(i7process_t *proc,
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what)) {
	proc->stylist = stylist;
}
void i7_set_process_glk_implementation(i7process_t *proc,
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z)) {
	proc->glk_implementation = glk_implementation;
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
like these other functions: see //C Object Model// for what it does.

= (text to inform7_clib.h)
int i7_run_process(i7process_t *proc);
void i7_benign_exit(i7process_t *proc);
void i7_fatal_exit(i7process_t *proc);
void i7_initialiser(i7process_t *proc); /* part of the compiled story, not inform_clib.c */
void i7_initialise_object_tree(i7process_t *proc); /* ditto */
=

= (text to inform7_clib.c)
i7word_t i7_fn_Main(i7process_t *proc);
int i7_run_process(i7process_t *proc) {
	int tc = setjmp(proc->execution_env);
	if (tc) {
		if (tc == 2) proc->termination_code = 0; /* terminated mid-stream but benignly */
		else proc->termination_code = tc; /* terminated mid-stream with a fatal error */
    } else {
		i7_initialise_memory_and_stack(proc);
		i7_initialise_variables(proc);
		i7_empty_object_tree(proc);
		i7_initialiser(proc);
		i7_initialise_object_tree(proc);
		i7_initialise_miniglk(proc);
		i7_fn_Main(proc);
		proc->termination_code = 0; /* terminated because the program completed */
    }
    return proc->termination_code;
}

void i7_fatal_exit(i7process_t *proc) {
//  Uncomment the next line to force a crash so that the stack can be inspected in a debugger
//	int x = 0; printf("%d", 1/x);
	longjmp(proc->execution_env, 1);
}

void i7_benign_exit(i7process_t *proc) {
	longjmp(proc->execution_env, 2);
}
=
