[Emit::] Emitting Inter.

@h Definitions.

@

=
inter_symbol *unchecked_interk = NULL;
inter_symbol *unchecked_function_interk = NULL;
inter_symbol *int_interk = NULL;
inter_symbol *string_interk = NULL;

inter_tree *I7_generation_tree = NULL;

inter_tree *Emit::tree(void) {
	return I7_generation_tree;
}

void Emit::begin(void) {
	inter_tree *I = Inter::Tree::new();
	Packaging::initialise_state(I);
	Packaging::outside_all_packages(I);
	I7_generation_tree = I;
	
	Packaging::incarnate(Site::veneer_request(I));
	Packaging::incarnate(Packaging::get_module(I, I"generic")->the_package);
	Packaging::incarnate(Packaging::get_module(I, I"synoptic")->the_package);
	Packaging::incarnate(Packaging::get_module(I, I"standard_rules")->the_package);	

	Hierarchy::establish(I);

	inter_name *KU = Hierarchy::find(K_UNCHECKED_HL);
	packaging_state save = Packaging::enter_home_of(KU);
	unchecked_interk = InterNames::to_symbol(KU);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_interk), UNCHECKED_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);

	inter_name *KUF = Hierarchy::find(K_UNCHECKED_FUNCTION_HL);
	save = Packaging::enter_home_of(KUF);
	unchecked_function_interk = InterNames::to_symbol(KUF);
	inter_t operands[2];
	operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_interk);
	operands[1] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_interk);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_function_interk), ROUTINE_IDT, 0, FUNCTION_ICON, 2, operands);
	Packaging::exit(Emit::tree(), save);

	inter_name *KTI = Hierarchy::find(K_TYPELESS_INT_HL);
	save = Packaging::enter_home_of(KTI);
	int_interk = InterNames::to_symbol(KTI);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), INT32_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);

	inter_name *KTS = Hierarchy::find(K_TYPELESS_STRING_HL);
	save = Packaging::enter_home_of(KTS);
	string_interk = InterNames::to_symbol(KTS);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), string_interk), TEXT_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(Emit::tree(), save);

	FundamentalConstants::emit(Task::vm());
	NewVerbs::ConjugateVerbDefinitions();
	
	Hierarchy::find(INFORMLIBRARY_HL);
}

inter_symbol *Emit::response(inter_name *iname, rule *R, int marker, inter_name *val_iname) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symb = InterNames::to_symbol(iname);
	inter_symbol *rsymb = InterNames::to_symbol(Rules::iname(R));
	inter_symbol *vsymb = InterNames::to_symbol(val_iname);
	inter_t val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(Packaging::at(Emit::tree())), Inter::Bookmarks::package(Packaging::at(Emit::tree())), vsymb, &val1, &val2);
	Produce::guard(Inter::Response::new(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), symb), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), rsymb), (inter_t) marker, val1, val2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return symb;
}

@ The Inter language allows pragmas, or code-generation hints, to be passed
through. These are specific to the target of compilation. Here we generate
only I6-target pragmas, which are commands in Inform Control Language.

This is a mini-language for controlling the I6 compiler, able to set
command-line switches, memory settings and so on. I6 ordinarily discards lines
beginning with exclamation marks as comments, but at the very top of the file,
lines beginning |!%| are read as ICL commands: as soon as any line (including
a blank line) doesn't have this signature, I6 exits ICL mode. This is why we
insert them into the Inter stream close to the top.

=
void Emit::pragma(text_stream *text) {
	inter_tree *I = Emit::tree();
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(I), Inter::Tree::root_package(I));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(I), ID), text);
	inter_symbol *target_name =
		Inter::SymbolsTables::symbol_from_name_creating(
			Inter::Tree::global_scope(I), I"target_I6");
	Produce::guard(Inter::Pragma::new(Site::pragmas(I), target_name, ID, 0, NULL));
}

void Emit::append(inter_name *iname, text_stream *text) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID), text);
	Produce::guard(Inter::Append::new(Packaging::at(Emit::tree()), symbol, ID, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

text_stream *Emit::main_render_unique(inter_symbols_table *T, text_stream *name) {
	return Inter::SymbolsTables::render_identifier_unique(T, name);
}

inter_symbol *Emit::holding_symbol(inter_symbols_table *T, text_stream *name) {
LOG("Holding %S\n", name);
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) {
		symb = Produce::new_symbol(T, name);
		inter_tree *I = Emit::tree();
		Produce::guard(Inter::Constant::new_numerical(Site::holdings(I), Inter::SymbolsTables::id_from_IRS_and_symbol(Site::holdings(I), symb), Inter::SymbolsTables::id_from_IRS_and_symbol(Site::holdings(I), int_interk), LITERAL_IVAL, 0, Produce::baseline(Site::holdings(I)), NULL));
		Produce::annotate_symbol_i(symb, HOLDING_IANN, 1);
	}
	return symb;
}

void Emit::kind(inter_name *iname, inter_t TID, inter_name *super,
	int constructor, int arity, kind **operand_kinds) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *S = InterNames::to_symbol(iname);
	inter_t SID = 0;
	if (S) SID = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), S);
	inter_symbol *SS = (super)?InterNames::to_symbol(super):NULL;
	inter_t SUP = 0;
	if (SS) SUP = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), SS);
	inter_t operands[MAX_KIND_ARITY];
	if (arity > MAX_KIND_ARITY) internal_error("kind arity too high");
	for (int i=0; i<arity; i++) {
		if (operand_kinds[i] == K_nil) operands[i] = 0;
		else {
			inter_symbol *S = Produce::kind_to_symbol(operand_kinds[i]);
			operands[i] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), S);
		}
	}
	Emit::kind_inner(SID, TID, SUP, constructor, arity, operands);
	InterNames::to_symbol(iname);
	Packaging::exit(Emit::tree(), save);
}

void Emit::kind_inner(inter_t SID, inter_t TID, inter_t SUP,
	int constructor, int arity, inter_t *operands) {
	Produce::guard(Inter::Kind::new(Packaging::at(Emit::tree()), SID, TID, SUP, constructor, arity, operands, Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

inter_symbol *Emit::variable(inter_name *name, kind *K, inter_t v1, inter_t v2, text_stream *rvalue) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *var_name = Produce::define_symbol(name);
	inter_symbol *var_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Variable::new(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), var_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), var_kind), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	if (rvalue) Produce::annotate_symbol_i(var_name, EXPLICIT_VARIABLE_IANN, 1);
	Packaging::exit(Emit::tree(), save);
	return var_name;
}

void Emit::property(inter_name *name, kind *K) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *prop_name = Produce::define_symbol(name);
	inter_symbol *prop_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Property::new(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), prop_kind), Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::permission(property *prn, kind *K, inter_name *name) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_name *prop_name = Properties::iname(prn);
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	inter_symbol *store = (name)?InterNames::to_symbol(name):NULL;
	Emit::basic_permission(Packaging::at(Emit::tree()), prop_name, owner_kind, store);
	Packaging::exit(Emit::tree(), save);
}

void Emit::instance_permission(property *prn, inter_name *inst_iname) {
	inter_name *prop_name = Properties::iname(prn);
	inter_symbol *inst_name = InterNames::to_symbol(inst_iname);
	packaging_state save = Packaging::enter_home_of(inst_iname);
	Emit::basic_permission(Packaging::at(Emit::tree()), prop_name, inst_name, NULL);
	Packaging::exit(Emit::tree(), save);
}

int ppi7_counter = 0;
void Emit::basic_permission(inter_bookmark *at, inter_name *name, inter_symbol *owner_name, inter_symbol *store) {
	inter_symbol *prop_name = Produce::define_symbol(name);
	inter_error_message *E = NULL;
	TEMPORARY_TEXT(ident);
	WRITE_TO(ident, "pp_i7_%d", ppi7_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(NULL, Inter::Bookmarks::scope(at), ident, &E);
	DISCARD_TEXT(ident);
	Produce::guard(E);
	Produce::guard(Inter::Permission::new(at,
		Inter::SymbolsTables::id_from_IRS_and_symbol(at, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(at, owner_name), Inter::SymbolsTables::id_from_IRS_and_symbol(at, pp_name), (store)?(Inter::SymbolsTables::id_from_IRS_and_symbol(at, store)):0, Produce::baseline(at), NULL));
}

typedef struct dval_written {
	kind *K_written;
	inter_t v1;
	inter_t v2;
	MEMORY_MANAGEMENT
} dval_written;

void Emit::ensure_defaultvalue(kind *K) {
	if (K == K_value) return;
	dval_written *dw;
	LOOP_OVER(dw, dval_written)
		if (Kinds::Compare::eq(K, dw->K_written))
			return;
	dw = CREATE(dval_written);
	dw->K_written = K; dw->v1 = 0; dw->v2 = 0;
	Kinds::RunTime::get_default_value(&(dw->v1), &(dw->v2), K);
	if (dw->v1 != 0)
		Emit::defaultvalue(K, dw->v1, dw->v2);
}

void Emit::defaultvalue(kind *K, inter_t v1, inter_t v2) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::DefaultValue::new(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), owner_kind), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::propertyvalue(property *P, kind *K, inter_t v1, inter_t v2) {
	Properties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(Properties::iname(P));
	inter_symbol *owner_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::PropertyValue::new(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), owner_kind), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

void Emit::instance_propertyvalue(property *P, instance *I, inter_t v1, inter_t v2) {
	Properties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(Properties::iname(P));
	inter_symbol *owner_kind = InterNames::to_symbol(Instances::emitted_iname(I));
	Produce::guard(Inter::PropertyValue::new(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), owner_kind), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

void Emit::named_string_constant(inter_name *name, text_stream *contents) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID), contents);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_textual(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), string_interk), ID, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::instance(inter_name *name, kind *K, int v) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *inst_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	inter_t v1 = LITERAL_IVAL, v2 = (inter_t) v;
	if (v == 0) { v1 = UNDEF_IVAL; v2 = 0; }
	Produce::guard(Inter::Instance::new(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), inst_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), val_kind), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::named_generic_constant_xiname(package_request *PR, inter_name *name, inter_name *xiname) {
	inter_t v1 = 0, v2 = 0;
	Inter::Symbols::to_data(Emit::tree(), Packaging::incarnate(PR), InterNames::to_symbol(xiname), &v1, &v2);
	Emit::named_generic_constant(name, v1, v2);
}

void Emit::named_generic_constant(inter_name *name, inter_t val1, inter_t val2) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_interk), val1, val2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

inter_name *Emit::named_numeric_constant(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

void Emit::hold_numeric_constant(inter_name *name, inter_t val) {
	inter_symbol *con_name = InterNames::to_symbol(name);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

void Emit::named_text_constant(inter_name *name, text_stream *content) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	inter_t v1 = 0, v2 = 0;
	Produce::text_value(Emit::tree(), &v1, &v2, content);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), v1, v2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::named_pseudo_numeric_constant(inter_name *name, kind *K, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), val_kind), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::ds_named_pseudo_numeric_constant(inter_name *name, kind *K, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), val_kind), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
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
	inter_t array_form;
	int no_entries;
	int capacity;
	inter_t *entry_data1;
	inter_t *entry_data2;
	struct nascent_array *up;
	struct nascent_array *down;
	MEMORY_MANAGEMENT
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

void Emit::add_entry(inter_t v1, inter_t v2) {
	if (current_A == NULL) internal_error("no nascent array");
	int N = current_A->no_entries;
	if (N+1 > current_A->capacity) {
		int M = 4*(N+1);
		if (current_A->capacity == 0) M = 256;

		inter_t *old_data1 = current_A->entry_data1;
		inter_t *old_data2 = current_A->entry_data2;

		current_A->entry_data1 = Memory::calloc(M, sizeof(inter_t), EMIT_ARRAY_MREASON);
		current_A->entry_data2 = Memory::calloc(M, sizeof(inter_t), EMIT_ARRAY_MREASON);

		for (int i=0; i<current_A->capacity; i++) {
			current_A->entry_data1[i] = old_data1[i];
			current_A->entry_data2[i] = old_data2[i];
		}

		if (old_data1) Memory::I7_array_free(old_data1, EMIT_ARRAY_MREASON, current_A->capacity, sizeof(inter_t));
		if (old_data2) Memory::I7_array_free(old_data2, EMIT_ARRAY_MREASON, current_A->capacity, sizeof(inter_t));

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
	inter_t val1 = 0, val2 = 0;
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

void Emit::array_generic_entry(inter_t val1, inter_t val2) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	Emit::add_entry(val1, val2);
}

#ifdef IF_MODULE
void Emit::array_action_entry(action_name *an) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	inter_symbol *symb = InterNames::to_symbol(PL::Actions::iname(an));
	inter_bookmark *IBM = Emit::array_IRS();
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), symb, &v1, &v2);
	Emit::add_entry(v1, v2);
}
#endif

void Emit::array_text_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Produce::text_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Produce::dword_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_plural_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Produce::plural_dword_value(Emit::tree(), &v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_numeric_entry(inter_t N) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	Emit::add_entry(LITERAL_IVAL, N);
}

void Emit::array_divider(text_stream *divider_text) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t S = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), S), divider_text);
	Emit::add_entry(DIVIDER_IVAL, S);
}

inter_bookmark *Emit::array_IRS(void) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_bookmark *IBM = Packaging::at(Emit::tree());
	return IBM;
}

void Emit::array_end(packaging_state save) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_symbol *con_name = current_A->array_name_symbol;
	inter_bookmark *IBM = Packaging::at(Emit::tree());
	kind *K = current_A->entry_kind;
	inter_t CID = 0;
	if (K) {
		inter_symbol *con_kind = NULL;
		if (current_A->array_form == CONSTANT_INDIRECT_LIST)
			con_kind = Produce::kind_to_symbol(Kinds::unary_construction(CON_list_of, K));
		else
			con_kind = Produce::kind_to_symbol(K);
		CID = Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, con_kind);
	} else {
		CID = Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, unchecked_interk);
	}
	inter_tree_node *array_in_progress =
		Inter::Node::fill_3(IBM, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, con_name), CID, current_A->array_form, NULL, Produce::baseline(IBM));
	int pos = array_in_progress->W.extent;
	if (Inter::Node::extend(array_in_progress, (unsigned int) (2*current_A->no_entries)) == FALSE)
		internal_error("can't extend frame");
	for (int i=0; i<current_A->no_entries; i++) {
		array_in_progress->W.data[pos++] = current_A->entry_data1[i];
		array_in_progress->W.data[pos++] = current_A->entry_data2[i];
	}
	Produce::guard(Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), array_in_progress));
	Inter::Bookmarks::insert(Packaging::at(Emit::tree()), array_in_progress);
	Emit::pull_array();
	Packaging::exit(Emit::tree(), save);
}

inter_name *Emit::named_iname_constant(inter_name *name, kind *K, inter_name *iname) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	inter_symbol *val_kind = Produce::kind_to_symbol(K);
	inter_symbol *alias = (iname)?InterNames::to_symbol(iname):NULL;
	if (alias == NULL) {
		if (Kinds::Compare::le(K, K_object)) alias = Site::veneer_symbol(Emit::tree(), NOTHING_VSYMB);
		else internal_error("can't handle a null alias");
	}
	inter_t val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(Packaging::at(Emit::tree())), Inter::Bookmarks::package(Packaging::at(Emit::tree())), alias, &val1, &val2);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), val_kind), val1, val2, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_numeric_constant_hex(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, HEX_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_unchecked_constant_hex(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, HEX_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), unchecked_interk), LITERAL_IVAL, val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

inter_name *Emit::named_numeric_constant_signed(inter_name *name, int val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Produce::define_symbol(name);
	Produce::annotate_symbol_i(con_name, SIGNED_IANN, 0);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(Emit::tree()), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), int_interk), LITERAL_IVAL, (inter_t) val, Produce::baseline(Packaging::at(Emit::tree())), NULL));
	Packaging::exit(Emit::tree(), save);
	return name;
}

// inter_bookmark current_inter_bookmark;

void Emit::early_comment(text_stream *text) {
/*	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID), text);
	Produce::guard(Inter::Comment::new(Packaging::at(Emit::tree()), Produce::baseline(Packaging::at(Emit::tree())) + 1, NULL, ID));
*/
}

void Emit::code_comment(text_stream *text) {
/*	inter_t ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID), text);
	Produce::guard(Inter::Comment::new(Produce::at(Emit::tree()), (inter_t) Produce::level(Emit::tree()), NULL, ID));
*/
}


void Emit::routine(inter_name *rname, kind *rkind, inter_package *block) {
	if (Packaging::at(Emit::tree()) == NULL) internal_error("no inter repository");
	inter_symbol *AB_symbol = Produce::kind_to_symbol(rkind);
	inter_symbol *rsymb = Produce::define_symbol(rname);
	Produce::guard(Inter::Constant::new_function(Packaging::at(Emit::tree()),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), rsymb),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(Emit::tree()), AB_symbol),
		block,
		Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

inter_symbol *Emit::local(kind *K, text_stream *lname, inter_t annot, text_stream *comm) {
	if (Site::get_cir(Emit::tree()) == NULL) internal_error("not in an inter routine");
	if (K == NULL) K = K_number;
	inter_symbol *loc_name = Produce::new_local_symbol(Site::get_cir(Emit::tree()), lname);
	inter_symbol *loc_kind = Produce::kind_to_symbol(K);
	inter_t ID = 0;
	if ((comm) && (Str::len(comm) > 0)) {
		ID = Inter::Warehouse::create_text(Inter::Tree::warehouse(Emit::tree()), Inter::Bookmarks::package(Packaging::at(Emit::tree())));
		Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID), comm);
	}
	if (annot) Produce::annotate_symbol_i(loc_name, annot, 0);
	Inter::Symbols::local(loc_name);
	Produce::guard(Inter::Local::new(Produce::locals_bookmark(Emit::tree()), loc_name, loc_kind, ID, Produce::baseline(Produce::locals_bookmark(Emit::tree())) + 1, NULL));
	return loc_name;
}

void Emit::cast(kind *F, kind *T) {
	inter_symbol *from_kind = Produce::kind_to_symbol(F);
	inter_symbol *to_kind = Produce::kind_to_symbol(T);
	Produce::guard(Inter::Cast::new(Produce::at(Emit::tree()), from_kind, to_kind, (inter_t) Produce::level(Emit::tree()), NULL));
}

void Emit::intervention(int stage, text_stream *segment, text_stream *part, text_stream *i6, text_stream *seg) {
	inter_warehouse *warehouse = Inter::Tree::warehouse(Emit::tree());
	inter_t ID1 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID1), segment);

	inter_t ID2 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID2), part);

	inter_t ID3 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID3), i6);

	inter_t ID4 = Inter::Warehouse::create_text(warehouse, Inter::Bookmarks::package(Packaging::at(Emit::tree())));
	Str::copy(Inter::Warehouse::get_text(Inter::Tree::warehouse(Emit::tree()), ID4), seg);

	inter_t ref = Inter::Warehouse::create_ref(warehouse);
	Inter::Warehouse::set_ref(warehouse, ref, (void *) current_sentence);

	Inter::Warehouse::attribute_resource(warehouse, ref, Inter::Bookmarks::package(Packaging::at(Emit::tree())));

	Produce::guard(Inter::Link::new(Packaging::at(Emit::tree()), (inter_t) stage, ID1, ID2, ID3, ID4, ref, Produce::baseline(Packaging::at(Emit::tree())), NULL));
}

@ =


text_stream *Emit::to_text(inter_name *iname) {
	if (iname == NULL) return NULL;
	return InterNames::to_symbol(iname)->symbol_name;
}

void Emit::holster(value_holster *VH, inter_name *iname) {
	if (Holsters::data_acceptable(VH)) {
		inter_t v1 = 0, v2 = 0;
		Emit::to_ival(&v1, &v2, iname);
		Holsters::holster_pair(VH, v1, v2);
	}
}

void Emit::symbol_to_ival(inter_t *val1, inter_t *val2, inter_symbol *S) {
	inter_bookmark *IBM = Packaging::at(Emit::tree());
	if (S) { Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival(inter_t *val1, inter_t *val2, inter_name *iname) {
	inter_bookmark *IBM = Packaging::at(Emit::tree());
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival_in_context(inter_name *context, inter_t *val1, inter_t *val2, inter_name *iname) {
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

void Emit::end_ival_emission(ival_emission *IE, inter_t *v1, inter_t *v2) {
	Holsters::unholster_pair(&(IE->emission_VH), v1, v2);
	Packaging::exit(Emit::tree(), IE->saved_PS);
}

package_request *Emit::current_enclosure(void) {
	return Packaging::enclosure(Emit::tree());
}

packaging_state Emit::unused_packaging_state(void) {
	return Packaging::stateless();
}
