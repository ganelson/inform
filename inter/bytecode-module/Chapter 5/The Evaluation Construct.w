[EvaluationInstruction::] The Evaluation Construct.

Defining the Evaluation construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void EvaluationInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(EVALUATION_IST, I"evaluation");
	InterInstruction::specify_syntax(IC, I"evaluation");
	InterInstruction::fix_instruction_length_between(IC, 2, 2);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, EvaluationInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, EvaluationInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, EvaluationInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of an |evaluation| instruction is laid out with just the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|.

=
inter_error_message *EvaluationInstruction::new(inter_bookmark *IBM, int level,
	inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, EVALUATION_IST,
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void EvaluationInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) &&
			(C->W.instruction[0] != SPLAT_IST) &&
			(C->W.instruction[0] != VAL_IST) &&
			(C->W.instruction[0] != LABEL_IST) &&
			(C->W.instruction[0] != EVALUATION_IST)) {
			*E = Inode::error(C, I"only a value can be below an evaluation", NULL);
			return;
		}
	}
}

@h Creating from textual Inter syntax.

=
void EvaluationInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = EvaluationInstruction::new(IBM, ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void EvaluationInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("evaluation");
}
