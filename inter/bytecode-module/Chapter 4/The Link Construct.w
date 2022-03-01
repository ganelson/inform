[LinkInstruction::] The Link Construct.

Defining the link construct.

@


=
void LinkInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LINK_IST, I"link");
	InterInstruction::specify_syntax(IC, I"link IDENTIFIER TEXT TEXT TEXT TEXT");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_LINK_IFR, EXTENT_LINK_IFR);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LinkInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, LinkInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LinkInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LinkInstruction::write);
}

@

@d STAGE_LINK_IFLD 2
@d SEGMENT_LINK_IFLD 3
@d PART_LINK_IFLD 4
@d TO_RAW_LINK_IFLD 5
@d TO_SEGMENT_LINK_IFLD 6

@d EXTENT_LINK_IFR 7

@d EARLY_LINK_STAGE 1
@d BEFORE_LINK_STAGE 2
@d INSTEAD_LINK_STAGE 3
@d AFTER_LINK_STAGE 4
@d CATCH_ALL_LINK_STAGE 5

=
void LinkInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_ti stage = 0;
	text_stream *stage_text = ilp->mr.exp[0];
	if (Str::eq(stage_text, I"early")) stage = EARLY_LINK_STAGE;
	else if (Str::eq(stage_text, I"before")) stage = BEFORE_LINK_STAGE;
	else if (Str::eq(stage_text, I"instead")) stage = INSTEAD_LINK_STAGE;
	else if (Str::eq(stage_text, I"after")) stage = AFTER_LINK_STAGE;
	else { *E = InterErrors::plain(I"no such stage name is supported", eloc); return; }

	inter_ti SIDS[5];
	SIDS[0] = stage;
	for (int i=1; i<=4; i++) {
		SIDS[i] = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
		*E = TextualInter::parse_literal_text(InterWarehouse::get_text(InterBookmark::warehouse(IBM), SIDS[i]), ilp->mr.exp[i], 0, Str::len(ilp->mr.exp[i]), eloc);
		if (*E) return;
	}

	*E = LinkInstruction::new(IBM, SIDS[0], SIDS[1], SIDS[2], SIDS[3], SIDS[4], (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *LinkInstruction::new(inter_bookmark *IBM,
	inter_ti stage, inter_ti text1, inter_ti text2, inter_ti text3, inter_ti text4, inter_ti level,
	struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_5_data_fields(IBM, LINK_IST, stage, text1, text2, text3, text4, eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void LinkInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	for (int i=SEGMENT_LINK_IFLD; i<=TO_SEGMENT_LINK_IFLD; i++)
		P->W.instruction[i] = grid[P->W.instruction[i]];
}

void LinkInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if ((P->W.instruction[STAGE_LINK_IFLD] != EARLY_LINK_STAGE) &&
		(P->W.instruction[STAGE_LINK_IFLD] != BEFORE_LINK_STAGE) &&
		(P->W.instruction[STAGE_LINK_IFLD] != INSTEAD_LINK_STAGE) &&
		(P->W.instruction[STAGE_LINK_IFLD] != AFTER_LINK_STAGE))
		{ *E = Inode::error(P, I"bad stage marker on link", NULL); return; }
	if (P->W.instruction[SEGMENT_LINK_IFLD] == 0) { *E = Inode::error(P, I"no segment text", NULL); return; }
	if (P->W.instruction[PART_LINK_IFLD] == 0) { *E = Inode::error(P, I"no part text", NULL); return; }
	if (P->W.instruction[TO_RAW_LINK_IFLD] == 0) { *E = Inode::error(P, I"no to-raw text", NULL); return; }
	if (P->W.instruction[TO_SEGMENT_LINK_IFLD] == 0) { *E = Inode::error(P, I"no to-segment text", NULL); return; }
}

void LinkInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("link ");
	switch (P->W.instruction[STAGE_LINK_IFLD]) {
		case EARLY_LINK_STAGE: WRITE("early"); break;
		case BEFORE_LINK_STAGE: WRITE("before"); break;
		case INSTEAD_LINK_STAGE: WRITE("instead"); break;
		case AFTER_LINK_STAGE: WRITE("after"); break;
	}
	for (int i=SEGMENT_LINK_IFLD; i<=TO_SEGMENT_LINK_IFLD; i++) {
		WRITE(" ");
		text_stream *S = Inode::ID_to_text(P, P->W.instruction[i]);
		TextualInter::write_text(OUT, S);
	}
}
