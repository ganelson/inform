[Inter::Variable::] The Variable Construct.

Defining the variable construct.

@

@e VARIABLE_IST

=
void Inter::Variable::define(void) {
	inter_construct *IC = InterConstruct::create_construct(VARIABLE_IST, I"variable");
	InterConstruct::defines_symbol_in_fields(IC, DEFN_VAR_IFLD, KIND_VAR_IFLD);
	InterConstruct::specify_syntax(IC, I"variable TOKENS = TOKENS");
	InterConstruct::fix_instruction_length_between(IC, EXTENT_VAR_IFR, EXTENT_VAR_IFR);
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

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, var_type, ilp->mr.exp[1], &val);
	if (*E) return;

	*E = Inter::Variable::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_name), var_type, val, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_bookmark *IBM, inter_ti VID, inter_type var_type, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, VARIABLE_IST, VID, InterTypes::to_TID_at(IBM, var_type), InterValuePairs::to_word1(val), InterValuePairs::to_word2(val), eloc, level);
	inter_error_message *E = Inter::Verify::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Variable::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = Inter::Verify::TID_field(owner, P, KIND_VAR_IFLD); if (*E) return;
	inter_type type = InterTypes::from_TID_in_field(P, KIND_VAR_IFLD);
	*E = Inter::Verify::data_pair_fields(owner, P, VAL1_VAR_IFLD, type); if (*E) return;
}

void Inter::Variable::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *var_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_VAR_IFLD);
	if (var_name) {
		WRITE("variable ");
		TextualInter::write_optional_type_marker(OUT, P, KIND_VAR_IFLD);
		WRITE("%S = ", InterSymbol::identifier(var_name));
		TextualInter::write_pair(OUT, P, InterValuePairs::get(P, VAL1_VAR_IFLD), FALSE);
		SymbolAnnotation::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write variable", NULL); return; }
}
