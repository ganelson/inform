[InbuildModule::] Inter Module.

Setting up the use of this module.

@h Introduction.

@d INBUILD_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e inform_kit_MT
@e inform_extension_MT
@e inform_kit_ittt_MT
@e element_activation_MT
@e inbuild_genre_MT
@e inbuild_work_MT
@e inbuild_edition_MT
@e inbuild_requirement_MT
@e inbuild_copy_MT
@e build_vertex_MT
@e build_methodology_MT
@e build_script_MT
@e build_step_MT
@e inbuild_nest_MT
@e inbuild_search_result_MT
@e inbuild_work_database_entry_array_MT
@e extension_census_datum_MT
@e extension_census_MT
@e inform_template_MT
@e inform_project_MT
@e inform_language_MT
@e inform_pipeline_MT
@e copy_error_MT
@e extension_dictionary_entry_MT
@e known_extension_clash_MT
@e build_skill_MT

=
ALLOCATE_INDIVIDUALLY(inform_kit)
ALLOCATE_INDIVIDUALLY(inform_extension)
ALLOCATE_INDIVIDUALLY(inform_kit_ittt)
ALLOCATE_INDIVIDUALLY(element_activation)
ALLOCATE_INDIVIDUALLY(inbuild_genre)
ALLOCATE_INDIVIDUALLY(inbuild_work)
ALLOCATE_INDIVIDUALLY(inbuild_edition)
ALLOCATE_INDIVIDUALLY(inbuild_requirement)
ALLOCATE_INDIVIDUALLY(inbuild_copy)
ALLOCATE_INDIVIDUALLY(build_vertex)
ALLOCATE_INDIVIDUALLY(build_methodology)
ALLOCATE_INDIVIDUALLY(build_script)
ALLOCATE_INDIVIDUALLY(build_step)
ALLOCATE_INDIVIDUALLY(inbuild_nest)
ALLOCATE_INDIVIDUALLY(inbuild_search_result)
ALLOCATE_INDIVIDUALLY(extension_census_datum)
ALLOCATE_INDIVIDUALLY(extension_census)
ALLOCATE_INDIVIDUALLY(inform_template)
ALLOCATE_INDIVIDUALLY(inform_project)
ALLOCATE_INDIVIDUALLY(inform_language)
ALLOCATE_INDIVIDUALLY(inform_pipeline)
ALLOCATE_INDIVIDUALLY(copy_error)
ALLOCATE_INDIVIDUALLY(extension_dictionary_entry)
ALLOCATE_INDIVIDUALLY(known_extension_clash)
ALLOCATE_INDIVIDUALLY(build_skill)

ALLOCATE_IN_ARRAYS(inbuild_work_database_entry, 100)

@h The beginning.

=
void InbuildModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
	KitManager::start();
	ExtensionManager::start();
	TemplateManager::start();
	LanguageManager::start();
	ProjectBundleManager::start();
	ProjectFileManager::start();
	PipelineManager::start();
	InterSkill::create();
	Inform7Skill::create();
	Inform6Skill::create();
	InblorbSkill::create();
}

@

@e EXTENSION_DICTIONARY_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(EXTENSION_DICTIONARY_MREASON, "extension dictionary");

@<Register this module's stream writers@> =
	Writers::register_writer('v', &VersionNumbers::writer);
	Writers::register_writer('X', &Works::writer);

@

@e EXTENSIONS_CENSUS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(EXTENSIONS_CENSUS_DA, L"extensions census", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_writer('J', &Languages::log);

@<Register this module's command line switches@> =
	;

@h The end.

=
void InbuildModule::end(void) {
}
