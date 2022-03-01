[CastInstruction::] The Cast Construct.

Defining the cast construct.

@


=
void CastInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CAST_IST, I"cast");
	InterInstruction::specify_syntax(IC, I"cast IDENTIFIER <- IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_CAST_IFR, EXTENT_CAST_IFR);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, CastInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, CastInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, CastInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, CastInstruction::verify_children);
}

@

@d BLOCK_CAST_IFLD 2
@d TO_KIND_CAST_IFLD 3
@d FROM_KIND_CAST_IFLD 4

@d EXTENT_CAST_IFR 5

=
void CastInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'val' used outside function", eloc); return; }

	inter_symbol *from_kind = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[1], TYPENAME_IST, E);
	if (*E) return;
	inter_symbol *to_kind = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[0], TYPENAME_IST, E);
	if (*E) return;

	*E = CastInstruction::new(IBM, from_kind, to_kind, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *CastInstruction::new(inter_bookmark *IBM, inter_symbol *from_kind, inter_symbol *to_kind, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, CAST_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, to_kind), InterSymbolsTable::id_from_symbol_at_bookmark(IBM, from_kind), eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void CastInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, TO_KIND_CAST_IFLD); if (*E) return;
	*E = VerifyingInter::TID_field(owner, P, FROM_KIND_CAST_IFLD); if (*E) return;
}

void CastInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbols_table *locals = InterPackage::scope_of(P);
	if (locals == NULL) { *E = Inode::error(P, I"function has no symbols table", NULL); return; }
	inter_symbol *from_kind = InterSymbolsTable::symbol_from_ID_at_node(P, FROM_KIND_CAST_IFLD);
	inter_symbol *to_kind = InterSymbolsTable::symbol_from_ID_at_node(P, TO_KIND_CAST_IFLD);
	if ((from_kind) && (to_kind)) {
		WRITE("cast ");
		TextualInter::write_symbol_from(OUT, P, TO_KIND_CAST_IFLD);
		WRITE(" <- ");
		TextualInter::write_symbol_from(OUT, P, FROM_KIND_CAST_IFLD);
	} else { *E = Inode::error(P, I"cannot write cast", NULL); return; }
}

void CastInstruction::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
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
