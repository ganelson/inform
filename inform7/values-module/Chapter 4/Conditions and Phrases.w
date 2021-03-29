[SPCond::] Conditions and Phrases.

To parse the text of To... phrases, say phrases and conditions.

@h Conditions.
In Inform syntax, a condition is an excerpt of text which measures the truth of
something. We will call it "pure" if it is self-sufficient, rather than
referring anaphorically to some implied subject. For instance, "if the bucket
is an open container" contains a pure condition, but "if an open container"
is impure. We are very wary of impure conditions, and don't allow the
logical operations or chronological restrictions to apply to them. So the
only valid impure conditions are description noun phrases.

=
<s-condition-uncached> ::=
	<s-cond-pure> |                     ==> { pass 1 }
	<s-descriptive-np>                  ==> { pass 1 }

@ Now for pure conditions. Note that logical "and" and "or" are implemented
directly right here, rather than being phrases defined in the Standard Rules,
and that they aren't the same as the "and" and "or" used a list dividers.

=
<s-cond-pure> ::=
	( <s-cond-pure> ) |                 ==> { pass 1 }
	<s-cond-pure> , and <s-cond-pure> | ==> { -, Conditions::new_LOGICAL_AND(RP[1], RP[2]) }
	<s-cond-pure> and <s-cond-pure> |   ==> { -, Conditions::new_LOGICAL_AND(RP[1], RP[2]) }
	<s-cond-pure> , or <s-cond-pure> |  ==> { -, Conditions::new_LOGICAL_OR(RP[1], RP[2]) }
	<s-cond-pure> or <s-cond-pure> |    ==> { -, Conditions::new_LOGICAL_OR(RP[1], RP[2]) }
	<s-cond-with-chronology> |          ==> { pass 1 }
	<s-cond-atomic>                     ==> { pass 1 }

@ Chronological restrictions include, for instance,

>> if the gate is open for the first time, ...

where the condition is divided as

>> if the gate is open / for the first time

and <s-cond-atomic> is used to parse the first half. While it's possible
to express this in Preform grammar, the result doesn't run quickly, so the
following implements this as a hand-coded nonterminal instead.

=
<s-cond-with-chronology> internal {
	#ifdef IF_MODULE
	time_period *tp = Occurrence::parse(W);
	if (tp) {
		wording RW = Occurrence::unused_wording(tp);
		if ((Wordings::nonempty(RW)) && (<s-cond-atomic>(RW))) {
			parse_node *atomic_cnd = <<rp>>;
			parse_node *spec = atomic_cnd;
			if (Node::is(spec, CONSTANT_NT)) {
				action_pattern *ap = ARvalues::to_action_pattern(spec);
				spec = AConditions::new_action_TEST_VALUE(ap, W);
			}
			==> { -, Conditions::attach_historic_requirement(spec, tp) };
			return TRUE;
		}
	}
	#endif
	==> { fail nonterminal };
}

@ The syntax for the logical operation "not" is more complicated, because
it only sometimes work by simply preceding the text with "not". Consider
this, for instance:

>> if not we are carrying the torch, ...

As a result, we can't handle negation in <s-cond-pure>, and have to
work into the grammar below on a case by case basis. And where we do allow
"not", we always check the positive sense first -- people do sometimes
create phrase options like "not printing anything", for example, which
begin with the word "not".

As a condition, an action pattern is implicitly considered as a test of
what the current action is:

>> if examining an open door, ...

This wouldn't work so well for the past tense form:

>> if examined an open door, ...

because it seems too clunky as neither quite active nor passive. Who examined
the open door? So Inform uses the following version instead:

>> if we have examined an open door, ...

thus adopting the "science we". Not very elegant, but the alternatives were
difficult to parse. "We are" is allowed for consistency's sake, but does
nothing, i.e., "we are taking" and "taking" are synonymous. Translators
to other languages may want to find more elegant solutions.

=
<s-cond-atomic> ::=
	<s-phrase-option-in-use> |                      ==> { pass 1 }
	not <s-phrase-option-in-use> |                  ==> { -, Conditions::negate(RP[1]) }
	<s-nonexistential-phrase-to-decide> |           ==> { pass 1 }
	<s-past-action-pattern-as-condition> |          ==> { pass 1 }
	<s-past-action-pattern-as-negated-condition> |  ==> { -, Conditions::negate(RP[1]) }
	<s-action-pattern-as-condition> |               ==> { pass 1 }
	<s-action-pattern-as-negated-condition> |       ==> { -, Conditions::negate(RP[1]) }
	<s-sentence> |                                  ==> { pass 1 }
	<s-existential-phrase-to-decide>                ==> { pass 1 }

@ As before, we try to get better sensitivity to ambiguities by dividing the
test for a phrase-to-decide into two, so that the following is used at a
different point if the excerpt begins "there is" than if it doesn't. The
point of this is that some phrases to decide have wording which coincides
with a description, and in general the phrase should win, but in the case
of "there is" we make the presumption that the author intends a sentence
testing the existence of something.

=
<s-nonexistential-phrase-to-decide> ::=
	<existential-verb-phrase> |   ==> { fail }
	<s-phrase-to-decide> |        ==> { pass 1 }
	not <s-phrase-to-decide>      ==> { -, Conditions::negate(RP[1]) }

<s-existential-phrase-to-decide> ::=
	^<existential-verb-phrase> |  ==> { fail }
	<s-phrase-to-decide> |        ==> { pass 1 }
	not <s-phrase-to-decide>      ==> { -, Conditions::negate(RP[1]) }

<existential-verb-phrase> ::=
	<np-existential> is/are ...

<s-phrase-to-decide> internal {
	parse_node *p = Lexicon::retrieve(COND_PHRASE_MC, W);
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		SPCond::add_ilist(spec, p);
		parse_node *tval = Node::new_with_words(TEST_VALUE_NT, W);
		tval->down = spec;
		==> { -, tval };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ The following only matches the phrase option names for the phrase currently
being compiled; all others are out of scope.

=
<s-phrase-option-in-use> internal {
	if (id_body_being_compiled) {
		int i = PhraseOptions::parse(id_body_being_compiled, W);
		if (i >= 0) {
			==> { -, Conditions::new_TEST_PHRASE_OPTION(i) };
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

@h Command phrases.
The final clutch of nonterminals in the S-grammar handles individual commands,
written in their semicolon-divided list in the body of a rule or "To..."
definition. For instance, in the not very sensible rule:

>> Instead of jumping: now the score is 10; say "Greetings!" instead.

Inform will use <s-command> to parse the text of the two commands in the rule
body. <s-command> parses the text with little attempt to judge whether the
parameters of the phrase match; it simply records possibilities for
typechecking to choose between much later on.

=
<s-command> ::=
	( <s-command> ) |                            ==> { pass 1 }
	<s-to-phrase>                                ==> { pass 1 }

<s-say-command> ::=
	( <s-say-command> ) |                        ==> { pass 1 }
	<s-adaptive-text> |                          ==> { pass 1 }
	<s-text-substitution>                        ==> { pass 1 }

<s-adaptive-text> ::=
	<s-local-variable> |                         ==> { fail }
	<adaptive-verb> verb |                       ==> { -, SPCond::say_verb(RP[1], R[1], NULL, W) }
	<adaptive-adjective> adjective |             ==> { -, SPCond::say_adjective(RP[1], W) }
	<adaptive-verb> |                            ==> { -, SPCond::say_verb(RP[1], R[1], NULL, W) }
	<modal-verb> <adaptive-verb-infinitive> verb | ==> @<Annotate the verb with a modal@>
	<modal-verb> <adaptive-verb-infinitive> |    ==> @<Annotate the verb with a modal@>
	<adaptive-adjective>                         ==> { -, SPCond::say_adjective(RP[1], W) }

<adaptive-adjective> internal {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL))
		return FALSE;
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		wording AW = Clusters::get_form_general(adj->adjective_names,
			Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::match(AW, W)) {
			==> { FALSE, adj};
			return TRUE;
		}
	}
	==> { fail nonterminal };
}

@ "To..." phrases are easy, or at least, easy to delegate:

=
<s-to-phrase> internal {
	parse_node *p = Lexicon::retrieve(VOID_PHRASE_MC, W);
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		SPCond::add_ilist(spec, p);
		==> { -, spec };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ =
<s-text-substitution> internal {
	parse_node *p = Lexicon::retrieve(SAY_PHRASE_MC, W);
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		SPCond::add_ilist(spec, p);
		==> { -, spec };
		return TRUE;
	}
	==> { fail nonterminal };
}

@<Annotate the verb with a modal@> =
	int neg = FALSE;
	if ((R[1]) || (R[2])) neg = TRUE;
	==> { -, SPCond::say_verb(RP[2], neg, RP[1], W) };

@ Invocation nodes for adaptive-text adjectives hold references to their masculine
singulars.

=
parse_node *SPCond::say_adjective(adjective *aph, wording W) {
	parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
	parse_node *inv = Invocations::new();
	Invocations::set_word_range(inv, W);
	Invocations::set_adjective(inv, aph);
	spec->down = Node::new(INVOCATION_LIST_NT);
	spec->down->down = Invocations::add_to_list(spec->down->down, inv);
	return spec;
}

@ Invocation nodes for adaptive-text verbs hold references to their first
person plurals.

=
parse_node *SPCond::say_verb(verb_conjugation *vc, int neg, verb_conjugation *mvc, wording W) {
	parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
	parse_node *inv = Invocations::new();
	Invocations::set_word_range(inv, W);
	Invocations::set_verb_conjugation(inv, vc, mvc, neg);
	spec->down = Node::new(INVOCATION_LIST_NT);
	spec->down->down = Invocations::add_to_list(spec->down->down, inv);
	return spec;
}

@ There are three basic kinds of phrase: those used as commands
(i.e., void procedures in C terms), those used as values (returning values
other than true/false) and those used as conditions (returning true or false).
These are stored in a way making basically the same use of a specification's
references, so all three are handled by the following code.

The usage of a phrase is called an "invocation" of it, and sometimes more than
one invocation appears, for two reasons: a "say" phrase can contain a sequence
of invocations to follow, one after another; and sometimes it will only be clear
at run-time which of several possible definitions is to apply, so the
possibilities will all be invoked.

=
void SPCond::add_ilist(parse_node *spec, parse_node *p) {
	@<Build the invocation list@>;

	int len = Invocations::length_of_list(spec->down->down);
	if (len >= MAX_INVOCATIONS_PER_PHRASE)
		@<Issue overcomplicated phrase problem message@>
	else if (len > 0)
		spec->down->down = Invocations::sort_list(spec->down->down);
}

@ There are multiple invocations, each produced from another node in the
S-tree as we run sideways through the alternative readings.

@<Build the invocation list@> =
	for (; p; p = p->next_alternative) {
		id_body *idb = RETRIEVE_POINTER_id_body(
			Lexicon::get_data(Node::get_meaning(p)));
		parse_node *inv = Phrases::Parser::parse_against(idb, p);
		if ((IDTypeData::is_the_primordial_say(&(idb->type_data)) == FALSE) &&
			(Rvalues::is_CONSTANT_of_kind(
				Invocations::get_token_as_parsed(inv, 0), K_text)))
			continue;
		if (spec->down == NULL) {
			spec->down = Node::new(INVOCATION_LIST_NT);
			Node::set_text(spec->down, Node::get_text(spec));
		}
		spec->down->down = Invocations::add_to_list(spec->down->down, inv);
	}

@ This problem used to be experienced for long say phrases in a situation
where many kinds of value have been created, so that "say V" for a value V
was heavily ambiguous -- pumping up the number of invocations generated. In
2010, the introduction of generics into Inform made it possible to define
"say V" just once, and after that it became so difficult to reach this
limit that we were unable to construct a test case for it.

@<Issue overcomplicated phrase problem message@> =
	spec->down->down->next = NULL; /* truncate to just one */
	Node::set_text(spec, Node::get_text(current_sentence));
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"In %1, the phrase being constructed is just too "
		"long and complicated, and will need to be simplified. (This "
		"sometimes happens with a 'say', or a piece of text, containing "
		"many text substitutions in succession: if so, it may be worth "
		"defining some more powerful text substitutions - for instance "
		"writing 'To say super-duper: ...', giving the gory details, "
		"and then using the single substitution '[super-duper]' in the "
		"original phrase.");
	Problems::issue_problem_end();
