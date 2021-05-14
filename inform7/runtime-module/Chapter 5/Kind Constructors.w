[RTKindConstructors::] Kind Constructors.

Hmmm.

@h Inter identifiers.
An identifier like |WHATEVER_TY|, then, begins life in a definition inside an
Neptune file; becomes attached to a constructor here; and finally winds up
back in Inter code, because we define it as the constant for the weak kind ID
of the kind which the constructor makes:

=
typedef struct kind_constructor_compilation_data {
	struct inter_name *con_iname;
	struct inter_name *list_iname;
	struct package_request *kc_package;
	struct inter_name *kind_GPR_iname;
	struct inter_name *instance_GPR_iname;
	struct inter_name *first_instance_iname;
	struct inter_name *next_instance_iname;
	struct inter_name *pr_iname;
	struct inter_name *inc_iname;
	struct inter_name *dec_iname;
	struct inter_name *mkdef_iname;
	struct inter_name *ranger_iname;
	struct inter_name *trace_iname;
} kind_constructor_compilation_data;

kind_constructor_compilation_data RTKindConstructors::new_compilation_data(kind_constructor *kc) {
	kind_constructor_compilation_data kccd;
	kccd.con_iname = NULL;
	kccd.kc_package = NULL;
	kccd.list_iname = NULL;
	kccd.kind_GPR_iname = NULL;
	kccd.instance_GPR_iname = NULL;
	kccd.first_instance_iname = NULL;
	kccd.next_instance_iname = NULL;
	kccd.pr_iname = NULL;
	kccd.inc_iname = NULL;
	kccd.dec_iname = NULL;
	kccd.mkdef_iname = NULL;
	kccd.ranger_iname = NULL;
	kccd.trace_iname = NULL;
//	if (Str::len(kc->name_in_template_code) == 0) {
//		package_request *R = RTKindConstructors::package(kc);
//		kccd.pr_iname = Hierarchy::make_iname_in(PRINT_DASH_FN_HL, R);
//		kccd.trace_iname = kccd.pr_iname;
//	}
	return kccd;
}

void RTKindConstructors::restart_copied_compilation_data(kind_constructor *kc) {
	kc->compilation_data.con_iname = NULL;
	kc->compilation_data.kc_package = NULL;
	kc->compilation_data.list_iname = NULL;
}

void RTKindConstructors::emit_constants(void) {
	kind_constructor *kc;
	LOOP_OVER(kc, kind_constructor) {
		Emit::numeric_constant(RTKindConstructors::iname(kc), 0);
		Hierarchy::make_available(RTKindConstructors::iname(kc));
	}
}
inter_name *RTKindConstructors::UNKNOWN_iname(void) {
	return CON_UNKNOWN->compilation_data.con_iname;
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
		wording W = Kinds::Constructors::get_name(kc, FALSE);
		if (Wordings::nonempty(W))
			Hierarchy::apply_metadata_from_wording(kc->compilation_data.kc_package, KIND_NAME_MD_HL, W);
		else if (Str::len(kc->name_in_template_code) > 0)
			Hierarchy::apply_metadata(kc->compilation_data.kc_package, KIND_NAME_MD_HL,
				kc->name_in_template_code);
		else
			Hierarchy::apply_metadata(kc->compilation_data.kc_package, KIND_NAME_MD_HL, I"(anonymous kind)");
	}
	return kc->compilation_data.kc_package;
}
inter_name *RTKindConstructors::iname(kind_constructor *kc) {
	if (kc->compilation_data.con_iname == NULL) {
		if (Str::len(kc->name_in_template_code) > 0) {
			kc->compilation_data.con_iname = Hierarchy::make_iname_with_specific_translation(WEAK_ID_HL,
				kc->name_in_template_code, RTKindConstructors::package(kc));
			Hierarchy::make_available(kc->compilation_data.con_iname);
		} else {
			TEMPORARY_TEXT(wn)
			WRITE_TO(wn, "WEAK_ID_%d", kc->allocation_id);
			kc->compilation_data.con_iname = Hierarchy::make_iname_with_specific_translation(WEAK_ID_HL,
				wn, RTKindConstructors::package(kc));
			DISCARD_TEXT(wn)
		}
	}
	return kc->compilation_data.con_iname;
}

inter_name *RTKindConstructors::list_iname(kind_constructor *kc) {
	return kc->compilation_data.list_iname;
}
void RTKindConstructors::set_list_iname(kind_constructor *kc, inter_name *iname) {
	kc->compilation_data.list_iname = iname;
}
inter_name *RTKindConstructors::first_instance_iname(kind_constructor *kc) {
	return kc->compilation_data.first_instance_iname;
}
void RTKindConstructors::set_first_instance_iname(kind_constructor *kc, inter_name *iname) {
	kc->compilation_data.first_instance_iname = iname;
}
inter_name *RTKindConstructors::next_instance_iname(kind_constructor *kc) {
	return kc->compilation_data.next_instance_iname;
}
void RTKindConstructors::set_next_instance_iname(kind_constructor *kc, inter_name *iname) {
	kc->compilation_data.next_instance_iname = iname;
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
	if (K->construct->compilation_data.pr_iname) {
		if (Kinds::Behaviour::is_subkind_of_object(K)) LOG("I reckon %u --> %n\n", K, K->construct->compilation_data.pr_iname);
		return K->construct->compilation_data.pr_iname;
	}
	if (Str::len(K->construct->name_in_template_code) == 0) {
LOG("Making dash fn for %u\n", K);
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
	if (Kinds::eq(K, K_scene))  {
		K->construct->compilation_data.pr_iname = Hierarchy::find(PRINT_SCENE_HL);
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
LOG("Making external fn for %u\n", K);
			K->construct->compilation_data.pr_iname = Hierarchy::make_iname_in(PRINT_FN_HL, R);
			inter_name *actual_iname = Produce::find_by_name(Emit::tree(), X);
			Emit::iname_constant(K->construct->compilation_data.pr_iname, K_value, actual_iname);
		} else internal_error("internal but unknown kind printing routine");
	} else {
LOG("Finding external fn for %u\n", K);
		if (external) K->construct->compilation_data.pr_iname = Produce::find_by_name(Emit::tree(), X);
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
inter_name *RTKindConstructors::get_mkdef_iname(kind *K) {
	if (K == NULL) internal_error("null kind has no mkdef fn");
	if (K->construct->compilation_data.mkdef_iname) return K->construct->compilation_data.mkdef_iname;
	package_request *R = RTKindConstructors::kind_package(K);
	K->construct->compilation_data.mkdef_iname = Hierarchy::make_iname_in(MKDEF_FN_HL, R);
	return K->construct->compilation_data.mkdef_iname;
}
inter_name *RTKindConstructors::get_name_of_printing_rule_ACTIONS(kind *K) {
	if (K == NULL) K = K_number;
	if (K->construct->compilation_data.trace_iname)
		return K->construct->compilation_data.trace_iname;
	if (Str::len(K->construct->name_in_template_code) == 0) {
		K->construct->compilation_data.trace_iname = RTKindConstructors::get_iname(K);
		return K->construct->compilation_data.trace_iname;
	}

	if (Str::len(K->construct->ACTIONS_identifier) > 0)
		K->construct->compilation_data.trace_iname = 
			Produce::find_by_name(Emit::tree(), K->construct->ACTIONS_identifier);
	else
		K->construct->compilation_data.trace_iname =
			Produce::find_by_name(Emit::tree(), I"DA_Name");
	return K->construct->compilation_data.trace_iname;
}

inter_name *RTKindConstructors::get_explicit_I6_GPR_iname(kind *K) {
	if (K == NULL) internal_error("RTKindConstructors::get_explicit_I6_GPR on null kind");
	if (Str::len(K->construct->explicit_GPR_identifier) > 0)
		return Produce::find_by_name(Emit::tree(), K->construct->explicit_GPR_identifier);
	return NULL;
}

inter_name *RTKindConstructors::get_distinguisher_iname(kind *K) {
	text_stream *N = Kinds::Behaviour::get_distinguisher(K);
	if (N == NULL) return NULL;
	return Produce::find_by_name(Emit::tree(), N);
}

inter_name *RTKindConstructors::get_comparison_fn_iname(kind *K) {
	return Produce::find_by_name(Emit::tree(), Kinds::Behaviour::get_comparison_routine(K));
}

inter_name *RTKindConstructors::get_support_fn_iname(kind *K) {
	TEMPORARY_TEXT(N)
	Kinds::Behaviour::write_support_routine_name(N, K);
	inter_name *iname = Produce::find_by_name(Emit::tree(), N);
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
	return Kinds::Constructors::offers_I6_GPR(K->construct);
}

@ Request that a GPR be compiled for this kind; the return value tell us whether
this will be allowed or not.

=
int RTKindConstructors::request_I6_GPR(kind *K) {
	if (RTKindConstructors::offers_I6_GPR(K) == FALSE) return FALSE; /* can't oblige */
	#ifdef CORE_MODULE
	if (K->construct->needs_GPR == FALSE) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "GPR for kind %u", K);
		Sequence::queue(&UnderstandValueTokens::agent, STORE_POINTER_kind(K), desc);
	}
	#endif
	K->construct->needs_GPR = TRUE; /* make note to oblige later */
	return TRUE;
}

@ Do we need to compile a GPR of our own for this kind?

=
int RTKindConstructors::needs_I6_GPR(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->needs_GPR;
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
	return Produce::find_by_name(Emit::tree(), N);
}

@ The following is used only when the kind has named instances.

=
int RTKindConstructors::get_highest_valid_value_as_integer(kind *K) {
	if (K == NULL) return 0;
	kind_constructor *kc = K->construct;
	if (kc == CON_activity) return NUMBER_CREATED(activity);
	if (kc == Kinds::get_construct(K_equation)) return NUMBER_CREATED(equation);
	if (kc == CON_rule) return NUMBER_CREATED(booking);
	if (kc == CON_rulebook) return NUMBER_CREATED(rulebook);
	if (kc == Kinds::get_construct(K_table)) return NUMBER_CREATED(table) + 1;
	if (kc == Kinds::get_construct(K_use_option)) return NUMBER_CREATED(use_option);
	if (kc == Kinds::get_construct(K_response)) return NUMBER_CREATED(response_message);
	return kc->next_free_value - 1;
}
