[Inter::Response::] The Response Construct.

Defining the response construct.

@

@e RESPONSE_IST

=
void Inter::Response::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		RESPONSE_IST,
		L"response (%i+) (%i+) (%d+) = (%c+)",
		I"response", I"responses");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Response::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Response::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Response::write);
}

@

@d DEFN_RESPONSE_IFLD 2
@d RULE_RESPONSE_IFLD 3
@d MARKER_RESPONSE_IFLD 4
@d VAL1_RESPONSE_IFLD 5
@d VAL2_RESPONSE_IFLD 6

@d EXTENT_RESPONSE_IFR 7

=
void Inter::Response::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, RESPONSE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *resp_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	inter_symbol *rule_name = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[1], CONSTANT_IST, E);
	if (*E) return;

	inter_t n1 = UNDEF_IVAL, n2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), NULL, ilp->mr.exp[2], &n1, &n2, Inter::Bookmarks::scope(IBM));
	if (*E) return;
	if ((n1 != LITERAL_IVAL) || (n2 >= 26))
		{ *E = Inter::Errors::plain(I"response marker out of range", eloc); return; }

	inter_symbol *val_name = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[3], CONSTANT_IST, E);
	if (*E) return;

	inter_t v1 = 0, v2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), val_name, &v1, &v2);
	*E = Inter::Response::new(IBM, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, resp_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, rule_name), n2, v1, v2, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Response::new(inter_bookmark *IBM, inter_t SID, inter_t RID, inter_t marker, inter_t v1, inter_t v2, inter_t level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_5(IBM, RESPONSE_IST, SID, RID, marker, v1, v2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

void Inter::Response::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_RESPONSE_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_RESPONSE_IFLD); if (*E) return;
	if (P->W.data[MARKER_RESPONSE_IFLD] >= 26) { *E = Inter::Errors::plain(I"response marker out of range", NULL); return; }
}

void Inter::Response::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *resp_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_RESPONSE_IFLD);
	inter_symbol *rule_name = Inter::SymbolsTables::symbol_from_frame_data(P, RULE_RESPONSE_IFLD);
	if ((resp_name) && (rule_name)) {
		WRITE("response %S %S %d = ", resp_name->symbol_name, rule_name->symbol_name, P->W.data[MARKER_RESPONSE_IFLD]);
		Inter::Types::write(OUT, P, NULL,
			P->W.data[VAL1_RESPONSE_IFLD], P->W.data[VAL1_RESPONSE_IFLD+1], Inter::Packages::scope_of(P), FALSE);
	} else {
		*E = Inode::error(P, I"response can't be written", NULL);
	}
}
