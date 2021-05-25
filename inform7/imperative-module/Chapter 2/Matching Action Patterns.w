[RTActionPatterns::] Matching Action Patterns.

Testing whether the current action matches an action pattern means compiling
a complicated multi-clause condition, which is what this section does.

@h API.
We provide two functions to the rest of Inform. "Actorless" mode is the
one less used: it means that we should not make assumptions about who the
actor is in cases where no actor is specified. See below.

The |:actions| test group may be useful here.

=
void RTActionPatterns::compile_pattern_match(action_pattern *ap) {
	RTActionPatterns::compile_pattern_match_inner(ap, FALSE);
}

void RTActionPatterns::compile_pattern_match_actorless(action_pattern *ap) {
	RTActionPatterns::compile_pattern_match_inner(ap, TRUE);
}

@h Compile-Pattern-Match-Clauses.
Matching a typical action pattern involves testing several different things:
for example, "going from the Casino in the presence of Le Chiffre" means
testing that the action is "going", that the origin is the Casino, and that
Le Chiffre is there -- three CPMC clauses.

The basic roster of CPMC clauses is here, but plugins can add more. In
particular, see //Matching Going Action Patterns//.

Do not rearrange this without first reading the code below: the ordering is
very significant. The CPMCs are grouped into "ranges", and it is intentional
that those ranges are numbered 0, 1, 3, 2; we need the additional CPMCs from
plugins to fall into range 2.

@d ACTOR_CPMCRANGE 0

@e ACTOR_IS_PLAYER_CPMC from 1
@e ACTOR_IS_NOT_PLAYER_CPMC
@e REQUESTER_EXISTS_CPMC
@e REQUESTER_DOES_NOT_EXIST_CPMC
@e ACTOR_MATCHES_CPMC

@d ACTION_CPMCRANGE 1

@e ACTION_MATCHES_CPMC

@d WHEN_CPMCRANGE 3

@e SET_SELF_TO_ACTOR_CPMC
@e WHEN_CONDITION_HOLDS_CPMC

@d DETAILS_CPMCRANGE 2

@e NOUN_EXISTS_CPMC
@e NOUN_IS_INP1_CPMC
@e SECOND_EXISTS_CPMC
@e SECOND_IS_INP2_CPMC
@e NOUN_MATCHES_AS_OBJECT_CPMC
@e NOUN_MATCHES_AS_VALUE_CPMC
@e SECOND_MATCHES_AS_OBJECT_CPMC
@e SECOND_MATCHES_AS_VALUE_CPMC
@e PLAYER_LOCATION_MATCHES_CPMC
@e ACTOR_IS_SOMEWHERE_CPMC
@e ACTOR_LOCATION_MATCHES_CPMC
@e PARAMETER_MATCHES_CPMC
@e OPTIONAL_CLAUSE_CPMC
@e PRESENCE_OF_MATCHES_CPMC
@e PRESENCE_OF_IN_SCOPE_CPMC
@e LOOP_OVER_SCOPE_CALLING_CPMC
@e LOOP_OVER_SCOPE_NOT_CALLING_CPMC

@h Matching.
When a pattern is written in a way which refers to the past -- "if we are examining
the table for the third time", say -- we divert to the past-tense code, though
in fact the underlying pattern -- "examining the table" -- will eventually come
back here, shorn of its |duration| marker. Anyway, we get rid of that case first.

The strategy is to work out a list of clauses needed, and then compile them.

=
void RTActionPatterns::compile_pattern_match_inner(action_pattern *ap,
	int actorless) {
	if (ap == NULL) return;
	LOGIF(ACTION_PATTERN_COMPILATION, "Compiling action pattern:\n  $A\n", ap);

	if (ap->duration) {
		LOGIF(ACTION_PATTERN_COMPILATION, "As past action\n");
		Chronology::compile_action_history_condition(ap->duration, *ap);
	} else {
		int cpm_count = 0, needed[MAX_CPM_CLAUSES];
		ap_clause *needed_apoc[MAX_CPM_CLAUSES];

		kind *kind_of_noun = K_object;
		kind *kind_of_second = K_object;
		@<Work out the kind of the noun and second noun@>;

		@<Work out what clauses will be needed@>;
		@<Compile the condition from these instructions@>;
	}
}

@ We can infer the kind which the noun or second noun would need to have
from the action. For example, "dropping something" implies that the "something"
is an object; but "setting the combination to something" might imply that
"something" is a number. (We look at the first action in the list because lists
are not allowed to mix actions with different kinds; so the answer would be
the same for any of the actions in the list.)

@<Work out the kind of the noun and second noun@> =
	anl_item *item = ActionNameLists::first_item(ap->action_list);
	if ((item) && (item->action_listed)) {
		kind_of_noun = ActionSemantics::kind_of_noun(item->action_listed);
		if (kind_of_noun == NULL) kind_of_noun = K_object;
		kind_of_second = ActionSemantics::kind_of_second(item->action_listed);
		if (kind_of_second == NULL) kind_of_second = K_object;
	}

@ The macro |CPMC_NEEDED| is a shorthand within this function (and in plugin
functions extending it) to specify that this particular pattern match will
need the clause |C|, which should be one of the |*_CPMC| values. |A| is then
the associated |ap_clause|: see //if: Action Pattern Clauses//.

The |MAX_CPM_CLAUSES| is not currently possible to reach, since the same CPMC
is never used twice when matching the same pattern, and there are nowhere near
256 different CPMCs.

@d MAX_CPM_CLAUSES 256

@d CPMC_NEEDED(C, A) {
	if (cpm_count >= MAX_CPM_CLAUSES) internal_error("action pattern grossly overcomplex");
	needed[cpm_count] = C;
	needed_apoc[cpm_count] = A;
	cpm_count++;
}

@ Some APs have a much simpler parametric form: see //if: Action Patterns//.
Those have just one parameter and just one clause applies; but most of the
time we deal with action-related APs, which can be very complex.

@<Work out what clauses will be needed@> =
	@<Test the parameter@>;

	int actor_is_player = FALSE;
	if (actorless == FALSE) @<Test some actor-related considerations@>;
	@<Test the choice of action@>;
	@<Test the noun@>;
	@<Test the second noun@>;
	@<Test the location@>;
	@<Test the presence of something@>;
	@<Test action-specific optional clauses specified by the source text@>;
	@<Ask the plugins if they want other tests added@>;
	@<Test the when condition@>;

@h In actor-considering mode only.
The semantics of who the actor is seem straightforward to authors of Inform
source text, but they are actually quite difficult to explain; the code has
a tendendy to fill up with double-negatives. Still, here goes.

@<Test some actor-related considerations@> =
	int test_requester = TRUE;
	if (APClauses::actor_is_anyone_except_player(ap) == FALSE) {
		actor_is_player = TRUE;
		@<Detect if the actor is actually the player after all@>;
		if (actor_is_player) @<Require actor to be the player@>
		else @<Require actor to not be the player@>;
	}
	if (test_requester) @<Test requester@>;

@ A pattern not mentioning any actor is implicitly assuming the player is the
actor: "painting the watercolour", for example. But, generally speaking, if the
action pattern does specifies an actor, then it will not be the player: "Uncle
Swithin riding the carriage", for example, clearly says that "Uncle Swithin" is
the actor. But we must make an exception for "the player riding the carriage".

@<Detect if the actor is actually the player after all@> =
	parse_node *spec = APClauses::spec(ap, ACTOR_AP_CLAUSE);
	if (spec) {
		actor_is_player = FALSE;
		nonlocal_variable *var = Lvalues::get_nonlocal_variable_if_any(spec);
		if ((var) && (var == player_VAR)) actor_is_player = TRUE;
		instance *I = Rvalues::to_object_instance(spec);
		if ((I) && (I == I_yourself)) actor_is_player = TRUE;
	}

@ For example, "

@<Require actor to not be the player@> =
	CPMC_NEEDED(ACTOR_IS_NOT_PLAYER_CPMC, NULL);
	if (APClauses::spec(ap, ACTOR_AP_CLAUSE))
		CPMC_NEEDED(ACTOR_MATCHES_CPMC, NULL);

@ It would do no harm to leave |test_requester| true, but would lead to a
redundant check being compiled.

@<Require actor to be the player@> =
	CPMC_NEEDED(ACTOR_IS_PLAYER_CPMC, NULL);
	test_requester = FALSE;

@ An action pattern such as "Fred asking Barney to look" is a request, and such
patterns are marked as such. Here we test that the current action is a request
if the pattern is, and also that it isn't if the pattern isn't.

@<Test requester@> =
	if (APClauses::is_request(ap)) {
		CPMC_NEEDED(REQUESTER_EXISTS_CPMC, NULL);
	} else {
		CPMC_NEEDED(REQUESTER_DOES_NOT_EXIST_CPMC, NULL);
	}

@h In both modes.

@<Test the parameter@> =
	if (APClauses::spec(ap, PARAMETRIC_AP_CLAUSE))
		CPMC_NEEDED(PARAMETER_MATCHES_CPMC, NULL);

@ There's an optimisation here. Some rules with premisses like "After dropping
something" are auto-filed into rulebooks tied to individual actions -- in this
case, the "after dropping rulebook". When testing that premiss, which is an
action pattern match, it would be redundant to test that the action is "dropping",
because this can be proved from the context; so we skip this test.

@<Test the choice of action@> =
	if ((ap->action_list) && (ActionNameLists::testing(ap->action_list)))
		CPMC_NEEDED(ACTION_MATCHES_CPMC, NULL);

@ In the case where no action is specified, but the noun is -- for example,
"doing something with a container" -- we need to check that it is an object
which is not "nothing". The slightly odd practice of the command parser is
such that the way to do with is |(noun) && (noun == inp1)|.

@<Test the noun@> =
	if (APClauses::spec(ap, NOUN_AP_CLAUSE)) {
		if (ap->action_list == NULL) {
			CPMC_NEEDED(NOUN_EXISTS_CPMC, NULL);
			CPMC_NEEDED(NOUN_IS_INP1_CPMC, NULL);
		}
		if (Kinds::Behaviour::is_object(kind_of_noun)) {
			CPMC_NEEDED(NOUN_MATCHES_AS_OBJECT_CPMC, NULL);
		} else {
			CPMC_NEEDED(NOUN_MATCHES_AS_VALUE_CPMC, NULL);
		}
	}

@<Test the second noun@> =
	if (APClauses::spec(ap, SECOND_AP_CLAUSE)) {
		if (ap->action_list == NULL) {
			CPMC_NEEDED(SECOND_EXISTS_CPMC, NULL);
			CPMC_NEEDED(SECOND_IS_INP2_CPMC, NULL);
		}
		if (Kinds::Behaviour::is_object(kind_of_second)) {
			CPMC_NEEDED(SECOND_MATCHES_AS_OBJECT_CPMC, NULL);
		} else {
			CPMC_NEEDED(SECOND_MATCHES_AS_VALUE_CPMC, NULL);
		}
	}

@ The meaning of "...in the Observatory" depends on who the actor is, because
that is the only practical way of finding out where the action is taking place.

@<Test the location@> =
	if (APClauses::spec(ap, IN_AP_CLAUSE)) {
		if (actor_is_player == TRUE) {
			CPMC_NEEDED(PLAYER_LOCATION_MATCHES_CPMC, NULL);
		} else {
			CPMC_NEEDED(ACTOR_IS_SOMEWHERE_CPMC, NULL);
			CPMC_NEEDED(ACTOR_LOCATION_MATCHES_CPMC, NULL);
		}
	}

@ The "...in the presence of X" clause is compiled three different ways, for
efficiency. Examples of these three cases are:
(*) "drinking the champagne in the presence of Sabrina";
(*) "drinking the champagne in the presence of a woman (called the ingenue)";
(*) "drinking the champagne in the presence of a woman".

@<Test the presence of something@> =
	parse_node *whom = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	if (whom) {
		instance *to_be_present = Specifications::object_exactly_described_if_any(whom);
		if (to_be_present) {
			CPMC_NEEDED(PRESENCE_OF_MATCHES_CPMC, NULL);
			CPMC_NEEDED(PRESENCE_OF_IN_SCOPE_CPMC, NULL);
		} else if (Wordings::nonempty(Descriptions::get_calling(whom))) {
			CPMC_NEEDED(LOOP_OVER_SCOPE_CALLING_CPMC, NULL);
		} else {
			CPMC_NEEDED(LOOP_OVER_SCOPE_NOT_CALLING_CPMC, NULL);
		}
	}

@ For example, "going from the Dining Room" uses the optional "from ..." clause
attached to the "going" action, so that would be picked up here:

@<Test action-specific optional clauses specified by the source text@> =
	LOOP_OVER_AP_CLAUSES(apoc, ap)
		if ((apoc->stv_to_match) && (apoc->clause_spec))
			CPMC_NEEDED(OPTIONAL_CLAUSE_CPMC, apoc);

@ And this is where, for example, //Matching Going Action Patterns// adds other
tests needed to reconcile the going variables, but which are not explicitly called
for by the source text:

@<Ask the plugins if they want other tests added@> =
	PluginCalls::set_pattern_match_requirements(ap, &cpm_count, needed, needed_apoc);

@ And finally, a stipulation that an arbitrary condition must hold.

@<Test the when condition@> =
	if (APClauses::spec(ap, WHEN_AP_CLAUSE)) {
		CPMC_NEEDED(SET_SELF_TO_ACTOR_CPMC, NULL);
		CPMC_NEEDED(WHEN_CONDITION_HOLDS_CPMC, NULL);
	}

@h Compiling the tests.
We group the tests into four "ranges": thus range 0 is all tests with CPMC number
in the range |ACTOR_IS_PLAYER_CPMC <= N <= ACTOR_MATCHES_CPMC|, and so on.
|count[R]| is the number of tests to perform in the range |R|.

@d CPMC_RANGE(ix, F, T) {
	ranges_from[ix] = F; ranges_to[ix] = T; count[ix] = 0;
	for (int i=0; i<cpm_count; i++)
		if ((needed[i] >= F) && (needed[i] <= T))
			count[ix]++;
}

@ For what is in these ranges, see the definitions above.

@<Compile the condition from these instructions@> =
	int ranges_from[4], ranges_to[4], count[4];
	CPMC_RANGE(ACTOR_CPMCRANGE,   ACTOR_IS_PLAYER_CPMC,   ACTOR_MATCHES_CPMC);
	CPMC_RANGE(ACTION_CPMCRANGE,  ACTION_MATCHES_CPMC,    ACTION_MATCHES_CPMC);
	CPMC_RANGE(DETAILS_CPMCRANGE, NOUN_EXISTS_CPMC,       NO_DEFINED_CPMC_VALUES);
	CPMC_RANGE(WHEN_CPMCRANGE,    SET_SELF_TO_ACTOR_CPMC, WHEN_CONDITION_HOLDS_CPMC);

	CompileConditions::begin();

	if (ActionNameLists::listwise_negated(ap->action_list))
		@<Listwise negated case@>
	else
		@<Listwise positive case@>;

	CompileConditions::end();

@ This is the easier case: all four ranges of condition must be true, and so
we compile code equivalent to |ACTION and ACTOR and DETAILS and WHEN|. We
do it in that order for two reasons: firstly, wrong actions are the commonest
reasom actions fail to match, and the ACTION tests are quick, so it's efficient
to test that first. (The ACTOR tests are also quick, but usually pass.) Secondly,
some DETAILS tests will compile non-typesafe code in cases where ACTION would
not pass, so DETAILS must be compiled after ACTION. Finally, we put WHEN at
the back because it compiles an arbitrary condition, and that could be
something quite slow to perform: so we check it only if we definitely need
to know the result.

Note that we must never compile nothing at all: if there are no clauses
we still have to compile |true|, to ensure that every action will match. 

@<Listwise positive case@> =
	int downs = 0;
	if (count[ACTION_CPMCRANGE] > 0) {
		if (count[ACTOR_CPMCRANGE] + count[DETAILS_CPMCRANGE] +
			count[WHEN_CPMCRANGE] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		int range = ACTION_CPMCRANGE;
		@<Compile a subcondition for this range@>;
	}
	if (count[ACTOR_CPMCRANGE] > 0) {
		if (count[DETAILS_CPMCRANGE] + count[WHEN_CPMCRANGE] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		int range = ACTOR_CPMCRANGE;
		@<Compile a subcondition for this range@>;
	}
	if (count[DETAILS_CPMCRANGE] > 0) {
		if (count[WHEN_CPMCRANGE] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		int range = DETAILS_CPMCRANGE;
		@<Compile a subcondition for this range@>;
	}
	if (count[WHEN_CPMCRANGE] > 0) {
		int range = WHEN_CPMCRANGE;
		@<Compile a subcondition for this range@>;
	}
	if (count[ACTOR_CPMCRANGE] + count[ACTION_CPMCRANGE] +
		count[DETAILS_CPMCRANGE] + count[WHEN_CPMCRANGE] == 0) {
		EmitCode::val_true();
	}
	while (downs > 0) { EmitCode::up(); downs--; }

@ A listwise negated pattern is something like "doing something other than
examining the box", which matches any action except "examining the box". It
might seem that this could be negated just as the negation of the positive
case, but that overlookz the hidden clauses about who the actor is, whether
the action is a request, and so on -- the |ACTOR_CPMCRANGE| -- and any
condition supplied -- the |WHEN_CPMCRANGE|.

For example, "doing something other than examining the box when the red door is
open" matches "dropping the box" only if the door is open at the time.

So this compiles as |ACTOR and (not (ACTION and DETAILS)) and WHEN|.

@<Listwise negated case@> =
	if (count[ACTOR_CPMCRANGE] > 0) {
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			int range = ACTOR_CPMCRANGE;
			@<Compile a subcondition for this range@>;
	}
	if (count[WHEN_CPMCRANGE] > 0) {
		EmitCode::inv(AND_BIP);
		EmitCode::down();
	}
	EmitCode::inv(NOT_BIP);
	EmitCode::down();
	if ((count[ACTION_CPMCRANGE] == 0) && (count[DETAILS_CPMCRANGE] == 0)) {
		EmitCode::val_false();
	} else {
		if ((count[ACTION_CPMCRANGE] > 0) && (count[DETAILS_CPMCRANGE] > 0)) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
		}
		if (count[ACTION_CPMCRANGE] > 0) {
			int range = ACTION_CPMCRANGE;
			@<Compile a subcondition for this range@>;
		}
		if (count[DETAILS_CPMCRANGE] > 0) {
			int range = DETAILS_CPMCRANGE;
			@<Compile a subcondition for this range@>;
		}
		if ((count[ACTION_CPMCRANGE] > 0) && (count[DETAILS_CPMCRANGE] > 0))
			EmitCode::up();
	}
	EmitCode::up();
	if (count[WHEN_CPMCRANGE] > 0) {
		int range = WHEN_CPMCRANGE;
		@<Compile a subcondition for this range@>;
		EmitCode::up();
	}
	if (count[ACTOR_CPMCRANGE] > 0) EmitCode::up();

@ So here we compile all the clauses in the range |range|. If no tests are needed
then no code would be compiled, which is not in fact a valid condition; but
this never happens, because the code above arranges that we never come here unless
there is at least one test in the range to be performed.

The range is then compiled to a simple conjunction of the tests needed, in
ascending numerical order of CPMC.

@<Compile a subcondition for this range@> =
	if (count[range] == 0) internal_error("logic error in AP matcher");
	int downs = 0;
	for (int i=0, done=0; i<cpm_count; i++) {
		int cpmc = needed[i];
		if ((cpmc >= ranges_from[range]) && (cpmc <= ranges_to[range])) {
			done++;
			if (done < count[range]) {
				EmitCode::inv(AND_BIP);
				EmitCode::down(); downs++;
			}
			ap_clause *apoc = needed_apoc[i];
			@<Compile a subcondition for this CPMC@>;
		}
	}
	while (downs > 0) { EmitCode::up(); downs--; }

@ And finally we compile a single clause as a condition. We first ask a plugin
if it wants to do that for us (as it must, for any non-standard CPMCs it has created);
and otherwise we do our own thing.

@<Compile a subcondition for this CPMC@> =
	if (PluginCalls::compile_pattern_match_clause(ap, cpmc) == FALSE)
	switch (cpmc) {
	
		/* The ACTOR range */
		
		case ACTOR_IS_PLAYER_CPMC:          @<Compile ACTOR_IS_PLAYER_CPMC test@>; break;
		case ACTOR_IS_NOT_PLAYER_CPMC:      @<Compile ACTOR_IS_NOT_PLAYER_CPMC test@>; break;
		case REQUESTER_EXISTS_CPMC:         @<Compile REQUESTER_EXISTS_CPMC test@>; break;
		case REQUESTER_DOES_NOT_EXIST_CPMC: @<Compile REQUESTER_DOES_NOT_EXIST_CPMC test@>; break;
		case ACTOR_MATCHES_CPMC:            @<Compile ACTOR_MATCHES_CPMC test@>; break;

		/* The ACTION range */
		
		case ACTION_MATCHES_CPMC:           @<Compile ACTION_MATCHES_CPMC test@>; break;

		/* The DETAILS range (but see plugins for extra ones) */
		
		case NOUN_EXISTS_CPMC:              @<Compile NOUN_EXISTS_CPMC test@>; break;
		case NOUN_IS_INP1_CPMC:             @<Compile NOUN_IS_INP1_CPMC test@>; break;
		case NOUN_MATCHES_AS_OBJECT_CPMC:   @<Compile NOUN_MATCHES_AS_OBJECT_CPMC test@>; break;
		case NOUN_MATCHES_AS_VALUE_CPMC:    @<Compile NOUN_MATCHES_AS_VALUE_CPMC test@>; break;

		case SECOND_EXISTS_CPMC:            @<Compile SECOND_EXISTS_CPMC test@>; break;
		case SECOND_IS_INP2_CPMC:           @<Compile SECOND_IS_INP2_CPMC test@>; break;
		case SECOND_MATCHES_AS_OBJECT_CPMC: @<Compile SECOND_MATCHES_AS_OBJECT_CPMC test@>; break;
		case SECOND_MATCHES_AS_VALUE_CPMC:  @<Compile SECOND_MATCHES_AS_VALUE_CPMC test@>; break;
			
		case PLAYER_LOCATION_MATCHES_CPMC:  @<Compile PLAYER_LOCATION_MATCHES_CPMC test@>; break;
		case ACTOR_IS_SOMEWHERE_CPMC:       @<Compile ACTOR_IS_SOMEWHERE_CPMC test@>; break;
		case ACTOR_LOCATION_MATCHES_CPMC:   @<Compile ACTOR_LOCATION_MATCHES_CPMC test@>; break;

		case PARAMETER_MATCHES_CPMC:        @<Compile PARAMETER_MATCHES_CPMC test@>; break;

		case OPTIONAL_CLAUSE_CPMC:          @<Compile OPTIONAL_CLAUSE_CPMC test@>; break;

		case PRESENCE_OF_MATCHES_CPMC:      @<Compile PRESENCE_OF_MATCHES_CPMC test@>; break;
		case PRESENCE_OF_IN_SCOPE_CPMC:     @<Compile PRESENCE_OF_IN_SCOPE_CPMC test@>; break;
		case LOOP_OVER_SCOPE_CALLING_CPMC:  @<Compile LOOP_OVER_SCOPE_CALLING_CPMC test@>; break;
		case LOOP_OVER_SCOPE_NOT_CALLING_CPMC: @<Compile LOOP_OVER_SCOPE_NOT_CALLING_CPMC test@>; break;

		/* The WHEN range */

		case SET_SELF_TO_ACTOR_CPMC:        @<Compile SET_SELF_TO_ACTOR_CPMC test@>; break;
		case WHEN_CONDITION_HOLDS_CPMC:     @<Compile WHEN_CONDITION_HOLDS_CPMC test@>; break;
	}

@h The ACTOR range of CPMCs.

@<Compile ACTOR_IS_PLAYER_CPMC test@> =
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
		EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
	EmitCode::up();

@<Compile ACTOR_IS_NOT_PLAYER_CPMC test@> =
	EmitCode::inv(NE_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
		EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
	EmitCode::up();

@<Compile REQUESTER_EXISTS_CPMC test@> =
	EmitCode::val_iname(K_object, Hierarchy::find(ACT_REQUESTER_HL));

@<Compile REQUESTER_DOES_NOT_EXIST_CPMC test@> =
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(ACT_REQUESTER_HL));
		EmitCode::val_number(0);
	EmitCode::up();

@<Compile ACTOR_MATCHES_CPMC test@> =
	RTActionPatterns::variable_matches_specification(Inter_actor_VAR,
		APClauses::spec(ap, ACTOR_AP_CLAUSE), K_object, FALSE);

@h The ACTION range of CPMCs.
Just one of these, but it's a doozy. Note that an action name list is essentially
a disjunction, i.e., a list of alternatives: "taking or dropping the box", for
example, features an action name list with |C == 2|.

@<Compile ACTION_MATCHES_CPMC test@> =
	action_name_list *head = ap->action_list;
	int C = ActionNameLists::length(head);
	if (C > 0) {
		LOGIF(ACTION_PATTERN_COMPILATION, "Emitting action name list: $L", head);

		int neg = ActionNameLists::itemwise_negated(head);
		if (neg) { EmitCode::inv(NOT_BIP); EmitCode::down(); }

		int N = 0, downs = 0;
		LOOP_THROUGH_ANL(L, head) {
			N++;
			if (N < C) { EmitCode::inv(OR_BIP); EmitCode::down(); downs++; }
			if (L->item.nap_listed) {
				EmitCode::inv(INDIRECT0_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value,
						RTNamedActionPatterns::test_fn_iname(L->item.nap_listed));
				EmitCode::up();
			} else {
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(ACTION_HL));
					EmitCode::val_iname(K_value,
						RTActions::double_sharp(L->item.action_listed));
				EmitCode::up();
			}
		}
		while (downs > 0) { EmitCode::up(); downs--; }

		if (neg) EmitCode::up();
	} else {
		EmitCode::val_true(); /* should never happen, but would be correct if it did */
	}

@h The DETAILS range of CPMCs.
For the frankly oddball way that the runtime variables |noun|, |inp1| and
|parsed_number| are juggled inside the parser, see //CommandParserKit//. Here
it's enough to know that
(a) for EXAMINE BOX, |noun| and |inp1| would be the box, and |parsed_number|
would have no meaning, but
(b) for TYPE 246, |inp1| would be 1, |parsed_number| would be 246, and |noun|
would be |nothing|.

@<Compile NOUN_EXISTS_CPMC test@> =
	EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
			
@<Compile NOUN_IS_INP1_CPMC test@> =
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
		EmitCode::val_iname(K_object, Hierarchy::find(INP1_HL));
	EmitCode::up();

@<Compile NOUN_MATCHES_AS_OBJECT_CPMC test@> =
	RTActionPatterns::variable_matches_specification(Inter_noun_VAR,
		APClauses::spec(ap, NOUN_AP_CLAUSE), kind_of_noun, FALSE);

@<Compile NOUN_MATCHES_AS_VALUE_CPMC test@> =
	RTActionPatterns::variable_matches_specification(
		TemporaryVariables::from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_noun),
		APClauses::spec(ap, NOUN_AP_CLAUSE), kind_of_noun, FALSE);

@ And similarly for the second noun, but with |second| and |inp2| in place of
|noun| and |inp1|.

@<Compile SECOND_EXISTS_CPMC test@> =
	EmitCode::val_iname(K_object, Hierarchy::find(SECOND_HL));

@<Compile SECOND_IS_INP2_CPMC test@> =
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_object, Hierarchy::find(SECOND_HL));
		EmitCode::val_iname(K_object, Hierarchy::find(INP2_HL));
	EmitCode::up();

@<Compile SECOND_MATCHES_AS_OBJECT_CPMC test@> =
	RTActionPatterns::variable_matches_specification(Inter_second_noun_VAR,
		APClauses::spec(ap, SECOND_AP_CLAUSE), kind_of_second, FALSE);
			
@<Compile SECOND_MATCHES_AS_VALUE_CPMC test@> =
	RTActionPatterns::variable_matches_specification(
		TemporaryVariables::from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_second),
		APClauses::spec(ap, SECOND_AP_CLAUSE), kind_of_second, FALSE);

@ An action takes place in the location of the actor: we will have no spooky
action at a distance here. If the actor can be proved to be the player, then
this test is sufficient:

@<Compile PLAYER_LOCATION_MATCHES_CPMC test@> =
	RTActionPatterns::variable_matches_specification(real_location_VAR,
		APClauses::spec(ap, IN_AP_CLAUSE), K_object, TRUE);

@ But if the actor might not be the player, we first test this condition,
which is true if and only if the actor is somewhere in play. (In particular,
an actor removed from the object tree because the character has, say, died,
can never have a location. But such an actor cannot be acting anyway.) Note
the side-effect of setting the |actor_location| variable...

@<Compile ACTOR_IS_SOMEWHERE_CPMC test@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_object, Hierarchy::find(ACTOR_LOCATION_HL));
		EmitCode::call(Hierarchy::find(LOCATIONOF_HL));
		EmitCode::down();
			EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
		EmitCode::up();
	EmitCode::up();

@ ...when is then used in this pattern match:

@<Compile ACTOR_LOCATION_MATCHES_CPMC test@> =
	RTActionPatterns::variable_matches_specification(actor_location_VAR,
		APClauses::spec(ap, IN_AP_CLAUSE), K_object, TRUE);

@ With "in the presence of" clauses, it is always the player's presence that
is meant, not the actor's: i.e., "in the presence of X" means that the player
must be near to X, not that the actor must be. This is questionable, but is
needed because the command parser is unable to calculate scope properly for
actors other than the player.

Even so, there are three cases. The easy one is when we know exactly who or
what we are to be in the presence of. Even so, that comes in two stages;
first, any conditions must be met. So "in the presence of an angry Mrs Sprout"
would test for the anger here.

@<Compile PRESENCE_OF_MATCHES_CPMC test@> =
	parse_node *whom = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	instance *to_be_present = Specifications::object_exactly_described_if_any(whom);
	RTActionPatterns::variable_matches_specification(
		TemporaryVariables::from_iname(RTInstances::value_iname(to_be_present), K_object),
		whom, K_object, FALSE);

@ And secondly, we test whether Mrs Sprout is nearby.

@<Compile PRESENCE_OF_IN_SCOPE_CPMC test@> =
	parse_node *whom = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	instance *to_be_present = Specifications::object_exactly_described_if_any(whom);
	EmitCode::call(Hierarchy::find(TESTSCOPE_HL));
	EmitCode::down();
		EmitCode::val_iname(K_value, RTInstances::value_iname(to_be_present));
		EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
	EmitCode::up();

@ The second case is the hardest: "in the presence of an angry person (called
the wrathful one)" must not only test if anyone nearby is angry, but also set
a new variable, "the wrathful one", to that person.

Note that we call //runtime: Looping Over Scope// to trigger the compilation of
a helper function, which will be placed in the same enclosure as the function
we are currently compiling.

@<Compile LOOP_OVER_SCOPE_CALLING_CPMC test@> =
	parse_node *whom = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	loop_over_scope *los = LoopingOverScope::new(whom);
	wording PC = Descriptions::get_calling(whom);
	local_variable *lvar = LocalVariables::ensure_calling(PC,
		Specifications::to_kind(whom));
	inter_symbol *lvar_s = LocalVariables::declare(lvar);
	EmitCode::inv(SEQUENTIAL_BIP);
	EmitCode::down();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(LOS_RV_HL));
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::call(Hierarchy::find(LOOPOVERSCOPE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, los->los_iname);
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, lvar_s);
				EmitCode::val_iname(K_value, Hierarchy::find(LOS_RV_HL));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@ The third case is slightly easier: "in the presence of an angry person", say,
with no variable to set.

@<Compile LOOP_OVER_SCOPE_NOT_CALLING_CPMC test@> =
	parse_node *whom = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	loop_over_scope *los = LoopingOverScope::new(whom);
	EmitCode::inv(SEQUENTIAL_BIP);
	EmitCode::down();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(LOS_RV_HL));
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::call(Hierarchy::find(LOOPOVERSCOPE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, los->los_iname);
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
			EmitCode::up();
			EmitCode::val_iname(K_value, Hierarchy::find(LOS_RV_HL));
		EmitCode::up();
	EmitCode::up();

@ The shenanigans here are because the "parameter object" variable, which is
used only when we are really parsing the premiss of an activity-based rule and
does not arise in genuine action patterns, is typeless at runtime: or rather,
it has a different meaning depending on the activity currently being processed,
and that means it is only typesafe within activity processing.

That makes it tricky to represent with a |nonlocal_variable|, which in principle
has a single kind for its whole existence. So here we temporarily amend the kind
of that variable to the kind we have deduced from the activity context.

@<Compile PARAMETER_MATCHES_CPMC test@> =
	nonlocal_variable *par_var = NonlocalVariables::parameter_object_variable();
	kind *saved_kind = NonlocalVariables::kind(par_var);
	NonlocalVariables::set_kind(par_var, ap->parameter_kind);
	RTActionPatterns::variable_matches_specification(par_var,
		APClauses::spec(ap, PARAMETRIC_AP_CLAUSE), ap->parameter_kind, FALSE);
	NonlocalVariables::set_kind(par_var, saved_kind);

@<Compile OPTIONAL_CLAUSE_CPMC test@> =
	kind *K = SharedVariables::get_kind(apoc->stv_to_match);
	RTActionPatterns::variable_matches_specification(
		TemporaryVariables::from_existing_variable(apoc->stv_to_match->underlying_var, K),
		apoc->clause_spec, K, APClauses::opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT));

@h The WHEN range of CPMCs.
This test is always true (even if |actor| is 0), but is executed for its side-effect
of setting the |self| pseudovariable, so that it will have the right contents when
the WHEN condition is evaluated.

@<Compile SET_SELF_TO_ACTOR_CPMC test@> =
	EmitCode::inv(SEQUENTIAL_BIP);
	EmitCode::down();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
		EmitCode::up();
		EmitCode::val_true();
	EmitCode::up();

@ And last but not least, despite its brief look, the test which may be the
slowest of all, and is therefore performed last:

@<Compile WHEN_CONDITION_HOLDS_CPMC test@> =
	CompileValues::to_code_val(APClauses::spec(ap, WHEN_AP_CLAUSE));

@h Matching variables.
Many of the clauses above amount to testing whether a given variable holds
an object (or other value) matching some specification: the following function
compiles code to test whether or not it does.

=
void RTActionPatterns::variable_matches_specification(nonlocal_variable *I6_global_variable,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	if (I6_global_variable == NULL) internal_error("no variable");
	if (spec == NULL) internal_error("no specification");

	parse_node *val = Lvalues::new_actual_NONLOCAL_VARIABLE(I6_global_variable);
	int is_parameter = FALSE;
	if (I6_global_variable == NonlocalVariables::parameter_object_variable())
		is_parameter = TRUE;
	RTActionPatterns::value_matches_specification(
		val, is_parameter, spec, verify_as_kind, adapt_region);
}

@h Matching values.
The serious work is done here. Note that this function is also called from
//runtime: Looping Over Scope//, because that essentially was a way to
defer the same matching process into a helper function.

The value |val| will in practice always be a local or global variable.

If the match makes a calling, as in "an open door (called the way out)", the
following compiles to the equivalent of |(way out = V, open-door(V))|; the first
clause has side effect of setting the "way out" variable, the second actually
performs the condition. It would then be unsafe to use the value of "way out"
if the condition were false, but Inform manages the scope of this variable so
that it cannot be referred to in that case.

=
void RTActionPatterns::value_matches_specification(parse_node *val, int is_parameter,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	if (val == NULL) internal_error("no variable");
	LOGIF(ACTION_PATTERN_COMPILATION, "[Value $P matches $P]\n", val, spec);

	@<Make sure the specification is known and definite@>;

	wording C = Descriptions::get_calling(spec);
	if (Wordings::nonempty(C)) {
		local_variable *lvar =
			LocalVariables::ensure_calling(C, Specifications::to_kind(spec));
		CompileConditions::add_calling(lvar);
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				inter_symbol *lvar_s = LocalVariables::declare(lvar);
				EmitCode::ref_symbol(K_value, lvar_s);
				CompileValues::to_code_val(val);
			EmitCode::up();
	}
	@<Match the value@>;
	if (Wordings::nonempty(C)) {
		EmitCode::up();
	}
}

@<Make sure the specification is known and definite@> =
	if (spec == NULL) internal_error("no specification");
	if (Node::is(spec, UNKNOWN_NT)) {
		if (problem_count == 0) internal_error("AP clause specification unknown");
		return; /* for error recovery only */
	}
	if (Kinds::Behaviour::definite(Specifications::to_kind(spec)) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_APClauseIndefinite),
			"that action seems to involve a value which is unclear about its kind",
			"and that's not allowed. For example, you're not allowed to just say 'Instead "
			"of taking a value: ...' because the taking action applies to objects; the "
			"vaguest you're allowed to be is 'Instead of taking an object: ...'.");
		return;
	}

@<Match the value@> =
	int compiled_ad_hoc = FALSE;
	if (Lvalues::is_lvalue(spec)) {
		if (Node::is(spec, TABLE_ENTRY_NT)) {
			@<Handle table entries ad-hoc@>;
			compiled_ad_hoc = TRUE;
		}
	} else if (Rvalues::is_rvalue(spec)) {
		if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec, K_understanding))) {
			@<Handle a constant snippet ad-hoc@>;
			compiled_ad_hoc = TRUE;
		}
		if ((is_parameter == FALSE) && (Rvalues::is_object(spec))) {
			instance *I = Specifications::object_exactly_described_if_any(spec);
			if ((I) && (Instances::of_kind(I, K_region))) {
				if (adapt_region) {
					@<Handle a regional containment test ad-hoc@>;
					compiled_ad_hoc = TRUE;
				}
			}
		}
	} else if (Specifications::is_description(spec)) {
		if ((is_parameter == FALSE) &&
			(Descriptions::to_instance(spec)) &&
			(adapt_region) &&
			(Instances::of_kind(Descriptions::to_instance(spec), K_region))) {
			@<Handle a regional containment test ad-hoc@>;
			compiled_ad_hoc = TRUE;
		}
	}
	if (compiled_ad_hoc) {
		LOGIF(ACTION_PATTERN_COMPILATION, "[Value-matcher compiles ad-hoc code]\n");
	} else {
		@<Match as a proposition@>;
	}

@ So there are four different implementations -- three exceptions, then one
general case.

The first handles, say, "a Queen listed in the Table of Monarchs".

@<Handle table entries ad-hoc@> =
	if (Node::no_children(spec) != 2) internal_error("MPE with bad no of args");
	LocalVariables::add_table_lookup();
	local_variable *ct_0_lv = LocalVariables::find_internal(I"ct_0");
	inter_symbol *ct_0_s = LocalVariables::declare(ct_0_lv);
	local_variable *ct_1_lv = LocalVariables::find_internal(I"ct_1");
	inter_symbol *ct_1_s = LocalVariables::declare(ct_1_lv);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, ct_1_s);
		EmitCode::call(Hierarchy::find(EXISTSTABLEROWCORR_HL));
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, ct_0_s);
				CompileValues::to_code_val(spec->down->next);
			EmitCode::up();
			CompileValues::to_code_val(spec->down);
			CompileValues::to_code_val(val);
		EmitCode::up();
	EmitCode::up();

@ The first case here might handle the "anything" in "asking Fred about anything";
second "asking Fred about "scooby snacks"".

@<Handle a constant snippet ad-hoc@> =
	if ((<understanding-action-irregular-operand>(Node::get_text(spec))) && (<<r>> == TRUE)) {
		EmitCode::val_true();
	} else {
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::inv(INDIRECT2_BIP);
			EmitCode::down();
				CompileValues::to_code_val(spec);
				EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_FROM_HL));
				EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_WORDS_HL));
			EmitCode::up();
			EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
		EmitCode::up();
	}

@ For some clauses, such as "going from R" or "in R", we want to allow for "R"
to be allowed to be a region and not just a room. But only for certain clauses,
so this is used only when the function was called with |adapt_region| set.

@<Handle a regional containment test ad-hoc@> =
	EmitCode::call(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
	EmitCode::down();
		CompileValues::to_code_val(val);
		CompileValues::to_code_val(spec);
	EmitCode::up();

@<Match as a proposition@> =
	pcalc_prop *prop = NULL;
	if (Specifications::is_description(spec)) prop = Descriptions::to_proposition(spec);
	if (prop == NULL) prop = SentencePropositions::from_spec(spec);
	if (prop == NULL) internal_error("unable to force proposition");
	if (verify_as_kind) {
		prop = Propositions::concatenate(prop,
			KindPredicates::new_atom(verify_as_kind, Terms::new_variable(0)));
		CompilePropositions::verify_descriptive(prop,
			"an action or activity to apply to things matching a given description", spec);
	}
	LOGIF(ACTION_PATTERN_COMPILATION, "[Value-matcher faces proposition: $D]\n", prop);
	TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
	CompilePropositions::to_test_as_condition(val, prop);
