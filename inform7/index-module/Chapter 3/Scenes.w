[IXScenes::] Scenes.

Parallel to the World index of space is the Scenes index of time,
and in this section we render it as HTML.

@ The mapping of time is on the one hand simpler than the mapping of space
since there is only one dimension, but on the other hand more complex since
scenes can be multiply present at the same instant of time (whereas rooms
cannot be multiply present at the same point in space). We resolve this
with a notation which takes a little bit of on-screen explanation, but
seems natural enough to learn in practice.

=
void IXScenes::index(OUTPUT_STREAM) {
	int nr = NUMBER_CREATED(scene);
	scene **sorted = Memory::calloc(nr, sizeof(scene *), INDEX_SORTING_MREASON);
	@<Sort the scenes@>;

	@<Tabulate the scenes@>;
	@<Show the legend for the scene table icons@>;
	@<Give details of each scene in turn@>;

	Memory::I7_array_free(sorted, INDEX_SORTING_MREASON, nr, sizeof(scene *));
}

void IXScenes::index_rules(OUTPUT_STREAM) {
	IXRules::index_scene(OUT); /* rules in generic scene-ending rulebooks */
	@<Show the generic scene-change rules@>;
}

@ As usual, we sort with the C library's |qsort|.

@<Sort the scenes@> =
	int i = 0;
	scene *sc;
	LOOP_OVER(sc, scene) sorted[i++] = sc;
	qsort(sorted, (size_t) nr, sizeof(scene *), IXScenes::compare_scenes);

@ The sorted ordering is used as-is later on, when we get to the details, but
for the tabulation it's refined further. First we have the start-of-play
scenes, in sorted order; then scenes with a condition for their beginning
(end 0), in sorted order; then scenes that don't, and which haven't been
covered as a result of one of the earlier ones, also in sorted order. (This
third category is usually empty except for scenes the author has forgotten
about and created but never made use of.)

@<Tabulate the scenes@> =
	for (int i=0; i<nr; i++) {
		scene *sc = sorted[i];
		if ((sc->start_of_play) || (sc == SC_entire_game))
			IXScenes::index_from_scene(OUT, sc, 0, START_OF_PLAY_END, NULL, sorted, nr);
	}
	for (int i=0; i<nr; i++) {
		scene *sc = sorted[i];
		if ((sc->ends[0].anchor_condition) && (sc != SC_entire_game))
			IXScenes::index_from_scene(OUT, sc, 0, START_OF_PLAY_END, NULL, sorted, nr);
	}
	for (int i=0; i<nr; i++) {
		scene *sc = sorted[i];
		if (sc->indexed == FALSE)
			IXScenes::index_from_scene(OUT, sc, 0, NEVER_HAPPENS_END, NULL, sorted, nr);
	}


@<Show the legend for the scene table icons@> =
	HTML_OPEN("p"); WRITE("Legend: ");
	IXScenes::scene_icon_legend(OUT, "WPB", "Begins when play begins");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "WhenC", "can begin whenever some condition holds");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "Segue", "follows when a previous scene ends");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "Simul", "begins simultaneously");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "WNever", "never begins");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "ENever", "never ends");
	WRITE("; ");
	IXScenes::scene_icon_legend(OUT, "Recurring", "recurring (can happen more than once)");
	WRITE(". <i>Scene names are italicised when and if they appear for a second "
		"or subsequent time because the scene can begin in more than one way</i>.");
	HTML_CLOSE("p");

@<Show the generic scene-change rules@> =
	HTML_OPEN("p");
	Index::anchor(OUT, I"SRULES");
	WRITE("<b>General rules applying to scene changes</b>");
	HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "When a scene begins", EMPTY_WORDING, NULL,
		Rulebooks::std(WHEN_SCENE_BEGINS_RB), NULL, NULL, 1, FALSE);
	IXRules::index_rules_box(OUT, "When a scene ends", EMPTY_WORDING, NULL,
		Rulebooks::std(WHEN_SCENE_ENDS_RB), NULL, NULL, 1, FALSE);

@<Give details of each scene in turn@> =
	Index::anchor(OUT, I"SDETAILS");
	for (int i=0; i<nr; i++) {
		HTML_TAG("hr");
		scene *sc = sorted[i];
		@<Give details of a specific scene@>;
	}

@ The curious condition about end 1 here is to avoid printing "Ends: Never"
in cases where fancier ends for the scene exist, so that the scene can, in
fact, end.

@<Give details of a specific scene@> =
	@<Index the name and recurrence status of the scene@>;
	if (sc == SC_entire_game) @<Explain the Entire Game scene@>;

	for (int end=0; end<sc->no_ends; end++) {
		if ((end == 1) && (sc->no_ends > 2) &&
			(sc->ends[1].anchor_condition==NULL) && (sc->ends[1].anchor_connectors==NULL))
			continue;
		@<Index the conditions for this scene end to occur@>;
		@<Index the rules which apply when this scene end occurs@>;
		if (end == 0) @<Index the rules which apply during this scene@>;
	}

@<Index the name and recurrence status of the scene@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	Index::anchor_numbered(OUT, sc->allocation_id);
	WRITE("<b>The <i>%+W</i> scene</b>", Scenes::get_name(sc));
	Index::link(OUT, Wordings::first_wn(Node::get_text(Instances::get_creating_sentence(sc->as_instance))));
	if (PropertyInferences::either_or_state(
		Instances::as_subject(sc->as_instance), P_recurring) > 0)
		WRITE("&nbsp;&nbsp;<i>recurring</i>");
	HTML_CLOSE("p");

@<Explain the Entire Game scene@> =
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("The Entire Game scene is built-in. It is going on whenever play is "
		"going on. (It is recurring so that if the story ends, but then resumes, "
		"it too will end but then begin again.)");
	HTML_CLOSE("p");

@<Index the rules which apply during this scene@> =
	int rbc = 0;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		if (Rulebooks::is_contextually_empty(rb, IXRules::scene_context(sc)) == FALSE) {
			if (rbc++ == 0) {
				HTML::open_indented_p(OUT, 1, "hanging");
				WRITE("<i>During this scene:</i>");
				HTML_CLOSE("p");
			}
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>%+W</i>", rb->primary_name); HTML_CLOSE("p");
			int ignore_me = 0;
			IXRules::index_rulebook(OUT, rb, "", IXRules::scene_context(sc), &ignore_me);
		}
	}

@<Index the conditions for this scene end to occur@> =
	HTML::open_indented_p(OUT, 1, "hanging");
	WRITE("<i>%s ", (end==0)?"Begins":"Ends");
	if (end >= 2) WRITE("%+W ", sc->ends[end].end_names);
	WRITE("when:</i> ");
	int count = 0;
	@<Index the play-begins condition@>;
	@<Index the I7 condition for a scene to end@>;
	@<Index connections to other scene ends@>;
	if (count == 0) WRITE("<b>never</b>");
	HTML_CLOSE("p");

@<Index the play-begins condition@> =
	if ((end==0) && (sc->start_of_play)) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		WRITE("<b>play begins</b>");
		count++;
	}

@<Index the I7 condition for a scene to end@> =
	if (sc->ends[end].anchor_condition) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		WRITE("%+W", Node::get_text(sc->ends[end].anchor_condition));
		Index::link(OUT, Wordings::first_wn(Node::get_text(sc->ends[end].anchor_condition_set)));
		count++;
	}

@<Index connections to other scene ends@> =
	for (scene_connector *scon = sc->ends[end].anchor_connectors; scon; scon=scon->next) {
		if (count > 0) {
			HTML_TAG("br");
			WRITE("<i>or when:</i> ");
		}
		wording NW = Instances::get_name(scon->connect_to->as_instance, FALSE);
		WRITE("<b>%+W</b> <i>%s</i>", NW, (scon->end==0)?"begins":"ends");
		if (scon->end >= 2) WRITE(" %+W", scon->connect_to->ends[scon->end].end_names);
		Index::link(OUT, Wordings::first_wn(Node::get_text(scon->where_said)));
		count++;
	}

@<Index the rules which apply when this scene end occurs@> =
	if (Rulebooks::is_empty(sc->ends[end].end_rulebook) == FALSE) {
		HTML::open_indented_p(OUT, 1, "hanging");
		WRITE("<i>What happens:</i>"); HTML_CLOSE("p");
		int ignore_me = 0;
		IXRules::index_rulebook(OUT, sc->ends[end].end_rulebook, "",
			IXRules::no_rule_context(), &ignore_me);
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
void IXScenes::index_from_scene(OUTPUT_STREAM, scene *sc, int depth,
	int end, scene *sc_from, scene **sorted, int nr) {
	HTML::open_indented_p(OUT, depth+1, "tight");
	@<Indicate the route by which this scene was reached@>;
	@<Name the scene in the table, italicised if we've seen it already@>;
	if (sc->indexed == FALSE) {
		@<Show the never-ends icon if appropriate@>;
		@<Show the recurring icon if appropriate@>;
	}
	HTML_CLOSE("p");
	if (sc->indexed) return;
	sc->indexed = TRUE;
	@<Indent to tabulate other scenes connected to the ends of this one@>;
}

@<Indicate the route by which this scene was reached@> =
	switch(end) {
		case 0: IXScenes::scene_icon(OUT, "Simul"); break;
		case 1: IXScenes::scene_icon(OUT, "Segue"); break;
		case START_OF_PLAY_END: break;
		case NEVER_HAPPENS_END: IXScenes::scene_icon(OUT, "WNever"); break;
		default:
			IXScenes::scene_icon(OUT, "Segue");
			WRITE("[ends %+W]&nbsp;", sc_from->ends[end].end_names); break;
	}
	if ((sc->indexed == FALSE) || (depth == 0)) {
		if (sc == SC_entire_game) IXScenes::scene_icon(OUT, "WPB");
		else if (sc->ends[0].anchor_condition) IXScenes::scene_icon(OUT, "WhenC");
		if (sc->start_of_play) IXScenes::scene_icon(OUT, "WPB");
	}

@<Name the scene in the table, italicised if we've seen it already@> =
	if (sc->indexed) WRITE("<i>");
	WRITE("%+W", Instances::get_name(sc->as_instance, FALSE));
	if (sc->indexed) WRITE("</i>");
	else Index::below_link_numbered(OUT, sc->allocation_id);

@<Show the never-ends icon if appropriate@> =
	int ways_to_end = 0;
	for (int e=1; e<sc->no_ends; e++) {
		if (sc->ends[e].anchor_connectors) ways_to_end++;
		if (sc->ends[e].anchor_condition) ways_to_end++;
	}
	if (ways_to_end == 0) IXScenes::scene_icon_append(OUT, "ENever");

@<Show the recurring icon if appropriate@> =
	inference_subject *subj = Instances::as_subject(sc->as_instance);
	if (PropertyInferences::either_or_state(subj, P_recurring) > UNKNOWN_CE)
		IXScenes::scene_icon_append(OUT, "Recurring");

@ And this is where the routine recurses, so that consequent scenes are
tabulated underneath the present one, indented one step further in (since
indentation is coupled to |depth|). First we recurse to scenes which end when
this one does; then to scenes which begin when this one ends.

@<Indent to tabulate other scenes connected to the ends of this one@> =
	for (int i=0; i<nr; i++) {
		scene *sc2 = sorted[i];
		scene_connector *scon;
		for (scon = sc2->ends[0].anchor_connectors; scon; scon=scon->next)
			if ((scon->connect_to == sc) && (scon->end >= 1))
				IXScenes::index_from_scene(OUT, sc2, depth + 1, scon->end, sc, sorted, nr);
	}
	for (int i=0; i<nr; i++) {
		scene *sc2 = sorted[i];
		scene_connector *scon;
		for (scon = sc2->ends[0].anchor_connectors; scon; scon=scon->next)
			if ((scon->connect_to == sc) && (scon->end == 0))
				IXScenes::index_from_scene(OUT, sc2, depth, scon->end, sc, sorted, nr);
	}

@ We have been using:

=
void IXScenes::scene_icon(OUTPUT_STREAM, char *si) {
	IXScenes::scene_icon_unspaced(OUT, si); WRITE("&nbsp;&nbsp;");
}

void IXScenes::scene_icon_append(OUTPUT_STREAM, char *si) {
	WRITE("&nbsp;&nbsp;"); IXScenes::scene_icon_unspaced(OUT, si);
}

void IXScenes::scene_icon_legend(OUTPUT_STREAM, char *si, char *gloss) {
	IXScenes::scene_icon_unspaced(OUT, si); WRITE("&nbsp;<i>%s</i>", gloss);
}

void IXScenes::scene_icon_unspaced(OUTPUT_STREAM, char *si) {
	HTML_TAG_WITH("img", "border=0 src=inform:/scene_icons/%s.png", si);
}

@ Lastly: the following is the criterion used for sorting the scenes into
their indexing order. The Entire Game always comes first, and then come the
rest in ascending alphabetical order.

=
int IXScenes::compare_scenes(const void *ent1, const void *ent2) {
	const scene *sc1 = *((const scene **) ent1);
	const scene *sc2 = *((const scene **) ent2);
	if ((sc1 == SC_entire_game) && (sc2 != SC_entire_game)) return -1;
	if ((sc1 != SC_entire_game) && (sc2 == SC_entire_game)) return 1;
	wording SW1 = Instances::get_name(sc1->as_instance, FALSE);
	wording SW2 = Instances::get_name(sc2->as_instance, FALSE);
	return Wordings::strcmp(SW1, SW2);
}
