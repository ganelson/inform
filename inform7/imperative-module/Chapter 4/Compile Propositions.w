[CompilePropositions::] Compile Propositions.

To compile a proposition within the body of the current function.

@h Compiling a test of a proposition.
Given a proposition $\phi$, and a value $v$, we compile a valid condition
to decide whether or not $\phi(v)$ is true. This is essentially how Inform
compiles something like "if all the doors are closed" -- where the proposition
has no free variable, so $v$ is never substituted -- or the test for something
like "taking an open container", where "an open container" is $\phi$ and $v$
is the item being taken.

=
void CompilePropositions::to_test_as_condition(parse_node *v, pcalc_prop *prop) {
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling as test: $D\n", prop);
	prop = Propositions::copy(prop);
	if (prop == NULL) {
		/* the empty proposition is always true */
		EmitCode::val_true();
	} else if (Deferrals::defer_test_of_proposition(v, prop) == FALSE) {
		if (v) Binding::substitute_var_0_in(prop, v);
		TRAVERSE_VARIABLE(atom);
		pcalc_prop *first_atom = prop, *last_atom = NULL;
		TRAVERSE_PROPOSITION(atom, prop) last_atom = atom;
		CompilePropositions::to_test_segment(prop, first_atom, last_atom);
	}
}

@ The following is used recursively to handle conjunctions and negations: it
tests the portion of a proposition between two atoms (including the two ends).

=
void CompilePropositions::to_test_segment(pcalc_prop *prop, pcalc_prop *from_atom,
	pcalc_prop *to_atom) {
	int active = FALSE, bl = 0;
	pcalc_prop *penult_atom = NULL;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop) {
		if (atom == from_atom) active = TRUE;
		if (active) {
			if ((bl == 0) && (atom != from_atom) &&
				(Propositions::implied_conjunction_between(atom_prev, atom))) {
				EmitCode::inv(AND_BIP); EmitCode::down();
				CompilePropositions::to_test_segment(prop, from_atom, atom_prev);
				CompilePropositions::to_test_segment(prop, atom, to_atom);
				EmitCode::up();
				return;
			}
			if (atom->element == NEGATION_CLOSE_ATOM) bl--;
			if (atom->element == NEGATION_OPEN_ATOM) bl++;
		}
		if (atom == to_atom) { active = FALSE; penult_atom = atom_prev; }
	}

	if ((from_atom->element == NEGATION_OPEN_ATOM) &&
		(to_atom->element == NEGATION_CLOSE_ATOM)) {
		if (from_atom == penult_atom) {
			/* the negation of empty proposition is always false */
			EmitCode::val_false();
		} else {
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
				CompilePropositions::to_test_segment(prop, from_atom->next, penult_atom);
			EmitCode::up();
		}
		return;
	}

	active = FALSE;
	TRAVERSE_PROPOSITION(atom, prop) {
		if (atom == from_atom) active = TRUE;
		if (active) CompileAtoms::code_to_perform(TEST_ATOM_TASK, atom);
		if (atom == to_atom) active = FALSE;
	}
}

@ The following wrapper tests if a variable $v$ matches a description $\phi$, which is a
case we need often enough to be worth its own function.

If the variable has kind $K$ then we conjoin to form ${\it kind}_K(v)\land\phi(v)$.
This will cause typechecking to fail if, say, the description "an open door" is
tested on a variable of kind "number". But we issue no problem message in that
case: we simply compile the condition as falsity. In this way, the test correctly
fails and without performing any type-unsafe operations on the value of the variable.

=
void CompilePropositions::to_test_if_variable_matches(parse_node *v, parse_node *desc) {
	if (desc == NULL) internal_error("VMD against null description");
	if (v == NULL) internal_error("VMD on null variable");
	if ((Lvalues::get_storage_form(v) != NONLOCAL_VARIABLE_NT) &&
		(Lvalues::get_storage_form(v) != LOCAL_VARIABLE_NT))
		internal_error("VMD on non-variable");
	LOG_INDENT;
	pcalc_prop *prop = SentencePropositions::from_spec(desc);
	kind *K = Specifications::to_kind(v);
	prop = Propositions::concatenate(
		KindPredicates::new_atom(K, Terms::new_variable(0)), prop);
	LOGIF(DESCRIPTION_COMPILATION, "[VMD: $P (%u) matches $D]\n", v, K, prop);
	if (TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting()) == NEVER_MATCH) {
		EmitCode::val_false();
	} else {
		CompilePropositions::to_test_as_condition(v, prop);
	}
	LOG_OUTDENT;
}

@h Making a proposition true.
Given a proposition $\phi$ with no free variables, compile code to make the
state of affairs it describes true. This is essentially how Inform compiles
something like "now all the doors are closed".

This is simpler, but a question arises of how to force $\lnot(\phi\land\psi)$ to
be true. It would be sufficient to falsify either one of $\phi$ or $\psi$
alone, but for the sake of symmetry we falsify both. (We took the same
decision when asserting propositions about the initial state of the model.)

=
void CompilePropositions::to_make_true(pcalc_prop *prop) {
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Compiling as 'now': $D\n", prop);
	@<Vet the proposition to be forced@>;
	if (Deferrals::defer_now_proposition(prop) == FALSE) {
		int parity = TRUE;
		TRAVERSE_VARIABLE(atom);
		TRAVERSE_PROPOSITION(atom, prop) {
			switch (atom->element) {
				case NEGATION_OPEN_ATOM: case NEGATION_CLOSE_ATOM:
					parity = (parity)?FALSE:TRUE;
					break;
				default:
					CompileAtoms::code_to_perform(
						(parity)?NOW_ATOM_TRUE_TASK:NOW_ATOM_FALSE_TASK, atom);
					break;
			}
		}
	}
}

@ We reject $\exists x$ because it would either require us to judge the $x$
most likely to be meant -- tricky -- or to create an $x$ out of nothing, which
it's too late for, since Inform does not have run-time object or value creation.

@<Vet the proposition to be forced@> =
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop) {
		if (atom->element == QUANTIFIER_ATOM) {
			if (Atoms::is_existence_quantifier(atom)) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_CantForceExistence),
					"this is not explicit enough",
					"and should set out definite relationships between specific things, "
					"like 'now the cat is in the bag', not something more elusive like "
					"'now the cat is carried by a woman.' (Which woman? That's the trouble.)");
				return;
			}
			if (Atoms::is_now_assertable_quantifier(atom) == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_CantForceGeneralised),
					"this can't be made true with 'now'",
					"because it is too vague about what it applies to. It's fine to say "
					"'now all the doors are open' or 'now none of the doors is open', "
					"because that clearly tells me which doors are affected; but if you "
					"write 'now six of the doors are open' or 'now almost all the doors "
					"are open', what am I to do?");
				return;
			}
		}
		if (CreationPredicates::is_calling_up_atom(atom)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_CantForceCalling),
				"a 'now' is not allowed to call names",
				"and it wouldn't really make sense to do so anyway. 'if a person (called "
				"the victim) is in the Trap Room' makes sense, because it gives a name - "
				"'victim' - to someone whose identity we don't know. But 'now a person "
				"(called the victim) is in the Trap Room' won't be allowed, because 'now' "
				"can only talk about people or things whose identities we do know.");
			return;
		}
	}

@ A variation on which: if we have a proposition $\phi(x)$ with one free variable,
and a value $t$, then we make it true that $\phi(t)$.

Ordinarily a problem message is triggered by attempting to change a kind, but we
allow it in this case so that, e.g., making "an open door" true about some door
will not throw the problem. The real issue here, of course, is that the user is
asserting the openness, and does not mean to be changing the doorness at all.

=
void CompilePropositions::to_make_true_about(pcalc_prop *prop, parse_node *t) {
	Binding::substitute_var_0_in(prop, t);
	TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting());
	int save_cck = suppress_C14CantChangeKind;
	suppress_C14CantChangeKind = TRUE;
	CompilePropositions::to_make_true(prop);
	suppress_C14CantChangeKind = save_cck;
}

@h Compiling code about the values matching a description.
Given a description containing the proposition $\phi(x)$, how many $x$ in its
domain of validity currently satisfy this? And so on.

In a few cases where the answer is known at compile time, we optimise: for
example, "the number of containers" or "the list of vehicles" can be known now.
But as soon as qualifying adjectives or subclauses are brought in, it's no
longer possible to know at compile-time.

=
void CompilePropositions::to_number_of_matches(parse_node *desc) {
	pcalc_prop *prop = Node::get_proposition(desc);
	if (Propositions::length(prop) == 1) {
		kind *K = Propositions::describes_kind(prop);
		int N = ListLiterals::extent_of_instance_list(K);
		if (N >= 0) {
			EmitCode::val_number((inter_ti) N);
			return;
		}
	}
	if (Deferrals::defer_number_of_matches(desc)) return;
	internal_error("no way to compile this without deferral");
}

void CompilePropositions::to_list_of_matches(parse_node *desc, kind *K) {
	pcalc_prop *prop = Node::get_proposition(desc);
	if (Propositions::length(prop) == 1) {
		kind *K = Propositions::describes_kind(prop);
		inter_name *iname = ListLiterals::get_instance_list(K);
		if (iname) {
			EmitCode::val_iname(K_value, iname);
			return;
		}
	}
	if (Deferrals::defer_list_of_matches(desc, K)) return;
	internal_error("no way to compile this without deferral");
}

void CompilePropositions::to_random_match(parse_node *desc) {
	pcalc_prop *prop = Node::get_proposition(desc);
	if (Propositions::length(prop) == 1) {
		kind *K = Propositions::describes_kind(prop);
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			EmitCode::inv(INDIRECT0_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value,
					RTKindConstructors::random_value_fn_iname(K));
			EmitCode::up();
			return;
		}
	}
	if (Deferrals::defer_random_match(desc)) return;
	internal_error("no way to compile this without deferral");
}

void CompilePropositions::to_total_of_matches(property *prn, parse_node *desc) {
	if (Deferrals::defer_total_of_matches(prn, desc)) return;
	internal_error("no way to compile this without deferral");
}

void CompilePropositions::to_extremal_match(parse_node *desc, property *prn, int sign) {
	if (Deferrals::defer_extremal_match(desc, prn, sign)) return;
	internal_error("no way to compile this without deferral");
}

void CompilePropositions::to_test_if_matches(parse_node *in, parse_node *desc) {
	if (Deferrals::defer_if_matches(in, desc)) return;
	internal_error("no way to compile this without deferral");
}

@h Checking the validity of a description.
The following utility routine checks that a proposition contains exactly one
free variable, producing problem messages if not -- all of that is really just
defensive programming; if Inform is correctly written, none of these conditions
can ever occur -- but also typechecking the proposition, which does do something
and can indeed throw problems.

=
void CompilePropositions::verify_descriptive(pcalc_prop *prop, char *billing,
	parse_node *constructor) {
	if (constructor == NULL) internal_error("description with null constructor");

	/* best guess at the text to quote in any problem message */
	wording EW = Node::get_text(constructor);
	if ((Wordings::empty(EW)) && (constructor->down))
		EW = Node::get_text(constructor->down);

	if (Binding::is_well_formed(prop, NULL) == FALSE)
		internal_error("malformed proposition in description verification");

	int N = Binding::number_free(prop);

	if (N == 1)
		TypecheckPropositions::type_check(prop,
			TypecheckPropositions::tc_problem_reporting(EW,
			"involve a range of objects matching a description"));

	if (N > 1) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_text(2, billing);
		Problems::quote_wording(3, EW);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"In %1, you are asking for %2, but this should range over a simpler "
			"description than '%3', please - it should not include any determiners such "
			"as 'at least three', 'all' or 'most'. (The range is always taken to be all "
			"of the things matching the description.)");
		Problems::issue_problem_end();
		return;
	}

	if (N < 1) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_text(2, billing);
		Problems::quote_wording(3, EW);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"In %1, you are asking for %2, but '%3' looks as if it ranges over only a "
			"single specific object, not a whole collection of objects.");
		Problems::issue_problem_end();
	}
}
