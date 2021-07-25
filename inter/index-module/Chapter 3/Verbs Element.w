[VerbsElement::] Verbs Element.

To write the Verbs element (Vb) in the index.

@ This is an uninspired corner of the index, but it's hard to think what would
be more usefully informative.

=
void VerbsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	HTML_OPEN("p");
	Localisation::italic_0(OUT, LD, I"Index.Elements.Vb.About");	
	HTML_CLOSE("p");

	int verb_count = 0;
	inter_lexicon *lexicon = InterpretIndex::get_lexicon();
	for (index_lexicon_entry *lex = lexicon->first; lex; lex = lex->sorted_next)
		if ((lex->part_of_speech == VERB_TLEXE) ||
			(lex->part_of_speech == MVERB_TLEXE) ||
			(lex->part_of_speech == PREP_TLEXE)) {
			text_stream *entry_text = lex->lemma;
			HTML_OPEN_WITH("p", "class=\"hang\"");
			IndexUtilities::anchor_numbered(OUT, 10000+verb_count++); /* anchors from 10000: see above */
			text_stream *key;
			if (lex->part_of_speech == VERB_TLEXE) key = I"Index.Elements.Vb.To";
			else if (lex->part_of_speech == MVERB_TLEXE) key = I"Index.Elements.Vb.To";
			else if (lex->part_of_speech == PREP_TLEXE) key = I"Index.Elements.Vb.ToBe";
			else key = I"Index.Elements.Vb.ToBeAbleTo";
			Localisation::write_1(OUT, LD, key, entry_text);
			IndexUtilities::link_package(OUT, lex->lex_package);
			WRITE(" ... ");
			if (lex->part_of_speech == MVERB_TLEXE)
				Localisation::italic_0(OUT, LD, I"Index.Elements.Vb.ForSayingOnly");
			else WRITE("%S", Metadata::read_optional_textual(lex->lex_package, I"^meaning"));
			HTML_CLOSE("p");
			VerbsElement::tabulate(OUT, lex, I"^present", I"Index.Elements.Vb.Present", LD);
			VerbsElement::tabulate(OUT, lex, I"^past", I"Index.Elements.Vb.Past", LD);
			VerbsElement::tabulate(OUT, lex, I"^present_perfect", I"Index.Elements.Vb.Perfect", LD);
			VerbsElement::tabulate(OUT, lex, I"^past_perfect", I"Index.Elements.Vb.PastPerfect", LD);
		}
}

void VerbsElement::tabulate(OUTPUT_STREAM, index_lexicon_entry *lex, text_stream *key,
	text_stream *tense, localisation_dictionary *LD) {
	text_stream *val = Metadata::read_optional_textual(lex->lex_package, key);
	if (Str::len(key) > 0) {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("<i>");
		Localisation::italic_0(OUT, LD, tense);
		WRITE("</i>&nbsp;%S", val);
		HTML_CLOSE("p");
	}
}
