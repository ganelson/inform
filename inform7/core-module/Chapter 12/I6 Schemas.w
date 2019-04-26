[Calculus::Schemas::] I6 Schemas.

To create, and later expand upon, short prototypes of I6 syntax for
such run-time tasks as the setting, unsetting or testing of a relation.

@h Definitions.

@ An I6 schema is an intermediate-level code for the final stages of
compiling to Inform 6 syntax. Its "prototype" is a C string encoded as
ISO Latin-1, in which the asterisk |*| acts as an escape character.

"Expanding" an I6 schema is essentially a form of macro expansion. A caller
supplies us with a schema and a number of parameters, each of which is either
a literal piece of text or a predicate calculus term. We then copy the schema's
prototype into the output, except as specified:

(1) |**| expands to a literal asterisk.

(2) |*1|, |*2|, ..., |*9| expands to the 1st to 9th parameter, where a literal
text parameter is copied straight through, whereas a term parameter is compiled
as a value. Expanding a parameter which was not supplied does nothing, but is
not an error.
(-a) The modifier |!|, as in |*!1| to |*!9|, enables the use of local
variables in any text substitutions compiled in the course of the term.
(-b) The modifier |#|, as in |*#1| to |*#9|, causes us to expand to the
ID number of the kind of value of the parameter, not to the parameter itself.
(If the parameter is literal text rather than a term, we do nothing.)

(3) |*=-| and |*=+| turn "dereference pointers" mode off and on, respectively.
This has effect only when compiling a value whose content is stored on the
heap; Inform ordinarily compiles this by making a new copy of the value and
using a pointer to it, but if "dereference pointers" is off then the pointer
to the original data is used instead. It's a sort of macro-expansion version
of the difference between call-by-value and call-by-reference. The effect lasts
only while the expander is running; when the expander finishes, it restores the
mode to its setting at the start.

(4) |*##| is reserved for the use of higher-level code in building schemas --
it has to do with locations of data on the heap -- but is not strictly speaking
legal in a schema. Attempting to expand it will cause an internal error.

Any other occurrence of an asterisk is illegal, and will throw an internal
error.

@ The I6 schema structure is very simple, then:

@d TYPICAL_I6_SCHEMA_LENGTH 128 /* in fact 40 is plenty */

=
typedef struct i6_schema {
	wchar_t prototype_storage[TYPICAL_I6_SCHEMA_LENGTH];
	struct text_stream prototype;
	struct inter_schema *compiled;
	int no_quoted_inames;
	struct inter_name *quoted_inames[2];
} i6_schema;

@h Building schemas.
The following makes up a new schema from a |printf|-style formatted string:

@d MAX_I6_SCHEMA_ATTEMPT 1024 /* plenty of room for conjectural schema overruns */

=
int unique_qi_counter = 0;

i6_schema *Calculus::Schemas::new(char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	i6_schema *sch = CREATE(i6_schema);
	sch->prototype = Streams::new_buffer(TYPICAL_I6_SCHEMA_LENGTH, sch->prototype_storage);
	sch->no_quoted_inames = 0;
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	sch->compiled = InterSchemas::from_i6s(&(sch->prototype), sch->no_quoted_inames, (void **) sch->quoted_inames);
	return sch;
}

@ And this is a variation for modifying an existing schema:

=
void Calculus::Schemas::modify(i6_schema *sch, char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	sch->prototype = Streams::new_buffer(TYPICAL_I6_SCHEMA_LENGTH, sch->prototype_storage);
	sch->no_quoted_inames = 0;
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	sch->compiled = InterSchemas::from_i6s(&(sch->prototype), sch->no_quoted_inames, (void **) sch->quoted_inames);
}

@ And another:

=
void Calculus::Schemas::append(i6_schema *sch, char *fmt, ...) {
	va_list ap; /* the variable argument list signified by the dots */
	text_stream *OUT = &(sch->prototype);
	@<Process the varargs into schema prototype text@>;
	va_end(ap); /* macro to end variable argument processing */
	sch->compiled = InterSchemas::from_i6s(&(sch->prototype), sch->no_quoted_inames, (void **) sch->quoted_inames);
}

@ Either way, the schema's prototype is written as follows:

@<Process the varargs into schema prototype text@> =
	char *p;
	va_start(ap, fmt); /* macro to begin variable argument processing */
	for (p = fmt; *p; p++) {
		switch (*p) {
			case '%': @<Recognise schema-format escape sequences@>; break;
			default: PUT(*p); break;
		}
	}

@ We recognise only a few escapes here: |%%|, a literal percentage sign; |%d|,
an integer; |%s|, a C string; |%S|, a text stream; and |%k|, a kind ID.

@<Recognise schema-format escape sequences@> =
	p++;
	switch (*p) {
		case 'd': WRITE("%d", va_arg(ap, int)); break;
		case 'k': Kinds::RunTime::compile_weak_id(OUT, va_arg(ap, kind *)); break;
		case 'L': WRITE("%~L", va_arg(ap, local_variable *)); break;
		case 'n': {
			inter_name *iname = (inter_name *) va_arg(ap, inter_name *);
			int N = sch->no_quoted_inames++;
			if (N >= 2) internal_error("too many inter_name quotes");
			sch->quoted_inames[N] = iname;
			WRITE("QUOTED_INAME_%d_%08x", N, unique_qi_counter++);
			break;
		}
		case 'N': WRITE("%N", va_arg(ap, int)); break;
		case 's': WRITE("%s", va_arg(ap, char *)); break;
		case 'S': WRITE("%S", va_arg(ap, text_stream *)); break;
		case '%': PUT('%'); break;
		default:
			fprintf(stderr, "*** Bad schema format: <%s> ***\n", fmt);
			internal_error("Unknown % string escape in schema format");
	}

@h Emptiness.
A schema is empty if its prototype is the null string.

=
int Calculus::Schemas::empty(i6_schema *sch) {
	if (sch == NULL) return TRUE;
	if (Str::len(&(sch->prototype)) == 0) return TRUE;
	return FALSE;
}

@h Expansion.
We provide two routines as a sort of API for expanding schemas. The user can
either specify two parameters, both of them terms...

=
void Calculus::Schemas::emit_expand_from_terms(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2, int semicolon) {
	i6s_emission_state ems = Calculus::Schemas::state(pt1, pt2, NULL, NULL);

	Calculus::Schemas::sch_emit_inner(sch, &ems, semicolon);
}

void Calculus::Schemas::emit_expand_from_locals(i6_schema *sch,
	local_variable *v1, local_variable *v2, int semicolon) {
	pcalc_term pt1 = Calculus::Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Calculus::Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	Calculus::Schemas::emit_expand_from_terms(sch, &pt1, &pt2, semicolon);
}

void Calculus::Schemas::emit_val_expand_from_locals(i6_schema *sch,
	local_variable *v1, local_variable *v2) {
	pcalc_term pt1 = Calculus::Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
	pcalc_term pt2 = Calculus::Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v2));
	Calculus::Schemas::emit_val_expand_from_terms(sch, &pt1, &pt2);
}

void Calculus::Schemas::emit_val_expand_from_terms(i6_schema *sch,
	pcalc_term *pt1, pcalc_term *pt2) {
	i6s_emission_state ems = Calculus::Schemas::state(pt1, pt2, NULL, NULL);

	Calculus::Schemas::sch_emit_inner(sch, &ems, FALSE);
}

typedef struct i6s_emission_state {
	struct text_stream *ops_textual[2];
	struct pcalc_term *ops_termwise[2];
} i6s_emission_state;

i6s_emission_state Calculus::Schemas::state(pcalc_term *pt1, pcalc_term *pt2, text_stream *str1, text_stream *str2) {
	i6s_emission_state ems;
	ems.ops_textual[0] = str1;
	ems.ops_textual[1] = str2;
	ems.ops_termwise[0] = pt1;
	ems.ops_termwise[1] = pt2;
	return ems;
}

@ =
void Calculus::Schemas::sch_emit_inner(i6_schema *sch, i6s_emission_state *ems, int code_mode) {

	if ((ems->ops_textual[0]) || (ems->ops_textual[1])) internal_error("Zap");

	Calculus::Schemas::sch_type_parameter(ems->ops_termwise[0]);
	Calculus::Schemas::sch_type_parameter(ems->ops_termwise[1]);

	BEGIN_COMPILATION_MODE;
	if (sch->compiled->dereference_mode)
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	int val_mode = FALSE;
	if (code_mode == FALSE) val_mode = TRUE;
	EmitInterSchemas::emit(&VH, sch->compiled, ems, code_mode, val_mode,
		&Calculus::Schemas::sch_inline, NULL);

	END_COMPILATION_MODE;
}

void Calculus::Schemas::sch_inline(value_holster *VH,
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
			Calculus::Schemas::sch_emit_parameter(ems->ops_termwise[0], give_kind_id,
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
			Calculus::Schemas::sch_emit_parameter(ems->ops_termwise[1],
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
		Calculus::Schemas::sch_emit_parameter(ems->ops_termwise[1],
			give_kind_id, give_comparison_routine, dereference_property, NULL, FALSE);
		Emit::val(K_number, LITERAL_IVAL, 0);
	}

@ =
void Calculus::Schemas::sch_emit_parameter(pcalc_term *pt,
	int give_kind_id, int give_comparison_routine,
	int dereference_property, kind *cast_to, int by_reference) {
	if (give_kind_id) {
		if (pt) Kinds::RunTime::emit_weak_id_as_val(pt->term_checked_as_kind);
	} else if (give_comparison_routine) {
		inter_name *cr = (pt)?(Kinds::Behaviour::get_comparison_routine_as_iname(pt->term_checked_as_kind)):NULL;
		if (cr == NULL) cr = Hierarchy::find(SIGNEDCOMPARE_HL);
		Emit::val_iname(K_value, cr);
	} else {
		if (by_reference) {
			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
			pcalc_term cpt = *pt;
			Calculus::Terms::emit(cpt);
			END_COMPILATION_MODE;
		} else {
			int down = FALSE;
			Kinds::RunTime::emit_cast_call(pt->term_checked_as_kind, cast_to, &down);
			pcalc_term cpt = *pt;
			if ((dereference_property) &&
				(ParseTree::is(cpt.constant, CONSTANT_NT))) {
				kind *K = Specifications::to_kind(cpt.constant);
				if (Kinds::get_construct(K) == CON_property)
					cpt = Calculus::Terms::new_constant(
						Lvalues::new_PROPERTY_VALUE(
							ParseTree::duplicate(cpt.constant),
							Rvalues::new_self_object_constant()));
			}
			Calculus::Terms::emit(cpt);
			if (down) Emit::up();
		}
	}
}

@ Last and very much least: in case we receive an untypechecked term, we fill
in its kind.

=
void Calculus::Schemas::sch_type_parameter(pcalc_term *pt) {
	if ((pt) && (pt->constant) && (pt->term_checked_as_kind == NULL))
		pt->term_checked_as_kind = Specifications::to_kind(pt->constant);
}

@h Logging schemas.

=
void Calculus::Schemas::log(i6_schema *sch) {
	if (sch == NULL) LOG("<null schema>");
	else LOG("<schema: %S>", &(sch->prototype));
}

void Calculus::Schemas::log_applied(i6_schema *sch, pcalc_term *pt1) {
	if (sch == NULL) { LOG("<null schema>"); return; }
	else LOG("<%S : $0>", &(sch->prototype), pt1);
}
