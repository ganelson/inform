[RelationSubjects::] Relation Subjects.

The relations family of inference subjects.

@ Every binary predicate has an associated subject:

=
inference_subject_family *relations_family = NULL;

inference_subject_family *RelationSubjects::family(void) {
	if (relations_family == NULL) {
		relations_family = InferenceSubjects::new_family();
		METHOD_ADD(relations_family, GET_DEFAULT_CERTAINTY_INFS_MTID,
			RelationSubjects::certainty);
		METHOD_ADD(relations_family, EMIT_ALL_INFS_MTID, RTRelations::emit_all);
		METHOD_ADD(relations_family, EMIT_ONE_INFS_MTID, RTRelations::emit_one);
		METHOD_ADD(relations_family, CHECK_MODEL_INFS_MTID, RelationSubjects::check_model);
		METHOD_ADD(relations_family, COMPLETE_MODEL_INFS_MTID, RelationSubjects::complete_model);
		METHOD_ADD(relations_family, GET_NAME_TEXT_INFS_MTID, RelationSubjects::get_name);
	}
	return relations_family;
}

inference_subject *RelationSubjects::new(binary_predicate *bp) {
	return InferenceSubjects::new(relations, RelationSubjects::family(),
		STORE_POINTER_binary_predicate(bp), NULL);
}

binary_predicate *RelationSubjects::to_bp(inference_subject *infs) {
	if ((infs) && (infs->infs_family == relations_family))
		return RETRIEVE_POINTER_binary_predicate(infs->represents);
	return NULL;
}

@ =
int RelationSubjects::certainty(inference_subject_family *f, inference_subject *infs) {
	return CERTAIN_CE;	
}

void RelationSubjects::get_name(inference_subject_family *family,
	inference_subject *from, wording *W) {
	*W = EMPTY_WORDING; /* nameless */
}

@ At model completion time, we need to do some work on equivalence relations:

=
void RelationSubjects::complete_model(inference_subject_family *family,
	inference_subject *infs) {
	int domain_size = NUMBER_CREATED(inference_subject);
	binary_predicate *bp = RelationSubjects::to_bp(infs);

	if (Relations::Explicit::stored_dynamically(bp)) return; /* handled at run-time */

	if ((Relations::Explicit::get_form_of_relation(bp) == Relation_Equiv) &&
		(bp->right_way_round)) {
		RTRelations::equivalence_relation_make_singleton_partitions(bp, domain_size);
		inference *i;
		POSITIVE_KNOWLEDGE_LOOP(i, World::Inferences::bp_as_subject(bp),
			ARBITRARY_RELATION_INF) {
			inference_subject *infs0, *infs1;
			World::Inferences::get_references(i, &infs0, &infs1);
			RTRelations::equivalence_relation_merge_classes(bp, domain_size,
				infs0->allocation_id, infs1->allocation_id);
		}
		RTRelations::equivalence_relation_add_properties(bp);
	}
}

@ We now check 1-to-1 relations to see if the initial conditions have
violated the 1-to-1-ness. Because of the way these relations are implemented
using a property, it seems in fact to be impossible to violate the left-hand
count -- a contradiction problem is reported when the inference was generated.
But in case the implementation is ever changed, it seems prudent to leave this
checking in.

=
void RelationSubjects::check_model(inference_subject_family *family,
	inference_subject *infs) {
	binary_predicate *bp = RelationSubjects::to_bp(infs);
	int f = Relations::Explicit::get_form_of_relation(bp);
	if ((bp->right_way_round) && ((f == Relation_OtoO) || (f == Relation_Sym_OtoO)))
		RelationSubjects::check_OtoO_relation(bp);
	if ((bp->right_way_round) && ((f == Relation_OtoV) || (f == Relation_VtoO)))
		RelationSubjects::check_OtoV_relation(bp);
}

void RelationSubjects::check_OtoO_relation(binary_predicate *bp) {
	int nc = NUMBER_CREATED(inference_subject);
	int *right_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **right_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **right_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));

	property *prn = Relations::Explicit::get_i6_storage_property(bp);

	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) right_counts[infs->allocation_id] = 0;
	LOOP_OVER(infs, inference_subject) {
		inference *inf1 = NULL;
		int leftc = 0;
		inference *inf;
		KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
			if ((World::Inferences::get_property(inf) == prn) &&
				(World::Inferences::get_certainty(inf) == CERTAIN_CE)) {
				parse_node *val = World::Inferences::get_property_value(inf);
				inference_subject *infs2 = InferenceSubjects::from_specification(val);
				leftc++;
				if (infs2) {
					int m = right_counts[infs2->allocation_id]++;
					if (m == 0) right_first[infs2->allocation_id] = inf;
					if (m == 1) right_second[infs2->allocation_id] = inf;
				}
				if (leftc == 1) inf1 = inf;
				if (leftc == 2) {
					StandardProblems::infs_contradiction_problem(_p_(BelievedImpossible),
						World::Inferences::where_inferred(inf1),
						World::Inferences::where_inferred(inf),
						infs, "can only relate to one other thing in this way",
						"since the relation in question is one-to-one.");
				}
			}
		}
	}
	LOOP_OVER(infs, inference_subject) {
		if (right_counts[infs->allocation_id] >= 2) {
			StandardProblems::infs_contradiction_problem(_p_(PM_Relation1to1Right),
				World::Inferences::where_inferred(right_first[infs->allocation_id]),
				World::Inferences::where_inferred(right_second[infs->allocation_id]),
				infs, "can only relate to one other thing in this way",
				"since the relation in question is one-to-one.");
		}
	}

	Memory::I7_array_free(right_second, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
	Memory::I7_array_free(right_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
}

void RelationSubjects::check_OtoV_relation(binary_predicate *bp) {
	int nc = NUMBER_CREATED(inference_subject);
	int *right_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **right_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **right_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	int *left_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **left_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **left_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));

	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) right_counts[infs->allocation_id] = 0;

	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, World::Inferences::bp_as_subject(bp),
		ARBITRARY_RELATION_INF) {
		parse_node *left_val = NULL;
		parse_node *right_val = NULL;
		World::Inferences::get_references_spec(inf, &left_val, &right_val);
		inference_subject *left_infs = InferenceSubjects::from_specification(left_val);
		inference_subject *right_infs = InferenceSubjects::from_specification(right_val);
		int left_id = (left_infs)?(left_infs->allocation_id):(-1);
		int right_id = (right_infs)?(right_infs->allocation_id):(-1);

		if (left_id >= 0) {
			int m = left_counts[left_id]++;
			if (m == 0) left_first[left_id] = inf;
			if (m == 1) left_second[left_id] = inf;
		}

		if (right_id >= 0) {
			int m = right_counts[right_id]++;
			if (m == 0) right_first[right_id] = inf;
			if (m == 1) right_second[right_id] = inf;
		}
	}

	if (Relations::Explicit::get_form_of_relation(bp) == Relation_VtoO) {
		LOOP_OVER(infs, inference_subject) {
			if (left_counts[infs->allocation_id] >= 2) {
				StandardProblems::infs_contradiction_problem(
					_p_(PM_RelationVtoOContradiction),
					World::Inferences::where_inferred(left_first[infs->allocation_id]),
					World::Inferences::where_inferred(left_second[infs->allocation_id]),
					infs, "can only relate to one other thing in this way",
					"since the relation in question is various-to-one.");
			}
		}
	} else {
		LOOP_OVER(infs, inference_subject) {
			if (right_counts[infs->allocation_id] >= 2) {
				StandardProblems::infs_contradiction_problem(
					_p_(PM_RelationOtoVContradiction),
					World::Inferences::where_inferred(right_first[infs->allocation_id]),
					World::Inferences::where_inferred(right_second[infs->allocation_id]),
					infs, "can only be related to by one other thing in this way",
					"since the relation in question is one-to-various.");
			}
		}
	}

	Memory::I7_array_free(right_second, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
	Memory::I7_array_free(left_second, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(left_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(left_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
}

