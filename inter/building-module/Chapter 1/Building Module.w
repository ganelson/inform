[BuildingModule::] Building Module.

Setting up the use of this module.

@h Introduction.

@d BUILDING_MODULE TRUE

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e inter_name_array_MT
@e inter_name_generator_array_MT
@e package_request_MT
@e hierarchy_location_MT
@e hierarchy_attachment_point_MT
@e hierarchy_metadatum_MT
@e module_package_MT
@e submodule_identity_MT
@e submodule_request_MT
@e compilation_module_MT
@e inter_schema_MT
@e inter_schema_node_MT
@e inter_schema_token_MT

@ With allocation functions:

=
ALLOCATE_INDIVIDUALLY(hierarchy_location)
ALLOCATE_INDIVIDUALLY(hierarchy_attachment_point)
ALLOCATE_INDIVIDUALLY(hierarchy_metadatum)
ALLOCATE_INDIVIDUALLY(package_request)
ALLOCATE_INDIVIDUALLY(module_package)
ALLOCATE_INDIVIDUALLY(submodule_identity)
ALLOCATE_INDIVIDUALLY(submodule_request)
ALLOCATE_INDIVIDUALLY(compilation_module)
ALLOCATE_INDIVIDUALLY(inter_schema)
ALLOCATE_INDIVIDUALLY(inter_schema_node)
ALLOCATE_INDIVIDUALLY(inter_schema_token)

ALLOCATE_IN_ARRAYS(inter_name, 1000)
ALLOCATE_IN_ARRAYS(inter_name_generator, 1000)

#ifdef CORE_MODULE
MAKE_ANNOTATION_FUNCTIONS(explicit_iname, inter_name)
MAKE_ANNOTATION_FUNCTIONS(module, compilation_module)
#endif

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void BuildingModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	Writers::register_writer('n', &InterNames::writer);

@

@e SCHEMA_COMPILATION_DA
@e SCHEMA_COMPILATION_DETAILS_DA
@e PACKAGING_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(SCHEMA_COMPILATION_DA, L"schema compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DETAILS_DA, L"schema compilation details", FALSE, FALSE);
	Log::declare_aspect(PACKAGING_DA, L"packaging", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('1', InterSchemas::log);
	Writers::register_logger('X', Packaging::log);

@<Register this module's command line switches@> =
	;

@h The end.

=
void BuildingModule::end(void) {
}
