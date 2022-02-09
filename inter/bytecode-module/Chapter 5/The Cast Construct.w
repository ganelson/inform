[Inter::Cast::] The Cast Construct.

Defining the cast construct.

@

@e CAST_IST

=
void Inter::Cast::define(void) {
	inter_construct *IC = InterConstruct::create_construct(CAST_IST, I"cast");
	InterConstruct::specify_syntax(IC, I"cast IDENTIFIER <- IDENTIFIER");
	InterConstruct::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterConstruct::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Cast::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Cast::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Cast::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Cast::verify_children);
}

@

@d BLOCK_CAST_IFLD 2
@d TO_KIND_CAST_IFLD 3
@d FROM_KIND_CAST_IFLD 4

@d EXTENT_CAST_IFR 5

=
void Inter::Cast::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = InterConstruct::vet_level(IBM, CAST_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = InterConstruct::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'val' used outside function", eloc); return; }

	inter_symbol *from_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;
	inter_symbol *to_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	*E = Inter::Cast::new(IBM, from_kind, to_kind, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Cast::new(inter_bookmark *IBM, inter_symbol *from_kind, inter_symbol *to_kind, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, CAST_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, to_kind), InterSymbolsTable::id_from_symbol_at_bookmark(IBM, from_kind), eloc, (inter_ti) level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Cast::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_CAST_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[TO_KIND_CAST_IFLD], KIND_IST); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[FROM_KIND_CAST_IFLD], KIND_IST); if (*E) return;
}

void Inter::Cast::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbols_table *locals = InterPackage::scope_of(P);
	if (locals == NULL) { *E = Inode::error(P, I"function has no symbols table", NULL); return; }
	inter_symbol *from_kind = InterSymbolsTable::symbol_from_ID_at_node(P, FROM_KIND_CAST_IFLD);
	inter_symbol *to_kind = InterSymbolsTable::symbol_from_ID_at_node(P, TO_KIND_CAST_IFLD);
	if ((from_kind) && (to_kind)) {
		WRITE("cast %S <- %S", to_kind->symbol_name, from_kind->symbol_name);
	} else { *E = Inode::error(P, I"cannot write cast", NULL); return; }
}

void Inter::Cast::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	int arity_as_invoked = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		arity_as_invoked++;
		if ((C->W.instruction[0] != INV_IST) && (C->W.instruction[0] != VAL_IST) && (C->W.instruction[0] != EVALUATION_IST) && (C->W.instruction[0] != CAST_IST)) {
			*E = Inode::error(P, I"only inv, cast, concatenate and val can be under a cast", NULL);
			return;
		}
	}
	if (arity_as_invoked != 1) {
		*E = Inode::error(P, I"a cast should have exactly one child", NULL);
		return;
	}
}
