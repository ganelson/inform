[GazetteerElement::] Gazetteer Element.

To write the Gazetteer element (Gz) in the index.

@ =
void GazetteerElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	IndexLexicon::listing(OUT, Indexing::get_lexicon(session), TRUE, LD);
}
