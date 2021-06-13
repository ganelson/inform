[IndexRules::] Index Rules.

Utility functions for indexing rules, rulebooks and activities.

@

=
inter_package *IndexRules::find_rulebook(tree_inventory *inv, text_stream *marker) {
	for (int i=0; i<TreeLists::len(inv->rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->rulebook_nodes->list[i].node);
		if (Str::eq(marker, Metadata::read_optional_textual(pack, I"^index_id")))
			return pack;
	}
	return NULL;
}

inter_package *IndexRules::find_activity(tree_inventory *inv, text_stream *marker) {
	for (int i=0; i<TreeLists::len(inv->activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->activity_nodes->list[i].node);
		if (Str::eq(marker, Metadata::read_optional_textual(pack, I"^index_id")))
			return pack;
	}
	return NULL;
}

typedef struct ix_rule_context {
	struct inter_package *action_context;
	struct simplified_scene *scene_context;
} ix_rule_context;

ix_rule_context IndexRules::action_context(inter_package *an) {
	ix_rule_context rc;
	rc.action_context = an;
	rc.scene_context = NULL;
	return rc;
}
ix_rule_context IndexRules::scene_context(simplified_scene *s) {
	ix_rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = s;
	return rc;
}

ix_rule_context IndexRules::no_rule_context(void) {
	ix_rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = NULL;
	return rc;
}

int IndexRules::phrase_fits_rule_context(inter_package *entry, ix_rule_context rc) {
	if (entry == NULL) return FALSE;
	if (rc.action_context) {
/*				
	if (ActionRules::within_action_context(phrcd, rc.action_context) == FALSE)
		return FALSE;
*/
	}
	if (rc.scene_context) {
		inter_symbol *scene_symbol = Metadata::read_optional_symbol(entry, I"^during");
		if (scene_symbol == NULL) return FALSE;
		if (Inter::Packages::container(scene_symbol->definition) != rc.scene_context->pack) return FALSE;
	}
	return TRUE;
}

int RS_unique_xtra_no = 77777;
void IndexRules::index_rules_box(OUTPUT_STREAM, tree_inventory *inv,
	text_stream *titling_text, text_stream *doc_link,
	inter_package *rb_pack, char *text, int indent, int hide_behind_plus) {
	if (rb_pack == NULL) return;

	int xtra_no = RS_unique_xtra_no++;

	char *col = "e0e0e0";

	int n = IndexRules::no_rules(inv->of_tree, rb_pack);

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
		IndexRules::index_rulebook(OUT, inv->of_tree, rb_pack, NULL, IndexRules::no_rule_context(), &ignore_me);
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
int IndexRules::index_rulebook(OUTPUT_STREAM, inter_tree *I, inter_package *rb_pack, text_stream *billing, ix_rule_context rc, int *resp_count) {
	int suppress_outcome = FALSE, t = 0;
	if (rb_pack == NULL) return 0;
	if (Str::len(billing) > 0) {
		if (rc.action_context) suppress_outcome = TRUE;
		if (IndexRules::is_contextually_empty(I, rb_pack, rc)) suppress_outcome = TRUE;
	}
	t = IndexRules::index_booking_list(OUT, I, rb_pack, rc, billing, resp_count);
	if (suppress_outcome == FALSE) IndexRules::index_outcomes(OUT, I, rb_pack);
	IndexRules::rb_index_placements(OUT, I, rb_pack);
	return t;
}

int IndexRules::is_contextually_empty(inter_tree *I, inter_package *rb_pack, ix_rule_context rc) {
	if (rb_pack) {
		inter_symbol *wanted = PackageTypes::get(I, I"_rulebook_entry");
		inter_tree_node *D = Inter::Packages::definition(rb_pack);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted)
					if (IndexRules::phrase_fits_rule_context(entry, rc))
						return FALSE;
			}
		}
	}
	return TRUE;
}

int IndexRules::no_rules(inter_tree *I, inter_package *rb_pack) {
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

int IndexRules::index_booking_list(OUTPUT_STREAM, inter_tree *I,
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
				if (IndexRules::phrase_fits_rule_context(entry, rc)) {
					count++;
					IndexRules::br_start_index_line(OUT, prev, billing);
					*resp_count += IndexRules::index_rule(OUT, I, entry, rb_pack, rc);
				}
				prev = entry;
			}
		}
	}
	return count;
}

int IX_show_index_links = TRUE;

void IndexRules::list_suppress_indexed_links(void) {
	IX_show_index_links = FALSE;
}

void IndexRules::list_resume_indexed_links(void) {
	IX_show_index_links = TRUE;
}

void IndexRules::br_start_index_line(OUTPUT_STREAM, inter_package *prev, text_stream *billing) {
	HTML::open_indented_p(OUT, 2, "hanging");
	if ((Str::len(billing) > 0) && (IX_show_index_links)) IndexRules::br_show_linkage_icon(OUT, prev);
	WRITE("%S", billing);
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	if ((Str::len(billing) > 0) && (IX_show_index_links)) IndexRules::br_show_linkage_icon(OUT, prev);
}

@ And here's how the index links (if wanted) are chosen and plotted:

=
void IndexRules::br_show_linkage_icon(OUTPUT_STREAM, inter_package *prev) {
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
int IndexRules::index_rule(OUTPUT_STREAM, inter_tree *I, inter_package *R, inter_package *owner, ix_rule_context rc) {
	int no_responses_indexed = 0;
	int response_box_id = RS_unique_xtra_no++;
	text_stream *name = Metadata::read_optional_textual(R, I"^name");
	text_stream *italicised_text = Metadata::read_optional_textual(R, I"^index_name");
	text_stream *first_line = Metadata::read_optional_textual(R, I"^first_line");
	if (Str::len(italicised_text) > 0) @<Index the italicised text to do with the rule@>;
	if (Str::len(name) > 0) @<Index the rule name along with Javascript buttons@>;
	if ((Str::len(italicised_text) == 0) &&
		(Str::len(name) == 0) && (Str::len(first_line) > 0))
		@<Index some text extracted from the first line of the otherwise anonymous rule@>;
	@<Index a link to the first line of the rule's definition@>;
	@<Index the small type rule numbering@>;
	HTML_CLOSE("p");
	@<Index any applicability conditions@>;
	HTML_CLOSE("p");
	@<Index any response texts in the rule@>;
	return no_responses_indexed;
}

@<Index the italicised text to do with the rule@> =
	WRITE("<i>%S", italicised_text);
	if (rc.scene_context)
		WRITE(" during %S", PlotElement::scene_name(rc.scene_context));
	WRITE("</i>&nbsp;&nbsp;");

@

@d MAX_PASTEABLE_RULE_NAME_LENGTH 500

@<Index the rule name along with Javascript buttons@> =
	HTML::begin_colour(OUT, I"800000");
	WRITE("%S", name);
	HTML::end_colour(OUT);
	WRITE("&nbsp;&nbsp;");

	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%S", name);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>name</i> ");

	Str::clear(S);
	WRITE_TO(S, "The %S is not listed in the %S.\n", name,
		Metadata::read_optional_textual(owner, I"^printed_name"));
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>unlist</i>");
	DISCARD_TEXT(S)

	inter_symbol *R_symbol = Metadata::read_optional_symbol(R, I"^rule");
	if (R_symbol) {
		int c = 0;
		inter_symbol *wanted = PackageTypes::get(I, I"_response");
		inter_tree_node *D = Inter::Packages::definition(R);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted)
					c++;
			}
		}
		if (c > 0) {
			WRITE("&nbsp;&nbsp;");
			Index::extra_link_with(OUT, response_box_id, "responses");
			WRITE("%d", c);
		}
	}

@<Index any response texts in the rule@> =
	inter_symbol *R_symbol = Metadata::read_optional_symbol(R, I"^rule");
	if (R_symbol) {
		int c = 0;
		inter_symbol *wanted = PackageTypes::get(I, I"_response");
		inter_tree_node *D = Inter::Packages::definition(R);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted) {
					if (c == 0) Index::extra_div_open_nested(OUT, response_box_id, 2);
					else HTML_TAG("br");
					IndexRules::index_response(OUT, R, entry);
					c++;
				}
			}
		}
		if (c > 0) Index::extra_div_close_nested(OUT);
		no_responses_indexed = c;
	}

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	WRITE("(%S)", first_line);

@<Index a link to the first line of the rule's definition@> =
	int at = (int) Metadata::read_optional_numeric(R, I"^at");
	if (at > 0) Index::link(OUT, at);

@<Index the small type rule numbering@> =
	inter_ti id = Metadata::read_optional_numeric(R, I"^index_number");
	if (id > 0) {
		WRITE(" ");
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		if (id >= 2) WRITE("%d", id - 2); else WRITE("primitive");
		HTML_CLOSE("span");
	}

@<Index any applicability conditions@> =
	inter_symbol *R_symbol = Metadata::read_optional_symbol(R, I"^rule");
	if (R_symbol) {
		inter_symbol *wanted = PackageTypes::get(I, I"_applicability_condition");
		inter_tree_node *D = Inter::Packages::definition(R);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted) {
					HTML_TAG("br");
					int at = (int) Metadata::read_optional_numeric(entry, I"^at");
					if (at > 0) Index::link(OUT, at);
					WRITE("&nbsp;%S", Metadata::read_textual(entry, I"^index_text"));
				}
			}
		}
	}

@ When we index a response, we also provide a paste button for the source
text to assert a change:

=
void IndexRules::index_response(OUTPUT_STREAM, inter_package *rule_pack, inter_package *resp_pack) {
	int marker = (int) Metadata::read_numeric(resp_pack, I"^marker");
	text_stream *text = Metadata::read_textual(resp_pack, I"^index_text");
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	HTML_OPEN_WITH("span",
		"style=\"color: #ffffff; "
		"font-family: 'Courier New', Courier, monospace; background-color: #8080ff;\"");
	WRITE("&nbsp;&nbsp;%c&nbsp;&nbsp; ", 'A' + marker);
	HTML_CLOSE("span");
	HTML_OPEN_WITH("span", "style=\"color: #000066;\"");
	WRITE("%S", text);
	HTML_CLOSE("span");
	WRITE("&nbsp;&nbsp;");
	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%+W response (%c)", Metadata::read_textual(rule_pack, I"^name"), 'A' + marker);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>name</i>");
	WRITE("&nbsp;");
	Str::clear(S);
	WRITE_TO(S, "The %+W response (%c) is \"New text.\".");
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>set</i>");
	DISCARD_TEXT(S)
}

@ =
void IndexRules::index_outcomes(OUTPUT_STREAM, inter_tree *I, inter_package *rb_pack) {
	inter_symbol *wanted = PackageTypes::get(I, I"_rulebook_outcome");
	inter_tree_node *D = Inter::Packages::definition(rb_pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {	
				HTML::open_indented_p(OUT, 2, "hanging");
				WRITE("<i>outcome</i>&nbsp;&nbsp;");
				int is_def = (int) Metadata::read_optional_numeric(entry, I"^is_default");
				if (is_def) WRITE("<b>");
				WRITE("%S", Metadata::read_optional_textual(entry, I"^text"));
				if (is_def) WRITE("</b> (default)");
				WRITE(" - <i>");
				if (Metadata::read_optional_numeric(entry, I"^succeeds"))
					WRITE("a success");
				else if (Metadata::read_optional_numeric(entry, I"^fails"))
					WRITE("a failure");
				else
					WRITE("no outcome");
				WRITE("</i>");
				HTML_CLOSE("p");
			}
		}
	}

	if (Metadata::read_optional_numeric(rb_pack, I"^default_succeeds")) {
		HTML::open_indented_p(OUT, 2, "hanging");
		WRITE("<i>default outcome is success</i>");
		HTML_CLOSE("p");
	}
	if (Metadata::read_optional_numeric(rb_pack, I"^default_fails")) {
		HTML::open_indented_p(OUT, 2, "hanging");
		WRITE("<i>default outcome is failure</i>");
		HTML_CLOSE("p");
	}
}

void IndexRules::rb_index_placements(OUTPUT_STREAM, inter_tree *I, inter_package *rb_pack) {
	inter_symbol *wanted = PackageTypes::get(I, I"_rulebook_placement");
	inter_tree_node *D = Inter::Packages::definition(rb_pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {	
				WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
				HTML_OPEN_WITH("span", "class=\"smaller\"");
				WRITE("<i>NB:</i> %S", Metadata::read_optional_textual(entry, I"^text"));
				int at = (int) Metadata::read_optional_numeric(entry, I"^at");
				if (at > 0) Index::link(OUT, at);
				HTML_CLOSE("span");
				HTML_TAG("br");
			}
		}
	}
}

@ =
void IndexRules::index_activity(OUTPUT_STREAM, inter_tree *I, inter_package *pack, int indent) {
	int empty = (int) Metadata::read_optional_numeric(pack, I"^empty");
/*	if (av->indexing_data.activity_indexed) return;
	av->indexing_data.activity_indexed = TRUE;
	if (av->indexing_data.cross_references) empty = FALSE;
*/

	text_stream *text = NULL;
	text_stream *doc_link = Metadata::read_optional_textual(pack, I"^documentation");
	if (empty) text = I"There are no rules before, for or after this activity.";
	IndexRules::activity_rules_box(OUT, I, doc_link, pack, text, indent, TRUE);
}

@ =
void IndexRules::activity_rules_box(OUTPUT_STREAM, inter_tree *I, text_stream *doc_link,
	inter_package *av_pack, text_stream *text, int indent, int hide_behind_plus) {

	int xtra_no = RS_unique_xtra_no++;

	char *col = "e8e0c0";

	inter_symbol *before_s = Metadata::read_symbol(av_pack, I"^before_rulebook");
	inter_symbol *for_s = Metadata::read_symbol(av_pack, I"^for_rulebook");
	inter_symbol *after_s = Metadata::read_symbol(av_pack, I"^after_rulebook");
	inter_package *before_pack = Inter::Packages::container(before_s->definition);
	inter_package *for_pack = Inter::Packages::container(for_s->definition);
	inter_package *after_pack = Inter::Packages::container(after_s->definition);

	int n = IndexRules::no_rules(I, before_pack) + IndexRules::no_rules(I, for_pack) + IndexRules::no_rules(I, after_pack);

	TEMPORARY_TEXT(textual_name)
	text_stream *name = Metadata::read_optional_textual(av_pack, I"^name");
	if (Str::len(name) > 0) WRITE_TO(textual_name, "%S", name);
	else WRITE_TO(textual_name, "nameless");
	string_position start = Str::start(textual_name);
	Str::put(start, Characters::tolower(Str::get(start)));

	if (hide_behind_plus) {
		HTML::open_indented_p(OUT, indent+1, "tight");
		Index::extra_link(OUT, xtra_no);
		if (n == 0) HTML::begin_colour(OUT, I"808080");
		WRITE("%S", textual_name);
		@<Write the titling line of an activity rules box@>;
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

	HTML_CLOSE("p");
	DISCARD_TEXT(textual_name)

	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);

	int ignore_me = 0;
	IndexRules::index_rulebook(OUT, I, before_pack, I"before", IndexRules::no_rule_context(), &ignore_me);
	IndexRules::index_rulebook(OUT, I, for_pack, I"for", IndexRules::no_rule_context(), &ignore_me);
	IndexRules::index_rulebook(OUT, I, after_pack, I"after", IndexRules::no_rule_context(), &ignore_me);

	inter_symbol *wanted = PackageTypes::get(I, I"_activity_xref");
	inter_tree_node *D = Inter::Packages::definition(av_pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {	
				HTML::open_indented_p(OUT, 2, "tight");
				WRITE("NB: %S", Metadata::read_optional_textual(entry, I"^text"));
				int at = (int) Metadata::read_optional_numeric(entry, I"^at");
				if (at > 0) Index::link(OUT, at);
				HTML_CLOSE("p");
			}
		}
	}

	if (hide_behind_plus) {
		Index::extra_div_close(OUT, col);
	} else {
		HTML::close_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
		HTML_CLOSE("p");
	}
}

@<Write the titling line of an activity rules box@> =
	if (Str::len(doc_link) > 0) Index::DocReferences::link(OUT, doc_link);
	WRITE(" ... activity");
	int at = (int) Metadata::read_optional_numeric(av_pack, I"^at");
	if (at > 0) Index::link(OUT, at);
