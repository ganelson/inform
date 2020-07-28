[Relations::] Relations.

What Inform internally calls "binary predicates", the user
calls "relations". In this section, we parse definitions of new relations
and create the resulting |binary_predicate| objects.

@ The following provides for run-time checking to make sure relations are
not used with the wrong kinds of object. (Compile-time checking excludes
other cases.)

=
typedef struct relation_guard {
	struct binary_predicate *guarding; /* which one is being defended */
	struct kind *check_L; /* or null if no check needed */
	struct kind *check_R; /* or null if no check needed */
	struct i6_schema *inner_test; /* schemas for the relation if check passes */
	struct i6_schema *inner_make_true;
	struct i6_schema *inner_make_false;
	struct i6_schema *f0; /* schemas for the relation's function */
	struct i6_schema *f1;
	struct inter_name *guard_f0_iname;
	struct inter_name *guard_f1_iname;
	struct inter_name *guard_test_iname;
	struct inter_name *guard_make_true_iname;
	struct inter_name *guard_make_false_iname;
	CLASS_DEFINITION
} relation_guard;

@h Built-in relation names.
These have to be defined somewhere, and it may as well be here.

@d EQUALITY_RELATION_NAME 0
@d UNIVERSAL_RELATION_NAME 1
@d MEANING_RELATION_NAME 2
@d PROVISION_RELATION_NAME 3
@d GE_RELATION_NAME 4
@d GT_RELATION_NAME 5
@d LE_RELATION_NAME 6
@d LT_RELATION_NAME 7
@d ADJACENCY_RELATION_NAME 8
@d REGIONAL_CONTAINMENT_RELATION_NAME 9
@d CONTAINMENT_RELATION_NAME 10
@d SUPPORT_RELATION_NAME 11
@d INCORPORATION_RELATION_NAME 12
@d CARRYING_RELATION_NAME 13
@d HOLDING_RELATION_NAME 14
@d WEARING_RELATION_NAME 15
@d POSSESSION_RELATION_NAME 16
@d VISIBILITY_RELATION_NAME 17
@d TOUCHABILITY_RELATION_NAME 18
@d CONCEALMENT_RELATION_NAME 19
@d ENCLOSURE_RELATION_NAME 20
@d ROOM_CONTAINMENT_RELATION_NAME 21

@ These are the English names of the built-in relations. The use of hyphenation
here is a fossil from the times when Inform allowed only single-word relation
names; but it doesn't seem worth changing, especially as the hyphenated
relations are almost never needed for anything. All the same, translators into
other languages may as well drop the hyphens.

=
<relation-names> ::=
	equality |
	universal |
	meaning |
	provision |
	numerically-greater-than-or-equal-to |
	numerically-greater-than |
	numerically-less-than-or-equal-to |
	numerically-less-than |
	adjacency |
	regional-containment |
	containment |
	support |
	incorporation |
	carrying |
	holding |
	wearing |
	possession |
	visibility |
	touchability |
	concealment |
	enclosure |
	room-containment

@h Creation, Stage I.
The creation of relations happens in two stages. First, when the parse tree is
being organised into sentences, we call the following routine the moment a
relation definition has been found. (This is important because it may affect
the parsing of subsequent sentences in the source text.) The predicate we make
is initially sketchy: but by existing, and having a name, it can be used in
subsequent verb definitions, and then subsequent sentences using those newly
defined verbs can be properly parsed all during the same run-through of the
parse tree.

@ This handles the special meaning "X relates Y to Z".

=
<new-relation-sentence-object> ::=
	<np-unparsed> to <np-unparsed>  ==> { TRUE, RP[1] }; ((parse_node *) RP[1])->next = RP[2];

@ =
int Relations::new_relation_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Knowledge relates various people to various things." */
		case ACCEPT_SMFT:
			if (<new-relation-sentence-object>(OW)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				Relations::parse_new(V);
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			Relations::parse_new_relation_further(V);
			break;
	}
	return FALSE;
}



@ The following grammar is used to parse the subject noun phrase of
sentences like

>> Acquaintance relates people to each other.

Since the point is to create something new, the only stipulation is that the
text of the subject mustn't be an existing relation name.

=
<relates-sentence-subject> ::=
	<relation-name> |    ==> @<Issue PM_RelationExists problem@>
	...							==> { TRUE, - }

@<Issue PM_RelationExists problem@> =
	*X = FALSE;
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RelationExists),
		"that relation already exists",
		"and cannot have its definition amended now.");

@ =
void Relations::parse_new(parse_node *PN) {
	<relates-sentence-subject>(Node::get_text(PN->next));
	if (<<r>>) {
		wording W = Node::get_text(PN->next);
		W = Wordings::truncate(W, 31);
		binary_predicate *bp = BinaryPredicates::make_pair_sketchily(
			WordAssemblages::from_wording(W), Relation_OtoO);
		Node::set_new_relation_here(PN->next, bp);
	}
}

@h Creation, Stage II.
In the second stage, which is reached during the first traverse of
sentences to work through the assertions, we parse the specification of the
relation properly and complete the BP structure. (In the interim period,
the name of the BP is really the only thing that has been used.)

Altogether, the Inform user is allowed to define some eight different forms
of relation. The code below is an attempt to find whatever common ground
can be found from these different outcomes, but inevitably ends up
splitting into cases.

=
void Relations::parse_new_relation_further(parse_node *PN) {
	wording RW = Node::get_text(PN->next); /* relation name */
	wording FW = Node::get_text(PN->next->next); /* left term declaration, before "to" */
	wording SW = Node::get_text(PN->next->next->next); /* right term declaration, after "to" */

	binary_predicate *bp = Node::get_new_relation_here(PN->next);
	if (bp == NULL) return; /* to recover from problem */
	binary_predicate *bpr = bp->reversal;

	property *prn = NULL; /* used for run-time storage of this relation */
	inter_name *i6_prn_name = NULL; /* the I6 identifier for this property */
	kind *storage_kind = NULL; /* what kind, if any, might be stored in it */
	inference_subject *storage_infs = NULL; /* summing these up */
	kind *left_kind = NULL, *right_kind = NULL; /* kind requirement */
	wording CONW = EMPTY_WORDING; /* text of test condition if any */

	int left_unique = NOT_APPLICABLE, /* |TRUE| for one, |FALSE| for various, */
		right_unique = NOT_APPLICABLE, /* ...or |NOT_APPLICABLE| for unspecified */
		symmetric = FALSE, /* a symmetric relation? */
		equivalence = FALSE, /* an equivalence ("in groups") relation? */
		rvno = FALSE, /* relate values not objects? */
		frf = FALSE, /* use fast route-finding? */
		dynamic = FALSE, /* use dynamic memory allocation for storage? */
		provide_prn = FALSE, /* allocate the storage property to the kind? */
		calling_made = FALSE; /* one of the terms has been given a name */

	if (bp == NULL) internal_error("BP in relation not initially parsed");

	if (Wordings::length(RW) > MAX_WORDS_IN_ASSEMBLAGE-4) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RelationNameTooLong),
			"this is too long a name for a single relation to have",
			"and would become unwieldy.");
		RW = Wordings::truncate(RW, MAX_WORDS_IN_ASSEMBLAGE-4);
	}

	@<Parse the classification variables and use them to fill in the BP term details@>;

	if (rvno) { bp->relates_values_not_objects = TRUE; bpr->relates_values_not_objects = TRUE; }
	if (frf) { bp->fast_route_finding = TRUE; bpr->fast_route_finding = TRUE; }
	if (prn) {
		bp->i6_storage_property = prn; bpr->i6_storage_property = prn;
		Properties::Valued::set_stored_relation(prn, bp);
	}
	if (dynamic) {
		bp->dynamic_memory = TRUE;
		bpr->dynamic_memory = TRUE;
		package_request *P = BinaryPredicates::package(bp);
		bp->initialiser_iname = Hierarchy::make_iname_in(RELATION_INITIALISER_FN_HL, P);
	}
	BinaryPredicates::mark_as_needed(bp);

	if (Wordings::nonempty(CONW)) @<Complete as a relation-by-routine BP@>
	else if (equivalence) @<Complete as an equivalence-relation BP@>
	else if (left_unique) {
		if (right_unique) {
			if (symmetric) @<Complete as a symmetric one-to-one BP@>
			else @<Complete as an asymmetric one-to-one BP@>;
		} else @<Complete as a one-to-various BP@>;
	} else {
		if (right_unique) @<Complete as a various-to-one BP@>
		else if (symmetric) @<Complete as a symmetric various-to-various BP@>
		else @<Complete as an asymmetric various-to-various BP@>;
	}

	if (dynamic) {
		if (calling_made) @<Issue a problem message since this won't be stored in a property@>;
		@<Override with dynamic allocation schemata@>;
		Kinds::RunTime::ensure_basic_heap_present();
	} else {
		if (provide_prn)
			Calculus::Propositions::Assert::assert_true_about(
				Calculus::Propositions::Abstract::to_provide_property(prn), storage_infs, prevailing_mood);
		@<Add in the reducing functions@>;
	}

	if ((Kinds::Compare::lt(left_kind, K_object)) || (Kinds::Compare::lt(right_kind, K_object))) {
		relation_guard *rg = CREATE(relation_guard);
		rg->check_L = NULL; if (Kinds::Compare::lt(left_kind, K_object)) rg->check_L = left_kind;
		rg->check_R = NULL; if (Kinds::Compare::lt(right_kind, K_object)) rg->check_R = right_kind;
		rg->inner_test = bp->test_function;
		rg->inner_make_true = bp->make_true_function;
		rg->inner_make_false = bp->make_false_function;
		rg->guarding = bp;
		rg->f0 = BinaryPredicates::get_term_function(&(bp->term_details[0]));
		rg->f1 = BinaryPredicates::get_term_function(&(bp->term_details[1]));
		rg->guard_f0_iname = NULL;
		rg->guard_f1_iname = NULL;
		rg->guard_test_iname = NULL;
		rg->guard_make_true_iname = NULL;
		rg->guard_make_false_iname = NULL;
		if (rg->f0) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_f0_iname = Hierarchy::make_iname_in(GUARD_F0_FN_HL, R);
			BinaryPredicates::set_term_function(&(bp->term_details[0]),
				Calculus::Schemas::new("(%n(*1))", rg->guard_f0_iname));
		}
		if (rg->f1) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_f1_iname = Hierarchy::make_iname_in(GUARD_F1_FN_HL, R);
			BinaryPredicates::set_term_function(&(bp->term_details[1]),
				Calculus::Schemas::new("(%n(*1))", rg->guard_f1_iname));
		}
		if (bp->test_function) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_test_iname = Hierarchy::make_iname_in(GUARD_TEST_FN_HL, R);
			bp->test_function = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_test_iname);
		}
		if (bp->make_true_function) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_make_true_iname = Hierarchy::make_iname_in(GUARD_MAKE_TRUE_FN_HL, R);
			bp->make_true_function = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_make_true_iname);
		}
		if (bp->make_false_function) {
			package_request *R = BinaryPredicates::package(bp);
			rg->guard_make_false_iname = Hierarchy::make_iname_in(GUARD_MAKE_FALSE_INAME_HL, R);
			bp->make_false_function = Calculus::Schemas::new("(%n(*1,*2))", rg->guard_make_false_iname);
		}
	}

	bpr->form_of_relation = bp->form_of_relation;

	LOGIF(RELATION_DEFINITIONS, "Defined the binary predicate:\n$2\n", bp);
}

@ The following grammar is used to parse the declaration of new relations in
sentences like

>> Acquaintance relates people to each other.

In such a sentence, we'll call "people" the left object noun phrase and
"each other" the right object noun phrase. The way <relation-term-basic>
is written below, it seems to match any text, but that's just an implementation
convenience; the |...| text will eventually have to match <k-kind> and thus
to be the name of a kind, possibly in the plural.

=
<relates-sentence-left-object> ::=
	<relation-term-basic> ( called ... ) |    ==> R[1] | CALLED_RBIT
	<relation-term-basic>									==> { pass 1 }

<relates-sentence-right-object> ::=
	<relation-term-right-named> with fast route-finding |    ==> R[1] | FRF_RBIT
	<relation-term-right-named> when ... |    ==> R[1] | WHEN_RBIT
	<relation-term-right-named>								==> { pass 1 }

<relation-term-right-named> ::=
	<relation-term-right> ( called ... ) |    ==> R[1] | CALLED_RBIT
	<relation-term-right>									==> { pass 1 }

<relation-term-right> ::=
	{another} |    ==> { ANOTHER_RBIT, - }
	{each other} |    ==> { EACHOTHER_RBIT, - }
	{each other in groups} |    ==> { GROUPS_RBIT, - }
	<relation-term-basic>									==> { pass 1 }

<relation-term-basic> ::=
	one ... |    ==> { ONE_RBIT, - }
	various ... |    ==> { VAR_RBIT, - }
	...														==> { 0, - }

@h The parsing phase.
Our aims here are:

(i) to decide if the definition is valid, and reject it with a suitable
problem message if not, returning from the current routine;
(ii) to fill in the classification variables |left_unique|, |symmetric|, etc.,
as defined above;
(iii) to choose a property which will provide run-time storage for this
relation, if it needs any; and
(iv) to set |bp->term_details[0]| and |...[1]| with the kinds, names and
logical properties of the two terms of the BP being defined.

@

@d FRF_RBIT 1
@d ONE_RBIT 2
@d VAR_RBIT 4
@d ANOTHER_RBIT 8
@d EACHOTHER_RBIT 16
@d GROUPS_RBIT 32
@d WHEN_RBIT 64
@d CALLED_RBIT 128

@<Parse the classification variables and use them to fill in the BP term details@> =
	LOGIF(RELATION_DEFINITIONS,
		"Relation definition of %W: left term: '%W', right term: '%W'\n",
			RW, FW, SW);
	wording LCALLW = EMPTY_WORDING; /* left term "calling" name */
	wording RCALLW = EMPTY_WORDING; /* right term "calling" name */

	<relates-sentence-left-object>(FW);
	int left_bitmap = <<r>>;
	if (left_bitmap & CALLED_RBIT) LCALLW = GET_RW(<relates-sentence-left-object>, 1);
	FW = GET_RW(<relation-term-basic>, 1);

	<relates-sentence-right-object>(SW);
	int right_bitmap = <<r>>;
	if (right_bitmap & CALLED_RBIT) RCALLW = GET_RW(<relation-term-right-named>, 1);
	SW = GET_RW(<relation-term-basic>, 1);

	if (right_bitmap & WHEN_RBIT)
		CONW = GET_RW(<relates-sentence-right-object>, 1);

	@<Find term multiplicities and use of fast route-finding@>;
	@<Detect use of a condition for a test-only relation@>;
	@<Detect callings for the terms of the relation@>;
	@<Detect use of symmetry in definition of second term@>;
	@<Vet the use of callings for the terms of the relation@>;
	@<Work out the kinds of the terms in the relation@>;

	if (left_unique == NOT_APPLICABLE) {
		left_unique = FALSE;
		if ((Wordings::nonempty(LCALLW)) || (right_unique == FALSE)) left_unique = TRUE;
	}
	if (right_unique == NOT_APPLICABLE) {
		right_unique = FALSE;
		if ((Wordings::nonempty(RCALLW)) || (left_unique == FALSE)) right_unique = TRUE;
	}

	if (Wordings::empty(CONW)) @<Determine property used for run-time storage@>;

	@<Fill in the BP term details based on the left- and right- variables@>;

@<Fill in the BP term details based on the left- and right- variables@> =
	bp_term_details left_bptd, right_bptd;

	inference_subject *left_infs = NULL, *right_infs = NULL;
	if (left_kind) left_infs = Kinds::Knowledge::as_subject(left_kind);
	if (right_kind) right_infs = Kinds::Knowledge::as_subject(right_kind);

	left_bptd = BinaryPredicates::full_new_term(left_infs, left_kind, LCALLW, NULL);
	right_bptd = BinaryPredicates::full_new_term(right_infs, right_kind, RCALLW, NULL);

	bp->term_details[0] = left_bptd; bp->term_details[1] = right_bptd;
	bpr->term_details[0] = right_bptd; bpr->term_details[1] = left_bptd;

@ We set word ranges for the condition (if any) and the callings (if any),
whittling down the word ranges for the left and right specifications if
these are clipped away, and also look at the multiplicities.

@<Find term multiplicities and use of fast route-finding@> =
	if (left_bitmap & ONE_RBIT) left_unique = TRUE;
	if (left_bitmap & VAR_RBIT) left_unique = FALSE;

	if (right_bitmap & ONE_RBIT) right_unique = TRUE;
	if (right_bitmap & VAR_RBIT) right_unique = FALSE;
	if (right_bitmap & FRF_RBIT) frf = TRUE;

	if (frf && (left_unique != FALSE) && (right_unique != FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_FRFUnavailable),
			"fast route-finding is only possible with various-to-various "
			"relations",
			"though this doesn't matter because with other relations the "
			"standard route-finding algorithm is efficient already.");
		return;
	}

@ When a relation is said to hold depending on a condition to be tested at
run-time, it is meaningless to tell Inform anything about the uniqueness of
terms in the domain: a relation might be one-to-one at the start of play
but become various-to-various later on, as the outcomes of these tests
change. So we reject any such misleading syntax.

@<Detect use of a condition for a test-only relation@> =
	if (right_bitmap & WHEN_RBIT) {
		if ((left_unique != NOT_APPLICABLE) || (right_unique != NOT_APPLICABLE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OneOrVariousWithWhen),
				"this relation is a mixture of different syntaxes",
				"and must be simplified. If it is going to specify 'one' or "
				"'various' then it cannot also say 'when' the relation holds.");
			return;
		}
	}

@ Callings are used to give names to the terms on each side of the relation,
e.g.,

>> Lock-fitting relates one thing (called the matching key) to various things.

@<Detect callings for the terms of the relation@> =
	if ((left_bitmap & CALLED_RBIT) || (right_bitmap & CALLED_RBIT))
		calling_made = TRUE;

@ The second term can be given in several special ways to indicate symmetry
between the two terms. This is more than a declaration that the left and
right terms belong to the same domain set (though that is true): it says
that $R(x, y)$ is true if and only if $R(y, x)$ is true.

@<Detect use of symmetry in definition of second term@> =
	int specified_one = left_unique;
	if (right_bitmap & ANOTHER_RBIT) {
		symmetric = TRUE; left_unique = TRUE; right_unique = TRUE;
	}
	if (right_bitmap & EACHOTHER_RBIT) {
		symmetric = TRUE; left_unique = FALSE; right_unique = FALSE;
	}
	if (right_bitmap & GROUPS_RBIT) {
		symmetric = TRUE; left_unique = FALSE; right_unique = FALSE; equivalence = TRUE;
	}
	if ((specified_one == TRUE) && (left_unique == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BothOneAndMany),
			"the left-hand term in this relation seems to be both 'one' thing "
			"and also many things",
			"given the mention of 'each other'. Try removing the 'one'.");
		return;
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
	if (Wordings::empty(CONW)) {
		if ((left_unique == FALSE) && (Wordings::nonempty(LCALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallLeft),
				"the left-hand term of this relation is not unique",
				"so you cannot assign a name to it using 'called'.");
			return;
		}
		if ((right_unique == FALSE) && (Wordings::nonempty(RCALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallRight),
				"the right-hand term of this relation is not unique",
				"so you cannot assign a name to it using 'called'.");
			return;
		}
		if ((Wordings::nonempty(LCALLW)) && (Wordings::nonempty(RCALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantCallBoth),
				"the terms of the relation can't be named on both sides at once",
				"and because of that it's best to use a single even-handed name: "
				"for instance, 'Marriage relates one person to another (called "
				"the spouse).' rather than 'Employment relates one person (called "
				"the boss) to one person (called the underling).'");
			return;
		}
		if ((symmetric == FALSE) && (left_unique) && (right_unique) && (Wordings::nonempty(RCALLW))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OneToOneMiscalled),
				"with a one-to-one relation which is not symmetrical "
				"only the left-hand item can be given a name using 'called'",
				"so this needs rephrasing to name the left in terms of the right "
				"rather than vice versa. For instance, 'Transmission relates "
				"one remote to one gadget (called the target).' should be "
				"rephrased as 'Transmission relates one gadget (called the "
				"target) to one remote.' It will then be possible to talk about "
				"'the gadget of' any given remote.");
			return;
		}
	}

@ Here we find out the kind which forms the domain on either side. Ideally
we want each to be a fixed-size and fairly small domain set; actually, best
of all is for both kinds to be within "object", since that can be stored
very efficiently, and the worst case is to be forced into "dynamic" storage:
this means using up heap memory allocated dynamically at run-time.

@<Work out the kinds of the terms in the relation@> =
	if (Relations::parse_relation_term_type(FW, &left_kind, "left") == FALSE) return;
	if (symmetric) {
		right_kind = left_kind;
	} else {
		if (Relations::parse_relation_term_type(SW, &right_kind, "right") == FALSE) return;
	}

	rvno = TRUE;
	if ((Kinds::Compare::le(left_kind, K_object)) &&
		(Kinds::Compare::le(right_kind, K_object))) rvno = FALSE;

	if (Wordings::empty(CONW)) {
		if ((Kinds::Compare::lt(left_kind, K_object) == FALSE) &&
			(Relations::check_finite_range(left_kind) == FALSE)) dynamic = TRUE;
		if ((Kinds::Compare::lt(right_kind, K_object) == FALSE) &&
			(symmetric == FALSE) &&
			(Relations::check_finite_range(right_kind) == FALSE)) dynamic = TRUE;
	}

@ All forms of relation we can produce from here use an I6 property for
run-time storage (though different forms of relation use it differently).
We use the calling, if any, to name this property: if there are no
callings, then it gets a name like "concealment relation storage", and is
omitted from the index.

@<Determine property used for run-time storage@> =
	if (Wordings::nonempty(LCALLW)) {
		prn = Properties::Valued::obtain_within_kind(LCALLW, left_kind);
		if (prn == NULL) return;
	} else if (Wordings::nonempty(RCALLW)) {
		prn = Properties::Valued::obtain_within_kind(RCALLW, right_kind);
		if (prn == NULL) return;
	} else {
		word_assemblage pw_wa =
			PreformUtilities::merge(<relation-storage-construction>, 0,
				WordAssemblages::from_wording(RW));
		wording PW = WordAssemblages::to_wording(&pw_wa);
		prn = Properties::Valued::obtain_within_kind(PW, K_object);
		if (prn == NULL) return;
		Properties::exclude_from_index(prn);
	}
	i6_prn_name = Properties::iname(prn);
	storage_kind = left_kind;
	kind *PK = NULL;
	if (left_unique) {
		storage_kind = right_kind;
		if (left_kind) PK = left_kind;
	} else if (right_unique) {
		storage_kind = left_kind;
		if (right_kind) PK = right_kind;
	}
	if ((PK) && (Kinds::Compare::le(PK, K_object) == FALSE)) Properties::Valued::set_kind(prn, PK);
	if (storage_kind) storage_infs = Kinds::Knowledge::as_subject(storage_kind);
	else storage_infs = NULL;
	if (Kinds::Compare::le(storage_kind, K_object) == FALSE) bp->storage_kind = storage_kind;
	if (((left_unique) || (right_unique)) && (PK) &&
		(Kinds::Compare::le(PK, K_object) == FALSE))
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
	bp->form_of_relation = Relation_OtoO;
	provide_prn = TRUE;
	if (Kinds::Compare::le(storage_kind, K_object)) {
		bp->make_true_function = Calculus::Schemas::new("Relation_Now1to1(*2,%n,*1)", i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toV(*2,%n,*1)", i6_prn_name);
	} else {
		bp->make_true_function = Calculus::Schemas::new("Relation_Now1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toVV(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_OtoV| case, or one to various: "R relates one K to various K".

@<Complete as a one-to-various BP@> =
	bp->form_of_relation = Relation_OtoV;
	provide_prn = TRUE;
	if (Kinds::Compare::le(storage_kind, K_object)) {
		bp->make_true_function = Calculus::Schemas::new("*2.%n = *1", i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toV(*2,%n,*1)", i6_prn_name);
	} else {
		bp->make_true_function = Calculus::Schemas::new("WriteGProperty(%k, *2, %n, *1)",
			storage_kind, i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toVV(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_VtoO| case, or various to one: "R relates various K to one K".

@<Complete as a various-to-one BP@> =
	bp->form_of_relation = Relation_VtoO;
	provide_prn = TRUE;
	if (Kinds::Compare::le(storage_kind, K_object)) {
		bp->make_true_function = Calculus::Schemas::new("*1.%n = *2", i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toV(*1,%n,*2)", i6_prn_name);
	} else {
		bp->make_true_function = Calculus::Schemas::new("WriteGProperty(%k, *1, %n, *2)",
			storage_kind, i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowN1toVV(*1,*2,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_VtoV| case, or various to various: "R relates various K to
various K".

@<Complete as an asymmetric various-to-various BP@> =
	bp->form_of_relation = Relation_VtoV;
	bp->arbitrary = TRUE;
	BinaryPredicates::mark_as_needed(bp);
	bp->test_function = Calculus::Schemas::new("(Relation_TestVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));
	bp->make_true_function = Calculus::Schemas::new("(Relation_NowVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));
	bp->make_false_function = Calculus::Schemas::new("(Relation_NowNVtoV(*1,%n,*2,false))",
		BinaryPredicates::iname(bp));

@ The |Relation_Sym_OtoO| case, or symmetric one to one: "R relates one K to
another".

@<Complete as a symmetric one-to-one BP@> =
	bp->form_of_relation = Relation_Sym_OtoO;
	provide_prn = TRUE;
	if (Kinds::Compare::le(storage_kind, K_object)) {
		bp->make_true_function = Calculus::Schemas::new("Relation_NowS1to1(*2,%n,*1)", i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowSN1to1(*2,%n,*1)", i6_prn_name);
	} else {
		bp->make_true_function = Calculus::Schemas::new("Relation_NowS1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowSN1to1V(*2,*1,%k,%n)",
			storage_kind, i6_prn_name);
	}

@ The |Relation_Sym_VtoV| case, or symmetric various to various: "R relates K
to each other".

@<Complete as a symmetric various-to-various BP@> =
	bp->form_of_relation = Relation_Sym_VtoV;
	bp->arbitrary = TRUE;
	BinaryPredicates::mark_as_needed(bp);
	bp->test_function = Calculus::Schemas::new("(Relation_TestVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));
	bp->make_true_function = Calculus::Schemas::new("(Relation_NowVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));
	bp->make_false_function = Calculus::Schemas::new("(Relation_NowNVtoV(*1,%n,*2,true))",
		BinaryPredicates::iname(bp));

@ The |Relation_Equiv| case, or equivalence relation: "R relates K to each
other in groups".

@<Complete as an equivalence-relation BP@> =
	bp->form_of_relation = Relation_Equiv;
	bp->arbitrary = TRUE;
	provide_prn = TRUE;
	if (Kinds::Compare::le(storage_kind, K_object)) {
		bp->test_function = Calculus::Schemas::new("(*1.%n == *2.%n)", i6_prn_name, i6_prn_name);
		bp->make_true_function = Calculus::Schemas::new("Relation_NowEquiv(*1,%n,*2)", i6_prn_name);
		bp->make_false_function = Calculus::Schemas::new("Relation_NowNEquiv(*1,%n,*2)", i6_prn_name);
	} else {
		bp->test_function =
			Calculus::Schemas::new("(GProperty(%k, *1, %n) == GProperty(%k, *2, %n))",
				storage_kind, i6_prn_name, storage_kind, i6_prn_name);
		bp->make_true_function =
			Calculus::Schemas::new("Relation_NowEquivV(*1,*2,%k,%n)", storage_kind, i6_prn_name);
		bp->make_false_function =
			Calculus::Schemas::new("Relation_NowNEquivV(*1,*2,%k,%n)", storage_kind, i6_prn_name);
	}
	Properties::Valued::set_kind(prn, K_number);

@ The |Relation_ByRoutine| case, or relation tested by a routine: "R relates
K to L when (some condition)".

@<Complete as a relation-by-routine BP@> =
	bp->form_of_relation = Relation_ByRoutine;
	package_request *P = BinaryPredicates::package(bp);
	bp->bp_by_routine_iname = Hierarchy::make_iname_in(RELATION_FN_HL, P);
	bp->test_function = Calculus::Schemas::new("(%n(*1,*2))", bp->bp_by_routine_iname);
	bp->condition_defn_text = CONW;

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
		if (left_unique) {
			if (right_kind) {
				if (Kinds::Compare::le(right_kind, K_object))
					f0 = Calculus::Schemas::new("(*1.%n)", i6_prn_name);
				else
					f0 = Calculus::Schemas::new("(GProperty(%k, *1, %n))",
						right_kind, i6_prn_name);
			}
		} else if (right_unique) {
			if (left_kind) {
				if (Kinds::Compare::le(left_kind, K_object))
					f1 = Calculus::Schemas::new("(*1.%n)", i6_prn_name);
				else
					f1 = Calculus::Schemas::new("(GProperty(%k, *1, %n))",
						left_kind, i6_prn_name);
			}
		}
		if (f0) BinaryPredicates::set_term_function(&(bp->term_details[0]), f0);
		if (f1) BinaryPredicates::set_term_function(&(bp->term_details[1]), f1);
	}

@<Override with dynamic allocation schemata@> =
	bp->test_function = Calculus::Schemas::new("(RelationTest(%n,RELS_TEST,*1,*2))",
		BinaryPredicates::iname(bp));
	bp->make_true_function = Calculus::Schemas::new("(RelationTest(%n,RELS_ASSERT_TRUE,*1,*2))",
		BinaryPredicates::iname(bp));
	bp->make_false_function = Calculus::Schemas::new("(RelationTest(%n,RELS_ASSERT_FALSE,*1,*2))",
		BinaryPredicates::iname(bp));

@h Storing relations.
At runtime, relation data is sometimes stored in a property, and that needs
to have a name:

=
<relation-storage-construction> ::=
	... relation storage

@h Parsing utilities.
A term is specified as a kind.

=
int Relations::parse_relation_term_type(wording W, kind **set_K, char *side) {
	if (<k-kind-articled>(W)) { *set_K = <<rp>>; return TRUE; }
	*set_K = NULL;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_text(3, side);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RelatedKindsUnknown));
	Problems::issue_problem_segment(
		"In the relation definition %1, I am unable to understand the %3-hand "
		"side -- I was expecting that %2 would be either the name of a kind, "
		"or the name of a kind of value, but it wasn't either of those.");
	Problems::issue_problem_end();
	return FALSE;
}

@ A modest utility, to check for a case we forbid because of the prohibitive
(or anyway unpredictable) run-time storage it would imply.

=
int Relations::check_finite_range(kind *K) {
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (K == NULL) return TRUE; /* to recover from earlier problems */
	if ((Kinds::Compare::le(K, K_object)) || (Kinds::Behaviour::definite(K) == FALSE))
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RangeOverlyBroad),
			"relations aren't allowed to range over all 'objects' or all 'values'",
			"as these are too broad. A relation has to be between two kinds of "
			"object, or kinds of value. So 'Taming relates various people to "
			"various animals' is fine, because 'people' and 'animals' both mean "
			"kinds of object, but 'Wanting relates various objects to various "
			"values' is not allowed.");
	return FALSE;
}

@h Relation records.
The template layer needs to be able to perform certain actions on any given
relation, regardless of its mode of storage (if any). We abstract all of this
by giving each relation a "record", which says what it can do, how it does
it, and where it stores its data.

@ The following permissions are intended to form a bitmap in arbitrary
combinations.

=
inter_name *RELS_SYMMETRIC_iname = NULL;
inter_name *RELS_EQUIVALENCE_iname = NULL;
inter_name *RELS_X_UNIQUE_iname = NULL;
inter_name *RELS_Y_UNIQUE_iname = NULL;
inter_name *RELS_TEST_iname = NULL;
inter_name *RELS_ASSERT_TRUE_iname = NULL;
inter_name *RELS_ASSERT_FALSE_iname = NULL;
inter_name *RELS_SHOW_iname = NULL;
inter_name *RELS_ROUTE_FIND_iname = NULL;
inter_name *RELS_ROUTE_FIND_COUNT_iname = NULL;
inter_name *RELS_LOOKUP_ANY_iname = NULL;
inter_name *RELS_LOOKUP_ALL_X_iname = NULL;
inter_name *RELS_LOOKUP_ALL_Y_iname = NULL;
inter_name *RELS_LIST_iname = NULL;
inter_name *REL_BLOCK_HEADER_symbol = NULL;
inter_name *TTF_iname = NULL;

inter_name *Relations::compile_defined_relation_constant(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_hex(iname, val);
	return iname;
}

void Relations::compile_defined_relation_constants(void) {
	RELS_SYMMETRIC_iname = Relations::compile_defined_relation_constant(RELS_SYMMETRIC_HL, 0x8000);
	RELS_EQUIVALENCE_iname = Relations::compile_defined_relation_constant(RELS_EQUIVALENCE_HL, 0x4000);
	RELS_X_UNIQUE_iname = Relations::compile_defined_relation_constant(RELS_X_UNIQUE_HL, 0x2000);
	RELS_Y_UNIQUE_iname = Relations::compile_defined_relation_constant(RELS_Y_UNIQUE_HL, 0x1000);
	RELS_TEST_iname = Relations::compile_defined_relation_constant(RELS_TEST_HL, 0x0800);
	RELS_ASSERT_TRUE_iname = Relations::compile_defined_relation_constant(RELS_ASSERT_TRUE_HL, 0x0400);
	RELS_ASSERT_FALSE_iname = Relations::compile_defined_relation_constant(RELS_ASSERT_FALSE_HL, 0x0200);
	RELS_SHOW_iname = Relations::compile_defined_relation_constant(RELS_SHOW_HL, 0x0100);
	RELS_ROUTE_FIND_iname = Relations::compile_defined_relation_constant(RELS_ROUTE_FIND_HL, 0x0080);
	RELS_ROUTE_FIND_COUNT_iname = Relations::compile_defined_relation_constant(RELS_ROUTE_FIND_COUNT_HL, 0x0040);
	RELS_LOOKUP_ANY_iname = Relations::compile_defined_relation_constant(RELS_LOOKUP_ANY_HL, 0x0008);
	RELS_LOOKUP_ALL_X_iname = Relations::compile_defined_relation_constant(RELS_LOOKUP_ALL_X_HL, 0x0004);
	RELS_LOOKUP_ALL_Y_iname = Relations::compile_defined_relation_constant(RELS_LOOKUP_ALL_Y_HL, 0x0002);
	RELS_LIST_iname = Relations::compile_defined_relation_constant(RELS_LIST_HL, 0x0001);
	if (TargetVMs::is_16_bit(Task::vm())) {
		REL_BLOCK_HEADER_symbol = Relations::compile_defined_relation_constant(REL_BLOCK_HEADER_HL, 0x100*5 + 13); /* $2^5 = 32$ bytes block */
	} else {
		REL_BLOCK_HEADER_symbol = Relations::compile_defined_relation_constant(REL_BLOCK_HEADER_HL, (0x100*6 + 13)*0x10000);
	}
	TTF_iname = Relations::compile_defined_relation_constant(TTF_SUM_HL, (0x0800 + 0x0400 + 0x0200));
	/* i.e., |RELS_TEST + RELS_ASSERT_TRUE + RELS_ASSERT_FALSE| */
}

@ =
void Relations::compile_relation_records(void) {
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate) {
		binary_predicate *dbp = bp;
		if (bp->right_way_round == FALSE) dbp = bp->reversal;
		int minimal = FALSE;
		if ((dbp == R_equality) || (dbp == R_meaning) ||
			(dbp == R_provision) || (dbp == R_universal))
			minimal = TRUE;
		if (bp->record_needed) {
			inter_name *handler = NULL;
			if (bp->dynamic_memory == FALSE)
				@<Write the relation handler routine for this BP@>;
			@<Write the relation record for this BP@>;
		}
	}
	inter_name *iname = Hierarchy::find(CREATEDYNAMICRELATIONS_HL);
	packaging_state save = Routines::begin(iname);
	LocalVariables::add_internal_local_c_as_symbol(I"i", "loop counter");
	LocalVariables::add_internal_local_c_as_symbol(I"rel", "new relation");
	LOOP_OVER(bp, binary_predicate) {
		if ((bp->dynamic_memory) && (bp->right_way_round)) {

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECREATE_HL));
			Produce::down(Emit::tree());
				Kinds::RunTime::emit_strong_id_as_val(BinaryPredicates::kind(bp));
				Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
			Produce::up(Emit::tree());

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_NAME_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
				TEMPORARY_TEXT(A)
				WRITE_TO(A, "%A", &(bp->relation_name));
				Produce::val_text(Emit::tree(), A);
				DISCARD_TEXT(A)
			Produce::up(Emit::tree());

			switch(bp->form_of_relation) {
				case Relation_OtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_OtoV:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOVADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_VtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_VTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_Sym_OtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_Equiv:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_EQUIVALENCEADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_VtoV: break;
				case Relation_Sym_VtoV:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
			}
			Produce::inv_primitive(Emit::tree(), INDIRECT0V_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, bp->initialiser_iname);
			Produce::up(Emit::tree());
		}
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@<Write the relation record for this BP@> =
	if (BinaryPredicates::iname(bp) == NULL) internal_error("no bp symbol");
	packaging_state save = Emit::named_array_begin(BinaryPredicates::iname(bp), K_value);
	if (bp->dynamic_memory) {
		Emit::array_numeric_entry((inter_ti) 1); /* meaning one entry, which is 0; to be filled in later */
	} else {
		Kinds::RunTime::emit_block_value_header(BinaryPredicates::kind(bp), FALSE, 8);
		Emit::array_null_entry();
		Emit::array_null_entry();
		@<Write the name field of the relation record@>;
		@<Write the permissions field of the relation record@>;
		@<Write the storage field of the relation metadata array@>;
		@<Write the kind field of the relation record@>;
		@<Write the handler field of the relation record@>;
		@<Write the description field of the relation record@>;
	}
	Emit::array_end(save);

@<Write the name field of the relation record@> =
	TEMPORARY_TEXT(NF)
	WRITE_TO(NF, "%A relation", &(bp->relation_name));
	Emit::array_text_entry(NF);
	DISCARD_TEXT(NF)

@<Write the permissions field of the relation record@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	inter_name *bm_symb = Hierarchy::make_iname_in(ABILITIES_HL, bp->bp_package);
	packaging_state save_sum = Emit::sum_constant_begin(bm_symb, K_value);
	if (RELS_TEST_iname == NULL) internal_error("no RELS symbols yet");
	Emit::array_iname_entry(RELS_TEST_iname);
	if (minimal == FALSE) {
		Emit::array_iname_entry(RELS_LOOKUP_ANY_iname);
		Emit::array_iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		Emit::array_iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		Emit::array_iname_entry(RELS_LIST_iname);
	}
	switch(dbp->form_of_relation) {
		case Relation_Implicit:
			if ((minimal == FALSE) && (BinaryPredicates::can_be_made_true_at_runtime(dbp))) {
				Emit::array_iname_entry(RELS_ASSERT_TRUE_iname);
				Emit::array_iname_entry(RELS_ASSERT_FALSE_iname);
				Emit::array_iname_entry(RELS_LOOKUP_ANY_iname); // Really?
			}
			break;
		case Relation_OtoO: Emit::array_iname_entry(RELS_X_UNIQUE_iname); Emit::array_iname_entry(RELS_Y_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_OtoV: Emit::array_iname_entry(RELS_X_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_VtoO: Emit::array_iname_entry(RELS_Y_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_Sym_OtoO:
			Emit::array_iname_entry(RELS_SYMMETRIC_iname);
			Emit::array_iname_entry(RELS_X_UNIQUE_iname);
			Emit::array_iname_entry(RELS_Y_UNIQUE_iname);
			@<Throw in the full suite@>; break;
		case Relation_Equiv: Emit::array_iname_entry(RELS_EQUIVALENCE_iname); @<Throw in the full suite@>; break;
		case Relation_VtoV: @<Throw in the full suite@>; break;
		case Relation_Sym_VtoV: Emit::array_iname_entry(RELS_SYMMETRIC_iname); @<Throw in the full suite@>; break;
		case Relation_ByRoutine: break;
		default:
			internal_error("Binary predicate with unknown structural type");
	}
	Emit::array_end(save_sum); /* of the summation, that is */
	Emit::array_iname_entry(bm_symb);

@<Throw in the full suite@> =
	Emit::array_iname_entry(RELS_ASSERT_TRUE_iname);
	Emit::array_iname_entry(RELS_ASSERT_FALSE_iname);
	Emit::array_iname_entry(RELS_SHOW_iname);
	Emit::array_iname_entry(RELS_ROUTE_FIND_iname);

@ The storage field has different meanings for different families of BPs:

@<Write the storage field of the relation metadata array@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	switch(dbp->form_of_relation) {
		case Relation_Implicit: /* Field 0 is not used */
			Emit::array_numeric_entry(0); /* which is not the same as |NULL|, unlike in C */
			break;
		case Relation_OtoO:
		case Relation_OtoV:
		case Relation_VtoO:
		case Relation_Sym_OtoO:
		case Relation_Equiv: /* Field 0 is the property used for run-time storage */
			Emit::array_iname_entry(Properties::iname(dbp->i6_storage_property));
			break;
		case Relation_VtoV:
		case Relation_Sym_VtoV: /* Field 0 is the bitmap array used for run-time storage */
			if (dbp->v2v_bitmap_iname == NULL) internal_error("gaah");
			Emit::array_iname_entry(dbp->v2v_bitmap_iname);
			break;
		case Relation_ByRoutine: /* Field 0 is the routine used to test the relation */
			Emit::array_iname_entry(dbp->bp_by_routine_iname);
			break;
		default:
			internal_error("Binary predicate with unknown structural type");
	}

@<Write the kind field of the relation record@> =
	Kinds::RunTime::emit_strong_id(BinaryPredicates::kind(bp));

@<Write the description field of the relation record@> =
	TEMPORARY_TEXT(DF)
	if (bp->form_of_relation == Relation_Implicit)
		WRITE_TO(DF, "%S", BinaryPredicates::get_log_name(bp));
	else CompiledText::from_text(DF, Node::get_text(bp->bp_created_at));
	Emit::array_text_entry(DF);
	DISCARD_TEXT(DF)

@<Write the handler field of the relation record@> =
	Emit::array_iname_entry(handler);

@<Write the relation handler routine for this BP@> =
	text_stream *X = I"X", *Y = I"Y";
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) { X = I"Y"; Y = I"X"; dbp = bp->reversal; }

	handler = BinaryPredicates::handler_iname(bp);
	packaging_state save = Routines::begin(handler);
	inter_symbol *rr_s = LocalVariables::add_named_call_as_symbol(I"rr");
	inter_symbol *task_s = LocalVariables::add_named_call_as_symbol(I"task");
	local_variable *X_lv = NULL, *Y_lv = NULL;
	inter_symbol *X_s = LocalVariables::add_named_call_as_symbol_noting(I"X", &X_lv);
	inter_symbol *Y_s = LocalVariables::add_named_call_as_symbol_noting(I"Y", &Y_lv);
	local_variable *Z1_lv = NULL, *Z2_lv = NULL, *Z3_lv = NULL, *Z4_lv = NULL;
	inter_symbol *Z1_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"Z1", "loop counter", &Z1_lv);
	LocalVariables::add_internal_local_c_as_symbol_noting(I"Z2", "loop counter", &Z2_lv);
	inter_symbol *Z3_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"Z3", "loop counter", &Z3_lv);
	LocalVariables::add_internal_local_c_as_symbol_noting(I"Z4", "loop counter", &Z4_lv);

	annotated_i6_schema asch; i6_schema *i6s = NULL;

	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, task_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					@<The TEST task@>;
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			if (minimal) {
				Produce::inv_primitive(Emit::tree(), DEFAULT_BIP);
				Produce::down(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The default case for minimal relations only@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			} else {
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ANY_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ANY task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ALL X task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ALL_Y_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ALL Y task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LIST_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LIST task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				if (BinaryPredicates::can_be_made_true_at_runtime(bp)) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ASSERT_TRUE_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ASSERT TRUE task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ASSERT_FALSE_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ASSERT FALSE task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *shower = NULL;
				int par = 0;
				switch(dbp->form_of_relation) {
					case Relation_OtoO: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_OtoV: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_VtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); break;
					case Relation_Sym_OtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); par = 1; break;
					case Relation_Equiv: shower = Hierarchy::find(RELATION_SHOWEQUIV_HL); break;
					case Relation_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); break;
					case Relation_Sym_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); par = 1; break;
				}
				if (shower) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_SHOW_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The SHOW task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *emptier = NULL;
				par = 0;
				switch(dbp->form_of_relation) {
					case Relation_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_OtoV: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_VtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_Sym_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); par = 1; break;
					case Relation_Equiv: emptier = Hierarchy::find(RELATION_EMPTYEQUIV_HL); break;
					case Relation_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); break;
					case Relation_Sym_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); par = 1; break;
				}
				if (emptier) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_EMPTY_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The EMPTY task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *router = NULL;
				int id_flag = TRUE;
				int follow = FALSE;
				switch(dbp->form_of_relation) {
					case Relation_OtoO: router = Hierarchy::find(OTOVRELROUTETO_HL); follow = TRUE; break;
					case Relation_OtoV: router = Hierarchy::find(OTOVRELROUTETO_HL); follow = TRUE; break;
					case Relation_VtoO: router = Hierarchy::find(VTOORELROUTETO_HL); follow = TRUE; break;
					case Relation_VtoV:
					case Relation_Sym_VtoV:
						id_flag = FALSE;
						router = Hierarchy::find(VTOVRELROUTETO_HL);
						break;
				}
				if (router) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ROUTE_FIND_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ROUTE FIND task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ROUTE_FIND_COUNT_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ROUTE FIND COUNT task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
			}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::rfalse(Emit::tree());
	Routines::end(save);

@<The default case for minimal relations only@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELMINIMAL_HL));
		Produce::val_symbol(Emit::tree(), K_value, task_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
	Produce::up(Emit::tree());

@<The ASSERT TRUE task@> =
	asch = Calculus::Atoms::Compile::blank_asch();
	i6s = BinaryPredicates::get_i6_schema(NOW_ATOM_TRUE_TASK, dbp, &asch);
	if (i6s == NULL) Produce::rfalse(Emit::tree());
	else {
		Calculus::Schemas::emit_expand_from_locals(i6s, X_lv, Y_lv, TRUE);
		Produce::rtrue(Emit::tree());
	}

@<The ASSERT FALSE task@> =
	asch = Calculus::Atoms::Compile::blank_asch();
	i6s = BinaryPredicates::get_i6_schema(NOW_ATOM_FALSE_TASK, dbp, &asch);
	if (i6s == NULL) Produce::rfalse(Emit::tree());
	else {
		Calculus::Schemas::emit_expand_from_locals(i6s, X_lv, Y_lv, TRUE);
		Produce::rtrue(Emit::tree());
	}

@<The TEST task@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		asch = Calculus::Atoms::Compile::blank_asch();
		i6s = BinaryPredicates::get_i6_schema(TEST_ATOM_TASK, dbp, &asch);
		int adapted = FALSE;
		for (int j=0; j<2; j++) {
			i6_schema *fnsc = BinaryPredicates::get_term_as_function_of_other(bp, j);
			if (fnsc) {
				if (j == 0) {
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						Calculus::Schemas::emit_val_expand_from_locals(fnsc, Y_lv, Y_lv);
					Produce::up(Emit::tree());
					adapted = TRUE;
				} else {
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, Y_s);
						Calculus::Schemas::emit_val_expand_from_locals(fnsc, X_lv, X_lv);
					Produce::up(Emit::tree());
					adapted = TRUE;
				}
			}
		}
		if (adapted == FALSE) {
			if (i6s == NULL) Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			else Calculus::Schemas::emit_val_expand_from_locals(i6s, X_lv, Y_lv);
		}
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rtrue(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::rfalse(Emit::tree());

@<The ROUTE FIND task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, router);
			@<Expand the ID operand@>;
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Expand the ID operand@> =
	if (id_flag) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RLNGETF_HL));
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, rr_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RR_STORAGE_HL));
		Produce::up(Emit::tree());
	} else {
		Produce::val_symbol(Emit::tree(), K_value, rr_s);
	}

@<The ROUTE FIND COUNT task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
	if (follow) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELFOLLOWVECTOR_HL));
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, router);
				@<Expand the ID operand@>;
				Produce::val_symbol(Emit::tree(), K_value, X_s);
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::up(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, router);
			@<Expand the ID operand@>;
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	}
	Produce::up(Emit::tree());

@<The SHOW task@> =
	Produce::inv_primitive(Emit::tree(), INDIRECT2V_BIP);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, shower);
		Produce::val_symbol(Emit::tree(), K_value, rr_s);
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, (inter_ti) par);
	Produce::up(Emit::tree());
	Produce::rtrue(Emit::tree());

@<The EMPTY task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, emptier);
			Produce::val_symbol(Emit::tree(), K_value, rr_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, (inter_ti) par);
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, X_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<The LOOKUP ANY task@> =
	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), OR_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_GET_X_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			int t = 0;
			@<Write rels lookup@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			t = 1;
			@<Write rels lookup@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<The LOOKUP ALL X task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	int t = 0;
	@<Write rels lookup list@>;

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
	Produce::up(Emit::tree());

@<The LOOKUP ALL Y task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	int t = 1;
	@<Write rels lookup list@>;

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
	Produce::up(Emit::tree());

@<The LIST task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, X_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLIST_ALL_X_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			int t = 0;
			@<Write rels lookup list all@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, Y_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLIST_ALL_Y_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					t = 1;
					@<Write rels lookup list all@>;
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, X_s);
	Produce::up(Emit::tree());

@<Write rels lookup@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Kinds::Behaviour::compile_domain_possible(K)) {
		i6_schema loop_schema;
		if (Calculus::Deferrals::write_loop_schema(&loop_schema, K)) {
			Calculus::Schemas::emit_expand_from_locals(&loop_schema, Z1_lv, Z2_lv, TRUE);
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::handler_iname(dbp));
							Produce::val_symbol(Emit::tree(), K_value, rr_s);
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
								Produce::val_symbol(Emit::tree(), K_value, X_s);
							} else {
								Produce::val_symbol(Emit::tree(), K_value, X_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							}
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, Y_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::rtrue(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());

							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, Y_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::rtrue(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());

							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rfalse(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rfalse(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	if (K == NULL) Produce::rfalse(Emit::tree());
	else {
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DEFAULTVALUEOFKOV_HL));
			Produce::down(Emit::tree());
				Kinds::RunTime::emit_strong_id_as_val(K);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

@<Write rels lookup list@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Kinds::Behaviour::compile_domain_possible(K)) {
		i6_schema loop_schema;
		if (Calculus::Deferrals::write_loop_schema(&loop_schema, K)) {
			Calculus::Schemas::emit_expand_from_locals(&loop_schema, Z1_lv, Z2_lv, TRUE);
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::handler_iname(dbp));
							Produce::val_symbol(Emit::tree(), K_value, rr_s);
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
								Produce::val_symbol(Emit::tree(), K_value, X_s);
							} else {
								Produce::val_symbol(Emit::tree(), K_value, X_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							}
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, Y_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@<Write rels lookup list all@> =
	kind *KL = BinaryPredicates::term_kind(dbp, 0);
	kind *KR = BinaryPredicates::term_kind(dbp, 1);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (KL == NULL)) KL = K_object;
	if ((dbp == R_containment) && (KR == NULL)) KR = K_object;
	#endif
	if ((Kinds::Behaviour::compile_domain_possible(KL)) && (Kinds::Behaviour::compile_domain_possible(KL))) {
		i6_schema loop_schema_L, loop_schema_R;
		if ((Calculus::Deferrals::write_loop_schema(&loop_schema_L, KL)) &&
			(Calculus::Deferrals::write_loop_schema(&loop_schema_R, KR))) {
			Calculus::Schemas::emit_expand_from_locals(&loop_schema_L, Z1_lv, Z2_lv, TRUE);
					Calculus::Schemas::emit_expand_from_locals(&loop_schema_R, Z3_lv, Z4_lv, TRUE);

							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
								Produce::down(Emit::tree());
									Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::handler_iname(dbp));
									Produce::val_symbol(Emit::tree(), K_value, rr_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
									Produce::val_symbol(Emit::tree(), K_value, Z1_s);
									Produce::val_symbol(Emit::tree(), K_value, Z3_s);
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
									Produce::down(Emit::tree());
										if (t == 0) {
											Produce::val_symbol(Emit::tree(), K_value, X_s);
											Produce::val_symbol(Emit::tree(), K_value, Z1_s);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
										} else {
											Produce::val_symbol(Emit::tree(), K_value, X_s);
											Produce::val_symbol(Emit::tree(), K_value, Z3_s);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
										}
									Produce::up(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@ And now a variation for default values: for example, an anonymous relation
between numbers and texts.

=
void Relations::compile_default_relation(inter_name *identifier, kind *K) {
	packaging_state save = Emit::named_array_begin(identifier, K_value);
	Kinds::RunTime::emit_block_value_header(K, FALSE, 8);
	Emit::array_null_entry();
	Emit::array_null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "default value of "); Kinds::Textual::write(DVT, K);
	Emit::array_text_entry(DVT);
	Emit::array_iname_entry(TTF_iname);
	Emit::array_numeric_entry(0);
	Kinds::RunTime::emit_strong_id(K);
	Emit::array_iname_entry(Hierarchy::find(EMPTYRELATIONHANDLER_HL));
	Emit::array_text_entry(DVT);
	DISCARD_TEXT(DVT)
	Emit::array_end(save);
}

void Relations::compile_blank_relation(kind *K) {
	Kinds::RunTime::emit_block_value_header(K, FALSE, 34);
	Emit::array_null_entry();
	Emit::array_null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "anonymous "); Kinds::Textual::write(DVT, K);
	Emit::array_text_entry(DVT);
	DISCARD_TEXT(DVT)

	Emit::array_iname_entry(TTF_iname);
	Emit::array_numeric_entry(7);
	Kinds::RunTime::emit_strong_id(K);
	kind *EK = Kinds::unary_construction_material(K);
	if (Kinds::Behaviour::uses_pointer_values(EK))
		Emit::array_iname_entry(Hierarchy::find(HASHLISTRELATIONHANDLER_HL));
	else
		Emit::array_iname_entry(Hierarchy::find(DOUBLEHASHSETRELATIONHANDLER_HL));

	Emit::array_text_entry(I"an anonymous relation");

	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	for (int i=0; i<24; i++) Emit::array_numeric_entry(0);
}

@h Support for the RELATIONS command.

=
void Relations::IterateRelations(void) {
	inter_name *iname = Hierarchy::find(ITERATERELATIONS_HL);
	packaging_state save = Routines::begin(iname);
	inter_symbol *callback_s = LocalVariables::add_named_call_as_symbol(I"callback");
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if (bp->record_needed) {
			Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, callback_s);
				Produce::val_iname(Emit::tree(), K_value, BinaryPredicates::iname(bp));
			Produce::up(Emit::tree());
		}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@h The bitmap for various-to-various relations.
It is unavoidable that a general V-to-V relation will take at least $LR$ bits
of storage, where $L$ is the size of the left domain and $R$ the size of the
right domain. (A symmetric V-to-V relation needs only a little over $LR/2$ bits,
though in practice we don't want the nuisance of this memory saving.) Cheaper
implementations would only be possible if we could guarantee that the relation
would have some regularity, or would be sparse, but we can't guarantee any
of that. Our strategy will therefore be to store these $LR$ bits in the most
direct way possible, with as little overhead as possible: in a bitmap.

@ The following code compiles a stream of bits into a sequence of 16-bit
I6 constants written in hexadecimal, padding out with 0s to fill any incomplete
word left at the end. The first bit of the stream becomes the least significant
bit of the first word of the output.

=
int word_compiled = 0, bit_counter = 0, words_compiled;

void Relations::begin_bit_stream(void) {
	word_compiled = 0; bit_counter = 0; words_compiled = 0;
}

void Relations::compile_bit(int b) {
	word_compiled += (b << bit_counter);
	bit_counter++;
	if (bit_counter == 16) {
		Emit::array_numeric_entry((inter_ti) word_compiled);
		words_compiled++;
		word_compiled = 0; bit_counter = 0;
	}
}

void Relations::end_bit_stream(void) {
	while (bit_counter != 0) Relations::compile_bit(0);
}

@ As was implied above, the run-time storage for a various to various relation
whose BP has allocation ID number |X| is an I6 word array called |V2V_Bitmap_X|.
This begins with a header of 8 words and is then followed by a bitmap.

=
void Relations::compile_vtov_storage(binary_predicate *bp) {
	int left_count = 0, right_count = 0, words_used = 0, bytes_used = 0;
	Relations::allocate_index_storage();
	@<Index the left and right domains and calculate their sizes@>;

	inter_name *v2v_iname = NULL;
	if ((left_count > 0) && (right_count > 0))
		@<Allocate a zeroed-out memory cache for relations with fast route-finding@>;

	package_request *P = BinaryPredicates::package(bp);
	bp->v2v_bitmap_iname = Hierarchy::make_iname_in(BITMAP_HL, P);
	packaging_state save = Emit::named_array_begin(bp->v2v_bitmap_iname, K_value);
	@<Compile header information in the V-to-V structure@>;

	if ((left_count > 0) && (right_count > 0))
		@<Compile bitmap pre-initialised to the V-to-V relation at start of play@>;

	Emit::array_end(save);

	Relations::free_index_storage();
}

@ We calculate numbers $L$ and $R$, and index the items being related, so that
the possible left values are indexed $0, 1, 2, ..., L-1$ and the possible
right values $0, 1, 2, ..., R-1$. Note that in a relation such as

>> Roominess relates various things to various containers.

the same object (if a container) might be in both the left and right domains,
and be indexed differently on each side: it might be thing number 11 but
container number 6, for instance.

$L$ and $R$ are stored in the variables |left_count| and |right_count|. If
the left domain contains objects, the index of a member |I| is stored in
RI 0; if the right domain does, then in RI 1. If the domain set is an
enumerated kind of value, no index needs to be stored, because the values
are already enumerated $1, 2, 3, ..., N$ for some $N$. The actual work in
this is done by the routine |Relations::relation_range| (below).

@<Index the left and right domains and calculate their sizes@> =
	left_count = Relations::relation_range(bp, 0);
	right_count = Relations::relation_range(bp, 1);

@ See "Relations.i6t" in the template layer for details.

@<Compile header information in the V-to-V structure@> =
	kind *left_kind = BinaryPredicates::term_kind(bp, 0);
	kind *right_kind = BinaryPredicates::term_kind(bp, 1);

	if ((Kinds::Compare::lt(left_kind, K_object)) && (left_count > 0)) {
		Emit::array_iname_entry(PL::Counting::instance_count_property_symbol(left_kind));
	} else Emit::array_numeric_entry(0);
	if ((Kinds::Compare::lt(right_kind, K_object)) && (right_count > 0)) {
		Emit::array_iname_entry(PL::Counting::instance_count_property_symbol(right_kind));
	} else Emit::array_numeric_entry(0);

	Emit::array_numeric_entry((inter_ti) left_count);
	Emit::array_numeric_entry((inter_ti) right_count);
	Emit::array_iname_entry(Kinds::Behaviour::get_iname(left_kind));
	Emit::array_iname_entry(Kinds::Behaviour::get_iname(right_kind));

	Emit::array_numeric_entry(1); /* Cache broken flag */
	if ((left_count > 0) && (right_count > 0))
		Emit::array_iname_entry(v2v_iname);
	else
		Emit::array_numeric_entry(0);
	words_used += 8;

@ Fast route finding is available only where the left and right domains are
equal, and even then, only when the user asked for it. If so, we allocate
$LR$ bytes as a cache if $L=R<256$, and $LR$ words otherwise. The cache
is initialised to all-zeros, which saves an inordinate amount of nuisance,
and this is why the "cache broken" flag is initially set in the header
above: it forces the template layer to generate the cache when first used.

@<Allocate a zeroed-out memory cache for relations with fast route-finding@> =
	package_request *P = BinaryPredicates::package(bp);
	inter_name *iname = Hierarchy::make_iname_in(ROUTE_CACHE_HL, P);
	kind *left_kind = BinaryPredicates::term_kind(bp, 0);
	kind *right_kind = BinaryPredicates::term_kind(bp, 1);
	if ((bp->fast_route_finding) &&
		(Kinds::Compare::eq(left_kind, right_kind)) &&
		(Kinds::Compare::lt(left_kind, K_object)) &&
		(left_count == right_count)) {
		if (left_count < 256) {
			v2v_iname = iname;
			packaging_state save = Emit::named_byte_array_begin(iname, K_number);
			Emit::array_numeric_entry((inter_ti) (2*left_count*left_count));
			Emit::array_end(save);
			bytes_used += 2*left_count*left_count;
		} else {
			v2v_iname = iname;
			packaging_state save = Emit::named_array_begin(iname, K_number);
			Emit::array_numeric_entry((inter_ti) (2*left_count*left_count));
			Emit::array_end(save);
			words_used += 2*left_count*left_count;
		}
	} else {
		v2v_iname = Emit::named_numeric_constant(iname, 0);
	}

@ The following routine conveniently determines whether a given INFS is
within the domain of one of the terms of a relation; the rule is that it
mustn't itself express a domain (otherwise, e.g., the kind "woman" would
show up as within the domain of "person" -- we want only instances here,
not kinds); and that it must inherit from the domain of the term.

=
int Relations::infs_in_domain(inference_subject *infs, binary_predicate *bp, int index) {
	if (InferenceSubjects::domain(infs) != NULL) return FALSE;
	kind *K = BinaryPredicates::term_kind(bp, index);
	if (K == NULL) return FALSE;
	inference_subject *domain_infs = Kinds::Knowledge::as_subject(K);
	if (InferenceSubjects::is_strictly_within(infs, domain_infs)) return TRUE;
	return FALSE;
}

@ Now to assemble the bitmap. We do this by looking at inferences in the world-model
to find out what pairs $(x, y)$ are such that assertions have declared that
$B(x, y)$ is true.

It would be convenient if the inferences could feed us the necessary
information in exactly the right order, but life is not that kind. On the
other hand it would be quicker and easier if we built the entire bitmap in
memory, so that it could send the pairs $(x, y)$ in any order at all, but
that's a little wasteful. We compromise and build the bitmap one row at a
time, requiring us to store a whole row, but allowing the world-model code
to send the pairs in that row in any order.

@<Compile bitmap pre-initialised to the V-to-V relation at start of play@> =
	char *row_flags = Memory::malloc(right_count, RELATION_CONSTRUCTION_MREASON);
	if (row_flags) {
		Relations::begin_bit_stream();

		inference_subject *infs;
		LOOP_OVER(infs, inference_subject)
			if (Relations::infs_in_domain(infs, bp, 0)) {
				int j;
				for (j=0; j<right_count; j++) row_flags[j] = 0;
				@<Find all pairs belonging to this row, and set the relevant flags@>;
				for (j=0; j<right_count; j++) Relations::compile_bit(row_flags[j]);
			}

		Relations::end_bit_stream();
		words_used += words_compiled;
		Memory::I7_free(row_flags, RELATION_CONSTRUCTION_MREASON, right_count);
	}

@<Find all pairs belonging to this row, and set the relevant flags@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
		inference_subject *left_infs, *right_infs;
		World::Inferences::get_references(inf, &left_infs, &right_infs);
		if (infs == left_infs) row_flags[Relations::get_relation_index(right_infs, 1)] = 1;
	}

@ Lastly on this: the way we count and index the left (|index=0|) or right (1)
domain. We count upwards from 0 (in order of creation).

=
int Relations::relation_range(binary_predicate *bp, int index) {
	int t = 0;
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		if (Relations::infs_in_domain(infs, bp, index)) Relations::set_relation_index(infs, index, t++);
		else Relations::set_relation_index(infs, index, -1);
	}
	return t;
}

@ Tiresomely, we have to store these indices for a little while, so:

=
int *relation_indices = NULL;
void Relations::allocate_index_storage(void) {
	int nc = NUMBER_CREATED(inference_subject);
	relation_indices = (int *) (Memory::calloc(nc, 2*sizeof(int), OBJECT_COMPILATION_MREASON));
}

void Relations::set_relation_index(inference_subject *infs, int i, int v) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	relation_indices[2*(infs->allocation_id) + i] = v;
}

int Relations::get_relation_index(inference_subject *infs, int i) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	return relation_indices[2*(infs->allocation_id) + i];
}

void Relations::free_index_storage(void) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	int nc = NUMBER_CREATED(inference_subject);
	Memory::I7_array_free(relation_indices, OBJECT_COMPILATION_MREASON, nc, 2*sizeof(int));
	relation_indices = NULL;
}

@h The partition for an equivalence relation.
An equivalence relation $E$ is such that $E(x, x)$ for all $x$, such that
$E(x, y)$ if and only if $E(y, x)$, and such that $E(x, y)$ and $E(y, z)$
together imply $E(x, z)$: the properties of being reflexive, symmetric
and transitive. The relation constructed by a sentence like

>> Alliance relates people to each other in groups.

is to be an equivalence relation. This means we need to ensure first that
the original state of the relation, resulting from assertions such as...

>>  The verb to be allied to implies the alliance relation. Louis is allied to Otto. Otto is allied to Helene.

...satisfies the reflexive, symmetric and transitive properties; and then
also that these properties are maintained at run-time when the situation
changes as a result of executing phrases such as

>> now Louis is allied to Gustav;

We use the same solution both in the compiler and at run-time, which is to
exploit an elementary theorem about ERs. Let $E$ be an equivalence relation
on the members of a set $S$ (say, the set of people in Central Europe).
Then there is a unique way to divide up $S$ into a "partition" of subsets
called "equivalence classes" such that:

(a) every member of $S$ is in exactly one of the classes,
(b) none of the classes is empty, and
(c) $E(x, y)$ is true if and only if $x$ and $y$ belong to the same class.

Conversely, given any partition of $S$ (i.e., satisfying (a) and (b)),
there is a unique equivalence relation $E$ such that (c) is true. In short:
possible states of an equivalence relation on a set correspond exactly to
possible ways to divide it up into non-empty, non-overlapping pieces.

We therefore store the current state not as some list of which pairs $(x, y)$
for which $E(x, y)$ is true, but instead as a partition of the set $S$. We
store this as a function $p:S\rightarrow \lbrace 1, 2, 3, ...\rbrace$ such
that $x$ and $y$ belong in the same class -- or to put it another way, such
that $E(x, y)$ is true -- if and only if $p(x) = p(y)$. When we are assembling
the initial state, the function $p$ is an array of integers whose address is
stored in the |bp->equivalence_partition| field of the BP structure. It is
then compiled into the storage properties of the I6 objects concerned. For
instance, if we have |p44_alliance| as the storage property for the "alliance"
relation, then |O31_Louis.p44_alliance| and |O32_Otto.p44_alliance| will be
set to the same partition number. The template routines which set and remove
alliance then maintain the collective values of the |p44_alliance| property,
keeping it always a valid partition function for the relation.

@ We calculate the initial partition by starting with the sparsest possible
equivalence relation, $E(x, y)$ if and only if $x=y$, where each member is
related only to itself. (This is the equality relation.) The partition
function here is given by $p(x)$ equals the allocation ID number for object
$x$, plus 1. Since all objects have distinct IDs, $p(x)=p(y)$ if and only
if $x=y$, which is what we want. But note that the objects in $S$ may well
not have contiguous ID numbers. This doesn't matter to us, but it means $p$
may look less tidy than we expect.

For instance, suppose there are five people: Sophie, Ryan, Daisy, Owen and
the player, with a "helping" equivalence relation. We might then generate
the initial partition:
$$ p(P) = 12, p(S) = 23, p(R) = 25, p(D) = 26, p(O) = 31. $$

=
void Relations::equivalence_relation_make_singleton_partitions(binary_predicate *bp,
	int domain_size) {
	int i;
	int *partition_array = Memory::calloc(domain_size, sizeof(int), PARTITION_MREASON);
	for (i=0; i<domain_size; i++) partition_array[i] = i+1;
	bp->equivalence_partition = partition_array;
}

@ The A-parser has meanwhile been reading in facts about the helping relation:

>> Sophie helps Ryan. Daisy helps Ryan. Owen helps the player.

And it feeds these facts to us one at a time. It tells us that $A(S, R)$
has to be true by calling the routine below for the helping relation with
the ID numbers of Sophie and Ryan as arguments. Sophie is currently in
class number 23, Ryan in class 25. We merge these two classes so that
anybody whose class number is 25 is moved down to have class number 23, and
so:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 26, p(O) = 31. $$
Similarly we now merge Daisy's class with Ryan's:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 23, p(O) = 31. $$
And Owen's with the player's:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 23, p(O) = 12. $$
This leaves us with the final partition where the two equivalence classes are
$$ \lbrace {\rm player}, {\rm Owen} \rbrace\quad \lbrace {\rm Sophie},
{\rm Daisy}, {\rm Ryan}\rbrace. $$
As mentioned above, it might seem "tidy" to renumber these classes 1 and 2
rather than 12 and 23, but there's really no need and we don't bother.

Note that the A-parser does not allow negative assertions about equivalence
relations to be made:

>> Daisy does not help Ryan.

While we could try to accommodate this (using the same method we use at
run-time to handle "now Daisy does not help Ryan"), it would only invite
users to set up these relations in a stylistically poor way.

=
void Relations::equivalence_relation_merge_classes(binary_predicate *bp,
	int domain_size, int ix1, int ix2) {
	if (bp->form_of_relation != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	int *partition_array = bp->equivalence_partition;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	int little, big; /* or, The Fairies' Parliament */
	big = partition_array[ix1]; little = partition_array[ix2];
	if (big == little) return;
	if (big < little) { int swap = little; little = big; big = swap; }
	int i;
	for (i=0; i<domain_size; i++)
		if (partition_array[i] == big)
			partition_array[i] = little;
}

@ Once that process has completed, the code which compiles the
initial state of the I6 object tree calls the following routine to ask it
to fill in the (let's say) |p63_helping| property for each person
in turn.

=
void Relations::equivalence_relation_add_properties(binary_predicate *bp) {
	kind *k = BinaryPredicates::term_kind(bp, 1);
	if (Kinds::Compare::le(k, K_object)) {
		instance *I;
		LOOP_OVER_INSTANCES(I, k) {
			inference_subject *infs = Instances::as_subject(I);
			@<Set the partition number property@>;
		}
	} else {
		instance *nc;
		LOOP_OVER_INSTANCES(nc, k) {
			inference_subject *infs = Instances::as_subject(nc);
			@<Set the partition number property@>;
		}
	}
}

@<Set the partition number property@> =
	parse_node *val = Rvalues::from_int(
		Relations::equivalence_relation_get_class(bp, infs->allocation_id), EMPTY_WORDING);
	Properties::Valued::assert(bp->i6_storage_property, infs, val, CERTAIN_CE);

@ Where:

=
int Relations::equivalence_relation_get_class(binary_predicate *bp, int ix) {
	if (bp->form_of_relation != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	int *partition_array = bp->equivalence_partition;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	return partition_array[ix];
}

@h Checking correctness of 1-to-1 relations.
We now check 1-to-1 relations to see if the initial conditions have
violated the 1-to-1-ness. Because of the way these relations are implemented
using a property, it seems in fact to be impossible to violate the left-hand
count -- a contradiction problem is reported when the inference was generated.
But in case the implementation is ever changed, it seems prudent to leave this
checking in.

=
void Relations::check_OtoO_relation(binary_predicate *bp) {
	int nc = NUMBER_CREATED(inference_subject);
	int *right_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **right_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **right_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));

	property *prn = BinaryPredicates::get_i6_storage_property(bp);

	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) right_counts[infs->allocation_id] = 0;
	LOOP_OVER(infs, inference_subject) {
		inference *inf1 = NULL;
		int leftc = 0;
		inference *inf;
		KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
			if ((World::Inferences::get_property(inf) == prn) &&
				(World::Inferences::get_certainty(inf) == CERTAIN_CE)) {
				parse_node *val = World::Inferences::get_property_value(inf);
				inference_subject *infs2 = InferenceSubjects::from_specification(val);
				leftc++;
				if (infs2) {
					int m = right_counts[infs2->allocation_id]++;
					if (m == 0) right_first[infs2->allocation_id] = inf;
					if (m == 1) right_second[infs2->allocation_id] = inf;
				}
				if (leftc == 1) inf1 = inf;
				if (leftc == 2) {
					StandardProblems::infs_contradiction_problem(_p_(BelievedImpossible),
						World::Inferences::where_inferred(inf1), World::Inferences::where_inferred(inf),
						infs, "can only relate to one other thing in this way",
						"since the relation in question is one-to-one.");
				}
			}
		}
	}
	LOOP_OVER(infs, inference_subject) {
		if (right_counts[infs->allocation_id] >= 2) {
			StandardProblems::infs_contradiction_problem(_p_(PM_Relation1to1Right),
				World::Inferences::where_inferred(right_first[infs->allocation_id]),
				World::Inferences::where_inferred(right_second[infs->allocation_id]),
				infs, "can only relate to one other thing in this way",
				"since the relation in question is one-to-one.");
		}
	}

	Memory::I7_array_free(right_second, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
	Memory::I7_array_free(right_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
}

void Relations::check_OtoV_relation(binary_predicate *bp) {
	int nc = NUMBER_CREATED(inference_subject);
	int *right_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **right_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **right_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	int *left_counts = (int *)
		(Memory::calloc(nc, sizeof(int), OBJECT_COMPILATION_MREASON));
	inference **left_first = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));
	inference **left_second = (inference **)
		(Memory::calloc(nc, sizeof(inference *), OBJECT_COMPILATION_MREASON));

	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) right_counts[infs->allocation_id] = 0;

	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
		parse_node *left_val = NULL;
		parse_node *right_val = NULL;
		World::Inferences::get_references_spec(inf, &left_val, &right_val);
		inference_subject *left_infs = InferenceSubjects::from_specification(left_val);
		inference_subject *right_infs = InferenceSubjects::from_specification(right_val);
		int left_id = (left_infs)?(left_infs->allocation_id):(-1);
		int right_id = (right_infs)?(right_infs->allocation_id):(-1);

		if (left_id >= 0) {
			int m = left_counts[left_id]++;
			if (m == 0) left_first[left_id] = inf;
			if (m == 1) left_second[left_id] = inf;
		}

		if (right_id >= 0) {
			int m = right_counts[right_id]++;
			if (m == 0) right_first[right_id] = inf;
			if (m == 1) right_second[right_id] = inf;
		}
	}

	if (bp->form_of_relation == Relation_VtoO) {
		LOOP_OVER(infs, inference_subject) {
			if (left_counts[infs->allocation_id] >= 2) {
				StandardProblems::infs_contradiction_problem(_p_(PM_RelationVtoOContradiction),
					World::Inferences::where_inferred(left_first[infs->allocation_id]),
					World::Inferences::where_inferred(left_second[infs->allocation_id]),
					infs, "can only relate to one other thing in this way",
					"since the relation in question is various-to-one.");
			}
		}
	} else {
		LOOP_OVER(infs, inference_subject) {
			if (right_counts[infs->allocation_id] >= 2) {
				StandardProblems::infs_contradiction_problem(_p_(PM_RelationOtoVContradiction),
					World::Inferences::where_inferred(right_first[infs->allocation_id]),
					World::Inferences::where_inferred(right_second[infs->allocation_id]),
					infs, "can only be related to by one other thing in this way",
					"since the relation in question is one-to-various.");
			}
		}
	}

	Memory::I7_array_free(right_second, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(right_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
	Memory::I7_array_free(left_second, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(left_first, OBJECT_COMPILATION_MREASON, nc, sizeof(inference *));
	Memory::I7_array_free(left_counts, OBJECT_COMPILATION_MREASON, nc, sizeof(int));
}

@h Generating routines to test relations by condition.
When a relation has to be tested as a condition, we can't simply embed that
condition as the I6 schema for "test relation": it might very well need
local variables, the table row-choosing variables, etc., to evaluate. It
has to be tested in its own context. So we generate a routine called
|Relation_X|, where |X| is the allocation ID number of the BP, which takes
two parameters |t_0| and |t_1| and returns true or false according to
whether or not $R(|t_0|, |t_1|)$.

This is where those routines are compiled.

=
void Relations::compile_defined_relations(void) {
	Relations::compile_relation_records();
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if ((bp->form_of_relation == Relation_ByRoutine) && (bp->right_way_round)) {
			current_sentence = bp->bp_created_at;
			TEMPORARY_TEXT(C)
			WRITE_TO(C, "Routine to decide if %S(t_0, t_1)", BinaryPredicates::get_log_name(bp));
			Produce::comment(Emit::tree(), C);
			DISCARD_TEXT(C)
			Relations::compile_routine_to_decide(bp->bp_by_routine_iname,
				bp->condition_defn_text, bp->term_details[0], bp->term_details[1]);
		}
	@<Compile RProperty routine@>;

	relation_guard *rg;
	LOOP_OVER(rg, relation_guard) {
		@<Compile RGuard f0 routine@>;
		@<Compile RGuard f1 routine@>;
		@<Compile RGuard T routine@>;
		@<Compile RGuard MT routine@>;
		@<Compile RGuard MF routine@>;
	}
}

@<Compile RProperty routine@> =
	packaging_state save = Routines::begin(Hierarchy::find(RPROPERTY_HL));
	inter_symbol *obj_s = LocalVariables::add_named_call_as_symbol(I"obj");
	inter_symbol *cl_s = LocalVariables::add_named_call_as_symbol(I"cl");
	inter_symbol *pr_s = LocalVariables::add_named_call_as_symbol(I"pr");

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, obj_s);
			Produce::val_symbol(Emit::tree(), K_value, cl_s);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, obj_s);
					Produce::val_symbol(Emit::tree(), K_value, pr_s);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_nothing(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);

@<Compile RGuard f0 routine@> =
	if (rg->guard_f0_iname) {
		packaging_state save = Routines::begin(rg->guard_f0_iname);
		local_variable *X_lv = NULL;
		inter_symbol *X_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"X", "which is related to at most one object", &X_lv);
		if (rg->f0) {
			if (rg->check_R) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
			Calculus::Schemas::emit_val_expand_from_locals(rg->f0, X_lv, X_lv);
			Produce::up(Emit::tree());
			if (rg->check_R) {
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_nothing(Emit::tree());
				Produce::up(Emit::tree());
			}
		} else {
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard f1 routine@> =
	if (rg->guard_f1_iname) {
		packaging_state save = Routines::begin(rg->guard_f1_iname);
		local_variable *X_lv = NULL;
		inter_symbol *X_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"X", "which is related to at most one object", &X_lv);
		if (rg->f1) {
			if (rg->check_L) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
			Calculus::Schemas::emit_val_expand_from_locals(rg->f1, X_lv, X_lv);
			Produce::up(Emit::tree());
			if (rg->check_L) {
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_nothing(Emit::tree());
				Produce::up(Emit::tree());
			}
		} else {
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard T routine@> =
	if (rg->guard_test_iname) {
		packaging_state save = Routines::begin(rg->guard_test_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_test) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());

				int downs = 0;
				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, L_s);
							Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
						Produce::up(Emit::tree());
					downs++;
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, R_s);
							Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
						Produce::up(Emit::tree());
					downs++;
				}
				Calculus::Schemas::emit_val_expand_from_locals(rg->inner_test, L_lv, R_lv);
				for (int i=0; i<downs; i++) Produce::up(Emit::tree());

				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

		}
		Produce::rfalse(Emit::tree());
		Routines::end(save);
	}

@<Compile RGuard MT routine@> =
	if (rg->guard_make_true_iname) {
		packaging_state save = Routines::begin(rg->guard_make_true_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_make_true) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());

				if ((rg->check_L) && (rg->check_R)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
					downs = 2;
				}

				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, L_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, R_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
				}
				for (int i=0; i<downs-1; i++) Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
			}

			Calculus::Schemas::emit_expand_from_locals(rg->inner_make_true, L_lv, R_lv, TRUE);
			Produce::rtrue(Emit::tree());

			if (downs > 0) { Produce::up(Emit::tree()); Produce::up(Emit::tree()); }

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				Produce::val_symbol(Emit::tree(), K_value, L_s);
				Produce::val_symbol(Emit::tree(), K_value, R_s);
				Produce::val_iname(Emit::tree(), K_value, rg->guarding->bp_iname);
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard MF routine@> =
	if (rg->guard_make_false_iname) {
		packaging_state save = Routines::begin(rg->guard_make_false_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_make_false) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());

				if ((rg->check_L) && (rg->check_R)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
					downs = 2;
				}

				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, L_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, R_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
				}
				for (int i=0; i<downs-1; i++) Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
			}

			Calculus::Schemas::emit_expand_from_locals(rg->inner_make_false, L_lv, R_lv, TRUE);
			Produce::rtrue(Emit::tree());

			if (downs > 0) { Produce::up(Emit::tree()); Produce::up(Emit::tree()); }

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				Produce::val_symbol(Emit::tree(), K_value, L_s);
				Produce::val_symbol(Emit::tree(), K_value, R_s);
				Produce::val_iname(Emit::tree(), K_value, rg->guarding->bp_iname);
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@ =
void Relations::compile_routine_to_decide(inter_name *rname,
	wording W, bp_term_details par1, bp_term_details par2) {

	packaging_state save = Routines::begin(rname);

	ph_stack_frame *phsf = Frames::current_stack_frame();
	BinaryPredicates::add_term_as_call_parameter(phsf, par1);
	BinaryPredicates::add_term_as_call_parameter(phsf, par2);

	LocalVariables::enable_possessive_form_of_it();

	parse_node *spec = NULL;
	if (<s-condition>(W)) spec = <<rp>>;
	if ((spec == NULL) || (Dash::validate_conditional_clause(spec) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRelationCondition),
			"the condition defining this relation makes no sense to me",
			"although the definition was properly formed - it is only "
			"the part after 'when' which I can't follow.");
	} else {
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_value, spec);
		Produce::up(Emit::tree());
	}

	Routines::end(save);
}

@h Indexing relations.
A brief table of relations appears on the Phrasebook Index page.

=
void Relations::index_table(OUTPUT_STREAM) {
	binary_predicate *bp;
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0); WRITE("<i>name</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>category</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>relates this...</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>...to this</i>");
	HTML::end_html_row(OUT);
	LOOP_OVER(bp, binary_predicate)
		if (bp->right_way_round) {
			char *type = NULL, *left = NULL, *right = NULL;
			switch (bp->relation_family) {
				case EQUALITY_KBP: type = "equality"; left = "<i>any</i>"; right = left; break;
				case QUASINUMERIC_KBP: type = "numeric"; break;
				case SPATIAL_KBP: type = "spatial"; break;
				case MAP_CONNECTING_KBP: type = "map"; left = "room/door"; right = left; break;
				case PROVISION_KBP: type = "provision"; left = "<i>any</i>"; right = "property"; break;
				case EXPLICIT_KBP:
					switch (bp->form_of_relation) {
						case Relation_OtoO: type = "one-to-one"; break;
						case Relation_OtoV: type = "one-to-various"; break;
						case Relation_VtoO: type = "various-to-one"; break;
						case Relation_VtoV: type = "various-to-various"; break;
						case Relation_Sym_OtoO: type = "one-to-another"; break;
						case Relation_Sym_VtoV: type = "various-to-each-other"; break;
						case Relation_Equiv: type = "in groups"; break;
						case Relation_ByRoutine: type = "defined"; break;
					}
					break;
			}
			if ((type == NULL) || (WordAssemblages::nonempty(bp->relation_name) == FALSE)) continue;
			HTML::first_html_column(OUT, 0);
			WordAssemblages::index(OUT, &(bp->relation_name));
			if (bp->bp_created_at) Index::link(OUT, Wordings::first_wn(Node::get_text(bp->bp_created_at)));
			HTML::next_html_column(OUT, 0);
			if (type) WRITE("%s", type); else WRITE("--");
			HTML::next_html_column(OUT, 0);
			BinaryPredicates::index_term_details(OUT, &(bp->term_details[0]));
			HTML::next_html_column(OUT, 0);
			BinaryPredicates::index_term_details(OUT, &(bp->term_details[1]));
			HTML::end_html_row(OUT);
		}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@ And a briefer note still for the table of verbs.

=
void Relations::index_for_verbs(OUTPUT_STREAM, binary_predicate *bp) {
	WRITE(" ... <i>");
	if (bp == NULL) WRITE("(a meaning internal to Inform)");
	else {
		if (bp->right_way_round == FALSE) {
			bp = bp->reversal;
			WRITE("reversed ");
		}
		WordAssemblages::index(OUT, &(bp->relation_name));
	}
	WRITE("</i>");
}
