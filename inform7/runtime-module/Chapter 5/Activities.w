[RTActivities::] Activities.

To compile the activities submodule for a compilation unit, which contains
_activity packages.

@h Compilation data.
Each |activity| object contains this data:

=
typedef struct activity_compilation_data {
	struct package_request *av_package; /* its |_activity| package */
	struct inter_name *value_iname;     /* an identifier for a constant identifying this */
	struct inter_name *variables_id;    /* ID for the shared variables set, if any */
} activity_compilation_data;

@ Which is created, long before compilation time, thus:

=
activity_compilation_data RTActivities::new_compilation_data(activity *av) {
	activity_compilation_data acd;
	acd.av_package = Hierarchy::local_package(ACTIVITIES_HAP);
	Hierarchy::apply_metadata_from_wording(acd.av_package, ACTIVITY_NAME_MD_HL, av->name);
	acd.value_iname = Hierarchy::make_iname_with_memo(ACTIVITY_VALUE_HL, acd.av_package, av->name);
	acd.variables_id = Hierarchy::make_iname_in(ACTIVITY_SHV_ID_HL, acd.av_package);
	return acd;
}

@ Regarded as an rvalue, an activity compiles to this:

=
inter_name *RTActivities::iname(activity *av) {
	return av->compilation_data.value_iname;
}

@ Three subpackages contain its three rulebooks, requested here:

=
package_request *RTActivities::rulebook_package(activity *av, int N) {
	package_request *pack = av->compilation_data.av_package;
	switch (N) {
		case 0: return Hierarchy::make_package_in(ACTIVITY_BEFORE_RB_HL, pack);
		case 1: return Hierarchy::make_package_in(ACTIVITY_FOR_RB_HL,    pack);
		case 2: return Hierarchy::make_package_in(ACTIVITY_AFTER_RB_HL,  pack);
	}
	internal_error("bad activity rulebook");
	return NULL;
}

@h Compilation.

=
void RTActivities::compile(void) {
	activity *av;
	LOOP_OVER(av, activity) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "activity '%W'", av->name);
		Sequence::queue(&RTActivities::compilation_agent, STORE_POINTER_activity(av), desc);
	}
}

@ So the following makes a single |_activity| package. As noted above, an activity
compiles as a value to its |value_iname|, which will typically have a descriptive
name such as |V_printing_short_title|. But this is equated below to another constant
in the same package, always called |activity_id|. Those ID numbers must all be
distinct at runtime, and this is arranged during linking: for now, we simply
write 0.

=
void RTActivities::compilation_agent(compilation_subtask *t) {
	activity *av = RETRIEVE_POINTER_activity(t->data);
	package_request *pack = av->compilation_data.av_package;

	inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_ID_HL, pack);
	Emit::numeric_constant(iname, 0); /* a placeholder: see above */

	Emit::iname_constant(av->compilation_data.value_iname, K_value, iname);

	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_BEFORE_MD_HL,
		av->before_rules->compilation_data.rb_id_iname);
	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_FOR_MD_HL,
		av->for_rules->compilation_data.rb_id_iname);
	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_AFTER_MD_HL,
		av->after_rules->compilation_data.rb_id_iname);
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_UFA_MD_HL,
		(inter_ti) Rulebooks::used_by_future_actions(av->before_rules));

	if (SharedVariables::set_empty(av->activity_variables) == FALSE) {
		inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_VARC_FN_HL, pack);
		RTVariables::set_shared_variables_creator(av->activity_variables, iname);
		RTVariables::compile_frame_creator(av->activity_variables);
		Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_VAR_CREATOR_MD_HL, iname);
	}
	Emit::numeric_constant(av->compilation_data.variables_id, 0);
}
