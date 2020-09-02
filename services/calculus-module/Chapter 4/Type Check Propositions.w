[Propositions::Checker::] Type Check Propositions.

Predicate calculus is a largely symbolic exercise, and its rules of
working tend to assume that all predicates are meaningful for all terms: this
means, for instance, that "if blue is 14" is likely to make a well-formed
sentence in predicate calculus. In this section we reject such propositions
on the grounds that they violate type-checking requirements on relations --
in this example, the equality relation.

@ We can unambiguously find the kind of value of any constant $C$, so if a
proposition's terms are all constant then type-checking is easy. ${\it is}(4, |score|)$
good, ${\it is}(4, |"fish"|)$ bad. The subtlety comes in interpreting
${\it is}(4, x)$, where $x$ is a variable. Our calculus allows variables to
range over many domains -- numbers, texts, scenes, objects, and so on.

@h Problem reporting kit.
The caller to |Propositions::Checker::type_check| has to fill this form out first. Paperwork,
what can you do, eh?

@d DECLINE_TO_MATCH 1000 /* not one of the three legal |*_MATCH| values */
@d NEVER_MATCH_SAYING_WHY_NOT 1001 /* not one of the three legal |*_MATCH| values */

=
typedef struct tc_problem_kit {
	int issue_error;
	struct wording ew_text;
	char *intention;
	int log_to_I6_text;
	int flag_problem;
} tc_problem_kit;

tc_problem_kit Propositions::Checker::tc_no_problem_reporting(void) {
	tc_problem_kit tck;
	tck.issue_error = FALSE; tck.ew_text = EMPTY_WORDING; tck.intention = "be silent checking";
	tck.log_to_I6_text = FALSE; tck.flag_problem = FALSE; return tck;
}

tc_problem_kit Propositions::Checker::tc_problem_reporting(wording W, char *intent) {
	tc_problem_kit tck = Propositions::Checker::tc_no_problem_reporting();
	tck.issue_error = TRUE; tck.ew_text = W; tck.intention = intent;
	return tck;
}

@ A version used only for the internal testing mode, when we print the outcome
into the debugging log, but diverted to an I6 string in the compiled code.

=
tc_problem_kit Propositions::Checker::tc_problem_logging(void) {
	tc_problem_kit tck = Propositions::Checker::tc_no_problem_reporting();
	tck.intention = "be internal testing"; tck.log_to_I6_text = TRUE; return tck;
}

@h Type-checking whole propositions.
This section provides a single routine to the rest of Inform: |Propositions::Checker::type_check|.
We determine the kinds for all variables, then work through the proposition,
ensuring that every predicate-like atom has terms which match at least one
possible reading of the meaning of the atom.

As usual in Inform, type-checking is not a passive process. If it can make
sense of the proposition by changing it, it will do so.

=
int Propositions::Checker::type_check(pcalc_prop *prop, tc_problem_kit tck_s) {
	TRAVERSE_VARIABLE(pl);
	variable_type_assignment vta;
	tc_problem_kit *tck = &tck_s;

	LOGIF(MATCHING, "Type-checking proposition: $D\n", prop);

	int j;
	if (prop == NULL) return ALWAYS_MATCH;
	if (Binding::is_well_formed(prop, NULL) == FALSE)
		internal_error("type-checking malformed proposition");

	@<First make sure any constants in the proposition have themselves been typechecked@>;

	for (j=0; j<26; j++) vta.assigned_kinds[j] = NULL;
	@<Look at KIND atoms to see what kinds of value are asserted for the variables@>;
	@<Look at KIND atoms to reject unarticled shockers@>;
	@<Assume any still-unfathomable variables represent objects@>;

	TRAVERSE_PROPOSITION(pl, prop) {
		for (j=0; j<pl->arity; j++) Propositions::Checker::kind_of_term(&(pl->terms[j]), &vta, tck);
		if (tck->flag_problem) return NEVER_MATCH;
		if ((pl->element == PREDICATE_ATOM) && (pl->arity == 2))
			@<A binary predicate is required to apply to terms of the right kinds@>;
		if ((pl->element == PREDICATE_ATOM) && (pl->arity == 1))
			@<A unary predicate is required to have an interpretation matching the kind of its term@>;
	}

	if (tck->log_to_I6_text) @<Show the variable assignment in the debugging log@>;
	return ALWAYS_MATCH;
}

@h Finding kinds for variables.
Every specification compiled by Inform has to pass through type-checking.
That includes the ones which occur as constants inside propositions, and this is
where.

The presence of an |UNKNOWN_NT| constant indicates something which failed to be
recognised by the S-parser. That shouldn't happen, but we allow for it so that
we can recover from an already reported problem.

Perhaps surprisingly, we don't reject generic constants: this is so that
sentences like

>> A thing usually weighs 10kg.

...can work -- here the generic constant for "thing" is treated as a noun,
since it can be the subject of inferences all by itself. So it can legitimately
be a term in a proposition.

@<First make sure any constants in the proposition have themselves been typechecked@> =
	TRAVERSE_PROPOSITION(pl, prop) {
		for (int j=0; j<pl->arity; j++) {
			parse_node *spec = Terms::constant_underlying(&(pl->terms[j]));
			if (spec) {
				#ifdef CORE_MODULE
				int rv = NEVER_MATCH;
				if (!(Node::is(spec, UNKNOWN_NT))) {
					if (tck->issue_error) rv = Dash::check_value(spec, NULL);
					else rv = Dash::check_value_silently(spec, NULL);
				}
				#endif
				#ifndef CORE_MODULE
				int rv = ALWAYS_MATCH;
				#endif
				if (rv == NEVER_MATCH)
					@<Recover from problem in S-parser by not issuing problem@>;
			}
		}
	}

@ If the proposition contains contradictory |KIND| atoms, it automatically fails
type-checking, even if there is no implication that both apply at once. This
throws out, for instance:
= (text)
	1. a scene which is not a number
	[ scene(x) & NOT[ number(x) NOT] ]
	Failed: proposition would not type-check
	x is both scene and number
=
It could be argued that all scenes ought to pass this proposition, but we will
treat it as a piece of nonsense, like "if Wednesday is not custard".

@<Look at KIND atoms to see what kinds of value are asserted for the variables@> =
	TRAVERSE_PROPOSITION(pl, prop)
		if (KindPredicates::is_kind_atom(pl)) {
			int v = pl->terms[0].variable;
			if (v >= 0) {
				kind *new_kind = KindPredicates::get_kind(pl);
				if (Kinds::Behaviour::is_object(new_kind)) new_kind = K_object;
				kind *old_kind = vta.assigned_kinds[v];
				if (old_kind) {
					if (Kinds::compatible(old_kind, new_kind) == NEVER_MATCH) {
						if (tck->log_to_I6_text)
							LOG("%c is both %u and %u\n", pcalc_vars[v], old_kind, new_kind);
						Propositions::Checker::issue_kind_typecheck_error(old_kind, new_kind, tck, pl);
						return NEVER_MATCH;
					}
					if (Kinds::Behaviour::definite(new_kind) == FALSE) new_kind = old_kind;
				}
				vta.assigned_kinds[v] = new_kind;
			}
		}

@ The following is arguably a problem which should have been thrown earlier,
but it's a very subtle one, and we want to use it only when everything else
(more or less) has worked.

@<Look at KIND atoms to reject unarticled shockers@> =
	TRAVERSE_PROPOSITION(pl, prop)
		if (KindPredicates::is_unarticled_atom(pl)) {
			if (tck->log_to_I6_text) LOG("Rejecting as unarticled\n");
			if (tck->issue_error == FALSE) return NEVER_MATCH;
			Propositions::Checker::problem(BareKindVariable_CALCERROR,
				NULL, EMPTY_WORDING, NULL, NULL, NULL, tck);
			return NEVER_MATCH;
		}

@ It's possible for a proposition to specify nothing about the kind of a
variable (usually a free one). If so, it's assumed to be an object. For
instance, if we define

>> Definition: a container is empty if the number of things in it is 0.

then we find that, say:
= (text)
	1. empty which is empty
	[ 'empty'(x) & 'empty'(x) ]
	x (free) - object.
=
though in fact it would also have been viable for $x$ to be a rulebook, a list,
or various other kinds of value.

@<Assume any still-unfathomable variables represent objects@> =
	int j;
	for (j=0; j<26; j++)
		if (vta.assigned_kinds[j] == NULL)
			vta.assigned_kinds[j] = K_object;

@ The following is really rather paranoid; it ought to be certain that a
problem message has already been issued, but just in case not...

@<Recover from problem in S-parser by not issuing problem@> =
	if (problem_count == 0) {
		if (tck->log_to_I6_text) LOG("Atom $o contains failed constant\n", pl);
		if (tck->issue_error == FALSE) return NEVER_MATCH;
		Propositions::Checker::problem(ConstantFailed_CALCERROR, spec,
			EMPTY_WORDING, NULL, NULL, NULL, tck);
	}
	return NEVER_MATCH;

@<A unary predicate is required to have an interpretation matching the kind of its term@> =
	unary_predicate *up = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	if (UnaryPredicateFamilies::typecheck(up, pl, &vta, tck) == NEVER_MATCH) {
		if (tck->log_to_I6_text) LOG("UP $o cannot be applied\n", pl);
		return NEVER_MATCH;
	}

@ The BP case is interesting because it forgives a failure in one case: of
${\it is}(t, C)$, where $C$ is a constant representing a value of an enumerated
kind. Sentence conversion is actually quite good at distinguishing these cases
and can see the difference between "the bus is red" and "the fashionable hue
is red", but it is defeated by cases where adjectives representing values are
used about other values -- "the Communist Rally is red", where "Communist
Rally" is a scene rather than an object, for instance. We first try requiring
|Rally| to be a colour: when that fails, we see if the atom ${\it red}(|Rally|)$
would work instead. If it would, we make the change within the proposition.

@<A binary predicate is required to apply to terms of the right kinds@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	if (BinaryPredicates::is_the_wrong_way_round(bp)) internal_error("BP wrong way round");
	if (Propositions::Checker::type_check_binary_predicate(pl, &vta, tck) == NEVER_MATCH) {
		if (bp == R_equality) {
			unary_predicate *alt = Terms::noun_to_adj_conversion(pl->terms[1]);
			if (alt) {
				pcalc_prop test_unary = *pl;
				test_unary.arity = 1;
				test_unary.predicate = STORE_POINTER_unary_predicate(alt);
				if (Propositions::Checker::type_check_unary_predicate(&test_unary, &vta, tck) == NEVER_MATCH)
					@<The BP fails type-checking@>;
				pl->arity = 1;
				pl->predicate = STORE_POINTER_unary_predicate(alt);
			} else @<The BP fails type-checking@>;
		} else @<The BP fails type-checking@>;
	}

@<The BP fails type-checking@> =
	if (tck->log_to_I6_text) LOG("BP $o cannot be applied\n", pl);
	return NEVER_MATCH;

@ Not so much for the debugging log as for the internal test, in fact, which
prints the log to an I6 string. This is the type-checking report in the case
of success.

@<Show the variable assignment in the debugging log@> =
	int var_states[26], c=0;
	Binding::determine_status(prop, var_states, NULL);
	for (int j=0; j<26; j++)
		if (var_states[j] != UNUSED_VST) {
			LOG("%c%s - %u. ", pcalc_vars[j],
				(var_states[j] == FREE_VST)?" (free)":"",
				vta.assigned_kinds[j]); c++;
		}
	if (c>0) LOG("\n");

@h The kind of a term.
The following routine works out the kind of value stored in a term, something
which requires contextual information: unless we know the kind of value stored
in each variable, we cannot know the kind of value a general term represents,
which is why the routine is here and not in the Terms section.

=
kind *Propositions::Checker::kind_of_term(pcalc_term *pt, variable_type_assignment *vta,
	tc_problem_kit *tck) {
	kind *K = Propositions::Checker::kind_of_term_inner(pt, vta, tck);
	pt->term_checked_as_kind = K;
	if (K == NULL) { LOGIF(MATCHING, "No kind for term $0 = $T\n", pt, pt->constant); tck->flag_problem = TRUE; }
	return K;
}

@ The case needing attention is a term in the form $t = f_B(s)$. By recursion
we can know the kind of $s$, but we must check that $f_B$ can validly be applied
to a value of that kind. If $B$ is a binary predicate with domains $R$ and $S$
(i.e., a subset of $R\times S$) then we will either have $f_B:R\to S$ or vice
versa; so we have to check that $s$ lies in $R$ (or $S$, respectively).

=
kind *Propositions::Checker::kind_of_term_inner(pcalc_term *pt, variable_type_assignment *vta,
	tc_problem_kit *tck) {
	if (pt->constant) return VALUE_TO_KIND_FUNCTION(pt->constant);
	if (pt->variable >= 0) return vta->assigned_kinds[pt->variable];
	if (pt->function) {
		binary_predicate *bp = pt->function->bp;
		kind *kind_found = Propositions::Checker::kind_of_term(&(pt->function->fn_of), vta, tck);
		kind *kind_from = Propositions::Checker::approximate_argument_kind(bp, pt->function->from_term);
		kind *kind_to = Propositions::Checker::approximate_argument_kind(bp, 1 - pt->function->from_term);
		if ((kind_from) && (Kinds::compatible(kind_found, kind_from) == NEVER_MATCH)) {
			if (tck->log_to_I6_text)
				LOG("Term $0 applies function to %u not %u\n", pt, kind_found, kind_from);
			Propositions::Checker::issue_bp_typecheck_error(bp, kind_found, kind_to, tck);
			kind_found = kind_from; /* the better to recover */
		}
		if (kind_to) return kind_to;
		return kind_found;
	}
	return NULL;
}

@ Some relations specify a kind for their terms, others do not. When they do
specify a kind of object, we usually want to be forgiving about nuances of
the kind of object -- for our purposes here, any object will do. (Run-time
type checking takes care of those nuances better.)

The following gives the kind of a given term. It should be used only where
the BP is one constraining its terms, such as when it provides a $f_B$
function.

=
kind *Propositions::Checker::approximate_argument_kind(binary_predicate *bp, int i) {
	kind *K = BinaryPredicates::term_kind(bp, i);
	if (K == NULL) return K_object;
	return Kinds::weaken(K, K_object);
}

@h Type-checking predicates.
We take unary predicates first, then binary. Unary predicates are just
adjectives, and all of the work for that has already been done, so we need
only produce a problem message when the worst happens.

=
int Propositions::Checker::type_check_unary_predicate(pcalc_prop *pl, variable_type_assignment *vta,
	tc_problem_kit *tck) {
	unary_predicate *tr = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	if (UnaryPredicateFamilies::typecheck(tr, pl, vta, tck) == NEVER_MATCH)
		return NEVER_MATCH;
	return ALWAYS_MATCH;
}

@ Binary predicates (BPs) are both easier and harder. Easier because they
have only one definition at a time (unlike, say, the adjective "empty"),
harder because the work hasn't already been done and because some BPs --
like "is" -- are polymorphic. Here goes:

=
int Propositions::Checker::type_check_binary_predicate(pcalc_prop *pl, variable_type_assignment *vta,
	tc_problem_kit *tck) {
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	kind *kinds_of_terms[2], *kinds_required[2];

	@<Work out what kinds we find@>;
	#ifdef VERB_MEANING_UNIVERSAL
	if (bp == VERB_MEANING_UNIVERSAL) @<Adapt to the universal relation@>;
	#endif
	@<Work out what kinds we should have found@>;

	int result = BinaryPredicateFamilies::typecheck(bp, kinds_of_terms, kinds_required, tck);
	if (result == NEVER_MATCH_SAYING_WHY_NOT) {
		kind *kinds_dereferencing_properties[2];
		LOG("0 = %u. 1 = %u\n", kinds_of_terms[0], kinds_of_terms[1]);
		kinds_dereferencing_properties[0] = Kinds::dereference_properties(kinds_of_terms[0]);
		kinds_dereferencing_properties[1] = kinds_of_terms[1];
		int r2 = BinaryPredicateFamilies::typecheck(bp, kinds_dereferencing_properties, kinds_required, tck);
		if ((r2 == ALWAYS_MATCH) || (r2 == SOMETIMES_MATCH)) result = r2;
	}

	if (result != DECLINE_TO_MATCH) {
		if (result == NEVER_MATCH_SAYING_WHY_NOT) {
			if (tck->issue_error == FALSE) return NEVER_MATCH;
			if (pl->terms[0].function)
				Propositions::Checker::issue_bp_typecheck_error(pl->terms[0].function->bp,
					Propositions::Checker::kind_of_term(&(pl->terms[0].function->fn_of), vta, tck),
					kinds_of_terms[1], tck);
			else if (pl->terms[1].function)
				Propositions::Checker::issue_bp_typecheck_error(pl->terms[1].function->bp,
					kinds_of_terms[0],
					Propositions::Checker::kind_of_term(&(pl->terms[1].function->fn_of), vta, tck),
					tck);
			else {
				LOG("(%u, %u) failed in $2\n", kinds_of_terms[0], kinds_of_terms[1], bp);
				Propositions::Checker::problem(ComparisonFailed_CALCERROR, NULL, EMPTY_WORDING,
					kinds_of_terms[0], kinds_of_terms[1], NULL, tck);
			}
			return NEVER_MATCH;
		}
		return result;
	}

	@<Apply default rule applying to most binary predicates@>;

	return ALWAYS_MATCH;
}

@ Once again we treat any kind of object as just "object", but we do take
note that some BPs -- like "is" -- specify no kinds at all, and so
produce a |kinds_required| which is |NULL|.

@<Work out what kinds we should have found@> =
	for (int i=0; i<2; i++) {
		kind *K = Kinds::weaken(BinaryPredicates::term_kind(bp, i), K_object);
		if (K == NULL) K = K_object;
		kinds_required[i] = K;
	}

@<Work out what kinds we find@> =
	for (int i=0; i<2; i++)
		kinds_of_terms[i] =
			Propositions::Checker::kind_of_term(&(pl->terms[i]), vta, tck);

@<Adapt to the universal relation@> =
	if (Kinds::get_construct(kinds_of_terms[0]) != CON_relation) {
		Propositions::Checker::problem(BadUniversal1_CALCERROR, NULL, EMPTY_WORDING,
			kinds_of_terms[0], NULL, NULL, tck);
		return NEVER_MATCH;
	}
	if (Kinds::get_construct(kinds_of_terms[1]) != CON_combination) {
		Propositions::Checker::problem(BadUniversal2_CALCERROR, NULL, EMPTY_WORDING,
			kinds_of_terms[1], NULL, NULL, tck);
		return NEVER_MATCH;
	}

	parse_node *left = pl->terms[0].constant;
	if (Node::is(left, CONSTANT_NT)) {
		bp = VALUE_TO_RELATION_FUNCTION(left);
		kind *cleft = NULL, *cright = NULL;
		Kinds::binary_construction_material(kinds_of_terms[1], &cleft, &cright);
		kinds_of_terms[0] = cleft;
		kinds_of_terms[1] = cright;
	}

@ The default rule is straightforward: the kinds found have to match the kinds
required.

@<Apply default rule applying to most binary predicates@> =
	int i;
	for (i=0; i<2; i++)
		if (kinds_required[i])
			if (Kinds::compatible(kinds_of_terms[i], kinds_required[i]) == NEVER_MATCH) {
				if (tck->log_to_I6_text)
					LOG("Term %d is %u not %u\n",
						i, kinds_of_terms[i], kinds_required[i]);
				Propositions::Checker::issue_bp_typecheck_error(bp,
					kinds_of_terms[0], kinds_of_terms[1], tck);
				return NEVER_MATCH;
			}

@h Two problem messages needed more than once.

=
void Propositions::Checker::issue_bp_typecheck_error(binary_predicate *bp,
	kind *t0, kind *t1, tc_problem_kit *tck) {
	Propositions::Checker::problem(BinaryMisapplied2_CALCERROR, NULL, EMPTY_WORDING,
		t0, t1, bp, tck);
}

void Propositions::Checker::issue_kind_typecheck_error(kind *actually_find,
	kind *need_to_find, tc_problem_kit *tck, pcalc_prop *ka) {
	binary_predicate *bp = (ka)?(ka->saved_bp):NULL;
	if (bp) {
		Propositions::Checker::problem(BinaryMisapplied1_CALCERROR, NULL, EMPTY_WORDING,
			actually_find, need_to_find, bp, tck);
	} else {
		Propositions::Checker::problem(KindMismatch_CALCERROR, NULL, EMPTY_WORDING,
			actually_find, need_to_find, bp, tck);
	}
}

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_SYNTAX_CALLBACK|
to some routine of her own, gazumping this one.

@e BareKindVariable_CALCERROR from 1
@e ConstantFailed_CALCERROR
@e UnaryMisapplied_CALCERROR
@e ComparisonFailed_CALCERROR
@e BadUniversal1_CALCERROR
@e BadUniversal2_CALCERROR
@e BinaryMisapplied1_CALCERROR
@e BinaryMisapplied2_CALCERROR
@e KindMismatch_CALCERROR

=
void Propositions::Checker::problem(int err_no, parse_node *spec, wording W,
	kind *K1, kind *K2, binary_predicate *bp, tc_problem_kit *tck) {
	#ifdef PROBLEM_CALCULUS_CALLBACK
	PROBLEM_CALCULUS_CALLBACK(err_no, spec, W, K1, K2, bp, tck);
	#endif
	#ifndef PROBLEM_CALCULUS_CALLBACK
	TEMPORARY_TEXT(text)
	WRITE_TO(text, "%+W", Node::get_text(current_sentence));
	switch (err_no) {
		case BareKindVariable_CALCERROR:
			Errors::with_text("letter variable used where noun expected: %S", text);
			break;
		case ConstantFailed_CALCERROR:
			Errors::with_text("constant made no sense: %S", text);
			break;
		case UnaryMisapplied_CALCERROR:
			Errors::with_text("unary predicate misapplied: %S", text);
			break;
		case ComparisonFailed_CALCERROR:
			Errors::with_text("compared incomparable values: %S", text);
			break;
		case BadUniversal1_CALCERROR:
			Errors::with_text("not a relation: %S", text);
			break;
		case BadUniversal2_CALCERROR:
			Errors::with_text("not a combination: %S", text);
			break;
		case BinaryMisapplied1_CALCERROR:
			Errors::with_text("binary predicate misapplied: %S", text);
			break;
		case BinaryMisapplied2_CALCERROR:
			Errors::with_text("binary predicate misapplied: %S", text);
			break;
		case KindMismatch_CALCERROR:
			Errors::with_text("kind mismatch: %S", text);
			break;
	}
	DISCARD_TEXT(text)
	#endif
}
