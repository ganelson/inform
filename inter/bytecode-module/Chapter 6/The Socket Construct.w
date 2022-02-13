[Inter::Socket::] The Socket Construct.

Defining the socket construct.

@

@e SOCKET_IST

=
void Inter::Socket::define(void) {
	inter_construct *IC = InterConstruct::create_construct(SOCKET_IST, I"socket");
	InterConstruct::specify_syntax(IC, I"socket IDENTIFIER TOKENS");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Socket::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Socket::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Socket::write);
	InterConstruct::allow_in_depth_range(IC, 0, 1);
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
}

void Inter::Socket::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, SOCKET_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_package *routine = InterBookmark::package(IBM);

	text_stream *symbol_name = ilp->mr.exp[0];
	text_stream *equate_name = NULL;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, ilp->mr.exp[1], L"~~> \"(%C+)\"")) {
		*E = Inter::Errors::plain(I"a socket cannot wire to a name", eloc); return;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"~~> (%C+)")) {
		equate_name = mr2.exp[0];
	} else {
		*E = Inter::Errors::plain(I"bad socket syntax", eloc); return;
	}

	inter_symbol *name_name = NULL;
	inter_ti level = 0;
	if (routine) {
		inter_symbols_table *locals = InterPackage::scope(routine);
		if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }
		name_name = TextualInter::new_symbol(eloc, locals, symbol_name, E);
		if (*E) return;
		inter_symbol *eq = InterSymbolsTable::URL_to_symbol(InterBookmark::tree(IBM), equate_name);
		if (eq == NULL) eq = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), equate_name);
		if (eq == NULL) {
			InterSymbol::make_socket(name_name);
			Wiring::wire_to_name(name_name, equate_name);
		} else {
			Wiring::make_socket_to(name_name, eq);
		}
		level = (inter_ti) ilp->indent_level;
	} else {
		*E = Inter::Errors::plain(I"sockets can exist only in the connectors package", eloc); return;
	}
}

void Inter::Socket::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	internal_error("SOCKET_IST structures cannot exist");
}

void Inter::Socket::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	internal_error("SOCKET_IST structures cannot exist");
}

@ The following writes a valid line of textual Inter to declare a plug or socket,
appearing at level |N| in the hierarchy.

=
void Inter::Socket::write_declaration(OUTPUT_STREAM, inter_symbol *S, int N) {
	for (int L=0; L<N; L++) WRITE("\t");
	switch (InterSymbol::get_type(S)) {
		case PLUG_ISYMT:   WRITE("plug"); break;
		case SOCKET_ISYMT: WRITE("socket"); break;
		default: internal_error("not a connector"); break;
	}
	WRITE(" %S", InterSymbol::identifier(S));
	if (Wiring::is_wired_to_name(S)) {
		WRITE(" ~~> \"%S\"", Wiring::wired_to_name(S));
	} else if (Wiring::is_wired(S)) {
		WRITE(" ~~> ");
		InterSymbolsTable::write_symbol_URL(OUT, Wiring::wired_to(S));
	} else {
		WRITE(" ?");
	}
}
