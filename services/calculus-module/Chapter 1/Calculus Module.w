[CalculusModule::] Calculus Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CALCULUS_MODULE TRUE

@ This module defines the following classes:

@e binary_predicate_CLASS
@e bp_family_CLASS
@e pcalc_term_CLASS
@e pcalc_func_CLASS
@e pcalc_prop_CLASS
@e unary_predicate_CLASS

=
DECLARE_CLASS(binary_predicate)
DECLARE_CLASS(bp_family)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_func, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_term, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(pcalc_prop, 1000)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(unary_predicate, 1000)

@ Like all modules, this one must define a |start| and |end| function:

@e PREDICATE_CALCULUS_DA
@e PREDICATE_CALCULUS_WORKINGS_DA

=
void CalculusModule::start(void) {
	Log::declare_aspect(PREDICATE_CALCULUS_DA, L"predicate calculus", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_WORKINGS_DA, L"predicate calculus workings", FALSE, FALSE);
	BinaryPredicates::start_explicit_relation();
}
void CalculusModule::end(void) {
}
