[Translation::] Translation.

A way to express rules for how to translate names from the Inter namespace into the
target language's namespace.

@ The //final// code-generator produces output code in a high-level language
which itself has identifier names. Clearly it is free to choose those names
however it would like; the process of going from an Inter name to a name in
the output is called "translation".

Each //hierarchy_location// comes with a //name_translation//, which specifies
how translation is to be done on the resource at this location. This might,
for example, express the idea "when code-generating, give this resource an
identifier name which is made by suffixing |_X| after the name of an
associated resource". Or more commonly, just "give this resource the same
identifier name as its Inter symbol name".

A variety of stipulations can be made, and with memory consumption unimportant
here, the following is really a union: almost all the fields will be left blank.

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
