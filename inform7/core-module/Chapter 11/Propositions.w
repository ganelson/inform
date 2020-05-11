[Calculus::Propositions::] Propositions.

To build and modify structures representing propositions in
predicate calculus.

@h Definitions.

@ We now begin on the data structures to hold propositions. Now a properly
constructed proposition has a natural tree structure -- one can regard
quantification, negation, and conjunction as higher nodes, and predicates
as leaves. So the idea of storing propositions as trees has a certain elegance.
At first it seems an advantage that any such tree is necessarily a valid
proposition. But in fact this is not so helpful, because we want to build
propositions gradually, and in particular intermediate states need to exist
which are not yet valid but will be. If we used a tree representation, we
would also need some cursor-position-like marker for the region of current
growth, and that could all become complicated. We will also find that the
main operation we need to perform is a depth-first traverse of the tree,
which is a little tiresome to do in a conventional loop (it lends itself to
recursion, but that's inconvenient).

So we will instead store propositions in a linked list, imitating the notation
used by mathematicians who write them along in a single line. Now there's a
natural way to store incomplete propositions and a natural build-point (at
the end), and depth-first traverses are easy -- just work along from left
to right. The disadvantage is that it's also easy to make malformed
propositions, so we have to build carefully.

For instance, "Test sentence (internal) with no man can see the box."
produces:
= (text)
	1. no man can see the box
	[ DoesNotExist x IN[ man(x) IN] : can-see(x, 'box') ]
=
The proposition is stored as a linked list of atoms, of elements like so:
= (text)
	QUANTIFIER --> DOMAIN_OPEN --> PREDICATE --> DOMAIN_CLOSE --> PREDICATE
=
In short: a proposition is a linked list of |pcalc_prop| atoms, joined by
their |next| fields. The present section contains routines to help build
and edit such lists.

@ In particular:

(a) The empty list, a |NULL| pointer, represents the universally true
proposition $\top$. Asserting it does nothing; testing it at run-time always
evaluates to |true|.

(b) The conjunction $\phi\land\psi$ is just the concatenation of their
linked lists.

(c) Negation $\lnot(\phi)$ is the concatenation |NEGATION_OPEN --> P --> NEGATION_CLOSE|,
where |P| is the linked list for $\phi$.

(d) The quantifier $Q v\in \lbrace v\mid\phi(v)\rbrace$ is
|QUANTIFIER --> DOMAIN_OPEN --> P --> DOMAIN_CLOSE|.

In this section, we'll call a segment of the list representing a pair of
matched brackets, like |DOMAIN_OPEN --> P --> DOMAIN_CLOSE|, a "group".

@ We sometimes need to indicate a position within a proposition -- a
position not of an atom, but between atoms. Consider the possible places
where letters could be inserted into the word "rap": before the "r"
(trap), between "r" and "a" (reap), between "a" and "p" (ramp),
after the "p" (rapt). Though "rap" is a three-letter word, there are
four possible insertion points -- so they can't exactly correspond to
letters. The convention used with Inform propositions is that a position
marker points to the |pcalc_prop| structure for the atom before
the position meant: and a |NULL| pointer in this context means the
front position, before the opening atom.

@ The code needed to perform a depth-first traverse of a proposition is
abstracted by the following macros. Note that we often need to remember
the atom before the current one, so we keep that in a spare variable
during each traverse. (This saves us having to maintain the proposition
data structure as a doubly linked list, which would be harder to edit.)

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

@h Implied conjunction.
Conjunction (logical "and") occurs so densely in propositions arising from
natural language that our data structures would grow large and unmanageable
if we wrote all of them out. So we adopt a convention similar to the one
in algebra, where the formula
$$ xy+w(v-1) $$
is understood to mean multiplication of $x$ by $y$, and of $w$ by $(v-1)$.
Note that if we were to write it out as a sequence of symbols
= (text)
	x y + w ( v - 1 )
=
then multiplication would only be understood at two positions, not between
every pair of symbols. In the same way, the following routine looks at a
pair of adjacent atoms and decides whether or not conjunction should be
understood between them.

=
int Calculus::Propositions::implied_conjunction_between(pcalc_prop *p1, pcalc_prop *p2) {
	if ((p1 == NULL) || (p2 == NULL)) return FALSE;
	if (Calculus::Atoms::element_get_group(p1->element) == OPEN_OPERATORS_GROUP) return FALSE;
	if (Calculus::Atoms::element_get_group(p2->element) == CLOSE_OPERATORS_GROUP) return FALSE;
	if (p1->element == QUANTIFIER_ATOM) return FALSE;
	if (p1->element == DOMAIN_CLOSE_ATOM) return FALSE;
	return TRUE;
}

@ Purely decoratively, we print some punctuation when logging a proposition;
this is chosen to look like standard mathematical notation.

=
char *Calculus::Propositions::debugging_log_text_between(pcalc_prop *p1, pcalc_prop *p2) {
	if ((p1 == NULL) || (p2 == NULL)) return "";
	if (p1->element == QUANTIFIER_ATOM) {
		if (p2->element == DOMAIN_OPEN_ATOM) return "";
		return ":";
	}
	if (p1->element == DOMAIN_CLOSE_ATOM) return ":";
	if (Calculus::Propositions::implied_conjunction_between(p1, p2)) {
		if (Streams::I6_escapes_enabled(DL)) return("&"); /* since |^| in I6 strings means newline */
		return ("^");
	}
	return "";
}

@ So we may as well complete the debugging log code now. Note that $\top$ is
logged as just |[ ]|.

=
int log_addresses = FALSE;
void Calculus::Propositions::log(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	LOG("[ ");
	TRAVERSE_PROPOSITION(p, prop) {
		char *bridge = Calculus::Propositions::debugging_log_text_between(p_prev, p);
		if (bridge[0]) LOG("%s ", bridge);
		if (log_addresses) LOG("%08x=", (unsigned int) p);
		Calculus::Atoms::log(p);
		LOG(" ");
	}
	LOG("]");
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
called syntactic validity; (iii) is well-formedness; (iv) is
type safety. Correct source text eventually makes propositions which
have all four properties, but intermediate half-built states often satisfy
only (i).

@ The following examples illustrate the differences. This one is not even
syntactically valid:
= (text)
|DOMAIN_OPEN_ATOM --> NEGATION_CLOSE_ATOM --> NEGATION_CLOSE_ATOM|
=
This one is syntactically valid, but not well-formed:
= (text)
|EVERYWHERE_ATOM(x) --> QUANTIFIER=for-all(x) --> PREDICATE=open(x)|
=
(If |x| ranges over all objects at the middle of the proposition, it had
better not already have a value, but if it doesn't, what can that first
atom mean? It would be like writing the formula $n + \sum_{n=1}^{10} n^2$,
where clearly two different things have been called $n$.)

And this proposition is well-formed but not type-safe:
= (text)
|QUANTIFIER=for-all(x) --> KIND=number(x) --> EVERYWHERE(x)|
=
(Here |x| is supposed to be a number, and therefore has no location, but
|EVERYWHERE| can validly be applied only to backdrop objects, so what
could |EVERYWHERE(x)| possibly mean?)

@ Well-formedness and type safety are left to later sections in this chapter,
but we can at least test syntactic validity here.

@d MAX_PROPOSITION_GROUP_NESTING 100 /* vastly more than could realistically be used */

=
int Calculus::Propositions::is_syntactically_valid(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	int groups_stack[MAX_PROPOSITION_GROUP_NESTING], group_sp = 0;
	TRAVERSE_PROPOSITION(p, prop) {
		/* (1) each individual atom has to be properly built: */
		char *err = Calculus::Atoms::validate(p);
		if (err) { LOG("Atom error: %s: $o\n", err, p); return FALSE; }
		/* (2) every open bracket must be matched by a close bracket of the same kind: */
		if (Calculus::Atoms::element_get_group(p->element) == OPEN_OPERATORS_GROUP) {
			if (group_sp >= MAX_PROPOSITION_GROUP_NESTING) {
				LOG("Group nesting too deep\n"); return FALSE;
			}
			groups_stack[group_sp++] = p->element;
		}
		if (Calculus::Atoms::element_get_group(p->element) == CLOSE_OPERATORS_GROUP) {
			if (group_sp <= 0) { LOG("Too many close groups\n"); return FALSE; }
			if (Calculus::Atoms::element_get_match(groups_stack[--group_sp]) != p->element) {
				LOG("Group open/close doesn't match\n"); return FALSE;
			}
		}
		/* (3) every quantifier except "exists" must be followed by domain brackets, which occur nowhere else: */
		if ((Calculus::Atoms::is_quantifier(p_prev)) && (Calculus::Atoms::is_existence_quantifier(p_prev) == FALSE)) {
			if (p->element != DOMAIN_OPEN_ATOM) { LOG("Quant without domain\n"); return FALSE; }
		} else {
			if (p->element == DOMAIN_OPEN_ATOM) { LOG("Domain without quant\n"); return FALSE; }
		}
		if ((p->next == NULL) &&
			(Calculus::Atoms::is_quantifier(p)) && (Calculus::Atoms::is_existence_quantifier(p) == FALSE)) {
			LOG("Ends without domain of final quantifier\n"); return FALSE;
		}
	}
	/* (4) a proposition must end with all its brackets closed: */
	if (group_sp != 0) { LOG("%d group(s) open\n", group_sp); return FALSE; }
	return TRUE;
}

@h Complexity.
Simple propositions contain only unary predicates or assertions that the
free variable has a given kind, or a given value. For example, "a closed
lockable door" is a simple proposition, but "four women in a lighted room"
is complex.

=
int Calculus::Propositions::is_complex(pcalc_prop *prop) {
	pcalc_prop *p;
	for (p = prop; p; p = p->next) {
		if (p->element == QUANTIFIER_ATOM) return TRUE;
		if (p->element == NEGATION_OPEN_ATOM) return TRUE;
		if (p->element == NEGATION_CLOSE_ATOM) return TRUE;
		if (p->element == DOMAIN_OPEN_ATOM) return TRUE;
		if (p->element == DOMAIN_CLOSE_ATOM) return TRUE;
		if ((p->element == PREDICATE_ATOM) && (p->arity == 2)) {
			if (Calculus::Atoms::is_equality_predicate(p) == FALSE) return TRUE;
			if (!(((p->terms[0].variable == 0) && (p->terms[1].constant)) ||
				((p->terms[1].variable == 0) && (p->terms[0].constant)))) return TRUE;
		}
	}
	return FALSE;
}

@h Primitive operations on propositions.
First, copying, which means copying not just the current atom, but all
subsequent ones.

=
pcalc_prop *Calculus::Propositions::copy(pcalc_prop *original) {
	pcalc_prop *first = NULL, *last = NULL, *prop = original;
	while (prop) {
		pcalc_prop *copied_atom = Calculus::Atoms::new(0);
		*copied_atom = *prop;
		for (int j=0; j<prop->arity; j++)
			copied_atom->terms[j] = Calculus::Terms::copy(prop->terms[j]);
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
pcalc_prop *Calculus::Propositions::concatenate(pcalc_prop *existing_body, pcalc_prop *tail) {
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
pcalc_prop *Calculus::Propositions::conjoin(pcalc_prop *existing_body, pcalc_prop *tail) {
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

	Calculus::Variables::renumber_bound(tail, existing_body, -1);
	existing_body = Calculus::Propositions::concatenate(existing_body, tail);
	return existing_body;
}

@<Report failure to log@> =
	LOG("Seriously misguided attempt to conjoin propositions:\n");
	log_addresses = TRUE;
	LOG("Existing body: $D\n", existing_body);
	LOG("Tail:          $D\n", tail);

@h Inserting and deleting atoms.
Here we insert an atom at a given position, or at the front if the position
is |NULL|.

=
pcalc_prop *Calculus::Propositions::insert_atom(pcalc_prop *prop, pcalc_prop *position,
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
pcalc_prop *Calculus::Propositions::delete_atom(pcalc_prop *prop, pcalc_prop *position) {
	if (position == NULL) {
		if (prop == NULL) internal_error("deleting atom nowhere");
		return prop->next;
	} else {
		if (position->next == NULL) internal_error("deleting atom off end");
		position->next = position->next->next;
		return prop;
	}
}

@h Inspecting contents.
First, we count the number of atoms in a given proposition. This is used by
other parts of Inform as a crude measure of how complicated it is; though in
fact it is not all that crude so long as it is applied to a proposition
which has been simplified.

=
int Calculus::Propositions::length(pcalc_prop *prop) {
	int n = 0;
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop) n++;
	return n;
}

@h Matching sequences of atoms.
The following sneakily variable-argument-length function can be used to
detect subsequences within a proposition: say, the sequence
= (text)
	QUANTIFIER --> PREDICATE --> anything --> CALLED
=
starting at the current position, which could be tested with:
= (text)
	Calculus::Propositions::match(p, 4, QUANTIFIER_ATOM, NULL, PREDICATE_ATOM, NULL,
		ANY_ATOM_HERE, NULL, CALLED_ATOM, &cp);
=
As can be seen, each atom is tested with an element number and an optional
pointer; when a successful match is made, the optional pointer is set to
the atom making the match. (So if the routine returns |TRUE| then we can
be certain that |cp| points to the |CALLED_ATOM| at the end of the run of
four.) There are two special pseudo-element-numbers:

@d ANY_ATOM_HERE 0 /* match any atom, but don't match beyond the end of the proposition */
@d END_PROP_HERE -1 /* a sentinel meaning "the proposition must end at this point" */

=
int Calculus::Propositions::match(pcalc_prop *prop, int c, ...) {
	int i, outcome = TRUE;
	va_list ap; /* the variable argument list signified by the dots */
	va_start(ap, c); /* macro to begin variable argument processing */
	for (i = 0; i < c; i++) {
		int a = va_arg(ap, int);
		pcalc_prop **atom_p = va_arg(ap, pcalc_prop **);
		if (atom_p != NULL) *atom_p = prop;
		switch (a) {
			case ANY_ATOM_HERE: if (prop == NULL) outcome = FALSE; break;
			case END_PROP_HERE: if (prop != NULL) outcome = FALSE; break;
			default: if (prop == NULL) outcome = FALSE;
				else if (prop->element != a) outcome = FALSE;
				break;
		}
		if (prop) prop = prop->next;
	}
	va_end(ap); /* macro to end variable argument processing */
	return outcome;
}

@h Seeking atoms.
Here we run through the proposition looking for either a given element, or
a given arity, or both:

=
pcalc_prop *Calculus::Propositions::prop_seek_atom(pcalc_prop *prop, int atom_req, int arity_req) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if (((atom_req < 0) || (p->element == atom_req)) &&
			((arity_req < 0) || (p->arity == arity_req)))
				return p;
	return NULL;
}

@ Seeking different kinds of atom is now easy:

=
int Calculus::Propositions::contains_binary_predicate(pcalc_prop *prop) {
	if (Calculus::Propositions::prop_seek_atom(prop, PREDICATE_ATOM, 2)) return TRUE; return FALSE;
}

int Calculus::Propositions::contains_quantifier(pcalc_prop *prop) {
	if (Calculus::Propositions::prop_seek_atom(prop, QUANTIFIER_ATOM, -1)) return TRUE; return FALSE;
}

pcalc_prop *Calculus::Propositions::composited_kind(pcalc_prop *prop) {
	pcalc_prop *k_atom = Calculus::Propositions::prop_seek_atom(prop, KIND_ATOM, -1);
	if ((k_atom) && (k_atom->composited == FALSE)) k_atom = NULL;
	return k_atom;
}

int Calculus::Propositions::contains_nonexistence_quantifier(pcalc_prop *prop) {
	while ((prop = Calculus::Propositions::prop_seek_atom(prop, QUANTIFIER_ATOM, 1)) != NULL) {
		quantifier *quant = RETRIEVE_POINTER_quantifier(prop->predicate);
		if (quant != exists_quantifier) return TRUE;
		prop = prop->next;
	}
	return FALSE;
}

int Calculus::Propositions::contains_callings(pcalc_prop *prop) {
	if (Calculus::Propositions::prop_seek_atom(prop, CALLED_ATOM, -1)) return TRUE; return FALSE;
}

@ Here we try to find out the kind of value of variable 0 without the full
expense of typechecking the proposition:

=
kind *Calculus::Propositions::describes_kind(pcalc_prop *prop) {
	pcalc_prop *p = prop;
	while ((p = Calculus::Propositions::prop_seek_atom(p, ISAKIND_ATOM, 1)) != NULL) {
		if ((Calculus::Terms::variable_underlying(&(p->terms[0])) == 0) &&
			(Kinds::Compare::eq(p->assert_kind, K_value))) return p->assert_kind;
		p = p->next;
	}
	p = prop;
	while ((p = Calculus::Propositions::prop_seek_atom(p, KIND_ATOM, 1)) != NULL) {
		if (Calculus::Terms::variable_underlying(&(p->terms[0])) == 0) return p->assert_kind;
		p = p->next;
	}
	parse_node *val = Calculus::Propositions::describes_value(prop);
	if (val) return Specifications::to_kind(val);
	return NULL;
}

@ And, similarly, the actual value it must have:

=
parse_node *Calculus::Propositions::describes_value(pcalc_prop *prop) {
	pcalc_prop *p; int bl = 0;
	for (p = prop; p; p = p->next)
		switch (p->element) {
			case NEGATION_OPEN_ATOM: bl++; break;
			case NEGATION_CLOSE_ATOM: bl--; break;
			case DOMAIN_OPEN_ATOM: bl++; break;
			case DOMAIN_CLOSE_ATOM: bl--; break;
			default:
				if (bl == 0) {
					if (Calculus::Atoms::is_equality_predicate(p)) {
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
int Calculus::Propositions::contains_adjective(pcalc_prop *prop) {
	if (Calculus::Propositions::prop_seek_atom(prop, PREDICATE_ATOM, 1)) return TRUE;
	return FALSE;
}

int Calculus::Propositions::count_unary_predicates(pcalc_prop *prop) {
	int ac = 0;
	pcalc_prop *p = prop;
	while ((p = Calculus::Propositions::prop_seek_atom(p, PREDICATE_ATOM, 1)) != NULL) {
		if (Calculus::Terms::variable_underlying(&(p->terms[0])) == 0) ac++;
		p = p->next;
	}
	return ac;
}

@ The following searches not for an atom, but for the lexically earliest
term in the proposition:

=
pcalc_term Calculus::Propositions::get_first_cited_term(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, prop)
		if (p->arity > 0)
			return p->terms[0];
	internal_error("Calculus::Propositions::get_first_cited_term on termless proposition");
	return Calculus::Terms::new_variable(0); /* never executed, but needed to prevent |gcc| warnings */
}

@ Here we attempt, if possible, to read a proposition as being either
{\it adjective}($v$) or $\exists v: {\it adjective}(v)$, where the adjective
can be also be read as a noun, and if so we return a constant term $t$ for
that noun; or if the proposition isn't in that form, we return $t=x$, that
is, variable 0.

=
pcalc_term Calculus::Propositions::convert_adj_to_noun(pcalc_prop *prop) {
	pcalc_term pct = Calculus::Terms::new_variable(0);
	if (prop == NULL) return pct;
	if (Calculus::Atoms::is_existence_quantifier(prop)) prop = prop->next;
	if (prop == NULL) return pct;
	if (prop->next != NULL) return pct;
	if ((prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
 		adjective_usage *tr = RETRIEVE_POINTER_adjective_usage(prop->predicate);
		return Calculus::Terms::adj_to_noun_conversion(tr);
	}
	if (prop->element == KIND_ATOM) {
 		kind *K = prop->assert_kind;
 		property *pname = Properties::Conditions::get_coinciding_property(K);
		if (pname) return Calculus::Terms::new_constant(Rvalues::from_property(pname));
	}
	return pct;
}

@ We often form propositions which are really lists of adjectives, and the
following are useful for looping through them:

=
adjective_usage *Calculus::Propositions::first_adjective_usage(pcalc_prop *prop, pcalc_prop **ppp) {
	prop = Calculus::Propositions::prop_seek_atom(prop, PREDICATE_ATOM, 1);
	if (ppp) *ppp = prop;
	if (prop == NULL) return NULL;
	return Calculus::Atoms::au_from_unary_PREDICATE(prop);
}

adjective_usage *Calculus::Propositions::next_adjective_usage(pcalc_prop **ppp) {
	if (ppp == NULL) internal_error("bad ppp");
	pcalc_prop *prop = Calculus::Propositions::prop_seek_atom((*ppp)->next, PREDICATE_ATOM, 1);
	*ppp = prop;
	if (prop == NULL) return NULL;
	return Calculus::Atoms::au_from_unary_PREDICATE(prop);
}

@h Bracketed groups.
The following routine tests whether the entire proposition is a single
bracketed group. For instance:
= (text)
	NEGATION_OPEN --> PREDICATE --> KIND --> NEGATION_CLOSE
=
would qualify. Note that detection succeeds only if the parentheses match,
and that they may be nested.

=
int Calculus::Propositions::is_a_group(pcalc_prop *prop, int governing) {
	int match = Calculus::Atoms::element_get_match(governing), level = 0;
	if (match == 0) internal_error("Calculus::Propositions::is_a_group called on unmatchable");
	TRAVERSE_VARIABLE(p);
	if ((prop == NULL) || (prop->element != governing)) return FALSE;
	TRAVERSE_PROPOSITION(p, prop) {
		if (Calculus::Atoms::element_get_group(p->element) == OPEN_OPERATORS_GROUP) level++;
		if (Calculus::Atoms::element_get_group(p->element) == CLOSE_OPERATORS_GROUP) level--;
	}
	if ((p_prev->element == match) && (level == 0)) return TRUE;
	return FALSE;
}

@ The following removes matched parentheses, leaving just the interior:

=
pcalc_prop *Calculus::Propositions::remove_topmost_group(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(p);
	if ((prop == NULL) || (Calculus::Propositions::is_a_group(prop, prop->element) == FALSE))
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
pcalc_prop *Calculus::Propositions::unnegate(pcalc_prop *prop) {
	if (Calculus::Propositions::is_a_group(prop, NEGATION_OPEN_ATOM))
		return Calculus::Propositions::remove_topmost_group(prop);
	return NULL;
}

@ More ambitiously, this removes matched parentheses found at any given
point in a proposition (which can continue after the close bracket).

=
pcalc_prop *Calculus::Propositions::ungroup_after(pcalc_prop *prop, pcalc_prop *position, pcalc_prop **last) {
	TRAVERSE_VARIABLE(p);
	pcalc_prop *from;
	int opener, closer, level;
	LOGIF(PREDICATE_CALCULUS_WORKINGS, "removing frontmost group from proposition: $D\n", prop);
	if (position == NULL) from = prop; else from = position->next;
	opener = from->element;
	closer = Calculus::Atoms::element_get_match(opener);
	if (closer == 0) internal_error("tried to remove frontmost group which doesn't open");
	from = from->next;
	prop = Calculus::Propositions::delete_atom(prop, position); /* remove opening atom */
	if (from->element == closer) { /* the special case of an empty group */
		prop = Calculus::Propositions::delete_atom(prop, position); /* remove opening atom */
		goto Ungrouped;
	}
	level = 0;
	TRAVERSE_PROPOSITION(p, from) {
		if (p->element == opener) level++;
		if (p->element == closer) level--;
		if (level < 0) {
			if (last) *last = p_prev;
			prop = Calculus::Propositions::delete_atom(prop, p_prev); /* remove closing atom */
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
pcalc_prop *Calculus::Propositions::trim_universal_quantifier(pcalc_prop *prop) {
	if ((Calculus::Atoms::is_for_all_x(prop)) &&
		(Calculus::Propositions::match(prop, 2, QUANTIFIER_ATOM, NULL, DOMAIN_OPEN_ATOM, NULL))) {
		prop = Calculus::Propositions::ungroup_after(prop, prop, NULL);
		prop = Calculus::Propositions::delete_atom(prop, NULL);
		LOGIF(PREDICATE_CALCULUS_WORKINGS, "Calculus::Propositions::trim_universal_quantifier: $D\n", prop);
	}
	return prop;
}

@ Less ambitiously:

=
pcalc_prop *Calculus::Propositions::remove_final_close_domain(pcalc_prop *prop, int *move_domain) {
	*move_domain = FALSE;
		TRAVERSE_VARIABLE(p);
		TRAVERSE_PROPOSITION(p, prop)
			if ((p->next == NULL) && (p->element == DOMAIN_CLOSE_ATOM)) {
				*move_domain = TRUE;
				return Calculus::Propositions::delete_atom(prop, p_prev);
			}
	return prop;
}

@ The following routine takes a SP and returns the best proposition it can,
with a single unbound variable, to represent SP.

=
pcalc_prop *Calculus::Propositions::from_spec(parse_node *spec) {
	if (spec == NULL) return NULL; /* the null description is universally true */

	if (Specifications::is_description(spec))
		return Descriptions::to_proposition(spec);

	pcalc_prop *prop = Specifications::to_proposition(spec);
	if (prop) return prop; /* a propositional form is already made */

	@<If this is an instance of a kind, but can be used adjectivally, convert it as such@>;
	@<If it's an either-or property name, it must be being used adjectivally@>;
	@<It must be an ordinary noun@>;
}

@ For example, if we have written:

>> Colour is a kind of value. The colours are pink, green and black. A thing has a colour.

then "pink" is both a noun and an adjective. If SP is its representation as a
noun, we return the proposition testing it adjectivally: {\it pink}($x$).

@<If this is an instance of a kind, but can be used adjectivally, convert it as such@> =
	instance *I = Rvalues::to_instance(spec);
	if (I) {
		property *pname = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
		if (pname) {
			prop = Calculus::Atoms::unary_PREDICATE_from_aph(Instances::get_adjectival_phrase(I), FALSE);
			@<Typecheck the propositional form, and return@>;
		}
	}

@ For example, if the SP is "scenery", we return the proposition {\it scenery}($x$).

@<If it's an either-or property name, it must be being used adjectivally@> =
	if (Rvalues::is_CONSTANT_construction(spec, CON_property)) {
		property *prn = Rvalues::to_property(spec);
		if (Properties::is_either_or(prn)) {
			prop = Calculus::Atoms::unary_PREDICATE_from_aph(
					Properties::EitherOr::get_aph(prn), FALSE);
			@<Typecheck the propositional form, and return@>;
		}
	}

@ For example, if the SP is the number 17, we return the proposition {\it is}($x$, 17).

@<It must be an ordinary noun@> =
	prop = Calculus::Atoms::prop_x_is_constant(Node::duplicate(spec));
	@<Typecheck the propositional form, and return@>;

@ In all cases, we finish by doing the following. In the one-atom noun cases
it's a formality, but we want to enforce the rule that all propositions
created in Inform go through type-checking, so:

@<Typecheck the propositional form, and return@> =
	Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	return prop;
