[Inter::Property::] The Property Construct.

Defining the property construct.

@

@e PROPERTY_IST

=
void Inter::Property::define(void) {
	inter_construct *IC = InterConstruct::create_construct(PROPERTY_IST, I"property");
	InterConstruct::defines_symbol_in_fields(IC, DEFN_PROP_IFLD, KIND_PROP_IFLD);
	InterConstruct::specify_syntax(IC, I"property TOKENS");
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Property::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Property::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Property::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Property::write);
}

@

@d DEFN_PROP_IFLD 2
@d KIND_PROP_IFLD 3
@d PERM_LIST_PROP_IFLD 4

@d EXTENT_PROP_IFR 5

=
void Inter::Property::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, PROPERTY_IST, ilp->indent_level, eloc);
	if (*E) return;

	text_stream *kind_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, name_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr2.exp[0];
		name_text = mr2.exp[1];
	}

	inter_type prop_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_symbol *prop_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, E);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), prop_name);

	*E = Inter::Property::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prop_name), prop_type, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Property::new(inter_bookmark *IBM, inter_ti PID, inter_type prop_type, inter_ti level, inter_error_location *eloc) {
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_ti L1 = InterWarehouse::create_node_list(warehouse, InterBookmark::package(IBM));
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, PROPERTY_IST, PID, InterTypes::to_TID_wrt_bookmark(IBM, prop_type), L1, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Property::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PERM_LIST_PROP_IFLD] = grid[P->W.instruction[PERM_LIST_PROP_IFLD]];
}

void Inter::Property::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_PROP_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	Inter::Verify::typed_data(owner, P, KIND_PROP_IFLD, -1, E);
}

inter_ti Inter::Property::permissions_list(inter_symbol *prop_name) {
	if (prop_name == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prop_name);
	if (D == NULL) return 0;
	return D->W.instruction[PERM_LIST_PROP_IFLD];
}

void Inter::Property::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PROP_IFLD);
	if (prop_name) {
		WRITE("property ");
		InterTypes::write_optional_type_marker(OUT, P, KIND_PROP_IFLD);
		WRITE("%S", InterSymbol::identifier(prop_name));
		SymbolAnnotation::write_annotations(OUT, P, prop_name);
	} else { *E = Inode::error(P, I"cannot write property", NULL); return; }
}
