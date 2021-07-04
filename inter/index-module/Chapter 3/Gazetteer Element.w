[GazetteerElement::] Gazetteer Element.

To write the Gazetteer element (Gz) in the index.

@ =
void GazetteerElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	IndexLexicon::stock(I);
	IndexLexicon::listing(OUT, TRUE);
}
