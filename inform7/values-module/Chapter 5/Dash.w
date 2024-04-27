[Dash::] Dash.

The part of Inform most nearly like a typechecker in a conventional compiler.

@ Dash is the second typechecking algorithm to be used in Inform, installed in
early 2015: the first had served since 2003, but became unwieldy after so many
exceptional cases had been added to it, and was impossible to adapt to the
redesigned parse tree. Dash is not so called because it's faster (it's
actually a few percent slower), but because at one stage Inform was running
both typecheckers side by side: TC and TC-dash, or Dash for short. TC-dash
won, it's still called Dash, and TC is no more.

Because Dash also deals with text which entirely fails to make sense, which in
other compilers would be rejected at a lower level, it has to issue basic
syntax errors as well as type mismatch errors. This is arguably a good thing,
though, because it means they can be issued using the same generally helpful
system as more sophisticated problems.

Partly because of the need to do this, the type-checker has a top-down
approach. It aims to prove that the node found can match what's expected,
making selections from alternative readings, and in limited cases actually
making changes to the parse tree, in order to do this. For instance,
consider checking the tree for:

>> let the score be the score plus 10

Dash takes the view that the phrase usage can be proved correct, so long as
the arguments can also be proved. There are several valid interpretations of
"let ... be ...", and these are all present in the parse tree as alternative
interpretations, so the typechecker tries each in turn, accepting one (or
more) if the arguments can be proved to be of the right type. This means
proving that argument 0 ("the score") is an lvalue and also that argument 1
("the score plus 10") is an rvalue. A further rule requires that the kind of
value of argument 1 must match the kind of value stored in the variable, here
a "number", so we must prove that too. Now "plus" is polymorphic and can
produce different kinds of value depending on the kinds of value it acts upon,
so again we must check all possible interpretations. But we finally succeed in
showing that "score" is an lvalue, "10" is a number, "score" is also a number,
and that "plus" on two numbers gives a number, so we complete the proof and
the phrase is proved correct.

@ When issuing problems, we show a form of backtrace so that the user can
see what we've considered, and this is used to accumulate data for that.

=
typedef struct inv_token_problem_token {
	struct wording problematic_text;
	struct parse_node *as_parsed;
	int already_described;
	int new_name; /* found in context of a name not yet defined */
	CLASS_DEFINITION
} inv_token_problem_token;

@h The Dashboard.
Dash uses a small suite of global variables to keep track of two decidedly
global side-effects of checking: the issuing of problem messages, and the
setting of kind variables. This suite is called the "dashboard".

First, we keep track of the problem messages we will issue, if any, using
a bitmap made up of the following modes:

@d BEGIN_DASH_MODE			int s_dm = dash_mode;
							kind **s_kvc = kind_of_var_to_create;
							parse_node *s_invl = Dash_ambiguity_list;
@d DASH_MODE_ENTER(mode)	dash_mode |= mode;
@d DASH_MODE_CREATE(K)		kind_of_var_to_create = K;
@d DASH_MODE_EXIT(mode)		dash_mode &= (~mode);
@d END_DASH_MODE			dash_mode = s_dm;
							kind_of_var_to_create = s_kvc;
							Dash_ambiguity_list = s_invl;
@d TEST_DASH_MODE(mode)		(dash_mode & mode)

@d ISSUE_PROBLEMS_DMODE     		0x00000001 /* rather than keep silent about them */
@d ISSUE_LOCAL_PROBLEMS_DMODE		0x00000002 /* at the end, that is */
@d ISSUE_GROSS_PROBLEMS_DMODE		0x00000004 /* at the end, that is */
@d ISSUE_INTERESTING_PROBLEMS_DMODE	0x00000008 /* unless casting to text */
@d ABSOLUTE_SILENCE_DMODE     		0x00000010 /* say nothing at all */

=
int dash_mode = ISSUE_PROBLEMS_DMODE; /* default */
kind **kind_of_var_to_create = NULL;
int dash_recursion_count = 0;

@ Three grades of problem can appear: "ordinary", "gross" and "grosser than
gross". We distinguish these in order to produce a Problem message which
reflects the biggest thing wrong, rather than being so esoteric that it misses
the main point. Changing a particular error condition from an ordinary to a
gross problem, or vice versa, has no effect on the result returned by Dash,
only on the Problem messages given to the user.

@d THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM
	no_gross_problems_thrown++; /* problems this gross cannot be suppressed */

@d THIS_IS_A_GROSS_PROBLEM
	no_gross_problems_thrown++; /* this increments even if the message is suppressed */
	if ((TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE) == FALSE) &&
		(TEST_DASH_MODE(ISSUE_GROSS_PROBLEMS_DMODE) == FALSE)) return NEVER_MATCH;

@d THIS_IS_AN_ORDINARY_PROBLEM
	if (TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE) == FALSE) return NEVER_MATCH;

=
int no_gross_problems_thrown = 0;
int no_interesting_problems_thrown = 0;
int initial_problem_count = 0;
int backtraced_problem_count = 0;

int Dash::problems_have_been_issued(void) {
	if (initial_problem_count < problem_count) return TRUE;
	return FALSE;
}

@ Next, we keep track of the most recent set of meanings attached to the
kind variables A, B, C, ..., Z, and the most recently looked-at list of
invocations.

=
kind_variable_declaration *most_recent_interpretation = NULL;
parse_node *Dash_ambiguity_list = NULL;

@ We need careful debug logging of what Dash does. During Inform's infancy, the
type checker was the hardest thing to debug, but that wasn't so much because
this was the great habitat and breeding ground for bugs; it was more that those
bugs which were here were by far the hardest to root out. So careful logging
on demand is vital.

Each call to the recursive Dash has its own unique ID number, to make logging
more legible.

@d LOG_DASH_LEFT
	LOGIF(MATCHING, "[%d%s] ",
		unique_DR_call_identifier,
		(TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE))?"":"-silent");
@d LOG_DASH(stage)
	LOGIF(MATCHING, "[%d%s] %s $P\n",
		unique_DR_call_identifier,
		(TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE))?"":"-silent", stage, p);

=
int unique_DR_call_identifier = 0, DR_call_counter = 0; /* solely to make the log more legible */

@h Return values.
Dash records the outcome of checking as one of three states.

It is perhaps telling that we never need a |Dash::best_case| routine.
Typecheckers are not allowed to be optimistic.

=
int Dash::worst_case(int rv1, int rv2) {
	if ((rv1 == NEVER_MATCH) || (rv2 == NEVER_MATCH)) return NEVER_MATCH;
	if ((rv1 == SOMETIMES_MATCH) || (rv2 == SOMETIMES_MATCH)) return SOMETIMES_MATCH;
	return ALWAYS_MATCH;
}

@h (1) Entering Dash.
Dash is structured into levels and this is level 1, the topmost.

Dash has three points of entry: to check a condition, check a value, or check
an invocation list for a phrase used in a routine.

These top-level routines do not look recursive, but in fact some can be,
because Dash needs to call the predicate calculus engine to typecheck
propositions: and these in turn call Dash to check that constant values
are used correctly.

All of these funnel downwards into level 2:

=
int Dash::check_condition(parse_node *p) {
	parse_node *cn = Node::new(CONDITION_CONTEXT_NT);
	cn->down = p;
	LOGIF(MATCHING, "Dash (1): condition\n");
	return Dash::funnel_to_level_2(cn, FALSE);
}

int Dash::check_value(parse_node *p, kind *K) {
	parse_node *vn = Node::new(RVALUE_CONTEXT_NT);
	if (K) Node::set_kind_required_by_context(vn, K);
	vn->down = p;
	if (K) LOGIF(MATCHING, "Dash (1): value of kind %u\n", K);
	if (K == NULL) LOGIF(MATCHING, "Dash (1): value\n");
	return Dash::funnel_to_level_2(vn, FALSE);
}

int Dash::check_value_silently(parse_node *p, kind *K) {
	parse_node *vn = Node::new(RVALUE_CONTEXT_NT);
	if (K) Node::set_kind_required_by_context(vn, K);
	vn->down = p;
	if (K) LOGIF(MATCHING, "Dash (1): value of kind %u\n", K);
	if (K == NULL) LOGIF(MATCHING, "Dash (1): value\n");
	return Dash::funnel_to_level_2(vn, TRUE);
}

int Dash::check_invl(parse_node *p) {
	LOGIF(MATCHING, "Dash (1): invocation list '%W'\n", Node::get_text(p));
	LOGIF(MATCHING, "p = $T\n", p);
	return Dash::funnel_to_level_2(p, FALSE);
}

int Dash::funnel_to_level_2(parse_node *p, int silently) {
	no_gross_problems_thrown = 0;
	dash_recursion_count = 0;
	BEGIN_DASH_MODE;
	if (!silently) DASH_MODE_ENTER(ISSUE_PROBLEMS_DMODE);
	initial_problem_count = problem_count;
	DASH_MODE_CREATE(NULL);
	Latticework::show_frame_variables();
	int rv = Dash::typecheck_recursive(p, NULL, TRUE);
	END_DASH_MODE;
	return rv;
}

@h (2) Recursion point.
Loosely speaking, Dash works by visiting every node in the parse tree being
examined with the following routine, which is therefore recursive as Dash
heads ever downward.

The routine itself is really just an outer shell, though, and has two
functions: it keeps the debugging log tidy (see above) and it produces
the backtrace if the inner routine should throw a problem message.

The recursion limit below is clearly arbitrary, but is there to prevent the
algorithm from slowing Inform unacceptably in the event of something like

>> say  g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g + g;

where "g" is a term Inform doesn't recognise, because otherwise this will
recurse through every possible interpretation of the plus sign (i.e. every
possible order of operations).

@d MAX_DASH_RECURSION 10000

=
int Dash::typecheck_recursive(parse_node *p, parse_node *context, int consider_alternatives) {
	if (p == NULL) internal_error("Dash on null node");

	if (dash_recursion_count >= MAX_DASH_RECURSION) return NEVER_MATCH;
	dash_recursion_count++;

	int outer_id = unique_DR_call_identifier;
	int problem_count_before = problem_count;
	unique_DR_call_identifier = DR_call_counter++;
	LOG_INDENT;
	LOG_DASH("(2)");
	int return_value = Dash::typecheck_recursive_inner(p, context, consider_alternatives);

	switch(return_value) {
		case ALWAYS_MATCH:    LOG_DASH_LEFT; LOGIF(MATCHING, "== always\n"); break;
		case SOMETIMES_MATCH: LOG_DASH_LEFT; LOGIF(MATCHING, "== sometimes\n"); break;
		case NEVER_MATCH:     LOG_DASH_LEFT; LOGIF(MATCHING, "== never\n"); break;
		default: internal_error("impossible verdict from Dash");
	}
	LOG_OUTDENT;

	if ((problem_count > problem_count_before) && (consider_alternatives))
		@<Consider adding a backtrace of what the type-checker was up to@>;

	unique_DR_call_identifier = outer_id;
	return return_value;
}

@ The backtrace is added to problem messages only if we have just been checking
a phrase, and if it produced problems not previously seen. The trick here is
to ensure that if we have

>> let X be a random wibble bibble spong;

then it will be the "random ..." phrase which is backtraced, and not the
"let ..." phrase, even though that also goes wrong in turn.

@<Consider adding a backtrace of what the type-checker was up to@> =
	if (problem_count > backtraced_problem_count) {
		if ((p) && (p->down) &&
			(Node::get_type(p) == INVOCATION_LIST_NT)) {
			TextSubstitutions::it_is_not_worth_adding();
			@<Backtrace what phrase definitions the type-checker was looking at@>;
			TextSubstitutions::it_is_worth_adding();
			backtraced_problem_count = problem_count;
		}
	}

@ We skip proven invocations, and those never needed because of them, since
those aren't in dispute; and we also skip groups not even reached, since they
aren't where the problem lies. (This can happen when checking a compound "say",
from a text substitution.)

@<Backtrace what phrase definitions the type-checker was looking at@> =
	parse_node *inv;
	LOOP_THROUGH_ALTERNATIVES(inv, p->down) LOG("$e\n", inv);

	int to_show = 0;
	LOOP_THROUGH_ALTERNATIVES(inv, p->down) {
		id_body *idb = Node::get_phrase_invoked(inv);
		if (IDTypeData::is_a_spare_say_X_phrase(&(idb->type_data))) continue;
		to_show++;
	}

	int announce = TRUE;
	text_stream *latest = Problems::latest_sigil();
	if (Str::eq_wide_string(latest, U"PM_AllInvsFailed")) announce = FALSE;

	if (announce) @<Produce the I was trying... banner@>;
	@<Produce the list of possibilities@>;
	int real_found = FALSE;
	@<Produce the tokens which were recognisable as something@>;
	@<Produce the tokens which weren't recognisable as something@>;
	@<Produce the tokens which were intentionally not recognisable as something@>;
	if (real_found) @<Produce a note about real versus integer@>;

@<Produce the I was trying... banner@> =
	Problems::issue_problem_begin(Task::syntax_tree(), "*");
	if (to_show > 1)
		Problems::issue_problem_segment("I was trying to match one of these phrases:");
	else
		Problems::issue_problem_segment("I was trying to match this phrase:");
	Problems::issue_problem_end();

@<Produce the list of possibilities@> =
	int shown = 0;
	LOOP_THROUGH_ALTERNATIVES(inv, p->down) {
		id_body *idb = Node::get_phrase_invoked(inv);
		if (IDTypeData::is_a_spare_say_X_phrase(&(idb->type_data))) continue;
		shown++;
		Problems::quote_number(1, &shown);
		Problems::quote_invocation(2, inv);
		if (announce == FALSE) {
			Problems::issue_problem_begin(Task::syntax_tree(), "***");
			announce = TRUE;
		} else {
			Problems::issue_problem_begin(Task::syntax_tree(), "****");
		}
		if (to_show > 1) Problems::issue_problem_segment("%1. %2");
		else Problems::issue_problem_segment("%2");
		Problems::issue_problem_end();
	}

@<Produce the tokens which were recognisable as something@> =
	int any = FALSE;
	inv_token_problem_token *itpt;
	LOOP_OVER(itpt, inv_token_problem_token)
		if (Node::is(itpt->as_parsed, UNKNOWN_NT) == FALSE)
			if (itpt->already_described == FALSE) {
				itpt->already_described = TRUE;
				if (any == FALSE) {
					any = TRUE;
					Problems::issue_problem_begin(Task::syntax_tree(), "*");
					Problems::issue_problem_segment("I recognised:");
					Problems::issue_problem_end();
				}
				@<Produce this token@>;
			}

@<Produce this token@> =
	Problems::quote_wording_tinted_green(1, itpt->problematic_text);
	Problems::quote_spec(2, itpt->as_parsed);
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	if (Specifications::is_value(itpt->as_parsed)) {
		kind *K = Specifications::to_kind(itpt->as_parsed);
		int changed = FALSE;
		K = Kinds::substitute(K, NULL, &changed, FALSE);
		Problems::quote_kind(3, K);
		if (Kinds::eq(K, K_real_number)) real_found = TRUE;
		if (Lvalues::is_lvalue(itpt->as_parsed))
			@<Produce the token for an lvalue@>
		else if (Node::is(itpt->as_parsed, PHRASE_TO_DECIDE_VALUE_NT))
			@<Produce the token for a phrase deciding a value@>
		else
			@<Produce the token for a constant rvalue@>;
	} else Problems::issue_problem_segment("%1 = %2");
	Problems::issue_problem_end();

@<Produce the token for an lvalue@> =
	Problems::issue_problem_segment("%1 = %2, holding %3");

@<Produce the token for a phrase deciding a value@> =
	char *seg = "%1 = an instruction to work out %3";
	if (K == NULL) seg = "%1 = a phrase";
	parse_node *found_invl = itpt->as_parsed->down;
	parse_node *inv;
	LOOP_THROUGH_ALTERNATIVES(inv, found_invl) {
		LOG("$e\n", inv);
		if (Dash::reading_passed(inv) == FALSE) {
			seg = "%1 = an instruction I think should work out %3, "
				"but which I can't make sense of";
			for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
				parse_node *tok = Invocations::get_token_as_parsed(inv, i);
				if (Node::is(tok, UNKNOWN_NT)) {
					Problems::quote_wording(4, Node::get_text(tok));
					seg = "%1 = an instruction I think should work out %3, "
						"but which I can't perform because '%4' doesn't make sense here";
					break;
				}
			}
		}
	}
	Problems::issue_problem_segment(seg);

@<Produce the token for a constant rvalue@> =
	char *seg = "%1 = %3";
	if (Rvalues::is_CONSTANT_construction(itpt->as_parsed, CON_property)) {
		property *prn = Node::get_constant_property(itpt->as_parsed);
		if (Properties::is_value_property(prn)) {
			binary_predicate *bp = ValueProperties::get_stored_relation(prn);
			if (bp) {
				seg = "%1 = %3, which is used to store %4, "
					"but is not the same thing as the relation itself";
				Problems::quote_relation(4, bp);
			}
		}
	}
	Problems::issue_problem_segment(seg);

@<Produce the tokens which were intentionally not recognisable as something@> =
	int unknowns = 0;
	inv_token_problem_token *itpt;
	LOOP_OVER(itpt, inv_token_problem_token)
		if ((Node::is(itpt->as_parsed, UNKNOWN_NT)) && (itpt->new_name))
			if (itpt->already_described == FALSE) {
				itpt->already_described = TRUE;
				if (unknowns < 5) {
					Problems::quote_wording_tinted_red(++unknowns,
						itpt->problematic_text);
				}
			}
	if (unknowns > 0) {
		Problems::issue_problem_begin(Task::syntax_tree(), "*");
		char *chunk = "";
		switch (unknowns) {
			case 1: chunk = "The name '%1' doesn't yet exist."; break;
			case 2: chunk = "The names '%1' and '%2' don't yet exist."; break;
			case 3: chunk = "The names '%1', '%2' and '%3' don't yet exist."; break;
			case 4: chunk = "The names '%1', '%2', '%3' and '%4' don't yet exist."; break;
			default: chunk = "The names '%1', '%2', '%3', '%4', and so on, don't yet exist."; break;
		}
		Problems::issue_problem_segment(chunk);
		Problems::issue_problem_end();
	}

@<Produce the tokens which weren't recognisable as something@> =
	int unknowns = 0;
	inv_token_problem_token *itpt;
	LOOP_OVER(itpt, inv_token_problem_token)
		if ((Node::is(itpt->as_parsed, UNKNOWN_NT)) &&
			(itpt->new_name == FALSE))
			if (itpt->already_described == FALSE) {
				itpt->already_described = TRUE;
				if (unknowns < 5) {
					Problems::quote_wording_tinted_red(++unknowns,
						itpt->problematic_text);
				}
			}
	if (unknowns > 0) {
		Problems::issue_problem_begin(Task::syntax_tree(), "*");
		char *chunk = "";
		switch (unknowns) {
			case 1: chunk = "But I didn't recognise '%1'."; break;
			case 2: chunk = "But I didn't recognise '%1' or '%2'."; break;
			case 3: chunk = "But I didn't recognise '%1', '%2' or '%3'."; break;
			case 4: chunk = "But I didn't recognise '%1', '%2', '%3' or '%4'."; break;
			default: chunk = "But I didn't recognise '%1', '%2', '%3', '%4' and so on."; break;
		}
		Problems::issue_problem_segment(chunk);
		Problems::issue_problem_end();
	}

@<Produce a note about real versus integer@> =
	Problems::issue_problem_begin(Task::syntax_tree(), "*");
	Problems::issue_problem_segment(
		" %PNote that Inform's kinds 'number' and 'real number' are not "
		"interchangeable. A 'number' like 7 can be used where a 'real "
		"number' is expected - it becomes 7.000 - but not vice versa. "
		"Use 'R to the nearest whole number' if you want to make a "
		"conversion.");
	Problems::issue_problem_end();

@h (3) Context switching.
After those epic preliminaries, we finally do some typechecking.

The scheme here is that our expectations of |p| depend on the context, and
this is defined by some node higher in the current subtree than |p|, which
we will call |context|. Most of the time this is the parent of |p|, but
sometimes the grandparent or great-grandparent; and at the start of the
recursion, when no context has appeared yet, it will be null. In effect,
then, the tree we're checking contains its own instructions on how it
should be checked. For example, the subtree
= (text)
	CONDITION_CONTEXT_NT
	    p
=
tells us that when we reach |p| it should be checked as a condition.

=
int Dash::typecheck_recursive_inner(parse_node *p, parse_node *context, int consider_alternatives) {
	LOG_DASH("(3)");
	switch (p->node_type) {
		case CONDITION_CONTEXT_NT: 			@<Switch context@>;

		case RVALUE_CONTEXT_NT: 			@<Switch context@>;
		case MATCHING_RVALUE_CONTEXT_NT: 	@<Switch context to an rvalue matching a description@>;
		case SPECIFIC_RVALUE_CONTEXT_NT: 	@<Switch context to an rvalue matching a value@>;
		case VOID_CONTEXT_NT: 				@<Switch to a void context@>;

		case LVALUE_CONTEXT_NT: 			@<Switch context to an lvalue@>;
		case LVALUE_TR_CONTEXT_NT: 			@<Switch context to a table reference lvalue@>;
		case LVALUE_LOCAL_CONTEXT_NT: 		@<Switch context to an existing local variable lvalue@>;

		case NEW_LOCAL_CONTEXT_NT: 			@<Deal with a new local variable name@>;

		default:							@<Typecheck within current context@>;
	}
	return NEVER_MATCH; /* to prevent compiler warnings: unreachable in fact */
}

@ When we find a node like |CONDITION_CONTEXT_NT|, that becomes the new context
and we move down to its only child.

@d SWITCH_CONTEXT_AND_RECURSE(p) Dash::typecheck_recursive(p->down, p, TRUE)

@<Switch context@> =
	return SWITCH_CONTEXT_AND_RECURSE(p);

@ Other context switches are essentially the same thing, plus a check that
the value meets some extra requirement. For example:

@<Switch context to an lvalue@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (Lvalues::is_lvalue(p->down) == FALSE)
		@<Issue problem for not being an lvalue@>;
	return rv;

@ More specifically:

@<Switch context to a table reference lvalue@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (Node::is(p->down, TABLE_ENTRY_NT) == FALSE)
		@<Issue problem for not being a table reference@>;
	return rv;

@<Switch context to an existing local variable lvalue@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (Node::is(p->down, LOCAL_VARIABLE_NT) == FALSE)
		@<Issue problem for not being an existing local@>;
	return rv;

@ Suppose we are matching the parameter of a phrase like this:

>> To inspect (D - an open door): ...

and typechecking the following invocation:

>> inspect the Marble Portal;

Then we would have |p| set to some value -- here "the Marble Portal" --
and the |MATCHING_RVALUE_CONTEXT_NT| node would point to a description node
for open doors. We must see if |p| matches that. Any match can be at best at
the "sometimes" level. We can prove the Marble Portal is a door at compile
time, but we can't prove it's open until run-time.

Note that we switch context and recurse first, then make the supplementary
check afterwards, when we know the kinds at least must be right.

@<Switch context to an rvalue matching a description@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (rv != NEVER_MATCH)
		rv = Dash::worst_case(rv,
			Dash::compatible_with_description(p->down,
				Node::get_token_to_be_parsed_against(p)));
	return rv;

@ This is something else that wouldn't appear in a typical typechecker.
Here we are dealing with a phrase specification such as:

>> To attract (N - 10) things: ...

where the "N" argument will be accepted if and only if it's the value 10.
The fact that Inform allows this is further evidence of the slippery way
that natural language doesn't distinguish values from types; early designs
of Inform didn't allow it, but many people reported this as a bug.

Again we switch context and recurse first. We can't safely test pointer
values, such as texts, for equality at compile time -- for one thing, we
don't know what text substitutions will then expand to -- so the value
test only forces us towards never or always when the constants being
compared are word values.

@<Switch context to an rvalue matching a value@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (rv != NEVER_MATCH) {
		kind *K = Specifications::to_kind(p->down);
		if ((Kinds::Behaviour::uses_block_values(K) == FALSE) &&
			(Node::is(p->down, CONSTANT_NT))) {
			parse_node *val = Node::get_token_to_be_parsed_against(p);
			if (!(Rvalues::compare_CONSTANT(p->down, val)))
				@<Issue problem for being the wrong rvalue@>;
		} else {
			rv = Dash::worst_case(rv, SOMETIMES_MATCH);
			LOGIF(MATCHING, "dropping to sometimes level for value comparison\n");
		}
	}
	return rv;

@ I would ideally like to remove void contexts from Dash entirely, but was
forced to retain them by the popularity of the Hypothetical Questions
extension, which made use of the old undocumented |phrase| token.

@<Switch to a void context@> =
	int rv = SWITCH_CONTEXT_AND_RECURSE(p);
	if (rv != NEVER_MATCH) {
		if (!(Node::is(p->down, PHRASE_TO_DECIDE_VALUE_NT))) {
			@<Issue problem for not being a phrase@>;
		}
	}
	return rv;

@ A whole set of problem messages arise out of contextual failures:

@<Issue problem for not being an lvalue@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p->down));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ValueAsStorageItem));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' is a value, not a place where a value is "
		"stored. "
		"%PFor example, if 'The tally is a number that varies.', then "
		"I can 'increment the tally', but I can't 'increment 37' - the "
		"number 37 is always what it is. Similarly, I can't 'increment "
		"the number of people'. Phrases like 'increment' work only on "
		"stored values, like values that vary, or table entries.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue problem for not being a table reference@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p->down));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ValueAsTableReference));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' is a value, not a reference to an entry "
		"in a table.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue problem for not being an existing local@> =
	if (TEST_DASH_MODE(ISSUE_LOCAL_PROBLEMS_DMODE)) {
		THIS_IS_AN_ORDINARY_PROBLEM;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(p));
		if (Specifications::is_kind_like(p->down))
			Problems::quote_text(3, "a kind of value");
		else
			Problems::quote_kind_of(3, p->down);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ExistingVarNotFound));
		Problems::issue_problem_segment(
			"In the sentence %1, I was expecting that '%2' would be the "
			"name of a temporary value, but it turned out to be %3.");
		Problems::issue_problem_end();
	}
	return NEVER_MATCH;

@<Issue problem for being the wrong rvalue@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p->down));
	Problems::quote_spec(3, p->down);
	Problems::quote_spec(4, val);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotExactValueWanted));
	Problems::issue_problem_segment(
		"In the sentence %1, I was expecting that '%2' would be the specific "
		"value '%4'.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue problem for not being a phrase@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p->down));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(...));
	Problems::issue_problem_segment(
		"In the sentence %1, I was expecting that '%2' would be a phrase.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@h New variables.
The following doesn't switch context and recurse down: there's nothing
to recurse down to, since all we have is a name for a new variable. Instead
we deal with that right away.

It might seem rather odd that the typechecker should be the part of Inform
which creates local variables. Surely that's a sign that the parsing went
wrong, so how did things get to this stage?

In a C-like language, where variables are predeclared, that would be true.
But in Inform, a phrase like:

>> let the monster be a random pterodactyl;

can be valid even where "the monster" is text not known to the S-parser
as yet -- indeed, that's how local variables are made. It's the typechecker
which sorts this out, because only the typechecker can decide which of the
subtly different forms of "let" is being used.

@<Deal with a new local variable name@> =
	kind *K = Node::get_kind_required_by_context(p);
	parse_node *check = p->down;
	if (Node::is(check, AMBIGUITY_NT)) check = check->down;
	if (LocalVariables::permit_as_new_local(check, FALSE)) {
		if (kind_of_var_to_create) *kind_of_var_to_create = K;
		return ALWAYS_MATCH;
	}
	@<Issue a problem for an inappropriate variable name@>;
	return NEVER_MATCH;

@ This problem message is never normally seen using the definitions in the
Standard Rules because the definitions made there are such that other
problems appear first. So the only way to see this message is to declare an
unambiguous phrase with one of its tokens requiring a variable of a
species; and then to misuse that phrase.

@<Issue a problem for an inappropriate variable name@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	if (Specifications::is_kind_like(p->down))
		Problems::quote_text(3, "a kind of value");
	else
		Problems::quote_kind_of(3, p->down);
	Problems::quote_kind(4, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindOfVariable));
	Problems::issue_problem_segment(
		"In the sentence %1, I was expecting that '%2' would be a new "
		"variable name (to hold %4), but it turned out to be %3.");
	Problems::issue_problem_end();

@h (4) Typechecking within current context.
Everything else, then, passes through here, with the context now set either
to |NULL| (meaning no expectations) or to some ancestor of |p| in the parse
tree.

Level 4 forks rapidly into three branches: (4A), for ambiguous readings;
(4I), for single invocations; and (4S), for single readings other than
invocations. Here's the code which does the switching:

@<Typecheck within current context@> =
	kind *kind_needed = NULL;
	int condition_context = FALSE;
	if (context) {
		kind_needed = Node::get_kind_required_by_context(context);
		if ((Node::is(context, CONDITION_CONTEXT_NT)) ||
			(Node::is(context, LOGICAL_AND_NT)) ||
			(Node::is(context, LOGICAL_OR_NT)) ||
			(Node::is(context, LOGICAL_NOT_NT)) ||
			(Node::is(context, LOGICAL_TENSE_NT)))
			condition_context = TRUE;
	}
	LOG_DASH("(4)");

	int outcome = ALWAYS_MATCH;
	if ((consider_alternatives) && (p->next_alternative))
		@<Resolve an ambiguous reading@>
	else
		@<Verify an unambiguous reading@>;
	return outcome;

@ For a phrase node, we pass the buck down to its invocation list. For an
invocation list, we pass the buck down to its invocation (which may or
may not be the first in a chain of alternatives), which means we end up
in (4I) either directly or via (4A). For everything else, it's (4S) for us.

@<Verify an unambiguous reading@> =
	switch (p->node_type) {
		case PHRASE_TO_DECIDE_VALUE_NT:
			outcome = Dash::typecheck_recursive(p->down, context, TRUE);
			break;

		case INVOCATION_LIST_NT: case INVOCATION_LIST_SAY_NT: case AMBIGUITY_NT:
			if (p->down == NULL) @<Unknown found text occurs as a command@>;
			BEGIN_DASH_MODE;
			Dash_ambiguity_list = p;
			outcome = Dash::typecheck_recursive(p->down, context, TRUE);
			END_DASH_MODE;
			break;

		case INVOCATION_NT: @<Step (4I) Verify an invocation@>; break;

		default: @<Step (4S) Verify anything else@>; break;
	}

@ (4A) Ambiguities.
Ambiguities presently consist of chains of invocation nodes listed in
the tree as alternatives.

@<Resolve an ambiguous reading@> =
	LOG_DASH("(4A)");
	parse_node *list_of_possible_readings[MAX_INVOCATIONS_PER_PHRASE];
	int no_of_possible_readings = 0;
	int no_of_passed_readings = 0;

	@<Step (4A.a) Set up the list of readings to test@>;
	@<Step (4A.b) Recurse Dash to try each reading in turn@>;
	if (Dash::problems_have_been_issued()) return NEVER_MATCH;
	if (no_of_passed_readings > 0) @<Step (4A.c) Preserve successful readings@>
	else @<Step (4A.d) Give up with no readings possible@>;
	LOGIF(MATCHING, "Ambiguity resolved to: $E", p);

@ Phrase definitions are kept in a linked list with a total ordering which
properly contains the partial ordering in which $P_1\leq P_2$ if they are
lexically identical and if each parameter of $P_1$ provably, at compile time,
also satisfies the requirements for the corresponding parameter of $P_2$.
They have already been lexically parsed in that order, so the list of
invocations (which will have accumulated during parsing) is also in that
same order. Now this is nearly the correct order for type-checking. But we
make one last adjustment: the phrase being compiled is moved to the back of
the list. This is to make recursion always the last thing checked, so that
later rules can override earlier ones but still make use of them.

@<Step (4A.a) Set up the list of readings to test@> =
	LOG_DASH("(4A.a)");
	parse_node *alt;
	LOOP_THROUGH_ALTERNATIVES(alt, p)
		if ((Node::is(alt, INVOCATION_NT)) &&
			(Node::get_phrase_invoked(alt) != Functions::defn_being_compiled()))
			@<Add this reading to the list of test cases@>;
	LOOP_THROUGH_ALTERNATIVES(alt, p)
		if (!((Node::is(alt, INVOCATION_NT)) &&
			(Node::get_phrase_invoked(alt) != Functions::defn_being_compiled())))
			@<Add this reading to the list of test cases@>;
	LOGIF(MATCHING, "Resolving %d possible readings:\n", no_of_possible_readings);
	for (int i=0; i<no_of_possible_readings; i++)
		LOGIF(MATCHING, "Possibility (P%d) $e\n", i, list_of_possible_readings[i]);

@ In general, it's not great for typecheckers in compilers to put an upper bound
on complexity, because although human-written code seldom hits such maxima, there's
always the possibility of mechanically-generated code which does. On the other hand,
the result of that doctrine is that a lot of modern compilers (Swift, for example)
slow to a painful crawl and allocate gigabytes of memory trying to understand
strange type constraints in two or three lines of code. So, for now at least,
let's be pragmatic.

@<Add this reading to the list of test cases@> =
	if (no_of_possible_readings >= MAX_INVOCATIONS_PER_PHRASE) {
		THIS_IS_AN_ORDINARY_PROBLEM;
		Problems::quote_wording(1, Node::get_text(p));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AmbiguitiesTooDeep));
		Problems::issue_problem_segment(
			"The phrase %1 is too complicated for me to disentangle without "
			"running very, very slowly as I check many ambiguities in it. There "
			"ought to be some way to simplify things for me?");
		Problems::issue_problem_end();
		return NEVER_MATCH;
	}
	list_of_possible_readings[no_of_possible_readings++] = alt;
	Dash::clear_flags(alt);

@ Now we work through the list of tests. We must produce at least one reading
passing at least at the "sometimes" level marked by the |UNPROVEN_DASHFLAG|, or
else the whole specification fails its match. The first proven match stops our
work, since we can never need lower-priority interpretations.

@<Step (4A.b) Recurse Dash to try each reading in turn@> =
	LOG_DASH("(4A.b)");
	for (int ref = 0; ref<no_of_possible_readings; ref++) {
		parse_node *inv = list_of_possible_readings[ref];

		@<Test the current reading and set its results flags accordingly@>;
		LOGIF(MATCHING, "(P%d) %s: $e\n", ref, Dash::verdict_to_text(inv), inv);

		if (Dash::test_flag(inv, PASSED_DASHFLAG)) {
			no_of_passed_readings++;
			if (Dash::test_flag(inv, UNPROVEN_DASHFLAG) == FALSE) break;
		}
		if (Dash::problems_have_been_issued()) break; /* to prevent duplication of problem messages */
	}
	LOGIF(MATCHING, "List %s: ", (no_of_passed_readings > 0)?"passed":"failed");
	for (int i=0; i<no_of_possible_readings; i++) {
		parse_node *inv = list_of_possible_readings[i];
		LOGIF(MATCHING, "%s ", Dash::quick_verdict_to_text(inv));
	}
	LOGIF(MATCHING, "|\n");

@ We tell Dash to run silently unless grosser-than-gross problems arise, and
also tell it to check the reading with no alternatives considered. (If we
let it consider alternatives, that would be circular: we'd end up here
again, and so on forever.)

@<Test the current reading and set its results flags accordingly@> =
	LOGIF(MATCHING, "(P%d) Trying <%W>: $e\n", ref, Node::get_text(inv), inv);

	BEGIN_DASH_MODE;
	DASH_MODE_EXIT(ISSUE_PROBLEMS_DMODE);
	int rv = Dash::typecheck_recursive(inv, context, FALSE);
	END_DASH_MODE;

	Dash::set_flag(inv, TESTED_DASHFLAG);
	if (rv != NEVER_MATCH) {
		Dash::set_flag(inv, PASSED_DASHFLAG);
		outcome = Dash::worst_case(outcome, rv);
	}

@ This is the happy ending, in which the list can probably be passed, though
there are still a handful of pitfalls.

@<Step (4A.c) Preserve successful readings@> =
	LOG_DASH("(4A.c)");
	@<Step (4A.c.1) Winnow the reading list down to the survivors@>;
	@<Step (4A.c.2) Infer the kind of any requested local variable@>;

@ To recap, after checking through the possible readings we have something
like this as the result:
= (text)
	f ? f g ? ? p - - -
=
We can now throw away the |f|, |g| and |-| readings -- failed, grossly failed,
or never reached -- to leave just those which will be compiled:
= (text)
	? ? ? p
=
If compiled this will result in run-time code to check if the arguments
allow the first invocation and run it if so; then the second; then the third;
and, if those three fell through, run the fourth invocation without further
checking.

@<Step (4A.c.1) Winnow the reading list down to the survivors@> =
	LOG_DASH("(4A.c.1)");
	int invocational = TRUE;
	if (Node::is(Dash_ambiguity_list, AMBIGUITY_NT)) invocational = FALSE;

	LOGIF(MATCHING, "Winnow %s from $T\n",
		(invocational)?"invocationally":"regularly", Dash_ambiguity_list);

	if (invocational) {
		int dubious = FALSE;
		for (int ref = 0; ref<no_of_possible_readings; ref++) {
			parse_node *inv = list_of_possible_readings[ref];
			if (Node::is(inv, INVOCATION_NT) == FALSE)
				dubious = TRUE;
		}
		if (dubious) @<Issue the dubious ambiguity problem message@>;
	}

	if (invocational) Dash_ambiguity_list->down = NULL;

	parse_node *last_survivor = NULL;
	for (int ref = 0; ref<no_of_possible_readings; ref++) {
		parse_node *inv = list_of_possible_readings[ref];
		inv->next_alternative = NULL;
		if (Dash::test_flag(inv, PASSED_DASHFLAG)) {
			if (invocational) {
				if (last_survivor) last_survivor->next_alternative = inv;
				else Dash_ambiguity_list->down = inv;
				last_survivor = inv;
			} else {
				parse_node *link = Dash_ambiguity_list->next;
				Node::copy(Dash_ambiguity_list, inv);
				Dash_ambiguity_list->next = link;
				Dash_ambiguity_list->next_alternative = NULL;
				break;
			}
		}
	}

	if (invocational) {
		p = Dash_ambiguity_list->down;
		int nfi = -1, number_ambiguity = FALSE;
		parse_node *inv;
		LOOP_THROUGH_ALTERNATIVES(inv, p)
			if (Node::is(inv, INVOCATION_NT)) {
				int nti = Invocations::get_no_tokens(inv);
				if (nfi == -1) nfi = nti;
				else if (nfi != nti) number_ambiguity = TRUE;
			}

		if (number_ambiguity) @<Issue the number ambiguity problem message@>;
	}
	LOGIF(MATCHING, "After winnowing, CS is $T\n", current_sentence);

@ This is a last-throw-of-the-dice problem message, designed to pick up just
a few really awkward ambiguities which have been missed elsewhere in the parser
or in Dash.

@<Issue the dubious ambiguity problem message@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_number(2, &no_of_possible_readings);
	Problems::quote_wording(3, Node::get_text(list_of_possible_readings[0]));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DubiousAmbiguity));
	Problems::issue_problem_segment(
		"The phrase %1 is ambiguous in a way that I can't sort out. "
		"I can see %2 different meanings of '%3', and no good way to choose.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@ This is another sort of error which couldn't happen with a conventional
programming language -- in C, for instance, it's syntactically obvious
how many arguments a function call has, because the brackets and commas
are unambiguous. But in Inform, there are no reserved tokens of syntax
acting like that. So we could easily have two accepted invocations in the
list which have different numbers of arguments to each other, and there's
no way safely to adjudicate that at run-time.

@<Issue the number ambiguity problem message@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnequalValueAmbiguity));
	Problems::issue_problem_segment(
		"The phrase %1 is ambiguous in a way that I can't disentangle. "
		"It has more than one plausible interpretation, such that it "
		"would only be possible to tell which is valid at run-time: "
		"ordinarily that would be fine, but because the different "
		"interpretations are so different (and involve different "
		"numbers of values being used) there's no good way to cope. "
		"Try rewording one of the phrases which caused this clash: "
		"there's a good chance the problem will then go away.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@ If an invocation passes, and asks to create a local variable, we need
to mark the tree accordingly. If there's just one invocation then (4I)
handles this, but if there's ambiguity, we handle it here, and only
for the surviving nodes.

@<Step (4A.c.2) Infer the kind of any requested local variable@> =
	LOG_DASH("(4A.c.2)");
	parse_node *inv;
	LOOP_THROUGH_ALTERNATIVES(inv, p)
		if (Node::is(inv, INVOCATION_NT))
			if (Dash::set_up_any_local_required(inv) == NEVER_MATCH)
				return NEVER_MATCH;

@ And this is the unhappy ending:

@<Step (4A.d) Give up with no readings possible@> =
	LOG_DASH("(4A.d)");
	THIS_IS_AN_ORDINARY_PROBLEM;
	if (InvocationLists::length(p) == 0) return NEVER_MATCH;

	LOGIF(MATCHING, "All possibilities failed: issuing problem\n");
	return Dash::failed(list_of_possible_readings, no_of_possible_readings,
		context, kind_needed);

@ (4I) Invocations.
Invocations are the hardest nodes to check, but here at least we can forget
all about the ambiguities arising from multiple possibilities, and look at
just a single one.

In the event of an interesting problem message, we mark an invocation as being
interestingly problematic, but we keep going, since other invocations might be
better. Only if everything fails will we retrace our steps and actually throw
the problem.

@<Step (4I) Verify an invocation@> =
	LOG_DASH("(4I)");
	int no_gross_problems_thrown_before = no_gross_problems_thrown;
	int no_interesting_problems_thrown_before = no_interesting_problems_thrown;
	int qualified = FALSE;
	parse_node *inv = p;
	ParseInvocations::parse_within_inv(inv);
	Dash::set_flag(inv, TESTED_DASHFLAG);
	id_body *idb = Node::get_phrase_invoked(inv);
	if (idb) {
		Node::set_kind_resulting(inv, IDTypeData::get_return_kind(&(idb->type_data)));

		/* are the arguments of the right kind? */
		if (outcome != NEVER_MATCH) @<Step (4I.a) Take care of arithmetic phrases@>;
		if (outcome != NEVER_MATCH) @<Step (4I.b) Take care of non-arithmetic phrases@>;
		if (outcome != NEVER_MATCH) @<Step (4I.c) Match type templates in the argument specifications@>;
		if (outcome != NEVER_MATCH) @<Step (4I.d) Match kinds in assignment phrases@>;

		/* if this evaluates something, is it a value of the right kind? */
		if (outcome != NEVER_MATCH) @<Step (4I.e) Check kind of value returned@>;

		/* are there any special rules about invoking this phrase? */
		if (outcome != NEVER_MATCH) @<Step (4I.f) Check any phrase options@>;
		if (outcome != NEVER_MATCH) @<Step (4I.g) Worry about self in say property of@>;
		if (outcome != NEVER_MATCH) @<Step (4I.h) Worry about using a phrase outside of the control structure it belongs to@>;
		if (outcome != NEVER_MATCH) @<Step (4I.i) Disallow any phrases which are now deprecated@>;

		/* should we mark to create a let variable here? */
		if ((outcome != NEVER_MATCH) && (consider_alternatives))
			outcome = Dash::worst_case(outcome, Dash::set_up_any_local_required(inv));
	}

	/* the outcome is now definitely known */
	if (outcome == NEVER_MATCH) @<Step (4I.j) Cope with failure@>
	else @<Step (4I.k) Cope with success@>;

@ Most problem messages issued by (4I) will be of a sort called "interesting",
and will use the following macro.

@d THIS_IS_AN_INTERESTING_PROBLEM
	outcome = NEVER_MATCH;
	no_interesting_problems_thrown++;
	if (TEST_DASH_MODE(ISSUE_INTERESTING_PROBLEMS_DMODE))

@ "Polymorphic" here means that the phrase (i) produces a value, and (ii) that
the kind of this value depends on the kinds of its arguments. Inform supports
only a few polymorphic phrases, all clearly declared as such in the Standard
Rules, and they come in two sorts: those marked with a "polymorphism exception",
and those marked as "arithmetic operations".

@<Step (4I.a) Take care of arithmetic phrases@> =
	LOG_DASH("(4I.a)");
	if (IDTypeData::arithmetic_operation(idb) == TOTAL_OPERATION)
		@<Step (4I.a.1) "Total P of O" has kind the kind of P@>
	else if (IDTypeData::is_arithmetic_phrase(idb)) @<Step (4I.a.2) Dimension-check arithmetic phrases@>;

@ For instance, the kind of "total carrying capacity of people in the Dining
Room" is a number, because the kind of the property "carrying capacity" is
"number".

@<Step (4I.a.1) "Total P of O" has kind the kind of P@> =
	LOG_DASH("(4I.a.1)");
	parse_node *P = Invocations::get_token_as_parsed(inv, 0);
	int rv = Dash::typecheck_recursive(P, NULL, TRUE);
	if ((rv != NEVER_MATCH) && (Rvalues::is_CONSTANT_construction(P, CON_property))) {
		property *prn = Rvalues::to_property(P);
		if (Properties::is_value_property(prn))
			Node::set_kind_resulting(inv, ValueProperties::kind(prn));
		else {
			THIS_IS_AN_INTERESTING_PROBLEM {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TotalEitherOr),
					"this seems to be an attempt to total up an either/or property",
					"and by definition such a property has nothing to total.");
			}
		}
	} else @<Fail the invocation for totalling something other than a property@>;

@ The problem message here is to help what turns out to be quite a popular
mistake. (Perhaps we should simply implement column-totalling and be done
with it.)

@<Fail the invocation for totalling something other than a property@> =
	LOG_DASH("(4I.a.1) failed as nonproperty");
	if (Kinds::get_construct(Node::get_kind_of_value(P)) == CON_table_column) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TotalTableColumn),
				"this seems to be an attempt to total up the column of a table",
				"whereas it's only legal to use 'total' for properties.");
		}
	}
	outcome = NEVER_MATCH;

@ For instance, the following blocks an attempt to add a number to a text.

@<Step (4I.a.2) Dimension-check arithmetic phrases@> =
	LOG_DASH("(4I.a.2)");
	int op_number = IDTypeData::arithmetic_operation(idb);
	LOGIF(MATCHING, "Arithmetic operation <op-%d>\n", op_number);

	parse_node *L, *R;
	kind *kind_wanted, *left_kind, *right_kind, *kind_produced;
	@<Work out the kinds of the operands, and what we want, and what we get@>;
	LOGIF(MATCHING, "%u (~) %u = %u\n", left_kind, right_kind, kind_produced);

	if (kind_produced) Node::set_kind_resulting(inv, kind_produced);
	else @<Fail the invocation for a dimensional problem@>;

@ For the way this is actually worked out, see the section on "Dimensions".

@<Work out the kinds of the operands, and what we want, and what we get@> =
	L = Invocations::get_token(inv, 0);
	left_kind = Dash::fix_arithmetic_operand(L);
	if (Kinds::Dimensions::arithmetic_op_is_unary(op_number)) {
		R = NULL; right_kind = NULL;
	} else {
		R = Invocations::get_token(inv, 1);
		right_kind = Dash::fix_arithmetic_operand(R);
	}
	if (((left_kind) && (Kinds::Behaviour::is_quasinumerical(left_kind) == FALSE)) ||
		((right_kind) && (Kinds::Behaviour::is_quasinumerical(right_kind) == FALSE)))
		kind_produced = NULL;
	else
		kind_produced = Kinds::Dimensions::arithmetic_on_kinds(left_kind, right_kind, op_number);
	kind_wanted = kind_needed;

@ Note that "value" -- the vaguest kind of all -- might come up here as
a result of some problem evaluating one of the operands, which has already been
reported in a problem message; so we only issue this problem message when
L and R are more definite.

@<Fail the invocation for a dimensional problem@> =
	if ((left_kind) && (Kinds::eq(left_kind, K_value) == FALSE) &&
		(right_kind) && (Kinds::eq(right_kind, K_value) == FALSE)) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			LOG("So the inv subtree is:\n$T\n", inv);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(L));
			Problems::quote_wording(3, Node::get_text(R));
			Problems::quote_kind(4, left_kind);
			Problems::quote_kind(5, right_kind);
			switch(op_number) {
				case PLUS_OPERATION: Problems::quote_text(6, "adding"); Problems::quote_text(7, "to"); break;
				case MINUS_OPERATION: Problems::quote_text(6, "subtracting"); Problems::quote_text(7, "from"); break;
				case TIMES_OPERATION: Problems::quote_text(6, "multiplying"); Problems::quote_text(7, "by"); break;
				case DIVIDE_OPERATION:
				case REMAINDER_OPERATION: Problems::quote_text(6, "dividing"); Problems::quote_text(7, "by"); break;
				case APPROXIMATE_OPERATION: Problems::quote_text(6, "rounding"); Problems::quote_text(7, "to"); break;
			}
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadArithmetic));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to involve %6 %4 ('%2') %7 %5 ('%3'), "
				"which is not good arithmetic.");
			Problems::issue_problem_end();
		}
	}
	outcome = NEVER_MATCH;

@ This is the general case: almost all phrases fall into this category,
including all phrases created outside the Standard Rules.

The deal is simply that every argument must match its specification. For
instance, if |inv| is an invocation of this phrase:

>> To truncate (L - a list of values) to (N - a number) entries: ...

...then token 0 must match "list of values", and token 1 must match "number".

@<Step (4I.b) Take care of non-arithmetic phrases@> =
	if (IDTypeData::is_arithmetic_phrase(idb) == FALSE) {
		LOG_DASH("(4I.b)");
		int i, exit_at_once = FALSE;
		for (i=0; i<Invocations::get_no_tokens(inv); i++) {
			LOGIF(MATCHING, "(4I.b) trying argument %d (prior to this, best possible: %d)\n",
				i, outcome);
			Invocations::set_token_check_to_do(inv, i, NULL);
			@<Type-check a single token from the list@>;
			if (exit_at_once) break;
		}
		LOGIF(MATCHING, "(4I.b) argument type matching %s\n",
			(outcome==NEVER_MATCH)?"failed":"passed");
	}

@<Type-check a single token from the list@> =
	parse_node *ith_spec = idb->type_data.token_sequence[i].to_match;
	if ((idb->type_data.token_sequence[i].construct == KIND_NAME_IDTC) && (outcome != NEVER_MATCH))
		@<Cautiously reparse this as a name of a kind of value@>
	else {
		int save_kcm = kind_checker_mode;
		kind_checker_mode = MATCH_KIND_VARIABLES_AS_UNIVERSAL;
		kind *create = NULL;
		BEGIN_DASH_MODE;
		DASH_MODE_EXIT(ISSUE_PROBLEMS_DMODE);
		DASH_MODE_CREATE(&create);
		int rv = Dash::typecheck_recursive(Invocations::get_token(inv, i), context, TRUE);
		END_DASH_MODE;
		switch(rv) {
			case NEVER_MATCH:
				LOGIF(MATCHING, "(4I.b) on %W failed at token %d\n", Node::get_text(p), i);
				outcome = NEVER_MATCH;
				if (Dash::problems_have_been_issued()) exit_at_once = TRUE;
				break;
			case SOMETIMES_MATCH:
				LOGIF(MATCHING, "(4I.b) on %W qualified at token %d\n", Node::get_text(p), i);
				Invocations::set_token_check_to_do(inv, i, ith_spec);
				qualified = TRUE;
				break;
		}
		kind_checker_mode = save_kcm;
		if (create) {
			if ((CompileBlocksAndLines::compiling_single_line_block()) &&
				(IDTypeData::is_a_let_assignment(idb))) {
				THIS_IS_AN_INTERESTING_PROBLEM {
					Problems::quote_source(1, current_sentence);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LetCreatedInIf));
					Problems::issue_problem_segment(
						"You wrote %1, but when a temporary value is created "
						"inside an 'if ..., ...' or an 'otherwise ...', it only "
						"lasts until that line is complete - which means it "
						"can never be used for anything, because it goes away "
						"as soon as created. To make something more durable, "
						"create it before the 'if' or 'otherwise'.");
					Problems::issue_problem_end();
				}
			}
			Invocations::set_token_variable_kind(inv, i, create);
		}
	}

@ The following is a delicate manoeuvre, but luckily it takes action only very
rarely and in very specific circumstances. We allow a very limited use
of second-order logic in using the name of a kind as if it were a value,
even though Inform is really not set up for this. The point is to allow:

>> let (name - nonexisting variable) be (K - name of kind of word value);

where the "K" parameter would match (1) but not (2), (3) or (4) from:

>> (1) let X be a number;
>> (2) let X be text;
>> (3) let X be 21;
>> (4) let X be \{1, 2, 3\};

What all of this has to do with being |UNKNOWN_NT| is that text parsed in the
expectation of a value will usually not recognise something like "a list
of numbers", so that would be here as |UNKNOWN_NT|. We take the otherwise
unheard-of measure of reparsing the text, but we only impose the result
if the match can definitely be made successfully.

We have to be very careful to take action only on (5) and not (6):

>> (5) let L be a list of scenes;
>> (6) let L be the list of scenes;

(5) creates L as an empty list, whereas (6) creates it as the list made up
of all scenes. We can tell these apart since (6) will have a valid phrase
in |ith_token|, an invocation of "the list of K", whereas (5) won't.

@<Cautiously reparse this as a name of a kind of value@> =
	outcome = NEVER_MATCH;
	parse_node *ith_token = Invocations::get_token_as_parsed(inv, i);
	LOGIF(MATCHING, "(4I.b) thinking about reparsing: $P\n", ith_token);
	int warned_already = FALSE;
	if (Node::is(ith_token, AMBIGUITY_NT)) ith_token = ith_token->down;
	if ((Node::is(ith_token, UNKNOWN_NT)) ||
		(Specifications::is_description(ith_token)) ||
		(Rvalues::is_CONSTANT_construction(ith_token, CON_property)) ||
		(Specifications::is_kind_like(ith_token)) ||
		((IDTypeData::is_a_let_assignment(idb) == FALSE) &&
			(Node::is(ith_token, PHRASE_TO_DECIDE_VALUE_NT)))) {
		wording W = Node::get_text(ith_token);

		kind *K = NULL;
		parse_node *reparsed = NULL;
		if (<s-type-expression>(W)) reparsed = <<rp>>;
		if (Specifications::is_kind_like(reparsed))
			K = Specifications::to_kind(reparsed);
		if ((K == NULL) && (<k-kind>(W))) K = <<rp>>;
		if (K == NULL) {
			if ((<value-property-name>(W)) &&
				(ValueProperties::coincides_with_kind(<<rp>>)))
				K = ValueProperties::kind(<<rp>>);
		}

		LOGIF(MATCHING, "(4I.b) reparsed as: %u (vs spec $P)\n", K, ith_spec);
		if ((K) && (Specifications::is_kind_like(ith_spec))) {
			kind *ikind = Specifications::to_kind(ith_spec);
			if (Kinds::Behaviour::definite(K)) {
				if (Kinds::compatible(K, ikind) == ALWAYS_MATCH) {
					LOGIF(MATCHING, "(4I.b) allows name-of token: $P\n", reparsed);
					Invocations::set_token_as_parsed(inv, i, Node::duplicate(reparsed));
					outcome = ALWAYS_MATCH;
				} else {
					THIS_IS_AN_ORDINARY_PROBLEM {
						warned_already = TRUE;
						Problems::quote_source(1, current_sentence);
						Problems::quote_wording(2, W);
						Problems::quote_kind(3, ikind);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NameOfKindMismatch));
						Problems::issue_problem_segment(
							"You wrote %1, but although '%2' is the name of a kind, "
							"it isn't the name of a kind of %3, which this phrase needs.");
						Problems::issue_problem_end();
					}
				}
			} else {
				THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM {
					warned_already = TRUE;
					Problems::quote_source(1, current_sentence);
					Problems::quote_wording(2, W);
					Problems::quote_kind(3, ikind);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadLocalKOV));
					Problems::issue_problem_segment(
						"You wrote %1, but although '%2' is the name of a kind, "
						"it isn't a definite kind and is instead a general "
						"description which might apply to many different kinds. "
						"(For example, 'let R be a relation' is vague because it doesn't "
						"make clear what R will relate - 'let R be a relation of numbers' "
						"would be fine.)");
					Problems::issue_problem_end();
				}
			}
		}
	}
	ith_token = Invocations::get_token_as_parsed(inv, i);
	if ((!Specifications::is_kind_like(ith_token)) && (warned_already == FALSE)) {
		THIS_IS_AN_ORDINARY_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(ith_token));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NameOfKindIsnt));
			Problems::issue_problem_segment(
				"You wrote %1, but although '%2' does have a meaning, "
				"it isn't the name of a kind, which this phrase needs.");
			Problems::issue_problem_end();
		}
	}

@ For templates and the meaning of |kind_checker_mode|, see the section
on "Kind Checking". But basically this handles the matching of an invocation
against a definition like:

>> To remove (N - value of kind K) from (L - list of Ks): ...

@<Step (4I.c) Match type templates in the argument specifications@> =
	LOG_DASH("(4I.c)");
	int exit_at_once = FALSE;

	kind_variable_declaration *kvd_marker = LAST_OBJECT(kind_variable_declaration);

	if (IDTypeData::contains_variables(&(idb->type_data))) {
		kind_variable_declaration *save_most_recent_interpretation = most_recent_interpretation;
		int pass, save_kcm = kind_checker_mode;
		for (pass = 1; pass <= 2; pass++) {
			LOGIF(MATCHING, "(4I.c) prototype check pass %d\n", pass);
			if (Log::aspect_switched_on(MATCHING_DA)) Latticework::show_variables();
			if (pass == 1) kind_checker_mode = MATCH_KIND_VARIABLES_INFERRING_VALUES;
			else kind_checker_mode = MATCH_KIND_VARIABLES_AS_VALUES;
			int i;
			for (i=0; i<Invocations::get_no_tokens(inv); i++) {
				kind *Kt = IDTypeData::token_kind(&(idb->type_data), i);
				if ((Kt) &&
					(idb->type_data.token_sequence[i].construct != NEW_LOCAL_IDTC)) {
					parse_node *token_spec = Invocations::get_token_as_parsed(inv, i);
					kind *kind_read = Specifications::to_kind(token_spec);
					LOGIF(MATCHING, "Token %d: $P: kind %u: template %u\n", i,
						token_spec, kind_read, Kt);
					switch(Kinds::compatible(kind_read, Kt)) {
						case NEVER_MATCH:
							LOGIF(MATCHING, "(4I.c) failed at token %d\n", i);
							outcome = NEVER_MATCH;
							if (Dash::problems_have_been_issued()) exit_at_once = TRUE;
							break;
						case SOMETIMES_MATCH:
							outcome = Dash::worst_case(outcome, SOMETIMES_MATCH);
							/* we won't use |with_qualifications| -- we don't know exactly what they are */
							LOGIF(MATCHING, "(4I.c) dropping to sometimes at token %d\n", i);
							break;
						case ALWAYS_MATCH:
							break;
					}
				}
				if (exit_at_once) break;
			}
			if (exit_at_once) break;
			if ((pass == 1) && (outcome != NEVER_MATCH)) {
				LOGIF(MATCHING, "(4I.c) prototype check passed\n");
				most_recent_interpretation = NULL;
				kind_variable_declaration *kvdm = kvd_marker;
				if (kvdm) kvdm = NEXT_OBJECT(kvdm, kind_variable_declaration);
				else kvdm = FIRST_OBJECT(kind_variable_declaration);
				while (kvdm) {
					kvdm->next = most_recent_interpretation;
					most_recent_interpretation = kvdm;
					kvdm = NEXT_OBJECT(kvdm, kind_variable_declaration);
				}
			}
		}
		kind_checker_mode = save_kcm;
		if (outcome != NEVER_MATCH) Node::set_kind_variable_declarations(inv, most_recent_interpretation);
		most_recent_interpretation = save_most_recent_interpretation;
	}

	if (Kinds::contains(Node::get_kind_resulting(inv), CON_KIND_VARIABLE)) {
		int changed = FALSE;
		kind *K = Kinds::substitute(Node::get_kind_resulting(inv), NULL, &changed, FALSE);
		if (changed) {
			LOGIF(MATCHING, "(4I.c) amended kind returned to %u\n", K);
			Node::set_kind_resulting(inv, K);
		} else @<Disallow an undeclared kind variable as return kind@>;
	}

@<Disallow an undeclared kind variable as return kind@> =
	THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"In the line %1, you seem to be using '%2' to produce a value, but "
		"it's not clear what kind of value this will be. It seems to use "
		"a phrase which has been declared wrongly, because the kind it decides "
		"is given only by a symbol which isn't otherwise defined.");
	Problems::issue_problem_end();
	outcome = NEVER_MATCH;

@ Although we don't implement it with prototypes as such, there's a
similar constraint on the arguments of an assignment. If we are checking an
invocation against:

>> To let (t - existing variable) be (u - value): ...

then we have so far checked that argument 0 is indeed the name of a variable
which already exists. But suppose the invocation is

>> let N be "there'll be no mutant enemy";

where N has already been created as a variable of kind "number". This clearly
has to be rejected, as it would violate type-safety. Step (4I.d) therefore
makes sure that all assignments match the kind of the new value against the
kind of the storage item to which it is being written.

A reasonable question might be why we don't implement this using the prototype
system of (4I.c), thus removing a rule from this already-complex algorithm, say by

>> To let (var - K variable) be (val - value of kind K): ...

The answer is that this would indeed work nicely for valid source text, but that
we would get less helpful problem messages in the all-too-likely case of a
mistake having been made.

@<Step (4I.d) Match kinds in assignment phrases@> =
	LOG_DASH("(4I.d)");
	if (IDTypeData::is_assignment_phrase(idb)) {
		parse_node *target = Invocations::get_token_as_parsed(inv, 0);
		parse_node *new_value = Invocations::get_token_as_parsed(inv, 1);

		parse_node *target_spec = idb->type_data.token_sequence[0].to_match;
		parse_node *new_value_spec = idb->type_data.token_sequence[1].to_match;

		local_variable *lvar = Lvalues::get_local_variable_if_any(target);
		if ((lvar) && (LocalVariables::protected(lvar)))
			outcome = NEVER_MATCH;
		else {
			if (Kinds::Behaviour::is_object(Specifications::to_kind(target_spec)))
				@<Step (4I.d.1) Police an assignment to an object@>;

			if (idb->type_data.token_sequence[0].construct != NEW_LOCAL_IDTC)
				@<Step (4I.d.2) Police an assignment to a storage item@>;
		}
	}

@ It doesn't always look like an assignment, but a phrase such as:

>> change the Marble Door to open;

has similar type-checking needs.

@<Step (4I.d.1) Police an assignment to an object@> =
	LOG_DASH("(4I.d.1)");
	instance *target_wo = Rvalues::to_object_instance(target);
	property *prn = NULL;
	int make_check = FALSE;
	if (Kinds::eq(Node::get_kind_of_value(new_value_spec), K_value))
		@<Maybe we're changing an object to a value of a kind coinciding with a property@>;
	if (Rvalues::is_CONSTANT_construction(new_value_spec, CON_property))
		@<Maybe we're changing an object to a named either/or property or condition state@>;
	if (make_check)
		@<Check that the property exists and that the object is allowed to have it@>;

@ There are actually two definitions like this in the Standard Rules:

>> (1) To change (o - object) to (w - value): ...
>> (2) To change (o - object) to (p - property): ...

Here's the code for (1), the less obvious case. This is needed for something like

>> change the canvas to blue;

where "blue" is a constant colour, and "colour" is both a kind and also a
property. (This case really is an assignment -- it assigns the value "blue"
to the colour property of the canvas.)

@<Maybe we're changing an object to a value of a kind coinciding with a property@> =
	LOG_DASH("(4I.d.1.a)");
	instance *I = Rvalues::to_instance(new_value);
	if (I == NULL) outcome = NEVER_MATCH;
	else {
		prn = Properties::property_with_same_name_as(Instances::to_kind(I));
		if (prn == NULL) outcome = NEVER_MATCH;
		else make_check = TRUE;
	}

@ And here's the simpler case, (2). A small quirk here is that it will also pick
up "change the Atrium to spiffy" in the following:

>> Atrium is a room. The Atrium can be spiffy, cool or lame.
>> When play begins: change the Atrium to spiffy.

...where "spiffy" is deemed a property rather than a constant value of a kind
because of the way the condition of the Atrium is declared. This is a little
bit horrid, but works fine in practice. (If we try to accommodate this case
within (1.2.4.1a), which might seem more logical, we run into trouble because
the property name is cast to a property value of |self| when being typechecked
against "value".)

@<Maybe we're changing an object to a named either/or property or condition state@> =
	LOG_DASH("(4I.d.1.b)");
	if (Rvalues::is_CONSTANT_construction(new_value, CON_property))
		prn = Rvalues::to_property(new_value);
	else if (Descriptions::number_of_adjectives_applied_to(new_value) == 1) {
		adjective *aph = AdjectivalPredicates::to_adjective(Descriptions::first_unary_predicate(new_value));
		if (AdjectiveAmbiguity::has_enumerative_meaning(aph))
			prn = Properties::property_with_same_name_as(Instances::to_kind(AdjectiveAmbiguity::has_enumerative_meaning(aph)));
		else if (AdjectiveAmbiguity::has_either_or_property_meaning(aph, NULL))
			prn = AdjectiveAmbiguity::has_either_or_property_meaning(aph, NULL);
	}
	make_check = TRUE;

@ We do something quite interesting here, if the object is not explicitly
named: we deliberately allow an assignment which may not be type-safe, and
without even dropping to the "sometimes" level. This is for phrases like so:

>> change the item to closed;

Here the author seems to know what he's doing, and is pretty sure that the
current contents of "item" will accept closure. All we can prove is that
"item" contains an object (or perhaps |nothing|, the non-object). But
we allow the assignment because it will compile to code which will issue
a helpful run-time problem message if it goes wrong.

Now that "change" has been removed, as of January 2011, it looks as if
this case in the type-checker is never exercised.

@<Check that the property exists and that the object is allowed to have it@> =
	LOGIF(MATCHING, "Property appears to be $Y\n", prn);
	if (prn == NULL) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(target));
			Problems::quote_wording(3, Node::get_text(new_value));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible)); /* the parser seems not to allow these */
			Problems::issue_problem_segment(
				"You wrote %1, asking to change the object '%2'. This would "
				"make sense if '%3' were an either/or property like 'open' "
				"(or perhaps a named property value like 'blue') - but it "
				"isn't, so the change makes no sense.");
			Problems::issue_problem_end();
		}
	}
	if ((target_wo) && (prn) &&
		(PropertyPermissions::find(Instances::as_subject(target_wo), prn, TRUE) == NULL)) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(target));
			Problems::quote_property(3, prn);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not allowed to have the property '%3'.");
			Problems::issue_problem_end();
		}
	}

@ This is more straightforward, with just a tiny glitch to make the rules
tougher on variables which hold text to be parsed. (Because the regular rules
for exchanging the subtly different forms of text which a double-quoted
literal can mean are too generous.)

@<Step (4I.d.2) Police an assignment to a storage item@> =
	kind *kind_wanted, *kind_found;
	LOGIF(MATCHING, "Check assignment of $P to $P\n", new_value, target);
	switch(Lvalues::get_storage_form(target_spec)) {
		case LOCAL_VARIABLE_NT: Problems::quote_text(6, "the name of"); break;
		case PROPERTY_VALUE_NT: Problems::quote_text(6, "a property whose kind of value is"); break;
		case NONLOCAL_VARIABLE_NT: Problems::quote_text(6, "a variable whose kind of value is"); break;
		case TABLE_ENTRY_NT: Problems::quote_text(6, "a table entry whose kind of value is"); break;
		case LIST_ENTRY_NT: Problems::quote_text(6, "an entry in a list whose kind of value is"); break;
		default: Problems::quote_text(6, "a stored value holding"); break;
	}
	kind_wanted = Specifications::to_kind(target);
	if (IDTypeData::is_assignment_phrase(idb))
		kind_wanted = Kinds::Dimensions::relative_kind(kind_wanted);
	kind_found = Specifications::to_kind(new_value);

	parse_node *new_invl = new_value->down;
	if (Node::is(new_invl, INVOCATION_LIST_NT)) {
		parse_node *new_inv;
		LOOP_THROUGH_ALTERNATIVES(new_inv, new_invl)
			if (Dash::test_flag(new_inv, PASSED_DASHFLAG)) break;
		if (new_inv) kind_found = Node::get_kind_resulting(new_inv);
	}
	LOGIF(MATCHING, "Kinds found: %u, wanted: %u\n", kind_found, kind_wanted);

	if (((K_understanding) && (Kinds::eq(kind_wanted, K_understanding)) &&
		(Kinds::eq(kind_found, K_understanding) == FALSE))
		|| (Kinds::compatible(kind_found, kind_wanted) == NEVER_MATCH)) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(target));
			Problems::quote_kind(3, Specifications::to_kind(target));
			Problems::quote_wording(4, Node::get_text(new_value));
			Problems::quote_kind(5, Specifications::to_kind(new_value));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ChangeToWrongValue));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is supposed to be "
				"%6 %3, so it cannot be set equal to %4, whose kind is %5.");
			Problems::issue_problem_end();
		}
	}

@ Suppose we have something like this:

>> award the current action points;

and we are typechecking |found| as "the current action" (a phrase deciding
a value) against |expected| as "number", the parameter expected in
"award (N - a number) points".

No matter how peculiar this invocation of |found| was, we have now successfully
worked out the kind of the value it would return if compiled, and this is
stored in |inv->kind_resulting|. We now check to see if this matches the kind
expected -- in this example, it won't, because a stored action does not cast
to a number.

@<Step (4I.e) Check kind of value returned@> =
	LOG_DASH("(4I.e)");
	int outcome_test = ALWAYS_MATCH;
	if (kind_needed) {
		LOGIF(MATCHING, "Checking returned %u against desired %u\n",
			Node::get_kind_resulting(inv), kind_needed);
		outcome_test = Kinds::compatible(
			Node::get_kind_resulting(inv), kind_needed);
	}
	switch (outcome_test) {
		case NEVER_MATCH: outcome = NEVER_MATCH; break;
		case SOMETIMES_MATCH: outcome = Dash::worst_case(outcome, SOMETIMES_MATCH); break;
	}

@ The final stage in type-checking a phrase is to ensure that any phrase
options are properly used.

@<Step (4I.f) Check any phrase options@> =
	LOG_DASH("(4I.f)");
	if ((outcome != NEVER_MATCH) && (Node::get_phrase_options_invoked(inv))) {
		int cso = PhraseOptions::parse_invoked_options(
			inv, (TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE))?FALSE:TRUE);
		if (cso == FALSE) outcome = NEVER_MATCH;
	}

@ A say phrase which involves a property of something implicitly changes
the scope for any vaguely described properties within the text supplied
as that property (if it is indeed text). We have to mark any such
property, and any such say. For instance, suppose we are typechecking

>> (1) "Oh, look: [initial appearance of the escritoire]"

and the initial appearance in question is:

>> (2) "A small, portable writing desk holding up to [carrying capacity] letters."

Printing text (2), it's important for the |self| object to be the
escritoire, which might not be the case otherwise; so during the printing
of (1), we have to change |self| temporarily and restore it afterwards.

@<Step (4I.g) Worry about self in say property of@> =
	LOG_DASH("(4I.g)");
	if ((IDTypeData::is_a_say_phrase(idb)) &&
		(Invocations::get_no_tokens(inv) == 1) &&
		(Lvalues::get_storage_form(Invocations::get_token_as_parsed(inv, 0)) == PROPERTY_VALUE_NT)) {
		Annotations::write_int(Invocations::get_token_as_parsed(inv, 0), record_as_self_ANNOT, TRUE);
		Invocations::mark_to_save_self(inv);
	}

@ Some phrases are defined with a notation making them allowable only inside
loops, or other control structures; for instance,

>> To break -- in loop: ...

And here is where we check that "break" is indeed used only in a loop.

@<Step (4I.h) Worry about using a phrase outside of the control structure it belongs to@> =
	LOG_DASH("(4I.h)");
	if (idb) {
		inchar32_t *required = IDTypeData::only_in(idb);
		if (required) {
			if (Wide::cmp(required, U"loop") == 0) {
				LOGIF(MATCHING, "Required to be inside loop body\n");
				if (CodeBlocks::inside_a_loop_body() == FALSE) {
					THIS_IS_AN_INTERESTING_PROBLEM {
						Problems::quote_source(1, current_sentence);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantUseOutsideLoop));
						Problems::issue_problem_segment(
							"%1 makes sense only inside a 'while' or 'repeat' loop.");
						Problems::issue_problem_end();
					}
				}
			} else {
				LOGIF(MATCHING, "Required to be inside block '%w'\n", required);
				inchar32_t *actual = CodeBlocks::name_of_current_block();
				if ((actual) && (Wide::cmp(actual, U"unless") == 0)) actual = U"if";
				if ((actual == NULL) || (Wide::cmp(required, actual) != 0)) {
					THIS_IS_AN_INTERESTING_PROBLEM {
						Problems::quote_source(1, current_sentence);
						Problems::quote_wide_text(2, required);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantUseOutsideStructure));
						Problems::issue_problem_segment(
							"%1 makes sense only inside a '%2' block.");
						Problems::issue_problem_end();
					}
				}
			}
		}
	}

@<Step (4I.i) Disallow any phrases which are now deprecated@> =
	if (global_compilation_settings.no_deprecated_features) {
		LOG_DASH("(4I.i)");
		if ((idb) && (idb->type_data.now_deprecated)) {
			THIS_IS_AN_INTERESTING_PROBLEM {
				Problems::quote_source(1, current_sentence);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible)); /* too moving a target to test */
				Problems::issue_problem_segment(
					"'%1' uses a phrase which is now deprecated: you should rephrase "
					"to avoid the need for it. I'd normally allow this, but you have "
					"the 'Use no deprecated features' option set.");
				Problems::issue_problem_end();
			}
		}
	}

@<Step (4I.j) Cope with failure@> =
	LOG_DASH("(4I.j) failure");
	if (no_gross_problems_thrown > no_gross_problems_thrown_before)
		Dash::set_flag(inv, GROSSLY_FAILED_DASHFLAG);
	else if (no_interesting_problems_thrown > no_interesting_problems_thrown_before)
		Dash::set_flag(inv, INTERESTINGLY_FAILED_DASHFLAG);
	if ((consider_alternatives) && (TEST_DASH_MODE(ISSUE_PROBLEMS_DMODE)))
		Dash::failed_one(inv, context, kind_needed);

@ Usage statistics are mainly interesting to the writers of Inform, to help us
to get some picture of how much phrases are used across a large corpus of
existing source text (e.g., the documentation examples, or the public
extensions).

@<Step (4I.k) Cope with success@> =
	LOG_DASH("(4I.k) success");
	Dash::set_flag(inv, PASSED_DASHFLAG);
	if (qualified) {
		Dash::set_flag(inv, UNPROVEN_DASHFLAG);
		Invocations::mark_unproven(inv);
	}
	if (idb) {
		wording NW = ToPhraseFamily::doc_ref(idb->head_of_defn);
		if (Wordings::nonempty(NW)) {
			TEMPORARY_TEXT(pds)
			WRITE_TO(pds, "%+W", Wordings::one_word(Wordings::first_wn(NW)));
			if (Log::aspect_switched_on(PHRASE_USAGE_DA)) {
				DocReferences::doc_mark_used(pds,
					Wordings::first_wn(Node::get_text(inv)));
			}
			DISCARD_TEXT(pds)
		}
	}

@h (4S) Verifying single non-invocation readings.
This is much easier, though that's because a lot of the work is delegated
to level 5.

@<Step (4S) Verify anything else@> =
	LOG_DASH("(4S.a)");
	LOG_INDENT;

	outcome = Dash::typecheck_single_node(p, kind_needed, condition_context);
	LOG_OUTDENT;
	@<Allow listed-in table references only where these are expected@>;

	LOG_DASH("(4S.b)");
	for (parse_node *arg = p->down; arg; arg = arg->next)
		outcome =
			Dash::worst_case(outcome,
				Dash::typecheck_recursive(arg, p, TRUE));
	if ((outcome != NEVER_MATCH) && (p->down)) {
		if (Node::is(p, LIST_ENTRY_NT))
			@<Step (4S.c) Check arguments of a list entry@>;
		if (Node::is(p, PROPERTY_VALUE_NT))
			@<Step (4S.d) Check arguments of a property value@>;
		if (Node::is(p, TABLE_ENTRY_NT))
			@<Step (4S.e) Check arguments of a table reference@>;
	}

@ The "C listed in T" form of table reference is illegal as a general value,
and allowed only in phrases using the |table-reference| token.

@<Allow listed-in table references only where these are expected@> =
	if ((Node::is(p, TABLE_ENTRY_NT)) &&
		(Node::no_children(p) == 2) &&
		(kind_needed) &&
		(!(Node::is(context, LVALUE_TR_CONTEXT_NT)))) {
		THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InexplicitTableEntryAsValue),
			"this form of table entry can only be used in certain special phrases",
			"because it doesn't explicitly refer to a single value. (You can see "
			"which phrases in the Phrasebook index: it's allowed wherever a 'table "
			"entry' is wanted.)");
		return NEVER_MATCH;
	}

@ For a list entry, we have to have a list and an index.

@<Step (4S.c) Check arguments of a list entry@> =
	LOG_DASH("(4S.c)");
	kind *K1 = Specifications::to_kind(p->down);
	kind *K2 = Specifications::to_kind(p->down->next);
	if (Kinds::unary_construction_material(K1) == NULL) {
		THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EntryOfNonList),
			"that doesn't make sense to me as a list entry",
			"since the entry is taken from something which isn't a list.");
		return NEVER_MATCH;
	}
	if (Kinds::eq(K2, K_number) == FALSE) {
		THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonNumericListEntry),
			"that doesn't make sense to me as a list entry",
			"because the indication of which entry is not a number. "
			"For instance, 'entry 3 of L' is allowed, but not 'entry "
			"\"six\" of L'. (List entries are numbered 1, 2, 3, ...)");
		return NEVER_MATCH;
	}

@ For a property value, we have to have a property and an owner (perhaps an
object, perhaps a value). If the owner is a value, we need to police the
availability of the property carefully, since no run-time checking can help
us there.

@<Step (4S.d) Check arguments of a property value@> =
	LOG_DASH("(4S.d)");
	parse_node *the_property = p->down;
	kind *K1 = Specifications::to_kind(the_property);
	if (Kinds::get_construct(K1) != CON_property) @<Issue a "not a property" problem message@>;
	property *prn = Rvalues::to_property(the_property);
	if (prn == NULL)
		internal_error("null property name in type checking");
	if (Properties::is_either_or(prn)) @<Issue a "not a value property" problem message@>;

	parse_node *the_owner = p->down->next;
	kind *K2 = Specifications::to_kind(the_owner);
	if ((K2 == NULL) || (Specifications::is_description(the_owner)))
		@<Issue a problem message for being too vague about the owner@>;

	inference_subject *owning_subject = InferenceSubjects::from_specification(the_owner);
	if (owning_subject == NULL) owning_subject = KindSubjects::from_kind(K2);
	if (PropertyPermissions::find(owning_subject, prn, TRUE) == NULL) {
		if ((Kinds::Behaviour::is_object(K2) == FALSE) ||
			((Rvalues::is_object(the_owner)) &&
				(Rvalues::is_self_object_constant(the_owner) == FALSE)))
			@<Issue a problem message for not being allowed this property@>;
	}

@ Inform constructs property-value specifications quite carefully, and I think
it's only possible for the typechecker to see one where the property isn't
a property when recovering from other problems.

@<Issue a "not a property" problem message@> =
	THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	Problems::quote_wording(3, Node::get_text(the_property));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend '%2' to be a property "
		"of something, but there is no such property as '%3'.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue a "not a value property" problem message@> =
	THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EitherOrAsValue));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend '%2' to be the value "
		"of a property of something, but that property has no value: it's "
		"something which an object either is or is not.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue a problem message for being too vague about the owner@> =
	THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	int owner_quoted = TRUE;
	if ((Specifications::to_kind(the_owner)) &&
		(Descriptions::get_quantifier(the_owner) == NULL))
		Problems::quote_kind(3, Specifications::to_kind(the_owner));
	else if (Wordings::nonempty(Node::get_text(the_owner)))
		Problems::quote_wording(3, Node::get_text(the_owner));
	else owner_quoted = FALSE;
	LOG("Owner tree is $T\n", the_owner);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyOfKind2));
	if (owner_quoted) {
		if (Wordings::nonempty(Node::get_text(p)))
			Problems::issue_problem_segment(
				"In the sentence %1, it looks as if you intend '%2' to be a property, "
				"but '%3' is not specific enough about who or what the owner is. ");
		else
			Problems::issue_problem_segment(
				"In the sentence %1, it looks as if you intend to look up a property "
				"of something, but '%3' is not specific enough about who or what "
				"the owner is. ");
	} else {
		if (Wordings::nonempty(Node::get_text(p)))
			Problems::issue_problem_segment(
				"In the sentence %1, it looks as if you intend '%2' to be a property, "
				"but you're not specific enough about who or what the owner is. ");
		else
			Problems::issue_problem_segment(
				"In the sentence %1, it looks as if you intend to look up a property "
				"of something, but you're not specific enough about who or what "
				"the owner is. ");
	}
	Problems::issue_problem_segment(
		"%PSometimes this mistake is made because Inform mostly doesn't understand "
		"the English language habit of referring to something indefinite by a "
		"common noun - for instance, writing 'change the carrying capacity of "
		"the container to 10' throws Inform because it doesn't understand "
		"that 'the container' means one which has been discussed recently.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@<Issue a problem message for not being allowed this property@> =
	THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, prn->name);
	Problems::quote_subject(3, owning_subject);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LookedUpForbiddenProperty));
	Problems::issue_problem_segment(
		"In the sentence %1, you seem to be looking up the '%2' property, "
		"but '%3' is not allowed to have that property. ");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@ For a table entry, we have to have a list and an index.

@<Step (4S.e) Check arguments of a table reference@> =
	LOG_DASH("(4S.e)");
	if (Node::no_children(p) == 4) {
		kind *col_kind = Specifications::to_kind(p->down->next);
		kind *col_contents_kind = Kinds::unary_construction_material(col_kind);
		kind *key_kind = Specifications::to_kind(p->down->next->next);
		LOGIF(MATCHING, "Kinds: col %u, contents %u, key %u\n",
			col_kind, col_contents_kind, key_kind);
		if ((Kinds::get_construct(col_kind) != CON_table_column) ||
			(col_contents_kind == NULL)) {
			THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"that doesn't make sense to me as a table entry",
				"since the entry is taken from something which isn't a table.");
			return NEVER_MATCH;
		}
		if ((K_snippet) &&
			(Kinds::eq(key_kind, K_snippet)) && (Kinds::eq(col_contents_kind, K_text))) {
			THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, col_contents_kind);
			Problems::quote_kind(3, key_kind);
			Problems::quote_wording(4, Node::get_text(p->down->next->next));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableCorrFruitless2));
			Problems::issue_problem_segment(
				"In the sentence %1, you seem to be looking up a corresponding "
				"entry in a table: but you're looking up a snippet of a command "
				"(%3) in a column of text. Although those look the same, they "
				"really aren't, and no match can be made. (You might be able to "
				"fix matters by converting the snippet to text, say writing '\"[%4]\"' "
				"in place of '%4'.)");
			Problems::issue_problem_end();
			return NEVER_MATCH;
		}
		if (Kinds::compatible(key_kind, col_contents_kind) == NEVER_MATCH) {
			THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, col_contents_kind);
			Problems::quote_kind(3, key_kind);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableCorrFruitless));
			Problems::issue_problem_segment(
				"In the sentence %1, you seem to be looking up a corresponding "
				"entry in a table: but it's fruitless to go looking for %3 "
				"in a column where each entry contains %2.");
			Problems::issue_problem_end();
			return NEVER_MATCH;
		}
	}

@<Unknown found text occurs as a command@> =
	THIS_IS_A_GROSS_PROBLEM;
	if (<structural-phrase-problem-diagnosis>(Node::get_text(p)) == FALSE) {
		if (Wordings::mismatched_brackets(Node::get_text(p))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnpairedBrackets),
				"this is a phrase which I don't recognise",
				"perhaps because it uses brackets '(' and ')' or braces '{' and '}' "
				"in a way that doesn't make sense to me. Each open '(' or '{' has "
				"to have a matching ')' or '}'.");
		} else {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownPhrase),
				"this is a phrase which I don't recognise",
				"possibly because it is one you meant to define but never got round "
				"to, or because the wording is wrong (see the Phrasebook section of "
				"the Index to check). Alternatively, it may be that the text "
				"immediately previous to this was a definition whose ending, normally "
				"a full stop, is missing?");
		}
	}
	return NEVER_MATCH;

@ "Diagnosis" nonterminals are used to parse syntax which is already known
to be invalid: they simply choose between problem messages. This one picks
up on misuse of structural phrases.

=
<structural-phrase-problem-diagnosis> ::=
	continue								==> @<Issue PM_WrongContinue problem@>

@<Issue PM_WrongContinue problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_WrongContinue),
		"this is a phrase which I don't recognise",
		"and which isn't defined. Perhaps you wanted the phrase which "
		"would skip to the next repetition of a loop, since that's "
		"written 'continue' in some programming languages (such as C "
		"and Inform 6)? If so, what you want is 'next'.");

@h Arithmetic operands.
The following works out the kind of an operand for an arithmetic operation,
which because of polymorphism is not as straightforward as it looks.

=
kind *Dash::fix_arithmetic_operand(parse_node *operand) {
	if (Node::is(operand->down, UNKNOWN_NT)) return NULL;
	if (Node::get_type(operand) != RVALUE_CONTEXT_NT)
		internal_error("arithmetic operand not an rvalue");
	kind *expected = NULL;
	parse_node *check = operand->down;
	if (Node::is(check, AMBIGUITY_NT)) check = check->down;
	if (Rvalues::is_CONSTANT_construction(check, CON_property)) {
		property *prn = Rvalues::to_property(check);
		if (Properties::is_either_or(prn) == FALSE)
			expected = ValueProperties::kind(prn);
	}
	kind *K = Node::get_kind_required_by_context(operand);
	Node::set_kind_required_by_context(operand, expected);
	BEGIN_DASH_MODE;
	DASH_MODE_EXIT(ISSUE_PROBLEMS_DMODE);
	DASH_MODE_CREATE(NULL);
	int rv = Dash::typecheck_recursive(operand, NULL, TRUE);
	END_DASH_MODE;
	Node::set_kind_required_by_context(operand, K);
	if (rv == NEVER_MATCH) return NULL;
	return Specifications::to_kind(operand->down);
}

@h Local variable markers.
Branches (4A) and (4I) both make use of the following code, which is
applied to any invocation surviving Dash.

Here's the usual way a local variable is made. One invocation we matched is
for the phrase whose prototype reads:

>> To let (T - nonexisting variable) be (V - value): ...

To be definite, let's suppose we are working on:

>> let the magic word be "Shazam [turn count] times!";

The checking code above accepted "magic word" as a new name, and marked
token 0 in the invocation as one where a new variable will need to be
created -- which is done if and when the invocation is ever compiled.

=
int Dash::set_up_any_local_required(parse_node *inv) {
	for (int i=0, N = Invocations::get_no_tokens(inv); i<N; i++) {
		kind *K = Invocations::get_token_variable_kind(inv, i);
		if (K) {
			if ((i == 0) && (N >= 2) && (Kinds::eq(K, K_value)) &&
				(IDTypeData::is_a_let_assignment(Node::get_phrase_invoked(inv))))
				@<Infer the kind of the new variable@>;

			int changed = FALSE;
			K = Kinds::substitute(K, NULL, &changed, FALSE);
			if (changed) LOGIF(MATCHING, "(4A.c.1) Local var amended to %u\n", K);
			Invocations::set_token_variable_kind(inv, i, K);
		}
	}
	return ALWAYS_MATCH;
}

@ The following code is used to work out a good kind for the new variable,
instead of "value", based on looking at token 1 -- the value being assigned.
In the example above, we look at this initial value,

>> "Shazam [turn count] times!"

and decide that K should be "text".

@<Infer the kind of the new variable@> =
	parse_node *val = Invocations::get_token_as_parsed(inv, i);
	wording W = Node::get_text(val);
	parse_node *initial_value = Invocations::get_token_as_parsed(inv, 1);
	parse_node *iv_spec = Node::get_phrase_invoked(inv)->type_data.token_sequence[1].to_match;
	if (initial_value)
		@<Where no kind was explicitly stated, infer this from the supplied initial value@>;

@ Unusually, it's legal for the initial value to be a kind --

>> let the magic digraph be a text;

This doesn't give us an initial value as such, but it explicitly tells us the
kind, which is good enough.

Otherwise, we either know the kind already from polymorphism calculations, or
we can work it out by seeing what the initial value evaluates to. Note that
with values which are objects, we guess the kind as the broadest subkind of
"object" to which the value belongs: in practice that means usually a thing,
a room or a region.

We make one exception to allow lines like --

>> let X be a one-to-one relation of numbers to men;

where the adjective "one-to-one" forces the right hand side to be description
of a relation.

@<Where no kind was explicitly stated, infer this from the supplied initial value@> =
	kind *seems_to_be = NULL;
	if ((Specifications::is_kind_like(iv_spec)) &&
		(Node::is(initial_value, CONSTANT_NT))) {
		kind *K = Node::get_kind_of_value(initial_value);
		if (Kinds::get_construct(K) == CON_description) {
			kind *DK = Kinds::unary_construction_material(K);
			if (Kinds::get_construct(DK) == CON_relation) seems_to_be = DK;
		}
	}
	if (seems_to_be == NULL) seems_to_be = Specifications::to_kind(initial_value);

	LOGIF(LOCAL_VARIABLES, "New variable %W from $P ($P) seems to be: %u\n",
		W, initial_value, iv_spec, seems_to_be);
	if (seems_to_be == NULL) @<Fail: the initial value of the local is unknown@>;

	if ((Kinds::get_construct(seems_to_be) == CON_list_of) &&
		(Kinds::eq(Kinds::unary_construction_material(seems_to_be), K_nil)))
		@<Fail: the initial value of the local is the empty list@>;
	if (Kinds::Behaviour::definite(seems_to_be) == FALSE)
		@<Fail: the initial value can't be stored@>;
	LOGIF(MATCHING, "(4A.c.1) Local variable seems to have kind: %u (kind-like: %d)\n",
		seems_to_be, Specifications::is_kind_like(initial_value));

	K = seems_to_be;
	if (Specifications::is_kind_like(initial_value) == FALSE)
		if (Kinds::Behaviour::is_subkind_of_object(K))
			while (Kinds::eq(Latticework::super(K), K_object) == FALSE)
				K = Latticework::super(K);
	LOGIF(MATCHING, "(4A.c.1) Local variable inferred to have kind: %u\n", K);

@<Fail: the initial value of the local is unknown@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(initial_value));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"The phrase %1 tries to use 'let' to give a temporary name to a value, "
		"but the value ('%2') is one that I can't understand.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@ Bet you didn't think of this one. Actually, the kind of the list can also
collapse to just "value" if the entries are incompatible, so we call the
relevant code to issue a better problem message if it can.

@<Fail: the initial value of the local is the empty list@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	int pc = problem_count;
	Lists::check_one(Node::get_text(initial_value));
	if (pc == problem_count) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantLetEmptyList));
		Problems::issue_problem_segment(
			"The phrase %1 tries to use 'let' to give a temporary name to the "
			"empty list '{ }', but because it's empty, I can't tell what kind of "
			"value the list should have. Try 'let X be a list of numbers' (or "
			"whatever) instead.");
		Problems::issue_problem_end();
	}
	return NEVER_MATCH;

@ And some kinds are just forbidden in storage:

@<Fail: the initial value can't be stored@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
		"this isn't a definite kind",
		"and is instead a general description which might apply to many "
		"different kinds, so I can't see how to create this named value. "
		"(For example, 'let R be a relation' is vague because it doesn't "
		"make clear what R will relate - 'let R be a relation of numbers' "
		"would be fine.)");
	return NEVER_MATCH;

@h Problems, problems, problems.
We are now in a situation where Dash has certainly failed, and on every
possible alternative reading, so it would be legitimate to return |NEVER_MATCH|
here, which would likely result in some anodyne problem message from higher
up in Dash.

But we want to produce more helpful problem messages than that. It's not
entirely clear how best to do this. Often, when a node fails, it fails for
seven different reasons -- each different possibility fails for a different
cause. We want, somehow, to guess which was the most likely to have been
intended and to report the problem with that one.

=
int Dash::failed_one(parse_node *inv, parse_node *context, kind *kind_needed) {
	parse_node *list[1];
	list[0] = inv;
	return Dash::failed(list, 1, context, kind_needed);
}

wording PM_BadIntermediateKind_wording = EMPTY_WORDING_INIT;

int Dash::failed(parse_node **list_of_possible_readings, int no_of_possible_readings,
	parse_node *context, kind *kind_needed) {
	if (Dash::problems_have_been_issued()) return NEVER_MATCH;

	parse_node *first_inv_in_group = NULL;
	parse_node *first_failing_interestingly = NULL;
	parse_node *first_not_failing_grossly = NULL;
	wording SW = EMPTY_WORDING;
	int list_includes_lets = FALSE;
	int nongross_count = 0;
	@<Scan through the invocations in the problematic group, gathering information@>;

	parse_node *most_likely_to_have_been_intended = NULL;
	@<Decide which invocation is the one most likely to have been intended@>;

	int pc_before = problem_count;
	if (first_failing_interestingly)
		@<Re-type-check the first interesting invocation, allowing interesting problems this time@>
	else if (most_likely_to_have_been_intended)
		@<Re-type-check the tokens of the most likely invocation with silence off@>
	if (problem_count == pc_before) {
		if (Wordings::nonempty(SW)) <failed-text-substitution-diagnosis>(SW);
		else @<Issue a problem for a regular phrase with multiple failed possibilities@>;
	}
	return NEVER_MATCH;
}

@<Scan through the invocations in the problematic group, gathering information@> =
	for (int ref=0; ref<no_of_possible_readings; ref++) {
		parse_node *inv = list_of_possible_readings[ref];
		if ((Dash::test_flag(inv, INTERESTINGLY_FAILED_DASHFLAG)) &&
			(first_failing_interestingly == NULL)) first_failing_interestingly = inv;
		if (first_inv_in_group == NULL) first_inv_in_group = inv;
		id_body *idb = Node::get_phrase_invoked(inv);
		if (idb) {
			if (IDTypeData::is_a_let_assignment(idb)) list_includes_lets = TRUE;
			if (Dash::test_flag(inv, GROSSLY_FAILED_DASHFLAG) == FALSE) {
				first_not_failing_grossly = inv;
				if (IDTypeData::is_a_say_X_phrase(&(idb->type_data))) SW = Node::get_text(inv);
				nongross_count++;
			}
		}
	}

@<Decide which invocation is the one most likely to have been intended@> =
	if (first_failing_interestingly)
		most_likely_to_have_been_intended = first_failing_interestingly;
	else if ((nongross_count > 1) && (list_includes_lets))
		most_likely_to_have_been_intended = first_not_failing_grossly;
	else if (nongross_count == 1)
		most_likely_to_have_been_intended = first_not_failing_grossly;
	else if ((nongross_count == 0) && (first_inv_in_group))
		most_likely_to_have_been_intended = first_inv_in_group;

@<Re-type-check the first interesting invocation, allowing interesting problems this time@> =
	BEGIN_DASH_MODE;
	DASH_MODE_ENTER(ISSUE_INTERESTING_PROBLEMS_DMODE);
	DASH_MODE_CREATE(NULL);
	Dash::typecheck_recursive(first_failing_interestingly, context, FALSE);
	END_DASH_MODE;

@<Re-type-check the tokens of the most likely invocation with silence off@> =
	int ec = problem_count;
	BEGIN_DASH_MODE;
	DASH_MODE_ENTER(ISSUE_PROBLEMS_DMODE);
	DASH_MODE_CREATE(NULL);
	for (int i=0; i<Invocations::get_no_tokens(most_likely_to_have_been_intended); i++) {
		Dash::typecheck_recursive(Invocations::get_token(most_likely_to_have_been_intended, i), context, TRUE);
		if (problem_count > ec) break;
	}
	if (problem_count == ec) {
		LOGIF(MATCHING, "Try again in local problems mode\n");
		BEGIN_DASH_MODE;
		DASH_MODE_ENTER(ISSUE_LOCAL_PROBLEMS_DMODE);
		DASH_MODE_CREATE(NULL);
		for (int i=0; i<Invocations::get_no_tokens(most_likely_to_have_been_intended); i++) {
			Dash::typecheck_recursive(Invocations::get_token(most_likely_to_have_been_intended, i), context, TRUE);
			if (problem_count > ec) break;
		}
		END_DASH_MODE;
	}
	END_DASH_MODE;
	if (problem_count == ec) {
		kind *K = Node::get_kind_resulting(most_likely_to_have_been_intended);
		kind *W = kind_needed;
		if ((K) && (W) && (Kinds::compatible(K, W) == NEVER_MATCH)) {
			THIS_IS_AN_ORDINARY_PROBLEM;
			wording PW = Node::get_text(list_of_possible_readings[0]);
			if (!(Wordings::eq(PM_BadIntermediateKind_wording, PW))) {
				PM_BadIntermediateKind_wording = PW;
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, PW);
				Problems::quote_kind(3, K);
				Problems::quote_kind(4, W);
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadIntermediateKind));
				Problems::issue_problem_segment(
					"In %1, the phrase '%2' doesn't seem to fit: I was hoping it would "
					"be %4, but in fact it's %3.");
				Problems::issue_problem_end();
			}
			return NEVER_MATCH;
		}
		if (problem_count == ec) {
			LOGIF(MATCHING, "Try again in gross problems mode\n$T\n", most_likely_to_have_been_intended);
			BEGIN_DASH_MODE;
			DASH_MODE_ENTER(ISSUE_GROSS_PROBLEMS_DMODE);
			DASH_MODE_CREATE(NULL);
			Dash::typecheck_recursive(most_likely_to_have_been_intended, context, FALSE);
			END_DASH_MODE;
		}
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"the ingredients in this phrase do not fit it",
				"and I am confused enough by this that I can't give a very helpful "
				"problem message. Sorry about that.");
	}

@<Issue a problem for a regular phrase with multiple failed possibilities@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AllInvsFailed));
	Problems::quote_source(1, current_sentence);
	Problems::issue_problem_segment(
		"You wrote %1, which I tried to match against several possible phrase "
		"definitions. None of them worked.");
	Problems::issue_problem_end();

@ The following chooses a problem message for a text substitution which is
unrecognised.

=
<failed-text-substitution-diagnosis> ::=
	a list of ... |    ==> @<Issue PM_SayAList problem@>
	...									==> @<Issue last-resort failed ts problem@>

@<Issue PM_SayAList problem@> =
	StandardProblems::sentence_in_detail_problem(Task::syntax_tree(), _p_(PM_SayAList), W,
		"this asked to say 'a list of...'",
		"which I read as being a general description applying to some "
		"lists and not others, so it's not something which can be said. "
		"(Maybe you meant 'the list of...' instead? That normally makes "
		"a definite list of whatever matches the '...' part.)");

@<Issue last-resort failed ts problem@> =
	StandardProblems::sentence_in_detail_problem(Task::syntax_tree(), _p_(BelievedImpossible), W,
		"this asked to say something which I do not recognise",
		"either as a value or as one of the possible text substitutions.");

@ In the final checklist of doomed possibility, the code to quote an
invocation in a problem message will call the following routine for each
parsed token. This remembers the token so that it can be explained in notes
at the end of the big list; but each word range is remembered only once,
for brevity. We don't gloss the meanings of literal constants like |26|
or |"frog"| since these are glaringly obvious.

=
void Dash::note_inv_token_text(parse_node *p, int new_name) {
	inv_token_problem_token *itpt;
	LOOP_OVER(itpt, inv_token_problem_token)
		if (Wordings::eq(itpt->problematic_text, Node::get_text(p))) {
			if (new_name) itpt->new_name = TRUE;
			return;
		}
	itpt = CREATE(inv_token_problem_token);
	itpt->problematic_text = Node::get_text(p);
	itpt->new_name = new_name;
	if (Node::is(p, AMBIGUITY_NT)) p = p->down;
	itpt->as_parsed = p; itpt->already_described = FALSE;
	if ((Rvalues::is_CONSTANT_of_kind(p, K_number)) ||
		(Rvalues::is_CONSTANT_of_kind(p, K_text))) itpt->already_described = TRUE;
}

@ This last little grammar diagnoses problems with a condition, and helps to
construct a problem message which will (usually) show which part of a compound
condition caused the trouble:

=
<condition-problem-diagnosis> ::=
	<condition-problem-part> <condition-problem-part-tail> |  ==> { R[1] | R[2], - }
	<condition-problem-part>                                  ==> { pass 1 }

<condition-problem-part-tail> ::=
	, and/or <condition-problem-diagnosis> |                  ==> { pass 1 }
	,/and/or <condition-problem-diagnosis>                    ==> { pass 1 }

<condition-problem-part> ::=
	<s-condition> |    ==> { 0, - }; @<Quote this-condition-okay segment@>;
	<s-value> |        ==> { INVALID_CP_BIT, - }; @<Quote this-condition-value segment@>;
	... begins/ends |  ==> { WHENWHILE_CP_BIT+INVALID_CP_BIT, - }; @<Quote scene-begins-or-ends segment@>;
	when/while *** |   ==> { WHENWHILE_CP_BIT+INVALID_CP_BIT, - }; @<Quote this-condition-bad segment@>;
	...                ==> { INVALID_CP_BIT, - }; @<Quote this-condition-bad segment@>;

@<Quote this-condition-okay segment@> =
	if (preform_lookahead_mode == FALSE) {
		Problems::quote_wording(4, W);
		Problems::issue_problem_segment("'%4' was okay; ");
	}

@<Quote this-condition-value segment@> =
	if (preform_lookahead_mode == FALSE) {
		Problems::quote_wording(4, W);
		Problems::issue_problem_segment(
			"'%4' only made sense as a value, which can't be used as a condition; ");
	}

@<Quote scene-begins-or-ends segment@> =
	if (preform_lookahead_mode == FALSE) {
		Problems::quote_wording(4, W);
		Problems::issue_problem_segment(
			"'%4' did not make sense as a condition, but looked as if it might "
			"be a way to specify a beginning or end for a scene - but such things "
			"can't be divided by 'or'; ");
	}

@<Quote this-condition-bad segment@> =
	if (preform_lookahead_mode == FALSE) {
		Problems::quote_wording(4, W);
		Problems::issue_problem_segment("'%4' did not make sense; ");
	}

@h (5) Single nodes.
Here we typecheck a single non-invocation node on its own terms, ignoring
any children it may have.

=
int Dash::typecheck_single_node(parse_node *p, kind *kind_expected, int condition_context) {
	LOG_DASH("(5)");
	LOGIF(MATCHING, "Kind expected: %u, condition expected: %d\n", kind_expected, condition_context);
	int outcome = ALWAYS_MATCH; /* drops to |SOMETIMES_MATCH| if a need for run-time checking is realised */

	if ((Rvalues::is_nothing_object_constant(p)) &&
		(kind_expected) && (Kinds::Behaviour::is_subkind_of_object(kind_expected)))
		@<Disallow "nothing" as a match for a description requiring a kind of object@>;

	@<Step (5.a) Deal with the UNKNOWN_NT@>;
	@<Step (5.b) Deal with bare property names@>;
	@<Step (5.c) Deal with any attached proposition@>;
	@<Step (5.d) Apply miscellaneous other coercions@>;
	@<Step (5.e) The Main Rule of Type-Checking@>;
	return outcome;
}

@ "You can't have/ Something for nothing," as Canadian power-trio Rush tell
us with the air of having just made a great discovery; well, you can't have
"nothing" for something, either --

@<Disallow "nothing" as a match for a description requiring a kind of object@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	Problems::quote_kind(3, kind_expected);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NothingForSomething));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' is literally no thing, and it consequently does "
		"not count as %3.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@h Rule (5.a).
In all cases, unknown text in |found| is incorrect. We can produce
any of more than twenty different problem messages here, in an attempt to be
helpful about what exactly is wrong.

@d SAY_UTSHAPE 1
@d LIST_UTSHAPE 2
@d NO_UTSHAPE 3

@<Step (5.a) Deal with the UNKNOWN_NT@> =
	LOG_DASH("(5.a)");
	if (Node::is(p, UNKNOWN_NT)) {
		THIS_IS_A_GROSS_PROBLEM;
		LOG("(5.a) problem message:\nfound: $Texpected: %u", p, kind_expected);
		#ifdef IF_MODULE
		if (Kinds::eq(kind_expected, K_stored_action))
			@<Unknown found text occurs as an action to try@>;
		#endif
		Problems::quote_source_eliding_begin(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(p));
		if (condition_context)
			Problems::quote_text(3, "a condition");
		else if (kind_expected == NULL)
			Problems::quote_kind(3, K_value);
		else
			Problems::quote_kind(3, kind_expected);

		int shape = NO_UTSHAPE;
		if (current_sentence) {
			<unknown-text-shape>(Node::get_text(current_sentence));
			shape = <<r>>;
		}
		if (shape == NO_UTSHAPE) {
			<unknown-text-shape>(Node::get_text(p));
			shape = <<r>>;
		}

		int preceding = Wordings::first_wn(Node::get_text(p)) - 1;
		if ((preceding >= 0) && (current_sentence) &&
			(((TextSubstitutions::currently_compiling()) || (shape == SAY_UTSHAPE))) &&
			((preceding == Wordings::first_wn(Node::get_text(current_sentence)))
				|| (Lexer::word(preceding) == COMMA_V)))
			@<Unknown found text occurs as a text substitution@>
		else if ((condition_context) && (shape == LIST_UTSHAPE))
			@<Issue a problem message for a compound condition which has gone bad@>
		else
			@<Issue a problem message for miscellaneous suspicious wordings@>;

		return NEVER_MATCH;
	}

@<Unknown found text occurs as an action to try@> =
	parse_node *spec = NULL;
	kind *K = NULL, *K2 = NULL;
	Dash::clear_validation_case();
	<action-pattern>(Node::get_text(p));
	if (Dash::get_validation_case(&spec, &K, &K2)) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownTryAction1));
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(p));
		Problems::quote_wording(3, Node::get_text(spec));
		Problems::quote_kind(4, K);
		Problems::quote_kind(5, K2);
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not an action I can try. This looks as "
			"if it might be because it contains something of the wrong kind. "
			"My best try involved seeing if '%3' could be %4, which might have "
			"made sense, but it turned out to be %5.");
		Problems::issue_problem_end();
	} else {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownTryAction2),
			"this is not an action I recognise",
			"or else is malformed in a way I can't see how to sort out.");
	}
	return NEVER_MATCH;

@ The <unknown-text-shape> is used purely in diagnosing problems; it helps
to decide, for instance, whether the errant phrase was intended to be a text
substitution or not.

=
<unknown-text-shape> ::=
	say ... |         ==> { SAY_UTSHAPE, - }
	... and/or ... |  ==> { LIST_UTSHAPE, - }
	...               ==> { NO_UTSHAPE, - }

<unknown-text-substitution-problem-diagnosis> ::=
	, ... |    ==> @<Issue PM_SayComma problem@>
	unicode ... |    ==> @<Issue PM_SayUnicode problem@>
	... condition |    ==> @<Issue PM_SayUnknownCondition problem@>
	otherwise/else *** |    ==> @<Issue PM_SayElseMisplaced problem@>
	...					==> @<Issue PM_SayUnknown problem@>

@<Issue PM_SayComma problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SayComma));
	Problems::issue_problem_segment(
		"In the line %1, I was expecting that '%2' would be something to "
		"'say', but unexpectedly it began with a comma. The usual form is "
		"just 'say \"text\"', perhaps with some substitutions in square "
		"brackets within the quoted text, but no commas.");
	Problems::issue_problem_end();

@<Issue PM_SayUnicode problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SayUnicode));
	Problems::issue_problem_segment(
		"In the line %1, I was expecting that '%2' would be something to "
		"'say', but it didn't look like any form of 'say' that I know. "
		"So I tried to read '%2' as a Unicode character, which seemed "
		"likely because of the word 'unicode', but that didn't work either. "
		"%PUnicode characters can be written either using their decimal "
		"numbers - for instance, 'Unicode 2041' - or with their standard "
		"names - 'Unicode Latin small ligature oe'. For efficiency reasons "
		"these names are only available if you ask for them; to make them "
		"available, you need to 'Include Unicode Character Names by Graham "
		"Nelson' or, if you really need more, 'Include Unicode Full "
		"Character Names by Graham Nelson'.");
	Problems::issue_problem_end();

@<Issue PM_SayElseMisplaced problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SayElseMisplaced));
	Problems::issue_problem_segment(
		"In the line %1, I was expecting that '%2' would be something to "
		"'say', but unexpectedly I found an 'otherwise' (or 'else'). That "
		"would be fine inside an '[if ...]' part of the text, but doesn't "
		"make sense on its own.");
	Problems::issue_problem_end();

@<Issue PM_SayUnknownCondition problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SayUnknownCondition));
	Problems::issue_problem_segment(
		"In the line %1, I was expecting that '%2' would be something to "
		"'say', but it didn't look like any form of 'say' that I know. So "
		"I tried to read '%2' as a value of some kind (because it's legal "
		"to say values), but couldn't make sense of it that way either. "
		"%PSometimes this happens because punctuation has gone wrong - "
		"for instance, if you've omitted a semicolon or full stop at the "
		"end of the 'say' phrase.");
	Problems::issue_problem_segment(
		"%PNames which end in 'condition' often represent the current "
		"state of something which can be in any one of three or more "
		"states. This will only be the case if you have explicitly said "
		"so, with a line like 'The rocket is either dry, fuelled or launched.' - "
		"in which case the value 'rocket condition' will always be one "
		"of 'dry', 'fuelled' or 'launched'. Note that all of this only "
		"applies to a list of three or more possibilities - a thing can "
		"have any number of either/or properties. For instance, a "
		"container is open or closed, but it also transparent or opaque. "
		"Neither of these counts as its 'condition'.");
	Problems::issue_problem_end();

@<Issue PM_SayUnknown problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SayUnknown));
	Problems::issue_problem_segment(
		"In the line %1, I was expecting that '%2' would be something to "
		"'say', but it didn't look like any form of 'say' that I know. So "
		"I tried to read '%2' as a value of some kind (because it's legal "
		"to say values), but couldn't make sense of it that way either. "
		"%PSometimes this happens because punctuation has gone wrong - "
		"for instance, if you've omitted a semicolon or full stop at the "
		"end of the 'say' phrase.");
	Problems::issue_problem_end();

@<Unknown found text occurs as a text substitution@> =
	<unknown-text-substitution-problem-diagnosis>(Node::get_text(p));

@ It's a bit unenlightening when an entire condition is rejected as
unknown if, in fact, only one of perhaps many clauses is broken. We
therefore produce quite an elaborate problem message which goes through
the clauses, summing up their status in turn:

@d INVALID_CP_BIT 1
@d WHENWHILE_CP_BIT 2

@<Issue a problem message for a compound condition which has gone bad@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CompoundConditionFailed));
	Problems::issue_problem_segment(
		"In the sentence %1, I was expecting that '%2' would be a condition. "
		"It didn't make sense as one long phrase, but because it was divided up by "
		"'and'/'or', I tried breaking it down into smaller conditions, but "
		"that didn't work either. ");
	<condition-problem-diagnosis>(Node::get_text(p));
	int dubious = <<r>>;
	if (dubious & INVALID_CP_BIT)
		Problems::issue_problem_segment(
			"so I ran out of ideas.");
	else
		Problems::issue_problem_segment(
			"but that combination of conditions isn't allowed to be joined "
			"together with 'and' or 'or', because that would just be too confusing. "
			"%PFor example, 'if the player is carrying a container or a "
			"supporter' has an obvious meaning in English, but Inform reads "
			"it as two different conditions glued together: 'if the player is "
			"carrying a container', and also 'a supporter'. The meaning of "
			"the first is obvious. The second part is true if the current "
			"item under discussion is a supporter - for instance, the noun of "
			"the current action, or the item to which a definition applies. "
			"Both of these conditions are useful in different circumstances, "
			"but combining them in one condition like this makes a very "
			"misleading line of text. So Inform disallows it.");
	if (dubious & WHENWHILE_CP_BIT)
		Problems::issue_problem_segment(
			"%PI notice there's a 'when' or 'while' being used as the opening "
			"word of one of those conditions, though; maybe that's the problem?");
	Problems::issue_problem_end();

@ These are cases where the wording used in the source text suggests some
common misunderstanding.

=
<unknown-value-problem-diagnosis> ::=
	turns |    ==> @<Issue PM_NumberOfTurns problem@>
	... is/are out of play |    ==> @<Issue PM_OutOfPlay problem@>
	unicode ... |    ==> @<Issue PM_MidTextUnicode problem@>
	... condition |    ==> @<Issue PM_UnknownCondition problem@>
	...								==> @<Issue PM_Unknown problem@>

<unknown-use-option-diagnosis> ::=
	... ^option |    ==> @<Issue PM_OptionlessOption problem@>
	...								==> @<Issue PM_Unknown problem@>

<unknown-activity-diagnosis> ::=
	... of |    ==> @<Issue PM_ActivityOf problem@>
	... for |    ==> @<Issue PM_ActivityWithFor problem@>
	...								==> @<Issue PM_Unknown problem@>

@<Issue PM_NumberOfTurns problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NumberOfTurns));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PPerhaps by 'turns' you meant the number of turns of play to date? "
		"If so, try 'turn count' instead.");
	Problems::issue_problem_end();

@<Issue PM_OutOfPlay problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_OutOfPlay));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PPeople sometimes say that things or people removed from all "
		"rooms are 'out of play', but Inform uses the adjective "
		"'off-stage' - for instance, 'if the ball is off-stage'. "
		"If you would like 'out of play' to work, you could always "
		"write 'Definition: A thing is out of play if it is off-stage.' "
		"Then the two would be equivalent.");
	Problems::issue_problem_end();

@<Issue PM_OptionlessOption problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_OptionlessOption));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PThe names of use options, on the rare occasions when they "
		"appear as values, always end with the word 'option' - for "
		"instance, we have to write 'American dialect option' not "
		"'American dialect'. As your text here doesn't end with the "
		"word 'option', perhaps you've forgotten this arcane rule?");
	Problems::issue_problem_end();

@<Issue PM_ActivityOf problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityOf));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PActivity names rarely end with 'of': for instance, when we talk "
		"about 'printing the name of something', properly speaking "
		"the activity is called 'printing the name'. Maybe that's it?");
	Problems::issue_problem_end();

@<Issue PM_MidTextUnicode problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MidTextUnicode));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PMaybe you intended this to produce a Unicode character? "
		"Unicode characters can be written either using their decimal "
		"numbers - for instance, 'Unicode 2041' - or with their standard "
		"names - 'Unicode Latin small ligature oe'. For the full list of "
		"those names, see the Unicode standard version 15.0.0.");
	Problems::issue_problem_end();

@<Issue PM_UnknownCondition problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownCondition));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PNames which end in 'condition' often represent the current "
		"state of something which can be in any one of three or more "
		"states. Names like this only work if you've declared them, with "
		"a line like 'The rocket is either dry, fuelled or launched.' - "
		"in which case the value 'rocket condition' will always be one "
		"of 'dry', 'fuelled' or 'launched'. Maybe you forgot to declare "
		"something like this, or mis-spelled the name of the owner?");
	Problems::issue_problem_end();

@<Issue PM_ActivityWithFor problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityWithFor));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_segment(
		"%PWere you by any chance meaning to refer to an activity by name, "
		"and used the word 'for' at the end of that name? If so, try removing "
		"just the word 'for'.");
	Problems::issue_problem_end();

@<Issue PM_Unknown problem@> =
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Unknown));
	@<Issue the generic unknown wording message@>;
	Problems::issue_problem_end();

@<Issue the generic unknown wording message@> =
	Problems::issue_problem_segment(
		"In the sentence %1, I was expecting to read %3, but instead found some "
		"text that I couldn't understand - '%2'. ");

@<Issue a problem message for miscellaneous suspicious wordings@> =
	if (Kinds::eq(kind_expected, K_use_option)) {
		<unknown-use-option-diagnosis>(Node::get_text(p));
	} else if (Kinds::get_construct(kind_expected) == CON_activity) {
		<unknown-activity-diagnosis>(Node::get_text(p));
	} else {
		<unknown-value-problem-diagnosis>(Node::get_text(p));
	}

@h Rule (5.b).
This is all concerned with a shorthand far more convenient to an Inform author
than it is to us -- where a property's name is used without any indication of
its owner.

@<Step (5.b) Deal with bare property names@> =
	LOG_DASH("(5.b)");
	if (Kinds::get_construct(kind_expected) != CON_property) {
		parse_node *check = p;
		if (Node::is(check, AMBIGUITY_NT)) check = check->down;
		if (Rvalues::is_CONSTANT_construction(check, CON_property)) {
			property *prn = Rvalues::to_property(check);
			@<Step (5.b.2) If a bare property name is used where we expect a value, coerce it if the kinds allow@>;
		}
	}

@ But more often we want a value which just happens in this case to come
from a property. For instance, in a text routine printing a description
like "The cedarwood box could hold [carrying capacity in words]
item[s].", we want "carrying capacity" to be a number value, and we
treat it as if it read "carrying capacity of the cedarwood box".

We don't coerce if the property holds a relation, because letting a variable
be a description of a relation tries to create a local relation on the
stack frame, and this is unlikely to be what anyone wanted.

@<Step (5.b.2) If a bare property name is used where we expect a value, coerce it if the kinds allow@> =
	LOG_DASH("(5.b.2)");
	if (kind_expected) {
	LOG_DASH("(5.b.2a)");
		if (Properties::is_value_property(prn)) {
	LOG_DASH("(5.b.2b)");
			kind *kind_if_coerced = ValueProperties::kind(prn);
			int verdict = Kinds::compatible(kind_if_coerced, kind_expected);
			if (verdict != NEVER_MATCH) {
	LOG_DASH("(5.b.2c)");
				@<Coerce into a property of the "self" object@>;
				return verdict;
			}
			if ((Kinds::get_construct(kind_expected) == CON_description) &&
				(Kinds::get_construct(kind_if_coerced) != CON_relation)) {
				LOGIF(MATCHING, "(5.b.2) coercing to description\n");
				parse_node *become = Specifications::from_kind(kind_if_coerced);
				Node::set_text(become, Node::get_text(p));
				Node::copy_in_place(p, Descriptions::to_rvalue(become));
				p->down = NULL;
			} else {
				LOGIF(MATCHING, "(5.b.2) declining to cast into property value form\n");
				return verdict;
			}
		}
	}

@ The tricky part is working out what the implicitly meant object is, a
classic donkey anaphora-style problem in linguistics. We don't even begin
to solve that here: indeed the decision is taken rather indirectly, because
we simply compile code which uses Inform 6's |self| variable to refer to
the owner. The I6 library and our own run-time code conspire to ensure that
|self| is always equal to something sensible.

@<Coerce into a property of the "self" object@> =
	parse_node *was = p->next_alternative;
	parse_node *pr = Node::duplicate(p);
	pr->next_alternative = NULL;
	parse_node *become = Lvalues::new_PROPERTY_VALUE(pr, Rvalues::new_self_object_constant());
	Node::copy(p, become);
	p->next_alternative = was;

	LOGIF(MATCHING, "(5.b) coercing PROPERTY to PROPERTY VALUE: $P\n", p);

@h Rule (5.c).
An unchecked SP can contain a proposition which, though valid as a
predicate calculus sentence, makes no sense for type reasons: for instance,
"the Orange Room is 10" compiles to a valid sentence but one in which the
binary predicate for equality is applied to incomparable SPs. To type-check,
we must prove that any proposition needed is valid on these grounds, and we
delegate that to "Type Check Propositions.w".

@<Step (5.c) Deal with any attached proposition@> =
	LOG_DASH("(5.c)");
	char *desired_to = NULL;
	if (Node::is(p, TEST_PROPOSITION_NT)) desired_to = "be a condition";
	if (Descriptions::is_complex(p)) desired_to = "be a description";

	if (desired_to) {
		if (TypecheckPropositions::type_check(Specifications::to_proposition(p),
			TypecheckPropositions::tc_no_problem_reporting())
			== NEVER_MATCH) {
			LOGIF(MATCHING, "(5.c) on $P failed proposition type-checking: $D\n",
				p, Specifications::to_proposition(p));
			THIS_IS_A_GROSS_PROBLEM;
			TypecheckPropositions::type_check(Specifications::to_proposition(p),
				TypecheckPropositions::tc_problem_reporting(Node::get_text(p), desired_to));
			return NEVER_MATCH;
		} else { LOG_DASH("(5.c) Okay!"); }
	}

@h Rule (5.d).
Something of a grab-bag, this one. What these three situations have in common
is that all use the typechecker to clarify ambiguities in syntax.

@<Step (5.d) Apply miscellaneous other coercions@> =
	#ifdef IF_MODULE
	@<Step (5.d.1) Coerce TEST ACTION to constant action@>;
	#endif
	@<Step (5.d.2) Coerce constant TEXT and TEXT ROUTINE to UNDERSTANDING@>;
	@<Step (5.d.3) Coerce a description to a value, if we expect a noun-like description@>;
	@<Step (5.d.4) Reject plausible but wrong uses due to use of inline-only types in phrases@>;

@ An action pattern can be an action if specific enough, and this is
crucial: it enables phrases such as "try taking the box" to work. When
such phrases are type-checked, they expect the argument to be a constant
action value, which is a specific action.

@<Step (5.d.1) Coerce TEST ACTION to constant action@> =
	LOG_DASH("(5.d.1)");
	if ((AConditions::is_action_TEST_VALUE(p)) && (kind_expected) &&
		(Kinds::compatible(K_stored_action, kind_expected))) {
		explicit_action *ea = Node::get_constant_explicit_action(p->down);
		if (ea == NULL) {
			action_pattern *ap = Node::get_constant_action_pattern(p->down);
			int failure_code = 0;
			ea = ExplicitActions::from_action_pattern(ap, &failure_code);
		
			if (failure_code == UNDERSPECIFIC_EA_FAILURE) {
				THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, Node::get_text(p));
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionNotSpecific));
				Problems::issue_problem_segment(
					"You wrote %1, but '%2' is too vague to describe a specific action. "
					"%PIt has to be an exact instruction about what is being done, and "
					"to what. For instance, 'taking the box' is fine, but 'dropping or "
					"taking something openable' is not.");
				Problems::issue_problem_end();
				return NEVER_MATCH;
			}
			if (failure_code == OVERSPECIFIC_EA_FAILURE) {
				THIS_IS_A_GROSSER_THAN_GROSS_PROBLEM;
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, Node::get_text(p));
				StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActionTooSpecific));
				Problems::issue_problem_segment(
					"You wrote %1, but '%2' imposes too many restrictions on the "
					"action to be carried out, by saying something about the "
					"circumstances which you can't guarantee will be true. "
					"%PSometimes this problem appears because I've misread text like "
					"'in ...' as a clause saying that the action takes place in a "
					"particular room, when in fact it was part of the name of one of "
					"the items involved. If that's the problem, try using 'let' to "
					"create a simpler name for it, and then rewrite the 'try' to use "
					"that simpler name - the ambiguity should then vanish.");
				Problems::issue_problem_end();
				return NEVER_MATCH;
			}
		}
		Node::copy_in_place(p, p->down);
		p->down = NULL;
		Node::set_kind_of_value(p, K_stored_action);
		Node::set_constant_explicit_action(p, ea);
		Node::set_constant_action_pattern(p, NULL);
		LOGIF(MATCHING, "Coerced to sa: $P\n", p);
		return ALWAYS_MATCH;
	}
	if ((condition_context) &&
		(Node::is(p, CONSTANT_NT))) {
		kind *E = Specifications::to_kind(p);
		if (Kinds::compatible(E, K_stored_action)) {
			parse_node *val = Node::duplicate(p);
			Node::copy_in_place(p, Node::new(TEST_VALUE_NT));
			Node::set_text(p, Node::get_text(val));
			p->down = val;
			LOGIF(MATCHING, "Coerced back again to sa: $P\n", p);
			return ALWAYS_MATCH;
		}
	}

@ The following applies only to literal text in double-quotes, which might
or might not include text substitutions in square brackets: if we check it
against "understanding", then we are trying to interpret it as a grammar
to parse rather than text to print. We need to coerce since these have very
different representations at run-time.

@<Step (5.d.2) Coerce constant TEXT and TEXT ROUTINE to UNDERSTANDING@> =
	LOG_DASH("(5.d.2)");
	if ((Rvalues::is_CONSTANT_of_kind(p, K_text)) &&
		(K_understanding) && (Kinds::eq(kind_expected, K_understanding))) {
		Node::set_kind_of_value(p, K_understanding);
	}

@ Another ambiguity is that the text "women who are in lighted rooms" in:

>> let N be the number of women who are in lighted rooms;

...is parsed as a description, a condition. But in
fact it's a noun here -- it has to be a value, in fact, which can go into
the "number of..." phrase as an argument. We make this happen by coercing
it to a constant value, using the "description of..." constructor.

@<Step (5.d.3) Coerce a description to a value, if we expect a noun-like description@> =
	LOG_DASH("(5.d.3)");
	kind *domain = NULL;
	if (Kinds::get_construct(kind_expected) == CON_description) {
		domain = Kinds::unary_construction_material(kind_expected);
	}
	if ((domain) && (Specifications::is_description(p))) {
		LOGIF(MATCHING, "(5.d.3) requiring description of %u\n", domain);
		kind *K = Specifications::to_kind(p);
		if (K == NULL) K = K_object;
		LOGIF(MATCHING, "(5.d.3) finding description of %u\n", K);
		int made_match = TRUE;
		if (Kinds::compatible(K, domain) == NEVER_MATCH) made_match = FALSE;
		@<Throw out the wrong sort of description with a seldom-seen problem message@>;
		quantifier *q = Descriptions::get_quantifier(p);
		if ((q) && (q != not_exists_quantifier) && (q != for_all_quantifier))
			@<Issue a problem message for a quantified proposition in the description@>;
		parse_node *as_con = Descriptions::to_rvalue(p);
		if (as_con == NULL)
			@<Issue a problem message for a malformed proposition in the description@>;
		Node::copy_in_place(p, as_con);
		p->down = NULL;
		return ALWAYS_MATCH;
	}

@ This is for undescriptive descriptions, really.

@<Issue a problem message for a quantified proposition in the description@> =
	THIS_IS_AN_INTERESTING_PROBLEM {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(p));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadQuantifierInDescription));
		Problems::issue_problem_segment(
			"In %1 you wrote the description '%2' in the context of a value, "
			"but descriptions used that way are not allowed to talk about "
			"quantities. For example, it's okay to write 'an even number' "
			"as a description value, but not 'three numbers' or 'most numbers'.");
		Problems::issue_problem_end();
	}
	return NEVER_MATCH;

@ The following message is seldom seen since most phrases using descriptions
are set up with two parallel versions. As every description matches exactly one
of these, there won't be a problem. But just in case the user has intentionally
defined a phrase for only one case:

@<Throw out the wrong sort of description with a seldom-seen problem message@> =
	if (made_match == FALSE) {
		THIS_IS_AN_ORDINARY_PROBLEM;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(p));
		Problems::quote_kind(3, K);
		Problems::quote_kind(4, domain);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"In the line %1, the text '%2' seems to be a description of %3, but "
			"a description of %4 was required.");
		Problems::issue_problem_end();
		return NEVER_MATCH;
	}

@ I can't see an easy proof that this can never occur, but nor can I make it
happen. The problem message is just in case someone finds a way. It appears
if the description has a proposition with other than one free variable, once
any universal quantifier ("all", etc.) is removed.

@<Issue a problem message for a malformed proposition in the description@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"In the line %1, the text '%2' is given where a description of a collection "
		"of things or values was required. For instance, 'rooms which contain "
		"something', or 'closed containers' - note that there is no need to say "
		"'all' or 'every' in this context, as that is understood already.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@ It might look as if this ought to be checked when phrase definitions are
made; the trouble is, "action", "condition" and so on are valid
in phrase definitions, but only in inline-defined ones. We don't want to get
into all that here, because the message is aimed more at Inform novices who
have made an understandable confusion.

@<Step (5.d.4) Reject plausible but wrong uses due to use of inline-only types in phrases@> =
	if (Lvalues::is_lvalue(p)) {
		kind *K = Specifications::to_kind(p);
		if (K == NULL) {
			THIS_IS_AN_ORDINARY_PROBLEM;
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(p));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible)); /* screened out at definition time */
			Problems::issue_problem_segment(
				"In the line %1, '%2' ought to be a value, but isn't - there must be "
				"something fishy about the way it was created. %P"
				"Usually this happens because it is one of the named items in "
				"a phrase definition, but stood for a chunk of text which can't "
				"be a value - for instance, 'To marvel at (feat - an action)' "
				"doesn't make 'feat' a value. (Calling it a 'stored action' "
				"would have been fine; and similarly, if you want something "
				"which is either true or false, use 'truth state' not 'condition'.)");
			Problems::issue_problem_end();
			return NEVER_MATCH;
		}
	}

@h Rule (5.e).
The "main rule" is, as we shall see, that |p| should have the same
species as |expected|, or if |expected| give no species then at least it
should have the same family. The two exceptional cases are when |expected|
is a description such as "an even number", or the name of a kind of value
such as "a scene", in which case we allow |p| if it's a value which
meets these requirements.

@<Step (5.e) The Main Rule of Type-Checking@> =
	int exceptional_case = FALSE;
	@<Step (5.e.2) Exception: when expecting a generic or actual CONSTANT@>;
	if (exceptional_case == FALSE) @<Step (5.e.3) Main rule@>;

@ Now for the related, but slightly simpler, case of matching the name of a
kind. Suppose we are parsing "award 5 points" against

>> To award (N - a number) points: ...

Here |p| will be the actual constant value 5, and |expected| the
generic constant value with kind "number".

A phrase which returns a value must have its own return value's kind
checked. Unfortunately we can't do that yet: we want to wait until
recursive type-checking has removed incorrect invocations before drawing a
conclusion about the return kind of the phrase.

@<Step (5.e.2) Exception: when expecting a generic or actual CONSTANT@> =
	LOG_DASH("(5.e.2)");
	if ((kind_expected) && (Specifications::is_value(p))) {
		if (Node::is(p, PHRASE_TO_DECIDE_VALUE_NT)) {
			LOGIF(MATCHING, "(5.e.2) exempting phrase from return value checking for now\n");
		} else {
			switch (Kinds::compatible(
				Specifications::to_kind(p),
				kind_expected)) {
				case NEVER_MATCH:
					@<Fail with a mismatched value problem message@>;
				case SOMETIMES_MATCH:
					outcome = SOMETIMES_MATCH;
					LOGIF(MATCHING, "dropping to sometimes level\n");
					return outcome;
					break;
				case ALWAYS_MATCH: break;
			}
		}
		exceptional_case = TRUE;
	}

@ This is the error message a typical C compiler's type-checker would issue;
it says the value has the wrong kind.

@<Fail with a mismatched value problem message@> =
	THIS_IS_AN_ORDINARY_PROBLEM;
	LOG("Offending subtree: $T\n", p);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	Problems::quote_kind(3, kind_expected);

	if (Node::is(p, LOCAL_VARIABLE_NT)) {
		local_variable *lvar = Node::get_constant_local_variable(p);
		Problems::quote_kind(4, LocalVariables::kind(lvar));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LocalMismatch));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is a temporary name for %4 (created by 'let' "
			"or 'repeat'), whereas I was expecting to find %3 there.");
		Problems::issue_problem_end();
	} else if (Kinds::eq(kind_expected, K_sayable_value)) {
		Problems::quote_kind(4, Specifications::to_kind(p));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_AllSayInvsFailed));
		if (Wordings::empty(Node::get_text(p)))
			Problems::issue_problem_segment(
				"You wrote %1, but that only works for sayable values, that is, "
				"values which I can display in text form. '%2' isn't one of those "
				"values: it's %4, a kind which isn't sayable.");
		else
			Problems::issue_problem_segment(
				"You wrote %1, but that only works for sayable values, that is, "
				"values which I can display in text form. This isn't one of those "
				"values: it's %4, a kind which isn't sayable.");
		Problems::issue_problem_end();
	} else {
		LOG("Found: %u; Expected: %u\n", Specifications::to_kind(p),
			kind_expected);
		Problems::quote_kind(4, Specifications::to_kind(p));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TypeMismatch));
		if (Wordings::empty(Node::get_text(p)))
			Problems::issue_problem_segment(
				"You wrote %1, but that has the wrong kind of value: %4 rather than %3.");
		else
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' has the wrong kind of value: %4 rather than %3.");
		Problems::issue_problem_end();
	}
	return NEVER_MATCH;

@ We now apply the main rule, supposing that neither of the exceptional cases
has intervened to stop us getting here. The found and expected specifications
must have the same family and, unless the expected species is |UNKNOWN_NT|, the
same species as well.

@<Step (5.e.3) Main rule@> =
	LOG_DASH("(5.e.3)");
	if ((kind_expected) || (condition_context)) {
		int condition_found = FALSE;
		if (Specifications::is_condition(p)) condition_found = TRUE;
		if (condition_found != condition_context) {
			if ((Specifications::is_description(p)) && (kind_expected))
				@<Fail with a warning about literal descriptions@>
			else
				@<Fail with a catch-all typechecking problem message@>;
		}
	}

@<Fail with a warning about literal descriptions@> =
	if (Descriptions::is_complex(p)) {
		THIS_IS_AN_INTERESTING_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(p));
			Problems::quote_kind(3, kind_expected);
			Problems::quote_kind_of(4, p);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GenericDescription));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is used in a context where I'd expect to see "
				"a (single) specific example of %3. Although what you wrote did "
				"make sense as a description, it could refer to many different "
				"values or to none, so it wasn't specific enough.");
			Problems::issue_problem_end();
		}
	} else {
		THIS_IS_AN_INTERESTING_PROBLEM {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(p));
			Problems::quote_kind(3, kind_expected);
			Problems::quote_kind_of(4, p);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_LiteralDescriptionAsValue));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is used in a context where I'd expect to see "
				"a (single) specific example of %3, not a description.");
			if ((Specifications::is_kind_like(p)) &&
				(Kinds::eq(Specifications::to_kind(p), K_time)))
				Problems::issue_problem_segment(
					" %P(If you meant the current time, this is called 'time "
					"of day' in Inform to avoid confusing it with the various "
					"other meanings that the word 'time' can have.)");
			Problems::issue_problem_end();
		}
	}
	return NEVER_MATCH;

@ This is the general-purpose Problem message to which the type-checker
resorts when it has nothing more specific to say.

@<Fail with a catch-all typechecking problem message@> =
	THIS_IS_AN_ORDINARY_PROBLEM;

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(p));
	Problems::quote_kind(3, kind_expected);
	Problems::quote_kind_of(4, p);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible)); /* at any rate I haven't seen it lately */
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' seems to be %4, whereas I was expecting to "
		"find %3 there.");
	Problems::issue_problem_end();
	return NEVER_MATCH;

@h Ambiguity testing flags.
To avoid filling the parse tree with unnecessary annotations, we apply these
only when resolving ambiguities, in (4A) above.

@d PASSED_DASHFLAG					0x00000001 /* once type-checked: did this pass type checking? */
@d UNPROVEN_DASHFLAG				0x00000002 /* once type-checked: will this need run-time checking? */
@d GROSSLY_FAILED_DASHFLAG			0x00000004 /* once type-checked: oh, this one failed big time */
@d TESTED_DASHFLAG					0x00000008 /* has been type-checked */
@d INTERESTINGLY_FAILED_DASHFLAG	0x00000010 /* an interesting problem message could be produced about the way this failed */

=
int Dash::reading_passed(parse_node *p) {
	if (Dash::test_flag(p, PASSED_DASHFLAG)) return TRUE;
	else if (Dash::test_flag(p, TESTED_DASHFLAG)) return FALSE;
	return NOT_APPLICABLE;
}

char *Dash::verdict_to_text(parse_node *p) {
	if (p == NULL) return "(no node)";
	char *verdict = "untested";
	if (Dash::test_flag(p, TESTED_DASHFLAG))        		verdict = "failed";
	if (Dash::test_flag(p, INTERESTINGLY_FAILED_DASHFLAG))	verdict = "interesting";
	if (Dash::test_flag(p, GROSSLY_FAILED_DASHFLAG)) 		verdict = "gross";
	if (Dash::test_flag(p, PASSED_DASHFLAG))         		verdict = "proven";
	if (Dash::test_flag(p, UNPROVEN_DASHFLAG))       		verdict = "unproven";
	return verdict;
}

char *Dash::quick_verdict_to_text(parse_node *p) {
	if (p == NULL) return "?";
	char *verdict = "-";
	if (Dash::test_flag(p, TESTED_DASHFLAG))         		verdict = "f";
	if (Dash::test_flag(p, INTERESTINGLY_FAILED_DASHFLAG))	verdict = "i";
	if (Dash::test_flag(p, GROSSLY_FAILED_DASHFLAG)) 		verdict = "g";
	if (Dash::test_flag(p, PASSED_DASHFLAG))         		verdict = "p";
	if (Dash::test_flag(p, UNPROVEN_DASHFLAG))       		verdict = "u";
	return verdict;
}

@ The bitmap holding the results of typechecking:

=
void Dash::set_flag(parse_node *p, int flag) {
	if (p == NULL) internal_error("tried to set flag for null p");
	int bm = Annotations::read_int(p, epistemological_status_ANNOT);
	Annotations::write_int(p, epistemological_status_ANNOT, bm | flag);
}

void Dash::clear_flags(parse_node *p) {
	if (p == NULL) internal_error("tried to clear flags for null p");
	Annotations::write_int(p, epistemological_status_ANNOT, 0);
}

void Dash::clear_flag(parse_node *p, int flag) {
	if (p == NULL) internal_error("tried to clear flag for null p");
	int bm = Annotations::read_int(p, epistemological_status_ANNOT);
	Annotations::write_int(p, epistemological_status_ANNOT, bm & (~flag));
}

int Dash::test_flag(parse_node *p, int flag) {
	int bm = (p)?(Annotations::read_int(p, epistemological_status_ANNOT)):0;
	if (bm & flag) return TRUE;
	return FALSE;
}

@ A convenience sometimes needed for checking conditional clauses, like the
"when..." attached to action patterns:

=
int Dash::validate_conditional_clause(parse_node *spec) {
	if (spec == NULL) return TRUE;
	if (Node::is(spec, UNKNOWN_NT)) return FALSE;
	if (Dash::check_condition(spec) == NEVER_MATCH) return FALSE;
	return TRUE;
}

@ The exceptional treatment of the "property" kind below is to allow
"examining scenery" to be an action pattern, where an either/or property
has a name which is really a noun rather than an adjective, luring people
into treating it as such.

=
parse_node *last_spec_failing_to_validate = NULL;
kind *last_kind_failing_to_validate = NULL;
kind *last_kind_found_failing_to_validate = NULL;

void Dash::clear_validation_case(void) {
	last_spec_failing_to_validate = NULL;
	last_kind_failing_to_validate = NULL;
	last_kind_found_failing_to_validate = NULL;
}

int Dash::get_validation_case(parse_node **spec, kind **set_K,
	kind **set_K2) {
	*spec = last_spec_failing_to_validate;
	*set_K = last_kind_failing_to_validate;
	*set_K2 = last_kind_found_failing_to_validate;
	if ((*spec == NULL) || (*set_K == NULL)) return FALSE;
	return TRUE;
}

int Dash::validate_parameter(parse_node *spec, kind *K) {
	parse_node *vts;
	kind *kind_found = NULL;
	if (spec == NULL) return TRUE;
	if (Node::is(spec, UNKNOWN_NT)) goto DontValidate;

	if (Specifications::is_description(spec)) {
		pcalc_prop *prop = Descriptions::to_proposition(spec);
		if ((prop) && (Binding::number_free(prop) != 1)) return FALSE;
	}

	if (Specifications::is_description(spec)) Dash::check_condition(spec);
	else Dash::check_value(spec, NULL); /* to force a generic return kind to be evaluated */
	kind_found = Specifications::to_kind(spec);
	if ((Kinds::get_construct(kind_found) == CON_property) && (Kinds::Behaviour::is_object(K)))
		return TRUE;
	if ((K_understanding) && (Kinds::eq(kind_found, K_snippet)) &&
		(Kinds::eq(K, K_understanding)))
		return TRUE;
	if ((K_understanding) && (Kinds::eq(K, K_understanding)) &&
		(Node::is(spec, CONSTANT_NT) == FALSE) &&
		(Kinds::eq(kind_found, K_text)))
		goto DontValidate;
	vts = Specifications::from_kind(K);
	if (Dash::compatible_with_description(spec, vts) == NEVER_MATCH) {
		if ((K_understanding) && (Kinds::eq(K, K_understanding)) && (Node::is(spec, CONSTANT_NT))) {
			vts = Specifications::from_kind(K_snippet);
			if (Dash::compatible_with_description(spec, vts) != NEVER_MATCH) return TRUE;
		}
		if (Kinds::eq(kind_found, K_value)) return TRUE; /* pick up later in type-checking */
		goto DontValidate;
	}
	return TRUE;

	DontValidate:
		last_spec_failing_to_validate = Node::duplicate(spec);
		last_kind_failing_to_validate = K;
		last_kind_found_failing_to_validate = kind_found;
		return FALSE;
}

@ This is the state of the |***| pseudo-phrase used for debugging:

=
int verbose_checking_state = FALSE;
linked_list *packages_to_log_inter_from = NULL;

void Dash::tracing_phrases(inchar32_t *text) {
	if ((text) && (text[0])) {
		TEMPORARY_TEXT(LT)
		WRITE_TO(LT, "%w", text);
		if (Str::eq_insensitive(LT, I"inter")) {
			inter_package *pack = Functions::package_being_compiled();
			if (pack) {
				if (packages_to_log_inter_from == NULL)
					packages_to_log_inter_from = NEW_LINKED_LIST(inter_package);
				ADD_TO_LINKED_LIST(pack, inter_package, packages_to_log_inter_from);
			}
		} else {
			Log::set_aspect_from_command_line(LT, FALSE);
		}
		DISCARD_TEXT(LT)
		verbose_checking_state = TRUE;
	} else {
		verbose_checking_state = (verbose_checking_state)?FALSE:TRUE;
		if (verbose_checking_state == FALSE) {
			Log::set_all_aspects(FALSE);
		} else {
			Log::set_aspect(MATCHING_DA, TRUE);
			Log::set_aspect(KIND_CHECKING_DA, TRUE);
			Log::set_aspect(LOCAL_VARIABLES_DA, TRUE);
		}
	}
}

linked_list *Dash::phrases_to_log(void) {
	return packages_to_log_inter_from;
}

@h Value checking.
The following adapts the above test to attempt to match two specifications
together: for example, to match "12" against "even number". This, rather
surprisingly, returns |SOMETIMES_MATCH|, since we find that the kinds
are guaranteed -- 12 is indeed a number -- but Inform doesn't "know" the
meaning of the word "even", only that it's a test which will be applied
at run time.

=
int Dash::compatible_with_description(parse_node *from_spec, parse_node *to_spec) {
	LOGIF(KIND_CHECKING, "[Can we match from: $P to: $P?]\n", from_spec, to_spec);

	kind *from = Specifications::to_kind(from_spec);
	kind *to = Specifications::to_kind(to_spec);

	int result = NEVER_MATCH;
	if ((from) && (to)) result = Kinds::compatible(from, to);
	else if (to) result = SOMETIMES_MATCH;

	if ((Descriptions::is_qualified(to_spec)) || (Descriptions::to_instance(to_spec)))
		result = Dash::worst_case(result, SOMETIMES_MATCH);

	switch(result) {
		case ALWAYS_MATCH:    LOGIF(KIND_CHECKING, "[Always]\n"); break;
		case SOMETIMES_MATCH: LOGIF(KIND_CHECKING, "[Sometimes]\n"); break;
		case NEVER_MATCH:     LOGIF(KIND_CHECKING, "[Never]\n"); break;
	}
	return result;
}

@h Ambiguous alternatives.

@d AMBIGUITY_JOIN_SYNTAX_CALLBACK Dash::ambiguity_join

=
int Dash::ambiguity_join(parse_node *existing, parse_node *reading) {
	if ((Specifications::is_phrasal(reading)) &&
		(Node::get_type(reading) == Node::get_type(existing))) {
		Dash::add_pr_inv(existing, reading);
		return TRUE;
	}
	return FALSE;
}

void Dash::add_pr_inv(parse_node *E, parse_node *reading) {
	for (parse_node *N = reading->down->down, *next_N = (N)?(N->next_alternative):NULL; N;
		N = next_N, next_N = (N)?(N->next_alternative):NULL)
		Dash::add_single_pr_inv(E, N);
}

void Dash::add_single_pr_inv(parse_node *E, parse_node *N) {
	E = E->down->down;
	if (Invocations::same_phrase_and_tokens(E, N)) return;
	while ((E) && (E->next_alternative)) {
		E = E->next_alternative;
		if (Invocations::same_phrase_and_tokens(E, N)) return;
	}
	E->next_alternative = N; N->next_alternative = NULL;
}

@h Internal testing.

=
void Dash::perform_dash_internal_test(OUTPUT_STREAM, struct internal_test_case *itc) {
	int full = FALSE;
	wording W = itc->text_supplying_the_case;
	@<Perform a Dash internal test@>;
}

void Dash::perform_dashlog_internal_test(OUTPUT_STREAM, struct internal_test_case *itc) {
	int full = TRUE;
	wording W = itc->text_supplying_the_case;
	@<Perform a Dash internal test@>;
}

@<Perform a Dash internal test@> =
	kind *K = NULL;
	parse_node *test_tree = NULL, *last_alt = NULL;
	<s-value-uncached>->multiplicitous = TRUE;
	<s-value-uncached>->ins.watched = TRUE;
	int n = 0;
	while (Wordings::nonempty(W)) {
		wording T = W;
		if (<phrase-with-comma-notation>(W)) {
			T = GET_RW(<phrase-with-comma-notation>, 1);
			W = GET_RW(<phrase-with-comma-notation>, 2);
		} else W = EMPTY_WORDING;
		if (<k-kind>(T)) K = <<rp>>;
		else if (<s-value-uncached>(T)) {
			parse_node *p = <<rp>>;
			if (last_alt) last_alt->next_alternative = p;
			else test_tree = p;
			last_alt = p;
			n++;
		} else LOG("Failed to parse: %W\n", T);
	}
	<s-value-uncached>->multiplicitous = FALSE;
	<s-value-uncached>->ins.watched = FALSE;
	if (n > 1) {
		parse_node *holder = Node::new(AMBIGUITY_NT);
		holder->down = test_tree;
		test_tree = holder;
	}
	LOG("$m\n", test_tree);
	if (K) {
		LOG("Dash: value of kind %u\n", K);
		if (full) Dash::tracing_phrases(NULL);
		int rv = Dash::check_value(test_tree, K);
		char *trv = "ALWAYS";
		if (rv == SOMETIMES_MATCH) trv = "SOMETIMES";
		if (rv == NEVER_MATCH) trv = "NEVER";
		LOG("Result: %s\n", trv);
		if (full) Dash::tracing_phrases(NULL);
		LOG("$m\n", test_tree);
	}
