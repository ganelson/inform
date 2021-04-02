[CreationPredicates::] The Creation Predicates.

To define the predicates causing instances to be created.

@ This predicate plays a very special role in our calculus, and must always
exist.

= (early code)
up_family *calling_up_family = NULL;
up_family *is_a_var_up_family = NULL;
up_family *is_a_const_up_family = NULL;
up_family *is_a_kind_up_family = NULL;

unary_predicate *is_a_var_up = NULL;
unary_predicate *is_a_const_up = NULL;

@h Family.
This is a minimal representation only: Inform adds other methods to the equality
family to handle its typechecking and so on.

=
void CreationPredicates::start(void) {
	calling_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(calling_up_family, LOG_UPF_MTID, CreationPredicates::log_calling);
	#ifdef CORE_MODULE
	METHOD_ADD(calling_up_family, TYPECHECK_UPF_MTID, CreationPredicates::typecheck_calling);
	METHOD_ADD(calling_up_family, SCHEMA_UPF_MTID, CreationPredicates::schema_calling);
	#endif
	is_a_var_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_var_up_family, STOCK_UPF_MTID, CreationPredicates::stock_is_a_var);
	METHOD_ADD(is_a_var_up_family, LOG_UPF_MTID, CreationPredicates::log_is_a_var);
	is_a_const_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_const_up_family, STOCK_UPF_MTID, CreationPredicates::stock_is_a_const);
	METHOD_ADD(is_a_const_up_family, LOG_UPF_MTID, CreationPredicates::log_is_a_const);
	is_a_kind_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_kind_up_family, LOG_UPF_MTID, CreationPredicates::log_is_a_kind);
	#ifdef CORE_MODULE
	METHOD_ADD(is_a_var_up_family, TYPECHECK_UPF_MTID, CreationPredicates::typecheck_is_a_var);
	METHOD_ADD(is_a_const_up_family, TYPECHECK_UPF_MTID, CreationPredicates::typecheck_is_a_const);
	METHOD_ADD(is_a_kind_up_family, TYPECHECK_UPF_MTID, CreationPredicates::typecheck_is_a_kind);
	#endif
}

@ |CALLED| atoms are interesting because they exist only for their side-effects:
they have no effect at all on the logical status of a proposition (well, except
that they should not be applied to free variables referred to nowhere else).
They can therefore be added or removed freely. In the phrase

>> if a woman is in a lighted room (called the den), ...

we need to note that the value of the bound variable corresponding to the
lighted room will need to be kept and to have a name ("the den"): this
will probably mean the inclusion of a |CALLED=den(y)| atom.

The calling data for a |CALLED| atom is the textual name by which the variable
will be called.

=
int CreationPredicates::is_calling_up_atom(pcalc_prop *prop) {
	if ((prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == calling_up_family) return TRUE;
	}
	return FALSE;
}

kind *CreationPredicates::what_kind_of_calling(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == calling_up_family) return up->assert_kind;
	}
	return NULL;
}

pcalc_prop *CreationPredicates::calling_up(wording W, pcalc_term t, kind *K) {
	unary_predicate *up = UnaryPredicates::new(calling_up_family);
	up->calling_name = W;
	up->assert_kind = K;
	return Atoms::unary_PREDICATE_new(up, t);
}

wording CreationPredicates::get_calling_name(pcalc_prop *prop) {
	if ((prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == calling_up_family) return up->calling_name;
	}
	return EMPTY_WORDING;
}

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void CreationPredicates::stock_is_a_var(up_family *self, int n) {
	if (n == 1) {
		is_a_var_up = UnaryPredicates::new(is_a_var_up_family);
	}
}

void CreationPredicates::stock_is_a_const(up_family *self, int n) {
	if (n == 1) {
		is_a_const_up = UnaryPredicates::new(is_a_const_up_family);
	}
}

pcalc_prop *CreationPredicates::is_a_var_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(is_a_var_up, t);
}

pcalc_prop *CreationPredicates::is_a_const_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(is_a_const_up, t);
}

pcalc_prop *CreationPredicates::is_a_kind_up(pcalc_term t, kind *K) {
	unary_predicate *up = UnaryPredicates::new(is_a_kind_up_family);
	up->assert_kind = K;
	return Atoms::unary_PREDICATE_new(up, t);
}

kind *CreationPredicates::what_kind(pcalc_prop *prop) {
	if ((prop) && (prop->element == PREDICATE_ATOM) && (prop->arity == 1)) {
		unary_predicate *up = RETRIEVE_POINTER_unary_predicate(prop->predicate);
		if (up->family == is_a_kind_up_family) return up->assert_kind;
	}
	return NULL;
}

#ifdef CORE_MODULE
int CreationPredicates::typecheck_calling(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}
int CreationPredicates::typecheck_is_a_var(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}
int CreationPredicates::typecheck_is_a_const(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}
int CreationPredicates::typecheck_is_a_kind(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, K_object) == NEVER_MATCH)
		internal_error("is_a_kind predicate misapplied");
	return ALWAYS_MATCH;
}
#endif

@ "Called" predicates cannot be asserted, and to test them, we simply copy the
value into the local variable of the given name. Note then that here
the I6 |=| (set equal) operator is being used in a condition context:
there's a good chance that the value set is non-zero (since all objects
and enumerated values are non-zero), but it isn't necessarily so --
in Inform it's legal to quantify over times and truth states, for
instance, where 0 is a legal I6 value. So we use the comma operator
to throw away the result of the assignment, and evaluate the condition
to |true|.

=
#ifdef CORE_MODULE
void CreationPredicates::schema_calling(up_family *self, int task, unary_predicate *up,
	annotated_i6_schema *asch, kind *K) {
	switch(task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "(%L=(*1), true)",
				LocalVariables::ensure_calling(up->calling_name, up->assert_kind));
			break;
		default:
			asch->schema = NULL;
			break;
	}
}
#endif

void CreationPredicates::log_calling(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("called='%W'", up->calling_name);
	if (up->assert_kind) WRITE(":%u", up->assert_kind);
}

void CreationPredicates::log_is_a_var(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-var");
}

void CreationPredicates::log_is_a_const(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-const");
}

void CreationPredicates::log_is_a_kind(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-kind");
	if (up->assert_kind) WRITE("=%u", up->assert_kind);
}

int CreationPredicates::contains_callings(pcalc_prop *prop) {
	for (pcalc_prop *p = prop; p; p = p->next)
		if (CreationPredicates::is_calling_up_atom(p))
			return TRUE;
	return FALSE;
}
