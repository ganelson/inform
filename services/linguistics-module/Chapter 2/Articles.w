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

@ An //article_usage// object is what a lexicon search returns when text is
matched against some form of a pronoun.

=
typedef struct article_usage {
	struct article *article_used;
	struct vocabulary_entry *word_used;
	struct grammatical_usage *usage;
	CLASS_DEFINITION
} article_usage;

@ =
void Articles::write_usage(OUTPUT_STREAM, article_usage *au) {
	WRITE(" {%S '%V'", au->article_used->name, au->word_used);
	Stock::write_usage(OUT, au->usage, GENDER_LCW + NUMBER_LCW + CASE_LCW);
	WRITE("}");
}

@ The stock of articles is fixed at two:

=
grammatical_category *articles_category = NULL;
article *definite_article = NULL;
article *indefinite_article = NULL;

void Articles::create_category(void) {
	articles_category = Stock::new_category(I"article");
	METHOD_ADD(articles_category, LOG_GRAMMATICAL_CATEGORY_MTID, Articles::log_item);
	definite_article = Articles::new(I"definite");
	indefinite_article = Articles::new(I"indefinite");
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

int Articles::may_be_definite(article_usage *au) {
	if ((au) && (au->article_used == definite_article)) return TRUE;
	return FALSE;			
}

@ It's very important to parse articles, which occur very often, rapidly. So
we give these special priority in Preform optimisation; they have their very
own private bit.

=
void Articles::mark_for_preform(void) {
	NTI::give_nt_reserved_incidence_bit(<article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<definite-article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<indefinite-article>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<definite-article-table>, ARTICLE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<indefinite-article-table>, ARTICLE_RES_NT_BIT);
}

@h Removing articles.
These are useful for stripping optional articles from text:

=
<optional-definite-article> ::=
	<definite-article> ... |	==> 0; *XP = RP[1]
	...

<optional-indefinite-article> ::=
	<indefinite-article> ... |	==> 0; *XP = RP[1]
	...

<optional-article> ::=
	<article> ... |	            ==> 0; *XP = RP[1]
	...

<compulsory-article> ::=
	<article> ...	            ==> 0; *XP = RP[1]

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

@h Parsing.
Articles are ideal for small word sets, because even when their tables of
inflected forms are in theory large, there are in practice few distinguishable
words in them.

=
small_word_set *article_sws = NULL, *definite_article_sws = NULL, *indefinite_article_sws = NULL;

@ And now we have to make them. The following capacity would be enough even if
we were simultaneously dealing with four languages in which every inflection
produced a different word. So it really is not going to run out.

@d ARTICLE_SWS_CAPACITY 4*NO_KNOWN_GENDERS*NO_KNOWN_NUMBERS*MAX_GRAMMATICAL_CASES

=
void Articles::create_small_word_sets(void) {
	article_sws = Stock::new_sws(ARTICLE_SWS_CAPACITY);
	Articles::add(article_sws, <definite-article-table>, definite_article);
	Articles::add(article_sws, <indefinite-article-table>, indefinite_article);

	definite_article_sws = Stock::new_sws(ARTICLE_SWS_CAPACITY);
	Articles::add(definite_article_sws, <definite-article-table>, definite_article);

	indefinite_article_sws = Stock::new_sws(ARTICLE_SWS_CAPACITY);
	Articles::add(indefinite_article_sws, <indefinite-article-table>, indefinite_article);
}

@ All of which use the following, which extracts inflected forms from the
nonterminal tables (see below for their English versions and layout).

=
small_word_set *Articles::add(small_word_set *sws, nonterminal *nt, article *a) {
	for (production_list *pl = nt->first_pl; pl; pl = pl->next_pl) {
		int c = 0;
		for (production *pr = pl->first_pr; pr; pr = pr->next_pr) {
			int t = 0;
			for (ptoken *pt = pr->first_pt; pt; pt = pt->next_pt) {
				for (ptoken *alt = pt; alt; alt = alt->alternative_ptoken)  {
					if (alt->ptoken_category != FIXED_WORD_PTC)
						PreformUtilities::production_error(nt, pr,
							"article sets must contain single fixed words");
					else {
						article_usage *au =
							(article_usage *) Stock::find_in_sws(sws, alt->ve_pt);
						if (au == NULL) {
							au = CREATE(article_usage);
							au->article_used = a;
							au->word_used = alt->ve_pt;
							au->usage = Stock::new_usage(a->in_stock, NULL);
							Stock::add_to_sws(sws, alt->ve_pt, au);
						}
						lcon_ti lcon = Stock::to_lcon(a->in_stock);
						lcon = Lcon::set_number(lcon, t%2);
						lcon = Lcon::set_gender(lcon, 1 + t/2);
						lcon = Lcon::set_case(lcon, c);
						Stock::add_form_to_usage(au->usage, lcon);
					}
				}
				t++;
			}
			c++;
		}
		if (c != Declensions::no_cases(pl->definition_language))
			PreformUtilities::production_error(nt, NULL,
				"wrong number of cases in article set");
	}
	return sws;
}

@ And here are the requisite nonterminals:

=
<article> internal 1 {
	if (article_sws == NULL) Articles::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	*XP = (article_usage *) Stock::find_in_sws(article_sws, ve);
	if (*XP) return TRUE;
	return FALSE;
}

<definite-article> internal 1 {
	if (article_sws == NULL) Articles::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	*XP = (article_usage *) Stock::find_in_sws(definite_article_sws, ve);
	if (*XP) return TRUE;
	return FALSE;
}

<indefinite-article> internal 1 {
	if (article_sws == NULL) Articles::create_small_word_sets();
	vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
	*XP = (article_usage *) Stock::find_in_sws(indefinite_article_sws, ve);
	if (*XP) return TRUE;
	return FALSE;
}

@h English articles.
So, then, these nonterminals are not parsed by Preform but are instead used
to stock small word sets above. The fornat is the same as the one used in
//Pronouns//: rows are cases, within which the sequence is neuter singular,
neuter plural, masculine singular, masculine plural, feminine singular,
feminine plural. In English, of course, articles hardly inflect at all,
but German would be quite a bit more interesting.

=
<definite-article-table> ::=
	the the the the the the |
	the the the the the the

<indefinite-article-table> ::=
	a/an some a/an some a/an some |
	a/an some a/an some a/an some

@h Unit testing.
The //linguistics-test// test case |articles| calls this.

=
void Articles::test(OUTPUT_STREAM) {
	WRITE("article_sws:\n");
	Articles::write_sws(OUT, article_sws);
	WRITE("definite_article_sws:\n");
	Articles::write_sws(OUT, definite_article_sws);
	WRITE("indefinite_article_sws:\n");
	Articles::write_sws(OUT, indefinite_article_sws);
}

void Articles::write_sws(OUTPUT_STREAM, small_word_set *sws) {
	for (int i=0; i<sws->used; i++) {
		WRITE("(%d) %V:", i, sws->word_ve[i]);
		article_usage *au = (article_usage *) sws->results[i];
		Articles::write_usage(OUT, au);
		WRITE("\n");
	}
}
