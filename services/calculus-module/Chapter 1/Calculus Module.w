[CalculusModule::] Calculus Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d CALCULUS_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

@e PREDICATE_CALCULUS_DA
@e PREDICATE_CALCULUS_WORKINGS_DA

=
COMPILE_WRITER(i6_schema *, Calculus::Schemas::log)
COMPILE_WRITER(pcalc_prop *, Propositions::log)
COMPILE_WRITER(pcalc_prop *, Atoms::log)
COMPILE_WRITER(pcalc_term *, Terms::log)
COMPILE_WRITER(binary_predicate *, BinaryPredicates::log)
COMPILE_WRITER(unary_predicate *, UnaryPredicates::log)

void CalculusModule::start(void) {
	REGISTER_WRITER('D', Propositions::log);
	REGISTER_WRITER('i', Calculus::Schemas::log);
	REGISTER_WRITER('o', Atoms::log);
	REGISTER_WRITER('r', UnaryPredicates::log);
	REGISTER_WRITER('0', Terms::log);
	REGISTER_WRITER('2', BinaryPredicates::log);
	Log::declare_aspect(PREDICATE_CALCULUS_DA, U"predicate calculus", FALSE, FALSE);
	Log::declare_aspect(PREDICATE_CALCULUS_WORKINGS_DA, U"predicate calculus workings", FALSE, FALSE);
	Annotations::declare_type(subject_term_ANNOT,
		CalculusModule::write_subject_term_ANNOT);
	KindPredicates::start();
	Calculus::Equality::start();
}
void CalculusModule::end(void) {
}

@ //calculus// provides one extra annotation for the syntax tree:

@e subject_term_ANNOT /* `pcalc_term`: what the subject of the subtree was */

@ =
DECLARE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)
MAKE_ANNOTATION_FUNCTIONS(subject_term, pcalc_term)

void CalculusModule::write_subject_term_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_subject_term(p)) {
		WRITE(" {term: ");
		Terms::write(OUT, Node::get_subject_term(p));
		WRITE("}");
	}
}

@ We also have to make annotation functions for one special annotation needed
by //linguistics//:

@<Predeclarations of node annotation functions@> +=
DECLARE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)

@ =
MAKE_ANNOTATION_FUNCTIONS(relationship, binary_predicate)
