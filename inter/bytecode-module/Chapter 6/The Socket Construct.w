[SocketInstruction::] The Socket Construct.

Defining the socket construct.

@ This is a pseudo-construct: it looks like an instruction in textual Inter
syntax, but specifies something else, and does not result in an |inter_tree_node|.

=
void SocketInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(SOCKET_IST, I"socket");
	InterInstruction::specify_syntax(IC, I"socket IDENTIFIER TOKENS");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, SocketInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, SocketInstruction::verify);
	InterInstruction::allow_in_depth_range(IC, 0, 1);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
}

void SocketInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = Inode::error(P, I"SOCKET_IST structures cannot exist", NULL);
}

@ What it does is to specify a symbol which is a socket in the current tree:
this results in an entry in the symbols table for the current package (which
will always be |/main/connectors|, in fact) but not an instruction.

For how these are printed back, see //PlugInstruction::write_declaration//,
which handles both plugs and sockets.

=
void SocketInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *symbol_text = ilp->mr.exp[0];
	text_stream *equate_text = ilp->mr.exp[1];

	inter_tree *I = InterBookmark::tree(IBM);
	inter_symbols_table *T = InterBookmark::scope(IBM);
	inter_symbol *socket_s = TextualInter::new_symbol(eloc, T, symbol_text, E);
	if (*E) return;

	text_stream *equate_name = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, equate_text, U"~~> \"(%C+)\"")) {
		*E = InterErrors::plain(I"a socket cannot wire to a name", eloc);
		return;
	} else if (Regexp::match(&mr, equate_text, U"~~> (%C+)")) {
		equate_name = mr.exp[0];
	} else {
		Regexp::dispose_of(&mr);
		*E = InterErrors::plain(I"bad socket syntax", eloc); return;
	}

	inter_symbol *eq = InterSymbolsTable::URL_to_symbol(I, equate_name);
	if (eq == NULL) {
		InterSymbol::make_socket(socket_s);
		Wiring::wire_to_name(socket_s, equate_name);
	} else {
		Wiring::make_socket_to(socket_s, eq);
	}
	Regexp::dispose_of(&mr);
}
