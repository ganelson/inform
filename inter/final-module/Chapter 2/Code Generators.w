[Generators::] Code Generators.

To create the range of possible targets into which Inter can be converted.

@h Creation.
Single, steel-cut artisanal code generators are made here.

=
typedef struct code_generator {
	struct text_stream *generator_name;
	struct method_set *methods;
	CLASS_DEFINITION
} code_generator;

code_generator *Generators::new(text_stream *name) {
	code_generator *generator = CREATE(code_generator);
	generator->generator_name = Str::duplicate(name);
	generator->methods = Methods::new_set();
	return generator;
}

@ Note that some code-generators, like the ones for C of Inform 6, correspond
to families of |target_vm|: others, like the one for printing an inventory of
what is in an Inter tree, are not tied to VMs. But those which are tied to VMs
must have the same names as the family names for those VMs.

=
code_generator *Generators::find(text_stream *name) {
	Generators::make_all();
	code_generator *generator;
	LOOP_OVER(generator, code_generator)
		if (Str::eq_insensitive(generator->generator_name, name))
			return generator;
	return NULL;
}

code_generator *Generators::find_for(target_vm *VM) {
	return Generators::find(TargetVMs::family(VM));
}

@ And generators are mass-produced here:

=
int generators_have_been_made = FALSE;

void Generators::make_all(void) {
	if (generators_have_been_made == FALSE) {
		generators_have_been_made = TRUE;
		TextualTarget::create_generator();
		BinaryTarget::create_generator();
		InvTarget::create_generator();
		I6Target::create_generator();
		CTarget::create_generator();
	}
}

@h Method calls.
Generators can be extremely simple: only one method is compulsory, which is that
they must respond to |BEGIN_GENERATION_MTID|. If they return |FALSE| to this, the
process stops: it's assumed that they have gone their own way and completed the
business. If they return |TRUE|, however, the "vanilla" algorithm for generating
imperative code is run for them, in which case a host of further method calls
will be made -- see below.

In practice, then, some generators provide |BEGIN_GENERATION_MTID| and nothing
else, and do their own thing; others provide basically the entire suite below,
and dovetail with the vanilla algorithm.

@e BEGIN_GENERATION_MTID
@e END_GENERATION_MTID

=
INT_METHOD_TYPE(BEGIN_GENERATION_MTID, code_generator *generator, code_generation *gen)
INT_METHOD_TYPE(END_GENERATION_MTID, code_generator *generator, code_generation *gen)

void Generators::go(code_generation *gen) {
	CodeGen::clear_all_transients(gen->from);
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->generator, BEGIN_GENERATION_MTID, gen);
	if (rv) return;
	Vanilla::go(gen);
	INT_METHOD_CALL(rv, gen->generator, END_GENERATION_MTID, gen);
	if (rv) return;
	CodeGen::write_segments(gen->to_stream, gen);
}

@ This method is called early in generation to give the generator a chance to
act on any |pragma| instructions at the top of the Inter tree. These are like
C compiler |#pragma| directives: a generator is free to completely ignore any
that it doesn't recognise or like. They are each "tagged" with a textual
indication of the generator intended to get the message -- thus, for example,
|Inform6| for |pragma| instructions expected to be useful only when generating
I6 code. Still, all pragmas are offered to all generators.

@e OFFER_PRAGMA_MTID

=
VOID_METHOD_TYPE(OFFER_PRAGMA_MTID, code_generator *generator, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content)
void Generators::offer_pragma(code_generation *gen, inter_tree_node *P, text_stream *tag,
	text_stream *content) {
	VOID_METHOD_CALL(gen->generator, OFFER_PRAGMA_MTID, gen, P, tag, content);
}

@h Methods for code inside functions.
Labels are identified by name only, and are potential |!jump| destinations:

@e PLACE_LABEL_MTID
@e EVALUATE_LABEL_MTID

=
VOID_METHOD_TYPE(PLACE_LABEL_MTID, code_generator *generator, code_generation *gen,
	text_stream *label_name)
VOID_METHOD_TYPE(EVALUATE_LABEL_MTID, code_generator *generator, code_generation *gen,
	text_stream *label_name)
void Generators::place_label(code_generation *gen, text_stream *label_name) {
	VOID_METHOD_CALL(gen->generator, PLACE_LABEL_MTID, gen, label_name);
}
void Generators::evaluate_label(code_generation *gen, text_stream *label_name) {
	VOID_METHOD_CALL(gen->generator, EVALUATE_LABEL_MTID, gen, label_name);
}

@ The three ways to invoke:

@e INVOKE_PRIMITIVE_MTID
@e INVOKE_FUNCTION_MTID
@e INVOKE_OPCODE_MTID

=
VOID_METHOD_TYPE(INVOKE_PRIMITIVE_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context)
VOID_METHOD_TYPE(INVOKE_FUNCTION_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *fn, inter_tree_node *P, int void_context)
VOID_METHOD_TYPE(INVOKE_OPCODE_MTID, code_generator *generator, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense, int void_context)
void Generators::invoke_primitive(code_generation *gen, inter_symbol *prim_name,
	inter_tree_node *P, int void_context) {
	VOID_METHOD_CALL(gen->generator, INVOKE_PRIMITIVE_MTID, gen, prim_name, P, void_context);
}
void Generators::invoke_function(code_generation *gen, inter_symbol *fn, inter_tree_node *P,
	int void_context) {
	VOID_METHOD_CALL(gen->generator, INVOKE_FUNCTION_MTID, gen, fn, P, void_context);
}
void Generators::invoke_opcode(code_generation *gen, text_stream *opcode, int operand_count,
	inter_tree_node **operands, inter_tree_node *label, int label_sense, int void_context) {
	VOID_METHOD_CALL(gen->generator, INVOKE_OPCODE_MTID, gen, opcode, operand_count,
		operands, label, label_sense, void_context);
}

@

@e MANGLE_IDENTIFIER_MTID

=
VOID_METHOD_TYPE(MANGLE_IDENTIFIER_MTID, code_generator *generator, text_stream *OUT, text_stream *identifier)
void Generators::mangle(code_generation *gen, text_stream *OUT, text_stream *identifier) {
	VOID_METHOD_CALL(gen->generator, MANGLE_IDENTIFIER_MTID, OUT, identifier);
}

@

@e COMPILE_DICTIONARY_WORD_MTID

=
VOID_METHOD_TYPE(COMPILE_DICTIONARY_WORD_MTID, code_generator *generator, code_generation *gen, text_stream *S, int pluralise)
void Generators::compile_dictionary_word(code_generation *gen, text_stream *S, int pluralise) {
	VOID_METHOD_CALL(gen->generator, COMPILE_DICTIONARY_WORD_MTID, gen, S, pluralise);
}

@

@e COMPILE_LITERAL_NUMBER_MTID
@e COMPILE_LITERAL_REAL_MTID

=
VOID_METHOD_TYPE(COMPILE_LITERAL_NUMBER_MTID, code_generator *generator, code_generation *gen, inter_ti val, int hex_mode)
VOID_METHOD_TYPE(COMPILE_LITERAL_REAL_MTID, code_generator *generator, code_generation *gen, text_stream *textual)
void Generators::compile_literal_number(code_generation *gen, inter_ti val, int hex_mode) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_NUMBER_MTID, gen, val, hex_mode);
}
void Generators::compile_literal_real(code_generation *gen, text_stream *textual) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_REAL_MTID, gen, textual);
}

@

@e COMPILE_LITERAL_TEXT_MTID

=
VOID_METHOD_TYPE(COMPILE_LITERAL_TEXT_MTID, code_generator *generator, code_generation *gen, text_stream *S, int escape_mode)
void Generators::compile_literal_text(code_generation *gen, text_stream *S, int escape_mode) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_TEXT_MTID, gen, S, escape_mode);
}

@

@e DECLARE_PROPERTY_MTID
@e DECLARE_ATTRIBUTE_MTID

=
VOID_METHOD_TYPE(DECLARE_PROPERTY_MTID, code_generator *generator, code_generation *gen, inter_symbol *prop_name, int used)
VOID_METHOD_TYPE(DECLARE_ATTRIBUTE_MTID, code_generator *generator, code_generation *gen, text_stream *prop_name)
void Generators::declare_property(code_generation *gen, inter_symbol *prop_name, int used) {
	VOID_METHOD_CALL(gen->generator, DECLARE_PROPERTY_MTID, gen, prop_name, used);
}
void Generators::declare_attribute(code_generation *gen, text_stream *prop_name) {
	VOID_METHOD_CALL(gen->generator, DECLARE_ATTRIBUTE_MTID, gen, prop_name);
}

@

@e PREPARE_VARIABLE_MTID
@e DECLARE_VARIABLE_MTID
@e DECLARE_VARIABLES_MTID
@e EVALUATE_VARIABLE_MTID

=
INT_METHOD_TYPE(PREPARE_VARIABLE_MTID, code_generator *generator, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k)
INT_METHOD_TYPE(DECLARE_VARIABLE_MTID, code_generator *generator, code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k, int of)
VOID_METHOD_TYPE(DECLARE_VARIABLES_MTID, code_generator *generator, code_generation *gen, linked_list *L)
VOID_METHOD_TYPE(DECLARE_LOCAL_VARIABLE_MTID, code_generator *generator, code_generation *gen, inter_tree_node *P, inter_symbol *var_name)
VOID_METHOD_TYPE(EVALUATE_VARIABLE_MTID, code_generator *generator, code_generation *gen, inter_symbol *var_name, int as_reference)
int Generators::prepare_variable(code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->generator, PREPARE_VARIABLE_MTID, gen, P, var_name, k);
	return rv;
}
int Generators::declare_variable(code_generation *gen, inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->generator, DECLARE_VARIABLE_MTID, gen, P, var_name, k, of);
	return rv;
}
void Generators::declare_variables(code_generation *gen, linked_list *L) {
	VOID_METHOD_CALL(gen->generator, DECLARE_VARIABLES_MTID, gen, L);
}
void Generators::evaluate_variable(code_generation *gen, inter_symbol *var_name, int as_reference) {
	VOID_METHOD_CALL(gen->generator, EVALUATE_VARIABLE_MTID, gen, var_name, as_reference);
}

@

@e PSEUDO_OBJECT_MTID

=
VOID_METHOD_TYPE(PSEUDO_OBJECT_MTID, code_generator *generator, code_generation *gen, text_stream *obj_name)
void Generators::pseudo_object(code_generation *gen, text_stream *obj_name) {
	VOID_METHOD_CALL(gen->generator, PSEUDO_OBJECT_MTID, gen, obj_name);
}

@

@e DECLARE_CLASS_MTID
@e END_CLASS_MTID
@e DECLARE_INSTANCE_MTID
@e END_INSTANCE_MTID
@e DECLARE_VALUE_INSTANCE_MTID
@e OPTIMISE_PROPERTY_MTID
@e ASSIGN_PROPERTY_MTID
@e PROPERTY_OFFSET_MTID

=
VOID_METHOD_TYPE(DECLARE_CLASS_MTID, code_generator *generator, code_generation *gen, text_stream *class_name, text_stream *printed_name, text_stream *super_class, segmentation_pos *saved)
VOID_METHOD_TYPE(END_CLASS_MTID, code_generator *generator, code_generation *gen, text_stream *class_name, segmentation_pos saved)
void Generators::declare_class(code_generation *gen, text_stream *class_name, text_stream *printed_name, text_stream *super_class, segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, DECLARE_CLASS_MTID, gen, class_name, printed_name, super_class, saved);
}
void Generators::end_class(code_generation *gen, text_stream *class_name, segmentation_pos saved) {
	VOID_METHOD_CALL(gen->generator, END_CLASS_MTID, gen, class_name, saved);
}
VOID_METHOD_TYPE(DECLARE_INSTANCE_MTID, code_generator *generator, code_generation *gen, text_stream *class_name, text_stream *instance_name, text_stream *printed_name, int acount, int is_dir, segmentation_pos *saved)
VOID_METHOD_TYPE(END_INSTANCE_MTID, code_generator *generator, code_generation *gen, text_stream *class_name, text_stream *instance_name, segmentation_pos saved)
void Generators::declare_instance(code_generation *gen, text_stream *class_name, text_stream *instance_name, text_stream *printed_name, int acount, int is_dir, segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, DECLARE_INSTANCE_MTID, gen, class_name, instance_name, printed_name, acount, is_dir, saved);
}
void Generators::end_instance(code_generation *gen, text_stream *class_name, text_stream *instance_name, segmentation_pos saved) {
	VOID_METHOD_CALL(gen->generator, END_INSTANCE_MTID, gen, class_name, instance_name, saved);
}
VOID_METHOD_TYPE(DECLARE_VALUE_INSTANCE_MTID, code_generator *generator, code_generation *gen, text_stream *instance_name, text_stream *printed_name, text_stream *val)
void Generators::declare_value_instance(code_generation *gen, text_stream *instance_name, text_stream *printed_name, text_stream *val) {
	VOID_METHOD_CALL(gen->generator, DECLARE_VALUE_INSTANCE_MTID, gen, instance_name, printed_name, val);
}
INT_METHOD_TYPE(OPTIMISE_PROPERTY_MTID, code_generator *generator, code_generation *gen, inter_symbol *prop_name, inter_tree_node *X)
int Generators::optimise_property_value(code_generation *gen, inter_symbol *prop_name, inter_tree_node *X) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->generator, OPTIMISE_PROPERTY_MTID, gen, prop_name, X);
	return rv;
}
VOID_METHOD_TYPE(ASSIGN_PROPERTY_MTID, code_generator *generator, code_generation *gen, text_stream *property_name, text_stream *val, int as_att)
void Generators::assign_property(code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	VOID_METHOD_CALL(gen->generator, ASSIGN_PROPERTY_MTID, gen, property_name, val, as_att);
}
void Generators::assign_mangled_property(code_generation *gen, text_stream *property_name, text_stream *val, int as_att) {
	TEMPORARY_TEXT(mangled)
	Generators::mangle(gen, mangled, val);
	Generators::assign_property(gen, property_name, mangled, as_att);
	DISCARD_TEXT(mangled)
}

VOID_METHOD_TYPE(PROPERTY_OFFSET_MTID, code_generator *generator, code_generation *gen, text_stream *property_name, int pos, int as_att)
void Generators::property_offset(code_generation *gen, text_stream *property_name, int pos, int as_att) {
	VOID_METHOD_CALL(gen->generator, PROPERTY_OFFSET_MTID, gen, property_name, pos, as_att);
}

@

@e DECLARE_CONSTANT_MTID

@d DATA_GDCFORM 1
@d COMPUTED_GDCFORM 2
@d LITERAL_TEXT_GDCFORM 3
@d RAW_GDCFORM 4

=
VOID_METHOD_TYPE(DECLARE_CONSTANT_MTID, code_generator *generator, code_generation *gen, text_stream *const_name, inter_symbol *const_s, int form, inter_tree_node *P, text_stream *val, int ifndef_me)
void Generators::declare_constant(code_generation *gen, text_stream *const_name, inter_symbol *const_s, int form, inter_tree_node *P, text_stream *val, int ifndef_me) {
	VOID_METHOD_CALL(gen->generator, DECLARE_CONSTANT_MTID, gen, const_name, const_s, form, P, val, ifndef_me);
}

@

@e PREDECLARE_FUNCTION_MTID
@e DECLARE_FUNCTION_MTID
@e BEGIN_FUNCTION_CODE_MTID
@e END_FUNCTION_MTID

=
VOID_METHOD_TYPE(PREDECLARE_FUNCTION_MTID, code_generator *generator, code_generation *gen, inter_symbol *fn, inter_tree_node *code)
VOID_METHOD_TYPE(DECLARE_FUNCTION_MTID, code_generator *generator, code_generation *gen, inter_symbol *fn, inter_tree_node *code)
VOID_METHOD_TYPE(END_FUNCTION_MTID, code_generator *generator, int pass, code_generation *gen, inter_symbol *fn)
void Generators::predeclare_function(code_generation *gen, inter_symbol *fn, inter_tree_node *code) {
	VOID_METHOD_CALL(gen->generator, PREDECLARE_FUNCTION_MTID, gen, fn, code);
}
void Generators::declare_function(code_generation *gen, inter_symbol *fn, inter_tree_node *code) {
	VOID_METHOD_CALL(gen->generator, DECLARE_FUNCTION_MTID, gen, fn, code);
}
void Generators::end_function(int pass, code_generation *gen, inter_symbol *fn) {
	VOID_METHOD_CALL(gen->generator, END_FUNCTION_MTID, pass, gen, fn);
}

@

@e BEGIN_ARRAY_MTID
@e ARRAY_ENTRY_MTID
@e ARRAY_ENTRIES_MTID
@e COMPILE_LITERAL_SYMBOL_MTID
@e END_ARRAY_MTID

@d WORD_ARRAY_FORMAT 1
@d BYTE_ARRAY_FORMAT 2
@d TABLE_ARRAY_FORMAT 3
@d BUFFER_ARRAY_FORMAT 4

=
INT_METHOD_TYPE(BEGIN_ARRAY_MTID, code_generator *generator, code_generation *gen, text_stream *const_name, inter_symbol *array_s, inter_tree_node *P, int format, segmentation_pos *saved)
VOID_METHOD_TYPE(ARRAY_ENTRY_MTID, code_generator *generator, code_generation *gen, text_stream *entry, int format)
VOID_METHOD_TYPE(ARRAY_ENTRIES_MTID, code_generator *generator, code_generation *gen, int how_many, int plus_ips, int format)
VOID_METHOD_TYPE(COMPILE_LITERAL_SYMBOL_MTID, code_generator *generator, code_generation *gen, inter_symbol *aliased)
VOID_METHOD_TYPE(END_ARRAY_MTID, code_generator *generator, code_generation *gen, int format, segmentation_pos *saved)
int Generators::begin_array(code_generation *gen, text_stream *const_name, inter_symbol *array_s, inter_tree_node *P, int format, segmentation_pos *saved) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->generator, BEGIN_ARRAY_MTID, gen, const_name, array_s, P, format, saved);
	return rv;
}
void Generators::array_entry(code_generation *gen, text_stream *entry, int format) {
	VOID_METHOD_CALL(gen->generator, ARRAY_ENTRY_MTID, gen, entry, format);
}
void Generators::array_entries(code_generation *gen, int how_many, int plus_ips, int format) {
	VOID_METHOD_CALL(gen->generator, ARRAY_ENTRIES_MTID, gen, how_many, plus_ips, format);
}
void Generators::mangled_array_entry(code_generation *gen, text_stream *entry, int format) {
	TEMPORARY_TEXT(mangled)
	Generators::mangle(gen, mangled, entry);
	VOID_METHOD_CALL(gen->generator, ARRAY_ENTRY_MTID, gen, mangled, format);
	DISCARD_TEXT(mangled)
}
void Generators::compile_literal_symbol(code_generation *gen, inter_symbol *aliased) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_SYMBOL_MTID, gen, aliased);
}

void Generators::end_array(code_generation *gen, int format, segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, END_ARRAY_MTID, gen, format, saved);
}

@

@e WORLD_MODEL_ESSENTIALS_MTID

=
VOID_METHOD_TYPE(WORLD_MODEL_ESSENTIALS_MTID, code_generator *generator, code_generation *gen)
void Generators::world_model_essentials(code_generation *gen) {
	VOID_METHOD_CALL(gen->generator, WORLD_MODEL_ESSENTIALS_MTID, gen);
}

@

@e NEW_ACTION_MTID

=
VOID_METHOD_TYPE(NEW_ACTION_MTID, code_generator *generator, code_generation *gen, text_stream *name, int true_action)
void Generators::new_action(code_generation *gen, text_stream *name, int true_action) {
	VOID_METHOD_CALL(gen->generator, NEW_ACTION_MTID, gen, name, true_action);
}
