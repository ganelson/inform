[IXRules::] Rules.

To index rules and rulebooks.

@h Indexing.
Some rules are provided with index text:

=
typedef struct rule_indexing_data {
	struct wording italicised_text; /* when indexing a rulebook */
} rule_indexing_data;

rule_indexing_data IXRules::new_indexing_data(rule *R) {
	rule_indexing_data rid;
	rid.italicised_text = EMPTY_WORDING;
	return rid;
}

void IXRules::set_italicised_index_text(rule *R, wording W) {
	R->indexing_data.italicised_text = W;
}

@ And off we go:

=
int IXRules::index(OUTPUT_STREAM, rule *R, rulebook *owner, rule_context rc) {
	int no_responses_indexed = 0;
	if (Wordings::nonempty(R->indexing_data.italicised_text)) @<Index the italicised text to do with the rule@>;
	if (Wordings::nonempty(R->name)) @<Index the rule name along with Javascript buttons@>;
	if ((Wordings::nonempty(R->indexing_data.italicised_text) == FALSE) &&
		(Wordings::nonempty(R->name) == FALSE) && (R->defn_as_phrase))
		@<Index some text extracted from the first line of the otherwise anonymous rule@>;
	@<Index a link to the first line of the rule's definition@>;
	if (global_compilation_settings.number_rules_in_index) @<Index the small type rule numbering@>;
	@<Index any applicability conditions@>;
	HTML_CLOSE("p");
	@<Index any response texts in the rule@>;
	return no_responses_indexed;
}

@<Index the italicised text to do with the rule@> =
	WRITE("<i>%+W", R->indexing_data.italicised_text);
	#ifdef IF_MODULE
	if (rc.scene_context) {
		WRITE(" during ");
		wording SW = Scenes::get_name(rc.scene_context);
		WRITE("%+W", SW);
	}
	#endif
	WRITE("</i>&nbsp;&nbsp;");

@

@d MAX_PASTEABLE_RULE_NAME_LENGTH 500

@<Index the rule name along with Javascript buttons@> =
	HTML::begin_colour(OUT, I"800000");
	WRITE("%+W", R->name);
	HTML::end_colour(OUT);
	WRITE("&nbsp;&nbsp;");

	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%+W", R->name);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>name</i> ");

	Str::clear(S);
	WRITE_TO(S, "The %W is not listed in the %W rulebook.\n", R->name, owner->primary_name);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>unlist</i>");
	DISCARD_TEXT(S)

	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->responses[l].message) {
			c++;
		}
	if (c > 0) {
		WRITE("&nbsp;&nbsp;");
		Index::extra_link_with(OUT, 1000000+R->allocation_id, "responses");
		WRITE("%d", c);
	}

@<Index any response texts in the rule@> =
	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->responses[l].message) {
			if (c == 0) Index::extra_div_open_nested(OUT, 1000000+R->allocation_id, 2);
			else HTML_TAG("br");
			Strings::index_response(OUT, R, l, R->responses[l].message);
			c++;
		}
	if (c > 0) Index::extra_div_close_nested(OUT);
	no_responses_indexed = c;

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	parse_node *pn = R->defn_as_phrase->declaration_node->down;
	if ((pn) && (Wordings::nonempty(Node::get_text(pn)))) {
		WRITE("(%+W", Node::get_text(pn));
		if (pn->next) WRITE("; ...");
		WRITE(")");
	}

@<Index a link to the first line of the rule's definition@> =
	if (R->defn_as_phrase) {
		parse_node *pn = R->defn_as_phrase->declaration_node;
		if ((pn) && (Wordings::nonempty(Node::get_text(pn))))
			Index::link(OUT, Wordings::first_wn(Node::get_text(pn)));
	}

@<Index the small type rule numbering@> =
	WRITE(" ");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (R->defn_as_phrase) WRITE("%d", R->defn_as_phrase->allocation_id);
	else WRITE("primitive");
	HTML_CLOSE("span");

@<Index any applicability conditions@> =
	applicability_constraint *acl;
	LOOP_OVER_LINKED_LIST(acl, applicability_constraint, R->applicability_constraints) {
		HTML_TAG("br");
		Index::link(OUT, Wordings::first_wn(Node::get_text(acl->where_imposed)));
		WRITE("&nbsp;%+W", Node::get_text(acl->where_imposed));
	}

@h Indexing of lists.
There's a division of labour: here we arrange the index of the rules and
show the linkage between them, while the actual content for each rule is
handled in the "Rules" section.

=
int IXRules::index_booking_list(OUTPUT_STREAM, booking_list *L, rule_context rc,
	char *billing, rulebook *owner, int *resp_count) {
	booking *prev = NULL;
	int count = 0;
	LOOP_OVER_BOOKINGS(br, L) {
		rule *R = RuleBookings::get_rule(br);
		int skip = FALSE;
		#ifdef IF_MODULE
		phrase *ph = Rules::get_defn_as_phrase(R);
		if (ph) {
			ph_runtime_context_data *phrcd = &(ph->runtime_context_data);
			scene *during_scene = Phrases::Context::get_scene(phrcd);
			if ((rc.scene_context) && (during_scene != rc.scene_context)) skip = TRUE;
			if ((rc.action_context) &&
				(Phrases::Context::within_action_context(phrcd, rc.action_context) == FALSE))
				skip = TRUE;
		}
		#endif
		if (skip == FALSE) {
			count++;
			IXRules::br_start_index_line(OUT, prev, billing);
			*resp_count += IXRules::index(OUT, R, owner, rc);
		}
		prev = br;
	}
	return count;
}

@ The "index links" are not hypertextual: they're the little icons showing
the order of precedence of rules in the list. On some index pages we don't
want this, so:

=
int show_index_links = TRUE;

void IXRules::list_suppress_indexed_links(void) {
	show_index_links = FALSE;
}

void IXRules::list_resume_indexed_links(void) {
	show_index_links = TRUE;
}

void IXRules::br_start_index_line(OUTPUT_STREAM, booking *prev, char *billing) {
	HTML::open_indented_p(OUT, 2, "hanging");
	if ((billing[0]) && (show_index_links)) IXRules::br_show_linkage_icon(OUT, prev);
	WRITE("%s", billing);
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	if ((billing[0] == 0) && (show_index_links)) IXRules::br_show_linkage_icon(OUT, prev);
}

@ And here's how the index links (if wanted) are chosen and plotted:

=
void IXRules::br_show_linkage_icon(OUTPUT_STREAM, booking *prev) {
	text_stream *icon_name = NULL; /* redundant assignment to appease |gcc -O2| */
	if ((prev == NULL) || (prev->commentary.tooltip_text == NULL)) {
		HTML::icon_with_tooltip(OUT, I"inform:/doc_images/rulenone.png",
			I"start of rulebook", NULL);
		return;
	}
	switch (prev->commentary.next_rule_specificity) {
		case -1: icon_name = I"inform:/doc_images/ruleless.png"; break;
		case 0: icon_name = I"inform:/doc_images/ruleequal.png"; break;
		case 1: icon_name = I"inform:/doc_images/rulemore.png"; break;
		default: internal_error("unknown rule specificity");
	}
	HTML::icon_with_tooltip(OUT, icon_name,
		prev->commentary.tooltip_text, prev->commentary.law_applied);
}

@h Rules index.
The Rules page of the index is essentially a trawl through the more
popular rulebooks, showing their contents in logical order.

=
void IXRules::Rules_page(OUTPUT_STREAM, int n) {
	if (n == 1) {
		@<Index the segment for the main action rulebooks@>;
		@<Index the segment for the sequence of play rulebooks@>;
		@<Index the segment for the Understanding rulebooks@>;
		@<Index the segment for the description rulebooks@>;
		@<Index the segment for the accessibility rulebooks@>;
		@<Index the segment for the light and darkness rulebooks@>;
		@<Index the segment for the top-level rulebooks@>;
		@<Index the segment for the action processing rulebooks@>;
		@<Index the segment for the responses@>;
	} else {
		if (IXRules::noteworthy_rulebooks(NULL) > 0)
			@<Index the segment for new rulebooks and activities@>;
		inform_extension *E;
		LOOP_OVER(E, inform_extension)
			if (Extensions::is_standard(E) == FALSE)
				if (IXRules::noteworthy_rulebooks(E) > 0)
					@<Index the segment for the rulebooks in this extension@>;
	}
}

@<Index the segment for the top-level rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>The top level</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("An Inform story file spends its whole time working through "
		"these three master rulebooks. They can be altered, just as all "
		"rulebooks can, but it's generally better to leave them alone.");
	HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Startup rules", EMPTY_WORDING, NULL,
		Rulebooks::std(STARTUP_RB), NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, STARTING_VIRTUAL_MACHINE_ACT, 2);
	Activities::index_by_number(OUT, PRINTING_BANNER_TEXT_ACT, 2);
	IXRules::index_rules_box(OUT, "Turn sequence rules", EMPTY_WORDING, NULL,
		Rulebooks::std(TURN_SEQUENCE_RB), NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, CONSTRUCTING_STATUS_LINE_ACT, 2);
	IXRules::index_rules_box(OUT, "Shutdown rules", EMPTY_WORDING, NULL,
		Rulebooks::std(SHUTDOWN_RB), NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, AMUSING_A_VICTORIOUS_PLAYER_ACT, 2);
	Activities::index_by_number(OUT, PRINTING_PLAYERS_OBITUARY_ACT, 2);
	Activities::index_by_number(OUT, DEALING_WITH_FINAL_QUESTION_ACT, 2);


@<Index the segment for the sequence of play rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Rules added to the sequence of play</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are the best places to put rules timed to happen "
		"at the start, at the end, or once each turn. (Each is run through at "
		"a carefully chosen moment in the relevant top-level rulebook.) It is "
		"also possible to have rules take effect at specific times of day "
		"or when certain events happen. Those are listed in the Scenes index, "
		"alongside rules taking place when scenes begin or end."); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "When play begins", EMPTY_WORDING, I"rules_wpb",
		Rulebooks::std(WHEN_PLAY_BEGINS_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Every turn", EMPTY_WORDING, I"rules_et",
		Rulebooks::std(EVERY_TURN_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "When play ends", EMPTY_WORDING, I"rules_wpe",
		Rulebooks::std(WHEN_PLAY_ENDS_RB), NULL, NULL, 1, TRUE);

@<Index the segment for the Understanding rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How commands are understood</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("'Understanding' here means turning a typed command, like GET FISH, "
		"into one or more actions, like taking the red herring. This is all handled "
		"by a single large rule (the parse command rule), but that rule makes use "
		"of the following activities and rulebooks in its work."); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Does the player mean", EMPTY_WORDING, I"rules_dtpm",
		Rulebooks::std(DOES_THE_PLAYER_MEAN_RB), NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, READING_A_COMMAND_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_SCOPE_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_CONCEALED_POSSESS_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_WHETHER_ALL_INC_ACT, 1);
	Activities::index_by_number(OUT, CLARIFYING_PARSERS_CHOICE_ACT, 1);
	Activities::index_by_number(OUT, ASKING_WHICH_DO_YOU_MEAN_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_A_PARSER_ERROR_ACT, 1);
	Activities::index_by_number(OUT, SUPPLYING_A_MISSING_NOUN_ACT, 1);
	Activities::index_by_number(OUT, SUPPLYING_A_MISSING_SECOND_ACT, 1);
	Activities::index_by_number(OUT, IMPLICITLY_TAKING_ACT, 1);

@<Index the segment for the main action rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Rules governing actions</b>"); HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("These rules are the ones which tell Inform how actions work, "
		"and which affect how they happen in particular cases.");
	HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Persuasion", EMPTY_WORDING, I"rules_per",
		Rulebooks::std(PERSUASION_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Unsuccessful attempt by", EMPTY_WORDING, I"rules_fail",
		Rulebooks::std(UNSUCCESSFUL_ATTEMPT_BY_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Before", EMPTY_WORDING, I"rules_before",
		Rulebooks::std(BEFORE_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Instead", EMPTY_WORDING, I"rules_instead",
		Rulebooks::std(INSTEAD_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Check", EMPTY_WORDING, NULL, NULL, NULL,
		"Check rules are tied to specific actions, and there are too many "
		"to index here. For instance, the check taking rules can only ever "
		"affect the taking action, so they are indexed on the detailed index "
		"page for taking.", 1, TRUE);
	IXRules::index_rules_box(OUT, "Carry out", EMPTY_WORDING, NULL, NULL, NULL,
		"Carry out rules are tied to specific actions, and there are too many "
		"to index here.", 1, TRUE);
	IXRules::index_rules_box(OUT, "After", EMPTY_WORDING, I"rules_after",
		Rulebooks::std(AFTER_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Report", EMPTY_WORDING, NULL, NULL, NULL,
		"Report rules are tied to specific actions, and there are too many "
		"to index here.", 1, TRUE);

@<Index the segment for the action processing rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How actions are processed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These form the technical machinery for dealing with actions, and are "
		"called on at least once every turn. They seldom need to be changed."); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Action-processing rules", EMPTY_WORDING, NULL,
		Rulebooks::std(ACTION_PROCESSING_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Specific action-processing rules", EMPTY_WORDING, NULL,
		Rulebooks::std(SPECIFIC_ACTION_PROCESSING_RB), NULL, NULL, 2, TRUE);
	IXRules::index_rules_box(OUT, "Player's action awareness rules", EMPTY_WORDING, NULL,
		Rulebooks::std(PLAYERS_ACTION_AWARENESS_RB), NULL, NULL, 3, TRUE);

@<Index the segment for the responses@> =
	HTML_OPEN("p"); WRITE("<b>How responses are printed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("The Standard Rules, and some extensions, reply to the player's "
		"commands with messages which are able to be modified."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_RESPONSE_ACT, 1);

@<Index the segment for the accessibility rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How accessibility is judged</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are used when deciding who can reach what, and "
		"who can see what."); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Reaching inside", EMPTY_WORDING, I"rules_ri",
		Rulebooks::std(REACHING_INSIDE_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Reaching outside", EMPTY_WORDING, I"rules_ri",
		Rulebooks::std(REACHING_OUTSIDE_RB), NULL, NULL, 1, TRUE);
	IXRules::index_rules_box(OUT, "Visibility", EMPTY_WORDING, I"visibility",
		Rulebooks::std(VISIBILITY_RB), NULL, NULL, 1, TRUE);

@<Index the segment for the light and darkness rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Light and darkness</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control how we describe darkness."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_NAME_OF_DARK_ROOM_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_DESC_OF_DARK_ROOM_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_NEWS_OF_DARKNESS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_NEWS_OF_LIGHT_ACT, 1);
	Activities::index_by_number(OUT, REFUSAL_TO_ACT_IN_DARK_ACT, 1);

@<Index the segment for the description rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How things are described</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control what is printed when naming rooms or "
		"things, and their descriptions."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_THE_NAME_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_THE_PLURAL_NAME_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_A_NUMBER_OF_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_ROOM_DESC_DETAILS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_INVENTORY_DETAILS_ACT, 1);
	Activities::index_by_number(OUT, LISTING_CONTENTS_ACT, 1);
	Activities::index_by_number(OUT, GROUPING_TOGETHER_ACT, 1);
	Activities::index_by_number(OUT, WRITING_A_PARAGRAPH_ABOUT_ACT, 1);
	Activities::index_by_number(OUT, LISTING_NONDESCRIPT_ITEMS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_LOCALE_DESCRIPTION_ACT, 1);
	Activities::index_by_number(OUT, CHOOSING_NOTABLE_LOCALE_OBJ_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_LOCALE_PARAGRAPH_ACT, 1);

@<Index the segment for new rulebooks and activities@> =
	HTML_OPEN("p"); WRITE("<b>From the source text</b>"); HTML_CLOSE("p");
	inform_extension *E = NULL; /* that is, not in an extension at all */
	@<Index rulebooks occurring in this part of the source text@>;

@<Index the segment for the rulebooks in this extension@> =
	HTML_OPEN("p"); WRITE("<b>From the extension ");
	Works::write_to_HTML_file(OUT, E->as_copy->edition->work, FALSE);
	WRITE("</b>"); HTML_CLOSE("p");
	@<Index rulebooks occurring in this part of the source text@>;

@<Index rulebooks occurring in this part of the source text@> =
	activity *av;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(rb->primary_name));
		if (rb->automatically_generated) continue;
		if (((E == NULL) && (sf == NULL)) ||
			(Extensions::corresponding_to(sf) == E))
			IXRules::index_rules_box(OUT, NULL, rb->primary_name, NULL, rb, NULL, NULL, 1, TRUE);
	}
	LOOP_OVER(av, activity) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(av->name));
		if (((E == NULL) && (sf == NULL)) ||
			(Extensions::corresponding_to(sf) == E))
			Activities::index(OUT, av, 1);
	}

@ =
int IXRules::noteworthy_rulebooks(inform_extension *E) {
	int nb = 0;
	activity *av;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(rb->primary_name));
		if (rb->automatically_generated) continue;
		if (((E == NULL) && (sf == NULL)) ||
			(Extensions::corresponding_to(sf) == E)) nb++;
	}
	LOOP_OVER(av, activity) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(av->name));
		if (((E == NULL) && (sf == NULL)) ||
			(Extensions::corresponding_to(sf) == E)) nb++;
	}
	return nb;
}

void IXRules::index_scene(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("<b>The scene-changing machinery</b>"); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Scene changing", EMPTY_WORDING, NULL,
		Rulebooks::std(SCENE_CHANGING_RB), NULL, NULL, 1, FALSE);
}

int unique_xtra_no = 0;
void IXRules::index_rules_box(OUTPUT_STREAM, char *name, wording W, text_stream *doc_link,
	rulebook *rb, activity *av, char *text, int indent, int hide_behind_plus) {
	int xtra_no = 0;
	if (rb) xtra_no = rb->allocation_id;
	else if (av) xtra_no = NUMBER_CREATED(rulebook) + av->allocation_id;
	else xtra_no = NUMBER_CREATED(rulebook) + NUMBER_CREATED(activity) + unique_xtra_no++;

	char *col = "e0e0e0";
	if (av) col = "e8e0c0";

	int n = 0;
	if (rb) n = Rulebooks::no_rules(rb);
	if (av) n = Activities::no_rules(av);

	TEMPORARY_TEXT(textual_name)
	if (name) WRITE_TO(textual_name, "%s", name);
	else if (Wordings::nonempty(W)) WRITE_TO(textual_name, "%+W", W);
	else WRITE_TO(textual_name, "nameless");
	string_position start = Str::start(textual_name);
	Str::put(start, Characters::tolower(Str::get(start)));

	if (hide_behind_plus) {
		HTML::open_indented_p(OUT, indent+1, "tight");
		Index::extra_link(OUT, xtra_no);
		if (n == 0) HTML::begin_colour(OUT, I"808080");
		WRITE("%S", textual_name);
		@<Write the titling line of an index rules box@>;
		WRITE(" (%d rule%s)", n, (n==1)?"":"s");
		if (n == 0) HTML::end_colour(OUT);
		HTML_CLOSE("p");

		Index::extra_div_open(OUT, xtra_no, indent+1, col);
	} else {
		HTML::open_indented_p(OUT, indent, "");
		HTML::open_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
	}

	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);


	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("<b>%S</b>", textual_name);
	@<Write the titling line of an index rules box@>;
	HTML_CLOSE("p");

	HTML::next_html_column_right_justified(OUT, 0);

	HTML::open_indented_p(OUT, 1, "tight");
	if (av) {
		TEMPORARY_TEXT(skeleton)
		WRITE_TO(skeleton, "Before %S:", textual_name);
		PasteButtons::paste_text(OUT, skeleton);
		WRITE("&nbsp;<i>b</i> ");
		Str::clear(skeleton);
		WRITE_TO(skeleton, "Rule for %S:", textual_name);
		PasteButtons::paste_text(OUT, skeleton);
		WRITE("&nbsp;<i>f</i> ");
		Str::clear(skeleton);
		WRITE_TO(skeleton, "After %S:", textual_name);
		PasteButtons::paste_text(OUT, skeleton);
		WRITE("&nbsp;<i>a</i>");
		DISCARD_TEXT(skeleton)
	} else {
		PasteButtons::paste_text(OUT, textual_name);
		WRITE("&nbsp;<i>name</i>");
	}
	HTML_CLOSE("p");
	DISCARD_TEXT(textual_name)

	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);

	if ((rb) && (Rulebooks::is_empty(rb, Phrases::Context::no_rule_context())))
		text = "There are no rules in this rulebook.";
	if (text) {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("%s", text); HTML_CLOSE("p");
	} else {
		if (rb) {
			int ignore_me = 0;
			IXRules::index_rulebook(OUT, rb, "", Phrases::Context::no_rule_context(), &ignore_me);
		}
		if (av) Activities::index_details(OUT, av);
	}
	if (hide_behind_plus) {
		Index::extra_div_close(OUT, col);
	} else {
		HTML::close_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
		HTML_CLOSE("p");
	}
}

@<Write the titling line of an index rules box@> =
	if (Str::len(doc_link) > 0) Index::DocReferences::link(OUT, doc_link);
	WRITE(" ... ");
	if (av) WRITE(" activity"); else {
		if ((rb) && (Rulebooks::get_focus_kind(rb)) &&
			(Kinds::eq(Rulebooks::get_focus_kind(rb), K_action_name) == FALSE)) {
			WRITE(" ");
			Kinds::Textual::write_articled(OUT, Rulebooks::get_focus_kind(rb));
			WRITE(" based");
		}
		WRITE(" rulebook");
	}
	int wn = -1;
	if (rb) wn = Wordings::first_wn(rb->primary_name);
	else if (av) wn = Wordings::first_wn(av->name);
	if (wn >= 0) Index::link(OUT, wn);

@ =
int IXRules::index_rulebook(OUTPUT_STREAM, rulebook *rb, char *billing, rule_context rc, int *resp_count) {
	int suppress_outcome = FALSE, t;
	if (rb == NULL) return 0;
	if (billing == NULL) internal_error("No billing for rb index");
	if (billing[0] != 0) {
		#ifdef IF_MODULE
		if (rc.action_context) suppress_outcome = TRUE;
		#endif
		if (BookingLists::is_contextually_empty(rb->contents, rc)) suppress_outcome = TRUE;
	}
	t = IXRules::index_booking_list(OUT, rb->contents, rc, billing, rb, resp_count);
	Rulebooks::Outcomes::index_outcomes(OUT, &(rb->my_outcomes), suppress_outcome);
	IXRules::rb_index_placements(OUT, rb);
	return t;
}

#ifdef IF_MODULE
void IXRules::index_action_rules(OUTPUT_STREAM, action_name *an, rulebook *rb,
	int code, char *desc, int *resp_count) {
	int t = 0;
	IXRules::list_suppress_indexed_links();
	if (code >= 0) t += IXRules::index_rulebook(OUT, Rulebooks::std(code), desc,
		Phrases::Context::action_context(an), resp_count);
	if (rb) t += IXRules::index_rulebook(OUT, rb, desc, Phrases::Context::no_rule_context(), resp_count);
	IXRules::list_resume_indexed_links();
	if (t > 0) HTML_TAG("br");
}
#endif

@h Affected by placements.
The contents of rulebooks can be unexpected if sentences are used which
explicitly list, or unlist, rules. To make the index more useful in these
cases, we keep a linked list, for each rulebook, of all sentences which
have affected it in this way:

=
typedef struct rulebook_indexing_data {
	struct placement_affecting *placement_list; /* linked list of explicit placements */
} rulebook_indexing_data;

typedef struct placement_affecting {
	struct parse_node *placement_sentence;
	struct placement_affecting *next;
	CLASS_DEFINITION
} placement_affecting;

rulebook_indexing_data IXRules::new_rulebook_indexing_data(rulebook *RB) {
	rulebook_indexing_data rid;
	rid.placement_list = NULL;
	return rid;
}

void IXRules::affected_by_placement(rulebook *rb, parse_node *where) {
	placement_affecting *npl = CREATE(placement_affecting);
	npl->placement_sentence = where;
	npl->next = rb->indexing_data.placement_list;
	rb->indexing_data.placement_list = npl;
}

int IXRules::rb_no_placements(rulebook *rb) {
	int t = 0;
	placement_affecting *npl = rb->indexing_data.placement_list;
	while (npl) { t++; npl = npl->next; }
	return t;
}

void IXRules::rb_index_placements(OUTPUT_STREAM, rulebook *rb) {
	placement_affecting *npl = rb->indexing_data.placement_list;
	while (npl) {
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("<i>NB:</i> %W", Node::get_text(npl->placement_sentence));
		Index::link(OUT, Wordings::first_wn(Node::get_text(npl->placement_sentence)));
		HTML_CLOSE("span");
		HTML_TAG("br");
		npl = npl->next;
	}
}
