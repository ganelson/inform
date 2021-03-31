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
	Emit::named_numeric_constant(acd.av_iname, (inter_ti) av->allocation_id);
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
	if (negate_me) { Produce::inv_primitive(Emit::tree(), NOT_BIP); Produce::down(Emit::tree()); downs++; }

	int cl = 0;
	for (activity_list *k = al; k; k = k->next) cl++;

	int ncl = 0;
	while (al != NULL) {
		if (++ncl < cl) {
			Produce::inv_primitive(Emit::tree(), OR_BIP);
			Produce::down(Emit::tree());
			downs++;
		}
		if (al->activity != NULL) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTACTIVITY_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, al->activity->compilation_data.av_iname);
				if (al->acting_on) {
					if (Specifications::is_description(al->acting_on)) {
						Produce::val_iname(Emit::tree(), K_value,
							Calculus::Deferrals::compile_deferred_description_test(al->acting_on));
					} else {
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Specifications::Compiler::emit_as_val(K_value, al->acting_on);
					}
				}
			Produce::up(Emit::tree());
		}
		else {
			Specifications::Compiler::emit_as_val(K_value, al->only_when);
		}
		al = al->next;
	}

	while (downs > 0) { Produce::up(Emit::tree()); downs--; }
}

void RTActivities::arrays(void) {
	RTActivities::Activity_before_rulebooks_array();
	RTActivities::Activity_for_rulebooks_array();
	RTActivities::Activity_after_rulebooks_array();
	RTActivities::Activity_atb_rulebooks_array();
}

void RTActivities::Activity_before_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_BEFORE_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->before_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTActivities::Activity_for_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_FOR_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->for_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTActivities::Activity_after_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_AFTER_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->after_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTActivities::Activity_atb_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_ATB_RULEBOOKS_HL);
	packaging_state save = Emit::named_byte_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) Rulebooks::used_by_future_actions(av->before_rules));
		i++;
	}
	if (i==0) Emit::array_numeric_entry(255);
	Emit::array_numeric_entry(255);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTActivities::activity_var_creators(void) {
	activity *av;
	LOOP_OVER(av, activity) {
		if (StackedVariables::set_empty(av->activity_variables) == FALSE) {
			inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_STV_CREATOR_FN_HL, av->compilation_data.av_package);
			StackedVariables::compile_frame_creator(av->activity_variables, iname);
		}
	}

	inter_name *iname = Hierarchy::find(ACTIVITY_VAR_CREATORS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	int c = 0;
	LOOP_OVER(av, activity) {
		if (StackedVariables::set_empty(av->activity_variables)) Emit::array_numeric_entry(0);
		else Emit::array_iname_entry(StackedVariables::frame_creator(av->activity_variables));
		c++;
	}
	Emit::array_numeric_entry(0);
	if (c == 0) Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}
