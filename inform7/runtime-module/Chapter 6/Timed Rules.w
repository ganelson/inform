[RTTimedRules::] Timed Rules.

Code to support rules like "At 12:03AM: ...".

@ Timed events are stored in two simple arrays, processed by run-time code.

=
void RTTimedRules::TimedEventsTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTSTABLE_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_value);
	int when_count = 0;
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else Emit::array_iname_entry(IDCompilation::iname(idb));
	}

	for (int i=0; i<when_count+1; i++) {
		Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTTimedRules::TimedEventTimesTable(void) {
	inter_name *iname = Hierarchy::find(TIMEDEVENTTIMESTABLE_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_number);
	int when_count = 0;
	id_body *idb;
	LOOP_OVER(idb, id_body) {
		int t = TimedRules::get_timing_of_event(idb->head_of_defn);
		if (t == NOT_A_TIMED_EVENT) continue;
		if (t == NO_FIXED_TIME) when_count++;
		else Emit::array_numeric_entry((inter_ti) t);
	}

	for (int i=0; i<when_count+1; i++) {
		Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}
