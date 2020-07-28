[Invocations::Inline::] Compile Invocations Inline.

Here we generate Inform 6 code to execute the phrase(s) called
for by an invocation list.

@h CSI: Inline.
The new criminal forensics show. Jack "The Invoker" Flathead, lonely but
brilliant scene of crime officer, tells it like it is, and as serial killers
stalk the troubled streets of Inline, Missouri, ... Oh, very well: this is
the code which turns an inline phrase definition into I6 code. For example:

>> To adjust (N - a number): (- AdjustThis({N}, 1); -).

That sounds like an elementary matter of copying it out, but we need to
expand material in curly braces, according to what amounts to a
mini-language. So:

>> adjust 16;

would expand to
= (text)
	AdjustThis(16, 1);
=
The exact definition of this mini-language has been the subject of some
speculation ever since the early days of the I7 Public Beta: but the exotic
features it contains were never meant to be used anywhere except by the
Standard Rules. They may change without warning.

@d MAX_INLINE_DEFN_LENGTH 1024

=
typedef struct csi_state {
	struct source_location *where_from;
	struct phrase *ph;
	struct parse_node *inv;
	struct tokens_packet *tokens;
	struct local_variable **my_vars;
} csi_state;

int Invocations::Inline::csi_inline_outer(value_holster *VH,
	parse_node *inv, source_location *where_from, tokens_packet *tokens) {

	phrase *ph = Node::get_phrase_invoked(inv);

	local_variable *my_vars[10]; /* the "my" variables 0 to 9 */
	@<Start with all of the implicit my-variables unused@>;
	@<Create any new local variables explicitly called for@>;

	csi_state CSIS;
	CSIS.where_from = where_from;
	CSIS.ph = ph;
	CSIS.inv = inv;
	CSIS.tokens = tokens;
	CSIS.my_vars = my_vars;

	inter_schema *tail_schema = NULL;

	@<Expand those into streams@>;

	if (Phrases::TypeData::block_follows(ph)) @<Open a code block@>
	else @<Release any variables created inline@>;

	return ph->inline_mor;
}

@ Inline invocations, unlike invocations by function call, are allowed to
create new local variables. There are two ways they can do this: implicitly,
that is, from |{-my:...}| bracings in the definition, in which case the
user never knows about these hidden locals:

@<Start with all of the implicit my-variables unused@> =
	for (int i=0; i<10; i++) my_vars[i] = NULL;

@ ...And explicitly, where the phrase typed by the user actually names the
variable(s) to be created, as here:

>> repeat with the item count running from 1 to 4:

where "item count" needs to be created as a number variable. (The type
checker has already done all of the work to decide what kind it has.)

@<Create any new local variables explicitly called for@> =
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *val = tokens->args[i];
		kind *K = Invocations::get_token_variable_kind(inv, i);
		if (K) @<Create a local at this token@>;
	}

@<Create a local at this token@> =
	local_variable *lvar = LocalVariables::new(Node::get_text(val), K);
	if (Phrases::TypeData::block_follows(ph) == LOOP_BODY_BLOCK_FOLLOWS)
		Frames::Blocks::set_scope_to_block_about_to_open(lvar);
	else
		Frames::Blocks::set_variable_scope(lvar);
	tokens->args[i] =
		Lvalues::new_LOCAL_VARIABLE(Node::get_text(val), lvar);
	if (Kinds::Behaviour::uses_pointer_values(K)) {
		inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
			Frames::emit_allocation(K);
		Produce::up(Emit::tree());
	}

@ Most phrases don't have tail definitions, so we only open such a stream
if we have to. All phrases have heads, but no opening is needed, since the
head goes to |OUT|.

@<Expand those into streams@> =
	Invocations::Inline::csi_inline_inner(VH, Phrases::get_inter_head(ph), &CSIS);
	if (Phrases::get_inter_tail(ph)) tail_schema = Phrases::get_inter_tail(ph);

@ Suppose there's a phrase with both head and tail. Then the tail won't appear
until much later on, when the new code block finishes. We won't live to see it;
in this routine, all we do is write the head. So we pass the tailpiece to
the code block handler, to be spliced in later on. (This is why we never close
the |TAIL| stream: that happens when the block closes.)

@<Open a code block@> =
	parse_node *val = NULL;
	if (Invocations::get_no_tokens(inv) > 0) val = tokens->args[0];
	Frames::Blocks::supply_val_and_stream(val, tail_schema, CSIS);

@ As we will see (in the discussion of |{-my:...}| below), any variables made
as scratch values for the invocation are deallocated as soon as we're finished,
unless a code block is opened: if it is, then they're deallocated when it ends.

@<Release any variables created inline@> =
	for (int i=0; i<10; i++)
		if (my_vars[i])
			LocalVariables::deallocate(my_vars[i]);

@ We can now forget about heads and tails, and work on expanding a single
inline definition into a single stream. Often this just involves copying it,
but there are two ways to escape from that transcription: with a "bracing",
or with a fragment of Inform 7 source text inside |(+| and |+)|.

=
void Invocations::Inline::csi_inline_inner(value_holster *VH, inter_schema *sch, csi_state *CSIS) {
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;

	int to_code = TRUE;
	int to_val = FALSE;
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) { to_val = TRUE; to_code = FALSE; }

	EmitInterSchemas::emit(Emit::tree(), VH, sch, CSIS, to_code, to_val, NULL, NULL,
		&Invocations::Inline::csi_inline_inner_inner, &Invocations::Inline::compile_I7_expression_from_text);
}

@ =
void Invocations::Inline::csi_inline_inner_inner(value_holster *VH,
	inter_schema_token *sche, void *CSIS_s, int prim_cat) {

	csi_state *CSIS = (csi_state *) CSIS_s;
	phrase *ph = CSIS->ph;
	parse_node *inv = CSIS->inv;
	tokens_packet *tokens = CSIS->tokens;
	local_variable **my_vars = CSIS->my_vars;

	if (sche->inline_command != no_ISINC) {
		if (sche->inline_command == primitive_definition_ISINC)
			@<Expand an entirely internal-made definition@>;
		@<Expand a bracing containing a kind command@>;
		@<Expand a bracing containing a typographic command@>;
		@<Expand a bracing containing a label or counter command@>;
		@<Expand a bracing containing a high-level command@>;
		@<Expand a bracing containing a miscellaneous command@>;
	}

	wording BRW = Feeds::feed_text(sche->bracing);
	@<Expand a bracing containing natural language text@>;
}

@ We'll take the easier, outward-facing syntax first: the bracings which
are part of the public Inform language. There are four ways this can go:

@d OPTS_INSUB 1		/* the text "phrase options" */
@d OPT_INSUB 2		/* the name of a specific phrase option */
@d LOCAL_INSUB 3	/* the name of a token */
@d PROBLEM_INSUB 4	/* the syntax was wrong, so do nothing */

@ Suppose we are invoking the following inline phrase definition:

>> To print (something - text) : (- print (PrintI6Text) {something}; -).

Here the inline definition is |"print (PrintI6Text) {something};"| and the
bracing, |{something}|, stands for something to be substituted in. This is
usually the name of one of the tokens in the phrase preamble, as it is here.
The name of any individual phrase option (valid in the phrase now being
invoked) expands to true or false according to whether it has been used;
the fixed text "phrase options" expands to the whole bitmap.

=
<inline-substitution> ::=
	phrase options |    ==> { OPTS_INSUB, - }
	<phrase-option>	|    ==> OPT_INSUB; <<opt>> = R[1]
	<name-local-to-inline-stack-frame> |    ==> LOCAL_INSUB; <<local_variable:var>> = RP[1]
	...										==> @<Issue PM_BadInlineExpansion problem@>

@ This matches one of the token names in the preamble to the inline definition.

=
<name-local-to-inline-stack-frame> internal {
	local_variable *lvar =
		LocalVariables::parse(&(ph_being_parsed->stack_frame), W);
	if (lvar) {
		*XP = lvar; return TRUE;
	}
	return FALSE;
}

@ In my first draft of Inform, this paragraph made reference to "meddling
charlatans" and what they "deserve". I'm a better person now.

@<Issue PM_BadInlineExpansion problem@> =
	*X = PROBLEM_INSUB;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadInlineExpansion));
	Problems::issue_problem_segment(
		"You wrote %1, but when I looked that phrase up I found that its inline "
		"definition included the bracing {%2}. Text written in braces like this, "
		"in an inline phrase definition, should be one of the following: a name "
		"of one of the tokens in the phrase, or a phrase option, or the text "
		"'phrase options' itself. %PThe ability to write inline phrases is really "
		"intended only for the Standard Rules and a few other low-level system "
		"extensions. A good rule of thumb is: if you can define a phrase without "
		"using I6 insertions, do.");
	Problems::issue_problem_end();

@ Acting on that:

@<Expand a bracing containing natural language text@> =
	phod_being_parsed = &(ph->options_data);
	ph_being_parsed = ph;
	<inline-substitution>(BRW);
	int current_opts = Invocations::get_phrase_options_bitmap(inv);
	switch (<<r>>) {
		case OPTS_INSUB:
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) current_opts);
			break;
		case OPT_INSUB:
			if (current_opts & <<opt>>) Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1); else Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			break;
		case LOCAL_INSUB: {
			local_variable *lvar = <<local_variable:var>>;
			int tok = LocalVariables::get_parameter_number(lvar);
			if (tok >= 0) @<Expand a bracing containing a token name@>;
			break;
		}
	}

@ At this point, the bracing text is the name of token number |tok|. Usually
we compile the value of that argument as drawn from the tokens packet, but
the presence of annotations can change what we do.

@<Expand a bracing containing a token name@> =
	parse_node *supplied = tokens->args[tok];

	int by_value_not_reference = TRUE;
	int blank_out = FALSE;
	int reference_exists = FALSE;
	int require_to_be_lvalue = FALSE;

	BEGIN_COMPILATION_MODE;
	@<Take account of any annotation to the inline token@>;
	kind *kind_vars_inline[27];
	@<Work out values for the kind variables in this context@>;
	kind **saved = Frames::temporarily_set_kvs(kind_vars_inline);
	int changed = FALSE;
	kind *kind_required =
		Kinds::substitute(ph->type_data.token_sequence[tok].token_kind,
		kind_vars_inline, &changed);
	@<If the token has to be an lvalue, reject it if it isn't@>;
	@<Compile the token value@>;
	Frames::temporarily_set_kvs(saved);
	END_COMPILATION_MODE;

@<Work out values for the kind variables in this context@> =
	kind_vars_inline[0] = NULL;
	for (int i=1; i<=26; i++) kind_vars_inline[i] = Frames::get_kind_variable(i);
	kind_variable_declaration *kvd = Node::get_kind_variable_declarations(inv);
	for (; kvd; kvd=kvd->next) kind_vars_inline[kvd->kv_number] = kvd->kv_value;

@<If the token has to be an lvalue, reject it if it isn't@> =
	if (require_to_be_lvalue) {
		nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(supplied);
		if (((nlv) && (NonlocalVariables::is_constant(nlv))) ||
			(ParseTreeUsage::is_lvalue(supplied) == FALSE)) {
			Problems::quote_source(1, current_sentence);
			if (nlv) Problems::quote_wording(2, nlv->name);
			else Problems::quote_spec(2, supplied);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotAnLvalue));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to mean changing '%2', which "
				"is a constant and can't be altered.");
			Problems::issue_problem_end();
		}
	}

@ The noteworthy thing here is the switch of compilation mode on text tokens.
It allows this:

>> let X be 17; write "remember [X]" to the file of Memos;

to work, the tricky part being that the definition being invoked is:
= (text)
	FileIO_PutContents({FN}, {T}, false);
=
The |{T}| bracing is the text one which triggers the mode change. The effect
is to ensure that the token is compiled along with recordings being made of
the current values of any local variables mentioned in it (bearing in mind
that text includes text substitutions). This seems so obviously a good thing
that it's hard to see why it isn't on by default. Well, it would be, except
that then response text changes using "now" would go wrong:

>> now can't exit closed containers rule response (A) is "Pesky [cage].";

The reference to "cage" in that text is to a local variable on the stack
frame for the can't exit closed containers rule, not to the local stack frame.

@<Compile the token value@> =
	if (Kinds::Compare::eq(kind_required, K_text))
		COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
	if (by_value_not_reference == TRUE)
		COMPILATION_MODE_ENTER(DEREFERENCE_POINTERS_CMODE);
	if (by_value_not_reference == FALSE)
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	if (blank_out == TRUE)
		COMPILATION_MODE_ENTER(BLANK_OUT_CMODE);
	if (blank_out == FALSE)
		COMPILATION_MODE_EXIT(BLANK_OUT_CMODE);
	if (reference_exists == TRUE) {
		COMPILATION_MODE_ENTER(TABLE_EXISTENCE_CMODE_ISSBM);
	}
	if (reference_exists == FALSE)
		COMPILATION_MODE_EXIT(TABLE_EXISTENCE_CMODE_ISSBM);
	LOGIF(MATCHING, "Expanding $P into '%W' with %d, $u%s%s\n",
		supplied, BRW, tok, kind_required,
		changed?" (after kind substitution)":"",
		by_value_not_reference?" (by value)":" (by reference)");
	Specifications::Compiler::emit_to_kind(supplied, kind_required);

@h Commands about kinds.
And that's it for the general machinery, but in another sense we're only just
getting started. We now go through all of the special syntaxes which make
invocation-language so baroque.

We'll start with a suite of details about kinds:
= (text)
	{-command:kind name}
=

@<Expand a bracing containing a kind command@> =
	Problems::quote_stream(4, sche->operand);
	if (sche->inline_command == new_ISINC) @<Inline command "new"@>;
	if (sche->inline_command == new_list_of_ISINC) @<Inline command "new-list-of"@>;
	if (sche->inline_command == printing_routine_ISINC) @<Inline command "printing-routine"@>;
	if (sche->inline_command == ranger_routine_ISINC) @<Inline command "ranger-routine"@>;
	if (sche->inline_command == next_routine_ISINC) @<Inline command "next-routine"@>;
	if (sche->inline_command == previous_routine_ISINC) @<Inline command "previous-routine"@>;
	if (sche->inline_command == strong_kind_ISINC) @<Inline command "strong-kind"@>;
	if (sche->inline_command == weak_kind_ISINC) @<Inline command "weak-kind"@>;

@ The following produces a new value of the given kind. If it's stored as a
word value, this will just be the default value, so |{-new:time}| will output
540, that being the Inform 6 representation of 9:00 AM. If it's a block value,
we compile code which creates a new value stored on the heap. This comes into
its own when kind variables are in play.

@<Inline command "new"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (Kinds::Behaviour::uses_pointer_values(K)) Frames::emit_allocation(K);
	else if (K == NULL) @<Issue an inline no-such-kind problem@>
	else if (Kinds::RunTime::emit_default_value_as_val(K, EMPTY_WORDING, NULL) == FALSE)
		@<Issue problem for no natural choice@>;
	return;

@<Issue problem for no natural choice@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoNaturalDefault2));
	Problems::issue_problem_segment(
		"To achieve %1, we'd need to be able to store a default value of "
		"the kind '%2', but there's no natural choice for this.");
	Problems::issue_problem_end();

@ The following complication makes lists of a given description. The inline
definition:
= (text)
	LIST_OF_TY_Desc({-new:list of K}, {D}, {-strong-kind:K})
=
is not good enough, because it fails if the description D makes reference to
local variables (as it well may); instead we must construe D as a deferred
proposition.

@<Inline command "new-list-of"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	Calculus::Deferrals::emit_list_of_S(tokens->args[0], K);
	return;

@<Inline command "next-routine"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (K) Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_inc_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "previous-routine"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (K) Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_dec_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "printing-routine"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (K) Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "ranger-routine"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if ((Kinds::Compare::eq(K, K_number)) ||
		(Kinds::Compare::eq(K, K_time)))
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GENERATERANDOMNUMBER_HL));
	else if (K) Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_ranger_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "strong-kind"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (K) Kinds::RunTime::emit_strong_id_as_val(K);
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "weak-kind"@> =
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand, Node::get_kind_variable_declarations(inv));
	if (K) Kinds::RunTime::emit_weak_id_as_val(K);
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Issue an inline no-such-kind problem@> =
	StandardProblems::inline_problem(_p_(PM_InlineNew), ph, sche->owner->parent_schema->converted_from,
		"I don't know any kind called '%4'.");

@h Typographic commands.
These rather crude commands work on a character-by-character level in the
code we're generating.

@<Expand a bracing containing a typographic command@> =
	if (sche->inline_command == backspace_ISINC) @<Inline command "backspace"@>;
	if (sche->inline_command == erase_ISINC) return;
	if (sche->inline_command == open_brace_ISINC) @<Inline command "open-brace"@>;
	if (sche->inline_command == close_brace_ISINC) @<Inline command "close-brace"@>;

@ The first two commands control the stream of text produced in inline
definition expansion, allowing us to back up along it. First, a single
character:

@<Inline command "backspace"@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BackspaceWithdrawn));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, "
		"but this contained the invalid annotation '{backspace}', "
		"which has been withdrawn. (Inline annotations are no longer "
		"allowed to amend the compilation stream to their left.)");
	Problems::issue_problem_end();
	return;

@ These should never occur in well-formed inter schemas; a schema would fail
lint if they did.

@<Inline command "open-brace"@> =
	return;

@<Inline command "close-brace"@> =
	return;

@h Label or counter commands.
Here we want to generate unique numbers, or uniquely named labels, on demand.

@<Expand a bracing containing a label or counter command@> =
	if (sche->inline_command == label_ISINC) @<Inline command "label"@>;
	if (sche->inline_command == counter_ISINC) @<Inline command "counter"@>;
	if (sche->inline_command == counter_storage_ISINC) @<Inline command "counter-storage"@>;
	if (sche->inline_command == counter_up_ISINC) @<Inline command "counter-up"@>;
	if (sche->inline_command == counter_down_ISINC) @<Inline command "counter-down"@>;
	if (sche->inline_command == counter_makes_array_ISINC) @<Inline command "counter-makes-array"@>;

@ We can have any number of sets of labels, each with its own base name,
which should be supplied as the argument. For example:
= (text)
	{-label:pineapple}
=
generates the current label in the "pineapple" set. (Sets don't need to be
declared: they can be mentioned the first time they are used.) These label
names take the form |L_pineapple_0|, |L_pineapple_1|, and so on; each named
set has its own counter (0, 1, 2, ...). So this inline definition works
safely:
= (text)
	jump {-label:leap}; print "Yikes! A trap!"; .{-label:leap}{-counter-up:leap};
=
if a little pointlessly, generating first
= (text)
	jump L_leap_0; print "Yikes! A trap!"; .L_leap_0;
=
and then
= (text)
	jump L_leap_1; print "Yikes! A trap!"; .L_leap_1;
=
and so on. The point of this is that it guarantees we won't define two labels
with identical names in the same Inform 6 routine, which would fail to compile.

@<Inline command "label"@> =
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".");
	JumpLabels::write(L, sche->operand);
	Produce::lab(Emit::tree(), Produce::reserve_label(Emit::tree(), L));
	DISCARD_TEXT(L)
	return;

@ We can also output just the numerical counter:

@<Inline command "counter"@> =
	Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) JumpLabels::read_counter(sche->operand, NOT_APPLICABLE));
	return;

@ We can also output just the storage array:

@<Inline command "counter-storage"@> =
	Produce::val_iname(Emit::tree(), K_value, JumpLabels::storage(sche->operand));
	return;

@ Or increment it, printing nothing:

@<Inline command "counter-up"@> =
	JumpLabels::read_counter(sche->operand, TRUE);
	return;

@ Or decrement it. (Careful, though: if it decrements below zero, an enigmatic
internal error will halt Inform.)

@<Inline command "counter-down"@> =
	JumpLabels::read_counter(sche->operand, FALSE);
	return;

@ We can use counters for anything, not just to generate labels, and one
useful trick is to allocate storage at run-time. Invoking
= (text)
	{-counter-makes-array:pineapple}
=
at any time during compilation (once or many times over, it makes no
difference) causes Inform to generate an array called |I7_ST_pineapple|
guaranteed to contain one entry for each counter value reached. Thus:

>> To remember (N - a number) for later: ...

might be defined inline as
= (text)
	{-counter-makes-array:pineapple}I7_ST_pineapple-->{-counter:pineapple} = {N};
=
and the effect will be to accumulate an array of numbers during compilation.
Note that the value of a counter can also be read in template language,
so with a little care we can get the final extent of the array, too. If more
than one word of storage per count is needed, try:
= (text)
	{-counter-makes-array:pineapple:3}
=
or similar -- this ensures that the array contains not fewer than three times
as many cells as the final value of the count. (If multiple invocations are
made with different numbers here, the maximum is taken.)

@<Inline command "counter-makes-array"@> =
	int words_per_count = 1;
	if (Str::len(sche->operand2) > 0) words_per_count = Str::atoi(sche->operand2, 0);
	JumpLabels::allocate_counter(sche->operand, words_per_count);
	return;

@h Token annotations.
The next category of invocation commands takes the form of an "annotation"
slightly changing the way a token would normally be compiled, but basically
using the same machinery as if the annotation hadn't been there.

@<Take account of any annotation to the inline token@> =
	int valid_annotation = FALSE;
	if (sche->inline_command == by_reference_ISINC) @<Inline annotation "by-reference"@>;
	if (sche->inline_command == by_reference_blank_out_ISINC) @<Inline annotation "by-reference-blank-out"@>;
	if (sche->inline_command == reference_exists_ISINC) @<Inline annotation "reference-exists"@>;
	if (sche->inline_command == lvalue_by_reference_ISINC) @<Inline annotation "lvalue-by-reference"@>;
	if (sche->inline_command == by_value_ISINC) @<Inline annotation "by-value"@>;

	if (sche->inline_command == box_quotation_text_ISINC) @<Inline annotation "box-quotation-text"@>;

	#ifdef IF_MODULE
	if (sche->inline_command == try_action_ISINC) @<Inline annotation "try-action"@>;
	if (sche->inline_command == try_action_silently_ISINC) @<Inline annotation "try-action-silently"@>;
	#endif

	if (sche->inline_command == return_value_ISINC) @<Inline annotation "return-value"@>;
	if (sche->inline_command == return_value_from_rule_ISINC) @<Inline annotation "return-value-from-rule"@>;

	if (sche->inline_command == property_holds_block_value_ISINC) @<Inline annotation "property-holds-block-value"@>;
	if (sche->inline_command == mark_event_used_ISINC) @<Inline annotation "mark-event-used"@>;

	if ((sche->inline_command != no_ISINC) && (valid_annotation == FALSE))
		@<Throw a problem message for an invalid inline annotation@>;

@ This affects only block values. When it's used, the token accepts the pointer
to the block value directly, that is, not copying the data over to a fresh
copy and using that instead. This means a definition like:

>> To zap (L - a list of numbers): (- Zap({-by-reference:L}, 10); -).

will call |Zap| on the actual list supplied to it. If |Zap| chooses to change
this list, the original will change.

@<Inline annotation "by-reference"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;

@ And, variedly:

@<Inline annotation "by-reference-blank-out"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;
	blank_out = TRUE;

@ And, variedly:

@<Inline annotation "reference-exists"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;
	reference_exists = TRUE;

@ This is a variant which checks that the reference is to an lvalue, that
is, to something which can be changed. If this weren't done, then

>> remove 2 from {1, 2, 3}

would compile without problem messages, though it would behave pretty oddly
at run-time.

@<Inline annotation "lvalue-by-reference"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;
	require_to_be_lvalue = TRUE;

@ This is the default, so it's redundant, but clarifies definitions.

@<Inline annotation "by-value"@> =
	by_value_not_reference = TRUE;
	valid_annotation = TRUE;

@ This is used only for the box statement in I6, which has slightly different
textual requirements than regular I6 text. We could get rid of this by making
a kind for box-quotation-text, and casting regular text to it, but honestly
having this annotation seems the smaller of the two warts.

@<Inline annotation "box-quotation-text"@> =
	if (Rvalues::is_CONSTANT_of_kind(supplied, K_text) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_spec(2, supplied);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Misboxed));
		Problems::issue_problem_segment(
			"I attempted to compile %1, but the text '%2' supplied to be a "
			"boxed quotation wasn't a constant piece of text in double-quotes. "
			"I'm afraid that's the only sort of text allowed here.");
		Problems::issue_problem_end();
		return;
	} else {
		COMPILATION_MODE_ENTER(COMPILE_TEXT_TO_QUOT_CMODE);
		by_value_not_reference = FALSE;
		valid_annotation = TRUE;
	}

@ Suppose we are invoking:

>> decide on 102;

from the Standard Rules definition:
= (text)
	return {-return-value:something};
=
We clearly need to police this: if the phrase is deciding a number, we need
to object to:

>> decide on "fish fingers";

That's one purpose of this annotation: it checks the value to see if it's
suitable to be returned. But we also might have to cast the value, or
check that it's valid at run-time. For instance, in a phrase to decide a
container, given

>> decide on the item;

we may need to check "item" at run-time: at compile-time we know it's an
object, but not necessarily that it's a container.

@<Inline annotation "return-value"@> =
	int returning_from_rule = FALSE;
	@<Handle an inline return@>;

@ Exactly the same mechanism is needed for rules which produce a value, but
the problem messages are phrased differently if something goes wrong.

@<Inline annotation "return-value-from-rule"@> =
	int returning_from_rule = TRUE;
	@<Handle an inline return@>;

@ So here's the common code:

@<Handle an inline return@> =
	kind *kind_needed;
	if (returning_from_rule) kind_needed = Rulebooks::kind_from_context();
	else kind_needed = Frames::get_kind_returned();
	kind *kind_supplied = Specifications::to_kind(supplied);

	int mor = Phrases::TypeData::get_mor(&(phrase_being_compiled->type_data));

	int allow_me = ALWAYS_MATCH;
	if ((kind_needed) && (Kinds::Compare::eq(kind_needed, K_nil) == FALSE))
		allow_me = Kinds::Compare::compatible(kind_supplied, kind_needed);
	else if ((mor == DECIDES_CONDITION_MOR) && (Kinds::Compare::eq(kind_supplied, K_truth_state)))
		allow_me = ALWAYS_MATCH;
	else @<Issue a problem for returning a value when none was asked@>;

	if (allow_me == ALWAYS_MATCH) {
		Specifications::Compiler::emit_to_kind(supplied, kind_needed);
	} else if ((allow_me == SOMETIMES_MATCH) && (Kinds::Compare::le(kind_needed, K_object))) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(CHECKKINDRETURNED_HL));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_to_kind(supplied, kind_needed);
			Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(kind_needed));
		Produce::up(Emit::tree());
	} else @<Issue a problem for returning a value of the wrong kind@>;

	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@<Issue a problem for returning a value when none was asked@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind_of(2, supplied);
	if (returning_from_rule) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RuleNotAllowedOutcome));
		Problems::issue_problem_segment(
			"You wrote %1 as something to be a successful outcome of a rule, which "
			"has the kind %2; but this is not a rule which is allowed to have a value "
			"as its outcome.");
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RedundantReturnKOV));
		Problems::issue_problem_segment(
			"You wrote %1 as the outcome of a phrase, %2, but in the definition of "
			"something which was not a phrase to decide a value.");
		Problems::issue_problem_end();
	}

@<Issue a problem for returning a value of the wrong kind@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, kind_supplied);
	Problems::quote_kind(3, kind_needed);
	if (returning_from_rule) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RuleOutcomeWrongKind));
		Problems::issue_problem_segment(
			"You wrote %1 as the outcome of a rule which produces a value, but this "
			"was the wrong kind of value: %2 rather than %3.");
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ReturnWrongKind));
		Problems::issue_problem_segment(
			"You wrote %1 as the outcome of a phrase to decide a value, but this was "
			"the wrong kind of value: %2 rather than %3.");
		Problems::issue_problem_end();
	}

@<Inline annotation "try-action"@> =
	if (Rvalues::is_CONSTANT_of_kind(supplied, K_stored_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(supplied);
		PL::Actions::Patterns::emit_try(ap, FALSE);
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(STORED_ACTION_TY_TRY_HL));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_stored_action, supplied);
		Produce::up(Emit::tree());
	}
	valid_annotation = TRUE;
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@<Inline annotation "try-action-silently"@> =
	if (Rvalues::is_CONSTANT_of_kind(supplied, K_stored_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(supplied);
		Produce::inv_primitive(Emit::tree(), PUSH_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(KEEP_SILENT_HL));
		Produce::up(Emit::tree());
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(KEEP_SILENT_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
		Produce::inv_primitive(Emit::tree(), PUSH_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SAY__P_HL));
		Produce::up(Emit::tree());
		Produce::inv_primitive(Emit::tree(), PUSH_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SAY__PC_HL));
		Produce::up(Emit::tree());
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(CLEARPARAGRAPHING_HL));
		Produce::down(Emit::tree());
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
		PL::Actions::Patterns::emit_try(ap, FALSE);
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIVIDEPARAGRAPHPOINT_HL));
		Produce::inv_primitive(Emit::tree(), PULL_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(SAY__PC_HL));
		Produce::up(Emit::tree());
		Produce::inv_primitive(Emit::tree(), PULL_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(SAY__P_HL));
		Produce::up(Emit::tree());
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(ADJUSTPARAGRAPHPOINT_HL));
		Produce::inv_primitive(Emit::tree(), PULL_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(KEEP_SILENT_HL));
		Produce::up(Emit::tree());
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(STORED_ACTION_TY_TRY_HL));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_stored_action, supplied);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	}
	valid_annotation = TRUE;
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@ Suppose we have a token which is a property name, and we want to know about
the kind of value the property holds. We can't simply take the kind of the
token, because that would be "property name". Instead:

@<Inline annotation "property-holds-block-value"@> =
	property *prn = Rvalues::to_property(supplied);
	if ((prn == NULL) || (Properties::is_either_or(prn))) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	} else {
		kind *K = Properties::Valued::kind(prn);
		if (Kinds::Behaviour::uses_pointer_values(K)) {
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		} else {
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
		}
	}
	return;

@ This little annotation is used for the phrases about timed rule firing:

>> To (R - rule) in (t - number) turn/turns from now: ...

has the inline definition:
= (text)
	SetTimedEvent({-mark-event-used:R}, {t}+1, 0);
=
The annotation makes no difference to how R is compiled, except that it
sneaks in a sanity check (R must be explicitly named and must be an event
rule), and also makes a note for indexing purposes.

@<Inline annotation "mark-event-used"@> =
	if (Rvalues::is_CONSTANT_construction(supplied, CON_rule)) {
		rule *R = Rvalues::to_rule(supplied);
		phrase *ph = Rules::get_I7_definition(R);
		if (ph) Phrases::Timed::note_usage(ph, current_sentence);
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(supplied));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NonconstantEvent));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' isn't the name of any timed event that "
			"I know of. (These need to be set up in a special way, like so - "
			"'At the time when stuff happens: ...' creates a timed event "
			"called 'stuff happens'.)");
		Problems::issue_problem_end();
	}
	valid_annotation = TRUE;

@<Throw a problem message for an invalid inline annotation@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_stream(2, sche->command);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadInlineTag));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, "
		"but this contained the invalid annotation '%2'.");
	Problems::issue_problem_end();
	return;

@h High-level commands.
This category is intended for powerful and flexible commands, allowing for
invocations which behave like control statements in other languages. (See
also |{-block}| above, though that is syntactically a divider rather than
a command, which is why it isn't here.)

@<Expand a bracing containing a high-level command@> =
	if (sche->inline_command == my_ISINC) @<Inline command "my"@>;
	if (sche->inline_command == unprotect_ISINC) @<Inline command "unprotect"@>;
	if (sche->inline_command == copy_ISINC) @<Inline command "copy"@>;
	if (sche->inline_command == initialise_ISINC) @<Inline command "initialise"@>;
	if (sche->inline_command == matches_description_ISINC) @<Inline command "matches-description"@>;
	if (sche->inline_command == now_matches_description_ISINC) @<Inline command "now-matches-description"@>;
	if (sche->inline_command == arithmetic_operation_ISINC) @<Inline command "arithmetic-operation"@>;
	if (sche->inline_command == say_ISINC) @<Inline command "say"@>;
	if (sche->inline_command == show_me_ISINC) @<Inline command "show-me"@>;

@ The |{-my:name}| command creates a local variable for use in the invocation,
and then prints the variable's name. (If the same variable is created twice,
the second time it's simply printed.)

@<Inline command "my"@> =
	local_variable *lvar = NULL;
	int n = Str::get_at(sche->operand, 0) - '0';
	if ((Str::get_at(sche->operand, 1) == 0) && (n >= 0) && (n < 10)) @<A single digit as the name@>
	else @<An Inform 6 identifier as the name@>;
	inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
	if (prim_cat == REF_PRIM_CAT) Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
	else Produce::val_symbol(Emit::tree(), K_value, lvar_s);
	return;

@ In the first form, we don't give an explicit name, but simply a digit from
0 to 9. We're therefore allowed to create up to 10 variables this way, and
the ones we create will be different from those made by any other invocation
(including other invocations of the same phrase). For example:

>> To Throne Room (P - phrase):

which is a phrase to repeat a single phrase P twice, could be defined thus:
= (text)
	(- for ({-my:1}=1; {-my:1}<=2; {-my:1}++) {P} -)
=
The variable lasts only until the end of the invocation. In general, given
this:

>> Throne Room say "Village.";
>> Throne Room say "Goons.";

...Inform will reallocate the same Inform 6 local as |{-my:1}| in each
invocation, because it safely can. But if the phrase starts a code block,
as in a more elaborate loop, then the variable lasts for the lifetime of
that code block.

@<A single digit as the name@> =
	lvar = my_vars[n];
	if (lvar == NULL) {
		my_vars[n] = LocalVariables::new(EMPTY_WORDING, K_number);
		lvar = my_vars[n];
		@<Set the kind of the my-variable@>;
		if (Phrases::TypeData::block_follows(ph))
			Frames::Blocks::set_scope_to_block_about_to_open(lvar);
	}

@ The second form is simpler. |{-my:1}| and such make locals with names like
|tmp_3|, which we have no control over. Here we get to make a local with
exactly the name we want. This can't be reallocated, of course; it's there
throughout the routine, so there's no question of setting its scope.
For example:

>> To be warned: ...

could be defined as:
= (text)
	(- {-my:warn} = true; -)
=
and then

>> To decide if we have been warned: ...

as
= (text)
	({-my:warn})
=
the net result being that if either phrase is used, then |warn| becomes a
local variable. The second phrase tests if the first has been used.

Nothing, of course, stops some other invocation from using a variable of
the same name for some quite different purpose, wreaking havoc. This is
why the numbered scheme above is mostly better.

@<An Inform 6 identifier as the name@> =
	lvar = LocalVariables::add_internal_local(sche->operand);
	@<Set the kind of the my-variable@>;

@ Finally, it's possible to set the I7 kind of a variable created by |{-my:...}|,
though there are hardly any circumstances where this is necessary, since I6
is typeless. But in a few cases where I7 is embedded inside I6 inside I7,
or when a block value is needed, or where we need to match against descriptions
(see below) where kind-checking comes into play, it could arise. For example:
= (text)
	{-my:1:list of numbers}
=

@<Set the kind of the my-variable@> =
	kind *K = NULL;
	if (Str::len(sche->operand2) > 0)
		K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand2,
			Node::get_kind_variable_declarations(inv));
	if (K == NULL) K = K_object;
	LocalVariables::set_kind(lvar, K);

@ Variables created by phrases are by default protected from being changed
by other phrases. So that, for example, within:

>> repeat with X running from 1 to 5:

it's a problem message to say something like "let X be 7". This protection
only extends to changes made at the I7 source text level, of course; our own
I6 code can do anything it likes. Protection looks like a good idea,
especially for loop counters like X, but of course it would make phrases
like:

>> let Y be 2;

unable to make variables, only constants. So the |{-unprotect:...}| command
lifts the protection on the variable named:

@<Inline command "unprotect"@> =
	parse_node *v =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	local_variable *lvar = Lvalues::get_local_variable_if_any(v);

	if (lvar) LocalVariables::unprotect(lvar);
	else @<Issue a no-such-local problem message@>;
	return;

@ Something to be careful of is that a variable created with |{-my:...}|,
or indeed a variable created explicitly by the phrase, may not begin with
contents which are typesafe for the kind you intend it to hold. Usually this
doesn't matter because it is immediately written with some value which is
indeed typesafe, and there's no problem. But if not, try using this:
|{-initialise:var:kind}| takes the named local variable and gives it the
default value for that kind. If the kind is omitted, the default is to use
the kind of the variable. For example,
= (text)
	{-my:1:time}{-initialise:1}
=
Note that this works only for kinds of word value, like "time". For kinds
of block value, like "list of numbers", it does nothing. This may seem odd,
but the point is that locals of that kind are automatically set to their
default values when created, so they are always typesafe anyway.

@<Inline command "initialise"@> =
	parse_node *V = Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	local_variable *lvar = Lvalues::get_local_variable_if_any(V);
	kind *K = NULL;
	if (Str::len(sche->operand2) > 0)
		K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand2, Node::get_kind_variable_declarations(inv));
	else
		K = Specifications::to_kind(V);

	if (Kinds::Behaviour::uses_pointer_values(K)) {
		if (Frames::Blocks::inside_a_loop_body()) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECOPY_HL));
			Produce::down(Emit::tree());
				inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
				Produce::val_symbol(Emit::tree(), K_value, lvar_s);
				Kinds::RunTime::emit_default_value_as_val(K, Node::get_text(V), "value");
			Produce::up(Emit::tree());
		}
	} else {
		int rv = FALSE;
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
			Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
			rv = Kinds::RunTime::emit_default_value_as_val(K, Node::get_text(V), "value");
		Produce::up(Emit::tree());

		if (rv == FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, K);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoNaturalDefault));
			Problems::issue_problem_segment(
				"To achieve %1, we'd need to be able to store a default value of "
				"the kind '%2', but there's no natural choice for this.");
			Problems::issue_problem_end();
		}
	}
	return;

@ The |{-copy:...}| command allows us to copy the content in a token or
variable into any storage item (a local variable, a global, a table entry,
a list entry), regardless of its kind of value. For example:

>> To let (t - nonexisting variable) be (u - value) (assignment operation): ...

is defined inline as:
= (text)
	{-unprotect:t}{-copy:t:u}
=
This may look superfluous: for example, in response to

>> let X be 10;

it generates only something like:
= (text)
	tmp_0 = 10;
=
which could have been achieved equally well with:
= (text)
	{-unprotect:t}{t} = {u};
=
But it makes something much more elaborate in response to, say:

>> let Y be the list of people in dark rooms;

where it's important to keep track of the allocation and deallocation of
dynamic lists, since Y is a block value not a word value. The point of the
|{-copy:to:from}| command is to hide all that complexity from the definer.

@<Inline command "copy"@> =
	int copy_form = 0;
	parse_node *from = NULL, *to = NULL;
	@<Find what we are copying from, to and how@>;
	@<Check that we're not copying to something the user isn't allowed to change@>;

	pcalc_term pt1 = Calculus::Terms::new_constant(to);
	pcalc_term pt2 = Calculus::Terms::new_constant(from);
	kind *K1 = Specifications::to_kind(to);
	kind *K2 = Specifications::to_kind(from);
	node_type_t storage_class = Lvalues::get_storage_form(to);
	if (copy_form != 0) @<Check that increment or decrement make sense@>;
	char *prototype = Lvalues::interpret_store(storage_class, K1, K2, copy_form);
	i6_schema *sch = Calculus::Schemas::new("%s;", prototype);
	LOGIF(KIND_CHECKING, "Inline copy: %s\n", prototype);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
	Calculus::Schemas::emit_expand_from_terms(sch, &pt1, &pt2, FALSE);
	END_COMPILATION_MODE;
	return;

@ If the |from| part is prefaced with a plus sign |+|, the new value is added
to the current value rather than replacing it; if |-|, it's subtracted. For
example,

>> To increase (S - storage) by (w - value) (assignment operation): ...

has the inline definition |{-copy:S:+w}|. Lastly, it's also legal to write
just a |+| or |-| sign alone, which increments or decrements. Be wary here,
because |{-copy:S:+}| adds 1 to S, whereas |{-copy:S:+1}| adds the value
of the variable {-my:1} to S.

@<Find what we are copying from, to and how@> =
	TEMPORARY_TEXT(from_p)

	int c = Str::get_first_char(sche->operand2);
	if (c == '+') { copy_form = 1; Str::copy_tail(from_p, sche->operand2, 1); }
	else if (c == '-') { copy_form = -1; Str::copy_tail(from_p, sche->operand2, 1); }
	else Str::copy(from_p, sche->operand2);

	if ((Str::len(from_p) == 0) && (copy_form != 0))
		from = Rvalues::from_int(1, EMPTY_WORDING);
	else if (Str::len(from_p) > 0)
		from = Invocations::Inline::parse_bracing_operand_as_identifier(from_p, ph, tokens, my_vars);

	to = Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);

	if ((to == NULL) || (from == NULL)) {
		Problems::quote_stream(4, sche->operand);
		Problems::quote_stream(5, sche->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineCopy), ph, sche->owner->parent_schema->converted_from,
			"The command to {-copy:...}, which asks to copy '%5' into '%4', has "
			"gone wrong: I couldn't work those out.");
		return;
	}
	DISCARD_TEXT(from_p)

@ Use of |{-copy:...}| will produce problem messages if the target is a protected
local variable, or a global which isn't allowed to change in play (such as the
story title).

@<Check that we're not copying to something the user isn't allowed to change@> =
	nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(to);
	if ((nlv) && (NonlocalVariables::must_be_constant(nlv))) return;
	if (nlv) NonlocalVariables::warn_about_change(nlv);

	local_variable *lvar = Lvalues::get_local_variable_if_any(to);
	if ((lvar) && (LocalVariables::protected(lvar))) return;

@ One can't, for example, increment a backdrop, or a text.

@<Check that increment or decrement make sense@> =
	if (Kinds::Behaviour::is_quasinumerical(K1) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, K1);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantIncrementKind));
		Problems::issue_problem_segment(
			"To achieve %1, we'd need to be able to add or subtract 1 from "
			"a value of the kind '%2', but there's no good way to do this.");
		Problems::issue_problem_end();
		return;
	}

@ The next command generates code able to test if a token in the invocation,
or an I6 variable, matches a given description -- which need not be constant.
For example,

>> To say a list of (OS - description of objects): ...

is defined in the Standard Rules thus:
= (text)
	objectloop({-my:itm} ofclass Object)
	    if ({-matches-description:itm:OS})
	        give itm workflag2;
	    else
	        give itm ~workflag2;
	WriteListOfMarkedObjects(ENGLISH_BIT);
=
The whole "workflag" nonsense is Inform 6 convention from the stone age, but
the basic point here is that the loop does one thing if an object matches
the description and another if it doesn't. (In this example |itm| was a
local I6 variable and |OS| a token from the invocation, but these can be
mixed freely. Or we could use a single digit to refer to a numbered "my"
variable.)

@<Inline command "matches-description"@> =
	parse_node *to_match =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand2, ph, tokens, my_vars);
	parse_node *to_test =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	if ((to_test == NULL) || (to_match == NULL)) {
		Problems::quote_stream(4, sche->operand);
		Problems::quote_stream(5, sche->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineMatchesDescription), ph, sche->owner->parent_schema->converted_from,
			"The command {-matches-description:...}, which asks to test whether "
			"'%5' is a valid description for '%4', has gone wrong: I couldn't "
			"work those out.");
	} else {
		Calculus::Deferrals::emit_substitution_test(to_test, to_match);
	}
	return;

@ This is the same, except that it compiles code to assert that the given
variable matches the given description.

@<Inline command "now-matches-description"@> =
	parse_node *to_test =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	parse_node *to_match =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand2, ph, tokens, my_vars);
	if ((to_test == NULL) || (to_match == NULL)) {
		Problems::quote_stream(4, sche->operand);
		Problems::quote_stream(5, sche->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineNowMatchesDescription),
			ph, sche->owner->parent_schema->converted_from,
			"The command {-now-matches-description:...}, which asks to change "
			"'%4' so that '%5' becomes a valid description of it, has gone "
			"wrong: I couldn't work those out.");
	} else {
		Calculus::Deferrals::emit_substitution_now(to_test, to_match);
	}
	return;

@<Inline command "arithmetic-operation"@> =
	int op = Phrases::TypeData::arithmetic_operation(ph);
	int binary = TRUE;
	if (Kinds::Dimensions::arithmetic_op_is_unary(op)) binary = FALSE;
	parse_node *X = NULL, *Y = NULL;
	kind *KX = NULL, *KY = NULL;
	@<Read the operands and their kinds@>;
	Kinds::Compile::perform_arithmetic_emit(op, NULL, X, NULL, KX, Y, NULL, KY);
	return;

@<Read the operands and their kinds@> =
	X = Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	KX = Specifications::to_kind(X);
	if (binary) {
		Y = Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand2, ph, tokens, my_vars);
		KY = Specifications::to_kind(Y);
	}

@ This prints a token or variable using the correct format for its kind. The
code below optimises this so that constant text is printed directly, rather
than stored as a constant text value and printed by a call to |TEXT_TY_Say|:
this saves 2 words of memory and a function call at print time. But the
result would be the same without the optimisation.

@<Inline command "say"@> =
	parse_node *to_say =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	if (to_say == NULL) {
		@<Issue a no-such-local problem message@>;
		return;
	}
	kind *K = Invocations::Inline::parse_bracing_operand_as_kind(sche->operand2,
		Node::get_kind_variable_declarations(inv));

	if (Kinds::Compare::eq(K, K_text)) @<Inline say text@>;
	if (Kinds::Compare::eq(K, K_number)) @<Inline say number@>;
	if (Kinds::Compare::eq(K, K_unicode_character)) @<Inline say unicode character@>;
	if (K) {
		Produce::inv_call_iname(Emit::tree(), Kinds::Behaviour::get_iname(K));
		Produce::down(Emit::tree());
			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
			Specifications::Compiler::emit_to_kind(to_say, K);
			END_COMPILATION_MODE;
		Produce::up(Emit::tree());
	} else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline say text@> =
	wording SW = Node::get_text(to_say);
	if ((Rvalues::is_CONSTANT_of_kind(to_say, K_text)) &&
		(Wordings::length(SW) == 1) &&
		(Vocabulary::test_flags(Wordings::first_wn(SW), TEXTWITHSUBS_MC) == FALSE)) {
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			TEMPORARY_TEXT(T)
			CompiledText::from_wide_string_for_emission(T, Lexer::word_text(Wordings::first_wn(SW)));
			Produce::val_text(Emit::tree(), T);
			DISCARD_TEXT(T)
		Produce::up(Emit::tree());
	} else {
		kind *K = Specifications::to_kind(to_say);
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Produce::inv_call_iname(Emit::tree(), Kinds::Behaviour::get_iname(K));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_to_kind(to_say, K);
		Produce::up(Emit::tree());
		END_COMPILATION_MODE;
	}
	return;

@ Numbers are also handled directly...

@<Inline say number@> =
	Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__N_HL));
			Specifications::Compiler::emit_to_kind(to_say, K);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	return;

@ And similarly for Unicode characters. It would be tidier to abstract this
with a function call, but it would cost a function call.

Note that emitting a Unicode character requires different code on the Z-machine
to Glulx; we have to handle this within I6 conditional compilation blocks
because neither syntax will compile when I6 is compiling for the other VM.

@<Inline say unicode character@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(UNICODE_TEMP_HL));
		Specifications::Compiler::emit_to_kind(to_say, K);
	Produce::up(Emit::tree());
	if (TargetVMs::is_16_bit(Task::vm())) {
		Produce::inv_assembly(Emit::tree(), I"@print_unicode");
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(UNICODE_TEMP_HL));
		Produce::up(Emit::tree());
	} else {
		Produce::inv_assembly(Emit::tree(), I"@streamunichar");
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(UNICODE_TEMP_HL));
		Produce::up(Emit::tree());
	}
	return;

@ This is for debugging purposes only: it does the equivalent of the "showme"
phrase applied to the named variable.

@<Inline command "show-me"@> =
	parse_node *to_show =
		Invocations::Inline::parse_bracing_operand_as_identifier(sche->operand, ph, tokens, my_vars);
	if (to_show == NULL) {
		@<Issue a no-such-local problem message@>;
		return;
	}
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	Produce::inv_primitive(Emit::tree(), IFDEBUG_BIP);
	Produce::down(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			PL::Parsing::TestScripts::emit_showme(to_show);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	END_COMPILATION_MODE;
	return;

@h Miscellaneous commands.
These really have nothing in common, except that each can be used only in
very special circumstances.

@<Expand a bracing containing a miscellaneous command@> =
	if (sche->inline_command == segment_count_ISINC) @<Inline command "segment-count"@>;
	if (sche->inline_command == final_segment_marker_ISINC) @<Inline command "final-segment-marker"@>;
	if (sche->inline_command == list_together_ISINC) @<Inline command "list-together"@>;
	if (sche->inline_command == rescale_ISINC) @<Inline command "rescale"@>;

@ These two are publicly documented, and have to do with multiple-segment
"say" phrases.

@<Inline command "segment-count"@> =
	Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) Annotations::read_int(inv, ssp_segment_count_ANNOT));
	return;

@<Inline command "final-segment-marker"@> =
	if (Annotations::read_int(inv, ssp_closing_segment_wn_ANNOT) == -1) {
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(NULL_HL));
	} else {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, "%~W", Wordings::one_word(Annotations::read_int(inv, ssp_closing_segment_wn_ANNOT)));
		inter_symbol *T_s = EmitInterSchemas::find_identifier_text(Emit::tree(), T, NULL, NULL);
		Produce::val_symbol(Emit::tree(), K_value, T_s);
		DISCARD_TEXT(T)
	}
	return;

@ This is a shim for an old Inform 6 library feature. It's used only to define
the "group... together" phrases.

@<Inline command "list-together"@> =
	if (sche->inline_subcommand == unarticled_ISINSC) {
		inter_name *iname = ListTogether::new(FALSE);
		Produce::val_iname(Emit::tree(), K_value, iname);
	} else if (sche->inline_subcommand == articled_ISINSC) {
		inter_name *iname = ListTogether::new(TRUE);
		Produce::val_iname(Emit::tree(), K_value, iname);
	} else StandardProblems::inline_problem(_p_(PM_InlineListTogether),
		ph, sche->owner->parent_schema->converted_from,
		"The only legal forms here are {-list-together:articled} and "
		"{-list-together:unarticled}.");
	return;

@ This exists to manage scaled arithmetic, and should only be used for the
mathematical definitions in the Standard Rules.

@<Inline command "rescale"@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RescaleWithdrawn));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, "
		"but this contained the invalid annotation '{-rescale:...}', "
		"which has been withdrawn.");
	Problems::issue_problem_end();
	return;

@h Primitive definitions.
Some phrases are just too complicated to express in invocation language,
especially those involving complicated linguistic propositions. For example:

>> To decide which arithmetic value is total (p - arithmetic value valued property) of (S - description of values): ...

has the inline definition:
= (text)
	(- {-primitive-definition:total-of} -).
=

@<Expand an entirely internal-made definition@> =
	if (sche->inline_subcommand == repeat_through_ISINSC) {
			Calculus::Deferrals::emit_repeat_through_domain_S(tokens->args[1],
				Lvalues::get_local_variable_if_any(tokens->args[0]));
	}

	else if (sche->inline_subcommand == repeat_through_list_ISINSC) {
		Calculus::Deferrals::emit_loop_over_list_S(tokens->args[1],
			Lvalues::get_local_variable_if_any(tokens->args[0]));
	}

	else if (sche->inline_subcommand == number_of_ISINSC) {
		Calculus::Deferrals::emit_number_of_S(tokens->args[0]);
	}

	else if (sche->inline_subcommand == random_of_ISINSC) {
		Calculus::Deferrals::emit_random_of_S(tokens->args[0]);
	}

	else if (sche->inline_subcommand == total_of_ISINSC) {
		Calculus::Deferrals::emit_total_of_S(
			Rvalues::to_property(tokens->args[0]), tokens->args[1]);
	}

	else if (sche->inline_subcommand == extremal_ISINSC) {
		if ((sche->extremal_property_sign != MEASURE_T_EXACTLY) && (sche->extremal_property)) {
			Calculus::Deferrals::emit_extremal_of_S(tokens->args[0],
				sche->extremal_property, sche->extremal_property_sign);
		} else
			StandardProblems::inline_problem(_p_(PM_InlineExtremal),
				ph, sche->owner->parent_schema->converted_from,
				"In the '{-primitive-definition:extremal...}' command, there "
				"should be a '<' or '>' sign then the name of a property.");
	}

	else if (sche->inline_subcommand == function_application_ISINSC) 	@<Primitive "function-application"@>
	else if (sche->inline_subcommand == description_application_ISINSC) @<Primitive "description-application"@>

	else if (sche->inline_subcommand == solve_equation_ISINSC) 		@<Primitive "solve-equation"@>

	else if (sche->inline_subcommand == switch_ISINSC) ;

	else if (sche->inline_subcommand == break_ISINSC) Frames::Blocks::emit_break();

	else if (sche->inline_subcommand == verbose_checking_ISINSC) {
		wchar_t *what = L"";
		if (tokens->tokens_count > 0) {
			parse_node *aspect = tokens->args[0];
			if (Wordings::nonempty(Node::get_text(aspect))) {
				int aw1 = Wordings::first_wn(Node::get_text(aspect));
				Word::dequote(aw1);
				what = Lexer::word_text(aw1);
			}
		}
		Dash::tracing_phrases(what);
	}
	else {
		Problems::quote_stream(4, sche->operand);
		StandardProblems::inline_problem(_p_(PM_InlinePrimitive), ph, sche->owner->parent_schema->converted_from,
			"I don't know any primitive definition called '%4'.");
	}
	return;

@<Primitive "function-application"@> =
	parse_node *fn = tokens->args[0];
	kind *fn_kind = Specifications::to_kind(fn);
	kind *X = NULL, *Y = NULL;
	if (Kinds::get_construct(fn_kind) != CON_phrase) {
		Problems::quote_spec(4, fn);
		StandardProblems::inline_problem(_p_(PM_InlineFunctionApplication),
			ph, sche->owner->parent_schema->converted_from,
			"A function application only makes sense if the first token, "
			"'%4', is a phrase: here it isn't.");
		return;
	}
	Kinds::binary_construction_material(fn_kind, &X, &Y);
	for (int i=1; i<tokens->tokens_count; i++) {
		tokens->args[i-1] = tokens->args[i];
		kind *head = NULL, *tail = NULL;
		Kinds::binary_construction_material(X, &head, &tail);
		X = tail;
		tokens->kind_required[i-1] = NULL;
		if ((Kinds::Behaviour::uses_pointer_values(head)) && (Kinds::Behaviour::definite(head)))
			tokens->kind_required[i-1] = head;
	}
	tokens->tokens_count--;

	Invocations::AsCalls::emit_function_call(tokens, NULL, -1, fn, TRUE);

@<Primitive "description-application"@> =
	parse_node *fn = tokens->args[1];
	tokens->args[1] = tokens->args[0];
	tokens->args[0] = Rvalues::from_int(-1, EMPTY_WORDING);
	tokens->tokens_count = 2;
	Invocations::AsCalls::emit_function_call(tokens, NULL, -1, fn, FALSE);

@<Primitive "solve-equation"@> =
	if (Rvalues::is_CONSTANT_of_kind(tokens->args[1], K_equation)) {
		Equations::emit_solution(Node::get_text(tokens->args[0]),
			Rvalues::to_equation(tokens->args[1]));
	} else {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SolvedNameless),
			"only specific named equations can be solved",
			"not equations arrived at by further calculations or choices. (Sorry: "
			"but there would be no safe way to determine when an equation could "
			"be used, because all equations have differing natures and variables.)");
	}

@<Issue a no-such-local problem message@> =
	Problems::quote_stream(4, sche->operand);
	StandardProblems::inline_problem(_p_(PM_InlineNoSuch), ph, sche->owner->parent_schema->converted_from,
		"I don't know any local variable called '%4'.");

@h Parsing the invocation operands.
Two ways. First, as an identifier name, which stands for a local I6 variable
or for a token in the phrase being invoked. There are three ways we can
write this:

(a) the operands "0" to "9", a single digit, mean the |{-my:...}| variables
with those numbers, if they exist;
(b) otherwise if we have the name of a token in the phrase being invoked,
then the operand refers to its value in the current invocation;
(c) and failing that we have the name of a local I6 variable.

=
parse_node *Invocations::Inline::parse_bracing_operand_as_identifier(text_stream *operand, phrase *ph,
	tokens_packet *tokens, local_variable **my_vars) {
	local_variable *lvar = NULL;
	if ((Str::get_at(operand, 1) == 0) && (Str::get_at(operand, 0) >= '0') && (Str::get_at(operand, 0) <= '9'))
		lvar = my_vars[Str::get_at(operand, 0) - '0'];
	else {
		wording LW = Feeds::feed_text(operand);
		lvar = LocalVariables::parse(&(ph->stack_frame), LW);
		if (lvar) {
			int tok = LocalVariables::get_parameter_number(lvar);
			if (tok >= 0) return tokens->args[tok];
		}
		lvar = LocalVariables::by_name(operand);
	}
	if (lvar) return Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, lvar);
	return NULL;
}

@ The second sort of operand is a kind.

If the kind named involves kind variables A, B, C, ..., then these are
substituted with their values in the context of the invocation being made.
In addition two special kind names are recognised:
= (text)
	return-kind
	rule-return-kind
=
The former being the return kind from the phrase we are being invoked in
(if it's a phrase to decide a value), and the latter being the kind of value
which this rule should produce (if it's a rule, and if it's in a rulebook
which wants to produce a value). For example, you could define a phrase
which would safely abandon any attempt to define a value like this:

>> To give up deciding: (- return {-new:return-kind}; -).

=
kind *Invocations::Inline::parse_bracing_operand_as_kind(text_stream *operand, kind_variable_declaration *kvd) {
	if (Str::eq_wide_string(operand, L"return-kind")) return Frames::get_kind_returned();
	if (Str::eq_wide_string(operand, L"rule-return-kind")) return Rulebooks::kind_from_context();
	kind *kind_vars_inline[27];
	for (int i=0; i<27; i++) kind_vars_inline[i] = NULL;
	for (; kvd; kvd=kvd->next) kind_vars_inline[kvd->kv_number] = kvd->kv_value;
	kind **saved = Frames::temporarily_set_kvs(kind_vars_inline);
	wording KW = Feeds::feed_text(operand);

	parse_node *spec = NULL;
	if (<s-type-expression>(KW)) spec = <<rp>>;
	Frames::temporarily_set_kvs(saved);
	kind *K = Specifications::to_kind(spec);
	return K;
}

@h I7 expression evaluation.
This is not quite like regular expression evaluation, because we want
"room" and "lighted" to be evaluated as the I6 translation of the
relevant class or property, rather than as code to test the predicate
"X is a room" or "X is lighted", and similarly for bare names
of defined adjectives. So:

=
void Invocations::Inline::compile_I7_expression_from_text(value_holster *VH, text_stream *OUT, text_stream *p) {
	if ((VH) && (VH->vhmode_wanted == INTER_VOID_VHMODE)) {
		Produce::evaluation(Emit::tree());
		Produce::down(Emit::tree());
	}

	Invocations::Inline::compile_I7_expression_from_text_inner(VH, OUT, p);

	if ((VH) && (VH->vhmode_wanted == INTER_VOID_VHMODE)) {
		Produce::up(Emit::tree());
	}
}

void Invocations::Inline::compile_I7_expression_from_text_inner(value_holster *VH, text_stream *OUT, text_stream *p) {
	wording LW = Feeds::feed_text(p);

	if (<property-name>(LW)) {
		if (VH)
			Produce::val_iname(Emit::tree(), K_value, Properties::iname(<<rp>>));
		else
			WRITE_TO(OUT, "%n", Properties::iname(<<rp>>));
		return;
	}

	if (<k-kind>(LW)) {
		kind *K = <<rp>>;
		if (Kinds::Compare::lt(K, K_object)) {
			if (VH)
				Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(K));
			else
				WRITE_TO(OUT, "%n", Kinds::RunTime::I6_classname(K));
			return;
		}
	}

	instance *I = Instances::parse_object(LW);
	if (I) {
		if (VH)
			Produce::val_iname(Emit::tree(), K_value, Instances::iname(<<rp>>));
		else
			WRITE_TO(OUT, "%~I", I);
		return;
	}

	adjective *aph = Adjectives::parse(LW);
	if (aph) {
		if (Adjectives::Meanings::write_adjective_test_routine(VH, aph)) return;
		StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"You tried to use '(+' and '+)' to expand to the Inform 6 routine "
			"address of an adjective, but it was an adjective with no meaning.");
		return;
	}

	#ifdef IF_MODULE
	int initial_problem_count = problem_count;
	#endif
	parse_node *spec = NULL;
	if (<s-value>(LW)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(LW);
	#ifndef IF_MODULE
	Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	#endif
	#ifdef IF_MODULE
	if (initial_problem_count < problem_count) return;
	Dash::check_value(spec, NULL);
	if (initial_problem_count < problem_count) return;
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	if (VH)
		Specifications::Compiler::emit_as_val(K_value, spec);
	else {
		nonlocal_variable *nlv = NonlocalVariables::parse(LW);
		if (nlv) {
			PUT(URL_SYMBOL_CHAR);
			Inter::SymbolsTables::symbol_to_url_name(OUT, InterNames::to_symbol(NonlocalVariables::iname(nlv)));
			PUT(URL_SYMBOL_CHAR);
		} else {
			value_holster VH2 = Holsters::new(INTER_DATA_VHMODE);
			Specifications::Compiler::compile_inner(&VH2, spec);
			inter_ti v1 = 0, v2 = 0;
			Holsters::unholster_pair(&VH2, &v1, &v2);
			if (v1 == ALIAS_IVAL) {
				PUT(URL_SYMBOL_CHAR);
				inter_symbols_table *T = Inter::Packages::scope(Emit::current_enclosure()->actual_package);
				inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, v2);
				Inter::SymbolsTables::symbol_to_url_name(OUT, S);
				PUT(URL_SYMBOL_CHAR);
			} else {
				CodeGen::FC::val_from(OUT, Packaging::at(Emit::tree()), v1, v2);
			}
		}
	}
	END_COMPILATION_MODE;
	#endif
}
