[IXRegions::] Regions.

Indexing the player's initial position.

@ 

=
int IXRegions::add_to_World_index(OUTPUT_STREAM, faux_instance *O) {
	if ((O) && (IXInstances::is_a_room(O))) {
		faux_instance *R = IXInstances::region_of(O);
		if (R) PL::HTMLMap::colour_chip(OUT, O, R, O->region_set_at);
	}
	return FALSE;
}
