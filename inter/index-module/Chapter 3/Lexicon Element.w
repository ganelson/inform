[LexiconElement::] Lexicon Element.

To write the Lexicon element (Lx) in the index.

@ =
void LexiconElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	IndexUtilities::anchor(OUT, I"LEXICON");
	HTML_OPEN("p");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	Localisation::roman(OUT, LD, I"Index.Elements.Lx.Explanation");
	HTML_CLOSE("span");
	HTML_CLOSE("p");
	IndexLexicon::listing(OUT, InterpretIndex::get_lexicon(), FALSE, LD);
}
