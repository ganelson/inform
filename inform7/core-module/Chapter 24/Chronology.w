[Chronology::] Chronology.

To keep track of the state of things so that it will be
possible in future to ask questions concerning the past.

@h Definitions.

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
	MEMORY_MANAGEMENT
} past_tense_condition_record;

typedef struct past_tense_action_record {
	#ifdef IF_MODULE
	struct action_pattern historic_action; /* action pattern to be matched */
	#endif
	struct parse_node *where_pta_tested; /* sentence in which AP is found */
	struct inter_name *pta_iname;
	MEMORY_MANAGEMENT
} past_tense_action_record;

@h Compiling chronology.
First, the here and now.

=
int no_past_tenses = 0, no_past_actions = 0;
int too_late_for_past_tenses = FALSE;

#ifdef IF_MODULE
void Chronology::ap_compile_forced_to_present(action_pattern ap) {
	PL::Actions::Patterns::convert_to_present_tense(&ap); /* prevent recursion */
	PL::Actions::Patterns::emit_pattern_match(ap, FALSE);
}
#endif

#ifdef IF_MODULE
void Chronology::compile_past_action_pattern(value_holster *VH, time_period duration, action_pattern ap) {
	char *op = duration.inform6_operator;
	compilation_module *C = Modules::find(current_sentence);
	package_request *PR = Packaging::request_resource(C, CHRONOLOGY_SUBPACKAGE);
	inter_name *pta_routine = Packaging::function(
		InterNames::one_off(I"pap_fn", PR),
		PR,
		InterNames::new(PAST_ACTION_ROUTINE_INAMEF));
	LOGIF(TIME_PERIODS,
		"Chronology::compile_past_action_pattern on: $A\nat: $t\n", &ap, &duration);
	if (PL::Actions::Patterns::makes_callings(&ap)) {
		Problems::Issue::sentence_problem(_p_(PM_PTAPMakesCallings),
			"a description of an action cannot both refer to past history "
			"and also use '(called ...)'",
			"because that would require Inform in general to remember "
			"too much information about past events.");
	}
	if (too_late_for_past_tenses) internal_error("too late for a PAP");
	if (op == NULL) op = "==";

	Emit::inv_primitive(and_interp);
	Emit::down();
		Emit::inv_primitive(indirect0_interp);
		Emit::down();
			Emit::val_iname(K_value, pta_routine);
		Emit::up();

	int L = duration.length; if (L < 0) L = 0;
	if (duration.until >= 0) {
		if (duration.units == TIMES_UNIT) {
			Emit::inv_primitive(and_interp);
			Emit::down();
				Emit::inv_primitive(le_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) L);
					Emit::inv_primitive(lookup_interp);
					Emit::down();
						Emit::val_iname(K_value, InterNames::extern(TIMESACTIONHASHAPPENED_EXNAMEF));
						Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Emit::up();
				Emit::up();
				Emit::inv_primitive(and_interp);
				Emit::down();
					Emit::inv_primitive(ge_interp);
					Emit::down();
						Emit::val(K_number, LITERAL_IVAL, (inter_t) duration.until);
						Emit::inv_primitive(lookup_interp);
						Emit::down();
							Emit::val_iname(K_value, InterNames::extern(TIMESACTIONHASHAPPENED_EXNAMEF));
							Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
						Emit::up();
					Emit::up();
					Emit::inv_primitive(lookupbyte_interp);
					Emit::down();
						Emit::val_iname(K_value, InterNames::extern(ACTIONCURRENTLYHAPPENINGFLAG_EXNAMEF));
						Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Emit::up();
				Emit::up();
			Emit::up();
		} else {
			Emit::inv_primitive(and_interp);
			Emit::down();
				Emit::inv_primitive(le_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) L);
					Emit::inv_primitive(lookup_interp);
					Emit::down();
						Emit::val_iname(K_value, InterNames::extern(TURNSACTIONHASBEENHAPPENING_EXNAMEF));
						Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Emit::up();
				Emit::up();
				Emit::inv_primitive(ge_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) duration.until);
					Emit::inv_primitive(lookup_interp);
					Emit::down();
						Emit::val_iname(K_value, InterNames::extern(TURNSACTIONHASBEENHAPPENING_EXNAMEF));
						Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	} else {
		if (duration.units == TIMES_UNIT) {
			Emit::inv_primitive(and_interp);
			Emit::down();
				@<Emit the op@>;
				Emit::down();
					Emit::inv_primitive(lookup_interp);
					Emit::down();
						Emit::val_iname(K_value, InterNames::extern(TIMESACTIONHASHAPPENED_EXNAMEF));
						Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Emit::up();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) L);
				Emit::up();
				Emit::inv_primitive(lookupbyte_interp);
				Emit::down();
					Emit::val_iname(K_value, InterNames::extern(ACTIONCURRENTLYHAPPENINGFLAG_EXNAMEF));
					Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
				Emit::up();
			Emit::up();
		} else {
			@<Emit the op@>;
			Emit::down();
				Emit::inv_primitive(lookup_interp);
				Emit::down();
					Emit::val_iname(K_value, InterNames::extern(TURNSACTIONHASBEENHAPPENING_EXNAMEF));
					Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_actions);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, (inter_t) L);
			Emit::up();
		}
	}
	Emit::up();

	past_tense_action_record *pta = CREATE(past_tense_action_record);
	pta->where_pta_tested = current_sentence;
	pta->historic_action = ap;
	pta->pta_iname = pta_routine;
	no_past_actions++;
}
#endif

@<Emit the op@> =
	if (strcmp(op, "==") == 0) Emit::inv_primitive(eq_interp);
	else if (strcmp(op, "~=") == 0) Emit::inv_primitive(ne_interp);
	else if (strcmp(op, ">") == 0) Emit::inv_primitive(gt_interp);
	else if (strcmp(op, ">=") == 0) Emit::inv_primitive(ge_interp);
	else if (strcmp(op, "<") == 0) Emit::inv_primitive(lt_interp);
	else if (strcmp(op, "<=") == 0) Emit::inv_primitive(le_interp);
	else internal_error("can't find operator");

@ =
void Chronology::compile_past_tense_condition(value_holster *VH, parse_node *spec) {
	time_period duration = *(ParseTree::get_condition_tense(spec));
	spec = spec->down;

	LOGIF(TIME_PERIODS,
		"Chronology::compile_past_tense_condition on:\n$T\nat: $t\nNPT: %d\n",
			spec, &duration, no_past_tenses);

	int pasturise = FALSE;

	#ifdef IF_MODULE
	action_pattern *ap = NULL;
	if (ParseTree::is(spec, TEST_VALUE_NT)) ap = Rvalues::to_action_pattern(spec->down);
	if ((ap) && (duration.tense != IS_TENSE)) {
		if ((duration.units == TIMES_UNIT) && (duration.length >= 2)) {
			Problems::Issue::sentence_problem(_p_(PM_NoMoreRonNewcombMoment),
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
		if ((duration.length == -1) && (duration.until == -1)) {
			PL::Actions::Patterns::emit_past_tense(ap);
			return;
		}
		pasturise = TRUE;
		duration.tense = IS_TENSE;
	}
	#endif

	int turns_flag = 0,
		perfect_flag = ((duration.tense)/2)%2,
		past_flag = (duration.tense)%2;
	char *op = duration.inform6_operator;
	past_tense_condition_record *ptc;

	if (too_late_for_past_tenses) internal_error("too late for a PTC");
	if (duration.units == TURNS_UNIT) turns_flag = 1;

	if ((past_flag == 0) && (perfect_flag == 0) && (op == NULL)) op = "==";
	else if (op == NULL) op = ">=";

	parse_node *cond = spec;

	int output_wanted = 1 + turns_flag;
	int operate = FALSE;
	if (Occurrence::is_valid(&duration))
		if ((duration.inform6_operator != NULL) || (duration.length >= 0))
			operate = TRUE;
	if (operate) {
		@<Emit the op@>;
		Emit::down();
	}
	Emit::inv_call(InterNames::to_symbol(InterNames::iname(TestSinglePastState_INAME)));
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, (inter_t) past_flag);
		Emit::val(K_number, LITERAL_IVAL, (inter_t) no_past_tenses);
		Emit::val(K_number, LITERAL_IVAL, 0);
		Emit::val(K_number, LITERAL_IVAL, (inter_t) (output_wanted + 4*perfect_flag));
	Emit::up();
	if (operate) {
		Emit::val(K_number, LITERAL_IVAL, (inter_t) duration.length);
		Emit::up();
	}

	if (no_past_tenses >= 1024) { /* limit imposed by the Z-machine implementation */
		Problems::Issue::limit_problem(_p_(Untestable), /* well, not conveniently */
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
	int once_only = TRUE;
	past_tense_action_record *pta;
	LOOP_OVER(pta, past_tense_action_record) {
		current_sentence = pta->where_pta_tested; /* ensure problems reported correctly */
		packaging_state save = Routines::begin(pta->pta_iname);

		Emit::inv_primitive(if_interp);
		Emit::down();
			Chronology::ap_compile_forced_to_present(pta->historic_action);
			Emit::code();
			Emit::down();
				Emit::rtrue();
			Emit::up();
		Emit::up();
		Emit::rfalse();

		if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
			once_only = FALSE;
			Problems::Issue::sentence_problem(_p_(PM_PastTableLookup),
				"it's not safe to look up table entries in a way referring "
				"to past history",
				"because it leads to dangerous ambiguities. For instance, "
				"does 'taking an item listed in the Table of Treasure "
				"for the first time' mean that this is the first time taking "
				"any of the things in the table, or only the first time "
				"this one? And so on.");
		}

		Routines::end(save);
	}
	Emit::named_array_begin(InterNames::iname(PastActionsI6Routines_INAME), K_value);
	LOOP_OVER(pta, past_tense_action_record)
		Emit::array_iname_entry(pta->pta_iname);
	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	Emit::array_end();
#endif
}

@ =
void Chronology::past_tenses_i6_escape(void) {
	int once_only = TRUE;
	past_tense_condition_record *ptc;
	LOGIF(TIME_PERIODS,
		"Creating %d past tense conditions in TestSinglePastState\n",
			NUMBER_CREATED(past_tense_condition_record));

	package_request *PR = Packaging::synoptic_resource(CHRONOLOGY_SUBPACKAGE);
	inter_name *iname = Packaging::function(
		InterNames::one_off(I"test_fn", PR),
		PR,
		InterNames::iname(TestSinglePastState_INAME));
	packaging_state save = Routines::begin(iname);
	inter_symbol *past_flag_s = LocalVariables::add_named_call_as_symbol(I"past_flag");
	inter_symbol *pt_s = LocalVariables::add_named_call_as_symbol(I"pt");
	inter_symbol *turn_end_s = LocalVariables::add_named_call_as_symbol(I"turn_end");
	inter_symbol *wanted_s = LocalVariables::add_named_call_as_symbol(I"wanted");
	inter_symbol *old_s = LocalVariables::add_internal_local_as_symbol(I"old");
	inter_symbol *new_s = LocalVariables::add_internal_local_as_symbol(I"new");
	inter_symbol *trips_s = LocalVariables::add_internal_local_as_symbol(I"trips");
	inter_symbol *consecutives_s = LocalVariables::add_internal_local_as_symbol(I"consecutives");
	Frames::determines_the_past();

	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		Emit::val_symbol(K_value, past_flag_s);
		Emit::code();
		Emit::down();
			@<Unpack the past@>;
		Emit::up();
		Emit::code();
		Emit::down();
			@<Unpack the present@>;
			@<Swizzle@>;
			@<Repack the present@>;
		Emit::up();
	Emit::up();

	@<Answer the question posed@>;

	Routines::end(save);
	LOGIF(TIME_PERIODS, "Creation of past tense conditions complete\n");
}

@<Unpack the past@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, new_s);
		Emit::inv_primitive(bitwiseand_interp);
		Emit::down();
			Emit::inv_primitive(lookup_interp);
			Emit::down();
				Emit::val_iname(K_object, InterNames::extern(PASTCHRONOLOGICALRECORD_EXNAMEF));
				Emit::val_symbol(K_value, pt_s);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 1);
		Emit::up();
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, trips_s);
		Emit::inv_primitive(divide_interp);
		Emit::down();
			Emit::inv_primitive(bitwiseand_interp);
			Emit::down();
				Emit::inv_primitive(lookup_interp);
				Emit::down();
					Emit::val_iname(K_object, InterNames::extern(PASTCHRONOLOGICALRECORD_EXNAMEF));
					Emit::val_symbol(K_value, pt_s);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 0xFE);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 2);
		Emit::up();
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, consecutives_s);
		Emit::inv_primitive(divide_interp);
		Emit::down();
			Emit::inv_primitive(bitwiseand_interp);
			Emit::down();
				Emit::inv_primitive(lookup_interp);
				Emit::down();
					Emit::val_iname(K_object, InterNames::extern(PASTCHRONOLOGICALRECORD_EXNAMEF));
					Emit::val_symbol(K_value, pt_s);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 0xFF00);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 0x100);
		Emit::up();
	Emit::up();

@<Unpack the present@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, old_s);
		Emit::inv_primitive(bitwiseand_interp);
		Emit::down();
			Emit::inv_primitive(lookup_interp);
			Emit::down();
				Emit::val_iname(K_object, InterNames::extern(PRESENTCHRONOLOGICALRECORD_EXNAMEF));
				Emit::val_symbol(K_value, pt_s);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 1);
		Emit::up();
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, trips_s);
		Emit::inv_primitive(divide_interp);
		Emit::down();
			Emit::inv_primitive(bitwiseand_interp);
			Emit::down();
				Emit::inv_primitive(lookup_interp);
				Emit::down();
					Emit::val_iname(K_object, InterNames::extern(PRESENTCHRONOLOGICALRECORD_EXNAMEF));
					Emit::val_symbol(K_value, pt_s);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 0xFE);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 2);
		Emit::up();
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, consecutives_s);
		Emit::inv_primitive(divide_interp);
		Emit::down();
			Emit::inv_primitive(bitwiseand_interp);
			Emit::down();
				Emit::inv_primitive(lookup_interp);
				Emit::down();
					Emit::val_iname(K_object, InterNames::extern(PRESENTCHRONOLOGICALRECORD_EXNAMEF));
					Emit::val_symbol(K_value, pt_s);
				Emit::up();
				Emit::val(K_number, LITERAL_IVAL, 0xFF00);
			Emit::up();
			Emit::val(K_number, LITERAL_IVAL, 0x100);
		Emit::up();
	Emit::up();

@<Repack the present@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::inv_primitive(lookupref_interp);
		Emit::down();
			Emit::val_iname(K_object, InterNames::extern(PRESENTCHRONOLOGICALRECORD_EXNAMEF));
			Emit::val_symbol(K_value, pt_s);
		Emit::up();
		Emit::inv_primitive(plus_interp);
		Emit::down();
			Emit::val_symbol(K_value, new_s);
			Emit::inv_primitive(plus_interp);
			Emit::down();
				Emit::inv_primitive(times_interp);
				Emit::down();
					Emit::val_symbol(K_value, trips_s);
					Emit::val(K_number, LITERAL_IVAL, 0x02);
				Emit::up();
				Emit::inv_primitive(times_interp);
				Emit::down();
					Emit::val_symbol(K_value, consecutives_s);
					Emit::val(K_number, LITERAL_IVAL, 0x100);
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

@<Swizzle@> =
	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, pt_s);
		Emit::code();
		Emit::down();
			LOOP_OVER(ptc, past_tense_condition_record) {
				current_sentence = ptc->where_ptc_tested; /* ensure problems reported correctly */
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) (ptc->allocation_id));
					Emit::code();
					Emit::down();
						BEGIN_COMPILATION_MODE;
						COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
						@<Compile code to set the new state of the condition, as measured in the present@>;
						END_COMPILATION_MODE;
						if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
							once_only = FALSE;
							Problems::Issue::sentence_problem(_p_(PM_PastTableEntries),
								"it's not safe to look up table entries in a way referring "
								"to past history",
								"because it leads to dangerous ambiguities. For instance, "
								"does 'taking an item listed in the Table of Treasure "
								"for the first time' mean that this is the first time taking "
								"any of the things in the table, or only the first time "
								"this one? And so on.");
						}
					Emit::up();
				Emit::up();
			}
			Emit::inv_primitive(default_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I"*** No such past tense condition ***\n");
					Emit::up();
					Emit::inv_primitive(store_interp);
					Emit::down();
						Emit::ref_symbol(K_value, new_s);
						Emit::val(K_number, LITERAL_IVAL, 0);
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(ifelse_interp);
	Emit::down();
		Emit::val_symbol(K_value, new_s);
		Emit::code();
		Emit::down();
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, old_s);
					Emit::val(K_truth_state, LITERAL_IVAL, 0);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(postincrement_interp);
					Emit::down();
						Emit::ref_symbol(K_value, trips_s);
					Emit::up();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(gt_interp);
						Emit::down();
							Emit::val_symbol(K_value, trips_s);
							Emit::val(K_number, LITERAL_IVAL, 127);
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(store_interp);
							Emit::down();
								Emit::ref_symbol(K_value, trips_s);
								Emit::val(K_number, LITERAL_IVAL, 127);
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();

			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::val_symbol(K_value, turn_end_s);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(postincrement_interp);
					Emit::down();
						Emit::ref_symbol(K_value, consecutives_s);
					Emit::up();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(gt_interp);
						Emit::down();
							Emit::val_symbol(K_value, consecutives_s);
							Emit::val(K_number, LITERAL_IVAL, 127);
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(store_interp);
							Emit::down();
								Emit::ref_symbol(K_value, consecutives_s);
								Emit::val(K_number, LITERAL_IVAL, 127);
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();

		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, consecutives_s);
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
	Emit::up();

@ The following goes through the dance of writing to a temporary stream in
order to ensure that the compilation happens in a memory stream, rather than
a file stream, thus allowing rewinding:

@<Compile code to set the new state of the condition, as measured in the present@> =
	if (ptc->condition) {
		parse_node *spec = ptc->condition;
		LOGIF(TIME_PERIODS, "Number %d: proposition $D\n",
			ptc->allocation_id, Specifications::to_proposition(spec));
		if (Calculus::Propositions::contains_callings(Specifications::to_proposition(spec))) {
			Problems::Issue::sentence_problem(_p_(PM_PastCallings),
				"it's not safe to use '(called ...)' in a way referring "
				"to past history",
				"because this would make a temporary value to hold the "
				"quantity in question, but at a different time from when "
				"it would be needed.");
		} else {
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, new_s);
				Specifications::Compiler::emit_as_val(K_value, spec);
			Emit::up();
		}
	} else {
		#ifdef IF_MODULE
		LOG("Picked up past $A\n", ptc->ap_to_test);
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, new_s);
			PL::Actions::Patterns::emit_past_tense(ptc->ap_to_test);
		Emit::up();
		#endif
	}

@<Answer the question posed@> =
	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, wanted_s);
		Emit::code();
		Emit::down();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 0);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::val_symbol(K_value, new_s);
						Emit::code();
						Emit::down();
							Emit::inv_primitive(return_interp);
							Emit::down();
								Emit::val_symbol(K_value, new_s);
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 1);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::val_symbol(K_value, new_s);
						Emit::code();
						Emit::down();
							Emit::inv_primitive(return_interp);
							Emit::down();
								Emit::val_symbol(K_value, trips_s);
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 2);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::val_symbol(K_value, new_s);
						Emit::code();
						Emit::down();
							Emit::inv_primitive(return_interp);
							Emit::down();
								Emit::inv_primitive(plus_interp); /* Plus one because we count the current turn */
								Emit::down();
									Emit::val_symbol(K_value, consecutives_s);
									Emit::val(K_number, LITERAL_IVAL, 1);
								Emit::up();
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 4);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val_symbol(K_value, new_s);
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 5);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val_symbol(K_value, trips_s);
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(case_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 6);
				Emit::code();
				Emit::down();
					Emit::inv_primitive(return_interp);
					Emit::down();
						Emit::val_symbol(K_value, consecutives_s);
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, 0);
	Emit::up();

@ The |{-E}| ("extents") escape.
Sizes for the arrays. We need to do these after compiling the code in the
escapes above, because they might continue to spawn each other as they
compile: e.g. a past tense action pattern might itself refer to a condition
in the still more remote past, as in the case of "After switching on the
lunar clock when the lunar clock has been switched on for more than five
times".

=
void Chronology::chronology_extents_i6_escape(void) {
	package_request *PR = Packaging::synoptic_resource(CHRONOLOGY_SUBPACKAGE);
	inter_name *iname1 = InterNames::one_off(I"NO_PAST_TENSE_CONDS", PR);
	inter_name *iname2 = InterNames::one_off(I"NO_PAST_TENSE_ACTIONS", PR);
	packaging_state save = Packaging::enter(PR);
	Emit::named_numeric_constant(iname1, (inter_t) no_past_tenses);
	Emit::named_numeric_constant(iname2, (inter_t) no_past_actions);
	Packaging::exit(save);
}
