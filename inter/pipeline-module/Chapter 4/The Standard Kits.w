[KitHierarchy::] The Standard Kits.

The layout and naming conventions for functions and other resources provided
by the standard kits, and which are called or accessed from code generated
by Inter or by the Inform 7 compiler.

@ Suppose you are a tool like //inform7// or //inter// and you are generating
a function, and in that function you want to access the variable |location| --
which is defined in //WorldModelKit// -- or call the function |BlkValueCreate| --
which is in //BasicInformKit//. These have not yet been linked in to the Inter
tree you're trying to build: so how do you describe them?

The answer is that you call |HierarchyLocations::iname(I, BLKVALUECREATE_HL)|,
say, and it will return an |inter_name| which is exactly what you need. This is
all done with plugs and sockets, but you don't care about that.

The one thing you do need to do is to ensure that the following initialisation
function has been called: if not, |HierarchyLocations::iname| won't find these
resources.

@e KIT_HIERARCHY_MADE_ITHBIT

=
void KitHierarchy::establish(inter_tree *I) {
	if (InterTree::test_history(I, KIT_HIERARCHY_MADE_ITHBIT)) return;
	InterTree::set_history(I, KIT_HIERARCHY_MADE_ITHBIT);
	@<Establish kit-defined resources@>;
}

@ The following, then, is an itemised list of what symbol names in the kits
the //inform7// and //inter// tools need to refer to. (It's not any kind of
comprehensive list of what is there.)

@d KIT_PROVIDED(id, n) HierarchyLocations::con(I, id, n, req);

@<Establish kit-defined resources@> =
	location_requirement req = LocationRequirements::plug();
	@<Establish resources offered by BasicInformKit@>;
	@<Establish resources offered by WorldModelKit@>;
	@<Establish resources offered by CommandParserKit@>;
	@<Establish resources offered by either WorldModelKit or BasicInformKit@>;
	@<Establish resources offered by EnglishLanguageKit@>;
	@<Establish resources offered by DialogueKit@>;

@h Offered by BasicInformKit.

@e ADJUSTPARAGRAPHPOINT_HL from 0
@e ARGUMENTTYPEFAILED_HL
@e AUXF_MAGIC_VALUE_HL
@e AUXF_STATUS_IS_CLOSED_HL
@e BLKVALUECOPY_HL
@e BLKVALUECOPYAZ_HL
@e BLKVALUECREATE_HL
@e BLKVALUECREATEONSTACK_HL
@e BLKVALUEERROR_HL
@e BLKVALUEFREE_HL
@e BLKVALUEFREEONSTACK_HL
@e BLKVALUEINCREFCOUNTPRIMITIVE_HL
@e BLKVALUEWRITE_HL
@e CHECKKINDRETURNED_HL
@e CLEARPARAGRAPHING_HL
@e CONSTANT_PACKED_TEXT_STORAGE_HL
@e CONSTANT_PERISHABLE_TEXT_STORAGE_HL
@e CUBEROOT_HL
@e DB_RULE_HL
@e DEBUG_RULES_HL
@e DEBUGPROPERTY_HL
@e DECIMALNUMBER_HL
@e DIGITTOVALUE_HL
@e DIVIDEPARAGRAPHPOINT_HL
@e DO_NOTHING_HL
@e DOUBLEHASHSETRELATIONHANDLER_HL
@e EMPTY_RULEBOOK_INAME_HL
@e EMPTY_TABLE_HL
@e EMPTY_TEXT_PACKED_HL
@e EMPTY_TEXT_VALUE_HL
@e EMPTYRELATIONHANDLER_HL
@e EXISTSTABLELOOKUPCORR_HL
@e EXISTSTABLELOOKUPENTRY_HL
@e EXISTSTABLEROWCORR_HL
@e FLOAT_NAN_HL
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
@e GENERATERANDOMNUMBER_HL
@e GPROPERTY_HL
@e HASHLISTRELATIONHANDLER_HL
@e I7SFRAME_HL
@e INDEX_OF_ENUM_VAL_HL
@e INTEGERDIVIDE_HL
@e INTEGERREMAINDER_HL
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
@e MSTACK_HL
@e MSTVO_HL
@e MSTVON_HL
@e NAME_HL
@e NEXT_ENUM_VAL_HL
@e NOTHING_HL
@e NUMBER_TY_ABS_HL
@e NUMBER_TY_TO_REAL_NUMBER_TY_HL
@e OTOVRELROUTETO_HL
@e PACKED_TEXT_STORAGE_HL
@e PARACONTENT_HL
@e PARAMETER_VALUE_HL
@e PREV_ENUM_VAL_HL
@e PRINTORRUN_HL
@e PRIOR_NAMED_LIST_GENDER_HL
@e PRIOR_NAMED_LIST_HL
@e PRIOR_NAMED_NOUN_HL
@e PROPERTY_LOOP_SIGN_HL
@e PROPERTY_TO_BE_TOTALLED_HL
@e RANDOM_ENUM_VAL_HL
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
@e RLANY_CAN_GET_X_HL
@e RLANY_CAN_GET_Y_HL
@e RLANY_GET_X_HL
@e RLIST_ALL_X_HL
@e RLIST_ALL_Y_HL
@e RLNGETF_HL
@e ROUNDOFFVALUE_HL
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
@e SIGNEDCOMPARE_HL
@e SQUAREROOT_HL
@e STACKFRAMECREATE_HL
@e SUPPRESS_TEXT_SUBSTITUTION_HL
@e TABLE_NOVALUE_HL
@e TABLELOOKUPCORR_HL
@e TABLELOOKUPENTRY_HL
@e TEXT_TY_COMPARE_HL
@e TEXT_TY_EXPANDIFPERISHABLE_HL
@e TEXT_TY_SAY_HL
@e THEEMPTYTABLE_HL
@e UNICODE_TEMP_HL
@e VTOORELROUTETO_HL
@e VTOVRELROUTETO_HL

@<Establish resources offered by BasicInformKit@> =
	KIT_PROVIDED(ADJUSTPARAGRAPHPOINT_HL,             I"AdjustParagraphPoint")
	KIT_PROVIDED(ARGUMENTTYPEFAILED_HL,               I"ArgumentTypeFailed")
	KIT_PROVIDED(AUXF_MAGIC_VALUE_HL,                 I"AUXF_MAGIC_VALUE")
	KIT_PROVIDED(AUXF_STATUS_IS_CLOSED_HL,            I"AUXF_STATUS_IS_CLOSED")
	KIT_PROVIDED(BLKVALUECOPY_HL,                     I"BlkValueCopy")
	KIT_PROVIDED(BLKVALUECOPYAZ_HL,                   I"BlkValueCopyAZ")
	KIT_PROVIDED(BLKVALUECREATE_HL,                   I"BlkValueCreate")
	KIT_PROVIDED(BLKVALUECREATEONSTACK_HL,            I"BlkValueCreateOnStack")
	KIT_PROVIDED(BLKVALUEERROR_HL,                    I"BlkValueError")
	KIT_PROVIDED(BLKVALUEFREE_HL,                     I"BlkValueFree")
	KIT_PROVIDED(BLKVALUEFREEONSTACK_HL,              I"BlkValueFreeOnStack")
	KIT_PROVIDED(BLKVALUEINCREFCOUNTPRIMITIVE_HL,     I"BlkValueIncRefCountPrimitive")
	KIT_PROVIDED(BLKVALUEWRITE_HL,                    I"BlkValueWrite")
	KIT_PROVIDED(CHECKKINDRETURNED_HL,                I"CheckKindReturned")
	KIT_PROVIDED(CLEARPARAGRAPHING_HL,                I"ClearParagraphing")
	KIT_PROVIDED(CONSTANT_PACKED_TEXT_STORAGE_HL,     I"CONSTANT_PACKED_TEXT_STORAGE")
	KIT_PROVIDED(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE")
	KIT_PROVIDED(CUBEROOT_HL,                         I"CubeRoot")
	KIT_PROVIDED(DB_RULE_HL,                          I"DB_Rule")
	KIT_PROVIDED(DEBUG_RULES_HL,                      I"debug_rules")
	KIT_PROVIDED(DEBUGPROPERTY_HL,                    I"DebugProperty")
	KIT_PROVIDED(DECIMALNUMBER_HL,                    I"DecimalNumber")
	KIT_PROVIDED(DIGITTOVALUE_HL,                     I"DigitToValue")
	KIT_PROVIDED(DIVIDEPARAGRAPHPOINT_HL,             I"DivideParagraphPoint")
	KIT_PROVIDED(DO_NOTHING_HL,                       I"DoNothing")
	KIT_PROVIDED(DOUBLEHASHSETRELATIONHANDLER_HL,     I"DoubleHashSetRelationHandler")
	KIT_PROVIDED(EMPTY_RULEBOOK_INAME_HL,             I"EMPTY_RULEBOOK")
	KIT_PROVIDED(EMPTY_TABLE_HL,                      I"TheEmptyTable")
	KIT_PROVIDED(EMPTY_TEXT_PACKED_HL,                I"EMPTY_TEXT_PACKED")
	KIT_PROVIDED(EMPTY_TEXT_VALUE_HL,                 I"EMPTY_TEXT_VALUE")
	KIT_PROVIDED(EMPTYRELATIONHANDLER_HL,             I"EmptyRelationHandler")
	KIT_PROVIDED(EXISTSTABLELOOKUPCORR_HL,            I"ExistsTableLookUpCorr")
	KIT_PROVIDED(EXISTSTABLELOOKUPENTRY_HL,           I"ExistsTableLookUpEntry")
	KIT_PROVIDED(EXISTSTABLEROWCORR_HL,               I"ExistsTableRowCorr")
	KIT_PROVIDED(FLOAT_NAN_HL,                        I"FLOAT_NAN")
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
	KIT_PROVIDED(GENERATERANDOMNUMBER_HL,             I"GenerateRandomNumber")
	KIT_PROVIDED(GPROPERTY_HL,                        I"GProperty")
	KIT_PROVIDED(HASHLISTRELATIONHANDLER_HL,          I"HashListRelationHandler")
	KIT_PROVIDED(I7SFRAME_HL,                         I"I7SFRAME")
	KIT_PROVIDED(INDEX_OF_ENUM_VAL_HL,                I"IndexOfEnumVal");
	KIT_PROVIDED(INTEGERDIVIDE_HL,                    I"IntegerDivide")
	KIT_PROVIDED(INTEGERREMAINDER_HL,                 I"IntegerRemainder")
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
	KIT_PROVIDED(MSTACK_HL,                           I"MStack")
	KIT_PROVIDED(MSTVO_HL,                            I"MstVO")
	KIT_PROVIDED(MSTVON_HL,                           I"MstVON")
	KIT_PROVIDED(NAME_HL,                             I"name")
	KIT_PROVIDED(NEXT_ENUM_VAL_HL,                    I"NextEnumVal");
	KIT_PROVIDED(NOTHING_HL,                          I"nothing")
	KIT_PROVIDED(NUMBER_TY_ABS_HL,                    I"NUMBER_TY_Abs")
	KIT_PROVIDED(NUMBER_TY_TO_REAL_NUMBER_TY_HL,      I"NUMBER_TY_to_REAL_NUMBER_TY")
	KIT_PROVIDED(OTOVRELROUTETO_HL,                   I"OtoVRelRouteTo")
	KIT_PROVIDED(PACKED_TEXT_STORAGE_HL,              I"PACKED_TEXT_STORAGE")
	KIT_PROVIDED(PARACONTENT_HL,                      I"ParaContent")
	KIT_PROVIDED(PARAMETER_VALUE_HL,                  I"parameter_value")
	KIT_PROVIDED(PREV_ENUM_VAL_HL,                    I"PrevEnumVal");
	KIT_PROVIDED(PRINTORRUN_HL,                       I"PrintOrRun")
	KIT_PROVIDED(PRIOR_NAMED_LIST_GENDER_HL,          I"prior_named_list_gender")
	KIT_PROVIDED(PRIOR_NAMED_LIST_HL,                 I"prior_named_list")
	KIT_PROVIDED(PRIOR_NAMED_NOUN_HL,                 I"prior_named_noun")
	KIT_PROVIDED(PROPERTY_LOOP_SIGN_HL,               I"property_loop_sign")
	KIT_PROVIDED(PROPERTY_TO_BE_TOTALLED_HL,          I"property_to_be_totalled")
	KIT_PROVIDED(RANDOM_ENUM_VAL_HL,                  I"RandomEnumVal");
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
	KIT_PROVIDED(RLANY_CAN_GET_X_HL,                  I"RLANY_CAN_GET_X")
	KIT_PROVIDED(RLANY_CAN_GET_Y_HL,                  I"RLANY_CAN_GET_Y")
	KIT_PROVIDED(RLANY_GET_X_HL,                      I"RLANY_GET_X")
	KIT_PROVIDED(RLIST_ALL_X_HL,                      I"RLIST_ALL_X")
	KIT_PROVIDED(RLIST_ALL_Y_HL,                      I"RLIST_ALL_Y")
	KIT_PROVIDED(RLNGETF_HL,                          I"RlnGetF")
	KIT_PROVIDED(ROUNDOFFVALUE_HL,                    I"RoundOffValue")
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
	KIT_PROVIDED(SIGNEDCOMPARE_HL,                    I"SignedCompare")
	KIT_PROVIDED(SQUAREROOT_HL,                       I"SquareRoot")
	KIT_PROVIDED(STACKFRAMECREATE_HL,                 I"StackFrameCreate")
	KIT_PROVIDED(SUPPRESS_TEXT_SUBSTITUTION_HL,       I"suppress_text_substitution")
	KIT_PROVIDED(TABLE_NOVALUE_HL,                    I"TABLE_NOVALUE")
	KIT_PROVIDED(TABLELOOKUPCORR_HL,                  I"TableLookUpCorr")
	KIT_PROVIDED(TABLELOOKUPENTRY_HL,                 I"TableLookUpEntry")
	KIT_PROVIDED(TEXT_TY_COMPARE_HL,                  I"TEXT_TY_Compare")
	KIT_PROVIDED(TEXT_TY_EXPANDIFPERISHABLE_HL,       I"TEXT_TY_ExpandIfPerishable")
	KIT_PROVIDED(TEXT_TY_SAY_HL,                      I"TEXT_TY_Say")
	KIT_PROVIDED(THEEMPTYTABLE_HL,                    I"TheEmptyTable")
	KIT_PROVIDED(UNICODE_TEMP_HL,                     I"unicode_temp")
	KIT_PROVIDED(VTOORELROUTETO_HL,                   I"VtoORelRouteTo")
	KIT_PROVIDED(VTOVRELROUTETO_HL,                   I"VtoVRelRouteTo")

@h Offered by CommandParserKit.

@e ARTICLEDESCRIPTORS_HL
@e ETYPE_HL
@e NEXTBEST_ETYPE_HL
@e NEXTWORDSTOPPED_HL
@e NOTINCONTEXTPE_HL
@e PARSETOKENSTOPPED_HL
@e TRYGIVENOBJECT_HL
@e WORDADDRESS_HL
@e WORDINPROPERTY_HL
@e WORDLENGTH_HL

@<Establish resources offered by CommandParserKit@> =
	KIT_PROVIDED(ARTICLEDESCRIPTORS_HL,               I"ArticleDescriptors")
	KIT_PROVIDED(ETYPE_HL,                            I"etype")
	KIT_PROVIDED(NEXTBEST_ETYPE_HL,                   I"nextbest_etype")
	KIT_PROVIDED(NEXTWORDSTOPPED_HL,                  I"NextWordStopped")
	KIT_PROVIDED(NOTINCONTEXTPE_HL,                   I"NOTINCONTEXT_PE")
	KIT_PROVIDED(PARSETOKENSTOPPED_HL,                I"ParseTokenStopped")
	KIT_PROVIDED(TRYGIVENOBJECT_HL,                   I"TryGivenObject")
	KIT_PROVIDED(WORDADDRESS_HL,                      I"WordAddress")
	KIT_PROVIDED(WORDINPROPERTY_HL,                   I"WordInProperty")
	KIT_PROVIDED(WORDLENGTH_HL,                       I"WordLength")

@h Offered by WorldModelKit.

@e ACT_REQUESTER_HL
@e ACTION_HL
@e ACTIONCURRENTLYHAPPENINGFLAG_HL
@e ACTOR_HL
@e ACTOR_LOCATION_HL
@e ALLOWINSHOWME_HL
@e ANIMATE_HL
@e C_STYLE_HL
@e COMPONENT_CHILD_HL
@e COMPONENT_PARENT_HL
@e COMPONENT_SIBLING_HL
@e CONSULT_FROM_HL
@e CONSULT_WORDS_HL
@e CONTAINER_HL
@e DA_NAME_HL
@e DEADFLAG_HL
@e DEBUG_SCENES_HL
@e DETECTPLURALWORD_HL
@e DURINGSCENEMATCHING_HL
@e ELEMENTARY_TT_HL
@e ENGLISH_BIT_HL
@e FOUND_EVERYWHERE_HL
@e GENERICVERBSUB_HL
@e GETGNAOFOBJECT_HL
@e GPR_FAIL_HL
@e GPR_NUMBER_HL
@e GPR_PREPOSITION_HL
@e GPR_TT_HL
@e INDENT_BIT_HL
@e INP1_HL
@e INP2_HL
@e INVENTORY_STAGE_HL
@e KEEP_SILENT_HL
@e LOCATION_HL
@e LOCATIONOF_HL
@e LOOPOVERSCOPE_HL
@e LOS_RV_HL
@e NEWLINE_BIT_HL
@e NOARTICLE_BIT_HL
@e NOUN_HL
@e NUMBER_TY_TO_TIME_TY_HL
@e PARSED_NUMBER_HL
@e PARSER_ACTION_HL
@e PARSER_ONE_HL
@e PARSER_TRACE_HL
@e PARSER_TWO_HL
@e PARSERERROR_HL
@e PAST_CHRONOLOGICAL_RECORD_HL
@e PLACEINSCOPE_HL
@e PLAYER_HL
@e PLURALFOUND_HL
@e PRESENT_CHRONOLOGICAL_RECORD_HL
@e REAL_LOCATION_HL
@e REASON_THE_ACTION_FAILED_HL
@e RESPONSEVIAACTIVITY_HL
@e ROUTINEFILTER_TT_HL
@e SCENE_ENDED_HL
@e SCENE_ENDINGS_HL
@e SCENE_LATEST_ENDING_HL
@e SCENE_STARTED_HL
@e SCENE_STATUS_HL
@e SCOPE_STAGE_HL
@e SCOPE_TT_HL
@e SECOND_HL
@e SHORT_NAME_HL
@e SPECIAL_WORD_HL
@e STORED_ACTION_TY_CURRENT_HL
@e STORED_ACTION_TY_TRY_HL
@e STORY_COMPLETE_HL
@e STORY_TENSE_HL
@e SUPPORTER_HL
@e SUPPRESS_SCOPE_LOOPS_HL
@e TESTACTIONBITMAP_HL
@e TESTACTIVITY_HL
@e TESTREGIONALCONTAINMENT_HL
@e TESTSCOPE_HL
@e TESTSTART_HL
@e THE_TIME_HL
@e THEDARK_HL
@e THESAME_HL
@e TIMESACTIONHASBEENHAPPENING_HL
@e TIMESACTIONHASHAPPENED_HL
@e TRYACTION_HL
@e TURNSACTIONHASBEENHAPPENING_HL
@e UNDERSTAND_AS_MISTAKE_NUMBER_HL
@e WHEN_SCENE_BEGINS_HL
@e WHEN_SCENE_ENDS_HL
@e WN_HL

@<Establish resources offered by WorldModelKit@> =
	KIT_PROVIDED(ACT_REQUESTER_HL,                    I"act_requester")
	KIT_PROVIDED(ACTION_HL,                           I"action")
	KIT_PROVIDED(ACTIONCURRENTLYHAPPENINGFLAG_HL,     I"ActionCurrentlyHappeningFlag")
	KIT_PROVIDED(ACTOR_HL,                            I"actor")
	KIT_PROVIDED(ACTOR_LOCATION_HL,                   I"actor_location")
	KIT_PROVIDED(ALLOWINSHOWME_HL,                    I"AllowInShowme")
	KIT_PROVIDED(ANIMATE_HL,                          I"animate")
	KIT_PROVIDED(C_STYLE_HL,                          I"c_style")
	KIT_PROVIDED(COMPONENT_CHILD_HL,                  I"component_child")
	KIT_PROVIDED(COMPONENT_PARENT_HL,                 I"component_parent")
	KIT_PROVIDED(COMPONENT_SIBLING_HL,                I"component_sibling")
	KIT_PROVIDED(CONSULT_FROM_HL,                     I"consult_from")
	KIT_PROVIDED(CONSULT_WORDS_HL,                    I"consult_words")
	KIT_PROVIDED(CONTAINER_HL,                        I"container")
	KIT_PROVIDED(DA_NAME_HL,                          I"DA_Name")
	KIT_PROVIDED(DEADFLAG_HL,                         I"deadflag")
	KIT_PROVIDED(DEBUG_SCENES_HL,                     I"debug_scenes")
	KIT_PROVIDED(DETECTPLURALWORD_HL,                 I"DetectPluralWord")
	KIT_PROVIDED(DURINGSCENEMATCHING_HL,              I"DuringSceneMatching")
	KIT_PROVIDED(ELEMENTARY_TT_HL,                    I"ELEMENTARY_TT")
	KIT_PROVIDED(ENGLISH_BIT_HL,                      I"ENGLISH_BIT")
	KIT_PROVIDED(FOUND_EVERYWHERE_HL,                 I"FoundEverywhere")
	KIT_PROVIDED(GENERICVERBSUB_HL,                   I"GenericVerbSub")
	KIT_PROVIDED(GETGNAOFOBJECT_HL,                   I"GetGNAOfObject")
	KIT_PROVIDED(GPR_FAIL_HL,                         I"GPR_FAIL")
	KIT_PROVIDED(GPR_NUMBER_HL,                       I"GPR_NUMBER")
	KIT_PROVIDED(GPR_PREPOSITION_HL,                  I"GPR_PREPOSITION")
	KIT_PROVIDED(GPR_TT_HL,                           I"GPR_TT")
	KIT_PROVIDED(INDENT_BIT_HL,                       I"INDENT_BIT")
	KIT_PROVIDED(INP1_HL,                             I"inp1")
	KIT_PROVIDED(INP2_HL,                             I"inp2")
	KIT_PROVIDED(INVENTORY_STAGE_HL,                  I"inventory_stage")
	KIT_PROVIDED(KEEP_SILENT_HL,                      I"keep_silent")
	KIT_PROVIDED(LOCATION_HL,                         I"location")
	KIT_PROVIDED(LOCATIONOF_HL,                       I"LocationOf")
	KIT_PROVIDED(LOOPOVERSCOPE_HL,                    I"LoopOverScope")
	KIT_PROVIDED(LOS_RV_HL,                           I"los_rv")
	KIT_PROVIDED(NEWLINE_BIT_HL,                      I"NEWLINE_BIT")
	KIT_PROVIDED(NOARTICLE_BIT_HL,                    I"NOARTICLE_BIT")
	KIT_PROVIDED(NOUN_HL,                             I"noun")
	KIT_PROVIDED(NUMBER_TY_TO_TIME_TY_HL,             I"NUMBER_TY_to_TIME_TY")
	KIT_PROVIDED(PARSED_NUMBER_HL,                    I"parsed_number")
	KIT_PROVIDED(PARSER_ACTION_HL,                    I"parser_action")
	KIT_PROVIDED(PARSER_ONE_HL,                       I"parser_one")
	KIT_PROVIDED(PARSER_TRACE_HL,                     I"parser_trace")
	KIT_PROVIDED(PARSER_TWO_HL,                       I"parser_two")
	KIT_PROVIDED(PARSERERROR_HL,                      I"ParserError")
	KIT_PROVIDED(PAST_CHRONOLOGICAL_RECORD_HL,        I"past_chronological_record")
	KIT_PROVIDED(PLACEINSCOPE_HL,                     I"PlaceInScope")
	KIT_PROVIDED(PLAYER_HL,                           I"player")
	KIT_PROVIDED(PLURALFOUND_HL,                      I"##PluralFound")
	KIT_PROVIDED(PRESENT_CHRONOLOGICAL_RECORD_HL,     I"present_chronological_record")
	KIT_PROVIDED(REAL_LOCATION_HL,                    I"real_location")
	KIT_PROVIDED(REASON_THE_ACTION_FAILED_HL,         I"reason_the_action_failed")
	KIT_PROVIDED(RESPONSEVIAACTIVITY_HL,              I"ResponseViaActivity")
	KIT_PROVIDED(ROUTINEFILTER_TT_HL,                 I"ROUTINE_FILTER_TT")
	KIT_PROVIDED(SCENE_ENDED_HL,                      I"scene_ended")
	KIT_PROVIDED(SCENE_ENDINGS_HL,                    I"scene_endings")
	KIT_PROVIDED(SCENE_LATEST_ENDING_HL,              I"scene_latest_ending")
	KIT_PROVIDED(SCENE_STARTED_HL,                    I"scene_started")
	KIT_PROVIDED(SCENE_STATUS_HL,                     I"scene_status")
	KIT_PROVIDED(SCOPE_STAGE_HL,                      I"scope_stage")
	KIT_PROVIDED(SCOPE_TT_HL,                         I"SCOPE_TT")
	KIT_PROVIDED(SECOND_HL,                           I"second")
	KIT_PROVIDED(SHORT_NAME_HL,                       I"short_name")
	KIT_PROVIDED(SPECIAL_WORD_HL,                     I"special_word")
	KIT_PROVIDED(STORED_ACTION_TY_CURRENT_HL,         I"STORED_ACTION_TY_Current")
	KIT_PROVIDED(STORED_ACTION_TY_TRY_HL,             I"STORED_ACTION_TY_Try")
	KIT_PROVIDED(STORY_COMPLETE_HL,                   I"story_complete")
	KIT_PROVIDED(STORY_TENSE_HL,                      I"story_tense")
	KIT_PROVIDED(SUPPORTER_HL,                        I"supporter")
	KIT_PROVIDED(SUPPRESS_SCOPE_LOOPS_HL,             I"suppress_scope_loops")
	KIT_PROVIDED(TESTACTIONBITMAP_HL,                 I"TestActionBitmap")
	KIT_PROVIDED(TESTACTIVITY_HL,                     I"TestActivity")
	KIT_PROVIDED(TESTREGIONALCONTAINMENT_HL,          I"TestRegionalContainment")
	KIT_PROVIDED(TESTSCOPE_HL,                        I"TestScope")
	KIT_PROVIDED(TESTSTART_HL,                        I"TestStart")
	KIT_PROVIDED(THE_TIME_HL,                         I"the_time")
	KIT_PROVIDED(THEDARK_HL,                          I"thedark")
	KIT_PROVIDED(THESAME_HL,                          I"##TheSame")
	KIT_PROVIDED(TIMESACTIONHASBEENHAPPENING_HL,      I"TimesActionHasBeenHappening")
	KIT_PROVIDED(TIMESACTIONHASHAPPENED_HL,           I"TimesActionHasHappened")
	KIT_PROVIDED(TRYACTION_HL,                        I"TryAction")
	KIT_PROVIDED(TURNSACTIONHASBEENHAPPENING_HL,      I"TurnsActionHasBeenHappening")
	KIT_PROVIDED(UNDERSTAND_AS_MISTAKE_NUMBER_HL,     I"understand_as_mistake_number")
	KIT_PROVIDED(WHEN_SCENE_BEGINS_HL,                I"WHEN_SCENE_BEGINS_RB")
	KIT_PROVIDED(WHEN_SCENE_ENDS_HL,                  I"WHEN_SCENE_ENDS_RB")
	KIT_PROVIDED(WN_HL,                               I"wn")

@

@e PNTOVP_HL
@e PRINTSHORTNAME_HL

@<Establish resources offered by either WorldModelKit or BasicInformKit@> =
	KIT_PROVIDED(PNTOVP_HL,                           I"PNToVP")
	KIT_PROVIDED(PRINTSHORTNAME_HL,                   I"PrintShortName")

@

@e THEN1__WD_HL

@<Establish resources offered by EnglishLanguageKit@> =
	KIT_PROVIDED(THEN1__WD_HL,                        I"THEN1__WD")

@

@e DIRECTOR_ADD_LIVE_SUBJECT_LIST_HL
@e DIRECTOR_AFTER_ACTION_HL
@e DIRECTOR_BEAT_BEING_PERFORMED_HL
@e DIRECTOR_PERFORM_TIED_BEAT_HL

@<Establish resources offered by DialogueKit@> =
	KIT_PROVIDED(DIRECTOR_ADD_LIVE_SUBJECT_LIST_HL,   I"DirectorAddLiveSubjectList")
	KIT_PROVIDED(DIRECTOR_AFTER_ACTION_HL,            I"DirectorAfterAction")
	KIT_PROVIDED(DIRECTOR_BEAT_BEING_PERFORMED_HL,    I"DirectorBeatBeingPerformed")
	KIT_PROVIDED(DIRECTOR_PERFORM_TIED_BEAT_HL,       I"DirectorPerformBeatIfUnperformed")
