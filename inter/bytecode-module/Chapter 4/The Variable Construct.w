[Inter::Variable::] The Variable Construct.

Defining the variable construct.

@

@e VARIABLE_IST

=
void Inter::Variable::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		VARIABLE_IST,
		L"variable (%i+) (%i+) = (%c+)",
		I"variable", I"variables");
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
	*E = Inter::Defn::vet_level(IBM, VARIABLE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *var_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *var_kind = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	Inter::Annotations::copy_set_to_symbol(&(ilp->set), var_name);

	inter_ti var_val1 = 0;
	inter_ti var_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), var_kind, ilp->mr.exp[2], &var_val1, &var_val2, Inter::Bookmarks::scope(IBM));
	if (*E) return;

	*E = Inter::Variable::new(IBM, InterSymbolsTables::id_from_IRS_and_symbol(IBM, var_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, var_kind), var_val1, var_val2, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_bookmark *IBM, inter_ti VID, inter_ti KID, inter_ti var_val1, inter_ti var_val2, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_4(IBM, VARIABLE_IST, VID, KID, var_val1, var_val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

void Inter::Variable::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_VAR_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_VAR_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.data[KIND_VAR_IFLD], KIND_IST);
}

void Inter::Variable::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *var_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	inter_symbol *var_kind = InterSymbolsTables::symbol_from_frame_data(P, KIND_VAR_IFLD);
	if ((var_name) && (var_kind)) {
		WRITE("variable %S %S = ", var_name->symbol_name, var_kind->symbol_name);
		Inter::Types::write(OUT, P, var_kind, P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], Inter::Packages::scope_of(P), FALSE);
		Inter::Symbols::write_annotations(OUT, P, var_name);
	} else { *E = Inode::error(P, I"cannot write variable", NULL); return; }
}

inter_symbol *Inter::Variable::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != VARIABLE_IST) return NULL;
	return InterSymbolsTables::symbol_from_frame_data(D, KIND_VAR_IFLD);
}
