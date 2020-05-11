[Sentences::] Sentences.

To break up the stream of words produced by the lexer into
English sentences, and join each to the parse tree.

@h Sentence breaking.
What breaks a sentence? In ordinary English, question marks, exclamation
marks, in some cases ellipses, but mainly full stops. In Inform source text,
only full stops are used outside quoted text; but we do have to recognise the
other cases when they occur at the end of quoted matter. Moreover, we
actually subdivide a little further, because we also want to break up
rule "sentences" into their subordinate clauses. Thus, going on
punctuation, we recognise rules as having the following model:

>> Preamble: phrase 1; phrase 2; ...; phrase N.

It is even, in certain limited circumstances, possible that a comma can
divide a sentence:

>> Instead of eating, say "You really aren't hungry just now."

This means that context is important even here, where it might have been
expected that all we needed to do was to spot the punctuation marks.

@h Finite state machine.
So we carry out the sentence breaking with a simple finite state machine --
the last sentence having been a rule preamble tells us that the current one
is probably a phrase, and so on -- and the following is its state. It is
inelegant that we have a singleton copy of this object and use a pointer
to it as a global variable; but it saves an awful lot of parameter-passing
in Preform grammar functions.

@default PROBLEM_REF_SYNTAX_TYPE void
@default PROJECT_REF_SYNTAX_TYPE void

@e NO_EXTENSION_POS from 0
@e BEFORE_BEGINS_EXTENSION_POS
@e MIDDLE_EXTENSION_POS
@e AFTER_ENDS_EXTENSION_POS
@e PAST_CARING_EXTENSION_POS

=
typedef struct syntax_fsm_state {
	source_file *sf; /* reading from this source file */
	int ext_pos; /* one of the |*_EXTENSION_POS| values: where we are in an extension */
	int skipping_material_at_level;
	int main_source_start_wn;
	node_type_t nt;
	int inside_rule_mode;
	int inside_table_mode;
	PROBLEM_REF_SYNTAX_TYPE *ref;
	PROJECT_REF_SYNTAX_TYPE *project_ref;
} syntax_fsm_state;

syntax_fsm_state the_one_and_only;
syntax_fsm_state *sfsm = &the_one_and_only;

@ Note that a reset zeroes everything out except the |main_source_start_wn|;
that's because we reset each time we begin a round of sentence-breaking, and
there may be many such rounds on the same Inform project, but there's only
one source text start position.

=
void Sentences::set_start_of_source(syntax_fsm_state *sfsm, int wn) {
	sfsm->main_source_start_wn = wn;
}

void Sentences::reset(syntax_fsm_state *sfsm, int is_extension,
	PROBLEM_REF_SYNTAX_TYPE *ref, PROJECT_REF_SYNTAX_TYPE *project_ref) {
	sfsm->sf = NULL;
	sfsm->inside_rule_mode = FALSE;
	sfsm->skipping_material_at_level = -1;
	sfsm->ref = ref;
	sfsm->project_ref = project_ref;
	if (is_extension) sfsm->ext_pos = BEFORE_BEGINS_EXTENSION_POS;
	else sfsm->ext_pos = NO_EXTENSION_POS;
}

@ These are the syntax errors we will generate.

@e UnexpectedSemicolon_SYNERROR from 1
@e ParaEndsInColon_SYNERROR
@e SentenceEndsInColon_SYNERROR
@e SentenceEndsInSemicolon_SYNERROR
@e SemicolonAfterColon_SYNERROR
@e SemicolonAfterStop_SYNERROR
@e ExtSpuriouslyContinues_SYNERROR
@e ExtNoBeginsHere_SYNERROR
@e ExtNoEndsHere_SYNERROR
@e HeadingOverLine_SYNERROR
@e HeadingStopsBeforeEndOfLine_SYNERROR

@ Now for the function itself. We break into bite-sized chunks, each of which is
despatched to the |Sentences::make_node| function with a note of the punctuation
which was used to end it.

=
void Sentences::break(parse_node_tree *T, wording W) {
	Sentences::break_inner(T, W, FALSE, NULL, NULL);
}
void Sentences::break_into_project_copy(parse_node_tree *T, wording W,
	PROBLEM_REF_SYNTAX_TYPE *ref, void *project_ref) {
	Sentences::break_inner(T, W, FALSE, ref, project_ref);
}
void Sentences::break_into_extension_copy(parse_node_tree *T, wording W,
	PROBLEM_REF_SYNTAX_TYPE *ref, PROJECT_REF_SYNTAX_TYPE *project_ref) {
	Sentences::break_inner(T, W, TRUE, ref, project_ref);
}

void Sentences::break_inner(parse_node_tree *T, wording W, int is_extension,
	PROBLEM_REF_SYNTAX_TYPE *ref, PROJECT_REF_SYNTAX_TYPE *project_ref) {
	while (((Wordings::nonempty(W))) && (compare_word(Wordings::first_wn(W), PARBREAK_V)))
		W = Wordings::trim_first_word(W);
	if (Wordings::empty(W)) return;

	int sentence_start = Wordings::first_wn(W);
	SyntaxTree::enable_last_sentence_cache(T);

	Sentences::reset(sfsm, is_extension, ref, project_ref);
	@<Go into table sentence mode if necessary@>;

	LOOP_THROUGH_WORDING(position, W)
		if (sentence_start < position) {
			int no_stop_words, back_up_one_word;
			int stop_character;

			@<Look for a sentence break, finding the number of stop words and the stop character@>;
			if (no_stop_words > 0) {
				Sentences::make_node(T, Wordings::new(sentence_start, position-1), stop_character);
				position = position + no_stop_words - 1;
				if (back_up_one_word) sentence_start = position;
				else sentence_start = position + 1;

				@<Go into table sentence mode if necessary@>;
			}
		}

	if ((sentence_start < Wordings::last_wn(W)) ||
		((sentence_start == Wordings::last_wn(W)) && (!(Lexer::word(Wordings::last_wn(W)) == PARBREAK_V)))) {
		Sentences::make_node(T, Wordings::from(W, sentence_start), '.');
	}

	SyntaxTree::disable_last_sentence_cache(T);

	if (is_extension)
		@<Issue a problem message if we are missing the begin and end here sentences@>;
	Sentences::reset(sfsm, FALSE, NULL, NULL);
}

@ A table is any sentence beginning with the word "Table". (Bad news for
anyone writing "Table Mountain is a room.", of course, but there are other
ways to do that, and it seems wise to keep the syntax for tables clear,
since their entries are governed by different lexical and semantic rules.)

@<Go into table sentence mode if necessary@> =
	if ((<structural-sentence>(Wordings::from(W, sentence_start))) &&
		(NodeType::has_flag(sfsm->nt, TABBED_NFLAG)))
		sfsm->inside_table_mode = TRUE;
	else
		sfsm->inside_table_mode = FALSE;

@ We now come to the definition of a sentence break, which is more complicated
than might have been expected.

For one thing, a run of sentence divisions is treated as a single division,
only the last of which is the one which counts. This looks odd at first sight,
because it means that Inform considers

>> The cat is on the table;.

to be a valid sentence, equivalent to

>> The cat is on the table.

But it has the advantage that it enables us to avoid being pointlessly strict
over the punctuation which precedes a paragraph break. Some people like to
write paragraphs like this:
= (text as Inform 7)
	Before going north:
	    say "Northward ho!";
	    now the compass points north;
=
And properly speaking that ends with a semicolon then a paragraph break,
which is a doubled sentence division. But we forgive it as harmless, and
that forgiveness is provided by the loop arrangement below.

We also avoid the need for empty sentences, because it is not possible
for the code below to detect them: thus

>> say "Look behind you!";;;;; now the Wug is in the Cave

is broken as two sentences, not six sentences of which four are empty.
Perhaps we ought to be stricter, and reject more of these dubious forms,
but at this point we have too little understanding of the semantics of
the text to risk annoying the user with problem messages.

@ Full stops, semicolons and paragraph breaks (all rendered by the lexer as
individual words: the stroke word in the case of the latter) are always
sentence divisions. The other cases are more complicated: see below.

@<Look for a sentence break, finding the number of stop words and the stop character@> =
	int at = position;
	no_stop_words = 0; stop_character = '?'; back_up_one_word = FALSE;
	while (at < Wordings::last_wn(W)) {
		int stopped = FALSE;

		if (Lexer::word(at) == PARBREAK_V) {
			if (stop_character == ':') @<Issue problem for colon at end of paragraph@>;
			stop_character = '|'; stopped = TRUE;
		}
		if (Lexer::word(at) == FULLSTOP_V) {
			if (stop_character == ':') @<Issue problem for colon at end of sentence@>;
			if (stop_character == ';') @<Issue problem for semicolon at end of sentence@>;
			stop_character = '.'; stopped = TRUE;
		}
		if (Lexer::word(at) == SEMICOLON_V) {
			if (stop_character == ':') @<Issue problem for semicolon after colon@>;
			if (stop_character == '.') @<Issue problem for semicolon after full stop@>;
			stop_character = ';'; stopped = TRUE;
		}

		@<Consider if a colon divides a sentence@>;
		@<Consider if punctuation within a preceding quoted text divides a sentence, making an X break@>;

		if (stopped == FALSE) break;
		no_stop_words++; at++;
	}
	if (stop_character == 'X') { /* X breaks are like full stops, but there is no stop word to skip over */
		stop_character = '.'; back_up_one_word = TRUE;
	}
	if (no_stop_words > 0)
		LOGIF(LEXICAL_OUTPUT, "Stop character '%c', no_stop_words %d, sentence_break %d, position %d\n",
			stop_character, no_stop_words, sentence_start, position);

@<Issue problem for colon at end of paragraph@> =
	Sentences::syntax_problem(ParaEndsInColon_SYNERROR, Wordings::new(sentence_start, at-1), sfsm->ref, 0);

@<Issue problem for colon at end of sentence@> =
	Sentences::syntax_problem(SentenceEndsInColon_SYNERROR, Wordings::new(sentence_start, at), sfsm->ref, 0);

@<Issue problem for semicolon at end of sentence@> =
	Sentences::syntax_problem(SentenceEndsInSemicolon_SYNERROR, Wordings::new(sentence_start, at), sfsm->ref, 0);

@<Issue problem for semicolon after colon@> =
	Sentences::syntax_problem(SemicolonAfterColon_SYNERROR, Wordings::new(sentence_start, at), sfsm->ref, 0);

@<Issue problem for semicolon after full stop@> =
	Sentences::syntax_problem(SemicolonAfterStop_SYNERROR, Wordings::new(sentence_start, at), sfsm->ref, 0);

@ Colons are normally dividers, too, but an exception is made if they come
between two apparently numerical constructions, because this suggests that
the colon is being used not as punctuation but within a literal pattern.
(For instance, "He went out at 1:34 PM." is a sentence with just one
clause, not two clauses divided by the colon; but "He went out at 1 PM:
the snow was still falling." is indeed divided. Our rule here correctly
distinguishes these cases, and although it can be fooled by really contrived
sentences -- "He went out at 1: 22 Company, the Parachute Regiment, was
marching." -- it's robust enough in practice. The exception is forbidden
if a line break occurs between the colon and the succeeding numeral, as
then we might be looking at switch cases in an "if".)

Note that here we are at a word position which is strictly within the word
range being sentence-broken, so that it is safe to examine both the word
before and the word after the current position.

@<Consider if a colon divides a sentence@> =
	if ((Lexer::word(at) == COLON_V) &&
		(Lexer::file_of_origin(at-1) == Lexer::file_of_origin(at)) &&
		(no_stop_words == 0) &&
		((Characters::isdigit(*(Lexer::word_raw_text(at-1))) == FALSE) ||
			(Characters::isdigit(*(Lexer::word_raw_text(at+1))) == FALSE) ||
			(Lexer::indentation_level(at+1) > 0))) {
		stop_character = ':'; stopped = TRUE;
	}

@ Inform authors habitually use the punctuation in quoted text to end
sentences, just as other writers of English do. The text

>> "Look out!" The explosion shattered the calm of the hillside.

is certainly intended as two sentences, not one.

An exception is made for table declarations, because a table needs to be formed as
one long sentence, and it clearly does not abide by the ordinary punctuation
rules of English. The point is that in the random line of table entries...

>> "Of cabbages and kings."\qquad Walrus\qquad "Carroll"

...the full stop after "kings" has no significance: the semantics of the
table would be no different if it were not there.

@<Consider if punctuation within a preceding quoted text divides a sentence, making an X break@> =
	if ((stopped == FALSE) && /* only look if we are not already at a division */
		(no_stop_words == 0) && /* be sure not to elide two such texts in a row */
		(sfsm->inside_table_mode == FALSE) && /* check that we are not scanning the body of a table */
		(isupper(*(Lexer::word_raw_text(at)))) && /* and the current word begins with a capital letter */
		(Word::text_ending_sentence(at-1))) { /* and the preceding one was quoted text ending in punctuation */
		stop_character = 'X'; stopped = TRUE;
	}

@h Making sentence nodes.
At this point we have established that |Sentences::make_node| is called
sequentially for every divided-off sentence in the original source text.
But we need a little machinery to skip past sentences which are being
excluded for one reason or another.

The design of Inform deliberately excludes conditional compilation in the
traditional C sense of |#ifdef| and |#endif|. This takes us too far from
what natural language would do, faced with the same basic issue. A book, or
a government form, would more naturally have a heading making clear that
the section beneath it is not universal in application. This is what Inform
does, too: it parses a heading to decide whether to skip the material,
and if so, the state |sfsm->skipping_material_at_level| is set to the
level of the heading in question. We then skip all subsequent sentences
until reaching the next heading of the same or higher status, or until
reaching the "... ends here." sentence (if we are reading an extension),
or until reaching the end of the text: whichever comes first.

=
void Sentences::make_node(parse_node_tree *T, wording W, int stop_character) {
	int heading_level = 0;
	int begins_or_ends = 0; /* 1 for "begins here", -1 for "ends here" */
	parse_node *new;

	if (Wordings::empty(W)) internal_error("empty sentence generated");

	Vocabulary::identify_word_range(W); /* a precaution to catch any late unidentified text */

	@<Detect a change of source file, and declare it as an implicit heading@>;
	@<Detect a dividing sentence@>;

	if ((begins_or_ends == -1) ||
		((heading_level > 0) && (heading_level <= sfsm->skipping_material_at_level)))
		sfsm->skipping_material_at_level = -1;

	if (sfsm->skipping_material_at_level >= 0) return;

	if (heading_level > 0) {
		@<Issue a problem message if the heading incorporates a line break@>;
		@<Issue a problem message if the heading does not end with a line break@>;
		@<Make a new HEADING node, possibly beginning to skip material@>;
		return;
	}

	@<Reject if we have run on past the end of an extension@>;
	@<Accept the new sentence as one or more nodes in the parse tree@>;
}

@ For reasons gone into in the section on Headings below, a change of
source file (e.g., when one extension has been read in and another begins)
is declared as if it were a super-heading in the text.

@<Detect a change of source file, and declare it as an implicit heading@> =
	if (Lexer::file_of_origin(Wordings::first_wn(W)) != sfsm->sf) {
		parse_node *implicit_heading = Node::new(HEADING_NT);
		Node::set_text(implicit_heading, W);
		Annotations::write_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
		Annotations::write_int(implicit_heading, heading_level_ANNOT, 0);
		SyntaxTree::graft_sentence(T, implicit_heading);
		#ifdef NEW_HEADING_SYNTAX_CALLBACK
		NEW_HEADING_SYNTAX_CALLBACK(T, implicit_heading, sfsm->project_ref);
		#endif
		sfsm->skipping_material_at_level = -1;
	}
	sfsm->sf = Lexer::file_of_origin(Wordings::first_wn(W));

@<Reject if we have run on past the end of an extension@> =
	if ((sfsm->ext_pos == AFTER_ENDS_EXTENSION_POS) && (begins_or_ends == 0)) {
		Sentences::syntax_problem(ExtSpuriouslyContinues_SYNERROR, W, sfsm->ref, 0);
		sfsm->ext_pos = PAST_CARING_EXTENSION_POS; /* to avoid multiply issuing this */
	}

@ The client must define a Preform nonterminal called |<dividing-sentence>|
which returns either a heading level number (1 to 10, with 1 the most
important), or |-1| to mean that the sentence begins an extension, or
|-2| that it ends one.

@<Detect a dividing sentence@> =
	if (<dividing-sentence>(W)) {
		switch (<<r>>) {
			case -1: if (sfsm->ext_pos != NO_EXTENSION_POS) begins_or_ends = 1; break;
			case -2: if (sfsm->ext_pos != NO_EXTENSION_POS) begins_or_ends = -1; break;
			default: heading_level = <<r>>; break;
		}
	}

@ We have already looked to see if the sentence could be a heading, and set
the variable |heading_level| to be its ranking in the hierarchy (with 1,
for "volume", the highest). But we also want to check that the heading
does not have a line break in, because this is almost certainly a mistake
by the designer, and likely to be a difficult one to understand: so we
should help out if we can. Such a problem is best recovered from by
continuing regardless.

@<Issue a problem message if the heading incorporates a line break@> =
	LOOP_THROUGH_WORDING(k, W)
		if (k > Wordings::first_wn(W))
			if ((Lexer::break_before(k) == '\n') || (Lexer::indentation_level(k) > 0)) {
				Sentences::syntax_problem(HeadingOverLine_SYNERROR, W, sfsm->ref, k);
				break;
			}

@ And similarly... Here we take the liberty of looking a little ahead of
the current word range in order to make the problem message more helpful:
we check that we are still looking at valid words in the lexer, just to be
on the safe side, but in fact we cannot run on past the end of the lexer
feed which fed the malformed heading, because of all of the run-off
newlines automatically added at the end of the feed of any source file.

@<Issue a problem message if the heading does not end with a line break@> =
	if (Lexer::break_before(Wordings::last_wn(W)+1) != '\n') {
		int k;
		for (k = Wordings::last_wn(W)+1;
			(k<=Wordings::last_wn(W)+8) &&
				(k<lexer_wordcount) && (Lexer::break_before(k) != '\n');
			k++) ;
		Sentences::syntax_problem(HeadingStopsBeforeEndOfLine_SYNERROR, W, sfsm->ref, k);
	}

@ We now have a genuine heading, and can declare it, calling a routine
in Headings to determine whether we should include the material.

@<Make a new HEADING node, possibly beginning to skip material@> =
	new = Node::new(HEADING_NT);
	Node::set_text(new, W);
	Annotations::write_int(new, sentence_unparsed_ANNOT, FALSE);
	Annotations::write_int(new, heading_level_ANNOT, heading_level);
	SyntaxTree::graft_sentence(T, new);
	#ifdef NEW_HEADING_SYNTAX_CALLBACK
	if (NEW_HEADING_SYNTAX_CALLBACK(T, new, sfsm->project_ref) == FALSE)
		sfsm->skipping_material_at_level = heading_level;
	#endif

@ When we finish scanning all the sentences in a given batch, and if they came
from an extension, we need to make sure we saw both beginning and end:

@<Issue a problem message if we are missing the begin and end here sentences@> =
	switch (sfsm->ext_pos) {
		case BEFORE_BEGINS_EXTENSION_POS: 
			Sentences::syntax_problem(ExtNoBeginsHere_SYNERROR, W, sfsm->ref, 0); break;
		case MIDDLE_EXTENSION_POS:
			Sentences::syntax_problem(ExtNoEndsHere_SYNERROR, W, sfsm->ref, 0); break;
	}

@h Unskipped material which is not a heading.
Each of the sentences which are to be included is given its own node on the
parse tree, which for the time being is a direct child of the root.
Sentences are classified by their node types, the main identification
attached to each unit in the tree.

(a) "Nonstructural sentences", which will be subject to further parsing
work, have node type |SENTENCE_NT| (and so will "regular sentences").
Anything we cannot place into categories (b) or (c) below will go here.

(b) "Sentences making up rules". These are sequences of sentences in which
a preamble (ending with a colon, or in certain cases a comma) of node type
|ROUTINE_NT| is followed by a sequence of phrases (ending with semicolons until
the last, which ends with a full stop or paragraph break), each of node type
|INVOCATION_LIST_NT|. For instance, the following produces three nodes:

>> To look upwards: say "Look out!"; something else.

(c) "Structural sentences". These demarcate the text, call for other text
or unusual matter to be included, etc.: the types in question are |TRACE_NT|,
|HEADING_NT|, |INCLUDE_NT|, |INFORM6CODE_NT|, |BEGINHERE_NT|, |ENDHERE_NT|,
|TABLE_NT|, |EQUATION_NT| and |BIBLIOGRAPHIC_NT|.

@ The second sentence in the source text is construed as containing
bibliographic data if it begins with a quoted piece of text, perhaps with
substitutions. For instance,

>> "A Dream of Fair to Middling Women" by Samuel Beckett

This sentence is at the position matched by <if-start-of-source-text>.
(It may not be the first sentence read, because implied extension inclusion
sentences and options-file sentences may have been read already.)

=
<if-start-of-source-text> internal 0 {
	int w1 = Wordings::first_wn(W);
	while (w1 >= 0) {
		if (w1 == sfsm->main_source_start_wn) return TRUE;
		if (compare_word(w1-1, PARBREAK_V) == FALSE) return FALSE;
		w1--;
	}
	return FALSE;
}

@<Accept the new sentence as one or more nodes in the parse tree@> =
	@<Convert comma-divided rule into two sentences, if this is allowed@>;
	@<Otherwise, make a SENTENCE node@>;

	@<Convert a rule preamble to a ROUTINE node and enter rule mode@>;
	if (sfsm->inside_rule_mode)
		@<Convert to a COMMAND node and exit rule mode unless a semicolon implies more@>
	else if (stop_character == ';') {
		Sentences::syntax_problem(UnexpectedSemicolon_SYNERROR, W, sfsm->ref, 0);
		stop_character = '.';
	}

	/* at this point we are certainly in assertion mode, not rule mode */
	if (<structural-sentence>(W)) {
		if (<<r>> == -1)
			@<Detect a language definition sentence and sneakily act upon it@>
		else if (<<r>> == -2) {
			@<Detect a Preform grammar inclusion and sneakily act upon it@>
			Node::set_type(new, sfsm->nt); return;
		} else {
			Node::set_type(new, sfsm->nt);
			#ifdef SUPERVISOR_MODULE
			if (sfsm->nt == BIBLIOGRAPHIC_NT)
				BiblioSentence::notify(sfsm->project_ref, new);
			#endif
			return;
		}
	}

	@<Convert a begins here or ends here sentence to a BEGINHERE or ENDHERE node and return@>;

	/* none of that happened, so we have a SENTENCE node for certain */
	Annotations::write_int(new, sentence_unparsed_ANNOT, TRUE);
	#ifdef NEW_NONSTRUCTURAL_SENTENCE_SYNTAX_CALLBACK
	NEW_NONSTRUCTURAL_SENTENCE_SYNTAX_CALLBACK(new);
	#endif

@ We make an exception to the exception for the serial comma used in a list of
alternatives: thus the comma in "Aeschylus, Sophocles, or Euripides" does
not trigger this rule. We need this exception because such lists of
alternatives often occur in rule preambles, where it's the third comma
which divides rule from preamble:

>> Instead of pushing, dropping, or taking the talisman, say "It is cursed."

The following is used to detect "or" in such lists.

=
<list-or-division> ::=
	...... , _or ...... |
	...... _or ......

@<Convert comma-divided rule into two sentences, if this is allowed@> =
	if ((sfsm->inside_rule_mode == FALSE)
		&& ((stop_character == '.') || (stop_character == '|'))
		&& (<comma-divisible-sentence>(W)))
		@<Look for a comma and split the sentence at it, unless in serial list@>;

@ In such sentences a comma is read as if it were a colon. (The text up to the
comma will then be given a |ROUTINE_NT| node and the text beyond the comma
will make a |INVOCATION_LIST_NT| node.)

@<Look for a comma and split the sentence at it, unless in serial list@> =
	int earliest_comma_position = Wordings::first_wn(W);
	@<Set earliest comma to position after the or, if there is one@>;
	wording AW = EMPTY_WORDING, BW = EMPTY_WORDING;
	if (<list-comma-division>(Wordings::from(W, earliest_comma_position))) {
		AW = GET_RW(<list-comma-division>, 1);
		BW = GET_RW(<list-comma-division>, 2);
	}
	if (Wordings::nonempty(AW)) {
		Sentences::make_node(T, Wordings::up_to(W, Wordings::last_wn(AW)), ':'); /* rule preamble stopped with a colon */
		Sentences::make_node(T, BW, '.'); /* rule body with one sentence, stopped with a stop */
		return;
	}

@<Set earliest comma to position after the or, if there is one@> =
	if (<list-or-division>(W)) {
		wording BW = GET_RW(<list-or-division>, 2);
		earliest_comma_position = Wordings::first_wn(BW);
	}

@ At this point we know that the text |W| will make one and only
one sentence node in the parse tree, so we may as well create and SyntaxTree::graft it
now. There are a number of special cases with variant node types, but the
commonest outcome is a SENTENCE node, so that's what we shall assume for now.

@<Otherwise, make a SENTENCE node@> =
	new = Node::new(SENTENCE_NT);
	Node::set_text(new, W);
	Annotations::write_int(new, sentence_unparsed_ANNOT, FALSE);
	SyntaxTree::graft_sentence(T, new);

@ Rules are sequences of phrases with a preamble in front, which we detect by
its terminating colon. For instance:

>> To look upwards: say "Look out!"; something else.

(which arrives at this routine as three separate "sentences") will produce
nodes with type |ROUTINE_NT|, |INVOCATION_LIST_NT| and |INVOCATION_LIST_NT| respectively.

This paragraph of code might look as if it should only be used in assertion
mode, not in rule mode, because how can a rule preamble legally occur in
the middle of another rule? But in fact it can, in two ways. One is the
officially sanctioned way to make a definition with a complex phrase:

>> Definition: a supporter is wobbly: if the player is on it, decide yes; decide no.

This produces four nodes: |ROUTINE_NT|, |ROUTINE_NT|, |INVOCATION_LIST_NT| and
|INVOCATION_LIST_NT| respectively.

The other arises somewhat less officially when people treat phrases as
if they were C (or Inform 6) statements, always to be terminated with
semicolons, and also run two rules together with no skipped paragraph
between:
= (text as Inform 7)
	To do one thing: something here;
	To do another thing: something else here;
=
A strict reading of our rules would oblige us to consider "To do another
thing:" as a phrase within the definition of "To do one thing", and
we would then have to issue a problem message. But this would be pettifogging.
(People who habitually shuffle phrases about in their editors tend not to
want to fuss about changing the punctuation of the last to a full stop
instead of a semicolon. We may lament this, but it is so.)

@<Convert a rule preamble to a ROUTINE node and enter rule mode@> =
	#ifdef list_node_type
	if (stop_character == ':') {
		if ((sfsm->inside_rule_mode) && (ControlStructures::detect(W))) {
			Node::set_type(new, list_entry_node_type);
			#ifdef CORE_MODULE
			Annotations::write_int(new, colon_block_command_ANNOT, TRUE);
			#endif
			sfsm->inside_rule_mode = TRUE;
			return;
		} else {
			Node::set_type(new, list_node_type);
			sfsm->inside_rule_mode = TRUE;
			return;
		}
	}
	#endif

@ Subsequent commands are divided by semicolons, and any failure of a
semicolon to appear indicates an end of the rule.

@<Convert to a COMMAND node and exit rule mode unless a semicolon implies more@> =
	#ifdef list_node_type
	Node::set_type(new, list_entry_node_type);
	#endif
	if (stop_character != ';') sfsm->inside_rule_mode = FALSE;
	return;

@ Finally, we must tidy away the previously detected "begins here" and
"ends here" sentences into nodes on the tree.

@<Convert a begins here or ends here sentence to a BEGINHERE or ENDHERE node and return@> =
	if (begins_or_ends == 1) {
		Node::set_type(new, BEGINHERE_NT);
		Node::set_text(new, Wordings::trim_last_word(Wordings::trim_last_word(W)));
		#ifdef BEGIN_OR_END_HERE_SYNTAX_CALLBACK
		BEGIN_OR_END_HERE_SYNTAX_CALLBACK(new, sfsm->ref);
		#endif
		return;
	}
	if (begins_or_ends == -1) {
		Node::set_type(new, ENDHERE_NT);
		Node::set_text(new, Wordings::trim_last_word(Wordings::trim_last_word(W)));
		#ifdef BEGIN_OR_END_HERE_SYNTAX_CALLBACK
		BEGIN_OR_END_HERE_SYNTAX_CALLBACK(new, sfsm->ref);
		#endif
		return;
	}

@ Why are we taking a sneak look at this sentence now? Because it affects
which headings we read the contents of. If we waited until sentence traverses,
it would be too late.

@<Detect a language definition sentence and sneakily act upon it@> =
	current_sentence = new;
	#ifdef LANGUAGE_ELEMENT_SYNTAX_CALLBACK
	LANGUAGE_ELEMENT_SYNTAX_CALLBACK(GET_RW(<language-modifying-sentence>, 1));
	#endif
	Annotations::write_int(new, language_element_ANNOT, TRUE);
	Annotations::write_int(new, sentence_unparsed_ANNOT, FALSE);

@ And for similar reasons:

@<Detect a Preform grammar inclusion and sneakily act upon it@> =
	current_sentence = new;
	Preform::parse_preform(GET_RW(<language-modifying-sentence>, 1), TRUE);
	Annotations::write_int(new, sentence_unparsed_ANNOT, FALSE);

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_SYNTAX_CALLBACK|
to some routine of her own, gazumping this one.

=
void Sentences::syntax_problem(int err_no, wording W, void *ref, int k) {
	#ifdef PROBLEM_SYNTAX_CALLBACK
	PROBLEM_SYNTAX_CALLBACK(err_no, W, ref, k);
	#endif
	#ifndef PROBLEM_SYNTAX_CALLBACK
	TEMPORARY_TEXT(text);
	WRITE_TO(text, "%+W", W);
	switch (err_no) {
		case UnexpectedSemicolon_SYNERROR:
			Errors::with_text("unexpected semicolon in sentence: %S", text);
			break;
		case ParaEndsInColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon: %S", text);
			break;
		case SentenceEndsInColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon and full stop: %S", text);
			break;
		case SentenceEndsInSemicolon_SYNERROR:
			Errors::with_text("paragraph ends with a semicolon and full stop: %S", text);
			break;
		case SemicolonAfterColon_SYNERROR:
			Errors::with_text("paragraph ends with a colon and semicolon: %S", text);
			break;
		case SemicolonAfterStop_SYNERROR:
			Errors::with_text("paragraph ends with a full stop and semicolon: %S", text);
			break;
		case ExtNoBeginsHere_SYNERROR:
			Errors::nowhere("extension has no beginning");
			break;
		case ExtNoEndsHere_SYNERROR:
			Errors::nowhere("extension has no end");
			break;
		case ExtSpuriouslyContinues_SYNERROR:
			Errors::with_text("extension continues after end: %S", text);
			break;
		case HeadingOverLine_SYNERROR:
			Errors::with_text("heading contains a line break: %S", text);
			break;
		case HeadingStopsBeforeEndOfLine_SYNERROR:
			Errors::with_text("heading stops before end of line: %S", text);
			break;
	}
	DISCARD_TEXT(text);
	#endif
}
