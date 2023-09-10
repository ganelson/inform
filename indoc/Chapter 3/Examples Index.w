[ExamplesIndex::] Examples Index.

To produces the contents and indexing pages, for HTML output and
multiple-files mode only.

@ These structures are used to hold details needed for one or both of the
alphabetic and thematic example indexes.

=
typedef struct example_index_data {
	int alpha_index_embolden;
	struct text_stream *alpha_index_rubric;
	struct text_stream *alpha_index_subtitle;
	struct section *alpha_index_to_S;
	struct example *alpha_index_to_E;
	struct text_stream *sort_key;
	CLASS_DEFINITION
} example_index_data;

dictionary *example_index_data_by_rubric = NULL;

@h Alphabetising the examples.
This is not quite an A-Z list of example names, because some examples are
allowed to be indexed twice, once under a literal name (say "Cloves")
and once under its point (say "Adverbs used in commands"). In addition to
that, some example snippets embedded in the body text of the manuals can
also appear here. So we actually maintain an alphabetical index able to
index examples under arbitrary, multiple descriptions.

=
void ExamplesIndex::add_to_alphabetic_examples_index(text_stream *given_rubric,
	section *index_to_S, example *index_to_E, int bold_flag) {
	TEMPORARY_TEXT(sort_key)
	TEMPORARY_TEXT(subtitle)
	Str::copy(sort_key, given_rubric);
	IndexUtilities::improve_alphabetisation(sort_key);

	example_index_data *eid = CREATE(example_index_data);
	eid->alpha_index_embolden = bold_flag;
	eid->alpha_index_rubric = Str::duplicate(given_rubric);
	eid->alpha_index_subtitle = Str::duplicate(subtitle);
	eid->alpha_index_to_S = index_to_S;
	eid->alpha_index_to_E = index_to_E;
	eid->sort_key = Str::duplicate(sort_key);

	if (example_index_data_by_rubric == NULL)
		example_index_data_by_rubric = Dictionaries::new(100, FALSE);
	Dictionaries::create(example_index_data_by_rubric, sort_key);
	Dictionaries::write_value(example_index_data_by_rubric, sort_key, (void *) eid);
}

@h Alphabetic index of examples.

=
void ExamplesIndex::write_alphabetical_examples_index(void) {
	@<Stock the alphabetical index@>;

	text_stream *OUT = IndexUtilities::open_page(
		I"Alphabetical Index of Examples", indoc_settings->examples_alphabetical_leafname);
	IndexUtilities::alphabet_row(OUT, 1);
	HTML_OPEN_WITH("table", "class=\"indextable\"");

	example_index_data **eid_list =
		Memory::calloc(NUMBER_CREATED(example_index_data), sizeof(example_index_data *), ARRAY_SORTING_MREASON);
	example_index_data *eid;
	LOOP_OVER(eid, example_index_data) eid_list[eid->allocation_id] = eid;
	qsort(eid_list, (size_t) NUMBER_CREATED(example_index_data), sizeof(example_index_data *),
		ExamplesIndex::sort_comparison);

	TEMPORARY_TEXT(current_subtitle)
	inchar32_t current_letter = 0;
	int first_letter_block = TRUE;
	for (int i=0; i<NUMBER_CREATED(example_index_data); i++) {
		example_index_data *eid = eid_list[i];
		inchar32_t initial = Str::get_first_char(eid->sort_key);
		if (Characters::isdigit(initial)) initial = '#';
		if (initial != current_letter) @<Start a new letter block@>;
		TEMPORARY_TEXT(url)
		@<Work out the URL of this example@>;
		@<Write an alphabetical-index entry@>;
		DISCARD_TEXT(url)
	}
	@<End a letter block@>;

	HTML_CLOSE("table");
	HTML_OPEN("p"); HTML_CLOSE("p");
	IndexUtilities::alphabet_row(OUT, 2);
	IndexUtilities::close_page(OUT);
	Memory::I7_free(eid_list, ARRAY_SORTING_MREASON,
		NUMBER_CREATED(example_index_data)*((int) sizeof(example_index_data *)));
}

@<Stock the alphabetical index@> =
	example *E;
	LOOP_OVER(E, example) {
		if (Str::len(E->ex_subtitle) > 0) {
			TEMPORARY_TEXT(index_as)
			WRITE_TO(index_as, "%S: %S", E->ex_public_name, E->ex_subtitle);
			ExamplesIndex::add_to_alphabetic_examples_index(index_as, NULL, E, TRUE);
			DISCARD_TEXT(index_as)
		} else if (Str::eq(E->ex_index, E->ex_public_name)) {
			ExamplesIndex::add_to_alphabetic_examples_index(E->ex_index, NULL, E, FALSE);
		} else {
			ExamplesIndex::add_to_alphabetic_examples_index(E->ex_public_name, NULL, E, TRUE);
			if (Str::len(E->ex_index) > 0)
				ExamplesIndex::add_to_alphabetic_examples_index(E->ex_index, NULL, E, FALSE);
		}
	}

@<Work out the URL of this example@> =
	if (eid->alpha_index_to_S)
		WRITE_TO(url, "%S", eid->alpha_index_to_S->section_URL);
	else
		Examples::goto_example_url(url, eid->alpha_index_to_E, volumes[0]);

@<Start a new letter block@> =
	current_letter = initial;
	if (first_letter_block == FALSE) { HTML_TAG("br"); @<End a letter block@>; }
	inchar32_t uc_current_letter = Characters::toupper(current_letter);
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"letterblock\"");
	TEMPORARY_TEXT(inc)
	PUT_TO(inc, uc_current_letter);
	HTML::anchor(OUT, inc);
	IndexUtilities::majuscule_heading(OUT, inc, TRUE);
	IndexUtilities::note_letter(uc_current_letter);
	DISCARD_TEXT(inc)
	HTML_CLOSE("td");
	HTML_OPEN("td");
	first_letter_block = FALSE;

@<End a letter block@> =
	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Write an alphabetical-index entry@> =
	HTML_OPEN_WITH("p", "class=\"indexentry\"");
	if (Str::len(eid->alpha_index_subtitle) > 0) {
		if (Str::ne(eid->alpha_index_subtitle, current_subtitle)) {
			WRITE("<b>%S</b><br />", eid->alpha_index_subtitle);
			Str::copy(current_subtitle, eid->alpha_index_subtitle);
		}
		WRITE("&#160;&#160;&#160;&#160;");
	}

	if (eid->alpha_index_embolden == TRUE) { HTML_OPEN("b"); }
	TEMPORARY_TEXT(link_text)
	Str::copy(link_text, eid->alpha_index_rubric);
	Rawtext::escape_HTML_characters_in(link_text);
	HTMLUtilities::general_link(OUT, I"standardlink", url, link_text);
	DISCARD_TEXT(link_text)

	if (eid->alpha_index_embolden == TRUE) { HTML_CLOSE("b"); }
	HTML_CLOSE("p");

@ =
int ExamplesIndex::sort_comparison(const void *ent1, const void *ent2) {
	const example_index_data *L1 = *((const example_index_data **) ent1);
	const example_index_data *L2 = *((const example_index_data **) ent2);
	return Str::cmp(L1->sort_key, L2->sort_key);
}

@h Thematic index of examples.

=
void ExamplesIndex::write_thematic_examples_index(void) {
	text_stream *OUT = IndexUtilities::open_page(
		I"Examples in Thematic Order", indoc_settings->examples_thematic_leafname);
	ExamplesIndex::write_index_for_volume(OUT, volumes[1]);
	IndexUtilities::close_page(OUT);
}

@h Numerical index of examples.

=
void ExamplesIndex::write_numerical_examples_index(void) {
	text_stream *OUT = IndexUtilities::open_page(
		I"Examples in Numerical Order", indoc_settings->examples_numerical_leafname);
	ExamplesIndex::write_index_for_volume(OUT, volumes[0]);
	IndexUtilities::close_page(OUT);
}

@ =
void ExamplesIndex::write_index_for_volume(OUTPUT_STREAM, volume *V) {
	chapter *owning_chapter = NULL;
	section *owning_section = NULL;
	for (int n = 0; n < no_examples; n++) {
		example *E = V->examples_sequence[n];
		section *S = E->example_belongs_to_section[V->allocation_id];
		chapter *C = S->in_which_chapter;
		if (owning_chapter != C) {
			if (owning_chapter != NULL) HTML_TAG("hr");
			owning_chapter = C;
			HTML_OPEN("p");
			WRITE("<b>Chapter %d: %S</b>", C->chapter_number, C->chapter_title);
			HTML_CLOSE("p");
		}
		if (owning_section != S) {
			owning_section = S;
			HTML_OPEN("p");
			WRITE("<i>%c%S</i>", SECTION_SYMBOL, S->title);
			HTML_CLOSE("p");
		}
		Examples::render_example_cue(OUT, E, V, TRUE);
	}
}
