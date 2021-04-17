[RTActivities::] Activities.

To write support code for activities.

@

=
typedef struct activity_compilation_data {
	struct package_request *av_package;
	struct inter_name *av_iname; /* an identifier for a constant identifying this */
} activity_compilation_data;

@

=
activity_compilation_data RTActivities::new_compilation_data(activity *av) {
	activity_compilation_data acd;
	acd.av_package = Hierarchy::local_package(ACTIVITIES_HAP);
	Hierarchy::markup_wording(acd.av_package, ACTIVITY_NAME_HMD, av->name);
	acd.av_iname = Hierarchy::make_iname_with_memo(ACTIVITY_HL, acd.av_package, av->name);
	Emit::numeric_constant(acd.av_iname, (inter_ti) av->allocation_id);
	return acd;
}

package_request *RTActivities::rulebook_package(activity *av, int N) {
	switch (N) {
		case 0: return Hierarchy::make_package_in(BEFORE_RB_HL, av->compilation_data.av_package);
		case 1: return Hierarchy::make_package_in(FOR_RB_HL, av->compilation_data.av_package);
		case 2: return Hierarchy::make_package_in(AFTER_RB_HL, av->compilation_data.av_package);
	}
	internal_error("bad activity rulebook");
	return NULL;
}

inter_name *RTActivities::iname(activity *av) {
	return av->compilation_data.av_iname;
}

void RTActivities::emit_activity_list(activity_list *al) {
	int negate_me = FALSE, downs = 0;
	if (al->ACL_parity == FALSE) negate_me = TRUE;
	if (negate_me) { EmitCode::inv(NOT_BIP); EmitCode::down(); downs++; }

	int cl = 0;
	for (activity_list *k = al; k; k = k->next) cl++;

	int ncl = 0;
	while (al != NULL) {
		if (++ncl < cl) {
			EmitCode::inv(OR_BIP);
			EmitCode::down();
			downs++;
		}
		if (al->activity != NULL) {
			EmitCode::call(Hierarchy::find(TESTACTIVITY_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, al->activity->compilation_data.av_iname);
				if (al->acting_on) {
					if (Specifications::is_description(al->acting_on)) {
						EmitCode::val_iname(K_value,
							Deferrals::function_to_test_description(al->acting_on));
					} else {
						EmitCode::val_number(0);
						CompileValues::to_code_val(al->acting_on);
					}
				}
			EmitCode::up();
		}
		else {
			CompileValues::to_code_val(al->only_when);
		}
		al = al->next;
	}

	while (downs > 0) { EmitCode::up(); downs--; }
}

void RTActivities::arrays(void) {
	RTActivities::Activity_before_rulebooks_array();
	RTActivities::Activity_for_rulebooks_array();
	RTActivities::Activity_after_rulebooks_array();
	RTActivities::Activity_atb_rulebooks_array();
}

void RTActivities::Activity_before_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_BEFORE_RULEBOOKS_HL);
	packaging_state save = EmitArrays::begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		EmitArrays::numeric_entry((inter_ti) av->before_rules->allocation_id);
		i++;
	}
	if (i==0) EmitArrays::null_entry();
	EmitArrays::null_entry();
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTActivities::Activity_for_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_FOR_RULEBOOKS_HL);
	packaging_state save = EmitArrays::begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		EmitArrays::numeric_entry((inter_ti) av->for_rules->allocation_id);
		i++;
	}
	if (i==0) EmitArrays::null_entry();
	EmitArrays::null_entry();
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTActivities::Activity_after_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_AFTER_RULEBOOKS_HL);
	packaging_state save = EmitArrays::begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		EmitArrays::numeric_entry((inter_ti) av->after_rules->allocation_id);
		i++;
	}
	if (i==0) EmitArrays::null_entry();
	EmitArrays::null_entry();
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTActivities::Activity_atb_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_ATB_RULEBOOKS_HL);
	packaging_state save = EmitArrays::begin_byte(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		EmitArrays::numeric_entry((inter_ti) Rulebooks::used_by_future_actions(av->before_rules));
		i++;
	}
	if (i==0) EmitArrays::numeric_entry(255);
	EmitArrays::numeric_entry(255);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}

void RTActivities::activity_var_creators(void) {
	activity *av;
	LOOP_OVER(av, activity) {
		if (SharedVariables::set_empty(av->activity_variables) == FALSE) {
			inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_STV_CREATOR_FN_HL, av->compilation_data.av_package);
			RTVariables::set_shared_variables_creator(av->activity_variables, iname);
			RTVariables::compile_frame_creator(av->activity_variables);
		}
	}

	inter_name *iname = Hierarchy::find(ACTIVITY_VAR_CREATORS_HL);
	packaging_state save = EmitArrays::begin(iname, K_value);
	int c = 0;
	LOOP_OVER(av, activity) {
		if (SharedVariables::set_empty(av->activity_variables)) EmitArrays::numeric_entry(0);
		else EmitArrays::iname_entry(RTVariables::get_shared_variables_creator(av->activity_variables));
		c++;
	}
	EmitArrays::numeric_entry(0);
	if (c == 0) EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}
