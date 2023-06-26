[CSIInline::] Compile Invocations Inline.

Here we generate Inter code to invoke a phrase from its inline definition.

@h Introduction.
In "CSI: Inline", which premieres Thursday at 9, Jack "The Invoker" Flathead,
lonely but brilliant scene of crime officer, tells it like it is, and as serial
killers stalk the troubled streets of Inline, Missouri, ... Well, no: CSI
stands here for "compile single invocation", and this is the harder case where
the phrase being invoked has an inline definition.

Inline definitions vary considerably in both simplicity and their legibility
to human eyes. Here is the text substitution "[bold type]":
= (text)
To say bold type -- running on:
	(- style bold; -).
=
On the other hand, here is how to repeat through a table:
= (text)
To repeat through (T - table name) in (TC - table column) order begin -- end loop
	(-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableNextRow({-my:1}, {TC}, 0, 1), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}~=0:
			{-my:2}=TableNextRow({-my:1}, {TC}, {-my:2}, 1), ct_0={-my:1}, ct_1={-my:2})
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
=
Inline definitions are written in a highly annotated and marked-up version of
Inform 6 notation, but are not actually I6 code.

That second example is a case where the definition has a "back" as well as a
"front". All definitions have a front; only if the text contains a |{-block}|
marker is there a back as well. The front is the material up to the marker, the
back is the material after it. The idea, of course, is that for inline
definitions of control structures involving blocks of code, we compile the
front material before compiling the block, and the back material afterwards.

@ The process of compiling from an inline definition is a little like
interpreting a program, and a //csi_state// object represents the state of
the (imaginary) computer doing that.

=
typedef struct csi_state {
	struct source_location *where_from;
	struct value_holster VH;
	struct id_body *idb;
	struct parse_node *inv;
	struct tokens_packet *tokens;
	struct local_variable *my_vars[10]; /* the "my" variables 0 to 9 */
} csi_state;

@h Front and back.
The function //CSIInline::csi_inline// compiles from the front of the definition, but not
the back (if it has one). The back won't appear until much later on, when the
new code block finishes. We won't live to see it; in this function, all we do
is pass the tailpiece to the code block handler, to be spliced in later on.

Note that if there is a code block, then any "my" variables created in this
invocation are preserved -- the back part of the definition may want to use
them. They will disappear anyway in that event, because their scope is set to
the code block in question.

=
int CSIInline::csi_inline(value_holster *VH, parse_node *inv, source_location *where_from,
	tokens_packet *tokens) {
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;
	csi_state CSIS;
	id_body *idb = Node::get_phrase_invoked(inv);
	@<Initialise the CSI state@>;
	@<Create any new local variables explicitly called for@>;
	CSIInline::from_schema(idb->head_of_defn->at,
		CompileImperativeDefn::get_front_schema(idb), &CSIS);
	if (IDTypeData::block_follows(idb)) {
		if (CodeBlocks::attach_back_schema(
			CompileImperativeDefn::get_back_schema(idb), CSIS) == FALSE) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_LoopWithoutBody),
				"there doesn't seem to be any body to this phrase",
				"in the way that a 'repeat', 'if' or 'while' is expected to have.");
		}
	} else {
		@<Release any my-variables created inline@>;
	}
	return idb->compilation_data.inline_mor;
}

@ The 10 variable registers hold the identities of local variables created inside
the inline definition using |{-my:0}| to |{-my:9}|: they're |NULL| until used, and
are mostly not used. The "repeat" example above uses |{-my:1}|, |{-my:2}|, and
|{-my:3}|, but leaves the others null. Most definitions use none of them.

@<Initialise the CSI state@> =
	CSIS.where_from = where_from;
	CSIS.VH = *VH; /* copied because it might be on the C call stack */
	CSIS.idb = idb;
	CSIS.inv = inv;
	CSIS.tokens = tokens;
	for (int i=0; i<10; i++) CSIS.my_vars[i] = NULL;

@ But phrases can create local variables through notation in the prototype as
well as in the definition. Consider the prototype:
= (text)
To repeat with (loopvar - nonexisting object variable)
	running through (L - list of values) begin -- end loop:
	...
=
Here, token 0, "nonexisting object variable", calls for us to create a new
local variable of kind "object" each time the phrase is invoked. This variable
may have a short lifetime, since its scope will be tied to the block of code
about to open.

Note that we do not initialise the variable -- that would be inefficient, in that
such stores would be unnecessary in some cases. So the responsibility of ensuring
that the variable contains a typesafe value is placed on the inline definition.
If it abuses that responsibility, type safety is simply lost. Consider:
= (text)
To conjure (bus - nonexisting object variable):
	(- {bus} = 26201; -).
When play begins:
	conjure the magic bus;
	showme the magic bus.
=
This will end horribly unless 26201 happens to be a valid object number, and it
almost certainly is not. But the Inform compiler throws no problem message, because
the code is legal. See the discussion of |{-initialise:...}| for how to deal with
this issue.

@<Create any new local variables explicitly called for@> =
	for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
		parse_node *val = tokens->token_vals[i];
		kind *K = Invocations::get_token_variable_kind(inv, i);
		if (K) {
			local_variable *lvar = LocalVariables::new_let_value(Node::get_text(val), K);
			if (IDTypeData::block_follows(idb) == LOOP_BODY_BLOCK_FOLLOWS)
				CodeBlocks::set_scope_to_block_about_to_open(lvar);
			else
				CodeBlocks::set_scope_to_current_block(lvar);
			tokens->token_vals[i] =
				Lvalues::new_LOCAL_VARIABLE(Node::get_text(val), lvar);
			if (Kinds::Behaviour::uses_block_values(K)) {
				inter_symbol *lvar_s = LocalVariables::declare(lvar);
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, lvar_s);
					Frames::emit_new_local_value(K);
				EmitCode::up();
			}
		}
	}

@ As we will see (in the discussion of |{-my:...}| below), any variables made
as scratch values for the invocation are deallocated as soon as we're finished,
unless a code block is opened: if it is, then they're deallocated when it ends.

@<Release any my-variables created inline@> =
	for (int i=0; i<10; i++)
		if (CSIS.my_vars[i])
			LocalVariableSlates::deallocate_I7_local(CSIS.my_vars[i]);

@ And this is what happens when the back part of the definition is finally
compiled.

=
void CSIInline::csi_inline_back(inter_schema *back, csi_state *CSIS) {
	if (back) CSIInline::from_schema(current_sentence, back, CSIS);
}

@h Single schemas.
We can now forget about fronts and backs, and work on expanding a single
inline definition into a single stream.

We do this by calling the very powerful |EmitInterSchemas::emit| function,
which parses the schema and calls us back to do something at each point in it.
In particular, it calls //CSIInline::from_schema_token// on each "token" of
the schema, and calls //CSIInline::from_source_text// on any material enclosed
in |(+ ... +)| notation.

|CSIS| is passed to this function as our "opaque state" -- meaning that it is
passed through unchanged to our callback functions, and means that the code
below can share some private state variables.

=
void CSIInline::from_schema(parse_node *from, inter_schema *sch, csi_state *CSIS) {
	if (LinkedLists::len(sch->parsing_errors) == 0) {
		EmitInterSchemas::emit(Emit::tree(), &(CSIS->VH), sch,
			IdentifierFinders::common_names_only(),
			&CSIInline::from_schema_token, &CSIInline::from_source_text, CSIS);
		CompileImperativeDefn::issue_schema_errors(from, sch, NULL);
	}
}

@ So we now have to write the function compiling code to implement |ist|.
See //building: Inter Schemas// for a specification of Inter schema tokens,
but roughly speaking each is either a command or a "bracing".

=
void CSIInline::from_schema_token(value_holster *VH,
	inter_schema_token *ist, void *CSIS_s, int prim_cat, text_stream *arg_L) {
	csi_state *CSIS = (csi_state *) CSIS_s; /* recover the "opaque state" */

	id_body *idb = CSIS->idb;
	parse_node *inv = CSIS->inv;
	tokens_packet *tokens = CSIS->tokens;
	local_variable **my_vars = CSIS->my_vars;

	int C = ist->inline_command;
	if (C != no_ISINC) {
		if (C == primitive_definition_ISINC) @<Expand an entirely internal-made definition@>;
		@<Expand a bracing containing a kind command@>;
		@<Expand a bracing containing a typographic command@>;
		@<Expand a bracing containing a label or counter command@>;
		@<Expand a bracing containing a high-level command@>;
		@<Expand a bracing containing a miscellaneous command@>;
	}

	wording BRW = Feeds::feed_text(ist->bracing);
	@<Expand a bracing for a token or phrase option@>;
}

@h Bracings for tokens.
For example, if the phrase prototype is |print (something to say - text)|, then the
bracing |{something to say}| refers to the token value at that point.

Such tokens can also be "annotated" with commands. |{-by-reference:something to say}|
means the same but indicates that it should be compiled without copying.

Lastly, though this is much less common, the bracing can compile to the bitmap value
for a phrase option or for the current bitmap of options specified by the invocation.
Those have no annotations.

The natural language part must match this:

@d OPTS_INSUB -1
@d LOCAL_INSUB -2

=
<inline-bracing-source-text> ::=
	phrase options |                      ==> { OPTS_INSUB, - }
	<phrase-option>	|                     ==> { R[1], - }
	<name-local-to-inline-stack-frame> |  ==> { LOCAL_INSUB, RP[1] }
	...                                   ==> @<Issue PM_BadInlineExpansion problem@>

@ This matches one of the token names in the preamble to the inline definition.

=
<name-local-to-inline-stack-frame> internal {
	local_variable *lvar =
		LocalVariables::parse(&(idb_being_parsed->compilation_data.id_stack_frame), W);
	if (lvar) {
		==> { -, lvar };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ In my first draft of Inform, this problem message made reference to "meddling
charlatans" and what they "deserve". I'm a better person now.

@<Issue PM_BadInlineExpansion problem@> =
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
	==> { fail nonterminal };

@ Acting on that:

@<Expand a bracing for a token or phrase option@> =
	phod_being_parsed = &(idb->type_data.options_data);
	idb_being_parsed = idb;
	if (<inline-bracing-source-text>(BRW)) {
		switch (<<r>>) {
			case OPTS_INSUB: {
				int current_opts = Invocations::get_phrase_options_bitmap(inv);
				EmitCode::val_number((inter_ti) current_opts);
				break;
			}
			case LOCAL_INSUB: {
				local_variable *lvar = <<rp>>;
				int tok = LocalVariables::get_parameter_number(lvar);
				if (tok >= 0) @<Expand a bracing containing a token name@>;
				break;
			}
			default: {
				int this_opt = -<<r>>;
				int current_opts = Invocations::get_phrase_options_bitmap(inv);
				if (current_opts & this_opt)
					EmitCode::val_number(1);
				else
					EmitCode::val_number(0);
				break;
			}
		}
	}

@ At this point, the bracing text is the name of token number |tok|. Usually
we compile the value of that argument as drawn from the tokens packet, but
the presence of annotations can change what we do.

@<Expand a bracing containing a token name@> =
	parse_node *supplied = tokens->token_vals[tok];

	int by_value_not_reference = TRUE;
	int require_to_be_lvalue = FALSE;

	@<Take account of any annotation to the inline token@>;
	kind *kind_vars_inline[27];
	@<Work out values for the kind variables in this context@>;
	kind **saved = Frames::temporarily_set_kvs(kind_vars_inline);
	int changed = FALSE;
	kind *kind_required =
		Kinds::substitute(IDTypeData::token_kind(&(idb->type_data), tok),
			kind_vars_inline, &changed, FALSE);
	@<If the token has to be an lvalue, reject it if it isn't@>;
	@<Compile the token value@>;
	Frames::temporarily_set_kvs(saved);

@<Work out values for the kind variables in this context@> =
	kind_vars_inline[0] = NULL;
	for (int i=1; i<=26; i++) kind_vars_inline[i] = Frames::get_kind_variable(i);
	kind_variable_declaration *kvd = Node::get_kind_variable_declarations(inv);
	for (; kvd; kvd=kvd->next) kind_vars_inline[kvd->kv_number] = kvd->kv_value;

@<If the token has to be an lvalue, reject it if it isn't@> =
	if (require_to_be_lvalue) {
		nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(supplied);
		if (((nlv) && (NonlocalVariables::is_constant(nlv))) ||
			(Lvalues::is_lvalue(supplied) == FALSE)) {
			Problems::quote_source(1, current_sentence);
			if (nlv) Problems::quote_wording(2, nlv->name);
			else Problems::quote_spec(2, supplied);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NotAnLvalue));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to mean changing '%2', which is a constant "
				"and can't be altered.");
			Problems::issue_problem_end();
		}
	}

@<Compile the token value@> =
	LOGIF(MATCHING, "Expanding $P into '%W' with %d, %u%s%s\n",
		supplied, BRW, tok, kind_required,
		changed?" (after kind substitution)":"",
		by_value_not_reference?" (by value)":" (by reference)");
	if (by_value_not_reference) {
		CompileValues::to_fresh_code_val_of_kind(supplied, kind_required);
	} else {
		CompileValues::to_code_val_of_kind(supplied, kind_required);
	}

@h Annotation commands for bracings with natural language.
These all modify the way a token is compiled.

@<Take account of any annotation to the inline token@> =
	int valid_annotation = FALSE;
	int C = ist->inline_command;
	if (C == by_reference_ISINC)           @<Inline annotation "by-reference"@>;
	if (C == by_reference_blank_out_ISINC) @<Inline annotation "by-reference-blank-out"@>;
	if (C == reference_exists_ISINC)       @<Inline annotation "reference-exists"@>;
	if (C == lvalue_by_reference_ISINC)    @<Inline annotation "lvalue-by-reference"@>;
	if (C == by_value_ISINC)               @<Inline annotation "by-value"@>;

	if (C == box_quotation_text_ISINC)     @<Inline annotation "box-quotation-text"@>;

	#ifdef IF_MODULE
	if (C == try_action_ISINC)             @<Inline annotation "try-action"@>;
	if (C == try_action_silently_ISINC)    @<Inline annotation "try-action-silently"@>;
	#endif

	if (C == return_value_ISINC)           @<Inline annotation "return-value"@>;
	if (C == return_value_from_rule_ISINC) @<Inline annotation "return-value-from-rule"@>;

	if (C == property_holds_block_value_ISINC) @<Inline annotation "property-holds-block-value"@>;
	if (C == mark_event_used_ISINC)        @<Inline annotation "mark-event-used"@>;

	if ((C != no_ISINC) && (valid_annotation == FALSE))
		@<Throw a problem message for an invalid inline annotation@>;

@ This affects only block values. When it's used, the token accepts the pointer
to the block value directly, that is, not copying the data over to a fresh
copy and using that instead. This means a definition like:
= (text as Inform 7)
To zap (L - a list of numbers):
	(- Zap({-by-reference:L}, 10); -).
=
will call |Zap| on the actual list supplied to it. If |Zap| chooses to change
this list, the original will change.

@<Inline annotation "by-reference"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;

@ And, variedly:

@<Inline annotation "by-reference-blank-out"@> =
	CompileLvalues::compile_table_reference(VH, supplied, FALSE, TRUE, 0);
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@ And, variedly:

@<Inline annotation "reference-exists"@> =
	CompileLvalues::compile_table_reference(VH, supplied, TRUE, FALSE, 0);
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@ This is a variant which checks that the reference is to an lvalue, that is,
to something which can be changed. If this weren't done, then
|remove 2 from {1, 2, 3}| would compile without problem messages, though it
would behave pretty oddly at run-time.

@<Inline annotation "lvalue-by-reference"@> =
	by_value_not_reference = FALSE;
	valid_annotation = TRUE;
	require_to_be_lvalue = TRUE;

@ This is the default, so it's redundant, but clarifies definitions.

@<Inline annotation "by-value"@> =
	by_value_not_reference = TRUE;
	valid_annotation = TRUE;

@ This is used only for compiling down to the |box| statement in I6, which has
slightly different textual requirements than regular text. We could get rid of
this by making a kind for box-quotation-text, and casting regular text to it,
but honestly having this annotation seems the smaller of the two warts.

@<Inline annotation "box-quotation-text"@> =
	if (Rvalues::is_CONSTANT_of_kind(supplied, K_text) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_spec(2, supplied);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Misboxed));
		Problems::issue_problem_segment(
			"I attempted to compile %1, but the text '%2' supplied to be a boxed "
			"quotation wasn't a constant piece of text in double-quotes. I'm afraid "
			"that's the only sort of text allowed here.");
		Problems::issue_problem_end();
		return;
	} else {
		value_holster VH = Holsters::new(INTER_VAL_VHMODE);
		BoxQuotations::new(&VH, Node::get_text(supplied));
		Holsters::unholster_to_code_val(Emit::tree(), &VH);
		return; /* that is, don't use the regular token compiler: we've done it ourselves */
	}

@ Suppose we are invoking "decide on 102" from the Basic Inform inline definition
of "decide on ...", which is:
= (text)
	(- return {-return-value:something}; -)
=
We clearly need to police this: if the phrase is deciding a number, we need to
object to |decide on "fish fingers"|.

That's one purpose of this annotation: it checks the value to see if it's suitable
to be returned. But we also might have to cast the value, or check that it's valid
at run-time. For instance, in a phrase to decide a container, given |decide on the item|
we may need to check "item" at run-time: at compile-time we know it's an object,
but not necessarily that it's a container.

@<Inline annotation "return-value"@> =
	int returning_from_rule = FALSE;
	@<Handle an inline return@>;

@ Exactly the same mechanism is needed for rules which produce a value, but the
problem messages are phrased differently if something goes wrong.

@<Inline annotation "return-value-from-rule"@> =
	int returning_from_rule = TRUE;
	@<Handle an inline return@>;

@ So here's the common code:

@<Handle an inline return@> =
	kind *kind_needed;
	if (returning_from_rule) kind_needed = Rulebooks::kind_from_context();
	else kind_needed = Frames::get_kind_returned();
	kind *kind_supplied = Specifications::to_kind(supplied);
	id_body *current_idb = Functions::defn_being_compiled();
	int mor = IDTypeData::get_mor(&(current_idb->type_data));

	int allow_me = ALWAYS_MATCH;
	if ((kind_needed) && (Kinds::eq(kind_needed, K_nil) == FALSE) &&
		(Kinds::eq(kind_needed, K_void) == FALSE))
		allow_me = Kinds::compatible(kind_supplied, kind_needed);
	else if ((mor == DECIDES_CONDITION_MOR) && (Kinds::eq(kind_supplied, K_truth_state)))
		allow_me = ALWAYS_MATCH;
	else @<Issue a problem for returning a value when none was asked@>;

	if (allow_me == ALWAYS_MATCH) {
		CompileValues::to_fresh_code_val_of_kind(supplied, kind_needed);
	} else if ((allow_me == SOMETIMES_MATCH) && (Kinds::Behaviour::is_object(kind_needed))) {
		EmitCode::call(Hierarchy::find(CHECKKINDRETURNED_HL));
		EmitCode::down();
			CompileValues::to_fresh_code_val_of_kind(supplied, kind_needed);
			EmitCode::val_iname(K_value, RTKindDeclarations::iname(kind_needed));
		EmitCode::up();
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
		explicit_action *ea = Node::get_constant_explicit_action(supplied);
		CSIInline::compile_try_action(ea, FALSE);
	} else {
		EmitCode::call(Hierarchy::find(STORED_ACTION_TY_TRY_HL));
		EmitCode::down();
			CompileValues::to_code_val_of_kind(supplied, K_stored_action);
		EmitCode::up();
	}
	valid_annotation = TRUE;
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@<Inline annotation "try-action-silently"@> =
	if (Rvalues::is_CONSTANT_of_kind(supplied, K_stored_action)) {
		explicit_action *ea = Node::get_constant_explicit_action(supplied);
		CSIInline::compile_try_action(ea, TRUE);
	} else {
		EmitCode::call(Hierarchy::find(STORED_ACTION_TY_TRY_HL));
		EmitCode::down();
			CompileValues::to_code_val_of_kind(supplied, K_stored_action);
			EmitCode::val_true();
		EmitCode::up();
	}
	valid_annotation = TRUE;
	return; /* that is, don't use the regular token compiler: we've done it ourselves */

@ Suppose we have a token which is a property name, and we want to know about the
kind of value the property holds. We can't simply take the kind of the token, because
that would be "property name". Instead:

@<Inline annotation "property-holds-block-value"@> =
	property *prn = Rvalues::to_property(supplied);
	if ((prn == NULL) || (Properties::is_either_or(prn))) {
		EmitCode::val_false();
	} else {
		kind *K = ValueProperties::kind(prn);
		if (Kinds::Behaviour::uses_block_values(K)) {
			EmitCode::val_true();
		} else {
			EmitCode::val_false();
		}
	}
	return;

@ This little annotation is used in //if: Timed Rules//.

@<Inline annotation "mark-event-used"@> =
	PluginCalls::nonstandard_inline_annotation(ist->inline_command, supplied);
	valid_annotation = TRUE;

@<Throw a problem message for an invalid inline annotation@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_stream(2, ist->command);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadInlineTag));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, but this contained the "
		"invalid annotation '%2'.");
	Problems::issue_problem_end();
	return;

@h Try and try silently.

=
void CSIInline::compile_try_action(explicit_action *ea, int silently) {
	if (silently) {
		EmitCode::inv(PUSH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(KEEP_SILENT_HL));
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(KEEP_SILENT_HL));
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::inv(PUSH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SAY__P_HL));
		EmitCode::up();
		EmitCode::inv(PUSH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SAY__PC_HL));
		EmitCode::up();
		EmitCode::call(Hierarchy::find(CLEARPARAGRAPHING_HL));
		EmitCode::down();
			EmitCode::val_true();
		EmitCode::up();
	}
	CompileRvalues::compile_explicit_action(ea, FALSE);
	if (silently) {
		EmitCode::call(Hierarchy::find(DIVIDEPARAGRAPHPOINT_HL));
		EmitCode::inv(PULL_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(SAY__PC_HL));
		EmitCode::up();
		EmitCode::inv(PULL_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(SAY__P_HL));
		EmitCode::up();
		EmitCode::call(Hierarchy::find(ADJUSTPARAGRAPHPOINT_HL));
		EmitCode::inv(PULL_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(KEEP_SILENT_HL));
		EmitCode::up();
	}
}

@h Commands about kinds.
And that's it for the general machinery, but in another sense we're only just
getting started. We now go through all of the special syntaxes which make
invocation-language so baroque.

We'll start with a suite of details about kinds:
= (text)
	{-command:kind name}
=

@<Expand a bracing containing a kind command@> =
	Problems::quote_stream(4, ist->operand);
	if (C == new_ISINC)              @<Inline command "new"@>;
	if (C == new_list_of_ISINC)      @<Inline command "new-list-of"@>;
	if (C == printing_routine_ISINC) @<Inline command "printing-routine"@>;
	if (C == ranger_routine_ISINC)   @<Inline command "ranger-routine"@>;
	if (C == indexing_routine_ISINC) @<Inline command "indexing-routine"@>;
	if (C == next_routine_ISINC)     @<Inline command "next-routine"@>;
	if (C == previous_routine_ISINC) @<Inline command "previous-routine"@>;
	if (C == strong_kind_ISINC)      @<Inline command "strong-kind"@>;
	if (C == weak_kind_ISINC)        @<Inline command "weak-kind"@>;

@ The following produces a new value of the given kind. If it's stored as a
word value, this will just be the default value, so |{-new:time}| will output
540, that being the Inform 6 representation of 9:00 AM. If it's a block value,
we compile code which creates a new value stored on the heap. This comes into
its own when kind variables are in play.

@<Inline command "new"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (Kinds::Behaviour::uses_block_values(K)) Frames::emit_new_local_value(K);
	else if (K == NULL) @<Issue an inline no-such-kind problem@>
	else if (DefaultValues::val(K, EMPTY_WORDING, NULL) == FALSE)
		@<Issue problem for no natural choice@>;
	return;

@<Issue problem for no natural choice@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoNaturalDefault2));
	Problems::issue_problem_segment(
		"To achieve %1, we'd need to be able to store a default value of the kind '%2', "
		"but there's no natural choice for this.");
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
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	CompilePropositions::to_list_of_matches(tokens->token_vals[0], K);
	return;

@<Inline command "next-routine"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) EmitCode::val_iname(K_value, RTKindConstructors::increment_fn_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "previous-routine"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) EmitCode::val_iname(K_value, RTKindConstructors::decrement_fn_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "printing-routine"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) EmitCode::val_iname(K_value, RTKindConstructors::printing_fn_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "ranger-routine"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if ((Kinds::eq(K, K_number)) ||
		(Kinds::eq(K, K_time)))
		EmitCode::val_iname(K_value, Hierarchy::find(GENERATERANDOMNUMBER_HL));
	else if (K) EmitCode::val_iname(K_value, RTKindConstructors::random_value_fn_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "indexing-routine"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) EmitCode::val_iname(K_value, RTKindConstructors::indexing_fn_iname(K));
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "strong-kind"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) RTKindIDs::emit_strong_ID_as_val(K);
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline command "weak-kind"@> =
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand,
		Node::get_kind_variable_declarations(inv));
	if (K) RTKindIDs::emit_weak_ID_as_val(K);
	else @<Issue an inline no-such-kind problem@>;
	return;

@<Issue an inline no-such-kind problem@> =
	StandardProblems::inline_problem(_p_(PM_InlineNew), idb,
		ist->owner->parent_schema->converted_from,
		"I don't know any kind called '%4'.");

@h Typographic commands.
These rather clumsy commands are a residue from earlier forms of the markup
language, really. |{-open-brace}| and |{-close-brace}| are handled for us
elsewhere, so we need do nothing. The other two have actually been withdrawn.

@<Expand a bracing containing a typographic command@> =
	if (C == backspace_ISINC)   @<Inline command "backspace"@>;
	if (C == erase_ISINC)       @<Inline command "erase"@>;
	if (C == open_brace_ISINC)  return;
	if (C == close_brace_ISINC) return;

@<Inline command "backspace"@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BackspaceWithdrawn));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, but this contained the "
		"invalid annotation '{backspace}', which has been withdrawn. (Inline annotations "
		"are no longer allowed to amend the compilation stream to their left.)");
	Problems::issue_problem_end();
	return;

@<Inline command "erase"@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EraseWithdrawn));
	Problems::issue_problem_segment(
		"I attempted to compile %1 using its inline definition, but this contained the "
		"invalid annotation '{erase}', which has been withdrawn. (Inline annotations "
		"are no longer allowed to blank out the compilation stream.)");
	Problems::issue_problem_end();
	return;

@h Label or counter commands.
Here we want to generate unique numbers, or uniquely named labels, on demand.

@<Expand a bracing containing a label or counter command@> =
	if (C == label_ISINC)               @<Inline command "label"@>;
	if (C == counter_ISINC)             @<Inline command "counter"@>;
	if (C == counter_storage_ISINC)     @<Inline command "counter-storage"@>;
	if (C == counter_up_ISINC)          @<Inline command "counter-up"@>;
	if (C == counter_down_ISINC)        @<Inline command "counter-down"@>;
	if (C == counter_makes_array_ISINC) @<Inline command "counter-makes-array"@>;

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
	if (arg_L != NULL) {
		JumpLabels::write(arg_L, ist->operand);
	} else {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".");
		JumpLabels::write(L, ist->operand);
		EmitCode::lab(EmitCode::reserve_label(L));
		DISCARD_TEXT(L)
	}
	return;

@ We can also output just the numerical counter:

@<Inline command "counter"@> =
	EmitCode::val_number((inter_ti) JumpLabels::read_counter(ist->operand, 0));
	return;

@ We can also output just the storage array:

@<Inline command "counter-storage"@> =
	EmitCode::val_iname(K_value, JumpLabels::storage_iname(ist->operand));
	return;

@ Or increment it, printing nothing:

@<Inline command "counter-up"@> =
	JumpLabels::read_counter(ist->operand, 1);
	return;

@ Or decrement it. (Careful, though: if it decrements below zero, an enigmatic
internal error will halt Inform.)

@<Inline command "counter-down"@> =
	JumpLabels::read_counter(ist->operand, 0);
	return;

@ We can use counters for anything, not just to generate labels, and one
useful trick is to allocate storage at run-time. Invoking
= (text)
	{-counter-makes-array:pineapple}
=
at any time during compilation (once or many times over, it makes no
difference) causes Inform to generate an array called |I7_ST_pineapple|
guaranteed to contain one entry for each counter value reached. Thus:
= (text as Inform 7)
To remember (N - a number) for later: ...
=
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
	if (Str::len(ist->operand2) > 0) words_per_count = Str::atoi(ist->operand2, 0);
	JumpLabels::allocate_storage(ist->operand, words_per_count);
	return;

@h High-level commands.
This category is intended for powerful and flexible commands, allowing for
invocations which behave like control statements in other languages. (See
also |{-block}| above, though that is syntactically a divider rather than
a command, which is why it isn't here.)

@<Expand a bracing containing a high-level command@> =
	if (C == my_ISINC)                      @<Inline command "my"@>;
	if (C == unprotect_ISINC)               @<Inline command "unprotect"@>;
	if (C == copy_ISINC)                    @<Inline command "copy"@>;
	if (C == initialise_ISINC)              @<Inline command "initialise"@>;
	if (C == matches_description_ISINC)     @<Inline command "matches-description"@>;
	if (C == now_matches_description_ISINC) @<Inline command "now-matches-description"@>;
	if (C == arithmetic_operation_ISINC)    @<Inline command "arithmetic-operation"@>;
	if (C == say_ISINC)                     @<Inline command "say"@>;
	if (C == show_me_ISINC)                 @<Inline command "show-me"@>;

@ The |{-my:name}| command creates a local variable for use in the invocation,
and then prints the variable's name. (If the same variable is created twice,
the second time it's simply printed.)

@<Inline command "my"@> =
	local_variable *lvar = NULL;
	int n = Str::get_at(ist->operand, 0) - '0';
	if ((Str::get_at(ist->operand, 1) == 0) && (n >= 0) && (n < 10))
		@<A single digit as the name@>
	else
		@<An Inter identifier as the name@>;
	inter_symbol *lvar_s = LocalVariables::declare(lvar);
	if (prim_cat == REF_PRIM_CAT) EmitCode::ref_symbol(K_value, lvar_s);
	else EmitCode::val_symbol(K_value, lvar_s);
	return;

@ In the first form, we don't give an explicit name, but simply a digit from
0 to 9. We're therefore allowed to create up to 10 variables this way, and
the ones we create will be different from those made by any other invocation
(including other invocations of the same phrase). See above.

@<A single digit as the name@> =
	lvar = my_vars[n];
	if (lvar == NULL) {
		my_vars[n] = LocalVariables::new_let_value(EMPTY_WORDING, K_number);
		lvar = my_vars[n];
		@<Set the kind of the new variable@>;
		if (IDTypeData::block_follows(idb))
			CodeBlocks::set_scope_to_block_about_to_open(lvar);
	}

@ The second form is simpler. |{-my:1}| and such make locals with names like
|tmp_3|, which we have no control over. Here we get to make a local with
exactly the name we want. This can't be reallocated, of course; it's there
throughout the routine, so there's no question of setting its scope. For example:
= (text as Inform 7)
To be warned:
	(- {-my:warn} = true; -).
To decide if we have been warned:
	(- ({-my:warn}) -).
=
The net result here is that if either phrase is used, then |warn| becomes a
local variable. The second phrase tests if the first has been used.

Nothing, of course, stops some other invocation from using a variable of
the same name for some quite different purpose, wreaking havoc. This is
why the numbered scheme above is mostly better.

@<An Inter identifier as the name@> =
	lvar = LocalVariables::new_internal(ist->operand);
	@<Set the kind of the new variable@>;

@ Finally, it's possible to set the I7 kind of a variable created by |{-my:...}|,
though there are hardly any circumstances where this is necessary, since Inter
is typeless. But in a few cases where I7 is embedded inside Inter inside I7,
or when a block value is needed, or where we need to match against descriptions
(see below) where kind-checking comes into play, it could arise. For example:
= (text)
	{-my:1:list of numbers}
=

@<Set the kind of the new variable@> =
	kind *K = NULL;
	if (Str::len(ist->operand2) > 0)
		K = CSIInline::parse_bracing_operand_as_kind(ist->operand2,
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
		CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb, tokens, my_vars);
	local_variable *lvar = Lvalues::get_local_variable_if_any(v);

	if (lvar) LocalVariables::unprotect(lvar);
	else @<Issue a no-such-local problem message@>;
	return;

@ Something to be careful of is that a variable created with |{-my:...}|,
or indeed a variable created explicitly by the phrase, may not begin with
contents which are typesafe for the kind you intend it to hold. Usually this
doesn't matter because it is immediately written with some value which is
indeed typesafe, and there's no problem. But if not, |{-initialise:var:kind}|
takes the named local variable and gives it the default value for that kind.
If the kind is omitted, the default is to use the kind of the variable. For example,
= (text)
	{-my:1:time}{-initialise:1}
=
Note that this works only for kinds of word value, like "time". For kinds
of block value, like "list of numbers", it does nothing. This may seem odd,
but the point is that locals of that kind are automatically set to their
default values when created, so they are always typesafe anyway.

Note also that the Dash typechecker allows the creation of local variables
whose kinds are subkinds of objects which may have no instances. For example,
in this program:
= (text)
	A cat is a kind of animal.
	To discuss the felines:
		let C be a cat;
		...
=
...it is legal to construct the variable |C| with kind |cat|, even though there
are no cats in the world, so that a call to |DefaultValues::val| would
generate a problem message. But we call |DefaultValues::val_allowing_nothing|
instead, so that |C| is created but with the value |nothing|.

This would be easier to understand if Inform's kinds system supported "optionals".
In the Swift language, for example, there would be a clear distinction between
the types |Cat| (runtime values must be instances of cat) and |Cat?| (runtime
values must be instances of cat or else |nothing|). In Inform, cat-valued global
variables and properties have the type |Cat|, but cat-valued locals have the
type |Cat?|. We do this to make it more convenient to write functions about
cats which will compile whether or not any cats exist; an extension might provide
such functions, for example, providing functionality which is only used if cats
do exist, but which should still compile without errors even if they do not.

@<Inline command "initialise"@> =
	parse_node *V = CSIInline::parse_bracing_operand_as_identifier(ist->operand,
		idb, tokens, my_vars);
	local_variable *lvar = Lvalues::get_local_variable_if_any(V);
	kind *K = NULL;
	if (Str::len(ist->operand2) > 0)
		K = CSIInline::parse_bracing_operand_as_kind(ist->operand2,
			Node::get_kind_variable_declarations(inv));
	else
		K = Specifications::to_kind(V);

	if (Kinds::Behaviour::uses_block_values(K)) {
		if (CodeBlocks::inside_a_loop_body()) {
			EmitCode::call(Hierarchy::find(BLKVALUECOPY_HL));
			EmitCode::down();
				inter_symbol *lvar_s = LocalVariables::declare(lvar);
				EmitCode::val_symbol(K_value, lvar_s);
				DefaultValues::val(K, Node::get_text(V), "value");
			EmitCode::up();
		}
	} else {
		int rv = FALSE;
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			inter_symbol *lvar_s = LocalVariables::declare(lvar);
			EmitCode::ref_symbol(K_value, lvar_s);
			rv = DefaultValues::val_allowing_nothing(K, Node::get_text(V), "value");
		EmitCode::up();
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

@ The |{-copy:...}| command allows us to copy the content in a token or variable
into any storage item (a local variable, a global, a table entry, a list entry),
regardless of its kind of value. For example:
= (text as Inform 7)
To let (t - nonexisting variable) be (u - value) (assignment operation):
	(- {-unprotect:t}{-copy:t:u} -).
=
This may look superfluous: for example, in response to "let X be 10" it generates
code equivalent to |tmp_0 = 10;|, which could have been achieved equally well with:
= (text)
	(- {-unprotect:t}{t} = {u}; -)
=
But it makes something much more elaborate in response to, say, "let Y be the
list of people in dark rooms", where it's important to keep track of the allocation
and deallocation of dynamic lists, since Y is a block value. The point of the
|{-copy:to:from}| command is to hide all that complexity from the definition.

@<Inline command "copy"@> =
	int copy_form = 0;
	parse_node *from = NULL, *to = NULL;
	@<Find what we are copying from, to and how@>;
	@<Check that we're not copying to something the user isn't allowed to change@>;

	pcalc_term pt1 = Terms::new_constant(to);
	pcalc_term pt2 = Terms::new_constant(from);
	kind *K1 = Specifications::to_kind(to);
	kind *K2 = Specifications::to_kind(from);
	node_type_t storage_class = Lvalues::get_storage_form(to);
	if (copy_form != 0) @<Check that increment or decrement make sense@>;
	char *prototype = CompileLvalues::interpret_store(storage_class, K1, K2, copy_form);
	i6_schema *sch = Calculus::Schemas::new("%s;", prototype);
	LOGIF(KIND_CHECKING, "Inline copy: %s\n", prototype);
	CompileSchemas::from_terms_in_val_context(sch, &pt1, &pt2);
	return;

@ If the |from| part is prefaced with a plus sign |+|, the new value is added
to the current value rather than replacing it; if |-|, it's subtracted. For
example,
= (text as Inform 7)
To increase (S - storage) by (w - value) (assignment operation):
	(- {-copy:S:+w} -).
=
Lastly, it's also legal to write just a |+| or |-| sign alone, which increments
or decrements. But be wary here, because |{-copy:S:+}| adds 1 to S, whereas
|{-copy:S:+1}| adds the value of the variable {-my:1} to S.

@<Find what we are copying from, to and how@> =
	TEMPORARY_TEXT(from_p)

	int c = Str::get_first_char(ist->operand2);
	if (c == '+') { copy_form = 1; Str::copy_tail(from_p, ist->operand2, 1); }
	else if (c == '-') { copy_form = -1; Str::copy_tail(from_p, ist->operand2, 1); }
	else Str::copy(from_p, ist->operand2);

	if ((Str::len(from_p) == 0) && (copy_form != 0))
		from = Rvalues::from_int(1, EMPTY_WORDING);
	else if (Str::len(from_p) > 0)
		from = CSIInline::parse_bracing_operand_as_identifier(from_p, idb, tokens, my_vars);

	to = CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb, tokens, my_vars);

	if ((to == NULL) || (from == NULL)) {
		Problems::quote_stream(4, ist->operand);
		Problems::quote_stream(5, ist->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineCopy), idb,
			ist->owner->parent_schema->converted_from,
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
			"To achieve %1, we'd need to be able to add or subtract 1 from a value of "
			"the kind '%2', but there's no good way to do this.");
		Problems::issue_problem_end();
		return;
	}

@ The next command generates code able to test if a token in the invocation,
or an Inter variable, matches a given description -- which need not be constant.
For example, if the phrase prototype includes the token |(OS - description of objects)|
then the bracing |{-matches-description:1:OS}| compiles a condition testing whether
the object in variable |{-my:1}| matches the description or not.

@<Inline command "matches-description"@> =
	parse_node *to_match =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand2, idb, tokens, my_vars);
	parse_node *to_test =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb, tokens, my_vars);
	if ((to_test == NULL) || (to_match == NULL)) {
		Problems::quote_stream(4, ist->operand);
		Problems::quote_stream(5, ist->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineMatchesDescription), idb,
			ist->owner->parent_schema->converted_from,
			"The command {-matches-description:...}, which asks to test whether "
			"'%5' is a valid description for '%4', has gone wrong: I couldn't "
			"work those out.");
	} else {
		CompilePropositions::to_test_if_matches(to_test, to_match);
	}
	return;

@ This is the same, except that it compiles code to assert that the given
variable matches the given description.

@<Inline command "now-matches-description"@> =
	parse_node *to_test =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb, tokens, my_vars);
	parse_node *to_match =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand2, idb, tokens, my_vars);
	if ((to_test == NULL) || (to_match == NULL)) {
		Problems::quote_stream(4, ist->operand);
		Problems::quote_stream(5, ist->operand2);
		StandardProblems::inline_problem(_p_(PM_InlineNowMatchesDescription),
			idb, ist->owner->parent_schema->converted_from,
			"The command {-now-matches-description:...}, which asks to change '%4' so "
			"that '%5' becomes a valid description of it, has gone wrong: I couldn't "
			"work those out.");
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(to_match);
		CompilePropositions::to_make_true_about(prop, to_test);
	}
	return;

@<Inline command "arithmetic-operation"@> =
	int op = IDTypeData::arithmetic_operation(idb);
	int binary = TRUE;
	if (Kinds::Dimensions::arithmetic_op_is_unary(op)) binary = FALSE;
	parse_node *X = NULL, *Y = NULL;
	kind *KX = NULL, *KY = NULL;
	@<Read the operands and their kinds@>;
	Kinds::Compile::perform_arithmetic_emit(op, NULL, X, NULL, KX, Y, NULL, KY);
	return;

@<Read the operands and their kinds@> =
	X = CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb,
		tokens, my_vars);
	KX = Specifications::to_kind(X);
	if (binary) {
		Y = CSIInline::parse_bracing_operand_as_identifier(ist->operand2, idb,
			tokens, my_vars);
		KY = Specifications::to_kind(Y);
	}

@ This prints a token or variable using the correct format for its kind. The
code below optimises this so that constant text is printed directly, rather
than stored as a constant text value and printed by a call to |TEXT_TY_Say|:
this saves 2 words of memory and a function call at print time. But the
result would be the same without the optimisation.

@<Inline command "say"@> =
	parse_node *to_say =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb,
			tokens, my_vars);
	if (to_say == NULL) {
		@<Issue a no-such-local problem message@>;
		return;
	}
	kind *K = CSIInline::parse_bracing_operand_as_kind(ist->operand2,
		Node::get_kind_variable_declarations(inv));

	if (Kinds::eq(K, K_text)) @<Inline say text@>;
	if (Kinds::eq(K, K_number)) @<Inline say number@>;
	if (Kinds::eq(K, K_unicode_character)) @<Inline say unicode character@>;
	if (K) {
		EmitCode::call(RTKindConstructors::printing_fn_iname(K));
		EmitCode::down();
			CompileValues::to_code_val_of_kind(to_say, K);
		EmitCode::up();
	} else @<Issue an inline no-such-kind problem@>;
	return;

@<Inline say text@> =
	wording SW = Node::get_text(to_say);
	if ((Rvalues::is_CONSTANT_of_kind(to_say, K_text)) &&
		(Wordings::length(SW) == 1) &&
		(Vocabulary::test_flags(Wordings::first_wn(SW), TEXTWITHSUBS_MC) == FALSE)) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			TEMPORARY_TEXT(T)
			TranscodeText::from_wide_string_for_emission(T,
				Lexer::word_text(Wordings::first_wn(SW)));
			EmitCode::val_text(T);
			DISCARD_TEXT(T)
		EmitCode::up();
	} else {
		kind *K = Specifications::to_kind(to_say);
		EmitCode::call(RTKindConstructors::printing_fn_iname(K));
		EmitCode::down();
			CompileValues::to_code_val_of_kind(to_say, K);
		EmitCode::up();
	}
	return;

@ Numbers are also handled directly...

@<Inline say number@> =
	EmitCode::inv(PRINTNUMBER_BIP);
	EmitCode::down();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_number, Hierarchy::find(SAY__N_HL));
			CompileValues::to_code_val_of_kind(to_say, NULL);
		EmitCode::up();
	EmitCode::up();
	return;

@ And similarly for Unicode characters. It would be tidier to abstract this
with a function call, but it would cost a function call.

Note that emitting a Unicode character is currently done with direct assembly
language.

@<Inline say unicode character@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_number, Hierarchy::find(UNICODE_TEMP_HL));
		CompileValues::to_code_val_of_kind(to_say, NULL);
	EmitCode::up();
	if (TargetVMs::is_16_bit(Task::vm())) {
		Produce::inv_assembly(Emit::tree(), I"@print_unicode");
		EmitCode::down();
			EmitCode::val_iname(K_number, Hierarchy::find(UNICODE_TEMP_HL));
		EmitCode::up();
	} else {
		Produce::inv_assembly(Emit::tree(), I"@streamunichar");
		EmitCode::down();
			EmitCode::val_iname(K_number, Hierarchy::find(UNICODE_TEMP_HL));
		EmitCode::up();
	}
	return;

@ This is for debugging purposes only: it does the equivalent of the "showme"
phrase applied to the named variable.

@<Inline command "show-me"@> =
	parse_node *to_show =
		CSIInline::parse_bracing_operand_as_identifier(ist->operand, idb, tokens, my_vars);
	if (to_show == NULL) {
		@<Issue a no-such-local problem message@>;
		return;
	}
	EmitCode::inv(IFDEBUG_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();
			CSIInline::emit_showme(to_show);
		EmitCode::up();
	EmitCode::up();
	return;

@h Miscellaneous commands.
These really have nothing in common, except that each can be used only in
very special circumstances.

@<Expand a bracing containing a miscellaneous command@> =
	if (C == segment_count_ISINC)        @<Inline command "segment-count"@>;
	if (C == final_segment_marker_ISINC) @<Inline command "final-segment-marker"@>;
	if (C == list_together_ISINC)        @<Inline command "list-together"@>;
	if (C == rescale_ISINC)              @<Inline command "rescale"@>;

@ These two are publicly documented, and have to do with multiple-segment
"say" phrases.

@<Inline command "segment-count"@> =
	EmitCode::val_number((inter_ti) Annotations::read_int(inv, ssp_segment_count_ANNOT));
	return;

@<Inline command "final-segment-marker"@> =
	if (Annotations::read_int(inv, ssp_closing_segment_wn_ANNOT) == 0) {
		EmitCode::val_iname(K_value, Hierarchy::find(NULL_HL));
	} else {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, "%~W", Wordings::one_word(
			Annotations::read_int(inv, ssp_closing_segment_wn_ANNOT)));
		inter_symbol *T_s = IdentifierFinders::find(Emit::tree(), T,
			IdentifierFinders::common_names_only());
		EmitCode::val_symbol(K_value, T_s);
		DISCARD_TEXT(T)
	}
	return;

@ This is a shim for an old Inform 6 library feature. It's used only to define
the "group... together" phrases.

@<Inline command "list-together"@> =
	if (ist->inline_subcommand == unarticled_ISINSC) {
		inter_name *iname = GroupTogether::new(FALSE);
		EmitCode::val_iname(K_value, iname);
	} else if (ist->inline_subcommand == articled_ISINSC) {
		inter_name *iname = GroupTogether::new(TRUE);
		EmitCode::val_iname(K_value, iname);
	} else StandardProblems::inline_problem(_p_(PM_InlineListTogether),
		idb, ist->owner->parent_schema->converted_from,
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
especially those involving complicated linguistic propositions.

@<Expand an entirely internal-made definition@> =
	switch (ist->inline_subcommand) {
		case repeat_through_ISINSC:
			CompileLoops::through_matches(tokens->token_vals[1],
				Lvalues::get_local_variable_if_any(tokens->token_vals[0]));
			break;
		case repeat_through_list_ISINSC:
			CompileLoops::through_list(tokens->token_vals[1],
				Lvalues::get_local_variable_if_any(tokens->token_vals[0]));
			break;
		case number_of_ISINSC:
			CompilePropositions::to_number_of_matches(tokens->token_vals[0]);	
			break;
		case random_of_ISINSC:
			CompilePropositions::to_random_match(tokens->token_vals[0]);
			break;
		case total_of_ISINSC:
			CompilePropositions::to_total_of_matches(
				Rvalues::to_property(tokens->token_vals[0]), tokens->token_vals[1]);
			break;
		case extremal_ISINSC:
			if ((ist->extremal_property_sign != MEASURE_T_EXACTLY) && (ist->extremal_property)) {
				CompilePropositions::to_extremal_match(tokens->token_vals[0],
					ist->extremal_property, ist->extremal_property_sign);
			} else {
				StandardProblems::inline_problem(_p_(PM_InlineExtremal),
				idb, ist->owner->parent_schema->converted_from,
				"In the '{-primitive-definition:extremal...}' command, there should "
				"be a '<' or '>' sign then the name of a property.");
			}
			break;
		case function_application_ISINSC:
			@<Primitive "function-application"@>
			break;
		case description_application_ISINSC:
			@<Primitive "description-application"@>
			break;
		case solve_equation_ISINSC:
			@<Primitive "solve-equation"@>
			break;
		case switch_ISINSC:
			break;
		case break_ISINSC:
			CodeBlocks::emit_break();
			break;
		case verbose_checking_ISINSC: {
			wchar_t *what = L"";
			if (tokens->tokens_count > 0) {
				parse_node *aspect = tokens->token_vals[0];
				if (Wordings::nonempty(Node::get_text(aspect))) {
					int aw1 = Wordings::first_wn(Node::get_text(aspect));
					Word::dequote(aw1);
					what = Lexer::word_text(aw1);
				}
			}
			Dash::tracing_phrases(what);
			break;
		}
		default:
			Problems::quote_stream(4, ist->operand);
			StandardProblems::inline_problem(_p_(PM_InlinePrimitive), idb,
				ist->owner->parent_schema->converted_from,
				"I don't know any primitive definition called '%4'.");
			break;
	}
	return;

@<Primitive "function-application"@> =
	parse_node *fn = tokens->token_vals[0];
	kind *fn_kind = Specifications::to_kind(fn);
	kind *X = NULL, *Y = NULL;
	if (Kinds::get_construct(fn_kind) != CON_phrase) {
		Problems::quote_spec(4, fn);
		StandardProblems::inline_problem(_p_(PM_InlineFunctionApplication),
			idb, ist->owner->parent_schema->converted_from,
			"A function application only makes sense if the first token, "
			"'%4', is a phrase: here it isn't.");
		return;
	}
	Kinds::binary_construction_material(fn_kind, &X, &Y);
	for (int i=1; i<tokens->tokens_count; i++) {
		tokens->token_vals[i-1] = tokens->token_vals[i];
		kind *head = NULL, *tail = NULL;
		Kinds::binary_construction_material(X, &head, &tail);
		X = tail;
		tokens->token_kinds[i-1] = NULL;
		if ((Kinds::Behaviour::uses_block_values(head)) &&
			(Kinds::Behaviour::definite(head)))
			tokens->token_kinds[i-1] = head;
	}
	tokens->tokens_count--;

	CallingFunctions::indirect_function_call(tokens, fn, TRUE);

@<Primitive "description-application"@> =
	parse_node *fn = tokens->token_vals[1];
	tokens->token_vals[1] = tokens->token_vals[0];
	tokens->token_vals[0] = Rvalues::from_int(-1, EMPTY_WORDING);
	tokens->tokens_count = 2;
	CallingFunctions::indirect_function_call(tokens, fn, FALSE);

@<Primitive "solve-equation"@> =
	if (Rvalues::is_CONSTANT_of_kind(tokens->token_vals[1], K_equation)) {
		EquationSolver::compile_solution(Node::get_text(tokens->token_vals[0]),
			Rvalues::to_equation(tokens->token_vals[1]));
	} else {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SolvedNameless),
			"only specific named equations can be solved",
			"not equations arrived at by further calculations or choices. (Sorry: "
			"but there would be no safe way to determine when an equation could "
			"be used, because all equations have differing natures and variables.)");
	}

@<Issue a no-such-local problem message@> =
	Problems::quote_stream(4, ist->operand);
	StandardProblems::inline_problem(_p_(PM_InlineNoSuch), idb,
		ist->owner->parent_schema->converted_from,
		"I don't know any local variable called '%4'.");

@h Parsing the invocation operands.
Two ways. First, as an identifier name, which stands for a local Inter variable
or for a token in the phrase being invoked. There are three ways we can
write this:

(a) the operands "0" to "9", a single digit, mean the |{-my:...}| variables
with those numbers, if they exist;
(b) otherwise if we have the name of a token in the phrase being invoked,
then the operand refers to its value in the current invocation;
(c) and failing that we have the name of a local Inter variable.

=
parse_node *CSIInline::parse_bracing_operand_as_identifier(text_stream *operand, id_body *idb,
	tokens_packet *tokens, local_variable **my_vars) {
	local_variable *lvar = NULL;
	if ((Str::get_at(operand, 1) == 0) &&
		(Str::get_at(operand, 0) >= '0') && (Str::get_at(operand, 0) <= '9'))
		lvar = my_vars[Str::get_at(operand, 0) - '0'];
	else {
		wording LW = Feeds::feed_text(operand);
		lvar = LocalVariables::parse(&(idb->compilation_data.id_stack_frame), LW);
		if (lvar) {
			int tok = LocalVariables::get_parameter_number(lvar);
			if (tok >= 0) return tokens->token_vals[tok];
		}
		lvar = LocalVariables::find_internal(operand);
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
= (text as Inform 7)
To give up deciding:
	(- return {-new:return-kind}; -).
=

=
kind *CSIInline::parse_bracing_operand_as_kind(text_stream *operand,
	kind_variable_declaration *kvd) {
	if (Str::eq_wide_string(operand, L"return-kind"))
		return Frames::get_kind_returned();
	if (Str::eq_wide_string(operand, L"rule-return-kind"))
		return Rulebooks::kind_from_context();
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

@h Bracket-plus notation.
An early compromise measure in the design of Inform 7, when the language was not
as expressive as it is today, was that "template files" of Inform 6 code, and
inline phrase definitions, could use the notation |(+ ... +)| to reinsert
high-level Inform 7 source text inside lower-level Inform 6 notation. Thus, for
example,
= (text)
	(- print (+ time of day +); -)
=
is a valid inline definition.

This is not (yet) deprecated, but is inelegant, and is used very little in Inform's
standard distribution. Requests to extend its abilities are very unlikely to be
heeded: it is more likely that we will curtail or abolish it.

The source text inside the |(+| and |+)| markers is evaluated as an expression,
rather than in void context, except that property names evaluate as nouns
referring to the property in the abstract rather than as conditions testing
those properties. Names of kinds of object (only) evaluate to Inter class
references for them. (Other kinds do not have Inter class references.)

=
void CSIInline::from_source_text(value_holster *VH, text_stream *p, void *opaque_state,
	int prim_cat) {
	CSIInline::eval_bracket_plus(VH, Feeds::feed_text(p), prim_cat);
}

@ This case, where orthodox compilation is happening, is more tolerable. Run the
test case |BracketPlus| to exercise every part of this function.

=
void CSIInline::eval_bracket_plus(value_holster *VH, wording LW, int prim_cat) {
	if (<property-name>(LW)) {
		CSIInline::eval_to_iname(RTProperties::iname(<<rp>>), prim_cat);
		return;
	}
	if (<k-kind>(LW)) {
		kind *K = <<rp>>;
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			CSIInline::eval_to_iname(RTKindDeclarations::iname(K), prim_cat);
			return;
		}
	}
	if (<instance-of-object>(LW)) {
		instance *I = <<rp>>;
		CSIInline::eval_to_iname(RTInstances::value_iname(I), prim_cat);
		return;
	}
	adjective *adj = Adjectives::parse(LW);
	if (adj) {
		inter_name *iname = RTAdjectives::guess_a_test_function(adj);
		if (iname)
			CSIInline::eval_to_iname(iname, prim_cat);
		else
			StandardProblems::unlocated_problem(Task::syntax_tree(),
				_p_(BelievedImpossible),
				"You tried to use '(+' and '+)' to expand to the Inter function "
				"defining an adjective, but it was an adjective with no definition.");
		return;
	}
	nonlocal_variable *nlv = NonlocalVariables::parse_global(LW);
	if (nlv) {
		CSIInline::eval_to_iname(RTVariables::iname(nlv), prim_cat);
		return;
	}
	if (prim_cat == REF_PRIM_CAT) {
		StandardProblems::unlocated_problem(Task::syntax_tree(),
			_p_(BelievedImpossible),
			"You tried to use '(+' and '+)' to store or modify something which "
			"I'm unable to alter using code written this way.");
		return;
	}

	parse_node *spec = NULL;
	@<Evaluate the text as a value@>;

	CompileValues::to_code_val(spec);
}

void CSIInline::eval_to_iname(inter_name *iname, int prim_cat) {
	if (prim_cat == REF_PRIM_CAT)
		EmitCode::ref_iname(K_value, iname);
	else 
		EmitCode::val_iname(K_value, iname);
}

@ The really bad case is this one, where we compile a sort of faux textual
representation. This is the functionality I would most like to remove from Inform.

=
void CSIInline::eval_bracket_plus_to_text(text_stream *OUT, wording LW) {
	if (<property-name>(LW)) {
		WRITE("%n", RTProperties::iname(<<rp>>));
		return;
	}
	if (<instance-of-object>(LW)) {
		instance *I = <<rp>>;
		WRITE("%~I", I);
		return;
	}
	adjective *adj = Adjectives::parse(LW);
	if (adj) {
		inter_name *iname = RTAdjectives::guess_a_test_function(adj);
		if (iname) {
			WRITE("%n", iname);
		} else {
			StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"You tried to use '(+' and '+)' to expand to the Inter function "
				"defining an adjective, but it was an adjective with no definition.");
		}
		return;
	}
	if (<k-kind>(LW)) {
		kind *K = <<rp>>;
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			WRITE("%n", RTKindDeclarations::iname(K));
			return;
		}
	}
	nonlocal_variable *nlv = NonlocalVariables::parse_global(LW);
	if (nlv) {
		PUT(URL_SYMBOL_CHAR);
		InterSymbolsTable::write_symbol_URL(OUT,
			InterNames::to_symbol(RTVariables::iname(nlv)));
		PUT(URL_SYMBOL_CHAR);
		return;
	}

	parse_node *spec = NULL;
	@<Evaluate the text as a value@>;
	if (Specifications::is_phrasal(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, LW);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PhraseInBracketsPlus));
		Problems::issue_problem_segment(
			"In %1, you tried to use '(+' and '+)' to expand to a value computed by a "
			"phrase, '%2', but these brackets can only be used with constant values.");
		Problems::issue_problem_end();
		WRITE("0");
		return;
	}
	
	inter_pair val = CompileValues::to_pair(spec);
	if (InterValuePairs::is_symbolic(val)) {
		PUT(URL_SYMBOL_CHAR);
		inter_symbol *S = InterValuePairs::to_symbol_in(val,
			Emit::current_enclosure()->actual_package);
		InterSymbolsTable::write_symbol_URL(OUT, S);
		PUT(URL_SYMBOL_CHAR);
	} else {
		CodeGen::val_to_text(OUT, Emit::at(), val, Task::vm());
	}
}

@<Evaluate the text as a value@> =
	int initial_problem_count = problem_count;
	if (<s-value>(LW)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(LW);
	if (initial_problem_count < problem_count) return;
	Dash::check_value(spec, NULL);
	if (initial_problem_count < problem_count) return;

@

=
void CSIInline::emit_showme(parse_node *spec) {
	TEMPORARY_TEXT(OUT)
	if (Node::is(spec, PROPERTY_VALUE_NT))
		spec = Lvalues::underlying_property(spec);
	kind *K = Specifications::to_kind(spec);
	if (Node::is(spec, CONSTANT_NT) == FALSE)
		WRITE("\"%+W\" = ", Node::get_text(spec));
	WRITE("%u: ", K);
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(OUT);
	EmitCode::up();
	DISCARD_TEXT(OUT)

	if (Kinds::get_construct(K) == CON_list_of) {
		EmitCode::call(Hierarchy::find(LIST_OF_TY_SAY_HL));
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number(1);
		EmitCode::up();
	} else {
		EmitCode::call(RTKindConstructors::printing_fn_iname(K));
		EmitCode::down();
			CompileValues::to_code_val(spec);
		EmitCode::up();
	}
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I"\n");
	EmitCode::up();
}
