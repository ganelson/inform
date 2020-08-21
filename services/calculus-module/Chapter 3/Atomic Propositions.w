[Calculus::Atoms::] Atomic Propositions.

To build and modify atoms, the syntactic pieces from which
propositions are built up.

@ As the description in the Introduction showed, propositions are complicated
data structures. Roughly speaking, they are made up of small independent pieces
which can be combined in a variety of ways into larger assemblies. In this
section, we look at the smallest pieces: some of these could be propositions in
their own right, others are only structural items needed to form up the
larger collections. But each individual piece, or "atom", is stored in
a |pcalc_prop| structure.

The question of how these are joined together is left until the next section.

@d MAX_ATOM_ARITY 2 /* for the moment, at any rate */

=
typedef struct pcalc_prop {
	int element; /* one of the constants below: always 1 or greater */
	int arity; /* 1 for quantifiers and unary predicates; 2 for BPs; 0 otherwise */
	struct general_pointer predicate; /* indicates which predicate structure is meant */
	struct pcalc_term terms[MAX_ATOM_ARITY]; /* terms to which the predicate applies */
	struct kind *assert_kind; /* |KIND_ATOM|: the kind of value of a variable */
	int composited; /* |KIND_ATOM|: arises from a composite determiner/noun like "somewhere" */
	int unarticled; /* |KIND_ATOM|: arises from an unarticled usage like "vehicle", not "a vehicle" */
	struct wording calling_name; /* |CALLED_ATOM|: text of the name this is called */
	struct quantifier *quant; /* |QUANTIFIER_ATOM|: which one */
	int quantification_parameter; /* |QUANTIFIER_ATOM|: e.g., the 3 in "all three" */
	struct pcalc_prop *next; /* next atom in the list for this proposition */
} pcalc_prop;

@ The Universe is filled with atoms, but they come in different kinds, called
elements. For us, an "element" is the identifying number, stored in the
|element| field, which tells Inform what kind of atom something is. The
following is our Periodic Table of all possible elements:

@d QUANTIFIER_ATOM 1 /* any generalised quantifier */

@d PREDICATE_ATOM 10 /* a property-based unary predicate, or any predicate of higher arity */
@d KIND_ATOM 11 /* a unary predicate $K(x)$ associated with a kind $K$ */
@d ISAKIND_ATOM 12 /* a unary predicate asserting that $x$ is the world-object for a kind */
@d ISAVAR_ATOM 13 /* a unary predicate asserting that $x$ is the SP for a global variable */
@d ISACONST_ATOM 14 /* a unary predicate asserting that $x$ is the SP for a named constant */
@d EVERYWHERE_ATOM 15 /* a unary predicate asserting omnipresence */
@d NOWHERE_ATOM 16 /* a unary predicate asserting nonpresence */
@d HERE_ATOM 17 /* a unary predicate asserting presence "here" */
@d CALLED_ATOM 18 /* to keep track of "(called the intruder)"-style names */

@d NEGATION_OPEN_ATOM 20 /* logical negation $\lnot$ applied to contents of group */
@d NEGATION_CLOSE_ATOM 30 /* end of logical negation $\lnot$ */
@d DOMAIN_OPEN_ATOM 21 /* logical negation $\lnot$ applied to contents of group */
@d DOMAIN_CLOSE_ATOM 31 /* end of logical negation $\lnot$ */

@ And as with columns in the Periodic Table, these elements come in what are
called "groups", because it often happens that atoms of different elements
behave similarly when the elements have something in common.

@d STRUCTURAL_GROUP 10
@d PREDICATES_GROUP 20
@d OPEN_OPERATORS_GROUP 30
@d CLOSE_OPERATORS_GROUP 40

@h The elements.
Given an element, the following returns the group to which it belongs.

=
int Calculus::Atoms::element_get_group(int element) {
	if (element <= 0) return 0;
	if (element < STRUCTURAL_GROUP) return STRUCTURAL_GROUP;
	if (element < PREDICATES_GROUP) return PREDICATES_GROUP;
	if (element < OPEN_OPERATORS_GROUP) return OPEN_OPERATORS_GROUP;
	if (element < CLOSE_OPERATORS_GROUP) return CLOSE_OPERATORS_GROUP;
	return 0;
}

@ Some atoms occur in pairs, which have to match like opening and closing
parentheses. The following returns 0 for an element code which does not behave
like this, or else returns the opposite number to any element code which does.

=
int Calculus::Atoms::element_get_match(int element) {
	switch (element) {
		case NEGATION_OPEN_ATOM: return NEGATION_CLOSE_ATOM;
		case NEGATION_CLOSE_ATOM: return NEGATION_OPEN_ATOM;
		case DOMAIN_OPEN_ATOM: return DOMAIN_CLOSE_ATOM;
		case DOMAIN_CLOSE_ATOM: return DOMAIN_OPEN_ATOM;
		default: return 0;
	}
}

@h Creating atoms.
Every atom is created by the following routine:

=
pcalc_prop *Calculus::Atoms::new(int element) {
	pcalc_prop *prop = CREATE(pcalc_prop);
	prop->next = NULL;
	prop->element = element;
	prop->assert_kind = NULL;
	prop->composited = FALSE;
	prop->unarticled = FALSE;
	prop->arity = 0;
	prop->predicate = NULL_GENERAL_POINTER;
	prop->quant = NULL;
	return prop;
}

@h The STRUCTURAL group.
Some convenient routines to handle atoms of specific elements now follow:
first, |QUANTIFIER| atoms. These have arity 1, and the single term must always
be a variable, the one which is being bound. The parameter is a number
needed for some |quantifier| types to identify the range: for instance,
it would be 7 in the case of $V_{=7}$.

Tying specific variables to quantifiers seems to be out of fashion in
modern computer science. Contemporary theorem-proving assistants mostly
use de Bruijn's numbering scheme, in which numbers 1, 2, 3, ..., refer
to variables being quantified in an indirect way. The advantage is that
propositions are easier to construct, since the same numbers can be used
in different subexpressions of the same proposition, and there's no
worrying about clashes. But it all just moves the difficulty elsewhere,
by making it less obvious how to pair up the numbers with variables at
compilation time, and less obvious even how many variables are needed.
So we stick to the old-fashioned way of imitating $\forall x: P(x)$
rather than $\forall 1. P$.

=
pcalc_prop *Calculus::Atoms::QUANTIFIER_new(quantifier *quant, int v, int parameter) {
	pcalc_prop *prop = Calculus::Atoms::new(QUANTIFIER_ATOM);
	prop->arity = 1;
	prop->terms[0] = Calculus::Terms::new_variable(v);
	prop->quant = quant;
	prop->quantification_parameter = parameter;
	return prop;
}

@ Quantifier atoms can be detected as follows:

=
int Calculus::Atoms::is_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM)) return TRUE;
	return FALSE;
}

quantifier *Calculus::Atoms::get_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM)) return prop->quant;
	return NULL;
}

int Calculus::Atoms::get_quantification_parameter(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM))
		return prop->quantification_parameter;
	return 0;
}

int Calculus::Atoms::is_existence_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == exists_quantifier))
		return TRUE;
	return FALSE;
}

int Calculus::Atoms::is_nonexistence_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == not_exists_quantifier))
		return TRUE;
	return FALSE;
}

int Calculus::Atoms::is_forall_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == for_all_quantifier))
		return TRUE;
	return FALSE;
}

int Calculus::Atoms::is_notall_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == not_for_all_quantifier))
		return TRUE;
	return FALSE;
}

int Calculus::Atoms::is_for_all_x(pcalc_prop *prop) {
	if ((Calculus::Atoms::is_forall_quantifier(prop)) && (prop->terms[0].variable == 0)) return TRUE;
	return FALSE;
}

@ See "Determiners and Quantifiers" for what a now-assertable quantifier is:

=
int Calculus::Atoms::is_now_assertable_quantifier(pcalc_prop *prop) {
	if (prop->element != QUANTIFIER_ATOM) return FALSE;
	return Quantifiers::is_now_assertable(prop->quant);
}

@h The PREDICATES group.
Next, unary predicates, beginning with the |EVERYWHERE| special case.

=
pcalc_prop *Calculus::Atoms::EVERYWHERE_new(pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(EVERYWHERE_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	return prop;
}

@ And |NOWHERE|:

=
pcalc_prop *Calculus::Atoms::NOWHERE_new(pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(NOWHERE_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	return prop;
}

@ And |HERE|:

=
pcalc_prop *Calculus::Atoms::HERE_new(pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(HERE_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	return prop;
}

@ And |ISAKIND|:

=
pcalc_prop *Calculus::Atoms::ISAKIND_new(pcalc_term pt, kind *K) {
	pcalc_prop *prop = Calculus::Atoms::new(ISAKIND_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	prop->assert_kind = K;
	return prop;
}

@ And |ISAVAR|:

=
pcalc_prop *Calculus::Atoms::ISAVAR_new(pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(ISAVAR_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	return prop;
}

@ And |ISACONST|:

=
pcalc_prop *Calculus::Atoms::ISACONST_new(pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(ISACONST_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	return prop;
}

@ |CALLED| atoms are interesting because they exist only for their side-effects:
they have no effect at all on the logical status of a proposition (well, except
that they should not be applied to free variables referred to nowhere else).
They can therefore be added or removed freely. In the phrase

>> if a woman is in a lighted room (called the den), ...

we need to note that the value of the bound variable corresponding to the
lighted room will need to be kept and to have a name ("the den"): this
will probably mean the inclusion of a |CALLED=den(y)| atom.

The calling data for a |CALLED| atom is the textual name by which the variable
will be called.

=
pcalc_prop *Calculus::Atoms::CALLED_new(wording W, pcalc_term pt, kind *K) {
	pcalc_prop *prop = Calculus::Atoms::new(CALLED_ATOM);
	prop->arity = 1;
	prop->terms[0] = pt;
	prop->calling_name = W;
	prop->assert_kind = K;
	return prop;
}

wording Calculus::Atoms::CALLED_get_name(pcalc_prop *prop) {
	return prop->calling_name;
}

@ Now for a |KIND| atom. At first sight, it looks odd that a unary
predicate for a kind is represented differently from other predicates.
Isn't it a unary predicate just like any other? Well: it is, but then
again, we want to compile propositions to reasonably efficient I6 code
which determines whether or not they are true. We particularly want to
look out for patterns like
$$ \forall x : ... \land {\it container}(x) \land ... $$
since they allow us to consider $x$ ranging over a smaller, and therefore
more efficiently searchable, domain: most objects aren't containers. So
|KIND_ATOM| atoms are useful in ways which other unary predicate atoms
are not.

Once again, this atom has arity 1, but the term no longer has to be a
variable; when Inform reads a sentence like

>> Viper Pit is a room.

the resulting proposition will include a |KIND| atom whose term is the
constant value for the Viper Pit.

Any kind of value can be assigned, but the commonest case involves a kind
of object, so a special routine exists just to create |KIND| atoms in
that case.

=
pcalc_prop *Calculus::Atoms::KIND_new(kind *K, pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(KIND_ATOM);
	prop->arity = 1;
	prop->assert_kind = K;
	prop->terms[0] = pt;
	return prop;
}

pcalc_prop *Calculus::Atoms::KIND_new_composited(kind *K, pcalc_term pt) {
	pcalc_prop *prop = Calculus::Atoms::new(KIND_ATOM);
	prop->arity = 1;
	prop->assert_kind = K;
	prop->terms[0] = pt;
	prop->composited = TRUE;
	return prop;
}

kind *Calculus::Atoms::get_asserted_kind(pcalc_prop *prop) {
	if (prop) return prop->assert_kind;
	return NULL;
}

int Calculus::Atoms::is_composited(pcalc_prop *prop) {
	if ((prop) && (prop->composited)) return TRUE;
	return FALSE;
}

void Calculus::Atoms::set_composited(pcalc_prop *prop, int state) {
	if (prop) prop->composited = state;
}

@ Likewise:

=
int Calculus::Atoms::is_unarticled(pcalc_prop *prop) {
	if ((prop) && (prop->unarticled)) return TRUE;
	return FALSE;
}

void Calculus::Atoms::set_unarticled(pcalc_prop *prop, int state) {
	if (prop) prop->unarticled = state;
}

@ That just leaves the general sort of unary predicate. In principle we ought
to be able to create $U(t)$ for any term $t$, but in practice we only ever
need $t=x$, that is, variable 0.

=
pcalc_prop *Calculus::Atoms::unary_PREDICATE_from_aph(adjective *aph, int negated) {
	pcalc_prop *prop = Calculus::Atoms::new(PREDICATE_ATOM);
	prop->arity = 1;
	prop->terms[0] = Calculus::Terms::new_variable(0);
	prop->predicate = STORE_POINTER_unary_predicate(
		UnaryPredicates::new(aph, (negated)?FALSE:TRUE));
	return prop;
}

unary_predicate *Calculus::Atoms::au_from_unary_PREDICATE(pcalc_prop *prop) {
	return RETRIEVE_POINTER_unary_predicate(prop->predicate);
}

@ And binary predicates are pretty well the same:

=
pcalc_prop *Calculus::Atoms::binary_PREDICATE_new(binary_predicate *bp,
	pcalc_term pt1, pcalc_term pt2) {
	pcalc_prop *prop = Calculus::Atoms::new(PREDICATE_ATOM);
	prop->arity = 2;
	prop->predicate = STORE_POINTER_binary_predicate(bp);
	prop->terms[0] = pt1; prop->terms[1] = pt2;
	return prop;
}

binary_predicate *Calculus::Atoms::is_binary_predicate(pcalc_prop *prop) {
	if (prop == NULL) return NULL;
	if (prop->element != PREDICATE_ATOM) return NULL;
	if (prop->arity != 2) return NULL;
	return RETRIEVE_POINTER_binary_predicate(prop->predicate);
}

int Calculus::Atoms::is_equality_predicate(pcalc_prop *prop) {
	binary_predicate *bp = Calculus::Atoms::is_binary_predicate(prop);
	if (bp == R_equality) return TRUE;
	return FALSE;
}

@ Given $C$, return the proposition {\it is}($x$, $C$):

=
pcalc_prop *Calculus::Atoms::prop_x_is_constant(parse_node *spec) {
	return Calculus::Atoms::binary_PREDICATE_new(R_equality,
		Calculus::Terms::new_variable(0), Calculus::Terms::new_constant(spec));
}

@ And conversely:

=
pcalc_term *Calculus::Atoms::is_x_equals(pcalc_prop *prop) {
	if (Calculus::Atoms::is_equality_predicate(prop) == FALSE) return NULL;
	if (prop->terms[0].variable != 0) return NULL;
	return &(prop->terms[1]);
}

@h Validating atoms.

=
char *Calculus::Atoms::validate(pcalc_prop *prop) {
	int group;
	if (prop == NULL) return NULL;
	group = Calculus::Atoms::element_get_group(prop->element);
	if (group == 0) return "atom of undiscovered element";
	if (prop->arity > MAX_ATOM_ARITY) return "atom with overly large arity";
	if (prop->arity < 0) return "atom with negative arity";
	if (prop->arity == 0) {
		if (group == PREDICATES_GROUP) return "predicate without terms";
		if (prop->element == QUANTIFIER_ATOM) return "quantifier without variable";
	} else {
		if ((prop->element != PREDICATE_ATOM) && (prop->arity != 1))
			return "unary atom with other than one term";
		if ((group == OPEN_OPERATORS_GROUP) || (group == CLOSE_OPERATORS_GROUP))
			return "parentheses with terms";
	}
	if ((prop->element == QUANTIFIER_ATOM) && (prop->terms[0].variable == -1))
		return "missing variable in quantification";
	return NULL;
}

@h Debugging log.
Logging atomic propositions divides into cases:

=
void Calculus::Atoms::log(pcalc_prop *prop) {
	Calculus::Atoms::write(DL, prop);
}
void Calculus::Atoms::write(text_stream *OUT, pcalc_prop *prop) {
	if (prop == NULL) { WRITE("<null-atom>"); return; }
	switch(prop->element) {
		case PREDICATE_ATOM:
			switch(prop->arity) {
				case 1: @<Log some suitable textual name for this unary predicate@>; break;
				case 2: @<Log some suitable textual name for this binary predicate@>; break;
				default: WRITE("?exotic-predicate-arity=%d?", prop->arity); break;
			}
			break;
		case QUANTIFIER_ATOM: {
			quantifier *quant = prop->quant;
			Quantifiers::log(OUT, quant, prop->quantification_parameter);
			WRITE(" "); @<Log a comma-separated list of terms for this atomic proposition@>;
			return;
		}
		case CALLED_ATOM: {
			wording W = Calculus::Atoms::CALLED_get_name(prop);
			WRITE("called='%W'", W);
			if (prop->assert_kind) {
				WRITE("(");
				Kinds::Textual::write(OUT, prop->assert_kind);
				WRITE(")");
			}
			break;
		}
		case KIND_ATOM:
			if (Streams::I6_escapes_enabled(DL) == FALSE) WRITE("kind=");
			Kinds::Textual::write(OUT, prop->assert_kind);
			if ((Streams::I6_escapes_enabled(DL) == FALSE) && (prop->composited)) WRITE("_c");
			if ((Streams::I6_escapes_enabled(DL) == FALSE) && (prop->unarticled)) WRITE("_u");
			break;
		case ISAKIND_ATOM: WRITE("is-a-kind"); break;
		case ISAVAR_ATOM: WRITE("is-a-var"); break;
		case ISACONST_ATOM: WRITE("is-a-const"); break;
		case EVERYWHERE_ATOM: WRITE("everywhere"); break;
		case NOWHERE_ATOM: WRITE("nowhere"); break;
		case HERE_ATOM: WRITE("here"); break;
		case NEGATION_OPEN_ATOM: WRITE("NOT["); break;
		case NEGATION_CLOSE_ATOM: WRITE("NOT]"); break;
		case DOMAIN_OPEN_ATOM: WRITE("IN["); break;
		case DOMAIN_CLOSE_ATOM: WRITE("IN]"); break;
		default: WRITE("?bad-atom?"); break;
	}
	if (prop->arity > 0) {
		WRITE("("); @<Log a comma-separated list of terms for this atomic proposition@>; WRITE(")");
	}
}

@<Log some suitable textual name for this unary predicate@> =
	unary_predicate *tr = RETRIEVE_POINTER_unary_predicate(prop->predicate);
	if (UnaryPredicates::get_parity(tr) == FALSE) WRITE("not-");
	Adjectives::write(OUT, UnaryPredicates::get_adj(tr));

@ And more easily:

@<Log some suitable textual name for this binary predicate@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(prop->predicate);
	if (bp == NULL) WRITE("?bad-bp?"); else WRITE("%S", BinaryPredicates::get_log_name(bp));

@ Just a diagnostic way of printing the terms in an atomic proposition, by
their index numbers. (They are numbered from 0 to $A-1$, where $A$ is the
arity.)

@<Log a comma-separated list of terms for this atomic proposition@> =
	int t;
	for (t=0; t<prop->arity; t++) {
		if (t>0) WRITE(", ");
		Calculus::Terms::write(OUT, &(prop->terms[t]));
	}
