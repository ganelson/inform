[LexiconElement::] Lexicon Element.

To write the Lexicon element (Lx) in the index.

@ =
void LexiconElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	TempLexicon::stock(I);
	Index::anchor(OUT, I"LEXICON");
	HTML_OPEN("p");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	WRITE("For instance, the description 'an unlocked door' is made "
		"up from the adjective 'unlocked' and the noun 'door', both of which "
		"can be found below. Property adjectives, like 'open', can be used "
		"when creating things - 'In the Ballroom is an open container' is "
		"allowed because 'open' is a property - but those with complicated "
		"definitions, like 'empty', can only be tested during play, e.g. "
		"with rules like 'Instead of taking an empty container, ...'.");
	HTML_CLOSE("span");
	HTML_CLOSE("p");
	TempLexicon::listing(OUT, FALSE);
}
