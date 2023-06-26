[CompileSchemas::] Compile Schemas.

Here we compile fragments of code from paraphrases written in Inform 6 notation,
and use that ability to compile general predicate calculus terms.

@ We provide the following functions as a sort of API for emitting schemas.
Recall that an |i6_schema|, defined in //calculus: Compilation Schemas//,
is a basically textual prototype of a fragment of code.

These functions really differ only in how the parameters are to be specified;
typical schemas look like |X(*1, true) == *2|, say, where some values go
in place of |*1| and |*2|. Those are the parameters, and they can be supplied
in several different ways.

=
void CompileSchemas::from_terms_in_void_context(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2) {
	CompileSchemas::sch_emit_inner(sch, pt1, pt2, TRUE);
}

void CompileSchemas::from_terms_in_val_context(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2) {
	CompileSchemas::sch_emit_inner(sch, pt1, pt2, FALSE);
}

void CompileSchemas::from_local_variables_in_void_context(i6_schema *sch,
	local_variable *v1, local_variable *v2) {
	pcalc_term pt1 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	CompileSchemas::from_terms_in_void_context(sch, &pt1, &pt2);
}

void CompileSchemas::from_local_variables_in_val_context(i6_schema *sch,
	local_variable *v1, local_variable *v2) {
	pcalc_term pt1 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	CompileSchemas::from_terms_in_val_context(sch, &pt1, &pt2);
}

void CompileSchemas::from_annotated_schema(annotated_i6_schema *asch) {
	if (asch->negate_schema) {
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
	}
	CompileSchemas::from_terms_in_void_context(asch->schema, &(asch->pt0), &(asch->pt1));
	if (asch->negate_schema) {
		EmitCode::up();
	}
}

@ And this is where the actual emission is done, though in fact the heavy
lifting is all done in //building: Inter Schemas//. Essentially all we do is
to call |EmitInterSchemas::emit|, with our compilation state -- such as it is --
stored in an |i6s_emission_state|. It then calls our nominated function on
each component part of the scheme, in its parsed and dismantled form.

In case we receive an untypechecked term (e.g., arising from a local variable
as above), we fill in its kind.

=
typedef struct i6s_emission_state {
	struct pcalc_term *ops_termwise[2];
	int by_ref;
} i6s_emission_state;

void CompileSchemas::sch_emit_inner(i6_schema *sch, pcalc_term *pt1, pcalc_term *pt2,
	int void_context) {
	i6s_emission_state ems;
	if ((pt1) && (pt1->constant) && (pt1->term_checked_as_kind == NULL))
		pt1->term_checked_as_kind = Specifications::to_kind(pt1->constant);
	if ((pt2) && (pt2->constant) && (pt2->term_checked_as_kind == NULL))
		pt2->term_checked_as_kind = Specifications::to_kind(pt2->constant);
	ems.ops_termwise[0] = pt1;
	ems.ops_termwise[1] = pt2;
	ems.by_ref = sch->compiled->dereference_mode;

	value_holster VH = Holsters::new(void_context?INTER_VOID_VHMODE:INTER_VAL_VHMODE);
	EmitInterSchemas::emit(Emit::tree(), &VH, sch->compiled,
		IdentifierFinders::common_names_only(),
		&CompileSchemas::from_schema_token, NULL, &ems);
	I6Errors::internal_error_on_schema_errors(sch->compiled);
}

@ So, then, this is called on each token in turn from the original schema. Note
that we only receive two commands here, as compared with the profusion of
commands received by the analogous function //CSIInline::from_schema_token// used
for inline definitions; this is because the range of notation in I6 schemas inside
the compiler is much smaller.

=
rule *rule_to_which_this_is_a_response = NULL; /* when a new response is being compiled */
int response_marker_within_that_rule = -1; /* when a new response is being compiled */

void CompileSchemas::from_schema_token(value_holster *VH,
	inter_schema_token *t, void *ems_s, int prim_cat, text_stream *arg_L) {
	i6s_emission_state *ems = (i6s_emission_state *) ems_s;

	int m = t->inline_modifiers;
	int by_reference = (m & BY_REFERENCE_ISSBM)?TRUE:(ems->by_ref);

	if (t->inline_command == substitute_ISINC)   @<Perform substitution@>
	else if (t->inline_command == combine_ISINC) @<Perform combine@>
	else internal_error("unimplemented command in schema");
}

@ This deals with a |*1| or |*2| token, which are placeholders for the tokens:
we substitute in |ems->ops_termwise[0]| or |ems->ops_termwise[1]| respectively.
Here |this| is the term in question, and |other| the other of the two.

@<Perform substitution@> =
	int N = t->constant_number;
	if ((N < 0) || (N >= 2)) internal_error("schemas are currently limited to *1 and *2");
	pcalc_term *this = ems->ops_termwise[N], *other = ems->ops_termwise[1-N];
	rule *R = rule_to_which_this_is_a_response;
	int M = response_marker_within_that_rule;
	if ((m & ADOPT_LOCAL_STACK_FRAME_ISSBM) &&
		(Rvalues::is_CONSTANT_of_kind(other->constant, K_response))) {
		rule_to_which_this_is_a_response = Rvalues::to_rule(other->constant);
		response_marker_within_that_rule = Rvalues::to_response_marker(other->constant);
	}
	kind *K = NULL;
	if (m & CAST_TO_KIND_OF_OTHER_TERM_ISSBM) K = other->term_checked_as_kind;
	CompileSchemas::compile_term_of_token(this, m, K, by_reference);
	rule_to_which_this_is_a_response = R;
	response_marker_within_that_rule = M;

@ This is for |*&|, which can only be used on the second term (i.e., term 1).
If that is a combination of two values then we unpack those and compile them
both, one after the other. 

@<Perform combine@> =
	int emit_without_combination = TRUE;
	pcalc_term *pt0 = ems->ops_termwise[0], *pt1 = ems->ops_termwise[1];
	if ((pt0) && (pt1)) {
		kind *reln_K = pt0->term_checked_as_kind;
		kind *comb_K = pt1->term_checked_as_kind;
		if ((Kinds::get_construct(reln_K) == CON_relation) &&
			(Kinds::get_construct(comb_K) == CON_combination)) {
			kind *req_A = NULL, *req_B = NULL;
			if (Kinds::Behaviour::definite(req_A) == FALSE) req_A = NULL;
			if (Kinds::Behaviour::definite(req_B) == FALSE) req_B = NULL;
			Kinds::binary_construction_material(reln_K, &req_A, &req_B);
			parse_node *spec_A = NULL, *spec_B = NULL;
			Rvalues::to_pair(pt1->constant, &spec_A, &spec_B);
			if (ems->by_ref) CompileValues::to_code_val_of_kind(spec_A, req_A);
			else             CompileValues::to_fresh_code_val_of_kind(spec_A, req_A);
			if (ems->by_ref) CompileValues::to_code_val_of_kind(spec_B, req_B);
			else             CompileValues::to_fresh_code_val_of_kind(spec_B, req_B);
			emit_without_combination = FALSE;
		}
	}
	if (emit_without_combination) {
		CompileSchemas::compile_term_of_token(pt1, m, NULL, by_reference);
		EmitCode::val_number(0);
	}

@ In either case (substitution or combination) we can end up down here. One
of four things can happen to the term arising from a token:

=
void CompileSchemas::compile_term_of_token(pcalc_term *pt, int m, kind *cast_to,
	int by_reference) {
	if (pt == NULL) internal_error("no term");
	if (m & GIVE_KIND_ID_ISSBM) @<Compile weak ID of the kind of this term@>;
	if (m & GIVE_COMPARISON_ROUTINE_ISSBM) @<Compile comparison function for the kind@>;
	@<Compile term as an lvalue or an rvalue@>;
}

@<Compile weak ID of the kind of this term@> =
	RTKindIDs::emit_weak_ID_as_val(pt->term_checked_as_kind);
	return;

@<Compile comparison function for the kind@> =
	inter_name *cr;
	if (pt->term_checked_as_kind)
		cr = RTKindConstructors::comparison_fn_iname(pt->term_checked_as_kind);
	else
		cr = Hierarchy::find(SIGNEDCOMPARE_HL);
	EmitCode::val_iname(K_value, cr);
	return;

@<Compile term as an lvalue or an rvalue@> =
	int storage_mode = COMPILE_LVALUE_AS_RVALUE;
	if (m & LVALUE_CONTEXT_ISSBM)      storage_mode = COMPILE_LVALUE_AS_LVALUE;
	if (m & STORAGE_AS_FUNCTION_ISSBM) storage_mode = COMPILE_LVALUE_AS_FUNCTION;
	pcalc_term cpt = *pt;
	if ((m & DEREFERENCE_PROPERTY_ISSBM) &&
		(Node::is(cpt.constant, CONSTANT_NT)) &&
		(Kinds::get_construct(Specifications::to_kind(cpt.constant)) == CON_property))
			cpt = Terms::new_constant(
				Lvalues::new_PROPERTY_VALUE(
					Node::duplicate(cpt.constant), Rvalues::new_self_object_constant()));
	if ((storage_mode != COMPILE_LVALUE_AS_RVALUE) &&
		((cpt.constant) && (Lvalues::is_lvalue(cpt.constant)))) {
		value_holster VH = Holsters::new(INTER_VAL_VHMODE);
		CompileLvalues::compile_in_mode(&VH, cpt.constant, storage_mode);
	} else {
		CompileSchemas::compile_term(cpt, cast_to, by_reference);
	}

@ We are now ready to compile a general predicate-calculus term, which is the
first milestone on our goal of compiling general propositions. The following
function is called from the above in the case when a term must be compiled
in an rvalue context, but also by //Compile Deferred Propositions//.

=
void CompileSchemas::compile_term(pcalc_term pt, kind *K, int by_reference) {
	if (pt.variable >= 0) @<Compile variable term@>;
	if (pt.constant)      @<Compile constant term@>;
	if (pt.function)      @<Compile function term@>;
	internal_error("Broken pcalc term");
}

@ Variables (in the predicate calculus sense) are compiled to Inter locals
with the same names -- that is, they are called |x|, |y|, |z|, ... and so on.

@<Compile variable term@> =
	local_variable *lvar = LocalVariables::find_pcalc_var(pt.variable);
	if (lvar == NULL) {
		LOG("var is %d\n", pt.variable);
		internal_error("no local exists which corresponds to calculus variable");
	}
	inter_symbol *lvar_s = LocalVariables::declare(lvar);
	EmitCode::val_symbol(K_value, lvar_s);
	return;

@ Constants are compiled using //Compile Values//, but note that we typecheck
any use of a phrase to decide a value here, because this might not otherwise
yet have been checked.

Cindered constants resulting from a deferral (see //Cinders and Deferrals//)
become |const_0|, |const_1|, ... These will only be valid inside a deferred
function, but that is fine because they cannot arise anywhere else.

@<Compile constant term@> =
	if (pt.cinder >= 0) {
		local_variable *lvar = Cinders::find_cinder_var(pt.cinder);
		if (lvar == NULL) internal_error("absent calculus variable");
		inter_symbol *lvar_s = LocalVariables::declare(lvar);
		EmitCode::val_symbol(K_value, lvar_s);
	} else {
		if (Specifications::is_phrasal(pt.constant)) Dash::check_value(pt.constant, NULL);
		if (by_reference) CompileValues::to_code_val_of_kind(pt.constant, K);
		else              CompileValues::to_fresh_code_val_of_kind(pt.constant, K);
	}
	return;

@ Functions $f_R(t)$ are compiled by expanding a schema for $f_R$ with $t$
as parameter.

@<Compile function term@> =
	binary_predicate *bp = (pt.function)->bp;
	i6_schema *fn = BinaryPredicates::get_term_as_fn_of_other(bp, 1-pt.function->from_term);
	if (fn == NULL) internal_error("function of non-functional predicate");
	CompileSchemas::from_terms_in_val_context(fn, &(pt.function->fn_of), NULL);
	return;
