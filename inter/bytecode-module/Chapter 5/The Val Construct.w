[ValInstruction::] The Val Construct.

Defining the val construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void ValInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(VAL_IST, I"val");
	InterInstruction::specify_syntax(IC, I"val TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 5, 5);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ValInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, ValInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, ValInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ValInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |val| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d TYPE_VAL_IFLD (DATA_IFLD + 0)
@d VAL1_VAL_IFLD (DATA_IFLD + 1)
@d VAL2_VAL_IFLD (DATA_IFLD + 2)

=
inter_error_message *ValInstruction::new(inter_bookmark *IBM, inter_type val_type,
	int level, inter_pair val, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, VAL_IST,
		/* TYPE_VAL_IFLD: */ InterTypes::to_TID_at(IBM, val_type),
		/* VAL1_VAL_IFLD: */ InterValuePairs::to_word1(val),
		/* VAL2_VAL_IFLD: */ InterValuePairs::to_word2(val),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void ValInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	InterValuePairs::set(P, VAL1_VAL_IFLD,
		InterValuePairs::transpose(InterValuePairs::get(P, VAL1_VAL_IFLD),
			grid, grid_extent, E));
}

@ Verification consists only of sanity checks.

=
void ValInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TYPE_VAL_IFLD);
	if (*E) return;
	inter_type type = InterTypes::from_TID_in_field(P, TYPE_VAL_IFLD);
	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_VAL_IFLD, type);
	if (*E) return;
}

@h Creating from textual Inter syntax.
Note that a |val| can legally hold a typename as a value.

=
void ValInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *type_text = NULL, *value_text = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, value_text, L"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0];
		value_text = mr.exp[1];
	}
	inter_pair val = InterValuePairs::undef();
	inter_type val_type =
		InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, type_text, E);
	if (*E == NULL) {
		inter_symbol *typename_as_value =
			TextualInter::find_symbol(IBM, eloc, value_text, TYPENAME_IST, E);
		if (typename_as_value) {
			*E = NULL;
			val = InterValuePairs::symbolic(IBM, typename_as_value);
		} else {
			*E = TextualInter::parse_pair(ilp->line, eloc, IBM, val_type, value_text, &val);
		}
	}
	Regexp::dispose_of(&mr);
	if (*E) return;

	*E = ValInstruction::new(IBM, val_type, ilp->indent_level, val, eloc);
}

@h Writing to textual Inter syntax.

=
void ValInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("val ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_VAL_IFLD);
	TextualInter::write_pair(OUT, P, ValInstruction::value(P), FALSE);
}

@h Access function.

=
inter_pair ValInstruction::value(inter_tree_node *P) {
	if (P == NULL) return InterValuePairs::undef();
	if (Inode::isnt(P, VAL_IST)) return InterValuePairs::undef();
	return InterValuePairs::get(P, VAL1_VAL_IFLD);
}
