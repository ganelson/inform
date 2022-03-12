[LabInstruction::] The Lab Construct.

Defining the Lab construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void LabInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LAB_IST, I"lab");
	InterInstruction::specify_syntax(IC, I"lab .IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, 3, 3);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LabInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LabInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LabInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |lab| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d LABEL_LAB_IFLD 2

=
inter_error_message *LabInstruction::new(inter_bookmark *IBM, inter_symbol *label,
	inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, LAB_IST,
		/* LABEL_LAB_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, label),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks. Note that we do not make the
customary call to //VerifyingInter::SID_field// on |LABEL_LAB_IFLD| for timing
reasons: it may refer to a symbol not yet defined.

=
void LabInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	inter_symbol *label = LabInstruction::label_symbol(P);
	if (InterSymbol::is_label(label) == FALSE) {
		*E = Inode::error(P, I"no such label", NULL);
		return;
	}
}

@h Creating from textual Inter syntax.
Note that a |lab| can occur either before or after the creation point for the
label it refers to; so if we have an unknown label name, we create it as a label
in expectation that the position will be declared in a future instruction.

=
void LabInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *label_name = ilp->mr.exp[0];
	inter_symbol *label_s =
		InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), label_name);
	if (label_s == NULL) {
		label_s = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), label_name, E);
		if (*E) return;
		InterSymbol::make_label(label_s);
	}
	if (InterSymbol::is_label(label_s) == FALSE) {
		*E = InterErrors::plain(I"not a label", eloc);
		return;
	}
	*E = LabInstruction::new(IBM, label_s, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void LabInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *label_s = LabInstruction::label_symbol(P);
	WRITE("lab %S", InterSymbol::identifier(label_s));
}

@h Access function.

=
inter_symbol *LabInstruction::label_symbol(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != LAB_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, LABEL_LAB_IFLD);
}
