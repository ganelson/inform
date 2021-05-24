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

@e ACTOR_IS_PLAYER_CPMC from 1
@e ACTOR_ISNT_PLAYER_CPMC
@e REQUESTER_EXISTS_CPMC
@e REQUESTER_DOESNT_EXIST_CPMC
@e ACTOR_MATCHES_CPMC
@e ACTION_MATCHES_CPMC
@e SET_SELF_TO_ACTOR_CPMC
@e WHEN_CONDITION_HOLDS_CPMC
@e NOUN_EXISTS_CPMC
@e NOUN_IS_INP1_CPMC
@e SECOND_EXISTS_CPMC
@e SECOND_IS_INP2_CPMC
@e NOUN_MATCHES_AS_OBJECT_CPMC
@e NOUN_MATCHES_AS_VALUE_CPMC
@e SECOND_MATCHES_AS_OBJECT_CPMC
@e SECOND_MATCHES_AS_VALUE_CPMC
@e PLAYER_LOCATION_MATCHES_CPMC
@e ACTOR_IN_RIGHT_PLACE_CPMC
@e ACTOR_LOCATION_MATCHES_CPMC
@e PARAMETER_MATCHES_CPMC
@e OPTIONAL_CLAUSE_CPMC
@e PRESENCE_OF_MATCHES_CPMC
@e PRESENCE_OF_IN_SCOPE_CPMC
@e LOOP_OVER_SCOPE_WITH_CALLING_CPMC
@e LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC

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
	CPMC_NEEDED(ACTOR_ISNT_PLAYER_CPMC, NULL);
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
		CPMC_NEEDED(REQUESTER_DOESNT_EXIST_CPMC, NULL);
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
			CPMC_NEEDED(ACTOR_IN_RIGHT_PLACE_CPMC, NULL);
			CPMC_NEEDED(ACTOR_LOCATION_MATCHES_CPMC, NULL);
		}
	}

@ The "...in the presence of X" clause is compiled three different ways, for
efficiency. Examples of these three cases are:
(*) "drinking the champagne in the presence of Sabrina";
(*) "drinking the champagne in the presence of a woman (called the ingenue)";
(*) "drinking the champagne in the presence of a woman".

@<Test the presence of something@> =
	parse_node *what = APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE);
	if (what) {
		instance *to_be_present = Specifications::object_exactly_described_if_any(what);
		if (to_be_present) {
			CPMC_NEEDED(PRESENCE_OF_MATCHES_CPMC, NULL);
			CPMC_NEEDED(PRESENCE_OF_IN_SCOPE_CPMC, NULL);
		} else if (Wordings::nonempty(Descriptions::get_calling(what))) {
			CPMC_NEEDED(LOOP_OVER_SCOPE_WITH_CALLING_CPMC, NULL);
		} else {
			CPMC_NEEDED(LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC, NULL);
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

@d CPMC_RANGE(ix, F, T) {
	ranges_from[ix] = F; ranges_to[ix] = T; ranges_count[ix] = 0;
	for (int i=0; i<cpm_count; i++)
		if ((needed[i] >= F) && (needed[i] <= T))
			ranges_count[ix]++;
}

@ Note that we must never compile nothing at all: if there are no clauses
and no negation, we still have to compile |true|, to ensure that every action
will match.

@<Compile the condition from these instructions@> =
	int ranges_from[4], ranges_to[4], ranges_count[4];
	CPMC_RANGE(0, ACTOR_IS_PLAYER_CPMC, ACTOR_MATCHES_CPMC);
	CPMC_RANGE(1, ACTION_MATCHES_CPMC, ACTION_MATCHES_CPMC);
	CPMC_RANGE(2, NOUN_EXISTS_CPMC, NO_DEFINED_CPMC_VALUES);
	CPMC_RANGE(3, SET_SELF_TO_ACTOR_CPMC, WHEN_CONDITION_HOLDS_CPMC);

	int range_to_compile = 0;
	CompileConditions::begin();

	if (ActionNameLists::listwise_negated(ap->action_list))
		@<Listwise negated case@>
	else
		@<Not listwise negated case@>;

	if ((ranges_count[0] + ranges_count[1] + ranges_count[2] + ranges_count[3] == 0) &&
		(ActionNameLists::listwise_negated(ap->action_list) == FALSE)) {
		EmitCode::val_true();
	}
	CompileConditions::end();

@<Listwise negated case@> =
	if (ranges_count[0] > 0) {
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			range_to_compile = 0;
			@<Emit CPM range@>;
	}
	if (ranges_count[3] > 0) {
		EmitCode::inv(AND_BIP);
		EmitCode::down();
	}
	EmitCode::inv(NOT_BIP);
	EmitCode::down();
	if ((ranges_count[1] == 0) && (ranges_count[2] == 0))
		EmitCode::val_false();
	else {
		if ((ranges_count[1] > 0) && (ranges_count[2] > 0)) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
		}
		if (ranges_count[1] > 0) {
			range_to_compile = 1;
			@<Emit CPM range@>;
		}
		if (ranges_count[2] > 0) {
			range_to_compile = 2;
			@<Emit CPM range@>;
		}
		if ((ranges_count[1] > 0) && (ranges_count[2] > 0)) EmitCode::up();
	}
	EmitCode::up();
	if (ranges_count[3] > 0) {
		range_to_compile = 3;
		@<Emit CPM range@>;
	}
	if (ranges_count[3] > 0) EmitCode::up();
	if (ranges_count[0] > 0) EmitCode::up();

@<Not listwise negated case@> =
	int downs = 0;
	if (ranges_count[1] > 0) {
		if (ranges_count[0]+ranges_count[2]+ranges_count[3] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		range_to_compile = 1;
		@<Emit CPM range@>;
	}
	if (ranges_count[0] > 0) {
		if (ranges_count[2]+ranges_count[3] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		range_to_compile = 0;
		@<Emit CPM range@>;
	}
	if (ranges_count[2] > 0) {
		if (ranges_count[3] > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down(); downs++;
		}
		range_to_compile = 2;
		@<Emit CPM range@>;
	}
	if (ranges_count[3] > 0) {
		range_to_compile = 3;
		@<Emit CPM range@>;
	}
	while (downs > 0) { EmitCode::up(); downs--; }

@ So here we compile all the clauses in the range |range_to_compile|, and there
is guaranteed to be at least one to compile.

@<Emit CPM range@> =
	int downs = 0;
	for (int i=0, done=0; i<cpm_count; i++) {
		int cpmc = needed[i];
		if ((cpmc >= ranges_from[range_to_compile]) && (cpmc <= ranges_to[range_to_compile])) {
			done++;
			if (done < ranges_count[range_to_compile]) {
				EmitCode::inv(AND_BIP);
				EmitCode::down(); downs++;
			}
			ap_clause *apoc = needed_apoc[i];
			@<Emit CPM condition piece@>;
		}
	}
	while (downs > 0) { EmitCode::up(); downs--; }

@ And finally we compile the actual clause. We first ask a plugin if it wants
to do that for us (as it must, for any non-standard CPMCs it has created);
and otherwise we do our own thing.

@<Emit CPM condition piece@> =
	if (PluginCalls::compile_pattern_match_clause(ap, cpmc) == FALSE)
	switch (cpmc) {
		case ACTOR_IS_PLAYER_CPMC:
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
			EmitCode::up();
			break;
		case ACTOR_ISNT_PLAYER_CPMC:
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
			EmitCode::up();
			break;
		case REQUESTER_EXISTS_CPMC:
			EmitCode::val_iname(K_object, Hierarchy::find(ACT_REQUESTER_HL));
			break;
		case REQUESTER_DOESNT_EXIST_CPMC:
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(ACT_REQUESTER_HL));
				EmitCode::val_number(0);
			EmitCode::up();
			break;
		case ACTOR_MATCHES_CPMC:
			RTActionPatterns::compile_pattern_match_clause(Inter_actor_VAR, APClauses::spec(ap, ACTOR_AP_CLAUSE), K_object, FALSE);
			break;
		case ACTION_MATCHES_CPMC:
			RTActionPatterns::compile_action_name_test(ap->action_list);
			break;
		case NOUN_EXISTS_CPMC:
			EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
			break;
		case NOUN_IS_INP1_CPMC:
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(INP1_HL));
			EmitCode::up();
			break;
		case SECOND_EXISTS_CPMC:
			EmitCode::val_iname(K_object, Hierarchy::find(SECOND_HL));
			break;
		case SECOND_IS_INP2_CPMC:
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SECOND_HL));
				EmitCode::val_iname(K_object, Hierarchy::find(INP2_HL));
			EmitCode::up();
			break;
		case NOUN_MATCHES_AS_OBJECT_CPMC:
			RTActionPatterns::compile_pattern_match_clause(Inter_noun_VAR, APClauses::spec(ap, NOUN_AP_CLAUSE),
				kind_of_noun, FALSE);
			break;
		case NOUN_MATCHES_AS_VALUE_CPMC:
			RTActionPatterns::compile_pattern_match_clause(
				TemporaryVariables::from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_noun),
				APClauses::spec(ap, NOUN_AP_CLAUSE), kind_of_noun, FALSE);
			break;
		case SECOND_MATCHES_AS_OBJECT_CPMC:
			RTActionPatterns::compile_pattern_match_clause(Inter_second_noun_VAR, APClauses::spec(ap, SECOND_AP_CLAUSE),
				kind_of_second, FALSE);
			break;
		case SECOND_MATCHES_AS_VALUE_CPMC:
			RTActionPatterns::compile_pattern_match_clause(
				TemporaryVariables::from_iname(Hierarchy::find(PARSED_NUMBER_HL), kind_of_second),
				APClauses::spec(ap, SECOND_AP_CLAUSE), kind_of_second, FALSE);
			break;
		case PLAYER_LOCATION_MATCHES_CPMC:
			RTActionPatterns::compile_pattern_match_clause(real_location_VAR, APClauses::spec(ap, IN_AP_CLAUSE), K_object, TRUE);
			break;
		case ACTOR_IN_RIGHT_PLACE_CPMC:
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_object, Hierarchy::find(ACTOR_LOCATION_HL));
				EmitCode::call(Hierarchy::find(LOCATIONOF_HL));
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				EmitCode::up();
			EmitCode::up();
			break;
		case ACTOR_LOCATION_MATCHES_CPMC:
			RTActionPatterns::compile_pattern_match_clause(actor_location_VAR,
				APClauses::spec(ap, IN_AP_CLAUSE), K_object, TRUE);
			break;
		case PARAMETER_MATCHES_CPMC: {
			kind *saved_kind = NonlocalVariables::kind(NonlocalVariables::parameter_object_variable());
			NonlocalVariables::set_kind(NonlocalVariables::parameter_object_variable(), ap->parameter_kind);
			RTActionPatterns::compile_pattern_match_clause(
				NonlocalVariables::parameter_object_variable(), APClauses::spec(ap, PARAMETRIC_AP_CLAUSE), ap->parameter_kind, FALSE);
			NonlocalVariables::set_kind(NonlocalVariables::parameter_object_variable(), saved_kind);
			break;
		}
		case OPTIONAL_CLAUSE_CPMC: {
			kind *K = SharedVariables::get_kind(apoc->stv_to_match);
			RTActionPatterns::compile_pattern_match_clause(
				TemporaryVariables::from_existing_variable(apoc->stv_to_match->underlying_var, K),
				apoc->clause_spec, K, APClauses::opt(apoc, ALLOW_REGION_AS_ROOM_APCOPT));
			break;
		}
		case PRESENCE_OF_MATCHES_CPMC: {
			instance *to_be_present =
				Specifications::object_exactly_described_if_any(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE));
			RTActionPatterns::compile_pattern_match_clause(
				TemporaryVariables::from_iname(RTInstances::value_iname(to_be_present), K_object),
				APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE), K_object, FALSE);
			break;
		}
		case PRESENCE_OF_IN_SCOPE_CPMC: {
			instance *to_be_present =
				Specifications::object_exactly_described_if_any(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE));
			EmitCode::call(Hierarchy::find(TESTSCOPE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTInstances::value_iname(to_be_present));
				EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
			EmitCode::up();
			break;
		}
		case LOOP_OVER_SCOPE_WITH_CALLING_CPMC: {
			loop_over_scope *los = LoopingOverScope::new(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE));
			wording PC = Descriptions::get_calling(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE));
			local_variable *lvar = LocalVariables::ensure_calling(PC,
				Specifications::to_kind(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE)));
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
			break;
		}
		case LOOP_OVER_SCOPE_WITHOUT_CALLING_CPMC: {
			loop_over_scope *los = LoopingOverScope::new(APClauses::spec(ap, IN_THE_PRESENCE_OF_AP_CLAUSE));
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
			break;
		}
		case SET_SELF_TO_ACTOR_CPMC:
			EmitCode::inv(SEQUENTIAL_BIP);
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				EmitCode::up();
				EmitCode::val_true();
			EmitCode::up();
			break;
		case WHEN_CONDITION_HOLDS_CPMC:
			CompileValues::to_code_val(APClauses::spec(ap, WHEN_AP_CLAUSE));
			break;
	}

@

=
void RTActionPatterns::compile_action_name_test(action_name_list *head) {
	int C = ActionNameLists::length(head);
	if (C == 0) return;
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
				EmitCode::val_iname(K_value, RTNamedActionPatterns::test_fn_iname(L->item.nap_listed));
			EmitCode::up();
		} else {
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(ACTION_HL));
				EmitCode::val_iname(K_value, RTActions::double_sharp(L->item.action_listed));
			EmitCode::up();
		}
	}
	while (downs > 0) { EmitCode::up(); downs--; }

	if (neg) EmitCode::up();
}

@ =
int RTActionPatterns::is_an_action_variable(parse_node *spec) {
	nonlocal_variable *nlv;
	if (spec == NULL) return FALSE;
	if (Lvalues::get_storage_form(spec) != NONLOCAL_VARIABLE_NT) return FALSE;
	nlv = Node::get_constant_nonlocal_variable(spec);
	if (nlv == Inter_noun_VAR) return TRUE;
	if (nlv == Inter_second_noun_VAR) return TRUE;
	if (nlv == Inter_actor_VAR) return TRUE;
	return FALSE;
}


@h Compiling action patterns.
The more complex clauses mostly act on a single I6 global variable.
In almost all cases, this falls through to the standard method for
testing a condition: we force it to propositional form, substituting the
global in for the value of free variable 0. However, rule clauses are
allowed a few syntaxes not permitted to ordinary conditions, and these
are handled as exceptional cases first:

(a) A table reference such as "a Queen listed in the Table of Monarchs"
expands.

(b) Writing "from R", where R is a region, tests if the room being gone
from is in R, not if it is equal to R. Similarly for other room-related
clauses such as "through" and "in".

(c) Given a piece of run-time parser grammar, we compile a test against
the standard I6 topic variables: there are two of these, so this is the
exceptional case where the clause doesn't act on a single I6 global,
and in this case we therefore ignore |I6_global_name|.

=
void RTActionPatterns::compile_pattern_match_clause(nonlocal_variable *I6_global_variable,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	if (spec == NULL) return;

	parse_node *I6_var_TS = NULL;
	if (I6_global_variable)
		I6_var_TS = Lvalues::new_actual_NONLOCAL_VARIABLE(I6_global_variable);

	int is_parameter = FALSE;
	if (I6_global_variable == NonlocalVariables::parameter_object_variable()) is_parameter = TRUE;

	RTActionPatterns::compile_pattern_match_clause_inner(
		I6_var_TS, is_parameter, spec, verify_as_kind, adapt_region);
}

void RTActionPatterns::compile_pattern_match_clause_inner(
	parse_node *I6_var_TS, int is_parameter,
	parse_node *spec, kind *verify_as_kind, int adapt_region) {
	int force_proposition = FALSE;

	if (spec == NULL) return;

	LOGIF(ACTION_PATTERN_COMPILATION, "[MPE on $P: $P]\n", I6_var_TS, spec);
	kind *K = Specifications::to_kind(spec);
	if (Kinds::Behaviour::definite(K) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_APClauseIndefinite),
			"that action seems to involve a value which is unclear about "
			"its kind",
			"and that's not allowed. For example, you're not allowed to just "
			"say 'Instead of taking a value: ...' because the taking action "
			"applies to objects; the vaguest you're allowed to be is 'Instead "
			"of taking an object: ...'.");
		return;
	}

	wording C = Descriptions::get_calling(spec);
	if (Wordings::nonempty(C)) {
		local_variable *lvar =
			LocalVariables::ensure_calling(C,
				Specifications::to_kind(spec));
		CompileConditions::add_calling(lvar);
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				inter_symbol *lvar_s = LocalVariables::declare(lvar);
				EmitCode::ref_symbol(K_value, lvar_s);
				CompileValues::to_code_val(I6_var_TS);
			EmitCode::up();
	}

	force_proposition = TRUE;

	if (Node::is(spec, UNKNOWN_NT)) {
		if (problem_count == 0) internal_error("MPE found unknown SP");
		force_proposition = FALSE;
	}
	else if (Lvalues::is_lvalue(spec)) {
		force_proposition = TRUE;
		if (Node::is(spec, TABLE_ENTRY_NT)) {
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
					CompileValues::to_code_val(I6_var_TS);
				EmitCode::up();
			EmitCode::up();
			force_proposition = FALSE;
		}
	}
	else if ((Specifications::is_kind_like(spec)) &&
			(Kinds::Behaviour::is_object(Specifications::to_kind(spec)) == FALSE)) {
			force_proposition = FALSE;
		}
	else if (Rvalues::is_rvalue(spec)) {
		if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec, K_understanding))) {
			if ((<understanding-action-irregular-operand>(Node::get_text(spec))) &&
				(<<r>> == TRUE)) {
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
			force_proposition = FALSE;
		}
		if ((is_parameter == FALSE) &&
			(Rvalues::is_object(spec))) {
			instance *I = Specifications::object_exactly_described_if_any(spec);
			if ((I) && (Instances::of_kind(I, K_region))) {
				LOGIF(ACTION_PATTERN_PARSING,
					"$P on %u : $T\n", spec, verify_as_kind, current_sentence);
				if (adapt_region) {
					EmitCode::call(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
					EmitCode::down();
						CompileValues::to_code_val(I6_var_TS);
						CompileValues::to_code_val(spec);
					EmitCode::up();
					force_proposition = FALSE;
				}
			}
		}
	}
	else if (Specifications::is_description(spec)) {
		if ((is_parameter == FALSE) &&
			((Descriptions::to_instance(spec)) &&
			(adapt_region) &&
			(Instances::of_kind(Descriptions::to_instance(spec), K_region)))) {
			EmitCode::call(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			EmitCode::down();
				CompileValues::to_code_val(I6_var_TS);
				CompileValues::to_code_val(spec);
			EmitCode::up();
		}
		force_proposition = FALSE;
	}

	pcalc_prop *prop = NULL;
	if (Specifications::is_description(spec))
		prop = Descriptions::to_proposition(spec);

	if (Lvalues::is_lvalue(spec))
		LOGIF(ACTION_PATTERN_COMPILATION, "Storage has $D\n", prop);

	if ((force_proposition) && (prop == NULL)) {
		prop = SentencePropositions::from_spec(spec);
		LOGIF(ACTION_PATTERN_COMPILATION, "[MPE forced proposition: $D]\n", prop);
		if (prop == NULL) internal_error("MPE unable to force proposition");
		if (verify_as_kind) {
			prop = Propositions::concatenate(prop,
				KindPredicates::new_atom(
					verify_as_kind, Terms::new_variable(0)));
			CompilePropositions::verify_descriptive(prop,
				"an action or activity to apply to things matching a given "
				"description", spec);
		}
	}

	if (prop) {
		LOGIF(ACTION_PATTERN_COMPILATION, "[MPE faces proposition: $D]\n", prop);
		TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
		CompilePropositions::to_test_as_condition(I6_var_TS, prop);
	}

	if (Wordings::nonempty(C)) {
		EmitCode::up();
	}
}


