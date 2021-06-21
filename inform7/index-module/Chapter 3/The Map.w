[IXMap::] The Map.

Indexing the player's initial position.

@ =
int IXMap::add_to_World_index(OUTPUT_STREAM, faux_instance *O) {
	if ((O) && (IXInstances::is_a_room(O))) {
		PL::SpatialMap::index_room_connections(OUT, O);
	}
	return FALSE;
}

int IXMap::annotate_in_World_index(OUTPUT_STREAM, faux_instance *O) {
	if ((O) && (IXInstances::is_a_door(O))) {
		faux_instance *A = NULL, *B = NULL;
		IXInstances::get_door_data(O, &A, &B);
		if ((A) && (B)) WRITE(" - <i>door to ");
		else WRITE(" - <i>one-sided door to ");
		faux_instance *X = A;
		if (A == IXPhysicalWorld::room_being_indexed()) X = B;
		if (X == NULL) X = IXInstances::other_side_of_door(O);
		if (X == NULL) WRITE("nowhere");
		else IXInstances::write_name(OUT, X);
		WRITE("</i>");
		return TRUE;
	}
	return FALSE;
}
