[CommandsIndex::] Commands Index.

To construct the index of command verbs.

@ The following modest structure is used for the indexing of command verbs,
and is too deeply boring to comment upon. These are the headwords of commands
which can be typed at run-time, like QUIT or INVENTORY. For indexing purposes,
we divide these headwords into five "natures":

@d NORMAL_COMMAND 1
@d ALIAS_COMMAND 2
@d OUT_OF_WORLD_COMMAND 3
@d TESTING_COMMAND 4
@d BARE_DIRECTION_COMMAND 5

=
typedef struct command_index_entry {
	int nature; /* one of the above values */
	struct text_stream *command_headword; /* text of command headword, such as "REMOVE" */
	struct command_grammar *cg_indexed; /* ...leading to... */
	struct command_index_entry *next_alphabetically; /* next in linked list */
	CLASS_DEFINITION
} command_index_entry;

command_index_entry *sorted_command_index = NULL; /* in alphabetical order of |text| */

@ =
void CommandsIndex::index_meta_verb(char *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%s", t);
	vie->nature = OUT_OF_WORLD_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

void CommandsIndex::test_verb(text_stream *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::duplicate(t);
	vie->nature = TESTING_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;
}

void CommandsIndex::verb_definition(OUTPUT_STREAM, wchar_t *p, text_stream *trueverb, wording W) {
	int i = 1;
	if ((p[0] == 0) || (p[1] == 0)) return;
	if (Str::len(trueverb) > 0) {
		if (Str::eq_wide_string(trueverb, L"0") == FALSE) {
			WRITE("%S", trueverb);
			if (Wordings::nonempty(W))
				CommandsIndex::index_command_aliases(OUT,
					CommandGrammars::for_command_verb(W));
			for (i=1; p[i+1]; i++) if (p[i] == ' ') break;
			for (; p[i+1]; i++) if (p[i] != ' ') break;
			if (p[i+1]) WRITE(" ");
		}
	}
	for (; p[i+1]; i++) {
		int c = p[i];
		switch(c) {
			case '"': WRITE("&quot;"); break;
			default: PUT_TO(OUT, c); break;
		}
	}
}

command_index_entry *CommandsIndex::vie_new_from(OUTPUT_STREAM, wchar_t *headword, command_grammar *cg, int nature) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%w", headword);
	vie->nature = nature;
	vie->cg_indexed = cg;
	vie->next_alphabetically = NULL;
	return vie;
}

void CommandsIndex::commands(OUTPUT_STREAM) {
	command_index_entry *vie, *vie2, *last_vie2, *list_start = NULL;
	command_grammar *cg;
	int head_letter;

	LOOP_OVER(cg, command_grammar)
		CommandsIndex::make_command_index_entries(OUT, cg);

	vie = CREATE(command_index_entry);
	vie->command_headword = I"0";
	vie->nature = BARE_DIRECTION_COMMAND;
	vie->cg_indexed = NULL;
	vie->next_alphabetically = NULL;

	LOOP_OVER(vie, command_index_entry) {
		if (list_start == NULL) { list_start = vie; continue; }
		vie2 = list_start;
		last_vie2 = NULL;
		while (vie2 && (Str::cmp(vie->command_headword, vie2->command_headword) > 0)) {
			last_vie2 = vie2;
			vie2 = vie2->next_alphabetically;
		}
		if (last_vie2 == NULL) {
			vie->next_alphabetically = list_start; list_start = vie;
		} else {
			last_vie2->next_alphabetically = vie; vie->next_alphabetically = vie2;
		}
	}

	for (vie = list_start, head_letter = 0; vie; vie = vie->next_alphabetically) {
		command_grammar *cg;
		if (Str::get_first_char(vie->command_headword) != head_letter) {
			if (head_letter) HTML_TAG("br");
			head_letter = Str::get_first_char(vie->command_headword);
		}
		cg = vie->cg_indexed;
		switch (vie->nature) {
			case NORMAL_COMMAND:
				CommandsIndex::index_normal(OUT, cg, vie->command_headword);
				break;
			case ALIAS_COMMAND:
				CommandsIndex::index_alias(OUT, cg, vie->command_headword);
				break;
			case OUT_OF_WORLD_COMMAND:
				HTML::begin_colour(OUT, I"800000");
				WRITE("&quot;%S&quot;, <i>a command for controlling play</i>",
					vie->command_headword);
				HTML::end_colour(OUT);
				HTML_TAG("br");
				break;
			case TESTING_COMMAND:
				HTML::begin_colour(OUT, I"800000");
				WRITE("&quot;%S&quot;, <i>a testing command not available "
					"in the final game</i>",
					vie->command_headword);
				HTML::end_colour(OUT);
				HTML_TAG("br");
				break;
			case BARE_DIRECTION_COMMAND:
				WRITE("&quot;[direction]&quot; - <i>Going</i>");
				HTML_TAG("br");
				break;
		}
	}
}

void CommandsIndex::alphabetical(OUTPUT_STREAM) {
	int nr = NUMBER_CREATED(action_name);
	action_name **sorted = Memory::calloc(nr, sizeof(action_name *), INDEX_SORTING_MREASON);
	if (sorted) {
		@<Sort the action names@>;
		@<Tabulate the action names@>;
		Memory::I7_array_free(sorted, INDEX_SORTING_MREASON, nr, sizeof(action_name *));
	}
}

@<Tabulate the action names@> =
	HTML::begin_html_table(OUT, NULL, FALSE, 0, 0, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	WRITE("<b>action</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>noun</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>second noun</b>");
	HTML::end_html_row(OUT);
	int i;
	for (i=0; i<nr; i++) {
		HTML::first_html_column(OUT, 0);
		action_name *an = sorted[i];
		if (ActionSemantics::is_out_of_world(an)) HTML::begin_colour(OUT, I"800000");
		WRITE("%W", ActionNameNames::tensed(an, IS_TENSE));
		if (ActionSemantics::is_out_of_world(an)) HTML::end_colour(OUT);
		Index::detail_link(OUT, "A", an->allocation_id, TRUE);

		if (ActionSemantics::requires_light(an)) WRITE(" <i>requires light</i>");

		HTML::next_html_column(OUT, 0);
		if (ActionSemantics::can_have_noun(an) == FALSE) {
			WRITE("&mdash;");
		} else {
			if (ActionSemantics::noun_access(an) == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (ActionSemantics::noun_access(an) == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>"); ChartElement::old_index_kind(OUT, ActionSemantics::kind_of_noun(an), FALSE, FALSE);
			WRITE("</b>");
		}

		HTML::next_html_column(OUT, 0);
		if (ActionSemantics::can_have_second(an) == FALSE) {
			WRITE("&mdash;");
		} else {
			if (ActionSemantics::second_access(an) == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (ActionSemantics::second_access(an) == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>"); ChartElement::old_index_kind(OUT, ActionSemantics::kind_of_second(an), FALSE, FALSE);
			WRITE("</b>");
		}
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);

@ As usual, we sort with the C library's |qsort|.

@<Sort the action names@> =
	int i = 0;
	action_name *an;
	LOOP_OVER(an, action_name) sorted[i++] = an;
	qsort(sorted, (size_t) nr, sizeof(action_name *), CommandsIndex::compare_action_names);

@ The following means the table is sorted in alphabetical order of action name.

=
int CommandsIndex::compare_action_names(const void *ent1, const void *ent2) {
	const action_name *an1 = *((const action_name **) ent1);
	const action_name *an2 = *((const action_name **) ent2);
	return Wordings::strcmp(ActionNameNames::tensed((action_name *) an1, IS_TENSE), ActionNameNames::tensed((action_name *) an2, IS_TENSE));
}

@ =
void CommandsIndex::page(OUTPUT_STREAM) {
	int f = FALSE, par_count = 0;
	action_name *an;
	heading *current_area = NULL;
	inform_extension *ext = NULL;
	LOOP_OVER(an, action_name) {
		int new_par = FALSE;
		f = IXActions::index(OUT, an, 1, &ext, &current_area, f, &new_par, FALSE, FALSE);
		if (new_par) par_count++;
		an->indexing_data.an_index_group = par_count;
	}
	if (f) HTML_CLOSE("p");
}

void CommandsIndex::detail_pages(void) {
	int f = FALSE;
	action_name *an;
	heading *current_area = NULL;
	inform_extension *ext = NULL;
	LOOP_OVER(an, action_name) {
		text_stream *OUT = Index::open_file(I"A.html", I"<Actions",
			an->allocation_id, I"Detail view");
		f = FALSE;
		int new_par = FALSE;
		action_name *an2;
		current_area = NULL;
		ext = NULL;
		LOOP_OVER(an2, action_name) {
			if (an2->indexing_data.an_index_group == an->indexing_data.an_index_group)
				f = IXActions::index(OUT, an2, 1, &ext, &current_area, f, &new_par, (an2 == an)?TRUE:FALSE, TRUE);
		}
		if (f) HTML_CLOSE("p");
		HTML_TAG("hr");
		IXActions::index(OUT, an, 2, &ext, &current_area, FALSE, &new_par, FALSE, FALSE);
	}
}

void CommandsIndex::tokens(OUTPUT_STREAM) {
	HTML_OPEN("p");
	WRITE("In addition to the tokens listed below, any description of an object "
		"or value can be used: for example, \"[number]\" matches text like 127 or "
		" SIX, and \"[open door]\" matches the name of any nearby door which is "
		"currently open.");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("Names of objects are normally understood only when they are within "
		"sight, but writing 'any' lifts this restriction. So \"[any person]\" allows "
		"every name of a person, wherever they happen to be.");
	HTML_CLOSE("p");
	CommandsIndex::index_tokens(OUT);
}

void CommandsIndex::index_for_extension(OUTPUT_STREAM, source_file *sf, inform_extension *E) {
	action_name *an;
	int kc = 0;
	LOOP_OVER(an, action_name)
		if (Lexer::file_of_origin(Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE))) == E->read_into_file)
			kc = IndexExtensions::document_headword(OUT, kc, E, "Actions", I"action",
				ActionNameNames::tensed(an, IS_TENSE));
	if (kc != 0) HTML_CLOSE("p");
}

@ The "Commands available to the player" portion of the Actions index page
is, in effect, an alphabetised merge of the CGLs found within the command CGs.
CGLs for the "no verb verb" appear under the special headword "0" (which
is not displayed); otherwise CGLs appear under the main command word, and
aliases are shown with references like: "drag", same as "pull".

One routine takes a CG and creates suitable entries for the Actions index
to process; the other two routines act upon any such entries once they are
needed.

=
void CommandsIndex::make_command_index_entries(OUTPUT_STREAM, command_grammar *cg) {
	if ((cg->cg_is == CG_IS_COMMAND) && (cg->first_line)) {
		if (Wordings::empty(cg->command))
			CommandsIndex::vie_new_from(OUT, L"0", cg, NORMAL_COMMAND);
		else
			CommandsIndex::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->command)), cg, NORMAL_COMMAND);
		for (int i=0; i<cg->no_aliased_commands; i++)
			CommandsIndex::vie_new_from(OUT, Lexer::word_text(Wordings::first_wn(cg->aliased_command[i])), cg, ALIAS_COMMAND);
	}
}

void CommandsIndex::index_alias(OUTPUT_STREAM, command_grammar *cg, text_stream *headword) {
	WRITE("&quot;%S&quot;, <i>same as</i> &quot;%N&quot;",
		headword, Wordings::first_wn(cg->command));
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "%N", Wordings::first_wn(cg->command));
	Index::below_link(OUT, link);
	DISCARD_TEXT(link)
	HTML_TAG("br");
}

@ =
void CommandsIndex::index_tokens(OUTPUT_STREAM) {
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "anybody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "anyone", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "anything", NULL, NULL, I"things_token", "same as \"[thing]\"");
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "other things", NULL, NULL, I"things_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "somebody", NULL, NULL, I"someone_token", "same as \"[someone]\"");
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "someone", NULL, NULL, I"someone_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "something", NULL, NULL, I"things_token", "same as \"[thing]\"");
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "something preferably held", NULL, NULL, I"things_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "text", NULL, NULL, I"text_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "things", NULL, NULL, I"things_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "things inside", NULL, NULL, I"things_token", NULL);
	CommandsIndex::index_tokens_for(OUT, EMPTY_WORDING, "things preferably held", NULL, NULL, I"things_token", NULL);
	command_grammar *cg;
	LOOP_OVER(cg, command_grammar)
		if (cg->cg_is == CG_IS_TOKEN)
			CommandsIndex::index_tokens_for(OUT, cg->token_name, NULL,
				cg->where_cg_created, cg, NULL, NULL);
}

void CommandsIndex::index_tokens_for(OUTPUT_STREAM, wording W, char *special, parse_node *where,
	command_grammar *defns, text_stream *help, char *explanation) {
	HTML::open_indented_p(OUT, 1, "tight");
	WRITE("\"[");
	if (special) WRITE("%s", special); else WRITE("%+W", W);
	WRITE("]\"");
	if (where) Index::link(OUT, Wordings::first_wn(Node::get_text(where)));
	if (Str::len(help) > 0) Index::DocReferences::link(OUT, help);
	if (explanation) WRITE(" - %s", explanation);
	HTML_CLOSE("p");
	if (defns) CommandsIndex::index_list_for_token(OUT, defns);
}


void CommandsIndex::index_command_aliases(OUTPUT_STREAM, command_grammar *cg) {
	if (cg == NULL) return;
	int i, n = cg->no_aliased_commands;
	for (i=0; i<n; i++)
		WRITE("/%N", Wordings::first_wn(cg->aliased_command[i]));
}


typedef struct cg_line_indexing_data {
	struct cg_line *next_with_action; /* used when indexing actions */
	struct command_grammar *belongs_to_cg; /* similarly, used only in indexing */
} cg_line_indexing_data;

cg_line_indexing_data CommandsIndex::new_id(cg_line *cg) {
	cg_line_indexing_data cglid;
	cglid.belongs_to_cg = NULL;
	cglid.next_with_action = NULL;
	return cglid;
}

@h Indexing by grammar.
This is the more obvious form of indexing: we show the grammar lines which
make up an individual CGL. (For instance, this is used in the Actions index
to show the grammar for an individual command word, by calling the routine
below for that command word's CG.) Such an index list is done in sorted
order, so that the order of appearance in the index corresponds to the
order of parsing -- this is what the reader of the index is interested in.

=
void CommandsIndex::index_normal(OUTPUT_STREAM, command_grammar *cg, text_stream *headword) {
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		CommandsIndex::cgl_index_normal(OUT, cgl, headword);
}

void CommandsIndex::cgl_index_normal(OUTPUT_STREAM, cg_line *cgl, text_stream *headword) {
	action_name *an = cgl->resulting_action;
	if (an == NULL) return;
	Index::anchor(OUT, headword);
	if (ActionSemantics::is_out_of_world(an))
		HTML::begin_colour(OUT, I"800000");
	WRITE("&quot;");
	CommandsIndex::verb_definition(OUT, Lexer::word_text(cgl->original_text),
		headword, EMPTY_WORDING);
	WRITE("&quot;");
	Index::link(OUT, cgl->original_text);
	WRITE(" - <i>%+W", ActionNameNames::tensed(an, IS_TENSE));
	Index::detail_link(OUT, "A", an->allocation_id, TRUE);
	if (cgl->reversed) WRITE(" (reversed)");
	WRITE("</i>");
	if (ActionSemantics::is_out_of_world(an))
		HTML::end_colour(OUT);
	HTML_TAG("br");
}

@h Indexing by action.
Grammar lines are typically indexed twice: the other time is when all
grammar lines belonging to a given action are tabulated. Special linked
lists are kept for this purpose, and this is where we unravel them and
print to the index. The question of sorted vs unsorted is meaningless
here, since the CGLs appearing in such a list will typically belong to
several different CGs. (As it happens, they appear in order of creation,
i.e., in source text order.)

Tiresomely, all of this means that we need to store "uphill" pointers
in CGLs: back up to the CGs that own them. The following routine does
this for a whole list of CGLs:

=
void CommandsIndex::list_assert_ownership(command_grammar *cg) {
	LOOP_THROUGH_UNSORTED_CG_LINES(cgl, cg)
		cgl->indexing_data.belongs_to_cg = cg;
}

@ And this routine accumulates the per-action lists of CGLs:

=
void CommandsIndex::list_with_action_add(cg_line *list_head, cg_line *cgl) {
	if (list_head == NULL) internal_error("tried to add to null action list");
	while (list_head->indexing_data.next_with_action)
		list_head = list_head->indexing_data.next_with_action;
	list_head->indexing_data.next_with_action = cgl;
}

@ Finally, here we index an action list of CGLs, each getting a line in
the HTML index.

=
int CommandsIndex::index_list_with_action(OUTPUT_STREAM, cg_line *cgl) {
	int said_something = FALSE;
	while (cgl != NULL) {
		if (cgl->indexing_data.belongs_to_cg) {
			wording VW = CommandGrammars::get_verb_text(cgl->indexing_data.belongs_to_cg);
			TEMPORARY_TEXT(trueverb)
			if (Wordings::nonempty(VW))
				WRITE_TO(trueverb, "%W", Wordings::one_word(Wordings::first_wn(VW)));
			HTML::open_indented_p(OUT, 2, "hanging");
			WRITE("&quot;");
			CommandsIndex::verb_definition(OUT,
				Lexer::word_text(cgl->original_text), trueverb, VW);
			WRITE("&quot;");
			Index::link(OUT, cgl->original_text);
			if (cgl->reversed) WRITE(" <i>reversed</i>");
			HTML_CLOSE("p");
			said_something = TRUE;
			DISCARD_TEXT(trueverb)
		}
		cgl = cgl->indexing_data.next_with_action;
	}
	return said_something;
}

@ And the same, but more simply:

=
void CommandsIndex::index_list_for_token(OUTPUT_STREAM, command_grammar *cg) {
	int k = 0;
	LOOP_THROUGH_SORTED_CG_LINES(cgl, cg)
		if (cgl->indexing_data.belongs_to_cg) {
			wording VW = CommandGrammars::get_verb_text(cgl->indexing_data.belongs_to_cg);
			TEMPORARY_TEXT(trueverb)
			if (Wordings::nonempty(VW))
				WRITE_TO(trueverb, "%W", Wordings::one_word(Wordings::first_wn(VW)));
			HTML::open_indented_p(OUT, 2, "hanging");
			if (k++ == 0) WRITE("="); else WRITE("or");
			WRITE(" &quot;");
			CommandsIndex::verb_definition(OUT,
				Lexer::word_text(cgl->original_text), trueverb, EMPTY_WORDING);
			WRITE("&quot;");
			Index::link(OUT, cgl->original_text);
			if (cgl->reversed) WRITE(" <i>reversed</i>");
			HTML_CLOSE("p");
			DISCARD_TEXT(trueverb)
		}	
}

