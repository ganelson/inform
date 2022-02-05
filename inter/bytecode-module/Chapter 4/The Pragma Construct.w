[Inter::Pragma::] The Pragma Construct.

Defining the pragma construct.

@

@e PRAGMA_IST

=
void Inter::Pragma::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PRAGMA_IST,
		L"pragma (%i+) \"(%c+)\"",
		I"pragma", I"pragmas"); /* pragmae? pragmata? */
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Pragma::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Pragma::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Pragma::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Pragma::write);
}

@

@d TARGET_PRAGMA_IFLD 2
@d TEXT_PRAGMA_IFLD 3

@d EXTENT_PRAGMA_IFR 4

=
void Inter::Pragma::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, PRAGMA_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *target_name = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), ilp->mr.exp[0]);
	if (target_name == NULL)
		target_name = Inter::Textual::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
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
				default: { *E = Inter::Errors::plain(I"no such backslash escape", eloc); return; }
			}
		}
		if (Inter::Constant::char_acceptable(c) == FALSE) { *E = Inter::Errors::quoted(I"bad character in text", S, eloc); return; }
		PUT_TO(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ID), c);
		literal_mode = FALSE;
	}

	*E = Inter::Pragma::new(IBM, target_name, ID, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Pragma::new(inter_bookmark *IBM, inter_symbol *target_name, inter_ti pragma_text, inter_ti level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, PRAGMA_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, target_name), pragma_text, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Pragma::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[TEXT_PRAGMA_IFLD] = grid[P->W.instruction[TEXT_PRAGMA_IFLD]];
}

void Inter::Pragma::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_PRAGMA_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_symbol *target_name = InterSymbolsTable::symbol_from_ID_at_node(P, TARGET_PRAGMA_IFLD);
	if (target_name == NULL) { *E = Inode::error(P, I"no target name", NULL); return; }
	if (P->W.instruction[TEXT_PRAGMA_IFLD] == 0) { *E = Inode::error(P, I"no pragma text", NULL); return; }
}

void Inter::Pragma::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *target_name = InterSymbolsTable::symbol_from_ID_at_node(P, TARGET_PRAGMA_IFLD);
	inter_ti ID = P->W.instruction[TEXT_PRAGMA_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	WRITE("pragma %S \"%S\"", target_name->symbol_name, S);
}
