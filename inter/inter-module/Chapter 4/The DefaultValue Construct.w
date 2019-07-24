[Inter::DefaultValue::] The DefaultValue Construct.

Defining the defaultvalue construct.

@

@e DEFAULTVALUE_IST

=
void Inter::DefaultValue::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		DEFAULTVALUE_IST,
		L"defaultvalue (%i+) = (%c+)",
		I"defaultvalue", I"defaultvalues");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::DefaultValue::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::DefaultValue::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::DefaultValue::write);
}

@

@d KIND_DEF_IFLD 2
@d VAL1_DEF_IFLD 3
@d VAL2_DEF_IFLD 4

@d EXTENT_DEF_IFR 5

=
void Inter::DefaultValue::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, DEFAULTVALUE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *con_kind = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	inter_t con_val1 = 0;
	inter_t con_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), con_kind, ilp->mr.exp[1], &con_val1, &con_val2, Inter::Bookmarks::scope(IBM));
	if (*E) return;

	*E = Inter::DefaultValue::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), con_val1, con_val2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::DefaultValue::new(inter_bookmark *IBM, inter_t KID, inter_t val1, inter_t val2, inter_t level, inter_error_location *eloc) {
	inter_tree_node *P = Inter::Frame::fill_3(IBM, DEFAULTVALUE_IST, KID, val1, val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::insert(P, IBM);
	return NULL;
}

void Inter::DefaultValue::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_DEF_IFR) *E = Inter::Frame::error(P, I"extent wrong", NULL);
	else *E = Inter::Verify::symbol(owner, P, P->W.data[KIND_DEF_IFLD], KIND_IST);
}

void Inter::DefaultValue::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_DEF_IFLD);
	if (con_kind) {
		WRITE("defaultvalue %S = ", con_kind->symbol_name);
		Inter::Types::write(OUT, P, con_kind,
			P->W.data[VAL1_DEF_IFLD], P->W.data[VAL1_DEF_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		*E = Inter::Frame::error(P, I"defaultvalue can't be written", NULL);
	}
}
