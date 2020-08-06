[ProblemsModule::] Problems Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d PROBLEMS_MODULE TRUE

@ Note that this module uses its fellow services module //syntax//, and adds
the following annotation to the syntax tree:

@e problem_falls_under_ANNOT /* |parse_node|: what heading the sentence falls under */

=
DECLARE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)
MAKE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)

@ Like all modules, this one must define a |start| and |end| function.

=
void ProblemsModule::start(void) {
	Annotations::allow_for_category(L2_NCAT, problem_falls_under_ANNOT);
	Annotations::declare_type(problem_falls_under_ANNOT,
		ProblemsModule::write_problem_falls_under_ANNOT);
}
void ProblemsModule::end(void) {
}
void ProblemsModule::write_problem_falls_under_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_problem_falls_under(p))
		WRITE("{under: '%W'}", Node::get_text(Node::get_problem_falls_under(p)));
}
