[RTNamedActionPatterns::] Named Action Patterns.

To compile the named_action_patterns submodule for a compilation unit, which contains
_named_action_pattern packages.

@h Compilation data.
Each |named_action_pattern| object contains this data:

=
typedef struct nap_compilation_data {
	struct package_request *nap_package;
	struct inter_name *test_fn_iname;
	struct parse_node *where_created;
} nap_compilation_data;

nap_compilation_data RTNamedActionPatterns::new(named_action_pattern *nap) {
	nap_compilation_data ncd;
	ncd.nap_package = NULL;
	ncd.test_fn_iname = NULL;
	ncd.where_created = current_sentence;
	return ncd;
}

@ The package is a simple one, mainly containing a function to test whether
the current action fits the named pattern or not.

=
package_request *RTNamedActionPatterns::package(named_action_pattern *nap) {
	if (nap->compilation_data.nap_package == NULL)
		nap->compilation_data.nap_package =
			Hierarchy::local_package_to(NAMED_ACTION_PATTERNS_HAP,
				nap->compilation_data.where_created);
	return nap->compilation_data.nap_package;
}

inter_name *RTNamedActionPatterns::test_fn_iname(named_action_pattern *nap) {
	if (nap->compilation_data.test_fn_iname == NULL)
		nap->compilation_data.test_fn_iname =
			Hierarchy::make_iname_in(NAP_FN_HL, RTNamedActionPatterns::package(nap));
	return nap->compilation_data.test_fn_iname;
}

@h Compilation.

=
void RTNamedActionPatterns::compile(void) {
	named_action_pattern *nap;
	LOOP_OVER(nap, named_action_pattern) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "named action pattern %W", nap->text_of_declaration);
		Sequence::queue(&RTNamedActionPatterns::compilation_agent,
			STORE_POINTER_named_action_pattern(nap), desc);
	}
}

void RTNamedActionPatterns::compilation_agent(compilation_subtask *t) {
	named_action_pattern *nap = RETRIEVE_POINTER_named_action_pattern(t->data);
	packaging_state save = Functions::begin(RTNamedActionPatterns::test_fn_iname(nap));
	named_action_pattern_entry *nape;
	LOOP_OVER_LINKED_LIST(nape, named_action_pattern_entry, nap->patterns) {
		action_pattern *ap = nape->behaviour;
		current_sentence = nape->where_decided;
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			RTActionPatterns::emit_pattern_match(ap, TRUE);
			EmitCode::code();
			EmitCode::down();
				EmitCode::rtrue();
			EmitCode::up();
		EmitCode::up();
	}
	EmitCode::rfalse();
	Functions::end(save);
}
