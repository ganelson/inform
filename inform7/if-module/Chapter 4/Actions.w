[PL::Actions::] Actions.

Each different sort of impulse to do something is an "action name".

@ An action is an impulse to do something within the model world, and there
will be many different sorts of impulse which a person may have: "going"
[i.e. somewhere], for example, or "wearing" [i.e. something].

Each of these different sorts of action is represented by an instance of
//action_name//, and each in turn corresponds to an instance of the enumerated
kind |K_action_name| at run-time. 

=
typedef struct action_name {
	struct noun *name; /* such as "taking action" */
	struct wording present_name; /* such as "drop" or "take" */
	struct wording past_name; /* such as "dropped" or "taken" */
	int it_optional; /* noun optional when describing the second noun? */
	int abbreviable; /* preposition optional when describing the second noun? */

	struct rulebook *check_rules; /* rulebooks private to this action */
	struct rulebook *carry_out_rules;
	struct rulebook *report_rules;
	struct stacked_variable_owner *action_variables;

	struct grammar_line *list_with_action; /* list of grammar producing this */

	struct action_semantics semantics;

	struct action_compilation_data compilation_data;
	struct action_indexing_data indexing_data;
	CLASS_DEFINITION
} action_name;

typedef struct action_semantics {
	int out_of_world; /* action is declared as out of world? */
	int requires_light; /* does this action require light to be carried out? */
	int min_parameters, max_parameters; /* in the range 0 to 2 */
	int noun_access; /* one of the possibilities below */
	int second_access;
	struct kind *noun_kind; /* if there is at least 1 parameter */
	struct kind *second_kind; /* if there are 2 parameters */
} action_semantics;

action_semantics PL::Actions::default_semantics(void) {
	action_semantics sem;
	sem.requires_light = FALSE;
	sem.noun_access = IMPOSSIBLE_ACCESS;
	sem.second_access = IMPOSSIBLE_ACCESS;
	sem.min_parameters = 0;
	sem.max_parameters = 0;
	sem.noun_kind = K_object;
	sem.second_kind = K_object;
	sem.out_of_world = FALSE;
	return sem;
}

@

= (early code)
stacked_variable_owner_list *all_nonempty_stacked_action_vars = NULL;

@ One action has special rules, to accommodate the "nowhere" syntax:

= (early code)
action_name *going_action = NULL;
action_name *waiting_action = NULL;

@

=
void PL::Actions::print_action_text_to(wording W, int start, OUTPUT_STREAM) {
	if (Wordings::first_wn(W) == start) {
		WRITE("%W", Wordings::first_word(W));
		W = Wordings::trim_first_word(W);
		if (Wordings::empty(W)) return;
		WRITE(" ");
	}
	WRITE("%+W", W);
}

@ The access possibilities for the noun and second noun are as follows.

@d UNRESTRICTED_ACCESS 0 /* question not meaningful, e.g. for a number */
@d IMPOSSIBLE_ACCESS 1 /* action doesn't take a noun, so no question of access */
@d DOESNT_REQUIRE_ACCESS 2 /* actor need not be able to touch this object */
@d REQUIRES_ACCESS 3 /* actor must be able to touch this object */
@d REQUIRES_POSSESSION 4 /* actor must be carrying this object */

=
int PL::Actions::actions_compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	if (PluginManager::active(actions_plugin) == FALSE)
		internal_error("actions plugin inactive");
	if (Kinds::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(spec);
		if (Holsters::data_acceptable(VH)) {
			inter_name *N = RTActions::iname(an);
			if (N) Emit::holster(VH, N);
		}
		return TRUE;
	}
	if (Kinds::eq(K, K_description_of_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(spec);
		PL::Actions::Patterns::compile_pattern_match(VH, *ap, FALSE);
		return TRUE;
	}
	if (Kinds::eq(K, K_stored_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(spec);
		if (TEST_COMPILATION_MODE(CONSTANT_CMODE))
			PL::Actions::Patterns::as_stored_action(VH, ap);
		else {
			PL::Actions::Patterns::emit_try(ap, TRUE);
		}
		return TRUE;
	}
	return FALSE;
}

int PL::Actions::actions_offered_property(kind *K, parse_node *owner, parse_node *what) {
	if (Kinds::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(owner);
		if (an == NULL) internal_error("failed to extract action-name structure");
		if (global_pass_state.pass == 1) PL::Actions::an_add_variable(an, what);
		return TRUE;
	}
	return FALSE;
}

int PL::Actions::actions_offered_specification(parse_node *owner, wording W) {
	if (Rvalues::is_CONSTANT_of_kind(owner, K_action_name)) {
		IXActions::actions_set_specification_text(
			Rvalues::to_action_name(owner), Wordings::first_wn(W));
		return TRUE;
	}
	return FALSE;
}

@ A stored action can always be compared to a gerund: for instance,

>> if the current action is taking something...

=
int PL::Actions::actions_typecheck_equality(kind *K1, kind *K2) {
	if ((Kinds::eq(K1, K_stored_action)) &&
		(Kinds::eq(K2, K_description_of_action)))
		return TRUE;
	return FALSE;
}

@ The constructor function for action names divides them into two according
to their implementation. Some actions are fully implemented in I6, and do
not have the standard check/carry out/report rulebooks: others are full I7
actions. (As I7 has matured, more and more actions have moved from the
first category to the second.)

@ This is an action name which Inform provides special support for; it
recognises the English name when defined by the Standard Rules. (So there is no
need to translate this to other languages.)

=
<notable-actions> ::=
	waiting |
	going

@ When we want to refer to an action name as a noun, we can use this to
make that explicit: for instance, "taking" becomes "the taking action".

=
<action-name-construction> ::=
	... action

@ =
action_name *PL::Actions::act_new(wording W, int implemented_by_I7) {
	int make_ds = FALSE;
	action_name *an = CREATE(action_name);
	if (<notable-actions>(W)) {
		if ((<<r>> == 1) && (going_action == NULL)) going_action = an;
		if ((<<r>> == 0) && (waiting_action == NULL)) {
			waiting_action = an;
			make_ds = TRUE;
		}
	}
	an->present_name = W;
	an->past_name = PastParticiples::pasturise_wording(an->present_name);
	an->it_optional = TRUE;
	an->abbreviable = FALSE;
	an->compilation_data = RTActions::new_data(W, implemented_by_I7);
	an->indexing_data = IXActions::new_data();
	an->check_rules = NULL;
	an->carry_out_rules = NULL;
	an->report_rules = NULL;
	an->list_with_action = NULL;
	
	an->semantics = PL::Actions::default_semantics();

	word_assemblage wa = PreformUtilities::merge(<action-name-construction>, 0,
		WordAssemblages::from_wording(W));
	wording AW = WordAssemblages::to_wording(&wa);
	an->name = Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_action_name(an), Task::language_of_syntax());

	Vocabulary::set_flags(Lexer::word(Wordings::first_wn(W)), ACTION_PARTICIPLE_MC);

	Kinds::Behaviour::new_enumerated_value(K_action_name);

	LOGIF(ACTION_CREATIONS, "Created action: %W\n", W);

	if (implemented_by_I7) {
		feed_t id = Feeds::begin();
		Feeds::feed_C_string_expanding_strings(L"check");
		Feeds::feed_wording(an->present_name);
		wording W = Feeds::end(id);
		package_request *CR = RTActions::rulebook_package(an, CHECK_RB_HL);
		an->check_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, CR);
		Rulebooks::fragment_by_actions(an->check_rules, 1);

		id = Feeds::begin();
		Feeds::feed_C_string_expanding_strings(L"carry out");
		Feeds::feed_wording(an->present_name);
		W = Feeds::end(id);
		package_request *OR = RTActions::rulebook_package(an, CARRY_OUT_RB_HL);
		an->carry_out_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, OR);
		Rulebooks::fragment_by_actions(an->carry_out_rules, 2);

		id = Feeds::begin();
		Feeds::feed_C_string_expanding_strings(L"report");
		Feeds::feed_wording(an->present_name);
		W = Feeds::end(id);
		package_request *RR = RTActions::rulebook_package(an, REPORT_RB_HL);
		an->report_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, RR);
		Rulebooks::fragment_by_actions(an->report_rules, 1);

		an->action_variables = StackedVariables::new_owner(20000+an->allocation_id);
	} else {
		an->action_variables = NULL;
	}

	action_name *an2;
	LOOP_OVER(an2, action_name)
		if (an != an2)
			if (PL::Actions::action_names_overlap(an, an2)) {
				an->it_optional = FALSE;
				an2->it_optional = FALSE;
			}

	return an;
}

/* pointing at, pointing it at */

@ The "action pronoun" use of "it" is to be a placeholder in an action
name to indicate where a noun phrase should appear. Some actions apply to
only one noun: for instance, in

>> taking the box

the action name is "taking". Others apply to two nouns:

>> unlocking the blue door with the key

has action name "unlocking it with". Inform always places one noun phrase
after the action name, but if it sees <action-pronoun> in the action name
then it places a second noun phrase at that point. (Any accusative pronoun
will do: it doesn't have to be "it".)

=
<action-pronoun> ::=
	<object-pronoun>

@ =
int PL::Actions::action_names_overlap(action_name *an1, action_name *an2) {
	wording W = an1->present_name;
	wording XW = an2->present_name;
	for (int i = Wordings::first_wn(W), j = Wordings::first_wn(XW);
		(i <= Wordings::last_wn(W)) && (j <= Wordings::last_wn(XW));
		i++, j++) {
		if ((<action-pronoun>(Wordings::one_word(i))) && (compare_words(i+1, j))) return TRUE;
		if ((<action-pronoun>(Wordings::one_word(j))) && (compare_words(j+1, i))) return TRUE;
		if (compare_words(i, j) == FALSE) return FALSE;
	}
	return FALSE;
}

void PL::Actions::log(action_name *an) {
	if (an == NULL) LOG("<null-action-name>");
	else LOG("%W", an->present_name);
}

@ And the following matches an action name (with no substitution of noun
phrases: "unlocking the door with" won't match the unlocking action; only
"unlocking it with" will do that).

=
<action-name> internal {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (Wordings::match(W, an->present_name)) {
			==> { -, an };
			return TRUE;
		}
	LOOP_OVER(an, action_name)
		if (<action-optional-trailing-prepositions>(an->present_name)) {
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

@ =
action_name *PL::Actions::longest_null(wording W, int tense, int *excess) {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (an->semantics.max_parameters == 0) {
			wording AW = (tense == IS_TENSE) ? (an->present_name) : (an->past_name);
			if (Wordings::starts_with(W, AW)) {
				*excess = Wordings::first_wn(W) + Wordings::length(AW);
				return an;
			}
		}
	return NULL;
}

int PL::Actions::it_optional(action_name *an) {
	return an->it_optional;
}

int PL::Actions::abbreviable(action_name *an) {
	return an->abbreviable;
}

action_name *PL::Actions::Wait(void) {
	if (waiting_action == NULL) internal_error("wait action not ready");
	return waiting_action;
}

rulebook *PL::Actions::get_fragmented_rulebook(action_name *an, rulebook *rb) {
	if (rb == built_in_rulebooks[CHECK_RB]) return an->check_rules;
	if (rb == built_in_rulebooks[CARRY_OUT_RB]) return an->carry_out_rules;
	if (rb == built_in_rulebooks[REPORT_RB]) return an->report_rules;
	internal_error("asked for peculiar fragmented rulebook"); return NULL;
}

rulebook *PL::Actions::switch_fragmented_rulebook(action_name *new_an, rulebook *orig) {
	action_name *an;
	if (new_an == NULL) return orig;
	LOOP_OVER(an, action_name) {
		if (orig == an->check_rules) return new_an->check_rules;
		if (orig == an->carry_out_rules) return new_an->carry_out_rules;
		if (orig == an->report_rules) return new_an->report_rules;
	}
	return orig;
}

@ Most actions are given automatically generated Inform 6 names in the
compiled code: |Q4_green|, for instance. A few must however correspond to
names of significance in the I6 library.

=
void PL::Actions::name_all(void) {
}

void PL::Actions::translates(wording W, parse_node *p2) {
	action_name *an = NULL;
	if (<action-name>(W)) an = <<rp>>;
	else {
		LOG("Tried action name %W\n", W);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TranslatesNonAction),
			"this does not appear to be the name of an action",
			"so cannot be translated into I6 at all.");
		return;
	}
	RTActions::translate(an, Node::get_text(p2));
}

int PL::Actions::get_stem_length(action_name *an) {
	if (Wordings::empty(an->present_name)) return 0; /* should never happen */
	int s = 0;
	LOOP_THROUGH_WORDING(k, an->present_name)
		if (!(<action-pronoun>(Wordings::one_word(k))))
			s++;
	return s;
}

@h Action variables.
Action variables can optionally be marked as able to extend the grammar of
action patterns. For example, the Standard Rules define:

>> The exiting action has an object called the container exited from (matched as "from").

and this allows "exiting from the cage", say, as an action pattern.

=
<action-variable> ::=
	<action-variable-name> ( matched as {<quoted-text-without-subs>} ) |    ==> { TRUE, - }
	<action-variable-name> ( ... ) |    ==> @<Issue PM_BadMatchingSyntax problem@>
	<action-variable-name>									==> { FALSE, - }

@ And the new action variable name is vetted by being run through this:

=
<action-variable-name> ::=
	<unfortunate-name> |    ==> @<Issue PM_ActionVarAnd problem@>
	...														==> { TRUE, - }

@<Issue PM_BadMatchingSyntax problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadMatchingSyntax));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an action - a value associated "
		"with a action and which has a name. The request seems to "
		"say in parentheses that the name in question is '%2', but "
		"I only recognise the form '(matched as \"some text\")' here.");
	Problems::issue_problem_end();
	==> { NOT_APPLICABLE, - };

@<Issue PM_ActionVarAnd problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionVarAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an action - a value associated "
		"with a action and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();

@ =
void PL::Actions::an_add_variable(action_name *an, parse_node *cnode) {
	wording MW = EMPTY_WORDING, NW = EMPTY_WORDING;
	stacked_variable *stv = NULL;

	if (Node::get_type(cnode) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionVarUncalled));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an action - a value associated "
			"with a action and which has a name. But since you only give "
			"a kind, not a name, I'm stuck. ('The taking action has a "
			"number called tenacity' is right, 'The taking action has a "
			"number' is too vague.)");
		Problems::issue_problem_end();
		return;
	}

	if (an->action_variables == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down->next));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable)); /* since we no longer define such actions */
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an action - a value associated "
			"with a action and which has a name. But this is a low-level "
			"action implemented internally by the Inform 6 library, and "
			"I am unable to give it any variables. Sorry.");
		Problems::issue_problem_end();
		return;
	}

	NW = Node::get_text(cnode->down->next);

	if (<action-variable>(Node::get_text(cnode->down->next))) {
		if (<<r>> == NOT_APPLICABLE) return;
		NW = GET_RW(<action-variable-name>, 1);
		if (<<r>>) {
			MW = GET_RW(<action-variable>, 1);
			int wn = Wordings::first_wn(MW);
			Word::dequote(wn);
			MW = Feeds::feed_C_string(Lexer::word_text(wn));
			if (Wordings::length(MW) > 1) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, MW);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MatchedAsTooLong));
				Problems::issue_problem_segment(
					"You wrote %1, which I am reading as a request to make "
					"a new named variable for an action - a value associated "
					"with a action and which has a name. You say that it should "
					"be '(matched as \"%2\")', but I can only recognise such "
					"matches when a single keyword is used to introduce the "
					"clause, and this is more than one word.");
				Problems::issue_problem_end();
				return;
			}
		}
	}

	kind *K = NULL;
	if (<k-kind>(Node::get_text(cnode->down))) K = <<rp>>;
	else {
		parse_node *spec = NULL;
		if (<s-type-expression>(Node::get_text(cnode->down))) spec = <<rp>>;
		if (Specifications::is_description(spec)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(cnode->down));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionVarOverspecific));
			Problems::issue_problem_segment(
				"You wrote %1, which I am reading as a request to make "
				"a new named variable for an action - a value associated "
				"with a action and which has a name. The request seems to "
				"say that the value in question is '%2', but this is too "
				"specific a description. (Instead, a kind of value "
				"(such as 'number') or a kind of object (such as 'room' "
				"or 'thing') should be given. To get a property whose "
				"contents can be any kind of object, use 'object'.)");
			Problems::issue_problem_end();
		} else {
			LOG("Offending SP: $T", spec);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(cnode->down));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionVarUnknownKOV));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not the name of a kind of "
				"value which I know (such as 'number' or 'text').");
			Problems::issue_problem_end();
		}
		return;
	}

	if (Kinds::eq(K, K_value)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionVarValue));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' "
			"does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door "
			"has a number called street address.' is allowed because "
			"'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

	if (StackedVariables::owner_empty(an->action_variables)) {
		all_nonempty_stacked_action_vars =
			StackedVariables::add_owner_to_list(all_nonempty_stacked_action_vars, an->action_variables);
	}

	stv = StackedVariables::add_empty(an->action_variables, NW, K);

	LOGIF(ACTION_CREATIONS, "Created action variable for $l: %W (%u)\n",
		an, Node::get_text(cnode->down->next), K);

	if (Wordings::nonempty(MW)) {
		StackedVariables::set_matching_text(stv, MW);
		LOGIF(ACTION_CREATIONS, "Match with text: %W + SP\n", MW);
	}
}

stacked_variable *PL::Actions::parse_match_clause(action_name *an, wording W) {
	return StackedVariables::parse_match_clause(an->action_variables, W);
}

@ This handles the special meaning "X is an action...".
<nounphrase-actionable> is an awkward necessity, designed to prevent the
regular sentence

>> The impulse is an action name that varies.

from being parsed as an instance of "... is an action ...", creating a
new action.

=
<new-action-sentence-object> ::=
	<indefinite-article> <new-action-sentence-object-unarticled> |    ==> { pass 2 }
	<new-action-sentence-object-unarticled>							==> { pass 1 }

<new-action-sentence-object-unarticled> ::=
	action <nounphrase-actionable> |    ==> { TRUE, RP[1] }
	action								==> @<Issue PM_BadActionDeclaration problem@>

<nounphrase-actionable> ::=
	^<variable-creation-tail>			==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<variable-creation-tail> ::=
	*** that/which vary/varies |
	*** variable

@<Issue PM_BadActionDeclaration problem@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadActionDeclaration),
		"it is not sufficient to say that something is an 'action'",
		"without giving the necessary details: for example, 'Unclamping "
		"is an action applying to one thing.'");
	==> { FALSE, NULL };

@ =
int PL::Actions::new_action_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Taking something is an action." */
		case ACCEPT_SMFT:
			if (<new-action-sentence-object>(OW)) {
				if (<<r>> == FALSE) return FALSE;
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			PL::Actions::act_parse_definition(V);
			break;
	}
	return FALSE;
}

@

@d OOW_ACT_CLAUSE 1
@d PP_ACT_CLAUSE 2
@d APPLYING_ACT_CLAUSE 3
@d LIGHT_ACT_CLAUSE 4
@d ABBREV_ACT_CLAUSE 5

=
action_name *an_being_parsed = NULL;

@ We now come to a quite difficult sentence to parse: the declaration of a
new action.

>> Inserting it into is an action applying to two things.
>> Verifying the story file is an action out of world and applying to nothing.

The subject noun phrase needs little further parsing -- it's the name of the
action to be created.

=
<action-sentence-subject> ::=
	<action-name> |  ==> @<Issue PM_ActionAlreadyExists problem@>
	...              ==> { 0, PL::Actions::act_new(W, TRUE) }

@<Issue PM_ActionAlreadyExists problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActionAlreadyExists),
		"that seems to be an action already existing",
		"so it cannot be redefined now. If you would like to reconfigure "
		"an action in the standard set - for instance if you prefer "
		"'unlocking' to apply to only one thing, not two - create a new "
		"action for what you need ('keyless unlocking', perhaps) and then "
		"change the grammar to use the new action rather than the old "
		"('Understand \"unlock [something]\" as keyless unlocking.').");
	==> { fail nonterminal };

@ The object NP is trickier, because it is a sequence
of "action clauses" which can occur in any order, which are allowed but
not required to be delimited as a list, and which can inconveniently
contain the word "and"; not only that, but note that in

>> applying to one thing and one number

the initial text "applying to one thing" would be valid as it stands.
It's convenient to define a single action clause first:

=
<action-clause> ::=
	out of world |                       ==> { OOW_ACT_CLAUSE, - }
	abbreviable |                        ==> { ABBREV_ACT_CLAUSE, - }
	with past participle ... |           ==> { PP_ACT_CLAUSE, - }
	applying to <action-applications> |  ==> { APPLYING_ACT_CLAUSE, -, <<num>> = R[1] }
	requiring light                      ==> { LIGHT_ACT_CLAUSE, - }

<action-applications> ::=
	nothing |                            ==> { 0, - }
	one <act-req> and one <act-req> |    ==> { 2, -, <<kind:op1>> = RP[1], <<ac1>> = R[1], <<kind:op2>> = RP[2], <<ac2>> = R[2] }
	one <act-req> and <act-req> |        ==> { 2, -, <<kind:op1>> = RP[1], <<ac1>> = R[1], <<kind:op2>> = RP[2], <<ac2>> = R[2] }
	<act-req> and one <act-req> |        ==> { 2, -, <<kind:op1>> = RP[1], <<ac1>> = R[1], <<kind:op2>> = RP[2], <<ac2>> = R[2] }
	<act-req> and <act-req> |            ==> { 2, -, <<kind:op1>> = RP[1], <<ac1>> = R[1], <<kind:op2>> = RP[2], <<ac2>> = R[2] }
	nothing or one <act-req> |           ==> { -1, -, <<kind:op1>> = RP[1], <<ac1>> = R[1] }
	one <act-req> |                      ==> { 1, -, <<kind:op1>> = RP[1], <<ac1>> = R[1] }
	two <act-req>	|                    ==> { 2, -, <<kind:op1>> = RP[1], <<ac1>> = R[1], <<kind:op2>> = RP[1], <<ac2>> = R[1] }
	<act-req> |                          ==> { 1, -, <<kind:op1>> = RP[1], <<ac1>> = R[1] }
	...                                  ==> @<Issue PM_ActionMisapplied problem@>;

<act-req> ::=
	<act-req-inner>                      ==> @<Check action kind@>;

<act-req-inner> ::=
	<action-access> <k-kind> |           ==> { R[1], RP[2] }
	<k-kind>                             ==> { UNRESTRICTED_ACCESS, RP[1] }

<action-access> ::=
	visible |                            ==> { DOESNT_REQUIRE_ACCESS, - }
	touchable |                          ==> { REQUIRES_ACCESS, - }
	carried                              ==> { REQUIRES_POSSESSION, - }

@ We are now able to define this peculiar form of list of action clauses:

=
<action-sentence-object> ::=
	<action-clauses> |                   ==> { 0, - }
	...                                  ==> @<Issue PM_ActionClauseUnknown problem@>

<action-clauses> ::=
	... |                                         ==> { lookahead }
	<action-clauses> <action-clause-terminated> | ==> { R[2], - }; PL::Actions::act_on_clause(R[2]);
	<action-clause-terminated>                    ==> { R[1], - }; PL::Actions::act_on_clause(R[1]);

<action-clause-terminated> ::=
	<action-clause> , and |              ==> { pass 1 }
	<action-clause> and |                ==> { pass 1 }
	<action-clause> , |                  ==> { pass 1 }
	<action-clause>                      ==> { pass 1 }

@<Issue PM_ActionClauseUnknown problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActionClauseUnknown),
		"the action definition contained text I couldn't follow",
		"and may be too complicated.");

@<Check action kind@> =
	int A = R[1]; kind *K = RP[1];
	if (Kinds::eq(K, K_thing)) {
		if (A == UNRESTRICTED_ACCESS) A = REQUIRES_ACCESS;
		==> { A, K_object };
	} else if (Kinds::Behaviour::is_subkind_of_object(K)) {
		@<Issue PM_ActionMisapplied problem@>;
	} else if (A != UNRESTRICTED_ACCESS) {
		@<Issue PM_ActionMisapplied problem@>;
	} else {
		==> { A, K };
	}

@<Issue PM_ActionMisapplied problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActionMisapplied),
		"an action can only apply to things or to kinds of value",
		"for instance: 'photographing is an action applying to "
		"one visible thing'.");
	==> { REQUIRES_ACCESS, K_thing };

@ =
void PL::Actions::act_on_clause(int N) {
	switch (N) {
		case OOW_ACT_CLAUSE:
			an_being_parsed->semantics.out_of_world = TRUE; break;
		case PP_ACT_CLAUSE: {
			wording C = GET_RW(<action-clause>, 1);
			if (Wordings::length(C) != 1)
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_MultiwordPastParticiple),
					"a past participle must be given as a single word",
					"even if the action name itself is longer than that. "
					"(For instance, the action name 'hanging around until' "
					"should have past participle given just as 'hung'; I "
					"can already deduce the rest.)");
			an_being_parsed->past_name =
				PL::Actions::set_past_participle(an_being_parsed->past_name,
					Wordings::last_wn(C));
			break;
		}
		case APPLYING_ACT_CLAUSE:
			an_being_parsed->semantics.noun_access = <<ac1>>; an_being_parsed->semantics.second_access = <<ac2>>;
			an_being_parsed->semantics.noun_kind = <<kind:op1>>; an_being_parsed->semantics.second_kind = <<kind:op2>>;
			an_being_parsed->semantics.min_parameters = <<num>>;
			an_being_parsed->semantics.max_parameters = an_being_parsed->semantics.min_parameters;
			if (an_being_parsed->semantics.min_parameters == -1) {
				an_being_parsed->semantics.min_parameters = 0;
				an_being_parsed->semantics.max_parameters = 1;
			}
			break;
		case LIGHT_ACT_CLAUSE:
			an_being_parsed->semantics.requires_light = TRUE;
			break;
		case ABBREV_ACT_CLAUSE:
			an_being_parsed->abbreviable = TRUE;
			break;
	}
}

@ =
wording PL::Actions::set_past_participle(wording W, int irregular_pp) {
	feed_t id = Feeds::begin();
	Feeds::feed_wording(Wordings::one_word(irregular_pp));
	if (Wordings::length(W) > 1)
		Feeds::feed_wording(Wordings::trim_first_word(W));
	return Feeds::end(id);
}

@ =
void PL::Actions::act_parse_definition(parse_node *p) {
	<action-sentence-subject>(Node::get_text(p->next));
	action_name *an = <<rp>>;
	if (an == NULL) return;

	if (p->next->next) {
		an->indexing_data.designers_specification = p->next->next;

		an_being_parsed = an;
		<<ac1>> = IMPOSSIBLE_ACCESS;
		<<ac2>> = IMPOSSIBLE_ACCESS;
		<<kind:op1>> = K_object;
		<<kind:op2>> = K_object;
		<<num>> = 0;

		<action-sentence-object>(Node::get_text(p->next->next));
	}

	if (an->semantics.max_parameters >= 2) {
		if ((Kinds::Behaviour::is_object(an->semantics.noun_kind) == FALSE) &&
			(Kinds::Behaviour::is_object(an->semantics.second_kind) == FALSE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActionBothValues),
				"this action definition asks to have a single action apply "
				"to two different things which are not objects",
				"and unfortunately a fundamental restriction is that an "
				"action can apply to two objects, or one object and one "
				"value, but not to two values. Sorry about that.");
			return;
		}
	}
}

int PL::Actions::is_out_of_world(action_name *an) {
	if (an->semantics.out_of_world) return TRUE;
	return FALSE;
}

kind *PL::Actions::get_data_type_of_noun(action_name *an) {
	return an->semantics.noun_kind;
}

kind *PL::Actions::get_data_type_of_second_noun(action_name *an) {
	return an->semantics.second_kind;
}

wording PL::Actions::set_text_to_name_tensed(action_name *an, int tense) {
	if (tense == HASBEEN_TENSE) return an->past_name;
	return an->present_name;
}

int PL::Actions::can_have_parameters(action_name *an) {
	if (an->semantics.max_parameters > 0) return TRUE;
	return FALSE;
}

int PL::Actions::get_max_parameters(action_name *an) {
	return an->semantics.max_parameters;
}

int PL::Actions::get_min_parameters(action_name *an) {
	return an->semantics.min_parameters;
}

@h Past tense.
Simpler actions -- those with no parameter, or a single parameter which is
a thing -- can be tested in the past tense. The run-time support for this
is a general bitmap revealing which actions have ever happened, plus a
bitmap for each object revealing which have ever been applied to the object
in question. This is where we compile the bitmaps in their fresh, empty form.

=
int PL::Actions::can_be_compiled_in_past_tense(action_name *an) {
	if (an->semantics.min_parameters > 1) return FALSE;
	if (an->semantics.max_parameters > 1) return FALSE;
	if ((an->semantics.max_parameters == 1) &&
		(Kinds::Behaviour::is_object(an->semantics.noun_kind) == FALSE))
			return FALSE;
	return TRUE;
}

@h The grammar list.

=
void PL::Actions::add_gl(action_name *an, grammar_line *gl) {
	if (an->list_with_action == NULL) an->list_with_action = gl;
	else PL::Parsing::Lines::list_with_action_add(an->list_with_action, gl);
}

void PL::Actions::remove_gl(action_name *an) {
	an->list_with_action = NULL;
}

@h Typechecking grammar for an action.

=
void PL::Actions::check_types_for_grammar(action_name *an, int tok_values,
	kind **tok_value_kinds) {
	int required = 0; char *failed_on = "<internal error>";

	if (an->semantics.noun_access != IMPOSSIBLE_ACCESS)
		required++;
	if (an->semantics.second_access != IMPOSSIBLE_ACCESS)
		required++;
	if (required < tok_values) {
		switch(required) {
			case 0:
				failed_on =
					"this action applies to nothing, but you have provided "
					"material in square brackets which expands to something";
				break;
			case 1:
				failed_on =
					"this action applies to just one thing, but you have "
					"put more than one thing in square brackets";
				break;
			default:
				failed_on =
					"this action applies to two things, the maximum possible, "
					"but you have put more than two in square brackets";
				break;
		}
		goto Unmatched;
	}

	if (tok_values >= 1) {
		switch(an->semantics.noun_access) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_data_type = tok_value_kinds[0];
				kind *desired_data_type = an->semantics.noun_kind;
				if (Kinds::compatible(supplied_data_type, desired_data_type)
					!= ALWAYS_MATCH) {
					failed_on =
						"the thing you suggest this action should act on "
						"has the wrong kind of value";
					goto Unmatched;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Behaviour::is_object(tok_value_kinds[0]) == FALSE) {
					failed_on =
						"the thing you suggest this action should act on "
						"is not an object at all";
					goto Unmatched;
				}
				break;
		}
	}
	if (tok_values == 2) {
		switch(an->semantics.second_access) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_data_type = tok_value_kinds[1];
				kind *desired_data_type = an->semantics.second_kind;
				if (Kinds::compatible(supplied_data_type, desired_data_type)
					!= ALWAYS_MATCH) {
					failed_on =
						"the second thing you suggest this action should act on "
						"has the wrong kind of value";
					goto Unmatched;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Behaviour::is_object(tok_value_kinds[1]) == FALSE) {
					failed_on =
						"the second thing you suggest this action should act on "
						"is not an object at all";
					goto Unmatched;
				}
				break;
		}
	}

	return;
	Unmatched:
		Problems::quote_source(1, current_sentence);
		if (an->indexing_data.designers_specification == NULL)
			Problems::quote_text(2, "<none given>");
		else
			Problems::quote_wording(2, Node::get_text(an->indexing_data.designers_specification));
		Problems::quote_wording(3, an->present_name);
		Problems::quote_text(4, failed_on);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GrammarMismatchesAction));
		Problems::issue_problem_segment("The grammar you give in %1 is not compatible "
			"with the %3 action (defined as '%2') - %4.");
		Problems::issue_problem_end();
}

