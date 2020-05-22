[ArticleInflection::] Article Inflection.

To inflect "a" into "an", and so forth.

@h The indefinite article trie.
Here we take text such as "UNESCO document" and put an article in front, to
get "a UNESCO document" (and not "an UNESCO document": these things are much
trickier than they look).

=
match_avinue *indef_trie = NULL;

void ArticleInflection::preface_by_article(OUTPUT_STREAM, text_stream *initial_text,
	NATURAL_LANGUAGE_WORDS_TYPE *nl) {
	if (indef_trie == NULL)
		indef_trie =
			PreformUtilities::define_trie(
				<singular-noun-to-its-indefinite-article>, TRIE_START,
				Linguistics::default_nl(NULL));
	wchar_t *result = Tries::search_avinue(indef_trie, initial_text);
	if (result == NULL) result = L"a";
	WRITE("%w %S", result, initial_text);
}
