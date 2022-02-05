[Inter::Reference::] The Reference Construct.

Defining the Reference construct.

@

@e REFERENCE_IST

=
void Inter::Reference::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		REFERENCE_IST,
		L"reference",
		I"reference", I"references");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE + CAN_HAVE_CHILDREN;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Reference::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Reference::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Reference::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Reference::verify_children);
}

@

@d BLOCK_RCE_IFLD 2

@d EXTENT_RCE_IFR 3

=
void Inter::Reference::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, REFERENCE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = Inter::Defn::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'reference' used outside function", eloc); return; }

	*E = Inter::Reference::new(IBM, ilp->indent_level, eloc);
}

inter_error_message *Inter::Reference::new(inter_bookmark *IBM, int level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, REFERENCE_IST, 0, eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Reference::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_RCE_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
}

void Inter::Reference::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("reference");
}

void Inter::Reference::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) && (C->W.instruction[0] != REF_IST) && (C->W.instruction[0] != SPLAT_IST) && (C->W.instruction[0] != VAL_IST) && (C->W.instruction[0] != LABEL_IST)) {
			*E = Inode::error(C, I"only an inv, a ref, a splat, a val, or a label can be below a reference", NULL);
			return;
		}
	}
}

int Inter::Reference::node_is_ref_to(inter_tree *I, inter_tree_node *P, inter_ti seek_bip) {
	int reffed = FALSE;
	while (P->W.instruction[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.instruction[ID_IFLD] == INV_IST) {
		if (P->W.instruction[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(P);
			inter_ti bip = Primitives::to_BIP(I, prim);
			if ((bip == seek_bip) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}
