[NewVerbRequests::] New Verb Requests.

Special sentences for creating new verbs.

@ There are two ways to make new verbs: one can equivalently say "To carry is
a verb meaning the carrying relation" or "To carry means the carrying
relation". One is a special meaning of "to be", the other of "to mean", but
they come to the same thing in the end.

First, this special meaning of "X is Y" is accepted only when Y matches:

=
<new-verb-sentence-object> ::=
	<indefinite-article> <new-verb-sentence-object-unarticled> |     ==> { pass 2 }
	<new-verb-sentence-object-unarticled>							 ==> { pass 1 }

<new-verb-sentence-object-unarticled> ::=
	verb |                                                           ==> { -, NULL }
	verb implying/meaning <definite-article> nounphrase-unparsed> |  ==> { -, RP[2] }
	verb implying/meaning <np-unparsed>                              ==> { -, RP[1] }

@ =
int NewVerbRequests::new_verb_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "To grow is a verb." */
		case ACCEPT_SMFT:
			if (<new-verb-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				NewVerbRequests::parse_new(NEW_SVO_VERB, V);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ Second, this handles the special meaning "The verb X means...".

=
<verb-means-sentence-subject> ::=
	<definite-article> <verb-means-sentence-subject-unarticled> |  ==> { pass 2 }
	<verb-means-sentence-subject-unarticled>                       ==> { pass 1 }

<verb-means-sentence-subject-unarticled> ::=
	verb to |                                                      ==> { fail }
	verb <np-unparsed> in the imperative |                         ==> { NEW_IMPERATIVE_VERB, RP[1] }
	verb <np-unparsed> |                                           ==> { NEW_SVO_VERB, RP[1] }
	operator <np-unparsed>                                         ==> { NEW_OPERATOR_VERB, RP[1] }

<verb-implies-sentence-subject> ::=
	in <natural-language> <infinitive-declaration> |  ==> { R[2], RP[1] }
	<infinitive-declaration>                          ==> { R[1], DefaultLanguage::get(NULL) }

<infinitive-declaration> ::=
	to <infinitive-usage> ( ... ) |                   ==> { R[1], -, <<giving-parts>> = TRUE }
	to <infinitive-usage> |                           ==> { R[1], -, <<giving-parts>> = FALSE }
	<infinitive-usage> ( ... ) |                      ==> { R[1], -, <<giving-parts>> = TRUE }
	<infinitive-usage>                                ==> { R[1], -, <<giving-parts>> = FALSE }

<infinitive-usage> ::=
	{be able to ...} |                                ==> { TRUE, - }
	{be able to} |                                    ==> { TRUE, - }
	...                                               ==> { FALSE, - }

@ =
int NewVerbRequests::verb_means_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The verb to grow means the growing relation." */
		case ACCEPT_SMFT:
			if (<verb-means-sentence-subject>(SW)) {
				int usage = <<r>>;
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				NewVerbRequests::parse_new(usage, V);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ And the above share the following. |usage| will be one of these:

@d NEW_IMPERATIVE_VERB 1
@d NEW_SVO_VERB 2
@d NEW_OPERATOR_VERB 3

=
void NewVerbRequests::parse_new(int usage, parse_node *V) {
	wording PW = EMPTY_WORDING; /* wording of the parts of speech */
	verb_meaning vm = VerbMeanings::meaninglessness(); int meaning_given = FALSE;
	int priority = -1;
	if (V->next->next) @<Find the verb meaning and priority@>;

	if (usage == NEW_OPERATOR_VERB) @<Handle a new operator verb@>
	else @<Handle a new verbal verb@>;
}

@ Note that numerical comparisons are handled by two methods. Verbally, they are
prepositions: "less than", for instance, is combined with "to be", giving us
"A is less than B" and similar forms. These wordy forms are therefore defined
as prepositional usages and created as such in Basic Inform. But we also
permit the use of the familiar mathematical symbols |<|, |>|, |<=| and |>=|.
Inform treats these as "operator verbs" without tense, so registers them as
verb usages, but without the full conjugation given to a conventional verb;
and they are also excluded from the lexicon in the Phrasebook index, being
notation rather than words. (This is why the variable |current_main_verb| is
cleared.)

=
@<Handle a new operator verb@> =
	wording W = Node::get_text(V->next);
	current_main_verb = NULL;
	verb *v = Verbs::new_operator_verb(vm);
	grammatical_usage *gu = Stock::new_usage(v->in_stock, Task::language_of_syntax());
	lcon_ti l = Verbs::to_lcon(v);
	l = Lcon::set_voice(l, ACTIVE_VOICE);
	l = Lcon::set_tense(l, IS_TENSE);
	l = Lcon::set_sense(l, POSITIVE_SENSE);
	l = Lcon::set_person(l, THIRD_PERSON);
	l = Lcon::set_number(l, SINGULAR_NUMBER);
	Stock::add_form_to_usage(gu, l);
	VerbUsages::new(WordAssemblages::from_wording(W), FALSE, gu, NULL);

@<Handle a new verbal verb@> =
	if (<verb-implies-sentence-subject>(Node::get_text(V->next))) {
		inform_language *nl = <<rp>>;
		int r = <<r>>;
		wording W = GET_RW(<infinitive-usage>, 1);
		if (<<giving-parts>>) PW = GET_RW(<infinitive-declaration>, 1);
		int unexpected_upper_casing_used = FALSE;
		@<Determine if unexpected upper casing is used in wording@>;

		wording V = W;
		wording P = EMPTY_WORDING;
		wording SP = EMPTY_WORDING;
		int divided = FALSE;
		LOOP_THROUGH_WORDING(pos, W) {
			if ((Lexer::word(pos) == PLUS_V) &&
				(pos > Wordings::first_wn(W)) && (pos < Wordings::last_wn(W))) {
				divided = TRUE;
				SP = Wordings::from(W, pos+1);
				V = Wordings::up_to(V, pos-1);
				W = Wordings::up_to(W, pos-1);
				break;
			}
		}
		if ((Wordings::length(W) > 1) && (r == FALSE)) {
			V = Wordings::first_word(W);
			P = Wordings::trim_first_word(W);
		}
		if ((Wordings::length(P) > MAX_WORDS_IN_PREPOSITION) ||
			(Wordings::length(SP) > MAX_WORDS_IN_PREPOSITION)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_PrepositionLong),
				"prepositions can be very long indeed in today's Inform",
				"but not as long as this.");
			return;
		}
		verb *vi = NULL;
		preposition *prep = NULL;
		preposition *second_prep = NULL;
		if (Wordings::nonempty(V)) @<Find or create a new verb@>;
		if (Wordings::nonempty(P))
			prep = Prepositions::make(WordAssemblages::from_wording(P),
				unexpected_upper_casing_used, current_sentence);
		if (Wordings::nonempty(SP))
			second_prep = Prepositions::make(WordAssemblages::from_wording(SP),
				unexpected_upper_casing_used, current_sentence);

		if (meaning_given) {
			verb_meaning *current =
				Verbs::first_unspecial_meaning_of_verb_form(
					Verbs::find_form(vi, prep, second_prep));
			if (VerbMeanings::is_meaningless(current) == FALSE) {
				LOG("Currently $w means $y\n", vi, current);
				parse_node *where = VerbMeanings::get_where_assigned(current);
				@<Issue the actual problem message@>;
			}
		}

		int structures = 0;
		if (usage == NEW_IMPERATIVE_VERB) {
			if (divided) structures = VOO_FS_BIT;
			structures = VO_FS_BIT;
		} else {
			if (divided) structures = SVOO_FS_BIT;
			else structures = SVO_FS_BIT;
		}

		Verbs::add_form(vi, prep, second_prep, vm, structures);
	}

@ And now for the definition grammar.

The handling of |PROP_VERBM| perhaps looks odd. What happens if the user typed

>> The verb to be mystified by implies the arfle barfle gloop property.

when there is no property of that name? The answer is that we can't check this
at the time we're parsing this sentence, because verb definitions are read long
before properties come into existence. The check will be made later on, and for
now absolutely any non-empty word range is accepted as the property name.

@d PROP_VERBM 1
@d REL_VERBM 2
@d VM_VERBM 3
@d BUILTIN_VERBM 4
@d NONE_VERBM 5

=
<verb-definition> ::=
	reversed <relation-name> relation |  ==> { REL_VERBM, BinaryPredicates::get_reversal(RP[1]) }
	<relation-name> relation |           ==> { REL_VERBM, RP[1] }
	to <instance-of-infinitive-form> |   ==> @<Use verb infinitive as shorthand@>
	... property |                       ==> { PROP_VERBM, - }
	built-in ... meaning |               ==> { BUILTIN_VERBM, - }
	... relation |                       ==> @<Issue PM_VerbRelationUnknown problem@>
	{relation} |                         ==> @<Issue PM_VerbRelationVague problem@>
	...                                  ==> @<Issue PM_VerbUnknownMeaning problem@>

@<Issue PM_VerbRelationUnknown problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_VerbRelationUnknown),
		"new verbs can only be defined in terms of existing relations",
		"all of which have names ending 'relation': thus '...implies the "
		"possession relation' is an example of a valid definition, this "
		"being one of the relations built into Inform.");
	==> { NONE_VERBM, - };

@<Issue PM_VerbRelationVague problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_VerbRelationVague),
		"that's too vague",
		"calling a relation simply 'relation'.");
	==> { NONE_VERBM, - };

@<Issue PM_VerbUnknownMeaning problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_VerbUnknownMeaning),
		"I don't see what the meaning of this verb ought to be",
		"because it doesn't take any of the three forms I know: a relation "
		"name ('...means the wearing relation'), a property name ('...means "
		"the matching key property'), or another verb ('...means to wear.').");
	==> { NONE_VERBM, - };

@<Use verb infinitive as shorthand@> =
	verb_form *vf = RP[1];
	verb_meaning *vm = Verbs::first_unspecial_meaning_of_verb_form(vf);
	if (vm) {
		==> { VM_VERBM, vm };
	} else {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that's another verb which has no meaning at present",
			"so this doesn't help me.");
		==> { NONE_VERBM, - };
	}

@ So we can now use the above grammar to understand the definition of the verb.
Note that it is legal, but does nothing, to request a built-in meaning which
does not exist: this allows for Basic Inform to mention built-in meanings
which exist only when certain features are active.

@<Find the verb meaning and priority@> =
	<verb-definition>(Node::get_text(V->next->next));
	switch (<<r>>) {
		case PROP_VERBM: {
			wording RW = GET_RW(<verb-definition>, 1);
			vm = VerbMeanings::regular(
				SettingPropertyRelations::make_set_property_BP(RW));
			break;
		}
		case REL_VERBM:
			vm = VerbMeanings::regular(<<rp>>);
			break;
		case BUILTIN_VERBM: {
			wording MW = GET_RW(<verb-definition>, 1);
			special_meaning_holder *smh = SpecialMeanings::find_from_wording(MW);
			if (smh == NULL) {
				return;
			} else {
				vm = VerbMeanings::special(smh);
				priority = SpecialMeanings::get_metadata_N(smh);
			}
			break;
		}
		case VM_VERBM: vm = *((verb_meaning *) (<<rp>>)); break;
		default: return;
	}
	meaning_given = TRUE;

@ Casing problems are acutely problematic with prepositions, because so many
locations have names which begin with them -- "Under Milkwood", "Inside the
Machine", "On Top of Old Smoky". Our best way to avoid confusion is to read
prepositions as such only when they do not unexpectedly jump into upper case,
i.e., to distinguish between the meanings of

>> X is in Bahrain. Y is In Bahrain.

according to the unexpected capital I in the second "In". But just occasionally
people do want to define prepositions which genuinely involve an unexpected
upper-case letter; and those we flag for special treatment, since otherwise
they could never be parsed successfully.

@<Determine if unexpected upper casing is used in wording@> =
	LOOP_THROUGH_WORDING(i, W)
		if (Word::unexpectedly_upper_case(i))
			unexpected_upper_casing_used = TRUE;

@<Find or create a new verb@> =
	word_assemblage infinitive = WordAssemblages::from_wording(V);
	verb_conjugation *vc = NULL;
	@<Conjugate the new verb@>;

	vi = vc->vc_conjugates;
	if (vi == NULL) @<Register the new verb's usage@>;

@<Conjugate the new verb@> =
	word_assemblage present_singular = WordAssemblages::lit_0();
	word_assemblage present_plural = WordAssemblages::lit_0();
	word_assemblage past = WordAssemblages::lit_0();
	word_assemblage past_participle = WordAssemblages::lit_0();
	word_assemblage participle = WordAssemblages::lit_0();
	if (Wordings::nonempty(PW)) {
		int improper_parts = FALSE;
		@<Parse the parts of speech supplied for the verb@>;
		if (improper_parts) @<Give up on verb definition as malformed@>;
	}
	word_assemblage overrides[7];
	int no_overrides = 7;
	overrides[BASE_FORM_TYPE] = WordAssemblages::lit_0();
	overrides[INFINITIVE_FORM_TYPE] = present_plural;
	overrides[PAST_PARTICIPLE_FORM_TYPE] = past_participle;
	overrides[PRESENT_PARTICIPLE_FORM_TYPE] = participle;
	overrides[ADJOINT_INFINITIVE_FORM_TYPE] = WordAssemblages::lit_0();
	overrides[5] = present_singular;
	overrides[6] = past;

	verb_conjugation *nvc = Conjugation::conjugate_with_overrides(infinitive,
		overrides, no_overrides, nl);

	vc = Conjugation::find_prior(nvc);
	if (vc == NULL) vc = nvc;

	if (Wordings::nonempty(PW)) {
		if ((vc) && (vc->vc_conjugates == copular_verb))
			@<Reject with a problem message if preposition is conjugated@>;
	}

@ The syntax allowing parts of speech to be given in brackets goes back to
the very early days of Inform, and is now deprecated. It generalises badly to
other languages, and doesn't even work perfectly for English.

The problem is that the source text is allowed to give only a selection of the
parts of the verb, and Inform has to guess which parts. So how does it
distinguish "X is suspected" from "X is suspecting"? It needs to know which is
the present participle, and it does this by looking for an -ing ending on
either the first or last word.

We read the parts of speech as a comma-separated list of individual parts
(but we don't allow "and" or "or" to divide this list: only commas).

At the end, if no present plural is supplied, we may as well use the
infinitive for that -- the two are the same in most regular English verbs
("to sleep", "they sleep") even if not irregular ones ("to be", "they are").

@<Parse the parts of speech supplied for the verb@> =
	int more_to_read = TRUE;
	int participle_count = 0;
	while (more_to_read) {
		wording CW = EMPTY_WORDING;
		if (<list-comma-division>(PW)) {
			CW = GET_RW(<list-comma-division>, 1);
			PW = GET_RW(<list-comma-division>, 2);
			more_to_read = TRUE;
		} else {
			CW = PW;
			more_to_read = FALSE;
		}
		@<Parse the part of speech in this clause@>;
	}
	if (WordAssemblages::nonempty(present_plural) == FALSE)
		present_plural = infinitive;

@ These two nonterminals are needed:

=
<conjugation> ::=
	<subject-pronoun> is/are ... |  ==> { 0, RP[1], <<is-participle>> = TRUE }
	<subject-pronoun> ...           ==> { 0, RP[1], <<is-participle>> = FALSE }

<participle-like> ::=
	<probable-participle> *** |
	*** <probable-participle>

@ A single English verb, such as "to contain", produces numerous |verb_usage|
objects, since we have one for each combination of tense, number and negation
-- "contains", "had not contained", etc. These have upper limits on their
sizes, not so much from the language definition as from limitations on our
implementation of it. But in practice they should never be reached.

@d MAX_WORDS_IN_VERB (MAX_WORDS_IN_ASSEMBLAGE - 4)

@<Parse the part of speech in this clause@> =
	if ((<conjugation>(CW)) == FALSE)
		@<Give up on verb definition as malformed@>;
	CW = GET_RW(<conjugation>, 1);
	pronoun_usage *pu = (pronoun_usage *) <<rp>>;
	int number = PLURAL_NUMBER;
	if (Stock::usage_might_be_singular(pu->usage)) number = SINGULAR_NUMBER;
	int is_a_participle = <<is-participle>>;

	if (Wordings::nonempty(P)) {
		int L = Wordings::length(P), C = Wordings::length(CW);
		if (C >= L) {
			wording T = Wordings::from(CW, Wordings::first_wn(CW) + C-L);
			if (Wordings::match(T, P)) {
				if (C > L) CW = Wordings::truncate(CW, C-L);
				else CW = EMPTY_WORDING;
			} else improper_parts = TRUE;
		} else improper_parts = TRUE;
	}

	if (Wordings::length(CW) > 0) {
		if (Wordings::length(CW) > MAX_WORDS_IN_VERB)
			@<Give up on verb definition as malformed@>;

		if (is_a_participle) {
			participle_count++;
			if ((<participle-like>(CW)) ||
				(WordAssemblages::nonempty(past_participle)))
				participle = WordAssemblages::from_wording(CW);
			else
				past_participle = WordAssemblages::from_wording(CW);
		} else {
			if (number == PLURAL_NUMBER) {
				if (WordAssemblages::nonempty(present_plural)) {
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_PresentPluralTwice),
						"the present plural has been given twice",
						"since two of the principal parts of this verb begin "
						"with 'they'.");
				}
				present_plural = WordAssemblages::from_wording(CW);
			} else {
				if (WordAssemblages::nonempty(present_singular))
					past = WordAssemblages::from_wording(CW);
				else
					present_singular = WordAssemblages::from_wording(CW);
			}
		}
	}

@ A catch-all problem message:

@<Give up on verb definition as malformed@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_VerbMalformed),
		"this verb's definition is malformed",
		"and should have its principal parts supplied like so: 'The verb "
		"to sport (he sports, they sport, he sported, it is sported, "
		"he is sporting) ...'.");
	return;

@ This funny little problem message is the price we pay for blurring grammar
in the syntax provided for users. Prepositions do not inflect in English
when used in different tenses or when negated, so there's no conjugation
involved, and we need to reject any attempt -- even though it would be
perfectly valid if a verb were being defined.

@<Reject with a problem message if preposition is conjugated@> =
	if (Wordings::nonempty(PW)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_PrepositionConjugated),
			"the principal parts of 'to be' are known already",
			"so should not be spelled out again as part of the instructions "
			"for this new preposition.");
		return;
	}

@<Issue the actual problem message@> =
	if (where)
		StandardProblems::two_sentences_problem(_p_(PM_DuplicateVerbs1),
			where,
			"this gives us two definitions of what appears to be the same verb",
			"or at least has the same infinitive form.");
	else
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(BelievedImpossible),
			"this verb definition appears to clash with a built-in verb",
			"a table of which can be seen on the Phrasebook index.");

@ The "priority" of a verb in an assertion affects which reading is chosen
in the case of ambiguity, with lower numbers preferred. See //linguistics//.

@<Register the new verb's usage@> =
	int p = 4;
	binary_predicate *bp = VerbMeanings::get_regular_meaning(&vm);
	if (bp == a_has_b_predicate) p = 1;
	if (bp == R_equality) p = 2;
	if ((nl) && (nl != DefaultLanguage::get(NULL))) p = 5;
	vi = Verbs::new_verb(vc, FALSE);
	vc->vc_conjugates = vi;
	if (priority >= 1) p = priority;
	VerbUsages::register_all_usages_of_verb(vi, unexpected_upper_casing_used,
		p, current_sentence);
