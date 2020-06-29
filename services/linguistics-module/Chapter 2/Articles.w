[Articles::] Articles.

Preform grammar for the articles.

@ 

@d DEF_ART 1 /* the definite article */
@d INDEF_ART 2 /* the indefinite article */
@d NO_ART 3 /* no article supplied */
@d IT_ART 4 /* a special case to handle "it" */

=
<article> ::=
	<indefinite-article> |      ==> R[1]
	<definite-article>          ==> R[1]

@ The articles need to be single words, and the following two productions
have an unusual convention: they are required to have production numbers
which encode both the implied grammatical number and gender. These numbers
mean:

|/a/| singular, neuter; |/b/| singular, masculine; |/c/| singular, feminine;
|/d/| plural, neuter; |/e/| plural, masculine; |/f/| plural, feminine.

But since in English gender doesn't appear in articles, and "the" is ambiguous
as to number in any case, we end up with something quite dull as the default:

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
	if ((Wordings::length(W) > 1) && (<optional-definite-article>(W)))
		return GET_RW(<optional-definite-article>, 1);
	return W;
}

wording Articles::remove_article(wording W) {
	if (Wordings::nonempty(W)) {
		<optional-article>(W);
		return GET_RW(<optional-article>, 1);
	}
	return W;
}

@ It's very important to parse articles, which occur very often, rapidly. So
we give these special priority in Preform optimisation; they have their very
own private bit.

=
void Articles::mark_for_preform(void) {
	NTI::give_nt_reserved_incidence_bit(<article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<definite-article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<indefinite-article>, ARTICLE_RES_NT_BIT);
}
