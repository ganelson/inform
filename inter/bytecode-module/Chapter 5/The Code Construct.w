[CodeInstruction::] The Code Construct.

Defining the Code construct.

@

=
void CodeInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CODE_IST, I"code");
	InterInstruction::specify_syntax(IC, I"code");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_CODE_IFR, EXTENT_CODE_IFR);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CodeInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CodeInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, CodeInstruction::verify_children);
}

@

@d BLOCK_CODE_IFLD 2

@d EXTENT_CODE_IFR 3

=
void CodeInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (InterBookmark::package(IBM) == NULL) {
		*E = InterErrors::plain(I"'code' used outside package", eloc); return;
	}

	*E = CodeInstruction::new(IBM, ilp->indent_level, eloc);
}

inter_error_message *CodeInstruction::new(inter_bookmark *IBM, int level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, CODE_IST, 0, eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void CodeInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("code");
}

void CodeInstruction::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) && (C->W.instruction[0] != SPLAT_IST) && (C->W.instruction[0] != EVALUATION_IST) && (C->W.instruction[0] != LABEL_IST) && (C->W.instruction[0] != VAL_IST) && (C->W.instruction[0] != COMMENT_IST) && (C->W.instruction[0] != NOP_IST)) {
			*E = Inode::error(C, I"only an inv, a val, a splat, a concatenate or a label can be below a code", NULL);
			return;
		}
	}
}
