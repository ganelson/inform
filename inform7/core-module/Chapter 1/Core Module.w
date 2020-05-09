[CoreModule::] Core Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CORE_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e bibliographic_datum_CLASS
@e phrase_CLASS
@e inference_CLASS
@e property_CLASS
@e property_permission_CLASS
@e rulebook_CLASS
@e booking_CLASS
@e phrase_option_array_CLASS
@e instance_CLASS
@e table_CLASS
@e table_column_CLASS
@e literal_text_CLASS
@e text_substitution_CLASS
@e invocation_array_CLASS
@e implication_CLASS
@e activity_CLASS
@e activity_list_array_CLASS
@e use_option_CLASS
@e i6_memory_setting_CLASS
@e definition_CLASS
@e binary_predicate_CLASS
@e pcalc_prop_array_CLASS
@e pcalc_func_array_CLASS
@e pcalc_prop_deferral_CLASS
@e literal_pattern_CLASS
@e generalisation_CLASS
@e i6_schema_array_CLASS
@e list_together_routine_CLASS
@e past_tense_condition_record_CLASS
@e past_tense_action_record_CLASS
@e named_rulebook_outcome_CLASS
@e stacked_variable_array_CLASS
@e stacked_variable_list_array_CLASS
@e stacked_variable_owner_array_CLASS
@e stacked_variable_owner_list_array_CLASS
@e pointer_allocation_CLASS
@e ph_stack_frame_box_CLASS
@e i6_inclusion_matter_CLASS
@e literal_list_CLASS
@e adjective_meaning_CLASS
@e adjective_meaning_block_CLASS
@e measurement_definition_CLASS
@e literal_pattern_name_CLASS
@e equation_CLASS
@e equation_symbol_CLASS
@e equation_node_CLASS
@e placement_affecting_array_CLASS
@e activity_crossref_array_CLASS
@e invocation_options_array_CLASS
@e inv_token_problem_token_CLASS
@e application_array_CLASS
@e plugin_call_array_CLASS
@e plugin_CLASS
@e nonlocal_variable_CLASS
@e inference_subject_CLASS
@e property_of_value_storage_CLASS
@e to_phrase_request_CLASS
@e constant_phrase_CLASS
@e use_as_event_CLASS
@e instance_usage_array_CLASS
@e rule_CLASS
@e rulebook_outcome_CLASS
@e applicability_condition_CLASS
@e llist_entry_CLASS
@e response_message_CLASS
@e table_contribution_array_CLASS
@e contents_entry_CLASS
@e local_variable_array_CLASS
@e relation_guard_CLASS
@e pcalc_term_array_CLASS
@e special_meaning_holder_CLASS
@e runtime_kind_structure_CLASS
@e internal_test_case_CLASS
@e test_scenario_CLASS
@e counting_data_CLASS
@e kind_interaction_CLASS
@e dval_written_CLASS
@e nascent_array_CLASS
@e value_holster_array_CLASS
@e adjective_iname_holder_CLASS
@e label_namespace_CLASS
@e compile_task_data_CLASS

@ Deep breath, then: the following macros define several hundred functions.

=
DECLARE_CLASS(activity)
DECLARE_CLASS(adjective_meaning)
DECLARE_CLASS(adjective_meaning_block)
DECLARE_CLASS(applicability_condition)
DECLARE_CLASS(binary_predicate)
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
DECLARE_CLASS(special_meaning_holder)
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

@ So much for the managed structures: now for the unmanaged structures.

=
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_crossref, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_list, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(application, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(i6_schema, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(instance_usage, 200)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(invocation_options, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(local_variable, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_func, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_prop, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_term, 1000)
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
COMPILE_WRITER(extension_dictionary_entry *, ExtensionDictionary::log_entry)
COMPILE_WRITER(parse_node *, Invocations::log_list)
COMPILE_WRITER(parse_node *, Invocations::log)
COMPILE_WRITER(heading *, Sentences::Headings::log)
COMPILE_WRITER(ph_type_data *, Phrases::TypeData::Textual::log)
COMPILE_WRITER(inference *, World::Inferences::log)
COMPILE_WRITER(i6_schema *, Calculus::Schemas::log)
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
@e PREDICATE_CALCULUS_DA
@e PREDICATE_CALCULUS_WORKINGS_DA
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
	Log::declare_aspect(PREDICATE_CALCULUS_DA, L"predicate calculus", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_WORKINGS_DA, L"predicate calculus workings", FALSE, FALSE);
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
	REGISTER_WRITER('0', Calculus::Terms::log);
	REGISTER_WRITER('2', BinaryPredicates::log);
	REGISTER_WRITER('B', Tables::log);
	REGISTER_WRITER('b', Rules::Bookings::log);
	REGISTER_WRITER('C', Tables::Columns::log);
	REGISTER_WRITER('D', Calculus::Propositions::log);
	REGISTER_WRITER('d', ExtensionDictionary::log_entry);
	REGISTER_WRITER('E', Invocations::log_list);
	REGISTER_WRITER('e', Invocations::log);
	REGISTER_WRITER('H', Sentences::Headings::log);
	REGISTER_WRITER('h', Phrases::TypeData::Textual::log);
	REGISTER_WRITER('I', World::Inferences::log);
	REGISTER_WRITER('i', Calculus::Schemas::log);
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

@ This module uses |syntax|, and adds the following annotations to the syntax
tree; though it's a little like itemising the baubles on a Christmas tree.

@e action_meaning_ANNOT /* |action_pattern|: meaning in parse tree when used as noun */
@e aph_ANNOT /* |adjectival_phrase|: which adjective is asserted */
@e category_of_I6_translation_ANNOT /* int: what sort of "translates into I6" sentence this is */
@e clears_pronouns_ANNOT /* |int|: this sentence erases the current value of "it" */
@e colon_block_command_ANNOT /* int: this COMMAND uses the ":" not begin/end syntax */
@e condition_tense_ANNOT /* |time_period|: for specification nodes */
@e constant_action_name_ANNOT /* |action_name|: for constant values */
@e constant_action_pattern_ANNOT /* |action_pattern|: for constant values */
@e constant_activity_ANNOT /* |activity|: for constant values */
@e constant_binary_predicate_ANNOT /* |binary_predicate|: for constant values */
@e constant_constant_phrase_ANNOT /* |constant_phrase|: for constant values */
@e constant_enumeration_ANNOT /* |int|: which one from an enumerated kind */
@e constant_equation_ANNOT /* |equation|: for constant values */
@e constant_grammar_verb_ANNOT /* |grammar_verb|: for constant values */
@e constant_instance_ANNOT /* |instance|: for constant values */
@e constant_local_variable_ANNOT /* |local_variable|: for constant values */
@e constant_named_action_pattern_ANNOT /* |named_action_pattern|: for constant values */
@e constant_named_rulebook_outcome_ANNOT /* |named_rulebook_outcome|: for constant values */
@e constant_nonlocal_variable_ANNOT /* |nonlocal_variable|: for constant values */
@e constant_number_ANNOT /* |int|: which integer this is */
@e constant_property_ANNOT /* |property|: for constant values */
@e constant_rule_ANNOT /* |rule|: for constant values */
@e constant_rulebook_ANNOT /* |rulebook|: for constant values */
@e constant_scene_ANNOT /* |scene|: for constant values */
@e constant_table_ANNOT /* |table|: for constant values */
@e constant_table_column_ANNOT /* |table_column|: for constant values */
@e constant_text_ANNOT /* |text_stream|: for constant values */
@e constant_use_option_ANNOT /* |use_option|: for constant values */
@e constant_verb_form_ANNOT /* |verb_form|: for constant values */
@e control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e converted_SN_ANNOT /* |int|: marking descriptions */
@e creation_proposition_ANNOT /* |pcalc_prop|: proposition which newly created value satisfies */
@e creation_site_ANNOT /* |int|: whether an instance was created from this node */
@e defn_language_ANNOT /* |inform_language|: what language this definition is in */
@e end_control_structure_used_ANNOT /* |control_structure_phrase|: for CODE BLOCK nodes only */
@e epistemological_status_ANNOT /* |int|: a bitmap of results from checking an ambiguous reading */
@e evaluation_ANNOT /* |parse_node|: result of evaluating the text */
@e examine_for_ofs_ANNOT /* |int|: mark this as a possible site for removing "of" tree breaks */
@e explicit_iname_ANNOT /* |inter_name|: is this value explicitly an iname? */
@e explicit_literal_ANNOT /* |int|: my value is an explicit integer or text */
@e explicit_vh_ANNOT /* |value_holster|: used for compiling I6-level properties */
@e from_text_substitution_ANNOT /* |int|: whether this is an implicit say invocation */
@e grammar_token_code_ANNOT /* int: used to identify grammar tokens */
@e grammar_token_literal_ANNOT /* int: for grammar tokens which are literal words */
@e grammar_token_relation_ANNOT /* |binary_predicate|: for relation tokens */
@e grammar_value_ANNOT /* |parse_node|: used as a marker when evaluating Understand grammar */
@e imperative_ANNOT /* |int|: marking definitions of imperative verbs */
@e implicit_in_creation_of_ANNOT /* |inference_subject|: for assemblies */
@e implicitness_count_ANNOT /* int: keeping track of recursive assemblies */
@e indentation_level_ANNOT /* |int|: for routines written with Pythonesque indentation */
@e interpretation_of_subject_ANNOT /* |inference_subject|: subject, during passes */
@e is_phrase_option_ANNOT /* |int|: this unparsed text is a phrase option */
@e kind_of_new_variable_ANNOT /* |kind|: what if anything is returned */
@e kind_of_value_ANNOT /* |kind|: for specification nodes */
@e kind_required_by_context_ANNOT /* |kind|: what if anything is expected here */
@e kind_resulting_ANNOT /* |kind|: what if anything is returned */
@e kind_variable_declarations_ANNOT /* |kind_variable_declaration|: and of these */
@e listing_sense_ANNOT /* |int|: are we listing a rule into something, or out of it? */
@e log_inclusion_sense_ANNOT /* |int|: should we include or exclude this from the debugging log? */
@e lpe_options_ANNOT /* |int|: options set for a literal pattern part */
@e modal_verb_ANNOT /* |verb_conjugation|: relevant only for that: e.g., "might" */
@e module_ANNOT /* |compilation_module|: set only for headings, routines and sentences */
@e multiplicity_ANNOT /* |int|: e.g., 5 for "five gold rings" */
@e negated_boolean_ANNOT /* int: set if adjective/verb meant negatively */
@e new_relation_here_ANNOT /* |binary_predicate|: new relation as subject of "relates" sentence */
@e nothing_object_ANNOT /* |int|: this represents |nothing| at run-time */
@e nowhere_ANNOT /* |int|: used by the spatial plugin to show this represents "nowhere" */
@e phrase_invoked_ANNOT /* |phrase|: the phrase believed to be invoked... */
@e phrase_option_ANNOT /* |int|: $2^i$ where $i$ is the option number, $0\leq i<16$ */
@e phrase_options_invoked_ANNOT /* |invocation_options|: details of any options used */
@e property_name_used_as_noun_ANNOT /* |int|: in ambiguous cases such as "open" */
@e proposition_ANNOT /* |pcalc_prop|: for specification nodes */
@e prep_ANNOT /* |preposition_identity|: for e.g. "is on" */
@e quant_ANNOT /* |quantifier|: for quantified excerpts like "three baskets" */
@e quantification_parameter_ANNOT /* |int|: e.g., 3 for "three baskets" */
@e record_as_self_ANNOT /* |int|: record recipient as |self| when writing this */
@e relationship_ANNOT /* |binary_predicate|: for RELATIONSHIP nodes */
@e resolved_ANNOT /* int: temp storage when resolving NPs */
@e response_code_ANNOT /* |int|: for responses only */
@e results_from_splitting_ANNOT /* |int|: node in a routine's parse tree from comma block notation */
@e row_amendable_ANNOT /* int: a candidate row for a table amendment */
@e save_self_ANNOT /* |int|: this invocation must save and preserve |self| at run-time */
@e say_adjective_ANNOT /* |adjectival_phrase|: ...or the adjective to be agreed with by "say" */
@e say_verb_ANNOT /* |verb_conjugation|: ...or the verb to be conjugated by "say" */
@e say_verb_negated_ANNOT /* relevant only for that */
@e self_object_ANNOT /* |int|: this represents |self| at run-time */
@e slash_class_ANNOT /* int: used when partitioning grammar tokens */
@e slash_dash_dash_ANNOT /* |int|: used when partitioning grammar tokens */
@e ssp_closing_segment_wn_ANNOT /* |int|: identifier for the last of these, or |-1| */
@e ssp_segment_count_ANNOT /* |int|: number of subsequent complex-say phrases in stream */
@e subject_ANNOT /* |inference_subject|: what this node describes */
@e subject_term_ANNOT /* |pcalc_term|: what the subject of the subtree was */
@e suppress_newlines_ANNOT /* |int|: whether the next say term runs on */
@e table_cell_unspecified_ANNOT /* int: used to mark table entries as unset */
@e text_unescaped_ANNOT /* |int|: flag used only for literal texts */
@e token_as_parsed_ANNOT /* |parse_node|: what if anything is returned */
@e token_check_to_do_ANNOT /* |parse_node|: what if anything is returned */
@e token_to_be_parsed_against_ANNOT /* |parse_node|: what if anything is returned */
@e turned_already_ANNOT /* |int|: aliasing like "player" to "yourself" performed already */
@e unproven_ANNOT /* |int|: this invocation needs run-time typechecking */
@e verb_id_ANNOT /* int: identifying what kind of VERB node */
@e verb_problem_issued_ANNOT /* |int|: has a problem message about the primary verb been issued already? */
@e vu_ANNOT /* |verb_usage|: for e.g. "does not carry" */
@e you_can_ignore_ANNOT /* |int|: for assertions now drained of meaning */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(aph, adjectival_phrase)
DECLARE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
DECLARE_ANNOTATION_FUNCTIONS(constant_activity, activity)
DECLARE_ANNOTATION_FUNCTIONS(constant_binary_predicate, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(constant_constant_phrase, constant_phrase)
DECLARE_ANNOTATION_FUNCTIONS(constant_equation, equation)
DECLARE_ANNOTATION_FUNCTIONS(constant_instance, instance)
DECLARE_ANNOTATION_FUNCTIONS(constant_local_variable, local_variable)
DECLARE_ANNOTATION_FUNCTIONS(constant_named_rulebook_outcome, named_rulebook_outcome)
DECLARE_ANNOTATION_FUNCTIONS(constant_nonlocal_variable, nonlocal_variable)
DECLARE_ANNOTATION_FUNCTIONS(constant_property, property)
DECLARE_ANNOTATION_FUNCTIONS(constant_rule, rule)
DECLARE_ANNOTATION_FUNCTIONS(constant_rulebook, rulebook)
DECLARE_ANNOTATION_FUNCTIONS(constant_table_column, table_column)
DECLARE_ANNOTATION_FUNCTIONS(constant_table, table)
DECLARE_ANNOTATION_FUNCTIONS(constant_text, text_stream)
DECLARE_ANNOTATION_FUNCTIONS(constant_use_option, use_option)
DECLARE_ANNOTATION_FUNCTIONS(constant_verb_form, verb_form)
DECLARE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
DECLARE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
DECLARE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(explicit_vh, value_holster)
DECLARE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
DECLARE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
DECLARE_ANNOTATION_FUNCTIONS(explicit_iname, inter_name)
DECLARE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(module, compilation_module)
DECLARE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
DECLARE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
DECLARE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
DECLARE_ANNOTATION_FUNCTIONS(prep, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(quant, quantifier)
DECLARE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
DECLARE_ANNOTATION_FUNCTIONS(say_adjective, adjectival_phrase)
DECLARE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
DECLARE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)
DECLARE_ANNOTATION_FUNCTIONS(subject, inference_subject)
DECLARE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)
DECLARE_ANNOTATION_FUNCTIONS(vu, verb_usage)

@ So we itemise the pointer-valued annotations below, and the macro expands
to provide their get and set functions:

=
MAKE_ANNOTATION_FUNCTIONS(aph, adjectival_phrase)
MAKE_ANNOTATION_FUNCTIONS(condition_tense, time_period)
MAKE_ANNOTATION_FUNCTIONS(constant_activity, activity)
MAKE_ANNOTATION_FUNCTIONS(constant_binary_predicate, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(constant_constant_phrase, constant_phrase)
MAKE_ANNOTATION_FUNCTIONS(constant_equation, equation)
MAKE_ANNOTATION_FUNCTIONS(constant_instance, instance)
MAKE_ANNOTATION_FUNCTIONS(constant_local_variable, local_variable)
MAKE_ANNOTATION_FUNCTIONS(constant_named_rulebook_outcome, named_rulebook_outcome)
MAKE_ANNOTATION_FUNCTIONS(constant_nonlocal_variable, nonlocal_variable)
MAKE_ANNOTATION_FUNCTIONS(constant_property, property)
MAKE_ANNOTATION_FUNCTIONS(constant_rule, rule)
MAKE_ANNOTATION_FUNCTIONS(constant_rulebook, rulebook)
MAKE_ANNOTATION_FUNCTIONS(constant_table_column, table_column)
MAKE_ANNOTATION_FUNCTIONS(constant_table, table)
MAKE_ANNOTATION_FUNCTIONS(constant_text, text_stream)
MAKE_ANNOTATION_FUNCTIONS(constant_use_option, use_option)
MAKE_ANNOTATION_FUNCTIONS(constant_verb_form, verb_form)
MAKE_ANNOTATION_FUNCTIONS(control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(creation_proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(defn_language, inform_language)
MAKE_ANNOTATION_FUNCTIONS(end_control_structure_used, control_structure_phrase)
MAKE_ANNOTATION_FUNCTIONS(evaluation, parse_node)
MAKE_ANNOTATION_FUNCTIONS(explicit_vh, value_holster)
MAKE_ANNOTATION_FUNCTIONS(grammar_token_relation, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(grammar_value, parse_node)
MAKE_ANNOTATION_FUNCTIONS(implicit_in_creation_of, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(interpretation_of_subject, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(kind_of_new_variable, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_of_value, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_required_by_context, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_resulting, kind)
MAKE_ANNOTATION_FUNCTIONS(kind_variable_declarations, kind_variable_declaration)
MAKE_ANNOTATION_FUNCTIONS(modal_verb, verb_conjugation)
MAKE_ANNOTATION_FUNCTIONS(new_relation_here, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(phrase_invoked, phrase)
MAKE_ANNOTATION_FUNCTIONS(phrase_options_invoked, invocation_options)
MAKE_ANNOTATION_FUNCTIONS(proposition, pcalc_prop)
MAKE_ANNOTATION_FUNCTIONS(prep, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(quant, quantifier)
MAKE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
MAKE_ANNOTATION_FUNCTIONS(say_adjective, adjectival_phrase)
MAKE_ANNOTATION_FUNCTIONS(say_verb, verb_conjugation)
MAKE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)
MAKE_ANNOTATION_FUNCTIONS(subject, inference_subject)
MAKE_ANNOTATION_FUNCTIONS(token_as_parsed, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_check_to_do, parse_node)
MAKE_ANNOTATION_FUNCTIONS(token_to_be_parsed_against, parse_node)
MAKE_ANNOTATION_FUNCTIONS(vu, verb_usage)
