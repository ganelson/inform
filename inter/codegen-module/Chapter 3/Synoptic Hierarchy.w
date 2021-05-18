[SynopticHierarchy::] Synoptic Hierarchy.

The layout and naming conventions for the contents of the main/synoptic module.

@

=
int SynopticHierarchy_established = FALSE;
void SynopticHierarchy::establish(inter_tree *I) {
	if (SynopticHierarchy_established) return;
	SynopticHierarchy_established = TRUE;
	location_requirement req;
	@<Establish actions@>;
	@<Establish activities@>;
	@<Establish chronology@>;
	@<Establish conjugations@>;
	@<Establish extensions@>;
	@<Establish instances@>;
	@<Establish kinds@>;
	@<Establish multimedia@>;
	@<Establish properties@>;
	@<Establish relations@>;
	@<Establish rulebooks@>;
	@<Establish rules@>;
	@<Establish scenes@>;
	@<Establish tables@>;
	@<Establish use options@>;
	@<Establish kit-defined resources@>;
}

@

@d SYN_SUBMD(r) req = HierarchyLocations::synoptic_submodule(I, Packaging::register_submodule(r));
@d SYN_CONST(id, n) {
		HierarchyLocations::ctr(I, id, n,    Translation::same(),      req);
		inter_name *iname = HierarchyLocations::find(I, id);
		inter_symbol *S = InterNames::to_symbol(iname);
		Inter::Connectors::socket(I, InterNames::to_text(iname), S);
	}
@d SYN_FUNCT(id, n, t) {
		HierarchyLocations::fun(I, id, n,    Translation::to(t),       req);
		inter_name *iname = HierarchyLocations::find(I, id);
		inter_symbol *S = InterNames::to_symbol(iname);
		Inter::Connectors::socket(I, Produce::get_translation(iname), S);
	}
@d KIT_PROVIDED(id, n)
		HierarchyLocations::ctr(I, id, n,    Translation::same(),      req);

@h Actions.

@e ACTIONCODING_HL from 0
@e ACTIONDATA_HL
@e ACTIONHAPPENED_HL
@e AD_RECORDS_HL
@e CCOUNT_ACTION_NAME_HL
@e DB_ACTION_DETAILS_HL

@<Establish actions@> =
	SYN_SUBMD(I"actions")
		SYN_CONST(ACTIONCODING_HL,                I"ActionCoding")
		SYN_CONST(ACTIONDATA_HL,                  I"ActionData")
		SYN_CONST(ACTIONHAPPENED_HL,              I"ActionHappened")
		SYN_CONST(AD_RECORDS_HL,                  I"AD_RECORDS")
		SYN_CONST(CCOUNT_ACTION_NAME_HL,          I"CCOUNT_ACTION_NAME")
		SYN_FUNCT(DB_ACTION_DETAILS_HL,           I"DB_Action_Details_fn", I"DB_Action_Details")

@h Activities.

@e ACTIVITY_AFTER_RULEBOOKS_HL
@e ACTIVITY_ATB_RULEBOOKS_HL
@e ACTIVITY_BEFORE_RULEBOOKS_HL
@e ACTIVITY_FOR_RULEBOOKS_HL
@e ACTIVITY_VAR_CREATORS_HL

@<Establish activities@> =
	SYN_SUBMD(I"activities")
		SYN_CONST(ACTIVITY_AFTER_RULEBOOKS_HL,    I"Activity_after_rulebooks")
		SYN_CONST(ACTIVITY_ATB_RULEBOOKS_HL,      I"Activity_atb_rulebooks")
		SYN_CONST(ACTIVITY_BEFORE_RULEBOOKS_HL,   I"Activity_before_rulebooks")
		SYN_CONST(ACTIVITY_FOR_RULEBOOKS_HL,      I"Activity_for_rulebooks")
		SYN_CONST(ACTIVITY_VAR_CREATORS_HL,       I"activity_var_creators")

@h Chronology.

@e TIMEDEVENTSTABLE_HL
@e TIMEDEVENTTIMESTABLE_HL
@e PASTACTIONSI6ROUTINES_HL
@e NO_PAST_TENSE_CONDS_HL
@e NO_PAST_TENSE_ACTIONS_HL
@e TESTSINGLEPASTSTATE_HL

@<Establish chronology@> =
	SYN_SUBMD(I"chronology")
		SYN_CONST(TIMEDEVENTSTABLE_HL,            I"TimedEventsTable")
		SYN_CONST(TIMEDEVENTTIMESTABLE_HL,        I"TimedEventTimesTable")
		SYN_CONST(PASTACTIONSI6ROUTINES_HL,       I"PastActionsI6Routines")
		SYN_CONST(NO_PAST_TENSE_CONDS_HL,         I"NO_PAST_TENSE_CONDS")
		SYN_CONST(NO_PAST_TENSE_ACTIONS_HL,       I"NO_PAST_TENSE_ACTIONS")
		SYN_FUNCT(TESTSINGLEPASTSTATE_HL,         I"test_fn", I"TestSinglePastState")

@h Conjugations.

@e TABLEOFVERBS_HL

@<Establish conjugations@> =
	SYN_SUBMD(I"conjugations")
		SYN_CONST(TABLEOFVERBS_HL,                I"TableOfVerbs")

@h Extensions.

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish extensions@> =
	SYN_SUBMD(I"extensions")
		SYN_FUNCT(SHOWEXTENSIONVERSIONS_HL,       I"showextensionversions_fn", I"ShowExtensionVersions")
		SYN_FUNCT(SHOWFULLEXTENSIONVERSIONS_HL,   I"showfullextensionversions_fn", I"ShowFullExtensionVersions")
		SYN_FUNCT(SHOWONEEXTENSION_HL,            I"showoneextension_fn", I"ShowOneExtension")

@h Instances.

@e SHOWMEINSTANCEDETAILS_HL

@<Establish instances@> =
	SYN_SUBMD(I"instances")
		SYN_FUNCT(SHOWMEINSTANCEDETAILS_HL,       I"showmeinstancedetails_fn", I"ShowMeInstanceDetails")

@h Kinds.

@e DEFAULTVALUEOFKOV_HL
@e DEFAULTVALUEFINDER_HL
@e PRINTKINDVALUEPAIR_HL
@e KOVCOMPARISONFUNCTION_HL
@e KOVDOMAINSIZE_HL
@e KOVISBLOCKVALUE_HL
@e I7_KIND_NAME_HL
@e KOVSUPPORTFUNCTION_HL
@e SHOWMEKINDDETAILS_HL
@e BASE_KIND_HWM_HL
@e RUCKSACK_CLASS_HL

@<Establish kinds@> =
	SYN_SUBMD(I"kinds")
		SYN_CONST(BASE_KIND_HWM_HL,               I"BASE_KIND_HWM")
		SYN_FUNCT(DEFAULTVALUEOFKOV_HL,           I"defaultvalue_fn", I"DefaultValueOfKOV")
		SYN_FUNCT(DEFAULTVALUEFINDER_HL,          I"defaultvaluefinder_fn", I"DefaultValueFinder")
		SYN_FUNCT(PRINTKINDVALUEPAIR_HL,          I"printkindvaluepair_fn", I"PrintKindValuePair")
		SYN_FUNCT(KOVCOMPARISONFUNCTION_HL,       I"comparison_fn", I"KOVComparisonFunction")
		SYN_FUNCT(KOVDOMAINSIZE_HL,               I"domainsize_fn", I"KOVDomainSize")
		SYN_FUNCT(KOVISBLOCKVALUE_HL,             I"blockvalue_fn", I"KOVIsBlockValue")
		SYN_FUNCT(I7_KIND_NAME_HL,                I"printkindname_fn", I"I7_Kind_Name")
		SYN_FUNCT(KOVSUPPORTFUNCTION_HL,          I"support_fn", I"KOVSupportFunction")
		SYN_FUNCT(SHOWMEKINDDETAILS_HL,           I"showmekinddetails_fn", I"ShowMeKindDetails")
		SYN_CONST(RUCKSACK_CLASS_HL,              I"RUCKSACK_CLASS")

@h Multimedia.

@e RESOURCEIDSOFFIGURES_HL
@e RESOURCEIDSOFSOUNDS_HL
@e NO_EXTERNAL_FILES_HL
@e TABLEOFEXTERNALFILES_HL

@<Establish multimedia@> =
	SYN_SUBMD(I"multimedia")
		SYN_CONST(RESOURCEIDSOFFIGURES_HL,        I"ResourceIDsOfFigures")
		SYN_CONST(RESOURCEIDSOFSOUNDS_HL,         I"ResourceIDsOfSounds")
		SYN_CONST(NO_EXTERNAL_FILES_HL,           I"NO_EXTERNAL_FILES")
		SYN_CONST(TABLEOFEXTERNALFILES_HL,        I"TableOfExternalFiles")

@h Properties.

@e CCOUNT_PROPERTY_HL

@<Establish properties@> =
	SYN_SUBMD(I"properties")
		SYN_CONST(CCOUNT_PROPERTY_HL,             I"CCOUNT_PROPERTY")

@h Relations.

@e CREATEDYNAMICRELATIONS_HL
@e CCOUNT_BINARY_PREDICATE_HL
@e ITERATERELATIONS_HL
@e RPROPERTY_HL

@<Establish relations@> =
	SYN_SUBMD(I"relations")
		SYN_FUNCT(CREATEDYNAMICRELATIONS_HL,      I"creator_fn", I"CreateDynamicRelations")
		SYN_CONST(CCOUNT_BINARY_PREDICATE_HL,     I"CCOUNT_BINARY_PREDICATE")
		SYN_FUNCT(ITERATERELATIONS_HL,            I"iterator_fn", I"IterateRelations")
		SYN_FUNCT(RPROPERTY_HL,                   I"property_fn", I"RProperty")

@h Rulebooks.

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish rulebooks@> =
	SYN_SUBMD(I"rulebooks")
		SYN_CONST(NUMBER_RULEBOOKS_CREATED_HL,    I"NUMBER_RULEBOOKS_CREATED")
		SYN_CONST(RULEBOOK_VAR_CREATORS_HL,       I"rulebook_var_creators")
		SYN_FUNCT(SLOW_LOOKUP_HL,                 I"slow_lookup_fn", I"MStack_GetRBVarCreator")
		SYN_CONST(RULEBOOKS_ARRAY_HL,             I"rulebooks_array")
		SYN_CONST(RULEBOOKNAMES_HL,               I"RulebookNames")

@h Rules.

@e RULEPRINTINGRULE_HL

@e RESPONSETEXTS_HL
@e NO_RESPONSES_HL
@e RESPONSEDIVISIONS_HL
@e PRINT_RESPONSE_HL

@<Establish rules@> =
	SYN_SUBMD(I"rules")
		SYN_FUNCT(RULEPRINTINGRULE_HL,            I"print_fn", I"RulePrintingRule")

	SYN_SUBMD(I"responses")
		SYN_CONST(RESPONSEDIVISIONS_HL,           I"ResponseDivisions")
		SYN_CONST(RESPONSETEXTS_HL,               I"ResponseTexts")
		SYN_CONST(NO_RESPONSES_HL,                I"NO_RESPONSES")
		SYN_FUNCT(PRINT_RESPONSE_HL,              I"print_fn", I"PrintResponse")

@h Scenes.

@e SHOWSCENESTATUS_HL
@e DETECTSCENECHANGE_HL

@<Establish scenes@> =
	SYN_SUBMD(I"scenes")
		SYN_FUNCT(SHOWSCENESTATUS_HL,             I"show_scene_status_fn", I"ShowSceneStatus")
		SYN_FUNCT(DETECTSCENECHANGE_HL,           I"detect_scene_change_fn", I"DetectSceneChange")

@h Tables.

@e PRINT_TABLE_HL
@e TABLEOFTABLES_HL
@e TB_BLANKS_HL
@e RANKING_TABLE_HL

@e TC_KOV_HL

@<Establish tables@> =
	SYN_SUBMD(I"tables")
		SYN_FUNCT(PRINT_TABLE_HL,                 I"print_fn", I"PrintTableName")
		SYN_CONST(TABLEOFTABLES_HL,               I"TableOfTables")
		SYN_CONST(TB_BLANKS_HL,                   I"TB_Blanks")
		SYN_CONST(RANKING_TABLE_HL,               I"RANKING_TABLE")

	SYN_SUBMD(I"table_columns")
		SYN_FUNCT(TC_KOV_HL,                      I"weak_kind_ID_of_column_entry_fn", I"TC_KOV")

@h Use options.

@e NO_USE_OPTIONS_HL
@e TESTUSEOPTION_HL
@e PRINT_USE_OPTION_HL

@<Establish use options@> =
	SYN_SUBMD(I"use_options")
		SYN_CONST(NO_USE_OPTIONS_HL,              I"NO_USE_OPTIONS")
		SYN_FUNCT(TESTUSEOPTION_HL,               I"test_fn", I"TestUseOption")
		SYN_FUNCT(PRINT_USE_OPTION_HL,            I"print_fn", I"PrintUseOption")

@h Kit-defined symbols.
The Inform 7 compiler creates none of the constants below. (Note that some are
the addresses of functions, but they are constants for our purposes here.)
Instead, they are defined using Inform 6 notation in one of the kits. We don't
need to know which kit; we simply leaves them as "plugs" to be connected to
"sockets" in the linking stage -- see //bytecode: Connectors//.

@e THESAME_HL
@e PLURALFOUND_HL
@e THEDARK_HL
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
@e DETECTPLURALWORD_HL
@e DIGITTOVALUE_HL
@e DIVIDEPARAGRAPHPOINT_HL
@e DOUBLEHASHSETRELATIONHANDLER_HL
@e DURINGSCENEMATCHING_HL
@e ELEMENTARY_TT_HL
@e EMPTY_RULEBOOK_INAME_HL
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
@e ROUNDOFFVALUE_HL
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

@<Establish kit-defined resources@> =
	req = HierarchyLocations::plug();
		KIT_PROVIDED(THESAME_HL,                          I"##TheSame")
		KIT_PROVIDED(PLURALFOUND_HL,                      I"##PluralFound")
		KIT_PROVIDED(THEDARK_HL,                          I"thedark")
		KIT_PROVIDED(ACT_REQUESTER_HL,                    I"act_requester")
		KIT_PROVIDED(ACTION_HL,                           I"action")
		KIT_PROVIDED(ACTIONCURRENTLYHAPPENINGFLAG_HL,     I"ActionCurrentlyHappeningFlag")
		KIT_PROVIDED(ACTOR_HL,                            I"actor")
		KIT_PROVIDED(ACTOR_LOCATION_HL,                   I"actor_location")
		KIT_PROVIDED(ADJUSTPARAGRAPHPOINT_HL,             I"AdjustParagraphPoint")
		KIT_PROVIDED(ALLOWINSHOWME_HL,                    I"AllowInShowme")
		KIT_PROVIDED(ANIMATE_HL,                          I"animate")
		KIT_PROVIDED(ARGUMENTTYPEFAILED_HL,               I"ArgumentTypeFailed")
		KIT_PROVIDED(ARTICLEDESCRIPTORS_HL,               I"ArticleDescriptors")
		KIT_PROVIDED(AUXF_MAGIC_VALUE_HL,                 I"AUXF_MAGIC_VALUE")
		KIT_PROVIDED(AUXF_STATUS_IS_CLOSED_HL,            I"AUXF_STATUS_IS_CLOSED")
		KIT_PROVIDED(BLKVALUECOPY_HL,                     I"BlkValueCopy")
		KIT_PROVIDED(BLKVALUECOPYAZ_HL,                   I"BlkValueCopyAZ")
		KIT_PROVIDED(BLKVALUECREATE_HL,                   I"BlkValueCreate")
		KIT_PROVIDED(BLKVALUECREATEONSTACK_HL,            I"BlkValueCreateOnStack")
		KIT_PROVIDED(BLKVALUEERROR_HL,                    I"BlkValueError")
		KIT_PROVIDED(BLKVALUEFREE_HL,                     I"BlkValueFree")
		KIT_PROVIDED(BLKVALUEFREEONSTACK_HL,              I"BlkValueFreeOnStack")
		KIT_PROVIDED(BLKVALUEWRITE_HL,                    I"BlkValueWrite")
		KIT_PROVIDED(C_STYLE_HL,                          I"c_style")
		KIT_PROVIDED(CHECKKINDRETURNED_HL,                I"CheckKindReturned")
		KIT_PROVIDED(CLEARPARAGRAPHING_HL,                I"ClearParagraphing")
		KIT_PROVIDED(COMPONENT_CHILD_HL,                  I"component_child")
		KIT_PROVIDED(COMPONENT_PARENT_HL,                 I"component_parent")
		KIT_PROVIDED(COMPONENT_SIBLING_HL,                I"component_sibling")
		KIT_PROVIDED(CONSTANT_PACKED_TEXT_STORAGE_HL,     I"CONSTANT_PACKED_TEXT_STORAGE")
		KIT_PROVIDED(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE")
		KIT_PROVIDED(CONSULT_FROM_HL,                     I"consult_from")
		KIT_PROVIDED(CONSULT_WORDS_HL,                    I"consult_words")
		KIT_PROVIDED(CONTAINER_HL,                        I"container")
		KIT_PROVIDED(CUBEROOT_HL,                         I"CubeRoot")
		KIT_PROVIDED(DA_NAME_HL,                          I"DA_Name")
		KIT_PROVIDED(DB_RULE_HL,                          I"DB_Rule")
		KIT_PROVIDED(DEADFLAG_HL,                         I"deadflag")
		KIT_PROVIDED(DEBUG_RULES_HL,                      I"debug_rules")
		KIT_PROVIDED(DEBUG_SCENES_HL,                     I"debug_scenes")
		KIT_PROVIDED(DECIMALNUMBER_HL,                    I"DecimalNumber")
		KIT_PROVIDED(DETECTPLURALWORD_HL,                 I"DetectPluralWord")
		KIT_PROVIDED(DIGITTOVALUE_HL,                     I"DigitToValue")
		KIT_PROVIDED(DIVIDEPARAGRAPHPOINT_HL,             I"DivideParagraphPoint")
		KIT_PROVIDED(DOUBLEHASHSETRELATIONHANDLER_HL,     I"DoubleHashSetRelationHandler")
		KIT_PROVIDED(DURINGSCENEMATCHING_HL,              I"DuringSceneMatching")
		KIT_PROVIDED(ELEMENTARY_TT_HL,                    I"ELEMENTARY_TT")
		KIT_PROVIDED(EMPTY_RULEBOOK_INAME_HL,             I"EMPTY_RULEBOOK")
		KIT_PROVIDED(EMPTY_TABLE_HL,                      I"TheEmptyTable")
		KIT_PROVIDED(EMPTY_TEXT_PACKED_HL,                I"EMPTY_TEXT_PACKED")
		KIT_PROVIDED(EMPTY_TEXT_VALUE_HL,                 I"EMPTY_TEXT_VALUE")
		KIT_PROVIDED(EMPTYRELATIONHANDLER_HL,             I"EmptyRelationHandler")
		KIT_PROVIDED(ENGLISH_BIT_HL,                      I"ENGLISH_BIT")
		KIT_PROVIDED(ETYPE_HL,                            I"etype")
		KIT_PROVIDED(EXISTSTABLELOOKUPCORR_HL,            I"ExistsTableLookUpCorr")
		KIT_PROVIDED(EXISTSTABLELOOKUPENTRY_HL,           I"ExistsTableLookUpEntry")
		KIT_PROVIDED(EXISTSTABLEROWCORR_HL,               I"ExistsTableRowCorr")
		KIT_PROVIDED(FLOATPARSE_HL,                       I"FloatParse")
		KIT_PROVIDED(FOLLOWRULEBOOK_HL,                   I"FollowRulebook")
		KIT_PROVIDED(formal_par0_HL,                      I"formal_par0")
		KIT_PROVIDED(formal_par1_HL,                      I"formal_par1")
		KIT_PROVIDED(formal_par2_HL,                      I"formal_par2")
		KIT_PROVIDED(formal_par3_HL,                      I"formal_par3")
		KIT_PROVIDED(formal_par4_HL,                      I"formal_par4")
		KIT_PROVIDED(formal_par5_HL,                      I"formal_par5")
		KIT_PROVIDED(formal_par6_HL,                      I"formal_par6")
		KIT_PROVIDED(formal_par7_HL,                      I"formal_par7")
		KIT_PROVIDED(FORMAL_RV_HL,                        I"formal_rv")
		KIT_PROVIDED(FOUND_EVERYWHERE_HL,                 I"FoundEverywhere")
		KIT_PROVIDED(GENERATERANDOMNUMBER_HL,             I"GenerateRandomNumber")
		KIT_PROVIDED(GENERICVERBSUB_HL,                   I"GenericVerbSub")
		KIT_PROVIDED(GETGNAOFOBJECT_HL,                   I"GetGNAOfObject")
		KIT_PROVIDED(GPR_FAIL_HL,                         I"GPR_FAIL")
		KIT_PROVIDED(GPR_NUMBER_HL,                       I"GPR_NUMBER")
		KIT_PROVIDED(GPR_PREPOSITION_HL,                  I"GPR_PREPOSITION")
		KIT_PROVIDED(GPR_TT_HL,                           I"GPR_TT")
		KIT_PROVIDED(GPROPERTY_HL,                        I"GProperty")
		KIT_PROVIDED(HASHLISTRELATIONHANDLER_HL,          I"HashListRelationHandler")
		KIT_PROVIDED(I7SFRAME_HL,                         I"I7SFRAME")
		KIT_PROVIDED(INDENT_BIT_HL,                       I"INDENT_BIT")
		KIT_PROVIDED(INP1_HL,                             I"inp1")
		KIT_PROVIDED(INP2_HL,                             I"inp2")
		KIT_PROVIDED(INTEGERDIVIDE_HL,                    I"IntegerDivide")
		KIT_PROVIDED(INTEGERREMAINDER_HL,                 I"IntegerRemainder")
		KIT_PROVIDED(INVENTORY_STAGE_HL,                  I"inventory_stage")
		KIT_PROVIDED(KEEP_SILENT_HL,                      I"keep_silent")
		KIT_PROVIDED(KINDATOMIC_HL,                       I"KindAtomic")
		KIT_PROVIDED(LATEST_RULE_RESULT_HL,               I"latest_rule_result")
		KIT_PROVIDED(LIST_ITEM_BASE_HL,                   I"LIST_ITEM_BASE")
		KIT_PROVIDED(LIST_ITEM_KOV_F_HL,                  I"LIST_ITEM_KOV_F")
		KIT_PROVIDED(LIST_OF_TY_DESC_HL,                  I"LIST_OF_TY_Desc")
		KIT_PROVIDED(LIST_OF_TY_GETITEM_HL,               I"LIST_OF_TY_GetItem")
		KIT_PROVIDED(LIST_OF_TY_GETLENGTH_HL,             I"LIST_OF_TY_GetLength")
		KIT_PROVIDED(LIST_OF_TY_INSERTITEM_HL,            I"LIST_OF_TY_InsertItem")
		KIT_PROVIDED(LIST_OF_TY_SAY_HL,                   I"LIST_OF_TY_Say")
		KIT_PROVIDED(LIST_OF_TY_SETLENGTH_HL,             I"LIST_OF_TY_SetLength")
		KIT_PROVIDED(LOCATION_HL,                         I"location")
		KIT_PROVIDED(LOCATIONOF_HL,                       I"LocationOf")
		KIT_PROVIDED(LOOPOVERSCOPE_HL,                    I"LoopOverScope")
		KIT_PROVIDED(LOS_RV_HL,                           I"los_rv")
		KIT_PROVIDED(MSTACK_HL,                           I"MStack")
		KIT_PROVIDED(MSTVO_HL,                            I"MstVO")
		KIT_PROVIDED(MSTVON_HL,                           I"MstVON")
		KIT_PROVIDED(NAME_HL,                             I"name")
		KIT_PROVIDED(NEWLINE_BIT_HL,                      I"NEWLINE_BIT")
		KIT_PROVIDED(NEXTBEST_ETYPE_HL,                   I"nextbest_etype")
		KIT_PROVIDED(NEXTWORDSTOPPED_HL,                  I"NextWordStopped")
		KIT_PROVIDED(NOARTICLE_BIT_HL,                    I"NOARTICLE_BIT")
		KIT_PROVIDED(NOTINCONTEXTPE_HL,                   I"NOTINCONTEXT_PE")
		KIT_PROVIDED(NOUN_HL,                             I"noun")
		KIT_PROVIDED(NUMBER_TY_ABS_HL,                    I"NUMBER_TY_Abs")
		KIT_PROVIDED(NUMBER_TY_TO_REAL_NUMBER_TY_HL,      I"NUMBER_TY_to_REAL_NUMBER_TY")
		KIT_PROVIDED(NUMBER_TY_TO_TIME_TY_HL,             I"NUMBER_TY_to_TIME_TY")
		KIT_PROVIDED(OTOVRELROUTETO_HL,                   I"OtoVRelRouteTo")
		KIT_PROVIDED(PACKED_TEXT_STORAGE_HL,              I"PACKED_TEXT_STORAGE")
		KIT_PROVIDED(PARACONTENT_HL,                      I"ParaContent")
		KIT_PROVIDED(PARAMETER_VALUE_HL,                  I"parameter_value")
		KIT_PROVIDED(PARSED_NUMBER_HL,                    I"parsed_number")
		KIT_PROVIDED(PARSER_ACTION_HL,                    I"parser_action")
		KIT_PROVIDED(PARSER_ONE_HL,                       I"parser_one")
		KIT_PROVIDED(PARSER_TRACE_HL,                     I"parser_trace")
		KIT_PROVIDED(PARSER_TWO_HL,                       I"parser_two")
		KIT_PROVIDED(PARSERERROR_HL,                      I"ParserError")
		KIT_PROVIDED(PARSETOKENSTOPPED_HL,                I"ParseTokenStopped")
		KIT_PROVIDED(PAST_CHRONOLOGICAL_RECORD_HL,        I"past_chronological_record")
		KIT_PROVIDED(PLACEINSCOPE_HL,                     I"PlaceInScope")
		KIT_PROVIDED(PLAYER_HL,                           I"player")
		KIT_PROVIDED(PNTOVP_HL,                           I"PNToVP")
		KIT_PROVIDED(PRESENT_CHRONOLOGICAL_RECORD_HL,     I"present_chronological_record")
		KIT_PROVIDED(PRINTORRUN_HL,                       I"PrintOrRun")
		KIT_PROVIDED(PRIOR_NAMED_LIST_HL,                 I"prior_named_list")
		KIT_PROVIDED(PRIOR_NAMED_LIST_GENDER_HL,          I"prior_named_list_gender")
		KIT_PROVIDED(PRIOR_NAMED_NOUN_HL,                 I"prior_named_noun")
		KIT_PROVIDED(PROPERTY_LOOP_SIGN_HL,               I"property_loop_sign")
		KIT_PROVIDED(PROPERTY_TO_BE_TOTALLED_HL,          I"property_to_be_totalled")
		KIT_PROVIDED(REAL_LOCATION_HL,                    I"real_location")
		KIT_PROVIDED(REAL_NUMBER_TY_ABS_HL,               I"REAL_NUMBER_TY_Abs")
		KIT_PROVIDED(REAL_NUMBER_TY_APPROXIMATE_HL,       I"REAL_NUMBER_TY_Approximate")
		KIT_PROVIDED(REAL_NUMBER_TY_COMPARE_HL,           I"REAL_NUMBER_TY_Compare")
		KIT_PROVIDED(REAL_NUMBER_TY_CUBE_ROOT_HL,         I"REAL_NUMBER_TY_Cube_Root")
		KIT_PROVIDED(REAL_NUMBER_TY_DIVIDE_HL,            I"REAL_NUMBER_TY_Divide")
		KIT_PROVIDED(REAL_NUMBER_TY_MINUS_HL,             I"REAL_NUMBER_TY_Minus")
		KIT_PROVIDED(REAL_NUMBER_TY_NAN_HL,               I"REAL_NUMBER_TY_Nan")
		KIT_PROVIDED(REAL_NUMBER_TY_NEGATE_HL,            I"REAL_NUMBER_TY_Negate")
		KIT_PROVIDED(REAL_NUMBER_TY_PLUS_HL,              I"REAL_NUMBER_TY_Plus")
		KIT_PROVIDED(REAL_NUMBER_TY_POW_HL,               I"REAL_NUMBER_TY_Pow")
		KIT_PROVIDED(REAL_NUMBER_TY_REMAINDER_HL,         I"REAL_NUMBER_TY_Remainder")
		KIT_PROVIDED(REAL_NUMBER_TY_ROOT_HL,              I"REAL_NUMBER_TY_Root")
		KIT_PROVIDED(REAL_NUMBER_TY_SAY_HL,               I"REAL_NUMBER_TY_Say")
		KIT_PROVIDED(REAL_NUMBER_TY_TIMES_HL,             I"REAL_NUMBER_TY_Times")
		KIT_PROVIDED(REAL_NUMBER_TY_TO_NUMBER_TY_HL,      I"REAL_NUMBER_TY_to_NUMBER_TY")
		KIT_PROVIDED(REASON_THE_ACTION_FAILED_HL,         I"reason_the_action_failed")
		KIT_PROVIDED(RELATION_EMPTYEQUIV_HL,              I"Relation_EmptyEquiv")
		KIT_PROVIDED(RELATION_EMPTYOTOO_HL,               I"Relation_EmptyOtoO")
		KIT_PROVIDED(RELATION_EMPTYVTOV_HL,               I"Relation_EmptyVtoV")
		KIT_PROVIDED(RELATION_RSHOWOTOO_HL,               I"Relation_RShowOtoO")
		KIT_PROVIDED(RELATION_SHOWEQUIV_HL,               I"Relation_ShowEquiv")
		KIT_PROVIDED(RELATION_SHOWOTOO_HL,                I"Relation_ShowOtoO")
		KIT_PROVIDED(RELATION_SHOWVTOV_HL,                I"Relation_ShowVtoV")
		KIT_PROVIDED(RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective")
		KIT_PROVIDED(RELATION_TY_NAME_HL,                 I"RELATION_TY_Name")
		KIT_PROVIDED(RELATION_TY_OTOOADJECTIVE_HL,        I"RELATION_TY_OToOAdjective")
		KIT_PROVIDED(RELATION_TY_OTOVADJECTIVE_HL,        I"RELATION_TY_OToVAdjective")
		KIT_PROVIDED(RELATION_TY_SYMMETRICADJECTIVE_HL,   I"RELATION_TY_SymmetricAdjective")
		KIT_PROVIDED(RELATION_TY_VTOOADJECTIVE_HL,        I"RELATION_TY_VToOAdjective")
		KIT_PROVIDED(RELATIONTEST_HL,                     I"RelationTest")
		KIT_PROVIDED(RELFOLLOWVECTOR_HL,                  I"RelFollowVector")
		KIT_PROVIDED(RELS_EMPTY_HL,                       I"RELS_EMPTY")
		KIT_PROVIDED(RESPONSEVIAACTIVITY_HL,              I"ResponseViaActivity")
		KIT_PROVIDED(RLANY_CAN_GET_X_HL,                  I"RLANY_CAN_GET_X")
		KIT_PROVIDED(RLANY_CAN_GET_Y_HL,                  I"RLANY_CAN_GET_Y")
		KIT_PROVIDED(RLANY_GET_X_HL,                      I"RLANY_GET_X")
		KIT_PROVIDED(RLIST_ALL_X_HL,                      I"RLIST_ALL_X")
		KIT_PROVIDED(RLIST_ALL_Y_HL,                      I"RLIST_ALL_Y")
		KIT_PROVIDED(RLNGETF_HL,                          I"RlnGetF")
		KIT_PROVIDED(ROUNDOFFVALUE_HL,                    I"RoundOffValue")
		KIT_PROVIDED(ROUTINEFILTER_TT_HL,                 I"ROUTINE_FILTER_TT")
		KIT_PROVIDED(RR_STORAGE_HL,                       I"RR_STORAGE")
		KIT_PROVIDED(RTP_RELKINDVIOLATION_HL,             I"RTP_RELKINDVIOLATION")
		KIT_PROVIDED(RTP_RELMINIMAL_HL,                   I"RTP_RELMINIMAL")
		KIT_PROVIDED(RULEBOOKFAILS_HL,                    I"RulebookFails")
		KIT_PROVIDED(RULEBOOKPARBREAK_HL,                 I"RulebookParBreak")
		KIT_PROVIDED(RULEBOOKSUCCEEDS_HL,                 I"RulebookSucceeds")
		KIT_PROVIDED(RUNTIMEPROBLEM_HL,                   I"RunTimeProblem")
		KIT_PROVIDED(SAY__N_HL,                           I"say__n")
		KIT_PROVIDED(SAY__P_HL,                           I"say__p")
		KIT_PROVIDED(SAY__PC_HL,                          I"say__pc")
		KIT_PROVIDED(SCENE_ENDED_HL,                      I"scene_ended")
		KIT_PROVIDED(SCENE_ENDINGS_HL,                    I"scene_endings")
		KIT_PROVIDED(SCENE_LATEST_ENDING_HL,              I"scene_latest_ending")
		KIT_PROVIDED(SCENE_STARTED_HL,                    I"scene_started")
		KIT_PROVIDED(SCENE_STATUS_HL,                     I"scene_status")
		KIT_PROVIDED(SCOPE_STAGE_HL,                      I"scope_stage")
		KIT_PROVIDED(SCOPE_TT_HL,                         I"SCOPE_TT")
		KIT_PROVIDED(SECOND_HL,                           I"second")
		KIT_PROVIDED(SHORT_NAME_HL,                       I"short_name")
		KIT_PROVIDED(SIGNEDCOMPARE_HL,                    I"SignedCompare")
		KIT_PROVIDED(SPECIAL_WORD_HL,                     I"special_word")
		KIT_PROVIDED(SQUAREROOT_HL,                       I"SquareRoot")
		KIT_PROVIDED(STACKFRAMECREATE_HL,                 I"StackFrameCreate")
		KIT_PROVIDED(STORED_ACTION_TY_CURRENT_HL,         I"STORED_ACTION_TY_Current")
		KIT_PROVIDED(STORED_ACTION_TY_TRY_HL,             I"STORED_ACTION_TY_Try")
		KIT_PROVIDED(STORY_TENSE_HL,                      I"story_tense")
		KIT_PROVIDED(SUPPORTER_HL,                        I"supporter")
		KIT_PROVIDED(SUPPRESS_SCOPE_LOOPS_HL,             I"suppress_scope_loops")
		KIT_PROVIDED(SUPPRESS_TEXT_SUBSTITUTION_HL,       I"suppress_text_substitution")
		KIT_PROVIDED(TABLE_NOVALUE_HL,                    I"TABLE_NOVALUE")
		KIT_PROVIDED(TABLELOOKUPCORR_HL,                  I"TableLookUpCorr")
		KIT_PROVIDED(TABLELOOKUPENTRY_HL,                 I"TableLookUpEntry")
		KIT_PROVIDED(TESTACTIONBITMAP_HL,                 I"TestActionBitmap")
		KIT_PROVIDED(TESTACTIVITY_HL,                     I"TestActivity")
		KIT_PROVIDED(TESTREGIONALCONTAINMENT_HL,          I"TestRegionalContainment")
		KIT_PROVIDED(TESTSCOPE_HL,                        I"TestScope")
		KIT_PROVIDED(TESTSTART_HL,                        I"TestStart")
		KIT_PROVIDED(TEXT_TY_COMPARE_HL,                  I"TEXT_TY_Compare")
		KIT_PROVIDED(TEXT_TY_EXPANDIFPERISHABLE_HL,       I"TEXT_TY_ExpandIfPerishable")
		KIT_PROVIDED(TEXT_TY_SAY_HL,                      I"TEXT_TY_Say")
		KIT_PROVIDED(THE_TIME_HL,                         I"the_time")
		KIT_PROVIDED(THEEMPTYTABLE_HL,                    I"TheEmptyTable")
		KIT_PROVIDED(THEN1__WD_HL,                        I"THEN1__WD")
		KIT_PROVIDED(TIMESACTIONHASBEENHAPPENING_HL,      I"TimesActionHasBeenHappening")
		KIT_PROVIDED(TIMESACTIONHASHAPPENED_HL,           I"TimesActionHasHappened")
		KIT_PROVIDED(TRYACTION_HL,                        I"TryAction")
		KIT_PROVIDED(TRYGIVENOBJECT_HL,                   I"TryGivenObject")
		KIT_PROVIDED(TURNSACTIONHASBEENHAPPENING_HL,      I"TurnsActionHasBeenHappening")
		KIT_PROVIDED(UNDERSTAND_AS_MISTAKE_NUMBER_HL,     I"understand_as_mistake_number")
		KIT_PROVIDED(UNICODE_TEMP_HL,                     I"unicode_temp")
		KIT_PROVIDED(VTOORELROUTETO_HL,                   I"VtoORelRouteTo")
		KIT_PROVIDED(VTOVRELROUTETO_HL,                   I"VtoVRelRouteTo")
		KIT_PROVIDED(WHEN_SCENE_BEGINS_HL,                I"WHEN_SCENE_BEGINS_RB")
		KIT_PROVIDED(WHEN_SCENE_ENDS_HL,                  I"WHEN_SCENE_ENDS_RB")
		KIT_PROVIDED(WN_HL,                               I"wn")
		KIT_PROVIDED(WORDADDRESS_HL,                      I"WordAddress")
		KIT_PROVIDED(WORDINPROPERTY_HL,                   I"WordInProperty")
		KIT_PROVIDED(WORDLENGTH_HL,                       I"WordLength")
