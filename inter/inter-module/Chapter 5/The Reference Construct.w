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
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, REFERENCE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'reference' used outside function", eloc); return; }

	*E = Inter::Reference::new(IBM, routine, ilp->indent_level, eloc);
}

inter_error_message *Inter::Reference::new(inter_bookmark *IBM, inter_symbol *routine, int level, inter_error_location *eloc) {
	inter_tree_node *P = Inter::Frame::fill_1(IBM, REFERENCE_IST, 0, eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::insert(P, IBM);
	return NULL;
}

void Inter::Reference::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_RCE_IFR) { *E = Inter::Frame::error(P, I"extent wrong", NULL); return; }
}

void Inter::Reference::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("reference");
}

void Inter::Reference::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.data[0] != INV_IST) && (C->W.data[0] != REF_IST) && (C->W.data[0] != SPLAT_IST) && (C->W.data[0] != VAL_IST) && (C->W.data[0] != LABEL_IST)) {
			*E = Inter::Frame::error(C, I"only an inv, a ref, a splat, a val, or a label can be below a reference", NULL);
			return;
		}
	}
}
