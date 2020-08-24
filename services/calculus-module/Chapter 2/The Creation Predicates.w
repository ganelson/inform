[Calculus::Creation::] The Creation Predicates.

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
void Calculus::Creation::start(void) {
	calling_up_family = UnaryPredicateFamilies::new();
	is_a_var_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_var_up_family, STOCK_UPF_MTID, Calculus::Creation::stock_is_a_var);
	METHOD_ADD(is_a_var_up_family, LOG_UPF_MTID, Calculus::Creation::log_is_a_var);
	is_a_const_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_const_up_family, STOCK_UPF_MTID, Calculus::Creation::stock_is_a_const);
	METHOD_ADD(is_a_const_up_family, LOG_UPF_MTID, Calculus::Creation::log_is_a_const);
	is_a_kind_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(is_a_kind_up_family, LOG_UPF_MTID, Calculus::Creation::log_is_a_kind);
	#ifdef CORE_MODULE
	METHOD_ADD(is_a_var_up_family, TYPECHECK_UPF_MTID, Calculus::Creation::typecheck_is_a_var);
	METHOD_ADD(is_a_const_up_family, TYPECHECK_UPF_MTID, Calculus::Creation::typecheck_is_a_const);
	METHOD_ADD(is_a_kind_up_family, TYPECHECK_UPF_MTID, Calculus::Creation::typecheck_is_a_kind);
	#endif
}

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void Calculus::Creation::stock_is_a_var(up_family *self, int n) {
	if (n == 1) {
		is_a_var_up = UnaryPredicates::blank(is_a_var_up_family);
	}
}

void Calculus::Creation::stock_is_a_const(up_family *self, int n) {
	if (n == 1) {
		is_a_const_up = UnaryPredicates::blank(is_a_const_up_family);
	}
}

pcalc_prop *Calculus::Creation::is_a_var_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(is_a_var_up, t);
}

pcalc_prop *Calculus::Creation::is_a_const_up(pcalc_term t) {
	return Atoms::unary_PREDICATE_new(is_a_const_up, t);
}

pcalc_prop *Calculus::Creation::is_a_kind_up(pcalc_term t, kind *K) {
	unary_predicate *up = UnaryPredicates::blank(is_a_kind_up_family);
	up->assert_kind = K;
	return Atoms::unary_PREDICATE_new(up, t);
}

#ifdef CORE_MODULE
int Calculus::Creation::typecheck_is_a_var(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}
int Calculus::Creation::typecheck_is_a_const(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}
int Calculus::Creation::typecheck_is_a_kind(up_family *self, unary_predicate *up,
	pcalc_prop *prop, variable_type_assignment *vta, tc_problem_kit *tck) {
	kind *actually_find = Propositions::Checker::kind_of_term(&(prop->terms[0]), vta, tck);
	if (Kinds::compatible(actually_find, K_object) == NEVER_MATCH)
		internal_error("is_a_kind predicate misapplied");
	return ALWAYS_MATCH;
}
#endif

void Calculus::Creation::log_is_a_var(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-var");
}

void Calculus::Creation::log_is_a_const(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-const");
}

void Calculus::Creation::log_is_a_kind(up_family *self, OUTPUT_STREAM, unary_predicate *up) {
	WRITE("is-a-kind");
	if (up->assert_kind) WRITE("=%u", up->assert_kind);
}
