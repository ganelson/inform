[PragmaInstruction::] The Pragma Construct.

Defining the pragma construct.

@


=
void PragmaInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PRAGMA_IST, I"pragma");
	InterInstruction::specify_syntax(IC, I"pragma IDENTIFIER TEXT");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_PRAGMA_IFR, EXTENT_PRAGMA_IFR);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PragmaInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, PragmaInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PragmaInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PragmaInstruction::write);
}

@

@d TARGET_PRAGMA_IFLD 2
@d TEXT_PRAGMA_IFLD 3

@d EXTENT_PRAGMA_IFR 4

=
void PragmaInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *target_name = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), ilp->mr.exp[0]);
	if (target_name == NULL)
		target_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	text_stream *S = ilp->mr.exp[1];
	inter_ti ID = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
	int literal_mode = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		int c = (int) Str::get(pos);
		if (literal_mode == FALSE) {
			if (c == '\\') { literal_mode = TRUE; continue; }
		} else {
			switch (c) {
				case '\\': break;
				case '"': break;
				case 't': c = 9; break;
				case 'n': c = 10; break;
				default: { *E = InterErrors::plain(I"no such backslash escape", eloc); return; }
			}
		}
		if (ConstantInstruction::char_acceptable(c) == FALSE) { *E = InterErrors::quoted(I"bad character in text", S, eloc); return; }
		PUT_TO(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ID), c);
		literal_mode = FALSE;
	}

	*E = PragmaInstruction::new(IBM, target_name, ID, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *PragmaInstruction::new(inter_bookmark *IBM, inter_symbol *target_name, inter_ti pragma_text, inter_ti level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, PRAGMA_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, target_name), pragma_text, eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void PragmaInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_PRAGMA_IFLD] = grid[P->W.instruction[TEXT_PRAGMA_IFLD]];
}

void PragmaInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_symbol *target_name = InterSymbolsTable::symbol_from_ID_at_node(P, TARGET_PRAGMA_IFLD);
	if (target_name == NULL) { *E = Inode::error(P, I"no target name", NULL); return; }
	if (P->W.instruction[TEXT_PRAGMA_IFLD] == 0) { *E = Inode::error(P, I"no pragma text", NULL); return; }
}

void PragmaInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *target_name = InterSymbolsTable::symbol_from_ID_at_node(P, TARGET_PRAGMA_IFLD);
	inter_ti ID = P->W.instruction[TEXT_PRAGMA_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	WRITE("pragma %S \"%S\"", InterSymbol::identifier(target_name), S);
}
