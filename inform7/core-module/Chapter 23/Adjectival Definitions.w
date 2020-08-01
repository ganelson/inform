[Phrases::Adjectives::] Adjectival Definitions.

The second of four ways phrases are invoked: as definitions of
adjectives which can be used as unary predicates in the calculus. (And we also
look after adjectives arising from I6 or I7 conditions, and from I6 routines.)

@h Definitions.

@ A typical example would be:

>> Definition: A container is significant if it contains a clue.

Here the domain of the definition is "container", and the meaning assigned
to "significant" is an I7 condition; but we can also make it an I6
condition, or (a tidier way to express the same thing) delegate it to an
I6 routine. Phrases enter only when we define an adjective with an
explicit, though nameless, I7 rule:

>> Definition: A container (called the sac) is significant: if the sac contains a clue, decide yes; ...

That makes four distinct kinds of adjective, but all share the following
structure to hold details of their specific meanings:

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

@h The adjectives traverse.
The following is used to deal with adjective definitions. In the simple
example:

>> Definition: A container is significant if it contains something.

we recognise this as a definition because its preamble consists just of
that one word:

=
<definition-header> ::=
	definition

@ Having got that far, Inform descends to the body of the definition:

>> A container is significant if it contains something

and applies the following grammar. This parsing happens very early in Inform's
run, before most of the kinds are created; but eventually the text of the
domain is expected to match <k-kind>. The text of the condition in
productions (a) and (b) in <adjective-definition> can have various
different forms. For timing reasons, we don't parse it this way, but it's
as if it had to match one of the following list of choices:

(1) <measurement-adjective-definition>
(2) <inform6-routine-adjective-definition>
(3) <inform6-condition-adjective-definition>
(4) <spec-condition>

At any rate, it will eventually have to make sense, but not yet.

Production (c) here looks useless, but is intended to catch cases like
this:

>> Definition: a container is roomy rather than poky: ...

where the material at |...| is a phrase determining the truth of the
definition. (This was a very early feature of Inform, and one I think the
language could drop without much loss. No comparable feature exists for
binary predicates, so it seems odd to have it for unary predicates, and
the doubled use of colons is unfortunate.)

=
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

@ And here is the supporting code:

@d DEFINED_POSITIVELY 1
@d DEFINED_NEGATIVELY -1
@d DEFINED_PHRASALLY 0
@d DEFINED_IN_SOME_WAY_NOT_YET_KNOWN -2

=
void Phrases::Adjectives::traverse(void) {
	SyntaxTree::traverse(Task::syntax_tree(), Phrases::Adjectives::look_for_headers);
}

void Phrases::Adjectives::look_for_headers(parse_node *p) {
	if (Node::get_type(p) == RULE_NT)
		if (<definition-header>(Node::get_text(p))) {
			compilation_unit *cm = CompilationUnits::current();
			CompilationUnits::set_current(p);
			parse_node *q = (p->down)?(p->down->down):NULL;
			if (q == NULL) @<Futz with the parse tree, trying right not down@>;

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

@ The tree structure is slightly different according to whether the adjective
is defined by routine or not.

@<Futz with the parse tree, trying right not down@> =
	if ((p->next == NULL) ||
		(Node::get_type(p->next) != RULE_NT)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"don't leave me in suspense",
			"write a definition after 'Definition:'!");
		return;
	}
	q = p->next; p->next = q->next; p->down = q->down; q->next = NULL;

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
		StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_DefinitionWithoutCondition),
			q, "a definition must take the form 'Definition: a ... is ... if/unless "
			"...' or else 'Definition: a ... is ...: ...'",
			"but I can't make this fit either shape.");
		return;
	}
	if ((Wordings::mismatched_brackets(AW)) ||
		((Wordings::nonempty(NW)) && (Wordings::mismatched_brackets(NW)))) {
		LOG("Definition tree:\n$T\n", p);
		StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_BracketedAdjective),
			q, "this definition seems to involve unexpected brackets in the name of "
			"the adjective being defined",
			"so I think I must be misreading it.");
		return;
	}

@ As we've seen, adjectives can take many forms, and what we do here is to
offer the new adjective around and see if anybody claims it.

@<Register the resulting adjective@> =
	adjective_meaning *am = Adjectives::Meanings::parse(q, the_format, AW, DNW, CONW, CALLW);
	if (am == NULL) internal_error("unclaimed adjective definition");

	if (Wordings::nonempty(NW)) {
		adjective_meaning *neg = Adjectives::Meanings::negate(am);
		Adjectives::Meanings::declare(neg, NW, 5);
	}

@

@d ADJECTIVE_NAME_VETTING_LINGUISTICS_CALLBACK Phrases::Adjectives::vet_name

=
int Phrases::Adjectives::vet_name(wording W) {
	if (<article>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ArticleAsAdjective),
			"a defined adjective cannot consist only of an article such as "
			"'a' or 'the'",
			"since this will lead to parsing ambiguities.");
		return FALSE;
	}
	if (<unsuitable-name>(W)) {
		if (problem_count == 0) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AdjectivePunctuated));
			Problems::issue_problem_segment(
				"The sentence %1 seems to create an adjective with the name "
				"'%2', but adjectives have to be contain only unpunctuated "
				"words.");
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
definition *Phrases::Adjectives::def_new(parse_node *q) {
	definition *def = CREATE(definition);
	def->node = q;
	def->format = 0;
	def->condition_to_match = EMPTY_WORDING;
	def->domain_calling = EMPTY_WORDING;
	def->definition_node = current_sentence;
	return def;
}
