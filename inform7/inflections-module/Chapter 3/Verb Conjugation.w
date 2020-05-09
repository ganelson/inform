[Conjugation::] Verb Conjugation.

Conjugating verbs into the many different forms they can take.

@ We will need to turn a base form of a verb -- in English, this is always the
infinitive -- into up to 123 variants; we manage this with quite an extensive
data structure. There will typically only be a few dozen fully conjugated
verbs in any source text, though, so the memory cost isn't too extreme. For
English it looks wasteful, since so many forms are the same, but for French
(say) they are almost all different.

=
typedef struct verb_conjugation {
	struct word_assemblage infinitive; /* not counting the "to", in English */
	struct word_assemblage past_participle;
	struct word_assemblage present_participle;
	struct verb_tabulation tabulations[NO_KNOWN_MOODS];
	PREFORM_LANGUAGE_TYPE *defined_in;
	#ifdef LINGUISTICS_MODULE
	struct verb_identity *vc_conjugates;
	#endif
	#ifdef CORE_MODULE
	struct parse_node *where_vc_created;
	struct inter_name *vc_iname;
	#endif
	int auxiliary_only; /* used only as an auxiliary, e.g. the "have" in "I have gone" */
	int instance_of_verb; /* defines an instance of kind "verb" at run-time */
	CLASS_DEFINITION
} verb_conjugation;

typedef struct verb_tabulation {
	struct word_assemblage to_be_auxiliary; /* use this if non-empty */
	struct word_assemblage vc_text[NO_KNOWN_TENSES][2][6];
	int modal_auxiliary_usage[NO_KNOWN_TENSES][2][6];
} verb_tabulation;

@h Making conjugations.
The following will make more sense if read alongside the examples in "English
Inflections", which explains the format in full. In fact English itself is a
little tame, though -- try the French Language extension for the real deal.

The crucial early step here is |Conjugation::follow_instructions|, which has
two tasks to perform: it works out the numbered verb forms, and it chooses
which tabulation will be used. Verb form number 0 is always the base text,
and subsequent numbers include some which are universal across all verbs
(these have |*_FORM_TYPE| constants), and others which vary from one
conjugation to another.

=
verb_conjugation *Conjugation::conjugate(word_assemblage base_text,
	PREFORM_LANGUAGE_TYPE *nl) {
	return Conjugation::conjugate_with_overrides(base_text, NULL, 0, nl);
}

verb_conjugation *Conjugation::conjugate_with_overrides(word_assemblage base_text,
	word_assemblage *overrides, int no_overrides, PREFORM_LANGUAGE_TYPE *nl) {
	if (nl == NULL) nl = English_language;
	if (WordAssemblages::nonempty(base_text) == FALSE)
		internal_error("No base text for verb conjugation");

	word_assemblage verb_forms[MAX_FORM_TYPES+1];
	@<Initialise all verb forms to the base text@>;

	int n = 1, aux_len = 0, avo_flag = FALSE, niv_flag = FALSE;
	nonterminal *tabulation =
		Conjugation::follow_instructions(verb_forms, &n, &aux_len, &avo_flag, &niv_flag, nl);

	@<Override any verb forms with supplied irregularities@>;
	@<Use the verb forms and the tabulation to make the conjugation@>;
}

@<Initialise all verb forms to the base text@> =
	int k;
	for (k=0; k<=MAX_FORM_TYPES; k++) verb_forms[k] = base_text;

@ This feature is provided so that English verb definitions can override the
usual grammatical rules, which enables us to create new irregular verbs.
For example, Inform will by default make the past participle "blended" out
of the verb "to blend", but a definition like

>> To blend (I blend, he blends, it is blent) ...

will cause "blent" to override "blended" in the |PAST_PARTICIPLE_FORM_TYPE|.
(Philip Larkin's poem "Church Going" uses "blent", but I've never seen
anybody else try this one on.)

Note that verb form 0 can't be overridden: that was the base text.

@<Override any verb forms with supplied irregularities@> =
	int k;
	for (k=1; k<no_overrides; k++)
		if (WordAssemblages::nonempty(overrides[k]))
			verb_forms[k] = overrides[k];

@<Use the verb forms and the tabulation to make the conjugation@> =
	verb_conjugation *vc = CREATE(verb_conjugation);
	#ifdef LINGUISTICS_MODULE
	vc->vc_conjugates = NULL;
	#endif
	vc->infinitive = verb_forms[INFINITIVE_FORM_TYPE];
	vc->present_participle = verb_forms[PRESENT_PARTICIPLE_FORM_TYPE];
	vc->past_participle = verb_forms[PAST_PARTICIPLE_FORM_TYPE];
	vc->defined_in = nl;
	vc->auxiliary_only = avo_flag;
	vc->instance_of_verb = (niv_flag)?FALSE:TRUE;
	#ifdef CORE_MODULE
	vc->where_vc_created = current_sentence;
	vc->vc_iname = NULL;
	#endif

	@<Start by blanking out all the passive and active slots@>;
	@<Work through the supplied tabulation, filling in slots as directed@>;

	return vc;

@<Start by blanking out all the passive and active slots@> =
	vc->tabulations[ACTIVE_MOOD].to_be_auxiliary = WordAssemblages::lit_0();
	vc->tabulations[PASSIVE_MOOD].to_be_auxiliary = WordAssemblages::lit_0();
	int i, tense, sense;
	for (tense=0; tense<NO_KNOWN_TENSES; tense++)
		for (sense=0; sense<2; sense++)
			for (i=0; i<6; i++) {
				vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][i] = WordAssemblages::lit_0();
				vc->tabulations[PASSIVE_MOOD].vc_text[tense][sense][i] = WordAssemblages::lit_0();
			}

@ A tabulation is a sort of program laying out what to put in which slots,
active or passive. Each production is a step in this program, and it consists
of a "selector" followed by a "line". For example, the production:
= (text as InC)
	a3 ( t1 avoir ) 3+*
=
contains six tokens; the selector is |a3|, and the line is made up from the
rest. (The selector is always just a single token.)

@<Work through the supplied tabulation, filling in slots as directed@> =
	production_list *pl;
	for (pl = tabulation->first_production_list; pl; pl = pl->next_production_list) {
		if (nl == pl->definition_language) {
			production *pr;
			for (pr = pl->first_production; pr; pr = pr->next_production) {
				ptoken *selector = pr->first_ptoken;
				ptoken *line = (selector)?(selector->next_ptoken):NULL;
				if ((selector) && (selector->ptoken_category == FIXED_WORD_PTC) && (line)) {
					@<Apply the given tabulation line to the slots selected@>;
				} else Conjugation::error(base_text, tabulation, pr,
					"tabulation row doesn't consist of a selector and then text");
			}
		}
	}

@<Apply the given tabulation line to the slots selected@> =
	int active_set = NOT_APPLICABLE, tense_set = -1, sense_set = -1, set_tba = FALSE;
	@<Parse the slot selector@>;

	if (set_tba)
		vc->tabulations[PASSIVE_MOOD].to_be_auxiliary =
			Conjugation::merge(line, 0, 0, 0, MAX_FORM_TYPES+1, verb_forms, nl, NULL);

	int person, tense, sense;
	for (tense=0; tense<NO_KNOWN_TENSES; tense++)
		for (sense=0; sense<2; sense++)
			for (person=0; person<6; person++) {
				if ((sense_set >= 0) && (sense != sense_set)) continue;
				if ((tense_set >= 0) && (tense != tense_set)) continue;
				if (active_set)
					vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][person] =
						Conjugation::merge(line, sense, tense, person, MAX_FORM_TYPES+1, verb_forms, nl,
						&(vc->tabulations[ACTIVE_MOOD].modal_auxiliary_usage[tense][sense][person]));
				else
					vc->tabulations[PASSIVE_MOOD].vc_text[tense][sense][person] =
						Conjugation::merge(line, sense, tense, person, MAX_FORM_TYPES+1, verb_forms, nl,
						&(vc->tabulations[PASSIVE_MOOD].modal_auxiliary_usage[tense][sense][person]));
			}

@ The selector tells us which tense(s), sense(s) and mood(s) to apply the
line to; |a3|, for example, means active mood, tense 3, in both positive
and negative senses.

@<Parse the slot selector@> =
	vocabulary_entry *ve = selector->ve_pt;
	wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if (p[0] == 'a') active_set = TRUE;
	if (p[0] == 'p') active_set = FALSE;
	if (active_set == NOT_APPLICABLE)
		Conjugation::error(base_text, tabulation, pr,
			"tabulation row doesn't begin with 'a' or 'p'");
	int at = 1;
	if (Characters::isdigit(p[at])) { tense_set = p[at++]-'1'; }
	if (p[at] == '+') { sense_set = 0; at++; }
	else if (p[at] == '-') { sense_set = 1; at++; }
	else if ((p[at] == '*') && (tense_set == -1) && (active_set == FALSE)) {
		set_tba = TRUE; at++;
	}
	if (p[at] != 0) {
		LOG("The selector here is: <%w>\n", p);
		Conjugation::error(base_text, tabulation, pr,
			"unrecognised selector in tabulation row");
	}

@ =
#ifdef CORE_MODULE
inter_name *Conjugation::conj_iname(verb_conjugation *vc) {
	if (vc->vc_iname == NULL) {
		if (vc->vc_conjugates == NULL) {
			package_request *R = Hierarchy::package(Modules::find(vc->where_vc_created), MVERBS_HAP);
			TEMPORARY_TEXT(ANT);
			WRITE_TO(ANT, "%A (modal)", vc->tabulations[ACTIVE_MOOD].vc_text[0][0][2]);
			Hierarchy::markup(R, MVERB_NAME_HMD, ANT);
			DISCARD_TEXT(ANT);
			vc->vc_iname = Hierarchy::make_iname_in(MODAL_CONJUGATION_FN_HL, R);
		} else {
			package_request *R = Verbs::verb_package(vc->vc_conjugates, vc->where_vc_created);
			TEMPORARY_TEXT(ANT);
			WRITE_TO(ANT, "to %A", vc->infinitive);
			Hierarchy::markup(R, VERB_NAME_HMD, ANT);
			DISCARD_TEXT(ANT);
			vc->vc_iname = Hierarchy::make_iname_in(NONMODAL_CONJUGATION_FN_HL, R);
		}
	}
	return vc->vc_iname;
}
#endif

@h Follow instructions.
That completes the top level of the routine, but it depended on two major
sub-steps: a preliminary pass called |Conjugation::follow_instructions| and
a routine to deal with the final results called |Conjugation::merge|.

Here's the first of these. Note that the routine indirects through three main
nonterminals; it always starts with |<verb-conjugation-instructions>| and
uses this to choose a "conjugation" nonterminal. It then chugs through
the conjugation, which ends by choosing a "tabulation". For example, in
English, the base text "do" passes through |<verb-conjugation-instructions>|,
which chooses the conjugation |<to-do-conjugation>|, which in turn sets some
participles and then chooses the tabulation |<to-do-tabulation>|.

=
nonterminal *Conjugation::follow_instructions(word_assemblage *verb_forms, int *highest_form_written,
	int *aux_len, int *avo_flag, int *niv_flag, PREFORM_LANGUAGE_TYPE *nl) {
	nonterminal *instructions_nt = <verb-conjugation-instructions>;
	nonterminal *tabulation_nt = NULL, *conjugation_nt = NULL;
	*highest_form_written = 1;
	*aux_len = 0; *avo_flag = FALSE; *niv_flag = FALSE;
	@<Pattern match on the base text to decide which conjugation to use@>;
	if (conjugation_nt == NULL)
		Conjugation::error(verb_forms[0], instructions_nt, NULL,
			"the instructions here failed to choose a conjugation");
	@<Process the conjugation and determine the tabulation@>;
	if (tabulation_nt == NULL)
		Conjugation::error(verb_forms[0], conjugation_nt, NULL,
			"the conjugation here failed to choose a tabulation");
	return tabulation_nt;
}

@<Pattern match on the base text to decide which conjugation to use@> =
	vocabulary_entry **base_text_words;
	int base_text_word_count;
	WordAssemblages::as_array(&(verb_forms[BASE_FORM_TYPE]), &base_text_words, &base_text_word_count);

	production_list *pl;
	for (pl = instructions_nt->first_production_list; pl; pl = pl->next_production_list) {
		if (nl == pl->definition_language) {
			production *pr;
			for (pr = pl->first_production; pr; pr = pr->next_production) {
				@<Try to match the base text against this production@>;
			}
		}
	}

@ Each production in this language's |<verb-conjugation-instructions>| grammar
consists of a (possibly empty) pattern to match, followed by the name of a
nonterminal to use as the conjugation if it matches. For example, in
= (text as InC)
	-querir <fr-querir-conjugation>
=
the pattern part is a single token, |-querir|, which matches if the base text
is a single word whose last six characters are "querir". A more complicated
case is:
= (text as InC)
	be able to ... <to-be-able-to-auxiliary>
=
Here the wildcard |...| matches one or more words, and the "auxiliary
infinitive" form is set to the part matched by |...|: for example,
"be able to see" matches with auxiliary infinitive "see".

@<Try to match the base text against this production@> =
	ptoken *pt, *last = NULL;
	int len = 0, malformed = FALSE;
	for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) { last = pt; len++; }
	if ((len >= 1) && (last->ptoken_category == NONTERMINAL_PTC)) {
		if (conjugation_nt == NULL) { /* i.e., if we have not yet chosen a conjugation */
			int failed_to_match = FALSE, wildcard_from = -1;
			@<Try to match the base text against the pattern part of the production@>;
			if (failed_to_match == FALSE) {
				conjugation_nt = last->nt_pt;
				verb_forms[ADJOINT_INFINITIVE_FORM_TYPE] = verb_forms[BASE_FORM_TYPE];
				if (wildcard_from > 0)
					WordAssemblages::truncate(&(verb_forms[ADJOINT_INFINITIVE_FORM_TYPE]), wildcard_from);
				*aux_len = wildcard_from;
			}
		}
	} else malformed = TRUE;
	if (malformed)
		Conjugation::error(verb_forms[BASE_FORM_TYPE], <verb-conjugation-instructions>, pr,
			"malformed line");

@<Try to match the base text against the pattern part of the production@> =
	int word_count = 0;
	for (pt = pr->first_ptoken; ((pt) && (pt != last)); pt = pt->next_ptoken) {
		if (pt->ptoken_category == FIXED_WORD_PTC) {
			if ((word_count < base_text_word_count) &&
				(Conjugation::compare_ve_with_tails(base_text_words[word_count], pt->ve_pt)))
				word_count++;
			else failed_to_match = TRUE;
		} else if (pt->ptoken_category == MULTIPLE_WILDCARD_PTC) {
			wildcard_from = word_count;
			if (base_text_word_count <= word_count)
				failed_to_match = TRUE; /* must match at least one word */
		} else malformed = TRUE;
	}
	if (wildcard_from == -1) {
		if (word_count != base_text_word_count) failed_to_match = TRUE;
		wildcard_from = 0;
	}

@ In a conjugation, productions have two possible forms: either just a single
nonterminal, which usually identifies the tabulation, or a number followed by some
tokens.

@<Process the conjugation and determine the tabulation@> =
	production_list *pl;
	for (pl = conjugation_nt->first_production_list; pl; pl = pl->next_production_list) {
		if (nl == pl->definition_language) {
			production *pr;
			for (pr = pl->first_production; pr; pr = pr->next_production) {
				ptoken *pt;
				int len = 0, malformed = FALSE;
				for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) len++;
				switch (len) {
					case 1:
						if (pr->first_ptoken->ptoken_category == NONTERMINAL_PTC) {
							if (pr->first_ptoken->nt_pt == <auxiliary-verb-only>)
								*avo_flag = TRUE;
							else if (pr->first_ptoken->nt_pt == <not-instance-of-verb-at-run-time>)
								*niv_flag = TRUE;
							else
								tabulation_nt = pr->first_ptoken->nt_pt;
						} else malformed = TRUE;
						break;
					case 2:
						@<Set a verb form from the conjugation line@>;
						break;
					default: malformed = TRUE; break;
				}
				if (malformed)
					Conjugation::error(verb_forms[BASE_FORM_TYPE], conjugation_nt, pr,
						"malformed line");
			}
		}
	}

@ So here we check the more interesting case. The number identifies which
verb form to set, and the token which follows it provides the content. For
example:

|2 having| set to the literal text "having"
|3 1+ed| set to verb form 1 with "ed" suffixed
|3 <en-trie-past-participle>| run this trie on the base text and take the result

@<Set a verb form from the conjugation line@> =
	ptoken *number_token = pr->first_ptoken;
	ptoken *content_token = number_token->next_ptoken;
	int n = Conjugation::ptoken_to_verb_form_number(number_token);
	if (n >= 0) {
		if (n > *highest_form_written) { *highest_form_written = n; }
		if (content_token->ptoken_category == NONTERMINAL_PTC)
			verb_forms[n] =
				Inflections::apply_trie_to_wa(
					verb_forms[BASE_FORM_TYPE],
					Preform::Nonparsing::define_trie(content_token->nt_pt, TRIE_END, nl));
		else if (content_token->ptoken_category == FIXED_WORD_PTC)
			verb_forms[n] =
				Conjugation::expand_with_endings(content_token->ve_pt, verb_forms);
		else malformed = TRUE;
	} else malformed = TRUE;

@h Merge verb material.
Now the final main step. |row| points to a list of ptokens containing text,
and we have to copy that text into a word assemblage and return it.

In theory that's a one-line routine, but it's made complicated by the number
of special syntaxes which can go into the row of text. For example, if |row|
is only
= (text as InC)
	will not do
=
then the word assemblage comes out to just "will not do"; but if it is
= (text as InC)
	( t1 auxiliary-have ) done
=
then we consult tense 1 (present) of the verb "auxiliary-have", extract
the relevant slot, then append "done". (This might produce "have done"
or "has done" or "haven't done" or "hasn't done", depending on the
current sense and person.) We call the business of extracting text from
a different verb's conjugation "lifting".

There are other complications, too. See "English Inflections" for more.

=
word_assemblage Conjugation::merge(ptoken *row,
	int sense, int tense, int person, int num_ingredients, word_assemblage *ingredients,
	PREFORM_LANGUAGE_TYPE *nl, int *modal_following) {
	if (modal_following) { *modal_following = 0; }
	word_assemblage wa = WordAssemblages::lit_0();
	int verb_form_to_lift = -1;
	ptoken *chunk;
	for (chunk = row; chunk; chunk = chunk->next_ptoken) {
		@<A plus-plus-digit indicates auxiliary modal usage@>;
		@<A form number followed by a bracketed verb lifts the relevant form@>;
		@<A bracketed verb becomes a lift@>;
		@<A fixed word is simply added to the result@>;
		@<A nonterminal is a table of persons@>;
		internal_error("Error in merge material line");
	}
	return Conjugation::shorten_with_contractions(wa);
}

@ To take the easiest case first. If we read a word like |trailing|, we simply
add it. But note that |Conjugation::expand_with_endings| has other tricks up its sleeve,
and might expand |3+ed| to "trailed".

@<A fixed word is simply added to the result@> =
	if (chunk->ptoken_category == FIXED_WORD_PTC) {
		wa = WordAssemblages::join(wa, Conjugation::expand_with_endings(chunk->ve_pt, ingredients));
		continue;
	}

@ If we read a nonterminal name, such as |<fr-vivre-present>|, then this must
be a grammar with six productions, giving the text to use for the six different
persons. We consult |person| and extract the relevant text. For example, if
|person| is 3, we extract "vivons". Note that this material is itself read
in by a recursive use of |Conjugation::merge()|, because this enables it to
make use of the same fancy features we're allowing here.

@<A nonterminal is a table of persons@> =
	if (chunk->ptoken_category == NONTERMINAL_PTC) {
		production_list *pl;
		for (pl = chunk->nt_pt->first_production_list; pl; pl = pl->next_production_list) {
			int N = 0;
			production *pr;
			for (pr = pl->first_production; pr; pr = pr->next_production) {
				if (N == person)
					wa = WordAssemblages::join(wa,
						Conjugation::merge(pr->first_ptoken,
							sense, tense, person, num_ingredients, ingredients, nl, NULL));
				N++;
			}
		}
		continue;
	}

@ A number followed by a verb in brackets, like so:
= (text as InC)
	3 ( avoir )
=
expands to verb form 3 of this verb -- the past participle of "avoir", which
is "eu", as it happens. This is a special kind of lift. It isn't actually
performed now; we make a note and carry it out when we reach the brackets,
on the next iteration.

@<A form number followed by a bracketed verb lifts the relevant form@> =
	int X = Conjugation::ptoken_to_verb_form_number(chunk);
	if ((X >= 0) && (Conjugation::ptoken_as_bracket(chunk->next_ptoken))) {
		verb_form_to_lift = X;
		continue;
	}

@ And now the lift takes place. We might at this point have |verb_form_to_lift|
set, in which case we should lift a verb form, or we might not, in which case
we should lift an ordinary usage, such as third-person singular in a particular
tense. A lift can optionally change tense or sense: for example,
= (text as InC)
	( t1 have )
=
lifts from the present tense of "to have". If there's no tense indicator,
the tense remains the current one. (It's also possible to change the sense from
positive to negative or vice versa with this, though I can't think of a
language where this would be useful.) Note that, once again, the text of the
infinitive passes through |Conjugation::expand_with_endings|, so that it can make use
of the numbered verb forms if we want it to.

@<A bracketed verb becomes a lift@> =
	if (Conjugation::ptoken_as_bracket(chunk) == 1) {
		chunk = chunk->next_ptoken; /* move past open bracket */

		/* if there is a tense/sense indicator, use it, and move forward */
		int S = -1;
		int T = Conjugation::ptoken_to_tense_indicator(chunk, &S) - 1;
		if (T >= 0) chunk = chunk->next_ptoken; else T = tense;
		if (S == -1) S = sense;

		/* extract the text of the infinitive */
		word_assemblage verb_lifted = WordAssemblages::lit_0();
		while ((chunk) && (Conjugation::ptoken_as_bracket(chunk) != -1)) {
			verb_lifted = WordAssemblages::join(verb_lifted,
				Conjugation::expand_with_endings(chunk->ve_pt, ingredients));
			chunk = chunk->next_ptoken;
		}

		verb_conjugation *aux = Conjugation::find_by_infinitive(verb_lifted);
		if (aux == NULL) aux = Conjugation::conjugate(verb_lifted, nl);
		if (aux == NULL) internal_error("can't conjugate lifted verb");
		switch (verb_form_to_lift) {
			case 1: wa = WordAssemblages::join(wa, aux->infinitive); break;
			case 2: wa = WordAssemblages::join(wa, aux->present_participle); break;
			case 3: wa = WordAssemblages::join(wa, aux->past_participle); break;
			case -1: wa = WordAssemblages::join(wa, aux->tabulations[ACTIVE_MOOD].vc_text[T][S][person]);
				break;
			default: internal_error("only parts 1, 2, 3 can be extracted");
		}
		continue;
	}

@<A plus-plus-digit indicates auxiliary modal usage@> =
	if (chunk->ptoken_category == FIXED_WORD_PTC) {
		wchar_t *p = Vocabulary::get_exemplar(chunk->ve_pt, TRUE);
		if ((p[0] == '+') && (p[1] == '+') && (Characters::isdigit(p[2])) && (p[3] == 0)) {
			if (modal_following) {
				*modal_following = ((int) p[2]) - ((int) '0');
			}
			continue;
		}
	}

@ Whenever we read a single word, it passes through the following. A word
like "fish" will pass through unchanged; a number like "7" will convert
to verb form 7 in the current verb (for example, 2 becomes the present
participle); a plus sign joins two pieces together; and a tilde is a tie,
joining but with a space. Thus |fish~to~fry| becomes three words.

=
word_assemblage Conjugation::expand_with_endings(vocabulary_entry *ve, word_assemblage *verb_forms) {
	if (ve == NULL) return WordAssemblages::lit_0();

	wchar_t *p = Vocabulary::get_exemplar(ve, TRUE);
	int i;
	for (i=0; p[i]; i++)
		if ((i>0) && (p[i+1]) && ((p[i] == '+') || (p[i] == '~'))) {
			vocabulary_entry *front =
				Vocabulary::entry_for_partial_text(p, 0, i-1);
			vocabulary_entry *back =
				Vocabulary::entry_for_partial_text(p, i+1, Wide::len(p)-1);
			word_assemblage front_wa = Conjugation::expand_with_endings(front, verb_forms);
			word_assemblage back_wa = Conjugation::expand_with_endings(back, verb_forms);
			TEMPORARY_TEXT(TEMP);
			WRITE_TO(TEMP, "%A", &front_wa);
			if (p[i] == '~') PUT_TO(TEMP, ' ');
			WRITE_TO(TEMP, "%A", &back_wa);
			wording W = Feeds::feed_stream(TEMP);
			DISCARD_TEXT(TEMP);
			return WordAssemblages::from_wording(W);
		}

	int X = Conjugation::ve_to_verb_form_number(ve);
	if (X >= 0) return verb_forms[X];

	return WordAssemblages::lit_1(ve);
}

@ The final step in merging verb material is to pass the result through the
following, which attends to contractions. (Most of the time it does nothing.)
For example, suppose we have:
= (text as InC)
	ne-' ai pas
=
The |-'| marker tells us that the word it attaches to should contract if a
vowel follows it. In this case that's what happens, so we convert to:
= (text as InC)
	n'ai pas
=
On the other hand,
= (text as InC)
	ne-' jette pas
=
would convert to
= (text as InC)
	ne jette pas
=
with no contraction. Either way, though, we have to take some action when
we see a |-'| marker.

=
word_assemblage Conjugation::shorten_with_contractions(word_assemblage wa) {
	vocabulary_entry **words;
	int word_count;
	WordAssemblages::as_array(&wa, &words, &word_count);
	int i;
	for (i=0; i<word_count-1; i++) {
		wchar_t *p = Vocabulary::get_exemplar(words[i], TRUE);
		wchar_t *q = Vocabulary::get_exemplar(words[i+1], TRUE);
		int j = Wide::len(p)-2;
		if ((j >= 0) && (p[j] == '-') && (p[j+1] == '\'')) {
			TEMPORARY_TEXT(TEMP);
			int contract_this = FALSE;
			@<Decide whether a contraction is needed here@>;
			if (contract_this) {
				int k;
				for (k=0; k<j-1; k++) { WRITE_TO(TEMP, "%c", p[k]); }
				WRITE_TO(TEMP, "'%w", q);
				wording W = Feeds::feed_stream(TEMP);
				words[i] = Lexer::word(Wordings::first_wn(W));
				for (k=i+1; k<word_count; k++) words[k] = words[k+1];
				word_count--;
				WordAssemblages::truncate_to(&wa, word_count);
			} else {
				int k;
				for (k=0; k<j; k++) { WRITE_TO(TEMP, "%c", p[k]); }
				wording W = Feeds::feed_stream(TEMP);
				words[i] = Lexer::word(Wordings::first_wn(W));
			}
			DISCARD_TEXT(TEMP);
		}
	}
	return wa;
}

@ We contract if the following word starts with a (possibly accented) vowel,
and we construe "y" (but not "h" or "w") as a vowel.

@<Decide whether a contraction is needed here@> =
	int incipit = q[0];
	int first = tolower(Characters::remove_accent(incipit));
	if ((first == 'a') || (first == 'e') || (first == 'i') ||
		(first == 'o') || (first == 'u') || (first == 'y'))
		contract_this = TRUE;

@h Parsing verb form numbers.
These are easy: they're just written as arabic numbers.

=
int Conjugation::ptoken_to_verb_form_number(ptoken *pt) {
	if ((pt) && (pt->ptoken_category == FIXED_WORD_PTC))
		return Conjugation::ve_to_verb_form_number(pt->ve_pt);
	return -1;
}

int Conjugation::ve_to_verb_form_number(vocabulary_entry *ve) {
	if (Vocabulary::test_vflags(ve, NUMBER_MC)) {
		int X = Vocabulary::get_literal_number_value(ve);
		if ((X >= 0) && (X < MAX_FORM_TYPES)) return X;
	}
	return -1;
}

@h Parsing tense and sense indicators.
These are a little harder: for example, |t2+| or |t3|.

=
int Conjugation::ptoken_to_tense_indicator(ptoken *pt, int *set_sense) {
	if ((pt) && (pt->ptoken_category == FIXED_WORD_PTC)) {
		vocabulary_entry *ve = pt->ve_pt;
		wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
		if ((p[0] == 't') && (Characters::isdigit(p[1])) && (p[2] == 0)) {
			int N = p[1] - '1' + 1;
			if ((N >= 1) && (N <= NO_KNOWN_TENSES)) return N;
		}
		if ((p[0] == 't') && (Characters::isdigit(p[1])) && (p[2] == '+') && (p[3] == 0)) {
			int N = p[1] - '1' + 1;
			if ((N >= 1) && (N <= NO_KNOWN_TENSES)) {
				*set_sense = 0; return N;
			}
		}
		if ((p[0] == 't') && (Characters::isdigit(p[1])) && (p[2] == '-') && (p[3] == 0)) {
			int N = p[1] - '1' + 1;
			if ((N >= 1) && (N <= NO_KNOWN_TENSES)) {
				*set_sense = 1; return N;
			}
		}
	}
	return -1;
}

@h Parsing utilities.

=
int Conjugation::ptoken_as_bracket(ptoken *pt) {
	if ((pt) && (pt->ptoken_category == FIXED_WORD_PTC)) {
		vocabulary_entry *ve = pt->ve_pt;
		if (ve == OPENBRACKET_V) return 1;
		if (ve == CLOSEBRACKET_V) return -1;
	}
	return 0;
}

@ In the following, for example, "breveter" as |ve| would match "-veter"
as |pattern|.

=
int Conjugation::compare_ve_with_tails(vocabulary_entry *ve, vocabulary_entry *pattern) {
	if (ve == pattern) return TRUE;
	wchar_t *p = Vocabulary::get_exemplar(pattern, FALSE);
	if (p[0] == '-') {
		wchar_t *q = Vocabulary::get_exemplar(ve, FALSE);
		int i, j = Wide::len(q)-(Wide::len(p)-1);
		for (i=1; p[i]; i++, j++)
			if ((j<0) || (p[i] != q[j]))
				return FALSE;
		return TRUE;
	}
	return FALSE;
}

@h Errors.
People are going to get their conjugations wrong; it's a very hard notation
to learn. No end users of Inform will ever write them at all -- this is a
low-level feature for translators only -- but translators need all the help
they can get, so we'll try to provide good problem messages.

=
void Conjugation::trie_definition_error(nonterminal *nt, production *pr, char *message) {
	Conjugation::basic_problem_handler(WordAssemblages::lit_0(), nt, pr, message);
}

@ And similarly:

=
void Conjugation::error(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	Conjugation::basic_problem_handler(base_text, nt, pr, message);
	exit(1);
}

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_SYNTAX_CALLBACK|
to some routine of her own, gazumping this one.

=
void Conjugation::basic_problem_handler(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	#ifdef INFLECTIONS_ERROR_HANDLER
	INFLECTIONS_ERROR_HANDLER(base_text, nt, pr, message);
	#endif
	#ifndef INFLECTIONS_ERROR_HANDLER
	if (pr) {
		LOG("The production at fault is:\n");
		Preform::log_production(pr, FALSE); LOG("\n");
	}
	TEMPORARY_TEXT(ERM);
	if (nt == NULL)
		WRITE_TO(ERM, "(no nonterminal)");
	else
		WRITE_TO(ERM, "nonterminal %w", Vocabulary::get_exemplar(nt->nonterminal_id, FALSE));
	WRITE_TO(ERM, ": ");

	if (WordAssemblages::nonempty(base_text))
		WRITE_TO(ERM, "can't conjugate verb '%A': ", &base_text);

	if (pr) {
		TEMPORARY_TEXT(TEMP);
		for (ptoken *pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
			Preform::write_ptoken(TEMP, pt);
			if (pt->next_ptoken) WRITE_TO(TEMP, " ");
		}
		WRITE_TO(ERM, "line %d ('%S'): ", pr->match_number, TEMP);
		DISCARD_TEXT(TEMP);
	}
	WRITE_TO(ERM, "%s", message);
	Errors::with_text("Preform error: %S", ERM);
	DISCARD_TEXT(ERM);
	#endif
}

@h Testing.
Similarly, the following helps translators by giving them unit tests for their
conjugations:

>> Test verb (internal) with appuyer.

=
void Conjugation::test(OUTPUT_STREAM, wording W, PREFORM_LANGUAGE_TYPE *nl) {
	verb_conjugation *vc = Conjugation::conjugate(
		WordAssemblages::from_wording(W), nl);
	if (vc == NULL) { WRITE("Failed test\n"); return; }
	Conjugation::write(OUT, vc);
	DESTROY(vc, verb_conjugation);
}

void Conjugation::write(OUTPUT_STREAM, verb_conjugation *vc) {
	WRITE("Infinitive: %A / Present participle: %A / Past participle: %A^",
		&(vc->infinitive), &(vc->present_participle), &(vc->past_participle));
	int mood_count = 2;
	if (WordAssemblages::nonempty(vc->tabulations[PASSIVE_MOOD].to_be_auxiliary)) mood_count = 1;
	int mood, sense, tense, person;
	for (mood=0; mood<mood_count; mood++) {
		for (sense=0; sense<2; sense++) {
			if (mood == 0) WRITE("Active "); else WRITE("Passive ");
			if (sense == 0) WRITE("positive^"); else WRITE("negative^");
			for (tense=0; tense<7; tense++) {
				WRITE("Tense %d: ", tense);
				for (person=0; person<6; person++) {
					word_assemblage *wa;
					if (mood == 0) wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][person]);
					else wa = &(vc->tabulations[PASSIVE_MOOD].vc_text[tense][sense][person]);
					if (person > 0) WRITE(" / ");
					if (WordAssemblages::nonempty(*wa)) WRITE("%A", wa);
					else WRITE("--");
				}
				WRITE("^");
			}
		}
	}
	if (WordAssemblages::nonempty(vc->tabulations[PASSIVE_MOOD].to_be_auxiliary))
		WRITE("Form passive as to be + %A\n", &(vc->tabulations[PASSIVE_MOOD].to_be_auxiliary));
}

verb_conjugation *Conjugation::find_by_infinitive(word_assemblage infinitive) {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		if (WordAssemblages::compare(&infinitive, &(vc->infinitive)))
			return vc;
	return NULL;
}

verb_conjugation *Conjugation::find_prior(verb_conjugation *nvc) {
	if (nvc == NULL) return NULL;
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation) {
		if (vc != nvc) {
			if (WordAssemblages::compare(&(nvc->infinitive), &(vc->infinitive)) == FALSE) continue;
			if (WordAssemblages::compare(&(nvc->past_participle), &(vc->past_participle)) == FALSE) continue;
			if (WordAssemblages::compare(&(nvc->present_participle), &(vc->present_participle)) == FALSE) continue;
			int match = TRUE;
			for (int i=0; i<NO_KNOWN_MOODS; i++) {
				verb_tabulation *nvt = &(nvc->tabulations[i]);
				verb_tabulation *vt = &(vc->tabulations[i]);
				if (WordAssemblages::compare(&(nvt->to_be_auxiliary), &(vt->to_be_auxiliary)) == FALSE) match = FALSE;
				for (int p=0; p<6; p++)
					for (int s=0; s<2; s++)
						for (int t=0; t<NO_KNOWN_TENSES; t++) {
							if (WordAssemblages::compare(&(nvt->vc_text[t][s][p]), &(vt->vc_text[t][s][p])) == FALSE) match = FALSE;
							if (nvt->modal_auxiliary_usage[t][s][p] != vt->modal_auxiliary_usage[t][s][p]) match = FALSE;
						}
			}
			if (match == FALSE) continue;
			return vc;
		}
	}
	return NULL;
}

@ This is for testing English only; it helps with the test suite cases derived
from our dictionary of 14,000 or so present and past participles.

=
void Conjugation::test_participle(OUTPUT_STREAM, wording W) {
	verb_conjugation *vc = Conjugation::conjugate(
		WordAssemblages::from_wording(W), English_language);
	if (vc == NULL) { WRITE("Failed test\n"); return; }
	Conjugation::write_participle(OUT, vc);
	DESTROY(vc, verb_conjugation);
}

void Conjugation::write_participle(OUTPUT_STREAM, verb_conjugation *vc) {
	WRITE("To %A: he is %A; it was %A.\n",
		&(vc->infinitive), &(vc->present_participle), &(vc->past_participle));
}

@ As noted above, these nonterminals have no parsing function, and are used only
as markers in verb conjugations.

=
<auxiliary-verb-only> internal {
	return FALSE;
}

<not-instance-of-verb-at-run-time> internal {
	return FALSE;
}
