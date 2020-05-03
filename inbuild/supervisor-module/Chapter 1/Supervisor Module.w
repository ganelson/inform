[SupervisorModule::] Supervisor Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d SUPERVISOR_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e build_methodology_MT
@e build_script_MT
@e build_skill_MT
@e build_step_MT
@e build_vertex_MT
@e control_structure_phrase_MT
@e copy_error_MT
@e element_activation_MT
@e extension_census_datum_MT
@e extension_census_MT
@e extension_dictionary_entry_MT
@e heading_MT
@e inbuild_copy_MT
@e inbuild_edition_MT
@e inbuild_genre_MT
@e inbuild_nest_MT
@e inbuild_requirement_MT
@e inbuild_search_result_MT
@e inbuild_work_MT
@e inform_extension_MT
@e inform_kit_ittt_MT
@e inform_kit_MT
@e inform_language_MT
@e inform_pipeline_MT
@e inform_project_MT
@e inform_template_MT
@e kit_dependency_MT
@e known_extension_clash_MT

@e inbuild_work_database_entry_array_MT

=
ALLOCATE_INDIVIDUALLY(build_methodology)
ALLOCATE_INDIVIDUALLY(build_script)
ALLOCATE_INDIVIDUALLY(build_skill)
ALLOCATE_INDIVIDUALLY(build_step)
ALLOCATE_INDIVIDUALLY(build_vertex)
ALLOCATE_INDIVIDUALLY(control_structure_phrase)
ALLOCATE_INDIVIDUALLY(copy_error)
ALLOCATE_INDIVIDUALLY(element_activation)
ALLOCATE_INDIVIDUALLY(extension_census_datum)
ALLOCATE_INDIVIDUALLY(extension_census)
ALLOCATE_INDIVIDUALLY(extension_dictionary_entry)
ALLOCATE_INDIVIDUALLY(heading)
ALLOCATE_INDIVIDUALLY(inbuild_copy)
ALLOCATE_INDIVIDUALLY(inbuild_edition)
ALLOCATE_INDIVIDUALLY(inbuild_genre)
ALLOCATE_INDIVIDUALLY(inbuild_nest)
ALLOCATE_INDIVIDUALLY(inbuild_requirement)
ALLOCATE_INDIVIDUALLY(inbuild_search_result)
ALLOCATE_INDIVIDUALLY(inbuild_work)
ALLOCATE_INDIVIDUALLY(inform_extension)
ALLOCATE_INDIVIDUALLY(inform_kit_ittt)
ALLOCATE_INDIVIDUALLY(inform_kit)
ALLOCATE_INDIVIDUALLY(inform_language)
ALLOCATE_INDIVIDUALLY(inform_pipeline)
ALLOCATE_INDIVIDUALLY(inform_project)
ALLOCATE_INDIVIDUALLY(inform_template)
ALLOCATE_INDIVIDUALLY(kit_dependency)
ALLOCATE_INDIVIDUALLY(known_extension_clash)

ALLOCATE_IN_ARRAYS(inbuild_work_database_entry, 100)

@ Like all modules, this one must define a |start| and |end| function:

=
void SupervisorModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	Supervisor::start();
}
void SupervisorModule::end(void) {
}

@

@e EXTENSION_DICTIONARY_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(EXTENSION_DICTIONARY_MREASON, "extension dictionary");

@<Register this module's stream writers@> =
	Writers::register_writer('X', &Works::writer);
	Writers::register_writer('J', &Languages::log);

@

@e EXTENSIONS_CENSUS_DA
@e HEADINGS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(EXTENSIONS_CENSUS_DA, L"extensions census", FALSE, FALSE);
	Log::declare_aspect(HEADINGS_DA, L"headings", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	;

@ This module uses |syntax|, and adds the following annotations to the
syntax tree.

@e embodying_heading_ANNOT /* |heading|: for parse nodes of headings */
@e inclusion_of_extension_ANNOT /* |inform_extension|: for parse nodes of headings */

=
DECLARE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
MAKE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
DECLARE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)
MAKE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)
