[Translation::] Translation.

A way to express rules for how to translate names from the Inter namespace into the
target language's namespace.

@ This section of code is pleasingly simple: it has no functionality, and exists as
a stand-alone section just to give these functions legible names.

=
typedef struct name_translation {
	struct text_stream *translate_to;
	int then_make_unique;
	struct inter_name_generator *name_generator;
	int derive;
	int by_imposition;
} name_translation;

name_translation Translation::same(void) {
	name_translation nt;
	nt.translate_to = NULL;
	nt.then_make_unique = FALSE;
	nt.name_generator = NULL;
	nt.derive = FALSE;
	nt.by_imposition = FALSE;
	return nt;
}

name_translation Translation::uniqued(void) {
	name_translation nt = Translation::same();
	nt.then_make_unique = TRUE;
	return nt;
}

name_translation Translation::imposed(void) {
	name_translation nt = Translation::same();
	nt.by_imposition = TRUE;
	return nt;
}

name_translation Translation::to(text_stream *S) {
	name_translation nt = Translation::same();
	nt.translate_to = S;
	return nt;
}

name_translation Translation::to_uniqued(text_stream *S) {
	name_translation nt = Translation::same();
	nt.translate_to = S;
	nt.then_make_unique = TRUE;
	return nt;
}

name_translation Translation::prefix(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::multiple_use_generator(S, NULL, NULL);
	nt.derive = TRUE;
	return nt;
}

name_translation Translation::suffix(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::multiple_use_generator(NULL, NULL, S);
	nt.derive = TRUE;
	return nt;
}

name_translation Translation::generate(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::multiple_use_generator(NULL, S, NULL);
	return nt;
}
