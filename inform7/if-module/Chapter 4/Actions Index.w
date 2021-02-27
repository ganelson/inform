[PL::Actions::Index::] Actions Index.

To construct the Actions index page.

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
	struct grammar_verb *gv_indexed; /* ...leading to... */
	struct command_index_entry *next_alphabetically; /* next in linked list */
	CLASS_DEFINITION
} command_index_entry;

command_index_entry *sorted_command_index = NULL; /* in alphabetical order of |text| */

@ =
void PL::Actions::Index::index_meta_verb(char *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%s", t);
	vie->nature = OUT_OF_WORLD_COMMAND;
	vie->gv_indexed = NULL;
	vie->next_alphabetically = NULL;
}

void PL::Actions::Index::test_verb(text_stream *t) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::duplicate(t);
	vie->nature = TESTING_COMMAND;
	vie->gv_indexed = NULL;
	vie->next_alphabetically = NULL;
}

void PL::Actions::Index::verb_definition(OUTPUT_STREAM, wchar_t *p, text_stream *trueverb, wording W) {
	int i = 1;
	if ((p[0] == 0) || (p[1] == 0)) return;
	if (Str::len(trueverb) > 0) {
		if (Str::eq_wide_string(trueverb, L"0") == FALSE) {
			WRITE("%S", trueverb);
			if (Wordings::nonempty(W))
				PL::Parsing::Verbs::index_command_aliases(OUT,
					PL::Parsing::Verbs::find_command(W));
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

command_index_entry *PL::Actions::Index::vie_new_from(OUTPUT_STREAM, wchar_t *headword, grammar_verb *gv, int nature) {
	command_index_entry *vie;
	vie = CREATE(command_index_entry);
	vie->command_headword = Str::new();
	WRITE_TO(vie->command_headword, "%w", headword);
	vie->nature = nature;
	vie->gv_indexed = gv;
	vie->next_alphabetically = NULL;
	return vie;
}

void PL::Actions::Index::commands(OUTPUT_STREAM) {
	command_index_entry *vie, *vie2, *last_vie2, *list_start = NULL;
	grammar_verb *gv;
	int head_letter;

	LOOP_OVER(gv, grammar_verb)
		PL::Parsing::Verbs::make_command_index_entries(OUT, gv);

	vie = CREATE(command_index_entry);
	vie->command_headword = I"0";
	vie->nature = BARE_DIRECTION_COMMAND;
	vie->gv_indexed = NULL;
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
		grammar_verb *gv;
		if (Str::get_first_char(vie->command_headword) != head_letter) {
			if (head_letter) HTML_TAG("br");
			head_letter = Str::get_first_char(vie->command_headword);
		}
		gv = vie->gv_indexed;
		switch (vie->nature) {
			case NORMAL_COMMAND:
				PL::Parsing::Verbs::index_normal(OUT, gv, vie->command_headword);
				break;
			case ALIAS_COMMAND:
				PL::Parsing::Verbs::index_alias(OUT, gv, vie->command_headword);
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

void PL::Actions::Index::alphabetical(OUTPUT_STREAM) {
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
		if (an->semantics.out_of_world) HTML::begin_colour(OUT, I"800000");
		WRITE("%W", an->present_name);
		if (an->semantics.out_of_world) HTML::end_colour(OUT);
		Index::detail_link(OUT, "A", an->allocation_id, TRUE);

		if (an->semantics.requires_light) WRITE(" <i>requires light</i>");

		HTML::next_html_column(OUT, 0);
		if (an->semantics.max_parameters < 1) {
			WRITE("&mdash;");
		} else {
			if (an->semantics.noun_access == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (an->semantics.noun_access == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>"); Kinds::Index::index_kind(OUT, an->semantics.noun_kind, FALSE, FALSE);
			WRITE("</b>");
		}

		HTML::next_html_column(OUT, 0);
		if (an->semantics.max_parameters < 2) {
			WRITE("&mdash;");
		} else {
			if (an->semantics.second_access == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (an->semantics.second_access == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>"); Kinds::Index::index_kind(OUT, an->semantics.second_kind, FALSE, FALSE);
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
	qsort(sorted, (size_t) nr, sizeof(action_name *), PL::Actions::Index::compare_action_names);

@ The following means the table is sorted in alphabetical order of action name.

=
int PL::Actions::Index::compare_action_names(const void *ent1, const void *ent2) {
	const action_name *an1 = *((const action_name **) ent1);
	const action_name *an2 = *((const action_name **) ent2);
	return Wordings::strcmp(an1->present_name, an2->present_name);
}

@ =
void PL::Actions::Index::page(OUTPUT_STREAM) {
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

void PL::Actions::Index::detail_pages(void) {
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

void PL::Actions::Index::tokens(OUTPUT_STREAM) {
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
	PL::Parsing::Verbs::index_tokens(OUT);
}

void PL::Actions::Index::index_for_extension(OUTPUT_STREAM, source_file *sf, inform_extension *E) {
	action_name *acn;
	int kc = 0;
	LOOP_OVER(acn, action_name)
		if (Lexer::file_of_origin(Wordings::first_wn(acn->present_name)) == E->read_into_file)
			kc = IndexExtensions::document_headword(OUT, kc, E, "Actions", I"action",
				acn->present_name);
	if (kc != 0) HTML_CLOSE("p");
}
