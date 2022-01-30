[PlotElement::] Plot Element.

To write the Plot element (Pl) in the index.

@ The mapping of time is on the one hand simpler than the mapping of space
since there is only one dimension, but on the other hand more complex since
scenes can be multiply present at the same instant of time (whereas rooms
cannot be multiply present at the same point in space). We resolve this
with a notation which takes a little bit of on-screen explanation, but
seems natural enough to learn in practice.

=
void PlotElement::render(OUTPUT_STREAM, index_session *session) {
	tree_inventory *inv = Indexing::get_inventory(session);
	inter_tree *I = Indexing::get_tree(session);
	localisation_dictionary *LD = Indexing::get_localisation(session);
	linked_list *L = Indexing::get_list_of_scenes(session);
	@<Tabulate the scenes@>;
	@<Show the legend for the scene table icons@>;
	@<Give details of each scene in turn@>;
}

@ The sorted ordering is used as-is later on, when we get to the details, but
for the tabulation it's refined further. First we have the start-of-play
scenes, in sorted order; then scenes with a condition for their beginning
(end 0), in sorted order; then scenes that don't, and which haven't been
covered as a result of one of the earlier ones, also in sorted order. (This
third category is usually empty except for scenes the author has forgotten
about and created but never made use of.)

@<Tabulate the scenes@> =
	simplified_scene *ssc;
	LOOP_OVER_LINKED_LIST(ssc, simplified_scene, L)
		ssc->indexed_already = FALSE;
	LOOP_OVER_LINKED_LIST(ssc, simplified_scene, L)
		if ((FauxScenes::starts_at_start_of_play(ssc)) || (FauxScenes::is_entire_game(ssc)))
			PlotElement::index_from_scene(OUT, ssc, 0, START_OF_PLAY_END, NULL, session);
	LOOP_OVER_LINKED_LIST(ssc, simplified_scene, L)
		if ((FauxScenes::starts_on_condition(ssc)) && (FauxScenes::is_entire_game(ssc) == FALSE))
			PlotElement::index_from_scene(OUT, ssc, 0, START_OF_PLAY_END, NULL, session);
	LOOP_OVER_LINKED_LIST(ssc, simplified_scene, L)
		if (ssc->indexed_already == FALSE)
			PlotElement::index_from_scene(OUT, ssc, 0, NEVER_HAPPENS_END, NULL, session);

@<Show the legend for the scene table icons@> =
	HTML_OPEN("p"); 
	Localisation::italic(OUT, LD, I"Index.Elements.Pl.LegendHeading");
	WRITE(": ");
	PlotElement::scene_icon_legend(OUT, "WPB", LD, I"Index.Elements.Pl.WPBLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "WhenC", LD, I"Index.Elements.Pl.WhenCLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Segue", LD, I"Index.Elements.Pl.SegueLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Simul", LD, I"Index.Elements.Pl.SimulLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "WNever", LD, I"Index.Elements.Pl.WNeverLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "ENever", LD, I"Index.Elements.Pl.ENeverLegend");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Recurring", LD, I"Index.Elements.Pl.RecurringLegend");
	WRITE(". ");
	Localisation::italic(OUT, LD, I"Index.Elements.Pl.LegendNote");
	HTML_CLOSE("p");

@<Give details of each scene in turn@> =
	IndexUtilities::anchor(OUT, I"SDETAILS");
	simplified_scene *ssc;
	LOOP_OVER_LINKED_LIST(ssc, simplified_scene, L) {
		HTML_TAG("hr");
		@<Give details of a specific scene@>;
	}

@ The curious condition about end 1 here is to avoid printing "Ends: Never"
in cases where fancier ends for the scene exist, so that the scene can, in
fact, end.

@<Give details of a specific scene@> =
	@<Index the name and recurrence status of the scene@>;
	if (FauxScenes::is_entire_game(ssc)) @<Explain the Entire Game scene@>;

	for (int end=0; end<FauxScenes::no_ends(ssc); end++) {
		if ((end == 1) && (FauxScenes::no_ends(ssc) > 2) &&
			(FauxScenes::has_anchor_condition(ssc->ends[1]) == FALSE) &&
			(ssc->ends[1]->anchor_connectors==NULL))
			continue;
		@<Index the conditions for this scene end to occur@>;
		@<Index the rules which apply when this scene end occurs@>;
		if (end == 0) @<Index the rules which apply during this scene@>;
	}

@<Index the name and recurrence status of the scene@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	IndexUtilities::anchor_numbered(OUT, ssc->allocation_id);
	Localisation::bold_t(OUT, LD, I"Index.Elements.Pl.SceneName",
		Metadata::read_textual(ssc->pack, I"^name"));
	IndexUtilities::link_package(OUT, ssc->pack);
	if (FauxScenes::recurs(ssc)) {
		WRITE("&nbsp;&nbsp;");
		Localisation::italic(OUT, LD, I"Index.Elements.Pl.Recurring");
	}
	HTML_CLOSE("p");

@<Explain the Entire Game scene@> =
	HTML::open_indented_p(OUT, 1, "tight");
	Localisation::roman(OUT, LD, I"Index.Elements.Pl.EntireGame");
	HTML_CLOSE("p");

@<Index the rules which apply during this scene@> =
	int rbc = 0;
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->rulebook_nodes)
		if (IndexRules::is_contextually_empty(I, pack,
			IndexRules::scene_context(ssc)) == FALSE) {
			if (rbc++ == 0) {
				HTML::open_indented_p(OUT, 1, "hanging");
				Localisation::italic(OUT, LD, I"Index.Elements.Pl.During");
				HTML_CLOSE("p");
			}
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>%S</i>", Metadata::read_textual(pack, I"^printed_name"));
			HTML_CLOSE("p");
			IndexRules::rulebook_list(OUT, I, pack, I"",
				IndexRules::scene_context(ssc), session);
		}

@<Index the conditions for this scene end to occur@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	if (end == 0) Localisation::italic(OUT, LD, I"Index.Elements.Pl.BeginsWhen");
	if (end == 1) Localisation::italic(OUT, LD, I"Index.Elements.Pl.EndsWhen");
	if (end >= 2) Localisation::italic_t(OUT, LD, I"Index.Elements.Pl.EndsUnusuallyWhen",
		FauxScenes::end_name(ssc->ends[end]));
	WRITE(" ");
	int count = 0;
	@<Index the play-begins condition@>;
	@<Index the I7 condition for a scene to end@>;
	@<Index connections to other scene ends@>;
	if (count == 0) Localisation::bold(OUT, LD, I"Index.Elements.Pl.Never");
	HTML_CLOSE("p");

@<Index the play-begins condition@> =
	if ((end==0) && (FauxScenes::starts_at_start_of_play(ssc))) {
		if (count > 0) {
			HTML_TAG("br");
			Localisation::italic(OUT, LD, I"Index.Elements.Pl.OrWhen");
			WRITE(" ");
		}
		WRITE("<b>play begins</b>");
		count++;
	}

@<Index the I7 condition for a scene to end@> =
	if (FauxScenes::has_anchor_condition(ssc->ends[end])) {
		if (count > 0) {
			HTML_TAG("br");
			Localisation::italic(OUT, LD, I"Index.Elements.Pl.OrWhen");
			WRITE(" ");
		}
		WRITE("%S", FauxScenes::anchor_condition(ssc->ends[end]));
		int at = FauxScenes::anchor_condition_set_at(ssc->ends[end]);
		if (at > 0) IndexUtilities::link(OUT, at);
		count++;
	}

@<Index connections to other scene ends@> =
	for (simplified_connector *scon = ssc->ends[end]->anchor_connectors; scon;
		scon=scon->next) {
		if (count > 0) {
			HTML_TAG("br");
			Localisation::italic(OUT, LD, I"Index.Elements.Pl.OrWhen");
			WRITE(" ");
		}
		simplified_scene *to_ssc = FauxScenes::connects_to(scon, session);
		text_stream *NW = FauxScenes::scene_name(to_ssc);
		WRITE("<b>%S</b> <i>%s</i>", NW,
			(FauxScenes::scon_end(scon)==0)?"begins":"ends");
		if (FauxScenes::scon_end(scon) >= 2)
			WRITE(" %S", FauxScenes::end_name(to_ssc->ends[FauxScenes::scon_end(scon)]));
		IndexUtilities::link(OUT, FauxScenes::scon_at(scon));
		count++;
	}

@<Index the rules which apply when this scene end occurs@> =
	inter_symbol *rb = FauxScenes::end_rulebook(ssc->ends[end]);
	inter_package *rb_pack = InterPackage::container(rb->definition);
	if (IndexRules::is_empty(I, rb_pack) == FALSE) {
		HTML::open_indented_p(OUT, 1, "hanging");
		Localisation::italic(OUT, LD, I"Index.Elements.Pl.WhatHappens");
		WRITE(":"); HTML_CLOSE("p");
		IndexRules::rulebook_list(OUT, I, rb_pack, I"",
			IndexRules::no_rule_context(), session);
	}

@h Table of Scenes.
We finally return to the table of scenes. The following is recursive, and
is called at the top level for each scene in turn which starts at the start
of play (see above).

A scene entry can be arrived at in three ways: through one of its ends, in
which case |end| is the number (0 for begins, 1 for standard ends, and so on),
or through being already active at the start of play, or through being covered
in the index even though it never happens in play. This means we need two
additional |end| numbers. They are only ever used at the top level, that is,
on the initial call when |depth| is 0.

@d START_OF_PLAY_END -1
@d NEVER_HAPPENS_END -2

=
void PlotElement::index_from_scene(OUTPUT_STREAM, simplified_scene *ssc, int depth,
	int end, simplified_scene *sc_from, index_session *session) {
	linked_list *L = Indexing::get_list_of_scenes(session);
	HTML::open_indented_p(OUT, depth+1, "tight");
	@<Indicate the route by which this scene was reached@>;
	@<Name the scene in the table, italicised if we've seen it already@>;
	if (ssc->indexed_already == FALSE) {
		@<Show the never-ends icon if appropriate@>;
		@<Show the recurring icon if appropriate@>;
	}
	HTML_CLOSE("p");
	if (ssc->indexed_already) return;
	ssc->indexed_already = TRUE;
	@<Indent to tabulate other scenes connected to the ends of this one@>;
}

@<Indicate the route by which this scene was reached@> =
	switch(end) {
		case 0: PlotElement::scene_icon(OUT, "Simul"); break;
		case 1: PlotElement::scene_icon(OUT, "Segue"); break;
		case START_OF_PLAY_END: break;
		case NEVER_HAPPENS_END: PlotElement::scene_icon(OUT, "WNever"); break;
		default:
			PlotElement::scene_icon(OUT, "Segue");
			WRITE("[ends %S]&nbsp;", FauxScenes::end_name(sc_from->ends[end])); break;
	}
	if ((ssc->indexed_already == FALSE) || (depth == 0)) {
		if (FauxScenes::is_entire_game(ssc)) PlotElement::scene_icon(OUT, "WPB");
		else if (FauxScenes::starts_on_condition(ssc)) PlotElement::scene_icon(OUT, "WhenC");
		if (FauxScenes::starts_at_start_of_play(ssc)) PlotElement::scene_icon(OUT, "WPB");
	}

@<Name the scene in the table, italicised if we've seen it already@> =
	if (ssc->indexed_already) WRITE("<i>");
	WRITE("%S", Metadata::read_textual(ssc->pack, I"^name"));
	if (ssc->indexed_already) WRITE("</i>");
	else IndexUtilities::below_link_numbered(OUT, ssc->allocation_id);

@<Show the never-ends icon if appropriate@> =
	if (FauxScenes::never_ends(ssc))
		PlotElement::scene_icon_append(OUT, "ENever");

@<Show the recurring icon if appropriate@> =
	if (FauxScenes::recurs(ssc))
		PlotElement::scene_icon_append(OUT, "Recurring");

@ And this is where the routine recurses, so that consequent scenes are
tabulated underneath the present one, indented one step further in (since
indentation is coupled to |depth|). First we recurse to scenes which end when
this one does; then to scenes which begin when this one ends.

@<Indent to tabulate other scenes connected to the ends of this one@> =
	simplified_scene *ssc2;
	LOOP_OVER_LINKED_LIST(ssc2, simplified_scene, L)
		for (simplified_connector *scon = ssc2->ends[0]->anchor_connectors; scon; scon=scon->next)
			if ((FauxScenes::connects_to(scon, session) == ssc) && (FauxScenes::scon_end(scon) >= 1))
				PlotElement::index_from_scene(OUT, ssc2, depth + 1, FauxScenes::scon_end(scon), ssc, session);
	LOOP_OVER_LINKED_LIST(ssc2, simplified_scene, L)
		for (simplified_connector *scon = ssc2->ends[0]->anchor_connectors; scon; scon=scon->next)
			if ((FauxScenes::connects_to(scon, session) == ssc) && (FauxScenes::scon_end(scon) == 0))
				PlotElement::index_from_scene(OUT, ssc2, depth, FauxScenes::scon_end(scon), ssc, session);

@ We have been using:

=
void PlotElement::scene_icon(OUTPUT_STREAM, char *si) {
	PlotElement::scene_icon_unspaced(OUT, si); WRITE("&nbsp;&nbsp;");
}

void PlotElement::scene_icon_append(OUTPUT_STREAM, char *si) {
	WRITE("&nbsp;&nbsp;"); PlotElement::scene_icon_unspaced(OUT, si);
}

void PlotElement::scene_icon_legend(OUTPUT_STREAM, char *si, localisation_dictionary *LD,
	text_stream *gloss) {
	PlotElement::scene_icon_unspaced(OUT, si);
	WRITE("&nbsp;");
	Localisation::italic(OUT, LD, gloss);
}

void PlotElement::scene_icon_unspaced(OUTPUT_STREAM, char *si) {
	HTML_TAG_WITH("img", "border=0 src=inform:/scene_icons/%s.png", si);
}
