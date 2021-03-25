[AdjectivalDefinitionFamily::] Adjectival Definition Family.

Imperative definitions of "Definition: X is Y: ..." adjectives.

@

= (early code)
imperative_defn_family *DEFINITIONAL_PHRASE_EFF_family = NULL; /* "Definition: a container is roomy if: ..." */

@

=
void AdjectivalDefinitionFamily::create_family(void) {
	DEFINITIONAL_PHRASE_EFF_family  = ImperativeDefinitions::new_family(I"DEFINITIONAL_PHRASE_EFF");
	METHOD_ADD(DEFINITIONAL_PHRASE_EFF_family, CLAIM_IMP_DEFN_MTID, AdjectivalDefinitionFamily::claim);
	METHOD_ADD(DEFINITIONAL_PHRASE_EFF_family, NEW_PHRASE_IMP_DEFN_MTID, AdjectivalDefinitionFamily::new_phrase);
}

@ =
<definition-preamble> ::=
	definition

@ =
void AdjectivalDefinitionFamily::claim(imperative_defn_family *self, imperative_defn *id) {
	wording W = Node::get_text(id->at);
	if (<definition-preamble>(W)) {
		id->family = DEFINITIONAL_PHRASE_EFF_family;
		if ((id->at->next) && (id->at->down == NULL) &&
			(Node::get_type(id->at->next) == IMPERATIVE_NT)) {
			ImperativeSubtrees::accept_body(id->at->next);
			Node::set_type(id->at->next, DEFN_CONT_NT);
		}
		Phrases::Adjectives::look_for_headers(id->at);
	}
}

@ If a phrase defines an adjective, like so:

>> Definition: A container is capacious if: ...

we need to make the pronoun "it" a local variable of kind "container" in the
stack frame used to compile the "..." part. If it uses a calling, like so:

>> Definition: A container (called the sack) is capacious if: ...

then we also want the name "sack" to refer to this. Here's where we take care
of it:

=
void AdjectivalDefinitionFamily::new_phrase(imperative_defn_family *self, imperative_defn *id, phrase *new_ph) {
	wording CW = EMPTY_WORDING;
	kind *K = NULL;
	Phrases::Phrasal::define_adjective_by_phrase(id->at, new_ph, &CW, &K);
	LocalVariables::add_pronoun(&(new_ph->stack_frame), CW, K);
}
