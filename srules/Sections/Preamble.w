Preamble.

The titling line and rubric, use options and a few other
technicalities before the Standard Rules get properly started.

@ The Standard Rules are like a boot program for a computer that is
starting up: at the beginning, the process is delicate, and the computer
needs a fairly exact sequence of things to be done; halfway through, the
essential work is done, but the system is still too primitive to be much
use, so we begin to create convenient intermediate-level code sitting on
top of the basics; so that, by the end, we have a fully flexible machine
ready to go in any number of directions. In this commentary, we try to
distinguish between what must be done (or else NI will crash, or fail in
some other way) and what is done simply as a design decision (to make the
Inform language come out the way we want it). Quite interesting hybrid
Informs could be built by making different decisions. Still, our design is
not entirely free, since it interacts with the I6 template layer (the
I7 equivalent of the old I6 library): a really radical alternate Inform
would need a different template layer, too.

@h Title.
Every Inform 7 extension begins with a standard titling line and a
rubric text, and the Standard Rules are no exception:

=
Version [[Version Number]] of the Standard Rules by Graham Nelson begins here.

"The Standard Rules, included in every project, define the basic framework
of kinds, actions and phrases which make Inform what it is."

@h Starting up.
The first task is to create the verbs which enable us to do everything
else. The first sentence should really read "The verb to mean means the
built-in verb-means meaning", but that would be circular. So Inform
starts with two verbs built in, "to mean" and "to be", with "to mean"
having the built-in "verb-means meaning", and "to be" initially having
no meaning at all. (We need "to be" because this enables us to conjugate
forms of "mean" such as "X is meant by": note the "is".)

So we actually start by defining the copular verb "to be". This has a
dozen special meanings, all valid only in assertion sentences, as well
as its regular one.

=
The verb to be means the built-in new-verb meaning.
The verb to be means the built-in new-plural meaning.
The verb to be means the built-in new-activity meaning.
The verb to be means the built-in new-action meaning.
The verb to be means the built-in new-adjective meaning.
The verb to be means the built-in new-either-or meaning.
The verb to be means the built-in defined-by-table meaning.
The verb to be means the built-in rule-listed-in meaning.
The verb to be means the built-in new-figure meaning.
The verb to be means the built-in new-sound meaning.
The verb to be means the built-in new-file meaning.
The verb to be means the built-in episode meaning.
The verb to be means the equality relation.

@ Unfinished business: the other meaning of "mean", and "imply" as
a synonym for it.

=
The verb to mean means the meaning relation.

The verb to imply means the built-in verb-means meaning.
The verb to imply means the meaning relation.

@ And now miscellaneous other important verbs. Note the plus notation, new
in May 2016, which marks for a second object phrase, and is thus only
useful for built-in meanings.

=
The verb to be able to be means the built-in can-be meaning.

The verb to have means the possession relation.

The verb to specify means the built-in specifies-notation meaning.

The verb to relate means the built-in new-relation meaning.
The verb to relate means the universal relation.

The verb to substitute for means the built-in rule-substitutes-for meaning.

The verb to begin when means the built-in scene-begins-when meaning.
The verb to end when means the built-in scene-ends-when meaning.
The verb to end + when means the built-in scene-ends-when meaning.

The verb to do means the built-in rule-does-nothing meaning.
The verb to do + if means the built-in rule-does-nothing-if meaning.
The verb to do + when means the built-in rule-does-nothing-if meaning.
The verb to do + unless means the built-in rule-does-nothing-unless meaning.

The verb to translate into + as means the built-in translates-into-unicode meaning.
The verb to translate into + as means the built-in translates-into-i6 meaning.
The verb to translate into + as means the built-in translates-into-language meaning.

The verb to translate as means the built-in use-translates meaning.

@ Finally, the verbs used as imperatives: "Test ... with ...", for example.

=
The verb to test + with in the imperative means the built-in test-with meaning.
The verb to understand + as in the imperative means the built-in understand-as meaning.
The verb to use in the imperative means the built-in use meaning.
The verb to release along with in the imperative means the built-in release-along-with meaning.
The verb to index map with in the imperative means the built-in index-map-with meaning.
The verb to include + in in the imperative means the built-in include-in meaning.
The verb to omit + from in the imperative means the built-in omit-from meaning.
The verb to document + at in the imperative means the built-in document-at meaning.

@ The following has no effect, and exists only to be a default non-value for
"use option" variables, should anyone ever create them:

=
Use ineffectual translates as (- ! Use ineffectual does nothing. -).

@ We can now make definitions of miscellaneous options: none are used by default,
but all translate into I6 constant definitions if used. (These are constants
whose values are used in the I6 library or in the template layer, which is
how they have effect.)

=
Use American dialect translates as (- Constant DIALECT_US; -).
Use the serial comma translates as (- Constant SERIAL_COMMA; -).
Use full-length room descriptions translates as (- #IFNDEF I7_LOOKMODE; Constant I7_LOOKMODE = 2; #ENDIF; -).
Use abbreviated room descriptions translates as (- #IFNDEF I7_LOOKMODE; Constant I7_LOOKMODE = 3; #ENDIF; -).
Use memory economy translates as (- Constant MEMORY_ECONOMY; -).
Use authorial modesty translates as (- Constant AUTHORIAL_MODESTY; -).
Use scoring translates as (- #IFNDEF USE_SCORING; Constant USE_SCORING = 1; #ENDIF; -).
Use no scoring translates as (- #IFNDEF USE_SCORING; Constant USE_SCORING = 0; #ENDIF; -).
Use engineering notation translates as (- Constant USE_E_NOTATION = 0; -).
Use unabbreviated object names translates as (- Constant UNABBREVIATED_OBJECT_NAMES = 0; -).
Use command line echoing translates as (- Constant ECHO_COMMANDS; -).
Use manual pronouns translates as (- Constant MANUAL_PRONOUNS; -).
Use undo prevention translates as (- Constant PREVENT_UNDO; -).
Use predictable randomisation translates as (- Constant FIX_RNG; -).
Use fast route-finding translates as (- Constant FAST_ROUTE_FINDING; -).
Use slow route-finding translates as (- Constant SLOW_ROUTE_FINDING; -).
Use numbered rules translates as (- Constant NUMBERED_RULES; -).
Use telemetry recordings translates as (- Constant TELEMETRY_ON; -).
Use no deprecated features translates as (- Constant NO_DEPRECATED_FEATURES; -).
Use gn testing version translates as (- Constant GN_TESTING_VERSION; -).
Use VERBOSE room descriptions translates as (- Constant DEFAULT_VERBOSE_DESCRIPTIONS; -).
Use BRIEF room descriptions translates as (- Constant DEFAULT_BRIEF_DESCRIPTIONS; -).
Use SUPERBRIEF room descriptions translates as (- Constant DEFAULT_SUPERBRIEF_DESCRIPTIONS; -).

@ These, on the other hand, are settings used by the dynamic memory management
code, which runs in I6 as part of the template layer. Each setting translates
to an I6 constant declaration, with the value chosen being substituted for
|{N}|.

The "dynamic memory allocation" defined here is slightly misleading, in
that the memory is only actually consumed in the event that any of the
kinds needing to use the heap is actually employed in the source
text being compiled. (8192 bytes may not sound much these days, but in the
tight array space of the Z-machine it's quite a large commitment, and we
want to avoid it whenever possible.)

=
Use dynamic memory allocation of at least 8192 translates as
	(- Constant DynamicMemoryAllocation = {N}; -).
Use maximum text length of at least 1024 translates as
	(- Constant TEXT_TY_BufferSize = {N}+3; -).
Use index figure thumbnails of at least 50 translates as
	(- Constant MAX_FIGURE_THUMBNAILS_IN_INDEX = {N}; -).

Use dynamic memory allocation of at least 8192.

@ This setting is to do with the Inform parser's handling of multiple objects.

=
Use maximum things understood at once of at least 100 translates as
	(- Constant MATCH_LIST_WORDS = {N}; -).

Use maximum things understood at once of at least 100.

@ That's it for the verbs with special internal meanings.

=
The verb to provide means the provision relation.

@ The following block of declarations is actually written by |indoc| and
modified each time we alter the documentation. It's a dictionary of symbolic
names like |HEADINGS| to HTML page leafnames like |doc71|.

=
[...and so on...]
Document PM_NoStartRoom PM_StartsOutsideRooms at doc4 "1.4" "1.4. The Go! button".
Document PM_CantAssertQuantifier PM_CantAssertNonKind PM_CantAssertNegatedRelations PM_CantAssertNegatedEverywhere PM_CantAssertAdjective PM_TwoLikelihoods PM_NegatedVerb1 PM_NoSuchVerbComma PM_NoSuchVerb at doc10 "2.1" "2.1. Creating the world".
Document PM_EnigmaticThey PM_EnigmaticPronoun PM_WordTooLong PM_TooMuchQuotedText PM_UnendingComment PM_UnendingQuote at doc12 "2.3" "2.3. Punctuation".
Document PM_BadTitleSentence PM_HeadingStopsBeforeEndOfLine PM_HeadingOverLine HEADINGS at doc14 "2.5" "2.5. Headings".
Document PM_UnknownInternalTest PM_TestDoubleWith PM_TestCommandTooLong PM_TestContainsUndo PM_TestBadRequirements PM_TestDuplicate PM_TestMultiWord at doc17 "2.8" "2.8. The TEST command".
Document PM_BogusExtension at doc19 "2.10" "2.10. Installing extensions".
Document PM_ExtMisidentifiedEnds PM_ExtInadequateVM PM_ExtMalformedVM PM_ExtMisidentified PM_ExtMiswordedBeginsHere PM_ExtVersionMalformed PM_IncludeExtQuoted at doc20 "2.11" "2.11. Including extensions".
Document OPTIONS PM_UnknownUseOption PM_UONotNumerical at doc21 "2.12" "2.12. Use options".
Document OPTIONSFILE at doc22 "2.13" "2.13. Administering classroom use".
Document STORYFILES PM_BadICLIdentifier at doc23 "2.14" "2.14. Limits and the Settings panel".
Document PM_DescriptionsEquated PM_SameKindEquated MAP kind_room at doc27 "3.2" "3.2. Rooms and the map".
Document PM_RegionRelation PM_RegionInTwoRegions PM_ExistingRegion REGIONS kind_region at doc29 "3.4" "3.4. Regions and the index map".
Document PM_KindsIncompatible PM_MiseEnAbyme PM_CantContainAndSupport PM_BothRoomAndSupporter KINDS at doc30 "3.5" "3.5. Kinds".
Document PM_PropertyNotPermitted at doc32 "3.7" "3.7. Properties depend on kind".
Document PM_EverywhereMisapplied PM_CantChangeEverywhere PM_EverywhereNonBackdrop kind_backdrop at doc34 "3.9" "3.9. Backdrops".
Document PM_TextWithoutSubject PM_TwoAppearances at doc36 "3.11" "3.11. Two descriptions of things".
Document PM_BadMapCell PM_RoomMissingDoor PM_DoorInThirdRoom PM_DoorToNonRoom PM_DoorOverconnected PM_DoorUnconnected PM_BothWaysDoor kind_door ph_frontside ph_backside ph_othersideof ph_directionofdoor at doc37 "3.12" "3.12. Doors".
Document kind_device at doc39 "3.14" "3.14. Devices and descriptions".
Document kind_vehicle at doc41 "3.16" "3.16. Vehicles and pushable things".
Document kind_person at doc42 "3.17" "3.17. Men, women and animals".
Document kind_player's at doc46 "3.21" "3.21. The player's holdall".
Document PM_RoomOrDoorAsPart PM_PartOfRoom at doc48 "3.23" "3.23. Parts of things".
Document ph_locationof at doc50 "3.25" "3.25. The location of something".
Document PM_NamelessDirection PM_DirectionTooLong PM_ImproperlyMadeDirection PM_TooManyDirections kind_direction at doc51 "3.26" "3.26. Directions".
Document NEWKINDS at doc52 "4.1" "4.1. New kinds".
Document PM_PluralIsQuoted PM_PluralOfQuoted at doc55 "4.4" "4.4. Plural assertions".
Document KINDSVALUE at doc56 "4.5" "4.5. Kinds of value".
Document PM_ValueCantHaveVProperties PM_ValueCantHaveProperties at doc57 "4.6" "4.6. Properties again".
Document PM_ThisIsEitherOr PM_MiscellaneousEOProblem PM_NonObjectCanBe PM_QualifiedCanBe PM_EitherOrAsValue at doc58 "4.7" "4.7. New either/or properties".
Document PM_RedundantThatVaries PM_BadProvides PM_PropertyKindClashes PM_PropertyKindVague PM_PropertyKindUnknown PM_PropertyTooSpecific PM_BadVisibilityWhen PM_PropertyUninitialisable PM_PropertyNameForbidden PM_PropertyCalledPresence PM_PropertyCalledArticle PM_PropertyOfKind1 at doc59 "4.8" "4.8. New value properties".
Document PM_EitherOnThree at doc61 "4.10" "4.10. Conditions of things".
Document ph_defaultvalue at doc62 "4.11" "4.11. Default values of kinds".
Document PM_EmptyKind VARIABLES var_location at doc63 "4.12" "4.12. Values that vary".
Document PM_TooManyDuplicates at doc65 "4.14" "4.14. Duplicates".
Document PM_ComplexEvery PM_AssemblyRegress PM_AssemblyLoop at doc66 "4.15" "4.15. Assemblies and body parts".
Document PM_TSWithPunctuation PM_TSWithComma at doc69 "5.1" "5.1. Text with substitutions".
Document phs_bracket phs_closebracket phs_apostrophe phs_quotemark at doc70 "5.2" "5.2. How Inform reads quoted text".
Document ph_say phs_a phs_A phs_the phs_The at doc71 "5.3" "5.3. Text which names things".
Document phs_numwords phs_s at doc72 "5.4" "5.4. Text with numbers".
Document phs_listof phs_alistof phs_Alistof phs_thelistof phs_Thelistof phs_islistof phs_isalistof phs_isthelistof phs_alistofconts at doc73 "5.5" "5.5. Text with lists".
Document PM_SayEndIfWithoutSayIf PM_SayOtherwiseWithoutIf PM_SayIfNested phs_if phs_unless phs_otherwise phs_endif phs_endunless phs_elseif phs_elseunless at doc74 "5.6" "5.6. Text with variations".
Document PM_ComplicatedSayStructure3 PM_ComplicatedSayStructure4 PM_ComplicatedSayStructure5 PM_ComplicatedSayStructure2 PM_ComplicatedSayStructure phs_oneof phs_or phs_purelyrandom phs_thenpurelyrandom phs_random phs_thenrandom phs_sticky phs_decreasing phs_order phs_cycling phs_stopping phs_firsttime at doc75 "5.7" "5.7. Text with random alternatives".
Document phs_linebreak phs_nolinebreak phs_runparaon phs_parabreak phs_condparabreak ph_breakpending phs_clarifbreak phs_runparaonsls at doc76 "5.8" "5.8. Line breaks and paragraph breaks".
Document phs_bold phs_italic phs_roman phs_fixedspacing phs_varspacing at doc77 "5.9" "5.9. Text with type styles".
Document PM_MidTextUnicode PM_SayUnicode at doc79 "5.11" "5.11. Unicode characters".
Document ph_boxed at doc80 "5.12" "5.12. Displaying quotations".
Document DESCRIPTIONS ph_numberof at doc82 "6.1" "6.1. What are descriptions?".
Document PM_ArticleAsAdjective PM_AdjDomainUnknown PM_AdjDomainSurreal PM_AdjDomainSlippery PM_DefinitionWithoutCondition PM_DefinitionBadCondition at doc85 "6.4" "6.4. Defining new adjectives".
Document PM_MultiwordGrading PM_GradingWrongKOV PM_GradingUnless PM_GradingUnknownProperty PM_GradingNonLiteral PM_GradingMisphrased PM_GradingCalled PM_ComparativeMisapplied at doc88 "6.7" "6.7. Comparatives".
Document PM_OutOfPlay at doc91 "6.10" "6.10. Existence and there".
Document ph_roomdirof ph_doordirof ph_roomordoor ph_bestroute ph_bestroutethrough ph_bestroutelength ph_bestroutethroughlength at doc95 "6.14" "6.14. Adjacent rooms and routes through the map".
Document PM_ComplexDeterminer at doc96 "6.15" "6.15. All, each and every".
Document PM_NonActionIn PM_APUnknown PM_APWithNoParticiple kind_actionname ACTIONS at doc98 "7.1" "7.1. Actions".
Document rules_instead at doc99 "7.2" "7.2. Instead rules".
Document rules_before ph_stopaction ph_continueaction at doc100 "7.3" "7.3. Before rules".
Document PM_ActionTooSpecific PM_ActionNotSpecific PM_UnknownTryAction2 PM_UnknownTryAction1 ph_try ph_trysilently at doc101 "7.4" "7.4. Try and try silently".
Document rules_after at doc102 "7.5" "7.5. After rules".
Document PM_APWithImmiscible PM_APWithDisjunction at doc105 "7.8" "7.8. Rules applying to more than one action".
Document var_noun at doc107 "7.10" "7.10. The noun and the second noun".
Document PM_APWithBadWhen PM_NonActionInPresenceOf at doc109 "7.12" "7.12. In the presence of, and when".
Document PM_GoingWithoutObject PM_GoingWrongKind at doc111 "7.14" "7.14. Going by, going through, going with".
Document KACTIONS PM_NamedAPWithActor at doc112 "7.15" "7.15. Kinds of action".
Document var_prompt at doc117 "8.2" "8.2. Changing the command prompt".
Document var_sl phs_surroundings at doc118 "8.3" "8.3. Changing the status line".
Document ph_changeexit ph_changenoexit at doc120 "8.5" "8.5. Change of properties with values".
Document ph_move at doc122 "8.7" "8.7. Moving things".
Document ph_movebackdrop ph_updatebackdrop at doc123 "8.8" "8.8. Moving backdrops".
Document ph_remove at doc125 "8.10" "8.10. Removing things from play".
Document PM_RedefinedNow PM_CantChangeKind PM_CantForceCalling PM_CantForceGeneralised PM_CantForceExistence PM_CantForceRelation PM_BadNow3 PM_BadNow2 PM_BadNow1 ph_now at doc126 "8.11" "8.11. Now...".
Document ph_increase ph_decrease ph_increment ph_decrement at doc127 "8.12" "8.12. Increasing and decreasing".
Document PM_CalledWithDash PM_CalledThe at doc130 "8.15" "8.15. Calling names".
Document ph_holder ph_firstheld ph_nextheld at doc132 "8.17" "8.17. Looking at containment by hand".
Document ph_randombetween ph_randomchance ph_seed at doc133 "8.18" "8.18. Randomness".
Document PM_RandomImpossible ph_randomdesc at doc134 "8.19" "8.19. Random choices of things".
Document rules_wpb ROOMPLAYBEGINS at doc135 "9.1" "9.1. When play begins".
Document var_score at doc136 "9.2" "9.2. Awarding points".
Document rules_wpe ph_end ph_endfinally ph_endsaying ph_endfinallysaying ph_ended ph_notended ph_finallyended ph_notfinallyended ph_resume at doc138 "9.4" "9.4. When play ends".
Document PM_NumberOfTurns rules_et at doc139 "9.5" "9.5. Every turn".
Document var_time kind_time at doc140 "9.6" "9.6. The time of day".
Document phs_timewords at doc141 "9.7" "9.7. Telling the time".
Document ph_durationmins ph_durationhours at doc142 "9.8" "9.8. Approximate times, lengths of time".
Document ph_shiftbefore ph_shiftafter ph_timebefore ph_timeafter at doc143 "9.9" "9.9. Comparing and shifting times".
Document ph_minspart ph_hourspart at doc144 "9.10" "9.10. Calculating times".
Document TIMEDEVENTS PM_UnusedTimedEvent PM_AtWithoutTime ph_timefromnow ph_turnsfromnow ph_attime at doc145 "9.11" "9.11. Future events".
Document PM_PTAPTooComplex at doc146 "9.12" "9.12. Actions as conditions".
Document PM_PastTableEntries PM_NonPresentTense PM_PastActionCalled PM_PastCallings PM_PastTableLookup PM_PTAPMakesCallings PM_PastSubordinate at doc147 "9.13" "9.13. The past and perfect tenses".
Document kind_scene SCENESINTRO at doc150 "10.1" "10.1. Introduction to scenes".
Document PM_ScenesBadCondition PM_ScenesOversetEnd PM_ScenesUnknownEnd PM_ScenesOnly PM_ScenesDisallowCalled PM_ScenesNotPlay at doc151 "10.2" "10.2. Creating a scene".
Document ph_scenetimesincebegan ph_scenetimesinceended ph_scenetimewhenbegan ph_scenetimewhenended at doc152 "10.3" "10.3. Using the Scene index".
Document ph_hashappened ph_hasnothappened ph_hasended ph_hasnotended at doc153 "10.4" "10.4. During scenes".
Document LINKINGSCENES at doc154 "10.5" "10.5. Linking scenes together".
Document PHRASES ph_nothing at doc159 "11.1" "11.1. What are phrases?".
Document PM_BareTo at doc160 "11.2" "11.2. The phrasebook".
Document PM_SaySlashed PM_AdjacentTokens PM_PhraseTooLong PM_TokenMisunderstood PM_BadTypeIndication PM_TokenWithNestedBrackets PM_TokenWithEmptyBrackets PM_TokenWithoutCloseBracket PM_TokenWithoutOpenBracket at doc161 "11.3" "11.3. Pattern matching".
Document ph_showme at doc162 "11.4" "11.4. The showme phrase".
Document PM_TruthStateToDecide kind_truthstate ph_indarkness ph_consents ph_whether at doc163 "11.5" "11.5. Conditions and questions".
Document PM_IfOutsidePhrase ph_if ph_unless at doc164 "11.6" "11.6. If".
Document PM_EmptyIndentedBlock PM_RunOnsInTabbedRoutine PM_MisalignedIndentation PM_NotInOldSyntax PM_BothBlockSyntaxes PM_CantUseOutsideStructure PM_WrongEnd PM_EndWithoutBegin PM_BlockNestingTooDeep PM_BeginWithoutEnd at doc165 "11.7" "11.7. Begin and end".
Document PM_OtherwiseInNonIf PM_OtherwiseWithoutIf PM_CaseValueMismatch PM_CaseValueNonConstant PM_OtherwiseIfAfterOtherwise PM_DoubleOtherwise PM_MisarrangedOtherwise PM_MisalignedCase PM_MisalignedOtherwise PM_NonCaseInIf ph_otherwise ph_switch at doc166 "11.8" "11.8. Otherwise".
Document ph_while at doc167 "11.9" "11.9. While".
Document PM_CalledInRepeat ph_repeat at doc168 "11.10" "11.10. Repeat".
Document PM_BadRepeatDomain ph_runthrough at doc169 "11.11" "11.11. Repeat running through".
Document PM_CantUseOutsideLoop ph_next ph_break at doc170 "11.12" "11.12. Next and break".
Document ph_stop at doc171 "11.13" "11.13. Stop".
Document PM_SayWithPhraseOptions PM_NotTheOnlyPhraseOption PM_NotAPhraseOption PM_PhraseOptionsExclusive PM_TooManyPhraseOptions ph_listcontents at doc172 "11.14" "11.14. Phrase options".
Document ph_let ph_letdefault at doc173 "11.15" "11.15. Let and temporary variables".
Document ph_yes ph_no at doc174 "11.16" "11.16. New conditions, new adjectives".
Document PM_RedundantReturnKOV PM_UnknownValueToDecide PM_ReturnWrongKind ph_decideon at doc175 "11.17" "11.17. Phrases to decide other things".
Document ph_enumfirst ph_enumlast ph_enumafter ph_enumbefore at doc176 "11.18" "11.18. The value after and the value before".
Document ARSUMMARY at doc178 "12.2" "12.2. How actions are processed".
Document var_person_asked at doc179 "12.3" "12.3. Giving instructions to other people".
Document rules_per at doc180 "12.4" "12.4. Persuasion".
Document rules_fail var_reason at doc181 "12.5" "12.5. Unsuccessful attempts".
Document PM_ActionMisapplied PM_ActionClauseUnknown PM_ActionBothValues PM_ActionAlreadyExists PM_GrammarMismatchesAction PM_MultiwordPastParticiple PM_MatchedAsTooLong NEWACTIONS ph_requirestouch ph_requirestouch2 ph_requirescarried ph_requirescarried2 ph_requireslight at doc183 "12.7" "12.7. New actions".
Document PM_BadOptionalAPClause PM_BadMatchingSyntax PM_ActionVarValue PM_ActionVarUnknownKOV PM_ActionVarOverspecific PM_ActionVarAnd PM_ActionVarsPastTense at doc186 "12.10" "12.10. Action variables".
Document PM_RuleWithComma PM_DuplicateRuleName at doc188 "12.12" "12.12. Check rules for actions by other people".
Document OUTOFWORLD at doc191 "12.15" "12.15. Out of world actions".
Document rules_ri at doc192 "12.16" "12.16. Reaching inside and reaching outside rules".
Document var_person_reaching at doc194 "12.18" "12.18. Changing reachability".
Document visibility at doc195 "12.19" "12.19. Changing visibility".
Document kind_storedaction ph_currentaction ph_actionpart ph_nounpart ph_secondpart ph_actorpart ph_involves ph_actionof at doc196 "12.20" "12.20. Stored actions".
Document PM_KindRelatedToValue PM_EveryWrongSide PM_BadRelation PM_RelationWithEitherOrProperty PM_RelationWithBadProperty PM_PropForBadKOV VERBS at doc198 "13.1" "13.1. Sentence verbs".
Document RELATIONS at doc200 "13.3" "13.3. What are relations?".
Document PM_BadKOVForRelationProperty PM_RelatedKindsUnknown PM_OneToOneMiscalled PM_CantCallBoth PM_CantCallRight PM_CantCallLeft PM_BothOneAndMany PM_OneOrVariousWithWhen PM_FRFUnavailable PM_RelationExists at doc202 "13.5" "13.5. Making new relations".
Document ph_showrelation at doc204 "13.7" "13.7. Relations in groups".
Document PM_PrepositionLong PM_PrepositionConjugated PM_DuplicateVerbs1 PM_VerbMalformed PM_PresentPluralTwice PM_VerbRelationUnknown PM_VerbUnknownMeaning PM_VerbRelationVague at doc206 "13.9" "13.9. Defining new assertion verbs".
Document ph_nextstep ph_numbersteps at doc208 "13.11" "13.11. Indirect relations".
Document PM_BadRelationCondition PM_Unassertable2 at doc209 "13.12" "13.12. Relations which express conditions".
Document ph_ifleft ph_ifright ph_rightlookup ph_leftlookup ph_leftlookuplist ph_rightlookuplist ph_leftdomain ph_rightdomain at doc210 "13.13" "13.13. Relations involving values".
Document ph_letrelation at doc212 "13.15" "13.15. Temporary relations".
Document phs_here phs_now at doc214 "14.1" "14.1. Tense and narrative viewpoint".
Document kind_verb phs_adapt phs_adaptv phs_adaptt phs_adaptvt phs_negate phs_negatev phs_negatet phs_negatevt phs_infinitive phs_pastpart phs_prespart at doc222 "14.9" "14.9. Verbs as values".
Document phs_response at doc223 "14.10" "14.10. Responses".
Document PM_LiteralOverflow PM_ElementOverflow PM_ZMachineOverflow PM_EvenOverflow-G PM_CantEquateValues PM_InequalityFailed kind_real_number kind_number at doc227 "15.2" "15.2. Numbers and real numbers".
Document ph_nearestwholenumber at doc228 "15.3" "15.3. Real number conversions".
Document phs_realplaces phs_decimal phs_decimalplaces phs_scientific phs_scientificplaces at doc229 "15.4" "15.4. Printing real numbers".
Document ph_plus ph_minus ph_times ph_divide ph_remainder ph_nearest ph_squareroot ph_realsquareroot ph_cuberoot at doc230 "15.5" "15.5. Arithmetic".
Document ph_ceiling ph_floor ph_absolutevalue ph_reciprocal ph_power ph_exp ph_logarithmto ph_logarithm at doc231 "15.6" "15.6. Powers and logarithms".
Document ph_degrees ph_sine ph_cosine ph_tangent ph_arcsine ph_arccosine ph_arctangent ph_hyperbolicsine ph_hyperboliccosine ph_hyperbolictangent ph_hyperbolicarcsine ph_hyperbolicarccosine ph_hyperbolicarctangent at doc232 "15.7" "15.7. Trigonometry".
Document PM_NegationForbidden PM_NegationInternal PM_LPEnumeration PM_LPBuiltInKOV PM_LPNotKOV at doc233 "15.8" "15.8. Units".
Document PM_DuplicateUnitSpec at doc234 "15.9" "15.9. Multiple notations".
Document PM_LPTooLittleAccuracy PM_LPCantScaleTwice PM_LPCantScaleYet at doc235 "15.10" "15.10. Scaling and equivalents".
Document PM_LPNotAllNamed PM_LPTooComplicated PM_LPTooManyElements PM_LPElementTooLarge PM_LPWithoutElement at doc239 "15.14" "15.14. Notations including more than one number".
Document PM_BadLPNameOption PM_BadLPPartOption PM_LPMultipleOptional PM_LPFirstOptional at doc240 "15.15" "15.15. The parts of a number specification".
Document PM_TotalTableColumn PM_TotalEitherOr ph_total at doc242 "15.17" "15.17. Totals".
Document PM_EquationSymbolWrongKOV PM_EquationSymbolMissing PM_EquationInsoluble PM_EquationBadTarget PM_EquationBadArithmetic PM_EquationDimensionPower PM_EquationIncomparable PM_EquationEquatesMultiply PM_EquationEquatesBadly PM_EquationDoesntEquate PM_EquationMispunctuated PM_EquationTooComplex PM_EquationOperatorUnrecognised PM_EquationLeadingZero PM_EquationTokenUnrecognised PM_EquationSymbolSpurious PM_EquationSymbolBadSub PM_EquationSymbolNonNumeric PM_EquationSymbolEqualsKOV PM_EquationSymbolNonValue PM_EquationSymbolVague PM_EquationSymbolMalformed PM_EquationSymbolMisdeclared PM_EquationMisnamed PM_EquationMisnumbered EQUATIONS ph_letequation at doc243 "15.18" "15.18. Equations".
Document ARITHMETIC PM_BadArithmetic PM_MultiplyingNonKOVs PM_BadLPOffset PM_BadLPEquivalent PM_DimensionsInconsistent PM_UnitSequenceOverflow PM_NonDimensional PM_DimensionNotBaseKOV PM_DimensionRedundant at doc245 "15.20" "15.20. Multiplication of units".
Document PM_TableRowFull PM_TableColumnBrackets PM_TableKindlessColumn PM_TableEntryGeneric PM_TableWithBlankNames PM_TableDefiningObject PM_TableOfExistingKind PM_TableOfBuiltInKind PM_TableOfQuantifiedKind PM_TableUndefined PM_TableWithoutRows PM_TableColumnAlready PM_TableColumnArticle PM_TableTooManyColumns PM_TableNameAmbiguous PM_TableNameDuplicate PM_TableMisnamed PM_TableIncompatibleEntry PM_TableUnknownEntry PM_TableDescriptionEntry PM_TableVariableEntry PM_TablePlayerEntry PM_TableColumnEmptyLists PM_TableCoincidesWithKind TABLES at doc246 "16.1" "16.1. Laying out tables".
Document ph_numrows at doc247 "16.2" "16.2. Looking up entries".
Document ph_showmetable phs_currenttablerow phs_tablerow phs_tablecolumn at doc249 "16.4" "16.4. Changing entries".
Document PM_NoRowSelected ph_chooserow ph_chooserowwith ph_chooserandomrow at doc250 "16.5" "16.5. Choosing rows".
Document ph_repeattable ph_repeattablereverse ph_repeattablecol ph_repeattablecolreverse at doc251 "16.6" "16.6. Repeating through tables".
Document ph_thereis ph_thereisno at doc252 "16.7" "16.7. Blank entries".
Document ph_chooseblankrow ph_numblank ph_numfilled ph_blankout ph_blankoutrow ph_blankoutcol ph_blankouttable at doc255 "16.10" "16.10. Adding and removing rows".
Document ph_sortrandom ph_sortcolumn ph_sortcolumnreverse at doc256 "16.11" "16.11. Sorting".
Document kind_tablename at doc260 "16.15" "16.15. Varying which table to look at".
Document PM_TableDefiningTheImpossible PM_TableDefiningNothing at doc261 "16.16" "16.16. Defining things with tables".
Document PM_TableNotContinuation at doc263 "16.18" "16.18. Table continuations".
Document PM_TableAmendmentMismatch PM_TableAmendmentMisfit at doc264 "16.19" "16.19. Table amendments".
Document UNDERSTANDING someone_token PM_TextTokenRestricted PM_OverComplexToken PM_BizarreToken PM_UnknownToken PM_UnparsableKind PM_UseThingNotObject PM_UseTextNotTopic PM_ObsoleteHeldTokens PM_UnderstandAsCompoundText PM_UnderstandCommaCommand PM_UnderstandEmptyText PM_LiteralPunctuation PM_UnderstandVague PM_UnderstandAsBadValue PM_UnderstandAsActivity PM_TextlessMistake PM_UnderstandMismatch PM_NontextualUnderstand PM_NotOldCommand PM_NotNewCommand PM_UnderstandCommandWhen PM_OldVerbUsage at doc265 "17.1" "17.1. Understand".
Document PM_GrammarIllFounded PM_TooManyGrammarLines PM_TooManyAliases PM_ThreeValuedLine at doc266 "17.2" "17.2. New commands for old grammar".
Document TOKENS things_token at doc268 "17.4" "17.4. Standard tokens of grammar".
Document text_token at doc269 "17.5" "17.5. The text token".
Document var_understood at doc273 "17.9" "17.9. Understanding kinds of value".
Document PM_UnderstandPluralValue PM_UnderstandAsQualified at doc275 "17.11" "17.11. Understanding values".
Document PM_SlashedCommand PM_OverAmbitiousSlash at doc276 "17.12" "17.12. This/that".
Document NEWTOKENS PM_TwoValuedToken PM_MixedOutcome at doc277 "17.13" "17.13. New tokens".
Document PM_UnknownUnpermittedProperty PM_BadReferringProperty PM_BadUnderstandPropertyAs PM_BadUnderstandProperty PM_UnknownUnderstandProperty at doc279 "17.15" "17.15. Understanding things by their properties".
Document PM_GrammarValueRelation PM_GrammarBadRelation PM_GrammarObjectlessRelation at doc280 "17.16" "17.16. Understanding things by their relations".
Document PM_BadWhen at doc281 "17.17" "17.17. Context: understanding when".
Document ph_setpronouns at doc282 "17.18" "17.18. Changing the meaning of pronouns".
Document rules_dtpm at doc283 "17.19" "17.19. Does the player mean...".
Document ph_multipleobjectlist ph_altermultipleobjectlist at doc284 "17.20" "17.20. Multiple action processing".
Document PM_BadActivityName kind_activity ACTIVITIES at doc287 "18.1" "18.1. What are activities?".
Document PM_BadWhenWhile at doc290 "18.4" "18.4. While clauses".
Document EXTACTIVITIES ph_carryout ph_carryoutwith ph_continueactivity at doc291 "18.5" "18.5. New activities".
Document PM_ActivityVarValue PM_ActivityVarUnknownKOV PM_ActivityVarOverspecific PM_ActivityVarAnd PM_ActivityVariableNameless at doc292 "18.6" "18.6. Activity variables".
Document ph_beginactivity ph_beginactivitywith ph_endactivity ph_endactivitywith ph_handlingactivity ph_handlingactivitywith ph_abandonactivity ph_abandonactivitywith at doc293 "18.7" "18.7. Beginning and ending activities manually".
Document var_particular act_con at doc295 "18.9" "18.9. Deciding the concealed possessions of something".
Document act_pn ph_omit at doc296 "18.10" "18.10. Printing the name of something".
Document act_ppn at doc297 "18.11" "18.11. Printing the plural name of something".
Document act_pan at doc298 "18.12" "18.12. Printing a number of something".
Document act_lc ph_group ph_groupart ph_grouptext at doc299 "18.13" "18.13. Listing contents of something".
Document act_gt at doc300 "18.14" "18.14. Grouping together something".
Document act_resp at doc301 "18.15" "18.15. Issuing the response text of something".
Document act_details at doc302 "18.16" "18.16. Printing room description details of something".
Document act_idetails at doc303 "18.17" "18.17. Printing inventory details of something".
Document act_toodark at doc304 "18.18" "18.18. Printing a refusal to act in the dark".
Document act_nowdark at doc305 "18.19" "18.19. Printing the announcement of darkness".
Document act_nowlight at doc306 "18.20" "18.20. Printing the announcement of light".
Document act_darkname at doc307 "18.21" "18.21. Printing the name of a dark room".
Document act_darkdesc at doc308 "18.22" "18.22. Printing the description of a dark room".
Document act_csl at doc309 "18.23" "18.23. Constructing the status line".
Document act_wpa at doc310 "18.24" "18.24. Writing a paragraph about".
Document act_lni at doc311 "18.25" "18.25. Listing nondescript items of something".
Document act_pld at doc312 "18.26" "18.26. Printing the locale description of something".
Document act_cnlo at doc313 "18.27" "18.27. Choosing notable locale objects for something".
Document act_plp at doc314 "18.28" "18.28. Printing a locale paragraph about".
Document act_ds ph_placeinscope ph_placecontentsinscope at doc315 "18.29" "18.29. Deciding the scope of something".
Document act_clarify at doc316 "18.30" "18.30. Clarifying the parser's choice of something".
Document act_which at doc317 "18.31" "18.31. Asking which do you mean".
Document act_smn at doc318 "18.32" "18.32. Supplying a missing noun/second noun".
Document kind_snippet var_command act_reading ph_snippetmatches ph_snippetdoesnotmatch ph_snippetincludes ph_snippetdoesnotinclude ph_rejectcommand ph_replacesnippet ph_cutsnippet ph_changecommand at doc319 "18.33" "18.33. Reading a command".
Document act_implicitly at doc320 "18.34" "18.34. Implicitly taking something".
Document act_parsererror at doc321 "18.35" "18.35. Printing a parser error".
Document act_all at doc322 "18.36" "18.36. Deciding whether all includes".
Document act_banner phs_banner at doc323 "18.37" "18.37. Printing the banner text".
Document act_obit at doc324 "18.38" "18.38. Printing the player's obituary".
Document act_amuse at doc325 "18.39" "18.39. Amusing a victorious player".
Document act_startvm at doc326 "18.40" "18.40. Starting the virtual machine".
Document PM_RulebookWithTo PM_RulebookWithDefinition PM_RulebookWithAt RULEBOOKS kind_rulebook kind_rule at doc327 "19.1" "19.1. On rules".
Document PM_RuleWithoutColon PM_RuleWithDefiniteArticle PM_BadRulePreamble PM_BadRulePreambleWhen at doc329 "19.3" "19.3. New rules".
Document PM_PlaceWithMissingRule PM_NoSuchRuleExists PM_UnspecifiedRulebookPlacement PM_BadRulePlacementNegation PM_ImproperRulePlacement RLISTING at doc330 "19.4" "19.4. Listing rules explicitly".
Document rules_proc at doc331 "19.5" "19.5. Changing the behaviour of rules".
Document NEWRULEBOOKS ph_follow at doc334 "19.8" "19.8. New rulebooks".
Document ph_followfor at doc335 "19.9" "19.9. Basis of a rulebook".
Document PM_RulebookVariableVague PM_RulebookVariableBadKind PM_RulebookVariableTooSpecific PM_RulebookVariableAnd at doc336 "19.10" "19.10. Rulebook variables".
Document PM_BadDefaultOutcome PM_DefaultOutcomeTwice ph_succeeds ph_fails ph_nodecision ph_succeeded ph_failed at doc337 "19.11" "19.11. Success and failure".
Document PM_NonOutcomeProperty PM_DuplicateOutcome PM_DefaultOutcomeAlready PM_DefaultNamedOutcomeTwice PM_BadOutcomeClarification PM_WrongEndToPhrase PM_MisplacedRulebookOutcome ph_rulebookoutcome at doc338 "19.12" "19.12. Named outcomes".
Document ph_succeedswith ph_producedby ph_producedbyfor at doc339 "19.13" "19.13. Rulebooks producing values".
Document ph_abide ph_abidefor ph_abideanon at doc340 "19.14" "19.14. Abide by".
Document rules_internal at doc341 "19.15" "19.15. Two rulebooks used internally".
Document ph_charnum ph_numchars ph_wordnum ph_numwords ph_pwordnum ph_numpwords ph_upwordnum ph_numupwords ph_linenum ph_numlines ph_paranum ph_numparas at doc345 "20.3" "20.3. Characters, words, punctuated words, unpunctuated words, lines, paragraphs".
Document ph_inlower ph_inupper ph_lowercase ph_uppercase ph_titlecase ph_sentencecase at doc346 "20.4" "20.4. Upper and lower case letters".
Document ph_matches ph_exactlymatches ph_nummatches at doc347 "20.5" "20.5. Matching and exactly matching".
Document ph_matchesre ph_exactlymatchesre ph_nummatchesre ph_matchtext ph_subexpressiontext at doc348 "20.6" "20.6. Regular expression matching".
Document ph_subform at doc349 "20.7" "20.7. Making new text with text substitutions".
Document ph_replacechar ph_replaceword ph_replacepword ph_replaceupword ph_replaceline ph_replacepara ph_replace ph_replacewordin ph_replacepwordin ph_replacere at doc350 "20.8" "20.8. Replacements".
Document kind_listof at doc352 "21.1" "21.1. Lists and entries".
Document PM_IncompatibleConstantListEntry PM_NonconstantConstantListEntry PM_BadConstantListEntry PM_CantLetEmptyList at doc353 "21.2" "21.2. Constant lists".
Document phs_listbraced phs_listdef phs_listindef at doc354 "21.3" "21.3. Saying lists of values".
Document ph_islistedin ph_isnotlistedin ph_repeatlist at doc355 "21.4" "21.4. Testing and iterating over lists".
Document ph_addtolist ph_addlisttolist ph_addatentry ph_addlistatentry ph_remfromlist ph_remlistfromlist ph_rementry ph_rementries at doc356 "21.5" "21.5. Building lists".
Document ph_listofdesc at doc357 "21.6" "21.6. Lists of objects".
Document ph_reverselist ph_sortlist ph_sortlistreverse ph_sortlistrandom ph_sortlistproperty ph_sortlistpropertyreverse ph_rotatelist ph_rotatelistback at doc359 "21.8" "21.8. Sorting, reversing and rotating lists".
Document ph_numberentries at doc360 "21.9" "21.9. Accessing entries in a list".
Document ph_changelength ph_truncate ph_truncatefirst ph_truncatelast ph_extend at doc361 "21.10" "21.10. Lengthening or shortening a list".
Document kind_description ph_valuematch at doc364 "22.2" "22.2. Descriptions as values".
Document ph_applied0 ph_applied1 ph_applied2 ph_applied3 ph_apply0 ph_apply1 ph_apply2 ph_apply3 at doc365 "22.3" "22.3. Phrases as values".
Document ph_appliedlist ph_filter ph_reduction at doc367 "22.5" "22.5. Map, filter and reduce".
Document PM_UnknownVirtualMachine at doc375 "23.3" "23.3. Virtual machines and story file formats".
Document FIGURES kind_figurename at doc376 "23.4" "23.4. Gathering the figures".
Document PM_PictureNotTextual PM_PictureDuplicate at doc377 "23.5" "23.5. Declaring and previewing the figures".
Document ph_displayfigure at doc378 "23.6" "23.6. Displaying the figures".
Document SOUNDS kind_soundname at doc379 "23.7" "23.7. Recorded sounds".
Document PM_SoundNotTextual PM_SoundDuplicate ph_playsf at doc380 "23.8" "23.8. Declaring and playing back sounds".
Document ph_figureid ph_soundid at doc382 "23.10" "23.10. Some technicalities about figures and sounds".
Document EFILES at doc383 "23.11" "23.11. Files".
Document PM_FilenameUnsafe PM_FilenameNotTextual PM_FilenameDuplicate PM_BadFileOwner PM_BadFileIFID kind_externalfile at doc384 "23.12" "23.12. Declaring files".
Document ph_writetable ph_readtable ph_fileexists at doc385 "23.13" "23.13. Writing and reading tables to external files".
Document ph_writetext ph_appendtext ph_saytext at doc386 "23.14" "23.14. Writing, reading and appending text to files".
Document ph_fileready ph_markfileready ph_markfilenotready at doc387 "23.15" "23.15. Exchanging files with other programs".
Document PM_BadEpisode at doc397 "25.2" "25.2. Bibliographic data".
Document LCARDS at doc399 "25.4" "25.4. The Library Card".
Document IFIDS at doc400 "25.5" "25.5. The Treaty of Babel and the IFID".
Document release_files PM_NoSuchPublicRelease at doc401 "25.6" "25.6. The Release button and the Materials folder".
Document PM_ReleaseAlong at doc402 "25.7" "25.7. The Joy of Feelies".
Document release_cover at doc403 "25.8" "25.8. Cover art".
Document release_postcard release_booklet at doc404 "25.9" "25.9. An introductory booklet and postcard".
Document release_website at doc405 "25.10" "25.10. A website".
Document release_interpreter at doc406 "25.11" "25.11. A playable web page".
Document PM_RoomInIgnoredSource at doc410 "25.15" "25.15. Republishing existing works of IF".
Document release_solution at doc411 "25.16" "25.16. Walkthrough solutions".
Document release_card release_source at doc412 "25.17" "25.17. Releasing the source text".
Document PM_MapPlacementDirection PM_MapPlacement PM_MapDirectionClue PM_MapHintUnknown PM_MapSettingTypeFailed PM_MapSettingTooLong PM_MapSettingUnknown PM_MapSettingOfUnknown PM_MapLevelMisnamed PM_MapBadRubric PM_MapUnknownOffsetBase PM_MapUnknownOffset PM_MapUnknownColour PM_MapNonLateral PM_MapToNonRoom PM_MapFromNonRoom MAPHINTS at doc413 "25.18" "25.18. Improving the index map".
Document EPSMAP at doc414 "25.19" "25.19. Producing an EPS format map".
Document EXTENSIONS at doc430 "27.1" "27.1. The status of extensions".
Document SRULES at doc431 "27.2" "27.2. The Standard Rules".
Document PM_ExtNoEndsHere PM_ExtNoBeginsHere PM_ExtMultipleEndsHere PM_ExtEndsWithoutBegins PM_ExtBeginsAfterEndsHere PM_ExtMultipleBeginsHere at doc434 "27.5" "27.5. A simple example extension".
Document PM_ExtNoVersion PM_ExtVersionTooLow phs_extcredits phs_compextcredits at doc435 "27.6" "27.6. Version numbering".
Document PM_UnequalHeadingInPlaceOf PM_HeadingInPlaceOfUnknown PM_HeadingInPlaceOfUnincluded at doc438 "27.9" "27.9. Extensions can interact with other extensions".
Document PM_ImplicationValueProperty PM_ImplicationCertain at doc442 "27.13" "27.13. Implications".
Document PM_BadInlineTag PM_BadInlineExpansion PM_InlineRule PM_InlineTooLong PM_UnendingI6 at doc444 "27.15" "27.15. Defining phrases in Inform 6".
Document PM_BadObjectTranslation at doc450 "27.21" "27.21. Inform 6 objects and classes".
Document PM_QuantityTranslatedAlready PM_NonQuantityTranslated PM_NonPropertyTranslated PM_TranslatedToNonIdentifier PM_TranslatedUnknownCategory PM_TranslatedTwice PM_TranslatesActionAlready PM_TranslatesNonAction at doc451 "27.22" "27.22. Inform 6 variables, properties, actions, and attributes".
Document PM_GrammarTranslatedAlready at doc452 "27.23" "27.23. Inform 6 Understand tokens".
Document PM_UnicodeOutOfRange PM_UnicodeNonLiteral PM_UnicodeAlready at doc454 "27.25" "27.25. Naming Unicode characters".
Document PM_WhenDefiningUnknown PM_BeforeTheLibrary PM_BadI6Inclusion PM_NoSuchPart PM_NoSuchTemplate at doc455 "27.26" "27.26. The template layer".
Document PM_LabelNamespaceTooLong at doc458 "27.29" "27.29. Invocation labels, counters and storage".
[...and so on...]

@ Inform source text has a core of basic computational abilities, and then
a whole set of additional elements to handle IF. We want all of those to be
used, so:

=
Use interactive fiction language elements. Use multimedia language elements.

@ Some Inform 7 projects are rather heavy-duty by the expectations of the
Inform 6 compiler (which it uses as a code-generator): I6 was written fifteen
years earlier, when computers were unimaginably smaller and slower. So many
of its default memory settings need to be raised to higher maxima.

Note that the Z-machine cannot accommodate more than 255 verbs, so this is
the highest |MAX_VERBS| setting we can safely make here.

The |MAX_LOCAL_VARIABLES| setting is suppressed by I7 if we're compiling
to the Z-machine, because it's only legal in I6 when compiling to Glulx.

=
Use ALLOC_CHUNK_SIZE of 32000.
Use MAX_ARRAYS of 10000.
Use MAX_CLASSES of 200.
Use MAX_VERBS of 255.
Use MAX_LABELS of 10000.
Use MAX_ZCODE_SIZE of 500000.
Use MAX_STATIC_DATA of 180000.
Use MAX_PROP_TABLE_SIZE of 200000.
Use MAX_INDIV_PROP_TABLE_SIZE of 20000.
Use MAX_STACK_SIZE of 65536.
Use MAX_SYMBOLS of 20000.
Use MAX_EXPRESSION_NODES of 256.
Use MAX_LABELS of 200000.
Use MAX_LOCAL_VARIABLES of 256.








