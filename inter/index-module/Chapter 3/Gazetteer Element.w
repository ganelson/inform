[GazetteerElement::] Gazetteer Element.

To write the Gazetteer element (Gz) in the index.

@ =
void GazetteerElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	IndexLexicon::listing(OUT, InterpretIndex::get_lexicon(), TRUE, LD);
}
