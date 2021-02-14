[IXAdjectives::] Adjectives.

To index adjectives.

@

=
void IXAdjectives::print(OUTPUT_STREAM, adjective_meaning *am) {
	@<Index the domain of validity of the AM@>;
	if (am->negated_from) {
		wording W = Adjectives::get_nominative_singular(am->negated_from->owning_adjective);
		WRITE(" opposite of </i>%+W<i>", W);
	} else {
		if ((AdjectiveMeanings::nonstandard_index_entry(OUT, am) == FALSE) &&
			(Wordings::nonempty(am->indexing_text)))
			WRITE("%+W", am->indexing_text);
	}
	if (Wordings::nonempty(am->indexing_text))
		Index::link(OUT, Wordings::first_wn(am->indexing_text));
}

@ This is supposed to imitate dictionaries, distinguishing meanings by
concisely showing their usage. Thus "empty" would have indexed entries
prefaced "(of a rulebook)", "(of an activity)", and so on.

@<Index the domain of validity of the AM@> =
	if (am->domain.domain_infs)
		WRITE("(of </i>%+W<i>) ",
			InferenceSubjects::get_name_text(am->domain.domain_infs));
