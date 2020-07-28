[Sentences::VPs::] Nonstructural Sentences.

To construct verb-phrase nodes in the parse tree.

@h Definitions.

@ At this point in the narrative, we have read files from disc, lexed the text
into a stream of words, and broken this into a list of sentences; we have
identified requests to include extensions, and fully acted on these, so that
we can now forget about that whole complication; and we have built a tree
of headings and subheadings (and file divisions) so that we have a clear map
of the overall structure of the source text. Sentences intended for use only
in some circumstances (for instance, when compiling for the Glulx virtual
machine) have been omitted as necessary, so that we can forget about that
complication, too.

This gives as much information as we can squeeze out by easily specified
mechanical means: we have attacked the text at the very small scale, letters
and words, and at the very large, headings and files. This zig-zag in scale
will continue. In the rest of this chapter, we find the overall structure of
sentences.

@ The parse tree is currently a long, long list: each sentence is a node
which is a child of the root, but no sentence has any child nodes of its own.
(That is about to change.) We can divide these sentences into three:

(a) Structural sentences -- headings, extension requests, extension bookends.
All these have now been dealt with.

(b) Sentences inside rules: rule preambles (|RULE_NT| nodes)
and phrases (|INVOCATION_LIST_NT|). These will not even be looked at until the
second phase of compilation, after the model world has been created.

(c) Sentences with primary verbs, having node type |SENTENCE_NT|. These are
the assertions: they make statements about the initial state of the model
world -- the existence of places and things, and their properties at the
start of play -- and which describe patterns of behaviour during play.

In the present section of code, then, we identify the primary verbs of
assertion sentences, and deal right away with some of the easier cases,
while leaving the harder ones for later.

@ Every |SENTENCE_NT| node is annotated with a verb type from the enumeration
below. All of the assertions which create objects and kinds, and put them
into relationships with each other -- a tremendous variety of possible
sentences, between them making up about three-quarters of all |SENTENCE_NT|
nodes in typical source -- fall into one of two verb types:

@d ASSERT_VB 10 /* "The bat and ball are on the table." */

@ Finally, the remaining verb types are all direct commands to Inform --
note the imperative forms they take: Use, Understand, Include, and so forth.
In a sense the whole source text is an instruction to Inform, but mostly
it's a passive one: the implicit message is "make the world so that all
this comes right". Here, on the other hand, the user actually speaks
directly. This is a point of the design which has sometimes seemed a little
doubtful -- wouldn't it be more consistent for all of these sentences to be
more passively worded? -- but pragmatism won out: circumlocutions such as
"American dialect is used." or "The story file is released along with..."
are plausible enough, but

>> "take noun" is understood as taking the noun.

would mean a lot of important sentences being oddly punctuated with no
initial capital letter, while forcing meaningless extra words, as in

>> The command "take noun" is understood as taking the noun.

might prove annoying. Users seem to find the directness of the imperative
easier to use, at any rate, and perhaps the difference in mood helps to
clarify that these are sentences rather different in implication from
the usual sort.

@d SPECIAL_MEANING_VB 70

@ This isn't a verb, and is used only to mark errors:

@d BAD_NONVERB 1000

@

= (early code)
wording FOW, FSW;

@h Traversing for primary verbs.
As with headings, so with |SENTENCE_NT| nodes: we want the ability to
come back later and add some more. That means that the primary-verb-finder
needs to be able to make more than one pass through. To handle this, all
|SENTENCE_NT| nodes are annotated on creation with the "sentence
unparsed" marker: we run through the top level of the parse tree,
look at all nodes with this marker, parse their associated sentences,
and remove the marker from them. (So, for instance, if this is run twice
in quick succession, the second run-through does nothing.)

=
void Sentences::VPs::traverse(void) {
	SyntaxTree::traverse(Task::syntax_tree(), Sentences::VPs::visit);
}
void Sentences::VPs::visit(parse_node *p) {
	if (Node::get_type(p) == TRACE_NT) {
		SyntaxTree::toggle_trace(Task::syntax_tree());
		Log::tracing_on(SyntaxTree::is_trace_set(Task::syntax_tree()), I"Diagramming");
	}
	if ((Node::get_type(p) == SENTENCE_NT) &&
		(Annotations::read_int(p, sentence_unparsed_ANNOT))) {
		Sentences::VPs::seek(p);
		@<Check that this is allowed, if it occurs in the Options file@>;
		Sentences::Rearrangement::check_sentence_for_direction_creation(p);
		Annotations::write_int(p, sentence_unparsed_ANNOT, FALSE);
	}
}

@<Check that this is allowed, if it occurs in the Options file@> =
	if (Wordings::within(Node::get_text(p), options_file_wording)) {
		special_meaning_holder *sm = Node::get_special_meaning(p->down);
		int err = TRUE;
		if ((SpecialMeanings::is(sm, UseOptions::use_SMF)) ||
			(SpecialMeanings::is(sm, PL::Parsing::TestScripts::test_with_SMF)) ||
			(SpecialMeanings::is(sm, Sentences::VPs::include_in_SMF)) ||
			(SpecialMeanings::is(sm, Sentences::VPs::omit_from_SMF))) err = FALSE;
		#ifdef IF_MODULE
		if (SpecialMeanings::is(sm, PL::Bibliographic::Release::release_along_with_SMF)) err = FALSE;
		#endif
		if (err)
			StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* not usefully testable, anyway */
				"The options file placed in this installation of Inform's folder "
				"is incorrect, making use of a sentence form which isn't allowed "
				"in that situation. The options file is only allowed to contain "
				"use options, Test ... with..., and Release along with... "
				"instructions.");
	}

@ To break up an individual sentence into noun phrases and a verb phrase
is quite simple: we feed it to the <nonstructural-sentence> grammar,
and if that doesn't work, we feed it to <bad-nonstructural-sentence-diagnosis>
to look for a good contextual problem message.

=
parse_node *nss_tree_head = NULL;
int bootstrapped = FALSE;

void Sentences::VPs::seek(parse_node *PN) {
	if (bootstrapped == FALSE) {
		NewVerbs::bootstrap();
		bootstrapped = TRUE;
	}
	nss_tree_head = PN;
	CLEAR_RW(<nonstructural-sentence>);
	if (!(<nonstructural-sentence>(Node::get_text(PN))))
		<bad-nonstructural-sentence-diagnosis>(Node::get_text(PN));
}

@ =
<the-debugging-log> ::=
	the debugging log

@ =
int Sentences::VPs::include_in_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Index map with ..." */
		case ACCEPT_SMFT:
			if (<the-debugging-log>(OW)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<np-articled-list>(O2W);
				V->next = <<rp>>;
				Sentences::VPs::switch_dl_mode(V->next, TRUE);
				return TRUE;
			}
			return FALSE;
	}
	return FALSE;
}

int Sentences::VPs::omit_from_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Index map with ..." */
		case ACCEPT_SMFT:
			if (<the-debugging-log>(OW)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<np-articled-list>(O2W);
				V->next = <<rp>>;
				Sentences::VPs::switch_dl_mode(V->next, FALSE);
				return TRUE;
			}
			return FALSE;
	}
	return FALSE;
}



@ =
void Sentences::VPs::switch_dl_mode(parse_node *PN, int sense) {
	if (Node::get_type(PN) == AND_NT) {
		Sentences::VPs::switch_dl_mode(PN->down, sense);
		Sentences::VPs::switch_dl_mode(PN->down->next, sense);
		return;
	}
	Sentences::VPs::set_aspect_from_text(Node::get_text(PN), sense);
}

@ =
<include-in-debugging-sentence-subject> ::=
	only <debugging-log-request> |  ==> { R[1] | ONLY_DLR, RP[1] }
	<debugging-log-request>         ==> { pass 1 }

<debugging-log-request> ::=
	everything |                    ==> { EVERYTHING_DLR, NULL }
	nothing |                       ==> { NOTHING_DLR, NULL }
	<preform-nonterminal> |         ==> { PREFORM_DLR, RP[1] }
	...                             ==> { SOMETHING_DLR, NULL }

=
void Sentences::VPs::set_aspect_from_text(wording W, int new_state) {
	LOGIF(DEBUGGING_LOG_INCLUSIONS, "Set contents of debugging log: %W -> %s\n",
		W, new_state?"TRUE":"FALSE");

	@<See if this is a compound request for debugging information@>;

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownDA));
	Problems::issue_problem_segment(
		"In the sentence %1, you asked to include '%2' in the "
		"debugging log, but there is no such debugging log topic.");
	Problems::issue_problem_end();
}

@ Requests can be divided as "R and S" (and can even use the serial comma),
and we also understand "only R" and "everything" and "nothing".

@d ONLY_DLR 1
@d EVERYTHING_DLR 2
@d NOTHING_DLR 4
@d SOMETHING_DLR 8
@d PREFORM_DLR 16

@<See if this is a compound request for debugging information@> =
	<include-in-debugging-sentence-subject>(W);
	if (<<r>> & ONLY_DLR) Log::set_all_aspects(1-new_state);
	if (<<r>> & EVERYTHING_DLR) { Log::set_all_aspects(new_state); return; }
	if (<<r>> & NOTHING_DLR) { Log::set_all_aspects(1-new_state); return; }
	if (<<r>> & SOMETHING_DLR) {
		wording RQW = GET_RW(<debugging-log-request>, 1);
		@<See if this is a simple request for debugging information@>;
	}
	if (<<r>> & PREFORM_DLR) { Instrumentation::watch(<<rp>>, new_state); return; }

@ Otherwise a request must be the name of a single debugging aspect.

@<See if this is a simple request for debugging information@> =
	TEMPORARY_TEXT(req)
	LOOP_THROUGH_WORDING(j, RQW) {
		WRITE_TO(req, "%N", j);
		if (j<Wordings::last_wn(RQW)) WRITE_TO(req, " ");
	}
	int rv = Log::set_aspect_from_command_line(req, FALSE);
	DISCARD_TEXT(req)
	if (rv) return;

@ Here, then, is one of Inform's largest grammars, <nonstructural-sentence>.

It's large because of the many exceptional, ad-hoc-looking syntaxes, and at
first sight those seem unnecessary: why not simply define more built-in verbs
and relations, and handle them as regular sentences? The answer to this is that
they have an irregular structure to them. Consider:

>> Trampling is an action applying to nothing.

This doesn't conform to the pattern of a verb plus a subject and object
noun phrase, each of which refers to some value.

An arguably inconsistent feature of the design of Inform is that some of these
sentences take the imperative mood:

>> Release along with the solution.

rather than the indicative ("The ball is in the box") which is otherwise
used for all Inform sentences other than rule definitions. Sometimes I think
this is a mistake, sometimes a virtue. In the case of "Release along", for
instance, we're telling the computer to do something, rather than telling
the computer about something -- which seems a worthwhile distinction. In the
case of "Understand X as Y", though, it could be argued that an indicative
use of "X means Y" would work better. (It was actually Andrew Plotkin's
suggestion that we use "Understand", and it stuck.) At any rate, it's too
late now, and I ask translators into natural languages to follow the same
pattern: use imperatives if the English does, and use indicatives otherwise.

Note also that "Index map with..." is an imperative, with the verb being
"to index", that is, it's an instruction to make a map; "index map" is
not a noun phrase here.

The ordering of the sentences in this nonterminal is important. A few notes:

(a) We check Unicode translations first of all, because we haven't any control
over the wording of character names in the Unicode standard. Among the 12,997
definitions used in the Unicode Full Character Names extension are such choice
examples as "downwards arrow from bar", "arabic hamza above", "kangxi
radical use" and so forth, and we don't want to misread "from", "above",
"use", and so on, as prepositions or verbs: in sentences like this one
they are nouns.

(b) Any sentence form with "is" or "has" in it must be checked before
regular sentences are checked: "X is an action...", for instance, is
otherwise easily mistaken for a regular assertion.

(c) We could conceivably have implemented "action" and "activity" as
pseudo-kinds, and thus handled sentences like these through ordinary
assertions, but it would have been a lot of fuss. So we do it the
simple-minded way.

(d) Note that activity declarations always simply end "is an activity.",
thus having nothing interesting by way of an object noun phrase, whereas
action declarations continue with usually extensive further text:
"... is an action applying to two visible things.", say.

=
<nonstructural-sentence> ::=
	<sentence-without-occurrences>								==> @<Construct NSS subtree for regular sentence@>

@<Construct NSS subtree for regular sentence@> =
	parse_node *VP_PN = RP[1];
	if (Annotations::read_int(VP_PN, linguistic_error_here_ANNOT) == TwoLikelihoods_LINERROR)
		@<Issue two likelihoods problem@>;
	if (Annotations::read_int(VP_PN, verb_id_ANNOT) == 0)
		Annotations::write_int(VP_PN, verb_id_ANNOT, ASSERT_VB);
	SyntaxTree::graft(Task::syntax_tree(), VP_PN, nss_tree_head);

	if (SyntaxTree::is_trace_set(Task::syntax_tree())) {
		LOG("$T\n", nss_tree_head); STREAM_FLUSH(DL);
	}
	==> { 0, - };

@<Issue two likelihoods problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TwoLikelihoods),
		"this sentence seems to have a likelihood qualification on both "
		"sides of the verb",
		"which is not allowed. 'The black door certainly is usually open' "
		"might possibly be grammatical English in some idioms, but Inform "
		"doesn't like a sentence in this shape because the 'certainly' "
		"on one side of the verb and the 'usually' on the other are "
		"rival indications of certainty.");

@ In all other cases it's routine to construct the subtree, which typically
gives the sentence node three children: verb phrase, subject noun phrase,
object noun phrase.
= (text)
	SENTENCE_NT "Railway Departure begins when the player is in the train"
	    VERB_NT "begins when"
	    PROPER_NOUN_NT "Railway Departure"
	    PROPER_NOUN_NT "the player is in the train"
=
This is made by |Sentences::VPs::nss_tree2|, but there are variants for one noun phrase or three.

=
int Sentences::VPs::nss_tree1(int t, wording VW, parse_node *np1) {
	parse_node *VP_PN = Node::new(VERB_NT);
	Node::set_text(VP_PN, VW);
	Annotations::write_int(VP_PN, verb_id_ANNOT, t);
	SyntaxTree::graft(Task::syntax_tree(), VP_PN, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np1, nss_tree_head);
	return 0;
}

int Sentences::VPs::nss_tree2(int t, wording VW, parse_node *np1, parse_node *np2) {
	parse_node *VP_PN = Node::new(VERB_NT);
	Node::set_text(VP_PN, VW);
	Annotations::write_int(VP_PN, verb_id_ANNOT, t);
	SyntaxTree::graft(Task::syntax_tree(), VP_PN, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np1, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np2, nss_tree_head);
	return 0;
}

int Sentences::VPs::nss_tree3(int t, wording VW, parse_node *np1, parse_node *np2, parse_node *np3) {
	parse_node *VP_PN = Node::new(VERB_NT);
	Node::set_text(VP_PN, VW);
	Annotations::write_int(VP_PN, verb_id_ANNOT, t);
	SyntaxTree::graft(Task::syntax_tree(), VP_PN, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np1, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np2, nss_tree_head);
	SyntaxTree::graft(Task::syntax_tree(), np3, nss_tree_head);
	return 0;
}

@ In the assertion parser, any text at all can be a noun phrase. However,
to disambiguate sentences we sometimes want to insist that it takes a
particular form: for instance <nounphrase-figure> matches any text ending
in the word "figure".

<nounphrase-actionable> is an awkward necessity, designed to prevent the
regular sentence

>> The impulse is an action name that varies.

from being parsed as an instance of "... is an action ...", creating a
new action.

=
<nounphrase-figure> ::=
	figure ...							==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<nounphrase-sound> ::=
	sound ...							==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<nounphrase-external-file> ::=
	<external-file-sentence-subject>    ==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<nounphrase-actionable> ::=
	^<variable-creation-tail>			==> { 0, Diagrams::new_UNPARSED_NOUN(W) }

<variable-creation-tail> ::=
	*** that/which vary/varies |
	*** variable

@ "I6" and "Inform 6" are synonymous here.

=
<translation-target-unicode> ::=
	unicode								==> { TRUE, NULL }

<translation-target-i6> ::=
	i6 |                                ==> { TRUE, NULL }
	inform 6							==> { TRUE, NULL }

<translation-target-language> ::=
	<natural-language>					==> { TRUE, RP[1] }

@ =
int Sentences::VPs::translates_into_unicode_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Black king chess piece translates into Unicode as 9818" */
		case ACCEPT_SMFT:
			if (<translation-target-unicode>(O2W)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case TRAVERSE2_SMFT:
			UnicodeTranslations::unicode_translates(V);
			break;
	}
	return FALSE;
}

int Sentences::VPs::translates_into_I6_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Black king chess piece translates into Unicode as 9818" */
		case ACCEPT_SMFT:
			if (<translation-target-i6>(O2W)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
		case TRAVERSE2_SMFT:
			IdentifierTranslations::as(V);
			break;
	}
	return FALSE;
}

int Sentences::VPs::translates_into_language_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Black king chess piece translates into Unicode as 9818" */
		case ACCEPT_SMFT:
			if (<translation-target-language>(O2W)) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				inform_language *nl = (inform_language *) (<<rp>>);
				<np-articled>(SW);
				V->next = <<rp>>;
				<np-articled>(OW);
				V->next->next = <<rp>>;
				Node::set_defn_language(V->next->next, nl);
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			UseNouns::nl_translates(V);
			break;
	}
	return FALSE;
}


@ This final case never matches a legal sentence: it simply hoovers up
usages of past tense assertion verbs in order to give them a better
Problem message than the one they will otherwise receive later on.

=
<bad-nonstructural-sentence-diagnosis> ::=
	... <bad-nonstructural-sentence-diagnosis-tail>

<bad-nonstructural-sentence-diagnosis-tail> ::=
	<relative-clause-marker> <certainty> <meaningful-nonimperative-verb> ... |    ==> { advance Wordings::delta(WR[1], W) }
	<relative-clause-marker> <meaningful-nonimperative-verb> ... |    ==> { advance Wordings::delta(WR[1], W) }
	<past-tense-verb> ... |    ==> @<Issue PM_NonPresentTense problem@>
	<negated-verb> ...																	==> @<Issue PM_NegatedVerb1 problem@>

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

@ This catches sentences like "Timothy does not carry the ring".

@<Issue PM_NegatedVerb1 problem@> =
	if (Annotations::read_int(current_sentence, verb_problem_issued_ANNOT) == FALSE) {
		Annotations::write_int(current_sentence, verb_problem_issued_ANNOT, TRUE);
		StandardProblems::negative_sentence_problem(Task::syntax_tree(), _p_(PM_NegatedVerb1));
	}

@h Logging verb numbers.

=
void Sentences::VPs::log(int verb_number) {
	switch(verb_number) {
		case ASSERT_VB: LOG("ASSERT_VB"); break;
		case SPECIAL_MEANING_VB: LOG("SPECIAL_MEANING_VB"); break;
		default: LOG("(number %d)", verb_number); break;
	}
}
