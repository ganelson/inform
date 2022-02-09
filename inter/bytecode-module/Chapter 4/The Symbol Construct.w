[Inter::Symbol::] The Symbol Construct.

Defining the symbol construct.

@

@e SYMBOL_IST

=
void Inter::Symbol::define(void) {
	inter_construct *IC = InterConstruct::create_construct(SYMBOL_IST, I"symbol");
	InterConstruct::specify_syntax(IC, I"symbol TOKEN IDENTIFIER TOKENS");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Symbol::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Symbol::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Symbol::write);
	InterConstruct::allow_in_depth_range(IC, 0, 1);
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterConstruct::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

void Inter::Symbol::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, SYMBOL_IST, ilp->indent_level, eloc);
	if (*E) return;
	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_package *routine = TextualInter::get_latest_block_package();

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
		inter_symbols_table *locals = InterPackage::scope(routine);
		if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }
		name_name = TextualInter::new_symbol(eloc, locals, symbol_name, E);
		if (*E) return;
		level = (inter_ti) ilp->indent_level;
	} else {
		name_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), symbol_name, E);
		if (*E) return;
	}

	if (Str::eq(ilp->mr.exp[0], I"private")) ;
	else if (Str::eq(ilp->mr.exp[0], I"public")) ;
	else { *E = Inter::Errors::plain(I"unknown scope keyword", eloc); return; }

	if (Str::eq(ilp->mr.exp[1], I"label"))  {
	     if (Str::get_first_char(symbol_name) != '.') {
	    	 *E = Inter::Errors::plain(I"label names must begin with a '.'", eloc); return;
	     }
	     InterSymbol::make_label(name_name);
	}
	else if (Str::eq(ilp->mr.exp[1], I"misc"))   InterSymbol::make_miscellaneous(name_name);
	else if (Str::eq(ilp->mr.exp[1], I"plug"))   InterSymbol::make_plug(name_name);
	else if (Str::eq(ilp->mr.exp[1], I"socket")) InterSymbol::make_socket(name_name);
	else if (Str::eq(ilp->mr.exp[1], I"local"))  InterSymbol::make_local(name_name);
	else { *E = Inter::Errors::plain(I"unknown symbol-type keyword", eloc); return; }

	if ((trans_name) && (equate_name)) {
		*E = Inter::Errors::plain(I"a symbol cannot be both translated and equated", eloc); return;
	}

	if (InterPackage::is_a_linkage_package(InterBookmark::package(IBM))) {
		if (InterSymbol::is_connector(name_name) == FALSE) {
			*E = Inter::Errors::plain(I"in a _linkage package, all symbols must be plugs or sockets", eloc); return;
		}
		if (equate_name) {
			if (InterSymbol::is_plug(name_name))
				Wiring::make_plug_wanting_identifier(name_name, equate_name);
			else {
				inter_symbol *eq = InterSymbolsTable::URL_to_symbol(InterBookmark::tree(IBM), equate_name);
				if (eq == NULL) eq = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), equate_name);
				if (eq == NULL) {
					Wiring::wire_to_name(name_name, equate_name);
				} else {
					Wiring::make_socket_to(name_name, eq);
				}
			}
		} else {
			*E = Inter::Errors::plain(I"link symbol not equated", eloc); return;
		}
	} else {
		if (InterSymbol::is_connector(name_name)) {
			*E = Inter::Errors::plain(I"plugs and sockets may only occur in a _linkage package", eloc); return;
		}
		if (trans_name) InterSymbol::set_translate(name_name, trans_name);
		if (equate_name) {
			inter_symbol *eq = InterSymbolsTable::URL_to_symbol(InterBookmark::tree(IBM), equate_name);
			if (eq == NULL) eq = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), equate_name);
			if (eq == NULL) {
				Wiring::wire_to_name(name_name, equate_name);
			} else {
				Wiring::wire_to(name_name, eq);
			}
		}
	}

	if (starred) {
		InterSymbol::set_flag(name_name, MAKE_NAME_UNIQUE_ISYMF);
	}
}

void Inter::Symbol::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}

void Inter::Symbol::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}
