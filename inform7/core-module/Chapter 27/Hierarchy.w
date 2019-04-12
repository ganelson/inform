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
}

@

@e THESAME_NRL from 0
@e PLURALFOUND_NRL
@e PARENT_NRL
@e CHILD_NRL
@e SIBLING_NRL
@e SELF_NRL
@e THEDARK_NRL
@e DEBUG_NRL
@e TARGET_ZCODE_NRL
@e TARGET_GLULX_NRL
@e DICT_WORD_SIZE_NRL
@e WORDSIZE_NRL
@e NULL_NRL
@e WORD_HIGHBIT_NRL
@e WORD_NEXTTOHIGHBIT_NRL
@e IMPROBABLE_VALUE_NRL
@e REPARSE_CODE_NRL
@e MAX_POSITIVE_NUMBER_NRL
@e MIN_NEGATIVE_NUMBER_NRL
@e FLOAT_NAN_NRL
@e RESPONSETEXTS_NRL
@e CAP_SHORT_NAME_EXISTS_NRL
@e NI_BUILD_COUNT_NRL
@e RANKING_TABLE_NRL
@e PLUGIN_FILES_NRL
@e MAX_WEAK_ID_NRL
@e NO_VERB_VERB_DEFINED_NRL
@e NO_TEST_SCENARIOS_NRL
@e MEMORY_HEAP_SIZE_NRL

@<Establish generic basics@> =
	package_request *generic_basics = Packaging::generic_resource(BASICS_SUBMODULE);
	InterNames::make_in(THESAME_NRL, I"##TheSame", generic_basics);
	InterNames::make_in(PLURALFOUND_NRL, I"##PluralFound", generic_basics);
	InterNames::make_in(PARENT_NRL, I"parent", generic_basics);
	InterNames::make_in(CHILD_NRL, I"child", generic_basics);
	InterNames::make_in(SIBLING_NRL, I"sibling", generic_basics);
	InterNames::make_in(SELF_NRL, I"self", generic_basics);
	InterNames::make_in(THEDARK_NRL, I"thedark", generic_basics);
	InterNames::make_in(RESPONSETEXTS_NRL, I"ResponseTexts", generic_basics);
	InterNames::make_in(DEBUG_NRL, I"DEBUG", generic_basics);
	InterNames::make_in(TARGET_ZCODE_NRL, I"TARGET_ZCODE", generic_basics);
	InterNames::make_in(TARGET_GLULX_NRL, I"TARGET_GLULX", generic_basics);
	InterNames::make_in(DICT_WORD_SIZE_NRL, I"DICT_WORD_SIZE", generic_basics);
	InterNames::make_in(WORDSIZE_NRL, I"WORDSIZE", generic_basics);
	InterNames::make_in(NULL_NRL, I"NULL", generic_basics);
	InterNames::make_in(WORD_HIGHBIT_NRL, I"WORD_HIGHBIT", generic_basics);
	InterNames::make_in(WORD_NEXTTOHIGHBIT_NRL, I"WORD_NEXTTOHIGHBIT", generic_basics);
	InterNames::make_in(IMPROBABLE_VALUE_NRL, I"IMPROBABLE_VALUE", generic_basics);
	InterNames::make_in(REPARSE_CODE_NRL, I"REPARSE_CODE", generic_basics);
	InterNames::make_in(MAX_POSITIVE_NUMBER_NRL, I"MAX_POSITIVE_NUMBER", generic_basics);
	InterNames::make_in(MIN_NEGATIVE_NUMBER_NRL, I"MIN_NEGATIVE_NUMBER", generic_basics);
	InterNames::make_in(FLOAT_NAN_NRL, I"FLOAT_NAN", generic_basics);
	InterNames::make_in(CAP_SHORT_NAME_EXISTS_NRL, I"CAP_SHORT_NAME_EXISTS", generic_basics);
	InterNames::make_in(NI_BUILD_COUNT_NRL, I"NI_BUILD_COUNT", generic_basics);
	InterNames::make_in(RANKING_TABLE_NRL, I"RANKING_TABLE", generic_basics);
	InterNames::make_in(PLUGIN_FILES_NRL, I"PLUGIN_FILES", generic_basics);
	InterNames::make_in(MAX_WEAK_ID_NRL, I"MAX_WEAK_ID", generic_basics);
	InterNames::make_in(NO_VERB_VERB_DEFINED_NRL, I"NO_VERB_VERB_DEFINED", generic_basics);
	InterNames::make_in(NO_TEST_SCENARIOS_NRL, I"NO_TEST_SCENARIOS", generic_basics);
	InterNames::make_in(MEMORY_HEAP_SIZE_NRL, I"MEMORY_HEAP_SIZE", generic_basics);

@

@e CCOUNT_QUOTATIONS_NRL
@e MAX_FRAME_SIZE_NEEDED_NRL
@e RNG_SEED_AT_START_OF_PLAY_NRL

@<Establish synoptic basics@> =
	package_request *basics = Packaging::synoptic_resource(BASICS_SUBMODULE);
	InterNames::make_in(CCOUNT_QUOTATIONS_NRL, I"CCOUNT_QUOTATIONS", basics);
	InterNames::make_in(MAX_FRAME_SIZE_NEEDED_NRL, I"MAX_FRAME_SIZE_NEEDED", basics);
	InterNames::make_in(RNG_SEED_AT_START_OF_PLAY_NRL, I"RNG_SEED_AT_START_OF_PLAY", basics);

@

@e CV_MEANING_NRL
@e CV_MODAL_NRL
@e CV_NEG_NRL
@e CV_POS_NRL

@<Establish generic conjugations@> =
	package_request *conj = Packaging::generic_resource(CONJUGATIONS_SUBMODULE);
	InterNames::make_in(CV_MEANING_NRL, I"CV_MEANING", conj);
	InterNames::make_in(CV_MODAL_NRL, I"CV_MODAL", conj);
	InterNames::make_in(CV_NEG_NRL, I"CV_NEG", conj);
	InterNames::make_in(CV_POS_NRL, I"CV_POS", conj);

@

@e RELS_ASSERT_FALSE_NRL
@e RELS_ASSERT_TRUE_NRL
@e RELS_EQUIVALENCE_NRL
@e RELS_LIST_NRL
@e RELS_LOOKUP_ALL_X_NRL
@e RELS_LOOKUP_ALL_Y_NRL
@e RELS_LOOKUP_ANY_NRL
@e RELS_ROUTE_FIND_COUNT_NRL
@e RELS_ROUTE_FIND_NRL
@e RELS_SHOW_NRL
@e RELS_SYMMETRIC_NRL
@e RELS_TEST_NRL
@e RELS_X_UNIQUE_NRL
@e RELS_Y_UNIQUE_NRL
@e REL_BLOCK_HEADER_NRL
@e TTF_SUM_NRL
@e MEANINGLESS_RR_NRL

@<Establish generic relations@> =
	package_request *generic_rels = Packaging::generic_resource(RELATIONS_SUBMODULE);
	InterNames::make_in(RELS_ASSERT_FALSE_NRL, I"RELS_ASSERT_FALSE", generic_rels);
	InterNames::make_in(RELS_ASSERT_TRUE_NRL, I"RELS_ASSERT_TRUE", generic_rels);
	InterNames::make_in(RELS_EQUIVALENCE_NRL, I"RELS_EQUIVALENCE", generic_rels);
	InterNames::make_in(RELS_LIST_NRL, I"RELS_LIST", generic_rels);
	InterNames::make_in(RELS_LOOKUP_ALL_X_NRL, I"RELS_LOOKUP_ALL_X", generic_rels);
	InterNames::make_in(RELS_LOOKUP_ALL_Y_NRL, I"RELS_LOOKUP_ALL_Y", generic_rels);
	InterNames::make_in(RELS_LOOKUP_ANY_NRL, I"RELS_LOOKUP_ANY", generic_rels);
	InterNames::make_in(RELS_ROUTE_FIND_COUNT_NRL, I"RELS_ROUTE_FIND_COUNT", generic_rels);
	InterNames::make_in(RELS_ROUTE_FIND_NRL, I"RELS_ROUTE_FIND", generic_rels);
	InterNames::make_in(RELS_SHOW_NRL, I"RELS_SHOW", generic_rels);
	InterNames::make_in(RELS_SYMMETRIC_NRL, I"RELS_SYMMETRIC", generic_rels);
	InterNames::make_in(RELS_TEST_NRL, I"RELS_TEST", generic_rels);
	InterNames::make_in(RELS_X_UNIQUE_NRL, I"RELS_X_UNIQUE", generic_rels);
	InterNames::make_in(RELS_Y_UNIQUE_NRL, I"RELS_Y_UNIQUE", generic_rels);
	InterNames::make_in(REL_BLOCK_HEADER_NRL, I"REL_BLOCK_HEADER", generic_rels);
	InterNames::make_in(TTF_SUM_NRL, I"TTF_sum", generic_rels);
	InterNames::make_in(MEANINGLESS_RR_NRL, I"MEANINGLESS_RR", generic_rels);

@

@e CREATEDYNAMICRELATIONS_NRL
@e CCOUNT_BINARY_PREDICATE_NRL
@e ITERATERELATIONS_NRL
@e RPROPERTY_NRL

@<Establish synoptic relations@> =
	package_request *rels = Packaging::synoptic_resource(RELATIONS_SUBMODULE);
	InterNames::make_function(CREATEDYNAMICRELATIONS_NRL, I"creator_fn", I"CreateDynamicRelations", rels);
	InterNames::make_in(CCOUNT_BINARY_PREDICATE_NRL, I"CCOUNT_BINARY_PREDICATE", rels);
	InterNames::make_function(ITERATERELATIONS_NRL, I"iterator_fn", I"IterateRelations", rels);
	InterNames::make_function(RPROPERTY_NRL, I"property_fn", I"RProperty", rels);

@

@e MISTAKEACTION_NRL

@<Establish generic actions@> =
	package_request *generic_acts = Packaging::generic_resource(ACTIONS_SUBMODULE);
	InterNames::make_in(MISTAKEACTION_NRL, I"##MistakeAction", generic_acts);

@

@e ACTIONCODING_NRL
@e ACTIONDATA_NRL
@e ACTIONHAPPENED_NRL
@e AD_RECORDS_NRL
@e CCOUNT_ACTION_NAME_NRL
@e DB_ACTION_DETAILS_NRL
@e MISTAKEACTIONSUB_NRL

@<Establish synoptic actions@> =
	package_request *acts = Packaging::synoptic_resource(ACTIONS_SUBMODULE);
	InterNames::make_in(ACTIONCODING_NRL, I"ActionCoding", acts);
	InterNames::make_in(ACTIONDATA_NRL, I"ActionData", acts);
	InterNames::make_in(ACTIONHAPPENED_NRL, I"ActionHappened", acts);
	InterNames::make_in(AD_RECORDS_NRL, I"AD_RECORDS", acts);
	InterNames::make_in(CCOUNT_ACTION_NAME_NRL, I"CCOUNT_ACTION_NAME", acts);
	InterNames::make_function(DB_ACTION_DETAILS_NRL, I"DB_Action_Details_fn", I"DB_Action_Details", acts);
	InterNames::make_function(MISTAKEACTIONSUB_NRL, I"MistakeActionSub_fn", I"MistakeActionSub", acts);

@

@e ACTIVITY_AFTER_RULEBOOKS_NRL
@e ACTIVITY_ATB_RULEBOOKS_NRL
@e ACTIVITY_BEFORE_RULEBOOKS_NRL
@e ACTIVITY_FOR_RULEBOOKS_NRL
@e ACTIVITY_VAR_CREATORS_NRL

@<Establish synoptic activities@> =
	package_request *activities = Packaging::synoptic_resource(ACTIVITIES_SUBMODULE);
	InterNames::make_in(ACTIVITY_AFTER_RULEBOOKS_NRL, I"Activity_after_rulebooks", activities);
	InterNames::make_in(ACTIVITY_ATB_RULEBOOKS_NRL, I"Activity_atb_rulebooks", activities);
	InterNames::make_in(ACTIVITY_BEFORE_RULEBOOKS_NRL, I"Activity_before_rulebooks", activities);
	InterNames::make_in(ACTIVITY_FOR_RULEBOOKS_NRL, I"Activity_for_rulebooks", activities);
	InterNames::make_in(ACTIVITY_VAR_CREATORS_NRL, I"activity_var_creators", activities);

@

@e VERB_DIRECTIVE_CREATURE_NRL
@e VERB_DIRECTIVE_DIVIDER_NRL
@e VERB_DIRECTIVE_HELD_NRL
@e VERB_DIRECTIVE_MULTI_NRL
@e VERB_DIRECTIVE_MULTIEXCEPT_NRL
@e VERB_DIRECTIVE_MULTIHELD_NRL
@e VERB_DIRECTIVE_MULTIINSIDE_NRL
@e VERB_DIRECTIVE_NOUN_NRL
@e VERB_DIRECTIVE_NUMBER_NRL
@e VERB_DIRECTIVE_RESULT_NRL
@e VERB_DIRECTIVE_REVERSE_NRL
@e VERB_DIRECTIVE_SLASH_NRL
@e VERB_DIRECTIVE_SPECIAL_NRL
@e VERB_DIRECTIVE_TOPIC_NRL
@e TESTSCRIPTSUB_NRL
@e INTERNALTESTCASES_NRL

@<Establish synoptic grammar@> =
	package_request *grammar = Packaging::synoptic_resource(GRAMMAR_SUBMODULE);
	InterNames::make_in(VERB_DIRECTIVE_CREATURE_NRL, I"VERB_DIRECTIVE_CREATURE", grammar);
	InterNames::make_in(VERB_DIRECTIVE_DIVIDER_NRL, I"VERB_DIRECTIVE_DIVIDER", grammar);
	InterNames::make_in(VERB_DIRECTIVE_HELD_NRL, I"VERB_DIRECTIVE_HELD", grammar);
	InterNames::make_in(VERB_DIRECTIVE_MULTI_NRL, I"VERB_DIRECTIVE_MULTI", grammar);
	InterNames::make_in(VERB_DIRECTIVE_MULTIEXCEPT_NRL, I"VERB_DIRECTIVE_MULTIEXCEPT", grammar);
	InterNames::make_in(VERB_DIRECTIVE_MULTIHELD_NRL, I"VERB_DIRECTIVE_MULTIHELD", grammar);
	InterNames::make_in(VERB_DIRECTIVE_MULTIINSIDE_NRL, I"VERB_DIRECTIVE_MULTIINSIDE", grammar);
	InterNames::make_in(VERB_DIRECTIVE_NOUN_NRL, I"VERB_DIRECTIVE_NOUN", grammar);
	InterNames::make_in(VERB_DIRECTIVE_NUMBER_NRL, I"VERB_DIRECTIVE_NUMBER", grammar);
	InterNames::make_in(VERB_DIRECTIVE_RESULT_NRL, I"VERB_DIRECTIVE_RESULT", grammar);
	InterNames::make_in(VERB_DIRECTIVE_REVERSE_NRL, I"VERB_DIRECTIVE_REVERSE", grammar);
	InterNames::make_in(VERB_DIRECTIVE_SLASH_NRL, I"VERB_DIRECTIVE_SLASH", grammar);
	InterNames::make_in(VERB_DIRECTIVE_SPECIAL_NRL, I"VERB_DIRECTIVE_SPECIAL", grammar);
	InterNames::make_in(VERB_DIRECTIVE_TOPIC_NRL, I"VERB_DIRECTIVE_TOPIC", grammar);
	InterNames::make_function(TESTSCRIPTSUB_NRL, I"action_fn", I"TestScriptSub", grammar);
	InterNames::make_function(INTERNALTESTCASES_NRL, I"run_tests_fn", I"InternalTestCases", grammar);

@

@e UNKNOWN_TY_NRL

@<Establish generic kinds@> =
	package_request *generic_kinds = Packaging::generic_resource(KINDS_SUBMODULE);
	InterNames::make_in(UNKNOWN_TY_NRL, I"UNKNOWN_TY", generic_kinds);

@e DEFAULTVALUEOFKOV_NRL
@e DEFAULTVALUEFINDER_NRL
@e PRINTKINDVALUEPAIR_NRL
@e KOVCOMPARISONFUNCTION_NRL
@e KOVDOMAINSIZE_NRL
@e KOVISBLOCKVALUE_NRL
@e I7_KIND_NAME_NRL
@e KOVSUPPORTFUNCTION_NRL
@e SHOWMEDETAILS_NRL
@e BASE_KIND_HWM_NRL

@<Establish synoptic kinds@> =
	package_request *kinds = Packaging::synoptic_resource(KINDS_SUBMODULE);
	InterNames::make_in(BASE_KIND_HWM_NRL, I"BASE_KIND_HWM", kinds);
	InterNames::make_function(DEFAULTVALUEOFKOV_NRL, I"defaultvalue_fn", I"DefaultValueOfKOV", kinds);
	InterNames::make_function(DEFAULTVALUEFINDER_NRL, I"defaultvaluefinder_fn", I"DefaultValueFinder", kinds);
	InterNames::make_function(PRINTKINDVALUEPAIR_NRL, I"printkindvaluepair_fn", I"PrintKindValuePair", kinds);
	InterNames::make_function(KOVCOMPARISONFUNCTION_NRL, I"comparison_fn", I"KOVComparisonFunction", kinds);
	InterNames::make_function(KOVDOMAINSIZE_NRL, I"domainsize_fn", I"KOVDomainSize", kinds);
	InterNames::make_function(KOVISBLOCKVALUE_NRL, I"blockvalue_fn", I"KOVIsBlockValue", kinds);
	InterNames::make_function(I7_KIND_NAME_NRL, I"printkindname_fn", I"I7_Kind_Name", kinds);
	InterNames::make_function(KOVSUPPORTFUNCTION_NRL, I"support_fn", I"KOVSupportFunction", kinds);
	InterNames::make_function(SHOWMEDETAILS_NRL, I"showmedetails_fn", I"ShowMeDetails", kinds);

@

@e CCOUNT_PROPERTY_NRL

@<Establish synoptic resources@> =
	package_request *props = Packaging::synoptic_resource(PROPERTIES_SUBMODULE);
	InterNames::make_in(CCOUNT_PROPERTY_NRL, I"CCOUNT_PROPERTY", props);

@

@e RULEPRINTINGRULE_NRL
@e RESPONSEDIVISIONS_NRL

@<Establish synoptic rules@> =
	package_request *rules = Packaging::synoptic_resource(RULES_SUBMODULE);
	InterNames::make_in(RESPONSEDIVISIONS_NRL, I"ResponseDivisions", rules);
	InterNames::make_function(RULEPRINTINGRULE_NRL, I"print_fn", I"RulePrintingRule", rules);

@

@e EMPTY_RULEBOOK_INAME_NRL

@<Establish generic rulebooks@> =
	package_request *generic_rulebooks = Packaging::generic_resource(RULEBOOKS_SUBMODULE);
	InterNames::make_function(EMPTY_RULEBOOK_INAME_NRL, I"empty_fn", I"EMPTY_RULEBOOK", generic_rulebooks);

@

@e NUMBER_RULEBOOKS_CREATED_NRL
@e RULEBOOK_VAR_CREATORS_NRL
@e SLOW_LOOKUP_NRL
@e RULEBOOKS_ARRAY_NRL
@e RULEBOOKNAMES_NRL

@<Establish synoptic rulebooks@> =
	package_request *rulebooks = Packaging::synoptic_resource(RULEBOOKS_SUBMODULE);
	InterNames::make_in(NUMBER_RULEBOOKS_CREATED_NRL, I"NUMBER_RULEBOOKS_CREATED", rulebooks);
	InterNames::make_in(RULEBOOK_VAR_CREATORS_NRL, I"rulebook_var_creators", rulebooks);
	InterNames::make_function(SLOW_LOOKUP_NRL, I"slow_lookup_fn", I"MStack_GetRBVarCreator", rulebooks);
	InterNames::make_in(RULEBOOKS_ARRAY_NRL, I"rulebooks_array", rulebooks);
	InterNames::make_in(RULEBOOKNAMES_NRL, I"RulebookNames", rulebooks);
@

@e TC_KOV_NRL
@e TB_BLANKS_NRL

@<Establish synoptic tables@> =
	package_request *tables = Packaging::synoptic_resource(TABLES_SUBMODULE);
	InterNames::make_in(TB_BLANKS_NRL, I"TB_Blanks", tables);
	InterNames::make_function(TC_KOV_NRL, I"weak_kind_ID_of_column_entry_fn", I"TC_KOV", tables);

@

@e DEFAULT_SCORING_SETTING_NRL
@e INITIAL_MAX_SCORE_NRL
@e NO_DIRECTIONS_NRL
@e SHOWSCENESTATUS_NRL
@e DETECTSCENECHANGE_NRL
@e MAP_STORAGE_NRL
@e INITIALSITUATION_NRL
@e PLAYER_OBJECT_INIS_NRL
@e START_OBJECT_INIS_NRL
@e START_ROOM_INIS_NRL
@e START_TIME_INIS_NRL
@e DONE_INIS_NRL

@<Establish synoptic int-fiction@> =
	package_request *int_fiction = Packaging::synoptic_resource(IF_SUBMODULE);
	InterNames::make_in(DEFAULT_SCORING_SETTING_NRL, I"DEFAULT_SCORING_SETTING", int_fiction);
	InterNames::make_in(INITIAL_MAX_SCORE_NRL, I"INITIAL_MAX_SCORE", int_fiction);
	InterNames::make_in(NO_DIRECTIONS_NRL, I"No_Directions", int_fiction);
	InterNames::make_function(SHOWSCENESTATUS_NRL, I"show_scene_status_fn", I"ShowSceneStatus", int_fiction);
	InterNames::make_function(DETECTSCENECHANGE_NRL, I"detect_scene_change_fn", I"DetectSceneChange", int_fiction);
	InterNames::make_in(MAP_STORAGE_NRL, I"Map_Storage", int_fiction);
	InterNames::make_in(INITIALSITUATION_NRL, I"InitialSituation", int_fiction);
	InterNames::make_in(PLAYER_OBJECT_INIS_NRL, I"PLAYER_OBJECT_INIS", int_fiction);
	InterNames::make_in(START_OBJECT_INIS_NRL, I"START_OBJECT_INIS", int_fiction);
	InterNames::make_in(START_ROOM_INIS_NRL, I"START_ROOM_INIS", int_fiction);
	InterNames::make_in(START_TIME_INIS_NRL, I"START_TIME_INIS", int_fiction);
	InterNames::make_in(DONE_INIS_NRL, I"DONE_INIS", int_fiction);

@

@e TIMEDEVENTSTABLE_NRL
@e TIMEDEVENTTIMESTABLE_NRL
@e PASTACTIONSI6ROUTINES_NRL
@e NO_PAST_TENSE_CONDS_NRL
@e NO_PAST_TENSE_ACTIONS_NRL
@e TESTSINGLEPASTSTATE_NRL

@<Establish synoptic chronology@> =
	package_request *chronology = Packaging::synoptic_resource(CHRONOLOGY_SUBMODULE);
	InterNames::make_in(TIMEDEVENTSTABLE_NRL, I"TimedEventsTable", chronology);
	InterNames::make_in(TIMEDEVENTTIMESTABLE_NRL, I"TimedEventTimesTable", chronology);
	InterNames::make_in(PASTACTIONSI6ROUTINES_NRL, I"PastActionsI6Routines", chronology);
	InterNames::make_in(NO_PAST_TENSE_CONDS_NRL, I"NO_PAST_TENSE_CONDS", chronology);
	InterNames::make_in(NO_PAST_TENSE_ACTIONS_NRL, I"NO_PAST_TENSE_ACTIONS", chronology);
	InterNames::make_function(TESTSINGLEPASTSTATE_NRL, I"test_fn", I"TestSinglePastState", chronology);

@

@e UUID_ARRAY_NRL
@e STORY_NRL
@e HEADLINE_NRL
@e STORY_AUTHOR_NRL
@e RELEASE_NRL
@e SERIAL_NRL

@<Establish synoptic bibliographic@> =
	package_request *biblio = Packaging::synoptic_resource(BIBLIOGRAPHIC_SUBMODULE);
	InterNames::make_in(UUID_ARRAY_NRL, I"UUID_ARRAY", biblio);
	InterNames::make_datum(STORY_NRL, I"Story_datum", I"Story", biblio);
	InterNames::make_datum(HEADLINE_NRL, I"Headline_datum", I"Headline", biblio);
	InterNames::make_datum(STORY_AUTHOR_NRL, I"Story_Author_datum", I"Story_Author", biblio);
	InterNames::make_datum(RELEASE_NRL, I"Release_datum", I"Release", biblio);
	InterNames::make_datum(SERIAL_NRL, I"Serial_datum", I"Serial", biblio);

@

@e SHOWEXTENSIONVERSIONS_NRL
@e SHOWFULLEXTENSIONVERSIONS_NRL
@e SHOWONEEXTENSION_NRL

@<Establish synoptic extensions@> =
	package_request *extensions = Packaging::synoptic_resource(EXTENSIONS_SUBMODULE);
	InterNames::make_function(SHOWEXTENSIONVERSIONS_NRL, I"showextensionversions_fn", I"ShowExtensionVersions", extensions);
	InterNames::make_function(SHOWFULLEXTENSIONVERSIONS_NRL, I"showfullextensionversions_fn", I"ShowFullExtensionVersions", extensions);
	InterNames::make_function(SHOWONEEXTENSION_NRL, I"showoneextension_fn", I"ShowOneExtension", extensions);

@

@e NOTHING_NRL
@e OBJECT_NRL
@e TESTUSEOPTION_NRL
@e TABLEOFTABLES_NRL
@e TABLEOFVERBS_NRL
@e CAPSHORTNAME_NRL
@e COMMANDPROMPTTEXT_NRL
@e DECIMAL_TOKEN_INNER_NRL
@e NO_USE_OPTIONS_NRL
@e RESOURCEIDSOFFIGURES_NRL
@e RESOURCEIDSOFSOUNDS_NRL
@e TIME_TOKEN_INNER_NRL
@e TRUTH_STATE_TOKEN_INNER_NRL

@

@<The rest@> =
	InterNames::make_on_demand(OBJECT_NRL, I"Object");
	InterNames::make_on_demand(NOTHING_NRL, I"nothing");
	InterNames::make_on_demand(TESTUSEOPTION_NRL, I"TestUseOption");
	InterNames::make_on_demand(TABLEOFTABLES_NRL, I"TableOfTables");
	InterNames::make_on_demand(TABLEOFVERBS_NRL, I"TableOfVerbs");
	InterNames::make_on_demand(CAPSHORTNAME_NRL, I"cap_short_name");
	InterNames::make_on_demand(COMMANDPROMPTTEXT_NRL, I"CommandPromptText");
	InterNames::make_on_demand(DECIMAL_TOKEN_INNER_NRL, I"DECIMAL_TOKEN_INNER");
	InterNames::make_on_demand(NO_USE_OPTIONS_NRL, I"NO_USE_OPTIONS");
	InterNames::make_on_demand(RESOURCEIDSOFFIGURES_NRL, I"ResourceIDsOfFigures");
	InterNames::make_on_demand(RESOURCEIDSOFSOUNDS_NRL, I"ResourceIDsOfSounds");
	InterNames::make_on_demand(TIME_TOKEN_INNER_NRL, I"TIME_TOKEN_INNER");
	InterNames::make_on_demand(TRUTH_STATE_TOKEN_INNER_NRL, I"TRUTH_STATE_TOKEN_INNER");

@

@e MAX_NRL

@

=
inter_name *Hierarchy::find(int id) {
	return InterNames::find(id);
}
