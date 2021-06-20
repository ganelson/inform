[ActionSemantics::] Action Semantics.

Constraints on how actions may be used in the model world.

@ For example, the "inserting it in" action requires two objects to act on,
not, for example, a single number. Action semantics are to an action name
as a type signature is to a function.

An action involves "parameters", that is, nouns which are involved in it:
there would be 2 for "inserting it in", which is the maximum allowed. By
long-standing tradition, the first parameter is called the "noun" and the
second is called the "second".

=
typedef struct action_semantics {
	int out_of_world; /* action is declared as out of world? */
	int requires_light; /* does this action require light to be carried out? */
	int min_parameters, max_parameters; /* in the range 0 to 2 */
	int noun_access; /* one of the possibilities below */
	int second_access;
	struct kind *noun_kind; /* if there is at least 1 parameter */
	struct kind *second_kind; /* if there are 2 parameters */
} action_semantics;

@ A newly created action, by default, has this:

=
action_semantics ActionSemantics::default(void) {
	action_semantics sem;
	sem.out_of_world = FALSE;
	sem.requires_light = FALSE;
	sem.min_parameters = 0;
	sem.max_parameters = 0;
	sem.noun_kind = K_object;
	sem.noun_access = UNRESTRICTED_ACCESS;
	sem.second_kind = K_object;
	sem.second_access = UNRESTRICTED_ACCESS;
	return sem;
}

@ The code in this section looks as if more possibilities might exist, but in
fact Inform creates actions with only four configurations of min and max
parameters: $(0, 0), (0, 1), (1, 1), (2, 2)$. Actions with an optional noun,
the $(0, 1)$ case, are a residue of the days of Inform 6, which allowed for
example "listening" and "listening to the frog" as the same action. Today the
preferred way to do that is to use activities for selecting missing parameters.

=
void ActionSemantics::give_action_an_optional_noun(action_name *an, int acc, kind *K) {
	an->semantics.min_parameters = 0;
	an->semantics.max_parameters = 1;
	an->semantics.noun_access = acc;
	an->semantics.noun_kind = K;
}
void ActionSemantics::give_action_one_noun(action_name *an, int acc, kind *K) {
	an->semantics.min_parameters = 1;
	an->semantics.max_parameters = 1;
	an->semantics.noun_access = acc;
	an->semantics.noun_kind = K;
}
void ActionSemantics::give_action_two_nouns(action_name *an, int acc1, kind *K1,
	int acc2, kind *K2) {
	an->semantics.min_parameters = 2;
	an->semantics.max_parameters = 2;
	an->semantics.noun_access = acc1;
	an->semantics.noun_kind = K1;
	an->semantics.second_access = acc2;
	an->semantics.second_kind = K2;
	if ((Kinds::Behaviour::is_object(K1) == FALSE) &&
		(Kinds::Behaviour::is_object(K2) == FALSE))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ActionBothValues),
			"this action definition asks to have a single action apply "
			"to two different things which are not objects",
			"and unfortunately a fundamental restriction is that an "
			"action can apply to two objects, or one object and one "
			"value, but not to two values. Sorry about that.");
}

void ActionSemantics::make_action_out_of_world(action_name *an) {
	an->semantics.out_of_world = TRUE;
}
void ActionSemantics::make_action_require_light(action_name *an) {
	an->semantics.requires_light = TRUE;
}

@ It clarifies code elsewhere to give these conditions names as functions:

=
int ActionSemantics::can_have_noun(action_name *an) {
	if (an->semantics.max_parameters >= 1) return TRUE;
	return FALSE;
}

int ActionSemantics::can_have_second(action_name *an) {
	if (an->semantics.max_parameters >= 2) return TRUE;
	return FALSE;
}

int ActionSemantics::must_have_noun(action_name *an) {
	if (an->semantics.min_parameters >= 1) return TRUE;
	return FALSE;
}

int ActionSemantics::must_have_second(action_name *an) {
	if (an->semantics.min_parameters >= 2) return TRUE;
	return FALSE;
}

int ActionSemantics::max_parameters(action_name *an) {
	return an->semantics.max_parameters;
}

int ActionSemantics::requires_light(action_name *an) {
	if (an->semantics.requires_light) return TRUE;
	return FALSE;
}

int ActionSemantics::is_out_of_world(action_name *an) {
	if (an->semantics.out_of_world) return TRUE;
	return FALSE;
}

int ActionSemantics::noun_access(action_name *an) {
	return an->semantics.noun_access;
}

int ActionSemantics::second_access(action_name *an) {
	return an->semantics.second_access;
}

kind *ActionSemantics::kind_of_noun(action_name *an) {
	return an->semantics.noun_kind;
}

kind *ActionSemantics::kind_of_second(action_name *an) {
	return an->semantics.second_kind;
}

@ And this simple function amounts to a typechecker for a use of an action.
But note that it checks for too many nouns, but not for too few; so it can be
used to verify vaguely described actions in which no noun is given.

=
void ActionSemantics::check_valid_application(action_name *an, int nouns_supplied,
	kind **noun_kinds) {
	int possible = an->semantics.max_parameters;
	if (nouns_supplied > possible) {
		char *failed_on = NULL;
		switch(possible) {
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
		@<Issue an action usage problem@>;
	}

	if (nouns_supplied >= 1) {
		switch(ActionSemantics::noun_access(an)) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_kind = noun_kinds[0];
				kind *desired_kind = ActionSemantics::kind_of_noun(an);
				if (Kinds::compatible(supplied_kind, desired_kind)
					!= ALWAYS_MATCH) {
					char *failed_on =
						"the thing you suggest this action should act on "
						"has the wrong kind of value";
					@<Issue an action usage problem@>;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Behaviour::is_object(noun_kinds[0]) == FALSE) {
					char *failed_on =
						"the thing you suggest this action should act on "
						"is not an object at all";
					@<Issue an action usage problem@>;
				}
				break;
		}
	}
	if (nouns_supplied >= 2) {
		switch(ActionSemantics::second_access(an)) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_kind = noun_kinds[1];
				kind *desired_kind = ActionSemantics::kind_of_second(an);
				if (Kinds::compatible(supplied_kind, desired_kind)
					!= ALWAYS_MATCH) {
					char *failed_on =
						"the second thing you suggest this action should act on "
						"has the wrong kind of value";
					@<Issue an action usage problem@>;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Behaviour::is_object(noun_kinds[1]) == FALSE) {
					char *failed_on =
						"the second thing you suggest this action should act on "
						"is not an object at all";
					@<Issue an action usage problem@>;
				}
				break;
		}
	}
}

@<Issue an action usage problem@> =
	Problems::quote_source(1, current_sentence);
	if (an->compilation_data.designers_specification == NULL)
		Problems::quote_text(2, "<none given>");
	else
		Problems::quote_wording(2,
			Node::get_text(an->compilation_data.designers_specification));
	Problems::quote_wording(3, ActionNameNames::tensed(an, IS_TENSE));
	Problems::quote_text(4, failed_on);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_GrammarMismatchesAction));
	Problems::issue_problem_segment("The grammar you give in %1 is not compatible "
		"with the %3 action (defined as '%2') - %4.");
	Problems::issue_problem_end();
	return;

@ A stricter check is performed when we might want to compile an action in the
past tense; only very simple actions -- those with no parameter, or a single
parameter which is a thing -- can be tested this way, for reasons which become
clear from the implementation in //runtime: Actions//.

=
int ActionSemantics::can_be_compiled_in_past_tense(action_name *an) {
	if (ActionSemantics::can_have_second(an)) return FALSE;
	if ((ActionSemantics::can_have_noun(an)) &&
		(Kinds::Behaviour::is_object(ActionSemantics::kind_of_noun(an)) == FALSE))
			return FALSE;
	return TRUE;
}
