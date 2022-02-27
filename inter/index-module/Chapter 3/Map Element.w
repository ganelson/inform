[MapElement::] Map Element.

To write the Map element (Mp) in the index.

@ This is by far the most complicated element to render, and much of the work
is delegated to //Spatial Mapping//. This section contains only the code which
cues all of that up; but even that code is fairly long.

=
void MapElement::render(OUTPUT_STREAM, index_session *session, int test_only) {
	int suppress_panel_changes = FALSE;
	localisation_dictionary *LD = Indexing::get_localisation(session);
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	SpatialMap::establish_spatial_coordinates(session);
	if (test_only) {
		SpatialMap::perform_map_internal_test(OUT, session);
	} else {
		HTMLMap::render_map_as_HTML(OUT, session);
		HTMLMap::add_region_key(OUT, session);
		MapElement::index_backdrop_further(OUT, NULL, 0, FALSE, 1, session);

		IndexUtilities::anchor(OUT, I"MDETAILS");
		int unruly = FALSE;
		@<Mark parts, directions and kinds as ineligible for listing in the World index@>;
		@<Give room details within each region in turn in the World index@>;
		@<Give room details for rooms outside any region in the World index@>;
		@<Give details of everything still unmentioned in the World index@>;
	}
}

@<Mark parts, directions and kinds as ineligible for listing in the World index@> =
	faux_instance *I;
	LOOP_OVER_FAUX_INSTANCES(faux_set, I)
		if ((MapElement::no_detail_index(I)) || (FauxInstances::is_a_direction(I)))
			FauxInstances::increment_indexing_count(I);

@<Give room details within each region in turn in the World index@> =
	faux_instance *reg;
	LOOP_OVER_FAUX_INSTANCES(faux_set, reg)
		if (FauxInstances::is_a_region(reg)) {
			int subheaded = FALSE;
			FauxInstances::increment_indexing_count(reg);
			faux_instance *rm;
			LOOP_OVER_FAUX_ROOMS(faux_set, rm)
				if (FauxInstances::region_of(rm) == reg) {
					if (subheaded == FALSE) {
						@<Start a new details panel on the World index@>;
						@<Index the name and super-region of the region@>;
						MapElement::index_backdrop_further(OUT, reg, 0, FALSE, 2, session);
						HTML_OPEN("p");
						subheaded = TRUE;
					}
					HTMLMap::render_single_room_as_HTML(OUT, rm, session);
					FauxInstances::increment_indexing_count(rm);
				}
		}

@<Index the name and super-region of the region@> =
	faux_instance *within = FauxInstances::region_of(reg);
	if (within)
		Localisation::bold_tt(OUT, LD, I"Index.Elements.Mp.RegionInRegion",
			FauxInstances::get_name(reg), FauxInstances::get_name(within));
	else
		Localisation::bold_t(OUT, LD, I"Index.Elements.Mp.Region",
			FauxInstances::get_name(reg));

@<Give room details for rooms outside any region in the World index@> =
	faux_instance *I;
	LOOP_OVER_FAUX_ROOMS(faux_set, I)
		if (FauxInstances::indexed_yet(I) == FALSE) {
			@<Start a new details panel on the World index@>;
			HTMLMap::render_single_room_as_HTML(OUT, I, session);
		}

@ By this point we've accounted for rooms (and their contents and any parts
thereof), directions (which we excluded), regions (ditto), and the player
object (which the Player plugin put in the right place). The only remainder
will be things which are offstage (and their contents and any parts thereof):

@<Give details of everything still unmentioned in the World index@> =
	int out_of_play_count = 0;
	faux_instance *I;
	LOOP_OVER_FAUX_INSTANCES(faux_set, I)
		if ((FauxInstances::indexed_yet(I) == FALSE) &&
			(FauxInstances::progenitor(I) == NULL)) {
			@<Start a new details panel on the World index@>;
			if (++out_of_play_count == 1) {
				suppress_panel_changes = TRUE;
				Localisation::bold(OUT, LD, I"Index.Elements.Mp.NowhereHeading");
				HTML_TAG("br");
			}
			MapElement::index(OUT, I, 2, FALSE, session);
		}
	suppress_panel_changes = FALSE;

@<Start a new details panel on the World index@> =
	if ((unruly) && (suppress_panel_changes == FALSE)) HTML_TAG("hr");
	unruly = TRUE;

@h Indexing individual objects.

@default MAX_OBJECT_INDEX_DEPTH 10000

=
void MapElement::index(OUTPUT_STREAM, faux_instance *I, int depth, int details,
	index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	if (depth == MAX_OBJECT_INDEX_DEPTH) internal_error("MAX_OBJECT_INDEX_DEPTH exceeded");
	if (I) {
		if (depth > NUMBER_CREATED(faux_instance) + 1) return; /* to recover from errors */
		FauxInstances::increment_indexing_count(I);
		if (FauxInstances::is_a_room(I)) IndexUtilities::set_room_being_indexed(I, session);
	}
	@<Begin the object citation line@>;
	int xtra = -1;
	if (I) xtra = IndexUtilities::extra_ID(session);
	if (xtra >= 0) IndexUtilities::extra_link(OUT, xtra);
	@<Index the name part of the object citation@>;
	if (I) @<Index the kind attribution part of the object citation@>;
	@<Index the link icons part of the object citation@>;
	@<End the object citation line@>;
	if (details) @<Add a subsidiary paragraph of details about this object@>;
	if (xtra >= 0) {
		IndexUtilities::extra_div_open(OUT, xtra, depth+1, "e0e0e0");
		@<Add the chain of kinds@>;
		@<Add the catalogue of specific properties@>;
		@<Add details depending on the kind@>;
		MapElement::index_usages(OUT, I, session);
		IndexUtilities::extra_div_close(OUT, "e0e0e0");
	}
	@<Recurse the index citation for the object as necessary@>;
}

@<Begin the object citation line@> =
	if (details) {
		HTML::open_indented_p(OUT, depth, "halftight");
		if (I != IndexUtilities::room_being_indexed(session))
			IndexUtilities::anchor(OUT, I->anchor_text);
	} else {
		#ifdef IF_MODULE
		if (I) MapElement::index_spatial_relationship(OUT, I, session);
		#endif
	}

@<End the object citation line@> =
	if (details) HTML_CLOSE("p");

@<Index the name part of the object citation@> =
	@<Quote the name of the object being indexed@>;

@<Quote the name of the object being indexed@> =
	TEMPORARY_TEXT(name)
	FauxInstances::write_name(name, I);
	if ((Str::len(name) == 0) && (I)) FauxInstances::write_kind(name, I);
	if (Str::len(name) == 0) {
		WRITE("nameless");
	} else {
		int embolden = details;
		if (FauxInstances::is_a_room(I)) embolden = TRUE;
		if (embolden) WRITE("<b>");
		WRITE("%S", name);
		if (embolden) WRITE("</b>");
		if (details) @<Elaborate the name of the object being indexed@>;
	}

@<Elaborate the name of the object being indexed@> =
	if (I) {
		WRITE(", ");
		TEMPORARY_TEXT(whatever)
		FauxInstances::write_kind(whatever, I);
		Localisation::roman_t(OUT, LD, I"Index.Elements.Mp.KindOf", whatever);
		DISCARD_TEXT(whatever)
	}

@<Index the kind attribution part of the object citation@> =
	if ((MapElement::annotate_door(OUT, I, session) == FALSE) &&
		(MapElement::annotate_player(OUT, I, session) == FALSE)) {
		if (FauxInstances::specify_kind(I)) {
			WRITE(" - <i>");
			FauxInstances::write_kind(OUT, I);
			WRITE("</i>");
		}
	}

@<Index the link icons part of the object citation@> =
	if (FauxInstances::created_at(I) > 0)
		IndexUtilities::link(OUT, FauxInstances::created_at(I));

@ This either recurses down through subkinds or through the spatial hierarchy.

@<Recurse the index citation for the object as necessary@> =
	#ifdef IF_MODULE
	MapElement::index_object_further(OUT, I, depth, details, session);
	#endif

@<Add a subsidiary paragraph of details about this object@> =
	HTML::open_indented_p(OUT, depth, "tight");
	text_stream *material =
		Metadata::read_optional_textual(I->package, I"^brief_inferences");
	WRITE("%S", material);

@<Add the chain of kinds@> =
	HTML::open_indented_p(OUT, 1, "tight");
	FauxInstances::write_kind_chain(OUT, I);
	if (FauxInstances::kind_set_at(I) > 0)
		IndexUtilities::link(OUT, FauxInstances::kind_set_at(I));
	WRITE(" &gt; <b>");
	FauxInstances::write_name(OUT, I);
	WRITE("</b>");
	HTML_CLOSE("p");

@<Add the catalogue of specific properties@> =
	text_stream *material =
		Metadata::read_optional_textual(I->package, I"^specific_inferences");
	WRITE("%S", material);

@<Add details depending on the kind@> =
	MapElement::add_room_to_World_index(OUT, I, session);
	MapElement::add_region_to_World_index(OUT, I);
	MapElement::add_to_World_index(OUT, I, session);

@

=
void MapElement::index_usages(OUTPUT_STREAM, faux_instance *I, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	int k = 0;
	inter_package *pack = I->package;
	inter_tree_node *P = Metadata::read_optional_list(pack, I"^backdrop_presences");
	if (P) {
		int offset = DATA_CONST_IFLD;
		while (offset < P->W.extent) {
			inter_pair val = InterValuePairs::get(P, offset);
			if (InterValuePairs::is_number(val)) {
				k++;
				if (k == 1) {
					HTML::open_indented_p(OUT, 1, "tight");
					Localisation::italic(OUT, LD, I"Index.Elements.Mp.MentionedIn");					
					WRITE(": ");
				} else WRITE("; ");
				IndexUtilities::link(OUT, (int) InterValuePairs::to_number(val));				
			} else internal_error("malformed usage metadata");
			offset += 2;
		}
	}
	if (k > 0) HTML_CLOSE("p");
}

int MapElement::add_room_to_World_index(OUTPUT_STREAM, faux_instance *O,
	index_session *session) {
	if ((O) && (FauxInstances::is_a_room(O))) {
		SpatialMap::index_room_connections(OUT, O, session);
	}
	return FALSE;
}

int MapElement::add_region_to_World_index(OUTPUT_STREAM, faux_instance *O) {
	if ((O) && (FauxInstances::is_a_room(O))) {
		faux_instance *R = FauxInstances::region_of(O);
		if (R) HTMLMap::colour_chip(OUT, O, R, FauxInstances::region_set_at(O));
	}
	return FALSE;
}

int MapElement::annotate_player(OUTPUT_STREAM, faux_instance *I,
	index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	if (I == FauxInstances::start_room(session)) {
		WRITE(" - ");
		Localisation::italic(OUT, LD, I"Index.Elements.Mp.RoomWherePlayBegins");		
		DocReferences::link(OUT, I"ROOMPLAYBEGINS");
		return TRUE;
	}
	return FALSE;
}

int MapElement::annotate_door(OUTPUT_STREAM, faux_instance *O,
	index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	if ((O) && (FauxInstances::is_a_door(O))) {
		faux_instance *A = NULL, *B = NULL;
		FauxInstances::get_door_data(O, &A, &B);
		TEMPORARY_TEXT(to)
		faux_instance *X = A;
		if (A == IndexUtilities::room_being_indexed(session)) X = B;
		if (X == NULL) X = FauxInstances::other_side_of_door(O);
		if (X == NULL) WRITE_TO(to, "nowhere");
		else FauxInstances::write_name(to, X);
		WRITE(" - ");
		if ((A) && (B)) Localisation::italic_t(OUT, LD, I"Index.Elements.Mp.DoorTo", to);
		else Localisation::italic_t(OUT, LD, I"Index.Elements.Mp.OneSidedDoorTo", to);
		DISCARD_TEXT(to)
		return TRUE;
	}
	return FALSE;
}

@ =
void MapElement::index_spatial_relationship(OUTPUT_STREAM, faux_instance *I,
	index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	text_stream *rel = NULL;
	faux_instance *P = FauxInstances::progenitor(I);
	if (P) {
		/* we omit "in" for brevity: that's understood to be the default */
		if (FauxInstances::is_a_supporter(P)) rel = I"Index.Elements.Mp.BriefOn";
		if (FauxInstances::is_a_person(P)) rel = I"Index.Elements.Mp.BriefCarried";
		if (FauxInstances::is_a_part(I)) rel = I"Index.Elements.Mp.BriefPart";
		if (FauxInstances::is_worn(I)) rel = I"Index.Elements.Mp.BriefWorn";
	}
	if (rel) {
		Localisation::italic(OUT, LD, rel);
		WRITE(" ");
	}
}

@ If something is a part, we don't detail it on the World index page, since
it already turns up under its owner.

=
int MapElement::no_detail_index(faux_instance *I) {
	if (FauxInstances::is_a_part(I)) return TRUE;
	return FALSE;
}

@ In the World index, we recurse to show the contents and parts:

=
void MapElement::index_object_further(OUTPUT_STREAM, faux_instance *I, int depth,
	int details, index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	if (depth > NUMBER_CREATED(faux_instance) + 1) return; /* to recover from errors */
	if (FauxInstances::incorp_child(I)) {
		faux_instance *I2 = FauxInstances::incorp_child(I);
		while (I2) {
			MapElement::index(OUT, I2, depth+1, details, session);
			I2 = FauxInstances::incorp_sibling(I2);
		}
	}
	if (FauxInstances::child(I))
		MapElement::index(OUT, FauxInstances::child(I), depth+1, details, session);
	if ((FauxInstances::is_a_room(I)) &&
		(FauxInstances::is_a_door(I) == FALSE)) {
		faux_instance *I2;
		LOOP_OVER_FAUX_INSTANCES(faux_set, I2) {
			if ((FauxInstances::is_a_door(I2)) && (FauxInstances::progenitor(I2) != I)) {
				faux_instance *A = NULL, *B = NULL;
				FauxInstances::get_door_data(I2, &A, &B);
				if (A == I) MapElement::index(OUT, I2, depth+1, details, session);
				if (B == I) MapElement::index(OUT, I2, depth+1, details, session);
			}
		}
	}
	MapElement::index_player_further(OUT, I, depth, details, session);
	MapElement::index_backdrop_further(OUT, I, depth, details, 0, session);

	if (FauxInstances::sibling(I))
		MapElement::index(OUT, FauxInstances::sibling(I), depth, details, session);
}

@ And also:

=
int MapElement::add_to_World_index(OUTPUT_STREAM, faux_instance *O,
	index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	if ((O) && (FauxInstances::is_a_thing(O))) {
		HTML::open_indented_p(OUT, 1, "tight");
		faux_instance *P = FauxInstances::progenitor(O);
		if (P) {
			Localisation::italic(OUT, LD, I"Index.Elements.Mp.InitialLocation");
			WRITE(": ");
			text_stream *rel = I"Index.Elements.Mp.In";
			if (FauxInstances::is_a_supporter(P)) rel = I"Index.Elements.Mp.On";
			if (FauxInstances::is_a_person(P)) rel = I"Index.Elements.Mp.Carried";
			if (FauxInstances::is_a_part(O)) rel = I"Index.Elements.Mp.Part";
			if (FauxInstances::is_worn(O)) rel = I"Index.Elements.Mp.Worn";
			TEMPORARY_TEXT(to)
			FauxInstances::write_name(to, P);
			Localisation::roman_t(OUT, LD, rel, to);
			WRITE(" ");
			DISCARD_TEXT(to)
			int at = FauxInstances::progenitor_set_at(O);
			if (at) IndexUtilities::link(OUT, at);

		}
		HTML_CLOSE("p");
	}
	return FALSE;
}

void MapElement::index_player_further(OUTPUT_STREAM, faux_instance *I, int depth,
	int details, index_session *session) {
	faux_instance *yourself = FauxInstances::yourself(session);
	if ((I == FauxInstances::start_room(session)) && (yourself) &&
		(FauxInstances::indexed_yet(yourself) == FALSE))
		MapElement::index(OUT, yourself, depth+1, details, session);
}

void MapElement::index_backdrop_further(OUTPUT_STREAM, faux_instance *loc, int depth,
	int details, int how, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	int discoveries = 0;
	faux_instance *bd;
	if (loc) {
		LOOP_OVER_LINKED_LIST(bd, faux_instance, loc->backdrop_presences) {
			if (++discoveries == 1) @<Insert fore-matter@>;
			MapElement::index(OUT, bd, depth+1, details, session);
		}
	} else {
		LOOP_OVER_FAUX_BACKDROPS(faux_set, bd)
			if (FauxInstances::is_everywhere(bd)) {
				if (++discoveries == 1) @<Insert fore-matter@>;
				MapElement::index(OUT, bd, depth+1, details, session);
			}
	}
	if (discoveries > 0) @<Insert after-matter@>;
}

@<Insert fore-matter@> =
	switch (how) {
		case 1: HTML_OPEN("p");
				Localisation::bold(OUT, LD, I"Index.Elements.Mp.EverywhereHeading");
				HTML_TAG("br"); break;
		case 2: HTML_TAG("br"); break;
	}

@<Insert after-matter@> =
	switch (how) {
		case 1: HTML_CLOSE("p"); HTML_TAG("hr"); HTML_OPEN("p"); break;
		case 2: break;
	}
