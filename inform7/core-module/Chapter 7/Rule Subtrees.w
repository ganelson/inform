[Sentences::RuleSubtrees::] Rule Subtrees.

To tidy up |INVOCATION_LIST_NT| nodes into a list of children under the
relevant |ROUTINE_NT| node, and so turn each rule definition into a single
subtree.

@h Definitions.

@ Initially, the phrases (|INVOCATION_LIST_NT|) making up a rule (|ROUTINE_NT|) are
simply listed after it in the parse tree, but we want them to become its
children: this is the only thing the $A$-grammar does with rules, which
otherwise wait until later to be dealt with.

The single routine in this section accomplishes the regrouping: after it
runs, every |INVOCATION_LIST_NT| is a child of the |ROUTINE_NT| header to which it
belongs.

@ Certain phrases are "structural": otherwise, if, repeat, while and so
on. These have different expectations in terms of the layout of surrounding
phrases in rule or phrase definitions, and the following structure defines
the relevant behaviour. (The contents are static.)

=
typedef struct control_structure_phrase {
	struct control_structure_phrase *subordinate_to;
	int indent_subblocks;
	int body_empty_except_for_subordinates;
	int used_at_stage;
	int is_a_loop;
	int requires_new_syntax;
	int allow_run_on;
	wchar_t *keyword;
	MEMORY_MANAGEMENT
} control_structure_phrase;

control_structure_phrase
	*switch_CSP = NULL,
	*if_CSP = NULL,
	*repeat_CSP = NULL,
	*while_CSP = NULL,
	*otherwise_CSP = NULL,
	*abbreviated_otherwise_CSP = NULL,
	*otherwise_if_CSP = NULL,
	*default_case_CSP = NULL,
	*case_CSP = NULL,
	*say_CSP = NULL,
	*now_CSP = NULL,
	*instead_CSP = NULL;

@ This routine is used whenever new material is added. Whenever it finds a
childless |ROUTINE_NT| followed by a sequence of |INVOCATION_LIST_NT| nodes, it
joins these in sequence as children of the |ROUTINE_NT|. Since it always
acts so as to leave a non-zero number of children, and since it acts only
on childless nodes, it cannot ever act on the same node twice.

=
void Sentences::RuleSubtrees::register_recently_lexed_phrases(void) {
	if (problem_count > 0) return; /* for then the tree is perhaps broken anyway */
	ParseTree::traverse(Sentences::RuleSubtrees::demote_command_nodes);
	ParseTree::traverse(Sentences::RuleSubtrees::detect_loose_command_nodes);
}

@ Command nodes are demoted to be children of routine nodes:

=
void Sentences::RuleSubtrees::demote_command_nodes(parse_node *p) {
	if ((ParseTree::get_type(p) == ROUTINE_NT) && (p->down == NULL)) {
		parse_node *end_def = p;
		while ((end_def->next) && (ParseTree::get_type(end_def->next) == INVOCATION_LIST_NT))
			end_def = end_def->next;
		if (p == end_def) return; /* |ROUTINE_NT| not followed by any |INVOCATION_LIST_NT|s */
		/* splice so that |p->next| to |end_def| become the children of |p|: */
		p->down = p->next;
		p->next = end_def->next;
		end_def->next = NULL;
		Sentences::RuleSubtrees::parse_routine_structure(p);
	}
}

@ And just in case:

=
void Sentences::RuleSubtrees::detect_loose_command_nodes(parse_node *p) {
	if (ParseTree::get_type(p) == INVOCATION_LIST_NT)
		internal_error("loose COMMAND node outside of rule definition");
}

@h Parsing Routine Structure.
There are now two possible syntaxes to express the structural makeup of a
routine. Traditional I7 syntax for blocks is to place them within begin/end
markers: the "begin" occurring at the end of the conditional or loop header,
and the "end if", "end while", etc., as a phrase of its own at the end of
the block. Newer I7 syntax (March 2008) is to use Python-style colons and
indentation. Both are allowed, but not in the same routine.

This routine opens with the routine's parse tree consisting of a simple
linked list of code-point nodes, one for each phrase. We must work out
which syntax is used, decipher it, and turn the list into a proper tree
structure in a single unified format.

How much simpler this would all be if we could abolish the old format, but
it's kept for the benefit of partially sighted users, who find tabbed
indentation difficult to manage with screen-readers.

=
void Sentences::RuleSubtrees::parse_routine_structure(parse_node *routine_node) {
	int initial_problem_count = problem_count;

	parse_node *uses_colon_syntax = NULL;
	parse_node *uses_begin_end_syntax = NULL;
	parse_node *mispunctuates_begin_end_syntax = NULL;
	parse_node *requires_colon_syntax = NULL;

	@<(a.1) See which block syntax is used by conditionals and loops@>;
	@<(a.2) Report problems if the two syntaxes are mixed up with each other@>;
	if (problem_count > initial_problem_count) return;

	if (uses_colon_syntax) @<(b.1) Annotate the parse tree with indentation levels@>;
	@<(b.2) Annotate the parse tree with control structure usage@>;

	@<(c) Expand comma notation for blocks@>;
	if (problem_count > initial_problem_count) return;

	if (uses_colon_syntax) @<(d) Insert end nodes and check the indentation@>;
	if (problem_count > initial_problem_count) return;

	@<(e) Structure the parse tree to match the use of control structures@>;
	if (problem_count > initial_problem_count) return;

	@<(f) Police the structure of the parse tree@>;
	if (problem_count > initial_problem_count) return;

	@<(g) Optimise out the otherwise if nodes@>;
	if (problem_count > initial_problem_count) return;

	@<(h) Remove any end markers as no longer necessary@>;
	if (problem_count > initial_problem_count) return;

	if (uses_colon_syntax == FALSE)
		@<(i) Remove any begin markers as no longer necessary@>;

	@<(j) Insert code block nodes so that nodes needing to be parsed are childless@>;
	@<(k) Insert instead marker nodes@>;
	@<(l) Break up say phrases@>;
}

@<(a.1) See which block syntax is used by conditionals and loops@> =
	parse_node *p;
	for (p = routine_node->down; p; p = p->next) {
		control_structure_phrase *csp =
			Sentences::RuleSubtrees::detect_control_structure(ParseTree::get_text(p));
		if (csp) {
			int syntax_used = ParseTree::int_annotation(p, colon_block_command_ANNOT);
			if (syntax_used == FALSE) { /* i.e., doesn't end with a colon */
				/* don't count "if x is 1, let y be 2" -- with no block -- as deciding it */
				if ((csp->subordinate_to == NULL) &&
					(!(<phrase-beginning-block>(ParseTree::get_text(p)))))
					syntax_used = NOT_APPLICABLE;
			}
			if (syntax_used != NOT_APPLICABLE) {
				if (syntax_used) {
					if (uses_colon_syntax == NULL) uses_colon_syntax = p;
				} else {
					@<Note what looks like a begin-end piece of syntax@>;
				}
			}
			if ((csp->requires_new_syntax) && (requires_colon_syntax == NULL))
				requires_colon_syntax = p;
		}
		if (Sentences::RuleSubtrees::detect_end_control_structure(ParseTree::get_text(p))) {
			if (uses_begin_end_syntax == NULL)
				uses_begin_end_syntax = p;
		}
	}

@ It's possible in oddball cases to mis-punctuate such as to fool us, so:

@<Note what looks like a begin-end piece of syntax@> =
	if ((uses_begin_end_syntax == NULL) && (mispunctuates_begin_end_syntax == NULL)) {
		if (<phrase-beginning-block>(ParseTree::get_text(p)))
			uses_begin_end_syntax = p;
		else
			mispunctuates_begin_end_syntax = p;
	}

@<(a.2) Report problems if the two syntaxes are mixed up with each other@> =
	if ((uses_colon_syntax) && (mispunctuates_begin_end_syntax)) {
		current_sentence = routine_node;
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, mispunctuates_begin_end_syntax);
		Problems::Issue::handmade_problem(_p_(PM_BadOldSyntax));
		Problems::issue_problem_segment(
			"The rule or phrase definition %1 seems to use indentation and "
			"colons to group phrases together into 'if', 'repeat' or 'while' "
			"blocks. That's fine, but then this phrase seems to be missing "
			"some punctuation - %2. Perhaps a colon is missing?");
		Problems::issue_problem_end();
		return;
	}

	if ((uses_colon_syntax) && (uses_begin_end_syntax)) {
		current_sentence = routine_node;
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, uses_colon_syntax);
		Problems::quote_source(3, uses_begin_end_syntax);
		Problems::Issue::handmade_problem(_p_(PM_BothBlockSyntaxes));
		Problems::issue_problem_segment(
			"The rule or phrase definition %1 seems to use both ways of grouping "
			"phrases together into 'if', 'repeat' and 'while' blocks at once. "
			"Inform allows two alternative forms, but they cannot be mixed in "
			"the same definition. %POne way is to end the 'if', 'repeat' or "
			"'while' phrases with a 'begin', and then to match that with an "
			"'end if' or similar. ('Otherwise' or 'otherwise if' clauses are "
			"phrases like any other, and end with semicolons in this case.) "
			"You use this begin/end form here, for instance - %3. %P"
			"The other way is to end with a colon ':' and then indent the "
			"subsequent phrases underneath, using tabs. (Note that any "
			"'otherwise' or 'otherwise if' clauses also have to end with "
			"colons in this case.) You use this indented form here - %2.");
		Problems::issue_problem_end();
		return;
	}

	if ((requires_colon_syntax) && (uses_begin_end_syntax)) {
		current_sentence = routine_node;
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, requires_colon_syntax);
		Problems::Issue::handmade_problem(_p_(PM_NotInOldSyntax));
		Problems::issue_problem_segment(
			"The construction %2, in the rule or phrase definition %1, "
			"is only allowed if the rule is written in the 'new' format, "
			"that is, with the phrases written one to a line with "
			"indentation showing how they are grouped together, and "
			"with colons indicating the start of such a group.");
		Problems::issue_problem_end();
		return;
	}

@ If we're using Pythonesque notation, then the number of tab stops of
indentation of a phrase tells us where it belongs in the structure, so
we mark up the tree with that information.

@<(b.1) Annotate the parse tree with indentation levels@> =
	ParseTree::annotate_int(routine_node, indentation_level_ANNOT,
		Lexer::indentation_level(Wordings::first_wn(ParseTree::get_text(routine_node))));
	parse_node *p;
	for (p = routine_node->down; p; p = p->next) {
		int I = Lexer::indentation_level(Wordings::first_wn(ParseTree::get_text(p)));
		ParseTree::annotate_int(p, indentation_level_ANNOT, I);
	}

@ Note that we are a little cautious about recognising phrases which will
open blocks, such as "repeat...", because of the dangers of false positives;
so we look for the "begin" keyword, or the colon. We're less cautious with
subordinate phrases (such as "otherwise") because we know their wonding
more certainly, and similarly for "end X" phrases.

@<(b.2) Annotate the parse tree with control structure usage@> =
	for (parse_node *p = routine_node->down; p; p = p->next) {
		control_structure_phrase *csp;
		csp = Sentences::RuleSubtrees::detect_control_structure(ParseTree::get_text(p));
		if (csp) {
			if ((ParseTree::int_annotation(p, colon_block_command_ANNOT)) ||
				(<phrase-beginning-block>(ParseTree::get_text(p))) ||
				(csp->subordinate_to)) {
				ParseTree::set_control_structure_used(p, csp);
				if (csp == case_CSP) @<Trim a switch case to just the case value@>;
			}
		}
		csp = Sentences::RuleSubtrees::detect_end_control_structure(ParseTree::get_text(p));
		if (csp) ParseTree::set_end_control_structure_used(p, csp);
	}

@ At this point anything at all can be a case value: it won't be parsed
or type-checked until compilation.

@<Trim a switch case to just the case value@> =
	ParseTree::set_text(p, GET_RW(<control-structure-phrase>, 1));

@ "Comma notation" is when a comma is used in an "if" statement to divide
off only a single consequential phrase, as in

>> if the hat is worn, try dropping the hat;

Such a line occupies a single node in its routine's parse tree, and we need
to break this up.

@<(c) Expand comma notation for blocks@> =
	for (parse_node *p = routine_node->down; p; p = p->next)
		if (ParseTree::get_control_structure_used(p) == NULL) {
			control_structure_phrase *csp;
			csp = Sentences::RuleSubtrees::detect_control_structure(ParseTree::get_text(p));
			if ((csp == if_CSP) && (<phrase-with-comma-notation>(ParseTree::get_text(p))))
				@<Effect a comma expansion@>;
		}

@<Effect a comma expansion@> =
	wording BCW = GET_RW(<phrase-with-comma-notation>, 1); /* text before the comma */
	wording ACW = GET_RW(<phrase-with-comma-notation>, 2); /* text after the comma */

	/* First trim and annotate the "if ..." part */
	ParseTree::annotate_int(p, colon_block_command_ANNOT, TRUE); /* it previously had no colon... */
	ParseTree::set_control_structure_used(p, csp); /* ...and therefore didn't have its CSP set */
	ParseTree::set_text(p, BCW);

	/* Now make a new node for the "then" part, indenting it one step inward */
	parse_node *then_node = ParseTree::new(INVOCATION_LIST_NT);
	ParseTree::annotate_int(then_node, results_from_splitting_ANNOT, TRUE);
	ParseTree::annotate_int(then_node, indentation_level_ANNOT,
		ParseTree::int_annotation(p, indentation_level_ANNOT) + 1);
	ParseTree::set_text(then_node, ACW);

	parse_node *last_node_of_if_construction = then_node, *rest_of_routine = p->next;

	/* Attach the "then" node after the "if" node: */
	p->next = then_node;

	@<Deal with an immediately following otherwise node, if there is one@>;

	if (uses_colon_syntax == FALSE) {
		last_node_of_if_construction->next = Sentences::RuleSubtrees::end_node(p);
		last_node_of_if_construction->next->next = rest_of_routine;
	} else {
		last_node_of_if_construction->next = rest_of_routine;
	}

@<Deal with an immediately following otherwise node, if there is one@> =
	if (rest_of_routine)
		if ((uses_colon_syntax == FALSE) ||
			(ParseTree::int_annotation(p, indentation_level_ANNOT) ==
				ParseTree::int_annotation(rest_of_routine, indentation_level_ANNOT))) {
			if (ParseTree::get_control_structure_used(rest_of_routine) == otherwise_CSP)
				@<Deal with an immediately following otherwise@>
			else if (Sentences::RuleSubtrees::abbreviated_otherwise(ParseTree::get_text(rest_of_routine)))
				@<Deal with an abbreviated otherwise node@>;
		}

@ We string a plain "otherwise" node onto the "if" construction.

@<Deal with an immediately following otherwise@> =
	then_node->next = rest_of_routine;
	last_node_of_if_construction = last_node_of_if_construction->next;
	rest_of_routine = rest_of_routine->next;

@ An abbreviated otherwise clause looks like this:

>> otherwise award 4 points;

and we want to split this, too, into distinct nodes.

@<Deal with an abbreviated otherwise node@> =
	parse_node *otherwise_node = ParseTree::new(CODE_BLOCK_NT);
	ParseTree::annotate_int(otherwise_node, results_from_splitting_ANNOT, TRUE);
	ParseTree::annotate_int(otherwise_node, indentation_level_ANNOT,
		ParseTree::int_annotation(p, indentation_level_ANNOT));
	ParseTree::set_text(otherwise_node,
		Wordings::one_word(Wordings::first_wn(ParseTree::get_text(rest_of_routine)))); /* extract just the word "otherwise" */
	ParseTree::set_control_structure_used(otherwise_node, otherwise_CSP);

	then_node->next = otherwise_node;
	otherwise_node->next = rest_of_routine;

	ParseTree::set_text(rest_of_routine,
		Wordings::trim_first_word(ParseTree::get_text(rest_of_routine))); /* to remove the "otherwise" */

	ParseTree::annotate_int(rest_of_routine, indentation_level_ANNOT,
		ParseTree::int_annotation(rest_of_routine, indentation_level_ANNOT) + 1);

	last_node_of_if_construction = rest_of_routine;
	rest_of_routine = rest_of_routine->next;

@ If the old-style syntax is used, there are explicit "end if", "end repeat"
and "end while" nodes in the list already. But if the Pythonesque syntax is
used then we need to create these nodes and insert them into the list; we
do these by reading off the structure from the pattern of indentation. It's
quite a long task, since this pattern may contain errors, which we have to
report more or less helpfully.

@<(d) Insert end nodes and check the indentation@> =
	parse_node *p, *prev, *run_on_at = NULL;
	parse_node *first_misaligned_phrase = NULL, *first_overindented_phrase = NULL;
	int k, indent, expected_indent = 1, indent_misalign = FALSE, indent_overmuch = FALSE,
		just_opened_block = FALSE;

	/* the blocks open stack holds blocks currently open */
	parse_node *blstack_opening_phrase[GROSS_AMOUNT_OF_INDENTATION+1];
	control_structure_phrase *blstack_construct[GROSS_AMOUNT_OF_INDENTATION+1];
	int blstack_stage[GROSS_AMOUNT_OF_INDENTATION+1];
	int blo_sp = 0, suppress_further_problems = FALSE;

	if (ParseTree::int_annotation(routine_node, indentation_level_ANNOT) != 0)
		@<Issue problem message for failing to start flush on the left margin@>;

	for (prev = NULL, p = routine_node->down, k=1; p; prev = p, p = p->next, k++) {
		control_structure_phrase *csp = ParseTree::get_control_structure_used(p);
		@<Determine actual indentation of this phrase@>;
		@<Compare actual indentation to what we expect from structure so far@>;
		@<Insert begin marker and increase expected indentation if a block begins here@>;
	}

	indent = 1;
	@<Try closing blocks to bring expected indentation down to match@>;

	if (indent_overmuch) @<Issue problem message for an excess of indentation@>
	else if (run_on_at) @<Issue problem message for run-ons within phrase definition@>
	else if (indent_misalign) @<Issue problem message for misaligned indentation@>;

@ Controversially:

@<Issue problem message for failing to start flush on the left margin@> =
	current_sentence = routine_node;
	Problems::quote_source_eliding_begin(1, current_sentence);
	Problems::Issue::handmade_problem(_p_(PM_NonflushRule));
	Problems::issue_problem_segment(
		"The phrase or rule definition %1 is written using tab indentations "
		"to show how its phrases are to be grouped together. But in that "
		"case the opening line needs to be on the left margin, not indented.");
	Problems::issue_problem_end();
	suppress_further_problems = TRUE;

@ Here we set |indent| to the number of tab-stops in from the margin, or to
|expected_indent| if the text does not appear to be at the start of its own
line in the source (because it runs on from a previous phrase, in
which case we set the |run_on_at| flag: except for following on from cases
in switches with a non-control-structure, which is allowed, because otherwise
the lines often look silly and short).

@<Determine actual indentation of this phrase@> =
	indent = expected_indent;
	if (ParseTree::int_annotation(p, indentation_level_ANNOT) > 0)
		indent = ParseTree::int_annotation(p, indentation_level_ANNOT);
	else if (Wordings::nonempty(ParseTree::get_text(p))) {
		switch (Lexer::break_before(Wordings::first_wn(ParseTree::get_text(p)))) {
			case '\n': indent = 0; break;
			case '\t': indent = 1; break;
			default:
				if ((prev) && (csp == NULL)) {
					control_structure_phrase *pcsp = ParseTree::get_control_structure_used(prev);
					if ((pcsp) && (pcsp->allow_run_on)) break;
				}
				if ((ParseTree::int_annotation(p, results_from_splitting_ANNOT) == FALSE) &&
					(run_on_at == NULL)) run_on_at = p;
				break;
		}
	}
	if (indent >= GROSS_AMOUNT_OF_INDENTATION) @<Record an excess of indentation@>;

@ We now know the |indent| level of the line as read, and also the
|expected_indent| given the definition so far. If they agree, fine. If they
don't agree, it isn't necessarily bad news -- if each line's indentation were
a function of the last, there would be no information in it, after all.
Roughly speaking, when |indent| is greater than we expect, that must be
wrong -- it means indentation has jumped inward as if to open a new block,
but blocks are opened explicitly and not by simply raising the indent.
But when |indent| is less than we expect, this may simply mean that the
current block(s) has or have been closed, because blocks are indeed closed
implicitly just by moving the indentation back in.

@<Compare actual indentation to what we expect from structure so far@> =
	if (indent == 0) {
		@<Record a misalignment of indentation@>;
		@<Record a phrase within current block@>;
	} else {
		if ((csp) && (csp->subordinate_to)) {
			@<Compare actual indentation to what we expect for an intermediate phrase@>;
			just_opened_block = TRUE;
		} else {
			if (expected_indent < indent) @<Record a misalignment of indentation@>;
			if (expected_indent > indent)
				@<Try closing blocks to bring expected indentation down to match@>;
			expected_indent = indent;
			@<Record a phrase within current block@>;
		}
	}
	if (expected_indent < 1) expected_indent = 1;

@ This is a small variation used for an intermediate phrase like "otherwise".
These are required to be at the same indentation as the line which opened the
block, rather than being one tab step in from there: in other words they are
not deemed part of the block itself. They can also occur in "stages", which
is a way to enforce one intermediate phrase only being allowed after another
one -- for instance, "otherwise if..." is not allowed after an "otherwise"
within an "if".

@<Compare actual indentation to what we expect for an intermediate phrase@> =
	expected_indent--;
	if (expected_indent < indent) {
		@<Issue problem for an intermediate phrase not matching@>;
	} else {
		@<Try closing blocks to bring expected indentation down to match@>;
		if ((blo_sp == 0) ||
			(csp->subordinate_to != blstack_construct[blo_sp-1])) {
			@<Issue problem for an intermediate phrase not matching@>;
		} else {
			if (blstack_stage[blo_sp-1] > csp->used_at_stage)
				@<Issue problem for an intermediate phrase out of sequence@>;
			blstack_stage[blo_sp-1] = csp->used_at_stage;
		}
	}
	expected_indent++;

@ In colon syntax, blocks are explicitly opened; they are only implicitly
closed. Here is the opening:

If |p| is a node representing a phrase beginning a block, and we're in the
colon syntax, then it is followed by a word which is the colon: thus if |p|
reads "if x is 2" then the word following the "2" will be ":".

@<Insert begin marker and increase expected indentation if a block begins here@> =
	if ((csp) && (csp->subordinate_to == NULL) && (ParseTree::int_annotation(p, colon_block_command_ANNOT))) {
		expected_indent++;
		if (csp->indent_subblocks) expected_indent++;
		blstack_construct[blo_sp] = csp;
		blstack_stage[blo_sp] = 0;
		blstack_opening_phrase[blo_sp++] = p;
		just_opened_block = TRUE;
	}

@ Now for the closing of colon-syntax blocks. We know that blocks must be
being closed if the indentation has jumped backwards: but it may be that many
blocks are being closed at once. (It may also be that the indentation has
gone awry.)

@<Try closing blocks to bring expected indentation down to match@> =
	if ((just_opened_block) &&
		(blo_sp > 0) &&
		(!(blstack_construct[blo_sp-1]->body_empty_except_for_subordinates)) && (p))
		@<Issue problem for an empty block@>;
	while (indent < expected_indent) {
		parse_node *opening;
		if (blo_sp == 0) {
			@<Record a misalignment of indentation@>;
			indent = expected_indent;
			break;
		}
		if ((blstack_construct[blo_sp-1]->body_empty_except_for_subordinates) &&
			(expected_indent - indent == 1)) {
			indent = expected_indent;
			break;
		}
		expected_indent--;
		if (blstack_construct[blo_sp-1]->indent_subblocks) expected_indent--;
		opening = blstack_opening_phrase[--blo_sp];
		@<Insert end marker to match the opening of the block phrase@>;
	}

@<Record a phrase within current block@> =
	if ((blo_sp > 0) &&
		(blstack_stage[blo_sp-1] == 0) &&
		(blstack_construct[blo_sp-1]->body_empty_except_for_subordinates)) {
		@<Issue problem for non-case in a switch@>;
	}
	just_opened_block = FALSE;

@ An end marker is a phrase like "end if" which matches the "if... begin"
above it: here we insert such a marker at a place where the source text
indentation implicitly requires it.

@<Insert end marker to match the opening of the block phrase@> =
	parse_node *implicit_end = Sentences::RuleSubtrees::end_node(opening);
	implicit_end->next = prev->next; prev->next = implicit_end;
	prev = implicit_end;

@ Here we throw what amounts to an exception...

@<Record a misalignment of indentation@> =
	indent_misalign = TRUE;
	if (first_misaligned_phrase == NULL) first_misaligned_phrase = p;

@ ...and catch it with something of a catch-all message:

@<Issue problem message for misaligned indentation@> =
	if (suppress_further_problems == FALSE) {
		LOG("$T\n", routine_node);
		current_sentence = routine_node;
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_source_eliding_begin(2, first_misaligned_phrase);
		Problems::Issue::handmade_problem(_p_(PM_MisalignedIndentation));
		Problems::issue_problem_segment(
			"The phrase or rule definition %1 is written using the 'colon "
			"and indentation' syntax for its 'if's, 'repeat's and 'while's, "
			"where blocks of phrases grouped together are indented one "
			"tab step inward from the 'if ...:' or similar phrase to which "
			"they belong. But the tabs here seem to be misaligned, and I can't "
			"determine the structure. The first phrase going awry in the "
			"definition seems to be %2, in case that helps. %PThis sometimes "
			"happens even when the code looks about right, to the eye, if rows "
			"of spaces have been used to indent phrases instead of tabs.");
		Problems::Issue::diagnose_further();
		Problems::issue_problem_end();
	}

@ And another...

@<Record an excess of indentation@> =
	indent_overmuch = TRUE;
	if (first_overindented_phrase == NULL) first_overindented_phrase = p;

@ ...caught here:

@<Issue problem message for an excess of indentation@> =
	if (suppress_further_problems == FALSE) {
		current_sentence = routine_node;
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_source_eliding_begin(2, first_overindented_phrase);
		Problems::Issue::handmade_problem(_p_(PM_TooMuchIndentation));
		Problems::issue_problem_segment(
			"The phrase or rule definition %1 is written using tab indentations "
			"to show how its phrases are to be grouped together. But the level "
			"of indentation goes far too deep, reaching more than 25 tab stops "
			"from the left margin.");
		Problems::issue_problem_end();
	}

@<Issue problem message for run-ons within phrase definition@> =
	if (suppress_further_problems == FALSE) {
		current_sentence = routine_node;
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_source_eliding_begin(2, run_on_at);
		Problems::Issue::handmade_problem(_p_(PM_RunOnsInTabbedRoutine));
		Problems::issue_problem_segment(
			"The phrase or rule definition %1 is written using the 'colon "
			"and indentation' syntax for its 'if's, 'repeat's and 'while's, "
			"but that's only allowed if each phrase in the definition "
			"occurs on its own line. So phrases like %2, which follow "
			"directly on from the previous phrase, aren't allowed.");
		Problems::issue_problem_end();
	}

@ It's a moot point whether the following should be incorrect syntax, but it
far more often happens as an accident than anything else, and it's hard to
think of a sensible use.

@<Issue problem for an empty block@> =
	if (suppress_further_problems == FALSE) {
		LOG("$T\n", routine_node);
		current_sentence = routine_node;
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_source_eliding_begin(2, prev);
		Problems::quote_source_eliding_begin(3, p);
		Problems::Issue::handmade_problem(_p_(PM_EmptyIndentedBlock));
		Problems::issue_problem_segment(
			"The phrase or rule definition %1 is written using the 'colon "
			"and indentation' syntax for its 'if's, 'repeat's and 'while's, "
			"where blocks of phrases grouped together are indented one "
			"tab step inward from the 'if ...:' or similar phrase to which "
			"they belong. But the phrase %2, which ought to begin a block, "
			"is immediately followed by %3 at the same or a lower indentation, "
			"so the block seems to be empty - this must mean there has been "
			"a mistake in indenting the phrases.");
		Problems::issue_problem_end();
	}

@<Issue problem for non-case in a switch@> =
	if (suppress_further_problems == FALSE) {
		current_sentence = routine_node;
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_source_eliding_begin(2, p);
		Problems::Issue::handmade_problem(_p_(PM_NonCaseInIf));
		Problems::issue_problem_segment(
			"In the phrase or rule definition %1, the phrase %2 came as a "
			"surprise since it was not a case in an 'if X is...' but was "
			"instead some other miscellaneous instruction.");
		Problems::issue_problem_end();
	}

@<Issue problem for an intermediate phrase not matching@> =
	if ((indent_misalign == FALSE) && (suppress_further_problems == FALSE)) {
		current_sentence = p;
		if (csp->subordinate_to == if_CSP) {
			LOG("$T\n", routine_node);
			Problems::Issue::sentence_problem(_p_(PM_MisalignedOtherwise),
				"this doesn't match a corresponding 'if'",
				"as it must. An 'otherwise' must be vertically underneath the "
				"'if' to which it corresponds, at the same indentation, and "
				"if the 'otherwise' uses a colon to begin a block then the "
				"'if' must do the same.");
		}
		if (csp->subordinate_to == switch_CSP)
			Problems::Issue::sentence_problem(_p_(PM_MisalignedCase),
				"this seems to be misplaced since it is not a case within an "
				"'if X is...'",
				"as it must be. Each case must be placed one tab stop in from "
				"the 'if X is...' to which it belongs, and the instructions "
				"for what to do in that case should be one tab stop further in "
				"still.");
	}

@<Issue problem for an intermediate phrase out of sequence@> =
	if ((indent_misalign == FALSE) && (suppress_further_problems == FALSE)) {
		current_sentence = p;
		if ((csp == default_case_CSP) || (csp == case_CSP))
			Problems::Issue::sentence_problem(_p_(PM_DefaultCaseNotLast),
				"'otherwise' must be the last clause if an 'if ... is:'",
				"and in particular it has to come after all the '-- V:' "
				"case values supplied.");
		else
			Problems::Issue::sentence_problem(_p_(PM_MisarrangedOtherwise),
				"this seems to be misplaced since it is out of sequence within its 'if'",
				"with an 'otherwise if...' coming after the more general 'otherwise' "
				"rather than before. (Note that an 'otherwise' or 'otherwise if' must "
				"be vertically underneath the 'if' to which it corresponds, at the "
				"same indentation.");
	}

@ And after all that work, the routine's parse tree still consists only of a
linked list of nodes; but at least it now contains the same pattern of nodes
whichever syntax is used. We finally make a meaningful tree out of it.

@<(e) Structure the parse tree to match the use of control structures@> =
	parse_node *routine_list = routine_node->down;
	parse_node *top_level = ParseTree::new(CODE_BLOCK_NT);

	routine_node->down = top_level;

	parse_node *attach_owners[MAX_BLOCK_NESTING+1];
	parse_node *attach_points[MAX_BLOCK_NESTING+1];
	control_structure_phrase *attach_csps[MAX_BLOCK_NESTING+1];
	int attach_point_sp = 0;

	/* push the top level code block onto the stack */
	attach_owners[attach_point_sp] = NULL;
	attach_csps[attach_point_sp] = NULL;
	attach_points[attach_point_sp++] = top_level;

	parse_node *overflow_point = NULL; /* if any overflow is found */
	for (parse_node *pn = routine_list, *pn_prev = NULL; pn; pn_prev = pn, pn = pn->next) {
		/* unstring this node from the old list */
		if (pn_prev) pn_prev->next = NULL;
		@<Attach the node to the routine's growing parse tree@>;
	}
	if (overflow_point) {
		current_sentence = overflow_point;
		Problems::Issue::sentence_problem(_p_(PM_BlockNestingTooDeep),
			"compound phrases have gone too deep",
			"perhaps because many have begun but not been properly ended?");
	}

@<Attach the node to the routine's growing parse tree@> =
	int go_up = FALSE, go_down = FALSE;
	control_structure_phrase *csp = ParseTree::get_end_control_structure_used(pn);
	if (csp) go_up = TRUE;
	else {
		csp = ParseTree::get_control_structure_used(pn);
		if (csp) {
			go_down = TRUE;
			if (Sentences::RuleSubtrees::opens_block(csp) == FALSE) {
				go_up = TRUE;
				ParseTree::set_type(pn, CODE_BLOCK_NT);
			}
		}
	}
	if (go_up) @<Move the attachment point up in the tree@>;
	@<Attach this latest node@>;
	if (go_down) @<Move the attachment point down in the tree@>;

@<Move the attachment point up in the tree@> =
	control_structure_phrase *superior_csp = attach_csps[attach_point_sp-1];
	if ((superior_csp) && (superior_csp->subordinate_to)) @<Pop the CSP stack@>;
	if (go_down == FALSE) @<Pop the CSP stack@>;

@<Attach this latest node@> =
	parse_node *to = attach_points[attach_point_sp-1];
	if ((go_up) && (go_down) && (attach_owners[attach_point_sp-1]))
		to = attach_owners[attach_point_sp-1];
	ParseTree::graft(pn, to);

@<Move the attachment point down in the tree@> =
	parse_node *next_attach_point = pn;
	if (go_up == FALSE) {
		pn->down = ParseTree::new(CODE_BLOCK_NT);
		next_attach_point = pn->down;
	}
	@<Push the CSP stack@>;

@ It's an error to let this underflow, but we'll catch that problem later.

@<Pop the CSP stack@> =
	if (attach_point_sp != 1) attach_point_sp--;

@ An overflow, however, we must catch right here.

@<Push the CSP stack@> =
	if (attach_point_sp <= MAX_BLOCK_NESTING) {
		attach_owners[attach_point_sp] = pn;
		attach_csps[attach_point_sp] = csp;
		attach_points[attach_point_sp++] = next_attach_point;
	} else {
		if (overflow_point == NULL) overflow_point = pn;
	}

@ We now have a neatly structured tree, so from here on anything we do will
need a recursive procedure.

Firstly, the tree is certainly neat, but it can still contain all kinds
of nonsense: "if" blocks with multiple "otherwise"s, for example. This is
where we look for such mistakes.

@<(f) Police the structure of the parse tree@> =
	int n = problem_count;
	Sentences::RuleSubtrees::police_code_block(routine_node->down, NULL);
	if (problem_count > n) LOG("Local parse tree: $T\n", routine_node);

@ Which recursively uses the following:

=
void Sentences::RuleSubtrees::police_code_block(parse_node *block, control_structure_phrase *context) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		current_sentence = p;

		control_structure_phrase *prior =
			(prev_p)?ParseTree::get_control_structure_used(prev_p):NULL;
		control_structure_phrase *csp = ParseTree::get_end_control_structure_used(p);
		if ((csp) && (csp != prior)) {
			if (prior == NULL) @<Issue problem for end without begin@>
			else @<Issue problem for wrong sort of end@>;
		}

		csp = ParseTree::get_control_structure_used(p);
		if (csp) {
			if (Sentences::RuleSubtrees::opens_block(csp)) {
				if ((p->next == NULL) ||
					(ParseTree::get_end_control_structure_used(p->next) == NULL))
					@<Issue problem for begin without end@>;
			} else {
				if (context == NULL)
					@<Choose a problem for a loose clause@>
				else if (context != csp->subordinate_to)
					@<Choose a problem for the wrong clause@>
				else if ((csp == otherwise_CSP) && (p->next))
					@<Choose a problem for otherwise not occurring last@>
				else if ((csp == default_case_CSP) && (p->next))
					@<Issue a problem for the default case not occurring last@>;
			}
		}

		if (p->down) Sentences::RuleSubtrees::police_code_block(p, csp);
	}
}

@ These used to be much-seen problem messages, until Inform moved to Pythonesque
structure-by-indentation. Nowadays "end if", "end while" and such are
automatically inserted into the stream of commands, always in the right place,
and always passing these checks. But the problem messages are kept for the sake
of old-format source text, and for refuseniks.

@<Issue problem for end without begin@> =
	Problems::Issue::sentence_problem_with_note(_p_(PM_EndWithoutBegin),
		"this is an 'end' with no matching 'begin'",
		"which should not happen: every phrase like 'if ... begin;' "
		"should eventually be followed by its bookend 'end if'. "
		"It makes no sense to have an 'end ...' on its own.",
		"Perhaps the problem is actually that you opened several "
		"such begin... end 'blocks' and accidentally closed them "
		"once too many? This is very easily done.");

@<Issue problem for wrong sort of end@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wide_text(2, prior->keyword);
	Problems::quote_source(3, prev_p);
	Problems::Issue::handmade_problem(_p_(PM_WrongEnd));
	Problems::issue_problem_segment(
		"You wrote %1, but the end I was expecting next was 'end %2', "
		"finishing the block you began with %3.");
	Problems::issue_problem_end();

@<Issue problem for begin without end@> =
	Problems::Issue::sentence_problem(_p_(PM_BeginWithoutEnd),
		"the definition of the phrase ended with no matching 'end' for "
		"this 'begin'",
		"bearing in mind that every begin must have a matching end, and "
		"that the one most recently begun must be the one first to end. For "
		"instance, 'if ... begin' must have a matching 'end if'.");

@<Choose a problem for a loose clause@> =
	if (csp == otherwise_CSP)
		Problems::Issue::sentence_problem(_p_(PM_OtherwiseWithoutIf),
			"this is an 'else' or 'otherwise' with no matching 'if' (or 'unless')",
			"which must be wrong.");
	else if (csp == otherwise_if_CSP)
		Problems::Issue::sentence_problem(_p_(PM_OtherwiseIfMisplaced),
			"the 'otherwise if' clause here seems not to be occurring inside "
			"a large 'if'",
			"and seems to be freestanding instead. (Though 'otherwise ...' can "
			"usually be used after simple one-line 'if's to provide an alternative "
			"course of action, 'otherwise if...' is a different matter, and is "
			"used to divide up larger-scale instructions.)");
	else
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"this clause can't occur outside of a control phrase",
			"which suggests that the structure of this routine is wrong.");

@<Choose a problem for the wrong clause@> =
	if ((csp == otherwise_CSP) || (csp == otherwise_if_CSP)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wide_text(2, context->keyword);
		Problems::Issue::handmade_problem(_p_(PM_OtherwiseInNonIf));
		Problems::issue_problem_segment(
			"The %1 here did not make sense inside a "
			"'%2' structure: it's provided for 'if' (or 'unless').");
		Problems::issue_problem_end();
	} else
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"this clause is wrong for the phrase containing it",
			"which suggests that the structure of this routine is wrong.");

@<Choose a problem for otherwise not occurring last@> =
	int doubled = FALSE, oi = FALSE;
	for (parse_node *p2 = p->next; p2; p2 = p2->next) {
		if (ParseTree::get_control_structure_used(p2) == otherwise_CSP) {
			current_sentence = p2;
			doubled = TRUE;
		}
		if (ParseTree::get_control_structure_used(p2) == otherwise_if_CSP)
			oi = TRUE;
	}
	if (doubled)
		Problems::Issue::sentence_problem(_p_(PM_DoubleOtherwise),
			"that makes two unconditional 'otherwise' or 'else' clauses "
			"for this 'if'",
			"which is forbidden since 'otherwise' is meant to be a single "
			"(optional) catch-all clause at the end.");
	else if (oi)
		Problems::Issue::sentence_problem(_p_(PM_OtherwiseIfAfterOtherwise),
			"this seems to be misplaced since it is out of sequence within its 'if'",
			"with an 'otherwise if...' coming after the more general 'otherwise' "
			"rather than before. (If there's an 'otherwise' clause, it has to be "
			"the last clause of the 'if'.)");
	else
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"'otherwise' must be the last clause",
			"but it seems not to be.");

@ This shouldn't happen because the switch construct requires Python syntax
and the structure of that was checked at indentation time, but just in case.

@<Issue a problem for the default case not occurring last@> =
	Problems::Issue::sentence_problem(_p_(BelievedImpossible),
		"'otherwise' must be the last clause",
		"which must be wrong.");

@ The tree is now known to be correctly structured, and there are no possible
problem messages left to issue. It's therefore safe to begin rearranging it.
We'll first eliminate one whole construction: "otherwise if whatever: ..."
can now become "otherwise: if whatever: ...".

@<(g) Optimise out the otherwise if nodes@> =
	int n = problem_count;
	Sentences::RuleSubtrees::purge_otherwise_if(routine_node->down);
	if (problem_count > n) LOG("Local parse tree: $T\n", routine_node);

@ We made a similar manoeuvre above, but for one-line "otherwise do something"
phrases following one-line "if", not for the wider case of "otherwise if". We
didn't handle this back then because to do so would have made it impossible
to issue good problem messages for failures to use "otherwise if" correctly.

=
void Sentences::RuleSubtrees::purge_otherwise_if(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		if (ParseTree::get_control_structure_used(p) == otherwise_if_CSP) {
			parse_node *former_contents = p->down;
			parse_node *former_successors = p->next;

			/* put an otherwise node in the position previously occupied by p */
			parse_node *otherwise_node = ParseTree::new(CODE_BLOCK_NT);
			ParseTree::set_control_structure_used(otherwise_node, otherwise_CSP);
			/* extract just the word "otherwise" */
			ParseTree::set_text(otherwise_node, Wordings::one_word(Wordings::first_wn(ParseTree::get_text(p))));
			if (prev_p) prev_p->next = otherwise_node; else block->down = otherwise_node;

			/* move p to below the otherwise node */
			otherwise_node->down = p;
			ParseTree::set_type(p, INVOCATION_LIST_NT);
			ParseTree::set_control_structure_used(p, if_CSP);
			p->next = NULL;
			ParseTree::set_text(p, Wordings::trim_first_word(ParseTree::get_text(p)));

			/* put the code previously under p under a new code block node under p */
			p->down = ParseTree::new(CODE_BLOCK_NT);
			p->down->down = former_contents;

			/* any further "otherwise if" or "otherwise" nodes after p follow */
			p->down->next = former_successors;
		}
		if (p->down) Sentences::RuleSubtrees::purge_otherwise_if(p);
	}
}

@ End nodes are now redundant: maybe they got here as explicit "end if" phrases
in the source text, or maybe they were auto-inserted by the indentation reader,
but now that the structure is known to be correct they serve no further purpose.
We remove them.

@<(h) Remove any end markers as no longer necessary@> =
	Sentences::RuleSubtrees::purge_end_markers(routine_node->down);

@ =
void Sentences::RuleSubtrees::purge_end_markers(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		if (ParseTree::get_end_control_structure_used(p)) {
			if (prev_p) prev_p->next = p->next; else block->down = p->next;
		}
		if (p->down) Sentences::RuleSubtrees::purge_end_markers(p);
	}
}

@ The "begin" keyword at the end of control constructs in the old-style syntax
can now be removed, too.

@<(i) Remove any begin markers as no longer necessary@> =
	Sentences::RuleSubtrees::purge_begin_markers(routine_node->down);

@ =
void Sentences::RuleSubtrees::purge_begin_markers(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		if (ParseTree::get_control_structure_used(p))
			if (<phrase-beginning-block>(ParseTree::get_text(p)))
				ParseTree::set_text(p, GET_RW(<phrase-beginning-block>, 1));
		if (p->down) Sentences::RuleSubtrees::purge_begin_markers(p);
	}
}

@ This all makes a nice tree, but it has the defect that the statements heading
block-opening phrases (the ifs, whiles, repeats) have child nodes (the blocks
of code consequent on them). We want them to be leaves for now, so that we
can append statement-parsing data underneath them later. So we insert blank
code block nodes to mark these phrases, and transfer the control structure
annotations to them.

@<(j) Insert code block nodes so that nodes needing to be parsed are childless@> =
	Sentences::RuleSubtrees::insert_cb_nodes(routine_node->down);

@ =
void Sentences::RuleSubtrees::insert_cb_nodes(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		if (Sentences::RuleSubtrees::opens_block(ParseTree::get_control_structure_used(p))) {
			parse_node *blank_cb_node = ParseTree::new(CODE_BLOCK_NT);
			ParseTree::set_control_structure_used(blank_cb_node,
				ParseTree::get_control_structure_used(p));
			ParseTree::set_control_structure_used(p, NULL);
			blank_cb_node->down = p;
			blank_cb_node->next = p->next;
			p->next = p->down;
			p->down = NULL;
			if (prev_p) prev_p->next = blank_cb_node; else block->down = blank_cb_node;
			p = blank_cb_node;
		}
		if (p->down) Sentences::RuleSubtrees::insert_cb_nodes(p);
	}
}

@ Now:

@<(k) Insert instead marker nodes@> =
	Sentences::RuleSubtrees::read_instead_markers(routine_node->down);

@ =
void Sentences::RuleSubtrees::read_instead_markers(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		if (<instead-keyword>(ParseTree::get_text(p))) {
			ParseTree::set_text(p, GET_RW(<instead-keyword>, 1));
			parse_node *instead_node = ParseTree::new(CODE_BLOCK_NT);
			ParseTree::set_control_structure_used(instead_node, instead_CSP);
			instead_node->next = p->next;
			p->next = instead_node;
		}
		if (p->down) Sentences::RuleSubtrees::read_instead_markers(p);
	}
}

@ Now:

@<(l) Break up say phrases@> =
	Sentences::RuleSubtrees::break_up_says(routine_node->down);

@ =
void Sentences::RuleSubtrees::break_up_says(parse_node *block) {
	for (parse_node *p = block->down, *prev_p = NULL; p; prev_p = p, p = p->next) {
		int sf = NO_SIGF;
		wording W = ParseTree::get_text(p);
		if (ParseTree::int_annotation(p, from_text_substitution_ANNOT)) sf = SAY_SIGF;
		else if (<other-significant-phrase>(W)) {
			sf = <<r>>; W = GET_RW(<other-significant-phrase>, 1);
		}
		switch (sf) {
			case SAY_SIGF: {
				parse_node *blank_cb_node = ParseTree::new(CODE_BLOCK_NT);
				ParseTree::set_control_structure_used(blank_cb_node, say_CSP);
				blank_cb_node->next = p->next;
				ParseTree::set_text(blank_cb_node, ParseTree::get_text(p));
				p->next = NULL;
				if (prev_p) prev_p->next = blank_cb_node; else block->down = blank_cb_node;

				current_sentence = p;
				Sentences::RuleSubtrees::unroll_says(blank_cb_node, W, 0);
				p = blank_cb_node;
				break;
			}
			case NOW_SIGF: {
				ParseTree::set_control_structure_used(p, now_CSP);
				parse_node *cond_node = ParseTree::new(CONDITION_CONTEXT_NT);
				ParseTree::set_text(cond_node, W);
				p->down = cond_node;
				break;
			}
		}
		if (p->down) Sentences::RuleSubtrees::break_up_says(p);
	}
}

void Sentences::RuleSubtrees::unroll_says(parse_node *cb_node, wording W, int depth) {
	while (<phrase-with-comma-notation>(W)) {
		wording AW = GET_RW(<phrase-with-comma-notation>, 1);
		wording BW = GET_RW(<phrase-with-comma-notation>, 2);
		W = AW;
		@<Bite off a say term@>;
		W = BW;
	}
	@<Bite off a say term@>;
}

@<Bite off a say term@> =
	if ((Wordings::length(W) > 1) || (Wide::cmp(Lexer::word_text(Wordings::first_wn(W)), L"\"\"") != 0)) {
		if ((Wordings::length(W) == 1) && (Vocabulary::test_flags(Wordings::first_wn(W), TEXTWITHSUBS_MC)) && (depth == 0)) {
			wchar_t *p = Lexer::word_raw_text(Wordings::first_wn(W));
			@<Check that substitution does not contain suspicious punctuation@>;
			wording A = Feeds::feed_text_expanding_strings(p);
			if (<verify-expanded-text-substitution>(A))
				Sentences::RuleSubtrees::unroll_says(cb_node, A, depth+1);
		} else {
			parse_node *say_term_node = ParseTree::new(INVOCATION_LIST_SAY_NT);
			ParseTree::set_text(say_term_node, W);
			ParseTree::graft(say_term_node, cb_node);
		}
	}

@<Check that substitution does not contain suspicious punctuation@> =
	int k, sqb = 0;
	for (k=0; p[k]; k++) {
		switch (p[k]) {
			case '[': sqb++; if (sqb > 1) @<Issue problem message for nested substitution@>; break;
			case ']': sqb--; if (sqb < 0) @<Issue problem message for unopened substitution@>; break;
			case ':': if ((k>0) && (Characters::isdigit(p[k-1])) && (Characters::isdigit(p[k+1]))) break;
			case ';':
				if (sqb > 0) @<Issue PM_TSWithPunctuation problem@>;
				break;
			case ',':
				if (sqb > 0) @<Issue problem message for comma in a substitution@>;
				break;
		}
	}
	if (sqb != 0) @<Issue problem message for unclosed substitution@>;

@ And the more specialised:

@<Issue problem message for comma in a substitution@> =
	it_is_not_worth_adding = TRUE;
	Problems::Issue::sentence_problem(_p_(PM_TSWithComma),
		"a substitution contains a comma ','",
		"which is against the rules, because 'say' is a special phrase in "
		"which the comma divides items in a list of things to say, and so it "
		"loses its ordinary meanings. Because of this, no text substitution "
		"can contain a comma. "
		"(If you're trying to use a value produced by a phrase with a phrase "
		"option - say 'the best route from A to B, using even locked doors' - "
		"you'll need to put this in a 'let' variable first and then say that, "
		"or else define a better text substitution to do the job for you.)");
	it_is_not_worth_adding = FALSE;
	return;

@<Issue problem message for nested substitution@> =
	it_is_not_worth_adding = TRUE;
	if ((p[k+1] == 'u') && (p[k+2] == 'n') && (p[k+3] == 'i') && (p[k+4] == 'c') &&
		(p[k+5] == 'o') && (p[k+6] == 'd') && (p[k+7] == 'e') && (p[k+8] == ' ')) {
		Problems::Issue::sentence_problem(_p_(PM_NestedUSubstitution),
			"the text here contains one substitution '[...]' inside another",
			"which is not allowed. Actually, it looks as if you might have got "
			"into this by typing an exotic character as part of the name of a "
			"text substitution - those get rewritten automatically as '[unicode N]' "
			"for the appropriate Unicode character code number N. Either way - "
			"this isn't allowed.");
	} else {
		Problems::Issue::sentence_problem(_p_(PM_NestedSubstitution),
			"the text here contains one substitution '[...]' inside another",
			"which is not allowed. (If you just wanted a literal open and closed "
			"square bracket, use '[bracket]' and '[close bracket]'.)");
	}
	it_is_not_worth_adding = FALSE;
	return;

@<Issue problem message for unclosed substitution@> =
	it_is_not_worth_adding = TRUE;
	Problems::Issue::sentence_problem(_p_(PM_UnclosedSubstitution),
		"the text here uses an open square bracket '[', which opens a substitution "
		"in the text, but doesn't close it again",
		"so that the result is malformed. (If you just wanted a literal open "
		"square bracket, use '[bracket]'.)");
	it_is_not_worth_adding = FALSE;
	return;

@<Issue problem message for unopened substitution@> =
	it_is_not_worth_adding = TRUE;
	Problems::Issue::sentence_problem(_p_(PM_UnopenedSubstitution),
		"the text here uses a close square bracket ']', which closes a substitution "
		"in the text, but never actually opened it",
		"with a matching '['. (If you just wanted a literal close square bracket, "
		"use '[close bracket]'.)");
	it_is_not_worth_adding = FALSE;
	return;

@ Something devious happens when production (b) of <s-say-phrase> is matched.
Double-quoted text is literal if it contains no square brackets, but is
expanded if it includes text substitutions in squares. When (b) matches,
Inform expands a text such as

>> "Look, [the noun] said."

into:

>> "Look, ", the noun, " said."

and then re-parses the result with the following nonterminal; note that we
make sure commas are used correctly before handing back to <s-say-phrase>
to parse the list.

=
<verify-expanded-text-substitution> ::=
	*** . *** |								==> @<Issue PM_TSWithPunctuation problem@>; return FAIL_NONTERMINAL
	, *** |									==> @<Issue PM_EmptySubstitution problem@>; return FAIL_NONTERMINAL
	*** , |									==> @<Issue PM_EmptySubstitution problem@>; return FAIL_NONTERMINAL
	*** , , ***	|							==> @<Issue PM_EmptySubstitution problem@>; return FAIL_NONTERMINAL
	...

@ So now just the problem messages:

@<Issue PM_TSWithPunctuation problem@> =
	it_is_not_worth_adding = TRUE;
	Problems::Issue::sentence_problem(_p_(PM_TSWithPunctuation),
		"a substitution contains a '.', ':' or ';'",
		"which suggests that a close square bracket ']' may have gone astray.");
	it_is_not_worth_adding = FALSE;

@ And:

@<Issue PM_EmptySubstitution problem@> =
	it_is_not_worth_adding = TRUE;
	Problems::Issue::sentence_problem(_p_(PM_EmptySubstitution),
		"the text here contains an empty substitution '[]'",
		"which is not allowed. To say nothing - well, say nothing.");
	it_is_not_worth_adding = FALSE;

@ That just leaves one utility routine, for manufacturing end nodes which
match a given begin node.

=
parse_node *Sentences::RuleSubtrees::end_node(parse_node *opening) {
	parse_node *implicit_end = ParseTree::new(INVOCATION_LIST_NT);
	ParseTree::set_end_control_structure_used(implicit_end,
		ParseTree::get_control_structure_used(opening));
	ParseTree::annotate_int(implicit_end, indentation_level_ANNOT,
		ParseTree::int_annotation(opening, indentation_level_ANNOT));
	return implicit_end;
}

@h Basic Structural Syntax.
The following routine is an attempt to contain information about the
basic structural phrases in one place in NI, so that if future loop constructs
are added, they can fairly simply be put here.

=
control_structure_phrase *Sentences::RuleSubtrees::csp_new(void) {
	control_structure_phrase *csp = CREATE(control_structure_phrase);
	csp->subordinate_to = NULL;
	csp->indent_subblocks = FALSE;
	csp->body_empty_except_for_subordinates = FALSE;
	csp->used_at_stage = -1;
	csp->requires_new_syntax = FALSE;
	csp->allow_run_on = FALSE;
	csp->keyword = L"<none>";
	csp->is_a_loop = FALSE;
	return csp;
}

void Sentences::RuleSubtrees::create_standard_csps(void) {
	switch_CSP = Sentences::RuleSubtrees::csp_new();
	switch_CSP->body_empty_except_for_subordinates = TRUE;
	switch_CSP->indent_subblocks = TRUE;
	switch_CSP->requires_new_syntax = TRUE;
	switch_CSP->keyword = L"if";

	if_CSP = Sentences::RuleSubtrees::csp_new();
	if_CSP->keyword = L"if";

	repeat_CSP = Sentences::RuleSubtrees::csp_new();
	repeat_CSP->keyword = L"repeat";
	repeat_CSP->is_a_loop = TRUE;

	while_CSP = Sentences::RuleSubtrees::csp_new();
	while_CSP->keyword = L"while";
	while_CSP->is_a_loop = TRUE;

	otherwise_CSP = Sentences::RuleSubtrees::csp_new();
	otherwise_CSP->subordinate_to =	if_CSP;
	otherwise_CSP->used_at_stage = 1;

	abbreviated_otherwise_CSP = Sentences::RuleSubtrees::csp_new();
	abbreviated_otherwise_CSP->subordinate_to =	if_CSP;
	abbreviated_otherwise_CSP->used_at_stage = 1;

	otherwise_if_CSP = Sentences::RuleSubtrees::csp_new();
	otherwise_if_CSP->subordinate_to = if_CSP;
	otherwise_if_CSP->used_at_stage = 0;

	case_CSP = Sentences::RuleSubtrees::csp_new();
	case_CSP->subordinate_to = switch_CSP;
	case_CSP->used_at_stage = 1;
	case_CSP->requires_new_syntax = TRUE;
	case_CSP->allow_run_on = TRUE;

	default_case_CSP = Sentences::RuleSubtrees::csp_new();
	default_case_CSP->subordinate_to = switch_CSP;
	default_case_CSP->used_at_stage = 2;
	default_case_CSP->requires_new_syntax = TRUE;
	default_case_CSP->allow_run_on = TRUE;

	say_CSP = Sentences::RuleSubtrees::csp_new();

	now_CSP = Sentences::RuleSubtrees::csp_new();

	instead_CSP = Sentences::RuleSubtrees::csp_new();
}

void Sentences::RuleSubtrees::log_control_structure(control_structure_phrase *csp) {
	if (csp == if_CSP) LOG("IF");
	if (csp == repeat_CSP) LOG("RPT");
	if (csp == while_CSP) LOG("WHI");
	if (csp == switch_CSP) LOG("SWI");
	if (csp == otherwise_CSP) LOG("O");
	if (csp == abbreviated_otherwise_CSP) LOG("AO");
	if (csp == otherwise_if_CSP) LOG("OIF");
	if (csp == case_CSP) LOG("CAS");
	if (csp == default_case_CSP) LOG("DEF");
	if (csp == say_CSP) LOG("SAY");
	if (csp == now_CSP) LOG("NOW");
	if (csp == instead_CSP) LOG("INS");
	if (csp == NULL) LOG("---");
}

int Sentences::RuleSubtrees::comma_possible(control_structure_phrase *csp) {
	if ((csp == if_CSP) || (csp == switch_CSP) || (csp == otherwise_if_CSP))
		return TRUE;
	return FALSE;
}

int Sentences::RuleSubtrees::is_a_loop(control_structure_phrase *csp) {
	if (csp) return csp->is_a_loop;
	return FALSE;
}

int Sentences::RuleSubtrees::opens_block(control_structure_phrase *csp) {
	if ((csp) && (csp->subordinate_to == NULL) && (csp != say_CSP) && (csp != now_CSP) && (csp != instead_CSP)) return TRUE;
	return FALSE;
}

int Sentences::RuleSubtrees::permits_break(control_structure_phrase *csp) {
	if ((csp == repeat_CSP) || (csp == while_CSP)) return TRUE;
	return FALSE;
}

wchar_t *Sentences::RuleSubtrees::incipit(control_structure_phrase *csp) {
	if (csp) return csp->keyword;
	return L"<none>";
}

control_structure_phrase *Sentences::RuleSubtrees::detect_control_structure(wording W) {
	if (<control-structure-phrase>(W)) {
		if (<<rp>> == abbreviated_otherwise_CSP) return NULL;
		return <<rp>>;
	}
	return NULL;
}

int Sentences::RuleSubtrees::abbreviated_otherwise(wording W) {
	if (<control-structure-phrase>(W)) {
		if (<<rp>> == abbreviated_otherwise_CSP) return TRUE;
	}
	return FALSE;
}

control_structure_phrase *Sentences::RuleSubtrees::detect_end_control_structure(wording W) {
	if (<end-control-structure-phrase>(W)) return <<rp>>;
	return NULL;
}

@ Control structures such as "if" act as a sort of super-punctuation inside
rule and phrase definitions, and in particular they affect the actual
punctuation of the sentences there (consider the rules about colons versus
semicolons). So, though it's still early in Inform's run, we need to seek
them out.

Here we parse the text of a command phrase which, if any, of the control
structures it might be. Note that <s-command> has a grammar partially
overlapping with this, and they need to match.

@d NO_SIGF 0
@d SAY_SIGF 1
@d NOW_SIGF 2

=
<control-structure-phrase> ::=
	if ... is begin |				==> 0; *XP = switch_CSP
	if ... is |						==> 0; *XP = switch_CSP
	if/unless ... |					==> 0; *XP = if_CSP
	repeat ... |					==> 0; *XP = repeat_CSP
	while ... |						==> 0; *XP = while_CSP
	else/otherwise |				==> 0; *XP = otherwise_CSP
	else/otherwise if/unless ... |	==> 0; *XP = otherwise_if_CSP
	else/otherwise ... |			==> 0; *XP = abbreviated_otherwise_CSP
	-- otherwise |					==> 0; *XP = default_case_CSP
	-- ...							==> 0; *XP = case_CSP

<end-control-structure-phrase> ::=
	end if/unless |					==> 0; *XP = if_CSP
	end while |						==> 0; *XP = while_CSP
	end repeat						==> 0; *XP = repeat_CSP

<other-significant-phrase> ::=
	say ... |						==> SAY_SIGF
	now ...							==> NOW_SIGF

@ This is used to see if an "if" is being used with the comma notation:

=
<phrase-with-comma-notation> ::=
	...... , ......

@ This is used to see if an "if" is being used with the comma notation:

=
<instead-keyword> ::=
	instead ... |
	... instead

@ Finally, this is used to see if a control structure opens a block:

=
<phrase-beginning-block> ::=
	... begin
