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
	heading *definition_area = Headings::of_wording(ActionNameNames::tensed(an, IS_TENSE));
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
				RTPhrasebook::index_definition_area(OUT, W, TRUE);
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
	if (ActionSemantics::is_out_of_world(an)) HTML::begin_colour(OUT, I"800000");
	if (pass == 1) {
		if (bold) WRITE("<b>");
		WRITE("%+W", ActionNameNames::tensed(an, IS_TENSE));
		if (bold) WRITE("</b>");
	} else {
		WRITE("<b>");
		int j = Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE));
		int somethings = 0;
		while (j <= Wordings::last_wn(ActionNameNames::tensed(an, IS_TENSE))) {
			if (<object-pronoun>(Wordings::one_word(j))) {
				IXActions::act_index_something(OUT, an, somethings++);
			} else {
				WRITE("%+W ", Wordings::one_word(j));
			}
			j++;
		}
		if (somethings < ActionSemantics::max_parameters(an))
			IXActions::act_index_something(OUT, an, somethings++);
	}
	if (ActionSemantics::is_out_of_world(an)) HTML::end_colour(OUT);
	if (pass == 2) {
		int swn = IXActions::an_get_specification_text(an);
		WRITE("</b>");
		Index::link(OUT, Wordings::first_wn(Node::get_text(an->indexing_data.designers_specification)));
		Index::anchor(OUT, RTActions::identifier(an));
		if (ActionSemantics::requires_light(an)) WRITE(" (requires light)");
		WRITE(" (<i>past tense</i> %+W)", an->naming_data.past_name);
		HTML_CLOSE("p");
		if (swn >= 0) { HTML_OPEN("p"); WRITE("%W", Wordings::one_word(swn)); HTML_CLOSE("p"); }
		HTML_TAG("hr");
		HTML_OPEN("p"); WRITE("<b>Typed commands leading to this action</b>\n"); HTML_CLOSE("p");
		HTML_OPEN("p");
		if (CommandsIndex::index_list_with_action(OUT, an->command_parser_grammar_producing_this) == FALSE)
			WRITE("<i>None</i>");
		HTML_CLOSE("p");
		if (SharedVariables::set_empty(an->action_variables) == FALSE) {
			HTML_OPEN("p"); WRITE("<b>Named values belonging to this action</b>\n"); HTML_CLOSE("p");
			IXActions::index_stv_set(OUT, an->action_variables);
		}

		HTML_OPEN("p"); WRITE("<b>Rules controlling this action</b>"); HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("\n");
		int resp_count = 0;
		if (ActionSemantics::is_out_of_world(an) == FALSE) {
			IXRules::index_action_rules(OUT, an, NULL, PERSUASION_RB, "persuasion", &resp_count);
			IXRules::index_action_rules(OUT, an, NULL, UNSUCCESSFUL_ATTEMPT_BY_RB, "unsuccessful attempt", &resp_count);
			IXRules::index_action_rules(OUT, an, NULL, SETTING_ACTION_VARIABLES_RB, "set action variables for", &resp_count);
			IXRules::index_action_rules(OUT, an, NULL, BEFORE_RB, "before", &resp_count);
			IXRules::index_action_rules(OUT, an, NULL, INSTEAD_RB, "instead of", &resp_count);
		}
		IXRules::index_action_rules(OUT, an, an->check_rules, CHECK_RB, "check", &resp_count);
		IXRules::index_action_rules(OUT, an, an->carry_out_rules, CARRY_OUT_RB, "carry out", &resp_count);
		if (ActionSemantics::is_out_of_world(an) == FALSE)
			IXRules::index_action_rules(OUT, an, NULL, AFTER_RB, "after", &resp_count);
		IXRules::index_action_rules(OUT, an, an->report_rules, REPORT_RB, "report", &resp_count);
		if (resp_count > 1) {
			WRITE("Click on the speech-bubble icons to see the responses, "
				"or here to see all of them:");
			WRITE("&nbsp;");
			Index::extra_all_link_with(OUT, NUMBER_CREATED(rule), "responses");
			WRITE("%d", resp_count);
		}
		HTML_CLOSE("p");
	} else {
		Index::link(OUT, Wordings::first_wn(Node::get_text(an->indexing_data.designers_specification)));
		Index::detail_link(OUT, "A", an->allocation_id, (on_details_page)?FALSE:TRUE);
	}
	return f;
}

void IXActions::index_stv_set(OUTPUT_STREAM, shared_variable_set *set) {
	shared_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, shared_variable, set->variables)
		if (stv->underlying_var) {
			HTML::open_indented_p(OUT, 2, "tight");
			IXActions::index_one(OUT, stv->underlying_var);
			HTML_CLOSE("p");
		}
}

void IXActions::index_one(OUTPUT_STREAM, nonlocal_variable *nlv) {
	WRITE("%+W", nlv->name);
	Index::link(OUT, Wordings::first_wn(nlv->name));
	if (Wordings::nonempty(nlv->var_documentation_symbol)) {
		TEMPORARY_TEXT(ixt)
		WRITE_TO(ixt, "%+W", Wordings::one_word(Wordings::first_wn(nlv->var_documentation_symbol)));
		Index::DocReferences::link(OUT, ixt);
		DISCARD_TEXT(ixt)
	}
	WRITE(" - <i>");
	Kinds::Textual::write(OUT, nlv->nlv_kind);
	WRITE("</i>");
}

void IXActions::act_index_something(OUTPUT_STREAM, action_name *an, int argc) {
	kind *K = NULL; /* redundant assignment to appease |gcc -O2| */
	HTML::begin_colour(OUT, I"000080");
	if (argc == 0) K = ActionSemantics::kind_of_noun(an);
	if (argc == 1) K = ActionSemantics::kind_of_second(an);
	if (Kinds::Behaviour::is_object(K)) WRITE("something");
	else if ((K_understanding) && (Kinds::eq(K, K_understanding))) WRITE("some text");
	else Kinds::Textual::write(OUT, K);
	HTML::end_colour(OUT);
	WRITE(" ");
}

void IXActions::index_named_patterns_for_extension(OUTPUT_STREAM, source_file *sf, inform_extension *E) {
	named_action_pattern *nap;
	int kc = 0;
	LOOP_OVER(nap, named_action_pattern)
		if (Lexer::file_of_origin(Wordings::first_wn(nap->text_of_declaration)) == E->read_into_file)
			kc = IndexExtensions::document_headword(OUT, kc, E, "Kinds of action", I"kind of action",
				nap->text_of_declaration);
	if (kc != 0) HTML_CLOSE("p");
}

