[Assertions::Relational::] Relation Knowledge.

This section draws inferences about the relationships between
objects or values.

@h Relationship nodes.
Here we have a relationship between subtrees $T_X$ and $T_Y$, where $T_X$
must be a list of values or objects (joined into an |AND_NT| tree), and
$T_Y$ must be a |RELATIONSHIP_NT| subtree -- which is usually a node
annotated with the predicate meant, and beneath that another list of
objects or values, but there are two exceptional cases to take care of.

=
void Assertions::Relational::assert_subtree_in_relationship(parse_node *value, parse_node *relationship_subtree) {
	if ((value == NULL) || (relationship_subtree == NULL))
		internal_error("assert relation between null subtrees");
	if (Node::get_type(relationship_subtree) != RELATIONSHIP_NT)
		internal_error("asserted malformed relationship subtree");
	if (Node::get_type(value) == AND_NT) {
		Assertions::Relational::assert_subtree_in_relationship(value->down, relationship_subtree);
		Assertions::Relational::assert_subtree_in_relationship(value->down->next, relationship_subtree);
		return;
	}
	#ifdef IF_MODULE
	if (PL::MapDirections::get_mapping_relationship(relationship_subtree))
		@<Exceptional relationship nodes for map connections@>;
	pronoun_usage *pro = Node::get_pronoun(relationship_subtree->down);
	if ((pro) && (pro->pronoun_used == here_pronoun))
		@<Exceptional relationship nodes for placing objects "here"@>;
	#endif

	@<Standard relationship nodes (the vast majority)@>;
}

@<Standard relationship nodes (the vast majority)@> =
	binary_predicate *bp = BinaryPredicates::get_reversal(Node::get_relationship(relationship_subtree));
	if (bp == NULL) internal_error("asserted bp-less relationship subtree");
	SettingPropertyRelations::fix_property_bp(bp);
	Assertions::Relational::assert_relation_between_subtrees(value, bp, relationship_subtree->down);
	return;

@<Exceptional relationship nodes for placing objects "here"@> =
	if (Node::get_subject(value) == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_HereFailedOnNothing),
			"that is an assertion which puts nothing 'here'",
			"which looks as if it might be trying to give me negative rather "
			"than positive information. There's no need to tell me something "
			"like 'Here is nothing.': just don't put anything there.");
	} else {
		Assert::true_about(
			Propositions::Abstract::to_put_here(),
			Node::get_subject(value), prevailing_mood);
	}
	return;

@<Exceptional relationship nodes for map connections@> =
	@<Make some paranoid checks that the map subtree is valid@>;
	Assertions::Relational::substitute_at_node(relationship_subtree->down);
	Assertions::Relational::substitute_at_node(relationship_subtree->down->next);
	inference_subject *iy = Node::get_subject(relationship_subtree->down);
	inference_subject *id = Node::get_subject(relationship_subtree->down->next);
	if (iy == NULL) {
		if (Rvalues::is_nothing_object_constant(
			Node::get_evaluation(relationship_subtree->down)))
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MapFromNowhere),
				"the source of a map connection can't be nowhere",
				"so sentences like 'The pink door is south of nowhere.' are not "
				"allowed.");
		else
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MapFromNonroom2),
				"the source of a map connection has to be a room or door",
				"so sentences like 'The pink door is south of 0.' are not "
				"allowed.");
		return;
	}
	if ((iy == NULL) || (id == NULL))
		internal_error("malformed directional subtree");
	if (Rvalues::is_nothing_object_constant(value))
		PL::Map::connect(iy, NULL, id);
	else if (Rvalues::is_object(Node::get_evaluation(value)))
		PL::Map::connect(iy, Node::get_subject(value), id);
	else {
		LOG("Val is $P\n", value);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MapToNonobject),
			"the destination of a map connection has to be either a room, "
			"a door or 'nowhere'",
			"but here the destination doesn't even seem to be an object.");
	}
	return;

@<Make some paranoid checks that the map subtree is valid@> =
	if ((relationship_subtree->down == NULL) ||
		(relationship_subtree->down->next == NULL) ||
		(relationship_subtree->down->next->next != NULL))
		internal_error("malformed DIRECTION");
	if (Node::get_type(relationship_subtree->down) != PROPER_NOUN_NT) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this is not straightforward in saying which room (or door) leads away from",
			"and should just name the source.");
		return;
	}
	if (Node::get_type(relationship_subtree->down->next) != PROPER_NOUN_NT) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this is not straightforward in saying which direction the room (or door) lies in",
			"and should just name the direction.");
		return;
	}

@ =
void Assertions::Relational::substitute_at_node(parse_node *p) {
	parse_node *spec = Node::get_evaluation(p);
	spec = NonlocalVariables::substitute_constants(spec);
	Refiner::give_spec_to_noun(p, spec);
}

@ So the majority case above calls |Assertions::Relational::assert_relation_between_subtrees| to say
that subtrees $T_X$ and $T_Y$, where $T_X$ is a single value or object and
$T_Y$ is a list of values or objects (joined into an |AND_NT| tree).

=
void Assertions::Relational::assert_relation_between_subtrees(parse_node *px, binary_predicate *bp, parse_node *py) {
	if (Node::get_type(py) == AND_NT) {
		Assertions::Relational::assert_relation_between_subtrees(px, bp, py->down);
		Assertions::Relational::assert_relation_between_subtrees(px, bp, py->down->next);
		return;
	}
	if (Node::get_type(py) == WITH_NT) {
		Assertions::Relational::assert_relation_between_subtrees(px, bp, py->down);
		return;
	}
	if (Node::get_type(py) == EVERY_NT) @<Issue problem for "every" used on the right@>;

	/* reverse the relation (and swap the terms) to ensure it's the right way round */
	if (BinaryPredicates::is_the_wrong_way_round(bp)) {
		parse_node *pz = px; px = py; py = pz;
		bp = BinaryPredicates::get_reversal(bp);
	}

	@<Normalise the two noun leaves@>;
	@<Impose a tedious restriction on relations between objects and values@>;

	Assert::true(
		Propositions::Abstract::to_set_relation(bp, Node::get_subject(px), Node::get_evaluation(px), Node::get_subject(py), Node::get_evaluation(py)),
		prevailing_mood);
}

@ Both sides have to be nouns representing constant values:

@<Normalise the two noun leaves@> =
	Refiner::nominalise_adjective(px); Refiner::turn_player_to_yourself(px);
	Refiner::nominalise_adjective(py); Refiner::turn_player_to_yourself(py);

	if (((Node::get_type(px) != PROPER_NOUN_NT) && (Node::get_type(px) != COMMON_NOUN_NT)) ||
		((Node::get_type(py) != PROPER_NOUN_NT) && (Node::get_type(py) != COMMON_NOUN_NT))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRelation),
			"this description of a relationship makes no sense to me",
			"and should be something like 'X is in Y' (or 'on' or 'part of Y'); "
			"or else 'X is here' or 'X is east of Y'.");
		return;
	}

@ At some point we should probably revisit this.

@<Impose a tedious restriction on relations between objects and values@> =
	if ((Relations::Explicit::relates_values_not_objects(bp)) &&
		(((Node::get_subject(px)) && (KindSubjects::to_kind(Node::get_subject(px)))) ||
		((Node::get_subject(py)) && (KindSubjects::to_kind(Node::get_subject(py)))))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_KindRelatedToValue),
			"relations between objects and values have to be made one "
			"object at a time",
			"not using kinds of object to make multiple relationships in "
			"a single sentence. (Sorry for this restriction. It's sometimes "
			"possible to get around it using words like 'every': for example, "
			"'Every person is in the Ballroom.' is allowed.)");
		return;
	}

@<Issue problem for "every" used on the right@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EveryWrongSide),
		"'every' can only be used on the other side of the verb",
		"because of limitations in Inform (but also to avoid certain possible "
		"ambiguities). In general, 'every' should be applied to the subject of an "
		"assertion sentence and not the object. Thus 'Sir Francis prefers every "
		"blonde' is not allowed, but 'Every blonde is preferred by Sir Francis' is. "
		"(It would be different if, instead of Sir Francis who's just one man, "
		"the name of a kind appeared: 'A vehicle is in every room' is fine, for "
		"example, because 'vehicle' is a kind.)");
	return;
