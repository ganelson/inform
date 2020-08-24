[CalculusModule::] Calculus Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CALCULUS_MODULE TRUE

@ This module defines the following classes:

@e i6_schema_CLASS
@e binary_predicate_CLASS
@e bp_family_CLASS
@e up_family_CLASS
@e pcalc_term_CLASS
@e pcalc_func_CLASS
@e pcalc_prop_CLASS
@e unary_predicate_CLASS

=
DECLARE_CLASS(binary_predicate)
DECLARE_CLASS(bp_family)
DECLARE_CLASS(up_family)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_func, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_term, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_prop, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(unary_predicate, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(i6_schema, 100)

@ Like all modules, this one must define a |start| and |end| function:

@e PREDICATE_CALCULUS_DA
@e PREDICATE_CALCULUS_WORKINGS_DA

=
COMPILE_WRITER(pcalc_prop *, Propositions::log)
COMPILE_WRITER(pcalc_prop *, Atoms::log)
COMPILE_WRITER(pcalc_term *, Terms::log)
COMPILE_WRITER(binary_predicate *, BinaryPredicates::log)
COMPILE_WRITER(unary_predicate *, UnaryPredicates::log)

void CalculusModule::start(void) {
	REGISTER_WRITER('D', Propositions::log);
	REGISTER_WRITER('o', Atoms::log);
	REGISTER_WRITER('0', Terms::log);
	REGISTER_WRITER('2', BinaryPredicates::log);
	REGISTER_WRITER('r', UnaryPredicates::log);
	Log::declare_aspect(PREDICATE_CALCULUS_DA, L"predicate calculus", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_WORKINGS_DA, L"predicate calculus workings", FALSE, FALSE);
	KindPredicates::start();
	AdjectivalPredicates::start();
	CreationPredicates::start();
	WherePredicates::start();
	Calculus::Equality::start();
}
void CalculusModule::end(void) {
}

@ We also have to make annotation functions for one special annotation needed
by //linguistics//:

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)

@ =
MAKE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
