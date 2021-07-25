[StandardsElement::] Standards Element.

To write the Standards element (St) in the index.

@ This is essentially a trawl through the more popular rulebooks, showing
their contents in logical order.

=
void StandardsElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);
	TreeLists::sort(inv->activity_nodes, Synoptic::module_order);

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
		IndexRules::find_rulebook(inv, I"startup"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"starting_virtual_machine", 2, LD);
	StandardsElement::activity(OUT, inv, I"printing_banner_text", 2, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.TurnSequenceRules", NULL,
		IndexRules::find_rulebook(inv, I"turn_sequence"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"constructing_status_line", 2, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ShutdownRules", NULL,
		IndexRules::find_rulebook(inv, I"shutdown"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"amusing_a_victorious_player", 2, LD);
	StandardsElement::activity(OUT, inv, I"printing_players_obituary", 2, LD);
	StandardsElement::activity(OUT, inv, I"dealing_with_final_question", 2, LD);

@<Index the segment for the sequence of play rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.SequenceHeading", I"Index.Elements.St.SequenceRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.WhenPlayBegins", I"rules_wpb",
		IndexRules::find_rulebook(inv, I"when_play_begins"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.EveryTurn", I"rules_et",
		IndexRules::find_rulebook(inv, I"every_turn"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.WhenPlayEnds", I"rules_wpe",
		IndexRules::find_rulebook(inv, I"when_play_ends"), NULL, 1, TRUE, LD);

@<Index the segment for the Understanding rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.UnderstoodHeading", I"Index.Elements.St.UnderstoodRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.DoesThePlayerMean", I"rules_dtpm",
		IndexRules::find_rulebook(inv, I"does_the_player_mean"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"reading_a_command", 1, LD);
	StandardsElement::activity(OUT, inv, I"deciding_scope", 1, LD);
	StandardsElement::activity(OUT, inv, I"deciding_concealed_possess", 1, LD);
	StandardsElement::activity(OUT, inv, I"deciding_whether_all_inc", 1, LD);
	StandardsElement::activity(OUT, inv, I"clarifying_parsers_choice", 1, LD);
	StandardsElement::activity(OUT, inv, I"asking_which_do_you_mean", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_a_parser_error", 1, LD);
	StandardsElement::activity(OUT, inv, I"supplying_a_missing_noun", 1, LD);
	StandardsElement::activity(OUT, inv, I"supplying_a_missing_second", 1, LD);
	StandardsElement::activity(OUT, inv, I"implicitly_taking", 1, LD);

@<Index the segment for the main action rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ActionsHeading", I"Index.Elements.St.ActionsRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Persuasion", I"rules_per",
		IndexRules::find_rulebook(inv, I"persuasion"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.UnsuccessfulAttemptBy", I"rules_fail",
		IndexRules::find_rulebook(inv, I"unsuccessful_attempt_by"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Before", I"rules_before",
		IndexRules::find_rulebook(inv, I"before"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Instead", I"rules_instead",
		IndexRules::find_rulebook(inv, I"instead"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Check", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.CheckRules"), 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.CarryOut", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.CarryOutRules"), 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.After", I"rules_after",
		IndexRules::find_rulebook(inv, I"after"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Report", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.ReportRules"), 1, TRUE, LD);

@<Index the segment for the action processing rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ProcessingHeading", I"Index.Elements.St.ProcessingRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ActionProcessingRules", NULL,
		IndexRules::find_rulebook(inv, I"action_processing"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.SpecificActionProcessingRules", NULL,
		IndexRules::find_rulebook(inv, I"specific_action_processing"), NULL, 2, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.PlayersActionAwarenessRules", NULL,
		IndexRules::find_rulebook(inv, I"players_action_awareness"), NULL, 3, TRUE, LD);

@<Index the segment for the responses@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.ResponsesHeading", I"Index.Elements.St.ResponsesRubric");
	StandardsElement::activity(OUT, inv, I"printing_response", 1, LD);

@<Index the segment for the accessibility rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.AccessibilityHeading", I"Index.Elements.St.AccessibilityRubric");
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ReachingInside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"reaching_inside"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.ReachingOutside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"reaching_outside"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.St.Visibility", I"visibility",
		IndexRules::find_rulebook(inv, I"visibility"), NULL, 1, TRUE, LD);

@<Index the segment for the light and darkness rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.LightHeading", I"Index.Elements.St.LightRubric");
	StandardsElement::activity(OUT, inv, I"printing_name_of_dark_room", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_desc_of_dark_room", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_news_of_darkness", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_news_of_light", 1, LD);
	StandardsElement::activity(OUT, inv, I"refusal_to_act_in_dark", 1, LD);

@<Index the segment for the description rulebooks@> =
	StandardsElement::subhead(OUT, LD,
		I"Index.Elements.St.DescriptionHeading", I"Index.Elements.St.DescriptionRubric");
	StandardsElement::activity(OUT, inv, I"printing_the_name", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_the_plural_name", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_a_number_of", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_room_desc_details", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_inventory_details", 1, LD);
	StandardsElement::activity(OUT, inv, I"listing_contents", 1, LD);
	StandardsElement::activity(OUT, inv, I"grouping_together", 1, LD);
	StandardsElement::activity(OUT, inv, I"writing_a_paragraph_about", 1, LD);
	StandardsElement::activity(OUT, inv, I"listing_nondescript_items", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_locale_description", 1, LD);
	StandardsElement::activity(OUT, inv, I"choosing_notable_locale_obj", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_locale_paragraph", 1, LD);

@ =
void StandardsElement::subhead(OUTPUT_STREAM, localisation_dictionary *LD,
	text_stream *heading_key, text_stream *rubric_key) {
	HTML_OPEN("p"); Localisation::bold(OUT, LD, heading_key); HTML_CLOSE("p");
	HTML_OPEN("p"); Localisation::roman(OUT, LD, rubric_key); HTML_CLOSE("p");
}

void StandardsElement::activity(OUTPUT_STREAM, tree_inventory *inv, text_stream *id,
	int indent, localisation_dictionary *LD) {
	inter_package *av = IndexRules::find_activity(inv, id);
	if (av) IndexRules::activity_box(OUT, inv->of_tree, av, indent, LD);
}
