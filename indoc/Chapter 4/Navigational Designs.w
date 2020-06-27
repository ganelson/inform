[Nav::] Navigational Designs.

To render linking gadgets in HTML forms of documentation, so that
the reader can navigate from section to section.

@h

=
typedef struct navigation_design {
	struct text_stream *codename;
	int ebook_friendly;
	int plain_friendly;
	int columnar;
	int simplified_examples;
	int simplified_letter_rows;
	struct text_stream *contents_body_class;
	struct method_set *methods;
	CLASS_DEFINITION
} navigation_design;

navigation_design *Nav::new(text_stream *code, int e, int p) {
	navigation_design *ND = CREATE(navigation_design);
	ND->codename = Str::duplicate(code);
	ND->ebook_friendly = e;
	ND->plain_friendly = p;
	ND->columnar = FALSE;
	ND->simplified_examples = FALSE;
	ND->simplified_letter_rows = FALSE;
	ND->contents_body_class = I"paper midnightpapertint";
	ND->methods = Methods::new_set();
	return ND;
}

void Nav::start(void) {
	Midnight::create(); /* needs to be created first */
	Twilight::create();
	Architect::create();
	Roadsign::create(); /* needs to be created before unsigned */
	Unsigned::create();
	Lacuna::create();
}

navigation_design *Nav::default(void) {
	return FIRST_OBJECT(navigation_design);
}

navigation_design *Nav::for_ebook(navigation_design *current) {
	if (current->ebook_friendly) return current;
	navigation_design *ND;
	LOOP_OVER(ND, navigation_design)
		if (ND->ebook_friendly)
			return ND;
	return NULL;
}

navigation_design *Nav::for_plain_text(navigation_design *current) {
	if (current->plain_friendly) return current;
	navigation_design *ND;
	LOOP_OVER(ND, navigation_design)
		if (ND->plain_friendly)
			return ND;
	return NULL;
}

navigation_design *Nav::parse(text_stream *val) {
	navigation_design *ND;
	LOOP_OVER(ND, navigation_design)
		if (Str::eq(val, ND->codename))
			return ND;
	return NULL;
}

@h Top.
At the front end of a section, before any of its text.

@e RENDER_VOLUME_TITLE_MTID
@e RENDER_CHAPTER_TITLE_MTID
@e RENDER_SECTION_TITLE_MTID

=
VOID_METHOD_TYPE(RENDER_VOLUME_TITLE_MTID, navigation_design *ND, text_stream *OUT, volume *V)
VOID_METHOD_TYPE(RENDER_CHAPTER_TITLE_MTID, navigation_design *ND, text_stream *OUT, volume *V, chapter *C)
VOID_METHOD_TYPE(RENDER_SECTION_TITLE_MTID, navigation_design *ND, text_stream *OUT, volume *V, chapter *C, section *S)

void Nav::render_navigation_top(OUTPUT_STREAM, volume *V, section *S) {
	if (indoc_settings->insertion_filename)
		HTML::incorporate_HTML(OUT, indoc_settings->insertion_filename);

	if (V->sections[0] == S) VOID_METHOD_CALL(indoc_settings->navigation, RENDER_VOLUME_TITLE_MTID, OUT, V);

	chapter *C = S->begins_which_chapter;
	if (C) VOID_METHOD_CALL(indoc_settings->navigation, RENDER_CHAPTER_TITLE_MTID, OUT, V, C);

	if (indoc_settings->html_for_Inform_application)
		@<Write HTML comments giving the Inform user interface search assistance@>;

	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_SECTION_TITLE_MTID, OUT, V, C, S);
}

@<Write HTML comments giving the Inform user interface search assistance@> =
	WRITE("\n");
	TEMPORARY_TEXT(comment)
	WRITE_TO(comment, "SEARCH TITLE \"%S\"", S->unlabelled_title);
	HTML::comment(OUT, comment);
	Str::clear(comment);
	WRITE_TO(comment, "SEARCH SECTION \"%S\"", S->label);
	HTML::comment(OUT, comment);
	Str::clear(comment);
	WRITE_TO(comment, "SEARCH SORT \"%S\"", S->sort_code);
	HTML::comment(OUT, comment);
	DISCARD_TEXT(comment)

@h Index top.
And this is a variant for index pages, such as the index of examples.

@e RENDER_INDEX_TOP_MTID

=
VOID_METHOD_TYPE(RENDER_INDEX_TOP_MTID, navigation_design *ND, text_stream *OUT, text_stream *filename, text_stream *title)

void Nav::render_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
	if (indoc_settings->insertion_filename)
		HTML::incorporate_HTML(OUT, indoc_settings->insertion_filename);

	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_INDEX_TOP_MTID, OUT, filename, title);
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

@e RENDER_NAV_MIDDLE_MTID

=
VOID_METHOD_TYPE(RENDER_NAV_MIDDLE_MTID, navigation_design *ND, text_stream *OUT, volume *V, section *S)

void Nav::render_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_NAV_MIDDLE_MTID, OUT, V, S);
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

@e RENDER_EXAMPLE_TOP_MTID

=
VOID_METHOD_TYPE(RENDER_EXAMPLE_TOP_MTID, navigation_design *ND, text_stream *OUT, volume *V, section *S)

void Nav::render_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {

	if (indoc_settings->format == HTML_FORMAT) {
		HTML::begin_div_with_class_S(OUT, I"bookexamples");
		HTML_OPEN_WITH("p", "class=\"chapterheading\"");
	}

	if (indoc_settings->examples_granularity == CHAPTER_GRANULARITY) {
		chapter *C = S->in_which_chapter;
		WRITE("Examples from %S", C->chapter_full_title);
	} else if (indoc_settings->examples_granularity == BOOK_GRANULARITY) {
		WRITE("Examples");
	}

	if (indoc_settings->format == HTML_FORMAT) { HTML_CLOSE("p"); } else WRITE("\n\n");

	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_EXAMPLE_TOP_MTID, OUT, V, S);
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

@e RENDER_EXAMPLE_BOTTOM_MTID

=
VOID_METHOD_TYPE(RENDER_EXAMPLE_BOTTOM_MTID, navigation_design *ND, text_stream *OUT, volume *V, section *S)

void Nav::render_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {
	if (indoc_settings->format == PLAIN_FORMAT) WRITE("\n\n");

	if (indoc_settings->format == HTML_FORMAT) {
		if (indoc_settings->examples_mode != EXMODE_open_internal)
			HTMLUtilities::ruled_line(OUT);
		HTML::end_div(OUT);
	}

	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_EXAMPLE_BOTTOM_MTID, OUT, V, S);
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

@e RENDER_NAV_BOTTOM_MTID

=
VOID_METHOD_TYPE(RENDER_NAV_BOTTOM_MTID, navigation_design *ND, text_stream *OUT, volume *V, section *S)

void Nav::render_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
	if (indoc_settings->format == HTML_FORMAT) HTML::comment(OUT, I"START IGNORE");
	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_NAV_BOTTOM_MTID, OUT, V, S);
	if (indoc_settings->format == HTML_FORMAT) HTML::comment(OUT, I"END IGNORE");
}

@h Contents page.
Midnight provides a contents page of its very own.

@e RENDER_CONTENTS_MTID
@e RENDER_CONTENTS_HEADING_MTID

=
VOID_METHOD_TYPE(RENDER_CONTENTS_MTID, navigation_design *ND)
VOID_METHOD_TYPE(RENDER_CONTENTS_HEADING_MTID, navigation_design *ND, text_stream *OUT, volume *V)

void Nav::render_navigation_contents_files(void) {
	VOID_METHOD_CALL_WITHOUT_ARGUMENTS(indoc_settings->navigation, RENDER_CONTENTS_MTID);
}

void Nav::navigation_contents_heading(OUTPUT_STREAM, volume *V) {
	VOID_METHOD_CALL(indoc_settings->navigation, RENDER_CONTENTS_HEADING_MTID, OUT, V);
}
