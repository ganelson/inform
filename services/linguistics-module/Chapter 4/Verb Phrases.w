[VerbPhrases::] Verb Phrases.

To construct verb-phrase subtrees for assertion sentences.

@h Seeking verbs.
The nonterminal <sentence> has to find the verb in a sentence, and find its
noun phrases, with no contextual knowledge at all. In a sentence with only
one plausible verb, this is not difficult: the verb in "Anna is a sailor"
must be "is". But suppose we have:

>> The Fisher-Price carry cot is a container.

Is the verb "carry" or "is"? A human reader will more likely judge that a
particular make of cot is being said to be a container (thus "is"), rather
than that, say, a progressive rock band called "The Fisher-Price" are
carrying copies of their new EP of remixed lullabies, "cot is a container".

But a human has to know a great deal about culture and society to make
this sort of judgement. How is <sentence> to do it? One answer might be to
recognise "the Fisher-Price carry cot" as something already known, having
been defined in an earlier sentence. But Inform does not require such
pre-declarations -- indeed, the above sentence is a legal way to create
the cot from nothing.

Instead, <sentence> has to use heuristic rules about what is most likely,
and the algorithm below is the product of a very great deal of experimentation.

@ There are two variant forms: <sentence> and <sentence-without-occurrences>.
Inform actually uses the latter, detecting adverbs of occurrence like "for
the third time" lower down in the compiler.[1] Either way, //VerbPhrases::seek//
does the work.[2]

[1] This reduces false negatives, usually involving ambiguity between "time",
the kind of value, and "time", the measure of how often something has happened.

[2] Between 2010 and early 2016, this was implemented in straight Preform
rather than as an internal. This was more satisfying to read but became just
too complicated to maintain once VSO verbs were added to the grammar.

=
<sentence> internal {
	int rv = VerbPhrases::seek(W, X, XP, 0, TRUE);
	VerbPhrases::corrective_surgery(*XP);
	@<Trace diagram@>;
	return rv;
}

<sentence-without-occurrences> internal {
	int rv = VerbPhrases::seek(W, X, XP, 0, FALSE);
	VerbPhrases::corrective_surgery(*XP);
	@<Trace diagram@>;
	return rv;
}

@<Trace diagram@> =
	if (VerbPhrases::tracing(RESULTS_VP_TRACE)) {
		if (rv) {
			LOG("Sentence subtree:\n"); LOG_INDENT;
			for (parse_node *N = *XP; N; N = N->next) LOG("$T", N);
			LOG_OUTDENT;
		} else LOG("No verb found\n");
	}

@ 

@e SEEK_VP_TRACE from 1
@e VIABILITY_VP_TRACE
@e RESULTS_VP_TRACE
@e SURGERY_VP_TRACE

=
int VerbPhrases::tracing(int A) {
	#ifdef TRACING_LINGUISTICS_CALLBACK
	return TRACING_LINGUISTICS_CALLBACK(A);
	#endif
	#ifndef TRACING_LINGUISTICS_CALLBACK
	return FALSE;
	#endif
}

@ The following shows two simple sentences parsed with tracing on:

= (undisplayed text from Figures/simple-trace.txt)

@ The following function is only recursive to at most one level. It's used either
to parse a whole sentence, or is called from within itself to deal with the
object phrase part of an existential sentence where the SP is defective.
In the latter case, the call parameter |existential_OP_edge| will be the word
number of the last word which can be safely considered as a possible
preposition.

For example, here is a case where recursion occurs and succeeds:

= (undisplayed text from Figures/recursive-good-trace.txt)

And here is a case where recursion is tried but does not provide the solution,
so that we have to soldier on regardless:

= (undisplayed text from Figures/recursive-bad-trace.txt)

=
int VerbPhrases::seek(wording W, int *X, void **XP, int existential_OP_edge,
	int detect_occurrences) {
	if (VerbPhrases::tracing(SEEK_VP_TRACE)) {
		if (existential_OP_edge > 0) {
			LOG("Seek verb in: %W | %W\n",
				Wordings::up_to(W, existential_OP_edge),
				Wordings::from(W, existential_OP_edge+1));
			LOG_INDENT;
		} else {
			LOG("Seek verb in: %W\n", W); LOG_INDENT;
		}
	}
	int rv = VerbPhrases::seek_inner(W, X, XP, existential_OP_edge, detect_occurrences);
	if (VerbPhrases::tracing(SEEK_VP_TRACE)) {
		LOG_OUTDENT; if (rv) LOG("Seek succeeded\n"); else LOG("Seek failed\n");
	}
	return rv;
}

int VerbPhrases::seek_inner(wording W, int *X, void **XP, int existential_OP_edge,
	int detect_occurrences) {
	int viable[VIABILITY_MAP_SIZE];
	@<Calculate the viability map@>;
	if (VerbPhrases::tracing(VIABILITY_VP_TRACE)) @<Log the viability map@>;
	@<Seek verb usages@>;
	return FALSE;
}

@ The "viability map" assigns a score to each word in the sentence. Here
are some example viability maps:

= (undisplayed text from Figures/solomon-viability.txt)

The scoring system is:
(a) Words definitely not part of a verb score 0 and are marked |--| above.
(b) Verb words outside brackets score 1, and inside brackets 2, except that
(c) Words which are part of a negated verb other than "to be" score 3.

The viability map contains occasional false positives (i.e., words having positive
score which should be zero), but never has false zeroes.

The following does not impose a size limit on sentences; it is only that parsing
is less efficient on sentences longer than this number of words. A sentence whose
primary verb does not appear in its first hundred words is a rarity.

@d VIABILITY_MAP_SIZE 100

@ Rule (c) is there so that we do not trip up on auxiliary verbs such as "does"
or "have" in "does not have".

The copular verb "to be" is exempt so that something like "Velma is not a
thinker" can be parsed as "(Velma) is (not a thinker)", allowing "not a thinker"
to be a noun phrase -- if "thinker" is an either/or property with a single possible
antonym -- "doer", let's say -- then we want to construe this sentence as if
it read "Velma is a doer".

@<Calculate the viability map@> =
	for (int i=0; (i<=Wordings::length(W)) && (i<VIABILITY_MAP_SIZE); i++) viable[i] = 0;
	int bl = 0;
	LOOP_THROUGH_WORDING(pos, W) {
		if (pos == existential_OP_edge) break;
		if ((Lexer::word(pos) == OPENBRACKET_V) || (Lexer::word(pos) == OPENBRACE_V)) bl++;
		if ((Lexer::word(pos) == CLOSEBRACKET_V) || (Lexer::word(pos) == CLOSEBRACE_V)) bl--;
		int i = pos - Wordings::first_wn(W);
		if (i >= VIABILITY_MAP_SIZE) break;
		if (NTI::test_vocabulary(Lexer::word(pos), <nonimperative-verb>) == FALSE) {
			viable[i] = 0;
		} else {
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
	LOG("viability map of '%W':\n", W);
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

@<Seek verb usages@> =
	for (int viability_level = 1; viability_level <= 2; viability_level++)
		@<Seek verb usages at this viability level@>;

@ Within that constraint, we check in two passes. On pass 1, we skip over any
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

@<Seek verb usages at this viability level@> =
	for (int pass = 1; pass <= 2; pass++)
		for (verb_usage_tier *tier = first_search_tier; tier; tier = tier->next_tier)
			if (tier->priority != 0)
				LOOP_THROUGH_WORDING(pos, W) {
					int j = pos - Wordings::first_wn(W);
					if ((j >= VIABILITY_MAP_SIZE) || (viable[j] == viability_level))
						@<Seek verb usage at position pos@>;
				}

@ At this point |TW| is the tail of the wording: its first word is what we
think might be the verb. For example, given

>> The coral snake is in the green bucket.

we might have |TW| being "is in the green bucket".

@<Seek verb usage at position pos@> =
	wording TW = Wordings::from(W, pos);
	for (verb_usage *vu = tier->tier_contents; vu; vu = vu->next_within_tier)
		@<Consider whether this usage is being made at this position@>;

@ We must test whether our verb usage appears at the front of |TW|, thougn for
efficiency's sake we first test whether the verb has a meaning. (There are
potentially a great many meaningless verbs, because of the way adaptive text
is handled in Inform.)

@<Consider whether this usage is being made at this position@> =
	verb *vi = VerbUsages::get_verb(vu);
	int i = -1;
	wording ISW = EMPTY_WORDING, IOW = EMPTY_WORDING;
	int certainty = UNKNOWN_CE, pre_certainty = UNKNOWN_CE, post_certainty = UNKNOWN_CE;
	for (verb_form *vf = vi->first_form; vf; vf = vf->next_form) {
		verb_meaning *vm = &(vf->list_of_senses->vm);
		if (VerbMeanings::is_meaningless(vm) == FALSE) {
			if (i < 0) {
				i = VerbUsages::parse_against_verb(TW, vu);
				if (!((i>Wordings::first_wn(TW)) && (i<=Wordings::last_wn(TW)))) break;
				@<Reject a match with verb in the wrong position@>;
				@<Now we definitely have the verb usage at the front@>;
			}
			@<Check whether the rest of the verb form pans out@>;
		}
	}

@ A further complication is that we will reject this usage if it occurs
somewhere forbidden: for example, if a verb form is only allowed in an SVO
configuration, we will ignore it if |TW| is the whole of |W|, because then the
verb would begin at the first word of the sentence. Conversely, if it is only
allowed in an imperative VO configuration, it's required to be there.

In Inform, for example, "to carry" is an SVO verb, so we will match "Peter
carries the flash cards" but not "Carries Peter"; and "to test" is a VOO verb,
so we will match "Test me with flash cards" but not "Peter tests me with
flash cards".

@<Reject a match with verb in the wrong position@> =
	if ((vf->form_structures & (VO_FS_BIT + VOO_FS_BIT)) == 0) {
		if (pos == Wordings::first_wn(W)) break;
	}		
	if ((vf->form_structures & (SVO_FS_BIT + SVOO_FS_BIT)) == 0) {
		if (pos > Wordings::first_wn(W)) break;
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
	if (VerbPhrases::tracing(SEEK_VP_TRACE))
		LOG("Found usage, pass %d tier %d: (%W) $w (%W)\n",
			pass, tier->priority, ISW, vi, IOW);

@  If the verb form is, say, "place in ... with ...", and we have detected the
verb as "places" in the sentence "Henry places the cherry on the cake", we
still must reject this usage because it's missing the essential prepositions
"in" and "with". (It would, however, pass if the verb form were "place... on...".)

@<Check whether the rest of the verb form pans out@> =
	wording SW = ISW, OW = IOW, O2W = EMPTY_WORDING;
	wording VW = Wordings::up_to(TW, Wordings::first_wn(OW) - 1);

	@<If we have recursed in an existential sentence, trim any which@>;

	preposition *prep1 = vf->preposition, *req1 = prep1;
	preposition *prep2 = vf->second_clause_preposition, *req2 = prep2;

	int last_preposition_position = Wordings::last_wn(OW);
	int existential = FALSE, structures = vf->form_structures;

	@<A copular verb with a defective SP is existential@>;
	@<Check whether we do indeed have these required prepositions in place@>;

	/* we couldn't check for this before, since we need to skip past the prepositions too */
	if ((pass == 1) && (<pre-verb-rc-marker>(SW))) { pos = Wordings::first_wn(OW) - 1; continue; }

	@<Check whether any sense of this verb form will accept this usage and succeed if so@>;

@ This is also where we detect whether we have an existential sentence such as
"There is a man in the Dining Room." If so, we will have to allow for the
preposition "in" to be divided from the verb "is". But we will first check
(by using our one level of recursion) whether the tail of the sentence makes
sense in its own right. In this example it doesn't, but for "There is a man
who is in the Dining Room" (note the additional "is"), it would.

@<A copular verb with a defective SP is existential@> =
	if ((existential_OP_edge == 0) && (vi == copular_verb) && (req2 == NULL) &&
		(<np-existential>(SW))) {
		if (<phrase-with-calling>(OW))
			last_preposition_position = Wordings::last_wn(GET_RW(<phrase-with-calling>, 1));
		LOG_INDENT; 
		int rv = VerbPhrases::seek(OW, X, XP, last_preposition_position, detect_occurrences);
		LOG_OUTDENT; 
		if (rv) return rv;
		existential = TRUE; structures = SVOO_FS_BIT; req1 = NULL; req2 = prep1;
	}

@ And that explains the following. If we have recursed on "There is a man
who is in the Dining Room" then we are currently looking at "a man who is in
the Dining Room", and have set the |SW| wording to "a man who". We want to
trim away that "who" from the end of the |SW|.

@<If we have recursed in an existential sentence, trim any which@> =
	if (existential_OP_edge > 0) /* i.e., if we have recursed */
		if (<pre-verb-rc-marker>(SW)) { /* there is indeed a "which" at the end of |SW| */
			SW = GET_RW(<pre-verb-rc-marker>, 1); /* so trim it off */
			if (VerbPhrases::tracing(SEEK_VP_TRACE))
				LOG("Trimmed to: (%W) $w (%W)\n", SW, vi, OW);
		}

@ This part at least is boringly straightforward.

@<Check whether we do indeed have these required prepositions in place@> =
	int usage_succeeds = TRUE;
	if (req1) {
		usage_succeeds = FALSE;
		if (!((req1->allow_unexpected_upper_case == FALSE) &&
			(Word::unexpectedly_upper_case(Wordings::first_wn(OW)))))
			if (WordAssemblages::is_at(&(req1->prep_text),
					Wordings::first_wn(OW), Wordings::last_wn(TW))) {
				OW = Wordings::from(OW,
					Wordings::first_wn(OW) + WordAssemblages::length(&(req1->prep_text)));
				VW = Wordings::up_to(TW, Wordings::first_wn(OW) - 1);
				usage_succeeds = TRUE;
			}
		if (usage_succeeds == FALSE) {
			if (VerbPhrases::tracing(SEEK_VP_TRACE))
				LOG("$w + $p + $p : failed for lack of '$p'\n",
					vi, prep1, prep2, req1);
			continue;
		}
	}

	if (req2) {
		usage_succeeds = FALSE;
		int found = -1;
		for (int j=Wordings::first_wn(OW) + 1; j < last_preposition_position; j++) {
			wording TOW = Wordings::from(OW, j);
			if (WordAssemblages::is_at(&(req2->prep_text),
				Wordings::first_wn(TOW), Wordings::last_wn(TOW))) {
				found = j; break;
			}
		}
		if (found >= 0) {
			if (existential) SW = Wordings::up_to(OW, found-1);
			else O2W = Wordings::up_to(OW, found-1);
			OW = Wordings::from(OW, found + WordAssemblages::length(&(req2->prep_text)));
			usage_succeeds = TRUE;
		}
		if (usage_succeeds == FALSE) {
			if (VerbPhrases::tracing(SEEK_VP_TRACE))
				LOG("$w + $p + $p : failed for lack of '$p'\n",
					vi, prep1, prep2, req2);
			continue;
		}
	}

@ Now we're getting somewhere. The verb and any prepositions required by this
form are all in place, and we know this would be a meaningful sentence. So
we start building the diagram tree for the sentence at last, with the node
representing the verb.

@<Check whether any sense of this verb form will accept this usage and succeed if so@> =
	parse_node *VP_PN = Node::new(VERB_NT);
	if (certainty != UNKNOWN_CE)
		Annotations::write_int(VP_PN, verbal_certainty_ANNOT, certainty);
	if (vu) Node::set_verb(VP_PN, vu);
	Node::set_preposition(VP_PN, prep1);
	Node::set_second_preposition(VP_PN, prep2);

	Node::set_text(VP_PN, VW);
	if (existential) Annotations::write_int(VP_PN, sentence_is_existential_ANNOT, TRUE);
	if ((pre_certainty != UNKNOWN_CE) && (post_certainty != UNKNOWN_CE))
		Annotations::write_int(VP_PN, linguistic_error_here_ANNOT, TwoLikelihoods_LINERROR);
	if (detect_occurrences) {
		time_period *tp = Occurrence::parse(OW);
		if (tp) {
			OW = Occurrence::unused_wording(tp);
			Node::set_occurrence(VP_PN, tp);
		}
	}
	wording NPs[MAX_NPS_IN_VP];
	NPs[0] = SW; NPs[1] = OW; NPs[2] = O2W;
	VP_PN = VerbPhrases::accept(vf, VP_PN, NPs);
	if (VP_PN) {
		*XP = VP_PN;
		if (VerbPhrases::tracing(SEEK_VP_TRACE))
			LOG("Accepted as $w + $p + $p\n", vi, prep1, prep2);
		return TRUE;
	} else {
		if (VerbPhrases::tracing(SEEK_VP_TRACE))
			LOG("Rejected as $w + $p + $p\n", vi, prep1, prep2);
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

For example, the special meaning of "to mean" occurring in:

>> Use American dialect means ...

will only accept a subject phrase beginning with the word "use". The power to
say no to |ACCEPT_SMFT| thus enables us to minimise confusions between special
and regular meanings.

If all the special meanings decline, we can fall back on a regular meaning,
if there is one.

@d MAX_NPS_IN_VP 3

=
parse_node *VerbPhrases::accept(verb_form *vf, parse_node *VP_PN, wording *NPs) {
	verb_meaning *vm = NULL;
	for (verb_sense *vs = (vf)?vf->list_of_senses:NULL; vs; vs = vs->next_sense) {
		vm = &(vs->vm);
		special_meaning_holder *sm = VerbMeanings::get_special_meaning(vm);
		if (sm) {
			wording SNPs[MAX_NPS_IN_VP];
			if (VerbMeanings::get_reversal_status_of_smf(vm)) {
				SNPs[0] = NPs[1]; SNPs[1] = NPs[0]; SNPs[2] = NPs[2];
			} else {
				SNPs[0] = NPs[0]; SNPs[1] = NPs[1]; SNPs[2] = NPs[2];
			}
			if (SpecialMeanings::call(sm, ACCEPT_SMFT, VP_PN, SNPs)) {
				Node::set_special_meaning(VP_PN, sm);
				return VP_PN;
			}
		}
	}
	if ((VerbMeanings::get_regular_meaning(vm)) &&
		(Wordings::nonempty(NPs[0])) &&
		(Wordings::nonempty(NPs[1])) &&
		(Wordings::empty(NPs[2])) &&
		(VerbPhrases::default_verb(ACCEPT_SMFT, VP_PN, vm, NPs))) return VP_PN;
	return NULL;
}

@ In effect, this is the sentence meaning function for all regular meanings.
For example, "Darcy is proud" and "Darcy wears the hat" will both end up here.
It is only ever called for task |ACCEPT_SMFT|, and it always accepts.

=
int VerbPhrases::default_verb(int task, parse_node *V, verb_meaning *vm, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) {
		case ACCEPT_SMFT: {
			verb_usage *vu = Node::get_verb(V);
			verb *vsave = permitted_verb;
			permitted_verb = VerbUsages::get_verb(vu);

			if (<np-as-object>(OW) == FALSE) internal_error("<np-as-object> failed");
			parse_node *O_PN = <<rp>>;

			if (<np-as-subject>(SW) == FALSE) internal_error("<np-as-subject> failed");
			parse_node *S_PN = <<rp>>;

			V->next = S_PN;
			V->next->next = O_PN;
			@<Insert a relationship subtree for the OP of a non-copular verb@>;

			permitted_verb = vsave;
			return TRUE;
		}
	}
	return FALSE;
}

@ See //About Sentence Diagrams//: the OP for a non-copular verb becomes a
|RELATIONSHIP_NT| subtree, with relation reversed so that it is given from
the point of view of the object, not the subject.

For example, in "Darcy wears the hat", the OP "the hat" becomes a
|RELATIONSHIP_NT| subtree with the relation "is worn by" -- from the hat's
point of view, it is being worn.

@<Insert a relationship subtree for the OP of a non-copular verb@> =
	VERB_MEANING_LINGUISTICS_TYPE *meaning = VerbMeanings::get_regular_meaning(vm);
	if (meaning != VERB_MEANING_EQUALITY)
		V->next->next = Diagrams::new_RELATIONSHIP(
			Node::get_text(V), VerbMeanings::reverse_VMT(meaning), O_PN);

@h Sidekick nonterminals.
We will want to spot adverbs of certainty adjacent to the verb itself;
English allows these either side, so "A man is usually happy" and "Peter
certainly is happy" are both possible. Note that these adverbs can divide
a verb from its preposition(s): consider "The rain in Spain lies mainly in
the plain", where "mainly" divides "lies" from "in".

=
<pre-verb-certainty> ::=
	... <certainty>					==> { R[1], - }

<post-verb-certainty> ::=
	<certainty> ...					==> { R[1], - }

@ Relative clauses ("a woman who is on the stage") are detected by the presence
of a marker word before the verb (in this example, "who"). Of course, such
a word doesn't always mean we have a relative clause, so we will need to be a
little careful using this nonterminal.

=
<rc-marker> ::=
	which/who/that

<pre-verb-rc-marker> ::=
	... <rc-marker>

@ The following is used only in the reconstruction of existential sentences
such as "There is a cat called Puss in Boots", where we want to prevent the
"in" being considered a preposition -- it is part of a calling-name.

=
<phrase-with-calling> ::=
	... called ...


@h Corrective surgery.
The following iterates until all possible surgeries have been done.

=
void VerbPhrases::corrective_surgery(parse_node *pn) {
	int rv = TRUE;
	while (rv) rv = VerbPhrases::corrective_surgery_r(pn);
}

int VerbPhrases::corrective_surgery_r(parse_node *pn) {
	for (; pn; pn=pn->next) {
		if (VerbPhrases::perform_location_surgery(pn)) return TRUE;
		if (VerbPhrases::perform_called_surgery(pn)) return TRUE;
		if ((pn->down) && (VerbPhrases::corrective_surgery_r(pn->down))) return TRUE;
	}
	return FALSE;
}

@ "Location surgery" is needed to make sentences like the second one here work:

>> Anna is on the table and under the Ming Vase.

It performs a transformation on the tree like so:

= (undisplayed text from Figures/location-surgery.txt)

Looks easy, doesn't it? You will implement it wrongly the first six times you try.

=
int VerbPhrases::perform_location_surgery(parse_node *p) {
	parse_node *old_and, *old_np1, *old_loc2;
	if ((Node::get_type(p) == RELATIONSHIP_NT) &&
		(p->down) && (Node::get_type(p->down) == AND_NT) &&
		(p->down->down) && (p->down->down->next) &&
		(Node::get_type(p->down->down->next) == RELATIONSHIP_NT)) {
		if (VerbPhrases::tracing(SURGERY_VP_TRACE)) LOG("Location surgery on:\n$T", p);
		wording AW = Node::get_text(p->down);
		old_and = p->down;
		old_np1 = old_and->down;
		old_loc2 = old_and->down->next;
		Node::copy(old_and, p); /* making this the new first location node */
		Node::set_type_and_clear_annotations(p, AND_NT); /* and this is new AND */
		Node::set_text(p, AW);
		p->down = old_and;
		old_and->down = old_np1;
		old_and->next = old_loc2;
		old_np1->next = NULL;
		if (VerbPhrases::tracing(SURGERY_VP_TRACE)) LOG("Results in:\n$T", p);
		return TRUE;
	}
	return FALSE;
}

@h Called surgery.
The following case is now, I believe, impossible, but once happened on phrases
like "north of a room called the Hot and Cold Room" where a |CALLED_NT| and
a |RELATIONSHIP_NT| had ended up the wrong way round. The code is retained
in case needed again in future.

=
int VerbPhrases::perform_called_surgery(parse_node *p) {
	if ((Node::get_type(p) == CALLED_NT) &&
		(p->down) && (Node::get_type(p->down) == RELATIONSHIP_NT) && (p->down->down)) {
		if (VerbPhrases::tracing(SURGERY_VP_TRACE)) LOG("Called surgery on:\n$T", p);
		parse_node *x_pn = p->down->down->next; /* "north" in the example */
		parse_node *name_pn = p->down->next; /* "hot and cold room" in the example */
		Node::set_type(p, RELATIONSHIP_NT);
		Node::set_type(p->down, CALLED_NT);
		p->down->next = x_pn;
		p->down->down->next = name_pn;
		if (VerbPhrases::tracing(SURGERY_VP_TRACE)) LOG("Results in:\n$T", p);
		return TRUE;
	}
	return FALSE;
}
