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
	struct id_body *rule_dependent;
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
	if (Rulebooks::is_empty(av->before_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->for_rules) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->after_rules) == FALSE) empty = FALSE;
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
	IXRules::index_rulebook(OUT, av->before_rules, "before",
		IXRules::no_rule_context(), &ignore_me);
	IXRules::index_rulebook(OUT, av->for_rules, "for",
		IXRules::no_rule_context(), &ignore_me);
	IXRules::index_rulebook(OUT, av->after_rules, "after",
		IXRules::no_rule_context(), &ignore_me);
	IXActivities::index_cross_references(OUT, av);
}

void IXActivities::annotate_list_for_cross_references(activity_list *avl, id_body *idb) {
	for (; avl; avl = avl->next)
		if (avl->activity) {
			activity *av = avl->activity;
			activity_crossref *acr = CREATE(activity_crossref);
			acr->next = av->indexing_data.cross_references;
			av->indexing_data.cross_references = acr;
			acr->rule_dependent = idb;
		}
}

void IXActivities::index_cross_references(OUTPUT_STREAM, activity *av) {
	activity_crossref *acr;
	for (acr = av->indexing_data.cross_references; acr; acr = acr->next) {
		id_body *idb = acr->rule_dependent;
		if ((ImperativeDefinitions::body_at(idb)) && (Wordings::nonempty(Node::get_text(ImperativeDefinitions::body_at(idb))))) {
			HTML::open_indented_p(OUT, 2, "tight");
			WRITE("NB: %W", Node::get_text(ImperativeDefinitions::body_at(idb)));
			Index::link(OUT, Wordings::first_wn(Node::get_text(ImperativeDefinitions::body_at(idb))));
			HTML_CLOSE("p");
		}
	}
}

@h Describing the current VM.

=
void IXActivities::innards(OUTPUT_STREAM, target_vm *VM) {
	IXActivities::index_VM(OUT, VM);
	NewUseOptions::index(OUT);
	HTML_OPEN("p");
	Index::extra_link(OUT, 3);
	WRITE("See some technicalities for Inform maintainers only");
	HTML_CLOSE("p");
	Index::extra_div_open(OUT, 3, 2, "e0e0e0");
	IXActivities::show_configuration(OUT);
	@<Add some paste buttons for the debugging log@>;
	Index::extra_div_close(OUT, "e0e0e0");
}

@ The index provides some hidden paste icons for these:

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	WRITE("Debugging log:");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	for (int i=0; i<NO_DEFINED_DA_VALUES; i++) {
		debugging_aspect *da = &(the_debugging_aspects[i]);
		if (Str::len(da->unhyphenated_name) > 0) {
			TEMPORARY_TEXT(is)
			WRITE_TO(is, "Include %S in the debugging log.", da->unhyphenated_name);
			PasteButtons::paste_text(OUT, is);
			WRITE("&nbsp;%S", is);
			DISCARD_TEXT(is)
			HTML_TAG("br");
		}
	}
	HTML_CLOSE("p");

@ =
void IXActivities::index_VM(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) internal_error("target VM not set yet");
	Index::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	ExtensionIndex::plot_icon(OUT, VM);
	TargetVMs::write(OUT, VM);
	HTML_CLOSE("p");
}

@ =
void IXActivities::show_configuration(OUTPUT_STREAM) {
	HTML_OPEN("p");
	Index::anchor(OUT, I"CONFIG");
	WRITE("Inform language definition:\n");
	PluginManager::list_plugins(OUT, "Included", TRUE);
	PluginManager::list_plugins(OUT, "Excluded", FALSE);
	HTML_CLOSE("p");
}
