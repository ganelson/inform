[Emit::] Emit.

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
	Packaging::incarnate(Packaging::get_unit(main_emission_tree, I"generic", I"_module")->the_package);
	Packaging::incarnate(Packaging::get_unit(main_emission_tree, I"synoptic", I"_module")->the_package);
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

inter_bookmark *Emit::at(void) {
	return Packaging::at(Emit::tree());
}

inter_ti Emit::baseline(void) {
	return Produce::baseline(Emit::at());
}

inter_package *Emit::package(void) {
	return Inter::Bookmarks::package(Emit::at());
}

package_request *Emit::current_enclosure(void) {
	return Packaging::enclosure(Emit::tree());
}

packaging_state Emit::new_packaging_state(void) {
	return Packaging::stateless();
}

inter_symbol *Emit::get_veneer_symbol(int id) {
	return Site::veneer_symbol(Emit::tree(), id);
}

@h Data as pairs of Inter bytes.
A single data value is stored in Inter bytecode as two consecutive words:
see //bytecode// for more on this. This means we sometimes deal with a doublet
of |inter_ti| variables:

=
void Emit::holster_iname(value_holster *VH, inter_name *iname) {
	if (Holsters::non_void_context(VH)) {
		if (iname == NULL) internal_error("no iname to holster");
		inter_ti v1 = 0, v2 = 0;
		Emit::to_value_pair(&v1, &v2, iname);
		Holsters::holster_pair(VH, v1, v2);
	}
}

@ A subtlety here is that the encoding of a symbol into a doublet depends on
what package it belongs to, the "context" referred to below:

=
void Emit::symbol_to_value_pair(inter_ti *v1, inter_ti *v2, inter_symbol *S) {
	Emit::stvp_inner(S, v1, v2, Inter::Bookmarks::package(Emit::at()));
}

void Emit::to_value_pair(inter_ti *v1, inter_ti *v2, inter_name *iname) {
	Emit::stvp_inner(InterNames::to_symbol(iname), v1, v2, Inter::Bookmarks::package(Emit::at()));
}

void Emit::to_value_pair_in_context(inter_name *context, inter_ti *v1, inter_ti *v2,
	inter_name *iname) {
	inter_package *pack = Packaging::incarnate(InterNames::location(context));
	inter_symbol *S = InterNames::to_symbol(iname);
	Emit::stvp_inner(S, v1, v2, pack);
}

void Emit::stvp_inner(inter_symbol *S, inter_ti *v1, inter_ti *v2,
	inter_package *pack) {
	if (S) {
		Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, S, v1, v2);
		return;
	}
	*v1 = LITERAL_IVAL; *v2 = 0;
}

@h Kinds.
Inter has a very simple, and non-binding, system of "kinds" -- a much simpler
one than Inform. We need symbols to refer to some basic Inter kinds, and here they are.

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

@ This emits a more general Inter kind, and is used by //Runtime Support for Kinds//.
Here |idt| is one of the |*_IDT| constants expressing what actual data is held;
|super| is the superkind, if any; the other three arguments are for kind
constructors.

=
void Emit::kind(inter_name *iname, inter_ti idt, inter_name *super,
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
	Emit::kind_inner(SID, idt, SUP, constructor, arity, operands);
	InterNames::to_symbol(iname);
	Packaging::exit(Emit::tree(), save);
}

@ The above both use:

=
void Emit::kind_inner(inter_ti SID, inter_ti idt, inter_ti SUP,
	int constructor, int arity, inter_ti *operands) {
	Produce::guard(Inter::Kind::new(Emit::at(), SID, idt, SUP, constructor, arity,
		operands, Emit::baseline(), NULL));
}

@ Default values for kinds are emitted thus. This is inefficient, but is called
so little that it doesn't matter.

=
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
	if (dw->v1 != 0) {
		packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
		inter_symbol *owner_kind = Produce::kind_to_symbol(K);
		Produce::guard(Inter::DefaultValue::new(Emit::at(),
			Emit::symbol_id(owner_kind), dw->v1, dw->v2, Emit::baseline(), NULL));
		Packaging::exit(Emit::tree(), save);
	}
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
inter_name *Emit::numeric_constant(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, int_interk, INVALID_IANN);
}

inter_name *Emit::named_numeric_constant_hex(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, int_interk, HEX_IANN);
}

inter_name *Emit::named_unchecked_constant_hex(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, unchecked_interk, HEX_IANN);
}

inter_name *Emit::named_numeric_constant_signed(inter_name *con_iname, int val) {
	return Emit::numeric_constant_inner(con_iname, (inter_ti) val, int_interk, SIGNED_IANN);
}

inter_name *Emit::unchecked_numeric_constant(inter_name *con_iname, inter_ti val) {
	return Emit::numeric_constant_inner(con_iname, val, unchecked_interk, INVALID_IANN);
}

inter_name *Emit::numeric_constant_inner(inter_name *con_iname, inter_ti val,
	inter_symbol *kind_s, inter_ti annotation) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	if (annotation != INVALID_IANN) Produce::annotate_symbol_i(con_s, annotation, 0);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_s),
		Emit::symbol_id(kind_s), LITERAL_IVAL, val, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return con_iname;
}

@ Text:

=
void Emit::text_constant(inter_name *con_iname, text_stream *contents) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(),
		Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), contents);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	Produce::guard(Inter::Constant::new_textual(Emit::at(), Emit::symbol_id(con_s),
		Emit::symbol_id(string_interk), ID, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@ And equating one constant to another named constant:

=
inter_name *Emit::iname_constant(inter_name *con_iname, kind *K, inter_name *val_iname) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	inter_symbol *val_s = (val_iname)?InterNames::to_symbol(val_iname):NULL;
	if (val_s == NULL) {
		if (Kinds::Behaviour::is_object(K))
			val_s = Emit::get_veneer_symbol(NOTHING_VSYMB);
		else
			internal_error("can't handle a null alias");
	}
	inter_ti v1 = 0, v2 = 0;
	Emit::symbol_to_value_pair(&v1, &v2, val_s);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_s),
		Emit::symbol_id(kind_s), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return con_iname;
}

@ These two variants are needed only for the oddball way //Bibliographic Data//
is compiled.

=
void Emit::text_constant_from_wide_string(inter_name *con_iname, wchar_t *str) {
	inter_ti v1 = 0, v2 = 0;
	inter_name *iname = TextLiterals::to_value(Feeds::feed_C_string(str));
	Emit::to_value_pair_in_context(con_iname, &v1, &v2, iname);
	Emit::named_generic_constant(con_iname, v1, v2);
}

void Emit::serial_number(inter_name *con_iname, text_stream *serial) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_ti v1 = 0, v2 = 0;
	Produce::text_value(Emit::tree(), &v1, &v2, serial);
	Emit::named_generic_constant(con_iname, v1, v2);
	Packaging::exit(Emit::tree(), save);
}

@ Similarly, there are just a few occasions when we need to extract the value
of a "variable" and define it as a constant:

=
void Emit::initial_value_as_constant(inter_name *con_iname, nonlocal_variable *var) {
	inter_ti v1 = 0, v2 = 0;
	RTVariables::initial_value_as_pair(con_iname, &v1, &v2, var);
	Emit::named_generic_constant(con_iname, v1, v2);
}

@ The above make use of this:

=
void Emit::named_generic_constant(inter_name *con_iname, inter_ti v1, inter_ti v2) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	Produce::guard(Inter::Constant::new_numerical(Emit::at(), Emit::symbol_id(con_s),
		Emit::symbol_id(unchecked_interk), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@h Instances.

=
void Emit::instance(inter_name *inst_iname, kind *K, int v) {
	packaging_state save = Packaging::enter_home_of(inst_iname);
	inter_symbol *inst_s = Produce::define_symbol(inst_iname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	if (kind_s == NULL) internal_error("no kind for val");
	inter_ti v1 = LITERAL_IVAL, v2 = (inter_ti) v;
	if (v == 0) { v1 = UNDEF_IVAL; v2 = 0; }
	Produce::guard(Inter::Instance::new(Emit::at(), Emit::symbol_id(inst_s),
		Emit::symbol_id(kind_s), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

@h Variables.

=
inter_symbol *Emit::variable(inter_name *var_iname, kind *K, inter_ti v1, inter_ti v2) {
	packaging_state save = Packaging::enter_home_of(var_iname);
	inter_symbol *var_s = Produce::define_symbol(var_iname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Variable::new(Emit::at(),
		Emit::symbol_id(var_s), Emit::symbol_id(kind_s), v1, v2, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
	return var_s;
}

@h Properties and permissions.

=
void Emit::property(inter_name *prop_iname, kind *K) {
	packaging_state save = Packaging::enter_home_of(prop_iname);
	inter_symbol *prop_s = Produce::define_symbol(prop_iname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Property::new(Emit::at(),
		Emit::symbol_id(prop_s), Emit::symbol_id(kind_s), Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}

void Emit::permission(property *prn, kind *K, inter_name *storage_iname) {
	packaging_state save = Packaging::enter(Kinds::Behaviour::package(K));
	inter_name *prop_s = RTProperties::iname(prn);
	inter_symbol *owner_s = Produce::kind_to_symbol(K);
	inter_symbol *store = (storage_iname)?InterNames::to_symbol(storage_iname):NULL;
	Emit::basic_permission(prop_s, owner_s, store);
	Packaging::exit(Emit::tree(), save);
}

void Emit::instance_permission(property *prn, inter_name *inst_iname) {
	inter_name *prop_s = RTProperties::iname(prn);
	inter_symbol *owner_s = InterNames::to_symbol(inst_iname);
	packaging_state save = Packaging::enter_home_of(inst_iname);
	Emit::basic_permission(prop_s, owner_s, NULL);
	Packaging::exit(Emit::tree(), save);
}

int ppi7_counter = 0;
void Emit::basic_permission(inter_name *prop_iname, inter_symbol *owner_name,
	inter_symbol *store_s) {
	inter_symbol *prop_s = Produce::define_symbol(prop_iname);
	inter_error_message *E = NULL;
	TEMPORARY_TEXT(ident)
	WRITE_TO(ident, "pp_i7_%d", ppi7_counter++);
	inter_symbol *pp_s =
		Inter::Textual::new_symbol(NULL, Inter::Bookmarks::scope(Emit::at()), ident, &E);
	DISCARD_TEXT(ident)
	Produce::guard(E);
	Produce::guard(Inter::Permission::new(Emit::at(),
		Emit::symbol_id(prop_s), Emit::symbol_id(owner_name), Emit::symbol_id(pp_s),
		(store_s)?(Emit::symbol_id(store_s)):0, Emit::baseline(), NULL));
}

@h Property values.

=
void Emit::propertyvalue(property *P, kind *K, inter_ti v1, inter_ti v2) {
	inter_symbol *prop_s = InterNames::to_symbol(RTProperties::iname(P));
	inter_symbol *owner_s = Produce::kind_to_symbol(K);
	Produce::guard(Inter::PropertyValue::new(Emit::at(),
		Emit::symbol_id(prop_s),
		Emit::symbol_id(owner_s), v1, v2, Emit::baseline(), NULL));
}

void Emit::instance_propertyvalue(property *P, instance *I, inter_ti v1, inter_ti v2) {
	inter_symbol *prop_s = InterNames::to_symbol(RTProperties::iname(P));
	inter_symbol *owner_s = InterNames::to_symbol(RTInstances::value_iname(I));
	Produce::guard(Inter::PropertyValue::new(Emit::at(),
		Emit::symbol_id(prop_s),
		Emit::symbol_id(owner_s), v1, v2, Emit::baseline(), NULL));
}

@h Private, keep out.
The following should be called only by //imperative: Functions//, which provides
the real API for starting and ending functions.

=
void Emit::function(inter_name *fn_iname, kind *K, inter_package *block) {
	if (Emit::at() == NULL) internal_error("no inter repository");
	inter_symbol *fn_s = Produce::define_symbol(fn_iname);
	inter_symbol *kind_s = Produce::kind_to_symbol(K);
	Produce::guard(Inter::Constant::new_function(Emit::at(),
		Emit::symbol_id(fn_s), Emit::symbol_id(kind_s), block,
		Emit::baseline(), NULL));
}

@h Interventions.
These should be used as little as possible, and perhaps it may one day be possible
to abolish them altogether. They insert direct kit material (i.e. paraphrased Inter
code written out as plain text in Inform 6 notation) into bytecode; this is then
assimilating during linking.

=
void Emit::intervention(int stage, text_stream *segment, text_stream *part,
	text_stream *i6, text_stream *seg) {
	inter_warehouse *warehouse = Emit::warehouse();
	inter_ti ID1 = Inter::Warehouse::create_text(warehouse, Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID1), segment);

	inter_ti ID2 = Inter::Warehouse::create_text(warehouse, Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID2), part);

	inter_ti ID3 = Inter::Warehouse::create_text(warehouse, Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID3), i6);

	inter_ti ID4 = Inter::Warehouse::create_text(warehouse, Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID4), seg);

	inter_ti ref = Inter::Warehouse::create_ref(warehouse);
	Inter::Warehouse::set_ref(warehouse, ref, (void *) current_sentence);

	Inter::Warehouse::attribute_resource(warehouse, ref, Emit::package());

	Produce::guard(Inter::Link::new(Emit::at(), (inter_ti) stage,
		ID1, ID2, ID3, ID4, ref, Emit::baseline(), NULL));
}

@ And this is a similarly inelegant construction:

=
void Emit::append(inter_name *iname, text_stream *text) {
	LOG("Append '%S'\n", text);
	packaging_state save = Packaging::enter_home_of(iname);
	inter_symbol *symbol = InterNames::to_symbol(iname);
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(), Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	Produce::guard(Inter::Append::new(Emit::at(), symbol, ID, Emit::baseline(), NULL));
	Packaging::exit(Emit::tree(), save);
}
