[Chronology::] Chronology.

To keep track of the state of things so that it will be
possible in future to ask questions concerning the past.

@ Some conditions stored in SPs, and also some actions stored in APs, are
evaluated in the past tense, and to do this we need to lodge them into
storage: the following simple structures are used for this.

=
typedef struct past_tense_condition_record {
	struct parse_node *condition; /* condition to be evaluated */
	#ifdef IF_MODULE
	struct action_pattern *ap_to_test; /* condition to be evaluated */
	#endif
	struct parse_node *where_ptc_tested; /* sentence in which condition is found */
	CLASS_DEFINITION
} past_tense_condition_record;

typedef struct past_tense_action_record {
	#ifdef IF_MODULE
	struct action_pattern historic_action; /* action pattern to be matched */
	#endif
	struct parse_node *where_pta_tested; /* sentence in which AP is found */
	struct inter_name *pta_iname;
	CLASS_DEFINITION
} past_tense_action_record;

@h Compiling chronology.
First, the here and now.

=
int no_past_tenses = 0, no_past_actions = 0;
int too_late_for_past_tenses = FALSE;

#ifdef IF_MODULE
void Chronology::ap_compile_forced_to_present(action_pattern ap) {
	ActionPatterns::convert_to_present_tense(&ap); /* prevent recursion */
	RTActionPatterns::emit_pattern_match(&ap, FALSE);
}
#endif

#ifdef IF_MODULE
void Chronology::compile_past_action_pattern(value_holster *VH, time_period *duration, action_pattern ap) {
	int op = Occurrence::operator(duration);
	if (op == NO_REPM) op = EQ_REPM;
	package_request *PR = Hierarchy::local_package(PAST_ACTION_PATTERNS_HAP);
	inter_name *pta_routine = Hierarchy::make_iname_in(PAP_FN_HL, PR);
	LOGIF(TIME_PERIODS,
		"Chronology::compile_past_action_pattern on: $A\nat: $t\n", &ap, duration);
	if (ActionPatterns::makes_callings(&ap)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PTAPMakesCallings),
			"a description of an action cannot both refer to past history "
			"and also use '(called ...)'",
			"because that would require Inform in general to remember "
			"too much information about past events.");
	}
	if (too_late_for_past_tenses) internal_error("too late for a PAP");

	EmitCode::inv(AND_BIP);
	EmitCode::down();
		EmitCode::inv(INDIRECT0_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, pta_routine);
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
						EmitCode::val_iname(K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						EmitCode::val_number((inter_ti) no_past_actions);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(AND_BIP);
				EmitCode::down();
					EmitCode::inv(GE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) U);
						EmitCode::inv(LOOKUP_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
							EmitCode::val_number((inter_ti) no_past_actions);
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(LOOKUPBYTE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
						EmitCode::val_number((inter_ti) no_past_actions);
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
						EmitCode::val_iname(K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						EmitCode::val_number((inter_ti) no_past_actions);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(GE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) U);
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						EmitCode::val_number((inter_ti) no_past_actions);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
	} else {
		if (units == TIMES_UNIT) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				@<Emit the op@>;
				EmitCode::down();
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						EmitCode::val_number((inter_ti) no_past_actions);
					EmitCode::up();
					EmitCode::val_number((inter_ti) L);
				EmitCode::up();
				EmitCode::inv(LOOKUPBYTE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
					EmitCode::val_number((inter_ti) no_past_actions);
				EmitCode::up();
			EmitCode::up();
		} else {
			@<Emit the op@>;
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
					EmitCode::val_number((inter_ti) no_past_actions);
				EmitCode::up();
				EmitCode::val_number((inter_ti) L);
			EmitCode::up();
		}
	}
	EmitCode::up();

	past_tense_action_record *pta = CREATE(past_tense_action_record);
	pta->where_pta_tested = current_sentence;
	pta->historic_action = ap;
	pta->pta_iname = pta_routine;
	no_past_actions++;
}
#endif

@<Emit the op@> =
	switch (op) {
		case EQ_REPM: EmitCode::inv(EQ_BIP); break;
		case LT_REPM: EmitCode::inv(LT_BIP); break;
		case LE_REPM: EmitCode::inv(LE_BIP); break;
		case GT_REPM: EmitCode::inv(GT_BIP); break;
		case GE_REPM: EmitCode::inv(GE_BIP); break;
		default: internal_error("unimplemented operator");
	}

@ =
void Chronology::compile_past_tense_condition(value_holster *VH, parse_node *spec) {
	time_period *duration = Node::get_condition_tense(spec);
	int tense = IS_TENSE;
	grammatical_usage *gu = Node::get_tense_marker(spec);
	if (gu) tense = Lcon::get_tense(Stock::first_form_in_usage(gu));
	spec = spec->down;

	LOGIF(TIME_PERIODS,
		"Chronology::compile_past_tense_condition on:\n$T\nat: $t\nNPT: %d\n",
			spec, duration, no_past_tenses);

	int pasturise = FALSE;

	#ifdef IF_MODULE
	action_pattern *ap = NULL;
	if (AConditions::is_action_TEST_VALUE(spec)) ap = AConditions::pattern_from_action_TEST_VALUE(spec);
	if ((ap) && (tense != IS_TENSE)) {
		if ((duration) && (Occurrence::units(duration) == TIMES_UNIT) && (Occurrence::length(duration) >= 2)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NoMoreRonNewcombMoment),
				"a condition like 'we have X', where X is an action, has either "
				"happened for one spell or never happened at all",
				"so it can't make sense to ask if it has happened two or more "
				"times. For instance, at the start of play 'we have jumped' is "
				"false, but once the player types JUMP, 'we have jumped' will "
				"then be true for the rest of time. 'We have jumped for the "
				"second time' doesn't mean the jumping happened twice, it "
				"means the having-jumped has happened twice, which is "
				"impossible.");
			return;
		}
		if ((duration == NULL) ||
			((Occurrence::length(duration) == -1) && (Occurrence::until(duration) == -1))) {
			RTActionPatterns::emit_past_tense(ap);
			return;
		}
		pasturise = TRUE;
		tense = IS_TENSE;
	}
	#endif

	int turns_flag = 0,
		perfect_flag = ((tense)/2)%2,
		past_flag = (tense)%2;
	past_tense_condition_record *ptc;

	if (too_late_for_past_tenses) internal_error("too late for a PTC");
	if (Occurrence::units(duration) == TURNS_UNIT) turns_flag = 1;

	int op = Occurrence::operator(duration);
	if (op == NO_REPM) {
		if ((past_flag == 0) && (perfect_flag == 0)) op = EQ_REPM;
		else op = GE_REPM;
	}

	parse_node *cond = spec;

	int output_wanted = 1 + turns_flag;
	if (duration) {
		@<Emit the op@>;
		EmitCode::down();
	}
	EmitCode::call(Hierarchy::find(TESTSINGLEPASTSTATE_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) past_flag);
		EmitCode::val_number((inter_ti) no_past_tenses);
		EmitCode::val_number(0);
		EmitCode::val_number((inter_ti) (output_wanted + 4*perfect_flag));
	EmitCode::up();
	if (duration) {
		EmitCode::val_number((inter_ti) Occurrence::length(duration));
		EmitCode::up();
	}

	if (no_past_tenses >= 1024) { /* limit imposed by the Z-machine implementation */
		StandardProblems::limit_problem(Task::syntax_tree(), _p_(Untestable), /* well, not conveniently */
			"conditions written in the past tense", 1024);
		return;
	}

	ptc = CREATE(past_tense_condition_record);
	ptc->where_ptc_tested = current_sentence;
	if (pasturise) {
		ptc->condition = NULL;
		#ifdef IF_MODULE
		ptc->ap_to_test = ap;
		#endif
	} else {
		ptc->condition = cond;
		#ifdef IF_MODULE
		ptc->ap_to_test = NULL;
		#endif
	}
	no_past_tenses++;
}

@h The periodic monitoring.
As can be seen from the above routines, we depend on the array |TrackedActions|,
on a routine called |TestSinglePastState| and on magical things happening at
run-time at the start of every action. Once these are defined, it's too
late to create any further past tense references, so:

=
void Chronology::allow_no_further_past_tenses(void) {
	too_late_for_past_tenses = TRUE;
}

@ The |{-A}| ("past actions") escape.
A series of |if| statements checking whether each past-tense action is now
true, and updating the relevant array entries accordingly.

This looks straightforward, but a tricky point arises from the fact that a
turn is not the same thing as a slot for an action. Usually they correspond,
but not always. So if the action for a turn is taking, and that causes
a further action of opening a box, say, what do we say about the number
of turns for which the taking and opening actions have been happening?

In |adjust| mode, we are at the start or end of a "try" action which
arises mid-turn. As can be seen, adjust mode is allowed only to change
the record of how many turns an action has been happening -- from 0 to 1,
and otherwise making no change, if the action is the one being tried;
or else back to 0 if it isn't. In particular, an action implicitly
tried does not affect the "times" count.

This is a delicate business. The better way to solve this would be to
stack a local copy of these arrays each time an action starts, and restore
it (with updates) each time it finishes. But there is just no storage
available in the Z-machine to contemplate this with equanimity, so we
compromise. Historically, it's been a fertile source of tricky bugs.
The test case |ActionInterrupted| should be checked if this code is
ever tampered with.

=
void Chronology::past_actions_i6_routines(void) {
#ifdef IF_MODULE
	if (PluginManager::active(actions_plugin)) {
		int once_only = TRUE;
		past_tense_action_record *pta;
		LOOP_OVER(pta, past_tense_action_record) {
			current_sentence = pta->where_pta_tested; /* ensure problems reported correctly */
			packaging_state save = Functions::begin(pta->pta_iname);

			EmitCode::inv(IF_BIP);
			EmitCode::down();
				Chronology::ap_compile_forced_to_present(pta->historic_action);
				EmitCode::code();
				EmitCode::down();
					EmitCode::rtrue();
				EmitCode::up();
			EmitCode::up();
			EmitCode::rfalse();

			if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
				once_only = FALSE;
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableLookup),
					"it's not safe to look up table entries in a way referring "
					"to past history",
					"because it leads to dangerous ambiguities. For instance, "
					"does 'taking an item listed in the Table of Treasure "
					"for the first time' mean that this is the first time taking "
					"any of the things in the table, or only the first time "
					"this one? And so on.");
			}

			Functions::end(save);
		}
		inter_name *iname = Hierarchy::find(PASTACTIONSI6ROUTINES_HL);
		packaging_state save = EmitArrays::begin(iname, K_value);
		LOOP_OVER(pta, past_tense_action_record)
			EmitArrays::iname_entry(pta->pta_iname);
		EmitArrays::numeric_entry(0);
		EmitArrays::numeric_entry(0);
		EmitArrays::end(save);
		Hierarchy::make_available(iname);
	}
#endif
}

@ =
void Chronology::past_tenses_i6_escape(void) {
	int once_only = TRUE;
	past_tense_condition_record *ptc;
	LOGIF(TIME_PERIODS,
		"Creating %d past tense conditions in TestSinglePastState\n",
			NUMBER_CREATED(past_tense_condition_record));

	inter_name *iname = Hierarchy::find(TESTSINGLEPASTSTATE_HL);
	packaging_state save = Functions::begin(iname);
	inter_symbol *past_flag_s = LocalVariables::new_other_as_symbol(I"past_flag");
	inter_symbol *pt_s = LocalVariables::new_other_as_symbol(I"pt");
	inter_symbol *turn_end_s = LocalVariables::new_other_as_symbol(I"turn_end");
	inter_symbol *wanted_s = LocalVariables::new_other_as_symbol(I"wanted");
	inter_symbol *old_s = LocalVariables::new_internal_as_symbol(I"old");
	inter_symbol *new_s = LocalVariables::new_internal_as_symbol(I"new");
	inter_symbol *trips_s = LocalVariables::new_internal_as_symbol(I"trips");
	inter_symbol *consecutives_s = LocalVariables::new_internal_as_symbol(I"consecutives");
	Frames::determines_the_past();

	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, past_flag_s);
		EmitCode::code();
		EmitCode::down();
			@<Unpack the past@>;
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Unpack the present@>;
			@<Swizzle@>;
			@<Repack the present@>;
		EmitCode::up();
	EmitCode::up();

	@<Answer the question posed@>;

	Functions::end(save);
	Hierarchy::make_available(iname);
	LOGIF(TIME_PERIODS, "Creation of past tense conditions complete\n");
}

@<Unpack the past@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, new_s);
		EmitCode::inv(BITWISEAND_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
				EmitCode::val_symbol(K_value, pt_s);
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, trips_s);
		EmitCode::inv(DIVIDE_BIP);
		EmitCode::down();
			EmitCode::inv(BITWISEAND_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
					EmitCode::val_symbol(K_value, pt_s);
				EmitCode::up();
				EmitCode::val_number(0xFE);
			EmitCode::up();
			EmitCode::val_number(2);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, consecutives_s);
		EmitCode::inv(DIVIDE_BIP);
		EmitCode::down();
			EmitCode::inv(BITWISEAND_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
					EmitCode::val_symbol(K_value, pt_s);
				EmitCode::up();
				EmitCode::val_number(0xFF00);
			EmitCode::up();
			EmitCode::val_number(0x100);
		EmitCode::up();
	EmitCode::up();

@<Unpack the present@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, old_s);
		EmitCode::inv(BITWISEAND_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
				EmitCode::val_symbol(K_value, pt_s);
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, trips_s);
		EmitCode::inv(DIVIDE_BIP);
		EmitCode::down();
			EmitCode::inv(BITWISEAND_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
					EmitCode::val_symbol(K_value, pt_s);
				EmitCode::up();
				EmitCode::val_number(0xFE);
			EmitCode::up();
			EmitCode::val_number(2);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, consecutives_s);
		EmitCode::inv(DIVIDE_BIP);
		EmitCode::down();
			EmitCode::inv(BITWISEAND_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
					EmitCode::val_symbol(K_value, pt_s);
				EmitCode::up();
				EmitCode::val_number(0xFF00);
			EmitCode::up();
			EmitCode::val_number(0x100);
		EmitCode::up();
	EmitCode::up();

@<Repack the present@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::inv(LOOKUPREF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
			EmitCode::val_symbol(K_value, pt_s);
		EmitCode::up();
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, new_s);
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(TIMES_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, trips_s);
					EmitCode::val_number(0x02);
				EmitCode::up();
				EmitCode::inv(TIMES_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, consecutives_s);
					EmitCode::val_number(0x100);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Swizzle@> =
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, pt_s);
		EmitCode::code();
		EmitCode::down();
			LOOP_OVER(ptc, past_tense_condition_record) {
				current_sentence = ptc->where_ptc_tested; /* ensure problems reported correctly */
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number((inter_ti) (ptc->allocation_id));
					EmitCode::code();
					EmitCode::down();
						@<Compile code to set the new state of the condition, as measured in the present@>;
						if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
							once_only = FALSE;
							StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableEntries),
								"it's not safe to look up table entries in a way referring "
								"to past history",
								"because it leads to dangerous ambiguities. For instance, "
								"does 'taking an item listed in the Table of Treasure "
								"for the first time' mean that this is the first time taking "
								"any of the things in the table, or only the first time "
								"this one? And so on.");
						}
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::inv(DEFAULT_BIP);
			EmitCode::down();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"*** No such past tense condition ***\n");
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, new_s);
						EmitCode::val_number(0);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, new_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, old_s);
					EmitCode::val_false();
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(POSTINCREMENT_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, trips_s);
					EmitCode::up();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GT_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, trips_s);
							EmitCode::val_number(127);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, trips_s);
								EmitCode::val_number(127);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, turn_end_s);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(POSTINCREMENT_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, consecutives_s);
					EmitCode::up();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GT_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, consecutives_s);
							EmitCode::val_number(127);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, consecutives_s);
								EmitCode::val_number(127);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, consecutives_s);
				EmitCode::val_number(0);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@ The following goes through the dance of writing to a temporary stream in
order to ensure that the compilation happens in a memory stream, rather than
a file stream, thus allowing rewinding:

@<Compile code to set the new state of the condition, as measured in the present@> =
	if (ptc->condition) {
		parse_node *spec = ptc->condition;
		LOGIF(TIME_PERIODS, "Number %d: proposition $D\n",
			ptc->allocation_id, Specifications::to_proposition(spec));
		if (CreationPredicates::contains_callings(Specifications::to_proposition(spec))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PastCallings),
				"it's not safe to use '(called ...)' in a way referring "
				"to past history",
				"because this would make a temporary value to hold the "
				"quantity in question, but at a different time from when "
				"it would be needed.");
		} else {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, new_s);
				CompileValues::to_code_val(spec);
			EmitCode::up();
		}
	} else {
		#ifdef IF_MODULE
		LOG("Picked up past $A\n", ptc->ap_to_test);
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, new_s);
			RTActionPatterns::emit_past_tense(ptc->ap_to_test);
		EmitCode::up();
		#endif
	}

@<Answer the question posed@> =
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, wanted_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(0);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, new_s);
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(RETURN_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, new_s);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(1);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, new_s);
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(RETURN_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, trips_s);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(2);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, new_s);
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(RETURN_BIP);
							EmitCode::down();
								EmitCode::inv(PLUS_BIP); /* Plus one because we count the current turn */
								EmitCode::down();
									EmitCode::val_symbol(K_value, consecutives_s);
									EmitCode::val_number(1);
								EmitCode::up();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(4);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, new_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(5);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, trips_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(6);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, consecutives_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_number(0);
	EmitCode::up();

@ The |{-E}| ("extents") escape.
Sizes for the arrays. We need to do these after compiling the code in the
escapes above, because they might continue to spawn each other as they
compile: e.g. a past tense action pattern might itself refer to a condition
in the still more remote past, as in the case of "After switching on the
lunar clock when the lunar clock has been switched on for more than five
times".

=
void Chronology::chronology_extents_i6_escape(void) {
	inter_name *iname1 = Hierarchy::find(NO_PAST_TENSE_CONDS_HL);
	Hierarchy::make_available(iname1);
	Emit::numeric_constant(iname1, (inter_ti) no_past_tenses);

	inter_name *iname2 = Hierarchy::find(NO_PAST_TENSE_ACTIONS_HL);
	Hierarchy::make_available(iname2);
	Emit::numeric_constant(iname2, (inter_ti) no_past_actions);
}

@ =
void Chronology::start_plugin(void) {
}

void Chronology::compile_runtime(void) {
	if (PluginManager::active(chronology_plugin)) {
		Chronology::chronology_extents_i6_escape();
		Chronology::past_tenses_i6_escape();
		Chronology::allow_no_further_past_tenses();
	}
}
