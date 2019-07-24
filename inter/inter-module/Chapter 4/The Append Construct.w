[Inter::Append::] The Append Construct.

Defining the append construct.

@

@e APPEND_IST

=
void Inter::Append::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		APPEND_IST,
		L"append (%i+) \"(%c+)\"",
		I"append", I"appends");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Append::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Append::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Append::write);
}

@

@d SYMBOL_APPEND_IFLD 2
@d TEXT_APPEND_IFLD 3

@d EXTENT_APPEND_IFR 4

=
void Inter::Append::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, APPEND_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (ilp->no_annotations > 0) {
		*E = Inter::Errors::plain(I"__annotations are not allowed", eloc);
		return;
	}

	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IBM), ilp->mr.exp[0]);
	if (symbol == NULL) {
		*E = Inter::Errors::plain(I"no such symbol", eloc);
		return;
	}

	inter_t ID = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::package(IBM));
	*E = Inter::Constant::parse_text(Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(IBM), ID), ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (*E) return;

	*E = Inter::Append::new(IBM, symbol, ID, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Append::new(inter_bookmark *IBM, inter_symbol *symbol, inter_t append_text, inter_t level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inter::Frame::fill_2(IBM, APPEND_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, symbol), append_text, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::insert(P, IBM);
	return NULL;
}

void Inter::Append::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_t vcount = Inter::Frame::vcount(P);

	if (P->W.extent != EXTENT_APPEND_IFR) { *E = Inter::Frame::error(P, I"extent wrong", NULL); return; }
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P->W.data[SYMBOL_APPEND_IFLD]);;
	if (symbol == NULL) { *E = Inter::Frame::error(P, I"no target name", NULL); return; }
	if (P->W.data[TEXT_APPEND_IFLD] == 0) { *E = Inter::Frame::error(P, I"no translation text", NULL); return; }

	if (vcount == 0) {
		inter_t ID = P->W.data[TEXT_APPEND_IFLD];
		text_stream *S = Inter::Frame::ID_to_text(P, ID);
		Inter::Symbols::set_append(symbol, S);
	}
}

void Inter::Append::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_APPEND_IFLD);
	inter_t ID = P->W.data[TEXT_APPEND_IFLD];
	text_stream *S = Inter::Frame::ID_to_text(P, ID);
	WRITE("append %S \"", symbol->symbol_name);
	Inter::Constant::write_text(OUT, S);
	WRITE("\"");
}
