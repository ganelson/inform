[ActionsNodes::] Actions-Only Nodes and Annotations.

Additional syntax tree node and annotation types used by the actions plugin.

@ There is just one additional node type, but it can take four new annotations:

@e ACTION_NT  /* "taking something closed" */

@e action_meaning_ANNOT /* |action_pattern|: meaning in parse tree when used as noun */
@e constant_action_name_ANNOT /* |action_name|: for constant values */
@e constant_action_pattern_ANNOT /* |action_pattern|: for constant values */
@e constant_named_action_pattern_ANNOT /* |named_action_pattern|: for constant values */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(action_meaning, action_pattern)
DECLARE_ANNOTATION_FUNCTIONS(constant_action_name, action_name)
DECLARE_ANNOTATION_FUNCTIONS(constant_action_pattern, action_pattern)
DECLARE_ANNOTATION_FUNCTIONS(constant_named_action_pattern, named_action_pattern)

@ =
MAKE_ANNOTATION_FUNCTIONS(action_meaning, action_pattern)
MAKE_ANNOTATION_FUNCTIONS(constant_action_name, action_name)
MAKE_ANNOTATION_FUNCTIONS(constant_action_pattern, action_pattern)
MAKE_ANNOTATION_FUNCTIONS(constant_named_action_pattern, named_action_pattern)

void ActionsNodes::nodes_and_annotations(void) {
	NodeType::new(ACTION_NT, I"ACTION_NT", 0, INFTY, L3_NCAT, ASSERT_NFLAG);

	Annotations::declare_type(action_meaning_ANNOT,
		ActionsNodes::write_action_meaning_ANNOT);
	Annotations::declare_type(constant_action_name_ANNOT,
		ActionsNodes::write_constant_action_name_ANNOT);
	Annotations::declare_type(constant_action_pattern_ANNOT,
		ActionsNodes::write_constant_action_pattern_ANNOT);
	Annotations::declare_type(constant_named_action_pattern_ANNOT,
		ActionsNodes::write_constant_named_action_pattern_ANNOT);

	Annotations::allow(ACTION_NT, action_meaning_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, action_meaning_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_action_name_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_action_pattern_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_named_action_pattern_ANNOT);
}

@ And for the debugging log:

=
void ActionsNodes::write_action_meaning_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_action_meaning(p)) {
		WRITE(" {action meaning: ");
		PL::Actions::Patterns::write(OUT, Node::get_action_meaning(p));
		WRITE("}");
	} 
}
void ActionsNodes::write_constant_action_name_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_action_name(p))
		WRITE(" {action name: %W}", Node::get_constant_action_name(p)->naming_data.present_name);
}
void ActionsNodes::write_constant_action_pattern_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_action_pattern(p)) {
		WRITE(" {action pattern: ");
		PL::Actions::Patterns::write(OUT, Node::get_constant_action_pattern(p));
		WRITE("}");
	} 
}
void ActionsNodes::write_constant_named_action_pattern_ANNOT(text_stream *OUT,
	parse_node *p) {
	if (Node::get_constant_named_action_pattern(p)) {
		WRITE(" {named action pattern: ");
		Nouns::write(OUT, Node::get_constant_named_action_pattern(p)->as_noun);
		WRITE("}");
	} 
}
