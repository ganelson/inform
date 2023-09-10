[PlugInstruction::] The Plug Construct.

Defining the symbol construct.

@ This is a pseudo-construct: it looks like an instruction in textual Inter
syntax, but specifies something else, and does not result in an |inter_tree_node|.

=
void PlugInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PLUG_IST, I"plug");
	InterInstruction::specify_syntax(IC, I"plug IDENTIFIER TOKENS");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PlugInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PlugInstruction::verify);
	InterInstruction::allow_in_depth_range(IC, 0, 1);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
}

void PlugInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = Inode::error(P, I"PLUG_IST structures cannot exist", NULL);
}

@ What it does is to specify a symbol which is a plug in the current tree:
this results in an entry in the symbols table for the current package (which
will always be |/main/connectors|, in fact) but not an instruction.

Surprisingly, this can actually result in a socket rather than a plug, but
only in the case where the plug asks to wire to something existing in the current
tree already.

=
void PlugInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *symbol_text = ilp->mr.exp[0];
	text_stream *equate_text = ilp->mr.exp[1];

	inter_tree *I = InterBookmark::tree(IBM);
	inter_symbols_table *T = InterBookmark::scope(IBM);
	inter_symbol *plug_s = TextualInter::new_symbol(eloc, T, symbol_text, E);
	if (*E) return;
	InterSymbol::make_plug(plug_s);

	text_stream *equate_name = NULL;
	int to_name = FALSE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, equate_text, U"~~> \"(%C+)\"")) {
		equate_name = mr.exp[0];
		to_name = TRUE;
	} else if (Regexp::match(&mr, equate_text, U"~~> (%C+)")) {
		equate_name = mr.exp[0];
	} else {
		Regexp::dispose_of(&mr);
		*E = InterErrors::plain(I"bad plug syntax", eloc); return;
	}

	if (to_name) {
		Wiring::make_plug_wanting_identifier(plug_s, equate_name);
	} else {
		inter_symbol *eq_s = InterSymbolsTable::URL_to_symbol(I, equate_name);
		if (eq_s == NULL) Wiring::wire_to_name(plug_s, equate_name);
		else Wiring::make_socket_to(plug_s, eq_s);
	}
	Regexp::dispose_of(&mr);
}

@ The following writes a valid line of textual Inter to declare a plug or socket,
appearing at level |N| in the hierarchy.

=
void PlugInstruction::write_declaration(OUTPUT_STREAM, inter_symbol *S, int N) {
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
