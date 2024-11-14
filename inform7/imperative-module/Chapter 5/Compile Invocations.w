[CompileInvocations::] Compile Invocations.

Generating code to perform an invocation.

@h Upper level: compiling from whole lists.
Here, we are given an invocation list |invl|, and we must generate Inter code
to carry it out. The code in this section does some complicated things; the
test group |:invocations| may be helpful when maintaining it.

=
void CompileInvocations::list(value_holster *VH, parse_node *invl, wording W,
		int allow_implied_newlines) {
	@<Check that the list is in canonical form@>;
	@<Tell the holster we intend to generate Inter code@>;

	if (InvocationLists::length(invl) > 0) {
		LOGIF(MATCHING, "Compiling from %d invocation(s)\n", InvocationLists::length(invl));
		source_location sl = Lexer::word_location(Wordings::first_wn(W));
		parse_node *first_inv = InvocationLists::first_reading(invl);
		@<Use runtime resolution only if necessary@>;
	}
}

@ The invocation list has already been typechecked by //values: Dash//. This
means that any invocation which could be disproved has been removed, and what's
left is either "proven" -- i.e., certain to be applicable -- or "unproven" --
i.e., only applicable if certain runtime checks are performed.

Here we check that the list does indeed contain 0 or more unproven invocations
followed by 0 or 1 proven ones, and that all invocations have the same number
of tokens.

@<Check that the list is in canonical form@> =
	int no_proven = 0, no_unproven = 0, common_token_count = -1, noncanonical = FALSE;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		int N = Invocations::get_no_tokens(inv);
		if (common_token_count == -1) common_token_count = N;
		else if (common_token_count != N) noncanonical = TRUE;
		if (Invocations::is_marked_unproven(inv)) {
			no_unproven++;
			if (no_proven > 0) noncanonical = TRUE;
		} else {
			no_proven++;
			if (no_proven > 1) noncanonical = TRUE;
		}
	}
	if (noncanonical) {
		LOOP_THROUGH_INVOCATION_LIST(inv, invl) LOG("$e\n", inv);
		internal_error("invocation list not in canonical form");
	}

@ In fact it is impossible for this to be called with |VH->vhmode_wanted| set to
anything other than |INTER_VAL_VHMODE| or |INTER_VOID_VHMODE|.

@<Tell the holster we intend to generate Inter code@> =
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;

@ Our task is to compile code which executes the first applicable invocation. If
there is any possibility that none are, we must generate code to produce a
runtime problem message in that case.

Since the list is in canonical form, if the first invocation is proven then it
is the only one, and therefore no runtime resolution will be needed.

@<Use runtime resolution only if necessary@> =
	if (Invocations::is_marked_unproven(first_inv)) {
		@<Compile using runtime resolution to choose between invocations@>;
	} else {
		tokens_packet tokens = CompileInvocations::new_tokens_packet(first_inv);
		CompileInvocations::single(VH, first_inv, &sl, &tokens, allow_implied_newlines);
	}

@ We get to here if the first invocation is unproven, meaning that at compile
time it was impossible to determine whether it was type-safe to execute. We must
therefore compile code to determine this at runtime.

There are two basic forms of this: "void mode", where the phrases are going to
be Inform 6 statements in a void context, and "value mode", where the phrases
will be expressions being evaluated.

@<Compile using runtime resolution to choose between invocations@> =
	id_body *idb = Node::get_phrase_invoked(first_inv);

	int void_mode = FALSE;
	if (idb->type_data.manner_of_return == DECIDES_NOTHING_MOR) void_mode = TRUE;
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
	else runtime-error-message();
=
where the chain of execution runs into the error message code only if none
of I1, ..., In can be applied. In the case where the final invocation is
proven, we can more simply do this:
= (text)
	if (condition for I1 to be valid) invoke I1(T1, ..., Tm);
	else if (condition for I2 to be valid) invoke I2(T1, ..., Tm);
	else invoke In(T1, ..., Tm);
=

@ That's almost what we do, but not quite. The problem lies in the fact that
the tokens |T1|, ..., |Tm| are evaluated multiple times - not in the invocations
(since only one is reached in execution) but in the condition tests. This
multiple evaluation would be incorrect if token evaluation had side-effects,
as it easily might, and would also waste time if the tokens were slow to evaluate.
So in fact we modify our scheme like so:
= (text)
	F1 = T1;
	F2 = T2;
	...
	if (condition for I1 to be valid) invoke I1(F1, ..., Fm);
	else if (condition for I2 to be valid) invoke I2(F1, ..., Fm);
	...
	else runtime-error-message();
=
Here |F1, ..., Fn| are called the "formal parameters". But now we have a tricky
issue to contend with: where can they be stored?

Here are the answers I thought of in turn:
(*) Make |F1, ..., Fn| local variables for the current function. Often works
but not always, since some of our eventual target VMs have low upper limits
on the number of locals in any one function.
(*) Put |F1, ..., Fn| on the call stack for the current function. Impossible
because the Inter VM has no memory access to its call stack, a restriction
forced on Inter by the nature of the Z-machine and Glulx VMs it is a bridge to.
(*) Have |F1, ..., Fn| be global variables. Impossible because they have to be
local in scope since evaluation of |T2|, say, might itself involve a call to
another phrase which needs to make a resolution itself.
(*) Have |F1, ..., Fn| be global variables, but push copies to the call stack
before the resolution, and pull them back afterwards, thus using only saved
copies. This sometimes works in void context (if we are careful to avoid cases
where the phrase invoked might perform a jump or return), but is impossible
in value context, where the Inter |PUSH_BIP| and |PULL_BIP| opcodes are illegal.
(*) Force the current function to be a kernel function inside an outer shell
function, and then allocate |F1, ..., Fn| as memory in the |I7SFRAME| space
provided by the shell function. This works, but is slower to access, and forces
us to have a memory stack, which can be a problem if we are compiling for a
very tight Z-machine memory.
(*) Force the current function to be a kernel function inside an outer shell
function, but have |F1, ..., Fn| be global variables anyway. In the shell
function, push copies of |F1, ..., Fn| to the call stack before calling the
kernel, and then pull these saved values back afterwards. This one, finally,
works in all cases, and is what we do.

@<Compile the resolution@> =
	int N = Invocations::get_no_tokens(first_inv); /* must be > 0, or we would be proven */
	nonlocal_variable *formal_vars[1000];
	inter_name *formal_var_inames[1000];
	for (int i=0; i<N; i++) {
		formal_vars[i] = TemporaryVariables::formal_parameter(i);
		formal_var_inames[i] = TemporaryVariables::iname_of_formal_parameter(i);
	}
	int total = TemporaryVariables::claim_formal_parameters(N);
	Frames::need_at_least_this_many_formals(total); /* forces the existence of a shell function */
	if (void_mode) @<Compile the resolution in void mode@>
	else @<Compile the resolution in value mode@>;
	TemporaryVariables::release_formal_parameters(N);

@<Compile the resolution in void mode@> =
	for (int i=0; i<N; i++)
		@<Set the ith formal parameter to the ith token value@>;
	int pos = 0, if_depth = 0;
	parse_node *inv, *last_inv = NULL;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		LOGIF(MATCHING, "RC%d: $e\n", pos, inv); pos++;
		last_inv = inv;
		if (if_depth > 0) {
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
		}
		tokens_packet tokens = CompileInvocations::new_tokens_packet(inv);
		@<Substitute the formal parameters into the tokens packet@>;
		if (Invocations::is_marked_unproven(inv)) {
			EmitCode::inv(IFELSE_BIP);
			EmitCode::down();
			@<Put the condition check here@>;
			EmitCode::code();
			EmitCode::down();
			if_depth++;
		}
		CompileInvocations::single(VH, inv, &sl, &tokens, allow_implied_newlines);
	}
	if (Invocations::is_marked_unproven(last_inv)) {
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
		@<Compile call to function throwing an RTP@>;
	}
	while (if_depth > 0) {
		EmitCode::up(); EmitCode::up();
		if_depth--;
	}

@ There may be checks needed on several tokens, so we accumulate these into
a list divided by logical-and |&&| operators.

@<Put the condition check here@> =
	int check_needed = 0;
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
		if (check_against) check_needed++;
	}
	int check_count = 0;
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
		if (check_against) {
			check_count++;
			if (check_count < check_needed) {
				EmitCode::inv(AND_BIP);
				EmitCode::down();
			}
			@<Compile a check that this formal variable matches the token@>;
		}
	}
	if (check_count == 0) internal_error("this should not be marked unproven");
	for (int i = 1; i <= check_count - 1; i++) EmitCode::up();

@ The check is either against a general description, such as "even number", or
a specific value, such as "10".

@<Compile a check that this formal variable matches the token@> =
	nonlocal_variable *nlv = formal_vars[i];
	parse_node *spec = Lvalues::new_actual_NONLOCAL_VARIABLE(nlv);
	if (Specifications::is_description(check_against)) {
		CompilePropositions::to_test_if_variable_matches(spec, check_against);
	} else if (Specifications::is_value(check_against)) {
		pcalc_prop *prop = Propositions::Abstract::to_set_relation(R_equality,
			NULL, spec, NULL, check_against);
		CompilePropositions::to_test_as_condition(NULL, prop);
	} else {
		LOG("Error on: $T", check_against);
		internal_error("bad check-against in runtime type check");
	}

@ A parameter corresponding to the name of a kind has no meaningful value
at runtime; we assign 0 to it for the sake of tidiness.

@<Set the ith formal parameter to the ith token value@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, formal_var_inames[i]);
		if (idb->type_data.token_sequence[i].construct == KIND_NAME_IDTC) {
			EmitCode::val_number(0);
		} else {
			parse_node *value =
				Invocations::get_token_as_parsed(first_inv, i);
			kind *to_be_used_as = Specifications::to_kind(
				idb->type_data.token_sequence[i].to_match);
			CompileValues::to_fresh_code_val_of_kind(value, to_be_used_as);
		}
	EmitCode::up();

@<Substitute the formal parameters into the tokens packet@> =
	for (int i=0; i<tokens.tokens_count; i++) {
		nonlocal_variable *nlv = formal_vars[i];
		NonlocalVariables::set_kind(nlv, tokens.token_kinds[i]);
		tokens.token_vals[i] = Lvalues::new_actual_NONLOCAL_VARIABLE(nlv);
	}

@<Compile call to function throwing an RTP@> =
	EmitCode::call(Hierarchy::find(ARGUMENTTYPEFAILED_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) sl.line_number);
		inform_extension *E = Extensions::corresponding_to(sl.file_of_origin);
		if (E) EmitCode::val_number((inter_ti) E->allocation_id + 1);
	EmitCode::up();

@ In value mode we want the same strategy and code paths, but all in the context
of a value. This means we can only use Inter opcodes which are legal in a value
context, making everything harder.

The |TERNARYSEQUENTIAL_BIP| opcode is similar to evaluating |x, y, z| in C: it
evaluates |x|, throws that away, evaluates |y|, ditto, then evaluates |z| as
its answer. |x| and |y| are thus evaluated only for and side-effects that has.
Here |x| is going to be code to set the formal parameters; |y| will be code
to test the conditions for invocation and invoke one of them into a dummy
variable called |formal_rv|; and |z| will simply evaluate |formal_rv|, thus
producing the answer.

@<Compile the resolution in value mode@> =
	EmitCode::inv(TERNARYSEQUENTIAL_BIP);
	EmitCode::down();
		/* Here is x: */
		@<Set the formal parameters in value mode@>;
		/* Here is y: */
		@<Perform the tests and invocations in value mode@>;
		/* Here is z: */
		EmitCode::val_iname(K_value, Hierarchy::find(FORMAL_RV_HL));
	EmitCode::up();

@ In Inter, as in C, assignments return a value and are therefore legal here.
But because Inter does not provide a binary sequential opcode, we will fold
our run of assignments into a single value by adding them up -- the result
doesn't matter, since it will be thrown away anyway. So if there are, say,
four formal parameters then our |x| will be:
= (text)
	(F4 = T4) + ((F3 = T3) + ((F2 = T2) + (F1 = T1)))
=
It isn't really important that we count downwards from 4 to 1 here, but we do
it because the Inform 6 compiler happens to evaluate operands of |+| in the
order right then left. So this actually causes |T1| to evaluate first, then |T2|
and so on, provided Inform 6 is the eventual code generator.

=
@<Set the formal parameters in value mode@> =
	int L = EmitCode::level();
	for (int i = N-1; i >= 0; i--) {
		if (i > 0) { EmitCode::inv(PLUS_BIP); EmitCode::down(); }
		@<Set the ith formal parameter to the ith token value@>;
	}
	for (int i = N-1; i >= 0; i--) {
		if (i > 0) EmitCode::up();
	}
	if (L != EmitCode::level()) internal_error("misimplemented");

@ Now the fun really begins. We compile |y| to an expression like so:
= (text)
	((condition for I1 to be valid) && ((formal_rv = I1) bitwise-or 1)) ||
	((condition for I2 to be valid) && ((formal_rv = I2) bitwise-or 1)) ||
	...
	((condition for In to be valid) && ((formal_rv = In) bitwise-or 1)) ||
	(issue run-time-problem)
=
The key here is that Inter, like C, evaluates operands of |&&| left to right
and short-circuits: if the left operand is false, the right is never evaluated,
and its side-effect (of invoking a phrase and setting |formal_rv|) never
happens; and similarly for logical-or.

Bitwise-or does not short-circuit, so the faintly ridiculous trick of
bitwise-or-ing with 1 ensures that any value is made non-zero, so that the
assignment is always regarded by Inter as "true". This all means that if
any condition is valid, no subsequent conditions will even be tested.

Note that all functions return values in Inter, so the function call to issue
the run-time problem is indeed legal in a value context.

Matters are a little simpler if the final invocation is proven:
= (text)
	((condition for I1 to be valid) && ((formal_rv = I1) bitwise-or 1)) ||
	((condition for I2 to be valid) && ((formal_rv = I2) bitwise-or 1)) ||
	...
	((formal_rv = In) bitwise-or 1)
=

@<Perform the tests and invocations in value mode@> =
	int L = EmitCode::level();
	int number_unproven = 0, last_is_unproven = TRUE;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl)
		if (Invocations::is_marked_unproven(inv)) number_unproven++;
		else last_is_unproven = FALSE;
	if (last_is_unproven) {
		EmitCode::inv(OR_BIP);
		EmitCode::down();
	}
	@<Perform the tests and invocations without RTP in value mode@>;
	if (last_is_unproven) {
		@<Compile call to function throwing an RTP@>;
		EmitCode::up();
	}
	if (L != EmitCode::level()) internal_error("misimplemented");

@<Perform the tests and invocations without RTP in value mode@> =
	int L = EmitCode::level();
	int pos = 0;
	LOOP_THROUGH_INVOCATION_LIST(inv, invl) {
		LOGIF(MATCHING, "RC%d: $e\n", pos, inv); pos++;
		if (pos < InvocationLists::length(invl)) {
			EmitCode::inv(OR_BIP);
			EmitCode::down();
		}
		tokens_packet tokens = CompileInvocations::new_tokens_packet(inv);
		@<Substitute the formal parameters into the tokens packet@>;
		@<Compile code to apply this invocation if it's applicable, value mode@>;
	}
	for (int i = 1; i <= InvocationLists::length(invl) - 1; i++)
		EmitCode::up();
	if (L != EmitCode::level()) internal_error("misimplemented");

@<Compile code to apply this invocation if it's applicable, value mode@> =
	int L = EmitCode::level();
	int ands_made = 0;
	@<Compile the check on invocation applicability, value mode@>;
	EmitCode::inv(BITWISEOR_BIP);
	EmitCode::down();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(FORMAL_RV_HL));
			CompileInvocations::single(VH, inv, &sl, &tokens, allow_implied_newlines);
		EmitCode::up();
		EmitCode::val_number(1);
	EmitCode::up();
	for (int i=0; i<ands_made; i++) EmitCode::up();
	if (L != EmitCode::level()) internal_error("misimplemented");

@<Compile the check on invocation applicability, value mode@> =
	if (Invocations::is_marked_unproven(inv)) {
		int checks_made = 0;
		for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
			parse_node *check_against = Invocations::get_token_check_to_do(inv, i);
			if (check_against) {
				EmitCode::inv(AND_BIP);
				EmitCode::down(); ands_made++;
				@<Compile a check that this formal variable matches the token@>;
				checks_made++;
			}
		}
		if (checks_made == 0) internal_error("this should not be marked unproven");
	}

@h Lower level: compiling single invocations.

=
void CompileInvocations::single(value_holster *VH, parse_node *inv,
	source_location *where_from, tokens_packet *tokens, int allow_implied_newlines) {
	LOGIF(MATCHING, "Compiling single invocation: $e\n", inv);
	if (Node::get_say_verb(inv)) {
		RTVerbs::ConjugateVerb_invoke_emit(
			Node::get_say_verb(inv),
			Node::get_modal_verb(inv),
			Annotations::read_int(inv, say_verb_negated_ANNOT));
	} else if (Node::get_say_adjective(inv)) {
		RTAdjectives::invoke(Node::get_say_adjective(inv));
	} else {
		@<Invoke a phrasal invocation@>;
	}
}

@ Note that the phrases which compile to Inter jump or return instructions can
never be marked to save |self|, or the code here would lead to slow stack overflow
errors, since |self| would be pushed but not pulled.

@<Invoke a phrasal invocation@> =
	int manner_of_return = DONT_KNOW_MOR;
	int save_self = FALSE;
	if (Invocations::is_marked_to_save_self(inv)) save_self = TRUE;

	if (save_self) {
		EmitCode::inv(PUSH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::up();
	}

	@<The art of invocation is delegation@>;
	@<Compile a newline if the phrase implicitly requires one@>;

	if (save_self) {
		EmitCode::inv(PULL_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::up();
	}

	if (manner_of_return != DONT_KNOW_MOR)
		LOGIF(MATCHING, "Single invocation return manner: %d\n", manner_of_return);
	if ((Functions::defn_being_compiled()) && (manner_of_return != DONT_KNOW_MOR))
		@<If the invocation compiled to a return from a function, check this is allowed@>;

@ For example, the definition of the phrase "To begin" isn't allowed to contain the
invocation "decide on 178", since it isn't a phrase to decide anything. This is
where that's checked:

@<If the invocation compiled to a return from a function, check this is allowed@> =
	id_body *current_idb = Functions::defn_being_compiled();
	int manner_expected = current_idb->type_data.manner_of_return;
	if ((manner_of_return != manner_expected) &&
		(manner_expected != DECIDES_NOTHING_AND_RETURNS_MOR)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_text(2,
			IDTypeData::describe_manner_of_return(manner_of_return, NULL, NULL));
		kind *K = NULL;
		Problems::quote_text(3,
			IDTypeData::describe_manner_of_return(manner_expected,
				&(current_idb->type_data), &K));
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
	}

@ The real work is done by one of the two sections following this one. Note that
only inline invocations are allowed to produce an exotic manner of return -- it's
not possible to define a high-level I7 phrase which effects, say, an immediate
end to the rule it's used in. Similarly, only inline invocations are allowed
to be followed by blocks of other phrases -- that is, are allowed to define
control structures.

@<The art of invocation is delegation@> =
	id_body *idb = Node::get_phrase_invoked(inv);
	if (IDTypeData::invoked_inline(idb))
		manner_of_return =
			CSIInline::csi_inline(VH, inv, where_from, tokens);
	else
		CallingFunctions::csi_by_call(VH, inv, where_from, tokens);

@ If |allow_implied_newlines| is set, we understand the final part of a
text literal to be allowed to print an implied newline. For example, here it's on:
= (text as Inform 7)
	say "At [time of day], I like to serve afternoon tea. Indian or Chinese?";
=
Here the question mark has an implied newline after it. But there are other
contexts in which newlines are not implied:
= (text as Inform 7)
	let the warning rubric be "Snakes!";
=

@<Compile a newline if the phrase implicitly requires one@> =
	if (IDTypeData::is_a_say_phrase(Node::get_phrase_invoked(inv))) {
		if ((Node::get_phrase_invoked(inv)->type_data.as_say.say_phrase_running_on == FALSE) &&
			(allow_implied_newlines) &&
			(tokens->tokens_count > 0) &&
			(Rvalues::is_CONSTANT_of_kind(tokens->token_vals[0], K_text)) &&
			(Word::text_ending_sentence(
				Wordings::first_wn(Node::get_text(tokens->token_vals[0]))))) {
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(I"\n");
			EmitCode::up();
		}
	}

@h Tokens packets.
This structure is a convenient holder for the token values being used when
invoking a phrase, and for what we think their kinds are.

In many cases that will not be much of an issue, but suppose the phrase to be
invoked is polymorphic, like so --
= (text as Inform 7)
To discuss (V - sayable value):
	say "You discourse about [V]."
=
If the invocation is "discuss 16", then the token has kind |K_number| not
|K_sayable_value|, because we derive the kind from what the phrase was actually
invoked on rather than the full range of what it might have been. Similarly,
the |fn_kind| is |function number -> nothing|, not |function sayable value -> nothing|.

=
typedef struct tokens_packet {
	int tokens_count;
	struct parse_node *token_vals[MAX_TOKENS_PER_PHRASE];
	struct kind *token_kinds[MAX_TOKENS_PER_PHRASE];
	struct kind *fn_kind;
} tokens_packet;

@ This is all easy to unpack from the invocation subtree.

If a token holds the name of a kind rather than a value as such, we use the
|nothing| constant as the "token value", just as a placeholder. It won't be compiled.

=
tokens_packet CompileInvocations::new_tokens_packet(parse_node *inv) {
	id_body *idb = Node::get_phrase_invoked(inv);
	tokens_packet tokens;
	tokens.tokens_count = Invocations::get_no_tokens_needed(inv);
	for (int i=0; i<tokens.tokens_count; i++) {
		parse_node *val = Invocations::get_token_as_parsed(inv, i);
		kind *K = Specifications::to_kind(idb->type_data.token_sequence[i].to_match);
		if ((IDTypeData::invoked_inline(idb) == FALSE) &&
			(Kinds::Behaviour::definite(K) == FALSE))
			tokens.token_kinds[i] = Specifications::to_kind(val);
		else
			tokens.token_kinds[i] = K;
		if (idb->type_data.token_sequence[i].construct == KIND_NAME_IDTC)
			tokens.token_vals[i] = Rvalues::new_nothing_object_constant();
		else
			tokens.token_vals[i] = val;
	}
	kind *return_kind = Node::get_kind_resulting(inv);
	if ((return_kind == NULL) && (idb)) return_kind = idb->type_data.return_kind;
	tokens.fn_kind =
		Kinds::function_kind(tokens.tokens_count, tokens.token_kinds, return_kind);
	return tokens;
}
