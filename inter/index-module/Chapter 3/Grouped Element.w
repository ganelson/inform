[GroupedElement::] Grouped Element.

To write the Grouped actions element (A1) in the index, and also the detailed
per-action pages linked from it.

@ The element itself is easily made:

=
void GroupedElement::render(OUTPUT_STREAM, index_session *session) {
	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->action_nodes, MakeSynopticModuleStage::module_order);

	int f = FALSE;
	text_stream *current_area = I"___no_area___";
	text_stream *current_subarea = I"___no_sub_area___";
	inter_package *an_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an_pack, i, inv->action_nodes) {
		inter_ti assim = Metadata::read_optional_numeric(an_pack, I"^action_assimilated");
		if (assim) continue;
		inter_ti id = Metadata::read_numeric(an_pack, I"action_id");
		text_stream *this_area = Metadata::optional_textual(an_pack, I"^index_heading");
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
		text_stream *this_subarea = Metadata::optional_textual(an_pack, I"^index_subheading");
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
		inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
		if (oow) HTML::begin_span(OUT, I"indexdullred");
		WRITE("%S", Metadata::optional_textual(an_pack, I"^name"));
		if (oow) HTML::end_span(OUT);
		IndexUtilities::link_package(OUT, an_pack);
		IndexUtilities::detail_link(OUT, "A", (int) id, TRUE);
		f = TRUE;
	}
	if (f) HTML_CLOSE("p");
}

@ Everything else in this section is for the detail pages: there is one such
page for each action.

=
void GroupedElement::detail_pages(index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->action_nodes, MakeSynopticModuleStage::module_order);

	inter_package *an_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an_pack, i, inv->action_nodes) {
		inter_ti assim = Metadata::read_optional_numeric(an_pack, I"^action_assimilated");
		if (assim) continue;
		inter_ti id = Metadata::read_numeric(an_pack, I"action_id");
		text_stream index_file_struct; text_stream *OUT = &index_file_struct;
		InterpretIndex::open_file(OUT, NULL, I"A.html", I"<Actions", (int) id, session);
		@<Write details page for the action@>;
		InterpretIndex::close_index_file(OUT);
	}
}

@<Write details page for the action@> =
	IndexUtilities::banner_line(OUT, NULL, 1, I"^", I"Details",
		I"Index.Pages.ActionDetails.Heading", "../Actions.html", LD);
	HTML_TAG("hr");
	@<Show the fancy navigate-similar-actions menu@>;
	HTML_TAG("hr");
	@<Show the heading@>
	HTML_TAG("hr");
	@<Show the commands@>;
	@<Show the action variables@>;
	@<Show the rules relevant to this action@>;

@<Show the fancy navigate-similar-actions menu@> =
	text_stream *this_area = Metadata::optional_textual(an_pack, I"^index_heading");
	text_stream *this_subarea = Metadata::optional_textual(an_pack, I"^index_subheading");
	HTML_OPEN("p");
	WRITE("<b>%S - %S</b><br>", this_area, this_subarea);
	int c = 0;
	inter_package *an2_pack;
	LOOP_OVER_INVENTORY_PACKAGES(an2_pack, j, inv->action_nodes) {
		text_stream *this_area2 = Metadata::optional_textual(an2_pack, I"^index_heading");
		text_stream *this_subarea2 = Metadata::optional_textual(an2_pack, I"^index_subheading");
		if ((Str::eq(this_area, this_area2)) && (Str::eq(this_subarea, this_subarea2))) {
			if (c++ > 0) WRITE(", ");
			if (j == i) WRITE("<b>");
			WRITE("%S", Metadata::optional_textual(an2_pack, I"^name"));
			if (j == i) WRITE("</b>");
			if (j != i) IndexUtilities::detail_link(OUT, "A",
				(int) Metadata::read_numeric(an2_pack, I"action_id"), FALSE);
		}
	}
	HTML_CLOSE("p");

@<Show the heading@> =
	inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
	inter_ti requires_light = Metadata::read_numeric(an_pack, I"^requires_light");
	HTML_OPEN("p");
	if (oow) HTML::begin_span(OUT, I"indexdullred");
	WRITE("<b>");
	WRITE("%S", Metadata::optional_textual(an_pack, I"^display_name"));
	if (oow) HTML::end_span(OUT);
	WRITE("</b>");
	IndexUtilities::link_package(OUT, an_pack);
	if (requires_light) {
		WRITE(" (");
		Localisation::roman(OUT, LD, I"Index.Elements.A1.RequiresLight");
		WRITE(")");
	}
	WRITE(" (");	
	Localisation::italic(OUT, LD, I"Index.Elements.A1.PastTense");
	WRITE(" %S)", Metadata::optional_textual(an_pack, I"^past_name"));
	text_stream *spec = Metadata::optional_textual(an_pack, I"^specification");
	if (Str::len(spec) > 0)	WRITE(": %S", spec);
	HTML_CLOSE("p");
	text_stream *desc = Metadata::optional_textual(an_pack, I"^description");
	if (Str::len(desc) > 0)	{ HTML_OPEN("p"); WRITE("%S", desc); HTML_CLOSE("p"); }

@<Show the commands@> =
	HTML_OPEN("p");
	Localisation::bold(OUT, LD, I"Index.Elements.A1.CommandsHeading");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	int producers = 0;
	inter_package *line_pack;
	LOOP_THROUGH_SUBPACKAGES(line_pack, an_pack, I"_cg_line") {
		inter_symbol *xref = Metadata::required_symbol(line_pack, I"^line");
		CommandsElement::index_grammar_line(OUT,
			InterPackage::container(xref->definition), NULL, LD);
		producers++;
	}
	if (producers == 0) Localisation::bold(OUT, LD, I"Index.Elements.A1.NoCommands");
	HTML_CLOSE("p");

@<Show the action variables@> =
	if (GroupedElement::no_vars(an_pack, I) > 0) {
		HTML_OPEN("p");
		Localisation::bold(OUT, LD, I"Index.Elements.A1.ValuesHeading");
		HTML_CLOSE("p");
		GroupedElement::index_shv_set(OUT, I, an_pack);
	}

@<Show the rules relevant to this action@> =
	HTML_OPEN("p");
	Localisation::bold(OUT, LD, I"Index.Elements.A1.RulesHeading");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	int resp_count = 0;
	inter_ti oow = Metadata::read_optional_numeric(an_pack, I"^out_of_world");
	if (oow == FALSE) {
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"persuasion", I"persuasion", session);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"unsuccessful_attempt_by", I"unsuccessful attempt", session);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"setting_action_variables", I"set action variables for", session);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"before", I"before", session);
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"instead", I"instead of", session);
	}
	inter_symbol *check_s = Metadata::required_symbol(an_pack, I"^check_rulebook");
	inter_symbol *carry_out_s = Metadata::required_symbol(an_pack, I"^carry_out_rulebook");
	inter_symbol *report_s = Metadata::required_symbol(an_pack, I"^report_rulebook");
	inter_package *check_pack = InterPackage::container(check_s->definition);
	inter_package *carry_out_pack = InterPackage::container(carry_out_s->definition);
	inter_package *report_pack = InterPackage::container(report_s->definition);

	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, check_pack,
		I"check", I"check", session);
	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, carry_out_pack,
		I"carry_out", I"carry out", session);
	if (oow == FALSE)
		resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, NULL,
			I"after", I"after", session);
	resp_count += IndexRules::index_action_rules(OUT, inv, an_pack, report_pack,
		I"report", I"report", session);
	if (resp_count > 1) {
		Localisation::roman(OUT, LD, I"Index.Elements.A1.ResponseIcons");
		WRITE(":&nbsp;");
		IndexUtilities::extra_all_link_with(OUT, InterNodeList::array_len(inv->rule_nodes), "responses");
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
		WRITE("%S", Metadata::optional_textual(var_pack, I"^name"));
		IndexUtilities::link_package(OUT, var_pack);
		IndexUtilities::link_to_documentation(OUT, var_pack);
		WRITE(" - <i>%S</i>", Metadata::optional_textual(var_pack, I"^kind"));
		HTML_CLOSE("p");
	}
}
