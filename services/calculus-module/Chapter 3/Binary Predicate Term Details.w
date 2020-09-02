[BPTerms::] Binary Predicate Term Details.

To keep track of requirements on the terms for a binary predicate.

@ Different BPs apply to different sorts of terms: for instance, the
numerical less-than comparison applies to numbers, whereas containment
applies to things. The two terms need not have the same domain: the
"wearing" relation, as seen in

>> Harry Smythe wears the tweed waistcoat.

is a binary predicate $W(x_0, x_1)$ such that $x_0$ ranges across people
and $x_1$ ranges across things.

It's therefore helpful to record requirements on any given term of a BP,
and we do that with the following structure.[1]

[1] Unary predicates do not use this structure, because it is slightly more
efficient to roughly duplicate this arrangement than to use it directly. But
the ideas are exactly the same.

@default TERM_DOMAIN_CALCULUS_TYPE struct kind

=
typedef struct bp_term_details {
	struct wording called_name; /* "(called...)" name, if any exists */
	TERM_DOMAIN_CALCULUS_TYPE *implies_infs; /* the domain of values allowed */
	struct kind *implies_kind; /* the kind of these values */
	struct i6_schema *function_of_other; /* the function $f_0$ or $f_1$ as above */
	char *index_term_as; /* usually null, but if not, used in Phrasebook index */
} bp_term_details;

@ =
bp_term_details BPTerms::new(TERM_DOMAIN_CALCULUS_TYPE *infs) {
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
bp_term_details BPTerms::new_full(TERM_DOMAIN_CALCULUS_TYPE *infs,
	kind *K, wording CW, i6_schema *f) {
	bp_term_details bptd = BPTerms::new(infs);
	bptd.implies_kind = K;
	bptd.called_name = CW;
	bptd.function_of_other = f;
	return bptd;
}

@ In a few cases BPs need to be created before the relevant domains are known,
so that we must fill them in later, using the following:

=
void BPTerms::set_domain(bp_term_details *bptd, kind *K) {
	if (bptd == NULL) internal_error("no BPTD");
	bptd->implies_kind = K;
	bptd->implies_infs = TERM_DOMAIN_FROM_KIND_FUNCTION(K);
}

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

=
void BPTerms::set_function(bp_term_details *bptd, i6_schema *f) {
	if (bptd == NULL) internal_error("no BPTD");
	bptd->function_of_other = f;
}

i6_schema *BPTerms::get_function(bp_term_details *bptd) {
	if (bptd == NULL) internal_error("no BPTD");
	return bptd->function_of_other;
}

@ The kind of a term is:

=
kind *BPTerms::kind(bp_term_details *bptd) {
	if (bptd == NULL) return NULL;
	if (bptd->implies_kind) return bptd->implies_kind;
	return TERM_DOMAIN_TO_KIND_FUNCTION(bptd->implies_infs);
}

@ The table of relations in the index uses the textual name of an INFS, so:

=
void BPTerms::index(OUTPUT_STREAM, bp_term_details *bptd) {
	if (bptd->index_term_as) { WRITE("%s", bptd->index_term_as); return; }
	wording W = EMPTY_WORDING;
	if (bptd->implies_infs) W = TERM_DOMAIN_WORDING_FUNCTION(bptd->implies_infs);
	if (Wordings::nonempty(W)) WRITE("%W", W); else WRITE("--");
}
