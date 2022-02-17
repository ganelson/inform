[Inter::Ref::] The Ref Construct.

Defining the ref construct.

@

@e REF_IST

=
void Inter::Ref::define(void) {
	inter_construct *IC = InterConstruct::create_construct(REF_IST, I"ref");
	InterConstruct::specify_syntax(IC, I"ref TOKENS");
	InterConstruct::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Ref::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Ref::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Ref::write);
}

@

@d BLOCK_REF_IFLD 2
@d KIND_REF_IFLD 3
@d VAL1_REF_IFLD 4
@d VAL2_REF_IFLD 5

@d EXTENT_REF_IFR 6

=
void Inter::Ref::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = InterConstruct::check_level_in_package(IBM, REF_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = Inter::Errors::plain(I"'ref' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	text_stream *kind_text = NULL, *value_text = ilp->mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, value_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr2.exp[0];
		value_text = mr2.exp[1];
	}

	inter_type ref_type = Inter::Types::parse(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_ti var_val1 = 0;
	inter_ti var_val2 = 0;
	*E = Inter::Types::read_to_type(ilp->line, eloc, IBM, ref_type, value_text, &var_val1, &var_val2, locals);
	if (*E) return;

	*E = Inter::Ref::new(IBM, ref_type, ilp->indent_level, var_val1, var_val2, eloc);
}

inter_error_message *Inter::Ref::new(inter_bookmark *IBM, inter_type ref_type, int level, inter_ti val1, inter_ti val2, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, REF_IST, 0, Inter::Types::to_TID(IBM, ref_type), val1, val2, eloc, (inter_ti) level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Ref::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_REF_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	Inter::Types::verify_type_field(owner, P, KIND_REF_IFLD, VAL1_REF_IFLD, E);
}

void Inter::Ref::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbols_table *locals = InterPackage::scope(pack);
	if (locals == NULL) { *E = Inode::error(P, I"function has no symbols table", NULL); return; }
	WRITE("ref ");
	Inter::Types::write_type_field(OUT, P, KIND_REF_IFLD);
	Inter::Types::write_pair(OUT, P, P->W.instruction[VAL1_REF_IFLD], P->W.instruction[VAL2_REF_IFLD], locals, FALSE);
}
