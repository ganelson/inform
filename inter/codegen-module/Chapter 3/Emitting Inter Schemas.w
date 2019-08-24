[EmitInterSchemas::] Emitting Inter Schemas.

@h Compilation.

=
void EmitInterSchemas::emit(value_holster *VH, inter_schema *sch, void *opaque_state,
	int to_code, int to_val, inter_symbols_table *first_call, inter_symbols_table *second_call,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t, void *opaque_state, int prim_cat),
	void (*i7_source_handler)(value_holster *VH, text_stream *OUT, text_stream *S)) {
	if (sch->mid_case) { Produce::to_last_level(4); }
	int prim_cat = VAL_PRIM_CAT;
	if (to_code) prim_cat = CODE_PRIM_CAT;
	int again = TRUE;
	while (again) {
		again = FALSE;
		for (inter_schema_node *isn = sch->node_tree; isn; isn=isn->next_node)
			if (EmitInterSchemas::process_conditionals(isn, first_call, second_call))
				again = TRUE;
	}
	for (inter_schema_node *isn = sch->node_tree; isn; isn=isn->next_node)
		EmitInterSchemas::emit_inner(isn, VH, sch, opaque_state, prim_cat, first_call, second_call, inline_command_handler, i7_source_handler);
}

@ =
int EmitInterSchemas::process_conditionals(inter_schema_node *isn, inter_symbols_table *first_call, inter_symbols_table *second_call) {
	if (isn == NULL) return FALSE;
	if (isn->blocked_by_conditional) return FALSE;
	if (isn->isn_type == DIRECTIVE_ISNT) @<Directive@>;
	for (isn=isn->child_node; isn; isn=isn->next_node)
		if (EmitInterSchemas::process_conditionals(isn, first_call, second_call))
			return TRUE;
	return FALSE;
}

@<Directive@> =
	if ((isn->dir_clarifier == IFDEF_I6RW) ||
		(isn->dir_clarifier == IFNDEF_I6RW) ||
		(isn->dir_clarifier == IFTRUE_I6RW) ||
		(isn->dir_clarifier == IFFALSE_I6RW)) {
		LOGIF(SCHEMA_COMPILATION, "Conditional directive in schema!\n");
		inter_schema_node *ifnot_node = NULL, *endif_node = NULL;
		inter_schema_node *at = isn->next_node;
		while (at) {
			if (at->blocked_by_conditional == FALSE) {
				if (at->dir_clarifier == IFDEF_I6RW) { isn = at; ifnot_node = NULL; }
				if (at->dir_clarifier == IFNDEF_I6RW) { isn = at; ifnot_node = NULL; }
				if (at->dir_clarifier == IFTRUE_I6RW) { isn = at; ifnot_node = NULL; }
				if (at->dir_clarifier == IFFALSE_I6RW) { isn = at; ifnot_node = NULL; }
				if (at->dir_clarifier == IFNOT_I6RW) ifnot_node = at;
				if (at->dir_clarifier == ENDIF_I6RW) { endif_node = at; break; }
			}
			at = at->next_node;
		}
		if (endif_node == NULL) internal_error("no matching #endif");
		
		text_stream *symbol_to_check = NULL;
		text_stream *value_to_check = NULL;
		inter_t operation_to_check = 0;
		if ((isn->dir_clarifier == IFDEF_I6RW) ||
			(isn->dir_clarifier == IFNDEF_I6RW)) {
			symbol_to_check = isn->child_node->expression_tokens->material;
		} else {
			inter_schema_node *to_eval = isn->child_node;
			while ((to_eval) && (to_eval->isn_type == SUBEXPRESSION_ISNT))
				to_eval = to_eval->child_node;
			if ((to_eval == NULL) || (to_eval->child_node->expression_tokens == NULL))
				internal_error("bad iftrue");
			symbol_to_check = to_eval->child_node->expression_tokens->material;
			operation_to_check = to_eval->isn_clarifier;
			value_to_check = to_eval->child_node->next_node->expression_tokens->material;
		}
		LOGIF(SCHEMA_COMPILATION, "Means checking %S\n", symbol_to_check);
		if (value_to_check) LOGIF(SCHEMA_COMPILATION, "Against %S\n", value_to_check);
		int val = -1, def = FALSE;
		if (Str::eq(symbol_to_check, I"#version_number")) { val = 8; def = TRUE; }
		else if (Str::eq(symbol_to_check, I"STRICT_MODE")) { def = TRUE; }
		else {
			inter_symbol *symb = EmitInterSchemas::find_identifier_text(symbol_to_check, NULL, second_call);
			while ((symb) && (symb->equated_to)) symb = symb->equated_to;
			LOGIF(SCHEMA_COMPILATION, "Symb is $3\n", symb);
			if (Inter::Symbols::is_defined(symb)) {
				def = TRUE;
				val = Inter::Symbols::evaluate_to_int(symb);
			}			
		}
		LOGIF(SCHEMA_COMPILATION, "Defined: %d, value: %d\n", def, val);
		
		int decision = TRUE;
		
		if ((isn->dir_clarifier == IFNDEF_I6RW)
			|| (isn->dir_clarifier == IFDEF_I6RW)) decision = def;
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
		
		if (isn->dir_clarifier == IFNDEF_I6RW) decision = decision?FALSE:TRUE;
		if (isn->dir_clarifier == IFFALSE_I6RW) decision = decision?FALSE:TRUE;
		isn->blocked_by_conditional = TRUE;
		endif_node->blocked_by_conditional = TRUE;
		if (ifnot_node) ifnot_node->blocked_by_conditional = TRUE;
		if (decision) {
			inter_schema_node *at = ifnot_node;
			while ((at) && (at != endif_node)) {
				at->blocked_by_conditional = TRUE;
				at = at->next_node;
			}
		} else {
			inter_schema_node *at = isn;
			while ((at) && (at != endif_node) && (at != ifnot_node)) {
				at->blocked_by_conditional = TRUE;
				at = at->next_node;
			}
		}
		if (Log::aspect_switched_on(SCHEMA_COMPILATION_DA)) {
			LOG("--- Resulting in: ---\n");
			for (inter_schema_node *at = isn; at; at = at->next_node)
				InterSchemas::log_just(at, 0);
			LOG("------\n");
		}
		return TRUE;
	}

@ =
void EmitInterSchemas::emit_inner(inter_schema_node *isn, value_holster *VH,
	inter_schema *sch, void *opaque_state, int prim_cat, inter_symbols_table *first_call, inter_symbols_table *second_call,
	void (*inline_command_handler)(value_holster *VH, inter_schema_token *t, void *opaque_state, int prim_cat),
	void (*i7_source_handler)(value_holster *VH, text_stream *OUT, text_stream *S)) {
	if (isn == NULL) return;
	if (isn->blocked_by_conditional) return;
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
		case MESSAGE_ISNT: @<Message@>; break;
		case CALLMESSAGE_ISNT: @<Call-message@>; break;
		case DIRECTIVE_ISNT: @<Non-conditional directive@>; break;
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
				#ifdef CORE_MODULE
				JumpLabels::write(L, t->operand);
				#endif
				#ifndef CORE_MODULE
				internal_error("label namespaces are unavailable in assimilation mode");
				#endif
			} else if ((t->ist_type == INLINE_ISTT) &&
				((t->inline_command == counter_up_ISINC) || (t->inline_command == counter_down_ISINC))) {
				value_holster VN = Holsters::new(INTER_DATA_VHMODE);
				if (inline_command_handler)
					(*inline_command_handler)(&VN, t, opaque_state, VAL_PRIM_CAT);
			} else internal_error("bad label stuff");
		}
	}
	Produce::place_label(Produce::reserve_label(L));
	DISCARD_TEXT(L);

@<Code block@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("code block in expression");
	if (isn->unopened == FALSE) {
		Produce::code();
		Produce::down();
	}
	for (inter_schema_node *at = isn->child_node; at; at=at->next_node)
		EmitInterSchemas::emit_inner(at,
			VH, sch, opaque_state, CODE_PRIM_CAT, first_call, second_call,
			inline_command_handler, i7_source_handler);
	if (isn->unclosed == FALSE) {
		Produce::up();
	}
	if (isn->unopened) Produce::to_last_level(0);

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
		Produce::inv_assembly(opcode_text);
		Produce::down();
		for (at = at->next_node; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at, VH, sch, opaque_state,
				VAL_PRIM_CAT, first_call, second_call,
				inline_command_handler, i7_source_handler);
		Produce::up();
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
			Produce::inv_call(to_call);
			at = at->next_node;
		} else {
			int argc = 0;
			for (inter_schema_node *n = isn->child_node; n; n=n->next_node) {
				if ((n->expression_tokens) && (n->expression_tokens->inline_command == combine_ISINC)) argc++;
				argc++;
			}
			switch (argc) {
				case 1: Produce::inv_primitive(Produce::opcode(INDIRECT0_BIP)); break;
				case 2: Produce::inv_primitive(Produce::opcode(INDIRECT1_BIP)); break;
				case 3: Produce::inv_primitive(Produce::opcode(INDIRECT2_BIP)); break;
				case 4: Produce::inv_primitive(Produce::opcode(INDIRECT3_BIP)); break;
				case 5: Produce::inv_primitive(Produce::opcode(INDIRECT4_BIP)); break;
				default: internal_error("too many args for indirect call"); break;
			}
		}
		Produce::down();
		for (; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		Produce::up();
	}

@<Message@> =
	if (isn->child_node) {
		inter_schema_node *at = isn->child_node;
		int argc = 0;
		for (inter_schema_node *n = isn->child_node; n; n=n->next_node) argc++;
		switch (argc) {
			case 2: Produce::inv_primitive(Produce::opcode(MESSAGE0_BIP)); break;
			case 3: Produce::inv_primitive(Produce::opcode(MESSAGE1_BIP)); break;
			case 4: Produce::inv_primitive(Produce::opcode(MESSAGE2_BIP)); break;
			case 5: Produce::inv_primitive(Produce::opcode(MESSAGE3_BIP)); break;
			default: internal_error("too many args for message"); break;
		}
		Produce::down();
		for (; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		Produce::up();
	}

@<Call-message@> =
	if (isn->child_node) {
		inter_schema_node *at = isn->child_node;
		int argc = 0;
		for (inter_schema_node *n = isn->child_node; n; n=n->next_node) argc++;
		switch (argc) {
			case 1: Produce::inv_primitive(Produce::opcode(CALLMESSAGE0_BIP)); break;
			case 2: Produce::inv_primitive(Produce::opcode(CALLMESSAGE1_BIP)); break;
			case 3: Produce::inv_primitive(Produce::opcode(CALLMESSAGE2_BIP)); break;
			case 4: Produce::inv_primitive(Produce::opcode(CALLMESSAGE3_BIP)); break;
			default: internal_error("too many args for call-message"); break;
		}
		Produce::down();
		for (; at; at=at->next_node)
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		Produce::up();
	}

@<Eval block@> =
	if ((prim_cat != CODE_PRIM_CAT) && (prim_cat != VAL_PRIM_CAT))
		internal_error("eval block outside evaluation context");
	if (isn->child_node == NULL) Produce::val(K_value, LITERAL_IVAL, 1);
	else {
		int d = 0;
		for (inter_schema_node *at = isn->child_node; at; at=at->next_node) {
			if (at->next_node) {
				d++;
				Produce::inv_primitive(Produce::opcode(SEQUENTIAL_BIP));
				Produce::down();
			}
			EmitInterSchemas::emit_inner(at,
				VH, sch, opaque_state, VAL_PRIM_CAT,
				first_call, second_call, inline_command_handler, i7_source_handler);
		}
		while (d > 0) { Produce::up(); d--; }
	}

@<Operation@> =
	if (prim_cat == REF_PRIM_CAT) { Produce::reference(); Produce::down(); }

	Produce::inv_primitive(Produce::opcode(isn->isn_clarifier));
	Produce::down();
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
	Produce::up();

	if (prim_cat == REF_PRIM_CAT) { Produce::up(); }

@<Subexpression@> =
	int d = 0;
	for (inter_schema_node *at = isn->child_node; at; at=at->next_node) {
		if (at->next_node) {
			d++;
			Produce::inv_primitive(Produce::opcode(SEQUENTIAL_BIP));
			Produce::down();
		}
		EmitInterSchemas::emit_inner(at,
			VH, sch, opaque_state, prim_cat, first_call, second_call,
			inline_command_handler, i7_source_handler);
	}
	while (d > 0) { Produce::up(); d--; }

@<Statement@> =
	if (prim_cat != CODE_PRIM_CAT) internal_error("statement in expression");
	if (isn->isn_clarifier == CASE_BIP) Produce::to_last_level(2);
	Produce::inv_primitive(Produce::opcode(isn->isn_clarifier));
	int arity = InterSchemas::ip_arity(isn->isn_clarifier);
	if (arity > 0) {
		Produce::down();
		if (isn->isn_clarifier == OBJECTLOOP_BIP)
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
			Produce::up();
		}
	}

@<Add the objectloop range tokens@> =
	inter_schema_node *oc_node = isn->child_node;
	while ((oc_node) &&
		((oc_node->isn_type != OPERATION_ISNT) ||
		(oc_node->isn_clarifier != OFCLASS_BIP)))
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
			#ifdef CORE_MODULE
			Produce::val_iname(K_value, Kinds::RunTime::I6_classname(K_object));
			#endif
			#ifndef CORE_MODULE
			inter_symbol *plug = Inter::Connectors::find_plug(Produce::tree(), I"OBJECT_TY");
			if (plug == NULL) plug = Inter::Connectors::plug(Produce::tree(), I"OBJECT_TY");
			Produce::val_symbol(K_value, plug);
			#endif
		} else internal_error("objectloop without visible variable");
	}

@<Expression@> =
	int cat_me = FALSE, lab_me = FALSE, print_ret_me = FALSE;
	int tc = 0; for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) tc++;
	if ((tc > 1) && (prim_cat == VAL_PRIM_CAT)) cat_me = TRUE;

	if ((tc == 1) && (prim_cat == CODE_PRIM_CAT) && (isn->expression_tokens->ist_type == DQUOTED_ISTT))
		print_ret_me = TRUE;

	if ((tc == 1) && (prim_cat == LAB_PRIM_CAT)) lab_me = TRUE;

	if (cat_me) { Produce::evaluation(); Produce::down(); }
	if (prim_cat == REF_PRIM_CAT) { Produce::reference(); Produce::down(); }

	for (inter_schema_token *t = isn->expression_tokens; t; t=t->next) {
		switch (t->ist_type) {
			case IDENTIFIER_ISTT: {
				if (lab_me)
					Produce::lab(Produce::reserve_label(t->material));
				else {
					#ifdef CORE_MODULE
					local_variable *lvar = LocalVariables::by_name_any(t->material);
					if (lvar) {
						inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
						Produce::val_symbol(K_value, lvar_s);
					} else {
						Produce::val_symbol(K_value, EmitInterSchemas::find_identifier(t, first_call, second_call));
					}
					#endif
					#ifndef CORE_MODULE
						Produce::val_symbol(K_value, EmitInterSchemas::find_identifier(t, first_call, second_call));
					#endif
				}
				break;
			}
			case ASM_ARROW_ISTT:
				Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_ARROW_VSYMB));
				break;
			case ASM_SP_ISTT:
				Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_SP_VSYMB));
				break;
			case ASM_NEGATED_LABEL_ISTT:
				if (Str::eq(t->material, I"rtrue")) 
					Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_NEG_RTRUE_VSYMB));
				else if (Str::eq(t->material, I"rfalse")) 
					Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_NEG_RFALSE_VSYMB));
				else {
					Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_NEG_VSYMB));
					Produce::lab(Produce::reserve_label(t->material));
				}
				break;
			case ASM_LABEL_ISTT:
				if (Str::eq(t->material, I"rtrue")) 
					Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_RTRUE_VSYMB));
				else if (Str::eq(t->material, I"rfalse")) 
					Produce::val_symbol(K_value, Packaging::veneer_symbol(ASM_RFALSE_VSYMB));
				else Produce::lab(Produce::reserve_label(t->material));
				break;
			case NUMBER_ISTT:
			case BIN_NUMBER_ISTT:
			case HEX_NUMBER_ISTT: {
				inter_t v1 = 0, v2 = 0;
				if (t->constant_number >= 0) { v1 = LITERAL_IVAL; v2 = (inter_t) t->constant_number; }
				else if (Inter::Types::read_I6_decimal(t->material, &v1, &v2) == FALSE)
					internal_error("bad number");
				Produce::val(K_value, v1, v2);
				break;
			}
			case REAL_NUMBER_ISTT:
				Produce::val_real_from_text(t->material);
				break;
			case DQUOTED_ISTT:
				if (print_ret_me) {
					Produce::inv_primitive(Produce::opcode(PRINTRET_BIP));
					Produce::down();
				}
				Produce::val_text(t->material);
				if (print_ret_me) {
					Produce::up();
				}
				break;
			case SQUOTED_ISTT:
				if (Str::len(t->material) == 1) {
					Produce::val_char(Str::get_at(t->material, 0));
				} else {
					Produce::val_dword(t->material);
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

	if (cat_me) { Produce::up(); }
	if (prim_cat == REF_PRIM_CAT) { Produce::up(); }

@<Non-conditional directive@> =
	internal_error("unknown directive");

@ =
inter_symbol *EmitInterSchemas::find_identifier(inter_schema_token *t, inter_symbols_table *first_call, inter_symbols_table *second_call) {
	if (t->as_quoted) return InterNames::to_symbol(t->as_quoted);
	return EmitInterSchemas::find_identifier_text(t->material, first_call, second_call);
}

inter_symbol *EmitInterSchemas::find_identifier_text(text_stream *S, inter_symbols_table *first_call, inter_symbols_table *second_call) {
	if (Str::get_at(S, 0) == 0x00A7) {
		TEMPORARY_TEXT(SR);
		Str::copy(SR, S);
		Str::delete_first_character(SR);
		Str::delete_last_character(SR);
		inter_symbol *I = Inter::SymbolsTables::url_name_to_symbol(Produce::tree(), NULL, SR);
		DISCARD_TEXT(SR);
		if (I) return I;
	}
	if (first_call) {
		inter_symbol *I = Produce::seek_symbol(first_call, S);
		if (I) return I;
	}
	if (second_call) {
		inter_symbol *I = Produce::seek_symbol(second_call, S);
		if (I) return I;
	}
	inter_symbol *I = Veneer::find(Packaging::incarnate(Packaging::veneer()), Packaging::veneer_booknark(), S, Produce::kind_to_symbol(NULL));
	if (I) return I;
	I = Produce::seek_symbol(Produce::connectors_scope(), S);
	if (I) return I;
	I = Produce::seek_symbol(Produce::main_scope(), S);
	if (I) return I;
	I = InterNames::to_symbol(Produce::find_by_name(S));
	if (I) return I;
	LOG("Defeated on %S\n", S);
	internal_error("unable to find identifier");
	return NULL;
}
