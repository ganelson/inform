[Hierarchy::] Hierarchy.

@

=
location_requirement home_for_weak_type_IDs;

void Hierarchy::establish(void) {
	home_for_weak_type_IDs = HierarchyLocations::blank();

	Packaging::register_counter(I"code_block"); // This will be counter number 0
	Packaging::register_counter(I"kernel"); // This will be counter number 1

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
	@<Establish enclosed matter@>;
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

	submodule_identity *basics = Packaging::register_submodule(I"basics");

	location_requirement generic_basics = HierarchyLocations::generic_submodule(basics);
	HierarchyLocations::con(THESAME_HL, I"##TheSame", Translation::same(), generic_basics);
	HierarchyLocations::con(PLURALFOUND_HL, I"##PluralFound", Translation::same(), generic_basics);
	HierarchyLocations::con(PARENT_HL, I"parent", Translation::same(), generic_basics);
	HierarchyLocations::con(CHILD_HL, I"child", Translation::same(), generic_basics);
	HierarchyLocations::con(SIBLING_HL, I"sibling", Translation::same(), generic_basics);
	HierarchyLocations::con(SELF_HL, I"self", Translation::same(), generic_basics);
	HierarchyLocations::con(THEDARK_HL, I"thedark", Translation::same(), generic_basics);
	HierarchyLocations::con(RESPONSETEXTS_HL, I"ResponseTexts", Translation::same(), generic_basics);
	HierarchyLocations::con(DEBUG_HL, I"DEBUG", Translation::same(), generic_basics);
	HierarchyLocations::con(TARGET_ZCODE_HL, I"TARGET_ZCODE", Translation::same(), generic_basics);
	HierarchyLocations::con(TARGET_GLULX_HL, I"TARGET_GLULX", Translation::same(), generic_basics);
	HierarchyLocations::con(DICT_WORD_SIZE_HL, I"DICT_WORD_SIZE", Translation::same(), generic_basics);
	HierarchyLocations::con(WORDSIZE_HL, I"WORDSIZE", Translation::same(), generic_basics);
	HierarchyLocations::con(NULL_HL, I"NULL", Translation::same(), generic_basics);
	HierarchyLocations::con(WORD_HIGHBIT_HL, I"WORD_HIGHBIT", Translation::same(), generic_basics);
	HierarchyLocations::con(WORD_NEXTTOHIGHBIT_HL, I"WORD_NEXTTOHIGHBIT", Translation::same(), generic_basics);
	HierarchyLocations::con(IMPROBABLE_VALUE_HL, I"IMPROBABLE_VALUE", Translation::same(), generic_basics);
	HierarchyLocations::con(REPARSE_CODE_HL, I"REPARSE_CODE", Translation::same(), generic_basics);
	HierarchyLocations::con(MAX_POSITIVE_NUMBER_HL, I"MAX_POSITIVE_NUMBER", Translation::same(), generic_basics);
	HierarchyLocations::con(MIN_NEGATIVE_NUMBER_HL, I"MIN_NEGATIVE_NUMBER", Translation::same(), generic_basics);
	HierarchyLocations::con(FLOAT_NAN_HL, I"FLOAT_NAN", Translation::same(), generic_basics);
	HierarchyLocations::con(CAP_SHORT_NAME_EXISTS_HL, I"CAP_SHORT_NAME_EXISTS", Translation::same(), generic_basics);
	HierarchyLocations::con(NI_BUILD_COUNT_HL, I"NI_BUILD_COUNT", Translation::same(), generic_basics);
	HierarchyLocations::con(RANKING_TABLE_HL, I"RANKING_TABLE", Translation::same(), generic_basics);
	HierarchyLocations::con(PLUGIN_FILES_HL, I"PLUGIN_FILES", Translation::same(), generic_basics);
	HierarchyLocations::con(MAX_WEAK_ID_HL, I"MAX_WEAK_ID", Translation::same(), generic_basics);
	HierarchyLocations::con(NO_VERB_VERB_DEFINED_HL, I"NO_VERB_VERB_DEFINED", Translation::same(), generic_basics);
	HierarchyLocations::con(NO_TEST_SCENARIOS_HL, I"NO_TEST_SCENARIOS", Translation::same(), generic_basics);
	HierarchyLocations::con(MEMORY_HEAP_SIZE_HL, I"MEMORY_HEAP_SIZE", Translation::same(), generic_basics);

	location_requirement synoptic_basics = HierarchyLocations::synoptic_submodule(basics);
	HierarchyLocations::con(CCOUNT_QUOTATIONS_HL, I"CCOUNT_QUOTATIONS", Translation::same(), synoptic_basics);
	HierarchyLocations::con(MAX_FRAME_SIZE_NEEDED_HL, I"MAX_FRAME_SIZE_NEEDED", Translation::same(), synoptic_basics);
	HierarchyLocations::con(RNG_SEED_AT_START_OF_PLAY_HL, I"RNG_SEED_AT_START_OF_PLAY", Translation::same(), synoptic_basics);

@h Actions.

@e MISTAKEACTION_HL

@e ACTIONS_HAP
@e ACTION_BASE_NAME_HL
@e DOUBLE_SHARP_NAME_HL
@e PERFORM_FN_HL
@e CHECK_RB_HL
@e CARRY_OUT_RB_HL
@e REPORT_RB_HL
@e ACTION_STV_CREATOR_FN_HL

@e ACTIONCODING_HL
@e ACTIONDATA_HL
@e ACTIONHAPPENED_HL
@e AD_RECORDS_HL
@e CCOUNT_ACTION_NAME_HL
@e DB_ACTION_DETAILS_HL
@e MISTAKEACTIONSUB_HL

@<Establish actions@> =
	submodule_identity *actions = Packaging::register_submodule(I"actions");

	location_requirement generic_actions = HierarchyLocations::generic_submodule(actions);
	HierarchyLocations::con(MISTAKEACTION_HL, I"##MistakeAction", Translation::same(), generic_actions);

	location_requirement local_actions = HierarchyLocations::local_submodule(actions);
	HierarchyLocations::ap(ACTIONS_HAP, local_actions, I"action", I"_action");
		location_requirement in_action = HierarchyLocations::any_package_of_type(I"_action");
		HierarchyLocations::con(ACTION_BASE_NAME_HL, NULL, Translation::generate(ACTION_BASE_INAMEF), in_action);
		HierarchyLocations::con(DOUBLE_SHARP_NAME_HL, NULL, Translation::derive(ACTION_INAMEF), in_action);
		HierarchyLocations::func(PERFORM_FN_HL, I"perform_fn", Translation::derive(ACTION_ROUTINE_INAMEF), in_action);
		HierarchyLocations::package(CHECK_RB_HL, I"check_rb", I"_rulebook", in_action);
		HierarchyLocations::package(CARRY_OUT_RB_HL, I"carry_out_rb", I"_rulebook", in_action);
		HierarchyLocations::package(REPORT_RB_HL, I"report_rb", I"_rulebook", in_action);
		HierarchyLocations::func(ACTION_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_action);

	location_requirement synoptic_actions = HierarchyLocations::synoptic_submodule(actions);
	HierarchyLocations::con(ACTIONCODING_HL, I"ActionCoding", Translation::same(), synoptic_actions);
	HierarchyLocations::con(ACTIONDATA_HL, I"ActionData", Translation::same(), synoptic_actions);
	HierarchyLocations::con(ACTIONHAPPENED_HL, I"ActionHappened", Translation::same(), synoptic_actions);
	HierarchyLocations::con(AD_RECORDS_HL, I"AD_RECORDS", Translation::same(), synoptic_actions);
	HierarchyLocations::con(CCOUNT_ACTION_NAME_HL, I"CCOUNT_ACTION_NAME", Translation::same(), synoptic_actions);
	HierarchyLocations::func(DB_ACTION_DETAILS_HL, I"DB_Action_Details_fn", Translation::to(I"DB_Action_Details"), synoptic_actions);
	HierarchyLocations::func(MISTAKEACTIONSUB_HL, I"MistakeActionSub_fn", Translation::to(I"MistakeActionSub"), synoptic_actions);

@h Activities.

@e ACTIVITIES_HAP
@e ACTIVITY_HL
@e BEFORE_RB_HL
@e FOR_RB_HL
@e AFTER_RB_HL
@e ACTIVITY_STV_CREATOR_FN_HL

@e ACTIVITY_AFTER_RULEBOOKS_HL
@e ACTIVITY_ATB_RULEBOOKS_HL
@e ACTIVITY_BEFORE_RULEBOOKS_HL
@e ACTIVITY_FOR_RULEBOOKS_HL
@e ACTIVITY_VAR_CREATORS_HL

@<Establish activities@> =
	submodule_identity *activities = Packaging::register_submodule(I"activities");

	location_requirement local_activities = HierarchyLocations::local_submodule(activities);
	HierarchyLocations::ap(ACTIVITIES_HAP, local_activities, I"activity", I"_activity");
		location_requirement in_activity = HierarchyLocations::any_package_of_type(I"_activity");
		HierarchyLocations::con(ACTIVITY_HL, NULL, Translation::generate(ACTIVITY_INAMEF), in_activity);
		HierarchyLocations::package(BEFORE_RB_HL, I"before_rb", I"_rulebook", in_activity);
		HierarchyLocations::package(FOR_RB_HL, I"for_rb", I"_rulebook", in_activity);
		HierarchyLocations::package(AFTER_RB_HL, I"after_rb", I"_rulebook", in_activity);
		HierarchyLocations::func(ACTIVITY_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_activity);

	location_requirement synoptic_activities = HierarchyLocations::synoptic_submodule(activities);
	HierarchyLocations::con(ACTIVITY_AFTER_RULEBOOKS_HL, I"Activity_after_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(ACTIVITY_ATB_RULEBOOKS_HL, I"Activity_atb_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(ACTIVITY_BEFORE_RULEBOOKS_HL, I"Activity_before_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(ACTIVITY_FOR_RULEBOOKS_HL, I"Activity_for_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(ACTIVITY_VAR_CREATORS_HL, I"activity_var_creators", Translation::same(), synoptic_activities);

@h Adjectives.

@e ADJECTIVES_HAP
@e ADJECTIVE_HL
@e ADJECTIVE_MEANINGS_HAP
@e MEASUREMENT_FN_HL
@e ADJECTIVE_PHRASES_HAP
@e DEFINITION_FN_HL
@e ADJECTIVE_TASKS_HAP
@e TASK_FN_HL

@<Establish adjectives@> =
	submodule_identity *adjectives = Packaging::register_submodule(I"adjectives");

	location_requirement local_adjectives = HierarchyLocations::local_submodule(adjectives);
	HierarchyLocations::ap(ADJECTIVES_HAP, local_adjectives, I"adjective", I"_adjective");
		location_requirement in_adjective = HierarchyLocations::any_package_of_type(I"_adjective");
		HierarchyLocations::con(ADJECTIVE_HL, I"adjective", Translation::uniqued(), in_adjective);
		HierarchyLocations::ap(ADJECTIVE_TASKS_HAP, in_adjective, I"adjective_task", I"_adjective_task");
			location_requirement in_adjective_task = HierarchyLocations::any_package_of_type(I"_adjective_task");
			HierarchyLocations::func(TASK_FN_HL, I"task_fn", Translation::uniqued(), in_adjective_task);
	HierarchyLocations::ap(ADJECTIVE_MEANINGS_HAP, local_adjectives, I"adjective_meaning", I"_adjective_meaning");
		location_requirement in_adjective_meaning = HierarchyLocations::any_package_of_type(I"_adjective_meaning");
		HierarchyLocations::func(MEASUREMENT_FN_HL, I"measurement_fn", Translation::generate(MEASUREMENT_ADJECTIVE_INAMEF), in_adjective_meaning);
	HierarchyLocations::ap(ADJECTIVE_PHRASES_HAP, local_adjectives, I"adjective_phrase", I"_adjective_phrase");
		location_requirement in_adjective_phrase = HierarchyLocations::any_package_of_type(I"_adjective_phrase");
		HierarchyLocations::func(DEFINITION_FN_HL, I"measurement_fn", Translation::generate(ADJECTIVE_DEFINED_INAMEF), in_adjective_phrase);

@h Bibliographic.

@e UUID_ARRAY_HL
@e STORY_HL
@e HEADLINE_HL
@e STORY_AUTHOR_HL
@e RELEASE_HL
@e SERIAL_HL

@<Establish bibliographic@> =
	submodule_identity *bibliographic = Packaging::register_submodule(I"bibliographic");

	location_requirement synoptic_biblio = HierarchyLocations::synoptic_submodule(bibliographic);
	HierarchyLocations::con(UUID_ARRAY_HL, I"UUID_ARRAY", Translation::same(), synoptic_biblio);
	HierarchyLocations::datum(STORY_HL, I"Story_datum", Translation::to(I"Story"), synoptic_biblio);
	HierarchyLocations::datum(HEADLINE_HL, I"Headline_datum", Translation::to(I"Headline"), synoptic_biblio);
	HierarchyLocations::datum(STORY_AUTHOR_HL, I"Story_Author_datum", Translation::to(I"Story_Author"), synoptic_biblio);
	HierarchyLocations::datum(RELEASE_HL, I"Release_datum", Translation::to(I"Release"), synoptic_biblio);
	HierarchyLocations::datum(SERIAL_HL, I"Serial_datum", Translation::to(I"Serial"), synoptic_biblio);

@h Chronology.

@e PAST_ACTION_PATTERNS_HAP
@e PAP_FN_HL

@e TIMEDEVENTSTABLE_HL
@e TIMEDEVENTTIMESTABLE_HL
@e PASTACTIONSI6ROUTINES_HL
@e NO_PAST_TENSE_CONDS_HL
@e NO_PAST_TENSE_ACTIONS_HL
@e TESTSINGLEPASTSTATE_HL

@<Establish chronology@> =
	submodule_identity *chronology = Packaging::register_submodule(I"chronology");

	location_requirement local_chronology = HierarchyLocations::local_submodule(chronology);
	HierarchyLocations::ap(PAST_ACTION_PATTERNS_HAP, local_chronology, I"past_action_pattern", I"_past_action_pattern");
		location_requirement in_past_action_pattern = HierarchyLocations::any_package_of_type(I"_past_action_pattern");
		HierarchyLocations::func(PAP_FN_HL, I"pap_fn", Translation::generate(PAST_ACTION_ROUTINE_INAMEF), in_past_action_pattern);

	location_requirement synoptic_chronology = HierarchyLocations::synoptic_submodule(chronology);
	HierarchyLocations::con(TIMEDEVENTSTABLE_HL, I"TimedEventsTable", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(TIMEDEVENTTIMESTABLE_HL, I"TimedEventTimesTable", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(PASTACTIONSI6ROUTINES_HL, I"PastActionsI6Routines", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(NO_PAST_TENSE_CONDS_HL, I"NO_PAST_TENSE_CONDS", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(NO_PAST_TENSE_ACTIONS_HL, I"NO_PAST_TENSE_ACTIONS", Translation::same(), synoptic_chronology);
	HierarchyLocations::func(TESTSINGLEPASTSTATE_HL, I"test_fn", Translation::to(I"TestSinglePastState"), synoptic_chronology);

@h Conjugations.

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@e MVERBS_HAP
@e MODAL_CONJUGATION_FN_HL
@e VERBS_HAP
@e NONMODAL_CONJUGATION_FN_HL
@e VERB_FORMS_HAP
@e FORM_FN_HL
@e CONJUGATION_FN_HL

@<Establish conjugations@> =
	submodule_identity *conjugations = Packaging::register_submodule(I"conjugations");

	location_requirement generic_conjugations = HierarchyLocations::generic_submodule(conjugations);
	HierarchyLocations::con(CV_MEANING_HL, I"CV_MEANING", Translation::same(), generic_conjugations);
	HierarchyLocations::con(CV_MODAL_HL, I"CV_MODAL", Translation::same(), generic_conjugations);
	HierarchyLocations::con(CV_NEG_HL, I"CV_NEG", Translation::same(), generic_conjugations);
	HierarchyLocations::con(CV_POS_HL, I"CV_POS", Translation::same(), generic_conjugations);

	location_requirement local_conjugations = HierarchyLocations::local_submodule(conjugations);
	HierarchyLocations::ap(MVERBS_HAP, local_conjugations, I"mverb", I"_modal_verb");
		location_requirement in_modal_verb = HierarchyLocations::any_package_of_type(I"_modal_verb");
		HierarchyLocations::func(MODAL_CONJUGATION_FN_HL, I"conjugation_fn", Translation::generate(CONJUGATE_VERB_ROUTINE_INAMEF), in_modal_verb);
	HierarchyLocations::ap(VERBS_HAP, local_conjugations, I"verb", I"_verb");
		location_requirement in_verb = HierarchyLocations::any_package_of_type(I"_verb");
		HierarchyLocations::func(NONMODAL_CONJUGATION_FN_HL, I"conjugation_fn", Translation::generate(CONJUGATE_VERB_ROUTINE_INAMEF), in_verb);
		HierarchyLocations::ap(VERB_FORMS_HAP, in_verb, I"form", I"_verb_form");
			location_requirement in_verb_form = HierarchyLocations::any_package_of_type(I"_verb_form");
			HierarchyLocations::func(FORM_FN_HL, I"form_fn", Translation::uniqued(), in_verb_form);

@h Equations.

@e EQUATIONS_HAP
@e SOLVE_FN_HL

@<Establish equations@> =
	submodule_identity *equations = Packaging::register_submodule(I"equations");

	location_requirement local_equations = HierarchyLocations::local_submodule(equations);
	HierarchyLocations::ap(EQUATIONS_HAP, local_equations, I"equation", I"_equation");
		location_requirement in_equation = HierarchyLocations::any_package_of_type(I"_equation");
		HierarchyLocations::func(SOLVE_FN_HL, I"solve_fn", Translation::uniqued(), in_equation);

@h Extensions.

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish extensions@> =
	submodule_identity *extensions = Packaging::register_submodule(I"extensions");

	location_requirement synoptic_extensions = HierarchyLocations::synoptic_submodule(extensions);
	HierarchyLocations::func(SHOWEXTENSIONVERSIONS_HL, I"showextensionversions_fn", Translation::to(I"ShowExtensionVersions"), synoptic_extensions);
	HierarchyLocations::func(SHOWFULLEXTENSIONVERSIONS_HL, I"showfullextensionversions_fn", Translation::to(I"ShowFullExtensionVersions"), synoptic_extensions);
	HierarchyLocations::func(SHOWONEEXTENSION_HL, I"showoneextension_fn", Translation::to(I"ShowOneExtension"), synoptic_extensions);

@h External files.

@e EXTERNAL_FILES_HAP
@e FILE_HL
@e IFID_HL

@<Establish external files@> =
	submodule_identity *external_files = Packaging::register_submodule(I"external_files");

	location_requirement local_external_files = HierarchyLocations::local_submodule(external_files);
	HierarchyLocations::ap(EXTERNAL_FILES_HAP, local_external_files, I"external_file", I"_external_file");
		location_requirement in_external_file = HierarchyLocations::any_package_of_type(I"_external_file");
		HierarchyLocations::con(FILE_HL, I"file", Translation::uniqued(), in_external_file);
		HierarchyLocations::con(IFID_HL, I"ifid", Translation::uniqued(), in_external_file);

@h Grammar.

@e COND_TOKENS_HAP
@e CONDITIONAL_TOKEN_FN_HL
@e CONSULT_TOKENS_HAP
@e CONSULT_FN_HL
@e TESTS_HAP
@e SCRIPT_HL
@e REQUIREMENTS_HL
@e LOOP_OVER_SCOPES_HAP
@e LOOP_OVER_SCOPE_FN_HL
@e MISTAKES_HAP
@e MISTAKE_FN_HL
@e NAMED_ACTION_PATTERNS_HAP
@e NAP_FN_HL
@e NAMED_TOKENS_HAP
@e PARSE_LINE_FN_HL
@e NOUN_FILTERS_HAP
@e NOUN_FILTER_FN_HL
@e PARSE_NAMES_HAP
@e PARSE_NAME_FN_HL
@e PARSE_NAME_DASH_FN_HL
@e SCOPE_FILTERS_HAP
@e SCOPE_FILTER_FN_HL
@e SLASH_TOKENS_HAP
@e SLASH_FN_HL

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
@e COMMANDS_HAP
@e VERB_DECLARATION_ARRAY_HL

@<Establish grammar@> =
	submodule_identity *grammar = Packaging::register_submodule(I"grammar");

	location_requirement local_grammar = HierarchyLocations::local_submodule(grammar);
	HierarchyLocations::ap(COND_TOKENS_HAP, local_grammar, I"conditional_token", I"_conditional_token");
		location_requirement in_conditional_token = HierarchyLocations::any_package_of_type(I"_conditional_token");
		HierarchyLocations::func(CONDITIONAL_TOKEN_FN_HL, I"conditional_token_fn", Translation::generate(GRAMMAR_LINE_COND_TOKEN_INAMEF), in_conditional_token);
	HierarchyLocations::ap(CONSULT_TOKENS_HAP, local_grammar, I"consult_token", I"_consult_token");
		location_requirement in_consult_token = HierarchyLocations::any_package_of_type(I"_consult_token");
		HierarchyLocations::func(CONSULT_FN_HL, I"consult_fn", Translation::generate(CONSULT_GRAMMAR_INAMEF), in_consult_token);
	HierarchyLocations::ap(TESTS_HAP, local_grammar, I"test", I"_test");
		location_requirement in_test = HierarchyLocations::any_package_of_type(I"_test");
		HierarchyLocations::con(SCRIPT_HL, I"script", Translation::uniqued(), in_test);
		HierarchyLocations::con(REQUIREMENTS_HL, I"requirements", Translation::uniqued(), in_test);
	HierarchyLocations::ap(LOOP_OVER_SCOPES_HAP, local_grammar, I"loop_over_scope", I"_loop_over_scope");
		location_requirement in_loop_over_scope = HierarchyLocations::any_package_of_type(I"_loop_over_scope");
		HierarchyLocations::func(LOOP_OVER_SCOPE_FN_HL, I"loop_over_scope_fn", Translation::generate(LOOP_OVER_SCOPE_ROUTINE_INAMEF), in_loop_over_scope);
	HierarchyLocations::ap(MISTAKES_HAP, local_grammar, I"mistake", I"_mistake");
		location_requirement in_mistake = HierarchyLocations::any_package_of_type(I"_mistake");
		HierarchyLocations::func(MISTAKE_FN_HL, I"mistake_fn", Translation::generate(GRAMMAR_LINE_MISTAKE_TOKEN_INAMEF), in_mistake);
	HierarchyLocations::ap(NAMED_ACTION_PATTERNS_HAP, local_grammar, I"named_action_pattern", I"_named_action_pattern");
		location_requirement in_named_action_pattern = HierarchyLocations::any_package_of_type(I"_named_action_pattern");
		HierarchyLocations::func(NAP_FN_HL, I"nap_fn", Translation::generate(NAMED_ACTION_PATTERN_INAMEF), in_named_action_pattern);
	HierarchyLocations::ap(NAMED_TOKENS_HAP, local_grammar, I"named_token", I"_named_token");
		location_requirement in_named_token = HierarchyLocations::any_package_of_type(I"_named_token");
		HierarchyLocations::func(PARSE_LINE_FN_HL, I"parse_line_fn", Translation::generate(GPR_FOR_TOKEN_INAMEF), in_named_token);
	HierarchyLocations::ap(NOUN_FILTERS_HAP, local_grammar, I"noun_filter", I"_noun_filter");
		location_requirement in_noun_filter= HierarchyLocations::any_package_of_type(I"_noun_filter");
		HierarchyLocations::func(NOUN_FILTER_FN_HL, I"filter_fn", Translation::generate(NOUN_FILTER_INAMEF), in_noun_filter);
	HierarchyLocations::ap(SCOPE_FILTERS_HAP, local_grammar, I"scope_filter", I"_scope_filter");
		location_requirement in_scope_filter = HierarchyLocations::any_package_of_type(I"_scope_filter");
		HierarchyLocations::func(SCOPE_FILTER_FN_HL, I"filter_fn", Translation::generate(SCOPE_FILTER_INAMEF), in_scope_filter);
	HierarchyLocations::ap(PARSE_NAMES_HAP, local_grammar, I"parse_name", I"_parse_name");
		location_requirement in_parse_name = HierarchyLocations::any_package_of_type(I"_parse_name");
		HierarchyLocations::func(PARSE_NAME_FN_HL, I"parse_name_fn", Translation::generate(GRAMMAR_PARSE_NAME_ROUTINE_INAMEF), in_parse_name);
		HierarchyLocations::func(PARSE_NAME_DASH_FN_HL, I"parse_name_fn", Translation::generate(PARSE_NAME_ROUTINE_INAMEF), in_parse_name);
	HierarchyLocations::ap(SLASH_TOKENS_HAP, local_grammar, I"slash_token", I"_slash_token");
		location_requirement in_slash_token = HierarchyLocations::any_package_of_type(I"_slash_token");
		HierarchyLocations::func(SLASH_FN_HL, I"slash_fn", Translation::generate(GRAMMAR_SLASH_GPR_INAMEF), in_slash_token);

	location_requirement synoptic_grammar = HierarchyLocations::synoptic_submodule(grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_CREATURE_HL, I"VERB_DIRECTIVE_CREATURE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_DIVIDER_HL, I"VERB_DIRECTIVE_DIVIDER", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_HELD_HL, I"VERB_DIRECTIVE_HELD", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_MULTI_HL, I"VERB_DIRECTIVE_MULTI", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_MULTIEXCEPT_HL, I"VERB_DIRECTIVE_MULTIEXCEPT", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_MULTIHELD_HL, I"VERB_DIRECTIVE_MULTIHELD", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_MULTIINSIDE_HL, I"VERB_DIRECTIVE_MULTIINSIDE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_NOUN_HL, I"VERB_DIRECTIVE_NOUN", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_NUMBER_HL, I"VERB_DIRECTIVE_NUMBER", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_RESULT_HL, I"VERB_DIRECTIVE_RESULT", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_REVERSE_HL, I"VERB_DIRECTIVE_REVERSE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_SLASH_HL, I"VERB_DIRECTIVE_SLASH", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_SPECIAL_HL, I"VERB_DIRECTIVE_SPECIAL", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(VERB_DIRECTIVE_TOPIC_HL, I"VERB_DIRECTIVE_TOPIC", Translation::same(), synoptic_grammar);
	HierarchyLocations::func(TESTSCRIPTSUB_HL, I"action_fn", Translation::to(I"TestScriptSub"), synoptic_grammar);
	HierarchyLocations::func(INTERNALTESTCASES_HL, I"run_tests_fn", Translation::to(I"InternalTestCases"), synoptic_grammar);
	HierarchyLocations::ap(COMMANDS_HAP, synoptic_grammar, I"command", I"_command");
		location_requirement in_command = HierarchyLocations::any_package_of_type(I"_command");
		HierarchyLocations::func(VERB_DECLARATION_ARRAY_HL, NULL, Translation::generate(VERB_DECLARATION_ARRAY_INAMEF), in_command);

@h Instances.

@e INSTANCES_HAP
@e INSTANCE_HL
@e BACKDROP_FOUND_IN_FN_HL
@e REGION_FOUND_IN_FN_HL
@e SHORT_NAME_FN_HL
@e SHORT_NAME_PROPERTY_FN_HL
@e TSD_DOOR_DIR_FN_HL
@e TSD_DOOR_TO_FN_HL
@e INLINE_PROPERTIES_HAP
@e INLINE_PROPERTY_HL

@<Establish instances@> =
	submodule_identity *instances = Packaging::register_submodule(I"instances");

	location_requirement local_instances = HierarchyLocations::local_submodule(instances);
	HierarchyLocations::ap(INSTANCES_HAP, local_instances, I"instance", I"_instance");
		location_requirement in_instance = HierarchyLocations::any_package_of_type(I"_instance");
		HierarchyLocations::con(INSTANCE_HL, I"I", Translation::uniqued(), in_instance);
		HierarchyLocations::func(BACKDROP_FOUND_IN_FN_HL, I"backdrop_found_in_fn", Translation::uniqued(), in_instance);
		HierarchyLocations::func(SHORT_NAME_FN_HL, I"short_name_fn", Translation::generate(SHORT_NAME_ROUTINE_INAMEF), in_instance);
		HierarchyLocations::func(SHORT_NAME_PROPERTY_FN_HL, I"short_name_property_fn", Translation::generate(SHORT_NAME_PROPERTY_ROUTINE_INAMEF), in_instance);
		HierarchyLocations::func(REGION_FOUND_IN_FN_HL, I"region_found_in_fn", Translation::generate(REGION_FOUND_IN_ROUTINE_INAMEF), in_instance);
		HierarchyLocations::func(TSD_DOOR_DIR_FN_HL, I"tsd_door_dir_fn", Translation::generate(TWO_SIDED_DOOR_DOOR_DIR_INAMEF), in_instance);
		HierarchyLocations::func(TSD_DOOR_TO_FN_HL, I"tsd_door_to_fn", Translation::generate(TWO_SIDED_DOOR_DOOR_TO_INAMEF), in_instance);
		HierarchyLocations::ap(INLINE_PROPERTIES_HAP, in_instance, I"inline_property", I"_inline_property");
			location_requirement in_inline_property = HierarchyLocations::any_package_of_type(I"_inline_property");
			HierarchyLocations::con(INLINE_PROPERTY_HL, I"inline", Translation::uniqued(), in_inline_property);

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
@e DIRECTIONS_HAP
@e DIRECTION_HL

@<Establish int-fiction@> =
	submodule_identity *interactive_fiction = Packaging::register_submodule(I"interactive_fiction");

	location_requirement synoptic_IF = HierarchyLocations::synoptic_submodule(interactive_fiction);
	HierarchyLocations::con(DEFAULT_SCORING_SETTING_HL, I"DEFAULT_SCORING_SETTING", Translation::same(), synoptic_IF);
	HierarchyLocations::con(INITIAL_MAX_SCORE_HL, I"INITIAL_MAX_SCORE", Translation::same(), synoptic_IF);
	HierarchyLocations::con(NO_DIRECTIONS_HL, I"No_Directions", Translation::same(), synoptic_IF);
	HierarchyLocations::func(SHOWSCENESTATUS_HL, I"show_scene_status_fn", Translation::to(I"ShowSceneStatus"), synoptic_IF);
	HierarchyLocations::func(DETECTSCENECHANGE_HL, I"detect_scene_change_fn", Translation::to(I"DetectSceneChange"), synoptic_IF);
	HierarchyLocations::con(MAP_STORAGE_HL, I"Map_Storage", Translation::same(), synoptic_IF);
	HierarchyLocations::con(INITIALSITUATION_HL, I"InitialSituation", Translation::same(), synoptic_IF);
	HierarchyLocations::con(PLAYER_OBJECT_INIS_HL, I"PLAYER_OBJECT_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(START_OBJECT_INIS_HL, I"START_OBJECT_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(START_ROOM_INIS_HL, I"START_ROOM_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(START_TIME_INIS_HL, I"START_TIME_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(DONE_INIS_HL, I"DONE_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::ap(DIRECTIONS_HAP, synoptic_IF, I"direction", I"_direction");
		location_requirement in_direction = HierarchyLocations::any_package_of_type(I"_direction");
		HierarchyLocations::con(DIRECTION_HL, NULL, Translation::generate(DIRECTION_OBJECT_INAMEF), in_direction);

@h Kinds.

@e UNKNOWN_TY_HL
@e K_UNCHECKED_HL
@e K_UNCHECKED_FUNCTION_HL
@e K_TYPELESS_INT_HL
@e K_TYPELESS_STRING_HL

@e KIND_HAP
@e KIND_HL
@e DEFAULT_VALUE_HL
@e DECREMENT_FN_HL
@e INCREMENT_FN_HL
@e PRINT_FN_HL
@e PRINT_DASH_FN_HL
@e RANGER_FN_HL
@e DEFAULT_CLOSURE_FN_HL
@e GPR_FN_HL
@e INSTANCE_GPR_FN_HL
@e FIRST_INSTANCE_HL
@e NEXT_INSTANCE_HL
@e COUNT_INSTANCE_HL
@e KIND_INLINE_PROPERTIES_HAP
@e KIND_INLINE_PROPERTY_HL

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
	submodule_identity *kinds = Packaging::register_submodule(I"kinds");

	location_requirement generic_kinds = HierarchyLocations::generic_submodule(kinds);
	HierarchyLocations::con(UNKNOWN_TY_HL, I"UNKNOWN_TY", Translation::same(), generic_kinds);
	HierarchyLocations::con(K_UNCHECKED_HL, I"K_unchecked", Translation::same(), generic_kinds);
	HierarchyLocations::con(K_UNCHECKED_FUNCTION_HL, I"K_unchecked_function", Translation::same(), generic_kinds);
	HierarchyLocations::con(K_TYPELESS_INT_HL, I"K_typeless_int", Translation::same(), generic_kinds);
	HierarchyLocations::con(K_TYPELESS_STRING_HL, I"K_typeless_string", Translation::same(), generic_kinds);

	location_requirement local_kinds = HierarchyLocations::local_submodule(kinds);
	HierarchyLocations::ap(KIND_HAP, local_kinds, I"kind", I"_kind");
		location_requirement in_kind = HierarchyLocations::any_package_of_type(I"_kind");
		HierarchyLocations::con(KIND_HL, NULL, Translation::generate(KIND_ID_INAMEF), in_kind);
		HierarchyLocations::con(DEFAULT_VALUE_HL, I"default_value", Translation::uniqued(), in_kind);
		HierarchyLocations::func(DECREMENT_FN_HL, I"decrement_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(INCREMENT_FN_HL, I"increment_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(PRINT_FN_HL, I"print_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(PRINT_DASH_FN_HL, I"print_fn", Translation::generate(PRINTING_ROUTINE_INAMEF), in_kind);
		HierarchyLocations::func(RANGER_FN_HL, I"ranger_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(DEFAULT_CLOSURE_FN_HL, I"default_closure_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(GPR_FN_HL, I"gpr_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(INSTANCE_GPR_FN_HL, I"instance_gpr_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::con(FIRST_INSTANCE_HL, NULL, Translation::derive_lettered(FIRST_INSTANCE_INAMEF, FIRST_INSTANCE_INDERIV), in_kind);
		HierarchyLocations::con(NEXT_INSTANCE_HL, NULL, Translation::derive_lettered(NEXT_INSTANCE_INAMEF, NEXT_INSTANCE_INDERIV), in_kind);
		HierarchyLocations::con(COUNT_INSTANCE_HL, NULL, Translation::derive_lettered(COUNT_INSTANCE_INAMEF, COUNT_INSTANCE_INDERIV), in_kind);
		HierarchyLocations::ap(KIND_INLINE_PROPERTIES_HAP, in_kind, I"inline_property", I"_inline_property");
			location_requirement in_kind_inline_property = HierarchyLocations::any_package_of_type(I"_inline_property");
			HierarchyLocations::con(KIND_INLINE_PROPERTY_HL, I"inline", Translation::uniqued(), in_kind_inline_property);

	location_requirement synoptic_kinds = HierarchyLocations::synoptic_submodule(kinds);
	HierarchyLocations::con(BASE_KIND_HWM_HL, I"BASE_KIND_HWM", Translation::same(), synoptic_kinds);
	HierarchyLocations::func(DEFAULTVALUEOFKOV_HL, I"defaultvalue_fn", Translation::to(I"DefaultValueOfKOV"), synoptic_kinds);
	HierarchyLocations::func(DEFAULTVALUEFINDER_HL, I"defaultvaluefinder_fn", Translation::to(I"DefaultValueFinder"), synoptic_kinds);
	HierarchyLocations::func(PRINTKINDVALUEPAIR_HL, I"printkindvaluepair_fn", Translation::to(I"PrintKindValuePair"), synoptic_kinds);
	HierarchyLocations::func(KOVCOMPARISONFUNCTION_HL, I"comparison_fn", Translation::to(I"KOVComparisonFunction"), synoptic_kinds);
	HierarchyLocations::func(KOVDOMAINSIZE_HL, I"domainsize_fn", Translation::to(I"KOVDomainSize"), synoptic_kinds);
	HierarchyLocations::func(KOVISBLOCKVALUE_HL, I"blockvalue_fn", Translation::to(I"KOVIsBlockValue"), synoptic_kinds);
	HierarchyLocations::func(I7_KIND_NAME_HL, I"printkindname_fn", Translation::to(I"I7_Kind_Name"), synoptic_kinds);
	HierarchyLocations::func(KOVSUPPORTFUNCTION_HL, I"support_fn", Translation::to(I"KOVSupportFunction"), synoptic_kinds);
	HierarchyLocations::func(SHOWMEDETAILS_HL, I"showmedetails_fn", Translation::to(I"ShowMeDetails"), synoptic_kinds);
	home_for_weak_type_IDs = synoptic_kinds;

@h Listing.

@e LISTS_TOGETHER_HAP
@e LIST_TOGETHER_ARRAY_HL
@e LIST_TOGETHER_FN_HL

@<Establish listing@> =
	submodule_identity *listing = Packaging::register_submodule(I"listing");

	location_requirement local_listing = HierarchyLocations::local_submodule(listing);
	HierarchyLocations::ap(LISTS_TOGETHER_HAP, local_listing, I"list_together", I"_list_together");
		location_requirement in_list_together = HierarchyLocations::any_package_of_type(I"_list_together");
		HierarchyLocations::con(LIST_TOGETHER_ARRAY_HL, I"list_together_array", Translation::uniqued(), in_list_together);
		HierarchyLocations::func(LIST_TOGETHER_FN_HL, I"list_together_fn", Translation::generate(LIST_TOGETHER_ROUTINE_INAMEF), in_list_together);

@h Phrases.

@e CLOSURES_HAP
@e CLOSURE_DATA_HL
@e PHRASES_HAP
@e REQUESTS_HAP
@e PHRASE_FN_HL
@e LABEL_STORAGES_HAP
@e LABEL_ASSOCIATED_STORAGE_HL

@<Establish phrases@> =
	submodule_identity *phrases = Packaging::register_submodule(I"phrases");

	location_requirement local_phrases = HierarchyLocations::local_submodule(phrases);
	HierarchyLocations::ap(PHRASES_HAP, local_phrases, I"phrase", I"_to_phrase");
		location_requirement in_to_phrase = HierarchyLocations::any_package_of_type(I"_to_phrase");
		HierarchyLocations::ap(CLOSURES_HAP, in_to_phrase, I"closure", I"_closure");
			location_requirement in_closure = HierarchyLocations::any_package_of_type(I"_closure");
			HierarchyLocations::con(CLOSURE_DATA_HL, I"closure_data", Translation::uniqued(), in_closure);
		HierarchyLocations::ap(REQUESTS_HAP, in_to_phrase, I"request", I"_request");
			location_requirement in_request = HierarchyLocations::any_package_of_type(I"_request");
			HierarchyLocations::func(PHRASE_FN_HL, I"phrase_fn", Translation::generate_in(PHRASE_REQUEST_INAMEF), in_request);

	location_requirement synoptic_phrases = HierarchyLocations::synoptic_submodule(phrases);
	HierarchyLocations::ap(LABEL_STORAGES_HAP, synoptic_phrases, I"label_storage", I"_label_storage");
		location_requirement in_label_storage = HierarchyLocations::any_package_of_type(I"_label_storage");
		HierarchyLocations::con(LABEL_ASSOCIATED_STORAGE_HL, I"label_associated_storage", Translation::uniqued(), in_label_storage);

@h Properties.

@e PROPERTIES_HAP
@e PROPERTY_HL
@e EITHER_OR_GPR_FN_HL

@e CCOUNT_PROPERTY_HL

@<Establish properties@> =
	submodule_identity *properties = Packaging::register_submodule(I"properties");

	location_requirement local_properties = HierarchyLocations::local_submodule(properties);
	HierarchyLocations::ap(PROPERTIES_HAP, local_properties, I"property", I"_property");
		location_requirement in_property = HierarchyLocations::any_package_of_type(I"_property");
		HierarchyLocations::con(PROPERTY_HL, I"P", Translation::same(), in_property);
		HierarchyLocations::func(EITHER_OR_GPR_FN_HL, I"either_or_GPR_fn", Translation::generate(GPR_FOR_EITHER_OR_PROPERTY_INAMEF), in_property);

	location_requirement synoptic_props = HierarchyLocations::synoptic_submodule(properties);
	HierarchyLocations::con(CCOUNT_PROPERTY_HL, I"CCOUNT_PROPERTY", Translation::same(), synoptic_props);

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
@e RELATION_RECORD_HL
@e BITMAP_HL
@e ABILITIES_HL
@e ROUTE_CACHE_HL
@e HANDLER_FN_HL
@e RELATION_INITIALISER_FN_HL
@e GUARD_F0_FN_HL
@e GUARD_F1_FN_HL
@e GUARD_TEST_FN_HL
@e GUARD_MAKE_TRUE_FN_HL
@e GUARD_MAKE_FALSE_INAME_HL
@e RELATION_FN_HL

@e CREATEDYNAMICRELATIONS_HL
@e CCOUNT_BINARY_PREDICATE_HL
@e ITERATERELATIONS_HL
@e RPROPERTY_HL

@<Establish relations@> =
	submodule_identity *relations = Packaging::register_submodule(I"relations");

	location_requirement generic_rels = HierarchyLocations::generic_submodule(relations);
	HierarchyLocations::con(RELS_ASSERT_FALSE_HL, I"RELS_ASSERT_FALSE", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_ASSERT_TRUE_HL, I"RELS_ASSERT_TRUE", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_EQUIVALENCE_HL, I"RELS_EQUIVALENCE", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_LIST_HL, I"RELS_LIST", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_LOOKUP_ALL_X_HL, I"RELS_LOOKUP_ALL_X", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_LOOKUP_ALL_Y_HL, I"RELS_LOOKUP_ALL_Y", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_LOOKUP_ANY_HL, I"RELS_LOOKUP_ANY", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_ROUTE_FIND_COUNT_HL, I"RELS_ROUTE_FIND_COUNT", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_ROUTE_FIND_HL, I"RELS_ROUTE_FIND", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_SHOW_HL, I"RELS_SHOW", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_SYMMETRIC_HL, I"RELS_SYMMETRIC", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_TEST_HL, I"RELS_TEST", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_X_UNIQUE_HL, I"RELS_X_UNIQUE", Translation::same(), generic_rels);
	HierarchyLocations::con(RELS_Y_UNIQUE_HL, I"RELS_Y_UNIQUE", Translation::same(), generic_rels);
	HierarchyLocations::con(REL_BLOCK_HEADER_HL, I"REL_BLOCK_HEADER", Translation::same(), generic_rels);
	HierarchyLocations::con(TTF_SUM_HL, I"TTF_sum", Translation::same(), generic_rels);
	HierarchyLocations::con(MEANINGLESS_RR_HL, I"MEANINGLESS_RR", Translation::same(), generic_rels);

	location_requirement local_rels = HierarchyLocations::local_submodule(relations);
	HierarchyLocations::ap(RELATIONS_HAP, local_rels, I"relation", I"_relation");
		location_requirement in_relation = HierarchyLocations::any_package_of_type(I"_relation");
		HierarchyLocations::con(RELATION_RECORD_HL, NULL, Translation::generate(RELATION_RECORD_INAMEF), in_relation);
		HierarchyLocations::con(BITMAP_HL, I"as_constant", Translation::uniqued(), in_relation);
		HierarchyLocations::con(ABILITIES_HL, I"abilities", Translation::uniqued(), in_relation);
		HierarchyLocations::con(ROUTE_CACHE_HL, I"route_cache", Translation::uniqued(), in_relation);
		HierarchyLocations::func(HANDLER_FN_HL, I"handler_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(RELATION_INITIALISER_FN_HL, I"relation_initialiser_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(GUARD_F0_FN_HL, I"guard_f0_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(GUARD_F1_FN_HL, I"guard_f1_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(GUARD_TEST_FN_HL, I"guard_test_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(GUARD_MAKE_TRUE_FN_HL, I"guard_make_true_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(GUARD_MAKE_FALSE_INAME_HL, I"guard_make_false_iname", Translation::uniqued(), in_relation);
		HierarchyLocations::func(RELATION_FN_HL, I"relation_fn", Translation::uniqued(), in_relation);

	location_requirement synoptic_rels = HierarchyLocations::synoptic_submodule(relations);
	HierarchyLocations::func(CREATEDYNAMICRELATIONS_HL, I"creator_fn", Translation::to(I"CreateDynamicRelations"), synoptic_rels);
	HierarchyLocations::con(CCOUNT_BINARY_PREDICATE_HL, I"CCOUNT_BINARY_PREDICATE", Translation::same(), synoptic_rels);
	HierarchyLocations::func(ITERATERELATIONS_HL, I"iterator_fn", Translation::to(I"IterateRelations"), synoptic_rels);
	HierarchyLocations::func(RPROPERTY_HL, I"property_fn", Translation::to(I"RProperty"), synoptic_rels);

@h Rulebooks.

@e EMPTY_RULEBOOK_INAME_HL

@e OUTCOMES_HAP
@e OUTCOME_HL
@e RULEBOOKS_HAP
@e RUN_FN_HL
@e RULEBOOK_STV_CREATOR_FN_HL

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish rulebooks@> =
	submodule_identity *rulebooks = Packaging::register_submodule(I"rulebooks");

	location_requirement generic_rulebooks = HierarchyLocations::generic_submodule(rulebooks);
	HierarchyLocations::func(EMPTY_RULEBOOK_INAME_HL, I"empty_fn", Translation::to(I"EMPTY_RULEBOOK"), generic_rulebooks);

	location_requirement local_rulebooks = HierarchyLocations::local_submodule(rulebooks);
	HierarchyLocations::ap(OUTCOMES_HAP, local_rulebooks, I"rulebook_outcome", I"_outcome");
		location_requirement in_outcome = HierarchyLocations::any_package_of_type(I"_outcome");
		HierarchyLocations::con(OUTCOME_HL, I"outcome", Translation::uniqued(), in_outcome);
	HierarchyLocations::ap(RULEBOOKS_HAP, local_rulebooks, I"rulebook", I"_rulebook");
		location_requirement in_rulebook = HierarchyLocations::any_package_of_type(I"_rulebook");
		HierarchyLocations::func(RUN_FN_HL, I"run_fn", Translation::uniqued(), in_rulebook);
		HierarchyLocations::func(RULEBOOK_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_rulebook);

	location_requirement synoptic_rulebooks = HierarchyLocations::synoptic_submodule(rulebooks);
	HierarchyLocations::con(NUMBER_RULEBOOKS_CREATED_HL, I"NUMBER_RULEBOOKS_CREATED", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::con(RULEBOOK_VAR_CREATORS_HL, I"rulebook_var_creators", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::func(SLOW_LOOKUP_HL, I"slow_lookup_fn", Translation::to(I"MStack_GetRBVarCreator"), synoptic_rulebooks);
	HierarchyLocations::con(RULEBOOKS_ARRAY_HL, I"rulebooks_array", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::con(RULEBOOKNAMES_HL, I"RulebookNames", Translation::same(), synoptic_rulebooks);

@h Rules.

@e RULES_HAP
@e SHELL_FN_HL
@e RULE_FN_HL
@e EXTERIOR_RULE_HL
@e RESPONDER_FN_HL
@e RESPONSES_HAP
@e AS_CONSTANT_HL
@e AS_BLOCK_CONSTANT_HL
@e LAUNCHER_HL

@e RULEPRINTINGRULE_HL
@e RESPONSEDIVISIONS_HL

@<Establish rules@> =
	submodule_identity *rules = Packaging::register_submodule(I"rules");

	location_requirement local_rules = HierarchyLocations::local_submodule(rules);
	HierarchyLocations::ap(RULES_HAP, local_rules, I"rule", I"_rule");
		location_requirement in_rule = HierarchyLocations::any_package_of_type(I"_rule");
		HierarchyLocations::func(SHELL_FN_HL, I"shell_fn", Translation::generate_in(RULE_SHELL_ROUTINE_INAMEF), in_rule);
		HierarchyLocations::func(RULE_FN_HL, I"rule_fn", Translation::generate_in(PHRASE_INAMEF), in_rule);
		HierarchyLocations::con(EXTERIOR_RULE_HL, I"exterior_rule", Translation::uniqued(), in_rule);
		HierarchyLocations::func(RESPONDER_FN_HL, I"responder_fn", Translation::derive(RESPONDER_INAMEF), in_rule);
		HierarchyLocations::ap(RESPONSES_HAP, in_rule, I"response", I"_response");
			location_requirement in_response = HierarchyLocations::any_package_of_type(I"_response");
			HierarchyLocations::con(AS_CONSTANT_HL, I"as_constant", Translation::uniqued(), in_response);
			HierarchyLocations::con(AS_BLOCK_CONSTANT_HL, I"as_block_constant", Translation::uniqued(), in_response);
			HierarchyLocations::func(LAUNCHER_HL, I"launcher", Translation::uniqued(), in_response);

	location_requirement synoptic_rules = HierarchyLocations::synoptic_submodule(rules);
	HierarchyLocations::con(RESPONSEDIVISIONS_HL, I"ResponseDivisions", Translation::same(), synoptic_rules);
	HierarchyLocations::func(RULEPRINTINGRULE_HL, I"print_fn", Translation::to(I"RulePrintingRule"), synoptic_rules);

@h Tables.

@e TABLES_HAP
@e TABLE_DATA_HL
@e TABLE_COLUMNS_HAP
@e COLUMN_DATA_HL

@e TC_KOV_HL
@e TB_BLANKS_HL

@<Establish tables@> =
	submodule_identity *tables = Packaging::register_submodule(I"tables");

	location_requirement local_tables = HierarchyLocations::local_submodule(tables);
	HierarchyLocations::ap(TABLES_HAP, local_tables, I"table", I"_table");
		location_requirement in_table = HierarchyLocations::any_package_of_type(I"_table");
		HierarchyLocations::con(TABLE_DATA_HL, I"table_data", Translation::uniqued(), in_table);
		HierarchyLocations::ap(TABLE_COLUMNS_HAP, in_table, I"table_column", I"_table_column");
			location_requirement in_table_column = HierarchyLocations::any_package_of_type(I"_table_column");
			HierarchyLocations::con(COLUMN_DATA_HL, I"column_data", Translation::uniqued(), in_table_column);

	location_requirement synoptic_tables = HierarchyLocations::synoptic_submodule(tables);
	HierarchyLocations::con(TB_BLANKS_HL, I"TB_Blanks", Translation::same(), synoptic_tables);
	HierarchyLocations::func(TC_KOV_HL, I"weak_kind_ID_of_column_entry_fn", Translation::to(I"TC_KOV"), synoptic_tables);

@h Variables.

@e VARIABLES_HAP
@e VARIABLE_HL

@<Establish variables@> =
	submodule_identity *variables = Packaging::register_submodule(I"variables");

	location_requirement local_variables = HierarchyLocations::local_submodule(variables);
	HierarchyLocations::ap(VARIABLES_HAP, local_variables, I"variable", I"_variable");
		location_requirement in_variable = HierarchyLocations::any_package_of_type(I"_variable");
		HierarchyLocations::con(VARIABLE_HL, NULL, Translation::generate(VARIABLE_INAMEF), in_variable);

@h Enclosed matter.

@e LITERALS_HAP
@e TEXT_LITERAL_HL
@e LIST_LITERAL_HL
@e TEXT_SUBSTITUTION_HL
@e TEXT_SUBSTITUTION_FN_HL
@e PROPOSITIONS_HAP
@e PROPOSITION_HL
@e RTP_HL
@e BLOCK_CONSTANTS_HAP
@e BLOCK_CONSTANT_HL
@e BOX_QUOTATIONS_HAP
@e BOX_QUOTATION_FN_HL
@e TEXT_SUBSTITUTIONS_HAP

@<Establish enclosed matter@> =
	location_requirement in_any_enclosure = HierarchyLocations::any_enclosure();
	HierarchyLocations::ap(LITERALS_HAP, in_any_enclosure, I"literal", I"_literal");
		location_requirement in_literal = HierarchyLocations::any_package_of_type(I"_literal");
		HierarchyLocations::con(TEXT_LITERAL_HL, I"text", Translation::uniqued(), in_literal);
		HierarchyLocations::con(LIST_LITERAL_HL, I"list", Translation::uniqued(), in_literal);
		HierarchyLocations::con(TEXT_SUBSTITUTION_HL, I"ts_array", Translation::uniqued(), in_literal);
		HierarchyLocations::func(TEXT_SUBSTITUTION_FN_HL, I"ts_fn", Translation::uniqued(), in_literal);
	HierarchyLocations::ap(PROPOSITIONS_HAP, in_any_enclosure, I"proposition", I"_proposition");
		location_requirement in_proposition = HierarchyLocations::any_package_of_type(I"_proposition");
		HierarchyLocations::func(PROPOSITION_HL, I"prop", Translation::uniqued(), in_proposition);
	HierarchyLocations::ap(BLOCK_CONSTANTS_HAP, in_any_enclosure, I"block_constant", I"_block_constant");
		location_requirement in_block_constant = HierarchyLocations::any_package_of_type(I"_block_constant");
		HierarchyLocations::con(BLOCK_CONSTANT_HL, I"bc", Translation::uniqued(), in_block_constant);
	HierarchyLocations::ap(BOX_QUOTATIONS_HAP, in_any_enclosure, I"block_constant", I"_box_quotation");
		location_requirement in_box_quotation = HierarchyLocations::any_package_of_type(I"_box_quotation");
		HierarchyLocations::func(BOX_QUOTATION_FN_HL, I"quotation_fn", Translation::uniqued(), in_box_quotation);
	HierarchyLocations::con(RTP_HL, I"rtp", Translation::uniqued(), in_any_enclosure);

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
@e K_EXTERNAL_FILE_XPACKAGE
@e K_RULEBOOK_OUTCOME_XPACKAGE
@e K_RESPONSE_XPACKAGE
@e K_SCENE_XPACKAGE
@e V_COMMAND_PROMPT_XPACKAGE

@e NOTHING_HL
@e OBJECT_HL
@e TESTUSEOPTION_HL
@e PRINT_USE_OPTION_HL
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

@e PRINT_TABLE_HL
@e PRINT_RULEBOOK_OUTCOME_HL
@e PRINT_RESPONSE_HL
@e PRINT_FIGURE_NAME_HL
@e PRINT_SOUND_NAME_HL
@e PRINT_EXTERNAL_FILE_NAME_HL
@e NO_EXTERNAL_FILES_HL
@e TABLEOFEXTERNALFILES_HL
@e PRINT_SCENE_HL

@

@<The rest@> =
	location_requirement in_K_object = HierarchyLocations::this_exotic_package(K_OBJECT_XPACKAGE);
	HierarchyLocations::con(OBJECT_HL, I"Object", Translation::same(), in_K_object);
	HierarchyLocations::con(NOTHING_HL, I"nothing", Translation::same(), in_K_object);
	HierarchyLocations::con(CAPSHORTNAME_HL, I"cap_short_name", Translation::same(), in_K_object);

	location_requirement in_K_number = HierarchyLocations::this_exotic_package(K_NUMBER_XPACKAGE);
	HierarchyLocations::func(DECIMAL_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"DECIMAL_TOKEN_INNER"), in_K_number);

	location_requirement in_K_time = HierarchyLocations::this_exotic_package(K_TIME_XPACKAGE);
	HierarchyLocations::func(TIME_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"TIME_TOKEN_INNER"), in_K_time);

	location_requirement in_K_truth_state = HierarchyLocations::this_exotic_package(K_TRUTH_STATE_XPACKAGE);
	HierarchyLocations::func(TRUTH_STATE_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"TRUTH_STATE_TOKEN_INNER"), in_K_truth_state);

	location_requirement in_K_table = HierarchyLocations::this_exotic_package(K_TABLE_XPACKAGE);
	HierarchyLocations::con(TABLEOFTABLES_HL, I"TableOfTables", Translation::same(), in_K_table);
	HierarchyLocations::func(PRINT_TABLE_HL, I"print_fn", Translation::to(I"PrintTableName"), in_K_table);

	location_requirement in_K_verb = HierarchyLocations::this_exotic_package(K_VERB_XPACKAGE);
	HierarchyLocations::con(TABLEOFVERBS_HL, I"TableOfVerbs", Translation::same(), in_K_verb);

	location_requirement in_K_figure_name = HierarchyLocations::this_exotic_package(K_FIGURE_NAME_XPACKAGE);
	HierarchyLocations::con(RESOURCEIDSOFFIGURES_HL, I"ResourceIDsOfFigures", Translation::same(), in_K_figure_name);
	HierarchyLocations::func(PRINT_FIGURE_NAME_HL, I"print_fn", Translation::to(I"PrintFigureName"), in_K_figure_name);

	location_requirement in_K_sound_name = HierarchyLocations::this_exotic_package(K_SOUND_NAME_XPACKAGE);
	HierarchyLocations::con(RESOURCEIDSOFSOUNDS_HL, I"ResourceIDsOfSounds", Translation::same(), in_K_sound_name);
	HierarchyLocations::func(PRINT_SOUND_NAME_HL, I"print_fn", Translation::to(I"PrintSoundName"), in_K_sound_name);

	location_requirement in_K_use_option = HierarchyLocations::this_exotic_package(K_USE_OPTION_XPACKAGE);
	HierarchyLocations::con(NO_USE_OPTIONS_HL, I"NO_USE_OPTIONS", Translation::same(), in_K_use_option);
	HierarchyLocations::func(TESTUSEOPTION_HL, I"test_fn", Translation::to(I"TestUseOption"), in_K_use_option);
	HierarchyLocations::func(PRINT_USE_OPTION_HL, I"print_fn", Translation::to(I"PrintUseOption"), in_K_use_option);

	location_requirement in_V_command_prompt = HierarchyLocations::this_exotic_package(V_COMMAND_PROMPT_XPACKAGE);
	HierarchyLocations::func(COMMANDPROMPTTEXT_HL, I"command_prompt_text_fn", Translation::to(I"CommandPromptText"), in_V_command_prompt);

	location_requirement in_K_external_file = HierarchyLocations::this_exotic_package(K_EXTERNAL_FILE_XPACKAGE);
	HierarchyLocations::con(NO_EXTERNAL_FILES_HL, I"NO_EXTERNAL_FILES", Translation::same(), in_K_external_file);
	HierarchyLocations::con(TABLEOFEXTERNALFILES_HL, I"TableOfExternalFiles", Translation::same(), in_K_external_file);
	HierarchyLocations::func(PRINT_EXTERNAL_FILE_NAME_HL, I"print_fn", Translation::to(I"PrintExternalFileName"), in_K_external_file);

	location_requirement in_K_rulebook_outcome = HierarchyLocations::this_exotic_package(K_RULEBOOK_OUTCOME_XPACKAGE);
	HierarchyLocations::func(PRINT_RULEBOOK_OUTCOME_HL, I"print_fn", Translation::to(I"RulebookOutcomePrintingRule"), in_K_rulebook_outcome);

	location_requirement in_K_response = HierarchyLocations::this_exotic_package(K_RESPONSE_XPACKAGE);
	HierarchyLocations::func(PRINT_RESPONSE_HL, I"print_fn", Translation::to(I"PrintResponse"), in_K_response);

	location_requirement in_K_scene = HierarchyLocations::this_exotic_package(K_SCENE_XPACKAGE);
	HierarchyLocations::func(PRINT_SCENE_HL, I"print_fn", Translation::to(I"PrintSceneName"), in_K_scene);

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
	location_requirement template = HierarchyLocations::this_package(Hierarchy::template());
	HierarchyLocations::con(ACT_REQUESTER_HL, I"act_requester", Translation::same(), template);
	HierarchyLocations::con(ACTION_HL, I"action", Translation::same(), template);
	HierarchyLocations::con(ACTIONCURRENTLYHAPPENINGFLAG_HL, I"ActionCurrentlyHappeningFlag", Translation::same(), template);
	HierarchyLocations::con(ACTOR_HL, I"actor", Translation::same(), template);
	HierarchyLocations::con(ACTOR_LOCATION_HL, I"actor_location", Translation::same(), template);
	HierarchyLocations::con(ADJUSTPARAGRAPHPOINT_HL, I"AdjustParagraphPoint", Translation::same(), template);
	HierarchyLocations::con(ALLOWINSHOWME_HL, I"AllowInShowme", Translation::same(), template);
	HierarchyLocations::con(ANIMATE_HL, I"animate", Translation::same(), template);
	HierarchyLocations::con(ARGUMENTTYPEFAILED_HL, I"ArgumentTypeFailed", Translation::same(), template);
	HierarchyLocations::con(ARTICLEDESCRIPTORS_HL, I"ArticleDescriptors", Translation::same(), template);
	HierarchyLocations::con(AUXF_MAGIC_VALUE_HL, I"AUXF_MAGIC_VALUE", Translation::same(), template);
	HierarchyLocations::con(AUXF_STATUS_IS_CLOSED_HL, I"AUXF_STATUS_IS_CLOSED", Translation::same(), template);
	HierarchyLocations::con(BLKVALUECOPY_HL, I"BlkValueCopy", Translation::same(), template);
	HierarchyLocations::con(BLKVALUECOPYAZ_HL, I"BlkValueCopyAZ", Translation::same(), template);
	HierarchyLocations::con(BLKVALUECREATE_HL, I"BlkValueCreate", Translation::same(), template);
	HierarchyLocations::con(BLKVALUECREATEONSTACK_HL, I"BlkValueCreateOnStack", Translation::same(), template);
	HierarchyLocations::con(BLKVALUEERROR_HL, I"BlkValueError", Translation::same(), template);
	HierarchyLocations::con(BLKVALUEFREE_HL, I"BlkValueFree", Translation::same(), template);
	HierarchyLocations::con(BLKVALUEFREEONSTACK_HL, I"BlkValueFreeOnStack", Translation::same(), template);
	HierarchyLocations::con(BLKVALUEWRITE_HL, I"BlkValueWrite", Translation::same(), template);
	HierarchyLocations::con(C_STYLE_HL, I"c_style", Translation::same(), template);
	HierarchyLocations::con(CHECKKINDRETURNED_HL, I"CheckKindReturned", Translation::same(), template);
	HierarchyLocations::con(CLEARPARAGRAPHING_HL, I"ClearParagraphing", Translation::same(), template);
	HierarchyLocations::con(COMPONENT_CHILD_HL, I"component_child", Translation::same(), template);
	HierarchyLocations::con(COMPONENT_PARENT_HL, I"component_parent", Translation::same(), template);
	HierarchyLocations::con(COMPONENT_SIBLING_HL, I"component_sibling", Translation::same(), template);
	HierarchyLocations::con(CONSTANT_PACKED_TEXT_STORAGE_HL, I"CONSTANT_PACKED_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(CONSULT_FROM_HL, I"consult_from", Translation::same(), template);
	HierarchyLocations::con(CONSULT_WORDS_HL, I"consult_words", Translation::same(), template);
	HierarchyLocations::con(CONTAINER_HL, I"container", Translation::same(), template);
	HierarchyLocations::con(CUBEROOT_HL, I"CubeRoot", Translation::same(), template);
	HierarchyLocations::con(DA_NAME_HL, I"DA_Name", Translation::same(), template);
	HierarchyLocations::con(DB_RULE_HL, I"DB_Rule", Translation::same(), template);
	HierarchyLocations::con(DEADFLAG_HL, I"deadflag", Translation::same(), template);
	HierarchyLocations::con(DEBUG_RULES_HL, I"debug_rules", Translation::same(), template);
	HierarchyLocations::con(DEBUG_SCENES_HL, I"debug_scenes", Translation::same(), template);
	HierarchyLocations::con(DECIMALNUMBER_HL, I"DecimalNumber", Translation::same(), template);
	HierarchyLocations::con(DEFERRED_CALLING_LIST_HL, I"deferred_calling_list", Translation::same(), template);
	HierarchyLocations::con(DETECTPLURALWORD_HL, I"DetectPluralWord", Translation::same(), template);
	HierarchyLocations::con(DIGITTOVALUE_HL, I"DigitToValue", Translation::same(), template);
	HierarchyLocations::con(DIVIDEPARAGRAPHPOINT_HL, I"DivideParagraphPoint", Translation::same(), template);
	HierarchyLocations::con(DOUBLEHASHSETRELATIONHANDLER_HL, I"DoubleHashSetRelationHandler", Translation::same(), template);
	HierarchyLocations::con(DURINGSCENEMATCHING_HL, I"DuringSceneMatching", Translation::same(), template);
	HierarchyLocations::con(ELEMENTARY_TT_HL, I"ELEMENTARY_TT", Translation::same(), template);
	HierarchyLocations::con(EMPTY_TABLE_HL, I"TheEmptyTable", Translation::same(), template);
	HierarchyLocations::con(EMPTY_TEXT_PACKED_HL, I"EMPTY_TEXT_PACKED", Translation::same(), template);
	HierarchyLocations::con(EMPTY_TEXT_VALUE_HL, I"EMPTY_TEXT_VALUE", Translation::same(), template);
	HierarchyLocations::con(EMPTYRELATIONHANDLER_HL, I"EmptyRelationHandler", Translation::same(), template);
	HierarchyLocations::con(ENGLISH_BIT_HL, I"ENGLISH_BIT", Translation::same(), template);
	HierarchyLocations::con(ETYPE_HL, I"etype", Translation::same(), template);
	HierarchyLocations::con(EXISTSTABLELOOKUPCORR_HL, I"ExistsTableLookUpCorr", Translation::same(), template);
	HierarchyLocations::con(EXISTSTABLELOOKUPENTRY_HL, I"ExistsTableLookUpEntry", Translation::same(), template);
	HierarchyLocations::con(EXISTSTABLEROWCORR_HL, I"ExistsTableRowCorr", Translation::same(), template);
	HierarchyLocations::con(FLOATPARSE_HL, I"FloatParse", Translation::same(), template);
	HierarchyLocations::con(FOLLOWRULEBOOK_HL, I"FollowRulebook", Translation::same(), template);
	HierarchyLocations::con(formal_par0_HL, I"formal_par0", Translation::same(), template);
	HierarchyLocations::con(formal_par1_HL, I"formal_par1", Translation::same(), template);
	HierarchyLocations::con(formal_par2_HL, I"formal_par2", Translation::same(), template);
	HierarchyLocations::con(formal_par3_HL, I"formal_par3", Translation::same(), template);
	HierarchyLocations::con(formal_par4_HL, I"formal_par4", Translation::same(), template);
	HierarchyLocations::con(formal_par5_HL, I"formal_par5", Translation::same(), template);
	HierarchyLocations::con(formal_par6_HL, I"formal_par6", Translation::same(), template);
	HierarchyLocations::con(formal_par7_HL, I"formal_par7", Translation::same(), template);
	HierarchyLocations::con(FORMAL_RV_HL, I"formal_rv", Translation::same(), template);
	HierarchyLocations::con(FOUND_EVERYWHERE_HL, I"FoundEverywhere", Translation::same(), template);
	HierarchyLocations::con(GENERATERANDOMNUMBER_HL, I"GenerateRandomNumber", Translation::same(), template);
	HierarchyLocations::con(GENERICVERBSUB_HL, I"GenericVerbSub", Translation::same(), template);
	HierarchyLocations::con(GETGNAOFOBJECT_HL, I"GetGNAOfObject", Translation::same(), template);
	HierarchyLocations::con(GPR_FAIL_HL, I"GPR_FAIL", Translation::same(), template);
	HierarchyLocations::con(GPR_NUMBER_HL, I"GPR_NUMBER", Translation::same(), template);
	HierarchyLocations::con(GPR_PREPOSITION_HL, I"GPR_PREPOSITION", Translation::same(), template);
	HierarchyLocations::con(GPR_TT_HL, I"GPR_TT", Translation::same(), template);
	HierarchyLocations::con(GPROPERTY_HL, I"GProperty", Translation::same(), template);
	HierarchyLocations::con(HASHLISTRELATIONHANDLER_HL, I"HashListRelationHandler", Translation::same(), template);
	HierarchyLocations::con(I7SFRAME_HL, I"I7SFRAME", Translation::same(), template);
	HierarchyLocations::con(INDENT_BIT_HL, I"INDENT_BIT", Translation::same(), template);
	HierarchyLocations::con(INP1_HL, I"inp1", Translation::same(), template);
	HierarchyLocations::con(INP2_HL, I"inp2", Translation::same(), template);
	HierarchyLocations::con(INTEGERDIVIDE_HL, I"IntegerDivide", Translation::same(), template);
	HierarchyLocations::con(INTEGERREMAINDER_HL, I"IntegerRemainder", Translation::same(), template);
	HierarchyLocations::con(INVENTORY_STAGE_HL, I"inventory_stage", Translation::same(), template);
	HierarchyLocations::con(KEEP_SILENT_HL, I"keep_silent", Translation::same(), template);
	HierarchyLocations::con(KINDATOMIC_HL, I"KindAtomic", Translation::same(), template);
	HierarchyLocations::con(LATEST_RULE_RESULT_HL, I"latest_rule_result", Translation::same(), template);
	HierarchyLocations::con(LIST_ITEM_BASE_HL, I"LIST_ITEM_BASE", Translation::same(), template);
	HierarchyLocations::con(LIST_ITEM_KOV_F_HL, I"LIST_ITEM_KOV_F", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_DESC_HL, I"LIST_OF_TY_Desc", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_GETITEM_HL, I"LIST_OF_TY_GetItem", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_GETLENGTH_HL, I"LIST_OF_TY_GetLength", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_INSERTITEM_HL, I"LIST_OF_TY_InsertItem", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_SAY_HL, I"LIST_OF_TY_Say", Translation::same(), template);
	HierarchyLocations::con(LIST_OF_TY_SETLENGTH_HL, I"LIST_OF_TY_SetLength", Translation::same(), template);
	HierarchyLocations::con(LOCALPARKING_HL, I"LocalParking", Translation::same(), template);
	HierarchyLocations::con(LOCATION_HL, I"location", Translation::same(), template);
	HierarchyLocations::con(LOCATIONOF_HL, I"LocationOf", Translation::same(), template);
	HierarchyLocations::con(LOOPOVERSCOPE_HL, I"LoopOverScope", Translation::same(), template);
	HierarchyLocations::con(LOS_RV_HL, I"los_rv", Translation::same(), template);
	HierarchyLocations::con(MSTACK_HL, I"MStack", Translation::same(), template);
	HierarchyLocations::con(MSTVO_HL, I"MstVO", Translation::same(), template);
	HierarchyLocations::con(MSTVON_HL, I"MstVON", Translation::same(), template);
	HierarchyLocations::con(NAME_HL, I"name", Translation::same(), template);
	HierarchyLocations::con(NEWLINE_BIT_HL, I"NEWLINE_BIT", Translation::same(), template);
	HierarchyLocations::con(NEXTBEST_ETYPE_HL, I"nextbest_etype", Translation::same(), template);
	HierarchyLocations::con(NEXTWORDSTOPPED_HL, I"NextWordStopped", Translation::same(), template);
	HierarchyLocations::con(NOARTICLE_BIT_HL, I"NOARTICLE_BIT", Translation::same(), template);
	HierarchyLocations::con(NOTINCONTEXTPE_HL, I"NOTINCONTEXT_PE", Translation::same(), template);
	HierarchyLocations::con(NOUN_HL, I"noun", Translation::same(), template);
	HierarchyLocations::con(NUMBER_TY_ABS_HL, I"NUMBER_TY_Abs", Translation::same(), template);
	HierarchyLocations::con(NUMBER_TY_TO_REAL_NUMBER_TY_HL, I"NUMBER_TY_to_REAL_NUMBER_TY", Translation::same(), template);
	HierarchyLocations::con(NUMBER_TY_TO_TIME_TY_HL, I"NUMBER_TY_to_TIME_TY", Translation::same(), template);
	HierarchyLocations::con(OTOVRELROUTETO_HL, I"OtoVRelRouteTo", Translation::same(), template);
	HierarchyLocations::con(PACKED_TEXT_STORAGE_HL, I"PACKED_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(PARACONTENT_HL, I"ParaContent", Translation::same(), template);
	HierarchyLocations::con(PARAMETER_VALUE_HL, I"parameter_value", Translation::same(), template);
	HierarchyLocations::con(PARSED_NUMBER_HL, I"parsed_number", Translation::same(), template);
	HierarchyLocations::con(PARSER_ACTION_HL, I"parser_action", Translation::same(), template);
	HierarchyLocations::con(PARSER_ONE_HL, I"parser_one", Translation::same(), template);
	HierarchyLocations::con(PARSER_TRACE_HL, I"parser_trace", Translation::same(), template);
	HierarchyLocations::con(PARSER_TWO_HL, I"parser_two", Translation::same(), template);
	HierarchyLocations::con(PARSERERROR_HL, I"ParserError", Translation::same(), template);
	HierarchyLocations::con(PARSETOKENSTOPPED_HL, I"ParseTokenStopped", Translation::same(), template);
	HierarchyLocations::con(PAST_CHRONOLOGICAL_RECORD_HL, I"past_chronological_record", Translation::same(), template);
	HierarchyLocations::con(PLACEINSCOPE_HL, I"PlaceInScope", Translation::same(), template);
	HierarchyLocations::con(PLAYER_HL, I"player", Translation::same(), template);
	HierarchyLocations::con(PNTOVP_HL, I"PNToVP", Translation::same(), template);
	HierarchyLocations::con(PRESENT_CHRONOLOGICAL_RECORD_HL, I"present_chronological_record", Translation::same(), template);
	HierarchyLocations::con(PRINTORRUN_HL, I"PrintOrRun", Translation::same(), template);
	HierarchyLocations::con(PRIOR_NAMED_LIST_HL, I"prior_named_list", Translation::same(), template);
	HierarchyLocations::con(PRIOR_NAMED_LIST_GENDER_HL, I"prior_named_list_gender", Translation::same(), template);
	HierarchyLocations::con(PRIOR_NAMED_NOUN_HL, I"prior_named_noun", Translation::same(), template);
	HierarchyLocations::con(PROPERTY_LOOP_SIGN_HL, I"property_loop_sign", Translation::same(), template);
	HierarchyLocations::con(PROPERTY_TO_BE_TOTALLED_HL, I"property_to_be_totalled", Translation::same(), template);
	HierarchyLocations::con(REAL_LOCATION_HL, I"real_location", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_ABS_HL, I"REAL_NUMBER_TY_Abs", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_APPROXIMATE_HL, I"REAL_NUMBER_TY_Approximate", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_COMPARE_HL, I"REAL_NUMBER_TY_Compare", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_CUBE_ROOT_HL, I"REAL_NUMBER_TY_Cube_Root", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_DIVIDE_HL, I"REAL_NUMBER_TY_Divide", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_MINUS_HL, I"REAL_NUMBER_TY_Minus", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_NAN_HL, I"REAL_NUMBER_TY_Nan", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_NEGATE_HL, I"REAL_NUMBER_TY_Negate", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_PLUS_HL, I"REAL_NUMBER_TY_Plus", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_POW_HL, I"REAL_NUMBER_TY_Pow", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_REMAINDER_HL, I"REAL_NUMBER_TY_Remainder", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_ROOT_HL, I"REAL_NUMBER_TY_Root", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_SAY_HL, I"REAL_NUMBER_TY_Say", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_TIMES_HL, I"REAL_NUMBER_TY_Times", Translation::same(), template);
	HierarchyLocations::con(REAL_NUMBER_TY_TO_NUMBER_TY_HL, I"REAL_NUMBER_TY_to_NUMBER_TY", Translation::same(), template);
	HierarchyLocations::con(REASON_THE_ACTION_FAILED_HL, I"reason_the_action_failed", Translation::same(), template);
	HierarchyLocations::con(RELATION_EMPTYEQUIV_HL, I"Relation_EmptyEquiv", Translation::same(), template);
	HierarchyLocations::con(RELATION_EMPTYOTOO_HL, I"Relation_EmptyOtoO", Translation::same(), template);
	HierarchyLocations::con(RELATION_EMPTYVTOV_HL, I"Relation_EmptyVtoV", Translation::same(), template);
	HierarchyLocations::con(RELATION_RSHOWOTOO_HL, I"Relation_RShowOtoO", Translation::same(), template);
	HierarchyLocations::con(RELATION_SHOWEQUIV_HL, I"Relation_ShowEquiv", Translation::same(), template);
	HierarchyLocations::con(RELATION_SHOWOTOO_HL, I"Relation_ShowOtoO", Translation::same(), template);
	HierarchyLocations::con(RELATION_SHOWVTOV_HL, I"Relation_ShowVtoV", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_NAME_HL, I"RELATION_TY_Name", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_OTOOADJECTIVE_HL, I"RELATION_TY_OToOAdjective", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_OTOVADJECTIVE_HL, I"RELATION_TY_OToVAdjective", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_SYMMETRICADJECTIVE_HL, I"RELATION_TY_SymmetricAdjective", Translation::same(), template);
	HierarchyLocations::con(RELATION_TY_VTOOADJECTIVE_HL, I"RELATION_TY_VToOAdjective", Translation::same(), template);
	HierarchyLocations::con(RELATIONTEST_HL, I"RelationTest", Translation::same(), template);
	HierarchyLocations::con(RELFOLLOWVECTOR_HL, I"RelFollowVector", Translation::same(), template);
	HierarchyLocations::con(RELS_EMPTY_HL, I"RELS_EMPTY", Translation::same(), template);
	HierarchyLocations::con(RESPONSEVIAACTIVITY_HL, I"ResponseViaActivity", Translation::same(), template);
	HierarchyLocations::con(RLANY_CAN_GET_X_HL, I"RLANY_CAN_GET_X", Translation::same(), template);
	HierarchyLocations::con(RLANY_CAN_GET_Y_HL, I"RLANY_CAN_GET_Y", Translation::same(), template);
	HierarchyLocations::con(RLANY_GET_X_HL, I"RLANY_GET_X", Translation::same(), template);
	HierarchyLocations::con(RLIST_ALL_X_HL, I"RLIST_ALL_X", Translation::same(), template);
	HierarchyLocations::con(RLIST_ALL_Y_HL, I"RLIST_ALL_Y", Translation::same(), template);
	HierarchyLocations::con(RLNGETF_HL, I"RlnGetF", Translation::same(), template);
	HierarchyLocations::con(ROUNDOFFTIME_HL, I"RoundOffTime", Translation::same(), template);
	HierarchyLocations::con(ROUTINEFILTER_TT_HL, I"ROUTINE_FILTER_TT", Translation::same(), template);
	HierarchyLocations::con(RR_STORAGE_HL, I"RR_STORAGE", Translation::same(), template);
	HierarchyLocations::con(RTP_RELKINDVIOLATION_HL, I"RTP_RELKINDVIOLATION", Translation::same(), template);
	HierarchyLocations::con(RTP_RELMINIMAL_HL, I"RTP_RELMINIMAL", Translation::same(), template);
	HierarchyLocations::con(RULEBOOKFAILS_HL, I"RulebookFails", Translation::same(), template);
	HierarchyLocations::con(RULEBOOKPARBREAK_HL, I"RulebookParBreak", Translation::same(), template);
	HierarchyLocations::con(RULEBOOKSUCCEEDS_HL, I"RulebookSucceeds", Translation::same(), template);
	HierarchyLocations::con(RUNTIMEPROBLEM_HL, I"RunTimeProblem", Translation::same(), template);
	HierarchyLocations::con(SAY__N_HL, I"say__n", Translation::same(), template);
	HierarchyLocations::con(SAY__P_HL, I"say__p", Translation::same(), template);
	HierarchyLocations::con(SAY__PC_HL, I"say__pc", Translation::same(), template);
	HierarchyLocations::con(SCENE_ENDED_HL, I"scene_ended", Translation::same(), template);
	HierarchyLocations::con(SCENE_ENDINGS_HL, I"scene_endings", Translation::same(), template);
	HierarchyLocations::con(SCENE_LATEST_ENDING_HL, I"scene_latest_ending", Translation::same(), template);
	HierarchyLocations::con(SCENE_STARTED_HL, I"scene_started", Translation::same(), template);
	HierarchyLocations::con(SCENE_STATUS_HL, I"scene_status", Translation::same(), template);
	HierarchyLocations::con(SCOPE_STAGE_HL, I"scope_stage", Translation::same(), template);
	HierarchyLocations::con(SCOPE_TT_HL, I"SCOPE_TT", Translation::same(), template);
	HierarchyLocations::con(SECOND_HL, I"second", Translation::same(), template);
	HierarchyLocations::con(SHORT_NAME_HL, I"short_name", Translation::same(), template);
	HierarchyLocations::con(SIGNEDCOMPARE_HL, I"SignedCompare", Translation::same(), template);
	HierarchyLocations::con(SPECIAL_WORD_HL, I"special_word", Translation::same(), template);
	HierarchyLocations::con(SQUAREROOT_HL, I"SquareRoot", Translation::same(), template);
	HierarchyLocations::con(STACKFRAMECREATE_HL, I"StackFrameCreate", Translation::same(), template);
	HierarchyLocations::con(STORED_ACTION_TY_CURRENT_HL, I"STORED_ACTION_TY_Current", Translation::same(), template);
	HierarchyLocations::con(STORED_ACTION_TY_TRY_HL, I"STORED_ACTION_TY_Try", Translation::same(), template);
	HierarchyLocations::con(STORY_TENSE_HL, I"story_tense", Translation::same(), template);
	HierarchyLocations::con(SUPPORTER_HL, I"supporter", Translation::same(), template);
	HierarchyLocations::con(SUPPRESS_SCOPE_LOOPS_HL, I"suppress_scope_loops", Translation::same(), template);
	HierarchyLocations::con(SUPPRESS_TEXT_SUBSTITUTION_HL, I"suppress_text_substitution", Translation::same(), template);
	HierarchyLocations::con(TABLE_NOVALUE_HL, I"TABLE_NOVALUE", Translation::same(), template);
	HierarchyLocations::con(TABLELOOKUPCORR_HL, I"TableLookUpCorr", Translation::same(), template);
	HierarchyLocations::con(TABLELOOKUPENTRY_HL, I"TableLookUpEntry", Translation::same(), template);
	HierarchyLocations::con(TESTACTIONBITMAP_HL, I"TestActionBitmap", Translation::same(), template);
	HierarchyLocations::con(TESTACTIVITY_HL, I"TestActivity", Translation::same(), template);
	HierarchyLocations::con(TESTREGIONALCONTAINMENT_HL, I"TestRegionalContainment", Translation::same(), template);
	HierarchyLocations::con(TESTSCOPE_HL, I"TestScope", Translation::same(), template);
	HierarchyLocations::con(TESTSTART_HL, I"TestStart", Translation::same(), template);
	HierarchyLocations::con(TEXT_TY_COMPARE_HL, I"TEXT_TY_Compare", Translation::same(), template);
	HierarchyLocations::con(TEXT_TY_EXPANDIFPERISHABLE_HL, I"TEXT_TY_ExpandIfPerishable", Translation::same(), template);
	HierarchyLocations::con(TEXT_TY_SAY_HL, I"TEXT_TY_Say", Translation::same(), template);
	HierarchyLocations::con(THE_TIME_HL, I"the_time", Translation::same(), template);
	HierarchyLocations::con(THEEMPTYTABLE_HL, I"TheEmptyTable", Translation::same(), template);
	HierarchyLocations::con(THEN1__WD_HL, I"THEN1__WD", Translation::same(), template);
	HierarchyLocations::con(TIMESACTIONHASBEENHAPPENING_HL, I"TimesActionHasBeenHappening", Translation::same(), template);
	HierarchyLocations::con(TIMESACTIONHASHAPPENED_HL, I"TimesActionHasHappened", Translation::same(), template);
	HierarchyLocations::con(TRYACTION_HL, I"TryAction", Translation::same(), template);
	HierarchyLocations::con(TRYGIVENOBJECT_HL, I"TryGivenObject", Translation::same(), template);
	HierarchyLocations::con(TURNSACTIONHASBEENHAPPENING_HL, I"TurnsActionHasBeenHappening", Translation::same(), template);
	HierarchyLocations::con(UNDERSTAND_AS_MISTAKE_NUMBER_HL, I"understand_as_mistake_number", Translation::same(), template);
	HierarchyLocations::con(UNICODE_TEMP_HL, I"unicode_temp", Translation::same(), template);
	HierarchyLocations::con(VTOORELROUTETO_HL, I"VtoORelRouteTo", Translation::same(), template);
	HierarchyLocations::con(VTOVRELROUTETO_HL, I"VtoVRelRouteTo", Translation::same(), template);
	HierarchyLocations::con(WHEN_SCENE_BEGINS_HL, I"WHEN_SCENE_BEGINS_RB", Translation::same(), template);
	HierarchyLocations::con(WHEN_SCENE_ENDS_HL, I"WHEN_SCENE_ENDS_RB", Translation::same(), template);
	HierarchyLocations::con(WN_HL, I"wn", Translation::same(), template);
	HierarchyLocations::con(WORDADDRESS_HL, I"WordAddress", Translation::same(), template);
	HierarchyLocations::con(WORDINPROPERTY_HL, I"WordInProperty", Translation::same(), template);
	HierarchyLocations::con(WORDLENGTH_HL, I"WordLength", Translation::same(), template);

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
		case K_EXTERNAL_FILE_XPACKAGE: return Kinds::Behaviour::package(K_external_file);
		case K_RULEBOOK_OUTCOME_XPACKAGE: return Kinds::Behaviour::package(K_rulebook_outcome);
		case K_RESPONSE_XPACKAGE: return Kinds::Behaviour::package(K_response);
		case K_SCENE_XPACKAGE: return Kinds::Behaviour::package(K_scene);
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
		HierarchyLocations::con(-1, name, Translation::same(), HierarchyLocations::this_package(Hierarchy::template()));
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
	return HierarchyLocations::attach_new_package(C, NULL, hap_id);
}

package_request *Hierarchy::synoptic_package(int hap_id) {
	return HierarchyLocations::attach_new_package(NULL, NULL, hap_id);
}

package_request *Hierarchy::local_package(int hap_id) {
	return HierarchyLocations::attach_new_package(Modules::find(current_sentence), NULL, hap_id);
}

package_request *Hierarchy::package_in_enclosure(int hap_id) {
	return HierarchyLocations::attach_new_package(NULL, Packaging::current_enclosure(), hap_id);
}

package_request *Hierarchy::package_within(int hap_id, package_request *super) {
	return HierarchyLocations::attach_new_package(NULL, super, hap_id);
}

inter_name *Hierarchy::make_iname_in(int id, package_request *P) {
	return HierarchyLocations::find_in_package(id, P, EMPTY_WORDING, NULL, NULL);
}

inter_name *Hierarchy::derive_iname_in(int id, inter_name *derive_from, package_request *P) {
	return HierarchyLocations::find_in_package(id, P, EMPTY_WORDING, NULL, derive_from);
}

inter_name *Hierarchy::make_localised_iname_in(int id, package_request *P, compilation_module *C) {
	return HierarchyLocations::find_in_package(id, P, EMPTY_WORDING, C, NULL);
}

inter_name *Hierarchy::make_block_iname(package_request *P) {
	return Packaging::supply_iname(P, 0);
}

inter_name *Hierarchy::make_kernel_iname(package_request *P) {
	inter_name *kernel_name = Packaging::supply_iname(P, 1);
	InterNames::set_flag(kernel_name, MAKE_NAME_UNIQUE);
	return kernel_name;
}

inter_name *Hierarchy::make_iname_with_memo(int id, package_request *P, wording W) {
	return HierarchyLocations::find_in_package(id, P, W, NULL, NULL);
}

package_request *Hierarchy::make_package_in(int id, package_request *P) {
	return HierarchyLocations::package_in_package(id, P);
}

package_request *Hierarchy::home_for_weak_type_IDs(void) {
	return home_for_weak_type_IDs.this_mundane_package;
}
