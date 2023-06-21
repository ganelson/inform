[Synoptic::] Synoptic Utilities.

Utility functions for generating the code in the synoptic module.

@h Dealing with symbols.
We are going to need to read and write these: for reading --

=
inter_symbol *Synoptic::get_symbol(inter_package *pack, text_stream *name) {
	inter_symbol *loc_s =
		InterSymbolsTable::symbol_from_name(InterPackage::scope(pack), name);
	if (loc_s == NULL) Metadata::err("package symbol not found", pack, name);
	return loc_s;
}

inter_tree_node *Synoptic::get_definition(inter_package *pack, text_stream *name) {
	inter_symbol *def_s = InterSymbolsTable::symbol_from_name(InterPackage::scope(pack), name);
	if (def_s == NULL) {
		LOG("Unable to find symbol %S in $6\n", name, pack);
		internal_error("no symbol");
	}
	inter_tree_node *D = def_s->definition;
	if (D == NULL) {
		LOG("Undefined symbol %S in $6\n", name, pack);
		internal_error("undefined symbol");
	}
	return D;
}

@ To clarify: here, the symbol is optional, that is, need not exist; but if it
does exist, it must have a definition, and we return that.

=
inter_symbol *Synoptic::get_optional_symbol(inter_package *pack, text_stream *name) {
	return InterSymbolsTable::symbol_from_name(InterPackage::scope(pack), name);
}

inter_tree_node *Synoptic::get_optional_definition(inter_package *pack, text_stream *name) {
	inter_symbol *def_s = InterSymbolsTable::symbol_from_name(InterPackage::scope(pack), name);
	if (def_s == NULL) return NULL;
	inter_tree_node *D = def_s->definition;
	if (D == NULL) internal_error("undefined symbol");
	return D;
}

@ And this creates a new symbol:

=
inter_symbol *Synoptic::new_symbol(inter_package *pack, text_stream *name) {
	return InterSymbolsTable::create_with_unique_name(InterPackage::scope(pack), name);
}

@h Making textual constants.

=
void Synoptic::textual_constant(inter_tree *I, pipeline_step *step,
	inter_symbol *con_s, text_stream *S, inter_bookmark *IBM) {
	Produce::guard(ConstantInstruction::new(IBM, con_s,
		LargeScale::text_literal_type(I), InterValuePairs::from_text(IBM, S),
		(inter_ti) InterBookmark::baseline(IBM) + 1, NULL));
}

@h Making functions.

=
inter_package *synoptic_fn_package = NULL;
packaging_state synoptic_fn_ps;
void Synoptic::begin_function(inter_tree *I, inter_name *iname) {
	synoptic_fn_package = Produce::function_body(I, &synoptic_fn_ps, iname);
}
void Synoptic::end_function(inter_tree *I, pipeline_step *step, inter_name *iname) {
	Produce::end_function_body(I);
	Packaging::exit(I, synoptic_fn_ps);
}

@ To give such a function a local:

=
inter_symbol *Synoptic::local(inter_tree *I, text_stream *name, text_stream *comment) {
	return Produce::local(I, K_value, name, comment);
}

@h Making arrays.

=
inter_tree_node *synoptic_array_node = NULL;
packaging_state synoptic_array_ps;

void Synoptic::begin_array(inter_tree *I, pipeline_step *step, inter_name *iname) {
	Synoptic::begin_array_inner(I, step, iname, CONST_LIST_FORMAT_WORDS);
}

void Synoptic::begin_bounded_array(inter_tree *I, pipeline_step *step, inter_name *iname) {
	Synoptic::begin_array_inner(I, step, iname, CONST_LIST_FORMAT_B_WORDS);
}

void Synoptic::begin_byte_array(inter_tree *I, pipeline_step *step, inter_name *iname) {
	Synoptic::begin_array_inner(I, step, iname, CONST_LIST_FORMAT_BYTES);
}

void Synoptic::begin_array_inner(inter_tree *I, pipeline_step *step, inter_name *iname,
	inter_ti format) {
	synoptic_array_ps = Packaging::enter_home_of(iname);
	inter_symbol *con_s = InterNames::to_symbol(iname);
	inter_ti TID = InterTypes::to_TID(InterBookmark::scope(Packaging::at(I)),
		InterTypes::from_constructor_code(LIST_ITCONC));
	synoptic_array_node = Inode::new_with_3_data_fields(Packaging::at(I), CONSTANT_IST,
		 InterSymbolsTable::id_at_bookmark(Packaging::at(I), con_s),
		 TID, format, NULL, 
		 (inter_ti) InterBookmark::baseline(Packaging::at(I)) + 1);
}

void Synoptic::end_array(inter_tree *I) {
	inter_error_message *E = VerifyingInter::instruction(
		InterBookmark::package(Packaging::at(I)), synoptic_array_node);
	if (E) {
		InterErrors::issue(E);
		internal_error("synoptic array failed verification");
	}
	NodePlacement::move_to_moving_bookmark(synoptic_array_node, Packaging::at(I));
	Packaging::exit(I, synoptic_array_ps);
}

@ Three ways to define an entry:

=
void Synoptic::numeric_entry(inter_ti N) {
	Inode::extend_instruction_by(synoptic_array_node, 2);
	InterValuePairs::set(synoptic_array_node, synoptic_array_node->W.extent-2,
		InterValuePairs::number(N));
}
void Synoptic::symbol_entry(inter_symbol *S) {
	Inode::extend_instruction_by(synoptic_array_node, 2);
	inter_package *pack = InterPackage::container(synoptic_array_node);
	inter_symbol *local_S = InterSymbolsTable::create_with_unique_name(
		InterPackage::scope(pack), InterSymbol::identifier(S));
	Wiring::wire_to(local_S, S);
	InterValuePairs::set(synoptic_array_node, synoptic_array_node->W.extent-2,
		InterValuePairs::symbolic_in(pack, local_S));
}
void Synoptic::textual_entry(text_stream *text) {
	inter_tree *I = Inode::tree(synoptic_array_node);
	Inode::extend_instruction_by(synoptic_array_node, 2);
	InterValuePairs::set(synoptic_array_node, synoptic_array_node->W.extent-2,
		InterValuePairs::from_text(Packaging::at(I), text));
}
