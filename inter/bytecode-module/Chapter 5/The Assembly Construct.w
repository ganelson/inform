[AssemblyInstruction::] The Assembly Construct.

Defining the assembly construct.

@

=
void AssemblyInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(ASSEMBLY_IST, I"assembly");
	InterInstruction::specify_syntax(IC, I"assembly TOKEN");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_ASSEMBLY_IFR, EXTENT_ASSEMBLY_IFR);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, AssemblyInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, AssemblyInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, AssemblyInstruction::write);
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
void AssemblyInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'assembly' used outside function", eloc); return; }

	inter_ti which = 0;
	if (Str::eq(ilp->mr.exp[0], I"store_to")) which = ASM_ARROW_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"stack")) which = ASM_SP_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_true_if_true")) which = ASM_RTRUE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_false_if_true")) which = ASM_RFALSE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"branch_if_false")) which = ASM_NEG_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_true_if_false")) which = ASM_NEG_RTRUE_ASMMARKER;
	else if (Str::eq(ilp->mr.exp[0], I"return_false_if_false")) which = ASM_NEG_RFALSE_ASMMARKER;
	if (which == 0) { *E = InterErrors::plain(I"unrecognised 'assembly' marker", eloc); return; }

	*E = AssemblyInstruction::new(IBM, which, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *AssemblyInstruction::new(inter_bookmark *IBM, inter_ti which, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, ASSEMBLY_IST, 0, which, eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void AssemblyInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_ti which = P->W.instruction[WHICH_ASSEMBLY_IFLD];
	if ((which == 0) || (which > ASM_NEG_RFALSE_ASMMARKER)) {
		*E = Inode::error(P, I"bad assembly marker code", NULL); return; }
}

void AssemblyInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
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

inter_ti AssemblyInstruction::which_marker(inter_tree_node *P) {
	inter_ti which = P->W.instruction[WHICH_ASSEMBLY_IFLD];
	if ((which == 0) || (which > ASM_NEG_RFALSE_ASMMARKER))
		internal_error("bad assembly marker");
	return which;
}
