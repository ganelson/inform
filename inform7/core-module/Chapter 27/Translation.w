[Translation::] Translation.

@

=
typedef struct name_translation {
	struct text_stream *translate_to;
	int then_make_unique;
	int generate_from;
	int localise;
} name_translation;

name_translation Translation::same(void) {
	name_translation nt;
	nt.translate_to = NULL;
	nt.then_make_unique = FALSE;
	nt.generate_from = -1;
	nt.localise = FALSE;
	return nt;
}

name_translation Translation::uniqued(void) {
	name_translation nt = Translation::same();
	nt.then_make_unique = TRUE;
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

name_translation Translation::generate(int f) {
	name_translation nt = Translation::same();
	nt.generate_from = f;
	return nt;
}

name_translation Translation::generate_in(int f) {
	name_translation nt = Translation::same();
	nt.generate_from = f;
	nt.localise = TRUE;
	return nt;
}
