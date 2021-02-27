[ActionVariables::] Action Variables.

Variables shared by the rules of the rulebooks processing an action.

@ Action names, that is, instances of |K_action_name|, do not have properties.
Instead, sentences which look as if they will assign properties are turned
into creations of action variables:

=
int ActionVariables::actions_offered_property(kind *K, parse_node *owner, parse_node *prop) {
	if (Kinds::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(owner);
		if (an == NULL) internal_error("failed to extract action-name structure");
		if (global_pass_state.pass == 1) {
			@<Require the variable to have an explicit name@>;
			kind *K = NULL;
			@<Determine and vet the kind of the new variable@>;
			wording NW = Node::get_text(prop->down->next);
			wording MW = EMPTY_WORDING;
			@<Find the name and match wordings@>;
			@<Reject multi-word match wordings@>;
			ActionVariables::new(an, K, NW, MW);
		}
		return TRUE;
	}
	return FALSE;
}

@ Properties can be nameless, or rather, have the name only of their kind;
but action variables cannot.

@<Require the variable to have an explicit name@> =
	if (Node::get_type(prop) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActionVarUncalled));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named "
			"variable for an action - a value associated with a action and which "
			"has a name. But since you only give a kind, not a name, I'm stuck. "
			"('The taking action has a number called tenacity' is right, 'The "
			"taking action has a number' is too vague.)");
		Problems::issue_problem_end();
		return TRUE;
	}

@<Determine and vet the kind of the new variable@> =
	wording KW = Node::get_text(prop->down);
	if (<k-kind>(KW)) K = <<rp>>;
	else {
		parse_node *spec = NULL;
		if (<s-type-expression>(KW)) spec = <<rp>>;
		if (Specifications::is_description(spec)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, KW);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_ActionVarOverspecific));
			Problems::issue_problem_segment(
				"You wrote %1, which I am reading as a request to make a new named "
				"variable for an action - a value associated with a action and which "
				"has a name. The request seems to say that the value in question is "
				"'%2', but this is too specific a description. (Instead, a kind of "
				"value (such as 'number') or a kind of object (such as 'room' or "
				"'thing') should be given. To get a property whose contents can be "
				"any kind of object, use 'object'.)");
			Problems::issue_problem_end();
		} else {
			LOG("Offending SP: $T", spec);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, KW);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_ActionVarUnknownKOV));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not the name of a kind of value which "
				"I know (such as 'number' or 'text').");
			Problems::issue_problem_end();
		}
		return TRUE;
	}

	if (Kinds::Behaviour::definite(K) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, KW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActionVarValue));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' does not give me "
			"a clear enough idea what it will hold. You need to say what kind of "
			"value: for instance, 'A door has a number called street address.' is "
			"allowed because 'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return TRUE;
	}

@ Variable names need to be sensible, but can have bracketed match clauses:

=
<action-variable> ::=
	<action-variable-name> ( matched as {<quoted-text-without-subs>} ) | ==> { TRUE, - }
	<action-variable-name> ( ... ) |          ==> @<Issue PM_BadMatchingSyntax problem@>
	<action-variable-name>                    ==> { FALSE, - }

<action-variable-name> ::=
	<unfortunate-name> |                      ==> @<Issue PM_ActionVarAnd problem@>
	...	                                      ==> { TRUE, - }

@<Issue PM_BadMatchingSyntax problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_BadMatchingSyntax));
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
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_ActionVarAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an action - a value associated "
		"with a action and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();
	==> { NOT_APPLICABLE, - };

@<Find the name and match wordings@> =
	if (<action-variable>(NW)) {
		if (<<r>> == NOT_APPLICABLE) return TRUE;
		NW = GET_RW(<action-variable-name>, 1);
		if (<<r>>) {
			MW = GET_RW(<action-variable>, 1);
			int wn = Wordings::first_wn(MW);
			Word::dequote(wn);
			MW = Feeds::feed_C_string(Lexer::word_text(wn));
		}
	}

@<Reject multi-word match wordings@> =
	if (Wordings::length(MW) > 1) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, MW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_MatchedAsTooLong));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an action - a value associated "
			"with a action and which has a name. You say that it should "
			"be '(matched as \"%2\")', but I can only recognise such "
			"matches when a single keyword is used to introduce the "
			"clause, and this is more than one word.");
		Problems::issue_problem_end();
		return TRUE;
	}

@ An owner list is maintained for all sets of actions which actually have
variables (hence "nonempty") -- many will not, in practice:

= (early code)
stacked_variable_owner_list *all_nonempty_stacked_action_vars = NULL;


@ =
void ActionVariables::new(action_name *an, kind *K, wording NW, wording MW) {
	if (StackedVariables::owner_empty(an->action_variables))
		all_nonempty_stacked_action_vars =
			StackedVariables::add_owner_to_list(
				all_nonempty_stacked_action_vars, an->action_variables);

	stacked_variable *stv = StackedVariables::add_empty(an->action_variables, NW, K);
	if (Wordings::nonempty(MW))
		StackedVariables::set_matching_text(stv, MW);

	LOGIF(ACTION_CREATIONS, "Created action variable for $l: %W (%u)\n", an, NW, K);
	if (Wordings::nonempty(MW))
		LOGIF(ACTION_CREATIONS, "Match with text: %W + SP\n", MW);
}

@ Action variables can optionally be marked as able to extend the grammar of
action patterns. For example, the Standard Rules define:

>> The exiting action has an object called the container exited from (matched as "from").

and this allows "exiting from the cage", say, as an action pattern.

=
stacked_variable *ActionVariables::parse_match_clause(action_name *an, wording W) {
	return StackedVariables::parse_match_clause(an->action_variables, W);
}
