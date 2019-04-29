[EmitInterSchemas::] Emitting Inter Schemas.

@h Compilation.

=
void EmitInterSchemas::emit(value_holster *VH, inter_schema *sch, void *opaque_state,
	int to_code, int to_val, inter_symbols_table *first_call, inter_symbols_table *second_call,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t, void *opaque_state, int prim_cat),
	void (*i7_source_handler)(value_holster *VH, text_stream *OUT, text_stream *S)) {
	if (sch->mid_case) { Emit::to_last_level(4); }
	int prim_cat = VAL_PRIM_CAT;
	if (to_code) prim_cat = CODE_PRIM_CAT;
	for (inter_schema_node *isn = sch->node_tree; isn; isn=isn->next_node)
		EmitInterSchemas::emit_inner(isn, VH, sch, opaque_state, prim_cat, first_call, second_call, inline_command_handler, i7_source_handler);
}

@ =
void EmitInterSchemas::emit_inner(inter_schema_node *isn, value_holster *VH,
	inter_schema *sch, void *opaque_state, int prim_cat, inter_symbols_table *first_call, inter_symbols_table *second_call,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t, void *opaque_state, int prim_cat),
	void (*i7_source_handler)(value_holster *VH, text_stream *OUT, text_stream *S)) {
	if (isn == NULL) return;
	switch (isn->isn_type) {
		case LABEL_ISNT: @<Label@>; break;
		case CODE_ISNT: @<Code block@>; break;
		case EVAL_ISNT: @<Eval block@>; break;
		case EXPRESSION_ISNT: @<Expression@>; break;
		case SUBEXPRESSION_ISNT: @<Subexpression@>; break;
		case STATEMENT_ISNT: @<Statement@>; break;
		case OPERATION_ISNT: @<Operation@>; break;
		case ASSEMBLY_ISNT: @<Assembly@>; break;
		case CALL_ISNT: @<Call@>; break;
		case DIRECTIVE_ISNT: @<Directive@>; break;
		default: internal_error("unknown schema node type");
	}
}

@<Label@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("label outside code");
	TEMPORARY_TEXT(L);
	WRITE_TO(L, ".");
	for (inter_schema_node *at = isn->child_node; at; at=at->next_node) {
		for (inter_schema_token *t = at->expression_tokens; t; t=t->next) {
			if (t->ist_type == IDENTIFIER_ISTT)
				WRITE_TO(L, "%S", t->material);
			else if ((t->ist_type == INLINE_ISTT) && (t->inline_command == label_ISINC)) {
				JumpLabels::write(L, t->operand);
			} else if ((t->ist_type == INLINE_ISTT) &&
				((t->inline_command == counter_up_ISINC) || (t->inline_command == counter_down_ISINC))) {
				value_holster VN = Holsters::new(INTER_DATA_VHMODE);
				if (inline_command_handler)
					(*inline_command_handler)(&VN, t, opaque_state, VAL_PRIM_CAT);
			} else internal_error("bad label stuff");
		}
	}
	Emit::place_label(Emit::reserve_label(L), TRUE);
	DISCARD_TEXT(L);

@<Code block@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("code block in expression");
	if (isn->unopened == FALSE) {
		Emit::code();
		Emit::down();
	}
	for (inter_schema_node *at = isn->child_node; at; at=at->next_node)
		EmitInterSchemas::emit_inner(at,
			VH, sch, opaque_state, CODE_PRIM_CAT, first_call, second_call,
			inline_command_handler, i7_source_handler);
	if (isn->unclosed == FALSE) {
		Emit::up();
	}
	if (isn->unopened) Emit::to_last_level(0);

@<Assembly@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("assembly in expression");
	inter_schema_node *at = isn->child_node;
	if (at) {
		text_stream *opcode_text = NULL;
		if (at->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *tok = at->expression_tokens;
			if ((tok->ist_type == OPCODE_ISTT) && (tok->next == NULL))
				opcode_text = tok->material;
		}
		if (opcode_text == NULL) internal_error("assembly malformed");
		Emit::inv_assembly(opcode_text);
		Emit::down();
		for (at = at->next_node; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at, VH, sch, opaque_state,
				VAL_PRIM_CAT, first_call, second_call,
				inline_command_handler, i7_source_handler);
		Emit::up();
	}

@<Call@> =
	if (isn->child_node) {
		inter_schema_node *at = isn->child_node;
		inter_symbol *to_call = NULL;
		if (at->isn_type == EXPRESSION_ISNT) {
			inter_schema_token *tok = at->expression_tokens;
			if ((tok->ist_type == IDENTIFIER_ISTT) && (tok->next == NULL)) {
				to_call = EmitInterSchemas::find_identifier(tok, first_call, second_call);
				if (Inter::Symbols::is_local(to_call)) to_call = NULL;
			}
		}
		if (to_call) {
			Emit::inv_call(to_call);
			at = at->next_node;
		} else {
			int argc = 0;
			for (inter_schema_node *n = isn->child_node; n; n=n->next_node) {
				if ((n->expression_tokens) && (n->expression_tokens->inline_command == combine_ISINC)) argc++;
				argc++;
			}
			switch (argc) {
				case 1: Emit::inv_primitive(indirect0_interp); break;
				case 2: Emit::inv_primitive(indirect1_interp); break;
				case 3: Emit::inv_primitive(indirect2_interp); break;
				case 4: Emit::inv_primitive(indirect3_interp); break;
				case 5: Emit::inv_primitive(indirect4_interp); break;
				default: internal_error("too many args for indirect call"); break;
			}
		}
		Emit::down();
		for (; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		Emit::up();
	}

@<Eval block@> =
	if ((prim_cat != CODE_PRIM_CAT) && (prim_cat != VAL_PRIM_CAT))
		internal_error("eval block outside evaluation context");
	if (isn->child_node == NULL) Emit::val(K_truth_state, LITERAL_IVAL, 1);
	else {
		int d = 0;
		for (inter_schema_node *at = isn->child_node; at; at=at->next_node) {
			if (at->next_node) {
				d++;
				Emit::inv_primitive(sequential_interp);
				Emit::down();
			}
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		}
		while (d > 0) { Emit::up(); d--; }
	}

@<Operation@> =
	if (prim_cat == REF_PRIM_CAT) { Emit::reference(); Emit::down(); }

	Emit::inv_primitive(isn->isn_clarifier);
	Emit::down();
	int pc = VAL_PRIM_CAT;
	if (InterSchemas::first_operand_ref(isn->isn_clarifier)) pc = REF_PRIM_CAT;
	EmitInterSchemas::emit_inner(isn->child_node,
		VH, sch, opaque_state, pc, first_call, second_call,
		inline_command_handler, i7_source_handler);
	if (InterSchemas::arity(isn->isn_clarifier) == 2)
		EmitInterSchemas::emit_inner(isn->child_node->next_node,
			VH, sch, opaque_state, VAL_PRIM_CAT,
			first_call, second_call,
			inline_command_handler, i7_source_handler);
	Emit::up();

	if (prim_cat == REF_PRIM_CAT) { Emit::up(); }

@<Subexpression@> =
	int d = 0;
	for (inter_schema_node *at = isn->child_node; at; at=at->next_node) {
		if (at->next_node) {
			d++;
			Emit::inv_primitive(sequential_interp);
			Emit::down();
		}
		EmitInterSchemas::emit_inner(at,
			VH, sch, opaque_state, prim_cat, first_call, second_call,
			inline_command_handler, i7_source_handler);
	}
	while (d > 0) { Emit::up(); d--; }

@<Statement@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("statement in expression");
	if (isn->isn_clarifier == case_interp) Emit::to_last_level(2);
	Emit::inv_primitive(isn->isn_clarifier);
	int arity = InterSchemas::ip_arity(isn->isn_clarifier);
	if (arity > 0) {
		Emit::down();
		if (isn->isn_clarifier == objectloop_interp)
			@<Add the objectloop range tokens@>;
		inter_schema_node *at = isn->child_node;
		inter_schema_node *last = NULL;
		int actual_arity = 0;
		for (int i = 0; ((at) && (i<arity)); i++) {
			actual_arity++;
			EmitInterSchemas::emit_inner(at, VH, sch, opaque_state,
				InterSchemas::ip_prim_cat(isn->isn_clarifier, i),
				first_call, second_call, inline_command_handler, i7_source_handler);
			last = at;
			at = at->next_node;
		}
		if (!((last) && (last->unclosed))) {
			Emit::up();
		}
	}

@<Add the objectloop range tokens@> =
	inter_schema_node *oc_node = isn->child_node;
	while ((oc_node) &&
		((oc_node->isn_type != OPERATION_ISNT) ||
		(oc_node->isn_clarifier != ofclass_interp)))
		oc_node = oc_node->child_node;
	if (oc_node) {
		inter_schema_node *var_node = oc_node->child_node;
		inter_schema_node *cl_node = var_node?(var_node->next_node):NULL;
		if ((var_node) && (cl_node)) {
			EmitInterSchemas::emit_inner(var_node, VH, sch, opaque_state, REF_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
			EmitInterSchemas::emit_inner(cl_node, VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		} else internal_error("malformed OC node");
	} else {
		inter_schema_node *var_node = isn->child_node;
		while ((var_node) && (var_node->isn_type != EXPRESSION_ISNT))
			var_node = var_node->child_node;
		if (var_node) {
			EmitInterSchemas::emit_inner(var_node, VH, sch, opaque_state, REF_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
			Emit::val_iname(K_value, Kinds::RunTime::I6_classname(K_object));
		} else internal_error("objectloop without visible variable");
	}

@<Expression@> =
	int cat_me = FALSE, lab_me = FALSE, print_ret_me = FALSE;
	int tc = 0; for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) tc++;
	if ((tc > 1) && (prim_cat == VAL_PRIM_CAT)) cat_me = TRUE;

	if ((tc == 1) && (prim_cat == CODE_PRIM_CAT) && (isn->expression_tokens->ist_type == DQUOTED_ISTT))
		print_ret_me = TRUE;

	if ((tc == 1) && (prim_cat == LAB_PRIM_CAT)) lab_me = TRUE;

	if (cat_me) { Emit::evaluation(); Emit::down(); }
	if (prim_cat == REF_PRIM_CAT) { Emit::reference(); Emit::down(); }

	for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
		switch (t->ist_type) {
			case IDENTIFIER_ISTT: {
				if (lab_me)
					Emit::lab(Emit::reserve_label(t->material));
				else {
					local_variable *lvar = LocalVariables::by_name_any(t->material);
					if (lvar) {
						inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
						Emit::val_symbol(K_value, lvar_s);
					} else {
						Emit::val_symbol(K_value, EmitInterSchemas::find_identifier(t, first_call, second_call));
					}
				}
				break;
			}
			case ASM_ARROW_ISTT:
				Emit::val_symbol(K_value, InterNames::to_symbol(Hierarchy::find(ASM_ARROW_HL)));
				break;
			case ASM_SP_ISTT:
				Emit::val_symbol(K_value, InterNames::to_symbol(Hierarchy::find(ASM_SP_HL)));
				break;
			case ASM_LABEL_ISTT:
				Emit::lab(Emit::reserve_label(t->material));
				break;
			case NUMBER_ISTT:
			case BIN_NUMBER_ISTT:
			case HEX_NUMBER_ISTT: {
				inter_t v1 = 0, v2 = 0;
				if (t->constant_number >= 0) { v1 = LITERAL_IVAL; v2 = (inter_t) t->constant_number; }
				else if (Inter::Types::read_I6_decimal(t->material, &v1, &v2) == FALSE)
					internal_error("bad number");
				Emit::val(K_number, v1, v2);
				break;
			}
			case REAL_NUMBER_ISTT:
				Emit::val_real_from_text(t->material);
				break;
			case DQUOTED_ISTT:
				if (print_ret_me) {
					Emit::inv_primitive(printret_interp);
					Emit::down();
				}
				Emit::val_text(t->material);
				if (print_ret_me) {
					Emit::up();
				}
				break;
			case SQUOTED_ISTT:
				if (Str::len(t->material) == 1) {
					Emit::val_char(Str::get_at(t->material, 0));
				} else {
					Emit::val_dword(t->material);
				}
				break;
			case I7_ISTT:
				(*i7_source_handler)(VH, NULL, t->material);
				break;
			case INLINE_ISTT:
				if (inline_command_handler)
					(*inline_command_handler)(VH, t, opaque_state, prim_cat);
				break;
			default:
				internal_error("bad expression token");
		}
	}

	if (cat_me) { Emit::up(); }
	if (prim_cat == REF_PRIM_CAT) { Emit::up(); }

@<Directive@> =
	LOG("Gen on dir!\n");
	InterSchemas::log_just(isn, 0);
	if (isn->dir_clarifier == ENDIF_I6RW) {
		Emit::entire_splat_code(I"#endif;");
	} else if (isn->dir_clarifier == IFNOT_I6RW) {
		Emit::entire_splat_code(I"#ifnot;");
	} else if ((isn->dir_clarifier == IFDEF_I6RW) || (isn->dir_clarifier == IFNDEF_I6RW)) {
		TEMPORARY_TEXT(T);
		switch(isn->dir_clarifier) {
			case IFDEF_I6RW: WRITE_TO(T, "#ifdef %S;", isn->child_node->expression_tokens->material); break;
			case IFNDEF_I6RW: WRITE_TO(T, "#ifndef %S;", isn->child_node->expression_tokens->material); break;
		}
		Emit::entire_splat_code(T);
		LOG("Resorted to %S\n", T);
		DISCARD_TEXT(T);
	} else {
		TEMPORARY_TEXT(T);
		switch(isn->dir_clarifier) {
			case IFTRUE_I6RW: WRITE_TO(T, "#iftrue "); break;
			case IFFALSE_I6RW: WRITE_TO(T, "#iffalse "); break;
			default: internal_error("unknown directive"); break;
		}
		WRITE_TO(T, "%S", isn->child_node->child_node->expression_tokens->material);
		if (isn->child_node->isn_clarifier == eq_interp) WRITE_TO(T, " == ");
		else if (isn->child_node->isn_clarifier == ne_interp) WRITE_TO(T, " ~= ");
		else if (isn->child_node->isn_clarifier == gt_interp) WRITE_TO(T, " > ");
		else if (isn->child_node->isn_clarifier == ge_interp) WRITE_TO(T, " >= ");
		else if (isn->child_node->isn_clarifier == lt_interp) WRITE_TO(T, " < ");
		else if (isn->child_node->isn_clarifier == le_interp) WRITE_TO(T, " <= ");
		else internal_error("unknown operator");
		WRITE_TO(T, "%S;", isn->child_node->child_node->next_node->expression_tokens->material);

		Emit::entire_splat_code(T);
		LOG("Resorted to %S\n", T);
		DISCARD_TEXT(T);
	}

@ =
inter_symbol *EmitInterSchemas::find_identifier(inter_schema_token *t, inter_symbols_table *first_call, inter_symbols_table *second_call) {
	if (t->as_quoted) return InterNames::to_symbol(t->as_quoted);
	return EmitInterSchemas::find_identifier_text(t->material, first_call, second_call);
}

inter_symbol *EmitInterSchemas::find_identifier_text(text_stream *S, inter_symbols_table *first_call, inter_symbols_table *second_call) {
	if (first_call) {
		inter_symbol *I = Emit::seek_symbol(first_call, S);
		if (I) return I;
	}
	if (second_call) {
		inter_symbol *I = Emit::seek_symbol(second_call, S);
		if (I) return I;
	}
	inter_symbol *I = Emit::seek_symbol(Emit::main_scope(), S);
	if (I) return I;
	I = InterNames::to_symbol(Hierarchy::find_by_name(S));
	if (I) return I;
	LOG("Defeated on %S\n", S);
	internal_error("unable to find identifier");
	return NULL;
}
