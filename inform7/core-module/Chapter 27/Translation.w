[Translation::] Translation.

@

=
typedef struct name_translation {
	struct text_stream *translate_to;
	int then_make_unique;
	int generate_from;
	int localise;
	int derive;
	int faux_letter;
} name_translation;

name_translation Translation::same(void) {
	name_translation nt;
	nt.translate_to = NULL;
	nt.then_make_unique = FALSE;
	nt.generate_from = -1;
	nt.localise = FALSE;
	nt.derive = FALSE;
	nt.faux_letter = -1;
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

name_translation Translation::derive(int f) {
	name_translation nt = Translation::same();
	nt.generate_from = f;
	nt.derive = TRUE;
	return nt;
}

name_translation Translation::derive_lettered(int f, int faux_letter) {
	name_translation nt = Translation::same();
	nt.generate_from = f;
	nt.derive = TRUE;
	nt.faux_letter = faux_letter;
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
