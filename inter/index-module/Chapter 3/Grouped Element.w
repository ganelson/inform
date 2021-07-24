[GroupedElement::] Grouped Element.

To write the Grouped actions element (A1) in the index, and also the detailed
per-action pages linked from it.

@ =
void GroupedElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->action_nodes, Synoptic::module_order);

	int f = FALSE;
	text_stream *current_area = I"___no_area___";
	text_stream *current_subarea = I"___no_sub_area___";
	inter_package *an_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an_pack, i, inv->action_nodes) {
		text_stream *this_area = Metadata::read_optional_textual(an_pack, I"^index_heading");
		int suppress_comma = FALSE;
		if (Str::eq(this_area, current_area) == FALSE) {
			if (f) HTML_CLOSE("p");
			HTML_OPEN("p");
			WRITE("<b>%S</b>", this_area);
			HTML_CLOSE("p");
			current_area = this_area;
			current_subarea = I"___no_sub_area___";
			f = FALSE;
			suppress_comma = TRUE;
		}
		text_stream *this_subarea = Metadata::read_optional_textual(an_pack, I"^index_subheading");
		if (Str::eq(this_subarea, current_subarea) == FALSE) {
			if (f) HTML_CLOSE("p");
			HTML_OPEN("p");
			WRITE("<b>%S</b><br>", this_subarea);
			current_subarea = this_subarea;
			f = TRUE;
			suppress_comma = TRUE;
		}
		if (f == FALSE) HTML_OPEN("p");
		if ((f) && (suppress_comma == FALSE)) WRITE(", ");
		GroupedElement::index_p1(OUT, an_pack, FALSE, FALSE, i);
		f = TRUE;
	}
	if (f) HTML_CLOSE("p");
}

void GroupedElement::index_p1(OUTPUT_STREAM, inter_package *an_pack, int bold,
	int on_details_page, int i) {
	inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
	if (oow) HTML::begin_colour(OUT, I"800000");
	if (bold) WRITE("<b>");
	WRITE("%S", Metadata::read_optional_textual(an_pack, I"^name"));
	if (bold) WRITE("</b>");
	if (oow) HTML::end_colour(OUT);
	IndexUtilities::link_package(OUT, an_pack);
	IndexUtilities::detail_link(OUT, "A", i, (on_details_page)?FALSE:TRUE);
}

void GroupedElement::detail_pages(localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->action_nodes, Synoptic::module_order);

	inter_package *an_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an_pack, i, inv->action_nodes) {
		text_stream *OUT = InterpretIndex::open_file(NULL, I"A.html", I"<Actions", i, LD);
		IndexUtilities::banner_line(OUT, NULL, 1, I"^", I"Details",
			I"Index.Pages.ActionDetails.Heading", "../Actions.html", LD);
		HTML_TAG("hr");
		text_stream *this_area = Metadata::read_optional_textual(an_pack, I"^index_heading");
		text_stream *this_subarea = Metadata::read_optional_textual(an_pack, I"^index_subheading");
		HTML_OPEN("p");
		WRITE("<b>%S - %S</b><br>", this_area, this_subarea);
		int c = 0;
		inter_package *an2_pack;
		LOOP_OVER_INVENTORY_PACKAGES(an2_pack, j, inv->action_nodes) {
			text_stream *this_area2 = Metadata::read_optional_textual(an2_pack, I"^index_heading");
			text_stream *this_subarea2 = Metadata::read_optional_textual(an2_pack, I"^index_subheading");
			if ((Str::eq(this_area, this_area2)) && (Str::eq(this_subarea, this_subarea2))) {
				if (c++ > 0) WRITE(", ");
				if (j == i) WRITE("<b>");
				WRITE("%S", Metadata::read_optional_textual(an2_pack, I"^name"));
				if (j == i) WRITE("</b>");
				if (j != i) IndexUtilities::detail_link(OUT, "A", j, FALSE);
			}
		}
		HTML_CLOSE("p");
		HTML_TAG("hr");
		@<Show the heading@>
		HTML_TAG("hr");
		@<Show the commands@>;
		@<Show the action variables@>;
		@<Show the rules relevant to this action@>;
		InterpretIndex::close_index_file(OUT);
	}
}

@<Show the heading@> =
	inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
	inter_ti requires_light = Metadata::read_numeric(an_pack, I"^requires_light");
	HTML_OPEN("p");
	if (oow) HTML::begin_colour(OUT, I"800000");
	WRITE("<b>");
	WRITE("%S", Metadata::read_optional_textual(an_pack, I"^display_name"));
	if (oow) HTML::end_colour(OUT);
	WRITE("</b>");
	IndexUtilities::link_package(OUT, an_pack);
	if (requires_light) WRITE(" (requires light)");
	WRITE(" (<i>past tense</i> %S)", Metadata::read_optional_textual(an_pack, I"^past_name"));
	text_stream *spec = Metadata::read_optional_textual(an_pack, I"^specification");
	if (Str::len(spec) > 0)	WRITE(": %S", spec);
	HTML_CLOSE("p");
	text_stream *desc = Metadata::read_optional_textual(an_pack, I"^description");
	if (Str::len(desc) > 0)	{ HTML_OPEN("p"); WRITE("%S", desc); HTML_CLOSE("p"); }

@<Show the commands@> =
	HTML_OPEN("p"); WRITE("<b>Typed commands leading to this action</b>\n"); HTML_CLOSE("p");
	HTML_OPEN("p");
	int producers = 0;
	inter_package *line_pack;
	LOOP_THROUGH_SUBPACKAGES(line_pack, an_pack, I"_cg_line") {
		inter_symbol *xref = Metadata::read_symbol(line_pack, I"^line");
		CommandsElement::index_grammar_line(OUT, Inter::Packages::container(xref->definition), NULL, LD);
		producers++;
	}
	if (producers == 0) WRITE("<i>None</i>");
	HTML_CLOSE("p");

@<Show the action variables@> =
	if (GroupedElement::no_vars(an_pack, I) > 0) {
		HTML_OPEN("p"); WRITE("<b>Named values belonging to this action</b>\n"); HTML_CLOSE("p");
		GroupedElement::index_shv_set(OUT, I, an_pack);
	}

@<Show the rules relevant to this action@> =
	HTML_OPEN("p"); WRITE("<b>Rules controlling this action</b>"); HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("\n");
	int resp_count = 0;
	inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
	if (oow == FALSE) {
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"persuasion", I"persuasion", LD);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"unsuccessful_attempt_by", I"unsuccessful attempt", LD);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"setting_action_variables", I"set action variables for", LD);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"before", I"before", LD);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"instead", I"instead of", LD);
	}
	inter_symbol *check_s = Metadata::read_symbol(an_pack, I"^check_rulebook");
	inter_symbol *carry_out_s = Metadata::read_symbol(an_pack, I"^carry_out_rulebook");
	inter_symbol *report_s = Metadata::read_symbol(an_pack, I"^report_rulebook");
	inter_package *check_pack = Inter::Packages::container(check_s->definition);
	inter_package *carry_out_pack = Inter::Packages::container(carry_out_s->definition);
	inter_package *report_pack = Inter::Packages::container(report_s->definition);

	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, check_pack, I"check", I"check", LD);
	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, carry_out_pack, I"carry_out", I"carry out", LD);
	if (oow == FALSE)
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL, I"after", I"after", LD);
	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, report_pack, I"report", I"report", LD);
	if (resp_count > 1) {
		WRITE("Click on the speech-bubble icons to see the responses, "
			"or here to see all of them:");
		WRITE("&nbsp;");
		IndexUtilities::extra_all_link_with(OUT, TreeLists::len(inv->rule_nodes), "responses");
		WRITE("%d", resp_count);
	}
	HTML_CLOSE("p");

@ =
int GroupedElement::no_vars(inter_package *set, inter_tree *I) {
	return InterTree::no_subpackages(set, I"_shared_variable");
}

void GroupedElement::index_shv_set(OUTPUT_STREAM, inter_tree *I, inter_package *set) {
	inter_package *var_pack;
	LOOP_THROUGH_SUBPACKAGES(var_pack, set, I"_shared_variable") {
		HTML::open_indented_p(OUT, 2, "tight");
		WRITE("%S", Metadata::read_optional_textual(var_pack, I"^name"));
		IndexUtilities::link_package(OUT, var_pack);
		IndexUtilities::link_to_documentation(OUT, var_pack);
		WRITE(" - <i>%S</i>", Metadata::read_optional_textual(var_pack, I"^kind"));
		HTML_CLOSE("p");
	}
}
