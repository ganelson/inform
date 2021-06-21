[IXPhysicalWorld::] Map Element.

This section masterminds the creation of the World and Kinds index
pages, though it delegates much of the work elsewhere. Though it does belong
to core Inform, these indexes will look pretty sparse if the spatial Plugins
aren't plugged in.

@h The World page.
This section belongs to the core of Inform, so it must work whatever plugins
are present, but the World index will look pretty sketchy without (for
instance) Spatial.

=
int suppress_panel_changes = FALSE;
void IXPhysicalWorld::render(OUTPUT_STREAM) {
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
}

@<Mark parts, directions and kinds as ineligible for listing in the World index@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((IXSpatial::no_detail_index(I))
			|| (Map::instance_is_a_direction(I)))
			IXInstances::increment_indexing_count(I);

@<Give room details within each region in turn in the World index@> =
	instance *reg;
	LOOP_OVER_INSTANCES(reg, K_object)
		if (Regions::object_is_a_region(reg)) {
			int subheaded = FALSE;
			IXInstances::increment_indexing_count(reg);
			instance *rm;
			LOOP_OVER_INSTANCES(rm, K_object)
				if ((Spatial::object_is_a_room(rm)) &&
					(Regions::enclosing(rm) == reg)) {
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
	instance *within = Regions::enclosing(reg);
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
			IXPhysicalWorld::index(OUT, I, 2, FALSE);
		}
	suppress_panel_changes = FALSE;

@<Start a new details panel on the World index@> =
	if ((unruly) && (suppress_panel_changes == FALSE)) HTML_TAG("hr");
	unruly = TRUE;

@h Indexing individual objects.

@default MAX_OBJECT_INDEX_DEPTH 10000

=
instance *indexing_room = NULL;
int xtras_count = 0;

instance *IXPhysicalWorld::room_being_indexed(void) {
	return indexing_room;
}

void IXPhysicalWorld::set_room_being_indexed(instance *I) {
	indexing_room = I;
}

void IXPhysicalWorld::index(OUTPUT_STREAM, instance *I, int depth, int details) {
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
	if (nt == NULL) internal_error("no noun to index");
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
		IXPhysicalWorld::index_usages(OUT, I);
		Index::extra_div_close(OUT, "e0e0e0");
	}
	@<Recurse the index citation for the object as necessary@>;
}

@<Begin the object citation line@> =
	if (details) {
		HTML::open_indented_p(OUT, depth, "halftight");
		if (I != indexing_room) Index::anchor(OUT, NounIdentifiers::identifier(nt));
	} else {
		#ifdef IF_MODULE
		if (I) IXSpatial::index_spatial_relationship(OUT, I);
		#endif
	}

@<End the object citation line@> =
	if (details) HTML_CLOSE("p");

@<Index the name part of the object citation@> =
	@<Quote the name of the object being indexed@>;

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
	parse_node *C = Instances::get_creating_sentence(I);
	if (C) Index::link(OUT, Wordings::first_wn(Node::get_text(C)));

@ This either recurses down through subkinds or through the spatial hierarchy.

@<Recurse the index citation for the object as necessary@> =
	#ifdef IF_MODULE
	IXSpatial::index_object_further(OUT, I, depth, details);
	#endif

@<Add a subsidiary paragraph of details about this object@> =
	HTML::open_indented_p(OUT, depth, "tight");
	IXInferences::index(OUT, Instances::as_subject(I), TRUE);

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
	PL::SpatialMap::write_name(OUT, I);
	WRITE("</b>");
	HTML_CLOSE("p");

@<Add the catalogue of specific properties@> =
	IXInferences::index_specific(OUT, Instances::as_subject(I));

@

=
void IXPhysicalWorld::index_usages(OUTPUT_STREAM, instance *I) {
	int k = 0;
	parse_node *at;
	LOOP_OVER_LINKED_LIST(at, parse_node, I->compilation_data.usages) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(Node::get_text(at)));
		if (Projects::draws_from_source_file(Task::project(), sf)) {
			k++;
			if (k == 1) {
				HTML::open_indented_p(OUT, 1, "tight");
				WRITE("<i>mentioned in rules:</i> ");
			} else WRITE("; ");
			Index::link(OUT, Wordings::first_wn(Node::get_text(at)));
		}
	}
	if (k > 0) HTML_CLOSE("p");
}
