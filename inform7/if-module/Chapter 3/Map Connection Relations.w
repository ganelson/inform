[PL::MapDirections::] Map Connection Relations.

To define one binary predicate for each map direction, such as
"mapped north of".

@h Family.

=
bp_family *map_connecting_bp_family = NULL;

void PL::MapDirections::start(void) {
	map_connecting_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(map_connecting_bp_family, TYPECHECK_BPF_MTID, PL::MapDirections::REL_typecheck);
	METHOD_ADD(map_connecting_bp_family, ASSERT_BPF_MTID, PL::MapDirections::REL_assert);
	METHOD_ADD(map_connecting_bp_family, SCHEMA_BPF_MTID, PL::MapDirections::REL_compile);
	METHOD_ADD(map_connecting_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, PL::MapDirections::REL_describe_for_problems);
	METHOD_ADD(map_connecting_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID, PL::MapDirections::REL_describe_briefly);
}

@ This section creates a family of implicit relations (implemented as binary
predicates) corresponding to the different directions.

For every direction created, a predicate is created for the possibility of
a map connection. For instance, "if Versailles is mapped north of the
Metro" tests the "mapped-north" BP. There is also one general relation
built in:

=
binary_predicate *R_adjacency = NULL;

@h The adjacency relation.
We may as well do this here: creating the relation "X is adjacent to Y".

=
void PL::MapDirections::create_relations(void) {
	R_adjacency =
		BinaryPredicates::make_pair(spatial_bp_family,
			BinaryPredicates::new_term(infs_room),
			BinaryPredicates::new_term(infs_room),
			I"adjacent-to", I"adjacent-from",
			NULL, NULL, Calculus::Schemas::new("TestAdjacency(*1,*2)"),
			PreformUtilities::wording(<relation-names>, ADJACENCY_RELATION_NAME));

}

@ There is nothing special about asserting this, so we don't intervene:

=
int PL::MapDirections::assert_relations(binary_predicate *relation, instance *I0, instance *I1) {
	return FALSE;
}

@h Subsequent creations.
Every direction created has a relation associated with it: for instance,
"north" has the relation "X is mapped north of Y". Now a direction is a
kind of object, but objects aren't created until after relations used to
parse sentences are needed. In fact, however, directions are "noticed"
at an earlier stage in Inform's run, so another two-step is needed:

=
binary_predicate *PL::MapDirections::create_sketchy_mapping_direction(wording W) {
	binary_predicate *bp;
	@<Create the mapping BP for the new direction@>;
	return bp;
}

@ When each direction is created, so are corresponding relations and
prepositional uses: for example, "northeast" makes "mapping northeast"
as a relation, and "mapped northeast of" as a prepositional usage.

The rule is actually that production (a) in <mapping-preposition-construction>
is used for all directions except those named in <notable-directions>,
where (b) is used. As a result, we make "mapped inside" and "mapped
outside" instead of "mapped inside of" and "mapped outside of." This
is done to avoid ambiguities with the already-existing meanings of inside
and outside to do with spatial containment.

The use of the word "mapped" may seem itself off. Why define "to be mapped
east of" rather than "to be east of"? After all, that seems to be what is
used in assertions like:

>> The Bakery is east of Pudding Lane.

In fact, the A-parser reads sentences like that by looking out specially for
direction names plus "of" -- so this is parsed without using the mapping
predicate for "east". But it cannot read:

>> The Flour Cellar is below the Bakery.

as a direction name plus "of", since "below" is not the name of the direction
"down", and anyway there is no "of".

We do not allow direction names with unexpected capital letters because we
want to allow room names to contain direction names on occasion:

>> The fire hydrant is in West from 47th Street.

=
<mapping-relation-construction> ::=
	mapping ...

<mapping-preposition-construction> ::=
	mapped ... of |
	mapped ... |
	... of |
	... from

@ Two of the directions are special to mapping, because they have to be parsed
slighly differently. (These are the English names; there is no need to translate
this to other languages.)

=
<notable-directions> ::=
	inside |
	outside

@ Directions are detected in sentences having the form "D is a direction." This
is intentionally done very early on.

@d MAX_DIRECTIONS 100 /* the Standard Rules define only 12, so this is plenty */

=
parse_node *directions_noticed[MAX_DIRECTIONS];
binary_predicate *direction_relations_noticed[MAX_DIRECTIONS];
int no_directions_noticed = 0;

@

@d MAX_MAPPING_RELATION_NAME_LENGTH MAX_WORDS_IN_DIRECTION*MAX_WORD_LENGTH+10

@<Create the mapping BP for the new direction@> =
	if (Wordings::length(W) > MAX_WORDS_IN_DIRECTION)
		W = Wordings::truncate(W, MAX_WORDS_IN_DIRECTION); /* just truncate for now */

	TEMPORARY_TEXT(relname) /* for debugging log, e.g., "north-map" */
	WRITE_TO(relname, "%W-map", W);
	LOOP_THROUGH_TEXT(pos, relname)
		if (Str::get(pos) == ' ') Str::put(pos, '-');
	bp_term_details room_term = BinaryPredicates::new_term(NULL);
	bp = BinaryPredicates::make_pair(map_connecting_bp_family,
		room_term, room_term, relname, NULL, NULL, NULL, NULL,
		PreformUtilities::merge(<mapping-relation-construction>, 0,
			WordAssemblages::from_wording(W)));

	int mpc_form = 0;
	if (<notable-directions>(W)) mpc_form = 1;

	preposition *prep1 = Prepositions::make(
		PreformUtilities::merge(<mapping-preposition-construction>, mpc_form,
			WordAssemblages::from_wording(W)),
		FALSE, current_sentence);
	preposition *prep2 = Prepositions::make(
		PreformUtilities::merge(<mapping-preposition-construction>, 2,
			WordAssemblages::from_wording(W)),
		FALSE, current_sentence);
	preposition *prep3 = Prepositions::make(
		PreformUtilities::merge(<mapping-preposition-construction>, 3,
			WordAssemblages::from_wording(W)),
		FALSE, current_sentence);

	verb_meaning vm = VerbMeanings::regular(bp);
	Verbs::add_form(copular_verb, prep1, NULL, vm, SVO_FS_BIT);
	Verbs::add_form(copular_verb, prep2, NULL, vm, SVO_FS_BIT);
	Verbs::add_form(copular_verb, prep3, NULL, vm, SVO_FS_BIT);

	DISCARD_TEXT(relname)

@ That was one step, and here's the second. At this point we have created the
instance |I| for the direction, and given it the kind "direction". That
makes it possible to complete the details of the BP.

|ident| can be any string of text which evaluates in I6 to the
object number of the direction object. It seems redundant here because
surely if we know |I|, we know its runtime representation; but that's not
true -- we need to call this routine at a time when the final identifier
names for I6 objects have not yet been settled.

=
int mmp_call_counter = 0;
void PL::MapDirections::make_mapped_predicate(instance *I, inter_name *ident) {
	wording W = Instances::get_name(I, FALSE);
	if ((Wordings::empty(W)) || (Wordings::length(W) > MAX_WORDS_IN_DIRECTION))
		internal_error("bad direction name");
	binary_predicate *bp = direction_relations_noticed[mmp_call_counter++];
	if (bp == NULL) {
		LOG("Improper text: %W\n", W);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ImproperlyMadeDirection),
			"directions must be created by only the simplest possible sentences",
			"in the form 'North-north-west is a direction' only. Using adjectives, "
			"'called', 'which', and so on is not allowed. (In practice this is not "
			"too much of a restriction. I won't allow 'Clockwise is a privately-named "
			"direction.', but I will allow 'Clockwise is a direction. Clockwise "
			"is privately-named.')");
		return;
	}
	bp->term_details[0] = BinaryPredicates::new_term(NULL);
	bp->term_details[1] = BinaryPredicates::new_term(NULL);
	BinaryPredicates::set_index_details(bp, "room/door", "room/door");
	bp->test_function = Calculus::Schemas::new("(MapConnection(*2,%n) == *1)", ident);
	bp->make_true_function = Calculus::Schemas::new("AssertMapConnection(*2,%n,*1)", ident);
	bp->make_false_function = Calculus::Schemas::new("AssertMapUnconnection(*2,%n,*1)", ident);
	PF_I(map, I)->direction_relation = bp;
}

@ 

=
void PL::MapDirections::look_for_direction_creation(parse_node *pn) {
	if (Node::get_type(pn) != SENTENCE_NT) return;
	if ((pn->down == NULL) || (pn->down->next == NULL) || (pn->down->next->next == NULL)) return;
	if (Node::get_type(pn->down) != VERB_NT) return;
	if (Node::get_type(pn->down->next) != UNPARSED_NOUN_NT) return;
	if (Node::get_type(pn->down->next->next) != UNPARSED_NOUN_NT) return;
	current_sentence = pn;
	pn = pn->down->next;
	if (!((<notable-map-kinds>(Node::get_text(pn->next)))
			&& (<<r>> == 0))) return;
	if (no_directions_noticed >= MAX_DIRECTIONS) {
		StandardProblems::limit_problem(Task::syntax_tree(), _p_(PM_TooManyDirections),
			"different directions", MAX_DIRECTIONS);
		return;
	}
	direction_relations_noticed[no_directions_noticed] =
		PL::MapDirections::create_sketchy_mapping_direction(Node::get_text(pn));
	directions_noticed[no_directions_noticed++] = pn;
}

@h Typechecking.
This won't catch everything, but it will do. Run-time checking will pick up
remaining anomalies.

=
int PL::MapDirections::REL_typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	int t;
	for (t=0; t<2; t++)
		if ((Kinds::compatible(kinds_of_terms[t], K_room) == NEVER_MATCH) &&
			(Kinds::compatible(kinds_of_terms[t], K_door) == NEVER_MATCH)) {
		LOG("Term %d is %u but should be a room or door\n", t, kinds_of_terms[t]);
		Calculus::Propositions::Checker::issue_bp_typecheck_error(bp, kinds_of_terms[0], kinds_of_terms[1], tck);
		return NEVER_MATCH;
	}
	return ALWAYS_MATCH;
}

@h Assertion.
Note that the following will infer |IS_ROOM_INF| for any source of a map
connection -- which will include doors. That doesn't matter, because the
Spatial plugin uses these inferences only for objects whose kind is not
explicitly given in the source text; and doors must always be specified as
such.

=
int PL::MapDirections::REL_assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	instance *o_dir = PL::MapDirections::get_mapping_direction(bp);
	inference_subject *infs_from = infs0;
	inference_subject *infs_to = infs1;

	World::Inferences::draw(IS_ROOM_INF, infs_from, prevailing_mood, NULL, NULL);
	if ((prevailing_mood >= 0) && (infs_to))
		World::Inferences::draw(IS_ROOM_INF, infs_to, LIKELY_CE, NULL, NULL);
	World::Inferences::draw(DIRECTION_INF, infs_from, prevailing_mood,
		infs_to, o_dir?(Instances::as_subject(o_dir)):NULL);

	return TRUE;
}

@h Compilation.
We need do nothing special: these relations can be compiled from their schemas.

=
int PL::MapDirections::REL_compile(bp_family *self, int task, binary_predicate *bp, annotated_i6_schema *asch) {
	return FALSE;
}

@h Problem message text.

=
int PL::MapDirections::REL_describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
void PL::MapDirections::REL_describe_briefly(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	WRITE("map");
}

@h The correspondence with directions.
(Speed really does not matter here.)

=
binary_predicate *PL::MapDirections::get_mapping_relation(instance *dir) {
	if (dir == NULL) return NULL;
	return PF_I(map, dir)->direction_relation;
}

instance *PL::MapDirections::get_mapping_direction(binary_predicate *bp) {
	if (bp == NULL) return NULL;
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if (PF_I(map, I)->direction_relation == bp)
			return I;
	return NULL;
}

instance *PL::MapDirections::get_mapping_relationship(parse_node *p) {
	binary_predicate *bp = Node::get_relationship(p);
	if ((bp) && (Plugins::Manage::plugged_in(map_plugin))) {
		instance *dir = PL::MapDirections::get_mapping_direction(
			BinaryPredicates::get_reversal(bp));
		if (dir == NULL) dir = PL::MapDirections::get_mapping_direction(bp);
		return dir;
	}
	return NULL;
}
