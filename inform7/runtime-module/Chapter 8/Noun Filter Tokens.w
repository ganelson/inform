[UnderstandFilterTokens::] Noun Filter Tokens.

Filters are used to require nouns to have specific kinds or
attributes, or to have specific scoping rules: they correspond to Inform 6's
|noun=Routine| and |scope=Routine| tokens. Though these are quite different
concepts in I6, their common handling seems natural in I7.

@h Definitions.

=
typedef struct noun_filter_token {
	struct parse_node *the_filter;
	struct parse_node *nft_created_at;
	int global_scope_flag;
	int any_things_flag;
	int parse_using_gpr;
	int nft_compiled;
	struct inter_name *nft_iname;
	CLASS_DEFINITION
} noun_filter_token;

@ There are only three things we can do with these: create them, compile
their names (used as I6 tokens), and compile their routines.

=
noun_filter_token *UnderstandFilterTokens::nft_new(parse_node *spec, int global_scope, int any_things) {
	noun_filter_token *nft = CREATE(noun_filter_token);
	nft->the_filter = spec;
	nft->global_scope_flag = global_scope;
	nft->any_things_flag = any_things;
	nft->nft_created_at = current_sentence;
	nft->parse_using_gpr = FALSE;
	nft->nft_compiled = FALSE;

	if (global_scope) {
		package_request *PR = Hierarchy::local_package(SCOPE_FILTERS_HAP);
		nft->nft_iname = Hierarchy::make_iname_in(SCOPE_FILTER_FN_HL, PR); 
	} else {
		package_request *PR = Hierarchy::local_package(NOUN_FILTERS_HAP);
		nft->nft_iname = Hierarchy::make_iname_in(NOUN_FILTER_FN_HL, PR); 
	}
	return nft;
}

inter_name *UnderstandFilterTokens::nft_compile_routine_iname(noun_filter_token *nft) {
	return nft->nft_iname;
}

void UnderstandFilterTokens::nft_compile_routine(noun_filter_token *nft) {
	parse_node *noun_var = Lvalues::new_actual_NONLOCAL_VARIABLE(Inter_noun_VAR);
	kind *R = Specifications::to_kind(nft->the_filter);
	kind *K = NonlocalVariables::kind(Inter_noun_VAR);
	NonlocalVariables::set_kind(Inter_noun_VAR, R);
	if (Kinds::Behaviour::is_object(R) == FALSE) nft->parse_using_gpr = TRUE;

	packaging_state save = Functions::begin(nft->nft_iname);
	if (nft->parse_using_gpr) {
		inter_symbol *v_s = LocalVariables::new_internal_commented_as_symbol(I"v", I"value parsed");
		inter_symbol *n_s = LocalVariables::new_internal_commented_as_symbol(I"n", I"saved value of noun");

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, v_s);
			inter_name *gpr_to_ask = Kinds::Behaviour::get_explicit_I6_GPR_iname(R);
			if (gpr_to_ask == NULL) gpr_to_ask = RTKinds::get_kind_GPR_iname(R);
			EmitCode::call(gpr_to_ask);
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, v_s);
				EmitCode::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, n_s);
					EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
					EmitCode::val_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
				EmitCode::up();

				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(NOT_BIP);
					EmitCode::down();
						CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, v_s);
							EmitCode::val_iname(K_object, Hierarchy::find(GPR_FAIL_HL));
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();

				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
					EmitCode::val_symbol(K_value, n_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, v_s);
		EmitCode::up();
	} else if (nft->global_scope_flag) {
		inter_symbol *obj_s = LocalVariables::new_internal_commented_as_symbol(I"obj", I"object loop variable");
		inter_symbol *o2_s = LocalVariables::new_internal_commented_as_symbol(I"o2", I"saved value of noun");

		EmitCode::inv(SWITCH_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_object, Hierarchy::find(SCOPE_STAGE_HL));
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(1);
					EmitCode::code();
					EmitCode::down();
						if (nft->any_things_flag) EmitCode::rtrue();
						else EmitCode::rfalse();
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(2);
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, obj_s);
							EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
						EmitCode::up();

						EmitCode::inv(OBJECTLOOP_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
							EmitCode::val_iname(K_value, RTKinds::I6_classname(K_object));
							CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);

							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_symbol(K_value, o2_s);
									EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
								EmitCode::up();
								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
									EmitCode::val_symbol(K_value, obj_s);
								EmitCode::up();

								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_iname(K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									EmitCode::val_true();
								EmitCode::up();

								EmitCode::call(Hierarchy::find(PLACEINSCOPE_HL));
								EmitCode::down();
									EmitCode::val_symbol(K_value, o2_s);
									EmitCode::val_true();
								EmitCode::up();

								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_iname(K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									EmitCode::val_false();
								EmitCode::up();

								EmitCode::inv(STORE_BIP);
								EmitCode::down();
									EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
									EmitCode::val_symbol(K_value, o2_s);
								EmitCode::up();
							EmitCode::up();
						EmitCode::up();

						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_object, Hierarchy::find(NOUN_HL));
							EmitCode::val_symbol(K_value, obj_s);
						EmitCode::up();

					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_number(3);
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_iname(K_object, Hierarchy::find(NEXTBEST_ETYPE_HL));
							EmitCode::val_iname(K_object, Hierarchy::find(NOTINCONTEXTPE_HL));
						EmitCode::up();
						EmitCode::inv(RETURN_BIP);
						EmitCode::down();
							EmitCode::val_number((inter_ti) (-1));
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		inter_symbol *x_s = LocalVariables::new_internal_commented_as_symbol(I"x", I"saved value of noun");
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, x_s);
			EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
		EmitCode::up();

		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			if (Specifications::to_proposition(nft->the_filter)) {
				TypecheckPropositions::type_check(Specifications::to_proposition(nft->the_filter), TypecheckPropositions::tc_no_problem_reporting());
				CompilePropositions::to_test_as_condition(
					noun_var, Specifications::to_proposition(nft->the_filter));
			} else
				CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);
		EmitCode::up();
	}
	Functions::end(save);
	NonlocalVariables::set_kind(Inter_noun_VAR, K);
}

@h Access via ID.
For now, though, these are perhaps strangely accessed by ID number. (Because
the |parse_node| structure can't conveniently be annotated with pointers,
that's why.)

=
void UnderstandFilterTokens::compile_id(noun_filter_token *nft) {
	if (nft) {
		if (nft->parse_using_gpr) EmitCode::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
		else if (nft->global_scope_flag) EmitCode::val_iname(K_value, Hierarchy::find(SCOPE_TT_HL));
		else EmitCode::val_iname(K_value, Hierarchy::find(ROUTINEFILTER_TT_HL));
		EmitCode::val_iname(K_value, nft->nft_iname);
	}
}

void UnderstandFilterTokens::emit_id(noun_filter_token *nft) {
	if (nft) {
		inter_ti annot = 0;
		if (nft->parse_using_gpr == FALSE) {
			if (nft->global_scope_flag) annot = SCOPE_FILTER_IANN;
			else annot = NOUN_FILTER_IANN;
		}
		inter_name *iname = UnderstandFilterTokens::nft_compile_routine_iname(nft);
		if (annot != 0)
			if (Produce::read_annotation(iname, annot) != 1)
				Produce::annotate_i(iname, annot, 1);
		EmitArrays::iname_entry(iname);
	}
}

@h Compiling everything.
Having referred to these filter routines, we need to compile them.

=
void UnderstandFilterTokens::compile(void) {
	noun_filter_token *nft;
	LOOP_OVER(nft, noun_filter_token)
		if (nft->nft_compiled == FALSE) {
			current_sentence = nft->nft_created_at;
			UnderstandFilterTokens::nft_compile_routine(nft);
			nft->nft_compiled = TRUE;
		}
}
