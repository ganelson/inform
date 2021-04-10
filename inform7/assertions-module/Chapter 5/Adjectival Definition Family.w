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
		AdjectivalDefinitionFamily::look_for_headers(id->at);
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

@


=
typedef struct definition {
	struct parse_node *definition_node; /* current sentence: where the word "Definition" is */
	struct parse_node *node; /* where the actual definition is */
	int format; /* |+1| to go by condition, |-1| to negate it, |0| to use routine */
	struct wording condition_to_match; /* text of condition to match, if |+1| or |-1| */
	struct wording domain_calling; /* what if anything the term is called */
	struct adjective_meaning *am_of_def; /* which adjective meaning */
	CLASS_DEFINITION
} definition;

@h Implementation details.
First, some Preform grammar:

=
<definition-header> ::=
	definition

<adjective-definition> ::=
	<adjective-domain> is/are <adjective-wording> if ... |      ==> { DEFINED_POSITIVELY, - }
	<adjective-domain> is/are <adjective-wording> unless ... |  ==> { DEFINED_NEGATIVELY, - }
	<adjective-domain> is/are <adjective-wording>               ==> { DEFINED_PHRASALLY, - }

<adjective-domain> ::=
	... ( called the ... ) |  ==> { 0, -, <<calling>> = TRUE }
	... ( called ... ) |      ==> { 0, -, <<calling>> = TRUE }
	...                       ==> { 0, -, <<calling>> = FALSE }

<adjective-wording> ::=
	... rather than ... |     ==> { 0, -, <<antonym>> = TRUE }
	...                       ==> { 0, -, <<antonym>> = FALSE }

@ The following function provides the method of identification:

@d DEFINED_POSITIVELY 1
@d DEFINED_NEGATIVELY -1
@d DEFINED_PHRASALLY 0
@d DEFINED_IN_SOME_WAY_NOT_YET_KNOWN -2

=
void AdjectivalDefinitionFamily::look_for_headers(parse_node *p) {
	if (Node::get_type(p) == IMPERATIVE_NT)
		if (<definition-header>(Node::get_text(p))) {
			compilation_unit *cm = CompilationUnits::current();
			CompilationUnits::set_current(p);
			parse_node *q = NULL;
			if (Node::get_type(p->next) == DEFN_CONT_NT) q = p->next;
			else q = (p->down)?(p->down->down):NULL;

			wording DNW = EMPTY_WORDING; /* domain name */
			wording CALLW = EMPTY_WORDING; /* calling */
			wording AW = EMPTY_WORDING; /* adjective name */
			wording NW = EMPTY_WORDING; /* negation name */
			wording CONW = EMPTY_WORDING; /* condition text */
			int the_format = DEFINED_IN_SOME_WAY_NOT_YET_KNOWN;

			@<Parse the Q-node as an adjective definition@>;
			@<Perform sanity checks on the result@>;
			@<Register the resulting adjective@>;

			if (the_format != DEFINED_PHRASALLY)  p->down = NULL;

			CompilationUnits::set_current_to(cm);
		}
}

@<Parse the Q-node as an adjective definition@> =
	if (<adjective-definition>(Node::get_text(q))) {
		the_format = <<r>>;
		DNW = GET_RW(<adjective-domain>, 1);
		if (<<calling>>) CALLW = GET_RW(<adjective-domain>, 2);
		AW = GET_RW(<adjective-wording>, 1);
		if (<<antonym>>) NW = GET_RW(<adjective-wording>, 2);
		if (the_format != DEFINED_PHRASALLY)
			CONW = GET_RW(<adjective-definition>, 1);
	}

@<Perform sanity checks on the result@> =
	if ((the_format == DEFINED_IN_SOME_WAY_NOT_YET_KNOWN) ||
		((the_format == DEFINED_PHRASALLY) && (q->down == NULL))) {
		LOG("Definition tree (%d):\n$T\n", the_format, q);
		StandardProblems::definition_problem(Task::syntax_tree(),
			_p_(PM_DefinitionWithoutCondition),
			q, "a definition must take the form 'Definition: a ... is ... if/unless "
			"...' or else 'Definition: a ... is ...: ...'",
			"but I can't make this fit either shape.");
		return;
	}
	if ((Wordings::mismatched_brackets(AW)) ||
		((Wordings::nonempty(NW)) && (Wordings::mismatched_brackets(NW)))) {
		LOG("Definition tree:\n$T\n", p);
		StandardProblems::definition_problem(Task::syntax_tree(),
			_p_(PM_BracketedAdjective),
			q, "this definition seems to involve unexpected brackets in the name of "
			"the adjective being defined",
			"so I think I must be misreading it.");
		return;
	}

@<Register the resulting adjective@> =
	current_sentence = q;
	adjective_meaning *am = AdjectiveMeanings::claim_definition(q, the_format, AW,
		DNW, CONW, CALLW);
	if (am == NULL) internal_error("unclaimed adjective definition");
	if (Wordings::nonempty(NW)) {
		current_sentence = q;
		adjective *adj = Adjectives::declare(NW, NULL);
		adjective_meaning *neg = AdjectiveMeanings::negate(am);
		AdjectiveAmbiguity::add_meaning_to_adjective(neg, adj);
	}

@ The usual strictures apply:

@d ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK AdjectivalDefinitionFamily::vet_name

=
int AdjectivalDefinitionFamily::vet_name(wording W) {
	if (<article>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ArticleAsAdjective),
			"a defined adjective cannot consist only of an article such as 'a' or 'the'",
			"since this will lead to parsing ambiguities.");
		return FALSE;
	}
	if (<unsuitable-name>(W)) {
		if (problem_count == 0) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_AdjectivePunctuated));
			Problems::issue_problem_segment(
				"The sentence %1 seems to create an adjective with the name '%2', but "
				"adjectives have to be contain only unpunctuated words.");
			Problems::issue_problem_end();
		}
		return FALSE;
	}
	LOOP_THROUGH_WORDING(n, W)
		NTI::mark_word(n, <s-adjective>);
	return TRUE;
}

@ Which leaves only:

=
definition *AdjectivalDefinitionFamily::new_definition(parse_node *q) {
	definition *def = CREATE(definition);
	def->node = q;
	def->format = 0;
	def->condition_to_match = EMPTY_WORDING;
	def->domain_calling = EMPTY_WORDING;
	def->definition_node = current_sentence;
	return def;
}
