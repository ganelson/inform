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
		CTarget::create_target();
	}
}

@

@e BEGIN_GENERATION_MTID
@e END_GENERATION_MTID

=
INT_METHOD_TYPE(BEGIN_GENERATION_MTID, code_generation_target *cgt, code_generation *gen)
INT_METHOD_TYPE(END_GENERATION_MTID, code_generation_target *cgt, code_generation *gen)
int CodeGen::Targets::begin_generation(code_generation *gen) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->target, BEGIN_GENERATION_MTID, gen);
	return rv;
}
int CodeGen::Targets::end_generation(code_generation *gen) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->target, END_GENERATION_MTID, gen);
	return rv;
}

@

@e GENERAL_SEGMENT_MTID
@e DEFAULT_SEGMENT_MTID
@e BASIC_CONSTANT_SEGMENT_MTID
@e CONSTANT_SEGMENT_MTID
@e TL_SEGMENT_MTID

=
INT_METHOD_TYPE(GENERAL_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P)
INT_METHOD_TYPE(DEFAULT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
INT_METHOD_TYPE(BASIC_CONSTANT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen, int depth)
INT_METHOD_TYPE(CONSTANT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
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

int CodeGen::Targets::tl_segment(code_generation *gen) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->target, TL_SEGMENT_MTID, gen);
	return rv;
}

@

@e MANGLE_IDENTIFIER_MTID

=
VOID_METHOD_TYPE(MANGLE_IDENTIFIER_MTID, code_generation_target *cgt, text_stream *OUT, text_stream *identifier)
void CodeGen::Targets::mangle(code_generation *gen, text_stream *OUT, text_stream *identifier) {
	VOID_METHOD_CALL(gen->target, MANGLE_IDENTIFIER_MTID, OUT, identifier);
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
@e DECLARE_ATTRIBUTE_MTID

=
VOID_METHOD_TYPE(DECLARE_PROPERTY_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *prop_name, int used)
VOID_METHOD_TYPE(DECLARE_ATTRIBUTE_MTID, code_generation_target *cgt, code_generation *gen, text_stream *prop_name)
void CodeGen::Targets::declare_property(code_generation *gen, inter_symbol *prop_name, int used) {
	VOID_METHOD_CALL(gen->target, DECLARE_PROPERTY_MTID, gen, prop_name, used);
}
void CodeGen::Targets::declare_attribute(code_generation *gen, text_stream *prop_name) {
	VOID_METHOD_CALL(gen->target, DECLARE_ATTRIBUTE_MTID, gen, prop_name);
}

@

@e PREPARE_VARIABLE_MTID
@e DECLARE_VARIABLE_MTID
@e DECLARE_LOCAL_VARIABLE_MTID

=
INT_METHOD_TYPE(PREPARE_VARIABLE_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k)
INT_METHOD_TYPE(DECLARE_VARIABLE_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k, int of)
VOID_METHOD_TYPE(DECLARE_LOCAL_VARIABLE_MTID, code_generation_target *cgt, int pass, code_generation *gen, inter_tree_node *P, inter_symbol *var_name)
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
void CodeGen::Targets::declare_local_variable(int pass, code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	VOID_METHOD_CALL(gen->target, DECLARE_LOCAL_VARIABLE_MTID, pass, gen, P, var_name);
}

@

@e DECLARE_CLASS_MTID
@e END_CLASS_MTID
@e DECLARE_INSTANCE_MTID
@e END_INSTANCE_MTID
@e ASSIGN_PROPERTY_MTID
@e PROPERTY_OFFSET_MTID

=
VOID_METHOD_TYPE(DECLARE_CLASS_MTID, code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *super_class)
VOID_METHOD_TYPE(END_CLASS_MTID, code_generation_target *cgt, code_generation *gen, text_stream *class_name)
void CodeGen::Targets::declare_class(code_generation *gen, text_stream *class_name, text_stream *super_class) {
	VOID_METHOD_CALL(gen->target, DECLARE_CLASS_MTID, gen, class_name, super_class);
}
void CodeGen::Targets::end_class(code_generation *gen, text_stream *class_name) {
	VOID_METHOD_CALL(gen->target, END_CLASS_MTID, gen, class_name);
}
VOID_METHOD_TYPE(DECLARE_INSTANCE_MTID, code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name, int acount, int is_dir)
VOID_METHOD_TYPE(END_INSTANCE_MTID, code_generation_target *cgt, code_generation *gen, text_stream *class_name, text_stream *instance_name)
void CodeGen::Targets::declare_instance(code_generation *gen, text_stream *class_name, text_stream *instance_name, int acount, int is_dir) {
	VOID_METHOD_CALL(gen->target, DECLARE_INSTANCE_MTID, gen, class_name, instance_name, acount, is_dir);
}
void CodeGen::Targets::end_instance(code_generation *gen, text_stream *class_name, text_stream *instance_name) {
	VOID_METHOD_CALL(gen->target, END_INSTANCE_MTID, gen, class_name, instance_name);
}
VOID_METHOD_TYPE(ASSIGN_PROPERTY_MTID, code_generation_target *cgt, code_generation *gen, text_stream *property_name, text_stream *val, int as_att)
void CodeGen::Targets::assign_property(code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	VOID_METHOD_CALL(gen->target, ASSIGN_PROPERTY_MTID, gen, property_name, val, as_att);
}
void CodeGen::Targets::assign_mangled_property(code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	TEMPORARY_TEXT(mangled)
	CodeGen::Targets::mangle(gen, mangled, val);
	CodeGen::Targets::assign_property(gen, property_name, mangled, as_att);
	DISCARD_TEXT(mangled)
}

VOID_METHOD_TYPE(PROPERTY_OFFSET_MTID, code_generation_target *cgt, code_generation *gen, text_stream *property_name, int pos, int as_att)
void CodeGen::Targets::property_offset(code_generation *gen, text_stream *property_name, int pos, int as_att) {
	VOID_METHOD_CALL(gen->target, PROPERTY_OFFSET_MTID, gen, property_name, pos, as_att);
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
VOID_METHOD_TYPE(BEGIN_CONSTANT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *const_name, int continues, int ifndef_me)
VOID_METHOD_TYPE(END_CONSTANT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *const_name, int ifndef_me)
void CodeGen::Targets::begin_constant(code_generation *gen, text_stream *const_name, int continues, int ifndef_me) {
	VOID_METHOD_CALL(gen->target, BEGIN_CONSTANT_MTID, gen, const_name, continues, ifndef_me);
}
void CodeGen::Targets::end_constant(code_generation *gen, text_stream *const_name, int ifndef_me) {
	VOID_METHOD_CALL(gen->target, END_CONSTANT_MTID, gen, const_name, ifndef_me);
}

@

@e BEGIN_FUNCTION_MTID
@e BEGIN_FUNCTION_CODE_MTID
@e PLACE_LABEL_MTID
@e END_FUNCTION_MTID

=
VOID_METHOD_TYPE(BEGIN_FUNCTION_MTID, code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn)
VOID_METHOD_TYPE(BEGIN_FUNCTION_CODE_MTID, code_generation_target *cgt, code_generation *gen)
VOID_METHOD_TYPE(PLACE_LABEL_MTID, code_generation_target *cgt, code_generation *gen, text_stream *label_name)
VOID_METHOD_TYPE(END_FUNCTION_MTID, code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn)
void CodeGen::Targets::begin_function(int pass, code_generation *gen, inter_symbol *fn) {
	VOID_METHOD_CALL(gen->target, BEGIN_FUNCTION_MTID, pass, gen, fn);
}
void CodeGen::Targets::begin_function_code(code_generation *gen) {
	VOID_METHOD_CALL(gen->target, BEGIN_FUNCTION_CODE_MTID, gen);
}
void CodeGen::Targets::place_label(code_generation *gen, text_stream *label_name) {
	VOID_METHOD_CALL(gen->target, PLACE_LABEL_MTID, gen, label_name);
}
void CodeGen::Targets::end_function(int pass, code_generation *gen, inter_symbol *fn) {
	VOID_METHOD_CALL(gen->target, END_FUNCTION_MTID, pass, gen, fn);
}

@

@e BEGIN_FUNCTION_CALL_MTID
@e ARGUMENT_MTID
@e END_FUNCTION_CALL_MTID

=
VOID_METHOD_TYPE(BEGIN_FUNCTION_CALL_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc)
VOID_METHOD_TYPE(ARGUMENT_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *F, inter_symbol *fn, int argc, int of_argc)
VOID_METHOD_TYPE(END_FUNCTION_CALL_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *fn, int argc)
void CodeGen::Targets::begin_function_call(code_generation *gen, inter_symbol *fn, int argc) {
	VOID_METHOD_CALL(gen->target, BEGIN_FUNCTION_CALL_MTID, gen, fn, argc);
}
void CodeGen::Targets::argument(code_generation *gen, inter_tree_node *F, inter_symbol *fn, int argc, int of_argc) {
	VOID_METHOD_CALL(gen->target, ARGUMENT_MTID, gen, F, fn, argc, of_argc);
}
void CodeGen::Targets::end_function_call(code_generation *gen, inter_symbol *fn, int argc) {
	VOID_METHOD_CALL(gen->target, END_FUNCTION_CALL_MTID, gen, fn, argc);
}

@

@e BEGIN_OPCODE_MTID
@e SUPPLY_OPERAND_MTID
@e END_OPCODE_MTID

=
VOID_METHOD_TYPE(BEGIN_OPCODE_MTID, code_generation_target *cgt, code_generation *gen, text_stream *opcode)
VOID_METHOD_TYPE(SUPPLY_OPERAND_MTID, code_generation_target *cgt, code_generation *gen, inter_tree_node *F, int is_label)
VOID_METHOD_TYPE(END_OPCODE_MTID, code_generation_target *cgt, code_generation *gen)
void CodeGen::Targets::begin_opcode(code_generation *gen, text_stream *opcode) {
	VOID_METHOD_CALL(gen->target, BEGIN_OPCODE_MTID, gen, opcode);
}
void CodeGen::Targets::supply_operand(code_generation *gen, inter_tree_node *F, int is_label) {
	VOID_METHOD_CALL(gen->target, SUPPLY_OPERAND_MTID, gen, F, is_label);
}
void CodeGen::Targets::end_opcode(code_generation *gen) {
	VOID_METHOD_CALL(gen->target, END_OPCODE_MTID, gen);
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
void CodeGen::Targets::mangled_array_entry(code_generation *gen, text_stream *entry, int format) {
	TEMPORARY_TEXT(mangled)
	CodeGen::Targets::mangle(gen, mangled, entry);
	VOID_METHOD_CALL(gen->target, ARRAY_ENTRY_MTID, gen, mangled, format);
	DISCARD_TEXT(mangled)
}
void CodeGen::Targets::end_array(code_generation *gen, int format) {
	VOID_METHOD_CALL(gen->target, END_ARRAY_MTID, gen, format);
}

@

@e NEW_FAKE_ACTION_MTID

=
VOID_METHOD_TYPE(NEW_FAKE_ACTION_MTID, code_generation_target *cgt, code_generation *gen, text_stream *name)
void CodeGen::Targets::new_fake_action(code_generation *gen, text_stream *name) {
	VOID_METHOD_CALL(gen->target, NEW_FAKE_ACTION_MTID, gen, name);
}
