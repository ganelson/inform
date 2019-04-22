[Emit::] Emitting Inter.

@h Definitions.

@

=
inter_symbol *unchecked_interk = NULL;
inter_symbol *unchecked_function_interk = NULL;
inter_symbol *int_interk = NULL;
inter_symbol *string_interk = NULL;

inter_repository *Emit::repository(void) {
	return Packaging::at()->read_into;
}

inter_t Emit::baseline(inter_reading_state *IRS) {
	if (IRS == NULL) return 0;
	if (IRS->current_package == NULL) return 0;
	if (IRS->current_package->codelike_package) return IRS->current_package->parent_package->I7_baseline;
	return IRS->current_package->I7_baseline;
}

inter_reading_state Emit::bookmark(void) {
	inter_reading_state b = Inter::Bookmarks::snapshot(Packaging::at());
	return b;
}

void Emit::nop(void) {
	Emit::guard(Inter::Nop::new(Packaging::at(), Emit::baseline(Packaging::at()), NULL));
}

dictionary *extern_symbols = NULL;

int glob_count = 0;

void Emit::begin(void) {
	inter_repository *repo = Inter::create(1, 4096);
	Packaging::initialise_state(repo);
	Packaging::outside_all_packages();

	inter_name *KU = Hierarchy::find(K_UNCHECKED_HL);
	packaging_state save = Packaging::enter_home_of(KU);
	unchecked_interk = InterNames::to_symbol(KU);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_interk), UNCHECKED_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(save);

	inter_name *KUF = Hierarchy::find(K_UNCHECKED_FUNCTION_HL);
	save = Packaging::enter_home_of(KUF);
	unchecked_function_interk = InterNames::to_symbol(KUF);
	inter_t operands[2];
	operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_interk);
	operands[1] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_interk);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_function_interk), ROUTINE_IDT, 0, FUNCTION_ICON, 2, operands);
	Packaging::exit(save);

	inter_name *KTI = Hierarchy::find(K_TYPELESS_INT_HL);
	save = Packaging::enter_home_of(KTI);
	int_interk = InterNames::to_symbol(KTI);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), INT32_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(save);

	inter_name *KTS = Hierarchy::find(K_TYPELESS_STRING_HL);
	save = Packaging::enter_home_of(KTS);
	string_interk = InterNames::to_symbol(KTS);
	Emit::kind_inner(Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), string_interk), TEXT_IDT, 0, BASE_ICON, 0, NULL);
	Packaging::exit(save);

	VirtualMachines::emit_fundamental_constants();
	NewVerbs::ConjugateVerbDefinitions();
}

void Emit::version(int N) {
	Emit::guard(Inter::Version::new(Packaging::at(), N, Emit::baseline(Packaging::at()), NULL));
}

inter_symbol *Emit::packagetype(text_stream *name, int enclosing) {
	inter_symbol *pt = Emit::new_symbol(Inter::get_global_symbols(Emit::repository()), name);
	Emit::guard(Inter::PackageType::new_packagetype(&package_types_bookmark, pt, Emit::baseline(&package_types_bookmark), NULL));
	if (enclosing) Emit::annotate_symbol_i(pt, ENCLOSING_IANN, 1);
	return pt;
}

void Emit::comment(text_stream *text) {
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), text);
	Emit::guard(Inter::Comment::new(Packaging::at(), Emit::baseline(Packaging::at()), NULL, ID));
}

inter_symbol *Emit::kind_to_symbol(kind *K) {
	if (K == NULL) return unchecked_interk;
	if (K == K_value) return unchecked_interk; /* for error recovery */
	return InterNames::to_symbol(Kinds::RunTime::iname(K));
}

inter_symbol *Emit::extern(text_stream *name, kind *K) {
	if (extern_symbols == NULL) extern_symbols = Dictionaries::new(1024, FALSE);
	if (Dictionaries::find(extern_symbols, name))
		return Dictionaries::read_value(extern_symbols, name);
	inter_symbol *symb = Emit::new_symbol(Emit::main_scope(), name);
	Inter::Symbols::extern(symb);
	Dictionaries::create(extern_symbols, name);
	Dictionaries::write_value(extern_symbols, name, symb);
	return symb;
}

inter_symbol *Emit::response(inter_name *iname, rule *R, int marker, inter_name *val_iname) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symb = InterNames::to_symbol(iname);
	inter_symbol *rsymb = InterNames::to_symbol(Rules::iname(R));
	inter_symbol *vsymb = InterNames::to_symbol(val_iname);
	inter_t val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Packaging::at()->read_into, Packaging::at()->current_package, vsymb, &val1, &val2);
	Emit::guard(Inter::Response::new(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), symb), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), rsymb), (inter_t) marker, val1, val2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
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
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), text);
	inter_symbol *target_name =
		Inter::SymbolsTables::symbol_from_name_creating(
			Inter::get_global_symbols(Emit::repository()), I"target_I6");
	Emit::guard(Inter::Pragma::new(&pragmas_bookmark, target_name, ID, 0, NULL));
}

void Emit::append(inter_name *iname, text_stream *text) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), text);
	Emit::guard(Inter::Append::new(Packaging::at(), symbol, ID, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::import(inter_name *iname, wording W) {
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_t ID = Inter::create_text(Emit::repository());
	WRITE_TO(Inter::get_text(Emit::repository(), ID), "%W", W);
	Emit::guard(Inter::Import::new(Packaging::at(), symbol, ID, Emit::baseline(Packaging::at()), NULL));
}

void Emit::export(inter_name *iname, wording W) {
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_t ID = Inter::create_text(Emit::repository());
	WRITE_TO(Inter::get_text(Emit::repository(), ID), "%W", W);
	Emit::guard(Inter::Export::new(Packaging::at(), symbol, ID, Emit::baseline(Packaging::at()), NULL));
}

void Emit::primitive(text_stream *prim, text_stream *category, inter_symbol **to) {
	if (to == NULL) internal_error("no symbol");
	TEMPORARY_TEXT(prim_command);
	WRITE_TO(prim_command, "primitive %S %S", prim, category);
	Emit::guard(Inter::Defn::read_construct_text(prim_command, NULL, Packaging::at()));
	inter_error_message *E = NULL;
	*to = Inter::Textual::find_symbol(Emit::repository(), NULL, Inter::get_global_symbols(Emit::repository()), prim, PRIMITIVE_IST, &E);
	Emit::guard(E);
	DISCARD_TEXT(prim_command);
}

inter_symbols_table *Emit::main_scope(void) {
	return Inter::Packages::scope(Inter::Packages::main(Emit::repository()));
}

inter_symbols_table *Emit::global_scope(void) {
	return Inter::get_global_symbols(Emit::repository());
}

void Emit::main_render_unique(inter_symbols_table *T, text_stream *name) {
	Inter::SymbolsTables::render_identifier_unique(T, name);
}

inter_symbol *Emit::seek_symbol(inter_symbols_table *T, text_stream *name) {
	return Inter::SymbolsTables::symbol_from_name(T, name);
}

inter_symbol *Emit::new_symbol(inter_symbols_table *T, text_stream *name) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if ((symb) && (Inter::Symbols::read_annotation(symb, HOLDING_IANN) == 1)) {
		Emit::annotate_symbol_i(symb, DELENDA_EST_IANN, 1);
		Inter::Nop::nop_out(Emit::repository(), Inter::Symbols::defining_frame(symb));
		Inter::Symbols::undefine(symb);
		return symb;
	}
	return Inter::SymbolsTables::create_with_unique_name(T, name);
}

inter_symbol *Emit::holding_symbol(inter_symbols_table *T, text_stream *name) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) {
		symb = Emit::new_symbol(T, name);
		Emit::guard(Inter::Constant::new_numerical(&holdings_bookmark, Inter::SymbolsTables::id_from_IRS_and_symbol(&holdings_bookmark, symb), Inter::SymbolsTables::id_from_IRS_and_symbol(&holdings_bookmark, int_interk), LITERAL_IVAL, 0, Emit::baseline(&holdings_bookmark), NULL));
		Emit::annotate_symbol_i(symb, HOLDING_IANN, 1);
	}
	return symb;
}

inter_symbol *Emit::new_local_symbol(inter_symbol *rsymb, text_stream *name) {
	return Inter::SymbolsTables::create_with_unique_name(Inter::Package::local_symbols(rsymb), name);
}

void Emit::annotate_symbol_t(inter_symbol *symb, inter_t annot_ID, text_stream *S) {
	Inter::Symbols::annotate_t(Emit::repository(), symb, annot_ID, S);
}

void Emit::annotate_symbol_w(inter_symbol *symb, inter_t annot_ID, wording W) {
	TEMPORARY_TEXT(temp);
	WRITE_TO(temp, "%W", W);
	Inter::Symbols::annotate_t(Emit::repository(), symb, annot_ID, temp);
	DISCARD_TEXT(temp);
}

void Emit::annotate_symbol_i(inter_symbol *symb, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(Emit::repository(), symb, annot_ID, V);
}

void Emit::annotate_iname_i(inter_name *N, inter_t annot_ID, inter_t V) {
	Inter::Symbols::annotate_i(Emit::repository(), InterNames::to_symbol(N), annot_ID, V);
}

void Emit::guard(inter_error_message *ERR) {
	if ((ERR) && (problem_count == 0)) { Inter::Errors::issue(ERR); /* internal_error("inter error"); */ }
}

void Emit::kind(inter_name *iname, inter_t TID, inter_name *super,
	int constructor, int arity, kind **operand_kinds) {
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *S = InterNames::to_symbol(iname);
	inter_t SID = 0;
	if (S) SID = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), S);
	inter_symbol *SS = (super)?InterNames::to_symbol(super):NULL;
	inter_t SUP = 0;
	if (SS) SUP = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), SS);
	inter_t operands[MAX_KIND_ARITY];
	if (arity > MAX_KIND_ARITY) internal_error("kind arity too high");
	for (int i=0; i<arity; i++) {
		if (operand_kinds[i] == K_nil) operands[i] = 0;
		else {
			inter_symbol *S = Emit::kind_to_symbol(operand_kinds[i]);
			operands[i] = Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), S);
		}
	}
	Emit::kind_inner(SID, TID, SUP, constructor, arity, operands);
	InterNames::to_symbol(iname);
	Packaging::exit(save);
}

void Emit::kind_inner(inter_t SID, inter_t TID, inter_t SUP,
	int constructor, int arity, inter_t *operands) {
	Emit::guard(Inter::Kind::new(Packaging::at(), SID, TID, SUP, constructor, arity, operands, Emit::baseline(Packaging::at()), NULL));
}

inter_symbol *Emit::variable(inter_name *name, kind *K, inter_t v1, inter_t v2, text_stream *rvalue) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *var_name = Emit::define_symbol(name);
	inter_symbol *var_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::Variable::new(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), var_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), var_kind), v1, v2, Emit::baseline(Packaging::at()), NULL));
	if (rvalue) Emit::annotate_symbol_i(var_name, EXPLICIT_VARIABLE_IANN, 1);
	Packaging::exit(save);
	return var_name;
}

void Emit::marker(text_stream *mark) {
	inter_symbol *mark_name = Emit::new_symbol(Emit::main_scope(), Str::duplicate(mark));
	Emit::guard(Inter::Marker::new(Packaging::at(), mark_name, Emit::baseline(Packaging::at()), NULL));
}

void Emit::property(inter_name *name, kind *K) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *prop_name = Emit::define_symbol(name);
	inter_symbol *prop_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::Property::new(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), prop_kind), Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::permission(property *prn, kind *K, inter_name *name) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_name *prop_name = Properties::iname(prn);
	inter_symbol *owner_kind = Emit::kind_to_symbol(K);
	inter_symbol *store = (name)?InterNames::to_symbol(name):NULL;
	Emit::basic_permission(Packaging::at(), prop_name, owner_kind, store);
	Packaging::exit(save);
}

void Emit::instance_permission(property *prn, inter_name *inst_iname) {
	inter_name *prop_name = Properties::iname(prn);
	inter_symbol *inst_name = InterNames::to_symbol(inst_iname);
	packaging_state save = Packaging::enter_home_of(inst_iname);
	Emit::basic_permission(Packaging::at(), prop_name, inst_name, NULL);
	Packaging::exit(save);
}

int ppi7_counter = 0;
void Emit::basic_permission(inter_reading_state *at, inter_name *name, inter_symbol *owner_name, inter_symbol *store) {
	inter_symbol *prop_name = Emit::define_symbol(name);
	inter_error_message *E = NULL;
	TEMPORARY_TEXT(ident);
	WRITE_TO(ident, "pp_i7_%d", ppi7_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(NULL, Inter::Bookmarks::scope(at), ident, &E);
	DISCARD_TEXT(ident);
	Emit::guard(E);
	Emit::guard(Inter::Permission::new(at,
		Inter::SymbolsTables::id_from_IRS_and_symbol(at, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(at, owner_name), Inter::SymbolsTables::id_from_IRS_and_symbol(at, pp_name), (store)?(Inter::SymbolsTables::id_from_IRS_and_symbol(at, store)):0, Emit::baseline(at), NULL));
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
	inter_symbol *owner_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::DefaultValue::new(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), owner_kind), v1, v2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::propertyvalue(property *P, kind *K, inter_t v1, inter_t v2) {
	Properties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(Properties::iname(P));
	inter_symbol *owner_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::PropertyValue::new(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), owner_kind), v1, v2, Emit::baseline(Packaging::at()), NULL));
}

void Emit::instance_propertyvalue(property *P, instance *I, inter_t v1, inter_t v2) {
	Properties::emit_single(P);
	inter_symbol *prop_name = InterNames::to_symbol(Properties::iname(P));
	inter_symbol *owner_kind = InterNames::to_symbol(Instances::emitted_iname(I));
	Emit::guard(Inter::PropertyValue::new(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), owner_kind), v1, v2, Emit::baseline(Packaging::at()), NULL));
}

void Emit::named_string_constant(inter_name *name, text_stream *contents) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), contents);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::guard(Inter::Constant::new_textual(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), string_interk), ID, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::metadata(package_request *P, text_stream *key, text_stream *value) {
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), value);
	inter_name *iname = InterNames::explicitly_named(key, P);
	inter_symbol *key_name = Emit::define_symbol(iname);
	packaging_state save = Packaging::enter_home_of(iname);
	Emit::guard(Inter::Metadata::new(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), key_name), ID, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::instance(inter_name *name, kind *K, int v) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *inst_name = Emit::define_symbol(name);
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	inter_t v1 = LITERAL_IVAL, v2 = (inter_t) v;
	if (v == 0) { v1 = UNDEF_IVAL; v2 = 0; }
	Emit::guard(Inter::Instance::new(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), inst_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), val_kind), v1, v2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::named_generic_constant_xiname(package_request *PR, inter_name *name, inter_name *xiname) {
	inter_t v1 = 0, v2 = 0;
	Inter::Symbols::to_data(Emit::repository(), Packaging::incarnate(PR), InterNames::to_symbol(xiname), &v1, &v2);
	Emit::named_generic_constant(name, v1, v2);
}

void Emit::named_generic_constant(inter_name *name, inter_t val1, inter_t val2) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_interk), val1, val2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

inter_name *Emit::named_numeric_constant(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
	return name;
}

void Emit::hold_numeric_constant(inter_name *name, inter_t val) {
	inter_symbol *con_name = InterNames::to_symbol(name);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
}

void Emit::named_text_constant(inter_name *name, text_stream *content) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	inter_t v1 = 0, v2 = 0;
	Emit::text_value(&v1, &v2, content);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), v1, v2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::named_pseudo_numeric_constant(inter_name *name, kind *K, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), val_kind), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

void Emit::ds_named_pseudo_numeric_constant(inter_name *name, kind *K, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), val_kind), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
}

packaging_state Emit::named_late_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Emit::annotate_iname_i(name, LATE_IANN, 1);
	return save;
}

packaging_state Emit::named_byte_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Emit::annotate_iname_i(name, BYTEARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_table_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Emit::annotate_iname_i(name, TABLEARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_string_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Emit::annotate_iname_i(name, STRINGARRAY_IANN, 1);
	return save;
}

packaging_state Emit::named_verb_array_begin(inter_name *name, kind *K) {
	packaging_state save = Emit::named_array_begin(name, K);
	Emit::annotate_iname_i(name, VERBARRAY_IANN, 1);
	Emit::annotate_iname_i(name, LATE_IANN, 1);
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

		current_A->entry_data1 = Memory::I7_calloc(M, sizeof(inter_t), EMIT_ARRAY_MREASON);
		current_A->entry_data2 = Memory::I7_calloc(M, sizeof(inter_t), EMIT_ARRAY_MREASON);

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
	inter_symbol *symb = Emit::define_symbol(N);
	Emit::push_array();
	if (K == NULL) K = K_value;
	current_A->entry_kind = K;
	current_A->array_name_symbol = symb;
	return save;
}

void Emit::array_iname_entry(inter_name *iname) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_symbol *alias;
	if (iname == NULL) alias = InterNames::to_symbol(Emit::nothing());
	else alias = InterNames::to_symbol(iname);
	inter_t val1 = 0, val2 = 0;
	inter_reading_state *IRS = Emit::array_IRS();
	Inter::Symbols::to_data(IRS->read_into, IRS->current_package, alias, &val1, &val2);
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
	inter_reading_state *IRS = Emit::array_IRS();
	Inter::Symbols::to_data(IRS->read_into, IRS->current_package, symb, &v1, &v2);
	Emit::add_entry(v1, v2);
}
#endif

void Emit::array_text_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Emit::text_value(&v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Emit::dword_value(&v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_plural_dword_entry(text_stream *content) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t v1 = 0, v2 = 0;
	Emit::plural_dword_value(&v1, &v2, content);
	Emit::add_entry(v1, v2);
}

void Emit::array_numeric_entry(inter_t N) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	Emit::add_entry(LITERAL_IVAL, N);
}

void Emit::array_divider(text_stream *divider_text) {
	if (current_A == NULL) internal_error("entry outside of inter array");
	inter_t S = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), S), divider_text);
	Emit::add_entry(DIVIDER_IVAL, S);
}

inter_reading_state *Emit::array_IRS(void) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_reading_state *IRS = Packaging::at();
	return IRS;
}

void Emit::array_end(packaging_state save) {
	if (current_A == NULL) internal_error("inter array not opened");
	inter_symbol *con_name = current_A->array_name_symbol;
	inter_reading_state *IRS = Packaging::at();
	kind *K = current_A->entry_kind;
	inter_t CID = 0;
	if (K) {
		inter_symbol *con_kind = NULL;
		if (current_A->array_form == CONSTANT_INDIRECT_LIST)
			con_kind = Emit::kind_to_symbol(Kinds::unary_construction(CON_list_of, K));
		else
			con_kind = Emit::kind_to_symbol(K);
		CID = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind);
	} else {
		CID = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, unchecked_interk);
	}
	inter_frame array_in_progress =
		Inter::Frame::fill_3(IRS, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), CID, current_A->array_form, NULL, Emit::baseline(IRS));
	int pos = array_in_progress.extent;
	if (Inter::Frame::extend(&array_in_progress, (unsigned int) (2*current_A->no_entries)) == FALSE)
		internal_error("can't extend frame");
	for (int i=0; i<current_A->no_entries; i++) {
		array_in_progress.data[pos++] = current_A->entry_data1[i];
		array_in_progress.data[pos++] = current_A->entry_data2[i];
	}
	Emit::guard(Inter::Defn::verify_construct(array_in_progress));
	Inter::Frame::insert(array_in_progress, Packaging::at());
	Emit::pull_array();
	Packaging::exit(save);
}

inter_name *nothing_iname = NULL;
inter_name *Emit::nothing(void) {
	if (K_object == NULL) internal_error("too soon for nothing");
	if (nothing_iname == NULL) {
		nothing_iname = Hierarchy::find(NOTHING_HL);
		packaging_state save = Packaging::enter_home_of(nothing_iname);
		Emit::named_pseudo_numeric_constant(nothing_iname, K_object, 0);
		Packaging::exit(save);
	}
	return nothing_iname;
}

inter_name *Emit::named_iname_constant(inter_name *name, kind *K, inter_name *iname) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	inter_symbol *alias = (iname)?InterNames::to_symbol(iname):NULL;
	if (alias == NULL) {
		if (Kinds::Compare::le(K, K_object)) alias = InterNames::to_symbol(Emit::nothing());
		else internal_error("can't handle a null alias");
	}
	inter_t val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Packaging::at()->read_into, Packaging::at()->current_package, alias, &val1, &val2);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), val_kind), val1, val2, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
	return name;
}

inter_name *Emit::named_numeric_constant_hex(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::annotate_symbol_i(con_name, HEX_IANN, 0);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
	return name;
}

inter_name *Emit::named_unchecked_constant_hex(inter_name *name, inter_t val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::annotate_symbol_i(con_name, HEX_IANN, 0);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), unchecked_interk), LITERAL_IVAL, val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
	return name;
}

inter_name *Emit::named_numeric_constant_signed(inter_name *name, int val) {
	packaging_state save = Packaging::enter_home_of(name);
	inter_symbol *con_name = Emit::define_symbol(name);
	Emit::annotate_symbol_i(con_name, SIGNED_IANN, 0);
	Emit::guard(Inter::Constant::new_numerical(Packaging::at(), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), int_interk), LITERAL_IVAL, (inter_t) val, Emit::baseline(Packaging::at()), NULL));
	Packaging::exit(save);
	return name;
}

inter_symbol *current_inter_routine = NULL;
inter_reading_state current_inter_reading_state;
inter_reading_state locals_bookmark;
inter_reading_state begin_bookmark;
inter_reading_state code_bookmark;

void Emit::early_comment(text_stream *text) {
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), text);
	Emit::guard(Inter::Comment::new(Packaging::at(), Emit::baseline(Packaging::at()) + 1, NULL, ID));
}

void Emit::code_comment(text_stream *text) {
	inter_t ID = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID), text);
	Emit::guard(Inter::Comment::new(Emit::at(), (inter_t) Emit::level(), NULL, ID));
}

inter_symbol *Emit::package(inter_name *iname, inter_symbol *ptype, inter_package **P) {
	inter_t B = Emit::baseline(Packaging::at());
	inter_symbol *rsymb = Emit::define_symbol(iname);
	if (ptype == NULL) internal_error("no package type");
	inter_package *IP = NULL;
	Emit::guard(Inter::Package::new_package(Packaging::at(), rsymb, ptype, B, NULL, &IP));
	if (IP) {
		IP->I7_baseline = B+1;
		Inter::Defn::set_current_package(Packaging::at(), IP);
		if (P) *P = IP;
	}
	return rsymb;
}

inter_symbol *Emit::block(packaging_state *save, inter_name *iname) {
	if (current_inter_routine) internal_error("nested routines");
	if (Packaging::at() == NULL) internal_error("no inter repository");

	if (save) {
		*save = Packaging::enter_home_of(iname);
		package_request *R = InterNames::location(iname);
		if ((R == NULL) || (R == Hierarchy::main())) {
			LOG("Routine outside of package: %n\n", iname);
			internal_error("routine outside of package");
		}
	}

	inter_name *block_iname = NULL;
	if (Packaging::housed_in_function(iname))
		block_iname = Hierarchy::make_block_iname(InterNames::location(iname));
	else internal_error("routine outside function package");
	inter_symbol *rsymb = Emit::package(block_iname, code_packagetype, NULL);

	current_inter_routine = rsymb;
	current_inter_reading_state = Emit::bookmark();
	locals_bookmark = current_inter_reading_state;
	Emit::place_label(Emit::reserve_label(I".begin"), FALSE);
	begin_bookmark = Emit::bookmark();
	Emit::early_comment(I"body:");
	code_bookmark = Emit::bookmark();
	Emit::place_label(Emit::reserve_label(I".end"), FALSE);
	code_insertion_point cip = Emit::new_cip(&code_bookmark);
	Emit::push_code_position(cip);
	return rsymb;
}

inter_name *Emit::kernel(inter_name *public_name) {
	if (Packaging::housed_in_function(public_name) == FALSE)
		internal_error("routine not housed in function");
	return Hierarchy::make_kernel_iname(InterNames::location(public_name));
}

void Emit::end_main_block(packaging_state save) {
	Packaging::exit(save);
}

void Emit::routine(inter_name *rname, kind *rkind, inter_symbol *block_name) {
	if (Packaging::at() == NULL) internal_error("no inter repository");
	inter_symbol *AB_symbol = Emit::kind_to_symbol(rkind);
	inter_symbol *rsymb = Emit::define_symbol(rname);
	Emit::guard(Inter::Constant::new_function(Packaging::at(),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), rsymb),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), AB_symbol),
		Inter::SymbolsTables::id_from_IRS_and_symbol(Packaging::at(), block_name),
		Emit::baseline(Packaging::at()), NULL));
}

inter_symbol *Emit::reserve_label(text_stream *lname) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_symbol *lab_name = Emit::local_exists(lname);
	if (lab_name) return lab_name;
	lab_name = Emit::new_local_symbol(current_inter_routine, lname);
	Inter::Symbols::label(lab_name);
	return lab_name;
}

void Emit::place_label(inter_symbol *lab_name, int inside) {
	if (inside) {
		Emit::guard(Inter::Label::new(Emit::at(), current_inter_routine, lab_name, (inter_t) Emit::level(), NULL));
	} else {
		Emit::guard(Inter::Label::new(Packaging::at(), current_inter_routine, lab_name, Emit::baseline(Packaging::at()) + 1, NULL));
	}
}

inter_symbol *Emit::local_exists(text_stream *lname) {
	return Inter::SymbolsTables::symbol_from_name(Inter::Package::local_symbols(current_inter_routine), lname);
}

inter_symbol *Emit::local(kind *K, text_stream *lname, inter_t annot, text_stream *comm) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	if (K == NULL) K = K_number;
	inter_symbol *loc_name = Emit::new_local_symbol(current_inter_routine, lname);
	inter_symbol *loc_kind = Emit::kind_to_symbol(K);
	inter_t ID = 0;
	if ((comm) && (Str::len(comm) > 0)) {
		ID = Inter::create_text(Emit::repository());
		Str::copy(Inter::get_text(Emit::repository(), ID), comm);
	}
	if (annot) Emit::annotate_symbol_i(loc_name, annot, 0);
	Inter::Symbols::local(loc_name);
	Emit::guard(Inter::Local::new(&locals_bookmark, current_inter_routine, loc_name, loc_kind, ID, Emit::baseline(&locals_bookmark) + 1, NULL));
	return loc_name;
}

void Emit::inv_primitive(inter_symbol *prim_symb) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	if ((prim_symb == switch_interp) ||
		(prim_symb == if_interp) ||
		(prim_symb == ifelse_interp) ||
		(prim_symb == for_interp) ||
		(prim_symb == while_interp) ||
		(prim_symb == objectloop_interp)) Emit::note_level(prim_symb);

	Emit::guard(Inter::Inv::new_primitive(Emit::at(), current_inter_routine, prim_symb, (inter_t) Emit::level(), NULL));
}

void Emit::inv_call(inter_symbol *prim_symb) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	Emit::guard(Inter::Inv::new_call(Emit::at(), current_inter_routine, prim_symb, (inter_t) Emit::level(), NULL));
}

void Emit::inv_call_iname(inter_name *iname) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_symbol *prim_symb = InterNames::to_symbol(iname);
	Emit::guard(Inter::Inv::new_call(Emit::at(), current_inter_routine, prim_symb, (inter_t) Emit::level(), NULL));
}

void Emit::inv_indirect_call(int arity) {
	switch (arity) {
		case 0: Emit::inv_primitive(indirect0_interp); break;
		case 1: Emit::inv_primitive(indirect1_interp); break;
		case 2: Emit::inv_primitive(indirect2_interp); break;
		case 3: Emit::inv_primitive(indirect3_interp); break;
		case 4: Emit::inv_primitive(indirect4_interp); break;
		default: internal_error("indirect function call with too many arguments");
	}
}

void Emit::inv_assembly(text_stream *opcode) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_t SID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), SID);
	Str::copy(glob_storage, opcode);
	Emit::guard(Inter::Inv::new_assembly(Emit::at(), current_inter_routine, SID, (inter_t) Emit::level(), NULL));
}

void Emit::return(kind *K, inter_name *iname) {
	Emit::inv_primitive(return_interp);
	Emit::down();
	Emit::val_iname(K, iname);
	Emit::up();
}

void Emit::rtrue(void) {
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, 1); /* that is, return "true" */
	Emit::up();
}

void Emit::rfalse(void) {
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, 0); /* that is, return "false" */
	Emit::up();
}

void Emit::push(kind *K, inter_name *iname) {
	Emit::inv_primitive(push_interp);
	Emit::down();
	Emit::val_iname(K, iname);
	Emit::up();
}

void Emit::pull(kind *K, inter_name *iname) {
	Emit::inv_primitive(pull_interp);
	Emit::down();
	Emit::ref_iname(K, iname);
	Emit::up();
}

@

@d MAX_NESTED_NOTEWORTHY_LEVELS 256
@d MAX_CIP_STACK_SIZE 2

=
typedef struct code_insertion_point {
	int inter_level;
	int noted_levels[MAX_NESTED_NOTEWORTHY_LEVELS];
	int noted_sp;
	int error_flag;
	inter_reading_state *insertion_bm;
} code_insertion_point;

code_insertion_point cip_stack[MAX_CIP_STACK_SIZE];
int cip_sp = 0;

code_insertion_point Emit::new_cip(inter_reading_state *IRS) {
	code_insertion_point cip;
	cip.inter_level = (int) (Emit::baseline(IRS) + 2);
	cip.noted_sp = 2;
	cip.error_flag = FALSE;
	cip.insertion_bm = IRS;
	return cip;
}

code_insertion_point Emit::begin_position(void) {
	code_insertion_point cip = Emit::new_cip(&begin_bookmark);
	return cip;
}

void Emit::push_code_position(code_insertion_point cip) {
	if (cip_sp >= MAX_CIP_STACK_SIZE) internal_error("CIP overflow");
	cip_stack[cip_sp++] = cip;
}

int Emit::level(void) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	return cip->inter_level;
}

void Emit::set_level(int N) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (N < 2) {
		if (problem_count == 0) cip->error_flag = TRUE;
		N = 2;
	}
	while (cip->noted_sp > 0) {
		if (cip->noted_levels[cip->noted_sp-1] < N) break;
		cip->noted_sp--;
	}
	cip->inter_level = N;
}

void Emit::note_level(inter_symbol *from) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (cip->noted_sp >= MAX_NESTED_NOTEWORTHY_LEVELS) return;
	cip->noted_levels[cip->noted_sp++] = Emit::level();
}

void Emit::to_last_level(int delta) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	code_insertion_point *cip = &cip_stack[cip_sp-1];
	if (cip->noted_sp <= 0) {
		if (problem_count == 0) cip->error_flag = TRUE;
	} else {
		Emit::set_level(cip->noted_levels[cip->noted_sp-1] + delta);
	}
}

inter_reading_state *Emit::at(void) {
	if (cip_sp <= 0) internal_error("CIP level accessed outside routine");
	return cip_stack[cip_sp-1].insertion_bm;
}

void Emit::down(void) {
	Emit::set_level(Emit::level() + 1);
	if (trace_inter_insertion) LOG("Down to %d\n", Emit::level());
}

void Emit::up(void) {
	Emit::set_level(Emit::level() - 1);
	if (trace_inter_insertion) LOG("Up to %d\n", Emit::level());
}

void Emit::pop_code_position(void) {
	if (cip_sp <= 0) internal_error("CIP underflow");
	if (cip_stack[cip_sp-1].error_flag) {
		internal_error("bad inter hierarchy");
	}
	cip_sp--;
}

void Emit::code(void) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	Emit::guard(Inter::Code::new(Emit::at(), current_inter_routine, Emit::level(), NULL));
}

void Emit::evaluation(void) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	Emit::guard(Inter::Evaluation::new(Emit::at(), current_inter_routine, Emit::level(), NULL));
}

void Emit::reference(void) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	Emit::guard(Inter::Reference::new(Emit::at(), current_inter_routine, Emit::level(), NULL));
}

void Emit::val(kind *K, inter_t val1, inter_t val2) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for val");
	Emit::guard(Inter::Val::new(Emit::at(), current_inter_routine, val_kind, Emit::level(), val1, val2, NULL));
}

void Emit::val_nothing(void) {
	Emit::val(K_number, LITERAL_IVAL, 0);
}

void Emit::lab(inter_symbol *L) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	Emit::guard(Inter::Lab::new(Emit::at(), current_inter_routine, L, (inter_t) Emit::level(), NULL));
}

void Emit::ref(kind *K, inter_t val1, inter_t val2) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	inter_symbol *val_kind = Emit::kind_to_symbol(K);
	if (val_kind == NULL) internal_error("no kind for ref");
	Emit::guard(Inter::Ref::new(Emit::at(), current_inter_routine, val_kind, Emit::level(), val1, val2, NULL));
}

void Emit::val_iname(kind *K, inter_name *iname) {
	if (iname == NULL) {
		if (problem_count == 0) internal_error("no iname");
		else Emit::val(K_value, LITERAL_IVAL, 0);
	} else {
		Emit::val_symbol(K, InterNames::to_symbol(iname));
	}
}

void Emit::val_symbol(kind *K, inter_symbol *s) {
	inter_t val1 = 0, val2 = 0;
	inter_reading_state *IRS = Packaging::at();
	Inter::Symbols::to_data(IRS->read_into, IRS->current_package, s, &val1, &val2);
	Emit::val(K, val1, val2);
}

void Emit::val_text(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Emit::text_value(&v1, &v2, S);
	Emit::val(K_value, v1, v2);
}

void Emit::val_char(wchar_t c) {
	Emit::val(K_number, LITERAL_IVAL, (inter_t) c);
}

void Emit::val_real(double g) {
	inter_t v1 = 0, v2 = 0;
	Emit::real_value(&v1, &v2, g);
	Emit::val(K_real_number, v1, v2);
}

void Emit::val_real_from_text(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Emit::real_value_from_text(&v1, &v2, S);
	Emit::val(K_real_number, v1, v2);
}

void Emit::val_dword(text_stream *S) {
	inter_t v1 = 0, v2 = 0;
	Emit::dword_value(&v1, &v2, S);
	Emit::val(K_value, v1, v2);
}

void Emit::ref_iname(kind *K, inter_name *iname) {
	Emit::ref_symbol(K, InterNames::to_symbol(iname));
}

void Emit::ref_symbol(kind *K, inter_symbol *s) {
	inter_t val1 = 0, val2 = 0;
	inter_reading_state *IRS = Packaging::at();
	Inter::Symbols::to_data(IRS->read_into, IRS->current_package, s, &val1, &val2);
	Emit::ref(K, val1, val2);
}

void Emit::cast(kind *F, kind *T) {
	inter_symbol *from_kind = Emit::kind_to_symbol(F);
	inter_symbol *to_kind = Emit::kind_to_symbol(T);
	Emit::guard(Inter::Cast::new(Emit::at(), current_inter_routine, from_kind, to_kind, (inter_t) Emit::level(), NULL));
}

void Emit::end_block(inter_symbol *rsymb) {
	if (current_inter_routine == NULL) internal_error("not in an inter routine");
	if (current_inter_routine != rsymb) internal_error("wrong inter routine ended");
	Emit::guard(Inter::Defn::pass2(Emit::repository(), FALSE, &current_inter_reading_state, TRUE, (int) Emit::baseline(&current_inter_reading_state)));
	current_inter_routine = NULL;
	Emit::pop_code_position();
	inter_reading_state *IRS = Packaging::at();
	IRS->current_package = IRS->current_package->parent_package;
}

int Emit::emitting_routine(void) {
	if (current_inter_routine) return TRUE;
	return FALSE;
}

text_stream *current_splat = NULL;

text_stream *Emit::begin_splat(void) {
	Emit::end_splat();
	if (current_splat == NULL) current_splat = Str::new();
	return current_splat;
}

void Emit::end_splat(void) {
	if (current_splat) {
		int L = Str::len(current_splat);
		if ((L > 1) ||
			((L == 1) && (Str::get_first_char(current_splat) != '\n'))) {
			Emit::entire_splat(current_splat, 0);
		}
		Str::clear(current_splat);
	}
}

void Emit::entire_splat(text_stream *content, inter_t level) {
	if (Str::len(content) == 0) return;
	inter_t SID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), SID);
	Str::copy(glob_storage, content);

	if (level > Emit::baseline(Packaging::at())) {
		Emit::guard(Inter::Splat::new(Emit::at(), current_inter_routine, SID, 0, level, 0, NULL));
	} else {
		Emit::guard(Inter::Splat::new(Packaging::at(), current_inter_routine, SID, 0, level, 0, NULL));
	}
}

void Emit::entire_splat_code(text_stream *content) {
	Emit::entire_splat(content, (inter_t) Emit::level());
}

void Emit::write_bytecode(filename *F) {
	if (Packaging::at() == NULL) internal_error("no inter repository");
	Inter::Binary::write(F, Emit::repository());
}

void Emit::glob_value(inter_t *v1, inter_t *v2, text_stream *glob, char *clue) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), ID);
	Str::copy(glob_storage, glob);
	*v1 = GLOB_IVAL;
	*v2 = ID;
	LOG("Glob (I7/%s): %S\n", clue, glob);
	glob_count++;
}

void Emit::text_value(inter_t *v1, inter_t *v2, text_stream *text) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *text_storage = Inter::get_text(Emit::repository(), ID);
	Str::copy(text_storage, text);
	*v1 = LITERAL_TEXT_IVAL;
	*v2 = ID;
}

int Emit::glob_count(void) {
	return glob_count;
}

void Emit::real_value(inter_t *v1, inter_t *v2, double g) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), ID);
	if (g > 0) WRITE_TO(glob_storage, "+");
	WRITE_TO(glob_storage, "%g", g);
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Emit::real_value_from_text(inter_t *v1, inter_t *v2, text_stream *S) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(glob_storage, Str::get(pos));
	*v1 = REAL_IVAL;
	*v2 = ID;
}

void Emit::dword_value(inter_t *v1, inter_t *v2, text_stream *glob) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), ID);
	Str::copy(glob_storage, glob);
	*v1 = DWORD_IVAL;
	*v2 = ID;
}

void Emit::plural_dword_value(inter_t *v1, inter_t *v2, text_stream *glob) {
	inter_t ID = Inter::create_text(Emit::repository());
	text_stream *glob_storage = Inter::get_text(Emit::repository(), ID);
	Str::copy(glob_storage, glob);
	*v1 = PDWORD_IVAL;
	*v2 = ID;
}

void Emit::intervention(int stage, text_stream *segment, text_stream *part, text_stream *i6, text_stream *seg) {
	inter_t ID1 = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID1), segment);

	inter_t ID2 = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID2), part);

	inter_t ID3 = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID3), i6);

	inter_t ID4 = Inter::create_text(Emit::repository());
	Str::copy(Inter::get_text(Emit::repository(), ID4), seg);

	inter_t ref = Inter::create_ref(Emit::repository());
	Inter::set_ref(Emit::repository(), ref, (void *) current_sentence);

	Emit::guard(Inter::Link::new(Packaging::at(), (inter_t) stage, ID1, ID2, ID3, ID4, ref, Emit::baseline(Packaging::at()), NULL));
}

@ =


void Emit::change_translation(inter_name *iname, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(iname), new_text);
}

text_stream *Emit::get_translation(inter_name *iname) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(iname));
}

text_stream *Emit::to_text(inter_name *iname) {
	if (iname == NULL) return NULL;
	return InterNames::to_symbol(iname)->symbol_name;
}

inter_symbol *Emit::define_symbol(inter_name *iname) {
	InterNames::to_symbol(iname);
	if (iname->symbol) {
		if (Inter::Symbols::is_predeclared(iname->symbol)) {
			Inter::Symbols::undefine(iname->symbol);
		}
	}
	if ((iname->symbol) && (Inter::Symbols::read_annotation(iname->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(iname->symbol, DELENDA_EST_IANN) != 1) {
			Emit::annotate_symbol_i(iname->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(iname->symbol);
		}
		return iname->symbol;
	}
	return iname->symbol;
}

inter_symbol *Emit::destroy_symbol(inter_name *iname) {
	InterNames::to_symbol(iname);
	if (iname->symbol) {
		if (Inter::Symbols::is_predeclared(iname->symbol)) {
			Inter::Symbols::undefine(iname->symbol);
		}
	}
	if ((iname->symbol) && (Inter::Symbols::read_annotation(iname->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(iname->symbol, DELENDA_EST_IANN) != 1) {
			Emit::annotate_symbol_i(iname->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(iname->symbol);
		}
		return iname->symbol;
	} else if (Inter::Symbols::read_annotation(iname->symbol, DELENDA_EST_IANN) != 1) internal_error("Bang");
	return iname->symbol;
}

void Emit::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void Emit::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
}

void Emit::annotate_i(inter_name *iname, inter_t annot_ID, inter_t V) {
	if (iname) Emit::annotate_symbol_i(InterNames::to_symbol(iname), annot_ID, V);
}

void Emit::annotate_t(inter_name *iname, inter_t annot_ID, text_stream *text) {
	if (iname) Emit::annotate_symbol_t(InterNames::to_symbol(iname), annot_ID, text);
}

void Emit::annotate_w(inter_name *iname, inter_t annot_ID, wording W) {
	if (iname) Emit::annotate_symbol_w(InterNames::to_symbol(iname), annot_ID, W);
}

int Emit::read_annotation(inter_name *iname, inter_t annot) {
	return Inter::Symbols::read_annotation(InterNames::to_symbol(iname), annot);
}

void Emit::holster(value_holster *VH, inter_name *iname) {
	if (Holsters::data_acceptable(VH)) {
		inter_t v1 = 0, v2 = 0;
		Emit::to_ival(&v1, &v2, iname);
		Holsters::holster_pair(VH, v1, v2);
	}
}

void Emit::symbol_to_ival(inter_t *val1, inter_t *val2, inter_symbol *S) {
	inter_reading_state *IRS = Packaging::at();
	if (S) { Inter::Symbols::to_data(IRS->read_into, IRS->current_package, S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival(inter_t *val1, inter_t *val2, inter_name *iname) {
	inter_reading_state *IRS = Packaging::at();
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(IRS->read_into, IRS->current_package, S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

void Emit::to_ival_in_context(inter_name *context, inter_t *val1, inter_t *val2, inter_name *iname) {
	package_request *PR = InterNames::location(context);
	inter_package *pack = Packaging::incarnate(PR);
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(pack->stored_in, pack, S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

int Emit::defined(inter_name *iname) {
	if (iname == NULL) return FALSE;
	inter_symbol *S = InterNames::to_symbol(iname);
	if (Inter::Symbols::is_defined(S)) return TRUE;
	return FALSE;
}

typedef struct ival_emission {
	value_holster emission_VH;
	packaging_state saved_PS;
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
	Packaging::exit(IE->saved_PS);
}

package_request *Emit::current_enclosure(void) {
	return Packaging::enclosure();
}

packaging_state Emit::unused_packaging_state(void) {
	return Packaging::stateless();
}
