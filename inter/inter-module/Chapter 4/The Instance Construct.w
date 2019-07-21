[Inter::Instance::] The Instance Construct.

Defining the instance construct.

@

@e INSTANCE_IST

=
void Inter::Instance::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		INSTANCE_IST,
		L"instance (%i+) (%c+)",
		I"instance", I"instances");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Instance::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Instance::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Instance::write);
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
void Inter::Instance::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, INSTANCE_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	text_stream *ktext = ilp->mr.exp[1], *vtext = NULL;

	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, ktext, L"(%i+) = (%c+)")) { ktext = mr2.exp[0]; vtext = mr2.exp[1]; }

	inter_symbol *inst_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *inst_kind = Inter::Textual::find_symbol(IBM->read_into, eloc, Inter::Bookmarks::scope(IBM), ktext, KIND_IST, E);
	if (*E) return;

	inter_data_type *idt = Inter::Kind::data_type(inst_kind);
	if (Inter::Types::is_enumerated(idt) == FALSE)
		{ *E = Inter::Errors::quoted(I"not a kind which has instances", ilp->mr.exp[1], eloc); return; }

	inter_t v1 = UNDEF_IVAL, v2 = 0;
	if (vtext) {
		*E = Inter::Types::read(ilp->line, eloc, IBM->read_into, Inter::Bookmarks::package(IBM), NULL, vtext, &v1, &v2, Inter::Bookmarks::scope(IBM));
		if (*E) return;
	}
	*E = Inter::Instance::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, inst_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, inst_kind), v1, v2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Instance::new(inter_bookmark *IBM, inter_t SID, inter_t KID, inter_t V1, inter_t V2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_6(IBM, INSTANCE_IST, SID, KID, V1, V2, Inter::create_frame_list(IBM->read_into), Inter::create_frame_list(IBM->read_into), eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Frame::insert(P, IBM);
	return NULL;
}

void Inter::Instance::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_INST_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	*E = Inter__Verify__defn(owner, P, DEFN_INST_IFLD); if (*E) return;
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P.data[DEFN_INST_IFLD]);
	*E = Inter::Verify::symbol(owner, P, P.data[KIND_INST_IFLD], KIND_IST); if (*E) return;
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P.data[KIND_INST_IFLD]);
	inter_data_type *idt = Inter::Kind::data_type(inst_kind);
	if (Inter::Types::is_enumerated(idt)) {
		if (P.data[VAL1_INST_IFLD] == UNDEF_IVAL) {
			P.data[VAL1_INST_IFLD] = LITERAL_IVAL;
			P.data[VAL2_INST_IFLD] = Inter::Kind::next_enumerated_value(inst_kind);
		}
	} else { *E = Inter::Frame::error(&P, I"not a kind which has instances", NULL); return; }
	*E = Inter::Verify::value(owner, P, VAL1_INST_IFLD, inst_kind); if (*E) return;

	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;
	if (vcount == 0) {
		Inter::Kind::new_instance(inst_kind, inst_name);
	}
}

inter_t Inter::Instance::permissions_list(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PERM_LIST_INST_IFLD];
}

void Inter::Instance::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *inst_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_INST_IFLD);
	inter_symbol *inst_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_INST_IFLD);
	if ((inst_name) && (inst_kind)) {
		inter_data_type *idt = Inter::Kind::data_type(inst_kind);
		if (idt) {
			WRITE("instance %S %S = ", inst_name->symbol_name, inst_kind->symbol_name);
			Inter::Types::write(OUT, &P, NULL,
				P.data[VAL1_INST_IFLD], P.data[VAL2_INST_IFLD], Inter::Packages::scope_of(P), FALSE);
		} else { *E = Inter::Frame::error(&P, I"instance with bad data type", NULL); return; }
	} else { *E = Inter::Frame::error(&P, I"bad instance", NULL); return; }
	Inter::Symbols::write_annotations(OUT, &P, inst_name);
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
