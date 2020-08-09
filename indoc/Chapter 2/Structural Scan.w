[Scanner::] Structural Scan.

Finding out how a volume divides up into chapters and sections.

@ Projects are divided into volumes, which are divided into chapters, which
in turn are divided into sections.

Volumes count from 0, in order of creation, so these are arrays.

@d MAX_VOLUMES 100
@d MAX_CHAPTERS_PER_VOLUME 100
@d MAX_SECTIONS_PER_VOLUME 1000
@d MAX_EXAMPLES_PER_VOLUME MAX_EXAMPLES

=
typedef struct volume {
 	struct text_stream *vol_title; /* e.g., "What Katy Did Next" */
 	struct text_stream *vol_abbrev; /* e.g., "WKDN" */
 	struct text_stream *vol_prefix; /* e.g., "K" */
 	struct filename *vol_rawtext_filename; /* source file */
 	struct text_stream *vol_CSS_leafname; /*  CSS file used for pages in this volume */
 	struct text_stream *vol_URL; /*  link to start of volume */
 	int vol_chapter_count;
 	int vol_section_count;
 	struct chapter *chapters[MAX_CHAPTERS_PER_VOLUME]; /* these count from 1 */
 	struct section *sections[MAX_SECTIONS_PER_VOLUME]; /* but these count from 0 */
 	struct example *examples_sequence[MAX_EXAMPLES_PER_VOLUME]; /* also these */
	struct dictionary *sections_by_name;
	CLASS_DEFINITION
} volume;

volume *volumes[MAX_VOLUMES];

@ Chapters:

=
typedef struct chapter {
 	struct text_stream *chapter_title; /* e.g., "The Pension Suisse" */
	int chapter_number; /* counting from 1 */
 	struct text_stream *chapter_full_title; /* e.g., "Chapter 7: The Pension Suisse" */
 	struct section *begins_at_section; /* e.g., section 51 might be the first of chapter 7 */
 	struct text_stream *chapter_anchor; /* HTML anchor to place at front of chapter, if any */
 	struct text_stream *chapter_URL; /* link to start of chapter */
 	struct chapter *next_chapter;
 	struct chapter *previous_chapter;
 	struct ebook_chapter *ebook_ref;
 	CLASS_DEFINITION
} chapter;

@ Sections:

@d MAX_DRS_PER_SECTION 100

=
typedef struct section {
	struct chapter *in_which_chapter; /* e.g., 7 */
	struct chapter *begins_which_chapter; /* e.g., 7, but -1 if it doesn't open a chapter */
	struct text_stream *unlabelled_title; /* e.g., "Corsica" */
	struct text_stream *label; /* e.g., "7.1" */
	struct text_stream *title; /* e.g, "7.1. Corsica" */
	struct text_stream *sort_code; /* a formatted version of the label for alphabetic sorting */
	struct filename *section_filename; /* filename to write this section (and perhaps others) into */
	struct text_stream *section_file_title; /* title the whole file will have */
	struct text_stream *section_anchor; /* HTML anchor to place at front of section, if any */
	struct text_stream *section_URL; /* link to start of section */
	struct text_stream *unanchored_URL; /* link to start of file holding this */
	int no_doc_reference_symbols;
	struct text_stream *doc_reference_symbols[MAX_DRS_PER_SECTION];
  	struct section *next_section;
 	struct section *previous_section;
 	int number_within_volume;
	CLASS_DEFINITION
} section;

@h Volumes.
These are created when we scan the instructions file.

=
void Scanner::create_volume(pathname *book_path, text_stream *leaf, text_stream *title, text_stream *abbrev_supplied) {
  	TEMPORARY_TEXT(pre)
 	TEMPORARY_TEXT(abbrev)
	Str::copy(abbrev, abbrev_supplied);

 	@<Work out title and abbreviation if these aren't supplied@>;

 	if (no_volumes > 0) PUT_TO(pre, Str::get_first_char(abbrev));

 	@<Ensure that no two volumes have the same abbreviation or the same prefix@>;

 	if (no_volumes >= MAX_VOLUMES) Errors::fatal("too many volumes");

 	volume *V = CREATE(volume);
 	volumes[no_volumes++] = V;
 	V->vol_title = Str::duplicate(title);
 	V->vol_prefix = Str::duplicate(pre);
 	V->vol_abbrev = Str::duplicate(abbrev);
 	V->vol_rawtext_filename = Filenames::in(book_path, leaf);
  	V->vol_CSS_leafname = NULL;
 	V->vol_URL = NULL;
 	V->vol_chapter_count = 0;
 	V->vol_section_count = 0;
 	V->sections_by_name = Dictionaries::new(100, FALSE);

 	PRINT("Volume %d: %S  %S %S  %f\n", no_volumes-1, title, abbrev, pre,
 		V->vol_rawtext_filename);
  	DISCARD_TEXT(pre)
  	DISCARD_TEXT(abbrev)
}

@<Work out title and abbreviation if these aren't supplied@> =
 	if (Str::len(title) == 0) title = I"Untitled";

 	if (Str::len(abbrev) == 0) {
 		int f = 0;
 		if (Str::begins_with_wide_string(title, L"A ")) f = 2;
 		else if (Str::begins_with_wide_string(title, L"An ")) f = 3;
 		else if (Str::begins_with_wide_string(title, L"The ")) f = 4;
 		for (int i=f; i<Str::len(title); i++) {
 			int c = Str::get_at(title, i);
 			if (Characters::is_whitespace(c)) continue;
 			if ((c >= 'a') && (c <= 'z')) continue;
 			PUT_TO(abbrev, c);
 		}
 	}

@<Ensure that no two volumes have the same abbreviation or the same prefix@> =
 	for (int i = 0; i < no_volumes; i++) {
 		if ((Str::eq(abbrev, volumes[i]->vol_abbrev)) || (Str::len(abbrev) == 0))
 			WRITE_TO(abbrev, "_%d", i);
  		if ((Str::eq(pre, volumes[i]->vol_prefix)) || (Str::len(pre) == 0))
 			WRITE_TO(pre, "_%d", i);
	}

@h Section title scanning.
This is a much skimpier first-pass-only scan which looks for section titles,
marrying them up with block numbers.

=
void Scanner::scan_rawtext_for_section_titles(volume *V) {
	filename *rawtext_filename = V->vol_rawtext_filename;
	sr_helper_state sr;
	sr.s = 0;
	sr.ch = 0;
	sr.chs = 0;
	sr.v = V->allocation_id;
	sr.owner = V;
	TextFiles::read(rawtext_filename, FALSE, "can't open instructions file",
		TRUE, Scanner::scan_rawtext_helper, NULL, &sr);
	V->vol_section_count = sr.s;
	V->vol_chapter_count = sr.ch;
	V->vol_URL = Str::new();
	if (sr.s > 0) Str::copy(V->vol_URL, V->sections[0]->unanchored_URL);

	for (int i=0; i<V->vol_section_count; i++) {
		if (i>0) V->sections[i]->previous_section = V->sections[i-1];
		if (i<V->vol_section_count-1) V->sections[i]->next_section = V->sections[i+1];
	}
	for (int i=0; i<V->vol_chapter_count; i++) {
		V->chapters[i]->chapter_number = i+1;
		if (i>0) V->chapters[i]->previous_chapter = V->chapters[i-1];
		if (i<V->vol_chapter_count-1) V->chapters[i]->next_chapter = V->chapters[i+1];
	}
}

typedef struct sr_helper_state {
	int v; /* volume number */
	int s; /* section number within the volume, starting from 0 */
	int ch; /* chapter number within the volume, starting from 1 */
	int chs; /* section number within current chapter, starting from 1 */
	struct volume *owner;
} sr_helper_state;

void Scanner::scan_rawtext_helper(text_stream *nl, text_file_position *tfp,
	void *v_sr) {
	sr_helper_state *sr = (sr_helper_state *) v_sr;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, nl, L"(%c*?) ")) Str::copy(nl, mr.exp[0]);
	if (Regexp::match(&mr, nl, L"%[(%c*?)%] (%c*)")) {
		section *S = CREATE(section);
		S->next_section = NULL; S->previous_section = NULL;
		S->begins_which_chapter = NULL;
		S->no_doc_reference_symbols = 0;
		S->number_within_volume = sr->s++;
		sr->owner->sections[S->number_within_volume] = S;

		text_stream *chi = mr.exp[0];
		text_stream *stitle = mr.exp[1];
		@<Strip away heading tags, but act on those filtering out the section@>;
		@<Deal with this as a chapter heading@>;
		@<Deal with this as a section heading@>;
	}
	Regexp::dispose_of(&mr);
}

@<Strip away heading tags, but act on those filtering out the section@> =
	match_results mr2 = Regexp::create_mr();
	while (Regexp::match(&mr2, chi, L"{(%c*?:}(%c*)")) {
 		Str::copy(chi, mr2.exp[1]);
 		if (Symbols::perform_ifdef(mr2.exp[0]) == FALSE) {
 			Regexp::dispose_of(&mr);
 			Regexp::dispose_of(&mr2);
 			return;
 		}
 	}
 	while (Regexp::match(&mr2, stitle, L"(%c*) {%c*?} *")) Str::copy(stitle, mr2.exp[0]);
 	if (Regexp::match(&mr2, stitle, L"(%c*?) ")) Str::copy(stitle, mr2.exp[0]);
 	Regexp::dispose_of(&mr2);

@<Deal with this as a chapter heading@> =
 	match_results mr2 = Regexp::create_mr();
 	if (Regexp::match(&mr2, chi, L"Chapter: (%c*)")) {
 		chapter *C = CREATE(chapter);
 		sr->owner->chapters[sr->ch++] = C;
 		sr->chs = 0;
 		C->chapter_title = Str::duplicate(mr2.exp[0]);
 		C->chapter_full_title = Str::new();
 		WRITE_TO(C->chapter_full_title, "Chapter %d: %S", sr->ch, C->chapter_title);
 		S->begins_which_chapter = C;
 		C->begins_at_section = S;
		C->next_chapter = NULL; C->previous_chapter = NULL;
		C->ebook_ref = NULL;
 	}
 	Regexp::dispose_of(&mr2);

@<Deal with this as a section heading@> =
 	chapter *C = (sr->ch > 0)?sr->owner->chapters[sr->ch-1]: NULL;
 	S->in_which_chapter = C;

 	sr->chs++;
 	S->label = Str::new();
 	WRITE_TO(S->label, "%d.%d", sr->ch, sr->chs);
 	S->sort_code = Str::new();
 	WRITE_TO(S->sort_code, "%03d-%03d-%03d-000", sr->v, sr->ch, sr->chs);

 	S->title = Str::new();
 	WRITE_TO(S->title, "%S. %S", S->label, stitle);
 	S->unlabelled_title = Str::duplicate(stitle);

	Dictionaries::create(sr->owner->sections_by_name, stitle);
	Dictionaries::write_value(
		sr->owner->sections_by_name, stitle, (void *) S);
	LOOP_THROUGH_TEXT(pos, stitle)
		Str::put(pos, Characters::toupper(Str::get(pos)));
	Dictionaries::create(sr->owner->sections_by_name, stitle);
	Dictionaries::write_value(
		sr->owner->sections_by_name, stitle, (void *) S);

 	@<Work out section URLs and anchors, depending on granularity@>;

 	if (S->begins_which_chapter)
 		@<Work out chapter URLs and anchors, depending on granularity@>;

@ This is relevant only to HTML, of course. The idea is that each section
has some linkable location, in the form of either a file URL, or a file plus
an anchor name: for example, it might be |WKDN_7.html#s4|. If the
anchor is blank, the filename alone is used.

@<Work out section URLs and anchors, depending on granularity@> =
 	char *extension = "txt";
 	if (indoc_settings->format == HTML_FORMAT) extension = "html";
 	TEMPORARY_TEXT(leaf)
 	if (indoc_settings->granularity == SECTION_GRANULARITY) {
 		if (indoc_settings->html_for_Inform_application)
 			WRITE_TO(leaf, "%Sdoc%d.%s", sr->owner->vol_prefix, sr->s, extension);
 		else
 			WRITE_TO(leaf, "%S_%d_%d.%s", sr->owner->vol_abbrev, sr->ch, sr->chs, extension);
 		S->section_anchor = Str::new();
 		S->section_file_title = Str::duplicate(S->title);
 	} else if (indoc_settings->granularity == CHAPTER_GRANULARITY) {
 		WRITE_TO(leaf, "%S_%d.%s", sr->owner->vol_abbrev, sr->ch, extension);
 		S->section_anchor = Str::new();
 		WRITE_TO(S->section_anchor, "s%d", sr->chs);
 		S->section_file_title = Str::duplicate(C->chapter_full_title);
 	} else {
 		WRITE_TO(leaf, "%S.%s", sr->owner->vol_abbrev, extension);
 		S->section_anchor = Str::new();
 		WRITE_TO(S->section_anchor, "c%d_s%d", sr->ch, sr->chs);
 		S->section_file_title = Str::duplicate(sr->owner->vol_title);
 	}
	S->section_filename = Filenames::in(indoc_settings->destination, leaf);
	S->section_URL = Str::duplicate(leaf);
	S->unanchored_URL = Str::duplicate(leaf);
	DISCARD_TEXT(leaf)
 	if (Str::len(S->section_anchor) > 0) WRITE_TO(S->section_URL, "#%S", S->section_anchor);

@ And similarly for chapters.

@<Work out chapter URLs and anchors, depending on granularity@> =
 	C->chapter_anchor = Str::new();
 	if (indoc_settings->granularity == SECTION_GRANULARITY) {
 	} else if (indoc_settings->granularity == CHAPTER_GRANULARITY) {
 		if (sr->ch == 1) WRITE_TO(C->chapter_anchor, "chapter_%d_%d", sr->v, sr->ch);
 	} else {
 		WRITE_TO(C->chapter_anchor, "chapter_%d_%d", sr->v, sr->ch);
 	}
 	C->chapter_URL = Str::duplicate(S->unanchored_URL);
 	if (Str::len(C->chapter_anchor) > 0) WRITE_TO(C->chapter_URL, "#%S", C->chapter_anchor);

@h The manifest file.
Its destiny is to hold a simple machine-readable contents listing, and it
helps the Inform application in searching the online documentation.

=
void Scanner::write_manifest_file(volume *V) {
	filename *M = Filenames::in(
		indoc_settings->destination, indoc_settings->manifest_leafname);
	text_stream M_struct;
	text_stream *OUT = &M_struct;
	if (Streams::open_to_file(OUT, M, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write manifest file", M);
	for (int i=0; i<V->vol_section_count; i++) {
		section *S = V->sections[i];
		WRITE("doc%d.html: %S  %S\n", i+1, S->label, S->title);
	}
	Streams::close(OUT);
}

@h Ebook markup.
This places internal markup within files in the EPUB version.

=
void Scanner::mark_up_ebook(void) {
	section *S;
	LOOP_OVER(S, section) {
		chapter *C = S->in_which_chapter;
		if (C) Epub::set_mark_in_chapter(C->ebook_ref, S->title, S->section_URL);
	}
}
