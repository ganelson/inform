[Origins::] Origins.

Keeping track of sources of code for an Inter tree.

@ We need a quick way to turn a filename, which may be a longish text, into a
symbol defined in a suitable |ORIGIN_IST| instruction at the top of the tree.
This will be a dictionary, i.e., a hash:

=
typedef struct site_origins_data {
	int origins_count;
	struct text_stream *last_filename;
	struct inter_symbol *last_symbol;
	struct dictionary *filenames_to_symbols;
} site_origins_data;

void Origins::clear_site_data(inter_tree *I) {
	building_site *B = &(I->site);
	B->soridata.origins_count = 0;
	B->soridata.last_filename = Str::new();
	B->soridata.last_symbol = NULL;
	B->soridata.filenames_to_symbols = Dictionaries::new(32, FALSE);
}

@ This gives us just one function: which returns the symbol for a filename,
creating it as necessary. |-| by definition means "nowhere".

This function is almost always called in such a way that two consecutive
non-null values of |fn| will be the same, so it makes sense to cache the
most recent answer as a first line of defence, and then use a dictionary
lookup if that fails.

=
inter_symbol *Origins::filename_to_origin(inter_tree *I, text_stream *fn) {
	if ((Str::len(fn) == 0) || (Str::eq(fn, I"-"))) return NULL;

	building_site *B = &(I->site);

	if (Str::eq(fn, B->soridata.last_filename)) return B->soridata.last_symbol;

	inter_symbol *symbol = NULL;
	dictionary *D = B->soridata.filenames_to_symbols;

	if (Dictionaries::find(D, fn)) {
		symbol = (inter_symbol *) Dictionaries::read_value(D, fn);
	} else {
		inter_symbols_table *scope = InterTree::global_scope(I);
		TEMPORARY_TEXT(sname)
		WRITE_TO(sname, "origin_%d", ++(B->soridata.origins_count));
		symbol = InterSymbolsTable::create_with_unique_name(scope, sname);
		DISCARD_TEXT(sname)
		LargeScale::emit_origin(I, symbol, fn);
		Dictionaries::create(D, fn);
		Dictionaries::write_value(D, fn, (void *) symbol);
	}

	Str::clear(B->soridata.last_filename);
	Str::copy(B->soridata.last_filename, fn);
	B->soridata.last_symbol = symbol;
	return symbol;
}
