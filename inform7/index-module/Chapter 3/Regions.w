[IXRegions::] Regions.

Indexing the player's initial position.

@ 

=
int IXRegions::add_to_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_room))) {
		instance *R = Regions::enclosing(O);
		if (R) PL::HTMLMap::colour_chip(OUT, O, R, REGIONS_DATA(O)->in_region_set_at);
	}
	return FALSE;
}
