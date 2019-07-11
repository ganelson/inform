[Inter::Cast::] The Cast Construct.

Defining the cast construct.

@

@e CAST_IST

=
void Inter::Cast::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		CAST_IST,
		L"cast (%i+) <- (%i+)",
		I"cast", I"casts");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE + CAN_HAVE_CHILDREN;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Cast::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Cast::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Cast::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Cast::verify_children);
}

@

@d BLOCK_CAST_IFLD 2
@d TO_KIND_CAST_IFLD 3
@d FROM_KIND_CAST_IFLD 4

@d EXTENT_CAST_IFR 5

=
void Inter::Cast::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IRS, CAST_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'val' used outside function", eloc); return; }

	inter_symbol *from_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;
	inter_symbol *to_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	*E = Inter::Cast::new(IRS, routine, from_kind, to_kind, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Cast::new(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *from_kind, inter_symbol *to_kind, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, CAST_IST, 0, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, to_kind), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, from_kind), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Cast::verify(inter_construct *IC, inter_frame P, inter_error_message **E) {
	if (P.extent != EXTENT_CAST_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::symbol(P, P.data[TO_KIND_CAST_IFLD], KIND_IST); if (*E) return;
	*E = Inter::Verify::symbol(P, P.data[FROM_KIND_CAST_IFLD], KIND_IST); if (*E) return;
}

void Inter::Cast::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) { *E = Inter::Frame::error(&P, I"function has no symbols table", NULL); return; }
	inter_symbol *from_kind = Inter::SymbolsTables::symbol_from_frame_data(P, FROM_KIND_CAST_IFLD);
	inter_symbol *to_kind = Inter::SymbolsTables::symbol_from_frame_data(P, TO_KIND_CAST_IFLD);
	if ((from_kind) && (to_kind)) {
		WRITE("cast %S <- %S", to_kind->symbol_name, from_kind->symbol_name);
	} else { *E = Inter::Frame::error(&P, I"cannot write cast", NULL); return; }
}

void Inter::Cast::verify_children(inter_construct *IC, inter_frame P, inter_error_message **E) {
	int arity_as_invoked = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		arity_as_invoked++;
		if ((C.data[0] != INV_IST) && (C.data[0] != VAL_IST) && (C.data[0] != EVALUATION_IST) && (C.data[0] != CAST_IST)) {
			*E = Inter::Frame::error(&P, I"only inv, cast, concatenate and val can be under a cast", NULL);
			return;
		}
	}
	if (arity_as_invoked != 1) {
		*E = Inter::Frame::error(&P, I"a cast should have exactly one child", NULL);
		return;
	}
}
