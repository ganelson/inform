[Articles::] Articles and Pronouns.

To define some elementary particles.

@h Pronouns.
We now define some grammatical basics. These are all very simple, and the user
can't create new instances of them -- whereas the source text can make new
adjectives, verbs and nouns, it can't make new pronouns.

=
<pronoun> ::=
	<nominative-pronoun> |    ==> R[1]
	<accusative-pronoun>		==> R[1]

<nominative-pronoun> ::=
	it/he/she |    ==> 1		/* singular */
	they						==> 2		/* plural */

<accusative-pronoun> ::=
	it/him/her |    ==> 1		/* singular */
	them						==> 2		/* plural */

@h Possessives.
Inform uses these not only for parsing but also to inflect text. For example,
if every person is given a nose, the player will see it as "my nose" not
"your nose". Inform handles such inflections by converting a pronoun in
one grammar into its corresponding pronoun in another (in this case, first
person to second person).

=
<possessive-first-person> ::=
	my |    ==> 1		/* singular */
	our							==> 2		/* plural */

<possessive-second-person> ::=
	your |    ==> 1		/* singular */
	your						==> 2		/* plural */

<possessive-third-person> ::=
	its/his/her |    ==> 1		/* singular */
	their						==> 2		/* plural */

@h Articles.

@d DEF_ART 1 /* the definite article */
@d INDEF_ART 2 /* the indefinite article */
@d NO_ART 3 /* no article supplied */
@d IT_ART 4 /* a special case to handle "it" */

=
<article> ::=
	<indefinite-article> |    ==> R[1]
	<definite-article>			==> R[1]

@ The articles need to be single words, and the following two productions
have an unusual convention: they are required to have production numbers
which encode both the implied grammatical number and gender.

(a) singular, neuter; (b) masculine; (c) feminine
(d) plural, neuter; (e) masculine; (f) feminine

In English gender doesn't appear in articles, and "the" is ambiguous as to
number in any case, so we end up with something quite dull:

=
<definite-article> ::=
	/a/ the

<indefinite-article> ::=
	/a/ a/an |
	/d/ some

@ These are useful for stripping optional articles from text:

=
<optional-definite-article> ::=
	<definite-article> ... |
	...

<optional-article> ::=
	<article> ... |
	...

<compulsory-article> ::=
	<article> ...

@ =
wording Articles::remove_the(wording W) {
	if ((Wordings::length(W) > 1) &&
		(<optional-definite-article>(W))) return GET_RW(<optional-definite-article>, 1);
	return W;
}

wording Articles::remove_article(wording W) {
	if (Wordings::nonempty(W)) {
		<optional-article>(W);
		return GET_RW(<optional-article>, 1);
	}
	return W;
}

@h Participles.
Inform guesses that most English words ending in "-ing" are present
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

@h Negation.

=
<negated-clause> ::=
	not ...

@h Marking for Preform efficiency.

=
void Articles::mark_for_preform(void) {
	Preform::assign_bitmap_bit(<article>, 2);
	Preform::assign_bitmap_bit(<definite-article>, 2);
	Preform::assign_bitmap_bit(<indefinite-article>, 2);
}
