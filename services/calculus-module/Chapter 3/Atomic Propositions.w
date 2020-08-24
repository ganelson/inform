[Atoms::] Atomic Propositions.

To build and modify atoms, the syntactic pieces from which
propositions are built up.

@h Elements and groups.
Propositions are built up from "atoms": see //What This Module Does// for
more. Those atoms are themselves //pcalc_prop// objects: what makes them
atomic is simply that their |next| links lead nowhere yet.

@d MAX_ATOM_ARITY 2

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

@ Each atom is an instance of an "element", and its |element| field is one
of the |*_ATOM| numbers below. Those elements in turn occur in "groups".

@d QUANTIFIERS_GROUP 10
@d QUANTIFIER_ATOM 1 /* any generalised quantifier */

@d PREDICATES_GROUP 20
@d PREDICATE_ATOM 10 /* a regular predicate, rather than these special cases -- */
@d KIND_ATOM 11 /* a unary predicate asserting that $x$ has kind $K$ */
@d EVERYWHERE_ATOM 15 /* a unary predicate asserting omnipresence */
@d NOWHERE_ATOM 16 /* a unary predicate asserting nonpresence */
@d HERE_ATOM 17 /* a unary predicate asserting presence "here" */
@d CALLED_ATOM 18 /* to keep track of "(called the intruder)"-style names */

@d OPEN_OPERATORS_GROUP 30
@d NEGATION_OPEN_ATOM 20 /* logical negation $\lnot$ applied to contents of group */
@d DOMAIN_OPEN_ATOM 21 /* this holds the domain of a quantifier */

@d CLOSE_OPERATORS_GROUP 40
@d NEGATION_CLOSE_ATOM 30 /* end of logical negation $\lnot$ */
@d DOMAIN_CLOSE_ATOM 31 /* end of quantifier domain */

=
int Atoms::group(int element) {
	if (element <= 0) return 0;
	if (element < QUANTIFIERS_GROUP) return QUANTIFIERS_GROUP;
	if (element < PREDICATES_GROUP) return PREDICATES_GROUP;
	if (element < OPEN_OPERATORS_GROUP) return OPEN_OPERATORS_GROUP;
	if (element < CLOSE_OPERATORS_GROUP) return CLOSE_OPERATORS_GROUP;
	return 0;
}

@ Some atoms occur in pairs, which have to match like opening and closing
parentheses. The following returns 0 for an element code which does not behave
like this, or else returns the opposite number to any element code which does.

=
int Atoms::counterpart(int element) {
	switch (element) {
		case NEGATION_OPEN_ATOM: return NEGATION_CLOSE_ATOM;
		case NEGATION_CLOSE_ATOM: return NEGATION_OPEN_ATOM;
		case DOMAIN_OPEN_ATOM: return DOMAIN_CLOSE_ATOM;
		case DOMAIN_CLOSE_ATOM: return DOMAIN_OPEN_ATOM;
		default: return 0;
	}
}

@ Every atom is created by the following routine:

=
pcalc_prop *Atoms::new(int element) {
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
This group contains only |QUANTIFIER| atoms. These have arity 1, and the single
term must always be a variable, the one which is being bound.[1] The parameter
is a number needed for some |quantifier| types to identify the range: for
instance, it would be 7 in the case of |Card= 7|.

[1] Tying specific variables to quantifiers seems to be out of fashion in
modern computer science. Contemporary theorem-proving assistants mostly
use de Bruijn's numbering scheme, in which numbers 1, 2, 3, ..., refer
to variables being quantified in an indirect way. The advantage is that
propositions are easier to construct, since the same numbers can be used
in different subexpressions of the same proposition, and there's no
worrying about clashes. But it all just moves the difficulty elsewhere,
by making it less obvious how to pair up the numbers with variables at
compilation time, and less obvious even how many variables are needed.

@ =
pcalc_prop *Atoms::QUANTIFIER_new(quantifier *quant, int v, int parameter) {
	pcalc_prop *prop = Atoms::new(QUANTIFIER_ATOM);
	prop->terms[prop->arity++] = Terms::new_variable(v);
	prop->quant = quant;
	prop->quantification_parameter = parameter;
	return prop;
}

@ Quantifier atoms can be detected as follows:

=
int Atoms::is_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM)) return TRUE;
	return FALSE;
}

quantifier *Atoms::get_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM)) return prop->quant;
	return NULL;
}

int Atoms::get_quantification_parameter(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM))
		return prop->quantification_parameter;
	return 0;
}

int Atoms::is_existence_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == exists_quantifier))
		return TRUE;
	return FALSE;
}

int Atoms::is_nonexistence_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == not_exists_quantifier))
		return TRUE;
	return FALSE;
}

int Atoms::is_forall_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == for_all_quantifier))
		return TRUE;
	return FALSE;
}

int Atoms::is_notall_quantifier(pcalc_prop *prop) {
	if ((prop) && (prop->element == QUANTIFIER_ATOM) &&
		(prop->quant == not_for_all_quantifier))
		return TRUE;
	return FALSE;
}

int Atoms::is_for_all_x(pcalc_prop *prop) {
	if ((Atoms::is_forall_quantifier(prop)) &&
		(prop->terms[0].variable == 0)) return TRUE;
	return FALSE;
}

@ See //linguistics: Determiners and Quantifiers// for what a now-assertable
quantifier is:

=
int Atoms::is_now_assertable_quantifier(pcalc_prop *prop) {
	if (prop->element != QUANTIFIER_ATOM) return FALSE;
	return Quantifiers::is_now_assertable(prop->quant);
}

@h The PREDICATES group.
Next, unary predicates, beginning with the |EVERYWHERE|, |NOWHERE|, |HERE|
special cases.

=
pcalc_prop *Atoms::EVERYWHERE_new(pcalc_term pt) {
	pcalc_prop *prop = Atoms::new(EVERYWHERE_ATOM);
	prop->terms[prop->arity++] = pt;
	return prop;
}

pcalc_prop *Atoms::NOWHERE_new(pcalc_term pt) {
	pcalc_prop *prop = Atoms::new(NOWHERE_ATOM);
	prop->terms[prop->arity++] = pt;
	return prop;
}

pcalc_prop *Atoms::HERE_new(pcalc_term pt) {
	pcalc_prop *prop = Atoms::new(HERE_ATOM);
	prop->terms[prop->arity++] = pt;
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
int Atoms::is_CALLED(pcalc_prop *prop) {
	if (prop->element == CALLED_ATOM) return TRUE;
	return FALSE;
}

pcalc_prop *Atoms::CALLED_new(wording W, pcalc_term pt, kind *K) {
	pcalc_prop *prop = Atoms::new(CALLED_ATOM);
	prop->terms[prop->arity++] = pt;
	prop->calling_name = W;
	prop->assert_kind = K;
	return prop;
}

wording Atoms::CALLED_get_name(pcalc_prop *prop) {
	return prop->calling_name;
}

@ Now for a |KIND| atom. At first sight, it looks odd that a unary
predicate for a kind is represented differently from other predicates.
Isn't it a unary predicate just like any other? Well: it is, but has the
special property that its truth does not change over time. If a value |v|
satisfies |kind=K(v)| at then start of execution, it will do so throughout.
That is not true of, say, adjectival predicates like |open(v)|. Not only
is |kind=K(v)| unchanging over time, but we can determine its truth or
falsity (if we know |v|) even at compile time. We can exploit this in many
ways.

=
pcalc_prop *Atoms::KIND_new(kind *K, pcalc_term pt) {
	pcalc_prop *prop = Atoms::new(KIND_ATOM);
	prop->arity = 1;
	prop->assert_kind = K;
	prop->terms[0] = pt;
	return prop;
}

kind *Atoms::get_asserted_kind(pcalc_prop *prop) {
	if (prop) return prop->assert_kind;
	return NULL;
}

@ Composited |KIND| atoms are special in that they represent composites
of quantifiers with common nouns -- for example, "everyone" is a composite
meaning "every person".

=
pcalc_prop *Atoms::KIND_new_composited(kind *K, pcalc_term pt) {
	pcalc_prop *prop = Atoms::new(KIND_ATOM);
	prop->arity = 1;
	prop->assert_kind = K;
	prop->terms[0] = pt;
	prop->composited = TRUE;
	return prop;
}

int Atoms::is_composited(pcalc_prop *prop) {
	if ((prop) && (prop->composited)) return TRUE;
	return FALSE;
}

void Atoms::set_composited(pcalc_prop *prop, int state) {
	if (prop) prop->composited = state;
}

@ Unarticled kinds are those which were introduced without an article, in
the linguistic sense.

=
int Atoms::is_unarticled(pcalc_prop *prop) {
	if ((prop) && (prop->unarticled)) return TRUE;
	return FALSE;
}

void Atoms::set_unarticled(pcalc_prop *prop, int state) {
	if (prop) prop->unarticled = state;
}

@ That just leaves the general sort of unary predicate. In principle we ought
to be able to create $U(t)$ for any term $t$, but in practice we only ever
need $t=x$, that is, variable 0.

=
pcalc_prop *Atoms::unary_PREDICATE_new(unary_predicate *up, pcalc_term t) {
	pcalc_prop *prop = Atoms::new(PREDICATE_ATOM);
	prop->arity = 1;
	prop->terms[0] = t;
	prop->predicate = STORE_POINTER_unary_predicate(up);
	return prop;
}

pcalc_prop *Atoms::from_adjective(adjective *aph, int negated, pcalc_term t) {
	return Atoms::unary_PREDICATE_new(UnaryPredicates::new(aph, (negated)?FALSE:TRUE), t);
}

pcalc_prop *Atoms::from_adjective_on_x(adjective *aph, int negated) {
	return Atoms::from_adjective(aph, negated, Terms::new_variable(0));
}

unary_predicate *Atoms::to_adjectival_usage(pcalc_prop *prop) {
	return RETRIEVE_POINTER_unary_predicate(prop->predicate);
}

@ And binary predicates are pretty well the same:

=
pcalc_prop *Atoms::binary_PREDICATE_new(binary_predicate *bp,
	pcalc_term pt1, pcalc_term pt2) {
	pcalc_prop *prop = Atoms::new(PREDICATE_ATOM);
	prop->arity = 2;
	prop->predicate = STORE_POINTER_binary_predicate(bp);
	prop->terms[0] = pt1; prop->terms[1] = pt2;
	return prop;
}

binary_predicate *Atoms::is_binary_predicate(pcalc_prop *prop) {
	if (prop == NULL) return NULL;
	if (prop->element != PREDICATE_ATOM) return NULL;
	if (prop->arity != 2) return NULL;
	return RETRIEVE_POINTER_binary_predicate(prop->predicate);
}

int Atoms::is_equality_predicate(pcalc_prop *prop) {
	binary_predicate *bp = Atoms::is_binary_predicate(prop);
	if (bp == R_equality) return TRUE;
	return FALSE;
}

@ Given $C$, return the proposition |(x == C)|:

=
pcalc_prop *Atoms::prop_x_is_constant(parse_node *C) {
	return Atoms::binary_PREDICATE_new(R_equality,
		Terms::new_variable(0), Terms::new_constant(C));
}

@ And conversely:

=
pcalc_term *Atoms::is_x_equals(pcalc_prop *prop) {
	if (Atoms::is_equality_predicate(prop) == FALSE) return NULL;
	if (prop->terms[0].variable != 0) return NULL;
	return &(prop->terms[1]);
}

@h Validating atoms.

=
char *Atoms::validate(pcalc_prop *prop) {
	int group;
	if (prop == NULL) return NULL;
	group = Atoms::group(prop->element);
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

@h Writing to text.
Logging atomic propositions divides into cases:

=
void Atoms::log(pcalc_prop *prop) {
	Atoms::write(DL, prop);
}
void Atoms::write(text_stream *OUT, pcalc_prop *prop) {
	if (prop == NULL) { WRITE("<null-atom>"); return; }
	@<Use a special notation for equality@>;
	if (Atoms::is_CALLED(prop)) {
		wording W = Atoms::CALLED_get_name(prop);
		WRITE("called='%W'", W);
		if (prop->assert_kind) {
			WRITE("(");
			Kinds::Textual::write(OUT, prop->assert_kind);
			WRITE(")");
		}
	} else
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
		case KIND_ATOM:
			if (Streams::I6_escapes_enabled(DL) == FALSE) WRITE("kind=");
			Kinds::Textual::write(OUT, prop->assert_kind);
			if ((Streams::I6_escapes_enabled(DL) == FALSE) && (prop->composited)) WRITE("_c");
			if ((Streams::I6_escapes_enabled(DL) == FALSE) && (prop->unarticled)) WRITE("_u");
			break;
		case EVERYWHERE_ATOM: WRITE("everywhere"); break;
		case NOWHERE_ATOM: WRITE("nowhere"); break;
		case HERE_ATOM: WRITE("here"); break;
		case NEGATION_OPEN_ATOM: WRITE("NOT<"); break;
		case NEGATION_CLOSE_ATOM: WRITE("NOT>"); break;
		case DOMAIN_OPEN_ATOM: WRITE("IN<"); break;
		case DOMAIN_CLOSE_ATOM: WRITE("IN>"); break;
		default: WRITE("?bad-atom?"); break;
	}
	if (prop->arity > 0) {
		WRITE("(");
		@<Log a comma-separated list of terms for this atomic proposition@>;
		WRITE(")");
	}
}

@<Use a special notation for equality@> =
	if ((prop->element == PREDICATE_ATOM) && (prop->arity == 2) &&
		(RETRIEVE_POINTER_binary_predicate(prop->predicate) == R_equality)) {
		WRITE("(");
		Terms::write(OUT, &(prop->terms[0]));
		WRITE(" == ");
		Terms::write(OUT, &(prop->terms[1]));
		WRITE(")");
		return;
	}

@<Log some suitable textual name for this unary predicate@> =
	unary_predicate *tr = RETRIEVE_POINTER_unary_predicate(prop->predicate);
	UnaryPredicateFamilies::log(OUT, tr);

@<Log some suitable textual name for this binary predicate@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(prop->predicate);
	if (bp == NULL) WRITE("?bad-bp?"); else WRITE("%S", BinaryPredicates::get_log_name(bp));

@<Log a comma-separated list of terms for this atomic proposition@> =
	for (int t=0; t<prop->arity; t++) {
		if (t>0) WRITE(", ");
		Terms::write(OUT, &(prop->terms[t]));
	}
