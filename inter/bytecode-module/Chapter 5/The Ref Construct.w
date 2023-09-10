[RefInstruction::] The Ref Construct.

Defining the ref construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void RefInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(REF_IST, I"ref");
	InterInstruction::specify_syntax(IC, I"ref TOKENS");
	InterInstruction::data_extent_always(IC, 3);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, RefInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, RefInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, RefInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |ref| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d TYPE_REF_IFLD (DATA_IFLD + 0)
@d VAL1_REF_IFLD (DATA_IFLD + 1)
@d VAL2_REF_IFLD (DATA_IFLD + 2)

=
inter_error_message *RefInstruction::new(inter_bookmark *IBM, inter_type ref_type,
	int level, inter_pair val, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, REF_IST,
		/* TYPE_REF_IFLD: */ InterTypes::to_TID_at(IBM, ref_type),
		/* VAL1_REF_IFLD: */ InterValuePairs::to_word1(val),
		/* VAL2_REF_IFLD: */ InterValuePairs::to_word2(val),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void RefInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TYPE_REF_IFLD);
	if (*E) return;
	inter_type type = InterTypes::from_TID_in_field(P, TYPE_REF_IFLD);
	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_REF_IFLD, type);
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void RefInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *type_text = NULL, *value_text = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, value_text, U"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0];
		value_text = mr.exp[1];
	}
	inter_pair val = InterValuePairs::undef();
	inter_type ref_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, type_text, E);
	if (*E == NULL)
		*E = TextualInter::parse_pair(ilp->line, eloc, IBM, ref_type, value_text, &val);
	Regexp::dispose_of(&mr);
	if (*E) return;

	*E = RefInstruction::new(IBM, ref_type, ilp->indent_level, val, eloc);
}

@h Writing to textual Inter syntax.

=
void RefInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("ref ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_REF_IFLD);
	TextualInter::write_pair(OUT, P, RefInstruction::value(P));
}

@h Access function.

=
inter_pair RefInstruction::value(inter_tree_node *P) {
	if (P == NULL) return InterValuePairs::undef();
	if (Inode::isnt(P, REF_IST)) return InterValuePairs::undef();
	return InterValuePairs::get(P, VAL1_REF_IFLD);
}
