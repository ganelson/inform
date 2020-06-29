[NounPhrases::] Noun Phrases.

To construct noun-phrase subtrees for assertion sentences found
in the parse tree.

@h Hierarchy of noun phrases.
Noun phrase nodes are built at four levels of elaboration, which we take in
turn:

(-NP1) Raw: where the text is entirely untouched and unannotated.
(-NP2) Articled: where any initial English article is converted to an annotation.
(-NP3) List-divided: where, in addition, a list is broken up into individual items.
(-NP4) Worldly: where, in addition, pronouns, relative phrases establishing
relationships and properties (and other grammar meaningful only for references
to physical objects and kinds) are parsed.

At levels (NP1) and (NP2), a NP produces a single |PROPER_NOUN_NT| node; at
level (NP3), the result is a subtree contining |PROPER_NOUN_NT| and |AND_NT|
nodes; but at level (NP4) this subtree may include any of |RELATIONSHIP_NT|,
|CALLED_NT|, |WITH_NT|, |AND_NT|, |KIND_NT| or |PROPER_NOUN_NT|.

Because a small proportion of noun phrase subtrees is thrown away, due to
backtracking on mistaken guesses at parsing of sentences, it is important
that creating an (NP) should have no side-effects beyond the construction
of the tree itself (and, of course, the memory used up, but we won't worry
about that: the proportion thrown away really is small).

@h Creation.
The following macro is useful in the grammar below:

@d GENERATE_RAW_NP
	0; *XP = (preform_lookahead_mode == FALSE)?(NounPhrases::new_raw(W)):NULL

=
parse_node *NounPhrases::new_raw(wording W) {
	parse_node *PN = Node::new(PROPER_NOUN_NT);
	Annotations::write_int(PN, nounphrase_article_ANNOT, NO_ART);
	Node::set_text(PN, W);
	return PN;
}

@ Other node types are generated as follows. Note that these make nothing in
lookahead mode; this prevents needless memory allocation.

=
parse_node *NounPhrases::PN_void(node_type_t t, wording W) {
	if (preform_lookahead_mode) return NULL;
	parse_node *P = Node::new(t);
	Node::set_text(P, W);
	return P;
}

parse_node *NounPhrases::PN_single(node_type_t t, wording W, parse_node *A) {
	if (preform_lookahead_mode) return NULL;
	parse_node *P = Node::new(t);
	Node::set_text(P, W);
	P->down = A;
	return P;
}

parse_node *NounPhrases::PN_pair(node_type_t t, wording W, parse_node *A, parse_node *B) {
	if (preform_lookahead_mode) return NULL;
	parse_node *P = Node::new(t);
	Node::set_text(P, W);
	P->down = A; P->down->next = B;
	return P;
}

@h Raw nounphrases (NP1).
A raw noun phrase can in principle be any nonempty wording:

=
<nounphrase> ::=
	...									==> GENERATE_RAW_NP

@h Articled nounphrases (NP2).
Although, again, any text is acceptable, now we now take note of the definite
or indefinite article, and also of whether it's used in the singular or the
plural.

Note that unexpectedly upper-case articles are left well alone: this is why

>> On the table is a thing called A Town Called Alice.

creates an object called "A Town Called Alice", not an indefinitely-articled
one called "Town Called Alice". Articles are not removed if that would
leave the text empty.

=
<nounphrase-definite> ::=
	<definite-article> <nounphrase> |    ==> 0; *XP = RP[2]
	<nounphrase>						==> 0; *XP = RP[1]

<nounphrase-articled> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<if-not-deliberately-capitalised> <indefinite-article> <nounphrase> |    ==> 0; *XP = RP[3]; @<Annotate node by article@>;
	<if-not-deliberately-capitalised> <definite-article> <nounphrase> |    ==> 0; *XP = RP[3]; @<Annotate node by definite article@>;
	<nounphrase>															==> 0; *XP = RP[1]

@<Annotate node by article@> =
	Annotations::write_int(*XP, nounphrase_article_ANNOT, INDEF_ART);
	Annotations::write_int(*XP, plural_reference_ANNOT, (R[2] >= 3)?TRUE:FALSE);
	Annotations::write_int(*XP, gender_reference_ANNOT, (R[2] % 3) + 1);

@<Annotate node by definite article@> =
	Annotations::write_int(*XP, nounphrase_article_ANNOT, DEF_ART);
	Annotations::write_int(*XP, plural_reference_ANNOT, (R[2] >= 3)?TRUE:FALSE);
	Annotations::write_int(*XP, gender_reference_ANNOT, (R[2] % 3) + 1);

@ Sometimes we want to look at the article (if any) used in a raw NP, and
absorb that into annotations, removing it from the wording. For instance, in

>> On the table is a thing called a part of the broken box.

we want to remove the initial article from the calling-name to produce
"part of the broken box". (If we handled this NP as other than raw, we might
spuriously make a subtree with |RELATIONSHIP_NT| in thanks to the apparent
"part of" clause.)

=
parse_node *NounPhrases::annotate_by_articles(parse_node *RAW_NP) {
	<nounphrase-articled>(Node::get_text(RAW_NP));
	parse_node *MODEL = <<rp>>;
	Node::set_text(RAW_NP, Node::get_text(MODEL));
	Annotations::write_int(RAW_NP, nounphrase_article_ANNOT,
		Annotations::read_int(MODEL, nounphrase_article_ANNOT));
	Annotations::write_int(RAW_NP, plural_reference_ANNOT,
		Annotations::read_int(MODEL, plural_reference_ANNOT));
	return RAW_NP;
}

@h Balanced variants.
The balanced versions match any text in which brackets and braces are used in
a correctly paired way; otherwise they are the same.

=
<np-balanced> ::=
	^<balanced-text> |    ==> 0; return FAIL_NONTERMINAL;
	<nounphrase>										==> 0; *XP = RP[1]

<np-articled-balanced> ::=
	^<balanced-text> |    ==> 0; return FAIL_NONTERMINAL;
	<nounphrase-articled>								==> 0; *XP = RP[1]

@h List-divided nounphrases (NP3).
An "articled list" matches text like

>> the lion, a witch, and some wardrobes

as a list of three articled noun phrases.

=
<nounphrase-articled-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-articled-balanced> <np-articled-tail> |    ==> 0; *XP = NounPhrases::PN_pair(AND_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<nounphrase-articled>								==> 0; *XP = RP[1]

<np-articled-tail> ::=
	, {_and} <nounphrase-articled-list> |    ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <nounphrase-articled-list>					==> Wordings::first_wn(W); *XP= RP[1]

@ That builds into a lopsided binary tree: thus "the lion, a witch,
and some wardrobes" becomes
= (text)
	AND_NT ","
	    PROPERTY_LIST_NT "lion" article:definite
	    AND_NT ", and"
	        PROPERTY_LIST_NT "witch" article:indefinite
	        PROPERTY_LIST_NT "wardrobe" article:indefinite pluralreference:true
=
The binary structure is chosen since it allows us to use a simple recursion
to run through possibilities, and also to preserve each connective of the text
in the |AND_NT| nodes.

@ Alternative lists divide up at "or". Thus

>> voluminous, middling big or poky

becomes a tree of three (raw) noun phrases.

=
<nounphrase-alternative-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-balanced> <np-alternative-tail> |    ==> 0; *XP = NounPhrases::PN_pair(AND_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<nounphrase>									==> 0; *XP = RP[1]

<np-alternative-tail> ::=
	, {_or} <nounphrase-alternative-list> |    ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/or} <nounphrase-alternative-list>			==> Wordings::first_wn(W); *XP= RP[1]

@h Worldly nounphrases (NP4).
That just leaves the big one. It comes in two versions, for the object and
subject NPs of a regular sentence, but they are almost exactly the same. They
differ slightly, as we'll see, in the handling of relative phrases; when
parsing a sentence such as

>> X is Y

Inform uses <nounphrase-as-subject> on X and <nounphrase-as-object> on Y. Both
of these make use of the recursive <np-inner> grammar, and the difference
in effect is that at the topmost level of recursion the as-subject version
allows only limited RPs, not unlimited ones. (In languages other than English,
we might want bigger differences, with X read in the nominative and Y in the
accusative.)

=
<nounphrase-as-object> ::=
	<np-inner> |    ==> 0; *XP = RP[1]
	<nounphrase-articled>							==> 0; *XP = RP[1]

<nounphrase-as-subject> ::=
	<if-not-deliberately-capitalised> <np-relative-phrase-limited> |    ==> 0; *XP = RP[2]
	<np-inner-without-rp> |    ==> 0; *XP = RP[1]
	<nounphrase-articled>							==> 0; *XP = RP[1]

<np-inner> ::=
	<if-not-deliberately-capitalised> <np-relative-phrase-unlimited> |    ==> 0; *XP = RP[2]
	<np-inner-without-rp>							==> 0; *XP = RP[1]

@ So here we go with relative phrases. We've already seen that our two general
forms of NP differ only in the range of RPs allowed at the top level: here we
see, furthermore, that the only limitation is that in the subject of an
assertion sentence, a RP can't be introduced with what seems to be a participle.

It might seem grammatically odd to be parsing RPs as the subject side of a
sentence, when they surely ought to belong to the VP rather than either of the
NPs. But English is, in fact, odd this way: it allows indicative statements,
but no other sentences, to use "subject-verb inversion". An assertion such as

>> In the Garden is a tortoise.

is impossible to parse with a naive grammar for relative phrases, because
the "in" is miles away from its governing verb "is". (This quirk is called an
inversion since the sentence is equivalent to the easier to construe
"A tortoise is in the Garden".) This is why we want to parse subject NPs
and object NPs symmetrically, and allow either one to be an RP instead.

And yet subject-verb inversion can't be allowed in all cases, though; we might
pedantically argue that the Yoda-like utterance

>> Holding the light sabre is the young Jedi.

is grammatically correct, but if so then we have to read

>> Holding Area is a room.

as a statement that a room is holding something called "Area", which then
causes Inform to throw problem messages about confusion between people and
rooms (since only people can hold things). So we forbid subject-verb inversion
in the case of a participle like "holding".

=
<np-relative-phrase-limited> ::=
	<np-relative-phrase-implicit> |    ==> 0; *XP = RP[1]
	<probable-participle> *** |    ==> 0; return FAIL_NONTERMINAL;
	<np-relative-phrase-explicit>								==> 0; *XP = RP[1]

<np-relative-phrase-unlimited> ::=
	<np-relative-phrase-implicit> |    ==> 0; *XP = RP[1]
	<np-relative-phrase-explicit>								==> 0; *XP = RP[1]

@ Inform guesses above that most English words ending in "-ing" are present
participles -- like guessing, bluffing, cheating, and so on. But there is
a conspicuous exception to this; so any word found in <non-participles>
is never treated as a participle.

=
<non-participles> ::=
	thing/something

<probable-participle> internal 1 {
	if (Vocabulary::test_flags(Wordings::first_wn(W), ING_MC)) {
		if (<non-participles>(W)) return FALSE;
		return TRUE;
	}
	return FALSE;
}

@ Finally, we define what we mean by implicit and explicit relative phrases.
As examples, the right-hand sides of:

>> The lawnmower is in the Garden.
>> The giraffe is here.

are explicit and implicit respectively. Implicit RPs are those where the
relationship is with something unstated. For instance, "here" generally means
a containment by the room currently being discussed; "carried" implies that
the player does the carrying.

Note that we throw out a relative phrase if the noun phrase within it would
begin with "and" or a comma; this enables us to parse sentences concerning
directions, in particular, a little better.

=
<np-relative-phrase-explicit> ::=
	<permitted-preposition> _,/and ... |    ==> 0; return FAIL_NONTERMINAL;
	<permitted-preposition> _,/and |    ==> 0; return FAIL_NONTERMINAL;
	<permitted-preposition> <np-inner-without-rp>		==> 0; @<Work out a meaning@>;

@<Work out a meaning@> =
	VERB_MEANING_LINGUISTICS_TYPE *R = VerbMeanings::get_relational_meaning(
		VerbMeanings::get_regular_meaning_of_verb(permitted_verb, RP[1], NULL));
	if (R == NULL) return FALSE;
	*XP = NounPhrases::PN_rel(W, VerbMeanings::reverse_VMT(R), -1, RP[2]);

@ Now the heart of it. There are basically seven constructions which can make
complex NPs from simple ones: we've already seen one of these, the relative
phrase. The sequence of checking these is very important, because it decides
which clauses are represented higher in the parse tree when multiple structures
are present within the NP. For instance, we want to turn

>> [A] in a container called the flask and cap with flange

into the subtree:
= (text)
	RELATIONSHIP_NT "in" = containment
	    CALLED_NT "called"
	        PROPER_NOUN_NT "container" article:indefinite
	        PROPER_NOUN_NT "flask and cap with flange" article:definite
=
but we also want:

>> [B] in a container with carrying capacity 10 and diameter 12
= (text)
	RELATIONSHIP_NT "in" = containment
	    WITH_NT "with"
	        PROPER_NOUN_NT "container" article:indefinite
	        AND_NT "and"
	            PROPERTY_LIST_NT "carrying capacity 10"
	            PROPERTY_LIST_NT "diameter 12"
=
These two cases together force our conventions: from sentence [A] we see
that initial relative clauses (in) must beat callings ("called") which
must beat property clauses ("with"), while from [B] we see that property
clauses must beat lists ("and"). These all have to beat "of" and
"from", which seem to be about linguistically equal, because these
constructions must be easily reversible, as we shall see, and the best way
to ensure that is to make sure they can only appear right down close to
leaves in the tree. This dictates
= (text)
	RELATIONSHIP_NT > CALLED_NT > WITH_NT > AND_NT
=
in the sense that a subtree construction higher in this chain will take
precedence over (and therefore be higher up in the tree than) one that is
lower. That leaves just the seventh construction: "kind of ...". To
avoid misreading this as an "of", and to protect "called", we need
= (text)
	CALLED_NT > KIND_NT
=
but otherwise we are fairly free where to put it (though the resulting trees
will take different shapes in some cases if we move it around, we could
write code which handled any of the outcomes about equally well). In fact,
we choose to make it lowest possible, so the final precedence order is:
= (text)
	RELATIONSHIP_NT > CALLED_NT > WITH_NT > AND_NT > KIND_NT
=
Once all possible constructions have been recursively exhausted, every leaf we
end up at is treated as a balanced articled NP. (Thus <np-inner> fails on
source text where brackets aren't balanced, such as "smile X-)". This is why
<nounphrase-as-object> above resorts to using <nounphrase-articled> if
<np-inner> should fail. The reason we want <np-inner> to require balance is
that otherwise "called" clauses can be misread: "frog (called toad)" can be
misread as saying that "frog (" is called "toad )".)

Two technicalities to note about the following nonterminal. Production (a)
exists to accept arbitrary text quickly and without allocating memory to hold
parse nodes when the Preform parser is simply performing a lookahead (to see
where it will eventually parse). This is a very important economy: without it,
parsing a list of $n$ items will have running time and space requirements of
order $2^n$. But during regular parsing, production (a) has no effect, and can
be ignored. Secondly, note the ampersand notation: recall that
|&whatever| at the start of production means "only try this production if the
word |whatever| is somewhere in the text we're looking at". Again, it's a
speed optimisation, and doesn't affect the language's definition.

=
<np-inner-without-rp> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-inner> {called} <np-articled-balanced> |    ==> 0; *XP = NounPhrases::PN_pair(CALLED_NT, WR[1], RP[1], RP[2])
	<np-inner> <np-with-or-having-tail> |    ==> 0; *XP = NounPhrases::PN_pair(WITH_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<np-inner> <np-and-tail> |    ==> 0; *XP = NounPhrases::PN_pair(AND_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<np-kind-phrase> |    ==> 0; *XP = RP[1]
	<nominative-pronoun> |    ==> GENERATE_RAW_NP; Annotations::write_int(*XP, nounphrase_article_ANNOT, IT_ART);
	<np-articled-balanced>							==> 0; *XP = RP[1]

@ The tail of with-or-having parses for instance "with carrying capacity 5"
in the NP

>> a container with carrying capacity 5

This makes use of a nifty feature of Preform: when Preform scans to see how to
divide the text, it tries <np-with-or-having-tail> in each possible position.
The reply can be yes, no, or no and move on a little. So if we spot "it with
action", the answer is no, and move on three words: that jumps over a "with"
which we don't want to recognise. (Because if we did, then "the locking it
with action" would be parsed as a property list, "action", attaching to a
bogus object called "locking it".)

=
<np-with-or-having-tail> ::=
	it with action *** |    ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} (/) *** |    ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} ... ( <response-letter> ) |    ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} <np-new-property-list>		==> Wordings::first_wn(WR[1]); *XP = RP[1]

<np-new-property-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-new-property> <np-new-property-tail> |    ==> 0; *XP = NounPhrases::PN_pair(AND_NT, Wordings::one_word(R[2]), RP[1], RP[2])
	<np-new-property>							==> 0; *XP = RP[1];

<np-new-property> ::=
	...											==> 0; *XP = NounPhrases::PN_void(PROPERTY_LIST_NT, W);

<np-new-property-tail> ::=
	, {_and} <np-new-property-list> |    ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <np-new-property-list>				==> Wordings::first_wn(W); *XP= RP[1]

@ The "and" tail is much easier:

=
<np-and-tail> ::=
	, {_and} <np-inner> |    ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <np-inner>							==> Wordings::first_wn(W); *XP= RP[1]

@ Kind phrases are easier:

>> A sedan chair is a kind of vehicle. A weather pattern is a kind.

Note that indefinite articles are permitted before the word "kind(s)",
but definite articles are not.

=
<np-kind-phrase> ::=
	<indefinite-article> <np-kind-phrase-unarticled> |    ==> 0; *XP = RP[2]
	<np-kind-phrase-unarticled>							==> 0; *XP = RP[1]

<np-kind-phrase-unarticled> ::=
	kind/kinds |    ==> 0; *XP = NounPhrases::PN_void(KIND_NT, W)
	kind/kinds of <np-inner>					==> 0; *XP = NounPhrases::PN_single(KIND_NT, W, RP[1])

@h Relationship nodes.
A modest utility routine to construct and annotation RELATIONSHIP nodes.

@d STANDARD_RELN 0 /* the default annotation value: never explicitly set */
@d PARENTAGE_HERE_RELN 1 /* only ever set by the Spatial plugin */
@d DIRECTION_RELN 2

=
parse_node *NounPhrases::PN_rel(wording W, VERB_MEANING_LINGUISTICS_TYPE *R, int reln_type, parse_node *referent) {
	if (preform_lookahead_mode) return NULL;
	parse_node *P = Node::new(RELATIONSHIP_NT);
	Node::set_text(P, W);
	#ifdef CORE_MODULE
	if (R) Node::set_relationship(P, R);
	else if (reln_type >= 0)
		Annotations::write_int(P, relationship_node_type_ANNOT, reln_type);
	else internal_error("undefined relationship node");
	#endif
	if (referent == NULL) {
		referent = NounPhrases::new_raw(W);
		Annotations::write_int(referent, implicitly_refers_to_ANNOT, TRUE);
	}
	P->down = referent;
	return P;
}
