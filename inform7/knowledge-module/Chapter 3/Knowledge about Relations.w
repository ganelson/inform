[KnowledgeAboutRelations::] Knowledge about Relations.

To store inferences about the state of relationships.

@

=
wording KnowledgeAboutRelations::SUBJ_get_name_text(inference_subject *from) {
	return EMPTY_WORDING; /* nameless */
}

general_pointer KnowledgeAboutRelations::SUBJ_new_permission_granted(inference_subject *from) {
	return NULL_GENERAL_POINTER;
}

void KnowledgeAboutRelations::SUBJ_make_adj_const_domain(inference_subject *infs,
	instance *nc, property *prn) {
}

void KnowledgeAboutRelations::SUBJ_complete_model(inference_subject *infs) {
	int domain_size = NUMBER_CREATED(inference_subject);
	binary_predicate *bp = InferenceSubjects::as_bp(infs);

	if (BinaryPredicates::store_dynamically(bp)) return; /* handled at run-time instead */
	if ((BinaryPredicates::get_form_of_relation(bp) == Relation_Equiv) && (bp->right_way_round)) {
		Relations::equivalence_relation_make_singleton_partitions(bp, domain_size);
		inference *i;
		POSITIVE_KNOWLEDGE_LOOP(i, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
			inference_subject *infs0, *infs1;
			World::Inferences::get_references(i, &infs0, &infs1);
			Relations::equivalence_relation_merge_classes(bp, domain_size,
				infs0->allocation_id, infs1->allocation_id);
		}
		Relations::equivalence_relation_add_properties(bp);
	}
}

void KnowledgeAboutRelations::SUBJ_check_model(inference_subject *infs) {
	binary_predicate *bp = InferenceSubjects::as_bp(infs);
	if ((bp->right_way_round) &&
		((bp->form_of_relation == Relation_OtoO) ||
			(bp->form_of_relation == Relation_Sym_OtoO)))
		Relations::check_OtoO_relation(bp);
	if ((bp->right_way_round) &&
		((bp->form_of_relation == Relation_OtoV) ||
			(bp->form_of_relation == Relation_VtoO)))
		Relations::check_OtoV_relation(bp);
}

int KnowledgeAboutRelations::SUBJ_emit_element_of_condition(inference_subject *infs, inter_symbol *t0_s) {
	internal_error("BP in runtime match condition");
	return FALSE;
}

int KnowledgeAboutRelations::SUBJ_compile_all(void) {
	return FALSE;
}

void KnowledgeAboutRelations::SUBJ_compile(inference_subject *infs) {
	binary_predicate *bp = InferenceSubjects::as_bp(infs);
	if (bp->right_way_round) {
		if (BinaryPredicates::store_dynamically(bp)) {
			packaging_state save = Routines::begin(bp->initialiser_iname);
			inference *i;
			inter_name *rtiname = Hierarchy::find(RELATIONTEST_HL);
			POSITIVE_KNOWLEDGE_LOOP(i, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
				parse_node *spec0, *spec1;
				World::Inferences::get_references_spec(i, &spec0, &spec1);
				BinaryPredicates::mark_as_needed(bp);
				Produce::inv_call_iname(Emit::tree(), rtiname);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, bp->bp_iname);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ASSERT_TRUE_HL));
					Specifications::Compiler::emit_as_val(K_value, spec0);
					Specifications::Compiler::emit_as_val(K_value, spec1);
				Produce::up(Emit::tree());
			}
			Routines::end(save);
		} else {
			if ((bp->form_of_relation == Relation_VtoV) ||
				(bp->form_of_relation == Relation_Sym_VtoV))
				Relations::compile_vtov_storage(bp);
		}
	}
}
