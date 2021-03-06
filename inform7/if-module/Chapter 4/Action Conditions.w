[AConditions::] Action Conditions.

A special condition for testing against action patterns.

@ The actions plugin introduces a special form of condition: authors can
write "if taking or dropping something", for example, and this is implicitly
a test of what the current action is.

This is represented in the parse tree as the twig:

	TEST_VALUE_NT
		CONSTANT_NT

where the constant below is the action seen as a noun -- linguistically, a
"gerund". It will always have the kind |K_stored_action| or |K_description_of_action|,
depending on whether the test is against an explicit action or something vaguer.

Here we create and test for such twigs:

=
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

@ As noted above, the gerund is just the child node, and from that we can
reconstruct the original action pattern which led to this condition:

=
parse_node *AConditions::gerund_from_TEST_VALUE(parse_node *spec) {
	if (AConditions::is_action_TEST_VALUE(spec) == FALSE)
		internal_error("gerund improperly extracted");
	return spec->down;
}

action_pattern *AConditions::pattern_from_action_TEST_VALUE(parse_node *spec) {
	if (AConditions::is_action_TEST_VALUE(spec)) {
		parse_node *gerund = AConditions::gerund_from_TEST_VALUE(spec);
		action_pattern *ap = ARvalues::to_action_pattern(gerund);
		if (ap == NULL) {
			explicit_action *ea = Node::get_constant_explicit_action(gerund);
			if (ea) ap = ea->as_described;
		}
		return ap;
	}
	return NULL;
}

@ Which we can then compile a test against:

=
int AConditions::compile_condition(value_holster *VH, parse_node *spec) {
	if (AConditions::is_action_TEST_VALUE(spec)) {
		action_pattern *ap = AConditions::pattern_from_action_TEST_VALUE(spec);
		RTActionPatterns::compile_pattern_match(VH, ap, FALSE);
		return TRUE;
	}
	return FALSE;
}
