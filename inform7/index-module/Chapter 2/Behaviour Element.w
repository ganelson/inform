[IXBehaviour::] Behaviour Element.

To index relations.

@ A brief table of relations appears on the Phrasebook Index page.

=
void IXBehaviour::render(OUTPUT_STREAM) {
	named_action_pattern *nap;
	int num_naps = NUMBER_CREATED(named_action_pattern);

	if (num_naps == 0) {
		HTML_OPEN("p");
		WRITE("No names for kinds of action have yet been defined.");
		HTML_CLOSE("p");
	}

	LOOP_OVER(nap, named_action_pattern) {
		HTML_OPEN("p"); WRITE("<b>%+W</b>", Nouns::nominative_singular(nap->as_noun));
		Index::link(OUT, Wordings::first_wn(nap->text_of_declaration));
		HTML_TAG("br");
		WRITE("&nbsp;&nbsp;<i>defined as any of the following acts:</i>\n");
		named_action_pattern_entry *nape;
		LOOP_OVER_LINKED_LIST(nape, named_action_pattern_entry, nap->patterns) {
			action_pattern *ap = nape->behaviour;
			HTML_TAG("br");
			WRITE("&nbsp;&nbsp;&nbsp;&nbsp;%+W", ap->text_of_pattern);
			Index::link(OUT, Wordings::first_wn(ap->text_of_pattern));
		}
		HTML_CLOSE("p");
	}
}

