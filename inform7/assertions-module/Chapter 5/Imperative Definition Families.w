[ImperativeDefinitionFamilies::] Imperative Definition Families.

Different categories of imperative definition.

@h Creation.
See //Imperative Definitions// for what these families are.

There are very few of them, and an Inform source text cannot create more.
The following is called at startup, and then that's the lot.

The order of creation is important here, or at least, it's important that
the rule family comes last, because this affects the order of the loop in
//ImperativeDefinitionFamilies::identify// below.

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

@h Identification.
So, then, the rest of this section provides an API, in effect, for different
users of imperative definitions to get their work done.

|IDENTIFY_IMP_DEFN_MTID| is for deciding from the syntax of a preamble whether
this definition should belong to the family or not. The recipient should set
|id->family| to itself if it wants the definition.

@e IDENTIFY_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(IDENTIFY_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitionFamilies::identify(imperative_defn *id) {
	id->family = unknown_idf;
	imperative_defn_family *f;
	LOOP_OVER(f, imperative_defn_family)
		if (id->family == unknown_idf)
			VOID_METHOD_CALL(f, IDENTIFY_IMP_DEFN_MTID, id);
}

@h Assessment.
|ASSESS_IMP_DEFN_MTID| is for parsing the preamble in more detail, later on.
At the start of assessment, this is called on each of the IDs belonging to the
family in turn.

@e ASSESS_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(ASSESS_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitionFamilies::assess(imperative_defn *id) {
	VOID_METHOD_CALL(id->family, ASSESS_IMP_DEFN_MTID, id);
}

@ |GIVEN_BODY_IMP_DEFN_MTID| is called on an ID just after |id->body_of_defn|
has finally been created.

@e GIVEN_BODY_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(GIVEN_BODY_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

void ImperativeDefinitionFamilies::given_body(imperative_defn *id) {
	VOID_METHOD_CALL(id->family, GIVEN_BODY_IMP_DEFN_MTID, id);
}

@ Next, |REGISTER_IMP_DEFN_MTID| is then called on the family when all of the
|ASSESS_IMP_DEFN_MTID| calls have been made, and all the bodies created.

@e REGISTER_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(REGISTER_IMP_DEFN_MTID, imperative_defn_family *f)

void ImperativeDefinitionFamilies::register(imperative_defn_family *f) {
	VOID_METHOD_CALL_WITHOUT_ARGUMENTS(f, REGISTER_IMP_DEFN_MTID);
}

@ A call to |TO_RCD_IMP_DEFN_MTID| is then made for each ID in turn, asking the
family to give the body its runtime context data.

@e TO_RCD_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(TO_RCD_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id,
	id_runtime_context_data *rcd)

id_runtime_context_data ImperativeDefinitionFamilies::to_phrcd(imperative_defn *id) {
	current_sentence = id->at;
	Frames::make_current(&(id->body_of_defn->compilation_data.id_stack_frame));
	id_runtime_context_data phrcd = RuntimeContextData::new();
	VOID_METHOD_CALL(id->family, TO_RCD_IMP_DEFN_MTID, id, &phrcd);
	Frames::remove_current();
	return phrcd;
}

@ Finally, |ASSESSMENT_COMPLETE_IMP_DEFN_MTID| is called on the family when
everything has been assessed.

@e ASSESSMENT_COMPLETE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(ASSESSMENT_COMPLETE_IMP_DEFN_MTID, imperative_defn_family *f)

void ImperativeDefinitionFamilies::assessment_complete(imperative_defn_family *f) {
	VOID_METHOD_CALL_WITHOUT_ARGUMENTS(f, ASSESSMENT_COMPLETE_IMP_DEFN_MTID);
}

@h What is allowed in the body.
The body of the definition can for the most part be any Inform 7 code, but
there are a few restrictions which depend on what the definition family is.
 
|ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID| should reply |TRUE| if phrases
intended to end rules or rulebooks can be used in the body; by default, not.

@e ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID, imperative_defn_family *f,
	imperative_defn *id)

int ImperativeDefinitionFamilies::goes_in_rulebooks(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_RULE_ONLY_PHRASES_IMP_DEFN_MTID, id);
	return rv;
}

@ |ALLOWS_EMPTY_IMP_DEFN_MTID| should reply |TRUE| if the body is allowed to
be empty, that is, for there to be no code at all. This happens for some
adjective definitions which wrap up in a single line. The default is no.

@e ALLOWS_EMPTY_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_EMPTY_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::allows_empty(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_EMPTY_IMP_DEFN_MTID, id);
	return rv;
}

@ |ALLOWS_INLINE_IMP_DEFN_MTID| should reply |TRUE| if the definition body can
be given as |(-| inline |-)| material. The default is no.

@e ALLOWS_INLINE_IMP_DEFN_MTID

=
INT_METHOD_TYPE(ALLOWS_INLINE_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::allows_inline(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, ALLOWS_INLINE_IMP_DEFN_MTID, id);
	return rv;
}

@h Compilation and indexing.
|COMPILE_IMP_DEFN_MTID| is called to ask the family to perform its main round
of compilation for any resources it will need -- most obviously, of course,
it may want to turn its definition bodies into Inter functions.

@e COMPILE_IMP_DEFN_MTID

=
VOID_METHOD_TYPE(COMPILE_IMP_DEFN_MTID, imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile)

void ImperativeDefinitionFamilies::compile(imperative_defn_family *f,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	VOID_METHOD_CALL(f, COMPILE_IMP_DEFN_MTID,
		total_phrases_compiled, total_phrases_to_compile);
}

@ |PHRASEBOOK_INDEX_IMP_DEFN_MTID| should reply |TRUE| if the definition should
go into the Phrasebook page of the index.

@e PHRASEBOOK_INDEX_IMP_DEFN_MTID

=
INT_METHOD_TYPE(PHRASEBOOK_INDEX_IMP_DEFN_MTID, imperative_defn_family *f, imperative_defn *id)

int ImperativeDefinitionFamilies::include_in_Phrasebook_index(imperative_defn *id) {
	int rv = FALSE;
	INT_METHOD_CALL(rv, id->family, PHRASEBOOK_INDEX_IMP_DEFN_MTID, id);
	return rv;
}
