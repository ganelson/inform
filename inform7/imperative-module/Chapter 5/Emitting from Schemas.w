[EmitSchemas::] Emitting from Schemas.

Here we emit code from an I6 schema.

@ We provide the following functions as a sort of API for emitting schemas.
Recall that an |i6_schema|, defined in //calculus: Compilation Schemas//,
is a basically textual prototype of a fragment of code. The hard work of
generating code from it is actually done in //building: Inter Schemas//,
but this section gives a convenient way to avoid dealing directly with that.

The following really differ only in how the parameters are to be specified;
typical schemas look like |X(*1, true) == *2|, say, where some values go
in place of |*1| and |*2|. Those are the parameters, and they can be supplied
in several different ways.

=
void EmitSchemas::emit_expand_from_terms(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2, int semicolon) {
	i6s_emission_state ems = EmitSchemas::state(pt1, pt2, NULL, NULL);

	EmitSchemas::sch_emit_inner(sch, &ems, semicolon);
}

void EmitSchemas::emit_expand_from_locals(i6_schema *sch,
	local_variable *v1, local_variable *v2, int semicolon) {
	pcalc_term pt1 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	EmitSchemas::emit_expand_from_terms(sch, &pt1, &pt2, semicolon);
}

void EmitSchemas::emit_val_expand_from_locals(i6_schema *sch,
	local_variable *v1, local_variable *v2) {
	pcalc_term pt1 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	EmitSchemas::emit_val_expand_from_terms(sch, &pt1, &pt2);
}

void EmitSchemas::emit_val_expand_from_terms(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2) {
	i6s_emission_state ems = EmitSchemas::state(pt1, pt2, NULL, NULL);

	EmitSchemas::sch_emit_inner(sch, &ems, FALSE);
}

typedef struct i6s_emission_state {
	struct text_stream *ops_textual[2];
	struct pcalc_term *ops_termwise[2];
} i6s_emission_state;

i6s_emission_state EmitSchemas::state(pcalc_term *pt1, pcalc_term *pt2,
	text_stream *str1, text_stream *str2) {
	i6s_emission_state ems;
	ems.ops_textual[0] = str1;
	ems.ops_textual[1] = str2;
	ems.ops_termwise[0] = pt1;
	ems.ops_termwise[1] = pt2;
	return ems;
}

@ =
void EmitSchemas::sch_emit_inner(i6_schema *sch, i6s_emission_state *ems, int code_mode) {

	if ((ems->ops_textual[0]) || (ems->ops_textual[1])) internal_error("Zap");

	EmitSchemas::sch_type_parameter(ems->ops_termwise[0]);
	EmitSchemas::sch_type_parameter(ems->ops_termwise[1]);

	BEGIN_COMPILATION_MODE;
	if (sch->compiled->dereference_mode)
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	int val_mode = FALSE;
	if (code_mode == FALSE) val_mode = TRUE;
	EmitInterSchemas::emit(Emit::tree(), &VH, sch->compiled, ems, code_mode, val_mode, NULL, NULL,
		&EmitSchemas::sch_inline, NULL);

	END_COMPILATION_MODE;
}

void EmitSchemas::sch_inline(value_holster *VH,
	inter_schema_token *t, void *ems_s, int prim_cat) {

	i6s_emission_state *ems = (i6s_emission_state *) ems_s;

	BEGIN_COMPILATION_MODE;

	int give_kind_id = FALSE, give_comparison_routine = FALSE,
		dereference_property = FALSE, adopt_local_stack_frame = FALSE,
		cast_to_kind_of_other_term = FALSE, by_reference = FALSE;

	if (t->inline_modifiers & PERMIT_LOCALS_IN_TEXT_CMODE_ISSBM)
		COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
	if (t->inline_modifiers & TREAT_AS_LVALUE_CMODE_ISSBM)
		COMPILATION_MODE_ENTER(TREAT_AS_LVALUE_CMODE);
	if (t->inline_modifiers & JUST_ROUTINE_CMODE_ISSBM)
		COMPILATION_MODE_ENTER(JUST_ROUTINE_CMODE);
	if (t->inline_modifiers & GIVE_KIND_ID_ISSBM) give_kind_id = TRUE;
	if (t->inline_modifiers & GIVE_COMPARISON_ROUTINE_ISSBM) give_comparison_routine = TRUE;
	if (t->inline_modifiers & DEREFERENCE_PROPERTY_ISSBM) dereference_property = TRUE;
	if (t->inline_modifiers & ADOPT_LOCAL_STACK_FRAME_ISSBM) adopt_local_stack_frame = TRUE;
	if (t->inline_modifiers & CAST_TO_KIND_OF_OTHER_TERM_ISSBM) cast_to_kind_of_other_term = TRUE;
	if (t->inline_modifiers & BY_REFERENCE_ISSBM) by_reference = TRUE;

	if (t->inline_command == substitute_ISINC) @<Perform substitution@>
	else if (t->inline_command == current_sentence_ISINC) @<Perform current sentence@>
	else if (t->inline_command == combine_ISINC) @<Perform combine@>
	else internal_error("unimplemented command in schema");

	END_COMPILATION_MODE;
}

@<Perform substitution@> =
	switch (t->constant_number) {
		case 0: {
			kind *K = NULL;
			if (cast_to_kind_of_other_term) K = ems->ops_termwise[1]->term_checked_as_kind;
			EmitSchemas::sch_emit_parameter(ems->ops_termwise[0], give_kind_id,
				give_comparison_routine, dereference_property, K, by_reference);
			break;
		}
		case 1: {
			rule *R = adopted_rule_for_compilation;
			int M = adopted_marker_for_compilation;
			if ((adopt_local_stack_frame) &&
				(Rvalues::is_CONSTANT_of_kind(ems->ops_termwise[0]->constant, K_response))) {
				adopted_rule_for_compilation =
					Rvalues::to_rule(ems->ops_termwise[0]->constant);
				adopted_marker_for_compilation =
					Strings::get_marker_from_response_spec(ems->ops_termwise[0]->constant);
			}
			kind *K = NULL;
			if (cast_to_kind_of_other_term) K = ems->ops_termwise[0]->term_checked_as_kind;
			EmitSchemas::sch_emit_parameter(ems->ops_termwise[1],
				give_kind_id, give_comparison_routine, dereference_property, K, by_reference);
			adopted_rule_for_compilation = R;
			adopted_marker_for_compilation = M;
			break;
		}
		default:
			internal_error("schemas are currently limited to *1 and *2");
	}

@<Perform current sentence@> =
	internal_error("Seems possible after all");

@<Perform combine@> =
	int epar = TRUE;
	if ((ems->ops_termwise[0]) && (ems->ops_termwise[1])) {
		kind *reln_K = ems->ops_termwise[0]->term_checked_as_kind;
		kind *comb_K = ems->ops_termwise[1]->term_checked_as_kind;
		if ((Kinds::get_construct(reln_K) == CON_relation) &&
			(Kinds::get_construct(comb_K) == CON_combination)) {
			kind *req_A = NULL, *req_B = NULL, *found_A = NULL, *found_B = NULL;
			Kinds::binary_construction_material(reln_K, &req_A, &req_B);
			Kinds::binary_construction_material(comb_K, &found_A, &found_B);
			parse_node *spec_A = NULL, *spec_B = NULL;
			Rvalues::to_pair(ems->ops_termwise[1]->constant, &spec_A, &spec_B);
			if (!((Kinds::Behaviour::uses_pointer_values(req_A)) && (Kinds::Behaviour::definite(req_A))))
				req_A = NULL;
			if (!((Kinds::Behaviour::uses_pointer_values(req_B)) && (Kinds::Behaviour::definite(req_B))))
				req_B = NULL;
			Specifications::Compiler::emit_to_kind(spec_A, req_A);
			Specifications::Compiler::emit_to_kind(spec_B, req_B);
			epar = FALSE;
		}
	}
	if (epar) {
		EmitSchemas::sch_emit_parameter(ems->ops_termwise[1],
			give_kind_id, give_comparison_routine, dereference_property, NULL, FALSE);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	}

@ =
void EmitSchemas::sch_emit_parameter(pcalc_term *pt,
	int give_kind_id, int give_comparison_routine,
	int dereference_property, kind *cast_to, int by_reference) {
	if (give_kind_id) {
		if (pt) RTKinds::emit_weak_id_as_val(pt->term_checked_as_kind);
	} else if (give_comparison_routine) {
		inter_name *cr = Hierarchy::find(SIGNEDCOMPARE_HL);
		if ((pt) && (pt->term_checked_as_kind)) {
			inter_name *specialised_cr = 
				Kinds::Behaviour::get_comparison_routine_as_iname(pt->term_checked_as_kind);
			if (specialised_cr) cr = specialised_cr;
		}
		Produce::val_iname(Emit::tree(), K_value, cr);
	} else {
		if (by_reference) {
			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
			pcalc_term cpt = *pt;
			Terms::emit(cpt);
			END_COMPILATION_MODE;
		} else {
			int down = FALSE;
			RTKinds::emit_cast_call(pt->term_checked_as_kind, cast_to, &down);
			pcalc_term cpt = *pt;
			if ((dereference_property) &&
				(Node::is(cpt.constant, CONSTANT_NT))) {
				kind *K = Specifications::to_kind(cpt.constant);
				if (Kinds::get_construct(K) == CON_property)
					cpt = Terms::new_constant(
						Lvalues::new_PROPERTY_VALUE(
							Node::duplicate(cpt.constant),
							Rvalues::new_self_object_constant()));
			}
			Terms::emit(cpt);
			if (down) Produce::up(Emit::tree());
		}
	}
}

@ Last and very much least: in case we receive an untypechecked term, we fill
in its kind.

=
void EmitSchemas::sch_type_parameter(pcalc_term *pt) {
	if ((pt) && (pt->constant) && (pt->term_checked_as_kind == NULL))
		pt->term_checked_as_kind = Specifications::to_kind(pt->constant);
}
