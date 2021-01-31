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
						Relations::Explicit::make_pair_sketchily(
							WordAssemblages::from_wording(RW)));
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
		"Relation defn: '%W' %s %s %s (%s %u, %s %u)\n",
			RR.RW,
			(RR.symmetric)?"symmetric":"asymmetric",
			(RR.equivalence)?"equivalence":"non-equivalence",
			(RR.frf)?"frf":"no-frf",
			(RR.terms[0].unique)?"one":"various", RR.terms[0].domain,
			(RR.terms[1].unique)?"one":"various", RR.terms[1].domain);
	RelationRequests::new(bp, &RR);

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

@

=
typedef struct by_routine_bp_data {
	struct wording condition_defn_text; /* ...unless this I7 condition is used instead */
	struct inter_name *bp_by_routine_iname; /* routine to determine */
	CLASS_DEFINITION
} by_routine_bp_data;

typedef struct equivalence_bp_data {
	int *equivalence_partition; /* (if right way) partition array of equivalence classes */
	CLASS_DEFINITION
} equivalence_bp_data;

@h Creation, Stage II.
Altogether, the Inform user is allowed to define some eight different forms
of relation. The code below is an attempt to find whatever common ground
can be found from these different outcomes, but inevitably ends up
splitting into cases.

=
void RelationRequests::new(binary_predicate *bp, relation_request *RR) {
	binary_predicate *bpr = bp->reversal;
	property *prn = NULL; /* used for run-time storage of this relation */
	inter_name *i6_prn_name = NULL; /* the I6 identifier for this property */
	kind *storage_kind = NULL; /* what kind, if any, might be stored in it */
	inference_subject *storage_infs = NULL; /* summing these up */

	explicit_bp_data *ED = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
			
	int rvno = FALSE, /* relate values not objects? */
		dynamic = FALSE, /* use dynamic memory allocation for storage? */
		provide_prn = FALSE, /* allocate the storage property to the kind? */
		calling_made = FALSE; /* one of the terms has been given a name */

	if (bp == NULL) internal_error("BP in relation not initially parsed");

	@<Parse the classification variables and use them to fill in the BP term details@>;

	if (rvno) { bp->relates_values_not_objects = TRUE; bpr->relates_values_not_objects = TRUE; }
	if (RR->frf) { bp->fast_route_finding = TRUE; bpr->fast_route_finding = TRUE; }
	if (prn) {
		ED->i6_storage_property = prn;
		Properties::Valued::set_stored_relation(prn, bp);
	}
	if (dynamic) {
		bp->dynamic_memory = TRUE;
		bpr->dynamic_memory = TRUE;
		package_request *P = BinaryPredicates::package(bp);
		bp->initialiser_iname = Hierarchy::make_iname_in(RELATION_INITIALISER_FN_HL, P);
	}
	BinaryPredicates::mark_as_needed(bp);

	if (Wordings::nonempty(RR->CONW)) @<Complete as a relation-by-routine BP@>
	else if (RR->equivalence) @<Complete as an equivalence-relation BP@>
	else if (RR->terms[0].unique) {
		if (RR->terms[1].unique) {
			if (RR->symmetric) @<Complete as a symmetric one-to-one BP@>
			else @<Complete as an asymmetric one-to-one BP@>;
		} else @<Complete as a one-to-various BP@>;
	} else {
		if (RR->terms[1].unique) @<Complete as a various-to-one BP@>
		else if (RR->symmetric) @<Complete as a symmetric various-to-various BP@>
		else @<Complete as an asymmetric various-to-various BP@>;
	}

	if (dynamic) {
		if (calling_made) @<Issue a problem message since this won't be stored in a property@>;
		@<Override with dynamic allocation schemata@>;
		Kinds::RunTime::ensure_basic_heap_present();
	} else {
		if (provide_prn)
			Propositions::Assert::assert_true_about(
				Propositions::Abstract::to_provide_property(prn), storage_infs, prevailing_mood);
		@<Add in the reducing functions@>;
	}

	if ((Kinds::Behaviour::is_subkind_of_object(RR->terms[0].domain)) || (Kinds::Behaviour::is_subkind_of_object(RR->terms[1].domain))) {
		relation_guard *rg = CREATE(relation_guard);
		rg->check_L = NULL; if (Kinds::Behaviour::is_subkind_of_object(RR->terms[0].domain)) rg->check_L = RR->terms[0].domain;
		rg->check_R = NULL; if (Kinds::Behaviour::is_subkind_of_object(RR->terms[1].domain)) rg->check_R = RR->terms[1].domain;
		rg->inner_test = bp->task_functions[TEST_ATOM_TASK];
		rg->inner_make_true = bp->task_functions[NOW_ATOM_TRUE_TASK];
		rg->inner_make_false = bp->task_functions[NOW_ATOM_FALSE_TASK];
		rg->guarding = bp;
		rg->f0 = BPTerms::get_function(&(bp->term_details[0]));
		rg->f1 = BPTerms::get_function(&(bp->term_details[1]));
		rg->guard_f0_iname = NULL;
		rg->guard_f1_iname = NULL;
		rg->guard_test_iname = NULL;
		rg->guard_make_true_iname = NULL;
		rg->guard_make_false_iname = NULL;
		if (rg->f0) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_f0_iname = Hierarchy::make_iname_in(GUARD_F0_FN_HL, R);
			BPTerms::set_function(&(bp->term_details[0]),
				Calculus::Schemas::new("(%n(*1))", rg->guard_f0_iname));
		}
		if (rg->f1) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_f1_iname = Hierarchy::make_iname_in(GUARD_F1_FN_HL, R);
			BPTerms::set_function(&(bp->term_details[1]),
				Calculus::Schemas::new("(%n(*1))", rg->guard_f1_iname));
		}
		if (bp->task_functions[TEST_ATOM_TASK]) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_test_iname = Hierarchy::make_iname_in(GUARD_TEST_FN_HL, R);
			bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_test_iname);
		}
		if (bp->task_functions[NOW_ATOM_TRUE_TASK]) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_make_true_iname = Hierarchy::make_iname_in(GUARD_MAKE_TRUE_FN_HL, R);
			bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_make_true_iname);
		}
		if (bp->task_functions[NOW_ATOM_FALSE_TASK]) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_make_false_iname = Hierarchy::make_iname_in(GUARD_MAKE_FALSE_INAME_HL, R);
			bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_make_false_iname);
		}
	}

	LOGIF(RELATION_DEFINITIONS, "Defined the binary predicate:\n$2\n", bp);
}

@h The parsing phase.

@<Parse the classification variables and use them to fill in the BP term details@> =
	@<Detect callings for the terms of the relation@>;
	@<Work out the kinds of the terms in the relation@>;

	if (Wordings::empty(RR->CONW)) @<Determine property used for run-time storage@>;

	@<Fill in the BP term details based on the left- and right- variables@>;

@<Fill in the BP term details based on the left- and right- variables@> =
	bp_term_details left_bptd, right_bptd;

	inference_subject *left_infs = NULL, *right_infs = NULL;
	if (RR->terms[0].domain) left_infs = Kinds::Knowledge::as_subject(RR->terms[0].domain);
	if (RR->terms[1].domain) right_infs = Kinds::Knowledge::as_subject(RR->terms[1].domain);

	left_bptd = BPTerms::new_full(left_infs, RR->terms[0].domain, RR->terms[0].CALLW, NULL);
	right_bptd = BPTerms::new_full(right_infs, RR->terms[1].domain, RR->terms[1].CALLW, NULL);

	bp->term_details[0] = left_bptd; bp->term_details[1] = right_bptd;
	bpr->term_details[0] = right_bptd; bpr->term_details[1] = left_bptd;

@ Callings are used to give names to the terms on each side of the relation,
e.g.,

>> Lock-fitting relates one thing (called the matching key) to various things.

@<Detect callings for the terms of the relation@> =
	if ((Wordings::nonempty(RR->terms[0].CALLW)) || (Wordings::nonempty(RR->terms[1].CALLW)))
		calling_made = TRUE;

@ Here we find out the kind which forms the domain on either side. Ideally
we want each to be a fixed-size and fairly small domain set; actually, best
of all is for both kinds to be within "object", since that can be stored
very efficiently, and the worst case is to be forced into "dynamic" storage:
this means using up heap memory allocated dynamically at run-time.

@<Work out the kinds of the terms in the relation@> =

	rvno = TRUE;
	if ((Kinds::Behaviour::is_object(RR->terms[0].domain)) &&
		(Kinds::Behaviour::is_object(RR->terms[1].domain))) rvno = FALSE;

	if (Wordings::empty(RR->CONW)) {
		if ((Kinds::Behaviour::is_subkind_of_object(RR->terms[0].domain) == FALSE) &&
			(RelationRequests::check_finite_range(RR->terms[0].domain) == FALSE)) dynamic = TRUE;
		if ((Kinds::Behaviour::is_subkind_of_object(RR->terms[1].domain) == FALSE) &&
			(RR->symmetric == FALSE) &&
			(RelationRequests::check_finite_range(RR->terms[1].domain) == FALSE)) dynamic = TRUE;
	}

@ All forms of relation we can produce from here use an I6 property for
run-time storage (though different forms of relation use it differently).
We use the calling, if any, to name this property: if there are no
callings, then it gets a name like "concealment relation storage", and is
omitted from the index.

@<Determine property used for run-time storage@> =
	if (Wordings::nonempty(RR->terms[0].CALLW)) {
		prn = Properties::Valued::obtain_within_kind(RR->terms[0].CALLW, RR->terms[0].domain);
		if (prn == NULL) return;
	} else if (Wordings::nonempty(RR->terms[1].CALLW)) {
		prn = Properties::Valued::obtain_within_kind(RR->terms[1].CALLW, RR->terms[1].domain);
		if (prn == NULL) return;
	} else {
		word_assemblage pw_wa =
			PreformUtilities::merge(<relation-storage-construction>, 0,
				WordAssemblages::from_wording(RR->RW));
		wording PW = WordAssemblages::to_wording(&pw_wa);
		prn = Properties::Valued::obtain_within_kind(PW, K_object);
		if (prn == NULL) return;
		Properties::exclude_from_index(prn);
	}
	i6_prn_name = Properties::iname(prn);
	storage_kind = RR->terms[0].domain;
	kind *PK = NULL;
	if (RR->terms[0].unique) {
		storage_kind = RR->terms[1].domain;
		if (RR->terms[0].domain) PK = RR->terms[0].domain;
	} else if (RR->terms[1].unique) {
		storage_kind = RR->terms[0].domain;
		if (RR->terms[1].domain) PK = RR->terms[1].domain;
	}
	if ((PK) && (Kinds::Behaviour::is_object(PK) == FALSE)) Properties::Valued::set_kind(prn, PK);
	if (storage_kind) storage_infs = Kinds::Knowledge::as_subject(storage_kind);
	else storage_infs = NULL;
	if (((RR->terms[0].unique) || (RR->terms[1].unique)) && (PK) &&
		(Kinds::Behaviour::is_object(PK) == FALSE))
		Properties::Valued::now_used_for_non_typesafe_relation(prn);

@<Issue a problem message since this won't be stored in a property@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RelNotStoredInProperty),
		"a '(called ...)' name can't be used for this relation",
		"because of the kinds involved in it. (Names for terms in a relation "
		"only work if it's possible to store the relation using properties, "
		"but that's impossible here, so Inform uses a different scheme.)");
	return;

@h The completion phase.
At this point the BP is filled in except for: its form; the schemas for
testing, asserting true and asserting false; the run-time storage property
to be used, if any; and any fields which are specific to the form in
question. Anyway, there are eight possible forms of explicit BP, so
here are eight paragraphs creating them.

@ The |Relation_OtoO| case, or one to one: "R relates one K to one K".

Such a relation consumes run-time storage of $5D$ bytes on the Z-machine
and $14D$ bytes on Glulx, where $D$ is the size of the domain...

@<Complete as an asymmetric one-to-one BP@> =
	ED->form_of_relation = Relation_OtoO;
	provide_prn = TRUE;
	if (Kinds::Behaviour::is_object(storage_kind)) {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("Relation_Now1to1(*2,%n,*1)", i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toV(*2,%n,*1)", i6_prn_name);
	} else {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("Relation_Now1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toVV(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_OtoV| case, or one to various: "R relates one K to various K".

@<Complete as a one-to-various BP@> =
	ED->form_of_relation = Relation_OtoV;
	provide_prn = TRUE;
	if (Kinds::Behaviour::is_object(storage_kind)) {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("*2.%n = *1", i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toV(*2,%n,*1)", i6_prn_name);
	} else {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("WriteGProperty(%k, *2, %n, *1)",
			storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toVV(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_VtoO| case, or various to one: "R relates various K to one K".

@<Complete as a various-to-one BP@> =
	ED->form_of_relation = Relation_VtoO;
	provide_prn = TRUE;
	if (Kinds::Behaviour::is_object(storage_kind)) {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("*1.%n = *2", i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toV(*1,%n,*2)", i6_prn_name);
	} else {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("WriteGProperty(%k, *1, %n, *2)",
			storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowN1toVV(*1,*2,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_VtoV| case, or various to various: "R relates various K to
various K".

@<Complete as an asymmetric various-to-various BP@> =
	ED->form_of_relation = Relation_VtoV;
	BinaryPredicates::mark_as_needed(bp);
	bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(Relation_TestVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("(Relation_NowVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("(Relation_NowNVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));

@ The |Relation_Sym_OtoO| case, or symmetric one to one: "R relates one K to
another".

@<Complete as a symmetric one-to-one BP@> =
	ED->form_of_relation = Relation_Sym_OtoO;
	provide_prn = TRUE;
	if (Kinds::Behaviour::is_object(storage_kind)) {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("Relation_NowS1to1(*2,%n,*1)", i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowSN1to1(*2,%n,*1)", i6_prn_name);
	} else {
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("Relation_NowS1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowSN1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_Sym_VtoV| case, or symmetric various to various: "R relates K
to each other".

@<Complete as a symmetric various-to-various BP@> =
	ED->form_of_relation = Relation_Sym_VtoV;
	BinaryPredicates::mark_as_needed(bp);
	bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(Relation_TestVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("(Relation_NowVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("(Relation_NowNVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));

@ The |Relation_Equiv| case, or equivalence relation: "R relates K to each
other in groups".

@<Complete as an equivalence-relation BP@> =
	ED->form_of_relation = Relation_Equiv;
	equivalence_bp_data *D = CREATE(equivalence_bp_data);
	D->equivalence_partition = NULL;
	ED->equiv_data = D;
	provide_prn = TRUE;
	if (Kinds::Behaviour::is_object(storage_kind)) {
		bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(*1.%n == *2.%n)", i6_prn_name, i6_prn_name);
		bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("Relation_NowEquiv(*1,%n,*2)", i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("Relation_NowNEquiv(*1,%n,*2)", i6_prn_name);
	} else {
		bp->task_functions[TEST_ATOM_TASK] =
			Calculus::Schemas::new("(GProperty(%k, *1, %n) == GProperty(%k, *2, %n))",
				storage_kind, i6_prn_name, storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_TRUE_TASK] =
			Calculus::Schemas::new("Relation_NowEquivV(*1,*2,%k,%n)", storage_kind, i6_prn_name);
		bp->task_functions[NOW_ATOM_FALSE_TASK] =
			Calculus::Schemas::new("Relation_NowNEquivV(*1,*2,%k,%n)", storage_kind, i6_prn_name);
	}
	Properties::Valued::set_kind(prn, K_number);

@ The case of a relation tested by a routine: "R relates K to L when (some
condition)".

@<Complete as a relation-by-routine BP@> =
	bp->relation_family = by_routine_bp_family;
	bp->reversal->relation_family = by_routine_bp_family;
	package_request *P = BinaryPredicates::package(bp);
	by_routine_bp_data *D = CREATE(by_routine_bp_data);
	D->condition_defn_text = RR->CONW;
	D->bp_by_routine_iname = Hierarchy::make_iname_in(RELATION_FN_HL, P);
	bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(%n(*1,*2))", D->bp_by_routine_iname);
	bp->family_specific = STORE_POINTER_by_routine_bp_data(D);

@ The left- and right- local variables above provide us with convenient
aliases for the entries which will end up in the |bp_term_details|
structures attached to the BP: this is where we put them back.

For the meaning of functions $f_0$ and $f_1$, see "Binary Predicates.w".
The idea here is this: suppose we have a relation of objects where the only
true outcomes have the form $B(f_0(y), y)$. At run-time we store the
identity of the counterpart object $f_0(y)$ in the |prn| property of the
original object $y$.

And we similarly construct an $f_1$ function if the only true outcomes
have the form $B(x, f_1(x))$.

@<Add in the reducing functions@> =
	if (i6_prn_name) {
		i6_schema *f0 = NULL, *f1 = NULL;
		if (RR->terms[0].unique) {
			if (RR->terms[1].domain) {
				if (Kinds::Behaviour::is_object(RR->terms[1].domain))
					f0 = Calculus::Schemas::new("(*1.%n)", i6_prn_name);
				else
					f0 = Calculus::Schemas::new("(GProperty(%k, *1, %n))",
						RR->terms[1].domain, i6_prn_name);
			}
		} else if (RR->terms[1].unique) {
			if (RR->terms[0].domain) {
				if (Kinds::Behaviour::is_object(RR->terms[0].domain))
					f1 = Calculus::Schemas::new("(*1.%n)", i6_prn_name);
				else
					f1 = Calculus::Schemas::new("(GProperty(%k, *1, %n))",
						RR->terms[0].domain, i6_prn_name);
			}
		}
		if (f0) BPTerms::set_function(&(bp->term_details[0]), f0);
		if (f1) BPTerms::set_function(&(bp->term_details[1]), f1);
	}

@<Override with dynamic allocation schemata@> =
	bp->task_functions[TEST_ATOM_TASK] = Calculus::Schemas::new("(RelationTest(%n,RELS_TEST,*1,*2))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_TRUE_TASK] = Calculus::Schemas::new("(RelationTest(%n,RELS_ASSERT_TRUE,*1,*2))",
		BinaryPredicates::iname(bp));
	bp->task_functions[NOW_ATOM_FALSE_TASK] = Calculus::Schemas::new("(RelationTest(%n,RELS_ASSERT_FALSE,*1,*2))",
		BinaryPredicates::iname(bp));

@h Storing relations.
At runtime, relation data is sometimes stored in a property, and that needs
to have a name:

=
<relation-storage-construction> ::=
	... relation storage

@ A modest utility, to check for a case we forbid because of the prohibitive
(or anyway unpredictable) run-time storage it would imply.

=
int RelationRequests::check_finite_range(kind *K) {
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (K == NULL) return TRUE; /* to recover from earlier problems */
	if ((Kinds::Behaviour::is_object(K)) || (Kinds::Behaviour::definite(K) == FALSE))
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RangeOverlyBroad),
			"relations aren't allowed to range over all 'objects' or all 'values'",
			"as these are too broad. A relation has to be between two kinds of "
			"object, or kinds of value. So 'Taming relates various people to "
			"various animals' is fine, because 'people' and 'animals' both mean "
			"kinds of object, but 'Wanting relates various objects to various "
			"values' is not allowed.");
	return FALSE;
}

@h Registering names of relations.

=
<relation-name-formal> ::=
	... relation

@ 

@d REGISTER_RELATIONS_CALCULUS_CALLBACK RelationRequests::register_name

=
void RelationRequests::register_name(binary_predicate *bp, word_assemblage source_name) {
	word_assemblage wa =
		PreformUtilities::merge(<relation-name-formal>, 0, source_name);
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_binary_predicate(bp), Task::language_of_syntax());
}
