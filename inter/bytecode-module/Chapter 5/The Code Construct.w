[CodeInstruction::] The Code Construct.

Defining the Code construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void CodeInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CODE_IST, I"code");
	InterInstruction::specify_syntax(IC, I"code");
	InterInstruction::data_extent_always(IC, 0);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CodeInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CodeInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, CodeInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of a |code| instruction is laid out with just the two
compulsory words -- see //Inter Nodes//.

=
inter_error_message *CodeInstruction::new(inter_bookmark *IBM, int level,
	inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, CODE_IST,
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void CodeInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) &&
			(C->W.instruction[0] != SPLAT_IST) &&
			(C->W.instruction[0] != EVALUATION_IST) &&
			(C->W.instruction[0] != LABEL_IST) &&
			(C->W.instruction[0] != VAL_IST) &&
			(C->W.instruction[0] != COMMENT_IST) &&
			(C->W.instruction[0] != PROVENANCE_IST) &&
			(C->W.instruction[0] != NOP_IST)) {
			*E = Inode::error(C, I"only executable matter can be below a code", NULL);
			return;
		}
	}
}

@h Creating from textual Inter syntax.

=
void CodeInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	*E = CodeInstruction::new(IBM, ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void CodeInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("code");
}
