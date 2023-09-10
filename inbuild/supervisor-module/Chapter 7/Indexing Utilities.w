[IndexUtilities::] Indexing Utilities.

Some conveniences shared by our different forms of index.

@ A temporary measure.

@d LETTER_ALPHABETIZATION 1
@d WORD_ALPHABETIZATION 2

@d WRAPPER_none 1
@d WRAPPER_epub 2
@d WRAPPER_zip 3

= (early code)
int indoc_settings_test_index_mode = FALSE;
int indoc_settings_index_alphabetisation_algorithm = LETTER_ALPHABETIZATION;
int indoc_settings_navigation_simplified_letter_rows = FALSE;
int indoc_settings_wrapper = WRAPPER_none;

@

=
void IndexUtilities::general_link(OUTPUT_STREAM, text_stream *cl, text_stream *to, text_stream *text) {
	HTML::begin_link_with_class(OUT, cl, to);
	WRITE("%S", text);
	HTML::end_link(OUT);
}

@ =
void IndexUtilities::escape_HTML_characters_in(text_stream *text) {
	TEMPORARY_TEXT(modified)
	for (int i=0, L=Str::len(text); i<L; i++) {
		inchar32_t c = Str::get_at(text, i);
		switch (c) {
			case '\"': 		WRITE_TO(modified, "&quot;"); break;
			case '<':		WRITE_TO(modified, "&lt;"); break;
			case '>':		WRITE_TO(modified, "&gt;"); break;
			case '&':
				if (Str::get_at(text, i+1) == '#') { PUT_TO(modified, c); break; }
				int j = i+1;
				while (Characters::isalnum(Str::get_at(text, j))) j++;
				if ((j > i+1) && (Str::get_at(text, j) == ';')) { PUT_TO(modified, c); break; }
				WRITE_TO(modified, "&amp;");
				break;
			default: 		PUT_TO(modified, c); break;
		}
	}
	Str::copy(text, modified);
	DISCARD_TEXT(modified)
}

@ Span notations allow markup such as |this is *dreadful*| to represent
emphasis; and are also used to mark headwords for indexing, as in
|this is ^{nifty}|.

@d MAX_PATTERN_LENGTH 1024

@d MARKUP_SPP 1
@d INDEX_TEXT_SPP 2
@d INDEX_SYMBOLS_SPP 3

@d WRAPPER_none 1
@d WRAPPER_epub 2
@d WRAPPER_zip 3

=
typedef struct span_notation {
	int sp_purpose;							/* one of the |*_SPP| constants */
	inchar32_t sp_left[MAX_PATTERN_LENGTH]; 	/* wide C string: the start pattern */
	int sp_left_len;
	inchar32_t sp_right[MAX_PATTERN_LENGTH];	/* wide C string: and end pattern */
	int sp_right_len;
	struct text_stream *sp_style;
	CLASS_DEFINITION
} span_notation;

void IndexUtilities::add_span_notation(compiled_documentation *cd,
	text_stream *L, text_stream *R, text_stream *style, int purpose) {
	span_notation *SN = CREATE(span_notation);
	SN->sp_style = Str::duplicate(style);
	Str::copy_to_wide_string(SN->sp_left, L, MAX_PATTERN_LENGTH);
	Str::copy_to_wide_string(SN->sp_right, R, MAX_PATTERN_LENGTH);
	SN->sp_left_len = Str::len(L);
	SN->sp_right_len = Str::len(R);
	SN->sp_purpose = purpose;
	ADD_TO_LINKED_LIST(SN, span_notation, cd->id.notations);
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
		Regexp::replace(sort_key, U"a ", NULL, REP_ATSTART);
		Regexp::replace(sort_key, U"an ", NULL, REP_ATSTART);
		Regexp::replace(sort_key, U"the ", NULL, REP_ATSTART);
		LOOP_THROUGH_TEXT(pos, sort_key)
			Str::put(pos, Characters::tolower(Characters::remove_accent(Str::get(pos))));
		Regexp::replace(sort_key, U"%[ *%]", U"____SQUARES____", REP_REPEATING);
		Regexp::replace(sort_key, U"%[", NULL, REP_REPEATING);
		Regexp::replace(sort_key, U"%]", NULL, REP_REPEATING);
		Regexp::replace(sort_key, U"____SQUARES____", U"[]", REP_REPEATING);
		Regexp::replace(sort_key, U"%(", NULL, REP_REPEATING);
		Regexp::replace(sort_key, U"%)", NULL, REP_REPEATING);
		Regexp::replace(sort_key, U"1 ", U"one ", REP_ATSTART);
		Regexp::replace(sort_key, U"2 ", U"two ", REP_ATSTART);
		Regexp::replace(sort_key, U"3 ", U"three ", REP_ATSTART);
		Regexp::replace(sort_key, U"4 ", U"four ", REP_ATSTART);
		Regexp::replace(sort_key, U"5 ", U"five ", REP_ATSTART);
		Regexp::replace(sort_key, U"6 ", U"six ", REP_ATSTART);
		Regexp::replace(sort_key, U"7 ", U"seven ", REP_ATSTART);
		Regexp::replace(sort_key, U"8 ", U"eight ", REP_ATSTART);
		Regexp::replace(sort_key, U"9 ", U"nine ", REP_ATSTART);
		Regexp::replace(sort_key, U"10 ", U"ten ", REP_ATSTART);
		Regexp::replace(sort_key, U"11 ", U"eleven ", REP_ATSTART);
		Regexp::replace(sort_key, U"12 ", U"twelve ", REP_ATSTART);
		TEMPORARY_TEXT(x)
		Str::copy(x, sort_key);
		Str::clear(sort_key);
		match_results mr = Regexp::create_mr();
		while (Regexp::match(&mr, x, U"(%c*?)(%d+)(%c*)")) {
			WRITE_TO(sort_key, "%S", mr.exp[0]);
			Str::copy(x, mr.exp[2]);
			WRITE_TO(sort_key, "%08d", Str::atoi(mr.exp[1], 0));
		}
		WRITE_TO(sort_key, "%S", x);
		DISCARD_TEXT(x)
	}
}

@ =
int letters_taken[26];
void IndexUtilities::note_letter(inchar32_t c) {
	inchar32_t i = c - (inchar32_t) 'A';
	if (i<26) letters_taken[i] = TRUE;
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
					TEMPORARY_TEXT(singleton)
					PUT_TO(singleton, (inchar32_t) ('A'+i));
					HTML::anchor(OUT, singleton);
					DISCARD_TEXT(singleton)
				}
			if (faked) { HTML_CLOSE("p"); }
			break;
		}
	}
	if (indoc_settings_navigation_simplified_letter_rows) {
		HTML_OPEN("p");
	} else {
		HTML_OPEN_WITH("table", "class=\"fullwidth\"");
		HTML_OPEN("tr");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}
	IndexUtilities::general_link(OUT, I"letterlink", I"#A", I"A"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#B", I"B"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#C", I"C"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#D", I"D"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#E", I"E"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#F", I"F"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#G", I"G"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#H", I"H"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#I", I"I"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#J", I"J"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#K", I"K"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#L", I"L"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#M", I"M"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#N", I"N"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#O", I"O"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#P", I"P"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#Q", I"Q"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#R", I"R"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#S", I"S"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#T", I"T"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#U", I"U"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#V", I"V"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#W", I"W"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#X", I"X"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#Y", I"Y"); @<Between@>;
	IndexUtilities::general_link(OUT, I"letterlink", I"#Z", I"Z");
	if (indoc_settings_navigation_simplified_letter_rows) {
		HTML_CLOSE("p");
	} else {
		HTML_CLOSE("td");
		HTML_CLOSE("tr");
		HTML_CLOSE("table");
	}
}

@<Between@> =
	if (indoc_settings_navigation_simplified_letter_rows) WRITE(" / ");
	else {
		HTML_CLOSE("td");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}

@ This is mainly used for the typographically dramatic link letters A, B, C, ...
but can also make fatter typographically dramatic headings, if it's stretched
in width and a longer text is supplied.

=
void IndexUtilities::majuscule_heading(OUTPUT_STREAM, text_stream *display_text, int single_letter) {
	if (indoc_settings_navigation_simplified_letter_rows) {
		if (single_letter == 1) {
			HTML::begin_div_with_class_S(OUT, I"majuscule", __FILE__, __LINE__);
		} else {
			HTML::begin_div_with_class_S(OUT, I"stretchymajuscule", __FILE__, __LINE__);
		}
		HTML_OPEN_WITH("span", "class=\"majusculelettering\"");
		WRITE("%S", display_text);
		HTML_CLOSE("span");
		HTML::end_div(OUT);
	} else {
		WRITE("<b>%S</b>", display_text);
	}
}
