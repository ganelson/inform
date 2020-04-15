[IndexUtilities::] Indexing Utilities.

Some conveniences shared by our different forms of index.

@h Top and tail.

=
text_stream index_stream;

text_stream *IndexUtilities::open_page(text_stream *title, text_stream *leafname) {
	filename *F = Filenames::in(indoc_settings->destination, leafname);
	if (indoc_settings->wrapper == WRAPPER_epub)
		Epub::note_page(indoc_settings->ebook, F, title, I"index");

	text_stream *OUT = &index_stream;
	if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("can't write index page file", F);

	TEMPORARY_TEXT(head);
	HTMLUtilities::get_tt_matter(head, 1, 1);
	if (Str::len(head) > 0) {
		wchar_t replacement[1024];
		TEMPORARY_TEXT(rep);
		WRITE_TO(rep, "<title>Inform 7 - %S</title>", title);
		Str::copy_to_wide_string(replacement, rep, 1024);
		DISCARD_TEXT(rep);
		Regexp::replace(head, L"%[SUBHEADING%]", NULL, REP_REPEATING);
		Regexp::replace(head, L"<title>%c*</title>", replacement, REP_REPEATING);
		WRITE("%S", head);
	} else {
		HTMLUtilities::begin_file(OUT, volumes[0]);
		HTMLUtilities::write_title(OUT, title);
		HTML::end_head(OUT);
		HTML::begin_body(OUT, I"paper papertint");
	}
	DISCARD_TEXT(head);
	Nav::render_navigation_index_top(OUT, leafname, title);
	return OUT;
}

@ =
void IndexUtilities::close_page(OUTPUT_STREAM) {
	TEMPORARY_TEXT(tail);
	HTMLUtilities::get_tt_matter(tail, 1, 0);
	if (Str::len(tail) > 0) WRITE("%S", tail);
	else HTML::end_body(OUT);
	Streams::close(OUT);
}

@h Alphabetisation.
We flatten the casing and remove the singular articles; we count small
numbers as words, so that "3 Wise Monkeys" is filed as if it were "Three
Wise Monkeys"; with parts of multipart examples, such as "Disappointment
Bay 3", we insert a 0 before the 3 so that up to 99 parts can appear and
alphabetical sorting will agree with numerical.

=
dictionary *alphabetisation_exceptions = NULL; /* hash of lemmas with unusual alphabetisations */

void IndexUtilities::alphabetisation_exception(text_stream *term, text_stream *alphabetise_as) {
	if (alphabetisation_exceptions == NULL)
		alphabetisation_exceptions = Dictionaries::new(100, TRUE);
	text_stream *val = Dictionaries::create_text(alphabetisation_exceptions, term);
	Str::copy(val, alphabetise_as);
}

void IndexUtilities::improve_alphabetisation(text_stream *sort_key) {
	text_stream *alph = Dictionaries::get_text(alphabetisation_exceptions, sort_key);
	if (Str::len(alph) > 0) {
		Str::copy(sort_key, alph);
		LOOP_THROUGH_TEXT(pos, sort_key)
			Str::put(pos, Characters::tolower(Str::get(pos)));
	} else {
		LOOP_THROUGH_TEXT(pos, sort_key)
			Str::put(pos, Characters::tolower(Str::get(pos)));
		Regexp::replace(sort_key, L"a ", NULL, REP_ATSTART);
		Regexp::replace(sort_key, L"an ", NULL, REP_ATSTART);
		Regexp::replace(sort_key, L"the ", NULL, REP_ATSTART);
		LOOP_THROUGH_TEXT(pos, sort_key)
			Str::put(pos, Characters::tolower(Characters::remove_accent(Str::get(pos))));
		Regexp::replace(sort_key, L"%[ *%]", L"____SQUARES____", REP_REPEATING);
		Regexp::replace(sort_key, L"%[", NULL, REP_REPEATING);
		Regexp::replace(sort_key, L"%]", NULL, REP_REPEATING);
		Regexp::replace(sort_key, L"____SQUARES____", L"[]", REP_REPEATING);
		Regexp::replace(sort_key, L"%(", NULL, REP_REPEATING);
		Regexp::replace(sort_key, L"%)", NULL, REP_REPEATING);
		Regexp::replace(sort_key, L"1 ", L"one ", REP_ATSTART);
		Regexp::replace(sort_key, L"2 ", L"two ", REP_ATSTART);
		Regexp::replace(sort_key, L"3 ", L"three ", REP_ATSTART);
		Regexp::replace(sort_key, L"4 ", L"four ", REP_ATSTART);
		Regexp::replace(sort_key, L"5 ", L"five ", REP_ATSTART);
		Regexp::replace(sort_key, L"6 ", L"six ", REP_ATSTART);
		Regexp::replace(sort_key, L"7 ", L"seven ", REP_ATSTART);
		Regexp::replace(sort_key, L"8 ", L"eight ", REP_ATSTART);
		Regexp::replace(sort_key, L"9 ", L"nine ", REP_ATSTART);
		Regexp::replace(sort_key, L"10 ", L"ten ", REP_ATSTART);
		Regexp::replace(sort_key, L"11 ", L"eleven ", REP_ATSTART);
		Regexp::replace(sort_key, L"12 ", L"twelve ", REP_ATSTART);
		TEMPORARY_TEXT(x);
		Str::copy(x, sort_key);
		Str::clear(sort_key);
		match_results mr = Regexp::create_mr();
		while (Regexp::match(&mr, x, L"(%c*?)(%d+)(%c*)")) {
			WRITE_TO(sort_key, "%S", mr.exp[0]);
			Str::copy(x, mr.exp[2]);
			WRITE_TO(sort_key, "%08d", Str::atoi(mr.exp[1], 0));
		}
		WRITE_TO(sort_key, "%S", x);
		DISCARD_TEXT(x);
	}
}

@ =
int letters_taken[26];
void IndexUtilities::note_letter(int c) {
	int i = c - 'A';
	if ((i>=0) && (i<26)) letters_taken[i] = TRUE;
}
void IndexUtilities::alphabet_row(OUTPUT_STREAM, int sequence) {
	switch (sequence) {
		case 1:
			for (int i=0; i<26; i++)
				letters_taken[i] = FALSE;
			break;
		case 2: {
			int faked = FALSE;
			for (int i=0; i<26; i++)
				if (letters_taken[i] == FALSE) {
					if (faked == FALSE) { faked = TRUE; HTML_OPEN("p"); }
					TEMPORARY_TEXT(singleton);
					PUT_TO(singleton, 'A'+i);
					HTML::anchor(OUT, singleton);
					DISCARD_TEXT(singleton);
				}
			if (faked) { HTML_CLOSE("p"); }
			break;
		}
	}
	if (indoc_settings->navigation->simplified_letter_rows) {
		HTML_OPEN("p");
	} else {
		HTML_OPEN_WITH("table", "class=\"fullwidth\"");
		HTML_OPEN("tr");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}
	HTMLUtilities::general_link(OUT, I"letterlink", I"#A", I"A"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#B", I"B"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#C", I"C"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#D", I"D"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#E", I"E"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#F", I"F"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#G", I"G"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#H", I"H"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#I", I"I"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#J", I"J"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#K", I"K"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#L", I"L"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#M", I"M"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#N", I"N"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#O", I"O"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#P", I"P"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#Q", I"Q"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#R", I"R"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#S", I"S"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#T", I"T"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#U", I"U"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#V", I"V"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#W", I"W"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#X", I"X"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#Y", I"Y"); @<Between@>;
	HTMLUtilities::general_link(OUT, I"letterlink", I"#Z", I"Z");
	if (indoc_settings->navigation->simplified_letter_rows) {
		HTML_CLOSE("p");
	} else {
		HTML_CLOSE("td");
		HTML_CLOSE("tr");
		HTML_CLOSE("table");
	}
}

@<Between@> =
	if (indoc_settings->navigation->simplified_letter_rows) WRITE(" / ");
	else {
		HTML_CLOSE("td");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}

@ This is mainly used for the typographically dramatic link letters A, B, C, ...
but can also make fatter typographically dramatic headings, if it's stretched
in width and a longer text is supplied.

=
void IndexUtilities::majuscule_heading(OUTPUT_STREAM, text_stream *display_text, int single_letter) {
	if (indoc_settings->navigation->simplified_letter_rows) {
		if (single_letter == 1) { HTML::begin_div_with_class_S(OUT, I"majuscule"); }
		else { HTML::begin_div_with_class_S(OUT, I"stretchymajuscule"); }
		HTML_OPEN_WITH("span", "class=\"majusculelettering\"");
		WRITE("%S", display_text);
		HTML_CLOSE("span");
		HTML::end_div(OUT);
	} else {
		WRITE("<b>%S</b>", display_text);
	}
}
