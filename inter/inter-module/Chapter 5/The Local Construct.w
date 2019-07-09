[Inter::Local::] The Local Construct.

Defining the local construct.

@

@e LOCAL_IST

=
void Inter::Local::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		LOCAL_IST,
		L"local (%C+) (%c+)",
		I"local", I"locals");
	IC->min_level = 0;
	IC->max_level = 0;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
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
void Inter::Local::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, LOCAL_IST, ilp->indent_level, eloc);
	if (*E) return;
	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'local' used outside function", eloc); return; }
	inter_symbols_table *locals = Inter::Package::local_symbols(routine);
	if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }

	inter_symbol *var_name = Inter::Textual::find_undefined_symbol(IRS, eloc, locals, ilp->mr.exp[0], E);
	if (*E) return;
	if ((var_name->symbol_scope != PRIVATE_ISYMS) ||
		(var_name->symbol_type != MISC_ISYMT)) { *E = Inter::Errors::plain(I"symbol of wrong S-type", eloc); return; }

	inter_symbol *var_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;

	for (int i=0; i<ilp->no_annotations; i++)
		Inter::Symbols::annotate(IRS->read_into, var_name, ilp->annotations[i]);

	*E = Inter::Local::new(IRS, routine, var_name, var_kind, ilp->terminal_comment, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Local::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *var_name, inter_symbol *var_kind, inter_t ID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, LOCAL_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, var_name), var_kind?(Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, var_kind)):0, eloc, level);
	Inter::Frame::attach_comment(P, ID);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Local::verify(inter_construct *IC, inter_frame P, inter_error_message **E) {
	if (P.extent != EXTENT_LOCAL_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) { *E = Inter::Frame::error(&P, I"no symbols table in function", NULL); return; }
	*E = Inter::Verify::local_defn(P, DEFN_LOCAL_IFLD, locals); if (*E) return;
	*E = Inter::Verify::symbol(P, P.data[KIND_LOCAL_IFLD], KIND_IST); if (*E) return;
}

void Inter::Local::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	inter_symbol *var_name = Inter::SymbolsTables::local_symbol_from_id(routine, P.data[DEFN_LOCAL_IFLD]);
	inter_symbol *var_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_LOCAL_IFLD);
	if (var_name) {
		WRITE("local %S %S", var_name->symbol_name, var_kind->symbol_name);
		Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, var_name);
	} else { *E = Inter::Frame::error(&P, I"cannot write local", NULL); return; }
}

inter_symbol *Inter::Local::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != LOCAL_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_LOCAL_IFLD);
}
