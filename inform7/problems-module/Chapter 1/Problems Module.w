[ProblemsModule::] Problems Module.

Setting up the use of this module.

@h Introduction.

@d PROBLEMS_MODULE TRUE

@h Annotations.

@e problem_falls_under_ANNOT /* |parse_node|: what heading the sentence falls under */

=
DECLARE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)
MAKE_ANNOTATION_FUNCTIONS(problem_falls_under, parse_node)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void ProblemsModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
	ParseTree::allow_annotation_to_category(L2_NCAT, problem_falls_under_ANNOT);
}

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;

@h The end.

=
void ProblemsModule::end(void) {
}
