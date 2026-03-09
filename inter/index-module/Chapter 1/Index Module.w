[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

@e INDEX_SORTING_MREASON
@e MAP_INDEX_MREASON
@e SCENE_SORTING_MREASON

@e SPATIAL_MAP_DA
@e SPATIAL_MAP_WORKINGS_DA

=
void IndexModule::start(void) {
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");
	Memory::reason_name(SCENE_SORTING_MREASON, "scene index sorting");
	Log::declare_aspect(SPATIAL_MAP_DA, U"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, U"spatial map workings", FALSE, FALSE);
}
void IndexModule::end(void) {
}
