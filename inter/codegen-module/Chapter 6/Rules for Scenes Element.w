[RulesForScenesElement::] Rules for Scenes Element.

To write the Rules for Scenes element (RS) in the index.

@

=
void RulesForScenesElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);

	HTML_OPEN("p"); WRITE("<b>The scene-changing machinery</b>"); HTML_CLOSE("p");
	RulesForScenesElement::index_rules_box(OUT, inv, I"Scene changing", NULL,
		RulesForScenesElement::find_rulebook(inv, I"scene_changing"), NULL, 1, FALSE);
	HTML_OPEN("p");
	Index::anchor(OUT, I"SRULES");
	WRITE("<b>General rules applying to scene changes</b>");
	HTML_CLOSE("p");
	RulesForScenesElement::index_rules_box(OUT, inv, I"When a scene begins", NULL,
		RulesForScenesElement::find_rulebook(inv, I"when_scene_begins"), NULL, 1, FALSE);
	RulesForScenesElement::index_rules_box(OUT, inv, I"When a scene ends", NULL,
		RulesForScenesElement::find_rulebook(inv, I"when_scene_ends"), NULL, 1, FALSE);
}

inter_package *RulesForScenesElement::find_rulebook(tree_inventory *inv, text_stream *marker) {
	for (int i=0; i<TreeLists::len(inv->rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->rulebook_nodes->list[i].node);
		if (Str::eq(marker, Metadata::read_optional_textual(pack, I"^index_id")))
			return pack;
	}
	return NULL;
}

typedef struct ix_rule_context {
	struct inter_package *action_context;
	struct inter_package *scene_context;
} ix_rule_context;

ix_rule_context RulesForScenesElement::action_context(inter_package *an) {
	ix_rule_context rc;
	rc.action_context = an;
	rc.scene_context = NULL;
	return rc;
}
ix_rule_context RulesForScenesElement::scene_context(inter_package *s) {
	ix_rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = s;
	return rc;
}

ix_rule_context RulesForScenesElement::no_rule_context(void) {
	ix_rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = NULL;
	return rc;
}

int RS_unique_xtra_no = 0;
void RulesForScenesElement::index_rules_box(OUTPUT_STREAM, tree_inventory *inv,
	text_stream *titling_text, text_stream *doc_link,
	inter_package *rb_pack, char *text, int indent, int hide_behind_plus) {
	if (rb_pack == NULL) return;

	int xtra_no = RS_unique_xtra_no++;

	char *col = "e0e0e0";

	int n = RulesForScenesElement::no_rules(inv->of_tree, rb_pack);

	TEMPORARY_TEXT(textual_name)
	if (Str::len(titling_text) > 0) WRITE_TO(textual_name, "%S", titling_text);
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
	PasteButtons::paste_text(OUT, textual_name);
	WRITE("&nbsp;<i>name</i>");
	HTML_CLOSE("p");
	DISCARD_TEXT(textual_name)

	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);

	if (n == 0) text = "There are no rules in this rulebook.";
	if (text) {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("%s", text); HTML_CLOSE("p");
	} else {
		int ignore_me = 0;
		RulesForScenesElement::index_rulebook(OUT, inv->of_tree, rb_pack, NULL, RulesForScenesElement::no_rule_context(), &ignore_me);
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
	WRITE(" ... %S", Metadata::read_optional_textual(rb_pack, I"^focus"));
	int at = (int) Metadata::read_optional_numeric(rb_pack, I"^at");
	if (at > 0) Index::link(OUT, at);

@ =
int RulesForScenesElement::index_rulebook(OUTPUT_STREAM, inter_tree *I, inter_package *rb_pack, text_stream *billing, ix_rule_context rc, int *resp_count) {
	int suppress_outcome = FALSE, t = 0;
	if (rb_pack == NULL) return 0;
	if (Str::len(billing) > 0) {
		if (rc.action_context) suppress_outcome = TRUE;
//		if (BookingLists::is_contextually_empty(rb->contents, rc)) suppress_outcome = TRUE;
	}
	t = RulesForScenesElement::index_booking_list(OUT, I, rb_pack, rc, billing, resp_count);
	RulesForScenesElement::index_outcomes(OUT, rb_pack, suppress_outcome);
	RulesForScenesElement::rb_index_placements(OUT, rb_pack);
	return t;
}

int RulesForScenesElement::no_rules(inter_tree *I, inter_package *rb_pack) {
	int N = 0;
	if (rb_pack) {
		inter_symbol *wanted = PackageTypes::get(I, I"_rulebook_entry");
		inter_tree_node *D = Inter::Packages::definition(rb_pack);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted)
					N++;
			}
		}
	}
	return N;
}

int RulesForScenesElement::index_booking_list(OUTPUT_STREAM, inter_tree *I,
	inter_package *rb_pack,
	ix_rule_context rc, text_stream *billing, int *resp_count) {
	inter_package *prev = NULL;
	int count = 0;
	inter_symbol *wanted = PackageTypes::get(I, I"_rulebook_entry");
	inter_tree_node *D = Inter::Packages::definition(rb_pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				int skip = FALSE;
/*				imperative_defn *id = Rules::get_imperative_definition(R);
				if (id) {
					id_body *idb = id->body_of_defn;
					id_runtime_context_data *phrcd = &(idb->runtime_context_data);
					scene *during_scene = Scenes::rcd_scene(phrcd);
					if ((rc.scene_context) && (during_scene != rc.scene_context)) skip = TRUE;
					if ((rc.action_context) &&
						(ActionRules::within_action_context(phrcd, rc.action_context) == FALSE))
						skip = TRUE;
				}
*/
				if (skip == FALSE) {
					count++;
					RulesForScenesElement::br_start_index_line(OUT, prev, billing);
					*resp_count += RulesForScenesElement::index_rule(OUT, entry, rb_pack, rc);
				}
				prev = entry;
			}
		}
	}
	return count;
}

int IX_show_index_links = TRUE;

void RulesForScenesElement::list_suppress_indexed_links(void) {
	IX_show_index_links = FALSE;
}

void RulesForScenesElement::list_resume_indexed_links(void) {
	IX_show_index_links = TRUE;
}

void RulesForScenesElement::br_start_index_line(OUTPUT_STREAM, inter_package *prev, text_stream *billing) {
	HTML::open_indented_p(OUT, 2, "hanging");
	if ((Str::len(billing) > 0) && (IX_show_index_links)) RulesForScenesElement::br_show_linkage_icon(OUT, prev);
	WRITE("%S", billing);
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	if ((Str::len(billing) > 0) && (IX_show_index_links)) RulesForScenesElement::br_show_linkage_icon(OUT, prev);
}

@ And here's how the index links (if wanted) are chosen and plotted:

=
void RulesForScenesElement::br_show_linkage_icon(OUTPUT_STREAM, inter_package *prev) {
	text_stream *icon_name = NULL; /* redundant assignment to appease |gcc -O2| */
	if ((prev == NULL) || (Str::len(Metadata::read_optional_textual(prev, I"^tooltip")) == 0)) {
		HTML::icon_with_tooltip(OUT, I"inform:/doc_images/rulenone.png",
			I"start of rulebook", NULL);
		return;
	}
	switch (Metadata::read_optional_numeric(prev, I"^specificity")) {
		case 0: icon_name = I"inform:/doc_images/ruleless.png"; break;
		case 1: icon_name = I"inform:/doc_images/ruleequal.png"; break;
		case 2: icon_name = I"inform:/doc_images/rulemore.png"; break;
		default: internal_error("unknown rule specificity");
	}
	HTML::icon_with_tooltip(OUT, icon_name,
		Metadata::read_optional_textual(prev, I"^tooltip"), Metadata::read_optional_textual(prev, I"^law"));
}

@ And off we go:

=
int RulesForScenesElement::index_rule(OUTPUT_STREAM, inter_package *R, inter_package *owner, ix_rule_context rc) {
	WRITE("RULE");
	int no_responses_indexed = 0;
/*
	if (Wordings::nonempty(R->indexing_data.italicised_text)) @<Index the italicised text to do with the rule@>;
	if (Wordings::nonempty(R->name)) @<Index the rule name along with Javascript buttons@>;
	if ((Wordings::nonempty(R->indexing_data.italicised_text) == FALSE) &&
		(Wordings::nonempty(R->name) == FALSE) && (R->defn_as_I7_source))
		@<Index some text extracted from the first line of the otherwise anonymous rule@>;
	@<Index a link to the first line of the rule's definition@>;
	if (global_compilation_settings.number_rules_in_index) @<Index the small type rule numbering@>;
	@<Index any applicability conditions@>;
	HTML_CLOSE("p");
	@<Index any response texts in the rule@>;
*/
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
			IXRules::index_response(OUT, R, l, R->responses[l].message);
			c++;
		}
	if (c > 0) Index::extra_div_close_nested(OUT);
	no_responses_indexed = c;

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	parse_node *pn = R->defn_as_I7_source->at->down;
	if ((pn) && (Wordings::nonempty(Node::get_text(pn)))) {
		WRITE("(%+W", Node::get_text(pn));
		if (pn->next) WRITE("; ...");
		WRITE(")");
	}

@<Index a link to the first line of the rule's definition@> =
	if (R->defn_as_I7_source) {
		parse_node *pn = R->defn_as_I7_source->at;
		if ((pn) && (Wordings::nonempty(Node::get_text(pn))))
			Index::link(OUT, Wordings::first_wn(Node::get_text(pn)));
	}

@<Index the small type rule numbering@> =
	WRITE(" ");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (R->defn_as_I7_source) WRITE("%d", R->defn_as_I7_source->allocation_id);
	else WRITE("primitive");
	HTML_CLOSE("span");

@<Index any applicability conditions@> =
	applicability_constraint *acl;
	LOOP_OVER_LINKED_LIST(acl, applicability_constraint, R->applicability_constraints) {
		HTML_TAG("br");
		Index::link(OUT, Wordings::first_wn(Node::get_text(acl->where_imposed)));
		WRITE("&nbsp;%+W", Node::get_text(acl->where_imposed));
	}

@ =
void RulesForScenesElement::index_outcomes(OUTPUT_STREAM, inter_package *rb_pack, int suppress_outcome) {
/*	outcomes *outs = ...?
	if (suppress_outcome == FALSE) {
		rulebook_outcome *ro;
		LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes) {
			named_rulebook_outcome *rbno = ro->outcome_name;
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>outcome</i>&nbsp;&nbsp;");
			if (outs->default_named_outcome == ro) WRITE("<b>");
			WRITE("%+W", Nouns::nominative_singular(rbno->name));
			if (outs->default_named_outcome == ro) WRITE("</b> (default)");
			WRITE(" - <i>");
			switch(ro->kind_of_outcome) {
				case SUCCESS_OUTCOME: WRITE("a success"); break;
				case FAILURE_OUTCOME: WRITE("a failure"); break;
				case NO_OUTCOME: WRITE("no outcome"); break;
			}
			WRITE("</i>");
			HTML_CLOSE("p");
		}
	}
	if ((outs->default_named_outcome == NULL) &&
		(outs->default_rule_outcome != NO_OUTCOME) &&
		(suppress_outcome == FALSE)) {
		HTML::open_indented_p(OUT, 2, "hanging");
		WRITE("<i>default outcome is</i> ");
		switch(outs->default_rule_outcome) {
			case SUCCESS_OUTCOME: WRITE("success"); break;
			case FAILURE_OUTCOME: WRITE("failure"); break;
		}
		HTML_CLOSE("p");
	}
*/
	WRITE("OUTCOMES");
}

void RulesForScenesElement::rb_index_placements(OUTPUT_STREAM, inter_package *rb_pack) {
/*	placement_affecting *npl = rb->indexing_data.placement_list;
	while (npl) {
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("<i>NB:</i> %W", Node::get_text(npl->placement_sentence));
		Index::link(OUT, Wordings::first_wn(Node::get_text(npl->placement_sentence)));
		HTML_CLOSE("span");
		HTML_TAG("br");
		npl = npl->next;
	}
*/
	WRITE("PLACEMENTS");
}

@ =
/* void RulesForScenesElement::activity_rules_box(OUTPUT_STREAM, char *titling_text, wording W, text_stream *doc_link,
	inter_package *rb_pack, activity *av, char *text, int indent, int hide_behind_plus) {
	if (rb_pack == NULL) return;

	int xtra_no = 0;
	if (rb) xtra_no = rb->allocation_id;
	else if (av) xtra_no = NUMBER_CREATED(rulebook) + av->allocation_id;
	else xtra_no = NUMBER_CREATED(rulebook) + NUMBER_CREATED(activity) + RS_unique_xtra_no++;

	char *col = "e0e0e0";
	if (av) col = "e8e0c0";

	int n = 0;
	if (rb) n = Rulebooks::no_rules(rb);
	if (av) n = IXActivities::no_rules(av);

	TEMPORARY_TEXT(textual_name)
	if (titling_text) WRITE_TO(textual_name, "%s", titling_text);
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
	@<Write the titling line of an activity rules box@>;
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

	if ((rb) && (Rulebooks::is_empty(rb)))
		text = "There are no rules in this rulebook.";
	if (text) {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("%s", text); HTML_CLOSE("p");
	} else {
		if (rb) {
			int ignore_me = 0;
			IXRules::index_rulebook(OUT, rb, "",
				RulesForScenesElement::no_rule_context(), &ignore_me);
		}
		if (av) IXActivities::index_details(OUT, av);
	}
	if (hide_behind_plus) {
		Index::extra_div_close(OUT, col);
	} else {
		HTML::close_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
		HTML_CLOSE("p");
	}
}
*/

@<Write the titling line of an activity rules box@> =
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

