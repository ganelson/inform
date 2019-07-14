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
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();

	text_stream *symbol_name = ilp->mr.exp[2];
	text_stream *trans_name = NULL;
	text_stream *equate_name = NULL;
	int starred = FALSE;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, symbol_name, L"(%C+) -> (%C+)")) {
		symbol_name = mr2.exp[0];
		trans_name = mr2.exp[1];
	} else if (Regexp::match(&mr2, symbol_name, L"(%C+) == (%C+)")) {
		symbol_name = mr2.exp[0];
		equate_name = mr2.exp[1];
	}
	if (Str::get_last_char(symbol_name) == '*') {
		starred = TRUE;
		Str::delete_last_character(symbol_name);
	}

	inter_symbol *name_name = NULL;
	inter_t level = 0;
	if (routine) {
		inter_symbols_table *locals = Inter::Package::local_symbols(routine);
		if (locals == NULL) { *E = Inter::Errors::plain(I"function has no symbols table", eloc); return; }
		name_name = Inter::Textual::new_symbol(eloc, locals, symbol_name, E);
		if (*E) return;
		level = (inter_t) ilp->indent_level;
	} else {
		name_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), symbol_name, E);
		if (*E) return;
	}

	if (Str::eq(ilp->mr.exp[0], I"private")) name_name->symbol_scope = PRIVATE_ISYMS;
	else if (Str::eq(ilp->mr.exp[0], I"public")) name_name->symbol_scope = PUBLIC_ISYMS;
	else if (Str::eq(ilp->mr.exp[0], I"external")) name_name->symbol_scope = EXTERNAL_ISYMS;
	else { *E = Inter::Errors::plain(I"unknown scope keyword", eloc); return; }

	if (Str::eq(ilp->mr.exp[1], I"label")) name_name->symbol_type = LABEL_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"misc")) name_name->symbol_type = MISC_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"package")) name_name->symbol_type = PACKAGE_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"packagetype")) name_name->symbol_type = PTYPE_ISYMT;
	else { *E = Inter::Errors::plain(I"unknown symbol-type keyword", eloc); return; }

	if (trans_name) Inter::Symbols::set_translate(name_name, trans_name);
	if (equate_name) {
		inter_symbol *eq = Inter::SymbolsTables::url_name_to_symbol(IBM->read_into, Inter::Bookmarks::scope(IBM), equate_name);
		if (eq == NULL) Inter::SymbolsTables::equate_textual(name_name, equate_name);
		else Inter::SymbolsTables::equate(name_name, eq);
	}

	if (starred) {
		Inter::Symbols::set_flag(name_name, MAKE_NAME_UNIQUE);
	}
}

void Inter::Symbol::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}

void Inter::Symbol::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	internal_error("SYMBOL_IST structures cannot exist");
}
