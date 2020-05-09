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
void Indexes::add_indexing_notation(text_stream *L, text_stream *R, text_stream *style, text_stream *options) {
	CSS::add_span_notation(L, R, style, INDEX_TEXT_SPP);
	Indexes::add_category(style, options, NULL);
}

void Indexes::add_indexing_notation_for_symbols(text_stream *L, text_stream *style, text_stream *options) {
	CSS::add_span_notation(L, NULL, style, INDEX_SYMBOLS_SPP);
	Indexes::add_category(style, options, NULL);
}

void Indexes::add_indexing_notation_for_definitions(text_stream *style, text_stream *options, text_stream *subdef) {
	TEMPORARY_TEXT(key);
	WRITE_TO(key, "!%S", subdef);
	if (Str::len(subdef) > 0) WRITE_TO(key, "-");
	WRITE_TO(key, "definition");
	Indexes::add_category(style, options, key);
	DISCARD_TEXT(key);
}

void Indexes::add_indexing_notation_for_examples(text_stream *style, text_stream *options) {
	Indexes::add_category(style, options, I"!example");
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
void Indexes::add_category(text_stream *name, text_stream *options, text_stream *redirect) {
	if (redirect) @<This is a redirection@>;

	indexing_category *ic = CREATE(indexing_category);
	if (categories_by_name == NULL)
		categories_by_name = Dictionaries::new(25, FALSE);
	Dictionaries::create(categories_by_name, name);
	Dictionaries::write_value(categories_by_name, name, ic);
	@<Work out the fiddly details@>;
}

@ When we want to say "use my new category X instead of the built-in category
Y", we use the redirection dictionary. Here |redirect| is Y, and |name| is X.

@<This is a redirection@> =
	if (categories_redirect == NULL) categories_redirect = Dictionaries::new(10, TRUE);
	text_stream *val = Dictionaries::create_text(categories_redirect, redirect);
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
int ito_registered = FALSE; /* used for the smoke test of the index */

void Indexes::scan_indexingnotations(text_stream *text, volume *V, section *S, example *E) {
	match_results outer_mr = Regexp::create_mr();
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&outer_mr, text, L"(%c*?)(%^+){(%c*?)}(%c*)")) {
		text_stream *left = outer_mr.exp[0];
		text_stream *carets = outer_mr.exp[1];
		text_stream *term_to_index = outer_mr.exp[2];
		text_stream *right = outer_mr.exp[3];
		TEMPORARY_TEXT(see);
		TEMPORARY_TEXT(alphabetise_as);
		if (Regexp::match(&mr, term_to_index, L"(%c+?) *<-- *(%c+) *")) {
			Str::copy(term_to_index, mr.exp[0]); Str::copy(see, mr.exp[1]);
		}
		if (Regexp::match(&mr, term_to_index, L"(%c+?) *--> *(%c+) *")) {
			Str::copy(term_to_index, mr.exp[0]); Str::copy(alphabetise_as, mr.exp[1]);
		}
		TEMPORARY_TEXT(lemma);
		Indexes::extract_from_indexable_matter(lemma, term_to_index);

		TEMPORARY_TEXT(midriff);
		Str::copy(midriff, lemma);

		Regexp::replace(midriff, L"%c*: ", NULL, REP_ATSTART);
		Regexp::replace(midriff, L"=___=%C+", NULL, 0);

		if ((V->allocation_id > 0) && (E)) {
			V = NULL; S = NULL; E = NULL;
		}
		if (Str::eq_wide_string(carets, L"^^^") == FALSE) {
			Indexes::mark_index_term(lemma, V, S, NULL, E, NULL, alphabetise_as);
		} else {
			Indexes::note_index_term_alphabetisation(lemma, alphabetise_as);
		}

		TEMPORARY_TEXT(smoke_test_text);
		Indexes::process_category_options(smoke_test_text, lemma, TRUE, 1);

		while (Regexp::match(&mr, see, L" *(%c+) *<-- *(%c+?) *")) {
			Str::copy(see, mr.exp[0]);
			TEMPORARY_TEXT(seethis);
			Indexes::extract_from_indexable_matter(seethis, mr.exp[1]);
			Indexes::mark_index_term(seethis, NULL, NULL, NULL, NULL, lemma, NULL);
			WRITE_TO(smoke_test_text, " <-- ");
			Indexes::process_category_options(smoke_test_text, seethis, TRUE, 2);
			DISCARD_TEXT(seethis);
		}
		if (Str::len(see) > 0) {
			TEMPORARY_TEXT(seethis);
			Indexes::extract_from_indexable_matter(seethis, see);
			Indexes::mark_index_term(seethis, NULL, NULL, NULL, NULL, lemma, NULL);
			WRITE_TO(smoke_test_text, " <-- ");
			Indexes::process_category_options(smoke_test_text, seethis, TRUE, 3);
			DISCARD_TEXT(seethis);
		}
		if (Str::eq_wide_string(carets, L"^") == FALSE) Str::clear(midriff);
		if (indoc_settings->test_index_mode) {
			if (ito_registered == FALSE) {
				ito_registered = TRUE;
				CSS::add_span_notation(
					I"___index_test_on___", I"___index_test_off___", I"smoketest", MARKUP_SPP);
			}
			Regexp::replace(smoke_test_text, L"=___=standard", L"", REP_REPEATING);
			Regexp::replace(smoke_test_text, L"=___=(%C+)", L" %(%0%)", REP_REPEATING);
			Regexp::replace(smoke_test_text, L":", L": ", REP_REPEATING);
			WRITE_TO(midriff, "___index_test_on___%S___index_test_off___", smoke_test_text);
		}
		Str::clear(text);
		WRITE_TO(text, "%S%S%S", left, midriff, right);
	}
	Regexp::dispose_of(&mr);
	Regexp::dispose_of(&outer_mr);
}

void Indexes::extract_from_indexable_matter(OUTPUT_STREAM, text_stream *text) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L" *(%c+?) *: *(%c+) *")) {
		text_stream *head = mr.exp[0];
		text_stream *tail = mr.exp[1];
		Indexes::extract_from_indexable_matter(OUT, head);
		WRITE(":");
		Indexes::extract_from_indexable_matter(OUT, tail);
		Regexp::dispose_of(&mr);
		return;
	}
	TEMPORARY_TEXT(trimmed);
	Str::copy(trimmed, text);
	Str::trim_white_space(trimmed);
	int claimed = FALSE;
	span_notation *SN;
	LOOP_OVER(SN, span_notation)
		if (SN->sp_purpose == INDEX_TEXT_SPP)
			if (Str::begins_with_wide_string(trimmed, SN->sp_left))
				if (Str::ends_with_wide_string(trimmed, SN->sp_right)) {
					for (int j=SN->sp_left_len, L=Str::len(trimmed); j<L-SN->sp_right_len; j++)
						PUT(Str::get_at(trimmed, j));
					WRITE("=___=%S", SN->sp_style);
					claimed = TRUE; break;
				}
	DISCARD_TEXT(trimmed);
	Regexp::dispose_of(&mr);
	if (claimed == FALSE) {
		WRITE("%S=___=standard", text); /* last resort */
	}
}

@ =
void Indexes::index_notify_of_symbol(text_stream *symbol, volume *V, section *S) {
	span_notation *SN;
	LOOP_OVER(SN, span_notation)
		if (SN->sp_purpose == INDEX_SYMBOLS_SPP) {
			if (Str::begins_with_wide_string(symbol, SN->sp_left)) {
				TEMPORARY_TEXT(term);
				Str::copy(term, S->unlabelled_title);
				LOOP_THROUGH_TEXT(pos, term)
					Str::put(pos, Characters::tolower(Str::get(pos)));
				WRITE_TO(term, "=___=%S", SN->sp_style);
				Indexes::mark_index_term(term, V, S, NULL, NULL, NULL, NULL);
				DISCARD_TEXT(term);
			}
		}
}

@ =
void Indexes::mark_index_term(text_stream *given_term, volume *V, section *S,
	text_stream *anchor, example *E, text_stream *see, text_stream *alphabetise_as) {
	TEMPORARY_TEXT(term);
	Indexes::process_category_options(term, given_term, TRUE, 4);
	if ((Regexp::match(NULL, term, L"IGNORE=___=ME%c*")) ||
		(Regexp::match(NULL, term, L"%c*:IGNORE=___=ME%c*"))) return;
	if (Str::len(alphabetise_as) > 0)
		IndexUtilities::alphabetisation_exception(term, alphabetise_as);
	Indexes::ensure_lemmas_exist(term);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, term, L"%c*=___=([^_]+?)")) {
		text_stream *category = mr.exp[0];
		indexing_category *ic = (indexing_category *)
			Dictionaries::read_value(categories_by_name, category);
		Regexp::dispose_of(&mr);
		if (ic->cat_alsounder == TRUE) {
			TEMPORARY_TEXT(processed_term);
			Indexes::process_category_options(processed_term, given_term, FALSE, 5);
			if ((Regexp::match(NULL, processed_term, L"IGNORE=___=ME%c*")) ||
				(Regexp::match(NULL, processed_term, L"%c*:IGNORE=___=ME%c*"))) return;
			Indexes::ensure_lemmas_exist(processed_term);
			Indexes::set_index_point(processed_term, V, S, anchor, E, see);
			DISCARD_TEXT(processed_term);
		}
	}
	Indexes::set_index_point(term, V, S, anchor, E, see);
	DISCARD_TEXT(term);
}

@ =
typedef struct index_lemma {
	struct text_stream *term; /* text of lemma */
	struct text_stream *index_points; /* comma-separated list of refs */
	struct text_stream *index_see; /* |<--|-separated list of refs */
	struct text_stream *sorting_key; /* final reading order is alphabetic on this */
	CLASS_DEFINITION
} index_lemma;

dictionary *index_points_dict = NULL;

void Indexes::ensure_lemmas_exist(text_stream *text) {
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L" *(%c+) *: *(%c+?) *")) {
		Indexes::ensure_lemmas_exist(mr.exp[0]);
		Regexp::dispose_of(&mr);
	}
	if (Dictionaries::find(index_points_dict, text) == NULL) {
		TEMPORARY_TEXT(copied);
		Str::copy(copied, text);
		Indexes::set_index_point(copied, NULL, NULL, NULL, NULL, NULL);
		DISCARD_TEXT(copied);
	}
}

void Indexes::set_index_point(text_stream *term, volume *V, section *S,
	text_stream *anchor, example *E, text_stream *see) {
	index_lemma *il = NULL;
	if (Dictionaries::find(index_points_dict, term)) {
		il = (index_lemma *) Dictionaries::read_value(index_points_dict, term);
	} else {
		if (index_points_dict == NULL) index_points_dict = Dictionaries::new(100, FALSE);
		Dictionaries::create(index_points_dict, term);
		il = CREATE(index_lemma);
		il->term = Str::duplicate(term);
		il->index_points = Str::new();
		il->index_see = Str::new();
		il->sorting_key = Str::new();
		Dictionaries::write_value(index_points_dict, term, il);
	}
	if (V) {
		int section_number = -1;
		if (S) section_number = S->number_within_volume;
		if (E) section_number = 100000 + E->allocation_id;
		if (section_number >= 0)
			WRITE_TO(il->index_points, "%d_%d_%S,", V->allocation_id, section_number, anchor);
	}
	if (Str::len(see) > 0) WRITE_TO(il->index_see, "%S<--", see);

	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, term, L"%c+ *: *(%c+?) *")) {
		Str::copy(term, mr.exp[0]);
		Regexp::dispose_of(&mr);
	}
	Regexp::replace(term, L"=___=%C*", NULL, 0);
}

@ =
void Indexes::note_index_term_alphabetisation(text_stream *term, text_stream *alphabetise_as) {
	TEMPORARY_TEXT(processed_term);
	Indexes::process_category_options(processed_term, term, TRUE, 6);
	IndexUtilities::alphabetisation_exception(processed_term, alphabetise_as);
	DISCARD_TEXT(processed_term);
}

void Indexes::process_category_options(OUTPUT_STREAM, text_stream *text, int allow_under, int n) {
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
		Indexes::process_category_options(OUT, mr.exp[0], TRUE, 7);
		WRITE(":");
		Indexes::process_category_options(OUT, mr.exp[1], allow_under, 8);
		Regexp::dispose_of(&mr);
		return;
	}

@ A category beginning |!| is either redirected to a regular category, or
else suppressed as unwanted (because the user didn't set up a redirection).

@<Redirect category names starting with an exclamation@> =
	if (Str::get_first_char(category) == '!') {
		text_stream *redirected =
			Dictionaries::get_text(categories_redirect, category);
		if (Str::len(redirected) > 0) Str::copy(category, redirected);
		else {
			Regexp::dispose_of(&mr);
			WRITE("IGNORE=___=ME");
			return;
		}
	}

@<Amend the lemma or category as necessary@> =
	indexing_category *ic = (indexing_category *)
		Dictionaries::read_value(categories_by_name, category);
	if (ic) {
		@<Perform name inversion as necessary@>;
		@<Prefix and suffix as necessary@>;
		@<Automatically file under a headword as necessary@>;
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
	TEMPORARY_TEXT(rewritten);
	WRITE_TO(rewritten, "%S%S%S", ic->cat_prefix, lemma, ic->cat_suffix);
	Str::copy(lemma, rewritten);
	DISCARD_TEXT(rewritten);

@ And this could automatically reroute the lemma so that it appears as
a subentry under the category's choice of headword: e.g., "James I"
might be placed as as a subentry of "Kings".

@<Automatically file under a headword as necessary@> =
	if ((allow_under) && (Str::len(ic->cat_under) > 0)) {
		TEMPORARY_TEXT(extracted);
		TEMPORARY_TEXT(icu);
		TEMPORARY_TEXT(old_lemma);
		Str::copy(old_lemma, lemma);

		Indexes::extract_from_indexable_matter(extracted, ic->cat_under);
		Indexes::process_category_options(icu, extracted, FALSE, 9);
		Str::clear(lemma);
		WRITE_TO(lemma, "%S:%S", icu, old_lemma);

		DISCARD_TEXT(extracted);
		DISCARD_TEXT(old_lemma);
		DISCARD_TEXT(icu);
	}

@h Rendering.
Having accumulated the lemmas, it's time to sort them and write the index
as it will be seen by the reader.

=
void Indexes::write_general_index(void) {
	text_stream *OUT = IndexUtilities::open_page(I"General Index", indoc_settings->definitions_index_leafname);
	index_lemma **lemma_list =
		Memory::calloc(NUMBER_CREATED(index_lemma), sizeof(index_lemma *), CLS_SORTING_MREASON);
	index_lemma *il;
	LOOP_OVER(il, index_lemma) lemma_list[il->allocation_id] = il;
	@<Construct sorting keys for the lemmas@>;
	qsort(lemma_list, (size_t) NUMBER_CREATED(index_lemma), sizeof(index_lemma *),
		Indexes::sort_comparison);
	@<Render the index in sorted order@>;
	@<Give feedback in index testing mode@>;
	Memory::I7_free(lemma_list, CLS_SORTING_MREASON,
		NUMBER_CREATED(index_lemma)*((int) sizeof(index_lemma *)));
	IndexUtilities::close_page(OUT);
}

int Indexes::sort_comparison(const void *ent1, const void *ent2) {
	const index_lemma *L1 = *((const index_lemma **) ent1);
	const index_lemma *L2 = *((const index_lemma **) ent2);
	return Str::cmp(L1->sorting_key, L2->sorting_key);
}

@<Construct sorting keys for the lemmas@> =
	index_lemma *il;
	LOOP_OVER(il, index_lemma) {
		TEMPORARY_TEXT(sort_key);
		Str::copy(sort_key, il->term);

		/* ensure subentries follow main entries */
		Regexp::replace(sort_key, L": *", L"ZZZZZZZZZZZZZZZZZZZZZZ", REP_REPEATING);
		IndexUtilities::improve_alphabetisation(sort_key);

		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, sort_key, L"a/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);
		if (Regexp::match(&mr, sort_key, L"the/%C+ (%c*)")) Str::copy(sort_key, mr.exp[0]);

		if (indoc_settings->index_alphabetisation_algorithm == WORD_ALPHABETIZATION)
			Regexp::replace(sort_key, L" ", L"aaaaaaaaaaaaaaaaaaaaaa", REP_REPEATING);

		TEMPORARY_TEXT(un);
		Str::copy(un, sort_key);
		Regexp::replace(un, L"%(%c*?%)", NULL, REP_REPEATING);
		Regexp::replace(un, L" ", NULL, REP_REPEATING);
		Regexp::replace(un, L",", NULL, REP_REPEATING);
		int f = ' ';
		if (Characters::isalpha(Str::get_first_char(sort_key)))
			f = Str::get_first_char(sort_key);
		WRITE_TO(il->sorting_key, "%c_%S=___=%S=___=%07d",
			f, un, sort_key, il->allocation_id);
		DISCARD_TEXT(un);
		DISCARD_TEXT(sort_key);
		Regexp::dispose_of(&mr);
	}

@<Render the index in sorted order@> =
	IndexUtilities::alphabet_row(OUT, 1);
	HTML_OPEN_WITH("table", "class=\"indextable\"");
	int current_incipit = 0;
	for (int i=0; i<NUMBER_CREATED(index_lemma); i++) {
		index_lemma *il = lemma_list[i];
		int incipit = Str::get_first_char(il->sorting_key);
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
	TEMPORARY_TEXT(inc);
	if (current_incipit == '#') WRITE_TO(inc, "NN");
	else PUT_TO(inc, current_incipit);
	HTML::anchor(OUT, inc);
	IndexUtilities::majuscule_heading(OUT, inc, TRUE);
	DISCARD_TEXT(inc);
	HTML_CLOSE("td");
	HTML_OPEN("td");

@<End a block of the index@> =
	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Render an index entry@> =
	TEMPORARY_TEXT(anc);
	int A = il->allocation_id;
	WRITE_TO(anc, "l%d", A);
	HTML::anchor(OUT, anc);
	DISCARD_TEXT(anc);

	TEMPORARY_TEXT(term);
	TEMPORARY_TEXT(category);
	match_results mr = Regexp::create_mr();
	Str::copy(term, il->term);
	if (Regexp::match(&mr, term, L"(%c*)=___=(%c*)")) {
		Str::copy(term, mr.exp[0]);
		Str::copy(category, mr.exp[1]);
	}
	indexing_category *ic = NULL;
	if (Dictionaries::find(categories_by_name, category) == NULL)
		PRINT("Warning: no such indexing category as '%S'\n", category);
	else {
		ic = Dictionaries::read_value(categories_by_name, category);
		ic->cat_usage++;

		int indent_level = 0;
		TEMPORARY_TEXT(lemma_wording);
		@<Work out the wording and indentation level@>;

		TEMPORARY_TEXT(details);
		WRITE_TO(details, "class=\"indexentry\" style=\"margin-left: %dem;\"", 4*indent_level);
		HTML::open(OUT, "p", details);
		DISCARD_TEXT(details);
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
	TEMPORARY_TEXT(untreated);
	Str::copy(untreated, term);
	while (Regexp::match(&mr, untreated, L"%c*?: *(%c+)")) {
		Str::copy(untreated, mr.exp[0]); indent_level++;
	}
	Rawtext::escape_HTML_characters_in(untreated);
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
	WRITE("<span class=\"index%S\">", category);
	WRITE("%S", lemma_wording);
	HTML_CLOSE("span");

@<Render the category gloss@> =
	if (Str::len(ic->cat_glossed) > 0)
		WRITE("&nbsp;<span class=\"indexgloss\">%S</span>", ic->cat_glossed);

@<Render the list of index points@> =
	TEMPORARY_TEXT(elist);
	Str::copy(elist, il->index_points);
	while (Regexp::match(&mr, elist, L"(%c*?)_(%c*?)_(%c*?),(%c*)")) {
		if (lc++ > 0) WRITE(", ");

		int volume_number = Str::atoi(mr.exp[0], 0);
		int section_number = Str::atoi(mr.exp[1], 0);
		TEMPORARY_TEXT(anchor);
		Str::copy(anchor, mr.exp[2]);
		Str::copy(elist, mr.exp[3]);

		TEMPORARY_TEXT(etext);
		if (section_number >= 100000) {
			int eno = section_number-100000;
			example *E = examples[eno];
			section_number = E->example_belongs_to_section[volume_number]->number_within_volume;
			WRITE_TO(etext, " ex %d", E->example_position[0]);
			Str::clear(anchor);
			WRITE_TO(anchor, "e%d", eno);
		}

		section *S = volumes[volume_number]->sections[section_number];
		if (S == NULL) {
			PRINT("Vol %d has no section no %d (goes to %d)\n",
				volume_number, section_number, volumes[volume_number]->vol_section_count);
			internal_error("unknown section");
		}
		TEMPORARY_TEXT(url);
		WRITE_TO(url, "%S", Filenames::get_leafname(S->section_filename));
		if (Str::len(anchor) > 0) WRITE_TO(url, "#%S", anchor);
		text_stream *link_class = I"indexlink";
		if (volume_number > 0) link_class = I"indexlinkalt";
		TEMPORARY_TEXT(link);
		WRITE_TO(link, "%S%S", S->label, etext);
		HTMLUtilities::general_link(OUT, link_class, url, link);
		DISCARD_TEXT(link);
		DISCARD_TEXT(url);
		DISCARD_TEXT(anchor);
		DISCARD_TEXT(etext);
	}
	DISCARD_TEXT(elist);

@<Render the list of see-references@> =
	TEMPORARY_TEXT(seelist);
	Str::copy(seelist, il->index_see);
	int sc = 0;
	if (Str::len(seelist) > 0) {
		if (lc > 0) WRITE("; ");
		HTML_OPEN_WITH("span", "class=\"indexsee\"");
		WRITE("see");
		if (lc > 0) WRITE(" also");
		WRITE("</span> ");
		match_results mr2 = Regexp::create_mr();
		while (Regexp::match(&mr2, seelist, L"(%c*?) *<-- *(%c*)")) {
			if (sc++ > 0) { WRITE("; "); }

			text_stream *see = mr2.exp[0];
			Str::copy(seelist, mr2.exp[1]);
			index_lemma *ils = (index_lemma *) Dictionaries::read_value(index_points_dict, see);
			TEMPORARY_TEXT(url);
			WRITE_TO(url, "#l%d", ils->allocation_id);
			Regexp::replace(see, L"=___=%i+?:", L":", REP_REPEATING);
			Regexp::replace(see, L"=___=%i+", NULL, REP_REPEATING);
			Regexp::replace(see, L":", L": ", REP_REPEATING);
			HTMLUtilities::general_link(OUT, I"indexseelink", url, see);
			DISCARD_TEXT(url);
		}
		Regexp::dispose_of(&mr2);
	}

@<Give feedback in index testing mode@> =
	if (indoc_settings->test_index_mode) {
		PRINT("indoc ran in index test mode: do not publish typeset documentation.\n");
		int t = 0;
		indexing_category *ic;
		LOOP_OVER(ic, indexing_category) {
			PRINT("%S: %d headword(s)\n", ic->cat_name, ic->cat_usage);
			t += ic->cat_usage;
		}
		PRINT("%d headword(s) in all\n", t);
	}
