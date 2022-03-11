[Emit::] Emit.

"Emitting" is the process of generating Inter bytecode, and this section provides
a comprehensive API for the runtime and imperative modules to do that.

@h The emission tree.
The //bytecode// module can maintain multiple independent trees of Inter code
in memory, so that most calls to //bytecode// or //building// take an |inter_tree|
pointer as their first function argument. But //runtime// and //imperative// work
on just one single tree.

Calling |LargeScale::begin_new_tree| makes a minimum of package types,
creates the |main| package, and so on, but leaves the tree basically still empty.

=
inter_tree *main_emission_tree = NULL;

inter_tree *Emit::create_emission_tree(void) {
	main_emission_tree = InterTree::new();
	LargeScale::begin_new_tree(main_emission_tree);
	return main_emission_tree;
}
inter_tree *Emit::tree(void) {
	return main_emission_tree;
}

inter_ti Emit::symbol_id(inter_symbol *S) {
	return InterSymbolsTable::id_from_symbol_at_bookmark(Emit::at(), S);
}

inter_warehouse *Emit::warehouse(void) {
	return InterTree::warehouse(Emit::tree());
}

inter_bookmark *Emit::at(void) {
	return Packaging::at(Emit::tree());
}

inter_ti Emit::baseline(void) {
	return Produce::baseline(Emit::at());
}

inter_package *Emit::package(void) {
	return InterBookmark::package(Emit::at());
}

package_request *Emit::current_enclosure(void) {
	return Packaging::enclosure(Emit::tree());
}

packaging_state Emit::new_packaging_state(void) {
	return Packaging::stateless();
}

@h Data as pairs of Inter bytes.
A single data value is stored in Inter bytecode as two consecutive words:
see //bytecode// for more on this. This means we sometimes deal with a doublet
of |inter_ti| variables:

=
void Emit::holster_iname(value_holster *VH, inter_name *iname) {
	if (Holsters::value_pair_allowed(VH)) {
		if (iname == NULL) internal_error("no iname to holster");
		Holsters::holster_pair(VH, Emit::to_value_pair(iname));
	}
}

@ A subtlety here is that the encoding of a symbol into a doublet depends on
what package it belongs to, the "context" referred to below:

=
inter_pair Emit::symbol_to_value_pair(inter_symbol *S) {
	return Emit::stvp_inner(S, InterBookmark::package(Emit::at()));
}

inter_pair Emit::to_value_pair(inter_name *iname) {
	return Emit::stvp_inner(InterNames::to_symbol(iname), InterBookmark::package(Emit::at()));
}

inter_pair Emit::to_value_pair_in_context(inter_name *context, inter_name *iname) {
	inter_package *pack = Packaging::incarnate(InterNames::location(context));
	inter_symbol *S = InterNames::to_symbol(iname);
	return Emit::stvp_inner(S, pack);
}

inter_pair Emit::stvp_inner(inter_symbol *S, inter_package *pack) {
	if (S) return InterValuePairs::symbolic_in(pack, S);
	return InterValuePairs::number(0);
}

@h Kinds.
Inter has a very simple, and non-binding, system of "typenames" -- a much simpler
system than Inform's hierarchy of kinds. Here we create a typename corresponding
to each kind whose data we will need to use in Inter. |super| is the superkind,
if any; |constructor| is one of the codes defined in //bytecode: Inter Data Types//;
the other three arguments are for kind constructors.

@d MAX_KIND_ARITY 128

=
void Emit::kind(inter_name *iname, inter_name *super,
	inter_ti constructor, int arity, kind **operand_kinds) {
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
		else operands[i] = Produce::kind_to_TID(Emit::at(), operand_kinds[i]);
	}
	Emit::kind_inner(SID, SUP, constructor, arity, operands);
	InterNames::to_symbol(iname);
	Packaging::exit(Emit::tree(), save);
}

@ The above both use:

=
void Emit::kind_inner(inter_ti SID, inter_ti SUP,
	inter_ti constructor, int arity, inter_ti *operands) {
	Produce::guard(TypenameInstruction::new(Emit::at(), SID, constructor, SUP, arity,
		operands, Emit::baseline(), NULL));
}

@ Default values for kinds are emitted thus. This is inefficient and maybe ought
to be replaced by a hash, but the list is short and the function is called
so little that it probably makes little difference.

=
linked_list *default_values_written = NULL;

void Emit::ensure_defaultvalue(kind *K) {
	if (K == K_value) return;
	if (default_values_written == NULL) default_values_written = NEW_LINKED_LIST(kind);
	kind *L;
	LOOP_OVER_LINKED_LIST(L, kind, default_values_written)
		if (Kinds::eq(K, L))
			return;
	ADD_TO_LINKED_LIST(K, kind, default_values_written);
	inter_pair def_val = DefaultValues::to_value_pair(K);
	if (InterValuePairs::is_undef(def_val) == FALSE) {
		packaging_state save = Packaging::enter(RTKindConstructors::kind_package(K));
		Produce::guard(DefaultValueInstruction::new(Emit::at(),
			Produce::kind_to_symbol(K), def_val, Emit::baseline(), NULL));
		Packaging::exit(Emit::tree(), save);
	}
}

@h Pragmas.
The Inter language allows pragmas, or code-generation hints, to be passed
through. These are specific to the target of compilation, and can be ignored
by all other targets. Here we generate only I6-target pragmas, which are commands
in I6's "Inform Control Language".

=
void Emit::pragma(text_stream *text) {
	inter_tree *I = Emit::tree();
	LargeScale::emit_pragma(I, I"Inform6", text);
}

@h Constants.
These functions make it easy to define a named value in Inter. If the value is
an unsigned numeric constant, use one of these two functions -- the first if
it represents an actual number at run-time, the second if not:

=
inter_name *Emit::numeric_constant(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, INT32_ITCONC, INVALID_IANN);
}

inter_name *Emit::named_numeric_constant_hex(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, INT32_ITCONC, HEX_IANN);
}

inter_name *Emit::named_unchecked_constant_hex(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, UNCHECKED_ITCONC, HEX_IANN);
}

inter_name *Emit::named_numeric_constant_signed(inter_name *con_iname, int val) {
	return Emit::numeric_constant_inner(con_iname, (inter_ti) val, INT32_ITCONC, SIGNED_IANN);
}

inter_name *Emit::unchecked_numeric_constant(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, UNCHECKED_ITCONC, INVALID_IANN);
}

inter_name *Emit::numeric_constant_inner(inter_name *con_iname, inter_ti val,
	inter_ti constructor_code, inter_ti annotation) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	if (annotation != INVALID_IANN) SymbolAnnotation::set_b(con_s, annotation, 0);
	Produce::guard(ConstantInstruction::new(Emit::at(), con_s,
		InterTypes::from_constructor_code(constructor_code), InterValuePairs::number(val),
		Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return con_iname;
}

@ Text:

=
void Emit::text_constant(inter_name *con_iname, text_stream *contents) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	Produce::guard(ConstantInstruction::new(Emit::at(), con_s,
		InterTypes::from_constructor_code(TEXT_ITCONC),
		InterValuePairs::from_text(Emit::at(), contents), Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@ And equating one constant to another named constant:

=
inter_name *Emit::iname_constant(inter_name *con_iname, kind *K, inter_name *val_iname) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	inter_symbol *val_s = (val_iname)?InterNames::to_symbol(val_iname):NULL;
	if (val_s == NULL) {
		if (Kinds::Behaviour::is_object(K))
			val_s = InterNames::to_symbol(Hierarchy::find(NOTHING_HL));
		else
			internal_error("can't handle a null alias");
	}
	Produce::guard(ConstantInstruction::new(Emit::at(), con_s,
		Produce::kind_to_type(K), Emit::symbol_to_value_pair(val_s),
		Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return con_iname;
}

@ These two variants are needed only for the oddball way //Bibliographic Data//
is compiled.

=
void Emit::text_constant_from_wide_string(inter_name *con_iname, wchar_t *str) {
	inter_name *iname = TextLiterals::to_value(Feeds::feed_C_string(str));
	Emit::named_generic_constant(con_iname,
		Emit::to_value_pair_in_context(con_iname, iname));
}

void Emit::serial_number(inter_name *con_iname, text_stream *serial) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_pair val = InterValuePairs::from_text(Emit::at(), serial);
	Emit::named_generic_constant(con_iname, val);
	Packaging::exit(Emit::tree(), save);
}

@ Similarly, there are just a few occasions when we need to extract the value
of a "variable" and define it as a constant:

=
void Emit::initial_value_as_constant(inter_name *con_iname, nonlocal_variable *var) {
	Emit::named_generic_constant(con_iname,
		RTVariables::initial_value_as_pair(con_iname, var));
}

void Emit::initial_value_as_raw_text(inter_name *con_iname, nonlocal_variable *var) {
	wording W = NonlocalVariables::initial_value_as_plain_text(var);
	TEMPORARY_TEXT(CONTENT)
	BibliographicData::compile_bibliographic_text(CONTENT,
		Lexer::word_text(Wordings::first_wn(W)), XML_BIBTEXT_MODE);
	Emit::text_constant(con_iname, CONTENT);
	DISCARD_TEXT(CONTENT)
}

@ The above make use of this:

=
void Emit::named_generic_constant(inter_name *con_iname, inter_pair val) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = InterNames::to_symbol(con_iname);
	Produce::guard(ConstantInstruction::new(Emit::at(), con_s,
		InterTypes::unchecked(), val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@h Instances.

=
void Emit::instance(inter_name *inst_iname, kind *K, int v) {
	packaging_state save = Packaging::enter_home_of(inst_iname);
	inter_symbol *inst_s = InterNames::to_symbol(inst_iname);
	inter_pair val = v ? InterValuePairs::number((inter_ti) v) : InterValuePairs::undef();
	Produce::guard(InstanceInstruction::new(Emit::at(), inst_s,
		Produce::kind_to_symbol(K), val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@h Variables.

=
inter_symbol *Emit::variable(inter_name *var_iname, kind *K, inter_pair val) {
	packaging_state save = Packaging::enter_home_of(var_iname);
	inter_symbol *var_s = InterNames::to_symbol(var_iname);
	inter_type type = InterTypes::unchecked();
	if ((K) && (K != K_value))
		type = InterTypes::from_type_name(Produce::kind_to_symbol(K));
	Produce::guard(VariableInstruction::new(Emit::at(),
		Emit::symbol_id(var_s), type, val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return var_s;
}

@h Properties and permissions.

=
void Emit::property(inter_name *prop_iname, kind *K) {
	packaging_state save = Packaging::enter_home_of(prop_iname);
	inter_symbol *prop_s = InterNames::to_symbol(prop_iname);
	inter_type type = InterTypes::unchecked();
	if ((K) && (K != K_value))
		type = InterTypes::from_type_name(Produce::kind_to_symbol(K));
	Produce::guard(PropertyInstruction::new(Emit::at(),
		Emit::symbol_id(prop_s), type, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::permission(property *prn, inter_symbol *owner_s, inter_name *storage_iname) {
	inter_name *prop_iname = RTProperties::iname(prn);
	inter_symbol *store_s = (storage_iname)?InterNames::to_symbol(storage_iname):NULL;
	inter_symbol *prop_s = InterNames::to_symbol(prop_iname);
	Produce::guard(PermissionInstruction::new(Emit::at(), prop_s, owner_s, store_s,
		Emit::baseline(), NULL));
}

@h Property values.

=
void Emit::propertyvalue(property *P, inter_name *owner, inter_pair val) {
	inter_symbol *prop_s = InterNames::to_symbol(RTProperties::iname(P));
	inter_symbol *owner_s = InterNames::to_symbol(owner);
	Produce::guard(PropertyValueInstruction::new(Emit::at(), Emit::symbol_id(prop_s),
		Emit::symbol_id(owner_s), val, Emit::baseline(), NULL));
}

@h Private, keep out.
The following should be called only by //imperative: Functions//, which provides
the real API for starting and ending functions.

=
void Emit::function(inter_name *fn_iname, kind *K, inter_package *block) {
	if (Emit::at() == NULL) internal_error("no inter repository");
	inter_symbol *fn_s = InterNames::to_symbol(fn_iname);
	Produce::guard(ConstantInstruction::new(Emit::at(), fn_s,
		Produce::kind_to_type(K), InterValuePairs::functional(block),
		Emit::baseline(), NULL));
}

@h Interventions.
These should be used as little as possible, and perhaps it may one day be possible
to abolish them altogether. They insert direct kit material (i.e. paraphrased Inter
code written out as plain text in Inform 6 notation) into bytecode; this is then
assimilating during linking. Note that only the raw i6 is actually carried over
into bytecode; everything else specified in those old-fashioned I7 sentences
about where to include the code is ignored.

=
void Emit::intervention(int stage, text_stream *segment, text_stream *part,
	text_stream *i6, text_stream *seg) {
	Produce::guard(InsertInstruction::new(Emit::at(), i6, Emit::baseline(), NULL));
}

@ And this is a similarly inelegant construction:

=
void Emit::append(inter_name *iname, text_stream *text) {
	LOG("Append '%S'\n", text);
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symbol = InterNames::to_symbol(iname);
	Produce::guard(AppendInstruction::new(Emit::at(), symbol, text, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}
