[Inter::Append::] The Append Construct.

Defining the append construct.

@

@e APPEND_IST

=
void Inter::Append::define(void) {
	inter_construct *IC = InterConstruct::create_construct(
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
	*E = InterConstruct::vet_level(IBM, APPEND_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) {
		*E = Inter::Errors::plain(I"__annotations are not allowed", eloc);
		return;
	}

	inter_symbol *symbol = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), ilp->mr.exp[0]);
	if (symbol == NULL) {
		*E = Inter::Errors::plain(I"no such symbol", eloc);
		return;
	}

	inter_ti ID = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
	*E = Inter::Constant::parse_text(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ID), ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (*E) return;

	*E = Inter::Append::new(IBM, symbol, ID, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Append::new(inter_bookmark *IBM, inter_symbol *symbol, inter_ti append_text, inter_ti level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, APPEND_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, symbol), append_text, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Append::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_ti vcount = Inode::bump_verification_count(P);

	if (P->W.extent != EXTENT_APPEND_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	inter_symbol *symbol = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[SYMBOL_APPEND_IFLD]);;
	if (symbol == NULL) { *E = Inode::error(P, I"no target name", NULL); return; }
	if (P->W.instruction[TEXT_APPEND_IFLD] == 0) { *E = Inode::error(P, I"no translation text", NULL); return; }

	if (vcount == 0) {
		inter_ti ID = P->W.instruction[TEXT_APPEND_IFLD];
		text_stream *S = Inode::ID_to_text(P, ID);
		SymbolAnnotation::set_t(P->tree, P->package, symbol, APPEND_IANN, S);
	}
}

void Inter::Append::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *symbol = InterSymbolsTable::symbol_from_ID_at_node(P, SYMBOL_APPEND_IFLD);
	inter_ti ID = P->W.instruction[TEXT_APPEND_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	WRITE("append %S \"", symbol->symbol_name);
	Inter::Constant::write_text(OUT, S);
	WRITE("\"");
}
