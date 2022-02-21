[Inter::Variable::] The Variable Construct.

Defining the variable construct.

@

@e VARIABLE_IST

=
void Inter::Variable::define(void) {
	inter_construct *IC = InterConstruct::create_construct(VARIABLE_IST, I"variable");
	InterConstruct::specify_syntax(IC, I"variable TOKENS = TOKENS");
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Variable::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Variable::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Variable::write);
}

@

@d DEFN_VAR_IFLD 2
@d KIND_VAR_IFLD 3
@d VAL1_VAR_IFLD 4
@d VAL2_VAR_IFLD 5

@d EXTENT_VAR_IFR 6

=
void Inter::Variable::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, VARIABLE_IST, ilp->indent_level, eloc);
	if (*E) return;

	text_stream *kind_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, name_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr2.exp[0];
		name_text = mr2.exp[1];
	}

	inter_type var_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_symbol *var_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, E);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), var_name);

	inter_ti var_val1 = 0;
	inter_ti var_val2 = 0;
	*E = InterValuePairs::parse(ilp->line, eloc, IBM, var_type, ilp->mr.exp[1], &var_val1, &var_val2, InterBookmark::scope(IBM));
	if (*E) return;

	*E = Inter::Variable::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_name), var_type, var_val1, var_val2, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_bookmark *IBM, inter_ti VID, inter_type var_type, inter_ti var_val1, inter_ti var_val2, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, VARIABLE_IST, VID, InterTypes::to_TID_wrt_bookmark(IBM, var_type), var_val1, var_val2, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Variable::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_VAR_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_VAR_IFLD); if (*E) return;
	Inter::Verify::typed_data(owner, P, KIND_VAR_IFLD, VAL1_VAR_IFLD, E);
}

void Inter::Variable::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *var_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_VAR_IFLD);
	if (var_name) {
		WRITE("variable ");
		InterTypes::write_optional_type_marker(OUT, P, KIND_VAR_IFLD);
		WRITE("%S = ", InterSymbol::identifier(var_name));
		InterValuePairs::write(OUT, P, P->W.instruction[VAL1_VAR_IFLD], P->W.instruction[VAL2_VAR_IFLD], InterPackage::scope_of(P), FALSE);
		SymbolAnnotation::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write variable", NULL); return; }
}

inter_type Inter::Variable::type_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return InterTypes::untyped();
	inter_tree_node *D = InterSymbol::definition(con_symbol);
	if (D == NULL) return InterTypes::untyped();
	if (D->W.instruction[ID_IFLD] != VARIABLE_IST) return InterTypes::untyped();
	return InterTypes::from_TID_in_field(D, KIND_VAR_IFLD);
}
