[PL::Parsing::Tokens::Values::] Tokens Parsing Values.

In the argot of Inform 6, GPR stands for General Parsing Routine,
and I7 makes heavy use of GPR tokens to achieve its ends. This section is
where the necessary I6 routines are compiled.

@ =
typedef struct gpr_kit {
	inter_symbol *cur_addr_s;
	inter_symbol *cur_len_s;
	inter_symbol *cur_word_s;
	inter_symbol *f_s;
	inter_symbol *g_s;
	inter_symbol *group_wn_s;
	inter_symbol *instance_s;
	inter_symbol *matched_number_s;
	inter_symbol *mid_word_s;
	inter_symbol *n_s;
	inter_symbol *original_wn_s;
	inter_symbol *pass_s;
	inter_symbol *pass1_n_s;
	inter_symbol *pass2_n_s;
	inter_symbol *range_from_s;
	inter_symbol *range_words_s;
	inter_symbol *rv_s;
	local_variable *rv_lv;
	inter_symbol *sgn_s;
	inter_symbol *spn_s;
	inter_symbol *ss_s;
	inter_symbol *tot_s;
	inter_symbol *try_from_wn_s;
	inter_symbol *v_s;
	inter_symbol *w_s;
	inter_symbol *wpos_s;
	inter_symbol *x_s;
} gpr_kit;

gpr_kit PL::Parsing::Tokens::Values::new_kit(void) {
	gpr_kit gprk;
	gprk.cur_addr_s = NULL;
	gprk.cur_len_s = NULL;
	gprk.cur_word_s = NULL;
	gprk.f_s = NULL;
	gprk.g_s = NULL;
	gprk.group_wn_s = NULL;
	gprk.instance_s = NULL;
	gprk.matched_number_s = NULL;
	gprk.mid_word_s = NULL;
	gprk.n_s = NULL;
	gprk.original_wn_s = NULL;
	gprk.pass_s = NULL;
	gprk.pass1_n_s = NULL;
	gprk.pass2_n_s = NULL;
	gprk.range_from_s = NULL;
	gprk.range_words_s = NULL;
	gprk.rv_s = NULL;
	gprk.rv_lv = NULL;
	gprk.sgn_s = NULL;
	gprk.spn_s = NULL;
	gprk.ss_s = NULL;
	gprk.tot_s = NULL;
	gprk.try_from_wn_s = NULL;
	gprk.v_s = NULL;
	gprk.w_s = NULL;
	gprk.wpos_s = NULL;
	gprk.x_s = NULL;
	return gprk;
}

void PL::Parsing::Tokens::Values::add_instance_call(gpr_kit *gprk) {
	gprk->instance_s = LocalVariables::add_named_call_as_symbol(I"instance");
}

void PL::Parsing::Tokens::Values::add_range_calls(gpr_kit *gprk) {
	gprk->range_from_s = LocalVariables::add_internal_local_c_as_symbol(I"range_from", "call parameter: word number of snippet start");
	gprk->range_words_s = LocalVariables::add_internal_local_c_as_symbol(I"range_words", "call parameter: snippet length");
}

void PL::Parsing::Tokens::Values::add_original(gpr_kit *gprk) {
	gprk->original_wn_s = LocalVariables::add_internal_local_as_symbol(I"original_wn");
}

void PL::Parsing::Tokens::Values::add_standard_set(gpr_kit *gprk) {
	gprk->group_wn_s = LocalVariables::add_internal_local_as_symbol(I"group_wn");
	gprk->v_s = LocalVariables::add_internal_local_as_symbol(I"v");
	gprk->w_s = LocalVariables::add_internal_local_as_symbol(I"w");
	gprk->rv_s = LocalVariables::add_internal_local_as_symbol_noting(I"rv", &(gprk->rv_lv));
}

void PL::Parsing::Tokens::Values::add_lp_vars(gpr_kit *gprk) {
	gprk->wpos_s = LocalVariables::add_internal_local_as_symbol(I"wpos");
	gprk->mid_word_s = LocalVariables::add_internal_local_as_symbol(I"mid_word");
	gprk->matched_number_s = LocalVariables::add_internal_local_as_symbol(I"matched_number");
	gprk->cur_word_s = LocalVariables::add_internal_local_as_symbol(I"cur_word");
	gprk->cur_len_s = LocalVariables::add_internal_local_as_symbol(I"cur_len");
	gprk->cur_addr_s = LocalVariables::add_internal_local_as_symbol(I"cur_addr");
	gprk->sgn_s = LocalVariables::add_internal_local_as_symbol(I"sgn");
	gprk->tot_s = LocalVariables::add_internal_local_as_symbol(I"tot");
	gprk->f_s = LocalVariables::add_internal_local_as_symbol(I"f");
	gprk->x_s = LocalVariables::add_internal_local_as_symbol(I"x");
}

void PL::Parsing::Tokens::Values::add_parse_name_vars(gpr_kit *gprk) {
	gprk->original_wn_s = LocalVariables::add_internal_local_c_as_symbol(I"original_wn", "first word of text parsed");
	gprk->group_wn_s = LocalVariables::add_internal_local_c_as_symbol(I"group_wn", "first word matched against A/B/C/... disjunction");
	gprk->try_from_wn_s = LocalVariables::add_internal_local_c_as_symbol(I"try_from_wn", "position to try matching from");
	gprk->n_s = LocalVariables::add_internal_local_c_as_symbol(I"n", "number of words matched");
	gprk->f_s = LocalVariables::add_internal_local_c_as_symbol(I"f", "flag: sufficiently good match found to justify success");
	gprk->w_s = LocalVariables::add_internal_local_c_as_symbol(I"w", "for use by individual grammar lines");
	gprk->rv_s = LocalVariables::add_internal_local_as_symbol_noting(I"rv", &(gprk->rv_lv));
	gprk->g_s = LocalVariables::add_internal_local_c_as_symbol(I"g", "temporary: success flag for parsing visibles");
	gprk->ss_s = LocalVariables::add_internal_local_c_as_symbol(I"ss", "temporary: saves 'self' in distinguishing visibles");
	gprk->spn_s = LocalVariables::add_internal_local_c_as_symbol(I"spn", "temporary: saves 'parsed_number' in parsing visibles");
	gprk->pass_s = LocalVariables::add_internal_local_c_as_symbol(I"pass", "pass counter (1 to 3)");
	gprk->pass1_n_s = LocalVariables::add_internal_local_c_as_symbol(I"pass1_n", "value of n recorded during pass 1");
	gprk->pass2_n_s = LocalVariables::add_internal_local_c_as_symbol(I"pass2_n", "value of n recorded during pass 2");
}

void PL::Parsing::Tokens::Values::number(void) {
	packaging_state save = Routines::begin(Hierarchy::find(DECIMAL_TOKEN_INNER_HL));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K_number);
	if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	Produce::up();
	Routines::end(save);
}

void PL::Parsing::Tokens::Values::time(void) {
	packaging_state save = Routines::begin(Hierarchy::find(TIME_TOKEN_INNER_HL));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	kind *K = PL::TimesOfDay::kind();
	if (K) {
		grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K);
		if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	}
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	Produce::up();
	Routines::end(save);
}

void PL::Parsing::Tokens::Values::truth_state(void) {
	packaging_state save = Routines::begin(Hierarchy::find(TRUTH_STATE_TOKEN_INNER_HL));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K_truth_state);
	if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	Produce::up();
	Routines::end(save);
}

void PL::Parsing::Tokens::Values::compile_type_gprs(void) {
	int next_label = 1, longest;
	grammar_verb *gv;
	kind *K;
	LOOP_OVER_BASE_KINDS(K) {
		if ((Kinds::Behaviour::is_an_enumeration(K)) ||
			(Kinds::Behaviour::is_quasinumerical(K))) {
			instance *q; literal_pattern *lp;
			if (Kinds::Behaviour::needs_I6_GPR(K) == FALSE) continue;
			inter_name *iname = Kinds::RunTime::get_kind_GPR_iname(K);
			packaging_state save = Routines::begin(iname);
			int need_lf_vars = FALSE;
			LITERAL_FORMS_LOOP(lp, K) {
				need_lf_vars = TRUE;
				break;
			}
			gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
			PL::Parsing::Tokens::Values::add_original(&gprk);
			PL::Parsing::Tokens::Values::add_standard_set(&gprk);
			if (need_lf_vars) PL::Parsing::Tokens::Values::add_lp_vars(&gprk);
			@<Compile body of kind GPR@>;
			Routines::end(save);
			
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				inter_name *iname = Kinds::RunTime::get_instance_GPR_iname(K);
				packaging_state save = Routines::begin(iname);
				gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
				PL::Parsing::Tokens::Values::add_instance_call(&gprk);
				PL::Parsing::Tokens::Values::add_original(&gprk);
				PL::Parsing::Tokens::Values::add_standard_set(&gprk);
				GV_IS_VALUE_instance_mode = TRUE;
				@<Compile body of kind GPR@>;
				GV_IS_VALUE_instance_mode = FALSE;
				Routines::end(save);
			}
		}
	}
}

@<Compile body of kind GPR@> =
	@<Save word number@>;
	LITERAL_FORMS_LOOP(lp, K) {
		LiteralPatterns::gpr(&gprk, lp);
		@<Reset word number@>;
	}

	gv = PL::Parsing::Verbs::get_parsing_grammar(K);
	if (gv != NULL) {
		PL::Parsing::Verbs::compile_iv(&gprk, gv);
		@<Reset word number@>;
	}
	longest = 0;
	LOOP_OVER_INSTANCES(q, K) {
		wording NW = Instances::get_name_in_play(q, FALSE);
		int L = Wordings::length(NW) - 1;
		if (L > longest) longest = L;
	}
	for (; longest >= 0; longest--) {
		LOOP_OVER_INSTANCES(q, K) {
			wording NW = Instances::get_name_in_play(q, FALSE);
			if (Wordings::length(NW) - 1 == longest) {
				if (GV_IS_VALUE_instance_mode) {
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(EQ_BIP));
						Produce::down();
							Produce::val_symbol(K_value, gprk.instance_s);
							Produce::val_iname(K_value, Instances::iname(q));
						Produce::up();
						Produce::code();
						Produce::down();
				}
				@<Reset word number@>;

				TEMPORARY_TEXT(L);
				WRITE_TO(L, ".Failed_%d", next_label++);
				inter_symbol *flab = Produce::reserve_label(L);
				DISCARD_TEXT(L);

				LOOP_THROUGH_WORDING(k, NW) {
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(NE_BIP));
						Produce::down();
							Produce::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
							TEMPORARY_TEXT(W);
							WRITE_TO(W, "%N", k);
							Produce::val_dword(W);
							DISCARD_TEXT(W);
						Produce::up();
						Produce::code();
						Produce::down();
							Produce::inv_primitive(Produce::opcode(JUMP_BIP));
							Produce::down();
								Produce::lab(flab);
							Produce::up();
						Produce::up();
					Produce::up();
				}
				Produce::inv_primitive(Produce::opcode(STORE_BIP));
				Produce::down();
					Produce::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
					Produce::val_iname(K_value, Instances::iname(q));
				Produce::up();
				Produce::inv_primitive(Produce::opcode(RETURN_BIP));
				Produce::down();
					Produce::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
				Produce::up();

				if (GV_IS_VALUE_instance_mode) {
						Produce::up();
					Produce::up();
				}
				Produce::place_label(flab);
			}
		}
	}
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	Produce::up();

@<Save word number@> =
	Produce::inv_primitive(Produce::opcode(STORE_BIP));
	Produce::down();
		Produce::ref_symbol(K_value, gprk.original_wn_s);
		Produce::val_iname(K_value, Hierarchy::find(WN_HL));
	Produce::up();

@<Reset word number@> =
	Produce::inv_primitive(Produce::opcode(STORE_BIP));
	Produce::down();
		Produce::ref_iname(K_value, Hierarchy::find(WN_HL));
		Produce::val_symbol(K_value, gprk.original_wn_s);
	Produce::up();
