[IXSpatial::] Spatial.

Indexing functions for the spatial structure of the world model.

@ =
void IXSpatial::index_spatial_relationship(OUTPUT_STREAM, instance *I) {
	char *rel = NULL;
	instance *P = Spatial::progenitor(I);
	if (P) {
		/* we could set |rel| to "in" here, but the index omits that for clarity */
		if (Instances::of_kind(P, K_supporter)) rel = "on";
		if (Instances::of_kind(P, K_person)) rel = "carried";
		if (SPATIAL_DATA(I)->part_flag) rel = "part";
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), property_inf)
			if (PropertyInferences::get_property(inf) == P_worn)
				rel = "worn";
	}
	if (rel) WRITE("<i>%s</i> ", rel);
}

@ If something is a part, we don't detail it on the World index page, since
it already turns up under its owner.

=
int IXSpatial::no_detail_index(instance *I) {
	if (SPATIAL_DATA(I)->incorp_tree_parent != NULL) return TRUE;
	return FALSE;
}

@ In the World index, we recurse to show the contents and parts:

=
void IXSpatial::index_object_further(OUTPUT_STREAM, instance *I, int depth, int details) {
	if (depth > NUMBER_CREATED(instance) + 1) return; /* to recover from errors */
	if (SPATIAL_DATA(I)->incorp_tree_child != NULL) {
		instance *I2 = SPATIAL_DATA(I)->incorp_tree_child;
		while (I2 != NULL) {
			IXPhysicalWorld::index(OUT, I2, depth+1, details);
			I2 = SPATIAL_DATA(I2)->incorp_tree_sibling;
		}
	}
	if (SPATIAL_DATA(I)->object_tree_child)
		IXPhysicalWorld::index(OUT, SPATIAL_DATA(I)->object_tree_child, depth+1, details);
	if ((Spatial::object_is_a_room(I)) &&
		(Map::instance_is_a_door(I) == FALSE)) {
		instance *I2;
		LOOP_OVER_INSTANCES(I2, K_object) {
			if ((Map::instance_is_a_door(I2)) && (Spatial::progenitor(I2) != I)) {
				instance *A = NULL, *B = NULL;
				Map::get_door_data(I2, &A, &B);
				if (A == I) IXPhysicalWorld::index(OUT, I2, depth+1, details);
				if (B == I) IXPhysicalWorld::index(OUT, I2, depth+1, details);
			}
		}
	}
	IXPlayer::index_object_further(OUT, I, depth, details);
	IXBackdrops::index_object_further(OUT, I, depth, details, 0);

	if (SPATIAL_DATA(I)->object_tree_sibling)
		IXPhysicalWorld::index(OUT, SPATIAL_DATA(I)->object_tree_sibling, depth, details);
}

@ And also:

=
int IXSpatial::add_to_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_thing))) {
		HTML::open_indented_p(OUT, 1, "tight");
		instance *P = Spatial::progenitor(O);
		if (P) {
			WRITE("<i>initial location:</i> ");
			char *rel = "in";
			if (Instances::of_kind(P, K_supporter)) rel = "on";
			if (Instances::of_kind(P, K_person)) rel = "carried by";
			if (SPATIAL_DATA(O)->part_flag) rel = "part of";
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(O), property_inf)
				if (PropertyInferences::get_property(inf) == P_worn)
					rel = "worn by";
			WRITE("%s ", rel);
			PL::SpatialMap::write_name(OUT, P);
			parse_node *at = SPATIAL_DATA(O)->progenitor_set_at;
			if (at) Index::link(OUT, Wordings::first_wn(Node::get_text(at)));

		}
		HTML_CLOSE("p");
	}
	return FALSE;
}
