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
		(inter_ti) Rulebooks::used_by_future_actions(av->before_rules));

	int empty = TRUE;
	if (Rulebooks::is_empty(av->before_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->for_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->after_rules) == FALSE) empty = FALSE;
	Hierarchy::apply_metadata_from_number(pack, ACTIVITY_EMPTY_MD_HL,
		(inter_ti) empty);
	if (Wordings::nonempty(av->indexing_data.av_documentation_symbol))
		Hierarchy::apply_metadata_from_raw_wording(pack, ACTIVITY_DOCUMENTATION_MD_HL,
			Wordings::one_word(Wordings::first_wn(av->indexing_data.av_documentation_symbol)));
	
	if (SharedVariables::set_empty(av->activity_variables) == FALSE) {
		inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_VARC_FN_HL, pack);
		RTSharedVariables::compile_creator_fn(av->activity_variables, iname);
		Hierarchy::apply_metadata_from_iname(pack, ACTIVITY_VAR_CREATOR_MD_HL, iname);
	}
	Emit::numeric_constant(av->compilation_data.variables_id, 0);

	activity_crossref *acr;
	for (acr = av->indexing_data.cross_references; acr; acr = acr->next) {
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

	text_stream *marker = NULL;
	if (av == Activities::std(AMUSING_A_VICTORIOUS_PLAYER_ACT)) marker = I"amusing_a_victorious_player";
	if (av == Activities::std(ASKING_WHICH_DO_YOU_MEAN_ACT)) marker = I"asking_which_do_you_mean";
	if (av == Activities::std(CHOOSING_NOTABLE_LOCALE_OBJ_ACT)) marker = I"choosing_notable_locale_obj";
	if (av == Activities::std(CLARIFYING_PARSERS_CHOICE_ACT)) marker = I"clarifying_parsers_choice";
	if (av == Activities::std(CONSTRUCTING_STATUS_LINE_ACT)) marker = I"constructing_status_line";
	if (av == Activities::std(DEALING_WITH_FINAL_QUESTION_ACT)) marker = I"dealing_with_final_question";
	if (av == Activities::std(DECIDING_CONCEALED_POSSESS_ACT)) marker = I"deciding_concealed_possess";
	if (av == Activities::std(DECIDING_SCOPE_ACT)) marker = I"deciding_scope";
	if (av == Activities::std(DECIDING_WHETHER_ALL_INC_ACT)) marker = I"deciding_whether_all_inc";
	if (av == Activities::std(GROUPING_TOGETHER_ACT)) marker = I"grouping_together";
	if (av == Activities::std(IMPLICITLY_TAKING_ACT)) marker = I"implicitly_taking";
	if (av == Activities::std(LISTING_CONTENTS_ACT)) marker = I"listing_contents";
	if (av == Activities::std(LISTING_NONDESCRIPT_ITEMS_ACT)) marker = I"listing_nondescript_items";
	if (av == Activities::std(PRINTING_A_NUMBER_OF_ACT)) marker = I"printing_a_number_of";
	if (av == Activities::std(PRINTING_A_PARSER_ERROR_ACT)) marker = I"printing_a_parser_error";
	if (av == Activities::std(PRINTING_BANNER_TEXT_ACT)) marker = I"printing_banner_text";
	if (av == Activities::std(PRINTING_DESC_OF_DARK_ROOM_ACT)) marker = I"printing_desc_of_dark_room";
	if (av == Activities::std(PRINTING_INVENTORY_DETAILS_ACT)) marker = I"printing_inventory_details";
	if (av == Activities::std(PRINTING_LOCALE_DESCRIPTION_ACT)) marker = I"printing_locale_description";
	if (av == Activities::std(PRINTING_LOCALE_PARAGRAPH_ACT)) marker = I"printing_locale_paragraph";
	if (av == Activities::std(PRINTING_NAME_OF_DARK_ROOM_ACT)) marker = I"printing_name_of_dark_room";
	if (av == Activities::std(PRINTING_NEWS_OF_DARKNESS_ACT)) marker = I"printing_news_of_darkness";
	if (av == Activities::std(PRINTING_NEWS_OF_LIGHT_ACT)) marker = I"printing_news_of_light";
	if (av == Activities::std(PRINTING_PLAYERS_OBITUARY_ACT)) marker = I"printing_players_obituary";
	if (av == Activities::std(PRINTING_RESPONSE_ACT)) marker = I"printing_response";
	if (av == Activities::std(PRINTING_ROOM_DESC_DETAILS_ACT)) marker = I"printing_room_desc_details";
	if (av == Activities::std(PRINTING_THE_NAME_ACT)) marker = I"printing_the_name";
	if (av == Activities::std(PRINTING_THE_PLURAL_NAME_ACT)) marker = I"printing_the_plural_name";
	if (av == Activities::std(READING_A_COMMAND_ACT)) marker = I"reading_a_command";
	if (av == Activities::std(REFUSAL_TO_ACT_IN_DARK_ACT)) marker = I"refusal_to_act_in_dark";
	if (av == Activities::std(STARTING_VIRTUAL_MACHINE_ACT)) marker = I"starting_virtual_machine";
	if (av == Activities::std(SUPPLYING_A_MISSING_NOUN_ACT)) marker = I"supplying_a_missing_noun";
	if (av == Activities::std(SUPPLYING_A_MISSING_SECOND_ACT)) marker = I"supplying_a_missing_second";
	if (av == Activities::std(WRITING_A_PARAGRAPH_ABOUT_ACT)) marker = I"writing_a_paragraph_about";
	if (marker) Hierarchy::apply_metadata(pack, ACTIVITY_INDEX_ID_MD_HL, marker);
}
