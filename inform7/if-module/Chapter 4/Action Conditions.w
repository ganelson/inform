[AConditions::] Action Conditions.

A special condition for testing against action patterns.

@ =
parse_node *AConditions::new_action_TEST_VALUE(action_pattern *ap, wording W) {
	if (ap == NULL) internal_error("null action pattern");
	parse_node *spec = Node::new_with_words(TEST_VALUE_NT, W);
	spec->down = ARvalues::from_action_pattern(ap);
	Node::set_text(spec->down, W);
	return spec;
}

int AConditions::is_action_TEST_VALUE(parse_node *spec) {
	if ((Node::is(spec, TEST_VALUE_NT)) &&
		((ARvalues::to_action_pattern(spec->down)) ||
		(ARvalues::to_explicit_action(spec->down)))) return TRUE;
	return FALSE;
}

parse_node *AConditions::action_tested(parse_node *spec) {
	if (AConditions::is_action_TEST_VALUE(spec) == FALSE)
		internal_error("action improperly extracted");
	return spec->down;
}
