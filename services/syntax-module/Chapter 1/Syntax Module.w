[SyntaxModule::] Syntax Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
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

@ Like all modules, this one must define a |start| and |end| function. Here,
all we need do is set up some debugging log facilities.

=
void SyntaxModule::start(void) {
	NodeType::make_parentage_allowed_table();
	NodeType::metadata_setup();
	Annotations::make_annotation_allowed_table();
	Writers::register_logger('m', Node::log_tree);    /* |$m| = log syntax tree from node */
	Writers::register_logger_I('N', NodeType::log);   /* |$N| = log individual node type */
	Writers::register_logger('P', Node::log_node);    /* |$P| = log individual parse node */
	Writers::register_logger('T', Node::log_subtree); /* |$T| = log tree under node */
}

void SyntaxModule::end(void) {
}
