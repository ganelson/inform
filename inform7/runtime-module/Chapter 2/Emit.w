[Emit::] Emitting Inter.

"Emitting" is the process of generating Inter bytecode, and this section provides
a comprehensive API for the runtime and imperative modules to do that.

@h The emission tree.
The //bytecode// module can maintain multiple independent trees of Inter code
in memory, so that most calls to //bytecode// or //building// take an |inter_tree|
pointer as their first function argument. But //runtime// and //imperative// work
on just one single tree.

Calling |Packaging::outside_all_packages| makes a minimum of package types,
creates the |main| package, and so on, but leaves the tree basically still empty.
We then give it three top-level modules to start off with: |veneer|, |generic|
and |synoptic|. These are needed early because //Hierarchy// uses them as
reference points. But as newly-created packages they are initially empty.

=
inter_tree *main_emission_tree = NULL;

inter_tree *Emit::create_emission_tree(void) {
	main_emission_tree = InterTree::new();
	Packaging::outside_all_packages(main_emission_tree);
	Packaging::incarnate(Site::veneer_request(main_emission_tree));
	Packaging::incarnate(Packaging::get_unit(main_emission_tree, I"generic")->the_package);
	Packaging::incarnate(Packaging::get_unit(main_emission_tree, I"synoptic")->the_package);
	return main_emission_tree;
}
inter_tree *Emit::tree(void) {
	return main_emission_tree;
}

inter_ti Emit::symbol_id(inter_symbol *S) {
	return InterSymbolsTables::id_from_IRS_and_symbol(Emit::at(), S);
}

inter_warehouse *Emit::warehouse(void) {
	return InterTree::warehouse(Emit::tree());
}

inter_ti Emit::baseline(void) {
	return Produce::baseline(Emit::at());
}

@h Where bytecode comes out.
We are generating a hierarchical structure and not a stream, so we need the
ability to move the point at which new opcodes are being spawned. Big moves
are made by changing package (see below), but small ones are made by moving
up or down in the hierarchy. For example, |Emit::down()| shifts us so that
we are now creating bytecode below the instruction last emitted, not after it.
|Emit::up()| then returns us back to where we were. These should always be
used in ways guaranteed to match.

=
inter_bookmark *Emit::at(void) {
	return Packaging::at(Emit::tree());
}
void Emit::up(void) {
	Produce::up(Emit::tree());
}
void Emit::down(void) {
	Produce::down(Emit::tree());
}

@h Rudimentary kinds.
Inter has a very simple, and non-binding, system of "kinds" -- a much simpler
one than Inform. We need symbols to refer to some of these, and here they are.

The way these are created is typical. First we ask //Hierarchy// for the
Inter tree position of what we're intending to make. Then call |Packaging::enter_home_of|
to move the emission point to the current end of the package in question; then
we compile what it is we actually want to make; and then call |Packaging::exit|
again to return to where we were.

=
inter_symbol *unchecked_interk = NULL;
inter_symbol *unchecked_function_interk = NULL;
inter_symbol *int_interk = NULL;
inter_symbol *string_interk = NULL;

void Emit::rudimentary_kinds(void) {
	inter_name *KU = Hierarchy::find(K_UNCHECKED_HL);
	packaging_state save = Packaging::enter_home_of(KU);
	unchecked_interk = InterNames::to_symbol(KU);
	Emit::kind_inner(Emit::symbol_id(unchecked_interk), UNCHECKED_IDT, 0,
		BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);

	inter_name *KUF = Hierarchy::find(K_UNCHECKED_FUNCTION_HL);
	save = Packaging::enter_home_of(KUF);
	unchecked_function_interk = InterNames::to_symbol(KUF);
	inter_ti operands[2];
	operands[0] = Emit::symbol_id(unchecked_interk);
	operands[1] = Emit::symbol_id(unchecked_interk);
	Emit::kind_inner(Emit::symbol_id(unchecked_function_interk), ROUTINE_IDT, 0,
		FUNCTION_ICON, 2, operands);
	Packaging::exit(Emit::tree(), save);

	inter_name *KTI = Hierarchy::find(K_TYPELESS_INT_HL);
	save = Packaging::enter_home_of(KTI);
	int_interk = InterNames::to_symbol(KTI);
	Emit::kind_inner(Emit::symbol_id(int_interk), INT32_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);

	inter_name *KTS = Hierarchy::find(K_TYPELESS_STRING_HL);
	save = Packaging::enter_home_of(KTS);
	string_interk = InterNames::to_symbol(KTS);
	Emit::kind_inner(Emit::symbol_id(string_interk), TEXT_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);
}

@h Pragmas.
The Inter language allows pragmas, or code-generation hints, to be passed
through. These are specific to the target of compilation, and can be ignored
by all other targets. Here we generate only I6-target pragmas, which are commands
in I6's "Inform Control Language".

This is a mini-language for controlling the I6 compiler, able to set
command-line switches, memory settings and so on. I6 ordinarily discards lines
beginning with exclamation marks as comments, but at the very top of the file,
lines beginning |!%| are read as ICL commands: as soon as any line (including
a blank line) doesn't have this signature, I6 exits ICL mode.

Pragmas occupy a fixed position in the global material at the root of the Inter
tree, so there's no need to ask //Hierarchy// where these live.

=
void Emit::pragma(text_stream *text) {
	inter_tree *I = Emit::tree();
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(),
		InterTree::root_package(I));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	inter_symbol *target_name =
		InterSymbolsTables::symbol_from_name_creating(
			InterTree::global_scope(I), I"target_I6");
	Produce::guard(Inter::Pragma::new(Site::pragmas(I), target_name, ID, 0, NULL));
}

@h Constants.
These functions make it easy to define a named value in Inter. If the value is
an unsigned numeric constant, use one of these two functions -- the first if
it represents an actual number at run-time, the second if not:

=
inter_name *Emit::named_numeric_constant(inter_name *name, inter_ti val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name),
		Emit::symbol_id(int_interk), LITERAL_IVAL, val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

void Emit::unchecked_numeric_constant(inter_name *name, inter_ti val) {
	Emit::named_generic_constant(name, LITERAL_IVAL, val);
}

@ Text:

=
void Emit::text_constant(inter_name *name, text_stream *contents) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(),
		Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), contents);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_textual(Emit::at(), Emit::symbol_id(con_name),
		Emit::symbol_id(string_interk), ID, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@ And equating one constant to another named constant:

=
void Emit::iname_as_constant(package_request *PR, inter_name *name, inter_name *xiname) {
	inter_ti v1 = 0, v2 = 0;
	Inter::Symbols::to_data(Emit::tree(), Packaging::incarnate(PR), InterNames::to_symbol(xiname), &v1, &v2);
	Emit::named_generic_constant(name, v1, v2);
}

@ These two variants are needed only for the oddball way //Bibliographic Data//
is compiled.

=
void Emit::text_constant_from_wide_string(inter_name *name, wchar_t *str) {
	inter_ti v1 = 0, v2 = 0;
	TextLiterals::compile_literal_from_text(name, &v1, &v2, str);
	Emit::named_generic_constant(name, v1, v2);
}

void Emit::serial_number(inter_name *name, text_stream *serial) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_ti v1 = 0, v2 = 0;
	Produce::text_value(Emit::tree(), &v1, &v2, serial);
	Emit::named_generic_constant(name, v1, v2);
	Packaging::exit(Emit::tree(), save);
}

@ Similarly, there are just a few occasions when we need to extract the value
of a "variable" and define it as a constant:

=
void Emit::initial_value_as_constant(inter_name *name, nonlocal_variable *var) {
	inter_ti v1 = 0, v2 = 0;
	RTVariables::seek_initial_value(name, &v1, &v2, var);
	Emit::named_generic_constant(name, v1, v2);
}

@ The above make use of this:

=
void Emit::named_generic_constant(inter_name *name, inter_ti val1, inter_ti val2) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name),
		Emit::symbol_id(unchecked_interk), val1, val2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@ =
inter_symbol *Emit::response(inter_name *iname, rule *R, int marker, inter_name *val_iname) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symb = InterNames::to_symbol(iname);
	inter_symbol *rsymb = InterNames::to_symbol(RTRules::iname(R));
	inter_symbol *vsymb = InterNames::to_symbol(val_iname);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(Emit::at()),
		Inter::Bookmarks::package(Emit::at()), vsymb, &val1, &val2);
	Produce::guard(Inter::Response::new(Emit::at(),
		Emit::symbol_id(symb),
		Emit::symbol_id(rsymb),
		(inter_ti) marker, val1, val2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return symb;
}

void Emit::append(inter_name *iname, text_stream *text) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(), Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	Produce::guard(Inter::Append::new(Emit::at(), symbol, ID, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

text_stream *Emit::main_render_unique(inter_symbols_table *T, text_stream *name) {
	return InterSymbolsTables::render_identifier_unique(T, name);
}

void Emit::kind(inter_name *iname, inter_ti TID, inter_name *super,
	int constructor, int arity, kind **operand_kinds) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *S = InterNames::to_symbol(iname);
	inter_ti SID = 0;
	if (S) SID = Emit::symbol_id(S);
	inter_symbol *SS = (super)?InterNames::to_symbol(super):NULL;
	inter_ti SUP = 0;
	if (SS) SUP = Emit::symbol_id(SS);
	inter_ti operands[MAX_KIND_ARITY];
	if (arity > MAX_KIND_ARITY) internal_error("kind arity too high");
	for (int i=0; i<arity; i++) {
		if ((operand_kinds[i] == K_nil) || (operand_kinds[i] == K_void)) operands[i] = 0;
		else {
			inter_symbol *S = Produce::kind_to_symbol(operand_kinds[i]);
			operands[i] = Emit::symbol_id(S);
		}
	}
	Emit::kind_inner(SID, TID, SUP, constructor, arity, operands);
	InterNames::to_symbol(iname);
	Packaging::exit(Emit::tree(), save);
}

void Emit::kind_inner(inter_ti SID, inter_ti TID, inter_ti SUP,
	int constructor, int arity, inter_ti *operands) {
	Produce::guard(Inter::Kind::new(Emit::at(), SID, TID, SUP, constructor, arity, operands, Emit::baseline(), NULL));
}

inter_symbol *Emit::variable(inter_name *name, kind *K, inter_ti v1, inter_ti v2, text_stream *rvalue) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *var_name = Produce::define_symbol(name);
	inter_symbol *var_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Variable::new(Emit::at(),
		Emit::symbol_id(var_name), Emit::symbol_id(var_kind), v1, v2, Emit::baseline(), NULL));
	if (rvalue) Produce::annotate_symbol_i(var_name, EXPLICIT_VARIABLE_IANN, 1);
	Packaging::exit(Emit::tree(), save);
	return var_name;
}

void Emit::property(inter_name *name, kind *K) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *prop_name = Produce::define_symbol(name);
	inter_symbol *prop_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Property::new(Emit::at(),
		Emit::symbol_id(prop_name), Emit::symbol_id(prop_kind), Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::permission(property *prn, kind *K, inter_name *name) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_name *prop_name = RTProperties::iname(prn);
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	inter_symbol *store = (name)?InterNames::to_symbol(name):NULL;
	Emit::basic_permission(Emit::at(), prop_name, owner_kind, store);
	Packaging::exit(Emit::tree(), save);
}

void Emit::instance_permission(property *prn, inter_name *inst_iname) {
	inter_name *prop_name = RTProperties::iname(prn);
	inter_symbol *inst_name = InterNames::to_symbol(inst_iname);
	packaging_state save = Packaging::enter_home_of(inst_iname);
	Emit::basic_permission(Emit::at(), prop_name, inst_name, NULL);
	Packaging::exit(Emit::tree(), save);
}

int ppi7_counter = 0;
void Emit::basic_permission(inter_bookmark *at, inter_name *name, inter_symbol *owner_name, inter_symbol *store) {
	inter_symbol *prop_name = Produce::define_symbol(name);
	inter_error_message *E = NULL;
	TEMPORARY_TEXT(ident)
	WRITE_TO(ident, "pp_i7_%d", ppi7_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(NULL, Inter::Bookmarks::scope(at), ident, &E);
	DISCARD_TEXT(ident)
	Produce::guard(E);
	Produce::guard(Inter::Permission::new(at,
		InterSymbolsTables::id_from_IRS_and_symbol(at, prop_name), InterSymbolsTables::id_from_IRS_and_symbol(at, owner_name), InterSymbolsTables::id_from_IRS_and_symbol(at, pp_name), (store)?(InterSymbolsTables::id_from_IRS_and_symbol(at, store)):0, Produce::baseline(at), NULL));
}

typedef struct dval_written {
	kind *K_written;
	inter_ti v1;
	inter_ti v2;
	CLASS_DEFINITION
} dval_written;

void Emit::ensure_defaultvalue(kind *K) {
	if (K == K_value) return;
	dval_written *dw;
	LOOP_OVER(dw, dval_written)
		if (Kinds::eq(K, dw->K_written))
			return;
	dw = CREATE(dval_written);
	dw->K_written = K; dw->v1 = 0; dw->v2 = 0;
	RTKinds::get_default_value(&(dw->v1), &(dw->v2), K);
	if (dw->v1 != 0)
		Emit::defaultvalue(K, dw->v1, dw->v2);
}

void Emit::defaultvalue(kind *K, inter_ti v1, inter_ti v2) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::DefaultValue::new(Emit::at(),
		Emit::symbol_id(owner_kind), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::propertyvalue(property *P, kind *K, inter_ti v1, inter_ti v2) {
	RTProperties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(RTProperties::iname(P));
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::PropertyValue::new(Emit::at(),
		Emit::symbol_id(prop_name), Emit::symbol_id(owner_kind), v1, v2, Emit::baseline(), NULL));
}

void Emit::instance_propertyvalue(property *P, instance *I, inter_ti v1, inter_ti v2) {
	RTProperties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(RTProperties::iname(P));
	inter_symbol *owner_kind = InterNames::to_symbol(RTInstances::emitted_iname(I));
	Produce::guard(Inter::PropertyValue::new(Emit::at(),
		Emit::symbol_id(prop_name), Emit::symbol_id(owner_kind), v1, v2, Emit::baseline(), NULL));
}

void Emit::instance(inter_name *name, kind *K, int v) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *inst_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	inter_ti v1 = LITERAL_IVAL, v2 = (inter_ti) v;
	if (v == 0) { v1 = UNDEF_IVAL; v2 = 0; }
	Produce::guard(Inter::Instance::new(Emit::at(), Emit::symbol_id(inst_name), Emit::symbol_id(val_kind), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

packaging_state Emit::named_late_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Produce::annotate_iname_i(name, LATE_IANN, 1);
	return save;
}

packaging_state Emit::named_byte_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Produce::annotate_iname_i(name, BYTEARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_table_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Produce::annotate_iname_i(name, TABLEARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_string_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Produce::annotate_iname_i(name, STRINGARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_verb_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Produce::annotate_iname_i(name, VERBARRAY_IANN, 1);
	Produce::annotate_iname_i(name, LATE_IANN, 1);
	return save;
}

typedef struct nascent_array {
	struct inter_symbol *array_name_symbol;
	struct kind *entry_kind;
	inter_ti array_form;
	int no_entries;
	int capacity;
	inter_ti *entry_data1;
	inter_ti *entry_data2;
	struct nascent_array *up;
	struct nascent_array *down;
	CLASS_DEFINITION
} nascent_array;

nascent_array *first_A = NULL, *current_A = NULL;

void Emit::push_array(void) {
	nascent_array *A = NULL;

	if (current_A) {
		A = current_A->down;
		if (A == NULL) {
			A = CREATE(nascent_array);
			A->up = current_A;
			A->down = NULL;
			A->capacity = 0;
			current_A->down = A;
		}
	} else {
		if (first_A) A = first_A;
		else {
			A = CREATE(nascent_array);
			A->up = NULL;
			A->down = NULL;
			A->capacity = 0;
			first_A = A;
		}
	}

	A->no_entries = 0;
	A->entry_kind = NULL;
	A->array_name_symbol = NULL;
	A->array_form = CONSTANT_INDIRECT_LIST;
	current_A = A;
}

void Emit::pull_array(void) {
	if (current_A == NULL) internal_error("pull array failed");
	current_A = current_A->up;
}

void Emit::add_entry(inter_ti v1, inter_ti v2) {
	if (current_A == NULL) internal_error("no nascent array");
	int N = current_A->no_entries;
	if (N+1 > current_A->capacity) {
		int M = 4*(N+1);
		if (current_A->capacity == 0) M = 256;

		inter_ti *old_data1 = current_A->entry_data1;
		inter_ti *old_data2 = current_A->entry_data2;

		current_A->entry_data1 = Memory::calloc(M, sizeof(inter_ti), EMIT_ARRAY_MREASON);
		current_A->entry_data2 = Memory::calloc(M, sizeof(inter_ti), EMIT_ARRAY_MREASON);

		for (int i=0; i<current_A->capacity; i++) {
			current_A->entry_data1[i] = old_data1[i];
			current_A->entry_data2[i] = old_data2[i];
		}

		if (old_data1) Memory::I7_array_free(old_data1, EMIT_ARRAY_MREASON, current_A->capacity, sizeof(inter_ti));
		if (old_data2) Memory::I7_array_free(old_data2, EMIT_ARRAY_MREASON, current_A->capacity, sizeof(inter_ti));

		current_A->capacity = M;
	}
	current_A->entry_data1[N] = v1;
	current_A->entry_data2[N] = v2;
	current_A->no_entries++;
}

packaging_state Emit::sum_constant_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	current_A->array_form = CONSTANT_SUM_LIST;
	return save;
}

packaging_state Emit::named_array_begin(inter_name *N, kind *K) {
	packaging_state save = Packaging::enter_home_of(N);
	inter_symbol *symb = Produce::define_symbol(N);
	Emit::push_array();
	if (K == NULL) K = K_value;
	current_A->entry_kind = K;
	current_A->array_name_symbol = symb;
	return save;
}

void Emit::array_iname_entry(inter_name *iname) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_symbol *alias;
	if (iname == NULL) alias = Site::veneer_symbol(Emit::tree(), NOTHING_VSYMB);
	else alias = InterNames::to_symbol(iname);
	inter_ti val1 = 0, val2 = 0;
	inter_bookmark *IBM = Emit::array_IRS();
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), alias, &val1, &val2);
	Emit::add_entry(val1, val2);
}

void Emit::array_null_entry(void) {
	Emit::array_iname_entry(Hierarchy::find(NULL_HL));
}

void Emit::array_MPN_entry(void) {
	Emit::array_iname_entry(Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
}

void Emit::array_generic_entry(inter_ti val1, inter_ti val2) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	Emit::add_entry(val1, val2);
}

#ifdef IF_MODULE
void Emit::array_action_entry(action_name *an) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_ti v1 = 0, v2 = 0;
	inter_symbol *symb = InterNames::to_symbol(RTActions::iname(an));
	inter_bookmark *IBM = Emit::array_IRS();
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), symb, &v1, &v2);
	Emit::add_entry(v1, v2);
}
#endif

void Emit::array_text_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_ti v1 = 0, v2 = 0;
	Produce::text_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_ti v1 = 0, v2 = 0;
	Produce::dword_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_plural_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_ti v1 = 0, v2 = 0;
	Produce::plural_dword_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_numeric_entry(inter_ti N) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	Emit::add_entry(LITERAL_IVAL, N);
}

void Emit::array_divider(text_stream *divider_text) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_ti S = Inter::Warehouse::create_text(Emit::warehouse(), Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), S), divider_text);
	Emit::add_entry(DIVIDER_IVAL, S);
}

inter_bookmark *Emit::array_IRS(void) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_bookmark *IBM = Emit::at();
	return IBM;
}

void Emit::array_end(packaging_state save) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_symbol *con_name = current_A->array_name_symbol;
	inter_bookmark *IBM = Emit::at();
	kind *K = current_A->entry_kind;
	inter_ti CID = 0;
	if (K) {
		inter_symbol *con_kind = NULL;
		if (current_A->array_form == CONSTANT_INDIRECT_LIST)
			con_kind = Produce::kind_to_symbol(Kinds::unary_con(CON_list_of, K));
		else
			con_kind = Produce::kind_to_symbol(K);
		CID = InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind);
	} else {
		CID = InterSymbolsTables::id_from_IRS_and_symbol(IBM, unchecked_interk);
	}
	inter_tree_node *array_in_progress =
		Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), CID, current_A->array_form, NULL, Produce::baseline(IBM));
	int pos = array_in_progress->W.extent;
	if (Inode::extend(array_in_progress, (unsigned int) (2*current_A->no_entries)) == FALSE)
		internal_error("can't extend frame");
	for (int i=0; i<current_A->no_entries; i++) {
		array_in_progress->W.data[pos++] = current_A->entry_data1[i];
		array_in_progress->W.data[pos++] = current_A->entry_data2[i];
	}
	Produce::guard(Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), array_in_progress));
	Inter::Bookmarks::insert(Emit::at(), array_in_progress);
	Emit::pull_array();
	Packaging::exit(Emit::tree(), save);
}

inter_name *Emit::named_iname_constant(inter_name *name, kind *K, inter_name *iname) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	inter_symbol *alias = (iname)?InterNames::to_symbol(iname):NULL;
	if (alias == NULL) {
		if (Kinds::Behaviour::is_object(K)) alias = Site::veneer_symbol(Emit::tree(), NOTHING_VSYMB);
		else internal_error("can't handle a null alias");
	}
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(Emit::at()), Inter::Bookmarks::package(Emit::at()), alias, &val1, &val2);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name), Emit::symbol_id(val_kind), val1, val2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_numeric_constant_hex(inter_name *name, inter_ti val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, HEX_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name), Emit::symbol_id(int_interk), LITERAL_IVAL, val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_unchecked_constant_hex(inter_name *name, inter_ti val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, HEX_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name), Emit::symbol_id(unchecked_interk), LITERAL_IVAL, val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_numeric_constant_signed(inter_name *name, int val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, SIGNED_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_name), Emit::symbol_id(int_interk), LITERAL_IVAL, (inter_ti) val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

void Emit::early_comment(text_stream *text) {
/*	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(), Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	Produce::guard(Inter::Comment::new(Emit::at(), Emit::baseline() + 1, NULL, ID));
*/
}

void Emit::code_comment(text_stream *text) {
/*	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(), Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	Produce::guard(Inter::Comment::new(Produce::at(Emit::tree()), (inter_ti) Produce::level(Emit::tree()), NULL, ID));
*/
}


void Emit::function(inter_name *rname, kind *rkind, inter_package *block) {
	if (Emit::at() == NULL) internal_error("no inter repository");
	inter_symbol *AB_symbol = Produce::kind_to_symbol(rkind);
	inter_symbol *rsymb = Produce::define_symbol(rname);
	Produce::guard(Inter::Constant::new_function(Emit::at(),
		Emit::symbol_id(rsymb),
		Emit::symbol_id(AB_symbol),
		block,
		Emit::baseline(), NULL));
}

inter_symbol *Emit::local(kind *K, text_stream *lname, inter_ti annot, text_stream *comm) {
	if (Site::get_cir(Emit::tree()) == NULL) internal_error("not in an inter routine");
	if (K == NULL) K = K_number;
	inter_symbol *loc_name = Produce::new_local_symbol(Site::get_cir(Emit::tree()), lname);
	inter_symbol *loc_kind = Produce::kind_to_symbol(K);
	inter_ti ID = 0;
	if ((comm) && (Str::len(comm) > 0)) {
		ID = Inter::Warehouse::create_text(Emit::warehouse(), Inter::Bookmarks::package(Emit::at()));
		Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), comm);
	}
	if (annot) Produce::annotate_symbol_i(loc_name, annot, 0);
	Inter::Symbols::local(loc_name);
	Produce::guard(Inter::Local::new(Produce::locals_bookmark(Emit::tree()), loc_name, loc_kind, ID, Produce::baseline(Produce::locals_bookmark(Emit::tree())) + 1, NULL));
	return loc_name;
}

void Emit::cast(kind *F, kind *T) {
	inter_symbol *from_kind = Produce::kind_to_symbol(F);
	inter_symbol *to_kind = Produce::kind_to_symbol(T);
	Produce::guard(Inter::Cast::new(Produce::at(Emit::tree()), from_kind, to_kind, (inter_ti) Produce::level(Emit::tree()), NULL));
}

void Emit::intervention(int stage, text_stream *segment, text_stream *part, text_stream *i6, text_stream *seg) {
	inter_warehouse *warehouse = Emit::warehouse();
	inter_ti ID1 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID1), segment);

	inter_ti ID2 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID2), part);

	inter_ti ID3 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID3), i6);

	inter_ti ID4 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Emit::at()));
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID4), seg);

	inter_ti ref = Inter::Warehouse::create_ref(warehouse);
	Inter::Warehouse::set_ref(warehouse, ref, (void *) current_sentence);

	Inter::Warehouse::attribute_resource(warehouse, ref, Inter::Bookmarks::package(Emit::at()));

	Produce::guard(Inter::Link::new(Emit::at(), (inter_ti) stage, ID1, ID2, ID3, ID4, ref, Emit::baseline(), NULL));
}

@ =


text_stream *Emit::to_text(inter_name *iname) {
	if (iname == NULL) return NULL;
	return InterNames::to_symbol(iname)->symbol_name;
}

void Emit::holster(value_holster *VH, inter_name *iname) {
	if (Holsters::data_acceptable(VH)) {
		inter_ti v1 = 0, v2 = 0;
		Emit::to_ival(&v1, &v2, iname);
		Holsters::holster_pair(VH, v1, v2);
	}
}

void Emit::symbol_to_ival(inter_ti *val1, inter_ti *val2, inter_symbol *S) {
	inter_bookmark *IBM = Emit::at();
	if (S) { Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival(inter_ti *val1, inter_ti *val2, inter_name *iname) {
	inter_bookmark *IBM = Emit::at();
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival_in_context(inter_name *context, inter_ti *val1, inter_ti *val2, inter_name *iname) {
	package_request *PR = InterNames::location(context);
	inter_package *pack = Packaging::incarnate(PR);
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

int Emit::defined(inter_name *iname) {
	if (iname == NULL) return FALSE;
	inter_symbol *S = InterNames::to_symbol(iname);
	if (Inter::Symbols::is_defined(S)) return TRUE;
	return FALSE;
}

typedef struct ival_emission {
	struct value_holster emission_VH;
	struct packaging_state saved_PS;
} ival_emission;

ival_emission Emit::begin_ival_emission(inter_name *iname) {
	ival_emission IE;
	IE.emission_VH = Holsters::new(INTER_DATA_VHMODE);
	IE.saved_PS = Packaging::enter_home_of(iname);
	return IE;
}

value_holster *Emit::ival_holster(ival_emission *IE) {
	return &(IE->emission_VH);
}

void Emit::end_ival_emission(ival_emission *IE, inter_ti *v1, inter_ti *v2) {
	Holsters::unholster_pair(&(IE->emission_VH), v1, v2);
	Packaging::exit(Emit::tree(), IE->saved_PS);
}

package_request *Emit::current_enclosure(void) {
	return Packaging::enclosure(Emit::tree());
}

packaging_state Emit::unused_packaging_state(void) {
	return Packaging::stateless();
}
