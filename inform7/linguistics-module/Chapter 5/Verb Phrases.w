[VerbPhrases::] Verb Phrases.

To construct standard verb-phrase nodes in the parse tree.

@h Regular and existential verb phrases.
Here we address the general case of an assertion sentence with a primary verb
in it. Note that we must expect at least some of the noun phrases in these
sentences to be previously unknown. To parse

>> The coral snake is in the green bucket.

at a time when neither snake nor bucket has been mentioned before, we
really have little option but to look for "is" plus preposition,
and cannot use the words either side as any support for the hypothesis
that this is indeed the verb.

Perhaps surprisingly we will choose to regard the "in" here as being
part of the object phrase for the sentence. It might seem to belong to
the verb rather than to a noun phrase, but an implementation motivated
by that wouldn't work, for two reasons. First, English allows subject-verb
inversions such as "In the green bucket is the coral snake", where the
"in" has moved some distance from the verb "is". Second, we have to allow
some use of zeugma. Zeugma is sometimes thought to be rare in English and
to be basically a comedy effect, as in the famous Flanders and Swann lyric:

>> She made no reply, up her mind, and a dash for the door.

in which three completely different senses of the same verb are used,
but in which the verb appears only once. It might seem reasonable for a
language like Inform simply to disallow this. Unfortunately, less
extreme zeugmas occur all the time:

>> The red door is west of the Dining Room and east of the Ballroom.

So we will have to allow information about relationships to annotate
noun phrases, not just verb phrases.

@ We will use the term "existential" for a "there is..." sentence such as:

>> There are four coins on the table.

The subject here is the meaningless noun phrase "there". English is defective
in not allowing optional subjects: it would be more logical to say "if an open
door is", but in fact we say "if there is an open door".

Note that we will recognise "there" as a placeholder only in the subject
position. English does allow it as an object, but then it's anaphoric,
referring back to a previously discussed place -- "I go into the lobby.
Julia is there." Since Inform can't handle anaphora, this isn't for us.

The most difficult existential sentences are those involving a second
verb, such as:

>> There are four coins which are on the table.

The noun phrase of an existential sentence is recognised thus:

=
<s-existential-np> ::=
	there							==> Node::new(UNKNOWN_NT);

@ We will want to spot adverbs of certainty adjacent to the verb itself;
English allows these either side, so "A man is usually happy" and "Peter
certainly is happy" are both possible. Note that these adverbs can divide
a verb from its preposition(s): consider "The rain in Spain lies mainly in
the plain", where "mainly" divides "lies" from "in".

=
<pre-verb-certainty> ::=
	... <certainty>					==> R[1]

<post-verb-certainty> ::=
	<certainty> ...					==> R[1]

@ Relative clauses ("a woman who is on the stage") are detected by the presence
of a marker word before the verb (in this example, "who"). Of course, such
a word doesn't always mean we have a relative clause, so we will need to be a
little careful using this nonterminal.

=
<relative-clause-marker> ::=
	which/who/that

<pre-verb-rc-marker> ::=
	... <relative-clause-marker>

@ For purely pragmatic reasons, we'll want to avoid reading prepositions (and
thus implicit relative clauses, such as "the cat in the hat") where they occur
after the word "called" in a sentence. For example, "a cat called Puss in
Boots" must not be thought to be in Boots.

=
<phrase-with-calling> ::=
	... called ...

@h Main nonterminal.
And so this nonterminal turns a sentence into a small parse tree. Between 2010
and early 2016, this was implemented in straight Preform rather than as an
internal, but that became simply too complicated to maintain once imperative
verbs were added to the grammar. Still, it was a pity.

=
<sentence> internal {
	if (VerbPhrases::tracing()) { LOG("Parsing the sentence: %W\n", W); LOG_INDENT; }
	int rv = VerbPhrases::seek(W, X, XP, 0);
	if (VerbPhrases::tracing()) {
		LOG_OUTDENT;
		if (rv) {
			LOG("Passed\n"); LOG_INDENT;
			for (parse_node *N = *XP; N; N = N->next) LOG("$T", N);
			LOG_OUTDENT;
		} else LOG("Failed\n");
	}
	return rv;
}

@ The following routine is only very slightly recursive. It's used either
as above, to parse a whole sentence like "The coral snake is in the green
bucket", or else is called (once) from within itself to parse just the
"four coins which are on the table" part of a difficult existential sentence
such as "There are four coins which are on the table."

In the latter case, the call parameter |existential_OP_edge| will be the word
number of the last word which can be safely considered as a possible
preposition. (That would just be the position of the word "table", in this
example, but in a sentence such as "There is a cat called Puss in Boots" the
last safe preposition position is "cat", the word before "called".)

The sequence in which usages are considered is very important, since we are
going to return the first legal usage found. We also want to be reasonably
efficient in minimising the number of comparisons. We therefore first map out
which word positions might be the beginning of verb phrases.

@d VIABILITY_MAP_SIZE 100

=
int VerbPhrases::seek(wording W, int *X, void **XP, int existential_OP_edge) {
	int viable[VIABILITY_MAP_SIZE];
	@<Calculate the viability map@>;
	if (VerbPhrases::tracing()) @<Log the viability map@>;
	@<Seek verb usages@>;
	return FALSE;
}

@ If the word at position |i| doesn't occur in any verb known to us, then
that has viability 0. Otherwise: if this position is outside of any brackets,
the viability is 1, and if it's inside, then 2; except that if the position
is one where a negated verb other than "to be" can be found, then we blank
that stretch of words out with 3s. This blanking out enables us to skip over
negations like the "does not have" in

>> The Solomon Islands does not have an air force.

and to avoid matching the subsequent "have". But the copular verb "to be" is
exempt from this. For the time being, if we see something like "Velma is not a
thinker" then we will parse it as "(Velma) is (not a thinker)", allowing "not
a thinker" to be a noun phrase. Assertions are generally supposed to be
positive statements, not negative ones, but we don't necessarily know about
this one yet. If "thinker" is an either/or property with a single possible
antonym -- "doer", let's say -- then we want to construe this sentence as if
it read "Velma is a doer". So, anyway, we allow "not" at the front of the
object noun phrase, and disallow "is not" and "are not" in order that this can
happen.

For example,

>> The soldier can see that (this is true) they do not carry rifles.

produces
= (text)
	viable map: the[1] -- can[1] see[1] -- ([2] -- is[2] -- )[1] -- do[3] not[3] carry[3] --
=
Note that we sometimes get false positives when testing whether the word occurs
in a verb (hence the way open bracket is marked here), but that doesn't matter,
since non-zero-ness in the viability map is used only to speed up parsing.

@<Calculate the viability map@> =
	for (int i=0; (i<=Wordings::length(W)) && (i<VIABILITY_MAP_SIZE); i++) viable[i] = 0;
	int bl = 0;
	LOOP_THROUGH_WORDING(pos, W) {
		if (pos == existential_OP_edge) break;
		if ((Lexer::word(pos) == OPENBRACKET_V) || (Lexer::word(pos) == OPENBRACE_V)) bl++;
		if ((Lexer::word(pos) == CLOSEBRACKET_V) || (Lexer::word(pos) == CLOSEBRACE_V)) bl--;
		int i = pos - Wordings::first_wn(W);
		if (i >= VIABILITY_MAP_SIZE) break;
		if (NTI::test_vocabulary(Lexer::word(pos), <meaningful-nonimperative-verb>) == FALSE) viable[i] = 0;
		else {
			if (bl == 0) viable[i] = 1; else viable[i] = 2;
			int pos_to = -(<negated-noncopular-verb-present>(Wordings::from(W, pos)));
			if (pos_to > pos) {
				while (pos_to >= pos) {
					if (i < VIABILITY_MAP_SIZE) viable[i] = 3;
					pos++, i++;
				}
				pos--;
			}
			if (((viable[i] == 1) || (viable[i] == 2)) && (existential_OP_edge > 0)) {
				wording S = Wordings::up_to(W, pos - 1);
				if (<pre-verb-rc-marker>(S) == FALSE) viable[i] = 0;
			}
		}
	}

@<Log the viability map@> =
	LOG("viable map: ");
	LOOP_THROUGH_WORDING(pos, W) {
		int i = pos - Wordings::first_wn(W);
		if (i >= VIABILITY_MAP_SIZE) break;
		if (viable[i]) LOG("%W[%d] ", Wordings::one_word(pos), viable[i]);
		else LOG("-- ");
	}
	LOG("\n");

@ We are in fact interested only in word positions with viability 1 or 2, and
in practice viability 2 positions are very unlikely to be correct, so we
will first make every effort to match a verb at a viability 1 position.
(Why do we allow viability 2 matches at all? Really just so that we can
report them as problems.)

Within that constraint, we check in two passes. On pass 1, we skip over any
verb usage which might be part of a relative clause, in that it's preceded
by a relative clause marker; on pass 2, should we ever get that far, this
restriction is lifted. Thus for example in the sentence

>> A man who does not carry an octopus is happy.

we would skip over the words of "does not carry" on pass 1 because they are
preceded by "who". The reason we go on to pass 2 is not that relative clauses
are ever allowed here: they aren't. It's that we might have misunderstood
the relative clause marker. For example, in

>> Telling it that is gossipy behaviour.

the "that" doesn't introduce a relative clause; "telling it that" is a
well-formed noun phrase.

Within each pass, we try each priority tier in turn (except the priority 0
tier, which is never allowed). Within each tier, we look for the leftmost
position of the current viability at which a verb usage occurs, and if two
such occur at the same position, we take the longer (or if they are of
equal length, the earliest defined).

The reason we need tiers is that many plausible sentences contain multiple
apparent uses of verbs. Consider:

>> Fred has carrying capacity 2.

where "has" and "carrying" could each be read as part of a verb phrase.
(In Inform, "To have" is on a higher tier than "to carry".) Or:

>> The Fisher-Price carry cot is a container.

In this sentence, "carry" is intended as part of the subject noun phrase,
but Inform has no way of telling that: if we didn't give "to be" priority
over "to carry" we would construe this sentence as saying that a group of
people called The Fisher-Price, perhaps a rock group, are carrying an
object called "cot is a container", perhaps their new EP of remixed
techno lullabies. (Far fewer plausible noun phrases contain "is" than
contain other verbs such as "carry".)

@<Seek verb usages@> =
	for (int viability_level = 1; viability_level <= 2; viability_level++)
		for (int pass = 1; pass <= 2; pass++)
			for (verb_usage_tier *tier = first_search_tier; tier; tier = tier->next_tier)
				if (tier->priority != 0)
					LOOP_THROUGH_WORDING(pos, W) {
						int j = pos - Wordings::first_wn(W);
						if ((j<VIABILITY_MAP_SIZE) && (viable[j] != viability_level)) continue;
						wording TW = Wordings::from(W, pos);
						for (verb_usage *vu = tier->tier_contents; vu; vu = vu->next_within_tier)
							@<Consider whether this usage is being made at this position@>;
					}

@ At this point |TW| is the tail of the wording: its first word is what we
think might be the verb. For example, given

>> The coral snake is in the green bucket.

we might have "is in the green bucket". We must test whether our verb usage
appears at the front of |TW|, and if so, whether it's meaningful. But in
fact we will make these checks in reverse order, for efficiency's sake.
(There are potentially a great many meaningless verbs, because of the
way adaptive text is handled in Inform.)

A further complication is that we will reject this usage if it occurs
somewhere forbidden: for example, if a verb form is only allowed in an SVO
configuration, we will ignore it if |TW| is the whole of |W|, because then the
verb would begin at the first word of the sentence. Conversely, if it is only
allowed in an imperative VO configuration, it's required to be there. Thus if
the whole sentence is "Carries Peter" then we won't match "carries", because
it's at the front; and if it's "Peter test me with flash cards", we won't
match "test... with..." because it's not at the front.

@<Consider whether this usage is being made at this position@> =
	verb_identity *vi = vu->verb_used;
	int i = -1;
	wording ISW = EMPTY_WORDING, IOW = EMPTY_WORDING;
	int certainty = UNKNOWN_CE, pre_certainty = UNKNOWN_CE, post_certainty = UNKNOWN_CE;
	for (verb_form *vf = vi->list_of_forms; vf; vf = vf->next_form) {
		verb_meaning *vm = &(vf->list_of_senses->vm);
		if (VerbMeanings::is_meaningless(vm) == FALSE) {
			if (i < 0) {
				i = VerbUsages::parse_against_verb(TW, vu);
				if (!((i>Wordings::first_wn(TW)) && (i<=Wordings::last_wn(TW)))) break;
				if (vf->form_structures & (VO_FS_BIT + VOO_FS_BIT)) {
					if (pos > Wordings::first_wn(W)) break;
				} else {
					if (pos == Wordings::first_wn(W)) break;
				}
				@<Now we definitely have the verb usage at the front@>;
			}
			@<Check whether the rest of the verb form pans out@>;
		}
	}

@ So now we know that the verb definitely appears. We form |ISW| as the
wording for the subject phrase and |IOW| the object phrase. Adverbs of
certainty are removed from these.

@<Now we definitely have the verb usage at the front@> =
	ISW = Wordings::up_to(W, pos-1);
	IOW = Wordings::from(W, i);
	if (<pre-verb-certainty>(ISW)) {
		pre_certainty = <<r>>;
		ISW = GET_RW(<pre-verb-certainty>, 1);
	}
	if (<post-verb-certainty>(IOW)) {
		post_certainty = <<r>>;
		IOW = GET_RW(<post-verb-certainty>, 1);
	}
	certainty = pre_certainty;
	if (certainty == UNKNOWN_CE) certainty = post_certainty;
	if (VerbPhrases::tracing()) LOG("Found usage, pass %d tier %d: (%W) $w (%W)\n",
		pass, tier->priority, ISW, vi, IOW);

@  If the verb form is, say, "place in ... with ...", and we have detected the
verb as "places" in the sentence "Henry places the cherry on the cake", we
still must reject this usage because it's missing the essential prepositions
"in" and "with". (It would, however, pass if the verb form were "place... on...".)

This is also where we detect whether we have an existential sentence such as
"There is a man in the Dining Room." If so, we will have to allow for the
preposition "in" to be divided from the verb "is". But we will first check
(by using our one level of recursion) whether the tail of the sentence makes
sense in its own right. In this example it doesn't, but for "There is a man
who is in the Dining Room" (note the additional "is"), it would.

@<Check whether the rest of the verb form pans out@> =
	wording SW = ISW, OW = IOW, O2W = EMPTY_WORDING;
	wording VW = Wordings::up_to(TW, Wordings::first_wn(OW) - 1);

	if (existential_OP_edge > 0) { /* i.e., if we are looking for "(S which) verbs (O)" */
		if (<pre-verb-rc-marker>(SW)) { /* there is indeed a "which" at the end of |SW| */
			SW = GET_RW(<pre-verb-rc-marker>, 1); /* so trim it off */
			if (VerbPhrases::tracing())
				LOG("Trimmed to: (%W) $w (%W)\n", SW, vi, OW);
		}
	}

	preposition_identity *prep = vf->preposition;
	preposition_identity *second_prep = vf->second_clause_preposition;

	preposition_identity *required_first = prep;
	preposition_identity *required_second = second_prep;

	int existential = FALSE, structures = vf->form_structures, last_preposition_position = Wordings::last_wn(OW);

	if ((existential_OP_edge == 0) && (vi == copular_verb) && (required_second == NULL) &&
		(<s-existential-np>(SW))) {
		if (<phrase-with-calling>(OW))
			last_preposition_position = Wordings::last_wn(GET_RW(<phrase-with-calling>, 1));
		int rv = VerbPhrases::seek(OW, X, XP, last_preposition_position);
		if (rv) return rv;
		existential = TRUE; structures = SVOO_FS_BIT; required_first = NULL; required_second = prep;
	}

	@<Check whether we do indeed have these required prepositions in place@>;

	/* we couldn't check for this before, since we need to skip past the prepositions too */
	if ((pass == 1) && (<pre-verb-rc-marker>(SW))) { pos = Wordings::first_wn(OW) - 1; continue; }

	@<Check whether any sense of this verb form will accept this usage and succeed if so@>;

@ This part at least is boringly straightforward.

@<Check whether we do indeed have these required prepositions in place@> =
	int usage_succeeds = TRUE;
	if (required_first) {
		usage_succeeds = FALSE;
		if (!((required_first->allow_unexpected_upper_case == FALSE) &&
			(Word::unexpectedly_upper_case(Wordings::first_wn(OW)))))
			if (WordAssemblages::is_at(&(required_first->prep_text),
					Wordings::first_wn(OW), Wordings::last_wn(TW))) {
				OW = Wordings::from(OW,
					Wordings::first_wn(OW) + WordAssemblages::length(&(required_first->prep_text)));
				VW = Wordings::up_to(TW, Wordings::first_wn(OW) - 1);
				usage_succeeds = TRUE;
			}
		if (usage_succeeds == FALSE) {
			if (VerbPhrases::tracing()) LOG("$w + $p + $p : failed for lack of $p\n",
				vi, prep, second_prep, prep);
			continue;
		}
	}

	if (required_second) {
		usage_succeeds = FALSE;
		int found = -1;
		for (int j=Wordings::first_wn(OW) + 1; j < last_preposition_position; j++) {
			wording TOW = Wordings::from(OW, j);
			if (WordAssemblages::is_at(&(required_second->prep_text),
				Wordings::first_wn(TOW), Wordings::last_wn(TOW))) {
				found = j; break;
			}
		}
		if (found >= 0) {
			if (existential) SW = Wordings::up_to(OW, found-1);
			else O2W = Wordings::up_to(OW, found-1);
			OW = Wordings::from(OW, found + WordAssemblages::length(&(required_second->prep_text)));
			usage_succeeds = TRUE;
		}
		if (usage_succeeds == FALSE) {
			if (VerbPhrases::tracing()) LOG("$w + $p + $p : failed for lack of $p\n",
				vi, prep, second_prep, second_prep);
			continue;
		}
	}

@ Now we're getting somewhere. The verb and any prepositions required by this
form are all in place, and we know this would be a meaningful sentence. So
we start building the diagram tree for the sentence at last, with the node
representing the verb.

@<Check whether any sense of this verb form will accept this usage and succeed if so@> =
	int possessive = FALSE;
	if (VerbMeanings::get_relational_meaning(vm) == VERB_MEANING_POSSESSION)
		possessive = TRUE;
	parse_node *VP_PN = Node::new(VERB_NT);
	if (certainty != UNKNOWN_CE)
		Annotations::write_int(VP_PN, verbal_certainty_ANNOT, certainty);
	if (vu) Node::set_verb(VP_PN, vu);
	Node::set_preposition(VP_PN, prep);
	Node::set_second_preposition(VP_PN, second_prep);

	Node::set_text(VP_PN, VW);
	if (possessive) Annotations::write_int(VP_PN, possessive_verb_ANNOT, TRUE);
	if (existential) Annotations::write_int(VP_PN, sentence_is_existential_ANNOT, TRUE);
	if ((pre_certainty != UNKNOWN_CE) && (post_certainty != UNKNOWN_CE))
		Annotations::write_int(VP_PN, linguistic_error_here_ANNOT, TwoLikelihoods_LINERROR);

	VP_PN = VerbPhrases::accept(vf, VP_PN, SW, OW, O2W);
	if (VP_PN) {
		*XP = VP_PN;
		if (VerbPhrases::tracing())
			LOG("Accepted as $w + $p + $p\n", vi, prep, second_prep);
		return TRUE;
	} else {
		if (VerbPhrases::tracing())
			LOG("Rejected as $w + $p + $p\n", vi, prep, second_prep);
	}

@ This routine completes the sentence diagram by adding further nodes to
represent the subject and object phrases. How this is done depends on the
sense of the verb: for example, in Inform, "X is an activity" produces a
rather different subtree to "Peter is a man". What happens is that each
possible sense of the verb form (in this case "is" with no prepositions)
is tried in turn: each one is asked, in effect, do you want this sentence?

This is where, at last, special sentence meaning functions come into their
own: they are called with the task |ACCEPT_SMFT| to see if they are willing
to accept this sentence, whose noun phrases are stored in the |NPs| array.
If they do want it, they should build the necessary diagram and return |TRUE|.

If all the special meanings decline, we can fall back on a regular meaning.

@d MAX_NPS_IN_VP 3

=
parse_node *VerbPhrases::accept(verb_form *vf, parse_node *VP_PN, wording SW, wording OW, wording O2W) {
	wording NPs[MAX_NPS_IN_VP];
	for (int i=0; i<MAX_NPS_IN_VP; i++) NPs[i] = EMPTY_WORDING;
	NPs[0] = SW; NPs[1] = OW; NPs[2] = O2W;
	for (verb_sense *vs = (vf)?vf->list_of_senses:NULL; vs; vs = vs->next_sense) {
		verb_meaning *vm = &(vs->vm);
		Node::set_verb_meaning(VP_PN, vm);
		int rev = FALSE;
		special_meaning_fn soa = VerbMeanings::get_special_meaning(vm, &rev);
		if (soa) {
			if (rev) { wording W = NPs[0]; NPs[0] = NPs[1]; NPs[1] = W; }
			if ((*soa)(ACCEPT_SMFT, VP_PN, NPs)) {
				return VP_PN;
			}
			if (rev) { wording W = NPs[0]; NPs[0] = NPs[1]; NPs[1] = W; }
		}
	}
	if (VerbPhrases::default_verb(ACCEPT_SMFT, VP_PN, NPs)) return VP_PN;
	return NULL;
}

@ In effect, this is the sentence meaning function for all regular meanings.
For example, "Darcy is proud" and "Darcy wears the hat" will both end up here.

=
int VerbPhrases::default_verb(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	if (Wordings::nonempty(NPs[2])) return FALSE;
	switch (task) {
		case ACCEPT_SMFT: {
			verb_usage *vu = Node::get_verb(V);
			verb_identity *vsave = permitted_verb_identity;
			permitted_verb_identity = (vu)?vu->verb_used:NULL;

			if (<nounphrase-as-object>(OW) == FALSE) internal_error("<nounphrase-as-object> failed");
			parse_node *O_PN = <<rp>>;

			if (<nounphrase-as-subject>(SW) == FALSE) internal_error("<nounphrase-as-subject> failed");
			parse_node *S_PN = <<rp>>;

			V->next = S_PN;
			V->next->next = O_PN;
			@<Insert a relationship subtree if the verb creates one without a relative phrase@>;

			permitted_verb_identity = vsave;
			return TRUE;
		}
	}
	return FALSE;
}

@ If we have parsed a verb expressing a relationship other than equality, we
need to record that in the parse tree. This code does the following:
= (text)
	SENTENCE_NT "Darcy wears the hat"  --->  SENTENCE_NT "Darcy wears the hat"
	    VERB_NT "wears"                         VERB_NT "wears"
	    PROPER_NOUN_NT "Darcy"                   PROPER_NOUN_NT "Darcy"
	    PROPER_NOUN_NT "hat"                     RELATIONSHIP_NT "wears" = is-worn-by
	                                                 PROPER_NOUN_NT "hat"
=
The meaning is reversed here because we are applying it to the object of the
sentence not the subject: we thus turn the idea of Darcy wearing the hat into
the exactly equivalent idea of the hat being worn by Darcy.

@<Insert a relationship subtree if the verb creates one without a relative phrase@> =
	verb_meaning *vm = Node::get_verb_meaning(V);
	VERB_MEANING_TYPE *meaning = VerbMeanings::get_relational_meaning(vm);
	if (meaning == NULL) return FALSE;
	Node::set_verb_meaning(V, vm);
	if ((Annotations::read_int(V, possessive_verb_ANNOT) == FALSE) && (meaning != VERB_MEANING_EQUALITY)) {
		V->next->next = NounPhrases::PN_rel(
			Node::get_text(V), VerbMeanings::reverse_VMT(meaning), STANDARD_RELN, O_PN);
	}

@

=
int VerbPhrases::tracing(void) {
	#ifdef TRACING_LINGUISTICS_CALLBACK
	return TRACING_LINGUISTICS_CALLBACK();
	#endif
	#ifndef TRACING_LINGUISTICS_CALLBACK
	return FALSE;
	#endif
}
