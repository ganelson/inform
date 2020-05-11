[ProblemsModule::] Problems Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d PROBLEMS_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

=
void ProblemsModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	Annotations::allow_for_category(L2_NCAT, problem_falls_under_ANNOT);
}
void ProblemsModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@ This module uses |syntax|, and adds the following annotations to the
syntax tree.

@e problem_falls_under_ANNOT /* |parse_node|: what heading the sentence falls under */

=
DECLARE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)
MAKE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)
