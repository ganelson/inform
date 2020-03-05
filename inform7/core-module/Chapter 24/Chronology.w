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
	package_request *PR = Hierarchy::local_package(PAST_ACTION_PATTERNS_HAP);
	inter_name *pta_routine = Hierarchy::make_iname_in(PAP_FN_HL, PR);
	LOGIF(TIME_PERIODS,
		"Chronology::compile_past_action_pattern on: $A\nat: $t\n", &ap, &duration);
	if (PL::Actions::Patterns::makes_callings(&ap)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PTAPMakesCallings),
			"a description of an action cannot both refer to past history "
			"and also use '(called ...)'",
			"because that would require Inform in general to remember "
			"too much information about past events.");
	}
	if (too_late_for_past_tenses) internal_error("too late for a PAP");
	if (op == NULL) op = "==";

	Produce::inv_primitive(Emit::tree(), AND_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), INDIRECT0_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, pta_routine);
		Produce::up(Emit::tree());

	int L = duration.length; if (L < 0) L = 0;
	if (duration.until >= 0) {
		if (duration.units == TIMES_UNIT) {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LE_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) L);
					Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), GE_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) duration.until);
						Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LE_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) L);
					Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), GE_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) duration.until);
					Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	} else {
		if (duration.units == TIMES_UNIT) {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
				@<Emit the op@>;
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TIMESACTIONHASHAPPENED_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
					Produce::up(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) L);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ACTIONCURRENTLYHAPPENINGFLAG_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		} else {
			@<Emit the op@>;
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(TURNSACTIONHASBEENHAPPENING_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_actions);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) L);
			Produce::up(Emit::tree());
		}
	}
	Produce::up(Emit::tree());

	past_tense_action_record *pta = CREATE(past_tense_action_record);
	pta->where_pta_tested = current_sentence;
	pta->historic_action = ap;
	pta->pta_iname = pta_routine;
	no_past_actions++;
}
#endif

@<Emit the op@> =
	if (strcmp(op, "==") == 0) Produce::inv_primitive(Emit::tree(), EQ_BIP);
	else if (strcmp(op, "~=") == 0) Produce::inv_primitive(Emit::tree(), NE_BIP);
	else if (strcmp(op, ">") == 0) Produce::inv_primitive(Emit::tree(), GT_BIP);
	else if (strcmp(op, ">=") == 0) Produce::inv_primitive(Emit::tree(), GE_BIP);
	else if (strcmp(op, "<") == 0) Produce::inv_primitive(Emit::tree(), LT_BIP);
	else if (strcmp(op, "<=") == 0) Produce::inv_primitive(Emit::tree(), LE_BIP);
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
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NoMoreRonNewcombMoment),
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
		Produce::down(Emit::tree());
	}
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTSINGLEPASTSTATE_HL));
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) past_flag);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) no_past_tenses);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (output_wanted + 4*perfect_flag));
	Produce::up(Emit::tree());
	if (operate) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) duration.length);
		Produce::up(Emit::tree());
	}

	if (no_past_tenses >= 1024) { /* limit imposed by the Z-machine implementation */
		Problems::Issue::limit_problem(Task::syntax_tree(), _p_(Untestable), /* well, not conveniently */
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

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Chronology::ap_compile_forced_to_present(pta->historic_action);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::rtrue(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::rfalse(Emit::tree());

		if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
			once_only = FALSE;
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableLookup),
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
	inter_name *iname = Hierarchy::find(PASTACTIONSI6ROUTINES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	LOOP_OVER(pta, past_tense_action_record)
		Emit::array_iname_entry(pta->pta_iname);
	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
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

	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, past_flag_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			@<Unpack the past@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			@<Unpack the present@>;
			@<Swizzle@>;
			@<Repack the present@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	@<Answer the question posed@>;

	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
	LOGIF(TIME_PERIODS, "Creation of past tense conditions complete\n");
}

@<Unpack the past@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, new_s);
		Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
				Produce::val_symbol(Emit::tree(), K_value, pt_s);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, trips_s);
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
					Produce::val_symbol(Emit::tree(), K_value, pt_s);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0xFE);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, consecutives_s);
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PAST_CHRONOLOGICAL_RECORD_HL));
					Produce::val_symbol(Emit::tree(), K_value, pt_s);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0xFF00);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0x100);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Unpack the present@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, old_s);
		Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
				Produce::val_symbol(Emit::tree(), K_value, pt_s);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, trips_s);
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
					Produce::val_symbol(Emit::tree(), K_value, pt_s);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0xFE);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, consecutives_s);
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
					Produce::val_symbol(Emit::tree(), K_value, pt_s);
				Produce::up(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0xFF00);
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0x100);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Repack the present@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PRESENT_CHRONOLOGICAL_RECORD_HL));
			Produce::val_symbol(Emit::tree(), K_value, pt_s);
		Produce::up(Emit::tree());
		Produce::inv_primitive(Emit::tree(), PLUS_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, new_s);
			Produce::inv_primitive(Emit::tree(), PLUS_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, trips_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0x02);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, consecutives_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0x100);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Swizzle@> =
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, pt_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			LOOP_OVER(ptc, past_tense_condition_record) {
				current_sentence = ptc->where_ptc_tested; /* ensure problems reported correctly */
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (ptc->allocation_id));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						BEGIN_COMPILATION_MODE;
						COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
						@<Compile code to set the new state of the condition, as measured in the present@>;
						END_COMPILATION_MODE;
						if ((LocalVariables::are_we_using_table_lookup()) && (once_only)) {
							once_only = FALSE;
							Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PastTableEntries),
								"it's not safe to look up table entries in a way referring "
								"to past history",
								"because it leads to dangerous ambiguities. For instance, "
								"does 'taking an item listed in the Table of Treasure "
								"for the first time' mean that this is the first time taking "
								"any of the things in the table, or only the first time "
								"this one? And so on.");
						}
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), DEFAULT_BIP);
			Produce::down(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						Produce::val_text(Emit::tree(), I"*** No such past tense condition ***\n");
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, new_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, new_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, old_s);
					Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, trips_s);
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), GT_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, trips_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 127);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, trips_s);
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 127);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, turn_end_s);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
					Produce::down(Emit::tree());
						Produce::ref_symbol(Emit::tree(), K_value, consecutives_s);
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), GT_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, consecutives_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 127);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), STORE_BIP);
							Produce::down(Emit::tree());
								Produce::ref_symbol(Emit::tree(), K_value, consecutives_s);
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 127);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, consecutives_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@ The following goes through the dance of writing to a temporary stream in
order to ensure that the compilation happens in a memory stream, rather than
a file stream, thus allowing rewinding:

@<Compile code to set the new state of the condition, as measured in the present@> =
	if (ptc->condition) {
		parse_node *spec = ptc->condition;
		LOGIF(TIME_PERIODS, "Number %d: proposition $D\n",
			ptc->allocation_id, Specifications::to_proposition(spec));
		if (Calculus::Propositions::contains_callings(Specifications::to_proposition(spec))) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PastCallings),
				"it's not safe to use '(called ...)' in a way referring "
				"to past history",
				"because this would make a temporary value to hold the "
				"quantity in question, but at a different time from when "
				"it would be needed.");
		} else {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, new_s);
				Specifications::Compiler::emit_as_val(K_value, spec);
			Produce::up(Emit::tree());
		}
	} else {
		#ifdef IF_MODULE
		LOG("Picked up past $A\n", ptc->ap_to_test);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, new_s);
			PL::Actions::Patterns::emit_past_tense(ptc->ap_to_test);
		Produce::up(Emit::tree());
		#endif
	}

@<Answer the question posed@> =
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, wanted_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, new_s);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, new_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, new_s);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, trips_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, new_s);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), PLUS_BIP); /* Plus one because we count the current turn */
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, consecutives_s);
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 4);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, new_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 5);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, trips_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 6);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, consecutives_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

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
	Hierarchy::make_available(Emit::tree(), iname1);
	Emit::named_numeric_constant(iname1, (inter_t) no_past_tenses);

	inter_name *iname2 = Hierarchy::find(NO_PAST_TENSE_ACTIONS_HL);
	Hierarchy::make_available(Emit::tree(), iname2);
	Emit::named_numeric_constant(iname2, (inter_t) no_past_actions);
}
