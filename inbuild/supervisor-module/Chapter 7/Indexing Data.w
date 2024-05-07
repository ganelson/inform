[IndexingData::] Indexing Data.

A set of compiled documentation has some notations for indexing, some categories
for its index entries, and a collection of "lemmas", or entries.

@ The totality of the indexing data for a CD is held in this structure:

=
typedef struct cd_indexing_data {
	struct linked_list *notations; /* of |index_markup_notation| */
	struct dictionary *categories_by_name; /* to |indexing_category| */
	struct dictionary *categories_redirect; /* to text */
	struct dictionary *lemmas; /* to |index_lemma| */
	struct linked_list *lemma_list; /* of |index_lemma| */
	struct index_lemma **sorted_lemma_list; /* or |NULL| if not yet sorted */
	struct dictionary *alphabetisation_exceptions; /* hash of lemmas with unusual alphabetisations */
	int letters_taken[26];
	int use_letter_alphabetisation; /* as opposed to word */
	int use_simplified_letter_rows;
} cd_indexing_data;

cd_indexing_data IndexingData::new_indexing_data(void) {
	cd_indexing_data id;
	id.notations = NEW_LINKED_LIST(index_markup_notation);
	id.categories_by_name = Dictionaries::new(25, FALSE);
	id.categories_redirect = Dictionaries::new(25, TRUE);
	id.lemmas = Dictionaries::new(100, FALSE);
	id.lemma_list = NEW_LINKED_LIST(index_lemma);
	id.sorted_lemma_list = NULL;
	id.alphabetisation_exceptions = Dictionaries::new(100, TRUE);
	for (int i=0; i<26; i++) id.letters_taken[i] = FALSE;
	id.use_letter_alphabetisation = TRUE;
	id.use_simplified_letter_rows = FALSE;
	return id;
}

@ Lemmas are stored by textual keys which are serialised versions of their
categorised terms. Two categorised terms are equal if and only if their serialised
forms are equal as strings.

=
index_lemma *IndexingData::retrieve_lemma(compiled_documentation *cd, categorised_term P) {
	TEMPORARY_TEXT(serialised)
	IndexTerms::serialise(serialised, cd, P);
	index_lemma *il = NULL;
	if (Dictionaries::find(cd->id.lemmas, serialised))
		il = (index_lemma *) Dictionaries::read_value(cd->id.lemmas, serialised);
	DISCARD_TEXT(serialised)
	return il;
}

void IndexingData::store_lemma(compiled_documentation *cd, index_lemma *il) {
	if (cd->id.sorted_lemma_list) internal_error("too late for more index entries");
	TEMPORARY_TEXT(serialised)
	IndexTerms::serialise(serialised, cd, il->term);
	Dictionaries::create(cd->id.lemmas, serialised);
	Dictionaries::write_value(cd->id.lemmas, serialised, il);
	ADD_TO_LINKED_LIST(il, index_lemma, cd->id.lemma_list);
	DISCARD_TEXT(serialised)
}

index_lemma **IndexingData::sort(compiled_documentation *cd, int *NL) {
	*NL = LinkedLists::len(cd->id.lemma_list);
	if (cd->id.sorted_lemma_list == NULL) {
		index_lemma *il;
		LOOP_OVER_LINKED_LIST(il, index_lemma, cd->id.lemma_list)
			IndexLemmas::make_sorting_key(cd, il);
		cd->id.sorted_lemma_list =
			Memory::calloc(*NL, sizeof(index_lemma *), ARRAY_SORTING_MREASON);
		int i=0;
		LOOP_OVER_LINKED_LIST(il, index_lemma, cd->id.lemma_list) cd->id.sorted_lemma_list[i++] = il;
		qsort(cd->id.sorted_lemma_list, (size_t) (*NL), sizeof(index_lemma *), IndexLemmas::cmp);
	}
	return cd->id.sorted_lemma_list;
}

@ The general index automatically contains an entry for every example. So if
it has more entries, it must have entries deliberately added by the source:

=
int IndexingData::indexing_occurred(compiled_documentation *cd) {
	if (LinkedLists::len(cd->id.lemma_list) > LinkedLists::len(cd->examples))
		return TRUE;
	return FALSE;
}

@ Categories are created first by reading in commands in the contents file:

=
int IndexingData::parse_category_command(compiled_documentation *cd,
	text_stream *command) {
	int success = TRUE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, command, U"^{(%C*)headword(%C*)} = (%C+) *(%c*)")) {
		indexing_category *ic = IndexingData::find_or_create_category(cd, mr.exp[2], mr.exp[3]);
		IndexMarkupNotations::add(cd, mr.exp[0], mr.exp[1], ic);
	} else if (Regexp::match(&mr, command, U"definition = (%C+) *(%c*)")) {
		indexing_category *ic = IndexingData::find_or_create_category(cd, mr.exp[0], mr.exp[1]);
		IndexingData::redirect_category(cd, I"!definition", ic);
	} else if (Regexp::match(&mr, command, U"(%C+)-definition = (%C+) *(%c*)")) {
		indexing_category *ic = IndexingData::find_or_create_category(cd, mr.exp[1], mr.exp[2]);
		TEMPORARY_TEXT(key)
		WRITE_TO(key, "!%S-definition", mr.exp[0]);
		IndexingData::redirect_category(cd, key, ic);
		DISCARD_TEXT(key)
	} else if (Regexp::match(&mr, command, U"example = (%C+) *(%c*)")) {
		indexing_category *ic = IndexingData::find_or_create_category(cd, mr.exp[0], mr.exp[1]);
		IndexingData::redirect_category(cd, I"!example", ic);
	} else {
		success = FALSE;
	}
	Regexp::dispose_of(&mr);
	return success;
}

@ Once all of the category commands have been read in, the following pair of
defaults are created automatically. Note that the notation for |standard| is
blank on either side, so that it always matches any lemma. This is why a lemma
with no special notation attached comes out in the category |standard|.

=
void IndexingData::add_default_categories(compiled_documentation *cd) {
	IndexMarkupNotations::add(cd, I"@", NULL,
		IndexingData::find_or_create_category(cd, I"name", I"(invert)"));
	IndexMarkupNotations::add(cd, NULL, NULL,
		IndexingData::find_or_create_category(cd, I"standard", NULL));
}

@ Categories can be looked up by name and turn out to have a lot of fiddly options
added:

=
typedef struct indexing_category {
	struct text_stream *cat_name;
	struct text_stream *cat_glossed; /* if set, print the style as a gloss */
	int cat_inverted; /* if set, apply name inversion */
	struct text_stream *cat_prefix; /* if set, prefix to entries */
	struct text_stream *cat_suffix; /* if set, suffix to entries */
	int cat_bracketed; /* if set, apply style to bracketed matter */
	int cat_unbracketed; /* if set, also prune brackets */
	struct text_stream *cat_under; /* for automatic subentries */
	int cat_alsounder; /* for automatic subentries */
	CLASS_DEFINITION
} indexing_category;

@ The following returns the category for a given name, creating it if it
doesn't already exist:

=
indexing_category *IndexingData::find_or_create_category(compiled_documentation *cd,
	text_stream *name, text_stream *supplied_options) {
	if (Dictionaries::find(cd->id.categories_by_name, name))
		return (indexing_category *)
			Dictionaries::read_value(cd->id.categories_by_name, name);

	indexing_category *ic = CREATE(indexing_category);
	ic->cat_name = Str::duplicate(name);
	Dictionaries::create(cd->id.categories_by_name, ic->cat_name);
	Dictionaries::write_value(cd->id.categories_by_name, ic->cat_name, ic);
	match_results mr = Regexp::create_mr();
	TEMPORARY_TEXT(options)
	WRITE_TO(options, "%S", supplied_options);
	@<Work out the fiddly details@>;
	DISCARD_TEXT(options)
	Regexp::dispose_of(&mr);
	return ic;
}

@ When we want to say "use my new category X instead of the built-in category
Y", we use the redirection dictionary. Here |redirect| is Y, and |name| is X.

@<This is a redirection@> =
	text_stream *val = Dictionaries::create_text(cd->id.categories_redirect, redirect);
	Str::copy(val, name);

@ There's a whole little mini-language for how to express details of our
category:

@<Work out the fiddly details@> =
	ic->cat_glossed = Str::new();
	if (Regexp::match(&mr, options, U"(%c*?) *%(\"(%c*?)\"%) *(%c*)")) {
		ic->cat_glossed = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_prefix = Str::new();
	if (Regexp::match(&mr, options, U"(%c*?) *%(prefix \"(%c*?)\"%) *(%c*)")) {
		ic->cat_prefix = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_suffix = Str::new();
	if (Regexp::match(&mr, options, U"(%c*?) *%(suffix \"(%c*?)\"%) *(%c*)")) {
		ic->cat_suffix = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_under = Str::new();
	if (Regexp::match(&mr, options, U"(%c*?) *%(under {(%c*?)}%) *(%c*)")) {
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
		ic->cat_under = Str::duplicate(mr.exp[1]);
	}
	ic->cat_alsounder = FALSE;
	if (Regexp::match(&mr, options, U"(%c*?) *%(also under {(%c*?)}%) *(%c*)")) {
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
		ic->cat_under = Str::duplicate(mr.exp[1]);
		ic->cat_alsounder = TRUE;
	}
	ic->cat_inverted = FALSE;
	if (Regexp::match(&mr, options, U"(%c*?) *%(invert%) *(%c*)")) {
		ic->cat_inverted = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	ic->cat_bracketed = FALSE;
	if (Regexp::match(&mr, options, U"(%c*?) *%(bracketed%) *(%c*)")) {
		ic->cat_bracketed = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	ic->cat_unbracketed = FALSE;
	if (Regexp::match(&mr, options, U"(%c*?) *%(unbracketed%) *(%c*)")) {
		ic->cat_bracketed = TRUE;
		ic->cat_unbracketed = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	if (Regexp::match(NULL, options, U"%c*?%C%c*"))
		Errors::with_text("Unknown notation options: %S", options);

@ As the above establishes, categories are found by name. We can also redirect
a second name so that it points to the same category:

=
void IndexingData::redirect_category(compiled_documentation *cd, text_stream *from,
	indexing_category *ic) {
	text_stream *val = Dictionaries::create_text(cd->id.categories_redirect, from);
	Str::copy(val, ic->cat_name);
}

@ Alphabetisation exceptions, like lemmas, are stored using a key serialised from
their categorised terms.

=
void IndexingData::make_exception(compiled_documentation *cd, categorised_term P,
	text_stream *alphabetise_as) {
	TEMPORARY_TEXT(key)
	IndexTerms::serialise(key, cd, P);
	text_stream *val = Dictionaries::create_text(cd->id.alphabetisation_exceptions, key);
	Str::copy(val, alphabetise_as);
	DISCARD_TEXT(key)
}

text_stream *IndexingData::find_exception(compiled_documentation *cd, categorised_term P) {
	TEMPORARY_TEXT(key)
	IndexTerms::serialise(key, cd, P);
	text_stream *alph = Dictionaries::get_text(cd->id.alphabetisation_exceptions, key);
	DISCARD_TEXT(key)
	return alph;
}
