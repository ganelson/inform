[RelationRequests::] New Relation Requests.

Special sentences for creating new relations.

@ The following reads sentences like:

>> Acquaintance relates people to each other.

Note that we take at least minimal action on this as soon as we detect it,
in the pre-pass: this is important because it may affect the classification
of subsequent sentences, which also happens in the pre-pass.

The |:relations| set of test cases may be useful when tweaking the code below.

=
<new-relation-sentence-object> ::=
	<np-unparsed> to <np-unparsed>  ==> { TRUE, Node::compose(RP[1], RP[2]) }

@ =
int RelationRequests::new_relation_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Knowledge relates various people to various things." */
		case ACCEPT_SMFT:
			if (<new-relation-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				wording RW = Node::get_text(V->next);
				if (<relation-name>(RW))
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_RelationExists),
						"that relation already exists",
						"and cannot have its definition amended now.");
				else if (Wordings::length(RW) > MAX_WORDS_IN_ASSEMBLAGE-4)
					StandardProblems::sentence_problem(Task::syntax_tree(),
						_p_(PM_RelationNameTooLong),
						"this is too long a name for a single relation to have",
						"and would become unwieldy.");
				else Node::set_new_relation_here(V->next,
						BinaryPredicates::make_pair_sketchily(
							WordAssemblages::from_wording(RW), Relation_OtoO));
				return TRUE;
			}
			break;
		case PASS_1_SMFT: {
			binary_predicate *bp = Node::get_new_relation_here(V->next);
			if (bp) @<Make the request@>;
			break;
		}
	}
	return FALSE;
}

@ We won't create the relation here, only submit a request in the form of
the following object. The terms 0 and 1 represent the part before the "to"
and after; in "relates people to each other", they would derive from "people"
and "each other" respectively.

=
typedef struct relation_request {
	struct wording RW; /* name of the relation */
	struct relation_request_term terms[2];
	struct wording CONW; /* condition text */
	int frf; /* has fast route-finding */
	int symmetric; /* a symmetric relation? */
	int equivalence; /* an equivalence ("in groups") relation? */
} relation_request;

typedef struct relation_request_term {
	struct kind *domain;
	struct wording CALLW; /* "calling" name */
	int unique; /* |TRUE| for one, |FALSE| for various, |NOT_APPLICABLE| if not yet known */
} relation_request_term;

@ Syntax on the left (term 0) and right (term 1) slightly differs. The integer
result is a bitmap of these:

@d FRF_RBIT 1
@d ONE_RBIT 2
@d VAR_RBIT 4
@d ANOTHER_RBIT 8
@d EACHOTHER_RBIT 16
@d GROUPS_RBIT 32
@d WHEN_RBIT 64
@d CALLED_RBIT 128

=
<relates-sentence-left-object> ::=
	<relation-term-basic> ( called ... ) |                 ==> { R[1] | CALLED_RBIT, - }
	<relation-term-basic>                                  ==> { pass 1 }

<relates-sentence-right-object> ::=
	<relation-term-right-named> with fast route-finding |  ==> { R[1] | FRF_RBIT, - }
	<relation-term-right-named> when ... |                 ==> { R[1] | WHEN_RBIT, - }
	<relation-term-right-named>                            ==> { pass 1 }

<relation-term-right-named> ::=
	<relation-term-right> ( called ... ) |                 ==> { R[1] | CALLED_RBIT, - }
	<relation-term-right>                                  ==> { pass 1 }

<relation-term-right> ::=
	{another} |                                            ==> { ANOTHER_RBIT, - }
	{each other} |                                         ==> { EACHOTHER_RBIT, - }
	{each other in groups} |                               ==> { GROUPS_RBIT, - }
	<relation-term-basic>                                  ==> { pass 1 }

<relation-term-basic> ::=
	one ... |                                              ==> { ONE_RBIT, - }
	various ... |                                          ==> { VAR_RBIT, - }
	...                                                    ==> { 0, - }

@<Make the request@> =
	relation_request RR;
	RR.RW = Node::get_text(V->next); /* relation name */
	RR.CONW = EMPTY_WORDING;
	RR.frf = FALSE;
	RR.symmetric = FALSE;
	RR.equivalence = FALSE;
	wording TW[2];
	int bitmap[2]; /* bitmap of the |*_RBIT| values */

	@<Parse left and right object phrases@>;
	@<Find term multiplicities and use of fast route-finding@>;
	@<Detect use of symmetry in definition of second term@>;
	@<Detect use of a condition for a test-only relation@>;
	@<Vet the use of callings for the terms of the relation@>;
	@<Find the left and right domain kinds@>;
	@<Infer uniqueness if not specified@>;

	LOGIF(RELATION_DEFINITIONS,
		"Relation defn: '%W' %s %s %s (%s $u, %s $u)\n",
			RR.RW,
			(RR.symmetric)?"symmetric":"asymmetric",
			(RR.equivalence)?"equivalence":"non-equivalence",
			(RR.frf)?"frf":"no-frf",
			(RR.terms[0].unique)?"one":"various", RR.terms[0].domain,
			(RR.terms[1].unique)?"one":"various", RR.terms[1].domain);
	Relations::new(bp, &RR);

@<Parse left and right object phrases@> =
	<relates-sentence-left-object>(Node::get_text(V->next->next));
	bitmap[0] = <<r>>;
	RR.terms[0].CALLW = EMPTY_WORDING; /* left term "calling" name */
	if (bitmap[0] & CALLED_RBIT)
		RR.terms[0].CALLW = GET_RW(<relates-sentence-left-object>, 1);
	TW[0] = GET_RW(<relation-term-basic>, 1);
	RR.terms[0].unique = NOT_APPLICABLE; 
	RR.terms[0].domain = NULL; 

	<relates-sentence-right-object>(Node::get_text(V->next->next->next));
	bitmap[1] = <<r>>;
	RR.terms[1].CALLW = EMPTY_WORDING; /* right term "calling" name */
	if (bitmap[1] & CALLED_RBIT)
		RR.terms[1].CALLW = GET_RW(<relation-term-right-named>, 1);
	TW[1] = GET_RW(<relation-term-basic>, 1);
	RR.terms[1].unique = NOT_APPLICABLE;
	RR.terms[1].domain = NULL; 

	if (bitmap[1] & WHEN_RBIT)
		RR.CONW = GET_RW(<relates-sentence-right-object>, 1);

@<Find term multiplicities and use of fast route-finding@> =
	if (bitmap[0] & ONE_RBIT) RR.terms[0].unique = TRUE;
	if (bitmap[0] & VAR_RBIT) RR.terms[0].unique = FALSE;

	if (bitmap[1] & ONE_RBIT) RR.terms[1].unique = TRUE;
	if (bitmap[1] & VAR_RBIT) RR.terms[1].unique = FALSE;
	if (bitmap[1] & FRF_RBIT) RR.frf = TRUE;

	if (RR.frf && (RR.terms[0].unique != FALSE) && (RR.terms[1].unique != FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FRFUnavailable),
			"fast route-finding is only possible with various-to-various "
			"relations",
			"though this doesn't matter because with other relations the "
			"standard route-finding algorithm is efficient already.");
		return FALSE;
	}

@ The second term can be given in several special ways to indicate symmetry
between the two terms. This is more than a declaration that the left and
right terms belong to the same domain set (though that is true): it says
that $R(x, y)$ is true if and only if $R(y, x)$ is true.

@<Detect use of symmetry in definition of second term@> =
	int specified_one = RR.terms[0].unique;
	if (bitmap[1] & ANOTHER_RBIT) {
		RR.symmetric = TRUE; RR.terms[0].unique = TRUE; RR.terms[1].unique = TRUE;
	}
	if (bitmap[1] & EACHOTHER_RBIT) {
		RR.symmetric = TRUE; RR.terms[0].unique = FALSE; RR.terms[1].unique = FALSE;
	}
	if (bitmap[1] & GROUPS_RBIT) {
		RR.symmetric = TRUE; RR.terms[0].unique = FALSE; RR.terms[1].unique = FALSE;
		RR.equivalence = TRUE;
	}
	if ((specified_one == TRUE) && (RR.terms[0].unique == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BothOneAndMany),
			"the left-hand term in this relation seems to be both 'one' thing "
			"and also many things",
			"given the mention of 'each other'. Try removing the 'one'.");
		return FALSE;
	}

@ When a relation is said to hold depending on a condition to be tested at
run-time, it is meaningless to tell Inform anything about the uniqueness of
terms in the domain: a relation might be one-to-one at the start of play
but become various-to-various later on, as the outcomes of these tests
change. So we reject any such misleading syntax.

@<Detect use of a condition for a test-only relation@> =
	if (bitmap[1] & WHEN_RBIT) {
		if ((RR.terms[0].unique != NOT_APPLICABLE) || (RR.terms[1].unique != NOT_APPLICABLE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OneOrVariousWithWhen),
				"this relation is a mixture of different syntaxes",
				"and must be simplified. If it is going to specify 'one' or "
				"'various' then it cannot also say 'when' the relation holds.");
			return FALSE;
		}
	}

@ To give a name to one term implies some degree of uniqueness about it.
But that only makes sense if there is indeed some uniqueness involved,
because otherwise it is unclear what the name refers to. Who is "the
greeter of the Queen of Sheba" given the following definition?

>> Acquaintance relates various people (called the greeter) to various people.

Because of that, callings are only allowed in certain circumstances. An
exception is made -- that is, they are always allowed -- where the relation
tests a given condition, because then the names identify the terms, e.g.,

>> Divisibility relates a number (called N) to a number (called M) when the remainder after dividing M by N is 0.

Here the names "N" and "M" unambiguously refer to the terms being tested
at this moment, and have no currency beyond that context.

@<Vet the use of callings for the terms of the relation@> =
	if (Wordings::empty(RR.CONW)) {
		if ((RR.terms[0].unique == FALSE) &&
			(Wordings::nonempty(RR.terms[0].CALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallLeft),
				"the left-hand term of this relation is not unique",
				"so you cannot assign a name to it using 'called'.");
			return FALSE;
		}
		if ((RR.terms[1].unique == FALSE) &&
			(Wordings::nonempty(RR.terms[1].CALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallRight),
				"the right-hand term of this relation is not unique",
				"so you cannot assign a name to it using 'called'.");
			return FALSE;
		}
		if ((Wordings::nonempty(RR.terms[0].CALLW)) &&
			(Wordings::nonempty(RR.terms[1].CALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallBoth),
				"the terms of the relation can't be named on both sides at once",
				"and because of that it's best to use a single even-handed name: "
				"for instance, 'Marriage relates one person to another (called "
				"the spouse).' rather than 'Employment relates one person (called "
				"the boss) to one person (called the underling).'");
			return FALSE;
		}
		if ((RR.symmetric == FALSE) && (RR.terms[0].unique) && (RR.terms[1].unique) &&
			(Wordings::nonempty(RR.terms[1].CALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OneToOneMiscalled),
				"with a one-to-one relation which is not symmetrical "
				"only the left-hand item can be given a name using 'called'",
				"so this needs rephrasing to name the left in terms of the right "
				"rather than vice versa. For instance, 'Transmission relates "
				"one remote to one gadget (called the target).' should be "
				"rephrased as 'Transmission relates one gadget (called the "
				"target) to one remote.' It will then be possible to talk about "
				"'the gadget of' any given remote.");
			return FALSE;
		}
	}

@<Find the left and right domain kinds@> =
	RR.terms[0].domain = RelationRequests::parse_term(TW[0], "left");
	if (RR.symmetric) {
		RR.terms[1].domain = RR.terms[0].domain;
	} else {
		RR.terms[1].domain = RelationRequests::parse_term(TW[1], "right");
	}
	if ((RR.terms[0].domain == NULL) || (RR.terms[1].domain == NULL)) return FALSE;

@<Infer uniqueness if not specified@> =
	if (RR.terms[0].unique == NOT_APPLICABLE) {
		RR.terms[0].unique = FALSE;
		if ((Wordings::nonempty(RR.terms[0].CALLW)) || (RR.terms[1].unique == FALSE))
			RR.terms[0].unique = TRUE;
	}
	if (RR.terms[1].unique == NOT_APPLICABLE) {
		RR.terms[1].unique = FALSE;
		if ((Wordings::nonempty(RR.terms[1].CALLW)) || (RR.terms[0].unique == FALSE))
			RR.terms[1].unique = TRUE;
	}

@ A term is specified as a kind:

=
kind *RelationRequests::parse_term(wording W, char *side) {
	if (<k-kind-articled>(W)) return <<rp>>;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_text(3, side);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RelatedKindsUnknown));
	Problems::issue_problem_segment(
		"In the relation definition %1, I am unable to understand the %3-hand "
		"side -- I was expecting that %2 would be either the name of a kind, "
		"or the name of a kind of value, but it wasn't either of those.");
	Problems::issue_problem_end();
	return NULL;
}
