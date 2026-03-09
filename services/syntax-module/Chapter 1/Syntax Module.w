[SyntaxModule::] Syntax Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d SYNTAX_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function. Here,
all we need do is set up some debugging log facilities.

=
void SyntaxModule::start(void) {
	NodeType::make_parentage_allowed_table();
	NodeType::metadata_setup();
	Annotations::make_annotation_allowed_table();
	Writers::register_writer('P', Node::write_node);  /* `%P` = write individual parse node */
	Writers::register_logger('m', Node::log_tree);    /* `$m` = log syntax tree from node */
	Writers::register_logger_I('N', NodeType::log);   /* `$N` = log individual node type */
	Writers::register_logger('P', Node::log_node);    /* `$P` = log individual parse node */
	Writers::register_logger('T', Node::log_subtree); /* `$T` = log tree under node */
	Annotations::begin();
}

void SyntaxModule::end(void) {
}
