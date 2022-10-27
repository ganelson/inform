[StandardsElement::] Standards Element.

To write the Standards element (St) in the index.

@ This is essentially a trawl through the more popular rulebooks, showing
their contents in logical order.

=
void StandardsElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->rulebook_nodes, MakeSynopticModuleStage::module_order);
	InterNodeList::array_sort(inv->activity_nodes, MakeSynopticModuleStage::module_order);

	@<Index the segment for the main action rulebooks@>;
	@<Index the segment for the sequence of play rulebooks@>;
	@<Index the segment for the Understanding rulebooks@>;
	@<Index the segment for the description rulebooks@>;
	@<Index the segment for the accessibility rulebooks@>;
	@<Index the segment for the light and darkness rulebooks@>;
	@<Index the segment for the top-level rulebooks@>;
	@<Index the segment for the action processing rulebooks@>;
	@<Index the segment for the responses@>;
}

@<Index the segment for the top-level rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.TopLevelHeading", I"Index.Elements.St.TopLevelRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.StartupRules", NULL,
		IndexRules::find_rulebook(inv, I"STARTUP_RB"), NULL, 1, TRUE, session);
	StandardsElement::activity(OUT, inv, I"STARTING_VIRTUAL_MACHINE_ACT", 2, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_BANNER_TEXT_ACT", 2, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.TurnSequenceRules", NULL,
		IndexRules::find_rulebook(inv, I"TURN_SEQUENCE_RB"), NULL, 1, TRUE, session);
	StandardsElement::activity(OUT, inv, I"CONSTRUCTING_STATUS_LINE_ACT", 2, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ShutdownRules", NULL,
		IndexRules::find_rulebook(inv, I"SHUTDOWN_RB"), NULL, 1, TRUE, session);
	StandardsElement::activity(OUT, inv, I"AMUSING_A_VICTORIOUS_PLAYER_ACT", 2, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_PLAYERS_OBITUARY_ACT", 2, session);
	StandardsElement::activity(OUT, inv, I"DEALING_WITH_FINAL_QUESTION_ACT", 2, session);

@<Index the segment for the sequence of play rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.SequenceHeading", I"Index.Elements.St.SequenceRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.WhenPlayBegins", I"rules_wpb",
		IndexRules::find_rulebook(inv, I"WHEN_PLAY_BEGINS_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.EveryTurn", I"rules_et",
		IndexRules::find_rulebook(inv, I"every_turn"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.WhenPlayEnds", I"rules_wpe",
		IndexRules::find_rulebook(inv, I"WHEN_PLAY_ENDS_RB"), NULL, 1, TRUE, session);

@<Index the segment for the Understanding rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.UnderstoodHeading", I"Index.Elements.St.UnderstoodRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.DoesThePlayerMean", I"rules_dtpm",
		IndexRules::find_rulebook(inv, I"DOES_THE_PLAYER_MEAN_RB"), NULL, 1, TRUE, session);
	StandardsElement::activity(OUT, inv, I"READING_A_COMMAND_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"DECIDING_SCOPE_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"DECIDING_CONCEALED_POSSESS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"DECIDING_WHETHER_ALL_INC_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"CLARIFYING_PARSERS_CHOICE_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"ASKING_WHICH_DO_YOU_MEAN_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_A_PARSER_ERROR_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"SUPPLYING_A_MISSING_NOUN_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"SUPPLYING_A_MISSING_SECOND_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"IMPLICITLY_TAKING_ACT", 1, session);

@<Index the segment for the main action rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ActionsHeading", I"Index.Elements.St.ActionsRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Persuasion", I"rules_per",
		IndexRules::find_rulebook(inv, I"PERSUADE_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.UnsuccessfulAttemptBy", I"rules_fail",
		IndexRules::find_rulebook(inv, I"UNSUCCESSFUL_ATTEMPT_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Before", I"rules_before",
		IndexRules::find_rulebook(inv, I"BEFORE_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Instead", I"rules_instead",
		IndexRules::find_rulebook(inv, I"INSTEAD_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Check", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.CheckRules"), 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.CarryOut", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.CarryOutRules"), 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.After", I"rules_after",
		IndexRules::find_rulebook(inv, I"AFTER_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Report", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.ReportRules"), 1, TRUE, session);

@<Index the segment for the action processing rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ProcessingHeading", I"Index.Elements.St.ProcessingRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ActionProcessingRules", NULL,
		IndexRules::find_rulebook(inv, I"ACTION_PROCESSING_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.SpecificActionProcessingRules", NULL,
		IndexRules::find_rulebook(inv, I"SPECIFIC_ACTION_PROCESSING_RB"), NULL, 2, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.PlayersActionAwarenessRules", NULL,
		IndexRules::find_rulebook(inv, I"PLAYERS_ACTION_AWARENESS_RB"), NULL, 3, TRUE, session);

@<Index the segment for the responses@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ResponsesHeading", I"Index.Elements.St.ResponsesRubric");
	StandardsElement::activity(OUT, inv, I"PRINTING_RESPONSE_ACT", 1, session);

@<Index the segment for the accessibility rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.AccessibilityHeading", I"Index.Elements.St.AccessibilityRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ReachingInside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"REACHING_INSIDE_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ReachingOutside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"REACHING_OUTSIDE_RB"), NULL, 1, TRUE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Visibility", I"visibility",
		IndexRules::find_rulebook(inv, I"VISIBLE_RB"), NULL, 1, TRUE, session);

@<Index the segment for the light and darkness rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.LightHeading", I"Index.Elements.St.LightRubric");
	StandardsElement::activity(OUT, inv, I"PRINTING_NAME_OF_DARK_ROOM_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_DESC_OF_DARK_ROOM_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_NEWS_OF_DARKNESS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_NEWS_OF_LIGHT_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"REFUSAL_TO_ACT_IN_DARK_ACT", 1, session);

@<Index the segment for the description rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.DescriptionHeading", I"Index.Elements.St.DescriptionRubric");
	StandardsElement::activity(OUT, inv, I"PRINTING_THE_NAME_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_THE_PLURAL_NAME_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_A_NUMBER_OF_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_ROOM_DESC_DETAILS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_INVENTORY_DETAILS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"LISTING_CONTENTS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"GROUPING_TOGETHER_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"WRITING_A_PARAGRAPH_ABOUT_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"LISTING_NONDESCRIPT_ITEMS_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_LOCALE_DESCRIPTION_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"CHOOSING_NOTABLE_LOCALE_OBJ_ACT", 1, session);
	StandardsElement::activity(OUT, inv, I"PRINTING_LOCALE_PARAGRAPH_ACT", 1, session);

@ =
void StandardsElement::subhead(OUTPUT_STREAM, localisation_dictionary *LD,
	text_stream *heading_key, text_stream *rubric_key) {
	HTML_OPEN("p"); Localisation::bold(OUT, LD, heading_key); HTML_CLOSE("p");
	HTML_OPEN("p"); Localisation::roman(OUT, LD, rubric_key); HTML_CLOSE("p");
}

void StandardsElement::activity(OUTPUT_STREAM, tree_inventory *inv, text_stream *id,
	int indent, index_session *session) {
	inter_package *av = IndexRules::find_activity(inv, id);
	if (av) IndexRules::activity_box(OUT, inv->of_tree, av, indent, session);
}
