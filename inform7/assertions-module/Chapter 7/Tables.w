[Tables::] Tables.

To manage and compile tables, which are two-dimensional arrays with
associative look-up facilities provided at run-time.

@ This is how a table is stored. Note that the limit on columns per table
must not rise to 100 or beyond because that would break the system of table
column ID numbers: see //runtime: Tables//.

@d MAX_COLUMNS_PER_TABLE 99

=
typedef struct table {
	struct wording table_no_text; /* the table number (if any) */
	struct wording table_name_text; /* the table name (if any) */
	struct table_contribution *table_created_at; /* where created in source */
	struct parse_node *headline_fragment; /* a pseudo-sentence formed by the heading line */
	int blank_rows; /* number of entirely blank rows to be appended (may be 0) */
	struct wording blank_rows_for_each_text; /* add one blank for each instance */
	struct wording blank_rows_text; /* text of blank rows specification */
	int fill_in_blanks; /* if set, fill any blank entries with default values */
	int first_column_by_definition; /* if set, first column defines new value names */
	struct kind *kind_defined_in_this_table; /* ...of this kind */
	int contains_property_values_at_run_time;
	struct parse_node *where_used_to_define;
	int preserve_row_order_at_run_time; /* if set, don't sort this table */
	struct table *amendment_of; /* if amendment of earlier table */
	int has_been_amended; /* if there exists an amendment of this */
	int approximate_array_space_needed; /* at run-time, in words */
	int disable_block_constant_correction; /* if set, don't translate block constant entries */

	int no_columns; /* must be at least 1 */
	struct table_column_usage columns[MAX_COLUMNS_PER_TABLE];

	struct table_compilation_data compilation_data;
	CLASS_DEFINITION
} table;

@ For indexing purposes only:

=
typedef struct table_contribution {
	struct parse_node *source_table;
	struct table_contribution *next;
} table_contribution;

@ These are convenient during parsing.

= (early code)
parse_node *table_cell_node = NULL;
int table_cell_row = -1;
int table_cell_col = -1;
table *table_being_examined = NULL;

@h Traversing for tables.
Tables of data are created in two passes through the source text:
the first finds their names and registers them with the parser, while
the second (much later) works out their columns and contents. At some
point we also try to find ambiguity problems which might bite us later on.

Here is that later one. By this point all of the constant values in Inform
exist, and so do all of the kinds, so we can now make sense of the kinds
of the columns and of what's in them; and we can check that this is all
consistent. This is called "stocking", and it comes in three phases:
see below.

=
void Tables::traverse_to_stock(void) {
	for (int phase = 1; phase <= 3; phase++) {
		table *t;
		LOOP_OVER(t, table) {
			current_sentence = t->table_created_at->source_table;
			Tables::stock_table(t, phase);
		}
	}
}

@ Last and least: a traverse existing just to issue a problem message in a
case which Inform can often cope with, but which the experience of users
suggests is never a good idea.

=
void Tables::check_tables_for_kind_clashes(void) {
	table *t;
	LOOP_OVER(t, table) {
		if ((Wordings::nonempty(t->table_name_text)) &&
			(<k-kind-articled>(t->table_name_text)) &&
			(Kinds::Behaviour::is_subkind_of_object(<<rp>>))) {
			Problems::quote_table(1, t);
			Problems::quote_wording(2, t->table_name_text);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_TableCoincidesWithKind));
			Problems::issue_problem_segment(
				"The name %1 will have to be disallowed because '%2' is also the "
				"name of a kind, or of the plural of a kind. (For instance, writing "
				"'Table of Rooms' is disallowed - it could lead to great confusion.)");
			Problems::issue_problem_end();
		}
	}
}

@h Table basics.
The following makes a blank structure for a table, but it isn't valid until
some of these fields have been properly filled in.

=
table *Tables::new_table_structure(parse_node *PN, wording W) {
	table *t = CREATE(table);
	t->table_no_text = EMPTY_WORDING;
	t->table_name_text = EMPTY_WORDING;
	t->headline_fragment = Diagrams::new_UNPARSED_NOUN(W);
	t->blank_rows = 0;
	t->blank_rows_text = EMPTY_WORDING;
	t->blank_rows_for_each_text = EMPTY_WORDING;
	t->fill_in_blanks = FALSE;
	t->first_column_by_definition = FALSE;
	t->kind_defined_in_this_table = NULL;
	t->where_used_to_define = NULL;
	t->contains_property_values_at_run_time = FALSE;
	t->preserve_row_order_at_run_time = FALSE;
	t->amendment_of = NULL;
	t->has_been_amended = FALSE;
	t->approximate_array_space_needed = 0;
	t->disable_block_constant_correction = FALSE;
	t->no_columns = 0;
	t->table_created_at = NULL;
	t->compilation_data = RTTables::new_table(PN, t, W);
	Tables::add_table_contribution(t, current_sentence);
	return t;
}

@ A little linked list of chunks of source contributing to the table:

=
void Tables::add_table_contribution(table *t, parse_node *src) {
	table_contribution *tc = CREATE(table_contribution);
	tc->source_table = src;
	tc->next = NULL;
	table_contribution *ltc = t->table_created_at;
	while ((ltc) && (ltc->next)) ltc = ltc->next;
	if (ltc) ltc->next = tc; else t->table_created_at = tc;
}

@ Logging:

=
void Tables::log(table *t) {
	LOG("{%n}", RTTables::identifier(t));
}

@ Dimensions:

=
int Tables::get_no_columns(table *t) {
	return t->no_columns;
}

int Tables::get_no_rows(table *t) {
	parse_node *PN; int c=0;
	for (PN=t->columns[0].entries->down; PN; PN=PN->next) c++;
	c += t->blank_rows;
	return c;
}

parse_node *Tables::cells_in_ith_column(table *t, int i) {
	if (t == NULL) internal_error("no such table");
	if ((i<0) || (i>=t->no_columns)) internal_error("column out of range");
	return t->columns[i].entries->down;
}

@ Miscellaneous services:

=
int Tables::expand_block_constants(table *t) {
	if (t->amendment_of) return FALSE;
	if (t->disable_block_constant_correction) return FALSE;
	return TRUE;
}

kind *Tables::kind_of_ith_column(table *t, int i) {
	if ((i<0) || (i>=t->no_columns))
		internal_error("tcdt for column out of range");
	return Tables::Columns::get_kind(t->columns[i].column_identity);
}

@ Oddball forms of naming:

=
parse_node *Tables::get_headline(table *t) {
	return t->headline_fragment;
}

@ The author can demand with a "translates as" sentence that a given
table should have an identifier given to it which is accessible to Inter:

=
void Tables::translates(wording W, parse_node *p2) {
	if (<s-constant-value>(W)) {
		table *T = Rvalues::to_table(<<rp>>);
		if (T) {
			RTTables::translate(T, Node::get_text(p2));
			return;
		}
	}
	LOG("Tried %W\n", W);
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_TranslatesNonTable),
		"this is not the name of a table",
		"so cannot be translated.");
}

@h Table creation.
Tables can be new, when they appear in the source, or can be related to
already-existing ones with the same name:

@d TABLE_IS_NEW 1
@d TABLE_IS_CONTINUED 2
@d TABLE_IS_AMENDED 3
@d TABLE_IS_REPLACED 4

@ Their headers can have three forms:

@d TABLE_HAS_ONLY_NUMBER 1
@d TABLE_HAS_ONLY_NAME 2
@d TABLE_HAS_NUMBER_AND_NAME 3

@ The source text declaration of tables is not easy to parse. Tabs are
significantly different from spaces or new-lines, for instance -- so the
ordinary rules about white space are suspended. Tabs divide entries in a row;
new-lines divide rows in a paragraph; and the table is terminated by a
paragraph break.

If a table is declared as

>> Table 12 - Chemical Elements

then it can be referred to elsewhere in the source either as "Table 12"
or as "Table of Chemical Elements", so both excerpts are registered
as meaningful. But it is legal to declare a table with only one of the
two forms in any case.

=
<table-header> ::=
	<table-new-name> ( continued ) |  ==> { TABLE_IS_CONTINUED, -, <<nameforms>> = R[1] }
	<table-new-name> ( amended ) |    ==> { TABLE_IS_AMENDED, -, <<nameforms>> = R[1] }
	<table-new-name> ( replaced ) |   ==> { TABLE_IS_REPLACED, -, <<nameforms>> = R[1] }
	<table-new-name>                  ==> { TABLE_IS_NEW, -, <<nameforms>> = R[1] }

<table-new-name> ::=
	table ... - ... |                 ==> { TABLE_HAS_NUMBER_AND_NAME, - }
	table ### |                       ==> { TABLE_HAS_ONLY_NUMBER, - }
	table of ... |                    ==> { TABLE_HAS_ONLY_NAME, - }
	table ...                         ==> @<Issue PM_TableMisnamed problem@>

@<Issue PM_TableMisnamed problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TableMisnamed),
		"this isn't allowed as the name of a Table",
		"since a table is required either to have a number, or to be a table 'of' "
		"something (or both). For example: 'Table 5', 'Table of Blue Meanies', and "
		"'Table 2 - Submarine Hues' are all allowed, but 'Table concerning "
		"Pepperland' is not.");
	==> { TABLE_HAS_ONLY_NAME, - };

@ The following is then used to register table names as constants. The idea
is that "Table 12 - Chemical Elements" will be registered both as Table 12
and as Table of Chemical Elements.

=
<table-names-construction> ::=
	table ... |
	table of ...

@ Optionally, tables can have a footer line specifying additional entirely
blank rows. In (b), the |...| is eventually required to be a kind, but this
happens later on, since the bare bones of tables are parsed very early in
Inform's run, when kinds haven't yet been created.

=
<table-footer> ::=
	*** with <cardinal-number> blank row/rows |  ==> { R[1], -, <<each>> = FALSE }
	*** with ... blank row/rows |                ==> { 0, -, <<each>> = NOT_APPLICABLE }
	*** with blank row/rows for each/every ...   ==> { 0, -, <<each>> = TRUE }

@ So, here goes. We first identify the top line of the table declaration
(the "headline"), then set the current sentence to that, even though in
parse tree terms it's only a fragment of a sentence: this makes problem
messages about the headline much more readable. We extract the table's
name, number and connection to other tables, and count its rows. In some
cases, for example where we are continuing an existing table, we use the
new table structure only temporarily: we transfer its rows to the existing
table and then destroy the temporary one made here.

=
void Tables::create_table(parse_node *PN) {
	wording W = Node::get_text(PN);
	int connection = TABLE_IS_NEW; /* i.e., no connection with existing tables */

	wording HW = Wordings::up_to(W, Wordings::last_word_of_formatted_text(W, FALSE));
	if (Wordings::length(HW) == 1) @<Reject this lexically malformed table declaration@>;

	table *t = Tables::new_table_structure(PN, HW);
	current_sentence = t->headline_fragment;

	@<Parse the table's header for a name and/or number, and connection to other tables@>;
	@<Require the table name not to tread on some other value@>;

	table *existing_table_with_same_name = NULL;
	@<Find the first existing table with the same name, if any@>;
	if (connection != TABLE_IS_NEW) @<Require the previous table to exist@>
	else @<Require the previous table not to exist@>;

	if (connection == TABLE_IS_NEW) {
		@<Register the names of the new table@>;
		LOGIF(TABLES, "Created: $B\n", t);
	}

	@<Parse the table's footer for a number of blank rows@>;
	int row_count = 0;
	@<Count out the rows and columns in the new table@>;

	if (connection != TABLE_IS_NEW)
		@<Act on the connection, possibly destroying the temporary table just made@>;
}

@ Changes to the lexer mean that this shouldn't happen, but just in case:

@<Reject this lexically malformed table declaration@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
		"this table does not strictly speaking start a paragraph",
		"and I'm afraid we need to speak strictly here. Even a comment coming before "
		"the start of the table is too much.");
	return;

@<Parse the table's header for a name and/or number, and connection to other tables@> =
	LOGIF(TABLES, "Parsing table headline %W\n", HW);
	<table-header>(HW);
	connection = <<r>>;

	switch (<<nameforms>>) {
		case TABLE_HAS_ONLY_NUMBER:
			t->table_no_text = GET_RW(<table-new-name>, 1);
			break;
		case TABLE_HAS_ONLY_NAME:
			t->table_name_text = GET_RW(<table-new-name>, 1);
			break;
		case TABLE_HAS_NUMBER_AND_NAME:
			t->table_no_text = GET_RW(<table-new-name>, 1);
			t->table_name_text = GET_RW(<table-new-name>, 2);
			break;
	}
	
	if ((Wordings::length(t->table_no_text) > 24) ||
		(Wordings::length(t->table_name_text) > 24)) {
		if (Wordings::length(t->table_no_text) > 24)
			Problems::quote_wording_as_source(1, t->table_no_text);
		else 
			Problems::quote_wording_as_source(1, t->table_name_text);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableNameTooLong));
		Problems::issue_problem_segment(
			"This table has been called %1, but that's just too much text. Tables "
			"really don't need names longer than 20 words.");
		Problems::issue_problem_end();
		DESTROY(t, table);
		return;
	}

@ Practical experience showed that the following restriction was wise:

@<Require the table name not to tread on some other value@> =
	if (<s-type-expression-or-value>(t->table_name_text)) {
		Problems::quote_wording_as_source(1, t->table_name_text);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableNameAmbiguous));
		Problems::issue_problem_segment(
			"The table name %1 will have to be disallowed as it is text which "
			"already has a meaning to Inform. For instance, creating the 'Table "
			"of Seven' would be disallowed because of the possible confusion "
			"with the number 'seven'.");
		Problems::issue_problem_end();
		DESTROY(t, table);
		return;
	}

@ It's not as simple as it seems to decide when a new table headline refers
back to a table which already exists -- there are several ways we could play
this. What we say is that if the new headline gives both name and number,
then both must match; if it gives name only, that must match; if it gives
number only, that must. Suppose that "Table 2 - Trees" already exists. Then:

(a) if "Table 2 - Shrubs" or "Table 3 - Trees" comes along, there's no match;
(b) if "Table of Trees" comes along, that does match;
(c) if "Table 2" comes along, so does that.

@d TABLE_NAMES_MATCH(t1, t2)
	((t1 != t2) && (Wordings::nonempty(t1->table_name_text)) &&
		(Wordings::nonempty(t2->table_name_text)) &&
		(Wordings::match(t2->table_name_text, t1->table_name_text)))
@d TABLE_NUMBERS_MATCH(t1, t2)
	((t1 != t2) && (Wordings::nonempty(t1->table_no_text)) &&
		(Wordings::nonempty(t2->table_no_text)) &&
		(Wordings::match(t2->table_no_text, t1->table_no_text)))

@<Find the first existing table with the same name, if any@> =
	if ((Wordings::nonempty(t->table_name_text)) &&
		(Wordings::nonempty(t->table_no_text))) {
		table *t2;
		LOOP_OVER(t2, table)
			if ((TABLE_NAMES_MATCH(t2, t)) && (TABLE_NUMBERS_MATCH(t2, t)))
				existing_table_with_same_name = t2;
	} else if (Wordings::nonempty(t->table_name_text)) {
		table *t2;
		LOOP_OVER(t2, table)
			if (TABLE_NAMES_MATCH(t2, t)) {
				if ((Wordings::nonempty(t->table_no_text)) &&
					(!(TABLE_NUMBERS_MATCH(t2, t))))
					continue;
				existing_table_with_same_name = t2;
			}
	} else if (Wordings::nonempty(t->table_no_text)) {
		table *t2;
		LOOP_OVER(t2, table)
			if (TABLE_NUMBERS_MATCH(t2, t))
				existing_table_with_same_name = t2;
	}

@<Require the previous table to exist@> =
	if (existing_table_with_same_name == NULL) {
		Problems::quote_table(1, t);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableNotContinuation));
		Problems::issue_problem_segment(
			"It looks as if %1 is meant to be related to an existing table, "
			"but I can't find one if it is. %P"
			"Perhaps you've put the new part before the original? The original "
			"has to be earlier in the source text.");
		Problems::issue_problem_end();
		DESTROY(t, table);
		return;
	}

@<Require the previous table not to exist@> =
	if (existing_table_with_same_name) {
		Problems::quote_table(1, t);
		Problems::quote_table(2, existing_table_with_same_name);
		Problems::quote_wording(3, HW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableNameDuplicate));
		Problems::issue_problem_segment(
			"I can't create %1 because its name overlaps with one that already "
			"exists: %2. %P"
			"It's possible to continue the existing one, if you just want to "
			"add more rows, by writing '%3 (continued)' here.");
		Problems::issue_problem_end();
		DESTROY(t, table);
		return;
	}

@<Register the names of the new table@> =
	if (Wordings::nonempty(t->table_no_text)) {
		LOGIF(TABLES, "Registering table by number: table %W\n", t->table_no_text);

		word_assemblage wa = PreformUtilities::merge(<table-names-construction>, 0,
			WordAssemblages::from_wording(t->table_no_text));
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			TABLE_MC, Rvalues::from_table(t), Task::language_of_syntax());
	}
	if (Wordings::nonempty(t->table_name_text)) {
		LOGIF(TABLES, "Registering table by name: table of %W\n", t->table_name_text);

		word_assemblage wa = PreformUtilities::merge(<table-names-construction>, 1,
				WordAssemblages::from_wording(t->table_name_text));
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			TABLE_MC, Rvalues::from_table(t), Task::language_of_syntax());
	}

@<Parse the table's footer for a number of blank rows@> =
	if (<table-footer>(W)) {
		W = GET_RW(<table-footer>, 1);
		switch (<<each>>) {
			case TRUE: t->blank_rows_for_each_text = GET_RW(<table-footer>, 2); break;
			case FALSE: t->blank_rows = <<r>>; break;
			case NOT_APPLICABLE: t->blank_rows = 1;
				t->blank_rows_text = GET_RW(<table-footer>, 2); break;
		}
	}

@ Here's where we start building. The table's representation in the parse
tree is currently very unhelpful: it's just one enormous sentence node with
all the words in, headings and cells merged together. Instead of using this
we hang a list of parse nodes, one for each cell, as children of the entries
node for each column.

@<Count out the rows and columns in the new table@> =
	int pos = Wordings::last_wn(HW)+1;
	while (pos <= Wordings::last_wn(W)) {
		int col_count = 0;
		int row_end = Wordings::last_word_of_formatted_text(Wordings::from(W, pos), FALSE);
		LOGIF(TABLES, "Row %d is %W\n", row_count, Wordings::new(pos, row_end));
		while (pos <= row_end) {
			int cell_end =
				Wordings::last_word_of_formatted_text(Wordings::new(pos, row_end), TRUE);
			LOGIF(TABLES, "Cell (%d, %d) is %W\n",
				row_count, col_count, Wordings::new(pos, cell_end));
			if (row_count == 0) @<This is a column-heading cell@>
			else @<This is a data cell@>;
			col_count++;
			pos = cell_end + 1;
		}
		@<Add implied blank data cells to fill out the row as needed@>;
		row_count++;
	}
	if ((row_count < 2) && (t->blank_rows == 0)) {
		StandardProblems::table_problem(_p_(PM_TableWithoutRows),
			t, NULL, PN, "%1 has no rows.");
		return;
	}

@ See "Table Columns" for the actual column creation: note that this makes
a node in the parse tree representing the column's use within this table.

@<This is a column-heading cell@> =
	current_sentence = PN;
	wording CW = Wordings::new(pos, cell_end);
	if (col_count == MAX_COLUMNS_PER_TABLE) {
		parse_node *overflow = Diagrams::new_UNPARSED_NOUN(CW);
		int limit = MAX_COLUMNS_PER_TABLE;
		Problems::quote_number(4, &limit);
		StandardProblems::table_problem(_p_(PM_TableTooManyColumns),
			t, NULL, overflow,
			"There are %4 columns in %1 already, and that's the absolute limit, "
			"so the column %3 can't be added.");
	}
	if (col_count < MAX_COLUMNS_PER_TABLE) {
		LOGIF(TABLES, "Creating col %d from '%W'\n", t->no_columns, CW);
		t->columns[t->no_columns] = Tables::Columns::add_to_table(CW, t);
		if (t->columns[t->no_columns].column_identity) /* i.e., no Problem occurred */
			t->no_columns++;
	}

@ Each data cell becomes a node, and is added to the list under its column.

@<This is a data cell@> =
	wording CW = Wordings::new(pos, cell_end);
	parse_node *cell = Diagrams::new_PROPER_NOUN(CW);
	if (col_count >= t->no_columns) {
		current_sentence = PN;
		Problems::quote_number(4, &(row_count));
		int given_col = col_count + 1; /* i.e., counting from 1 rather than 0 */
		Problems::quote_number(5, &(given_col));
		Problems::quote_number(6, &(t->no_columns));
		StandardProblems::table_problem(_p_(PM_TableRowFull),
			t, NULL, cell,
			"In row %4 of the table %1, the entry %3 won't fit, because its row "
			"is already full. (This entry would be in column %5 and the table has "
			"only %6.)");
	} else {
		Annotations::write_int(cell, table_cell_unspecified_ANNOT, FALSE);
		SyntaxTree::graft(Task::syntax_tree(), cell, t->columns[col_count].entries);
	}

@ If a row finishes early, we pad it out with blanks.

@<Add implied blank data cells to fill out the row as needed@> =
	while (col_count < t->no_columns) { /* which can only happen on data rows */
		parse_node *cell = Tables::empty_cell_node();
		Annotations::write_int(cell, table_cell_unspecified_ANNOT, TRUE);
		SyntaxTree::graft(Task::syntax_tree(), cell, t->columns[col_count].entries);
		col_count++;
	}

@ All parsing is finished now.

@<Act on the connection, possibly destroying the temporary table just made@> =
	table *old_t = existing_table_with_same_name;
	Tables::add_table_contribution(old_t, t->headline_fragment);
	int new_to_old[MAX_COLUMNS_PER_TABLE], old_to_new[MAX_COLUMNS_PER_TABLE];
	@<Build the column correspondence tables@>;
	switch (connection) {
		case TABLE_IS_CONTINUED: @<Make the new part a continuation of the existing table@>; break;
		case TABLE_IS_AMENDED: @<Make the new part an amendment of the existing table@>; break;
		case TABLE_IS_REPLACED: @<Make the new part a replacement of the existing table@>; break;
		default: internal_error("unknown form of table connection");
	}

@ We assume that columns in the new and old tables will be partial permutations
of each other: for example the old might have columns "fish", "mammals", "birds"
(index |j| running from 0 to 2) and the new "mammals", "reptiles", "fish",
"fungi" (index |i| running from 0 to 3). We're going to store both the permutation
and its inverse, with the index |-1| meaning that the column doesn't appear in
the other table at all. The result will be:
= (text)
	old_to_new: 2, 0, -1
	new_to_old: 1, -1, 0, -1
=

@<Build the column correspondence tables@> =
	int i, j;
	for (j=0; j<old_t->no_columns; j++) old_to_new[j] = -1;
	for (i=0; i<t->no_columns; i++) new_to_old[i] = -1;
	for (i=0; i<t->no_columns; i++)
		for (j=0; j<old_t->no_columns; j++)
			if (t->columns[i].column_identity == old_t->columns[j].column_identity) {
				new_to_old[i] = j; old_to_new[j] = i;
			}
	LOGIF(TABLES, "Column correspondence table:\n  old->new: ");
	for (j=0; j<old_t->no_columns; j++)
		LOGIF(TABLES, "%d (%W) ", old_to_new[j],
			Nouns::nominative_singular(old_t->columns[j].column_identity->name));
	LOGIF(TABLES, "\n  new->old: ");
	for (i=0; i<t->no_columns; i++)
		LOGIF(TABLES, "%d (%W) ", new_to_old[i],
			Nouns::nominative_singular(t->columns[i].column_identity->name));
	LOGIF(TABLES, "\n");

@ We can carry out the continuation immediately, since it just means splicing
the new table's rows onto the ends of the old table's columns.

@<Make the new part a continuation of the existing table@> =
	@<Require that every column of the new table is also found in the old one@>;
	@<Transfer blank rows of the new table to the old one@>;
	if (row_count >= 2) {
		int j;
		for (j=0; j<old_t->no_columns; j++)
			if (old_to_new[j] >= 0) {
				SyntaxTree::graft(Task::syntax_tree(),
					t->columns[old_to_new[j]].entries->down,
					old_t->columns[j].entries);
			} else {
				int i;
				for (i=1; i<row_count; i++) { /* from 1 to omit the column headings */
					parse_node *blank = Tables::empty_cell_node();
					Annotations::write_int(blank, table_cell_unspecified_ANNOT, TRUE);
					SyntaxTree::graft(Task::syntax_tree(), blank, old_t->columns[j].entries);
				}
			}
	}
	DESTROY(t, table);

@ It's a little awkward to work out what the policy is if the original table
wants a row for each man, and the continuation wants a row for each woman.

@<Transfer blank rows of the new table to the old one@> =
	old_t->blank_rows += t->blank_rows;
	if (Wordings::nonempty(t->blank_rows_for_each_text)) {
		if (Wordings::nonempty(old_t->blank_rows_for_each_text)) {
			current_sentence = t->table_created_at->source_table;
			Problems::quote_table(1, t);
			Problems::quote_table(2, old_t);
			Problems::quote_wording(3, old_t->blank_rows_for_each_text);
			Problems::quote_wording(4, t->blank_rows_for_each_text);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_TableContinuationContradicts));
			Problems::issue_problem_segment(
				"The table %1 says that it should have a blank row for each "
				"%4, but the original %2 already says it has a blank for each "
				"%3. It can only be specified once.");
			Problems::issue_problem_end();
		}
		old_t->blank_rows_for_each_text = t->blank_rows_for_each_text;
	}

@ And similarly for replacements...

@<Make the new part a replacement of the existing table@> =
	@<Require that every column of the old table is also found in the new one@>;
	@<Copy blank rows of the new table to the old one@>;
	int j;
	for (j=0; j<old_t->no_columns; j++)
		if (old_to_new[j] >= 0) /* and if this isn't true, we've issued a Problem already */
			old_t->columns[j].entries->down
				= t->columns[old_to_new[j]].entries->down;
	int i;
	for (i=0; i<t->no_columns; i++)
		if (new_to_old[i] == -1)
			old_t->columns[old_t->no_columns++] = t->columns[i]; /* old table must have room */
	DESTROY(t, table);

@ ...but this is easier:

@<Copy blank rows of the new table to the old one@> =
	old_t->blank_rows = t->blank_rows;
	old_t->blank_rows_text = t->blank_rows_text;
	old_t->blank_rows_for_each_text = t->blank_rows_for_each_text;

@ Amendments can't be done yet, because they depend on recognising values,
and it's far too early in Inform's run to recognise constants. So we must
postpone the work until later: note that we don't destroy the new table
structure in this case.

@<Make the new part an amendment of the existing table@> =
	@<Require that the old and new tables have exactly matching columns@>;
	t->amendment_of = old_t;
	old_t->has_been_amended = TRUE;
	LOGIF(TABLES, "Amendment table created pro tem\n");

@ Here each new column must appear once in the old table, but the new
table doesn't have to cover everything in the old table. (Blanks are
used in continuation rows for columns not mentioned.)

@<Require that every column of the new table is also found in the old one@> =
	int i, missing = 0;
	for (i=0; i<t->no_columns; i++)
		if (new_to_old[i] == -1)
			missing++;
	if (missing > 0) {
		for (i=0; i<t->no_columns; i++)
			LOG("nto[%d] = %d, otn[%d] = %d\n", i, new_to_old[i], i, old_to_new[i]);
		current_sentence = t->table_created_at->source_table;
		Problems::quote_table(1, t);
		Problems::quote_table(2, old_t);
		if (missing == 1) Problems::quote_text(3, "a column");
		else Problems::quote_text(3, "columns");
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableContinuationAddsCols));
		Problems::issue_problem_segment(
			"The table %1 won't work as a continuation, because it contains "
			"%3 not found in the original %2.");
		Problems::issue_problem_end();
		@<Display the old and new table column names@>;
		DESTROY(t, table);
		return;
	}

@ Here each old column must appear once in the new table, but the new
table is allowed to have extra columns. (This means the new table can
be "wider" than the old one.)

@<Require that every column of the old table is also found in the new one@> =
	int j, missing = 0;
	for (j=0; j<old_t->no_columns; j++)
		if (old_to_new[j] == -1)
			missing++;
	if (missing > 0) {
		current_sentence = t->table_created_at->source_table;
		Problems::quote_table(1, t);
		Problems::quote_table(2, old_t);
		if (missing == 1) Problems::quote_text(3, "a column");
		else Problems::quote_text(3, "columns");
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableReplacementMissesCols));
		Problems::issue_problem_segment(
			"The table %1 won't work as a replacement, because it's missing "
			"%3 found in the original %2.");
		Problems::issue_problem_end();
		@<Display the old and new table column names@>;
		DESTROY(t, table);
		return;
	}

@ We require this to be the identity permutation, i.e., exactly the same
columns and in the same order.

@<Require that the old and new tables have exactly matching columns@> =
	int mismatch = FALSE;
	if (t->no_columns != old_t->no_columns) mismatch = TRUE;
	int j;
	for (j=0; j<old_t->no_columns; j++)
		if (old_to_new[j] != j)
			mismatch = TRUE;
	if (mismatch) {
		current_sentence = t->table_created_at->source_table;
		Problems::quote_table(1, t);
		Problems::quote_table(2, old_t);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableAmendmentMisfit));
		Problems::issue_problem_segment(
			"Columns in %1 do not exactly match the original %2. I can only "
			"make changes to rows in an existing table if the amended versions "
			"have the same columns and in the same order.");
		Problems::issue_problem_end();
		@<Display the old and new table column names@>;
		DESTROY(t, table);
		return;
	}

@<Display the old and new table column names@> =
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	Problems::issue_problem_segment("The old table has columns: "); {
		TEMPORARY_TEXT(TEMP)
		int j;
		for (j=0; j<old_t->no_columns; j++) {
			if (j > 0) WRITE_TO(TEMP, ", ");
			WRITE_TO(TEMP, "%+W",
				Nouns::nominative_singular(old_t->columns[j].column_identity->name));
		}
		WRITE_TO(TEMP, ". ");
		Problems::issue_problem_segment_from_stream(TEMP);
		DISCARD_TEXT(TEMP)
	}
	Problems::issue_problem_end();
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	Problems::issue_problem_segment("The new table has columns: "); {
		TEMPORARY_TEXT(TEMP)
		int i;
		for (i=0; i<t->no_columns; i++) {
			if (i > 0) WRITE_TO(TEMP, ", ");
			WRITE_TO(TEMP, "%+W",
				Nouns::nominative_singular(t->columns[i].column_identity->name));
		}
		WRITE_TO(TEMP, ".");
		Problems::issue_problem_segment_from_stream(TEMP);
		DISCARD_TEXT(TEMP)
	}
	Problems::issue_problem_end();

@ =
parse_node *Tables::empty_cell_node(void) {
	return Diagrams::new_PROPER_NOUN(EMPTY_WORDING);
}

@h Table stocking.
See also the corresponding code in "Table Sections".

Note that the first column plays a special role in tables used to define new
constants, because it holds the names of things which don't exist yet -- the
things to be defined. So we exempt it from the checking below.

=
void Tables::stock_table(table *t, int phase) {
	LOGIF(TABLES, "Stocking $B (%d cols): phase %d\n", t, t->no_columns, phase);
	table_being_examined = t;
	int i = 0;
	if (t->first_column_by_definition) i = 1;
	for (; i<t->no_columns; i++) {
		table_column_usage *tcu = &(t->columns[i]);
		switch (phase) {
			case 1:
				tcu->kind_name_entries = 0;
				tcu->actual_constant_entries = 0;
				tcu->observed_constant_cell = NULL;
				Tables::Columns::check_explicit_headings(t, i, tcu);
				break;
			case 2: {
				int c;
				parse_node *PN;
				for (PN = t->columns[i].entries->down, c = 1; PN; PN = PN->next, c++)
					if (Wordings::nonempty(Node::get_text(PN)))
						Tables::stock_table_cell(t, PN, c, i);
				break;
			}
			case 3: Tables::Columns::approve_kind(t, i, tcu);
				break;
		}
	}
}

@ All of that is delegated to "Table Columns" except for the |Tables::stock_table_cell|
routine, which comes next. It will parse the text of the entry in a cell
and act accordingly; the grammar returns one of the following:

@d BLANK_TABLE_ENTRY 1
@d SPEC_TABLE_ENTRY 2
@d ACTION_TABLE_ENTRY 3
@d TOPIC_TABLE_ENTRY 4
@d INSTANCE_TABLE_ENTRY 5
@d KIND_TABLE_ENTRY 6
@d NAMED_CONSTANT_ENTRY 7
@d PROBLEMATIC_TABLE_ENTRY -1

@ Every cell of every table is required to match the following. Perhaps
unexpectedly, the syntax doesn't require each entry to be a valid Inform
constant; entries can also be blanks, or names of kinds (thus specifying the
kind of the table but not the contents), and there are special arrangements
for grammar to be understood (in "topic" columns) and for actions written as
constants.

Despite appearances, fully general type expressions (such as "open doors", or
"number of women") can't legally appear in table cells. The contents have
to be constants; the grammar lets more general text through only to let
us issue more contextual problem messages.

=
<table-cell> ::=
	<table-cell-blank> |       ==> { BLANK_TABLE_ENTRY, Specifications::new_UNKNOWN(W) }
	<k-kind-articled> |        ==> @<Make anomalous entry for kind@>
	<s-named-constant> |       ==> { NAMED_CONSTANT_ENTRY, RP[1] }
	<s-global-variable>	|      ==> @<Issue PM_TablePlayerEntry or C20TableVariableEntry problem@>
	<table-cell-value> |       ==> { pass 1 }
	<list-of-double-quotes> |  ==> @<Make anomalous entry for text to be understood@>
	...                        ==> @<Issue PM_TableUnknownEntry problem@>

<table-cell-blank> ::=
	--

<table-cell-value> ::=
	the action of <s-constant-action> |  ==> { ACTION_TABLE_ENTRY, RP[1] }
	<s-constant-action> |                ==> { ACTION_TABLE_ENTRY, RP[1] }
	the action of <s-explicit-action> |  ==> @<Issue PM_NonconstantActionInTable problem@>
	<s-explicit-action> |                ==> @<Issue PM_NonconstantActionInTable problem@>
	<instance-of-non-object> |           ==> { INSTANCE_TABLE_ENTRY, Rvalues::from_instance(RP[1]) }
	<s-type-expression>                  ==> { SPEC_TABLE_ENTRY, RP[1] }

<list-of-double-quotes> ::=
	<quoted-text> or <list-of-double-quotes> |
	<quoted-text>

@<Make anomalous entry for kind@> =
	parse_node *new = Specifications::from_kind(RP[1]);
	Node::set_text(new, W);
	==> { KIND_TABLE_ENTRY, new };

@<Make anomalous entry for text to be understood@> =
	parse_node *new = Specifications::from_kind(K_text);
	Node::set_text(new, W);
	==> { TOPIC_TABLE_ENTRY, new };

@<Issue PM_NonconstantActionInTable problem@> =
	int quoted_col = table_cell_col + 1; /* i.e., counting from 1 */
	Problems::quote_number(4, &quoted_col);
	Problems::quote_wording(5,
		Nouns::nominative_singular(
			table_being_examined->columns[table_cell_col].column_identity->name));
	Problems::quote_number(6, &table_cell_row);
	StandardProblems::table_problem(_p_(PM_NonconstantActionInTable),
		table_being_examined, NULL, table_cell_node,
		"In %1, I'm reading the text %3 in column %4 (%5) of row %6, but this is "
		"an action involving a variable, that is, a value that might vary in play. "
		"%PThis often happens if the action mentions 'the player', for example, "
		"because 'the player' is a variable. If 'the player' is the person "
		"carrying out the action, simply leave those words out; if 'the player' "
		"is involved in some other way, try using 'yourself' instead.");
	==> { PROBLEMATIC_TABLE_ENTRY, - };

@ The message PM_TablePlayerEntry is so called because by far the commonest
case of this is people writing "player" as a constant value in a column of
people -- it needs to be "yourself" instead, since "player" is a variable.

@<Issue PM_TablePlayerEntry or C20TableVariableEntry problem@> =
	nonlocal_variable *q = Lvalues::get_nonlocal_variable_if_any(RP[1]);
	if (q == NULL) internal_error("no such variable");
	inference_subject *infs = NonlocalVariables::get_alias(q);
	if (infs) {
		int quoted_col = table_cell_col + 1; /* i.e., counting from 1 */
		Problems::quote_number(4, &quoted_col);
		Problems::quote_wording(5,
			Nouns::nominative_singular(
				table_being_examined->columns[table_cell_col].column_identity->name));
		Problems::quote_number(6, &table_cell_row);
		Problems::quote_subject(7, infs);
		StandardProblems::table_problem(_p_(PM_TablePlayerEntry),
			table_being_examined, NULL, table_cell_node,
			"In %1, the entry %3 in column %4 (%5) of row %6 is the name of a value "
			"which varies, not a constant, and can't be stored as a table entry. %P"
			"This variable is usually set to the constant value '%7', so you might "
			"want to write that instead.");
	} else {
		int quoted_col = table_cell_col + 1; /* i.e., counting from 1 */
		Problems::quote_number(4, &quoted_col);
		Problems::quote_wording(5,
			Nouns::nominative_singular(
				table_being_examined->columns[table_cell_col].column_identity->name));
		Problems::quote_number(6, &table_cell_row);
		StandardProblems::table_problem(_p_(PM_TableVariableEntry),
			table_being_examined, NULL, table_cell_node,
			"In %1, the entry %3 in column %4 (%5) of row %6 is the name of a value "
			"which varies, not a constant, so it can't be stored as a table entry.");
	}
	==> { PROBLEMATIC_TABLE_ENTRY, - };

@<Issue PM_TableUnknownEntry problem@> =
	@<Actually issue PM_TableUnknownEntry problem@>;
	==> { PROBLEMATIC_TABLE_ENTRY, - };

@ (There are actually two ways this can happen, which is why it's set out like this.)

@<Actually issue PM_TableUnknownEntry problem@> =
	int quoted_col = table_cell_col + 1; /* i.e., counting from 1 */
	Problems::quote_number(4, &quoted_col);
	Problems::quote_wording(5,
		Nouns::nominative_singular(
			table_being_examined->columns[table_cell_col].column_identity->name));
	Problems::quote_number(6, &table_cell_row);
	StandardProblems::table_problem(_p_(PM_TableUnknownEntry),
		table_being_examined, NULL, table_cell_node,
		"In %1, I'm reading the text %3 in column %4 (%5) of row %6, but I don't "
		"know what this means. %PThis should usually be a value, like a number "
		"or a piece of text, or a blank entry marker '--', but in some circumstances "
		"it can also be an action (such as 'taking the box'), or a kind (such as "
		"'a number') to show what sort of values will go into an otherwise blank "
		"row.");

@ =
void Tables::stock_table_cell(table *t, parse_node *cell, int row_count, int col_count) {
	current_sentence = cell;
	int topic_exception = FALSE;
	table_cell_node = cell;
	table_cell_row = row_count;
	table_cell_col = col_count;

	@<Parse the table cell and give it an evaluation as a noun@>;
	parse_node *evaluation = Node::get_evaluation(cell);
	LOGIF(TABLES, "Cell evaluates to: $P\n", evaluation);

	if (topic_exception == FALSE) @<Require the cell to evaluate to an actual constant@>;

	Tables::Columns::note_kind(t, col_count, &(t->columns[col_count]), cell,
		Specifications::to_kind(evaluation), FALSE);
}

@<Parse the table cell and give it an evaluation as a noun@> =
	<table-cell>(Node::get_text(cell));
	parse_node *spec = <<rp>>;
	switch (<<r>>) {
		case BLANK_TABLE_ENTRY:
			Annotations::write_int(cell, table_cell_unspecified_ANNOT, TRUE);
			return;
		case SPEC_TABLE_ENTRY:
			Refiner::give_spec_to_noun(cell, spec);
			break;
		case NAMED_CONSTANT_ENTRY:
			topic_exception = TRUE;
			Refiner::give_spec_to_noun(cell, spec);
			break;
		case INSTANCE_TABLE_ENTRY:
			Refiner::give_spec_to_noun(cell, spec);
			break;
		case KIND_TABLE_ENTRY:
			Annotations::write_int(cell, table_cell_unspecified_ANNOT, TRUE);
			kind *K = Specifications::to_kind(spec);
			Tables::Columns::note_kind(t, col_count, &(t->columns[col_count]), cell,
				K, TRUE);
			return;
		case ACTION_TABLE_ENTRY:
			Refiner::give_spec_to_noun(cell, spec);
			break;
		case TOPIC_TABLE_ENTRY:
			Refiner::give_spec_to_noun(cell, spec);
			topic_exception = TRUE;
			break;
		case PROBLEMATIC_TABLE_ENTRY:
			return;
	}

@<Require the cell to evaluate to an actual constant@> =
	if ((Specifications::is_kind_like(evaluation)) ||
		(Specifications::is_description(evaluation))) {
		LOG("Evaluation is $P\n", evaluation);
		int quoted_col = table_cell_col + 1; /* i.e., counting from 1 */
		Problems::quote_number(4, &quoted_col);
		Problems::quote_wording(5,
			Nouns::nominative_singular(
				table_being_examined->columns[table_cell_col].column_identity->name));
		Problems::quote_number(6, &table_cell_row);
		StandardProblems::table_problem(_p_(PM_TableDescriptionEntry),
			t, NULL, cell,
			"In %1, the entry %3 in column %4 (%5) of row %6 is a general description "
			"of things with no definite value, and can't be stored as a table entry.");
		return;
	}
	if (Node::is(evaluation, CONSTANT_NT) == FALSE) {
		LOG("Evaluation is $P\n", evaluation);
		@<Actually issue PM_TableUnknownEntry problem@>;
	}

@h Completing tables.
Later on in Inform's run, just before compiling the tables, we call this:

=
void Tables::complete(void) {
	@<Finally make any table amendments which have been called for@>;
	@<Create blank rows described textually, if they were@>;
	@<Create blank rows for each instance of a kind, if requested@>;
}

@ For the actual code, see below.

@<Finally make any table amendments which have been called for@> =
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of)
			Tables::amend_table(t->amendment_of, t);

@<Create blank rows described textually, if they were@> =
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			current_sentence = t->table_created_at->source_table;
			wording W = t->blank_rows_text;
			int N = -1;
			if (Wordings::nonempty(W)) {
				if (<s-named-constant>(W)) {
					parse_node *val = NonlocalVariables::substitute_constants(<<rp>>);
					N = Rvalues::to_int(val);
				}
				if (N >= 0) t->blank_rows = N;
				else {
					Problems::quote_wording(4, t->blank_rows_text);
					StandardProblems::table_problem(_p_(PM_TableUnknownBlanks),
						t, NULL, current_sentence,
						"%1 asked to have '%4' extra blank rows, but that would "
						"only make sense for a literal number like '15' or a "
						"name for a constant number. (The number must of course "
						"be 0 or more.)");
				}
			}
		}

@<Create blank rows for each instance of a kind, if requested@> =
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			current_sentence = t->table_created_at->source_table;
			if (Wordings::nonempty(t->blank_rows_for_each_text)) {
				kind *K = NULL;
				if (<k-kind>(t->blank_rows_for_each_text)) {
					K = <<rp>>;
					t->blank_rows += Instances::count(K);
				} else {
					Problems::quote_wording(4, t->blank_rows_for_each_text);
					StandardProblems::table_problem(_p_(PM_TableKindlessBlanks),
						t, NULL, current_sentence,
						"%1 asked to have extra blank rows for each '%4', but that "
						"isn't a kind, so I can't see how many blank rows to make.");
				}
			}
		}

@h Amending tables.
Unlike continuations and replacements, table amendments depend on actual values
written into the cells, which means they can't be performed early in the run.
So for quite a long time two table structures exist: the "main table", the
actual one which will exist in play; and the "amendments" table, which is a
structure holding the amendment lines, but which won't actually exist
independently at run-time. The following routine is where the rows from the
amendments table are used to modify the main table, after which the amendments
table has no further use.

As might be expected, we work down the amendments table and apply them one
at a time:

=
void Tables::amend_table(table *main_table, table *amendments) {
	LOGIF(TABLES, "Amending table $B according to $B\n", main_table, amendments);
	parse_node *leftmost_amend_cell = NULL;
	int amend_row = 1, amendment_problem_opened = FALSE;
	for (amend_row = 1, leftmost_amend_cell = amendments->columns[0].entries->down;
		leftmost_amend_cell;
		amend_row++, leftmost_amend_cell = leftmost_amend_cell->next)
		@<Apply the amendment in this row to the main table@>;
}

@ The following is not so obvious. The amendment row is intended to replace a
row in the main table, and we need to decide which one. Suppose the amendment
reads:
= (text)
	62   "lampstand"   10:30 AM
=
If the main table has exactly one row with 62 in the first column, we choose
that; if it contains more than one, we look for rows which begin with
|62| and then |"lampstand"|; and so on. (Recall that amendment tables have
exactly the same columns as their originals, and in the same order.)

In the following, |col| is the rightmost column used in the initial string
being tried: so when it's 0, we're just trying to match |62|, when it's 1
we're trying to match |62| and |"lampstand"|; and so on. But of course each
such search is narrower than the one before, so we only need to look at the
rows which passed last time, and test their values in column |col|.

In fact, we do this in reverse: we start with every row in the main table
marked as a possible match, and then exclude rows as they fail to match.
Eventually this should leave only a single row, and that's the winner.

@<Apply the amendment in this row to the main table@> =
	int col, matches_in_last_round = 0;
	@<Mark every row in the main table as a possible match@>;
	for (col = 0; col < main_table->no_columns; col++) {
		parse_node *amend_cell;
		@<Set the amend-cell to this column's cell in the current amendment row@>;
		if (Annotations::read_int(amend_cell, table_cell_unspecified_ANNOT) == FALSE) {
			int only_row_left = -1;
			@<Use the key value in the amend-cell to make an amendment@>;
			if (only_row_left >= 0) {
				Tables::splice_table_row(main_table, amendments, only_row_left, amend_row);
				break;
			}
		}
	}

@ We need one flag for each row in the main table; we do this with the "row
amendable" annotation for the cell nodes in the first column. (There's nothing
special about the first column, but it's guaranteed to exist, i.e., there is
always at least one column.)

@<Mark every row in the main table as a possible match@> =
	parse_node *leftmost_cell;
	for (leftmost_cell = main_table->columns[0].entries->down;
		leftmost_cell;
		leftmost_cell = leftmost_cell->next) {
		Annotations::write_int(leftmost_cell, row_amendable_ANNOT, TRUE);
		matches_in_last_round++;
	}

@<Set the amend-cell to this column's cell in the current amendment row@> =
	int i;
	for (i = 1, amend_cell = amendments->columns[col].entries->down;
		amend_cell && (i < amend_row); i++, amend_cell = amend_cell->next) ;
	if (amend_cell == NULL) internal_error("columns in amendments aren't equal in length");

@ When we get here, then, we look at the key value in the amend-cell: suppose
this is the number 17. If there's no row in the main table having 17 in this
column, we're stuck. But if there are two or more, we allow the loop to move
us along to the next column, hoping that the key value there will find a
unique match. If we're in the last column and there are still multiple
possibilities, the amendment row must be identical to more than one row
of the main table -- in this case the amendment will have no effect, but
put another way, it can do no harm.

@<Use the key value in the amend-cell to make an amendment@> =
	parse_node *amend_key = Node::get_evaluation(amend_cell);
	LOGIF(TABLES, "Amend row %d, col %d, key $P: $T\n", amend_row, col, amend_key, amend_cell);
	if (Node::is(amend_key, CONSTANT_NT) == FALSE)
		internal_error("bad key in amendments table"); /* code above should make this impossible */

	int matches = 0;
	@<Find the number of possible-match rows in the main table with this key value in the same column@>;
	if (matches == 0) @<Issue problem to say that no row in the main table matches@>;
	if (matches > 1) {
		if (col < main_table->no_columns - 1) /* i.e., if we haven't reached the final column */
			only_row_left = -1; /* because there's no single row left */
	}
	matches_in_last_round = matches;

@ The loop below and its inner conditional look pretty forbidding, but they
come down to this: loop through each row of the main table which is still a
possible match.

@<Find the number of possible-match rows in the main table with this key value in the same column@> =
	int row;
	parse_node *leftmost_cell;
	parse_node *main_cell;
	for (row = 1,
		main_cell = main_table->columns[col].entries->down,
		leftmost_cell = main_table->columns[0].entries->down;
		main_cell;
		row++,
		main_cell = main_cell->next,
		leftmost_cell = leftmost_cell->next) {
		parse_node *main_value = Node::get_evaluation(main_cell);
		if (Annotations::read_int(leftmost_cell, row_amendable_ANNOT))
			@<See if this possible-match row has the right key value in the new column@>;
	}

@ We not only record the result if there's a match; we kick the row out of the
possible-match set if there isn't.

@<See if this possible-match row has the right key value in the new column@> =
	LOG("Key in row %d is $P\n", row, main_value);
	if ((Node::is(main_value, CONSTANT_NT)) &&
		(Rvalues::compare_CONSTANT(amend_key, main_value))) {
		matches++;
		only_row_left = row;
	} else {
		Annotations::write_int(leftmost_cell, row_amendable_ANNOT, FALSE);
	}

@ That just leaves the problem message, a very subtle one which took a long
time to find a clear wording for:

@<Issue problem to say that no row in the main table matches@> =
	@<Begin an amendment problem message@>;
	int quoted_col = col + 1; /* i.e., counting from 1, not 0 */
	Problems::quote_number(1, &amend_row);
	Problems::quote_number(2, &quoted_col);
	Problems::quote_source(3, amend_cell);
	Problems::quote_wording(4,
		Nouns::nominative_singular(main_table->columns[col].column_identity->name));
	Problems::quote_table(5, main_table);
	Problems::quote_number(6, &matches_in_last_round);
	if (matches_in_last_round > 2) Problems::quote_text(7, "any");
	else Problems::quote_text(7, "either");
	Problems::issue_problem_begin(Task::syntax_tree(), "****");
	if (col == 0)
	Problems::issue_problem_segment(
		"(Amendment %1). I can't match this to any row - there's nothing with "
		"an entry of %3 in the lefthand column (%4).");
	else
	Problems::issue_problem_segment(
		"(Amendment %1). I can't decide which row this should replace. "
		"It matches %6 rows until I get up to column %2 (%4), but then "
		"it reads %3, which is different from %7 of them.");
	Problems::issue_problem_end();
	break; /* to move on to the next row in the amendments */

@<Begin an amendment problem message@> =
	if (amendment_problem_opened == FALSE) {
		amendment_problem_opened = TRUE;
		current_sentence = amendments->table_created_at->source_table;
		Problems::quote_table(1, main_table);
		Problems::quote_table(2, amendments);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableAmendmentMismatch));
		Problems::issue_problem_segment(
			"I'm currently trying to amend rows in %1 according to the instructions "
			"in %2. To do that, I have to match each amendment row in turn, which "
			"I do by trying to match up entries in the leftmost column(s).");
		Problems::issue_problem_end();
		Problems::issue_problem_begin(Task::syntax_tree(), "****");
		Problems::issue_problem_segment("But I ran into problems:");
		Problems::issue_problem_end();
	}

@ And, of course, the actual splicing of the amendment row in place of the
original:

=
void Tables::splice_table_row(table *table_to, table *table_from, int row_to, int row_from) {
	int i;
	for (i=0; i<table_to->no_columns; i++) {
		parse_node *cell_to, *cell_from;
		int row;
		for (row = 1, cell_to = table_to->columns[i].entries->down;
				cell_to && (row < row_to); cell_to = cell_to->next, row++) ;
		for (row = 1, cell_from = table_from->columns[i].entries->down;
				cell_from && (row < row_from); cell_from = cell_from->next, row++) ;
		if ((cell_to) && (cell_from)) {
			Refiner::copy_noun_details(cell_to, cell_from);
			Annotations::write_int(cell_to, table_cell_unspecified_ANNOT,
				Annotations::read_int(cell_from, table_cell_unspecified_ANNOT));
		} else internal_error("bad table row splice");
	}
}

@ This is called when a table is being asked to define objects (or kinds).

=
void Tables::use_to_define(table *t, int defining_objects, parse_node *where) {
	if (t == NULL) internal_error("no table");
	if (defining_objects == FALSE) {
		t->contains_property_values_at_run_time = TRUE;
		t->fill_in_blanks = TRUE;
		t->preserve_row_order_at_run_time = TRUE;
		t->disable_block_constant_correction = TRUE;
	}
	if ((t->has_been_amended) && (defining_objects))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TableCantDefineAndAmend),
			"you can't use 'defined by' to define objects using a table "
			"which is amended by another table",
			"since that could too easily lead to ambiguities about what "
			"the property values are.");
	t->first_column_by_definition = TRUE;
	t->where_used_to_define = where;
}
