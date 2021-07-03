[VerbsElement::] Verbs Element.

To write the Verbs element (Vb) in the index.

@

=
void VerbsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	TempLexicon::stock(I);
	HTML_OPEN("p"); WRITE("Verbs listed as \"for saying only\" are values of the kind \"verb\" "
		"and can be used in adaptive text, but they have no meaning to Inform, so "
		"they can't be used in sentences about what's in the story.");
	HTML_CLOSE("p");
	int verb_count = 0;
	for (index_tlexicon_entry *lex = sorted_tlexicon; lex; lex = lex->sorted_next)
		if ((lex->part_of_speech == VERB_TLEXE) ||
			(lex->part_of_speech == MVERB_TLEXE) ||
			(lex->part_of_speech == PREP_TLEXE)) {
			text_stream *entry_text = lex->lemma;
			HTML_OPEN_WITH("p", "class=\"hang\"");
			Index::anchor_numbered(OUT, 10000+verb_count++); /* anchors from 10000: see above */
			if (lex->part_of_speech == VERB_TLEXE) WRITE("To <b>%S</b>", entry_text);
			else if (lex->part_of_speech == MVERB_TLEXE) WRITE("To <b>%S</b>", entry_text);
			else if (lex->part_of_speech == PREP_TLEXE) WRITE("To be <b>%S</b>", entry_text);
			else WRITE("To be able to <b>%S</b>", entry_text);
			int at = (int) Metadata::read_optional_numeric(lex->lex_package, I"^at");
			if (at > 0) Index::link(OUT, at);
			if (lex->part_of_speech == MVERB_TLEXE) WRITE(" ... for saying only");
			else WRITE(" ... <i>%S</i>", Metadata::read_optional_textual(lex->lex_package, I"^meaning"));
			HTML_CLOSE("p");
			VerbsElement::tabulate_verbs(OUT, lex, I"^present", "present");
			VerbsElement::tabulate_verbs(OUT, lex, I"^past", "past");
			VerbsElement::tabulate_verbs(OUT, lex, I"^present_perfect", "present perfect");
			VerbsElement::tabulate_verbs(OUT, lex, I"^past_perfect", "past perfect");
		}
}

void VerbsElement::tabulate_verbs(OUTPUT_STREAM, index_tlexicon_entry *lex, text_stream *key, char *tensename) {
	text_stream *val = Metadata::read_optional_textual(lex->lex_package, key);
	if (Str::len(key) > 0) {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("<i>%s:</i>&nbsp;%S", tensename, val);
		HTML_CLOSE("p");
	}
}
