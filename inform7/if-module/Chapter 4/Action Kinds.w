[ARvalues::] Action Kinds.

Three action-related kinds of value.

@ The following represent action names, stored actions and descriptions of
actions respectively: see //Actions Plugin// for what these terms mean.

= (early code)
kind *K_action_name = NULL;
kind *K_stored_action = NULL;
kind *K_description_of_action = NULL;

@ These are created by a Neptune file inside //WorldModelKit//, and are
recognised by their Inter identifiers:

=
int ARvalues::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"ACTION_NAME_TY")) {
		K_action_name = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"DESCRIPTION_OF_ACTION_TY")) {
		K_description_of_action = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"STORED_ACTION_TY")) {
		K_stored_action = new_base; return TRUE;
	}
	return FALSE;
}

@ A stored action can always be compared to a gerund: for instance,

>> if the current action is taking something...

=
int ARvalues::actions_typecheck_equality(kind *K1, kind *K2) {
	if ((Kinds::eq(K1, K_stored_action)) && (Kinds::eq(K2, K_description_of_action)))
		return TRUE;
	return FALSE;
}

@ All three of these kinds can have constant values. For an action name, these
correspond simply to //action_name// objects:

=
parse_node *ARvalues::from_action_name(action_name *val) { 
		CONV_FROM(action_name, K_action_name) }
action_name *ARvalues::to_action_name(parse_node *spec) { 
		CONV_TO(action_name) }

@ When text is parsed to an action pattern, the result can be stored as a
constant in two ways. If the pattern unambiguously describes a single explicit
action, the result has the kind "stored action" and corresponds to an
//explicit_action// object; if the pattern is looser than that, the result
is a "description of action" and correspond to an //action_pattern//.

For example, "taking the golden telephone" might be a |K_stored_action|
constant, but "doing something to the golden telephone" or "taking something"
or "taking the golden telephone in the presence of Mr Wu" would all be
|K_description_of_action|.

=
parse_node *ARvalues::from_action_pattern(action_pattern *val) {
	int failure_code = 0;
	explicit_action *ea = ExplicitActions::from_action_pattern(val, &failure_code);
	if (ea) {
		parse_node *spec = Node::new(CONSTANT_NT);
		Node::set_kind_of_value(spec, K_stored_action);
		Node::set_constant_explicit_action(spec, ea);
		return spec;
	} else {
		CONV_FROM(action_pattern, K_description_of_action);
	}
}
action_pattern *ARvalues::to_action_pattern(parse_node *spec) { 
		CONV_TO(action_pattern) }
explicit_action *ARvalues::to_explicit_action(parse_node *spec) { 
		CONV_TO(explicit_action) }

@ Finally, for a named action pattern, constant values correspond to
//named_action_pattern// objects. These are actually never used at run-time
and do not appear as rvalues in any permanent way inside the compiler, so
the kind |K_description_of_action| is given to them only on principle. If
they were used as values, this is the kind we would probably give them.

=
parse_node *ARvalues::from_named_action_pattern(named_action_pattern *val) { 
		CONV_FROM(named_action_pattern, K_description_of_action ) }
named_action_pattern *ARvalues::to_named_action_pattern(parse_node *spec) { 
		CONV_TO(named_action_pattern) }

@ It's not useful to be able to compare description of action constants for
equality in this sense. There would be a case for doing so with stored actions,
but in practice there seems little need, so for the moment we do not.

=
int ARvalues::compare_CONSTANT(parse_node *spec1, parse_node *spec2, int *rv) {
	kind *K = Node::get_kind_of_value(spec1);
	if (Kinds::eq(K, K_action_name)) {
		if (ARvalues::to_action_name(spec1) == ARvalues::to_action_name(spec2)) {
			*rv = TRUE;
		}
		*rv = FALSE;
		return TRUE;
	}
	return FALSE;
}
