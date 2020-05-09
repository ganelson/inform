[SyntaxModule::] Syntax Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d SYNTAX_MODULE TRUE

@ This module defines the following classes:

@e parse_node_CLASS
@e parse_node_tree_CLASS
@e parse_node_annotation_CLASS

=
DECLARE_CLASS(parse_node)
DECLARE_CLASS(parse_node_tree)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(parse_node_annotation, 500)

@ Like all modules, this one must define a |start| and |end| function:

=
void SyntaxModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	ParseTree::metadata_setup();
}
void SyntaxModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

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
