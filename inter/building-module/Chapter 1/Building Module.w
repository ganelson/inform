[BuildingModule::] Building Module.

Setting up the use of this module.

@h Introduction.

@d BUILDING_MODULE TRUE

@h The beginning.

@e SCHEMA_COMPILATION_DA
@e SCHEMA_COMPILATION_DETAILS_DA
@e PACKAGING_DA

=
void BuildingModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}

@<Register this module's stream writers@> =
	Writers::register_writer('n', &InterNames::writer);

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(SCHEMA_COMPILATION_DA,
		U"schema compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DETAILS_DA,
		U"schema compilation details", FALSE, FALSE);
	Log::declare_aspect(PACKAGING_DA,
		U"packaging", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('1', InterSchemas::log);
	Writers::register_logger('X', Packaging::log);

@h Initialising.
The following is a component part of the `inter_tree` structure, and is comprised
of four subcomponents of its own. That makes a lot of working data, but none of
it changes the meaning of an Inter tree: it exists as workspace needed by the
functions in this module for constructing trees.

=
typedef struct building_site {
	struct site_structure_data strdata;
	struct site_hierarchy_data shdata;
	struct site_packaging_data spdata;
	struct site_production_data sprdata;
	struct site_primitives_data spridata;
	struct site_origins_data soridata;
} building_site;

void BuildingModule::clear_data(inter_tree *I) {
	LargeScale::clear_site_data(I);
	HierarchyLocations::clear_site_data(I);
	Produce::clear_site_data(I);
	Packaging::clear_site_data(I);
	Primitives::clear_site_data(I);
	Origins::clear_site_data(I);
}

@h The end.

=
void BuildingModule::end(void) {
}
