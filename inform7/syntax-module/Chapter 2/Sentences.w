[Sentences::] Sentences.

To break up the stream of words produced by the lexer into
English sentences, and join each to the parse tree.

@h Definitions.

@ The following need to be available so that we can parse the source text
position.

=
int no_sentences_read = 0;
int sfsm_extension_position = 0; /* 0: not an extension; 1: before "begins here"; 2: before "ends here"; 3: after */
node_type_t ssnt = 0;

parse_node *standard_rules_inclusion_point = NULL;
parse_node *language_extension_inclusion_point = NULL; /* after the Standard Rules */

@

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
So we carry out the sentence breaking with a simple finite state machine --
the last sentence having been a rule preamble tells us that the current one
is probably a phrase, and so on -- and the following is its state.

=
source_file *sfsm_source_file = NULL;
int sfsm_inside_rule_mode = FALSE;
int sfsm_skipping_material_at_level = -1;
int sfsm_in_tabbed_mode = FALSE;
EXTENSION_FILE_TYPE *sfsm_extension = NULL;

@ Now for the routine itself. We break into bite-sized chunks, each of which is
despatched to the |Sentences::make_node| routine with a note of the punctuation
which was used to end it. Each call to this routine represents one cycle of our
finite state machine.

=
void Sentences::break(wording W, EXTENSION_FILE_TYPE *from_extension) {
	int sentence_start = Wordings::first_wn(W);
	ParseTree::enable_last_sentence_cacheing();

	@<Reset the sentence finite state machine@>;
	@<Go into table sentence mode if necessary@>;

	LOOP_THROUGH_WORDING(position, W)
		if (sentence_start < position) {
			int no_stop_words, back_up_one_word;
			int stop_character;

			@<Look for a sentence break, finding the number of stop words and the stop character@>;
			if (no_stop_words > 0) {
				Sentences::make_node(Wordings::new(sentence_start, position-1), stop_character);
				position = position + no_stop_words - 1;
				if (back_up_one_word) sentence_start = position;
				else sentence_start = position + 1;

				@<Go into table sentence mode if necessary@>;
			}
		}

	if ((sentence_start < Wordings::last_wn(W)) ||
		((sentence_start == Wordings::last_wn(W)) && (!(Lexer::word(Wordings::last_wn(W)) == PARBREAK_V)))) {
		Sentences::make_node(Wordings::from(W, sentence_start), '.');
	}

	ParseTree::disable_last_sentence_cacheing();

	if (from_extension)
		@<Issue a problem message if we are missing the begin and end here sentences@>;
	@<Reset the sentence finite state machine@>;
}

@ Each call to |Sentences::break| starts afresh, with no residual state
left over from previous calls. (The same cannot be said for |Sentences::make_node|,
which constructs individual sentences and is repeatedly called by us, and
that is why these are global variables rather than locals in |Sentences::break|.)

@<Reset the sentence finite state machine@> =
	sfsm_source_file = NULL;
	sfsm_inside_rule_mode = FALSE;
	sfsm_skipping_material_at_level = -1;
	sfsm_extension = from_extension;
	if (from_extension) sfsm_extension_position = 1;
	else sfsm_extension_position = 0;

@ A table is any sentence beginning with the word "Table". (Bad news for
anyone writing "Table Mountain is a room.", of course, but there are other
ways to do that, and it seems wise to keep the syntax for tables clear,
since their entries are governed by different lexical and semantic rules.)

@<Go into table sentence mode if necessary@> =
	if ((<structural-sentence>(Wordings::from(W, sentence_start))) &&
		(ParseTree::test_flag(ssnt, TABBED_CONTENT_NFLAG)))
		sfsm_in_tabbed_mode = TRUE;
	else
		sfsm_in_tabbed_mode = FALSE;

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

	|Before going north:|
	|    say "Northward ho!";|
	|    now the compass points north;|

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
	SYNTAX_PROBLEM_HANDLER(ParaEndsInColon_SYNERROR, Wordings::new(sentence_start, at-1), NULL, 0);

@<Issue problem for colon at end of sentence@> =
	SYNTAX_PROBLEM_HANDLER(SentenceEndsInColon_SYNERROR, Wordings::new(sentence_start, at), NULL, 0);

@<Issue problem for semicolon at end of sentence@> =
	SYNTAX_PROBLEM_HANDLER(SentenceEndsInSemicolon_SYNERROR, Wordings::new(sentence_start, at), NULL, 0);

@<Issue problem for semicolon after colon@> =
	SYNTAX_PROBLEM_HANDLER(SemicolonAfterColon_SYNERROR, Wordings::new(sentence_start, at), NULL, 0);

@<Issue problem for semicolon after full stop@> =
	SYNTAX_PROBLEM_HANDLER(SemicolonAfterStop_SYNERROR, Wordings::new(sentence_start, at), NULL, 0);

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
		(sfsm_in_tabbed_mode == FALSE) && /* check that we are not scanning the body of a table */
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
and if so, the state |sfsm_skipping_material_at_level| is set to the
level of the heading in question. We then skip all subsequent sentences
until reaching the next heading of the same or higher status, or until
reaching the "... ends here." sentence (if we are reading an extension),
or until reaching the end of the text: whichever comes first.

=
void Sentences::make_node(wording W, int stop_character) {
	int heading_level = 0, begins_or_ends = 0;
	parse_node *new;

	if (Wordings::empty(W)) internal_error("empty sentence generated");

	#ifdef SENTENCE_COUNT_MONITOR
	if (SENTENCE_COUNT_MONITOR(W)) no_sentences_read++;
	#else
	no_sentences_read++;
	#endif

	Vocabulary::identify_word_range(W); /* a precaution to catch any late unidentified text */

	@<Detect a change of source file, and declare it as an implicit heading@>;
	@<Detect a dividing sentence@>;

	if ((begins_or_ends == -1) ||
		((heading_level > 0) && (heading_level <= sfsm_skipping_material_at_level)))
		sfsm_skipping_material_at_level = -1;

	if (sfsm_skipping_material_at_level >= 0) return;

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
	if (Lexer::file_of_origin(Wordings::first_wn(W)) != sfsm_source_file) {
		parse_node *implicit_heading = ParseTree::new(HEADING_NT);
		ParseTree::set_text(implicit_heading, W);
		ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
		ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
		ParseTree::insert_sentence(implicit_heading);
		#ifdef NEW_HEADING_HANDLER
		NEW_HEADING_HANDLER(implicit_heading);
		#endif
		sfsm_skipping_material_at_level = -1;
	}
	sfsm_source_file = Lexer::file_of_origin(Wordings::first_wn(W));

@<Reject if we have run on past the end of an extension@> =
	if ((sfsm_extension_position == 3) && (begins_or_ends == 0)) {
		SYNTAX_PROBLEM_HANDLER(ExtSpuriouslyContinues_SYNERROR, W, sfsm_extension, 0);
		sfsm_extension_position = 4; /* to avoid multiply issuing this */
	}

@ The client must define a Preform nonterminal called |<dividing-sentence>|
which returns either a heading level number (1 to 10, with 1 the most
important), or |-1| to mean that the sentence begins an extension, or
|-2| that it ends one.

@<Detect a dividing sentence@> =
	if (<dividing-sentence>(W)) {
		switch (<<r>>) {
			case -1: if (sfsm_extension_position > 0) begins_or_ends = 1;
				break;
			case -2:
				if (sfsm_extension_position > 0) begins_or_ends = -1;
				break;
			default:
				heading_level = <<r>>;
				break;
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
				SYNTAX_PROBLEM_HANDLER(HeadingOverLine_SYNERROR, W, NULL, k);
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
			(k<=Wordings::last_wn(W)+8) && (k<lexer_wordcount) && (Lexer::break_before(k) != '\n');
			k++) ;
		SYNTAX_PROBLEM_HANDLER(HeadingStopsBeforeEndOfLine_SYNERROR, W, NULL, k);
	}

@ We now have a genuine heading, and can declare it, calling a routine
in Headings to determine whether we should include the material.

@<Make a new HEADING node, possibly beginning to skip material@> =
	new = ParseTree::new(HEADING_NT);
	ParseTree::set_text(new, W);
	ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(new, heading_level_ANNOT, heading_level);
	ParseTree::insert_sentence(new);
	#ifdef NEW_HEADING_HANDLER
	if (NEW_HEADING_HANDLER(new) == FALSE)
		sfsm_skipping_material_at_level = heading_level;
	#endif

@ When we finish scanning all the sentences in a given batch, and if they came
from an extension, we need to make sure we saw both beginning and end:

@<Issue a problem message if we are missing the begin and end here sentences@> =
	switch (sfsm_extension_position) {
		case 1: SYNTAX_PROBLEM_HANDLER(ExtNoBeginsHere_SYNERROR, W, sfsm_extension, 0); break;
		case 2: SYNTAX_PROBLEM_HANDLER(ExtNoEndsHere_SYNERROR, W, sfsm_extension, 0); break;
		case 3: break;
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
(Strictly speaking it's the second sentence read, not the first, because all
source texts implicitly begin with an inclusion of the Standard Rules.)

=
<if-start-of-source-text> internal 0 {
	int w1 = Wordings::first_wn(W);
	#ifdef CORE_MODULE
	int N = 1 + Projects::number_of_early_fed_sentences(Inbuild::project());
	#endif
	#ifndef CORE_MODULE
	int N = 3;
	#endif
	if ((no_sentences_read == N) &&
		((w1 == 0) || (compare_word(w1-1, PARBREAK_V)))) return TRUE;
	return FALSE;
}

@ When Inform reads the (optional!) Options file, very early in its run, it
tries to obey any use options in the file right away -- earlier even than
<structural-sentence>. It spots these, very crudely, as sentences which
match the following (that is, which start with "use"). Note the final full
stop -- it's needed before sentence-breaking has even taken place.

=
<use-option-sentence-shape> ::=
	use ... .

@<Accept the new sentence as one or more nodes in the parse tree@> =
	@<Convert comma-divided rule into two sentences, if this is allowed@>;
	@<Otherwise, make a SENTENCE node@>;

	@<Convert a rule preamble to a ROUTINE node and enter rule mode@>;
	if (sfsm_inside_rule_mode)
		@<Convert to a COMMAND node and exit rule mode unless a semicolon implies further commands@>
	else if (stop_character == ';') {
		SYNTAX_PROBLEM_HANDLER(UnexpectedSemicolon_SYNERROR, W, NULL, 0);
		stop_character = '.';
	}

	/* at this point we are certainly in assertion mode, not rule mode */
	if (<structural-sentence>(W)) {
		if (<<r>> == -1)
			@<Detect a language definition sentence and sneakily act upon it@>
		else if (<<r>> == -2) {
			@<Detect a Preform grammar inclusion and sneakily act upon it@>
			ParseTree::set_type(new, ssnt); return;
		} else {
			if (ssnt == INCLUDE_NT) {
				new->down = <<rp>>;
				if (standard_rules_inclusion_point == NULL) standard_rules_inclusion_point = new;
				else if (language_extension_inclusion_point == NULL) language_extension_inclusion_point = new;
			}
			ParseTree::set_type(new, ssnt);
			#ifdef IF_MODULE
			if (ssnt == BIBLIOGRAPHIC_NT)
				NaturalLanguages::set_language_of_play(
					PL::Bibliographic::scan_language(new));
			#endif
			return;
		}
	}

	@<Convert a begins here or ends here sentence to a BEGINHERE or ENDHERE node and return@>;

	/* none of that happened, so we have a SENTENCE node for certain */
	ParseTree::annotate_int(new, sentence_unparsed_ANNOT, TRUE);
	#ifdef SENTENCE_ANNOTATION_FUNCTION
	SENTENCE_ANNOTATION_FUNCTION(new);
	#endif

@ Rules are ordinarily detected by their colon, which divides the header from the
rest: colons are not otherwise legal in Inform. But there's an exception. If the
sentence consists of text matching the following grammar, followed by comma,
followed by more text, then the comma is read as if it's a colon and the
sentence becomes a rule. For example:

>> Instead of going north, try entering the cage

=
<comma-divisible-sentence> ::=
	instead of ... |
	every turn *** |
	before ... |
	after ... |
	when ...

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
	if ((sfsm_inside_rule_mode == FALSE)
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
		Sentences::make_node(Wordings::up_to(W, Wordings::last_wn(AW)), ':'); /* rule preamble stopped with a colon */
		Sentences::make_node(BW, '.'); /* rule body with one sentence, stopped with a stop */
		return;
	}

@<Set earliest comma to position after the or, if there is one@> =
	if (<list-or-division>(W)) {
		wording BW = GET_RW(<list-or-division>, 2);
		earliest_comma_position = Wordings::first_wn(BW);
	}

@ At this point we know that the text |W| will make one and only
one sentence node in the parse tree, so we may as well create and ParseTree::graft it
now. There are a number of special cases with variant node types, but the
commonest outcome is a SENTENCE node, so that's what we shall assume for now.

@<Otherwise, make a SENTENCE node@> =
	new = ParseTree::new(SENTENCE_NT);
	ParseTree::set_text(new, W);
	ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
	ParseTree::insert_sentence(new);

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

	|To do one thing: something here;|
	|To do another thing: something else here;|

A strict reading of our rules would oblige us to consider "To do another
thing:" as a phrase within the definition of "To do one thing", and
we would then have to issue a problem message. But this would be pettifogging.
(People who habitually shuffle phrases about in their editors tend not to
want to fuss about changing the punctuation of the last to a full stop
instead of a semicolon. We may lament this, but it is so.)

@<Convert a rule preamble to a ROUTINE node and enter rule mode@> =
	#ifdef list_node_type
	if (stop_character == ':') {
		if ((sfsm_inside_rule_mode) && (Sentences::RuleSubtrees::detect_control_structure(W))) {
			ParseTree::set_type(new, list_entry_node_type);
			ParseTree::annotate_int(new, colon_block_command_ANNOT, TRUE);
			sfsm_inside_rule_mode = TRUE;
			return;
		} else {
			ParseTree::set_type(new, list_node_type);
			sfsm_inside_rule_mode = TRUE;
			return;
		}
	}
	#endif

@ Subsequent commands are divided by semicolons, and any failure of a
semicolon to appear indicates an end of the rule.

@<Convert to a COMMAND node and exit rule mode unless a semicolon implies further commands@> =
	#ifdef list_node_type
	ParseTree::set_type(new, list_entry_node_type);
	#endif
	if (stop_character != ';') sfsm_inside_rule_mode = FALSE;
	return;

@ Finally, we must tidy away the previously detected "begins here" and
"ends here" sentences into nodes on the tree.

@<Convert a begins here or ends here sentence to a BEGINHERE or ENDHERE node and return@> =
	if (begins_or_ends == 1) {
		ParseTree::set_type(new, BEGINHERE_NT);
		ParseTree::set_text(new, Wordings::trim_last_word(Wordings::trim_last_word(W)));
		#ifdef NEW_BEGINEND_HANDLER
		NEW_BEGINEND_HANDLER(new, sfsm_extension);
		#endif
		return;
	}
	if (begins_or_ends == -1) {
		ParseTree::set_type(new, ENDHERE_NT);
		ParseTree::set_text(new, Wordings::trim_last_word(Wordings::trim_last_word(W)));
		#ifdef NEW_BEGINEND_HANDLER
		NEW_BEGINEND_HANDLER(new, sfsm_extension);
		#endif
		return;
	}

@ Why are we taking a sneak look at this sentence now? Because it affects
which headings we read the contents of. If we waited until sentence traverses,
it would be too late.

@<Detect a language definition sentence and sneakily act upon it@> =
	current_sentence = new;
	#ifdef NEW_LANGUAGE_HANDLER
	NEW_LANGUAGE_HANDLER(GET_RW(<language-modifying-sentence>, 1));
	#endif
	ParseTree::annotate_int(new, language_element_ANNOT, TRUE);
	ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);

@ And for similar reasons:

@<Detect a Preform grammar inclusion and sneakily act upon it@> =
	current_sentence = new;
	Preform::parse_preform(GET_RW(<language-modifying-sentence>, 1), TRUE);
	ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
