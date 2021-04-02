[RTMeasurements::] Measurements.

To compile run-time support for measurement adjectives.

@

=
typedef struct measurement_compilation_data {
	struct inter_name *mdef_iname;
	int property_schema_written; /* I6 schema for testing written yet? */
} measurement_compilation_data;

void RTMeasurements::make_iname(measurement_definition *mdef) {
	package_request *P =
		Hierarchy::package(CompilationUnits::current(), ADJECTIVE_MEANINGS_HAP);
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
			packaging_state save = Routines::begin(mdef->compilation_data.mdef_iname);
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
			if (Propositions::Checker::type_check(prop,
				Propositions::Checker::tc_problem_reporting(
					mdef->region_threshold_text,
					"be giving the boundary of the definition")) == ALWAYS_MATCH) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Calculus::Deferrals::emit_test_of_proposition(NULL, prop);
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::rtrue(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			}
			Produce::rfalse(Emit::tree());
			Routines::end(save);
		}
}
