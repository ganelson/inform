[VariableInstruction::] The Variable Construct.

Defining the variable construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void VariableInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(VARIABLE_IST, I"variable");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_VAR_IFLD, TYPE_VAR_IFLD);
	InterInstruction::specify_syntax(IC, I"variable TOKENS = TOKENS");
	InterInstruction::data_extent_always(IC, 4);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, VariableInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, VariableInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, VariableInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, VariableInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |propertyvalue| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d DEFN_VAR_IFLD (DATA_IFLD + 0)
@d TYPE_VAR_IFLD (DATA_IFLD + 1)
@d VAL1_VAR_IFLD (DATA_IFLD + 2)
@d VAL2_VAR_IFLD (DATA_IFLD + 3)

=
inter_error_message *VariableInstruction::new(inter_bookmark *IBM, inter_symbol *var_s,
	inter_type var_type, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, VARIABLE_IST,
		/* DEFN_VAR_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, var_s),
		/* TYPE_VAR_IFLD: */ InterTypes::to_TID_at(IBM, var_type),
		/* VAL1_VAR_IFLD: */ InterValuePairs::to_word1(val),
		/* VAL2_VAR_IFLD: */ InterValuePairs::to_word2(val),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void VariableInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	InterValuePairs::set(P, VAL1_PVAL_IFLD,
		InterValuePairs::transpose(InterValuePairs::get(P, VAL1_PVAL_IFLD), grid, grid_extent, E));
}

@ Verification consists only of sanity checks.

=
void VariableInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TYPE_VAR_IFLD);
	if (*E) return;
	inter_type type = InterTypes::from_TID_in_field(P, TYPE_VAR_IFLD);
	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_VAR_IFLD, type);
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void VariableInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *type_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, name_text, L"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0]; name_text = mr.exp[1];
	}
	inter_type var_type =
		InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, type_text, E);
	inter_symbol *var_s = NULL;
	if (*E == NULL)
		var_s = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, E);
	Regexp::dispose_of(&mr);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), var_s);

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, var_type, ilp->mr.exp[1], &val);
	if (*E) return;

	*E = VariableInstruction::new(IBM, var_s, var_type, val,
		(inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void VariableInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *var_s = VariableInstruction::variable(P);
	WRITE("variable ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_VAR_IFLD);
	WRITE("%S = ", InterSymbol::identifier(var_s));
	TextualInter::write_pair(OUT, P, VariableInstruction::value(P));
}

@h Access functions.

=
inter_symbol *VariableInstruction::variable(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, VARIABLE_IST)) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_VAR_IFLD);
}

inter_pair VariableInstruction::value(inter_tree_node *P) {
	if (P == NULL) return InterValuePairs::undef();
	if (Inode::isnt(P, VARIABLE_IST)) return InterValuePairs::undef();
	return InterValuePairs::get(P, VAL1_VAR_IFLD);
}
