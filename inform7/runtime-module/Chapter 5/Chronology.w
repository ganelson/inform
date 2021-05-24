[Chronology::] Chronology.

To compile the chronology submodule for a compilation unit, which contains
_past_condition and _action_history_condition packages.

@h Plugin.
A little awkwardly, these two features make up the "chronology" plugin. There
are arguments for and against making these features doctrinally part of Basic
Inform: or at least for making past tense conditions part of it. But Basic
Inform has no concept of "turns", for example.

In any case, for now, these features are an optional plugin, but the activation
function does nothing:

=
void Chronology::start_plugin(void) {
}

@h Past tense conditions.
Each past tense condition, such as "if the green door has been open", causes
one of these objects to be created, which records that we have to keep track
of something -- in this case, whether or not the green door is open.

=
typedef struct past_tense_condition_record {
	struct parse_node *condition; /* condition to be evaluated */
	struct action_pattern *ap_to_test; /* condition to be evaluated */
	struct parse_node *where_ptc_tested; /* sentence in which condition is found */
	struct package_request *ptc_package;
	struct inter_name *ptc_iname;
	CLASS_DEFINITION
} past_tense_condition_record;

@ This is called when a past tense condition is needed. The idea is simple
enough -- we make a note to compile code monitoring whether the green door
is open, which will end up being a "past state"; but for now we only call
a function which tests that past state.

Things are more complicated if the condition is an action pattern, as in
"if we have taken something portable for the third time". There are a few
easy cases -- e.g., "if we have taken" can be resolved using the action
bitmap which always exists, and therefore does not need any request for a
past state to be maintained.

=
void Chronology::compile_past_tense_condition(parse_node *tense_indicator) {
	time_period *duration = Node::get_condition_tense(tense_indicator);
	grammatical_usage *gu = Node::get_tense_marker(tense_indicator);
	int tense = (gu)?(Lcon::get_tense(Stock::first_form_in_usage(gu))):IS_TENSE;
	parse_node *cond = tense_indicator->down;

	action_pattern *ap = NULL;
	if ((tense != IS_TENSE) && (AConditions::is_action_TEST_VALUE(cond))) {
		ap = AConditions::pattern_from_action_TEST_VALUE(cond);
		@<Avoid the Ron Newcomb Moment@>;
		@<Divert an easy case to a simple bitmap lookup@>;
		tense = IS_TENSE;
	}

	int turns_flag = 0,
		perfect_flag = ((tense)/2)%2,
		past_flag = (tense)%2;
	if (Occurrence::units(duration) == TURNS_UNIT) turns_flag = 1;
	int op = Occurrence::operator(duration);
	if (op == NO_REPM) {
		if ((past_flag == 0) && (perfect_flag == 0)) op = EQ_REPM;
		else op = GE_REPM;
	}

	inter_name *id_iname = NULL;
	@<Make a record of this and queue a request to compile a function to monitor it@>;
	@<Compile a call to TESTSINGLEPASTSTATE@>;
}

@ A treacherous issue named after its discoverer:

@<Avoid the Ron Newcomb Moment@> =
	if ((duration) && (Occurrence::units(duration) == TIMES_UNIT) &&
		(Occurrence::length(duration) >= 2)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_NoMoreRonNewcombMoment),
			"a condition like 'we have X', where X is an action, has either happened for "
			"one spell or never happened at all",
			"so it can't make sense to ask if it has happened two or more times. For "
			"instance, at the start of play 'we have jumped' is false, but once the "
			"player types JUMP, 'we have jumped' will then be true for the rest of time. "
			"'We have jumped for the second time' doesn't mean the jumping happened "
			"twice, it means the having-jumped has happened twice, which is impossible.");
		return;
	}

@<Divert an easy case to a simple bitmap lookup@> =
	if ((duration == NULL) ||
		((Occurrence::length(duration) == -1) && (Occurrence::until(duration) == -1))) {
		Chronology::compile_action_bitmap_test(ap);
		return;
	}

@<Make a record of this and queue a request to compile a function to monitor it@> =
	past_tense_condition_record *ptc = CREATE(past_tense_condition_record);
	ptc->where_ptc_tested = current_sentence;
	if (ap) {
		ptc->condition = NULL;
		ptc->ap_to_test = ap;
	} else {
		ptc->condition = cond;
		ptc->ap_to_test = NULL;
	}
	package_request *PR = Hierarchy::local_package(PAST_TENSE_CONDS_HAP);
	ptc->ptc_package = PR;
	ptc->ptc_iname = NULL;
	id_iname = Hierarchy::make_iname_in(PTC_ID_HL, ptc->ptc_package);
	Emit::numeric_constant(id_iname, 0); /* a placeholder: made unique in linking */
	text_stream *desc = Str::new();
	WRITE_TO(desc, "past tense condition %d", ptc->allocation_id);
	Sequence::queue(&Chronology::ptc_agent,
		STORE_POINTER_past_tense_condition_record(ptc), desc);

@ So, then, the function just requested will monitor the past state at intervals
throughout the program's running. By the time code reaches the present position,
then, that past state is available, and can be accessed with a simple function call.

@<Compile a call to TESTSINGLEPASTSTATE@> =
	int output_wanted = 1 + turns_flag;
	if (duration) {
		Chronology::emit_comparison_operator(op);
		EmitCode::down();
	}
	EmitCode::call(Hierarchy::find(TESTSINGLEPASTSTATE_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) past_flag);
		EmitCode::val_iname(K_value, id_iname);
		EmitCode::val_number(0);
		EmitCode::val_number((inter_ti) (output_wanted + 4*perfect_flag));
	EmitCode::up();
	if (duration) {
		EmitCode::val_number((inter_ti) Occurrence::length(duration));
		EmitCode::up();
	}

@ =
int PM_PastTableEntries_once_only = TRUE;
void Chronology::ptc_agent(compilation_subtask *t) {
	past_tense_condition_record *ptc = RETRIEVE_POINTER_past_tense_condition_record(t->data);
	current_sentence = ptc->where_ptc_tested; /* ensure problems reported correctly */
	ptc->ptc_iname = Hierarchy::make_iname_in(PTC_FN_HL, ptc->ptc_package);
	packaging_state save = Functions::begin(ptc->ptc_iname);
	Frames::determines_the_past();
	@<Compile code to set the new state of the condition, as measured in the present@>;
	if ((LocalVariables::are_we_using_table_lookup()) && (PM_PastTableEntries_once_only)) {
		PM_PastTableEntries_once_only = FALSE;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableEntries),
			"it's not safe to look up table entries in a way referring to past history",
			"because it leads to dangerous ambiguities. For instance, does 'taking an item "
			"listed in the Table of Treasure for the first time' mean that this is the "
			"first time taking any of the things in the table, or only the first time "
			"this one? And so on.");
	}
	Functions::end(save);
	inter_name *md_iname = Hierarchy::make_iname_in(PTC_VALUE_MD_HL, ptc->ptc_package);
	Emit::iname_constant(md_iname, K_value, ptc->ptc_iname);
}

@<Compile code to set the new state of the condition, as measured in the present@> =
	if (ptc->condition) {
		parse_node *cond = ptc->condition;
		LOGIF(TIME_PERIODS, "Number %d: proposition $D\n",
			ptc->allocation_id, Specifications::to_proposition(cond));
		if (CreationPredicates::contains_callings(Specifications::to_proposition(cond))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastCallings),
				"it's not safe to use '(called ...)' in a way referring to past history",
				"because this would make a temporary value to hold the quantity in question, "
				"but at a different time from when it would be needed.");
		} else {
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				CompileValues::to_code_val(cond);
			EmitCode::up();
		}
	} else {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			Chronology::compile_action_bitmap_test(ptc->ap_to_test);
		EmitCode::up();
	}

@ This, then, is the easy case of testing something like "if we have looked".

=
void Chronology::compile_action_bitmap_test(action_pattern *ap) {
	int bad_form = FALSE;
	EmitCode::call(Hierarchy::find(TESTACTIONBITMAP_HL));
	EmitCode::down();
	if (APClauses::spec(ap, NOUN_AP_CLAUSE) == NULL)
		EmitCode::val_number(0);
	else
		CompileValues::to_code_val(APClauses::spec(ap, NOUN_AP_CLAUSE));
	int L = ActionNameLists::length(ap->action_list);
	if (L == 0)
		EmitCode::val_number((inter_ti) -1);
	else {
		anl_item *item = ActionNameLists::first_item(ap->action_list);
		if (L >= 2) bad_form = TRUE;
		if (ActionSemantics::can_be_compiled_in_past_tense(item->action_listed) == FALSE)
			bad_form = TRUE;
		EmitCode::val_iname(K_value, RTActions::double_sharp(item->action_listed));
	}
	EmitCode::up();
	if (APClauses::viable_in_past_tense(ap) == FALSE) bad_form = TRUE;
	if (bad_form)
		@<Issue too complex PT problem@>;
}

@<Issue too complex PT problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PTAPTooComplex),
		"that is too complex a past tense action",
		"at least for this version of Inform to handle: we may improve matters in later "
		"releases. The restriction is that the actions used in the past tense may take at "
		"most one object, and that this must be a physical thing (not a value, in other "
		"words). And no details of where or what else was then happening can be specified.");

@h Action history conditions.
An "action history condition" is subtly different: for example, "if taking
something edible for the third turn". Reference is made to the past, by implication,
but the action itself is referred to in the present tense. (Whereas "if we have
taken something" would be a past tense condition: see above.)

=
typedef struct action_history_condition_record {
	struct action_pattern historic_action; /* action pattern to be matched */
	struct parse_node *where_ahcr_tested; /* sentence in which AP is found */
	struct package_request *ahcr_package;
	struct inter_name *ahcr_iname;
	CLASS_DEFINITION
} action_history_condition_record;

@ The |duration| here records the "for the third turn" part; the |ap|, the
"taking something edible" part.

=
void Chronology::compile_action_history_condition(time_period *duration, action_pattern ap) {
	int op = Occurrence::operator(duration);
	if (op == NO_REPM) op = EQ_REPM;
	package_request *PR = Hierarchy::local_package(ACTION_HISTORY_CONDS_HAP);
	inter_name *ahc_function = Hierarchy::make_iname_in(AHC_FN_HL, PR);
	LOGIF(TIME_PERIODS,
		"Chronology::compile_action_history_condition on: $A\nat: $t\n", &ap, duration);
	if (ActionPatterns::makes_callings(&ap)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PTAPMakesCallings),
			"a description of an action cannot both refer to past history and also use "
			"'(called ...)'",
			"because that would require Inform in general to remember too much information "
			"about past events.");
	}

	inter_name *id_iname = NULL;
	@<Make a record of the need for this AHC and queue a request to compile it@>;
	@<Compile code to perform the test in the here and now@>;
}

@<Make a record of the need for this AHC and queue a request to compile it@> =
	action_history_condition_record *ahcr = CREATE(action_history_condition_record);
	ahcr->where_ahcr_tested = current_sentence;
	ahcr->historic_action = ap;
	ahcr->ahcr_iname = ahc_function;
	ahcr->ahcr_package = PR;
	text_stream *desc = Str::new();
	WRITE_TO(desc, "past tense action %d", ahcr->allocation_id);
	Sequence::queue(&Chronology::ahcr_agent,
		STORE_POINTER_action_history_condition_record(ahcr), desc);
	id_iname = Hierarchy::make_iname_in(AHC_ID_HL, ahcr->ahcr_package);
	Emit::numeric_constant(id_iname, 0); /* a placeholder: made unique in linking */

@ The test compiled here relies entirely on a slew of arrays being correctly
maintained. Those arrays are all managed by code compiled in linking (see
//codegen: Chronology//, code which has regularly been calling our own AHC
function throughout play.

@<Compile code to perform the test in the here and now@> =
	EmitCode::inv(AND_BIP);
	EmitCode::down();
		EmitCode::inv(INDIRECT0_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, ahc_function);
		EmitCode::up();

	int L = Occurrence::length(duration), U = Occurrence::until(duration),
		units = Occurrence::units(duration);
	if (L < 0) L = 0;
	if (U >= 0) {
		if (units == TIMES_UNIT) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::inv(LE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) L);
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value,
							Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						EmitCode::val_iname(K_value, id_iname);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(AND_BIP);
				EmitCode::down();
					EmitCode::inv(GE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) U);
						EmitCode::inv(LOOKUP_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value,
								Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
							EmitCode::val_iname(K_value, id_iname);
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(LOOKUPBYTE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value,
							Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
						EmitCode::val_iname(K_value, id_iname);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		} else {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::inv(LE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) L);
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value,
							Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						EmitCode::val_iname(K_value, id_iname);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(GE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) U);
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value,
							Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						EmitCode::val_iname(K_value, id_iname);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
	} else {
		if (units == TIMES_UNIT) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				Chronology::emit_comparison_operator(op);
				EmitCode::down();
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value,
							Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						EmitCode::val_iname(K_value, id_iname);
					EmitCode::up();
					EmitCode::val_number((inter_ti) L);
				EmitCode::up();
				EmitCode::inv(LOOKUPBYTE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value,
						Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
					EmitCode::val_iname(K_value, id_iname);
				EmitCode::up();
			EmitCode::up();
		} else {
			Chronology::emit_comparison_operator(op);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value,
						Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
					EmitCode::val_iname(K_value, id_iname);
				EmitCode::up();
				EmitCode::val_number((inter_ti) L);
			EmitCode::up();
		}
	}
	EmitCode::up();

@ The AHC function is very simple: it returns true if the current action matches
the pattern, and otherwise false.

=
int PM_PastTableLookup_once_only = TRUE;
void Chronology::ahcr_agent(compilation_subtask *t) {
	action_history_condition_record *ahcr =
		RETRIEVE_POINTER_action_history_condition_record(t->data);
	current_sentence = ahcr->where_ahcr_tested; /* ensure problems reported correctly */
	packaging_state save = Functions::begin(ahcr->ahcr_iname);

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		ActionPatterns::convert_to_present_tense(&(ahcr->historic_action)); /* prevent recursion */
		RTActionPatterns::compile_pattern_match(&(ahcr->historic_action));
		EmitCode::code();
		EmitCode::down();
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();
	EmitCode::rfalse();

	if ((LocalVariables::are_we_using_table_lookup()) && (PM_PastTableLookup_once_only)) {
		PM_PastTableLookup_once_only = FALSE;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableLookup),
			"it's not safe to look up table entries in a way referring to past history",
			"because it leads to dangerous ambiguities. For instance, does 'taking an item "
			"listed in the Table of Treasure for the first time' mean that this is the "
			"first time taking any of the things in the table, or only the first time "
			"this one? And so on.");
	}

	Functions::end(save);
	inter_name *md_iname = Hierarchy::make_iname_in(AHC_VALUE_MD_HL, ahcr->ahcr_package);
	Emit::iname_constant(md_iname, K_value, ahcr->ahcr_iname);
}

@h Utility.
Last and very much least:

=
void Chronology::emit_comparison_operator(int op) {
	switch (op) {
		case EQ_REPM: EmitCode::inv(EQ_BIP); break;
		case LT_REPM: EmitCode::inv(LT_BIP); break;
		case LE_REPM: EmitCode::inv(LE_BIP); break;
		case GT_REPM: EmitCode::inv(GT_BIP); break;
		case GE_REPM: EmitCode::inv(GE_BIP); break;
		default: internal_error("unimplemented operator");
	}
}
