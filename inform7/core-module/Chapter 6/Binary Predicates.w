[BinaryPredicates::] Binary Predicates.

To create and manage binary predicates, which are the underlying
data structures beneath Inform's relations.

@h Definitions.

@ A "binary predicate" (the term comes from logic) is a property $B$
such that for any combination $x$ and $y$, and at any given moment at
run-time, $B(x, y)$ is either true or false.

Examples used in Inform include equality, where $EQ(x, y)$ is true if and
only if $x = y$, and containment, where $C(x, y)$ is true if and only if the
thing $x$ is inside the room or container $y$. ($EQ$ does not change
during play, but $C$ does.) A fairly large set of binary predicates is built
into Inform, and the user is allowed to create more with sentences like

>> Lock-fitting relates one thing (called the matching key) to various things.

In the Inform documentation, binary predicates are called "relations".
The code to parse "relates" sentences and construct the binary predicate
implied can be found in the next section, "Relations.w".

Binary predicates are of central importance because they allow complex
sentences to be written which talk about more than one thing at a time,
with some connection between them. In excerpts like "an animal inside
something" or "a man who wears the top hat", the meanings of the two
connecting pieces of text -- "inside" and "who wears" -- are (pointers
to) binary predicates: the containment relation and the wearing relation.

Inform is rich in ways to create relations, and consequently the BPs are
many and varied. They turn up in one-off examples but also in whole families.
Still, despite the variation, what they share in common is greater yet,
and so a single |binary_predicate| structure is used to represent them all.

@ The values $x$ and $y$ to which a binary predicate $B$ can apply are
called its "terms". For some relations, the source text gives these
names:

>> Lock-fitting relates one thing (called the matching key) to various things.

Here the $x$ term has the name "matching key", whereas the $y$ term is
anonymous. (More often, both are anonymous.) Internally the terms are not
named but are numbered 0 and 1: so we should really write $B(x_0, x_1)$
rather than $B(x, y)$.

@ Different BPs apply to different sorts of terms: for instance, the
numerical less-than comparison applies to numbers, whereas containment
applies to things. The two terms need not have the same domain: the
"wearing" relation, as seen in

>> Harry Smythe wears the tweed waistcoat.

is a binary predicate $W(x_0, x_1)$ such that $x_0$ ranges across people
and $x_1$ ranges across things.

Inform represents this by allowing each BP to have either a
designated kind of object, or a designated kind of value, or no
restriction at all, for each term. (In practice, even the unrestricted
terms have limitations, but which are enforced by special code in the
type-checker to handle special predicates such as equality. For instance,
$EQ(x, y)$ can be tested for any values $x$ and $y$ of the same kind, so
the two terms in effect constrain each other.)

In the S-parser, type-checking is used to make sure the source text doesn't
try to test or assert $B(x, y)$ for any $x$ or $y$ which don't fit, so that

>> if 1 wears "Hello there", ...

will be rejected. Whereas in the A-parser, these restrictions are used to
infer information about otherwise unknown quantities: so writing

>> Harry Smythe wears the tweed waistcoat.

causes the A-parser to force the Harry Smythe object to be of kind
"person", and the tweed waistcoat of kind "thing".

@ Some BPs are such that $B(x, y)$ can be true for more or less any
combination of $x$ and $y$. Those can take a lot of storage and it is
difficult to perform any reasoning about them, because knowing that $B(x,
y)$ is true doesn't give you any information about $B(x, z)$. For instance,
the BP created by

>> Suspicion relates various people to various people.

is stored at run-time in a bitmap of $P^2$ bits, where $P$ is the number
of people, and searching it ("if anyone suspects Harry") requires
exhaustive loops, which incur some speed overhead as well.

But other BPs have special properties restricting the circumstances in
which they are true, and in those cases we want to capitalise on that.
"Contains" is an example of this. A single thing $y$ can be (directly)
inside only one other thing $x$ at a time, so that if we know $C(x, y)$
and $C(w, y)$ then we can deduce that $x=w$. We write this common value
as $f_0(y)$, the only possible value for term 0 given that term 1 is $y$.
Another way to say this is that the only possible pairs making $C$ true
have the form $C(f_0(y), y)$.

And similarly for term 1. If we write $T$ for the "on top of" relation
then it turns out that there is a function $f_1$ such that the only cases
where $T$ is true have the form $T(x, f_1(x))$. Here $f_1(x)$ is the thing
which directly supports $x$.

Containment has an $f_0$ but not an $f_1$ function; "on top of" has an
$f_1$ but not an $f_0$. Many BPs (like "suspicion" above) have neither.

Note that if $B$ does have an $f_0$ function then its reversal $R$ has an
identical $f_1$ function, and vice versa.

@ We never in fact need to calculate the value of $f_0(y)$ from $y$ during
compilation -- only at run-time. So we store the function $f_0(y)$ as what
is called an "I6 schema", basically a piece of I6 source code with a
place-holder where $y$ is to be inserted. In the case of containment, the
schema is written
$$ f_0(|*1|) = |ContainerOf(*1)| $$
and what this means is that we can calculate $f_0(y)$ from an object $y$
at run-time by calling the |ContainerOf| function, which tells us what
container (if any) is at present directly containing $y$.

@ To sum up, each term of a BP can specify: a name, a domain, and an
$f_i$ function. Every one of these details is optional. They are gathered
together in a sub-structure called |bp_term_details|.

=
typedef struct bp_term_details {
	struct wording called_name; /* "(called...)" name, if any exists */
	struct inference_subject *implies_infs; /* the domain of values allowed */
	struct kind *implies_kind; /* the kind of these values */
	struct i6_schema *function_of_other; /* the function $f_0$ or $f_1$ as above */
	char *index_term_as; /* usually null, but if not, used in Phrasebook index */
} bp_term_details;

@ Given any binary predicate $B$, we may wish to do some or all of the
following at run-time:

(a) Test whether or not $B(x, y)$ is true at run-time. Here Inform
needs to compile an I6 condition.

(b) Assert that $B(x, y)$ is true in the assertion sentences of
the source text. Inform will need to remember all pairs $x, y$ for which $B$
has been asserted so that it can compile this information as the original
state of the I6 data structure containing the current state of $B$.

(c) Set $B(x, y)$ true, or false, at run-time. Here Inform needs to
compile I6 code which will modify that data structure.

Some BPs provide an I6 schema to achieve (a), others provide (a) and (b),
while a happy few provide all of (a), (b), (c).

The variety of BPs is such that different BPs use very different run-time
mechanisms. Some relations compile elaborate routines to test (a), some
look at parents or chidren in the I6 object tree, some look at I6 property
values, others look inside bitmaps. The actual work is often done by routines
in the I6 template, which are called by code generated by the I6 schema for
(a); and similarly for (b) and (c).

@ Each BP has a partner which we call its "reversal". If $B$ is the
original and $R$ is its reversal, then $B(x, y)$ is true if and only if
$R(y, x)$ is true. Reversals sometimes occur quite naturally in English
language. "To wear" is the reversal of "to be worn by". "Contains" is
the reversal of being "inside". (Though not every BP has an interesting
reversal. The reversal of "is" -- equality -- looks much the same as the
original, because $x=y$ if and only if $y=x$.)

The following sentences express the same fact:

>> The ball is inside the trophy case.
>> The trophy case contains the ball.

...but when we parse them into their meanings, we could easily lose sight
that they are saying the same thing, because they involve different BPs:

	|inside(ball, trophy case)| and |contains(trophy case, ball)|

It's usually a bad idea for any computer program to represent the same
conceptual idea in more than one way. So for every pair of BPs $X$ and $Y$
which are each other's reversal, Inform designates one as being
"the right way round" and the other as being "the wrong way round".
Whenever a sentence's meaning involves a BP which is "the wrong way
round", Inform swaps over the terms and replaces the BP by its reversal,
which is "the right way round". That makes it much easier to recognise
when pairs of sentences like the one above are duplicating each other's
meanings.

This is purely an internal implementation trick. There's no natural sense
in language or mathematics in which "contains" is the right way round
and "inside" the wrong way round.

@ We can finally now declare the epic BP structure.

=
typedef struct binary_predicate {
	int relation_family; /* one of the |*_KBP| constants defined below */
	int form_of_relation; /* one of the |Relation_*| constants defined below */
	struct word_assemblage relation_name; /* (which might have length 0) */
	struct parse_node *bp_created_at; /* where declared in the source text */
	struct text_stream *debugging_log_name; /* used when printing propositions to the debug log */
	struct package_request *bp_package;
	struct inter_name *bp_iname; /* when referred to as a constant */
	struct inter_name *handler_iname;
	struct inter_name *v2v_bitmap_iname; /* only relevant for some relations */

	struct bp_term_details term_details[2]; /* term 0 is the left term, 1 is the right */

	struct binary_predicate *reversal; /* the $R$ such that $R(x,y)$ iff $B(y,x)$ */
	int right_way_round; /* was this BP created directly? or is it a reversal of another? */

	/* how to compile code which tests or forces this BP to be true or false: */
	struct inter_name *bp_by_routine_iname; /* for relations by routine */
	struct i6_schema *test_function; /* I6 schema for (a) testing $B(x, y)$... */
	struct wording condition_defn_text; /* ...unless this I7 condition is used instead */
	struct i6_schema *make_true_function; /* I6 schema for (b) "now $B(x, y)$" */
	struct i6_schema *make_false_function; /* I6 schema for (c) "now ${\rm not}(B(x, y))$" */

	/* for use in the A-parser: */
	int arbitrary; /* allow source to assert $B(x, y)$ for any arbitrary pairs $x, y$ */
	struct property *set_property; /* asserting $B(x, v)$ sets this prop. of $x$ to $v$ */
	struct wording property_pending_text; /* temp. version used until props created */
	int relates_values_not_objects; /* true if either term is necessarily a value... */
	struct inference_subject *knowledge_about_bp; /* ...and if so, here's the list of known assertions */

	/* for optimisation of run-time code: */
	int dynamic_memory; /* stored in dynamically allocated memory */
	struct inter_name *initialiser_iname; /* and if so, this is the name of its initialiser */
	struct property *i6_storage_property; /* provides run-time storage */
	struct kind *storage_kind; /* kind of property owner */
	int allow_function_simplification; /* allow Inform to make use of any $f_i$ functions? */
	int fast_route_finding; /* use fast rather than slow route-finding algorithm? */
	char *loop_parent_optimisation_proviso; /* if not NULL, optimise loops using object tree */
	char *loop_parent_optimisation_ranger; /* if not NULL, routine iterating through contents */
	int record_needed; /* we need to compile a small array of details in readable memory */

	/* details, filled in for right-way-round BPs only, for particular kinds of BP: */
	int a_listed_in_predicate; /* (if right way) was this generated from a table column? */
	struct property *same_property; /* (if right way) if a "same property as..." */
	struct property *comparative_property; /* (if right way) if a comparative adjective */
	int comparison_sign; /* ...and |+1| or |-1| according to sign of definition */
	int *equivalence_partition; /* (if right way) partition array of equivalence classes */

	MEMORY_MANAGEMENT
} binary_predicate;

@ This seems a good point to lay out a classification of all of the BPs
existing within Inform. Broadly, they divide into two: the ones explicitly
created by the source text, in sentences like

>> Admiration relates various people to various people.

These are called "explicit". The others are "implicit" and are either
created automatically soon after Inform starts up, or else are created as
a consequence of something else being created by the source text, such as

>> Definition: A woman is tall if her height is 68 or more.

which implicitly creates a "taller than" relation. All explicit BPs are
constructed in the "Relations.w" section of the source code.

@d EQUALITY_KBP 1 /* there is exactly one of these: the $x=y$ predicate */
@d QUASINUMERIC_KBP 2 /* the inequality comparison $\leq$, $<$ and so on */
@d SPATIAL_KBP 3 /* a relation associated with a map connection */
@d MAP_CONNECTING_KBP 4 /* a relation associated with a map connection */
@d PROPERTY_SETTING_KBP 5 /* a relation associated with a value property */
@d PROPERTY_SAME_KBP 6 /* another relation associated with a value property */
@d PROPERTY_COMPARISON_KBP 7 /* another relation associated with a value property */
@d LISTED_IN_KBP 8 /* a relation for indirect table lookups, one for each column name */
@d PROVISION_KBP 9 /* a relation for specifying which objects provide which properties */
@d UNIVERSAL_KBP 10 /* a relation for applying general other relations */

@d EXPLICIT_KBP 100 /* defined explicitly in the source text; the others are all implicit */

@ The following constants are used to identify the "form" of a BP (in that the
|form_of_relation| field of any BP always equals one of these and never changes).
These constant names (and values) exactly match a set of constants compiled
into every I6 program created by Inform, so they can be used freely both in
the Inform source code and also in the I6 template layer.

@d Relation_Implicit	-1 /* all implicit BPs have this form, and all others are explicit */

@d Relation_OtoO		1 /* one to one: "R relates one K to one K" */
@d Relation_OtoV		2 /* one to various: "R relates one K to various K" */
@d Relation_VtoO		3 /* various to one: "R relates various K to one K" */
@d Relation_VtoV		4 /* various to various: "R relates various K to various K" */
@d Relation_Sym_OtoO	5 /* symmetric one to one: "R relates one K to another" */
@d Relation_Sym_VtoV	6 /* symmetric various to various: "R relates K to each other" */
@d Relation_Equiv		7 /* equivalence relation: "R relates K to each other in groups" */

@d Relation_ByRoutine	8 /* relation tested by a routine: "R relates K to L when (some condition)" */

@ That completes the catalogue of the one-off cases, and we can move on
to the five families of implicit relations which correspond to other
structures in the source text.

@ The second family of implicit relations corresponds to any property which has
been given as the meaning of a verb, as in the example

>> The verb to weigh (it weighs, they weigh, it is weighing) implies the weight property.

This implicitly constructs a relation $W(p, w)$ where $p$ is a thing and
$w$ a weight.

@ The third family corresponds to defined adjectives which perform a
numerical comparison in a particular way, as here:

>> Definition: A woman is tall if her height is 68 or more.

This implicitly constructs a relation $T(x, y)$ which is true if and only
if woman $x$ is taller than woman $y$.

@ The fourth family corresponds to value properties, so that

>> A door has a number called street number.

implicitly constructs a relation $SN(d_1, d_2)$ which is true if and only if
doors $d_1$ and $d_2$ have the same street number.

@ The fifth family corresponds to names of table columns. If any table includes
a column headed "eggs per clutch" then that will implicitly construct a
relation $LEPC(n, T)$ which is true if and only if the number $n$ is listed
as one of the eggs-per-clutch entries in the table $T$, where $T$ has to be
one of the tables which has a column of this name.

@d VERB_MEANING_TYPE struct binary_predicate
@d VERB_MEANING_REVERSAL BinaryPredicates::get_reversal
@d VERB_MEANING_EQUALITY R_equality
@d VERB_MEANING_UNIVERSAL R_universal
@d VERB_MEANING_POSSESSION a_has_b_predicate

@h Creating term details.
The essential point in defining a term is to describe the domain of values it
ranges over, which we do by giving an "inference subject" (INFS). An INFS is
roughly speaking anything in the model world which Inform can store knowledge
about; here it will almost always be a generality of things, such as "all
numbers", or "all rooms".

=
bp_term_details BinaryPredicates::new_term(inference_subject *infs) {
	bp_term_details bptd;
	bptd.called_name = EMPTY_WORDING;
	bptd.function_of_other = NULL;
	bptd.implies_infs = infs;
	bptd.implies_kind = NULL;
	bptd.index_term_as = NULL;
	return bptd;
}

@ And there is also a fuller version, including the inessentials:

=
bp_term_details BinaryPredicates::full_new_term(inference_subject *infs, kind *K,
	wording CW, i6_schema *f) {
	bp_term_details bptd = BinaryPredicates::new_term(infs);
	bptd.implies_kind = K;
	bptd.called_name = CW;
	bptd.function_of_other = f;
	return bptd;
}

@ In a few cases BPs need to be created before the relevant domains are known,
so that we must fill them in later, using the following:

=
void BinaryPredicates::set_term_domain(bp_term_details *bptd, kind *K) {
	if (bptd == NULL) internal_error("no BPTD");
	bptd->implies_kind = K;
	bptd->implies_infs = Kinds::Knowledge::as_subject(K);
}

@ Similarly:

=
void BinaryPredicates::set_term_function(bp_term_details *bptd, i6_schema *f) {
	if (bptd == NULL) internal_error("no BPTD");
	bptd->function_of_other = f;
}

i6_schema *BinaryPredicates::get_term_function(bp_term_details *bptd) {
	if (bptd == NULL) internal_error("no BPTD");
	return bptd->function_of_other;
}

@ Combining these:

=
kind *BinaryPredicates::kind(binary_predicate *bp) {
	if (bp == R_equality) return Kinds::binary_construction(CON_relation, K_value, K_value);
	kind *K0 = BinaryPredicates::kind_of_term(&(bp->term_details[0]));
	kind *K1 = BinaryPredicates::kind_of_term(&(bp->term_details[1]));
	if (K0 == NULL) K0 = K_object;
	if (K1 == NULL) K1 = K_object;
	return Kinds::binary_construction(CON_relation, K0, K1);
}

@ The kind of a term is:

=
kind *BinaryPredicates::kind_of_term(bp_term_details *bptd) {
	if (bptd == NULL) return NULL;
	if (bptd->implies_kind) return bptd->implies_kind;
	return InferenceSubjects::domain(bptd->implies_infs);
}

@ The table of relations in the index uses the textual name of an INFS, so:

=
void BinaryPredicates::index_term_details(OUTPUT_STREAM, bp_term_details *bptd) {
	if (bptd->index_term_as) { WRITE("%s", bptd->index_term_as); return; }
	wording W = EMPTY_WORDING;
	if (bptd->implies_infs) W = InferenceSubjects::get_name_text(bptd->implies_infs);
	if (Wordings::nonempty(W)) WRITE("%W", W); else WRITE("--");
}

@ The following routine adds the given BP term as a call parameter to the
routine currently being compiled, deciding that something is an object if
its kind indications are all blank, but verifying that the value supplied
matches the specific necessary kind of object if there is one.

=
void BinaryPredicates::add_term_as_call_parameter(ph_stack_frame *phsf, bp_term_details bptd) {
	kind *K = BinaryPredicates::kind_of_term(&bptd);
	kind *PK = K;
	if ((PK == NULL) || (Kinds::Compare::lt(PK, K_object))) PK = K_object;
	inter_symbol *lv_s = LocalVariables::add_call_parameter_as_symbol(phsf,
		bptd.called_name, PK);
	if (Kinds::Compare::lt(K, K_object)) {
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(not_interp);
			Emit::down();
				Emit::inv_primitive(ofclass_interp);
				Emit::down();
					Emit::val_symbol(K_value, lv_s);
					Emit::val_iname(K_value, Kinds::RunTime::I6_classname(K));
				Emit::up();
			Emit::up();
			Emit::code();
			Emit::down();
				Emit::rfalse();
			Emit::up();
		Emit::up();
	}
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
is one and only one exception to this rule: the equality predicate where
$EQ(x, y)$ if $x = y$. Equality plays a special role in the system of logic
we'll be using. Since $x = y$ and $y = x$ are exactly equivalent, it is safe
to make $EQ$ its own reversal; this makes it impossible for equality to occur
"the wrong way round" in any proposition, even one which is not yet fully
simplified.

There is no fixed domain to which $x$ and $y$ belong: equality can be
used whenever $x$ and $y$ belong to the same domain. Thus "if the score is
12" and "if the location is the Pantheon" are both valid uses of $EQ$,
where $x$ and $y$ are numbers in the former case and rooms in the latter.
It will take special handling in the type-checker to achieve
this effect. For now, we give $EQ$ entirely blank term details.

=
binary_predicate *BinaryPredicates::make_equality(void) {
	binary_predicate *bp = BinaryPredicates::make_single(EQUALITY_KBP,
		BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
		I"is", NULL, NULL, NULL,
		Preform::Nonparsing::wording(<relation-names>, EQUALITY_RELATION_NAME));

	bp->reversal = bp; bp->right_way_round = TRUE;
	return bp;
}

@h Making a pair of relations.
Every other BP belongs to a matched pair, in which each is the reversal of
the other, but only one is designated as being "the right way round".
The left-hand term of one behaves like the right-hand term of the other,
and vice versa.

The BP which is the wrong way round is never used in compilation, because
it will long before that have been reversed, so we only fill in details of
how to compile the BP for the one which is the right way round.

=
binary_predicate *BinaryPredicates::make_pair(int family,
	bp_term_details left_term, bp_term_details right_term,
	text_stream *name, text_stream *namer, property *pn,
	i6_schema *mtf, i6_schema *tf, word_assemblage source_name) {
	binary_predicate *bp, *bpr;
	TEMPORARY_TEXT(n);
	TEMPORARY_TEXT(nr);
	Str::copy(n, name);
	if (Str::len(n) == 0) WRITE_TO(n, "nameless");
	Str::copy(nr, namer);
	if (Str::len(nr) == 0) WRITE_TO(nr, "%S-r", n);

	bp  = BinaryPredicates::make_single(family, left_term, right_term, n,
		pn, mtf, tf, source_name);
	bpr = BinaryPredicates::make_single(family, right_term, left_term, nr,
		NULL, NULL, NULL, WordAssemblages::lit_0());

	bp->reversal = bpr; bpr->reversal = bp;
	bp->right_way_round = TRUE; bpr->right_way_round = FALSE;

	if (WordAssemblages::nonempty(source_name)) {
		word_assemblage wa =
			Preform::Nonparsing::merge(<relation-name-formal>, 0, source_name);
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER,
			REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
			MISCELLANEOUS_MC, Rvalues::from_binary_predicate(bp));
	}

	return bp;
}

@ When the source text declares new relations, it turns out to be convenient
to make their BPs in a two-stage process: to make sketchy, mostly-blank BP
structures for them early on -- but getting their names registered -- and
then fill in the correct details later. This is where such sketchy pairs are
made:

=
binary_predicate *BinaryPredicates::make_pair_sketchily(word_assemblage wa, int f) {
	TEMPORARY_TEXT(relname);
	WRITE_TO(relname, "%V", WordAssemblages::first_word(&wa));
	binary_predicate *bp =
		BinaryPredicates::make_pair(EXPLICIT_KBP,
		BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
		relname, NULL, NULL, NULL, NULL, wa);
	DISCARD_TEXT(relname);
	bp->form_of_relation = f;
	bp->reversal->form_of_relation = f;
	return bp;
}

@h BP construction.
The following routine should only ever be called from the two above: provided
we stick to that, we ensure the golden rule that {\it every BP has a reversal
and a BP equals its reversal if and only if it is the equality relation}.

It looks a little asymmetric that the "make true function" schema |mtf| is an
argument here, but the "make false function" isn't. That's because it happens
that the implicit relations defined in this section of code generally do
support making-true, but don't support making-false, so that such an argument
would always be |NULL| in practice.

=
binary_predicate *BinaryPredicates::make_single(int family,
	bp_term_details left_term, bp_term_details right_term,
	text_stream *name, property *pn,
	i6_schema *mtf, i6_schema *tf, word_assemblage rn) {
	binary_predicate *bp = CREATE(binary_predicate);

	bp->relation_family = family;
	bp->form_of_relation = Relation_Implicit;
	bp->relation_name = rn;
	bp->bp_created_at = current_sentence;
	bp->debugging_log_name = Str::duplicate(name);
	bp->bp_package = NULL;
	bp->bp_iname = NULL;
	bp->handler_iname = NULL;
	bp->v2v_bitmap_iname = NULL;

	bp->term_details[0] = left_term; bp->term_details[1] = right_term;

	/* the |reversal| and the |right_way_round| field must be set by the caller */

	/* for use in code compilation */
	bp->bp_by_routine_iname = NULL;
	bp->test_function = tf;
	bp->condition_defn_text = EMPTY_WORDING;
	bp->make_true_function = mtf;
	bp->make_false_function = NULL;

	/* for use by the A-parser */
	bp->arbitrary = FALSE;
	bp->set_property = NULL;
	bp->property_pending_text = EMPTY_WORDING;
	bp->relates_values_not_objects = FALSE;
	bp->knowledge_about_bp =
		InferenceSubjects::new(relations,
			RELN_SUB, STORE_POINTER_binary_predicate(bp), CERTAIN_CE);

	/* for optimisation of run-time code */
	bp->dynamic_memory = FALSE;
	bp->initialiser_iname = NULL;
	bp->i6_storage_property = pn;
	bp->storage_kind = NULL;
	bp->allow_function_simplification = TRUE;
	bp->fast_route_finding = FALSE;
	bp->loop_parent_optimisation_proviso = NULL;
	bp->loop_parent_optimisation_ranger = NULL;
	bp->record_needed = FALSE;

	/* details for particular kinds of relation */
	bp->a_listed_in_predicate = FALSE;
	bp->same_property = NULL;
	bp->comparative_property = NULL;
	bp->comparison_sign = 0;
	bp->equivalence_partition = NULL;

	return bp;
}

@h The package.

=
package_request *BinaryPredicates::package(binary_predicate *bp) {
	if (bp == NULL) internal_error("null bp");
	if (bp->bp_package == NULL) {
		package_request *R = Packaging::request_resource(Modules::find(bp->bp_created_at), RELATIONS_SUBPACKAGE);
		bp->bp_package = Packaging::request(Packaging::supply_iname(R, RELATION_PR_COUNTER), R, relation_ptype);
	}
	return bp->bp_package;
}

@h The handler.

=
inter_name *BinaryPredicates::handler_iname(binary_predicate *bp) {
	if (bp->handler_iname == NULL) {
		package_request *R = BinaryPredicates::package(bp);
		bp->handler_iname = Packaging::function(InterNames::one_off(I"handler_fn", R), R, NULL);
		Inter::Symbols::set_flag(InterNames::to_symbol(bp->handler_iname), MAKE_NAME_UNIQUE);
	}
	return bp->handler_iname;
}

@h As an INFS.

=
wording BinaryPredicates::SUBJ_get_name_text(inference_subject *from) {
	return EMPTY_WORDING; /* nameless */
}

general_pointer BinaryPredicates::SUBJ_new_permission_granted(inference_subject *from) {
	return NULL_GENERAL_POINTER;
}

void BinaryPredicates::SUBJ_make_adj_const_domain(inference_subject *infs,
	instance *nc, property *prn) {
}

void BinaryPredicates::SUBJ_complete_model(inference_subject *infs) {
	int domain_size = NUMBER_CREATED(inference_subject);
	binary_predicate *bp = InferenceSubjects::as_bp(infs);

	if (BinaryPredicates::store_dynamically(bp)) return; /* handled at run-time instead */
	if ((BinaryPredicates::get_form_of_relation(bp) == Relation_Equiv) && (bp->right_way_round)) {
		Relations::equivalence_relation_make_singleton_partitions(bp, domain_size);
		inference *i;
		POSITIVE_KNOWLEDGE_LOOP(i, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
			inference_subject *infs0, *infs1;
			World::Inferences::get_references(i, &infs0, &infs1);
			Relations::equivalence_relation_merge_classes(bp, domain_size,
				infs0->allocation_id, infs1->allocation_id);
		}
		Relations::equivalence_relation_add_properties(bp);
	}
}

void BinaryPredicates::SUBJ_check_model(inference_subject *infs) {
	binary_predicate *bp = InferenceSubjects::as_bp(infs);
	if ((bp->right_way_round) &&
		((bp->form_of_relation == Relation_OtoO) ||
			(bp->form_of_relation == Relation_Sym_OtoO)))
		Relations::check_OtoO_relation(bp);
	if ((bp->right_way_round) &&
		((bp->form_of_relation == Relation_OtoV) ||
			(bp->form_of_relation == Relation_VtoO)))
		Relations::check_OtoV_relation(bp);
}

int BinaryPredicates::SUBJ_emit_element_of_condition(inference_subject *infs, inter_symbol *t0_s) {
	internal_error("BP in runtime match condition");
	return FALSE;
}

int BinaryPredicates::SUBJ_compile_all(void) {
	return FALSE;
}

void BinaryPredicates::SUBJ_compile(inference_subject *infs) {
	binary_predicate *bp = InferenceSubjects::as_bp(infs);
	if (bp->right_way_round) {
		if (BinaryPredicates::store_dynamically(bp)) {
			Routines::begin(bp->initialiser_iname);
			inference *i;
			inter_name *rtiname = InterNames::extern(RELATIONTEST_EXNAMEF);
			POSITIVE_KNOWLEDGE_LOOP(i, BinaryPredicates::as_subject(bp), ARBITRARY_RELATION_INF) {
				parse_node *spec0, *spec1;
				World::Inferences::get_references_spec(i, &spec0, &spec1);
				BinaryPredicates::mark_as_needed(bp);
				Emit::inv_call(InterNames::to_symbol(rtiname));
				Emit::down();
					Emit::val_iname(K_value, bp->bp_iname);
					Emit::val_iname(K_value, InterNames::iname(RELS_ASSERT_TRUE_INAME));
					Specifications::Compiler::emit_as_val(K_value, spec0);
					Specifications::Compiler::emit_as_val(K_value, spec1);
				Emit::up();
			}
			Routines::end();
		} else {
			if ((bp->form_of_relation == Relation_VtoV) ||
				(bp->form_of_relation == Relation_Sym_VtoV))
				Relations::compile_vtov_storage(bp);
		}
	}
}

@h BP and term logging.

=
void BinaryPredicates::log_term_details(bp_term_details *bptd, int i) {
	LOG("  function(%d): $i\n", i, bptd->function_of_other);
	if (Wordings::nonempty(bptd->called_name)) LOG("  term %d is '%W'\n", i, bptd->called_name);
	if (bptd->implies_infs) {
		wording W = InferenceSubjects::get_name_text(bptd->implies_infs);
		if (Wordings::nonempty(W)) LOG("  term %d has domain %W\n", i, W);
	}
}

void BinaryPredicates::log(binary_predicate *bp) {
	int i;
	if (bp == NULL) { LOG("<null-BP>\n"); return; }
	LOG("BP%d <%S> - %s way round - %s\n",
		bp->allocation_id, bp->debugging_log_name, bp->right_way_round?"right":"wrong",
		BinaryPredicates::form_to_text(bp));
	for (i=0; i<2; i++) BinaryPredicates::log_term_details(&bp->term_details[i], i);
	LOG("  test: $i\n", bp->test_function);
	LOG("  make true: $i\n", bp->make_true_function);
	LOG("  make false: $i\n", bp->make_false_function);
	LOG("  storage property: $Y\n", bp->i6_storage_property);
}

@h Relation names.
A useful little nonterminal to spot the names of relation, such as
"adjacency". (Note: not "adjacency relation".) This is only used when there
is good reason to suspect that the word in question is the name of a relation,
so the fact that it runs relatively slowly does not matter.

=
<relation-name> internal {
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if (WordAssemblages::compare_with_wording(&(bp->relation_name), W)) {
			*XP = bp; return TRUE;
		}
	return FALSE;
}

@ =
text_stream *BinaryPredicates::get_log_name(binary_predicate *bp) {
	return bp->debugging_log_name;
}

@h Miscellaneous access routines.

=
int BinaryPredicates::get_form_of_relation(binary_predicate *bp) {
	return bp->form_of_relation;
}
int BinaryPredicates::is_explicit_with_runtime_storage(binary_predicate *bp) {
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	if (bp->form_of_relation == Relation_Implicit) return FALSE;
	if (bp->form_of_relation == Relation_ByRoutine) return FALSE;
	return TRUE;
}
char *BinaryPredicates::form_to_text(binary_predicate *bp) {
	switch(bp->form_of_relation) {
		case Relation_Implicit: return "Relation_Implicit";
		case Relation_OtoO: return "Relation_OtoO";
		case Relation_OtoV: return "Relation_OtoV";
		case Relation_VtoO: return "Relation_VtoO";
		case Relation_VtoV: return "Relation_VtoV";
		case Relation_Sym_OtoO: return "Relation_Sym_OtoO";
		case Relation_Sym_VtoV: return "Relation_Sym_VtoV";
		case Relation_Equiv: return "Relation_Equiv";
		case Relation_ByRoutine: return "Relation_ByRoutine";
		default: return "formless-BP";
	}
}

parse_node *BinaryPredicates::get_bp_created_at(binary_predicate *bp) {
	return bp->bp_created_at;
}

@ Details of the terms:

=
kind *BinaryPredicates::term_kind(binary_predicate *bp, int t) {
	if (bp == NULL) internal_error("tried to find kind of null relation");
	return BinaryPredicates::kind_of_term(&(bp->term_details[t]));
}
i6_schema *BinaryPredicates::get_term_as_function_of_other(binary_predicate *bp, int t) {
	if (bp == NULL) internal_error("tried to find function of null relation");
	return bp->term_details[t].function_of_other;
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
	return bp->test_function;
}
int BinaryPredicates::can_be_made_true_at_runtime(binary_predicate *bp) {
	if ((bp->make_true_function) ||
		(bp->reversal->make_true_function)) return TRUE;
	return FALSE;
}

@ For the A-parser. The real code is all elsewhere; note that the
|assertions| field, which is used only for relations between values rather
than objects, is a linked list. (Information about objects is stored in
linked lists pointed to from the |instance| structure in question; that
can't be done if an assertion is about values, so they are stored under the
relation itself.)

=
int BinaryPredicates::allow_arbitrary_assertions(binary_predicate *bp) {
	return bp->arbitrary;
}
int BinaryPredicates::store_dynamically(binary_predicate *bp) {
	return bp->dynamic_memory;
}
int BinaryPredicates::relates_values_not_objects(binary_predicate *bp) {
	return bp->relates_values_not_objects;
}
inference_subject *BinaryPredicates::as_subject(binary_predicate *bp) {
	return bp->knowledge_about_bp;
}

@ For use when optimising code.

=
property *BinaryPredicates::get_i6_storage_property(binary_predicate *bp) {
	return bp->i6_storage_property;
}
int BinaryPredicates::allows_function_simplification(binary_predicate *bp) {
	return bp->allow_function_simplification;
}
inter_name *default_rr = NULL;
void BinaryPredicates::mark_as_needed(binary_predicate *bp) {
	if (bp->record_needed == FALSE) {
		bp->bp_iname = InterNames::new(RELATION_RECORD_INAMEF);
		bp->bp_iname->eventual_owner = BinaryPredicates::package(bp);
		if (default_rr == NULL) {
			default_rr = bp->bp_iname;
			Emit::named_iname_constant(InterNames::iname(MEANINGLESS_RR_INAME), K_value, bp->bp_iname);
		}
	}
	bp->record_needed = TRUE;
}

inter_name *BinaryPredicates::iname(binary_predicate *bp) {
	if (bp == NULL) return NULL;
	return bp->bp_iname;
}

@ For use with comparative relations.

=
void BinaryPredicates::set_comparison_details(binary_predicate *bp,
	int sign, property *prn) {
	bp->comparison_sign = sign; bp->comparative_property = prn;
}

@ The predicate-calculus engine compiles much better loops if
we can help it by providing an I6 schema of a loop header solving the
following problem:

Loop a variable $v$ (in the schema, |*1|) over all possible $x$ such that
$R(x, t)$, for some fixed $t$ (in the schema, |*1|).

If we can't do this, it will still manage, but by the brute force method
of looping over all $x$ in the left domain of $R$ and testing every possible
$R(x, t)$.

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
proviso |P|, is such that |P(x) == t|. For example, ${\it worn-by}(x, t)$
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

@h The built-in BPs.
Here we create spatial relationships, numerical comparisons and a few others:
all of the BPs in the "exceptional one-off cases" part of the classification
above. This happens very early in compilation.

=
void BinaryPredicates::make_built_in(void) {
	Calculus::Equality::REL_create_initial_stock();
	Properties::ProvisionRelation::REL_create_initial_stock();
	Relations::Universal::REL_create_initial_stock();
	Calculus::QuasinumericRelations::REL_create_initial_stock();
	#ifdef IF_MODULE
	PL::SpatialRelations::REL_create_initial_stock();
	PL::MapDirections::REL_create_initial_stock();
	#endif
	Properties::SettingRelations::REL_create_initial_stock();
	Properties::SameRelations::REL_create_initial_stock();
	Properties::ComparativeRelations::REL_create_initial_stock();
	Tables::Relations::REL_create_initial_stock();
	Relations::Explicit::REL_create_initial_stock();
}

@h Other property-based relations.

=
void BinaryPredicates::make_built_in_further(void) {
	Calculus::Equality::REL_create_second_stock();
	Properties::ProvisionRelation::REL_create_second_stock();
	Relations::Universal::REL_create_second_stock();
	Calculus::QuasinumericRelations::REL_create_second_stock();
	#ifdef IF_MODULE
	PL::SpatialRelations::REL_create_second_stock();
	PL::MapDirections::REL_create_second_stock();
	#endif
	Properties::SettingRelations::REL_create_second_stock();
	Properties::SameRelations::REL_create_second_stock();
	Properties::ComparativeRelations::REL_create_second_stock();
	Tables::Relations::REL_create_second_stock();
	Relations::Explicit::REL_create_second_stock();
}

@

@d DECLINE_TO_MATCH 1000 /* not one of the three legal |*_MATCH| values */
@d NEVER_MATCH_SAYING_WHY_NOT 1001 /* not one of the three legal |*_MATCH| values */

=
int BinaryPredicates::typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	int result = DECLINE_TO_MATCH;
	switch (bp->relation_family) {
		case EQUALITY_KBP: result = Calculus::Equality::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case PROVISION_KBP: result = Properties::ProvisionRelation::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case UNIVERSAL_KBP: result = Relations::Universal::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case QUASINUMERIC_KBP: result = Calculus::QuasinumericRelations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		#ifdef IF_MODULE
		case SPATIAL_KBP: result = PL::SpatialRelations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case MAP_CONNECTING_KBP: result = PL::MapDirections::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		#endif
		#ifndef IF_MODULE
		case SPATIAL_KBP: result = TRUE; break;
		case MAP_CONNECTING_KBP: result = TRUE; break;
		#endif
		case PROPERTY_SETTING_KBP: result = Properties::SettingRelations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case PROPERTY_SAME_KBP: result = Properties::SameRelations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case PROPERTY_COMPARISON_KBP: result = Properties::ComparativeRelations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case LISTED_IN_KBP: result = Tables::Relations::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		case EXPLICIT_KBP: result = Relations::Explicit::REL_typecheck(bp, kinds_of_terms, kinds_required, tck); break;
		default: internal_error("typechecked unknown KBP");
	}
	return result;
}

int BinaryPredicates::assert(binary_predicate *bp,
		inference_subject *subj0, parse_node *spec0, inference_subject *subj1, parse_node *spec1) {
	int success = FALSE;
	switch (bp->relation_family) {
		case EQUALITY_KBP: success = Calculus::Equality::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case PROVISION_KBP: success = Properties::ProvisionRelation::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case UNIVERSAL_KBP: success = Relations::Universal::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case QUASINUMERIC_KBP: success = Calculus::QuasinumericRelations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		#ifdef IF_MODULE
		case SPATIAL_KBP: success = PL::SpatialRelations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case MAP_CONNECTING_KBP: success = PL::MapDirections::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		#endif
		#ifndef IF_MODULE
		case SPATIAL_KBP: success = FALSE; break;
		case MAP_CONNECTING_KBP: success = FALSE; break;
		#endif
		case PROPERTY_SETTING_KBP: success = Properties::SettingRelations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case PROPERTY_SAME_KBP: success = Properties::SameRelations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case PROPERTY_COMPARISON_KBP: success = Properties::ComparativeRelations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case LISTED_IN_KBP: success = Tables::Relations::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		case EXPLICIT_KBP: success = Relations::Explicit::REL_assert(bp, subj0, spec0, subj1, spec1); break;
		default: internal_error("asserted unknown KBP");
	}
	return success;
}

i6_schema *BinaryPredicates::get_i6_schema(int task, binary_predicate *bp, annotated_i6_schema *asch) {
	int success = FALSE;
	switch (bp->relation_family) {
		case EQUALITY_KBP: success = Calculus::Equality::REL_compile(task, bp, asch); break;
		case PROVISION_KBP: success = Properties::ProvisionRelation::REL_compile(task, bp, asch); break;
		case UNIVERSAL_KBP: success = Relations::Universal::REL_compile(task, bp, asch); break;
		case QUASINUMERIC_KBP: success = Calculus::QuasinumericRelations::REL_compile(task, bp, asch); break;
		#ifdef IF_MODULE
		case SPATIAL_KBP: success = PL::SpatialRelations::REL_compile(task, bp, asch); break;
		case MAP_CONNECTING_KBP: success = PL::MapDirections::REL_compile(task, bp, asch); break;
		#endif
		#ifndef IF_MODULE
		case SPATIAL_KBP: success = FALSE; break;
		case MAP_CONNECTING_KBP: success = FALSE; break;
		#endif
		case PROPERTY_SETTING_KBP: success = Properties::SettingRelations::REL_compile(task, bp, asch); break;
		case PROPERTY_SAME_KBP: success = Properties::SameRelations::REL_compile(task, bp, asch); break;
		case PROPERTY_COMPARISON_KBP: success = Properties::ComparativeRelations::REL_compile(task, bp, asch); break;
		case LISTED_IN_KBP: success = Tables::Relations::REL_compile(task, bp, asch); break;
		case EXPLICIT_KBP: success = Relations::Explicit::REL_compile(task, bp, asch); break;
		default: internal_error("compiled unknown KBP");
	}

	if (success == FALSE) {
		switch(task) {
			case TEST_ATOM_TASK: asch->schema = bp->test_function; break;
			case NOW_ATOM_TRUE_TASK: asch->schema = bp->make_true_function; break;
			case NOW_ATOM_FALSE_TASK: asch->schema = bp->make_false_function; break;
		}
	}

	return asch->schema;
}

void BinaryPredicates::describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	int success = FALSE;
	switch (bp->relation_family) {
		case EQUALITY_KBP: success = Calculus::Equality::REL_describe_for_problems(OUT, bp); break;
		case PROVISION_KBP: success = Properties::ProvisionRelation::REL_describe_for_problems(OUT, bp); break;
		case UNIVERSAL_KBP: success = Relations::Universal::REL_describe_for_problems(OUT, bp); break;
		case QUASINUMERIC_KBP: success = Calculus::QuasinumericRelations::REL_describe_for_problems(OUT, bp); break;
		#ifdef IF_MODULE
		case SPATIAL_KBP: success = PL::SpatialRelations::REL_describe_for_problems(OUT, bp); break;
		case MAP_CONNECTING_KBP: success = PL::MapDirections::REL_describe_for_problems(OUT, bp); break;
		#endif
		#ifndef IF_MODULE
		case SPATIAL_KBP: success = FALSE; break;
		case MAP_CONNECTING_KBP: success = FALSE; break;
		#endif
		case PROPERTY_SETTING_KBP: success = Properties::SettingRelations::REL_describe_for_problems(OUT, bp); break;
		case PROPERTY_SAME_KBP: success = Properties::SameRelations::REL_describe_for_problems(OUT, bp); break;
		case PROPERTY_COMPARISON_KBP: success = Properties::ComparativeRelations::REL_describe_for_problems(OUT, bp); break;
		case LISTED_IN_KBP: success = Tables::Relations::REL_describe_for_problems(OUT, bp); break;
		case EXPLICIT_KBP: success = Relations::Explicit::REL_describe_for_problems(OUT, bp); break;
		default: internal_error("found unknown KBP");
	}
	if (success == NOT_APPLICABLE) return;
	if (success == FALSE) {
		if (WordAssemblages::nonempty(bp->relation_name)) WRITE("the %A", &(bp->relation_name));
		else WRITE("a");
		WRITE(" relation");
	}
	kind *K0 = BinaryPredicates::term_kind(bp, 0); if (K0 == NULL) K0 = K_object;
	kind *K1 = BinaryPredicates::term_kind(bp, 1); if (K1 == NULL) K1 = K_object;
	WRITE(" (between ");
	if (Kinds::Compare::eq(K0, K1)) {
		Kinds::Textual::write_plural(OUT, K0);
	} else {
		Kinds::Textual::write_articled(OUT, K0);
		WRITE(" and ");
		Kinds::Textual::write_articled(OUT, K1);
	}
	WRITE(")");
}
