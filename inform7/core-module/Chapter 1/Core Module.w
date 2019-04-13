[CoreModule::] Core Module.

Setting up the use of this module.

@h Introduction.

@d CORE_MODULE TRUE

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e bibliographic_datum_MT
@e heading_MT
@e phrase_MT
@e inference_array_MT
@e property_MT
@e property_permission_MT
@e extension_file_MT
@e rulebook_MT
@e booking_MT
@e phrase_option_array_MT
@e instance_MT
@e table_MT
@e table_column_MT
@e literal_text_MT
@e text_substitution_MT
@e invocation_array_MT
@e implication_MT
@e activity_MT
@e activity_list_array_MT
@e use_option_MT
@e i6_memory_setting_MT
@e definition_MT
@e binary_predicate_MT
@e pcalc_prop_array_MT
@e pcalc_func_array_MT
@e pcalc_prop_deferral_MT
@e literal_pattern_MT
@e generalisation_MT
@e extension_census_datum_MT
@e extension_dictionary_entry_MT
@e known_extension_clash_MT
@e i6_schema_array_MT
@e list_together_routine_MT
@e past_tense_condition_record_MT
@e past_tense_action_record_MT
@e named_rulebook_outcome_MT
@e label_namespace_MT
@e stacked_variable_array_MT
@e stacked_variable_list_array_MT
@e stacked_variable_owner_array_MT
@e stacked_variable_owner_list_array_MT
@e pointer_allocation_MT
@e ph_stack_frame_box_MT
@e i6_inclusion_matter_MT
@e literal_list_MT
@e extension_identifier_database_entry_array_MT
@e control_structure_phrase_MT
@e adjective_meaning_MT
@e adjective_meaning_block_MT
@e measurement_definition_MT
@e literal_pattern_name_MT
@e equation_MT
@e equation_symbol_MT
@e equation_node_MT
@e placement_affecting_array_MT
@e activity_crossref_array_MT
@e VM_usage_note_MT
@e invocation_options_array_MT
@e inv_token_problem_token_MT
@e application_array_MT
@e plugin_call_array_MT
@e plugin_MT
@e nonlocal_variable_MT
@e inference_subject_MT
@e property_of_value_storage_MT
@e to_phrase_request_MT
@e constant_phrase_MT
@e use_as_event_MT
@e instance_usage_array_MT
@e rule_MT
@e rulebook_outcome_MT
@e applicability_condition_MT
@e natural_language_MT
@e llist_entry_MT
@e response_message_MT
@e table_contribution_array_MT
@e contents_entry_MT
@e local_variable_array_MT
@e relation_guard_MT
@e pcalc_term_array_MT
@e special_meaning_holder_MT
@e runtime_kind_structure_MT
@e internal_test_case_MT
@e test_scenario_MT
@e counting_data_MT
@e kind_interaction_MT
@e dval_written_MT
@e nascent_array_MT
@e value_holster_array_MT
@e inter_namespace_MT
@e inter_name_MT
@e inter_name_family_MT
@e inter_name_consumption_token_MT
@e adjective_iname_holder_MT
@e compilation_module_MT
@e inter_schema_MT
@e inter_schema_node_MT
@e inter_schema_token_MT
@e package_request_MT
@e named_resource_location_MT
@e hierarchy_attachment_point_MT
@e subpackage_request_counter_MT

@ Deep breath, then: the following macros define several hundred functions.

=
ALLOCATE_INDIVIDUALLY(activity)
ALLOCATE_INDIVIDUALLY(adjective_meaning)
ALLOCATE_INDIVIDUALLY(adjective_meaning_block)
ALLOCATE_INDIVIDUALLY(applicability_condition)
ALLOCATE_INDIVIDUALLY(binary_predicate)
ALLOCATE_INDIVIDUALLY(booking)
ALLOCATE_INDIVIDUALLY(compilation_module)
ALLOCATE_INDIVIDUALLY(constant_phrase)
ALLOCATE_INDIVIDUALLY(contents_entry)
ALLOCATE_INDIVIDUALLY(control_structure_phrase)
ALLOCATE_INDIVIDUALLY(counting_data)
ALLOCATE_INDIVIDUALLY(definition)
ALLOCATE_INDIVIDUALLY(dval_written)
ALLOCATE_INDIVIDUALLY(equation_node)
ALLOCATE_INDIVIDUALLY(equation_symbol)
ALLOCATE_INDIVIDUALLY(equation)
ALLOCATE_INDIVIDUALLY(extension_census_datum)
ALLOCATE_INDIVIDUALLY(extension_dictionary_entry)
ALLOCATE_INDIVIDUALLY(extension_file)
ALLOCATE_INDIVIDUALLY(generalisation)
ALLOCATE_INDIVIDUALLY(heading)
ALLOCATE_INDIVIDUALLY(i6_inclusion_matter)
ALLOCATE_INDIVIDUALLY(i6_memory_setting)
ALLOCATE_INDIVIDUALLY(implication)
ALLOCATE_INDIVIDUALLY(inference_subject)
ALLOCATE_INDIVIDUALLY(instance)
ALLOCATE_INDIVIDUALLY(inter_namespace)
ALLOCATE_INDIVIDUALLY(inter_name)
ALLOCATE_INDIVIDUALLY(inter_name_family)
ALLOCATE_INDIVIDUALLY(inter_name_consumption_token)
ALLOCATE_INDIVIDUALLY(internal_test_case)
ALLOCATE_INDIVIDUALLY(inv_token_problem_token)
ALLOCATE_INDIVIDUALLY(kind_interaction)
ALLOCATE_INDIVIDUALLY(known_extension_clash)
ALLOCATE_INDIVIDUALLY(label_namespace)
ALLOCATE_INDIVIDUALLY(list_together_routine)
ALLOCATE_INDIVIDUALLY(literal_list)
ALLOCATE_INDIVIDUALLY(literal_pattern_name)
ALLOCATE_INDIVIDUALLY(literal_pattern)
ALLOCATE_INDIVIDUALLY(literal_text)
ALLOCATE_INDIVIDUALLY(llist_entry)
ALLOCATE_INDIVIDUALLY(measurement_definition)
ALLOCATE_INDIVIDUALLY(named_rulebook_outcome)
ALLOCATE_INDIVIDUALLY(nascent_array)
ALLOCATE_INDIVIDUALLY(natural_language)
ALLOCATE_INDIVIDUALLY(nonlocal_variable)
ALLOCATE_INDIVIDUALLY(past_tense_action_record)
ALLOCATE_INDIVIDUALLY(past_tense_condition_record)
ALLOCATE_INDIVIDUALLY(pcalc_prop_deferral)
ALLOCATE_INDIVIDUALLY(ph_stack_frame_box)
ALLOCATE_INDIVIDUALLY(phrase)
ALLOCATE_INDIVIDUALLY(plugin)
ALLOCATE_INDIVIDUALLY(pointer_allocation)
ALLOCATE_INDIVIDUALLY(property_of_value_storage)
ALLOCATE_INDIVIDUALLY(property_permission)
ALLOCATE_INDIVIDUALLY(property)
ALLOCATE_INDIVIDUALLY(relation_guard)
ALLOCATE_INDIVIDUALLY(response_message)
ALLOCATE_INDIVIDUALLY(rule)
ALLOCATE_INDIVIDUALLY(rulebook_outcome)
ALLOCATE_INDIVIDUALLY(rulebook)
ALLOCATE_INDIVIDUALLY(special_meaning_holder)
ALLOCATE_INDIVIDUALLY(table_column)
ALLOCATE_INDIVIDUALLY(table)
ALLOCATE_INDIVIDUALLY(test_scenario)
ALLOCATE_INDIVIDUALLY(text_substitution)
ALLOCATE_INDIVIDUALLY(to_phrase_request)
ALLOCATE_INDIVIDUALLY(use_as_event)
ALLOCATE_INDIVIDUALLY(use_option)
ALLOCATE_INDIVIDUALLY(VM_usage_note)
ALLOCATE_INDIVIDUALLY(runtime_kind_structure)
ALLOCATE_INDIVIDUALLY(adjective_iname_holder)
ALLOCATE_INDIVIDUALLY(inter_schema)
ALLOCATE_INDIVIDUALLY(inter_schema_node)
ALLOCATE_INDIVIDUALLY(inter_schema_token)
ALLOCATE_INDIVIDUALLY(package_request)
ALLOCATE_INDIVIDUALLY(named_resource_location)
ALLOCATE_INDIVIDUALLY(hierarchy_attachment_point)
ALLOCATE_INDIVIDUALLY(subpackage_request_counter)

@ So much for the managed structures: now for the unmanaged structures.

=
ALLOCATE_IN_ARRAYS(activity_crossref, 100)
ALLOCATE_IN_ARRAYS(activity_list, 1000)
ALLOCATE_IN_ARRAYS(application, 100)
ALLOCATE_IN_ARRAYS(extension_identifier_database_entry, 100)
ALLOCATE_IN_ARRAYS(i6_schema, 100)
ALLOCATE_IN_ARRAYS(inference, 100)
ALLOCATE_IN_ARRAYS(instance_usage, 200)
ALLOCATE_IN_ARRAYS(invocation_options, 100)
ALLOCATE_IN_ARRAYS(local_variable, 100)
ALLOCATE_IN_ARRAYS(pcalc_func, 1000)
ALLOCATE_IN_ARRAYS(pcalc_prop, 1000)
ALLOCATE_IN_ARRAYS(pcalc_term, 1000)
ALLOCATE_IN_ARRAYS(phrase_option, 100)
ALLOCATE_IN_ARRAYS(placement_affecting, 100)
ALLOCATE_IN_ARRAYS(plugin_call, 100)
ALLOCATE_IN_ARRAYS(stacked_variable_list, 100)
ALLOCATE_IN_ARRAYS(stacked_variable_owner_list, 100)
ALLOCATE_IN_ARRAYS(stacked_variable_owner, 100)
ALLOCATE_IN_ARRAYS(stacked_variable, 100)
ALLOCATE_IN_ARRAYS(table_contribution, 100)
ALLOCATE_IN_ARRAYS(value_holster, 100)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

@d WORDING_LOGS_ALLOWED

@d REGISTER_WRITER(c, f) Writers::register_logger(c, &f##_writer);
@d COMPILE_WRITER(t, f)
	void f##_writer(text_stream *format, void *obj) { text_stream *SDL = DL; DL = format; if (DL) f((t) obj); DL = SDL; }

@d REGISTER_WRITER_I(c, f) Writers::register_logger_I(c, &f##_writer);
@d COMPILE_WRITER_I(t, f)
	void f##_writer(text_stream *format, int I) { text_stream *SDL = DL; DL = format; if (DL) f((t) I); DL = SDL; }

@d REGISTER_WRITER_W(c, f) Writers::register_logger_W(c, &f##_writer);
@d COMPILE_WRITER_W(f)
	void f##_writer(text_stream *format, wording W) { text_stream *SDL = DL; DL = format; if (DL) f(W); DL = SDL; }

=
COMPILE_WRITER(pcalc_term *, Calculus::Terms::log)
COMPILE_WRITER(binary_predicate *, BinaryPredicates::log)
COMPILE_WRITER(table *, Tables::log)
COMPILE_WRITER(booking *, Rules::Bookings::log)
COMPILE_WRITER(table_column *, Tables::Columns::log)
COMPILE_WRITER(pcalc_prop *, Calculus::Propositions::log)
COMPILE_WRITER(extension_dictionary_entry *, Extensions::Dictionary::log_entry)
COMPILE_WRITER(parse_node *, Invocations::log_list)
COMPILE_WRITER(parse_node *, Invocations::log)
COMPILE_WRITER(heading *, Sentences::Headings::log)
COMPILE_WRITER(ph_type_data *, Phrases::TypeData::Textual::log)
COMPILE_WRITER(inference *, World::Inferences::log)
COMPILE_WRITER(i6_schema *, Calculus::Schemas::log)
COMPILE_WRITER(inter_schema *, InterSchemas::log)
COMPILE_WRITER(natural_language *, NaturalLanguages::log)
COMPILE_WRITER(inference_subject *, InferenceSubjects::log)
COMPILE_WRITER(rulebook *, Rulebooks::log)
COMPILE_WRITER(local_variable *, LocalVariables::log)
COMPILE_WRITER_I(int, World::Inferences::log_kind)
COMPILE_WRITER(instance *, Instances::log)
COMPILE_WRITER(pcalc_prop *, Calculus::Atoms::log)
COMPILE_WRITER(unit_sequence *, Kinds::Dimensions::log_unit_sequence)
COMPILE_WRITER(equation *, Equations::log)
COMPILE_WRITER(phrase *, Phrases::log)
COMPILE_WRITER(adjective_usage *, AdjectiveUsages::log)
COMPILE_WRITER(ph_usage_data *, Phrases::Usage::log)
COMPILE_WRITER(kind *, Kinds::Textual::log)
COMPILE_WRITER_I(int, Sentences::VPs::log)
COMPILE_WRITER(extension_file *, Extensions::Files::log)
COMPILE_WRITER(package_request *, Packaging::log)
COMPILE_WRITER(property *, Properties::log)
COMPILE_WRITER(nonlocal_variable *, NonlocalVariables::log)
COMPILE_WRITER(noun *, Nouns::log)

@ =
void CoreModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@ Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional |malloc| and |calloc| routines.

@e EXTENSION_DICTIONARY_MREASON
@e INDEX_SORTING_MREASON
@e INSTANCE_COUNTING_MREASON
@e MAP_INDEX_MREASON
@e PARTITION_MREASON
@e TYPE_TABLES_MREASON
@e INV_LIST_MREASON
@e COMPILATION_SIZE_MREASON
@e OBJECT_COMPILATION_MREASON
@e DOC_FRAGMENT_MREASON
@e RELATION_CONSTRUCTION_MREASON
@e EMIT_ARRAY_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(EXTENSION_DICTIONARY_MREASON, "extension dictionary");
	Memory::reason_name(INDEX_SORTING_MREASON, "index sorting");
	Memory::reason_name(INSTANCE_COUNTING_MREASON, "instance-of-kind counting");
	Memory::reason_name(MAP_INDEX_MREASON, "map in the World index");
	Memory::reason_name(PARTITION_MREASON, "initial state for relations in groups");
	Memory::reason_name(TYPE_TABLES_MREASON, "tables of details of the kinds of values");
	Memory::reason_name(INV_LIST_MREASON, "lists for type-checking invocations");
	Memory::reason_name(COMPILATION_SIZE_MREASON, "size estimates for compiled objects");
	Memory::reason_name(OBJECT_COMPILATION_MREASON, "compilation workspace for objects");
	Memory::reason_name(DOC_FRAGMENT_MREASON, "documentation fragments");
	Memory::reason_name(RELATION_CONSTRUCTION_MREASON, "relation bitmap storage");
	Memory::reason_name(EMIT_ARRAY_MREASON, "emitter array storage");

@<Register this module's stream writers@> =
	Writers::register_writer_I('B', &CoreModule::writer);
	Writers::register_writer('I', &Instances::writer);
	Writers::register_writer('L', &LocalVariables::writer);
	Writers::register_writer('n', &InterNames::writer);
	Writers::register_writer('X', &Extensions::IDs::writer);

@

@e ACTION_CREATIONS_DA
@e ACTION_PATTERN_COMPILATION_DA
@e ACTION_PATTERN_PARSING_DA
@e ASSEMBLIES_DA
@e ASSERTIONS_DA
@e CASE_INSENSITIVE_FILEHANDLING_DA
@e CONDITIONS_DA
@e DEBUGGING_LOG_CONTENTS_DA
@e DESCRIPTION_COMPILATION_DA
@e EXPRESSIONS_DA
@e EXTENSIONS_CENSUS_DA
@e FIGURE_CREATIONS_DA
@e GRAMMAR_DA
@e GRAMMAR_CONSTRUCTION_DA
@e HEADINGS_DA
@e IMPLICATIONS_DA
@e INFERENCES_DA
@e LOCAL_VARIABLES_DA
@e MEANING_LIST_ALLOCATION_DA
@e MEMORY_ALLOCATION_DA
@e NOUN_RESOLUTION_DA
@e OBJECT_COMPILATION_DA
@e OBJECT_CREATIONS_DA
@e OBJECT_TREE_DA
@e PACKAGING_DA
@e PHRASE_COMPARISONS_DA
@e PHRASE_COMPILATION_DA
@e PHRASE_CREATIONS_DA
@e PHRASE_REGISTRATION_DA
@e PHRASE_USAGE_DA
@e PREDICATE_CALCULUS_DA
@e PREDICATE_CALCULUS_WORKINGS_DA
@e PRONOUNS_DA
@e PROPERTY_CREATIONS_DA
@e PROPERTY_PROVISION_DA
@e PROPERTY_TRANSLATIONS_DA
@e RELATION_DEFINITIONS_DA
@e RULE_ATTACHMENTS_DA
@e RULEBOOK_COMPILATION_DA
@e SCHEMA_COMPILATION_DA
@e SCHEMA_COMPILATION_DETAILS_DA
@e SPATIAL_MAP_DA
@e SPATIAL_MAP_WORKINGS_DA
@e SPECIFICATION_PERMISSIONS_DA
@e SPECIFICATION_USAGE_DA
@e SPECIFICITIES_DA
@e TABLES_DA
@e TEXT_SUBSTITUTIONS_DA
@e VARIABLE_CREATIONS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(ACTION_CREATIONS_DA, L"action creations", FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_COMPILATION_DA, L"action pattern compilation", FALSE, FALSE);
	Log::declare_aspect(ACTION_PATTERN_PARSING_DA, L"action pattern parsing", FALSE, FALSE);
	Log::declare_aspect(ASSEMBLIES_DA, L"assemblies", FALSE, FALSE);
	Log::declare_aspect(ASSERTIONS_DA, L"assertions", FALSE, TRUE);
	Log::declare_aspect(CASE_INSENSITIVE_FILEHANDLING_DA, L"case insensitive filehandling", FALSE, FALSE);
	Log::declare_aspect(CONDITIONS_DA, L"conditions", FALSE, FALSE);
	Log::declare_aspect(DEBUGGING_LOG_CONTENTS_DA, L"debugging log contents", TRUE, FALSE);
	Log::declare_aspect(DESCRIPTION_COMPILATION_DA, L"description compilation", FALSE, FALSE);
	Log::declare_aspect(EXPRESSIONS_DA, L"expressions", FALSE, FALSE);
	Log::declare_aspect(EXTENSIONS_CENSUS_DA, L"extensions census", FALSE, FALSE);
	Log::declare_aspect(FIGURE_CREATIONS_DA, L"figure creations", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_DA, L"grammar", FALSE, FALSE);
	Log::declare_aspect(GRAMMAR_CONSTRUCTION_DA, L"grammar construction", FALSE, FALSE);
	Log::declare_aspect(HEADINGS_DA, L"headings", FALSE, FALSE);
	Log::declare_aspect(IMPLICATIONS_DA, L"implications", FALSE, TRUE);
	Log::declare_aspect(INFERENCES_DA, L"inferences", FALSE, TRUE);
	Log::declare_aspect(LOCAL_VARIABLES_DA, L"local variables", FALSE, FALSE);
	Log::declare_aspect(MEANING_LIST_ALLOCATION_DA, L"meaning list allocation", FALSE, FALSE);
	Log::declare_aspect(MEMORY_ALLOCATION_DA, L"memory allocation", FALSE, FALSE);
	Log::declare_aspect(NOUN_RESOLUTION_DA, L"noun resolution", FALSE, FALSE);
	Log::declare_aspect(OBJECT_COMPILATION_DA, L"object compilation", FALSE, FALSE);
	Log::declare_aspect(OBJECT_CREATIONS_DA, L"object creations", FALSE, FALSE);
	Log::declare_aspect(OBJECT_TREE_DA, L"object tree", FALSE, FALSE);
	Log::declare_aspect(PACKAGING_DA, L"packaging", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPARISONS_DA, L"phrase comparisons", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPILATION_DA, L"phrase compilation", FALSE, FALSE);
	Log::declare_aspect(PHRASE_CREATIONS_DA, L"phrase creations", FALSE, FALSE);
	Log::declare_aspect(PHRASE_REGISTRATION_DA, L"phrase registration", FALSE, FALSE);
	Log::declare_aspect(PHRASE_USAGE_DA, L"phrase usage", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_DA, L"predicate calculus", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_WORKINGS_DA, L"predicate calculus workings", FALSE, FALSE);
	Log::declare_aspect(PRONOUNS_DA, L"pronouns", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_CREATIONS_DA, L"property creations", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_PROVISION_DA, L"property provision", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_TRANSLATIONS_DA, L"property translations", FALSE, FALSE);
	Log::declare_aspect(RELATION_DEFINITIONS_DA, L"relation definitions", FALSE, FALSE);
	Log::declare_aspect(RULE_ATTACHMENTS_DA, L"rule attachments", FALSE, FALSE);
	Log::declare_aspect(RULEBOOK_COMPILATION_DA, L"rulebook compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DA, L"schema compilation", FALSE, FALSE);
	Log::declare_aspect(SCHEMA_COMPILATION_DETAILS_DA, L"schema compilation details", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);
	Log::declare_aspect(SPECIFICATION_PERMISSIONS_DA, L"specification permissions", FALSE, FALSE);
	Log::declare_aspect(SPECIFICATION_USAGE_DA, L"specification usage", FALSE, FALSE);
	Log::declare_aspect(SPECIFICITIES_DA, L"specificities", FALSE, FALSE);
	Log::declare_aspect(TABLES_DA, L"table construction", FALSE, FALSE);
	Log::declare_aspect(TEXT_SUBSTITUTIONS_DA, L"text substitutions", FALSE, FALSE);
	Log::declare_aspect(VARIABLE_CREATIONS_DA, L"variable creations", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('0', Calculus::Terms::log);
	REGISTER_WRITER('1', InterSchemas::log);
	REGISTER_WRITER('2', BinaryPredicates::log);
	REGISTER_WRITER('B', Tables::log);
	REGISTER_WRITER('b', Rules::Bookings::log);
	REGISTER_WRITER('C', Tables::Columns::log);
	REGISTER_WRITER('D', Calculus::Propositions::log);
	REGISTER_WRITER('d', Extensions::Dictionary::log_entry);
	REGISTER_WRITER('E', Invocations::log_list);
	REGISTER_WRITER('e', Invocations::log);
	REGISTER_WRITER('H', Sentences::Headings::log);
	REGISTER_WRITER('h', Phrases::TypeData::Textual::log);
	REGISTER_WRITER('I', World::Inferences::log);
	REGISTER_WRITER('i', Calculus::Schemas::log);
	REGISTER_WRITER('J', NaturalLanguages::log);
	REGISTER_WRITER('j', InferenceSubjects::log);
	REGISTER_WRITER('K', Rulebooks::log);
	REGISTER_WRITER('k', LocalVariables::log);
	REGISTER_WRITER_I('n', World::Inferences::log_kind)
	REGISTER_WRITER('O', Instances::log);
	REGISTER_WRITER('o', Calculus::Atoms::log);
	REGISTER_WRITER('Q', Kinds::Dimensions::log_unit_sequence);
	REGISTER_WRITER('q', Equations::log);
	REGISTER_WRITER('R', Phrases::log);
	REGISTER_WRITER('r', AdjectiveUsages::log);
	REGISTER_WRITER('U', Phrases::Usage::log);
	REGISTER_WRITER('u', Kinds::Textual::log);
	REGISTER_WRITER_I('V', Sentences::VPs::log)
	REGISTER_WRITER('X', Packaging::log);
	REGISTER_WRITER('x', Extensions::Files::log);
	REGISTER_WRITER('Y', Properties::log);
	REGISTER_WRITER('Z', NonlocalVariables::log);
	REGISTER_WRITER('z', Nouns::log);

@<Register this module's command line switches@> =
	;

@ =
void CoreModule::writer(OUTPUT_STREAM, char *format_string, int wn) {
	if (Time::fixed()) {
		if (wn) WRITE("9Z99");
		else WRITE("Inform 7.99.99");
	} else {
		if (wn) WRITE("[[Build Number]]");
		else WRITE("Inform [[Version Number]]");
	}
}

@h The end.

=
void CoreModule::end(void) {
}
