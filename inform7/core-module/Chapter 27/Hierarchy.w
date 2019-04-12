[Hierarchy::] Hierarchy.

@

@e BASICS_SUBMODULE from 0
@e KINDS_SUBMODULE
@e CONJUGATIONS_SUBMODULE
@e RULES_SUBMODULE
@e PHRASES_SUBMODULE
@e ADJECTIVES_SUBMODULE
@e INSTANCES_SUBMODULE
@e PROPERTIES_SUBMODULE
@e VARIABLES_SUBMODULE
@e EXTENSIONS_SUBMODULE
@e ACTIONS_SUBMODULE
@e RULEBOOKS_SUBMODULE
@e ACTIVITIES_SUBMODULE
@e RELATIONS_SUBMODULE
@e GRAMMAR_SUBMODULE
@e TABLES_SUBMODULE
@e CHRONOLOGY_SUBMODULE
@e LISTING_SUBMODULE
@e EQUATIONS_SUBMODULE
@e BIBLIOGRAPHIC_SUBMODULE
@e IF_SUBMODULE
@e EXTERNAL_FILES_SUBMODULE

@e MAX_SUBMODULE

=
text_stream *Hierarchy::submodule_name(int spid) {
	text_stream *N = NULL;
	switch (spid) {
		case BASICS_SUBMODULE: N = I"basics"; break;
		case KINDS_SUBMODULE: N = I"kinds"; break;
		case CONJUGATIONS_SUBMODULE: N = I"conjugations"; break;
		case RULES_SUBMODULE: N = I"rules"; break;
		case PHRASES_SUBMODULE: N = I"phrases"; break;
		case ADJECTIVES_SUBMODULE: N = I"adjectives"; break;
		case INSTANCES_SUBMODULE: N = I"instances"; break;
		case PROPERTIES_SUBMODULE: N = I"properties"; break;
		case VARIABLES_SUBMODULE: N = I"variables"; break;
		case EXTENSIONS_SUBMODULE: N = I"extensions"; break;
		case ACTIONS_SUBMODULE: N = I"actions"; break;
		case RULEBOOKS_SUBMODULE: N = I"rulebooks"; break;
		case ACTIVITIES_SUBMODULE: N = I"activities"; break;
		case RELATIONS_SUBMODULE: N = I"relations"; break;
		case GRAMMAR_SUBMODULE: N = I"grammar"; break;
		case TABLES_SUBMODULE: N = I"tables"; break;
		case CHRONOLOGY_SUBMODULE: N = I"chronology"; break;
		case LISTING_SUBMODULE: N = I"listing"; break;
		case EQUATIONS_SUBMODULE: N = I"equations"; break;
		case BIBLIOGRAPHIC_SUBMODULE: N = I"bibliographic"; break;
		case IF_SUBMODULE: N = I"interactive_fiction"; break;
		case EXTERNAL_FILES_SUBMODULE: N = I"external_files"; break;
		default: internal_error("nameless resource");
	}
	return N;
}

@ =
void Hierarchy::establish(void) {
	@<Establish generic basics@>;
	@<Establish synoptic basics@>;
	@<Establish generic conjugations@>;
	@<Establish generic relations@>;
	@<Establish synoptic relations@>;
	@<Establish generic actions@>;
	@<Establish synoptic actions@>;
	@<Establish synoptic activities@>;
	@<Establish synoptic grammar@>;
	@<Establish generic kinds@>;
	@<Establish synoptic kinds@>;
	@<Establish synoptic resources@>;
	@<Establish synoptic rules@>;
	@<Establish generic rulebooks@>;
	@<Establish synoptic rulebooks@>;
	@<Establish synoptic tables@>;
	@<Establish synoptic int-fiction@>;
	@<Establish synoptic chronology@>;
	@<Establish synoptic bibliographic@>;
	@<Establish synoptic extensions@>;
	@<The rest@>;
	
	@<Establish template resources@>;
}

@

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

@<Establish generic basics@> =
	package_request *generic_basics = Packaging::generic_resource(BASICS_SUBMODULE);
	HierarchyLocations::make_in(THESAME_HL, I"##TheSame", generic_basics);
	HierarchyLocations::make_in(PLURALFOUND_HL, I"##PluralFound", generic_basics);
	HierarchyLocations::make_in(PARENT_HL, I"parent", generic_basics);
	HierarchyLocations::make_in(CHILD_HL, I"child", generic_basics);
	HierarchyLocations::make_in(SIBLING_HL, I"sibling", generic_basics);
	HierarchyLocations::make_in(SELF_HL, I"self", generic_basics);
	HierarchyLocations::make_in(THEDARK_HL, I"thedark", generic_basics);
	HierarchyLocations::make_in(RESPONSETEXTS_HL, I"ResponseTexts", generic_basics);
	HierarchyLocations::make_in(DEBUG_HL, I"DEBUG", generic_basics);
	HierarchyLocations::make_in(TARGET_ZCODE_HL, I"TARGET_ZCODE", generic_basics);
	HierarchyLocations::make_in(TARGET_GLULX_HL, I"TARGET_GLULX", generic_basics);
	HierarchyLocations::make_in(DICT_WORD_SIZE_HL, I"DICT_WORD_SIZE", generic_basics);
	HierarchyLocations::make_in(WORDSIZE_HL, I"WORDSIZE", generic_basics);
	HierarchyLocations::make_in(NULL_HL, I"NULL", generic_basics);
	HierarchyLocations::make_in(WORD_HIGHBIT_HL, I"WORD_HIGHBIT", generic_basics);
	HierarchyLocations::make_in(WORD_NEXTTOHIGHBIT_HL, I"WORD_NEXTTOHIGHBIT", generic_basics);
	HierarchyLocations::make_in(IMPROBABLE_VALUE_HL, I"IMPROBABLE_VALUE", generic_basics);
	HierarchyLocations::make_in(REPARSE_CODE_HL, I"REPARSE_CODE", generic_basics);
	HierarchyLocations::make_in(MAX_POSITIVE_NUMBER_HL, I"MAX_POSITIVE_NUMBER", generic_basics);
	HierarchyLocations::make_in(MIN_NEGATIVE_NUMBER_HL, I"MIN_NEGATIVE_NUMBER", generic_basics);
	HierarchyLocations::make_in(FLOAT_NAN_HL, I"FLOAT_NAN", generic_basics);
	HierarchyLocations::make_in(CAP_SHORT_NAME_EXISTS_HL, I"CAP_SHORT_NAME_EXISTS", generic_basics);
	HierarchyLocations::make_in(NI_BUILD_COUNT_HL, I"NI_BUILD_COUNT", generic_basics);
	HierarchyLocations::make_in(RANKING_TABLE_HL, I"RANKING_TABLE", generic_basics);
	HierarchyLocations::make_in(PLUGIN_FILES_HL, I"PLUGIN_FILES", generic_basics);
	HierarchyLocations::make_in(MAX_WEAK_ID_HL, I"MAX_WEAK_ID", generic_basics);
	HierarchyLocations::make_in(NO_VERB_VERB_DEFINED_HL, I"NO_VERB_VERB_DEFINED", generic_basics);
	HierarchyLocations::make_in(NO_TEST_SCENARIOS_HL, I"NO_TEST_SCENARIOS", generic_basics);
	HierarchyLocations::make_in(MEMORY_HEAP_SIZE_HL, I"MEMORY_HEAP_SIZE", generic_basics);

@

@e CCOUNT_QUOTATIONS_HL
@e MAX_FRAME_SIZE_NEEDED_HL
@e RNG_SEED_AT_START_OF_PLAY_HL

@<Establish synoptic basics@> =
	package_request *basics = Packaging::synoptic_resource(BASICS_SUBMODULE);
	HierarchyLocations::make_in(CCOUNT_QUOTATIONS_HL, I"CCOUNT_QUOTATIONS", basics);
	HierarchyLocations::make_in(MAX_FRAME_SIZE_NEEDED_HL, I"MAX_FRAME_SIZE_NEEDED", basics);
	HierarchyLocations::make_in(RNG_SEED_AT_START_OF_PLAY_HL, I"RNG_SEED_AT_START_OF_PLAY", basics);

@

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@<Establish generic conjugations@> =
	package_request *conj = Packaging::generic_resource(CONJUGATIONS_SUBMODULE);
	HierarchyLocations::make_in(CV_MEANING_HL, I"CV_MEANING", conj);
	HierarchyLocations::make_in(CV_MODAL_HL, I"CV_MODAL", conj);
	HierarchyLocations::make_in(CV_NEG_HL, I"CV_NEG", conj);
	HierarchyLocations::make_in(CV_POS_HL, I"CV_POS", conj);

@

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

@<Establish generic relations@> =
	package_request *generic_rels = Packaging::generic_resource(RELATIONS_SUBMODULE);
	HierarchyLocations::make_in(RELS_ASSERT_FALSE_HL, I"RELS_ASSERT_FALSE", generic_rels);
	HierarchyLocations::make_in(RELS_ASSERT_TRUE_HL, I"RELS_ASSERT_TRUE", generic_rels);
	HierarchyLocations::make_in(RELS_EQUIVALENCE_HL, I"RELS_EQUIVALENCE", generic_rels);
	HierarchyLocations::make_in(RELS_LIST_HL, I"RELS_LIST", generic_rels);
	HierarchyLocations::make_in(RELS_LOOKUP_ALL_X_HL, I"RELS_LOOKUP_ALL_X", generic_rels);
	HierarchyLocations::make_in(RELS_LOOKUP_ALL_Y_HL, I"RELS_LOOKUP_ALL_Y", generic_rels);
	HierarchyLocations::make_in(RELS_LOOKUP_ANY_HL, I"RELS_LOOKUP_ANY", generic_rels);
	HierarchyLocations::make_in(RELS_ROUTE_FIND_COUNT_HL, I"RELS_ROUTE_FIND_COUNT", generic_rels);
	HierarchyLocations::make_in(RELS_ROUTE_FIND_HL, I"RELS_ROUTE_FIND", generic_rels);
	HierarchyLocations::make_in(RELS_SHOW_HL, I"RELS_SHOW", generic_rels);
	HierarchyLocations::make_in(RELS_SYMMETRIC_HL, I"RELS_SYMMETRIC", generic_rels);
	HierarchyLocations::make_in(RELS_TEST_HL, I"RELS_TEST", generic_rels);
	HierarchyLocations::make_in(RELS_X_UNIQUE_HL, I"RELS_X_UNIQUE", generic_rels);
	HierarchyLocations::make_in(RELS_Y_UNIQUE_HL, I"RELS_Y_UNIQUE", generic_rels);
	HierarchyLocations::make_in(REL_BLOCK_HEADER_HL, I"REL_BLOCK_HEADER", generic_rels);
	HierarchyLocations::make_in(TTF_SUM_HL, I"TTF_sum", generic_rels);
	HierarchyLocations::make_in(MEANINGLESS_RR_HL, I"MEANINGLESS_RR", generic_rels);

@

@e CREATEDYNAMICRELATIONS_HL
@e CCOUNT_BINARY_PREDICATE_HL
@e ITERATERELATIONS_HL
@e RPROPERTY_HL

@<Establish synoptic relations@> =
	package_request *rels = Packaging::synoptic_resource(RELATIONS_SUBMODULE);
	HierarchyLocations::make_function(CREATEDYNAMICRELATIONS_HL, I"creator_fn", I"CreateDynamicRelations", rels);
	HierarchyLocations::make_in(CCOUNT_BINARY_PREDICATE_HL, I"CCOUNT_BINARY_PREDICATE", rels);
	HierarchyLocations::make_function(ITERATERELATIONS_HL, I"iterator_fn", I"IterateRelations", rels);
	HierarchyLocations::make_function(RPROPERTY_HL, I"property_fn", I"RProperty", rels);

@

@e MISTAKEACTION_HL

@<Establish generic actions@> =
	package_request *generic_acts = Packaging::generic_resource(ACTIONS_SUBMODULE);
	HierarchyLocations::make_in(MISTAKEACTION_HL, I"##MistakeAction", generic_acts);

@

@e ACTIONCODING_HL
@e ACTIONDATA_HL
@e ACTIONHAPPENED_HL
@e AD_RECORDS_HL
@e CCOUNT_ACTION_NAME_HL
@e DB_ACTION_DETAILS_HL
@e MISTAKEACTIONSUB_HL

@<Establish synoptic actions@> =
	package_request *acts = Packaging::synoptic_resource(ACTIONS_SUBMODULE);
	HierarchyLocations::make_in(ACTIONCODING_HL, I"ActionCoding", acts);
	HierarchyLocations::make_in(ACTIONDATA_HL, I"ActionData", acts);
	HierarchyLocations::make_in(ACTIONHAPPENED_HL, I"ActionHappened", acts);
	HierarchyLocations::make_in(AD_RECORDS_HL, I"AD_RECORDS", acts);
	HierarchyLocations::make_in(CCOUNT_ACTION_NAME_HL, I"CCOUNT_ACTION_NAME", acts);
	HierarchyLocations::make_function(DB_ACTION_DETAILS_HL, I"DB_Action_Details_fn", I"DB_Action_Details", acts);
	HierarchyLocations::make_function(MISTAKEACTIONSUB_HL, I"MistakeActionSub_fn", I"MistakeActionSub", acts);

@

@e ACTIVITY_AFTER_RULEBOOKS_HL
@e ACTIVITY_ATB_RULEBOOKS_HL
@e ACTIVITY_BEFORE_RULEBOOKS_HL
@e ACTIVITY_FOR_RULEBOOKS_HL
@e ACTIVITY_VAR_CREATORS_HL

@<Establish synoptic activities@> =
	package_request *activities = Packaging::synoptic_resource(ACTIVITIES_SUBMODULE);
	HierarchyLocations::make_in(ACTIVITY_AFTER_RULEBOOKS_HL, I"Activity_after_rulebooks", activities);
	HierarchyLocations::make_in(ACTIVITY_ATB_RULEBOOKS_HL, I"Activity_atb_rulebooks", activities);
	HierarchyLocations::make_in(ACTIVITY_BEFORE_RULEBOOKS_HL, I"Activity_before_rulebooks", activities);
	HierarchyLocations::make_in(ACTIVITY_FOR_RULEBOOKS_HL, I"Activity_for_rulebooks", activities);
	HierarchyLocations::make_in(ACTIVITY_VAR_CREATORS_HL, I"activity_var_creators", activities);

@

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

@<Establish synoptic grammar@> =
	package_request *grammar = Packaging::synoptic_resource(GRAMMAR_SUBMODULE);
	HierarchyLocations::make_in(VERB_DIRECTIVE_CREATURE_HL, I"VERB_DIRECTIVE_CREATURE", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_DIVIDER_HL, I"VERB_DIRECTIVE_DIVIDER", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_HELD_HL, I"VERB_DIRECTIVE_HELD", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_MULTI_HL, I"VERB_DIRECTIVE_MULTI", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_MULTIEXCEPT_HL, I"VERB_DIRECTIVE_MULTIEXCEPT", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_MULTIHELD_HL, I"VERB_DIRECTIVE_MULTIHELD", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_MULTIINSIDE_HL, I"VERB_DIRECTIVE_MULTIINSIDE", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_NOUN_HL, I"VERB_DIRECTIVE_NOUN", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_NUMBER_HL, I"VERB_DIRECTIVE_NUMBER", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_RESULT_HL, I"VERB_DIRECTIVE_RESULT", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_REVERSE_HL, I"VERB_DIRECTIVE_REVERSE", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_SLASH_HL, I"VERB_DIRECTIVE_SLASH", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_SPECIAL_HL, I"VERB_DIRECTIVE_SPECIAL", grammar);
	HierarchyLocations::make_in(VERB_DIRECTIVE_TOPIC_HL, I"VERB_DIRECTIVE_TOPIC", grammar);
	HierarchyLocations::make_function(TESTSCRIPTSUB_HL, I"action_fn", I"TestScriptSub", grammar);
	HierarchyLocations::make_function(INTERNALTESTCASES_HL, I"run_tests_fn", I"InternalTestCases", grammar);

@

@e UNKNOWN_TY_HL

@<Establish generic kinds@> =
	package_request *generic_kinds = Packaging::generic_resource(KINDS_SUBMODULE);
	HierarchyLocations::make_in(UNKNOWN_TY_HL, I"UNKNOWN_TY", generic_kinds);

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

@<Establish synoptic kinds@> =
	package_request *kinds = Packaging::synoptic_resource(KINDS_SUBMODULE);
	HierarchyLocations::make_in(BASE_KIND_HWM_HL, I"BASE_KIND_HWM", kinds);
	HierarchyLocations::make_function(DEFAULTVALUEOFKOV_HL, I"defaultvalue_fn", I"DefaultValueOfKOV", kinds);
	HierarchyLocations::make_function(DEFAULTVALUEFINDER_HL, I"defaultvaluefinder_fn", I"DefaultValueFinder", kinds);
	HierarchyLocations::make_function(PRINTKINDVALUEPAIR_HL, I"printkindvaluepair_fn", I"PrintKindValuePair", kinds);
	HierarchyLocations::make_function(KOVCOMPARISONFUNCTION_HL, I"comparison_fn", I"KOVComparisonFunction", kinds);
	HierarchyLocations::make_function(KOVDOMAINSIZE_HL, I"domainsize_fn", I"KOVDomainSize", kinds);
	HierarchyLocations::make_function(KOVISBLOCKVALUE_HL, I"blockvalue_fn", I"KOVIsBlockValue", kinds);
	HierarchyLocations::make_function(I7_KIND_NAME_HL, I"printkindname_fn", I"I7_Kind_Name", kinds);
	HierarchyLocations::make_function(KOVSUPPORTFUNCTION_HL, I"support_fn", I"KOVSupportFunction", kinds);
	HierarchyLocations::make_function(SHOWMEDETAILS_HL, I"showmedetails_fn", I"ShowMeDetails", kinds);

@

@e CCOUNT_PROPERTY_HL

@<Establish synoptic resources@> =
	package_request *props = Packaging::synoptic_resource(PROPERTIES_SUBMODULE);
	HierarchyLocations::make_in(CCOUNT_PROPERTY_HL, I"CCOUNT_PROPERTY", props);

@

@e RULEPRINTINGRULE_HL
@e RESPONSEDIVISIONS_HL

@<Establish synoptic rules@> =
	package_request *rules = Packaging::synoptic_resource(RULES_SUBMODULE);
	HierarchyLocations::make_in(RESPONSEDIVISIONS_HL, I"ResponseDivisions", rules);
	HierarchyLocations::make_function(RULEPRINTINGRULE_HL, I"print_fn", I"RulePrintingRule", rules);

@

@e EMPTY_RULEBOOK_INAME_HL

@<Establish generic rulebooks@> =
	package_request *generic_rulebooks = Packaging::generic_resource(RULEBOOKS_SUBMODULE);
	HierarchyLocations::make_function(EMPTY_RULEBOOK_INAME_HL, I"empty_fn", I"EMPTY_RULEBOOK", generic_rulebooks);

@

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish synoptic rulebooks@> =
	package_request *rulebooks = Packaging::synoptic_resource(RULEBOOKS_SUBMODULE);
	HierarchyLocations::make_in(NUMBER_RULEBOOKS_CREATED_HL, I"NUMBER_RULEBOOKS_CREATED", rulebooks);
	HierarchyLocations::make_in(RULEBOOK_VAR_CREATORS_HL, I"rulebook_var_creators", rulebooks);
	HierarchyLocations::make_function(SLOW_LOOKUP_HL, I"slow_lookup_fn", I"MStack_GetRBVarCreator", rulebooks);
	HierarchyLocations::make_in(RULEBOOKS_ARRAY_HL, I"rulebooks_array", rulebooks);
	HierarchyLocations::make_in(RULEBOOKNAMES_HL, I"RulebookNames", rulebooks);
@

@e TC_KOV_HL
@e TB_BLANKS_HL

@<Establish synoptic tables@> =
	package_request *tables = Packaging::synoptic_resource(TABLES_SUBMODULE);
	HierarchyLocations::make_in(TB_BLANKS_HL, I"TB_Blanks", tables);
	HierarchyLocations::make_function(TC_KOV_HL, I"weak_kind_ID_of_column_entry_fn", I"TC_KOV", tables);

@

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

@<Establish synoptic int-fiction@> =
	package_request *int_fiction = Packaging::synoptic_resource(IF_SUBMODULE);
	HierarchyLocations::make_in(DEFAULT_SCORING_SETTING_HL, I"DEFAULT_SCORING_SETTING", int_fiction);
	HierarchyLocations::make_in(INITIAL_MAX_SCORE_HL, I"INITIAL_MAX_SCORE", int_fiction);
	HierarchyLocations::make_in(NO_DIRECTIONS_HL, I"No_Directions", int_fiction);
	HierarchyLocations::make_function(SHOWSCENESTATUS_HL, I"show_scene_status_fn", I"ShowSceneStatus", int_fiction);
	HierarchyLocations::make_function(DETECTSCENECHANGE_HL, I"detect_scene_change_fn", I"DetectSceneChange", int_fiction);
	HierarchyLocations::make_in(MAP_STORAGE_HL, I"Map_Storage", int_fiction);
	HierarchyLocations::make_in(INITIALSITUATION_HL, I"InitialSituation", int_fiction);
	HierarchyLocations::make_in(PLAYER_OBJECT_INIS_HL, I"PLAYER_OBJECT_INIS", int_fiction);
	HierarchyLocations::make_in(START_OBJECT_INIS_HL, I"START_OBJECT_INIS", int_fiction);
	HierarchyLocations::make_in(START_ROOM_INIS_HL, I"START_ROOM_INIS", int_fiction);
	HierarchyLocations::make_in(START_TIME_INIS_HL, I"START_TIME_INIS", int_fiction);
	HierarchyLocations::make_in(DONE_INIS_HL, I"DONE_INIS", int_fiction);

@

@e TIMEDEVENTSTABLE_HL
@e TIMEDEVENTTIMESTABLE_HL
@e PASTACTIONSI6ROUTINES_HL
@e NO_PAST_TENSE_CONDS_HL
@e NO_PAST_TENSE_ACTIONS_HL
@e TESTSINGLEPASTSTATE_HL

@<Establish synoptic chronology@> =
	package_request *chronology = Packaging::synoptic_resource(CHRONOLOGY_SUBMODULE);
	HierarchyLocations::make_in(TIMEDEVENTSTABLE_HL, I"TimedEventsTable", chronology);
	HierarchyLocations::make_in(TIMEDEVENTTIMESTABLE_HL, I"TimedEventTimesTable", chronology);
	HierarchyLocations::make_in(PASTACTIONSI6ROUTINES_HL, I"PastActionsI6Routines", chronology);
	HierarchyLocations::make_in(NO_PAST_TENSE_CONDS_HL, I"NO_PAST_TENSE_CONDS", chronology);
	HierarchyLocations::make_in(NO_PAST_TENSE_ACTIONS_HL, I"NO_PAST_TENSE_ACTIONS", chronology);
	HierarchyLocations::make_function(TESTSINGLEPASTSTATE_HL, I"test_fn", I"TestSinglePastState", chronology);

@

@e UUID_ARRAY_HL
@e STORY_HL
@e HEADLINE_HL
@e STORY_AUTHOR_HL
@e RELEASE_HL
@e SERIAL_HL

@<Establish synoptic bibliographic@> =
	package_request *biblio = Packaging::synoptic_resource(BIBLIOGRAPHIC_SUBMODULE);
	HierarchyLocations::make_in(UUID_ARRAY_HL, I"UUID_ARRAY", biblio);
	HierarchyLocations::make_datum(STORY_HL, I"Story_datum", I"Story", biblio);
	HierarchyLocations::make_datum(HEADLINE_HL, I"Headline_datum", I"Headline", biblio);
	HierarchyLocations::make_datum(STORY_AUTHOR_HL, I"Story_Author_datum", I"Story_Author", biblio);
	HierarchyLocations::make_datum(RELEASE_HL, I"Release_datum", I"Release", biblio);
	HierarchyLocations::make_datum(SERIAL_HL, I"Serial_datum", I"Serial", biblio);

@

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish synoptic extensions@> =
	package_request *extensions = Packaging::synoptic_resource(EXTENSIONS_SUBMODULE);
	HierarchyLocations::make_function(SHOWEXTENSIONVERSIONS_HL, I"showextensionversions_fn", I"ShowExtensionVersions", extensions);
	HierarchyLocations::make_function(SHOWFULLEXTENSIONVERSIONS_HL, I"showfullextensionversions_fn", I"ShowFullExtensionVersions", extensions);
	HierarchyLocations::make_function(SHOWONEEXTENSION_HL, I"showoneextension_fn", I"ShowOneExtension", extensions);

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
	package_request *template = Packaging::request_template();	
	HierarchyLocations::make_in(ACT_REQUESTER_HL, I"act_requester", template);
	HierarchyLocations::make_in(ACTION_HL, I"action", template);
	HierarchyLocations::make_in(ACTIONCURRENTLYHAPPENINGFLAG_HL, I"ActionCurrentlyHappeningFlag", template);
	HierarchyLocations::make_in(ACTOR_HL, I"actor", template);
	HierarchyLocations::make_in(ACTOR_LOCATION_HL, I"actor_location", template);
	HierarchyLocations::make_in(ADJUSTPARAGRAPHPOINT_HL, I"AdjustParagraphPoint", template);
	HierarchyLocations::make_in(ALLOWINSHOWME_HL, I"AllowInShowme", template);
	HierarchyLocations::make_in(ANIMATE_HL, I"animate", template);
	HierarchyLocations::make_in(ARGUMENTTYPEFAILED_HL, I"ArgumentTypeFailed", template);
	HierarchyLocations::make_in(ARTICLEDESCRIPTORS_HL, I"ArticleDescriptors", template);
	HierarchyLocations::make_in(AUXF_MAGIC_VALUE_HL, I"AUXF_MAGIC_VALUE", template);
	HierarchyLocations::make_in(AUXF_STATUS_IS_CLOSED_HL, I"AUXF_STATUS_IS_CLOSED", template);
	HierarchyLocations::make_in(BLKVALUECOPY_HL, I"BlkValueCopy", template);
	HierarchyLocations::make_in(BLKVALUECOPYAZ_HL, I"BlkValueCopyAZ", template);
	HierarchyLocations::make_in(BLKVALUECREATE_HL, I"BlkValueCreate", template);
	HierarchyLocations::make_in(BLKVALUECREATEONSTACK_HL, I"BlkValueCreateOnStack", template);
	HierarchyLocations::make_in(BLKVALUEERROR_HL, I"BlkValueError", template);
	HierarchyLocations::make_in(BLKVALUEFREE_HL, I"BlkValueFree", template);
	HierarchyLocations::make_in(BLKVALUEFREEONSTACK_HL, I"BlkValueFreeOnStack", template);
	HierarchyLocations::make_in(BLKVALUEWRITE_HL, I"BlkValueWrite", template);
	HierarchyLocations::make_in(C_STYLE_HL, I"c_style", template);
	HierarchyLocations::make_in(CHECKKINDRETURNED_HL, I"CheckKindReturned", template);
	HierarchyLocations::make_in(CLEARPARAGRAPHING_HL, I"ClearParagraphing", template);
	HierarchyLocations::make_in(COMPONENT_CHILD_HL, I"component_child", template);
	HierarchyLocations::make_in(COMPONENT_PARENT_HL, I"component_parent", template);
	HierarchyLocations::make_in(COMPONENT_SIBLING_HL, I"component_sibling", template);
	HierarchyLocations::make_in(CONSTANT_PACKED_TEXT_STORAGE_HL, I"CONSTANT_PACKED_TEXT_STORAGE", template);
	HierarchyLocations::make_in(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE", template);
	HierarchyLocations::make_in(CONSULT_FROM_HL, I"consult_from", template);
	HierarchyLocations::make_in(CONSULT_WORDS_HL, I"consult_words", template);
	HierarchyLocations::make_in(CONTAINER_HL, I"container", template);
	HierarchyLocations::make_in(CUBEROOT_HL, I"CubeRoot", template);
	HierarchyLocations::make_in(DA_NAME_HL, I"DA_Name", template);
	HierarchyLocations::make_in(DB_RULE_HL, I"DB_Rule", template);
	HierarchyLocations::make_in(DEADFLAG_HL, I"deadflag", template);
	HierarchyLocations::make_in(DEBUG_RULES_HL, I"debug_rules", template);
	HierarchyLocations::make_in(DEBUG_SCENES_HL, I"debug_scenes", template);
	HierarchyLocations::make_in(DECIMALNUMBER_HL, I"DecimalNumber", template);
	HierarchyLocations::make_in(DEFERRED_CALLING_LIST_HL, I"deferred_calling_list", template);
	HierarchyLocations::make_in(DETECTPLURALWORD_HL, I"DetectPluralWord", template);
	HierarchyLocations::make_in(DIGITTOVALUE_HL, I"DigitToValue", template);
	HierarchyLocations::make_in(DIVIDEPARAGRAPHPOINT_HL, I"DivideParagraphPoint", template);
	HierarchyLocations::make_in(DOUBLEHASHSETRELATIONHANDLER_HL, I"DoubleHashSetRelationHandler", template);
	HierarchyLocations::make_in(DURINGSCENEMATCHING_HL, I"DuringSceneMatching", template);
	HierarchyLocations::make_in(ELEMENTARY_TT_HL, I"ELEMENTARY_TT", template);
	HierarchyLocations::make_in(EMPTY_TABLE_HL, I"TheEmptyTable", template);
	HierarchyLocations::make_in(EMPTY_TEXT_PACKED_HL, I"EMPTY_TEXT_PACKED", template);
	HierarchyLocations::make_in(EMPTY_TEXT_VALUE_HL, I"EMPTY_TEXT_VALUE", template);
	HierarchyLocations::make_in(EMPTYRELATIONHANDLER_HL, I"EmptyRelationHandler", template);
	HierarchyLocations::make_in(ENGLISH_BIT_HL, I"ENGLISH_BIT", template);
	HierarchyLocations::make_in(ETYPE_HL, I"etype", template);
	HierarchyLocations::make_in(EXISTSTABLELOOKUPCORR_HL, I"ExistsTableLookUpCorr", template);
	HierarchyLocations::make_in(EXISTSTABLELOOKUPENTRY_HL, I"ExistsTableLookUpEntry", template);
	HierarchyLocations::make_in(EXISTSTABLEROWCORR_HL, I"ExistsTableRowCorr", template);
	HierarchyLocations::make_in(FLOATPARSE_HL, I"FloatParse", template);
	HierarchyLocations::make_in(FOLLOWRULEBOOK_HL, I"FollowRulebook", template);
	HierarchyLocations::make_in(formal_par0_HL, I"formal_par0", template);
	HierarchyLocations::make_in(formal_par1_HL, I"formal_par1", template);
	HierarchyLocations::make_in(formal_par2_HL, I"formal_par2", template);
	HierarchyLocations::make_in(formal_par3_HL, I"formal_par3", template);
	HierarchyLocations::make_in(formal_par4_HL, I"formal_par4", template);
	HierarchyLocations::make_in(formal_par5_HL, I"formal_par5", template);
	HierarchyLocations::make_in(formal_par6_HL, I"formal_par6", template);
	HierarchyLocations::make_in(formal_par7_HL, I"formal_par7", template);
	HierarchyLocations::make_in(FORMAL_RV_HL, I"formal_rv", template);
	HierarchyLocations::make_in(FOUND_EVERYWHERE_HL, I"FoundEverywhere", template);
	HierarchyLocations::make_in(GENERATERANDOMNUMBER_HL, I"GenerateRandomNumber", template);
	HierarchyLocations::make_in(GENERICVERBSUB_HL, I"GenericVerbSub", template);
	HierarchyLocations::make_in(GETGNAOFOBJECT_HL, I"GetGNAOfObject", template);
	HierarchyLocations::make_in(GPR_FAIL_HL, I"GPR_FAIL", template);
	HierarchyLocations::make_in(GPR_NUMBER_HL, I"GPR_NUMBER", template);
	HierarchyLocations::make_in(GPR_PREPOSITION_HL, I"GPR_PREPOSITION", template);
	HierarchyLocations::make_in(GPR_TT_HL, I"GPR_TT", template);
	HierarchyLocations::make_in(GPROPERTY_HL, I"GProperty", template);
	HierarchyLocations::make_in(HASHLISTRELATIONHANDLER_HL, I"HashListRelationHandler", template);
	HierarchyLocations::make_in(I7SFRAME_HL, I"I7SFRAME", template);
	HierarchyLocations::make_in(INDENT_BIT_HL, I"INDENT_BIT", template);
	HierarchyLocations::make_in(INP1_HL, I"inp1", template);
	HierarchyLocations::make_in(INP2_HL, I"inp2", template);
	HierarchyLocations::make_in(INTEGERDIVIDE_HL, I"IntegerDivide", template);
	HierarchyLocations::make_in(INTEGERREMAINDER_HL, I"IntegerRemainder", template);
	HierarchyLocations::make_in(INVENTORY_STAGE_HL, I"inventory_stage", template);
	HierarchyLocations::make_in(KEEP_SILENT_HL, I"keep_silent", template);
	HierarchyLocations::make_in(KINDATOMIC_HL, I"KindAtomic", template);
	HierarchyLocations::make_in(LATEST_RULE_RESULT_HL, I"latest_rule_result", template);
	HierarchyLocations::make_in(LIST_ITEM_BASE_HL, I"LIST_ITEM_BASE", template);
	HierarchyLocations::make_in(LIST_ITEM_KOV_F_HL, I"LIST_ITEM_KOV_F", template);
	HierarchyLocations::make_in(LIST_OF_TY_DESC_HL, I"LIST_OF_TY_Desc", template);
	HierarchyLocations::make_in(LIST_OF_TY_GETITEM_HL, I"LIST_OF_TY_GetItem", template);
	HierarchyLocations::make_in(LIST_OF_TY_GETLENGTH_HL, I"LIST_OF_TY_GetLength", template);
	HierarchyLocations::make_in(LIST_OF_TY_INSERTITEM_HL, I"LIST_OF_TY_InsertItem", template);
	HierarchyLocations::make_in(LIST_OF_TY_SAY_HL, I"LIST_OF_TY_Say", template);
	HierarchyLocations::make_in(LIST_OF_TY_SETLENGTH_HL, I"LIST_OF_TY_SetLength", template);
	HierarchyLocations::make_in(LOCALPARKING_HL, I"LocalParking", template);
	HierarchyLocations::make_in(LOCATION_HL, I"location", template);
	HierarchyLocations::make_in(LOCATIONOF_HL, I"LocationOf", template);
	HierarchyLocations::make_in(LOOPOVERSCOPE_HL, I"LoopOverScope", template);
	HierarchyLocations::make_in(LOS_RV_HL, I"los_rv", template);
	HierarchyLocations::make_in(MSTACK_HL, I"MStack", template);
	HierarchyLocations::make_in(MSTVO_HL, I"MstVO", template);
	HierarchyLocations::make_in(MSTVON_HL, I"MstVON", template);
	HierarchyLocations::make_in(NAME_HL, I"name", template);
	HierarchyLocations::make_in(NEWLINE_BIT_HL, I"NEWLINE_BIT", template);
	HierarchyLocations::make_in(NEXTBEST_ETYPE_HL, I"nextbest_etype", template);
	HierarchyLocations::make_in(NEXTWORDSTOPPED_HL, I"NextWordStopped", template);
	HierarchyLocations::make_in(NOARTICLE_BIT_HL, I"NOARTICLE_BIT", template);
	HierarchyLocations::make_in(NOTINCONTEXTPE_HL, I"NOTINCONTEXT_PE", template);
	HierarchyLocations::make_in(NOUN_HL, I"noun", template);
	HierarchyLocations::make_in(NUMBER_TY_ABS_HL, I"NUMBER_TY_Abs", template);
	HierarchyLocations::make_in(NUMBER_TY_TO_REAL_NUMBER_TY_HL, I"NUMBER_TY_to_REAL_NUMBER_TY", template);
	HierarchyLocations::make_in(NUMBER_TY_TO_TIME_TY_HL, I"NUMBER_TY_to_TIME_TY", template);
	HierarchyLocations::make_in(OTOVRELROUTETO_HL, I"OtoVRelRouteTo", template);
	HierarchyLocations::make_in(PACKED_TEXT_STORAGE_HL, I"PACKED_TEXT_STORAGE", template);
	HierarchyLocations::make_in(PARACONTENT_HL, I"ParaContent", template);
	HierarchyLocations::make_in(PARAMETER_VALUE_HL, I"parameter_value", template);
	HierarchyLocations::make_in(PARSED_NUMBER_HL, I"parsed_number", template);
	HierarchyLocations::make_in(PARSER_ACTION_HL, I"parser_action", template);
	HierarchyLocations::make_in(PARSER_ONE_HL, I"parser_one", template);
	HierarchyLocations::make_in(PARSER_TRACE_HL, I"parser_trace", template);
	HierarchyLocations::make_in(PARSER_TWO_HL, I"parser_two", template);
	HierarchyLocations::make_in(PARSERERROR_HL, I"ParserError", template);
	HierarchyLocations::make_in(PARSETOKENSTOPPED_HL, I"ParseTokenStopped", template);
	HierarchyLocations::make_in(PAST_CHRONOLOGICAL_RECORD_HL, I"past_chronological_record", template);
	HierarchyLocations::make_in(PLACEINSCOPE_HL, I"PlaceInScope", template);
	HierarchyLocations::make_in(PLAYER_HL, I"player", template);
	HierarchyLocations::make_in(PNTOVP_HL, I"PNToVP", template);
	HierarchyLocations::make_in(PRESENT_CHRONOLOGICAL_RECORD_HL, I"present_chronological_record", template);
	HierarchyLocations::make_in(PRINTORRUN_HL, I"PrintOrRun", template);
	HierarchyLocations::make_in(PRIOR_NAMED_LIST_HL, I"prior_named_list", template);
	HierarchyLocations::make_in(PRIOR_NAMED_LIST_GENDER_HL, I"prior_named_list_gender", template);
	HierarchyLocations::make_in(PRIOR_NAMED_NOUN_HL, I"prior_named_noun", template);
	HierarchyLocations::make_in(PROPERTY_LOOP_SIGN_HL, I"property_loop_sign", template);
	HierarchyLocations::make_in(PROPERTY_TO_BE_TOTALLED_HL, I"property_to_be_totalled", template);
	HierarchyLocations::make_in(REAL_LOCATION_HL, I"real_location", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_ABS_HL, I"REAL_NUMBER_TY_Abs", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_APPROXIMATE_HL, I"REAL_NUMBER_TY_Approximate", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_COMPARE_HL, I"REAL_NUMBER_TY_Compare", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_CUBE_ROOT_HL, I"REAL_NUMBER_TY_Cube_Root", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_DIVIDE_HL, I"REAL_NUMBER_TY_Divide", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_MINUS_HL, I"REAL_NUMBER_TY_Minus", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_NAN_HL, I"REAL_NUMBER_TY_Nan", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_NEGATE_HL, I"REAL_NUMBER_TY_Negate", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_PLUS_HL, I"REAL_NUMBER_TY_Plus", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_POW_HL, I"REAL_NUMBER_TY_Pow", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_REMAINDER_HL, I"REAL_NUMBER_TY_Remainder", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_ROOT_HL, I"REAL_NUMBER_TY_Root", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_SAY_HL, I"REAL_NUMBER_TY_Say", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_TIMES_HL, I"REAL_NUMBER_TY_Times", template);
	HierarchyLocations::make_in(REAL_NUMBER_TY_TO_NUMBER_TY_HL, I"REAL_NUMBER_TY_to_NUMBER_TY", template);
	HierarchyLocations::make_in(REASON_THE_ACTION_FAILED_HL, I"reason_the_action_failed", template);
	HierarchyLocations::make_in(RELATION_EMPTYEQUIV_HL, I"Relation_EmptyEquiv", template);
	HierarchyLocations::make_in(RELATION_EMPTYOTOO_HL, I"Relation_EmptyOtoO", template);
	HierarchyLocations::make_in(RELATION_EMPTYVTOV_HL, I"Relation_EmptyVtoV", template);
	HierarchyLocations::make_in(RELATION_RSHOWOTOO_HL, I"Relation_RShowOtoO", template);
	HierarchyLocations::make_in(RELATION_SHOWEQUIV_HL, I"Relation_ShowEquiv", template);
	HierarchyLocations::make_in(RELATION_SHOWOTOO_HL, I"Relation_ShowOtoO", template);
	HierarchyLocations::make_in(RELATION_SHOWVTOV_HL, I"Relation_ShowVtoV", template);
	HierarchyLocations::make_in(RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective", template);
	HierarchyLocations::make_in(RELATION_TY_NAME_HL, I"RELATION_TY_Name", template);
	HierarchyLocations::make_in(RELATION_TY_OTOOADJECTIVE_HL, I"RELATION_TY_OToOAdjective", template);
	HierarchyLocations::make_in(RELATION_TY_OTOVADJECTIVE_HL, I"RELATION_TY_OToVAdjective", template);
	HierarchyLocations::make_in(RELATION_TY_SYMMETRICADJECTIVE_HL, I"RELATION_TY_SymmetricAdjective", template);
	HierarchyLocations::make_in(RELATION_TY_VTOOADJECTIVE_HL, I"RELATION_TY_VToOAdjective", template);
	HierarchyLocations::make_in(RELATIONTEST_HL, I"RelationTest", template);
	HierarchyLocations::make_in(RELFOLLOWVECTOR_HL, I"RelFollowVector", template);
	HierarchyLocations::make_in(RELS_EMPTY_HL, I"RELS_EMPTY", template);
	HierarchyLocations::make_in(RESPONSEVIAACTIVITY_HL, I"ResponseViaActivity", template);
	HierarchyLocations::make_in(RLANY_CAN_GET_X_HL, I"RLANY_CAN_GET_X", template);
	HierarchyLocations::make_in(RLANY_CAN_GET_Y_HL, I"RLANY_CAN_GET_Y", template);
	HierarchyLocations::make_in(RLANY_GET_X_HL, I"RLANY_GET_X", template);
	HierarchyLocations::make_in(RLIST_ALL_X_HL, I"RLIST_ALL_X", template);
	HierarchyLocations::make_in(RLIST_ALL_Y_HL, I"RLIST_ALL_Y", template);
	HierarchyLocations::make_in(RLNGETF_HL, I"RlnGetF", template);
	HierarchyLocations::make_in(ROUNDOFFTIME_HL, I"RoundOffTime", template);
	HierarchyLocations::make_in(ROUTINEFILTER_TT_HL, I"ROUTINE_FILTER_TT", template);
	HierarchyLocations::make_in(RR_STORAGE_HL, I"RR_STORAGE", template);
	HierarchyLocations::make_in(RTP_RELKINDVIOLATION_HL, I"RTP_RELKINDVIOLATION", template);
	HierarchyLocations::make_in(RTP_RELMINIMAL_HL, I"RTP_RELMINIMAL", template);
	HierarchyLocations::make_in(RULEBOOKFAILS_HL, I"RulebookFails", template);
	HierarchyLocations::make_in(RULEBOOKPARBREAK_HL, I"RulebookParBreak", template);
	HierarchyLocations::make_in(RULEBOOKSUCCEEDS_HL, I"RulebookSucceeds", template);
	HierarchyLocations::make_in(RUNTIMEPROBLEM_HL, I"RunTimeProblem", template);
	HierarchyLocations::make_in(SAY__N_HL, I"say__n", template);
	HierarchyLocations::make_in(SAY__P_HL, I"say__p", template);
	HierarchyLocations::make_in(SAY__PC_HL, I"say__pc", template);
	HierarchyLocations::make_in(SCENE_ENDED_HL, I"scene_ended", template);
	HierarchyLocations::make_in(SCENE_ENDINGS_HL, I"scene_endings", template);
	HierarchyLocations::make_in(SCENE_LATEST_ENDING_HL, I"scene_latest_ending", template);
	HierarchyLocations::make_in(SCENE_STARTED_HL, I"scene_started", template);
	HierarchyLocations::make_in(SCENE_STATUS_HL, I"scene_status", template);
	HierarchyLocations::make_in(SCOPE_STAGE_HL, I"scope_stage", template);
	HierarchyLocations::make_in(SCOPE_TT_HL, I"SCOPE_TT", template);
	HierarchyLocations::make_in(SECOND_HL, I"second", template);
	HierarchyLocations::make_in(SHORT_NAME_HL, I"short_name", template);
	HierarchyLocations::make_in(SIGNEDCOMPARE_HL, I"SignedCompare", template);
	HierarchyLocations::make_in(SPECIAL_WORD_HL, I"special_word", template);
	HierarchyLocations::make_in(SQUAREROOT_HL, I"SquareRoot", template);
	HierarchyLocations::make_in(STACKFRAMECREATE_HL, I"StackFrameCreate", template);
	HierarchyLocations::make_in(STORED_ACTION_TY_CURRENT_HL, I"STORED_ACTION_TY_Current", template);
	HierarchyLocations::make_in(STORED_ACTION_TY_TRY_HL, I"STORED_ACTION_TY_Try", template);
	HierarchyLocations::make_in(STORY_TENSE_HL, I"story_tense", template);
	HierarchyLocations::make_in(SUPPORTER_HL, I"supporter", template);
	HierarchyLocations::make_in(SUPPRESS_SCOPE_LOOPS_HL, I"suppress_scope_loops", template);
	HierarchyLocations::make_in(SUPPRESS_TEXT_SUBSTITUTION_HL, I"suppress_text_substitution", template);
	HierarchyLocations::make_in(TABLE_NOVALUE_HL, I"TABLE_NOVALUE", template);
	HierarchyLocations::make_in(TABLELOOKUPCORR_HL, I"TableLookUpCorr", template);
	HierarchyLocations::make_in(TABLELOOKUPENTRY_HL, I"TableLookUpEntry", template);
	HierarchyLocations::make_in(TESTACTIONBITMAP_HL, I"TestActionBitmap", template);
	HierarchyLocations::make_in(TESTACTIVITY_HL, I"TestActivity", template);
	HierarchyLocations::make_in(TESTREGIONALCONTAINMENT_HL, I"TestRegionalContainment", template);
	HierarchyLocations::make_in(TESTSCOPE_HL, I"TestScope", template);
	HierarchyLocations::make_in(TESTSTART_HL, I"TestStart", template);
	HierarchyLocations::make_in(TEXT_TY_COMPARE_HL, I"TEXT_TY_Compare", template);
	HierarchyLocations::make_in(TEXT_TY_EXPANDIFPERISHABLE_HL, I"TEXT_TY_ExpandIfPerishable", template);
	HierarchyLocations::make_in(TEXT_TY_SAY_HL, I"TEXT_TY_Say", template);
	HierarchyLocations::make_in(THE_TIME_HL, I"the_time", template);
	HierarchyLocations::make_in(THEEMPTYTABLE_HL, I"TheEmptyTable", template);
	HierarchyLocations::make_in(THEN1__WD_HL, I"THEN1__WD", template);
	HierarchyLocations::make_in(TIMESACTIONHASBEENHAPPENING_HL, I"TimesActionHasBeenHappening", template);
	HierarchyLocations::make_in(TIMESACTIONHASHAPPENED_HL, I"TimesActionHasHappened", template);
	HierarchyLocations::make_in(TRYACTION_HL, I"TryAction", template);
	HierarchyLocations::make_in(TRYGIVENOBJECT_HL, I"TryGivenObject", template);
	HierarchyLocations::make_in(TURNSACTIONHASBEENHAPPENING_HL, I"TurnsActionHasBeenHappening", template);
	HierarchyLocations::make_in(UNDERSTAND_AS_MISTAKE_NUMBER_HL, I"understand_as_mistake_number", template);
	HierarchyLocations::make_in(UNICODE_TEMP_HL, I"unicode_temp", template);
	HierarchyLocations::make_in(VTOORELROUTETO_HL, I"VtoORelRouteTo", template);
	HierarchyLocations::make_in(VTOVRELROUTETO_HL, I"VtoVRelRouteTo", template);
	HierarchyLocations::make_in(WHEN_SCENE_BEGINS_HL, I"WHEN_SCENE_BEGINS_RB", template);
	HierarchyLocations::make_in(WHEN_SCENE_ENDS_HL, I"WHEN_SCENE_ENDS_RB", template);
	HierarchyLocations::make_in(WN_HL, I"wn", template);
	HierarchyLocations::make_in(WORDADDRESS_HL, I"WordAddress", template);
	HierarchyLocations::make_in(WORDINPROPERTY_HL, I"WordInProperty", template);
	HierarchyLocations::make_in(WORDLENGTH_HL, I"WordLength", template);

@

@e MAX_HL

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
		HierarchyLocations::make_in(-1, name, Packaging::request_template());
		try = HierarchyLocations::find_by_name(name);
	}
	return try;
}
