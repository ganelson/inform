[EmitInterSchemas::] Emitting Inter Schemas.

To compile Inter code following the model in an Inter schema tree.

@ This section presents just one function to the rest of Inform: it compiles
Inter code from a schema. Though there are many arguments, this is still fairly
simple to use:

(*) |I| is the tree to compile code into. Code will appear at the current write
position in that tree.
(*) |VH| is a value holster (see //Value Holsters//), but a simple one: it either
says "generate code in a void context" (that's |INTER_VOID_VHMODE|) or "generate
code in a value context" (|INTER_VAL_VHMODE|). The difference is that, say,
statements such as |print "Hello";| cannot be compiled in a value context, only
in a void one.
(*) |sch| is the schema to compile from. It is unchanged by the process, except
that nodes made inaccessible by conditional compilation are marked as such.
(*) If the schema mentions identifiers -- as for example |DoSomething(1, 2)|
mentions the identifier |DoSomething| -- then these must somehow be matched up
with |inter_symbol|s giving them a meaning. |finder| says how: see //Identifier Finders//.
(*) As we have seen, schema notation is (almost) Inform 6 syntax, except for two
big extensions: one is Inform 7 source text placed between |(+| and |+)| markers,
and the other is braced commands like |{-by-reference: X}|. The code below cannot
deal with either of these. Instead, we must supply callback functions to deal
with them as they arise. (Supplying |NULL| as either of these makes the relevant
notation do nothing.)
(*) |opaque_state| is a pointer to any data which you, the caller, want to be
passed through to those two callback functions. The code below otherwise makes
no use of it; and it can of course be |NULL| if no state is needed.

So the simplest valid usage of the function would be something like:
= (text as InC)
	value_holster VH = Holsters::new(INTER_VOID_VHMODE);
	identifier_finder finder = IdentifierFinders::common_names_only();
	EmitInterSchemas::emit(I, &VH, sch, finder, NULL, NULL, NULL);
=
which roughly means "compile pure Inform 6 code to Inter in a void context, but
do not recognise any identifiers as corresponding to local variables".

Note that emission can turn up syntax errors which went undetected earlier
(because they depend more on context); if so, these are attached to the schema.
It's the caller's responsibility to check for those and act accordingly.

=
void EmitInterSchemas::emit(inter_tree *I, value_holster *VH, inter_schema *sch,
	identifier_finder finder,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t,
		void *opaque_state, int prim_cat, text_stream *L),
	void (*i7_source_handler)(value_holster *VH, text_stream *S,
		void *opaque_state, int prim_cat),
	void *opaque_state) {

	@<Reset the write position if we're in the middle of a switch statement@>;
	@<Recursively deal with conditional compilation@>;
	@<Traverse the tree, compiling each node@>;
}

@ This allows a very edgy edge case: schemas which make case constructions making
sense only within a switch statement, but where the schema does not itself
include the |switch| head or tail.

@<Reset the write position if we're in the middle of a switch statement@> =
	if (sch->mid_case) Produce::set_level_to_current_code_block_plus(I, 4);

@ The following looks for conditional compilations such as:
= (text as Inform 6)
	#ifdef TARGET_GLULX;
	print "This is Glulx!";
	#endif
=
and strikes out any nodes which are not to be compiled from -- for example, the
|print| statement here would be marked as |blocked_by_conditional| if the symbol
|TARGET_GLULX| were not defined.

Note that this is done only once for each schema, so we are implicitly assuming
that the outcome of |#ifdef TARGET_GLULX;| would be the same every time during the
same run of //inform7// or //inter//. But of course it must be, since although
we may generate many times from the same schema, it will always be within the
same machine architecture each time.

@<Recursively deal with conditional compilation@> =
	int again = TRUE;
	while (again) {
		again = FALSE;
		for (inter_schema_node *node = sch->node_tree; node; node=node->next_node)
			if (EmitInterSchemas::process_conditionals(I, node, finder))
				again = TRUE;
	}

@ =
int EmitInterSchemas::process_conditionals(inter_tree *I, inter_schema_node *dir_node,
	identifier_finder finder) {
	if (dir_node == NULL) return FALSE;
	if (dir_node->blocked_by_conditional) return FALSE;
	if (dir_node->isn_type == DIRECTIVE_ISNT) @<Directive@>;
	for (dir_node=dir_node->child_node; dir_node; dir_node=dir_node->next_node)
		if (EmitInterSchemas::process_conditionals(I, dir_node, finder))
			return TRUE;
	return FALSE; /* signalling the function should not be called again */
}

@<Directive@> =
	if ((dir_node->dir_clarifier == IFDEF_I6RW) ||
		(dir_node->dir_clarifier == IFNDEF_I6RW) ||
		(dir_node->dir_clarifier == IFTRUE_I6RW) ||
		(dir_node->dir_clarifier == IFFALSE_I6RW)) {
		LOGIF(SCHEMA_COMPILATION, "Conditional directive in schema!\n");
		inter_schema_node *ifnot_node = NULL, *endif_node = NULL;
		@<Find the clauses of the conditional we will resolve@>;
		
		text_stream *symbol_to_check = NULL;
		text_stream *value_to_check = NULL;
		inter_ti operation_to_check = 0;
		@<Work out what the condition is@>;

		int val = -1, def = FALSE;
		@<Find out whether this symbol is defined, and if so, what its value is@>;
		
		int decision = TRUE;
		@<Decide whether the condition is met or not@>;

		@<Mark the three clause nodes as blocked@>;

		if (decision == FALSE) @<Mark the if body as blocked@>
		else @<Mark the if-not body as blocked@>;

		if (Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) {
			LOG("--- Resulting in: ---\n");
			for (inter_schema_node *at = dir_node; at; at = at->next_node)
				InterSchemas::log_just(at, 0);
			LOG("------\n");
		}
		return TRUE; /* forcing this function to be called again */
	}

@ The aim here is to find an innermost conditional, setting |dir_node| to its
head, |ifnot_node| to the position of the |#Ifnot| -- if there is one; they
are optional in I6 -- and |endif_node| to the position of its |#Endif|, whose
existence is mandatory. For example:
= (text as Inform 6)
	#ifdef TARGET_ZCODE;
	#ifdef DEBUG;            <--- dir_node
	print "ZD!";
	#ifnot;                  <--- ifnot_node
	print "Z!";
	#endif;                  <--- endif_node
	#endif;
=
Note that we only need find one such conditional, because once we resolve it,
we will return but the function will then be applied again, and so on until
all conditionals are resolved.

@<Find the clauses of the conditional we will resolve@> =
	inter_schema_node *at = dir_node->next_node;
	while (at) {
		if (at->blocked_by_conditional == FALSE) {
			if (at->dir_clarifier == IFDEF_I6RW)   { dir_node = at; ifnot_node = NULL; }
			if (at->dir_clarifier == IFNDEF_I6RW)  { dir_node = at; ifnot_node = NULL; }
			if (at->dir_clarifier == IFTRUE_I6RW)  { dir_node = at; ifnot_node = NULL; }
			if (at->dir_clarifier == IFFALSE_I6RW) { dir_node = at; ifnot_node = NULL; }
			if (at->dir_clarifier == IFNOT_I6RW)   { ifnot_node = at; }
			if (at->dir_clarifier == ENDIF_I6RW)   { endif_node = at; break; }
		}
		at = at->next_node;
	}
	if (endif_node == NULL) {
		I6Errors::issue_at_node(dir_node, I"no matching '#endif'");
		return FALSE;
	}

@ We are going to recognise only very simple conditions, such as:
= (text as Inform 6)
	#ifdef SYMBOL;
	#iftrue SYMBOL == N;
=

@<Work out what the condition is@> =
	if ((dir_node->dir_clarifier == IFDEF_I6RW) ||
		(dir_node->dir_clarifier == IFNDEF_I6RW)) {
		if ((dir_node->child_node == NULL) ||
			(dir_node->child_node->expression_tokens == NULL)) {
			I6Errors::issue_at_node(dir_node, I"bare '#ifdef' or '#ifndef'");
			return FALSE;
		}
		symbol_to_check = dir_node->child_node->expression_tokens->material;
	} else {
		inter_schema_node *to_eval = dir_node->child_node;
		while ((to_eval) && (to_eval->isn_type == SUBEXPRESSION_ISNT))
			to_eval = to_eval->child_node;
		if ((to_eval == NULL) || (to_eval->child_node == NULL) ||
			(to_eval->child_node->expression_tokens == NULL)) {
			I6Errors::issue_at_node(dir_node, I"malformed '#if...'");
			return FALSE;
		}
		symbol_to_check = to_eval->child_node->expression_tokens->material;
		operation_to_check = to_eval->isn_clarifier;
		value_to_check = to_eval->child_node->next_node->expression_tokens->material;
	}
	LOGIF(SCHEMA_COMPILATION, "Means checking %S\n", symbol_to_check);
	if (value_to_check) LOGIF(SCHEMA_COMPILATION, "Against %S\n", value_to_check);

@<Find out whether this symbol is defined, and if so, what its value is@> =
	if (Str::eq(symbol_to_check, I"#version_number")) { val = 8; def = TRUE; }
	else if (Str::eq(symbol_to_check, I"STRICT_MODE")) { def = TRUE; }
	else {
		identifier_finder global_finder = finder;
		IdentifierFinders::next_priority(&global_finder,
			InterPackage::scope(LargeScale::architecture_package(I)));
		inter_symbol *symb = IdentifierFinders::find(I,
			symbol_to_check, global_finder);
		symb = Wiring::cable_end(symb);
		LOGIF(SCHEMA_COMPILATION, "Symb is $3\n", symb);
		if (InterSymbol::is_defined(symb)) {
			def = TRUE;
			val = InterSymbol::evaluate_to_int(symb);
		}			
	}
	LOGIF(SCHEMA_COMPILATION, "Defined: %d, value: %d\n", def, val);

@<Decide whether the condition is met or not@> =		
	if ((dir_node->dir_clarifier == IFNDEF_I6RW)
		|| (dir_node->dir_clarifier == IFDEF_I6RW)) decision = def;
	else {
		int h = Str::atoi(value_to_check, 0);
		LOGIF(SCHEMA_COMPILATION, "Want value %d\n", h);
		if (operation_to_check == EQ_BIP) decision = (val == h)?TRUE:FALSE;
		if (operation_to_check == NE_BIP) decision = (val != h)?TRUE:FALSE;
		if (operation_to_check == GE_BIP) decision = (val >= h)?TRUE:FALSE;
		if (operation_to_check == GT_BIP) decision = (val > h)?TRUE:FALSE;
		if (operation_to_check == LE_BIP) decision = (val <= h)?TRUE:FALSE;
		if (operation_to_check == LT_BIP) decision = (val < h)?TRUE:FALSE;
	}
	
	if (dir_node->dir_clarifier == IFNDEF_I6RW) decision = decision?FALSE:TRUE;
	if (dir_node->dir_clarifier == IFFALSE_I6RW) decision = decision?FALSE:TRUE;

@ Note that marking the clauses this way ensures that the next call to this
function will not pick up this same conditional again. The repeated calling
must therefore terminate, because the schema is finite in size and on each
call returning |TRUE| at least 2 previously unblocked nodes are marked as blocked.

@<Mark the three clause nodes as blocked@> =
	dir_node->blocked_by_conditional = TRUE;
	endif_node->blocked_by_conditional = TRUE;
	if (ifnot_node) ifnot_node->blocked_by_conditional = TRUE;

@<Mark the if body as blocked@> =
	inter_schema_node *at = dir_node;
	while ((at) && (at != endif_node) && (at != ifnot_node)) {
		at->blocked_by_conditional = TRUE;
		at = at->next_node;
	}

@<Mark the if-not body as blocked@> =
	inter_schema_node *at = ifnot_node;
	while ((at) && (at != endif_node)) {
		at->blocked_by_conditional = TRUE;
		at = at->next_node;
	}

@ That disposes of conditional compilation: finally we can emit unconditional
code. We do that with a recursive function; since the many parameters have to
be passed down through each call, using the following macro makes everything
easier to read. |node| is the current node to compile, of course; |prim_cat|
is the "primitive category", which is Inter jargon for context.

The category at the top of the tree depends on whether we are compiling the
schema in void or value context, which is signalled to us by |VH|. As we
recurse downwards, though, the category will change. The schema |print n;|
begins in |CODE_PRIM_CAT| (i.e., void context), but by the time the node for
|n| is reached, we must be in |VAL_PRIM_CAT|.

@d EIS_RECURSE(node, prim_cat)
	 EmitInterSchemas::emit_recursively(I, node, VH, sch, opaque_state, prim_cat,
	 	finder, inline_command_handler, i7_source_handler);

@<Traverse the tree, compiling each node@> =
	int prim_cat = CODE_PRIM_CAT;
	if (VH->vhmode_wanted == INTER_VAL_VHMODE) prim_cat = VAL_PRIM_CAT;
	else if (VH->vhmode_wanted != INTER_VOID_VHMODE)
		internal_error("must emit schemas in INTER_VAL_VHMODE or INTER_VOID_VHMODE");
	
	for (inter_schema_node *node = sch->node_tree; node; node=node->next_node)
		EIS_RECURSE(node, prim_cat);

@ As noted, this is very much a recursive function, but it does not automatically
recurse downwards: that depends on what is done at given nodes.

In particular, no children of blocked nodes -- those removed by conditional
compilation -- are ever visited.

=
void EmitInterSchemas::emit_recursively(inter_tree *I, inter_schema_node *node,
	value_holster *VH, inter_schema *sch, void *opaque_state, int prim_cat,
	identifier_finder finder,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t,
		void *opaque_state, int prim_cat, text_stream *L),
	void (*i7_source_handler)(value_holster *VH, text_stream *S,
		void *opaque_state, int prim_cat)) {
	if ((node) && (node->blocked_by_conditional == FALSE))
		@<Emit code for this unblocked node@>;
}

@<Emit code for this unblocked node@> =
	switch (node->isn_type) {
		case ASSEMBLY_ISNT: @<Assembly@>; break;
		case CALL_ISNT: @<Call@>; break;
		case CALLMESSAGE_ISNT: @<Call-message@>; break;
		case CODE_ISNT: @<Code block@>; break;
		case DIRECTIVE_ISNT: @<Non-conditional directive@>; break;
		case EVAL_ISNT: @<Eval block@>; break;
		case EXPRESSION_ISNT: @<Expression@>; break;
		case LABEL_ISNT: @<Label@>; break;
		case MESSAGE_ISNT: @<Message@>; break;
		case OPERATION_ISNT: @<Operation@>; break;
		case STATEMENT_ISNT: @<Statement@>; break;
		case SUBEXPRESSION_ISNT: @<Subexpression@>; break;
		default: internal_error("unknown schema node type");
	}

@ Assembly language can only appear in |CODE_PRIM_CAT| mode and looks like so:
= (text)
	ASSEMBLY_ISNT
		EXPRESSION_ISNT
			OPCODE_ISTT "@mul"
		EXPRESSION_ISNT
			x
		EXPRESSION_ISNT
			y
		EXPRESSION_ISNT
			z
=
Note that recursion in |VAL_PRIM_CAT| mode evaluates |x|, |y| and |z|.

@<Assembly@> =
	if (prim_cat != CODE_PRIM_CAT) { /* should never in fact happen */
		I6Errors::issue_at_node(node, I"assembly language unexpected here");
		return;
	}
	inter_schema_node *at = node->child_node;
	if (at) {
		text_stream *opcode_text = NULL;
		if (at->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *tok = at->expression_tokens;
			if ((tok->ist_type == OPCODE_ISTT) && (tok->next == NULL))
				opcode_text = tok->material;
		}
		if (opcode_text == NULL) { /* should never in fact happen */
			I6Errors::issue_at_node(node, I"assembly language malformed here");
			return;
		}
		Produce::inv_assembly(I, opcode_text);
		Produce::down(I);
		for (at = at->next_node; at; at=at->next_node)
			EIS_RECURSE(at, VAL_PRIM_CAT);
		Produce::up(I);
	}

@ What looks syntactically like a function call may in Inform 6 be a use of
one of the "built-in functions" -- for example, |y = child(O)|. But it is not
in fact a function, in the traditional Inform 6 implementation, at least;
and it is not legal to perform, say, |x = child; y = indirect(x, O);|
because |child|, not really being a function, has no address.

The design of Inter has gone back and forth over whether to make these Inter
functions in order to simplify the picture. But if so, they are a nuisance in
linking, it turns out, and so where we have ended up is that the I6 "built-in
functions" are implemented by Inter primitives. It follows that a function
call to them must be compiled as a special case.

@<Call@> =
	if (node->child_node) {
		inter_schema_token *external_tok = NULL;
		inter_schema_node *at = node->child_node;
		inter_symbol *to_call = NULL;
		inter_ti bip_for_builtin_fn = 0;
		if (at->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *tok = at->expression_tokens;
			if ((tok->ist_type == IDENTIFIER_ISTT) && (tok->next == NULL))
				@<Work out what function or primitive to call or invoke@>;
		}
		@<Compile the invocation@>;
		Produce::down(I);
		for (; at; at=at->next_node) EIS_RECURSE(at, VAL_PRIM_CAT);
		Produce::up(I);
		if (external_tok) external_tok->ist_type = IDENTIFIER_ISTT;
	}

@ Inform 6 syntax is surprisingly liberal in what it allows as a function call,
and the |f| in |f(x)| does not have to be a function name; it can be a variable,
for example, holding the address of a function.

In the following, |to_call| should be set to the |inter_symbol| for the function
to call, if the function is literally named; or |bip_for_builtin_fn| should be
set to the primitive to invoke instead; and otherwise an indirect function call
to an address will be compiled.

With one exception: the |external__f(x)| notation, which does not occur in I6,
but permits function calls outside of the target environment. See
//inform7: Calling Inform from C// for more on this. Note that although the
code here appears to amend the schema by changing a token type, it is in fact
changed back again very soon after.

@<Work out what function or primitive to call or invoke@> =
	if (Str::prefix_eq(tok->material, I"external__", 10)) { 
		external_tok = tok;
		bip_for_builtin_fn = EXTERNALCALL_BIP;
		external_tok->ist_type = DQUOTED_ISTT;
	} else if (Str::eq(tok->material, I"random")) { 
		bip_for_builtin_fn = RANDOM_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"child")) { 
		bip_for_builtin_fn = CHILD_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"children")) { 
		bip_for_builtin_fn = CHILDREN_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"parent")) { 
		bip_for_builtin_fn = PARENT_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"sibling")) { 
		bip_for_builtin_fn = SIBLING_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"metaclass")) { 
		bip_for_builtin_fn = METACLASS_BIP;
		at = at->next_node;
	} else if (Str::eq(tok->material, I"indirect")) { 
		at = at->next_node;
	} else if (Str::eq(tok->material, I"glk")) {
		I6Errors::issue_at_node(node, I"the glk() function is now unsupported");
		return;
	} else {	
		to_call = IdentifierFinders::find_token(I, tok, finder);
		if (InterSymbol::is_local(to_call)) to_call = NULL;
		if (to_call) {
			inter_tree_node *D = to_call->definition;
			if (Inode::is(D, VARIABLE_IST)) to_call = NULL;
		}
	}

@<Compile the invocation@> =
	if (bip_for_builtin_fn > 0) {
		Produce::inv_primitive(I, bip_for_builtin_fn);		
	} else if (to_call) {
		Produce::inv_call_symbol(I, to_call);
		at = at->next_node;
	} else {
		int argc = 0;
		for (inter_schema_node *n = node->child_node; n; n=n->next_node) {
			if ((n->expression_tokens) &&
				(n->expression_tokens->inline_command == combine_ISINC)) argc++;
			argc++;
		}
		inter_ti BIP = Primitives::BIP_for_indirect_call_returning_value(argc-1);
		Produce::inv_primitive(I, BIP);
	}

@ This is really a simplified version of the "call" case, where we know that
we have to perform indirection, i.e., call a function whose address is stored
somewhere (in fact, always in a property value).

@<Call-message@> =
	if (node->child_node) {
		inter_schema_node *at = node->child_node;
		int argc = 0;
		for (inter_schema_node *n = node->child_node; n; n=n->next_node) argc++;
		if (argc > 4) {
			I6Errors::issue_at_node(node, I"too many arguments for call-message");
			return;
		}
		inter_ti BIP = Primitives::BIP_for_indirect_call_returning_value(argc-1);
		Produce::inv_primitive(I, BIP);
		Produce::down(I);
		for (; at; at=at->next_node) EIS_RECURSE(at, VAL_PRIM_CAT);
		Produce::up(I);
	}

@ Note that inter schemas can contain code blocks which are half-open at either
end, and this enables some fruity Inform 7 inline phrase definitions. So the
following can generate the equivalent of |{ ...|  or |... }| as well as the
more natural |{ ... }|.

@<Code block@> =
	if (prim_cat != CODE_PRIM_CAT) {
		I6Errors::issue_at_node(node, I"unexpected '{ ... }' code block");
		return;
	}
	if (node->unopened == FALSE) {
		Produce::code(I);
		Produce::down(I);
	}
	for (inter_schema_node *at = node->child_node; at; at=at->next_node)
		EIS_RECURSE(at, CODE_PRIM_CAT);
	if (node->unclosed == FALSE) {
		Produce::up(I);
	}
	if (node->unopened) Produce::set_level_to_current_code_block_plus(I, 0);

@ Note that conditional directives have already been taken care of. The
only other Inform 6 directive valid inside a function body is OrigSource.
Therefore:

@<Non-conditional directive@> =
	if (node->dir_clarifier == ORIGSOURCE_I6RW) {
		@<OrigSource directive@>;
	}
	else {
		I6Errors::issue_at_node(node, I"misplaced directive");
		return;
	}

@<OrigSource directive@> =
	text_stream *origfilename = NULL;
	int origlinenum = 0;
	if (node->child_node) {
		origfilename = node->child_node->expression_tokens->material;
		if (node->child_node->expression_tokens->next) {
			origlinenum = Str::atoi(node->child_node->expression_tokens->next->material, 0);
		}
	}
	Produce::provenance(I, Provenance::at_file_and_line(origfilename, origlinenum));

@ An |EVAL_ISNT| node can have any number of children, they are sequentially
evaluated for their potential side-effects, but only the last produces a value.

@<Eval block@> =
	if ((prim_cat != CODE_PRIM_CAT) && (prim_cat != VAL_PRIM_CAT)){
		I6Errors::issue_at_node(node, I"expression in unexpected place");
		return;
	}
	if (node->child_node == NULL) Produce::val(I, K_value, InterValuePairs::number(1));
	else {
		int d = 0;
		for (inter_schema_node *at = node->child_node; at; at=at->next_node) {
			if (at->next_node) {
				d++;
				Produce::inv_primitive(I, SEQUENTIAL_BIP);
				Produce::down(I);
			}
			EIS_RECURSE(at, VAL_PRIM_CAT);
		}
		while (d > 0) { Produce::up(I); d--; }
	}

@ Note that an expression consisting only of a double-quoted text, in void
context, is a print-then-print-new-line-then-return-true statement in Inform 6.
This is where we detect that. (Because its meaning depends on context -- i.e.,
it doesn't mean that in value context -- we couldn't have decided this when
parsing the schema.)

@<Expression@> =
	int serial_evaluate_us = FALSE, reference_me = FALSE, print_ret_me = FALSE;
	@<Decide whether exceptional expression modes apply@>;

	if (serial_evaluate_us) { Produce::evaluation(I); Produce::down(I); }
	if (reference_me) { Produce::reference(I); Produce::down(I); }
	if (print_ret_me) {
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
	}

	for (inter_schema_token *t = node->expression_tokens; t; t=t->next)
	    @<Evaluate this token@>;

	if (print_ret_me) {
		Produce::up(I);
		Produce::inv_primitive(I, PRINTNL_BIP);
		Produce::rtrue(I);					
	}
	if (reference_me) { Produce::up(I); }
	if (serial_evaluate_us) { Produce::up(I); }

@ Note that at most one of thexe exceptional cases can arise at a time.

@<Decide whether exceptional expression modes apply@> =
	int evaluations_to_perform = 0;
	for (inter_schema_token *t = node->expression_tokens; t; t=t->next)
		evaluations_to_perform++;

	if (evaluations_to_perform > 1) {
		if (prim_cat == VAL_PRIM_CAT) serial_evaluate_us = TRUE;
	} else if (evaluations_to_perform == 1) {
		if ((prim_cat == CODE_PRIM_CAT) &&
			(node->expression_tokens->ist_type == DQUOTED_ISTT))
			print_ret_me = TRUE;
	}
	
	if (prim_cat == REF_PRIM_CAT) reference_me = TRUE;

@<Evaluate this token@> =
	switch (t->ist_type) {
		case IDENTIFIER_ISTT:
			if (prim_cat == LAB_PRIM_CAT)
				Produce::lab(I, Produce::reserve_label(I, t->material));
			else
				Produce::val_symbol(I, K_value,
					IdentifierFinders::find_token(I, t, finder));
			break;
		case ASM_ARROW_ISTT:
			Produce::assembly_marker(I, ASM_ARROW_ASMMARKER);
			break;
		case ASM_SP_ISTT:
			Produce::assembly_marker(I, ASM_SP_ASMMARKER);
			break;
		case ASM_NEGATED_LABEL_ISTT:
			if (Str::eq(t->material, I"rtrue")) 
				Produce::assembly_marker(I, ASM_NEG_RTRUE_ASMMARKER);
			else if (Str::eq(t->material, I"rfalse")) 
				Produce::assembly_marker(I, ASM_NEG_RFALSE_ASMMARKER);
			else {
				Produce::assembly_marker(I, ASM_NEG_ASMMARKER);
				Produce::lab(I, Produce::reserve_label(I, t->material));
			}
			break;
		case ASM_LABEL_ISTT:
			if (Str::eq(t->material, I"rtrue")) 
				Produce::assembly_marker(I, ASM_RTRUE_ASMMARKER);
			else if (Str::eq(t->material, I"rfalse")) 
				Produce::assembly_marker(I, ASM_RFALSE_ASMMARKER);
			else
				Produce::lab(I, Produce::reserve_label(I, t->material));
			break;
		case NUMBER_ISTT:
		case BIN_NUMBER_ISTT:
		case HEX_NUMBER_ISTT: {
			inter_pair val;
			if (t->constant_number >= 0) {
				val = InterValuePairs::number((inter_ti) t->constant_number);
			} else {
				val = InterValuePairs::number_from_I6_notation(t->material);
				if (InterValuePairs::is_undef(val)) {
					TEMPORARY_TEXT(msg)
					WRITE_TO(msg, "malformed literal number '%S'", t->material);
					I6Errors::issue_at_node(node, msg);
					DISCARD_TEXT(msg)
					return;
				}
			}
			Produce::val(I, K_value, val);
			break;
		}
		case REAL_NUMBER_ISTT:
			Produce::val_real_from_text(I, t->material);
			break;
		case DQUOTED_ISTT:
			Produce::val_text(I, t->material);
			break;
		case SQUOTED_ISTT:
			if (Str::len(t->material) == 1) {
				Produce::val_char(I, Str::get_at(t->material, 0));
			} else {
				Produce::val_dword(I, t->material);
			}
			break;
		case I7_ISTT:
			if (i7_source_handler)
				(*i7_source_handler)(VH, t->material, opaque_state, prim_cat);
			break;
		case INLINE_ISTT:
			if (inline_command_handler)
				(*inline_command_handler)(VH, t, opaque_state, prim_cat, NULL);
			break;
		default: {
			TEMPORARY_TEXT(msg)
			WRITE_TO(msg, "'%S' was unexpected in expression context", t->material);
			I6Errors::issue_at_node(node, msg);
			DISCARD_TEXT(msg)
			break;
		}
	}

@ A twig for a label, such as:
= (text)
	LABEL_ISNT
		EXPRESSION_ISNT
			MyLabel
=
This places the label |MyLabel| at the current write position.

What makes this more complicated is that an inline command might be being used
to determine the name of that label, and/or to amend a label numbering counter.
For example, the schema |.{-label:Say}{-counter-up:Say};| results in:
= (text)
	LABEL_ISNT
		EXPRESSION_ISNT
			INLINE_ISNT = label:Say
		EXPRESSION_ISNT
			INLINE_ISNT = counter-up:Say
=

@<Label@> =
	if (prim_cat != CODE_PRIM_CAT) {
		I6Errors::issue_at_node(node, I"label in unexpected place");
		return;
	}
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".");
	for (inter_schema_node *at = node->child_node; at; at=at->next_node) {
		for (inter_schema_token *t = at->expression_tokens; t; t=t->next) {
			if (t->ist_type == IDENTIFIER_ISTT) {
				WRITE_TO(L, "%S", t->material);
			} else if ((t->ist_type == INLINE_ISTT) &&
					((t->inline_command == label_ISINC) ||
					 (t->inline_command == counter_up_ISINC) ||
					 (t->inline_command == counter_down_ISINC))) {
				value_holster VN = Holsters::new(INTER_DATA_VHMODE);
				if (inline_command_handler)
					(*inline_command_handler)(&VN, t, opaque_state, VAL_PRIM_CAT, L);
			} else {
				TEMPORARY_TEXT(msg)
				WRITE_TO(msg, "expected label name but found '%S'", t->material);
				I6Errors::issue_at_node(node, msg);
				DISCARD_TEXT(msg)
				return;
			}
		}
	}
	Produce::place_label(I, Produce::reserve_label(I, L));
	DISCARD_TEXT(L)

@<Message@> =
	inter_schema_node *at = node->child_node;
	if (at) {
		int argc = 0;
		for (inter_schema_node *n = at; n; n=n->next_node) argc++;
		inter_ti BIP = Primitives::BIP_for_message_send(argc);
		Produce::inv_primitive(I, BIP);
		Produce::down(I);
		for (; at; at=at->next_node) EIS_RECURSE(at, VAL_PRIM_CAT);
		Produce::up(I);
	}

@ Note the three pseudo-operations here -- that is, operators which do not
directly correspond to Inter primitives. They are:

(*) |HAS_XBIP|, which is done by performing a property lookup;
(*) |HASNT_XBIP|, which is done by negating the same;
(*) |OWNERKIND_XBIP|, which is a way to finesse that |PROPERTYVALUE_BIP| is
ternary at the Inter level, but only binary in Inform 6 source code. When
the code writes |obj.prop|, this is treated here as if it had been
|OBJECT_TY>>obj.prop|; so the value |OBJECT_TY| is dropped in. But if the
author had written |K>>obj.prop| -- giving the full ternary form -- we
suppress the |>>| operator and take |K|, |obj|, |prop| as the three arguments
to the primitive |PROPERTYVALUE_BIP|. (|>>| has no other purpose or use, and
is not present in standard Inform 6 syntax.)

@<Operation@> =
	inter_ti op = node->isn_clarifier;	
	if ((op == HAS_XBIP) || (op == HASNT_XBIP)) op = PROPERTYVALUE_BIP;

	int reference_me = FALSE, negate_me = FALSE, insert_OBJECT_TY = FALSE, nop_me = FALSE;
	@<Decide whether exceptional operator modes apply@>;
	
	if (reference_me) {
		Produce::reference(I);
		Produce::down(I);
	}
	if (negate_me) {
		Produce::inv_primitive(I, NOT_BIP);
		Produce::down(I);
	}
	if (nop_me == FALSE) {
		Produce::inv_primitive(I, op);
		Produce::down(I);
	}
	@<Operands@>;
	if (nop_me == FALSE) { Produce::up(I); }
	if (negate_me) { Produce::up(I); }
	if (reference_me) { Produce::up(I); }

@<Decide whether exceptional operator modes apply@> =
	if (prim_cat == REF_PRIM_CAT) reference_me = TRUE;
	if (node->isn_clarifier == HASNT_XBIP) negate_me = TRUE;
	if ((op == PROPERTYEXISTS_BIP) || (op == PROPERTYVALUE_BIP) ||
		(op == PROPERTYARRAY_BIP) || (op == PROPERTYLENGTH_BIP)) {
		if ((node->child_node->isn_type != OPERATION_ISNT) ||
			(node->child_node->isn_clarifier != OWNERKIND_XBIP))
			insert_OBJECT_TY = TRUE;
	}
	if (op == OWNERKIND_XBIP) nop_me = TRUE;

@<Operands@> =
	if (insert_OBJECT_TY) {
		inter_symbol *OBJECT_TY_s =
			IdentifierFinders::find(I, I"OBJECT_TY", finder);
		Produce::val_symbol(I, K_value, OBJECT_TY_s);
	}
	int pc = VAL_PRIM_CAT;
	if (Primitives::term_category(node->isn_clarifier, 0) == REF_PRIM_CAT)
		pc = REF_PRIM_CAT;
	EIS_RECURSE(node->child_node, pc);
	if (I6Operators::arity(node->isn_clarifier) == 2)
		EIS_RECURSE(node->child_node->next_node, VAL_PRIM_CAT);

@ The pseudo-statement |READ_XBIP| is handled as the assembly language |@aread|.
We don't want to regard keyboard input as being a core feature of the Inter
instruction set, but rather as something available on some platforms and not
on others.

@<Statement@> =
	if (prim_cat != CODE_PRIM_CAT) {
		I6Errors::issue_at_node(node, I"statement in unexpected place");
		return;
	}
	if (node->isn_clarifier == CASE_BIP) Produce::set_level_to_current_code_block_plus(I, 2);
	if (node->isn_clarifier == READ_XBIP) Produce::inv_assembly(I, I"@aread");
	else Produce::inv_primitive(I, node->isn_clarifier);
	if (node->isn_clarifier == OBJECTLOOP_BIP) {
		@<Handle OBJECTLOOP as a special case@>;
	} else {
		int arity = Primitives::term_count(node->isn_clarifier);
		if (arity > 0) {
			Produce::down(I);
			inter_schema_node *at = node->child_node;
			inter_schema_node *last = NULL;
			for (int i = 0; ((at) && (i<arity)); i++) {
				EIS_RECURSE(at, Primitives::term_category(node->isn_clarifier, i));
				last = at;
				at = at->next_node;
			}
			if (!((last) && (last->unclosed))) Produce::up(I);
		}
	}

@ As noted in //Inter Primitives//, the signature of |OBJECTLOOP_BIP| is
|ref val val code -> void|, so it needs four operands:

(1) The |ref| is the variable.
(2) The first |val| is the object class it ranges over. If we are unable to
narrow this down, we will simply make that |Object|, the result being a
potentially slow loop over all objects.
(3) The second |val| is condition which must apply to any given |x| for the
code block to be executed.
(4) The |code| is the code block.

But it arrives here not with four child nodes, but just two, corresponding to
the second |val| and the |code| respectively. We must find the first two as
subexpressions of the first child, by directly probing its subtree. Consider
these possibilities:
= (text)
	objectloop (x) { ... }
	            |  \ code
	            ref and second val; first val is "Object"

	objectloop (x ofclass K1_thing) { ... }
	            |            |         |
	            ref       first val   code
	           --------------------
	                second val

	objectloop ((x ofclass K1_thing) && (x has container)) { ... }
	             |             |                              |
	             ref       first val                         code
	           -------------------------------------------
	                           second val
=

@<Handle OBJECTLOOP as a special case@> =
	Produce::down(I);
	inter_schema_node *oc_node = node->child_node;
	while ((oc_node) &&
		((oc_node->isn_type != OPERATION_ISNT) ||
		(oc_node->isn_clarifier != OFCLASS_BIP)))
		oc_node = oc_node->child_node;
	if (oc_node) {
		inter_schema_node *var_node = oc_node->child_node;
		inter_schema_node *cl_node = var_node?(var_node->next_node):NULL;
		if ((var_node) && (cl_node)) {
			EIS_RECURSE(var_node, REF_PRIM_CAT);
			EIS_RECURSE(cl_node, VAL_PRIM_CAT);
		} else {
			I6Errors::issue_at_node(node, I"malformed 'objectloop' header");
			return;
		}
	} else {
		inter_schema_node *var_node = node->child_node;
		while ((var_node) && (var_node->isn_type != EXPRESSION_ISNT))
			var_node = var_node->child_node;
		if ((var_node) && (var_node->expression_tokens) &&
			((var_node->expression_tokens->ist_type == IDENTIFIER_ISTT) ||
				(var_node->expression_tokens->ist_type == INLINE_ISTT))) {
			EIS_RECURSE(var_node, REF_PRIM_CAT);
			Produce::val_symbol(I, K_value, IdentifierFinders::find(I, I"Object", finder));
		} else {
			I6Errors::issue_at_node(node, I"'objectloop' without visible variable");
			return;
		}
	}
	inter_schema_node *at = node->child_node;
	EIS_RECURSE(at, VAL_PRIM_CAT);
	at = at->next_node;
	EIS_RECURSE(at, CODE_PRIM_CAT);
	if (at->unclosed == FALSE) Produce::up(I);

@ Last and least: a subexpression node gives one or more nodes to be evaluated,
and if there's more than one, we use the |SEQUENTIAL_BIP| operator (which is
like the comma in C) to throw away the results of the non-final evaluations.

@<Subexpression@> =
	int d = 0;
	for (inter_schema_node *at = node->child_node; at; at=at->next_node) {
		if (at->next_node) {
			d++;
			Produce::inv_primitive(I, SEQUENTIAL_BIP);
			Produce::down(I);
		}
		EIS_RECURSE(at, prim_cat);
	}
	while (d > 0) { Produce::up(I); d--; }
