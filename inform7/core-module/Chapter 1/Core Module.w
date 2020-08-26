[CoreModule::] Core Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CORE_MODULE TRUE

@ This module defines the following classes:

@e bibliographic_datum_CLASS
@e phrase_CLASS
@e inference_CLASS
@e property_CLASS
@e property_permission_CLASS
@e rulebook_CLASS
@e booking_CLASS
@e phrase_option_CLASS
@e instance_CLASS
@e table_CLASS
@e table_column_CLASS
@e literal_text_CLASS
@e text_substitution_CLASS
@e invocation_CLASS
@e implication_CLASS
@e activity_CLASS
@e activity_list_CLASS
@e use_option_CLASS
@e i6_memory_setting_CLASS
@e definition_CLASS
@e pcalc_prop_deferral_CLASS
@e literal_pattern_CLASS
@e generalisation_CLASS
@e list_together_routine_CLASS
@e past_tense_condition_record_CLASS
@e past_tense_action_record_CLASS
@e named_rulebook_outcome_CLASS
@e stacked_variable_CLASS
@e stacked_variable_list_CLASS
@e stacked_variable_owner_CLASS
@e stacked_variable_owner_list_CLASS
@e pointer_allocation_CLASS
@e ph_stack_frame_box_CLASS
@e i6_inclusion_matter_CLASS
@e literal_list_CLASS
@e adjective_meaning_CLASS
@e measurement_definition_CLASS
@e literal_pattern_name_CLASS
@e equation_CLASS
@e equation_symbol_CLASS
@e equation_node_CLASS
@e placement_affecting_CLASS
@e activity_crossref_CLASS
@e invocation_options_CLASS
@e inv_token_problem_token_CLASS
@e application_CLASS
@e plugin_call_CLASS
@e plugin_CLASS
@e nonlocal_variable_CLASS
@e inference_subject_CLASS
@e property_of_value_storage_CLASS
@e to_phrase_request_CLASS
@e constant_phrase_CLASS
@e use_as_event_CLASS
@e instance_usage_CLASS
@e rule_CLASS
@e rulebook_outcome_CLASS
@e applicability_condition_CLASS
@e llist_entry_CLASS
@e response_message_CLASS
@e table_contribution_CLASS
@e contents_entry_CLASS
@e local_variable_CLASS
@e relation_guard_CLASS
@e runtime_kind_structure_CLASS
@e internal_test_case_CLASS
@e test_scenario_CLASS
@e counting_data_CLASS
@e kind_interaction_CLASS
@e dval_written_CLASS
@e nascent_array_CLASS
@e value_holster_CLASS
@e adjective_iname_holder_CLASS
@e label_namespace_CLASS
@e compile_task_data_CLASS
@e comparative_bp_data_CLASS

@ Deep breath, then: the following macros define several hundred functions.

=
DECLARE_CLASS(activity)
DECLARE_CLASS(adjective_meaning)
DECLARE_CLASS(applicability_condition)
DECLARE_CLASS(booking)
DECLARE_CLASS(constant_phrase)
DECLARE_CLASS(contents_entry)
DECLARE_CLASS(counting_data)
DECLARE_CLASS(definition)
DECLARE_CLASS(dval_written)
DECLARE_CLASS(equation_node)
DECLARE_CLASS(equation_symbol)
DECLARE_CLASS(equation)
DECLARE_CLASS(generalisation)
DECLARE_CLASS(i6_inclusion_matter)
DECLARE_CLASS(i6_memory_setting)
DECLARE_CLASS(implication)
DECLARE_CLASS(inference)
DECLARE_CLASS(inference_subject)
DECLARE_CLASS(instance)
DECLARE_CLASS(internal_test_case)
DECLARE_CLASS(inv_token_problem_token)
DECLARE_CLASS(kind_interaction)
DECLARE_CLASS(list_together_routine)
DECLARE_CLASS(literal_list)
DECLARE_CLASS(literal_pattern_name)
DECLARE_CLASS(literal_pattern)
DECLARE_CLASS(literal_text)
DECLARE_CLASS(llist_entry)
DECLARE_CLASS(measurement_definition)
DECLARE_CLASS(named_rulebook_outcome)
DECLARE_CLASS(nascent_array)
DECLARE_CLASS(nonlocal_variable)
DECLARE_CLASS(past_tense_action_record)
DECLARE_CLASS(past_tense_condition_record)
DECLARE_CLASS(pcalc_prop_deferral)
DECLARE_CLASS(ph_stack_frame_box)
DECLARE_CLASS(phrase)
DECLARE_CLASS(plugin)
DECLARE_CLASS(pointer_allocation)
DECLARE_CLASS(property_of_value_storage)
DECLARE_CLASS(property_permission)
DECLARE_CLASS(property)
DECLARE_CLASS(relation_guard)
DECLARE_CLASS(response_message)
DECLARE_CLASS(rule)
DECLARE_CLASS(rulebook_outcome)
DECLARE_CLASS(rulebook)
DECLARE_CLASS(table_column)
DECLARE_CLASS(table)
DECLARE_CLASS(test_scenario)
DECLARE_CLASS(text_substitution)
DECLARE_CLASS(to_phrase_request)
DECLARE_CLASS(use_as_event)
DECLARE_CLASS(use_option)
DECLARE_CLASS(runtime_kind_structure)
DECLARE_CLASS(adjective_iname_holder)
DECLARE_CLASS(label_namespace)
DECLARE_CLASS(compile_task_data)
DECLARE_CLASS(comparative_bp_data)

@ So much for the managed structures: now for the unmanaged structures.

=
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_crossref, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_list, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(application, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(instance_usage, 200)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(invocation_options, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(local_variable, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(phrase_option, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(placement_affecting, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(plugin_call, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_list, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_owner_list, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_owner, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(table_contribution, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(value_holster, 100)

@ Next we define some functions, by macro, which write to the debugging log
or other text streams.

@d REGISTER_WRITER_W(c, f) Writers::register_logger_W(c, &f##_writer);
@d COMPILE_WRITER_W(f)
	void f##_writer(text_stream *format, wording W) { text_stream *SDL = DL; DL = format; if (DL) f(W); DL = SDL; }

=
COMPILE_WRITER(table *, Tables::log)
COMPILE_WRITER(booking *, Rules::Bookings::log)
COMPILE_WRITER(table_column *, Tables::Columns::log)
COMPILE_WRITER(extension_dictionary_entry *, ExtensionDictionary::log_entry)
COMPILE_WRITER(parse_node *, Invocations::log_list)
COMPILE_WRITER(parse_node *, Invocations::log)
COMPILE_WRITER(heading *, IndexHeadings::log)
COMPILE_WRITER(ph_type_data *, Phrases::TypeData::Textual::log)
COMPILE_WRITER(inference *, World::Inferences::log)
COMPILE_WRITER(i6_schema *, Calculus::Schemas::log)
COMPILE_WRITER(inference_subject *, InferenceSubjects::log)
COMPILE_WRITER(rulebook *, Rulebooks::log)
COMPILE_WRITER(local_variable *, LocalVariables::log)
COMPILE_WRITER_I(int, World::Inferences::log_kind)
COMPILE_WRITER(instance *, Instances::log)
COMPILE_WRITER(equation *, Equations::log)
COMPILE_WRITER(phrase *, Phrases::log)
COMPILE_WRITER(ph_usage_data *, Phrases::Usage::log)
COMPILE_WRITER(property *, Properties::log)
COMPILE_WRITER(nonlocal_variable *, NonlocalVariables::log)
COMPILE_WRITER(noun *, Nouns::log)

@ Like all modules, this one must define a |start| and |end| function:

=
void CoreModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	CorePreform::set_core_internal_NTIs();
	Calculus::QuasinumericRelations::start();
	Properties::SameRelations::start();
	Properties::SettingRelations::start();
	Properties::ComparativeRelations::start();
	Tables::Relations::start();
	Properties::ProvisionRelation::start();
	Relations::Universal::start();
	Relations::Explicit::start();
	EqualityDetails::start();
	ParseTreeUsage::declare_annotations();
}
void CoreModule::end(void) {
}

@ Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional |malloc| and |calloc| routines.

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
@e FIGURE_CREATIONS_DA
@e IMPLICATIONS_DA
@e INFERENCES_DA
@e LOCAL_VARIABLES_DA
@e MEANING_LIST_ALLOCATION_DA
@e MEMORY_ALLOCATION_DA
@e NOUN_RESOLUTION_DA
@e OBJECT_COMPILATION_DA
@e OBJECT_CREATIONS_DA
@e OBJECT_TREE_DA
@e PHRASE_COMPARISONS_DA
@e PHRASE_COMPILATION_DA
@e PHRASE_CREATIONS_DA
@e PHRASE_REGISTRATION_DA
@e PHRASE_USAGE_DA
@e PRONOUNS_DA
@e PROPERTY_CREATIONS_DA
@e PROPERTY_PROVISION_DA
@e PROPERTY_TRANSLATIONS_DA
@e RELATION_DEFINITIONS_DA
@e RULE_ATTACHMENTS_DA
@e RULEBOOK_COMPILATION_DA
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
	Log::declare_aspect(FIGURE_CREATIONS_DA, L"figure creations", FALSE, FALSE);
	Log::declare_aspect(IMPLICATIONS_DA, L"implications", FALSE, TRUE);
	Log::declare_aspect(INFERENCES_DA, L"inferences", FALSE, TRUE);
	Log::declare_aspect(LOCAL_VARIABLES_DA, L"local variables", FALSE, FALSE);
	Log::declare_aspect(MEANING_LIST_ALLOCATION_DA, L"meaning list allocation", FALSE, FALSE);
	Log::declare_aspect(MEMORY_ALLOCATION_DA, L"memory allocation", FALSE, FALSE);
	Log::declare_aspect(NOUN_RESOLUTION_DA, L"noun resolution", FALSE, FALSE);
	Log::declare_aspect(OBJECT_COMPILATION_DA, L"object compilation", FALSE, FALSE);
	Log::declare_aspect(OBJECT_CREATIONS_DA, L"object creations", FALSE, FALSE);
	Log::declare_aspect(OBJECT_TREE_DA, L"object tree", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPARISONS_DA, L"phrase comparisons", FALSE, FALSE);
	Log::declare_aspect(PHRASE_COMPILATION_DA, L"phrase compilation", FALSE, FALSE);
	Log::declare_aspect(PHRASE_CREATIONS_DA, L"phrase creations", FALSE, FALSE);
	Log::declare_aspect(PHRASE_REGISTRATION_DA, L"phrase registration", FALSE, FALSE);
	Log::declare_aspect(PHRASE_USAGE_DA, L"phrase usage", FALSE, FALSE);
	Log::declare_aspect(PRONOUNS_DA, L"pronouns", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_CREATIONS_DA, L"property creations", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_PROVISION_DA, L"property provision", FALSE, FALSE);
	Log::declare_aspect(PROPERTY_TRANSLATIONS_DA, L"property translations", FALSE, FALSE);
	Log::declare_aspect(RELATION_DEFINITIONS_DA, L"relation definitions", FALSE, FALSE);
	Log::declare_aspect(RULE_ATTACHMENTS_DA, L"rule attachments", FALSE, FALSE);
	Log::declare_aspect(RULEBOOK_COMPILATION_DA, L"rulebook compilation", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_DA, L"spatial map", FALSE, FALSE);
	Log::declare_aspect(SPATIAL_MAP_WORKINGS_DA, L"spatial map workings", FALSE, FALSE);
	Log::declare_aspect(SPECIFICATION_PERMISSIONS_DA, L"specification permissions", FALSE, FALSE);
	Log::declare_aspect(SPECIFICATION_USAGE_DA, L"specification usage", FALSE, FALSE);
	Log::declare_aspect(SPECIFICITIES_DA, L"specificities", FALSE, FALSE);
	Log::declare_aspect(TABLES_DA, L"table construction", FALSE, FALSE);
	Log::declare_aspect(TEXT_SUBSTITUTIONS_DA, L"text substitutions", FALSE, FALSE);
	Log::declare_aspect(VARIABLE_CREATIONS_DA, L"variable creations", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('B', Tables::log);
	REGISTER_WRITER('b', Rules::Bookings::log);
	REGISTER_WRITER('C', Tables::Columns::log);
	REGISTER_WRITER('d', ExtensionDictionary::log_entry);
	REGISTER_WRITER('E', Invocations::log_list);
	REGISTER_WRITER('e', Invocations::log);
	REGISTER_WRITER('H', IndexHeadings::log);
	REGISTER_WRITER('h', Phrases::TypeData::Textual::log);
	REGISTER_WRITER('I', World::Inferences::log);
	REGISTER_WRITER('i', Calculus::Schemas::log);
	REGISTER_WRITER('j', InferenceSubjects::log);
	REGISTER_WRITER('K', Rulebooks::log);
	REGISTER_WRITER('k', LocalVariables::log);
	REGISTER_WRITER_I('n', World::Inferences::log_kind)
	REGISTER_WRITER('O', Instances::log);
	REGISTER_WRITER('q', Equations::log);
	REGISTER_WRITER('R', Phrases::log);
	REGISTER_WRITER('U', Phrases::Usage::log);
	REGISTER_WRITER('Y', Properties::log);
	REGISTER_WRITER('Z', NonlocalVariables::log);
	REGISTER_WRITER('z', Nouns::log);

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

@h Built-in relation names.
These have to be defined somewhere, and it may as well be here.

@d EQUALITY_RELATION_NAME 0
@d UNIVERSAL_RELATION_NAME 1
@d MEANING_RELATION_NAME 2
@d PROVISION_RELATION_NAME 3
@d GE_RELATION_NAME 4
@d GT_RELATION_NAME 5
@d LE_RELATION_NAME 6
@d LT_RELATION_NAME 7
@d ADJACENCY_RELATION_NAME 8
@d REGIONAL_CONTAINMENT_RELATION_NAME 9
@d CONTAINMENT_RELATION_NAME 10
@d SUPPORT_RELATION_NAME 11
@d INCORPORATION_RELATION_NAME 12
@d CARRYING_RELATION_NAME 13
@d HOLDING_RELATION_NAME 14
@d WEARING_RELATION_NAME 15
@d POSSESSION_RELATION_NAME 16
@d VISIBILITY_RELATION_NAME 17
@d TOUCHABILITY_RELATION_NAME 18
@d CONCEALMENT_RELATION_NAME 19
@d ENCLOSURE_RELATION_NAME 20
@d ROOM_CONTAINMENT_RELATION_NAME 21

@ These are the English names of the built-in relations. The use of hyphenation
here is a fossil from the times when Inform allowed only single-word relation
names; but it doesn't seem worth changing, especially as the hyphenated
relations are almost never needed for anything. All the same, translators into
other languages may as well drop the hyphens.

=
<relation-names> ::=
	equality |
	universal |
	meaning |
	provision |
	numerically-greater-than-or-equal-to |
	numerically-greater-than |
	numerically-less-than-or-equal-to |
	numerically-less-than |
	adjacency |
	regional-containment |
	containment |
	support |
	incorporation |
	carrying |
	holding |
	wearing |
	possession |
	visibility |
	touchability |
	concealment |
	enclosure |
	room-containment
