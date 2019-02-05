[Inter::Symbol::] The Symbol Construct.

Defining the symbol construct.

@

@e SYMBOL_IST

=
void Inter::Symbol::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		SYMBOL_IST,
		L"symbol (%i+) (%i+) (%c+)",
		&Inter::Symbol::read,
		NULL,
		&Inter::Symbol::verify,
		&Inter::Symbol::write,
		NULL,
		NULL,
		NULL,
		NULL,
		I"symbol", I"symbols");
	IC->min_level = 0;
	IC->max_level = 1;
}

inter_error_message *Inter::Symbol::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, SYMBOL_IST, ilp->indent_level, eloc);
	if (E) return E;
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

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
		if (locals == NULL) return Inter::Errors::plain(I"function has no symbols table", eloc);
		name_name = Inter::Textual::new_symbol(eloc, locals, symbol_name, &E);
		if (E) return E;
		level = (inter_t) ilp->indent_level;
	} else {
		name_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), symbol_name, &E);
		if (E) return E;
	}

	if (Str::eq(ilp->mr.exp[0], I"private")) name_name->symbol_scope = PRIVATE_ISYMS;
	else if (Str::eq(ilp->mr.exp[0], I"public")) name_name->symbol_scope = PUBLIC_ISYMS;
	else if (Str::eq(ilp->mr.exp[0], I"external")) name_name->symbol_scope = EXTERNAL_ISYMS;
	else return Inter::Errors::plain(I"unknown scope keyword", eloc);

	if (Str::eq(ilp->mr.exp[1], I"label")) name_name->symbol_type = LABEL_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"misc")) name_name->symbol_type = MISC_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"package")) name_name->symbol_type = PACKAGE_ISYMT;
	else if (Str::eq(ilp->mr.exp[1], I"packagetype")) name_name->symbol_type = PTYPE_ISYMT;
	else return Inter::Errors::plain(I"unknown symbol-type keyword", eloc);

	if (trans_name) Inter::Symbols::set_translate(name_name, trans_name);
	if (equate_name) {
		inter_symbol *eq = Inter::SymbolsTables::url_name_to_symbol(IRS->read_into, Inter::Bookmarks::scope(IRS), equate_name);
		if (eq == NULL) Inter::SymbolsTables::equate_textual(name_name, equate_name);
		else Inter::SymbolsTables::equate(name_name, eq);
	}

	if (starred) {
		Inter::Symbols::set_flag(name_name, MAKE_NAME_UNIQUE);
	}

	return NULL;
}

inter_error_message *Inter::Symbol::verify(inter_frame P) {
	internal_error("SYMBOL_IST structures cannot exist");
	return NULL;
}

inter_error_message *Inter::Symbol::write(OUTPUT_STREAM, inter_frame P) {
	internal_error("SYMBOL_IST structures cannot exist");
	return NULL;
}
