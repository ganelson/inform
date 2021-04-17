[RTMeasurements::] Measurements.

To compile run-time support for measurement adjectives.

@

=
typedef struct measurement_compilation_data {
	struct inter_name *mdef_iname;
	int property_schema_written; /* I6 schema for testing written yet? */
} measurement_compilation_data;

void RTMeasurements::make_iname(measurement_definition *mdef) {
	package_request *P = Hierarchy::local_package(ADJECTIVE_MEANINGS_HAP);
	mdef->compilation_data.mdef_iname = Hierarchy::make_iname_in(MEASUREMENT_FN_HL, P);
	mdef->compilation_data.property_schema_written = FALSE;
}

void RTMeasurements::make_test_schema(measurement_definition *mdef, int T) {
	if ((mdef->compilation_data.property_schema_written == FALSE) &&
		(T == TEST_ATOM_TASK)) {
		i6_schema *sch = AdjectiveMeanings::make_schema(
			mdef->headword_as_adjective, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "%n(*1)", mdef->compilation_data.mdef_iname);
		mdef->compilation_data.property_schema_written = TRUE;
	}
}

void RTMeasurements::compile_test_functions(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition)
		if (mdef->compilation_data.property_schema_written) {
			packaging_state save = Functions::begin(mdef->compilation_data.mdef_iname);
			local_variable *lv = LocalVariables::new_call_parameter(
				Frames::current_stack_frame(),
				EMPTY_WORDING,
				AdjectiveMeaningDomains::get_kind(mdef->headword_as_adjective));
			parse_node *var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, lv);
			parse_node *evaluated_prop = Lvalues::new_PROPERTY_VALUE(
				Rvalues::from_property(mdef->prop), var);
			parse_node *val = NULL;
			if (<s-literal>(mdef->region_threshold_text)) val = <<rp>>;
			else internal_error("literal unreadable");
			pcalc_prop *prop = Atoms::binary_PREDICATE_new(
				Measurements::weak_comparison_bp(mdef->region_shape),
				Terms::new_constant(evaluated_prop),
				Terms::new_constant(val));
			if (TypecheckPropositions::type_check(prop,
				TypecheckPropositions::tc_problem_reporting(
					mdef->region_threshold_text,
					"be giving the boundary of the definition")) == ALWAYS_MATCH) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					CompilePropositions::to_test_as_condition(NULL, prop);
					EmitCode::code();
					EmitCode::down();
						EmitCode::rtrue();
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::rfalse();
			Functions::end(save);
		}
}
