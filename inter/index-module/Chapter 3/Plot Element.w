[PlotElement::] Plot Element.

To write the Plot element (Pl) in the index.

@ The mapping of time is on the one hand simpler than the mapping of space
since there is only one dimension, but on the other hand more complex since
scenes can be multiply present at the same instant of time (whereas rooms
cannot be multiply present at the same point in space). We resolve this
with a notation which takes a little bit of on-screen explanation, but
seems natural enough to learn in practice.

@d MAX_SCENE_ENDS 32 /* this must exceed 31 */

=
typedef struct simplified_scene {
	struct inter_package *pack;
	int no_ends;
	struct simplified_end *ends[MAX_SCENE_ENDS];
	int indexed_already;
	CLASS_DEFINITION
} simplified_scene;

typedef struct simplified_end {
	struct inter_package *end_pack;
	struct simplified_connector *anchor_connectors; /* linked list */
	CLASS_DEFINITION
} simplified_end;

typedef struct simplified_connector {
	struct inter_package *con_pack;
	struct simplified_scene *connect_to;
	struct simplified_connector *next; /* next in list of connectors for a scene end */
	CLASS_DEFINITION
} simplified_connector;

simplified_scene *PlotElement::simplified(inter_tree *I, inter_package *sc_pack) {
	simplified_scene *ssc = CREATE(simplified_scene);
	ssc->pack = sc_pack;
	ssc->no_ends = 0;
	ssc->indexed_already = FALSE;
	inter_symbol *wanted = PackageTypes::get(I, I"_scene_end");
	inter_symbol *wanted_within = PackageTypes::get(I, I"_scene_connector");
	inter_tree_node *D = Inter::Packages::definition(sc_pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				simplified_end *se = CREATE(simplified_end);
				se->end_pack = entry;
				se->anchor_connectors = NULL;
				LOOP_THROUGH_INTER_CHILDREN(B, C) {
					if (B->W.data[ID_IFLD] == PACKAGE_IST) {
						inter_package *inner_entry = Inter::Package::defined_by_frame(B);
						if (Inter::Packages::type(inner_entry) == wanted_within) {
							simplified_connector *scon = CREATE(simplified_connector);
							scon->con_pack = inner_entry;
							scon->next = NULL;
							if (se->anchor_connectors == NULL) {
								se->anchor_connectors = scon;
							} else {
								simplified_connector *last = se->anchor_connectors;
								while ((last) && (last->next)) last = last->next;
								last->next = scon;
							}
							scon->connect_to = NULL;
						}
					}
				}
				if (ssc->no_ends >= MAX_SCENE_ENDS) internal_error("too many scene ends");
				ssc->ends[ssc->no_ends++] = se;
			}
		}
	}
	return ssc;
}

int PlotElement::is_entire_game(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^is_entire_game")) return TRUE;
	return FALSE;
}

int PlotElement::recurs(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^recurs")) return TRUE;
	return FALSE;
}

int PlotElement::never_ends(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^never_ends")) return TRUE;
	return FALSE;
}

int PlotElement::starts_at_start_of_play(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^starts")) return TRUE;
	return FALSE;
}

int PlotElement::starts_on_condition(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^starts_on_condition")) return TRUE;
	return FALSE;
}

int PlotElement::no_ends(simplified_scene *ssc) {
	return ssc->no_ends;
}

text_stream *PlotElement::scene_name(simplified_scene *ssc) {
	return Metadata::read_textual(ssc->pack, I"^name");
}

text_stream *PlotElement::end_name(simplified_end *se) {
	return Metadata::read_textual(se->end_pack, I"^name");
}

text_stream *PlotElement::anchor_condition(simplified_end *se) {
	return Metadata::read_textual(se->end_pack, I"^condition");
}

int PlotElement::has_anchor_condition(simplified_end *se) {
	if (Str::len(PlotElement::anchor_condition(se)) > 0) return TRUE;
	return FALSE;
}

int PlotElement::anchor_condition_set_at(simplified_end *se) {
	return (int) Metadata::read_optional_numeric(se->end_pack, I"^at");
}

inter_symbol *PlotElement::end_rulebook(simplified_end *se) {
	return Metadata::read_optional_symbol(se->end_pack, I"^rulebook");
}

simplified_scene *PlotElement::connects_to(simplified_connector *scon) {
	if (scon->connect_to) return scon->connect_to;
	inter_symbol *sc_symbol = Metadata::read_optional_symbol(scon->con_pack, I"^to");
	if (sc_symbol) {
		inter_package *to_pack = Inter::Packages::container(sc_symbol->definition);
		simplified_scene *ssc;
		LOOP_OVER(ssc, simplified_scene)
			if (ssc->pack == to_pack) {
				scon->connect_to = ssc;
				return ssc;
			}
	}
	internal_error("scene metadata broken: bad connector");
	return NULL;
}

int PlotElement::scon_end(simplified_connector *scon) {
	return (int) Metadata::read_numeric(scon->con_pack, I"^end");
}

int PlotElement::scon_at(simplified_connector *scon) {
	return (int) Metadata::read_numeric(scon->con_pack, I"^at");
}

void PlotElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->scene_nodes, PlotElement::scene_order);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);

	int no_scenes = TreeLists::len(inv->scene_nodes);
	simplified_scene **plot = Memory::calloc(no_scenes, sizeof(simplified_scene *), SCENE_SORTING_MREASON);
	for (int i=0; i<no_scenes; i++)
		plot[i] = PlotElement::simplified(I, Inter::Package::defined_by_frame(inv->scene_nodes->list[i].node));

	@<Tabulate the scenes@>;
	@<Show the legend for the scene table icons@>;
	@<Give details of each scene in turn@>;
	Memory::I7_array_free(plot, SCENE_SORTING_MREASON, no_scenes, sizeof(simplified_scene *));
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
	LOOP_OVER(ssc, simplified_scene)
		if ((PlotElement::starts_at_start_of_play(ssc)) || (PlotElement::is_entire_game(ssc)))
			PlotElement::index_from_scene(OUT, plot, ssc, 0, START_OF_PLAY_END, NULL);
	LOOP_OVER(ssc, simplified_scene)
		if ((PlotElement::starts_on_condition(ssc)) && (PlotElement::is_entire_game(ssc) == FALSE))
			PlotElement::index_from_scene(OUT, plot, ssc, 0, START_OF_PLAY_END, NULL);
	LOOP_OVER(ssc, simplified_scene)
		if (ssc->indexed_already == FALSE)
			PlotElement::index_from_scene(OUT, plot, ssc, 0, NEVER_HAPPENS_END, NULL);

@<Show the legend for the scene table icons@> =
	HTML_OPEN("p"); WRITE("Legend: ");
	PlotElement::scene_icon_legend(OUT, "WPB", "Begins when play begins");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "WhenC", "can begin whenever some condition holds");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Segue", "follows when a previous scene ends");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Simul", "begins simultaneously");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "WNever", "never begins");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "ENever", "never ends");
	WRITE("; ");
	PlotElement::scene_icon_legend(OUT, "Recurring", "recurring (can happen more than once)");
	WRITE(". <i>Scene names are italicised when and if they appear for a second "
		"or subsequent time because the scene can begin in more than one way</i>.");
	HTML_CLOSE("p");


@<Give details of each scene in turn@> =
	IndexUtilities::anchor(OUT, I"SDETAILS");
	simplified_scene *ssc;
	LOOP_OVER(ssc, simplified_scene) {
		HTML_TAG("hr");
		@<Give details of a specific scene@>;
	}

@ The curious condition about end 1 here is to avoid printing "Ends: Never"
in cases where fancier ends for the scene exist, so that the scene can, in
fact, end.

@<Give details of a specific scene@> =
	@<Index the name and recurrence status of the scene@>;
	if (PlotElement::is_entire_game(ssc)) @<Explain the Entire Game scene@>;

	for (int end=0; end<PlotElement::no_ends(ssc); end++) {
		if ((end == 1) && (PlotElement::no_ends(ssc) > 2) &&
			(PlotElement::has_anchor_condition(ssc->ends[1]) == FALSE) &&
			(ssc->ends[1]->anchor_connectors==NULL))
			continue;
		@<Index the conditions for this scene end to occur@>;
		@<Index the rules which apply when this scene end occurs@>;
		if (end == 0) @<Index the rules which apply during this scene@>;
	}

@<Index the name and recurrence status of the scene@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	IndexUtilities::anchor_numbered(OUT, ssc->allocation_id);
	WRITE("<b>The <i>%S</i> scene</b>", Metadata::read_textual(ssc->pack, I"^name"));
	int at = (int) Metadata::read_optional_numeric(ssc->pack, I"^at");
	if (at > 0) IndexUtilities::link(OUT, at);
	if (PlotElement::recurs(ssc)) WRITE("&nbsp;&nbsp;<i>recurring</i>");
	HTML_CLOSE("p");

@<Explain the Entire Game scene@> =
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("The Entire Game scene is built-in. It is going on whenever play is "
		"going on. (It is recurring so that if the story ends, but then resumes, "
		"it too will end but then begin again.)");
	HTML_CLOSE("p");

@<Index the rules which apply during this scene@> =
	int rbc = 0;
	for (int i=0; i<TreeLists::len(inv->rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->rulebook_nodes->list[i].node);
		if (IndexRules::is_contextually_empty(I, pack, IndexRules::scene_context(ssc)) == FALSE) {
			if (rbc++ == 0) {
				HTML::open_indented_p(OUT, 1, "hanging");
				WRITE("<i>During this scene:</i>");
				HTML_CLOSE("p");
			}
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>%S</i>", Metadata::read_textual(pack, I"^printed_name")); HTML_CLOSE("p");
			IndexRules::rulebook_list(OUT, I, pack, I"", IndexRules::scene_context(ssc), LD);
		}
	}

@<Index the conditions for this scene end to occur@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	WRITE("<i>%s ", (end==0)?"Begins":"Ends");
	if (end >= 2) WRITE("%S ", PlotElement::end_name(ssc->ends[end]));
	WRITE("when:</i> ");
	int count = 0;
	@<Index the play-begins condition@>;
	@<Index the I7 condition for a scene to end@>;
	@<Index connections to other scene ends@>;
	if (count == 0) WRITE("<b>never</b>");
	HTML_CLOSE("p");

@<Index the play-begins condition@> =
	if ((end==0) && (PlotElement::starts_at_start_of_play(ssc))) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		WRITE("<b>play begins</b>");
		count++;
	}

@<Index the I7 condition for a scene to end@> =
	if (PlotElement::has_anchor_condition(ssc->ends[end])) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		WRITE("%S", PlotElement::anchor_condition(ssc->ends[end]));
		int at = PlotElement::anchor_condition_set_at(ssc->ends[end]);
		if (at > 0) IndexUtilities::link(OUT, at);
		count++;
	}

@<Index connections to other scene ends@> =
	for (simplified_connector *scon = ssc->ends[end]->anchor_connectors; scon; scon=scon->next) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		simplified_scene *to_ssc = PlotElement::connects_to(scon);
		text_stream *NW = PlotElement::scene_name(to_ssc);
		WRITE("<b>%S</b> <i>%s</i>", NW, (PlotElement::scon_end(scon)==0)?"begins":"ends");
		if (PlotElement::scon_end(scon) >= 2) WRITE(" %S", PlotElement::end_name(to_ssc->ends[PlotElement::scon_end(scon)]));
		IndexUtilities::link(OUT, PlotElement::scon_at(scon));
		count++;
	}

@<Index the rules which apply when this scene end occurs@> =
	inter_symbol *rb = PlotElement::end_rulebook(ssc->ends[end]);
	inter_package *rb_pack = Inter::Packages::container(rb->definition);
	if (IndexRules::is_empty(I, rb_pack) == FALSE) {
		HTML::open_indented_p(OUT, 1, "hanging");
		WRITE("<i>What happens:</i>"); HTML_CLOSE("p");
		IndexRules::rulebook_list(OUT, I, rb_pack, I"", IndexRules::no_rule_context(), LD);
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
void PlotElement::index_from_scene(OUTPUT_STREAM, simplified_scene **plot,
	simplified_scene *ssc, int depth, int end, simplified_scene *sc_from) {
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
			WRITE("[ends %S]&nbsp;", PlotElement::end_name(sc_from->ends[end])); break;
	}
	if ((ssc->indexed_already == FALSE) || (depth == 0)) {
		if (PlotElement::is_entire_game(ssc)) PlotElement::scene_icon(OUT, "WPB");
		else if (PlotElement::starts_on_condition(ssc)) PlotElement::scene_icon(OUT, "WhenC");
		if (PlotElement::starts_at_start_of_play(ssc)) PlotElement::scene_icon(OUT, "WPB");
	}

@<Name the scene in the table, italicised if we've seen it already@> =
	if (ssc->indexed_already) WRITE("<i>");
	WRITE("%S", Metadata::read_textual(ssc->pack, I"^name"));
	if (ssc->indexed_already) WRITE("</i>");
	else IndexUtilities::below_link_numbered(OUT, ssc->allocation_id);

@<Show the never-ends icon if appropriate@> =
	if (PlotElement::never_ends(ssc))
		PlotElement::scene_icon_append(OUT, "ENever");

@<Show the recurring icon if appropriate@> =
	if (PlotElement::recurs(ssc))
		PlotElement::scene_icon_append(OUT, "Recurring");

@ And this is where the routine recurses, so that consequent scenes are
tabulated underneath the present one, indented one step further in (since
indentation is coupled to |depth|). First we recurse to scenes which end when
this one does; then to scenes which begin when this one ends.

@<Indent to tabulate other scenes connected to the ends of this one@> =
	simplified_scene *ssc2;
	LOOP_OVER(ssc2, simplified_scene) {
		for (simplified_connector *scon = ssc2->ends[0]->anchor_connectors; scon; scon=scon->next)
			if ((PlotElement::connects_to(scon) == ssc) && (PlotElement::scon_end(scon) >= 1))
				PlotElement::index_from_scene(OUT, plot, ssc2, depth + 1, PlotElement::scon_end(scon), ssc);
	}
	LOOP_OVER(ssc2, simplified_scene) {
		for (simplified_connector *scon = ssc2->ends[0]->anchor_connectors; scon; scon=scon->next)
			if ((PlotElement::connects_to(scon) == ssc) && (PlotElement::scon_end(scon) == 0))
				PlotElement::index_from_scene(OUT, plot, ssc2, depth, PlotElement::scon_end(scon), ssc);
	}

@ We have been using:

=
void PlotElement::scene_icon(OUTPUT_STREAM, char *si) {
	PlotElement::scene_icon_unspaced(OUT, si); WRITE("&nbsp;&nbsp;");
}

void PlotElement::scene_icon_append(OUTPUT_STREAM, char *si) {
	WRITE("&nbsp;&nbsp;"); PlotElement::scene_icon_unspaced(OUT, si);
}

void PlotElement::scene_icon_legend(OUTPUT_STREAM, char *si, char *gloss) {
	PlotElement::scene_icon_unspaced(OUT, si); WRITE("&nbsp;<i>%s</i>", gloss);
}

void PlotElement::scene_icon_unspaced(OUTPUT_STREAM, char *si) {
	HTML_TAG_WITH("img", "border=0 src=inform:/scene_icons/%s.png", si);
}

@ Lastly: the following is the criterion used for sorting the scenes into
their indexing order. The Entire Game always comes first, and then come the
rest in ascending alphabetical order.

=
int PlotElement::scene_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *sc1 = Inter::Package::defined_by_frame(P1);
	inter_package *sc2 = Inter::Package::defined_by_frame(P2);
	if (Metadata::read_optional_numeric(sc1, I"^is_entire_game")) return -1;
	if (Metadata::read_optional_numeric(sc2, I"^is_entire_game")) return 1;
	text_stream *SW1 = Metadata::read_textual(sc1, I"^name");
	text_stream *SW2 = Metadata::read_textual(sc2, I"^name");
	return Str::cmp(SW1, SW2);
}
