[InterSchemas::] Inter Schemas.

Building an inter schema, a form of annotated syntax tree.

@h Introduction.
See //What This Module Does// for an introduction to what an Inter schema is.
For this section of code, it's sufficient to know that an //inter_schema//
is an annotated syntax tree made up of //inter_schema_node// nodes.

Relatively few inter schemas are generated during Inform's run -- typically a
few hundred -- so they do not need to be stored compactly or compiled quickly.

=
typedef struct inter_schema {
	struct text_stream *converted_from; /* a copy of the source notation */
	struct inter_schema_node *node_tree; /* the structure */
	int mid_case; /* does this seem to be used inside a switch case? */
	int dereference_mode; /* emit from this in dereference-pointers mode */
	struct linked_list *parsing_errors; /* of |schema_parsing_error| */
	struct text_provenance provenance;
	CLASS_DEFINITION
} inter_schema;

@ =
inter_schema *InterSchemas::new(text_stream *source, text_provenance provenance) {
	inter_schema *sch = CREATE(inter_schema);
	sch->converted_from = Str::duplicate(source);
	sch->node_tree = NULL;
	sch->mid_case = FALSE;
	sch->dereference_mode = FALSE;
	sch->parsing_errors = NULL;
	sch->provenance = provenance;
	return sch;
}

@ Each node has one of the following |*_ISNT| types. (For a while eliminated nodes
were retained in the tree but given the no-op type |OH_NO_IT_ISNT|, but unfortunately
we now more efficiently remove them.)

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
	inter_ti isn_clarifier;							/* for |STATEMENT_ISNT| and |OPERATION_ISNT| only */
	int dir_clarifier;								/* for |DIRECTIVE_ISNT| only */
	struct inter_schema_token *expression_tokens;	/* for |EXPRESSION_ISNT| only */

	int semicolon_terminated;						/* for |EXPRESSION_ISNT| only */
	int unclosed;									/* for |CODE_ISNT| only */
	int unopened;									/* for |CODE_ISNT| only */

	int blocked_by_conditional;						/* used in code generation */

	struct text_provenance provenance; 				/* used for error reporting */
	CLASS_DEFINITION
} inter_schema_node;

@ =
inter_schema_node *InterSchemas::new_node(inter_schema *sch, int isnt,
	inter_schema_token *near_here) {
	inter_schema_node *isn = CREATE(inter_schema_node);
	isn->parent_schema = sch;

	isn->parent_node = NULL;
	isn->child_node = NULL;
	isn->next_node = NULL;
	isn->node_marked = FALSE;

	isn->isn_type = isnt;

	isn->expression_tokens = NULL;
	isn->isn_clarifier = 0;
	isn->dir_clarifier = -1;

	isn->semicolon_terminated = FALSE;
	isn->unclosed = FALSE;
	isn->unopened = FALSE;
	isn->blocked_by_conditional = FALSE;

	isn->provenance = (sch)?(sch->provenance):(Provenance::nowhere());
	if (near_here) Provenance::advance_line(&(isn->provenance), near_here->line_offset);
	return isn;
}

inter_schema_node *InterSchemas::new_node_near_node(inter_schema *sch, int isnt,
	inter_schema_node *near_here) {
	inter_schema_node *isn = InterSchemas::new_node(sch, isnt, NULL);
	if (near_here) isn->provenance = near_here->provenance;
	return isn;
}

@ Ordinarily, a |CODE_ISNT| node represents a complete block of I6 code.
For example, in
= (text as Inform 6)
	if (x == 1) { print "Hello!"; }
=
the print statement occurs inside a complete block, which will eventually
be represented as a |CODE_ISNT|. But some inline phrase definitions leave
blocks half-open. For example,
= (text as Inform 6)
	if (x == 1)
=
is a legal phrase definition: we read it as
= (text as Inform 6)
	if (x == 1) {
=
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
			inter_schema_node *code_isn =
				InterSchemas::new_node(isn->parent_schema, CODE_ISNT, NULL);
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
= (text as Inform 6)
	{X}:
=
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
@e DCOLON_ISTT				/* double-colon */

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

	inter_ti operation_primitive;				/* |OPERATOR_ISTT| only: e.g. |PLUS_BIP| for |+| */
	int reserved_word;							/* |RESERVED_ISTT| only: which one */
	int constant_number;						/* |NUMBER_ISTT| only: if non-negative, value of number */
	struct inter_name *as_quoted;				/* |IDENTIFIER_ISTT| only: the identified symbol if known */
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
	int line_offset;							/* counting lines for error message use */
	CLASS_DEFINITION
} inter_schema_token;

@ =
inter_schema_token *InterSchemas::new_token(int type, text_stream *material,
	inter_ti operation_primitive, int reserved_word, int n, int offset) {
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
	t->as_quoted = NULL;
	t->reserved_word = reserved_word;
	t->constant_number = n;
	t->preinsert = FALSE;
	t->postinsert = FALSE;
	t->line_offset = offset;
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
@e ORIGSOURCE_I6RW

@ The value of |inline_command|, in an |INLINE_ISTT| node, must be one of:

@e no_ISINC from 1
@e primitive_definition_ISINC
@e new_ISINC
@e new_list_of_ISINC
@e printing_routine_ISINC
@e next_routine_ISINC
@e previous_routine_ISINC
@e ranger_routine_ISINC
@e indexing_routine_ISINC
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
		sch->node_tree = InterSchemas::new_node(sch, EXPRESSION_ISNT, t);
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

@ When more drastic things happen, we need to fix all the ownership links:

=
void InterSchemas::changed_tokens_on(inter_schema_node *isn) {
	if (isn)
		for (inter_schema_token *l = isn->expression_tokens; l; l=l->next)
			l->owner = isn;
}

@ These are useful for scanning tokens:

=
int InterSchemas::opening_reserved_word(inter_schema_node *node) {
	inter_schema_token *f = InterSchemas::first_dark_token(node);
	if ((f) && (f->ist_type == RESERVED_ISTT)) return f->reserved_word;
	return 0;
}

int InterSchemas::opening_directive_word(inter_schema_node *node) {
	inter_schema_token *f = InterSchemas::first_dark_token(node);
	if ((f) && (f->ist_type == DIRECTIVE_ISTT)) return f->reserved_word;
	return 0;
}

inter_schema_token *InterSchemas::first_dark_token(inter_schema_node *node) {
	if (node == NULL) return NULL;
	inter_schema_token *n = node->expression_tokens;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	return n;
}

inter_schema_token *InterSchemas::next_dark_token(inter_schema_token *t) {
	if (t == NULL) return NULL;
	inter_schema_token *n = t->next;
	while ((n) && (n->ist_type == WHITE_SPACE_ISTT)) n = n->next;
	return n;
}

inter_schema_token *InterSchemas::second_dark_token(inter_schema_node *node) {
	return InterSchemas::next_dark_token(InterSchemas::first_dark_token(node));
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
	if (Provenance::is_somewhere(isn->provenance)) {
		LOG("%04d ", Provenance::get_line(isn->provenance));
	} else {
		LOG(".... ");
	}
	if (isn->blocked_by_conditional) LOG("XX"); else LOG("  ");
	for (int d = 0; d < depth; d++) LOG("    ");
	switch (isn->isn_type) {
		case STATEMENT_ISNT:
			LOG("* (statement) %S\n", Primitives::BIP_to_name(isn->isn_clarifier));
			break;
		case OPERATION_ISNT:
			LOG("* (operation) %S\n", Primitives::BIP_to_name(isn->isn_clarifier));
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
				case ORIGSOURCE_I6RW: LOG("#origsource"); break;
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
				if (Provenance::is_somewhere(isn->provenance)) {
					LOG("%04d ", Provenance::get_line(isn->provenance));
				} else {
					LOG(".... ");
				}
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
		case DCOLON_ISTT:		LOG("DCOLON      "); break;
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
}

@h Lint.
As can be seen, the |inter_schema| structure is quite complicated, and there
are numerous invariants it has to satisfy. As a precaution, then, we check that
all of these invariants hold before shipping out a compiled schema. This is
where the check is done:

=
void InterSchemas::lint(inter_schema *sch) {
	if ((sch) && (sch->parsing_errors == NULL)) {
		text_stream *err = InterSchemas::lint_isn(sch->node_tree, 0);
		if (err) {
			LOG("Lint fail: %S\n$1\n", err, sch);
			WRITE_TO(STDERR, "Lint fail: %S\n%S\n", err, sch->converted_from);
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
					case DCOLON_ISTT:		return I"contains double-colon node";
					case OPERATOR_ISTT:		return I"contains operator node";
				}
				if ((t->ist_type == INLINE_ISTT) && (t->inline_command == open_brace_ISINC))
					return I"contains manual open-brace";
				if ((t->ist_type == INLINE_ISTT) && (t->inline_command == close_brace_ISINC))
					return I"contains manual close-brace";
				if ((t->ist_type == NUMBER_ISTT) && (t->next) &&
					(t->next->ist_type == NUMBER_ISTT) && (asm == FALSE))
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
