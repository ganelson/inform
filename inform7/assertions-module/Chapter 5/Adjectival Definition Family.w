[AdjectivalDefinitionFamily::] Adjectival Definition Family.

Imperative definitions of "Definition: X is Y: ..." adjectives.

@ This family is used for adjective definitions, whether or not they run on
into substantial amounts of code.

=
imperative_defn_family *adjectival_idf = NULL; /* "Definition: a container is roomy if: ..." */

void AdjectivalDefinitionFamily::create_family(void) {
	adjectival_idf  = ImperativeDefinitionFamilies::new(I"adjectival-idf", FALSE);
	METHOD_ADD(adjectival_idf, IDENTIFY_IMP_DEFN_MTID, AdjectivalDefinitionFamily::identify);
	METHOD_ADD(adjectival_idf, GIVEN_BODY_IMP_DEFN_MTID, AdjectivalDefinitionFamily::given_body);
	METHOD_ADD(adjectival_idf, ALLOWS_EMPTY_IMP_DEFN_MTID, AdjectivalDefinitionFamily::allows_empty);
	METHOD_ADD(adjectival_idf, COMPILE_IMP_DEFN_MTID, AdjectivalDefinitionFamily::compile);
}

@ Colons are used slightly differently in some adjectival definitions. Consider:
= (text as Inform 7)
Definition: A container is roomy if its carrying capacity is greater than 10.
Definition: A container is possessed by the Devil:
	if its carrying capacity is 666, decide yes;
	decide no.
=
To Inform this looks like three consecutive |IMPERATIVE_NT| nodes:
= (text as Inform 7)
Definition:
	A container is roomy if its carrying capacity is greater than 10.

Definition:

A container is possessed by the Devil:
	if its carrying capacity is 666, decide yes;
	decide no.
=
But we want to create just two //imperative_defn// objects, not three. So
when the second |IMPERATIVE_NT| node is identified as belonging to us, we
take the opportunity to change the type of the third node to |DEFN_CONT_NT|
("definition continuation"). That means it will not lead to an //imperative_defn//
of its own.

@ =
<definition-preamble> ::=
	definition

@ =
void AdjectivalDefinitionFamily::identify(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<definition-preamble>(W)) {
		id->family = adjectival_idf;
		if ((id->at->next) && (id->at->down == NULL) &&
			(Node::get_type(id->at->next) == IMPERATIVE_NT)) {
			ImperativeSubtrees::accept_body(id->at->next);
			Node::set_type(id->at->next, DEFN_CONT_NT);
		}
		Phrases::Adjectives::look_for_headers(id->at);
	}
}

@ Since the "Definition:" node might have no code under it (because the code
is actually under the continuation node):

=
int AdjectivalDefinitionFamily::allows_empty(imperative_defn_family *self, imperative_defn *id) {
	return TRUE;
}

@ The body of code under a definition needs to be set up so that:
(*) The code expects to make a yes/no decision;
(*) The pronoun "it" is a local variable referring to the value being tested,
perhaps also with a calling -- consider the example "Definition: A
container (called the sack) is capacious if...".

=
void AdjectivalDefinitionFamily::given_body(imperative_defn_family *self, imperative_defn *id) {
	id_body *body = id->body_of_defn;

	IDTypeData::set_mor(&(body->type_data), DECIDES_CONDITION_MOR, NULL);

	wording CALLW = EMPTY_WORDING;
	kind *K = NULL;
	Phrases::Phrasal::define_adjective_by_phrase(id->at, body, &CALLW, &K);
	Frames::enable_it(&(body->compilation_data.id_stack_frame), CALLW, K);

}

@ The code body for any definition is compiled here:

=
void AdjectivalDefinitionFamily::compile(imperative_defn_family *self,
	int *total_phrases_compiled, int total_phrases_to_compile) {
	imperative_defn *id;
	LOOP_OVER(id, imperative_defn)
		if (id->family == adjectival_idf)
			IDCompilation::compile(id->body_of_defn, total_phrases_compiled,
				total_phrases_to_compile, NULL, NULL);
	RTAdjectives::compile_support_code();
}
