[Data::Objects::] Index Physical World.

This section masterminds the creation of the World and Kinds index
pages, though it delegates much of the work elsewhere. Though it does belong
to core Inform, these indexes will look pretty sparse if the spatial Plugins
aren't plugged in.

@h The Kinds page.

=
void Data::Objects::page_Kinds(OUTPUT_STREAM) {
	@<Assign each kind of object a corresponding documentation symbol@>;
	Kinds::Index::index_kinds(OUT, 1);
}

@ The following routine looks at each kind of object, takes the first word
of its name, prefixes "kind" and looks to see if there is a documentation
symbol of that name: if there is, it attaches it to the relevant field of
the kind.

@<Assign each kind of object a corresponding documentation symbol@> =
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			wording W = Kinds::Behaviour::get_name(K, FALSE);
			if (Wordings::nonempty(W)) {
				TEMPORARY_TEXT(temp)
				WRITE_TO(temp, "kind_%N", Wordings::first_wn(W));
				if (Index::DocReferences::validate_if_possible(temp))
					Kinds::Behaviour::set_documentation_reference(K, temp);
				DISCARD_TEXT(temp)
			}
		}

@h The World page.
This section belongs to the core of Inform, so it must work whatever plugins
are present, but the World index will look pretty sketchy without (for
instance) Spatial.

=
int suppress_panel_changes = FALSE;
void Data::Objects::page_World(OUTPUT_STREAM) {
	#ifdef IF_MODULE
	if (Task::wraps_existing_storyfile()) return; /* in this case there is no model world */
	if (PluginManager::active(map_plugin) == FALSE) return; /* in this case there is no model world */

	PL::SpatialMap::establish_benchmark_room();
	PL::EPSMap::traverse_for_map_parameters(1);
	PL::SpatialMap::establish_spatial_coordinates();
	PL::HTMLMap::render_map_as_HTML(OUT);
	PL::HTMLMap::add_region_key(OUT);
	PL::EPSMap::render_map_as_EPS();

	IXBackdrops::index_object_further(OUT, NULL, 0, FALSE, 1);

	Index::anchor(OUT, I"MDETAILS");
	int unruly = FALSE;
	@<Mark parts, directions and kinds as ineligible for listing in the World index@>;
	@<Give room details within each region in turn in the World index@>;
	@<Give room details for rooms outside any region in the World index@>;
	@<Give details of everything still unmentioned in the World index@>;
	#endif
}

@<Mark parts, directions and kinds as ineligible for listing in the World index@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((IXSpatial::no_detail_index(I))
			|| (PL::Map::object_is_a_direction(I)))
			IXInstances::increment_indexing_count(I);

@<Give room details within each region in turn in the World index@> =
	instance *reg;
	LOOP_OVER_INSTANCES(reg, K_object)
		if (PL::Regions::object_is_a_region(reg)) {
			int subheaded = FALSE;
			IXInstances::increment_indexing_count(reg);
			instance *rm;
			LOOP_OVER_INSTANCES(rm, K_object)
				if ((Spatial::object_is_a_room(rm)) &&
					(PL::Regions::enclosing(rm) == reg)) {
					if (subheaded == FALSE) {
						@<Start a new details panel on the World index@>;
						@<Index the name and super-region of the region@>;
						IXBackdrops::index_object_further(OUT, reg, 0, FALSE, 2);
						HTML_OPEN("p");
						subheaded = TRUE;
					}
					PL::HTMLMap::render_single_room_as_HTML(OUT, rm);
					IXInstances::increment_indexing_count(rm);
				}
		}

@<Index the name and super-region of the region@> =
	WRITE("<b>The <i>%+W</i> region", Instances::get_name(reg, FALSE));
	instance *within = PL::Regions::enclosing(reg);
	if (within) WRITE(" within the <i>%+W</i> region", Instances::get_name(within, FALSE));
	WRITE("</b>");

@<Give room details for rooms outside any region in the World index@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Spatial::object_is_a_room(I)) &&
			(IXInstances::indexed_yet(I) == FALSE)) {
			@<Start a new details panel on the World index@>;
			PL::HTMLMap::render_single_room_as_HTML(OUT, I);
		}

@ By this point we've accounted for rooms (and their contents and any parts
thereof), directions (which we excluded), regions (ditto), and the player
object (which the Player plugin put in the right place). The only remainder
will be things which are offstage (and their contents and any parts thereof):

@<Give details of everything still unmentioned in the World index@> =
	int out_of_play_count = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((IXInstances::indexed_yet(I) == FALSE) &&
			(Spatial::progenitor(I) == NULL)) {
			@<Start a new details panel on the World index@>;
			if (++out_of_play_count == 1) {
				suppress_panel_changes = TRUE;
				WRITE("<b>Nowhere (that is, initially not in any room):</b>");
				HTML_TAG("br");
			}
			Data::Objects::index(OUT, I, NULL, 2, FALSE);
		}
	suppress_panel_changes = FALSE;

@<Start a new details panel on the World index@> =
	if ((unruly) && (suppress_panel_changes == FALSE)) HTML_TAG("hr");
	unruly = TRUE;

@h Indexing individual objects.
Rather ingeniously, the following routine is used both to index instance objects,
in the World index, and to index kinds of object, as rows in the table on the
Kinds index. The point of doing both together is to ensure a consistent layout.
If |details| is set, a whole paragraph of details follows; otherwise there is
just a line, which in |tabulating_kinds_index| mode comes out as a row in the
table of Kinds.

@d MAX_OBJECT_INDEX_DEPTH 10000

=
int tabulating_kinds_index = FALSE;
instance *indexing_room = NULL;
int xtras_count = 0;

instance *Data::Objects::room_being_indexed(void) {
	return indexing_room;
}

void Data::Objects::index(OUTPUT_STREAM, instance *I, kind *K, int depth, int details) {
	if (depth == MAX_OBJECT_INDEX_DEPTH) internal_error("MAX_OBJECT_INDEX_DEPTH exceeded");
	noun *nt = NULL;
	if (I) {
		if (depth > NUMBER_CREATED(instance) + 1) return; /* to recover from errors */
		IXInstances::increment_indexing_count(I);
		#ifdef IF_MODULE
		if (Instances::of_kind(I, K_room)) indexing_room = I;
		#endif
		nt = Instances::get_noun(I);
	}
	if (K) nt = Kinds::Behaviour::get_noun(K);
	if (nt == NULL) internal_error("no noun to index");
	int shaded = FALSE;
	@<Begin the object citation line@>;
	int xtra = -1;
	if (I) xtra = xtras_count++;
	if (xtra >= 0) Index::extra_link(OUT, xtra);
	@<Index the name part of the object citation@>;
	if (I) @<Index the kind attribution part of the object citation@>;
	@<Index the link icons part of the object citation@>;
	@<End the object citation line@>;
	if (details) @<Add a subsidiary paragraph of details about this object@>;
	if (xtra >= 0) {
		Index::extra_div_open(OUT, xtra, depth+1, "e0e0e0");
		@<Add the chain of kinds@>;
		@<Add the catalogue of specific properties@>;
		PluginCalls::add_to_World_index(OUT, I);
		IXInstances::index_usages(OUT, I);
		Index::extra_div_close(OUT, "e0e0e0");
	}
	@<Recurse the index citation for the object as necessary@>;
}

@<Begin the object citation line@> =
	if (tabulating_kinds_index) Kinds::Index::begin_chart_row(OUT);
	if (details) {
		HTML::open_indented_p(OUT, depth, "halftight");
		if ((K) || (I != indexing_room)) Index::anchor(OUT, NounIdentifiers::identifier(nt));
	} else {
		#ifdef IF_MODULE
		if (I) IXSpatial::index_spatial_relationship(OUT, I);
		#endif
	}

@<End the object citation line@> =
	if (tabulating_kinds_index)
		Kinds::Index::end_chart_row(OUT, shaded, K, "tick", "tick", "tick");
	else {
		if (details) HTML_CLOSE("p");
	}

@<Index the name part of the object citation@> =
	if (tabulating_kinds_index) {
		int c = Instances::count(K);
		if ((c == 0) && (details == FALSE)) shaded = TRUE;
		if (shaded) HTML::begin_colour(OUT, I"808080");
		@<Quote the name of the object being indexed@>;
		if (shaded) HTML::end_colour(OUT);
		if ((details == FALSE) && (c > 0)) WRITE(" [%d]", c);
	} else {
		@<Quote the name of the object being indexed@>;
	}

@<Quote the name of the object being indexed@> =
	wording W = Nouns::nominative_in_language(nt, FALSE, Projects::get_language_of_play(Task::project()));
	if ((Wordings::empty(W)) && (I)) {
		kind *IK = Instances::to_kind(I);
		W = Kinds::Behaviour::get_name_in_play(IK, FALSE, Projects::get_language_of_play(Task::project()));
	}
	if (Wordings::empty(W)) {
		WRITE("nameless");
	} else {
		int embolden = details;
		#ifdef IF_MODULE
		if (Spatial::object_is_a_room(I)) embolden = TRUE;
		#endif
		if (embolden) WRITE("<b>");
		WRITE("%+W", W);
		if (embolden) WRITE("</b>");
		if (details) @<Elaborate the name of the object being indexed@>;
	}

@<Elaborate the name of the object being indexed@> =
	if (I) {
		kind *k = Instances::to_kind(I);
		if (Kinds::Behaviour::is_subkind_of_object(k)) {
			wording W = Kinds::Behaviour::get_name_in_play(k, FALSE, Projects::get_language_of_play(Task::project()));
			if (Wordings::nonempty(W)) {
				WRITE(", a kind of %+W", W);
			}
		}
	}
	wording PW = Nouns::nominative_in_language(nt, TRUE, Projects::get_language_of_play(Task::project()));
	if (Wordings::nonempty(PW)) WRITE(" (<i>plural</i> %+W)", PW);

@<Index the kind attribution part of the object citation@> =
	if (PluginCalls::annotate_in_World_index(OUT, I) == FALSE) {
		kind *k = Instances::to_kind(I);
		if (k) {
			#ifdef IF_MODULE
			wording W = Kinds::Behaviour::get_name(k, FALSE);
			if ((Wordings::nonempty(W)) &&
				(Kinds::eq(k, K_object) == FALSE) &&
				(Kinds::eq(k, K_thing) == FALSE) &&
				(Kinds::eq(k, K_room) == FALSE)) {
				WRITE(" - <i>%+W</i>", W);
			}
			#endif
		}
	}

@<Index the link icons part of the object citation@> =
	parse_node *C = NULL;
	if (K) C = Kinds::Behaviour::get_creating_sentence(K);
	if (I) C = Instances::get_creating_sentence(I);
	if (C) Index::link(OUT, Wordings::first_wn(Node::get_text(C)));
	if ((K) && (Kinds::Behaviour::get_documentation_reference(K)))
		Index::DocReferences::link(OUT, Kinds::Behaviour::get_documentation_reference(K));
	if ((details == FALSE) && (K))
		Index::below_link(OUT, NounIdentifiers::identifier(nt));

@ This either recurses down through subkinds or through the spatial hierarchy.

@<Recurse the index citation for the object as necessary@> =
	if (K) {
		kind *K2;
		LOOP_OVER_BASE_KINDS(K2)
			if (Kinds::eq(Latticework::super(K2), K))
				Data::Objects::index(OUT, NULL, K2, depth+1, details);
	} else {
		#ifdef IF_MODULE
		IXSpatial::index_object_further(OUT, I, depth, details);
		#endif
	}

@<Add a subsidiary paragraph of details about this object@> =
	HTML::open_indented_p(OUT, depth, "tight");
	if (I) IXInferences::index(OUT, Instances::as_subject(I), TRUE);
	else IXInferences::index(OUT, KindSubjects::from_kind(K), TRUE);
	if (K) {
		HTML_CLOSE("p");
		Data::Objects::index_instances(OUT, K, depth);
	}

@<Add the chain of kinds@> =
	HTML::open_indented_p(OUT, 1, "tight");
	kind *IK = Instances::to_kind(I);
	int i = 0;
	while ((IK != K_object) && (IK)) {
		i++;
		IK = Latticework::super(IK);
	}
	int j;
	for (j=i-1; j>=0; j--) {
		int k; IK = Instances::to_kind(I);
		for (k=0; k<j; k++) IK = Latticework::super(IK);
		if (j != i-1) WRITE(" &gt; ");
		wording W = Kinds::Behaviour::get_name(IK, FALSE);
		WRITE("%+W", W);
	}
	parse_node *P = Instances::get_kind_set_sentence(I);
	if (P) Index::link(OUT, Wordings::first_wn(Node::get_text(P)));
	WRITE(" &gt; <b>");
	IXInstances::index_name(OUT, I);
	WRITE("</b>");
	HTML_CLOSE("p");

@<Add the catalogue of specific properties@> =
	IXInferences::index_specific(OUT, Instances::as_subject(I));

@ =
void Data::Objects::index_instances(OUTPUT_STREAM, kind *K, int depth) {
	HTML::open_indented_p(OUT, depth, "tight");
	int c = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K) c++;
	if (c >= 10) {
		int xtra = xtras_count++;
		Index::extra_link(OUT, xtra);
		HTML::begin_colour(OUT, I"808080");
		WRITE("%d ", c);
		wording PW = Kinds::Behaviour::get_name(K, TRUE);
		if (Wordings::nonempty(PW)) WRITE("%+W", PW);
		else WRITE("instances");
		HTML::end_colour(OUT);
		HTML_CLOSE("p");
		Index::extra_div_open(OUT, xtra, depth+1, "e0e0e0");
		c = 0;
		LOOP_OVER_INSTANCES(I, K) {
			if (c > 0) WRITE(", "); c++;
			HTML::begin_colour(OUT, I"808080");
			IXInstances::index_name(OUT, I);
			HTML::end_colour(OUT);
			parse_node *at = Instances::get_creating_sentence(I);
			if (at) Index::link(OUT, Wordings::first_wn(Node::get_text(at)));
		}
		Index::extra_div_close(OUT, "e0e0e0");
	} else {
		c = 0;
		LOOP_OVER_INSTANCES(I, K) {
			if (c > 0) WRITE(", "); c++;
			HTML::begin_colour(OUT, I"808080");
			IXInstances::index_name(OUT, I);
			HTML::end_colour(OUT);
			parse_node *at = Instances::get_creating_sentence(I);
			if (at) Index::link(OUT, Wordings::first_wn(Node::get_text(at)));
		}
		HTML_CLOSE("p");
	}
}
