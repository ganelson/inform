[Inter::Permission::] The Permission Construct.

Defining the permission construct.

@

@e PERMISSION_IST

=
void Inter::Permission::define(void) {
	Inter::Defn::create_construct(
		PERMISSION_IST,
		L"permission (%i+) (%i+) *(%i*)",
		&Inter::Permission::read,
		NULL,
		&Inter::Permission::verify,
		&Inter::Permission::write,
		NULL,
		NULL,
		NULL,
		&Inter::Permission::show_dependencies,
		I"permission", I"permissions");
}

@

@d DEFN_PERM_IFLD 2
@d PROP_PERM_IFLD 3
@d OWNER_PERM_IFLD 4
@d STORAGE_PERM_IFLD 5

@d EXTENT_PERM_IFR 6

=
int pp_counter = 1;
inter_error_message *Inter::Permission::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, PERMISSION_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *prop_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], PROPERTY_IST, &E);
	if (E) return E;
	inter_symbol *owner_name = Inter::Textual::find_KOI(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], &E);
	if (E) return E;

	if (Inter::Kind::is(owner_name)) {
		if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
			return Inter::Errors::quoted(I"not a kind which can have property values", ilp->mr.exp[1], eloc);

		inter_frame_list *FL =
			Inter::find_frame_list(
				IRS->read_into,
				Inter::Kind::permissions_list(owner_name));
		if (FL == NULL) internal_error("no permissions list");

		inter_frame X;
		LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
			inter_symbol *prop_allowed = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				return Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc);
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
				return Inter::Errors::quoted(I"permission already given", ilp->mr.exp[0], eloc);
		}
	}

	TEMPORARY_TEXT(ident);
	WRITE_TO(ident, "pp_auto_%d", pp_counter++);
	inter_symbol *pp_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ident, &E);
	DISCARD_TEXT(ident);
	if (E) return E;

	inter_symbol *store = NULL;
	if (Str::len(ilp->mr.exp[2]) > 0) {
		store = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[2], CONSTANT_IST, &E);
		if (E) return E;
	}

	return Inter::Permission::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, prop_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, owner_name),
		Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, pp_name), (store)?(Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, store)):0, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Permission::new(inter_reading_state *IRS, inter_t PID, inter_t KID,
	inter_t PPID, inter_t SID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, PERMISSION_IST, PPID, PID, KID, SID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Permission::verify(inter_frame P) {
	inter_t vcount = P.repo_segment->bytecode[P.index + PREFRAME_VERIFICATION_COUNT]++;

	if (P.extent != EXTENT_PERM_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);

	inter_error_message *E = Inter::Verify::defn(P, DEFN_PERM_IFLD); if (E) return E;
	E = Inter::Verify::symbol(P, P.data[PROP_PERM_IFLD], PROPERTY_IST); if (E) return E;
	E = Inter::Verify::symbol_KOI(P, P.data[OWNER_PERM_IFLD]); if (E) return E;
	if (P.data[STORAGE_PERM_IFLD]) {
		E = Inter::Verify::symbol(P, P.data[STORAGE_PERM_IFLD], CONSTANT_IST); if (E) return E;
	}
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);

	if (vcount == 0) {
		inter_frame_list *FL = NULL;

		if (Inter::Kind::is(owner_name)) {
			if (Inter::Types::is_enumerated(Inter::Kind::data_type(owner_name)) == FALSE)
				return Inter::Frame::error(&P, I"property permission for non-enumerated kind", NULL);
			FL = Inter::find_frame_list(
					P.repo_segment->owning_repo,
					Inter::Kind::permissions_list(owner_name));
			if (FL == NULL) internal_error("no permissions list");
			inter_frame X;
			LOOP_THROUGH_INTER_FRAME_LIST(X, FL) {
				inter_symbol *prop_X = Inter::SymbolsTables::symbol_from_frame_data(X, PROP_PERM_IFLD);
				inter_symbol *prop_P = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
				if (prop_X == prop_P) return Inter::Frame::error(&P, I"duplicate permission", prop_name->symbol_name);
				inter_symbol *owner_X = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
				if (owner_X != owner_P) return Inter::Frame::error(&P, I"kind permission list malformed A", owner_name->symbol_name);
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
				if (prop_X == prop_P) return Inter::Frame::error(&P, I"duplicate permission", prop_name->symbol_name);
				inter_symbol *owner_X = Inter::SymbolsTables::symbol_from_frame_data(X, OWNER_PERM_IFLD);
				inter_symbol *owner_P = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
				if (owner_X != owner_P) return Inter::Frame::error(&P, I"kind permission list malformed A", owner_name->symbol_name);
			}
		}

		Inter::add_to_frame_list(FL, P, NULL);

		FL = Inter::find_frame_list(
				P.repo_segment->owning_repo,
				Inter::Property::permissions_list(prop_name));
		Inter::add_to_frame_list(FL, P, NULL);
	}
	return NULL;
}

inter_error_message *Inter::Permission::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
	if ((prop_name) && (owner_name)) {
		WRITE("permission %S %S", prop_name->symbol_name, owner_name->symbol_name);
		if (P.data[STORAGE_PERM_IFLD]) {
			inter_symbol *store = Inter::SymbolsTables::symbol_from_frame_data(P, STORAGE_PERM_IFLD);
			WRITE(" %S", store->symbol_name);
		}
	} else return Inter::Frame::error(&P, I"cannot write permission", NULL);
	return NULL;
}

void Inter::Permission::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *prop_name = Inter::SymbolsTables::symbol_from_frame_data(P, PROP_PERM_IFLD);
	inter_symbol *owner_name = Inter::SymbolsTables::symbol_from_frame_data(P, OWNER_PERM_IFLD);
	if ((prop_name) && (owner_name)) {
		(*callback)(prop_name, owner_name, state);
		if (P.data[STORAGE_PERM_IFLD]) {
			inter_symbol *store = Inter::SymbolsTables::symbol_from_frame_data(P, STORAGE_PERM_IFLD);
			if (store) (*callback)(prop_name, store, state);
		}
	}
}
