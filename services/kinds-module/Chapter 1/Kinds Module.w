[KindsModule::] Kinds Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d KINDS_MODULE TRUE

@ This module defines the following classes:

@e dimensional_rule_CLASS
@e kind_CLASS
@e kind_variable_declaration_CLASS
@e kind_constructor_CLASS
@e kind_template_definition_CLASS
@e kind_macro_definition_CLASS
@e kind_constructor_comparison_schema_CLASS
@e kind_constructor_casting_rule_CLASS
@e kind_constructor_instance_CLASS
@e kind_constructor_instance_rule_CLASS
@e unit_sequence_CLASS
@e star_invention_CLASS

=
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(dimensional_rule, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind, 1000)
DECLARE_CLASS(kind_variable_declaration)
DECLARE_CLASS(kind_constructor)
DECLARE_CLASS(kind_macro_definition)
DECLARE_CLASS(kind_template_definition)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_casting_rule, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_comparison_schema, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_instance, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(kind_constructor_instance_rule, 100)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(unit_sequence, 50)
DECLARE_CLASS(star_invention)

@ Like all modules, this one must define a |start| and |end| function:

@e KIND_CHANGES_DA
@e KIND_CHECKING_DA
@e KIND_CREATIONS_DA
@e MATCHING_DA

=
void KindsModule::start(void) {
	Writers::register_writer('u', &Kinds::Textual::writer);
	Writers::register_logger('Q', Kinds::Dimensions::logger);
	Log::declare_aspect(KIND_CHANGES_DA, L"kind changes", FALSE, TRUE);
	Log::declare_aspect(KIND_CHECKING_DA, L"kind checking", FALSE, FALSE);
	Log::declare_aspect(KIND_CREATIONS_DA, L"kind creations", FALSE, FALSE);
	Log::declare_aspect(MATCHING_DA, L"matching", FALSE, FALSE);
	KindsModule::set_internal_NTIs();
}
void KindsModule::end(void) {
}

@ A little Preform optimisation:

=
void KindsModule::set_internal_NTIs(void) {
	NTI::give_nt_reserved_incidence_bit(<k-kind>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-kind-of-kind>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-base-kind>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-kind-construction>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-kind-variable-texts>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-kind-variable>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-formal-variable>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-irregular-kind-construction>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-variable-definition>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-single-term>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-optional-term>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-tupled-term>, COMMON_NOUN_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<k-tuple-list>, COMMON_NOUN_RES_NT_BIT);
}

@ Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_KINDS_CALLBACK|
to some routine of her own, gazumping this one.

@e DimensionRedundant_KINDERROR from 1
@e DimensionNotBaseKOV_KINDERROR
@e NonDimensional_KINDERROR
@e UnitSequenceOverflow_KINDERROR
@e DimensionsInconsistent_KINDERROR
@e KindUnalterable_KINDERROR
@e KindsCircular_KINDERROR
@e KindsCircular2_KINDERROR
@e LPCantScaleYet_KINDERROR
@e LPCantScaleTwice_KINDERROR
@e NeptuneError_KINDERROR

=
void KindsModule::problem_handler(int err_no, parse_node *pn, text_stream *E,
	kind *K1, kind *K2) {
	#ifdef PROBLEM_KINDS_CALLBACK
	PROBLEM_KINDS_CALLBACK(err_no, pn, E, K1, K2);
	#endif
	#ifndef PROBLEM_KINDS_CALLBACK
	TEMPORARY_TEXT(text)
	if (pn) WRITE_TO(text, "%+W", Node::get_text(pn));
	if (E) WRITE_TO(text, "%S", E);
	switch (err_no) {
		case DimensionRedundant_KINDERROR:
			Errors::with_text("multiplication rule given twice: %S", text);
			break;
		case DimensionNotBaseKOV_KINDERROR:
			Errors::with_text("multiplication rule too complex: %S", text);
			break;
		case NonDimensional_KINDERROR:
			Errors::with_text("multiplication rule quotes non-numerical kinds: %S", text);
			break;
		case UnitSequenceOverflow_KINDERROR:
			Errors::with_text("multiplication rule far too complex: %S", text);
			break;
		case DimensionsInconsistent_KINDERROR:
			Errors::with_text("multiplication rule creates inconsistency: %S", text);
			break;
		case KindUnalterable_KINDERROR:
			Errors::with_text("making this subkind would lead to a contradiction: %S", text);
			break;
		case KindsCircular_KINDERROR:
			Errors::with_text("making this subkind would lead to a circularity: %S", text);
			break;
		case KindsCircular2_KINDERROR:
			Errors::with_text("making this subkind would a kind being its own subkind: %S", text);
			break;
		case LPCantScaleYet_KINDERROR:
			Errors::with_text("tries to scale a value with no point of reference: %S", text);
			break;
		case LPCantScaleTwice_KINDERROR:
			Errors::with_text("tries to scale a value which has already been scaled: %S", text);
			break;
		case NeptuneError_KINDERROR:
			Errors::with_text("error in Neptune file: %S", text);
			break;
		default: internal_error("unimplemented problem message");
	}
	DISCARD_TEXT(text)
	#endif
}

