[Calculus::Creation::] The Creation Predicates.

To define the predicates causing instances to be created.

@ This predicate plays a very special role in our calculus, and must always
exist.

= (early code)
up_family *calling_up_family = NULL;
up_family *creation_up_family = NULL;

@h Family.
This is a minimal representation only: Inform adds other methods to the equality
family to handle its typechecking and so on.

=
void Calculus::Creation::start(void) {
	calling_up_family = UnaryPredicateFamilies::new();
	creation_up_family = UnaryPredicateFamilies::new();
	METHOD_ADD(creation_up_family, STOCK_UPF_MTID, Calculus::Creation::stock_creation);
}

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void Calculus::Creation::stock_creation(up_family *self, int n) {
	if (n == 1) {
		; // make isakind, etc., here
	}
}
