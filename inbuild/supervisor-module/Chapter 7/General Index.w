[Indexes::] Contents and Indexes.

To produce a general index, for HTML output only.

@h Indexing notations.
These allow markup such as |this is ^{nifty}| to mark headwords in the source
documentation for indexing.

Only two of the four ways to add indexing notation actually create a new
notation as such: the other two instead piggyback on built-in, i.e., already
defined, ones. But in all four cases a new "category" is made, corresponding
roughly to a CSS class used in the final output.

=
void Indexes::add_indexing_notation(compiled_documentation *cd, text_stream *L, text_stream *R, text_stream *style, text_stream *options) {
	IndexUtilities::add_span_notation(cd, L, R, style, INDEX_TEXT_SPP);
	Indexes::add_category(cd, style, options, NULL);
}

void Indexes::add_indexing_notation_for_symbols(compiled_documentation *cd, text_stream *L, text_stream *style, text_stream *options) {
	IndexUtilities::add_span_notation(cd, L, NULL, style, INDEX_SYMBOLS_SPP);
	Indexes::add_category(cd, style, options, NULL);
}

void Indexes::add_indexing_notation_for_definitions(compiled_documentation *cd, text_stream *style, text_stream *options, text_stream *subdef) {
	TEMPORARY_TEXT(key)
	WRITE_TO(key, "!%S", subdef);
	if (Str::len(subdef) > 0) WRITE_TO(key, "-");
	WRITE_TO(key, "definition");
	Indexes::add_category(cd, style, options, key);
	DISCARD_TEXT(key)
}

void Indexes::add_indexing_notation_for_examples(compiled_documentation *cd, text_stream *style, text_stream *options) {
	Indexes::add_category(cd, style, options, I"!example");
}

typedef struct cd_indexing_data {
	int present_with_index;
	struct linked_list *notations; /* of |span_notation| */
	struct dictionary *categories_by_name; /* to |indexing_category| */
	struct dictionary *categories_redirect; /* to text */
	struct dictionary *lemmas; /* to |index_lemma| */
	struct linked_list *lemma_list; /* of |index_lemma| */
} cd_indexing_data;

cd_indexing_data Indexes::new_indexing_data(void) {
	cd_indexing_data id;
	id.present_with_index = FALSE;
	id.notations = NEW_LINKED_LIST(span_notation);
	id.categories_by_name = Dictionaries::new(25, FALSE);
	id.categories_redirect = Dictionaries::new(25, TRUE);
	id.lemmas = Dictionaries::new(100, FALSE);
	id.lemma_list = NEW_LINKED_LIST(index_lemma);
	return id;
}

int Indexes::indexing_occurred(compiled_documentation *cd) {
	return cd->id.present_with_index;
}

@h Categories.
Categories can be looked up by name (which correspond to CSS class name),
and turn out to have a lot of fiddly options added.

=
typedef struct indexing_category {
	struct text_stream *cat_name;
	struct text_stream *cat_glossed; /* if set, print the style as a gloss */
	int cat_inverted; /* if set, apply name inversion */
	struct text_stream *cat_prefix; /* if set, prefix to entries */
	struct text_stream *cat_suffix; /* if set, suffix to entries */
	int cat_bracketed; /* if set, apply style to bracketed matter */
	int cat_unbracketed; /* if set, also prune brackets */
	int cat_usage; /* for counting headwords */
	struct text_stream *cat_under; /* for automatic subentries */
	int cat_alsounder; /* for automatic subentries */
	CLASS_DEFINITION
} indexing_category;

dictionary *categories_by_name = NULL;
dictionary *categories_redirect = NULL; /* for the built-in categories only */

@ Every new style goes into the name dictionary:

=
void Indexes::add_category(compiled_documentation *cd, text_stream *name, text_stream *options, text_stream *redirect) {
	if (Str::len(redirect) > 0) @<This is a redirection@>;
	if (Dictionaries::find(cd->id.categories_by_name, name) == NULL) {
		indexing_category *ic = CREATE(indexing_category);
		Dictionaries::create(cd->id.categories_by_name, name);
		Dictionaries::write_value(cd->id.categories_by_name, name, ic);
		@<Work out the fiddly details@>;
	}
}

@ When we want to say "use my new category X instead of the built-in category
Y", we use the redirection dictionary. Here |redirect| is Y, and |name| is X.

@<This is a redirection@> =
	text_stream *val = Dictionaries::create_text(cd->id.categories_redirect, redirect);
	Str::copy(val, name);

@ There's a whole little mini-language for how to express details of our
category:

@<Work out the fiddly details@> =
	ic->cat_name = Str::duplicate(name);
	match_results mr = Regexp::create_mr();
	ic->cat_glossed = Str::new();
	if (Regexp::match(&mr, options, L"(%c*?) *%(\"(%c*?)\"%) *(%c*)")) {
		ic->cat_glossed = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_prefix = Str::new();
	if (Regexp::match(&mr, options, L"(%c*?) *%(prefix \"(%c*?)\"%) *(%c*)")) {
		ic->cat_prefix = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_suffix = Str::new();
	if (Regexp::match(&mr, options, L"(%c*?) *%(suffix \"(%c*?)\"%) *(%c*)")) {
		ic->cat_suffix = Str::duplicate(mr.exp[1]);
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
	}
	ic->cat_under = Str::new();
	if (Regexp::match(&mr, options, L"(%c*?) *%(under {(%c*?)}%) *(%c*)")) {
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
		ic->cat_under = Str::duplicate(mr.exp[1]);
	}
	ic->cat_alsounder = FALSE;
	if (Regexp::match(&mr, options, L"(%c*?) *%(also under {(%c*?)}%) *(%c*)")) {
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[2]);
		ic->cat_under = Str::duplicate(mr.exp[1]);
		ic->cat_alsounder = TRUE;
	}
	ic->cat_inverted = FALSE;
	if (Regexp::match(&mr, options, L"(%c*?) *%(invert%) *(%c*)")) {
		ic->cat_inverted = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	ic->cat_bracketed = FALSE;
	if (Regexp::match(&mr, options, L"(%c*?) *%(bracketed%) *(%c*)")) {
		ic->cat_bracketed = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	ic->cat_unbracketed = FALSE;
	if (Regexp::match(&mr, options, L"(%c*?) *%(unbracketed%) *(%c*)")) {
		ic->cat_bracketed = TRUE;
		ic->cat_unbracketed = TRUE;
		Str::clear(options); WRITE_TO(options, "%S%S", mr.exp[0], mr.exp[1]);
	}
	if (Regexp::match(NULL, options, L"%c*?%C%c*"))
		Errors::with_text("Unknown notation options: %S", options);
	ic->cat_usage = 0;
	Regexp::dispose_of(&mr);

@ The following looks slow, but in fact there's no problem in practice.

=
void Indexes::scan(compiled_documentation *cd) {
	markdown_item *latest = cd->markdown_content;
	int volume_number = -1;
	Indexes::scan_r(cd, cd->markdown_content, &latest, NULL, &volume_number);
	volume_number = -1;
	IFM_example *E;
	LOOP_OVER_LINKED_LIST(E, IFM_example, cd->examples)
		Indexes::scan_r(cd, E->header, NULL, E, &volume_number);
	if (LinkedLists::len(cd->id.lemma_list) > 0) cd->id.present_with_index = TRUE;
	LOOP_OVER_LINKED_LIST(E, IFM_example, cd->examples) {
		TEMPORARY_TEXT(term)
		Indexes::extract_from_indexable_matter(term, cd, Str::duplicate(E->name));
		Indexes::mark_index_term(cd, term, 0, NULL, E->URL, E, NULL, NULL, 1);
		if (Str::len(E->ex_index) > 0) {
			Str::clear(term);
			Indexes::extract_from_indexable_matter(term, cd, Str::duplicate(E->ex_index));
			Indexes::mark_index_term(cd, term, 0, NULL, E->URL, E, NULL, NULL, 2);
		}
		DISCARD_TEXT(term)
	}
}

void Indexes::scan_r(compiled_documentation *cd, markdown_item *md, markdown_item **latest,
	IFM_example *E, int *volume_number) {
	if (md) {
		if (md->type == VOLUME_MIT) (*volume_number)++;
		if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) <= 2)) {
			if (latest) *latest = md;
		}
		if (md->type == INDEX_MARKER_MIT) {
			Indexes::scan_indexingnotations(cd, md, md->details, md->stashed, *volume_number,
				(latest)?(*latest):NULL, E);
		}
	}
	for (markdown_item *ch = md->down; ch; ch=ch->next)
		Indexes::scan_r(cd, ch, latest, E, volume_number);
}

void Indexes::scan_indexingnotations(compiled_documentation *cd, markdown_item *md,
	int carets, text_stream *term_to_index, int V, markdown_item *S, IFM_example *E) {
	match_results mr = Regexp::create_mr();
	TEMPORARY_TEXT(see)
	TEMPORARY_TEXT(alphabetise_as)
	if (Regexp::match(&mr, term_to_index, L"(%c+?) *<-- *(%c+) *")) {
		Str::copy(term_to_index, mr.exp[0]); Str::copy(see, mr.exp[1]);
	}
	if (Regexp::match(&mr, term_to_index, L"(%c+?) *--> *(%c+) *")) {
		Str::copy(term_to_index, mr.exp[0]); Str::copy(alphabetise_as, mr.exp[1]);
	}
	TEMPORARY_TEXT(lemma)
	Indexes::extract_from_indexable_matter(lemma, cd, term_to_index);

	if ((V > 0) && (E)) {
		V = 0; S = NULL; E = NULL;
	}
	if (carets < 3) {
		Indexes::mark_index_term(cd, lemma, V, S, NULL, E, NULL, alphabetise_as, FALSE);
	} else {
		Indexes::note_index_term_alphabetisation(cd, lemma, alphabetise_as);
	}

	TEMPORARY_TEXT(smoke_test_text)
	Indexes::process_category_options(smoke_test_text, cd, lemma, TRUE, 1);

	while (Regexp::match(&mr, see, L" *(%c+) *<-- *(%c+?) *")) {
		Str::copy(see, mr.exp[0]);
		TEMPORARY_TEXT(seethis)
		Indexes::extract_from_indexable_matter(seethis, cd, mr.exp[1]);
		Indexes::mark_index_term(cd, seethis, -1, NULL, NULL, NULL, lemma, NULL, FALSE);
		WRITE_TO(smoke_test_text, " <-- ");
		Indexes::process_category_options(smoke_test_text, cd, seethis, TRUE, 2);
		DISCARD_TEXT(seethis)
	}
	if (Str::len(see) > 0) {
		TEMPORARY_TEXT(seethis)
		Indexes::extract_from_indexable_matter(seethis, cd, see);
		Indexes::mark_index_term(cd, seethis, -1, NULL, NULL, NULL, lemma, NULL, FALSE);
		WRITE_TO(smoke_test_text, " <-- ");
		Indexes::process_category_options(smoke_test_text, cd, seethis, TRUE, 3);
		DISCARD_TEXT(seethis)
	}
	if (indoc_settings_test_index_mode) {
		Regexp::replace(smoke_test_text, L"=___=standard", L"", REP_REPEATING);
		Regexp::replace(smoke_test_text, L"=___=(%C+)", L" %(%0%)", REP_REPEATING);
		Regexp::replace(smoke_test_text, L":", L": ", REP_REPEATING);
		md->type = PLAIN_MIT;
		md->sliced_from = Str::duplicate(smoke_test_text);
		md->from = 0; md->to = Str::len(smoke_test_text) - 1;
	}
	DISCARD_TEXT(lemma)
	DISCARD_TEXT(see)
	DISCARD_TEXT(alphabetise_as)
	DISCARD_TEXT(smoke_test_text)
	Regexp::dispose_of(&mr);
}

void Indexes::extract_from_indexable_matter(OUTPUT_STREAM, compiled_documentation *cd, text_stream *text) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L" *(%c+?) *: *(%c+) *")) {
		text_stream *head = mr.exp[0];
		text_stream *tail = mr.exp[1];
		Indexes::extract_from_indexable_matter(OUT, cd, head);
		WRITE(":");
		Indexes::extract_from_indexable_matter(OUT, cd, tail);
		Regexp::dispose_of(&mr);
		return;
	}
	TEMPORARY_TEXT(trimmed)
	Str::copy(trimmed, text);
	Str::trim_white_space(trimmed);
	int claimed = FALSE;
	span_notation *SN;
	LOOP_OVER_LINKED_LIST(SN, span_notation, cd->id.notations)
		if (SN->sp_purpose == INDEX_TEXT_SPP)
			if (Str::begins_with_wide_string(trimmed, SN->sp_left))
				if (Str::ends_with_wide_string(trimmed, SN->sp_right)) {
					for (int j=SN->sp_left_len, L=Str::len(trimmed); j<L-SN->sp_right_len; j++)
						PUT(Str::get_at(trimmed, j));
					WRITE("=___=%S", SN->sp_style);
					claimed = TRUE; break;
				}
	DISCARD_TEXT(trimmed)
	Regexp::dispose_of(&mr);
	if (claimed == FALSE) {
		WRITE("%S=___=standard", text); /* last resort */
	}
}

@ =
void Indexes::index_notify_of_symbol(compiled_documentation *cd, text_stream *symbol, int V, markdown_item *S) {
	span_notation *SN;
	LOOP_OVER_LINKED_LIST(SN, span_notation, cd->id.notations)
		if (SN->sp_purpose == INDEX_SYMBOLS_SPP) {
			if (Str::begins_with_wide_string(symbol, SN->sp_left)) {
				TEMPORARY_TEXT(term)
				Str::copy(term, S->stashed);
				LOOP_THROUGH_TEXT(pos, term)
					Str::put(pos, Characters::tolower(Str::get(pos)));
				WRITE_TO(term, "=___=%S", SN->sp_style);
				Indexes::mark_index_term(cd, term, V, S, NULL, NULL, NULL, NULL, FALSE);
				DISCARD_TEXT(term)
			}
		}
}

@ =
void Indexes::mark_index_term(compiled_documentation *cd, text_stream *given_term, int V, markdown_item *S,
	text_stream *anchor, IFM_example *E, text_stream *see, text_stream *alphabetise_as,
	int example_index_status) {
	TEMPORARY_TEXT(term)
	Indexes::process_category_options(term, cd, given_term, TRUE, 4);
	if ((Regexp::match(NULL, term, L"IGNORE=___=ME%c*")) ||
		(Regexp::match(NULL, term, L"%c*:IGNORE=___=ME%c*"))) return;
	if (Str::len(alphabetise_as) > 0)
		IndexUtilities::alphabetisation_exception(term, alphabetise_as);
	Indexes::ensure_lemmas_exist(cd, term, example_index_status);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, term, L"%c*=___=([^_]+?)")) {
		text_stream *category = mr.exp[0];
		if (Dictionaries::find(cd->id.categories_by_name, category)) {
			indexing_category *ic = (indexing_category *)
				Dictionaries::read_value(cd->id.categories_by_name, category);
			Regexp::dispose_of(&mr);
			if ((ic) && (ic->cat_alsounder == TRUE)) {
				TEMPORARY_TEXT(processed_term)
				Indexes::process_category_options(processed_term, cd, given_term, FALSE, 5);
				if ((Regexp::match(NULL, processed_term, L"IGNORE=___=ME%c*")) ||
					(Regexp::match(NULL, processed_term, L"%c*:IGNORE=___=ME%c*"))) return;
				Indexes::ensure_lemmas_exist(cd, processed_term, example_index_status);
				Indexes::set_index_point(cd, processed_term, V, S, anchor, E, see,
					example_index_status);
				DISCARD_TEXT(processed_term)
			}
		}
	}
	Indexes::set_index_point(cd, term, V, S, anchor, E, see, example_index_status);
	DISCARD_TEXT(term)
}

@ =
typedef struct index_lemma {
	struct text_stream *term; /* text of lemma */
	struct linked_list *index_points; /* of |index_reference| */
	struct text_stream *index_see; /* |<--|-separated list of refs */
	struct text_stream *sorting_key; /* final reading order is alphabetic on this */
	int example_index_status; /* as well as in the general index */
	CLASS_DEFINITION
} index_lemma;

typedef struct index_reference {
	int volume;
	struct IFM_example *example;
	struct markdown_item *section;
	struct text_stream *anchor;
	CLASS_DEFINITION
} index_reference;

void Indexes::ensure_lemmas_exist(compiled_documentation *cd, text_stream *text,
	int example_index_status) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L" *(%c+) *: *(%c+?) *"))
		Indexes::ensure_lemmas_exist(cd, mr.exp[0], example_index_status);
	Regexp::dispose_of(&mr);
	if (Dictionaries::find(cd->id.lemmas, text) == NULL) {
		TEMPORARY_TEXT(copied)
		Str::copy(copied, text);
		Indexes::set_index_point(cd, copied, -1, NULL, NULL, NULL, NULL, example_index_status);
		DISCARD_TEXT(copied)
	}
}

void Indexes::set_index_point(compiled_documentation *cd, text_stream *term, int V, markdown_item *S,
	text_stream *anchor, IFM_example *E, text_stream *see, int example_index_status) {
	index_lemma *il = NULL;
	if (Dictionaries::find(cd->id.lemmas, term)) {
		il = (index_lemma *) Dictionaries::read_value(cd->id.lemmas, term);
	} else {
		Dictionaries::create(cd->id.lemmas, term);
		il = CREATE(index_lemma);
		il->term = Str::duplicate(term);
		il->index_points = NEW_LINKED_LIST(index_reference);
		il->index_see = Str::new();
		il->sorting_key = Str::new();
		il->example_index_status = example_index_status;
		Dictionaries::write_value(cd->id.lemmas, term, il);
		ADD_TO_LINKED_LIST(il, index_lemma, cd->id.lemma_list);
	}
	if ((V >= 0) && ((E) || (S))) {
		index_reference *ref = CREATE(index_reference);
		ref->volume = V;
		ref->example = E;
		ref->section = S;
		ref->anchor = Str::duplicate(anchor);
		ADD_TO_LINKED_LIST(ref, index_reference, il->index_points);
	}
	if (Str::len(see) > 0) WRITE_TO(il->index_see, "%S<--", see);
}


@ =
void Indexes::note_index_term_alphabetisation(compiled_documentation *cd,
	text_stream *term, text_stream *alphabetise_as) {
	TEMPORARY_TEXT(processed_term)
	Indexes::process_category_options(processed_term, cd, term, TRUE, 6);
	IndexUtilities::alphabetisation_exception(processed_term, alphabetise_as);
	DISCARD_TEXT(processed_term)
}

void Indexes::process_category_options(OUTPUT_STREAM, compiled_documentation *cd,
	text_stream *text, int allow_under, int n) {
	match_results mr = Regexp::create_mr();
	@<Break the text down into a colon-separated list of categories and process each@>;
	if (Regexp::match(&mr, text, L"(%c*)=___=(%c*)")) {
		text_stream *lemma = mr.exp[0];
		text_stream *category = mr.exp[1];
		@<Redirect category names starting with an exclamation@>;
		@<Amend the lemma or category as necessary@>;
		WRITE("%S=___=%S", lemma, category);
	} else {
		Errors::with_text("bad indexing term: %S", text);
		WRITE("IGNORE=___=ME");
	}
	Regexp::dispose_of(&mr);
}

@<Break the text down into a colon-separated list of categories and process each@> =
	if (Regexp::match(&mr, text, L" *(%c+?) *: *(%c+)")) {
		Indexes::process_category_options(OUT, cd, mr.exp[0], TRUE, 7);
		WRITE(":");
		Indexes::process_category_options(OUT, cd, mr.exp[1], allow_under, 8);
		Regexp::dispose_of(&mr);
		return;
	}

@ A category beginning |!| is either redirected to a regular category, or
else suppressed as unwanted (because the user didn't set up a redirection).

@<Redirect category names starting with an exclamation@> =
	if (Str::get_first_char(category) == '!') {
		text_stream *redirected =
			Dictionaries::get_text(cd->id.categories_redirect, category);
		if (Str::len(redirected) > 0) Str::copy(category, redirected);
		else {
			Regexp::dispose_of(&mr);
			WRITE("IGNORE=___=ME");
			return;
		}
	}

@<Amend the lemma or category as necessary@> =
	if (Dictionaries::find(cd->id.categories_by_name, category)) {
		indexing_category *ic = (indexing_category *)
			Dictionaries::read_value(cd->id.categories_by_name, category);
		if (ic) {
			@<Perform name inversion as necessary@>;
			@<Prefix and suffix as necessary@>;
			@<Automatically file under a headword as necessary@>;
		}
	}

@ This inverts "Sir Robert Cecil" to "Cecil, Sir Robert", but leaves
"Mary, Queen of Scots" alone.

@<Perform name inversion as necessary@> =
	if ((ic->cat_inverted) && (Regexp::match(NULL, lemma, L"%c*,%c*") == FALSE)) {
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, lemma, L"(%c*?) (%C+) *")) {
			Str::clear(lemma);
			WRITE_TO(lemma, "%S, %S", mr.exp[1], mr.exp[0]);
		}
		Regexp::dispose_of(&mr);
	}

@ This, for example, could append "(monarch)" to the name of every lemma
in the category "royalty", so that "James I" becomes "James I (monarch)".

@<Prefix and suffix as necessary@> =
	TEMPORARY_TEXT(rewritten)
	WRITE_TO(rewritten, "%S%S%S", ic->cat_prefix, lemma, ic->cat_suffix);
	Str::copy(lemma, rewritten);
	DISCARD_TEXT(rewritten)

@ And this could automatically reroute the lemma so that it appears as
a subentry under the category's choice of headword: e.g., "James I"
might be placed as as a subentry of "Kings".

@<Automatically file under a headword as necessary@> =
	if ((allow_under) && (Str::len(ic->cat_under) > 0)) {
		TEMPORARY_TEXT(extracted)
		TEMPORARY_TEXT(icu)
		TEMPORARY_TEXT(old_lemma)
		Str::copy(old_lemma, lemma);

		Indexes::extract_from_indexable_matter(extracted, cd, ic->cat_under);
		Indexes::process_category_options(icu, cd, extracted, FALSE, 9);
		Str::clear(lemma);
		WRITE_TO(lemma, "%S:%S", icu, old_lemma);

		DISCARD_TEXT(extracted)
		DISCARD_TEXT(old_lemma)
		DISCARD_TEXT(icu)
	}

@h Rendering.
Having accumulated the lemmas, it's time to sort them and write the index
as it will be seen by the reader.

=
void Indexes::write_example_index(OUTPUT_STREAM, compiled_documentation *cd) {
	Indexes::write_general_index_inner(OUT, cd, TRUE);
}

void Indexes::write_general_index(OUTPUT_STREAM, compiled_documentation *cd) {
	Indexes::write_general_index_inner(OUT, cd, FALSE);
}

void Indexes::write_general_index_inner(OUTPUT_STREAM, compiled_documentation *cd,
	int just_examples) {
	HTML_OPEN_WITH("div", "class=\"generalindex\"");
	@<Construct sorting keys for the lemmas@>;
	int NL = LinkedLists::len(cd->id.lemma_list);
	index_lemma **lemma_list =
		Memory::calloc(NL, sizeof(index_lemma *), ARRAY_SORTING_MREASON);
	index_lemma *il; int i=0;
	LOOP_OVER_LINKED_LIST(il, index_lemma, cd->id.lemma_list) lemma_list[i++] = il;
	qsort(lemma_list, (size_t) NL, sizeof(index_lemma *), Indexes::sort_comparison);
	@<Render the index in sorted order@>;
	@<Give feedback in index testing mode@>;
	Memory::I7_free(lemma_list, ARRAY_SORTING_MREASON, NL*((int) sizeof(index_lemma *)));
	HTML_CLOSE("div");
}

int Indexes::sort_comparison(const void *ent1, const void *ent2) {
	const index_lemma *L1 = *((const index_lemma **) ent1);
	const index_lemma *L2 = *((const index_lemma **) ent2);
	return Str::cmp(L1->sorting_key, L2->sorting_key);
}

@<Construct sorting keys for the lemmas@> =
	index_lemma *il;
	LOOP_OVER_LINKED_LIST(il, index_lemma, cd->id.lemma_list) {
		TEMPORARY_TEXT(sort_key)
		Str::copy(sort_key, il->term);

		/* ensure subentries follow main entries */
		Regexp::replace(sort_key, L": *", L"ZZZZZZZZZZZZZZZZZZZZZZ", REP_REPEATING);
		IndexUtilities::improve_alphabetisation(sort_key);

		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, sort_key, L"a/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);
		if (Regexp::match(&mr, sort_key, L"the/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);

		if (indoc_settings_index_alphabetisation_algorithm == WORD_ALPHABETIZATION)
			Regexp::replace(sort_key, L" ", L"aaaaaaaaaaaaaaaaaaaaaa", REP_REPEATING);

		TEMPORARY_TEXT(un)
		Str::copy(un, sort_key);
		Regexp::replace(un, L"%(%c*?%)", NULL, REP_REPEATING);
		Regexp::replace(un, L" ", NULL, REP_REPEATING);
		Regexp::replace(un, L",", NULL, REP_REPEATING);
		int f = ' ';
		if (Characters::isalpha(Str::get_first_char(sort_key)))
			f = Str::get_first_char(sort_key);
		WRITE_TO(il->sorting_key, "%c_%S=___=%S=___=%07d",
			f, un, sort_key, il->allocation_id);
		DISCARD_TEXT(un)
		DISCARD_TEXT(sort_key)
		Regexp::dispose_of(&mr);
	}

@<Render the index in sorted order@> =
	IndexUtilities::alphabet_row(OUT, 1);
	HTML_OPEN_WITH("table", "class=\"indextable\"");
	wchar_t current_incipit = 0;
	for (int i=0; i<NL; i++) {
		index_lemma *il = lemma_list[i];
		if ((just_examples) && (il->example_index_status == 0)) continue;
		wchar_t incipit = Str::get_first_char(il->sorting_key);
		if (Characters::isalpha(incipit)) incipit = Characters::toupper(incipit);
		else incipit = '#';
		if (incipit != current_incipit) {
			if (current_incipit != 0) @<End a block of the index@>;
			current_incipit = incipit;
			IndexUtilities::note_letter(current_incipit);
			@<Start a block of the index@>;
		}
		@<Render an index entry@>;
	}
	if (current_incipit != 0) @<End a block of the index@>;
	HTML_CLOSE("table");
	IndexUtilities::alphabet_row(OUT, 2);

@<Start a block of the index@> =
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"letterblock\"");
	TEMPORARY_TEXT(inc)
	if (current_incipit == '#') WRITE_TO(inc, "NN");
	else PUT_TO(inc, current_incipit);
	HTML::anchor(OUT, inc);
	IndexUtilities::majuscule_heading(OUT, inc, TRUE);
	DISCARD_TEXT(inc)
	HTML_CLOSE("td");
	HTML_OPEN("td");

@<End a block of the index@> =
	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Render an index entry@> =
	TEMPORARY_TEXT(anc)
	int A = il->allocation_id;
	WRITE_TO(anc, "l%d", A);
	HTML::anchor(OUT, anc);
	DISCARD_TEXT(anc)

	TEMPORARY_TEXT(term)
	TEMPORARY_TEXT(category)
	match_results mr = Regexp::create_mr();
	Str::copy(term, il->term);
	if (Regexp::match(&mr, term, L"(%c*)=___=(%c*)")) {
		Str::copy(term, mr.exp[0]);
		Str::copy(category, mr.exp[1]);
	}
	indexing_category *ic = NULL;
	if (Dictionaries::find(cd->id.categories_by_name, category) == NULL) {
		if (Str::eq_insensitive(category, I"standard") == FALSE)
			PRINT("Warning: no such indexing category as '%S'\n", category);
	} else {
		ic = Dictionaries::read_value(cd->id.categories_by_name, category);
		ic->cat_usage++;

		int indent_level = 0;
		TEMPORARY_TEXT(lemma_wording)
		@<Work out the wording and indentation level@>;

		TEMPORARY_TEXT(details)
		WRITE_TO(details, "class=\"indexentry\" style=\"margin-left: %dem;\"", 4*indent_level);
		HTML::open(OUT, "p", details, __FILE__, __LINE__);
		DISCARD_TEXT(details)
		@<Render the lemma text@>;
		@<Render the category gloss@>;
		WRITE("&nbsp;&nbsp;");
		int lc = 0;
		@<Render the list of index points@>;
		@<Render the list of see-references@>;
		HTML_CLOSE("p");
		Regexp::dispose_of(&mr);
	}

@

@d SAVED_OPEN_BRACKET 0x0086  /* Unicode "start of selected area" */
@d SAVED_CLOSE_BRACKET 0x0087 /* Unicode "end of selected area" */

@<Work out the wording and indentation level@> =
	TEMPORARY_TEXT(untreated)
	Str::copy(untreated, term);
	while (Regexp::match(&mr, untreated, L"%c*?: *(%c+)")) {
		Str::copy(untreated, mr.exp[0]); indent_level++;
	}
	IndexUtilities::escape_HTML_characters_in(untreated);
	for (int i=0, L = Str::len(untreated); i<L; i++) {
		int c = Str::get_at(untreated, i);
		if (c == '\\') {
			int n = 0, d = 0, id = 0;
			while (Characters::isdigit(id = Str::get_at(untreated, i+1))) {
				i++, d++; n = n*10 + (id - '0');
			}
			if (n == 0) n = Str::get_at(untreated, ++i);
			if (n == '(') n = SAVED_OPEN_BRACKET;
			if (n == ')') n = SAVED_CLOSE_BRACKET;
			PUT_TO(lemma_wording, n);
		} else PUT_TO(lemma_wording, c);
	}

	if (ic->cat_bracketed) {
		while (Regexp::match(&mr, lemma_wording, L"(%c*?)%((%c*?)%)(%c*)")) {
			Str::clear(lemma_wording);
			WRITE_TO(lemma_wording,
				"%S<span class=\"index%Sbracketed\">___openb___%S___closeb___</span>%S",
				mr.exp[0], category, mr.exp[1], mr.exp[2]);
		}
		if (ic->cat_unbracketed) {
			Regexp::replace(lemma_wording, L"___openb___", NULL, REP_REPEATING);
			Regexp::replace(lemma_wording, L"___closeb___", NULL, REP_REPEATING);
		} else {
			Regexp::replace(lemma_wording, L"___openb___", L"(", REP_REPEATING);
			Regexp::replace(lemma_wording, L"___closeb___", L")", REP_REPEATING);
		}
	}

	LOOP_THROUGH_TEXT(pos, lemma_wording) {
		int d = Str::get(pos);
		if (d == SAVED_OPEN_BRACKET) Str::put(pos, '(');
		if (d == SAVED_CLOSE_BRACKET) Str::put(pos, ')');
	}

@<Render the lemma text@> =
	if (il->example_index_status == 1) HTML_OPEN("b");
	WRITE("<span class=\"index%S\">", category);
	WRITE("%S", lemma_wording);
	HTML_CLOSE("span");
	if (il->example_index_status == 1) HTML_CLOSE("b");

@<Render the category gloss@> =
	if (Str::len(ic->cat_glossed) > 0)
		WRITE("&nbsp;<span class=\"indexgloss\">%S</span>", ic->cat_glossed);

@<Render the list of index points@> =
	index_reference *ref;
	LOOP_OVER_LINKED_LIST(ref, index_reference, il->index_points) {
		if (lc++ > 0) WRITE(", ");

		int volume_number = ref->volume;
		markdown_item *S = ref->section;

		IFM_example *E = ref->example;
		if ((E) && (S == NULL)) S = E->cue;
		if ((S == NULL) && (E == NULL))
			internal_error("unknown destination in index reference");

		text_stream *link_class = I"indexlink";
		if (volume_number > 0) link_class = I"indexlinkalt";
		TEMPORARY_TEXT(link)
		text_stream *A = ref->anchor;
		if (S) {
			for (int i=0; i<Str::len(S->stashed); i++) {
				wchar_t c = Str::get_at(S->stashed, i);
				if (c == ':') break;
				if ((Characters::isdigit(c)) || (c == '.')) PUT_TO(link, c);
			}
			A = MarkdownVariations::URL_for_heading(S);
		}
		if (E) {
			if (S) WRITE_TO(link, " ");
			WRITE_TO(link, "ex %S", E->insignia);
			A = E->URL;
		}
		if (Str::len(A) == 0) { LOG("Alert! No anchor for %S\n", link); }
		IndexUtilities::general_link(OUT, link_class, A, link);
		DISCARD_TEXT(link)
	}

@<Render the list of see-references@> =
	TEMPORARY_TEXT(seelist)
	Str::copy(seelist, il->index_see);
	int sc = 0;
	if (Str::len(seelist) > 0) {
		if (lc > 0) WRITE("; ");
		HTML_OPEN_WITH("span", "class=\"indexsee\"");
		WRITE("see ");
		if (lc > 0) WRITE("also ");
		HTML_CLOSE("span");
		match_results mr2 = Regexp::create_mr();
		while (Regexp::match(&mr2, seelist, L"(%c*?) *<-- *(%c*)")) {
			if (sc++ > 0) { WRITE("; "); }

			text_stream *see = mr2.exp[0];
			Str::copy(seelist, mr2.exp[1]);
			index_lemma *ils = (index_lemma *) Dictionaries::read_value(cd->id.lemmas, see);
			TEMPORARY_TEXT(url)
			WRITE_TO(url, "#l%d", ils->allocation_id);
			Regexp::replace(see, L"=___=%i+?:", L":", REP_REPEATING);
			Regexp::replace(see, L"=___=%i+", NULL, REP_REPEATING);
			Regexp::replace(see, L":", L": ", REP_REPEATING);
			IndexUtilities::general_link(OUT, I"indexseelink", url, see);
			DISCARD_TEXT(url)
		}
		Regexp::dispose_of(&mr2);
	}

@<Give feedback in index testing mode@> =
	if (indoc_settings_test_index_mode) {
		PRINT("indoc ran in index test mode: do not publish typeset documentation.\n");
		int t = 0;
		indexing_category *ic;
		LOOP_OVER(ic, indexing_category) {
			PRINT("%S: %d headword(s)\n", ic->cat_name, ic->cat_usage);
			t += ic->cat_usage;
		}
		PRINT("%d headword(s) in all\n", t);
	}

@

=
void Indexes::render_eg_index(OUTPUT_STREAM, markdown_item *md) {
	markdown_item *pending_chapter = NULL, *pending_section = NULL;
	if (md) Indexes::render_eg_index_r(OUT, md, &pending_chapter, &pending_section);
}

void Indexes::render_eg_index_r(OUTPUT_STREAM, markdown_item *md,
	markdown_item **pending_chapter, markdown_item **pending_section) {
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 1)) {
		*pending_chapter = md;
		*pending_section = NULL;
	}
	if ((md->type == HEADING_MIT) && (Markdown::get_heading_level(md) == 2)) {
		*pending_section = md;
	}
	if (md->type == INFORM_EXAMPLE_HEADING_MIT) {
		if (*pending_chapter) {
			Markdown::render_extended(OUT, *pending_chapter, InformFlavouredMarkdown::variation());
			*pending_chapter = NULL;
		}
		if (*pending_section) {
			Markdown::render_extended(OUT, *pending_section, InformFlavouredMarkdown::variation());
			*pending_section = NULL;
		}
		Markdown::render_extended(OUT, md, InformFlavouredMarkdown::variation());
	}
	for (markdown_item *ch = md->down; ch; ch = ch->next)
		Indexes::render_eg_index_r(OUT, ch, pending_chapter, pending_section);
}
