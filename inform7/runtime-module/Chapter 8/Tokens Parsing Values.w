[UnderstandValueTokens::] Tokens Parsing Values.

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

gpr_kit UnderstandValueTokens::new_kit(void) {
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

void UnderstandValueTokens::add_instance_call(gpr_kit *gprk) {
	gprk->instance_s = LocalVariables::new_other_as_symbol(I"instance");
}

void UnderstandValueTokens::add_range_calls(gpr_kit *gprk) {
	gprk->range_from_s = LocalVariables::new_internal_commented_as_symbol(I"range_from", I"call parameter: word number of snippet start");
	gprk->range_words_s = LocalVariables::new_internal_commented_as_symbol(I"range_words", I"call parameter: snippet length");
}

void UnderstandValueTokens::add_original(gpr_kit *gprk) {
	gprk->original_wn_s = LocalVariables::new_internal_as_symbol(I"original_wn");
}

void UnderstandValueTokens::add_standard_set(gpr_kit *gprk) {
	gprk->group_wn_s = LocalVariables::new_internal_as_symbol(I"group_wn");
	gprk->v_s = LocalVariables::new_internal_as_symbol(I"v");
	gprk->w_s = LocalVariables::new_internal_as_symbol(I"w");
	gprk->rv_lv = LocalVariables::new_internal(I"rv");
	gprk->rv_s = LocalVariables::declare(gprk->rv_lv);
}

void UnderstandValueTokens::add_lp_vars(gpr_kit *gprk) {
	gprk->wpos_s = LocalVariables::new_internal_as_symbol(I"wpos");
	gprk->mid_word_s = LocalVariables::new_internal_as_symbol(I"mid_word");
	gprk->matched_number_s = LocalVariables::new_internal_as_symbol(I"matched_number");
	gprk->cur_word_s = LocalVariables::new_internal_as_symbol(I"cur_word");
	gprk->cur_len_s = LocalVariables::new_internal_as_symbol(I"cur_len");
	gprk->cur_addr_s = LocalVariables::new_internal_as_symbol(I"cur_addr");
	gprk->sgn_s = LocalVariables::new_internal_as_symbol(I"sgn");
	gprk->tot_s = LocalVariables::new_internal_as_symbol(I"tot");
	gprk->f_s = LocalVariables::new_internal_as_symbol(I"f");
	gprk->x_s = LocalVariables::new_internal_as_symbol(I"x");
}

void UnderstandValueTokens::add_parse_name_vars(gpr_kit *gprk) {
	gprk->original_wn_s = LocalVariables::new_internal_commented_as_symbol(I"original_wn", I"first word of text parsed");
	gprk->group_wn_s = LocalVariables::new_internal_commented_as_symbol(I"group_wn", I"first word matched against A/B/C/... disjunction");
	gprk->try_from_wn_s = LocalVariables::new_internal_commented_as_symbol(I"try_from_wn", I"position to try matching from");
	gprk->n_s = LocalVariables::new_internal_commented_as_symbol(I"n", I"number of words matched");
	gprk->f_s = LocalVariables::new_internal_commented_as_symbol(I"f", I"flag: sufficiently good match found to justify success");
	gprk->w_s = LocalVariables::new_internal_commented_as_symbol(I"w", I"for use by individual grammar lines");
	gprk->rv_lv = LocalVariables::new_internal(I"rv");
	gprk->rv_s = LocalVariables::declare(gprk->rv_lv);
	gprk->g_s = LocalVariables::new_internal_commented_as_symbol(I"g", I"temporary: success flag for parsing visibles");
	gprk->ss_s = LocalVariables::new_internal_commented_as_symbol(I"ss", I"temporary: saves 'self' in distinguishing visibles");
	gprk->spn_s = LocalVariables::new_internal_commented_as_symbol(I"spn", I"temporary: saves 'parsed_number' in parsing visibles");
	gprk->pass_s = LocalVariables::new_internal_commented_as_symbol(I"pass", I"pass counter (1 to 3)");
	gprk->pass1_n_s = LocalVariables::new_internal_commented_as_symbol(I"pass1_n", I"value of n recorded during pass 1");
	gprk->pass2_n_s = LocalVariables::new_internal_commented_as_symbol(I"pass2_n", I"value of n recorded during pass 2");
}

void UnderstandValueTokens::number(void) {
	inter_name *iname = Hierarchy::find(DECIMAL_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit gprk = UnderstandValueTokens::new_kit();
	UnderstandValueTokens::add_original(&gprk);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_number);
	if (cg) RTCommandGrammars::compile_iv(&gprk, cg);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
	Hierarchy::make_available(iname);
}

void UnderstandValueTokens::time(void) {
	inter_name *iname = Hierarchy::find(TIME_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit gprk = UnderstandValueTokens::new_kit();
	UnderstandValueTokens::add_original(&gprk);
	kind *K = TimesOfDay::kind();
	if (K) {
		command_grammar *cg = CommandGrammars::get_parsing_grammar(K);
		if (cg) RTCommandGrammars::compile_iv(&gprk, cg);
	}
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
	Hierarchy::make_available(iname);
}

void UnderstandValueTokens::truth_state(void) {
	inter_name *iname = Hierarchy::find(TRUTH_STATE_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit gprk = UnderstandValueTokens::new_kit();
	UnderstandValueTokens::add_original(&gprk);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_truth_state);
	if (cg) RTCommandGrammars::compile_iv(&gprk, cg);
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();
	Functions::end(save);
	Hierarchy::make_available(iname);
}

void UnderstandValueTokens::agent(compilation_subtask *t) {
	kind *K = RETRIEVE_POINTER_kind(t->data);
		if ((Kinds::Behaviour::is_an_enumeration(K)) ||
			(Kinds::Behaviour::is_quasinumerical(K))) {
	int next_label = 1, longest;
	command_grammar *cg;
	instance *q; literal_pattern *lp;
			inter_name *iname = RTKindConstructors::get_kind_GPR_iname(K);
			packaging_state save = Functions::begin(iname);
			int need_lf_vars = FALSE;
			LITERAL_FORMS_LOOP(lp, K) {
				need_lf_vars = TRUE;
				break;
			}
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			UnderstandValueTokens::add_original(&gprk);
			UnderstandValueTokens::add_standard_set(&gprk);
			if (need_lf_vars) UnderstandValueTokens::add_lp_vars(&gprk);
			@<Compile body of kind GPR@>;
			Functions::end(save);
			
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				inter_name *iname = RTKindConstructors::get_instance_GPR_iname(K);
				packaging_state save = Functions::begin(iname);
				gpr_kit gprk = UnderstandValueTokens::new_kit();
				UnderstandValueTokens::add_instance_call(&gprk);
				UnderstandValueTokens::add_original(&gprk);
				UnderstandValueTokens::add_standard_set(&gprk);
				GV_IS_VALUE_instance_mode = TRUE;
				@<Compile body of kind GPR@>;
				GV_IS_VALUE_instance_mode = FALSE;
				Functions::end(save);
			}
			}
}

void UnderstandValueTokens::compile_type_gprs(void) {
	int next_label = 1, longest;
	command_grammar *cg;
	kind *K;
	LOOP_OVER_BASE_KINDS(K) {
		if ((Kinds::Behaviour::is_an_enumeration(K)) ||
			(Kinds::Behaviour::is_quasinumerical(K))) {
			instance *q; literal_pattern *lp;
			if (RTKindConstructors::needs_I6_GPR(K) == FALSE) continue;
			inter_name *iname = RTKindConstructors::get_kind_GPR_iname(K);
			packaging_state save = Functions::begin(iname);
			int need_lf_vars = FALSE;
			LITERAL_FORMS_LOOP(lp, K) {
				need_lf_vars = TRUE;
				break;
			}
			gpr_kit gprk = UnderstandValueTokens::new_kit();
			UnderstandValueTokens::add_original(&gprk);
			UnderstandValueTokens::add_standard_set(&gprk);
			if (need_lf_vars) UnderstandValueTokens::add_lp_vars(&gprk);
			@<Compile body of kind GPR@>;
			Functions::end(save);
			
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				inter_name *iname = RTKindConstructors::get_instance_GPR_iname(K);
				packaging_state save = Functions::begin(iname);
				gpr_kit gprk = UnderstandValueTokens::new_kit();
				UnderstandValueTokens::add_instance_call(&gprk);
				UnderstandValueTokens::add_original(&gprk);
				UnderstandValueTokens::add_standard_set(&gprk);
				GV_IS_VALUE_instance_mode = TRUE;
				@<Compile body of kind GPR@>;
				GV_IS_VALUE_instance_mode = FALSE;
				Functions::end(save);
			}
		}
	}
}

@<Compile body of kind GPR@> =
	@<Save word number@>;
	LITERAL_FORMS_LOOP(lp, K) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk.rv_s);
			EmitCode::call(RTLiteralPatterns::parse_fn_iname(lp));
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gprk.rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk.rv_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		@<Reset word number@>;
	}

	cg = CommandGrammars::get_parsing_grammar(K);
	if (cg != NULL) {
		RTCommandGrammars::compile_iv(&gprk, cg);
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
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, gprk.instance_s);
							EmitCode::val_iname(K_value, RTInstances::value_iname(q));
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
				}
				@<Reset word number@>;

				TEMPORARY_TEXT(L)
				WRITE_TO(L, ".Failed_%d", next_label++);
				inter_symbol *flab = EmitCode::reserve_label(L);
				DISCARD_TEXT(L)

				LOOP_THROUGH_WORDING(k, NW) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(NE_BIP);
						EmitCode::down();
							EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
							TEMPORARY_TEXT(W)
							WRITE_TO(W, "%N", k);
							EmitCode::val_dword(W);
							DISCARD_TEXT(W)
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(JUMP_BIP);
							EmitCode::down();
								EmitCode::lab(flab);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				}
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
					EmitCode::val_iname(K_value, RTInstances::value_iname(q));
				EmitCode::up();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
				EmitCode::up();

				if (GV_IS_VALUE_instance_mode) {
						EmitCode::up();
					EmitCode::up();
				}
				EmitCode::place_label(flab);
			}
		}
	}
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();

@<Save word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();

@<Reset word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, gprk.original_wn_s);
	EmitCode::up();
