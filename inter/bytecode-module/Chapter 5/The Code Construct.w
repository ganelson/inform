[Inter::Code::] The Code Construct.

Defining the Code construct.

@

@e CODE_IST

=
void Inter::Code::define(void) {
	inter_construct *IC = InterConstruct::create_construct(CODE_IST, I"code");
	InterConstruct::specify_syntax(IC, I"code");
	InterConstruct::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterConstruct::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Code::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Code::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Code::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Code::verify_children);
}

@

@d BLOCK_CODE_IFLD 2

@d EXTENT_CODE_IFR 3

=
void Inter::Code::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = InterConstruct::vet_level(IBM, CODE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = InterConstruct::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'code' used outside function", eloc); return; }

	*E = Inter::Code::new(IBM, ilp->indent_level, eloc);
}

inter_error_message *Inter::Code::new(inter_bookmark *IBM, int level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, CODE_IST, 0, eloc, (inter_ti) level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Code::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_CODE_IFR) *E = Inode::error(P, I"extent wrong", NULL);
}

void Inter::Code::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("code");
}

void Inter::Code::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) && (C->W.instruction[0] != SPLAT_IST) && (C->W.instruction[0] != EVALUATION_IST) && (C->W.instruction[0] != LABEL_IST) && (C->W.instruction[0] != VAL_IST) && (C->W.instruction[0] != COMMENT_IST) && (C->W.instruction[0] != NOP_IST)) {
			*E = Inode::error(C, I"only an inv, a val, a splat, a concatenate or a label can be below a code", NULL);
			return;
		}
	}
}
