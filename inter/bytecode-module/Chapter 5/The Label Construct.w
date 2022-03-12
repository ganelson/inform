[LabelInstruction::] The Label Construct.

Defining the label construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void LabelInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LABEL_IST, I"label");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_LABEL_IFLD, -1);
	InterInstruction::specify_syntax(IC, I".IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, 3, 3);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LabelInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LabelInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LabelInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |label| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d DEFN_LABEL_IFLD 2

=
inter_error_message *LabelInstruction::new(inter_bookmark *IBM, inter_symbol *lab_name,
	inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, LABEL_IST,
		/* DEFN_LABEL_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, lab_name),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void LabelInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	inter_symbol *lab_name = LabelInstruction::label_symbol(P);
	if (InterSymbol::is_label(lab_name) == FALSE) {
		*E = Inode::error(P, I"not a label",
			(lab_name)?(InterSymbol::identifier(lab_name)):NULL);
		return;
	}
	if (P->W.instruction[LEVEL_IFLD] < 1) {
		*E = Inode::error(P, I"label with bad level", NULL);
		return;
	}
}

@h Creating from textual Inter syntax.
Note that a |.LABEL| can occur either before or after it is used in |lab| instructions,
so that the label name might already have been created: see //LabInstruction::read//.

=
void LabelInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *label_name = ilp->mr.exp[0];
	inter_symbol *label_s =
		InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), label_name);
	if (label_s == NULL) {
		label_s = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), label_name, E);
		if (*E) return;
	} else if (InterSymbol::is_defined(label_s)) {
		*E = InterErrors::plain(I"label_s defined in function once already", eloc);
		return;
	}
	InterSymbol::make_label(label_s);
	*E = LabelInstruction::new(IBM, label_s, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void LabelInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *label_s = LabelInstruction::label_symbol(P);
	WRITE("%S", InterSymbol::identifier(label_s));
}

@h Access function.

=
inter_symbol *LabelInstruction::label_symbol(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != LABEL_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_LABEL_IFLD);
}
