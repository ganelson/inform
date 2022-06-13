[LexiconElement::] Lexicon Element.

To write the Lexicon element (Lx) in the index.

@ =
void LexiconElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	IndexUtilities::anchor(OUT, I"LEXICON");
	HTML_OPEN("p");
	HTML::begin_span(OUT, I"smaller");
	Localisation::roman(OUT, LD, I"Index.Elements.Lx.Explanation");
	HTML::end_span(OUT);
	HTML_CLOSE("p");
	IndexLexicon::listing(OUT, Indexing::get_lexicon(session), FALSE, LD);
}
