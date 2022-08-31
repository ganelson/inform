[MapRelations::] Map Connection Relations.

To define one binary predicate for each map direction, such as
"mapped north of".

@h Family.
This section creates a family of implicit relations (implemented as binary
predicates) corresponding to the different directions.

For every direction created, a predicate is created for the possibility of
a map connection. For instance, "if Versailles is mapped north of the
Metro" tests the "mapped-north" BP.

=
bp_family *map_connecting_bp_family = NULL;

void MapRelations::start(void) {
	map_connecting_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(map_connecting_bp_family, TYPECHECK_BPF_MTID, MapRelations::typecheck);
	METHOD_ADD(map_connecting_bp_family, ASSERT_BPF_MTID, MapRelations::assert);
	METHOD_ADD(map_connecting_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID,
		MapRelations::describe_for_index);
}

@h Subsequent creations.
Every direction created has a relation associated with it: for instance,
"north" has the relation "X is mapped north of Y". Now a direction is a
kind of object, but objects aren't created until after relations used to
parse sentences are needed. In fact, however, directions are "noticed"
at an earlier stage in Inform's run, so another two-step is needed:

=
binary_predicate *MapRelations::create_sketchy_mapping_direction(wording W) {
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

The use of the word "mapped" may seem itself odd. Why define "to be mapped
east of" rather than "to be east of"? After all, that seems to be what is
used in assertions like:

>> The Bakery is east of Pudding Lane.

In fact, the assertion parser reads sentences like that by looking out specially
for direction names plus "of" -- so this is parsed without using the mapping
predicate for "east". But it cannot read:

>> The Flour Cellar is below the Bakery.

as a direction name plus "of", since "below" is not the name of the direction
"down", and anyway there is no "of".

=
<mapping-relation-construction> ::=
	mapping ...

<mapping-preposition-construction> ::=
	mapped ... of |
	mapped ... |
	... of |
	... from

@ Two of the directions are special to mapping, because they have to be parsed
slightly differently. (These are the English names; there is no need to translate
this to other languages.)

=
<notable-directions> ::=
	inside |
	outside

@ Directions are detected in sentences having the form "D is a direction." This
is intentionally done very early on.

@d MAX_MAPPING_RELATION_NAME_LENGTH MAX_WORDS_IN_DIRECTION*MAX_WORD_LENGTH+10

@<Create the mapping BP for the new direction@> =
	if (Wordings::length(W) > MAX_WORDS_IN_DIRECTION)
		W = Wordings::truncate(W, MAX_WORDS_IN_DIRECTION); /* just truncate for now */

	TEMPORARY_TEXT(relname) /* for debugging log, e.g., "north-map" */
	WRITE_TO(relname, "%W-map", W);
	LOOP_THROUGH_TEXT(pos, relname)
		if (Str::get(pos) == ' ') Str::put(pos, '-');
	bp_term_details room_term = BPTerms::new(NULL);
	bp = BinaryPredicates::make_pair(map_connecting_bp_family,
		room_term, room_term, relname, NULL, NULL, NULL,
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

=
int mmp_call_counter = 0;
void MapRelations::make_mapped_predicate(instance *I) {
	wording W = Instances::get_name(I, FALSE);
	if ((Wordings::empty(W)) || (Wordings::length(W) > MAX_WORDS_IN_DIRECTION))
		internal_error("bad direction name");
	binary_predicate *bp = direction_relations_noticed[mmp_call_counter++];
	if (bp == NULL) {
		LOG("Improper text: %W\n", W);
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ImproperlyMadeDirection),
			"directions must be created by only the simplest possible sentences",
			"in the form 'North-north-west is a direction' only. Using adjectives, "
			"'called', 'which', and so on is not allowed. (In practice this is not "
			"too much of a restriction. I won't allow 'Clockwise is a privately-named "
			"direction.', but I will allow 'Clockwise is a direction. Clockwise "
			"is privately-named.')");
		return;
	}
	bp->term_details[0] = BPTerms::new(NULL);
	bp->term_details[1] = BPTerms::new(NULL);
	BinaryPredicates::set_index_details(bp, "room/door", "room/door");
	RTMap::set_map_schemas(bp, I);
	MAP_DATA(I)->direction_relation = bp;
}

@h Typechecking.
This won't catch everything, but it will do. Run-time checking will pick up
remaining anomalies.

=
int MapRelations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	for (int t=0; t<2; t++)
		if ((Kinds::compatible(kinds_of_terms[t], K_room) == NEVER_MATCH) &&
			(Kinds::compatible(kinds_of_terms[t], K_door) == NEVER_MATCH)) {
			TypecheckPropositions::issue_bp_typecheck_error(bp, kinds_of_terms[0],
				kinds_of_terms[1], tck);
			return NEVER_MATCH;
		}
	return ALWAYS_MATCH;
}

@h Assertion.
Note that the following will infer |IS_ROOM_INF| for any source of a map
connection -- which will include doors. That doesn't matter, because the
Spatial feature uses these inferences only for objects whose kind is not
explicitly given in the source text; and doors must always be specified as
such.

=
int MapRelations::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	instance *o_dir = MapRelations::get_mapping_direction(bp);
	inference_subject *infs_to = infs0;
	inference_subject *infs_from = infs1;
	SpatialInferences::infer_is_room(infs_from, prevailing_mood);
	if ((prevailing_mood >= 0) && (infs_to))
		SpatialInferences::infer_is_room(infs_to, LIKELY_CE);
	Map::infer_direction(infs_from, infs_to, o_dir);
	return TRUE;
}

@h Indexing.

=
void MapRelations::describe_for_index(bp_family *self, OUTPUT_STREAM,
	binary_predicate *bp) {
	WRITE("map");
}

@h The correspondence with directions.
Speed really does not matter here.

=
binary_predicate *MapRelations::get_mapping_relation(instance *dir) {
	if (dir == NULL) return NULL;
	return MAP_DATA(dir)->direction_relation;
}

instance *MapRelations::get_mapping_direction(binary_predicate *bp) {
	if (bp == NULL) return NULL;
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if (MAP_DATA(I)->direction_relation == bp)
			return I;
	return NULL;
}

instance *MapRelations::get_mapping_relationship(parse_node *p) {
	binary_predicate *bp = Node::get_relationship(p);
	if ((bp) && (FEATURE_ACTIVE(map))) {
		instance *dir = MapRelations::get_mapping_direction(
			BinaryPredicates::get_reversal(bp));
		if (dir == NULL) dir = MapRelations::get_mapping_direction(bp);
		return dir;
	}
	return NULL;
}

@h The adjacency relation.
There is also one general relation built in, though it belongs to the spatial family:

=
void MapRelations::create_relations(void) {
	BinaryPredicates::make_pair(spatial_bp_family,
		BPTerms::new(infs_room),
		BPTerms::new(infs_room),
		I"adjacent-to", I"adjacent-from",
		NULL, Calculus::Schemas::new("TestAdjacency(*1,*2)"),
		PreformUtilities::wording(<relation-names>, ADJACENCY_RELATION_NAME));
}
