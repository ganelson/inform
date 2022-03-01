[ReferenceInstruction::] The Reference Construct.

Defining the Reference construct.

@


=
void ReferenceInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(REFERENCE_IST, I"reference");
	InterInstruction::specify_syntax(IC, I"reference");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_RCE_IFR, EXTENT_RCE_IFR);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ReferenceInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ReferenceInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, ReferenceInstruction::verify_children);
}

@

Used to be BLOCK_RCE_IFLD 2 with extent 3

@d EXTENT_RCE_IFR 2

=
void ReferenceInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'reference' used outside function", eloc); return; }

	*E = ReferenceInstruction::new(IBM, ilp->indent_level, eloc);
}

inter_error_message *ReferenceInstruction::new(inter_bookmark *IBM, int level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, REFERENCE_IST, eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}


void ReferenceInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("reference");
}

void ReferenceInstruction::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) && (C->W.instruction[0] != REF_IST) && (C->W.instruction[0] != SPLAT_IST) && (C->W.instruction[0] != VAL_IST) && (C->W.instruction[0] != LABEL_IST)) {
			*E = Inode::error(C, I"only an inv, a ref, a splat, a val, or a label can be below a reference", NULL);
			return;
		}
	}
}

int ReferenceInstruction::node_is_ref_to(inter_tree *I, inter_tree_node *P, inter_ti seek_bip) {
	int reffed = FALSE;
	while (P->W.instruction[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.instruction[ID_IFLD] == INV_IST) {
		if (P->W.instruction[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = InvInstruction::invokee(P);
			inter_ti bip = Primitives::to_BIP(I, prim);
			if ((bip == seek_bip) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}
