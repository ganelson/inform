[Translation::] Translation.

@

=
typedef struct name_translation {
	struct text_stream *translate_to;
	int then_make_unique;
	struct inter_name_family *name_generator;
	int localise;
	int derive;
	int by_imposition;
	int faux_letter;
} name_translation;

name_translation Translation::same(void) {
	name_translation nt;
	nt.translate_to = NULL;
	nt.then_make_unique = FALSE;
	nt.name_generator = NULL;
	nt.localise = FALSE;
	nt.derive = FALSE;
	nt.by_imposition = FALSE;
	nt.faux_letter = -1;
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
	nt.name_generator = InterNames::name_generator(S, NULL, NULL);
	nt.derive = TRUE;
	return nt;
}

name_translation Translation::suffix(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::name_generator(NULL, NULL, S);
	nt.derive = TRUE;
	return nt;
}

name_translation Translation::suffix_special(text_stream *S, int faux_letter) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::name_generator(NULL, NULL, S);
	nt.derive = TRUE;
	nt.faux_letter = faux_letter;
	return nt;
}

name_translation Translation::generate(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::name_generator(NULL, S, NULL);
	return nt;
}

name_translation Translation::generate_in(text_stream *S) {
	name_translation nt = Translation::same();
	nt.name_generator = InterNames::name_generator(NULL, S, NULL);
	nt.localise = TRUE;
	return nt;
}
