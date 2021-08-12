[CTarget::] Generating C.

To generate I6 code from intermediate code.

@h Target.

=
code_generation_target *c_target = NULL;
void CTarget::create_target(void) {
	c_target = CodeGen::Targets::new(I"c");

	METHOD_ADD(c_target, BEGIN_GENERATION_MTID, CTarget::begin_generation);
	METHOD_ADD(c_target, END_GENERATION_MTID, CTarget::end_generation);

	CNamespace::initialise(c_target);
	CMemoryModel::initialise(c_target);
	CObjectModel::initialise(c_target);
	CLiteralsModel::initialise(c_target);
	CAssembly::initialise(c_target);

	METHOD_ADD(c_target, GENERAL_SEGMENT_MTID, CTarget::general_segment);
	METHOD_ADD(c_target, TL_SEGMENT_MTID, CTarget::tl_segment);
	METHOD_ADD(c_target, DEFAULT_SEGMENT_MTID, CTarget::default_segment);
	METHOD_ADD(c_target, BASIC_CONSTANT_SEGMENT_MTID, CTarget::basic_constant_segment);
	METHOD_ADD(c_target, CONSTANT_SEGMENT_MTID, CTarget::constant_segment);
	METHOD_ADD(c_target, PROPERTY_SEGMENT_MTID, CTarget::property_segment);
	METHOD_ADD(c_target, COMPILE_PRIMITIVE_MTID, CTarget::compile_primitive);
	METHOD_ADD(c_target, PREPARE_VARIABLE_MTID, CTarget::prepare_variable);
	METHOD_ADD(c_target, DECLARE_VARIABLE_MTID, CTarget::declare_variable);
	METHOD_ADD(c_target, DECLARE_LOCAL_VARIABLE_MTID, CTarget::declare_local_variable);
	METHOD_ADD(c_target, BEGIN_CONSTANT_MTID, CTarget::begin_constant);
	METHOD_ADD(c_target, END_CONSTANT_MTID, CTarget::end_constant);
	METHOD_ADD(c_target, BEGIN_FUNCTION_MTID, CTarget::begin_function);
	METHOD_ADD(c_target, BEGIN_FUNCTION_CODE_MTID, CTarget::begin_function_code);
	METHOD_ADD(c_target, PLACE_LABEL_MTID, CTarget::place_label);
	METHOD_ADD(c_target, END_FUNCTION_MTID, CTarget::end_function);
	METHOD_ADD(c_target, BEGIN_FUNCTION_CALL_MTID, CTarget::begin_function_call);
	METHOD_ADD(c_target, ARGUMENT_MTID, CTarget::argument);
	METHOD_ADD(c_target, END_FUNCTION_CALL_MTID, CTarget::end_function_call);
	METHOD_ADD(c_target, NEW_FAKE_ACTION_MTID, CTarget::new_fake_action);
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
	int C_action_count;
	struct C_generation_memory_model_data memdata;
	struct C_generation_object_model_data objdata;
	struct C_generation_literals_model_data litdata;
	struct C_generation_assembly_data asmdata;
	CLASS_DEFINITION
} C_generation_data;

void CTarget::initialise_data(code_generation *gen) {
	CMemoryModel::initialise_data(gen);
	CObjectModel::initialise_data(gen);
	CLiteralsModel::initialise_data(gen);
	CAssembly::initialise_data(gen);
	C_GEN_DATA(C_action_count) = 0;
}

@h Begin and end.

=
int CTarget::begin_generation(code_generation_target *cgt, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(C_generation_data), C_target_segments);
	CTarget::initialise_data(gen);

	CNamespace::fix_locals(gen);

	generated_segment *saved = CodeGen::select(gen, c_fundamental_types_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("typedef int i7val;\n");
	WRITE("typedef unsigned char i7byte;\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_header_matter_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.h\"\n");
	CodeGen::deselect(gen, saved);

	CMemoryModel::begin(gen);
	CTarget::begin_functions(gen);
	CObjectModel::begin(gen);
	CLiteralsModel::begin(gen);
	CAssembly::begin(gen);

	return FALSE;
}

int CTarget::end_generation(code_generation_target *cgt, code_generation *gen) {
	CMemoryModel::end(gen);
	CTarget::end_functions(gen);
	CObjectModel::end(gen);
	CLiteralsModel::end(gen);
	CAssembly::end(gen);

	return FALSE;
}
