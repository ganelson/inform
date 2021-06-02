[IXMap::] The Map.

Indexing the player's initial position.

@ =
int IXMap::add_to_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_room))) {
		PL::SpatialMap::index_room_connections(OUT, O);
	}
	return FALSE;
}

int IXMap::annotate_in_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_door))) {
		instance *A = NULL, *B = NULL;
		Map::get_door_data(O, &A, &B);
		if ((A) && (B)) WRITE(" - <i>door to ");
		else WRITE(" - <i>one-sided door to ");
		instance *X = A;
		if (A == IXPhysicalWorld::room_being_indexed()) X = B;
		if (X == NULL) {
			parse_node *S = PropertyInferences::value_of(
				Instances::as_subject(O), P_other_side);
			X = Rvalues::to_object_instance(S);
		}
		if (X == NULL) WRITE("nowhere");
		else IXInstances::index_name(OUT, X);
		WRITE("</i>");
		return TRUE;
	}
	return FALSE;
}
