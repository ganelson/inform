[IXPhysicalWorld::] Map Element.

This section masterminds the creation of the World and Kinds index
pages, though it delegates much of the work elsewhere. Though it does belong
to core Inform, these indexes will look pretty sparse if the spatial Plugins
aren't plugged in.

@h The World page.

=
int suppress_panel_changes = FALSE;
void IXPhysicalWorld::render(OUTPUT_STREAM, int test_only) {
	PL::SpatialMap::initialise_page_directions();
	IXInstances::make_faux();
	PL::SpatialMap::establish_spatial_coordinates();
	if (test_only) {
		PL::SpatialMap::perform_map_internal_test(OUT);
	} else {
		PL::HTMLMap::render_map_as_HTML(OUT);
		PL::HTMLMap::add_region_key(OUT);
		IXBackdrops::index_object_further(OUT, NULL, 0, FALSE, 1);

		Index::anchor(OUT, I"MDETAILS");
		int unruly = FALSE;
		@<Mark parts, directions and kinds as ineligible for listing in the World index@>;
		@<Give room details within each region in turn in the World index@>;
		@<Give room details for rooms outside any region in the World index@>;
		@<Give details of everything still unmentioned in the World index@>;
	}
}

@<Mark parts, directions and kinds as ineligible for listing in the World index@> =
	faux_instance *I;
	LOOP_OVER_OBJECTS(I)
		if ((IXSpatial::no_detail_index(I))
			|| (IXInstances::is_a_direction(I)))
			IXInstances::increment_indexing_count(I);

@<Give room details within each region in turn in the World index@> =
	faux_instance *reg;
	LOOP_OVER_OBJECTS(reg)
		if (IXInstances::is_a_region(reg)) {
			int subheaded = FALSE;
			IXInstances::increment_indexing_count(reg);
			faux_instance *rm;
			LOOP_OVER_ROOMS(rm)
				if (IXInstances::region_of(rm) == reg) {
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
	WRITE("<b>The <i>%S</i> region", IXInstances::get_name(reg));
	faux_instance *within = IXInstances::region_of(reg);
	if (within) WRITE(" within the <i>%S</i> region", IXInstances::get_name(within));
	WRITE("</b>");

@<Give room details for rooms outside any region in the World index@> =
	faux_instance *I;
	LOOP_OVER_ROOMS(I)
		if (IXInstances::indexed_yet(I) == FALSE) {
			@<Start a new details panel on the World index@>;
			PL::HTMLMap::render_single_room_as_HTML(OUT, I);
		}

@ By this point we've accounted for rooms (and their contents and any parts
thereof), directions (which we excluded), regions (ditto), and the player
object (which the Player plugin put in the right place). The only remainder
will be things which are offstage (and their contents and any parts thereof):

@<Give details of everything still unmentioned in the World index@> =
	int out_of_play_count = 0;
	faux_instance *I;
	LOOP_OVER_OBJECTS(I)
		if ((IXInstances::indexed_yet(I) == FALSE) &&
			(IXInstances::progenitor(I) == NULL)) {
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
faux_instance *indexing_room = NULL;
int xtras_count = 0;

faux_instance *IXPhysicalWorld::room_being_indexed(void) {
	return indexing_room;
}

void IXPhysicalWorld::set_room_being_indexed(faux_instance *I) {
	indexing_room = I;
}

void IXPhysicalWorld::index(OUTPUT_STREAM, faux_instance *I, int depth, int details) {
	if (depth == MAX_OBJECT_INDEX_DEPTH) internal_error("MAX_OBJECT_INDEX_DEPTH exceeded");
	if (I) {
		if (depth > NUMBER_CREATED(faux_instance) + 1) return; /* to recover from errors */
		IXInstances::increment_indexing_count(I);
		if (IXInstances::is_a_room(I)) indexing_room = I;
	}
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
		@<Add details depending on the kind@>;
		IXPhysicalWorld::index_usages(OUT, I);
		Index::extra_div_close(OUT, "e0e0e0");
	}
	@<Recurse the index citation for the object as necessary@>;
}

@<Begin the object citation line@> =
	if (details) {
		HTML::open_indented_p(OUT, depth, "halftight");
		if (I != indexing_room) Index::anchor(OUT, I->anchor_text);
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
	TEMPORARY_TEXT(name)
	IXInstances::write_name(name, I);
	if ((Str::len(name) == 0) && (I)) IXInstances::write_kind(name, I);
	if (Str::len(name) == 0) {
		WRITE("nameless");
	} else {
		int embolden = details;
		if (IXInstances::is_a_room(I)) embolden = TRUE;
		if (embolden) WRITE("<b>");
		WRITE("%S", name);
		if (embolden) WRITE("</b>");
		if (details) @<Elaborate the name of the object being indexed@>;
	}

@<Elaborate the name of the object being indexed@> =
	if (I) {
		WRITE(", a kind of ");
		IXInstances::write_kind(OUT, I);
	}

@<Index the kind attribution part of the object citation@> =
	if ((IXMap::annotate_in_World_index(OUT, I) == FALSE) &&
		(IXPlayer::annotate_in_World_index(OUT, I) == FALSE)) {
		if (I->specify_kind) {
			WRITE(" - <i>");
			IXInstances::write_kind(OUT, I);
			WRITE("</i>");
		}
	}

@<Index the link icons part of the object citation@> =
	if (I->created_at > 0) Index::link(OUT, I->created_at);

@ This either recurses down through subkinds or through the spatial hierarchy.

@<Recurse the index citation for the object as necessary@> =
	#ifdef IF_MODULE
	IXSpatial::index_object_further(OUT, I, depth, details);
	#endif

@<Add a subsidiary paragraph of details about this object@> =
	HTML::open_indented_p(OUT, depth, "tight");
	text_stream *material = Metadata::read_optional_textual(I->package, I"^brief_inferences");
	WRITE("%S", material);

@<Add the chain of kinds@> =
	HTML::open_indented_p(OUT, 1, "tight");
	IXInstances::write_kind_chain(OUT, I);
	if (I->kind_set_at > 0) Index::link(OUT, I->kind_set_at);
	WRITE(" &gt; <b>");
	IXInstances::write_name(OUT, I);
	WRITE("</b>");
	HTML_CLOSE("p");

@<Add the catalogue of specific properties@> =
	text_stream *material = Metadata::read_optional_textual(I->package, I"^specific_inferences");
	WRITE("%S", material);

@<Add details depending on the kind@> =
	IXMap::add_to_World_index(OUT, I);
	IXRegions::add_to_World_index(OUT, I);
	IXSpatial::add_to_World_index(OUT, I);

@

=
void IXPhysicalWorld::index_usages(OUTPUT_STREAM, faux_instance *I) {
	int k = 0;
	inter_package *pack = I->package;
	inter_tree_node *P = Metadata::read_optional_list(pack, I"^backdrop_presences");
	if (P) {
		int offset = DATA_CONST_IFLD;
		while (offset < P->W.extent) {
			inter_ti v1 = P->W.data[offset], v2 = P->W.data[offset+1];
			if (v1 == LITERAL_IVAL) {
				k++;
				if (k == 1) {
					HTML::open_indented_p(OUT, 1, "tight");
					WRITE("<i>mentioned in rules:</i> ");
				} else WRITE("; ");
				Index::link(OUT, (int) v2);				
			} else internal_error("malformed usage metadata");
			offset += 2;
		}
	}
	if (k > 0) HTML_CLOSE("p");
}
