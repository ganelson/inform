[Extensions::] Extension Services.

An Inform 7 extension.

@ =
typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	#ifdef CORE_MODULE
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	int loaded_from_built_in_area; /* Located within Inform application */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct source_file *read_into_file; /* Which source file loaded this */
	struct text_stream *rubric_as_lexed;
	struct text_stream *extra_credit_as_lexed;
	#endif
	MEMORY_MANAGEMENT
} inform_extension;

inform_extension *Extensions::new_ie(void) {
	inform_extension *E = CREATE(inform_extension);
	E->as_copy = NULL;
	#ifdef CORE_MODULE
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->loaded_from_built_in_area = FALSE;
	E->authorial_modesty = FALSE;
	E->rubric_as_lexed = NULL;
	E->extra_credit_as_lexed = NULL;	
	E->read_into_file = NULL;
	#endif
	return E;
}
