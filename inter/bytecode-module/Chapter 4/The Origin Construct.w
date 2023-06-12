[OriginInstruction::] The Origin Construct.

Defining the origin construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void OriginInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(ORIGIN_IST, I"origin");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_ORIGIN_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"origin @IDENTIFIER TEXT");
	InterInstruction::data_extent_at_least(IC, 2);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, OriginInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, OriginInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, OriginInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, OriginInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |primitive| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by two words:

@d DEFN_ORIGIN_IFLD (DATA_IFLD + 0)
@d FILENAME_ORIGIN_IFLD (DATA_IFLD + 1)

=
inter_error_message *OriginInstruction::new(inter_bookmark *IBM, inter_symbol *orig_name, 
	text_stream *file, inter_ti level, inter_error_location *eloc) {

	inter_tree_node *F = Inode::new_with_2_data_fields(IBM, ORIGIN_IST,
		/* DEFN_ORIGIN_IFLD: */     InterSymbolsTable::id_at_bookmark(IBM, orig_name),
		/* FILENAME_ORIGIN_IFLD: */ InterWarehouse::create_text_at(IBM, file),
		eloc, level);

	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), F);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(F, IBM);

	return NULL;
}

void OriginInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[FILENAME_ORIGIN_IFLD] = grid[P->W.instruction[FILENAME_ORIGIN_IFLD]];
}

@ Verification consists only of sanity checks.

=
void OriginInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::text_field(owner, P, FILENAME_ORIGIN_IFLD);
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void OriginInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *orig_name =
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	*E = OriginInstruction::new(IBM, orig_name, ilp->mr.exp[1],
		(inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void OriginInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *orig_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_ORIGIN_IFLD);
	WRITE("origin @%S", InterSymbol::identifier(orig_name));
	WRITE(" ");
	TextualInter::write_text(OUT, OriginInstruction::filename(P));
}

@h Access functions.

=
text_stream *OriginInstruction::filename(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, ORIGIN_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[FILENAME_ORIGIN_IFLD]);
}
