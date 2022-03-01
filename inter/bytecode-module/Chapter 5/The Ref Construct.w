[RefInstruction::] The Ref Construct.

Defining the ref construct.

@


=
void RefInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(REF_IST, I"ref");
	InterInstruction::specify_syntax(IC, I"ref TOKENS");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_REF_IFR, EXTENT_REF_IFR);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, RefInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, RefInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, RefInstruction::write);
}

@

@d BLOCK_REF_IFLD 2
@d KIND_REF_IFLD 3
@d VAL1_REF_IFLD 4
@d VAL2_REF_IFLD 5

@d EXTENT_REF_IFR 6

=
void RefInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'ref' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = InterErrors::plain(I"function has no symbols table", eloc); return; }

	text_stream *kind_text = NULL, *value_text = ilp->mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, value_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr2.exp[0];
		value_text = mr2.exp[1];
	}

	inter_type ref_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, ref_type, value_text, &val);
	if (*E) return;

	*E = RefInstruction::new(IBM, ref_type, ilp->indent_level, val, eloc);
}

inter_error_message *RefInstruction::new(inter_bookmark *IBM, inter_type ref_type, int level, inter_pair val, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, REF_IST, 0, InterTypes::to_TID_at(IBM, ref_type),
		InterValuePairs::to_word1(val), InterValuePairs::to_word2(val), eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void RefInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, KIND_REF_IFLD);
	if (*E) return;
	inter_type type = InterTypes::from_TID_in_field(P, KIND_REF_IFLD);
	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_REF_IFLD, type);
	if (*E) return;
}

void RefInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("ref ");
	TextualInter::write_optional_type_marker(OUT, P, KIND_REF_IFLD);
	TextualInter::write_pair(OUT, P, InterValuePairs::get(P, VAL1_REF_IFLD), FALSE);
}
