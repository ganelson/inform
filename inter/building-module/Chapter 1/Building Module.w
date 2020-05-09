[BuildingModule::] Building Module.

Setting up the use of this module.

@h Introduction.

@d BUILDING_MODULE TRUE

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e inter_name_array_CLASS
@e inter_name_generator_array_CLASS
@e package_request_CLASS
@e hierarchy_location_CLASS
@e hierarchy_attachment_point_CLASS
@e hierarchy_metadatum_CLASS
@e module_package_CLASS
@e submodule_identity_CLASS
@e submodule_request_CLASS
@e compilation_module_CLASS
@e inter_schema_CLASS
@e inter_schema_node_CLASS
@e inter_schema_token_CLASS

@ With allocation functions:

=
DECLARE_CLASS(hierarchy_location)
DECLARE_CLASS(hierarchy_attachment_point)
DECLARE_CLASS(hierarchy_metadatum)
DECLARE_CLASS(package_request)
DECLARE_CLASS(module_package)
DECLARE_CLASS(submodule_identity)
DECLARE_CLASS(submodule_request)
DECLARE_CLASS(compilation_module)
DECLARE_CLASS(inter_schema)
DECLARE_CLASS(inter_schema_node)
DECLARE_CLASS(inter_schema_token)

DECLARE_CLASS_ALLOCATED_IN_ARRAYS(inter_name, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(inter_name_generator, 1000)

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
