[KindGPRs::] Kind GPRs.

General parsing routine (GPR) functions to match values of non-object kinds in
the command parser.

@ We provide special support for the token "[number]" here. This is a function
which picks up any irregular meanings added by the source text, say by "Understand
"lots" as 100."; it does not parse orthodox numbers like 4, -3, and such.

=
void KindGPRs::number(void) {
	inter_name *iname = Hierarchy::find(DECIMAL_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_number);
	if (cg) @<Return on any matches@>;
	@<Give up@>;
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@<Return on any matches@> =
	GPRs::add_standard_vars(&kit);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	RTCommandGrammars::compile_for_value_GPR(&kit, cg);

@<Give up@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();

@ And similarly "[time]":

=
void KindGPRs::time(void) {
	inter_name *iname = Hierarchy::find(TIME_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	kind *K = TimesOfDay::kind();
	if (K) {
		command_grammar *cg = CommandGrammars::get_parsing_grammar(K);
		if (cg) @<Return on any matches@>;
	}
	@<Give up@>;
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@ And "[truth state]":

=
void KindGPRs::truth_state(void) {
	inter_name *iname = Hierarchy::find(TRUTH_STATE_TOKEN_INNER_HL);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K_truth_state);
	if (cg) @<Return on any matches@>;
	@<Give up@>;
	Functions::end(save);
	Hierarchy::make_available(iname);
}

@ More generally, we can make a GPR for values of any enumeration or quasinumerical
kind on request.

This does not work for other kinds, and in particular for kinds of object. Those
are handled elsewhere by //Noun Filter Tokens//.

For a quasinumerical kind, we compile only a general GPR to match values of that
kind, trying each possible notation in turn until one matches:

=
void KindGPRs::quasinumerical_agent(compilation_subtask *t) {
	kind *K = RETRIEVE_POINTER_kind(t->data);
	if (Kinds::Behaviour::is_quasinumerical(K) == FALSE) internal_error("miscall");
	inter_name *iname = RTKindConstructors::GPR_iname(K);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	GPRs::add_LP_vars(&kit);
	@<Save word number@>;
	@<Save word number@>;
	@<Match more elaborate grammar for this kind, if there is any@>;
	literal_pattern *lp;
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
	@<Completely fail@>;
	Functions::end(save);
}

@<Save word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit.original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();

@<Match more elaborate grammar for this kind, if there is any@> =
	command_grammar *cg = CommandGrammars::get_parsing_grammar(K);
	if (cg) {
		RTCommandGrammars::compile_for_value_GPR(&kit, cg);
		@<Reset word number@>;
	}

@<Reset word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit.original_wn_s);
	EmitCode::up();

@<Completely fail@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
	EmitCode::up();

@ For an enumeration, we make two functions:

=
void KindGPRs::enumeration_agent(compilation_subtask *t) {
	kind *K = RETRIEVE_POINTER_kind(t->data);
	if (Kinds::Behaviour::is_an_enumeration(K) == FALSE) internal_error("miscall");
	@<Compile the normal GPR@>;
	@<Compile the instance GPR@>;
}

@ The first is a straightforward GPR to match any instance name for the kind.
For example, for a kind called "colour", it might match any of "burnt umber",
"cerulean blue" or "sienna".

@<Compile the normal GPR@> =
	inter_name *iname = RTKindConstructors::GPR_iname(K);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	@<Save word number@>;
	@<Match more elaborate grammar for this kind, if there is any@>;
	@<Match instances in decreasing name length order@>;
	@<Completely fail@>;
	Functions::end(save);

@ The second is not quite a standard GPR, because it takes a call parameter,
|instance|. The GPR matches only the name of that one instance; thus, if called
with |I_burnt_umber|, it would match only "burnt umber".

Why is this needed? The answer is that whereas objects can have individual
|parse_name| functions, allowing authors to customise the recognised names for
them, instances of non-object enumerations do not have a |parse_name|. So this
is the only way to allow, say, "Understand "sooty" as burnt umber." to work --
the grammar holding "sooty" comes out only in the following function.

@<Compile the instance GPR@> =
	inter_name *iname = RTKindConstructors::instance_GPR_iname(K);
	packaging_state save = Functions::begin(iname);
	gpr_kit kit = GPRs::new_kit();
	GPRs::add_instance_var(&kit);
	GPRs::add_original_var(&kit);
	GPRs::add_standard_vars(&kit);
	kit.GV_IS_VALUE_instance_mode = TRUE;
	@<Save word number@>;
	@<Match more elaborate grammar for this kind, if there is any@>;
	@<Match instances in decreasing name length order@>;
	@<Completely fail@>;
	Functions::end(save);

@ We try longer names first so that if the enumeration contains both "yellow"
and "yellow chromium" then we match YELLOW CHROMIUM against the longer option.

@<Match instances in decreasing name length order@> =
	int next_label = 1;

	int longest = 0;
	instance *I; 
	LOOP_OVER_INSTANCES(I, K) {
		wording NW = Instances::get_name_in_play(I, FALSE);
		int L = Wordings::length(NW);
		if (L > longest) longest = L;
	}
	for (int len = longest; len >= 1; len--) {
		LOOP_OVER_INSTANCES(I, K) {
			wording NW = Instances::get_name_in_play(I, FALSE);
			if (Wordings::length(NW) == len) {
				if (kit.GV_IS_VALUE_instance_mode) {
					@<Test if this is the right instance@>;
					@<Match the instance I@>;
					@<Close test if this is the right instance@>;
				} else {
					@<Match the instance I@>;
					@<Reset word number@>;
				}
			}
		}
	}

@<Match the instance I@> =
	TEMPORARY_TEXT(L)
	WRITE_TO(L, ".Failed_%d", next_label++);
	inter_symbol *failure_label = EmitCode::reserve_label(L);
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
					EmitCode::lab(failure_label);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
		EmitCode::val_iname(K_value, RTInstances::value_iname(I));
	EmitCode::up();
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
	EmitCode::up();

	EmitCode::place_label(failure_label);

@<Test if this is the right instance@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit.instance_s);
			EmitCode::val_iname(K_value, RTInstances::value_iname(I));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();

@<Close test if this is the right instance@> =
			@<Completely fail@>;
		EmitCode::up();
	EmitCode::up();
