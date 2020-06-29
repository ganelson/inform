[Calculus::Atoms::Compile::] Compile Atoms.

In this section, given an atom of a proposition we compile I6 code
as required for any of three possible outcomes: (i) to test whether it is
true, (ii) to make it henceforth true, or (iii) to make it henceforth false.

@h Definitions.

@ The compilation method is to look at the atom, work out a suitable I6
schema involving code to be applied to the one or two terms attaching to
the atom, and then expand this. In some circumstances, the process of
finding the schema will reveal that we need to apply it to different terms
from those originally found in the atom, however, so we also need to keep
track of that; and also of whether a condition is being regarded
negatively.

=
typedef struct annotated_i6_schema {
	struct i6_schema *schema;
	int negate_schema; /* true if atom is to be tested with the opposite parity */
	struct pcalc_term pt0; /* terms on which the I6 schema is to be expanded */
	struct pcalc_term pt1;
	int involves_action_variables;
} annotated_i6_schema;

@ Some constants to enumerate the three cases of what we are to do. This
looks asymmetrical -- shouldn't we also test to see whether an atom is false,
a fourth case?

The answer is that there's no need, since "test false" can be done by
compiling "test true" and applying the I7 negation operator |~~| to the
result. No similar trick can be used to combine making something
true or false into a single operation.

@d TEST_ATOM_TASK 1
@d NOW_ATOM_TRUE_TASK 2
@d NOW_ATOM_FALSE_TASK 3

@ For its internal purposes, Inform is sometimes able to compile atoms which
wouldn't be allowed in a typical use of "now" from the source text; so it
can suppress the following problem messages:

=
int suppress_C14CantChangeKind = FALSE;
int suppress_C14ActionVarsPastTense = FALSE;

@ So, then:

=
void Calculus::Atoms::Compile::emit(int task, pcalc_prop *pl, int with_semicolon) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	Calculus::Atoms::Compile::compile(&VH, task, pl, with_semicolon);
}

void Calculus::Atoms::Compile::compile(value_holster *VH, int task, pcalc_prop *pl, int with_semicolon) {
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
	asch = Calculus::Atoms::Compile::i6_schema_of_atom(&sch, pl, task);
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
annotated_i6_schema Calculus::Atoms::Compile::i6_schema_of_atom(i6_schema *sch, pcalc_prop *pl, int task) {
	annotated_i6_schema asch;

	Calculus::Schemas::modify(sch, " "); /* a non-NULL return in case problems occur */
	asch.schema = sch;
	asch.negate_schema = FALSE;
	asch.pt0 = pl->terms[0]; asch.pt1 = pl->terms[1];
	asch.involves_action_variables = Calculus::Atoms::Compile::atom_involves_action_variables(pl);

	switch(pl->element) {
		case CALLED_ATOM: @<Make an annotated schema for a CALLED atom@>;
		case KIND_ATOM: @<Make an annotated schema for a KIND atom@>;
		case EVERYWHERE_ATOM: @<Make an annotated schema for an EVERYWHERE atom@>;
		case NOWHERE_ATOM: @<Make an annotated schema for a NOWHERE atom@>;
		case HERE_ATOM: @<Make an annotated schema for a HERE atom@>;
		case PREDICATE_ATOM:
			switch(pl->arity) {
				case 1: @<Make an annotated schema for a unary predicate@>;
				case 2: @<Make an annotated schema for a binary predicate@>;
			}
	}

	asch.schema = NULL; /* signal that the atom cannot be compiled simply */
	return asch;
}

@ We are now able to look at the different types of atom one at a time.

CALLED atoms cannot be asserted, and to test them, we simply copy the
value into the local variable of the given name. Note then that here
the I6 |=| (set equal) operator is being used in a condition context:
there's a good chance that the value set is non-zero (since all objects
and enumerated values are non-zero), but it isn't necessarily so --
in Inform it's legal to quantify over times and truth states, for
instance, where 0 is a legal I6 value. So we use the comma operator
to throw away the result of the assignment, and evaluate the condition
to |true|.

@<Make an annotated schema for a CALLED atom@> =
	switch(task) {
		case TEST_ATOM_TASK: {
			wording W = Calculus::Atoms::CALLED_get_name(pl);
			Calculus::Schemas::modify(sch, "(%L=(*1), true)",
				LocalVariables::ensure_called_local(W, pl->assert_kind));
			return asch;
		}
		default: asch.schema = NULL; return asch;
	}

@ In any type-checked proposition, a |KIND| atom can only exist where it is
always at least sometimes true. In particular, if $K$ is a kind of value, then
the atom $K(v)$ can only exist where $v$ is of that kind of value, so that the
atom is always true when tested. But if $K$ is a kind of object, then $K(O)$
may occur in the proposition for any object $O$, where $O$ need not belong
to $K$ at all: so there is something substantive to check, which we do using
the I6 |ofclass| operator.

@<Make an annotated schema for a KIND atom@> =
	switch(task) {
		case TEST_ATOM_TASK:
			if (Kinds::Compare::lt(pl->assert_kind, K_object))
				Calculus::Schemas::modify(sch, "*1 ofclass %n",
					Kinds::RunTime::I6_classname(pl->assert_kind));
			else {
				if ((Kinds::get_construct(pl->assert_kind) == CON_list_of) && (problem_count == 0)) {
					Problems::quote_source(1, current_sentence);
					Problems::quote_kind(2, pl->assert_kind);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantCheckListContents));
					Problems::issue_problem_segment(
						"In %1, you use a list which might or might not match a "
						"definition requiring %2. But there's no efficient way to "
						"tell during play whether the list actually contains that, "
						"without laboriously checking every entry. Because "
						"in general this would be a bad idea, this usage is "
						"not allowed.");
					Problems::issue_problem_end();
				}
				Calculus::Schemas::modify(sch, "true");
			}
			return asch;
		case NOW_ATOM_TRUE_TASK:
		case NOW_ATOM_FALSE_TASK:
			if (suppress_C14CantChangeKind == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantChangeKind),
					"the kind of something is fixed",
					"and cannot be changed during play with a 'now'.");
				asch.schema = NULL;
			} else Calculus::Schemas::modify(sch, " ");
			return asch;
	}

@ An easy case. Note that |FoundEverywhere| is a template routine existing
to provide a common value of the I6 |found_in| property -- common that is
to all backdrops which are currently everywhere.

@<Make an annotated schema for an EVERYWHERE atom@> =
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(sch, "BackdropEverywhere(*1)");
			return asch;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(sch, "MoveObject(*1, FoundEverywhere); MoveFloatingObjects();");
			return asch;
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantChangeEverywhere),
				"not being 'everywhere' is not something which can be changed "
				"during play using 'now'",
				"because it's not exact enough about what needs to be done.");
			asch.schema = NULL; return asch;
	}

@ And another.

@<Make an annotated schema for a NOWHERE atom@> =
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(sch, "LocationOf(*1) == nothing");
			return asch;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(sch, "RemoveFromPlay(*1);");
			return asch;
		case NOW_ATOM_FALSE_TASK:
			Calculus::Schemas::modify(sch, "MoveObject(*1, real_location, 1, false);");
			return asch;
	}

@ And another. (In fact, at present |HERE| atoms are never included in
propositions to be compiled, so this code is never used.)

@<Make an annotated schema for a HERE atom@> =
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(sch, "LocationOf(*1) == location");
			return asch;
		case NOW_ATOM_TRUE_TASK:
		case NOW_ATOM_FALSE_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"being 'here' is not something which can be changed during play",
				"so it cannot be brought about or cancelled out with 'now'.");
			asch.schema = NULL; return asch;
	}

@ The last unary atom is an adjective, for which we hand over to the general
adjective apparatus.

@<Make an annotated schema for a unary predicate@> =
	int atask = 0; /* redundant assignment to appease |gcc -O2| */
	adjective_usage *tr = RETRIEVE_POINTER_adjective_usage(pl->predicate);
	adjective *aph = AdjectiveUsages::get_aph(tr);

	if (AdjectiveUsages::get_parity(tr) == FALSE) asch.negate_schema = TRUE;

	if ((pl->terms[0].constant) && (pl->terms[0].term_checked_as_kind == NULL))
		pl->terms[0].term_checked_as_kind = Specifications::to_kind(pl->terms[0].constant);

	switch(task) {
		case TEST_ATOM_TASK: atask = TEST_ADJECTIVE_TASK; break;
		case NOW_ATOM_TRUE_TASK: atask = NOW_ADJECTIVE_TRUE_TASK; break;
		case NOW_ATOM_FALSE_TASK: atask = NOW_ADJECTIVE_FALSE_TASK; break;
	}

	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Unary predicate: $o, on: $u\n", pl, pl->terms[0].term_checked_as_kind);
	asch.schema = Adjectives::Meanings::get_i6_schema(aph, pl->terms[0].term_checked_as_kind, atask);
	return asch;

@ Delegation is similarly the art of compiling a BP:

@<Make an annotated schema for a binary predicate@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	binary_predicate *bp_to_assert = NULL;

	@<Undo any functional simplification of the relation@>;
	asch.schema = BinaryPredicates::get_i6_schema(task, bp_to_assert, &asch);
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
int Calculus::Atoms::Compile::atom_involves_action_variables(pcalc_prop *pl) {
	#ifdef IF_MODULE
	for (int i=0; i<pl->arity; i++) {
		parse_node *operand = Calculus::Terms::constant_underlying(&(pl->terms[i]));
		if (PL::Actions::Patterns::is_an_action_variable(operand)) return TRUE;
	}
	#endif
	return FALSE;
}

@h An unannotated one.

=
annotated_i6_schema Calculus::Atoms::Compile::blank_asch(void) {
	annotated_i6_schema asch;
	asch.schema = Calculus::Schemas::new(" ");
	asch.negate_schema = FALSE;
	asch.pt0 = Calculus::Terms::new_variable(0);
	asch.pt1 = Calculus::Terms::new_variable(0);
	asch.involves_action_variables = FALSE;
	return asch;
}
