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

@h The Go mechanism.
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

@h Methods called by Vanilla.
This method is called early in generation to give the generator a chance to
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

@

@e PREDECLARE_FUNCTION_MTID

=
VOID_METHOD_TYPE(PREDECLARE_FUNCTION_MTID, code_generator *generator, code_generation *gen,
	vanilla_function *vf)
VOID_METHOD_TYPE(END_FUNCTION_MTID, code_generator *generator, int pass, code_generation *gen,
	inter_symbol *fn)
void Generators::predeclare_function(code_generation *gen, vanilla_function *vf) {
	VOID_METHOD_CALL(gen->generator, PREDECLARE_FUNCTION_MTID, gen, vf);
}

@h Methods called by Vanilla Constants.

@e NEW_ACTION_MTID

=
VOID_METHOD_TYPE(NEW_ACTION_MTID, code_generator *generator, code_generation *gen,
	text_stream *name, int true_action, int N)
void Generators::new_action(code_generation *gen, text_stream *name, int true_action, int N) {
	VOID_METHOD_CALL(gen->generator, NEW_ACTION_MTID, gen, name, true_action, N);
}

@

@e PSEUDO_OBJECT_MTID

=
VOID_METHOD_TYPE(PSEUDO_OBJECT_MTID, code_generator *generator, code_generation *gen,
	text_stream *obj_name)
void Generators::pseudo_object(code_generation *gen, text_stream *obj_name) {
	VOID_METHOD_CALL(gen->generator, PSEUDO_OBJECT_MTID, gen, obj_name);
}

@

@e DECLARE_FUNCTION_MTID

=
VOID_METHOD_TYPE(DECLARE_FUNCTION_MTID, code_generator *generator, code_generation *gen,
	vanilla_function *vf)
void Generators::declare_function(code_generation *gen, vanilla_function *vf) {
	VOID_METHOD_CALL(gen->generator, DECLARE_FUNCTION_MTID, gen, vf);
}

@

@e BEGIN_ARRAY_MTID
@e ARRAY_ENTRY_MTID
@e ARRAY_ENTRIES_MTID
@e END_ARRAY_MTID

@d WORD_ARRAY_FORMAT 1
@d BYTE_ARRAY_FORMAT 2
@d TABLE_ARRAY_FORMAT 3
@d BUFFER_ARRAY_FORMAT 4

=
INT_METHOD_TYPE(BEGIN_ARRAY_MTID, code_generator *generator, code_generation *gen,
	text_stream *const_name, inter_symbol *array_s, inter_tree_node *P, int zero_count,
	int format, segmentation_pos *saved)
VOID_METHOD_TYPE(ARRAY_ENTRY_MTID, code_generator *generator, code_generation *gen,
	text_stream *entry, int format)
VOID_METHOD_TYPE(ARRAY_ENTRIES_MTID, code_generator *generator, code_generation *gen,
	int how_many, int format)
VOID_METHOD_TYPE(END_ARRAY_MTID, code_generator *generator, code_generation *gen,
	int format, int zero_count, segmentation_pos *saved)
int Generators::begin_array(code_generation *gen, text_stream *const_name,
	inter_symbol *array_s, inter_tree_node *P, int format, int zero_count,
	segmentation_pos *saved) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, gen->generator, BEGIN_ARRAY_MTID, gen, const_name, array_s,
		P, format, zero_count, saved);
	return rv;
}
void Generators::array_entry(code_generation *gen, text_stream *entry, int format) {
	VOID_METHOD_CALL(gen->generator, ARRAY_ENTRY_MTID, gen, entry, format);
}
void Generators::mangled_array_entry(code_generation *gen, text_stream *entry, int format) {
	TEMPORARY_TEXT(mangled)
	Generators::mangle(gen, mangled, entry);
	VOID_METHOD_CALL(gen->generator, ARRAY_ENTRY_MTID, gen, mangled, format);
	DISCARD_TEXT(mangled)
}
void Generators::symbol_array_entry(code_generation *gen, inter_symbol *entry, int format) {
	Generators::mangled_array_entry(gen, InterSymbol::trans(entry), format);
}

void Generators::end_array(code_generation *gen, int format, int zero_count,
	segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, END_ARRAY_MTID, gen, format, zero_count, saved);
}

@

@e DECLARE_CONSTANT_MTID

@d DATA_GDCFORM 1
@d COMPUTED_GDCFORM 2
@d LITERAL_TEXT_GDCFORM 3
@d RAW_GDCFORM 4
@d MANGLED_GDCFORM 5

=
VOID_METHOD_TYPE(DECLARE_CONSTANT_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *const_s, int form, text_stream *val)
void Generators::declare_constant(code_generation *gen, inter_symbol *const_s, int form,
	text_stream *val) {
	VOID_METHOD_CALL(gen->generator, DECLARE_CONSTANT_MTID, gen, const_s, form, val);
}

@

@e WORD_TO_BYTE_MTID

=
VOID_METHOD_TYPE(WORD_TO_BYTE_MTID, code_generator *generator, code_generation *gen,
	text_stream *to_write, text_stream *val, int b)
void Generators::word_to_byte(code_generation *gen, text_stream *to_write,
	text_stream *val, int b) {
	VOID_METHOD_CALL(gen->generator, WORD_TO_BYTE_MTID, gen, to_write, val, b);
}

@h Methods called by Vanilla Code.
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

@ Provenance instructions. These identify the original source location that
generated the current code.

@e PLACE_PROVENANCE_MTID

=
VOID_METHOD_TYPE(PLACE_PROVENANCE_MTID, code_generator *generator, code_generation *gen,
	text_provenance *source_loc)
void Generators::place_provenance(code_generation *gen, text_provenance *source_loc) {
	VOID_METHOD_CALL(gen->generator, PLACE_PROVENANCE_MTID, gen, source_loc);
}

@ The three ways to invoke (and a doohickey for assembly opcodes):

@e INVOKE_PRIMITIVE_MTID
@e INVOKE_FUNCTION_MTID
@e INVOKE_OPCODE_MTID
@e ASSEMBLY_MARKER_MTID

=
VOID_METHOD_TYPE(INVOKE_PRIMITIVE_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *prim_name, inter_tree_node *P, int void_context)
VOID_METHOD_TYPE(INVOKE_FUNCTION_MTID, code_generator *generator, code_generation *gen,
	inter_tree_node *P, vanilla_function *vf, int void_context)
VOID_METHOD_TYPE(INVOKE_OPCODE_MTID, code_generator *generator, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense)
VOID_METHOD_TYPE(ASSEMBLY_MARKER_MTID, code_generator *generator, code_generation *gen,
	inter_ti marker)
void Generators::invoke_primitive(code_generation *gen, inter_symbol *prim_name,
	inter_tree_node *P, int void_context) {
	VOID_METHOD_CALL(gen->generator, INVOKE_PRIMITIVE_MTID, gen, prim_name, P, void_context);
}
void Generators::invoke_function(code_generation *gen, inter_tree_node *P,
	vanilla_function *vf, int void_context) {
	VOID_METHOD_CALL(gen->generator, INVOKE_FUNCTION_MTID, gen, P, vf, void_context);
}
void Generators::invoke_opcode(code_generation *gen, text_stream *opcode, int operand_count,
	inter_tree_node **operands, inter_tree_node *label, int label_sense) {
	VOID_METHOD_CALL(gen->generator, INVOKE_OPCODE_MTID, gen, opcode, operand_count,
		operands, label, label_sense);
}
void Generators::assembly_marker(code_generation *gen, inter_ti marker) {
	VOID_METHOD_CALL(gen->generator, ASSEMBLY_MARKER_MTID, gen, marker);
}

@

@e MANGLE_IDENTIFIER_MTID

=
VOID_METHOD_TYPE(MANGLE_IDENTIFIER_MTID, code_generator *generator, text_stream *OUT,
	text_stream *identifier)
void Generators::mangle(code_generation *gen, text_stream *OUT, text_stream *identifier) {
	VOID_METHOD_CALL(gen->generator, MANGLE_IDENTIFIER_MTID, OUT, identifier);
}

@h Methods called by Vanilla Objects.

@e DECLARE_PROPERTY_MTID

=
VOID_METHOD_TYPE(DECLARE_PROPERTY_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *prop_name, linked_list *all_forms)
void Generators::declare_property(code_generation *gen, inter_symbol *prop_name,
	linked_list *all_forms) {
	VOID_METHOD_CALL(gen->generator, DECLARE_PROPERTY_MTID, gen, prop_name, all_forms);
}

@

@e PREPARE_VARIABLE_MTID
@e DECLARE_VARIABLE_MTID
@e DECLARE_VARIABLES_MTID
@e EVALUATE_VARIABLE_MTID

=
INT_METHOD_TYPE(PREPARE_VARIABLE_MTID, code_generator *generator, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k)
INT_METHOD_TYPE(DECLARE_VARIABLE_MTID, code_generator *generator, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of)
VOID_METHOD_TYPE(DECLARE_VARIABLES_MTID, code_generator *generator, code_generation *gen,
	linked_list *L)
VOID_METHOD_TYPE(DECLARE_LOCAL_VARIABLE_MTID, code_generator *generator,
	code_generation *gen, inter_tree_node *P, inter_symbol *var_name)
VOID_METHOD_TYPE(EVALUATE_VARIABLE_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *var_name, int as_reference)
int Generators::prepare_variable(code_generation *gen, inter_tree_node *P,
	inter_symbol *var_name, int k) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->generator, PREPARE_VARIABLE_MTID, gen, P, var_name, k);
	return rv;
}
int Generators::declare_variable(code_generation *gen, inter_tree_node *P,
	inter_symbol *var_name, int k, int of) {
	int rv = 0;
	INT_METHOD_CALL(rv, gen->generator, DECLARE_VARIABLE_MTID, gen, P, var_name, k, of);
	return rv;
}
void Generators::declare_variables(code_generation *gen, linked_list *L) {
	VOID_METHOD_CALL(gen->generator, DECLARE_VARIABLES_MTID, gen, L);
}
void Generators::evaluate_variable(code_generation *gen, inter_symbol *var_name,
	int as_reference) {
	VOID_METHOD_CALL(gen->generator, EVALUATE_VARIABLE_MTID, gen, var_name, as_reference);
}

@

@e DECLARE_KIND_MTID
@e END_KIND_MTID
@e DECLARE_INSTANCE_MTID
@e END_INSTANCE_MTID
@e ASSIGN_PROPERTY_MTID
@e ASSIGN_PROPERTIES_MTID

=
VOID_METHOD_TYPE(DECLARE_KIND_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *kind_s, segmentation_pos *saved)
VOID_METHOD_TYPE(END_KIND_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *kind_s, segmentation_pos saved)
void Generators::declare_kind(code_generation *gen, inter_symbol *kind_s,
	segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, DECLARE_KIND_MTID, gen, kind_s, saved);
}
void Generators::end_kind(code_generation *gen, inter_symbol *kind_s, segmentation_pos saved) {
	VOID_METHOD_CALL(gen->generator, END_KIND_MTID, gen, kind_s, saved);
}

VOID_METHOD_TYPE(DECLARE_INSTANCE_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *inst_s, inter_symbol *kind_s, int enumeration, segmentation_pos *saved)
VOID_METHOD_TYPE(END_INSTANCE_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *inst_s, inter_symbol *kind_s, segmentation_pos saved)
void Generators::declare_instance(code_generation *gen, inter_symbol *inst_s,
	inter_symbol *kind_s, int enumeration, segmentation_pos *saved) {
	VOID_METHOD_CALL(gen->generator, DECLARE_INSTANCE_MTID, gen, inst_s, kind_s, enumeration, saved);
}
void Generators::end_instance(code_generation *gen, inter_symbol *inst_s,
	inter_symbol *kind_s, segmentation_pos saved) {
	VOID_METHOD_CALL(gen->generator, END_INSTANCE_MTID, gen, inst_s, kind_s, saved);
}

VOID_METHOD_TYPE(ASSIGN_PROPERTY_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *prop_name, inter_pair val, inter_tree_node *X)
VOID_METHOD_TYPE(ASSIGN_PROPERTIES_MTID, code_generator *generator, code_generation *gen,
	inter_symbol *kind_name, inter_symbol *prop_name, text_stream *array)
void Generators::assign_property(code_generation *gen, inter_symbol *prop_name,
	inter_pair val, inter_tree_node *X) {
	VOID_METHOD_CALL(gen->generator, ASSIGN_PROPERTY_MTID, gen, prop_name, val, X);
}
void Generators::assign_properties(code_generation *gen, inter_symbol *kind_name,
	inter_symbol *prop_name, text_stream *array) {
	VOID_METHOD_CALL(gen->generator, ASSIGN_PROPERTIES_MTID, gen, kind_name, prop_name, array);
}

@h Methods used for compiling from Inter pairs.

@e COMPILE_DICTIONARY_WORD_MTID
@e COMPILE_LITERAL_NUMBER_MTID
@e COMPILE_LITERAL_REAL_MTID
@e COMPILE_LITERAL_SYMBOL_MTID
@e COMPILE_LITERAL_TEXT_MTID

=
VOID_METHOD_TYPE(COMPILE_LITERAL_NUMBER_MTID, code_generator *generator,
	code_generation *gen, inter_ti val, int hex_mode)
VOID_METHOD_TYPE(COMPILE_LITERAL_REAL_MTID, code_generator *generator,
	code_generation *gen, text_stream *textual)
VOID_METHOD_TYPE(COMPILE_LITERAL_SYMBOL_MTID, code_generator *generator,
	code_generation *gen, inter_symbol *aliased)
VOID_METHOD_TYPE(COMPILE_LITERAL_TEXT_MTID, code_generator *generator,
	code_generation *gen, text_stream *S, int escape_mode)
VOID_METHOD_TYPE(COMPILE_DICTIONARY_WORD_MTID, code_generator *generator,
	code_generation *gen, text_stream *S, int pluralise)

void Generators::compile_literal_number(code_generation *gen, inter_ti val, int hex_mode) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_NUMBER_MTID, gen, val, hex_mode);
}
void Generators::compile_literal_real(code_generation *gen, text_stream *textual) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_REAL_MTID, gen, textual);
}
void Generators::compile_literal_symbol(code_generation *gen, inter_symbol *aliased) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_SYMBOL_MTID, gen, aliased);
}
void Generators::compile_literal_text(code_generation *gen, text_stream *S, int escape_mode) {
	VOID_METHOD_CALL(gen->generator, COMPILE_LITERAL_TEXT_MTID, gen, S, escape_mode);
}
void Generators::compile_dictionary_word(code_generation *gen, text_stream *S, int pluralise) {
	VOID_METHOD_CALL(gen->generator, COMPILE_DICTIONARY_WORD_MTID, gen, S, pluralise);
}
