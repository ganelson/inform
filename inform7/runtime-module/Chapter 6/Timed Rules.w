[RTTimedRules::] Timed Rules.

Code to support rules like "At 12:03AM: ...".

@ 

=
void RTTimedRules::annotate_rules(void) {
	rule *R;
	LOOP_OVER(R, rule) {
		imperative_defn *id = R->defn_as_I7_source;
		if (id) {
			int t = TimedRules::get_timing_of_event(id);
			if (t == NOT_A_TIMED_EVENT) continue;
			Hierarchy::apply_metadata_from_number(R->compilation_data.rule_package,
				RULE_TIMED_METADATA_HL, 1);
			if (t != NO_FIXED_TIME)
				Hierarchy::apply_metadata_from_number(R->compilation_data.rule_package,
					RULE_TIMED_FOR_METADATA_HL, (inter_ti) t);
		}
	}
}
