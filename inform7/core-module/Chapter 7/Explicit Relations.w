[Relations::Explicit::] Explicit Relations.

To draw inferences from the relations created explicitly by the
source text.

@h Managing the BPs generated.
The relations created in this section belong to the "explicit" family,
named so because their definitions are explicit in the source text. Initially,
there are none.

= (early code)
bp_family *explicit_bp_family = NULL;

@ =
void Relations::Explicit::start(void) {
	explicit_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(explicit_bp_family, TYPECHECK_BPF_MTID, Relations::Explicit::REL_typecheck);
	METHOD_ADD(explicit_bp_family, ASSERT_BPF_MTID, Relations::Explicit::REL_assert);
	METHOD_ADD(explicit_bp_family, SCHEMA_BPF_MTID, Relations::Explicit::REL_compile);
	METHOD_ADD(explicit_bp_family, DESCRIBE_FOR_PROBLEMS_BPF_MTID, Relations::Explicit::REL_describe_for_problems);
	METHOD_ADD(explicit_bp_family, DESCRIBE_FOR_INDEX_BPF_MTID, Relations::Explicit::REL_describe_briefly);
}

@ They typecheck by the default rule only:

=
int Relations::Explicit::REL_typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return DECLINE_TO_MATCH;
}

@ They are asserted thus. Note that if we have a symmetric relation then we need
to behave as if $B(y, x)$ had also been asserted whenever $B(x, y)$ has, if
$x\neq y$.

=
int Relations::Explicit::REL_assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {

	@<Reject non-assertable relations@>;
	if (BinaryPredicates::store_dynamically(bp)) {
		World::Inferences::draw_relation_spec(bp, spec0, spec1);
		return TRUE;
	} else {
		if ((infs0 == NULL) || (infs1 == NULL)) @<Reject relationship with nothing@>;
		if (BinaryPredicates::allow_arbitrary_assertions(bp)) {
			World::Inferences::draw_relation(bp, infs0, infs1);
			if ((BinaryPredicates::get_form_of_relation(bp) == Relation_Sym_VtoV) && (infs0 != infs1))
				World::Inferences::draw_relation(bp, infs1, infs0);
			return TRUE;
		}
		if (BinaryPredicates::is_explicit_with_runtime_storage(bp)) {
			Relations::Explicit::infer_property_based_relation(bp, infs1, infs0);
			if ((BinaryPredicates::get_form_of_relation(bp) == Relation_Sym_OtoO) && (infs0 != infs1))
				Relations::Explicit::infer_property_based_relation(bp, infs0, infs1);
			return TRUE;
		}
	}
	return FALSE;
}

@ This is the point at which non-assertable relations are thrown out.

@<Reject non-assertable relations@> =
	if (BinaryPredicates::can_be_made_true_at_runtime(bp) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Unassertable2),
			"the relationship you describe is not exact enough",
			"so that I do not know how to make this assertion come true. "
			"For instance, saying 'The Study is adjacent to the Hallway.' "
			"is not good enough because I need to know in what direction: "
			"is it east of the Hallway, perhaps, or west?");
		return TRUE;
	}

@<Reject relationship with nothing@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantRelateNothing),
		"the relationship you describe seems to be with nothing",
		"which does not really make sense. 'Nothing' looks like a noun, "
		"but really Inform uses it to mean the absence of one, so it's "
		"against the rules to say something like 'Mr Cogito disputes nothing' "
		"to try to put 'Mr Cogito' and 'nothing' into a relationship.");
	return TRUE;

@ This routine converts the knowledge that $R(ox, oy)$ into a single
inference. It can only be used for a simple subclass of the relations:
those which store |oy|, the only thing related to |ox|, in a given property
of |ox|. The beauty of this is that the "only thing related to" business
is then enforced by the inference mechanism, since an attempt to assert
both $R(x,y)$ and $R(x,z)$ will result in contradictory property value
inferences for $y$ and $z$.

=
void Relations::Explicit::infer_property_based_relation(binary_predicate *relation,
	inference_subject *infs0, inference_subject *infs1) {
	if (BinaryPredicates::get_form_of_relation(relation) == Relation_VtoO) {
		inference_subject *swap=infs0; infs0=infs1; infs1=swap;
	}
	property *prn = BinaryPredicates::get_i6_storage_property(relation);
	World::Inferences::draw_property(infs0, prn, InferenceSubjects::as_constant(infs1));
}

@ We need do nothing special: these relations can be compiled from their schemas.

=
int Relations::Explicit::REL_compile(bp_family *self, int task, binary_predicate *bp, annotated_i6_schema *asch) {
	return FALSE;
}

@ Problem message text:

=
int Relations::Explicit::REL_describe_for_problems(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
void Relations::Explicit::REL_describe_briefly(bp_family *self, OUTPUT_STREAM, binary_predicate *bp) {
	switch (bp->form_of_relation) {
		case Relation_OtoO: WRITE("one-to-one"); break;
		case Relation_OtoV: WRITE("one-to-various"); break;
		case Relation_VtoO: WRITE("various-to-one"); break;
		case Relation_VtoV: WRITE("various-to-various"); break;
		case Relation_Sym_OtoO: WRITE("one-to-another"); break;
		case Relation_Sym_VtoV: WRITE("various-to-each-other"); break;
		case Relation_Equiv: WRITE("in groups"); break;
		case Relation_ByRoutine: WRITE("defined"); break;
	}
}
