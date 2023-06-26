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
		InvTarget::inv_to(DL, Emit::tree());
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
	submodule_identity *activities = LargeScale::register_submodule_identity(I"activities");
	H_BEGIN(LocationRequirements::local_submodule(activities))
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
	H_BEGIN(LocationRequirements::any_package_of_type(c))
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

@d H_C_T(id, n) HierarchyLocations::con(I, id, n,                              H_CURRENT);
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
in category (1). Names in category (2) are set up in //pipeline: Synoptic Hierarchy//
and //pipeline: The Standard Kits//, but by very similar methods.

=
void Hierarchy::establish(void) {
	Packaging::incarnate(LargeScale::module_request(Emit::tree(), I"generic")->where_found);
	SynopticHierarchy::establish(Emit::tree());
	KitHierarchy::establish(Emit::tree());
	H_BEGIN_DECLARATIONS
	@<Establish locations for material created by the compiler@>;
	@<Establish locations for material expected to be added by linking@>;
	@<Prevent architectural symbols from being doubly defined@>;
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
	@<Establish external files@>;
	@<Establish grammar@>;
	@<Establish instances@>;
	@<Establish int-fiction@>;
	@<Establish internal files@>;
	@<Establish kinds@>;
	@<Establish literal patterns@>;
	@<Establish mapping hints@>;
	@<Establish phrases@>;
	@<Establish properties@>;
	@<Establish relations@>;
	@<Establish rulebooks@>;
	@<Establish rules@>;
	@<Establish tables@>;
	@<Establish use options@>;
	@<Establish variables@>;
	@<Establish enclosed matter@>;
	@<The rest@>;

@<Establish locations for material expected to be added by linking@> =
	@<Establish architectural resources@>;

@h Basics.

@e BOGUS_HAP from 0

@e I7_VERSION_NUMBER_HL
@e I7_FULL_VERSION_NUMBER_HL
@e VM_MD_HL
@e VM_ICON_MD_HL
@e LANGUAGE_ELEMENTS_USED_MD_HL
@e LANGUAGE_ELEMENTS_NOT_USED_MD_HL
@e MEMORY_ECONOMY_MD_HL
@e MAX_INDEXED_FIGURES_HL
@e NO_TEST_SCENARIOS_HL
@e MEMORY_HEAP_SIZE_HL
@e LOCALPARKING_HL
@e RNG_SEED_AT_START_OF_PLAY_HL
@e MAX_FRAME_SIZE_NEEDED_HL
@e SUBMAIN_HL
@e AFTER_ACTION_HOOK_HL
@e HEADINGS_HAP
@e HEADING_INDEXABLE_MD_HL
@e HEADING_TEXT_MD_HL
@e HEADING_PARTS_MD_HL
@e HEADING_PART1_MD_HL
@e HEADING_PART2_MD_HL
@e HEADING_PART3_MD_HL
@e HEADING_AT_MD_HL
@e HEADING_LEVEL_MD_HL
@e HEADING_INDENTATION_MD_HL
@e HEADING_WORD_COUNT_MD_HL
@e HEADING_SUMMARY_MD_HL
@e HEADING_ID_HL
@e DEBUGGING_ASPECTS_HAP
@e DEBUGGING_ASPECT_NAME_MD_HL
@e DEBUGGING_ASPECT_USED_MD_HL

@<Establish basics@> =
	submodule_identity *basics = LargeScale::register_submodule_identity(I"basics");

	H_BEGIN(LocationRequirements::completion_submodule(I, basics))
		H_C_T(I7_VERSION_NUMBER_HL,           I"I7_VERSION_NUMBER")
		H_C_T(I7_FULL_VERSION_NUMBER_HL,      I"I7_FULL_VERSION_NUMBER")
		H_C_T(VM_MD_HL,                       I"^virtual_machine")
		H_C_T(VM_ICON_MD_HL,                  I"^virtual_machine_icon")
		H_C_T(LANGUAGE_ELEMENTS_USED_MD_HL,   I"^language_elements_used")
		H_C_T(LANGUAGE_ELEMENTS_NOT_USED_MD_HL, I"^language_elements_not_used")
		H_C_T(MEMORY_ECONOMY_MD_HL,           I"^memory_economy")
		H_C_T(MEMORY_HEAP_SIZE_HL,            I"MEMORY_HEAP_SIZE")
		H_C_T(LOCALPARKING_HL,                I"LocalParking")
		H_C_T(RNG_SEED_AT_START_OF_PLAY_HL,   I"RNG_SEED_AT_START_OF_PLAY")
		H_C_T(MAX_INDEXED_FIGURES_HL,         I"^max_indexed_figures")
		H_C_T(MAX_FRAME_SIZE_NEEDED_HL,       I"MAX_FRAME_SIZE_NEEDED")
		H_F_T(SUBMAIN_HL,                     I"Submain_fn", I"Submain")
		H_C_T(AFTER_ACTION_HOOK_HL,           I"AfterActionHook")
		H_BEGIN_AP(HEADINGS_HAP,              I"heading", I"_heading")
			H_C_U(HEADING_INDEXABLE_MD_HL,    I"^indexable")
			H_C_U(HEADING_TEXT_MD_HL,         I"^text")
			H_C_U(HEADING_PARTS_MD_HL,        I"^parts")
			H_C_U(HEADING_PART1_MD_HL,        I"^part1")
			H_C_U(HEADING_PART2_MD_HL,        I"^part2")
			H_C_U(HEADING_PART3_MD_HL,        I"^part3")
			H_C_U(HEADING_AT_MD_HL,           I"^at")
			H_C_U(HEADING_LEVEL_MD_HL,        I"^level")
			H_C_U(HEADING_INDENTATION_MD_HL,  I"^indentation")
			H_C_U(HEADING_WORD_COUNT_MD_HL,   I"^word_count")
			H_C_U(HEADING_SUMMARY_MD_HL,      I"^summary")
			H_C_U(HEADING_ID_HL,              I"id")
		H_END
		H_BEGIN_AP(DEBUGGING_ASPECTS_HAP,     I"debugging_aspect", I"_debugging_aspect")
			H_C_U(DEBUGGING_ASPECT_NAME_MD_HL, I"^name")
			H_C_U(DEBUGGING_ASPECT_USED_MD_HL, I"^used")
		H_END
	H_END

@h Modules.

@e EXT_CATEGORY_MD_HL
@e EXT_AT_MD_HL
@e EXT_TITLE_MD_HL
@e EXT_AUTHOR_MD_HL
@e EXT_VERSION_MD_HL
@e EXT_CREDIT_MD_HL
@e EXT_EXTRA_CREDIT_MD_HL
@e EXT_MODESTY_MD_HL
@e EXT_WORD_COUNT_MD_HL
@e EXT_INCLUDED_AT_MD_HL
@e EXT_INCLUDED_BY_MD_HL
@e EXT_AUTO_INCLUDED_MD_HL
@e EXT_STANDARD_MD_HL
@e EXTENSION_ID_HL

@<Establish modules@> =
	H_BEGIN(LocationRequirements::any_package_of_type(I"_module"))
		H_C_U(EXT_CATEGORY_MD_HL,       I"^category")
		H_C_U(EXT_AT_MD_HL,             I"^at")
		H_C_U(EXT_TITLE_MD_HL,          I"^title")
		H_C_U(EXT_AUTHOR_MD_HL,         I"^author")
		H_C_U(EXT_VERSION_MD_HL,        I"^version")
		H_C_U(EXT_CREDIT_MD_HL,         I"^credit")
		H_C_U(EXT_EXTRA_CREDIT_MD_HL,   I"^extra_credit")
		H_C_U(EXT_MODESTY_MD_HL,        I"^modesty")
		H_C_U(EXT_WORD_COUNT_MD_HL,     I"^word_count")
		H_C_U(EXT_INCLUDED_AT_MD_HL,    I"^included_at")
		H_C_U(EXT_INCLUDED_BY_MD_HL,    I"^included_by")
		H_C_U(EXT_AUTO_INCLUDED_MD_HL,  I"^auto_included")
		H_C_U(EXT_STANDARD_MD_HL,       I"^standard")
		H_C_U(EXTENSION_ID_HL,          I"extension_id")
	H_END

@h Actions.

@e ACTIONS_HAP
@e ACTION_NAME_MD_HL
@e ACTION_DISPLAY_NAME_MD_HL
@e ACTION_PAST_NAME_MD_HL
@e ACTION_AT_MD_HL
@e ACTION_VARC_MD_HL
@e DEBUG_ACTION_MD_HL
@e ACTION_DSHARP_MD_HL
@e NO_CODING_MD_HL
@e OUT_OF_WORLD_MD_HL
@e REQUIRES_LIGHT_MD_HL
@e CAN_HAVE_NOUN_MD_HL
@e CAN_HAVE_SECOND_MD_HL
@e NOUN_ACCESS_MD_HL
@e SECOND_ACCESS_MD_HL
@e NOUN_KIND_MD_HL
@e SECOND_KIND_MD_HL
@e ACTION_CHECK_MD_HL 
@e ACTION_CARRY_OUT_MD_HL
@e ACTION_REPORT_MD_HL
@e ACTION_INDEX_HEADING_MD_HL
@e ACTION_INDEX_SUBHEADING_MD_HL
@e ACTION_SPECIFICATION_MD_HL
@e ACTION_DESCRIPTION_MD_HL
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
@e CG_LINES_PRODUCING_HAP
@e CG_LINE_PRODUCING_MD_HL
@e ACTION_VARIABLES_HAP
@e ACTION_VAR_NAME_MD_HL
@e ACTION_VAR_AT_MD_HL
@e ACTION_VAR_DOCUMENTATION_MD_HL
@e ACTION_VAR_KIND_MD_HL
@e NAMED_ACTION_PATTERNS_HAP
@e NAP_FN_HL
@e NAP_NAME_MD_HL
@e NAP_AT_MD_HL
@e NAMED_ACTION_ENTRIES_HAP
@e NAPE_TEXT_MD_HL
@e NAPE_AT_MD_HL

@<Establish actions@> =
	submodule_identity *actions = LargeScale::register_submodule_identity(I"actions");

	H_BEGIN(LocationRequirements::local_submodule(actions))
		H_BEGIN_AP(ACTIONS_HAP, I"action", I"_action")
			H_C_U(ACTION_NAME_MD_HL,             I"^name")
			H_C_U(ACTION_DISPLAY_NAME_MD_HL,     I"^display_name")
			H_C_U(ACTION_PAST_NAME_MD_HL,        I"^past_name")
			H_C_U(ACTION_AT_MD_HL,               I"^at")
			H_C_U(ACTION_VARC_MD_HL,             I"^var_creator")
			H_C_U(DEBUG_ACTION_MD_HL,            I"^debug_fn")
			H_C_U(ACTION_DSHARP_MD_HL,           I"^double_sharp")
			H_C_U(NO_CODING_MD_HL,               I"^no_coding")
			H_C_U(OUT_OF_WORLD_MD_HL,            I"^out_of_world")
			H_C_U(REQUIRES_LIGHT_MD_HL,          I"^requires_light")
			H_C_U(CAN_HAVE_NOUN_MD_HL,           I"^can_have_noun")
			H_C_U(CAN_HAVE_SECOND_MD_HL,         I"^can_have_second")
			H_C_U(NOUN_ACCESS_MD_HL,             I"^noun_access")
			H_C_U(SECOND_ACCESS_MD_HL,           I"^second_access")
			H_C_U(NOUN_KIND_MD_HL,               I"^noun_kind")
			H_C_U(SECOND_KIND_MD_HL,             I"^second_kind")
			H_C_U(ACTION_CHECK_MD_HL,            I"^check_rulebook")
			H_C_U(ACTION_CARRY_OUT_MD_HL,        I"^carry_out_rulebook")
			H_C_U(ACTION_REPORT_MD_HL,           I"^report_rulebook")
			H_C_U(ACTION_INDEX_HEADING_MD_HL,    I"^index_heading")
			H_C_U(ACTION_INDEX_SUBHEADING_MD_HL, I"^index_subheading")
			H_C_U(ACTION_SPECIFICATION_MD_HL,    I"^specification")
			H_C_U(ACTION_DESCRIPTION_MD_HL,      I"^description")
			H_C_U(ACTION_ID_HL,                  I"action_id")
			H_C_U(ACTION_BASE_NAME_HL,           I"A")
			H_C_T(WAIT_HL,                       I"Wait")
			H_C_I(TRANSLATED_BASE_NAME_HL)
			H_C_P(DOUBLE_SHARP_NAME_HL,          I"##")
			H_F_S(PERFORM_FN_HL,                 I"perform_fn", I"Sub")
			H_F_S(DEBUG_ACTION_FN_HL,            I"debug_fn", I"Dbg")
			H_PKG(CHECK_RB_HL,                   I"check_rb", I"_rulebook")
			H_PKG(CARRY_OUT_RB_HL,               I"carry_out_rb", I"_rulebook")
			H_PKG(REPORT_RB_HL,                  I"report_rb", I"_rulebook")
			H_C_U(ACTION_SHV_ID_HL,              I"var_id")
			H_F_U(ACTION_STV_CREATOR_FN_HL,      I"stv_creator_fn")
			H_BEGIN_AP(CG_LINES_PRODUCING_HAP,   I"cg_line", I"_cg_line")
				H_C_U(CG_LINE_PRODUCING_MD_HL,   I"^line")
			H_END
			H_BEGIN_AP(ACTION_VARIABLES_HAP, I"action_variable", I"_shared_variable")
				H_C_U(ACTION_VAR_NAME_MD_HL,     I"^name")
				H_C_U(ACTION_VAR_AT_MD_HL,       I"^at")
				H_C_U(ACTION_VAR_DOCUMENTATION_MD_HL, I"^documentation")
				H_C_U(ACTION_VAR_KIND_MD_HL,     I"^kind")
			H_END
		H_END
	H_END

	submodule_identity *naps = LargeScale::register_submodule_identity(I"named_action_patterns");

	H_BEGIN(LocationRequirements::local_submodule(naps))
		H_BEGIN_AP(NAMED_ACTION_PATTERNS_HAP, I"named_action_pattern", I"_named_action_pattern")
			H_F_U(NAP_FN_HL,                  I"nap_fn")
			H_C_U(NAP_NAME_MD_HL,             I"^name")
			H_C_U(NAP_AT_MD_HL,               I"^at")
			H_BEGIN_AP(NAMED_ACTION_ENTRIES_HAP, I"named_action_pattern_entry", I"_named_action_pattern_entry")
				H_C_U(NAPE_TEXT_MD_HL,         I"^text")
				H_C_U(NAPE_AT_MD_HL,           I"^at")
			H_END
		H_END
	H_END

@h Activities.

@e ACTIVITIES_HAP

@e ACTIVITY_NAME_MD_HL
@e ACTIVITY_AT_MD_HL
@e ACTIVITY_VAR_CREATOR_MD_HL
@e ACTIVITY_BEFORE_MD_HL
@e ACTIVITY_FOR_MD_HL
@e ACTIVITY_AFTER_MD_HL
@e ACTIVITY_UFA_MD_HL
@e ACTIVITY_HID_MD_HL
@e ACTIVITY_INDEX_ID_MD_HL
@e ACTIVITY_DOCUMENTATION_MD_HL
@e ACTIVITY_XREFS_HAP
@e XREF_TEXT_MD_HL
@e XREF_AT_MD_HL

@e ACTIVITY_ID_HL
@e ACTIVITY_VALUE_HL
@e ACTIVITY_BEFORE_RB_HL
@e ACTIVITY_FOR_RB_HL
@e ACTIVITY_AFTER_RB_HL
@e ACTIVITY_EMPTY_MD_HL
@e ACTIVITY_SHV_ID_HL
@e ACTIVITY_VARC_FN_HL

@<Establish activities@> =
	submodule_identity *activities = LargeScale::register_submodule_identity(I"activities");

	H_BEGIN(LocationRequirements::local_submodule(activities))
		H_BEGIN_AP(ACTIVITIES_HAP,            I"activity", I"_activity")

			H_C_U(ACTIVITY_NAME_MD_HL,        I"^name")
			H_C_U(ACTIVITY_AT_MD_HL,          I"^at")
			H_C_U(ACTIVITY_BEFORE_MD_HL,      I"^before_rulebook")
			H_C_U(ACTIVITY_FOR_MD_HL,         I"^for_rulebook")
			H_C_U(ACTIVITY_AFTER_MD_HL,       I"^after_rulebook")
			H_C_U(ACTIVITY_EMPTY_MD_HL,       I"^empty")
			H_C_U(ACTIVITY_UFA_MD_HL,         I"^used_by_future")
			H_C_U(ACTIVITY_HID_MD_HL,         I"^hide_in_debugging")
			H_C_U(ACTIVITY_VAR_CREATOR_MD_HL, I"^var_creator")
			H_C_U(ACTIVITY_DOCUMENTATION_MD_HL, I"^documentation")
			H_C_U(ACTIVITY_INDEX_ID_MD_HL,    I"^index_id")
			H_BEGIN_AP(ACTIVITY_XREFS_HAP,    I"activity_xref", I"_activity_xref")
				H_C_U(XREF_TEXT_MD_HL,        I"^text")
				H_C_U(XREF_AT_MD_HL,          I"^at")
			H_END
			H_C_U(ACTIVITY_ID_HL,             I"activity_id")
			H_C_G(ACTIVITY_VALUE_HL,          I"V")
			H_PKG(ACTIVITY_BEFORE_RB_HL,      I"before_rb", I"_rulebook")
			H_PKG(ACTIVITY_FOR_RB_HL,         I"for_rb", I"_rulebook")
			H_PKG(ACTIVITY_AFTER_RB_HL,       I"after_rb", I"_rulebook")
			H_C_U(ACTIVITY_SHV_ID_HL,         I"var_id")
			H_F_U(ACTIVITY_VARC_FN_HL,        I"stv_creator_fn")
		H_END
	H_END

@h Adjectives.

@e ADJECTIVES_HAP
@e ADJECTIVE_HL
@e ADJECTIVE_TEXT_MD_HL
@e ADJECTIVE_INDEX_MD_HL
@e MEASUREMENTS_HAP
@e MEASUREMENT_FN_HL
@e ADJECTIVE_PHRASES_HAP
@e DEFINITION_FN_HL
@e ADJECTIVE_TASKS_HAP
@e TASK_FN_HL

@<Establish adjectives@> =
	submodule_identity *adjectives = LargeScale::register_submodule_identity(I"adjectives");

	H_BEGIN(LocationRequirements::local_submodule(adjectives))
		H_BEGIN_AP(ADJECTIVES_HAP,            I"adjective", I"_adjective")
			H_C_U(ADJECTIVE_HL,               I"adjective")
			H_C_U(ADJECTIVE_TEXT_MD_HL,       I"^text")
			H_C_U(ADJECTIVE_INDEX_MD_HL,      I"^index_entry")
			H_BEGIN_AP(ADJECTIVE_TASKS_HAP,   I"adjective_task", I"_adjective_task")
				H_F_U(TASK_FN_HL,             I"task_fn")
			H_END
		H_END
		H_BEGIN_AP(MEASUREMENTS_HAP,          I"measurement", I"_measurement")
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

@e IFID_MD_HL
@e STORY_MD_HL
@e HEADLINE_MD_HL
@e GENRE_MD_HL
@e AUTHOR_MD_HL
@e RELEASE_MD_HL
@e STORY_VERSION_MD_HL
@e SERIAL_MD_HL
@e LANGUAGE_MD_HL
@e DESCRIPTION_MD_HL
@e EPISODE_NUMBER_MD_HL
@e SERIES_NAME_MD_HL
@e YEAR_MD_HL

@<Establish bibliographic@> =
	submodule_identity *bibliographic = LargeScale::register_submodule_identity(I"bibliographic");

	H_BEGIN(LocationRequirements::completion_submodule(I, bibliographic))
		H_C_T(UUID_ARRAY_HL,                  I"UUID_ARRAY")
		H_D_T(STORY_HL,                       I"Story_datum", I"Story")
		H_D_T(HEADLINE_HL,                    I"Headline_datum", I"Headline")
		H_D_T(STORY_AUTHOR_HL,                I"Author_datum", I"Story_Author")
		H_D_T(RELEASE_HL,                     I"Release_datum", I"Release")
		H_D_T(SERIAL_HL,                      I"Serial_datum", I"Serial")
		H_C_T(IFID_MD_HL,                     I"^IFID")
		H_C_T(STORY_MD_HL,                    I"^title")
		H_C_T(HEADLINE_MD_HL,                 I"^headline")
		H_C_T(GENRE_MD_HL,                    I"^genre")
		H_C_T(AUTHOR_MD_HL,                   I"^author")
		H_C_T(RELEASE_MD_HL,                  I"^release")
		H_C_T(STORY_VERSION_MD_HL,            I"^version")
		H_C_T(SERIAL_MD_HL,                   I"^serial")
		H_C_T(LANGUAGE_MD_HL,                 I"^language")
		H_C_T(DESCRIPTION_MD_HL,              I"^description")
		H_C_T(EPISODE_NUMBER_MD_HL,           I"^episode")
		H_C_T(SERIES_NAME_MD_HL,              I"^series")
		H_C_T(YEAR_MD_HL,                     I"^year")
	H_END

@h Chronology.

@e PAST_TENSE_CONDS_HAP
@e PTC_ID_HL
@e PTC_VALUE_MD_HL
@e PTC_FN_HL

@e ACTION_HISTORY_CONDS_HAP
@e AHC_ID_HL
@e AHC_VALUE_MD_HL
@e AHC_FN_HL

@<Establish chronology@> =
	submodule_identity *chronology = LargeScale::register_submodule_identity(I"chronology");

	H_BEGIN(LocationRequirements::local_submodule(chronology))
		H_BEGIN_AP(PAST_TENSE_CONDS_HAP, I"past_condition", I"_past_condition")
			H_C_U(PTC_ID_HL,                  I"ptc_id")
			H_C_U(PTC_VALUE_MD_HL,            I"^value")
			H_F_G(PTC_FN_HL,                  I"pcon_fn", I"PCONR")
		H_END
		H_BEGIN_AP(ACTION_HISTORY_CONDS_HAP,  I"action_history_condition", I"_action_history_condition")
			H_C_U(AHC_ID_HL,                  I"ahc_id")
			H_C_U(AHC_VALUE_MD_HL,            I"^value")
			H_F_G(AHC_FN_HL,                  I"pap_fn", I"PAPR")
		H_END
	H_END

@h Conjugations.

@e CV_MEANING_HL
@e CV_MODAL_HL
@e CV_NEG_HL
@e CV_POS_HL

@e MVERBS_HAP
@e MVERB_NAME_MD_HL
@e MVERB_AT_MD_HL
@e MVERB_INFINITIVE_MD_HL
@e MODAL_CONJUGATION_FN_HL
@e VERBS_HAP
@e VERB_NAME_MD_HL
@e VERB_AT_MD_HL
@e VERB_INFINITIVE_MD_HL
@e VERB_MEANING_MD_HL
@e VERB_MEANINGLESS_MD_HL
@e VERB_PRESENT_MD_HL
@e VERB_PAST_MD_HL
@e VERB_PRESENT_PERFECT_MD_HL
@e VERB_PAST_PERFECT_MD_HL
@e NONMODAL_CONJUGATION_FN_HL
@e VERB_FORMS_HAP
@e FORM_VALUE_MD_HL
@e FORM_SORTING_MD_HL
@e FORM_FN_HL
@e CONJUGATION_FN_HL
@e PREPOSITIONS_HAP
@e PREPOSITION_NAME_MD_HL
@e PREPOSITION_AT_MD_HL

@<Establish conjugations@> =
	submodule_identity *conjugations = LargeScale::register_submodule_identity(I"conjugations");

	H_BEGIN(LocationRequirements::generic_submodule(I, conjugations))
		H_C_T(CV_MEANING_HL,                  I"CV_MEANING")
		H_C_T(CV_MODAL_HL,                    I"CV_MODAL")
		H_C_T(CV_NEG_HL,                      I"CV_NEG")
		H_C_T(CV_POS_HL,                      I"CV_POS")
	H_END

	H_BEGIN(LocationRequirements::local_submodule(conjugations))
		H_BEGIN_AP(MVERBS_HAP,                 I"modal_verb", I"_modal_verb")
			H_C_U(MVERB_NAME_MD_HL,            I"^name")
			H_C_U(MVERB_AT_MD_HL,              I"^at")
			H_C_U(MVERB_INFINITIVE_MD_HL,      I"^infinitive")
			H_F_G(MODAL_CONJUGATION_FN_HL,     I"conjugation_fn", I"ConjugateModalVerb")
		H_END
		H_BEGIN_AP(VERBS_HAP,                  I"verb", I"_verb")
			H_C_U(VERB_NAME_MD_HL,             I"^name")
			H_C_U(VERB_AT_MD_HL,               I"^at")
			H_C_U(VERB_INFINITIVE_MD_HL,       I"^infinitive")
			H_C_U(VERB_MEANING_MD_HL,          I"^meaning")
			H_C_U(VERB_MEANINGLESS_MD_HL,      I"^meaningless")
			H_C_U(VERB_PRESENT_MD_HL,          I"^present")
			H_C_U(VERB_PAST_MD_HL,             I"^past")
			H_C_U(VERB_PRESENT_PERFECT_MD_HL,  I"^present_perfect")
			H_C_U(VERB_PAST_PERFECT_MD_HL,     I"^past_perfect")
			H_F_G(NONMODAL_CONJUGATION_FN_HL,  I"conjugation_fn", I"ConjugateVerb")
			H_BEGIN_AP(VERB_FORMS_HAP,         I"form", I"_verb_form")
				H_C_U(FORM_VALUE_MD_HL,        I"^verb_value")
				H_C_U(FORM_SORTING_MD_HL,      I"^verb_sorting")
				H_F_U(FORM_FN_HL,              I"form_fn")
			H_END
		H_END
		H_BEGIN_AP(PREPOSITIONS_HAP,           I"preposition", I"_preposition")
			H_C_U(PREPOSITION_NAME_MD_HL,      I"^text")
			H_C_U(PREPOSITION_AT_MD_HL,        I"^at")
		H_END
	H_END

@h Equations.

@e EQUATIONS_HAP
@e IDENTIFIER_FN_HL
@e EQUATION_NAME_MD_HL
@e EQUATION_TEXT_MD_HL
@e EQUATION_AT_MD_HL

@<Establish equations@> =
	submodule_identity *equations = LargeScale::register_submodule_identity(I"equations");

	H_BEGIN(LocationRequirements::local_submodule(equations))
		H_BEGIN_AP(EQUATIONS_HAP,             I"equation", I"_equation")
			H_C_U(EQUATION_NAME_MD_HL,        I"^name")
			H_C_U(EQUATION_TEXT_MD_HL,        I"^text")
			H_C_U(EQUATION_AT_MD_HL,          I"^at")
			H_F_U(IDENTIFIER_FN_HL,           I"identifier_fn")
		H_END
	H_END

@h External files.

@e EXTERNAL_FILES_HAP
@e FILE_HL
@e IFID_HL

@<Establish external files@> =
	submodule_identity *external_files = LargeScale::register_submodule_identity(I"external_files");

	H_BEGIN(LocationRequirements::local_submodule(external_files))
		H_BEGIN_AP(EXTERNAL_FILES_HAP,        I"external_file", I"_external_file")
			H_C_U(FILE_HL,                    I"file")
			H_C_U(IFID_HL,                    I"ifid")
		H_END
	H_END

@h Grammar.

@e COND_TOKENS_HAP
@e CONDITIONAL_TOKEN_FN_HL
@e TESTS_HAP
@e SCRIPT_HL
@e TEST_MD_HL
@e TEST_NAME_MD_HL
@e TEST_LENGTH_MD_HL
@e REQUIREMENTS_HL
@e MISTAKES_HAP
@e MISTAKE_FN_HL
@e NOUN_FILTERS_HAP
@e NOUN_FILTER_FN_HL
@e PARSE_NAMES_HAP
@e PARSE_NAME_FN_HL
@e SCOPE_FILTERS_HAP
@e SCOPE_FILTER_FN_HL
@e SLASH_TOKENS_HAP
@e SLASH_FN_HL

@e REPARSE_CODE_HL
@e DICT_ENTRY_BYTES_HL
@e DICT_WORD_SIZE_HL
@e VERB_DIRECTIVE_META_HL
@e VERB_DIRECTIVE_NOUN_FILTER_HL
@e VERB_DIRECTIVE_SCOPE_FILTER_HL
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

@e OBJECT_NOUNS_HAP
@e NAME_ARRAY_HL

@e COMMANDS_HAP
@e VERB_DECLARATION_ARRAY_HL
@e MISTAKEACTION_HL
@e MISTAKEACTIONSUB_HL

@e COMMAND_GRAMMARS_HAP
@e CG_IS_COMMAND_MD_HL
@e CG_IS_TOKEN_MD_HL
@e CG_IS_SUBJECT_MD_HL
@e CG_IS_VALUE_MD_HL
@e CG_IS_CONSULT_MD_HL
@e CG_IS_PROPERTY_NAME_MD_HL
@e CG_AT_MD_HL
@e CG_NAME_MD_HL
@e CG_COMMAND_MD_HL
@e PROPERTY_GPR_FN_HL
@e PARSE_LINE_FN_HL
@e CONSULT_FN_HL
@e NO_VERB_VERB_DEFINED_HL
@e CG_COMMAND_ALIASES_HAP
@e CG_ALIAS_MD_HL
@e CG_LINES_HAP
@e CG_XREF_SYMBOL_HL
@e CG_LINE_TEXT_MD_HL
@e CG_LINE_AT_MD_HL
@e CG_ACTION_MD_HL
@e CG_LINE_REVERSED_MD_HL
@e CG_TRUE_VERB_MD_HL

@<Establish grammar@> =
	submodule_identity *grammar = LargeScale::register_submodule_identity(I"grammar");

	H_BEGIN(LocationRequirements::generic_submodule(I, grammar))
		H_C_T(REPARSE_CODE_HL,                I"REPARSE_CODE")
		H_C_T(DICT_ENTRY_BYTES_HL,            I"DICT_ENTRY_BYTES")
		H_C_T(DICT_WORD_SIZE_HL,              I"DICT_WORD_SIZE")
		H_C_T(VERB_DIRECTIVE_META_HL,         I"VERB_DIRECTIVE_META")
		H_C_T(VERB_DIRECTIVE_NOUN_FILTER_HL,  I"VERB_DIRECTIVE_NOUN_FILTER")
		H_C_T(VERB_DIRECTIVE_SCOPE_FILTER_HL, I"VERB_DIRECTIVE_SCOPE_FILTER")
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
		H_C_T(MISTAKEACTION_HL,               I"##MistakeAction")
	H_END

	H_BEGIN(LocationRequirements::local_submodule(grammar))
		H_BEGIN_AP(TESTS_HAP,                 I"test", I"_test")
			H_C_U(TEST_NAME_MD_HL,            I"^name")
			H_C_U(TEST_LENGTH_MD_HL,          I"^length")
			H_C_U(SCRIPT_HL,                  I"script")
			H_C_U(REQUIREMENTS_HL,            I"requirements")
		H_END
		H_BEGIN_AP(MISTAKES_HAP,              I"mistake", I"_mistake")
			H_F_G(MISTAKE_FN_HL,              I"mistake_fn", I"Mistake_Token")
		H_END
		H_BEGIN_AP(NOUN_FILTERS_HAP,          I"noun_filter", I"_noun_filter")
			H_F_G(NOUN_FILTER_FN_HL,          I"filter_fn", I"Noun_Filter")
		H_END
		H_BEGIN_AP(SCOPE_FILTERS_HAP,         I"scope_filter", I"_scope_filter")
			H_F_G(SCOPE_FILTER_FN_HL,         I"filter_fn", I"Scope_Filter")
		H_END
		H_BEGIN_AP(PARSE_NAMES_HAP,           I"parse_name", I"_parse_name")
		H_END
		H_BEGIN_AP(SLASH_TOKENS_HAP,          I"slash_token", I"_slash_token")
			H_F_G(SLASH_FN_HL,                I"slash_fn", I"SlashGPR")
		H_END
	H_END

	H_BEGIN(LocationRequirements::completion_submodule(I, grammar))
		H_BEGIN_AP(OBJECT_NOUNS_HAP,          I"object_noun", I"_object_noun")
			H_F_G(NAME_ARRAY_HL,              I"name_array", I"name_array")
			H_F_G(PARSE_NAME_FN_HL,           I"parse_name_fn", I"parse_name")
		H_END
		H_BEGIN_AP(COMMANDS_HAP,              I"command", I"_command")
			H_F_G(VERB_DECLARATION_ARRAY_HL,  NULL, I"GV_Grammar")
			H_C_T(NO_VERB_VERB_DEFINED_HL,    I"NO_VERB_VERB_DEFINED")
		H_END
		H_BEGIN_AP(COMMAND_GRAMMARS_HAP,      I"command_grammar", I"_command_grammar")
			H_C_U(CG_IS_COMMAND_MD_HL,        I"^is_command")
			H_C_U(CG_IS_TOKEN_MD_HL,          I"^is_token")
			H_C_U(CG_IS_SUBJECT_MD_HL,        I"^is_subject")
			H_C_U(CG_IS_VALUE_MD_HL,          I"^is_value")
			H_C_U(CG_IS_CONSULT_MD_HL,        I"^is_consult")
			H_C_U(CG_IS_PROPERTY_NAME_MD_HL,  I"^is_property_name")
			H_C_U(CG_AT_MD_HL,                I"^at")
			H_C_U(CG_NAME_MD_HL,              I"^name")
			H_C_U(CG_COMMAND_MD_HL,           I"^command")
			H_F_G(PROPERTY_GPR_FN_HL,         I"either_or_GPR_fn", I"PRN_PN")
			H_F_G(PARSE_LINE_FN_HL,           I"parse_line_fn", I"GPR_Line")
			H_F_G(CONSULT_FN_HL,              I"consult_fn", I"Consult_Grammar")
			H_BEGIN_AP(CG_COMMAND_ALIASES_HAP, I"cg_alias", I"_cg_alias")
				H_C_U(CG_ALIAS_MD_HL,         I"^alias")
			H_END
			H_BEGIN_AP(CG_LINES_HAP,    	  I"cg_line", I"_cg_line")
				H_C_U(CG_XREF_SYMBOL_HL,      I"line_ref")
				H_C_U(CG_LINE_TEXT_MD_HL,     I"^text")
				H_C_U(CG_LINE_AT_MD_HL,       I"^at")
				H_C_U(CG_ACTION_MD_HL,        I"^action")
				H_C_U(CG_TRUE_VERB_MD_HL,     I"^true_verb")
				H_C_U(CG_LINE_REVERSED_MD_HL, I"^reversed")
			H_END
		H_END
		H_BEGIN_AP(COND_TOKENS_HAP,           I"conditional_token", I"_conditional_token")
			H_F_G(CONDITIONAL_TOKEN_FN_HL,    I"conditional_token_fn", I"Cond_Token")
		H_END
		H_F_T(MISTAKEACTIONSUB_HL,            I"MistakeActionSub_fn", I"MistakeActionSub")
	H_END

@h Instances.

@e INSTANCES_HAP
@e INSTANCE_NAME_MD_HL
@e INSTANCE_DECLARATION_ORDER_MD_HL
@e INSTANCE_PRINTED_NAME_MD_HL
@e INSTANCE_ABBREVIATION_MD_HL
@e INSTANCE_AT_MD_HL
@e INSTANCE_KIND_SET_AT_MD_HL
@e INSTANCE_PROGENITOR_SET_AT_MD_HL
@e INSTANCE_REGION_SET_AT_MD_HL
@e INSTANCE_VALUE_MD_HL
@e INSTANCE_KIND_MD_HL
@e INSTANCE_KIND_XREF_MD_HL
@e INSTANCE_INDEX_KIND_MD_HL
@e INSTANCE_INDEX_KIND_CHAIN_MD_HL
@e INSTANCE_IS_OBJECT_MD_HL
@e INSTANCE_IS_SCENE_MD_HL
@e INSTANCE_IS_ENTIRE_GAME_MD_HL
@e INSTANCE_SCENE_STARTS_MD_HL
@e INSTANCE_SCENE_STARTS_ON_CONDITION_MD_HL
@e INSTANCE_SCENE_STARTS_ON_BEAT_MD_HL
@e INSTANCE_SCENE_ENDS_ON_BEAT_MD_HL
@e INSTANCE_SCENE_RECURS_MD_HL
@e INSTANCE_SCENE_NEVER_ENDS_MD_HL
@e INSTANCE_IS_EXF_MD_HL
@e INSTANCE_IS_INF_MD_HL
@e INSTANCE_FILE_VALUE_MD_HL
@e INSTANCE_INTERNAL_FILE_FORMAT_MD_HL
@e INSTANCE_INTERNAL_FILE_ID_MD_HL
@e INSTANCE_FILE_IS_BINARY_MD_HL
@e INSTANCE_FILE_OWNED_MD_HL
@e INSTANCE_FILE_OWNED_BY_OTHER_MD_HL
@e INSTANCE_FILE_OWNER_MD_HL
@e INSTANCE_LEAFNAME_MD_HL
@e INSTANCE_IS_FIGURE_MD_HL
@e INSTANCE_FIGURE_ID_MD_HL
@e INSTANCE_FIGURE_FILENAME_MD_HL
@e INSTANCE_IS_SOUND_MD_HL
@e INSTANCE_SOUND_FILENAME_MD_HL
@e INSTANCE_SOUND_ID_MD_HL
@e INSTANCE_SSF_MD_HL
@e INSTANCE_SCF_MD_HL
@e INSTANCE_IS_WORN_MD_HL
@e INSTANCE_IS_EVERYWHERE_MD_HL
@e INSTANCE_IS_A_PART_MD_HL
@e INSTANCE_IS_YOURSELF_MD_HL
@e INSTANCE_IS_BENCHMARK_ROOM_MD_HL
@e INSTANCE_IS_START_ROOM_MD_HL
@e INSTANCE_IS_THING_MD_HL
@e INSTANCE_IS_SUPPORTER_MD_HL
@e INSTANCE_IS_PERSON_MD_HL
@e INSTANCE_IS_ROOM_MD_HL
@e INSTANCE_IS_DOOR_MD_HL
@e INSTANCE_SPATIAL_DEPTH_MD_HL
@e INSTANCE_DOOR_OTHER_SIDE_MD_HL
@e INSTANCE_DOOR_SIDE_A_MD_HL
@e INSTANCE_DOOR_SIDE_B_MD_HL
@e INSTANCE_IS_REGION_MD_HL
@e INSTANCE_IS_DIRECTION_MD_HL
@e INSTANCE_OPPOSITE_DIRECTION_MD_HL
@e INSTANCE_IS_BACKDROP_MD_HL
@e INSTANCE_BACKDROP_PRESENCES_MD_HL
@e INSTANCE_REGION_ENCLOSING_MD_HL
@e INSTANCE_SIBLING_MD_HL
@e INSTANCE_CHILD_MD_HL
@e INSTANCE_PROGENITOR_MD_HL
@e INSTANCE_INCORP_SIBLING_MD_HL
@e INSTANCE_INCORP_CHILD_MD_HL
@e INSTANCE_MAP_MD_HL
@e INSTANCE_USAGES_MD_HL
@e INSTANCE_BRIEF_INFERENCES_MD_HL
@e INSTANCE_SPECIFIC_INFERENCES_MD_HL
@e SCENE_ENDS_HAP
@e SCENE_END_NAME_MD_HL
@e SCENE_END_AT_MD_HL
@e SCENE_END_CONDITION_MD_HL
@e SCENE_END_RULEBOOK_MD_HL
@e SCENE_CONNECTORS_HAP
@e SCENE_CONNECTOR_TO_MD_HL
@e SCENE_CONNECTOR_END_MD_HL
@e SCENE_CONNECTOR_AT_MD_HL
@e INST_SHOWME_MD_HL
@e INST_SHOWME_FN_HL
@e INSTANCE_HL
@e SCENE_STATUS_FN_HL
@e SCENE_CHANGE_FN_HL
@e BACKDROP_FOUND_IN_FN_HL
@e REGION_FOUND_IN_FN_HL
@e SHORT_NAME_FN_HL
@e SHORT_NAME_PROPERTY_FN_HL
@e TSD_DOOR_DIR_FN_HL
@e TSD_DOOR_TO_FN_HL
@e INLINE_PROPERTIES_HAP
@e INLINE_PROPERTY_HL
@e DIRECTION_HL
@e INSTANCE_IS_DB_MD_HL
@e INSTANCE_IS_DL_MD_HL
@e INSTANCE_IS_DC_MD_HL
@e BEAT_ARRAY_MD_HL
@e BEAT_ARRAY_HL
@e BEAT_AVAILABLE_FN_HL
@e BEAT_RELEVANT_FN_HL
@e BEAT_STRUCTURE_HL
@e BEAT_SPEAKERS_HL
@e LINE_ARRAY_MD_HL
@e LINE_ARRAY_HL
@e LINE_AVAILABLE_FN_HL
@e LINE_SPEAKER_FN_HL
@e LINE_INTERLOCUTOR_FN_HL
@e LINE_MENTIONING_FN_HL
@e LINE_ACTION_FN_HL
@e CHOICE_ARRAY_MD_HL
@e CHOICE_ARRAY_HL
@e CHOICE_AVAILABLE_FN_HL
@e CHOICE_ACTION_MATCH_FN_HL

@<Establish instances@> =
	submodule_identity *instances = LargeScale::register_submodule_identity(I"instances");

	H_BEGIN(LocationRequirements::local_submodule(instances))
		H_BEGIN_AP(INSTANCES_HAP,                           I"instance", I"_instance")
			H_C_U(INSTANCE_NAME_MD_HL,                      I"^name")
			H_C_U(INSTANCE_DECLARATION_ORDER_MD_HL,         I"^declaration_order")
			H_C_U(INSTANCE_PRINTED_NAME_MD_HL,              I"^printed_name")
			H_C_U(INSTANCE_ABBREVIATION_MD_HL,              I"^abbreviation")
			H_C_U(INSTANCE_AT_MD_HL,                        I"^at")
			H_C_U(INSTANCE_KIND_SET_AT_MD_HL,               I"^kind_set_at")
			H_C_U(INSTANCE_PROGENITOR_SET_AT_MD_HL,         I"^progenitor_set_at")
			H_C_U(INSTANCE_REGION_SET_AT_MD_HL,             I"^region_set_at")
			H_C_U(INSTANCE_VALUE_MD_HL,                     I"^value")
			H_C_U(INSTANCE_KIND_MD_HL,                      I"^kind")
			H_C_U(INSTANCE_KIND_XREF_MD_HL,                 I"^kind_xref")
			H_C_U(INSTANCE_INDEX_KIND_MD_HL,                I"^index_kind")
			H_C_U(INSTANCE_INDEX_KIND_CHAIN_MD_HL,          I"^index_kind_chain")
			H_C_U(INSTANCE_IS_OBJECT_MD_HL,                 I"^is_object")
			H_C_U(INSTANCE_IS_SCENE_MD_HL,                  I"^is_scene")
			H_C_U(INSTANCE_IS_WORN_MD_HL,                   I"^is_worn")
			H_C_U(INSTANCE_IS_EVERYWHERE_MD_HL,             I"^is_everywhere")
			H_C_U(INSTANCE_IS_A_PART_MD_HL,                 I"^is_a_part")
			H_C_U(INSTANCE_IS_YOURSELF_MD_HL,               I"^is_yourself")
			H_C_U(INSTANCE_IS_BENCHMARK_ROOM_MD_HL,         I"^is_benchmark_room")
			H_C_U(INSTANCE_IS_START_ROOM_MD_HL,             I"^is_start_room")
			H_C_U(INSTANCE_IS_ENTIRE_GAME_MD_HL,            I"^is_entire_game")
			H_C_U(INSTANCE_SCENE_STARTS_MD_HL,              I"^starts")
			H_C_U(INSTANCE_SCENE_STARTS_ON_CONDITION_MD_HL, I"^starts_on_condition")
			H_C_U(INSTANCE_SCENE_STARTS_ON_BEAT_MD_HL,      I"^starts_on_beat")
			H_C_U(INSTANCE_SCENE_ENDS_ON_BEAT_MD_HL,        I"^ends_on_beat")
			H_C_U(INSTANCE_SCENE_RECURS_MD_HL,              I"^recurs")
			H_C_U(INSTANCE_SCENE_NEVER_ENDS_MD_HL,          I"^never_ends")
			H_C_U(INSTANCE_SSF_MD_HL,                       I"^scene_status_fn")
			H_C_U(INSTANCE_SCF_MD_HL,                       I"^scene_change_fn")
			H_BEGIN_AP(SCENE_ENDS_HAP,                      I"scene_end", I"_scene_end")
				H_C_U(SCENE_END_NAME_MD_HL,                 I"^name")
				H_C_U(SCENE_END_AT_MD_HL,                   I"^at")
				H_C_U(SCENE_END_CONDITION_MD_HL,            I"^condition")
				H_C_U(SCENE_END_RULEBOOK_MD_HL,             I"^rulebook")
				H_BEGIN_AP(SCENE_CONNECTORS_HAP,            I"scene_connector", I"_scene_connector")
					H_C_U(SCENE_CONNECTOR_TO_MD_HL,         I"^to")
					H_C_U(SCENE_CONNECTOR_END_MD_HL,        I"^end")
					H_C_U(SCENE_CONNECTOR_AT_MD_HL,         I"^at")
				H_END
			H_END
			H_C_U(INSTANCE_IS_EXF_MD_HL,                    I"^is_file")
			H_C_U(INSTANCE_IS_INF_MD_HL,                    I"^is_internal_file")
			H_C_U(INSTANCE_FILE_VALUE_MD_HL,                I"^file_value")
			H_C_U(INSTANCE_FILE_OWNED_MD_HL,                I"^file_owned")
			H_C_U(INSTANCE_FILE_OWNED_BY_OTHER_MD_HL,       I"^file_owned_by_other")
			H_C_U(INSTANCE_FILE_OWNER_MD_HL,                I"^file_owner")
			H_C_U(INSTANCE_INTERNAL_FILE_FORMAT_MD_HL,      I"^internal_file_format")
			H_C_U(INSTANCE_INTERNAL_FILE_ID_MD_HL,          I"^resource_id")
			H_C_U(INSTANCE_FILE_IS_BINARY_MD_HL,            I"^is_binary")
			H_C_U(INSTANCE_LEAFNAME_MD_HL,                  I"^filename")
			H_C_U(INSTANCE_IS_FIGURE_MD_HL,                 I"^is_figure")
			H_C_U(INSTANCE_FIGURE_FILENAME_MD_HL,           I"^filename")
			H_C_U(INSTANCE_FIGURE_ID_MD_HL,                 I"^resource_id")
			H_C_U(INSTANCE_IS_SOUND_MD_HL,                  I"^is_sound")
			H_C_U(INSTANCE_SOUND_FILENAME_MD_HL,            I"^filename")
			H_C_U(INSTANCE_SOUND_ID_MD_HL,                  I"^resource_id")
			H_C_U(INST_SHOWME_MD_HL,                        I"^showme_fn")
			H_C_U(INSTANCE_IS_THING_MD_HL,                  I"^is_thing")
			H_C_U(INSTANCE_IS_SUPPORTER_MD_HL,              I"^is_supporter")
			H_C_U(INSTANCE_IS_PERSON_MD_HL,                 I"^is_person")
			H_C_U(INSTANCE_IS_ROOM_MD_HL,                   I"^is_room")
			H_C_U(INSTANCE_IS_DOOR_MD_HL,                   I"^is_door")
			H_C_U(INSTANCE_SPATIAL_DEPTH_MD_HL,             I"^spatial_depth")
			H_C_U(INSTANCE_DOOR_OTHER_SIDE_MD_HL,           I"^other_side")
			H_C_U(INSTANCE_DOOR_SIDE_A_MD_HL,               I"^side_a")
			H_C_U(INSTANCE_DOOR_SIDE_B_MD_HL,               I"^side_b")
			H_C_U(INSTANCE_IS_REGION_MD_HL,                 I"^is_region")
			H_C_U(INSTANCE_IS_DIRECTION_MD_HL,              I"^is_direction")
			H_C_U(INSTANCE_OPPOSITE_DIRECTION_MD_HL,        I"^opposite_direction")
			H_C_U(INSTANCE_IS_BACKDROP_MD_HL,               I"^is_backdrop")
			H_C_U(INSTANCE_BACKDROP_PRESENCES_MD_HL,        I"^backdrop_presences")
			H_C_U(INSTANCE_REGION_ENCLOSING_MD_HL,          I"^region_enclosing")
			H_C_U(INSTANCE_SIBLING_MD_HL,                   I"^sibling")
			H_C_U(INSTANCE_CHILD_MD_HL,                     I"^child")
			H_C_U(INSTANCE_PROGENITOR_MD_HL,                I"^progenitor")
			H_C_U(INSTANCE_INCORP_SIBLING_MD_HL,            I"^incorp_sibling")
			H_C_U(INSTANCE_INCORP_CHILD_MD_HL,              I"^incorp_child")
			H_C_U(INSTANCE_MAP_MD_HL,                       I"^map")
			H_C_U(INSTANCE_USAGES_MD_HL,                    I"^usages")
			H_C_U(INSTANCE_BRIEF_INFERENCES_MD_HL,          I"^brief_inferences")
			H_C_U(INSTANCE_SPECIFIC_INFERENCES_MD_HL,       I"^specific_inferences")
			H_C_U(INSTANCE_HL,                              I"I")
			H_F_U(SCENE_STATUS_FN_HL,                       I"scene_status_fn")
			H_F_U(SCENE_CHANGE_FN_HL,                       I"scene_change_fn")
			H_F_U(BACKDROP_FOUND_IN_FN_HL,                  I"backdrop_found_in_fn")
			H_F_G(SHORT_NAME_FN_HL,                         I"short_name_fn", I"SN_R")
			H_F_G(SHORT_NAME_PROPERTY_FN_HL,                I"short_name_property_fn", I"SN_R_A")
			H_F_G(REGION_FOUND_IN_FN_HL,                    I"region_found_in_fn", I"RFI_for_I")
			H_F_G(TSD_DOOR_DIR_FN_HL,                       I"tsd_door_dir_fn", I"TSD_door_dir_value")
			H_F_G(TSD_DOOR_TO_FN_HL,                        I"tsd_door_to_fn", I"TSD_door_to_value")
			H_C_U(INSTANCE_IS_DB_MD_HL,                     I"^is_dialogue_beat")
			H_C_U(INSTANCE_IS_DL_MD_HL,                     I"^is_dialogue_line")
			H_C_U(INSTANCE_IS_DC_MD_HL,                     I"^is_dialogue_choice")
			H_C_U(BEAT_ARRAY_MD_HL,                         I"^beat_data")
			H_C_U(BEAT_ARRAY_HL,                            I"beat_data")
			H_F_U(BEAT_AVAILABLE_FN_HL,                     I"available_fn")
			H_F_U(BEAT_RELEVANT_FN_HL,                      I"relevant_fn")
			H_C_U(BEAT_STRUCTURE_HL,                        I"structure")
			H_C_U(BEAT_SPEAKERS_HL,                         I"speakers")
			H_C_U(LINE_ARRAY_MD_HL,                         I"^line_data")
			H_C_U(LINE_ARRAY_HL,                            I"line_data")
			H_F_U(LINE_AVAILABLE_FN_HL,                     I"available_fn")
			H_F_U(LINE_SPEAKER_FN_HL,                       I"speaker_fn")
			H_F_U(LINE_INTERLOCUTOR_FN_HL,                  I"interlocutor_fn")
			H_F_U(LINE_MENTIONING_FN_HL,                    I"mentioning_fn")
			H_F_U(LINE_ACTION_FN_HL,                        I"action_fn")
			H_C_U(CHOICE_ARRAY_MD_HL,                       I"^choice_data")
			H_C_U(CHOICE_ARRAY_HL,                          I"choice_data")
			H_F_U(CHOICE_AVAILABLE_FN_HL,                   I"available_fn")
			H_F_U(CHOICE_ACTION_MATCH_FN_HL,                I"action_match_fn")
			H_F_U(INST_SHOWME_FN_HL,                        I"showme_fn")
			H_BEGIN_AP(INLINE_PROPERTIES_HAP,               I"inline_property", I"_inline_property")
				H_C_U(INLINE_PROPERTY_HL,                   I"inline")
			H_END
			H_C_G(DIRECTION_HL,                             I"DirectionObject")
		H_END
	H_END

@h Interactive Fiction.

@e PLAYER_OBJECT_INIS_HL
@e START_OBJECT_INIS_HL
@e START_ROOM_INIS_HL
@e START_TIME_INIS_HL
@e START_BEAT_INIS_HL
@e DONE_INIS_HL

@e NO_DIRECTIONS_HL
@e MAP_STORAGE_HL
@e INITIALSITUATION_HL

@<Establish int-fiction@> =
	submodule_identity *interactive_fiction = LargeScale::register_submodule_identity(I"interactive_fiction");

	H_BEGIN(LocationRequirements::generic_submodule(I, interactive_fiction))
		H_C_T(PLAYER_OBJECT_INIS_HL,          I"PLAYER_OBJECT_INIS")
		H_C_T(START_OBJECT_INIS_HL,           I"START_OBJECT_INIS")
		H_C_T(START_ROOM_INIS_HL,             I"START_ROOM_INIS")
		H_C_T(START_TIME_INIS_HL,             I"START_TIME_INIS")
		H_C_T(START_BEAT_INIS_HL,             I"START_BEAT_INIS")
		H_C_T(DONE_INIS_HL,                   I"DONE_INIS")
	H_END

	H_BEGIN(LocationRequirements::completion_submodule(I, interactive_fiction))
		H_C_T(NO_DIRECTIONS_HL,               I"No_Directions")
		H_C_T(MAP_STORAGE_HL,                 I"Map_Storage")
		H_C_T(INITIALSITUATION_HL,            I"InitialSituation")
	H_END

@h Internal files.

@e INTERNAL_FILES_HAP
@e INTERNAL_FILE_HL

@<Establish internal files@> =
	submodule_identity *internal_files = LargeScale::register_submodule_identity(I"internal_files");

	H_BEGIN(LocationRequirements::local_submodule(internal_files))
		H_BEGIN_AP(INTERNAL_FILES_HAP,        I"internal_file", I"_internal_file")
			H_C_U(INTERNAL_FILE_HL,           I"file")
		H_END
	H_END

@h Kinds.

@e K_UNCHECKED_HL
@e K_UNCHECKED_FUNCTION_HL
@e K_UNCHECKED_LIST_HL
@e K_INT32_HL
@e K_INT2_HL
@e K_STRING_HL

@e KIND_HAP
@e KIND_NAME_MD_HL
@e KIND_SOURCE_ORDER_MD_HL
@e KIND_DECLARATION_ORDER_MD_HL
@e KIND_SPECIFICATION_MD_HL
@e KIND_AT_MD_HL
@e KIND_CLASS_MD_HL
@e KIND_PNAME_MD_HL
@e KIND_INDEX_VARIANCE_MD_HL
@e KIND_INDEX_SINGULAR_MD_HL
@e KIND_INDEX_PLURAL_MD_HL
@e KIND_SHOWME_MD_HL
@e KIND_IS_BASE_MD_HL
@e KIND_IS_PROPER_MD_HL
@e KIND_IS_QUASINUMERICAL_MD_HL
@e KIND_IS_DEF_MD_HL
@e KIND_IS_OBJECT_MD_HL
@e INDEX_SUPERKIND_MD_HL
@e KIND_IS_SKOO_MD_HL
@e KIND_HAS_BV_MD_HL
@e KIND_WEAK_ID_MD_HL
@e KIND_STRONG_ID_MD_HL
@e KIND_PRINT_FN_MD_HL
@e KIND_CMP_FN_MD_HL
@e KIND_SUPPORT_FN_MD_HL
@e KIND_MKDEF_FN_MD_HL
@e KIND_DSIZE_MD_HL
@e KIND_DOCUMENTATION_MD_HL
@e KIND_INDEX_PRIORITY_MD_HL
@e SUPERKIND_MD_HL
@e RUCKSACK_CLASS_MD_HL
@e MIN_VAL_INDEX_MD_HL
@e MAX_VAL_INDEX_MD_HL
@e KIND_INDEX_NOTATION_MD_HL
@e DIMENSIONS_INDEX_MD_HL
@e KIND_SHADED_MD_HL
@e KIND_FINITE_DOMAIN_MD_HL
@e KIND_HAS_PROPERTIES_MD_HL
@e KIND_UNDERSTANDABLE_MD_HL
@e KIND_INDEX_DEFAULT_MD_HL
@e KIND_INSTANCE_COUNT_MD_HL
@e KIND_INFERENCES_MD_HL
@e KIND_BRIEF_INFERENCES_MD_HL
@e WEAK_ID_HL
@e ICOUNT_HL
@e FWMATRIX_SIZE_HL
@e NUM_DOORS_HL
@e NUM_ROOMS_HL
@e ENUMERATION_ARRAY_MD_HL
@e KIND_XREF_SYMBOL_HL
@e DECREMENT_FN_HL
@e INCREMENT_FN_HL
@e PRINT_FN_HL
@e PRINT_DASH_FN_HL
@e MKDEF_FN_HL
@e RANGER_FN_HL
@e INDEXING_FN_HL
@e DEFAULT_CLOSURE_FN_HL
@e GPR_FN_HL
@e SHOWME_FN_HL
@e INSTANCE_GPR_FN_HL
@e INSTANCE_LIST_HL
@e FIRST_INSTANCE_HL
@e INSTANCES_ARRAY_HL
@e NEXT_INSTANCE_HL
@e BASE_IK_1_HL
@e BASE_IK_2_HL
@e BASE_IK_3_HL
@e BASE_IK_4_HL
@e BASE_IK_5_HL
@e BASE_IK_6_HL
@e BASE_IK_7_HL
@e BASE_IK_8_HL
@e BASE_IK_9_HL
@e BASE_IK_10_HL
@e BASE_IK_HL
@e KIND_INLINE_PROPERTIES_HAP
@e KIND_INLINE_PROPERTY_HL
@e KIND_PROPERTIES_HAP

@e KIND_CONFORMANCE_HAP
@e CONFORMED_TO_MD_HL

@e DERIVED_KIND_HAP
@e DK_NEEDED_MD_HL
@e DK_STRONG_ID_HL
@e DK_KIND_HL
@e DK_DEFAULT_VALUE_HL

@e KIND_CLASS_HL

@e MULTIPLICATION_RULE_HAP
@e SET_AT_MD_HL
@e LEFT_OPERAND_MD_HL
@e RIGHT_OPERAND_MD_HL
@e RESULT_MD_HL
@e LEFT_OPERAND_BM_MD_HL
@e RIGHT_OPERAND_BM_MD_HL
@e RESULT_BM_MD_HL

@<Establish kinds@> =
	submodule_identity *kinds = LargeScale::register_submodule_identity(I"kinds");

	H_BEGIN(LocationRequirements::generic_submodule(I, kinds))
		H_C_T(K_UNCHECKED_HL,                 I"K_unchecked")
		H_C_T(K_UNCHECKED_FUNCTION_HL,        I"K_unchecked_function")
		H_C_T(K_UNCHECKED_LIST_HL,            I"K_unchecked_list")
		H_C_T(K_INT32_HL,                     I"K_int32")
		H_C_T(K_INT2_HL,                      I"K_int2")
		H_C_T(K_STRING_HL,                    I"K_string")
	H_END

	H_BEGIN(LocationRequirements::local_submodule(kinds))
		H_BEGIN_AP(KIND_HAP,                  I"kind", I"_kind")
			H_C_U(KIND_NAME_MD_HL,            I"^name")
			H_C_U(KIND_SOURCE_ORDER_MD_HL,    I"^source_order")
			H_C_U(KIND_DECLARATION_ORDER_MD_HL, I"^declaration_order")
			H_C_U(KIND_SPECIFICATION_MD_HL,   I"^specification")
			H_C_U(KIND_AT_MD_HL,              I"^at")
			H_C_U(KIND_CLASS_MD_HL,           I"^object_class")
			H_C_U(KIND_PNAME_MD_HL,           I"^printed_name")
			H_C_U(KIND_INDEX_SINGULAR_MD_HL,  I"^index_singular")
			H_C_U(KIND_INDEX_PLURAL_MD_HL,    I"^index_plural")
			H_C_U(KIND_INDEX_VARIANCE_MD_HL,  I"^variance")
			H_C_U(KIND_SHOWME_MD_HL,          I"^showme_fn")
			H_C_U(KIND_IS_BASE_MD_HL,         I"^is_base")
			H_C_U(KIND_IS_PROPER_MD_HL,       I"^is_proper")
			H_C_U(KIND_IS_QUASINUMERICAL_MD_HL, I"^is_quasinumerical")
			H_C_U(KIND_IS_DEF_MD_HL,          I"^is_definite")
			H_C_U(KIND_IS_OBJECT_MD_HL,       I"^is_object")
			H_C_U(KIND_IS_SKOO_MD_HL,         I"^is_subkind_of_object")
			H_C_U(INDEX_SUPERKIND_MD_HL,      I"^index_superkind")
			H_C_U(KIND_HAS_BV_MD_HL,          I"^has_block_values")
			H_C_U(KIND_WEAK_ID_MD_HL,         I"^weak_id")
			H_C_U(KIND_STRONG_ID_MD_HL,       I"^strong_id")
			H_C_U(KIND_CMP_FN_MD_HL,          I"^cmp_fn")
			H_C_U(KIND_PRINT_FN_MD_HL,        I"^print_fn")
			H_C_U(KIND_SUPPORT_FN_MD_HL,      I"^support_fn")
			H_C_U(KIND_MKDEF_FN_MD_HL,        I"^mkdef_fn")
			H_C_U(KIND_DSIZE_MD_HL,           I"^domain_size")
			H_C_U(RUCKSACK_CLASS_MD_HL,       I"^rucksack_class")
			H_C_U(MIN_VAL_INDEX_MD_HL,        I"^min_value")
			H_C_U(MAX_VAL_INDEX_MD_HL,        I"^max_value")
			H_C_U(KIND_INDEX_NOTATION_MD_HL,  I"^notation")
			H_C_U(DIMENSIONS_INDEX_MD_HL,     I"^dimensions")
			H_C_U(KIND_DOCUMENTATION_MD_HL,   I"^documentation")
			H_C_U(KIND_INDEX_PRIORITY_MD_HL,  I"^index_priority")
			H_C_U(SUPERKIND_MD_HL,            I"^superkind")
			H_C_U(KIND_SHADED_MD_HL,          I"^shaded_in_index")
			H_C_U(KIND_FINITE_DOMAIN_MD_HL,   I"^finite_domain")
			H_C_U(KIND_HAS_PROPERTIES_MD_HL,  I"^has_properties")
			H_C_U(KIND_UNDERSTANDABLE_MD_HL,  I"^understandable")
			H_C_U(KIND_INDEX_DEFAULT_MD_HL,   I"^index_default")
			H_C_U(KIND_INSTANCE_COUNT_MD_HL,  I"^instance_count")
			H_C_U(KIND_BRIEF_INFERENCES_MD_HL, I"^brief_inferences")
			H_C_U(KIND_INFERENCES_MD_HL,      I"^inferences")
			H_C_I(WEAK_ID_HL)
			H_C_I(ICOUNT_HL)
			H_C_U(ENUMERATION_ARRAY_MD_HL,    I"^enumeration_array")
			H_C_U(FWMATRIX_SIZE_HL,           I"FWMATRIX_SIZE")
			H_C_U(NUM_DOORS_HL,               I"NUM_DOORS")
			H_C_U(NUM_ROOMS_HL,               I"NUM_ROOMS")
			H_C_U(KIND_XREF_SYMBOL_HL,        I"kind_ref")
			H_F_U(MKDEF_FN_HL,                I"mkdef_fn")
			H_F_U(DECREMENT_FN_HL,            I"decrement_fn")
			H_F_U(INCREMENT_FN_HL,            I"increment_fn")
			H_F_U(PRINT_FN_HL,                I"print_fn")
			H_F_G(PRINT_DASH_FN_HL,           I"print_fn", I"E")
			H_F_U(RANGER_FN_HL,               I"ranger_fn")
			H_F_U(INDEXING_FN_HL,             I"indexing_fn")
			H_F_U(DEFAULT_CLOSURE_FN_HL,      I"default_closure_fn")
			H_F_U(GPR_FN_HL,                  I"gpr_fn")
			H_F_U(INSTANCE_GPR_FN_HL,         I"instance_gpr_fn")
			H_C_U(INSTANCE_LIST_HL,           I"instance_list")
			H_F_U(SHOWME_FN_HL,               I"showme_fn")
			H_C_S(FIRST_INSTANCE_HL,          I"_First")
			H_C_S(NEXT_INSTANCE_HL,           I"_Next")
			H_C_S(INSTANCES_ARRAY_HL,         I"_Array")
			H_C_T(BASE_IK_1_HL,               I"IK1_Count")
			H_C_T(BASE_IK_2_HL,               I"IK2_Count")
			H_C_T(BASE_IK_3_HL,               I"IK3_Count")
			H_C_T(BASE_IK_4_HL,               I"IK4_Count")
			H_C_T(BASE_IK_5_HL,               I"IK5_Count")
			H_C_T(BASE_IK_6_HL,               I"IK6_Count")
			H_C_T(BASE_IK_7_HL,               I"IK7_Count")
			H_C_T(BASE_IK_8_HL,               I"IK8_Count")
			H_C_T(BASE_IK_9_HL,               I"IK9_Count")
			H_C_T(BASE_IK_10_HL,              I"IK10_Count")
			H_C_S(BASE_IK_HL,                 I"_Count")
			H_C_G(KIND_CLASS_HL,              I"K")
			H_BEGIN_AP(KIND_INLINE_PROPERTIES_HAP, I"inline_property", I"_inline_property")
				H_C_U(KIND_INLINE_PROPERTY_HL, I"inline")
			H_END
			H_BEGIN_AP(KIND_CONFORMANCE_HAP,  I"conformance", I"_conformance")
				H_C_U(CONFORMED_TO_MD_HL,     I"^conformed_to")
			H_END
		H_END
		H_BEGIN_AP(DERIVED_KIND_HAP,          I"derived_kind", I"_derived_kind")
			H_C_U(DK_NEEDED_MD_HL,            I"^default_value_needed")
			H_C_U(DK_STRONG_ID_HL,            I"strong_id")
			H_C_G(DK_KIND_HL,                 I"DK")
			H_C_U(DK_DEFAULT_VALUE_HL,        I"default_value")
		H_END
		H_BEGIN_AP(KIND_PROPERTIES_HAP,       I"property", I"_property")
		H_END
	H_END

	H_BEGIN(LocationRequirements::completion_submodule(I, kinds))
		H_BEGIN_AP(MULTIPLICATION_RULE_HAP,   I"multiplication_rule", I"_multiplication_rule")
			H_C_U(SET_AT_MD_HL,               I"^at")
			H_C_U(LEFT_OPERAND_MD_HL,         I"^left_operand")
			H_C_U(RIGHT_OPERAND_MD_HL,        I"^right_operand")
			H_C_U(RESULT_MD_HL,               I"^result")
			H_C_U(LEFT_OPERAND_BM_MD_HL,      I"^left_operand_benchmark")
			H_C_U(RIGHT_OPERAND_BM_MD_HL,     I"^right_operand_benchmark")
			H_C_U(RESULT_BM_MD_HL,            I"^result_benchmark")
		H_END
	H_END

@h Literal patterns.

@e LITERAL_PATTERNS_HAP
@e LP_PRINT_FN_HL
@e LP_PARSE_FN_HL

@<Establish literal patterns@> =
	submodule_identity *literals = LargeScale::register_submodule_identity(I"literal_patterns");

	H_BEGIN(LocationRequirements::local_submodule(literals))
		H_BEGIN_AP(LITERAL_PATTERNS_HAP,      I"literal_pattern", I"_literal_pattern")
			H_F_U(LP_PRINT_FN_HL,             I"print_fn")
			H_F_U(LP_PARSE_FN_HL,             I"parse_fn")
		H_END
	H_END

@h Mapping hints.

@e MAPPING_HINTS_HAP
@e MH_FROM_HL
@e MH_TO_HL
@e MH_DIR_HL
@e MH_AS_DIR_HL
@e MH_NAME_HL
@e MH_SCOPE_LEVEL_HL
@e MH_SCOPE_INSTANCE_HL
@e MH_TEXT_HL
@e MH_NUMBER_HL
@e MH_ANNOTATION_HL
@e MH_POINT_SIZE_HL
@e MH_FONT_HL
@e MH_COLOUR_HL
@e MH_OFFSET_HL
@e MH_OFFSET_FROM_HL

@<Establish mapping hints@> =
	submodule_identity *hints = LargeScale::register_submodule_identity(I"mapping_hints");

	H_BEGIN(LocationRequirements::completion_submodule(I, hints))
		H_BEGIN_AP(MAPPING_HINTS_HAP,      I"mapping_hint", I"_mapping_hint")
			H_C_U(MH_FROM_HL,              I"^from")
			H_C_U(MH_TO_HL,                I"^to")
			H_C_U(MH_DIR_HL,               I"^dir")
			H_C_U(MH_AS_DIR_HL,            I"^as_dir")
			H_C_U(MH_NAME_HL,              I"^name")
			H_C_U(MH_SCOPE_LEVEL_HL,       I"^scope_level")
			H_C_U(MH_SCOPE_INSTANCE_HL,    I"^scope_instance")
			H_C_U(MH_TEXT_HL,              I"^text")
			H_C_U(MH_NUMBER_HL,            I"^number")
			H_C_U(MH_ANNOTATION_HL,        I"^annotation")
			H_C_U(MH_POINT_SIZE_HL,        I"^point_size")
			H_C_U(MH_FONT_HL,              I"^font")
			H_C_U(MH_COLOUR_HL,            I"^colour")
			H_C_U(MH_OFFSET_HL,            I"^offset")
			H_C_U(MH_OFFSET_FROM_HL,       I"^offset_from")
		H_END
	H_END

@h Phrases.

@e CLOSURES_HAP
@e CLOSURE_DATA_HL
@e PHRASES_HAP
@e REQUESTS_HAP
@e PHRASE_SYNTAX_MD_HL
@e PHRASE_FN_HL
@e LABEL_STORAGES_HAP
@e LABEL_ASSOCIATED_STORAGE_HL
@e PHRASEBOOK_SUPER_HEADING_HAP
@e PHRASEBOOK_SUPER_HEADING_TEXT_MD_HL
@e PHRASEBOOK_HEADING_HAP
@e PHRASEBOOK_HEADING_TEXT_MD_HL
@e PHRASEBOOK_ENTRY_HAP
@e PHRASEBOOK_ENTRY_TEXT_MD_HL

@<Establish phrases@> =
	submodule_identity *phrases = LargeScale::register_submodule_identity(I"phrases");

	H_BEGIN(LocationRequirements::local_submodule(phrases))
		H_BEGIN_AP(PHRASES_HAP,               I"phrase", I"_to_phrase")
			H_BEGIN_AP(CLOSURES_HAP,          I"closure", I"_closure")
				H_C_U(CLOSURE_DATA_HL,        I"closure_data")
			H_END
			H_BEGIN_AP(REQUESTS_HAP,          I"request", I"_request")
				H_C_U(PHRASE_SYNTAX_MD_HL,    I"^phrase_syntax")
				H_F_U(PHRASE_FN_HL,           I"phrase_fn")
			H_END
		H_END
	H_END

	H_BEGIN(LocationRequirements::any_enclosure())
		H_BEGIN_AP(LABEL_STORAGES_HAP,        I"label_storage", I"_label_storage")
			H_C_U(LABEL_ASSOCIATED_STORAGE_HL, I"label_associated_storage")
		H_END
	H_END

	H_BEGIN(LocationRequirements::completion_submodule(I, phrases))
		H_BEGIN_AP(PHRASEBOOK_SUPER_HEADING_HAP,       I"phrasebook_super_heading", I"_phrasebook_super_heading")
			H_C_U(PHRASEBOOK_SUPER_HEADING_TEXT_MD_HL, I"^text")
			H_BEGIN_AP(PHRASEBOOK_HEADING_HAP,         I"phrasebook_heading", I"_phrasebook_heading")
				H_C_U(PHRASEBOOK_HEADING_TEXT_MD_HL,   I"^text")
				H_BEGIN_AP(PHRASEBOOK_ENTRY_HAP,       I"phrasebook_entry", I"_phrasebook_entry")
					H_C_U(PHRASEBOOK_ENTRY_TEXT_MD_HL, I"^text")
				H_END
			H_END
		H_END
	H_END

@h Properties.

@e PROPERTIES_HAP
@e PROPERTY_NAME_MD_HL
@e PROPERTY_ORDER_MD_HL
@e PROPERTY_ID_HL
@e PROPERTY_HL

@<Establish properties@> =
	submodule_identity *properties = LargeScale::register_submodule_identity(I"properties");

	H_BEGIN(LocationRequirements::local_submodule(properties))
		H_BEGIN_AP(PROPERTIES_HAP,            I"property", I"_property")
			H_C_U(PROPERTY_NAME_MD_HL,        I"^name")
			H_C_U(PROPERTY_ORDER_MD_HL,       I"^source_order")
			H_C_U(PROPERTY_ID_HL,             I"property_id")
			H_C_T(PROPERTY_HL,                I"P")
		H_END
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
@e RELATION_NAME_MD_HL
@e RELATION_DESCRIPTION_MD_HL
@e RELATION_AT_MD_HL
@e RELATION_TERM0_MD_HL
@e RELATION_TERM1_MD_HL
@e RELATION_VALUE_MD_HL
@e RELATION_CREATOR_MD_HL
@e RELATION_ID_HL
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
@e RELATION_CREATOR_FN_HL

@<Establish relations@> =
	submodule_identity *relations = LargeScale::register_submodule_identity(I"relations");

	H_BEGIN(LocationRequirements::generic_submodule(I, relations))
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

	H_BEGIN(LocationRequirements::local_submodule(relations))
		H_BEGIN_AP(RELATIONS_HAP,             I"relation", I"_relation")
			H_C_U(RELATION_NAME_MD_HL,        I"^name")
			H_C_U(RELATION_AT_MD_HL,          I"^at")
			H_C_U(RELATION_DESCRIPTION_MD_HL, I"^description")
			H_C_U(RELATION_TERM0_MD_HL,       I"^term0")
			H_C_U(RELATION_TERM1_MD_HL,       I"^term1")
			H_C_U(RELATION_VALUE_MD_HL,       I"^value")
			H_C_U(RELATION_CREATOR_MD_HL,     I"^creator")
			H_C_U(RELATION_ID_HL,             I"relation_id")
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
			H_F_U(RELATION_CREATOR_FN_HL,     I"creator_fn")
		H_END
	H_END

@h Rulebooks.

@e RBNO4_INAME_HL
@e RBNO3_INAME_HL
@e RBNO2_INAME_HL
@e RBNO1_INAME_HL
@e RBNO0_INAME_HL

@e OUTCOMES_HAP
@e OUTCOME_NAME_MD_HL
@e OUTCOME_HL
@e RULEBOOKS_HAP
@e RULEBOOK_AT_MD_HL
@e RULEBOOK_NAME_MD_HL
@e RULEBOOK_PNAME_MD_HL
@e RULEBOOK_VARC_MD_HL
@e RULEBOOK_INDEX_ID_MD_HL
@e RULEBOOK_RUN_FN_MD_HL
@e RULEBOOK_ID_HL
@e RULEBOOK_TRANS_ID_HL
@e RULEBOOK_FOCUS_MD_HL
@e RUN_FN_HL
@e RULEBOOK_STV_CREATOR_FN_HL
@e RULEBOOK_ENTRIES_HAP
@e RULE_ENTRY_MD_HL
@e TOOLTIP_TEXT_MD_HL
@e NEXT_RULE_SPECIFICITY_MD_HL
@e LAW_APPLIED_MD_HL
@e BRULE_NAME_MD_HL
@e RULE_INDEX_NAME_MD_HL
@e RULE_FIRST_LINE_MD_HL
@e RULE_INDEX_NUMBER_MD_HL
@e BRULE_AT_MD_HL
@e RULE_DURING_MD_HL
@e RULE_DURING_TEXT_MD_HL
@e RULE_ACTION_RELEVANCES_HAP
@e RULE_ACTION_RELEVANCE_MD_HL
@e RULEBOOK_PLACEMENTS_HAP
@e PLACEMENT_TEXT_MD_HL
@e PLACEMENT_AT_MD_HL
@e RULEBOOK_AUTOMATIC_MD_HL
@e RULEBOOK_DEFAULT_SUCCEEDS_MD_HL
@e RULEBOOK_DEFAULT_FAILS_MD_HL
@e RULEBOOK_OUTCOMES_HAP
@e OUTCOME_TEXT_MD_HL
@e OUTCOME_SUCCEEDS_MD_HL
@e OUTCOME_FAILS_MD_HL
@e OUTCOME_IS_DEFAULT_MD_HL

@<Establish rulebooks@> =
	submodule_identity *rulebooks = LargeScale::register_submodule_identity(I"rulebooks");

	H_BEGIN(LocationRequirements::local_submodule(rulebooks))
		H_BEGIN_AP(OUTCOMES_HAP,                       I"rulebook_outcome", I"_outcome")
			H_C_U(OUTCOME_NAME_MD_HL,                  I"^name")
			H_C_U(OUTCOME_HL,                          I"outcome")
			H_C_U(RBNO4_INAME_HL,                      I"RBNO4_OUTCOME")
			H_C_U(RBNO3_INAME_HL,                      I"RBNO3_OUTCOME")
			H_C_U(RBNO2_INAME_HL,                      I"RBNO2_OUTCOME")
			H_C_U(RBNO1_INAME_HL,                      I"RBNO1_OUTCOME")
			H_C_U(RBNO0_INAME_HL,                      I"RBNO0_OUTCOME")
		H_END
		H_BEGIN_AP(RULEBOOKS_HAP,                      I"rulebook", I"_rulebook")
			H_C_U(RULEBOOK_AT_MD_HL,                   I"^at")
			H_C_U(RULEBOOK_NAME_MD_HL,                 I"^name")
			H_C_U(RULEBOOK_PNAME_MD_HL,                I"^printed_name")
			H_C_U(RULEBOOK_RUN_FN_MD_HL,               I"^run_fn")
			H_C_U(RULEBOOK_VARC_MD_HL,                 I"^var_creator")
			H_C_U(RULEBOOK_INDEX_ID_MD_HL,             I"^index_id")
			H_C_U(RULEBOOK_FOCUS_MD_HL,                I"^focus")
			H_C_U(RULEBOOK_ID_HL,                      I"rulebook_id")
			H_C_U(RULEBOOK_TRANS_ID_HL,                I"translated_rulebook_id")
			H_F_U(RUN_FN_HL,                           I"run_fn")
			H_F_U(RULEBOOK_STV_CREATOR_FN_HL,          I"stv_creator_fn")
			H_BEGIN_AP(RULEBOOK_ENTRIES_HAP,           I"entry", I"_rulebook_entry")
				H_C_U(RULE_ENTRY_MD_HL,                I"^rule")
				H_C_U(TOOLTIP_TEXT_MD_HL,              I"^tooltip")
				H_C_U(NEXT_RULE_SPECIFICITY_MD_HL,     I"^specificity")
				H_C_U(LAW_APPLIED_MD_HL,               I"^law")
				H_C_U(BRULE_NAME_MD_HL,                I"^name")
				H_C_U(RULE_INDEX_NAME_MD_HL,           I"^index_name")
				H_C_U(RULE_FIRST_LINE_MD_HL,           I"^first_line")
				H_C_U(RULE_INDEX_NUMBER_MD_HL,         I"^index_number")
				H_C_U(BRULE_AT_MD_HL,                  I"^at")
				H_C_U(RULE_DURING_MD_HL,               I"^during")
				H_C_U(RULE_DURING_TEXT_MD_HL,          I"^during_text")
				H_BEGIN_AP(RULE_ACTION_RELEVANCES_HAP, I"relevant_action", I"_relevant_action")
					H_C_U(RULE_ACTION_RELEVANCE_MD_HL, I"^action")
				H_END
			H_END
			H_BEGIN_AP(RULEBOOK_PLACEMENTS_HAP,        I"placement", I"_rulebook_placement")
				H_C_U(PLACEMENT_TEXT_MD_HL,            I"^text")
				H_C_U(PLACEMENT_AT_MD_HL,              I"^at")
			H_END
			H_C_U(RULEBOOK_AUTOMATIC_MD_HL,            I"^automatically_generated")
			H_C_U(RULEBOOK_DEFAULT_SUCCEEDS_MD_HL,     I"^default_succeeds")
			H_C_U(RULEBOOK_DEFAULT_FAILS_MD_HL,        I"^default_fails")
			H_BEGIN_AP(RULEBOOK_OUTCOMES_HAP,          I"outcome", I"_rulebook_outcome")
				H_C_U(OUTCOME_TEXT_MD_HL,              I"^text")
				H_C_U(OUTCOME_SUCCEEDS_MD_HL,          I"^succeeds")
				H_C_U(OUTCOME_FAILS_MD_HL,             I"^fails")
				H_C_U(OUTCOME_IS_DEFAULT_MD_HL,        I"^is_default")
			H_END
		H_END
	H_END

@h Rules.

@e RULES_HAP
@e RULE_ANCHOR_HL
@e RULE_NAME_MD_HL
@e RULE_PREAMBLE_MD_HL
@e RULE_PNAME_MD_HL
@e RULE_AT_MD_HL
@e RULE_VALUE_MD_HL
@e RULE_TIMED_MD_HL
@e RULE_TIMED_FOR_MD_HL
@e TIMED_RULE_TRIGGER_HAP
@e RULE_USED_AT_MD_HL
@e SHELL_FN_HL
@e RULE_FN_HL
@e EXTERIOR_RULE_HL
@e RESPONDER_FN_HL
@e RESPONSES_HAP
@e AS_CONSTANT_HL
@e AS_BLOCK_CONSTANT_HL
@e LAUNCHER_HL
@e RESP_VALUE_MD_HL
@e RULE_MD_HL
@e MARKER_MD_HL
@e INDEX_TEXT_MD_HL
@e GROUP_HL
@e RULE_APPLICABILITY_CONDITIONS_HAP
@e AC_TEXT_MD_HL
@e AC_AT_MD_HL

@<Establish rules@> =
	submodule_identity *rules = LargeScale::register_submodule_identity(I"rules");

	H_BEGIN(LocationRequirements::local_submodule(rules))
		H_BEGIN_AP(RULES_HAP,                 I"rule", I"_rule")
			H_C_U(RULE_ANCHOR_HL,             I"anchor")
			H_C_U(RULE_NAME_MD_HL,            I"^name")
			H_C_U(RULE_PREAMBLE_MD_HL,        I"^preamble")
			H_C_U(RULE_PNAME_MD_HL,           I"^printed_name")
			H_C_U(RULE_AT_MD_HL,              I"^at")			
			H_C_U(RULE_VALUE_MD_HL,           I"^value")
			H_C_U(RULE_TIMED_MD_HL,           I"^timed")
			H_C_U(RULE_TIMED_FOR_MD_HL,       I"^timed_for")
			H_BEGIN_AP(TIMED_RULE_TRIGGER_HAP, I"timed_rule_trigger", I"_timed_rule_trigger")
				H_C_U(RULE_USED_AT_MD_HL,     I"^used_at")
			H_END
			H_F_U(SHELL_FN_HL,                I"shell_fn")
			H_F_U(RULE_FN_HL,                 I"rule_fn")
			H_C_U(EXTERIOR_RULE_HL,           I"exterior_rule")
			H_F_S(RESPONDER_FN_HL,            I"responder_fn", I"M")
			H_BEGIN_AP(RESPONSES_HAP,         I"response", I"_response")
				H_C_U(RESP_VALUE_MD_HL,       I"^value")
				H_C_U(RULE_MD_HL,             I"^rule")
				H_C_U(MARKER_MD_HL,           I"^marker")
				H_C_U(INDEX_TEXT_MD_HL,       I"^index_text")
				H_C_U(GROUP_HL,               I"^group")
				H_C_U(AS_CONSTANT_HL,         I"response_id")
				H_C_U(AS_BLOCK_CONSTANT_HL,   I"as_block_constant")
				H_F_U(LAUNCHER_HL,            I"launcher")
			H_END
			H_BEGIN_AP(RULE_APPLICABILITY_CONDITIONS_HAP, I"applicability_condition", I"_applicability_condition")
				H_C_U(AC_TEXT_MD_HL,          I"^text")
				H_C_U(AC_AT_MD_HL,            I"^at")
			H_END
		H_END
	H_END

@h Tables.

@e TABLES_HAP
@e TABLE_NAME_MD_HL
@e TABLE_PNAME_MD_HL
@e TABLE_VALUE_MD_HL
@e RANKING_TABLE_MD_HL
@e TABLE_ROWS_MD_HL
@e TABLE_BLANK_ROWS_MD_HL
@e TABLE_BLANK_ROWS_FOR_MD_HL
@e TABLE_DEFINES_MD_HL
@e TABLE_DEFINES_TEXT_MD_HL
@e TABLE_DEFINES_AT_MD_HL
@e TABLE_ID_HL
@e TABLE_DATA_HL
@e TABLE_COLUMN_USAGES_HAP
@e COLUMN_DATA_HL
@e COLUMN_IDENTITY_HL
@e COLUMN_BITS_HL
@e COLUMN_BLANKS_HL
@e COLUMN_BLANK_DATA_HL
@e TABLE_CONTRIBUTION_HAP
@e TABLE_CONTRIBUTION_AT_MD_HL

@e TABLE_COLUMNS_HAP
@e TABLE_COLUMN_ID_HL
@e TABLE_COLUMN_NAME_MD_HL
@e TABLE_COLUMN_CONTENTS_MD_HL
@e TABLE_COLUMN_KIND_MD_HL

@<Establish tables@> =
	submodule_identity *tables = LargeScale::register_submodule_identity(I"tables");

	H_BEGIN(LocationRequirements::local_submodule(tables))
		H_BEGIN_AP(TABLES_HAP,                I"table", I"_table")
			H_C_U(TABLE_NAME_MD_HL,           I"^name")
			H_C_U(TABLE_PNAME_MD_HL,          I"^printed_name")
			H_C_U(TABLE_VALUE_MD_HL,          I"^value")
			H_C_U(RANKING_TABLE_MD_HL,        I"^ranking_table")
			H_C_U(TABLE_ROWS_MD_HL,           I"^rows")
			H_C_U(TABLE_BLANK_ROWS_MD_HL,     I"^blank_rows")
			H_C_U(TABLE_BLANK_ROWS_FOR_MD_HL, I"^blank_rows_for_each")
			H_C_U(TABLE_DEFINES_MD_HL,        I"^defines")
			H_C_U(TABLE_DEFINES_TEXT_MD_HL,   I"^defines_text")
			H_C_U(TABLE_DEFINES_AT_MD_HL,     I"^defines_at")
			H_C_U(TABLE_ID_HL,                I"table_id")
			H_C_U(TABLE_DATA_HL,              I"table_data")
			H_BEGIN_AP(TABLE_COLUMN_USAGES_HAP, I"column", I"_table_column_usage")
				H_C_U(COLUMN_DATA_HL,         I"column_data")
				H_C_U(COLUMN_IDENTITY_HL,     I"column_identity")
				H_C_U(COLUMN_BITS_HL,         I"column_bits")
				H_C_U(COLUMN_BLANKS_HL,       I"column_blanks")
				H_C_U(COLUMN_BLANK_DATA_HL,   I"^column_blank_data")
			H_END
			H_BEGIN_AP(TABLE_CONTRIBUTION_HAP, I"contribution", I"_table_contribution")
				H_C_U(TABLE_CONTRIBUTION_AT_MD_HL, I"^at")
			H_END
		H_END
	H_END

	submodule_identity *table_columns = LargeScale::register_submodule_identity(I"table_columns");
	H_BEGIN(LocationRequirements::local_submodule(table_columns))
		H_BEGIN_AP(TABLE_COLUMNS_HAP,         I"table_column", I"_table_column")
			H_C_U(TABLE_COLUMN_ID_HL,         I"table_column_id")
			H_C_U(TABLE_COLUMN_NAME_MD_HL,    I"^name")
			H_C_U(TABLE_COLUMN_CONTENTS_MD_HL, I"^contents")
			H_C_U(TABLE_COLUMN_KIND_MD_HL,    I"^column_kind")
		H_END
	H_END

@h Use options.

@e USE_OPTIONS_HAP
@e USE_OPTION_MD_HL
@e USE_OPTION_PNAME_MD_HL
@e USE_OPTION_ON_MD_HL
@e USE_OPTION_USED_AT_MD_HL
@e SOURCE_FILE_SCOPED_MD_HL
@e USED_IN_SOURCE_TEXT_MD_HL
@e USED_IN_OPTIONS_MD_HL
@e USED_IN_EXTENSION_MD_HL
@e USE_OPTION_CV_MD_HL
@e USE_OPTION_ID_HL

@<Establish use options@> =
	submodule_identity *use_options = LargeScale::register_submodule_identity(I"use_options");

	H_BEGIN(LocationRequirements::local_submodule(use_options))
		H_BEGIN_AP(USE_OPTIONS_HAP,           I"use_option", I"_use_option")
			H_C_U(USE_OPTION_MD_HL,           I"^name")
			H_C_U(USE_OPTION_USED_AT_MD_HL,   I"^at")
			H_C_U(USE_OPTION_PNAME_MD_HL,     I"^printed_name")
			H_C_U(USE_OPTION_ON_MD_HL,        I"^active")
			H_C_U(SOURCE_FILE_SCOPED_MD_HL,   I"^source_file_scoped")
			H_C_U(USED_IN_SOURCE_TEXT_MD_HL,  I"^used_in_source_text")
			H_C_U(USED_IN_OPTIONS_MD_HL,      I"^used_in_options")
			H_C_U(USED_IN_EXTENSION_MD_HL,    I"^used_in_extension")
			H_C_U(USE_OPTION_CV_MD_HL,        I"^configured_value")
			H_C_U(USE_OPTION_ID_HL,           I"use_option_id")
		H_END
	H_END

@h Variables.

@e VARIABLES_HAP
@e VARIABLE_NAME_MD_HL
@e VARIABLE_AT_MD_HL
@e VARIABLE_HEADING_MD_HL
@e VARIABLE_INDEXABLE_MD_HL
@e VARIABLE_UNDERSTOOD_MD_HL
@e VARIABLE_CONTENTS_MD_HL
@e VARIABLE_DOCUMENTATION_MD_HL
@e VARIABLE_COUNTERPART_MD_HL
@e VARIABLE_HL
@e COMMANDPROMPTTEXT_HL
@e INITIAL_MAX_SCORE_HL

@<Establish variables@> =
	submodule_identity *variables = LargeScale::register_submodule_identity(I"variables");

	H_BEGIN(LocationRequirements::local_submodule(variables))
		H_BEGIN_AP(VARIABLES_HAP,             I"variable", I"_variable")
			H_C_U(VARIABLE_NAME_MD_HL,        I"^name")
			H_C_U(VARIABLE_AT_MD_HL,          I"^at")
			H_C_U(VARIABLE_HEADING_MD_HL,     I"^heading")
			H_C_U(VARIABLE_INDEXABLE_MD_HL,   I"^indexable")
			H_C_U(VARIABLE_UNDERSTOOD_MD_HL,  I"^understood")
			H_C_U(VARIABLE_CONTENTS_MD_HL,    I"^contents")
			H_C_U(VARIABLE_DOCUMENTATION_MD_HL, I"^documentation")
			H_C_U(VARIABLE_COUNTERPART_MD_HL, I"^counterpart")
			H_C_G(VARIABLE_HL,                I"V")
			H_F_T(COMMANDPROMPTTEXT_HL,       I"command_prompt_text_fn", I"CommandPromptText")
			H_C_T(INITIAL_MAX_SCORE_HL,       I"INITIAL_MAX_SCORE")
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
@e LOOPS_OVER_SCOPE_HAP
@e LOOP_OVER_SCOPE_FN_HL

@<Establish enclosed matter@> =
	H_BEGIN(LocationRequirements::any_enclosure())
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
		H_BEGIN_AP(LOOPS_OVER_SCOPE_HAP,      I"loop_over_scope", I"_loop_over_scope")
			H_F_G(LOOP_OVER_SCOPE_FN_HL,      I"loop_over_scope_fn", I"LOS")
		H_END
		H_C_U(RTP_HL,                         I"rtp")
	H_END

@

@e K_OBJECT_XPACKAGE from 0
@e K_NUMBER_XPACKAGE
@e K_TIME_XPACKAGE
@e K_TRUTH_STATE_XPACKAGE

@e CAPSHORTNAME_HL
@e DECIMAL_TOKEN_INNER_HL
@e TIME_TOKEN_INNER_HL
@e TRUTH_STATE_TOKEN_INNER_HL

@<The rest@> =
	H_BEGIN(LocationRequirements::this_exotic_package(K_OBJECT_XPACKAGE))
		H_C_T(CAPSHORTNAME_HL,                I"cap_short_name")
	H_END

	H_BEGIN(LocationRequirements::this_exotic_package(K_NUMBER_XPACKAGE))
		H_F_T(DECIMAL_TOKEN_INNER_HL,         I"gpr_fn", I"DECIMAL_TOKEN_INNER")
	H_END

	H_BEGIN(LocationRequirements::this_exotic_package(K_TIME_XPACKAGE))
		H_F_T(TIME_TOKEN_INNER_HL,            I"gpr_fn", I"TIME_TOKEN_INNER")
	H_END

	H_BEGIN(LocationRequirements::this_exotic_package(K_TRUTH_STATE_XPACKAGE))
		H_F_T(TRUTH_STATE_TOKEN_INNER_HL,     I"gpr_fn", I"TRUTH_STATE_TOKEN_INNER")
	H_END

@h Architectural symbols.
These are built-in constants (and one built-in variable, |self|) which come
from the platform we are compiling to. See //building: Large-Scale Structure//.

There are other architectural symbols besides these, but these are the only
ones which the //inform7//-compiled code needs to refer to.

@e SELF_HL
@e NULL_HL
@e MAX_POSITIVE_NUMBER_HL
@e MIN_NEGATIVE_NUMBER_HL

@<Establish architectural resources@> =
	H_BEGIN(LocationRequirements::architectural_package(I))
		H_C_T(SELF_HL,                        I"self")
		H_C_T(NULL_HL,                        I"NULL")
		H_C_T(MAX_POSITIVE_NUMBER_HL,         I"MAX_POSITIVE_NUMBER")
		H_C_T(MIN_NEGATIVE_NUMBER_HL,         I"MIN_NEGATIVE_NUMBER")
	H_END

@ Note that because these are automatically created by the building machinery
anyway, we need to make sure that a call to |Hierarchy::find| does not
create a duplicate with a name like |NULL_1|. This is a race condition, and
the easiest way to avoid it is to force the issue now:

@<Prevent architectural symbols from being doubly defined@> =
	inter_name *self_iname = Hierarchy::find(SELF_HL);
	self_iname->symbol = LargeScale::find_architectural_symbol(I, I"self");
	InterNames::to_symbol(Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
	InterNames::to_symbol(Hierarchy::find(MIN_NEGATIVE_NUMBER_HL));
	InterNames::to_symbol(Hierarchy::find(NULL_HL));

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
	location_requirement plug = LocationRequirements::plug();
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
		case K_OBJECT_XPACKAGE:            return RTKindConstructors::kind_package(K_object);
		case K_NUMBER_XPACKAGE:            return RTKindConstructors::kind_package(K_number);
		case K_TIME_XPACKAGE:              return RTKindConstructors::kind_package(K_time);
		case K_TRUTH_STATE_XPACKAGE:       return RTKindConstructors::kind_package(K_truth_state);
	}
	internal_error("unknown exotic package");
	return NULL;
}

@h Finding where to put things.
So, for example, |Hierarchy::find(ACTIVITY_VAR_CREATORS_HL)| returns the iname
at which this array should be placed, by calling, e.g., //EmitArrays::begin_word//.

=
inter_name *Hierarchy::find(int id) {
	return HierarchyLocations::iname(Emit::tree(), id);
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
	return HierarchyLocations::make_iname_in(Emit::tree(), id, P);
}

@ There are then some variations on this function. This version adds the wording |W|
to the name, just to make the Inter code more comprehensible. An example would be
|ACTIVITY_VALUE_HL|, declared abover as |H_C_G(ACTIVITY_VALUE_HL, I"V")|. The resulting name
"generated" (hence the |G| in |H_C_G|) might be, for example, |V1_starting_the_virtual_mach|.
The number |1| guarantees uniqueness; the (truncated) text following is purely for
the reader's convenience.

=
inter_name *Hierarchy::make_iname_with_memo(int id, package_request *P, wording W) {
	return HierarchyLocations::make_iname_with_memo(Emit::tree(), id, P, W);
}
inter_name *Hierarchy::make_iname_with_shorter_memo(int id, package_request *P, wording W) {
	return HierarchyLocations::make_iname_with_shorter_memo(Emit::tree(), id, P, W);
}

@ And this further elaboration supplies the number to use, in place of the |1|.
This is needed only for kinds, where the kits expect to find classes called, e.g.,
|K7_backdrop|, even though in some circumstances this may not be number |7| in
class inheritance tree order.

=
inter_name *Hierarchy::make_iname_with_memo_and_value(int id, package_request *P,
	wording W, int x) {
	inter_name *iname =
		HierarchyLocations::make_iname_with_memo_and_value(Emit::tree(), id, P, W, x);
	return iname;
}

@ When a translated name has to be generated from the name of something related to
it (e.g. by adding a prefix or suffix), the following should be used:

=
inter_name *Hierarchy::derive_iname_in(int id, inter_name *from, package_request *P) {
	return HierarchyLocations::derive_iname_in(Emit::tree(), id, from, P);
}

inter_name *Hierarchy::derive_iname_in_translating(int id, inter_name *from, package_request *P) {
	return HierarchyLocations::derive_iname_in_translating(Emit::tree(), id, from, P);
}

@ For the handful of names with "imposed translation", where the caller has to
supply the translated name, the following should be used:

=
inter_name *Hierarchy::make_iname_with_specific_translation(int id, text_stream *name,
	package_request *P) {
	return HierarchyLocations::make_iname_with_specific_translation(Emit::tree(),
		id, name, P);
}

@h Availability.
Just as the code generated by the compiler needs to be able to access code in
the kits, so also the other way around: code in a kit may need to call a
function which we're compiling. Kits can only see those inames which we "make
available", using the following, which creates a socket. Again, see
//bytecode: The Wiring// for more.

=
void Hierarchy::make_available(inter_name *iname) {
	text_stream *ma_as = InterNames::get_translation(iname);
	if (Str::len(ma_as) == 0) ma_as = InterNames::to_text(iname);
	LargeScale::package_type(Emit::tree(), I"_linkage");
	inter_symbol *S = InterNames::to_symbol(iname);
	Wiring::socket(Emit::tree(), ma_as, S);
}

void Hierarchy::make_available_one_per_name_only(inter_name *iname) {
	text_stream *ma_as = InterNames::get_translation(iname);
	if (Str::len(ma_as) == 0) ma_as = InterNames::to_text(iname);
	LargeScale::package_type(Emit::tree(), I"_linkage");
	inter_symbol *S = InterNames::to_symbol(iname);
	Wiring::socket_one_per_name_only(Emit::tree(), ma_as, S);
}

@h Adding packages at attachment points.
Consider the following example piece of declaration:
= (text as InC)
	H_BEGIN(LocationRequirements::local_submodule(kinds))
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
	module_request *M = (C) ? (CompilationUnits::to_module_package(C)) : NULL;
	return HierarchyLocations::attach_new_package(Emit::tree(), M, NULL, hap_id);
}

@ If we just want the compilation unit in which a given sentence lies:

=
package_request *Hierarchy::local_package(int hap_id) {
	return Hierarchy::local_package_to(hap_id, current_sentence);
}

package_request *Hierarchy::local_package_to(int hap_id, parse_node *at) {
	return Hierarchy::package(CompilationUnits::find(at), hap_id);
}

@ There is just one package called |synoptic|, so there's no issue of what
compilation unit is meant: that's why it's "synoptic".

=
package_request *Hierarchy::synoptic_package(int hap_id) {
	return HierarchyLocations::attach_new_package(Emit::tree(), NULL, NULL, hap_id);
}

package_request *Hierarchy::completion_package(int hap_id) {
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
	return HierarchyLocations::subpackage(Emit::tree(), id, P);
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

void Hierarchy::apply_metadata_from_filename(package_request *P, int id, filename *F) {
	TEMPORARY_TEXT(as_text)
	WRITE_TO(as_text, "%f", F);
	Hierarchy::apply_metadata(P, id, as_text);
	DISCARD_TEXT(as_text)
}

void Hierarchy::apply_metadata_from_heading(package_request *P, int id, heading *h) {
	Hierarchy::apply_metadata_from_iname(P, id, CompletionModule::heading_id(h));
}
