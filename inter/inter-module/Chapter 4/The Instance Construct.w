[Inter::Instance::] The Instance Construct.

Defining the instance construct.

@

@e INSTANCE_IST

=
void Inter::Instance::define(void) {
	Inter::Defn::create_construct(
		INSTANCE_IST,
		L"instance (%i+) (%c+)",
		&Inter::Instance::read,
		NULL,
		&Inter::Instance::verify,
		&Inter::Instance::write,
		NULL,
		NULL,
		NULL,
		&Inter::Instance::show_dependencies,
		I"instance", I"instances");
}

@

@d DEFN_INST_IFLD 2
@d KIND_INST_IFLD 3
@d VAL1_INST_IFLD 4
@d VAL2_INST_IFLD 5
@d PLIST_INST_IFLD 6
@d PERM_LIST_INST_IFLD 7

@d EXTENT_INST_IFR 8

=
inter_error_message *Inter::Instance::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, INSTANCE_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	text_stream *ktext = ilp->mr.exp[1], *vtext = NULL;

	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, ktext, L"(%i+) = (%c+)")) { ktext = mr2.exp[0]; vtext = mr2.exp[1]; }

	inter_symbol *inst_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;
	inter_symbol *inst_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ktext, KIND_IST, &E);
	if (E) return E;

	inter_data_type *idt = Inter::Kind::data_type(inst_kind);
	if (Inter::Types::is_enumerated(idt) == FALSE)
		return Inter::Errors::quoted(I"not a kind which has instances", ilp->mr.exp[1], eloc);

	inter_t v1 = UNDEF_IVAL, v2 = 0;
	if (vtext) {
		E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, NULL, vtext, &v1, &v2, Inter::Bookmarks::scope(IRS));
		if (E) return E;
	}
	return Inter::Instance::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, inst_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, inst_kind), v1, v2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Instance::new(inter_reading_state *IRS, inter_t SID, inter_t KID, inter_t V1, inter_t V2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_6(IRS, INSTANCE_IST, SID, KID, V1, V2, Inter::create_frame_list(IRS->read_into), Inter::create_frame_list(IRS->read_into), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Instance::verify(inter_frame P) {
	if (P.extent != EXTENT_INST_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_INST_IFLD); if (E) return E;
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	E = Inter::Verify::symbol(P, P.data[KIND_INST_IFLD], KIND_IST); if (E) return E;
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);
	inter_data_type *idt = Inter::Kind::data_type(inst_kind);
	if (Inter::Types::is_enumerated(idt)) {
		if (P.data[VAL1_INST_IFLD] == UNDEF_IVAL) {
			P.data[VAL1_INST_IFLD] = LITERAL_IVAL;
			P.data[VAL2_INST_IFLD] = Inter::Kind::next_enumerated_value(inst_kind);
		}
	} else return Inter::Frame::error(&P, I"not a kind which has instances", NULL);
	E = Inter::Verify::value(P, VAL1_INST_IFLD, inst_kind); if (E) return E;

	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;
	if (vcount == 0) Inter::Kind::new_instance(inst_kind, inst_name);

	return NULL;
}

inter_t Inter::Instance::permissions_list(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PERM_LIST_INST_IFLD];
}

inter_error_message *Inter::Instance::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);
	if ((inst_name) && (inst_kind)) {
		inter_data_type *idt = Inter::Kind::data_type(inst_kind);
		if (idt) {
			WRITE("instance %S %S = ", inst_name->symbol_name, inst_kind->symbol_name);
			Inter::Types::write(OUT, P.repo_segment->owning_repo, NULL,
				P.data[VAL1_INST_IFLD], P.data[VAL2_INST_IFLD], Inter::Packages::scope_of(P), FALSE);
		} else return Inter::Frame::error(&P, I"instance with bad data type", NULL);
	} else return Inter::Frame::error(&P, I"bad instance", NULL);
	Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, inst_name);
	return NULL;
}

void Inter::Instance::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);
	if ((inst_name) && (inst_kind)) (*callback)(inst_name, inst_kind, state);
}

inter_t Inter::Instance::properties_list(inter_symbol *inst_name) {
	if (inst_name == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(inst_name);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PLIST_INST_IFLD];
}

inter_symbol *Inter::Instance::kind_of(inter_symbol *inst_name) {
	if (inst_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(inst_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != INSTANCE_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_INST_IFLD);
}
