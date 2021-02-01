Class Predeclarations.

Predeclaring the classes used in the six central Inform modules.

@ For annoying reasons to do with code ordering constraints in C, we need
to declare the classes used by the central Inform modules all at once and
up front, here in //core//. (This enables them to be used as values of
syntax tree annotations.) The central modules can't be independently compiled
of each other or of //core// in any case.

Deep breath, then: the following macros define several hundred functions.
We begin with //core// itself.

@e compile_task_data_CLASS

=
DECLARE_CLASS(compile_task_data)

@ //assertions// --

@e adjective_iname_holder_CLASS
@e adjective_meaning_CLASS
@e application_CLASS
@e by_routine_bp_data_CLASS
@e equivalence_bp_data_CLASS
@e explicit_bp_data_CLASS
@e generalisation_CLASS
@e i6_memory_setting_CLASS
@e implication_CLASS
@e relation_guard_CLASS
@e table_CLASS
@e table_column_CLASS
@e table_contribution_CLASS
@e use_option_CLASS

=
DECLARE_CLASS(adjective_iname_holder)
DECLARE_CLASS(adjective_meaning)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(application, 100)
DECLARE_CLASS(generalisation)
DECLARE_CLASS(by_routine_bp_data)
DECLARE_CLASS(equivalence_bp_data)
DECLARE_CLASS(explicit_bp_data)
DECLARE_CLASS(i6_memory_setting)
DECLARE_CLASS(implication)
DECLARE_CLASS(relation_guard)
DECLARE_CLASS(table)
DECLARE_CLASS(table_column)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(table_contribution, 100)
DECLARE_CLASS(use_option)

@ //values// --

@e equation_CLASS
@e equation_node_CLASS
@e equation_symbol_CLASS
@e instance_CLASS
@e instance_usage_CLASS
@e inv_token_problem_token_CLASS
@e literal_list_CLASS
@e literal_pattern_CLASS
@e literal_pattern_name_CLASS
@e literal_text_CLASS
@e llist_entry_CLASS
@e nonlocal_variable_CLASS
@e response_message_CLASS
@e text_substitution_CLASS

=
DECLARE_CLASS(equation)
DECLARE_CLASS(equation_node)
DECLARE_CLASS(equation_symbol)
DECLARE_CLASS(instance)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(instance_usage, 200)
DECLARE_CLASS(inv_token_problem_token)
DECLARE_CLASS(literal_list)
DECLARE_CLASS(literal_pattern)
DECLARE_CLASS(literal_pattern_name)
DECLARE_CLASS(literal_text)
DECLARE_CLASS(llist_entry)
DECLARE_CLASS(nonlocal_variable)
DECLARE_CLASS(response_message)
DECLARE_CLASS(text_substitution)

@ //knowledge// --

@e activity_CLASS
@e activity_crossref_CLASS
@e activity_list_CLASS
@e applicability_condition_CLASS
@e booking_CLASS
@e comparative_bp_data_CLASS
@e counting_data_CLASS
@e inference_CLASS
@e inference_subject_CLASS
@e measurement_definition_CLASS
@e named_rulebook_outcome_CLASS
@e placement_affecting_CLASS
@e property_CLASS
@e property_permission_CLASS
@e property_of_value_storage_CLASS
@e property_setting_bp_data_CLASS
@e rule_CLASS
@e rulebook_CLASS
@e rulebook_outcome_CLASS
@e stacked_variable_CLASS
@e stacked_variable_list_CLASS
@e stacked_variable_owner_CLASS
@e stacked_variable_owner_list_CLASS

=
DECLARE_CLASS(activity)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_crossref, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(activity_list, 1000)
DECLARE_CLASS(applicability_condition)
DECLARE_CLASS(booking)
DECLARE_CLASS(comparative_bp_data)
DECLARE_CLASS(counting_data)
DECLARE_CLASS(inference)
DECLARE_CLASS(inference_subject)
DECLARE_CLASS(measurement_definition)
DECLARE_CLASS(named_rulebook_outcome)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(placement_affecting, 100)
DECLARE_CLASS(property_of_value_storage)
DECLARE_CLASS(property_permission)
DECLARE_CLASS(property)
DECLARE_CLASS(property_setting_bp_data)
DECLARE_CLASS(rule)
DECLARE_CLASS(rulebook)
DECLARE_CLASS(rulebook_outcome)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_list, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_owner, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(stacked_variable_owner_list, 100)

@ //imperative// --

@e constant_phrase_CLASS
@e invocation_options_CLASS
@e local_variable_CLASS
@e past_tense_action_record_CLASS
@e past_tense_condition_record_CLASS
@e pcalc_prop_deferral_CLASS
@e ph_stack_frame_box_CLASS
@e phrase_CLASS
@e phrase_option_CLASS
@e pointer_allocation_CLASS
@e to_phrase_request_CLASS
@e use_as_event_CLASS

=
DECLARE_CLASS(constant_phrase)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(invocation_options, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(local_variable, 100)
DECLARE_CLASS(past_tense_action_record)
DECLARE_CLASS(past_tense_condition_record)
DECLARE_CLASS(pcalc_prop_deferral)
DECLARE_CLASS(ph_stack_frame_box)
DECLARE_CLASS(phrase)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(phrase_option, 100)
DECLARE_CLASS(pointer_allocation)
DECLARE_CLASS(to_phrase_request)
DECLARE_CLASS(use_as_event)

@ //runtime// --

@e bp_runtime_implementation_CLASS
@e definition_CLASS
@e dval_written_CLASS
@e i6_inclusion_matter_CLASS
@e internal_test_case_CLASS
@e kind_interaction_CLASS
@e label_namespace_CLASS
@e list_together_routine_CLASS
@e nascent_array_CLASS
@e plugin_CLASS
@e plugin_call_CLASS
@e runtime_kind_structure_CLASS
@e test_scenario_CLASS

=
DECLARE_CLASS(bp_runtime_implementation)
DECLARE_CLASS(definition)
DECLARE_CLASS(dval_written)
DECLARE_CLASS(i6_inclusion_matter)
DECLARE_CLASS(internal_test_case)
DECLARE_CLASS(kind_interaction)
DECLARE_CLASS(label_namespace)
DECLARE_CLASS(list_together_routine)
DECLARE_CLASS(nascent_array)
DECLARE_CLASS(plugin)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(plugin_call, 100)
DECLARE_CLASS(runtime_kind_structure)
DECLARE_CLASS(test_scenario)

@ And finally //index// --

@e contents_entry_CLASS
@e documentation_ref_CLASS
@e index_page_CLASS
@e index_element_CLASS
@e index_lexicon_entry_CLASS

=
DECLARE_CLASS(contents_entry)
DECLARE_CLASS(documentation_ref)
DECLARE_CLASS(index_element)
DECLARE_CLASS(index_page)
DECLARE_CLASS(index_lexicon_entry)
