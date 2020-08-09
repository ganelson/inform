[Invocations::Compiler::] Compile Invocations.

Here we generate Inform 6 code to execute the phrase(s) called
for by an invocation list.

@ This represents the tokens being used when invoking a phrase:

=
typedef struct tokens_packet {
	int tokens_count; /* number of arguments to phrase */
	struct parse_node *args[32]; /* what they are */
	struct kind *kind_required[32]; /* what pointer kinds of value, if they are */
	struct kind *as_requested; /* kind for the function call */
} tokens_packet;

@h Top level: compiling lists.
The invocation list will consist of at least one invocation, and all of these
except possibly the last one will be "unproven" by the type-checking
apparatus -- that is, will not be safe to execute without run-time checking.
We must execute exactly one invocation in the list -- the first one which
is found to be type-safe -- or else produce a run-time error message.

It follows that there is only one case where no checking is needed: when
the list consists of a single proven invocation. This we compile directly
to the I6 stream. In all other cases, we compile a function call to a
"resolver routine" to the I6 stream, delegating the choice to an
external routine: and we will probably have to compile this routine, too,
unless the decision on this block is one that we recognise from an
earlier invocation list (in what may be another setting entirely).

=
void Invocations::Compiler::compile_invocation_list(value_holster *VH, parse_node *invl, wording W) {
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;

	int wn = Wordings::first_wn(W);
	if (Invocations::length_of_list(invl) > 0) {
		LOGIF(MATCHING, "Compiling from %d invocations\n", Invocations::length_of_list(invl));
		source_location sl = Lexer::word_location(wn);

		if (Invocations::is_marked_to_save_self(Invocations::first_in_list(invl))) {
			Produce::inv_primitive(Emit::tree(), PUSH_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
			Produce::up(Emit::tree());
		}
		if (Invocations::is_marked_unproven(Invocations::first_in_list(invl))) {
			@<Compile using run-time resolution to choose between invocations@>;
		} else {
			@<Compile as a series of invocations all of which run@>;
		}

		if (Invocations::is_marked_to_save_self(Invocations::first_in_list(invl))) {
			Produce::inv_primitive(Emit::tree(), PULL_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
			Produce::up(Emit::tree());
		}
	}
}

@<Compile as a series of invocations all of which run@> =
	int pos = 0;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		LOGIF(MATCHING, "C%d: $e\n", pos, inv); pos++;
		if (Node::get_say_verb(inv)) {
			VerbsAtRunTime::ConjugateVerb_invoke_emit(
				Node::get_say_verb(inv),
				Node::get_modal_verb(inv),
				Annotations::read_int(inv, say_verb_negated_ANNOT));
		} else if (Node::get_say_adjective(inv)) {
			Adjectives::Meanings::emit(Node::get_say_adjective(inv));
		} else {
			@<Otherwise, use the standard way to compile an invoked phrase@>;
		}
	}

@<Otherwise, use the standard way to compile an invoked phrase@> =
	phrase *ph = Node::get_phrase_invoked(inv);
	tokens_packet tokens;
	@<First construct an arguments packet@>;
	value_holster VH2 = Holsters::new(VH->vhmode_wanted);
	int returned_in_manner =
		Invocations::Compiler::compile_single_invocation(&VH2, inv, &sl, &tokens);

	if ((phrase_being_compiled) && (returned_in_manner != DONT_KNOW_MOR))
		@<If the invocation compiled to a return from a function, check this is allowed@>;

@<First construct an arguments packet@> =
	tokens.tokens_count = Invocations::get_no_tokens_needed(inv);
	for (int i=0; i<tokens.tokens_count; i++) {
		parse_node *val = Invocations::get_token_as_parsed(inv, i);
		kind *K = Specifications::to_kind(
			ph->type_data.token_sequence[i].to_match);
		if ((Phrases::TypeData::invoked_inline(ph) == FALSE) &&
			(Kinds::Behaviour::definite(K) == FALSE))
			tokens.kind_required[i] = Specifications::to_kind(val);
		else
			tokens.kind_required[i] = K;
		if (ph->type_data.token_sequence[i].construct == KIND_NAME_PT_CONSTRUCT)
			tokens.args[i] = Rvalues::new_nothing_object_constant();
		else
			tokens.args[i] = val;
	}
	kind *return_kind = Node::get_kind_resulting(Invocations::first_in_list(invl));
	if ((return_kind == NULL) && (ph)) return_kind = ph->type_data.return_kind;
	tokens.as_requested =
		Kinds::function_kind(tokens.tokens_count, tokens.kind_required, return_kind);

@ For example, a standard "To..." phrase isn't allowed to contain the invocation

>> decide on 178;

since it isn't a phrase to decide anything. This is where that's checked:

@<If the invocation compiled to a return from a function, check this is allowed@> =
	int manner_expected = phrase_being_compiled->type_data.manner_of_return;
	if ((returned_in_manner != manner_expected) &&
		(manner_expected != DECIDES_NOTHING_AND_RETURNS_MOR)) {
		LOG("C%d: $e: returned in manner %d\n", pos, inv, returned_in_manner);
		LOG("vs Phrase being compiled: %d\n", manner_expected);
		Problems::quote_source(1, current_sentence);
		Problems::quote_text(2,
			Phrases::TypeData::describe_manner_of_return(returned_in_manner, NULL, NULL));
		kind *K = NULL;
		Problems::quote_text(3,
			Phrases::TypeData::describe_manner_of_return(manner_expected,
				&(phrase_being_compiled->type_data), &K));
		if (K) Problems::quote_kind(4, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_WrongEndToPhrase));
		if (K)
			Problems::issue_problem_segment(
				"The line %1 seems to be a way that the phrase you're defining can come "
				"to an end, with %2, but it should always end up with a phrase to "
				"decide %4.");
		else
			Problems::issue_problem_segment(
				"The line %1 seems to be a way that the phrase you're defining can come "
				"to an end, with %2, but it should always end up with %3.");
		Problems::issue_problem_end();
		return;
	}


@ We get to here if the first invocation is unproven, meaning that at compile
time it was impossible to determine whether it was type-safe to execute. We must
therefore compile code to determine this at run-time.

There are two basic forms of this: "void mode", where the phrases are going to
be Inform 6 statements in a void context, and "value mode", where the phrases
will be expressions being evaluated.

@<Compile using run-time resolution to choose between invocations@> =
	phrase *ph = Node::get_phrase_invoked(Invocations::first_in_list(invl));

	int N = Invocations::get_no_tokens(Invocations::first_in_list(invl));
	Frames::need_at_least_this_many_formals(N);

	int void_mode = FALSE;
	if (ph->type_data.manner_of_return == DECIDES_NOTHING_MOR) void_mode = TRUE;

	@<Compile the resolution@>;

@ Our basic idea is best explained in void mode, where it's much simpler to
carry out. Suppose we have invocations I1, ..., In, and tokens T1, ..., Tm.
(In a group like this, every invocation will have the same number of tokens.)
We want each invocation in turn to try to handle the situation, and to stop
as soon as one of them does. The first thought is this:
= (text)
	if (condition for I1 to be valid) invoke I1(T1, ..., Tm);
	else if (condition for I2 to be valid) invoke I2(T1, ..., Tm);
	...
	else run-time-error-message();
=
where the chain of execution runs into the error message code only if none
of I1, ..., In can be applied. In fact, it will sometimes happen that the
final invocation can be proved applicable at compile time, and then we'll
compile this instead:
= (text)
	if (condition for I1 to be valid) invoke I1(T1, ..., Tm);
	else if (condition for I2 to be valid) invoke I2(T1, ..., Tm);
	else invoke In(T1, ..., Tm);
=
Note that it's not possible for an intermediate invocation in the group to
be provably correct, because if it is then we wouldn't have collected any
further possibilities.

@ That's almost what we do, but not quite. The problem lies in the fact that
the tokens T1, ..., Tm are evaluated multiple times - not in the invocations
(since only one is reached in execution) but in the condition tests. This
multiple evaluation would be incorrect if token evaluation had side-effects,
as it easily might (for example if T1 were a call to some phrase to decide
something, and that phrase had side-effects). So in fact we modify our
scheme like so:
= (text)
	formal_par1 = T1;
	formal_par2 = T2;
	...
	if (condition for I1 to be valid) invoke I1(formal_par1, ..., formal_parm);
	else if (condition for I2 to be valid) invoke I2(formal_par1, ..., formal_parm);
	...
	else run-time-error-message();
=
This fixes the side-effect problem, provided we compile the conditions so
that they measure the "formal parameters" instead of the original T1, T2, ...
But another possible trap is that the |formal_par1|, ..., variables need
to be local to the current I6 stack frame, since evaluation of T2, say,
might itself involve a call to another phrase which recursively needs to
make a resolution itself.

Finding local storage here is more problematic than it looks. I6 has an
absolute limit on the number of local variables, imposed by the virtual
machines it runs on. We can't create any local stack space, because the
stack isn't memory-accessible on either of the VMs Inform compiles to. It's
not reliable to create an auxiliary stack in main memory, because this
couldn't resize on the Z-machine, and we want to avoid use of the heap,
because we want Inform to carry on working even in cramped Z-machine cases
where there's no memory for any heap at all. What we do, then, is to store
|formal_par1| et seq as global I6 variables, and to use an outer shell
routine to push and pull their values, thus in effect making them additional
locals, albeit at a small performance hit.

@ In value mode we want the same strategy and code paths, but all in
the context of a value.

@<Compile the resolution@> =
	if (void_mode) {
		@<Compile code to set the formal parameters in void mode@>;
		@<Compile code to apply the first invocation which is applicable@>;
	} else {
		Produce::inv_primitive(Emit::tree(), TERNARYSEQUENTIAL_BIP);
		Produce::down(Emit::tree());
			int no_conditions_tested = 0;
			int L = Produce::level(Emit::tree());
			@<Emit code to set the formal parameters in expression mode@>;
			if (L != Produce::level(Emit::tree())) internal_error("formal parameter expression error");
			int NC = 0, unprov = FALSE, prov = FALSE;
			@<Count the applicability conditions@>;
			TEMPORARY_TEXT(C) WRITE_TO(C, "Think %d unprov %d prov %d", NC, unprov, prov); Emit::code_comment(C); DISCARD_TEXT(C)
			if (unprov) { Produce::inv_primitive(Emit::tree(), OR_BIP); Produce::down(Emit::tree()); }
			@<Compile code to apply the first invocation which is applicable, as expression@>;
			for (int i = 0; i<NC-1; i++) Produce::up(Emit::tree());
			if (prov) Produce::up(Emit::tree());
			if (unprov) {
				@<Compile code for the execution path where no invocations were applicable@>;
				Produce::up(Emit::tree());
			}
			if (L != Produce::level(Emit::tree())) internal_error("applicability expression error");
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(FORMAL_RV_HL));
		Produce::up(Emit::tree());
	}

@ In void mode, this code is simple: it just produces a list of assignments:
= (text)
	formal_par1 = T1;
	formal_par2 = T2;
	...
=
@<Compile code to set the formal parameters in void mode@> =
	for (int i=0; i<N; i++) {
		@<Compile the actual assignment@>;
	}

@ In value mode, we exploit the fact that, as in C, assignments return a value
and are therefore legal in an expression context; but, again avoiding the
serial comma at the cost of a fruitless addition,
= (text)
	(formal_parn = Tn) + ... + (formal_par1 = T1)
=
Again, this is written in reverse order because I6 will evaluate this from
right to left: we want T1 to evaluate first, then T2, and so on.

@<Emit code to set the formal parameters in expression mode@> =
	for (int i=N-1; i>=0; i--) {
		if (i > 0) { Produce::inv_primitive(Emit::tree(), PLUS_BIP); Produce::down(Emit::tree()); }
		@<Compile the actual assignment@>;
	}
	for (int i=N-1; i>0; i--) Produce::up(Emit::tree());

@ A parameter corresponding to the name of a kind has no meaningful value
at run-time; we assign 0 to it for the sake of tidiness.

@<Compile the actual assignment@> =
	NonlocalVariables::temporary_formal(i);
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_value, NonlocalVariables::formal_par(i));
		if (ph->type_data.token_sequence[i].construct == KIND_NAME_PT_CONSTRUCT)
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		else {
			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_ENTER(DEREFERENCE_POINTERS_CMODE);
			parse_node *value =
				Invocations::get_token_as_parsed(Invocations::first_in_list(invl), i);
			kind *to_be_used_as = Specifications::to_kind(
				ph->type_data.token_sequence[i].to_match);
			Specifications::Compiler::emit_to_kind(value, to_be_used_as);
			END_COMPILATION_MODE;
		}
	Produce::up(Emit::tree());

@ So now we come to the part which switches the execution stream. In void mode,
it will look like so:
= (text)
	if (condition for I1 to be valid) invoke I1;
	else if (condition for I2 to be valid) invoke I2;
	...
	else run-time-error-message();
=
but in value mode, where invocations return values,
= (text)
	((condition for I1 to be valid) && ((formal_rv = I1) bitwise-or 1))
	logical-or ((condition for I2 to be valid) && ((formal_rv = I2) bitwise-or 1))
	...
=
The key here is that I6, like C, evaluates operands of |&&| left to right
and short-circuits: if the left operand is false, the right is never evaluated,
and its side-effect (of invoking a phrase and setting |formal_rv|) never
happens; and similarly for logical-or. Bitwise or doesn't have that property,
and the ridiculous trick of bitwise-or-ing with 1 ensures that any value is
made non-zero, so that the assignment is always regarded by I6 as "true".
This in turn means that if any invocation is reached in this expression,
no subsequent lines are looked at.

@<Compile code to apply the first invocation which is applicable@> =
	int no_conditions_tested = 0, if_depth = 0;
	int pos = 0;
	parse_node *last_inv = NULL;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		LOGIF(MATCHING, "RC%d: $e\n", pos, inv); pos++;
		last_inv = inv;
		if (no_conditions_tested > 0) {
			if (void_mode) {
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
			}
		}
		@<Compile code to apply this invocation if it's applicable@>;
	}
	if (Invocations::is_marked_unproven(last_inv)) {
		@<Compile code for the execution path where no invocations were applicable@>;
	}
	while (if_depth > 0) { Produce::up(Emit::tree()); Produce::up(Emit::tree()); if_depth--; }

@<Compile code to apply the first invocation which is applicable, as expression@> =
	int pos = 0;
	parse_node *last_inv = NULL;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		LOGIF(MATCHING, "RC%d: $e\n", pos, inv); pos++;
		last_inv = inv;
		@<Compile code to apply this invocation if it's applicable, expression version@>;
	}

@<Count the applicability conditions@> =
	parse_node *last_inv = NULL;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		int checks_needed = FALSE;
		last_inv = inv;
		for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
			parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
			if (check_against) checks_needed = TRUE;
		}
		if (checks_needed) NC++; else prov = TRUE;
	}
	if (Invocations::is_marked_unproven(last_inv)) unprov = TRUE;

@<Compile code for the execution path where no invocations were applicable@> =
	if (no_conditions_tested == 0) internal_error("condition proof error");
	if (void_mode) {
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
	}
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(ARGUMENTTYPEFAILED_HL));
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sl.line_number);
		inform_extension *E = Extensions::corresponding_to(sl.file_of_origin);
		if (E) Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) E->allocation_id + 1);
	Produce::up(Emit::tree());

@<Compile code to apply this invocation if it's applicable@> =
	if (Node::get_say_verb(inv))
		VerbsAtRunTime::ConjugateVerb_invoke_emit(
			Node::get_say_verb(inv),
			Node::get_modal_verb(inv),
			Annotations::read_int(inv, say_verb_negated_ANNOT));
	else if (Node::get_say_adjective(inv))
		Adjectives::Meanings::emit(Node::get_say_adjective(inv));
	else {
		phrase *ph = Node::get_phrase_invoked(inv);
		tokens_packet tokens;
		@<First construct an arguments packet@>;
		@<Substitute the formal parameter variables into the tokens@>;
		@<Compile the check on invocation applicability, emission version@>;
		@<Compile the invocation part, emission version@>;
	}

@<Compile code to apply this invocation if it's applicable, expression version@> =
	if (Node::get_say_verb(inv))
		VerbsAtRunTime::ConjugateVerb_invoke_emit(
			Node::get_say_verb(inv),
			Node::get_modal_verb(inv),
			Annotations::read_int(inv, say_verb_negated_ANNOT));
	else if (Node::get_say_adjective(inv))
		Adjectives::Meanings::emit(Node::get_say_adjective(inv));
	else {
		phrase *ph = Node::get_phrase_invoked(inv);
		tokens_packet tokens;
		@<First construct an arguments packet@>;
		@<Substitute the formal parameter variables into the tokens@>;
		int L = Produce::level(Emit::tree()), or_made = FALSE, ands_made = 0;
		@<Compile the check on invocation applicability, expression version@>;
		@<Compile the invocation part, emission version@>;
		for (int i=0; i<ands_made; i++) Produce::up(Emit::tree());
		int target = L;
		if (or_made) target++;
		if (target != Produce::level(Emit::tree())) internal_error("levels wrong");
	}

@<Substitute the formal parameter variables into the tokens@> =
	for (int i=0; i<tokens.tokens_count; i++) {
		nonlocal_variable *nlv = NonlocalVariables::temporary_formal(i);
		NonlocalVariables::set_kind(nlv, tokens.kind_required[i]);
		tokens.args[i] = Lvalues::new_actual_NONLOCAL_VARIABLE(nlv);
	}

@<Compile the check on invocation applicability, emission version@> =
	int check_needed = 0;
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
		if (check_against != NULL) check_needed++;
	}

	if (check_needed > 0) {
		if (void_mode) {
			Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
			Produce::down(Emit::tree());
			@<Put the condition check here, emission version@>;
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
			if_depth++;
		} else {
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Produce::down(Emit::tree());
			@<Put the condition check here, emission version@>;
		}
		no_conditions_tested++;
	} else if (Invocations::is_marked_unproven(inv))
		internal_error("unable to compile a run-time kind check");

@<Compile the check on invocation applicability, expression version@> =
	int check_needed = 0;
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
		if (check_against != NULL) check_needed++;
	}

	if (check_needed > 0) {
		no_conditions_tested++;
		if ((no_conditions_tested < NC) || (prov)) {
			Produce::inv_primitive(Emit::tree(), OR_BIP);
			Produce::down(Emit::tree()); or_made = TRUE;
		}
		for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
			parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
			if (check_against) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree()); ands_made++;
				BEGIN_COMPILATION_MODE;
				COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
				nonlocal_variable *nlv = NonlocalVariables::temporary_formal(i);
				parse_node *spec = Lvalues::new_actual_NONLOCAL_VARIABLE(nlv);
				@<Compile a check that this formal variable matches the token, emission version@>;
				END_COMPILATION_MODE;
			}
		}
	}

@ There may be checks needed on several tokens, so we accumulate these into
a list divided by logical-and |&&| operators.

@<Put the condition check here, emission version@> =
	int and_depth = 0;
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

	for (int i=0, check_count = 0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
		if (check_against != NULL) {
			check_count++;
			if (check_count < check_needed) {
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Produce::down(Emit::tree());
				and_depth++;
			}

			nonlocal_variable *nlv = NonlocalVariables::temporary_formal(i);
			parse_node *spec = Lvalues::new_actual_NONLOCAL_VARIABLE(nlv);
			@<Compile a check that this formal variable matches the token, emission version@>;
		}
	}

	while (and_depth > 0) { Produce::up(Emit::tree()); and_depth--; }

	END_COMPILATION_MODE;

@ There are two things we might want to check, exemplified by what happens
in this situation:

>> To collate (N - an even number): ...
>> To collate (N - 10): ...
>> collate X;

To compile "collate X", we need to test at run-time which invocation applies.
(We actually check the second of these first, because it's more specific.)
In case we test if X is 10, in the other that X matches the description
"even number".

@<Compile a check that this formal variable matches the token, emission version@> =
	if (Specifications::is_description(check_against)) {
		Calculus::Deferrals::emit_test_if_var_matches_description(
			spec, check_against);
	} else if (ParseTreeUsage::is_value(check_against)) {
		pcalc_prop *prop = Calculus::Propositions::Abstract::to_set_relation(R_equality,
			NULL, spec, NULL, check_against);
		Calculus::Deferrals::emit_test_of_proposition(NULL, prop);
	} else {
		LOG("Error on: $T", check_against);
		internal_error("bad check-against in run-time type check");
	}

@ ...and the actual invocation is now simple. In void mode, simply:
= (text)
	invoke(formal-vars)
=
whereas in value mode,
= (text)
	((formal_rv = invoke(formal-vars)) bitwise-or 1)
=
As noted above, the bitwise-or is a clumsy way to force the condition to
evaluate to "true" with a minimum of branches in the compiled code.

@<Compile the invocation part, emission version@> =
	if (!void_mode) {
		Produce::inv_primitive(Emit::tree(), BITWISEOR_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(FORMAL_RV_HL));
	}

	value_holster VH2 = Holsters::new(VH->vhmode_wanted);
	int returned_in_manner =
		Invocations::Compiler::compile_single_invocation(&VH2, inv, &sl, &tokens);

	if (!void_mode) {
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	}

	if (returned_in_manner != DONT_KNOW_MOR)
		@<If the invocation compiled to a return from a function, check this is allowed@>;

@h Lower level: compiling single invocations.

Phrases to decide a condition must compile to valid I6 conditions, which
we need to ensure there are round brackets around.

=
int Invocations::Compiler::compile_single_invocation(value_holster *VH, parse_node *inv,
	source_location *where_from, tokens_packet *tokens) {
	LOGIF(MATCHING, "Compiling single invocation: $e\n", inv);
	BEGIN_COMPILATION_MODE;

	phrase *ph = Node::get_phrase_invoked(inv);
	int manner_of_return = DONT_KNOW_MOR;

	@<The art of invocation is delegation@>;

	@<Compile a newline if the phrase implicitly requires one@>;

	END_COMPILATION_MODE;
	if (manner_of_return != DONT_KNOW_MOR)
		LOGIF(MATCHING, "Single invocation return manner: %d\n", manner_of_return);
	return manner_of_return;
}

@ The real work is done by one of the two sections following this one. Note that
only inline invocations are allowed to produce an exotic manner of return -- it's
not possible to define a high-level I7 phrase which effects, say, an immediate
end to the rule it's used in. Similarly, only inline invocations are allowed
to be followed by blocks of other phrases -- that is, are allowed to define
control structures.

@<The art of invocation is delegation@> =
	if (Phrases::TypeData::invoked_inline(ph))
		manner_of_return =
			Invocations::Inline::csi_inline_outer(VH, inv, where_from, tokens);
	else
		Invocations::AsCalls::csi_by_call(VH, inv, where_from, tokens);

@ This is where we implement the convention that saying text ending with a full
stop automatically generates a newline:

@<Compile a newline if the phrase implicitly requires one@> =
	if ((Invocations::implies_newline(inv)) &&
		(tokens->tokens_count > 0) &&
		(Rvalues::is_CONSTANT_of_kind(tokens->args[0], K_text)) &&
		(Word::text_ending_sentence(Wordings::first_wn(Node::get_text(tokens->args[0]))))) {
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), I"\n");
		Produce::up(Emit::tree());
	}
