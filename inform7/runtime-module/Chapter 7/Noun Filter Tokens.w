[NounFilterTokens::] Noun Filter Tokens.

General parsing routine (GPR) functions to match objects which fit some
description, or have some scoping requirement.

@ Recall that "scope" in the command parser means the set of things which
the player can discuss at a given point: usually, that will be anything
visible to the player's avatar in the world model. Usually, but not always,
and noun filter tokens can monkey with this.

=
typedef struct noun_filter_token {
	struct parse_node *the_filter;
	struct parse_node *nft_created_at;
	int change_scope;
	int change_scope_to_any_things;
	struct package_request *nft_package;
	struct inter_name *nft_iname;
	CLASS_DEFINITION
} noun_filter_token;

@ There are only three things we can do with these: create them, compile
their names (used as I6 tokens), and compile their routines.

=
noun_filter_token *NounFilterTokens::new(parse_node *spec, int change_scope, int any_things) {
	noun_filter_token *nft = CREATE(noun_filter_token);
	nft->the_filter = spec;
	nft->change_scope = change_scope;
	nft->change_scope_to_any_things = any_things;
	nft->nft_created_at = current_sentence;
	nft->nft_package = NULL;
	nft->nft_iname = NULL;
	return nft;
}

package_request *NounFilterTokens::package(noun_filter_token *nft) {
	if (nft->nft_package == NULL) {
		if (nft->change_scope) {
			nft->nft_package = Hierarchy::local_package(SCOPE_FILTERS_HAP);
		} else {
			nft->nft_package = Hierarchy::local_package(NOUN_FILTERS_HAP);
		}
	}
	return nft->nft_package;
}

inter_name *NounFilterTokens::filter_fn_iname(noun_filter_token *nft) {
	if (nft->nft_iname == NULL) {
		if (nft->change_scope) {
			nft->nft_iname =
				Hierarchy::make_iname_in(SCOPE_FILTER_FN_HL, NounFilterTokens::package(nft)); 
		} else {
			nft->nft_iname =
				Hierarchy::make_iname_in(NOUN_FILTER_FN_HL, NounFilterTokens::package(nft)); 
		}
		text_stream *desc = Str::new();
		WRITE_TO(desc, "noun filter token %d", nft->allocation_id);
		Sequence::queue(&NounFilterTokens::compilation_agent,
			STORE_POINTER_noun_filter_token(nft), desc);
	}
	return nft->nft_iname;
}

@ There are three different implementations:

@e VIA_GPR_NFTIMP from 1
@e VIA_SCOPE_FILTER_NFTIMP
@e VIA_NOUN_FILTER_NFTIMP

int NounFilterTokens::implementation(noun_filter_token *nft) {
	kind *K = Specifications::to_kind(nft->the_filter);
	if (Kinds::Behaviour::is_object(K) == FALSE) return VIA_GPR_NFTIMP;
	if (nft->change_scope) return VIA_SCOPE_FILTER_NFTIMP;
	return VIA_NOUN_FILTER_NFTIMP;
}

void NounFilterTokens::compilation_agent(compilation_subtask *t) {
	kind *save_K = NonlocalVariables::kind(Inter_noun_VAR);

	noun_filter_token *nft = RETRIEVE_POINTER_noun_filter_token(t->data);
	kind *K = Specifications::to_kind(nft->the_filter);
	NonlocalVariables::set_kind(Inter_noun_VAR, K);

	parse_node *noun_var = Lvalues::new_actual_NONLOCAL_VARIABLE(Inter_noun_VAR);

	packaging_state save = Functions::begin(NounFilterTokens::filter_fn_iname(nft));
	switch (NounFilterTokens::implementation(nft)) {
		case VIA_GPR_NFTIMP: @<Implement via GPR@>; break;
		case VIA_SCOPE_FILTER_NFTIMP: @<Implement as a scope filter@>; break;
		case VIA_NOUN_FILTER_NFTIMP: @<Implement as a noun filter@>; break;
	}
	Functions::end(save);
	NonlocalVariables::set_kind(Inter_noun_VAR, save_K);
}

@<Implement via GPR@> =
	inter_symbol *v_s =
		LocalVariables::new_internal_commented_as_symbol(I"v", I"value parsed");
	inter_symbol *n_s =
		LocalVariables::new_internal_commented_as_symbol(I"n", I"saved value of noun");

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, v_s);
		EmitCode::call(RTKindConstructors::GPR_iname(K));
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

@ For more on scope filters, and their specification, see the DM4.

@<Implement as a scope filter@> =
	inter_symbol *obj_s =
		LocalVariables::new_internal_commented_as_symbol(I"obj", I"object loop variable");
	inter_symbol *o2_s =
		LocalVariables::new_internal_commented_as_symbol(I"o2", I"saved value of noun");

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
					if (nft->change_scope_to_any_things) EmitCode::rtrue();
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
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(K_object));
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
								EmitCode::ref_iname(K_object,
									Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
								EmitCode::val_true();
							EmitCode::up();

							EmitCode::call(Hierarchy::find(PLACEINSCOPE_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, o2_s);
								EmitCode::val_true();
							EmitCode::up();

							EmitCode::inv(STORE_BIP);
							EmitCode::down();
								EmitCode::ref_iname(K_object,
									Hierarchy::find(SUPPRESS_SCOPE_LOOPS_HL));
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

@ Similarly, for more on noun filters, see the DM4; but as will be evident, this
really only wraps a simple condition. We convert this to a proposition with one
free variable, $x$, and then substitute |noun| for this value.

@<Implement as a noun filter@> =
	inter_symbol *x_s =
		LocalVariables::new_internal_commented_as_symbol(I"x", I"saved value of noun");
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, x_s);
		EmitCode::val_iname(K_object, Hierarchy::find(NOUN_HL));
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		if (Specifications::to_proposition(nft->the_filter)) {
			TypecheckPropositions::type_check(Specifications::to_proposition(nft->the_filter),
				TypecheckPropositions::tc_no_problem_reporting());
			CompilePropositions::to_test_as_condition(
				noun_var, Specifications::to_proposition(nft->the_filter));
		} else {
			CompilePropositions::to_test_if_variable_matches(noun_var, nft->the_filter);
		}
	EmitCode::up();

@ NFTs are sometimes used in code mode, in which case they appear as function
calls in the form |ParseTokenStopped(f, T)|, where |T| is the token itself and
|f| is some appropriate function in the command parser.

=
void NounFilterTokens::function_and_filter(noun_filter_token *nft) {
	inter_name *iname = NounFilterTokens::filter_fn_iname(nft);
	EmitCode::call(Hierarchy::find(PARSETOKENSTOPPED_HL));
	EmitCode::down();
		inter_name *f = NULL;
		switch (NounFilterTokens::implementation(nft)) {
			case VIA_GPR_NFTIMP: f = Hierarchy::find(GPR_TT_HL); break;
			case VIA_SCOPE_FILTER_NFTIMP: f = Hierarchy::find(SCOPE_TT_HL); break;
			case VIA_NOUN_FILTER_NFTIMP: f = Hierarchy::find(ROUTINEFILTER_TT_HL); break;
		}
		EmitCode::val_iname(K_value, f);
		EmitCode::val_iname(K_value, iname);
	EmitCode::up();
}

@ And alternatively NFTs become single array entries; but if so, they may need
to be prefaced with a marker so that the code generator can understand that they
are not like other tokens.

=
void NounFilterTokens::array_entry(noun_filter_token *nft) {
	inter_name *iname = NounFilterTokens::filter_fn_iname(nft);
	if (nft) {
		switch (NounFilterTokens::implementation(nft)) {
			case VIA_GPR_NFTIMP: break;
			case VIA_SCOPE_FILTER_NFTIMP:
				EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_SCOPE_FILTER_HL));
				break;
			case VIA_NOUN_FILTER_NFTIMP:
				EmitArrays::iname_entry(Hierarchy::find(VERB_DIRECTIVE_NOUN_FILTER_HL));
				break;
		}
		EmitArrays::iname_entry(iname);
	}
}
