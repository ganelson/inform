[Inter::Symbol::] The Symbol Construct.

Defining the symbol construct.

@

@e SYMBOL_IST

=
void Inter::Symbol::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		SYMBOL_IST,
		L"symbol (%C+) (%i+) (%c+)",
		I"symbol", I"symbols");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Symbol::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Symbol::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Symbol::write);
	IC->min_level = 0;
	IC->max_level = 1;
}

void Inter::Symbol::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, SYMBOL_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (Inter::Annotations::exist(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_package *routine = Inter::Defn::get_latest_block_package();

	text_stream *symbol_name = ilp->mr.exp[2];
	text_stream *trans_name = NULL;
	text_stream *equate_name = NULL;
	int starred = FALSE;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, symbol_name, L"(%C+) `(%C+)`")) {
		symbol_name = mr2.exp[0];
		trans_name = mr2.exp[1];
	} else if (Regexp::match(&mr2, symbol_name, L"(%C+) --%? (%C+)")) {
		symbol_name = mr2.exp[0];
		equate_name = mr2.exp[1];
	} else if (Regexp::match(&mr2, symbol_name, L"(%C+) --> (%C+)")) {
		symbol_name = mr2.exp[0];
		equate_name = mr2.exp[1];
	}
	if (Str::get_last_char(symbol_name) == '*') {
		starred = TRUE;
		Str::delete_last_character(symbol_name);
	}

	inter_symbol *name_name = NULL;
	inter_ti level = 0;
	if (routine) {
		inter_symbols_table *locals = Inter::Packages::scope(routine);
		if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }
		name_name = Inter::Textual::new_symbol(eloc, locals, symbol_name, E);
		if (*E) return;
		level = (inter_ti) ilp->indent_level;
	} else {
		name_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), symbol_name, E);
		if (*E) return;
	}

	if (Str::eq(ilp->mr.exp[0], I"private")) Inter::Symbols::set_scope(name_name, PRIVATE_ISYMS);
	else if (Str::eq(ilp->mr.exp[0], I"public")) Inter::Symbols::set_scope(name_name, PUBLIC_ISYMS);
	else if (Str::eq(ilp->mr.exp[0], I"external")) Inter::Symbols::set_scope(name_name, EXTERNAL_ISYMS);
	else if (Str::eq(ilp->mr.exp[0], I"plug")) Inter::Symbols::set_scope(name_name, PLUG_ISYMS);
	else if (Str::eq(ilp->mr.exp[0], I"socket")) Inter::Symbols::set_scope(name_name, SOCKET_ISYMS);
	else { *E = Inter::Errors::plain(I"unknown scope keyword", eloc); return; }

	if (Str::eq(ilp->mr.exp[1], I"label")) Inter::Symbols::set_type(name_name, LABEL_ISYMT);
	else if (Str::eq(ilp->mr.exp[1], I"misc")) Inter::Symbols::set_type(name_name, MISC_ISYMT);
	else if (Str::eq(ilp->mr.exp[1], I"package")) Inter::Symbols::set_type(name_name, PACKAGE_ISYMT);
	else if (Str::eq(ilp->mr.exp[1], I"packagetype")) Inter::Symbols::set_type(name_name, PTYPE_ISYMT);
	else { *E = Inter::Errors::plain(I"unknown symbol-type keyword", eloc); return; }

	if ((trans_name) && (equate_name)) {
		*E = Inter::Errors::plain(I"a symbol cannot be both translated and equated", eloc); return;
	}

	if (Inter::Packages::is_linklike(Inter::Bookmarks::package(IBM))) {
		if (Inter::Symbols::is_connector(name_name) == FALSE) {
			*E = Inter::Errors::plain(I"in a _linkage package, all symbols must be plugs or sockets", eloc); return;
		}
		if (equate_name) {
			if (Inter::Symbols::get_scope(name_name) == PLUG_ISYMS)
				Wiring::convert_to_plug(name_name, equate_name);
			else {
				inter_symbol *eq = InterSymbolsTables::url_name_to_symbol(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::scope(IBM), equate_name);
				if (eq == NULL) {
					Wiring::wire_to_name(name_name, equate_name);
					Inter::Symbols::set_scope(name_name, EXTERNAL_ISYMS);
				} else {
					Wiring::convert_to_socket(name_name, eq);
				}
			}
		} else {
			*E = Inter::Errors::plain(I"link symbol not equated", eloc); return;
		}
	} else {
		if (Inter::Symbols::is_connector(name_name)) {
			*E = Inter::Errors::plain(I"plugs and sockets may only occur in a _linkage package", eloc); return;
		}
		if (trans_name) Inter::Symbols::set_translate(name_name, trans_name);
		if (equate_name) {
			inter_symbol *eq = InterSymbolsTables::url_name_to_symbol(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::scope(IBM), equate_name);
			if (eq == NULL) {
				Wiring::wire_to_name(name_name, equate_name);
				Inter::Symbols::set_scope(name_name, EXTERNAL_ISYMS);
			} else {
				Wiring::wire_to(name_name, eq);
			}
		}
	}

	if (starred) {
		Inter::Symbols::set_flag(name_name, MAKE_NAME_UNIQUE);
	}
}

void Inter::Symbol::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}

void Inter::Symbol::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}
