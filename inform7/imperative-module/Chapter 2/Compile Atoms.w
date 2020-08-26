[Atoms::Compile::] Compile Atoms.

In this section, given an atom of a proposition we compile I6 code
as required for any of three possible outcomes: (i) to test whether it is
true, (ii) to make it henceforth true, or (iii) to make it henceforth false.

@ The compilation method is to look at the atom, work out a suitable I6
schema involving code to be applied to the one or two terms attaching to
the atom, and then expand this. In some circumstances, the process of
finding the schema will reveal that we need to apply it to different terms
from those originally found in the atom, however, so we also need to keep
track of that; and also of whether a condition is being regarded
negatively.

@ For its internal purposes, Inform is sometimes able to compile atoms which
wouldn't be allowed in a typical use of "now" from the source text; so it
can suppress the following problem messages:

=
int suppress_C14ActionVarsPastTense = FALSE;

@ So, then:

=
void Atoms::Compile::emit(int task, pcalc_prop *pl, int with_semicolon) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	Atoms::Compile::compile(&VH, task, pl, with_semicolon);
}

void Atoms::Compile::compile(value_holster *VH, int task, pcalc_prop *pl, int with_semicolon) {
	i6_schema sch;
	annotated_i6_schema asch;

	switch (task) {
		case TEST_ATOM_TASK: LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling condition: $o\n", pl); break;
		case NOW_ATOM_TRUE_TASK: LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling 'now': $o\n", pl); break;
		case NOW_ATOM_FALSE_TASK: LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling 'now' false: $o\n", pl); break;
		default: internal_error("unknown compile task");
	}

	@<Stage 1: make an annotated schema from the atom@>;
	@<Stage 2: expand that schema to the output stream@>;
}

@h Stage 1.

@<Stage 1: make an annotated schema from the atom@> =
	asch = Atoms::Compile::i6_schema_of_atom(&sch, pl, task);
	if (asch.schema == NULL) {
		if (problem_count == 0)
			@<Issue a fallback problem message, since the schema-maker evidently didn't@>;
		return;
	}
	@<Reject all discussion of the action variables in the past tense@>;

@<Issue a fallback problem message, since the schema-maker evidently didn't@> =
	LOG("Failed on task: $o\n", pl);
	if (task == TEST_ATOM_TASK)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this is not a condition I am able to test",
			"or at any rate not during play.");
	else
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantForceRelation),
			"this is not something I can make true with 'now'",
			"because it is too vague about the underlying cause which would "
			"need to be arranged.");

@ This is in the user's own best interest.

@<Reject all discussion of the action variables in the past tense@> =
	if ((asch.involves_action_variables) &&
		(Frames::used_for_past_tense()) &&
		(suppress_C14ActionVarsPastTense == FALSE)) {
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActionVarsPastTense),
				"it is misleading to talk about the noun, the second noun "
				"or the person asked to do something in past tenses",
				"because in the past, those were different things and "
				"people, or may have been nothing at all. Writing "
				"'if the noun has been unlocked' tends not to do what we "
				"might hope because the value of 'noun' changes every turn. "
				"So such conditions are not allowed, although to get around "
				"this we can instead write 'if we have unlocked the noun', "
				"which uses a special mechanism to remember everything which "
				"has happened to every object.");
		return;
	}

@h Stage 2.
A valid I6 condition has to be bracketed, so we surround the output with
brackets if testing; and a valid I6 statement has to end with a semicolon,
so we terminate with that if making true or false.

@<Stage 2: expand that schema to the output stream@> =
	if (asch.negate_schema) {
		Produce::inv_primitive(Emit::tree(), NOT_BIP);
		Produce::down(Emit::tree());
	}
	Calculus::Schemas::emit_expand_from_terms(asch.schema, &(asch.pt0), &(asch.pt1), with_semicolon);
	if (asch.negate_schema) {
		Produce::up(Emit::tree());
	}

@h Constructing the schema.

=
annotated_i6_schema Atoms::Compile::i6_schema_of_atom(i6_schema *sch, pcalc_prop *pl, int task) {
	annotated_i6_schema asch;

	Calculus::Schemas::modify(sch, " "); /* a non-NULL return in case problems occur */
	asch.schema = sch;
	asch.negate_schema = FALSE;
	asch.pt0 = pl->terms[0]; asch.pt1 = pl->terms[1];
	asch.involves_action_variables = Atoms::Compile::atom_involves_action_variables(pl);
	if (pl->element == PREDICATE_ATOM) {
		switch(pl->arity) {
			case 1: @<Make an annotated schema for a unary predicate@>;
			case 2: @<Make an annotated schema for a binary predicate@>;
		}
	}
	asch.schema = NULL; /* signal that the atom cannot be compiled simply */
	return asch;
}

@ We hand over to the general UP apparatus for this.

@<Make an annotated schema for a unary predicate@> =
	if ((pl->terms[0].constant) && (pl->terms[0].term_checked_as_kind == NULL))
		pl->terms[0].term_checked_as_kind = Specifications::to_kind(pl->terms[0].constant);
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Unary predicate: $o, on: %u\n", pl, pl->terms[0].term_checked_as_kind);
	unary_predicate *tr = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	UnaryPredicateFamilies::get_schema(task, tr, &asch, pl->terms[0].term_checked_as_kind);
	return asch;

@ Delegation is similarly the art of compiling a BP:

@<Make an annotated schema for a binary predicate@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	binary_predicate *bp_to_assert = NULL;

	@<Undo any functional simplification of the relation@>;
	asch.schema = BinaryPredicateFamilies::get_schema(task, bp_to_assert, &asch);
	return asch;

@ When a relation $R(x, y)$ has been simplified to $is(x, f_R(y))$
or $is(g_R(x), y)$, it can be tested but not asserted true or false;
we have to re-establish $R(x, y)$ before we can proceed.

@<Undo any functional simplification of the relation@> =
	if ((task != TEST_ATOM_TASK) && (bp == R_equality)) {
		if (pl->terms[0].function) {
			bp_to_assert = pl->terms[0].function->bp;
			asch.pt0 = pl->terms[0].function->fn_of;
		} else if (pl->terms[1].function) {
			bp_to_assert = pl->terms[1].function->bp;
			asch.pt1 = pl->terms[1].function->fn_of;
		}
		if (bp_to_assert == R_equality)
			internal_error("contraction of predicate applied to equality");
	}
	if (bp_to_assert == NULL) bp_to_assert = bp;

@ =
int Atoms::Compile::atom_involves_action_variables(pcalc_prop *pl) {
	#ifdef IF_MODULE
	for (int i=0; i<pl->arity; i++) {
		parse_node *operand = Terms::constant_underlying(&(pl->terms[i]));
		if (PL::Actions::Patterns::is_an_action_variable(operand)) return TRUE;
	}
	#endif
	return FALSE;
}

@h An unannotated one.

=
annotated_i6_schema Atoms::Compile::blank_asch(void) {
	annotated_i6_schema asch;
	asch.schema = Calculus::Schemas::new(" ");
	asch.negate_schema = FALSE;
	asch.pt0 = Terms::new_variable(0);
	asch.pt1 = Terms::new_variable(0);
	asch.involves_action_variables = FALSE;
	return asch;
}
