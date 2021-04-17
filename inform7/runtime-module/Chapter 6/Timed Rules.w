[RTTimedRules::] Timed Rules.

Code to support rules like "At 12:03AM: ...".

@ Timed events are stored in two simple arrays, processed by run-time code.

=
void RTTimedRules::TimedEventsTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTSTABLE_HL);
	packaging_state save = EmitArrays::begin_table(iname, K_value);
	int when_count = 0;
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else EmitArrays::iname_entry(CompileImperativeDefn::iname(idb));
	}

	for (int i=0; i<when_count+1; i++) {
		EmitArrays::numeric_entry(0);
		EmitArrays::numeric_entry(0);
	}
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTTimedRules::TimedEventTimesTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTTIMESTABLE_HL);
	packaging_state save = EmitArrays::begin_table(iname, K_number);
	int when_count = 0;
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else EmitArrays::numeric_entry((inter_ti) t);
	}

	for (int i=0; i<when_count+1; i++) {
		EmitArrays::numeric_entry(0);
		EmitArrays::numeric_entry(0);
	}
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}
