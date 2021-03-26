[ImperativeDefinitionFamilies::] Imperative Definition Families.

Different categories of imperative definition.

@ There are very few of these, and an Inform source text cannot create more.
The following is called at startup, and then that's the lot:

=
imperative_defn_family *unknown_idf = NULL; /* used only temporarily */

void ImperativeDefinitionFamilies::create(void) {
	unknown_idf = ImperativeDefinitionFamilies::new(I"unknown-idf", FALSE);
	AdjectivalDefinitionFamily::create_family();
	ToPhraseFamily::create_family();
	RuleFamily::create_family();
}

@ Such a family is little more than a set of methods:

=
typedef struct imperative_defn_family {
	struct text_stream *family_name;
	struct method_set *methods;
	int compile_last;
	CLASS_DEFINITION
} imperative_defn_family;

imperative_defn_family *ImperativeDefinitionFamilies::new(text_stream *name, int last) {
	imperative_defn_family *family = CREATE(imperative_defn_family);
	family->family_name = Str::duplicate(name);
	family->methods = Methods::new_set();
	family->compile_last = last;
	return family;
}

@ So, then, the rest of this section provides an API, in effect, for different
users of imperative definitions to get their work done.

|CLAIM_IMP_DEFN_MTID| is for deciding from the syntax of a preamble whether
this definition should belong to the family or not.

@e CLAIM_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(CLAIM_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitionFamilies::identify(imperative_defn *id) {
	id->family = unknown_idf;
	imperative_defn_family *f;
	LOOP_OVER(f, imperative_defn_family)
		if (id->family == unknown_idf)
			VOID_METHOD_CALL(f, CLAIM_IMP_DEFN_MTID, id);
}

@ |ASSESS_IMP_DEFN_MTID| is for parsing it in more detail, later on.

@e ASSESS_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(ASSESS_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitionFamilies::assess(imperative_defn *id) {
	VOID_METHOD_CALL(id->family, ASSESS_IMP_DEFN_MTID, id);
}

@ |REGISTER_IMP_DEFN_MTID| is called on the family when everything has
been assessed.

@e REGISTER_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(REGISTER_IMP_DEFN_MTID, imperative_defn_family *f, int initial_problem_count)

void ImperativeDefinitionFamilies::register(imperative_defn_family *f, int initial_problem_count) {
	VOID_METHOD_CALL(f, REGISTER_IMP_DEFN_MTID, initial_problem_count);
}

@ |ASSESSMENT_COMPLETE_IMP_DEFN_MTID| is called on the family when everything has
been assessed.

@e ASSESSMENT_COMPLETE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(ASSESSMENT_COMPLETE_IMP_DEFN_MTID, imperative_defn_family *f, int initial_problem_count)

void ImperativeDefinitionFamilies::assessment_complete(imperative_defn_family *f, int initial_problem_count) {
	VOID_METHOD_CALL(f, ASSESSMENT_COMPLETE_IMP_DEFN_MTID, initial_problem_count);
}

@ |NEW_PHRASE_IMP_DEFN_MTID| is for ...

@e NEW_PHRASE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(NEW_PHRASE_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id, phrase *new_ph)

void ImperativeDefinitionFamilies::given_body(imperative_defn *id, phrase *new_ph) {
	VOID_METHOD_CALL(id->family, NEW_PHRASE_IMP_DEFN_MTID, id, new_ph);
}

@ |TO_RCD_IMP_DEFN_MTID| is for...

@e TO_RCD_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(TO_RCD_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id, ph_runtime_context_data *rcd)

ph_runtime_context_data ImperativeDefinitionFamilies::to_phrcd(imperative_defn *id) {
	current_sentence = id->at;
	Frames::make_current(&(id->body_of_defn->stack_frame));
	ph_runtime_context_data phrcd = Phrases::Context::new();
	VOID_METHOD_CALL(id->family, TO_RCD_IMP_DEFN_MTID, id, &phrcd);
	Frames::remove_current();
	return phrcd;
}

@ |TO_PHTD_IMP_DEFN_MTID| is for...

@e TO_PHTD_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(TO_PHTD_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id, ph_type_data *phtd, wording XW, wording *OW)

void ImperativeDefinitionFamilies::to_phtd(imperative_defn *id, ph_type_data *phtd, wording XW, wording *OW) {
	VOID_METHOD_CALL(id->family, TO_PHTD_IMP_DEFN_MTID, id, phtd, XW, OW);
}

@ Whether phrases which end the current rulebook are allowed in the definition body.

@e ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::goes_in_rulebooks(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID, id);
	return rv;
}

@ Whether the definition body can be empty (as when a definition of an adjective
does not go on to contain code).

@e ALLOWS_EMPTY_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_EMPTY_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::allows_empty(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_EMPTY_IMP_DEFN_MTID, id);
	return rv;
}

@ Whether the definition body can be given as |(-| inline |-)| material.

@e ALLOWS_INLINE_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_INLINE_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::allows_inline(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_INLINE_IMP_DEFN_MTID, id);
	return rv;
}

@ |COMPILE_IMP_DEFN_MTID| is for .

@e COMPILE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(COMPILE_IMP_DEFN_MTID, imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile)

void ImperativeDefinitionFamilies::compile(imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	VOID_METHOD_CALL(f, COMPILE_IMP_DEFN_MTID,
		total_phrases_compiled, total_phrases_to_compile);
}

@ |COMPILE_IMP_DEFN_MTID| is for .

@e COMPILE_AS_NEEDED_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(COMPILE_AS_NEEDED_IMP_DEFN_MTID, imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile)

void ImperativeDefinitionFamilies::compile_as_needed(imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	VOID_METHOD_CALL(f, COMPILE_AS_NEEDED_IMP_DEFN_MTID,
		total_phrases_compiled, total_phrases_to_compile);
}

@ |PHRASEBOOK_INDEX_IMP_DEFN_MTID| is for .

@e PHRASEBOOK_INDEX_IMP_DEFN_MTID

=
INT_METHOD_TYPE(PHRASEBOOK_INDEX_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::include_in_Phrasebook_index(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, PHRASEBOOK_INDEX_IMP_DEFN_MTID, id);
	return rv;
}
