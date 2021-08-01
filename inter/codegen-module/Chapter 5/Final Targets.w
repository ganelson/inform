[CodeGen::Targets::] Final Targets.

To create the range of possible targets into which Inter can be converted.

@h Targets.
Single, steel-cut artisanal targets are made here:

=
typedef struct code_generation_target {
	struct text_stream *target_name;
	struct method_set *methods;
	CLASS_DEFINITION
} code_generation_target;

code_generation_target *CodeGen::Targets::new(text_stream *name) {
	code_generation_target *cgt = CREATE(code_generation_target);
	cgt->target_name = Str::duplicate(name);
	cgt->methods = Methods::new_set();
	return cgt;
}

@ And they are mass-produced here:

=
int cgts_made = FALSE;

void CodeGen::Targets::make_targets(void) {
	if (cgts_made == FALSE) {
		cgts_made = TRUE;
		CodeGen::Textual::create_target();
		CodeGen::Binary::create_target();
		CodeGen::Inventory::create_target();
		CodeGen::I6::create_target();
		CodeGen::C::create_target();
	}
}

@

@e BEGIN_GENERATION_MTID

=
INT_METHOD_TYPE(BEGIN_GENERATION_MTID, code_generation_target *cgt, code_generation *gen)
int CodeGen::Targets::begin_generation(code_generation *gen) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->target, BEGIN_GENERATION_MTID, gen);
	return rv;
}

@

@e GENERAL_SEGMENT_MTID
@e DEFAULT_SEGMENT_MTID
@e BASIC_CONSTANT_SEGMENT_MTID
@e CONSTANT_SEGMENT_MTID
@e PROPERTY_SEGMENT_MTID
@e TL_SEGMENT_MTID

=
INT_METHOD_TYPE(GENERAL_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P)
INT_METHOD_TYPE(DEFAULT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
INT_METHOD_TYPE(BASIC_CONSTANT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen, int depth)
INT_METHOD_TYPE(CONSTANT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
INT_METHOD_TYPE(PROPERTY_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
INT_METHOD_TYPE(TL_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)

int CodeGen::Targets::general_segment(code_generation *gen, inter_tree_node *P) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, GENERAL_SEGMENT_MTID, gen, P);
	return rv;
}

int CodeGen::Targets::default_segment(code_generation *gen) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, DEFAULT_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::constant_segment(code_generation *gen) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, CONSTANT_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::basic_constant_segment(code_generation *gen, int depth) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, BASIC_CONSTANT_SEGMENT_MTID, gen, depth);
	return rv;
}

int CodeGen::Targets::property_segment(code_generation *gen) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, PROPERTY_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::tl_segment(code_generation *gen) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, TL_SEGMENT_MTID, gen);
	return rv;
}

@

@e COMPILE_PRIMITIVE_MTID

=
INT_METHOD_TYPE(COMPILE_PRIMITIVE_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *prim_name, inter_tree_node *P)
int CodeGen::Targets::compile_primitive(code_generation *gen, inter_symbol *prim_name, inter_tree_node *P) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->target, COMPILE_PRIMITIVE_MTID, gen, prim_name, P);
	return rv;
}

@

@e COMPILE_DICTIONARY_WORD_MTID

=
VOID_METHOD_TYPE(COMPILE_DICTIONARY_WORD_MTID, code_generation_target *cgt, code_generation *gen, text_stream *S, int pluralise)
void CodeGen::Targets::compile_dictionary_word(code_generation *gen, text_stream *S, int pluralise) {
	VOID_METHOD_CALL(gen->target, COMPILE_DICTIONARY_WORD_MTID, gen, S, pluralise);
}

@

@e COMPILE_LITERAL_NUMBER_MTID

=
VOID_METHOD_TYPE(COMPILE_LITERAL_NUMBER_MTID, code_generation_target *cgt, code_generation *gen, inter_ti val, int hex_mode)
void CodeGen::Targets::compile_literal_number(code_generation *gen, inter_ti val, int hex_mode) {
	VOID_METHOD_CALL(gen->target, COMPILE_LITERAL_NUMBER_MTID, gen, val, hex_mode);
}

@

@e COMPILE_LITERAL_TEXT_MTID

=
VOID_METHOD_TYPE(COMPILE_LITERAL_TEXT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *S, int print_mode, int box_mode)
void CodeGen::Targets::compile_literal_text(code_generation *gen, text_stream *S, int print_mode, int box_mode) {
	VOID_METHOD_CALL(gen->target, COMPILE_LITERAL_TEXT_MTID, gen, S, print_mode, box_mode);
}

@

@e DECLARE_PROPERTY_MTID

=
VOID_METHOD_TYPE(DECLARE_PROPERTY_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *prop_name, int used)
void CodeGen::Targets::declare_property(code_generation *gen, inter_symbol *prop_name, int used) {
	VOID_METHOD_CALL(gen->target, DECLARE_PROPERTY_MTID, gen, prop_name, used);
}

@

@e PREPARE_VARIABLE_MTID
@e DECLARE_VARIABLE_MTID
@e DECLARE_LOCAL_VARIABLE_MTID

=
INT_METHOD_TYPE(PREPARE_VARIABLE_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k)
INT_METHOD_TYPE(DECLARE_VARIABLE_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k, int of)
VOID_METHOD_TYPE(DECLARE_LOCAL_VARIABLE_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, inter_symbol *var_name)
int CodeGen::Targets::prepare_variable(code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, PREPARE_VARIABLE_MTID, gen, P, var_name, k);
	return rv;
}
int CodeGen::Targets::declare_variable(code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, DECLARE_VARIABLE_MTID, gen, P, var_name, k, of);
	return rv;
}
void CodeGen::Targets::declare_local_variable(code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	VOID_METHOD_CALL(gen->target, DECLARE_LOCAL_VARIABLE_MTID, gen, P, var_name);
}

@

@e OFFER_PRAGMA_MTID

=
VOID_METHOD_TYPE(OFFER_PRAGMA_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, text_stream *tag, text_stream *content)
void CodeGen::Targets::offer_pragma(code_generation *gen, inter_tree_node *P, text_stream *tag, text_stream *content) {
	VOID_METHOD_CALL(gen->target, OFFER_PRAGMA_MTID, gen, P, tag, content);
}

@

@e BEGIN_CONSTANT_MTID
@e END_CONSTANT_MTID

=
VOID_METHOD_TYPE(BEGIN_CONSTANT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *const_name, int continues)
VOID_METHOD_TYPE(END_CONSTANT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *const_name)
void CodeGen::Targets::begin_constant(code_generation *gen, text_stream *const_name, int continues) {
	VOID_METHOD_CALL(gen->target, BEGIN_CONSTANT_MTID, gen, const_name, continues);
}
void CodeGen::Targets::end_constant(code_generation *gen, text_stream *const_name) {
	VOID_METHOD_CALL(gen->target, END_CONSTANT_MTID, gen, const_name);
}

@

@e BEGIN_FUNCTION_MTID
@e BEGIN_FUNCTION_CODE_MTID
@e END_FUNCTION_MTID

=
VOID_METHOD_TYPE(BEGIN_FUNCTION_MTID, code_generation_target *cgt, code_generation *gen, text_stream *fn_name)
VOID_METHOD_TYPE(BEGIN_FUNCTION_CODE_MTID, code_generation_target *cgt, code_generation *gen)
VOID_METHOD_TYPE(END_FUNCTION_MTID, code_generation_target *cgt, code_generation *gen)
void CodeGen::Targets::begin_function(code_generation *gen, text_stream *fn_name) {
	VOID_METHOD_CALL(gen->target, BEGIN_FUNCTION_MTID, gen, fn_name);
}
void CodeGen::Targets::begin_function_code(code_generation *gen) {
	VOID_METHOD_CALL(gen->target, BEGIN_FUNCTION_CODE_MTID, gen);
}
void CodeGen::Targets::end_function(code_generation *gen) {
	VOID_METHOD_CALL(gen->target, END_FUNCTION_MTID, gen);
}

@

@e BEGIN_ARRAY_MTID
@e ARRAY_ENTRY_MTID
@e END_ARRAY_MTID

@d WORD_ARRAY_FORMAT 1
@d BYTE_ARRAY_FORMAT 2
@d TABLE_ARRAY_FORMAT 3
@d BUFFER_ARRAY_FORMAT 4

=
VOID_METHOD_TYPE(BEGIN_ARRAY_MTID, code_generation_target *cgt, code_generation *gen, text_stream *const_name, int format)
VOID_METHOD_TYPE(ARRAY_ENTRY_MTID, code_generation_target *cgt, code_generation *gen, text_stream *entry, int format)
VOID_METHOD_TYPE(END_ARRAY_MTID, code_generation_target *cgt, code_generation *gen, int format)
void CodeGen::Targets::begin_array(code_generation *gen, text_stream *const_name, int format) {
	VOID_METHOD_CALL(gen->target, BEGIN_ARRAY_MTID, gen, const_name, format);
}
void CodeGen::Targets::array_entry(code_generation *gen, text_stream *entry, int format) {
	VOID_METHOD_CALL(gen->target, ARRAY_ENTRY_MTID, gen, entry, format);
}
void CodeGen::Targets::end_array(code_generation *gen, int format) {
	VOID_METHOD_CALL(gen->target, END_ARRAY_MTID, gen, format);
}
