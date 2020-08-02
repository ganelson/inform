[Plurals::] Pluralisation Requests.

Special sentences for setting exotic plural forms of nouns.

@ Sentences like "the plural of cherub is cherubim" are hardly needed now,
because the //inflections// module now contains a full implementation of
Conway's algorithm. Still, we keep the syntax around, and it may one day be
useful again for languages other than English.

The subject phrase must match:

=
<plural-sentence-subject> ::=
	<article> plural of <np-articled> |  ==> { pass 2 }
	plural of <np-articled>              ==> { pass 1 }

@ Note that we are saved later grief by not allowing a plural form which
would be illegal as a new noun: allowing "The plural of thing is ," would not
end well.

Otherwise, though, we simply send the request to //inflections: Pluralisation//.

=
int Plurals::plural_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The plural of seraph is seraphim." */
		case ACCEPT_SMFT:
			if (<plural-sentence-subject>(SW)) {
				V->next = <<rp>>;
				<np-unparsed>(OW);
				V->next->next = <<rp>>;
				wording S = Node::get_text(V->next);
				wording P = Node::get_text(V->next->next);
				@<Forbid plural declarations containing quoted text@>;
				if (Assertions::Creator::vet_name_for_noun(P) == FALSE) return TRUE;
				Pluralisation::register(S, P, DefaultLanguage::get(NULL));
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ In general names of things which we need plurals for cannot contain quoted
text anyway, so the following problem messages are not too gratuitous.

@<Forbid plural declarations containing quoted text@> =
	LOOP_THROUGH_WORDING(i, S)
		if (Vocabulary::test_flags(i, TEXT_MC + TEXTWITHSUBS_MC)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_PluralOfQuoted),
				"declares a plural for a phrase containing quoted text",
				"which is forbidden. Sentences like this are supposed to "
				"declare plurals without quotation marks: for instance, "
				"'The plural of attorney general is attorneys general.'");
			return TRUE;
		}
	LOOP_THROUGH_WORDING(i, P)
		if (Vocabulary::test_flags(i, TEXT_MC + TEXTWITHSUBS_MC)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_PluralIsQuoted),
				"declares a plural for a phrase using quoted text",
				"which is forbidden. Sentences like this are supposed to "
				"declare plurals without quotation marks: for instance, "
				"'The plural of procurator fiscal is procurators fiscal.'");
			return TRUE;
		}
