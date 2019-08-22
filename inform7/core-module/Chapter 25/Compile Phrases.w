[Routines::Compile::] Compile Phrases.

Phrases defined with a list of invocations, rather than inline,
have to be compiled to I6 routines, and this is where we organise that.

@h Definitions.

@ The nature of the phrase currently being compiled provides a sort of
context for how we read the definition -- for example, that it makes no
sense to write "end the action" in a phrase which isn't an action-based
rule. So we keep track of this. Note that one phrase definition cannot
contain another, so there is never any need to recursively compile phrases.

= (early code)
phrase *phrase_being_compiled = NULL; /* phrase whose definition is being compiled */

@ This routine sits at the summit of a mountain of code: it compiles a
non-line phrase definition into a routine. Note once again that a single
phrase can be compiled multiple times, with different kinds. For example,

>> To grasp (V - a value): say "I see, [V]."

might be compiled once in a form where V was a text, and another time where
it was a number. The form needed is included in the request |req|, which
should always be supplied for "To..." phrases, but left null for rules.

=
void Routines::Compile::routine(phrase *ph,
	stacked_variable_owner_list *legible, to_phrase_request *req,
	applicability_condition *acl) {

	if ((ph->declaration_node == NULL) ||
		(ParseTree::get_type(ph->declaration_node) != ROUTINE_NT) ||
		(Wordings::empty(ParseTree::get_text(ph->declaration_node))))
		internal_error("tried to compile phrase with bad ROUTINE node");
	LOGIF(PHRASE_COMPILATION, "Compiling phrase:\n$T", ph->declaration_node);

	Modules::set_current(ph->declaration_node);
	phrase_being_compiled = ph;
	@<Set up the stack frame for this compilation request@>;

	@<Compile some commentary about the routine to follow@>;

	packaging_state save = Routines::begin_framed(Routines::Compile::iname(ph, req), &(ph->stack_frame));

	@<Compile the body of the routine@>;

	Routines::end(save);

	phrase_being_compiled = NULL;
	current_sentence = NULL;
	Modules::set_current(NULL);
}

@<Compile some commentary about the routine to follow@> =
	heading *definition_area =
		Sentences::Headings::of_wording(ParseTree::get_text(ph->declaration_node));
	extension_file *definition_extension =
		Sentences::Headings::get_extension_containing(definition_area);
	if (definition_extension)
		Extensions::Files::write_I6_comment_describing(definition_extension);
	Routines::ToPhrases::comment_on_request(req);
	Phrases::Usage::write_I6_comment_describing(&(ph->usage_data));

@<Set up the stack frame for this compilation request@> =
	ph_stack_frame *phsf = &(ph->stack_frame);
	ph_type_data *phtd = &(ph->type_data);
	Frames::make_current(phsf);

	kind *version_kind = NULL;
	if (req) version_kind = Routines::ToPhrases::kind_of_request(req);
	else version_kind = Phrases::TypeData::kind(phtd);
	Phrases::TypeData::into_stack_frame(phsf, phtd, version_kind, FALSE);

	if (req) Frames::set_kind_variables(phsf,
		Routines::ToPhrases::kind_variables_for_request(req));
	else Frames::set_kind_variables(phsf, NULL);

	Frames::set_stvol(phsf, legible);

	LocalVariables::deallocate_all(phsf); /* in case any are left from an earlier compile */
	ExParser::warn_expression_cache(); /* that local variables may have changed */

@<Compile the body of the routine@> =
	current_sentence = ph->declaration_node;
	if (Phrases::Context::compile_test_head(ph, acl) == FALSE) {
		if (ph->declaration_node) {
			ParseTree::verify_structure(ph->declaration_node);
			Routines::Compile::code_block_outer(1, ph->declaration_node->down);
			ParseTree::verify_structure(ph->declaration_node);
		}
		current_sentence = ph->declaration_node;
		Phrases::Context::compile_test_tail(ph, acl);

		@<Compile a terminal return statement@>;
	}

@ In I6, all routines return a value, and if execution runs into the |]| end
marker without any return being made then the routine returns |false| if the
routine is a property value, |true| otherwise. That convention is unhelpful
to us, so we end our routine with code which certainly performs a return.

@<Compile a terminal return statement@> =
	Emit::inv_primitive(Produce::opcode(RETURN_BIP));
	Emit::down();
	kind *K = Frames::get_kind_returned();
	if (K) {
		if (Kinds::RunTime::emit_default_value_as_val(K, EMPTY_WORDING,
			"value decided by this phrase") != TRUE) {
			Problems::Issue::sentence_problem(_p_(PM_DefaultDecideFails),
				"it's not possible to decide such a value",
				"so this can't be allowed.");
			Emit::val(K_number, LITERAL_IVAL, 0);
		}
	} else {
		Emit::val(K_number, LITERAL_IVAL, 0); /* that is, return "false" */
	}
	Emit::up();

@ The name of our I6 routine depends not only on the phrase but also on the
request made for its compilation -- this enables the text version of a
phrase to be different from the number version, and so on.

=
inter_name *Routines::Compile::iname(phrase *ph, to_phrase_request *req) {
	if (req) return req->req_iname;
	return Phrases::iname(ph);
}

@ =
int disallow_let_assignments = FALSE;
int Routines::Compile::disallow_let(void) {
	return disallow_let_assignments;
}

void Routines::Compile::code_block_outer(int statement_count, parse_node *pn) {
	Routines::Compile::code_block(statement_count, pn, TRUE);
}

int Routines::Compile::code_block(int statement_count, parse_node *pn, int top_level) {
	if (pn) {
		int m = <s-value-uncached>->multiplicitous;
		<s-value-uncached>->multiplicitous = TRUE;
		if (ParseTree::get_type(pn) != CODE_BLOCK_NT) internal_error("not a code block");
		if ((top_level == FALSE) && (pn->down) && (pn->down->next == NULL) && (pn->down->down == NULL))
			disallow_let_assignments = TRUE;
		for (parse_node *p = pn->down; p; p = p->next) {
			statement_count = Routines::Compile::code_line(statement_count, p);
		}
		disallow_let_assignments = FALSE;
		<s-value-uncached>->multiplicitous = m;
	}
	return statement_count;
}

int Routines::Compile::code_line(int statement_count, parse_node *p) {
	control_structure_phrase *csp = ParseTree::get_control_structure_used(p);
	parse_node *to_compile = p;
	if (Sentences::RuleSubtrees::opens_block(csp)) {
		Frames::Blocks::beginning_block_phrase(csp);
		to_compile = p->down;
	}
	statement_count++;
	@<Compile a comment about this line@>;
	int L = Emit::level();
	@<Compile the head@>;
	@<Compile the midriff@>;
	@<Compile the tail@>;
	return statement_count;
}

@<Compile a comment about this line@> =
	if (Wordings::nonempty(ParseTree::get_text(to_compile))) {
		TEMPORARY_TEXT(C);
		WRITE_TO(C, "[%d: ", statement_count);
		CompiledText::comment(C, ParseTree::get_text(to_compile));
		WRITE_TO(C, "]");
		Emit::code_comment(C);
		DISCARD_TEXT(C);
	}

@<Compile the head@> =
	if (csp == say_CSP) {
		current_sentence = to_compile;
		@<Compile a say head@>;
	}

@<Compile a say head@> =
	for (parse_node *say_node = p->down, *prev_sn = NULL; say_node; prev_sn = say_node, say_node = say_node->next) {
		ExParser::parse_say_term(say_node);
		parse_node *inv = Invocations::first_in_list(say_node->down);
		if (inv) {
			if (prev_sn) {
				if ((ParseTree::get_say_verb(inv)) ||
					(ParseTree::get_say_adjective(inv)) ||
					((Phrases::TypeData::is_a_say_phrase(ParseTree::get_phrase_invoked(inv))) &&
						(ParseTree::get_phrase_invoked(inv)->type_data.as_say.say_phrase_running_on)))
					ParseTree::annotate_int(prev_sn, suppress_newlines_ANNOT, TRUE);
			}
		}
	}
	Emit::inv_primitive(Produce::opcode(STORE_BIP)); /* warn the paragraph breaker: this will print */
	Emit::down();
		Emit::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		Emit::val(K_number, LITERAL_IVAL, 1);
	Emit::up();
	Routines::Compile::verify_say_node_list(p->down);

@<Compile the midriff@> =
	if (ParseTree::get_type(to_compile) == INVOCATION_LIST_SAY_NT) @<Compile a say term midriff@>
	else if (csp == now_CSP) @<Compile a now midriff@>
	else if (csp == if_CSP) @<Compile an if midriff@>
	else if (csp == switch_CSP) @<Compile a switch midriff@>
	else if ((csp != say_CSP) && (csp != instead_CSP)) {
		if (<named-rulebook-outcome>(ParseTree::get_text(to_compile)))
			@<Compile a named rulebook outline midriff@>
		else @<Compile a standard midriff@>;
	}

@<Compile a say term midriff@> =
	BEGIN_COMPILATION_MODE;
	if (ParseTree::int_annotation(to_compile, suppress_newlines_ANNOT))
		COMPILATION_MODE_EXIT(IMPLY_NEWLINES_IN_SAY_CMODE);
	Routines::Compile::line(to_compile, TRUE, INTER_VOID_VHMODE);
	END_COMPILATION_MODE;

@ In fact, "now" propositions are never empty, but there's nothing in
principle wrong with asserting that the universally true proposition is
henceforth to be true, so we simply compile empty code in that case.

@<Compile a now midriff@> =
	current_sentence = to_compile;
	wording XW = ParseTree::get_text(p->down);
	parse_node *cs = NULL;
	if (<s-condition>(XW)) cs = <<rp>>; else cs = Specifications::new_UNKNOWN(XW);
	LOGIF(MATCHING, "Now cond is $T\n", cs);
	int rv = Dash::check_condition(cs);
	LOGIF(MATCHING, "After Dash, it's $T\n", cs);

	if (ParseTree::is(cs, TEST_PROPOSITION_NT)) {
		if (rv != NEVER_MATCH) {
			pcalc_prop *prop = Specifications::to_proposition(cs);
			if (prop) {
				BEGIN_COMPILATION_MODE;
				COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
				Calculus::Deferrals::emit_now_proposition(prop);
				END_COMPILATION_MODE;
			}
		}
	} else if (ParseTreeUsage::is_condition(cs))
		@<Issue a problem message for the wrong sort of condition in a "now"@>
	else if (rv != NEVER_MATCH) @<Issue a problem message for an unrecognised condition@>;

@ A deluxe problem message.

@<Issue a problem message for the wrong sort of condition in a "now"@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, ParseTree::get_text(cs));
	if (ParseTree::is(cs, TEST_VALUE_NT)) {
		Problems::Issue::handmade_problem(_p_(PM_BadNow1));
		Problems::issue_problem_segment(
			"You wrote %1, but although '%2' is a condition which it is legal "
			"to test with 'if', 'when', and so forth, it is not something I "
			"can arrange to happen on request. Whether it is true or not "
			"depends on current circumstances: so to make it true, you will "
			"need to adjust those circumstances.");
		Problems::issue_problem_end();
	} else if (ParseTree::is(cs, LOGICAL_AND_NT)) {
		Problems::Issue::handmade_problem(_p_(PM_BadNow2));
		Problems::issue_problem_segment(
			"You wrote %1, but 'now' does not work with the condition '%2' "
			"because it can only make one wish come true at a time: so it "
			"doesn't like the 'and'. Try rewriting as two 'now's in a row?");
		Problems::issue_problem_end();
	} else {
		Problems::Issue::handmade_problem(_p_(PM_BadNow3));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2'	isn't the sort of condition which can be "
			"made to be true, in the way that 'the ball is on the table' can be "
			"made true with a straightforward movement of one object (the ball).");
		Problems::issue_problem_end();
	}

@<Issue a problem message for an unrecognised condition@> =
	LOG("$T\n", current_sentence);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, ParseTree::get_text(cs));
	Problems::Issue::handmade_problem(_p_(...));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2'	isn't a condition, so I can't see how to "
		"make it true from here on.");
	Problems::issue_problem_end();

@<Issue a problem message for an unrecognised action@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, ParseTree::get_text(cs));
	Problems::Issue::handmade_problem(_p_(...));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2'	isn't an action, so I can't see how to try it.");
	Problems::issue_problem_end();

@<Compile a named rulebook outline midriff@> =
	current_sentence = to_compile;
	named_rulebook_outcome *nrbo = <<rp>>;
	if (phrase_being_compiled) {
		int ram = Phrases::Usage::get_effect(&(phrase_being_compiled->usage_data));
		if ((ram != RULE_IN_RULEBOOK_EFF) &&
			(ram != RULE_NOT_IN_RULEBOOK_EFF)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, ParseTree::get_text(to_compile));
			Problems::Issue::handmade_problem(_p_(PM_MisplacedRulebookOutcome2));
			Problems::issue_problem_segment(
				"You wrote %1, but this is a rulebook outcome which can only be used "
				"within rulebooks which recognise it. You've used it in a definition "
				"which isn't for use in rulebooks at all, so it must be wrong here.");
			Problems::issue_problem_end();
		}
	}
	rulebook *rb = Rulebooks::Outcomes::allow_outcome(nrbo);
	if (rb) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(to_compile));
		Problems::quote_wording(3, rb->primary_name);
		Problems::Issue::handmade_problem(_p_(PM_MisplacedRulebookOutcome));
		Problems::issue_problem_segment(
			"You wrote %1, but this is a rulebook outcome which can only be used "
			"within rulebooks which recognise it. You've used it in a rule which "
			"has to be listed in the '%3' rulebook, where '%2' doesn't have a meaning.");
		Problems::issue_problem_end();
	}
	Rulebooks::Outcomes::compile_outcome(nrbo);

@<Compile an if midriff@> =
	if (p->down->next->next) Emit::inv_primitive(Produce::opcode(IFELSE_BIP));
	else Emit::inv_primitive(Produce::opcode(IF_BIP));
	Emit::down();
		current_sentence = to_compile;
		Routines::Compile::line(to_compile, FALSE, INTER_VAL_VHMODE);

		Emit::code();
		Emit::down();
			Frames::Blocks::open_code_block();
			statement_count = Routines::Compile::code_block(statement_count, p->down->next, FALSE);
		if (p->down->next->next) {
		Emit::up();
		Emit::code();
		Emit::down();
			Frames::Blocks::divide_code_block();
			statement_count = Routines::Compile::code_block(statement_count, p->down->next->next, FALSE);
		}
			Frames::Blocks::close_code_block();
		Emit::up();
	Emit::up();

@<Compile a switch midriff@> =
	current_sentence = to_compile;
	Routines::Compile::line(to_compile, FALSE, INTER_VOID_VHMODE);

	Frames::Blocks::open_code_block();

	parse_node *val = Frames::Blocks::switch_value();
	if (val == NULL) internal_error("no switch value");
	kind *switch_kind = Specifications::to_kind(val);
	int pointery = FALSE;
	inter_symbol *sw_v = NULL;

	if (Kinds::Behaviour::uses_pointer_values(switch_kind)) pointery = TRUE;

	LOG("Switch val is $T for kind $u pointery %d\n", val, switch_kind, pointery);

	local_variable *lvar = NULL;
	int downs = 0;

	if (pointery) {
		lvar = LocalVariables::add_switch_value(K_value);
		sw_v = LocalVariables::declare_this(lvar, FALSE, 7);
		Emit::inv_primitive(Produce::opcode(STORE_BIP));
		Emit::down();
			Emit::ref_symbol(K_value, sw_v);
			Specifications::Compiler::emit_as_val(switch_kind, val);
		Emit::up();
	} else {
		Emit::inv_primitive(Produce::opcode(SWITCH_BIP));
		Emit::down();
			Specifications::Compiler::emit_as_val(switch_kind, val);
			Emit::code();
			Emit::down();
	}

			int c = 0;
			for (parse_node *ow_node = p->down->next->next; ow_node; ow_node = ow_node->next, c++) {
				current_sentence = ow_node;
				Frames::Blocks::divide_code_block();

				if (ParseTree::get_control_structure_used(ow_node) == default_case_CSP) {
					if (pointery) @<Handle a pointery default@>
					else @<Handle a non-pointery default@>;
				} else {
					if (<s-type-expression-or-value>(ParseTree::get_text(ow_node))) {
						parse_node *case_spec = <<rp>>;
						case_spec = NonlocalVariables::substitute_constants(case_spec);
						ParseTree::set_evaluation(ow_node, case_spec);
						if (Dash::check_value(case_spec, NULL) != NEVER_MATCH) {
							kind *case_kind = Specifications::to_kind(case_spec);
							instance *I = Rvalues::to_object_instance(case_spec);
							if (I) case_kind = Instances::to_kind(I);
							LOGIF(MATCHING, "(h.3) switch kind is $u, case kind is $u\n", switch_kind, case_kind);
							if ((ParseTree::get_kind_of_value(case_spec) == NULL) && (I == NULL)) {
								Problems::quote_source(1, current_sentence);
								Problems::quote_kind(2, switch_kind);
								Problems::Issue::handmade_problem(_p_(PM_CaseValueNonConstant));
								Problems::issue_problem_segment(
									"The case %1 is required to be a constant value, rather than "
									"something which has different values at different times: "
									"specifically, it has to be %2.");
								Problems::issue_problem_end();
								case_spec = Rvalues::new_nothing_object_constant();
							} else if (Kinds::Compare::compatible(case_kind, switch_kind) != ALWAYS_MATCH) {
								Problems::quote_source(1, current_sentence);
								Problems::quote_kind(2, case_kind);
								Problems::quote_kind(3, switch_kind);
								Problems::Issue::handmade_problem(_p_(PM_CaseValueMismatch));
								Problems::issue_problem_segment(
									"The case %1 has the wrong kind of value for the possibilities "
									"being chosen from: %2 instead of %3.");
								Problems::issue_problem_end();
								case_spec = Rvalues::new_nothing_object_constant();
							} else {
								if (pointery) @<Handle a pointery case@>
								else @<Handle a non-pointery case@>;
							}
						} else @<Issue problem message for unknown case value@>
					} else @<Issue problem message for unknown case value@>;
				}
			}

	if (pointery) {
		while (downs-- > 0) Emit::up();
		Frames::Blocks::close_code_block();
	} else {
		Emit::up();
		Frames::Blocks::close_code_block();
	Emit::up();
	}

	if (problem_count == 0)
		for (parse_node *A = p->down->next->next; A; A = A->next) {
			int dup = FALSE;
			for (parse_node *B = A->next; B; B = B->next)
				if (Rvalues::compare_CONSTANT(
					ParseTree::get_evaluation(A), ParseTree::get_evaluation(B)))
						dup = TRUE;
			if (dup) {
				current_sentence = A;
				Problems::quote_source(1, A);
				Problems::quote_spec(2, ParseTree::get_evaluation(A));
				Problems::Issue::handmade_problem(_p_(PM_CaseValueDuplicated));
				Problems::issue_problem_segment(
					"The case %1 occurs more than once in this 'if' switch.");
				Problems::issue_problem_end();
			}
		}

@<Handle a non-pointery case@> =
	Emit::inv_primitive(Produce::opcode(CASE_BIP));
	Emit::down();
		Specifications::Compiler::emit_as_val(switch_kind, case_spec);
		Emit::code();
		Emit::down();
			statement_count = Routines::Compile::code_block(statement_count, ow_node, FALSE);
		Emit::up();
	Emit::up();

@<Handle a non-pointery default@> =
	Emit::inv_primitive(Produce::opcode(DEFAULT_BIP));
	Emit::down();
		Emit::code();
		Emit::down();
			statement_count = Routines::Compile::code_block(statement_count, ow_node, FALSE);
		Emit::up();
	Emit::up();

@<Handle a pointery case@> =
	int final_flag = FALSE;
	if (ow_node->next == NULL) final_flag = TRUE;

	if (final_flag) Emit::inv_primitive(Produce::opcode(IF_BIP));
	else Emit::inv_primitive(Produce::opcode(IFELSE_BIP));
	Emit::down();
		LocalVariables::set_kind(lvar, switch_kind);
		parse_node *sw_v = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, lvar);
		pcalc_prop *prop = Calculus::Propositions::Abstract::to_set_relation(
			R_equality, NULL, sw_v, NULL, case_spec);
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
		Calculus::Deferrals::emit_test_of_proposition(NULL, prop);
		Emit::code();
		Emit::down();
			statement_count = Routines::Compile::code_block(statement_count, ow_node, FALSE);
		if (final_flag == FALSE) {
			Emit::up();
			Emit::code();
			Emit::down();
		}
	downs += 2;

@<Handle a pointery default@> =
	statement_count = Routines::Compile::code_block(statement_count, ow_node, FALSE);

@<Compile a standard midriff@> =
	current_sentence = to_compile;
	Routines::Compile::line(to_compile, FALSE, INTER_VOID_VHMODE);

@<Compile the tail@> =
	if (csp == if_CSP) @<Compile an if tail@>
	else if (csp == switch_CSP) @<Compile a switch tail@>
	else if (csp == say_CSP) @<Compile a say tail@>
	else if (csp == instead_CSP) @<Compile an instead tail@>
	else if (Sentences::RuleSubtrees::opens_block(csp)) @<Compile a loop tail@>;

@<Compile an if tail@> =
	;

@ Switch statements in I6 look much like those in C, but are written without
the ceaseless repetition of the keyword "case". Thus, |15:| does what
|case 15:| would do in C. But |default:| is the same in both.

@<Compile a switch tail@> =
	;

@<Issue problem message for unknown case value@> =
	Problems::Issue::sentence_problem(_p_(PM_CaseValueUnknown),
		"I don't recognise this case value",
		"that is, the value written after the '--'.");

@<If this is a say group, but not a say control structure, notify the paragraphing code@> =

@ As will be seen, two sets of labels and counters are kept here: see the
inline definitions for "say if" and similar.

@<Compile a say tail@> =
	statement_count = Routines::Compile::code_block(statement_count, p, FALSE);

	TEMPORARY_TEXT(SAYL);
	WRITE_TO(SAYL, ".");
	JumpLabels::write(SAYL, I"Say");
	Emit::place_label(Emit::reserve_label(SAYL));
	DISCARD_TEXT(SAYL);

	JumpLabels::read_counter(I"Say", TRUE);

	TEMPORARY_TEXT(SAYXL);
	WRITE_TO(SAYXL, ".");
	JumpLabels::write(SAYXL, I"SayX");
	Emit::place_label(Emit::reserve_label(SAYXL));
	DISCARD_TEXT(SAYXL);

	JumpLabels::read_counter(I"SayX", TRUE);

@<Compile an instead tail@> =
	Emit::rtrue();

@<Compile a loop tail@> =
	Frames::Blocks::open_code_block();
	statement_count = Routines::Compile::code_block(statement_count, p->down->next, FALSE);
	while (Emit::level() > L) Emit::up();
	Frames::Blocks::close_code_block();

@ This routine takes the text of a line from a phrase definition, parses it,
type-checks it, and finally, all being well, compiles it.

=
parse_node *void_phrase_please = NULL; /* instructions for the typechecker */

void Routines::Compile::line(parse_node *p, int already_parsed, int vhm) {
	int initial_problem_count = problem_count;

	LOGIF(EXPRESSIONS, "\n-- -- Evaluating <%W> -- --\n", ParseTree::get_text(p));

	LOGIF(EXPRESSIONS, "(a) Parsing:\n");
	if (already_parsed) {
		parse_node *inv = Invocations::first_in_list(p->down);
		if ((inv) &&
			(ParseTree::get_phrase_invoked(inv)) &&
			(Phrases::TypeData::is_a_say_phrase(ParseTree::get_phrase_invoked(inv))) &&
			(ParseTree::get_phrase_invoked(inv)->type_data.as_say.say_control_structure == NO_SAY_CS)) {
			Emit::inv_call_iname(Hierarchy::find(PARACONTENT_HL));
		}
	} else {
		ExParser::parse_void_phrase(p);
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "(b) Type checking:\n$E", p->down);
		Dash::check_invl(p);
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "(c) Compilation:\n$E", p->down);
		value_holster VH = Holsters::new(vhm);
		Invocations::Compiler::compile_invocation_list(&VH,
			p->down, ParseTree::get_text(p));
	}

	if (initial_problem_count == problem_count) {
		LOGIF(EXPRESSIONS, "-- -- Completed -- --\n");
	} else {
		LOGIF(EXPRESSIONS, "-- -- Failed -- --\n");
	}
}

@ And this is where we are:

=
parse_node *Routines::Compile::line_being_compiled(void) {
	if (phrase_being_compiled) return current_sentence;
	return NULL;
}

@h Validation of invocations.
Recall that a complex text such as:

>> "Platinum is shinier than [if a Colony is in the Supply Pile]gold[otherwise]silver."

is complied into a specification holding a list of invocations; in this case
there are five, invoking the phrases --

(1) "say [text]"
(2) "say if ..."
(3) "say [text]"
(4) "say otherwise"
(5) "say [text]"

In the following routine we check this list to see that two sorts of control
structure are correctly used. The first is "say if"; here, for instance, it
would be an error to use "say otherwise" without "say if", or to have them
the wrong way round.

The other is the SSP, the "segmented say phrase". For example:

>> "The best defence is [one of]Lighthouse[or]Moat[or]having no money[at random]."

Here there are nine invocations, and the interesting ones have to come in
the sequence "[one of]" (a start), then any number of "[or]" segments (middles),
and lastly "[at random]" (an end). SSPs can even be nested, within limits:

@d MAX_COMPLEX_SAY_DEPTH 32 /* and it would be terrible coding style to approach this */

=
int Routines::Compile::verify_say_node_list(parse_node *say_node_list) {
	int problem_issued = FALSE;
	int say_invocations_found = 0;
	@<Check that say control structures have been used in a correct sequence@>;
	return say_invocations_found;
}

@ Given correct code, the following does very little. It checks that structural
say phrases (SSPs), such as the substitutions here:

>> "Platinum is shinier than [if a Colony is in the Supply Pile]gold[otherwise]silver."

...are used correctly; for instance, that there isn't an "[otherwise]" before
the "[if...]".

It doesn't quite do nothing, though, because it also counts the say phrases found.

@<Check that say control structures have been used in a correct sequence@> =
	int it_was_not_worth_adding = it_is_not_worth_adding;
	it_is_not_worth_adding = TRUE;

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
				phrase *ph = ParseTree::get_phrase_invoked(inv);
				if ((ParseTree::get_phrase_invoked(inv)) &&
					(Phrases::TypeData::is_a_say_phrase(ph))) {
					int say_cs, ssp_tok, ssp_ctok, ssp_pos;
					Phrases::TypeData::get_say_data(&(ph->type_data.as_say),
						&say_cs, &ssp_tok, &ssp_ctok, &ssp_pos);

					if (ssp_pos == SSP_START) @<This starts a complex SSP@>;
					if (ssp_pos == SSP_MIDDLE) @<This is a middle term in a complex SSP@>;
					if (ssp_pos == SSP_END) @<This ends a complex SSP@>;

					if (say_cs == IF_SAY_CS) @<This is a say if@>;
					if ((say_cs == OTHERWISE_SAY_CS) || (say_cs == OTHERWISE_IF_SAY_CS))
						@<This is a say otherwise@>;
					if (say_cs == END_IF_SAY_CS) @<This is a say end if@>;

					say_invocations_found++;
				}
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
	it_is_not_worth_adding = it_was_not_worth_adding;

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
		ParseTree::annotate_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT,
			ParseTree::int_annotation(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT)+1);
		ParseTree::annotate_int(inv, ssp_segment_count_ANNOT,
			ParseTree::int_annotation(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT));
	} else @<Issue a problem message for middle without start@>;

@<This ends a complex SSP@> =
	if ((SSP_sp > 0) && (SSP_stack[SSP_sp-1] != -1) &&
		(compare_words(SSP_stack[SSP_sp-1], ssp_tok))) {
		ParseTree::annotate_int(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT,
			ParseTree::int_annotation(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT)+1);
		ParseTree::annotate_int(SSP_invocations[SSP_sp-1], ssp_closing_segment_wn_ANNOT, ssp_ctok);
		ParseTree::annotate_int(inv, ssp_segment_count_ANNOT,
			ParseTree::int_annotation(SSP_invocations[SSP_sp-1], ssp_segment_count_ANNOT));
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
	if (say_if_nesting == 0) @<Issue a problem message for say end if without say if@>
	else if ((SSP_sp > 0) && (SSP_stack[SSP_sp-1] != -1))
		@<Issue a problem message for say end if interleaved with another construction@>
	else {
		say_if_nesting--;
		SSP_sp--;
	}

@<Issue a problem message for middle without start@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(inv));
		Problems::Issue::handmade_problem(_p_(PM_ComplicatedSayStructure));
		Problems::issue_problem_segment(
			"In the text at %1, the text substitution '[%2]' ought to occur as the "
			"middle part of its construction, but it appears to be on its own.");
		Routines::Compile::add_say_construction_to_error(ssp_tok);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for end without start@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(inv));
		Problems::Issue::handmade_problem(_p_(PM_ComplicatedSayStructure2));
		Problems::issue_problem_segment(
			"In the text at %1, the text substitution '[%2]' ought to occur as the "
			"ending part of its construction, but it appears to be on its own.");
		Routines::Compile::add_say_construction_to_error(ssp_tok);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for nested say if@> =
	if (problem_issued == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_SayIfNested),
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
		Problems::Issue::sentence_problem(_p_(PM_SayOverComplex),
			"this is too complex a text substitution",
			"and needs to be simplified. You might find it helful to define "
			"a new text substitution of your own ('To say fiddly details: "
			"...') and then use it in this text by including the '[fiddly details]'.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say otherwise without say if@> =
	if (problem_issued == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_SayOtherwiseWithoutIf),
			"an '[otherwise]' text substitution occurs where there appears to be no "
			"[if ...]",
			"which doesn't make sense - there is nothing for it to be otherwise to.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say otherwise interleaved with another construction@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(inv));
		Problems::Issue::handmade_problem(_p_(PM_ComplicatedSayStructure5));
		Problems::issue_problem_segment(
			"In the text at %1, the '[%2]' ought to occur inside an [if ...], but "
			"is cut off because it has been interleaved with a complicated say "
			"construction.");
		Routines::Compile::add_say_construction_to_error(SSP_stack[SSP_sp-1]);
		Problems::issue_problem_end();
		problem_issued = TRUE;
	}

@<Issue a problem message for two say otherwises@> =
	if (problem_issued == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_TwoSayOtherwises),
			"there's already an (unconditional) \"[otherwise]\" or \"[else]\" "
			"in this text substitution",
			"so it doesn't make sense to follow that with a further one.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say end if without say if@> =
	if (problem_issued == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_SayEndIfWithoutSayIf),
			"an '[end if]' text substitution occurs where there appears to be no "
			"[if ...]",
			"which doesn't make sense - there is nothing for it to end.");
		problem_issued = TRUE;
	}

@<Issue a problem message for say end if interleaved with another construction@> =
	if (problem_issued == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(inv));
		Problems::Issue::handmade_problem(_p_(PM_ComplicatedSayStructure4));
		Problems::issue_problem_segment(
			"In the text at %1, the '[%2]' is cut off from its [if ...], because "
			"it has been interleaved with a complicated say construction.");
		Routines::Compile::add_say_construction_to_error(SSP_stack[SSP_sp-1]);
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
			Problems::quote_wording(2, ParseTree::get_text(stinv));
			Problems::Issue::handmade_problem(_p_(PM_ComplicatedSayStructure3));
			Problems::issue_problem_segment(
				"In the text at %1, the text substitution '[%2]' seems to start a "
				"complicated say construction, but it doesn't have a matching end.");
			if (ssp_tok >= 0) Routines::Compile::add_say_construction_to_error(ssp_tok);
			Problems::issue_problem_end();
			problem_issued = TRUE;
		}
	}

@h Problem messages for complex say constructions.

=
void Routines::Compile::add_say_construction_to_error(int ssp_tok) {
	Problems::issue_problem_segment(" %P(The construction I'm thinking of is '");
	Routines::Compile::add_scte_list(ssp_tok, SSP_START);
	Problems::issue_problem_segment(" ... ");
	Routines::Compile::add_scte_list(ssp_tok, SSP_MIDDLE);
	Problems::issue_problem_segment(" ... ");
	Routines::Compile::add_scte_list(ssp_tok, SSP_END);
	Problems::issue_problem_segment("'.)");
}

void Routines::Compile::add_scte_list(int ssp_tok, int list_pos) {
	phrase *ph; int ct = 0;
	LOOP_OVER(ph, phrase) {
		wording W;
		if (Phrases::TypeData::ssp_matches(&(ph->type_data), ssp_tok, list_pos, &W)) {
			Problems::quote_wording(3, W);
			if (ct++ == 0) Problems::issue_problem_segment("[%3]");
			else Problems::issue_problem_segment("/[%3]");
		}
	}
}
