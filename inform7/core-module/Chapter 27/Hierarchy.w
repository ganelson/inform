[Hierarchy::] Hierarchy.

@

@e BASICS_SUBMODULE from 0
@e ACTIONS_SUBMODULE
@e ACTIVITIES_SUBMODULE
@e ADJECTIVES_SUBMODULE
@e BIBLIOGRAPHIC_SUBMODULE
@e CHRONOLOGY_SUBMODULE
@e CONJUGATIONS_SUBMODULE
@e EQUATIONS_SUBMODULE
@e EXTENSIONS_SUBMODULE
@e EXTERNAL_FILES_SUBMODULE
@e GRAMMAR_SUBMODULE
@e IF_SUBMODULE
@e INSTANCES_SUBMODULE
@e KINDS_SUBMODULE
@e LISTING_SUBMODULE
@e PHRASES_SUBMODULE
@e PROPERTIES_SUBMODULE
@e RELATIONS_SUBMODULE
@e RULEBOOKS_SUBMODULE
@e RULES_SUBMODULE
@e TABLES_SUBMODULE
@e VARIABLES_SUBMODULE

@e MAX_SUBMODULE

=
text_stream *Hierarchy::submodule_name(int spid) {
	text_stream *N = NULL;
	switch (spid) {
		case BASICS_SUBMODULE: N = I"basics"; break;
		case ACTIONS_SUBMODULE: N = I"actions"; break;
		case ACTIVITIES_SUBMODULE: N = I"activities"; break;
		case ADJECTIVES_SUBMODULE: N = I"adjectives"; break;
		case BIBLIOGRAPHIC_SUBMODULE: N = I"bibliographic"; break;
		case CHRONOLOGY_SUBMODULE: N = I"chronology"; break;
		case CONJUGATIONS_SUBMODULE: N = I"conjugations"; break;
		case EQUATIONS_SUBMODULE: N = I"equations"; break;
		case EXTENSIONS_SUBMODULE: N = I"extensions"; break;
		case EXTERNAL_FILES_SUBMODULE: N = I"external_files"; break;
		case GRAMMAR_SUBMODULE: N = I"grammar"; break;
		case IF_SUBMODULE: N = I"interactive_fiction"; break;
		case INSTANCES_SUBMODULE: N = I"instances"; break;
		case KINDS_SUBMODULE: N = I"kinds"; break;
		case LISTING_SUBMODULE: N = I"listing"; break;
		case PHRASES_SUBMODULE: N = I"phrases"; break;
		case PROPERTIES_SUBMODULE: N = I"properties"; break;
		case RELATIONS_SUBMODULE: N = I"relations"; break;
		case RULEBOOKS_SUBMODULE: N = I"rulebooks"; break;
		case RULES_SUBMODULE: N = I"rules"; break;
		case TABLES_SUBMODULE: N = I"tables"; break;
		case VARIABLES_SUBMODULE: N = I"variables"; break;
		default: internal_error("nameless resource");
	}
	return N;
}

@

@e BLOCK_CONSTANT_PR_COUNTER from 0
@e BLOCK_PR_COUNTER
@e FORM_PR_COUNTER
@e INLINE_PR_COUNTER
@e LITERAL_PR_COUNTER
@e MISC_PR_COUNTER
@e PROPOSITION_PR_COUNTER
@e SUBSTITUTION_PR_COUNTER
@e SUBSTITUTIONF_PR_COUNTER
@e TASK_PR_COUNTER

=
void Hierarchy::establish(void) {
	Packaging::register_counter(I"block_constant");
	Packaging::register_counter(I"code_block");
	Packaging::register_counter(I"form");
	Packaging::register_counter(I"inline_pval");
	Packaging::register_counter(I"literal");
	Packaging::register_counter(I"misc_const");
	Packaging::register_counter(I"proposition");
	Packaging::register_counter(I"ts");
	Packaging::register_counter(I"ts_fn");
	Packaging::register_counter(I"task");

	@<Establish basics@>;
	@<Establish actions@>;
	@<Establish activities@>;
	@<Establish adjectives@>;
	@<Establish bibliographic@>;
	@<Establish chronology@>;
	@<Establish conjugations@>;
	@<Establish equations@>;
	@<Establish extensions@>;
	@<Establish external files@>;
	@<Establish grammar@>;
	@<Establish instances@>;
	@<Establish int-fiction@>;
	@<Establish kinds@>;
	@<Establish listing@>;
	@<Establish phrases@>;
	@<Establish properties@>;
	@<Establish relations@>;
	@<Establish rulebooks@>;
	@<Establish rules@>;
	@<Establish tables@>;
	@<Establish variables@>;
	@<The rest@>;
	
	@<Establish template resources@>;
}

@h Basics.

@e THESAME_HL from 0
@e PLURALFOUND_HL
@e PARENT_HL
@e CHILD_HL
@e SIBLING_HL
@e SELF_HL
@e THEDARK_HL
@e DEBUG_HL
@e TARGET_ZCODE_HL
@e TARGET_GLULX_HL
@e DICT_WORD_SIZE_HL
@e WORDSIZE_HL
@e NULL_HL
@e WORD_HIGHBIT_HL
@e WORD_NEXTTOHIGHBIT_HL
@e IMPROBABLE_VALUE_HL
@e REPARSE_CODE_HL
@e MAX_POSITIVE_NUMBER_HL
@e MIN_NEGATIVE_NUMBER_HL
@e FLOAT_NAN_HL
@e RESPONSETEXTS_HL
@e CAP_SHORT_NAME_EXISTS_HL
@e NI_BUILD_COUNT_HL
@e RANKING_TABLE_HL
@e PLUGIN_FILES_HL
@e MAX_WEAK_ID_HL
@e NO_VERB_VERB_DEFINED_HL
@e NO_TEST_SCENARIOS_HL
@e MEMORY_HEAP_SIZE_HL

@e CCOUNT_QUOTATIONS_HL
@e MAX_FRAME_SIZE_NEEDED_HL
@e RNG_SEED_AT_START_OF_PLAY_HL

@<Establish basics@> =
	package_request *generic_basics = Packaging::generic_resource(BASICS_SUBMODULE);
	HierarchyLocations::make(THESAME_HL, I"##TheSame", generic_basics);
	HierarchyLocations::make(PLURALFOUND_HL, I"##PluralFound", generic_basics);
	HierarchyLocations::make(PARENT_HL, I"parent", generic_basics);
	HierarchyLocations::make(CHILD_HL, I"child", generic_basics);
	HierarchyLocations::make(SIBLING_HL, I"sibling", generic_basics);
	HierarchyLocations::make(SELF_HL, I"self", generic_basics);
	HierarchyLocations::make(THEDARK_HL, I"thedark", generic_basics);
	HierarchyLocations::make(RESPONSETEXTS_HL, I"ResponseTexts", generic_basics);
	HierarchyLocations::make(DEBUG_HL, I"DEBUG", generic_basics);
	HierarchyLocations::make(TARGET_ZCODE_HL, I"TARGET_ZCODE", generic_basics);
	HierarchyLocations::make(TARGET_GLULX_HL, I"TARGET_GLULX", generic_basics);
	HierarchyLocations::make(DICT_WORD_SIZE_HL, I"DICT_WORD_SIZE", generic_basics);
	HierarchyLocations::make(WORDSIZE_HL, I"WORDSIZE", generic_basics);
	HierarchyLocations::make(NULL_HL, I"NULL", generic_basics);
	HierarchyLocations::make(WORD_HIGHBIT_HL, I"WORD_HIGHBIT", generic_basics);
	HierarchyLocations::make(WORD_NEXTTOHIGHBIT_HL, I"WORD_NEXTTOHIGHBIT", generic_basics);
	HierarchyLocations::make(IMPROBABLE_VALUE_HL, I"IMPROBABLE_VALUE", generic_basics);
	HierarchyLocations::make(REPARSE_CODE_HL, I"REPARSE_CODE", generic_basics);
	HierarchyLocations::make(MAX_POSITIVE_NUMBER_HL, I"MAX_POSITIVE_NUMBER", generic_basics);
	HierarchyLocations::make(MIN_NEGATIVE_NUMBER_HL, I"MIN_NEGATIVE_NUMBER", generic_basics);
	HierarchyLocations::make(FLOAT_NAN_HL, I"FLOAT_NAN", generic_basics);
	HierarchyLocations::make(CAP_SHORT_NAME_EXISTS_HL, I"CAP_SHORT_NAME_EXISTS", generic_basics);
	HierarchyLocations::make(NI_BUILD_COUNT_HL, I"NI_BUILD_COUNT", generic_basics);
	HierarchyLocations::make(RANKING_TABLE_HL, I"RANKING_TABLE", generic_basics);
	HierarchyLocations::make(PLUGIN_FILES_HL, I"PLUGIN_FILES", generic_basics);
	HierarchyLocations::make(MAX_WEAK_ID_HL, I"MAX_WEAK_ID", generic_basics);
	HierarchyLocations::make(NO_VERB_VERB_DEFINED_HL, I"NO_VERB_VERB_DEFINED", generic_basics);
	HierarchyLocations::make(NO_TEST_SCENARIOS_HL, I"NO_TEST_SCENARIOS", generic_basics);
	HierarchyLocations::make(MEMORY_HEAP_SIZE_HL, I"MEMORY_HEAP_SIZE", generic_basics);

	package_request *synoptic_basics = Packaging::synoptic_resource(BASICS_SUBMODULE);
	HierarchyLocations::make(CCOUNT_QUOTATIONS_HL, I"CCOUNT_QUOTATIONS", synoptic_basics);
	HierarchyLocations::make(MAX_FRAME_SIZE_NEEDED_HL, I"MAX_FRAME_SIZE_NEEDED", synoptic_basics);
	HierarchyLocations::make(RNG_SEED_AT_START_OF_PLAY_HL, I"RNG_SEED_AT_START_OF_PLAY", synoptic_basics);

@h Actions.

@e MISTAKEACTION_HL

@e ACTIONS_HAP
@e CHECK_RB_HL
@e CARRY_OUT_RB_HL
@e REPORT_RB_HL

@e ACTIONCODING_HL
@e ACTIONDATA_HL
@e ACTIONHAPPENED_HL
@e AD_RECORDS_HL
@e CCOUNT_ACTION_NAME_HL
@e DB_ACTION_DETAILS_HL
@e MISTAKEACTIONSUB_HL

@<Establish actions@> =
	package_request *generic_actions = Packaging::generic_resource(ACTIONS_SUBMODULE);
	HierarchyLocations::make(MISTAKEACTION_HL, I"##MistakeAction", generic_actions);

	inter_symbol *action_ptype = Packaging::register_ptype(I"_action", TRUE);
	HierarchyLocations::ap(ACTIONS_HAP, ACTIONS_SUBMODULE, I"action", action_ptype);
		HierarchyLocations::make_rulebook_within(CHECK_RB_HL, I"check_rb", action_ptype);
		HierarchyLocations::make_rulebook_within(CARRY_OUT_RB_HL, I"carry_out_rb", action_ptype);
		HierarchyLocations::make_rulebook_within(REPORT_RB_HL, I"report_rb", action_ptype);

	package_request *synoptic_actions = Packaging::synoptic_resource(ACTIONS_SUBMODULE);
	HierarchyLocations::make(ACTIONCODING_HL, I"ActionCoding", synoptic_actions);
	HierarchyLocations::make(ACTIONDATA_HL, I"ActionData", synoptic_actions);
	HierarchyLocations::make(ACTIONHAPPENED_HL, I"ActionHappened", synoptic_actions);
	HierarchyLocations::make(AD_RECORDS_HL, I"AD_RECORDS", synoptic_actions);
	HierarchyLocations::make(CCOUNT_ACTION_NAME_HL, I"CCOUNT_ACTION_NAME", synoptic_actions);
	HierarchyLocations::make_function(DB_ACTION_DETAILS_HL, I"DB_Action_Details_fn", I"DB_Action_Details", synoptic_actions);
	HierarchyLocations::make_function(MISTAKEACTIONSUB_HL, I"MistakeActionSub_fn", I"MistakeActionSub", synoptic_actions);

@h Activities.

@e ACTIVITIES_HAP
@e BEFORE_RB_HL
@e FOR_RB_HL
@e AFTER_RB_HL

@e ACTIVITY_AFTER_RULEBOOKS_HL
@e ACTIVITY_ATB_RULEBOOKS_HL
@e ACTIVITY_BEFORE_RULEBOOKS_HL
@e ACTIVITY_FOR_RULEBOOKS_HL
@e ACTIVITY_VAR_CREATORS_HL

@<Establish activities@> =
	inter_symbol *activity_ptype = Packaging::register_ptype(I"_activity", TRUE);
	HierarchyLocations::ap(ACTIVITIES_HAP, ACTIVITIES_SUBMODULE, I"activity", activity_ptype);
		HierarchyLocations::make_rulebook_within(BEFORE_RB_HL, I"before_rb", activity_ptype);
		HierarchyLocations::make_rulebook_within(FOR_RB_HL, I"for_rb", activity_ptype);
		HierarchyLocations::make_rulebook_within(AFTER_RB_HL, I"after_rb", activity_ptype);

	package_request *synoptic_activities = Packaging::synoptic_resource(ACTIVITIES_SUBMODULE);
	HierarchyLocations::make(ACTIVITY_AFTER_RULEBOOKS_HL, I"Activity_after_rulebooks", synoptic_activities);
	HierarchyLocations::make(ACTIVITY_ATB_RULEBOOKS_HL, I"Activity_atb_rulebooks", synoptic_activities);
	HierarchyLocations::make(ACTIVITY_BEFORE_RULEBOOKS_HL, I"Activity_before_rulebooks", synoptic_activities);
	HierarchyLocations::make(ACTIVITY_FOR_RULEBOOKS_HL, I"Activity_for_rulebooks", synoptic_activities);
	HierarchyLocations::make(ACTIVITY_VAR_CREATORS_HL, I"activity_var_creators", synoptic_activities);

@h Adjectives.

@e ADJECTIVES_HAP
@e ADJECTIVE_MEANINGS_HAP
@e ADJECTIVE_PHRASES_HAP

@<Establish adjectives@> =
	inter_symbol *adjective_ptype = Packaging::register_ptype(I"_adjective", TRUE);
	HierarchyLocations::ap(ADJECTIVES_HAP, ADJECTIVES_SUBMODULE, I"adjective", adjective_ptype);
	inter_symbol *adjective_meaning_ptype = Packaging::register_ptype(I"_adjective_meaning", TRUE);
	HierarchyLocations::ap(ADJECTIVE_MEANINGS_HAP, ADJECTIVES_SUBMODULE, I"adjective_meaning", adjective_meaning_ptype);
	inter_symbol *adjective_phrase_ptype = Packaging::register_ptype(I"_adjective_phrase", TRUE);
	HierarchyLocations::ap(ADJECTIVE_PHRASES_HAP, ADJECTIVES_SUBMODULE, I"adjective_phrase", adjective_phrase_ptype);

@h Bibliographic.

@e UUID_ARRAY_HL
@e STORY_HL
@e HEADLINE_HL
@e STORY_AUTHOR_HL
@e RELEASE_HL
@e SERIAL_HL

@<Establish bibliographic@> =
	package_request *synoptic_biblio = Packaging::synoptic_resource(BIBLIOGRAPHIC_SUBMODULE);
	HierarchyLocations::make(UUID_ARRAY_HL, I"UUID_ARRAY", synoptic_biblio);
	HierarchyLocations::make_datum(STORY_HL, I"Story_datum", I"Story", synoptic_biblio);
	HierarchyLocations::make_datum(HEADLINE_HL, I"Headline_datum", I"Headline", synoptic_biblio);
	HierarchyLocations::make_datum(STORY_AUTHOR_HL, I"Story_Author_datum", I"Story_Author", synoptic_biblio);
	HierarchyLocations::make_datum(RELEASE_HL, I"Release_datum", I"Release", synoptic_biblio);
	HierarchyLocations::make_datum(SERIAL_HL, I"Serial_datum", I"Serial", synoptic_biblio);

@h Chronology.

@e PAST_ACTION_PATTERNS_HAP

@e TIMEDEVENTSTABLE_HL
@e TIMEDEVENTTIMESTABLE_HL
@e PASTACTIONSI6ROUTINES_HL
@e NO_PAST_TENSE_CONDS_HL
@e NO_PAST_TENSE_ACTIONS_HL
@e TESTSINGLEPASTSTATE_HL

@<Establish chronology@> =
	inter_symbol *past_action_pattern_ptype = Packaging::register_ptype(I"_past_action_pattern", TRUE);
	HierarchyLocations::ap(PAST_ACTION_PATTERNS_HAP, CHRONOLOGY_SUBMODULE, I"past_action_pattern", past_action_pattern_ptype);

	package_request *synoptic_chronology = Packaging::synoptic_resource(CHRONOLOGY_SUBMODULE);
	HierarchyLocations::make(TIMEDEVENTSTABLE_HL, I"TimedEventsTable", synoptic_chronology);
	HierarchyLocations::make(TIMEDEVENTTIMESTABLE_HL, I"TimedEventTimesTable", synoptic_chronology);
	HierarchyLocations::make(PASTACTIONSI6ROUTINES_HL, I"PastActionsI6Routines", synoptic_chronology);
	HierarchyLocations::make(NO_PAST_TENSE_CONDS_HL, I"NO_PAST_TENSE_CONDS", synoptic_chronology);
	HierarchyLocations::make(NO_PAST_TENSE_ACTIONS_HL, I"NO_PAST_TENSE_ACTIONS", synoptic_chronology);
	HierarchyLocations::make_function(TESTSINGLEPASTSTATE_HL, I"test_fn", I"TestSinglePastState", synoptic_chronology);

@h Conjugations.

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@e MVERBS_HAP
@e VERBS_HAP

@<Establish conjugations@> =
	package_request *generic_conjugations = Packaging::generic_resource(CONJUGATIONS_SUBMODULE);
	HierarchyLocations::make(CV_MEANING_HL, I"CV_MEANING", generic_conjugations);
	HierarchyLocations::make(CV_MODAL_HL, I"CV_MODAL", generic_conjugations);
	HierarchyLocations::make(CV_NEG_HL, I"CV_NEG", generic_conjugations);
	HierarchyLocations::make(CV_POS_HL, I"CV_POS", generic_conjugations);

	inter_symbol *mverb_ptype = Packaging::register_ptype(I"_modal_verb", TRUE);
	HierarchyLocations::ap(MVERBS_HAP, CONJUGATIONS_SUBMODULE, I"mverb", mverb_ptype);
	inter_symbol *verb_ptype = Packaging::register_ptype(I"_verb", TRUE);
	HierarchyLocations::ap(VERBS_HAP, CONJUGATIONS_SUBMODULE, I"verb", verb_ptype);

@h Equations.

@e EQUATIONS_HAP

@<Establish equations@> =
	inter_symbol *equation_ptype = Packaging::register_ptype(I"_equation", TRUE);
	HierarchyLocations::ap(EQUATIONS_HAP, EQUATIONS_SUBMODULE, I"equation", equation_ptype);
	
@h Extensions.

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish extensions@> =
	package_request *synoptic_extensions = Packaging::synoptic_resource(EXTENSIONS_SUBMODULE);
	HierarchyLocations::make_function(SHOWEXTENSIONVERSIONS_HL, I"showextensionversions_fn", I"ShowExtensionVersions", synoptic_extensions);
	HierarchyLocations::make_function(SHOWFULLEXTENSIONVERSIONS_HL, I"showfullextensionversions_fn", I"ShowFullExtensionVersions", synoptic_extensions);
	HierarchyLocations::make_function(SHOWONEEXTENSION_HL, I"showoneextension_fn", I"ShowOneExtension", synoptic_extensions);

@h External files.

@e EXTERNAL_FILES_HAP

@<Establish external files@> =
	inter_symbol *external_file_ptype = Packaging::register_ptype(I"_external_file", TRUE);
	HierarchyLocations::ap(EXTERNAL_FILES_HAP, EXTERNAL_FILES_SUBMODULE, I"external_file", external_file_ptype);

@h Grammar.

@e COND_TOKENS_HAP
@e CONSULT_TOKENS_HAP
@e TESTS_HAP
@e LOOP_OVER_SCOPES_HAP
@e MISTAKES_HAP
@e NAMED_ACTION_PATTERNS_HAP
@e NAMED_TOKENS_HAP
@e NOUN_FILTERS_HAP
@e PARSE_NAMES_HAP
@e SCOPE_FILTERS_HAP
@e SLASH_TOKENS_HAP

@e VERB_DIRECTIVE_CREATURE_HL
@e VERB_DIRECTIVE_DIVIDER_HL
@e VERB_DIRECTIVE_HELD_HL
@e VERB_DIRECTIVE_MULTI_HL
@e VERB_DIRECTIVE_MULTIEXCEPT_HL
@e VERB_DIRECTIVE_MULTIHELD_HL
@e VERB_DIRECTIVE_MULTIINSIDE_HL
@e VERB_DIRECTIVE_NOUN_HL
@e VERB_DIRECTIVE_NUMBER_HL
@e VERB_DIRECTIVE_RESULT_HL
@e VERB_DIRECTIVE_REVERSE_HL
@e VERB_DIRECTIVE_SLASH_HL
@e VERB_DIRECTIVE_SPECIAL_HL
@e VERB_DIRECTIVE_TOPIC_HL
@e TESTSCRIPTSUB_HL
@e INTERNALTESTCASES_HL
@e COMMAND_PR_COUNTER
@e COMMANDS_HAP

@<Establish grammar@> =
	inter_symbol *cond_ptype = Packaging::register_ptype(I"_conditional_token", TRUE);
	HierarchyLocations::ap(COND_TOKENS_HAP, GRAMMAR_SUBMODULE, I"conditional_token", cond_ptype);
	inter_symbol *consult_ptype = Packaging::register_ptype(I"_consult_token", TRUE);
	HierarchyLocations::ap(CONSULT_TOKENS_HAP, GRAMMAR_SUBMODULE, I"consult_token", consult_ptype);
	inter_symbol *test_ptype = Packaging::register_ptype(I"_test", TRUE);
	HierarchyLocations::ap(TESTS_HAP, GRAMMAR_SUBMODULE, I"test", test_ptype);
	inter_symbol *los_ptype = Packaging::register_ptype(I"_loop_over_scope", TRUE);
	HierarchyLocations::ap(LOOP_OVER_SCOPES_HAP, GRAMMAR_SUBMODULE, I"loop_over_scope", los_ptype);
	inter_symbol *m_ptype = Packaging::register_ptype(I"_mistake", TRUE);
	HierarchyLocations::ap(MISTAKES_HAP, GRAMMAR_SUBMODULE, I"mistake", m_ptype);
	inter_symbol *nap_ptype = Packaging::register_ptype(I"_named_action_pattern", TRUE);
	HierarchyLocations::ap(NAMED_ACTION_PATTERNS_HAP, GRAMMAR_SUBMODULE, I"named_action_pattern", nap_ptype);
	inter_symbol *nt_ptype = Packaging::register_ptype(I"_named_token", TRUE);
	HierarchyLocations::ap(NAMED_TOKENS_HAP, GRAMMAR_SUBMODULE, I"named_token", nt_ptype);
	inter_symbol *nf_ptype = Packaging::register_ptype(I"_noun_filter", TRUE);
	HierarchyLocations::ap(NOUN_FILTERS_HAP, GRAMMAR_SUBMODULE, I"noun_filter", nf_ptype);
	inter_symbol *sf_ptype = Packaging::register_ptype(I"_scope_filter", TRUE);
	HierarchyLocations::ap(SCOPE_FILTERS_HAP, GRAMMAR_SUBMODULE, I"scope_filter", sf_ptype);
	inter_symbol *pn_ptype = Packaging::register_ptype(I"_parse_name", TRUE);
	HierarchyLocations::ap(PARSE_NAMES_HAP, GRAMMAR_SUBMODULE, I"parse_name", pn_ptype);
	inter_symbol *slash_ptype = Packaging::register_ptype(I"_slash_token", TRUE);
	HierarchyLocations::ap(SLASH_TOKENS_HAP, GRAMMAR_SUBMODULE, I"slash_token", slash_ptype);

	package_request *synoptic_grammar = Packaging::synoptic_resource(GRAMMAR_SUBMODULE);
	HierarchyLocations::make(VERB_DIRECTIVE_CREATURE_HL, I"VERB_DIRECTIVE_CREATURE", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_DIVIDER_HL, I"VERB_DIRECTIVE_DIVIDER", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_HELD_HL, I"VERB_DIRECTIVE_HELD", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_MULTI_HL, I"VERB_DIRECTIVE_MULTI", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_MULTIEXCEPT_HL, I"VERB_DIRECTIVE_MULTIEXCEPT", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_MULTIHELD_HL, I"VERB_DIRECTIVE_MULTIHELD", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_MULTIINSIDE_HL, I"VERB_DIRECTIVE_MULTIINSIDE", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_NOUN_HL, I"VERB_DIRECTIVE_NOUN", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_NUMBER_HL, I"VERB_DIRECTIVE_NUMBER", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_RESULT_HL, I"VERB_DIRECTIVE_RESULT", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_REVERSE_HL, I"VERB_DIRECTIVE_REVERSE", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_SLASH_HL, I"VERB_DIRECTIVE_SLASH", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_SPECIAL_HL, I"VERB_DIRECTIVE_SPECIAL", synoptic_grammar);
	HierarchyLocations::make(VERB_DIRECTIVE_TOPIC_HL, I"VERB_DIRECTIVE_TOPIC", synoptic_grammar);
	HierarchyLocations::make_function(TESTSCRIPTSUB_HL, I"action_fn", I"TestScriptSub", synoptic_grammar);
	HierarchyLocations::make_function(INTERNALTESTCASES_HL, I"run_tests_fn", I"InternalTestCases", synoptic_grammar);
	inter_symbol *command_ptype = Packaging::register_ptype(I"_command", TRUE);
	HierarchyLocations::synoptic_ap(COMMANDS_HAP, GRAMMAR_SUBMODULE, I"command", command_ptype);

@h Instances.

@e INSTANCES_HAP

@<Establish instances@> =
	inter_symbol *instance_ptype = Packaging::register_ptype(I"_instance", TRUE);
	HierarchyLocations::ap(INSTANCES_HAP, INSTANCES_SUBMODULE, I"instance", instance_ptype);

@h Interactive Fiction.

@e DEFAULT_SCORING_SETTING_HL
@e INITIAL_MAX_SCORE_HL
@e NO_DIRECTIONS_HL
@e SHOWSCENESTATUS_HL
@e DETECTSCENECHANGE_HL
@e MAP_STORAGE_HL
@e INITIALSITUATION_HL
@e PLAYER_OBJECT_INIS_HL
@e START_OBJECT_INIS_HL
@e START_ROOM_INIS_HL
@e START_TIME_INIS_HL
@e DONE_INIS_HL

@<Establish int-fiction@> =
	package_request *synoptic_IF = Packaging::synoptic_resource(IF_SUBMODULE);
	HierarchyLocations::make(DEFAULT_SCORING_SETTING_HL, I"DEFAULT_SCORING_SETTING", synoptic_IF);
	HierarchyLocations::make(INITIAL_MAX_SCORE_HL, I"INITIAL_MAX_SCORE", synoptic_IF);
	HierarchyLocations::make(NO_DIRECTIONS_HL, I"No_Directions", synoptic_IF);
	HierarchyLocations::make_function(SHOWSCENESTATUS_HL, I"show_scene_status_fn", I"ShowSceneStatus", synoptic_IF);
	HierarchyLocations::make_function(DETECTSCENECHANGE_HL, I"detect_scene_change_fn", I"DetectSceneChange", synoptic_IF);
	HierarchyLocations::make(MAP_STORAGE_HL, I"Map_Storage", synoptic_IF);
	HierarchyLocations::make(INITIALSITUATION_HL, I"InitialSituation", synoptic_IF);
	HierarchyLocations::make(PLAYER_OBJECT_INIS_HL, I"PLAYER_OBJECT_INIS", synoptic_IF);
	HierarchyLocations::make(START_OBJECT_INIS_HL, I"START_OBJECT_INIS", synoptic_IF);
	HierarchyLocations::make(START_ROOM_INIS_HL, I"START_ROOM_INIS", synoptic_IF);
	HierarchyLocations::make(START_TIME_INIS_HL, I"START_TIME_INIS", synoptic_IF);
	HierarchyLocations::make(DONE_INIS_HL, I"DONE_INIS", synoptic_IF);

@h Kinds.

@e UNKNOWN_TY_HL
@e K_UNCHECKED_HL
@e K_UNCHECKED_FUNCTION_HL
@e K_TYPELESS_INT_HL
@e K_TYPELESS_STRING_HL

@e KIND_HAP

@e DEFAULTVALUEOFKOV_HL
@e DEFAULTVALUEFINDER_HL
@e PRINTKINDVALUEPAIR_HL
@e KOVCOMPARISONFUNCTION_HL
@e KOVDOMAINSIZE_HL
@e KOVISBLOCKVALUE_HL
@e I7_KIND_NAME_HL
@e KOVSUPPORTFUNCTION_HL
@e SHOWMEDETAILS_HL
@e BASE_KIND_HWM_HL

@<Establish kinds@> =
	package_request *generic_kinds = Packaging::generic_resource(KINDS_SUBMODULE);
	HierarchyLocations::make(UNKNOWN_TY_HL, I"UNKNOWN_TY", generic_kinds);
	HierarchyLocations::make(K_UNCHECKED_HL, I"K_unchecked", generic_kinds);
	HierarchyLocations::make(K_UNCHECKED_FUNCTION_HL, I"K_unchecked_function", generic_kinds);
	HierarchyLocations::make(K_TYPELESS_INT_HL, I"K_typeless_int", generic_kinds);
	HierarchyLocations::make(K_TYPELESS_STRING_HL, I"K_typeless_string", generic_kinds);

	inter_symbol *kind_ptype = Packaging::register_ptype(I"_kind", TRUE);
	HierarchyLocations::ap(KIND_HAP, KINDS_SUBMODULE, I"kind", kind_ptype);

	package_request *synoptic_kinds = Packaging::synoptic_resource(KINDS_SUBMODULE);
	HierarchyLocations::make(BASE_KIND_HWM_HL, I"BASE_KIND_HWM", synoptic_kinds);
	HierarchyLocations::make_function(DEFAULTVALUEOFKOV_HL, I"defaultvalue_fn", I"DefaultValueOfKOV", synoptic_kinds);
	HierarchyLocations::make_function(DEFAULTVALUEFINDER_HL, I"defaultvaluefinder_fn", I"DefaultValueFinder", synoptic_kinds);
	HierarchyLocations::make_function(PRINTKINDVALUEPAIR_HL, I"printkindvaluepair_fn", I"PrintKindValuePair", synoptic_kinds);
	HierarchyLocations::make_function(KOVCOMPARISONFUNCTION_HL, I"comparison_fn", I"KOVComparisonFunction", synoptic_kinds);
	HierarchyLocations::make_function(KOVDOMAINSIZE_HL, I"domainsize_fn", I"KOVDomainSize", synoptic_kinds);
	HierarchyLocations::make_function(KOVISBLOCKVALUE_HL, I"blockvalue_fn", I"KOVIsBlockValue", synoptic_kinds);
	HierarchyLocations::make_function(I7_KIND_NAME_HL, I"printkindname_fn", I"I7_Kind_Name", synoptic_kinds);
	HierarchyLocations::make_function(KOVSUPPORTFUNCTION_HL, I"support_fn", I"KOVSupportFunction", synoptic_kinds);
	HierarchyLocations::make_function(SHOWMEDETAILS_HL, I"showmedetails_fn", I"ShowMeDetails", synoptic_kinds);

@h Listing.

@e LISTS_TOGETHER_HAP

@<Establish listing@> =
	inter_symbol *list_together_ptype = Packaging::register_ptype(I"_list_together", TRUE);
	HierarchyLocations::ap(LISTS_TOGETHER_HAP, LISTING_SUBMODULE, I"list_together", list_together_ptype);

@h Phrases.

@e CLOSURES_HAP
@e PHRASES_HAP
@e REQUESTS_HAP
@e LABEL_STORAGES_HAP

@<Establish phrases@> =
	inter_symbol *to_phrase_ptype = Packaging::register_ptype(I"_phrase", TRUE);
	HierarchyLocations::ap(PHRASES_HAP, PHRASES_SUBMODULE, I"phrase", to_phrase_ptype);
		inter_symbol *closure_ptype = Packaging::register_ptype(I"_closure", TRUE);
		HierarchyLocations::ap_within(CLOSURES_HAP, to_phrase_ptype, I"closure", closure_ptype);
		inter_symbol *request_ptype = Packaging::register_ptype(I"_request", TRUE);
		HierarchyLocations::ap_within(REQUESTS_HAP, to_phrase_ptype, I"request", request_ptype);

	inter_symbol *label_storage_ptype = Packaging::register_ptype(I"_label_storage", TRUE);
	HierarchyLocations::synoptic_ap(LABEL_STORAGES_HAP, PHRASES_SUBMODULE, I"label_associated_storage", label_storage_ptype);

@h Properties.

@e PROPERTIES_HAP

@e CCOUNT_PROPERTY_HL

@<Establish properties@> =
	inter_symbol *property_ptype = Packaging::register_ptype(I"_property", TRUE);
	HierarchyLocations::ap(PROPERTIES_HAP, PROPERTIES_SUBMODULE, I"property", property_ptype);

	package_request *synoptic_props = Packaging::synoptic_resource(PROPERTIES_SUBMODULE);
	HierarchyLocations::make(CCOUNT_PROPERTY_HL, I"CCOUNT_PROPERTY", synoptic_props);

@h Relations.

@e RELS_ASSERT_FALSE_HL
@e RELS_ASSERT_TRUE_HL
@e RELS_EQUIVALENCE_HL
@e RELS_LIST_HL
@e RELS_LOOKUP_ALL_X_HL
@e RELS_LOOKUP_ALL_Y_HL
@e RELS_LOOKUP_ANY_HL
@e RELS_ROUTE_FIND_COUNT_HL
@e RELS_ROUTE_FIND_HL
@e RELS_SHOW_HL
@e RELS_SYMMETRIC_HL
@e RELS_TEST_HL
@e RELS_X_UNIQUE_HL
@e RELS_Y_UNIQUE_HL
@e REL_BLOCK_HEADER_HL
@e TTF_SUM_HL
@e MEANINGLESS_RR_HL

@e RELATIONS_HAP

@e CREATEDYNAMICRELATIONS_HL
@e CCOUNT_BINARY_PREDICATE_HL
@e ITERATERELATIONS_HL
@e RPROPERTY_HL

@<Establish relations@> =
	package_request *generic_rels = Packaging::generic_resource(RELATIONS_SUBMODULE);
	HierarchyLocations::make(RELS_ASSERT_FALSE_HL, I"RELS_ASSERT_FALSE", generic_rels);
	HierarchyLocations::make(RELS_ASSERT_TRUE_HL, I"RELS_ASSERT_TRUE", generic_rels);
	HierarchyLocations::make(RELS_EQUIVALENCE_HL, I"RELS_EQUIVALENCE", generic_rels);
	HierarchyLocations::make(RELS_LIST_HL, I"RELS_LIST", generic_rels);
	HierarchyLocations::make(RELS_LOOKUP_ALL_X_HL, I"RELS_LOOKUP_ALL_X", generic_rels);
	HierarchyLocations::make(RELS_LOOKUP_ALL_Y_HL, I"RELS_LOOKUP_ALL_Y", generic_rels);
	HierarchyLocations::make(RELS_LOOKUP_ANY_HL, I"RELS_LOOKUP_ANY", generic_rels);
	HierarchyLocations::make(RELS_ROUTE_FIND_COUNT_HL, I"RELS_ROUTE_FIND_COUNT", generic_rels);
	HierarchyLocations::make(RELS_ROUTE_FIND_HL, I"RELS_ROUTE_FIND", generic_rels);
	HierarchyLocations::make(RELS_SHOW_HL, I"RELS_SHOW", generic_rels);
	HierarchyLocations::make(RELS_SYMMETRIC_HL, I"RELS_SYMMETRIC", generic_rels);
	HierarchyLocations::make(RELS_TEST_HL, I"RELS_TEST", generic_rels);
	HierarchyLocations::make(RELS_X_UNIQUE_HL, I"RELS_X_UNIQUE", generic_rels);
	HierarchyLocations::make(RELS_Y_UNIQUE_HL, I"RELS_Y_UNIQUE", generic_rels);
	HierarchyLocations::make(REL_BLOCK_HEADER_HL, I"REL_BLOCK_HEADER", generic_rels);
	HierarchyLocations::make(TTF_SUM_HL, I"TTF_sum", generic_rels);
	HierarchyLocations::make(MEANINGLESS_RR_HL, I"MEANINGLESS_RR", generic_rels);

	inter_symbol *relation_ptype = Packaging::register_ptype(I"_relation", TRUE);
	HierarchyLocations::ap(RELATIONS_HAP, RELATIONS_SUBMODULE, I"relation", relation_ptype);

	package_request *synoptic_rels = Packaging::synoptic_resource(RELATIONS_SUBMODULE);
	HierarchyLocations::make_function(CREATEDYNAMICRELATIONS_HL, I"creator_fn", I"CreateDynamicRelations", synoptic_rels);
	HierarchyLocations::make(CCOUNT_BINARY_PREDICATE_HL, I"CCOUNT_BINARY_PREDICATE", synoptic_rels);
	HierarchyLocations::make_function(ITERATERELATIONS_HL, I"iterator_fn", I"IterateRelations", synoptic_rels);
	HierarchyLocations::make_function(RPROPERTY_HL, I"property_fn", I"RProperty", synoptic_rels);

@h Rulebooks.

@e EMPTY_RULEBOOK_INAME_HL

@e OUTCOMES_HAP
@e RULEBOOKS_HAP

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish rulebooks@> =
	package_request *generic_rulebooks = Packaging::generic_resource(RULEBOOKS_SUBMODULE);
	HierarchyLocations::make_function(EMPTY_RULEBOOK_INAME_HL, I"empty_fn", I"EMPTY_RULEBOOK", generic_rulebooks);

	inter_symbol *outcome_ptype = Packaging::register_ptype(I"_outcome", TRUE);
	HierarchyLocations::ap(OUTCOMES_HAP, RULEBOOKS_SUBMODULE, I"rulebook_outcome", outcome_ptype);
	inter_symbol *rulebook_ptype = Packaging::register_ptype(I"_rulebook", TRUE);
	HierarchyLocations::ap(RULEBOOKS_HAP, RULEBOOKS_SUBMODULE, I"rulebook", rulebook_ptype);

	package_request *synoptic_rulebooks = Packaging::synoptic_resource(RULEBOOKS_SUBMODULE);
	HierarchyLocations::make(NUMBER_RULEBOOKS_CREATED_HL, I"NUMBER_RULEBOOKS_CREATED", synoptic_rulebooks);
	HierarchyLocations::make(RULEBOOK_VAR_CREATORS_HL, I"rulebook_var_creators", synoptic_rulebooks);
	HierarchyLocations::make_function(SLOW_LOOKUP_HL, I"slow_lookup_fn", I"MStack_GetRBVarCreator", synoptic_rulebooks);
	HierarchyLocations::make(RULEBOOKS_ARRAY_HL, I"rulebooks_array", synoptic_rulebooks);
	HierarchyLocations::make(RULEBOOKNAMES_HL, I"RulebookNames", synoptic_rulebooks);

@h Rules.

@e RULES_HAP
@e RESPONSES_HAP

@e RULEPRINTINGRULE_HL
@e RESPONSEDIVISIONS_HL

@<Establish rules@> =
	inter_symbol *rule_ptype = Packaging::register_ptype(I"_rule", TRUE);
	HierarchyLocations::ap(RULES_HAP, RULES_SUBMODULE, I"rule", rule_ptype);
		inter_symbol *response_ptype = Packaging::register_ptype(I"_response", TRUE);
		HierarchyLocations::ap_within(RESPONSES_HAP, rule_ptype, I"response", response_ptype);

	package_request *synoptic_rules = Packaging::synoptic_resource(RULES_SUBMODULE);
	HierarchyLocations::make(RESPONSEDIVISIONS_HL, I"ResponseDivisions", synoptic_rules);
	HierarchyLocations::make_function(RULEPRINTINGRULE_HL, I"print_fn", I"RulePrintingRule", synoptic_rules);

@h Tables.

@e TABLES_HAP
@e TABLE_COLUMNS_HAP

@e TC_KOV_HL
@e TB_BLANKS_HL

@<Establish tables@> =
	inter_symbol *table_ptype = Packaging::register_ptype(I"_table", TRUE);
	HierarchyLocations::ap(TABLES_HAP, TABLES_SUBMODULE, I"table", table_ptype);
		inter_symbol *table_column_ptype = Packaging::register_ptype(I"_table_column", TRUE);
		HierarchyLocations::ap_within(TABLE_COLUMNS_HAP, table_ptype, I"table_column", table_column_ptype);

	package_request *synoptic_tables = Packaging::synoptic_resource(TABLES_SUBMODULE);
	HierarchyLocations::make(TB_BLANKS_HL, I"TB_Blanks", synoptic_tables);
	HierarchyLocations::make_function(TC_KOV_HL, I"weak_kind_ID_of_column_entry_fn", I"TC_KOV", synoptic_tables);

@h Variables.

@e VARIABLES_HAP

@<Establish variables@> =
	inter_symbol *variable_ptype = Packaging::register_ptype(I"_variable", TRUE);
	HierarchyLocations::ap(VARIABLES_HAP, VARIABLES_SUBMODULE, I"variable", variable_ptype);

@

@e K_OBJECT_XPACKAGE from 0
@e K_NUMBER_XPACKAGE
@e K_TIME_XPACKAGE
@e K_TRUTH_STATE_XPACKAGE
@e K_TABLE_XPACKAGE
@e K_VERB_XPACKAGE
@e K_FIGURE_NAME_XPACKAGE
@e K_SOUND_NAME_XPACKAGE
@e K_USE_OPTION_XPACKAGE
@e V_COMMAND_PROMPT_XPACKAGE

@e NOTHING_HL
@e OBJECT_HL
@e TESTUSEOPTION_HL
@e TABLEOFTABLES_HL
@e TABLEOFVERBS_HL
@e CAPSHORTNAME_HL
@e COMMANDPROMPTTEXT_HL
@e DECIMAL_TOKEN_INNER_HL
@e NO_USE_OPTIONS_HL
@e RESOURCEIDSOFFIGURES_HL
@e RESOURCEIDSOFSOUNDS_HL
@e TIME_TOKEN_INNER_HL
@e TRUTH_STATE_TOKEN_INNER_HL

@

@<The rest@> =
	HierarchyLocations::make_in_exotic(OBJECT_HL, I"Object", K_OBJECT_XPACKAGE);
	HierarchyLocations::make_in_exotic(NOTHING_HL, I"nothing", K_OBJECT_XPACKAGE);
	HierarchyLocations::make_in_exotic(CAPSHORTNAME_HL, I"cap_short_name", K_OBJECT_XPACKAGE);

	HierarchyLocations::make_function_in_exotic(DECIMAL_TOKEN_INNER_HL, I"gpr_fn", I"DECIMAL_TOKEN_INNER", K_NUMBER_XPACKAGE);

	HierarchyLocations::make_function_in_exotic(TIME_TOKEN_INNER_HL, I"gpr_fn", I"TIME_TOKEN_INNER", K_TIME_XPACKAGE);

	HierarchyLocations::make_function_in_exotic(TRUTH_STATE_TOKEN_INNER_HL, I"gpr_fn", I"TRUTH_STATE_TOKEN_INNER", K_TRUTH_STATE_XPACKAGE);

	HierarchyLocations::make_in_exotic(TABLEOFTABLES_HL, I"TableOfTables", K_TABLE_XPACKAGE);

	HierarchyLocations::make_in_exotic(TABLEOFVERBS_HL, I"TableOfVerbs", K_VERB_XPACKAGE);

	HierarchyLocations::make_in_exotic(RESOURCEIDSOFFIGURES_HL, I"ResourceIDsOfFigures", K_FIGURE_NAME_XPACKAGE);

	HierarchyLocations::make_in_exotic(RESOURCEIDSOFSOUNDS_HL, I"ResourceIDsOfSounds", K_SOUND_NAME_XPACKAGE);

	HierarchyLocations::make_in_exotic(NO_USE_OPTIONS_HL, I"NO_USE_OPTIONS", K_USE_OPTION_XPACKAGE);
	HierarchyLocations::make_function_in_exotic(TESTUSEOPTION_HL, I"test_fn", I"TestUseOption", K_USE_OPTION_XPACKAGE);

	HierarchyLocations::make_function_in_exotic(COMMANDPROMPTTEXT_HL, I"command_prompt_text_fn", I"CommandPromptText", V_COMMAND_PROMPT_XPACKAGE);

@

@e ACT_REQUESTER_HL
@e ACTION_HL
@e ACTIONCURRENTLYHAPPENINGFLAG_HL
@e ACTOR_HL
@e ACTOR_LOCATION_HL
@e ADJUSTPARAGRAPHPOINT_HL
@e ALLOWINSHOWME_HL
@e ANIMATE_HL
@e ARGUMENTTYPEFAILED_HL
@e ARTICLEDESCRIPTORS_HL
@e AUXF_MAGIC_VALUE_HL
@e AUXF_STATUS_IS_CLOSED_HL
@e BLKVALUECOPY_HL
@e BLKVALUECOPYAZ_HL
@e BLKVALUECREATE_HL
@e BLKVALUECREATEONSTACK_HL
@e BLKVALUEERROR_HL
@e BLKVALUEFREE_HL
@e BLKVALUEFREEONSTACK_HL
@e BLKVALUEWRITE_HL
@e C_STYLE_HL
@e CHECKKINDRETURNED_HL
@e CLEARPARAGRAPHING_HL
@e COMPONENT_CHILD_HL
@e COMPONENT_PARENT_HL
@e COMPONENT_SIBLING_HL
@e CONSTANT_PACKED_TEXT_STORAGE_HL
@e CONSTANT_PERISHABLE_TEXT_STORAGE_HL
@e CONSULT_FROM_HL
@e CONSULT_WORDS_HL
@e CONTAINER_HL
@e CUBEROOT_HL
@e DA_NAME_HL
@e DB_RULE_HL
@e DEADFLAG_HL
@e DEBUG_RULES_HL
@e DEBUG_SCENES_HL
@e DECIMALNUMBER_HL
@e DEFERRED_CALLING_LIST_HL
@e DETECTPLURALWORD_HL
@e DIGITTOVALUE_HL
@e DIVIDEPARAGRAPHPOINT_HL
@e DOUBLEHASHSETRELATIONHANDLER_HL
@e DURINGSCENEMATCHING_HL
@e ELEMENTARY_TT_HL
@e EMPTY_TABLE_HL
@e EMPTY_TEXT_PACKED_HL
@e EMPTY_TEXT_VALUE_HL
@e EMPTYRELATIONHANDLER_HL
@e ENGLISH_BIT_HL
@e ETYPE_HL
@e EXISTSTABLELOOKUPCORR_HL
@e EXISTSTABLELOOKUPENTRY_HL
@e EXISTSTABLEROWCORR_HL
@e FLOATPARSE_HL
@e FOLLOWRULEBOOK_HL
@e formal_par0_HL
@e formal_par1_HL
@e formal_par2_HL
@e formal_par3_HL
@e formal_par4_HL
@e formal_par5_HL
@e formal_par6_HL
@e formal_par7_HL
@e FORMAL_RV_HL
@e FOUND_EVERYWHERE_HL
@e GENERATERANDOMNUMBER_HL
@e GENERICVERBSUB_HL
@e GETGNAOFOBJECT_HL
@e GPR_FAIL_HL
@e GPR_NUMBER_HL
@e GPR_PREPOSITION_HL
@e GPR_TT_HL
@e GPROPERTY_HL
@e HASHLISTRELATIONHANDLER_HL
@e I7SFRAME_HL
@e INDENT_BIT_HL
@e INP1_HL
@e INP2_HL
@e INTEGERDIVIDE_HL
@e INTEGERREMAINDER_HL
@e INVENTORY_STAGE_HL
@e KEEP_SILENT_HL
@e KINDATOMIC_HL
@e LATEST_RULE_RESULT_HL
@e LIST_ITEM_BASE_HL
@e LIST_ITEM_KOV_F_HL
@e LIST_OF_TY_DESC_HL
@e LIST_OF_TY_GETITEM_HL
@e LIST_OF_TY_GETLENGTH_HL
@e LIST_OF_TY_INSERTITEM_HL
@e LIST_OF_TY_SAY_HL
@e LIST_OF_TY_SETLENGTH_HL
@e LOCALPARKING_HL
@e LOCATION_HL
@e LOCATIONOF_HL
@e LOOPOVERSCOPE_HL
@e LOS_RV_HL
@e MSTACK_HL
@e MSTVO_HL
@e MSTVON_HL
@e NAME_HL
@e NEWLINE_BIT_HL
@e NEXTBEST_ETYPE_HL
@e NEXTWORDSTOPPED_HL
@e NOARTICLE_BIT_HL
@e NOTINCONTEXTPE_HL
@e NOUN_HL
@e NUMBER_TY_ABS_HL
@e NUMBER_TY_TO_REAL_NUMBER_TY_HL
@e NUMBER_TY_TO_TIME_TY_HL
@e OTOVRELROUTETO_HL
@e PACKED_TEXT_STORAGE_HL
@e PARACONTENT_HL
@e PARAMETER_VALUE_HL
@e PARSED_NUMBER_HL
@e PARSER_ACTION_HL
@e PARSER_ONE_HL
@e PARSER_TRACE_HL
@e PARSER_TWO_HL
@e PARSERERROR_HL
@e PARSETOKENSTOPPED_HL
@e PAST_CHRONOLOGICAL_RECORD_HL
@e PLACEINSCOPE_HL
@e PLAYER_HL
@e PNTOVP_HL
@e PRESENT_CHRONOLOGICAL_RECORD_HL
@e PRINTORRUN_HL
@e PRIOR_NAMED_LIST_HL
@e PRIOR_NAMED_LIST_GENDER_HL
@e PRIOR_NAMED_NOUN_HL
@e PROPERTY_LOOP_SIGN_HL
@e PROPERTY_TO_BE_TOTALLED_HL
@e REAL_LOCATION_HL
@e REAL_NUMBER_TY_ABS_HL
@e REAL_NUMBER_TY_APPROXIMATE_HL
@e REAL_NUMBER_TY_COMPARE_HL
@e REAL_NUMBER_TY_CUBE_ROOT_HL
@e REAL_NUMBER_TY_DIVIDE_HL
@e REAL_NUMBER_TY_MINUS_HL
@e REAL_NUMBER_TY_NAN_HL
@e REAL_NUMBER_TY_NEGATE_HL
@e REAL_NUMBER_TY_PLUS_HL
@e REAL_NUMBER_TY_POW_HL
@e REAL_NUMBER_TY_REMAINDER_HL
@e REAL_NUMBER_TY_ROOT_HL
@e REAL_NUMBER_TY_SAY_HL
@e REAL_NUMBER_TY_TIMES_HL
@e REAL_NUMBER_TY_TO_NUMBER_TY_HL
@e REASON_THE_ACTION_FAILED_HL
@e RELATION_EMPTYEQUIV_HL
@e RELATION_EMPTYOTOO_HL
@e RELATION_EMPTYVTOV_HL
@e RELATION_RSHOWOTOO_HL
@e RELATION_SHOWEQUIV_HL
@e RELATION_SHOWOTOO_HL
@e RELATION_SHOWVTOV_HL
@e RELATION_TY_EQUIVALENCEADJECTIVE_HL
@e RELATION_TY_NAME_HL
@e RELATION_TY_OTOOADJECTIVE_HL
@e RELATION_TY_OTOVADJECTIVE_HL
@e RELATION_TY_SYMMETRICADJECTIVE_HL
@e RELATION_TY_VTOOADJECTIVE_HL
@e RELATIONTEST_HL
@e RELFOLLOWVECTOR_HL
@e RELS_EMPTY_HL
@e RESPONSEVIAACTIVITY_HL
@e RLANY_CAN_GET_X_HL
@e RLANY_CAN_GET_Y_HL
@e RLANY_GET_X_HL
@e RLIST_ALL_X_HL
@e RLIST_ALL_Y_HL
@e RLNGETF_HL
@e ROUNDOFFTIME_HL
@e ROUTINEFILTER_TT_HL
@e RR_STORAGE_HL
@e RTP_RELKINDVIOLATION_HL
@e RTP_RELMINIMAL_HL
@e RULEBOOKFAILS_HL
@e RULEBOOKPARBREAK_HL
@e RULEBOOKSUCCEEDS_HL
@e RUNTIMEPROBLEM_HL
@e SAY__N_HL
@e SAY__P_HL
@e SAY__PC_HL
@e SCENE_ENDED_HL
@e SCENE_ENDINGS_HL
@e SCENE_LATEST_ENDING_HL
@e SCENE_STARTED_HL
@e SCENE_STATUS_HL
@e SCOPE_STAGE_HL
@e SCOPE_TT_HL
@e SECOND_HL
@e SHORT_NAME_HL
@e SIGNEDCOMPARE_HL
@e SPECIAL_WORD_HL
@e SQUAREROOT_HL
@e STACKFRAMECREATE_HL
@e STORED_ACTION_TY_CURRENT_HL
@e STORED_ACTION_TY_TRY_HL
@e STORY_TENSE_HL
@e SUPPORTER_HL
@e SUPPRESS_SCOPE_LOOPS_HL
@e SUPPRESS_TEXT_SUBSTITUTION_HL
@e TABLE_NOVALUE_HL
@e TABLELOOKUPCORR_HL
@e TABLELOOKUPENTRY_HL
@e TESTACTIONBITMAP_HL
@e TESTACTIVITY_HL
@e TESTREGIONALCONTAINMENT_HL
@e TESTSCOPE_HL
@e TESTSTART_HL
@e TEXT_TY_COMPARE_HL
@e TEXT_TY_EXPANDIFPERISHABLE_HL
@e TEXT_TY_SAY_HL
@e THE_TIME_HL
@e THEEMPTYTABLE_HL
@e THEN1__WD_HL
@e TIMESACTIONHASBEENHAPPENING_HL
@e TIMESACTIONHASHAPPENED_HL
@e TRYACTION_HL
@e TRYGIVENOBJECT_HL
@e TURNSACTIONHASBEENHAPPENING_HL
@e UNDERSTAND_AS_MISTAKE_NUMBER_HL
@e UNICODE_TEMP_HL
@e VTOORELROUTETO_HL
@e VTOVRELROUTETO_HL
@e WHEN_SCENE_BEGINS_HL
@e WHEN_SCENE_ENDS_HL
@e WN_HL
@e WORDADDRESS_HL
@e WORDINPROPERTY_HL
@e WORDLENGTH_HL

@<Establish template resources@> =
	package_request *template = Hierarchy::template();	
	HierarchyLocations::make(ACT_REQUESTER_HL, I"act_requester", template);
	HierarchyLocations::make(ACTION_HL, I"action", template);
	HierarchyLocations::make(ACTIONCURRENTLYHAPPENINGFLAG_HL, I"ActionCurrentlyHappeningFlag", template);
	HierarchyLocations::make(ACTOR_HL, I"actor", template);
	HierarchyLocations::make(ACTOR_LOCATION_HL, I"actor_location", template);
	HierarchyLocations::make(ADJUSTPARAGRAPHPOINT_HL, I"AdjustParagraphPoint", template);
	HierarchyLocations::make(ALLOWINSHOWME_HL, I"AllowInShowme", template);
	HierarchyLocations::make(ANIMATE_HL, I"animate", template);
	HierarchyLocations::make(ARGUMENTTYPEFAILED_HL, I"ArgumentTypeFailed", template);
	HierarchyLocations::make(ARTICLEDESCRIPTORS_HL, I"ArticleDescriptors", template);
	HierarchyLocations::make(AUXF_MAGIC_VALUE_HL, I"AUXF_MAGIC_VALUE", template);
	HierarchyLocations::make(AUXF_STATUS_IS_CLOSED_HL, I"AUXF_STATUS_IS_CLOSED", template);
	HierarchyLocations::make(BLKVALUECOPY_HL, I"BlkValueCopy", template);
	HierarchyLocations::make(BLKVALUECOPYAZ_HL, I"BlkValueCopyAZ", template);
	HierarchyLocations::make(BLKVALUECREATE_HL, I"BlkValueCreate", template);
	HierarchyLocations::make(BLKVALUECREATEONSTACK_HL, I"BlkValueCreateOnStack", template);
	HierarchyLocations::make(BLKVALUEERROR_HL, I"BlkValueError", template);
	HierarchyLocations::make(BLKVALUEFREE_HL, I"BlkValueFree", template);
	HierarchyLocations::make(BLKVALUEFREEONSTACK_HL, I"BlkValueFreeOnStack", template);
	HierarchyLocations::make(BLKVALUEWRITE_HL, I"BlkValueWrite", template);
	HierarchyLocations::make(C_STYLE_HL, I"c_style", template);
	HierarchyLocations::make(CHECKKINDRETURNED_HL, I"CheckKindReturned", template);
	HierarchyLocations::make(CLEARPARAGRAPHING_HL, I"ClearParagraphing", template);
	HierarchyLocations::make(COMPONENT_CHILD_HL, I"component_child", template);
	HierarchyLocations::make(COMPONENT_PARENT_HL, I"component_parent", template);
	HierarchyLocations::make(COMPONENT_SIBLING_HL, I"component_sibling", template);
	HierarchyLocations::make(CONSTANT_PACKED_TEXT_STORAGE_HL, I"CONSTANT_PACKED_TEXT_STORAGE", template);
	HierarchyLocations::make(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE", template);
	HierarchyLocations::make(CONSULT_FROM_HL, I"consult_from", template);
	HierarchyLocations::make(CONSULT_WORDS_HL, I"consult_words", template);
	HierarchyLocations::make(CONTAINER_HL, I"container", template);
	HierarchyLocations::make(CUBEROOT_HL, I"CubeRoot", template);
	HierarchyLocations::make(DA_NAME_HL, I"DA_Name", template);
	HierarchyLocations::make(DB_RULE_HL, I"DB_Rule", template);
	HierarchyLocations::make(DEADFLAG_HL, I"deadflag", template);
	HierarchyLocations::make(DEBUG_RULES_HL, I"debug_rules", template);
	HierarchyLocations::make(DEBUG_SCENES_HL, I"debug_scenes", template);
	HierarchyLocations::make(DECIMALNUMBER_HL, I"DecimalNumber", template);
	HierarchyLocations::make(DEFERRED_CALLING_LIST_HL, I"deferred_calling_list", template);
	HierarchyLocations::make(DETECTPLURALWORD_HL, I"DetectPluralWord", template);
	HierarchyLocations::make(DIGITTOVALUE_HL, I"DigitToValue", template);
	HierarchyLocations::make(DIVIDEPARAGRAPHPOINT_HL, I"DivideParagraphPoint", template);
	HierarchyLocations::make(DOUBLEHASHSETRELATIONHANDLER_HL, I"DoubleHashSetRelationHandler", template);
	HierarchyLocations::make(DURINGSCENEMATCHING_HL, I"DuringSceneMatching", template);
	HierarchyLocations::make(ELEMENTARY_TT_HL, I"ELEMENTARY_TT", template);
	HierarchyLocations::make(EMPTY_TABLE_HL, I"TheEmptyTable", template);
	HierarchyLocations::make(EMPTY_TEXT_PACKED_HL, I"EMPTY_TEXT_PACKED", template);
	HierarchyLocations::make(EMPTY_TEXT_VALUE_HL, I"EMPTY_TEXT_VALUE", template);
	HierarchyLocations::make(EMPTYRELATIONHANDLER_HL, I"EmptyRelationHandler", template);
	HierarchyLocations::make(ENGLISH_BIT_HL, I"ENGLISH_BIT", template);
	HierarchyLocations::make(ETYPE_HL, I"etype", template);
	HierarchyLocations::make(EXISTSTABLELOOKUPCORR_HL, I"ExistsTableLookUpCorr", template);
	HierarchyLocations::make(EXISTSTABLELOOKUPENTRY_HL, I"ExistsTableLookUpEntry", template);
	HierarchyLocations::make(EXISTSTABLEROWCORR_HL, I"ExistsTableRowCorr", template);
	HierarchyLocations::make(FLOATPARSE_HL, I"FloatParse", template);
	HierarchyLocations::make(FOLLOWRULEBOOK_HL, I"FollowRulebook", template);
	HierarchyLocations::make(formal_par0_HL, I"formal_par0", template);
	HierarchyLocations::make(formal_par1_HL, I"formal_par1", template);
	HierarchyLocations::make(formal_par2_HL, I"formal_par2", template);
	HierarchyLocations::make(formal_par3_HL, I"formal_par3", template);
	HierarchyLocations::make(formal_par4_HL, I"formal_par4", template);
	HierarchyLocations::make(formal_par5_HL, I"formal_par5", template);
	HierarchyLocations::make(formal_par6_HL, I"formal_par6", template);
	HierarchyLocations::make(formal_par7_HL, I"formal_par7", template);
	HierarchyLocations::make(FORMAL_RV_HL, I"formal_rv", template);
	HierarchyLocations::make(FOUND_EVERYWHERE_HL, I"FoundEverywhere", template);
	HierarchyLocations::make(GENERATERANDOMNUMBER_HL, I"GenerateRandomNumber", template);
	HierarchyLocations::make(GENERICVERBSUB_HL, I"GenericVerbSub", template);
	HierarchyLocations::make(GETGNAOFOBJECT_HL, I"GetGNAOfObject", template);
	HierarchyLocations::make(GPR_FAIL_HL, I"GPR_FAIL", template);
	HierarchyLocations::make(GPR_NUMBER_HL, I"GPR_NUMBER", template);
	HierarchyLocations::make(GPR_PREPOSITION_HL, I"GPR_PREPOSITION", template);
	HierarchyLocations::make(GPR_TT_HL, I"GPR_TT", template);
	HierarchyLocations::make(GPROPERTY_HL, I"GProperty", template);
	HierarchyLocations::make(HASHLISTRELATIONHANDLER_HL, I"HashListRelationHandler", template);
	HierarchyLocations::make(I7SFRAME_HL, I"I7SFRAME", template);
	HierarchyLocations::make(INDENT_BIT_HL, I"INDENT_BIT", template);
	HierarchyLocations::make(INP1_HL, I"inp1", template);
	HierarchyLocations::make(INP2_HL, I"inp2", template);
	HierarchyLocations::make(INTEGERDIVIDE_HL, I"IntegerDivide", template);
	HierarchyLocations::make(INTEGERREMAINDER_HL, I"IntegerRemainder", template);
	HierarchyLocations::make(INVENTORY_STAGE_HL, I"inventory_stage", template);
	HierarchyLocations::make(KEEP_SILENT_HL, I"keep_silent", template);
	HierarchyLocations::make(KINDATOMIC_HL, I"KindAtomic", template);
	HierarchyLocations::make(LATEST_RULE_RESULT_HL, I"latest_rule_result", template);
	HierarchyLocations::make(LIST_ITEM_BASE_HL, I"LIST_ITEM_BASE", template);
	HierarchyLocations::make(LIST_ITEM_KOV_F_HL, I"LIST_ITEM_KOV_F", template);
	HierarchyLocations::make(LIST_OF_TY_DESC_HL, I"LIST_OF_TY_Desc", template);
	HierarchyLocations::make(LIST_OF_TY_GETITEM_HL, I"LIST_OF_TY_GetItem", template);
	HierarchyLocations::make(LIST_OF_TY_GETLENGTH_HL, I"LIST_OF_TY_GetLength", template);
	HierarchyLocations::make(LIST_OF_TY_INSERTITEM_HL, I"LIST_OF_TY_InsertItem", template);
	HierarchyLocations::make(LIST_OF_TY_SAY_HL, I"LIST_OF_TY_Say", template);
	HierarchyLocations::make(LIST_OF_TY_SETLENGTH_HL, I"LIST_OF_TY_SetLength", template);
	HierarchyLocations::make(LOCALPARKING_HL, I"LocalParking", template);
	HierarchyLocations::make(LOCATION_HL, I"location", template);
	HierarchyLocations::make(LOCATIONOF_HL, I"LocationOf", template);
	HierarchyLocations::make(LOOPOVERSCOPE_HL, I"LoopOverScope", template);
	HierarchyLocations::make(LOS_RV_HL, I"los_rv", template);
	HierarchyLocations::make(MSTACK_HL, I"MStack", template);
	HierarchyLocations::make(MSTVO_HL, I"MstVO", template);
	HierarchyLocations::make(MSTVON_HL, I"MstVON", template);
	HierarchyLocations::make(NAME_HL, I"name", template);
	HierarchyLocations::make(NEWLINE_BIT_HL, I"NEWLINE_BIT", template);
	HierarchyLocations::make(NEXTBEST_ETYPE_HL, I"nextbest_etype", template);
	HierarchyLocations::make(NEXTWORDSTOPPED_HL, I"NextWordStopped", template);
	HierarchyLocations::make(NOARTICLE_BIT_HL, I"NOARTICLE_BIT", template);
	HierarchyLocations::make(NOTINCONTEXTPE_HL, I"NOTINCONTEXT_PE", template);
	HierarchyLocations::make(NOUN_HL, I"noun", template);
	HierarchyLocations::make(NUMBER_TY_ABS_HL, I"NUMBER_TY_Abs", template);
	HierarchyLocations::make(NUMBER_TY_TO_REAL_NUMBER_TY_HL, I"NUMBER_TY_to_REAL_NUMBER_TY", template);
	HierarchyLocations::make(NUMBER_TY_TO_TIME_TY_HL, I"NUMBER_TY_to_TIME_TY", template);
	HierarchyLocations::make(OTOVRELROUTETO_HL, I"OtoVRelRouteTo", template);
	HierarchyLocations::make(PACKED_TEXT_STORAGE_HL, I"PACKED_TEXT_STORAGE", template);
	HierarchyLocations::make(PARACONTENT_HL, I"ParaContent", template);
	HierarchyLocations::make(PARAMETER_VALUE_HL, I"parameter_value", template);
	HierarchyLocations::make(PARSED_NUMBER_HL, I"parsed_number", template);
	HierarchyLocations::make(PARSER_ACTION_HL, I"parser_action", template);
	HierarchyLocations::make(PARSER_ONE_HL, I"parser_one", template);
	HierarchyLocations::make(PARSER_TRACE_HL, I"parser_trace", template);
	HierarchyLocations::make(PARSER_TWO_HL, I"parser_two", template);
	HierarchyLocations::make(PARSERERROR_HL, I"ParserError", template);
	HierarchyLocations::make(PARSETOKENSTOPPED_HL, I"ParseTokenStopped", template);
	HierarchyLocations::make(PAST_CHRONOLOGICAL_RECORD_HL, I"past_chronological_record", template);
	HierarchyLocations::make(PLACEINSCOPE_HL, I"PlaceInScope", template);
	HierarchyLocations::make(PLAYER_HL, I"player", template);
	HierarchyLocations::make(PNTOVP_HL, I"PNToVP", template);
	HierarchyLocations::make(PRESENT_CHRONOLOGICAL_RECORD_HL, I"present_chronological_record", template);
	HierarchyLocations::make(PRINTORRUN_HL, I"PrintOrRun", template);
	HierarchyLocations::make(PRIOR_NAMED_LIST_HL, I"prior_named_list", template);
	HierarchyLocations::make(PRIOR_NAMED_LIST_GENDER_HL, I"prior_named_list_gender", template);
	HierarchyLocations::make(PRIOR_NAMED_NOUN_HL, I"prior_named_noun", template);
	HierarchyLocations::make(PROPERTY_LOOP_SIGN_HL, I"property_loop_sign", template);
	HierarchyLocations::make(PROPERTY_TO_BE_TOTALLED_HL, I"property_to_be_totalled", template);
	HierarchyLocations::make(REAL_LOCATION_HL, I"real_location", template);
	HierarchyLocations::make(REAL_NUMBER_TY_ABS_HL, I"REAL_NUMBER_TY_Abs", template);
	HierarchyLocations::make(REAL_NUMBER_TY_APPROXIMATE_HL, I"REAL_NUMBER_TY_Approximate", template);
	HierarchyLocations::make(REAL_NUMBER_TY_COMPARE_HL, I"REAL_NUMBER_TY_Compare", template);
	HierarchyLocations::make(REAL_NUMBER_TY_CUBE_ROOT_HL, I"REAL_NUMBER_TY_Cube_Root", template);
	HierarchyLocations::make(REAL_NUMBER_TY_DIVIDE_HL, I"REAL_NUMBER_TY_Divide", template);
	HierarchyLocations::make(REAL_NUMBER_TY_MINUS_HL, I"REAL_NUMBER_TY_Minus", template);
	HierarchyLocations::make(REAL_NUMBER_TY_NAN_HL, I"REAL_NUMBER_TY_Nan", template);
	HierarchyLocations::make(REAL_NUMBER_TY_NEGATE_HL, I"REAL_NUMBER_TY_Negate", template);
	HierarchyLocations::make(REAL_NUMBER_TY_PLUS_HL, I"REAL_NUMBER_TY_Plus", template);
	HierarchyLocations::make(REAL_NUMBER_TY_POW_HL, I"REAL_NUMBER_TY_Pow", template);
	HierarchyLocations::make(REAL_NUMBER_TY_REMAINDER_HL, I"REAL_NUMBER_TY_Remainder", template);
	HierarchyLocations::make(REAL_NUMBER_TY_ROOT_HL, I"REAL_NUMBER_TY_Root", template);
	HierarchyLocations::make(REAL_NUMBER_TY_SAY_HL, I"REAL_NUMBER_TY_Say", template);
	HierarchyLocations::make(REAL_NUMBER_TY_TIMES_HL, I"REAL_NUMBER_TY_Times", template);
	HierarchyLocations::make(REAL_NUMBER_TY_TO_NUMBER_TY_HL, I"REAL_NUMBER_TY_to_NUMBER_TY", template);
	HierarchyLocations::make(REASON_THE_ACTION_FAILED_HL, I"reason_the_action_failed", template);
	HierarchyLocations::make(RELATION_EMPTYEQUIV_HL, I"Relation_EmptyEquiv", template);
	HierarchyLocations::make(RELATION_EMPTYOTOO_HL, I"Relation_EmptyOtoO", template);
	HierarchyLocations::make(RELATION_EMPTYVTOV_HL, I"Relation_EmptyVtoV", template);
	HierarchyLocations::make(RELATION_RSHOWOTOO_HL, I"Relation_RShowOtoO", template);
	HierarchyLocations::make(RELATION_SHOWEQUIV_HL, I"Relation_ShowEquiv", template);
	HierarchyLocations::make(RELATION_SHOWOTOO_HL, I"Relation_ShowOtoO", template);
	HierarchyLocations::make(RELATION_SHOWVTOV_HL, I"Relation_ShowVtoV", template);
	HierarchyLocations::make(RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective", template);
	HierarchyLocations::make(RELATION_TY_NAME_HL, I"RELATION_TY_Name", template);
	HierarchyLocations::make(RELATION_TY_OTOOADJECTIVE_HL, I"RELATION_TY_OToOAdjective", template);
	HierarchyLocations::make(RELATION_TY_OTOVADJECTIVE_HL, I"RELATION_TY_OToVAdjective", template);
	HierarchyLocations::make(RELATION_TY_SYMMETRICADJECTIVE_HL, I"RELATION_TY_SymmetricAdjective", template);
	HierarchyLocations::make(RELATION_TY_VTOOADJECTIVE_HL, I"RELATION_TY_VToOAdjective", template);
	HierarchyLocations::make(RELATIONTEST_HL, I"RelationTest", template);
	HierarchyLocations::make(RELFOLLOWVECTOR_HL, I"RelFollowVector", template);
	HierarchyLocations::make(RELS_EMPTY_HL, I"RELS_EMPTY", template);
	HierarchyLocations::make(RESPONSEVIAACTIVITY_HL, I"ResponseViaActivity", template);
	HierarchyLocations::make(RLANY_CAN_GET_X_HL, I"RLANY_CAN_GET_X", template);
	HierarchyLocations::make(RLANY_CAN_GET_Y_HL, I"RLANY_CAN_GET_Y", template);
	HierarchyLocations::make(RLANY_GET_X_HL, I"RLANY_GET_X", template);
	HierarchyLocations::make(RLIST_ALL_X_HL, I"RLIST_ALL_X", template);
	HierarchyLocations::make(RLIST_ALL_Y_HL, I"RLIST_ALL_Y", template);
	HierarchyLocations::make(RLNGETF_HL, I"RlnGetF", template);
	HierarchyLocations::make(ROUNDOFFTIME_HL, I"RoundOffTime", template);
	HierarchyLocations::make(ROUTINEFILTER_TT_HL, I"ROUTINE_FILTER_TT", template);
	HierarchyLocations::make(RR_STORAGE_HL, I"RR_STORAGE", template);
	HierarchyLocations::make(RTP_RELKINDVIOLATION_HL, I"RTP_RELKINDVIOLATION", template);
	HierarchyLocations::make(RTP_RELMINIMAL_HL, I"RTP_RELMINIMAL", template);
	HierarchyLocations::make(RULEBOOKFAILS_HL, I"RulebookFails", template);
	HierarchyLocations::make(RULEBOOKPARBREAK_HL, I"RulebookParBreak", template);
	HierarchyLocations::make(RULEBOOKSUCCEEDS_HL, I"RulebookSucceeds", template);
	HierarchyLocations::make(RUNTIMEPROBLEM_HL, I"RunTimeProblem", template);
	HierarchyLocations::make(SAY__N_HL, I"say__n", template);
	HierarchyLocations::make(SAY__P_HL, I"say__p", template);
	HierarchyLocations::make(SAY__PC_HL, I"say__pc", template);
	HierarchyLocations::make(SCENE_ENDED_HL, I"scene_ended", template);
	HierarchyLocations::make(SCENE_ENDINGS_HL, I"scene_endings", template);
	HierarchyLocations::make(SCENE_LATEST_ENDING_HL, I"scene_latest_ending", template);
	HierarchyLocations::make(SCENE_STARTED_HL, I"scene_started", template);
	HierarchyLocations::make(SCENE_STATUS_HL, I"scene_status", template);
	HierarchyLocations::make(SCOPE_STAGE_HL, I"scope_stage", template);
	HierarchyLocations::make(SCOPE_TT_HL, I"SCOPE_TT", template);
	HierarchyLocations::make(SECOND_HL, I"second", template);
	HierarchyLocations::make(SHORT_NAME_HL, I"short_name", template);
	HierarchyLocations::make(SIGNEDCOMPARE_HL, I"SignedCompare", template);
	HierarchyLocations::make(SPECIAL_WORD_HL, I"special_word", template);
	HierarchyLocations::make(SQUAREROOT_HL, I"SquareRoot", template);
	HierarchyLocations::make(STACKFRAMECREATE_HL, I"StackFrameCreate", template);
	HierarchyLocations::make(STORED_ACTION_TY_CURRENT_HL, I"STORED_ACTION_TY_Current", template);
	HierarchyLocations::make(STORED_ACTION_TY_TRY_HL, I"STORED_ACTION_TY_Try", template);
	HierarchyLocations::make(STORY_TENSE_HL, I"story_tense", template);
	HierarchyLocations::make(SUPPORTER_HL, I"supporter", template);
	HierarchyLocations::make(SUPPRESS_SCOPE_LOOPS_HL, I"suppress_scope_loops", template);
	HierarchyLocations::make(SUPPRESS_TEXT_SUBSTITUTION_HL, I"suppress_text_substitution", template);
	HierarchyLocations::make(TABLE_NOVALUE_HL, I"TABLE_NOVALUE", template);
	HierarchyLocations::make(TABLELOOKUPCORR_HL, I"TableLookUpCorr", template);
	HierarchyLocations::make(TABLELOOKUPENTRY_HL, I"TableLookUpEntry", template);
	HierarchyLocations::make(TESTACTIONBITMAP_HL, I"TestActionBitmap", template);
	HierarchyLocations::make(TESTACTIVITY_HL, I"TestActivity", template);
	HierarchyLocations::make(TESTREGIONALCONTAINMENT_HL, I"TestRegionalContainment", template);
	HierarchyLocations::make(TESTSCOPE_HL, I"TestScope", template);
	HierarchyLocations::make(TESTSTART_HL, I"TestStart", template);
	HierarchyLocations::make(TEXT_TY_COMPARE_HL, I"TEXT_TY_Compare", template);
	HierarchyLocations::make(TEXT_TY_EXPANDIFPERISHABLE_HL, I"TEXT_TY_ExpandIfPerishable", template);
	HierarchyLocations::make(TEXT_TY_SAY_HL, I"TEXT_TY_Say", template);
	HierarchyLocations::make(THE_TIME_HL, I"the_time", template);
	HierarchyLocations::make(THEEMPTYTABLE_HL, I"TheEmptyTable", template);
	HierarchyLocations::make(THEN1__WD_HL, I"THEN1__WD", template);
	HierarchyLocations::make(TIMESACTIONHASBEENHAPPENING_HL, I"TimesActionHasBeenHappening", template);
	HierarchyLocations::make(TIMESACTIONHASHAPPENED_HL, I"TimesActionHasHappened", template);
	HierarchyLocations::make(TRYACTION_HL, I"TryAction", template);
	HierarchyLocations::make(TRYGIVENOBJECT_HL, I"TryGivenObject", template);
	HierarchyLocations::make(TURNSACTIONHASBEENHAPPENING_HL, I"TurnsActionHasBeenHappening", template);
	HierarchyLocations::make(UNDERSTAND_AS_MISTAKE_NUMBER_HL, I"understand_as_mistake_number", template);
	HierarchyLocations::make(UNICODE_TEMP_HL, I"unicode_temp", template);
	HierarchyLocations::make(VTOORELROUTETO_HL, I"VtoORelRouteTo", template);
	HierarchyLocations::make(VTOVRELROUTETO_HL, I"VtoVRelRouteTo", template);
	HierarchyLocations::make(WHEN_SCENE_BEGINS_HL, I"WHEN_SCENE_BEGINS_RB", template);
	HierarchyLocations::make(WHEN_SCENE_ENDS_HL, I"WHEN_SCENE_ENDS_RB", template);
	HierarchyLocations::make(WN_HL, I"wn", template);
	HierarchyLocations::make(WORDADDRESS_HL, I"WordAddress", template);
	HierarchyLocations::make(WORDINPROPERTY_HL, I"WordInProperty", template);
	HierarchyLocations::make(WORDLENGTH_HL, I"WordLength", template);

@

@e MAX_HL
@e MAX_HAP

@

=
package_request *Hierarchy::exotic_package(int x) {
	switch (x) {
		case K_OBJECT_XPACKAGE: return Kinds::Behaviour::package(K_object);
		case K_NUMBER_XPACKAGE: return Kinds::Behaviour::package(K_number);
		case K_TIME_XPACKAGE: return Kinds::Behaviour::package(K_time);
		case K_TRUTH_STATE_XPACKAGE: return Kinds::Behaviour::package(K_truth_state);
		case K_TABLE_XPACKAGE: return Kinds::Behaviour::package(K_table);
		case K_VERB_XPACKAGE: return Kinds::Behaviour::package(K_verb);
		case K_FIGURE_NAME_XPACKAGE: return Kinds::Behaviour::package(K_figure_name);
		case K_SOUND_NAME_XPACKAGE: return Kinds::Behaviour::package(K_sound_name);
		case K_USE_OPTION_XPACKAGE: return Kinds::Behaviour::package(K_use_option);
		case V_COMMAND_PROMPT_XPACKAGE:
			return Packaging::home_of(NonlocalVariables::iname(command_prompt_VAR));
	}
	internal_error("unknown exotic package");
	return NULL;
}

@

=
inter_name *Hierarchy::post_process(int HL_id, inter_name *iname) {
	switch (HL_id) {
		case THESAME_HL:
		case PLURALFOUND_HL:
		case PARENT_HL:
		case CHILD_HL:
		case SIBLING_HL:
		case THEDARK_HL:
		case FLOAT_NAN_HL:
		case RESPONSETEXTS_HL: {
			packaging_state save = Packaging::enter_home_of(iname);
			Emit::named_numeric_constant(iname, 0);
			Packaging::exit(save);
			break;
		}
		case SELF_HL: {
			packaging_state save = Packaging::enter_home_of(iname);
			Emit::variable(iname, K_value, UNDEF_IVAL, 0, I"self");
			Packaging::exit(save);
			break;
		}
		case OBJECT_HL:
			iname = Kinds::RunTime::I6_classname(K_object);
			break;
	}
	return iname;
}

@

=
inter_name *Hierarchy::find(int id) {
	return HierarchyLocations::find(id);
}

void Hierarchy::make_available(inter_name *iname) {
	HierarchyLocations::make_as(-1, InterNames::to_symbol(iname)->symbol_name, iname);
}

inter_name *Hierarchy::find_by_name(text_stream *name) {
	if (Str::len(name) == 0) internal_error("empty extern");
	inter_name *try = HierarchyLocations::find_by_name(name);
	if (try == NULL) {
		HierarchyLocations::make(-1, name, Hierarchy::template());
		try = HierarchyLocations::find_by_name(name);
	}
	return try;
}

package_request *main_pr = NULL;
package_request *Hierarchy::main(void) {
	if (main_pr == NULL)
		main_pr = Packaging::request(InterNames::one_off(I"main", NULL), NULL, plain_ptype);
	return main_pr;
}

package_request *resources_pr = NULL;
package_request *Hierarchy::resources(void) {
	if (resources_pr == NULL)
		resources_pr = Packaging::request(
			InterNames::one_off(I"resources", Hierarchy::main()),
			Hierarchy::main(), plain_ptype);
	return resources_pr;
}

package_request *template_pr = NULL;
package_request *Hierarchy::template(void) {
	if (template_pr == NULL)
		template_pr = Packaging::request(
			InterNames::one_off(I"template", Hierarchy::resources()),
			Hierarchy::resources(), module_ptype);
	return template_pr;
}

package_request *Hierarchy::package(compilation_module *C, int hap_id) {
	return HierarchyLocations::package(C, hap_id);
}

package_request *Hierarchy::synoptic_package(int hap_id) {
	return HierarchyLocations::synoptic_package(hap_id);
}

package_request *Hierarchy::local_package(int hap_id) {
	return HierarchyLocations::package(Modules::find(current_sentence), hap_id);
}

package_request *Hierarchy::package_within(int hap_id, package_request *super) {
	return HierarchyLocations::package_within(super, hap_id);
}

package_request *Hierarchy::package_in_package(int id, package_request *P) {
	return HierarchyLocations::package_in_package(id, P);
}

package_request *Hierarchy::home_for_weak_type_IDs(void) {
	return Packaging::synoptic_resource(KINDS_SUBMODULE);
}
