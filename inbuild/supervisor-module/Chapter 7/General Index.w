[Indexes::] Contents and Indexes.

To render a documentation index into HTML form.

@ Having accumulated the lemmas, it's time to sort them and write the index
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
	int NL = 0;
	index_lemma **lemma_list = IndexingData::sort(cd, &NL);
	HTML_OPEN_WITH("div", "class=\"generalindex\"");
	@<Render the index in sorted order@>;
	HTML_CLOSE("div");
}

@<Render the index in sorted order@> =
	Indexes::alphabet_row(OUT, cd, 1);
	HTML_OPEN_WITH("table", "class=\"indextable\"");
	inchar32_t current_incipit = 0;
	for (int i=0; i<NL; i++) {
		index_lemma *il = lemma_list[i];
		if ((just_examples) && (il->lemma_source == BODY_LEMMASOURCE)) continue;
		if ((!just_examples) && (il->lemma_source == EG_ALT_LEMMASOURCE)) continue;
		inchar32_t incipit = Str::get_first_char(il->sorting_key);
		if (Characters::isalpha(incipit)) incipit = Characters::toupper(incipit);
		else incipit = '#';
		if (incipit != current_incipit) {
			if (current_incipit != 0) @<End a block of the index@>;
			current_incipit = incipit;
			Indexes::note_letter(cd, current_incipit);
			@<Start a block of the index@>;
		}
		@<Place an anchor for the index entry@>;
		@<Render an index entry@>;
	}
	if (current_incipit != 0) @<End a block of the index@>;
	HTML_CLOSE("table");
	Indexes::alphabet_row(OUT, cd, 2);

@<Start a block of the index@> =
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "class=\"letterblock\"");
	TEMPORARY_TEXT(inc)
	if (current_incipit == '#') WRITE_TO(inc, "NN");
	else PUT_TO(inc, current_incipit);
	HTML::anchor(OUT, inc);
	Indexes::majuscule_heading(OUT, cd, inc, TRUE);
	DISCARD_TEXT(inc)
	HTML_CLOSE("td");
	HTML_OPEN("td");

@<End a block of the index@> =
	HTML_CLOSE("td");
	HTML_CLOSE("tr");

@<Place an anchor for the index entry@> =
	TEMPORARY_TEXT(anc)
	WRITE_TO(anc, "l%d", il->allocation_id);
	HTML::anchor(OUT, anc);
	DISCARD_TEXT(anc)

@<Render an index entry@> =
	indexing_category *ic = IndexTerms::final_category(cd, il->term);
	if (ic == NULL) internal_error("no indexing category");
	IFM_example *EG = NULL;
	@<Find example relevant to this entry@>;
	TEMPORARY_TEXT(lemma_wording)
	@<Resolve backslash escapes in plain text@>;
	if (ic->cat_bracketed) @<Deal with unescaped brackets if the category makes them significant@>;
	@<Restore any escaped round brackets@>;
	@<Actually render the entry@>;
	DISCARD_TEXT(lemma_wording)

@<Find example relevant to this entry@> =
	if (il->lemma_source != BODY_LEMMASOURCE) {
		index_reference *ref;
		LOOP_OVER_LINKED_LIST(ref, index_reference, il->references)
			if (ref->posn.example)
				EG = ref->posn.example;
	}

@ Backslash before a character makes it literal. In particular we reassign
escaped open and close brackets to make them impossible to confuse with
unescaped ones:

@d SAVED_OPEN_BRACKET 0x0086  /* Unicode "start of selected area" */
@d SAVED_CLOSE_BRACKET 0x0087 /* Unicode "end of selected area" */

@<Resolve backslash escapes in plain text@> =
	text_stream *plain_text = IndexTerms::final_text(cd, il->term);
	for (int i=0, L = Str::len(plain_text); i<L; i++) {
		inchar32_t c = Str::get_at(plain_text, i);
		if (c == '\\') {
			inchar32_t n = Str::get_at(plain_text, ++i);
			if (n == '(') n = SAVED_OPEN_BRACKET;
			if (n == ')') n = SAVED_CLOSE_BRACKET;
			PUT_TO(lemma_wording, n);
		} else PUT_TO(lemma_wording, c);
	}
	Indexes::escape_HTML_characters_in(lemma_wording);

@<Deal with unescaped brackets if the category makes them significant@> =
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, lemma_wording, U"(%c*?)%(%(%+ %+%)%)(%c*)")) {
		Str::clear(lemma_wording);
		WRITE_TO(lemma_wording,
			"%S<span class=\"index%Sbracketed\">%c+ +%c</span>%S",
			mr.exp[0], ic->cat_name, SAVED_OPEN_BRACKET, SAVED_CLOSE_BRACKET, mr.exp[1]);
	}
	while (Regexp::match(&mr, lemma_wording, U"(%c*?)%(%(%- %-%)%)(%c*)")) {
		Str::clear(lemma_wording);
		WRITE_TO(lemma_wording,
			"%S<span class=\"index%Sbracketed\">%c- -%c</span>%S",
			mr.exp[0], ic->cat_name, SAVED_OPEN_BRACKET, SAVED_CLOSE_BRACKET, mr.exp[1]);
	}
	TEMPORARY_TEXT(L)
	TEMPORARY_TEXT(R)
	if (ic->cat_unbracketed == FALSE) PUT_TO(L, SAVED_OPEN_BRACKET);
	if (ic->cat_unbracketed == FALSE) PUT_TO(R, SAVED_CLOSE_BRACKET);
	while (Regexp::match(&mr, lemma_wording, U"(%c*?)%((%c*?)%)(%c*)")) {
		Str::clear(lemma_wording);
		WRITE_TO(lemma_wording,
			"%S<span class=\"index%Sbracketed\">%S%S%S</span>%S",
			mr.exp[0], ic->cat_name, L, mr.exp[1], R, mr.exp[2]);
	}
	DISCARD_TEXT(L)
	DISCARD_TEXT(R)
	Regexp::dispose_of(&mr);

@<Restore any escaped round brackets@> =
	LOOP_THROUGH_TEXT(pos, lemma_wording) {
		inchar32_t d = Str::get(pos);
		if (d == SAVED_OPEN_BRACKET) Str::put(pos, '(');
		if (d == SAVED_CLOSE_BRACKET) Str::put(pos, ')');
	}

@<Actually render the entry@> =
	int indent = 4*(il->term.no_subterms - 1); /* measured in em-spaces */
	HTML_OPEN_WITH("p", "class=\"indexentry\" style=\"margin-left: %dem;\"", indent);
	@<Render the lemma text@>;
	@<Render the category gloss@>;
	WRITE("&nbsp;&nbsp;");
	int lc = 0;
	@<Render the references@>;
	@<Render the cross-references@>;
	HTML_CLOSE("p");

@<Render the lemma text@> =
	if (il->lemma_source == EG_NAME_LEMMASOURCE) {
		HTML_OPEN("b");
		if (EG) HTML_OPEN_WITH("a", "href=\"%S\"", EG->URL);
	}
	HTML_OPEN_WITH("span", "class=\"index%S\"", ic->cat_name);
	WRITE("%S", lemma_wording);
	HTML_CLOSE("span");
	if (il->lemma_source == EG_NAME_LEMMASOURCE) {
		if (EG) HTML_CLOSE("a");
		HTML_CLOSE("b");
	}

@<Render the category gloss@> =
	if (Str::len(ic->cat_glossed) > 0)
		WRITE("&nbsp;<span class=\"indexgloss\">%S</span>", ic->cat_glossed);

@<Render the references@> =
	index_reference *ref;
	LOOP_OVER_LINKED_LIST(ref, index_reference, il->references) {
		if (lc++ > 0) WRITE(", ");

		int volume_number = ref->posn.volume_number;
		markdown_item *S = ref->posn.latest;

		IFM_example *E = ref->posn.example;
		if ((E) && (S == NULL)) S = E->cue;
		if ((S == NULL) && (E == NULL))
			internal_error("unknown destination in index reference");

		text_stream *link_class = I"indexlink";
		if (volume_number > 0) link_class = I"indexlinkalt";
		TEMPORARY_TEXT(link)
		text_stream *A = NULL;
		if (S) {
			for (int i=0; i<Str::len(S->stashed); i++) {
				inchar32_t c = Str::get_at(S->stashed, i);
				if (c == ':') break;
				if ((Characters::isdigit(c)) || (c == '.')) PUT_TO(link, c);
			}
			A = MarkdownVariations::URL_for_heading(S);
		}
		if (E) {
			if (S) WRITE_TO(link, " ");
			WRITE_TO(link, "ex %S", E->insignia);
			if (EG == NULL) A = E->URL;
		}
		Indexes::general_link(OUT, link_class, A, link);
		DISCARD_TEXT(link)
	}

@<Render the cross-references@> =
	if (LinkedLists::len(il->cross_references) > 0) {
		if (lc > 0) WRITE("; ");
		HTML_OPEN_WITH("span", "class=\"indexsee\"");
		WRITE("see ");
		if (lc > 0) WRITE("also ");
		HTML_CLOSE("span");
		int c = 0;
		index_cross_reference *xref;
		LOOP_OVER_LINKED_LIST(xref, index_cross_reference, il->cross_references) {
			if (c++ > 0) WRITE("; ");
			index_lemma *ils = IndexingData::retrieve_lemma(cd, xref->P);
			if (ils == NULL) internal_error("no such xref");
			TEMPORARY_TEXT(url)
			WRITE_TO(url, "#l%d", ils->allocation_id);
			TEMPORARY_TEXT(see)
			IndexTerms::paraphrase(see, cd, xref->P);
			Indexes::general_link(OUT, I"indexseelink", url, see);
			DISCARD_TEXT(url)
			DISCARD_TEXT(see)
		}
	}

@h Utilities.

=
void Indexes::general_link(OUTPUT_STREAM, text_stream *cl, text_stream *to, text_stream *text) {
	HTML::begin_link_with_class(OUT, cl, to);
	WRITE("%S", text);
	HTML::end_link(OUT);
}

@ =
void Indexes::escape_HTML_characters_in(text_stream *text) {
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

@h Alphabet rows.

@ =
void Indexes::note_letter(compiled_documentation *cd, inchar32_t c) {
	inchar32_t i = c - (inchar32_t) 'A';
	if (i<26) cd->id.letters_taken[i] = TRUE;
}
void Indexes::alphabet_row(OUTPUT_STREAM, compiled_documentation *cd, int sequence) {
	switch (sequence) {
		case 1:
			for (int i=0; i<26; i++)
				cd->id.letters_taken[i] = FALSE;
			break;
		case 2: {
			int faked = FALSE;
			for (int i=0; i<26; i++)
				if (cd->id.letters_taken[i] == FALSE) {
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
	if (cd->id.use_simplified_letter_rows) {
		HTML_OPEN("p");
	} else {
		HTML_OPEN_WITH("table", "class=\"fullwidth\"");
		HTML_OPEN("tr");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}
	Indexes::general_link(OUT, I"letterlink", I"#A", I"A"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#B", I"B"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#C", I"C"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#D", I"D"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#E", I"E"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#F", I"F"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#G", I"G"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#H", I"H"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#I", I"I"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#J", I"J"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#K", I"K"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#L", I"L"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#M", I"M"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#N", I"N"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#O", I"O"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#P", I"P"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#Q", I"Q"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#R", I"R"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#S", I"S"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#T", I"T"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#U", I"U"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#V", I"V"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#W", I"W"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#X", I"X"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#Y", I"Y"); @<Between@>;
	Indexes::general_link(OUT, I"letterlink", I"#Z", I"Z");
	if (cd->id.use_simplified_letter_rows) {
		HTML_CLOSE("p");
	} else {
		HTML_CLOSE("td");
		HTML_CLOSE("tr");
		HTML_CLOSE("table");
	}
}

@<Between@> =
	if (cd->id.use_simplified_letter_rows) WRITE(" / ");
	else {
		HTML_CLOSE("td");
		HTML_OPEN_WITH("td", "class=\"letterinrow\"");
	}

@ This is mainly used for the typographically dramatic link letters A, B, C, ...
but can also make fatter typographically dramatic headings, if it's stretched
in width and a longer text is supplied.

=
void Indexes::majuscule_heading(OUTPUT_STREAM, compiled_documentation *cd,
	text_stream *display_text, int single_letter) {
	if (cd->id.use_simplified_letter_rows) {
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
