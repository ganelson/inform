[InterSymbolsTables::] Symbols Tables.

To manage searchable tables of named symbols.

@h Symbols tables.

=
typedef struct inter_symbols_table {
	struct inter_package *owning_package;
	struct dictionary *symbols_lookup;
	int size;
	struct inter_symbol **symbol_array;
	int n_index;
	inter_ti next_free_ID;
	CLASS_DEFINITION
} inter_symbols_table;

@

@d INITIAL_INTER_SYMBOLS_ID_RANGE 16
@d SYMBOLS_THRESHOLD 5

=
inter_symbols_table *InterSymbolsTables::new(void) {
	inter_symbols_table *ST = CREATE(inter_symbols_table);
	ST->symbols_lookup = NULL;
	ST->size = INITIAL_INTER_SYMBOLS_ID_RANGE;
	ST->symbol_array = (inter_symbol **)
		Memory::calloc(INITIAL_INTER_SYMBOLS_ID_RANGE, sizeof(inter_symbol *), INTER_SYMBOLS_MREASON);
	for (int i=0; i<INITIAL_INTER_SYMBOLS_ID_RANGE; i++) ST->symbol_array[i] = NULL;
	ST->n_index = 0;
	ST->owning_package = NULL;
	ST->next_free_ID = SYMBOL_BASE_VAL;
	return ST;
}

void InterSymbolsTables::log(OUTPUT_STREAM, void *vst) {
	inter_symbols_table *ST = (inter_symbols_table *) vst;
	if (ST == NULL) WRITE("<null-stable>");
	else {
		WRITE("<%d:", ST->allocation_id);
		if (ST->owning_package == NULL) WRITE("(root)");
		else WRITE("$6", ST->owning_package);
		WRITE(">");
	}
}

@

@d LOOP_OVER_SYMBOLS_TABLE(S, T)
	for (int i=0; i<T->size; i++)
		for (inter_symbol *S = T->symbol_array[i]; S; S = NULL)

=
void InterSymbolsTables::write_declarations(OUTPUT_STREAM, inter_symbols_table *ST, int L) {
	if (ST == NULL) return;
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		if (S) {
			Inter::Symbols::write_declaration(OUT, S, L); WRITE("\n");
		}
	}
}

inter_symbol *InterSymbolsTables::search_inner(inter_symbols_table *T, text_stream *S, int create, inter_ti ID, int equating) {
	if (T == NULL) internal_error("no IST");
	if (S == NULL) return NULL;
	
	if ((T->symbols_lookup == NULL) &&
		(T->next_free_ID - SYMBOL_BASE_VAL >= SYMBOLS_THRESHOLD)) {
		T->symbols_lookup = Dictionaries::new(INITIAL_INTER_SYMBOLS_ID_RANGE, FALSE);
		for (int i=0; i<T->size; i++) {
			inter_symbol *A = T->symbol_array[i];
			if (A) {
				Dictionaries::create(T->symbols_lookup, A->symbol_name);
				Dictionaries::write_value(T->symbols_lookup, A->symbol_name, (void *) A);
			}
		}
	}
	
	if (T->symbols_lookup == NULL) {
		for (int i=0; i<T->size; i++) {
			inter_symbol *A = T->symbol_array[i];
			if ((A) && (Str::eq(S, A->symbol_name))) {
				if (equating) {
					while (A->equated_to) A = A->equated_to;
				}
				return A;
			}
		}
	} else {	
		dict_entry *de = Dictionaries::find(T->symbols_lookup, S);
		if (de) {
			inter_symbol *A = (inter_symbol *) Dictionaries::read_value(T->symbols_lookup, S);
			if (A) {
				if (equating) {
					while (A->equated_to) A = A->equated_to;
				}
				return A;
			}
		}
	}

	if (create == FALSE) return NULL;

	if (ID == 0) ID = T->next_free_ID++;
	inter_symbol *ST = Inter::Symbols::new(S, T, ID);

	if (T->symbols_lookup) {
		Dictionaries::create(T->symbols_lookup, S);
		Dictionaries::write_value(T->symbols_lookup, S, (void *) ST);
	}

	int index = (int) ID - (int) SYMBOL_BASE_VAL;
	if (index < 0) internal_error("bad symbol ID index");
	if (index >= T->size) {
		int new_size = T->size;
		while (index >= new_size) new_size = new_size * 4;

		inter_symbol **enlarged = (inter_symbol **)
			Memory::calloc(new_size, sizeof(inter_symbol *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<new_size; i++)
			if (i < T->size)
				enlarged[i] = T->symbol_array[i];
			else
				enlarged[i] = NULL;
		Memory::I7_free(T->symbol_array, INTER_SYMBOLS_MREASON, T->size);
		T->size = new_size;
		T->symbol_array = enlarged;
	}
	if (index >= T->size) internal_error("inter symbols expansion failed");
	T->symbol_array[index] = ST;

	return ST;
}

@h From name to symbol.

=
inter_symbol *InterSymbolsTables::symbol_from_name(inter_symbols_table *T, text_stream *S) {
	return InterSymbolsTables::search_inner(T, S, FALSE, 0, TRUE);
}

inter_symbol *InterSymbolsTables::symbol_from_name_not_equating(inter_symbols_table *T, text_stream *S) {
	return InterSymbolsTables::search_inner(T, S, FALSE, 0, FALSE);
}

inter_symbol *InterSymbolsTables::symbol_from_name_creating(inter_symbols_table *T, text_stream *S) {
	return InterSymbolsTables::search_inner(T, S, TRUE, 0, TRUE);
}

inter_symbol *InterSymbolsTables::symbol_from_name_creating_at_ID(inter_symbols_table *T, text_stream *S, inter_ti ID) {
	return InterSymbolsTables::search_inner(T, S, TRUE, ID, TRUE);
}

inter_symbol *InterSymbolsTables::symbol_from_name_in_main(inter_tree *I, text_stream *S) {
	return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(Site::main_package_if_it_exists(I)), S);
}

inter_symbol *InterSymbolsTables::symbol_from_name_in_basics(inter_tree *I, text_stream *S) {
	inter_package *P = Inter::Packages::basics(I);
	if (P == NULL) return NULL;
	return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
}

inter_symbol *InterSymbolsTables::symbol_from_name_in_veneer(inter_tree *I, text_stream *S) {
	inter_package *P = Inter::Packages::veneer(I);
	if (P == NULL) return NULL;
	return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
}

inter_symbol *InterSymbolsTables::symbol_from_name_in_template(inter_tree *I, text_stream *S) {
	inter_package *P = Inter::Packages::template(I);
	if (P == NULL) return NULL;
	return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(P), S);
}

inter_symbol *InterSymbolsTables::symbol_from_name_in_main_or_basics(inter_tree *I, text_stream *S) {
	inter_symbol *symbol = InterSymbolsTables::symbol_from_name_in_basics(I, S);
	if (symbol == NULL) symbol = InterSymbolsTables::symbol_from_name_in_veneer(I, S);
	if (symbol == NULL) symbol = InterSymbolsTables::symbol_from_name_in_main(I, S);
	return symbol;
}

@h Creation by unique name.

=
text_stream *InterSymbolsTables::render_identifier_unique(inter_symbols_table *T, text_stream *name) {
	inter_symbol *ST;
	int N = 1, A = 0, still_unduplicated = TRUE;
	while ((ST = InterSymbolsTables::symbol_from_name(T, name)) != NULL) {
		if (still_unduplicated) {
			name = Str::duplicate(name);
			still_unduplicated = FALSE;
		}
		TEMPORARY_TEXT(TAIL)
		WRITE_TO(TAIL, "_%d", N++);
		if (A > 0) Str::truncate(name, Str::len(name) - A);
		A = Str::len(TAIL);
		WRITE_TO(name, "%S", TAIL);
		Str::truncate(name, 31);
		DISCARD_TEXT(TAIL)
	}
	return name;
}

inter_symbol *InterSymbolsTables::create_with_unique_name(inter_symbols_table *T, text_stream *name) {
	return InterSymbolsTables::symbol_from_name_creating(T,
		InterSymbolsTables::render_identifier_unique(T, name));
}

@h From symbol to ID.
Symbols are represented in Inter bytecode by their ID numbers, but these only
make sense in the context of a symbols table: i.e., the same ID can have
a different meaning in one inter frame than in another. We provide two ways
to access this: one following equations, the other not.

=
inter_symbol *InterSymbolsTables::unequated_symbol_from_id(inter_symbols_table *T, inter_ti ID) {
	if (T == NULL) return NULL;
	int index = (int) ID - (int) SYMBOL_BASE_VAL;
	if (index < 0) return NULL;
	if (index >= T->size) return NULL;
	return T->symbol_array[index];
}

inter_symbol *InterSymbolsTables::symbol_from_id(inter_symbols_table *T, inter_ti ID) {
	inter_symbol *S = InterSymbolsTables::unequated_symbol_from_id(T, ID);
	while ((S) && (S->equated_to)) S = S->equated_to;
	return S;
}

@ It's convenient to have some abbreviations for common ways to access the above.

=
inter_symbol *InterSymbolsTables::symbol_from_frame_data(inter_tree_node *P, int x) {
	return InterSymbolsTables::symbol_from_id(Inter::Packages::scope_of(P), P->W.data[x]);
}

inter_symbol *InterSymbolsTables::global_symbol_from_frame_data(inter_tree_node *P, int x) {
	return InterSymbolsTables::symbol_from_id(Inode::globals(P), P->W.data[x]);
}

inter_symbol *InterSymbolsTables::local_symbol_from_id(inter_package *owner, inter_ti ID) {
	return InterSymbolsTables::symbol_from_id(Inter::Packages::scope(owner), ID);
}

inter_symbol *InterSymbolsTables::symbol_from_data_pair_and_table(inter_ti val1, inter_ti val2, inter_symbols_table *T) {
	if (val1 == ALIAS_IVAL) return InterSymbolsTables::symbol_from_id(T, val2);
	return NULL;
}

inter_symbol *InterSymbolsTables::symbol_from_data_pair_and_frame(inter_ti val1, inter_ti val2, inter_tree_node *P) {
	return InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
}

@h From ID to symbol.
If all we want is to read the ID of a symbol definitely present in the given
symbols table, that's easy:

=
inter_ti InterSymbolsTables::id_from_symbol_inner_not_creating(inter_tree *I, inter_package *P, inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	inter_symbols_table *T = Inter::Packages::scope(P);
	if (T == NULL) T = Inter::Tree::global_scope(I);
	if (T != S->owning_table) {
		LOG("Symbol is $3, owned by $4, but we wanted ID from $4\n", S, S->owning_table, T);
		internal_error("ID not available in this scope");
	}
	return S->symbol_ID;
}

inter_ti InterSymbolsTables::id_from_symbol_not_creating(inter_tree *I, inter_package *P, inter_symbol *S) {
	return InterSymbolsTables::id_from_symbol_inner_not_creating(I, P, S);
}

inter_ti InterSymbolsTables::id_from_bookmark_and_symbol_not_creating(inter_bookmark *IBM, inter_symbol *S) {
	return InterSymbolsTables::id_from_symbol_inner_not_creating(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), S);
}

@ However, things become more interesting if we want an ID for a symbol in
a context other than its home. We then create a new symbol in the current
context, equate it to the original, and return the ID of the new symbol.

Globals are not allowed to be reached this way, purely for efficiency's
sake: we don't want to proliferate equated symbols for primitives like
|!store|, not for package types like |_code|. (But it would work perfectly
well if we did.) It's therefore an internal error to call this routine with
a global symbol in any non-global context.

=
inter_ti InterSymbolsTables::id_from_symbol_inner(inter_symbols_table *G, inter_package *P, inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	inter_symbols_table *T = Inter::Packages::scope(P);
	if (T == NULL) T = G;
	if (T != S->owning_table) {
		LOGIF(INTER_SYMBOLS, "Seek ID of $3 from $4, which is not its owner $4\n", S, T, S->owning_table);
		if (S->owning_table == G) {
			LOG("Seek ID of $3 from $4, which is not its owner $4\n", S, T, S->owning_table);
			internal_error("attempted to equate to global");
		}
		for (int i=0; i<T->size; i++)
			if ((T->symbol_array[i]) && (T->symbol_array[i]->equated_to == S))
				return (inter_ti) T->symbol_array[i]->symbol_ID;
		text_stream *N = InterSymbolsTables::render_identifier_unique(T, S->symbol_name);
		inter_symbol *X = InterSymbolsTables::search_inner(T, N, TRUE, 0, FALSE);
		if (X->equated_to == NULL) {
			InterSymbolsTables::equate(X, S);
			LOGIF(INTER_SYMBOLS, "Equating $3 to new $3\n", S, X);
		}
		if (X->equated_to != S) {
			LOG("Want ID for $3 but there's already $3 locally which equates to $3\n", S, X, X->equated_to);
			internal_error("external symbol clash");
		}
		return X->symbol_ID;
	}
	return S->symbol_ID;
}

inter_ti InterSymbolsTables::id_from_symbol(inter_tree *I, inter_package *P, inter_symbol *S) {
	return InterSymbolsTables::id_from_symbol_inner(Inter::Tree::global_scope(I), P, S);
}

inter_ti InterSymbolsTables::id_from_symbol_F(inter_tree_node *F, inter_package *P, inter_symbol *S) {
	return InterSymbolsTables::id_from_symbol_inner(Inode::globals(F), P, S);
}

inter_ti InterSymbolsTables::id_from_IRS_and_symbol(inter_bookmark *IBM, inter_symbol *S) {
	return InterSymbolsTables::id_from_symbol_inner(Inter::Tree::global_scope(Inter::Bookmarks::tree(IBM)), Inter::Bookmarks::package(IBM), S);
}

@h Equations.

=
void InterSymbolsTables::equate(inter_symbol *S_from, inter_symbol *S_to) {
	if ((S_from == NULL) || (S_to == NULL)) internal_error("bad symbol equation");
	S_from->equated_to = S_to;
	if ((Inter::Symbols::get_scope(S_from) != SOCKET_ISYMS) &&
		(Inter::Symbols::get_scope(S_from) != PLUG_ISYMS))
		Inter::Symbols::set_scope(S_from, EXTERNAL_ISYMS);
	LOGIF(INTER_SYMBOLS, "Equate $3 to $3\n", S_from, S_to);
	int c = 0;
	for (inter_symbol *S = S_from; S; S = S->equated_to, c++)
		if (c == 20) {
			c = 0;
			for (inter_symbol *S = S_from; c < 20; S = S->equated_to, c++)
				LOG("%d. %S\n", c, S->symbol_name);
			internal_error("probably circular symbol equation");
		}
}

void InterSymbolsTables::equate_textual(inter_symbol *S_from, text_stream *name) {
	if ((S_from == NULL) || (name == NULL)) internal_error("bad symbol equation");
	S_from->equated_to = NULL;
	S_from->equated_name = Str::duplicate(name);
	Inter::Symbols::set_scope(S_from, EXTERNAL_ISYMS);
}

void InterSymbolsTables::make_plug(inter_symbol *S_from, text_stream *wanted) {
	if ((S_from == NULL) || (wanted == NULL)) internal_error("bad link equation");
	S_from->equated_to = NULL;
	S_from->equated_name = Str::duplicate(wanted);
	Inter::Symbols::set_scope(S_from, PLUG_ISYMS);
	Inter::Symbols::set_type(S_from, MISC_ISYMT);
}

void InterSymbolsTables::make_socket(inter_symbol *S_from, inter_symbol *wired_from) {
	if (S_from == NULL) internal_error("bad link equation");
	S_from->equated_to = wired_from;
	Inter::Symbols::set_scope(S_from, SOCKET_ISYMS);
}

void InterSymbolsTables::resolve_forward_references(inter_tree *I, inter_error_location *eloc) {
	Inter::Tree::traverse(I, InterSymbolsTables::rfr_visitor, eloc, NULL, PACKAGE_IST);
}

void InterSymbolsTables::rfr_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_location *eloc = (inter_error_location *) state;
	inter_package *pack = Inter::Package::defined_by_frame(P);
	if (pack == NULL) internal_error("no package defined here");
	inter_symbols_table *T = Inter::Packages::scope(pack);
	if (T == NULL) internal_error("package with no symbols");
	for (int i=0; i<T->size; i++) {
		inter_symbol *symb = T->symbol_array[i];
		if ((symb) && (symb->equated_name)) {
			if (Inter::Symbols::get_scope(symb) == PLUG_ISYMS) continue;
			inter_symbol *S_to = InterSymbolsTables::url_name_to_symbol(Inter::Packages::tree(pack), T, symb->equated_name);
			if (S_to == NULL) Inter::Errors::issue(Inter::Errors::quoted(I"unable to locate symbol", symb->equated_name, eloc));
			else if (Inter::Symbols::get_scope(symb) == SOCKET_ISYMS)
				InterSymbolsTables::make_socket(symb, S_to);
			else InterSymbolsTables::equate(symb, S_to);
			symb->equated_name = NULL;
		}
	}
}

@h URL-style symbol names.

@d MAX_URL_SYMBOL_NAME_DEPTH 512

=
inter_symbol *InterSymbolsTables::url_name_to_symbol(inter_tree *I, inter_symbols_table *T, text_stream *S) {
	inter_symbols_table *at = Inter::Tree::global_scope(I);
	if (Str::get_first_char(S) == '/') {
		inter_package *at_P = I->root_package;
		TEMPORARY_TEXT(C)
		LOOP_THROUGH_TEXT(P, S) {
			wchar_t c = Str::get(P);
			if (c == '/') {
				if (Str::len(C) > 0) {
					at_P = Inter::Packages::by_name(at_P, C);
					if (at_P == NULL) return NULL;
				}
				Str::clear(C);
			} else {
				PUT_TO(C, c);
			}
		}
		return InterSymbolsTables::symbol_from_name(Inter::Packages::scope(at_P), C);
	}
	inter_symbol *try = InterSymbolsTables::symbol_from_name(at, S);
	if (try) return try;
	if (T) return InterSymbolsTables::symbol_from_name(T, S);
	return NULL;
}

void InterSymbolsTables::symbol_to_url_name(OUTPUT_STREAM, inter_symbol *S) {
	inter_package *chain[MAX_URL_SYMBOL_NAME_DEPTH];
	int chain_length = 0;
	inter_package *P = S->owning_table->owning_package;
	if (P == NULL) { WRITE("%S", S->symbol_name); return; }
	while (P) {
		if (chain_length >= MAX_URL_SYMBOL_NAME_DEPTH) internal_error("package nesting too deep");
		chain[chain_length++] = P;
		P = Inter::Packages::parent(P);
	}
	for (int i=chain_length-1; i>=0; i--) WRITE("/%S", Inter::Packages::name(chain[i]));
	WRITE("/%S", S->symbol_name);
}

