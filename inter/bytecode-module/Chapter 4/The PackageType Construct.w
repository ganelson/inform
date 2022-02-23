[Inter::PackageType::] The PackageType Construct.

Defining the packagetype construct.

@

@e PACKAGETYPE_IST

=
void Inter::PackageType::define(void) {
	inter_construct *IC = InterConstruct::create_construct(PACKAGETYPE_IST, I"packagetype");
	InterConstruct::defines_symbol_in_fields(IC, DEFN_PTYPE_IFLD, -1);
	InterConstruct::specify_syntax(IC, I"packagetype _IDENTIFIER");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::PackageType::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::PackageType::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::PackageType::write);
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
}

@

@d DEFN_PTYPE_IFLD 2

@d EXTENT_PTYPE_IFR 3

=
void Inter::PackageType::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, PACKAGETYPE_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *ptype_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	*E = Inter::PackageType::new_packagetype(IBM, ptype_name, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::PackageType::new_packagetype(inter_bookmark *IBM, inter_symbol *ptype, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_1_data_field(IBM, PACKAGETYPE_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, ptype), eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::PackageType::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent < EXTENT_PTYPE_IFR) { *E = Inode::error(P, I"package extent wrong", NULL); return; }
}

void Inter::PackageType::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *ptype_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PTYPE_IFLD);
	if (ptype_name) WRITE("packagetype %S", InterSymbol::identifier(ptype_name));
	else { *E = Inode::error(P, I"cannot write packagetype", NULL); return; }
}
