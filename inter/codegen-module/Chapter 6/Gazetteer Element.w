[GazetteerElement::] Gazetteer Element.

To write the Gazetteer element (Gz) in the index.

@ =
void GazetteerElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	TempLexicon::stock(I);
	TempLexicon::listing(OUT, TRUE);
}
