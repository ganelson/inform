[RTActions::] Actions.

@

=
typedef struct action_compilation_data {
	int translated;
	struct text_stream *translated_name;
	struct inter_name *an_base_iname; /* e.g., |Take| */
	struct inter_name *an_iname; /* e.g., |##Take| */
	struct inter_name *an_routine_iname; /* e.g., |TakeSub| */
	struct inter_name *variables_id; /* for the shared variables set */
	struct package_request *an_package;
} action_compilation_data;

action_compilation_data RTActions::new_data(wording W) {
	action_compilation_data acd;
	acd.translated = FALSE;
	acd.translated_name = NULL;
	acd.an_iname = NULL;
	acd.an_base_iname = NULL;
	acd.an_routine_iname = NULL;
	acd.an_package = Hierarchy::local_package(ACTIONS_HAP);
	Hierarchy::apply_metadata_from_wording(acd.an_package, ACTION_NAME_MD_HL, W);
	acd.variables_id = Hierarchy::make_iname_in(ACTION_SHV_ID_HL, acd.an_package);
	return acd;
}

package_request *RTActions::rulebook_package(action_name *an, int RB) {
	return Hierarchy::make_package_in(RB, an->compilation_data.an_package);
}

void RTActions::translate(action_name *an, wording W) {
	if (an->compilation_data.translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatesActionAlready),
			"this action has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	if (an->compilation_data.an_base_iname)
		internal_error("too late for action base name translation");

	an->compilation_data.translated = TRUE;
	an->compilation_data.translated_name = Str::new();
	WRITE_TO(an->compilation_data.translated_name, "%N", Wordings::first_wn(W));
	LOGIF(ACTION_CREATIONS, "Translated action: $l as %W\n", an, W);
}

inter_name *RTActions::base_iname(action_name *an) {
	if (an->compilation_data.an_base_iname == NULL) {
		if (waiting_action == an)
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_in(WAIT_HL, an->compilation_data.an_package);
		else if (Str::len(an->compilation_data.translated_name) > 0)
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_with_specific_translation(TRANSLATED_BASE_NAME_HL, an->compilation_data.translated_name, an->compilation_data.an_package);
		else
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_with_memo(ACTION_BASE_NAME_HL, an->compilation_data.an_package, ActionNameNames::tensed(an, IS_TENSE));
	}
	return an->compilation_data.an_base_iname;
}

inter_name *RTActions::double_sharp(action_name *an) {
	if (an->compilation_data.an_iname == NULL) {
		an->compilation_data.an_iname =
			Hierarchy::derive_iname_in(DOUBLE_SHARP_NAME_HL, RTActions::base_iname(an), an->compilation_data.an_package);
		Emit::unchecked_numeric_constant(an->compilation_data.an_iname, (inter_ti) an->allocation_id);
		Hierarchy::make_available(an->compilation_data.an_iname);
		Produce::annotate_i(an->compilation_data.an_iname, ACTION_IANN, 1);
	}
	return an->compilation_data.an_iname;
}

inter_name *RTActions::Sub(action_name *an) {
	if (an->compilation_data.an_routine_iname == NULL) {
		an->compilation_data.an_routine_iname =
			Hierarchy::derive_iname_in(PERFORM_FN_HL, RTActions::base_iname(an), an->compilation_data.an_package);
		Hierarchy::make_available(an->compilation_data.an_routine_iname);
	}
	return an->compilation_data.an_routine_iname;
}

text_stream *RTActions::identifier(action_name *an) {
	return InterNames::to_text(RTActions::base_iname(an));
}

void RTActions::compile_action_name_var_creators(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		if ((an->action_variables) &&
			(SharedVariables::set_empty(an->action_variables) == FALSE)) {
			inter_name *iname = Hierarchy::make_iname_in(ACTION_STV_CREATOR_FN_HL,
				an->compilation_data.an_package);
			RTVariables::set_shared_variables_creator(an->action_variables, iname);
			RTVariables::compile_frame_creator(an->action_variables);
			inter_name *vc = Hierarchy::make_iname_in(ACTION_VARC_MD_HL,
				an->compilation_data.an_package);
			Emit::iname_constant(vc, K_value, iname);
		}
	}
}

void RTActions::compile_metadata(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		inter_name *iname = Hierarchy::make_iname_in(ACTION_ID_HL,
			an->compilation_data.an_package);
		Emit::numeric_constant(iname, 0);
		Emit::numeric_constant(an->compilation_data.variables_id, 0);
		if (Str::get_first_char(RTActions::identifier(an)) == '_')
			Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
				NO_CODING_MD_HL, 1);
		inter_name *dsc = Hierarchy::make_iname_in(ACTION_DSHARP_MD_HL,
			an->compilation_data.an_package);
		Emit::iname_constant(dsc, K_value, RTActions::double_sharp(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			OUT_OF_WORLD_MD_HL, (inter_ti) ActionSemantics::is_out_of_world(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			REQUIRES_LIGHT_MD_HL, (inter_ti) ActionSemantics::requires_light(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			CAN_HAVE_NOUN_MD_HL, (inter_ti) ActionSemantics::can_have_noun(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			CAN_HAVE_SECOND_MD_HL, (inter_ti) ActionSemantics::can_have_second(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			NOUN_ACCESS_MD_HL, (inter_ti) ActionSemantics::noun_access(an));
		Hierarchy::apply_metadata_from_number(an->compilation_data.an_package,
			SECOND_ACCESS_MD_HL, (inter_ti) ActionSemantics::second_access(an));
		inter_name *kn_iname = Hierarchy::make_iname_in(NOUN_KIND_MD_HL,
			an->compilation_data.an_package);
		RTKinds::constant_from_strong_id(kn_iname, ActionSemantics::kind_of_noun(an));
		inter_name *ks_iname = Hierarchy::make_iname_in(SECOND_KIND_MD_HL,
			an->compilation_data.an_package);
		RTKinds::constant_from_strong_id(ks_iname, ActionSemantics::kind_of_second(an));
	}
}

parse_node *RTActions::compile_action_bitmap_property(instance *I) {
	package_request *R = NULL;
	inter_name *N = NULL;
	if (I) {
		R = RTInstances::package(I);
		package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	} else {
		R = Kinds::Behaviour::package(K_object);
		package_request *PR = Hierarchy::package_within(KIND_INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(KIND_INLINE_PROPERTY_HL, PR);
	}
	packaging_state save = EmitArrays::begin(N, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++) EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	Produce::annotate_i(N, INLINE_ARRAY_IANN, 1);
	return Rvalues::from_iname(N);
}

@h Compiling data about actions.
In I6, there was no common infrastructure for the implementation of
actions: each defined its own |-Sub| routine. Here, we do have a common
infrastructure, and we access it with a single call.

=
void RTActions::compile_functions(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		inter_name *iname = RTActions::Sub(an);
		packaging_state save = Functions::begin(iname);
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			inter_name *generic_iname = Hierarchy::find(GENERICVERBSUB_HL);
			EmitCode::call(generic_iname);
			EmitCode::down();
				EmitCode::val_iname(K_value, an->check_rules->compilation_data.rb_id_iname);
				EmitCode::val_iname(K_value, an->carry_out_rules->compilation_data.rb_id_iname);
				EmitCode::val_iname(K_value, an->report_rules->compilation_data.rb_id_iname);
			EmitCode::up();
		EmitCode::up();
		Functions::end(save);

		@<Make a debug fn@>;
	}
}

@<Make a debug fn@> = 
	inter_name *iname = Hierarchy::derive_iname_in(DEBUG_ACTION_FN_HL,
		RTActions::base_iname(an), an->compilation_data.an_package);
	Hierarchy::apply_metadata_from_iname(an->compilation_data.an_package,
		DEBUG_ACTION_MD_HL, iname);
	save = Functions::begin(iname);
	inter_symbol *n_s = LocalVariables::new_other_as_symbol(I"n");
	inter_symbol *s_s = LocalVariables::new_other_as_symbol(I"s");
	inter_symbol *for_say_s = LocalVariables::new_other_as_symbol(I"for_say");

				int j = Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)), j0 = -1, somethings = 0, clc = 0;
				while (j <= Wordings::last_wn(ActionNameNames::tensed(an, IS_TENSE))) {
					if (<object-pronoun>(Wordings::one_word(j))) {
						if (j0 >= 0) {
							@<Insert a space here if needed to break up the action name@>;

							TEMPORARY_TEXT(AT)
							RTActions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)), AT);
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(AT);
							EmitCode::up();
							DISCARD_TEXT(AT)

							j0 = -1;
						}
						@<Insert a space here if needed to break up the action name@>;
						EmitCode::inv(IFELSE_BIP);
						EmitCode::down();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, for_say_s);
								EmitCode::val_number(2);
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								EmitCode::inv(PRINT_BIP);
								EmitCode::down();
									EmitCode::val_text(I"it");
								EmitCode::up();
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								RTActions::cat_something2(an, somethings++, n_s, s_s);
							EmitCode::up();
						EmitCode::up();
					} else {
						if (j0<0) j0 = j;
					}
					j++;
				}
				if (j0 >= 0) {
					@<Insert a space here if needed to break up the action name@>;
					TEMPORARY_TEXT(AT)
					RTActions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)), AT);
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(AT);
					EmitCode::up();
					DISCARD_TEXT(AT)
				}
				if (somethings < ActionSemantics::max_parameters(an)) {
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(NE_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, for_say_s);
							EmitCode::val_number(2);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							@<Insert a space here if needed to break up the action name@>;
							RTActions::cat_something2(an, somethings++, n_s, s_s);
						EmitCode::up();
					EmitCode::up();
				}


	Functions::end(save);

@<Insert a space here if needed to break up the action name@> =
	if (clc++ > 0) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I" ");
		EmitCode::up();
	}

@

=
void RTActions::print_action_text_to(wording W, int start, OUTPUT_STREAM) {
	if (Wordings::first_wn(W) == start) {
		WRITE("%W", Wordings::first_word(W));
		W = Wordings::trim_first_word(W);
		if (Wordings::empty(W)) return;
		WRITE(" ");
	}
	WRITE("%+W", W);
}

@ =
void RTActions::cat_something2(action_name *an, int n, inter_symbol *n_s, inter_symbol *s_s) {
	kind *K = ActionSemantics::kind_of_noun(an);
	inter_symbol *var = n_s;
	if (n > 0) {
		K = ActionSemantics::kind_of_second(an); var = s_s;
	}
	if (Kinds::Behaviour::is_object(K) == FALSE)
		var = InterNames::to_symbol(Hierarchy::find(PARSED_NUMBER_HL));
	EmitCode::inv(INDIRECT1V_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Kinds::Behaviour::get_name_of_printing_rule_ACTIONS(K));
		if ((K_understanding) && (Kinds::eq(K, K_understanding))) {
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(TIMES_BIP);
				EmitCode::down();
					EmitCode::val_number(100);
					EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_FROM_HL));
				EmitCode::up();
				EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_WORDS_HL));
			EmitCode::up();
		} else {
			EmitCode::val_symbol(K_value, var);
		}
	EmitCode::up();
}

int RTActions::actions_compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	if (PluginManager::active(actions_plugin) == FALSE)
		internal_error("actions plugin inactive");
	if (Kinds::eq(K, K_action_name)) {
		action_name *an = ARvalues::to_action_name(spec);
		if (Holsters::non_void_context(VH)) {
			inter_name *N = RTActions::double_sharp(an);
			if (N) Emit::holster_iname(VH, N);
		}
		return TRUE;
	}
	if (Kinds::eq(K, K_description_of_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(spec);
		RTActionPatterns::compile_pattern_match(VH, ap, FALSE);
		return TRUE;
	}
	if (Kinds::eq(K, K_stored_action)) {
		explicit_action *ea = Node::get_constant_explicit_action(spec);
		if (CompileValues::compiling_in_constant_mode())
			RTActionPatterns::as_stored_action(VH, ea);
		else {
			RTActionPatterns::emit_try(ea, TRUE);
		}
		return TRUE;
	}
	return FALSE;
}

int RTActions::action_variable_set_ID(action_name *an) {
	return 20000 + an->allocation_id;
}

void RTActions::emit_anl(action_name_list *head) {
	int C = ActionNameLists::length(head);
	if (C == 0) return;
	LOGIF(ACTION_PATTERN_COMPILATION, "Emitting action name list: $L", head);

	int neg = ActionNameLists::itemwise_negated(head);
	if (neg) { EmitCode::inv(NOT_BIP); EmitCode::down(); }

	int N = 0, downs = 0;
	LOOP_THROUGH_ANL(L, head) {
		N++;
		if (N < C) { EmitCode::inv(OR_BIP); EmitCode::down(); downs++; }
		if (L->item.nap_listed) {
			EmitCode::inv(INDIRECT0_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTNamedActionPatterns::identifier(L->item.nap_listed));
			EmitCode::up();
		} else {
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(ACTION_HL));
				EmitCode::val_iname(K_value, RTActions::double_sharp(L->item.action_listed));
			EmitCode::up();
		}
	}
	while (downs > 0) { EmitCode::up(); downs--; }

	if (neg) EmitCode::up();
}

@ =
int RTActions::is_an_action_variable(parse_node *spec) {
	nonlocal_variable *nlv;
	if (spec == NULL) return FALSE;
	if (Lvalues::get_storage_form(spec) != NONLOCAL_VARIABLE_NT) return FALSE;
	nlv = Node::get_constant_nonlocal_variable(spec);
	if (nlv == Inter_noun_VAR) return TRUE;
	if (nlv == Inter_second_noun_VAR) return TRUE;
	if (nlv == Inter_actor_VAR) return TRUE;
	return FALSE;
}
