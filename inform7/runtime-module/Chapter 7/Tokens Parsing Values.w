[UnderstandValueTokens::] Tokens Parsing Values.

In the argot of Inform 6, GPR stands for General Parsing Routine,
and I7 makes heavy use of GPR tokens to achieve its ends. This section is
where the necessary I6 routines are compiled.

@ =


void UnderstandValueTokens::number(void) {
	inter_name *iname = Hierarchy::find(DECIMAL_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_number);
	if (cg) RTCommandGrammars::compile_for_value_GPR(&kit, cg);
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
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	kind *K = TimesOfDay::kind();
	if (K) {
		command_grammar *cg = CommandGrammars::get_parsing_grammar(K);
		if (cg) RTCommandGrammars::compile_for_value_GPR(&kit, cg);
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
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_truth_state);
	if (cg) RTCommandGrammars::compile_for_value_GPR(&kit, cg);
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
		gpr_kit kit = GPRs::new_kit();
		GPRs::add_original_var(&kit);
		GPRs::add_standard_vars(&kit);
		if (need_lf_vars) GPRs::add_LP_vars(&kit);
		@<Compile body of kind GPR@>;
		Functions::end(save);
		
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			inter_name *iname = RTKindConstructors::get_instance_GPR_iname(K);
			packaging_state save = Functions::begin(iname);
			gpr_kit kit = GPRs::new_kit();
			GPRs::add_instance_var(&kit);
			GPRs::add_original_var(&kit);
			GPRs::add_standard_vars(&kit);
			kit.GV_IS_VALUE_instance_mode = TRUE;
			@<Compile body of kind GPR@>;
			kit.GV_IS_VALUE_instance_mode = FALSE;
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
			gpr_kit kit = GPRs::new_kit();
			GPRs::add_original_var(&kit);
			GPRs::add_standard_vars(&kit);
			if (need_lf_vars) GPRs::add_LP_vars(&kit);
			@<Compile body of kind GPR@>;
			Functions::end(save);
			
			if (Kinds::Behaviour::is_an_enumeration(K)) {
				inter_name *iname = RTKindConstructors::get_instance_GPR_iname(K);
				packaging_state save = Functions::begin(iname);
				gpr_kit kit = GPRs::new_kit();
				GPRs::add_instance_var(&kit);
				GPRs::add_original_var(&kit);
				GPRs::add_standard_vars(&kit);
				kit.GV_IS_VALUE_instance_mode = TRUE;
				@<Compile body of kind GPR@>;
				kit.GV_IS_VALUE_instance_mode = FALSE;
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
			EmitCode::ref_symbol(K_value, kit.rv_s);
			EmitCode::call(RTLiteralPatterns::parse_fn_iname(lp));
		EmitCode::up();
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit.rv_s);
				EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, kit.rv_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		@<Reset word number@>;
	}

	cg = CommandGrammars::get_parsing_grammar(K);
	if (cg != NULL) {
		RTCommandGrammars::compile_for_value_GPR(&kit, cg);
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
				if (kit.GV_IS_VALUE_instance_mode) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, kit.instance_s);
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

				if (kit.GV_IS_VALUE_instance_mode) {
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
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();

@<Reset word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit.original_wn_s);
	EmitCode::up();
