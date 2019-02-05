[Calculus::Variables::] Binding and Substitution.

To substitute constants into propositions in place of variables,
and to apply quantifiers to bind any unbound variables.

@h Definitions.

@ In any given proposition:

(a) a variable is {\it unused} if it is never mentioned as, or in, any term,
and is not the variable of any quantifier;

(b) a variable is {\it bound} if it appears as the variable of any |QUANTIFIER_ATOM|;

(c) a variable is {\it free} if it is used but not bound.

These are mutually exclusive (no two can be true at the same time), and in
any given proposition, each of the 26 variables is always either unused, bound
or free.

In this section we are concerned with three operations applied to propositions:

(a) {\it substitution} means replacing each mention of a given variable
with a given constant: for instance, changing $x$ to 3 throughout
("substituting $x=3$"). This has no effect if $x$ is unused, and is
illegal if $x$ is bound, since it could produce nonsense like "for all 3,
3 is odd".

(b) {\it binding} means adding a new quantifier to a proposition, ranging
some variable $v$. If $v$ were unused this would be unlikely to be sensible
(it would just make an inefficient way to test the size of the domain set),
whereas if $v$ were already a bound variable then the result would be a
proposition which is no longer well-formed. So binding can only be done to
free variables.

(c) {\it renumbering} means replacing each mention of a given variable $v$
with another variable $w$. Clearly $w$ needs to be initially unused, or we
could accidentally change "$v$ is greater than $w$" into "$w$ is greater
than $w$". But provided $w$ is unused, the proposition's truth or otherwise
remains unchanged.

@ Propositions with free variables are vague, and we would like to get rid
of them. It can be very difficult to guess their values, just as subtle
human understanding seems to be needed to interpret pronouns like "it"
(see the enormous literature on the donkey anaphora problem in
linguistics). So we aim to translate excerpts of source text into just two
kinds of proposition:

(a) an {\it S-proposition} which has no free variables -- such as the result
of translating "The tree is in the Courtyard" or "Every door is open";

(b) an {\it SN-proposition} in which only variable 0 ($x$) is free -- such
as the result of translating "open containers which are in lighted rooms",
which comes out to a proposition $\phi(x)$ testing whether $x$ is one.

Whole English sentences or conditions make S-propositions, but
descriptions make SN-propositions. (By renumbering, any proposition with one
free variable can be made into an SN-proposition.)

@h Well-formedness.
It might seem logical to have a routine which takes a proposition $\phi$
and a variable $v$ and returns its status -- unused, free or bound. But this
would be inefficient, since we want to work with all 26 at once, so instead
we take a pointer to an array of |int| which needs to have (at least, but
probably exactly) 26 entries, and on exit each entry is set to one of the
following. In the course of doing that, it's easy to test whether variables
are used properly -- a bound variable should occur for the first time in
its quantification, and should not reoccur once the subexpression holding
the quantifier has finished. We set the |valid| flag if all is well.

@d UNUSED_VST 1
@d FREE_VST 2
@d BOUND_VST 3

=
void Calculus::Variables::determine_status(pcalc_prop *prop, int *var_states, int *valid) {
	TRAVERSE_VARIABLE(p);
	int j, unavailable[26], blevel = 0, dummy;
	if (valid == NULL) valid = &dummy;
	*valid = TRUE;
	for (j=0; j<26; j++) { var_states[j] = UNUSED_VST; unavailable[j] = 0; }
	TRAVERSE_PROPOSITION(p, prop) {
		if (Calculus::Atoms::element_get_group(p->element) == OPEN_OPERATORS_GROUP) blevel++;
		if (Calculus::Atoms::element_get_group(p->element) == CLOSE_OPERATORS_GROUP) {
			blevel--;
			for (j=0; j<26; j++) if (unavailable[j] > blevel) unavailable[j] = -1;
		}
		for (j=0; j<p->arity; j++) {
			int v = Calculus::Terms::variable_underlying(&(p->terms[j]));
			if (v >= 26) internal_error("corrupted variable term");
			if (v >= 0) {
				if (unavailable[v] == -1) {
					*valid = FALSE;
					LOG("$o invalid because of %c unavailable\n", p, pcalc_vars[v]);
				}
				if (p->element == QUANTIFIER_ATOM) {
					if (var_states[v] != UNUSED_VST) {
						*valid = FALSE;
						LOG("$D: $o invalid because of %c Q for F\n", prop, p, pcalc_vars[v]);
					}
					var_states[v] = BOUND_VST; unavailable[v] = blevel;
				} else {
					if (var_states[v] == UNUSED_VST) var_states[v] = FREE_VST;
				}
			}
		}
	}
}

@ With just a little wrapping, this gives us the test of well-formedness.

=
int Calculus::Variables::is_well_formed(pcalc_prop *prop) {
	int status, var_states[26];
	if (Calculus::Propositions::is_syntactically_valid(prop) == FALSE) return FALSE;
	Calculus::Variables::determine_status(prop, var_states, &status);
	if (status == FALSE) { LOG("Variable usage malformed\n"); return FALSE; }
	return TRUE;
}

@ Occasionally we really do care only about one of the 26 variables:

=
int Calculus::Variables::status(pcalc_prop *prop, int v) {
	int var_states[26];
	if (v == -1) return UNUSED_VST;
	Calculus::Variables::determine_status(prop, var_states, NULL);
	return var_states[v];
}

@ To distinguish sentences from descriptions, the following can be informative:

=
int Calculus::Variables::number_free(pcalc_prop *prop) {
	int var_states[26], j, c;
	Calculus::Variables::determine_status(prop, var_states, NULL);
	for (j=0, c=0; j<26; j++) if (var_states[j] == FREE_VST) c++;
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "There %s %d free variable%s in $D\n",
		(c==1)?"is":"are", c, (c==1)?"":"s", prop);
	return c;
}

@ While this gives us a new variable which can safely be added to an existing
proposition:

=
int Calculus::Variables::find_unused(pcalc_prop *prop) {
	int var_states[26], j;
	Calculus::Variables::determine_status(prop, var_states, NULL);
	for (j=0; j<26; j++) if (var_states[j] == UNUSED_VST) return j;
	return 25; /* the best we can do: it avoids crashes, at least... */
}

@h Renumbering.
Another "vector operation" on variables: to renumber them throughout a
proposition according to a map array. If |renumber_map[j]| is $-1$, make
no change; otherwise each instance of variable $j$ should be changed to
this new number.

Note that because |QUANTIFIER_ATOM|s store the variable being quantified
as a term, the following changes quantification variables as well as
predicate terms, which is as it should be.

=
void Calculus::Variables::vars_map(pcalc_prop *prop, int *renumber_map, pcalc_term *preserving) {
	TRAVERSE_VARIABLE(p);
	int j;
	TRAVERSE_PROPOSITION(p, prop)
		for (j=0; j<p->arity; j++) {
			pcalc_term *pt = &(p->terms[j]);
			Calculus::Variables::term_map(pt, renumber_map);
		}
	if (preserving) Calculus::Variables::term_map(preserving, renumber_map);
}

void Calculus::Variables::term_map(pcalc_term *pt, int *renumber_map) {
	while (pt->function) pt=&(pt->function->fn_of);
	int nv = renumber_map[pt->variable];
	if ((pt->variable >= 0) && (nv >= 0)) {
		if (nv >= 26) internal_error("malformed renumbering map");
		pt->variable = nv;
	}
}

@ The following takes any proposition and edits it so that the variables
used are the lowest-numbered ones; moreover, variables are introduced
in numerical order -- that is, the first mentioned will be $x$, then the
next introduced will be $y$, and so on.

=
void Calculus::Variables::renumber(pcalc_prop *prop, pcalc_term *preserving) {
	TRAVERSE_VARIABLE(p);
	int j, k, renumber_map[26];

	for (j=0; j<26; j++) renumber_map[j] = -1;

	k = 0;
	TRAVERSE_PROPOSITION(p, prop)
		for (j=0; j<p->arity; j++) {
			int v = Calculus::Terms::variable_underlying(&(p->terms[j]));
			if ((v >= 0) && (renumber_map[v] == -1)) renumber_map[v] = k++;
		}

	Calculus::Variables::vars_map(prop, renumber_map, preserving);
}

@ This more complicated routine renumbers bound variables in one proposition
in order to guarantee that none of them coincides with a variable used
in a second proposition. This is needed in order to take the conjunction of
two propositions, because "for all $x$, $x$ is a door" and "there exists $x$
such that $x$ is a container" mean different things by $x$; they can only
be combined in a single proposition if one of the $x$ variables is changed
to, say, $y$.

The surprising thing here is the asymmetry. Why do we only renumber to avoid
clashes with bound variables in |prop| -- why not free ones as well? The
answer is that we use a form of conjunction in Inform which assumes that a
free variable in $\phi$ has the same meaning as it does in $\psi$; thus in
conjoining "open" with "lockable" we assume that the same thing is meant
to be both open and lockable. If we renumbered to avoid clashes in free
variables, we would produce a proposition meaning that one unknown thing is
open, and another one lockable: that would have two free variables and be
much harder to interpret.

If we pass a |query| parameter which is a valid variable number, the routine
returns its new identity when renumbered.

=
int Calculus::Variables::renumber_bound(pcalc_prop *prop, pcalc_prop *not_to_overlap, int query) {
	int prop_vstates[26], nto_vstates[26], renumber_map[26];
	int j, next_unused;
	Calculus::Variables::determine_status(prop, prop_vstates, NULL);
	Calculus::Variables::determine_status(not_to_overlap, nto_vstates, NULL);

	for (j=0, next_unused=0; j<26; j++)
		if ((prop_vstates[j] == BOUND_VST) && (nto_vstates[j] != UNUSED_VST)) {
			@<Advance to the next variable not used in either proposition@>;
			renumber_map[j] = next_unused++;
		} else renumber_map[j] = -1;

	Calculus::Variables::vars_map(prop, renumber_map, NULL);
	if (query == -1) return -1;
	if (renumber_map[query] == -1) return query;
	return renumber_map[query];
}

@ Again, we fall back on variable 25 if we run out. (This can only happen if
the conjunction of the two propositions had 26 variables.)

@<Advance to the next variable not used in either proposition@> =
	int k;
	for (k=next_unused; (k<26) &&
		(!((prop_vstates[k] == UNUSED_VST) && (nto_vstates[k] == UNUSED_VST))); k++) ;
	if (k == 26) next_unused = 25; else next_unused = k;

@h Binding.
In this routine, we look for free variables and preface the proposition
with $\exists$ quantifiers to bind them. For instance, ${\it open}(x)$ becomes
$\exists x: {\it open}(x)$.

We first renumber the proposition's variables from left to right, and
then quantify in reverse order -- thus starting with the innermost free
variable and working outwards (i.e., towards the left). Since at each
stage we are prefacing the proposition, though, the net effect is that in
the final proposition the previously free variables are bound in increasing
order. For instance:
$$ {\it in}(x, y) \quad\rightarrow\quad
\exists y: {\it in}(x, y) \quad\rightarrow\quad
\exists x: \exists y: {\it in}(x, y) $$

=
pcalc_prop *Calculus::Variables::bind_existential(pcalc_prop *prop,
	pcalc_term *preserving) {
	int var_states[26], j;

	Calculus::Variables::renumber(prop, preserving);
	Calculus::Variables::determine_status(prop, var_states, NULL);

	for (j=25; j>=0; j--)
		if (var_states[j] == FREE_VST)
			prop = Calculus::Propositions::insert_atom(prop, NULL,
				Calculus::Atoms::QUANTIFIER_new(exists_quantifier, j, 0));

	return prop;
}

@h Substitution.
In the following, we substitute term $T$ (a constant or function) in place
of variable $v$ in the given proposition. We begin with two utility routines
to substitute into the variable "underneath" a given term.

=
int Calculus::Variables::substitute_v_in_term(pcalc_term *pt, int v, pcalc_term *t) {
	if (pt->variable == v) { *pt = *t; return TRUE; }
	if (pt->function) return Calculus::Variables::substitute_v_in_term(&(pt->function->fn_of), v, t);
	return FALSE;
}

void Calculus::Variables::substitute_nothing_in_term(pcalc_term *pt, pcalc_term *t) {
	if ((pt->constant) && (Rvalues::is_nothing_object_constant(pt->constant))) { *pt = *t; return; }
	if (pt->function) Calculus::Variables::substitute_nothing_in_term(&(pt->function->fn_of), t);
}

void Calculus::Variables::substitute_term_in_term(pcalc_term *pt, pcalc_term *t) {
	if (pt->constant) { *pt = *t; return; }
	if (pt->function) Calculus::Variables::substitute_term_in_term(&(pt->function->fn_of), t);
}

@ Now the main procedure. This is one of those deceptive problems where the
actual algorithm is obvious, but the circumstances when it can validly be
applied are less so.

The difficulty depends on the term $T$ being substituted in for the variable
$v$. In general every term is a chain of functions with, right at the end,
either a constant or a variable. If a constant is underneath, there is no
problem at all. But if there is a variable underneath $T$ -- a VUT, as we
say below -- then it's possible that the substitution introduces circularities
which would make it invalid. If that happens, we run into this:

@d DISALLOW(msg) {
	if (verify_only) { *allowed = FALSE; return prop; }
	internal_error(msg);
}

@ So the routine is intended to be called twice: once to ask if the situation
looks viable, and once to perform the substitution itself.

=
pcalc_prop *Calculus::Variables::substitute_term(pcalc_prop *prop, int v, pcalc_term t,
	int verify_only, int *allowed, int *changed) {
	TRAVERSE_VARIABLE(p);

	if (verify_only) *allowed = TRUE;
	if ((v<0) || (v>=26)) DISALLOW("variable substitution out of range");
	if (Calculus::Variables::is_well_formed(prop) == FALSE)
		DISALLOW("substituting into malformed prop");
	@<Make sure the substitution would not fail because of a circularity@>;
	if (verify_only) return prop;

	LOGIF(PREDICATE_CALCULUS_WORKINGS, "Substituting %c = $0 in: $D\n", pcalc_vars[v], &t, prop);

	TRAVERSE_PROPOSITION(p, prop) {
		int i;
		for (i=0; i<p->arity; i++)
			if (Calculus::Variables::substitute_v_in_term(&(p->terms[i]), v, &t))
				*changed = TRUE;
	}

	if (Calculus::Variables::is_well_formed(prop) == FALSE)
		internal_error("substitution made malformed prop");
	return prop;
}

@ The problem we might find, then, is that setting $v=T$ will be circular
because $T$ itself depends on $v$. There are two ways this can happen: first,
$T$ might be directly a function of $v$ itself, i.e., the VUT might be $v$;
second, $T$ might be a function of some variable $w$ which, by being quantified
after $v$, is allowed to depend on it, in some way that we can't determine.
(For examples of this, see "Simplifications".)

The general rule, then, is that $T$ can contain only constants or variables
which are free {\it within and after the scope of $v$}. (If $w$ is bound
outside the scope of $v$ but after it, this means $w$ didn't exist at the
time that $v$ did, and the attempted substitution would produce a proposition
which isn't well-formed -- $w$ would occur before its quantifier.) We can
check this condition pretty easily, it turns out:

@<Make sure the substitution would not fail because of a circularity@> =
	if ((verify_only == FALSE) && (Calculus::Variables::status(prop, v) == BOUND_VST))
		DISALLOW("substituting bound variable");
	int vut = Calculus::Terms::variable_underlying(&t);
	if (vut >= 0) {
		int v_has_been_seen = FALSE;
		if (v == vut) DISALLOW("resubstituting same variable");
		TRAVERSE_PROPOSITION(p, prop) {
			if (v_has_been_seen == FALSE) {
				int i;
				for (i=0; i<p->arity; i++)
					if (Calculus::Terms::variable_underlying(&(p->terms[i])) == v)
						v_has_been_seen = TRUE;
			}
			if ((p->element == QUANTIFIER_ATOM) && (p->terms[0].variable == vut) &&
				(v_has_been_seen))
					DISALLOW("substituted value may be circular");
		}
	}

@h A footnote on variable 0.
Because of the special status of $x$ (variable 0) -- the one allowed to be
free in SN-propositions -- we sometimes need to know about it. The range
of a bound variable can be found by looking at its quantifier, but a free
variable can remain ambiguous. The presence of a |KIND| atom will explicitly
solve the problem for us; if we don't find one, though, we will simply have
to assume that the set of objects is the domain of $x$. (We return |NULL|
here, but that's the assumption which the caller will have to make.)

=
kind *Calculus::Variables::kind_of_variable_0(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if ((p->element == KIND_ATOM) && (p->terms[0].variable == 0)) {
			kind *K = p->assert_kind;
			if (K) return K;
		}
	return NULL;
}

@ And a quick way to substitute it:

=
pcalc_prop *Calculus::Variables::substitute_var_0_in(pcalc_prop *prop, parse_node *spec) {
	int bogus;
	return Calculus::Variables::substitute_term(prop, 0, Calculus::Terms::new_constant(spec), FALSE, NULL, &bogus);
}

@ If we are willing to work a little harder:

=
kind *Calculus::Variables::infer_kind_of_variable_0(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop) {
		if ((p->element == KIND_ATOM) && (p->terms[0].variable == 0)) {
			kind *K = p->assert_kind;
			if (K) return K;
		}
		if ((p->element == PREDICATE_ATOM) && (p->arity == 1) && (p->terms[0].variable == 0)) {
			adjective_usage *tr = RETRIEVE_POINTER_adjective_usage(p->predicate);
			adjectival_phrase *aph = AdjectiveUsages::get_aph(tr);
			adjective_meaning *am = Adjectives::Meanings::first_meaning(aph);
			kind *K = Adjectives::Meanings::get_domain(am);
			if (K) return K;
		}
	}
	return NULL;
}

@h Detect locals.
Properly speaking, this has nothing to do with variables,
but it solves a similar problem.

Here we search a proposition to look for any term involving a local variable.
This is used to verify past tense propositions, which cannot rely on local
values because their contents may have been wiped and reused many times
since the time with which the proposition is concerned.

=
int Calculus::Variables::detect_locals(pcalc_prop *prop, parse_node **example) {
	TRAVERSE_VARIABLE(pl);
	int i, locals_count = 0;

	TRAVERSE_PROPOSITION(pl, prop)
		for (i=0; i<pl->arity; i++)
			locals_count =
				Calculus::Variables::detect_local_in_term(&(pl->terms[i]), locals_count, example);

	return locals_count;
}

int Calculus::Variables::detect_local_in_term(pcalc_term *pt, int locals_count, parse_node **example) {
	if (pt->function)
		locals_count += Calculus::Variables::detect_local_in_term(&(pt->function->fn_of), locals_count, example);
	if (pt->constant)
		locals_count += Calculus::Variables::detect_local_in_spec(pt->constant, locals_count, example);
	return locals_count;
}

int Calculus::Variables::detect_local_in_spec(parse_node *spec, int locals_count, parse_node **example) {
	if (spec == NULL) return locals_count;
	if (Lvalues::get_storage_form(spec) == LOCAL_VARIABLE_NT) {
		if ((example) && (*example == NULL)) *example = spec;
		return ++locals_count;
	}
	if (Lvalues::get_storage_form(spec) == NONLOCAL_VARIABLE_NT) {
		nonlocal_variable *nlv = ParseTree::get_constant_nonlocal_variable(spec);
		if (NonlocalVariables::is_global(nlv) == FALSE) {
			if ((example) && (*example == NULL)) *example = spec;
			return ++locals_count;
		}
	}
	if (ParseTreeUsage::is_phrasal(spec)) {
		parse_node *inv;
		LOOP_THROUGH_INVOCATION_LIST(inv, spec->down->down) {
			parse_node *param;
			LOOP_THROUGH_TOKENS_PARSED_IN_INV(inv, param)
				locals_count +=
					Calculus::Variables::detect_local_in_spec(param, locals_count, example);
		}
	}
	for (parse_node *p = spec->down; p; p = p->next)
		locals_count +=
			Calculus::Variables::detect_local_in_spec(p, locals_count, example);
	return locals_count;
}
