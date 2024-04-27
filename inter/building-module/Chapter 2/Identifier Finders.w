[IdentifierFinders::] Identifier Finders.

Suppose we have an identifier name which we think refers to some symbol in an
Inter tree. Where do we look for it?

@ The answer must depend on context, so the question really has to be "with
the conventions given by this |identifier_finder|, what |inter_symbol|
does this name correspond to?".

@d MAX_IDENTIFIER_PRIORITIES 3

=
typedef struct identifier_finder {
	int no_priorities;
	struct inter_symbols_table *priorities[MAX_IDENTIFIER_PRIORITIES];
	struct text_stream *from_namespace;
} identifier_finder;

@ The most basic set of conventions only allows us to see names visible
everywhere:

=
identifier_finder IdentifierFinders::common_names_only(void) {
	identifier_finder finder;
	finder.no_priorities = 0;
	finder.from_namespace = NULL;
	return finder;
}

@ But we can add to that by providing up to three symbols tables to search
in preference order (first match wins):

=
void IdentifierFinders::next_priority(identifier_finder *finder,
	inter_symbols_table *where) {
	if (finder->no_priorities >= MAX_IDENTIFIER_PRIORITIES)
		internal_error("too many identifier finder priorities");
	finder->priorities[finder->no_priorities++] = where;
}

@ And we can similarly specify the namespace we're coming from:

=
void IdentifierFinders::set_namespace(identifier_finder *finder,
	text_stream *namespace) {
	if (Str::len(namespace) > 0) {
		if (Str::len(finder->from_namespace) > 0) internal_error("namespace twice");
		finder->from_namespace = Str::duplicate(namespace);
	}
}

@ And here goes.

=
inter_symbol *IdentifierFinders::find(inter_tree *I, text_stream *name,
	identifier_finder finder) {
	if (Str::get_at(name, 0) == 0x00A7)
		@<Interpret this as an absolute URL@>
	else
		@<Interpret this as an identifier@>;
	LOG("Defeated on %S\n", name);
	internal_error("unable to find identifier");
	return NULL;
}

@ If the name begins with this magic character, we interpret it as an absolute
URL within the tree -- the conventions are then unimportant: either the symbol
exists where we said it is, or nothing is found. And in that case we will
halt with an internal error: so this must be done speculatively.

@<Interpret this as an absolute URL@> =
	TEMPORARY_TEXT(SR)
	Str::copy(SR, name);
	Str::delete_first_character(SR);
	Str::delete_last_character(SR);
	inter_symbol *S = InterSymbolsTable::URL_to_symbol(I, SR);
	DISCARD_TEXT(SR)
	if (S) return S;

@ Here, though, if all attempts to find the identifier fail, we in effect
force it to exist by creating a plug with this name, and then returning that.
So the above internal error cannot occur.

@<Interpret this as an identifier@> =
	text_stream *seek = name;
	TEMPORARY_TEXT(N)
	int add_namespace = FALSE;
	if (Str::len(finder.from_namespace) > 0) {
		add_namespace = TRUE;
		for (int i=0; i<Str::len(name); i++)
			if (Str::get_at(name, i) == '`')
				add_namespace = FALSE;
		if (add_namespace) {
			WRITE_TO(N, "%S`%S", finder.from_namespace, name);
			seek = N;
		}
	}
	inter_symbol *S = NULL;
	for (int i = 0; i < finder.no_priorities; i++) {
		S = InterSymbolsTable::symbol_from_name(finder.priorities[i], seek);
		if (S) goto Exit;
	}
	S = LargeScale::find_architectural_symbol(I, name);
	if (S) goto Exit;
	S = InterSymbolsTable::symbol_from_name(LargeScale::connectors_scope(I), seek);
	if (S) goto Exit;
	S = InterSymbolsTable::symbol_from_name(LargeScale::main_scope(I), name);
	if (S) goto Exit;
	if (add_namespace)
		S = InterNames::to_symbol(HierarchyLocations::find_by_implied_name(I, name, finder.from_namespace));
	else
		S = InterNames::to_symbol(HierarchyLocations::find_by_name(I, seek));
	Exit: ;
	DISCARD_TEXT(N)
	return S;

@ A small variation. Note that a token can be marked explicitly with an iname
to which it corresponds; if it has been, then this overrides the finding process,
because the symbol which that iname incarnates as must be the right one.

=
inter_symbol *IdentifierFinders::find_token(inter_tree *I, inter_schema_token *t,
	identifier_finder finder) {
	if (t->as_quoted) return InterNames::to_symbol(t->as_quoted);
	#ifdef CORE_MODULE
	local_variable *lvar = LocalVariables::by_identifier(t->material);
	if (lvar) return LocalVariables::declare(lvar);
	#endif
	LOGIF(INTER_CONNECTORS, "Finding token %S from namespace '%S'\n",
		t->material, finder.from_namespace);
	return IdentifierFinders::find(I, t->material, finder);
}
