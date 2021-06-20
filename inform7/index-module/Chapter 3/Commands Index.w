[CommandsIndex::] Commands Index.

To construct the index of command verbs.

@ =
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
			WRITE("<b>"); Kinds::Textual::write_as_HTML(OUT, ActionSemantics::kind_of_noun(an));
			WRITE("</b>");
		}

		HTML::next_html_column(OUT, 0);
		if (ActionSemantics::can_have_second(an) == FALSE) {
			WRITE("&mdash;");
		} else {
			if (ActionSemantics::second_access(an) == REQUIRES_ACCESS) WRITE("<i>touchable</i> ");
			if (ActionSemantics::second_access(an) == REQUIRES_POSSESSION) WRITE("<i>carried</i> ");
			WRITE("<b>"); Kinds::Textual::write_as_HTML(OUT, ActionSemantics::kind_of_second(an));
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
