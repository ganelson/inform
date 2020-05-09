[Pluralisation::] Pluralisation.

To form plurals of nouns.

@h Dictionary.
A modest dictionary of plurals is maintained to allow the user to record
better plurals than the ones we would make ourselves. This assumes that a
plural can be constructed without knowledge of context, but that works in
almost all cases. (Arguably "dwarf" should pluralise to "dwarfs" when
discussing stars and to "dwarves" when reading Tolkien, but it is devoutly
to be hoped that few works of IF will contain both at once.)

=
typedef struct plural_dictionary_entry {
	PREFORM_LANGUAGE_TYPE *defined_in;
	struct wording singular_form; /* words of singular form */
	struct wording plural_form; /* words of plural form */
	CLASS_DEFINITION
} plural_dictionary_entry;

@ Note that we are entirely allowed to register a new plural for a phrase
which already has a plural in the dictionary, even for the same language,
which is why we do not trouble to search the existing dictionary here.

=
void Pluralisation::register(wording S, wording P, PREFORM_LANGUAGE_TYPE *nl) {
	plural_dictionary_entry *pde = CREATE(plural_dictionary_entry);
	pde->singular_form = S;
	pde->plural_form = P;
	pde->defined_in = nl;
	LOGIF(CONSTRUCTED_PLURALS, "[Registering plural of %W as %W]\n", S, P);
}

@h Searching the plural dictionary.
The following routine can either be called once only -- in which case it
yields up the best known plural for the phrase -- or iteratively, in which
case it serves up all known plurals of the given phrase, starting with the
best (the earliest defined in the text, if any plural for this phrase has
been so defined) and finishing up with the worst (a mechanically-made
one not found in the dictionary).

=
plural_dictionary_entry *Pluralisation::make(wording W, wording *PW,
	plural_dictionary_entry *search_from, PREFORM_LANGUAGE_TYPE *nl) {
	if (nl == NULL) nl = English_language;

	plural_dictionary_entry *pde;

	if (Wordings::empty(W)) { *PW = EMPTY_WORDING; return NULL; }

	if (search_from == NULL) search_from = FIRST_OBJECT(plural_dictionary_entry);
	else search_from = NEXT_OBJECT(search_from, plural_dictionary_entry);

	for (pde = search_from; pde; pde = NEXT_OBJECT(pde, plural_dictionary_entry))
		if ((pde->defined_in == NULL) || (pde->defined_in == nl))
			if (Wordings::match(W, pde->singular_form)) {
				*PW = pde->plural_form;
				return pde;
			}

	@<Make a new plural by lexical writing back@>;

	return NULL;
}

@ When the dictionary fails us, we use lexical rewriting to construct plurals
of phrases found only in the singular in the source. For instance, if the
designer says that "A wicker basket is a kind of container" then Inform will
need to recognise not only "wicker basket" but also "wicker baskets", a
pair of words not found in the source text anywhere. So the following
routine takes the text |(w1, w2)| and feeds a suitable plural into the
lexer, emerging with the text |(plw1, plw2)|.

We do not write the new plural into the dictionary: there is no need, as
it can be rebuilt quickly whenever needed again.

@<Make a new plural by lexical writing back@> =
	feed_t id = Feeds::begin();
	if (Wordings::length(W) > 1) Feeds::feed_wording(Wordings::trim_last_word(W));
	int last_wn = Wordings::last_wn(W);
	TEMPORARY_TEXT(original);
	TEMPORARY_TEXT(pluralised);
	WRITE_TO(original, "%+W", Wordings::one_word(last_wn));
	if (*(Lexer::word_text(last_wn)) == '\"') WRITE_TO(pluralised, "some-long-text");
	else Pluralisation::regular(pluralised, original, nl);
	Feeds::feed_stream(pluralised);
	*PW = Feeds::end(id);
	DISCARD_TEXT(original);
	DISCARD_TEXT(pluralised);
	LOGIF(CONSTRUCTED_PLURALS, "[Constructing plural of %W as %W]\n", W, *PW);

@h The pluralizing trie.
The following takes a single word, assumes it to be a noun which meaningfully
has a plural, and modifies it to the plural form.

=
int Pluralisation::regular(OUTPUT_STREAM, text_stream *from, PREFORM_LANGUAGE_TYPE *nl) {
	if (nl == NULL) nl = English_language;
	match_avinue *plural_trie =
		Preform::Nonparsing::define_trie(<singular-noun-to-its-plural>, TRIE_END, nl);
	return Inflections::suffix_inflection(OUT, plural_trie, from);
}
