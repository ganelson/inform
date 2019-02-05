[Plurals::] Plural Dictionary.

To parse sentences like "The plural of woman is women".

@h Stocking the plurals dictionary.
The user gives us plurals with special sentences, whose subject is like so:

=
<plural-sentence-subject> ::=
	<article> plural of <nounphrase-articled> |				==> TRUE; *XP = RP[2]
	plural of <nounphrase-articled>							==> TRUE; *XP = RP[1]

@ We take immediate action on parsing the sentence, and after that ignore it
as having been dealt with.

Note that we are entirely allowed to register a new plural for a phrase
which already has a plural in the dictionary, which is why we do not
trouble to search the existing dictionary here.

=
int Plurals::plural_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The plural of woman is women." */
		case ACCEPT_SMFT:
			FSW = SW; FOW = OW;
			if (<plural-sentence-subject>(SW)) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				V->next = <<rp>>;
				<nounphrase>(OW);
				V->next->next = <<rp>>;
				wording S = ParseTree::get_text(V->next);
				wording P = ParseTree::get_text(V->next->next);
				@<Forbid plural declarations containing quoted text@>;
				if (Assertions::Creator::vet_name_for_noun(P) == FALSE) return TRUE;
				Pluralisation::register(S, P, English_language);
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
		if (Vocabulary::test_flags(i, TEXT_MC+TEXTWITHSUBS_MC)) {
			Problems::Issue::sentence_problem(_p_(PM_PluralOfQuoted),
				"declares a plural for a phrase containing quoted text",
				"which is forbidden. Sentences like this are supposed to "
				"declare plurals without quotation marks: for instance, "
				"'The plural of attorney general is attorneys general.'");
			return TRUE;
		}
	LOOP_THROUGH_WORDING(i, P)
		if (Vocabulary::test_flags(i, TEXT_MC+TEXTWITHSUBS_MC)) {
			Problems::Issue::sentence_problem(_p_(PM_PluralIsQuoted),
				"declares a plural for a phrase using quoted text",
				"which is forbidden. Sentences like this are supposed to "
				"declare plurals without quotation marks: for instance, "
				"'The plural of procurator fiscal is procurators fiscal.'");
			return TRUE;
		}
