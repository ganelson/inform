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
		(Wordings::nonempty(R->name) == FALSE) && (R->defn_as_phrase))
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
			Strings::index_response(OUT, R, l, R->responses[l].message);
			c++;
		}
	if (c > 0) Index::extra_div_close_nested(OUT);
	no_responses_indexed = c;

@<Index some text extracted from the first line of the otherwise anonymous rule@> =
	parse_node *pn = R->defn_as_phrase->declaration_node->down;
	if ((pn) && (Wordings::nonempty(Node::get_text(pn)))) {
		WRITE("(%+W", Node::get_text(pn));
		if (pn->next) WRITE("; ...");
		WRITE(")");
	}

@<Index a link to the first line of the rule's definition@> =
	if (R->defn_as_phrase) {
		parse_node *pn = R->defn_as_phrase->declaration_node;
		if ((pn) && (Wordings::nonempty(Node::get_text(pn))))
			Index::link(OUT, Wordings::first_wn(Node::get_text(pn)));
	}

@<Index the small type rule numbering@> =
	WRITE(" ");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (R->defn_as_phrase) WRITE("%d", R->defn_as_phrase->allocation_id);
	else WRITE("primitive");
	HTML_CLOSE("span");

@<Index any applicability conditions@> =
	applicability_condition *acl;
	LOOP_OVER_LINKED_LIST(acl, applicability_condition, R->applicability_conditions) {
		HTML_TAG("br");
		Index::link(OUT, Wordings::first_wn(Node::get_text(acl->where_imposed)));
		WRITE("&nbsp;%+W", Node::get_text(acl->where_imposed));
	}
