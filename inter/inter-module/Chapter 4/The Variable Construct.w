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

	for (int i=0; i<ilp->no_annotations; i++)
		Inter::Symbols::annotate(var_name, ilp->annotations[i]);

	inter_t var_val1 = 0;
	inter_t var_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), var_kind, ilp->mr.exp[2], &var_val1, &var_val2, Inter::Bookmarks::scope(IBM));
	if (*E) return;

	*E = Inter::Variable::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, var_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, var_kind), var_val1, var_val2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_bookmark *IBM, inter_t VID, inter_t KID, inter_t var_val1, inter_t var_val2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IBM, VARIABLE_IST, VID, KID, var_val1, var_val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Frame::insert(P, IBM);
	return NULL;
}

void Inter::Variable::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_VAR_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	*E = Inter__Verify__defn(owner, P, DEFN_VAR_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P.data[KIND_VAR_IFLD], KIND_IST);
}

void Inter::Variable::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	inter_symbol *var_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_VAR_IFLD);
	if ((var_name) && (var_kind)) {
		WRITE("variable %S %S = ", var_name->symbol_name, var_kind->symbol_name);
		Inter::Types::write(OUT, &P, var_kind, P.data[VAL1_VAR_IFLD], P.data[VAL2_VAR_IFLD], Inter::Packages::scope_of(P), FALSE);
		Inter::Symbols::write_annotations(OUT, &P, var_name);
	} else { *E = Inter::Frame::error(&P, I"cannot write variable", NULL); return; }
}

inter_symbol *Inter::Variable::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != VARIABLE_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_VAR_IFLD);
}
