[RTActivities::] Activities.

To compile the activities submodule for a compilation unit, which contains
_activity packages.

@h Compilation data.
Each |activity| object contains this data:

=
typedef struct activity_compilation_data {
	int translated;
	struct text_stream *translated_name;
	struct package_request *av_package; /* its |_activity| package */
	struct inter_name *value_iname;     /* an identifier for a constant identifying this */
	struct inter_name *translated_iname; /* an alias useful for linking purposes */
	struct inter_name *variables_id;    /* ID for the shared variables set, if any */
	struct wording av_documentation_symbol; /* cross-reference to HTML documentation, if any */
	struct activity_crossref *cross_references;
} activity_compilation_data;

typedef struct activity_crossref {
	struct id_body *rule_dependent;
	struct activity_crossref *next;
} activity_crossref;

@ Which is created, long before compilation time, thus:

=
activity_compilation_data RTActivities::new_compilation_data(activity *av, wording doc) {
	activity_compilation_data acd;
	acd.translated = FALSE;
	acd.translated_name = NULL;
	acd.av_package = Hierarchy::local_package(ACTIVITIES_HAP);
	acd.value_iname = Hierarchy::make_iname_with_memo(ACTIVITY_VALUE_HL, acd.av_package, av->name);
	acd.translated_iname = NULL;
	acd.variables_id = Hierarchy::make_iname_in(ACTIVITY_SHV_ID_HL, acd.av_package);
	acd.av_documentation_symbol = doc;
	acd.cross_references = NULL;
	return acd;
}

@ Regarded as an rvalue, an activity compiles to this:

=
inter_name *RTActivities::iname(activity *av) {
	return av->compilation_data.value_iname;
}

inter_name *RTActivities::id_translated(activity *av) {
	if (Str::len(av->compilation_data.translated_name) == 0) return NULL;
	if (av->compilation_data.translated_iname == NULL) {
		av->compilation_data.translated_iname = InterNames::explicitly_named(
			av->compilation_data.translated_name, av->compilation_data.av_package);
		Hierarchy::make_available(av->compilation_data.translated_iname);
	}
	return av->compilation_data.translated_iname;
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

@ =
void RTActivities::annotate_list_for_cross_references(activity_list *avl, id_body *idb) {
	for (; avl; avl = avl->next)
		if (avl->activity) {
			activity *av = avl->activity;
			activity_crossref *acr = CREATE(activity_crossref);
			acr->next = av->compilation_data.cross_references;
			av->compilation_data.cross_references = acr;
			acr->rule_dependent = idb;
		}
}

@ =
void RTActivities::translate(activity *av, wording W) {
	if (av->compilation_data.translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatesActivityAlready),
			"this activity has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	av->compilation_data.translated = TRUE;
	av->compilation_data.translated_name = Str::new();
	WRITE_TO(av->compilation_data.translated_name, "%N", Wordings::first_wn(W));
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
	inter_name *translated = RTActivities::id_translated(av);
	if (translated) Emit::iname_constant(translated, K_value, iname);

	Emit::iname_constant(av->compilation_data.value_iname, K_value, iname);

	Hierarchy::apply_metadata_from_wording(pack, ACTIVITY_NAME_MD_HL, av->name);
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_AT_MD_HL,
		(inter_ti) Wordings::first_wn(av->name));

	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_BEFORE_MD_HL,
		RTRulebooks::id_iname(av->before_rules));
	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_FOR_MD_HL,
		RTRulebooks::id_iname(av->for_rules));
	Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_AFTER_MD_HL,
		RTRulebooks::id_iname(av->after_rules));
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_UFA_MD_HL,
		(inter_ti) Activities::used_by_future_actions(av));
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_HID_MD_HL,
		(inter_ti) Activities::hide_in_debugging(av));

	int empty = TRUE;
	if (Rulebooks::is_empty(av->before_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->for_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->after_rules) == FALSE) empty = FALSE;
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_EMPTY_MD_HL,
		(inter_ti) empty);
	if (Wordings::nonempty(av->compilation_data.av_documentation_symbol))
		Hierarchy::apply_metadata_from_raw_wording(pack, ACTIVITY_DOCUMENTATION_MD_HL,
			Wordings::one_word(Wordings::first_wn(av->compilation_data.av_documentation_symbol)));
	
	if (SharedVariables::set_empty(av->activity_variables) == FALSE) {
		inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_VARC_FN_HL, pack);
		RTSharedVariables::compile_creator_fn(av->activity_variables, iname);
		Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_VAR_CREATOR_MD_HL, iname);
	}
	Emit::numeric_constant(av->compilation_data.variables_id, 0);

	activity_crossref *acr;
	for (acr = av->compilation_data.cross_references; acr; acr = acr->next) {
		id_body *idb = acr->rule_dependent;
		if ((ImperativeDefinitions::body_at(idb)) &&
			(Wordings::nonempty(Node::get_text(ImperativeDefinitions::body_at(idb))))) {
			package_request *EP =
				Hierarchy::package_within(ACTIVITY_XREFS_HAP, pack);
			Hierarchy::apply_metadata_from_raw_wording(EP, XREF_TEXT_MD_HL,
				Node::get_text(ImperativeDefinitions::body_at(idb)));
			Hierarchy::apply_metadata_from_number(EP, XREF_AT_MD_HL,
				(inter_ti) Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
		}
	}

	text_stream *marker = av->compilation_data.translated_name;
	if (Str::len(marker) > 0) Hierarchy::apply_metadata(pack, ACTIVITY_INDEX_ID_MD_HL, marker);
}
