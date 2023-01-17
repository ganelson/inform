[SpatialRelations::] Spatial Relations.

Binary predicates for spatial relationships.

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
binary_predicate *R_audibility = NULL;
binary_predicate *R_touchability = NULL;
binary_predicate *R_concealment = NULL;
binary_predicate *R_enclosure = NULL;

@ These relations are all hard-wired in:

=
void SpatialRelations::start(void) {
	METHOD_ADD(spatial_bp_family, STOCK_BPF_MTID, SpatialRelations::stock);
	METHOD_ADD(spatial_bp_family, TYPECHECK_BPF_MTID, SpatialRelations::typecheck);
	METHOD_ADD(spatial_bp_family, ASSERT_BPF_MTID, SpatialRelations::assert);
	METHOD_ADD(spatial_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID,
		SpatialRelations::describe_for_index);
}

void SpatialRelations::stock(bp_family *self, int n) {
	if (n == 1) {
		@<Make built-in spatial relationships@>;
		@<Make built-in indirect spatial relationships@>;
		MapRelations::create_relations();
		Regions::create_relations();
	}
}

@ Containment, support, incorporation, carrying, holding, wearing and
possession. The "loop parent optimisation" is explained elsewhere, but
the basic idea is that given a fixed $y$ you can search for all $x$ such
that $B(x, y)$ by looking at the object-tree children of $y$ at run-time.
On a large work of IF, this cuts the number of cases to check by a factor
of 100 or more. (It can't be used for component parts, since those are
not stored in the I6 object tree; nor for the holding relation, since that's
a union of the others, and therefore includes incorporation.)

@<Make built-in spatial relationships@> =
	R_containment =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(NULL, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("ContainerOf(*1)")),
			BPTerms::new(NULL),
			I"contains", I"is-in",
			Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, CONTAINMENT_RELATION_NAME));
	R_containment->loop_parent_optimisation_proviso = "ContainerOf";
	R_containment->loop_parent_optimisation_ranger = "TestContainmentRange";
	BinaryPredicates::set_index_details(R_containment, "container/room", "thing");
	R_support =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(infs_supporter, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("SupporterOf(*1)")),
			BPTerms::new(infs_thing),
			I"supports", I"is-on",
			Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, SUPPORT_RELATION_NAME));
	R_support->loop_parent_optimisation_proviso = "SupporterOf";
	R_incorporation =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(infs_thing, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("PartOf(*1)")),
			BPTerms::new(infs_thing),
			I"incorporates", I"is-part-of",
			Calculus::Schemas::new("MakePart(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, INCORPORATION_RELATION_NAME));
	R_carrying =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(infs_person, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("CarrierOf(*1)")),
			BPTerms::new(infs_thing),
			I"carries", I"is-carried-by",
			Calculus::Schemas::new("MakeHolderOf(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, CARRYING_RELATION_NAME));
	R_carrying->loop_parent_optimisation_proviso = "CarrierOf";
	R_holding =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(NULL, K_object, EMPTY_WORDING,
				Calculus::Schemas::new("HolderOf(*1)")),
			BPTerms::new_full(NULL, K_object, EMPTY_WORDING,
				NULL),
			I"holds", I"is-held-by",
			Calculus::Schemas::new("MakeHolderOf(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, HOLDING_RELATION_NAME));
	/* can't be optimised, because parts are also held */
	R_wearing =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(infs_person, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("WearerOf(*1)")),
			BPTerms::new(infs_thing),
			I"wears", I"is-worn-by",
			Calculus::Schemas::new("WearObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, WEARING_RELATION_NAME));
	R_wearing->loop_parent_optimisation_proviso = "WearerOf";
	a_has_b_predicate =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(NULL, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("OwnerOf(*1)")),
			BPTerms::new(NULL),
			I"has", I"is-had-by",
			Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, POSSESSION_RELATION_NAME));
	a_has_b_predicate->loop_parent_optimisation_proviso = "OwnerOf";
	BinaryPredicates::set_index_details(a_has_b_predicate, "person", "thing");
	room_containment_predicate =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new_full(infs_room, NULL, EMPTY_WORDING,
				Calculus::Schemas::new("LocationOf(*1)")),
			BPTerms::new(infs_thing),
			I"is-room-of", I"is-in-room",
			Calculus::Schemas::new("MoveObject(*2,*1)"), NULL,
			PreformUtilities::wording(<relation-names>, ROOM_CONTAINMENT_RELATION_NAME));
	room_containment_predicate->loop_parent_optimisation_proviso = "LocationOf";

@ Visibility, touchability, concealment and enclosure: all relations which
can be tested at run-time, but which can't be asserted or made true or false.

@<Make built-in indirect spatial relationships@> =
	R_visibility =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new(infs_thing),
			BPTerms::new(infs_thing),
			I"can-see", I"can-be-seen-by",
			NULL, Calculus::Schemas::new("TestVisibility(*1,*2)"),
			PreformUtilities::wording(<relation-names>, VISIBILITY_RELATION_NAME));
	R_audibility =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new(infs_thing),
			BPTerms::new(infs_thing),
			I"can-hear", I"can-be-heard-by",
			NULL, Calculus::Schemas::new("TestAudibility(*1,*2)"),
			PreformUtilities::wording(<relation-names>, AUDIBILITY_RELATION_NAME));
	R_touchability =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new(infs_thing),
			BPTerms::new(infs_thing),
			I"can-touch", I"can-be-touched-by",
			NULL, Calculus::Schemas::new("TestTouchability(*1,*2)"),
			PreformUtilities::wording(<relation-names>, TOUCHABILITY_RELATION_NAME));
	R_concealment =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new(infs_thing),
			BPTerms::new(infs_thing),
			I"conceals", I"is-concealed-by",
			NULL, Calculus::Schemas::new("TestConcealment(*1,*2)"),
			PreformUtilities::wording(<relation-names>, CONCEALMENT_RELATION_NAME));
	R_enclosure =
		BinaryPredicates::make_pair(spatial_bp_family,
			BPTerms::new(KindSubjects::from_kind(K_object)),
			BPTerms::new(KindSubjects::from_kind(K_object)),
			I"encloses", I"is-enclosed-by",
			NULL, Calculus::Schemas::new("IndirectlyContains(*1,*2)"),
			PreformUtilities::wording(<relation-names>, ENCLOSURE_RELATION_NAME));

@ No special rules apply to typechecking:

=
int SpatialRelations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@ "In" requires delicate handling, because of the way that English uses it
sometimes transitively and sometimes not. "The passport is in the desk", "The
passport is in the Dining Room" and "The passport is in Venezuela" place the
same object in a container, a room or a region respectively.

=
int SpatialRelations::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	instance *I0 = InstanceSubjects::to_object_instance(infs0),
		*I1 = InstanceSubjects::to_object_instance(infs1);
	if ((I0) && (I1)) {
		if (I1 == I0) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MiseEnAbyme),
				"this asks to put something inside itself",
				"like saying 'the bottle is in the bottle'.");
			return TRUE;
		}
		@<Offer our dependent features a chance to assert the relation instead@>;

		if (BinaryPredicates::can_be_made_true_at_runtime(bp) == FALSE)
			@<Issue a problem message for an unassertable indirect spatial relation@>;
		if ((bp == R_incorporation) && (Instances::of_kind(I0, K_room)))
			@<Issue a problem message for trying to subdivide a room@>;

		@<Draw inferences using only the standard Spatial conventions@>;
		if (bp == R_wearing)
			@<Assert the worn and wearable properties@>;
		if (bp == R_holding)
			@<Assert the kind of the holder@>;
		return TRUE;
	}
	if (I1 == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UndefinedContainment),
			"this asks to put something whose identity I don't know inside something else",
			"and the reason I don't know that identity is that it isn't either a name "
			"of a room or thing, or of a constant or variable set to a room or thing.");
		return TRUE;
	}
	if (I0 == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UndefinedContainment2),
			"this asks to put something inside something else whose identity I don't know",
			"and the reason I don't know that identity is that it isn't either a name "
			"of a room or thing, or of a constant or variable set to a room or thing.");
		return TRUE;
	}

	return FALSE;
}

@ Note that Backdrops needs to take priority over Regions here; the case of
putting a backdrop inside a region clearly has to be implemented in some
way which isn't symmetrical between the two, and this way round is cleanest.

@<Offer our dependent features a chance to assert the relation instead@> =
	if (Backdrops::assert_relations(bp, I0, I1)) return TRUE;
	if (Regions::assert_relations(bp, I0, I1)) return TRUE;

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
	SpatialInferences::infer_part_of(item,
		(bp == R_incorporation)?CERTAIN_CE:IMPOSSIBLE_CE, loc);
	if (bp == R_containment)
		SpatialInferences::infer_contains_things(loc, CERTAIN_CE);
	SpatialInferences::infer_parentage(item, CERTAIN_CE, loc);
	SpatialInferences::infer_is_room(item, IMPOSSIBLE_CE);

@ If something is being worn, it needs to have the I7 either/or property
"wearable" and also the I6-only attribute |worn|. (Arguably Clothing ought
to be a feature of its own, but the compiler needs to do hardly anything
special to make it work, so this doesn't seem worth the trouble.)

@<Assert the worn and wearable properties@> =
	inference_subject *item = Instances::as_subject(I1);
	if (P_wearable)
		PropertyInferences::draw(item, P_wearable, NULL);
	if (P_worn == NULL) {
		P_worn = EitherOrProperties::new_nameless(I"worn");
	}
	PropertyInferences::draw(item, P_worn, NULL);

@ This unusual deduction is part of a mitigation for Jira issue I7-2220,
which analysed inconsistencies in the implementation of the holding relation.
Prior to this change, the terms of "X holds Y" were given the kinds thing and
person respectively: i.e., Y was assumed to be a person. But this was in
practice not always true. However, without that assumption, sentences like
"Mr Smith holds the coin" do not automatically deduce that Mr Smith is a person.
So the following hand-coded rule makes that deduction.

@<Assert the kind of the holder@> =
	Propositions::Abstract::assert_kind_of_instance(I0, K_person);
	Propositions::Abstract::assert_kind_of_instance(I1, K_thing);

@h Cursory description.

=
void SpatialRelations::describe_for_index(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	WRITE("spatial");
}
