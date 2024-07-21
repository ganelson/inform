[Binding::] Binding and Substitution.

To substitute constants into propositions in place of variables,
and to apply quantifiers to bind any unbound variables.

@h Status of variables.
In any proposition $\phi$, we say that a variable $v$ is "bound" if it
appears as the variable governed by a quantifier: it is "free" if it
does appear somewhere in $\phi$ -- either directly as a term or indirectly
through a function application -- and is not bound. For instance, in
$$ \forall x : K(x) \land B(x, f_C(y)) $$
the variable $x$ is bound and the variable $y$ is free.

In any given proposition, each of the 26 variables always satisfies exactly
one of the following:

(a) it is unused if it is never mentioned as, or in, any term, and is not the
variable of any quantifier;
(b) it is bound if it appears as the variable of any |QUANTIFIER_ATOM|;
(c) it is free if it is used but not bound.

The following shows some examples of operations on variables:
= (text from Figures/binding.txt as REPL)

It might seem logical to have a function which takes a proposition $\phi$
and a variable $v$ and returns its status -- unused, free or bound. But this
would be inefficient, since we want to work with all 26 at once, so instead
we take a pointer to an array of |int| which needs to have (at least, but
probably exactly) 26 entries, and on exit each entry is set to one of the
following.

In the course of doing that, it's easy to test whether variables are used
properly -- a bound variable should occur for the first time in its
quantification, and should not reoccur once the subexpression holding the
quantifier has finished. We return |TRUE| if all is well, or |FALSE| if not,
writing the reason why not to |err|.

@d UNUSED_VST 1
@d FREE_VST 2
@d BOUND_VST 3

=
int Binding::determine_status(pcalc_prop *prop, int *var_states,
	text_stream *err) {
	TRAVERSE_VARIABLE(p);
	int j, unavailable[26], blevel = 0, valid = TRUE;
	for (j=0; j<26; j++) { var_states[j] = UNUSED_VST; unavailable[j] = 0; }
	TRAVERSE_PROPOSITION(p, prop) {
		if (Atoms::is_opener(p->element)) blevel++;
		if (Atoms::is_closer(p->element)) {
			blevel--;
			for (j=0; j<26; j++) if (unavailable[j] > blevel) unavailable[j] = -1;
		}
		for (j=0; j<p->arity; j++) {
			int v = Terms::variable_underlying(&(p->terms[j]));
			if (v >= 26) {
				WRITE_TO(err, "corrupted variable term");
				valid = FALSE;
			} else if (v >= 0) {
				if (unavailable[v] == -1) {
					valid = FALSE;
					WRITE_TO(err, "%c unavailable", pcalc_vars[v]);
				}
				if (p->element == QUANTIFIER_ATOM) {
					if (var_states[v] != UNUSED_VST) {
						valid = FALSE;
						WRITE_TO(err, "%c used outside its binding", pcalc_vars[v]);
					}
					var_states[v] = BOUND_VST; unavailable[v] = blevel;
				} else {
					if (var_states[v] == UNUSED_VST) var_states[v] = FREE_VST;
				}
			}
		}
	}
	return valid;
}

@ With just a little wrapping, this gives us the test of well-formedness.

=
int Binding::is_well_formed(pcalc_prop *prop, text_stream *err) {
	int var_states[26];
	if (Propositions::is_syntactically_valid(prop, err) == FALSE) return FALSE;
	return Binding::determine_status(prop, var_states, err);
}

@ Occasionally we really do care only about one of the 26 variables:

=
int Binding::status(pcalc_prop *prop, int v) {
	int var_states[26];
	if (v == -1) return UNUSED_VST;
	Binding::determine_status(prop, var_states, NULL);
	return var_states[v];
}

@ To distinguish sentences from descriptions, the following can be informative:

=
int Binding::number_free(pcalc_prop *prop) {
	int var_states[26], j, c;
	Binding::determine_status(prop, var_states, NULL);
	for (j=0, c=0; j<26; j++) if (var_states[j] == FREE_VST) c++;
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "There %s %d free variable%s in $D\n",
		(c==1)?"is":"are", c, (c==1)?"":"s", prop);
	return c;
}

@ While this gives us a new variable which can safely be added to an existing
proposition:

=
int Binding::find_unused(pcalc_prop *prop) {
	int var_states[26], j;
	Binding::determine_status(prop, var_states, NULL);
	for (j=0; j<26; j++) if (var_states[j] == UNUSED_VST) return j;
	return 25; /* the best we can do: it avoids crashes, at least... */
}

@ Another "vector operation" on variables: to renumber them throughout a
proposition according to a map array. If |renumber_map[j]| is $-1$, make
no change; otherwise each instance of variable $j$ should be changed to
this new number.

In general, it is dangerous to renumber any variable to another which is
already used in the same proposition: that way we could accidentally change
"$v$ is greater than $w$" into "$w$ is greater than $w$", thus changing the
meaning.

Note that because |QUANTIFIER_ATOM|s store the variable being quantified
as a term, the following changes quantification variables as well as
predicate terms, which is as it should be.

=
pcalc_prop *Binding::vars_map(pcalc_prop *prop, int *renumber_map, pcalc_term *preserving) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		for (int j=0; j<p->arity; j++) {
			pcalc_term *pt = &(p->terms[j]);
			Binding::term_map(pt, renumber_map);
		}
	if (preserving) Binding::term_map(preserving, renumber_map);
	return prop;
}

void Binding::term_map(pcalc_term *pt, int *renumber_map) {
	while (pt->function) pt=&(pt->function->fn_of);
	if (pt->variable >= 0) {
		int nv = renumber_map[pt->variable];
		if (nv >= 0) {
			if (nv >= 26) internal_error("malformed renumbering map");
			pt->variable = nv;
		}
	}
}

@ The following takes any proposition and edits it so that the variables
used are the lowest-numbered ones; moreover, variables are introduced
in numerical order -- that is, the first mentioned will be $x$, then the
next introduced will be $y$, and so on.

=
pcalc_prop *Binding::renumber(pcalc_prop *prop, pcalc_term *preserving) {
	TRAVERSE_VARIABLE(p);
	int renumber_map[26];
	for (int j=0; j<26; j++) renumber_map[j] = -1;
	int k = 0;
	TRAVERSE_PROPOSITION(p, prop)
		for (int j=0; j<p->arity; j++) {
			int v = Terms::variable_underlying(&(p->terms[j]));
			if ((v >= 0) && (renumber_map[v] == -1)) renumber_map[v] = k++;
		}
	return Binding::vars_map(prop, renumber_map, preserving);
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
int Binding::renumber_bound(pcalc_prop *prop, pcalc_prop *not_to_overlap, int query) {
	int prop_vstates[26], nto_vstates[26], renumber_map[26];
	int j, next_unused;
	Binding::determine_status(prop, prop_vstates, NULL);
	Binding::determine_status(not_to_overlap, nto_vstates, NULL);

	for (j=0, next_unused=0; j<26; j++)
		if ((prop_vstates[j] == BOUND_VST) && (nto_vstates[j] != UNUSED_VST)) {
			@<Advance to the next variable not used in either proposition@>;
			renumber_map[j] = next_unused++;
		} else renumber_map[j] = -1;

	Binding::vars_map(prop, renumber_map, NULL);
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

@h Getting rid of free variables.
Propositions with free variables are vague, and Inform tries to minimise its
use of them. Whole verb phrases such as "the tree is in the Courtyard" can in
general become propositions with no free variables, while descriptions such as
"open containers which are in lighted rooms" will become propositions in which
only variable 0, |x|, is free.

Here we see two ways to remove a free variable from a proposition:
= (text from Figures/binding2.txt as REPL)

@ The first way is "binding". Suppose |x| is free and we do not know its
value. We can at least put |Exists x :| at the front of the proposition, thus
saying only "well, it's something". This does the equivalent of turning "open
containers which are in lighted rooms" into "an open container is in a lighted
room", by applying the existential quantifier to anything free.

=
pcalc_prop *Binding::bind_existential(pcalc_prop *prop,
	pcalc_term *preserving) {
	int var_states[26], j;

	Binding::renumber(prop, preserving);
	Binding::determine_status(prop, var_states, NULL);

	for (j=25; j>=0; j--)
		if (var_states[j] == FREE_VST)
			prop = Propositions::insert_atom(prop, NULL,
				Atoms::QUANTIFIER_new(exists_quantifier, j, 0));

	return prop;
}

@ The second way is "substitution", for use when we do know the value of the
free variable we want to remove. We replace every mention of it with some
other term: but as we shall see, this is trickier than it seems.

We begin with two utility routines to substitute into the variable "underneath"
a given term.

=
int Binding::substitute_v_in_term(pcalc_term *pt, int v, pcalc_term *t) {
	if (pt->variable == v) { *pt = *t; return TRUE; }
	if (pt->function) return Binding::substitute_v_in_term(&(pt->function->fn_of), v, t);
	return FALSE;
}

void Binding::substitute_nothing_in_term(pcalc_term *pt, pcalc_term *t) {
#ifdef DETECT_NOTHING_CALCULUS_CALLBACK
	if ((pt->constant) && (DETECT_NOTHING_CALCULUS_CALLBACK(pt->constant))) { *pt = *t; return; }
	if (pt->function) Binding::substitute_nothing_in_term(&(pt->function->fn_of), t);
#endif
}

void Binding::substitute_term_in_term(pcalc_term *pt, pcalc_term *t) {
	if (pt->constant) { *pt = *t; return; }
	if (pt->function) Binding::substitute_term_in_term(&(pt->function->fn_of), t);
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
pcalc_prop *Binding::substitute_term(pcalc_prop *prop, int v, pcalc_term t,
	int verify_only, int *allowed, int *changed) {
	TRAVERSE_VARIABLE(p);

	if (verify_only) *allowed = TRUE;
	if ((v<0) || (v>=26)) DISALLOW("variable substitution out of range");
	if (Binding::is_well_formed(prop, NULL) == FALSE)
		DISALLOW("substituting into malformed prop");
	@<Make sure the substitution would not fail because of a circularity@>;
	if (verify_only) return prop;

	LOGIF(PREDICATE_CALCULUS_WORKINGS,
		"Substituting %c = $0 in: $D\n", pcalc_vars[v], &t, prop);

	TRAVERSE_PROPOSITION(p, prop) {
		int i;
		for (i=0; i<p->arity; i++)
			if (Binding::substitute_v_in_term(&(p->terms[i]), v, &t))
				*changed = TRUE;
	}

	if (Binding::is_well_formed(prop, NULL) == FALSE)
		internal_error("substitution made malformed prop");
	return prop;
}

@ The problem we might find, then, is that setting $v=T$ will be circular
because $T$ itself depends on $v$. There are two ways this can happen: first,
$T$ might be directly a function of $v$ itself, i.e., the VUT might be $v$;
second, $T$ might be a function of some variable $w$ which, by being quantified
after $v$, is allowed to depend on it, in some way that we can't determine.

The general rule, then, is that $T$ can contain only constants or variables
which are free within and after the scope of $v$. (If $w$ is bound
outside the scope of $v$ but after it, this means $w$ didn't exist at the
time that $v$ did, and the attempted substitution would produce a proposition
which isn't well-formed -- $w$ would occur before its quantifier.) We can
check this condition pretty easily, it turns out:

@<Make sure the substitution would not fail because of a circularity@> =
	if ((verify_only == FALSE) && (Binding::status(prop, v) == BOUND_VST))
		DISALLOW("substituting bound variable");
	int vut = Terms::variable_underlying(&t);
	if (vut >= 0) {
		int v_has_been_seen = FALSE;
		if (v == vut) DISALLOW("resubstituting same variable");
		TRAVERSE_PROPOSITION(p, prop) {
			if (v_has_been_seen == FALSE) {
				int i;
				for (i=0; i<p->arity; i++)
					if (Terms::variable_underlying(&(p->terms[i])) == v)
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
variable can remain ambiguous. The presence of a "kind" atom will explicitly
solve the problem for us; if we don't find one, though, we will simply have
to assume that the set of objects is the domain of $x$. (We return |NULL|
here, but that's the assumption which the caller will have to make.)

=
kind *Binding::kind_of_variable_0(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if ((KindPredicates::is_kind_atom(p)) && (p->terms[0].variable == 0))
			return KindPredicates::get_kind(p);
	return NULL;
}

@ And a quick way to substitute it:

=
pcalc_prop *Binding::substitute_var_0_in(pcalc_prop *prop, parse_node *spec) {
	int bogus;
	return Binding::substitute_term(prop, 0, Terms::new_constant(spec), FALSE, NULL, &bogus);
}

@ If we are willing to work a little harder:

=
kind *Binding::infer_kind_of_variable_0(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop) {
		if ((p->element == PREDICATE_ATOM) && (p->arity == 1) && (p->terms[0].variable == 0)) {
			unary_predicate *up = RETRIEVE_POINTER_unary_predicate(p->predicate);
			kind *K = UnaryPredicateFamilies::infer_kind(up);
			if (K) return K;
		}
	}
	return NULL;
}

@h Unbinding.

=
pcalc_prop *Binding::unbind(pcalc_prop *prop) {
	if ((prop) && (Binding::number_free(prop) == 0) && (Atoms::is_existence_quantifier(prop)))
		prop = prop->next;
	return prop;
}

@h Detect locals.
Properly speaking, this has nothing to do with variables, but it solves a similar
problem.

Here we search a proposition to look for any term involving a local variable.
This is used to verify past tense propositions, which cannot rely on local
values because their contents may have been wiped and reused many times
since the time with which the proposition is concerned.

=
#ifdef CORE_MODULE
int Binding::detect_locals(pcalc_prop *prop, parse_node **example) {
	TRAVERSE_VARIABLE(pl);
	int i, locals_count = 0;

	TRAVERSE_PROPOSITION(pl, prop)
		for (i=0; i<pl->arity; i++)
			locals_count =
				Binding::detect_local_in_term(&(pl->terms[i]), locals_count, example);

	return locals_count;
}

int Binding::detect_local_in_term(pcalc_term *pt, int locals_count, parse_node **example) {
	if (pt->function)
		locals_count += Binding::detect_local_in_term(&(pt->function->fn_of), locals_count, example);
	if (pt->constant)
		locals_count += Binding::detect_local_in_spec(pt->constant, locals_count, example);
	return locals_count;
}

int Binding::detect_local_in_spec(parse_node *spec, int locals_count, parse_node **example) {
	if (spec == NULL) return locals_count;
	if (Lvalues::get_storage_form(spec) == LOCAL_VARIABLE_NT) {
		if ((example) && (*example == NULL)) *example = spec;
		return ++locals_count;
	}
	if (Lvalues::get_storage_form(spec) == NONLOCAL_VARIABLE_NT) {
		nonlocal_variable *nlv = Node::get_constant_nonlocal_variable(spec);
		if (NonlocalVariables::is_global(nlv) == FALSE) {
			if ((example) && (*example == NULL)) *example = spec;
			return ++locals_count;
		}
	}
	if (Specifications::is_phrasal(spec)) {
		parse_node *inv;
		LOOP_THROUGH_INVOCATION_LIST(inv, spec->down->down) {
			int tc = Invocations::get_no_tokens(inv);
			for (int i=0; i<tc; i++) {
				parse_node *param = Invocations::get_token_as_parsed(inv, i);
				locals_count +=
					Binding::detect_local_in_spec(param, locals_count, example);
			}
		}
	}
	for (parse_node *p = spec->down; p; p = p->next)
		locals_count +=
			Binding::detect_local_in_spec(p, locals_count, example);
	return locals_count;
}
#endif
