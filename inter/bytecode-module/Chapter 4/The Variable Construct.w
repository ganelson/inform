[Inter::Variable::] The Variable Construct.

Defining the variable construct.

@

@e VARIABLE_IST

=
void Inter::Variable::define(void) {
	inter_construct *IC = InterConstruct::create_construct(VARIABLE_IST, I"variable");
	InterConstruct::specify_syntax(IC, L"variable (%i+) (%i+) = (%c+)");
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
	*E = InterConstruct::vet_level(IBM, VARIABLE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *var_name = Inter::Textual::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *var_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), var_name);

	inter_ti var_val1 = 0;
	inter_ti var_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, InterBookmark::tree(IBM), InterBookmark::package(IBM), var_kind, ilp->mr.exp[2], &var_val1, &var_val2, InterBookmark::scope(IBM));
	if (*E) return;

	*E = Inter::Variable::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_name), InterSymbolsTable::id_from_symbol_at_bookmark(IBM, var_kind), var_val1, var_val2, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_bookmark *IBM, inter_ti VID, inter_ti KID, inter_ti var_val1, inter_ti var_val2, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, VARIABLE_IST, VID, KID, var_val1, var_val2, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Variable::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_VAR_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_VAR_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.instruction[KIND_VAR_IFLD], KIND_IST);
}

void Inter::Variable::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *var_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_VAR_IFLD);
	inter_symbol *var_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_VAR_IFLD);
	if ((var_name) && (var_kind)) {
		WRITE("variable %S %S = ", var_name->symbol_name, var_kind->symbol_name);
		Inter::Types::write(OUT, P, var_kind, P->W.instruction[VAL1_VAR_IFLD], P->W.instruction[VAL2_VAR_IFLD], InterPackage::scope_of(P), FALSE);
		SymbolAnnotation::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write variable", NULL); return; }
}

inter_symbol *Inter::Variable::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.instruction[ID_IFLD] != VARIABLE_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(D, KIND_VAR_IFLD);
}
