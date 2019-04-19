[PL::Parsing::Tokens::Filters::] Noun Filter Tokens.

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
	MEMORY_MANAGEMENT
} noun_filter_token;

@ There are only three things we can do with these: create them, compile
their names (used as I6 tokens), and compile their routines.

=
noun_filter_token *PL::Parsing::Tokens::Filters::nft_new(parse_node *spec, int global_scope, int any_things) {
	pcalc_prop *prop = Specifications::to_proposition(spec);
	if ((prop) && (Calculus::Variables::number_free(prop) != 1)) {
		LOG("So $P and $D\n", spec, prop);
		Problems::Issue::sentence_problem(_p_(PM_FilterQuantified),
			"the [any ...] doesn't clearly give a description in the '...' part",
			"where I was expecting something like '[any vehicle]'.");
		spec = Specifications::from_kind(K_object);
	}

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

inter_name *PL::Parsing::Tokens::Filters::nft_compile_routine_iname(noun_filter_token *nft) {
	return nft->nft_iname;
}

void PL::Parsing::Tokens::Filters::nft_compile_routine(noun_filter_token *nft) {
	parse_node *noun_var = Lvalues::new_actual_NONLOCAL_VARIABLE(I6_noun_VAR);
	kind *R = Specifications::to_kind(nft->the_filter);
	kind *K = NonlocalVariables::kind(I6_noun_VAR);
	NonlocalVariables::set_kind(I6_noun_VAR, R);
	if (Kinds::Compare::le(R, K_object) == FALSE) nft->parse_using_gpr = TRUE;

	packaging_state save = Routines::begin(nft->nft_iname);
	if (nft->parse_using_gpr) {
		inter_symbol *v_s = LocalVariables::add_internal_local_c_as_symbol(I"v", "value parsed");
		inter_symbol *n_s = LocalVariables::add_internal_local_c_as_symbol(I"n", "saved value of noun");

		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, v_s);
			inter_name *gpr_to_ask = Kinds::Behaviour::get_explicit_I6_GPR_iname(R);
			if (gpr_to_ask == NULL) gpr_to_ask = Kinds::RunTime::get_kind_GPR_iname(R);
			Emit::inv_call_iname(gpr_to_ask);
		Emit::up();

		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_symbol(K_value, v_s);
				Emit::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
			Emit::up();
			Emit::code();
			Emit::down();
				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_symbol(K_value, n_s);
					Emit::val_iname(K_object, Hierarchy::find(NOUN_HL));
				Emit::up();
				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
					Emit::val_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
				Emit::up();

				Emit::inv_primitive(if_interp);
				Emit::down();
					Emit::inv_primitive(not_interp);
					Emit::down();
						Calculus::Deferrals::emit_test_if_var_matches_description(noun_var, nft->the_filter);
					Emit::up();
					Emit::code();
					Emit::down();
						Emit::inv_primitive(store_interp);
						Emit::down();
							Emit::ref_symbol(K_value, v_s);
							Emit::val_iname(K_object, Hierarchy::find(GPR_FAIL_HL));
						Emit::up();
					Emit::up();
				Emit::up();

				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
					Emit::val_symbol(K_value, n_s);
				Emit::up();
			Emit::up();
		Emit::up();

		Emit::inv_primitive(return_interp);
		Emit::down();
			Emit::val_symbol(K_value, v_s);
		Emit::up();
	} else if (nft->global_scope_flag) {
		inter_symbol *obj_s = LocalVariables::add_internal_local_c_as_symbol(I"obj", "object loop variable");
		inter_symbol *o2_s = LocalVariables::add_internal_local_c_as_symbol(I"o2", "saved value of noun");

		Emit::inv_primitive(switch_interp);
		Emit::down();
			Emit::val_iname(K_object, Hierarchy::find(SCOPE_STAGE_HL));
			Emit::code();
			Emit::down();
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, 1);
					Emit::code();
					Emit::down();
						if (nft->any_things_flag) Emit::rtrue();
						else Emit::rfalse();
					Emit::up();
				Emit::up();
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, 2);
					Emit::code();
					Emit::down();
						Emit::inv_primitive(store_interp);
						Emit::down();
							Emit::ref_symbol(K_value, obj_s);
							Emit::val_iname(K_object, Hierarchy::find(NOUN_HL));
						Emit::up();

						Emit::inv_primitive(objectloop_interp);
						Emit::down();
							Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
							Emit::val_iname(K_value, Kinds::RunTime::I6_classname(K_object));
							Calculus::Deferrals::emit_test_if_var_matches_description(noun_var, nft->the_filter);

							Emit::code();
							Emit::down();
								Emit::inv_primitive(store_interp);
								Emit::down();
									Emit::ref_symbol(K_value, o2_s);
									Emit::val_iname(K_object, Hierarchy::find(NOUN_HL));
								Emit::up();
								Emit::inv_primitive(store_interp);
								Emit::down();
									Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
									Emit::val_symbol(K_value, obj_s);
								Emit::up();

								Emit::inv_primitive(store_interp);
								Emit::down();
									Emit::ref_iname(K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									Emit::val(K_truth_state, LITERAL_IVAL, 1);
								Emit::up();

								Emit::inv_call_iname(Hierarchy::find(PLACEINSCOPE_HL));
								Emit::down();
									Emit::val_symbol(K_value, o2_s);
									Emit::val(K_truth_state, LITERAL_IVAL, 1);
								Emit::up();

								Emit::inv_primitive(store_interp);
								Emit::down();
									Emit::ref_iname(K_object, Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
									Emit::val(K_truth_state, LITERAL_IVAL, 0);
								Emit::up();

								Emit::inv_primitive(store_interp);
								Emit::down();
									Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
									Emit::val_symbol(K_value, o2_s);
								Emit::up();
							Emit::up();
						Emit::up();

						Emit::inv_primitive(store_interp);
						Emit::down();
							Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
							Emit::val_symbol(K_value, obj_s);
						Emit::up();

					Emit::up();
				Emit::up();
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, 3);
					Emit::code();
					Emit::down();
						Emit::inv_primitive(store_interp);
						Emit::down();
							Emit::ref_iname(K_object, Hierarchy::find(NEXTBEST_ETYPE_HL));
							Emit::val_iname(K_object, Hierarchy::find(NOTINCONTEXTPE_HL));
						Emit::up();
						Emit::inv_primitive(return_interp);
						Emit::down();
							Emit::val(K_number, LITERAL_IVAL, (inter_t) (-1));
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	} else {
		inter_symbol *x_s = LocalVariables::add_internal_local_c_as_symbol(I"x", "saved value of noun");
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, x_s);
			Emit::val_iname(K_object, Hierarchy::find(NOUN_HL));
		Emit::up();

		Emit::inv_primitive(return_interp);
		Emit::down();
			if (Specifications::to_proposition(nft->the_filter)) {
				Calculus::Propositions::Checker::type_check(Specifications::to_proposition(nft->the_filter), Calculus::Propositions::Checker::tc_no_problem_reporting());
				Calculus::Deferrals::emit_test_of_proposition(
					noun_var, Specifications::to_proposition(nft->the_filter));
			} else
				Calculus::Deferrals::emit_test_if_var_matches_description(noun_var, nft->the_filter);
		Emit::up();
	}
	Routines::end(save);
	NonlocalVariables::set_kind(I6_noun_VAR, K);
}

@h Access via ID.
For now, though, these are perhaps strangely accessed by ID number. (Because
the |parse_node| structure can't conveniently be annotated with pointers,
that's why.)

=
int too_late_for_further_NFTs = FALSE;

int PL::Parsing::Tokens::Filters::new_id(parse_node *spec, int global_scope, int any_things) {
	if (too_late_for_further_NFTs)
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"complicated instructions on understanding the player's command "
			"are not allowed in the past tense",
			"for instance by being applied to several previous turns in a row.");

	kind *K = Specifications::to_kind(spec);
	if ((Kinds::Compare::le(K, K_object) == FALSE) && (Kinds::Behaviour::request_I6_GPR(K) == FALSE) && (global_scope))
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"this is a kind of value I can't understand in command grammar",
			"so the '[any ...]' part will have to go.");

	return PL::Parsing::Tokens::Filters::nft_new(spec, global_scope, any_things)->allocation_id;
}

void PL::Parsing::Tokens::Filters::compile_id(int id) {
	noun_filter_token *nft;
	LOOP_OVER(nft, noun_filter_token)
		if (nft->allocation_id == id) {
			if (nft->parse_using_gpr) Emit::val_iname(K_value, Hierarchy::find(GPR_TT_HL));
			else if (nft->global_scope_flag) Emit::val_iname(K_value, Hierarchy::find(SCOPE_TT_HL));
			else Emit::val_iname(K_value, Hierarchy::find(ROUTINEFILTER_TT_HL));
			Emit::val_iname(K_value, nft->nft_iname);
		}
}

void PL::Parsing::Tokens::Filters::emit_id(int id) {
	noun_filter_token *nft;
	LOOP_OVER(nft, noun_filter_token)
		if (nft->allocation_id == id) {
			inter_t annot = 0;
			if (nft->parse_using_gpr == FALSE) {
				if (nft->global_scope_flag) annot = SCOPE_FILTER_IANN;
				else annot = NOUN_FILTER_IANN;
			}
			inter_name *iname = PL::Parsing::Tokens::Filters::nft_compile_routine_iname(nft);
			if (annot != 0)
				if (Emit::read_annotation(iname, annot) != 1)
					Emit::annotate_i(iname, annot, 1);
			Emit::array_iname_entry(iname);
		}
}

@h Compiling everything.
Having referred to these filter routines, we need to compile them.

=
void PL::Parsing::Tokens::Filters::compile(void) {
	noun_filter_token *nft;
	LOOP_OVER(nft, noun_filter_token)
		if (nft->nft_compiled == FALSE) {
			current_sentence = nft->nft_created_at;
			PL::Parsing::Tokens::Filters::nft_compile_routine(nft);
			nft->nft_compiled = TRUE;
		}
	/* too_late_for_further_NFTs = TRUE; */
}
