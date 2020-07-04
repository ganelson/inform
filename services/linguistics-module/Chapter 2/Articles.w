[Articles::] Articles.

Preform grammar for the articles.

@h Articles.
Article objects contain no interesting data: in effect, the //article// class
is an enumeration.

=
typedef struct article {
	struct text_stream *name;
	struct linguistic_stock_item *in_stock;

	CLASS_DEFINITION
} article;

@ The stock of articles is fixed at three:

=
grammatical_category *articles_category = NULL;
article *definite_article = NULL;
article *indefinite_article = NULL;

void Articles::create_category(void) {
	articles_category = Stock::new_category(I"article");
	METHOD_ADD(articles_category, LOG_GRAMMATICAL_CATEGORY_MTID, Articles::log_item);
	definite_article = Articles::new(I"definite article");
	indefinite_article = Articles::new(I"indefinite article");
}

article *Articles::new(text_stream *name) {
	article *P = CREATE(article);
	P->name = Str::duplicate(name);
	P->in_stock = Stock::new(articles_category, STORE_POINTER_article(P));
	return P;
}

void Articles::log_item(grammatical_category *cat, general_pointer data) {
	article *P = RETRIEVE_POINTER_article(data);
	LOG("%S", P->name);
}

@h Stock references.
We ignore case in articles, but do take note of number and gender.

=
lcon_ti Articles::use(article *P, int n, int g) {
	lcon_ti lcon = Stock::to_lcon(P->in_stock);
	lcon = Lcon::set_number(lcon, n);
	lcon = Lcon::set_gender(lcon, g);
	return lcon;
}

int Articles::use_a_to_f(article *P, int r) {
	return Articles::use(P, (r >= 3)?PLURAL_NUMBER:SINGULAR_NUMBER, (r % 3) + 1);
}

article *Articles::from_lcon(lcon_ti lcon) {
	linguistic_stock_item *item = Stock::from_lcon(lcon);
	if (item == NULL) return NULL;
	return RETRIEVE_POINTER_article(item->data);
}

void Articles::write_lcon(OUTPUT_STREAM, lcon_ti lcon) {
	article *P = Articles::from_lcon(lcon);
	WRITE(" %S ", P->name);
	Lcon::write_number(OUT, Lcon::get_number(lcon));
	Lcon::write_gender(OUT, Lcon::get_gender(lcon));
}

@h English articles.
A small subterfuge is used here for efficiency's sake. In principle we should
test and distinguish all six combined number/gender forms of the articles,
but that would be fractionally slower in English where there are so few
possibilities. The indirection below enables <definite-article-forms> and
<indefinite-article-forms> to be only partially filled in, with the amount
differing in different languages.

=
<article> ::=
	<indefinite-article> |      ==> R[1]
	<definite-article>          ==> R[1]

<definite-article> ::=
	<definite-article-forms>	==> Articles::use_a_to_f(definite_article, R[1])

<indefinite-article> ::=
	<indefinite-article-forms>	==> Articles::use_a_to_f(indefinite_article, R[1])

@ The articles need to be single words, and the following two productions
have an unusual convention: they are required to have production numbers
which encode both the implied grammatical number and gender. These numbers
mean:

|/a/| singular, neuter; |/b/| singular, masculine; |/c/| singular, feminine;
|/d/| plural, neuter; |/e/| plural, masculine; |/f/| plural, feminine.

But since in English gender doesn't appear in articles, and "the" is ambiguous
as to number in any case, we end up with something quite dull as the default:

=
<definite-article-forms> ::=
	/a/ the

<indefinite-article-forms> ::=
	/a/ a/an |
	/d/ some

@ It's very important to parse articles, which occur very often, rapidly. So
we give these special priority in Preform optimisation; they have their very
own private bit.

=
void Articles::mark_for_preform(void) {
	NTI::give_nt_reserved_incidence_bit(<article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<definite-article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<indefinite-article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<definite-article-forms>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<indefinite-article-forms>, ARTICLE_RES_NT_BIT);
}

@h Removing articles.
These are useful for stripping optional articles from text:

=
<optional-definite-article> ::=
	<definite-article> ... |	==> R[1]
	...

<optional-indefinite-article> ::=
	<indefinite-article> ... |	==> R[1]
	...

<optional-article> ::=
	<article> ... |	            ==> R[1]
	...

<compulsory-article> ::=
	<article> ...	            ==> R[1]

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
