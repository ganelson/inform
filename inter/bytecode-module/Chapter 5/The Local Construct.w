[LocalInstruction::] The Local Construct.

Defining the local construct.

@


=
void LocalInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(LOCAL_IST, I"local");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_LOCAL_IFLD, KIND_LOCAL_IFLD);
	InterInstruction::specify_syntax(IC, I"local TOKENS");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_LOCAL_IFR, EXTENT_LOCAL_IFR);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_ANNOTATIONS_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, LocalInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, LocalInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, LocalInstruction::write);
}

@

@d BLOCK_LOCAL_IFLD 2
@d DEFN_LOCAL_IFLD 3
@d KIND_LOCAL_IFLD 4

@d EXTENT_LOCAL_IFR 5

=
void LocalInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = InterBookmark::package(IBM);
	if (routine == NULL) { *E = InterErrors::plain(I"'local' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = InterErrors::plain(I"function has no symbols table", eloc); return; }

	text_stream *kind_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, name_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr2.exp[0];
		name_text = mr2.exp[1];
	}

	inter_type var_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_symbol *var_name = TextualInter::new_symbol(eloc, locals, name_text, E);
	if (*E) return;
	InterSymbol::make_local(var_name);

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), var_name);

	*E = LocalInstruction::new(IBM, var_name, var_type, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *LocalInstruction::new(inter_bookmark *IBM, inter_symbol *var_name,
	inter_type var_type, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, LOCAL_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_name), InterTypes::to_TID_at(IBM, var_type), eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void LocalInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::TID_field(owner, P, KIND_LOCAL_IFLD);
}

void LocalInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *var_name = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[DEFN_LOCAL_IFLD]);
	if (var_name) {
		WRITE("local ");
		TextualInter::write_optional_type_marker(OUT, P, KIND_LOCAL_IFLD);
		WRITE("%S", InterSymbol::identifier(var_name));
		SymbolAnnotation::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write local", NULL); return; }
}
