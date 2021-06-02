[IXTables::] Tables Element.

To index tables.

@h Indexing.
Tables inside extensions are often used just for the storage needed to manage
back-of-house algorithms, so to speak, and they aren't intended for the end
user to poke around with; that's certainly true of the tables in the Standard
Rules, which of course are always present. So these are hidden by default.

=
void IXTables::render(OUTPUT_STREAM) {
	HTML_OPEN("p");
	int m = IXTables::index_tables_in(OUT, NULL, 0);
	HTML_CLOSE("p");
	HTML_OPEN("p");
	Index::extra_link(OUT, 2);
	if (m > 0) WRITE("Show tables inside extensions too");
	else WRITE("Show tables inside extensions (there are none in the main text)");
	HTML_CLOSE("p");
	Index::extra_div_open(OUT, 2, 1, "e0e0e0");
	inform_extension *E; int efc = 0;
	LOOP_OVER(E, inform_extension) IXTables::index_tables_in(OUT, E, efc++);
	Index::extra_div_close(OUT, "e0e0e0");
}

@ This tabulates tables within a given extension, returning the number listed,
and does nothing at all if that number is 0.

=
int IXTables::index_tables_in(OUTPUT_STREAM, inform_extension *E, int efc) {
	int tc = 0; table *t;
	LOOP_OVER(t, table) if (IXTables::table_within(t, E)) tc++;
	if (tc > 0) {
		if (E) {
			HTML_OPEN("p");
			WRITE("<i>%S</i>", E->as_copy->edition->work->title);
			HTML_CLOSE("p");
		}
		HTML::begin_plain_html_table(OUT);
		LOOP_OVER(t, table)
			if (IXTables::table_within(t, E))
				@<Index this table@>;
		HTML::end_html_table(OUT);
	}
	return tc;
}

@ The following probably ought to use a multiplication sign rather than a
Helvetica-style lower case "x", but life is full of compromises.

@<Index this table@> =
	HTML::first_html_column_spaced(OUT, 0);
	WRITE("<b>%+W</b>", Node::get_text(t->headline_fragment));
	table_contribution *tc; int ntc = 0;
	for (tc = t->table_created_at; tc; tc = tc->next) {
		if (ntc++ > 0) WRITE(" +");
		Index::link(OUT, Wordings::first_wn(Node::get_text(tc->source_table)));
	}
	HTML::next_html_column_spaced(OUT, 0);
	int rc = Tables::get_no_rows(t);
	WRITE("<i>");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (t->first_column_by_definition) {
		WRITE("%d definition%s", rc,
			(rc == 1)?"":"s");
	} else {
		WRITE("%d column%s x %d row%s",
			t->no_columns, (t->no_columns == 1)?"":"s",
			rc, (rc == 1)?"":"s");
	}
	if (t->blank_rows > 0) {
		WRITE(" (%d blank", t->blank_rows);
		if (Wordings::nonempty(t->blank_rows_for_each_text))
			WRITE(", one for each %+W", t->blank_rows_for_each_text);
		WRITE(")");
	}
	HTML_CLOSE("span");
	WRITE("</i>");
	HTML::end_html_row(OUT);
	int col;
	for (col = 0; col < t->no_columns; col++) {
		HTML::first_html_column(OUT, 0);
		WRITE("&nbsp;&nbsp;col %d:&nbsp;&nbsp;", col+1);
		wording CW = Nouns::nominative_singular(t->columns[col].column_identity->name);
		if ((t->first_column_by_definition) && (col == 0)) {
			parse_node *PN = t->where_used_to_define;
			WRITE("%+W", Node::get_text(PN));
			Index::link(OUT, Wordings::first_wn(Node::get_text(PN)));
		} else {
			if (t->first_column_by_definition) WRITE("<i>sets</i> ");
			WRITE("%+W&nbsp;", CW);
			TEMPORARY_TEXT(TEMP)
			WRITE_TO(TEMP, "%+W", CW);
			if (t->first_column_by_definition == FALSE) WRITE_TO(TEMP, " entry");
			PasteButtons::paste_text(OUT, TEMP);
			DISCARD_TEXT(TEMP)
		}
		HTML::next_html_column(OUT, 0);
		if ((t->first_column_by_definition) && (col == 0)) {
			parse_node *cell;
			int row;
			for (row = 1, cell = t->columns[0].entries->down; cell; cell = cell->next, row++) {
				if (row > 1) WRITE(", ");
				WRITE("%+W", Node::get_text(cell));
				Index::link(OUT, Wordings::first_wn(Node::get_text(cell)));
			}
		} else if (t->first_column_by_definition) {
			Kinds::Textual::write(OUT,
				Tables::Columns::get_kind(
					t->columns[col].column_identity));
			WRITE(" property");
		} else {
			WRITE("of ");
			Kinds::Textual::write_plural(OUT,
				Tables::Columns::get_kind(
					t->columns[col].column_identity));
		}
		HTML::end_html_row(OUT);
	}

@ The following laboriously tests whether a table is defined within a
given extension:

=
int IXTables::table_within(table *t, inform_extension *E) {
	if (t->amendment_of) return FALSE;
	heading *at_heading =
		Headings::of_wording(Node::get_text(t->table_created_at->source_table));
	inform_extension *at_E = Headings::get_extension_containing(at_heading);
	if (E == at_E) return TRUE;
	return FALSE;
}
