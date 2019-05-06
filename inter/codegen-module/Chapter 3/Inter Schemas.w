[InterSchemas::] Inter Schemas.

@h Definition.
An inter schema is a set of instructions for compiling inter code, while
interspersing certain values at given places.

The main use of this is for compiling invocations of inline-defined phrases.
For example, the phrase definition:

>> To adjust (N - a number): (- AdjustThis({N}, 1); -).

results in an inter schema being compiled from this text:

	|AdjustThis({N}, 1);|

The notation here is essentially Inform 6 code with a few special features
in braces: here, |{N}|, which expands to the value of the token |N| mentioned
in the phrase preamble. The notation being basically I6 was very convenient
in the years 2004-17, when Inform generated only I6 code: it became more
problematic in 2018. The task then was to generate inter instructions, even
though those would then usually be converted back into I6 anyway.

And so the code in this section was written. The first half amounts to a
miniature Inform 6 compiler: its task is to take text such as

	|AdjustThis({N}, 1);|

and convert that into an inter schema. The second half is a code generator,
which takes a given schema and generates inter code from it.

@h Anatomy of a schema.
Relatively few inter schemas are generated during Inform's run (typically a
few hundred), so they do not need to be stored compactly or compiled quickly.

=
typedef struct inter_schema {
	struct text_stream *converted_from; /* copy of the source notation */
	struct inter_schema_node *node_tree; /* the structure */
	int mid_case; /* does this seem to be used inside a switch case? */
	int dereference_mode; /* emit from this in dereference-pointers mode */
	MEMORY_MANAGEMENT
} inter_schema;

@ =
inter_schema *InterSchemas::new(text_stream *source) {
	inter_schema *sch = CREATE(inter_schema);
	sch->converted_from = Str::duplicate(source);
	sch->node_tree = NULL;
	sch->mid_case = FALSE;
	sch->dereference_mode = FALSE;
	return sch;
}

@ A schema is a connected tree of nodes, each of which has one of the
following types. (Tempting to mark eliminated nodes as |OH_NO_IT_ISNT|,
but the need to do this went away.)

@e EXPRESSION_ISNT from 1
@e CODE_ISNT
@e EVAL_ISNT
@e STATEMENT_ISNT
@e OPERATION_ISNT
@e SUBEXPRESSION_ISNT
@e DIRECTIVE_ISNT
@e ASSEMBLY_ISNT
@e LABEL_ISNT
@e CALL_ISNT
@e MESSAGE_ISNT
@e CALLMESSAGE_ISNT

=
typedef struct inter_schema_node {
	struct inter_schema *parent_schema;

	struct inter_schema_node *parent_node;
	struct inter_schema_node *child_node;
	struct inter_schema_node *next_node;
	int node_marked;								/* used fleetingly during traverses */

	int isn_type;									/* one of the |*_ISNT| values */
	struct inter_symbol *isn_clarifier;				/* for |STATEMENT_ISNT| and |OPERATION_ISNT| only */
	int dir_clarifier;								/* for |DIRECTIVE_ISNT| only */
	struct inter_schema_token *expression_tokens;	/* for |EXPRESSION_ISNT| only */

	int semicolon_terminated;						/* for |EXPRESSION_ISNT| only */
	int unclosed;									/* for |CODE_ISNT| only */
	int unopened;									/* for |CODE_ISNT| only */

	int blocked_by_conditional;						/* used in code generation */

	MEMORY_MANAGEMENT
} inter_schema_node;

@ =
inter_schema_node *InterSchemas::new_node(inter_schema *sch, int isnt) {
	inter_schema_node *isn = CREATE(inter_schema_node);
	isn->parent_schema = sch;

	isn->parent_node = NULL;
	isn->child_node = NULL;
	isn->next_node = NULL;
	isn->node_marked = FALSE;

	isn->isn_type = isnt;

	isn->expression_tokens = NULL;
	isn->isn_clarifier = NULL;
	isn->dir_clarifier = -1;

	isn->semicolon_terminated = FALSE;
	isn->unclosed = FALSE;
	isn->unopened = FALSE;
	isn->blocked_by_conditional = FALSE;

	return isn;
}

@ Ordinarily, a |CODE_ISNT| node represents a complete block of I6 code.
For example, in

	|if (x == 1) { print "Hello!"; }|

the print statement occurs inside a complete block, which will eventually
be represented as a |CODE_ISNT|. But some inline phrase definitions leave
blocks half-open. For example,

	|if (x == 1)|

is a legal phrase definition: we read it as

	|if (x == 1) {|

and the schema has to contain a |CODE_ISNT| marked as having been left
unclosed. Similarly, some definitions close an I6 block which is assumed
as having been opened by an earlier phrase invocation.

Here we mark a code node as being unclosed. Clearly, if a node is unclosed
then any parent code nodes of it must also be unclosed, so we recurse
upwards.

=
void InterSchemas::mark_unclosed(inter_schema_node *isn) {
	while (isn) {
		if (isn->isn_type == CODE_ISNT) isn->unclosed = TRUE;
		isn = isn->parent_node;
	}
}

@ The situation with unopened nodes is different: we must ensure that a
single code node is left unopened, even if we have to create a code node
at the top of the tree to serve that role.

=
void InterSchemas::mark_unopened(inter_schema_node *isn) {
	while (isn) {
		if (isn->isn_type == CODE_ISNT) {
			isn->unopened = TRUE;
			return;
		}
		if (isn->parent_node == NULL) {
			inter_schema *sch = isn->parent_schema;
			inter_schema_node *top = sch->node_tree;
			inter_schema_node *code_isn = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
			code_isn->child_node = top;
			sch->node_tree = code_isn;
			for (inter_schema_node *n = top; n; n = n->next_node)
				n->parent_node = code_isn;
			code_isn->unopened = TRUE;
			return;
		}
		isn = isn->parent_node;
	}
}

@ A further complication is that some schemas arise from definitions used
only in the middle of switch statements; they contain neither the start nor
the end of the construct, so the above mechanisms are not sufficient.
For example, the inline definition

	|{X}:|

implies, by use of the colon, that it's a switch case. We can't conveniently
associate this with any single node, so we mark the schema as a whole.

=
void InterSchemas::mark_case_closed(inter_schema_node *isn) {
	if (isn) isn->parent_schema->mid_case = TRUE;
}

@ |EXPRESSION_ISNT| nodes carry a linked list of tokens with them. When we
begin compiling a schema, we form a single expression node with a long list
of tokens: gradually this is transformed into a tree of nodes with more,
but much shorter, expression nodes, and in the process most of the token
types are eliminated. The following types are present only during the
compilation process, and never survive into the final schema:

@e RAW_ISTT from 1			/* something unidentified as yet */
@e WHITE_SPACE_ISTT			/* a stretch of white space */
@e RESERVED_ISTT			/* am I6 reserved word such as |while| */
@e OPERATOR_ISTT			/* an I6 operator such as |-->| or |+| */
@e DIVIDER_ISTT				/* a semicolon used to divide I6 statements */
@e OPEN_ROUND_ISTT			/* open round bracket */
@e CLOSE_ROUND_ISTT			/* close round bracket */
@e OPEN_BRACE_ISTT			/* open brace bracket */
@e CLOSE_BRACE_ISTT			/* close brace bracket */
@e COMMA_ISTT				/* comma */
@e COLON_ISTT				/* colon */

@ Whereas these token types do make it into the compiled schema:

@e IDENTIFIER_ISTT			/* an I6 identifier such as |my_var12| */
@e OPCODE_ISTT				/* an Inform assembly language opcode such as |@pull| */
@e DIRECTIVE_ISTT			/* an Inform compiler directive such as |#iftrue| */
@e NUMBER_ISTT				/* a constant number */
@e BIN_NUMBER_ISTT			/* a constant number */
@e HEX_NUMBER_ISTT			/* a constant number */
@e REAL_NUMBER_ISTT			/* a constant number */
@e DQUOTED_ISTT				/* a constant piece of text |"like this"| */
@e SQUOTED_ISTT				/* a constant piece of text such as |'x'| */
@e I7_ISTT					/* I7 material in |(+ ... +)| notation */
@e INLINE_ISTT				/* an inline command such as |{-my:1}| */
@e ASM_ARROW_ISTT			/* the arrow sign |->| used in assembly language only */
@e ASM_SP_ISTT				/* the stack pointer pseudo-variable |sp| */
@e ASM_LABEL_ISTT			/* the label sign |?| used in assembly language only */
@e ASM_NEGATED_LABEL_ISTT   /* the label sign |?~| used in assembly language only */

=
typedef struct inter_schema_token {
	struct inter_schema_node *owner;			/* these form a linked list attached to the owner node */
	struct inter_schema_token *next;

	int ist_type;								/* one of the |*_ISTT| values above */
	struct text_stream *material;				/* textual form of token */

	struct inter_symbol *operation_primitive;	/* |OPERATOR_ISTT| only: e.g. |plus_interp| for |+| */
	int reserved_word;							/* |RESERVED_ISTT| only: which one */
	int constant_number;						/* |NUMBER_ISTT| only: if non-negative, value of number */
	#ifdef CORE_MODULE
	struct inter_name *as_quoted;				/* |IDENTIFIER_ISTT| only: the identified symbol if known */
	#endif
	int inline_command;							/* |INLINE_ISTT| only: one of the |*_ISINC| values */
	int inline_modifiers;
	int inline_subcommand;						/* |INLINE_ISTT| only: one of the |*_ISINSC| values */
	struct text_stream *bracing;
	struct text_stream *command;
	struct text_stream *operand;
	struct text_stream *operand2;
	#ifdef CORE_MODULE
	struct property *extremal_property;
	int extremal_property_sign;
	#endif

	int preinsert;								/* fleeting markers only */
	int postinsert;

	MEMORY_MANAGEMENT
} inter_schema_token;

@ =
inter_schema_token *InterSchemas::new_token(int type, text_stream *material, inter_symbol *operation_primitive, int reserved_word, int n) {
	inter_schema_token *t = CREATE(inter_schema_token);
	t->ist_type = type;
	t->material = Str::duplicate(material);
	t->bracing = NULL;
	t->command = NULL;
	t->operand = NULL;
	t->operand2 = NULL;
	#ifdef CORE_MODULE
	t->extremal_property = NULL; /* that is, none given */
	t->extremal_property_sign = MEASURE_T_EXACTLY; /* that is, none given */
	#endif
	t->inline_command = no_ISINC;
	t->inline_subcommand = no_ISINSC;
	t->next = NULL;
	t->owner = NULL;
	t->operation_primitive = operation_primitive;
	#ifdef CORE_MODULE
	t->as_quoted = NULL;
	#endif
	t->reserved_word = reserved_word;
	t->constant_number = n;
	t->preinsert = FALSE;
	t->postinsert = FALSE;
	return t;
}

@ The value of |reserved_word|, in a |RESERVED_ISTT| node, must be one of:

@e IF_I6RW from 1
@e ELSE_I6RW
@e STYLE_I6RW
@e RETURN_I6RW
@e RTRUE_I6RW
@e RFALSE_I6RW
@e FOR_I6RW
@e OBJECTLOOP_I6RW
@e WHILE_I6RW
@e DO_I6RW
@e UNTIL_I6RW
@e PRINT_I6RW
@e PRINTRET_I6RW
@e NEWLINE_I6RW
@e GIVE_I6RW
@e MOVE_I6RW
@e REMOVE_I6RW
@e JUMP_I6RW
@e SWITCH_I6RW
@e DEFAULT_I6RW
@e FONT_I6RW
@e BREAK_I6RW
@e CONTINUE_I6RW
@e QUIT_I6RW
@e RESTORE_I6RW
@e SPACES_I6RW
@e READ_I6RW
@e INVERSION_I6RW

@e IFDEF_I6RW
@e IFNDEF_I6RW
@e IFTRUE_I6RW
@e IFFALSE_I6RW
@e IFNOT_I6RW
@e ENDIF_I6RW

@ The value of |inline_command|, in an |INLINE_ISTT| node, must be one of:

@e no_ISINC from 1
@e primitive_definition_ISINC
@e new_ISINC
@e new_list_of_ISINC
@e printing_routine_ISINC
@e next_routine_ISINC
@e previous_routine_ISINC
@e ranger_routine_ISINC
@e strong_kind_ISINC
@e weak_kind_ISINC
@e backspace_ISINC
@e erase_ISINC
@e open_brace_ISINC
@e close_brace_ISINC
@e label_ISINC
@e counter_ISINC
@e counter_storage_ISINC
@e counter_up_ISINC
@e counter_down_ISINC
@e counter_makes_array_ISINC
@e by_reference_ISINC
@e by_reference_blank_out_ISINC
@e reference_exists_ISINC
@e lvalue_by_reference_ISINC
@e by_value_ISINC
@e box_quotation_text_ISINC
@e try_action_ISINC
@e try_action_silently_ISINC
@e return_value_ISINC
@e return_value_from_rule_ISINC
@e property_holds_block_value_ISINC
@e mark_event_used_ISINC
@e my_ISINC
@e unprotect_ISINC
@e copy_ISINC
@e initialise_ISINC
@e matches_description_ISINC
@e now_matches_description_ISINC
@e arithmetic_operation_ISINC
@e say_ISINC
@e show_me_ISINC
@e segment_count_ISINC
@e final_segment_marker_ISINC
@e list_together_ISINC
@e rescale_ISINC
@e unknown_ISINC

@e substitute_ISINC
@e current_sentence_ISINC
@e combine_ISINC

@ The value of |inline_subcommand|, in an |INLINE_ISTT| node, must be one of:

@e no_ISINSC from 1
@e unarticled_ISINSC
@e articled_ISINSC
@e repeat_through_ISINSC
@e repeat_through_list_ISINSC
@e number_of_ISINSC
@e random_of_ISINSC
@e total_of_ISINSC
@e extremal_ISINSC
@e function_application_ISINSC
@e description_application_ISINSC
@e solve_equation_ISINSC
@e switch_ISINSC
@e break_ISINSC
@e verbose_checking_ISINSC

@h Token insertion.

=
void InterSchemas::add_token(inter_schema *sch, inter_schema_token *t) {
	if (sch->node_tree == NULL)
		sch->node_tree = InterSchemas::new_node(sch, EXPRESSION_ISNT);
	InterSchemas::add_token_to_node(sch->node_tree, t);
}

void InterSchemas::add_token_to_node(inter_schema_node *isn, inter_schema_token *t) {
	if (isn->expression_tokens == NULL) isn->expression_tokens = t;
	else {
		inter_schema_token *p = isn->expression_tokens;
		while ((p) && (p->next)) p = p->next;
		p->next = t;
	}
	t->owner = isn;
}

void InterSchemas::add_token_after(inter_schema_token *t, inter_schema_token *existing) {
	if (existing == NULL) internal_error("can't add after null element");
	inter_schema_token *was = existing->next;
	existing->next = t;
	t->next = was;
	t->owner = existing->owner;
}

@h Logging.
It is invaluable to be able to see compiled schemas in the debugging log, so
we go to some trouble here.

=
void InterSchemas::log(OUTPUT_STREAM, void *vis) {
	inter_schema *sch = (inter_schema *) vis;
	if (sch == NULL) LOG("<null schema>\n");
	else if (sch->node_tree == NULL) LOG("<schema without nodes>\n");
	else InterSchemas::log_depth(sch->node_tree, 0);
}

void InterSchemas::log_depth(inter_schema_node *isn, int depth) {
	for (; isn; isn=isn->next_node)
		InterSchemas::log_just(isn, depth);
}
void InterSchemas::log_just(inter_schema_node *isn, int depth) {
	if (isn->blocked_by_conditional) LOG("XX"); else LOG("  ");
	for (int d = 0; d < depth; d++) LOG("    ");
	switch (isn->isn_type) {
		case STATEMENT_ISNT:
			LOG("* (statement) %S\n", isn->isn_clarifier->symbol_name);
			break;
		case OPERATION_ISNT:
			LOG("* (operation) %S\n", isn->isn_clarifier->symbol_name);
			break;
		case CODE_ISNT:
			LOG("* (code)");
			if (isn->unclosed) LOG(" <");
			if (isn->unopened) LOG(" >");
			LOG("\n");
			break;
		case EVAL_ISNT:
			LOG("* (eval)\n");
			break;
		case ASSEMBLY_ISNT:
			LOG("* (assembly)\n");
			break;
		case DIRECTIVE_ISNT:
			LOG("* (directive) ");
			switch(isn->dir_clarifier) {
				case IFDEF_I6RW: LOG("#ifdef"); break;
				case IFNDEF_I6RW: LOG("#ifndef"); break;
				case IFTRUE_I6RW: LOG("#iftrue"); break;
				case IFFALSE_I6RW: LOG("#iffalse"); break;
				case IFNOT_I6RW: LOG("#ifnot"); break;
				case ENDIF_I6RW: LOG("#endif"); break;
				default: LOG("<unknown>"); break;
			}
			LOG("\n");
			break;
		case LABEL_ISNT:
			LOG("* (label)\n");
			break;
		case CALL_ISNT:
			LOG("* (call)\n");
			break;
		case MESSAGE_ISNT:
			LOG("* (message)\n");
			break;
		case CALLMESSAGE_ISNT:
			LOG("* (call-message)\n");
			break;
		case SUBEXPRESSION_ISNT:
			LOG("* (subexpression)\n");
			break;
		case EXPRESSION_ISNT:
			LOG("* (expr)");
			if (isn->semicolon_terminated) LOG(" ;");
			if (isn->unclosed) LOG(" <");
			if (isn->unopened) LOG(" >");
			if (isn->expression_tokens == NULL) LOG(" - empty");
			LOG("\n");
			for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
				for (int d = 0; d < depth + 1; d++) LOG("    ");
				InterSchemas::log_ist(t);
				if (isn != t->owner) LOG(" !!! ownership incorrect here");
				LOG("\n");
			}
			break;
	}
	InterSchemas::log_depth(isn->child_node, depth+1);
}

void InterSchemas::log_ist(inter_schema_token *t) {
	if (t == NULL) { LOG("<NULL-IST>"); return; }
	switch (t->ist_type) {
		case RAW_ISTT:			LOG("RAW         "); break;
		case OPERATOR_ISTT:		LOG("OPERATOR    "); break;
		case OPCODE_ISTT:		LOG("OPCODE      "); break;
		case DIRECTIVE_ISTT:	LOG("DIRECTIVE   "); break;
		case IDENTIFIER_ISTT:	LOG("IDENTIFIER  "); break;
		case RESERVED_ISTT:		LOG("RESERVED    "); break;
		case NUMBER_ISTT:		LOG("NUMBER      "); break;
		case BIN_NUMBER_ISTT:	LOG("BIN_NUMBER  "); break;
		case HEX_NUMBER_ISTT:	LOG("HEX_NUMBER  "); break;
		case REAL_NUMBER_ISTT:	LOG("REAL_NUMBER "); break;
		case DQUOTED_ISTT:		LOG("DQUOTED     "); break;
		case SQUOTED_ISTT:		LOG("SQUOTED     "); break;
		case WHITE_SPACE_ISTT:	LOG("WHITE_SPACE "); break;
		case DIVIDER_ISTT:		LOG("DIVIDER     "); break;
		case OPEN_ROUND_ISTT:	LOG("OPEN_ROUND  "); break;
		case CLOSE_ROUND_ISTT:	LOG("CLOSE_ROUND "); break;
		case OPEN_BRACE_ISTT:	LOG("OPEN_BRACE  "); break;
		case CLOSE_BRACE_ISTT:	LOG("CLOSE_BRACE "); break;
		case COMMA_ISTT:		LOG("COMMA       "); break;
		case COLON_ISTT:		LOG("COLON       "); break;
		case I7_ISTT:			LOG("I7          "); break;
		case INLINE_ISTT:		LOG("INLINE      "); break;
		case ASM_ARROW_ISTT:	LOG("ASM_ARROW   "); break;
		case ASM_SP_ISTT:		LOG("ASM_SP      "); break;
		case ASM_LABEL_ISTT:	LOG("ASM_LABEL   "); break;
		case ASM_NEGATED_LABEL_ISTT:	LOG("NEGASM_LABEL "); break;
		default: LOG("<unknown>"); break;
	}
	LOG("%S", t->material);
	if (t->inline_modifiers & GIVE_KIND_ID_ISSBM) LOG(" GIVE_KIND_ID");
	if (t->inline_modifiers & GIVE_COMPARISON_ROUTINE_ISSBM) LOG(" GIVE_COMPARISON_ROUTINE");
	if (t->inline_modifiers & DEREFERENCE_PROPERTY_ISSBM) LOG(" DEREFERENCE_PROPERTY");
	if (t->inline_modifiers & ADOPT_LOCAL_STACK_FRAME_ISSBM) LOG(" ADOPT_LOCAL_STACK_FRAME");
	if (t->inline_modifiers & CAST_TO_KIND_OF_OTHER_TERM_ISSBM) LOG(" CAST_TO_KIND_OF_OTHER_TERM");
	if (t->inline_modifiers & BY_REFERENCE_ISSBM) LOG(" BY_REFERENCE");
	if (t->inline_modifiers & PERMIT_LOCALS_IN_TEXT_CMODE_ISSBM) LOG(" PERMIT_LOCALS_IN_TEXT_CMODE");
}

@h Lint.
As can be seen, the |inter_schema| structure is quite complicated, and there
are numerous invariants it has to satisfy. As a precaution, then, we check that
all of these invariants hold before shipping out a compiled schema. This is
where the check is done:

=
void InterSchemas::lint(inter_schema *sch) {
	if (sch) {
		text_stream *err = InterSchemas::lint_isn(sch->node_tree, 0);
		if (err) {
			LOG("Lint fail: %S\n$1\n", err, sch);
			internal_error("inter schema failed lint");
		}
	}
}

text_stream *InterSchemas::lint_isn(inter_schema_node *isn, int depth) {
	for (; isn; isn=isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			int asm = FALSE;
			for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
				switch (t->ist_type) {
					case OPCODE_ISTT:		if (t == isn->expression_tokens) asm = TRUE;
											else return I"contains loose assembler";
											break;
					case RAW_ISTT:			return I"contains raw node";
					case OPEN_BRACE_ISTT:	return I"contains open-brace node";
					case CLOSE_BRACE_ISTT:	return I"contains close-brace node";
					case OPEN_ROUND_ISTT:	return I"contains open-round node";
					case CLOSE_ROUND_ISTT:	return I"contains close-round node";
					case COMMA_ISTT:		return I"contains comma node";
					case DIVIDER_ISTT:		return I"contains divider node";
					case RESERVED_ISTT:		return I"contains reserved word node";
					case COLON_ISTT:		return I"contains colon node";
					case OPERATOR_ISTT:		return I"contains operator node";
				}
				if ((t->ist_type == INLINE_ISTT) && (t->inline_command == open_brace_ISINC))
					return I"contains manual open-brace";
				if ((t->ist_type == INLINE_ISTT) && (t->inline_command == close_brace_ISINC))
					return I"contains manual close-brace";
				if ((t->ist_type == NUMBER_ISTT) && (t->next) && (t->next->ist_type == NUMBER_ISTT) && (asm == FALSE))
					return I"two consecutive numbers";
				if (isn != t->owner)
					return I"ownership linkage broken";
			}
			if (isn->child_node) return I"expression has child nodes";
		} else {
			if (isn->expression_tokens) return I"non-expression has elements";
		}
		if ((isn->child_node) && (isn->child_node->parent_node != isn))
			return I"child-parent linkage broken";
		if ((isn->isn_clarifier) && (isn->expression_tokens))
			return I"ambiguous is-node";
		text_stream *R = InterSchemas::lint_isn(isn->child_node, depth+1);
		if (R) return R;
	}
	return NULL;
}

@h I6S.

=
dictionary *compiled_i6s_dict = NULL;

inter_schema *InterSchemas::from_i6s(text_stream *prototype, int no_quoted_inames, void **quoted_inames) {
	if (compiled_i6s_dict == NULL) {
		compiled_i6s_dict = Dictionaries::new(512, FALSE);
	}
	dict_entry *de = Dictionaries::find(compiled_i6s_dict, prototype);
	if (de) return (inter_schema *) Dictionaries::read_value(compiled_i6s_dict, prototype);

	inter_schema *result = InterSchemas::from_text(prototype, TRUE, no_quoted_inames, quoted_inames);

	Dictionaries::create(compiled_i6s_dict, prototype);
	Dictionaries::write_value(compiled_i6s_dict, prototype, (void *) result);

	return result;
}

@h Heads and tails.
Most inline-defined phrases compile to a single schema, but some compile to
two, the head and the tail (which typically bookend a loop structure). A
general inline definition must therefore in principle be compiled to two
schemas, not one.

The definition is in a wide C string because it's coming raw from the lexer,
as the content of a |(- ... -)| lexeme, but with the |(-| and |-)| removed.

=
void InterSchemas::from_inline_phrase_definition(wchar_t *p, inter_schema **head, inter_schema **tail) {
	*head = NULL; *tail = NULL;

	text_stream *head_defn = Str::new();
	text_stream *tail_defn = Str::new();
	@<Fetch the head and tail definitions@>;

	*head = InterSchemas::from_text(head_defn, FALSE, 0, NULL);
	if (Str::len(tail_defn) > 0)
		*tail = InterSchemas::from_text(tail_defn, FALSE, 0, NULL);
}

@ A tail will only be present if the definition contains |{-block}|. If it
does, we then split the definition into a head and a tail, and again trim
white space from each. Note that |{-block}| is not legal anywhere else.

For example:

>> To repeat with a King's Court begin -- end loop:

could be given the definition:

	|@push {-my:trcount};|
	|for (trcount=1; trcount<=3; trcount++)|
	|    {-block}|
	|@pull trcount;|

This then repeats what it's given three times, while guaranteeing that the
counter is always a local variable called |trcount|, and that no matter how
such operations are nested, they will work. We might then write:

	|To say iteration: (- print {-my:trcount}; -).|

and then this will work as might be hoped:

	|repeat with a King's Court:|
	|    say "[iteration]...";|
	|        repeat with a King's Court:|
	|            say "[iteration]. You play a Shanty Town, getting +2 Actions.";|

This is a slightly contrived example, and often |{-block}| isn't needed. If
we didn't care about accessing the iteration count in the body of the loop,
for instance, we could simply have defined:

	|for ({-my:1}=1; {-my:1}<=3; {-my:1}++)|

and Inform would then have allocated a new variable as loop counter each time.

@<Fetch the head and tail definitions@> =
	while (Characters::is_whitespace(*p)) p++;
	WRITE_TO(head_defn, "%w", p);
	int effective_end = 0;
	for (int i=0, L=Str::len(head_defn); i<L; i++)
		if (!(Characters::is_whitespace(Str::get_at(head_defn, i))))
			effective_end = i+1;
	Str::truncate(head_defn, effective_end);

	for (int i=0, L=Str::len(head_defn); i<L; i++)
		if (Str::includes_wide_string_at(head_defn, L"{-block}", i)) {
			int after = i+8, before = i;
			while (Characters::is_whitespace(Str::get_at(head_defn, after))) after++;
			while (Characters::is_whitespace(Str::get_at(head_defn, before-1))) before--;
			Str::copy_tail(tail_defn, head_defn, after);
			Str::truncate(head_defn, before);
			break;
		}

@h Compiler.
This is a two-stage process.

=
inter_schema *InterSchemas::from_text(text_stream *from, int abbreviated, int no_quoted_inames, void **quoted_inames) {
	inter_schema *sch = InterSchemas::new(from);

	if ((Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) ||
		(Log::aspect_switched_on(SCHEMA_COMPILATION_DETAILS_DA)))
		LOG("\n\n------------\nCompiling inter schema from: <%S>\n", from);

	@<Begin the schema as a single expression node with a linked list of tokens@>;
	@<Perform transformations to grow the tree and reduce the token count@>;

	InterSchemas::lint(sch);

	if ((Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) ||
		(Log::aspect_switched_on(SCHEMA_COMPILATION_DETAILS_DA)))
		LOG("Completed inter schema:\n$1", sch);
	return sch;
}

@h Stage 1.
Our method is to tokenise the source code as if it were Inform 6, but to look
out for the two extra syntaxes allowed, |{-bracing}| and |(+ Inform 7 interpolation +)|.

@e NO_TOKSTATE from 1
@e COMMENT_TOKSTATE			/* currently scanning an I6 comment |! ...| */
@e DQUOTED_TOKSTATE
@e SQUOTED_TOKSTATE
@e WHITE_TOKSTATE
@e TOK_TOKSTATE				/* an actual token */

@<Begin the schema as a single expression node with a linked list of tokens@> =
	inter_schema_token *preceding_token = NULL;

	int definition_length = Str::len(from);
	text_stream *current_raw = Str::new();
	int tokeniser_state = NO_TOKSTATE;
	int pos = 0;
	if ((abbreviated) && (Str::begins_with_wide_string(from, L"*=-"))) {
		sch->dereference_mode = TRUE; pos = 3;
	}
	for (; pos<definition_length; pos++) {
		int c = Str::get_at(from, pos);
		if (Characters::is_whitespace(c)) {
			if ((tokeniser_state == TOK_TOKSTATE) || (tokeniser_state == NO_TOKSTATE)) {
				@<Absorb raw material, if any@>;
				tokeniser_state = WHITE_TOKSTATE;
				PUT_TO(current_raw, ' ');
			}
		} else {
			if (tokeniser_state == WHITE_TOKSTATE) {
				@<Absorb raw material, if any@>;
				tokeniser_state = NO_TOKSTATE;
			}
		}

		switch (tokeniser_state) {
			 case DQUOTED_TOKSTATE:
			 	if (c == '"') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 case SQUOTED_TOKSTATE:
			 	if (c == '\'') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 case COMMENT_TOKSTATE:
			 	if (c == '\n') tokeniser_state = NO_TOKSTATE;
			 	break;
			 case WHITE_TOKSTATE: break;
			 default:
			 	if (c == '!') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = COMMENT_TOKSTATE; break;
			 	}
			 	if (c == '"') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = DQUOTED_TOKSTATE; break;
			 	}
			 	if (c == '\'') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = SQUOTED_TOKSTATE; break;
			 	}
				if ((c == '{') && (abbreviated == FALSE))
					@<Look for a possible bracing@>
				else if ((c == '*') && (abbreviated == TRUE))
					@<Look for a possible abbreviated command@>
				else if ((c == '(') && (Str::get_at(from, pos+1) == '+') && (abbreviated == FALSE))
					@<Look for a possible Inform 7 fragment@>
				else @<Absorb a raw character@>;
				break;
		}
	}
	@<Absorb raw material, if any@>;

@<Absorb a raw character@> =
	tokeniser_state = TOK_TOKSTATE;
	PUT_TO(current_raw, c);

@<Absorb raw material, if any@> =
	if (Str::len(current_raw)) {
		switch (tokeniser_state) {
			case WHITE_TOKSTATE:
				InterSchemas::add_token(sch, InterSchemas::new_token(WHITE_SPACE_ISTT, I" ", NULL, 0, -1));
				break;
			case DQUOTED_TOKSTATE:
				InterSchemas::de_escape_text(current_raw);
				InterSchemas::add_token(sch, InterSchemas::new_token(DQUOTED_ISTT, current_raw, NULL, 0, -1));
				break;
			case SQUOTED_TOKSTATE:
				InterSchemas::add_token(sch, InterSchemas::new_token(SQUOTED_ISTT, current_raw, NULL, 0, -1));
				break;
			default:
				@<Look for individual tokens@>;
				break;
		}
		Str::clear(current_raw);
	}
	tokeniser_state = NO_TOKSTATE;

@ Material in |(+ ... +)| notation is an interpolation of I7 source text.

@<Look for a possible Inform 7 fragment@> =
	int save_pos = pos, accept = FALSE;
	TEMPORARY_TEXT(source_text_fragment);
	pos += 2;
	while (Str::get_at(from, pos)) {
		if ((Str::get_at(from, pos-1) == '+') && (Str::get_at(from, pos) == ')')) {
			Str::delete_last_character(source_text_fragment);
			accept = TRUE; break;
		}
		PUT_TO(source_text_fragment, Str::get_at(from, pos++));
	}
	if (accept) {
		@<Absorb raw material, if any@>;
		@<Expand a fragment of Inform 7 text@>;
	} else { int c = '('; @<Absorb a raw character@>; pos = save_pos; }
	DISCARD_TEXT(source_text_fragment);

@ The empty I7 interpolation is legal, but produces no result.

@<Expand a fragment of Inform 7 text@> =
	if (Str::len(source_text_fragment) > 0) {
		InterSchemas::add_token(sch, InterSchemas::new_token(I7_ISTT, source_text_fragment, NULL, 0, -1));
	}

@ Material in braces sometimes indicates an inline command, but not always,
because braces often occur innocently in I6 code. So we require the first
character after the open-brace not to be white-space, and also not to be
a pipe (though I've forgotten why). The text inside the braces is called
a "bracing".

@<Look for a possible bracing@> =
	int save_pos = pos++, accept = FALSE;
	TEMPORARY_TEXT(bracing);
	while (TRUE) {
		int c = Str::get_at(from, pos);
		if (c == 0) break;
		if (c == '}') { accept = TRUE; break; }
		PUT_TO(bracing, c);
		pos++;
	}
	int first = Str::get_first_char(bracing);
	if ((accept) && (first != ' ') && (first != '\t') && (first != '\n') && (first != '|')) {
		@<Absorb raw material, if any@>;
		@<Parse a bracing into an inline command@>;
	} else { int c = '{'; @<Absorb a raw character@>; pos = save_pos; }
	DISCARD_TEXT(bracing);

@ That's everything, then, except the one thing that counts: how to expand
a bracing.

@<Parse a bracing into an inline command@> =
	inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, bracing, NULL, 0, -1);
	t->bracing = Str::duplicate(bracing);
	t->command = Str::new();
	t->operand = Str::new();
	t->operand2 = Str::new();
	@<Decompose the bracing@>;
	if (Str::len(t->command) > 0) {
		if (Str::eq_wide_string(t->command, L"primitive-definition")) {
			t->inline_command = primitive_definition_ISINC;
			if (Str::eq_wide_string(t->operand, L"repeat-through")) t->inline_subcommand = repeat_through_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"repeat-through-list")) t->inline_subcommand = repeat_through_list_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"number-of")) t->inline_subcommand = number_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"random-of")) t->inline_subcommand = random_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"total-of")) t->inline_subcommand = total_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"extremal")) t->inline_subcommand = extremal_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"function-application")) t->inline_subcommand = function_application_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"description-application")) t->inline_subcommand = description_application_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"solve-equation")) t->inline_subcommand = solve_equation_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"switch")) t->inline_subcommand = switch_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"break")) t->inline_subcommand = break_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"verbose-checking")) t->inline_subcommand = verbose_checking_ISINSC;
		} else if (Str::eq_wide_string(t->command, L"new")) t->inline_command = new_ISINC;
		else if (Str::eq_wide_string(t->command, L"new-list-of")) t->inline_command = new_list_of_ISINC;
		else if (Str::eq_wide_string(t->command, L"printing-routine")) t->inline_command = printing_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"ranger-routine")) t->inline_command = ranger_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"next-routine")) t->inline_command = next_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"previous-routine")) t->inline_command = previous_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"strong-kind")) t->inline_command = strong_kind_ISINC;
		else if (Str::eq_wide_string(t->command, L"weak-kind")) t->inline_command = weak_kind_ISINC;
		else if (Str::eq_wide_string(t->command, L"backspace")) t->inline_command = backspace_ISINC;
		else if (Str::eq_wide_string(t->command, L"erase")) t->inline_command = erase_ISINC;
		else if (Str::eq_wide_string(t->command, L"open-brace")) t->inline_command = open_brace_ISINC;
		else if (Str::eq_wide_string(t->command, L"close-brace")) t->inline_command = close_brace_ISINC;
		else if (Str::eq_wide_string(t->command, L"label")) t->inline_command = label_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter")) t->inline_command = counter_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-storage")) t->inline_command = counter_storage_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-up")) t->inline_command = counter_up_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-down")) t->inline_command = counter_down_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-makes-array")) t->inline_command = counter_makes_array_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-reference")) t->inline_command = by_reference_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-reference-blank-out")) t->inline_command = by_reference_blank_out_ISINC;
		else if (Str::eq_wide_string(t->command, L"reference-exists")) t->inline_command = reference_exists_ISINC;
		else if (Str::eq_wide_string(t->command, L"lvalue-by-reference")) t->inline_command = lvalue_by_reference_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-value")) t->inline_command = by_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"box-quotation-text")) t->inline_command = box_quotation_text_ISINC;
		else if (Str::eq_wide_string(t->command, L"try-action")) t->inline_command = try_action_ISINC;
		else if (Str::eq_wide_string(t->command, L"try-action-silently")) t->inline_command = try_action_silently_ISINC;
		else if (Str::eq_wide_string(t->command, L"return-value")) t->inline_command = return_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"return-value-from-rule")) t->inline_command = return_value_from_rule_ISINC;
		else if (Str::eq_wide_string(t->command, L"property-holds-block-value")) t->inline_command = property_holds_block_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"mark-event-used")) t->inline_command = mark_event_used_ISINC;
		else if (Str::eq_wide_string(t->command, L"my")) t->inline_command = my_ISINC;
		else if (Str::eq_wide_string(t->command, L"unprotect")) t->inline_command = unprotect_ISINC;
		else if (Str::eq_wide_string(t->command, L"copy")) t->inline_command = copy_ISINC;
		else if (Str::eq_wide_string(t->command, L"initialise")) t->inline_command = initialise_ISINC;
		else if (Str::eq_wide_string(t->command, L"matches-description")) t->inline_command = matches_description_ISINC;
		else if (Str::eq_wide_string(t->command, L"now-matches-description")) t->inline_command = now_matches_description_ISINC;
		else if (Str::eq_wide_string(t->command, L"arithmetic-operation")) t->inline_command = arithmetic_operation_ISINC;
		else if (Str::eq_wide_string(t->command, L"say")) t->inline_command = say_ISINC;
		else if (Str::eq_wide_string(t->command, L"show-me")) t->inline_command = show_me_ISINC;
		else if (Str::eq_wide_string(t->command, L"segment-count")) t->inline_command = segment_count_ISINC;
		else if (Str::eq_wide_string(t->command, L"final-segment-marker")) t->inline_command = final_segment_marker_ISINC;
		else if (Str::eq_wide_string(t->command, L"list-together")) {
			t->inline_command = list_together_ISINC;
			if (Str::eq_wide_string(t->operand, L"unarticled")) t->inline_subcommand = unarticled_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"articled")) t->inline_subcommand = articled_ISINSC;
		} else if (Str::eq_wide_string(t->command, L"rescale")) t->inline_command = rescale_ISINC;
		else t->inline_command = unknown_ISINC;
	}

	InterSchemas::add_token(sch, t);
	preceding_token = t;

@ A bracing can take any of the following forms:

	|{-command}|
	|{-command:operand}|
	|{-command:operand:operand2}|
	|{-command:operand<property name}|
	|{-command:operand>property name}|
	|{some text}|
	|{-annotation:some text}|

We parse this with the command or annotation in |command|, the "some text"
or operand in |bracing|, the property name (if given) in |extremal_property|,
the direction of the |<| or |>| in |extremal_property_sign|, and the second,
optional, operand in |operand2|.

@<Decompose the bracing@> =
	TEMPORARY_TEXT(pname);
	if (Str::get_first_char(t->bracing) == '-') {
		int portion = 1;
		for (int i=1, L = Str::len(t->bracing); i<L; i++) {
			int c = Str::get_at(t->bracing, i);
			switch(portion) {
				case 1:
					if (c == ':') portion = 2;
					else PUT_TO(t->command, c);
					break;
				case 2:
					if (c == ':') portion = 3;
					#ifdef CORE_MODULE
					else if (c == '<') { t->extremal_property_sign = MEASURE_T_OR_LESS; portion = 4; }
					else if (c == '>') { t->extremal_property_sign = MEASURE_T_OR_MORE; portion = 4; }
					#endif
					else PUT_TO(t->operand, c);
					break;
				case 3:
					PUT_TO(t->operand2, c); break;
				case 4:
					PUT_TO(pname, c); break;
			}
		}
		#ifdef CORE_MODULE
		if (t->extremal_property_sign != MEASURE_T_EXACTLY) {
			wording W = Feeds::feed_stream(pname);
			if (<property-name>(W)) t->extremal_property = <<rp>>;
		}
		#endif
		Str::copy(t->bracing, t->operand);
	}
	DISCARD_TEXT(pname);

@ In abbreviated prototypes, |*1| and |*2| are placeholders.

@d GIVE_KIND_ID_ISSBM					1
@d GIVE_COMPARISON_ROUTINE_ISSBM		2
@d DEREFERENCE_PROPERTY_ISSBM			4
@d ADOPT_LOCAL_STACK_FRAME_ISSBM		8
@d CAST_TO_KIND_OF_OTHER_TERM_ISSBM		16
@d BY_REFERENCE_ISSBM					32
@d PERMIT_LOCALS_IN_TEXT_CMODE_ISSBM	64
@d TREAT_AS_LVALUE_CMODE_ISSBM			128
@d JUST_ROUTINE_CMODE_ISSBM				256
@d TABLE_EXISTENCE_CMODE_ISSBM			512

@<Look for a possible abbreviated command@> =
	int at = pos;
	int c = Str::get_at(from, ++at);
	int iss_bitmap = 0;
	switch (c) {
		case '!': iss_bitmap = iss_bitmap | PERMIT_LOCALS_IN_TEXT_CMODE_ISSBM; c = Str::get_at(from, ++at); break;
		case '%': iss_bitmap = iss_bitmap | TREAT_AS_LVALUE_CMODE_ISSBM; c = Str::get_at(from, ++at); break;
		case '$': iss_bitmap = iss_bitmap | JUST_ROUTINE_CMODE_ISSBM; c = Str::get_at(from, ++at); break;
		case '#': iss_bitmap = iss_bitmap | GIVE_KIND_ID_ISSBM; c = Str::get_at(from, ++at); break;
		case '_': iss_bitmap = iss_bitmap | GIVE_COMPARISON_ROUTINE_ISSBM; c = Str::get_at(from, ++at); break;
		case '+': iss_bitmap = iss_bitmap | DEREFERENCE_PROPERTY_ISSBM; c = Str::get_at(from, ++at); break;
		case '|': iss_bitmap = iss_bitmap | (DEREFERENCE_PROPERTY_ISSBM + TREAT_AS_LVALUE_CMODE_ISSBM); c = Str::get_at(from, ++at); break;
		case '?': iss_bitmap = iss_bitmap | ADOPT_LOCAL_STACK_FRAME_ISSBM; c = Str::get_at(from, ++at); break;
		case '<': iss_bitmap = iss_bitmap | CAST_TO_KIND_OF_OTHER_TERM_ISSBM; c = Str::get_at(from, ++at); break;
		case '^': iss_bitmap = iss_bitmap | (ADOPT_LOCAL_STACK_FRAME_ISSBM + BY_REFERENCE_ISSBM); c = Str::get_at(from, ++at); break;
		case '>': iss_bitmap = iss_bitmap | BY_REFERENCE_ISSBM; c = Str::get_at(from, ++at); break;
	}
	if (Characters::isdigit(c)) {
		@<Absorb raw material, if any@>;
		TEMPORARY_TEXT(T);
		for (int i=pos; i<=at; i++) PUT_TO(T, Str::get_at(from, i));
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, T, NULL, 0, -1);
		t->bracing = Str::duplicate(T);
		t->inline_command = substitute_ISINC;
		t->inline_modifiers = iss_bitmap;
		t->constant_number = c - '1';
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		DISCARD_TEXT(T);
		pos = at;
	} else if (c == '?') {
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, I"*?", NULL, 0, -1);
		t->bracing = I"*?";
		t->inline_command = current_sentence_ISINC;
		t->inline_modifiers = iss_bitmap;
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		pos = at;
	} else if (c == '&') {
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, I"*&", NULL, 0, -1);
		t->bracing = I"*&";
		t->inline_command = combine_ISINC;
		t->inline_modifiers = iss_bitmap;
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		pos = at;
	} else if (c == '-') {
		internal_error("the '*-' schema notation has been abolished");
	} else if (c == '*') {
		int c = '*'; @<Absorb a raw character@>;
		pos = at;
	} else {
		int c = '{'; @<Absorb a raw character@>;
	}

@ That leaves us with just the main case to handle: raw I6 code which is
outside of quotation marks and commentary, and which doesn't include
bracings or I7 interpolations. That might look like, for instance,

	|Frog + 2*Toad(|

(there is no reason to suppose that this stretch of code is complete or
matches parentheses); we must tokenise it into

	|Frog| |W| |+| |W| |2| |*| |Toad| |(|

where |W| indicates a white space token. What we do is scan through the
text until we reach the start of a new token, and then break off what we
scanned through since the last time.

@<Look for individual tokens@> =
	int L = Str::len(current_raw);
	int c_start = 0, escaped = FALSE;
	for (int p = 0; p < L; p++) {
		int c1 = Str::get_at(current_raw, p), c2 = 0, c3 = 0;
		if (p < L-1) c2 = Str::get_at(current_raw, p+1);
		if (p < L-2) c3 = Str::get_at(current_raw, p+2);

		if (escaped == FALSE) {
			if ((c1 == '$') && ((p == 0) || (Characters::isalpha(Str::get_at(current_raw, p-1)) == FALSE)))
				@<Break off here for real, binary or hexadecimal notation@>;
			if (c1 == '-') @<Break off here for negative number@>;
			@<Break off here for operators@>;
		}
		if (c1 == 0x00A7) escaped = escaped?FALSE:TRUE;
	}
	if (c_start < L) {
		int x = c_start, y = L-1;
		@<Break off a token@>;
	}

@ Recall that in I6 notation, a dollar introduces a non-decimal number, and
the character after the initial dollar determines which:

	|$+3.14159E2|
	|$$1001001|
	|$1FE6|

@<Break off here for real, binary or hexadecimal notation@> =
	int x = c_start, y = p-1;
	@<Break off a token@>;
	switch (c2) {
		case '+': case '-':
			x = p; y = p+1;
			while ((Str::get_at(current_raw, y+1) == '.') ||
					(Str::get_at(current_raw, y+1) == 'E') ||
					(Str::get_at(current_raw, y+1) == 'e') ||
					(Characters::isdigit(Str::get_at(current_raw, y+1))))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		case '$':
			x = p; y = p+1;
			while ((Str::get_at(current_raw, y+1) == '0') ||
					(Str::get_at(current_raw, y+1) == '1'))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		default:
			x = p; y = p;
			while (Characters::isalnum(Str::get_at(current_raw, y+1)))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
	}

@ A token beginning with a minus sign and continuing with digits may still
not be a negative number: it may be the binary subtraction operator.
For example, we need to tokenise |x-1| as

	|x| |-| |1|

and not as

	|x| |-1|

This requires context, that is, remembering what the previous token was.

@<Break off here for negative number@> =
	if (((preceding_token == NULL) ||
		(preceding_token->ist_type == OPEN_ROUND_ISTT) ||
		(preceding_token->ist_type == OPERATOR_ISTT) ||
		(preceding_token->ist_type == DIVIDER_ISTT)) &&
		(c_start == p) &&
		(!((abbreviated) && (preceding_token->ist_type == INLINE_ISTT)))) {
// LOG("Spec nn cs %d p %d\n", c_start, p);
		int dc = p+1;
		while (Characters::isdigit(Str::get_at(current_raw, dc))) dc++;
		if (dc > p+1) {
			int x = c_start, y = p-1;
			@<Break off a token@>;
			x = p; y = dc - 1;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		}
	}

@ In I6, operators made of non-alphanumeric characters can be up to three
characters long, and we take the longest match: thus |-->| is a trigraph,
not the monograph |-| followed by the digraph |->|.

We treat the |@| sign as if it were alphanumeric for the sake of assembly
language opcodes such as |@pull|.

@<Break off here for operators@> =
	int monograph = TRUE, digraph = FALSE, trigraph = FALSE;
	if ((Characters::isalnum(c1)) || (c1 == '_') || (c1 == '$')) monograph = FALSE;
	if (c1 == 0x00A7) monograph = FALSE;
	if ((c1 == '#') && (Characters::isalpha(c2))) monograph = FALSE;
	if ((c1 == '_') && (Characters::isalpha(c2))) monograph = FALSE;
	if ((c1 == '#') && (c2 == '#') && (Characters::isalpha(c3))) monograph = FALSE;
	if ((c1 == '@') && (Characters::isalpha(c2))) monograph = FALSE;

	if ((c1 == '+') && (c2 == '+')) digraph = TRUE;
	if ((c1 == '-') && (c2 == '-')) digraph = TRUE;
	if ((c1 == '>') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '<') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '=') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '-') && (c2 == '>')) digraph = TRUE;
	if ((c1 == '.') && (c2 == '&')) digraph = TRUE;
	if ((c1 == '.') && (c2 == '#')) digraph = TRUE;
	if ((c1 == '~') && (c2 == '~')) digraph = TRUE;
	if ((c1 == '~') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '&') && (c2 == '&')) digraph = TRUE;
	if ((c1 == '|') && (c2 == '|')) digraph = TRUE;

	if ((c1 == '-') && (c2 == '-') && (c3 == '>')) trigraph = TRUE;

	if (trigraph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p+2;
		@<Break off a token@>;
		p += 2;
		c_start = p+1;
		continue;
	}

	if (digraph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p+1;
		@<Break off a token@>;
		p++;
		c_start = p+1;
		continue;
	}

	if (monograph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p;
		@<Break off a token@>;
		c_start = p+1;
		continue;
	}

@ In this code, the new token is between character positions |x| and |y|
inclusive; we ignore an empty token.

@<Break off a token@> =
	if (y >= x) {
		TEMPORARY_TEXT(T);
		for (int i = x; i <= y; i++) PUT_TO(T, Str::get_at(current_raw, i));

		int is = RAW_ISTT;
		inter_symbol *which = NULL;
		int which_rw = 0, which_number = -1, which_quote = -1;
		@<Identify this new token@>;

		inter_schema_token *n = InterSchemas::new_token(is, T, which, which_rw, which_number);
		#ifdef CORE_MODULE
		if (which_quote >= 0) n->as_quoted = quoted_inames[which_quote];
		#endif
		InterSchemas::add_token(sch, n);
		if (n->ist_type != WHITE_SPACE_ISTT) preceding_token = n;
		DISCARD_TEXT(T);
	}

@ Finally, we identify what sort of token we're looking at.

@<Identify this new token@> =
	if (Str::get_at(T, 0) == '@') is = OPCODE_ISTT;
	if (Str::get_at(T, 0) == 0x00A7)
		is = IDENTIFIER_ISTT;
	if ((Str::get_at(T, 0) == '#') && (Str::get_at(T, 1) == '#') && (Characters::isalpha(Str::get_at(T, 2)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			int c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '#') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			int c = Str::get(P);
			if ((c != '_') && (c != '#') && (c != '$') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '_') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			int c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if (Characters::isalpha(Str::get_at(T, 0))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			int c = Str::get(P);
			if ((c != '_') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
		if (Str::begins_with_wide_string(T, L"QUOTED_INAME_0_")) which_quote = 0;
		else if (Str::begins_with_wide_string(T, L"QUOTED_INAME_1_")) which_quote = 1;
		if (Str::eq(T, I"I7_string")) { Str::clear(T); WRITE_TO(T, "I7_String"); }
		if (Str::eq(T, I"COMMA_WORD")) { Str::clear(T); WRITE_TO(T, "comma_word"); }
	}
	if (Characters::isdigit(Str::get_at(T, 0))) {
		is = NUMBER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			int c = Str::get(P);
			if (!Characters::isdigit(c))
				is = RAW_ISTT;
		}
	}
	if (Str::get_at(T, 0) == '$') {
		is = HEX_NUMBER_ISTT;
		wchar_t c = Str::get_at(T, 1);
		if (c == '$') is = BIN_NUMBER_ISTT;
		if (c == '+') is = REAL_NUMBER_ISTT;
		if (c == '-') is = REAL_NUMBER_ISTT;
	}
	if (Str::get_at(T, 0) == '-') is = NUMBER_ISTT;

	if (Str::eq(T, I"false")) { is = NUMBER_ISTT; which_number = 0; }
	if (Str::eq(T, I"true")) { is = NUMBER_ISTT; which_number = 1; }
	if (Str::eq(T, I"nothing")) { is = NUMBER_ISTT; which_number = 0; }

	if (Str::eq(T, I"if")) { is = RESERVED_ISTT; which_rw = IF_I6RW; }
	if (Str::eq(T, I"else")) { is = RESERVED_ISTT; which_rw = ELSE_I6RW; }
	if (Str::eq(T, I"style")) { is = RESERVED_ISTT; which_rw = STYLE_I6RW; }
	if (Str::eq(T, I"return")) { is = RESERVED_ISTT; which_rw = RETURN_I6RW; }
	if (Str::eq(T, I"rtrue")) { is = RESERVED_ISTT; which_rw = RTRUE_I6RW; }
	if (Str::eq(T, I"rfalse")) { is = RESERVED_ISTT; which_rw = RFALSE_I6RW; }
	if (Str::eq(T, I"for")) { is = RESERVED_ISTT; which_rw = FOR_I6RW; }
	if (Str::eq(T, I"objectloop")) { is = RESERVED_ISTT; which_rw = OBJECTLOOP_I6RW; }
	if (Str::eq(T, I"while")) { is = RESERVED_ISTT; which_rw = WHILE_I6RW; }
	if (Str::eq(T, I"do")) { is = RESERVED_ISTT; which_rw = DO_I6RW; }
	if (Str::eq(T, I"until")) { is = RESERVED_ISTT; which_rw = UNTIL_I6RW; }
	if (Str::eq(T, I"print")) { is = RESERVED_ISTT; which_rw = PRINT_I6RW; }
	if (Str::eq(T, I"print_ret")) { is = RESERVED_ISTT; which_rw = PRINTRET_I6RW; }
	if (Str::eq(T, I"new_line")) { is = RESERVED_ISTT; which_rw = NEWLINE_I6RW; }
	if (Str::eq(T, I"give")) { is = RESERVED_ISTT; which_rw = GIVE_I6RW; }
	if (Str::eq(T, I"move")) { is = RESERVED_ISTT; which_rw = MOVE_I6RW; }
	if (Str::eq(T, I"remove")) { is = RESERVED_ISTT; which_rw = REMOVE_I6RW; }
	if (Str::eq(T, I"jump")) { is = RESERVED_ISTT; which_rw = JUMP_I6RW; }
	if (Str::eq(T, I"switch")) { is = RESERVED_ISTT; which_rw = SWITCH_I6RW; }
	if (Str::eq(T, I"default")) { is = RESERVED_ISTT; which_rw = DEFAULT_I6RW; }
	if (Str::eq(T, I"font")) { is = RESERVED_ISTT; which_rw = FONT_I6RW; }
	if (Str::eq(T, I"continue")) { is = RESERVED_ISTT; which_rw = CONTINUE_I6RW; }
	if (Str::eq(T, I"break")) { is = RESERVED_ISTT; which_rw = BREAK_I6RW; }
	if (Str::eq(T, I"quit")) { is = RESERVED_ISTT; which_rw = QUIT_I6RW; }
	if (Str::eq(T, I"restore")) { is = RESERVED_ISTT; which_rw = RESTORE_I6RW; }
	if (Str::eq(T, I"spaces")) { is = RESERVED_ISTT; which_rw = SPACES_I6RW; }
	if (Str::eq(T, I"read")) { is = RESERVED_ISTT; which_rw = READ_I6RW; }
	if (Str::eq(T, I"inversion")) { is = RESERVED_ISTT; which_rw = INVERSION_I6RW; }

	if (Str::eq_insensitive(T, I"#IFDEF")) { is = DIRECTIVE_ISTT; which_rw = IFDEF_I6RW; }
	if (Str::eq_insensitive(T, I"#IFNDEF")) { is = DIRECTIVE_ISTT; which_rw = IFNDEF_I6RW; }
	if (Str::eq_insensitive(T, I"#IFTRUE")) { is = DIRECTIVE_ISTT; which_rw = IFTRUE_I6RW; }
	if (Str::eq_insensitive(T, I"#IFFALSE")) { is = DIRECTIVE_ISTT; which_rw = IFFALSE_I6RW; }
	if (Str::eq_insensitive(T, I"#IFNOT")) { is = DIRECTIVE_ISTT; which_rw = IFNOT_I6RW; }
	if (Str::eq_insensitive(T, I"#ENDIF")) { is = DIRECTIVE_ISTT; which_rw = ENDIF_I6RW; }

	if (Str::eq(T, I",")) is = COMMA_ISTT;
	if (Str::eq(T, I":")) is = COLON_ISTT;
	if (Str::eq(T, I"(")) is = OPEN_ROUND_ISTT;
	if (Str::eq(T, I")")) is = CLOSE_ROUND_ISTT;
	if (Str::eq(T, I"{")) is = OPEN_BRACE_ISTT;
	if (Str::eq(T, I"}")) is = CLOSE_BRACE_ISTT;
	if (Str::eq(T, I";")) is = DIVIDER_ISTT;

	if (Str::eq(T, I".")) { is = OPERATOR_ISTT; which = propertyvalue_interp; }
	if (Str::eq(T, I".&")) { is = OPERATOR_ISTT; which = propertyaddress_interp; }
	if (Str::eq(T, I".#")) { is = OPERATOR_ISTT; which = propertylength_interp; }

	if (Str::eq(T, I"=")) { is = OPERATOR_ISTT; which = store_interp; }

	if (Str::eq(T, I"+")) { is = OPERATOR_ISTT; which = plus_interp; }
	if (Str::eq(T, I"-")) { is = OPERATOR_ISTT; which = minus_interp; }
	if (Str::eq(T, I"*")) { is = OPERATOR_ISTT; which = times_interp; }
	if (Str::eq(T, I"/")) { is = OPERATOR_ISTT; which = divide_interp; }
	if (Str::eq(T, I"%")) { is = OPERATOR_ISTT; which = modulo_interp; }

	if (Str::eq(T, I">")) { is = OPERATOR_ISTT; which = gt_interp; }
	if (Str::eq(T, I">=")) { is = OPERATOR_ISTT; which = ge_interp; }
	if (Str::eq(T, I"<")) { is = OPERATOR_ISTT; which = lt_interp; }
	if (Str::eq(T, I"<=")) { is = OPERATOR_ISTT; which = le_interp; }
	if (Str::eq(T, I"==")) { is = OPERATOR_ISTT; which = eq_interp; }
	if (Str::eq(T, I"~=")) { is = OPERATOR_ISTT; which = ne_interp; }

	if (Str::eq(T, I"~~")) { is = OPERATOR_ISTT; which = not_interp; }
	if (Str::eq(T, I"&&")) { is = OPERATOR_ISTT; which = and_interp; }
	if (Str::eq(T, I"||")) { is = OPERATOR_ISTT; which = or_interp; }
	if (Str::eq(T, I"or")) { is = OPERATOR_ISTT; which = alternative_interp; }

	if (Str::eq(T, I"ofclass")) { is = OPERATOR_ISTT; which = ofclass_interp; }
	if (Str::eq(T, I"has")) { is = OPERATOR_ISTT; which = has_interp; }
	if (Str::eq(T, I"hasnt")) { is = OPERATOR_ISTT; which = hasnt_interp; }
	if (Str::eq(T, I"provides")) { is = OPERATOR_ISTT; which = provides_interp; }
	if (Str::eq(T, I"in")) { is = OPERATOR_ISTT; which = in_interp; }
	if (Str::eq(T, I"notin")) { is = OPERATOR_ISTT; which = notin_interp; }

	if (Str::eq(T, I"|")) { is = OPERATOR_ISTT; which = bitwiseor_interp; }
	if (Str::eq(T, I"&")) { is = OPERATOR_ISTT; which = bitwiseand_interp; }
	if (Str::eq(T, I"~")) { is = OPERATOR_ISTT; which = bitwisenot_interp; }

	if (Str::eq(T, I"++")) { is = OPERATOR_ISTT; which = postincrement_interp; }
	if (Str::eq(T, I"--")) { is = OPERATOR_ISTT; which = postdecrement_interp; }

	if (Str::eq(T, I"->")) { is = OPERATOR_ISTT; which = lookupbyte_interp; }
	if (Str::eq(T, I"-->")) { is = OPERATOR_ISTT; which = lookup_interp; }

@h Stage 2.
In the second half of the process, we apply a series of transformations to
the schema tree, gradually shaking out the (sometimes ambiguous) syntactic
markers such as |COMMA_ISTT| and replacing them with semantically clear
subtrees.

Each transformation will be applied until it returns |FALSE| to say that
it could see nothing to do, or |NOT_APPLICABLE| to say that it did but
that it doesn't want to be called again. Some transformations make use
of temporary markers attached to nodes or tokens in the tree, so we clear
these out at the start of each iteration.

@d REPEATEDLY_APPLY(X)
	{
		InterSchemas::unmark(sch->node_tree);
		while (TRUE) {
			int rv = X(NULL, sch->node_tree);
			if (rv == FALSE) break;
			LOGIF(SCHEMA_COMPILATION_DETAILS, "After round of " #X ":\n$1\n", sch);
			if (rv == NOT_APPLICABLE) break;
		}
	}

=
void InterSchemas::unmark(inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		isn->node_marked = FALSE;
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			t->preinsert = 0;
			t->postinsert = 0;
		}
		InterSchemas::unmark(isn->child_node);
	}
}

@ With that mechanism in place, we can do the business:

@<Perform transformations to grow the tree and reduce the token count@> =
	REPEATEDLY_APPLY(InterSchemas::implied_braces);
	REPEATEDLY_APPLY(InterSchemas::unbrace_schema);
	REPEATEDLY_APPLY(InterSchemas::divide_schema);
	REPEATEDLY_APPLY(InterSchemas::undivide_schema);
	REPEATEDLY_APPLY(InterSchemas::resolve_halfopen_blocks);
	REPEATEDLY_APPLY(InterSchemas::break_early_bracings);
	REPEATEDLY_APPLY(InterSchemas::strip_spacing);
	REPEATEDLY_APPLY(InterSchemas::splitprints);
	REPEATEDLY_APPLY(InterSchemas::splitcases);
	REPEATEDLY_APPLY(InterSchemas::strip_spacing);
	REPEATEDLY_APPLY(InterSchemas::splitprints);
	REPEATEDLY_APPLY(InterSchemas::identify_constructs);
	REPEATEDLY_APPLY(InterSchemas::treat_constructs);
	REPEATEDLY_APPLY(InterSchemas::add_missing_bodies);
	REPEATEDLY_APPLY(InterSchemas::remove_empties);
	REPEATEDLY_APPLY(InterSchemas::outer_subexpressions);
	REPEATEDLY_APPLY(InterSchemas::top_level_commas);
	REPEATEDLY_APPLY(InterSchemas::alternatecases);
	REPEATEDLY_APPLY(InterSchemas::outer_subexpressions);
	REPEATEDLY_APPLY(InterSchemas::strip_all_spacing);
	REPEATEDLY_APPLY(InterSchemas::debracket);
	REPEATEDLY_APPLY(InterSchemas::implied_return_values);
	REPEATEDLY_APPLY(InterSchemas::message_calls);

@ =
int InterSchemas::implied_braces(inter_schema_node *par, inter_schema_node *at) {
	for (inter_schema_node *isn = at; isn; isn=isn->next_node) {
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			if ((t->ist_type == RESERVED_ISTT) &&
				((t->reserved_word == IF_I6RW) ||
					(t->reserved_word == WHILE_I6RW) ||
					(t->reserved_word == FOR_I6RW) ||
					(t->reserved_word == SWITCH_I6RW) ||
					(t->reserved_word == OBJECTLOOP_I6RW))) {
				inter_schema_token *n = t->next;
				int bl = 0;
				while (n) {
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) { n = n->next; break; }
					}
					n = n->next;
				}
				if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				if ((n) && (n->ist_type != OPEN_BRACE_ISTT))
					@<Make pre and post markers from here@>;
			}
			if ((t->ist_type == RESERVED_ISTT) &&
				(t->reserved_word == ELSE_I6RW)) {
				inter_schema_token *n = t->next;
				if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				if ((n) && (n->ist_type != OPEN_BRACE_ISTT))
					@<Make pre and post markers from here@>;
			}
		}
	}

	int changed = TRUE, rounds = 0;
	while (changed) {
		changed = FALSE; rounds++;
		for (inter_schema_node *isn = at; isn; isn=isn->next_node) {
			for (inter_schema_token *t = isn->expression_tokens, *prev = NULL; t; prev = t, t=t->next) {
				if ((prev) && (t->preinsert > 0)) {
					t->preinsert--;
					inter_schema_token *open_b =
						InterSchemas::new_token(OPEN_BRACE_ISTT, I"{", NULL, 0, -1);
					InterSchemas::add_token_after(open_b, prev);
					changed = TRUE;
				}
				if (t->postinsert > 0) {
					t->postinsert--;
					inter_schema_token *close_b =
						InterSchemas::new_token(CLOSE_BRACE_ISTT, I"}", NULL, 0, -1);
					InterSchemas::add_token_after(close_b, t);
					changed = TRUE;
				}
			}
		}
	}
	if (rounds > 1) return NOT_APPLICABLE;
	return FALSE;
}

@<Make pre and post markers from here@> =
	n->preinsert++;
	int found_if = FALSE, brl = 0, posted = FALSE, upped = FALSE;
	inter_schema_token *last_n = n;
	while (n) {
		if (n->ist_type == OPEN_BRACE_ISTT) { brl++; upped = TRUE; }
		if (n->ist_type == CLOSE_BRACE_ISTT) brl--;
		if (n->ist_type == OPEN_ROUND_ISTT) brl++;
		if (n->ist_type == CLOSE_ROUND_ISTT) brl--;
		if ((brl == 0) && (n->ist_type == RESERVED_ISTT) && (n->reserved_word == IF_I6RW))
			found_if = TRUE;
		if ((brl == 0) &&
			((n->ist_type == DIVIDER_ISTT) ||
				((upped) && (n->ist_type == CLOSE_BRACE_ISTT)))) {
			inter_schema_token *m = n->next;
			while ((m) && (m->ist_type == WHITE_SPACE_ISTT)) m = m->next;
			if ((found_if == FALSE) || (m == NULL) || (m->ist_type != RESERVED_ISTT) || (m->reserved_word != ELSE_I6RW)) {
				n->postinsert++; posted = TRUE;
				break;
			}
		}
		last_n = n;
		n = n->next;
	}
	if (posted == FALSE) {
		last_n->postinsert++;
	}

@ =
int InterSchemas::unbrace_schema(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		for (inter_schema_token *t = isn->expression_tokens, *prev = NULL; t; prev = t, t=t->next) {
			if ((prev) && (t->ist_type == OPEN_BRACE_ISTT)) {
				prev->next = NULL;
				inter_schema_node *code_isn = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
				isn->child_node = code_isn;
				code_isn->parent_node = isn;

				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				code_isn->child_node = new_isn;
				new_isn->parent_node = code_isn;

				prev = t; t = t->next;
				while ((t) && (t->ist_type == WHITE_SPACE_ISTT)) { prev = t; t = t->next; }

				new_isn->expression_tokens = t;
				inter_schema_token *n = new_isn->expression_tokens, *pn = NULL;
				int brl = 1;
				while (n) {
					if (n->ist_type == OPEN_BRACE_ISTT) brl++;
					if (n->ist_type == CLOSE_BRACE_ISTT) brl--;
					if (n->ist_type == OPEN_ROUND_ISTT) brl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) brl--;
					n->owner = new_isn;
					if (brl == 0) {
						if (pn == NULL) new_isn->expression_tokens = NULL;
						else pn->next = NULL;
						break;
					}
					pn = n; n = n->next;
				}
				if (n) {
					inter_schema_token *resumed = n->next;
					n->next = NULL;
					while ((resumed) && (resumed->ist_type == WHITE_SPACE_ISTT)) resumed = resumed->next;
					if (resumed) {
						inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = resumed;
						new_isn->parent_node = isn->parent_node;
						for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
							l->owner = new_isn;
						}
						inter_schema_node *saved = isn->next_node;
						isn->next_node = new_isn;
						new_isn->next_node = saved;
					}
				}
				return TRUE;
			}
		}
		if (InterSchemas::unbrace_schema(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::divide_schema(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		int bl = 0;
		for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
			if (t->ist_type == OPEN_ROUND_ISTT) bl++;
			if (t->ist_type == CLOSE_ROUND_ISTT) bl--;
			if ((bl == 0) && (t->ist_type == DIVIDER_ISTT) && (t->next)) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = t->next;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
					l->owner = new_isn;
				}
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				t->next = NULL;
				return TRUE;
			}
		}
		if (InterSchemas::divide_schema(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::undivide_schema(inter_schema_node *par, inter_schema_node *isn) {
	int rv = FALSE;
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		if ((t) && (t->ist_type == DIVIDER_ISTT)) {
			isn->expression_tokens = NULL;
			isn->semicolon_terminated = TRUE;
			rv = TRUE;
		} else {
			while ((t) && (t->next)) {
				if (t->next->ist_type == DIVIDER_ISTT) { t->next = NULL; isn->semicolon_terminated = TRUE; rv = TRUE; break; }
				t = t->next;
			}
		}
		if (InterSchemas::undivide_schema(isn, isn->child_node)) rv = TRUE;
	}
	return rv;
}

int InterSchemas::resolve_halfopen_blocks(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		while ((t) && (t->ist_type == WHITE_SPACE_ISTT)) t = t->next;
		if ((t) && (t->ist_type == INLINE_ISTT) && (t->inline_command == open_brace_ISINC)) {
			InterSchemas::mark_unclosed(isn);
			t->ist_type = WHITE_SPACE_ISTT;
			t->material = I" ";
			return TRUE;
		}
		if ((t) && (t->ist_type == INLINE_ISTT) && (t->inline_command == close_brace_ISINC)) {
			InterSchemas::mark_unopened(isn);
			t->ist_type = WHITE_SPACE_ISTT;
			t->material = I" ";
			if (t->next) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = t->next;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
					l->owner = new_isn;
				}
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				t->next = NULL;
			}
			return TRUE;
		}
		if (InterSchemas::resolve_halfopen_blocks(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::permitted_early(inter_schema_token *n) {
	if ((n) && (n->ist_type == INLINE_ISTT)) return TRUE;
	if ((n) && (n->ist_type == WHITE_SPACE_ISTT)) return TRUE;
	return FALSE;
}

int InterSchemas::break_early_bracings(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *n = isn->expression_tokens;
		if (n) {
			inter_schema_token *m = NULL;
			while (InterSchemas::permitted_early(n)) {
				m = n;
				n = n->next;
			}
			if ((m) && (n) && (n->ist_type == RESERVED_ISTT)) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				new_isn->expression_tokens = n;
				new_isn->parent_node = isn->parent_node;
				if (isn->child_node) {
					new_isn->child_node = isn->child_node;
					new_isn->child_node->parent_node = new_isn;
					isn->child_node = NULL;
				}
				for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
					l->owner = new_isn;
				}
				inter_schema_node *saved = isn->next_node;
				isn->next_node = new_isn;
				new_isn->next_node = saved;
				m->next = NULL;
				return TRUE;
			}
		}
		if (InterSchemas::break_early_bracings(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::strip_spacing(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		inter_schema_token *t = isn->expression_tokens;
		if ((t) && (t->ist_type == WHITE_SPACE_ISTT)) {
			isn->expression_tokens = t->next;
			return TRUE;
		}
		if (InterSchemas::strip_spacing(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::strip_all_spacing(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == WHITE_SPACE_ISTT)) {
			isn->expression_tokens = isn->expression_tokens->next;
			return TRUE;
		}
		int d = 0;
		inter_schema_token *prev = isn->expression_tokens;
		if (prev) {
			inter_schema_token *n = prev->next;
			while (n) {
			 	if (n->ist_type == WHITE_SPACE_ISTT) { prev->next = n->next; d++; }
				prev = n; n = n->next;
			}
		}
		if (d > 0) return TRUE;
		if (InterSchemas::strip_all_spacing(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::splitprints(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			if ((isn->expression_tokens->ist_type == RESERVED_ISTT)
				&& ((isn->expression_tokens->reserved_word == PRINT_I6RW) ||
					(isn->expression_tokens->reserved_word == PRINTRET_I6RW))) {
				inter_schema_token *n = isn->expression_tokens->next, *prev = isn->expression_tokens;
				int bl = 0;
				while (n) {
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
					if ((n->ist_type == COMMA_ISTT) && (bl == 0)) {
						prev->next = NULL;
						n->ist_type = RESERVED_ISTT;
						n->reserved_word = isn->expression_tokens->reserved_word;
						isn->expression_tokens->reserved_word = PRINT_I6RW;
						isn->expression_tokens->material = I"print";
						if (n->reserved_word == PRINT_I6RW) n->material = I"print";
						else n->material = I"print_ret";
						inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = n;
						new_isn->parent_node = isn->parent_node;
						for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
							l->owner = new_isn;
						}
						inter_schema_node *saved = isn->next_node;
						isn->next_node = new_isn;
						new_isn->next_node = saved;
						new_isn->semicolon_terminated = isn->semicolon_terminated;
						return TRUE;
					}
					prev = n; n = n->next;
				}
			}
		}
		if (InterSchemas::splitprints(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::casey(inter_schema_node *isn) {
	if (isn == NULL) return FALSE;
	if (isn->expression_tokens) {
		inter_schema_token *n = isn->expression_tokens;
		int bl = 0;
		while (n) {
			if (n->ist_type == OPEN_ROUND_ISTT) bl++;
			if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
			if ((n->ist_type == COLON_ISTT) && (bl == 0)) return TRUE;
			n = n->next;
		}
	}
	return FALSE;
}

int InterSchemas::splitcases(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			inter_schema_token *n = isn->expression_tokens, *prev = isn->expression_tokens;
			int bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((n->ist_type == COLON_ISTT) && (bl == 0)) {
					inter_schema_node *original_child = isn->child_node;

					int defaulter = FALSE;
					if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == RESERVED_ISTT) &&
						(isn->expression_tokens->reserved_word == DEFAULT_I6RW)) defaulter = TRUE;
					
					inter_schema_node *sw_val = NULL;
					inter_schema_node *sw_code = NULL;
					if (defaulter) {
						sw_code = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
						isn->child_node = sw_code;
						sw_code->parent_node = isn;
					} else {
						sw_val = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						sw_code = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
						sw_val->next_node = sw_code;
						sw_val->parent_node = isn; isn->child_node = sw_val;
						sw_code->parent_node = isn;
					}

					int switch_begins = FALSE;
					int switch_ends = FALSE;
					inter_schema_node *pn = isn->parent_node;
					while (pn) {
						if ((pn->expression_tokens) && (pn->expression_tokens->ist_type == RESERVED_ISTT) &&
							(pn->expression_tokens->reserved_word == SWITCH_I6RW)) {
							switch_begins = TRUE;
							if (isn->next_node) switch_ends = TRUE;
						}
						pn = pn->parent_node;
					}
					if (switch_ends == FALSE) InterSchemas::mark_unclosed(sw_code);
					if (switch_begins == FALSE) InterSchemas::mark_case_closed(isn);
					if (sw_val) sw_val->expression_tokens = isn->expression_tokens;
					prev->next = NULL;
					isn->expression_tokens = NULL;
					isn->isn_type = STATEMENT_ISNT;
					if (defaulter)
						isn->isn_clarifier = default_interp;
					else
						isn->isn_clarifier = case_interp;

					inter_schema_node *sw_code_exp = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					sw_code_exp->expression_tokens = n->next;

					sw_code->child_node = sw_code_exp;
					sw_code_exp->parent_node = sw_code;

					if (sw_val)
						for (inter_schema_token *t = sw_val->expression_tokens; t; t = t->next)
							t->owner = sw_val;
					for (inter_schema_token *t = sw_code_exp->expression_tokens; t; t = t->next)
						t->owner = sw_code_exp;
					
					sw_code_exp->child_node = original_child;

					inter_schema_node *at = isn->next_node;
					inter_schema_node *attach = sw_code_exp;
					while ((at) && (InterSchemas::casey(at) == FALSE)) {
						inter_schema_node *next_at = at->next_node;
						at->next_node = NULL;
						at->parent_node = sw_code;
						attach->next_node = at;
						attach = at;
						isn->next_node = next_at;
						at = next_at;
					}

					return TRUE;
				}
				prev = n; n = n->next;
			}
		}
		if (InterSchemas::splitcases(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::alternatecases(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->isn_clarifier == case_interp) && (isn->child_node)) {
			inter_schema_node *A = isn->child_node;
			inter_schema_node *B = isn->child_node->next_node;
			if ((A) && (B) && (B->next_node)) {
				inter_schema_node *C = InterSchemas::new_node(isn->parent_schema, OPERATION_ISNT);
				C->isn_clarifier = alternativecase_interp;
				C->child_node = A;
				A->parent_node = C; B->parent_node = C;
				isn->child_node = C; C->next_node = B->next_node; B->next_node = NULL;
				C->parent_node = isn;
				return TRUE;
			}				
		}
		if (InterSchemas::alternatecases(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::identify_constructs(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if (isn->expression_tokens) {
			inter_symbol *subordinate_to = NULL;
			inter_schema_token *operand1 = NULL, *operand2 = NULL;
			inter_schema_node *operand2_node = NULL;
			int dangle = NOT_APPLICABLE;
			text_stream *dangle_text = NULL;
			if (isn->expression_tokens->ist_type == RESERVED_ISTT) {
				switch (isn->expression_tokens->reserved_word) {
					case PRINT_I6RW:
					case PRINTRET_I6RW:
						subordinate_to = printnumber_interp;
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						if ((n) && (n->ist_type == OPEN_ROUND_ISTT)) {
							n = n->next;
							while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
							inter_schema_token *pr = n;
							if (pr) {
								n = n->next;
								while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
								if ((n) && (n->ist_type == CLOSE_ROUND_ISTT)) {
									n = n->next;
									while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
									if (Str::eq(pr->material, I"address")) {
										subordinate_to = printaddress_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"number")) {
										subordinate_to = printnlnumber_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"char")) {
										subordinate_to = printchar_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"string")) {
										subordinate_to = printstring_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"name")) {
										subordinate_to = printname_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"the")) {
										subordinate_to = printdef_interp;
										operand1 = n;
									} else if (Str::eq(pr->material, I"The")) {
										subordinate_to = printcdef_interp;
										operand1 = n;
									} else if ((Str::eq(pr->material, I"a")) || (Str::eq(pr->material, I"an"))) {
										subordinate_to = printindef_interp;
										operand1 = n;
									} else if ((Str::eq(pr->material, I"A")) || (Str::eq(pr->material, I"An"))) {
										subordinate_to = printcindef_interp;
										operand1 = n;
									} else {
										isn->expression_tokens = pr;
										inter_schema_token *open_b =
											InterSchemas::new_token(OPEN_ROUND_ISTT, I"(", NULL, 0, -1);
										InterSchemas::add_token_after(open_b, isn->expression_tokens);
										open_b->next = n;
										n = open_b;
										while ((n) && (n->next)) n = n->next;
										inter_schema_token *close_b =
											InterSchemas::new_token(CLOSE_ROUND_ISTT, I")", NULL, 0, -1);
										InterSchemas::add_token_after(close_b, n);
										subordinate_to = NULL;
										operand1 = NULL;
									}
								}
							}
						}
						if (subordinate_to == printnumber_interp) {
							inter_schema_token *n = isn->expression_tokens->next;
							while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
							if ((n) && (n->ist_type == DQUOTED_ISTT)) {
								subordinate_to = print_interp;
								InterSchemas::de_escape_text(n->material);
							}
						}
						if (isn->expression_tokens->reserved_word == PRINTRET_I6RW) {
							inter_schema_node *save_next = isn->next_node;
							isn->next_node = InterSchemas::new_node(isn->parent_schema, STATEMENT_ISNT);
							isn->next_node->parent_node = isn->parent_node;
							isn->next_node->isn_clarifier = print_interp;
							isn->next_node->child_node = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
							isn->next_node->child_node->parent_node = isn->next_node;
							InterSchemas::add_token_to_node(isn->next_node->child_node, InterSchemas::new_token(DQUOTED_ISTT, I"\n", NULL, 0, -1));
							isn->next_node->next_node = InterSchemas::new_node(isn->parent_schema, STATEMENT_ISNT);
							isn->next_node->next_node->parent_node = isn->parent_node;
							isn->next_node->next_node->isn_clarifier = return_interp;
							isn->next_node->next_node->next_node = save_next;
						}
						break;
					case STYLE_I6RW: {
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						if ((n) && (Str::eq(n->material, I"roman"))) subordinate_to = styleroman_interp;
						if ((n) && (Str::eq(n->material, I"bold"))) subordinate_to = stylebold_interp;
						if ((n) && (Str::eq(n->material, I"underline"))) subordinate_to = styleunderline_interp;
						if ((n) && (Str::eq(n->material, I"reverse"))) subordinate_to = stylereverse_interp;
						if (subordinate_to) isn->expression_tokens->next = NULL;
						break;
					}
					case INVERSION_I6RW:
						subordinate_to = inversion_interp;
						break;
					case FONT_I6RW: {
						subordinate_to = font_interp;
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						if ((n) && (Str::eq(n->material, I"on"))) dangle = 1;
						if ((n) && (Str::eq(n->material, I"off"))) dangle = 0;
						break;
					}
					case OBJECTLOOP_I6RW:
						subordinate_to = objectloop_interp;
						break;
					case SWITCH_I6RW:
						subordinate_to = switch_interp;
						break;
					case IF_I6RW: {
						subordinate_to = if_interp;
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand1 = n;
						inter_schema_node *next_isn = isn->next_node;
						if ((next_isn) && (next_isn->expression_tokens) &&
							(next_isn->expression_tokens->ist_type == RESERVED_ISTT) &&
							(next_isn->expression_tokens->reserved_word == ELSE_I6RW) &&
							(next_isn->child_node)) {
							inter_schema_token *n = next_isn->child_node->child_node->expression_tokens;
							while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
							operand2 = n;
							if (n) {
								subordinate_to = ifelse_interp;
								operand2_node = next_isn->child_node;
							}
							isn->next_node = next_isn->next_node;
						}
						break;
					}
					case FOR_I6RW:
						subordinate_to = for_interp;
						break;
					case WHILE_I6RW:
						subordinate_to = while_interp;
						break;
					case DO_I6RW:
						subordinate_to = do_interp;
						inter_schema_node *next_isn = isn->next_node;
						if ((next_isn) && (next_isn->expression_tokens) &&
							(next_isn->expression_tokens->ist_type == RESERVED_ISTT) &&
							(next_isn->expression_tokens->reserved_word == UNTIL_I6RW)) {
	//						operand2_node = next_isn->child_node;
							isn->next_node = next_isn->next_node;
							inter_schema_token *n = next_isn->expression_tokens->next;
							while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
							operand1 = n;
//							while (n) {
//								n->owner = operand2_node;
//								n = n->next;
//							}
						} else {
							internal_error("do without until");
						}
						break;
					case JUMP_I6RW:
						subordinate_to = jump_interp;
						break;
					case RETURN_I6RW:
						subordinate_to = return_interp;
						break;
					case RTRUE_I6RW:
						subordinate_to = return_interp;
						dangle = TRUE;
						break;
					case RFALSE_I6RW:
						subordinate_to = return_interp;
						dangle = FALSE;
						break;
					case BREAK_I6RW:
						subordinate_to = break_interp;
						break;
					case CONTINUE_I6RW:
						subordinate_to = continue_interp;
						break;
					case QUIT_I6RW:
						subordinate_to = quit_interp;
						break;
					case RESTORE_I6RW:
						subordinate_to = restore_interp;
						break;
					case SPACES_I6RW:
						subordinate_to = spaces_interp;
						break;
					case NEWLINE_I6RW:
						subordinate_to = print_interp;
						dangle_text = I"\n";
						break;
					case MOVE_I6RW: {
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand1 = n;
						while (n) {
							if (Str::eq(n->material, I"to")) {
								n->ist_type = WHITE_SPACE_ISTT;
								n->material = I" ";
								operand2 = n->next;
								n->next = NULL;
								while ((operand2) && (operand2->ist_type == WHITE_SPACE_ISTT)) operand2 = operand2->next;
								break;
							}
							n = n->next;
						}
						if ((operand1) && (operand2)) subordinate_to = move_interp;
						break;
					}
					case READ_I6RW: {
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand1 = n;
						n = n->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand2 = n;
						operand1->next = NULL;
						operand2->next = NULL;
						if ((operand1) && (operand2)) subordinate_to = read_interp;
						break;
					}
					case REMOVE_I6RW:
						subordinate_to = remove_interp;
						break;
					case GIVE_I6RW: {
						inter_schema_token *n = isn->expression_tokens->next;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand1 = n;
						n = n->next;
						operand1->next = NULL;
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						if ((n) && (n->ist_type == OPERATOR_ISTT) && (n->operation_primitive == bitwisenot_interp)) {
							subordinate_to = take_interp;
							n = n->next;
						} else {
							subordinate_to = give_interp;
						}
						while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
						operand2 = n;
						break;
					}
				}
			}
			if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == DIRECTIVE_ISTT)) {
				isn->isn_type = DIRECTIVE_ISNT;
				isn->dir_clarifier = isn->expression_tokens->reserved_word;
				if (isn->expression_tokens->next) {
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					isn->child_node = new_isn;
					new_isn->parent_node = isn;
					new_isn->expression_tokens = isn->expression_tokens->next;
					for (inter_schema_token *n = new_isn->expression_tokens; n; n = n->next)
						n->owner = new_isn;
				}
				isn->expression_tokens = NULL;
				subordinate_to = NULL;
			}
			if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == OPCODE_ISTT)) {
				if (Str::eq(isn->expression_tokens->material, I"@push")) subordinate_to = push_interp;
				else if (Str::eq(isn->expression_tokens->material, I"@pull")) subordinate_to = pull_interp;
				else {
					isn->isn_type = ASSEMBLY_ISNT;
					inter_schema_node *prev_node = NULL;
					for (inter_schema_token *l = isn->expression_tokens, *n = l?(l->next):NULL; l; l=n, n=n?(n->next):NULL) {
						if (l->ist_type != WHITE_SPACE_ISTT) {
							inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
							new_isn->expression_tokens = l; l->next = NULL; l->owner = new_isn;
							if (l->operation_primitive) {
								l->ist_type = IDENTIFIER_ISTT;
								l->operation_primitive = NULL;
							}
							if ((n) && (Str::eq(l->material, I"-"))) {
								l->material = Str::new();
								WRITE_TO(l->material, "-%S", n->material);
								l->ist_type = NUMBER_ISTT;
								n = n->next;
							}
							if (Str::eq(l->material, I"->")) l->ist_type = ASM_ARROW_ISTT;
							if (Str::eq(l->material, I"sp")) l->ist_type = ASM_SP_ISTT;
							if ((Str::eq(l->material, I"?")) && (n)) {
								l->ist_type = ASM_LABEL_ISTT;
								l->material = n->material;
								n = n->next;
								if (Str::eq(l->material, I"~")) {
									l->ist_type = ASM_NEGATED_LABEL_ISTT;
									l->material = n->material;
									n = n->next;
								}
							}
							if (isn->child_node == NULL) isn->child_node = new_isn;
							else if (prev_node) prev_node->next_node = new_isn;
							new_isn->parent_node = isn;
							prev_node = new_isn;
						}
					}
					isn->expression_tokens = NULL;
				}
			}
			if (subordinate_to) {
				inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				if (operand1 == NULL) operand1 = isn->expression_tokens->next;
				new_isn->expression_tokens = operand1;
				if ((new_isn->expression_tokens) && (new_isn->expression_tokens->ist_type == WHITE_SPACE_ISTT)) new_isn->expression_tokens = new_isn->expression_tokens->next;
				for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
					l->owner = new_isn;
				}
				isn->isn_clarifier = subordinate_to;
				isn->isn_type = STATEMENT_ISNT;
				isn->expression_tokens = NULL;
				new_isn->next_node = isn->child_node;
				isn->child_node = new_isn;
				new_isn->parent_node = isn;
				if (dangle != NOT_APPLICABLE) {
					text_stream *T = Str::new();
					WRITE_TO(T, "%d", dangle);
					new_isn->expression_tokens = InterSchemas::new_token(NUMBER_ISTT, T, NULL, 0, -1);
					new_isn->expression_tokens->owner = new_isn;
				}
				if (dangle_text) {
					new_isn->expression_tokens = InterSchemas::new_token(DQUOTED_ISTT, dangle_text, NULL, 0, -1);
					new_isn->expression_tokens->owner = new_isn;
					InterSchemas::de_escape_text(new_isn->expression_tokens->material);
				}
				if (operand2) {
					inter_schema_node *new_new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					if (subordinate_to == ifelse_interp) {
						new_new_isn->semicolon_terminated = TRUE;
						new_new_isn->next_node = new_isn->next_node->next_node;
						new_isn->next_node->next_node = new_new_isn;
					} else {
						new_new_isn->next_node = new_isn->next_node;
						new_isn->next_node = new_new_isn;
					}
					new_new_isn->parent_node = isn;
					new_new_isn->expression_tokens = operand2;
					if ((new_new_isn->expression_tokens) && (new_new_isn->expression_tokens->ist_type == WHITE_SPACE_ISTT))
						new_new_isn->expression_tokens = new_new_isn->expression_tokens->next;
					for (inter_schema_token *l = new_new_isn->expression_tokens; l; l=l->next) {
						l->owner = new_new_isn;
					}
				}
				if (operand2_node) {
					operand2_node->next_node = NULL;
					new_isn->next_node->next_node = operand2_node;
					operand2_node->parent_node = isn;
					for (inter_schema_token *l = operand2_node->child_node->expression_tokens; l; l=l->next) {
						l->owner = operand2_node->child_node;
					}
				}
				return 1;
			}
		}
		if ((isn->isn_type != ASSEMBLY_ISNT) && (isn->isn_type != DIRECTIVE_ISNT))
			if (InterSchemas::identify_constructs(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::treat_constructs(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		if ((isn->isn_type == STATEMENT_ISNT) &&
			(isn->isn_clarifier == for_interp) &&
			(isn->node_marked == FALSE)) {
			inter_schema_node *predicates = isn->child_node;
			if ((predicates == NULL) || (predicates->isn_type != EXPRESSION_ISNT))
				internal_error("malformed proto-for");
			inter_schema_token *n = predicates->expression_tokens;
			inter_schema_node *code_node = predicates->next_node;
			int bl = 0, cw = 0;
			inter_schema_token *from[3], *to[3];
			for (int i=0; i<3; i++) { from[i] = 0; to[i] = 0; }
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) {
					if ((bl > 0) && (from[cw] == NULL)) from[cw] = n;
					bl++;
				} else if (n->ist_type == CLOSE_ROUND_ISTT) {
					bl--;
					if (bl == 0) @<End a wodge@>;
				} else if (bl == 1) {
					if (n->ist_type == COLON_ISTT) @<End a wodge@>
					else {
						if (from[cw] == NULL) from[cw] = n;
					}
				}
				n = n->next;
			}
			if (cw != 3) internal_error("malformed for prototype");
			for (int i=0; i<3; i++) {
// LOG("For clause %d is :", i); InterSchemas::log_ist(from[i]); LOG(" to "); InterSchemas::log_ist(to[i]); LOG("\n");
				inter_schema_node *eval_isn = InterSchemas::new_node(isn->parent_schema, EVAL_ISNT);
				if (i == 0) isn->child_node = eval_isn;
				if (i == 1) isn->child_node->next_node = eval_isn;
				if (i == 2) {
					isn->child_node->next_node->next_node = eval_isn;
					eval_isn->next_node = code_node;
				}
				eval_isn->parent_node = isn;

				inter_schema_node *expr_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
				eval_isn->child_node = expr_isn;
				expr_isn->parent_node = eval_isn;

				inter_schema_token *m = from[i];
				while ((m) && (m->ist_type == WHITE_SPACE_ISTT)) m = m->next;
				expr_isn->expression_tokens = m;
				if (m == to[i]) expr_isn->expression_tokens = NULL;
				else {
					while (m) {
						m->owner = expr_isn;
						if (m->next == to[i]) m->next = NULL;
						m = m->next;
					}
				}
			}
			isn->node_marked = TRUE;
			return TRUE;
		}
		if (InterSchemas::treat_constructs(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@<End a wodge@> =
	if (from[cw] == NULL) to[cw] = NULL;
	else to[cw] = n;
	if (from[cw] == to[cw]) { from[cw] = NULL; to[cw] = NULL; }
	cw++;

@ =
int InterSchemas::add_missing_bodies(inter_schema_node *par, inter_schema_node *isn) {
	for (; isn; isn=isn->next_node) {
		int req = 0;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == if_interp)) req = 2;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == ifelse_interp)) req = 3;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == for_interp)) req = 4;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == while_interp)) req = 2;
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == objectloop_interp)) req = 2;
		if ((req > 0) && (isn->node_marked == FALSE)) {
			int actual = 0;
			for (inter_schema_node *ch = isn->child_node; ch; ch=ch->next_node) actual++;
			if (actual < req-1) internal_error("far too few child nodes");
			if (actual > req) internal_error("too many child nodes");
			if (actual == req-1) {
				inter_schema_node *code_isn = InterSchemas::new_node(isn->parent_schema, CODE_ISNT);
				code_isn->parent_node = isn;

				inter_schema_node *ch = isn->child_node;
				while ((ch) && (ch->next_node)) ch=ch->next_node;
				ch->next_node = code_isn;

				InterSchemas::mark_unclosed(code_isn);
				isn->node_marked = TRUE;
				return TRUE;
			}
		}
		if (InterSchemas::add_missing_bodies(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::remove_empties(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == EXPRESSION_ISNT) && (isn->expression_tokens == NULL)) {
			if (prev) prev->next_node = isn->next_node;
			else if (par) par->child_node = isn->next_node;
			else isn->parent_schema->node_tree = isn->next_node;
			return TRUE;
		}
		if (InterSchemas::remove_empties(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::top_level_commas(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *n = isn->expression_tokens, *prev = NULL;
			int bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((n->ist_type == COMMA_ISTT) && (bl == 0) && (prev)) {
					prev->next = NULL;
					prev = n; n = n->next;
					while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) { prev = n; n = n->next; }
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = n;
					new_isn->parent_node = isn->parent_node;
					for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
						l->owner = new_isn;
					}
					inter_schema_node *saved = isn->next_node;
					isn->next_node = new_isn;
					new_isn->next_node = saved;
					new_isn->semicolon_terminated = isn->semicolon_terminated;
					return TRUE;
				}
				prev = n; n = n->next;
			}
		}
		if (InterSchemas::top_level_commas(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::debracket(inter_schema_node *par, inter_schema_node *isn) {
	if (InterSchemas::outer_subexpressions(par, isn)) return TRUE;
	if (InterSchemas::op_subexpressions(par, isn)) return TRUE;
	if (InterSchemas::place_calls(par, isn)) return TRUE;
	return FALSE;
}

int InterSchemas::outer_subexpressions(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *n = isn->expression_tokens;
			while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
			if ((n) && (n->ist_type == OPEN_ROUND_ISTT)) {
				int bl = 1, fails = FALSE;
				n = n->next;
				while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				inter_schema_token *from = n, *to = NULL;
				while (n) {
					if ((bl == 0) && (n->ist_type != WHITE_SPACE_ISTT)) fails = TRUE;
					if (n->ist_type == OPEN_ROUND_ISTT) bl++;
					else if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) to = n;
					}
					n = n->next;
				}
				if ((fails == FALSE) && (from) && (to) && (from != to)) {
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = from;
					for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
						l->owner = new_isn;
						if (l->next == to) l->next = NULL;
					}
					isn->isn_type = SUBEXPRESSION_ISNT;
					isn->expression_tokens = NULL;

					isn->child_node = new_isn;
					new_isn->parent_node = isn;

					return TRUE;
				}
			}
		}
		if (InterSchemas::outer_subexpressions(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::prefer_over(inter_symbol *p, inter_symbol *existing) {
	if (existing == NULL) return TRUE;
	if (InterSchemas::precedence(p) < InterSchemas::precedence(existing)) return TRUE;
	if ((InterSchemas::precedence(p) == InterSchemas::precedence(existing)) &&
		(InterSchemas::right_associative(p)) &&
		(InterSchemas::arity(p) == 2) &&
		(InterSchemas::arity(existing) == 2)) return TRUE;
	return FALSE;
}

int InterSchemas::op_subexpressions(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if ((isn->node_marked == FALSE) && (isn->isn_type == EXPRESSION_ISNT)) {
			isn->node_marked = TRUE;
			inter_schema_token *n = isn->expression_tokens;
			int bl = 0;
			inter_symbol *best_operator = NULL;
			inter_schema_token *break_at = NULL;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) bl++;
				if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
				if ((bl == 0) && (n->ist_type == OPERATOR_ISTT)) {
					inter_symbol *this_operator = n->operation_primitive;
					if (InterSchemas::prefer_over(this_operator, best_operator)) {
						break_at = n; best_operator = this_operator;
					}
				}
				n = n->next;
			}
			if (break_at) {
				inter_schema_token *n = isn->expression_tokens;
				while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
				inter_schema_token *from = n, *to = break_at;
				int has_operand_before = FALSE, has_operand_after = FALSE;
				if ((from) && (from != to)) {
					inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
					new_isn->expression_tokens = from;
					for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
						l->owner = new_isn;
						if (l->next == to) l->next = NULL;
					}
					if (isn->child_node == NULL) {
						isn->child_node = new_isn;
					} else {
						isn->child_node->next_node = new_isn;
					}
					new_isn->parent_node = isn;
					has_operand_before = TRUE;
				} else {
					if (best_operator == in_interp) {
						break_at->ist_type = IDENTIFIER_ISTT;
						break_at->operation_primitive = NULL;
						break_at = NULL;
					}
				}
				if (break_at) {
					n = break_at->next;
					while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
					from = n; to = NULL;
					if ((from) && (from != to)) {
						inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
						new_isn->expression_tokens = from;
						for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
							l->owner = new_isn;
							if (l->next == to) l->next = NULL;
						}
						if (isn->child_node == NULL) {
							isn->child_node = new_isn;
						} else {
							isn->child_node->next_node = new_isn;
						}
						new_isn->parent_node = isn;
						has_operand_after = TRUE;
					}

					isn->isn_type = OPERATION_ISNT;
					isn->expression_tokens = NULL;
					isn->isn_clarifier = break_at->operation_primitive;
					if ((break_at->operation_primitive == minus_interp) && (has_operand_before == FALSE))
						isn->isn_clarifier = unaryminus_interp;
					if ((break_at->operation_primitive == postincrement_interp) && (has_operand_before == FALSE))
						isn->isn_clarifier = preincrement_interp;
					if ((break_at->operation_primitive == postdecrement_interp) && (has_operand_before == FALSE))
						isn->isn_clarifier = predecrement_interp;
					if ((break_at->operation_primitive == propertyvalue_interp) && (has_operand_before == FALSE)) {
						isn->isn_type = LABEL_ISNT;
						isn->isn_clarifier = NULL;
					} else {
						int a = 0;
						if (has_operand_before) a++;
						if (has_operand_after) a++;
						if (a != InterSchemas::arity(isn->isn_clarifier)) {
							LOG("Seem to have arity %d with isn %S\n", a, isn->isn_clarifier->symbol_name);
							LOG("$1\n", isn->parent_schema);
							internal_error("bad arity");
						}
					}
					return TRUE;
				}
			}
		}
		if (InterSchemas::op_subexpressions(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

int InterSchemas::place_calls(inter_schema_node *par, inter_schema_node *isn) {
	for ( ; isn; isn = isn->next_node) {
		if (isn->isn_type == EXPRESSION_ISNT) {
			if ((isn->expression_tokens) && (isn->expression_tokens->ist_type == OPEN_ROUND_ISTT)) {
				int bl = 0, term_count = 0, tops = 0;
				inter_schema_token *opener = NULL, *closer = NULL;
				for (inter_schema_token *n = isn->expression_tokens; n; n = n->next) {
					if (n->ist_type == OPEN_ROUND_ISTT) {
						bl++;
						if (bl == 1) { opener = n; closer = NULL; term_count++; }
					} else if (n->ist_type == CLOSE_ROUND_ISTT) {
						bl--;
						if (bl == 0) { closer = n; }
					} else if (bl == 0) tops++;
				}
				if ((term_count == 2) && (tops == 0) && (opener) && (closer)) {
					@<Call brackets found@>;
				}
			}
			inter_schema_token *n = isn->expression_tokens;
			inter_schema_token *opener = NULL, *closer = NULL;
			int pre_count = 0, pre_bracings = 0, post_count = 0, veto = FALSE, bl = 0;
			while (n) {
				if (n->ist_type == OPEN_ROUND_ISTT) {
					bl++;
					if (bl == 1) {
						if (opener == NULL) opener = n;
						else veto = TRUE;
					}
				} else if (n->ist_type == CLOSE_ROUND_ISTT) {
					bl--;
					if ((bl == 0) && (closer == NULL)) closer = n;
				} else if ((bl == 0) && (n->ist_type != INLINE_ISTT)) {
					if (opener == NULL) pre_count++;
					if ((opener) && (closer)) post_count++;
				} else if (bl == 0) {
					if (opener == NULL) pre_bracings++;
				}
				n = n->next;
			}
			if (((pre_count == 1) || ((pre_count == 0) && (pre_bracings > 0))) &&
				(post_count == 0) && (opener) && (closer) && (veto == FALSE))
				@<Call brackets found@>;
		}
		if (InterSchemas::place_calls(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@<Call brackets found@> =
	inter_schema_token *from = isn->expression_tokens, *to = opener, *resume = opener->next;
	@<Relegate node@>;
	inter_schema_token *n = resume; from = n; int bl = 0;
	while ((n != closer) && (n)) {
		if (n->ist_type == OPEN_ROUND_ISTT) bl++;
		if (n->ist_type == CLOSE_ROUND_ISTT) bl--;
		if ((bl == 0) && (n->ist_type == COMMA_ISTT)) {
			to = n; resume = n->next;
			@<Relegate node@>;
			from = resume; n = from;
		} else {
			n = n->next;
		}
	}
	to = closer;
	@<Relegate node@>;

	isn->expression_tokens = NULL; isn->isn_type = CALL_ISNT;
	return TRUE;

@<Relegate node@> =
	if ((from) && (to) && (from != to)) {
		inter_schema_node *new_isn = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
		new_isn->expression_tokens = from;
		for (inter_schema_token *l = new_isn->expression_tokens; l; l=l->next) {
			l->owner = new_isn;
			if (l->next == to) l->next = NULL;
		}
		if (isn->child_node == NULL) {
			isn->child_node = new_isn;
		} else {
			inter_schema_node *xisn = isn->child_node;
			while ((xisn) && (xisn->next_node)) xisn = xisn->next_node;
			xisn->next_node = new_isn;
		}
		new_isn->parent_node = isn;
	}

@ =
int InterSchemas::implied_return_values(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == STATEMENT_ISNT) && (isn->isn_clarifier == return_interp) && (isn->child_node == FALSE)) {
			isn->child_node = InterSchemas::new_node(isn->parent_schema, EXPRESSION_ISNT);
			isn->child_node->parent_node = isn;
			isn->child_node->expression_tokens = InterSchemas::new_token(NUMBER_ISTT, I"1", NULL, 0, -1);
			isn->child_node->expression_tokens->owner = isn->child_node;
			return TRUE;
		}
		if (InterSchemas::implied_return_values(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
int InterSchemas::message_calls(inter_schema_node *par, inter_schema_node *isn) {
	for (inter_schema_node *prev = NULL; isn; prev = isn, isn = isn->next_node) {
		if ((isn->isn_type == OPERATION_ISNT) && (isn->isn_clarifier == propertyvalue_interp) &&
			(isn->child_node) && (isn->child_node->next_node) && (isn->child_node->next_node->isn_type == CALL_ISNT)) {
			inter_schema_node *obj = isn->child_node;
			inter_schema_node *message = isn->child_node->next_node->child_node;
			inter_schema_node *args = isn->child_node->next_node->child_node->next_node;
			isn->isn_type = MESSAGE_ISNT; isn->isn_clarifier = NULL;
			obj->next_node = message; message->parent_node = isn; message->next_node = args;
			if (message->isn_type == EXPRESSION_ISNT) {
				inter_schema_token *n = message->expression_tokens;
				if ((n) && (Str::eq(n->material, I"call"))) {
					obj->next_node = args; isn->isn_type = CALLMESSAGE_ISNT;
				}
			}
			while (args) { args->parent_node = isn; args = args->next_node; }
			return TRUE;
		}
		if (InterSchemas::message_calls(isn, isn->child_node)) return TRUE;
	}
	return FALSE;
}

@ =
void InterSchemas::de_escape_text(text_stream *m) {
	int run_start = -1, run_len = 0, run_includes = FALSE;
	for (int i=0; i<Str::len(m); i++) {
		wchar_t c = Str::get_at(m, i);
		if ((c == ' ') || (c == '\t') || (c == '\n')) {
			if (run_start == -1) {
				run_start = i;
				run_len = 0;
				run_includes = FALSE;
			}
			run_len++;
			if (c == '\n') run_includes = TRUE;
		} else {
			if ((run_start >= 0) && (run_includes)) {
				Str::put_at(m, run_start, ' ');
				for (int j=0; j<run_len-1; j++)
					Str::delete_nth_character(m, run_start+1);
				i = run_start;
			}
			run_start = -1;
		}
	}
	LOOP_THROUGH_TEXT(P, m) {
		if (Str::get(P) == '^')
			Str::put(P, '\n');
		if (Str::get(P) == '~')
			Str::put(P, '\"');
	}
}

@h Operators in I6.
The following routines return data which is essentially the content of the
table shown in section 6.2 of the Inform 6 Technical Manual: which operators
take precedence over which others, which are right or left associative,
which are prefix or postfix, and so on.

The superclass operator |::| is not allowed in schemas, but nor is it needed.

@d UNPRECEDENTED_OPERATOR 10000

=
int InterSchemas::precedence(inter_symbol *O) {
	if (O == store_interp) return 1;

	if (O == and_interp) return 2;
	if (O == or_interp) return 2;
	if (O == not_interp) return 2;

	if (O == eq_interp) return 3;
	if (O == gt_interp) return 3;
	if (O == ge_interp) return 3;
	if (O == lt_interp) return 3;
	if (O == le_interp) return 3;
	if (O == ne_interp) return 3;
	if (O == has_interp) return 3;
	if (O == hasnt_interp) return 3;
	if (O == ofclass_interp) return 3;
	if (O == provides_interp) return 3;
	if (O == in_interp) return 3;
	if (O == notin_interp) return 3;

	if (O == alternative_interp) return 4;
	if (O == alternativecase_interp) return 4;

	if (O == plus_interp) return 5;
	if (O == minus_interp) return 5;

	if (O == times_interp) return 6;
	if (O == divide_interp) return 6;
	if (O == modulo_interp) return 6;
	if (O == bitwiseand_interp) return 6;
	if (O == bitwiseor_interp) return 6;
	if (O == bitwisenot_interp) return 6;

	if (O == lookup_interp) return 7;
	if (O == lookupbyte_interp) return 7;

	if (O == unaryminus_interp) return 8;

	if (O == preincrement_interp) return 9;
	if (O == predecrement_interp) return 9;
	if (O == postincrement_interp) return 9;
	if (O == postdecrement_interp) return 9;

	if (O == propertyaddress_interp) return 10;
	if (O == propertylength_interp) return 10;

	if (O == propertyvalue_interp) return 12;

	return UNPRECEDENTED_OPERATOR;
}

int InterSchemas::first_operand_ref(inter_symbol *O) {
	if (O == store_interp) return TRUE;
	if (O == preincrement_interp) return TRUE;
	if (O == predecrement_interp) return TRUE;
	if (O == postincrement_interp) return TRUE;
	if (O == postdecrement_interp) return TRUE;
	return FALSE;
}

text_stream *InterSchemas::text_form(inter_symbol *O) {
	if (O == store_interp) return I"=";

	if (O == and_interp) return I"&&";
	if (O == or_interp) return I"||";
	if (O == not_interp) return I"~~";

	if (O == eq_interp) return I"==";
	if (O == gt_interp) return I">";
	if (O == ge_interp) return I">=";
	if (O == lt_interp) return I"<";
	if (O == le_interp) return I"<=";
	if (O == ne_interp) return I"~=";
	if (O == has_interp) return I"has";
	if (O == hasnt_interp) return I"hasnt";
	if (O == ofclass_interp) return I"ofclass";
	if (O == provides_interp) return I"provides";
	if (O == in_interp) return I"in";
	if (O == notin_interp) return I"notin";

	if (O == alternative_interp) return I"or";

	if (O == plus_interp) return I"+";
	if (O == minus_interp) return I"-";

	if (O == times_interp) return I"*";
	if (O == divide_interp) return I"/";
	if (O == modulo_interp) return I"%";
	if (O == bitwiseand_interp) return I"&";
	if (O == bitwiseor_interp) return I"|";
	if (O == bitwisenot_interp) return I"~";

	if (O == lookup_interp) return I"-->";
	if (O == lookupbyte_interp) return I"->";

	if (O == unaryminus_interp) return I"-";

	if (O == preincrement_interp) return I"++";
	if (O == predecrement_interp) return I"--";
	if (O == postincrement_interp) return I"++";
	if (O == postdecrement_interp) return I"--";

	if (O == propertyaddress_interp) return I".&";
	if (O == propertylength_interp) return I".#";

	if (O == propertyvalue_interp) return I".";

	return I"???";
}

int InterSchemas::arity(inter_symbol *O) {
	if (O == store_interp) return 2;

	if (O == and_interp) return 2;
	if (O == or_interp) return 2;
	if (O == not_interp) return 1;

	if (O == alternative_interp) return 2;
	if (O == alternativecase_interp) return 2;

	if (O == eq_interp) return 2;
	if (O == gt_interp) return 2;
	if (O == ge_interp) return 2;
	if (O == lt_interp) return 2;
	if (O == le_interp) return 2;
	if (O == ne_interp) return 2;
	if (O == has_interp) return 2;
	if (O == hasnt_interp) return 2;
	if (O == ofclass_interp) return 2;
	if (O == provides_interp) return 2;
	if (O == in_interp) return 2;
	if (O == notin_interp) return 2;

	if (O == plus_interp) return 2;
	if (O == minus_interp) return 2;

	if (O == times_interp) return 2;
	if (O == divide_interp) return 2;
	if (O == modulo_interp) return 2;
	if (O == bitwiseand_interp) return 2;
	if (O == bitwiseor_interp) return 2;
	if (O == bitwisenot_interp) return 1;

	if (O == lookup_interp) return 2;
	if (O == lookupbyte_interp) return 2;

	if (O == unaryminus_interp) return 1;

	if (O == preincrement_interp) return 1;
	if (O == predecrement_interp) return 1;
	if (O == postincrement_interp) return 1;
	if (O == postdecrement_interp) return 1;

	if (O == propertyaddress_interp) return 2;
	if (O == propertylength_interp) return 2;
	if (O == propertyvalue_interp) return 2;

	return 0;
}

int InterSchemas::prefix(inter_symbol *O) {
	if (O == not_interp) return TRUE;
	if (O == bitwisenot_interp) return TRUE;
	if (O == unaryminus_interp) return TRUE;

	if (O == preincrement_interp) return TRUE;
	if (O == predecrement_interp) return TRUE;
	if (O == postincrement_interp) return FALSE;
	if (O == postdecrement_interp) return FALSE;

	return NOT_APPLICABLE;
}

int InterSchemas::right_associative(inter_symbol *O) {
	if (O == store_interp) return FALSE;
	return TRUE;
}

@h Metadata on inter primitives.

=
int InterSchemas::ip_arity(inter_symbol *O) {
	int arity = 1;
	if ((O == styleroman_interp) ||
		(O == stylebold_interp) ||
		(O == styleunderline_interp) ||
		(O == stylereverse_interp) ||
		(O == inversion_interp)) arity = 0;
	if (O == break_interp) arity = 0;
	if (O == continue_interp) arity = 0;
	if (O == quit_interp) arity = 0;
	if (O == move_interp) arity = 2;
	if (O == give_interp) arity = 2;
	if (O == take_interp) arity = 2;
	if (O == default_interp) arity = 1;
	if (O == case_interp) arity = 2;
	if (O == switch_interp) arity = 2;
	if (O == objectloop_interp) arity = 2;
	if (O == if_interp) arity = 2;
	if (O == ifelse_interp) arity = 3;
	if (O == for_interp) arity = 4;
	if (O == while_interp) arity = 2;
	if (O == do_interp) arity = 2;
	if (O == read_interp) arity = 2;
	return arity;
}

int InterSchemas::ip_loopy(inter_symbol *O) {
	int loopy = FALSE;
	if (O == objectloop_interp) loopy = TRUE;
	if (O == for_interp) loopy = TRUE;
	if (O == while_interp) loopy = TRUE;
	if (O == do_interp) loopy = TRUE;
	return loopy;
}

int InterSchemas::ip_prim_cat(inter_symbol *O, int i) {
	int ok = VAL_PRIM_CAT;
	if (O == jump_interp) ok = LAB_PRIM_CAT;
	if (O == restore_interp) ok = LAB_PRIM_CAT;
	if (O == pull_interp) ok = REF_PRIM_CAT;

	if ((O == if_interp) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == switch_interp) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == case_interp) && (i == 1)) ok = CODE_PRIM_CAT;
	if ((O == default_interp) && (i == 0)) ok = CODE_PRIM_CAT;
	if ((O == ifelse_interp) && (i >= 1)) ok = CODE_PRIM_CAT;
	if ((InterSchemas::ip_loopy(O)) && (i == InterSchemas::ip_arity(O) - 1)) ok = CODE_PRIM_CAT;
	return ok;
}
