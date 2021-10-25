[CTarget::] Final C.

To generate ANSI C-99 code from intermediate code.

@h Target.
This generator produces C source code, using the Vanilla algorithm.

=
code_generator *c_target = NULL;
void CTarget::create_generator(void) {
	c_target = Generators::new(I"c");

	METHOD_ADD(c_target, BEGIN_GENERATION_MTID, CTarget::begin_generation);
	METHOD_ADD(c_target, END_GENERATION_MTID, CTarget::end_generation);

	CProgramControl::initialise(c_target);
	CNamespace::initialise(c_target);
	CMemoryModel::initialise(c_target);
	CFunctionModel::initialise(c_target);
	CObjectModel::initialise(c_target);
	CLiteralsModel::initialise(c_target);
	CGlobals::initialise(c_target);
	CAssembly::initialise(c_target);
	CInputOutputModel::initialise(c_target);
}

@h Segmentation.
This generator produces two files: a primary one implementing the Inter program
in C, and a secondary header file defining certain constants so that external
code can interface with it. Both are divided into segments. The main file thus:

@e c_header_inclusion_I7CGS
@e c_ids_and_maxima_I7CGS
@e c_library_inclusion_I7CGS
@e c_predeclarations_I7CGS
@e c_very_early_matter_I7CGS
@e c_constants_I7CGS
@e c_early_matter_I7CGS
@e c_text_literals_code_I7CGS
@e c_summations_at_eof_I7CGS
@e c_arrays_I7CGS
@e c_main_matter_I7CGS
@e c_functions_at_eof_I7CGS
@e c_code_at_eof_I7CGS
@e c_verb_arrays_I7CGS
@e c_stubs_at_eof_I7CGS
@e c_property_offset_creator_I7CGS
@e c_mem_I7CGS
@e c_globals_array_I7CGS
@e c_initialiser_I7CGS

=
int C_target_segments[] = {
	c_header_inclusion_I7CGS,
	c_ids_and_maxima_I7CGS,
	c_library_inclusion_I7CGS,
	c_predeclarations_I7CGS,
	c_very_early_matter_I7CGS,
	c_constants_I7CGS,
	c_early_matter_I7CGS,
	c_text_literals_code_I7CGS,
	c_summations_at_eof_I7CGS,
	c_arrays_I7CGS,
	c_main_matter_I7CGS,
	c_functions_at_eof_I7CGS,
	c_code_at_eof_I7CGS,
	c_verb_arrays_I7CGS,
	c_stubs_at_eof_I7CGS,
	c_property_offset_creator_I7CGS,
	c_mem_I7CGS,
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
int CTarget::begin_generation(code_generator *cgt, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(C_generation_data), C_target_segments);
	CodeGen::additional_segments(gen, C_symbols_header_segments);
	CTarget::initialise_data(gen);

	@<Parse the C compilation options@>;
	@<Compile the Clib header inclusion and some clang pragmas@>;
	@<Compile the Clib code inclusion@>;

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

@ =
int CTarget::end_generation(code_generator *cgt, code_generation *gen) {
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

@ Now we need three fundamental types. |i7word_t| is a type which can hold any
Inter word value: since we do not support C for 16-bit Inter code, we can
safely make this a 32-bit integer. |unsigned_i7word_t| will be used very little,
but is an unsigned version of the same. (It must be the case that an |i7word_t|
can survive being cast to |unsigned_i7word_t| and back again intact.) Lastly,
|i7byte_t| holds an Inter byte value, and must be unsigned.

= (text to inform7_clib.h)
typedef int32_t i7word_t;
typedef uint32_t unsigned_i7word_t;
typedef unsigned char i7byte_t;
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

typedef struct i7state_t {
	i7byte_t *memory;
	i7word_t himem;
	i7word_t stack[I7_ASM_STACK_CAPACITY];
	int stack_pointer;
	i7word_t *object_tree_parent;
	i7word_t *object_tree_child;
	i7word_t *object_tree_sibling;
	i7word_t *variables;
	i7word_t tmp;
	i7word_t current_output_stream_ID;
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
	i7word_t (*communicator)(struct i7process_t *proc, char *id, int argc, i7word_t *args);
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
	S.tmp = 0;
	S.stack_pointer = 0;
	S.object_tree_parent = NULL; S.object_tree_child = NULL; S.object_tree_sibling = NULL;
	S.variables = NULL;
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
	proc.use_UTF8 = 1;
	return proc;
}
=

@ The |i7_new_process| function refers to two default functions attached to
a new process, so we must define those:

= (text to inform7_clib.h)
char *i7_default_sender(int count);
void i7_default_receiver(int id, wchar_t c, char *style);
i7word_t i7_default_communicator(i7process_t *proc, char *id, int argc, i7word_t *args);
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

In all cases, execution is kicked off when |i7_run_process| is called on a process.
Ordinarily, that will execute the entire Inform 7 program and then come back to us;
but we need to cope with a sudden halt during execution, either through a fatal
error or through a use of the |@quit| opcode.

We do that with the |setjmp| and |longjmp| mechanism of C. This is a very limited
sort of exception-handling will a well deserved reputation for crankiness, and we
will use it with due caution. It is essential that the underlying |jmp_buf| data
not move in memory for any reason between the setting and the jumping. (This is
why there is no mechanism to copy or fork an |i7_process_t|.)

Note that the |i7_initializer| function is compiled and is not pre-written
like these other functions: see //C Object Model// for what it does.

= (text to inform7_clib.h)
int i7_run_process(i7process_t *proc);
void i7_benign_exit(i7process_t *proc);
void i7_fatal_exit(i7process_t *proc);
void i7_initializer(i7process_t *proc); /* part of the compiled story, not inform_clib.c */
=

= (text to inform7_clib.c)
i7word_t fn_i7_mgl_Main(i7process_t *proc);
int i7_run_process(i7process_t *proc) {
	int tc = setjmp(proc->execution_env);
	if (tc) {
		if (tc == 2) proc->termination_code = 0; /* terminated mid-stream but benignly */
		else proc->termination_code = tc; /* terminated mid-stream with a fatal error */
    } else {
		i7_initialise_memory_and_stack(proc);
		i7_initialise_variables(proc);
		i7_initialise_object_tree(proc);
		i7_initializer(proc);
		i7_initialise_streams(proc);
		fn_i7_mgl_Main(proc);
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
