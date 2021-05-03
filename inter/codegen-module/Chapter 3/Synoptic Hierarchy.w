[SynopticHierarchy::] Synoptic Hierarchy.

To provide an enforced structure for the synoptic module.

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
}

@

@d SYN_SUBMD(r) req = HierarchyLocations::synoptic_submodule(I, Packaging::register_submodule(r));
@d SYN_CONST(id, n) {
		HierarchyLocations::ctr(I, id, n,    Translation::same(),      req);
		inter_name *iname = HierarchyLocations::find(I, id);
		inter_symbol *S = InterNames::to_symbol(iname);
		Inter::Connectors::socket(I, InterNames::to_text(iname), S);
	}
@d SYN_FUNCT(id, n, t) HierarchyLocations::fun(I, id, n, Translation::to(t),       req);

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

@e TC_KOV_HL

@<Establish tables@> =
	SYN_SUBMD(I"tables")
		SYN_FUNCT(PRINT_TABLE_HL,                 I"print_fn", I"PrintTableName")
		SYN_CONST(TABLEOFTABLES_HL,               I"TableOfTables")
		SYN_CONST(TB_BLANKS_HL,                   I"TB_Blanks")

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
