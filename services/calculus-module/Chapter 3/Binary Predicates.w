[BinaryPredicates::] Binary Predicates.

To create and manage binary predicates, which are the underlying
data structures beneath Inform's relations.

@h Introduction.
A "binary predicate" is a property $B$ such that for any combination $x$ and
$y$, and at any given moment at run-time, $B(x, y)$ is either true or false.
$x$ and $y$ are called its "terms", and are numbered 0 and 1 below.

The classic example is equality, $(x == y)$, which is true if and only if they
are the same value. But Inform has many others. In the Inform documentation,
binary predicates are called "relations". These are grouped by //bp_family//,
and the |family_specific| field of a BP holds data meaningful only to a
predicate in that family; for example, in a predicate to measure a property,
this would store the property in question and the threshold value.

The calculus module tries to be blind to the nuances of how these families
behave differently from each other, and also to the quite complicated issue
of how to compile supporting code and data structures for use at run-time.
See //runtime: Relations// for all of that.

@ Each BP has a partner which we call its "reversal".[1] If $B$ is the
original and $R$ is its reversal, then $B(x, y)$ is true if and only if
$R(y, x)$ is true. Reversals sometimes occur quite naturally in English
language. "To wear" is the reversal of "to be worn by". "Contains" is
the reversal of being "inside".

The following sentences express the same fact:
= (text as Inform 7)
The ball is inside the trophy case. The trophy case contains the ball.
=
...even though they involve different BPs:
= (text)
	inside(ball, trophy case)
	contains(trophy case, ball)
=
So for every pair of BPs $X$ and $Y$ which are each other's reversal, Inform
designates one as being "the right way round" and the other as being "the
wrong way round".[2] Whenever a sentence's meaning involves a BP which is "the
wrong way round", Inform swaps over the terms and replaces the BP by its
reversal, which is "the right way round". The above pair of sentences is
then more easily recognised as a duplicate meaning.

[1] The equality relation is the only BP which is its own reversal: "A is B"
and "B is A" are the same meaning.

[2] This is purely an implementation convenience; there's no real sense in
logic or linguistics in which either way round is better. The equality
relation is always the right way round.

@ Given any binary predicate $B$, we may wish to perform one of several
possible "tasks" ar run-time. This will require code to be generated, which
is done via a "schema". See //BinaryPredicateFamilies::get_schema//, but
by default this adopts the one given in the BP's |task_functions| field.

@ Without further ado:

=
typedef struct binary_predicate {
	struct bp_family *relation_family;
	general_pointer family_specific; /* details for particular kinds of BP */

	struct word_assemblage relation_name; /* (which might have length 0) */
	struct parse_node *bp_created_at; /* where declared in the source text */
	struct text_stream *debugging_log_name; /* used when printing propositions to the debug log */

	struct bp_term_details term_details[2]; /* 0 is the left term, 1 is the right */

	struct binary_predicate *reversal; /* see above */
	int right_way_round; /* was this BP created directly? or is it a reversal of another? */

	/* how to compile code which tests or forces this BP to be true or false: */
	struct i6_schema *task_functions[4]; /* I6 schema for tasks */
	char *loop_parent_optimisation_proviso; /* if not NULL, optimise loops using object tree */
	char *loop_parent_optimisation_ranger; /* if not NULL, routine iterating through contents */

	/* somewhere to stash what we know about these relationships: */
	TERM_DOMAIN_CALCULUS_TYPE *knowledge_about_bp; /* in Inform, this is an inference subject */

	#ifdef CORE_MODULE
	struct bp_compilation_data compilation_data;
	#endif

	CLASS_DEFINITION
} binary_predicate;

@ The //linguistics// module needs a data type for what verbs are supposed
to mean: well, |binary_predicate| is perfect for that.

@d VERB_MEANING_LINGUISTICS_TYPE struct binary_predicate
@d VERB_MEANING_REVERSAL_LINGUISTICS_CALLBACK BinaryPredicates::get_reversal
@d VERB_MEANING_EQUALITY R_equality
@d VERB_MEANING_POSSESSION a_has_b_predicate

@h Combining the terms.
For handling the terms individually, see //Binary Predicate Term Details//.

Inform makes only very sparing use of the ability to define terms which have
no kind; this deactivates certain type-checks. It almost but not quite works to
use |value| instead, and almost but not quite works to default null terms to
|value| rather than to |object|; the difficulty in that case comes with spatial
containment, i.e., "X is in Y". See the test cases |MetaRelations|,
|ContainmentScanning| and |RelevantRelations| before fooling with any of this.

=
kind *BinaryPredicates::kind(binary_predicate *bp) {
	if (bp == R_equality) return Kinds::binary_con(CON_relation, K_value, K_value);
	kind *K0 = BinaryPredicates::term_kind(bp, 0);
	kind *K1 = BinaryPredicates::term_kind(bp, 1);
	if (K0 == NULL) K0 = K_object;
	if (K1 == NULL) K1 = K_object;
	return Kinds::binary_con(CON_relation, K0, K1);
}

@ Details of the terms:

=
kind *BinaryPredicates::term_kind(binary_predicate *bp, int t) {
	if (bp == NULL) internal_error("tried to find kind of null relation");
	return BPTerms::kind(&(bp->term_details[t]));
}
i6_schema *BinaryPredicates::get_term_as_fn_of_other(binary_predicate *bp, int t) {
	if (bp == NULL) internal_error("tried to find function of null relation");
	return bp->term_details[t].function_of_other;
}

@ And as a convenience:

=
void BinaryPredicates::set_index_details(binary_predicate *bp, char *left, char *right) {
	if (left) {
		bp->term_details[0].index_term_as = left;
		bp->reversal->term_details[1].index_term_as = left;
	}
	if (right) {
		bp->term_details[1].index_term_as = right;
		bp->reversal->term_details[0].index_term_as = right;
	}
}

@h Making the equality relation.
As we shall see below, BPs are almost always created in matched pairs. There
is just one exception: equality. This is a very polymorphic relation indeed,
and its terms have a null domain to impose no restrictions at all.

=
binary_predicate *BinaryPredicates::make_equality(bp_family *family, word_assemblage WA) {
	binary_predicate *bp = BinaryPredicates::make_single(family,
		BPTerms::new(NULL), BPTerms::new(NULL),
		I"is", NULL, NULL, WA);
	bp->reversal = bp; bp->right_way_round = TRUE;
	#ifdef BINARY_PREDICATE_CREATED_CALCULUS_CALLBACK
	BINARY_PREDICATE_CREATED_CALCULUS_CALLBACK(bp, WA);
	#endif
	return bp;
}

@h Making a pair of relations.
Every other BP belongs to a matched pair, in which each is the reversal of
the other. The one which is the wrong way round is never used in compilation,
because it will long before that have been reversed, so we only fill in
details of how to compile the BP for the one which is the right way round.

=
binary_predicate *BinaryPredicates::make_pair(bp_family *family,
	bp_term_details left_term, bp_term_details right_term,
	text_stream *name, text_stream *namer,
	i6_schema *mtf, i6_schema *tf, word_assemblage source_name) {
	binary_predicate *bp, *bpr;
	TEMPORARY_TEXT(n)
	TEMPORARY_TEXT(nr)
	Str::copy(n, name);
	if (Str::len(n) == 0) WRITE_TO(n, "nameless");
	Str::copy(nr, namer);
	if (Str::len(nr) == 0) WRITE_TO(nr, "%S-r", n);

	bp  = BinaryPredicates::make_single(family, left_term, right_term, n,
		mtf, tf, source_name);
	bpr = BinaryPredicates::make_single(family, right_term, left_term, nr,
		NULL, NULL, WordAssemblages::lit_0());

	bp->reversal = bpr; bpr->reversal = bp;
	bp->right_way_round = TRUE; bpr->right_way_round = FALSE;

	if (WordAssemblages::nonempty(source_name)) {
		#ifdef BINARY_PREDICATE_CREATED_CALCULUS_CALLBACK
		BINARY_PREDICATE_CREATED_CALCULUS_CALLBACK(bp, source_name);
		#endif
	}

	return bp;
}

@h BP construction.
The following routine should only ever be called from the two above.

It looks a little asymmetric that the "make true function" schema |mtf| is an
argument here, but the "make false function" isn't; that's just because
Inform finds this convenient. A "make false" can easily be added later.

=
binary_predicate *BinaryPredicates::make_single(bp_family *family,
	bp_term_details left_term, bp_term_details right_term,
	text_stream *name, i6_schema *mtf, i6_schema *tf, word_assemblage rn) {
	binary_predicate *bp = CREATE(binary_predicate);
	bp->relation_family = family;
	bp->relation_name = rn;
	bp->bp_created_at = current_sentence;
	bp->debugging_log_name = Str::duplicate(name);

	bp->term_details[0] = left_term; bp->term_details[1] = right_term;

	/* the |reversal| and the |right_way_round| field must be set by the caller */

	/* for use in code compilation */
	bp->task_functions[0] = NULL; /* not used: there's no task 0 */
	bp->task_functions[TEST_ATOM_TASK] = tf;
	bp->task_functions[NOW_ATOM_TRUE_TASK] = mtf;
	bp->task_functions[NOW_ATOM_FALSE_TASK] = NULL;
	bp->loop_parent_optimisation_proviso = NULL;
	bp->loop_parent_optimisation_ranger = NULL;

	/* for use by the A-parser */
	#ifdef CORE_MODULE
	bp->knowledge_about_bp = RelationSubjects::new(bp);
	#endif
	#ifndef CORE_MODULE
	bp->knowledge_about_bp = NULL;
	#endif

	/* details for particular kinds of relation */
	bp->family_specific = NULL_GENERAL_POINTER;

	#ifdef CORE_MODULE
	bp->compilation_data = RTRelations::new_compilation_data(bp);
	#endif

	return bp;
}

@h BP and term logging.

=
void BinaryPredicates::log_term_details(bp_term_details *bptd, int i) {
	LOG("  function(%d): $i\n", i, bptd->function_of_other);
	if (Wordings::nonempty(bptd->called_name)) LOG("  term %d is '%W'\n", i, bptd->called_name);
	if (bptd->implies_infs) {
		wording W = TERM_DOMAIN_WORDING_FUNCTION(bptd->implies_infs);
		if (Wordings::nonempty(W)) LOG("  term %d has domain %W\n", i, W);
	}
}

void BinaryPredicates::log(binary_predicate *bp) {
	if (bp == NULL) { LOG("<null-BP>\n"); return; }
	#ifdef CORE_MODULE
	LOG("BP%d <%S> - %s way round - %s\n",
		bp->allocation_id, bp->debugging_log_name, bp->right_way_round?"right":"wrong",
		ExplicitRelations::form_to_text(bp));
	#endif
	#ifndef CORE_MODULE
	LOG("BP%d <%S> - %s way round\n",
		bp->allocation_id, bp->debugging_log_name, bp->right_way_round?"right":"wrong");
	#endif
	for (int i=0; i<2; i++) BinaryPredicates::log_term_details(&bp->term_details[i], i);
	LOG("  test: $i\n", bp->task_functions[TEST_ATOM_TASK]);
	LOG("  make true: $i\n", bp->task_functions[NOW_ATOM_TRUE_TASK]);
	LOG("  make false: $i\n", bp->task_functions[NOW_ATOM_FALSE_TASK]);
}

@h Relation names.
This is a useful little nonterminal to spot the names of relation, such as
"adjacency". (Note: not "adjacency relation".) This should only be used when
there is good reason to suspect that the word in question is the name of a
relation, so the fact that it runs relatively slowly does not matter.

=
<relation-name> internal {
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if (WordAssemblages::compare_with_wording(&(bp->relation_name), W)) {
			==> { -, bp }; return TRUE;
		}
	==> { fail nonterminal };
}

@ =
text_stream *BinaryPredicates::get_log_name(binary_predicate *bp) {
	return bp->debugging_log_name;
}

@h Miscellaneous access routines.

=
parse_node *BinaryPredicates::get_bp_created_at(binary_predicate *bp) {
	return bp->bp_created_at;
}

@ Reversing:

=
binary_predicate *BinaryPredicates::get_reversal(binary_predicate *bp) {
	if (bp == NULL) internal_error("tried to find reversal of null relation");
	return bp->reversal;
}
int BinaryPredicates::is_the_wrong_way_round(binary_predicate *bp) {
	if ((bp) && (bp->right_way_round == FALSE)) return TRUE;
	return FALSE;
}

@ For compiling code from conditions:

=
i6_schema *BinaryPredicates::get_test_function(binary_predicate *bp) {
	return bp->task_functions[TEST_ATOM_TASK];
}
int BinaryPredicates::can_be_made_true_at_runtime(binary_predicate *bp) {
	if ((bp->task_functions[NOW_ATOM_TRUE_TASK]) ||
		(bp->reversal->task_functions[NOW_ATOM_TRUE_TASK])) return TRUE;
	return FALSE;
}

@h Loop schema.
The predicate-calculus engine compiles much better loops if we can help it by
providing an I6 schema of a loop header solving the following problem:

Loop a variable $v$ (in the schema, |*1|) over all possible $x$ such that
$R(x, t)$, for some fixed $t$ (in the schema, |*2|).

If we can't do this, it will have to fall back on the brute force method of
looping over all $x$ in the left domain of $R$ and testing every possible $R(x, t)$.

=
int BinaryPredicates::write_optimised_loop_schema(i6_schema *sch, binary_predicate *bp) {
	if (bp == NULL) return FALSE;
	@<Try loop ranger optimisation@>;
	@<Try loop parent optimisation subject to a proviso@>;
	return FALSE;
}

@ Some relations $R$ provide a "ranger" routine, |R|, which is such that
|R(t)| supplies the first "child" of $t$ and |R(t, n)| supplies the next
"child" after $n$. Thus |R| iterates through some linked list of all the
objects $x$ such that $R(x, t)$.

@<Try loop ranger optimisation@> =
	if (bp->loop_parent_optimisation_ranger) {
		Calculus::Schemas::modify(sch,
			"for (*1=%s(*2): *1: *1=%s(*2,*1))",
			bp->loop_parent_optimisation_ranger,
			bp->loop_parent_optimisation_ranger);
		return TRUE;
	}

@ Other relations make use of the I6 object tree, in cases where $R(x, t)$
is true if and only if $t$ is an object which is the parent of $x$ in the
I6 object tree and some routine associated with $R$, called its
proviso |P|, is such that |P(x) == t|. For example, worn-by($x$, $t$)
is true iff $t$ is the parent of $x$ and |WearerOf(x) == t|. The proviso
ensures that we don't falsely pick up, say, items carried by $t$ which
aren't being worn, or aren't even clothing.

@<Try loop parent optimisation subject to a proviso@> =
	if (bp->loop_parent_optimisation_proviso) {
		Calculus::Schemas::modify(sch,
			"objectloop (*1 in *2) if (%s(*1)==parent(*1))",
			bp->loop_parent_optimisation_proviso);
		return TRUE;
	}
