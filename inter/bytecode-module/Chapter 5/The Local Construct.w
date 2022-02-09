[Inter::Local::] The Local Construct.

Defining the local construct.

@

@e LOCAL_IST

=
void Inter::Local::define(void) {
	inter_construct *IC = InterConstruct::create_construct(LOCAL_IST, I"local");
	InterConstruct::specify_syntax(IC, I"local TOKEN TOKENS");
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Local::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Local::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Local::write);
}

@

@d BLOCK_LOCAL_IFLD 2
@d DEFN_LOCAL_IFLD 3
@d KIND_LOCAL_IFLD 4

@d EXTENT_LOCAL_IFR 5

=
void Inter::Local::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::vet_level(IBM, LOCAL_IST, ilp->indent_level, eloc);
	if (*E) return;
	inter_package *routine = InterConstruct::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'local' used outside function", eloc); return; }
	inter_symbols_table *locals = InterPackage::scope(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *var_name = Inter::Textual::find_undefined_symbol(IBM, eloc, locals, ilp->mr.exp[0], E);
	if (*E) return;
	if (InterSymbol::is_local(var_name) == FALSE) { *E = Inter::Errors::plain(I"symbol of wrong S-type", eloc); return; }

	inter_symbol *var_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), var_name);

	*E = Inter::Local::new(IBM, var_name, var_kind, ilp->terminal_comment, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Local::new(inter_bookmark *IBM, inter_symbol *var_name, inter_symbol *var_kind, inter_ti ID, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, LOCAL_IST, 0, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_name), var_kind?(InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_kind)):0, eloc, level);
	Inode::attach_comment(P, ID);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Local::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_LOCAL_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_symbols_table *locals = InterPackage::scope(owner);
	if (locals == NULL) { *E = Inode::error(P, I"no symbols table in function", NULL); return; }
	*E = Inter::Verify::local_defn(P, DEFN_LOCAL_IFLD, locals); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[KIND_LOCAL_IFLD], KIND_IST); if (*E) return;
}

void Inter::Local::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = InterPackage::container(P);
	inter_symbol *var_name = InterSymbolsTable::symbol_from_ID_in_package(pack, P->W.instruction[DEFN_LOCAL_IFLD]);
	inter_symbol *var_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_LOCAL_IFLD);
	if (var_name) {
		WRITE("local %S %S", var_name->symbol_name, var_kind->symbol_name);
		SymbolAnnotation::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write local", NULL); return; }
}

inter_symbol *Inter::Local::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.instruction[ID_IFLD] != LOCAL_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(D, KIND_LOCAL_IFLD);
}
