[IXActivities::] Activities.

To index activities.

@ 

=
typedef struct activity_indexing_data {
	int activity_indexed; /* has this been indexed yet? */
	struct wording av_documentation_symbol; /* cross-reference to HTML documentation, if any */
	struct activity_crossref *cross_references;
} activity_indexing_data;

typedef struct activity_crossref {
	struct phrase *rule_dependent;
	struct activity_crossref *next;
} activity_crossref;

@ =
activity_indexing_data IXActivities::new_indexing_data(activity *av, wording doc) {
	activity_indexing_data aid;
	aid.activity_indexed = FALSE;
	aid.av_documentation_symbol = doc;
	aid.cross_references = NULL;
	return aid;
}

void IXActivities::index_by_number(OUTPUT_STREAM, int id, int indent) {
	activity *av = Activities::std(id);
	if (av) IXActivities::index(OUT, av, indent);
}

int IXActivities::no_rules(activity *av) {
	int t = 0;
	t += Rulebooks::no_rules(av->before_rules);
	t += Rulebooks::no_rules(av->for_rules);
	t += Rulebooks::no_rules(av->after_rules);
	return t;
}
void IXActivities::index(OUTPUT_STREAM, activity *av, int indent) {
	int empty = TRUE;
	char *text = NULL;
	if (av->indexing_data.activity_indexed) return;
	av->indexing_data.activity_indexed = TRUE;
	if (Rulebooks::is_empty(av->before_rules, Phrases::Context::no_rule_context()) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->for_rules, Phrases::Context::no_rule_context()) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->after_rules, Phrases::Context::no_rule_context()) == FALSE) empty = FALSE;
	if (av->indexing_data.cross_references) empty = FALSE;
	TEMPORARY_TEXT(doc_link)
	if (Wordings::nonempty(av->indexing_data.av_documentation_symbol))
		WRITE_TO(doc_link, "%+W", Wordings::one_word(Wordings::first_wn(av->indexing_data.av_documentation_symbol)));
	if (empty) text = "There are no rules before, for or after this activity.";
	IXRules::index_rules_box(OUT, NULL, av->name, doc_link,
		NULL, av, text, indent, TRUE);
	DISCARD_TEXT(doc_link)
}

void IXActivities::index_details(OUTPUT_STREAM, activity *av) {
	int ignore_me = 0;
	IXRules::index_rulebook(OUT, av->before_rules, "before", Phrases::Context::no_rule_context(), &ignore_me);
	IXRules::index_rulebook(OUT, av->for_rules, "for", Phrases::Context::no_rule_context(), &ignore_me);
	IXRules::index_rulebook(OUT, av->after_rules, "after", Phrases::Context::no_rule_context(), &ignore_me);
	IXActivities::index_cross_references(OUT, av);
}

void IXActivities::annotate_list_for_cross_references(activity_list *avl, phrase *ph) {
	for (; avl; avl = avl->next)
		if (avl->activity) {
			activity *av = avl->activity;
			activity_crossref *acr = CREATE(activity_crossref);
			acr->next = av->indexing_data.cross_references;
			av->indexing_data.cross_references = acr;
			acr->rule_dependent = ph;
		}
}

void IXActivities::index_cross_references(OUTPUT_STREAM, activity *av) {
	activity_crossref *acr;
	for (acr = av->indexing_data.cross_references; acr; acr = acr->next) {
		phrase *ph = acr->rule_dependent;
		if ((ph->declaration_node) && (Wordings::nonempty(Node::get_text(ph->declaration_node)))) {
			HTML::open_indented_p(OUT, 2, "tight");
			WRITE("NB: %W", Node::get_text(ph->declaration_node));
			Index::link(OUT, Wordings::first_wn(Node::get_text(ph->declaration_node)));
			HTML_CLOSE("p");
		}
	}
}
