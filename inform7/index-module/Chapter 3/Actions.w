[IXActions::] Actions.

To produce the index of external files.

@

=
typedef struct action_indexing_data {
	int an_specification_text_word; /* description used in index */
	int an_index_group; /* paragraph number it belongs to (1, 2, 3, ...) */
	struct parse_node *designers_specification; /* where created */
} action_indexing_data;

action_indexing_data IXActions::new_data(void) {
	action_indexing_data aid;
	aid.an_index_group = 0;
	aid.designers_specification = NULL;
	aid.an_specification_text_word = -1;
	return aid;
}

void IXActions::actions_set_specification_text(action_name *an, int wn) {
	an->indexing_data.an_specification_text_word = wn;
}
int IXActions::an_get_specification_text(action_name *an) {
	return an->indexing_data.an_specification_text_word;
}

int IXActions::index(OUTPUT_STREAM, action_name *an, int pass,
	inform_extension **ext, heading **current_area, int f, int *new_par, int bold,
	int on_details_page) {
	if (an->compilation_data.use_verb_routine_in_I6_library) return f;
	heading *definition_area = Headings::of_wording(an->present_name);
	*new_par = FALSE;
	if (pass == 1) {
		inform_extension *this_extension =
			Headings::get_extension_containing(definition_area);
		if (*ext != this_extension) {
			*ext = this_extension;
			if (*ext == NULL) {
				if (f) HTML_CLOSE("p");
				HTML_OPEN("p");
				WRITE("<b>New actions defined in the source</b>");
				HTML_TAG("br");
				f = FALSE;
				*new_par = TRUE;
			} else if (Extensions::is_standard(*ext) == FALSE) {
				if (f) HTML_CLOSE("p");
				HTML_OPEN("p");
				WRITE("<b>Actions defined by the extension ");
				Extensions::write_name_to_file(*ext, OUT);
				WRITE(" by ");
				Extensions::write_author_to_file(*ext, OUT);
				WRITE("</b>");
				HTML_TAG("br");
				f = FALSE;
				*new_par = TRUE;
			}
		}
		if ((definition_area != *current_area) && (Extensions::is_standard(*ext))) {
			if (f) HTML_CLOSE("p");
			HTML_OPEN("p");
			wording W = Headings::get_text(definition_area);
			if (Wordings::nonempty(W)) {
				Phrases::Index::index_definition_area(OUT, W, TRUE);
			} else if (*ext == NULL) {
				WRITE("<b>");
				WRITE("New actions");
				WRITE("</b>");
				HTML_TAG("br");
			}
			f = FALSE;
			*new_par = TRUE;
		}
	}
	if (pass == 1) {
		if (f) WRITE(", "); else {
			if (*new_par == FALSE) {
				HTML_OPEN("p");
				*new_par = TRUE;
			}
		}
	}

	f = TRUE;
	*current_area = definition_area;
	if (pass == 2) {
		HTML_OPEN("p");
	}
	if (an->semantics.out_of_world) HTML::begin_colour(OUT, I"800000");
	if (pass == 1) {
		if (bold) WRITE("<b>");
		WRITE("%+W", an->present_name);
		if (bold) WRITE("</b>");
	} else {
		WRITE("<b>");
		int j = Wordings::first_wn(an->present_name);
		int somethings = 0;
		while (j <= Wordings::last_wn(an->present_name)) {
			if (<action-pronoun>(Wordings::one_word(j))) {
				IXActions::act_index_something(OUT, an, somethings++);
			} else {
				WRITE("%+W ", Wordings::one_word(j));
			}
			j++;
		}
		if (somethings < an->semantics.max_parameters)
			IXActions::act_index_something(OUT, an, somethings++);
	}
	if (an->semantics.out_of_world) HTML::end_colour(OUT);
	if (pass == 2) {
		int swn = IXActions::an_get_specification_text(an);
		WRITE("</b>");
		Index::link(OUT, Wordings::first_wn(Node::get_text(an->indexing_data.designers_specification)));
		Index::anchor(OUT, RTActions::identifier(an));
		if (an->semantics.requires_light) WRITE(" (requires light)");
		WRITE(" (<i>past tense</i> %+W)", an->past_name);
		HTML_CLOSE("p");
		if (swn >= 0) { HTML_OPEN("p"); WRITE("%W", Wordings::one_word(swn)); HTML_CLOSE("p"); }
		HTML_TAG("hr");
		HTML_OPEN("p"); WRITE("<b>Typed commands leading to this action</b>\n"); HTML_CLOSE("p");
		HTML_OPEN("p");
		if (PL::Parsing::Lines::index_list_with_action(OUT, an->list_with_action) == FALSE)
			WRITE("<i>None</i>");
		HTML_CLOSE("p");
		if (StackedVariables::owner_empty(an->action_variables) == FALSE) {
			HTML_OPEN("p"); WRITE("<b>Named values belonging to this action</b>\n"); HTML_CLOSE("p");
			StackedVariables::index_owner(OUT, an->action_variables);
		}

		HTML_OPEN("p"); WRITE("<b>Rules controlling this action</b>"); HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("\n");
		int resp_count = 0;
		if (an->semantics.out_of_world == FALSE) {
			Rulebooks::index_action_rules(OUT, an, NULL, PERSUASION_RB, "persuasion", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, UNSUCCESSFUL_ATTEMPT_BY_RB, "unsuccessful attempt", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, SETTING_ACTION_VARIABLES_RB, "set action variables for", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, BEFORE_RB, "before", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, INSTEAD_RB, "instead of", &resp_count);
		}
		Rulebooks::index_action_rules(OUT, an, an->check_rules, CHECK_RB, "check", &resp_count);
		Rulebooks::index_action_rules(OUT, an, an->carry_out_rules, CARRY_OUT_RB, "carry out", &resp_count);
		if (an->semantics.out_of_world == FALSE)
			Rulebooks::index_action_rules(OUT, an, NULL, AFTER_RB, "after", &resp_count);
		Rulebooks::index_action_rules(OUT, an, an->report_rules, REPORT_RB, "report", &resp_count);
		if (resp_count > 1) {
			WRITE("Click on the speech-bubble icons to see the responses, "
				"or here to see all of them:");
			WRITE("&nbsp;");
			Index::extra_link_with(OUT, 2000000, "responses");
			WRITE("%d", resp_count);
		}
		HTML_CLOSE("p");
	} else {
		Index::link(OUT, Wordings::first_wn(Node::get_text(an->indexing_data.designers_specification)));
		Index::detail_link(OUT, "A", an->allocation_id, (on_details_page)?FALSE:TRUE);
	}
	return f;
}

void IXActions::act_index_something(OUTPUT_STREAM, action_name *an, int argc) {
	kind *K = NULL; /* redundant assignment to appease |gcc -O2| */
	HTML::begin_colour(OUT, I"000080");
	if (argc == 0) K = an->semantics.noun_kind;
	if (argc == 1) K = an->semantics.second_kind;
	if (Kinds::Behaviour::is_object(K)) WRITE("something");
	else if ((K_understanding) && (Kinds::eq(K, K_understanding))) WRITE("some text");
	else Kinds::Textual::write(OUT, K);
	HTML::end_colour(OUT);
	WRITE(" ");
}
