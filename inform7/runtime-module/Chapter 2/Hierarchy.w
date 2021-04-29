[Hierarchy::] Hierarchy.

To provide an enforced structure and set of naming conventions for packages
and names in the Inter code we generate.

@h Introduction.
See //What This Module Does// for an overview of how Inter hierarchies work.

This section of code amounts to a detailed rundown of exactly how Inform's
hierarchy of packages fits together: it's a sort of directory listing of every
resource we might compile. In actual runs, of course, not all of them will be.

This section makes extensive use of //building: Hierarchy Locations//, which
provides a general way to set up Inter hierarchies.

Adding this to the source text of a project:
= (text as Inform 7)
Include Inter hierarchy in the debugging log.
=
causes the following function to log the Inter hierarchy before and after
linking the kits:

=
void Hierarchy::log(void) {
	if (Log::aspect_switched_on(HIERARCHY_DA)) {
		LOG("+==============================================================+\n");
		LOG("Inventory of current Inter tree:\n");
		LOG("+--------------------------------------------------------------+\n");
		LOG_INDENT;
		CodeGen::Inventory::inv_to(DL, Emit::tree());
		LOG_OUTDENT;
		LOG("+==============================================================+\n\n");
	}
}

@h Notation.
Cower, puny mortal! Know thou not, thou hast entered Macro Valley?

The code given below looks like structured data, but it's actually code, even
if the macros give it the look of having a mini-language of its own. But it's
easy to read with practice.

We are going to give a series of declarations about what can go into a given
position in the hierarchy (a "location requirement"). Each will be a block
beginning either |H_BEGIN| or |H_BEGIN_AP|, and ending |H_END|. These can
be nested, so we store the requirements on a stack.

An |H_BEGIN(location)| block declares what can go into a position in the
hierarchy matching the |location|.

An |H_BEGIN_AP(id, name, type)| block can only be given inside another block, and
says that there is an "attachment position" at this location. This means that
a family of similarly-structured packages there, and each one has the contents
which follow. Attachment positions like |id| are numbered with the |*_HAP|
enumeration. Names for the packages are generated using |name| (they will then
be numbered in sequence |name_0|, |name_1| and so on), and they have |type|
as their package type.

For example, this:
= (text as InC)
	submodule_identity *activities = Packaging::register_submodule(I"activities");
	H_BEGIN(HierarchyLocations::local_submodule(activities))
		H_BEGIN_AP(ACTIVITIES_HAP,            I"activity", I"_activity")
			...
		H_END
	H_END
=
declares that each compilation unit will have a package called |activities| of
type |_submodule|. Inside that will be a numbered series of packages called
|activity_0|, |activity_1|, ..., each one of type |_activity|. And inside each
of those packages will be the ingredients specified by |...|.

Note that |H_BEGIN_AP| ... |H_END| blocks can be nested inside each other; in
principle to any depth, though as it happens we never exceed 3.

@d MAX_H_REQUIREMENTS_DEPTH 10
@d H_BEGIN_DECLARATIONS
	inter_tree *I = Emit::tree();
	location_requirement requirements[MAX_H_REQUIREMENTS_DEPTH];
	int req_sp = 0;
@d H_BEGIN(r) 
	if (req_sp >= MAX_H_REQUIREMENTS_DEPTH) internal_error("too deep for me");
	requirements[req_sp++] = r;
@d H_BEGIN_AP(a, b, c)
	HierarchyLocations::att(I, a, b, c, H_CURRENT);
	H_BEGIN(HierarchyLocations::any_package_of_type(c))
@d H_END
	if (req_sp == 0) internal_error("too many H-exits");
	req_sp--;
@d H_CURRENT
	requirements[req_sp-1]
@d H_END_DECLARATIONS
	if (req_sp != 0) internal_error("hierarchy misaligned");

@ So, other than |H_BEGIN_AP| ... |H_END| blocks, what can appear inside a
block? The answer is that we can define four different things.

@ A package can appear. |id| is the location ID, one of the |*_HL| enumerated
values. |name| and |type| are then the package name and type.

@d H_PKG(id, name, type) HierarchyLocations::pkg(I, id, name, type, H_CURRENT);

@ A constant can appear. Constants, like cats, have three different
names: the |id| is one of the |*_HL| enumeration values; the |identifier| is
the identifier this constant will have within its Inter package; and the
|translation| is the identifier that will be translated to when the Inter code
is eventually converted to, say, Inform 6 code in our final output.

An important difference here is that Inter identifiers only have to be unique
within their own packages, which are in effect namespaces. But translated
identifiers have to be unique across the whole compiled program. Several
different strategies are used to concoct these translated identifiers:

(*) |H_C_T| means the constant is a one-off, and the translation is the same
as the Inter identifier, unless Inform source text has intervened to change
that translation.
(*) |H_C_G| means that the constant will appear in multiple packages, and that
Inform should generate unique names for it based on the one given, e.g., by
suffixing |_1|, |_2|, ...
(*) |H_C_S| is like |H_C_G|, except that the name is taken from the parent
package with a suffix;
(*) |H_C_P| is like |H_C_G|, except that the name is taken from the parent
package with a prefix;
(*) |H_C_U| is like |H_C_G|, except that this "unique-ization" should be done
at the linking stage, not in the main compiler.
(*) |H_C_I| says that Inform will impose a choice of its own which is not
expressible here. This is used very little, but for example to make sure that
kind IDs for kinds supplied by kits have the names given for them in Neptune files.

@d H_C_T(id, n) HierarchyLocations::ctr(I, id, n,    Translation::same(),      H_CURRENT);
@d H_C_G(id, n) HierarchyLocations::ctr(I, id, NULL, Translation::generate(n), H_CURRENT);
@d H_C_S(id, n) HierarchyLocations::ctr(I, id, NULL, Translation::suffix(n),   H_CURRENT);
@d H_C_P(id, n) HierarchyLocations::ctr(I, id, NULL, Translation::prefix(n),   H_CURRENT);
@d H_C_U(id, n) HierarchyLocations::ctr(I, id, n,    Translation::uniqued(),   H_CURRENT);
@d H_C_I(id)    HierarchyLocations::ctr(I, id, NULL, Translation::imposed(),   H_CURRENT);

@ Functions use the same conventions, except that "imposition" never happens.

@d H_F_T(id, n, t) HierarchyLocations::fun(I, id, n, Translation::to(t),       H_CURRENT);
@d H_F_G(id, n, t) HierarchyLocations::fun(I, id, n, Translation::generate(t), H_CURRENT);
@d H_F_S(id, n, t) HierarchyLocations::fun(I, id, n, Translation::suffix(t),   H_CURRENT);
@d H_F_P(id, n, t) HierarchyLocations::fun(I, id, n, Translation::prefix(t),   H_CURRENT);
@d H_F_U(id, n)    HierarchyLocations::fun(I, id, n, Translation::uniqued(),   H_CURRENT);

@ Last and least, a datum can appear. |id| is the location ID, one of the |*_HL| enumerated
values.

@d H_D_T(id, ident, final) HierarchyLocations::dat(I, id, ident, Translation::to(final), H_CURRENT);

@ We can finally give the single function which sets up almost the entire hierarchy.
The eventual hierarchy will contain both

(1) material generated in the main compiler, such as functions derived from rule
definitions, and also
(2) material added later in linking, for example from kits like //WorldModelKit//.

The following catalogue contains location and naming conventions for everything
in category (1), and for some of the names in category (2) which the main 
compiler needs to refer to. For example, the Inform compiler generates calls
to an Inter function called |BlkValueCopy|. This is a function in the kit
//BasicInformKit//, but it has a hierarchy location ID, |BLKVALUECOPY_HL|, so
that the compiler can refer to it.

=
void Hierarchy::establish(void) {
	H_BEGIN_DECLARATIONS
	@<Establish locations for material created by the compiler@>;
	@<Establish locations for material expected to be added by linking@>;
	InterNames::to_symbol(Hierarchy::find(SELF_HL));
	H_END_DECLARATIONS
}

@<Establish locations for material created by the compiler@> =
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
	@<Establish phrases@>;
	@<Establish properties@>;
	@<Establish relations@>;
	@<Establish rulebooks@>;
	@<Establish rules@>;
	@<Establish tables@>;
	@<Establish variables@>;
	@<Establish enclosed matter@>;
	@<The rest@>;

@<Establish locations for material expected to be added by linking@> =
	@<Establish veneer resources@>;
	@<Establish kit-defined resources@>;

@h Basics.

@e NULL_HL from 0
@e WORD_HIGHBIT_HL
@e WORD_NEXTTOHIGHBIT_HL
@e IMPROBABLE_VALUE_HL
@e REPARSE_CODE_HL
@e MAX_POSITIVE_NUMBER_HL
@e MIN_NEGATIVE_NUMBER_HL
@e I7_VERSION_NUMBER_HL
@e I7_FULL_VERSION_NUMBER_HL
@e RANKING_TABLE_HL
@e MAX_WEAK_ID_HL
@e NO_VERB_VERB_DEFINED_HL
@e NO_TEST_SCENARIOS_HL
@e MEMORY_HEAP_SIZE_HL
@e KIT_CONFIGURATION_BITMAP_HL
@e KIT_CONFIGURATION_LOOKMODE_HL
@e LOCALPARKING_HL

@e MAX_FRAME_SIZE_NEEDED_HL
@e RNG_SEED_AT_START_OF_PLAY_HL

@e SUBMAIN_HL

@<Establish basics@> =
	submodule_identity *basics = Packaging::register_submodule(I"basics");

	H_BEGIN(HierarchyLocations::generic_submodule(I, basics))
		H_C_T(NULL_HL,                        I"NULL")
		H_C_T(WORD_HIGHBIT_HL,                I"WORD_HIGHBIT")
		H_C_T(WORD_NEXTTOHIGHBIT_HL,          I"WORD_NEXTTOHIGHBIT")
		H_C_T(IMPROBABLE_VALUE_HL,            I"IMPROBABLE_VALUE")
		H_C_T(REPARSE_CODE_HL,                I"REPARSE_CODE")
		H_C_T(MAX_POSITIVE_NUMBER_HL,         I"MAX_POSITIVE_NUMBER")
		H_C_T(MIN_NEGATIVE_NUMBER_HL,         I"MIN_NEGATIVE_NUMBER")
		H_C_T(I7_VERSION_NUMBER_HL,           I"I7_VERSION_NUMBER")
		H_C_T(I7_FULL_VERSION_NUMBER_HL,      I"I7_FULL_VERSION_NUMBER")
		H_C_T(RANKING_TABLE_HL,               I"RANKING_TABLE")
		H_C_T(MAX_WEAK_ID_HL,                 I"MAX_WEAK_ID")
		H_C_T(NO_VERB_VERB_DEFINED_HL,        I"NO_VERB_VERB_DEFINED")
		H_C_T(MEMORY_HEAP_SIZE_HL,            I"MEMORY_HEAP_SIZE")
		H_C_T(KIT_CONFIGURATION_BITMAP_HL,    I"KIT_CONFIGURATION_BITMAP")
		H_C_T(KIT_CONFIGURATION_LOOKMODE_HL,  I"KIT_CONFIGURATION_LOOKMODE")
		H_C_T(LOCALPARKING_HL,                I"LocalParking")
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, basics))
		H_C_T(MAX_FRAME_SIZE_NEEDED_HL,       I"MAX_FRAME_SIZE_NEEDED")
		H_C_T(RNG_SEED_AT_START_OF_PLAY_HL,   I"RNG_SEED_AT_START_OF_PLAY")
	H_END

	submodule_identity *basic_extras = Packaging::register_submodule(I"BasicInformExtrasKit");
	H_BEGIN(HierarchyLocations::generic_submodule(I, basic_extras))
		H_F_T(SUBMAIN_HL,                     I"Submain_fn", I"Submain")
	H_END

@h Modules.

@e EXT_CATEGORY_METADATA_HL
@e EXT_TITLE_METADATA_HL
@e EXT_AUTHOR_METADATA_HL
@e EXT_VERSION_METADATA_HL

@<Establish modules@> =
	H_BEGIN(HierarchyLocations::any_package_of_type(I"_module"))
		H_C_U(EXT_CATEGORY_METADATA_HL,       I"^category")
		H_C_U(EXT_TITLE_METADATA_HL,          I"^title")
		H_C_U(EXT_AUTHOR_METADATA_HL,         I"^author")
		H_C_U(EXT_VERSION_METADATA_HL,        I"^version")
	H_END

@h Actions.

@e BOGUS_HAP from 0
@e ACTIONS_HAP
@e ACTION_NAME_METADATA_HL
@e ACTION_VARC_METADATA_HL
@e DEBUG_ACTION_METADATA_HL
@e ACTION_DSHARP_METADATA_HL
@e NO_CODING_METADATA_HL
@e OUT_OF_WORLD_METADATA_HL
@e REQUIRES_LIGHT_METADATA_HL
@e CAN_HAVE_NOUN_METADATA_HL
@e CAN_HAVE_SECOND_METADATA_HL
@e NOUN_ACCESS_METADATA_HL
@e SECOND_ACCESS_METADATA_HL
@e NOUN_KIND_METADATA_HL
@e SECOND_KIND_METADATA_HL
@e ACTION_ID_HL
@e ACTION_BASE_NAME_HL
@e WAIT_HL
@e TRANSLATED_BASE_NAME_HL
@e DOUBLE_SHARP_NAME_HL
@e PERFORM_FN_HL
@e DEBUG_ACTION_FN_HL
@e CHECK_RB_HL
@e CARRY_OUT_RB_HL
@e REPORT_RB_HL
@e ACTION_SHV_ID_HL
@e ACTION_STV_CREATOR_FN_HL

@e ACTIONCODING_HL
@e ACTIONDATA_HL
@e ACTIONHAPPENED_HL
@e AD_RECORDS_HL
@e CCOUNT_ACTION_NAME_HL
@e DB_ACTION_DETAILS_HL

@<Establish actions@> =
	submodule_identity *actions = Packaging::register_submodule(I"actions");

	H_BEGIN(HierarchyLocations::local_submodule(actions))
		H_BEGIN_AP(ACTIONS_HAP,               I"action", I"_action")
			H_C_U(ACTION_NAME_METADATA_HL,    I"^name")
			H_C_U(ACTION_VARC_METADATA_HL,    I"^var_creator")
			H_C_U(DEBUG_ACTION_METADATA_HL,   I"^debug_fn")
			H_C_U(ACTION_DSHARP_METADATA_HL,  I"^double_sharp")
			H_C_U(NO_CODING_METADATA_HL,      I"^no_coding")
			H_C_U(OUT_OF_WORLD_METADATA_HL,   I"^out_of_world")
			H_C_U(REQUIRES_LIGHT_METADATA_HL, I"^requires_light")
			H_C_U(CAN_HAVE_NOUN_METADATA_HL,  I"^can_have_noun")
			H_C_U(CAN_HAVE_SECOND_METADATA_HL, I"^can_have_second")
			H_C_U(NOUN_ACCESS_METADATA_HL,    I"^noun_access")
			H_C_U(SECOND_ACCESS_METADATA_HL,  I"^second_access")
			H_C_U(NOUN_KIND_METADATA_HL,      I"^noun_kind")
			H_C_U(SECOND_KIND_METADATA_HL,    I"^second_kind")
			H_C_U(ACTION_ID_HL,               I"action_id")
			H_C_U(ACTION_BASE_NAME_HL,        I"A")
			H_C_T(WAIT_HL,                    I"Wait")
			H_C_I(TRANSLATED_BASE_NAME_HL)
			H_C_P(DOUBLE_SHARP_NAME_HL,       I"##")
			H_F_S(PERFORM_FN_HL,              I"perform_fn", I"Sub")
			H_F_S(DEBUG_ACTION_FN_HL,         I"debug_fn", I"Dbg")
			H_PKG(CHECK_RB_HL,                I"check_rb", I"_rulebook")
			H_PKG(CARRY_OUT_RB_HL,            I"carry_out_rb", I"_rulebook")
			H_PKG(REPORT_RB_HL,               I"report_rb", I"_rulebook")
			H_C_U(ACTION_SHV_ID_HL,           I"var_id")
			H_F_U(ACTION_STV_CREATOR_FN_HL,   I"stv_creator_fn")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, actions))
		H_C_T(ACTIONCODING_HL,                I"ActionCoding")
		H_C_T(ACTIONDATA_HL,                  I"ActionData")
		H_C_T(ACTIONHAPPENED_HL,              I"ActionHappened")
		H_C_T(AD_RECORDS_HL,                  I"AD_RECORDS")
		H_C_T(CCOUNT_ACTION_NAME_HL,          I"CCOUNT_ACTION_NAME")
		H_F_T(DB_ACTION_DETAILS_HL,           I"DB_Action_Details_fn", I"DB_Action_Details")
	H_END

@h Activities.

@e ACTIVITIES_HAP
@e ACTIVITY_NAME_METADATA_HL
@e ACTIVITY_VARC_METADATA_HL
@e ACTIVITY_BEFORE_METADATA_HL
@e ACTIVITY_FOR_METADATA_HL
@e ACTIVITY_AFTER_METADATA_HL
@e ACTIVITY_UFA_METADATA_HL
@e ACTIVITY_ID_HL
@e ACTIVITY_HL
@e BEFORE_RB_HL
@e FOR_RB_HL
@e AFTER_RB_HL
@e ACTIVITY_SHV_ID_HL
@e ACTIVITY_STV_CREATOR_FN_HL

@e ACTIVITY_AFTER_RULEBOOKS_HL
@e ACTIVITY_ATB_RULEBOOKS_HL
@e ACTIVITY_BEFORE_RULEBOOKS_HL
@e ACTIVITY_FOR_RULEBOOKS_HL
@e ACTIVITY_VAR_CREATORS_HL

@<Establish activities@> =
	submodule_identity *activities = Packaging::register_submodule(I"activities");

	H_BEGIN(HierarchyLocations::local_submodule(activities))
		H_BEGIN_AP(ACTIVITIES_HAP,            I"activity", I"_activity")
			H_C_U(ACTIVITY_NAME_METADATA_HL,  I"^name")
			H_C_U(ACTIVITY_BEFORE_METADATA_HL, I"^before_rulebook")
			H_C_U(ACTIVITY_FOR_METADATA_HL,   I"^for_rulebook")
			H_C_U(ACTIVITY_AFTER_METADATA_HL, I"^after_rulebook")
			H_C_U(ACTIVITY_UFA_METADATA_HL,   I"^used_by_future")
			H_C_U(ACTIVITY_VARC_METADATA_HL,  I"^var_creator")
			H_C_U(ACTIVITY_ID_HL,             I"activity_id")
			H_C_G(ACTIVITY_HL,                I"V")
			H_PKG(BEFORE_RB_HL,               I"before_rb", I"_rulebook")
			H_PKG(FOR_RB_HL,                  I"for_rb", I"_rulebook")
			H_PKG(AFTER_RB_HL,                I"after_rb", I"_rulebook")
			H_C_U(ACTIVITY_SHV_ID_HL,         I"var_id")
			H_F_U(ACTIVITY_STV_CREATOR_FN_HL, I"stv_creator_fn")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, activities))
		H_C_T(ACTIVITY_AFTER_RULEBOOKS_HL,    I"Activity_after_rulebooks")
		H_C_T(ACTIVITY_ATB_RULEBOOKS_HL,      I"Activity_atb_rulebooks")
		H_C_T(ACTIVITY_BEFORE_RULEBOOKS_HL,   I"Activity_before_rulebooks")
		H_C_T(ACTIVITY_FOR_RULEBOOKS_HL,      I"Activity_for_rulebooks")
		H_C_T(ACTIVITY_VAR_CREATORS_HL,       I"activity_var_creators")
	H_END

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

	H_BEGIN(HierarchyLocations::local_submodule(adjectives))
		H_BEGIN_AP(ADJECTIVES_HAP,            I"adjective", I"_adjective")
			H_C_U(ADJECTIVE_HL,               I"adjective")
			H_BEGIN_AP(ADJECTIVE_TASKS_HAP,   I"adjective_task", I"_adjective_task")
				H_F_U(TASK_FN_HL,             I"task_fn")
			H_END
		H_END
		H_BEGIN_AP(ADJECTIVE_MEANINGS_HAP,    I"adjective_meaning", I"_adjective_meaning")
			H_F_G(MEASUREMENT_FN_HL,          I"measurement_fn", I"MADJ_Test")
		H_END
		H_BEGIN_AP(ADJECTIVE_PHRASES_HAP,     I"adjective_phrase", I"_adjective_phrase")
			H_F_G(DEFINITION_FN_HL,           I"measurement_fn", I"ADJDEFN")
		H_END
	H_END

@h Bibliographic.

@e UUID_ARRAY_HL
@e STORY_HL
@e HEADLINE_HL
@e STORY_AUTHOR_HL
@e RELEASE_HL
@e SERIAL_HL

@<Establish bibliographic@> =
	submodule_identity *bibliographic = Packaging::register_submodule(I"bibliographic");

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, bibliographic))
		H_C_T(UUID_ARRAY_HL,                  I"UUID_ARRAY")
		H_D_T(STORY_HL,                       I"Story_datum", I"Story")
		H_D_T(HEADLINE_HL,                    I"Headline_datum", I"Headline")
		H_D_T(STORY_AUTHOR_HL,                I"Author_datum", I"Story_Author")
		H_D_T(RELEASE_HL,                     I"Release_datum", I"Release")
		H_D_T(SERIAL_HL,                      I"Serial_datum", I"Serial")
	H_END

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

	H_BEGIN(HierarchyLocations::local_submodule(chronology))
		H_BEGIN_AP(PAST_ACTION_PATTERNS_HAP,  I"past_action_pattern", I"_past_action_pattern")
			H_F_G(PAP_FN_HL,                  I"pap_fn", I"PAPR")
		H_END
	H_END
	H_BEGIN(HierarchyLocations::synoptic_submodule(I, chronology))
		H_C_T(TIMEDEVENTSTABLE_HL,            I"TimedEventsTable")
		H_C_T(TIMEDEVENTTIMESTABLE_HL,        I"TimedEventTimesTable")
		H_C_T(PASTACTIONSI6ROUTINES_HL,       I"PastActionsI6Routines")
		H_C_T(NO_PAST_TENSE_CONDS_HL,         I"NO_PAST_TENSE_CONDS")
		H_C_T(NO_PAST_TENSE_ACTIONS_HL,       I"NO_PAST_TENSE_ACTIONS")
		H_F_T(TESTSINGLEPASTSTATE_HL,         I"test_fn", I"TestSinglePastState")
	H_END

@h Conjugations.

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@e MVERBS_HAP
@e MVERB_NAME_METADATA_HL
@e MODAL_CONJUGATION_FN_HL
@e VERBS_HAP
@e VERB_NAME_METADATA_HL
@e NONMODAL_CONJUGATION_FN_HL
@e VERB_FORMS_HAP
@e FORM_FN_HL
@e CONJUGATION_FN_HL

@<Establish conjugations@> =
	submodule_identity *conjugations = Packaging::register_submodule(I"conjugations");

	H_BEGIN(HierarchyLocations::generic_submodule(I, conjugations))
		H_C_T(CV_MEANING_HL,                  I"CV_MEANING")
		H_C_T(CV_MODAL_HL,                    I"CV_MODAL")
		H_C_T(CV_NEG_HL,                      I"CV_NEG")
		H_C_T(CV_POS_HL,                      I"CV_POS")
	H_END

	H_BEGIN(HierarchyLocations::local_submodule(conjugations))
		H_BEGIN_AP(MVERBS_HAP,                I"mverb", I"_modal_verb")
			H_C_U(MVERB_NAME_METADATA_HL,     I"^name")
			H_F_G(MODAL_CONJUGATION_FN_HL,    I"conjugation_fn", I"ConjugateModalVerb")
		H_END
		H_BEGIN_AP(VERBS_HAP,                 I"verb", I"_verb")
			H_C_U(VERB_NAME_METADATA_HL,      I"^name")
			H_F_G(NONMODAL_CONJUGATION_FN_HL, I"conjugation_fn", I"ConjugateVerb")
			H_BEGIN_AP(VERB_FORMS_HAP,        I"form", I"_verb_form")
				H_F_U(FORM_FN_HL,             I"form_fn")
			H_END
		H_END
	H_END

@h Equations.

@e EQUATIONS_HAP
@e SOLVE_FN_HL

@<Establish equations@> =
	submodule_identity *equations = Packaging::register_submodule(I"equations");

	H_BEGIN(HierarchyLocations::local_submodule(equations))
		H_BEGIN_AP(EQUATIONS_HAP,             I"equation", I"_equation")
			H_F_U(SOLVE_FN_HL,                I"solve_fn")
		H_END
	H_END

@h Extensions.

@e SHOWEXTENSIONVERSIONS_HL
@e SHOWFULLEXTENSIONVERSIONS_HL
@e SHOWONEEXTENSION_HL

@<Establish extensions@> =
	submodule_identity *extensions = Packaging::register_submodule(I"extensions");

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, extensions))
		H_F_T(SHOWEXTENSIONVERSIONS_HL,       I"showextensionversions_fn", I"ShowExtensionVersions")
		H_F_T(SHOWFULLEXTENSIONVERSIONS_HL,   I"showfullextensionversions_fn", I"ShowFullExtensionVersions")
		H_F_T(SHOWONEEXTENSION_HL,            I"showoneextension_fn", I"ShowOneExtension")
	H_END

@h External files.

@e EXTERNAL_FILES_HAP
@e FILE_HL
@e IFID_HL

@<Establish external files@> =
	submodule_identity *external_files = Packaging::register_submodule(I"external_files");

	H_BEGIN(HierarchyLocations::local_submodule(external_files))
		H_BEGIN_AP(EXTERNAL_FILES_HAP,        I"external_file", I"_external_file")
			H_C_U(FILE_HL,                    I"file")
			H_C_U(IFID_HL,                    I"ifid")
		H_END
	H_END

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
@e MISTAKEACTION_HL
@e MISTAKEACTIONSUB_HL

@<Establish grammar@> =
	submodule_identity *grammar = Packaging::register_submodule(I"grammar");

	H_BEGIN(HierarchyLocations::local_submodule(grammar))
		H_BEGIN_AP(COND_TOKENS_HAP,           I"conditional_token", I"_conditional_token")
			H_F_G(CONDITIONAL_TOKEN_FN_HL,    I"conditional_token_fn", I"Cond_Token")
		H_END
		H_BEGIN_AP(CONSULT_TOKENS_HAP,        I"consult_token", I"_consult_token")
			H_F_G(CONSULT_FN_HL,              I"consult_fn", I"Consult_Grammar")
		H_END
		H_BEGIN_AP(TESTS_HAP,                 I"test", I"_test")
			H_C_U(SCRIPT_HL,                  I"script")
			H_C_U(REQUIREMENTS_HL,            I"requirements")
		H_END
		H_BEGIN_AP(LOOP_OVER_SCOPES_HAP,      I"loop_over_scope", I"_loop_over_scope")
			H_F_G(LOOP_OVER_SCOPE_FN_HL,      I"loop_over_scope_fn", I"LOS")
		H_END
		H_BEGIN_AP(MISTAKES_HAP,              I"mistake", I"_mistake")
			H_F_G(MISTAKE_FN_HL,              I"mistake_fn", I"Mistake_Token")
		H_END
		H_BEGIN_AP(NAMED_ACTION_PATTERNS_HAP, I"named_action_pattern", I"_named_action_pattern")
			H_F_G(NAP_FN_HL,                  I"nap_fn", I"NAP")
		H_END
		H_BEGIN_AP(NAMED_TOKENS_HAP,          I"named_token", I"_named_token")
			H_F_G(PARSE_LINE_FN_HL,           I"parse_line_fn", I"GPR_Line")
		H_END
		H_BEGIN_AP(NOUN_FILTERS_HAP,          I"noun_filter", I"_noun_filter")
			H_F_G(NOUN_FILTER_FN_HL,          I"filter_fn", I"Noun_Filter")
		H_END
		H_BEGIN_AP(SCOPE_FILTERS_HAP,         I"scope_filter", I"_scope_filter")
			H_F_G(SCOPE_FILTER_FN_HL,         I"filter_fn", I"Scope_Filter")
		H_END
		H_BEGIN_AP(PARSE_NAMES_HAP,           I"parse_name", I"_parse_name")
			H_F_G(PARSE_NAME_FN_HL,           I"parse_name_fn", I"Parse_Name_GV")
			H_F_G(PARSE_NAME_DASH_FN_HL,      I"parse_name_fn", I"PN_for_S")
		H_END
		H_BEGIN_AP(SLASH_TOKENS_HAP,          I"slash_token", I"_slash_token")
			H_F_G(SLASH_FN_HL,                I"slash_fn", I"SlashGPR")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, grammar))
		H_C_T(VERB_DIRECTIVE_CREATURE_HL,     I"VERB_DIRECTIVE_CREATURE")
		H_C_T(VERB_DIRECTIVE_DIVIDER_HL,      I"VERB_DIRECTIVE_DIVIDER")
		H_C_T(VERB_DIRECTIVE_HELD_HL,         I"VERB_DIRECTIVE_HELD")
		H_C_T(VERB_DIRECTIVE_MULTI_HL,        I"VERB_DIRECTIVE_MULTI")
		H_C_T(VERB_DIRECTIVE_MULTIEXCEPT_HL,  I"VERB_DIRECTIVE_MULTIEXCEPT")
		H_C_T(VERB_DIRECTIVE_MULTIHELD_HL,    I"VERB_DIRECTIVE_MULTIHELD")
		H_C_T(VERB_DIRECTIVE_MULTIINSIDE_HL,  I"VERB_DIRECTIVE_MULTIINSIDE")
		H_C_T(VERB_DIRECTIVE_NOUN_HL,         I"VERB_DIRECTIVE_NOUN")
		H_C_T(VERB_DIRECTIVE_NUMBER_HL,       I"VERB_DIRECTIVE_NUMBER")
		H_C_T(VERB_DIRECTIVE_RESULT_HL,       I"VERB_DIRECTIVE_RESULT")
		H_C_T(VERB_DIRECTIVE_REVERSE_HL,      I"VERB_DIRECTIVE_REVERSE")
		H_C_T(VERB_DIRECTIVE_SLASH_HL,        I"VERB_DIRECTIVE_SLASH")
		H_C_T(VERB_DIRECTIVE_SPECIAL_HL,      I"VERB_DIRECTIVE_SPECIAL")
		H_C_T(VERB_DIRECTIVE_TOPIC_HL,        I"VERB_DIRECTIVE_TOPIC")
		H_F_T(TESTSCRIPTSUB_HL,               I"TestScriptSub_fn", I"TestScriptSub")
		H_F_T(INTERNALTESTCASES_HL,           I"run_tests_fn", I"InternalTestCases")
		H_BEGIN_AP(COMMANDS_HAP,              I"command", I"_command")
			H_F_G(VERB_DECLARATION_ARRAY_HL,  NULL, I"GV_Grammar")
		H_END
		H_C_T(MISTAKEACTION_HL,               I"##MistakeAction")
		H_F_T(MISTAKEACTIONSUB_HL,            I"MistakeActionSub_fn", I"MistakeActionSub")
	H_END

@h Instances.

@e INSTANCES_HAP
@e INSTANCE_NAME_METADATA_HL
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

	H_BEGIN(HierarchyLocations::local_submodule(instances))
		H_BEGIN_AP(INSTANCES_HAP,             I"instance", I"_instance")
			H_C_U(INSTANCE_NAME_METADATA_HL,  I"^name")
			H_C_U(INSTANCE_HL,                I"I")
			H_F_U(BACKDROP_FOUND_IN_FN_HL,    I"backdrop_found_in_fn")
			H_F_G(SHORT_NAME_FN_HL,           I"short_name_fn", I"SN_R")
			H_F_G(SHORT_NAME_PROPERTY_FN_HL,  I"short_name_property_fn", I"SN_R_A")
			H_F_G(REGION_FOUND_IN_FN_HL,      I"region_found_in_fn", I"RFI_for_I")
			H_F_G(TSD_DOOR_DIR_FN_HL,         I"tsd_door_dir_fn", I"TSD_door_dir_value")
			H_F_G(TSD_DOOR_TO_FN_HL,          I"tsd_door_to_fn", I"TSD_door_to_value")
			H_BEGIN_AP(INLINE_PROPERTIES_HAP, I"inline_property", I"_inline_property")
				H_C_U(INLINE_PROPERTY_HL,     I"inline")
			H_END
		H_END
	H_END

@h Interactive Fiction.

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

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, interactive_fiction))
		H_C_T(INITIAL_MAX_SCORE_HL,           I"INITIAL_MAX_SCORE")
		H_C_T(NO_DIRECTIONS_HL,               I"No_Directions")
		H_F_T(SHOWSCENESTATUS_HL,             I"show_scene_status_fn", I"ShowSceneStatus")
		H_F_T(DETECTSCENECHANGE_HL,           I"detect_scene_change_fn", I"DetectSceneChange")
		H_C_T(MAP_STORAGE_HL,                 I"Map_Storage")
		H_C_T(INITIALSITUATION_HL,            I"InitialSituation")
		H_C_T(PLAYER_OBJECT_INIS_HL,          I"PLAYER_OBJECT_INIS")
		H_C_T(START_OBJECT_INIS_HL,           I"START_OBJECT_INIS")
		H_C_T(START_ROOM_INIS_HL,             I"START_ROOM_INIS")
		H_C_T(START_TIME_INIS_HL,             I"START_TIME_INIS")
		H_C_T(DONE_INIS_HL,                   I"DONE_INIS")
		H_BEGIN_AP(DIRECTIONS_HAP,            I"direction", I"_direction")
			H_C_G(DIRECTION_HL,               I"DirectionObject")
		H_END
	H_END

@h Kinds.

@e K_UNCHECKED_HL
@e K_UNCHECKED_FUNCTION_HL
@e K_TYPELESS_INT_HL
@e K_TYPELESS_STRING_HL
@e RUCKSACK_CLASS_HL

@e KIND_HAP
@e KIND_NAME_METADATA_HL
@e KIND_CLASS_HL
@e KIND_HL
@e WEAK_ID_HL
@e ICOUNT_HL
@e ILIST_HL
@e DEFAULT_VALUE_HL
@e DECREMENT_FN_HL
@e INCREMENT_FN_HL
@e PRINT_FN_HL
@e PRINT_DASH_FN_HL
@e RANGER_FN_HL
@e DEFAULT_CLOSURE_FN_HL
@e GPR_FN_HL
@e INSTANCE_GPR_FN_HL
@e INSTANCE_LIST_HL
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

	H_BEGIN(HierarchyLocations::generic_submodule(I, kinds))
		H_C_T(K_UNCHECKED_HL,                 I"K_unchecked")
		H_C_T(K_UNCHECKED_FUNCTION_HL,        I"K_unchecked_function")
		H_C_T(K_TYPELESS_INT_HL,              I"K_typeless_int")
		H_C_T(K_TYPELESS_STRING_HL,           I"K_typeless_string")
		H_C_T(RUCKSACK_CLASS_HL,              I"RUCKSACK_CLASS")
	H_END

	H_BEGIN(HierarchyLocations::local_submodule(kinds))
		H_BEGIN_AP(KIND_HAP,                  I"kind", I"_kind")
			H_C_U(KIND_NAME_METADATA_HL,      I"^name")
			H_C_G(KIND_CLASS_HL,              I"K")
			H_C_G(KIND_HL,                    I"KD")
			H_C_I(WEAK_ID_HL)
			H_C_I(ICOUNT_HL)
			H_C_I(ILIST_HL)
			H_C_U(DEFAULT_VALUE_HL,           I"default_value")
			H_F_U(DECREMENT_FN_HL,            I"decrement_fn")
			H_F_U(INCREMENT_FN_HL,            I"increment_fn")
			H_F_U(PRINT_FN_HL,                I"print_fn")
			H_F_G(PRINT_DASH_FN_HL,           I"print_fn", I"E")
			H_F_U(RANGER_FN_HL,               I"ranger_fn")
			H_F_U(DEFAULT_CLOSURE_FN_HL,      I"default_closure_fn")
			H_F_U(GPR_FN_HL,                  I"gpr_fn")
			H_F_U(INSTANCE_GPR_FN_HL,         I"instance_gpr_fn")
			H_C_U(INSTANCE_LIST_HL,           I"instance_list")
			H_C_S(FIRST_INSTANCE_HL,          I"_First")
			H_C_S(NEXT_INSTANCE_HL,           I"_Next")
			H_C_T(COUNT_INSTANCE_1_HL,        I"IK1_Count")
			H_C_T(COUNT_INSTANCE_2_HL,        I"IK2_Count")
			H_C_T(COUNT_INSTANCE_3_HL,        I"IK3_Count")
			H_C_T(COUNT_INSTANCE_4_HL,        I"IK4_Count")
			H_C_T(COUNT_INSTANCE_5_HL,        I"IK5_Count")
			H_C_T(COUNT_INSTANCE_6_HL,        I"IK6_Count")
			H_C_T(COUNT_INSTANCE_7_HL,        I"IK7_Count")
			H_C_T(COUNT_INSTANCE_8_HL,        I"IK8_Count")
			H_C_T(COUNT_INSTANCE_9_HL,        I"IK9_Count")
			H_C_T(COUNT_INSTANCE_10_HL,       I"IK10_Count")
			H_C_S(COUNT_INSTANCE_HL,          I"_Count")
			H_BEGIN_AP(KIND_INLINE_PROPERTIES_HAP, I"inline_property", I"_inline_property")
				H_C_U(KIND_INLINE_PROPERTY_HL, I"inline")
			H_END
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, kinds))
		H_C_T(BASE_KIND_HWM_HL,               I"BASE_KIND_HWM")
		H_F_T(DEFAULTVALUEOFKOV_HL,           I"defaultvalue_fn", I"DefaultValueOfKOV")
		H_F_T(DEFAULTVALUEFINDER_HL,          I"defaultvaluefinder_fn", I"DefaultValueFinder")
		H_F_T(PRINTKINDVALUEPAIR_HL,          I"printkindvaluepair_fn", I"PrintKindValuePair")
		H_F_T(KOVCOMPARISONFUNCTION_HL,       I"comparison_fn", I"KOVComparisonFunction")
		H_F_T(KOVDOMAINSIZE_HL,               I"domainsize_fn", I"KOVDomainSize")
		H_F_T(KOVISBLOCKVALUE_HL,             I"blockvalue_fn", I"KOVIsBlockValue")
		H_F_T(I7_KIND_NAME_HL,                I"printkindname_fn", I"I7_Kind_Name")
		H_F_T(KOVSUPPORTFUNCTION_HL,          I"support_fn", I"KOVSupportFunction")
		H_F_T(SHOWMEDETAILS_HL,               I"showmedetails_fn", I"ShowMeDetails")
	H_END

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

	H_BEGIN(HierarchyLocations::local_submodule(phrases))
		H_BEGIN_AP(PHRASES_HAP,               I"phrase", I"_to_phrase")
			H_BEGIN_AP(CLOSURES_HAP,          I"closure", I"_closure")
				H_C_U(CLOSURE_DATA_HL,        I"closure_data")
			H_END
			H_BEGIN_AP(REQUESTS_HAP,          I"request", I"_request")
				H_F_U(PHRASE_FN_HL,           I"phrase_fn")
			H_END
		H_END
	H_END

	H_BEGIN(HierarchyLocations::any_enclosure())
		H_BEGIN_AP(LABEL_STORAGES_HAP,        I"label_storage", I"_label_storage")
			H_C_U(LABEL_ASSOCIATED_STORAGE_HL, I"label_associated_storage")
		H_END
	H_END

@h Properties.

@e PROPERTIES_HAP
@e PROPERTY_NAME_METADATA_HL
@e PROPERTY_HL
@e EITHER_OR_GPR_FN_HL

@e CCOUNT_PROPERTY_HL

@<Establish properties@> =
	submodule_identity *properties = Packaging::register_submodule(I"properties");

	H_BEGIN(HierarchyLocations::local_submodule(properties))
		H_BEGIN_AP(PROPERTIES_HAP,            I"property", I"_property")
			H_C_U(PROPERTY_NAME_METADATA_HL,  I"^name")
			H_C_T(PROPERTY_HL,                I"P")
			H_F_G(EITHER_OR_GPR_FN_HL,        I"either_or_GPR_fn", I"PRN_PN")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, properties))
		H_C_T(CCOUNT_PROPERTY_HL,             I"CCOUNT_PROPERTY")
	H_END

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

	H_BEGIN(HierarchyLocations::generic_submodule(I, relations))
		H_C_T(RELS_ASSERT_FALSE_HL,           I"RELS_ASSERT_FALSE")
		H_C_T(RELS_ASSERT_TRUE_HL,            I"RELS_ASSERT_TRUE")
		H_C_T(RELS_EQUIVALENCE_HL,            I"RELS_EQUIVALENCE")
		H_C_T(RELS_LIST_HL,                   I"RELS_LIST")
		H_C_T(RELS_LOOKUP_ALL_X_HL,           I"RELS_LOOKUP_ALL_X")
		H_C_T(RELS_LOOKUP_ALL_Y_HL,           I"RELS_LOOKUP_ALL_Y")
		H_C_T(RELS_LOOKUP_ANY_HL,             I"RELS_LOOKUP_ANY")
		H_C_T(RELS_ROUTE_FIND_COUNT_HL,       I"RELS_ROUTE_FIND_COUNT")
		H_C_T(RELS_ROUTE_FIND_HL,             I"RELS_ROUTE_FIND")
		H_C_T(RELS_SHOW_HL,                   I"RELS_SHOW")
		H_C_T(RELS_SYMMETRIC_HL,              I"RELS_SYMMETRIC")
		H_C_T(RELS_TEST_HL,                   I"RELS_TEST")
		H_C_T(RELS_X_UNIQUE_HL,               I"RELS_X_UNIQUE")
		H_C_T(RELS_Y_UNIQUE_HL,               I"RELS_Y_UNIQUE")
		H_C_T(REL_BLOCK_HEADER_HL,            I"REL_BLOCK_HEADER")
		H_C_T(TTF_SUM_HL,                     I"TTF_sum")
		H_C_T(MEANINGLESS_RR_HL,              I"MEANINGLESS_RR")
	H_END

	H_BEGIN(HierarchyLocations::local_submodule(relations))
		H_BEGIN_AP(RELATIONS_HAP,             I"relation", I"_relation")
			H_C_G(RELATION_RECORD_HL,         I"Rel_Record")
			H_C_U(BITMAP_HL,                  I"as_constant")
			H_C_U(ABILITIES_HL,               I"abilities")
			H_C_U(ROUTE_CACHE_HL,             I"route_cache")
			H_F_U(HANDLER_FN_HL,              I"handler_fn")
			H_F_U(RELATION_INITIALISER_FN_HL, I"relation_initialiser_fn")
			H_F_U(GUARD_F0_FN_HL,             I"guard_f0_fn")
			H_F_U(GUARD_F1_FN_HL,             I"guard_f1_fn")
			H_F_U(GUARD_TEST_FN_HL,           I"guard_test_fn")
			H_F_U(GUARD_MAKE_TRUE_FN_HL,      I"guard_make_true_fn")
			H_F_U(GUARD_MAKE_FALSE_INAME_HL,  I"guard_make_false_iname")
			H_F_U(RELATION_FN_HL,             I"relation_fn")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, relations))
		H_F_T(CREATEDYNAMICRELATIONS_HL,      I"creator_fn", I"CreateDynamicRelations")
		H_C_T(CCOUNT_BINARY_PREDICATE_HL,     I"CCOUNT_BINARY_PREDICATE")
		H_F_T(ITERATERELATIONS_HL,            I"iterator_fn", I"IterateRelations")
		H_F_T(RPROPERTY_HL,                   I"property_fn", I"RProperty")
	H_END

@h Rulebooks.

@e EMPTY_RULEBOOK_INAME_HL
@e RBNO4_INAME_HL
@e RBNO3_INAME_HL
@e RBNO2_INAME_HL
@e RBNO1_INAME_HL
@e RBNO0_INAME_HL

@e OUTCOMES_HAP
@e OUTCOME_NAME_METADATA_HL
@e OUTCOME_HL
@e RULEBOOKS_HAP
@e RULEBOOK_NAME_METADATA_HL
@e RULEBOOK_PNAME_METADATA_HL
@e RULEBOOK_VARC_METADATA_HL
@e RULEBOOK_RUN_FN_METADATA_HL
@e RULEBOOK_ID_HL
@e RUN_FN_HL
@e RULEBOOK_STV_CREATOR_FN_HL

@e NUMBER_RULEBOOKS_CREATED_HL
@e RULEBOOK_VAR_CREATORS_HL
@e SLOW_LOOKUP_HL
@e RULEBOOKS_ARRAY_HL
@e RULEBOOKNAMES_HL

@<Establish rulebooks@> =
	submodule_identity *rulebooks = Packaging::register_submodule(I"rulebooks");

	H_BEGIN(HierarchyLocations::generic_submodule(I, rulebooks))
		H_F_T(EMPTY_RULEBOOK_INAME_HL,        I"empty_fn", I"EMPTY_RULEBOOK")
		H_C_U(RBNO4_INAME_HL,                 I"RBNO4_OUTCOME")
		H_C_U(RBNO3_INAME_HL,                 I"RBNO3_OUTCOME")
		H_C_U(RBNO2_INAME_HL,                 I"RBNO2_OUTCOME")
		H_C_U(RBNO1_INAME_HL,                 I"RBNO1_OUTCOME")
		H_C_U(RBNO0_INAME_HL,                 I"RBNO0_OUTCOME")
	H_END

	H_BEGIN(HierarchyLocations::local_submodule(rulebooks))
		H_BEGIN_AP(OUTCOMES_HAP,              I"rulebook_outcome", I"_outcome")
			H_C_U(OUTCOME_NAME_METADATA_HL,   I"^name")
			H_C_U(OUTCOME_HL,                 I"outcome")
		H_END
		H_BEGIN_AP(RULEBOOKS_HAP,             I"rulebook", I"_rulebook")
			H_C_U(RULEBOOK_NAME_METADATA_HL,  I"^name")
			H_C_U(RULEBOOK_PNAME_METADATA_HL, I"^printed_name")
			H_C_U(RULEBOOK_RUN_FN_METADATA_HL, I"^run_fn")
			H_C_U(RULEBOOK_VARC_METADATA_HL,  I"^var_creator")
			H_C_U(RULEBOOK_ID_HL,             I"rulebook_id")
			H_F_U(RUN_FN_HL,                  I"run_fn")
			H_F_U(RULEBOOK_STV_CREATOR_FN_HL, I"stv_creator_fn")
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, rulebooks))
		H_C_T(NUMBER_RULEBOOKS_CREATED_HL,    I"NUMBER_RULEBOOKS_CREATED")
		H_C_T(RULEBOOK_VAR_CREATORS_HL,       I"rulebook_var_creators")
		H_F_T(SLOW_LOOKUP_HL,                 I"slow_lookup_fn", I"MStack_GetRBVarCreator")
		H_C_T(RULEBOOKS_ARRAY_HL,             I"rulebooks_array")
		H_C_T(RULEBOOKNAMES_HL,               I"RulebookNames")
	H_END

@h Rules.

@e RULES_HAP
@e RULE_NAME_METADATA_HL
@e RULE_PNAME_METADATA_HL
@e RULE_VALUE_METADATA_HL
@e SHELL_FN_HL
@e RULE_FN_HL
@e EXTERIOR_RULE_HL
@e RESPONDER_FN_HL
@e RESPONSES_HAP
@e AS_CONSTANT_HL
@e AS_BLOCK_CONSTANT_HL
@e LAUNCHER_HL
@e RESP_VALUE_METADATA_HL
@e RULE_METADATA_HL
@e MARKER_METADATA_HL
@e GROUP_HL

@e RULEPRINTINGRULE_HL
@e RESPONSETEXTS_HL
@e NO_RESPONSES_HL
@e RESPONSEDIVISIONS_HL

@<Establish rules@> =
	submodule_identity *rules = Packaging::register_submodule(I"rules");

	H_BEGIN(HierarchyLocations::local_submodule(rules))
		H_BEGIN_AP(RULES_HAP,                 I"rule", I"_rule")
			H_C_U(RULE_NAME_METADATA_HL,      I"^name")
			H_C_U(RULE_PNAME_METADATA_HL,     I"^printed_name")
			H_C_U(RULE_VALUE_METADATA_HL,     I"^value")
			H_F_U(SHELL_FN_HL,                I"shell_fn")
			H_F_U(RULE_FN_HL,                 I"rule_fn")
			H_C_U(EXTERIOR_RULE_HL,           I"exterior_rule")
			H_F_S(RESPONDER_FN_HL,            I"responder_fn", I"M")
			H_BEGIN_AP(RESPONSES_HAP,         I"response", I"_response")
				H_C_U(RESP_VALUE_METADATA_HL, I"^value")
				H_C_U(RULE_METADATA_HL,       I"^rule")
				H_C_U(MARKER_METADATA_HL,     I"^marker")
				H_C_U(GROUP_HL,               I"^group")
				H_C_U(AS_CONSTANT_HL,         I"response_id")
				H_C_U(AS_BLOCK_CONSTANT_HL,   I"as_block_constant")
				H_F_U(LAUNCHER_HL,            I"launcher")
			H_END
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, rules))
		H_C_T(RESPONSEDIVISIONS_HL,           I"ResponseDivisions")
		H_C_T(RESPONSETEXTS_HL,               I"ResponseTexts")
		H_C_T(NO_RESPONSES_HL,                I"NO_RESPONSES")
		H_F_T(RULEPRINTINGRULE_HL,            I"print_fn", I"RulePrintingRule")
	H_END

@h Tables.

@e TABLES_HAP
@e TABLE_NAME_METADATA_HL
@e TABLE_DATA_HL
@e TABLE_COLUMNS_HAP
@e COLUMN_DATA_HL

@e TC_KOV_HL
@e TB_BLANKS_HL

@<Establish tables@> =
	submodule_identity *tables = Packaging::register_submodule(I"tables");

	H_BEGIN(HierarchyLocations::local_submodule(tables))
		H_BEGIN_AP(TABLES_HAP,                I"table", I"_table")
			H_C_U(TABLE_NAME_METADATA_HL,     I"^name")
			H_C_U(TABLE_DATA_HL,              I"table_data")
			H_BEGIN_AP(TABLE_COLUMNS_HAP,     I"table_column", I"_table_column")
				H_C_U(COLUMN_DATA_HL,         I"column_data")
			H_END
		H_END
	H_END

	H_BEGIN(HierarchyLocations::synoptic_submodule(I, tables))
		H_C_T(TB_BLANKS_HL,                   I"TB_Blanks")
		H_F_T(TC_KOV_HL,                      I"weak_kind_ID_of_column_entry_fn", I"TC_KOV")
	H_END

@h Variables.

@e VARIABLES_HAP
@e VARIABLE_NAME_METADATA_HL
@e VARIABLE_HL

@<Establish variables@> =
	submodule_identity *variables = Packaging::register_submodule(I"variables");

	H_BEGIN(HierarchyLocations::local_submodule(variables))
		H_BEGIN_AP(VARIABLES_HAP,             I"variable", I"_variable")
			H_C_U(VARIABLE_NAME_METADATA_HL,  I"^name")
			H_C_G(VARIABLE_HL,                I"V")
		H_END
	H_END

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
@e BOX_FLAG_HL
@e BOX_QUOTATION_FN_HL
@e GROUPS_TOGETHER_HAP
@e GROUP_TOGETHER_FN_HL

@<Establish enclosed matter@> =
	H_BEGIN(HierarchyLocations::any_enclosure())
		H_BEGIN_AP(LITERALS_HAP,              I"literal", I"_literal")
			H_C_U(TEXT_LITERAL_HL,            I"text")
			H_C_U(LIST_LITERAL_HL,            I"list")
			H_C_U(TEXT_SUBSTITUTION_HL,       I"ts_array")
			H_F_U(TEXT_SUBSTITUTION_FN_HL,    I"ts_fn")
		H_END
		H_BEGIN_AP(PROPOSITIONS_HAP,          I"proposition", I"_proposition")
			H_F_U(PROPOSITION_HL,             I"prop")
		H_END
		H_BEGIN_AP(BLOCK_CONSTANTS_HAP,       I"block_constant", I"_block_constant")
			H_C_U(BLOCK_CONSTANT_HL,          I"bc")
		H_END
		H_BEGIN_AP(BOX_QUOTATIONS_HAP,        I"block_constant", I"_box_quotation")
			H_C_U(BOX_FLAG_HL,                I"quotation_flag")
			H_F_U(BOX_QUOTATION_FN_HL,        I"quotation_fn")
		H_END
		H_BEGIN_AP(GROUPS_TOGETHER_HAP,       I"group_together", I"_group_together")
			H_F_U(GROUP_TOGETHER_FN_HL,       I"group_together_fn")
		H_END
		H_C_U(RTP_HL,                         I"rtp")
	H_END

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

@<The rest@> =
	H_BEGIN(HierarchyLocations::this_exotic_package(K_OBJECT_XPACKAGE))
		H_C_T(CAPSHORTNAME_HL,                I"cap_short_name")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_NUMBER_XPACKAGE))
		H_F_T(DECIMAL_TOKEN_INNER_HL,         I"gpr_fn", I"DECIMAL_TOKEN_INNER")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_TIME_XPACKAGE))
		H_F_T(TIME_TOKEN_INNER_HL,            I"gpr_fn", I"TIME_TOKEN_INNER")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_TRUTH_STATE_XPACKAGE))
		H_F_T(TRUTH_STATE_TOKEN_INNER_HL,     I"gpr_fn", I"TRUTH_STATE_TOKEN_INNER")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_TABLE_XPACKAGE))
		H_C_T(TABLEOFTABLES_HL,               I"TableOfTables")
		H_F_T(PRINT_TABLE_HL,                 I"print_fn", I"PrintTableName")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_VERB_XPACKAGE))
		H_C_T(TABLEOFVERBS_HL,                I"TableOfVerbs")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_FIGURE_NAME_XPACKAGE))
		H_C_T(RESOURCEIDSOFFIGURES_HL,        I"ResourceIDsOfFigures")
		H_F_T(PRINT_FIGURE_NAME_HL,           I"print_fn", I"PrintFigureName")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_SOUND_NAME_XPACKAGE))
		H_C_T(RESOURCEIDSOFSOUNDS_HL,         I"ResourceIDsOfSounds")
		H_F_T(PRINT_SOUND_NAME_HL,            I"print_fn", I"PrintSoundName")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_USE_OPTION_XPACKAGE))
		H_C_T(NO_USE_OPTIONS_HL,              I"NO_USE_OPTIONS")
		H_F_T(TESTUSEOPTION_HL,               I"test_fn", I"TestUseOption")
		H_F_T(PRINT_USE_OPTION_HL,            I"print_fn", I"PrintUseOption")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(V_COMMAND_PROMPT_XPACKAGE))
		H_F_T(COMMANDPROMPTTEXT_HL,           I"command_prompt_text_fn", I"CommandPromptText")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_EXTERNAL_FILE_XPACKAGE))
		H_C_T(NO_EXTERNAL_FILES_HL,           I"NO_EXTERNAL_FILES")
		H_C_T(TABLEOFEXTERNALFILES_HL,        I"TableOfExternalFiles")
		H_F_T(PRINT_EXTERNAL_FILE_NAME_HL,    I"print_fn", I"PrintExternalFileName")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_RULEBOOK_OUTCOME_XPACKAGE))
		H_F_T(PRINT_RULEBOOK_OUTCOME_HL,      I"print_fn", I"RulebookOutcomePrintingRule")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_RESPONSE_XPACKAGE))
		H_F_T(PRINT_RESPONSE_HL,              I"print_fn", I"PrintResponse")
	H_END

	H_BEGIN(HierarchyLocations::this_exotic_package(K_SCENE_XPACKAGE))
		H_F_T(PRINT_SCENE_HL,                 I"print_fn", I"PrintSceneName")
	H_END

@h Veneer-defined symbols.
The "veneer" in the Inform 6 compiler consists of a few constants and functions
automatically created by the compiler itself, and which therefore have no source
code producing them. For example, |WORDSIZE| is a constant which gives the size
of a word of data in bytes -- for Inform 6, this is always either 2 or 4.

The Inform compiler only needs to refer to a few of these symbols directly,
and here they are. For their meanings, see the Inform 6 Technical Manual.

@e SELF_HL
@e DEBUG_HL
@e TARGET_ZCODE_HL
@e TARGET_GLULX_HL
@e DICT_WORD_SIZE_HL
@e WORDSIZE_HL
@e INDIV_PROP_START_HL

@<Establish veneer resources@> =
	H_BEGIN(HierarchyLocations::the_veneer(I))
		H_C_T(SELF_HL,                        I"self")
		H_C_T(DEBUG_HL,                       I"DEBUG")
		H_C_T(TARGET_ZCODE_HL,                I"TARGET_ZCODE")
		H_C_T(TARGET_GLULX_HL,                I"TARGET_GLULX")
		H_C_T(DICT_WORD_SIZE_HL,              I"DICT_WORD_SIZE")
		H_C_T(WORDSIZE_HL,                    I"WORDSIZE")
		H_C_T(INDIV_PROP_START_HL,            I"INDIV_PROP_START")
	H_END

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
	H_BEGIN(HierarchyLocations::plug())
		H_C_T(THESAME_HL,                          I"##TheSame")
		H_C_T(PLURALFOUND_HL,                      I"##PluralFound")
		H_C_T(THEDARK_HL,                          I"thedark")
		H_C_T(ACT_REQUESTER_HL,                    I"act_requester")
		H_C_T(ACTION_HL,                           I"action")
		H_C_T(ACTIONCURRENTLYHAPPENINGFLAG_HL,     I"ActionCurrentlyHappeningFlag")
		H_C_T(ACTOR_HL,                            I"actor")
		H_C_T(ACTOR_LOCATION_HL,                   I"actor_location")
		H_C_T(ADJUSTPARAGRAPHPOINT_HL,             I"AdjustParagraphPoint")
		H_C_T(ALLOWINSHOWME_HL,                    I"AllowInShowme")
		H_C_T(ANIMATE_HL,                          I"animate")
		H_C_T(ARGUMENTTYPEFAILED_HL,               I"ArgumentTypeFailed")
		H_C_T(ARTICLEDESCRIPTORS_HL,               I"ArticleDescriptors")
		H_C_T(AUXF_MAGIC_VALUE_HL,                 I"AUXF_MAGIC_VALUE")
		H_C_T(AUXF_STATUS_IS_CLOSED_HL,            I"AUXF_STATUS_IS_CLOSED")
		H_C_T(BLKVALUECOPY_HL,                     I"BlkValueCopy")
		H_C_T(BLKVALUECOPYAZ_HL,                   I"BlkValueCopyAZ")
		H_C_T(BLKVALUECREATE_HL,                   I"BlkValueCreate")
		H_C_T(BLKVALUECREATEONSTACK_HL,            I"BlkValueCreateOnStack")
		H_C_T(BLKVALUEERROR_HL,                    I"BlkValueError")
		H_C_T(BLKVALUEFREE_HL,                     I"BlkValueFree")
		H_C_T(BLKVALUEFREEONSTACK_HL,              I"BlkValueFreeOnStack")
		H_C_T(BLKVALUEWRITE_HL,                    I"BlkValueWrite")
		H_C_T(C_STYLE_HL,                          I"c_style")
		H_C_T(CHECKKINDRETURNED_HL,                I"CheckKindReturned")
		H_C_T(CLEARPARAGRAPHING_HL,                I"ClearParagraphing")
		H_C_T(COMPONENT_CHILD_HL,                  I"component_child")
		H_C_T(COMPONENT_PARENT_HL,                 I"component_parent")
		H_C_T(COMPONENT_SIBLING_HL,                I"component_sibling")
		H_C_T(CONSTANT_PACKED_TEXT_STORAGE_HL,     I"CONSTANT_PACKED_TEXT_STORAGE")
		H_C_T(CONSTANT_PERISHABLE_TEXT_STORAGE_HL, I"CONSTANT_PERISHABLE_TEXT_STORAGE")
		H_C_T(CONSULT_FROM_HL,                     I"consult_from")
		H_C_T(CONSULT_WORDS_HL,                    I"consult_words")
		H_C_T(CONTAINER_HL,                        I"container")
		H_C_T(CUBEROOT_HL,                         I"CubeRoot")
		H_C_T(DA_NAME_HL,                          I"DA_Name")
		H_C_T(DB_RULE_HL,                          I"DB_Rule")
		H_C_T(DEADFLAG_HL,                         I"deadflag")
		H_C_T(DEBUG_RULES_HL,                      I"debug_rules")
		H_C_T(DEBUG_SCENES_HL,                     I"debug_scenes")
		H_C_T(DECIMALNUMBER_HL,                    I"DecimalNumber")
		H_C_T(DETECTPLURALWORD_HL,                 I"DetectPluralWord")
		H_C_T(DIGITTOVALUE_HL,                     I"DigitToValue")
		H_C_T(DIVIDEPARAGRAPHPOINT_HL,             I"DivideParagraphPoint")
		H_C_T(DOUBLEHASHSETRELATIONHANDLER_HL,     I"DoubleHashSetRelationHandler")
		H_C_T(DURINGSCENEMATCHING_HL,              I"DuringSceneMatching")
		H_C_T(ELEMENTARY_TT_HL,                    I"ELEMENTARY_TT")
		H_C_T(EMPTY_TABLE_HL,                      I"TheEmptyTable")
		H_C_T(EMPTY_TEXT_PACKED_HL,                I"EMPTY_TEXT_PACKED")
		H_C_T(EMPTY_TEXT_VALUE_HL,                 I"EMPTY_TEXT_VALUE")
		H_C_T(EMPTYRELATIONHANDLER_HL,             I"EmptyRelationHandler")
		H_C_T(ENGLISH_BIT_HL,                      I"ENGLISH_BIT")
		H_C_T(ETYPE_HL,                            I"etype")
		H_C_T(EXISTSTABLELOOKUPCORR_HL,            I"ExistsTableLookUpCorr")
		H_C_T(EXISTSTABLELOOKUPENTRY_HL,           I"ExistsTableLookUpEntry")
		H_C_T(EXISTSTABLEROWCORR_HL,               I"ExistsTableRowCorr")
		H_C_T(FLOATPARSE_HL,                       I"FloatParse")
		H_C_T(FOLLOWRULEBOOK_HL,                   I"FollowRulebook")
		H_C_T(formal_par0_HL,                      I"formal_par0")
		H_C_T(formal_par1_HL,                      I"formal_par1")
		H_C_T(formal_par2_HL,                      I"formal_par2")
		H_C_T(formal_par3_HL,                      I"formal_par3")
		H_C_T(formal_par4_HL,                      I"formal_par4")
		H_C_T(formal_par5_HL,                      I"formal_par5")
		H_C_T(formal_par6_HL,                      I"formal_par6")
		H_C_T(formal_par7_HL,                      I"formal_par7")
		H_C_T(FORMAL_RV_HL,                        I"formal_rv")
		H_C_T(FOUND_EVERYWHERE_HL,                 I"FoundEverywhere")
		H_C_T(GENERATERANDOMNUMBER_HL,             I"GenerateRandomNumber")
		H_C_T(GENERICVERBSUB_HL,                   I"GenericVerbSub")
		H_C_T(GETGNAOFOBJECT_HL,                   I"GetGNAOfObject")
		H_C_T(GPR_FAIL_HL,                         I"GPR_FAIL")
		H_C_T(GPR_NUMBER_HL,                       I"GPR_NUMBER")
		H_C_T(GPR_PREPOSITION_HL,                  I"GPR_PREPOSITION")
		H_C_T(GPR_TT_HL,                           I"GPR_TT")
		H_C_T(GPROPERTY_HL,                        I"GProperty")
		H_C_T(HASHLISTRELATIONHANDLER_HL,          I"HashListRelationHandler")
		H_C_T(I7SFRAME_HL,                         I"I7SFRAME")
		H_C_T(INDENT_BIT_HL,                       I"INDENT_BIT")
		H_C_T(INP1_HL,                             I"inp1")
		H_C_T(INP2_HL,                             I"inp2")
		H_C_T(INTEGERDIVIDE_HL,                    I"IntegerDivide")
		H_C_T(INTEGERREMAINDER_HL,                 I"IntegerRemainder")
		H_C_T(INVENTORY_STAGE_HL,                  I"inventory_stage")
		H_C_T(KEEP_SILENT_HL,                      I"keep_silent")
		H_C_T(KINDATOMIC_HL,                       I"KindAtomic")
		H_C_T(LATEST_RULE_RESULT_HL,               I"latest_rule_result")
		H_C_T(LIST_ITEM_BASE_HL,                   I"LIST_ITEM_BASE")
		H_C_T(LIST_ITEM_KOV_F_HL,                  I"LIST_ITEM_KOV_F")
		H_C_T(LIST_OF_TY_DESC_HL,                  I"LIST_OF_TY_Desc")
		H_C_T(LIST_OF_TY_GETITEM_HL,               I"LIST_OF_TY_GetItem")
		H_C_T(LIST_OF_TY_GETLENGTH_HL,             I"LIST_OF_TY_GetLength")
		H_C_T(LIST_OF_TY_INSERTITEM_HL,            I"LIST_OF_TY_InsertItem")
		H_C_T(LIST_OF_TY_SAY_HL,                   I"LIST_OF_TY_Say")
		H_C_T(LIST_OF_TY_SETLENGTH_HL,             I"LIST_OF_TY_SetLength")
		H_C_T(LOCATION_HL,                         I"location")
		H_C_T(LOCATIONOF_HL,                       I"LocationOf")
		H_C_T(LOOPOVERSCOPE_HL,                    I"LoopOverScope")
		H_C_T(LOS_RV_HL,                           I"los_rv")
		H_C_T(MSTACK_HL,                           I"MStack")
		H_C_T(MSTVO_HL,                            I"MstVO")
		H_C_T(MSTVON_HL,                           I"MstVON")
		H_C_T(NAME_HL,                             I"name")
		H_C_T(NEWLINE_BIT_HL,                      I"NEWLINE_BIT")
		H_C_T(NEXTBEST_ETYPE_HL,                   I"nextbest_etype")
		H_C_T(NEXTWORDSTOPPED_HL,                  I"NextWordStopped")
		H_C_T(NOARTICLE_BIT_HL,                    I"NOARTICLE_BIT")
		H_C_T(NOTINCONTEXTPE_HL,                   I"NOTINCONTEXT_PE")
		H_C_T(NOUN_HL,                             I"noun")
		H_C_T(NUMBER_TY_ABS_HL,                    I"NUMBER_TY_Abs")
		H_C_T(NUMBER_TY_TO_REAL_NUMBER_TY_HL,      I"NUMBER_TY_to_REAL_NUMBER_TY")
		H_C_T(NUMBER_TY_TO_TIME_TY_HL,             I"NUMBER_TY_to_TIME_TY")
		H_C_T(OTOVRELROUTETO_HL,                   I"OtoVRelRouteTo")
		H_C_T(PACKED_TEXT_STORAGE_HL,              I"PACKED_TEXT_STORAGE")
		H_C_T(PARACONTENT_HL,                      I"ParaContent")
		H_C_T(PARAMETER_VALUE_HL,                  I"parameter_value")
		H_C_T(PARSED_NUMBER_HL,                    I"parsed_number")
		H_C_T(PARSER_ACTION_HL,                    I"parser_action")
		H_C_T(PARSER_ONE_HL,                       I"parser_one")
		H_C_T(PARSER_TRACE_HL,                     I"parser_trace")
		H_C_T(PARSER_TWO_HL,                       I"parser_two")
		H_C_T(PARSERERROR_HL,                      I"ParserError")
		H_C_T(PARSETOKENSTOPPED_HL,                I"ParseTokenStopped")
		H_C_T(PAST_CHRONOLOGICAL_RECORD_HL,        I"past_chronological_record")
		H_C_T(PLACEINSCOPE_HL,                     I"PlaceInScope")
		H_C_T(PLAYER_HL,                           I"player")
		H_C_T(PNTOVP_HL,                           I"PNToVP")
		H_C_T(PRESENT_CHRONOLOGICAL_RECORD_HL,     I"present_chronological_record")
		H_C_T(PRINTORRUN_HL,                       I"PrintOrRun")
		H_C_T(PRIOR_NAMED_LIST_HL,                 I"prior_named_list")
		H_C_T(PRIOR_NAMED_LIST_GENDER_HL,          I"prior_named_list_gender")
		H_C_T(PRIOR_NAMED_NOUN_HL,                 I"prior_named_noun")
		H_C_T(PROPERTY_LOOP_SIGN_HL,               I"property_loop_sign")
		H_C_T(PROPERTY_TO_BE_TOTALLED_HL,          I"property_to_be_totalled")
		H_C_T(REAL_LOCATION_HL,                    I"real_location")
		H_C_T(REAL_NUMBER_TY_ABS_HL,               I"REAL_NUMBER_TY_Abs")
		H_C_T(REAL_NUMBER_TY_APPROXIMATE_HL,       I"REAL_NUMBER_TY_Approximate")
		H_C_T(REAL_NUMBER_TY_COMPARE_HL,           I"REAL_NUMBER_TY_Compare")
		H_C_T(REAL_NUMBER_TY_CUBE_ROOT_HL,         I"REAL_NUMBER_TY_Cube_Root")
		H_C_T(REAL_NUMBER_TY_DIVIDE_HL,            I"REAL_NUMBER_TY_Divide")
		H_C_T(REAL_NUMBER_TY_MINUS_HL,             I"REAL_NUMBER_TY_Minus")
		H_C_T(REAL_NUMBER_TY_NAN_HL,               I"REAL_NUMBER_TY_Nan")
		H_C_T(REAL_NUMBER_TY_NEGATE_HL,            I"REAL_NUMBER_TY_Negate")
		H_C_T(REAL_NUMBER_TY_PLUS_HL,              I"REAL_NUMBER_TY_Plus")
		H_C_T(REAL_NUMBER_TY_POW_HL,               I"REAL_NUMBER_TY_Pow")
		H_C_T(REAL_NUMBER_TY_REMAINDER_HL,         I"REAL_NUMBER_TY_Remainder")
		H_C_T(REAL_NUMBER_TY_ROOT_HL,              I"REAL_NUMBER_TY_Root")
		H_C_T(REAL_NUMBER_TY_SAY_HL,               I"REAL_NUMBER_TY_Say")
		H_C_T(REAL_NUMBER_TY_TIMES_HL,             I"REAL_NUMBER_TY_Times")
		H_C_T(REAL_NUMBER_TY_TO_NUMBER_TY_HL,      I"REAL_NUMBER_TY_to_NUMBER_TY")
		H_C_T(REASON_THE_ACTION_FAILED_HL,         I"reason_the_action_failed")
		H_C_T(RELATION_EMPTYEQUIV_HL,              I"Relation_EmptyEquiv")
		H_C_T(RELATION_EMPTYOTOO_HL,               I"Relation_EmptyOtoO")
		H_C_T(RELATION_EMPTYVTOV_HL,               I"Relation_EmptyVtoV")
		H_C_T(RELATION_RSHOWOTOO_HL,               I"Relation_RShowOtoO")
		H_C_T(RELATION_SHOWEQUIV_HL,               I"Relation_ShowEquiv")
		H_C_T(RELATION_SHOWOTOO_HL,                I"Relation_ShowOtoO")
		H_C_T(RELATION_SHOWVTOV_HL,                I"Relation_ShowVtoV")
		H_C_T(RELATION_TY_EQUIVALENCEADJECTIVE_HL, I"RELATION_TY_EquivalenceAdjective")
		H_C_T(RELATION_TY_NAME_HL,                 I"RELATION_TY_Name")
		H_C_T(RELATION_TY_OTOOADJECTIVE_HL,        I"RELATION_TY_OToOAdjective")
		H_C_T(RELATION_TY_OTOVADJECTIVE_HL,        I"RELATION_TY_OToVAdjective")
		H_C_T(RELATION_TY_SYMMETRICADJECTIVE_HL,   I"RELATION_TY_SymmetricAdjective")
		H_C_T(RELATION_TY_VTOOADJECTIVE_HL,        I"RELATION_TY_VToOAdjective")
		H_C_T(RELATIONTEST_HL,                     I"RelationTest")
		H_C_T(RELFOLLOWVECTOR_HL,                  I"RelFollowVector")
		H_C_T(RELS_EMPTY_HL,                       I"RELS_EMPTY")
		H_C_T(RESPONSEVIAACTIVITY_HL,              I"ResponseViaActivity")
		H_C_T(RLANY_CAN_GET_X_HL,                  I"RLANY_CAN_GET_X")
		H_C_T(RLANY_CAN_GET_Y_HL,                  I"RLANY_CAN_GET_Y")
		H_C_T(RLANY_GET_X_HL,                      I"RLANY_GET_X")
		H_C_T(RLIST_ALL_X_HL,                      I"RLIST_ALL_X")
		H_C_T(RLIST_ALL_Y_HL,                      I"RLIST_ALL_Y")
		H_C_T(RLNGETF_HL,                          I"RlnGetF")
		H_C_T(ROUNDOFFVALUE_HL,                    I"RoundOffValue")
		H_C_T(ROUTINEFILTER_TT_HL,                 I"ROUTINE_FILTER_TT")
		H_C_T(RR_STORAGE_HL,                       I"RR_STORAGE")
		H_C_T(RTP_RELKINDVIOLATION_HL,             I"RTP_RELKINDVIOLATION")
		H_C_T(RTP_RELMINIMAL_HL,                   I"RTP_RELMINIMAL")
		H_C_T(RULEBOOKFAILS_HL,                    I"RulebookFails")
		H_C_T(RULEBOOKPARBREAK_HL,                 I"RulebookParBreak")
		H_C_T(RULEBOOKSUCCEEDS_HL,                 I"RulebookSucceeds")
		H_C_T(RUNTIMEPROBLEM_HL,                   I"RunTimeProblem")
		H_C_T(SAY__N_HL,                           I"say__n")
		H_C_T(SAY__P_HL,                           I"say__p")
		H_C_T(SAY__PC_HL,                          I"say__pc")
		H_C_T(SCENE_ENDED_HL,                      I"scene_ended")
		H_C_T(SCENE_ENDINGS_HL,                    I"scene_endings")
		H_C_T(SCENE_LATEST_ENDING_HL,              I"scene_latest_ending")
		H_C_T(SCENE_STARTED_HL,                    I"scene_started")
		H_C_T(SCENE_STATUS_HL,                     I"scene_status")
		H_C_T(SCOPE_STAGE_HL,                      I"scope_stage")
		H_C_T(SCOPE_TT_HL,                         I"SCOPE_TT")
		H_C_T(SECOND_HL,                           I"second")
		H_C_T(SHORT_NAME_HL,                       I"short_name")
		H_C_T(SIGNEDCOMPARE_HL,                    I"SignedCompare")
		H_C_T(SPECIAL_WORD_HL,                     I"special_word")
		H_C_T(SQUAREROOT_HL,                       I"SquareRoot")
		H_C_T(STACKFRAMECREATE_HL,                 I"StackFrameCreate")
		H_C_T(STORED_ACTION_TY_CURRENT_HL,         I"STORED_ACTION_TY_Current")
		H_C_T(STORED_ACTION_TY_TRY_HL,             I"STORED_ACTION_TY_Try")
		H_C_T(STORY_TENSE_HL,                      I"story_tense")
		H_C_T(SUPPORTER_HL,                        I"supporter")
		H_C_T(SUPPRESS_SCOPE_LOOPS_HL,             I"suppress_scope_loops")
		H_C_T(SUPPRESS_TEXT_SUBSTITUTION_HL,       I"suppress_text_substitution")
		H_C_T(TABLE_NOVALUE_HL,                    I"TABLE_NOVALUE")
		H_C_T(TABLELOOKUPCORR_HL,                  I"TableLookUpCorr")
		H_C_T(TABLELOOKUPENTRY_HL,                 I"TableLookUpEntry")
		H_C_T(TESTACTIONBITMAP_HL,                 I"TestActionBitmap")
		H_C_T(TESTACTIVITY_HL,                     I"TestActivity")
		H_C_T(TESTREGIONALCONTAINMENT_HL,          I"TestRegionalContainment")
		H_C_T(TESTSCOPE_HL,                        I"TestScope")
		H_C_T(TESTSTART_HL,                        I"TestStart")
		H_C_T(TEXT_TY_COMPARE_HL,                  I"TEXT_TY_Compare")
		H_C_T(TEXT_TY_EXPANDIFPERISHABLE_HL,       I"TEXT_TY_ExpandIfPerishable")
		H_C_T(TEXT_TY_SAY_HL,                      I"TEXT_TY_Say")
		H_C_T(THE_TIME_HL,                         I"the_time")
		H_C_T(THEEMPTYTABLE_HL,                    I"TheEmptyTable")
		H_C_T(THEN1__WD_HL,                        I"THEN1__WD")
		H_C_T(TIMESACTIONHASBEENHAPPENING_HL,      I"TimesActionHasBeenHappening")
		H_C_T(TIMESACTIONHASHAPPENED_HL,           I"TimesActionHasHappened")
		H_C_T(TRYACTION_HL,                        I"TryAction")
		H_C_T(TRYGIVENOBJECT_HL,                   I"TryGivenObject")
		H_C_T(TURNSACTIONHASBEENHAPPENING_HL,      I"TurnsActionHasBeenHappening")
		H_C_T(UNDERSTAND_AS_MISTAKE_NUMBER_HL,     I"understand_as_mistake_number")
		H_C_T(UNICODE_TEMP_HL,                     I"unicode_temp")
		H_C_T(VTOORELROUTETO_HL,                   I"VtoORelRouteTo")
		H_C_T(VTOVRELROUTETO_HL,                   I"VtoVRelRouteTo")
		H_C_T(WHEN_SCENE_BEGINS_HL,                I"WHEN_SCENE_BEGINS_RB")
		H_C_T(WHEN_SCENE_ENDS_HL,                  I"WHEN_SCENE_ENDS_RB")
		H_C_T(WN_HL,                               I"wn")
		H_C_T(WORDADDRESS_HL,                      I"WordAddress")
		H_C_T(WORDINPROPERTY_HL,                   I"WordInProperty")
		H_C_T(WORDLENGTH_HL,                       I"WordLength")
	H_END

@ Heaven knows, that all seems like plenty, but there's one final case. Neptune
files inside kits -- which define built-in kinds like "number" -- need to make
reference to constants in those kits which give their default values. For
example, the "description of K" kind constructor is created by //BasicInformKit//,
and its default value compiles to the value |Prop_Falsity|. This is a function
also defined in //BasicInformKit//. But there is no id |PROP_FALSITY_HL| because
the main compiler doesn't want to hardwire this: perhaps the implementation in
the kit will change at some point, after all.

So the compiler reserves a block of location IDs to be used by default values
of kinds in kits. On demand, it then allocates these to be used; so, for
example, |Prop_Falsity| might be given |KIND_DEFAULT5_HL|.

There are only a few of these, and the absolute limit here doesn't seem
problematic right now.

@e KIND_DEFAULT1_HL
@e KIND_DEFAULT2_HL
@e KIND_DEFAULT3_HL
@e KIND_DEFAULT4_HL
@e KIND_DEFAULT5_HL
@e KIND_DEFAULT6_HL
@e KIND_DEFAULT7_HL
@e KIND_DEFAULT8_HL
@e KIND_DEFAULT9_HL
@e KIND_DEFAULT10_HL
@e KIND_DEFAULT11_HL
@e KIND_DEFAULT12_HL
@e KIND_DEFAULT13_HL
@e KIND_DEFAULT14_HL
@e KIND_DEFAULT15_HL
@e KIND_DEFAULT16_HL

@d MAX_KIND_DEFAULTS 16

=
int no_kind_defaults_used;
kind_constructor *kind_defaults_used[MAX_KIND_DEFAULTS];
int Hierarchy::kind_default(kind_constructor *con, text_stream *Inter_constant_name) {
	for (int i=0; i<no_kind_defaults_used; i++)
		if (con == kind_defaults_used[i])
			return KIND_DEFAULT1_HL + i;
	if (no_kind_defaults_used >= MAX_KIND_DEFAULTS)
		internal_error("too many Neptune file-defined kinds have default values");
	location_requirement plug = HierarchyLocations::plug();
	int hl = KIND_DEFAULT1_HL + no_kind_defaults_used;
	kind_defaults_used[no_kind_defaults_used++] = con;
	HierarchyLocations::con(Emit::tree(), hl, Inter_constant_name, plug);
	return hl;
}

@ A few of the above locations were "exotic packages", which are not really very
exotic, but which are locations not easily falling into patterns. Here they are:

=
package_request *Hierarchy::exotic_package(int x) {
	switch (x) {
		case K_OBJECT_XPACKAGE:           return Kinds::Behaviour::package(K_object);
		case K_NUMBER_XPACKAGE:           return Kinds::Behaviour::package(K_number);
		case K_TIME_XPACKAGE:             return Kinds::Behaviour::package(K_time);
		case K_TRUTH_STATE_XPACKAGE:      return Kinds::Behaviour::package(K_truth_state);
		case K_TABLE_XPACKAGE:            return Kinds::Behaviour::package(K_table);
		case K_VERB_XPACKAGE:             return Kinds::Behaviour::package(K_verb);
		case K_FIGURE_NAME_XPACKAGE:      return Kinds::Behaviour::package(K_figure_name);
		case K_SOUND_NAME_XPACKAGE:       return Kinds::Behaviour::package(K_sound_name);
		case K_USE_OPTION_XPACKAGE:       return Kinds::Behaviour::package(K_use_option);
		case K_EXTERNAL_FILE_XPACKAGE:    return Kinds::Behaviour::package(K_external_file);
		case K_RULEBOOK_OUTCOME_XPACKAGE: return Kinds::Behaviour::package(K_rulebook_outcome);
		case K_RESPONSE_XPACKAGE:         return Kinds::Behaviour::package(K_response);
		case K_SCENE_XPACKAGE:            return Kinds::Behaviour::package(K_scene);
		case V_COMMAND_PROMPT_XPACKAGE:
			return InterNames::location(
				RTVariables::iname(RTTemporaryVariables::command_prompt_variable()));
	}
	internal_error("unknown exotic package");
	return NULL;
}

@h Finding where to put things.
So, for example, |Hierarchy::find(ACTIVITY_VAR_CREATORS_HL)| returns the iname
at which this array should be placed, by calling, e.g., //EmitArrays::begin//.

=
inter_name *Hierarchy::find(int id) {
	return HierarchyLocations::find(Emit::tree(), id);
}

@ That's fine for one-off inames. But now suppose we have this:
= (text as InC)
		H_BEGIN_AP(EXTERNAL_FILES_HAP,        I"external_file", I"_external_file")
			H_C_U(FILE_HL,                    I"file")
			H_C_U(IFID_HL,                    I"ifid")
		H_END
=
...and we are compiling a file, so that we need a |FILE_HL| iname. To get that,
we call |Hierarchy::make_iname_in(FILE_HL, P)|, where |P| represents the |_external_file|
package holding it. (|P| can in turn be obtained using the functions below.)

If this is called where |P| is some other package -- i.e., not of package type
|_external_file| -- an internal error is thrown, in order to enforce the rules.

=
inter_name *Hierarchy::make_iname_in(int id, package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING,
		NULL, -1, NULL);
}

@ There are then some variations on this function. This version adds the wording |W|
to the name, just to make the Inter code more comprehensible. An example would be
|ACTIVITY_HL|, declared abover as |H_C_G(ACTIVITY_HL, I"V")|. The resulting name
"generated" (hence the |G| in |H_C_G|) might be, for example, |V1_starting_the_virtual_mach|.
The number |1| guarantees uniqueness; the (truncated) text following is purely for
the reader's convenience.

=
inter_name *Hierarchy::make_iname_with_memo(int id, package_request *P, wording W) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, W, NULL, -1, NULL);
}

@ And this further elaboration supplies the number to use, in place of the |1|.
This is needed only for kinds, where the kits expect to find classes called, e.g.,
|K7_backdrop|, even though in some circumstances this may not be number |7| in
class inheritance tree order.

=
inter_name *Hierarchy::make_iname_with_memo_and_value(int id, package_request *P,
	wording W, int x) {
	inter_name *iname = HierarchyLocations::find_in_package(Emit::tree(), id, P, W,
		NULL, x, NULL);
	Hierarchy::make_available(iname);
	return iname;
}

@ When a translated name has to be generated from the name of something related to
it (e.g. by adding a prefix or suffix), the following should be used:

=
inter_name *Hierarchy::derive_iname_in(int id, inter_name *from, package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING,
		from, -1, NULL);
}

@ For the handful of names with "imposed translation", where the caller has to
supply the translated name, the following should be used:

=
inter_name *Hierarchy::make_iname_with_specific_translation(int id, text_stream *name,
	package_request *P) {
	return HierarchyLocations::find_in_package(Emit::tree(), id, P, EMPTY_WORDING,
		NULL, -1, name);
}

@h Availability.
Just as the code generated by the compiler needs to be able to access code in
the kits, so also the other way around: code in a kit may need to call a
function which we're compiling. Kits can only see those inames which we "make
available", using the following, which creates a socket. Again, see
//bytecode: Connectors// for more.

=
void Hierarchy::make_available(inter_name *iname) {
	text_stream *ma_as = Produce::get_translation(iname);
	if (Str::len(ma_as) == 0) ma_as = InterNames::to_text(iname);
	PackageTypes::get(Emit::tree(), I"_linkage");
	inter_symbol *S = InterNames::to_symbol(iname);
	Inter::Connectors::socket(Emit::tree(), ma_as, S);
}

@h Adding packages at attachment points.
Consider the following example piece of declaration:
= (text as InC)
	H_BEGIN(HierarchyLocations::local_submodule(kinds))
		H_BEGIN_AP(KIND_HAP,                  I"kind", I"_kind")
			...
		H_END
	H_END
=
Here, the "attachment point" (AP) is a place where multiple packages can be
placed, each with the same internal structure (defined by the |...| part
omitted here). |kinds| is a submodule name, and the "local" part means that
each compilation unit will become its own module, which will have its own
individual |kinds| submodule. Each of those will have multiple packages inside
of package type |_kind|.

Well, given that picture, |Hierarchy::package(C, KIND_HAP)| will create a new
such |_kind| package inside C. For example, it might return a new package
|main/locksmith_by_emily_short/kinds/K_lock|.

=
package_request *Hierarchy::package(compilation_unit *C, int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), C, NULL, hap_id);
}

@ If we just want the compilation unit in which the current sentence lies:

=
package_request *Hierarchy::local_package(int hap_id) {
	return Hierarchy::local_package_to(hap_id, current_sentence);
}

package_request *Hierarchy::local_package_to(int hap_id, parse_node *at) {
	return HierarchyLocations::attach_new_package(Emit::tree(),
		CompilationUnits::find(at), NULL, hap_id);
}

@ There is just one package called |synoptic|, so there's no issue of what
compilation unit is meant: that's why it's "synoptic".

=
package_request *Hierarchy::synoptic_package(int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, NULL, hap_id);
}

@ Attachment points do not always have to be at the top level of submodules,
as the |KIND_HAP| example was. For example:
= (text as InC)
		H_BEGIN_AP(VERBS_HAP,                 I"verb", I"_verb")
			...
			H_BEGIN_AP(VERB_FORMS_HAP,        I"form", I"_verb_form")
				...
			H_END
		H_END
=
Here a |_verb_form| package has to be created inside a |_verb| package. Calling
|Hierarchy::package_within(VERB_FORMS_HAP, P)| indeed constructs a new one
inside the package |P|; if |P| does not have type |_verb|, an internal error
will automatically trip, in order to enforce the layout rules.

=
package_request *Hierarchy::package_within(int hap_id, package_request *super) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, super, hap_id);
}

@h Adding packages not at attachment points. 
Just a handful of packages are made other than with the |*_HAP| attachment
point system, and for those:

=
package_request *Hierarchy::make_package_in(int id, package_request *P) {
	return HierarchyLocations::package_in_package(Emit::tree(), id, P);
}

@h Metadata.
These are convenient functions for marking up packages with metadata:

=
void Hierarchy::apply_metadata(package_request *P, int id, text_stream *value) {
	inter_name *iname = Hierarchy::make_iname_in(id, P);
	Emit::text_constant(iname, value);
}

void Hierarchy::apply_metadata_from_number(package_request *P, int id, inter_ti N) {
	inter_name *iname = Hierarchy::make_iname_in(id, P);
	Emit::numeric_constant(iname, N);
}

void Hierarchy::apply_metadata_from_iname(package_request *P, int id, inter_name *val) {
	inter_name *iname = Hierarchy::make_iname_in(id, P);
	Emit::iname_constant(iname, K_value, val);
}

void Hierarchy::apply_metadata_from_wording(package_request *P, int id, wording W) {
	TEMPORARY_TEXT(ANT)
	WRITE_TO(ANT, "%W", W);
	Hierarchy::apply_metadata(P, id, ANT);
	DISCARD_TEXT(ANT)
}

void Hierarchy::apply_metadata_from_raw_wording(package_request *P, int id, wording W) {
	TEMPORARY_TEXT(ANT)
	WRITE_TO(ANT, "%+W", W);
	Hierarchy::apply_metadata(P, id, ANT);
	DISCARD_TEXT(ANT)
}
