[BinaryPredicates::] Binary Predicates.

To create and manage binary predicates, which are the underlying
data structures beneath Inform's relations.

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

(For Inform, the following will be an inference subject, which is a wider
category than kinds.)

@default TERM_DOMAIN_CALCULUS_TYPE struct kind

=
typedef struct bp_term_details {
	struct wording called_name; /* "(called...)" name, if any exists */
	TERM_DOMAIN_CALCULUS_TYPE *implies_infs; /* the domain of values allowed */
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
= (text)
	inside(ball, trophy case)| and |contains(trophy case, ball)
=
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
	struct bp_family *relation_family;
	int form_of_relation; /* one of the |Relation_*| constants defined below */
	struct word_assemblage relation_name; /* (which might have length 0) */
	struct parse_node *bp_created_at; /* where declared in the source text */
	struct text_stream *debugging_log_name; /* used when printing propositions to the debug log */

	#ifdef CORE_MODULE
	struct package_request *bp_package;
	struct inter_name *bp_iname; /* when referred to as a constant */
	struct inter_name *handler_iname;
	struct inter_name *v2v_bitmap_iname; /* only relevant for some relations */
	struct inter_name *bp_by_routine_iname; /* for relations by routine */
	struct inter_name *initialiser_iname; /* if stored in dynamically allocated memory */
	#endif

	struct bp_term_details term_details[2]; /* term 0 is the left term, 1 is the right */

	struct binary_predicate *reversal; /* the $R$ such that $R(x,y)$ iff $B(y,x)$ */
	int right_way_round; /* was this BP created directly? or is it a reversal of another? */

	/* how to compile code which tests or forces this BP to be true or false: */
	struct i6_schema *test_function; /* I6 schema for (a) testing $B(x, y)$... */
	struct wording condition_defn_text; /* ...unless this I7 condition is used instead */
	struct i6_schema *make_true_function; /* I6 schema for (b) "now $B(x, y)$" */
	struct i6_schema *make_false_function; /* I6 schema for (c) "now ${\rm not}(B(x, y))$" */

	/* for use in the A-parser: */
	int arbitrary; /* allow source to assert $B(x, y)$ for any arbitrary pairs $x, y$ */
	struct property *set_property; /* asserting $B(x, v)$ sets this prop. of $x$ to $v$ */
	struct wording property_pending_text; /* temp. version used until props created */
	int relates_values_not_objects; /* true if either term is necessarily a value... */
	TERM_DOMAIN_CALCULUS_TYPE *knowledge_about_bp; /* ...and if so, here's the list of known assertions */

	/* for optimisation of run-time code: */
	int dynamic_memory; /* stored in dynamically allocated memory */
	#ifdef CORE_MODULE
	struct property *i6_storage_property; /* provides run-time storage */
	#endif
	struct kind *storage_kind; /* kind of property owner */
	int allow_function_simplification; /* allow Inform to make use of any $f_i$ functions? */
	int fast_route_finding; /* use fast rather than slow route-finding algorithm? */
	char *loop_parent_optimisation_proviso; /* if not NULL, optimise loops using object tree */
	char *loop_parent_optimisation_ranger; /* if not NULL, routine iterating through contents */
	int record_needed; /* we need to compile a small array of details in readable memory */

	/* details, filled in for right-way-round BPs only, for particular kinds of BP: */
	int a_listed_in_predicate; /* (if right way) was this generated from a table column? */
	int *equivalence_partition; /* (if right way) partition array of equivalence classes */

	general_pointer family_specific;

	CLASS_DEFINITION
} binary_predicate;

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

@d VERB_MEANING_LINGUISTICS_TYPE struct binary_predicate
@d VERB_MEANING_REVERSAL_LINGUISTICS_CALLBACK BinaryPredicates::get_reversal
@d VERB_MEANING_EQUALITY R_equality
@d VERB_MEANING_POSSESSION a_has_b_predicate

@h Creating term details.
The essential point in defining a term is to describe the domain of values it
ranges over, which we do by giving an "inference subject" (INFS). An INFS is
roughly speaking anything in the model world which Inform can store knowledge
about; here it will almost always be a generality of things, such as "all
numbers", or "all rooms".

=
bp_term_details BinaryPredicates::new_term(TERM_DOMAIN_CALCULUS_TYPE *infs) {
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
bp_term_details BinaryPredicates::full_new_term(TERM_DOMAIN_CALCULUS_TYPE *infs, kind *K,
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
	bptd->implies_infs = TERM_DOMAIN_FROM_KIND_FUNCTION(K);
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
	if (bp == R_equality) return Kinds::binary_con(CON_relation, K_value, K_value);
	kind *K0 = BinaryPredicates::kind_of_term(&(bp->term_details[0]));
	kind *K1 = BinaryPredicates::kind_of_term(&(bp->term_details[1]));
	if (K0 == NULL) K0 = K_object;
	if (K1 == NULL) K1 = K_object;
	return Kinds::binary_con(CON_relation, K0, K1);
}

@ The kind of a term is:

=
kind *BinaryPredicates::kind_of_term(bp_term_details *bptd) {
	if (bptd == NULL) return NULL;
	if (bptd->implies_kind) return bptd->implies_kind;
	return TERM_DOMAIN_TO_KIND_FUNCTION(bptd->implies_infs);
}

@ The table of relations in the index uses the textual name of an INFS, so:

=
void BinaryPredicates::index_term_details(OUTPUT_STREAM, bp_term_details *bptd) {
	if (bptd->index_term_as) { WRITE("%s", bptd->index_term_as); return; }
	wording W = EMPTY_WORDING;
	if (bptd->implies_infs) W = TERM_DOMAIN_WORDING_FUNCTION(bptd->implies_infs);
	if (Wordings::nonempty(W)) WRITE("%W", W); else WRITE("--");
}

@ The following routine adds the given BP term as a call parameter to the
routine currently being compiled, deciding that something is an object if
its kind indications are all blank, but verifying that the value supplied
matches the specific necessary kind of object if there is one.

=
#ifdef CORE_MODULE
void BinaryPredicates::add_term_as_call_parameter(ph_stack_frame *phsf, bp_term_details bptd) {
	kind *K = BinaryPredicates::kind_of_term(&bptd);
	kind *PK = K;
	if ((PK == NULL) || (Kinds::Behaviour::is_subkind_of_object(PK))) PK = K_object;
	inter_symbol *lv_s = LocalVariables::add_call_parameter_as_symbol(phsf,
		bptd.called_name, PK);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), NOT_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, lv_s);
					Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(K));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::rfalse(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}
}
#endif

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
binary_predicate *BinaryPredicates::make_equality(bp_family *family, word_assemblage WA) {
	binary_predicate *bp = BinaryPredicates::make_single(family,
		BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
		I"is", NULL, NULL, WA);
	bp->reversal = bp; bp->right_way_round = TRUE;
	#ifdef REGISTER_RELATIONS_CALCULUS_CALLBACK
	REGISTER_RELATIONS_CALCULUS_CALLBACK(bp, WA);
	#endif
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
		#ifdef REGISTER_RELATIONS_CALCULUS_CALLBACK
		REGISTER_RELATIONS_CALCULUS_CALLBACK(bp, source_name);
		#endif
	}

	return bp;
}

@ When the source text declares new relations, it turns out to be convenient
to make their BPs in a two-stage process: to make sketchy, mostly-blank BP
structures for them early on -- but getting their names registered -- and
then fill in the correct details later. This is where such sketchy pairs are
made:

=
binary_predicate *BinaryPredicates::make_pair_sketchily(bp_family *family,
	word_assemblage wa, int f) {
	TEMPORARY_TEXT(relname)
	WRITE_TO(relname, "%V", WordAssemblages::first_word(&wa));
	binary_predicate *bp =
		BinaryPredicates::make_pair(family,
		BinaryPredicates::new_term(NULL), BinaryPredicates::new_term(NULL),
		relname, NULL, NULL, NULL, wa);
	DISCARD_TEXT(relname)
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
binary_predicate *BinaryPredicates::make_single(bp_family *family,
	bp_term_details left_term, bp_term_details right_term,
	text_stream *name,
	i6_schema *mtf, i6_schema *tf, word_assemblage rn) {
	binary_predicate *bp = CREATE(binary_predicate);
	bp->relation_family = family;
	bp->form_of_relation = Relation_Implicit;
	bp->relation_name = rn;
	bp->bp_created_at = current_sentence;
	bp->debugging_log_name = Str::duplicate(name);
	
	#ifdef CORE_MODULE
	bp->bp_package = NULL;
	bp->bp_iname = NULL;
	bp->handler_iname = NULL;
	bp->v2v_bitmap_iname = NULL;
	bp->bp_by_routine_iname = NULL;
	bp->initialiser_iname = NULL;
	#endif

	bp->term_details[0] = left_term; bp->term_details[1] = right_term;

	/* the |reversal| and the |right_way_round| field must be set by the caller */

	/* for use in code compilation */
	bp->test_function = tf;
	bp->condition_defn_text = EMPTY_WORDING;
	bp->make_true_function = mtf;
	bp->make_false_function = NULL;

	/* for use by the A-parser */
	bp->arbitrary = FALSE;
	bp->set_property = NULL;
	bp->property_pending_text = EMPTY_WORDING;
	bp->relates_values_not_objects = FALSE;
	#ifdef CORE_MODULE
	bp->knowledge_about_bp =
		InferenceSubjects::new(relations,
			RELN_SUB, STORE_POINTER_binary_predicate(bp), CERTAIN_CE);
	#endif
	#ifndef CORE_MODULE
	bp->knowledge_about_bp = NULL;
	#endif
	
	/* for optimisation of run-time code */
	bp->dynamic_memory = FALSE;
	#ifdef CORE_MODULE
	bp->i6_storage_property = NULL;
	#endif
	bp->storage_kind = NULL;
	bp->allow_function_simplification = TRUE;
	bp->fast_route_finding = FALSE;
	bp->loop_parent_optimisation_proviso = NULL;
	bp->loop_parent_optimisation_ranger = NULL;
	bp->record_needed = FALSE;

	/* details for particular kinds of relation */
	bp->a_listed_in_predicate = FALSE;
	bp->equivalence_partition = NULL;

	bp->family_specific = NULL_GENERAL_POINTER;

	return bp;
}

@h The package.

=
#ifdef CORE_MODULE
package_request *BinaryPredicates::package(binary_predicate *bp) {
	if (bp == NULL) internal_error("null bp");
	if (bp->bp_package == NULL)
		bp->bp_package = Hierarchy::package(CompilationUnits::find(bp->bp_created_at), RELATIONS_HAP);
	return bp->bp_package;
}
#endif

@h The handler.

=
#ifdef CORE_MODULE
inter_name *BinaryPredicates::handler_iname(binary_predicate *bp) {
	if (bp->handler_iname == NULL) {
		package_request *R = BinaryPredicates::package(bp);
		bp->handler_iname = Hierarchy::make_iname_in(HANDLER_FN_HL, R);
	}
	return bp->handler_iname;
}
#endif

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
	int i;
	if (bp == NULL) { LOG("<null-BP>\n"); return; }
	LOG("BP%d <%S> - %s way round - %s\n",
		bp->allocation_id, bp->debugging_log_name, bp->right_way_round?"right":"wrong",
		BinaryPredicates::form_to_text(bp));
	for (i=0; i<2; i++) BinaryPredicates::log_term_details(&bp->term_details[i], i);
	LOG("  test: $i\n", bp->test_function);
	LOG("  make true: $i\n", bp->make_true_function);
	LOG("  make false: $i\n", bp->make_false_function);
	#ifdef CORE_MODULE
	LOG("  storage property: $Y\n", bp->i6_storage_property);
	#endif
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
TERM_DOMAIN_CALCULUS_TYPE *BinaryPredicates::as_subject(binary_predicate *bp) {
	return bp->knowledge_about_bp;
}

@ For use when optimising code.

=
#ifdef CORE_MODULE
property *BinaryPredicates::get_i6_storage_property(binary_predicate *bp) {
	return bp->i6_storage_property;
}
#endif
int BinaryPredicates::allows_function_simplification(binary_predicate *bp) {
	return bp->allow_function_simplification;
}
#ifdef CORE_MODULE
inter_name *default_rr = NULL;
void BinaryPredicates::mark_as_needed(binary_predicate *bp) {
	if (bp->record_needed == FALSE) {
		bp->bp_iname = Hierarchy::make_iname_in(RELATION_RECORD_HL, BinaryPredicates::package(bp));
		if (default_rr == NULL) {
			default_rr = bp->bp_iname;
			inter_name *iname = Hierarchy::find(MEANINGLESS_RR_HL);
			Emit::named_iname_constant(iname, K_value, default_rr);
			Hierarchy::make_available(Emit::tree(), iname);
		}
	}
	bp->record_needed = TRUE;
}
#endif

#ifdef CORE_MODULE
inter_name *BinaryPredicates::iname(binary_predicate *bp) {
	if (bp == NULL) return NULL;
	return bp->bp_iname;
}
#endif

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
