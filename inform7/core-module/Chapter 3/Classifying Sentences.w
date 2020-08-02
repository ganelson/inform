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
	if (Node::get_type(p) == SENTENCE_NT) Classifying::sentence(p);
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
	parse_node *save = current_sentence;
	current_sentence = p;
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
			#ifdef IF_MODULE
			PL::MapDirections::look_for_direction_creation(p);
			#endif
			PropertySentences::look_for_property_creation(p);
			@<Issue problem message if either subject or object contains mismatched brackets@>;
			@<Issue problem message if subject starts with double-quoted literal text@>;
			if ((VP_PN->next) && (VP_PN->next->next) && (Assertions::Copular::possessive(VP_PN->next->next)))
				@<Diagram property callings@>;
		} else {
			LOG("$T\n", p);
			<no-primary-verb-diagnosis>(W);
		}
	}
	current_sentence = save;
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
			(SpecialMeanings::call(sm, ALLOW_IN_OPTIONS_FILE_SMFT, NULL, NULL) == FALSE)) {
			StandardProblems::unlocated_problem(Task::syntax_tree(),
				_p_(BelievedImpossible), /* not convenient to test automatically, anyway */
				"The options file placed in this installation of Inform's folder "
				"is incorrect, making use of a sentence form which isn't allowed "
				"in that situation. The options file is only allowed to contain "
				"use options, Test ... with..., and Release along with... "
				"instructions.");
			return;
		}
	}

@ The //linguistics// module no longer makes sentence diagrams with this defect,
so the following problem ought now to be impossible to generate. But I'm leaving
the test here in case of future changes.

@<Issue problem message if either subject or object contains mismatched brackets@> =
	if ((VP_PN->next) && (VP_PN->next->next)) {
		if ((Wordings::mismatched_brackets(Node::get_text(VP_PN->next))) ||
			(Wordings::mismatched_brackets(Node::get_text(VP_PN->next->next)))) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2,
				Wordings::one_word(Wordings::last_wn(Node::get_text(VP_PN->next)) + 1));
			Problems::quote_wording(3, Node::get_text(VP_PN->next));
			Problems::quote_wording(4, Node::get_text(VP_PN->next->next));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
			if (Wordings::nonempty(Node::get_text(VP_PN->next->next)))
				Problems::issue_problem_segment(
					"I must be misreading the sentence %1. The verb "
					"looks to me like '%2', but then the brackets don't "
					"match in what I have left: '%3' and '%4'.");
			else
				Problems::issue_problem_segment(
					"I must be misreading the sentence %1. The verb "
					"looks to me like '%2', but then the brackets don't "
					"match in what I have left: '%3'.");
			Problems::issue_problem_end();
			return;
		}
	}

@ This is a pragmatic sort of problem message. A priori, assertion sentences
like this might be okay, but in practice they cannot be useful and are far
more likely to occur as a result of something like:

>> "This is a dining room" East is the Ballroom.

where the lack of a closing full stop in the quoted text means that //linguistics//
read this as one single sentence, equating |"This is a dining room" East|
with |the Ballroom|.

Special-meaning sentences are exempt; this is needed because subject phrases
for "Understand ... as ..." are indeed sometimes multiword clauses the first
word of which is quoted.

@<Issue problem message if subject starts with double-quoted literal text@> =
	special_meaning_holder *sm = Node::get_special_meaning(VP_PN);
	if ((sm == NULL)
		&& (Wordings::length(Node::get_text(VP_PN->next)) > 1)
		&& (Vocabulary::test_flags(
			Wordings::first_wn(Node::get_text(VP_PN->next)), TEXT_MC+TEXTWITHSUBS_MC))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextNotClosing),
			"it looks as if perhaps you did not intend that to read as a "
			"single sentence",
			"and possibly the text in quotes was supposed to stand as "
			"as a sentence on its own? (The convention is that if text "
			"ends in a full stop, exclamation or question mark, perhaps "
			"with a close bracket or quotation mark involved as well, then "
			"that punctuation mark also closes the sentence to which the "
			"text belongs: but otherwise the words following the quoted "
			"text are considered part of the same sentence.)");
		return;
	}

@ Here |py| is a |CALLED_NT| subtree for "an A called B", which we relabel
as a |PROPERTYCALLED_NT| subtree and hang beneath an |ALLOWED_NT| node;
or else it's a property or list of properties, as in "carrying capacity 7".

@<Diagram property callings@> =
	parse_node *px = VP_PN->next;
	parse_node *py = VP_PN->next->next->down;
	if (Node::get_type(py) == CALLED_NT) {
		if (Wordings::match(Node::get_text(py->down->next), Node::get_text(py->down))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SuperfluousCalled),
				"'called' should be used only when the name is different from the kind",
				"so this sentence should be simplified. For example, 'A door has a "
				"colour called colour' should be written more simply as 'A door has "
				"a colour'; but 'called' can be used for something like 'A door has "
				"a number called the street number'.");
			return;
		}
		Node::set_type(py, PROPERTYCALLED_NT);
		if (Node::get_type(py->down) == AND_NT) {
internal_error("Og yeah?");
			int L = Node::left_edge_of(py->down),
				R = Node::right_edge_of(py->down);
			<np-articled>(Wordings::new(L, R));
			parse_node *pn = <<rp>>;
			pn->next = py->down->next;
			py->down = pn;
			LOG("Thus $T", py);
		}
		px->next = Node::new(ALLOWED_NT);
		px->next->down = py;
		int prohibited = <prohibited-property-owners>(Node::get_text(px));
		if (!prohibited) {
			<np-articled-list>(Node::get_text(py->down->next));
			py->down->next = <<rp>>;
		}
	} else {
		Node::set_type(py, PROPERTY_LIST_NT);
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

@ The following is needed to handle something like "colour of the box",
where "colour" is a property name. We must be careful, though, to avoid
confusion with variable declarations:

>> The interesting var is a description of numbers that varies.

which would otherwise be misread as an attempt to set the "description"
property of something.

@d ALLOW_OF_LINGUISTICS_CALLBACK Classifying::allow_of

=
<allow-of-x> ::=
	in the presence |    ==> { fail }
	<property-name-v>    ==> { -, - }

<allow-of-y> ::=
	... that varies |    ==> { fail}
	... variable |       ==> { fail }
	...                  ==> { -, - }

@ =
int Classifying::allow_of(wording XW, wording YW) {
	if ((<allow-of-x>(XW)) && (<allow-of-y>(YW))) return TRUE;
	return FALSE;
}
