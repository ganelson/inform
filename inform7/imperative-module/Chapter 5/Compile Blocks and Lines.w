[CompileBlocksAndLines::] Compile Blocks and Lines.

Compiling a code block of lines from an imperative definition.

@h Blocks of code.
As this section of code opens, we are looking at the parse tree for the body
of a rule or phrase definition. A request has been made to compile (a version of)
this into an Inter function; the stack frame for that has been sorted out, and
the function begun. Now we must compile the actual code to go into the function;
the test group |:invocations| exercises all of this.

Here is a typical example rule, taken from the Standard Rules:
= (text as Inform 7)
Report an actor waiting (this is the standard report waiting rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Time [pass]." (A);
	otherwise:
		say "[The actor] [wait]." (B).
=
In the parse tree, this now looks like so:
= (text)
IMPERATIVE_NT'report an actor waiting ( this is the standard report waiting'
	CODE_BLOCK_NT
		CODE_BLOCK_NT
			INVOCATION_LIST_NT'if the actor is the player'
			CODE_BLOCK_NT
				CODE_BLOCK_NT
					INVOCATION_LIST_NT'if the action is not silent'
					CODE_BLOCK_NT
						INVOCATION_LIST_NT'now the prior named object is nothing'
						CODE_BLOCK_NT'say "Time [pass]." ( a )'
							INVOCATION_LIST_SAY_NT'"Time [pass]." ( a )'
			CODE_BLOCK_NT'otherwise'
				CODE_BLOCK_NT'say "[The actor] [wait]." ( b )'
					INVOCATION_LIST_SAY_NT'"[The actor] [wait]." ( b )'
=
This diagram has been simplified to remove the child nodes of the |INVOCATION_LIST_NT|
and |INVOCATION_LIST_SAY_NT| nodes; the point is to show the structure of the code
blocks here.

We work recursively down through these blocks. Note that the entire definition
always hangs from a single top-level |CODE_BLOCK_NT|.

=
void CompileBlocksAndLines::full_definition_body(int statement_count, parse_node *body,
	int allow_implied_newlines) {
	text_provenance last_loc = Provenance::nowhere();
	CompileBlocksAndLines::code_block(statement_count, body, TRUE, allow_implied_newlines, &last_loc);
	if (Provenance::is_somewhere(last_loc)) {
		last_loc = Provenance::nowhere();
		EmitCode::provenance(last_loc);
	}
}

@ See //words: Nonterminals// for an explanation of what it means for a nonterminal
such as <s-value-uncached> to be "multiplicitous": briefly, though, it causes
<s-value-uncached> to return all possible interpretations of the text as a list
of nodes joined by |->next_alternative|, rather than returning just the single
most "likely" interpretation.

=
int CompileBlocksAndLines::code_block(int statement_count, parse_node *block, int top_level,
	int allow_implied_newlines, text_provenance *last_loc) {
	if (block) {
		if (Node::get_type(block) != CODE_BLOCK_NT) internal_error("not a code block");
		int saved_mult = <s-value-uncached>->multiplicitous;
		<s-value-uncached>->multiplicitous = TRUE;
		int block_size = 0, singleton = FALSE;
		for (parse_node *p = block->down; p; p = p->next) block_size++;
		if ((top_level == FALSE) && (block_size == 1)) singleton = TRUE;
		for (parse_node *p = block->down; p; p = p->next)
			statement_count =
				CompileBlocksAndLines::code_line(statement_count, p, singleton,
					allow_implied_newlines, last_loc);
		<s-value-uncached>->multiplicitous = saved_mult;
	}
	return statement_count;
}

@ There's nothing special about singleton blocks except that we want to issue
problem messages for something like this:
= (text as Inform 7)
	if the player is in the Hall of Mirrors:
		let the court favourite be Moliere;
	if Louis is happy:
		...
=
...where the "let" phrase can have no meaningful effect, since "court favourite"
is destroyed immediately after its creation. So in order to check for that, we
keep the following state variable:

=
int compiling_single_line_block = FALSE;
int CompileBlocksAndLines::compiling_single_line_block(void) {
	return compiling_single_line_block;
}

@h Individual lines of code.
So, then, this is called on each child node of a |CODE_BLOCK_NT| in turn:

=
int CompileBlocksAndLines::code_line(int statement_count, parse_node *p, int as_singleton,
	int allow_implied_newlines, text_provenance *last_loc) {
	compiling_single_line_block = as_singleton;
	control_structure_phrase *csp = Node::get_control_structure_used(p);
	parse_node *to_compile = p;
	if (ControlStructures::opens_block(csp)) {
		CodeBlocks::beginning_block_phrase(csp);
		to_compile = p->down;
	}
	statement_count++;
	@<Compile a comment about this line@>;
	@<Compile a location reference for this line@>;
	int L = EmitCode::level();
	@<Compile the head@>;
	@<Compile the midriff@>;
	@<Compile the tail@>;
	compiling_single_line_block = FALSE;
	return statement_count;
}

@<Compile a comment about this line@> =
	if (Wordings::nonempty(Node::get_text(to_compile))) {
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "[%d: ", statement_count);
		TranscodeText::comment(C, Node::get_text(to_compile));
		WRITE_TO(C, "]");
		EmitCode::comment(C);
		DISCARD_TEXT(C)
	}

@<Compile a location reference for this line@> =
	source_location sl = Wordings::location(Node::get_text(to_compile));
	if (sl.file_of_origin) {
		TEMPORARY_TEXT(fname);
		WRITE_TO(fname, "%f", sl.file_of_origin->name);
		text_provenance loc = Provenance::at_file_and_line(fname, sl.line_number);
		DISCARD_TEXT(fname);
		if (Str::ne(loc.textual_filename, last_loc->textual_filename) || loc.line_number != last_loc->line_number) {
			*last_loc = loc;
			EmitCode::provenance(loc);
		}
	}

@h Head code for lines.
We divide the work of compiling the line into "head" code, "midriff" code
and then "tail" code. For the head, there's usually nothing to do, except
for "say" phrases:

@<Compile the head@> =
	if (csp == say_CSP) {
		current_sentence = to_compile;
		@<Compile a say head@>;
	}

@ "Say" phrases are different, since their invocation lists can contain multiple
things to do (rather than multiple alternatives for one thing to do). We also
need to treat the last of those things differently to the others: if it means
printing literal text ending in sentence-ending punctuation, we need to infer
a newline.

@<Compile a say head@> =
	for (parse_node *say_node = p->down, *prev_sn = NULL;
		say_node;
		prev_sn = say_node, say_node = say_node->next) {
		SParser::parse_say_term(say_node);
		parse_node *inv = InvocationLists::first_reading(say_node->down);
		if (inv) {
			if (prev_sn) {
				if ((Node::get_say_verb(inv)) ||
					(Node::get_say_adjective(inv)) ||
					((IDTypeData::is_a_say_phrase(Node::get_phrase_invoked(inv))) &&
						(Node::get_phrase_invoked(inv)->type_data.as_say.say_phrase_running_on)))
					Annotations::write_int(prev_sn, suppress_newlines_ANNOT, TRUE);
			}
		}
	}
	/* warn the paragraph breaker by setting the say__p flag that this will print */
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		EmitCode::val_number(1);
	EmitCode::up();
	CompileBlocksAndLines::verify_say_node_list(p->down);

@h Midriff code for lines.
The midriff is more work, because several of the control structure phrases
need bespoke handling:

@<Compile the midriff@> =
	if (Node::get_type(to_compile) == INVOCATION_LIST_SAY_NT) @<Compile a say term midriff@>
	else if (csp == now_CSP) @<Compile a now midriff@>
	else if (csp == if_CSP) @<Compile an if midriff@>
	else if (csp == switch_CSP) @<Compile a switch midriff@>
	else if ((csp != say_CSP) && (csp != instead_CSP)) {
		if (<named-rulebook-outcome>(Node::get_text(to_compile)))
			@<Compile a named rulebook outline midriff@>
		else @<Compile a standard midriff@>;
	}

@<Compile a say term midriff@> =
	int s = allow_implied_newlines;
	if (Annotations::read_int(to_compile, suppress_newlines_ANNOT))
		allow_implied_newlines = FALSE;
	CompileBlocksAndLines::evaluate_invocation(to_compile, TRUE, INTER_VOID_VHMODE,
		allow_implied_newlines);
	allow_implied_newlines = s;

@<Compile a now midriff@> =
	current_sentence = to_compile;
	wording XW = Node::get_text(p->down);
	CompileBlocksAndLines::compile_a_now(XW);

@<Compile a named rulebook outline midriff@> =
	current_sentence = to_compile;
	named_rulebook_outcome *nrbo = <<rp>>;
	id_body *being_compiled = Functions::defn_being_compiled();
	if (being_compiled) {
		if (ImperativeDefinitionFamilies::goes_in_rulebooks(being_compiled->head_of_defn)
			== FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(to_compile));
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_MisplacedRulebookOutcome2));
			Problems::issue_problem_segment(
				"You wrote %1, but this is a rulebook outcome which can only be used within "
				"rulebooks which recognise it. You've used it in a definition which isn't "
				"for use in rulebooks at all, so it must be wrong here.");
			Problems::issue_problem_end();
		}
	}
	rulebook *rb = NULL;
	if (RuleFamily::outcome_restrictions_waived() == FALSE)
		rb = FocusAndOutcome::rulebook_not_supporting(nrbo, Functions::defn_being_compiled());
	if (rb) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(to_compile));
		Problems::quote_wording(3, rb->primary_name);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_MisplacedRulebookOutcome));
		Problems::issue_problem_segment(
			"You wrote %1, but this is a rulebook outcome which can only be used within "
			"rulebooks which recognise it. You've used it in a rule which has to be listed "
			"in the '%3' rulebook, where '%2' doesn't have a meaning.");
		Problems::issue_problem_end();
	}
	RTRulebooks::compile_outcome(nrbo);

@ When an "if" node has two children, they are the condition to test and then
the code block of what to execute if the condition is true:
= (text)
		CODE_BLOCK_NT {control structure: IF}
			INVOCATION_LIST_NT'if ...' {colon_block_command} {indent: 1}
			CODE_BLOCK_NT
				...
=
When it has three children, the extra block is what to execute if the condition
is false:
= (text)
		CODE_BLOCK_NT {control structure: IF}
			INVOCATION_LIST_NT'if ...' {colon_block_command} {indent: 1}
			CODE_BLOCK_NT
				...
			CODE_BLOCK_NT'otherwise' {colon_block_command} {indent: 1} {control structure: O}
				...
=

@<Compile an if midriff@> =
	if (p->down->next->next) EmitCode::inv(IFELSE_BIP);
	else EmitCode::inv(IF_BIP);
	EmitCode::down();
		current_sentence = to_compile;
		CompileBlocksAndLines::evaluate_invocation(to_compile, FALSE, INTER_VAL_VHMODE,
			allow_implied_newlines);

		EmitCode::code();
		EmitCode::down();
			CodeBlocks::open_code_block();
			statement_count = CompileBlocksAndLines::code_block(statement_count,
				p->down->next, FALSE, allow_implied_newlines, last_loc);
		if (p->down->next->next) {
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			CodeBlocks::divide_code_block();
			statement_count = CompileBlocksAndLines::code_block(statement_count,
				p->down->next->next, FALSE, allow_implied_newlines, last_loc);
		}
			CodeBlocks::close_code_block();
		EmitCode::up();
	EmitCode::up();

@ Switches, like |switch| in C, offer code to execute in different cases
depending on the "switch value". How efficiently this can be done depends
on the kind of that value.

The Inter VM offers an efficient way to provide switches for single-word
values, using |SWITCH_BIP|. But that only works if equality between two
values |V1| and |V2| can be tested by |V1 == V2|. For word-valued kinds
like |K_number|, that's fine, but not for kinds whose values are stored
in allocated blocks of memory, like |K_text|: |V1| and |V2| may be
pointers to different blocks of data, so that |V1 != V2|, even though
both blocks might hold the word "doubloon" so that the values are in fact
equal.

So we have to provide two completely different implementations. The harder
case, involving pointers to block values, is called "pointery"; the other
one is the "non-pointery" case.

@<Compile a switch midriff@> =
	current_sentence = to_compile;
	CompileBlocksAndLines::evaluate_invocation(to_compile, FALSE, INTER_VOID_VHMODE,
		allow_implied_newlines);

	CodeBlocks::open_code_block();

	parse_node *switch_val = CodeBlocks::switch_value();
	kind *switch_kind = Specifications::to_kind(switch_val);
	if (switch_val == NULL) internal_error("no switch value");

	int downs = 0;
	local_variable *sw_lv = NULL;
	inter_symbol *sw_v = NULL;
	int pointery = FALSE;
	if (Kinds::Behaviour::uses_block_values(switch_kind)) pointery = TRUE;

	LOG("Switch val is $T for kind %u pointery %d\n", switch_val, switch_kind, pointery);

	if (pointery) @<Begin a pointery switch@>
	else @<Begin a non-pointery switch@>;

	int c = 0;
	for (parse_node *ow_node = p->down->next->next; ow_node; ow_node = ow_node->next, c++) {
		current_sentence = ow_node;
		CodeBlocks::divide_code_block();

		if (Node::get_control_structure_used(ow_node) == default_case_CSP) {
			if (pointery) @<Handle a pointery default@>
			else @<Handle a non-pointery default@>;
		} else {
			if (<s-type-expression-or-value>(Node::get_text(ow_node))) {
				parse_node *case_spec = <<rp>>;
				case_spec = NonlocalVariables::substitute_constants(case_spec);
				Node::set_evaluation(ow_node, case_spec);
				if (Dash::check_value(case_spec, NULL) != NEVER_MATCH)
					@<Handle a general case@>
				else
					@<Issue problem message for unknown case value@>;
			} else {
				@<Issue problem message for unknown case value@>;
			}
		}
	}

	if (pointery) @<End a pointery switch@>
	else @<End a non-pointery switch@>;

	if (problem_count == 0) @<Test for duplicate cases@>;

@<Handle a general case@> =
	kind *case_kind = Specifications::to_kind(case_spec);
	instance *I = Rvalues::to_object_instance(case_spec);
	if (I) case_kind = Instances::to_kind(I);
	LOGIF(MATCHING, "(h.3) switch kind is %u, case kind is %u\n", switch_kind, case_kind);
	if ((Node::get_kind_of_value(case_spec) == NULL) && (I == NULL)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, switch_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CaseValueNonConstant));
		Problems::issue_problem_segment(
			"The case %1 is required to be a constant value, rather than "
			"something which has different values at different times: "
			"specifically, it has to be %2.");
		Problems::issue_problem_end();
		case_spec = Rvalues::new_nothing_object_constant();
	} else if (Kinds::compatible(case_kind, switch_kind) != ALWAYS_MATCH) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, case_kind);
		Problems::quote_kind(3, switch_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CaseValueMismatch));
		Problems::issue_problem_segment(
			"The case %1 has the wrong kind of value for the possibilities "
			"being chosen from: %2 instead of %3.");
		Problems::issue_problem_end();
		case_spec = Rvalues::new_nothing_object_constant();
	} else {
		if (pointery) @<Handle a pointery case@>
		else @<Handle a non-pointery case@>;
	}

@ Okay, so here's the code for a pointery switch. We generate something like this:
= (text)
	sw_v = ... switch value ...
	if (Equals(sw_v, v1)) {
		... case for v1 ...
	} else {
		if (Equals(sw_v, v2)) {
			... case for v2 ...
		} else {
			... default case ...
		}
	}
=	
We begin by ensuring that the function has a scratch local variable called |sw_v|,
and store the switch value in it. We need not use |BlkValueCopy| to make an
independent copy, since |sw_v| will be read-only: we can just copy the address of
the data into |sw_v| with a single |STORE_BIP| instruction, which is much faster.

@<Begin a pointery switch@> =
	sw_lv = LocalVariables::add_switch_value(K_value);
	sw_v = LocalVariables::declare(sw_lv);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, sw_v);
		CompileValues::to_code_val_of_kind(switch_val, switch_kind);
	EmitCode::up();

@ Now we handle the switch case for what to do when |sw_v| is |case_spec|. The count
of |downs| is how many times we have called |Produce::down|.

@<Handle a pointery case@> =
	int final_flag = FALSE;
	if (ow_node->next == NULL) final_flag = TRUE;

	if (final_flag) EmitCode::inv(IF_BIP);
	else EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		LocalVariables::set_kind(sw_lv, switch_kind);
		parse_node *sw_v = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, sw_lv);
		pcalc_prop *prop = Propositions::Abstract::to_set_relation(
			R_equality, NULL, sw_v, NULL, case_spec);
		TypecheckPropositions::type_check(prop,
			TypecheckPropositions::tc_no_problem_reporting());
		CompilePropositions::to_test_as_condition(NULL, prop);
		EmitCode::code();
		EmitCode::down();
			statement_count = CompileBlocksAndLines::code_block(statement_count,
				ow_node, FALSE, allow_implied_newlines, last_loc);
		if (final_flag == FALSE) {
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
		}
	downs += 2;

@ There need not be a default switch case, but if there is, then:

@<Handle a pointery default@> =
	statement_count = CompileBlocksAndLines::code_block(statement_count, ow_node,
		FALSE, allow_implied_newlines, last_loc);

@<End a pointery switch@> =
	while (downs-- > 0) EmitCode::up();
	CodeBlocks::close_code_block();

@ And now the more efficient case, using Inter's |SWITCH_BIP|, |CASE_BIP| and
|DEFAULT_BIP| instructions.

@<Begin a non-pointery switch@> =
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		CompileValues::to_code_val_of_kind(switch_val, switch_kind);
		EmitCode::code();
		EmitCode::down();

@<Handle a non-pointery case@> =
	EmitCode::inv(CASE_BIP);
	EmitCode::down();
		CompileValues::to_code_val_of_kind(case_spec, switch_kind);
		EmitCode::code();
		EmitCode::down();
			statement_count = CompileBlocksAndLines::code_block(statement_count,
				ow_node, FALSE, allow_implied_newlines, last_loc);
		EmitCode::up();
	EmitCode::up();

@<Handle a non-pointery default@> =
	EmitCode::inv(DEFAULT_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();
			statement_count = CompileBlocksAndLines::code_block(statement_count,
				ow_node, FALSE, allow_implied_newlines, last_loc);
		EmitCode::up();
	EmitCode::up();

@<End a non-pointery switch@> =
	EmitCode::up();
	CodeBlocks::close_code_block();
	EmitCode::up();

@ In either implementation, we perform this check:

@<Test for duplicate cases@> =
	for (parse_node *A = p->down->next->next; A; A = A->next) {
		int dup = FALSE;
		for (parse_node *B = A->next; B; B = B->next)
			if (Rvalues::compare_CONSTANT(
				Node::get_evaluation(A), Node::get_evaluation(B)))
					dup = TRUE;
		if (dup) {
			current_sentence = A;
			Problems::quote_source(1, A);
			Problems::quote_spec(2, Node::get_evaluation(A));
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_CaseValueDuplicated));
			Problems::issue_problem_segment(
				"The case %1 occurs more than once in this 'if' switch.");
			Problems::issue_problem_end();
		}
	}

@<Compile a standard midriff@> =
	current_sentence = to_compile;
	CompileBlocksAndLines::evaluate_invocation(to_compile, FALSE, INTER_VOID_VHMODE,
		allow_implied_newlines);

@h Tail code for lines.

@<Compile the tail@> =
	if (csp == if_CSP) @<Compile an if tail@>
	else if (csp == switch_CSP) @<Compile a switch tail@>
	else if (csp == say_CSP) @<Compile a say tail@>
	else if (csp == instead_CSP) @<Compile an instead tail@>
	else if (ControlStructures::opens_block(csp)) @<Compile a loop tail@>;

@<Compile an if tail@> =
	;

@<Compile a switch tail@> =
	;

@<Issue problem message for unknown case value@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CaseValueUnknown),
		"I don't recognise this case value",
		"that is, the value written after the '--'.");

@ As will be seen, two sets of labels and counters are kept here: see the
inline definitions for "say if" and similar.

@<Compile a say tail@> =
	statement_count = CompileBlocksAndLines::code_block(statement_count, p,
		FALSE, allow_implied_newlines, last_loc);

	TEMPORARY_TEXT(SAYL)
	WRITE_TO(SAYL, ".");
	JumpLabels::write(SAYL, I"Say");
	EmitCode::place_label(EmitCode::reserve_label(SAYL));
	DISCARD_TEXT(SAYL)

	JumpLabels::read_counter(I"Say", 1);

	TEMPORARY_TEXT(SAYXL)
	WRITE_TO(SAYXL, ".");
	JumpLabels::write(SAYXL, I"SayX");
	EmitCode::place_label(EmitCode::reserve_label(SAYXL));
	DISCARD_TEXT(SAYXL)

	JumpLabels::read_counter(I"SayX", 1);

@<Compile an instead tail@> =
	EmitCode::rtrue();

@<Compile a loop tail@> =
	CodeBlocks::open_code_block();
	statement_count = CompileBlocksAndLines::code_block(statement_count, p->down->next,
		FALSE, allow_implied_newlines, last_loc);
	while (EmitCode::level() > L) EmitCode::up();
	CodeBlocks::close_code_block();

@h Nows.

=
void CompileBlocksAndLines::compile_a_now(wording XW) {
	parse_node *cs = NULL;
	if (<s-condition>(XW)) cs = <<rp>>; else cs = Specifications::new_UNKNOWN(XW);
	LOGIF(MATCHING, "Now cond is $T\n", cs);
	int rv = Dash::check_condition(cs);
	LOGIF(MATCHING, "After Dash, it's $T\n", cs);

	if (Node::is(cs, TEST_PROPOSITION_NT)) {
		if (rv != NEVER_MATCH) {
			pcalc_prop *prop = Specifications::to_proposition(cs);
			if (prop) CompilePropositions::to_make_true(prop);
		}
	} else if (Specifications::is_condition(cs))
		@<Issue a problem message for the wrong sort of condition in a "now"@>
	else if (rv != NEVER_MATCH) @<Issue a problem message for an unrecognised condition@>;
}

@<Issue a problem message for the wrong sort of condition in a "now"@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(cs));
	if (Node::is(cs, TEST_VALUE_NT)) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadNow1));
		Problems::issue_problem_segment(
			"You wrote %1, but although '%2' is a condition which it is legal to test "
			"with 'if', 'when', and so forth, it is not something I can arrange to happen "
			"on request. Whether it is true or not depends on current circumstances: so "
			"to make it true, you will need to adjust those circumstances.");
		Problems::issue_problem_end();
	} else if (Node::is(cs, LOGICAL_AND_NT)) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadNow2));
		Problems::issue_problem_segment(
			"You wrote %1, but 'now' does not work with the condition '%2' because it can "
			"only make one wish come true at a time: so it doesn't like the 'and'. Try "
			"rewriting as two 'now's in a row?");
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadNow3));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2'	isn't the sort of condition which can be made to be "
			"true, in the way that 'the ball is on the table' can be made true with a "
			"straightforward movement of one object (the ball).");
		Problems::issue_problem_end();
	}

@<Issue a problem message for an unrecognised condition@> =
	LOG("$T\n", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(cs));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2'	isn't a condition, so I can't see how to make it true "
		"from here on.");
	Problems::issue_problem_end();

@h The evaluator.
This function takes the text of a line from a phrase definition, parses it,
type-checks it, and finally, all being well, compiles it.

=
void CompileBlocksAndLines::evaluate_invocation(parse_node *p, int already_parsed,
	int vhm, int allow_implied_newlines) {
	int initial_problem_count = problem_count;

	LOGIF(EXPRESSIONS, "\n-- -- Evaluating <%W> -- --\n", Node::get_text(p));

	LOGIF(EXPRESSIONS, "(a) Parsing:\n");
	if (already_parsed) {
		parse_node *inv = InvocationLists::first_reading(p->down);
		if ((inv) &&
			(Node::get_phrase_invoked(inv)) &&
			(IDTypeData::is_a_say_phrase(Node::get_phrase_invoked(inv))) &&
			(Node::get_phrase_invoked(inv)->type_data.as_say.say_control_structure == NO_SAY_CS)) {
			EmitCode::call(Hierarchy::find(PARACONTENT_HL));
		}
	} else {
		SParser::parse_void_phrase(p);
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "(b) Type checking:\n$E", p->down);
		Dash::check_invl(p);
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "(c) Compilation:\n$E", p->down);
		value_holster VH = Holsters::new(vhm);
		CompileInvocations::list(&VH, p->down, Node::get_text(p), allow_implied_newlines);
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "-- -- Completed -- --\n");
	} else {
		LOGIF(EXPRESSIONS, "-- -- Failed -- --\n");
	}
}

@h Validating sequences of say invocations.
Test substitutions result in "say" invocations with multiple things to do:
here are examples, increasing in difficulty --
= (text as Inform 7)
"Estates are worth at least [N]."
"Platinum is shinier than [if a Colony is in the Supply Pile]gold[otherwise]silver."
"The best defence is [one of]Lighthouse[or]Moat[or]having no money[at random]."
=
These imply 3, 5 and 9 individual invocations, respectively. The second and
third examples involve "say control structures", which means that those
invocations have to connect properly with each other: thus "[if...]" can be
followed by "[otherwise]", but "[otherwise]" must not occur on its own, and
so on. The final example is a so-called "segmented say phrase", or SSP.

These say control structures can even be nested, within limits:

@d MAX_COMPLEX_SAY_DEPTH 32 /* and it would be terrible coding style to approach this */

@ The following function throws problem messages for each of the many ways these
say control structures can be abused. On correct code, it also annotates nodes
for SSP clauses in a way which will later help //Compile Invocations Inline//.

=
void CompileBlocksAndLines::verify_say_node_list(parse_node *say_node_list) {
	int problem_issued = FALSE;
	int it_was_not_worth_adding = TextSubstitutions::is_it_worth_adding();
	TextSubstitutions::it_is_not_worth_adding();

	int SSP_sp = 0;
	int SSP_stack[MAX_COMPLEX_SAY_DEPTH];
	int SSP_stack_otherwised[MAX_COMPLEX_SAY_DEPTH];
	parse_node *SSP_invocations[MAX_COMPLEX_SAY_DEPTH];
	int say_if_nesting = 0;

	for (parse_node *say_node = say_node_list; say_node; say_node = say_node->next) {
		parse_node *invl = say_node->down;
		if (invl) {
			parse_node *inv;
			LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
				id_body *idb = Node::get_phrase_invoked(inv);
				if ((Node::get_phrase_invoked(inv)) &&
					(IDTypeData::is_a_say_phrase(idb)))
					@<This is a say invocation@>;
			}
		}
	}
	if (SSP_sp > 0) {
		if ((SSP_sp == 1) && (SSP_stack[0] == -1)) {
			/* an if without an end if, which uniquely is legal */
		} else {
			@<Issue a problem message for an SSP without end@>;
		}
	}
	if (it_was_not_worth_adding) TextSubstitutions::it_is_not_worth_adding();
	else TextSubstitutions::it_is_worth_adding();
}

@<This is a say invocation@> =
	int say_cs, ssp_tok, ssp_ctok, ssp_pos;
	IDTypeData::get_say_data(&(idb->type_data.as_say), &say_cs, &ssp_tok, &ssp_ctok, &ssp_pos);

	if (ssp_pos == SSP_START) @<This starts a complex SSP@>;
	if (ssp_pos == SSP_MIDDLE) @<This is a middle term in a complex SSP@>;
	if (ssp_pos == SSP_END) @<This ends a complex SSP@>;

	if (say_cs == IF_SAY_CS) @<This is a say if@>;
	if ((say_cs == OTHERWISE_SAY_CS) || (say_cs == OTHERWISE_IF_SAY_CS))
		@<This is a say otherwise@>;
	if (say_cs == END_IF_SAY_CS) @<This is a say end if@>;

@<This starts a complex SSP@> =
	if (SSP_sp >= MAX_COMPLEX_SAY_DEPTH) {
		@<Issue a problem message for an overcomplex SSP@>;
	} else {
		SSP_invocations[SSP_sp] = inv;
		SSP_stack_otherwised[SSP_sp] = FALSE;
		SSP_stack[SSP_sp++] = ssp_tok;
	}

@<This is a middle term in a complex SSP@> =
	if ((SSP_sp > 0) && (SSP_stack[SSP_sp-1] != -1) &&
		(compare_words(SSP_stack[SSP_sp-1], ssp_tok))) {
		Annotations::write_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT,
			Annotations::read_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT)+1);
		Annotations::write_int(inv, ssp_segment_count_ANNOT,
			Annotations::read_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT));
	} else @<Issue a problem message for middle without start@>;

@<This ends a complex SSP@> =
	if ((SSP_sp > 0) && (SSP_stack[SSP_sp-1] != -1) &&
		(compare_words(SSP_stack[SSP_sp-1], ssp_tok))) {
		Annotations::write_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT,
			Annotations::read_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT)+1);
		Annotations::write_int(SSP_invocations[SSP_sp-1], ssp_closing_segment_wn_ANNOT, ssp_ctok);
		Annotations::write_int(inv, ssp_segment_count_ANNOT,
			Annotations::read_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT));
		SSP_sp--;
	} else @<Issue a problem message for end without start@>;

@<This is a say if@> =
	if (say_if_nesting == 0) {
		say_if_nesting++;
		SSP_invocations[SSP_sp] = NULL;
		SSP_stack_otherwised[SSP_sp] = FALSE;
		SSP_stack[SSP_sp++] = -1;
	} else @<Issue a problem message for nested say if@>;

@<This is a say otherwise@> =
	if (say_if_nesting == 0)
		@<Issue a problem message for say otherwise without say if@>
	else if (SSP_sp > 0) {
		if (SSP_stack[SSP_sp-1] != -1)
			@<Issue a problem message for say otherwise interleaved with another construction@>;
		if (SSP_stack_otherwised[SSP_sp-1])
			@<Issue a problem message for two say otherwises@>
		if (say_cs == OTHERWISE_SAY_CS) SSP_stack_otherwised[SSP_sp-1] = TRUE;
	}

@<This is a say end if@> =
	if (say_if_nesting == 0)
		@<Issue a problem message for say end if without say if@>
	else if ((SSP_sp > 0) && (SSP_stack[SSP_sp-1] != -1))
		@<Issue a problem message for say end if interleaved with another construction@>
	else {
		say_if_nesting--;
		SSP_sp--;
	}

@<Issue a problem message for middle without start@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(inv));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ComplicatedSayStructure));
		Problems::issue_problem_segment(
			"In the text at %1, the text substitution '[%2]' ought to occur as the "
			"middle part of its construction, but it appears to be on its own.");
		CompileBlocksAndLines::add_say_construction_to_error(ssp_tok);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for end without start@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(inv));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ComplicatedSayStructure2));
		Problems::issue_problem_segment(
			"In the text at %1, the text substitution '[%2]' ought to occur as the "
			"ending part of its construction, but it appears to be on its own.");
		CompileBlocksAndLines::add_say_construction_to_error(ssp_tok);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for nested say if@> =
	if (problem_issued == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_SayIfNested),
			"a second '[if ...]' text substitution occurs inside an existing one",
			"which makes this text too complicated. While a single text can contain "
			"more than one '[if ...]', this can only happen if the old if is finished "
			"with an '[end if]' or the new one is written '[otherwise if]'. If you "
			"need more complicated variety than this allows, the best approach is "
			"to define a new text substitution of your own ('To say fiddly details: "
			"...') and then use it in this text by including the '[fiddly details]'.");
		problem_issued = TRUE;
	}

@<Issue a problem message for an overcomplex SSP@> =
	if (problem_issued == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_SayOverComplex),
			"this is too complex a text substitution",
			"and needs to be simplified. You might find it helpful to define a new text "
			"substitution of your own ('To say fiddly details: ...') and then use it "
			"in this text by including the '[fiddly details]'.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say otherwise without say if@> =
	if (problem_issued == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_SayOtherwiseWithoutIf),
			"an '[otherwise]' text substitution occurs where there appears to be no "
			"[if ...]",
			"which doesn't make sense - there is nothing for it to be otherwise to.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say otherwise interleaved with another construction@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(inv));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ComplicatedSayStructure5));
		Problems::issue_problem_segment(
			"In the text at %1, the '[%2]' ought to occur inside an [if ...], but is cut "
			"off because it has been interleaved with a complicated say construction.");
		CompileBlocksAndLines::add_say_construction_to_error(SSP_stack[SSP_sp-1]);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for two say otherwises@> =
	if (problem_issued == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TwoSayOtherwises),
			"there's already an (unconditional) \"[otherwise]\" or \"[else]\" in this "
			"text substitution",
			"so it doesn't make sense to follow that with a further one.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say end if without say if@> =
	if (problem_issued == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_SayEndIfWithoutSayIf),
			"an '[end if]' text substitution occurs where there appears to be no "
			"[if ...]",
			"which doesn't make sense - there is nothing for it to end.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say end if interleaved with another construction@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(inv));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ComplicatedSayStructure4));
		Problems::issue_problem_segment(
			"In the text at %1, the '[%2]' is cut off from its [if ...], because it "
			"has been interleaved with a complicated say construction.");
		CompileBlocksAndLines::add_say_construction_to_error(SSP_stack[SSP_sp-1]);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for an SSP without end@> =
	if (problem_issued == FALSE) {
		parse_node *stinv = NULL;
		int i, ssp_tok = -1;
		for (i=0; i<SSP_sp; i++)
			if (SSP_invocations[i]) {
				stinv = SSP_invocations[i];
				ssp_tok = SSP_stack[i];
			}
		if (stinv) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(stinv));
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_ComplicatedSayStructure3));
			Problems::issue_problem_segment(
				"In the text at %1, the text substitution '[%2]' seems to start a "
				"complicated say construction, but it doesn't have a matching end.");
			if (ssp_tok >= 0) CompileBlocksAndLines::add_say_construction_to_error(ssp_tok);
			Problems::issue_problem_end();
			problem_issued = TRUE;
		}
	}

@ These just help to construct problem messages for complex say constructions:

=
void CompileBlocksAndLines::add_say_construction_to_error(int ssp_tok) {
	Problems::issue_problem_segment(" %P(The construction I'm thinking of is '");
	CompileBlocksAndLines::add_scte_list(ssp_tok, SSP_START);
	Problems::issue_problem_segment(" ... ");
	CompileBlocksAndLines::add_scte_list(ssp_tok, SSP_MIDDLE);
	Problems::issue_problem_segment(" ... ");
	CompileBlocksAndLines::add_scte_list(ssp_tok, SSP_END);
	Problems::issue_problem_segment("'.)");
}

void CompileBlocksAndLines::add_scte_list(int ssp_tok, int list_pos) {
	id_body *idb; int ct = 0;
	LOOP_OVER(idb, id_body) {
		wording W;
		if (IDTypeData::ssp_matches(&(idb->type_data), ssp_tok, list_pos, &W)) {
			Problems::quote_wording(3, W);
			if (ct++ == 0) Problems::issue_problem_segment("[%3]");
			else Problems::issue_problem_segment("/[%3]");
		}
	}
}
