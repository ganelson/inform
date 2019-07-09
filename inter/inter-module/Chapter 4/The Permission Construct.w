[Inter::Permission::] The Permission Construct.

Defining the permission construct.

@

@e PERMISSION_IST

=
void Inter::Permission::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PERMISSION_IST,
		L"permission (%i+) (%i+) *(%i*)",
		I"permission", I"permissions");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Permission::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Permission::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Permission::write);
}

@

@d DEFN_PERM_IFLD 2
@d PROP_PERM_IFLD 3
@d OWNER_PERM_IFLD 4
@d STORAGE_PERM_IFLD 5

@d EXTENT_PERM_IFR 6

=
int pp_counter = 1;
void Inter::Permission::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, PERMISSION_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *prop_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], PROPERTY_IST, E);
	if (*E) return;
	inter_symbol *owner_name = Inter::Textual::find_KOI(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], E);
	if (*E) return;

	if (Inter::Kind::is(owner_name)) {
		if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
			{ *E = Inter::Errors::quoted(I"not a kind which can have property values", ilp->mr.exp[1], eloc); return; }

		inter_frame_list *FL =
			Inter::find_frame_list(
				IRS->read_into,
				Inter::Kind::permissions_list(owner_name));
		if (FL == NULL) internal_error("no permissions list");

		inter_frame X;
		LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
			inter_symbol *prop_allowed = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				{ *E = Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc); return; }
		}
	} else {
		inter_frame_list *FL =
			Inter::find_frame_list(
				IRS->read_into,
				Inter::Instance::permissions_list(owner_name));
		if (FL == NULL) internal_error("no permissions list");

		inter_frame X;
		LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
			inter_symbol *prop_allowed = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				{ *E = Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc); return; }
		}
	}

	TEMPORARY_TEXT(ident);
	WRITE_TO(ident, "pp_auto_%d", pp_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ident, E);
	DISCARD_TEXT(ident);
	if (*E) return;

	inter_symbol *store = NULL;
	if (Str::len(ilp->mr.exp[2]) > 0) {
		store = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[2], CONSTANT_IST, E);
		if (*E) return;
	}

	*E = Inter::Permission::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, owner_name),
		Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, pp_name), (store)?(Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, store)):0, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Permission::new(inter_reading_state *IRS, inter_t PID, inter_t KID,
	inter_t PPID, inter_t SID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, PERMISSION_IST, PPID, PID, KID, SID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Permission::verify(inter_construct *IC, inter_frame P, inter_error_message **E) {
	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;

	if (P.extent != EXTENT_PERM_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }

	*E = Inter::Verify::defn(P, DEFN_PERM_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(P, P.data[PROP_PERM_IFLD], PROPERTY_IST); if (*E) return;
	*E = Inter::Verify::symbol_KOI(P, P.data[OWNER_PERM_IFLD]); if (*E) return;
	if (P.data[STORAGE_PERM_IFLD]) {
		*E = Inter::Verify::symbol(P, P.data[STORAGE_PERM_IFLD], CONSTANT_IST); if (*E) return;
	}
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);

	if (vcount == 0) {
		inter_frame_list *FL = NULL;

		if (Inter::Kind::is(owner_name)) {
			if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
				{ *E = Inter::Frame::error(&P, I"property permission for non-enumerated kind", NULL); return; }
			FL = Inter::find_frame_list(
					P.repo_segment->owning_repo,
					Inter::Kind::permissions_list(owner_name));
			if (FL == NULL) internal_error("no permissions list");
			inter_frame X;
			LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
				inter_symbol *prop_X = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
				inter_symbol *prop_P = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
				if (prop_X == prop_P) { *E = Inter::Frame::error(&P, I"duplicate permission", prop_name->symbol_name); return; }
				inter_symbol *owner_X = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
				if (owner_X != owner_P) { *E = Inter::Frame::error(&P, I"kind permission list malformed A", owner_name->symbol_name); return; }
			}
		} else {
			FL = Inter::find_frame_list(
					P.repo_segment->owning_repo,
					Inter::Instance::permissions_list(owner_name));
			if (FL == NULL) internal_error("no permissions list");
			inter_frame X;
			LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
				inter_symbol *prop_X = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
				inter_symbol *prop_P = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
				if (prop_X == prop_P) { *E = Inter::Frame::error(&P, I"duplicate permission", prop_name->symbol_name); return; }
				inter_symbol *owner_X = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
				if (owner_X != owner_P) { *E = Inter::Frame::error(&P, I"kind permission list malformed A", owner_name->symbol_name); return; }
			}
		}

		Inter::add_to_frame_list(FL, P, NULL);

		FL = Inter::find_frame_list(
				P.repo_segment->owning_repo,
				Inter::Property::permissions_list(prop_name));
		Inter::add_to_frame_list(FL, P, NULL);
	}
}

void Inter::Permission::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
	if ((prop_name) && (owner_name)) {
		WRITE("permission %S %S", prop_name->symbol_name, owner_name->symbol_name);
		if (P.data[STORAGE_PERM_IFLD]) {
			inter_symbol *store = Inter::SymbolsTables::symbol_from_frame_data(P, STORAGE_PERM_IFLD);
			WRITE(" %S", store->symbol_name);
		}
	} else { *E = Inter::Frame::error(&P, I"cannot write permission", NULL); return; }
}
