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
	int element; /* one of the |*_ATOM| constants below: always 1 or greater */
	int arity; /* 1 for quantifiers and unary predicates; 2 for BPs; 0 otherwise */
	struct general_pointer predicate; /* indicates which predicate structure is meant */
	struct binary_predicate *saved_bp; /* for problem messages only */
	struct pcalc_term terms[MAX_ATOM_ARITY]; /* terms to which the predicate applies */
	struct quantifier *quant; /* |QUANTIFIER_ATOM|: which one */
	int quantification_parameter; /* |QUANTIFIER_ATOM|: e.g., the 3 in "all three" */
	struct pcalc_prop *next; /* next atom in the list for this proposition */
} pcalc_prop;

@ Each atom is an instance of an "element". There were never as many as 92 of
these, but at one time the total was pushing 20, with many quasi-predicates
having their own atom types. The introduction of //Unary Predicate Families//
in 2020 simplified the picture considerably.

@e QUANTIFIER_ATOM from 1 /* any generalised quantifier */
@e PREDICATE_ATOM         /* a regular predicate, rather than these special cases -- */
@e NEGATION_OPEN_ATOM     /* logical negation $\lnot$ applied to contents of group */
@e NEGATION_CLOSE_ATOM    /* end of logical negation $\lnot$ */
@e DOMAIN_OPEN_ATOM       /* this holds the domain of a quantifier */
@e DOMAIN_CLOSE_ATOM      /* end of quantifier domain */

@ To handle the paired punctuation marks:

=
int Atoms::is_opener(int element) {
	if ((element == NEGATION_OPEN_ATOM) || (element == DOMAIN_OPEN_ATOM))
		return TRUE;
	return FALSE;
}

int Atoms::is_closer(int element) {
	if ((element == NEGATION_CLOSE_ATOM) || (element == DOMAIN_CLOSE_ATOM))
		return TRUE;
	return FALSE;
}

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
	prop->arity = 0;
	prop->predicate = NULL_GENERAL_POINTER;
	prop->quant = NULL;
	prop->saved_bp = NULL;
	return prop;
}

@h Quantifiers.
These have arity 1, and the single term must always be a variable, the one
which is being bound.[1] The parameter is a number needed for some
|quantifier| types to identify the range: for instance, it would be 7 in the
case of |Card= 7|.

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

@h Unary predicates.

=
pcalc_prop *Atoms::unary_PREDICATE_new(unary_predicate *up, pcalc_term t) {
	pcalc_prop *prop = Atoms::new(PREDICATE_ATOM);
	prop->arity = 1;
	prop->terms[0] = t;
	prop->predicate = STORE_POINTER_unary_predicate(up);
	return prop;
}

unary_predicate *Atoms::to_adjectival_usage(pcalc_prop *prop) {
	return RETRIEVE_POINTER_unary_predicate(prop->predicate);
}

@h Binary predicates.

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
	if (prop == NULL) return NULL;
	if (prop->arity > MAX_ATOM_ARITY) return "atom with overly large arity";
	if (prop->arity < 0) return "atom with negative arity";
	if (prop->arity == 0) {
		if (prop->element == PREDICATE_ATOM) return "predicate without terms";
		if (prop->element == QUANTIFIER_ATOM) return "quantifier without variable";
	} else {
		if ((prop->element != PREDICATE_ATOM) && (prop->arity != 1))
			return "unary atom with other than one term";
		if ((Atoms::is_closer(prop->element)) || (Atoms::is_opener(prop->element)))
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
			break;
		}
		case NEGATION_OPEN_ATOM: WRITE("NOT<"); break;
		case NEGATION_CLOSE_ATOM: WRITE("NOT>"); break;
		case DOMAIN_OPEN_ATOM: WRITE("IN<"); break;
		case DOMAIN_CLOSE_ATOM: WRITE("IN>"); break;
		default: WRITE("?bad-atom?"); break;
	}
	if (prop->arity > 0) {
		if (prop->element != QUANTIFIER_ATOM) WRITE("(");
		@<Log a comma-separated list of terms for this atomic proposition@>;
		if (prop->element != QUANTIFIER_ATOM) WRITE(")");
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
