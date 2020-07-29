[VerbUsages::] Verb Usages.

To parse the many forms a verb can take.

@h Verb usages.
We already have the ability to conjugate verbs -- to turn "to have" into "I have",
"you have", "he has", "they have had", "we will have" and so on -- from the
//inflections// module. However, we won't necessarily want to recognise all of
those forms in sentences in the source text. For example, Inform only looks
at present tense forms of verbs in the third person, or at imperative forms.

To be recognised as referring to a given verb, a conjugated form of it must
be turned into one of the following structures:

=
typedef struct verb_usage {
	struct grammatical_usage *usage;        /* includes verb, mood, tense, sense */
	struct word_assemblage vu_text;			/* text to recognise */
	int vu_allow_unexpected_upper_case; 	/* for verbs like "to Hoover" or "to Google" */
	struct verb_usage *next_in_search_list; /* within a linked list of all usages in length order */
	struct verb_usage *next_within_tier;	/* within the linked list for this tier (see below) */
	struct parse_node *where_vu_created; 	/* for use if problem messages needed */

	struct linguistic_stock_item *in_stock;

	#ifdef CORE_MODULE
	struct index_lexicon_entry *vu_lex_entry; 	/* for use when indexing */
	#endif
	CLASS_DEFINITION
} verb_usage;

@ =
void VerbUsages::write_usage(OUTPUT_STREAM, verb_usage *vu) {
	if (vu == NULL) { WRITE("(null verb usage)"); return; }
	WRITE(" {verb");
	verb *V = VerbUsages::get_verb(vu);
	if (V) WRITE(" '%A'", &(V->conjugation->infinitive));
	Stock::write_usage(OUT, vu->usage, SENSE_LCW+MOOD_LCW+TENSE_LCW+PERSON_LCW+NUMBER_LCW);
	WRITE("}");
}

@h Search list and tiers.
A "search list" of verb usages indicates what order the possibilities should be
checked in. The simpler list is in order of word count:

=
verb_usage *vu_search_list = NULL; /* head of linked list of usages in length order */

@d LOOP_OVER_USAGES(vu)
	for (vu = vu_search_list; vu; vu = vu->next_in_search_list)

@ The more complex list involves "tiers" of verbs with different priorities.

A particular challenge of parsing natural language is to decide the most likely
word in a sentence to be its primary verb. (The verb in "Heatwave Bone Breaks
Clog Hospital" is not "to break".) This is especially challenging when the
noun phrases can't be understood since they refer to things not yet created.
In Inform, for example, "Peter wears a felt hat" might be the only reference
anywhere in the source text to either Peter or the hat, which must each be
created in response to this sentence, and therefore can't be used to
understand it.

The model we use is to sort verb usages into "tiers", each with a numerical
"priority", which is a non-negative number. Tier 0 verb usages are never
recognised. (This does not make them useless: Inform can generate adaptive
text using them, and they can exist as run-time values in Inform.) Otherwise,
the lower the priority number, the more likely it is that this verb is meant.
If two usages belong to the same tier, the earlier in a sentence is preferred.

The tiers are stored as a linked list, in priority order:

=
typedef struct verb_usage_tier {
	int priority;
	struct verb_usage *tier_contents; /* head of linked list for this tier */
	struct verb_usage_tier *next_tier;
	CLASS_DEFINITION
} verb_usage_tier;

verb_usage_tier *first_search_tier = NULL; /* head of linked list of tiers */

@h Creation.
Here we create a single verb usage; note that the empty text cannot be used.

=
verb_usage *VerbUsages::new(word_assemblage wa, int unexpected_upper_casing_used,
	grammatical_usage *usage, parse_node *where) {
	if (WordAssemblages::nonempty(wa) == FALSE) return NULL;
	LOGIF(VERB_USAGES, "new usage: '%A'\n", &wa);
	VerbUsages::mark_as_verb(WordAssemblages::first_word(&wa));
	verb_usage *vu = CREATE(verb_usage);
	vu->vu_text = wa;
	#ifdef CORE_MODULE
	vu->vu_lex_entry = current_main_verb;
	#endif
	vu->where_vu_created = where;
	vu->usage = usage;
	vu->vu_allow_unexpected_upper_case = unexpected_upper_casing_used;
	vu->next_within_tier = NULL;
	vu->next_in_search_list = NULL;
	@<Add to the length-order search list@>;
	return vu;
}

@ These are insertion-sorted into a list in decreasing order of word count,
with oldest first in the case of equal length:

@<Add to the length-order search list@> =
	if (vu_search_list == NULL) vu_search_list = vu;
	else {
		for (verb_usage *evu = vu_search_list, *prev = NULL; evu;
			prev = evu, evu = evu->next_in_search_list) {
			if (WordAssemblages::longer(&wa, &(evu->vu_text)) > 0) {
				vu->next_in_search_list = evu;
				if (prev == NULL) vu_search_list = vu;
				else prev->next_in_search_list = vu;
				break;
			}
			if (evu->next_in_search_list == NULL) {
				evu->next_in_search_list = vu;
				break;
			}
		}
	}

@h Registration of regular verbs.
It would be tiresome to have to call the above routine for every possible
conjugated form of a verb individually, so the following takes care of
a whole verb at once.

The copular verb has no passive, since it doesn't distinguish between
subject and object. In English, we can say "the hat is worn by Peter"
as equivalent to "Peter wears the hat", but not "1 is been by X" as
equivalent to "X is 1".

=
verb_usage *regular_to_be = NULL; /* "is" */
verb_usage *negated_to_be = NULL; /* "is not" */

void VerbUsages::register_all_usages_of_verb(verb *vi,
	int unexpected_upper_casing_used, int priority, parse_node *where) {
	verb_conjugation *vc = vi->conjugation;
	if (vc == NULL) return;
	#ifdef CORE_MODULE
	IndexLexicon::new_main_verb(vc->infinitive, VERB_LEXE);
	#endif

	VerbUsages::register_moods_of_verb(vc, ACTIVE_MOOD, vi,
		unexpected_upper_casing_used, priority, where);

	if (vi != copular_verb) {
		VerbUsages::register_moods_of_verb(vc, PASSIVE_MOOD, vi,
			unexpected_upper_casing_used, priority, where);
		@<Add present participle forms@>;
	}
}

@ With the present participle the meaning is back the right way around: for
instance, "to be fetching" has the same meaning as "to fetch". At any rate,
Inform's linguistic model is not subtle enough to distinguish the difference,
in terms of a continuous rather than instantaneous process, which a human
reader might be aware of.

Partly because of that, we don't allow these forms for the copular verb:
"He is being difficult" doesn't quite mean "He is difficult", which is the
best sense we could make of it, and "He is being in the Dining Room" has
an unfortunate mock-Indian sound to it.

@<Add present participle forms@> =
	if (WordAssemblages::nonempty(vc->present_participle)) {
		preposition *prep =
			Prepositions::make(vc->present_participle, unexpected_upper_casing_used,
			where);
		Verbs::add_form(copular_verb, prep, NULL,
			VerbMeanings::indirected(vi, FALSE), SVO_FS_BIT);
	}

@ Note that forms using the auxiliary "to be" are given meanings which indirect
to the meanings of the main verb: thus "Y is owned by X" is indirected to
the reversal of the meaning "X owns Y", and "X is owning Y" to the unreversed
meaning. Both forms are then internally implemented as prepositional forms
of "to be", which is convenient however dubious in linguistic terms.

=
void VerbUsages::register_moods_of_verb(verb_conjugation *vc, int mood,
	verb *vi, int unexpected_upper_casing_used, int priority, parse_node *where) {
	verb_tabulation *vt = &(vc->tabulations[mood]);
	if (WordAssemblages::nonempty(vt->to_be_auxiliary)) {
		preposition *prep =
			Prepositions::make(vt->to_be_auxiliary, unexpected_upper_casing_used,
			where);
		Verbs::add_form(copular_verb, prep, NULL,
			VerbMeanings::indirected(vi, (mood == PASSIVE_MOOD)?TRUE:FALSE),
			SVO_FS_BIT);
		return;
	}
	@<Register usages@>;
}

@ The sequence of registration is important here, and it's done this way to
minimise false readings due to overlaps. We take future or other exotic
tenses (say, the French past historic) first; then the perfect tenses,
then the imperfect; within that, we take negated forms first, then positive;
within that, we take present before past tense; within that, we run through
the persons from 1PS to 3PP.

Moreover, we need to group together identical wordings, so that each is
registered only once, but with an accumulated grammatical usage marker.
For example, consider the regular English verb "to carry". Of the six present
tense active mood forms, only one -- "carries" -- uniquely identifies its
number and person (i.e., as third person singular); the other five are all
"carry". So we make two registrations, one with a //grammatical_usage//
containing a single linguistic constant, the other with one containing five.

We do this by accumulating a to-do list of forms we are interested in --
callback functions can tell us to ignore certain forms -- and the worst-case
scenario is if every imaginable form is different, so the to-do list needs
to be this long just in case:

@d MAX_POSSIBLE_VERB_USAGES NO_KNOWN_NUMBERS*NO_KNOWN_PERSONS*NO_KNOWN_TENSES*NO_KNOWN_SENSES

@<Register usages@> =
	int to_do = 0,
		lcons_to_do[MAX_POSSIBLE_VERB_USAGES],
		priorities_to_do[MAX_POSSIBLE_VERB_USAGES],
		copular_marker[MAX_POSSIBLE_VERB_USAGES],
		done[MAX_POSSIBLE_VERB_USAGES];
	word_assemblage wa_to_do[MAX_POSSIBLE_VERB_USAGES];
	for (int tense = WILLBE_TENSE; tense < NO_KNOWN_TENSES; tense++)
		for (int sense = 1; sense >= 0; sense--)
			@<Make to-do list of usages in this combination@>;

	int t1 = HASBEEN_TENSE, t2 = HADBEEN_TENSE;
	@<Make to-do list of usages in these tenses@>;
	t1 = IS_TENSE; t2 = WAS_TENSE;
	@<Make to-do list of usages in these tenses@>;
	@<Register each equivalence class of to-do list entries@>;

@<Make to-do list of usages in these tenses@> =
	for (int sense = 1; sense >= 0; sense--) {
		int tense = t1;
		@<Make to-do list of usages in this combination@>;
		tense = t2;
		@<Make to-do list of usages in this combination@>;
	}

@<Make to-do list of usages in this combination@> =
	for (int number = 0; number < NO_KNOWN_NUMBERS; number++)
		for (int person = 0; person < NO_KNOWN_PERSONS; person++) {
			int p = priority;
			#ifdef ALLOW_VERB_IN_ASSERTIONS_LINGUISTICS_CALLBACK
			if (ALLOW_VERB_IN_ASSERTIONS_LINGUISTICS_CALLBACK(vc, tense, sense, person) == FALSE) p = 0;
			#else
			if (VerbUsages::allow_in_assertions(vc, tense, sense, person) == FALSE) p = 0;
			#endif
			if (p == 0) {
				#ifdef ALLOW_VERB_LINGUISTICS_CALLBACK
				if (ALLOW_VERB_LINGUISTICS_CALLBACK(vc, tense, sense, person) == FALSE) p = -1;
				#else
				if (VerbUsages::allow_generally(vc, tense, sense, person) == FALSE) p = -1;
				#endif
			}
			if (p >= 0) @<Add this form to the to-do list@>;
		}

@<Add this form to the to-do list@> =
	lcon_ti l = Verbs::to_lcon(vi);
	l = Lcon::set_mood(l, mood);
	l = Lcon::set_tense(l, tense);
	l = Lcon::set_sense(l, sense);
	l = Lcon::set_person(l, person);
	l = Lcon::set_number(l, number);
	lcons_to_do[to_do] = l;
	priorities_to_do[to_do] = p;
	done[to_do] = FALSE;
	wa_to_do[to_do] = vt->vc_text[tense][sense][person][number];
	copular_marker[to_do] = 0;
	if (vi == copular_verb) {
		if ((tense == IS_TENSE) && (person == THIRD_PERSON) && (number == SINGULAR_NUMBER)) {
			if (sense == 1) copular_marker[to_do] = -1;
			else copular_marker[to_do] = 1;
		}
	}
	to_do++;

@ Two entries on the to-do list are "equivalent" if they have the same wording.
For example, "carry" first person singular present tense is equivalent to
the same thing in the second person, and so on. The priority for an equivalence
class is the maximum priority for any of its members; this ensures, for example,
that "carry" (1ps) which has priority 0 will not hold back "carry" (3pp) which
needs to have priority 1.

@<Register each equivalence class of to-do list entries@> =
	for (int i=0; i<to_do; i++)
		if (done[i] == FALSE) {
			int max_priority = -1;
			grammatical_usage *gu = Stock::new_usage(vi->in_stock, DefaultLanguage::get(NULL));
			for (int j=0; j<to_do; j++)
				if (WordAssemblages::eq(&(wa_to_do[i]), &(wa_to_do[j]))) {
					done[j] = TRUE;
					Stock::add_form_to_usage(gu, lcons_to_do[j]);
					if (priorities_to_do[j] > max_priority) max_priority = priorities_to_do[j];
				}
			verb_usage *vu = VerbUsages::new(wa_to_do[i],
				unexpected_upper_casing_used, gu, where);
			if (vu) VerbUsages::set_search_priority(vu, max_priority);
			if (copular_marker[i] == 1) regular_to_be = vu;
			if (copular_marker[i] == -1) negated_to_be = vu;
		}

@ Here are the default decisions on what usages are allowed; the defaults are
what are used by Inform. In assertions:

=
int VerbUsages::allow_in_assertions(verb_conjugation *vc, int tense, int sense, int person) {
	if ((tense == IS_TENSE) && (sense == POSITIVE_SENSE) && (person == THIRD_PERSON))
		return TRUE;
	return FALSE;
}

@ And in other usages (e.g., in Inform's "now the pink door is not open"):

=
int VerbUsages::allow_generally(verb_conjugation *vc, int tense, int sense, int person) {
	if (((tense == IS_TENSE) || (tense == WAS_TENSE) ||
			(tense == HASBEEN_TENSE) || (tense == HADBEEN_TENSE)) &&
		(person == THIRD_PERSON))
		return TRUE;
	return FALSE;
}

@ That just leaves the business of setting the "priority" of a usage. As
noted above, priority 0 usages are ignored, while otherwise low numbers
beat high ones. For example, in "The verb to be means the equality relation",
the verb "be" might have priority 2 and so be beaten by the verb "mean",
with priority 1.

We must add the new usage to the tier with the given priority, creating
that tier if need be. Newly created tiers are insertion-sorted into a
list, with lower priority numbers before higher ones.

=
void VerbUsages::set_search_priority(verb_usage *vu, int p) {
	verb_usage_tier *tier = first_search_tier, *last_tier = NULL;
	LOGIF(VERB_USAGES, "Usage '%A' has priority %d\n", &(vu->vu_text), p);
	while ((tier) && (tier->priority <= p)) {
		if (tier->priority == p) {
			VerbUsages::add_to_tier(vu, tier);
			return;
		}
		last_tier = tier;
		tier = tier->next_tier;
	}
	tier = CREATE(verb_usage_tier);
	tier->priority = p;
	tier->tier_contents = NULL;
	VerbUsages::add_to_tier(vu, tier);
	if (last_tier) {
		tier->next_tier = last_tier->next_tier;
		last_tier->next_tier = tier;
	} else {
		tier->next_tier = first_search_tier;
		first_search_tier = tier;
	}
}

void VerbUsages::add_to_tier(verb_usage *vu, verb_usage_tier *tier) {
	verb_usage *known = tier->tier_contents;
	while ((known) && (known->next_within_tier))
		known = known->next_within_tier;
	if (known) known->next_within_tier = vu;
	else tier->tier_contents = vu;
	vu->next_within_tier = NULL;
}

@h Miscellaneous utility routines.
A usage is "foreign" if it belongs to a language other than English:

=
int VerbUsages::is_foreign(verb_usage *vu) {
	verb *v = VerbUsages::get_verb(vu);
	if ((v) && (v->conjugation->defined_in) &&
		(v->conjugation->defined_in != DefaultLanguage::get(NULL))) {
		return TRUE;
	}
	return FALSE;
}

@ And some access routines.

=
VERB_MEANING_LINGUISTICS_TYPE *VerbUsages::get_regular_meaning(verb_usage *vu, preposition *prep, preposition *second_prep) {
	if (vu == NULL) return NULL;
	VERB_MEANING_LINGUISTICS_TYPE *root = VerbMeanings::get_regular_meaning_of_form(Verbs::find_form(VerbUsages::get_verb(vu), prep, second_prep));
	if ((root) && (VerbUsages::get_mood(vu) == PASSIVE_MOOD) && (root != VERB_MEANING_EQUALITY))
		root = VerbMeanings::reverse_VMT(root);
	return root;
}

verb *VerbUsages::get_verb(verb_usage *vu) {
	if (vu) return Verbs::from_lcon(Stock::first_form_in_usage(vu->usage));
	return NULL;
}

int VerbUsages::get_mood(verb_usage *vu) {
	return Lcon::get_mood(Stock::first_form_in_usage(vu->usage));
}

int VerbUsages::get_tense_used(verb_usage *vu) {
	return Lcon::get_tense(Stock::first_form_in_usage(vu->usage));
}

int VerbUsages::is_used_negatively(verb_usage *vu) {
	if (Lcon::get_sense(Stock::first_form_in_usage(vu->usage)) == NEGATIVE_SENSE) return TRUE;
	return FALSE;
}

@h Parsing source text against verb usages.
Given a particular VU, and a word range |w1| to |w2|, we test whether the
range begins with but does not consist only of the text of the VU. We return
the first word after the VU text if it does (which will therefore be a
word number still inside the range), or $-1$ if it doesn't.

It is potentially quite slow to test every word against every possible verb,
even though there are typically fairly few verbs in the S-grammar, so we
confine ourselves to words flagged in the vocabulary as being used in verbs.

=
int VerbUsages::parse_against_verb(wording W, verb_usage *vu) {
	if ((vu->vu_allow_unexpected_upper_case == FALSE) &&
		(Word::unexpectedly_upper_case(Wordings::first_wn(W)))) return -1;
	return WordAssemblages::parse_as_strictly_initial_text(W, &(vu->vu_text));
}

@ The "permitted verb" is just a piece of temporary context used in parsing:
it's convenient for the verb currently being considered to be stored in
a global variable.

=
verb *permitted_verb = NULL;

@ We now define a whole run of internals to parse verbs. As examples,

>> is
>> has not been
>> was carried by

are all, in the sense we mean it here, "verbs".

We never match a verb if it is unexpectedly given in upper case form. Thus
"The Glory That Is Rome is a room" will be read as "(The Glory That Is
Rome) is (a room)", not "(The Glory That) is (Rome is a room)".

The following picks up any verb which can be used in an SVO sentence and
which has a meaning.

=
<nonimperative-verb> internal ? {
	verb_usage *vu;
	LOOP_OVER_USAGES(vu) {
		verb *vi = VerbUsages::get_verb(vu);
		for (verb_form *vf = vi->first_form; vf; vf = vf->next_form)
			if ((VerbMeanings::is_meaningless(&(vf->list_of_senses->vm)) == FALSE) &&
				(vf->form_structures & (SVO_FS_BIT + SVOO_FS_BIT))) {
				int i = VerbUsages::parse_against_verb(W, vu);
				if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
					if ((vf->preposition == NULL) ||
						(WordAssemblages::is_at(&(vf->preposition->prep_text), i, Wordings::last_wn(W)))) {
						==> { -, vu };
						permitted_verb = VerbUsages::get_verb(vu);
						return i-1;
					}
				}
			}
	}
	==> { fail nonterminal };
}

@ A copular verb is one which implies the equality relation: in practice,
that means it's "to be". So the following matches "is", "were not",
and so on.

=
<copular-verb> internal ? {
	verb_usage *vu;
	if (preform_backtrack) { vu = preform_backtrack; goto BacktrackFrom; }
	LOOP_OVER_USAGES(vu) {
		if (VerbUsages::get_verb(vu) == copular_verb) {
			int i = VerbUsages::parse_against_verb(W, vu);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
				==> { -, vu };
				return -(i-1);
			}
			BacktrackFrom: ;
		}
	}
	==> { fail nonterminal };
}

@ A noncopular verb is anything that isn't copular, but here we also require
it to be in the present tense and the negative sense. So, for example, "does
not carry" qualifies; "is not" or "supports" don't qualify.

=
<negated-noncopular-verb-present> internal ? {
	verb_usage *vu;
	if (preform_backtrack) { vu = preform_backtrack; goto BacktrackFrom; }
	LOOP_OVER_USAGES(vu) {
		if ((VerbUsages::get_tense_used(vu) == IS_TENSE) &&
			(VerbUsages::get_verb(vu) != copular_verb) &&
			(VerbUsages::is_used_negatively(vu))) {
			int i = VerbUsages::parse_against_verb(W, vu);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
				==> { -, vu };
				return -(i-1);
			}
			BacktrackFrom: ;
		}
	}
	==> { fail nonterminal };
}

@ A universal verb is one which implies the universal relation: in Inform,
that means it's "to relate".

=
<universal-verb> internal ? {
	#ifdef VERB_MEANING_UNIVERSAL
	verb_usage *vu;
	LOOP_OVER_USAGES(vu)
		if (VerbUsages::get_regular_meaning(vu, NULL, NULL) == VERB_MEANING_UNIVERSAL) {
			int i = VerbUsages::parse_against_verb(W, vu);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
				==> { -, vu };
				return i-1;
			}
		}
	#endif
	==> { fail nonterminal };
}

@
Any verb usage which is negative in sense: this is used only to diagnose problems.

=
<negated-verb> internal ? {
	verb_usage *vu;
	if (preform_backtrack) { vu = preform_backtrack; goto BacktrackFrom; }
	LOOP_OVER_USAGES(vu) {
		if (VerbUsages::is_used_negatively(vu)) {
			int i = VerbUsages::parse_against_verb(W, vu);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
				==> { -, vu };
				return -(i-1);
			}
			BacktrackFrom: ;
		}
	}
	==> { fail nonterminal };
}

@ Any verb usage which is in the past tense: this is used only to diagnose problems.

=
<past-tense-verb> internal ? {
	verb_usage *vu;
	if (preform_backtrack) { vu = preform_backtrack; goto BacktrackFrom; }
	LOOP_OVER_USAGES(vu) {
		if (VerbUsages::get_tense_used(vu) != IS_TENSE) {
			int i = VerbUsages::parse_against_verb(W, vu);
			if ((i>Wordings::first_wn(W)) && (i<=Wordings::last_wn(W))) {
				==> { -, vu };
				return -(i-1);
			}
			BacktrackFrom: ;
		}
	}
	==> { fail nonterminal };
}

@ The following are used only when recognising text expansions for adaptive
uses of verbs:

=
<adaptive-verb> internal {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		if (vc->auxiliary_only == FALSE) {
			int p = VerbUsages::adaptive_person(vc->defined_in);
			int n = VerbUsages::adaptive_number(vc->defined_in);
			word_assemblage *we_form = &(vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][POSITIVE_SENSE][p][n]);
			word_assemblage *we_dont_form = &(vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][NEGATIVE_SENSE][p][n]);
			if (WordAssemblages::compare_with_wording(we_form, W)) {
				==> { FALSE, vc }; return TRUE;
			}
			if (WordAssemblages::compare_with_wording(we_dont_form, W)) {
				==> { TRUE, vc }; return TRUE;
			}
		}
	==> { fail nonterminal };
}

<adaptive-verb-infinitive> internal {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		if (vc->auxiliary_only == FALSE) {
			word_assemblage *infinitive_form = &(vc->infinitive);
			if (WordAssemblages::compare_with_wording(infinitive_form, W)) {
				==> { FALSE, vc }; return TRUE;
			}
		}
	==> { fail nonterminal };
}

@ These three nonterminals are used by Inform only to recognise constant
names for verbs. For example, the parsing of the Inform constants "the verb take"
or "the verb to be able to see" use these.

=
<instance-of-verb> internal {
	verb_form *vf;
	LOOP_OVER(vf, verb_form) {
		verb_conjugation *vc = vf->underlying_verb->conjugation;
		if ((vc) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb)) {
			if (WordAssemblages::compare_with_wording(&(vf->pos_reference_text), W)) {
				==> { FALSE, vf }; return TRUE;
			}
			if (WordAssemblages::compare_with_wording(&(vf->neg_reference_text), W)) {
				==> { TRUE, vf }; return TRUE;
			}
		}
	}
	==> { fail nonterminal };
}

<instance-of-infinitive-form> internal {
	verb_form *vf;
	LOOP_OVER(vf, verb_form) {
		verb_conjugation *vc = vf->underlying_verb->conjugation;
		if ((vc) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb)) {
			if (WordAssemblages::compare_with_wording(&(vf->infinitive_reference_text), W)) {
				==> { FALSE, vf }; return TRUE;
			}
		}
	}
	==> { fail nonterminal };
}

<modal-verb> internal {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		if (vc->auxiliary_only == FALSE) {
			int p = VerbUsages::adaptive_person(vc->defined_in);
			int n = VerbUsages::adaptive_number(vc->defined_in);
			if (vc->tabulations[ACTIVE_MOOD].modal_auxiliary_usage[IS_TENSE][POSITIVE_SENSE][p][n] != 0) {
				word_assemblage *we_form = &(vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][POSITIVE_SENSE][p][n]);
				word_assemblage *we_dont_form = &(vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][NEGATIVE_SENSE][p][n]);
				if (WordAssemblages::compare_with_wording(we_form, W)) {
					==> { FALSE, vc }; return TRUE;
				}
				if (WordAssemblages::compare_with_wording(we_dont_form, W)) {
					==> { TRUE, vc }; return TRUE;
				}
			}
		}
	==> { fail nonterminal };
}

@h Optimisation.

=
void VerbUsages::mark_as_verb(vocabulary_entry *ve) {
	NTI::mark_vocabulary(ve, <nonimperative-verb>);
	NTI::mark_vocabulary(ve, <copular-verb>);
	NTI::mark_vocabulary(ve, <negated-noncopular-verb-present>);
	NTI::mark_vocabulary(ve, <universal-verb>);
	NTI::mark_vocabulary(ve, <negated-verb>);
	NTI::mark_vocabulary(ve, <past-tense-verb>);
}

void VerbUsages::preform_optimiser(void) {
	NTI::first_word_in_match_must_have_my_NTI_bit(<nonimperative-verb>);
	NTI::first_word_in_match_must_have_my_NTI_bit(<copular-verb>);
	NTI::first_word_in_match_must_have_my_NTI_bit(<negated-noncopular-verb-present>);
	NTI::first_word_in_match_must_have_my_NTI_bit(<universal-verb>);
	NTI::first_word_in_match_must_have_my_NTI_bit(<negated-verb>);
	NTI::first_word_in_match_must_have_my_NTI_bit(<past-tense-verb>);
}

@h Adaptive person.

=
int VerbUsages::adaptive_person(NATURAL_LANGUAGE_WORDS_TYPE *X) {
	#ifdef ADAPTIVE_PERSON_LINGUISTICS_CALLBACK
	int N = ADAPTIVE_PERSON_LINGUISTICS_CALLBACK(X);
	if (N >= 0) return N;
	return FIRST_PERSON;
	#endif
	#ifndef ADAPTIVE_PERSON_LINGUISTICS_CALLBACK
	return FIRST_PERSON;
	#endif
}
int VerbUsages::adaptive_number(NATURAL_LANGUAGE_WORDS_TYPE *X) {
	#ifdef ADAPTIVE_NUMBER_LINGUISTICS_CALLBACK
	int N = ADAPTIVE_NUMBER_LINGUISTICS_CALLBACK(X);
	if (N >= 0) return N;
	return PLURAL_NUMBER;
	#endif
	#ifndef ADAPTIVE_NUMBER_LINGUISTICS_CALLBACK
	return PLURAL_NUMBER;
	#endif
}
