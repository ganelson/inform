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
	Routines::begin(InterNames::iname(DECIMAL_TOKEN_INNER_INAME));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K_number);
	if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_iname(K_value, InterNames::extern(GPRFAIL_EXNAMEF));
	Emit::up();
	Routines::end();
}

void PL::Parsing::Tokens::Values::time(void) {
	Routines::begin(InterNames::iname(TIME_TOKEN_INNER_INAME));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	kind *K = PL::TimesOfDay::kind();
	if (K) {
		grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K);
		if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	}
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_iname(K_value, InterNames::extern(GPRFAIL_EXNAMEF));
	Emit::up();
	Routines::end();
}

void PL::Parsing::Tokens::Values::truth_state(void) {
	Routines::begin(InterNames::iname(TRUTH_STATE_TOKEN_INNER_INAME));
	gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
	PL::Parsing::Tokens::Values::add_original(&gprk);
	grammar_verb *gv = PL::Parsing::Verbs::get_parsing_grammar(K_truth_state);
	if (gv) PL::Parsing::Verbs::compile_iv(&gprk, gv);
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_iname(K_value, InterNames::extern(GPRFAIL_EXNAMEF));
	Emit::up();
	Routines::end();
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
			Routines::begin(Kinds::RunTime::get_kind_GPR_iname(K));
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
			Routines::end();
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				Routines::begin(Kinds::RunTime::get_instance_GPR_iname(K));
				gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
				PL::Parsing::Tokens::Values::add_instance_call(&gprk);
				PL::Parsing::Tokens::Values::add_original(&gprk);
				PL::Parsing::Tokens::Values::add_standard_set(&gprk);
				GV_IS_VALUE_instance_mode = TRUE;
				@<Compile body of kind GPR@>;
				GV_IS_VALUE_instance_mode = FALSE;
				Routines::end();
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
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(eq_interp);
						Emit::down();
							Emit::val_symbol(K_value, gprk.instance_s);
							Emit::val_iname(K_value, Instances::iname(q));
						Emit::up();
						Emit::code();
						Emit::down();
				}
				@<Reset word number@>;

				TEMPORARY_TEXT(L);
				WRITE_TO(L, ".Failed_%d", next_label++);
				inter_symbol *flab = Emit::reserve_label(L);
				DISCARD_TEXT(L);

				LOOP_THROUGH_WORDING(k, NW) {
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(ne_interp);
						Emit::down();
							Emit::inv_call(InterNames::to_symbol(InterNames::extern(NEXTWORDSTOPPED_EXNAMEF)));
							TEMPORARY_TEXT(W);
							WRITE_TO(W, "%N", k);
							Emit::val_dword(W);
							DISCARD_TEXT(W);
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(jump_interp);
							Emit::down();
								Emit::lab(flab);
							Emit::up();
						Emit::up();
					Emit::up();
				}
				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_iname(K_value, InterNames::extern(PARSEDNUMBER_EXNAMEF));
					Emit::val_iname(K_value, Instances::iname(q));
				Emit::up();
				Emit::inv_primitive(return_interp);
				Emit::down();
					Emit::val_iname(K_value, InterNames::extern(GPRNUMBER_EXNAMEF));
				Emit::up();

				if (GV_IS_VALUE_instance_mode) {
						Emit::up();
					Emit::up();
				}
				Emit::place_label(flab, TRUE);
			}
		}
	}
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_iname(K_value, InterNames::extern(GPRFAIL_EXNAMEF));
	Emit::up();

@<Save word number@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk.original_wn_s);
		Emit::val_iname(K_value, InterNames::extern(WN_EXNAMEF));
	Emit::up();

@<Reset word number@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, InterNames::extern(WN_EXNAMEF));
		Emit::val_symbol(K_value, gprk.original_wn_s);
	Emit::up();

@ =
void PL::Parsing::Tokens::Values::gprv_compile(OUTPUT_STREAM, kind *K) {
	WRITE("%n", Kinds::RunTime::get_kind_GPR_iname(K));
}
inter_name *PL::Parsing::Tokens::Values::gprv_iname(kind *K) {
	return Kinds::RunTime::get_kind_GPR_iname(K);
}
void PL::Parsing::Tokens::Values::igprv_compile(OUTPUT_STREAM, kind *K) {
	WRITE("%n", Kinds::RunTime::get_instance_GPR_iname(K));
}
