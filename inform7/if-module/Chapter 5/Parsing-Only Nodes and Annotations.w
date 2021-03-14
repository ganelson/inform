[ParsingNodes::] Parsing-Only Nodes and Annotations.

Additional syntax tree node and annotation types used by the parsing plugin.

@ There is just one additional node type, used for tokens in Understand grammar,
but there are also several new annotations:

@e TOKEN_NT   /* used for tokens in grammar */

@e constant_command_grammar_ANNOT /* |command_grammar|: for constant values */
@e grammar_token_literal_ANNOT /* int: for grammar tokens which are literal words */
@e grammar_token_relation_ANNOT /* |binary_predicate|: for relation tokens */
@e grammar_value_ANNOT /* |parse_node|: used as a marker when evaluating Understand grammar */
@e slash_class_ANNOT /* int: used when partitioning grammar tokens */
@e slash_dash_dash_ANNOT /* |int|: used when partitioning grammar tokens */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(constant_command_grammar, command_grammar)

@ =
MAKE_ANNOTATION_FUNCTIONS(constant_command_grammar, command_grammar)

void ParsingNodes::nodes_and_annotations(void) {
	NodeType::new(TOKEN_NT, I"TOKEN_NT",   0, INFTY, L3_NCAT, 0);

	Annotations::declare_type(constant_command_grammar_ANNOT,
		ParsingNodes::write_constant_grammar_verb_ANNOT);
	Annotations::declare_type(grammar_token_literal_ANNOT,
		ParsingNodes::write_grammar_token_literal_ANNOT);
	Annotations::declare_type(grammar_token_relation_ANNOT,
		ParsingNodes::write_grammar_token_relation_ANNOT);
	Annotations::declare_type(grammar_value_ANNOT,
		ParsingNodes::write_grammar_value_ANNOT);
	Annotations::declare_type(slash_class_ANNOT,
		ParsingNodes::write_slash_class_ANNOT);
	Annotations::declare_type(slash_dash_dash_ANNOT,
		ParsingNodes::write_slash_dash_dash_ANNOT);

	Annotations::allow(CONSTANT_NT, constant_command_grammar_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_token_literal_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_token_relation_ANNOT);
	Annotations::allow(TOKEN_NT, grammar_value_ANNOT);
	Annotations::allow(TOKEN_NT, slash_class_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, slash_dash_dash_ANNOT);
}

@ And for the debugging log:

=
void ParsingNodes::write_constant_grammar_verb_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_command_grammar(p))
		WRITE(" {command grammar: CG%d}", Node::get_constant_command_grammar(p)->allocation_id);
}
void ParsingNodes::write_grammar_token_literal_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {grammar token literal: %d}",
		Annotations::read_int(p, grammar_token_literal_ANNOT));
}
void ParsingNodes::write_grammar_token_relation_ANNOT(text_stream *OUT, parse_node *p) {
	binary_predicate *bp = Node::get_grammar_token_relation(p);
	if (bp) WRITE(" {grammar token relation: %S}", bp->debugging_log_name);
}
void ParsingNodes::write_grammar_value_ANNOT(text_stream *OUT, parse_node *p) {
	WRITE(" {grammar value: $P}", Node::get_grammar_value(p));
}
void ParsingNodes::write_slash_class_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, slash_class_ANNOT) > 0)
		WRITE(" {slash: %d}", Annotations::read_int(p, slash_class_ANNOT));
}
void ParsingNodes::write_slash_dash_dash_ANNOT(text_stream *OUT, parse_node *p) {
	if (Annotations::read_int(p, slash_dash_dash_ANNOT) > 0)
		WRITE(" {slash-dash-dash: %d}", Annotations::read_int(p, slash_dash_dash_ANNOT));
}
