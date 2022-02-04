[InterSymbolsTable::] Symbols Tables.

To manage searchable tables of named symbols.

@h Introduction.
A symbols table indexes the symbols available in a given package, and indexes
each symbol in two ways:

(a) With a dictionary for (fairly) efficient lookup by name; and
(b) With an array for rapid lookup by ID number.

Note that symbol IDs are just unsigned integers, though always integers which
exceed |SYMBOL_BASE_VAL|. They can be interpreted only in context of the
symbols table they refer to: so, for example, the ID |0x40000005| will mean
one thing in one package and something else in another. 

Some packages are very small. To save memory, the dictionary (a) is created
only when the number of symbols reaches |NO_SYMBOLS_WORTH_A_DICTIONARY|; if
there are fewer than that, it's quicker to perform name searches exhaustively
anyway, so there's no real loss in speed.

@d SYMBOL_BASE_VAL 0x40000000
@d NO_SYMBOLS_WORTH_A_DICTIONARY 5

=
typedef struct inter_symbols_table {
	struct inter_package *owning_package;

	struct dictionary *symbols_dictionary; /* this is (a) */

	struct inter_symbol **symbol_array; /* and this is (b) */
	int symbol_array_size;
	inter_ti next_free_symbol_ID;

	inter_ti resource_ID; /* within the warehouse for the tree holding the package */
	CLASS_DEFINITION
} inter_symbols_table;

@ =
inter_symbols_table *InterSymbolsTable::new(inter_ti resource_ID) {
	inter_symbols_table *ST = CREATE(inter_symbols_table);
	ST->owning_package = NULL;

	ST->symbols_dictionary = NULL;

	ST->symbol_array_size = 16;
	ST->symbol_array = (inter_symbol **) Memory::calloc(ST->symbol_array_size,
		sizeof(inter_symbol *), INTER_SYMBOLS_MREASON);
	for (int i=0; i<ST->symbol_array_size; i++) ST->symbol_array[i] = NULL;
	ST->next_free_symbol_ID = SYMBOL_BASE_VAL;

	ST->resource_ID = resource_ID;
	return ST;
}

@ Symbols tables and inter packages correspond exactly to each other, but are
not merged into a single data structure for timing reasons (mainly in the
harder case when loading binary Inter from a file).

See //InterPackage::set_scope// for where |owning_package| is set. This
function is the inverse of //InterPackage::scope//:

=
inter_package *InterSymbolsTable::package(inter_symbols_table *ST) {
	if (ST) return ST->owning_package;
	return NULL;
}

@ It is legal to strike a symbol out of a table, by setting its array entry
to be null, though this must be done with great care (if there are references
to this symbol in Inter code anywhere, for example, trouble would follow).
But this means the array may contain some nulls. The following macro loops
through non-null symbols |S| in the table |T|; note that the second |for| "loop"
executes once if |S| is non-null, and not at all if it is null.

@d LOOP_OVER_SYMBOLS_TABLE(S, T)
	for (int i=0; i<(T?(T->symbol_array_size):0); i++)
		for (inter_symbol *S = T->symbol_array[i]; S; S = NULL)

@ The following private-to-us function is an all-purpose way to access symbols
in a table by name.

If a symbol called |name| exists, we return it; or, if |wire_following| is set,
we follow the wiring to the symbol at the end of the cable -- this is what the
|name| actually means; the name doesn't really have a local meaning within the
package, in this case. (Note that the result is then a symbol outside the table
being searched, and therefore belonging to a different package to the one we
started in.)

If no such symbol exists, but |create| is set, we then create it. If |ID| is
zero, we give it the next free symbol ID within the table; otherwise we give
it exactly the id |ID|. (This is needed when loading binary Inter from a file,
and we need to make sure that we use the same IDs as those expected by that
binary code.)

=
inter_symbol *InterSymbolsTable::search_inner(inter_symbols_table *T, text_stream *name,
	int create, inter_ti ID, int wire_following) {
	if (T == NULL) internal_error("no symbols table");
	@<Handle the empty symbol name as a special case@>;
	@<Look for the name in the table, and return it if it exists@>;
	if (create) @<Create a new symbol with this name, and return it@>;
	return NULL;
}

@<Handle the empty symbol name as a special case@> =
	if (Str::len(name) == 0) {
		if (create) internal_error("cannot create a symbol with the empty name");
		return NULL;
	}

@<Look for the name in the table, and return it if it exists@> =
	inter_symbol *S = NULL;
	if (T->symbols_dictionary == NULL) {
		LOOP_OVER_SYMBOLS_TABLE(A, T)
			if (Str::eq(name, A->symbol_name)) {
				S = A; break;
			}
	} else {	
		dict_entry *de = Dictionaries::find(T->symbols_dictionary, name);
		if (de) S = (inter_symbol *) Dictionaries::read_value(T->symbols_dictionary, name);
	}
	if (S) {
		if (wire_following) S = Wiring::cable_end(S);
		return S;
	}

@<Create a new symbol with this name, and return it@> =
	if (ID == 0) ID = T->next_free_symbol_ID++;
	inter_symbol *S = InterSymbol::new_for_symbols_table(name, T, ID);
	@<Add S to the array@>;
	if (T->symbols_dictionary) {
		@<Add S to the dictionary@>;
	} else {
		if (T->next_free_symbol_ID - SYMBOL_BASE_VAL >= NO_SYMBOLS_WORTH_A_DICTIONARY)
			@<Make a dictionary from the whole symbols array, including the new S@>;
	}
	return S;

@<Add S to the array@> =
	int index = (int) ID - (int) SYMBOL_BASE_VAL;
	if (index < 0) internal_error("bad symbol ID index");
	if (index >= T->symbol_array_size) {
		int new_size = T->symbol_array_size;
		while (index >= new_size) new_size = new_size * 4;

		inter_symbol **enlarged = (inter_symbol **)
			Memory::calloc(new_size, sizeof(inter_symbol *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<new_size; i++)
			if (i < T->symbol_array_size)
				enlarged[i] = T->symbol_array[i];
			else
				enlarged[i] = NULL;
		Memory::I7_free(T->symbol_array, INTER_SYMBOLS_MREASON, T->symbol_array_size);
		T->symbol_array_size = new_size;
		T->symbol_array = enlarged;
	}
	if (index >= T->symbol_array_size) internal_error("inter symbols expansion failed");
	T->symbol_array[index] = S;

@<Add S to the dictionary@> =
	Dictionaries::create(T->symbols_dictionary, name);
	Dictionaries::write_value(T->symbols_dictionary, name, (void *) S);

@<Make a dictionary from the whole symbols array, including the new S@> =
	T->symbols_dictionary = Dictionaries::new(16, FALSE);
	LOOP_OVER_SYMBOLS_TABLE(A, T) {
		Dictionaries::create(T->symbols_dictionary, A->symbol_name);
		Dictionaries::write_value(T->symbols_dictionary, A->symbol_name, (void *) A);
	}

@h From name to symbol.
Variations on the above then provide an API for looking up the meaning of names
within a symbols table.

First: what if anything does |name| mean? Return |NULL| if nothing.

This is wire-following: that is, if the answer is a symbol wired to another symbol
elsewhere in the tree, then we return that other symbol.

=
inter_symbol *InterSymbolsTable::symbol_from_name(inter_symbols_table *T, text_stream *name) {
	return InterSymbolsTable::search_inner(T, name, FALSE, 0, TRUE);
}

@ The same, but not wire-following. The result might therefore be a symbol which
is wired to something elsewhere in the tree, and doesn't really have a local
meaning of its own.

=
inter_symbol *InterSymbolsTable::symbol_from_name_not_equating(inter_symbols_table *T,
	text_stream *name) {
	return InterSymbolsTable::search_inner(T, name, FALSE, 0, FALSE);
}

@ The same, but creating the name if it doesn't exist already.

=
inter_symbol *InterSymbolsTable::symbol_from_name_creating(inter_symbols_table *T,
	text_stream *name) {
	return InterSymbolsTable::search_inner(T, name, TRUE, 0, TRUE);
}

@ Use this variant, which forces the symbol ID to a particular value, only if you
are sure you know what you're doing. It would be disastrous to use an ID already
taken.

=
inter_symbol *InterSymbolsTable::symbol_from_name_creating_at_ID(inter_symbols_table *T,
	text_stream *name, inter_ti ID) {
	return InterSymbolsTable::search_inner(T, name, TRUE, ID, TRUE);
}

@h Creation by unique name.
Here we definitely want a new symbol, not an existing one, and if necessary
we monkey with the proposed name for it until it differs from the name of anything
already defined in the package.

=
inter_symbol *InterSymbolsTable::create_with_unique_name(inter_symbols_table *T,
	text_stream *name) {
	return InterSymbolsTable::symbol_from_name_creating(T,
		InterSymbolsTable::render_identifier_unique(T, name));
}

@ Which uses the following to construct its unique name:

=
text_stream *InterSymbolsTable::render_identifier_unique(inter_symbols_table *T,
	text_stream *name) {
	inter_symbol *ST;
	int N = 1, A = 0, still_unduplicated = TRUE;
	while ((ST = InterSymbolsTable::symbol_from_name(T, name)) != NULL) {
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

@h From ID to symbol.
Symbols are represented in Inter bytecode by their ID numbers, but these only
make sense in the context of a symbols table: i.e., the same ID can have
a different meaning in one inter frame than in another. We provide two ways
to access this: one following equations, the other not.

=
inter_symbol *InterSymbolsTable::symbol_from_ID_not_equating(inter_symbols_table *T,
	inter_ti ID) {
	if (T == NULL) return NULL;
	int index = (int) ID - (int) SYMBOL_BASE_VAL;
	if (index < 0) return NULL;
	if (index >= T->symbol_array_size) return NULL;
	return T->symbol_array[index];
}

inter_symbol *InterSymbolsTable::symbol_from_ID(inter_symbols_table *T, inter_ti ID) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_not_equating(T, ID);
	return Wiring::cable_end(S);
}

@ It's convenient to have some abbreviations for common ways to access the above.

=
inter_symbol *InterSymbolsTable::symbol_from_ID_at_node(inter_tree_node *P, int x) {
	return InterSymbolsTable::symbol_from_ID(InterPackage::scope_of(P), P->W.instruction[x]);
}

inter_symbol *InterSymbolsTable::global_symbol_from_ID_at_node(inter_tree_node *P, int x) {
	return InterSymbolsTable::symbol_from_ID(Inode::globals(P), P->W.instruction[x]);
}

inter_symbol *InterSymbolsTable::symbol_from_ID_in_package(inter_package *owner, inter_ti ID) {
	return InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), ID);
}

@ A data pair in the form |(ALIAS_IVAL, ID)| is understood as the symbol with this
ID in the contextually relevant package. So:

=
inter_symbol *InterSymbolsTable::symbol_from_data_pair(inter_ti val1, inter_ti val2,
	inter_symbols_table *T) {
	if (val1 == ALIAS_IVAL) return InterSymbolsTable::symbol_from_ID(T, val2);
	return NULL;
}

inter_symbol *InterSymbolsTable::symbol_from_data_pair_at_node(inter_ti val1,
	inter_ti val2, inter_tree_node *P) {
	return InterSymbolsTable::symbol_from_data_pair(val1, val2, InterPackage::scope_of(P));
}

@h From symbol to ID.
If all we want is to read the ID of a symbol definitely present in the given
symbols table, that's easy. Suppose we have this example:
= (text)
    +-----------------+
    | Package P       |
    |                 |
    | 0: example      |
    | 1: another      |
    | 2: plugh        |
    | 3: further      |
    +-----------------+
=
Then if we want the ID of symbol |plugh| in package |P|, we just return 3,
its symbol ID within the table.

Here, if |P| is null then we use the root package, and therefore the global
symbols table.

=
inter_ti InterSymbolsTable::id_from_symbol_not_creating(inter_tree *I,
	inter_package *P, inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	inter_symbols_table *T = InterPackage::scope(P);
	if (T == NULL) T = InterTree::global_scope(I);
	if (T != S->owning_table) {
		LOG("Symbol is $3, owned by $4, but we wanted ID from $4\n", S, S->owning_table, T);
		internal_error("ID not available in this scope");
	}
	return S->symbol_ID;
}

inter_ti InterSymbolsTable::id_from_global_symbol(inter_tree *I, inter_symbol *S) {
	return InterSymbolsTable::id_from_symbol_not_creating(I, NULL, S);
}

@ However, things become more interesting if we do not know that the symbol
|S| belongs to |P|. Suppose:
= (text)
    +-----------------+    +-----------------+
    | Package P       |    | Package SP      |
    |                 |    |                 |
    | 0: example      |    | 0: xyzzy        |
    | 1: another      |    | 1: plugh        |
    | 2: further      |    |                 |
    +-----------------+    +-----------------+
=
and suppose we again want the ID for |plugh| within package |P|. The only way
to do this is to create a new symbol in |P| and wire it to |plugh|:
= (text)
    +-----------------+
    | Package P       |
    |                 |    +-----------------+
    | 0: example      |    | Package SP      |
    | 1: another      |    |                 |
    | 2: further      |    |   0: xyzzy      |
    | 3: plugh ~~~~~~~~~~~~~~> 1: plugh      |
    +-----------------+    +-----------------+
=
We can then return 3 as the ID of |plugh| within |P|. 

Note that there are now two symbols named |plugh|, one in each package. But the
new one in |P| is a sort of reference only: it is wired to the old one in |SP|.
To see what the new |plugh| means, one must follow the wiring to the old |plugh|.
But this is no real burden, because:

(a) A name-search by //InterSymbolsTable::symbol_from_name// on |"plugh"| within
the package |P| finds the new |plugh| symbol but then follows the wiring to
the old |plugh| in |SP|, and returns that; and

(b) So does ID lookup by //InterSymbolsTable::symbol_from_ID// on ID 3 within |P|.

In effect, once the following function has been used, everything will work just
as if the symbol were in |P| after all.

Finally, note that this awkward case:
= (text)
    +-----------------+    +-----------------+
    | Package P       |    | Package SP      |
    |                 |    |                 |
    | 0: plugh        |    | 0: xyzzy        |
    | 1: another      |    | 1: plugh        |
    | 2: further      |    |                 |
    +-----------------+    +-----------------+
=
also needs to be handled: i.e., where package |P| already contains a different
and unrelated symbol coincidentally called |"plugh"|. In that case, we end up with:
= (text)
    +-----------------+
    | Package P       |
    |                 |    +-----------------+
    | 0: plugh        |    | Package SP      |
    | 1: another      |    |                 |
    | 2: further      |    |   0: xyzzy      |
    | 3: plugh_1 ~~~~~~~~~~~~> 1: plugh      |
    +-----------------+    +-----------------+
=
This time, the reference symbol has been named |"plugh_1"| to avoid a name
collision with the original |plugh| in package |P|.

=
inter_ti InterSymbolsTable::id_from_symbol(inter_tree *I, inter_package *P, inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	inter_symbols_table *P_table = InterPackage::scope(P);
	if (P_table == NULL) P_table = InterTree::global_scope(I);
	inter_symbols_table *SP_table = S->owning_table;
	if (P_table != SP_table) @<We need an ID to a faraway symbol@>
	else return S->symbol_ID;
}

@ Because global symbols are visible everywhere, we never need local IDs for
them on a package-by-package basis, so it is an error to call this function if
|S| is a global.

@<We need an ID to a faraway symbol@> =
	LOGIF(INTER_SYMBOLS,
		"Seek ID of $3 from $4, which is not its owner $4\n", S, P_table, SP_table);
	if (SP_table == InterTree::global_scope(I))
		internal_error("cannot make a local symbol ID from a global symbol");
	@<If this table already has a symbol wired to that faraway symbol, fine: use that@>;
	@<Otherwise make a new symbol in the table and wire it to the faraway one@>;

@<If this table already has a symbol wired to that faraway symbol, fine: use that@> =
	LOOP_OVER_SYMBOLS_TABLE(E, P_table)
		if (Wiring::wired_to(E) == S)
			return (inter_ti) E->symbol_ID;

@<Otherwise make a new symbol in the table and wire it to the faraway one@> =
	inter_symbol *X = InterSymbolsTable::create_with_unique_name(P_table, S->symbol_name);
	Wiring::wire_to(X, S);
	return X->symbol_ID;

@ The same operation, but the local context expressed differently:

=
inter_ti InterSymbolsTable::id_from_symbol_at_bookmark(inter_bookmark *IBM,
	inter_symbol *S) {
	return InterSymbolsTable::id_from_symbol(InterBookmark::tree(IBM),
		InterBookmark::package(IBM), S);
}

@h URL-style symbol names.
We saw in //InterPackage::write_URL// that every package can be identified
uniquely by a URL, so that, say, |/main/example/whatever| means the package
|whatever| in the package |example| in the package |main| at the root of the tree.

As a result, symbols can also have unique URLs: |/main/example/whatever/plugh|
means the symbol called |plugh| which is in that package.

This is not really two different conventions. The URL for a package is the same
as the URL for the symbol of that package's name, so really we can think of URLs
for packages as a special case of URLs for symbols.

@d MAX_URL_SYMBOL_NAME_DEPTH 512

=
void InterSymbolsTable::write_symbol_URL(OUTPUT_STREAM, inter_symbol *S) {
	inter_package *chain[MAX_URL_SYMBOL_NAME_DEPTH];
	int chain_length = 0;
	inter_package *P = InterSymbolsTable::package(S->owning_table);
	if (P == NULL) { WRITE("%S", S->symbol_name); return; }
	while (P) {
		if (chain_length >= MAX_URL_SYMBOL_NAME_DEPTH) internal_error("package nesting too deep");
		chain[chain_length++] = P;
		P = InterPackage::parent(P);
	}
	for (int i=chain_length-1; i>=0; i--) WRITE("/%S", InterPackage::name(chain[i]));
	WRITE("/%S", S->symbol_name);
}

@ Conversely, we parse a URL and locate the symbol it describes.

All URLs here are absolute. If no initial |/| occurs, the URL is assumed to be
a global name: so |/global_name| and |global_name| both mean the same thing,
i.e., the symbol named |global_name| in the root package. However, |this/that|
means a symbol named |this/that| (which cannot ever exist), not a symbol named
|that| in a package named |this|.

=
inter_symbol *InterSymbolsTable::URL_to_symbol(inter_tree *I, text_stream *URL) {
	if (Str::get_first_char(URL) == '/') {
		inter_package *at_P = I->root_package;
		TEMPORARY_TEXT(C)
		LOOP_THROUGH_TEXT(P, URL) {
			wchar_t c = Str::get(P);
			if (c == '/') {
				if (Str::len(C) > 0) {
					at_P = InterPackage::from_name(at_P, C);
					if (at_P == NULL) return NULL;
				}
				Str::clear(C);
			} else {
				PUT_TO(C, c);
			}
		}
		return InterSymbolsTable::symbol_from_name(InterPackage::scope(at_P), C);
	}
	return InterSymbolsTable::symbol_from_name(InterTree::global_scope(I), URL);
}

@h Striking out symbols.
This is a desperation measure. The tree may be full of references to |S| made
by its ID: those IDs will then fail to resolve if the array entry for |S| has
been struck out to |NULL|, and the result could be horribly inconsistent.
So the function should be used only with great care.

Note that the name is not removed from the dictionary (if the table has one).
This means that textual lookups on it might still return |S|: so, again, do
not use the function if that is able to cause problems.

=
void InterSymbolsTable::remove_symbol(inter_symbol *S) {
	int index = (int) S->symbol_ID - (int) SYMBOL_BASE_VAL;
	Wiring::wire_to(S, NULL);
	S->owning_table->symbol_array[index] = NULL;
}

@h Logging.

=
void InterSymbolsTable::log(OUTPUT_STREAM, void *vst) {
	inter_symbols_table *ST = (inter_symbols_table *) vst;
	if (ST == NULL) WRITE("<null-stable>");
	else {
		WRITE("<%d:", ST->allocation_id);
		inter_package *P = InterSymbolsTable::package(ST);
		if (P == NULL) WRITE("(root)"); else WRITE("$6", P);
		WRITE(">");
	}
}

