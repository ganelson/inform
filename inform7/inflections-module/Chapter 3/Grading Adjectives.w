[Grading::] Grading Adjectives.

To inflect adjectives into comparative and superlative forms.

@h Constructing comparatives.
In English, the comparative of an adjective can generally be formed by
suffixing the inflected form with "than"; thus, "big" to "bigger than".
The following does the suffixing:

=
<comparative-construction> ::=
	... than

@ =
wording Grading::make_comparative(wording W, PREFORM_LANGUAGE_TYPE *nl) {
	TEMPORARY_TEXT(comprised);
	TEMPORARY_TEXT(transformed);
	if (*(Lexer::word_text(Wordings::first_wn(W))) == '\"')
		WRITE_TO(comprised, "some-long-text");
	else
		WRITE_TO(comprised, "%N", Wordings::first_wn(W));
	if (nl == NULL) nl = English_language;
	match_avinue *comp_trie =
		Preform::Nonparsing::define_trie(<adjective-to-comparative>, TRIE_END, nl);
	Inflections::suffix_inflection(transformed, comp_trie, comprised);
	wording PW = Feeds::feed_stream(transformed);
	word_assemblage merged =
		Preform::Nonparsing::merge(<comparative-construction>, 0,
			WordAssemblages::from_wording(PW));
	PW = WordAssemblages::to_wording(&merged);
	LOGIF(CONSTRUCTED_PLURALS, "[Comparative of %W is %W]\n", W, PW);
	DISCARD_TEXT(transformed);
	DISCARD_TEXT(comprised);
	return PW;
}

wording Grading::make_superlative(wording W, PREFORM_LANGUAGE_TYPE *nl) {
	TEMPORARY_TEXT(comprised);
	TEMPORARY_TEXT(transformed);
	if (*(Lexer::word_text(Wordings::first_wn(W))) == '\"')
		WRITE_TO(comprised, "some-long-text");
	else
		WRITE_TO(comprised, "%N", Wordings::first_wn(W));
	if (nl == NULL) nl = English_language;
	match_avinue *comp_trie =
		Preform::Nonparsing::define_trie(<adjective-to-superlative>, TRIE_END, nl);
	Inflections::suffix_inflection(transformed, comp_trie, comprised);
	wording PW = Feeds::feed_stream(transformed);
	LOGIF(CONSTRUCTED_PLURALS, "[Superlative of %W is %W]\n", W, PW);
	DISCARD_TEXT(transformed);
	DISCARD_TEXT(comprised);
	return PW;
}

@ There has to be a better term than "quiddity" for this grammatical construct,
but what I mean is the property for which the given adjective makes a
comparison: for instance, "tallness" for "tall", or "steeliness" for
"steely".

=
wording Grading::make_quiddity(wording W, PREFORM_LANGUAGE_TYPE *nl) {
	TEMPORARY_TEXT(comprised);
	TEMPORARY_TEXT(transformed);
	if (*(Lexer::word_text(Wordings::first_wn(W))) == '\"')
		WRITE_TO(comprised, "some-long-text");
	else
		WRITE_TO(comprised, "%N", Wordings::first_wn(W));
	if (nl == NULL) nl = English_language;
	match_avinue *comp_trie =
		Preform::Nonparsing::define_trie(<adjective-to-quiddity>, TRIE_END, nl);
	Inflections::suffix_inflection(transformed, comp_trie, comprised);
	wording PW = Feeds::feed_stream(transformed);
	LOGIF(CONSTRUCTED_PLURALS, "[Quiddity of %W is %W]\n", W, PW);
	DISCARD_TEXT(transformed);
	DISCARD_TEXT(comprised);
	return PW;
}
