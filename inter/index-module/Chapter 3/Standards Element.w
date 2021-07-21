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
	HTML_OPEN("p"); WRITE("<b>The top level</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("An Inform story file spends its whole time working through "
		"these three master rulebooks. They can be altered, just as all "
		"rulebooks can, but it's generally better to leave them alone.");
	HTML_CLOSE("p");

	IndexRules::rulebook_box(OUT, inv, I"Startup rules", NULL,
		IndexRules::find_rulebook(inv, I"startup"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"starting_virtual_machine", 2, LD);
	StandardsElement::activity(OUT, inv, I"printing_banner_text", 2, LD);
	IndexRules::rulebook_box(OUT, inv, I"Turn sequence rules", NULL,
		IndexRules::find_rulebook(inv, I"turn_sequence"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"constructing_status_line", 2, LD);
	IndexRules::rulebook_box(OUT, inv, I"Shutdown rules", NULL,
		IndexRules::find_rulebook(inv, I"shutdown"), NULL, 1, TRUE, LD);
	StandardsElement::activity(OUT, inv, I"amusing_a_victorious_player", 2, LD);
	StandardsElement::activity(OUT, inv, I"printing_players_obituary", 2, LD);
	StandardsElement::activity(OUT, inv, I"dealing_with_final_question", 2, LD);

@<Index the segment for the sequence of play rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Rules added to the sequence of play</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are the best places to put rules timed to happen "
		"at the start, at the end, or once each turn. (Each is run through at "
		"a carefully chosen moment in the relevant top-level rulebook.) It is "
		"also possible to have rules take effect at specific times of day "
		"or when certain events happen. Those are listed in the Scenes index, "
		"alongside rules taking place when scenes begin or end."); HTML_CLOSE("p");
	IndexRules::rulebook_box(OUT, inv, I"When play begins", I"rules_wpb",
		IndexRules::find_rulebook(inv, I"when_play_begins"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Every turn", I"rules_et",
		IndexRules::find_rulebook(inv, I"every_turn"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"When play ends", I"rules_wpe",
		IndexRules::find_rulebook(inv, I"when_play_ends"), NULL, 1, TRUE, LD);

@<Index the segment for the Understanding rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How commands are understood</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("'Understanding' here means turning a typed command, like GET FISH, "
		"into one or more actions, like taking the red herring. This is all handled "
		"by a single large rule (the parse command rule), but that rule makes use "
		"of the following activities and rulebooks in its work."); HTML_CLOSE("p");
	IndexRules::rulebook_box(OUT, inv, I"Does the player mean", I"rules_dtpm",
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
	HTML_OPEN("p"); WRITE("<b>Rules governing actions</b>"); HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("These rules are the ones which tell Inform how actions work, "
		"and which affect how they happen in particular cases.");
	HTML_CLOSE("p");
	IndexRules::rulebook_box(OUT, inv, I"Persuasion", I"rules_per",
		IndexRules::find_rulebook(inv, I"persuasion"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Unsuccessful attempt by", I"rules_fail",
		IndexRules::find_rulebook(inv, I"unsuccessful_attempt_by"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Before", I"rules_before",
		IndexRules::find_rulebook(inv, I"before"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Instead", I"rules_instead",
		IndexRules::find_rulebook(inv, I"instead"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Check", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.Check"), 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Carry out", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.CarryOut"), 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"After", I"rules_after",
		IndexRules::find_rulebook(inv, I"after"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Report", NULL, NULL,
		Localisation::read(LD, I"Index.Elements.St.Report"), 1, TRUE, LD);

@<Index the segment for the action processing rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How actions are processed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These form the technical machinery for dealing with actions, and are "
		"called on at least once every turn. They seldom need to be changed."); HTML_CLOSE("p");
	IndexRules::rulebook_box(OUT, inv, I"Action-processing rules", NULL,
		IndexRules::find_rulebook(inv, I"action_processing"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Specific action-processing rules", NULL,
		IndexRules::find_rulebook(inv, I"specific_action_processing"), NULL, 2, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Player's action awareness rules", NULL,
		IndexRules::find_rulebook(inv, I"players_action_awareness"), NULL, 3, TRUE, LD);

@<Index the segment for the responses@> =
	HTML_OPEN("p"); WRITE("<b>How responses are printed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("The Standard Rules, and some extensions, reply to the player's "
		"commands with messages which are able to be modified."); HTML_CLOSE("p");
	StandardsElement::activity(OUT, inv, I"printing_response", 1, LD);

@<Index the segment for the accessibility rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How accessibility is judged</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are used when deciding who can reach what, and "
		"who can see what."); HTML_CLOSE("p");
	IndexRules::rulebook_box(OUT, inv, I"Reaching inside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"reaching_inside"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Reaching outside", I"rules_ri",
		IndexRules::find_rulebook(inv, I"reaching_outside"), NULL, 1, TRUE, LD);
	IndexRules::rulebook_box(OUT, inv, I"Visibility", I"visibility",
		IndexRules::find_rulebook(inv, I"visibility"), NULL, 1, TRUE, LD);

@<Index the segment for the light and darkness rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Light and darkness</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control how we describe darkness."); HTML_CLOSE("p");
	StandardsElement::activity(OUT, inv, I"printing_name_of_dark_room", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_desc_of_dark_room", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_news_of_darkness", 1, LD);
	StandardsElement::activity(OUT, inv, I"printing_news_of_light", 1, LD);
	StandardsElement::activity(OUT, inv, I"refusal_to_act_in_dark", 1, LD);

@<Index the segment for the description rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How things are described</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control what is printed when naming rooms or "
		"things, and their descriptions."); HTML_CLOSE("p");
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
void StandardsElement::activity(OUTPUT_STREAM, tree_inventory *inv, text_stream *id,
	int indent, localisation_dictionary *LD) {
	inter_package *av = IndexRules::find_activity(inv, id);
	if (av) IndexRules::activity_box(OUT, inv->of_tree, av, indent, LD);
}
