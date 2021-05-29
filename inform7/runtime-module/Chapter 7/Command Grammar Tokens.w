[RTCommandGrammarTokens::] Command Grammar Tokens.

Compiling single command parser tokens.

@ 

=
int ol_loop_counter = 0;
void RTCommandGrammarTokens::compile(gpr_kit *gprk, cg_token *cgt, int code_mode,
	inter_symbol *failure_label, int consult_mode) {

	if (CGTokens::is_literal(cgt)) @<Handle a literal word token@>;

	binary_predicate *bp = cgt->token_relation;
	if (bp) @<Handle a relation token@>;

	parse_node *spec = cgt->what_token_describes;
	if (cgt->defined_by) spec = ParsingPlugin::rvalue_from_command_grammar(cgt->defined_by);

	if (Specifications::is_kind_like(spec)) {
		kind *K = Node::get_kind_of_value(spec);
		if ((K) && (Kinds::Behaviour::is_object(K) == FALSE) &&
			(Kinds::eq(K, K_understanding) == FALSE) &&
			(RTKindConstructors::offers_I6_GPR(K)))
			@<Handle a kind token which is not an object@>;
	}

	if (CGTokens::is_I6_parser_token(cgt))
		@<Handle a built-in token@>;

	if (Specifications::is_description(spec))
		@<Handle a description token@>;

	if (cgt->defined_by)
		@<Handle an indirection through another grammar@>;

	if ((Node::is(spec, CONSTANT_NT)) && (Rvalues::is_object(spec)))
		@<Handle a constant object name token@>;

	internal_error("unimplemented token");
}

@<Handle a literal word token@> =
	int wn = Wordings::first_wn(CGTokens::text(cgt));
	if (code_mode) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
				TEMPORARY_TEXT(N)
				WRITE_TO(N, "%N", wn);
				EmitCode::val_dword(N);
				DISCARD_TEXT(N)
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	} else {
		TEMPORARY_TEXT(WT)
		WRITE_TO(WT, "%N", wn);
		EmitArrays::dword_entry(WT);
		DISCARD_TEXT(WT)
	}
	return;

@<Handle a relation token@> =
	EmitCode::call(Hierarchy::find(ARTICLEDESCRIPTORS_HL));
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->w_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	if (bp == R_containment) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
				EmitCode::inv(HAS_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(CONTAINER_HL));
				EmitCode::up();
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	}
	if (bp == R_support) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
				EmitCode::inv(HAS_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(SUPPORTER_HL));
				EmitCode::up();
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	}
	if ((bp == a_has_b_predicate) || (bp == R_wearing) ||
		(bp == R_carrying)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
				EmitCode::inv(HAS_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(ANIMATE_HL));
				EmitCode::up();
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	}
	if ((bp == R_containment) ||
		(bp == R_support) ||
		(bp == a_has_b_predicate) ||
		(bp == R_wearing) ||
		(bp == R_carrying)) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
		inter_symbol *exit_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)

		EmitCode::inv(OBJECTLOOP_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_iname(K_value, RTKindDeclarations::iname(K_object));
			EmitCode::inv(IN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				if (bp == R_carrying) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(HAS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->rv_s);
							EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(CONTINUE_BIP);
						EmitCode::up();
					EmitCode::up();
				}
				if (bp == R_wearing) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(NOT_BIP);
						EmitCode::down();
							EmitCode::inv(HAS_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->rv_s);
								EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
							EmitCode::up();
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(CONTINUE_BIP);
						EmitCode::up();
					EmitCode::up();
				}
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->rv_s);
							EmitCode::val_true();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(GT_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(JUMP_BIP);
						EmitCode::down();
							EmitCode::lab(exit_label);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();
		@<Jump to our doom@>;
		EmitCode::place_label(exit_label);
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();
	} else if (bp == R_incorporation) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
		inter_symbol *exit_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_CHILD_HL));
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(WHILE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->rv_s);
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->rv_s);
							EmitCode::val_true();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(GT_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(JUMP_BIP);
						EmitCode::down();
							EmitCode::lab(exit_label);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->rv_s);
						EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_SIBLING_HL));
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();
		@<Jump to our doom@>;
		EmitCode::place_label(exit_label);
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_number(0);
		EmitCode::up();
	} else if ((BinaryPredicates::get_reversal(bp) == R_containment) ||
		(BinaryPredicates::get_reversal(bp) == R_support) ||
		(BinaryPredicates::get_reversal(bp) == a_has_b_predicate) ||
		(BinaryPredicates::get_reversal(bp) == R_wearing) ||
		(BinaryPredicates::get_reversal(bp) == R_carrying)) {
		if (BinaryPredicates::get_reversal(bp) == R_carrying) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(HAS_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		}
		if (BinaryPredicates::get_reversal(bp) == R_wearing) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::inv(HAS_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(P_worn));
					EmitCode::up();
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
		}
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::call_symbol(Emit::get_veneer_symbol(PARENT_VSYMB));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, gprk->w_s);
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->rv_s);
					EmitCode::val_true();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->w_s);
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	} else if (BinaryPredicates::get_reversal(bp) == R_incorporation) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(COMPONENT_PARENT_HL));
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, gprk->w_s);
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->rv_s);
					EmitCode::val_true();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::val_symbol(K_value, gprk->w_s);
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
	} else {
		i6_schema *i6s;
		int reverse = FALSE;
		int continue_loop_on_fail = TRUE;

		i6s = BinaryPredicates::get_test_function(bp);
		LOGIF(GRAMMAR_CONSTRUCTION, "Read I6s $i from $2\n", i6s, bp);
		if ((i6s == NULL) && (BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp)))) {
			reverse = TRUE;
			i6s = BinaryPredicates::get_test_function(BinaryPredicates::get_reversal(bp));
			LOGIF(GRAMMAR_CONSTRUCTION, "But read I6s $i from reversal\n", i6s);
		}

		if (i6s) {
			kind *K = BinaryPredicates::term_kind(bp, 1);
			if (Kinds::Behaviour::is_subkind_of_object(K)) {
				LOGIF(GRAMMAR_CONSTRUCTION, "Term 1 of BP is %u\n", K);
				EmitCode::inv(OBJECTLOOPX_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								pcalc_term rv_term = Terms::new_constant(
									Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, gprk->rv_lv));
								pcalc_term self_term = Terms::new_constant(
									Rvalues::new_self_object_constant());
								if (reverse)
									CompileSchemas::from_terms_in_val_context(i6s, &rv_term, &self_term);
								else
									CompileSchemas::from_terms_in_val_context(i6s, &self_term, &rv_term);
				continue_loop_on_fail = TRUE;
			}
		} else {
			property *prn = ExplicitRelations::get_i6_storage_property(bp);
			reverse = FALSE;
			if (BinaryPredicates::is_the_wrong_way_round(bp)) reverse = TRUE;
			if (ExplicitRelations::get_form_of_relation(bp) == Relation_VtoO) {
				if (reverse) reverse = FALSE; else reverse = TRUE;
			}
			if (prn) {
				if (reverse) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(PROVIDES_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
							EmitCode::val_iname(K_value, RTProperties::iname(prn));
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();

							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_symbol(K_value, gprk->rv_s);
								EmitCode::inv(PROPERTYVALUE_BIP);
								EmitCode::down();
									EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
									EmitCode::val_iname(K_value, RTProperties::iname(prn));
								EmitCode::up();
							EmitCode::up();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, gprk->rv_s);

					continue_loop_on_fail = FALSE;
				} else {
					kind *K = BinaryPredicates::term_kind(bp, 1);
					EmitCode::inv(OBJECTLOOPX_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->rv_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::inv(AND_BIP);
									EmitCode::down();
										EmitCode::inv(PROVIDES_BIP);
										EmitCode::down();
											EmitCode::val_symbol(K_value, gprk->rv_s);
											EmitCode::val_iname(K_value, RTProperties::iname(prn));
										EmitCode::up();
										EmitCode::inv(EQ_BIP);
										EmitCode::down();
											EmitCode::inv(PROPERTYVALUE_BIP);
											EmitCode::down();
												EmitCode::val_symbol(K_value, gprk->rv_s);
												EmitCode::val_iname(K_value, RTProperties::iname(prn));
											EmitCode::up();
											EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
										EmitCode::up();
									EmitCode::up();
					continue_loop_on_fail = TRUE;
				}
			}
		}

							EmitCode::val_false();
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							if (continue_loop_on_fail == FALSE) {
								@<Jump to our doom@>;
							} else {
								EmitCode::inv(CONTINUE_BIP);
							}
						EmitCode::up();
					EmitCode::up();

					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::up();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
						EmitCode::inv(PLUS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk->w_s);
							EmitCode::call(Hierarchy::find(TRYGIVENOBJECT_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->rv_s);
								EmitCode::val_true();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();

					TEMPORARY_TEXT(L)
					WRITE_TO(L, ".ol_mm_%d", ol_loop_counter++);
					inter_symbol *exit_label = EmitCode::reserve_label(L);
					DISCARD_TEXT(L)

					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GT_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(JUMP_BIP);
							EmitCode::down();
								EmitCode::lab(exit_label);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();

				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
			@<Jump to our doom@>;
			EmitCode::place_label(exit_label);
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_number(0);
			EmitCode::up();
		}
		return;

@<Handle a kind token which is not an object@> =
	text_stream *GPR_fn_iname = RTKindConstructors::get_explicit_I6_GPR(K);
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
				if (Str::len(GPR_fn_iname) > 0)
					EmitCode::val_iname(K_value, Produce::find_by_name(Emit::tree(), GPR_fn_iname));
				else
					EmitCode::val_iname(K_value, RTKindConstructors::get_kind_GPR_iname(K));
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
		EmitCode::up();
	} else {
		if (Str::len(GPR_fn_iname) > 0)
			EmitArrays::iname_entry(Produce::find_by_name(Emit::tree(), GPR_fn_iname));
		else
			EmitArrays::iname_entry(RTKindConstructors::get_kind_GPR_iname(K));
	}
	return;

@<Handle a built-in token@> =
	inter_name *i6_token_iname = RTCommandGrammars::iname_for_I6_parser_token(cgt);
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(ELEMENTARY_TT_HL));
				EmitCode::val_iname(K_value, i6_token_iname);
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_symbol(K_value, gprk->w_s);
		EmitCode::up();
	} else {
		EmitArrays::iname_entry(i6_token_iname);
	}
	return;

@<Handle a description token@> =
	if (Descriptions::is_qualified(spec)) {
		if (code_mode) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->w_s);
				EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
				EmitCode::down();
					UnderstandFilterTokens::compile_id(cgt->noun_filter);
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->w_s);
					EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
				EmitCode::up();
				@<Then jump to our doom@>;
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->rv_s);
				EmitCode::val_symbol(K_value, gprk->w_s);
			EmitCode::up();
		} else {
			UnderstandFilterTokens::emit_id(cgt->noun_filter);
		}
	} else {
		kind *K = Specifications::to_kind(spec);
		if (RTKindConstructors::offers_I6_GPR(K)) {
			text_stream *i6_gpr_name = RTKindConstructors::get_explicit_I6_GPR(K);
			if (code_mode) {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->w_s);
					EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
						if (Str::len(i6_gpr_name) > 0)
							EmitCode::val_iname(K_value, Produce::find_by_name(Emit::tree(), i6_gpr_name));
						else
							EmitCode::val_iname(K_value, RTKindConstructors::get_kind_GPR_iname(K));
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(NE_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
					EmitCode::up();
					@<Then jump to our doom@>;
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_iname(K_number, Hierarchy::find(GPR_NUMBER_HL));
				EmitCode::up();
			} else {
				if (Str::len(i6_gpr_name) > 0)
					EmitArrays::iname_entry(Produce::find_by_name(Emit::tree(), i6_gpr_name));
				else
					EmitArrays::iname_entry(RTKindConstructors::get_kind_GPR_iname(K));
			}
		} else if (Kinds::Behaviour::is_object(K)) {
			if (code_mode) {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->w_s);
					EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
					EmitCode::down();
						UnderstandFilterTokens::compile_id(cgt->noun_filter);
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->w_s);
						EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
					EmitCode::up();
					@<Then jump to our doom@>;
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
			} else {
				UnderstandFilterTokens::emit_id(cgt->noun_filter);
			}
		} else internal_error("no token for description");
	}
	return;

@<Handle an indirection through another grammar@> =
	command_grammar *cg = cgt->defined_by;
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
				EmitCode::val_iname(K_value, RTCommandGrammars::get_cg_token_iname(cg));
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_PREPOSITION_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->rv_s);
					EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitArrays::iname_entry(RTCommandGrammars::get_cg_token_iname(cg));
	}
	return;

@<Handle a constant object name token@> =
	if (code_mode) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->w_s);
			EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
			EmitCode::down();
				UnderstandFilterTokens::compile_id(cgt->noun_filter);
			EmitCode::up();
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk->w_s);
				EmitCode::val_iname(K_number, Hierarchy::find(GPR_FAIL_HL));
			EmitCode::up();
			@<Then jump to our doom@>;
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->rv_s);
			EmitCode::val_symbol(K_value, gprk->w_s);
		EmitCode::up();
	} else {
		UnderstandFilterTokens::emit_id(cgt->noun_filter);
	}
	return;

@<Then jump to our doom@> =
	EmitCode::code();
	EmitCode::down();
		@<Jump to our doom@>;
	EmitCode::up();

@<Jump to our doom@> =
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(failure_label);
	EmitCode::up();
