[CompileAtoms::] Compile Atoms.

Given an atom of a proposition we compile Inter code to test it, to make it
henceforth true, or to make it henceforth false.

@ First we make a schema for what we want, and then we ask //Compile Schemas//
to compile it:

=
void CompileAtoms::code_to_perform(int task, pcalc_prop *atom) {
	switch (task) {
		case TEST_ATOM_TASK:
			LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling condition: $o\n", atom); break;
		case NOW_ATOM_TRUE_TASK:
			LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling 'now': $o\n", atom); break;
		case NOW_ATOM_FALSE_TASK:
			LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling 'now' false: $o\n", atom); break;
		default: internal_error("unknown compile task");
	}
	@<Reject all discussion of the action variables in the past tense@>;
	annotated_i6_schema asch = Calculus::Schemas::blank_asch();
	if (CompileAtoms::annotate_schema(&asch, atom, task)) {
		CompileSchemas::from_annotated_schema(&asch);
	} else {
		if (problem_count == 0) @<Issue a fallback problem message@>;
	}
}

@<Reject all discussion of the action variables in the past tense@> =
	int uses_av = FALSE;
	for (int i=0; i<atom->arity; i++) {
		parse_node *operand = Terms::constant_underlying(&(atom->terms[i]));
		if (RTActions::is_an_action_variable(operand)) uses_av = TRUE;
	}
	if ((uses_av) && (Frames::used_for_past_tense()) && (problem_count == 0)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ActionVarsPastTense),
			"it is misleading to talk about the noun, the second noun or the person "
			"asked to do something in past tenses",
			"because in the past, those were different things and people, or may have "
			"been nothing at all. Writing 'if the noun has been unlocked' tends not to "
			"do what we might hope because the value of 'noun' changes every turn. "
			"So such conditions are not allowed, although to get around this we can "
			"instead write 'if we have unlocked the noun', which uses a special "
			"mechanism to remember everything which has happened to every object.");
		return;
	}

@<Issue a fallback problem message@> =
	LOG("Failed on task: $o\n", atom);
	if (task == TEST_ATOM_TASK)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this is not a condition I am able to test",
			"or at any rate not during play.");
	else
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantForceRelation),
			"this is not something I can make true with 'now'",
			"because it is too vague about the underlying cause which would "
			"need to be arranged.");

@ Which makes use of:

=
int CompileAtoms::annotate_schema(annotated_i6_schema *asch, pcalc_prop *atom, int task) {
	asch->pt0 = atom->terms[0]; asch->pt1 = atom->terms[1];
	if (atom->element == PREDICATE_ATOM) {
		switch(atom->arity) {
			case 1: @<Make an annotated schema for a unary predicate@>;
			case 2: @<Make an annotated schema for a binary predicate@>;
		}
	}
	return FALSE; /* signal that the atom cannot be compiled simply */
}

@ We hand over to the general UP apparatus for this.

@<Make an annotated schema for a unary predicate@> =
	if ((atom->terms[0].constant) && (atom->terms[0].term_checked_as_kind == NULL))
		atom->terms[0].term_checked_as_kind = Specifications::to_kind(atom->terms[0].constant);
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Unary predicate: $o, on: %u\n",
		atom, atom->terms[0].term_checked_as_kind);
	unary_predicate *tr = RETRIEVE_POINTER_unary_predicate(atom->predicate);
	UnaryPredicateFamilies::get_schema(task, tr, asch, atom->terms[0].term_checked_as_kind);
	if (asch->schema) return TRUE;
	return FALSE;

@ Delegation is similarly the art of compiling a BP:

@<Make an annotated schema for a binary predicate@> =
	if ((atom->terms[0].constant) && (atom->terms[0].term_checked_as_kind == NULL))
		atom->terms[0].term_checked_as_kind = Specifications::to_kind(atom->terms[0].constant);
	if ((atom->terms[1].constant) && (atom->terms[1].term_checked_as_kind == NULL))
		atom->terms[1].term_checked_as_kind = Specifications::to_kind(atom->terms[1].constant);
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Binary predicate: $o, on: %u, %u\n",
		atom, atom->terms[0].term_checked_as_kind, atom->terms[1].term_checked_as_kind);

	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(atom->predicate);
	binary_predicate *bp_to_assert = NULL;
	@<Undo any functional simplification of the relation@>;
	asch->schema = BinaryPredicateFamilies::get_schema(task, bp_to_assert, asch);
	if (asch->schema) return TRUE;
	return FALSE;

@ When a relation $R(x, y)$ has been simplified to $is(x, f_R(y))$ or $is(g_R(x), y)$,
it can be tested but not asserted true or false; we have to re-establish $R(x, y)$
before we can proceed.

@<Undo any functional simplification of the relation@> =
	if ((task != TEST_ATOM_TASK) && (bp == R_equality)) {
		if (atom->terms[0].function) {
			bp_to_assert = atom->terms[0].function->bp;
			asch->pt0 = atom->terms[0].function->fn_of;
		} else if (atom->terms[1].function) {
			bp_to_assert = atom->terms[1].function->bp;
			asch->pt1 = atom->terms[1].function->fn_of;
		}
		if (bp_to_assert == R_equality)
			internal_error("contraction of predicate applied to equality");
	}
	if (bp_to_assert == NULL) bp_to_assert = bp;
