[ActionNameNames::] Action Name Names.

There is an annoying profusion of ways an action can have a name.

@ An //action_name// can be referred to in quite a number of ways, and the
rules about that are gathered into this structure:

=
typedef struct action_naming_data {
	struct noun *as_noun; /* such as "taking action" */
	struct wording present_name; /* such as "dropping" or "removing it from" */
	struct wording past_name; /* such as "dropped" or "removed it from" */
	int it_optional; /* noun optional when describing the second noun? */
	int abbreviable; /* preposition optional when describing the second noun? */
} action_naming_data;

@ Here, the default settings are made from |W|. The past tense form is made
automatically from the present. The noun form is made using the following
construction; thus, the run-time value corresponding to "taking" is "the taking
action".

=
<action-name-construction> ::=
	... action

@ =
void ActionNameNames::baptise(action_name *an, wording W) {
	an->naming_data.present_name = W;
	an->naming_data.past_name =
		PastParticiples::pasturise_wording(an->naming_data.present_name);
	an->naming_data.it_optional = TRUE;
	an->naming_data.abbreviable = FALSE;
	word_assemblage wa = PreformUtilities::merge(<action-name-construction>, 0,
		WordAssemblages::from_wording(W));
	wording AW = WordAssemblages::to_wording(&wa);
	an->naming_data.as_noun = Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, ARvalues::from_action_name(an), Task::language_of_syntax());
	Vocabulary::set_flags(Lexer::word(Wordings::first_wn(W)), ACTION_PARTICIPLE_MC);
	action_name *an2;
	LOOP_OVER(an2, action_name)
		if (an != an2)
			if (ActionNameNames::action_names_overlap(an, an2)) {
				an->naming_data.it_optional = FALSE;
				an2->naming_data.it_optional = FALSE;
			}
	ActionsPlugin::notice_new_action_name(an);
}

@ In the early days of Inform, past participles had to be set explicitly, and
we retain the ability for authors to do that; but the automatics are now good
enough that this is almost never used.

=
void ActionNameNames::set_irregular_past(action_name *an, wording C) {			
	if (Wordings::length(C) != 1)
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_MultiwordPastParticiple),
			"a past participle must be given as a single word",
			"even if the action name itself is longer than that. (For instance, "
			"the action name 'hanging around until' should have past participle "
			"given just as 'hung'; I can already deduce the rest.)");
	wording W = an_being_parsed->naming_data.past_name;
	feed_t id = Feeds::begin();
	Feeds::feed_wording(C);
	if (Wordings::length(W) > 1) Feeds::feed_wording(Wordings::trim_first_word(W));
	an_being_parsed->naming_data.past_name = Feeds::end(id);
}

@ We are unlikely to need other tenses.

=
wording ActionNameNames::tensed(action_name *an, int tense) {
	if (tense == IS_TENSE) return an->naming_data.present_name;
	if (tense == HASBEEN_TENSE) return an->naming_data.past_name;
	internal_error("action tense unsupported");
	return an->naming_data.present_name;
}

void ActionNameNames::log(action_name *an) {
	if (an == NULL) LOG("<null-action-name>");
	else LOG("%W", ActionNameNames::tensed(an, IS_TENSE));
}

@ Object pronouns -- let's just say, the word "it" for brevity -- in an action
name are significant: they are placeholders for where the first of two nouns
is supposed to go. Thus, in the action name "unlocking it with", the word "it"
shows where to put the name of what is being unlocked.

In an "abbreviable" action name, the preposition after the "it" can be omitted
in source text: thus "unlocking it" would do as well as "unlocking it with".

And even the "it" can be omitted, taking us right down to "unlocking", but only
if there is not ambiguity in doing so. We became more careful about this when an
author innocently created different actions called "pointing at" and "pointing
it at" in the same work: the trouble being that "pointing" might be a legal
abbreviation for both of them. The following looks for action names which
overlap in this way, so that permission to lose the "it" can be withdrawn in
their cases:

=
int ActionNameNames::action_names_overlap(action_name *an1, action_name *an2) {
	wording W = an1->naming_data.present_name;
	wording XW = an2->naming_data.present_name;
	for (int i = Wordings::first_wn(W), j = Wordings::first_wn(XW);
		(i <= Wordings::last_wn(W)) && (j <= Wordings::last_wn(XW));
		i++, j++) {
		if ((<object-pronoun>(Wordings::one_word(i))) && (compare_words(i+1, j))) return TRUE;
		if ((<object-pronoun>(Wordings::one_word(j))) && (compare_words(j+1, i))) return TRUE;
		if (compare_words(i, j) == FALSE) return FALSE;
	}
	return FALSE;
}

@ The "non-it length" of an action name is the number of words other than the
pronoun. For example, the non-it length of "unlocking it with" is 2.

=
int ActionNameNames::non_it_length(action_name *an) {
	int s = 0;
	LOOP_THROUGH_WORDING(k, an->naming_data.present_name)
		if (!(<object-pronoun>(Wordings::one_word(k))))
			s++;
	return s;
}

@ Whether "it" is optional is determined automatically, then, but whether the
preposition can be abbreviated is under the author's control:

=
int ActionNameNames::it_optional(action_name *an) {
	return an->naming_data.it_optional;
}

void ActionNameNames::make_abbreviable(action_name *an) {
	an->naming_data.abbreviable = TRUE;
}

int ActionNameNames::abbreviable(action_name *an) {
	return an->naming_data.abbreviable;
}

@ The names of the three rulebooks associated with an action are built here.
Note that it is absolutely required that the names consist of a fixed prefix
wording, followed by the present-tense name of the action in question.

=
<action-rulebook-construction> ::=
	check ... |
	carry out ... |
	report ...

@ =
wording ActionNameNames::rulebook_name(action_name *an, int RB) {
	int N = 0;
	switch (RB) {
		case CHECK_RB_HL:     N = 0; break;
		case CARRY_OUT_RB_HL: N = 1; break;
		case REPORT_RB_HL:    N = 2; break;
		default: internal_error("unimplemented action rulebook");
	}
	word_assemblage wa = PreformUtilities::merge(<action-rulebook-construction>, N,
		WordAssemblages::from_wording(ActionNameNames::tensed(an, IS_TENSE)));
	return WordAssemblages::to_wording(&wa);
}

@ Parsing descriptions of action is in general very difficult, but here
are some simple starts in on it.

The following matches an action name with no substitution of noun phrases,
and without the word "action": thus "unlocking it with" matches, but not
"unlocking the door with" or "unlocking it with action".

This should be used only where speed is unimportant. It would not be a good
idea to use this when parsing action patterns.

=
<action-name> internal {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (Wordings::match(W, ActionNameNames::tensed(an, IS_TENSE))) {
			==> { -, an };
			return TRUE;
		}
	LOOP_OVER(an, action_name)
		if (<action-optional-trailing-prepositions>(ActionNameNames::tensed(an, IS_TENSE))) {
			wording SHW = GET_RW(<action-optional-trailing-prepositions>, 1);
			if (Wordings::match(W, SHW)) {
				==> { -, an };
				return TRUE;
			}
		}
	==> { fail nonterminal };
}

@ However, <action-name> can also be made to match an action name without
a final preposition, if that preposition is on the following list. For
example, it allows "listening" to match the listening to action; this is
needed because of the almost unique status of "listening" in having an
optional noun. (Unabbreviated action names always win if there's an
ambiguity here: i.e., if there is a second action called just "listening",
then that's what "listening" will match.)

=
<action-optional-trailing-prepositions> ::=
	... to

@ The following returns the longest-named action beginning with the wording |W|
and which cannot take nouns; and the word number |posn| is moved past this
number of words.

=
action_name *ActionNameNames::longest_nounless(wording W, int tense, int *posn) {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (ActionSemantics::can_have_noun(an) == FALSE) {
			wording AW = ActionNameNames::tensed(an, tense);
			if (Wordings::starts_with(W, AW)) {
				if (posn) *posn = Wordings::first_wn(W) + Wordings::length(AW);
				return an;
			}
		}
	return NULL;
}
