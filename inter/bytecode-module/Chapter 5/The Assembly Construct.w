[Inter::Assembly::] The Lab Construct.

Defining the Lab construct.

@

@e ASSEMBLY_IST

=
void Inter::Assembly::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		ASSEMBLY_IST,
		L"assembly (%C+)",
		I"assembly", I"assemblies");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Assembly::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Assembly::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Assembly::write);
}

@

@d BLOCK_ASSEMBLY_IFLD 2
@d WHICH_ASSEMBLY_IFLD 3

@d EXTENT_ASSEMBLY_IFR 4

@e ASM_ARROW_ASMMARKER from 1
@e ASM_SP_ASMMARKER
@e ASM_RTRUE_ASMMARKER
@e ASM_RFALSE_ASMMARKER
@e ASM_NEG_ASMMARKER
@e ASM_NEG_RTRUE_ASMMARKER
@e ASM_NEG_RFALSE_ASMMARKER

=
void Inter::Assembly::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (Inter::Annotations::exist(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IBM, ASSEMBLY_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = Inter::Defn::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'assembly' used outside function", eloc); return; }

	inter_ti which = 0;
	if (Str::eq(ilp->mr.exp[0], I"store_to")) which = ASM_ARROW_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"stack")) which = ASM_SP_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_true_if_true")) which = ASM_RTRUE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_false_if_true")) which = ASM_RFALSE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"branch_if_false")) which = ASM_NEG_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_true_if_false")) which = ASM_NEG_RTRUE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_false_if_false")) which = ASM_NEG_RFALSE_ASMMARKER;
	if (which == 0) { *E = Inter::Errors::plain(I"unrecognised 'assembly' marker", eloc); return; }

	*E = Inter::Assembly::new(IBM, which, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Assembly::new(inter_bookmark *IBM, inter_ti which, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, ASSEMBLY_IST, 0, which, eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Assembly::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_ASSEMBLY_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_ti which = P->W.instruction[WHICH_ASSEMBLY_IFLD];
	if ((which == 0) || (which > ASM_NEG_RFALSE_ASMMARKER)) {
		*E = Inode::error(P, I"bad assembly marker code", NULL); return; }
}

void Inter::Assembly::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_ti which = P->W.instruction[WHICH_ASSEMBLY_IFLD];
	switch (which) {
		case ASM_ARROW_ASMMARKER: WRITE("assembly store_to"); break;
		case ASM_SP_ASMMARKER: WRITE("assembly stack"); break;
		case ASM_RTRUE_ASMMARKER: WRITE("assembly return_true_if_true"); break;
		case ASM_RFALSE_ASMMARKER: WRITE("assembly return_false_if_true"); break;
		case ASM_NEG_ASMMARKER: WRITE("assembly branch_if_false"); break;
		case ASM_NEG_RTRUE_ASMMARKER: WRITE("assembly return_true_if_false"); break;
		case ASM_NEG_RFALSE_ASMMARKER: WRITE("assembly return_false_if_false"); break;
		default: *E = Inode::error(P, I"cannot write lab", NULL); return;
	}
}

inter_ti Inter::Assembly::which_marker(inter_tree_node *P) {
	inter_ti which = P->W.instruction[WHICH_ASSEMBLY_IFLD];
	if ((which == 0) || (which > ASM_NEG_RFALSE_ASMMARKER))
		internal_error("bad assembly marker");
	return which;
}
