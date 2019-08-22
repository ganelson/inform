[NewVerbs::] New Verbs.

To define verbal forms for relations, in different tenses and numbers.

@h Definitions.

@ A single English verb, such as "to contain", produces numerous |verb_usage|
objects, since we have one for each combination of tense, number and negation
-- "contains", "had not contained", etc. These have upper limits on their
sizes, not so much from the language definition as from limitations on our
implementation of it. But in practice they should never be reached.

@d MAX_WORDS_IN_VERB (MAX_WORDS_IN_ASSEMBLAGE - 4)

@ =
typedef struct special_meaning_holder {
	int (*sm_func)(int, parse_node *, wording *); /* (for tangling reasons, can't use typedef here) */
	struct text_stream *sm_name;
	int verb_priority;
	MEMORY_MANAGEMENT
} special_meaning_holder;

@h Inequalities as operator verbs.
Note that numerical comparisons are handled by two methods. Verbally, they are
prepositions: "less than", for instance, is combined with "to be", giving us
"A is less than B" and similar forms. These wordy forms are therefore defined
as prepositional usages and created as such in the Standard Rules. But we also
permit the use of the familiar mathematical symbols |<|, |>|, |<=| and |>=|.
Inform treats these as "operator verbs" without tense, so registers them as
verb usages, but without the full conjugation given to a conventional verb;
and they are also excluded from the lexicon in the Phrasebook index, being
notation rather than words. (This is why the variable |current_main_verb| is
cleared.)

=
<inequality-conjugations> ::=
	< |			/* implies the numerically-less-than relation */
	> |			/* implies the numerically-greater-than relation */
	<= |		/* implies the numerically-less-than-or-equal-to relation */
	>=			/* implies the numerically-greater-than-or-equal-to relation */


=
void NewVerbs::add_inequalities(void) {
	NewVerbs::add_inequalities_inner(
		NewVerbs::ineq_vm(R_numerically_less_than),
		NewVerbs::ineq_vm(R_numerically_greater_than),
		NewVerbs::ineq_vm(R_numerically_less_than_or_equal_to),
		NewVerbs::ineq_vm(R_numerically_greater_than_or_equal_to));
}

void NewVerbs::add_inequalities_inner(verb_meaning lt, verb_meaning gt, verb_meaning le, verb_meaning ge) {
	set_where_created = NULL;
	current_main_verb = NULL;
	VerbUsages::register_single_usage(Preform::Nonparsing::wording(<inequality-conjugations>, 0),
		FALSE, IS_TENSE, ACTIVE_MOOD, Verbs::new_operator_verb(lt), FALSE);
	VerbUsages::register_single_usage(Preform::Nonparsing::wording(<inequality-conjugations>, 1),
		FALSE, IS_TENSE, ACTIVE_MOOD, Verbs::new_operator_verb(gt), FALSE);
	VerbUsages::register_single_usage(Preform::Nonparsing::wording(<inequality-conjugations>, 2),
		FALSE, IS_TENSE, ACTIVE_MOOD, Verbs::new_operator_verb(le), FALSE);
	VerbUsages::register_single_usage(Preform::Nonparsing::wording(<inequality-conjugations>, 3),
		FALSE, IS_TENSE, ACTIVE_MOOD, Verbs::new_operator_verb(ge), FALSE);
}

verb_meaning NewVerbs::ineq_vm(binary_predicate *bp) {
	return VerbMeanings::new(bp, NULL);
}

@h Parsing new verb declarations.
In addition to the built-in stock, new verbs can be declared from the
source text. This is where such text is parsed and acted upon.

@d PROP_VERBM 1
@d REL_VERBM 2
@d VM_VERBM 3
@d BUILTIN_VERBM 4
@d NONE_VERBM 5

@ This is the grammar for parsing new verb declarations:

>> The verb to suspect (he suspects, they suspect, he suspected, it is suspected, he is suspecting) implies the suspecting relation.

>> The verb to be suspicious of implies the suspecting relation.

The "Verb Phrases" section left this sentence with the text after
"The verb to..." as the subject, and the text after "implies the"
as the object.

=
<verb-implies-sentence-subject> ::=
	in <natural-language> <infinitive-declaration> |	==> R[2]; <<natural_language:nl>> = (natural_language *) (RP[1]);
	<infinitive-declaration>							==> R[1]; <<natural_language:nl>> = English_language;

<infinitive-declaration> ::=
	to <infinitive-usage> ( ... ) |		==> R[1]; <<giving-parts>> = TRUE
	to <infinitive-usage> |				==> R[1]; <<giving-parts>> = FALSE
	<infinitive-usage> ( ... ) |		==> R[1]; <<giving-parts>> = TRUE
	<infinitive-usage>					==> R[1]; <<giving-parts>> = FALSE

<infinitive-usage> ::=
	{be able to ...} |					==> TRUE
	{be able to} |						==> TRUE
	...									==> FALSE

@ The text in brackets, if given, is a comma-separated list of conjugations
of the verb. Each one is matched against this:

=
<conjugation> ::=
	<nominative-pronoun> is/are ... |	==> R[1]; <<is-participle>> = TRUE
	<nominative-pronoun> ...			==> R[1]; <<is-participle>> = FALSE

@ This syntax was a design mistake. It generalises badly to other languages,
and doesn't even work perfectly for English. The problem is that the source
text is allowed to give only a selection of the parts of the verb, and
Inform has to guess which parts. So how does it distinguish "X is suspected"
from "X is suspecting"? It needs to know which is the present participle,
and it does this by looking for an -ing ending on either the first or
last word. The following nonterminal matches for that.

=
<participle-like> ::=
	<probable-participle> *** |
	*** <probable-participle>

@ And now for the object noun phrase in the sentence.

The use of |... property| perhaps looks odd. What happens if the user typed

>> The verb to be mystified by implies the arfle barfle gloop property.

when there is no property of that name? The answer is that we can't check this
at the time we're parsing this sentence, because verb definitions are read long
before properties come into existence. The check will be made later on, and for
now absolutely any non-empty word range is accepted as the property name.

=
<verb-implies-sentence-object> ::=
	reversed <relation-name> relation |		==> REL_VERBM; *XP = BinaryPredicates::get_reversal(RP[1])
	<relation-name> relation |				==> REL_VERBM; *XP = RP[1]
	to <instance-of-infinitive-form> |		==> @<Use verb infinitive as shorthand@>
	... property |							==> PROP_VERBM
	built-in ... meaning |					==> BUILTIN_VERBM
	... relation |							==> @<Issue PM_VerbRelationUnknown problem@>
	{relation} |							==> @<Issue PM_VerbRelationVague problem@>
	...										==> @<Issue PM_VerbUnknownMeaning problem@>

@<Issue PM_VerbRelationUnknown problem@> =
	*X = NONE_VERBM;
	Problems::Issue::sentence_problem(_p_(PM_VerbRelationUnknown),
		"new verbs can only be defined in terms of existing relations",
		"all of which have names ending 'relation': thus '...implies the "
		"possession relation' is an example of a valid definition, this "
		"being one of the relations built into Inform.");

@<Issue PM_VerbRelationVague problem@> =
	*X = NONE_VERBM;
	Problems::Issue::sentence_problem(_p_(PM_VerbRelationVague),
		"that's too vague",
		"calling a relation simply 'relation'.");


@<Issue PM_VerbUnknownMeaning problem@> =
	*X = NONE_VERBM;
	Problems::Issue::sentence_problem(_p_(PM_VerbUnknownMeaning),
		"I don't see what the meaning of this verb ought to be",
		"because it doesn't take any of the three forms I know: a relation "
		"name ('...means the wearing relation'), a property name ('...means "
		"the matching key property'), or another verb ('...means to wear.').");

@<Use verb infinitive as shorthand@> =
	*X = VM_VERBM;
	verb_form *vf = RP[1];
	verb_meaning *vm = Verbs::regular_meaning_from_form(vf);
	if (vm) {
		*XP = vm;
	} else {
		*X = NONE_VERBM;
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"that's another verb which has no meaning at present",
			"so this doesn't help me.");
	}

@ This handles the special meaning "X is a verb...".

=
<new-verb-sentence-object> ::=
	<indefinite-article> <new-verb-sentence-object-unarticled> |	==> R[2]; *XP = RP[2]
	<new-verb-sentence-object-unarticled>							==> R[1]; *XP = RP[1]

<new-verb-sentence-object-unarticled> ::=
	verb |															==> TRUE; *XP = NULL;
	verb implying/meaning <nounphrase-definite>						==> TRUE; *XP = RP[1]

@ =
int NewVerbs::new_verb_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "To grow is a verb." */
		case ACCEPT_SMFT:
			if (<new-verb-sentence-object>(OW)) {
				if (<<r>> == FALSE) return FALSE;
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				NewVerbs::parse_new(V, FALSE);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ And this handles the special meaning "The verb X means...".

=
<verb-means-sentence-subject> ::=
	<definite-article> <verb-means-sentence-subject-unarticled> |	==> R[2]; *XP = RP[2]
	<verb-means-sentence-subject-unarticled>							==> R[1]; *XP = RP[1]

<verb-means-sentence-subject-unarticled> ::=
	verb to |														==> FALSE; return FAIL_NONTERMINAL;
	verb <nounphrase> in the imperative |							==> TRUE; *XP = RP[1]
	verb <nounphrase>												==> FALSE; *XP = RP[1]

@ =
int NewVerbs::verb_means_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The verb to grow means the growing relation." */
		case ACCEPT_SMFT:
			if (<verb-means-sentence-subject>(SW)) {
				int imperative_flag = <<r>>;
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				V->next = <<rp>>;
				<nounphrase-articled>(OW);
				V->next->next = <<rp>>;
				NewVerbs::parse_new(V, imperative_flag);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ =
int new_verb_sequence_count = 0;
void NewVerbs::parse_new(parse_node *PN, int imperative) {
	wording PW = EMPTY_WORDING; /* wording of the parts of speech */
	verb_meaning vm = VerbMeanings::meaninglessness(); int meaning_given = FALSE;
	int priority = -1;
	set_where_created = current_sentence;

	if (PN->next->next)
		@<Find the underlying relation of the new verb or preposition@>;

	if (<verb-implies-sentence-subject>(ParseTree::get_text(PN->next))) {
		natural_language *nl = <<natural_language:nl>>;
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
			Problems::Issue::sentence_problem(_p_(PM_PrepositionLong),
				"prepositions can be very long indeed in today's Inform",
				"but not as long as this.");
			return;
		}
		verb_identity *vi = NULL;
		preposition_identity *prep = NULL;
		preposition_identity *second_prep = NULL;
		if (Wordings::nonempty(V)) @<Find or create a new verb@>;
		if (Wordings::nonempty(P))
			prep = Prepositions::make(WordAssemblages::from_wording(P),
				unexpected_upper_casing_used);
		if (Wordings::nonempty(SP))
			second_prep = Prepositions::make(WordAssemblages::from_wording(SP),
				unexpected_upper_casing_used);

		if (meaning_given) {
			verb_meaning *current = Verbs::regular_meaning(vi, prep, second_prep);
			if (VerbMeanings::is_meaningless(current) == FALSE) {
				LOG("Currently $w means $y\n", vi, current);
				parse_node *where = VerbMeanings::get_where_assigned(current);
				@<Issue the actual problem message@>;
			}
		}

		int structures = 0;
		if (imperative) {
			if (divided) structures = VOO_FS_BIT;
			structures = VO_FS_BIT;
		} else {
			if (divided) structures = SVOO_FS_BIT;
			else structures = SVO_FS_BIT;
		}

		Verbs::add_form(vi, prep, second_prep, vm, structures);
	}
}

@h I: Semantics.

@<Find the underlying relation of the new verb or preposition@> =
	<verb-implies-sentence-object>(ParseTree::get_text(PN->next->next));
	switch (<<r>>) {
		case PROP_VERBM: {
			wording RW = GET_RW(<verb-implies-sentence-object>, 1);
			vm = VerbMeanings::new(Properties::SettingRelations::make_set_property_BP(RW), NULL); break;
		}
		case REL_VERBM:
			vm = VerbMeanings::new(<<rp>>, NULL);
			break;
		case BUILTIN_VERBM: {
			wording MW = GET_RW(<verb-implies-sentence-object>, 1);
			vm = NewVerbs::sm_by_name(Lexer::word_text(Wordings::first_wn(MW)), &priority);
			if ((Wordings::length(MW) != 1) || (VerbMeanings::is_meaningless(&vm))) {
				#ifndef IF_MODULE
				source_file *pos = Lexer::file_of_origin(Wordings::first_wn(MW));
				extension_file *loc = SourceFiles::get_extension_corresponding(pos);
				if (loc == standard_rules_extension) return;
				#endif
				Problems::Issue::sentence_problem(_p_(PM_NoSuchBuiltInMeaning),
					"that's not one of the built-in meanings I know",
					"and should be one of the ones used in the Preamble to the "
					"Standard Rules.");
				vm = VerbMeanings::new(R_equality, NULL);
			}
			break;
		}
		case VM_VERBM: vm = *((verb_meaning *) (<<rp>>)); break;
		default: return;
	}
	meaning_given = TRUE;

@h IIa: Syntax of a new verb usage.

@ The following can define both a verb and a preposition, coupling them
together, or can define either one alone.

We shouldn't really use the same sentence form to define prepositions as they
do to define verbs: but it's easy to remember, and convenient, and no
alternative seems better, so we go along with it, and allow

>> The verb to be beneath implies ...

even though this is not the definition of a verb at all, and it is only
"beneath" which is being defined.

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

@ =
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

	verb_conjugation *nvc = Conjugation::conjugate_with_overrides(infinitive, overrides, no_overrides, nl);

	vc = Conjugation::find_prior(nvc);
	if (vc == NULL) vc = nvc;

	if (Wordings::nonempty(PW)) {
		if ((vc) && (vc->vc_conjugates == copular_verb))
			@<Reject with a problem message if preposition is conjugated@>;
	}

@ We read the parts of speech as a comma-separated list of individual parts
(but we don't allow "and" or "or" to divide this list: only commas).

At the end, if no present plural is supplied, we may as well use the
infinitive for that -- the two are the same in most regular English verbs
("to sleep", "they sleep") even if not irregular ones ("to be",
"they are").

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
	if (WordAssemblages::nonempty(present_plural) == FALSE) present_plural = infinitive;

@ Note that the suffix "-ing" is used to distinguish the present participle
("he is grabbing") from the past ("he is grabbed").

@<Parse the part of speech in this clause@> =
	if ((<conjugation>(CW)) == FALSE)
		@<Give up on verb definition as malformed@>;
	CW = GET_RW(<conjugation>, 1);
	int number = <<r>>;
	int is_a_participle = <<is-participle>>;

	if (Wordings::nonempty(P)) {
		int L = Wordings::length(P), C = Wordings::length(CW);
		LOG("Looking at %W (%d) and %W (%d)\n", P, L, CW, C);
		if (C >= L) {
			wording T = Wordings::from(CW, Wordings::first_wn(CW) + C-L);
			LOG("Tail %W\n", T);
			if (Wordings::match(T, P)) {
				if (C > L) CW = Wordings::truncate(CW, C-L);
				else CW = EMPTY_WORDING;
			} else improper_parts = TRUE;
		} else improper_parts = TRUE;
		LOG("Improper: %d\n", improper_parts);
	}

	if (Wordings::length(CW) > 0) {
		if (Wordings::length(CW) > MAX_WORDS_IN_VERB) @<Give up on verb definition as malformed@>;

		if (is_a_participle) {
			participle_count++;
			if ((<participle-like>(CW)) ||
				(WordAssemblages::nonempty(past_participle)))
				participle = WordAssemblages::from_wording(CW);
			else
				past_participle = WordAssemblages::from_wording(CW);
		} else {
			if (number == 2) {
				if (WordAssemblages::nonempty(present_plural)) {
					Problems::Issue::sentence_problem(_p_(PM_PresentPluralTwice),
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
	Problems::Issue::sentence_problem(_p_(PM_VerbMalformed),
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
		Problems::Issue::sentence_problem(_p_(PM_PrepositionConjugated),
			"the principal parts of 'to be' are known already",
			"so should not be spelled out again as part of the instructions "
			"for this new preposition.");
		return;
	}

@<Issue the actual problem message@> =
	if (where)
		Problems::Issue::two_sentences_problem(_p_(PM_DuplicateVerbs1),
			where,
			"this gives us two definitions of what appears to be the same verb",
			"or at least has the same infinitive form.");
	else
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"this verb definition appears to clash with a built-in verb",
			"a table of which can be seen on the Phrasebook index.");

@ The "priority" of a verb in an assertion affects which reading is chosen
in the case of ambiguity, with lower numbers preferred. We rank our verbs
as "to have" (priority 1), "to be" (2), general English verbs (3) and then
foreign verbs (4).

@<Register the new verb's usage@> =
	int p = 4;
	binary_predicate *bp = VerbMeanings::get_relational_meaning(&vm);
	if (bp == a_has_b_predicate) p = 1;
	if (bp == R_equality) p = 2;
	if ((nl) && (nl != English_language)) p = 5;
	++new_verb_sequence_count;
	vi = Verbs::new_verb(vc, FALSE);
	vc->vc_conjugates = vi;
	if (priority >= 1) p = priority;
	VerbUsages::register_all_usages_of_verb(vi, unexpected_upper_casing_used, p);

@h Bootstrapping.

=
<bootstrap-verb> ::=
	be |
	mean |
	imply

@ =
void NewVerbs::declare_sm(int (*func)(int, parse_node *, wording *), text_stream *name, int p) {
	special_meaning_holder *smh = CREATE(special_meaning_holder);
	smh->sm_func = func;
	smh->sm_name = Str::duplicate(name);
	smh->verb_priority = p;
}

verb_meaning NewVerbs::sm_by_name(wchar_t *name, int *p) {
	special_meaning_holder *smh;
	LOOP_OVER(smh, special_meaning_holder)
		if (Str::eq_wide_string(smh->sm_name, name)) {
			if (p) *p = smh->verb_priority;
			return VerbMeanings::special(smh->sm_func);
		}
	return VerbMeanings::meaninglessness();
}

void NewVerbs::bootstrap(void) {
	NewVerbs::declare_sm(NewVerbs::verb_means_SMF, 							I"verb-means", 3);

	NewVerbs::declare_sm(NewVerbs::new_verb_SMF, 							I"new-verb", 2);
	NewVerbs::declare_sm(Plurals::plural_SMF, 								I"new-plural", 2);
	NewVerbs::declare_sm(Activities::new_activity_SMF, 						I"new-activity", 2);
	#ifdef IF_MODULE
	NewVerbs::declare_sm(PL::Actions::new_action_SMF, 						I"new-action", 2);
	#endif
	NewVerbs::declare_sm(NewVerbs::new_adjective_SMF,						I"new-adjective", 2);
	NewVerbs::declare_sm(Assertions::Property::either_SMF,					I"new-either-or", 2);
	NewVerbs::declare_sm(Tables::Defining::defined_by_SMF,					I"defined-by-table", 2);
	NewVerbs::declare_sm(Rules::Placement::listed_in_SMF,					I"rule-listed-in", 2);
	#ifdef MULTIMEDIA_MODULE
	NewVerbs::declare_sm(PL::Figures::new_figure_SMF,						I"new-figure", 2);
	NewVerbs::declare_sm(PL::Sounds::new_sound_SMF,							I"new-sound", 2);
	NewVerbs::declare_sm(PL::Files::new_file_SMF,							I"new-file", 2);
	#endif
	#ifdef IF_MODULE
	NewVerbs::declare_sm(PL::Bibliographic::episode_SMF,					I"episode", 2);
	#endif
	NewVerbs::declare_sm(Relations::new_relation_SMF,						I"new-relation", 1);
	NewVerbs::declare_sm(Assertions::Property::optional_either_SMF,			I"can-be", 2);
	NewVerbs::declare_sm(LiteralPatterns::specifies_SMF, 					I"specifies-notation", 4);
	NewVerbs::declare_sm(Rules::Placement::substitutes_for_SMF,				I"rule-substitutes-for", 1);
	#ifdef IF_MODULE
	NewVerbs::declare_sm(PL::Scenes::begins_when_SMF,						I"scene-begins-when", 1);
	NewVerbs::declare_sm(PL::Scenes::ends_when_SMF,							I"scene-ends-when", 1);
	#endif
	NewVerbs::declare_sm(Rules::Placement::does_nothing_SMF,				I"rule-does-nothing", 1);
	NewVerbs::declare_sm(Rules::Placement::does_nothing_if_SMF,				I"rule-does-nothing-if", 1);
	NewVerbs::declare_sm(Rules::Placement::does_nothing_unless_SMF,			I"rule-does-nothing-unless", 1);
	NewVerbs::declare_sm(Sentences::VPs::translates_into_unicode_as_SMF,	I"translates-into-unicode", 1);
	NewVerbs::declare_sm(Sentences::VPs::translates_into_I6_as_SMF,			I"translates-into-i6", 1);
	NewVerbs::declare_sm(Sentences::VPs::translates_into_language_as_SMF,	I"translates-into-language", 1);
	NewVerbs::declare_sm(UseOptions::use_translates_as_SMF,					I"use-translates", 4);
	#ifdef IF_MODULE
	NewVerbs::declare_sm(PL::Parsing::TestScripts::test_with_SMF,			I"test-with", 1);
	NewVerbs::declare_sm(PL::Parsing::understand_as_SMF,					I"understand-as", 1);
	#endif
	NewVerbs::declare_sm(UseOptions::use_SMF,								I"use", 4);
	#ifdef IF_MODULE
	NewVerbs::declare_sm(PL::Bibliographic::Release::release_along_with_SMF,I"release-along-with", 4);
	NewVerbs::declare_sm(PL::EPSMap::index_map_with_SMF,					I"index-map-with", 4);
	#endif
	NewVerbs::declare_sm(Sentences::VPs::include_in_SMF,					I"include-in", 4);
	NewVerbs::declare_sm(Sentences::VPs::omit_from_SMF,						I"omit-from", 4);
	NewVerbs::declare_sm(Index::DocReferences::document_at_SMF,				I"document-at", 4);

	word_assemblage infinitive = Preform::Nonparsing::wording(<bootstrap-verb>, 0);
	verb_conjugation *vc = Conjugation::conjugate(infinitive, English_language);
	verb_identity *vi = Verbs::new_verb(vc, TRUE);
	vc->vc_conjugates = vi;
	VerbUsages::register_all_usages_of_verb(vi, FALSE, 2);

	infinitive = Preform::Nonparsing::wording(<bootstrap-verb>, 1);
	vc = Conjugation::conjugate(infinitive, English_language);
	vi = Verbs::new_verb(vc, FALSE);
	vc->vc_conjugates = vi;
	VerbUsages::register_all_usages_of_verb(vi, FALSE, 3);

	Verbs::add_form(vi, NULL, NULL, NewVerbs::sm_by_name(L"verb-means", NULL), SVO_FS_BIT);
}

@h Runtime conjugation.

=
void NewVerbs::ConjugateVerb_invoke_emit(verb_conjugation *vc,
	verb_conjugation *modal, int negated) {
	inter_name *cv_pos = Hierarchy::find(CV_POS_HL);
	inter_name *cv_neg = Hierarchy::find(CV_NEG_HL);
	if (modal) {
		if (negated) {
			Emit::inv_call_iname(Conjugation::conj_iname(modal));
			Emit::down();
				Emit::val_iname(K_value, cv_neg);
				Emit::inv_call_iname(Hierarchy::find(PNTOVP_HL));
				Emit::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				Emit::val_iname(K_value, Conjugation::conj_iname(vc));
			Emit::up();
		} else {
			Emit::inv_call_iname(Conjugation::conj_iname(modal));
			Emit::down();
				Emit::val_iname(K_value, cv_pos);
				Emit::inv_call_iname(Hierarchy::find(PNTOVP_HL));
				Emit::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				Emit::val_iname(K_value, Conjugation::conj_iname(vc));
			Emit::up();
		}
	} else {
		if (negated) {
			Emit::inv_call_iname(Conjugation::conj_iname(vc));
			Emit::down();
				Emit::val_iname(K_value, cv_neg);
				Emit::inv_call_iname(Hierarchy::find(PNTOVP_HL));
				Emit::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
			Emit::up();
		} else {
			Emit::inv_call_iname(Conjugation::conj_iname(vc));
			Emit::down();
				Emit::val_iname(K_value, cv_pos);
				Emit::inv_call_iname(Hierarchy::find(PNTOVP_HL));
				Emit::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
			Emit::up();
		}
	}
	Emit::inv_primitive(Produce::opcode(STORE_BIP));
	Emit::down();
		Emit::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		Emit::val(K_number, LITERAL_IVAL, 1);
	Emit::up();
}

@ Each VC is represented by a routine at run-time:

=
int NewVerbs::verb_form_is_instance(verb_form *vf) {
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	if ((vc) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb) &&
		((vf->preposition == NULL) || (vf->underlying_verb != copular_verb)))
		return TRUE;
	return FALSE;
}

void NewVerbs::ConjugateVerbDefinitions(void) {
	inter_name *CV_POS_iname = Hierarchy::find(CV_POS_HL);
	inter_name *CV_NEG_iname = Hierarchy::find(CV_NEG_HL);
	inter_name *CV_MODAL_INAME_iname = Hierarchy::find(CV_MODAL_HL);
	inter_name *CV_MEANING_iname = Hierarchy::find(CV_MEANING_HL);

	Emit::named_numeric_constant_signed(CV_POS_iname, -1);
	Emit::named_numeric_constant_signed(CV_NEG_iname, -2);
	Emit::named_numeric_constant_signed(CV_MODAL_INAME_iname, -3);
	Emit::named_numeric_constant_signed(CV_MEANING_iname, -4);
}

void NewVerbs::ConjugateVerb(void) {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		@<Compile ConjugateVerb routine@>;
	verb_form *vf;
	LOOP_OVER(vf, verb_form)
		if (NewVerbs::verb_form_is_instance(vf))
			@<Compile ConjugateVerbForm routine@>;
	inter_name *iname = Hierarchy::find(TABLEOFVERBS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	LOOP_OVER(vf, verb_form)
		if (NewVerbs::verb_form_is_instance(vf))
			Emit::array_iname_entry(Verbs::form_iname(vf));
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@<Compile ConjugateVerb routine@> =
	packaging_state save = Routines::begin(Conjugation::conj_iname(vc));
	inter_symbol *fn_s = LocalVariables::add_named_call_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::add_named_call_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::add_named_call_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::add_named_call_as_symbol(I"modal_to");

	Emit::inv_primitive(Produce::opcode(SWITCH_BIP));
	Emit::down();
		Emit::val_symbol(K_value, fn_s);
		Emit::code();
		Emit::down();
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 1);
				Emit::code();
				Emit::down();
					NewVerbs::conj_from_wa(&(vc->infinitive), vc, modal_to_s, 0);
				Emit::up();
			Emit::up();
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 2);
				Emit::code();
				Emit::down();
					NewVerbs::conj_from_wa(&(vc->past_participle), vc, modal_to_s, 0);
				Emit::up();
			Emit::up();
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 3);
				Emit::code();
				Emit::down();
					NewVerbs::conj_from_wa(&(vc->present_participle), vc, modal_to_s, 0);
				Emit::up();
			Emit::up();

	int modal_verb = FALSE;
	@<Check for modality@>;

	verb_identity *vi = vc->vc_conjugates;
	verb_meaning *vm = (vi)?Verbs::regular_meaning(vi, NULL, NULL):NULL;
	binary_predicate *meaning = VerbMeanings::get_relational_meaning(vm);
	inter_name *rel_iname = default_rr;
	if (meaning) {
		BinaryPredicates::mark_as_needed(meaning);
		rel_iname = meaning->bp_iname;
	}

			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(CV_MODAL_HL));
				Emit::code();
				Emit::down();
					if (modal_verb) Emit::rtrue();
					else Emit::rfalse();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(CV_MEANING_HL));
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Produce::opcode(RETURN_BIP));
					Emit::down();
						Emit::val_iname(K_value, rel_iname);
					Emit::up();
				Emit::up();
			Emit::up();

	for (int sense = 0; sense < 2; sense++) {
		inter_name *sense_iname = Hierarchy::find(CV_POS_HL);
		if (sense == 1) sense_iname = Hierarchy::find(CV_NEG_HL);
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val_iname(K_value, sense_iname);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Produce::opcode(SWITCH_BIP));
					Emit::down();
						Emit::val_symbol(K_value, t_s);
						Emit::code();
						Emit::down();
							@<Compile conjugation in this sense@>;
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
	}
		Emit::up();
	Emit::up();

	Routines::end(save);

@<Compile ConjugateVerbForm routine@> =
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	packaging_state save = Routines::begin(Verbs::form_iname(vf));
	inter_symbol *fn_s = LocalVariables::add_named_call_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::add_named_call_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::add_named_call_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::add_named_call_as_symbol(I"modal_to");

	TEMPORARY_TEXT(C);
	WRITE_TO(C, "%A", &(vf->infinitive_reference_text));
	Emit::code_comment(C);
	DISCARD_TEXT(C);

	Emit::inv_primitive(Produce::opcode(STORE_BIP));
	Emit::down();
		Emit::ref_symbol(K_value, t_s);
		Emit::inv_call_iname(Conjugation::conj_iname(vc));
		Emit::down();
			Emit::val_symbol(K_value, fn_s);
			Emit::val_symbol(K_value, vp_s);
			Emit::val_symbol(K_value, t_s);
			Emit::val_symbol(K_value, modal_to_s);
		Emit::up();
	Emit::up();

	Emit::inv_primitive(Produce::opcode(IF_BIP));
	Emit::down();
		Emit::inv_primitive(Produce::opcode(EQ_BIP));
		Emit::down();
			Emit::val_symbol(K_value, fn_s);
			Emit::val_iname(K_value, Hierarchy::find(CV_MODAL_HL));
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(Produce::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_symbol(K_value, t_s);
			Emit::up();
		Emit::up();
	Emit::up();

	verb_meaning *vm = &(vf->list_of_senses->vm);
	inter_name *rel_iname = default_rr;
	binary_predicate *meaning = VerbMeanings::get_relational_meaning(vm);
	if (meaning) {
		BinaryPredicates::mark_as_needed(meaning);
		rel_iname = meaning->bp_iname;
	}


	Emit::inv_primitive(Produce::opcode(IF_BIP));
	Emit::down();
		Emit::inv_primitive(Produce::opcode(EQ_BIP));
		Emit::down();
			Emit::val_symbol(K_value, fn_s);
			Emit::val_iname(K_value, Hierarchy::find(CV_MEANING_HL));
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(Produce::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_iname(K_value, rel_iname);
			Emit::up();
		Emit::up();
	Emit::up();

	if (vf->preposition) {
		TEMPORARY_TEXT(T);
		WRITE_TO(T, " %A", &(vf->preposition->prep_text));
		Emit::inv_primitive(Produce::opcode(PRINT_BIP));
		Emit::down();
			Emit::val_text(T);
		Emit::up();
		DISCARD_TEXT(T);
	}

	Routines::end(save);

@<Check for modality@> =
	for (int sense = 0; sense < 2; sense++)
		for (int tense=0; tense<NO_KNOWN_TENSES; tense++)
			for (int part=1; part<=6; part++)
				if (vc->tabulations[ACTIVE_MOOD].modal_auxiliary_usage[tense][sense][part-1] != 0)
					modal_verb = TRUE;

@<Compile conjugation in this sense@> =
	for (int tense=0; tense<NO_KNOWN_TENSES; tense++) {
		int some_exist = FALSE, some_dont_exist = FALSE,
			some_differ = FALSE, some_except_3PS_differ = FALSE, some_are_modal = FALSE;
		word_assemblage *common = NULL, *common_except_3PS = NULL;
		for (int part=1; part<=6; part++) {
			word_assemblage *wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][part-1]);
			if (WordAssemblages::nonempty(*wa)) {
				if (some_exist) {
					if (WordAssemblages::compare(wa, common) == FALSE)
						some_differ = TRUE;
					if (part != 3) {
						if (common_except_3PS == NULL) common_except_3PS = wa;
						else if (WordAssemblages::compare(wa, common_except_3PS) == FALSE)
							some_except_3PS_differ = TRUE;
					}
				} else {
					some_exist = TRUE;
					common = wa;
					if (part != 3) common_except_3PS = wa;
				}
				if (vc->tabulations[ACTIVE_MOOD].modal_auxiliary_usage[tense][sense][part-1] != 0)
					some_are_modal = TRUE;
			}
			else some_dont_exist = TRUE;
		}
		if (some_exist) {
			Emit::inv_primitive(Produce::opcode(CASE_BIP));
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, (inter_t) (tense+1));
				Emit::code();
				Emit::down();
					if ((some_differ) || (some_are_modal)) {
						if ((some_except_3PS_differ) || (some_dont_exist) || (some_are_modal))
							@<Compile a full switch of all six parts@>
						else
							@<Compile a choice between 3PS and the rest@>;
					} else {
						@<Compile for the case where all six parts are the same@>;
					}
				Emit::up();
			Emit::up();
		}
	}

@<Compile a full switch of all six parts@> =
	Emit::inv_primitive(Produce::opcode(SWITCH_BIP));
	Emit::down();
		Emit::val_symbol(K_value, vp_s);
		Emit::code();
		Emit::down();
			for (int part=1; part<=6; part++) {
				word_assemblage *wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][part-1]);
				if (WordAssemblages::nonempty(*wa)) {
					Emit::inv_primitive(Produce::opcode(CASE_BIP));
					Emit::down();
						Emit::val(K_number, LITERAL_IVAL, (inter_t) part);
						Emit::code();
						Emit::down();
							int mau = vc->tabulations[ACTIVE_MOOD].modal_auxiliary_usage[tense][sense][part-1];
							NewVerbs::conj_from_wa(wa, vc, modal_to_s, mau);
						Emit::up();
					Emit::up();
				}
			}
		Emit::up();
	Emit::up();

@<Compile a choice between 3PS and the rest@> =
	Emit::inv_primitive(Produce::opcode(IFELSE_BIP));
	Emit::down();
		Emit::inv_primitive(Produce::opcode(EQ_BIP));
		Emit::down();
			Emit::val_symbol(K_value, vp_s);
			Emit::val(K_number, LITERAL_IVAL, 3);
		Emit::up();
		Emit::code();
		Emit::down();
			word_assemblage *wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][2]);
			NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Emit::up();
		Emit::code();
		Emit::down();
			wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][0]);
			NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Emit::up();
	Emit::up();

@<Compile for the case where all six parts are the same@> =
	word_assemblage *wa = &(vc->tabulations[ACTIVE_MOOD].vc_text[tense][sense][0]);
	NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);

@ =
void NewVerbs::conj_from_wa(word_assemblage *wa, verb_conjugation *vc, inter_symbol *modal_to_s, int mau) {
	Emit::inv_primitive(Produce::opcode(PRINT_BIP));
	Emit::down();
		TEMPORARY_TEXT(OUT);
		if ((NewVerbs::takes_contraction_form(wa) == FALSE) && (NewVerbs::takes_contraction_form(&(vc->infinitive))))
			WRITE(" ");
		int i, n;
		vocabulary_entry **words;
		WordAssemblages::as_array(wa, &words, &n);
		for (i=0; i<n; i++) {
			if (i>0) WRITE(" ");
			wchar_t *q = Vocabulary::get_exemplar(words[i], FALSE);
			if ((q[0]) && (q[Wide::len(q)-1] == '*')) {
internal_error("star alert!");
				TEMPORARY_TEXT(unstarred);
				WRITE_TO(unstarred, "%V", words[i]);
				Str::delete_last_character(unstarred);
				feed_t id = Feeds::begin();
				Feeds::feed_text(L" ");
				Feeds::feed_stream(unstarred);
				Feeds::feed_text(L" ");
				DISCARD_TEXT(unstarred);
				wording W = Feeds::end(id);
				adjectival_phrase *aph = Adjectives::declare(W, vc->defined_in);
				WRITE("\"; %n(prior_named_noun, (prior_named_list >= 2)); print \"",
					aph->aph_iname);
			} else {
				WRITE("%V", words[i]);
			}
		}
		Emit::val_text(OUT);
		DISCARD_TEXT(OUT);
	Emit::up();
	if (mau != 0) {
		Emit::inv_primitive(Produce::opcode(IF_BIP));
		Emit::down();
			Emit::val_symbol(K_value, modal_to_s);
			Emit::code();
			Emit::down();
				Emit::inv_primitive(Produce::opcode(PRINT_BIP));
				Emit::down();
					Emit::val_text(I" ");
				Emit::up();
				Emit::inv_primitive(Produce::opcode(INDIRECT1V_BIP));
				Emit::down();
					Emit::val_symbol(K_value, modal_to_s);
					Emit::val(K_number, LITERAL_IVAL, (inter_t) mau);
				Emit::up();
			Emit::up();
		Emit::up();
	}
}

int NewVerbs::takes_contraction_form(word_assemblage *wa) {
	vocabulary_entry *ve = WordAssemblages::first_word(wa);
	if (ve == NULL) return FALSE;
	wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if (p[0] == '\'') return TRUE;
	return FALSE;
}

@ This handles the special meaning "X is an adjective...".

=
<new-adjective-sentence-object> ::=
	<indefinite-article> <new-adjective-sentence-object-unarticled> |	==> R[2]; *XP = RP[2]
	<new-adjective-sentence-object-unarticled>							==> R[1]; *XP = RP[1]

<new-adjective-sentence-object-unarticled> ::=
	adjective |															==> TRUE; *XP = NULL
	adjective implying/meaning <nounphrase-definite>					==> TRUE; *XP = RP[1]

@ =
int NewVerbs::new_adjective_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "In French petit is an adjective meaning..." */
		case ACCEPT_SMFT:
			if (<new-adjective-sentence-object>(OW)) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				if (O == NULL) { <nounphrase>(OW); O = <<rp>>; }
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			NewVerbs::declare_meaningless_adjective(V);
			break;
	}
	return FALSE;
}



@ =
<adjective-definition-subject> ::=
	in <natural-language> ... |		==> TRUE; *XP = RP[1];
	...								==> TRUE; *XP = language_of_play;

@ =
void NewVerbs::declare_meaningless_adjective(parse_node *p) {
	wording W = ParseTree::get_text(p->next);
	<adjective-definition-subject>(W);
	PREFORM_LANGUAGE_TYPE *nl = <<rp>>;
	W = GET_RW(<adjective-definition-subject>, 1);
	if (!(<adaptive-adjective>(W)))
		Adjectives::declare(W, nl);
}

@h Debug log.
The following dumps the entire stock of registered verb and preposition
usages to the debugging log.

=
void NewVerbs::log(verb_usage *vu) {
	if (vu == NULL) { LOG("(null verb usage)"); return; }
	LOG("VU: $f ", &(vu->vu_text));
	if (vu->negated_form_of_verb) LOG("(negated) ");
	Linguistics::log_tense_number(DL, vu->tensed);
}

void NewVerbs::log_all(void) {
	verb_usage *vu;
	preposition_identity *prep;
	LOG("The current S-grammar has the following verb and preposition usages:\n");
	LOOP_OVER(vu, verb_usage) {
		NewVerbs::log(vu);
		LOG("\n");
	}
	LOOP_OVER(prep, preposition_identity) {
		LOG("$p\n", prep);
	}
}

@h Index tabulation.
The following produces the table of verbs in the Phrasebook Index page.

=
void NewVerbs::tabulate(OUTPUT_STREAM, lexicon_entry *lex, int tense, char *tensename) {
	verb_usage *vu; int f = TRUE;
	LOOP_OVER(vu, verb_usage)
		if ((vu->vu_lex_entry == lex) && (VerbUsages::is_used_negatively(vu) == FALSE)
			 && (VerbUsages::get_tense_used(vu) == tense)) {
			vocabulary_entry *lastword = WordAssemblages::last_word(&(vu->vu_text));
			if (f) {
				HTMLFiles::open_para(OUT, 2, "tight");
				WRITE("<i>%s:</i>&nbsp;", tensename);
			} else WRITE("; ");
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), L"by") == 0) WRITE("B ");
			else WRITE("A ");
			WordAssemblages::index(OUT, &(vu->vu_text));
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), L"by") == 0) WRITE("A");
			else WRITE("B");
			f = FALSE;
		}
	if (f == FALSE) HTML_CLOSE("p");
}

void NewVerbs::tabulate_meaning(OUTPUT_STREAM, lexicon_entry *lex) {
	verb_usage *vu;
	LOOP_OVER(vu, verb_usage)
		if (vu->vu_lex_entry == lex) {
			if (vu->where_vu_created)
				Index::link(OUT, Wordings::first_wn(ParseTree::get_text(vu->where_vu_created)));
			verb_meaning *vm = Verbs::regular_meaning(vu->verb_used, NULL, NULL);
			if (vm) {
				binary_predicate *bp = VerbMeanings::get_relational_meaning(vm);
				if (bp) Relations::index_for_verbs(OUT, bp);
			}
			return;
		}
	preposition_identity *prep;
	LOOP_OVER(prep, preposition_identity)
		if (prep->prep_lex_entry == lex) {
			if (prep->where_prep_created)
				Index::link(OUT, Wordings::first_wn(ParseTree::get_text(prep->where_prep_created)));
			verb_meaning *vm = Verbs::regular_meaning(copular_verb, prep, NULL);
			if (vm) {
				binary_predicate *bp = VerbMeanings::get_relational_meaning(vm);
				if (bp) Relations::index_for_verbs(OUT, bp);
			}
			return;
		}
}

