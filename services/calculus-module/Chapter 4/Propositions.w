[Propositions::] Propositions.

To build and modify structures representing propositions in
predicate calculus.

@h Internal representation.
There is no perfectly convenient way to represent propositions. The two
obvious strategies are:

(a) Hold them more or less as written, in a flat sequence of atoms.
(b) Hold them in a tree which branches at each logical operation.

We follow (a), which is easier to iterate through without tiresome amounts
of recursion, but comes at the cost of extra complexity when it comes to
grouping the terms -- this is why we need the awkward |NOT<| and |NOT>|
atoms, for example. (b) would almost certainly be better if we needed to
accommodate disjunction as well as conjunction, but we do not. The main
demerit of (a) is that it is easy to make malformed propositions, so we have
to build and edit carefully.

So propositions are represented by the //pcalc_prop// object at the front, an
atomic proposition, and this leads via its |next| field to a second atomit
proposition, and so on. Now there's a natural way to store incomplete
propositions and a natural build-point (at the end), and depth-first traverses
are easy -- just work along from left to right.

@ In particular:

(1) The empty list, a |NULL| pointer, represents the universally true
proposition $\top$. Asserting it does nothing; testing it at run-time always
evaluates to |true|.
(2) The conjunction $\alpha\land\beta$ is almost the concatenation of their
linked lists |A --> B|, except that we must be careful if they appear to have
variables in common.
(3) Negation $\lnot(\phi)$ is the concatenation |NOT< --> P --> NOT>|,
where |P| is the linked list for $\phi$.
(4) The quantifier $Q v\in \lbrace v\mid\phi(v)\rbrace$ is
|QUANTIFIER --> IN< --> P --> IN>|, where |P| is the linked list for $\phi$.

Conjunction occurs so densely in propositions arising from
natural language that we save a lot of memory and fuss by simply implying it:
thus "great green dragon" is |PREDICATE --> PREDICATE --> PREDICATE|, rather than
something like |PREDICATE --> AND_SIGN --> PREDICATE --> AND_SIGN --> PREDICATE|.
Disjunction hardly ever occurs, so although the above scheme could simulate
it with $\alpha\lor\beta = \lnot((\lnot\alpha)\land(\lnot\beta))$, we never do.

The following function determines whether or not |P1 --> P2| should be
understood as a conjunction.
=
int Propositions::implied_conjunction_between(pcalc_prop *p1, pcalc_prop *p2) {
	if ((p1 == NULL) || (p2 == NULL)) return FALSE;
	if (Atoms::is_opener(p1->element)) return FALSE;
	if (Atoms::is_closer(p2->element)) return FALSE;
	if (p1->element == QUANTIFIER_ATOM) return FALSE;
	if (p1->element == DOMAIN_CLOSE_ATOM) return FALSE;
	return TRUE;
}

@ Purely decoratively, we print some punctuation when logging a proposition;
this is chosen to look like standard mathematical notation.

=
char *Propositions::debugging_log_text_between(pcalc_prop *p1, pcalc_prop *p2) {
	if ((p1 == NULL) || (p2 == NULL)) return "";
	if (p1->element == QUANTIFIER_ATOM) {
		if (p2->element == DOMAIN_OPEN_ATOM) return "";
		return ":";
	}
	if (p1->element == DOMAIN_CLOSE_ATOM) return ":";
	if (Propositions::implied_conjunction_between(p1, p2)) {
		if (Streams::I6_escapes_enabled(DL))
			return("&"); /* since |^| in Inter strings means newline */
		return ("^");
	}
	return "";
}

@h Walking through propositions.
We sometimes need to indicate a position within a proposition -- a position
not of an atom, but between atoms. Consider the possible places where letters
could be inserted into the word "rap": before the "r" (trap), between "r" and
"a" (reap), between "a" and "p" (ramp), after the "p" (rapt). Though "rap" is
a three-letter word, there are four possible insertion points -- so they can't
exactly correspond to letters. The convention we use is that a position marker
points to the //|pcalc_prop// structure for the atom before the position
meant: and a |NULL| pointer in this context means the front position, before
the opening atom.

@ The code needed to walk through a proposition is abstracted by the following
macros. Note that we often need to remember the atom before the current one,
so we keep that in a spare variable during each traverse. (This saves us
having to maintain the proposition data structure as a doubly linked list,
which would be harder to edit.)

One macro declares the name of a marker variable to be used when traversing;
the other is the necessary loop head. Note that we do not assume that |p|
will still be non-|NULL| at the end of a loop iteration, just because it
was at the beginning: local edits are sometimes performed in the traverse,
and it can happen that an edit truncates the proposition so savagely that the
loop finds its ground cut out from under it.

@d TRAVERSE_VARIABLE(p)
	pcalc_prop *p = NULL, *p##_prev = NULL;
	int p##_repeat = FALSE;

@d TRAVERSE_PROPOSITION(p, start)
	for (p=start, p##_prev=NULL, p##_repeat = FALSE;
		p;
		(p##_repeat == FALSE)?(p##_prev=p, p=(p)?(p->next):NULL):0, p##_repeat = FALSE)

@ An edit which happens during a traverse is permitted to make any change
to the proposition at and beyond the marker position |p|, but not allowed
to change what came before. Since such an edit might leave |p| pointing
to an atom which has been cut, or moved later, we must perform the following
macro after edits to restore |p|. We know that the atom which was before
|p| at the start of the loop has not been changed -- since edits aren't
allowed there -- so |p_prev| must be correct, and we therefore restore
|p| to the next atom after |p_prev|.

There is a catch, however: if our edit consists only of deleting some
atoms then using |PROPOSITION_EDITED| correctly resets |p| to the current
atom at the marker position, and that will be the first atom after the
ones deleted. If we then just go around the loop, we move on to the next
atom; as a result, the first atom after the deleted ones is skipped over.
We can avoid this by using |PROPOSITION_EDITED_REPEATING_CURRENT| instead.

Every routine which simplifies a proposition is expected to have an |int *|
argument called |changed|: on exit, the |int| variable this points to
should be set if and only if a change has been made to the proposition.

@d PROPOSITION_EDITED(p, prop)
	if (p##_prev == NULL) p = prop; else p = p##_prev->next;
	*changed = TRUE;

@d PROPOSITION_EDITED_REPEATING_CURRENT(p, prop)
	PROPOSITION_EDITED(p, prop)
	p##_repeat = TRUE;

@ So we may as well complete the debugging log code now. Note that $\top$ is
logged as just |<< >>|.

=
void Propositions::log(pcalc_prop *prop) {
	Propositions::write(DL, prop);
}
void Propositions::write(OUTPUT_STREAM, pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	WRITE("<< ");
	TRAVERSE_PROPOSITION(p, prop) {
		char *bridge = Propositions::debugging_log_text_between(p_prev, p);
		if (bridge[0]) WRITE("%s ", bridge);
		Atoms::write(OUT, p);
		WRITE(" ");
	}
	WRITE(">>");
}

@h Validity.
Since the proposition data structure lets us build all kinds of nonsense,
we'll be much safer if we can check our working -- if we can verify that a
proposition is valid. But what does that mean? We might mean:

(i) a proposition is good if its sequence of |next| pointers all correctly
point to |pcalc_prop| structures, and don't loop around into a circle;
(ii) a proposition is good if (i) is true, and it is correctly punctuated;
(iii) a proposition is good if (ii) is true, and it never confuses
together two different variables by giving both the same letter;
(iv) a proposition is good if (iii) is true, and all of its predicates
can safely be applied to all of their terms, and we can identify what
kind of value each variable ranges over.

These are steadily stronger conditions. The first is a basic invariant of
our data structures: nothing failing (i) will ever be allowed to exist,
provided the routines in this section are free of bugs. Condition (ii) is
called syntactic validity; (iii) is well-formedness; (iv) is type safety.
Correct source text eventually makes propositions which have all four
properties, but intermediate half-built states often satisfy only (i).

@ The following examples illustrate the differences. This one is not even
syntactically valid:
= (text)
|IN< --> NOT> --> NOT>|
=
This one is syntactically valid, but not well-formed:
= (text)
|EVERYWHERE(x) --> QUANTIFIER x --> PREDICATE(x)|
=
(If |x| ranges over all objects at the middle of the proposition, it had
better not already have a value, but if it doesn't, what can that first
atom mean? It would be like writing the formula $n + \sum_{n=1}^{10} n^2$,
where clearly two different things have been called $n$.)

And this proposition is well-formed but not type-safe:
= (text)
|QUANTIFIER(x) --> kind=number(x) --> EVERYWHERE(x)|
=
(Here |x| is supposed to be a number, and therefore has no location, but
|EVERYWHERE| can validly be applied only to backdrop objects, so what
could |EVERYWHERE(x)| possibly mean?)

@ The following tests only (ii), validity. //calculus-test// is unable to make
atoms which fail to pass //Atoms::validate//, nor can it make some of the
misconstructions tested for below, but numerous other defects can be tested:
= (text from Figures/validity.txt as REPL)

@d MAX_PROPOSITION_GROUP_NESTING 100 /* vastly more than could realistically be used */

=
int Propositions::is_syntactically_valid(pcalc_prop *prop, text_stream *err) {
	TRAVERSE_VARIABLE(p);
	int groups_stack[MAX_PROPOSITION_GROUP_NESTING], group_sp = 0;
	TRAVERSE_PROPOSITION(p, prop) {
		/* (1) each individual atom has to be properly built: */
		char *v_err = Atoms::validate(p);
		if (v_err) { WRITE_TO(err, "atom error: %s", err); return FALSE; }
		/* (2) every open bracket must be matched by a close bracket of the same kind: */
		if (Atoms::is_opener(p->element)) {
			if (group_sp >= MAX_PROPOSITION_GROUP_NESTING) {
				WRITE_TO(err, "group nesting too deep"); return FALSE;
			}
			groups_stack[group_sp++] = p->element;
		}
		if (Atoms::is_closer(p->element)) {
			if (group_sp <= 0) { WRITE_TO(err, "too many close groups"); return FALSE; }
			if (Atoms::counterpart(groups_stack[--group_sp]) != p->element) {
				WRITE_TO(err, "group open/close doesn't match"); return FALSE;
			}
		}
		/* (3) every quantifier except "exists" must be followed by domain brackets: */
		if ((Atoms::is_quantifier(p_prev)) && (Atoms::is_existence_quantifier(p_prev) == FALSE)) {
			if (p->element != DOMAIN_OPEN_ATOM) {
				WRITE_TO(err, "quantifier without domain"); return FALSE;
			}
		} else {
			if (p->element == DOMAIN_OPEN_ATOM) {
				WRITE_TO(err, "domain without quantifier"); return FALSE;
			}
		}
		if ((p->next == NULL) &&
			(Atoms::is_quantifier(p)) && (Atoms::is_existence_quantifier(p) == FALSE)) {
			WRITE_TO(err, "nonexistential quantifier without domain"); return FALSE;
		}
	}
	/* (4) a proposition must end with all its brackets closed: */
	if (group_sp != 0) { WRITE_TO(err, "%d group(s) open", group_sp); return FALSE; }
	return TRUE;
}

@h Complexity.
Simple propositions contain only unary predicates or assertions that the
free variable has a given kind, or a given value. For example, "a closed
lockable door" is a simple proposition, but "four women in a lighted room"
is complex. The only simple binary predicate is one which assigns a definite
value to |x|. Examples:
= (text from Figures/complexity.txt as REPL)

=
int Propositions::is_complex(pcalc_prop *prop) {
	pcalc_prop *p;
	for (p = prop; p; p = p->next) {
		if (p->element == QUANTIFIER_ATOM) return TRUE;
		if (p->element == NEGATION_OPEN_ATOM) return TRUE;
		if (p->element == NEGATION_CLOSE_ATOM) return TRUE;
		if (p->element == DOMAIN_OPEN_ATOM) return TRUE;
		if (p->element == DOMAIN_CLOSE_ATOM) return TRUE;
		if ((p->element == PREDICATE_ATOM) && (p->arity == 2)) {
			if (Atoms::is_equality_predicate(p) == FALSE) return TRUE;
			if (!(((p->terms[0].variable == 0) && (p->terms[1].constant)) ||
				((p->terms[1].variable == 0) && (p->terms[0].constant)))) return TRUE;
		}
	}
	return FALSE;
}

@h Primitive operations on propositions.
Now for some basic operations, as shown in the following examoles:
= (text from Figures/operations.txt as REPL)

Note that the conjunction of A and B renamed the variable |x| in B to |y|,
so that it no longer clashed with the meaning of |x| in A. The concatenation
did not, simply writing one after the other.

@ First, copying, which means copying not just the current atom, but all
subsequent ones.

=
pcalc_prop *Propositions::copy(pcalc_prop *original) {
	pcalc_prop *first = NULL, *last = NULL, *prop = original;
	while (prop) {
		pcalc_prop *copied_atom = Atoms::new(0);
		*copied_atom = *prop;
		for (int j=0; j<prop->arity; j++)
			copied_atom->terms[j] = Terms::copy(prop->terms[j]);
		copied_atom->next = NULL;
		if (first) last->next = copied_atom;
		else first = copied_atom;
		last = copied_atom;
		prop = prop->next;
	}
	return first;
}

@ Now to concatenate propositions. If $E$ and $T$ are both syntactically valid,
the result will be, too; but the same is not true of well-formedness, so we
need to be careful in using this.

=
pcalc_prop *Propositions::concatenate(pcalc_prop *existing_body, pcalc_prop *tail) {
	pcalc_prop *end = existing_body;
	if (end == NULL) return tail;
	int sc = 0;
	while (end && (end->next)) {
		if (sc++ == 100000) internal_error("malformed proposition");
		end = end->next;
	}
	end->next = tail;
	return existing_body;
}

@ And here is a version which protects us:

=
pcalc_prop *Propositions::conjoin(pcalc_prop *existing_body, pcalc_prop *tail) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, existing_body)
		if (p == tail) {
			@<Report failure to log@>;
			internal_error("conjoin proposition to a subset of itself");
		}
	TRAVERSE_PROPOSITION(p, tail)
		if (p == existing_body) {
			@<Report failure to log@>;
			internal_error("conjoin proposition to a superset of itself");
		}

	Binding::renumber_bound(tail, existing_body, -1);
	existing_body = Propositions::concatenate(existing_body, tail);
	return existing_body;
}

@<Report failure to log@> =
	LOG("Seriously misguided attempt to conjoin propositions:\n");
	LOG("Existing body: $D\n", existing_body);
	LOG("Tail:          $D\n", tail);

@ Negation and quantification can be done with these shorthand functions:

=
pcalc_prop *Propositions::negate(pcalc_prop *prop) {
	return Propositions::concatenate(
		Atoms::new(NEGATION_OPEN_ATOM),
			Propositions::concatenate(
				prop,
				Atoms::new(NEGATION_CLOSE_ATOM)));
}

pcalc_prop *Propositions::quantify(quantifier *quant, int v, int parameter,
	pcalc_prop *domain, pcalc_prop *prop) {
	pcalc_prop *Q = Atoms::QUANTIFIER_new(quant, v, parameter);
	return Propositions::quantify_using(Q, domain, prop);
}

pcalc_prop *Propositions::quantify_using(pcalc_prop *Q, pcalc_prop *domain,
	pcalc_prop *prop) {
	if (domain)
		Q = Propositions::concatenate(
			Q,
			Propositions::concatenate(
				Atoms::new(DOMAIN_OPEN_ATOM),
				Propositions::concatenate(
					domain,
					Atoms::new(DOMAIN_CLOSE_ATOM))));
	return Propositions::concatenate(Q, prop);
}

@h Inserting and deleting atoms.
These operations do what they say, but the result is often syntactically
invalid. Handle with care.
= (text from Figures/editing.txt as REPL)

@ Here we insert an atom at a given position, or at the front if the position
is |NULL|.

=
pcalc_prop *Propositions::insert_atom(pcalc_prop *prop, pcalc_prop *position,
	pcalc_prop *new_atom) {
	if (position == NULL) {
		new_atom->next = prop;
		return new_atom;
	} else {
		if (prop == NULL) internal_error("inserting atom nowhere");
		new_atom->next = position->next;
		position->next = new_atom;
		return prop;
	}
}

@ And similarly, with the deleted atom the one after the position given:

=
pcalc_prop *Propositions::delete_atom(pcalc_prop *prop, pcalc_prop *position) {
	if (position == NULL) {
		if (prop == NULL) internal_error("deleting atom nowhere");
		return prop->next;
	} else {
		if (position->next == NULL) internal_error("deleting atom off end");
		position->next = position->next->next;
		return prop;
	}
}

@h Miscellaneous further operations.
The rest of this section is given over to miscellaneous utility functions:
= (text from Figures/miscellaneous.txt as REPL)

@h Inspecting contents.
First, we count the number of atoms in a given proposition. This is used by
other parts of Inform as a crude measure of how complicated it is; though in
fact it is not all that crude so long as it is applied to a proposition
which has been simplified.

=
int Propositions::length(pcalc_prop *prop) {
	int n = 0;
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop) n++;
	return n;
}

@h Matching sequences of atoms.
The following sneakily variable-argument-length function can be used to
detect subsequences within a proposition: say, the sequence
= (text)
	QUANTIFIER --> PREDICATE --> anything --> PREDICATE
=
starting at the current position, which could be tested with:
= (text)
	Propositions::match(p, 4,
		QUANTIFIER_ATOM, NULL,
		PREDICATE_ATOM, NULL, NULL,
		ANY_ATOM_HERE, NULL,
		PREDICATE_ATOM, &pp, NULL);
=
As can be seen, each atom is tested with an element number and an optional
pointer; when a successful match is made, the optional pointer is set to
the atom making the match. |PREDICATE_ATOM| atoms are followed by a third
parameter, which if not |NULL| requires it to be a unary predicate of that
family. (So if the routine returns |TRUE| then we can be certain that |pp|
points to the |PREDICATE_ATOM| at the end of the run of four.) There are
two special pseudo-element-numbers:

@d ANY_ATOM_HERE 0 /* match any atom, but don't match beyond the end of the proposition */
@d END_PROP_HERE -1 /* a sentinel meaning "the proposition must end at this point" */

=
int Propositions::match(pcalc_prop *prop, int c, ...) {
	int outcome = TRUE;
	va_list ap; /* the variable argument list signified by the dots */
	va_start(ap, c); /* macro to begin variable argument processing */
	for (int i = 0; i < c; i++) {
		int a = va_arg(ap, int);
		pcalc_prop **atom_p = va_arg(ap, pcalc_prop **);
		if (atom_p != NULL) *atom_p = prop;
		up_family *req_up = NULL;
		if (a == PREDICATE_ATOM) req_up = va_arg(ap, up_family *);
		switch (a) {
			case ANY_ATOM_HERE: if (prop == NULL) outcome = FALSE; break;
			case END_PROP_HERE: if (prop != NULL) outcome = FALSE; break;
			default: if (prop == NULL) outcome = FALSE;
				else if (prop->element != a) outcome = FALSE;
				else if (req_up) {
					if (prop->arity == 1) {
						unary_predicate *up =
							RETRIEVE_POINTER_unary_predicate(prop->predicate);
						if (up->family != req_up) outcome = FALSE;
					} else outcome = FALSE;
				}
				break;
		}
		if (prop) prop = prop->next;
	}
	va_end(ap); /* macro to end variable argument processing */
	return outcome;
}

@ Here we run through the proposition looking for either a given element, or
a given arity, or both:

=
pcalc_prop *Propositions::prop_seek_atom(pcalc_prop *prop, int atom_req, int arity_req) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if (((atom_req < 0) || (p->element == atom_req)) &&
			((arity_req < 0) || (p->arity == arity_req)))
				return p;
	return NULL;
}

pcalc_prop *Propositions::prop_seek_up_family(pcalc_prop *prop, up_family *f) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if ((p->element == PREDICATE_ATOM) && (p->arity == 1)) {
			unary_predicate *up = RETRIEVE_POINTER_unary_predicate(p->predicate);
			if (up->family == f) return p;
		}
	return NULL;
}

@ Seeking different kinds of atom is now easy:

=
int Propositions::contains_binary_predicate(pcalc_prop *prop) {
	if (Propositions::prop_seek_atom(prop, PREDICATE_ATOM, 2)) return TRUE; return FALSE;
}

int Propositions::contains_quantifier(pcalc_prop *prop) {
	if (Propositions::prop_seek_atom(prop, QUANTIFIER_ATOM, -1)) return TRUE; return FALSE;
}

pcalc_prop *Propositions::composited_kind(pcalc_prop *prop) {
	pcalc_prop *k_atom = Propositions::prop_seek_up_family(prop, kind_up_family);
	if (KindPredicates::is_composited_atom(k_atom) == FALSE) k_atom = NULL;
	return k_atom;
}

int Propositions::contains_nonexistence_quantifier(pcalc_prop *prop) {
	while ((prop = Propositions::prop_seek_atom(prop, QUANTIFIER_ATOM, 1)) != NULL) {
		quantifier *quant = prop->quant;
		if (quant != exists_quantifier) return TRUE;
		prop = prop->next;
	}
	return FALSE;
}

@ Here we try to find out the kind of value of variable 0 without the full
expense of typechecking the proposition:

=
kind *Propositions::describes_kind(pcalc_prop *prop) {
	pcalc_prop *p = prop;
	while ((p = Propositions::prop_seek_up_family(p, kind_up_family)) != NULL) {
		if (Terms::variable_underlying(&(p->terms[0])) == 0)
			return KindPredicates::get_kind(p);
		p = p->next;
	}
	parse_node *val = Propositions::describes_value(prop);
	if (val) return VALUE_TO_KIND_FUNCTION(val);
	return NULL;
}

@ And, similarly, the actual value it must have:

=
parse_node *Propositions::describes_value(pcalc_prop *prop) {
	pcalc_prop *p; int bl = 0;
	for (p = prop; p; p = p->next)
		switch (p->element) {
			case NEGATION_OPEN_ATOM: bl++; break;
			case NEGATION_CLOSE_ATOM: bl--; break;
			case DOMAIN_OPEN_ATOM: bl++; break;
			case DOMAIN_CLOSE_ATOM: bl--; break;
			default:
				if (bl == 0) {
					if (Atoms::is_equality_predicate(p)) {
						if ((p->terms[0].variable == 0) && (p->terms[1].constant))
							return p->terms[1].constant;
						if ((p->terms[1].variable == 0) && (p->terms[0].constant))
							return p->terms[0].constant;
					}
				}
				break;
		}
	return NULL;
}

@ Finding an adjective is easy: it's a predicate of arity 1.

=
#ifdef CORE_MODULE
int Propositions::contains_adjective(pcalc_prop *prop) {
	for (pcalc_prop *p = prop; p; p = p->next)
		if ((p->element == PREDICATE_ATOM) && (p->arity == 1)) {
			unary_predicate *up = RETRIEVE_POINTER_unary_predicate(p->predicate);
			if (up->family == adjectival_up_family)
				return TRUE;
		}
	return FALSE;
}

int Propositions::count_adjectives(pcalc_prop *prop) {
	int ac = 0;
	for (pcalc_prop *p = prop; p; p = p->next)
		if ((p->element == PREDICATE_ATOM) && (p->arity == 1) &&
			(Terms::variable_underlying(&(p->terms[0])) == 0)) {
			unary_predicate *up = RETRIEVE_POINTER_unary_predicate(p->predicate);
			if (up->family == adjectival_up_family) ac++;
		}
	return ac;
}
#endif

@ The following searches not for an atom, but for the lexically earliest
term in the proposition:

=
pcalc_term Propositions::get_first_cited_term(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if (p->arity > 0)
			return p->terms[0];
	internal_error("Propositions::get_first_cited_term on termless proposition");
	return Terms::new_variable(0); /* never executed, but needed to prevent |gcc| warnings */
}

@ Here we attempt, if possible, to read a proposition as being either
{\it adjective}($v$) or $\exists v: {\it adjective}(v)$, where the adjective
can be also be read as a noun, and if so we return a constant term $t$ for
that noun; or if the proposition isn't in that form, we return $t=x$, that
is, variable 0.

=
#ifdef CORE_MODULE
pcalc_term Propositions::convert_adj_to_noun(pcalc_prop *prop) {
	pcalc_term pct = Terms::new_variable(0);
	if (prop == NULL) return pct;
	if (Atoms::is_existence_quantifier(prop)) prop = prop->next;
	if (prop == NULL) return pct;
	if (prop->next != NULL) return pct;
	if ((prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
 		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
 		if (up->family == adjectival_up_family)
			return Terms::adj_to_noun_conversion(up);
	}
	if (KindPredicates::is_kind_atom(prop)) {
 		kind *K = KindPredicates::get_kind(prop);
 		property *pname = Properties::property_with_same_name_as(K);
		if (pname) return Terms::new_constant(Rvalues::from_property(pname));
	}
	return pct;
}
#endif

@ We often form propositions which are really lists of adjectives, and the
following are useful for looping through them:

=
#ifdef CORE_MODULE
unary_predicate *Propositions::first_unary_predicate(pcalc_prop *prop, pcalc_prop **ppp) {
	prop = Propositions::prop_seek_up_family(prop, adjectival_up_family);
	if (ppp) *ppp = prop;
	if (prop == NULL) return NULL;
	return Atoms::to_adjectival_usage(prop);
}

unary_predicate *Propositions::next_unary_predicate(pcalc_prop **ppp) {
	if (ppp == NULL) internal_error("bad ppp");
	pcalc_prop *prop = Propositions::prop_seek_up_family((*ppp)->next, adjectival_up_family);
	*ppp = prop;
	if (prop == NULL) return NULL;
	return Atoms::to_adjectival_usage(prop);
}
#endif

@h Bracketed groups.
The following routine tests whether the entire proposition is a single
bracketed group. For instance:
= (text)
	NOT< --> PREDICATE --> NOT>
=
would qualify. Note that detection succeeds only if the parentheses match,
and that they may be nested.

=
int Propositions::is_a_group(pcalc_prop *prop, int governing) {
	int match = Atoms::counterpart(governing), level = 0;
	if (match == 0) internal_error("Propositions::is_a_group called on unmatchable");
	TRAVERSE_VARIABLE(p);
	if ((prop == NULL) || (prop->element != governing)) return FALSE;
	TRAVERSE_PROPOSITION(p, prop) {
		if (Atoms::is_opener(p->element)) level++;
		if (Atoms::is_closer(p->element)) level--;
	}
	if ((p_prev->element == match) && (level == 0)) return TRUE;
	return FALSE;
}

@ The following removes matched parentheses, leaving just the interior:

=
pcalc_prop *Propositions::remove_topmost_group(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	if ((prop == NULL) || (Propositions::is_a_group(prop, prop->element) == FALSE))
		internal_error("tried to remove topmost group which wasn't there");
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "ungrouping proposition: $D\n", prop);
	prop = prop->next;
	TRAVERSE_PROPOSITION(p, prop)
		if ((p->next) && (p->next->next == NULL)) { p->next = NULL; break; }
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "to ungrouped result: $D\n", prop);
	return prop;
}

@ The main application of which is to remove negation:

=
pcalc_prop *Propositions::unnegate(pcalc_prop *prop) {
	if (Propositions::is_a_group(prop, NEGATION_OPEN_ATOM))
		return Propositions::remove_topmost_group(prop);
	return NULL;
}

@ More ambitiously, this removes matched parentheses found at any given
point in a proposition (which can continue after the close bracket).

=
pcalc_prop *Propositions::ungroup_after(pcalc_prop *prop, pcalc_prop *position, pcalc_prop **last) {
	TRAVERSE_VARIABLE(p);
	pcalc_prop *from;
	int opener, closer, level;
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "removing frontmost group from proposition: $D\n", prop);
	if (position == NULL) from = prop; else from = position->next;
	opener = from->element;
	closer = Atoms::counterpart(opener);
	if (closer == 0) internal_error("tried to remove frontmost group which doesn't open");
	from = from->next;
	prop = Propositions::delete_atom(prop, position); /* remove opening atom */
	if (from->element == closer) { /* the special case of an empty group */
		prop = Propositions::delete_atom(prop, position); /* remove opening atom */
		goto Ungrouped;
	}
	level = 0;
	TRAVERSE_PROPOSITION(p, from) {
		if (p->element == opener) level++;
		if (p->element == closer) level--;
		if (level < 0) {
			if (last) *last = p_prev;
			prop = Propositions::delete_atom(prop, p_prev); /* remove closing atom */
			goto Ungrouped;
		}
	}
	internal_error("tried to remove frontmost group which doesn't close");
	Ungrouped:
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "to ungrouped result: $D\n", prop);
	return prop;
}

@ Occasionally we want to strip away a "for all", and since that is always
followed by a domain specification, we must also ungroup this:

=
pcalc_prop *Propositions::trim_universal_quantifier(pcalc_prop *prop) {
	if ((Atoms::is_for_all_x(prop)) &&
		(Propositions::match(prop, 2,
			QUANTIFIER_ATOM, NULL,
			DOMAIN_OPEN_ATOM, NULL))) {
		prop = Propositions::ungroup_after(prop, prop, NULL);
		prop = Propositions::delete_atom(prop, NULL);
		LOGIF(PREDICATE_CALCULUS_WORKINGS, "Propositions::trim_universal_quantifier: $D\n", prop);
	}
	return prop;
}

@ Less ambitiously:

=
pcalc_prop *Propositions::remove_final_close_domain(pcalc_prop *prop, int *move_domain) {
	if (move_domain) *move_domain = FALSE;
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if ((p->next == NULL) && (p->element == DOMAIN_CLOSE_ATOM)) {
			if (move_domain) *move_domain = TRUE;
			return Propositions::delete_atom(prop, p_prev);
		}
	return prop;
}
