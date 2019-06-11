[Inter::Variable::] The Variable Construct.

Defining the variable construct.

@

@e VARIABLE_IST

=
void Inter::Variable::define(void) {
	Inter::Defn::create_construct(
		VARIABLE_IST,
		L"variable (%i+) (%i+) = (%c+)",
		&Inter::Variable::read,
		NULL,
		&Inter::Variable::verify,
		&Inter::Variable::write,
		NULL,
		NULL,
		NULL,
		NULL,
		&Inter::Variable::show_dependencies,
		I"variable", I"variables");
}

@

@d DEFN_VAR_IFLD 2
@d KIND_VAR_IFLD 3
@d VAL1_VAR_IFLD 4
@d VAL2_VAR_IFLD 5

@d EXTENT_VAR_IFR 6

=
inter_error_message *Inter::Variable::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, VARIABLE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *var_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;
	inter_symbol *var_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], KIND_IST, &E);
	if (E) return E;

	for (int i=0; i<ilp->no_annotations; i++)
		Inter::Symbols::annotate(IRS->read_into, var_name, ilp->annotations[i]);

	inter_t var_val1 = 0;
	inter_t var_val2 = 0;
	E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, var_kind, ilp->mr.exp[2], &var_val1, &var_val2, Inter::Bookmarks::scope(IRS));
	if (E) return E;

	return Inter::Variable::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, var_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, var_kind), var_val1, var_val2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Variable::new(inter_reading_state *IRS, inter_t VID, inter_t KID, inter_t var_val1, inter_t var_val2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, VARIABLE_IST, VID, KID, var_val1, var_val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Variable::verify(inter_frame P) {
	if (P.extent != EXTENT_VAR_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_VAR_IFLD); if (E) return E;
	E = Inter::Verify::symbol(P, P.data[KIND_VAR_IFLD], KIND_IST); if (E) return E;
	return NULL;
}

inter_error_message *Inter::Variable::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	inter_symbol *var_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_VAR_IFLD);
	if ((var_name) && (var_kind)) {
		WRITE("variable %S %S = ", var_name->symbol_name, var_kind->symbol_name);
		Inter::Types::write(OUT, P.repo_segment->owning_repo, var_kind, P.data[VAL1_VAR_IFLD], P.data[VAL2_VAR_IFLD], Inter::Packages::scope_of(P), FALSE);
		Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, var_name);
	} else return Inter::Frame::error(&P, I"cannot write variable", NULL);
	return NULL;
}

void Inter::Variable::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	inter_symbol *var_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_VAR_IFLD);
	if ((var_name) && (var_kind)) {
		(*callback)(var_name, var_kind, state);
		inter_t v1 = P.data[VAL1_VAR_IFLD], v2 = P.data[VAL2_VAR_IFLD];
		inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
		if (S) (*callback)(var_name, S, state);
	}
}

inter_symbol *Inter::Variable::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != VARIABLE_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_VAR_IFLD);
}
