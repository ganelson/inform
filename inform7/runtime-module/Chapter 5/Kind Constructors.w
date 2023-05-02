[RTKindConstructors::] Kind Constructors.

Each kind constructor has an Inter package of resources.

@h Inter identifiers.

=
typedef struct kind_constructor_compilation_data {
	struct inter_name *xref_iname;
	struct inter_name *con_iname;
	struct inter_name *list_iname;
	struct package_request *kc_package;
	struct inter_name *kind_GPR_iname;
	int needs_GPR; /* a GPR is actually required to be compiled */
	struct inter_name *instance_GPR_iname;
	struct inter_name *first_instance_iname;
	struct inter_name *next_instance_iname;
	struct inter_name *instance_count_iname;
	struct inter_name *pr_iname;
	struct inter_name *inc_iname;
	struct inter_name *dec_iname;
	struct inter_name *mkdef_iname;
	struct inter_name *ranger_iname;
	struct inter_name *debug_print_fn_iname;
	struct package_request *usage_package;
	int declaration_sequence_number;
} kind_constructor_compilation_data;

kind_constructor_compilation_data RTKindConstructors::new_compilation_data(kind_constructor *kc) {
	kind_constructor_compilation_data kccd;
	kccd.xref_iname = NULL;
	kccd.con_iname = NULL;
	kccd.kc_package = NULL;
	kccd.list_iname = NULL;
	kccd.kind_GPR_iname = NULL;
	kccd.needs_GPR = FALSE;
	kccd.instance_GPR_iname = NULL;
	kccd.first_instance_iname = NULL;
	kccd.next_instance_iname = NULL;
	kccd.instance_count_iname = NULL;
	kccd.pr_iname = NULL;
	kccd.inc_iname = NULL;
	kccd.dec_iname = NULL;
	kccd.mkdef_iname = NULL;
	kccd.ranger_iname = NULL;
	kccd.debug_print_fn_iname = NULL;
	kccd.usage_package = NULL;
	kccd.declaration_sequence_number = -1;
	return kccd;
}

package_request *RTKindConstructors::package(kind_constructor *kc) {
	if (kc->compilation_data.kc_package == NULL) {
		if (kc->where_defined_in_source_text) {
			kc->compilation_data.kc_package = Hierarchy::local_package_to(KIND_HAP,
				kc->where_defined_in_source_text);
		} else if (kc->superkind_set_at) {
			kc->compilation_data.kc_package = Hierarchy::local_package_to(KIND_HAP,
				kc->superkind_set_at);
		} else {
			kc->compilation_data.kc_package = Hierarchy::synoptic_package(KIND_HAP);
		}
		wording W = KindConstructors::get_name(kc, FALSE);
		if (Wordings::nonempty(W))
			Hierarchy::apply_metadata_from_wording(kc->compilation_data.kc_package, KIND_NAME_MD_HL, W);
		else if (Str::len(kc->explicit_identifier) > 0)
			Hierarchy::apply_metadata(kc->compilation_data.kc_package, KIND_NAME_MD_HL,
				kc->explicit_identifier);
		else
			Hierarchy::apply_metadata(kc->compilation_data.kc_package, KIND_NAME_MD_HL, I"(anonymous kind)");
		if (kc->where_defined_in_source_text)
			Hierarchy::apply_metadata_from_number(kc->compilation_data.kc_package, KIND_AT_MD_HL,
				(inter_ti) Wordings::first_wn(Node::get_text(kc->where_defined_in_source_text)));
	}
	return kc->compilation_data.kc_package;
}

package_request *RTKindConstructors::usage_package(kind_constructor *kc) {
	if (kc->compilation_data.usage_package == NULL)
		kc->compilation_data.usage_package =
			Hierarchy::completion_package(KIND_USAGE_HAP);
	return kc->compilation_data.usage_package;
}

inter_name *RTKindConstructors::xref_iname(kind_constructor *kc) {
	if (kc->compilation_data.xref_iname == NULL)
		kc->compilation_data.xref_iname =
			Hierarchy::make_iname_in(KIND_XREF_SYMBOL_HL, RTKindConstructors::package(kc));
	return kc->compilation_data.xref_iname;
}

@ An identifier like |WHATEVER_TY|, then, begins life in a definition inside an
Neptune file; becomes attached to a constructor here; and finally winds up
back in Inter code, because we define it as the constant for the weak kind ID
of the kind which the constructor makes:

=
inter_name *RTKindConstructors::weak_ID_iname(kind_constructor *kc) {
	if (kc->compilation_data.con_iname == NULL) {
		kc->compilation_data.con_iname =
			Hierarchy::make_iname_with_specific_translation(WEAK_ID_HL,
				RTKindIDs::identifier_for_weak_ID(kc), RTKindConstructors::package(kc));
		Hierarchy::make_available(kc->compilation_data.con_iname);
	}
	return kc->compilation_data.con_iname;
}

inter_name *RTKindConstructors::UNKNOWN_iname(void) {
	return CON_UNKNOWN->compilation_data.con_iname;
}

inter_name *RTKindConstructors::list_iname(kind_constructor *kc) {
	return kc->compilation_data.list_iname;
}
void RTKindConstructors::set_list_iname(kind_constructor *kc, inter_name *iname) {
	kc->compilation_data.list_iname = iname;
}

inter_name *RTKindConstructors::first_instance_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	if (kc->compilation_data.first_instance_iname == NULL)
		kc->compilation_data.first_instance_iname =
			Hierarchy::derive_iname_in(FIRST_INSTANCE_HL,
				RTKindDeclarations::iname(K), RTKindConstructors::package(kc));
	return kc->compilation_data.first_instance_iname;
}

inter_name *RTKindConstructors::next_instance_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	if (kc->compilation_data.next_instance_iname == NULL)
		kc->compilation_data.next_instance_iname =
			Hierarchy::derive_iname_in(NEXT_INSTANCE_HL,
				RTKindDeclarations::iname(K), RTKindConstructors::package(kc));
	return kc->compilation_data.next_instance_iname;
}

inter_name *RTKindConstructors::instance_count_iname(kind *K) {
	kind_constructor *kc = Kinds::get_construct(K);
	if (kc->compilation_data.instance_count_iname == NULL) {
		int N = Kinds::Behaviour::get_range_number(K), hl = -1;
		switch (N) {
			case 1: hl = COUNT_INSTANCE_1_HL; break;
			case 2: hl = COUNT_INSTANCE_2_HL; break;
			case 3: hl = COUNT_INSTANCE_3_HL; break;
			case 4: hl = COUNT_INSTANCE_4_HL; break;
			case 5: hl = COUNT_INSTANCE_5_HL; break;
			case 6: hl = COUNT_INSTANCE_6_HL; break;
			case 7: hl = COUNT_INSTANCE_7_HL; break;
			case 8: hl = COUNT_INSTANCE_8_HL; break;
			case 9: hl = COUNT_INSTANCE_9_HL; break;
			case 10: hl = COUNT_INSTANCE_10_HL; break;
		}
		if (hl == -1)
			kc->compilation_data.instance_count_iname =
				Hierarchy::derive_iname_in(COUNT_INSTANCE_HL, RTKindDeclarations::iname(K),
					RTKindConstructors::kind_package(K));
		else
			kc->compilation_data.instance_count_iname =
				Hierarchy::make_iname_in(hl, RTKindConstructors::kind_package(K));
	}
	return kc->compilation_data.instance_count_iname;
}

@ Convenient storage for some names.

=
inter_name *RTKindConstructors::get_kind_GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	if (kc->compilation_data.kind_GPR_iname == NULL) {
		package_request *R = RTKindConstructors::kind_package(K);
		kc->compilation_data.kind_GPR_iname =
			Hierarchy::make_iname_in(GPR_FN_HL, R);
	}
	return kc->compilation_data.kind_GPR_iname;
}

inter_name *RTKindConstructors::get_exp_kind_GPR_iname(kind *K) {
	inter_name *GPR = NULL;
	text_stream *GPR_fn_identifier = RTKindConstructors::get_explicit_I6_GPR(K);
	if (Str::len(GPR_fn_identifier) > 0)
		GPR = HierarchyLocations::find_by_name(Emit::tree(), GPR_fn_identifier);
	else
		GPR = RTKindConstructors::get_kind_GPR_iname(K);
	return GPR;
}

inter_name *RTKindConstructors::get_instance_GPR_iname(kind *K) {
	if (K == NULL) return NULL;
	kind_constructor *kc = Kinds::get_construct(K);
	if (kc->compilation_data.instance_GPR_iname == NULL) {
		package_request *R = RTKindConstructors::kind_package(K);
		kc->compilation_data.instance_GPR_iname =
			Hierarchy::make_iname_in(INSTANCE_GPR_FN_HL, R);
	}
	return kc->compilation_data.instance_GPR_iname;
}

@

=
inter_name *RTKindConstructors::get_iname(kind *K) {
	if (K == NULL) {
		if (K_number) return RTKindConstructors::get_iname(K_number);
		internal_error("null kind has no printing routine");
	}
	K = Kinds::weaken(K, K_object);
	if (K->construct->compilation_data.pr_iname)
		return K->construct->compilation_data.pr_iname;
	if (Str::len(K->construct->explicit_identifier) == 0) {
		package_request *R = RTKindConstructors::package(K->construct);
		K->construct->compilation_data.pr_iname = Hierarchy::make_iname_in(PRINT_DASH_FN_HL, R);
		return K->construct->compilation_data.pr_iname;
	}

	if (Kinds::eq(K, K_use_option)) {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_USE_OPTION_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_table))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_TABLE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_rulebook_outcome))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_RULEBOOK_OUTCOME_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_response))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_RESPONSE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_figure_name))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_FIGURE_NAME_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_sound_name))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_SOUND_NAME_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_external_file))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_EXTERNAL_FILE_NAME_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_internal_file))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_INTERNAL_FILE_NAME_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_scene))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_SCENE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_dialogue_beat))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_DIALOGUE_BEAT_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_dialogue_line))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_DIALOGUE_LINE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_dialogue_choice))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_DIALOGUE_CHOICE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Kinds::eq(K, K_performance_style))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_PERFORMANCE_STYLE_HL);
		Hierarchy::make_available(K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}

	package_request *R = NULL;
	int external = TRUE;
	if ((Kinds::get_construct(K) == CON_rule) ||
		(Kinds::get_construct(K) == CON_rulebook)) external = TRUE;
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		R = RTKindConstructors::kind_package(K); external = FALSE;
	}
	text_stream *X = K->construct->print_identifier;
	if (Kinds::Behaviour::is_quasinumerical(K)) {
		R = RTKindConstructors::kind_package(K); external = FALSE;
	}
	if (Kinds::eq(K, K_time)) external = TRUE;
	if (Kinds::eq(K, K_number)) external = TRUE;
	if (Kinds::eq(K, K_real_number)) external = TRUE;
	if (Str::len(X) == 0) X = I"DecimalNumber";

	if (R) {
		if (external) {
			K->construct->compilation_data.pr_iname = Hierarchy::make_iname_in(PRINT_FN_HL, R);
			inter_name *actual_iname = HierarchyLocations::find_by_name(Emit::tree(), X);
			Emit::iname_constant(K->construct->compilation_data.pr_iname, K_value, actual_iname);
		} else {
			WRITE_TO(STDERR, "identifier: '%S'\n", X);
			internal_error("internal but unknown kind printing routine");
		}
	} else {
		if (external) K->construct->compilation_data.pr_iname = HierarchyLocations::find_by_name(Emit::tree(), X);
		else internal_error("internal but unpackaged kind printing routine");
	}
	return K->construct->compilation_data.pr_iname;
}
package_request *RTKindConstructors::kind_package(kind *K) {
	return RTKindConstructors::package(K->construct);
}
inter_name *RTKindConstructors::get_inc_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no inc routine");
	if (K->construct->compilation_data.inc_iname) return K->construct->compilation_data.inc_iname;
	package_request *R = RTKindConstructors::kind_package(K);
	K->construct->compilation_data.inc_iname = Hierarchy::make_iname_in(DECREMENT_FN_HL, R);
	return K->construct->compilation_data.inc_iname;
}
inter_name *RTKindConstructors::get_dec_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no dec routine");
	if (K->construct->compilation_data.dec_iname) return K->construct->compilation_data.dec_iname;
	package_request *R = RTKindConstructors::kind_package(K);
	K->construct->compilation_data.dec_iname = Hierarchy::make_iname_in(INCREMENT_FN_HL, R);
	return K->construct->compilation_data.dec_iname;
}
inter_name *RTKindConstructors::get_ranger_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no ranger fn");
	if (K->construct->compilation_data.ranger_iname) return K->construct->compilation_data.ranger_iname;
	package_request *R = RTKindConstructors::kind_package(K);
	K->construct->compilation_data.ranger_iname = Hierarchy::make_iname_in(RANGER_FN_HL, R);
	return K->construct->compilation_data.ranger_iname;
}
inter_name *RTKindConstructors::get_mkdef_iname(kind_constructor *kc) {
	if (kc->compilation_data.mkdef_iname == NULL)
		kc->compilation_data.mkdef_iname =
			Hierarchy::make_iname_in(MKDEF_FN_HL, RTKindConstructors::package(kc));
	return kc->compilation_data.mkdef_iname;
}
inter_name *RTKindConstructors::get_debug_print_fn_iname(kind *K) {
	if (K == NULL) K = K_number;
	if (K->construct->compilation_data.debug_print_fn_iname)
		return K->construct->compilation_data.debug_print_fn_iname;
	if (Str::len(K->construct->explicit_identifier) == 0) {
		K->construct->compilation_data.debug_print_fn_iname = RTKindConstructors::get_iname(K);
		return K->construct->compilation_data.debug_print_fn_iname;
	}

	if (Str::len(K->construct->ACTIONS_identifier) > 0)
		K->construct->compilation_data.debug_print_fn_iname = 
			HierarchyLocations::find_by_name(Emit::tree(), K->construct->ACTIONS_identifier);
	else
		K->construct->compilation_data.debug_print_fn_iname =
			HierarchyLocations::find_by_name(Emit::tree(), I"DA_Name");
	return K->construct->compilation_data.debug_print_fn_iname;
}

inter_name *RTKindConstructors::get_explicit_I6_GPR_iname(kind *K) {
	if (K == NULL) internal_error("RTKindConstructors::get_explicit_I6_GPR on null kind");
	if (Str::len(K->construct->explicit_GPR_identifier) > 0)
		return HierarchyLocations::find_by_name(Emit::tree(), K->construct->explicit_GPR_identifier);
	return NULL;
}

inter_name *RTKindConstructors::get_distinguisher_iname(kind *K) {
	text_stream *N = Kinds::Behaviour::get_distinguisher(K);
	if (N == NULL) return NULL;
	return HierarchyLocations::find_by_name(Emit::tree(), N);
}

inter_name *RTKindConstructors::get_comparison_fn_iname(kind_constructor *kc) {
	return HierarchyLocations::find_by_name(Emit::tree(),
		KindConstructors::get_comparison_fn_identifier(kc));
}

inter_name *RTKindConstructors::get_support_fn_iname(kind_constructor *kc) {
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%S_Support", kc->explicit_identifier);
	inter_name *iname = HierarchyLocations::find_by_name(Emit::tree(), N);
	DISCARD_TEXT(N)
	return iname;
}

@ Moving on to understanding: some kinds can be used as tokens in Understand
sentences, others can't. Thus "[time]" is a valid Understand token, but
"[stored action]" is not.

Some kinds provide have a GPR ("general parsing routine", an I6 piece of
jargon) defined in some Inter kit: if so, this returns the GPR's name; if
not, it returns |NULL|.

=
text_stream *RTKindConstructors::get_explicit_I6_GPR(kind *K) {
	if (K == NULL) internal_error("RTKindConstructors::get_explicit_I6_GPR on null kind");
	return K->construct->explicit_GPR_identifier;
}

@ Can the kind have a GPR of any kind in the final code?

=
int RTKindConstructors::offers_I6_GPR(kind *K) {
	if (K == NULL) return FALSE;
	return KindConstructors::offers_I6_GPR(K->construct);
}

@ Request that a GPR be compiled for this kind; the return value tell us whether
this will be allowed or not.

=
int RTKindConstructors::request_I6_GPR(kind *K) {
	if (RTKindConstructors::offers_I6_GPR(K) == FALSE) return FALSE; /* can't oblige */
	if (K->construct->compilation_data.needs_GPR == FALSE) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "GPR for kind %u", K);
		if (Kinds::Behaviour::is_an_enumeration(K)) {
			K->construct->compilation_data.needs_GPR = TRUE;
			Sequence::queue(&KindGPRs::enumeration_agent, STORE_POINTER_kind(K), desc);
		} else if (Kinds::Behaviour::is_quasinumerical(K)) {
			K->construct->compilation_data.needs_GPR = TRUE;
			Sequence::queue(&KindGPRs::quasinumerical_agent, STORE_POINTER_kind(K), desc);
		}
		return TRUE;
	}
	return TRUE;
}

@ A recognition-only GPR is used for matching specific data in the course of
parsing names of objects, but not as a grammar token in its own right.

=
text_stream *RTKindConstructors::get_recognition_only_GPR(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->recognition_routine;
}

inter_name *RTKindConstructors::get_recognition_only_GPR_as_iname(kind *K) {
	text_stream *N = RTKindConstructors::get_recognition_only_GPR(K);
	if (N == NULL) return NULL;
	return HierarchyLocations::find_by_name(Emit::tree(), N);
}

@ The following is used only when the kind has named instances.

=
int RTKindConstructors::get_highest_valid_value_as_integer(kind *K) {
	if (K == NULL) return 0;
	return RTKindConstructors::get_highest_valid_value_as_integer_kc(K->construct);
}

int RTKindConstructors::get_highest_valid_value_as_integer_kc(kind_constructor *kc) {
	if (kc == NULL) return 0;
	if (kc == CON_activity) return NUMBER_CREATED(activity);
	if (kc == Kinds::get_construct(K_equation)) return NUMBER_CREATED(equation);
	if (kc == CON_rule) return NUMBER_CREATED(booking);
	if (kc == CON_rulebook) return NUMBER_CREATED(rulebook);
	if (kc == Kinds::get_construct(K_table)) return NUMBER_CREATED(table) + 1;
	if (kc == Kinds::get_construct(K_use_option)) return NUMBER_CREATED(use_option);
	if (kc == Kinds::get_construct(K_response)) return NUMBER_CREATED(response_message);
	return kc->next_free_value - 1;
}

@h Compilation.

=
int RTKindConstructors::is_subkind_of_object(kind_constructor *kc) {
	if (Kinds::Behaviour::is_subkind_of_object(Kinds::base_construction(kc)))
		return TRUE;
	return FALSE;
}

int RTKindConstructors::is_object(kind_constructor *kc) {
	if (Kinds::Behaviour::is_object(Kinds::base_construction(kc))) return TRUE;
	return FALSE;
}

void RTKindConstructors::compile(void) {
	RTKindConstructors::assign_declaration_sequence_numbers();
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		package_request *pack = RTKindConstructors::package(kc);

		Emit::numeric_constant(RTKindConstructors::xref_iname(kc), 561);	
			
		Emit::numeric_constant(RTKindConstructors::weak_ID_iname(kc), 0);
		Hierarchy::make_available(RTKindConstructors::weak_ID_iname(kc));

		TEMPORARY_TEXT(S)
		WRITE_TO(S, "%+W", KindConstructors::get_name(kc, FALSE));
		Hierarchy::apply_metadata(pack,
			KIND_PNAME_MD_HL, S);
		DISCARD_TEXT(S)

		inference *inf;
		int made_exp = FALSE;
		KNOWLEDGE_LOOP(inf, KindSubjects::from_kind(K), property_inf)
			if (PropertyInferences::get_property(inf) == P_specification) {
				parse_node *spec = PropertyInferences::get_value(inf);
				TEMPORARY_TEXT(exp)
				IndexUtilities::dequote(exp, Lexer::word_raw_text(Wordings::first_wn(Node::get_text(spec))));
				Hierarchy::apply_metadata(pack, KIND_SPECIFICATION_MD_HL, exp);
				DISCARD_TEXT(exp)
				made_exp = TRUE;
				break;
			}
		if ((made_exp == FALSE) && (RTKindConstructors::is_subkind_of_object(kc) == FALSE)) {
			text_stream *exp = Kinds::Behaviour::get_specification_text(K);
			if (Str::len(exp) > 0)
				Hierarchy::apply_metadata(pack, KIND_SPECIFICATION_MD_HL, exp);
		}
		Hierarchy::apply_metadata_from_number(pack,
			KIND_IS_BASE_MD_HL, 1);
		if (KindConstructors::is_arithmetic(kc))
			Hierarchy::apply_metadata_from_number(pack, KIND_IS_QUASINUMERICAL_MD_HL, 1);
		if (RTKindConstructors::is_object(kc)) {
			Hierarchy::apply_metadata_from_number(pack, KIND_IS_OBJECT_MD_HL, 1);
		} else {
			Hierarchy::apply_metadata_from_number(pack, KIND_IS_OBJECT_MD_HL, 0);
		}
		if (RTKindConstructors::is_subkind_of_object(kc)) {
			kind *super_K = Latticework::super(K);
			Hierarchy::apply_metadata_from_number(pack, KIND_IS_SKOO_MD_HL, 1);
			TEMPORARY_TEXT(SK)
			WRITE_TO(SK, "%u", super_K);
			Hierarchy::apply_metadata(pack, INDEX_SUPERKIND_MD_HL, SK);
			DISCARD_TEXT(SK)
			Hierarchy::apply_metadata_from_iname(pack, SUPERKIND_MD_HL,
				RTKindConstructors::weak_ID_iname(super_K->construct));
		} else {
			Hierarchy::apply_metadata_from_number(pack, KIND_IS_SKOO_MD_HL, 0);
		}
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			wording W = Kinds::Behaviour::get_name(K, FALSE);
			if (Wordings::nonempty(W)) {
				TEMPORARY_TEXT(temp)
				WRITE_TO(temp, "kind_%N", Wordings::first_wn(W));
				if (DocReferences::validate_if_possible(temp))
					Kinds::Behaviour::set_documentation_reference(K, temp);
				DISCARD_TEXT(temp)
			}
		}
		text_stream *DR = Kinds::Behaviour::get_documentation_reference(K);
		if (Str::len(DR) > 0)
			Hierarchy::apply_metadata(pack, KIND_DOCUMENTATION_MD_HL, DR);
		if (Kinds::is_proper_constructor(K)) {
			TEMPORARY_TEXT(CONS)
			int i, a = KindConstructors::arity(Kinds::get_construct(K));
			if ((a == 2) &&
				(KindConstructors::variance(Kinds::get_construct(K), 0) ==
					KindConstructors::variance(Kinds::get_construct(K), 1)))
				a = 1;
			for (i=0; i<a; i++) {
				if (i > 0) WRITE_TO(CONS, ", ");
				if (KindConstructors::variance(Kinds::get_construct(K), i) > 0)
					WRITE_TO(CONS, "covariant");
				else
					WRITE_TO(CONS, "contravariant");
				if (a > 1) WRITE_TO(CONS, " in %c", 'K'+i);
			}
			Hierarchy::apply_metadata(pack, KIND_INDEX_VARIANCE_MD_HL, CONS);
			DISCARD_TEXT(CONS)	
		}
		

		Hierarchy::apply_metadata_from_number(pack, KIND_INDEX_PRIORITY_MD_HL,
			(inter_ti) Kinds::Behaviour::get_index_priority(K));
		if (RTKindConstructors::is_subkind_of_object(kc)) {
			Hierarchy::apply_metadata_from_iname(pack,
				KIND_CLASS_MD_HL, RTKindDeclarations::iname(Kinds::base_construction(kc)));
		}
		if (KindConstructors::is_definite(kc)) {
			Hierarchy::apply_metadata_from_number(pack,
				KIND_IS_DEF_MD_HL, 1);
		} else {
			Hierarchy::apply_metadata_from_number(pack,
				KIND_IS_DEF_MD_HL, 0);
		}		
		if (KindConstructors::uses_block_values(kc)) {
			Hierarchy::apply_metadata_from_number(pack,
				KIND_HAS_BV_MD_HL, 1);
		} else {
			Hierarchy::apply_metadata_from_number(pack,
				KIND_HAS_BV_MD_HL, 0);
		}		
		inter_name *weak_iname = RTKindIDs::weak_iname_of_constructor(kc);
		if (weak_iname == NULL) internal_error("no iname for weak ID");
		Hierarchy::apply_metadata_from_iname(pack,
			KIND_WEAK_ID_MD_HL, weak_iname);
		Hierarchy::apply_metadata_from_iname(pack,
			KIND_STRONG_ID_MD_HL, RTKindConstructors::weak_ID_iname(kc));
		if (KindConstructors::uses_block_values(kc)) {
			inter_name *sf_iname = RTKindConstructors::get_support_fn_iname(kc);
			if (sf_iname)
				Hierarchy::apply_metadata_from_iname(pack,
					KIND_SUPPORT_FN_MD_HL, sf_iname);
			else internal_error("kind with block values but no support function");
		}

		if ((RTKindConstructors::is_subkind_of_object(kc) == FALSE) &&
			(KindConstructors::is_definite(kc)) &&
			(KindConstructors::uses_signed_comparisons(kc) == FALSE)) {
			inter_name *cf_iname = RTKindConstructors::get_comparison_fn_iname(kc);
			if (cf_iname)
				Hierarchy::apply_metadata_from_iname(pack,
					KIND_CMP_FN_MD_HL, cf_iname);
			else internal_error("kind with no comparison function");
		}
		if (Kinds::Behaviour::definite(Kinds::base_construction(kc))) {
			inter_name *mkdef_iname = RTKindConstructors::get_mkdef_iname(kc);
			Hierarchy::apply_metadata_from_iname(pack,
				KIND_MKDEF_FN_MD_HL, mkdef_iname);
		}
		if (RTKindConstructors::is_subkind_of_object(kc) == FALSE) {
			inter_name *printing_rule_name =
				RTKindConstructors::get_iname(Kinds::base_construction(kc));
			if (printing_rule_name)
				Hierarchy::apply_metadata_from_iname(pack,
					KIND_PRINT_FN_MD_HL, printing_rule_name);
		}
		if ((RTKindConstructors::is_subkind_of_object(kc) == FALSE) &&
			(KindConstructors::is_an_enumeration(kc)))
				Hierarchy::apply_metadata_from_number(pack,
					KIND_DSIZE_MD_HL,
					(inter_ti) RTKindConstructors::get_highest_valid_value_as_integer_kc(kc));

		if (Kinds::Behaviour::definite(Kinds::base_construction(kc))) {
			inter_name *mkdef_iname = RTKindConstructors::get_mkdef_iname(kc);
			packaging_state save = Functions::begin(mkdef_iname);
			inter_symbol *sk_s = LocalVariables::new_other_as_symbol(I"sk");
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				if (KindConstructors::uses_block_values(kc)) {
					inter_name *iname = Hierarchy::find(BLKVALUECREATE_HL);
					EmitCode::call(iname);
					EmitCode::down();
						EmitCode::val_symbol(K_value, sk_s);
					EmitCode::up();
				} else {
					if (RTKindConstructors::is_subkind_of_object(kc))
						EmitCode::val_false();
					else
						DefaultValues::val(Kinds::base_construction(kc),
							EMPTY_WORDING, "default value");
				}
			EmitCode::up();
			Functions::end(save);
		}
		
		if ((Kinds::Behaviour::is_an_enumeration(K)) || (Kinds::Behaviour::is_object(K))) {
			TEMPORARY_TEXT(ICN)
			WRITE_TO(ICN, "ICOUNT_");
			Kinds::Textual::write(ICN, K);
			Str::truncate(ICN, 31);
			LOOP_THROUGH_TEXT(pos, ICN) {
				Str::put(pos, Characters::toupper(Str::get(pos)));
				if (Characters::isalnum(Str::get(pos)) == FALSE) Str::put(pos, '_');
			}
			inter_name *iname = Hierarchy::make_iname_with_specific_translation(ICOUNT_HL,
				InterSymbolsTable::render_identifier_unique(LargeScale::main_scope(Emit::tree()), ICN),
				RTKindConstructors::kind_package(K));
			Hierarchy::make_available(iname);
			DISCARD_TEXT(ICN)
			Emit::numeric_constant(iname, (inter_ti) Instances::count(K));
			
			if (Kinds::eq(K, K_room)) {
				inter_name *iname = 
					Hierarchy::make_iname_in(FWMATRIX_SIZE_HL, RTKindConstructors::kind_package(K));
				Hierarchy::make_available(iname);
				inter_ti val = 0;
				if (TargetVMs::is_16_bit(Task::vm()) == FALSE)
					val = (inter_ti) (Instances::count(K)*Instances::count(K));
				if (global_compilation_settings.fast_route_finding)
					val = (inter_ti) (Instances::count(K)*Instances::count(K));
				if (global_compilation_settings.slow_route_finding)
					val = 0;
				if (val <= 1) val = 2;
				Emit::numeric_constant(iname, (inter_ti) val);
			}
		}
		if (Kinds::Behaviour::is_object(K)) {
			Hierarchy::apply_metadata_from_number(RTKindConstructors::kind_package(K),
				KIND_IS_OBJECT_MD_HL, 1);
		} else {
			Hierarchy::apply_metadata_from_number(RTKindConstructors::kind_package(K),
				KIND_IS_OBJECT_MD_HL, 0);
		}

		if (Kinds::Behaviour::is_object(K)) {
			if (RTShowmeCommand::needed_for_kind(K)) {
				inter_name *iname = Hierarchy::make_iname_in(SHOWME_FN_HL,
					RTKindConstructors::kind_package(K));
				RTShowmeCommand::compile_kind_showme_fn(iname, K);
				Hierarchy::apply_metadata_from_iname(RTKindConstructors::kind_package(K),
					KIND_SHOWME_MD_HL, iname);
			}
		}

		if (Kinds::eq(K, K_players_holdall))
			Hierarchy::apply_metadata_from_number(pack, RUCKSACK_CLASS_MD_HL, 1);

		@<Compile data support functions@>;
		
		if (kc->compilation_data.declaration_sequence_number >= 0)
			Hierarchy::apply_metadata_from_number(pack, KIND_DECLARATION_ORDER_MD_HL,
				(inter_ti) kc->compilation_data.declaration_sequence_number);

		if ((Kinds::Behaviour::is_quasinumerical(K)) && (Kinds::is_intermediate(K) == FALSE)) {
			TEMPORARY_TEXT(OUT)
			@<Index the minimum positive value for a quasinumerical kind@>;
			Hierarchy::apply_metadata(pack, MIN_VAL_INDEX_MD_HL, OUT);
			Str::clear(OUT);
			@<Index the maximum positive value for a quasinumerical kind@>;
			Hierarchy::apply_metadata(pack, MAX_VAL_INDEX_MD_HL, OUT);
			Str::clear(OUT);
			@<Index the dimensions for a quasinumerical kind@>;
			Hierarchy::apply_metadata(pack, DIMENSIONS_INDEX_MD_HL, OUT);
			DISCARD_TEXT(OUT)
		}

		if ((RTKindConstructors::get_highest_valid_value_as_integer(K) == 0) &&
			(Kinds::Behaviour::indexed_grey_if_empty(K)))
			Hierarchy::apply_metadata_from_number(pack, KIND_SHADED_MD_HL, 1);
		if (Deferrals::has_finite_domain(K))
			Hierarchy::apply_metadata_from_number(pack, KIND_FINITE_DOMAIN_MD_HL, 1);
		if (KindSubjects::has_properties(K))
			Hierarchy::apply_metadata_from_number(pack, KIND_HAS_PROPERTIES_MD_HL, 1);
		if (RTKindConstructors::offers_I6_GPR(K))
			Hierarchy::apply_metadata_from_number(pack, KIND_UNDERSTANDABLE_MD_HL, 1);
		if (Instances::count(K) > 0)
			Hierarchy::apply_metadata_from_number(pack, KIND_INSTANCE_COUNT_MD_HL,
				(inter_ti) Instances::count(K));
		TEMPORARY_TEXT(IDV)
		int found = FALSE;
		instance *inst;
		LOOP_OVER_INSTANCES(inst, K) {
			Instances::write_name(IDV, inst);
			found = TRUE;
			break;
		}
		if (found == FALSE) {
			text_stream *p = Kinds::Behaviour::get_index_default_value(K);
			if (Str::eq_wide_string(p, L"<0-in-literal-pattern>"))
				@<Index the constant 0 but use the default literal pattern@>
			else if (Str::eq_wide_string(p, L"<first-constant>"))
				WRITE_TO(IDV, "--");
			else WRITE_TO(IDV, "%S", p);
		}
		Hierarchy::apply_metadata(pack, KIND_INDEX_DEFAULT_MD_HL, IDV);
		DISCARD_TEXT(IDV)
		
		TEMPORARY_TEXT(SN)
		RTKindConstructors::index_name(SN, K, FALSE);
		if (Str::len(SN) > 0) Hierarchy::apply_metadata(pack, KIND_INDEX_SINGULAR_MD_HL, SN);
		DISCARD_TEXT(SN)
		
		TEMPORARY_TEXT(PN)
		RTKindConstructors::index_name(PN, K, TRUE);
		if (Str::len(PN) > 0) Hierarchy::apply_metadata(pack, KIND_INDEX_PLURAL_MD_HL, PN);
		DISCARD_TEXT(PN)

		kind *K2;
		LOOP_OVER_BASE_KINDS(K2) {
			if ((Kinds::Behaviour::is_kind_of_kind(K2)) && (Kinds::conforms_to(K, K2))
				 && (Kinds::eq(K2, K_pointer_value) == FALSE)
				 && (Kinds::eq(K2, K_stored_value) == FALSE)) {
				package_request *R =
					Hierarchy::package_within(KIND_CONFORMANCE_HAP, pack);
				Hierarchy::apply_metadata_from_iname(R, CONFORMED_TO_MD_HL,
					RTKindConstructors::xref_iname(K2->construct));
			}
		}

		if (LiteralPatterns::list_of_literal_forms(K)) {
			TEMPORARY_TEXT(LF)
			LiteralPatterns::index_all(LF, K);
			Hierarchy::apply_metadata(pack, KIND_INDEX_NOTATION_MD_HL, LF);
			DISCARD_TEXT(LF)
		}

		RTInferences::index(pack, KIND_BRIEF_INFERENCES_MD_HL, KindSubjects::from_kind(K), TRUE);
		RTInferences::index(pack, KIND_INFERENCES_MD_HL, KindSubjects::from_kind(K), FALSE);
	}
	@<Compile multiplication rules for the index@>;
}

@ For every quasinumeric kind the default value is 0, but we don't want to
index just "0" because that means 0-as-a-number: we want it to come out
as "0 kg", "0 hectares", or whatever is appropriate.

@<Index the constant 0 but use the default literal pattern@> =
	if (LiteralPatterns::list_of_literal_forms(K))
		LiteralPatterns::index_value(IDV,
			LiteralPatterns::list_of_literal_forms(K), 0);
	else
		WRITE_TO(IDV, "--");

@<Index the minimum positive value for a quasinumerical kind@> =
	if (Kinds::eq(K, K_number)) WRITE("1");
	else {
		text_stream *p = Kinds::Behaviour::get_index_minimum_value(K);
		if (Str::len(p) > 0) WRITE("%S", p);
		else LiteralPatterns::index_value(OUT,
			LiteralPatterns::list_of_literal_forms(K), 1);
	}

@<Index the maximum positive value for a quasinumerical kind@> =
	if (Kinds::eq(K, K_number)) {
		if (TargetVMs::is_16_bit(Task::vm())) WRITE("32767");
		else WRITE("2147483647");
	} else {
		text_stream *p = Kinds::Behaviour::get_index_maximum_value(K);
		if (Str::len(p) > 0) WRITE("%S", p);
		else {
			if (TargetVMs::is_16_bit(Task::vm()))
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(K), 32767);
			else
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(K), 2147483647);
		}
	}

@<Index the dimensions for a quasinumerical kind@> =
	if (Kinds::Dimensions::dimensionless(K) == FALSE) {
		unit_sequence *deriv = Kinds::Behaviour::get_dimensional_form(K);
		Kinds::Dimensions::index_unit_sequence(OUT, deriv, TRUE);
	}

@<Compile multiplication rules for the index@> =
	kind *L, *R, *O;
	int wn;
	LOOP_OVER_MULTIPLICATIONS(L, R, O, wn) {
		package_request *pack = Hierarchy::completion_package(MULTIPLICATION_RULE_HAP);
		if (wn >= 0) Hierarchy::apply_metadata_from_number(pack, SET_AT_MD_HL, (inter_ti) wn);
		TEMPORARY_TEXT(OUT)
		WRITE_TO(OUT, "%u", L);
		Hierarchy::apply_metadata(pack, LEFT_OPERAND_MD_HL, OUT);
		Str::clear(OUT);
		WRITE_TO(OUT, "%u", R);
		Hierarchy::apply_metadata(pack, RIGHT_OPERAND_MD_HL, OUT);
		Str::clear(OUT);
		WRITE_TO(OUT, "%u", O);
		Hierarchy::apply_metadata(pack, RESULT_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, L);
		Hierarchy::apply_metadata(pack, LEFT_OPERAND_BM_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, R);
		Hierarchy::apply_metadata(pack, RIGHT_OPERAND_BM_MD_HL, OUT);
		Str::clear(OUT);
		LiteralPatterns::index_benchmark_value(OUT, O);
		Hierarchy::apply_metadata(pack, RESULT_BM_MD_HL, OUT);
		DISCARD_TEXT(OUT)
	}

@

=
void RTKindConstructors::index_name(OUTPUT_STREAM, kind *K, int plural) {
	wording W = Kinds::Behaviour::get_name(K, plural);
	if (Wordings::nonempty(W)) {
		if (Kinds::is_proper_constructor(K)) {
			@<Index the constructor text@>;
		} else {
			WRITE("%W", W);
		}
	}
}

@<Index the constructor text@> =
	int length = Wordings::length(W), w1 = Wordings::first_wn(W), tinted = TRUE;
	int i, first_stroke = -1, last_stroke = -1;
	for (i=0; i<length; i++) {
		if (Lexer::word(w1+i) == STROKE_V) {
			if (first_stroke == -1) first_stroke = i;
			last_stroke = i;
		}
	}
	int from = 0, to = length-1;
	if (last_stroke >= 0) from = last_stroke+1; else tinted = FALSE;
	if (tinted) HTML::begin_span(OUT, I"indexgrey");
	for (i=from; i<=to; i++) {
		int j, untinted = FALSE;
		for (j=0; j<first_stroke; j++)
			if (Lexer::word(w1+j) == Lexer::word(w1+i))
				untinted = TRUE;
		if (untinted) HTML::end_span(OUT);
		if (i>from) WRITE(" ");
		if (Lexer::word(w1+i) == CAPITAL_K_V) WRITE("K");
		else if (Lexer::word(w1+i) == CAPITAL_L_V) WRITE("L");
		else WRITE("%V", Lexer::word(w1+i));
		if (untinted) HTML::begin_span(OUT, I"indexgrey");
	}
	if (tinted) HTML::end_span(OUT);

@

=
inter_ti kind_sequence_counter = 0;

void RTKindConstructors::assign_declaration_sequence_numbers(void) {
	int N = 0;
	RTKindConstructors::assign_dsn_r(&N, KindSubjects::from_kind(K_object));
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		if ((RTKindDeclarations::base_represented_in_Inter(K)) &&
			(KindSubjects::has_properties(K)) &&
			(Kinds::Behaviour::is_object(K) == FALSE))
			K->construct->compilation_data.declaration_sequence_number = N++;
	}
}

void RTKindConstructors::assign_dsn_r(int *N, inference_subject *within) {
	kind *K = KindSubjects::to_kind(within);
	K->construct->compilation_data.declaration_sequence_number = (*N)++;
	inference_subject *subj;
	LOOP_OVER(subj, inference_subject)
		if ((InferenceSubjects::narrowest_broader_subject(subj) == within) &&
			(InferenceSubjects::is_a_kind_of_object(subj)))
			RTKindConstructors::assign_dsn_r(N, subj);
}

@

=
void RTKindConstructors::compile_permissions(void) {
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		if ((kc == CON_KIND_VARIABLE) || (kc == CON_INTERMEDIATE)) continue;
		kind *K = Kinds::base_construction(kc);
		if (RTKindDeclarations::base_represented_in_Inter(K)) {
			RTPropertyPermissions::emit_kind_permissions(K);
			RTPropertyValues::compile_values_for_kind(K);
		}
	}
}

@<Compile data support functions@> =
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		inter_name *printing_rule_name = RTKindConstructors::get_iname(K);
		@<Compile I6 printing routine for an enumerated kind@>;
		@<Compile the A and B routines for an enumerated kind@>;
		@<Compile random-ranger routine for this kind@>;
	}
	if ((Kinds::Behaviour::is_built_in(K) == FALSE) &&
		(Kinds::Behaviour::is_subkind_of_object(K) == FALSE) &&
		(Kinds::Behaviour::is_an_enumeration(K) == FALSE)) {
		if (Kinds::eq(K, K_use_option)) {
			inter_name *printing_rule_name = RTKindConstructors::get_iname(K);
			packaging_state save = Functions::begin(printing_rule_name);
			inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
			EmitCode::call(Hierarchy::find(PRINT_USE_OPTION_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, value_s);
			EmitCode::up();
			Functions::end(save);
			continue;
		}
		if (Kinds::eq(K, K_table)) {
			inter_name *printing_rule_name = RTKindConstructors::get_iname(K);
			packaging_state save = Functions::begin(printing_rule_name);
			inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
			EmitCode::call(Hierarchy::find(PRINT_TABLE_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, value_s);
			EmitCode::up();
			Functions::end(save);
			continue;
		}
		if (Kinds::eq(K, K_response)) {
			inter_name *printing_rule_name = RTKindConstructors::get_iname(K);
			packaging_state save = Functions::begin(printing_rule_name);
			inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
			EmitCode::call(Hierarchy::find(PRINT_RESPONSE_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, value_s);
			EmitCode::up();
			Functions::end(save);
			continue;
		}
		inter_name *printing_rule_name = RTKindConstructors::get_iname(K);
		if (Kinds::Behaviour::is_quasinumerical(K)) {
			@<Compile I6 printing routine for a unit kind@>;
			@<Compile random-ranger routine for this kind@>;
		} else {
			@<Compile I6 printing routine for a vacant but named kind@>;
		}
	}

@ A slightly bogus case first. If the source text declares a kind but never
gives any enumerated values or literal patterns, then such values will never
appear at run-time; but we need the printing routine to exist to avoid
compilation errors.

@<Compile I6 printing routine for a vacant but named kind@> =
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "weak kind ID: %n\n", RTKindIDs::weak_iname(K));
	EmitCode::comment(C);
	DISCARD_TEXT(C)
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, value_s);
	EmitCode::up();
	Functions::end(save);

@ A unit is printed back with its earliest-defined literal pattern used as
notation. If it had no literal patterns, it would come out as decimal numbers,
but at present this can't happen.

@<Compile I6 printing routine for a unit kind@> =
	if (LiteralPatterns::list_of_literal_forms(K))
		RTLiteralPatterns::printing_routine(printing_rule_name,
			LiteralPatterns::list_of_literal_forms(K));
	else {
		packaging_state save = Functions::begin(printing_rule_name);
		inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, value_s);
		EmitCode::up();
		Functions::end(save);
	}

@<Compile I6 printing routine for an enumerated kind@> =
	packaging_state save = Functions::begin(printing_rule_name);
	inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, value_s);
		EmitCode::code();
		EmitCode::down();
			instance *I;
			LOOP_OVER_INSTANCES(I, K) {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTInstances::value_iname(I));
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(PRINT_BIP);
						EmitCode::down();
							TEMPORARY_TEXT(CT)
							wording NW = Instances::get_name_in_play(I, FALSE);
							LOOP_THROUGH_WORDING(k, NW) {
								TranscodeText::from_wide_string(CT, Lexer::word_raw_text(k), CT_RAW);
								if (k < Wordings::last_wn(NW)) WRITE_TO(CT, " ");
							}
							EmitCode::val_text(CT);
							DISCARD_TEXT(CT)
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::inv(DEFAULT_BIP); /* this default case should never be needed, unless the user has blundered at the I6 level: */
			EmitCode::down();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						TEMPORARY_TEXT(DT)
						wording W = Kinds::Behaviour::get_name(K, FALSE);
						WRITE_TO(DT, "<illegal ");
						if (Wordings::nonempty(W)) WRITE_TO(DT, "%W", W);
						else WRITE_TO(DT, "value");
						WRITE_TO(DT, ">");
						EmitCode::val_text(DT);
						DISCARD_TEXT(DT)
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	Functions::end(save);

@ The suite of standard routines provided for enumerative types is a little
like the one in Ada (|T'Succ|, |T'Pred|, and so on).

If the type is called, say, |T1_colour|, then we have:

(a) |A_T1_colour(v)| advances to the next valid value for the type,
wrapping around to the first from the last;
(b) |B_T1_colour(v)| goes back to the previous valid value for the type,
wrapping around to the last from the first, so that it is the inverse function
to |A_T1_colour(v)|.

@<Compile the A and B routines for an enumerated kind@> =
	int instance_count = 0;
	instance *I;
	LOOP_OVER_INSTANCES(I, K) instance_count++;

	inter_name *iname_i = RTKindConstructors::get_inc_iname(K);
	packaging_state save = Functions::begin(iname_i);
	@<Implement the A routine@>;
	Functions::end(save);

	inter_name *iname_d = RTKindConstructors::get_dec_iname(K);
	save = Functions::begin(iname_d);
	@<Implement the B routine@>;
	Functions::end(save);

@ There should be a blue historical plaque on the wall here: this was the
first function ever implemented by emitting Inter code, on 12 November 2017.

@<Implement the A routine@> =
	local_variable *lv_x = LocalVariables::new_other_parameter(I"x");
	LocalVariables::set_kind(lv_x, K);
	inter_symbol *x = LocalVariables::declare(lv_x);

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();

	if (instance_count <= 1) {
		EmitCode::val_symbol(K, x);
	} else {
		EmitCode::cast(K_number, K);
		EmitCode::down();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MODULO_BIP);
				EmitCode::down();
					EmitCode::cast(K, K_number);
					EmitCode::down();
						EmitCode::val_symbol(K, x);
					EmitCode::up();
					EmitCode::val_number((inter_ti) instance_count);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	}

	EmitCode::up();

@ And this was the second, a few minutes later.

@<Implement the B routine@> =
	local_variable *lv_x = LocalVariables::new_other_parameter(I"x");
	LocalVariables::set_kind(lv_x, K);
	inter_symbol *x = LocalVariables::declare(lv_x);

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();

	if (instance_count <= 1) {
		EmitCode::val_symbol(K, x);
	} else {
		EmitCode::cast(K_number, K);
		EmitCode::down();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MODULO_BIP);
				EmitCode::down();

				if (instance_count > 2) {
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::cast(K, K_number);
						EmitCode::down();
							EmitCode::val_symbol(K, x);
						EmitCode::up();
						EmitCode::val_number((inter_ti) instance_count-2);
					EmitCode::up();
				} else {
					EmitCode::cast(K, K_number);
					EmitCode::down();
						EmitCode::val_symbol(K, x);
					EmitCode::up();
				}

					EmitCode::val_number((inter_ti) instance_count);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	}

	EmitCode::up();

@ And here we add:

(a) |R_T1_colour()| returns a uniformly random choice of the valid
values of the given type. (For a unit, this will be a uniformly random positive
value, which will probably not be useful.)
(b) |R_T1_colour(a, b)| returns a uniformly random choice in between |a|
and |b| inclusive.

@<Compile random-ranger routine for this kind@> =
	inter_name *iname_r = RTKindConstructors::get_ranger_iname(K);
	packaging_state save = Functions::begin(iname_r);
	inter_symbol *a_s = LocalVariables::new_other_as_symbol(I"a");
	inter_symbol *b_s = LocalVariables::new_other_as_symbol(I"b");

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, a_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, b_s);
				EmitCode::val_number(0);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::inv(RANDOM_BIP);
				EmitCode::down();
					if (Kinds::Behaviour::is_quasinumerical(K))
						EmitCode::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
					else
						EmitCode::val_number((inter_ti) RTKindConstructors::get_highest_valid_value_as_integer(K));
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, a_s);
			EmitCode::val_symbol(K_value, b_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, b_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	inter_symbol *smaller = NULL, *larger = NULL;

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, a_s);
			EmitCode::val_symbol(K_value, b_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				smaller = b_s; larger = a_s;
				@<Formula for range@>;
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		smaller = a_s; larger = b_s;
		@<Formula for range@>;
	EmitCode::up();

	Functions::end(save);

@<Formula for range@> =
	EmitCode::inv(PLUS_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, smaller);
		EmitCode::inv(MODULO_BIP);
		EmitCode::down();
			EmitCode::inv(RANDOM_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
			EmitCode::up();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(MINUS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, larger);
					EmitCode::val_symbol(K_value, smaller);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

