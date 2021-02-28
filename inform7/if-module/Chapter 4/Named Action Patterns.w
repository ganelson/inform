[NamedActionPatterns::] Named Action Patterns.

A named action pattern is a categorisation of behaviour.

@ Behaviour such as "acting suspiciously" is stored as a named action pattern,
which is little more than a list of action patterns; a given action falls under
this category if it matches one of the patterns.

=
typedef struct named_action_pattern {
	struct noun *as_noun;
	struct linked_list *patterns; /* of |action_pattern| */
	struct wording text_of_declaration;
	struct nap_compilation_data compilation_data;
	CLASS_DEFINITION
} named_action_pattern;

typedef struct named_action_pattern_entry {
	struct action_pattern *behaviour;
	struct parse_node *where_decided;
	CLASS_DEFINITION
} named_action_pattern_entry;

@ The following adds an action pattern to a NAP identified only by its name, |W|:

=
void NamedActionPatterns::add(action_pattern *ap, wording W) {
	named_action_pattern *nap = NamedActionPatterns::by_name(W);
	if (nap == NULL) nap = NamedActionPatterns::new(W);
	named_action_pattern_entry *nape = CREATE(named_action_pattern_entry);
	nape->behaviour = ap;
	nape->where_decided = current_sentence;
	ADD_TO_LINKED_LIST(nape, named_action_pattern_entry, nap->patterns);
}

named_action_pattern *NamedActionPatterns::by_name(wording W) {
	parse_node *p = Lexicon::retrieve(NAMED_AP_MC, W);
	if (p) return Rvalues::to_named_action_pattern(p);
	return NULL;
}

named_action_pattern *NamedActionPatterns::new(wording W) {
	named_action_pattern *nap = CREATE(named_action_pattern);
	nap->patterns = NEW_LINKED_LIST(named_action_pattern_entry);
	nap->text_of_declaration = W;
	nap->compilation_data = RTNamedActionPatterns::new(nap);
	nap->as_noun = Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		NAMED_AP_MC, Rvalues::from_named_action_pattern(nap), Task::language_of_syntax());
	return nap;
}

@ And here we test whether a given action name appears in a NAP, which it does
if and only if it appears in one of the patterns in the list:

=
int NamedActionPatterns::covers_action(named_action_pattern *nap, action_name *an) {
	named_action_pattern_entry *nape;
	if (nap)
		LOOP_OVER_LINKED_LIST(nape, named_action_pattern_entry, nap->patterns)
			if (ActionPatterns::within_action_context(nape->behaviour, an))
				return TRUE;
	return FALSE;
}
