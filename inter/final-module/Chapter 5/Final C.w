[CTarget::] Generating C.

To generate I6 code from intermediate code.

@h Target,

=
code_generation_target *c_target = NULL;
void CTarget::create_target(void) {
	c_target = CodeGen::Targets::new(I"c");

	METHOD_ADD(c_target, BEGIN_GENERATION_MTID, CTarget::begin_generation);
	METHOD_ADD(c_target, END_GENERATION_MTID, CTarget::end_generation);

	CObjectModel::initialise(c_target);

	METHOD_ADD(c_target, GENERAL_SEGMENT_MTID, CTarget::general_segment);
	METHOD_ADD(c_target, TL_SEGMENT_MTID, CTarget::tl_segment);
	METHOD_ADD(c_target, DEFAULT_SEGMENT_MTID, CTarget::default_segment);
	METHOD_ADD(c_target, BASIC_CONSTANT_SEGMENT_MTID, CTarget::basic_constant_segment);
	METHOD_ADD(c_target, CONSTANT_SEGMENT_MTID, CTarget::constant_segment);
	METHOD_ADD(c_target, PROPERTY_SEGMENT_MTID, CTarget::property_segment);
	METHOD_ADD(c_target, MANGLE_IDENTIFIER_MTID, CTarget::mangle);
	METHOD_ADD(c_target, COMPILE_PRIMITIVE_MTID, CTarget::compile_primitive);
	METHOD_ADD(c_target, COMPILE_DICTIONARY_WORD_MTID, CTarget::compile_dictionary_word);
	METHOD_ADD(c_target, COMPILE_LITERAL_NUMBER_MTID, CTarget::compile_literal_number);
	METHOD_ADD(c_target, COMPILE_LITERAL_TEXT_MTID, CTarget::compile_literal_text);
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
	METHOD_ADD(c_target, BEGIN_OPCODE_MTID, CTarget::begin_opcode);
	METHOD_ADD(c_target, SUPPLY_OPERAND_MTID, CTarget::supply_operand);
	METHOD_ADD(c_target, END_OPCODE_MTID, CTarget::end_opcode);
	METHOD_ADD(c_target, BEGIN_ARRAY_MTID, CTarget::begin_array);
	METHOD_ADD(c_target, ARRAY_ENTRY_MTID, CTarget::array_entry);
	METHOD_ADD(c_target, END_ARRAY_MTID, CTarget::end_array);
	METHOD_ADD(c_target, OFFER_PRAGMA_MTID, CTarget::offer_pragma)
	METHOD_ADD(c_target, NEW_FAKE_ACTION_MTID, CTarget::new_fake_action);
}

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
	text_stream *double_quoted_C;
	int no_double_quoted_C_strings;
	int extent_of_i7mem;
	int C_dword_count;
	int C_action_count;
	struct dictionary *C_vm_dictionary;
	struct C_generation_object_model_data objdata;
	CLASS_DEFINITION
} C_generation_data;

void CTarget::initialise_data(code_generation *gen) {
	CObjectModel::initialise_data(gen);
	C_GEN_DATA(double_quoted_C) = Str::new();
	C_GEN_DATA(no_double_quoted_C_strings) = 0;
	C_GEN_DATA(extent_of_i7mem) = 0;
	C_GEN_DATA(C_dword_count) = 0;
	C_GEN_DATA(C_action_count) = 0;
	C_GEN_DATA(C_vm_dictionary) = Dictionaries::new(1024, TRUE);
}

@h Begin and end.

=
int CTarget::begin_generation(code_generation_target *cgt, code_generation *gen) {
	CodeGen::create_segments(gen, CREATE(C_generation_data), C_target_segments);
	CTarget::initialise_data(gen);

	CTarget::fix_locals(gen);

	generated_segment *saved = CodeGen::select(gen, c_fundamental_types_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("typedef int i7val;\n");
	WRITE("typedef unsigned char i7byte;\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_header_matter_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#include \"inform7_clib.h\"\n");
	CodeGen::deselect(gen, saved);

	CTarget::begin_memory(gen);
	CTarget::begin_functions(gen);
	CObjectModel::begin(gen);
	CTarget::begin_dictionary_words(gen);

	return FALSE;
}

int CTarget::end_generation(code_generation_target *cgt, code_generation *gen) {
	CTarget::end_memory(gen);
	CTarget::end_functions(gen);
	CObjectModel::end(gen);
	CTarget::end_dictionary_words(gen);

	return FALSE;
}
