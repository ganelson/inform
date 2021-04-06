[IXBibliographicData::] Bibliographic Data.

To write the Library Card in the index.

@ The Library Card is part of the Contents index, and is intended as a
natural way to present bibliographic data to the user. In effect, it's a
simplified form of the iFiction record, without the XML overhead.

=
void IXBibliographicData::Library_Card(OUTPUT_STREAM) {
	HTML_OPEN("p");
	Index::anchor(OUT, I"LCARD");
	HTML::begin_html_table(OUT, "*bg_images/indexcard.png", FALSE, 0, 3, 3, 0, 0);
	IXBibliographicData::Library_Card_entry(OUT, "Story title", story_title_VAR, I"Untitled");
	IXBibliographicData::Library_Card_entry(OUT, "Story author", story_author_VAR, I"Anonymous");
	IXBibliographicData::Library_Card_entry(OUT, "Story headline", story_headline_VAR, I"An Interactive Fiction");
	IXBibliographicData::Library_Card_entry(OUT, "Story genre", story_genre_VAR, I"Fiction");
	if (episode_number >= 0) {
		TEMPORARY_TEXT(episode_text)
		WRITE_TO(episode_text, "%d of %w", episode_number, series_name);
		IXBibliographicData::Library_Card_entry(OUT, "Episode", NULL, episode_text);
		DISCARD_TEXT(episode_text)
	}
	IXBibliographicData::Library_Card_entry(OUT, "Release number", story_release_number_VAR, I"1");
	IXBibliographicData::Library_Card_entry(OUT, "Story creation year", story_creation_year_VAR, I"(This year)");
	TEMPORARY_TEXT(lang)
	inform_language *L = Projects::get_language_of_play(Task::project());
	if (L == NULL) WRITE_TO(lang, "English");
	else WRITE_TO(lang, "%X", L->as_copy->edition->work);
	IXBibliographicData::Library_Card_entry(OUT, "Language of play", NULL, lang);
	DISCARD_TEXT(lang)
	IXBibliographicData::Library_Card_entry(OUT, "IFID number", NULL, BibliographicData::read_uuid());
	IXBibliographicData::Library_Card_entry(OUT, "Story description", story_description_VAR, I"None");
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@ This uses:

=
void IXBibliographicData::Library_Card_entry(OUTPUT_STREAM, char *field,
	nonlocal_variable *nlv, text_stream *t) {
	text_stream *col = I"303030";
	if (nlv == story_title_VAR) col = I"803030";
	HTML::first_html_column_nowrap(OUT, 0, NULL);
	HTML::begin_colour(OUT, col);
	HTML_OPEN_WITH("span", "class=\"typewritten\"");
	WRITE("%s", field);
	HTML_CLOSE("span");
	HTML::end_colour(OUT);
	HTML::next_html_column(OUT, 0);
	HTML::begin_colour(OUT, col);
	HTML_OPEN_WITH("span", "class=\"typewritten\"");
	HTML_OPEN("b");
	IXBibliographicData::index_variable(OUT, nlv, t);
	HTML_CLOSE("b");
	HTML_CLOSE("span");
	HTML::end_colour(OUT);
	HTML::end_html_row(OUT);
}

@ The Index also likes to print the name and authorship at the top of the
Contents listing, so:

=
void IXBibliographicData::contents_heading(OUTPUT_STREAM) {
	if ((story_title_VAR == NULL) || (story_author_VAR == NULL))
		WRITE("Contents");
	else {
		IXBibliographicData::index_variable(OUT, story_title_VAR,
			I"Untitled");
		WRITE(" by ");
		IXBibliographicData::index_variable(OUT, story_author_VAR,
			I"Anonymous");
	}
}

@ And both of those features use:

=
void IXBibliographicData::index_variable(OUTPUT_STREAM,
	nonlocal_variable *nlv, text_stream *t) {
	if ((nlv) && (VariableSubjects::has_initial_value_set(nlv))) {
		wording W = NonlocalVariables::initial_value_as_plain_text(nlv);
		BibliographicData::compile_bibliographic_text(OUT,
			Lexer::word_text(Wordings::first_wn(W)), XML_BIBTEXT_MODE);
	} else {
		WRITE("%S", t);
	}
}
