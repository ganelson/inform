[NounPhrases::] Noun Phrases.

To construct noun-phrase subtrees for assertion sentences.

@h Hierarchy of noun phrases.
Noun phrase nodes are built at four levels of elaboration, which we take in
turn:

(-NP1) Raw: where the text is entirely untouched and unannotated.
(-NP2) Articled: where any initial article is converted to an annotation.
(-NP3) List-divided: where, in addition, a list is broken up into individual items.
(-NP4) Full: where, in addition, pronouns, relative phrases establishing
relationships and properties, and so on are parsed.

@h Raw nounphrases (NP1).
A raw noun phrase is always a single |UNPARSED_NOUN_NT|. The following always
matches any non-empty text:

=
<np-unparsed> ::=
	...                 ==> 0; *XP = Diagrams::new_UNPARSED_NOUN(W)

@ This "balanced" version, however, requires any brackets and braces to be
used in a balanced way: thus |frogs ( and toads )| would match, but
|frogs ( and| would not. It therefore does not always match.

=
<np-balanced> ::=
	^<balanced-text> |  ==> 0; return FAIL_NONTERMINAL;
	<np-unparsed>       ==> 0; *XP = RP[1]

@ The noun phrase of an existential sentence is recognised thus:

=
<np-existential> ::=
	there               ==> 0; *XP = Diagrams::new_DEFECTIVE(W);

@h Articled nounphrases (NP2).
Now an initial article becomes an annotation and is removed from the text.
Note that
(a) Unexpectedly upper-case articles are left well alone, as in the sentence:

>> On the table is a thing called A Town Called Alice.

(b) Articles are not removed if that would leave the text empty.

(c) If we are in a language where the same word might either be definite or
indefinite, the latter has precedence.

=
<np-articled> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<if-not-deliberately-capitalised> <indefinite-article> <np-unparsed> |  ==> 0; *XP = NounPhrases::add_article(RP[3], RP[2]);
	<if-not-deliberately-capitalised> <definite-article> <np-unparsed> |    ==> 0; *XP = NounPhrases::add_article(RP[3], RP[2]);
	<np-unparsed>															==> 0; *XP = RP[1]

<np-articled-balanced> ::=
	^<balanced-text> |                                                      ==> 0; return FAIL_NONTERMINAL;
	<np-articled>								                            ==> 0; *XP = RP[1]

@ =
parse_node *NounPhrases::add_article(parse_node *p, article_usage *au) {
	Node::set_article(p, au);
	return p;
}

@ The following function is only occasionally useful (for example, Inform
uses it in //core: Tables of Definitions//); takes an existing raw node
and retrospectively applies <np-articled> to it.

=
parse_node *NounPhrases::annotate_by_articles(parse_node *RAW_NP) {
	<np-articled>(Node::get_text(RAW_NP));
	parse_node *MODEL = <<rp>>;
	Node::set_text(RAW_NP, Node::get_text(MODEL));
	Node::set_article(RAW_NP, Node::get_article(MODEL));
	return RAW_NP;
}

@h List-divided nounphrases (NP3).
An "articled list" matches text like "the lion, a witch, and some wardrobes"
as a list of articled noun phrases.

Note that the requirement that non-final terms in the list have to be balanced
means that an and or a comma inside brackets can never be a divider. Thus
"the horse (and its boy)" would be one item, not two.

=
<np-articled-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-articled-balanced> <np-articled-tail> |  ==> 0; *XP = Diagrams::new_AND(Wordings::one_word(R[2]), RP[1], RP[2])
	<np-articled>                                ==> 0; *XP = RP[1]

<np-articled-tail> ::=
	, {_and} <np-articled-list> |                ==> Wordings::first_wn(W); *XP = RP[1]
	{_,/and} <np-articled-list>                  ==> Wordings::first_wn(W); *XP = RP[1]

@ "Alternative lists" divide up at "or" rather than "and", thus matching text
such as "voluminous, middling big or poky", and the individual entries are not
articled.

=
<np-alternative-list> ::=
	... |                                  ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<np-balanced> <np-alternative-tail> |  ==> 0; *XP = Diagrams::new_AND(Wordings::one_word(R[2]), RP[1], RP[2])
	<np-unparsed>                          ==> 0; *XP = RP[1]

<np-alternative-tail> ::=
	, {_or} <np-alternative-list> |  ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/or} <np-alternative-list>    ==> Wordings::first_wn(W); *XP= RP[1]

@h Full nounphrases (NP4).
When fully parsing the structure of a nounphrase, we have five different
constructions in play, and need to work out their precedence over each other:
rather as |*| takes precedence over |+| in arithmetic expressions in C, so
here we have --
= (text)
	RELATIONSHIP_NT > CALLED_NT > WITH_NT > AND_NT > KIND_NT
=
That is, relative clauses take precedence over callings, and so on. The
above hierarchy is arrived at thus:
(a) We need |RELATIONSHIP_NT > WITH_NT| so that "X is in a container with
carrying capacity 10" will work.
(b) We need |WITH_NT > AND_NT| so that "X is a container with carrying
capacity 10 and diameter 12" will work.
(c) We need |CALLED_NT > WITH_NT| so that "X is a container called the flask
with flange" will work.
(d) We need |RELATIONSHIP_NT > CALLED_NT| so that "A man called Horse is in
the High Sierra" will work.
(e) We want |KIND_NT| to be of low precedence because it is always either
the word "kind" alone, or "kind of N" for some atomic noun N.

See //About Sentence Diagrams// for numerous examples.

@ Full nounphrase parsing varies slightly according to the position of the
phrase, i.e., whether it is in the subject or object position. Thus "X is Y"
or "X is in Y" would lead to X being parsed by <np-as-subject>, Y by <np-as-object>.
They are identical except that:

(a) In subject position, a full nounphrase can use "there" to indicate
an existential sentence such as "there is a hair in my soup"; and

(b) In subject position, a relative phrase cannot begin with a word which
looks like a participle.

=
<np-as-subject> ::=
	<np-existential> |                                                  ==> 0; *XP = RP[1]
	<if-not-deliberately-capitalised> <np-relative-phrase-limited> |    ==> 0; *XP = RP[2]
	<np-nonrelative>                                                    ==> 0; *XP = RP[1]

<np-as-object> ::=
	<if-not-deliberately-capitalised> <np-relative-phrase-unlimited> |  ==> 0; *XP = RP[2]
	<np-nonrelative>                                                    ==> 0; *XP = RP[1]

@ To explain the limitation here: RPs only exist in the subject position due
to subject-verb inversion in English. Thus, "In the Garden is a tortoise" is a
legal inversion of "A tortoise is in the Garden". Following this logic we ought
to accept Yoda-like inversions such as "Holding the light sabre is the young Jedi",
but we don't want to do that, because then a sentence like "Holding Area is a room"
might have to be read as saying that a nameless room is holding something
called "Area".

=
<np-relative-phrase-limited> ::=
	<np-relative-phrase-implicit> |                                     ==> 0; *XP = RP[1]
	<probable-participle> *** |                                         ==> 0; return FAIL_NONTERMINAL;
	<np-relative-phrase-explicit>                                       ==> 0; *XP = RP[1]

<np-relative-phrase-unlimited> ::=
	<np-relative-phrase-implicit> |                                     ==> 0; *XP = RP[1]
	<np-relative-phrase-explicit>                                       ==> 0; *XP = RP[1]

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

@ An implicit RP is a word like "carried", or "worn", on its own -- this
implies a relation to some unspecified noun. We represent that in the tree
using the "implied noun" pronoun. For now, these are fixed.

=
<np-relative-phrase-implicit> ::=
	worn |              ==> @<Act on the implicit RP worn@>
	carried |           ==> @<Act on the implicit RP carried@>
	initially carried   ==> @<Act on the implicit RP initially carried@>

@<Act on the implicit RP worn@> =
	#ifndef IF_MODULE
	return FALSE;
	#endif
	#ifdef IF_MODULE
	*X = 0; *XP = Diagrams::new_implied_RELATIONSHIP(W, R_wearing);
	#endif

@<Act on the implicit RP carried@> =
	#ifndef IF_MODULE
	return FALSE;
	#endif
	#ifdef IF_MODULE
	*X = 0; *XP = Diagrams::new_implied_RELATIONSHIP(W, R_carrying);
	#endif

@<Act on the implicit RP initially carried@> =
	#ifndef IF_MODULE
	return FALSE;
	#endif
	#ifdef IF_MODULE
	*X = 0; *XP = Diagrams::new_implied_RELATIONSHIP(W, R_carrying);
	#endif

@ An explicit RP is one which uses a preposition and then a noun phrase: for
example, "on the table" is explicit.

Note that we throw out a relative phrase if the noun phrase within it would
begin with "and" or a comma; this enables us to parse sentences concerning
directions, in particular, a little better. But it means we do not recognise
"of, by and for the people" as an RP.

=
<np-relative-phrase-explicit> ::=
	<permitted-preposition> _,/and ... |       ==> 0; return FAIL_NONTERMINAL;
	<permitted-preposition> _,/and |           ==> 0; return FAIL_NONTERMINAL;
	<permitted-preposition> <np-nonrelative>   ==> @<Work out a meaning@>

@<Work out a meaning@> =
	VERB_MEANING_LINGUISTICS_TYPE *R = VerbMeanings::get_regular_meaning_of_form(
		Verbs::find_form(permitted_verb, RP[1], NULL));
	if (R == NULL) return FALSE;
	*XP = Diagrams::new_RELATIONSHIP(W, VerbMeanings::reverse_VMT(R), RP[2]);

@ We have now disposed of |RELATIONSHIP_NT| and are left with the constructs:
= (text)
	CALLED_NT > WITH_NT > AND_NT > KIND_NT
=
These are all handled by <np-nonrelative>. Two points to note:
(a) The first production accepts arbitrary text quickly and without allocating
memory if we're in lookahead mode -- an important economy since otherwise
parsing a list of $n$ items would have running time and memory of order $2^n$.
(b) If we regard the above constructs as being like operators in arithmetic,
then the operands have to match <np-operand>, and this requires text which has
balanced brackets. That ensures that, for example, "frog (called toad)"
is not misread as saying that "frog (" is called "toad )". But note that
the final <np-articled> production catches any unbalanced text, so even
text like "smile X-)" will in fact match <np-nonrelative>.

=
<np-nonrelative> ::=
	... |                                           ==> 0; *XP = NULL; return preform_lookahead_mode;
	<np-operand> {called} <np-articled-balanced> |  ==> 0; *XP = Diagrams::new_CALLED(WR[1], RP[1], RP[2])
	<np-operand> <np-with-or-having-tail> |         ==> 0; *XP = Diagrams::new_WITH(Wordings::one_word(R[2]), RP[1], RP[2])
	<np-operand> <np-and-tail> |                    ==> 0; *XP = Diagrams::new_AND(Wordings::one_word(R[2]), RP[1], RP[2])
	<np-kind-phrase> |                              ==> 0; *XP = RP[1]
	<agent-pronoun> |                               ==> 0; *XP = Diagrams::new_PRONOUN(W, RP[1])
	<here-pronoun> |                                ==> 0; *XP = Diagrams::new_PRONOUN(W, RP[1])
	<np-articled>                                   ==> 0; *XP = RP[1]

<np-operand> ::=
	<if-not-deliberately-capitalised> <np-relative-phrase-unlimited> |  ==> 0; *XP = RP[2]
	^<balanced-text> |                                                  ==> 0; return FAIL_NONTERMINAL;
	<np-nonrelative>                                                    ==> 0; *XP = RP[1]

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
	it with action *** |                       ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} (/) *** |                    ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} ... ( <response-letter> ) |  ==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{with/having} <np-new-property-list>       ==> Wordings::first_wn(WR[1]); *XP = RP[1]

<np-new-property-list> ::=
	... |                                      ==> 0; *XP = NULL; return preform_lookahead_mode;
	<np-new-property> <np-new-property-tail> | ==> 0; *XP = Diagrams::new_AND(Wordings::one_word(R[2]), RP[1], RP[2])
	<np-new-property>                          ==> 0; *XP = RP[1];

<np-new-property-tail> ::=
	, {_and} <np-new-property-list> |          ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <np-new-property-list>            ==> Wordings::first_wn(W); *XP= RP[1]

<np-new-property> ::=
	...                                        ==> 0; *XP = Diagrams::new_PROPERTY_LIST(W);

@ The "and" tail is much easier:

=
<np-and-tail> ::=
	, {_and} <np-operand> |                    ==> Wordings::first_wn(W); *XP= RP[1]
	{_,/and} <np-operand>                      ==> Wordings::first_wn(W); *XP= RP[1]

@ Kind phrases are easier:

>> A sedan chair is a kind of vehicle. A weather pattern is a kind.

Note that indefinite articles are permitted before the word "kind(s)",
but definite articles are not.

=
<np-kind-phrase> ::=
	<indefinite-article> <np-kind-phrase-unarticled> |  ==> 0; *XP = RP[2]
	<np-kind-phrase-unarticled>                         ==> 0; *XP = RP[1]

<np-kind-phrase-unarticled> ::=
	kind/kinds |                                        ==> 0; *XP = Diagrams::new_KIND(W, NULL)
	kind/kinds of <np-operand>                          ==> 0; *XP = Diagrams::new_KIND(W, RP[1])
