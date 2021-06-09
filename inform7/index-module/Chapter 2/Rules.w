[IXRules::] Rules.

To index rules and rulebooks.

@h Indexing.
Some rules are provided with index text:

=
typedef struct rule_indexing_data {
	struct wording italicised_text; /* when indexing a rulebook */
} rule_indexing_data;

rule_indexing_data IXRules::new_indexing_data(rule *R) {
	rule_indexing_data rid;
	rid.italicised_text = EMPTY_WORDING;
	return rid;
}

void IXRules::set_italicised_index_text(rule *R, wording W) {
	R->indexing_data.italicised_text = W;
}

@ And off we go:

=
int IXRules::index(OUTPUT_STREAM, rule *R, rulebook *owner, rule_context rc) {
	int no_responses_indexed = 0;
	if (Wordings::nonempty(R->indexing_data.italicised_text)) @<Index the italicised text to do with the rule@>;
	if (Wordings::nonempty(R->name)) @<Index the rule name along with Javascript buttons@>;
	if ((Wordings::nonempty(R->indexing_data.italicised_text) == FALSE) &&
		(Wordings::nonempty(R->name) == FALSE) && (R->defn_as_I7_source))
		@<Index some text extracted from the first line of the otherwise anonymous rule@>;
	@<Index a link to the first line of the rule's definition@>;
	if (global_compilation_settings.number_rules_in_index) @<Index the small type rule numbering@>;
	@<Index any applicability conditions@>;
	HTML_CLOSE("p");
	@<Index any response texts in the rule@>;
	return no_responses_indexed;
}

@<Index the italicised text to do with the rule@> =
	WRITE("<i>%+W", R->indexing_data.italicised_text);
	#ifdef IF_MODULE
	if (rc.scene_context) {
		WRITE(" during ");
		wording SW = Scenes::get_name(rc.scene_context);
		WRITE("%+W", SW);
	}
	#endif
	WRITE("</i>&nbsp;&nbsp;");

@

@d MAX_PASTEABLE_RULE_NAME_LENGTH 500

@<Index the rule name along with Javascript buttons@> =
	HTML::begin_colour(OUT, I"800000");
	WRITE("%+W", R->name);
	HTML::end_colour(OUT);
	WRITE("&nbsp;&nbsp;");

	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%+W", R->name);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>name</i> ");

	Str::clear(S);
	WRITE_TO(S, "The %W is not listed in the %W rulebook.\n", R->name, owner->primary_name);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>unlist</i>");
	DISCARD_TEXT(S)

	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->responses[l].message) {
			c++;
		}
	if (c > 0) {
		WRITE("&nbsp;&nbsp;");
		Index::extra_link_with(OUT, 1000000+R->allocation_id, "responses");
		WRITE("%d", c);
	}

@<Index any response texts in the rule@> =
	int l, c;
	for (l=0, c=0; l<26; l++)
		if (R->responses[l].message) {
			if (c == 0) Index::extra_div_open_nested(OUT, 1000000+R->allocation_id, 2);
			else HTML_TAG("br");
			IXRules::index_response(OUT, R, l, R->responses[l].message);
			c++;
		}
	if (c > 0) Index::extra_div_close_nested(OUT);
	no_responses_indexed = c;

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	parse_node *pn = R->defn_as_I7_source->at->down;
	if ((pn) && (Wordings::nonempty(Node::get_text(pn)))) {
		WRITE("(%+W", Node::get_text(pn));
		if (pn->next) WRITE("; ...");
		WRITE(")");
	}

@<Index a link to the first line of the rule's definition@> =
	if (R->defn_as_I7_source) {
		parse_node *pn = R->defn_as_I7_source->at;
		if ((pn) && (Wordings::nonempty(Node::get_text(pn))))
			Index::link(OUT, Wordings::first_wn(Node::get_text(pn)));
	}

@<Index the small type rule numbering@> =
	WRITE(" ");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (R->defn_as_I7_source) WRITE("%d", R->defn_as_I7_source->allocation_id);
	else WRITE("primitive");
	HTML_CLOSE("span");

@<Index any applicability conditions@> =
	applicability_constraint *acl;
	LOOP_OVER_LINKED_LIST(acl, applicability_constraint, R->applicability_constraints) {
		HTML_TAG("br");
		Index::link(OUT, Wordings::first_wn(Node::get_text(acl->where_imposed)));
		WRITE("&nbsp;%+W", Node::get_text(acl->where_imposed));
	}

@h Indexing of lists.
There's a division of labour: here we arrange the index of the rules and
show the linkage between them, while the actual content for each rule is
handled in the "Rules" section.

=
int IXRules::index_booking_list(OUTPUT_STREAM, booking_list *L, rule_context rc,
	char *billing, rulebook *owner, int *resp_count) {
	booking *prev = NULL;
	int count = 0;
	LOOP_OVER_BOOKINGS(br, L) {
		rule *R = RuleBookings::get_rule(br);
		int skip = FALSE;
		#ifdef IF_MODULE
		imperative_defn *id = Rules::get_imperative_definition(R);
		if (id) {
			id_body *idb = id->body_of_defn;
			id_runtime_context_data *phrcd = &(idb->runtime_context_data);
			scene *during_scene = Scenes::rcd_scene(phrcd);
			if ((rc.scene_context) && (during_scene != rc.scene_context)) skip = TRUE;
			if ((rc.action_context) &&
				(ActionRules::within_action_context(phrcd, rc.action_context) == FALSE))
				skip = TRUE;
		}
		#endif
		if (skip == FALSE) {
			count++;
			IXRules::br_start_index_line(OUT, prev, billing);
			*resp_count += IXRules::index(OUT, R, owner, rc);
		}
		prev = br;
	}
	return count;
}

@ The "index links" are not hypertextual: they're the little icons showing
the order of precedence of rules in the list. On some index pages we don't
want this, so:

=
int show_index_links = TRUE;

void IXRules::list_suppress_indexed_links(void) {
	show_index_links = FALSE;
}

void IXRules::list_resume_indexed_links(void) {
	show_index_links = TRUE;
}

void IXRules::br_start_index_line(OUTPUT_STREAM, booking *prev, char *billing) {
	HTML::open_indented_p(OUT, 2, "hanging");
	if ((billing[0]) && (show_index_links)) IXRules::br_show_linkage_icon(OUT, prev);
	WRITE("%s", billing);
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	if ((billing[0] == 0) && (show_index_links)) IXRules::br_show_linkage_icon(OUT, prev);
}

@ And here's how the index links (if wanted) are chosen and plotted:

=
void IXRules::br_show_linkage_icon(OUTPUT_STREAM, booking *prev) {
	text_stream *icon_name = NULL; /* redundant assignment to appease |gcc -O2| */
	if ((prev == NULL) || (prev->commentary.tooltip_text == NULL)) {
		HTML::icon_with_tooltip(OUT, I"inform:/doc_images/rulenone.png",
			I"start of rulebook", NULL);
		return;
	}
	switch (prev->commentary.next_rule_specificity) {
		case -1: icon_name = I"inform:/doc_images/ruleless.png"; break;
		case 0: icon_name = I"inform:/doc_images/ruleequal.png"; break;
		case 1: icon_name = I"inform:/doc_images/rulemore.png"; break;
		default: internal_error("unknown rule specificity");
	}
	HTML::icon_with_tooltip(OUT, icon_name,
		prev->commentary.tooltip_text, prev->commentary.law_applied);
}

@ =
int unique_xtra_no = 0;


@ =
int IXRules::index_rulebook(OUTPUT_STREAM, rulebook *rb, char *billing, rule_context rc, int *resp_count) {
	int suppress_outcome = FALSE, t;
	if (rb == NULL) return 0;
	if (billing == NULL) internal_error("No billing for rb index");
	if (billing[0] != 0) {
		#ifdef IF_MODULE
		if (rc.action_context) suppress_outcome = TRUE;
		#endif
		if (BookingLists::is_contextually_empty(rb->contents, rc)) suppress_outcome = TRUE;
	}
	t = IXRules::index_booking_list(OUT, rb->contents, rc, billing, rb, resp_count);
	IXRules::index_outcomes(OUT, &(rb->my_outcomes), suppress_outcome);
	IXRules::rb_index_placements(OUT, rb);
	return t;
}

#ifdef IF_MODULE
void IXRules::index_action_rules(OUTPUT_STREAM, action_name *an, rulebook *rb,
	int code, char *desc, int *resp_count) {
	int t = 0;
	IXRules::list_suppress_indexed_links();
	if (code >= 0) t += IXRules::index_rulebook(OUT, Rulebooks::std(code), desc,
		IXRules::action_context(an), resp_count);
	if (rb) t += IXRules::index_rulebook(OUT, rb, desc,
		IXRules::no_rule_context(), resp_count);
	IXRules::list_resume_indexed_links();
	if (t > 0) HTML_TAG("br");
}
#endif

@h Affected by placements.
The contents of rulebooks can be unexpected if sentences are used which
explicitly list, or unlist, rules. To make the index more useful in these
cases, we keep a linked list, for each rulebook, of all sentences which
have affected it in this way:

=
typedef struct rulebook_indexing_data {
	struct placement_affecting *placement_list; /* linked list of explicit placements */
} rulebook_indexing_data;

typedef struct placement_affecting {
	struct parse_node *placement_sentence;
	struct placement_affecting *next;
	CLASS_DEFINITION
} placement_affecting;

rulebook_indexing_data IXRules::new_rulebook_indexing_data(rulebook *RB) {
	rulebook_indexing_data rid;
	rid.placement_list = NULL;
	return rid;
}

void IXRules::affected_by_placement(rulebook *rb, parse_node *where) {
	placement_affecting *npl = CREATE(placement_affecting);
	npl->placement_sentence = where;
	npl->next = rb->indexing_data.placement_list;
	rb->indexing_data.placement_list = npl;
}

int IXRules::rb_no_placements(rulebook *rb) {
	int t = 0;
	placement_affecting *npl = rb->indexing_data.placement_list;
	while (npl) { t++; npl = npl->next; }
	return t;
}

void IXRules::rb_index_placements(OUTPUT_STREAM, rulebook *rb) {
	placement_affecting *npl = rb->indexing_data.placement_list;
	while (npl) {
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("<i>NB:</i> %W", Node::get_text(npl->placement_sentence));
		Index::link(OUT, Wordings::first_wn(Node::get_text(npl->placement_sentence)));
		HTML_CLOSE("span");
		HTML_TAG("br");
		npl = npl->next;
	}
}

void IXRules::index_outcomes(OUTPUT_STREAM, outcomes *outs, int suppress_outcome) {
	if (suppress_outcome == FALSE) {
		rulebook_outcome *ro;
		LOOP_OVER_LINKED_LIST(ro, rulebook_outcome, outs->named_outcomes) {
			named_rulebook_outcome *rbno = ro->outcome_name;
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("<i>outcome</i>&nbsp;&nbsp;");
			if (outs->default_named_outcome == ro) WRITE("<b>");
			WRITE("%+W", Nouns::nominative_singular(rbno->name));
			if (outs->default_named_outcome == ro) WRITE("</b> (default)");
			WRITE(" - <i>");
			switch(ro->kind_of_outcome) {
				case SUCCESS_OUTCOME: WRITE("a success"); break;
				case FAILURE_OUTCOME: WRITE("a failure"); break;
				case NO_OUTCOME: WRITE("no outcome"); break;
			}
			WRITE("</i>");
			HTML_CLOSE("p");
		}
	}
	if ((outs->default_named_outcome == NULL) &&
		(outs->default_rule_outcome != NO_OUTCOME) &&
		(suppress_outcome == FALSE)) {
		HTML::open_indented_p(OUT, 2, "hanging");
		WRITE("<i>default outcome is</i> ");
		switch(outs->default_rule_outcome) {
			case SUCCESS_OUTCOME: WRITE("success"); break;
			case FAILURE_OUTCOME: WRITE("failure"); break;
		}
		HTML_CLOSE("p");
	}
}

@h Rule contexts.
These are mainly (only?) used in indexing, as a way to represent the idea of
being the relevant scene or action for a rule.

=
typedef struct rule_context {
	struct action_name *action_context;
	struct scene *scene_context;
} rule_context;

rule_context IXRules::action_context(action_name *an) {
	rule_context rc;
	rc.action_context = an;
	rc.scene_context = NULL;
	return rc;
}
rule_context IXRules::scene_context(scene *s) {
	rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = s;
	return rc;
}

rule_context IXRules::no_rule_context(void) {
	rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = NULL;
	return rc;
}

int IXRules::phrase_fits_rule_context(id_body *idb, rule_context rc) {
	if (rc.scene_context == NULL) return TRUE;
	if (idb == NULL) return FALSE;
	if (Scenes::rcd_scene(&(idb->runtime_context_data)) != rc.scene_context) return FALSE;
	return TRUE;
}

@ When we index a response, we also provide a paste button for the source
text to assert a change:

=
void IXRules::index_response(OUTPUT_STREAM, rule *R, int marker, response_message *resp) {
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	HTML_OPEN_WITH("span",
		"style=\"color: #ffffff; "
		"font-family: 'Courier New', Courier, monospace; background-color: #8080ff;\"");
	WRITE("&nbsp;&nbsp;%c&nbsp;&nbsp; ", 'A' + marker);
	HTML_CLOSE("span");
	HTML_OPEN_WITH("span", "style=\"color: #000066;\"");
	WRITE("%+W", resp->the_ts->unsubstituted_text);
	HTML_CLOSE("span");
	WRITE("&nbsp;&nbsp;");
	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%+W response (%c)", R->name, 'A' + marker);
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>name</i>");
	WRITE("&nbsp;");
	Str::clear(S);
	WRITE_TO(S, "The %+W response (%c) is \"New text.\".");
	PasteButtons::paste_text(OUT, S);
	WRITE("&nbsp;<i>set</i>");
	DISCARD_TEXT(S)
}
