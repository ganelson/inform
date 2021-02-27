[RTNamedActionPatterns::] Named Action Patterns.

@

=
typedef struct nap_compilation_data {
	struct inter_name *nap_iname; /* for an I6 routine to test this NAP */
} nap_compilation_data;

nap_compilation_data RTNamedActionPatterns::new(named_action_pattern *nap) {
	nap_compilation_data ncd;
	package_request *PR = Hierarchy::local_package(NAMED_ACTION_PATTERNS_HAP);
	ncd.nap_iname = Hierarchy::make_iname_in(NAP_FN_HL, PR);
	return ncd;
}

inter_name *RTNamedActionPatterns::identifier(named_action_pattern *nap) {
	return nap->compilation_data.nap_iname;
}

void RTNamedActionPatterns::compile(void) {
	named_action_pattern *nap;
	LOOP_OVER(nap, named_action_pattern) {
		packaging_state save = Routines::begin(nap->compilation_data.nap_iname);
		named_action_pattern_entry *nape;
		LOOP_OVER_LINKED_LIST(nape, named_action_pattern_entry, nap->patterns) {
			action_pattern *ap = nape->behaviour;
			current_sentence = nape->where_decided;
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				ActionPatterns::emit_pattern_match(*ap, TRUE);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
		Produce::rfalse(Emit::tree());
		Routines::end(save);
	}
}
