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

		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, v_s);
			inter_name *gpr_to_ask = Kinds::Behaviour::get_explicit_I6_GPR_iname(R);
			if (gpr_to_ask == NULL) gpr_to_ask = RTKinds::get_kind_GPR_iname(R);
			Produce::inv_call_iname(Emit::tree(), gpr_to_ask);
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, v_s);
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(GPR_NUMBER_HL));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, n_s);
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
				Emit::up();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
					Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PARSED_NUMBER_HL));
				Emit::up();

				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), NOT_BIP);
					Emit::down();
						CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, v_s);
							Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(GPR_FAIL_HL));
						Emit::up();
					Emit::up();
				Emit::up();

				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
					Produce::val_symbol(Emit::tree(), K_value, n_s);
				Emit::up();
			Emit::up();
		Emit::up();

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, v_s);
		Emit::up();
	} else if (nft->global_scope_flag) {
		inter_symbol *obj_s = LocalVariables::new_internal_commented_as_symbol(I"obj", I"object loop variable");
		inter_symbol *o2_s = LocalVariables::new_internal_commented_as_symbol(I"o2", I"saved value of noun");

		Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCOPE_STAGE_HL));
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Emit::down();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::code(Emit::tree());
					Emit::down();
						if (nft->any_things_flag) Produce::rtrue(Emit::tree());
						else Produce::rfalse(Emit::tree());
					Emit::up();
				Emit::up();
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Emit::down();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, obj_s);
							Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
						Emit::up();

						Produce::inv_primitive(Emit::tree(), OBJECTLOOP_BIP);
						Emit::down();
							Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
							Produce::val_iname(Emit::tree(), K_value, RTKinds::I6_classname(K_object));
							CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);

							Produce::code(Emit::tree());
							Emit::down();
								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_symbol(Emit::tree(), K_value, o2_s);
									Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
								Emit::up();
								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
									Produce::val_symbol(Emit::tree(), K_value, obj_s);
								Emit::up();

								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
								Emit::up();

								Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PLACEINSCOPE_HL));
								Emit::down();
									Produce::val_symbol(Emit::tree(), K_value, o2_s);
									Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
								Emit::up();

								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
								Emit::up();

								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
									Produce::val_symbol(Emit::tree(), K_value, o2_s);
								Emit::up();
							Emit::up();
						Emit::up();

						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
							Produce::val_symbol(Emit::tree(), K_value, obj_s);
						Emit::up();

					Emit::up();
				Emit::up();
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Emit::down();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(NEXTBEST_ETYPE_HL));
							Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOTINCONTEXTPE_HL));
						Emit::up();
						Produce::inv_primitive(Emit::tree(), RETURN_BIP);
						Emit::down();
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (-1));
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	} else {
		inter_symbol *x_s = LocalVariables::new_internal_commented_as_symbol(I"x", I"saved value of noun");
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, x_s);
			Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(NOUN_HL));
		Emit::up();

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Emit::down();
			if (Specifications::to_proposition(nft->the_filter)) {
				TypecheckPropositions::type_check(Specifications::to_proposition(nft->the_filter), TypecheckPropositions::tc_no_problem_reporting());
				CompilePropositions::to_test_as_condition(
					noun_var, Specifications::to_proposition(nft->the_filter));
			} else
				CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);
		Emit::up();
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
		if (nft->parse_using_gpr) Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_TT_HL));
		else if (nft->global_scope_flag) Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCOPE_TT_HL));
		else Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(ROUTINEFILTER_TT_HL));
		Produce::val_iname(Emit::tree(), K_value, nft->nft_iname);
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
		Emit::array_iname_entry(iname);
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
