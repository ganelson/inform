[RTActions::] Actions.

@

=
typedef struct action_compilation_data {
	int translated;
	struct text_stream *translated_name;
	struct inter_name *an_base_iname; /* e.g., |Take| */
	struct inter_name *an_iname; /* e.g., |##Take| */
	struct inter_name *an_routine_iname; /* e.g., |TakeSub| */
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
	Hierarchy::markup_wording(acd.an_package, ACTION_NAME_HMD, W);
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
				Hierarchy::make_iname_with_specific_name(TRANSLATED_BASE_NAME_HL, an->compilation_data.translated_name, an->compilation_data.an_package);
		else
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_with_memo(ACTION_BASE_NAME_HL, an->compilation_data.an_package, an->naming_data.present_name);
	}
	return an->compilation_data.an_base_iname;
}

inter_name *RTActions::double_sharp(action_name *an) {
	if (an->compilation_data.an_iname == NULL) {
		an->compilation_data.an_iname =
			Hierarchy::derive_iname_in(DOUBLE_SHARP_NAME_HL, RTActions::base_iname(an), an->compilation_data.an_package);
		Emit::ds_named_pseudo_numeric_constant(an->compilation_data.an_iname, K_value, (inter_ti) an->allocation_id);
		Hierarchy::make_available(Emit::tree(), an->compilation_data.an_iname);
		Produce::annotate_i(an->compilation_data.an_iname, ACTION_IANN, 1);
	}
	return an->compilation_data.an_iname;
}

inter_name *RTActions::Sub(action_name *an) {
	if (an->compilation_data.an_routine_iname == NULL) {
		an->compilation_data.an_routine_iname =
			Hierarchy::derive_iname_in(PERFORM_FN_HL, RTActions::base_iname(an), an->compilation_data.an_package);
		Hierarchy::make_available(Emit::tree(), an->compilation_data.an_routine_iname);
	}
	return an->compilation_data.an_routine_iname;
}

inter_name *RTActions::iname(action_name *an) {
	return RTActions::double_sharp(an);
}

text_stream *RTActions::identifier(action_name *an) {
	return Emit::to_text(RTActions::base_iname(an));
}

void RTActions::compile_action_name_var_creators(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		if ((an->action_variables) &&
			(StackedVariables::owner_empty(an->action_variables) == FALSE)) {
			inter_name *iname = Hierarchy::make_iname_in(ACTION_STV_CREATOR_FN_HL, an->compilation_data.an_package);
			StackedVariables::compile_frame_creator(an->action_variables, iname);
		}
	}
}

void RTActions::ActionCoding_array(void) {
	inter_name *iname = Hierarchy::find(ACTIONCODING_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	action_name *an;
	LOOP_OVER(an, action_name) {
		if (Str::get_first_char(RTActions::identifier(an)) == '_')
			Emit::array_numeric_entry(0);
		else Emit::array_action_entry(an);
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
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
	packaging_state save = Emit::named_array_begin(N, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++) Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Produce::annotate_i(N, INLINE_ARRAY_IANN, 1);
	return Rvalues::from_iname(N);
}

void RTActions::ActionHappened(void) {
	inter_name *iname = Hierarchy::find(ACTIONHAPPENED_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++)
		Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@h Compiling data about actions.
In I6, there was no common infrastructure for the implementation of
actions: each defined its own |-Sub| routine. Here, we do have a common
infrastructure, and we access it with a single call.

=
void RTActions::compile_action_routines(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		inter_name *iname = RTActions::Sub(an);
		packaging_state save = Routines::begin(iname);
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			inter_name *generic_iname = Hierarchy::find(GENERICVERBSUB_HL);
			Produce::inv_call_iname(Emit::tree(), generic_iname);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) an->check_rules->allocation_id);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) an->carry_out_rules->allocation_id);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) an->report_rules->allocation_id);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Routines::end(save);
	}
}

void RTActions::ActionData(void) {
	RTActions::compile_action_name_var_creators();
	action_name *an;
	int mn, ms, ml, mnp, msp, hn, hs, record_count = 0;

	inter_name *iname = Hierarchy::find(ACTIONDATA_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_value);
	LOOP_OVER(an, action_name) {
		mn = 0; ms = 0; ml = 0; mnp = 1; msp = 1; hn = 0; hs = 0;
		if (ActionSemantics::requires_light(an)) ml = 1;
		if (ActionSemantics::noun_access(an) == REQUIRES_ACCESS) mn = 1;
		if (ActionSemantics::second_access(an) == REQUIRES_ACCESS) ms = 1;
		if (ActionSemantics::noun_access(an) == REQUIRES_POSSESSION) { mn = 1; hn = 1; }
		if (ActionSemantics::second_access(an) == REQUIRES_POSSESSION) { ms = 1; hs = 1; }
		if (ActionSemantics::can_have_noun(an) == FALSE) mnp = 0;
		if (ActionSemantics::can_have_second(an) == FALSE) msp = 0;
		record_count++;
		Emit::array_action_entry(an);
		inter_ti bitmap = (inter_ti) (mn + ms*0x02 + ml*0x04 + mnp*0x08 +
			msp*0x10 + ((ActionSemantics::is_out_of_world(an))?1:0)*0x20 + hn*0x40 + hs*0x80);
		Emit::array_numeric_entry(bitmap);
		RTKinds::emit_strong_id(ActionSemantics::kind_of_noun(an));
		RTKinds::emit_strong_id(ActionSemantics::kind_of_second(an));
		if ((an->action_variables) &&
				(StackedVariables::owner_empty(an->action_variables) == FALSE))
			Emit::array_iname_entry(StackedVariables::frame_creator(an->action_variables));
		else Emit::array_numeric_entry(0);
		Emit::array_numeric_entry((inter_ti) (20000+an->allocation_id));
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);

	inter_name *ad_iname = Hierarchy::find(AD_RECORDS_HL);
	Emit::named_numeric_constant(ad_iname, (inter_ti) record_count);
	Hierarchy::make_available(Emit::tree(), ad_iname);

	inter_name *DB_Action_Details_iname = Hierarchy::find(DB_ACTION_DETAILS_HL);
	save = Routines::begin(DB_Action_Details_iname);
	inter_symbol *act_s = LocalVariables::add_named_call_as_symbol(I"act");
	inter_symbol *n_s = LocalVariables::add_named_call_as_symbol(I"n");
	inter_symbol *s_s = LocalVariables::add_named_call_as_symbol(I"s");
	inter_symbol *for_say_s = LocalVariables::add_named_call_as_symbol(I"for_say");
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, act_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());

	LOOP_OVER(an, action_name) {
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, RTActions::double_sharp(an));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());

				int j = Wordings::first_wn(an->naming_data.present_name), j0 = -1, somethings = 0, clc = 0;
				while (j <= Wordings::last_wn(an->naming_data.present_name)) {
					if (<object-pronoun>(Wordings::one_word(j))) {
						if (j0 >= 0) {
							@<Insert a space here if needed to break up the action name@>;

							TEMPORARY_TEXT(AT)
							RTActions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(an->naming_data.present_name), AT);
							Produce::inv_primitive(Emit::tree(), PRINT_BIP);
							Produce::down(Emit::tree());
								Produce::val_text(Emit::tree(), AT);
							Produce::up(Emit::tree());
							DISCARD_TEXT(AT)

							j0 = -1;
						}
						@<Insert a space here if needed to break up the action name@>;
						Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), EQ_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, for_say_s);
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), PRINT_BIP);
								Produce::down(Emit::tree());
									Produce::val_text(Emit::tree(), I"it");
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								RTActions::cat_something2(an, somethings++, n_s, s_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					} else {
						if (j0<0) j0 = j;
					}
					j++;
				}
				if (j0 >= 0) {
					@<Insert a space here if needed to break up the action name@>;
					TEMPORARY_TEXT(AT)
					RTActions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(an->naming_data.present_name), AT);
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						Produce::val_text(Emit::tree(), AT);
					Produce::up(Emit::tree());
					DISCARD_TEXT(AT)
				}
				if (somethings < ActionSemantics::max_parameters(an)) {
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), NE_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, for_say_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<Insert a space here if needed to break up the action name@>;
							RTActions::cat_something2(an, somethings++, n_s, s_s);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}

				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
	}

		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), DB_Action_Details_iname);
}

@<Insert a space here if needed to break up the action name@> =
	if (clc++ > 0) {
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), I" ");
		Produce::up(Emit::tree());
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
	Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_name_of_printing_rule_ACTIONS(K));
		if ((K_understanding) && (Kinds::eq(K, K_understanding))) {
			Produce::inv_primitive(Emit::tree(), PLUS_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 100);
					Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(CONSULT_FROM_HL));
				Produce::up(Emit::tree());
				Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(CONSULT_WORDS_HL));
			Produce::up(Emit::tree());
		} else {
			Produce::val_symbol(Emit::tree(), K_value, var);
		}
	Produce::up(Emit::tree());
}

int RTActions::actions_compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	if (PluginManager::active(actions_plugin) == FALSE)
		internal_error("actions plugin inactive");
	if (Kinds::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(spec);
		if (Holsters::data_acceptable(VH)) {
			inter_name *N = RTActions::iname(an);
			if (N) Emit::holster(VH, N);
		}
		return TRUE;
	}
	if (Kinds::eq(K, K_description_of_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(spec);
		PL::Actions::Patterns::compile_pattern_match(VH, *ap, FALSE);
		return TRUE;
	}
	if (Kinds::eq(K, K_stored_action)) {
		action_pattern *ap = Node::get_constant_action_pattern(spec);
		if (TEST_COMPILATION_MODE(CONSTANT_CMODE))
			PL::Actions::Patterns::as_stored_action(VH, ap);
		else {
			PL::Actions::Patterns::emit_try(ap, TRUE);
		}
		return TRUE;
	}
	return FALSE;
}

int RTActions::action_variable_set_ID(action_name *an) {
	return 20000 + an->allocation_id;
}
