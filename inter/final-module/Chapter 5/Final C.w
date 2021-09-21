[CTarget::] Final C.

Managing, or really just delegating, the generation of ANSI C code from a tree of Inter.

@h Target.

=
code_generation_target *c_target = NULL;
void CTarget::create_target(void) {
	c_target = CodeGen::Targets::new(I"c");

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

	METHOD_ADD(c_target, GENERAL_SEGMENT_MTID, CTarget::general_segment);
	METHOD_ADD(c_target, TL_SEGMENT_MTID, CTarget::tl_segment);
	METHOD_ADD(c_target, DEFAULT_SEGMENT_MTID, CTarget::default_segment);
	METHOD_ADD(c_target, BASIC_CONSTANT_SEGMENT_MTID, CTarget::basic_constant_segment);
	METHOD_ADD(c_target, CONSTANT_SEGMENT_MTID, CTarget::constant_segment);
}

@h Static supporting code.
The C code generated here would not compile as a stand-alone file. It needs
to use variables and functions from a small unchanging library called 
|inform7_clib.h|. (The |.h| there is questionable, since this is not purely
a header file: it contains actual content and not only predeclarations. On
the other hand, it serves the same basic purpose.)

The code we generate here can only make sense if read alongside |inform7_clib.h|,
and vice versa, so the file is presented here in installments. This is the
first of those:

= (text to inform7_clib.h)
/* This is a library of C code to support Inform or other Inter programs compiled
   tp ANSI C. It was generated mechanically from the Inter source code, so to
   change it, edit that and not this. */

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

typedef int32_t i7word_t;
typedef uint32_t i7uval;
typedef unsigned char i7byte_t;

#define I7_ASM_STACK_CAPACITY 128

typedef struct i7state {
	i7byte_t *memory;
	i7word_t himem;
	i7word_t stack[I7_ASM_STACK_CAPACITY];
	int stack_pointer;
	i7word_t *i7_object_tree_parent;
	i7word_t *i7_object_tree_child;
	i7word_t *i7_object_tree_sibling;
	i7word_t *variables;
	i7word_t tmp;
	i7word_t i7_str_id;
} i7state;

typedef struct i7snapshot {
	int valid;
	struct i7state then;
	jmp_buf env;
} i7snapshot;

#define I7_MAX_SNAPSHOTS 10

typedef struct i7process_t {
	i7state state;
	i7snapshot snapshots[I7_MAX_SNAPSHOTS];
	int snapshot_pos;
	jmp_buf execution_env;
	int termination_code;
	int just_undid;
	void (*receiver)(int id, wchar_t c, char *style);
	int send_count;
	char *(*sender)(int count);
	i7word_t (*communicator)(struct i7process_t *proc, char *id, int argc, i7word_t *args);
	int use_UTF8;
} i7process_t;

i7state i7_new_state(void);
i7process_t i7_new_process(void);
i7snapshot i7_new_snapshot(void);
void i7_save_snapshot(i7process_t *proc);
int i7_has_snapshot(i7process_t *proc);
void i7_restore_snapshot(i7process_t *proc);
void i7_restore_snapshot_from(i7process_t *proc, i7snapshot *ss);
void i7_destroy_latest_snapshot(i7process_t *proc);
int i7_run_process(i7process_t *proc);
void i7_set_process_receiver(i7process_t *proc, void (*receiver)(int id, wchar_t c, char *style), int UTF8);
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count));
void i7_set_process_communicator(i7process_t *proc, i7word_t (*communicator)(i7process_t *proc, char *id, int argc, i7word_t *args));
void i7_initializer(i7process_t *proc);
void i7_fatal_exit(i7process_t *proc);
void i7_destroy_state(i7process_t *proc, i7state *s);
void i7_destroy_snapshot(i7process_t *proc, i7snapshot *old);
char *i7_default_sender(int count);
void i7_default_receiver(int id, wchar_t c, char *style);
i7word_t i7_default_communicator(i7process_t *proc, char *id, int argc, i7word_t *args);
int default_main(int argc, char **argv);
=

= (text to inform7_clib.c)
#ifndef I7_CLIB_C_INCLUDED
#define I7_CLIB_C_INCLUDED 1

i7state i7_new_state(void) {
	i7state S;
	S.memory = NULL;
	S.himem = 0;
	S.tmp = 0;
	S.stack_pointer = 0;
	S.i7_object_tree_parent = NULL;
	S.i7_object_tree_child = NULL;
	S.i7_object_tree_sibling = NULL;
	S.variables = NULL;
	return S;
}

void i7_copy_state(i7process_t *proc, i7state *to, i7state *from) {
	to->himem = from->himem;
	to->memory = calloc(i7_static_himem, sizeof(i7byte_t));
	if (to->memory == NULL) { 
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_static_himem; i++) to->memory[i] = from->memory[i];
	to->tmp = from->tmp;
	to->stack_pointer = from->stack_pointer;
	for (int i=0; i<from->stack_pointer; i++) to->stack[i] = from->stack[i];
	to->i7_object_tree_parent  = calloc(i7_max_objects, sizeof(i7word_t));
	to->i7_object_tree_child   = calloc(i7_max_objects, sizeof(i7word_t));
	to->i7_object_tree_sibling = calloc(i7_max_objects, sizeof(i7word_t));
	
	if ((to->i7_object_tree_parent == NULL) ||
		(to->i7_object_tree_child == NULL) ||
		(to->i7_object_tree_sibling == NULL)) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_max_objects; i++) {
		to->i7_object_tree_parent[i] = from->i7_object_tree_parent[i];
		to->i7_object_tree_child[i] = from->i7_object_tree_child[i];
		to->i7_object_tree_sibling[i] = from->i7_object_tree_sibling[i];
	}
	to->variables = calloc(i7_no_variables, sizeof(i7word_t));
	if (to->variables == NULL) { 
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_no_variables; i++)
		to->variables[i] = from->variables[i];
}

void i7_destroy_state(i7process_t *proc, i7state *s) {
	free(s->memory);
	s->himem = 0;
	free(s->i7_object_tree_parent);
	free(s->i7_object_tree_child);
	free(s->i7_object_tree_sibling);
	s->stack_pointer = 0;
	free(s->variables);
}

void i7_destroy_snapshot(i7process_t *proc, i7snapshot *old) {
	i7_destroy_state(proc, &(old->then));
	old->valid = 0;
}

i7snapshot i7_new_snapshot(void) {
	i7snapshot SS;
	SS.valid = 0;
	SS.then = i7_new_state();
	return SS;
}

i7process_t i7_new_process(void) {
	i7process_t proc;
	proc.state = i7_new_state();
	for (int i=0; i<I7_MAX_SNAPSHOTS; i++) proc.snapshots[i] = i7_new_snapshot();
	proc.just_undid = 0;
	proc.snapshot_pos = 0;
	proc.receiver = i7_default_receiver;
	proc.send_count = 0;
	proc.sender = i7_default_sender;
	proc.use_UTF8 = 1;
	proc.communicator = i7_default_communicator;
	return proc;
}

i7word_t i7_default_communicator(i7process_t *proc, char *id, int argc, i7word_t *args) {
	printf("No communicator: external function calls not allowed from thus process\n");
	i7_fatal_exit(proc);
	return 0;
}

void i7_save_snapshot(i7process_t *proc) {
	if (proc->snapshots[proc->snapshot_pos].valid)
		i7_destroy_snapshot(proc, &(proc->snapshots[proc->snapshot_pos]));
	proc->snapshots[proc->snapshot_pos] = i7_new_snapshot();
	proc->snapshots[proc->snapshot_pos].valid = 1;
	i7_copy_state(proc, &(proc->snapshots[proc->snapshot_pos].then), &(proc->state));
	int was = proc->snapshot_pos;
	proc->snapshot_pos++;
	if (proc->snapshot_pos == I7_MAX_SNAPSHOTS) proc->snapshot_pos = 0;
//	if (setjmp(proc->snapshots[was].env)) fprintf(stdout, "*** Restore! %d ***\n", proc->just_undid);
}

int i7_has_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	return proc->snapshots[will_be].valid;
}

void i7_destroy_latest_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid)
		i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	proc->snapshot_pos = will_be;
}

void i7_restore_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid == 0) {
		printf("Restore impossible\n");
		i7_fatal_exit(proc);
	}
	i7_restore_snapshot_from(proc, &(proc->snapshots[will_be]));
	i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	int was = proc->snapshot_pos;
	proc->snapshot_pos = will_be;
//	longjmp(proc->snapshots[was].env, 1);
}

void i7_restore_snapshot_from(i7process_t *proc, i7snapshot *ss) {
	i7_destroy_state(proc, &(proc->state));
	i7_copy_state(proc, &(proc->state), &(ss->then));
}

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

int default_main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_run_process(&proc);
	if (proc.termination_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return proc.termination_code;
}

i7word_t fn_i7_mgl_Main(i7process_t *proc);
int i7_run_process(i7process_t *proc) {
	int tc = setjmp(proc->execution_env);
	if (tc) {
		if (tc == 2) tc = 0;
		proc->termination_code = tc; /* terminated abnormally */
    } else {
		i7_initialise_state(proc);
		i7_initializer(proc);
		i7_initialise_streams(proc);
		fn_i7_mgl_Main(proc);
		proc->termination_code = 0; /* terminated normally */
    }
    return proc->termination_code;
}
void i7_set_process_receiver(i7process_t *proc, void (*receiver)(int id, wchar_t c, char *style), int UTF8) {
	proc->receiver = receiver;
	proc->use_UTF8 = UTF8;
}
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count)) {
	proc->sender = sender;
}
void i7_set_process_communicator(i7process_t *proc, i7word_t (*communicator)(i7process_t *proc, char *id, int argc, i7word_t *args)) {
	proc->communicator = communicator;
}

void i7_fatal_exit(i7process_t *proc) {
//	int x = 0; printf("%d", 1/x);
	longjmp(proc->execution_env, 1);
}

void i7_benign_exit(i7process_t *proc) {
	longjmp(proc->execution_env, 2);
}
=

@h Segmentation.

@e c_header_inclusion_I7CGS
@e c_ids_and_maxima_I7CGS
@e c_library_inclusion_I7CGS
@e c_predeclarations_I7CGS
@e c_very_early_matter_I7CGS
@e c_constants_1_I7CGS
@e c_constants_2_I7CGS
@e c_constants_3_I7CGS
@e c_constants_4_I7CGS
@e c_constants_5_I7CGS
@e c_constants_6_I7CGS
@e c_constants_7_I7CGS
@e c_constants_8_I7CGS
@e c_constants_9_I7CGS
@e c_constants_10_I7CGS
@e c_early_matter_I7CGS
@e c_text_literals_code_I7CGS
@e c_summations_at_eof_I7CGS
@e c_arrays_at_eof_I7CGS
@e c_main_matter_I7CGS
@e c_functions_at_eof_I7CGS
@e c_code_at_eof_I7CGS
@e c_verbs_at_eof_I7CGS
@e c_stubs_at_eof_I7CGS
@e c_property_offset_creator_I7CGS
@e c_mem_I7CGS
@e c_globals_array_I7CGS
@e c_initialiser_I7CGS

@e c_instances_symbols_I7CGS
@e c_enum_symbols_I7CGS
@e c_kinds_symbols_I7CGS
@e c_actions_symbols_I7CGS
@e c_property_symbols_I7CGS
@e c_variable_symbols_I7CGS
@e c_function_symbols_I7CGS

=
int C_target_segments[] = {
	c_header_inclusion_I7CGS,
	c_ids_and_maxima_I7CGS,
	c_library_inclusion_I7CGS,
	c_predeclarations_I7CGS,
	c_very_early_matter_I7CGS,
	c_constants_1_I7CGS,
	c_constants_2_I7CGS,
	c_constants_3_I7CGS,
	c_constants_4_I7CGS,
	c_constants_5_I7CGS,
	c_constants_6_I7CGS,
	c_constants_7_I7CGS,
	c_constants_8_I7CGS,
	c_constants_9_I7CGS,
	c_constants_10_I7CGS,
	c_early_matter_I7CGS,
	c_text_literals_code_I7CGS,
	c_summations_at_eof_I7CGS,
	c_arrays_at_eof_I7CGS,
	c_main_matter_I7CGS,
	c_functions_at_eof_I7CGS,
	c_code_at_eof_I7CGS,
	c_verbs_at_eof_I7CGS,
	c_stubs_at_eof_I7CGS,
	c_property_offset_creator_I7CGS,
	c_mem_I7CGS,
	c_globals_array_I7CGS,
	c_initialiser_I7CGS,
	-1
};

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

@h State data.

@d C_GEN_DATA(x) ((C_generation_data *) (gen->target_specific_data))->x

=
typedef struct C_generation_data {
	struct C_generation_memory_model_data memdata;
	struct C_generation_function_model_data fndata;
	struct C_generation_object_model_data objdata;
	struct C_generation_literals_model_data litdata;
	CLASS_DEFINITION
} C_generation_data;

void CTarget::initialise_data(code_generation *gen) {
	CMemoryModel::initialise_data(gen);
	CFunctionModel::initialise_data(gen);
	CObjectModel::initialise_data(gen);
	CLiteralsModel::initialise_data(gen);
	CGlobals::initialise_data(gen);
	CAssembly::initialise_data(gen);
	CInputOutputModel::initialise_data(gen);
}

@h Begin and end.

=
int CTarget::begin_generation(code_generation_target *cgt, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(C_generation_data), C_target_segments);
	CodeGen::additional_segments(gen, C_symbols_header_segments);
	CTarget::initialise_data(gen);

	CNamespace::fix_locals(gen);

	generated_segment *saved = CodeGen::select(gen, c_header_inclusion_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	int compile_main = TRUE;
	target_vm *VM = gen->for_VM;
	linked_list *opts = TargetVMs::option_list(VM);
	text_stream *opt;
	LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
		if (Str::eq_insensitive(opt, I"main")) compile_main = TRUE;
		else if (Str::eq_insensitive(opt, I"no-main")) compile_main = FALSE;
		else if (Str::eq_insensitive(opt, I"symbols-header")) ;
		else if (Str::eq_insensitive(opt, I"no-symbols-header")) ;
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
	if (Architectures::debug_enabled(TargetVMs::get_architecture(VM)))
		WRITE("#define DEBUG\n");
	WRITE("#include \"inform7_clib.h\"\n");
	if (compile_main)
		WRITE("int main(int argc, char **argv) { return default_main(argc, argv); }\n");
	WRITE("#pragma clang diagnostic push\n");
	WRITE("#pragma clang diagnostic ignored \"-Wunused-value\"\n");
	WRITE("#pragma clang diagnostic ignored \"-Wparentheses-equality\"\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_library_inclusion_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.c\"\n");
	CodeGen::deselect(gen, saved);

	CMemoryModel::begin(gen);
	CFunctionModel::begin(gen);
	CObjectModel::begin(gen);
	CLiteralsModel::begin(gen);
	CGlobals::begin(gen);
	CAssembly::begin(gen);
	CInputOutputModel::begin(gen);

	return FALSE;
}

int CTarget::end_generation(code_generation_target *cgt, code_generation *gen) {
	CFunctionModel::end(gen);
	CObjectModel::end(gen);
	CLiteralsModel::end(gen);
	CGlobals::end(gen);
	CAssembly::end(gen);
	CInputOutputModel::end(gen);
	CMemoryModel::end(gen); /* must be last to end */

	generated_segment *saved = CodeGen::select(gen, c_initialiser_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#pragma clang diagnostic pop\n");
	CodeGen::deselect(gen, saved);

	filename *F = gen->to_file;
	if (F) {
		int compile_symbols = FALSE;
		target_vm *VM = gen->for_VM;
		linked_list *opts = TargetVMs::option_list(VM);
		text_stream *opt;
		LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
			if (Str::eq_insensitive(opt, I"symbols-header")) compile_symbols = TRUE;
			if (Str::eq_insensitive(opt, I"no-symbols-header")) compile_symbols = FALSE;
		}
		if (compile_symbols) {
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
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_instances_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (2) Values of enumerated kinds */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_enum_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (3) Kind IDs */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_kinds_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (4) Action IDs */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_actions_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (5) Property IDs */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_property_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (6) Variable IDs */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_variable_symbols_I7CGS));
			WRITE_TO(&HF, "\n/* (7) Function IDs */\n\n");
			WRITE_TO(&HF, "%S", CodeGen::content(gen, c_function_symbols_I7CGS));
			STREAM_CLOSE(&HF);
		}
	}
	
	return FALSE;
}

int CTarget::general_segment(code_generation_target *cgt, code_generation *gen, inter_tree_node *P) {
	switch (P->W.data[ID_IFLD]) {
		case CONSTANT_IST: {
			inter_symbol *con_name =
				InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			int choice = c_early_matter_I7CGS;
			if (Str::eq(con_name->symbol_name, I"DynamicMemoryAllocation")) choice = c_very_early_matter_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, LATE_IANN) == 1) choice = c_code_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) choice = c_arrays_at_eof_I7CGS;
			if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) choice = c_arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) choice = c_verbs_at_eof_I7CGS;
			if (Inter::Constant::is_routine(con_name)) choice = c_functions_at_eof_I7CGS;
			return choice;
		}
	}
	return CTarget::default_segment(cgt);
}

int CTarget::default_segment(code_generation_target *cgt) {
	return c_main_matter_I7CGS;
}
int CTarget::constant_segment(code_generation_target *cgt, code_generation *gen) {
	return c_early_matter_I7CGS;
}
int CTarget::basic_constant_segment(code_generation_target *cgt, code_generation *gen, inter_symbol *con_name, int depth) {
	if (Str::eq(CodeGen::CL::name(con_name), I"Release")) return c_ids_and_maxima_I7CGS;
	if (Str::eq(CodeGen::CL::name(con_name), I"Serial")) return c_ids_and_maxima_I7CGS;
	if (depth >= 10) depth = 10;
	return c_constants_1_I7CGS + depth - 1;
}
int CTarget::tl_segment(code_generation_target *cgt) {
	return c_text_literals_code_I7CGS;
}
