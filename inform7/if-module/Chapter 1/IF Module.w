[IFModule::] IF Module.

Setting up the use of this module.

@h Predeclarations.

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(action_meaning, action_pattern)
DECLARE_ANNOTATION_FUNCTIONS(constant_action_name, action_name)
DECLARE_ANNOTATION_FUNCTIONS(constant_action_pattern, action_pattern)
DECLARE_ANNOTATION_FUNCTIONS(constant_grammar_verb, grammar_verb)
DECLARE_ANNOTATION_FUNCTIONS(constant_named_action_pattern, named_action_pattern)
DECLARE_ANNOTATION_FUNCTIONS(constant_scene, scene)

@h Introduction.

@d IF_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e action_name_MT
@e auxiliary_file_MT
@e backdrop_found_in_notice_MT
@e cached_understanding_MT
@e command_index_entry_MT
@e connected_submap_MT
@e door_dir_notice_MT
@e door_to_notice_MT
@e EPS_map_level_MT
@e grammar_line_MT
@e grammar_verb_MT
@e loop_over_scope_MT
@e map_data_MT
@e named_action_pattern_MT
@e noun_filter_token_MT
@e parse_name_notice_MT
@e parsing_data_MT
@e parsing_pp_data_MT
@e regions_data_MT
@e reserved_command_verb_MT
@e rubric_holder_MT
@e scene_MT
@e short_name_notice_MT
@e slash_gpr_MT
@e spatial_data_MT

@e action_name_list_array_MT
@e action_pattern_array_MT
@e ap_optional_clause_array_MT
@e scene_connector_array_MT
@e understanding_item_array_MT
@e understanding_reference_array_MT

=
ALLOCATE_INDIVIDUALLY(action_name)
ALLOCATE_INDIVIDUALLY(auxiliary_file)
ALLOCATE_INDIVIDUALLY(backdrop_found_in_notice)
ALLOCATE_INDIVIDUALLY(cached_understanding)
ALLOCATE_INDIVIDUALLY(command_index_entry)
ALLOCATE_INDIVIDUALLY(connected_submap)
ALLOCATE_INDIVIDUALLY(door_dir_notice)
ALLOCATE_INDIVIDUALLY(door_to_notice)
ALLOCATE_INDIVIDUALLY(EPS_map_level)
ALLOCATE_INDIVIDUALLY(grammar_line)
ALLOCATE_INDIVIDUALLY(grammar_verb)
ALLOCATE_INDIVIDUALLY(loop_over_scope)
ALLOCATE_INDIVIDUALLY(map_data)
ALLOCATE_INDIVIDUALLY(named_action_pattern)
ALLOCATE_INDIVIDUALLY(noun_filter_token)
ALLOCATE_INDIVIDUALLY(parse_name_notice)
ALLOCATE_INDIVIDUALLY(parsing_data)
ALLOCATE_INDIVIDUALLY(parsing_pp_data)
ALLOCATE_INDIVIDUALLY(regions_data)
ALLOCATE_INDIVIDUALLY(reserved_command_verb)
ALLOCATE_INDIVIDUALLY(rubric_holder)
ALLOCATE_INDIVIDUALLY(scene)
ALLOCATE_INDIVIDUALLY(short_name_notice)
ALLOCATE_INDIVIDUALLY(slash_gpr)
ALLOCATE_INDIVIDUALLY(spatial_data)

ALLOCATE_IN_ARRAYS(action_name_list, 1000)
ALLOCATE_IN_ARRAYS(action_pattern, 100)
ALLOCATE_IN_ARRAYS(ap_optional_clause, 400)
ALLOCATE_IN_ARRAYS(scene_connector, 1000)
ALLOCATE_IN_ARRAYS(understanding_item, 100)
ALLOCATE_IN_ARRAYS(understanding_reference, 100)

MAKE_ANNOTATION_FUNCTIONS(action_meaning, action_pattern)
MAKE_ANNOTATION_FUNCTIONS(constant_action_name, action_name)
MAKE_ANNOTATION_FUNCTIONS(constant_action_pattern, action_pattern)
MAKE_ANNOTATION_FUNCTIONS(constant_grammar_verb, grammar_verb)
MAKE_ANNOTATION_FUNCTIONS(constant_named_action_pattern, named_action_pattern)
MAKE_ANNOTATION_FUNCTIONS(constant_scene, scene)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
COMPILE_WRITER(action_pattern *, PL::Actions::Patterns::log)
COMPILE_WRITER(grammar_verb *, PL::Parsing::Verbs::log)
COMPILE_WRITER(grammar_line *, PL::Parsing::Lines::log)
COMPILE_WRITER(action_name_list *, PL::Actions::Lists::log)
COMPILE_WRITER(action_name *, PL::Actions::log)

void IFModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	REGISTER_WRITER('A', PL::Actions::Patterns::log);
	REGISTER_WRITER('G', PL::Parsing::Verbs::log);
	REGISTER_WRITER('g', PL::Parsing::Lines::log);
	REGISTER_WRITER('L', PL::Actions::Lists::log);
	REGISTER_WRITER('l', PL::Actions::log);

@<Register this module's command line switches@> =
	;

@h The end.

=
void IFModule::end(void) {
}
