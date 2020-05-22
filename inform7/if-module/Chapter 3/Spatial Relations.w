[PL::SpatialRelations::] Spatial Relations.

A continuation of the Spatial plugin which defines the binary
predicates corresponding to basic spatial relationships.

@h Definitions.

@ So this section of code is all about the following:

= (early code)
/* fundamental spatial relationships */
binary_predicate *R_containment = NULL;
binary_predicate *R_support = NULL;
binary_predicate *R_incorporation = NULL;
binary_predicate *R_carrying = NULL;
binary_predicate *R_holding = NULL;
binary_predicate *R_wearing = NULL;
binary_predicate *room_containment_predicate = NULL;

/* indirect spatial relationships */
binary_predicate *R_visibility = NULL;
binary_predicate *R_touchability = NULL;
binary_predicate *R_concealment = NULL;
binary_predicate *R_enclosure = NULL;

@h Initial stock.
These relations are all hard-wired in.

=
void PL::SpatialRelations::REL_create_initial_stock(void) {
	@<Make built-in spatial relationships@>;
	@<Make built-in indirect spatial relationships@>;
	PL::MapDirections::create_relations();
	PL::Regions::create_relations();
}

@ Containment, support, incorporation, carrying, holding, wearing and
possession. The "loop parent optimisation" is explained elsewhere, but
the basic idea is that given a fixed $y$ you can search for all $x$ such
that $B(x, y)$ by looking at the object-tree children of $y$ at run-time.
On a large work of IF, this cuts the number of cases to check by a factor
of 100 or more. (But it can't be used for component parts, since those are
not stored in the I6 object tree; nor for the holding relation, since that's
a union of the others, and therefore includes incorporation.)

@<Make built-in spatial relationships@> =
	R_containment =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(NULL, NULL, EMPTY_WORDING, Calculus::Schemas::new("ContainerOf(*1)")),
			BinaryPredicates::new_term(NULL),
			I"contains", I"is-in",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, CONTAINMENT_RELATION_NAME));
	R_containment->loop_parent_optimisation_proviso = "ContainerOf";
	R_containment->loop_parent_optimisation_ranger = "TestContainmentRange";
	BinaryPredicates::set_index_details(R_containment, "container/room", "thing");
	R_support =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_supporter, NULL, EMPTY_WORDING, Calculus::Schemas::new("SupporterOf(*1)")),
			BinaryPredicates::new_term(infs_thing),
			I"supports", I"is-on",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, SUPPORT_RELATION_NAME));
	R_support->loop_parent_optimisation_proviso = "SupporterOf";
	R_incorporation =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_thing, NULL, EMPTY_WORDING, Calculus::Schemas::new("(*1.component_parent)")),
			BinaryPredicates::new_term(infs_thing),
			I"incorporates", I"is-part-of",
			NULL, Calculus::Schemas::new("MakePart(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, INCORPORATION_RELATION_NAME));
	R_carrying =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_person, NULL, EMPTY_WORDING, Calculus::Schemas::new("CarrierOf(*1)")),
			BinaryPredicates::new_term(infs_thing),
			I"carries", I"is-carried-by",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, CARRYING_RELATION_NAME));
	R_carrying->loop_parent_optimisation_proviso = "CarrierOf";
	R_holding =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_person, NULL, EMPTY_WORDING, Calculus::Schemas::new("HolderOf(*1)")),
			BinaryPredicates::new_term(infs_thing),
			I"holds", I"is-held-by",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, HOLDING_RELATION_NAME));
	/* can't be optimised, because parts are also held */
	R_wearing =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_person, NULL, EMPTY_WORDING, Calculus::Schemas::new("WearerOf(*1)")),
			BinaryPredicates::new_term(infs_thing),
			I"wears", I"is-worn-by",
			NULL, Calculus::Schemas::new("WearObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, WEARING_RELATION_NAME));
	R_wearing->loop_parent_optimisation_proviso = "WearerOf";
	a_has_b_predicate =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(NULL, NULL, EMPTY_WORDING, Calculus::Schemas::new("OwnerOf(*1)")),
			BinaryPredicates::new_term(NULL),
			I"has", I"is-had-by",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, POSSESSION_RELATION_NAME));
	a_has_b_predicate->loop_parent_optimisation_proviso = "OwnerOf";
	BinaryPredicates::set_index_details(a_has_b_predicate, "person", "thing");
	room_containment_predicate =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(infs_room, NULL, EMPTY_WORDING, Calculus::Schemas::new("LocationOf(*1)")),
			BinaryPredicates::new_term(infs_thing),
			I"is-room-of", I"is-in-room",
			NULL, Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, ROOM_CONTAINMENT_RELATION_NAME));
	room_containment_predicate->loop_parent_optimisation_proviso = "LocationOf";

@ Visibility, touchability, concealment and enclosure: all relations which
can be tested at run-time, but which can't be asserted or made true or false.

@<Make built-in indirect spatial relationships@> =
	R_visibility =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::new_term(infs_thing),
			BinaryPredicates::new_term(infs_thing),
			I"can-see", I"can-be-seen-by",
			NULL, NULL, Calculus::Schemas::new("TestVisibility(*1,*2)"),
			PreformUtilities::wording(<relation-names>, VISIBILITY_RELATION_NAME));
	R_touchability =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::new_term(infs_thing),
			BinaryPredicates::new_term(infs_thing),
			I"can-touch", I"can-be-touched-by",
			NULL, NULL, Calculus::Schemas::new("TestTouchability(*1,*2)"),
			PreformUtilities::wording(<relation-names>, TOUCHABILITY_RELATION_NAME));
	R_concealment =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::new_term(infs_thing),
			BinaryPredicates::new_term(infs_thing),
			I"conceals", I"is-concealed-by",
			NULL, NULL, Calculus::Schemas::new("TestConcealment(*1,*2)"),
			PreformUtilities::wording(<relation-names>, CONCEALMENT_RELATION_NAME));
	R_enclosure =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::new_term(Kinds::Knowledge::as_subject(K_object)),
			BinaryPredicates::new_term(Kinds::Knowledge::as_subject(K_object)),
			I"encloses", I"is-enclosed-by",
			NULL, NULL, Calculus::Schemas::new("IndirectlyContains(*1,*2)"),
			PreformUtilities::wording(<relation-names>, ENCLOSURE_RELATION_NAME));

@h Second stock.
There is none -- this is a family of relations which is all built in.

=
void PL::SpatialRelations::REL_create_second_stock(void) {
}

@h Typechecking.
No special rules apply.

=
int PL::SpatialRelations::REL_typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@h Assertion.
"In" requires delicate handling, because of the way that English uses it
sometimes transitively and sometimes not. "The passport is in the desk",
"The passport is in the Dining Room" and "The passport is in Venezuela"
place the same object in a container, a room or a region respectively.

=
int PL::SpatialRelations::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	instance *I0 = InferenceSubjects::as_object_instance(infs0),
		*I1 = InferenceSubjects::as_object_instance(infs1);
	if ((I0) && (I1)) {
		if (I1 == I0) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MiseEnAbyme),
				"this asks to put something inside itself",
				"like saying 'the bottle is in the bottle'.");
			return TRUE;
		}
		@<Offer our dependent plugins a chance to assert the relation instead@>;

		if (BinaryPredicates::can_be_made_true_at_runtime(bp) == FALSE)
			@<Issue a problem message for an unassertable indirect spatial relation@>;
		if ((bp == R_incorporation) && (Instances::of_kind(I0, K_room)))
			@<Issue a problem message for trying to subdivide a room@>;

		@<Draw inferences using only the standard Spatial conventions@>;
		if (bp == R_wearing)
			@<Assert the worn and wearable properties@>;
		return TRUE;
	}

	return FALSE;
}

@ Note that Backdrops needs to take priority over Regions here; the case of
putting a backdrop inside a region clearly has to be implemented in some
way which isn't symmetrical between the two, and this way round is cleanest.

@<Offer our dependent plugins a chance to assert the relation instead@> =
	if (PL::Backdrops::assert_relations(bp, I0, I1)) return TRUE;
	if (PL::MapDirections::assert_relations(bp, I0, I1)) return TRUE;
	if (PL::Regions::assert_relations(bp, I0, I1)) return TRUE;

@ This is the point at which non-assertable relations are thrown out.

@<Issue a problem message for an unassertable indirect spatial relation@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Unassertable),
		"the relationship you describe is not exact enough",
		"so that I do not know how to make this assertion come true. "
		"For instance, saying 'The Study is adjacent to the Hallway.' "
		"is not good enough because I need to know in what direction: "
		"is it east of the Hallway, perhaps, or west?");
	return TRUE;

@ People sometimes try, a little hopefully, to subdivide rooms. Alas for them.

@<Issue a problem message for trying to subdivide a room@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PartOfRoom),
		"this asks to make something a part of a room",
		"when only things are allowed to have parts.");
	return TRUE;

@ So we can forget about the complications of backdrops and regions now.

@<Draw inferences using only the standard Spatial conventions@> =
	inference_subject *item = Instances::as_subject(I1);
	inference_subject *loc = Instances::as_subject(I0);
	World::Inferences::draw(PART_OF_INF, item,
		(bp == R_incorporation)?CERTAIN_CE:IMPOSSIBLE_CE,
		loc, NULL);
	if (bp == R_containment)
		World::Inferences::draw(CONTAINS_THINGS_INF, loc, CERTAIN_CE, item, NULL);
	World::Inferences::draw(PARENTAGE_INF, item, CERTAIN_CE, loc, NULL);
	World::Inferences::draw(IS_ROOM_INF, item, IMPOSSIBLE_CE, NULL, NULL);

@ If something is being worn, it needs to have the I7 either/or property
"wearable" and also the I6-only attribute |worn|. (Arguably Clothing ought
to be a plugin of its own, but the compiler needs to do hardly anything
special to make it work, so this doesn't seem worth the trouble.)

@<Assert the worn and wearable properties@> =
	inference_subject *item = Instances::as_subject(I1);
	if (P_wearable)
		World::Inferences::draw_property(item, P_wearable, NULL);
	if (P_worn == NULL) {
		P_worn = Properties::EitherOr::new_nameless(L"worn");
		Properties::EitherOr::implement_as_attribute(P_worn, TRUE);
	}
	World::Inferences::draw_property(item, P_worn, NULL);

@h Compilation.
We need do nothing special: these relations can be compiled from their schemas.

=
int PL::SpatialRelations::REL_compile(int task, binary_predicate *bp, annotated_i6_schema *asch) {
	return FALSE;
}

@h Problem message text.

=
int PL::SpatialRelations::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
