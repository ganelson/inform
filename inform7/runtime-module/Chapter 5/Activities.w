[RTActivities::] Activities.

To write support code for activities.

@

=
typedef struct activity_compilation_data {
	struct package_request *av_package;
	struct inter_name *av_iname; /* an identifier for a constant identifying this */
	struct inter_name *variables_id; /* for the shared variables set */
} activity_compilation_data;

@

=
activity_compilation_data RTActivities::new_compilation_data(activity *av) {
	activity_compilation_data acd;
	acd.av_package = Hierarchy::local_package(ACTIVITIES_HAP);
	Hierarchy::apply_metadata_from_wording(acd.av_package, ACTIVITY_NAME_METADATA_HL, av->name);
	acd.av_iname = Hierarchy::make_iname_with_memo(ACTIVITY_HL, acd.av_package, av->name);
	acd.variables_id = Hierarchy::make_iname_in(ACTIVITY_SHV_ID_HL, acd.av_package);
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

void RTActivities::activity_var_creators(void) {
	activity *av;
	LOOP_OVER(av, activity) {
		inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_ID_HL, av->compilation_data.av_package);
		Emit::numeric_constant(iname, 0);
		Emit::iname_constant(av->compilation_data.av_iname, K_value, iname);
		Hierarchy::apply_metadata_from_iname(av->compilation_data.av_package, ACTIVITY_BEFORE_METADATA_HL,
			av->before_rules->compilation_data.rb_id_iname);
		Hierarchy::apply_metadata_from_iname(av->compilation_data.av_package, ACTIVITY_FOR_METADATA_HL,
			av->for_rules->compilation_data.rb_id_iname);
		Hierarchy::apply_metadata_from_iname(av->compilation_data.av_package, ACTIVITY_AFTER_METADATA_HL,
			av->after_rules->compilation_data.rb_id_iname);
		int ufa = Rulebooks::used_by_future_actions(av->before_rules);
		Hierarchy::apply_metadata_from_number(av->compilation_data.av_package, ACTIVITY_UFA_METADATA_HL, (inter_ti) ufa);

		if (SharedVariables::set_empty(av->activity_variables) == FALSE) {
			inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_STV_CREATOR_FN_HL, av->compilation_data.av_package);
			RTVariables::set_shared_variables_creator(av->activity_variables, iname);
			RTVariables::compile_frame_creator(av->activity_variables);
			Hierarchy::apply_metadata_from_iname(av->compilation_data.av_package, ACTIVITY_VARC_METADATA_HL,
				iname);
		}
		Emit::numeric_constant(av->compilation_data.variables_id, 0);
	}
}
