[SyntaxModule::] Syntax Module.

Setting up the use of this module.

@h Introduction.

@d SYNTAX_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e parse_node_MT
@e parse_node_annotation_array_MT

=
ALLOCATE_INDIVIDUALLY(parse_node)
ALLOCATE_IN_ARRAYS(parse_node_annotation, 500)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void SyntaxModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
	ParseTree::metadata_setup();
}

@<Register this module's stream writers@> =
	;

@

@e VERIFICATIONS_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(VERIFICATIONS_DA, L"verifications", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('m', ParseTree::log_tree);
	Writers::register_logger_I('N', ParseTree::log_type);
	Writers::register_logger('P', ParseTree::log_node);
	Writers::register_logger('T', ParseTree::log_subtree);

@<Register this module's command line switches@> =
	;

@h The end.

=
void SyntaxModule::end(void) {
}
