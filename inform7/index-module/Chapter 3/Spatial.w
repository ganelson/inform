[IXSpatial::] Spatial.

Indexing functions for the spatial structure of the world model.

@ =
void IXSpatial::index_spatial_relationship(OUTPUT_STREAM, faux_instance *I) {
	char *rel = NULL;
	faux_instance *P = IXInstances::progenitor(I);
	if (P) {
		/* we could set |rel| to "in" here, but the index omits that for clarity */
		if (IXInstances::is_a_supporter(P)) rel = "on";
		if (IXInstances::is_a_person(P)) rel = "carried";
		if (I->is_a_part) rel = "part";
		if (I->is_worn) rel = "worn";
	}
	if (rel) WRITE("<i>%s</i> ", rel);
}

@ If something is a part, we don't detail it on the World index page, since
it already turns up under its owner.

=
int IXSpatial::no_detail_index(faux_instance *I) {
	if (I->is_a_part) return TRUE;
	return FALSE;
}

@ In the World index, we recurse to show the contents and parts:

=
void IXSpatial::index_object_further(OUTPUT_STREAM, faux_instance *I, int depth, int details) {
	if (depth > NUMBER_CREATED(faux_instance) + 1) return; /* to recover from errors */
	if (IXInstances::incorp_child(I)) {
		faux_instance *I2 = IXInstances::incorp_child(I);
		while (I2) {
			IXPhysicalWorld::index(OUT, I2, depth+1, details);
			I2 = IXInstances::incorp_sibling(I2);
		}
	}
	if (IXInstances::child(I))
		IXPhysicalWorld::index(OUT, IXInstances::child(I), depth+1, details);
	if ((IXInstances::is_a_room(I)) &&
		(IXInstances::is_a_door(I) == FALSE)) {
		faux_instance *I2;
		LOOP_OVER_OBJECTS(I2) {
			if ((IXInstances::is_a_door(I2)) && (IXInstances::progenitor(I2) != I)) {
				faux_instance *A = NULL, *B = NULL;
				IXInstances::get_door_data(I2, &A, &B);
				if (A == I) IXPhysicalWorld::index(OUT, I2, depth+1, details);
				if (B == I) IXPhysicalWorld::index(OUT, I2, depth+1, details);
			}
		}
	}
	IXPlayer::index_object_further(OUT, I, depth, details);
	IXBackdrops::index_object_further(OUT, I, depth, details, 0);

	if (IXInstances::sibling(I))
		IXPhysicalWorld::index(OUT, IXInstances::sibling(I), depth, details);
}

@ And also:

=
int IXSpatial::add_to_World_index(OUTPUT_STREAM, faux_instance *O) {
	if ((O) && (IXInstances::is_a_thing(O))) {
		HTML::open_indented_p(OUT, 1, "tight");
		faux_instance *P = IXInstances::progenitor(O);
		if (P) {
			WRITE("<i>initial location:</i> ");
			char *rel = "in";
			if (IXInstances::is_a_supporter(P)) rel = "on";
			if (IXInstances::is_a_person(P)) rel = "carried by";
			if (O->is_a_part) rel = "part of";
			if (O->is_worn) rel = "worn by";
			WRITE("%s ", rel);
			IXInstances::write_name(OUT, P);
			int at = O->progenitor_set_at;
			if (at) Index::link(OUT, at);

		}
		HTML_CLOSE("p");
	}
	return FALSE;
}
