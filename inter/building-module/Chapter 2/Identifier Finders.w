[IdentifierFinders::] Identifier Finders.

@h Identifying identifiers.

@d MAX_IDENTIFIER_PRIORITIES 3

=
typedef struct identifier_finder {
	int no_priorities;
	struct inter_symbols_table *priorities[MAX_IDENTIFIER_PRIORITIES];
} identifier_finder;

identifier_finder IdentifierFinders::common_names_only(void) {
	identifier_finder finder;
	finder.no_priorities = 0;
	return finder;
}

void IdentifierFinders::next_priority(identifier_finder *finder,
	inter_symbols_table *where) {
	if (finder->no_priorities >= MAX_IDENTIFIER_PRIORITIES)
		internal_error("too many identifier finder priorities");
	finder->priorities[finder->no_priorities++] = where;
}

inter_symbol *IdentifierFinders::find(inter_tree *I, text_stream *name,
	identifier_finder finder) {
	if (Str::get_at(name, 0) == 0x00A7) {
		TEMPORARY_TEXT(SR)
		Str::copy(SR, name);
		Str::delete_first_character(SR);
		Str::delete_last_character(SR);
		inter_symbol *S = InterSymbolsTables::url_name_to_symbol(I, NULL, SR);
		DISCARD_TEXT(SR)
		if (S) return S;
	}
	for (int i = 0; i < finder.no_priorities; i++) {
		inter_symbol *S = Produce::seek_symbol(finder.priorities[i], name);
		if (S) return S;
	}
	inter_symbol *S = LargeScale::find_architectural_symbol(I, name, Produce::kind_to_symbol(NULL));
	if (S) return S;
	S = Produce::seek_symbol(Produce::connectors_scope(I), name);
	if (S) return S;
	S = Produce::seek_symbol(Produce::main_scope(I), name);
	if (S) return S;
	S = InterNames::to_symbol(Produce::find_by_name(I, name));
	if (S) return S;
	LOG("Defeated on %S\n", name);
	internal_error("unable to find identifier");
	return NULL;
}

inter_symbol *IdentifierFinders::find_token(inter_tree *I, inter_schema_token *t,
	identifier_finder finder) {
	if (t->as_quoted) return InterNames::to_symbol(t->as_quoted);
	return IdentifierFinders::find(I, t->material, finder);
}
