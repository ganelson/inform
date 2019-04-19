[PL::Bibliographic::] Bibliographic Data.

To manage the special variables providing bibliographic data on the
work of IF being generated (title, author's name and so forth), and to write
the Library Card in the index.

@h Definitions.

@ Much of this section is best understood by reference to the Treaty of
Babel, a cross-IF-system standard for bibliographic data and packaging
agreed between the major IF design systems in 2006. Inform aims to comply
fully with the Treaty and the code below should be maintained as such.

The bibliographic data for the story is kept in the following variables,
which are used to build the iFiction record and the releasing blurb at
the end of a successful compilation.

=
nonlocal_variable *story_title_VAR = NULL;
nonlocal_variable *story_author_VAR = NULL;
nonlocal_variable *story_headline_VAR = NULL;
nonlocal_variable *story_genre_VAR = NULL;
nonlocal_variable *story_description_VAR = NULL;
nonlocal_variable *story_release_number_VAR = NULL;
nonlocal_variable *story_creation_year_VAR = NULL;
int episode_number = -1; /* for a work which is part of a numbered series */
wchar_t *series_name = NULL;

@ This is organised as a plugin since it's all broadly IF-based, and not
something you'd expect in a general programming language. But the main
effect is only to make a small number of variables special.

=
void PL::Bibliographic::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_VARIABLE_NOTIFY, PL::Bibliographic::bibliographic_new_variable_notify);
}

@ The following grammar contains the names of all of the bibliographic
variables -- those used to set entries on the Library Card about a project.
As usual, Inform uses these English wordings to detect the creation of the
variables in the Standard Rules, which are in English: so there's no point
in translating this nonterminal to other languages.

=
<notable-bibliographic-variables> ::=
	story title |
	story author |
	story headline |
	story genre |
	story description |
	story creation year |
	release number

@ And we read them here:

@d STORY_TITLE_BIBV 0
@d STORY_AUTHOR_BIBV 1
@d STORY_HEADLINE_BIBV 2
@d STORY_GENRE_BIBV 3
@d STORY_DESCRIPTION_BIBV 4
@d STORY_CREATION_YEAR_BIBV 5
@d RELEASE_NUMBER_BIBV 6

=
int PL::Bibliographic::bibliographic_new_variable_notify(nonlocal_variable *q) {
	if (<notable-bibliographic-variables>(q->name)) {
		switch (<<r>>) {
			case STORY_TITLE_BIBV: story_title_VAR = q; break;
			case STORY_AUTHOR_BIBV: story_author_VAR = q; break;
			case STORY_HEADLINE_BIBV: story_headline_VAR = q; break;
			case STORY_GENRE_BIBV: story_genre_VAR = q; break;
			case STORY_DESCRIPTION_BIBV: story_description_VAR = q; break;
			case STORY_CREATION_YEAR_BIBV: story_creation_year_VAR = q; break;
			case RELEASE_NUMBER_BIBV: story_release_number_VAR = q; break;
		}
		NonlocalVariables::make_constant(q, TRUE);
	}
	return FALSE;
}

@ This is what the top line of the main source text should look like, if it's
to declare the title and author.

=
<titling-line> ::=
	<plain-titling-line> ( in <natural-language> ) |	==> R[1]; *XP = RP[2];
	<plain-titling-line>								==> R[1]; *XP = NULL;

<plain-titling-line> ::=
	{<quoted-text-without-subs>} by ... |	==> TRUE
	{<quoted-text-without-subs>}			==> FALSE

@ That grammar is used at two points: first, to spot the natural language
being used in the source text, something we have to look ahead to since
it affects the grammar needed to understand the rest of the file --

=
natural_language *PL::Bibliographic::scan_language(parse_node *PN) {
	if (<titling-line>(ParseTree::get_text(PN))) return <<rp>>;
	return NULL;
}

@ -- and secondly, to parse the titling-line sentence in the regular way,
setting bibliographic variables as needed. The following is called on the
first sentence in the source text if and only if it begins with text in
double quotes:

=
void PL::Bibliographic::bibliographic_data(parse_node *PN) {
	if (<titling-line>(ParseTree::get_text(PN))) {
		wording TW = GET_RW(<plain-titling-line>, 1);
		wording AW = EMPTY_WORDING;
		if (<<r>>) AW = GET_RW(<plain-titling-line>, 2);
		if ((story_title_VAR) && (story_author_VAR)) {
			@<Set the story title from the titling line@>;
			if (Wordings::nonempty(AW)) @<Set the author from the titling line@>;
		}
	} else {
		Problems::Issue::sentence_problem(_p_(PM_BadTitleSentence),
			"the initial bibliographic sentence can only be a title in double-quotes",
			"possibly followed with 'by' and the name of the author.");
	}
}

@ We must not of course simply write to the variables; we call the assertion
machinery to generate an inference about their values, because that ensures
that contradictions, and so forth, are properly complained about.

@<Set the story title from the titling line@> =
	parse_node *the_title;
	if (<s-value>(TW)) the_title = <<rp>>;
	else the_title = Specifications::new_UNKNOWN(TW);
	Assertions::PropertyKnowledge::initialise_global_variable(story_title_VAR, the_title);
	Strings::TextLiterals::suppress_quote_expansion(ParseTree::get_text(the_title));

@ The author is often given outside of quotation marks:

>> "The Large Scale Structure of Space-Time" by Lindsay Lohan

and in such cases we transcribe the name-words into quotes so that we can
treat them as a text literal ("Lindsay Lohan").

@<Set the author from the titling line@> =
	TEMPORARY_TEXT(author_buffer);
	if (<quoted-text>(AW) == FALSE) {
		WRITE_TO(author_buffer, "\"%+W", AW);
		for (int i=1, L=Str::len(author_buffer); i<L; i++)
			if (Str::get_at(author_buffer, i) == '\"')
				Str::put_at(author_buffer, i, '\'');
		WRITE_TO(author_buffer, "\" ");
		AW = Feeds::feed_stream(author_buffer);
	}
	DISCARD_TEXT(author_buffer);
	parse_node *the_author;
	if (<s-value>(AW)) the_author = <<rp>>;
	else the_author = Specifications::new_UNKNOWN(AW);
	Assertions::PropertyKnowledge::initialise_global_variable(story_author_VAR, the_author);

@ This unattractive routine performs a string comparison of the author's name
against one that's supplied, case sensitively, and is used when deciding
whether to print credits at run-time for extensions written by the same
person as the author of the main work.

=
int PL::Bibliographic::story_author_is(text_stream *p) {
	if ((story_author_VAR) &&
		(NonlocalVariables::has_initial_value_set(story_author_VAR))) {
		parse_node *spec = NonlocalVariables::get_initial_value(story_author_VAR);
		ParseTree::set_kind_of_value(spec, K_text);
		int result = FALSE;
		TEMPORARY_TEXT(TEMP);
		wording W = ParseTree::get_text(spec);
		int w1 = Wordings::first_wn(W);
		HTMLFiles::compile_bibliographic_text(TEMP, Lexer::word_text(w1));
		if (Str::eq(TEMP, p)) result = TRUE;
		DISCARD_TEXT(TEMP);
		return result;
	}
	return FALSE;
}

@ Inform probably shouldn't support this sentence, which does nothing other
than to fill in two pieces of rarely-used bibliographic data (which could
just as easily be variables). But two of the larger worked examples we were
trying Inform out on, in the early days, belonged to a sequence called
"When in Rome". So it didn't seem such an obscure request at the time.

>> This is episode 2 of "When in Rome".

The subject noun phrase is fixed, so the information is in the object NP,
which must match:

=
<episode-sentence-subject> ::=
	<definite-article> story |
	this story |
	story

<episode-sentence-object> ::=
	episode <cardinal-number> of <quoted-text-without-subs> |		==> R[1]; <<series>> = R[2];
	episode ...														==> @<Issue PM_BadEpisode problem@>;

@<Issue PM_BadEpisode problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(_p_(PM_BadEpisode),
		"this is not the right way to specify how the story "
		"fits into a larger narrative",
		"and should take the form 'The story is episode 2 of "
		"\"Belt of Orion\", where the episode number has to be a "
		"whole number 0, 1, 2, ... and the series name has to be "
		"plain text without [substitutions].");

@ This handles the special meaning "The story is episode...".

=
int PL::Bibliographic::episode_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The story is episode 2 of ..." */
		case ACCEPT_SMFT:
			if ((<episode-sentence-subject>(SW)) && (<episode-sentence-object>(OW))) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				if (<<r>> >= 0) {
					episode_number = <<r>>;
					Word::dequote(<<series>>);
					series_name = Lexer::word_text(<<series>>);
				}
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ In the I6 template layer, some of the bibliographic variables are actually
compiled to constants, used early on at run-time to print the banner.

=
void PL::Bibliographic::compile_constants(void) {
	encode_constant_text_bibliographically = TRUE;
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_I6_CMODE);

	if (story_title_VAR) @<Compile the I6 Story constant@>;
	if (story_headline_VAR) @<Compile the I6 Headline constant@>;
	if (story_author_VAR) @<Compile the I6 Story Author constant@>;
	if (story_release_number_VAR) @<Compile the I6 Release directive@>;
	@<Compile the I6 serial number, based on the date@>;

	END_COMPILATION_MODE;
	encode_constant_text_bibliographically = FALSE;
}

@ If the author doesn't name a work, then its title is properly "", not
"Welcome": that's just something we use to provide a readable banner.

@<Compile the I6 Story constant@> =
	inter_name *iname = Hierarchy::find(STORY_HL);
	NonlocalVariables::treat_as_plain_text_word(story_title_VAR);
	inter_t v1 = 0, v2 = 0;
	if (NonlocalVariables::has_initial_value_set(story_title_VAR))
		NonlocalVariables::seek_initial_value(iname, &v1, &v2, story_title_VAR);
	else
		Strings::TextLiterals::compile_literal_from_text(iname, &v1, &v2, L"\"Welcome\"");
	Emit::named_generic_constant(iname, v1, v2);

@ And similarly here:

@<Compile the I6 Headline constant@> =
	inter_name *iname = Hierarchy::find(HEADLINE_HL);
	inter_t v1 = 0, v2 = 0;
	if (NonlocalVariables::has_initial_value_set(story_headline_VAR)) {
		NonlocalVariables::treat_as_plain_text_word(story_headline_VAR);
		NonlocalVariables::seek_initial_value(iname, &v1, &v2, story_headline_VAR);
	} else {
		Strings::TextLiterals::compile_literal_from_text(iname, &v1, &v2, L"\"An Interactive Fiction\"");
	}
	Emit::named_generic_constant(iname, v1, v2);

@ This time we compile nothing if no author is provided:

@<Compile the I6 Story Author constant@> =
	if (NonlocalVariables::has_initial_value_set(story_author_VAR)) {
		inter_name *iname = Hierarchy::find(STORY_AUTHOR_HL);
		inter_t v1 = 0, v2 = 0;
		NonlocalVariables::treat_as_plain_text_word(story_author_VAR);
		NonlocalVariables::seek_initial_value(iname, &v1, &v2, story_author_VAR);
		Emit::named_generic_constant(iname, v1, v2);
	}

@ Similarly (but numerically):

@<Compile the I6 Release directive@> =
	if (NonlocalVariables::has_initial_value_set(story_release_number_VAR)) {
		inter_name *iname = Hierarchy::find(RELEASE_HL);
		inter_t v1 = 0, v2 = 0;
		NonlocalVariables::seek_initial_value(iname, &v1, &v2, story_release_number_VAR);
		Emit::named_generic_constant(iname, v1, v2);
	}

@ This innocuous code -- if Inform runs on 25 June 2013, we compile the serial
number "130625" -- is actually controversial: quite a few users feel they
should be able to fake the date-stamp with dates of their own choosing.

@<Compile the I6 serial number, based on the date@> =
	inter_name *iname = Hierarchy::find(SERIAL_HL);
	TEMPORARY_TEXT(SN);
	int year_digits = (the_present->tm_year) % 100;
	WRITE_TO(SN, "%02d%02d%02d",
		year_digits, (the_present->tm_mon)+1, the_present->tm_mday);
	Emit::named_text_constant(iname, SN);
	DISCARD_TEXT(SN);

@ The Library Card is part of the Contents index, and is intended as a
natural way to present bibliographic data to the user. In effect, it's a
simplified form of the iFiction record, without the XML overhead.

=
void PL::Bibliographic::index_library_card(OUTPUT_STREAM) {
	HTML_OPEN("p");
	Index::anchor(OUT, I"LCARD");
	HTML::begin_html_table(OUT, "*bg_images/indexcard.png", FALSE, 0, 3, 3, 0, 0);
	PL::Bibliographic::library_card_entry(OUT, "Story title", story_title_VAR, I"Untitled");
	PL::Bibliographic::library_card_entry(OUT, "Story author", story_author_VAR, I"Anonymous");
	PL::Bibliographic::library_card_entry(OUT, "Story headline", story_headline_VAR, I"An Interactive Fiction");
	PL::Bibliographic::library_card_entry(OUT, "Story genre", story_genre_VAR, I"Fiction");
	if (episode_number >= 0) {
		TEMPORARY_TEXT(episode_text);
		WRITE_TO(episode_text, "%d of %w", episode_number, series_name);
		PL::Bibliographic::library_card_entry(OUT, "Episode", NULL, episode_text);
		DISCARD_TEXT(episode_text);
	}
	PL::Bibliographic::library_card_entry(OUT, "Release number", story_release_number_VAR, I"1");
	PL::Bibliographic::library_card_entry(OUT, "Story creation year", story_creation_year_VAR, I"(This year)");
	TEMPORARY_TEXT(lang);
	WRITE_TO(lang, "%+W", NaturalLanguages::get_name(language_of_play));
	PL::Bibliographic::library_card_entry(OUT, "Language of play", NULL, lang);
	DISCARD_TEXT(lang);
	PL::Bibliographic::library_card_entry(OUT, "IFID number", NULL, PL::Bibliographic::IFID::read_uuid());
	PL::Bibliographic::library_card_entry(OUT, "Story description", story_description_VAR, I"None");
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@ This uses:

=
void PL::Bibliographic::library_card_entry(OUTPUT_STREAM, char *field, nonlocal_variable *nlv, text_stream *t) {
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
	PL::Bibliographic::index_bibliographic_variable(OUT, nlv, t);
	HTML_CLOSE("b");
	HTML_CLOSE("span");
	HTML::end_colour(OUT);
	HTML::end_html_row(OUT);
}

@ The Index also likes to print the name and authorship at the top of the
Contents listing, so:

=
void PL::Bibliographic::contents_heading(OUTPUT_STREAM) {
	if ((story_title_VAR == NULL) || (story_author_VAR == NULL))
		WRITE("Contents");
	else {
		PL::Bibliographic::index_bibliographic_variable(OUT, story_title_VAR, I"Untitled");
		WRITE(" by ");
		PL::Bibliographic::index_bibliographic_variable(OUT, story_author_VAR, I"Anonymous");
	}
}

@ And both of those features use:

=
void PL::Bibliographic::index_bibliographic_variable(OUTPUT_STREAM, nonlocal_variable *nlv, text_stream *t) {
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_XML_CMODE);
	if ((nlv) && (NonlocalVariables::has_initial_value_set(nlv))) {
		wording W = NonlocalVariables::treat_as_plain_text_word(nlv);
		HTMLFiles::compile_bibliographic_text(OUT, Lexer::word_text(Wordings::first_wn(W)));
	} else {
		WRITE("%S", t);
	}
	END_COMPILATION_MODE;
}
