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

@ We are allowed to give names to certain kinds of behaviour by "characterising"
an action.

=
void NamedActionPatterns::characterise(action_pattern *ap, wording W) {
	LOGIF(ACTION_PATTERN_PARSING, "Characterising the action:\n$A...as %W\n", ap, W);

	if (<article>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPIsArticle),
			"there's only an article here",
			"not a name, so I'm not sure what this action is supposed to be.");
		return;
	}

	if (APClauses::get_val(ap, ACTOR_AP_CLAUSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamedAPWithActor),
			"behaviour characterised by named action patterns can only specify the action",
			"not the actor: as a result, it cannot include requests to other people to "
			"do things.");
		return;
	}

	NamedActionPatterns::add(ap, W);
}

@ So, then, the following adds an action pattern to a NAP identified only by its name, |W|:

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

@ A Preform version of the parser-by-name:

=
<named-action-pattern> internal {
	named_action_pattern *nap = NamedActionPatterns::by_name(W);
	if (nap) {
		==> { -, nap }; return TRUE;
	}
	==> { fail nonterminal };
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
