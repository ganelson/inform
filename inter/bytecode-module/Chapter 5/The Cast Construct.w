[CastInstruction::] The Cast Construct.

Defining the cast construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void CastInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CAST_IST, I"cast");
	InterInstruction::specify_syntax(IC, I"cast IDENTIFIER <- IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, 4, 4);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CastInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, CastInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CastInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, CastInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of a |typename| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d TO_KIND_CAST_IFLD 2
@d FROM_KIND_CAST_IFLD 3

=
inter_error_message *CastInstruction::new(inter_bookmark *IBM, inter_type from_type,
	inter_type to_type, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, CAST_IST,
		/* TO_KIND_CAST_IFLD: */   InterTypes::to_TID_at(IBM, to_type),
		/* FROM_KIND_CAST_IFLD: */ InterTypes::to_TID_at(IBM, from_type),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void CastInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TO_KIND_CAST_IFLD);
	if (*E) return;
	*E = VerifyingInter::TID_field(owner, P, FROM_KIND_CAST_IFLD);
	if (*E) return;
}

void CastInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	int arity_as_invoked = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		arity_as_invoked++;
		if ((C->W.instruction[0] != INV_IST) &&
			(C->W.instruction[0] != VAL_IST) &&
			(C->W.instruction[0] != EVALUATION_IST) &&
			(C->W.instruction[0] != CAST_IST)) {
			*E = Inode::error(P, I"only a value can be under a cast", NULL);
			return;
		}
	}
	if (arity_as_invoked != 1) {
		*E = Inode::error(P, I"a cast should have exactly one child", NULL);
		return;
	}
}

@h Creating from textual Inter syntax.

=
void CastInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *to_text = ilp->mr.exp[0];
	text_stream *from_text = ilp->mr.exp[1];
	
	inter_symbols_table *T = InterBookmark::scope(IBM);
	inter_type from_type = InterTypes::parse_simple(T, eloc, from_text, E);
	if (*E) return;
	inter_type to_type = InterTypes::parse_simple(T, eloc, to_text, E);
	if (*E) return;

	*E = CastInstruction::new(IBM, from_type, to_type, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void CastInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	WRITE("cast ");
	TextualInter::write_compulsory_type_marker(OUT, P, TO_KIND_CAST_IFLD);
	WRITE(" <- ");
	TextualInter::write_compulsory_type_marker(OUT, P, FROM_KIND_CAST_IFLD);
}
