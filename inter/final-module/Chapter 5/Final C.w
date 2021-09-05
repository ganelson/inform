[CTarget::] Generating C.

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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <ctype.h>

int begin_execution(void (*receiver)(int id, wchar_t c));

#ifndef I7_NO_MAIN
void default_receiver(int id, wchar_t c) {
	if (id == 201) fputc(c, stdout);
}

int main(int argc, char **argv) {
	return begin_execution(default_receiver);
}
#endif

void i7_fatal_exit(void) {
	printf("*** Fatal error: halted ***\n");
	fflush(stdout); fflush(stderr);
	int x = 0; printf("%d", 1/x);
	exit(1);
}

i7val i7_tmp = 0;
=

@h Segmentation.

@e c_fundamental_types_I7CGS
@e c_ids_and_maxima_I7CGS
@e c_header_matter_I7CGS
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
@e c_globals_array_I7CGS
@e c_main_matter_I7CGS
@e c_functions_at_eof_I7CGS
@e c_code_at_eof_I7CGS
@e c_verbs_at_eof_I7CGS
@e c_stubs_at_eof_I7CGS
@e c_property_offset_creator_I7CGS
@e c_mem_I7CGS
@e c_initialiser_I7CGS

=
int C_target_segments[] = {
	c_fundamental_types_I7CGS,
	c_ids_and_maxima_I7CGS,
	c_header_matter_I7CGS,
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
	c_globals_array_I7CGS,
	c_main_matter_I7CGS,
	c_functions_at_eof_I7CGS,
	c_code_at_eof_I7CGS,
	c_verbs_at_eof_I7CGS,
	c_stubs_at_eof_I7CGS,
	c_property_offset_creator_I7CGS,
	c_mem_I7CGS,
	c_initialiser_I7CGS,
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
	CTarget::initialise_data(gen);

	CNamespace::fix_locals(gen);

	generated_segment *saved = CodeGen::select(gen, c_fundamental_types_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#include <stdint.h>\n");
	WRITE("typedef int32_t i7val;\n");
	WRITE("typedef uint32_t i7uval;\n");
	WRITE("typedef unsigned char i7byte;\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_header_matter_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.h\"\n");
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
int CTarget::basic_constant_segment(code_generation_target *cgt, code_generation *gen, int depth) {
	if (depth >= 10) depth = 10;
	return c_constants_1_I7CGS + depth - 1;
}
int CTarget::tl_segment(code_generation_target *cgt) {
	return c_text_literals_code_I7CGS;
}
