[Hierarchy::] Hierarchy.

@

@e BOGUS_HAP from 0

=
void Hierarchy::establish(inter_tree *I) {
	@<Establish basics@>;
	@<Establish modules@>;
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

@e SELF_HL from 0
@e DEBUG_HL
@e TARGET_ZCODE_HL
@e TARGET_GLULX_HL
@e INDIV_PROP_START_HL
@e DICT_WORD_SIZE_HL
@e WORDSIZE_HL
@e NULL_HL
@e WORD_HIGHBIT_HL
@e WORD_NEXTTOHIGHBIT_HL
@e IMPROBABLE_VALUE_HL
@e REPARSE_CODE_HL
@e MAX_POSITIVE_NUMBER_HL
@e MIN_NEGATIVE_NUMBER_HL
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

	location_requirement generic_basics = HierarchyLocations::generic_submodule(I, basics);
	HierarchyLocations::con(I, NULL_HL, I"NULL", Translation::same(), generic_basics);
	HierarchyLocations::con(I, WORD_HIGHBIT_HL, I"WORD_HIGHBIT", Translation::same(), generic_basics);
	HierarchyLocations::con(I, WORD_NEXTTOHIGHBIT_HL, I"WORD_NEXTTOHIGHBIT", Translation::same(), generic_basics);
	HierarchyLocations::con(I, IMPROBABLE_VALUE_HL, I"IMPROBABLE_VALUE", Translation::same(), generic_basics);
	HierarchyLocations::con(I, REPARSE_CODE_HL, I"REPARSE_CODE", Translation::same(), generic_basics);
	HierarchyLocations::con(I, MAX_POSITIVE_NUMBER_HL, I"MAX_POSITIVE_NUMBER", Translation::same(), generic_basics);
	HierarchyLocations::con(I, MIN_NEGATIVE_NUMBER_HL, I"MIN_NEGATIVE_NUMBER", Translation::same(), generic_basics);
	HierarchyLocations::con(I, CAP_SHORT_NAME_EXISTS_HL, I"CAP_SHORT_NAME_EXISTS", Translation::same(), generic_basics);
	HierarchyLocations::con(I, NI_BUILD_COUNT_HL, I"NI_BUILD_COUNT", Translation::same(), generic_basics);
	HierarchyLocations::con(I, RANKING_TABLE_HL, I"RANKING_TABLE", Translation::same(), generic_basics);
	HierarchyLocations::con(I, PLUGIN_FILES_HL, I"PLUGIN_FILES", Translation::same(), generic_basics);
	HierarchyLocations::con(I, MAX_WEAK_ID_HL, I"MAX_WEAK_ID", Translation::same(), generic_basics);
	HierarchyLocations::con(I, NO_VERB_VERB_DEFINED_HL, I"NO_VERB_VERB_DEFINED", Translation::same(), generic_basics);
	HierarchyLocations::con(I, NO_TEST_SCENARIOS_HL, I"NO_TEST_SCENARIOS", Translation::same(), generic_basics);
	HierarchyLocations::con(I, MEMORY_HEAP_SIZE_HL, I"MEMORY_HEAP_SIZE", Translation::same(), generic_basics);

	location_requirement synoptic_basics = HierarchyLocations::synoptic_submodule(I, basics);
	HierarchyLocations::con(I, CCOUNT_QUOTATIONS_HL, I"CCOUNT_QUOTATIONS", Translation::same(), synoptic_basics);
	HierarchyLocations::con(I, MAX_FRAME_SIZE_NEEDED_HL, I"MAX_FRAME_SIZE_NEEDED", Translation::same(), synoptic_basics);
	HierarchyLocations::con(I, RNG_SEED_AT_START_OF_PLAY_HL, I"RNG_SEED_AT_START_OF_PLAY", Translation::same(), synoptic_basics);

	location_requirement veneer = HierarchyLocations::this_package(Site::veneer_request(I));
	HierarchyLocations::con(I, SELF_HL, I"self", Translation::same(), veneer);
	HierarchyLocations::con(I, DEBUG_HL, I"DEBUG", Translation::same(), veneer);
	HierarchyLocations::con(I, TARGET_ZCODE_HL, I"TARGET_ZCODE", Translation::same(), veneer);
	HierarchyLocations::con(I, TARGET_GLULX_HL, I"TARGET_GLULX", Translation::same(), veneer);
	HierarchyLocations::con(I, DICT_WORD_SIZE_HL, I"DICT_WORD_SIZE", Translation::same(), veneer);
	HierarchyLocations::con(I, WORDSIZE_HL, I"WORDSIZE", Translation::same(), veneer);
	HierarchyLocations::con(I, INDIV_PROP_START_HL, I"INDIV_PROP_START", Translation::same(), veneer);

@h Modules.

@e EXT_TITLE_HMD from 0
@e EXT_AUTHOR_HMD
@e EXT_VERSION_HMD

@<Establish modules@> =
	location_requirement in_module = HierarchyLocations::any_package_of_type(I"_module");
	HierarchyLocations::metadata(I, EXT_TITLE_HMD, in_module, I"`title");
	HierarchyLocations::metadata(I, EXT_AUTHOR_HMD, in_module, I"`author");
	HierarchyLocations::metadata(I, EXT_VERSION_HMD, in_module, I"`version");

@h Actions.

@e ACTIONS_HAP
@e ACTION_NAME_HMD
@e ACTION_BASE_NAME_HL
@e WAIT_HL
@e TRANSLATED_BASE_NAME_HL
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
@e SACTIONS_HAP
@e MISTAKEACTIONPACKAGE_HL
@e MISTAKEACTION_HL
@e MISTAKEACTIONSUB_HL

@<Establish actions@> =
	submodule_identity *actions = Packaging::register_submodule(I"actions");

	location_requirement local_actions = HierarchyLocations::local_submodule(actions);
	HierarchyLocations::ap(I, ACTIONS_HAP, local_actions, I"action", I"_action");
		location_requirement in_action = HierarchyLocations::any_package_of_type(I"_action");
		HierarchyLocations::metadata(I, ACTION_NAME_HMD, in_action, I"`name");
		HierarchyLocations::con(I, ACTION_BASE_NAME_HL, I"A", Translation::uniqued(), in_action);
		HierarchyLocations::con(I, WAIT_HL, I"Wait", Translation::same(), in_action);
		HierarchyLocations::con(I, TRANSLATED_BASE_NAME_HL, NULL, Translation::imposed(), in_action);
		HierarchyLocations::con(I, DOUBLE_SHARP_NAME_HL, NULL, Translation::prefix(I"##"), in_action);
		HierarchyLocations::func(I, PERFORM_FN_HL, I"perform_fn", Translation::suffix(I"Sub"), in_action);
		HierarchyLocations::package(I, CHECK_RB_HL, I"check_rb", I"_rulebook", in_action);
		HierarchyLocations::package(I, CARRY_OUT_RB_HL, I"carry_out_rb", I"_rulebook", in_action);
		HierarchyLocations::package(I, REPORT_RB_HL, I"report_rb", I"_rulebook", in_action);
		HierarchyLocations::func(I, ACTION_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_action);

	location_requirement synoptic_actions = HierarchyLocations::synoptic_submodule(I, actions);
	HierarchyLocations::con(I, ACTIONCODING_HL, I"ActionCoding", Translation::same(), synoptic_actions);
	HierarchyLocations::con(I, ACTIONDATA_HL, I"ActionData", Translation::same(), synoptic_actions);
	HierarchyLocations::con(I, ACTIONHAPPENED_HL, I"ActionHappened", Translation::same(), synoptic_actions);
	HierarchyLocations::con(I, AD_RECORDS_HL, I"AD_RECORDS", Translation::same(), synoptic_actions);
	HierarchyLocations::con(I, CCOUNT_ACTION_NAME_HL, I"CCOUNT_ACTION_NAME", Translation::same(), synoptic_actions);
	HierarchyLocations::func(I, DB_ACTION_DETAILS_HL, I"DB_Action_Details_fn", Translation::to(I"DB_Action_Details"), synoptic_actions);
	HierarchyLocations::ap(I, SACTIONS_HAP, synoptic_actions, I"action", I"_action");
	HierarchyLocations::package(I, MISTAKEACTIONPACKAGE_HL, I"mistake_action", I"_action", synoptic_actions);
	HierarchyLocations::con(I, MISTAKEACTION_HL, I"##MistakeAction", Translation::same(), in_action);
	HierarchyLocations::func(I, MISTAKEACTIONSUB_HL, I"MistakeActionSub_fn", Translation::to(I"MistakeActionSub"), in_action);

@h Activities.

@e ACTIVITIES_HAP
@e ACTIVITY_NAME_HMD
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
	HierarchyLocations::ap(I, ACTIVITIES_HAP, local_activities, I"activity", I"_activity");
		location_requirement in_activity = HierarchyLocations::any_package_of_type(I"_activity");
		HierarchyLocations::metadata(I, ACTIVITY_NAME_HMD, in_activity, I"`name");
		HierarchyLocations::con(I, ACTIVITY_HL, NULL, Translation::generate(I"V"), in_activity);
		HierarchyLocations::package(I, BEFORE_RB_HL, I"before_rb", I"_rulebook", in_activity);
		HierarchyLocations::package(I, FOR_RB_HL, I"for_rb", I"_rulebook", in_activity);
		HierarchyLocations::package(I, AFTER_RB_HL, I"after_rb", I"_rulebook", in_activity);
		HierarchyLocations::func(I, ACTIVITY_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_activity);

	location_requirement synoptic_activities = HierarchyLocations::synoptic_submodule(I, activities);
	HierarchyLocations::con(I, ACTIVITY_AFTER_RULEBOOKS_HL, I"Activity_after_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(I, ACTIVITY_ATB_RULEBOOKS_HL, I"Activity_atb_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(I, ACTIVITY_BEFORE_RULEBOOKS_HL, I"Activity_before_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(I, ACTIVITY_FOR_RULEBOOKS_HL, I"Activity_for_rulebooks", Translation::same(), synoptic_activities);
	HierarchyLocations::con(I, ACTIVITY_VAR_CREATORS_HL, I"activity_var_creators", Translation::same(), synoptic_activities);

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
	HierarchyLocations::ap(I, ADJECTIVES_HAP, local_adjectives, I"adjective", I"_adjective");
		location_requirement in_adjective = HierarchyLocations::any_package_of_type(I"_adjective");
		HierarchyLocations::con(I, ADJECTIVE_HL, I"adjective", Translation::uniqued(), in_adjective);
		HierarchyLocations::ap(I, ADJECTIVE_TASKS_HAP, in_adjective, I"adjective_task", I"_adjective_task");
			location_requirement in_adjective_task = HierarchyLocations::any_package_of_type(I"_adjective_task");
			HierarchyLocations::func(I, TASK_FN_HL, I"task_fn", Translation::uniqued(), in_adjective_task);
	HierarchyLocations::ap(I, ADJECTIVE_MEANINGS_HAP, local_adjectives, I"adjective_meaning", I"_adjective_meaning");
		location_requirement in_adjective_meaning = HierarchyLocations::any_package_of_type(I"_adjective_meaning");
		HierarchyLocations::func(I, MEASUREMENT_FN_HL, I"measurement_fn", Translation::generate(I"MADJ_Test"), in_adjective_meaning);
	HierarchyLocations::ap(I, ADJECTIVE_PHRASES_HAP, local_adjectives, I"adjective_phrase", I"_adjective_phrase");
		location_requirement in_adjective_phrase = HierarchyLocations::any_package_of_type(I"_adjective_phrase");
		HierarchyLocations::func(I, DEFINITION_FN_HL, I"measurement_fn", Translation::generate(I"ADJDEFN"), in_adjective_phrase);

@h Bibliographic.

@e UUID_ARRAY_HL
@e STORY_HL
@e HEADLINE_HL
@e STORY_AUTHOR_HL
@e RELEASE_HL
@e SERIAL_HL

@<Establish bibliographic@> =
	submodule_identity *bibliographic = Packaging::register_submodule(I"bibliographic");

	location_requirement synoptic_biblio = HierarchyLocations::synoptic_submodule(I, bibliographic);
	HierarchyLocations::con(I, UUID_ARRAY_HL, I"UUID_ARRAY", Translation::same(), synoptic_biblio);
	HierarchyLocations::datum(I, STORY_HL, I"Story_datum", Translation::to(I"Story"), synoptic_biblio);
	HierarchyLocations::datum(I, HEADLINE_HL, I"Headline_datum", Translation::to(I"Headline"), synoptic_biblio);
	HierarchyLocations::datum(I, STORY_AUTHOR_HL, I"Story_Author_datum", Translation::to(I"Story_Author"), synoptic_biblio);
	HierarchyLocations::datum(I, RELEASE_HL, I"Release_datum", Translation::to(I"Release"), synoptic_biblio);
	HierarchyLocations::datum(I, SERIAL_HL, I"Serial_datum", Translation::to(I"Serial"), synoptic_biblio);

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
	HierarchyLocations::ap(I, PAST_ACTION_PATTERNS_HAP, local_chronology, I"past_action_pattern", I"_past_action_pattern");
		location_requirement in_past_action_pattern = HierarchyLocations::any_package_of_type(I"_past_action_pattern");
		HierarchyLocations::func(I, PAP_FN_HL, I"pap_fn", Translation::generate(I"PAPR"), in_past_action_pattern);

	location_requirement synoptic_chronology = HierarchyLocations::synoptic_submodule(I, chronology);
	HierarchyLocations::con(I, TIMEDEVENTSTABLE_HL, I"TimedEventsTable", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(I, TIMEDEVENTTIMESTABLE_HL, I"TimedEventTimesTable", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(I, PASTACTIONSI6ROUTINES_HL, I"PastActionsI6Routines", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(I, NO_PAST_TENSE_CONDS_HL, I"NO_PAST_TENSE_CONDS", Translation::same(), synoptic_chronology);
	HierarchyLocations::con(I, NO_PAST_TENSE_ACTIONS_HL, I"NO_PAST_TENSE_ACTIONS", Translation::same(), synoptic_chronology);
	HierarchyLocations::func(I, TESTSINGLEPASTSTATE_HL, I"test_fn", Translation::to(I"TestSinglePastState"), synoptic_chronology);

@h Conjugations.

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@e MVERBS_HAP
@e MVERB_NAME_HMD
@e MODAL_CONJUGATION_FN_HL
@e VERBS_HAP
@e VERB_NAME_HMD
@e NONMODAL_CONJUGATION_FN_HL
@e VERB_FORMS_HAP
@e FORM_FN_HL
@e CONJUGATION_FN_HL

@<Establish conjugations@> =
	submodule_identity *conjugations = Packaging::register_submodule(I"conjugations");

	location_requirement generic_conjugations = HierarchyLocations::generic_submodule(I, conjugations);
	HierarchyLocations::con(I, CV_MEANING_HL, I"CV_MEANING", Translation::same(), generic_conjugations);
	HierarchyLocations::con(I, CV_MODAL_HL, I"CV_MODAL", Translation::same(), generic_conjugations);
	HierarchyLocations::con(I, CV_NEG_HL, I"CV_NEG", Translation::same(), generic_conjugations);
	HierarchyLocations::con(I, CV_POS_HL, I"CV_POS", Translation::same(), generic_conjugations);

	location_requirement local_conjugations = HierarchyLocations::local_submodule(conjugations);
	HierarchyLocations::ap(I, MVERBS_HAP, local_conjugations, I"mverb", I"_modal_verb");
		location_requirement in_modal_verb = HierarchyLocations::any_package_of_type(I"_modal_verb");
		HierarchyLocations::metadata(I, MVERB_NAME_HMD, in_modal_verb, I"`name");
		HierarchyLocations::func(I, MODAL_CONJUGATION_FN_HL, I"conjugation_fn", Translation::generate(I"ConjugateModalVerb"), in_modal_verb);
	HierarchyLocations::ap(I, VERBS_HAP, local_conjugations, I"verb", I"_verb");
		location_requirement in_verb = HierarchyLocations::any_package_of_type(I"_verb");
		HierarchyLocations::metadata(I, VERB_NAME_HMD, in_verb, I"`name");
		HierarchyLocations::func(I, NONMODAL_CONJUGATION_FN_HL, I"conjugation_fn", Translation::generate(I"ConjugateVerb"), in_verb);
		HierarchyLocations::ap(I, VERB_FORMS_HAP, in_verb, I"form", I"_verb_form");
			location_requirement in_verb_form = HierarchyLocations::any_package_of_type(I"_verb_form");
			HierarchyLocations::func(I, FORM_FN_HL, I"form_fn", Translation::uniqued(), in_verb_form);

@h Equations.

@e EQUATIONS_HAP
@e SOLVE_FN_HL

@<Establish equations@> =
	submodule_identity *equations = Packaging::register_submodule(I"equations");

	location_requirement local_equations = HierarchyLocations::local_submodule(equations);
	HierarchyLocations::ap(I, EQUATIONS_HAP, local_equations, I"equation", I"_equation");
		location_requirement in_equation = HierarchyLocations::any_package_of_type(I"_equation");
		HierarchyLocations::func(I, SOLVE_FN_HL, I"solve_fn", Translation::uniqued(), in_equation);

@h Extensions.

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish extensions@> =
	submodule_identity *extensions = Packaging::register_submodule(I"extensions");

	location_requirement synoptic_extensions = HierarchyLocations::synoptic_submodule(I, extensions);
	HierarchyLocations::func(I, SHOWEXTENSIONVERSIONS_HL, I"showextensionversions_fn", Translation::to(I"ShowExtensionVersions"), synoptic_extensions);
	HierarchyLocations::func(I, SHOWFULLEXTENSIONVERSIONS_HL, I"showfullextensionversions_fn", Translation::to(I"ShowFullExtensionVersions"), synoptic_extensions);
	HierarchyLocations::func(I, SHOWONEEXTENSION_HL, I"showoneextension_fn", Translation::to(I"ShowOneExtension"), synoptic_extensions);

@h External files.

@e EXTERNAL_FILES_HAP
@e FILE_HL
@e IFID_HL

@<Establish external files@> =
	submodule_identity *external_files = Packaging::register_submodule(I"external_files");

	location_requirement local_external_files = HierarchyLocations::local_submodule(external_files);
	HierarchyLocations::ap(I, EXTERNAL_FILES_HAP, local_external_files, I"external_file", I"_external_file");
		location_requirement in_external_file = HierarchyLocations::any_package_of_type(I"_external_file");
		HierarchyLocations::con(I, FILE_HL, I"file", Translation::uniqued(), in_external_file);
		HierarchyLocations::con(I, IFID_HL, I"ifid", Translation::uniqued(), in_external_file);

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
	HierarchyLocations::ap(I, COND_TOKENS_HAP, local_grammar, I"conditional_token", I"_conditional_token");
		location_requirement in_conditional_token = HierarchyLocations::any_package_of_type(I"_conditional_token");
		HierarchyLocations::func(I, CONDITIONAL_TOKEN_FN_HL, I"conditional_token_fn", Translation::generate(I"Cond_Token"), in_conditional_token);
	HierarchyLocations::ap(I, CONSULT_TOKENS_HAP, local_grammar, I"consult_token", I"_consult_token");
		location_requirement in_consult_token = HierarchyLocations::any_package_of_type(I"_consult_token");
		HierarchyLocations::func(I, CONSULT_FN_HL, I"consult_fn", Translation::generate(I"Consult_Grammar"), in_consult_token);
	HierarchyLocations::ap(I, TESTS_HAP, local_grammar, I"test", I"_test");
		location_requirement in_test = HierarchyLocations::any_package_of_type(I"_test");
		HierarchyLocations::con(I, SCRIPT_HL, I"script", Translation::uniqued(), in_test);
		HierarchyLocations::con(I, REQUIREMENTS_HL, I"requirements", Translation::uniqued(), in_test);
	HierarchyLocations::ap(I, LOOP_OVER_SCOPES_HAP, local_grammar, I"loop_over_scope", I"_loop_over_scope");
		location_requirement in_loop_over_scope = HierarchyLocations::any_package_of_type(I"_loop_over_scope");
		HierarchyLocations::func(I, LOOP_OVER_SCOPE_FN_HL, I"loop_over_scope_fn", Translation::generate(I"LOS"), in_loop_over_scope);
	HierarchyLocations::ap(I, MISTAKES_HAP, local_grammar, I"mistake", I"_mistake");
		location_requirement in_mistake = HierarchyLocations::any_package_of_type(I"_mistake");
		HierarchyLocations::func(I, MISTAKE_FN_HL, I"mistake_fn", Translation::generate(I"Mistake_Token"), in_mistake);
	HierarchyLocations::ap(I, NAMED_ACTION_PATTERNS_HAP, local_grammar, I"named_action_pattern", I"_named_action_pattern");
		location_requirement in_named_action_pattern = HierarchyLocations::any_package_of_type(I"_named_action_pattern");
		HierarchyLocations::func(I, NAP_FN_HL, I"nap_fn", Translation::generate(I"NAP"), in_named_action_pattern);
	HierarchyLocations::ap(I, NAMED_TOKENS_HAP, local_grammar, I"named_token", I"_named_token");
		location_requirement in_named_token = HierarchyLocations::any_package_of_type(I"_named_token");
		HierarchyLocations::func(I, PARSE_LINE_FN_HL, I"parse_line_fn", Translation::generate(I"GPR_Line"), in_named_token);
	HierarchyLocations::ap(I, NOUN_FILTERS_HAP, local_grammar, I"noun_filter", I"_noun_filter");
		location_requirement in_noun_filter= HierarchyLocations::any_package_of_type(I"_noun_filter");
		HierarchyLocations::func(I, NOUN_FILTER_FN_HL, I"filter_fn", Translation::generate(I"Noun_Filter"), in_noun_filter);
	HierarchyLocations::ap(I, SCOPE_FILTERS_HAP, local_grammar, I"scope_filter", I"_scope_filter");
		location_requirement in_scope_filter = HierarchyLocations::any_package_of_type(I"_scope_filter");
		HierarchyLocations::func(I, SCOPE_FILTER_FN_HL, I"filter_fn", Translation::generate(I"Scope_Filter"), in_scope_filter);
	HierarchyLocations::ap(I, PARSE_NAMES_HAP, local_grammar, I"parse_name", I"_parse_name");
		location_requirement in_parse_name = HierarchyLocations::any_package_of_type(I"_parse_name");
		HierarchyLocations::func(I, PARSE_NAME_FN_HL, I"parse_name_fn", Translation::generate(I"Parse_Name_GV"), in_parse_name);
		HierarchyLocations::func(I, PARSE_NAME_DASH_FN_HL, I"parse_name_fn", Translation::generate(I"PN_for_S"), in_parse_name);
	HierarchyLocations::ap(I, SLASH_TOKENS_HAP, local_grammar, I"slash_token", I"_slash_token");
		location_requirement in_slash_token = HierarchyLocations::any_package_of_type(I"_slash_token");
		HierarchyLocations::func(I, SLASH_FN_HL, I"slash_fn", Translation::generate(I"SlashGPR"), in_slash_token);

	location_requirement synoptic_grammar = HierarchyLocations::synoptic_submodule(I, grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_CREATURE_HL, I"VERB_DIRECTIVE_CREATURE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_DIVIDER_HL, I"VERB_DIRECTIVE_DIVIDER", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_HELD_HL, I"VERB_DIRECTIVE_HELD", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_MULTI_HL, I"VERB_DIRECTIVE_MULTI", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_MULTIEXCEPT_HL, I"VERB_DIRECTIVE_MULTIEXCEPT", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_MULTIHELD_HL, I"VERB_DIRECTIVE_MULTIHELD", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_MULTIINSIDE_HL, I"VERB_DIRECTIVE_MULTIINSIDE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_NOUN_HL, I"VERB_DIRECTIVE_NOUN", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_NUMBER_HL, I"VERB_DIRECTIVE_NUMBER", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_RESULT_HL, I"VERB_DIRECTIVE_RESULT", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_REVERSE_HL, I"VERB_DIRECTIVE_REVERSE", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_SLASH_HL, I"VERB_DIRECTIVE_SLASH", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_SPECIAL_HL, I"VERB_DIRECTIVE_SPECIAL", Translation::same(), synoptic_grammar);
	HierarchyLocations::con(I, VERB_DIRECTIVE_TOPIC_HL, I"VERB_DIRECTIVE_TOPIC", Translation::same(), synoptic_grammar);
	HierarchyLocations::func(I, TESTSCRIPTSUB_HL, I"action_fn", Translation::to(I"TestScriptSub"), synoptic_grammar);
	HierarchyLocations::func(I, INTERNALTESTCASES_HL, I"run_tests_fn", Translation::to(I"InternalTestCases"), synoptic_grammar);
	HierarchyLocations::ap(I, COMMANDS_HAP, synoptic_grammar, I"command", I"_command");
		location_requirement in_command = HierarchyLocations::any_package_of_type(I"_command");
		HierarchyLocations::func(I, VERB_DECLARATION_ARRAY_HL, NULL, Translation::generate(I"GV_Grammar"), in_command);

@h Instances.

@e INSTANCES_HAP
@e INSTANCE_NAME_HMD
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
	HierarchyLocations::ap(I, INSTANCES_HAP, local_instances, I"instance", I"_instance");
		location_requirement in_instance = HierarchyLocations::any_package_of_type(I"_instance");
		HierarchyLocations::metadata(I, INSTANCE_NAME_HMD, in_instance, I"`name");
		HierarchyLocations::con(I, INSTANCE_HL, I"I", Translation::uniqued(), in_instance);
		HierarchyLocations::func(I, BACKDROP_FOUND_IN_FN_HL, I"backdrop_found_in_fn", Translation::uniqued(), in_instance);
		HierarchyLocations::func(I, SHORT_NAME_FN_HL, I"short_name_fn", Translation::generate(I"SN_R"), in_instance);
		HierarchyLocations::func(I, SHORT_NAME_PROPERTY_FN_HL, I"short_name_property_fn", Translation::generate(I"SN_R_A"), in_instance);
		HierarchyLocations::func(I, REGION_FOUND_IN_FN_HL, I"region_found_in_fn", Translation::generate(I"RFI_for_I"), in_instance);
		HierarchyLocations::func(I, TSD_DOOR_DIR_FN_HL, I"tsd_door_dir_fn", Translation::generate(I"TSD_door_dir_value"), in_instance);
		HierarchyLocations::func(I, TSD_DOOR_TO_FN_HL, I"tsd_door_to_fn", Translation::generate(I"TSD_door_to_value"), in_instance);
		HierarchyLocations::ap(I, INLINE_PROPERTIES_HAP, in_instance, I"inline_property", I"_inline_property");
			location_requirement in_inline_property = HierarchyLocations::any_package_of_type(I"_inline_property");
			HierarchyLocations::con(I, INLINE_PROPERTY_HL, I"inline", Translation::uniqued(), in_inline_property);

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

	location_requirement synoptic_IF = HierarchyLocations::synoptic_submodule(I, interactive_fiction);
	HierarchyLocations::con(I, DEFAULT_SCORING_SETTING_HL, I"DEFAULT_SCORING_SETTING", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, INITIAL_MAX_SCORE_HL, I"INITIAL_MAX_SCORE", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, NO_DIRECTIONS_HL, I"No_Directions", Translation::same(), synoptic_IF);
	HierarchyLocations::func(I, SHOWSCENESTATUS_HL, I"show_scene_status_fn", Translation::to(I"ShowSceneStatus"), synoptic_IF);
	HierarchyLocations::func(I, DETECTSCENECHANGE_HL, I"detect_scene_change_fn", Translation::to(I"DetectSceneChange"), synoptic_IF);
	HierarchyLocations::con(I, MAP_STORAGE_HL, I"Map_Storage", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, INITIALSITUATION_HL, I"InitialSituation", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, PLAYER_OBJECT_INIS_HL, I"PLAYER_OBJECT_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, START_OBJECT_INIS_HL, I"START_OBJECT_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, START_ROOM_INIS_HL, I"START_ROOM_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, START_TIME_INIS_HL, I"START_TIME_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::con(I, DONE_INIS_HL, I"DONE_INIS", Translation::same(), synoptic_IF);
	HierarchyLocations::ap(I, DIRECTIONS_HAP, synoptic_IF, I"direction", I"_direction");
		location_requirement in_direction = HierarchyLocations::any_package_of_type(I"_direction");
		HierarchyLocations::con(I, DIRECTION_HL, NULL, Translation::generate(I"DirectionObject"), in_direction);

@h Kinds.

@e UNKNOWN_TY_HL
@e K_UNCHECKED_HL
@e K_UNCHECKED_FUNCTION_HL
@e K_TYPELESS_INT_HL
@e K_TYPELESS_STRING_HL

@e KIND_HAP
@e KIND_NAME_HMD
@e KIND_CLASS_HL
@e KIND_HL
@e WEAK_ID_HL
@e ICOUNT_HL
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
@e COUNT_INSTANCE_1_HL
@e COUNT_INSTANCE_2_HL
@e COUNT_INSTANCE_3_HL
@e COUNT_INSTANCE_4_HL
@e COUNT_INSTANCE_5_HL
@e COUNT_INSTANCE_6_HL
@e COUNT_INSTANCE_7_HL
@e COUNT_INSTANCE_8_HL
@e COUNT_INSTANCE_9_HL
@e COUNT_INSTANCE_10_HL
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

	location_requirement generic_kinds = HierarchyLocations::generic_submodule(I, kinds);
	HierarchyLocations::con(I, UNKNOWN_TY_HL, I"UNKNOWN_TY", Translation::same(), generic_kinds);
	HierarchyLocations::con(I, K_UNCHECKED_HL, I"K_unchecked", Translation::same(), generic_kinds);
	HierarchyLocations::con(I, K_UNCHECKED_FUNCTION_HL, I"K_unchecked_function", Translation::same(), generic_kinds);
	HierarchyLocations::con(I, K_TYPELESS_INT_HL, I"K_typeless_int", Translation::same(), generic_kinds);
	HierarchyLocations::con(I, K_TYPELESS_STRING_HL, I"K_typeless_string", Translation::same(), generic_kinds);

	location_requirement local_kinds = HierarchyLocations::local_submodule(kinds);
	HierarchyLocations::ap(I, KIND_HAP, local_kinds, I"kind", I"_kind");
		location_requirement in_kind = HierarchyLocations::any_package_of_type(I"_kind");
		HierarchyLocations::metadata(I, KIND_NAME_HMD, in_kind, I"`name");
		HierarchyLocations::con(I, KIND_CLASS_HL, NULL, Translation::generate(I"K"), in_kind);
		HierarchyLocations::con(I, KIND_HL, NULL, Translation::generate(I"KD"), in_kind);
		HierarchyLocations::con(I, WEAK_ID_HL, NULL, Translation::imposed(), in_kind);
		HierarchyLocations::con(I, ICOUNT_HL, NULL, Translation::imposed(), in_kind);
		HierarchyLocations::con(I, DEFAULT_VALUE_HL, I"default_value", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, DECREMENT_FN_HL, I"decrement_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, INCREMENT_FN_HL, I"increment_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, PRINT_FN_HL, I"print_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, PRINT_DASH_FN_HL, I"print_fn", Translation::generate(I"E"), in_kind);
		HierarchyLocations::func(I, RANGER_FN_HL, I"ranger_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, DEFAULT_CLOSURE_FN_HL, I"default_closure_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, GPR_FN_HL, I"gpr_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::func(I, INSTANCE_GPR_FN_HL, I"instance_gpr_fn", Translation::uniqued(), in_kind);
		HierarchyLocations::con(I, FIRST_INSTANCE_HL, NULL, Translation::suffix(I"_First"), in_kind);
		HierarchyLocations::con(I, NEXT_INSTANCE_HL, NULL, Translation::suffix(I"_Next"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_1_HL, NULL, Translation::to(I"IK1_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_2_HL, NULL, Translation::to(I"IK2_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_3_HL, NULL, Translation::to(I"IK3_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_4_HL, NULL, Translation::to(I"IK4_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_5_HL, NULL, Translation::to(I"IK5_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_6_HL, NULL, Translation::to(I"IK6_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_7_HL, NULL, Translation::to(I"IK7_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_8_HL, NULL, Translation::to(I"IK8_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_9_HL, NULL, Translation::to(I"IK9_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_10_HL, NULL, Translation::to(I"IK10_Count"), in_kind);
		HierarchyLocations::con(I, COUNT_INSTANCE_HL, NULL, Translation::suffix(I"_Count"), in_kind);
		HierarchyLocations::ap(I, KIND_INLINE_PROPERTIES_HAP, in_kind, I"inline_property", I"_inline_property");
			location_requirement in_kind_inline_property = HierarchyLocations::any_package_of_type(I"_inline_property");
			HierarchyLocations::con(I, KIND_INLINE_PROPERTY_HL, I"inline", Translation::uniqued(), in_kind_inline_property);

	location_requirement synoptic_kinds = HierarchyLocations::synoptic_submodule(I, kinds);
	HierarchyLocations::con(I, BASE_KIND_HWM_HL, I"BASE_KIND_HWM", Translation::same(), synoptic_kinds);
	HierarchyLocations::func(I, DEFAULTVALUEOFKOV_HL, I"defaultvalue_fn", Translation::to(I"DefaultValueOfKOV"), synoptic_kinds);
	HierarchyLocations::func(I, DEFAULTVALUEFINDER_HL, I"defaultvaluefinder_fn", Translation::to(I"DefaultValueFinder"), synoptic_kinds);
	HierarchyLocations::func(I, PRINTKINDVALUEPAIR_HL, I"printkindvaluepair_fn", Translation::to(I"PrintKindValuePair"), synoptic_kinds);
	HierarchyLocations::func(I, KOVCOMPARISONFUNCTION_HL, I"comparison_fn", Translation::to(I"KOVComparisonFunction"), synoptic_kinds);
	HierarchyLocations::func(I, KOVDOMAINSIZE_HL, I"domainsize_fn", Translation::to(I"KOVDomainSize"), synoptic_kinds);
	HierarchyLocations::func(I, KOVISBLOCKVALUE_HL, I"blockvalue_fn", Translation::to(I"KOVIsBlockValue"), synoptic_kinds);
	HierarchyLocations::func(I, I7_KIND_NAME_HL, I"printkindname_fn", Translation::to(I"I7_Kind_Name"), synoptic_kinds);
	HierarchyLocations::func(I, KOVSUPPORTFUNCTION_HL, I"support_fn", Translation::to(I"KOVSupportFunction"), synoptic_kinds);
	HierarchyLocations::func(I, SHOWMEDETAILS_HL, I"showmedetails_fn", Translation::to(I"ShowMeDetails"), synoptic_kinds);

@h Listing.

@e LISTS_TOGETHER_HAP
@e LIST_TOGETHER_ARRAY_HL
@e LIST_TOGETHER_FN_HL

@<Establish listing@> =
	submodule_identity *listing = Packaging::register_submodule(I"listing");

	location_requirement local_listing = HierarchyLocations::local_submodule(listing);
	HierarchyLocations::ap(I, LISTS_TOGETHER_HAP, local_listing, I"list_together", I"_list_together");
		location_requirement in_list_together = HierarchyLocations::any_package_of_type(I"_list_together");
		HierarchyLocations::con(I, LIST_TOGETHER_ARRAY_HL, I"list_together_array", Translation::uniqued(), in_list_together);
		HierarchyLocations::func(I, LIST_TOGETHER_FN_HL, I"list_together_fn", Translation::generate(I"LTR_R"), in_list_together);

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
	HierarchyLocations::ap(I, PHRASES_HAP, local_phrases, I"phrase", I"_to_phrase");
		location_requirement in_to_phrase = HierarchyLocations::any_package_of_type(I"_to_phrase");
		HierarchyLocations::ap(I, CLOSURES_HAP, in_to_phrase, I"closure", I"_closure");
			location_requirement in_closure = HierarchyLocations::any_package_of_type(I"_closure");
			HierarchyLocations::con(I, CLOSURE_DATA_HL, I"closure_data", Translation::uniqued(), in_closure);
		HierarchyLocations::ap(I, REQUESTS_HAP, in_to_phrase, I"request", I"_request");
			location_requirement in_request = HierarchyLocations::any_package_of_type(I"_request");
			HierarchyLocations::func(I, PHRASE_FN_HL, I"phrase_fn", Translation::uniqued(), in_request);

	location_requirement synoptic_phrases = HierarchyLocations::synoptic_submodule(I, phrases);
	HierarchyLocations::ap(I, LABEL_STORAGES_HAP, synoptic_phrases, I"label_storage", I"_label_storage");
		location_requirement in_label_storage = HierarchyLocations::any_package_of_type(I"_label_storage");
		HierarchyLocations::con(I, LABEL_ASSOCIATED_STORAGE_HL, I"label_associated_storage", Translation::uniqued(), in_label_storage);

@h Properties.

@e PROPERTIES_HAP
@e PROPERTY_NAME_HMD
@e PROPERTY_HL
@e EITHER_OR_GPR_FN_HL

@e CCOUNT_PROPERTY_HL

@<Establish properties@> =
	submodule_identity *properties = Packaging::register_submodule(I"properties");

	location_requirement local_properties = HierarchyLocations::local_submodule(properties);
	HierarchyLocations::ap(I, PROPERTIES_HAP, local_properties, I"property", I"_property");
		location_requirement in_property = HierarchyLocations::any_package_of_type(I"_property");
		HierarchyLocations::metadata(I, PROPERTY_NAME_HMD, in_property, I"`name");
		HierarchyLocations::con(I, PROPERTY_HL, I"P", Translation::same(), in_property);
		HierarchyLocations::func(I, EITHER_OR_GPR_FN_HL, I"either_or_GPR_fn", Translation::generate(I"PRN_PN"), in_property);

	location_requirement synoptic_props = HierarchyLocations::synoptic_submodule(I, properties);
	HierarchyLocations::con(I, CCOUNT_PROPERTY_HL, I"CCOUNT_PROPERTY", Translation::same(), synoptic_props);

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

	location_requirement generic_rels = HierarchyLocations::generic_submodule(I, relations);
	HierarchyLocations::con(I, RELS_ASSERT_FALSE_HL, I"RELS_ASSERT_FALSE", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_ASSERT_TRUE_HL, I"RELS_ASSERT_TRUE", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_EQUIVALENCE_HL, I"RELS_EQUIVALENCE", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_LIST_HL, I"RELS_LIST", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_LOOKUP_ALL_X_HL, I"RELS_LOOKUP_ALL_X", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_LOOKUP_ALL_Y_HL, I"RELS_LOOKUP_ALL_Y", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_LOOKUP_ANY_HL, I"RELS_LOOKUP_ANY", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_ROUTE_FIND_COUNT_HL, I"RELS_ROUTE_FIND_COUNT", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_ROUTE_FIND_HL, I"RELS_ROUTE_FIND", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_SHOW_HL, I"RELS_SHOW", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_SYMMETRIC_HL, I"RELS_SYMMETRIC", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_TEST_HL, I"RELS_TEST", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_X_UNIQUE_HL, I"RELS_X_UNIQUE", Translation::same(), generic_rels);
	HierarchyLocations::con(I, RELS_Y_UNIQUE_HL, I"RELS_Y_UNIQUE", Translation::same(), generic_rels);
	HierarchyLocations::con(I, REL_BLOCK_HEADER_HL, I"REL_BLOCK_HEADER", Translation::same(), generic_rels);
	HierarchyLocations::con(I, TTF_SUM_HL, I"TTF_sum", Translation::same(), generic_rels);
	HierarchyLocations::con(I, MEANINGLESS_RR_HL, I"MEANINGLESS_RR", Translation::same(), generic_rels);

	location_requirement local_rels = HierarchyLocations::local_submodule(relations);
	HierarchyLocations::ap(I, RELATIONS_HAP, local_rels, I"relation", I"_relation");
		location_requirement in_relation = HierarchyLocations::any_package_of_type(I"_relation");
		HierarchyLocations::con(I, RELATION_RECORD_HL, NULL, Translation::generate(I"Rel_Record"), in_relation);
		HierarchyLocations::con(I, BITMAP_HL, I"as_constant", Translation::uniqued(), in_relation);
		HierarchyLocations::con(I, ABILITIES_HL, I"abilities", Translation::uniqued(), in_relation);
		HierarchyLocations::con(I, ROUTE_CACHE_HL, I"route_cache", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, HANDLER_FN_HL, I"handler_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, RELATION_INITIALISER_FN_HL, I"relation_initialiser_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, GUARD_F0_FN_HL, I"guard_f0_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, GUARD_F1_FN_HL, I"guard_f1_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, GUARD_TEST_FN_HL, I"guard_test_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, GUARD_MAKE_TRUE_FN_HL, I"guard_make_true_fn", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, GUARD_MAKE_FALSE_INAME_HL, I"guard_make_false_iname", Translation::uniqued(), in_relation);
		HierarchyLocations::func(I, RELATION_FN_HL, I"relation_fn", Translation::uniqued(), in_relation);

	location_requirement synoptic_rels = HierarchyLocations::synoptic_submodule(I, relations);
	HierarchyLocations::func(I, CREATEDYNAMICRELATIONS_HL, I"creator_fn", Translation::to(I"CreateDynamicRelations"), synoptic_rels);
	HierarchyLocations::con(I, CCOUNT_BINARY_PREDICATE_HL, I"CCOUNT_BINARY_PREDICATE", Translation::same(), synoptic_rels);
	HierarchyLocations::func(I, ITERATERELATIONS_HL, I"iterator_fn", Translation::to(I"IterateRelations"), synoptic_rels);
	HierarchyLocations::func(I, RPROPERTY_HL, I"property_fn", Translation::to(I"RProperty"), synoptic_rels);

@h Rulebooks.

@e EMPTY_RULEBOOK_INAME_HL

@e OUTCOMES_HAP
@e OUTCOME_NAME_HMD
@e OUTCOME_HL
@e RULEBOOKS_HAP
@e RULEBOOK_NAME_HMD
@e RUN_FN_HL
@e RULEBOOK_STV_CREATOR_FN_HL

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish rulebooks@> =
	submodule_identity *rulebooks = Packaging::register_submodule(I"rulebooks");

	location_requirement generic_rulebooks = HierarchyLocations::generic_submodule(I, rulebooks);
	HierarchyLocations::func(I, EMPTY_RULEBOOK_INAME_HL, I"empty_fn", Translation::to(I"EMPTY_RULEBOOK"), generic_rulebooks);

	location_requirement local_rulebooks = HierarchyLocations::local_submodule(rulebooks);
	HierarchyLocations::ap(I, OUTCOMES_HAP, local_rulebooks, I"rulebook_outcome", I"_outcome");
		location_requirement in_outcome = HierarchyLocations::any_package_of_type(I"_outcome");
		HierarchyLocations::metadata(I, OUTCOME_NAME_HMD, in_outcome, I"`name");
		HierarchyLocations::con(I, OUTCOME_HL, I"outcome", Translation::uniqued(), in_outcome);
	HierarchyLocations::ap(I, RULEBOOKS_HAP, local_rulebooks, I"rulebook", I"_rulebook");
		location_requirement in_rulebook = HierarchyLocations::any_package_of_type(I"_rulebook");
		HierarchyLocations::metadata(I, RULEBOOK_NAME_HMD, in_rulebook, I"`name");
		HierarchyLocations::func(I, RUN_FN_HL, I"run_fn", Translation::uniqued(), in_rulebook);
		HierarchyLocations::func(I, RULEBOOK_STV_CREATOR_FN_HL, I"stv_creator_fn", Translation::uniqued(), in_rulebook);

	location_requirement synoptic_rulebooks = HierarchyLocations::synoptic_submodule(I, rulebooks);
	HierarchyLocations::con(I, NUMBER_RULEBOOKS_CREATED_HL, I"NUMBER_RULEBOOKS_CREATED", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::con(I, RULEBOOK_VAR_CREATORS_HL, I"rulebook_var_creators", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::func(I, SLOW_LOOKUP_HL, I"slow_lookup_fn", Translation::to(I"MStack_GetRBVarCreator"), synoptic_rulebooks);
	HierarchyLocations::con(I, RULEBOOKS_ARRAY_HL, I"rulebooks_array", Translation::same(), synoptic_rulebooks);
	HierarchyLocations::con(I, RULEBOOKNAMES_HL, I"RulebookNames", Translation::same(), synoptic_rulebooks);

@h Rules.

@e RULES_HAP
@e RULE_NAME_HMD
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
	HierarchyLocations::ap(I, RULES_HAP, local_rules, I"rule", I"_rule");
		location_requirement in_rule = HierarchyLocations::any_package_of_type(I"_rule");
		HierarchyLocations::metadata(I, RULE_NAME_HMD, in_rule, I"`name");
		HierarchyLocations::func(I, SHELL_FN_HL, I"shell_fn", Translation::uniqued(), in_rule);
		HierarchyLocations::func(I, RULE_FN_HL, I"rule_fn", Translation::uniqued(), in_rule);
		HierarchyLocations::con(I, EXTERIOR_RULE_HL, I"exterior_rule", Translation::uniqued(), in_rule);
		HierarchyLocations::func(I, RESPONDER_FN_HL, I"responder_fn", Translation::suffix(I"M"), in_rule);
		HierarchyLocations::ap(I, RESPONSES_HAP, in_rule, I"response", I"_response");
			location_requirement in_response = HierarchyLocations::any_package_of_type(I"_response");
			HierarchyLocations::con(I, AS_CONSTANT_HL, I"as_constant", Translation::uniqued(), in_response);
			HierarchyLocations::con(I, AS_BLOCK_CONSTANT_HL, I"as_block_constant", Translation::uniqued(), in_response);
			HierarchyLocations::func(I, LAUNCHER_HL, I"launcher", Translation::uniqued(), in_response);

	location_requirement synoptic_rules = HierarchyLocations::synoptic_submodule(I, rules);
	HierarchyLocations::con(I, RESPONSEDIVISIONS_HL, I"ResponseDivisions", Translation::same(), synoptic_rules);
	HierarchyLocations::func(I, RULEPRINTINGRULE_HL, I"print_fn", Translation::to(I"RulePrintingRule"), synoptic_rules);

@h Tables.

@e TABLES_HAP
@e TABLE_NAME_HMD
@e TABLE_DATA_HL
@e TABLE_COLUMNS_HAP
@e COLUMN_DATA_HL

@e TC_KOV_HL
@e TB_BLANKS_HL

@<Establish tables@> =
	submodule_identity *tables = Packaging::register_submodule(I"tables");

	location_requirement local_tables = HierarchyLocations::local_submodule(tables);
	HierarchyLocations::ap(I, TABLES_HAP, local_tables, I"table", I"_table");
		location_requirement in_table = HierarchyLocations::any_package_of_type(I"_table");
		HierarchyLocations::metadata(I, TABLE_NAME_HMD, in_table, I"`name");
		HierarchyLocations::con(I, TABLE_DATA_HL, I"table_data", Translation::uniqued(), in_table);
		HierarchyLocations::ap(I, TABLE_COLUMNS_HAP, in_table, I"table_column", I"_table_column");
			location_requirement in_table_column = HierarchyLocations::any_package_of_type(I"_table_column");
			HierarchyLocations::con(I, COLUMN_DATA_HL, I"column_data", Translation::uniqued(), in_table_column);

	location_requirement synoptic_tables = HierarchyLocations::synoptic_submodule(I, tables);
	HierarchyLocations::con(I, TB_BLANKS_HL, I"TB_Blanks", Translation::same(), synoptic_tables);
	HierarchyLocations::func(I, TC_KOV_HL, I"weak_kind_ID_of_column_entry_fn", Translation::to(I"TC_KOV"), synoptic_tables);

@h Variables.

@e VARIABLES_HAP
@e VARIABLE_NAME_HMD
@e VARIABLE_HL

@<Establish variables@> =
	submodule_identity *variables = Packaging::register_submodule(I"variables");

	location_requirement local_variables = HierarchyLocations::local_submodule(variables);
	HierarchyLocations::ap(I, VARIABLES_HAP, local_variables, I"variable", I"_variable");
		location_requirement in_variable = HierarchyLocations::any_package_of_type(I"_variable");
		HierarchyLocations::metadata(I, VARIABLE_NAME_HMD, in_variable, I"`name");
		HierarchyLocations::con(I, VARIABLE_HL, NULL, Translation::generate(I"V"), in_variable);

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
	HierarchyLocations::ap(I, LITERALS_HAP, in_any_enclosure, I"literal", I"_literal");
		location_requirement in_literal = HierarchyLocations::any_package_of_type(I"_literal");
		HierarchyLocations::con(I, TEXT_LITERAL_HL, I"text", Translation::uniqued(), in_literal);
		HierarchyLocations::con(I, LIST_LITERAL_HL, I"list", Translation::uniqued(), in_literal);
		HierarchyLocations::con(I, TEXT_SUBSTITUTION_HL, I"ts_array", Translation::uniqued(), in_literal);
		HierarchyLocations::func(I, TEXT_SUBSTITUTION_FN_HL, I"ts_fn", Translation::uniqued(), in_literal);
	HierarchyLocations::ap(I, PROPOSITIONS_HAP, in_any_enclosure, I"proposition", I"_proposition");
		location_requirement in_proposition = HierarchyLocations::any_package_of_type(I"_proposition");
		HierarchyLocations::func(I, PROPOSITION_HL, I"prop", Translation::uniqued(), in_proposition);
	HierarchyLocations::ap(I, BLOCK_CONSTANTS_HAP, in_any_enclosure, I"block_constant", I"_block_constant");
		location_requirement in_block_constant = HierarchyLocations::any_package_of_type(I"_block_constant");
		HierarchyLocations::con(I, BLOCK_CONSTANT_HL, I"bc", Translation::uniqued(), in_block_constant);
	HierarchyLocations::ap(I, BOX_QUOTATIONS_HAP, in_any_enclosure, I"block_constant", I"_box_quotation");
		location_requirement in_box_quotation = HierarchyLocations::any_package_of_type(I"_box_quotation");
		HierarchyLocations::func(I, BOX_QUOTATION_FN_HL, I"quotation_fn", Translation::uniqued(), in_box_quotation);
	HierarchyLocations::con(I, RTP_HL, I"rtp", Translation::uniqued(), in_any_enclosure);

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
	HierarchyLocations::con(I, CAPSHORTNAME_HL, I"cap_short_name", Translation::same(), in_K_object);

	location_requirement in_K_number = HierarchyLocations::this_exotic_package(K_NUMBER_XPACKAGE);
	HierarchyLocations::func(I, DECIMAL_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"DECIMAL_TOKEN_INNER"), in_K_number);

	location_requirement in_K_time = HierarchyLocations::this_exotic_package(K_TIME_XPACKAGE);
	HierarchyLocations::func(I, TIME_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"TIME_TOKEN_INNER"), in_K_time);

	location_requirement in_K_truth_state = HierarchyLocations::this_exotic_package(K_TRUTH_STATE_XPACKAGE);
	HierarchyLocations::func(I, TRUTH_STATE_TOKEN_INNER_HL, I"gpr_fn", Translation::to(I"TRUTH_STATE_TOKEN_INNER"), in_K_truth_state);

	location_requirement in_K_table = HierarchyLocations::this_exotic_package(K_TABLE_XPACKAGE);
	HierarchyLocations::con(I, TABLEOFTABLES_HL, I"TableOfTables", Translation::same(), in_K_table);
	HierarchyLocations::func(I, PRINT_TABLE_HL, I"print_fn", Translation::to(I"PrintTableName"), in_K_table);

	location_requirement in_K_verb = HierarchyLocations::this_exotic_package(K_VERB_XPACKAGE);
	HierarchyLocations::con(I, TABLEOFVERBS_HL, I"TableOfVerbs", Translation::same(), in_K_verb);

	location_requirement in_K_figure_name = HierarchyLocations::this_exotic_package(K_FIGURE_NAME_XPACKAGE);
	HierarchyLocations::con(I, RESOURCEIDSOFFIGURES_HL, I"ResourceIDsOfFigures", Translation::same(), in_K_figure_name);
	HierarchyLocations::func(I, PRINT_FIGURE_NAME_HL, I"print_fn", Translation::to(I"PrintFigureName"), in_K_figure_name);

	location_requirement in_K_sound_name = HierarchyLocations::this_exotic_package(K_SOUND_NAME_XPACKAGE);
	HierarchyLocations::con(I, RESOURCEIDSOFSOUNDS_HL, I"ResourceIDsOfSounds", Translation::same(), in_K_sound_name);
	HierarchyLocations::func(I, PRINT_SOUND_NAME_HL, I"print_fn", Translation::to(I"PrintSoundName"), in_K_sound_name);

	location_requirement in_K_use_option = HierarchyLocations::this_exotic_package(K_USE_OPTION_XPACKAGE);
	HierarchyLocations::con(I, NO_USE_OPTIONS_HL, I"NO_USE_OPTIONS", Translation::same(), in_K_use_option);
	HierarchyLocations::func(I, TESTUSEOPTION_HL, I"test_fn", Translation::to(I"TestUseOption"), in_K_use_option);
	HierarchyLocations::func(I, PRINT_USE_OPTION_HL, I"print_fn", Translation::to(I"PrintUseOption"), in_K_use_option);

	location_requirement in_V_command_prompt = HierarchyLocations::this_exotic_package(V_COMMAND_PROMPT_XPACKAGE);
	HierarchyLocations::func(I, COMMANDPROMPTTEXT_HL, I"command_prompt_text_fn", Translation::to(I"CommandPromptText"), in_V_command_prompt);

	location_requirement in_K_external_file = HierarchyLocations::this_exotic_package(K_EXTERNAL_FILE_XPACKAGE);
	HierarchyLocations::con(I, NO_EXTERNAL_FILES_HL, I"NO_EXTERNAL_FILES", Translation::same(), in_K_external_file);
	HierarchyLocations::con(I, TABLEOFEXTERNALFILES_HL, I"TableOfExternalFiles", Translation::same(), in_K_external_file);
	HierarchyLocations::func(I, PRINT_EXTERNAL_FILE_NAME_HL, I"print_fn", Translation::to(I"PrintExternalFileName"), in_K_external_file);

	location_requirement in_K_rulebook_outcome = HierarchyLocations::this_exotic_package(K_RULEBOOK_OUTCOME_XPACKAGE);
	HierarchyLocations::func(I, PRINT_RULEBOOK_OUTCOME_HL, I"print_fn", Translation::to(I"RulebookOutcomePrintingRule"), in_K_rulebook_outcome);

	location_requirement in_K_response = HierarchyLocations::this_exotic_package(K_RESPONSE_XPACKAGE);
	HierarchyLocations::func(I, PRINT_RESPONSE_HL, I"print_fn", Translation::to(I"PrintResponse"), in_K_response);

	location_requirement in_K_scene = HierarchyLocations::this_exotic_package(K_SCENE_XPACKAGE);
	HierarchyLocations::func(I, PRINT_SCENE_HL, I"print_fn", Translation::to(I"PrintSceneName"), in_K_scene);

@

@e THESAME_HL
@e PLURALFOUND_HL
@e THEDARK_HL
@e INFORMLIBRARY_HL
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
@e DEFAULTTOPIC_HL
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
@e LITTLE_USED_DO_NOTHING_R_HL
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
	location_requirement template = HierarchyLocations::plug();
	HierarchyLocations::con(I, THESAME_HL, I"##TheSame", Translation::same(), template);
	HierarchyLocations::con(I, PLURALFOUND_HL, I"##PluralFound", Translation::same(), template);
	HierarchyLocations::con(I, THEDARK_HL, I"thedark", Translation::same(), template);
	HierarchyLocations::con(I, INFORMLIBRARY_HL, I"InformLibrary", Translation::same(), template);
	HierarchyLocations::con(I, ACT_REQUESTER_HL, I"act_requester", Translation::same(), template);
	HierarchyLocations::con(I, ACTION_HL, I"action", Translation::same(), template);
	HierarchyLocations::con(I, ACTIONCURRENTLYHAPPENINGFLAG_HL, I"ActionCurrentlyHappeningFlag", Translation::same(), template);
	HierarchyLocations::con(I, ACTOR_HL, I"actor", Translation::same(), template);
	HierarchyLocations::con(I, ACTOR_LOCATION_HL, I"actor_location", Translation::same(), template);
	HierarchyLocations::con(I, ADJUSTPARAGRAPHPOINT_HL, I"AdjustParagraphPoint", Translation::same(), template);
	HierarchyLocations::con(I, ALLOWINSHOWME_HL, I"AllowInShowme", Translation::same(), template);
	HierarchyLocations::con(I, ANIMATE_HL, I"animate", Translation::same(), template);
	HierarchyLocations::con(I, ARGUMENTTYPEFAILED_HL, I"ArgumentTypeFailed", Translation::same(), template);
	HierarchyLocations::con(I, ARTICLEDESCRIPTORS_HL, I"ArticleDescriptors", Translation::same(), template);
	HierarchyLocations::con(I, AUXF_MAGIC_VALUE_HL, I"AUXF_MAGIC_VALUE", Translation::same(), template);
	HierarchyLocations::con(I, AUXF_STATUS_IS_CLOSED_HL, I"AUXF_STATUS_IS_CLOSED", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUECOPY_HL, I"BlkValueCopy", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUECOPYAZ_HL, I"BlkValueCopyAZ", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUECREATE_HL, I"BlkValueCreate", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUECREATEONSTACK_HL, I"BlkValueCreateOnStack", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUEERROR_HL, I"BlkValueError", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUEFREE_HL, I"BlkValueFree", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUEFREEONSTACK_HL, I"BlkValueFreeOnStack", Translation::same(), template);
	HierarchyLocations::con(I, BLKVALUEWRITE_HL, I"BlkValueWrite", Translation::same(), template);
	HierarchyLocations::con(I, C_STYLE_HL, I"c_style", Translation::same(), template);
	HierarchyLocations::con(I, CHECKKINDRETURNED_HL, I"CheckKindReturned", Translation::same(), template);
	HierarchyLocations::con(I, CLEARPARAGRAPHING_HL, I"ClearParagraphing", Translation::same(), template);
	HierarchyLocations::con(I, COMPONENT_CHILD_HL, I"component_child", Translation::same(), template);
	HierarchyLocations::con(I, COMPONENT_PARENT_HL, I"component_parent", Translation::same(), template);
	HierarchyLocations::con(I, COMPONENT_SIBLING_HL, I"component_sibling", Translation::same(), template);
	HierarchyLocations::con(I, CONSTANT_PACKED_TEXT_STORAGE_HL, I"CONSTANT_PACKED_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(I, CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(I, CONSULT_FROM_HL, I"consult_from", Translation::same(), template);
	HierarchyLocations::con(I, CONSULT_WORDS_HL, I"consult_words", Translation::same(), template);
	HierarchyLocations::con(I, CONTAINER_HL, I"container", Translation::same(), template);
	HierarchyLocations::con(I, CUBEROOT_HL, I"CubeRoot", Translation::same(), template);
	HierarchyLocations::con(I, DA_NAME_HL, I"DA_Name", Translation::same(), template);
	HierarchyLocations::con(I, DB_RULE_HL, I"DB_Rule", Translation::same(), template);
	HierarchyLocations::con(I, DEADFLAG_HL, I"deadflag", Translation::same(), template);
	HierarchyLocations::con(I, DEBUG_RULES_HL, I"debug_rules", Translation::same(), template);
	HierarchyLocations::con(I, DEBUG_SCENES_HL, I"debug_scenes", Translation::same(), template);
	HierarchyLocations::con(I, DECIMALNUMBER_HL, I"DecimalNumber", Translation::same(), template);
	HierarchyLocations::con(I, DEFAULTTOPIC_HL, I"DefaultTopic", Translation::same(), template);
	HierarchyLocations::con(I, DEFERRED_CALLING_LIST_HL, I"deferred_calling_list", Translation::same(), template);
	HierarchyLocations::con(I, DETECTPLURALWORD_HL, I"DetectPluralWord", Translation::same(), template);
	HierarchyLocations::con(I, DIGITTOVALUE_HL, I"DigitToValue", Translation::same(), template);
	HierarchyLocations::con(I, DIVIDEPARAGRAPHPOINT_HL, I"DivideParagraphPoint", Translation::same(), template);
	HierarchyLocations::con(I, DOUBLEHASHSETRELATIONHANDLER_HL, I"DoubleHashSetRelationHandler", Translation::same(), template);
	HierarchyLocations::con(I, DURINGSCENEMATCHING_HL, I"DuringSceneMatching", Translation::same(), template);
	HierarchyLocations::con(I, ELEMENTARY_TT_HL, I"ELEMENTARY_TT", Translation::same(), template);
	HierarchyLocations::con(I, EMPTY_TABLE_HL, I"TheEmptyTable", Translation::same(), template);
	HierarchyLocations::con(I, EMPTY_TEXT_PACKED_HL, I"EMPTY_TEXT_PACKED", Translation::same(), template);
	HierarchyLocations::con(I, EMPTY_TEXT_VALUE_HL, I"EMPTY_TEXT_VALUE", Translation::same(), template);
	HierarchyLocations::con(I, EMPTYRELATIONHANDLER_HL, I"EmptyRelationHandler", Translation::same(), template);
	HierarchyLocations::con(I, ENGLISH_BIT_HL, I"ENGLISH_BIT", Translation::same(), template);
	HierarchyLocations::con(I, ETYPE_HL, I"etype", Translation::same(), template);
	HierarchyLocations::con(I, EXISTSTABLELOOKUPCORR_HL, I"ExistsTableLookUpCorr", Translation::same(), template);
	HierarchyLocations::con(I, EXISTSTABLELOOKUPENTRY_HL, I"ExistsTableLookUpEntry", Translation::same(), template);
	HierarchyLocations::con(I, EXISTSTABLEROWCORR_HL, I"ExistsTableRowCorr", Translation::same(), template);
	HierarchyLocations::con(I, FLOATPARSE_HL, I"FloatParse", Translation::same(), template);
	HierarchyLocations::con(I, FOLLOWRULEBOOK_HL, I"FollowRulebook", Translation::same(), template);
	HierarchyLocations::con(I, formal_par0_HL, I"formal_par0", Translation::same(), template);
	HierarchyLocations::con(I, formal_par1_HL, I"formal_par1", Translation::same(), template);
	HierarchyLocations::con(I, formal_par2_HL, I"formal_par2", Translation::same(), template);
	HierarchyLocations::con(I, formal_par3_HL, I"formal_par3", Translation::same(), template);
	HierarchyLocations::con(I, formal_par4_HL, I"formal_par4", Translation::same(), template);
	HierarchyLocations::con(I, formal_par5_HL, I"formal_par5", Translation::same(), template);
	HierarchyLocations::con(I, formal_par6_HL, I"formal_par6", Translation::same(), template);
	HierarchyLocations::con(I, formal_par7_HL, I"formal_par7", Translation::same(), template);
	HierarchyLocations::con(I, FORMAL_RV_HL, I"formal_rv", Translation::same(), template);
	HierarchyLocations::con(I, FOUND_EVERYWHERE_HL, I"FoundEverywhere", Translation::same(), template);
	HierarchyLocations::con(I, GENERATERANDOMNUMBER_HL, I"GenerateRandomNumber", Translation::same(), template);
	HierarchyLocations::con(I, GENERICVERBSUB_HL, I"GenericVerbSub", Translation::same(), template);
	HierarchyLocations::con(I, GETGNAOFOBJECT_HL, I"GetGNAOfObject", Translation::same(), template);
	HierarchyLocations::con(I, GPR_FAIL_HL, I"GPR_FAIL", Translation::same(), template);
	HierarchyLocations::con(I, GPR_NUMBER_HL, I"GPR_NUMBER", Translation::same(), template);
	HierarchyLocations::con(I, GPR_PREPOSITION_HL, I"GPR_PREPOSITION", Translation::same(), template);
	HierarchyLocations::con(I, GPR_TT_HL, I"GPR_TT", Translation::same(), template);
	HierarchyLocations::con(I, GPROPERTY_HL, I"GProperty", Translation::same(), template);
	HierarchyLocations::con(I, HASHLISTRELATIONHANDLER_HL, I"HashListRelationHandler", Translation::same(), template);
	HierarchyLocations::con(I, I7SFRAME_HL, I"I7SFRAME", Translation::same(), template);
	HierarchyLocations::con(I, INDENT_BIT_HL, I"INDENT_BIT", Translation::same(), template);
	HierarchyLocations::con(I, INP1_HL, I"inp1", Translation::same(), template);
	HierarchyLocations::con(I, INP2_HL, I"inp2", Translation::same(), template);
	HierarchyLocations::con(I, INTEGERDIVIDE_HL, I"IntegerDivide", Translation::same(), template);
	HierarchyLocations::con(I, INTEGERREMAINDER_HL, I"IntegerRemainder", Translation::same(), template);
	HierarchyLocations::con(I, INVENTORY_STAGE_HL, I"inventory_stage", Translation::same(), template);
	HierarchyLocations::con(I, KEEP_SILENT_HL, I"keep_silent", Translation::same(), template);
	HierarchyLocations::con(I, KINDATOMIC_HL, I"KindAtomic", Translation::same(), template);
	HierarchyLocations::con(I, LATEST_RULE_RESULT_HL, I"latest_rule_result", Translation::same(), template);
	HierarchyLocations::con(I, LIST_ITEM_BASE_HL, I"LIST_ITEM_BASE", Translation::same(), template);
	HierarchyLocations::con(I, LIST_ITEM_KOV_F_HL, I"LIST_ITEM_KOV_F", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_DESC_HL, I"LIST_OF_TY_Desc", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_GETITEM_HL, I"LIST_OF_TY_GetItem", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_GETLENGTH_HL, I"LIST_OF_TY_GetLength", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_INSERTITEM_HL, I"LIST_OF_TY_InsertItem", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_SAY_HL, I"LIST_OF_TY_Say", Translation::same(), template);
	HierarchyLocations::con(I, LIST_OF_TY_SETLENGTH_HL, I"LIST_OF_TY_SetLength", Translation::same(), template);
	HierarchyLocations::con(I, LITTLE_USED_DO_NOTHING_R_HL, I"LITTLE_USED_DO_NOTHING_R", Translation::same(), template);
	HierarchyLocations::con(I, LOCALPARKING_HL, I"LocalParking", Translation::same(), template);
	HierarchyLocations::con(I, LOCATION_HL, I"location", Translation::same(), template);
	HierarchyLocations::con(I, LOCATIONOF_HL, I"LocationOf", Translation::same(), template);
	HierarchyLocations::con(I, LOOPOVERSCOPE_HL, I"LoopOverScope", Translation::same(), template);
	HierarchyLocations::con(I, LOS_RV_HL, I"los_rv", Translation::same(), template);
	HierarchyLocations::con(I, MSTACK_HL, I"MStack", Translation::same(), template);
	HierarchyLocations::con(I, MSTVO_HL, I"MstVO", Translation::same(), template);
	HierarchyLocations::con(I, MSTVON_HL, I"MstVON", Translation::same(), template);
	HierarchyLocations::con(I, NAME_HL, I"name", Translation::same(), template);
	HierarchyLocations::con(I, NEWLINE_BIT_HL, I"NEWLINE_BIT", Translation::same(), template);
	HierarchyLocations::con(I, NEXTBEST_ETYPE_HL, I"nextbest_etype", Translation::same(), template);
	HierarchyLocations::con(I, NEXTWORDSTOPPED_HL, I"NextWordStopped", Translation::same(), template);
	HierarchyLocations::con(I, NOARTICLE_BIT_HL, I"NOARTICLE_BIT", Translation::same(), template);
	HierarchyLocations::con(I, NOTINCONTEXTPE_HL, I"NOTINCONTEXT_PE", Translation::same(), template);
	HierarchyLocations::con(I, NOUN_HL, I"noun", Translation::same(), template);
	HierarchyLocations::con(I, NUMBER_TY_ABS_HL, I"NUMBER_TY_Abs", Translation::same(), template);
	HierarchyLocations::con(I, NUMBER_TY_TO_REAL_NUMBER_TY_HL, I"NUMBER_TY_to_REAL_NUMBER_TY", Translation::same(), template);
	HierarchyLocations::con(I, NUMBER_TY_TO_TIME_TY_HL, I"NUMBER_TY_to_TIME_TY", Translation::same(), template);
	HierarchyLocations::con(I, OTOVRELROUTETO_HL, I"OtoVRelRouteTo", Translation::same(), template);
	HierarchyLocations::con(I, PACKED_TEXT_STORAGE_HL, I"PACKED_TEXT_STORAGE", Translation::same(), template);
	HierarchyLocations::con(I, PARACONTENT_HL, I"ParaContent", Translation::same(), template);
	HierarchyLocations::con(I, PARAMETER_VALUE_HL, I"parameter_value", Translation::same(), template);
	HierarchyLocations::con(I, PARSED_NUMBER_HL, I"parsed_number", Translation::same(), template);
	HierarchyLocations::con(I, PARSER_ACTION_HL, I"parser_action", Translation::same(), template);
	HierarchyLocations::con(I, PARSER_ONE_HL, I"parser_one", Translation::same(), template);
	HierarchyLocations::con(I, PARSER_TRACE_HL, I"parser_trace", Translation::same(), template);
	HierarchyLocations::con(I, PARSER_TWO_HL, I"parser_two", Translation::same(), template);
	HierarchyLocations::con(I, PARSERERROR_HL, I"ParserError", Translation::same(), template);
	HierarchyLocations::con(I, PARSETOKENSTOPPED_HL, I"ParseTokenStopped", Translation::same(), template);
	HierarchyLocations::con(I, PAST_CHRONOLOGICAL_RECORD_HL, I"past_chronological_record", Translation::same(), template);
	HierarchyLocations::con(I, PLACEINSCOPE_HL, I"PlaceInScope", Translation::same(), template);
	HierarchyLocations::con(I, PLAYER_HL, I"player", Translation::same(), template);
	HierarchyLocations::con(I, PNTOVP_HL, I"PNToVP", Translation::same(), template);
	HierarchyLocations::con(I, PRESENT_CHRONOLOGICAL_RECORD_HL, I"present_chronological_record", Translation::same(), template);
	HierarchyLocations::con(I, PRINTORRUN_HL, I"PrintOrRun", Translation::same(), template);
	HierarchyLocations::con(I, PRIOR_NAMED_LIST_HL, I"prior_named_list", Translation::same(), template);
	HierarchyLocations::con(I, PRIOR_NAMED_LIST_GENDER_HL, I"prior_named_list_gender", Translation::same(), template);
	HierarchyLocations::con(I, PRIOR_NAMED_NOUN_HL, I"prior_named_noun", Translation::same(), template);
	HierarchyLocations::con(I, PROPERTY_LOOP_SIGN_HL, I"property_loop_sign", Translation::same(), template);
	HierarchyLocations::con(I, PROPERTY_TO_BE_TOTALLED_HL, I"property_to_be_totalled", Translation::same(), template);
	HierarchyLocations::con(I, REAL_LOCATION_HL, I"real_location", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_ABS_HL, I"REAL_NUMBER_TY_Abs", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_APPROXIMATE_HL, I"REAL_NUMBER_TY_Approximate", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_COMPARE_HL, I"REAL_NUMBER_TY_Compare", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_CUBE_ROOT_HL, I"REAL_NUMBER_TY_Cube_Root", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_DIVIDE_HL, I"REAL_NUMBER_TY_Divide", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_MINUS_HL, I"REAL_NUMBER_TY_Minus", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_NAN_HL, I"REAL_NUMBER_TY_Nan", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_NEGATE_HL, I"REAL_NUMBER_TY_Negate", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_PLUS_HL, I"REAL_NUMBER_TY_Plus", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_POW_HL, I"REAL_NUMBER_TY_Pow", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_REMAINDER_HL, I"REAL_NUMBER_TY_Remainder", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_ROOT_HL, I"REAL_NUMBER_TY_Root", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_SAY_HL, I"REAL_NUMBER_TY_Say", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_TIMES_HL, I"REAL_NUMBER_TY_Times", Translation::same(), template);
	HierarchyLocations::con(I, REAL_NUMBER_TY_TO_NUMBER_TY_HL, I"REAL_NUMBER_TY_to_NUMBER_TY", Translation::same(), template);
	HierarchyLocations::con(I, REASON_THE_ACTION_FAILED_HL, I"reason_the_action_failed", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_EMPTYEQUIV_HL, I"Relation_EmptyEquiv", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_EMPTYOTOO_HL, I"Relation_EmptyOtoO", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_EMPTYVTOV_HL, I"Relation_EmptyVtoV", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_RSHOWOTOO_HL, I"Relation_RShowOtoO", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_SHOWEQUIV_HL, I"Relation_ShowEquiv", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_SHOWOTOO_HL, I"Relation_ShowOtoO", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_SHOWVTOV_HL, I"Relation_ShowVtoV", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_NAME_HL, I"RELATION_TY_Name", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_OTOOADJECTIVE_HL, I"RELATION_TY_OToOAdjective", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_OTOVADJECTIVE_HL, I"RELATION_TY_OToVAdjective", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_SYMMETRICADJECTIVE_HL, I"RELATION_TY_SymmetricAdjective", Translation::same(), template);
	HierarchyLocations::con(I, RELATION_TY_VTOOADJECTIVE_HL, I"RELATION_TY_VToOAdjective", Translation::same(), template);
	HierarchyLocations::con(I, RELATIONTEST_HL, I"RelationTest", Translation::same(), template);
	HierarchyLocations::con(I, RELFOLLOWVECTOR_HL, I"RelFollowVector", Translation::same(), template);
	HierarchyLocations::con(I, RELS_EMPTY_HL, I"RELS_EMPTY", Translation::same(), template);
	HierarchyLocations::con(I, RESPONSEVIAACTIVITY_HL, I"ResponseViaActivity", Translation::same(), template);
	HierarchyLocations::con(I, RLANY_CAN_GET_X_HL, I"RLANY_CAN_GET_X", Translation::same(), template);
	HierarchyLocations::con(I, RLANY_CAN_GET_Y_HL, I"RLANY_CAN_GET_Y", Translation::same(), template);
	HierarchyLocations::con(I, RLANY_GET_X_HL, I"RLANY_GET_X", Translation::same(), template);
	HierarchyLocations::con(I, RLIST_ALL_X_HL, I"RLIST_ALL_X", Translation::same(), template);
	HierarchyLocations::con(I, RLIST_ALL_Y_HL, I"RLIST_ALL_Y", Translation::same(), template);
	HierarchyLocations::con(I, RLNGETF_HL, I"RlnGetF", Translation::same(), template);
	HierarchyLocations::con(I, ROUNDOFFTIME_HL, I"RoundOffTime", Translation::same(), template);
	HierarchyLocations::con(I, ROUTINEFILTER_TT_HL, I"ROUTINE_FILTER_TT", Translation::same(), template);
	HierarchyLocations::con(I, RR_STORAGE_HL, I"RR_STORAGE", Translation::same(), template);
	HierarchyLocations::con(I, RTP_RELKINDVIOLATION_HL, I"RTP_RELKINDVIOLATION", Translation::same(), template);
	HierarchyLocations::con(I, RTP_RELMINIMAL_HL, I"RTP_RELMINIMAL", Translation::same(), template);
	HierarchyLocations::con(I, RULEBOOKFAILS_HL, I"RulebookFails", Translation::same(), template);
	HierarchyLocations::con(I, RULEBOOKPARBREAK_HL, I"RulebookParBreak", Translation::same(), template);
	HierarchyLocations::con(I, RULEBOOKSUCCEEDS_HL, I"RulebookSucceeds", Translation::same(), template);
	HierarchyLocations::con(I, RUNTIMEPROBLEM_HL, I"RunTimeProblem", Translation::same(), template);
	HierarchyLocations::con(I, SAY__N_HL, I"say__n", Translation::same(), template);
	HierarchyLocations::con(I, SAY__P_HL, I"say__p", Translation::same(), template);
	HierarchyLocations::con(I, SAY__PC_HL, I"say__pc", Translation::same(), template);
	HierarchyLocations::con(I, SCENE_ENDED_HL, I"scene_ended", Translation::same(), template);
	HierarchyLocations::con(I, SCENE_ENDINGS_HL, I"scene_endings", Translation::same(), template);
	HierarchyLocations::con(I, SCENE_LATEST_ENDING_HL, I"scene_latest_ending", Translation::same(), template);
	HierarchyLocations::con(I, SCENE_STARTED_HL, I"scene_started", Translation::same(), template);
	HierarchyLocations::con(I, SCENE_STATUS_HL, I"scene_status", Translation::same(), template);
	HierarchyLocations::con(I, SCOPE_STAGE_HL, I"scope_stage", Translation::same(), template);
	HierarchyLocations::con(I, SCOPE_TT_HL, I"SCOPE_TT", Translation::same(), template);
	HierarchyLocations::con(I, SECOND_HL, I"second", Translation::same(), template);
	HierarchyLocations::con(I, SHORT_NAME_HL, I"short_name", Translation::same(), template);
	HierarchyLocations::con(I, SIGNEDCOMPARE_HL, I"SignedCompare", Translation::same(), template);
	HierarchyLocations::con(I, SPECIAL_WORD_HL, I"special_word", Translation::same(), template);
	HierarchyLocations::con(I, SQUAREROOT_HL, I"SquareRoot", Translation::same(), template);
	HierarchyLocations::con(I, STACKFRAMECREATE_HL, I"StackFrameCreate", Translation::same(), template);
	HierarchyLocations::con(I, STORED_ACTION_TY_CURRENT_HL, I"STORED_ACTION_TY_Current", Translation::same(), template);
	HierarchyLocations::con(I, STORED_ACTION_TY_TRY_HL, I"STORED_ACTION_TY_Try", Translation::same(), template);
	HierarchyLocations::con(I, STORY_TENSE_HL, I"story_tense", Translation::same(), template);
	HierarchyLocations::con(I, SUPPORTER_HL, I"supporter", Translation::same(), template);
	HierarchyLocations::con(I, SUPPRESS_SCOPE_LOOPS_HL, I"suppress_scope_loops", Translation::same(), template);
	HierarchyLocations::con(I, SUPPRESS_TEXT_SUBSTITUTION_HL, I"suppress_text_substitution", Translation::same(), template);
	HierarchyLocations::con(I, TABLE_NOVALUE_HL, I"TABLE_NOVALUE", Translation::same(), template);
	HierarchyLocations::con(I, TABLELOOKUPCORR_HL, I"TableLookUpCorr", Translation::same(), template);
	HierarchyLocations::con(I, TABLELOOKUPENTRY_HL, I"TableLookUpEntry", Translation::same(), template);
	HierarchyLocations::con(I, TESTACTIONBITMAP_HL, I"TestActionBitmap", Translation::same(), template);
	HierarchyLocations::con(I, TESTACTIVITY_HL, I"TestActivity", Translation::same(), template);
	HierarchyLocations::con(I, TESTREGIONALCONTAINMENT_HL, I"TestRegionalContainment", Translation::same(), template);
	HierarchyLocations::con(I, TESTSCOPE_HL, I"TestScope", Translation::same(), template);
	HierarchyLocations::con(I, TESTSTART_HL, I"TestStart", Translation::same(), template);
	HierarchyLocations::con(I, TEXT_TY_COMPARE_HL, I"TEXT_TY_Compare", Translation::same(), template);
	HierarchyLocations::con(I, TEXT_TY_EXPANDIFPERISHABLE_HL, I"TEXT_TY_ExpandIfPerishable", Translation::same(), template);
	HierarchyLocations::con(I, TEXT_TY_SAY_HL, I"TEXT_TY_Say", Translation::same(), template);
	HierarchyLocations::con(I, THE_TIME_HL, I"the_time", Translation::same(), template);
	HierarchyLocations::con(I, THEEMPTYTABLE_HL, I"TheEmptyTable", Translation::same(), template);
	HierarchyLocations::con(I, THEN1__WD_HL, I"THEN1__WD", Translation::same(), template);
	HierarchyLocations::con(I, TIMESACTIONHASBEENHAPPENING_HL, I"TimesActionHasBeenHappening", Translation::same(), template);
	HierarchyLocations::con(I, TIMESACTIONHASHAPPENED_HL, I"TimesActionHasHappened", Translation::same(), template);
	HierarchyLocations::con(I, TRYACTION_HL, I"TryAction", Translation::same(), template);
	HierarchyLocations::con(I, TRYGIVENOBJECT_HL, I"TryGivenObject", Translation::same(), template);
	HierarchyLocations::con(I, TURNSACTIONHASBEENHAPPENING_HL, I"TurnsActionHasBeenHappening", Translation::same(), template);
	HierarchyLocations::con(I, UNDERSTAND_AS_MISTAKE_NUMBER_HL, I"understand_as_mistake_number", Translation::same(), template);
	HierarchyLocations::con(I, UNICODE_TEMP_HL, I"unicode_temp", Translation::same(), template);
	HierarchyLocations::con(I, VTOORELROUTETO_HL, I"VtoORelRouteTo", Translation::same(), template);
	HierarchyLocations::con(I, VTOVRELROUTETO_HL, I"VtoVRelRouteTo", Translation::same(), template);
	HierarchyLocations::con(I, WHEN_SCENE_BEGINS_HL, I"WHEN_SCENE_BEGINS_RB", Translation::same(), template);
	HierarchyLocations::con(I, WHEN_SCENE_ENDS_HL, I"WHEN_SCENE_ENDS_RB", Translation::same(), template);
	HierarchyLocations::con(I, WN_HL, I"wn", Translation::same(), template);
	HierarchyLocations::con(I, WORDADDRESS_HL, I"WordAddress", Translation::same(), template);
	HierarchyLocations::con(I, WORDINPROPERTY_HL, I"WordInProperty", Translation::same(), template);
	HierarchyLocations::con(I, WORDLENGTH_HL, I"WordLength", Translation::same(), template);

@

@e MAX_HL
@e MAX_HAP
@e MAX_HMD

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
			return InterNames::location(NonlocalVariables::iname(command_prompt_VAR));
	}
	internal_error("unknown exotic package");
	return NULL;
}

@

=
inter_name *Hierarchy::post_process(int HL_id, inter_name *iname) {
	switch (HL_id) {
		case SELF_HL:
			Emit::variable(iname, K_value, UNDEF_IVAL, 0, I"self");
			break;
	}
	return iname;
}

@

=
inter_name *Hierarchy::find(int id) {
	return HierarchyLocations::find(Emit::tree(), id);
}

void Hierarchy::make_available(inter_tree *I, inter_name *iname) {
	text_stream *ma_as = Produce::get_translation(iname);
	if (Str::len(ma_as) == 0) ma_as = Emit::to_text(iname);
	PackageTypes::get(I, I"_linkage");
	inter_symbol *S = InterNames::to_symbol(iname);
	Inter::Connectors::socket(Emit::tree(), ma_as, S);
}

package_request *Hierarchy::package(compilation_module *C, int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), C, NULL, hap_id);
}

package_request *Hierarchy::synoptic_package(int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, NULL, hap_id);
}

package_request *Hierarchy::local_package(int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), Modules::find(current_sentence), NULL, hap_id);
}

package_request *Hierarchy::package_in_enclosure(int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, Packaging::enclosure(Emit::tree()), hap_id);
}

package_request *Hierarchy::package_within(int hap_id, package_request *super) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, super, hap_id);
}

inter_name *Hierarchy::make_iname_in(int id, package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING, NULL, -1, NULL);
}

inter_name *Hierarchy::make_iname_with_specific_name(int id, text_stream *name, package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING, NULL, -1, name);
}

inter_name *Hierarchy::derive_iname_in(int id, inter_name *derive_from, package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING, derive_from, -1, NULL);
}

inter_name *Hierarchy::make_localised_iname_in(int id, package_request *P, compilation_module *C) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING, NULL, -1, NULL);
}

inter_name *Hierarchy::make_iname_with_memo(int id, package_request *P, wording W) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, W, NULL, -1, NULL);
}

inter_name *Hierarchy::make_iname_with_memo_and_value(int id, package_request *P, wording W, int x) {
	inter_name *iname = HierarchyLocations::find_in_package(Emit::tree(), id, P, W, NULL, x, NULL);
	Hierarchy::make_available(Emit::tree(), iname);
	return iname;
}

package_request *Hierarchy::make_package_in(int id, package_request *P) {
	return HierarchyLocations::package_in_package(Emit::tree(), id, P);
}

void Hierarchy::markup(package_request *R, int hm_id, text_stream *value) {
	HierarchyLocations::markup(Emit::tree(), R, hm_id, value);
}

void Hierarchy::markup_wording(package_request *R, int hm_id, wording W) {
	TEMPORARY_TEXT(ANT);
	WRITE_TO(ANT, "%W", W);
	Hierarchy::markup(R, hm_id, ANT);
	DISCARD_TEXT(ANT);
}

void Hierarchy::markup_wa(package_request *R, int hm_id, word_assemblage WA) {
	TEMPORARY_TEXT(ANT);
	WRITE_TO(ANT, "%A", WA);
	Hierarchy::markup(R, hm_id, ANT);
	DISCARD_TEXT(ANT);
}
