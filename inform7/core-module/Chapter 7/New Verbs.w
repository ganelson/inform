[NewVerbs::] New Verbs.

To define verbal forms for relations, in different tenses and numbers.

@h Definitions.

@ A single English verb, such as "to contain", produces numerous |verb_usage|
objects, since we have one for each combination of tense, number and negation
-- "contains", "had not contained", etc. These have upper limits on their
sizes, not so much from the language definition as from limitations on our
implementation of it. But in practice they should never be reached.

@d MAX_WORDS_IN_VERB (MAX_WORDS_IN_ASSEMBLAGE - 4)

@

=
typedef struct verb_compilation_data {
	struct package_request *verb_package;
} verb_compilation_data;

typedef struct verb_form_compilation_data {
	struct inter_name *vf_iname; /* routine to conjugate this */
	struct parse_node *where_vf_created;
} verb_form_compilation_data;

@

@d VERB_COMPILATION_LINGUISTICS_CALLBACK NewVerbs::initialise_verb
@d VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK NewVerbs::initialise_verb_form

=
void NewVerbs::initialise_verb(verb *V) {
	V->verb_compilation.verb_package = NULL;
}

void NewVerbs::initialise_verb_form(verb_form *VF) {
	VF->verb_form_compilation.vf_iname = NULL;
	VF->verb_form_compilation.where_vf_created = current_sentence;
}

package_request *NewVerbs::package(verb *V, parse_node *where) {
	if (V == NULL) internal_error("no verb identity");
	if (V->verb_compilation.verb_package == NULL)
		V->verb_compilation.verb_package =
			Hierarchy::package(CompilationUnits::find(where), VERBS_HAP);
	return V->verb_compilation.verb_package;
}

inter_name *NewVerbs::form_iname(verb_form *vf) {
	if (vf->verb_form_compilation.vf_iname == NULL) {
		package_request *R =
			NewVerbs::package(vf->underlying_verb, vf->verb_form_compilation.where_vf_created);
		package_request *R2 = Hierarchy::package_within(VERB_FORMS_HAP, R);
		vf->verb_form_compilation.vf_iname = Hierarchy::make_iname_in(FORM_FN_HL, R2);
	}
	return vf->verb_form_compilation.vf_iname;
}

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
void NewVerbs::add_operator(wording W, verb_meaning vm) {
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
	LOG("So W is %W\n", W);
	VerbUsages::new(WordAssemblages::from_wording(W), FALSE, gu, NULL);
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

@ The text in brackets, if given, is a comma-separated list of conjugations
of the verb. Each one is matched against this:

=
<conjugation> ::=
	<subject-pronoun> is/are ... |  ==> { 0, RP[1], <<is-participle>> = TRUE }
	<subject-pronoun> ...           ==> { 0, RP[1], <<is-participle>> = FALSE }

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
	verb_meaning *vm = VerbMeanings::first_unspecial_meaning_of_verb_form(vf);
	if (vm) {
		==> { VM_VERBM, vm };
	} else {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that's another verb which has no meaning at present",
			"so this doesn't help me.");
		==> { NONE_VERBM, - };
	}

@ This handles the special meaning "X is a verb...".

=
<new-verb-sentence-object> ::=
	<indefinite-article> <new-verb-sentence-object-unarticled> |     ==> { pass 2 }
	<new-verb-sentence-object-unarticled>							 ==> { pass 1 }

<new-verb-sentence-object-unarticled> ::=
	verb |                                                           ==> { TRUE, NULL }
	verb implying/meaning <definite-article> nounphrase-unparsed> |  ==> { TRUE, RP[2] }
	verb implying/meaning <np-unparsed>                              ==> { TRUE, RP[1] }

@ =
int NewVerbs::new_verb_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "To grow is a verb." */
		case ACCEPT_SMFT:
			if (<new-verb-sentence-object>(OW)) {
				if (<<r>> == FALSE) return FALSE;
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				NewVerbs::parse_new(V, FALSE, FALSE);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ And this handles the special meaning "The verb X means...".

=
<verb-means-sentence-subject> ::=
	<definite-article> <verb-means-sentence-subject-unarticled> |  ==> { pass 2 }
	<verb-means-sentence-subject-unarticled>                       ==> { pass 1 }

<verb-means-sentence-subject-unarticled> ::=
	verb to |                                                      ==> { fail }
	verb <np-unparsed> in the imperative |                         ==> { TRUE, RP[1] }
	verb <np-unparsed> |                                           ==> { FALSE, RP[1] }
	operator <np-unparsed>                                         ==> { NOT_APPLICABLE, RP[1] }

@ =
int NewVerbs::verb_means_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The verb to grow means the growing relation." */
		case ACCEPT_SMFT:
			if (<verb-means-sentence-subject>(SW)) {
				int imperative_flag = FALSE, operator_flag = FALSE;
				if (<<r>> == TRUE) imperative_flag = TRUE;
				if (<<r>> == NOT_APPLICABLE) operator_flag = TRUE;
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				NewVerbs::parse_new(V, imperative_flag, operator_flag);
				return TRUE;
			}
			break;
	}
	return FALSE;
}

@ =
void NewVerbs::parse_new(parse_node *PN, int imperative, int operator) {
	wording PW = EMPTY_WORDING; /* wording of the parts of speech */
	verb_meaning vm = VerbMeanings::meaninglessness(); int meaning_given = FALSE;
	int priority = -1;

	if (PN->next->next)
		@<Find the underlying relation of the new verb or preposition@>;

	if ((operator) && (<verb-means-sentence-subject>(Node::get_text(PN->next)))) {
		NewVerbs::add_operator(Node::get_text(<<rp>>), vm);
		return;
	}

	if (<verb-implies-sentence-subject>(Node::get_text(PN->next))) {
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
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PrepositionLong),
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
			verb_meaning *current = VerbMeanings::first_unspecial_meaning_of_verb_form(Verbs::find_form(vi, prep, second_prep));
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
	<verb-implies-sentence-object>(Node::get_text(PN->next->next));
	switch (<<r>>) {
		case PROP_VERBM: {
			wording RW = GET_RW(<verb-implies-sentence-object>, 1);
			vm = VerbMeanings::regular(Properties::SettingRelations::make_set_property_BP(RW)); break;
		}
		case REL_VERBM:
			vm = VerbMeanings::regular(<<rp>>);
			break;
		case BUILTIN_VERBM: {
			wording MW = GET_RW(<verb-implies-sentence-object>, 1);
			special_meaning_holder *smh = SpecialMeanings::find_from_wording(MW);
			if (smh == NULL) {
				#ifndef IF_MODULE
				source_file *pos = Lexer::file_of_origin(Wordings::first_wn(MW));
				inform_extension *loc = Extensions::corresponding_to(pos);
				if (Extensions::is_standard(loc)) return;
				#endif
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NoSuchBuiltInMeaning),
					"that's not one of the built-in meanings I know",
					"and should be one of the ones used in the Preamble to the "
					"Standard Rules.");
				vm = VerbMeanings::regular(R_equality);
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
	pronoun_usage *pu = (pronoun_usage *) <<rp>>;
	int number = PLURAL_NUMBER;
	if (Stock::usage_might_be_singular(pu->usage)) number = SINGULAR_NUMBER;
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
			if (number == PLURAL_NUMBER) {
				if (WordAssemblages::nonempty(present_plural)) {
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PresentPluralTwice),
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
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PrepositionConjugated),
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
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this verb definition appears to clash with a built-in verb",
			"a table of which can be seen on the Phrasebook index.");

@ The "priority" of a verb in an assertion affects which reading is chosen
in the case of ambiguity, with lower numbers preferred. We rank our verbs
as "to have" (priority 1), "to be" (2), general English verbs (3) and then
foreign verbs (4).

@<Register the new verb's usage@> =
	int p = 4;
	binary_predicate *bp = VerbMeanings::get_regular_meaning(&vm);
	if (bp == a_has_b_predicate) p = 1;
	if (bp == R_equality) p = 2;
	if ((nl) && (nl != DefaultLanguage::get(NULL))) p = 5;
	vi = Verbs::new_verb(vc, FALSE);
	vc->vc_conjugates = vi;
	if (priority >= 1) p = priority;
	VerbUsages::register_all_usages_of_verb(vi, unexpected_upper_casing_used, p, current_sentence);

@h Runtime conjugation.

=
void NewVerbs::ConjugateVerb_invoke_emit(verb_conjugation *vc,
	verb_conjugation *modal, int negated) {
	inter_name *cv_pos = Hierarchy::find(CV_POS_HL);
	inter_name *cv_neg = Hierarchy::find(CV_NEG_HL);
	if (modal) {
		if (negated) {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(modal));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_neg);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
				Produce::val_iname(Emit::tree(), K_value, Conjugation::conj_iname(vc));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(modal));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_pos);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
				Produce::val_iname(Emit::tree(), K_value, Conjugation::conj_iname(vc));
			Produce::up(Emit::tree());
		}
	} else {
		if (negated) {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_neg);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_pos);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
			Produce::up(Emit::tree());
		}
	}
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
	Produce::up(Emit::tree());
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
	
	Hierarchy::make_available(Emit::tree(), CV_POS_iname);
	Hierarchy::make_available(Emit::tree(), CV_NEG_iname);
	Hierarchy::make_available(Emit::tree(), CV_MODAL_INAME_iname);
	Hierarchy::make_available(Emit::tree(), CV_MEANING_iname);
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
			Emit::array_iname_entry(NewVerbs::form_iname(vf));
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@<Compile ConjugateVerb routine@> =
	packaging_state save = Routines::begin(Conjugation::conj_iname(vc));
	inter_symbol *fn_s = LocalVariables::add_named_call_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::add_named_call_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::add_named_call_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::add_named_call_as_symbol(I"modal_to");

	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, fn_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					NewVerbs::conj_from_wa(&(vc->infinitive), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					NewVerbs::conj_from_wa(&(vc->past_participle), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					NewVerbs::conj_from_wa(&(vc->present_participle), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

	int modal_verb = FALSE;
	@<Check for modality@>;

	verb *vi = vc->vc_conjugates;
	verb_meaning *vm = (vi)?VerbMeanings::first_unspecial_meaning_of_verb_form(Verbs::base_form(vi)):NULL;
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	inter_name *rel_iname = default_rr;
	if (meaning) {
		BinaryPredicates::mark_as_needed(meaning);
		rel_iname = meaning->bp_iname;
	}

			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MODAL_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					if (modal_verb) Produce::rtrue(Emit::tree());
					else Produce::rfalse(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MEANING_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, rel_iname);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

	for (int sense = 0; sense < 2; sense++) {
		inter_name *sense_iname = Hierarchy::find(CV_POS_HL);
		if (sense == 1) sense_iname = Hierarchy::find(CV_NEG_HL);
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, sense_iname);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, t_s);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<Compile conjugation in this sense@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
	}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Routines::end(save);

@<Compile ConjugateVerbForm routine@> =
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	packaging_state save = Routines::begin(NewVerbs::form_iname(vf));
	inter_symbol *fn_s = LocalVariables::add_named_call_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::add_named_call_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::add_named_call_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::add_named_call_as_symbol(I"modal_to");

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%A", &(vf->infinitive_reference_text));
	Emit::code_comment(C);
	DISCARD_TEXT(C)

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, t_s);
		Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_symbol(Emit::tree(), K_value, vp_s);
			Produce::val_symbol(Emit::tree(), K_value, t_s);
			Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MODAL_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, t_s);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	verb_meaning *vm = &(vf->list_of_senses->vm);
	inter_name *rel_iname = default_rr;
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	if (meaning) {
		BinaryPredicates::mark_as_needed(meaning);
		rel_iname = meaning->bp_iname;
	}


	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MEANING_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, rel_iname);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	if (vf->preposition) {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, " %A", &(vf->preposition->prep_text));
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), T);
		Produce::up(Emit::tree());
		DISCARD_TEXT(T)
	}

	Routines::end(save);

@<Check for modality@> =
	for (int sense=0; sense<NO_KNOWN_SENSES; sense++)
		for (int tense=0; tense<NO_KNOWN_TENSES; tense++)
			for (int person=0; person<NO_KNOWN_PERSONS; person++)
				for (int number=0; number<NO_KNOWN_NUMBERS; number++)
					if (vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number] != 0)
						modal_verb = TRUE;

@<Compile conjugation in this sense@> =
	for (int tense=0; tense<NO_KNOWN_TENSES; tense++) {
		int some_exist = FALSE, some_dont_exist = FALSE,
			some_differ = FALSE, some_except_3PS_differ = FALSE, some_are_modal = FALSE;
		word_assemblage *common = NULL, *common_except_3PS = NULL;
		for (int person=0; person<NO_KNOWN_PERSONS; person++)
			for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
				word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][person][number]);
				if (WordAssemblages::nonempty(*wa)) {
					if (some_exist) {
						if (WordAssemblages::eq(wa, common) == FALSE)
							some_differ = TRUE;
						if ((person != THIRD_PERSON) || (number != SINGULAR_NUMBER)) {
							if (common_except_3PS == NULL) common_except_3PS = wa;
							else if (WordAssemblages::eq(wa, common_except_3PS) == FALSE)
								some_except_3PS_differ = TRUE;
						}
					} else {
						some_exist = TRUE;
						common = wa;
						if ((person != THIRD_PERSON) || (number != SINGULAR_NUMBER))
							common_except_3PS = wa;
					}
					if (vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number] != 0)
						some_are_modal = TRUE;
				}
				else some_dont_exist = TRUE;
			}
		if (some_exist) {
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (tense+1));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					if ((some_differ) || (some_are_modal)) {
						if ((some_except_3PS_differ) || (some_dont_exist) || (some_are_modal))
							@<Compile a full switch of all six parts@>
						else
							@<Compile a choice between 3PS and the rest@>;
					} else {
						@<Compile for the case where all six parts are the same@>;
					}
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@<Compile a full switch of all six parts@> =
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, vp_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			for (int person=0; person<NO_KNOWN_PERSONS; person++)
				for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
					word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][person][number]);
					if (WordAssemblages::nonempty(*wa)) {
						Produce::inv_primitive(Emit::tree(), CASE_BIP);
						Produce::down(Emit::tree());
							inter_ti part = ((inter_ti) person) + 3*((inter_ti) number) + 1;
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) part);
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								int mau = vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number];
								NewVerbs::conj_from_wa(wa, vc, modal_to_s, mau);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					}
				}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Compile a choice between 3PS and the rest@> =
	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, vp_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][THIRD_PERSON][SINGULAR_NUMBER]);
			NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
			NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Compile for the case where all six parts are the same@> =
	word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
	NewVerbs::conj_from_wa(wa, vc, modal_to_s, 0);

@ =
void NewVerbs::conj_from_wa(word_assemblage *wa, verb_conjugation *vc, inter_symbol *modal_to_s, int mau) {
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Produce::down(Emit::tree());
		TEMPORARY_TEXT(OUT)
		if ((NewVerbs::takes_contraction_form(wa) == FALSE) && (NewVerbs::takes_contraction_form(&(vc->infinitive))))
			WRITE(" ");
		int i, n;
		vocabulary_entry **words;
		WordAssemblages::as_array(wa, &words, &n);
		for (i=0; i<n; i++) {
			if (i>0) WRITE(" ");
			wchar_t *q = Vocabulary::get_exemplar(words[i], FALSE);
			if ((q[0]) && (q[Wide::len(q)-1] == '*')) {
				TEMPORARY_TEXT(unstarred)
				WRITE_TO(unstarred, "%V", words[i]);
				Str::delete_last_character(unstarred);
				feed_t id = Feeds::begin();
				Feeds::feed_C_string(L" ");
				Feeds::feed_text(unstarred);
				Feeds::feed_C_string(L" ");
				DISCARD_TEXT(unstarred)
				wording W = Feeds::end(id);
				adjective *aph = Adjectives::declare(W, vc->defined_in);
				WRITE("\"; %n(prior_named_noun, (prior_named_list >= 2)); print \"",
					aph->adjective_compilation.aph_iname);
			} else {
				WRITE("%V", words[i]);
			}
		}
		Produce::val_text(Emit::tree(), OUT);
		DISCARD_TEXT(OUT)
	Produce::up(Emit::tree());
	if (mau != 0) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PRINT_BIP);
				Produce::down(Emit::tree());
					Produce::val_text(Emit::tree(), I" ");
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) mau);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
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
	<indefinite-article> <new-adjective-sentence-object-unarticled> |  ==> { pass 2 }
	<new-adjective-sentence-object-unarticled>                         ==> { pass 1 }

<new-adjective-sentence-object-unarticled> ::=
	adjective |                                                        ==> { TRUE, NULL }
	adjective implying/meaning <definite-article> <np-unparsed>	|      ==> { TRUE, RP[2] }
	adjective implying/meaning <np-unparsed>					       ==> { TRUE, RP[1] }

@ =
int NewVerbs::new_adjective_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "In French petit is an adjective meaning..." */
		case ACCEPT_SMFT:
			if (<new-adjective-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				if (O == NULL) { <np-unparsed>(OW); O = <<rp>>; }
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			NewVerbs::declare_meaningless_adjective(V);
			break;
	}
	return FALSE;
}



@ =
<adjective-definition-subject> ::=
	in <natural-language> ... |  ==> { TRUE, RP[1] }
	...                          ==> { TRUE, Projects::get_language_of_play(Task::project()) }

@ =
void NewVerbs::declare_meaningless_adjective(parse_node *p) {
	wording W = Node::get_text(p->next);
	<adjective-definition-subject>(W);
	NATURAL_LANGUAGE_WORDS_TYPE *nl = <<rp>>;
	W = GET_RW(<adjective-definition-subject>, 1);
	if (!(<adaptive-adjective>(W)))
		Adjectives::declare(W, nl);
}

@h Debug log.
The following dumps the entire stock of registered verb and preposition
usages to the debugging log.

=
void NewVerbs::log(verb_usage *vu) {
	VerbUsages::write_usage(DL, vu);
}

void NewVerbs::log_all(void) {
	verb_usage *vu;
	preposition *prep;
	LOG("The current S-grammar has the following verb and preposition usages:\n");
	LOOP_OVER(vu, verb_usage) {
		NewVerbs::log(vu);
		LOG("\n");
	}
	LOOP_OVER(prep, preposition) {
		LOG("$p\n", prep);
	}
}

@h Index tabulation.
The following produces the table of verbs in the Phrasebook Index page.

=
void NewVerbs::tabulate(OUTPUT_STREAM, index_lexicon_entry *lex, int tense, char *tensename) {
	verb_usage *vu; int f = TRUE;
	LOOP_OVER(vu, verb_usage)
		if ((vu->vu_lex_entry == lex) && (VerbUsages::is_used_negatively(vu) == FALSE)
			 && (VerbUsages::get_tense_used(vu) == tense)) {
			vocabulary_entry *lastword = WordAssemblages::last_word(&(vu->vu_text));
			if (f) {
				HTML::open_indented_p(OUT, 2, "tight");
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

void NewVerbs::tabulate_meaning(OUTPUT_STREAM, index_lexicon_entry *lex) {
	verb_usage *vu;
	LOOP_OVER(vu, verb_usage)
		if (vu->vu_lex_entry == lex) {
			if (vu->where_vu_created)
				Index::link(OUT, Wordings::first_wn(Node::get_text(vu->where_vu_created)));
			binary_predicate *bp = VerbMeanings::get_regular_meaning_of_form(Verbs::base_form(VerbUsages::get_verb(vu)));
			if (bp) Relations::index_for_verbs(OUT, bp);
			return;
		}
	preposition *prep;
	LOOP_OVER(prep, preposition)
		if (prep->prep_lex_entry == lex) {
			if (prep->where_prep_created)
				Index::link(OUT, Wordings::first_wn(Node::get_text(prep->where_prep_created)));
			binary_predicate *bp = VerbMeanings::get_regular_meaning_of_form(Verbs::find_form(copular_verb, prep, NULL));
			if (bp) Relations::index_for_verbs(OUT, bp);
			return;
		}
}

@

@d TRACING_LINGUISTICS_CALLBACK NewVerbs::trace_parsing

=
int NewVerbs::trace_parsing(int A) {
	if (SyntaxTree::is_trace_set(Task::syntax_tree())) return TRUE;
	return FALSE;
}
