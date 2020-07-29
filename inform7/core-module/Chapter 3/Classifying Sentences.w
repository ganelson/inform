[Classifying::] Classifying Sentences.

To work out the verbs used and to diagram sentences in the source.

@h Traversing for primary verbs.
The story so far: the //supervisor// module has arranged for the source
text to be read in by //words// and has made a rudimentary parse tree for
it using //syntax//. Certain "structural" sentences, such as headings, have
been taken care of, and turned into nodes with types like |HEADING_NT|.

But the assertions we want to read -- such as "The Mona Lisa is in the Louvre",
or "The plural of major general is majors general" -- are all simply
|SENTENCE_NT| nodes with no children. The following traverse begins Inform's
compilation process in earnest: for each such |SENTENCE_NT| node, it asks
the //linguistics// module to identify a primary verb, noun phrases and so
on, placing them in a subtree.

=
int classification_traverse_done = FALSE;

void Classifying::traverse(void) {
	SyntaxTree::traverse(Task::syntax_tree(), Classifying::visit);
	classification_traverse_done = TRUE;
}

void Classifying::visit(parse_node *p) {
	if (Node::get_type(p) == TRACE_NT) {
		SyntaxTree::toggle_trace(Task::syntax_tree());
		Log::tracing_on(SyntaxTree::is_trace_set(Task::syntax_tree()), I"Diagramming");
	}
	if (Node::get_type(p) == SENTENCE_NT) {
		Classifying::sentence(p);
		Sentences::Rearrangement::check_sentence_for_direction_creation(p);
	}
}

@ Certain extra sentences, called "inventions", are sometimes created after
that traverse takes place: those extra |SENTENCE_NT| nodes therefore won't
be caught. Extra sentences can happen in two ways:

(a) When additional text is fed to the lexer and sentence-broken by the
//syntax// module, at which point //syntax// calls the function below
because we have given it as a callback.

(b) When explicit rearrangement of the tree causes new |SENTENCE_NT| nodes
to be created. Any code doing this should call the following function
explicitly.

@d NEW_NONSTRUCTURAL_SENTENCE_SYNTAX_CALLBACK Classifying::visit_extra_sentence

=
void Classifying::visit_extra_sentence(parse_node *new) {
	if (classification_traverse_done) Classifying::sentence(new);
}

@h Textual sentences.
"Textual" sentences are not really sentences at all, and are just double-quoted
text used in isolation -- Inform sometimes recognises these as being implicit
property values, as for the description of a room just created. These sentences
are necessarily exempt from having a primary verb.

=
int Classifying::sentence_is_textual(parse_node *p) {
	if ((Wordings::length(Node::get_text(p)) == 1) &&
			(Vocabulary::test_flags(
				Wordings::first_wn(Node::get_text(p)), TEXT_MC+TEXTWITHSUBS_MC)))
		return TRUE;
	return FALSE;
}

@h Classifying a single sentence.
Every |SENTENCE_NT| node, however it is constructed, therefore ends up here,
and we ask the //linguistics// module to "diagram" it.

See //linguistics: About Sentence Diagrams// for many examples.

=
void Classifying::sentence(parse_node *p) {
	if (Classifying::sentence_is_textual(p) == FALSE) {
		wording W = Node::get_text(p);
		if (<sentence-without-occurrences>(W)) {
			parse_node *VP_PN = <<rp>>;
			switch (Annotations::read_int(VP_PN, linguistic_error_here_ANNOT)) {
				case TwoLikelihoods_LINERROR: @<Issue PM_TwoLikelihoods problem@>; break;
			}
			SyntaxTree::graft(Task::syntax_tree(), VP_PN, p);
			if (SyntaxTree::is_trace_set(Task::syntax_tree())) LOG("$T\n", p);
			@<Check that this is allowed, if it occurs in the Options file@>;
		} else {
			LOG("$T\n", p);
			<no-primary-verb-diagnosis>(W);
		}
	}
}

@<Issue PM_TwoLikelihoods problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TwoLikelihoods),
		"this sentence seems to have a likelihood qualification on both "
		"sides of the verb",
		"which is not allowed. 'The black door certainly is usually open' "
		"might possibly be grammatical English in some idioms, but Inform "
		"doesn't like a sentence in this shape because the 'certainly' "
		"on one side of the verb and the 'usually' on the other are "
		"rival indications of certainty.");

@ Only special-meaning sentences are allowed in Options files, and not all
of those.

@<Check that this is allowed, if it occurs in the Options file@> =
	if (Wordings::within(Node::get_text(p), options_file_wording)) {
		special_meaning_holder *sm = Node::get_special_meaning(p->down);
		if ((sm == NULL) ||
			(SpecialMeanings::call(sm, ALLOW_IN_OPTIONS_FILE_SMFT, NULL, NULL) == FALSE))
			StandardProblems::unlocated_problem(Task::syntax_tree(),
				_p_(BelievedImpossible), /* not convenient to test automatically, anyway */
				"The options file placed in this installation of Inform's folder "
				"is incorrect, making use of a sentence form which isn't allowed "
				"in that situation. The options file is only allowed to contain "
				"use options, Test ... with..., and Release along with... "
				"instructions.");
	}

@ From the earliest beta-testing, the problem message for "I can't find a verb"
split into cases. Inform is quite sensitive to punctuation errors as between
comma, paragraph break and semicolon, and this is where that sensitivity begins
to bite. The grammar below is just a set of heuristics, really: once we enter
this, a problem message of some kind will certainly result.

=
<no-primary-verb-diagnosis> ::=
	... <no-primary-verb-diagnosis-tail> |
	before/every/after/when/instead/check/carry/report ... | ==> @<Issue PM_RuleWithoutColon problem@>
	if ... |												 ==> @<Issue PM_IfOutsidePhrase problem@>
	... , ... |												 ==> @<Issue PM_NoSuchVerbComma problem@>
	...														 ==> @<Issue PM_NoSuchVerb problem@>

<no-primary-verb-diagnosis-tail> ::=
	<rc-marker> <certainty> <nonimperative-verb> ... |  ==> { advance Wordings::delta(WR[1], W) }
	<rc-marker> <nonimperative-verb> ... |              ==> { advance Wordings::delta(WR[1], W) }
	<past-tense-verb> ... |                             ==> @<Issue PM_NonPresentTense problem@>
	<negated-verb> ...                                  ==> @<Issue PM_NegatedVerb1 problem@>

@<Issue PM_RuleWithoutColon problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RuleWithoutColon),
		"I can't find a verb that I know how to deal with, so can't do anything "
		"with this sentence. It looks as if it might be a rule definition",
		"but if so then it is lacking the necessary colon (or comma). "
		"The punctuation style for rules is 'Rule conditions: do this; "
		"do that; do some more.' Perhaps you used a full stop instead "
		"of the colon?");

@<Issue PM_IfOutsidePhrase problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_IfOutsidePhrase),
		"I can't find a verb that I know how to deal with. This looks like an 'if' "
		"phrase which has slipped its moorings",
		"so I am ignoring it. ('If' phrases, like all other such "
		"instructions, belong inside definitions of rules or phrases - "
		"not as sentences which have no context. Maybe a full stop or a "
		"skipped line was accidentally used instead of semicolon, so that you "
		"inadvertently ended the last rule early?)");

@<Issue PM_NoSuchVerbComma problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchVerbComma));
	Problems::issue_problem_segment(
		"In the sentence %1, I can't find a verb that I know how to deal with. "
		"(I notice there's a comma here, which is sometimes used to abbreviate "
		"rules which would normally be written with a colon - for instance, "
		"'Before taking: say \"You draw breath.\"' can be abbreviated to 'Before "
		"taking, say...' - but that's only allowed for Before, Instead and "
		"After rules. I mention all this in case you meant this sentence "
		"as a rule in some rulebook, but used a comma where there should "
		"have been a colon ':'?)");
	Problems::issue_problem_end();

@<Issue PM_NoSuchVerb problem@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoSuchVerb));
	Problems::issue_problem_segment(
		"In the sentence %1, I can't find a verb that I know how to deal with.");
	Problems::issue_problem_end();

@<Issue PM_NonPresentTense problem@> =
	if (Annotations::read_int(current_sentence, verb_problem_issued_ANNOT) == FALSE) {
		Annotations::write_int(current_sentence, verb_problem_issued_ANNOT, TRUE);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonPresentTense),
			"assertions about the initial state of play must be given in the "
			"present tense",
			"so 'The cat is in the basket' is fine but not 'The cat has been in "
			"the basket'. Time is presumed to start only when the game begins, so "
			"there is no anterior state which we can speak of.");
	}

@<Issue PM_NegatedVerb1 problem@> =
	if (Annotations::read_int(current_sentence, verb_problem_issued_ANNOT) == FALSE) {
		Annotations::write_int(current_sentence, verb_problem_issued_ANNOT, TRUE);
		StandardProblems::negative_sentence_problem(Task::syntax_tree(), _p_(PM_NegatedVerb1));
	}
