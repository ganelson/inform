[Tables::Columns::] Table Columns.

To manage the named columns which appear in tables.

@ Tables are one of the most distinctive data structures of Inform. They
imitate printed tables in books or scientific papers, and the data inside
them is arranged in columns, each of which is headed by a name.

Data in a given column must have a definite kind, such as "number". Where
this is unspecified in any explicit way, it is inferred by performing a
join on the kinds of the values quoted in the column -- that is, the result
is the narrowest kind capable of holding all of the observed values.

Inform has a limited ability to link tables together, as in a relational
database, but this relies on an unusual design decision: if a column in
two different tables has the same name, then it must have the same kind
in both tables.

=
typedef struct table_column {
	struct noun *name; /* name of column (without "entry" suffix) */
	struct kind *kind_stored_in_column; /* what kind of value is stored in this column */
	struct table *table_from_which_kind_inferred; /* usually the earliest use */
	struct binary_predicate *listed_in_predicate; /* see below */
	struct table_column_compilation_data compilation_data;
	CLASS_DEFINITION
} table_column;

@ The predicate calculus engine often finds conditions equivalent to "if A
is a C listed in T", and we implement this as a binary predicate -- see
//Listed-In Relations//. There is one such relation for each column, and
a pointer is stored in |listed_in_predicate|.

=
binary_predicate *Tables::Columns::get_listed_in_predicate(table_column *tc) {
	return tc->listed_in_predicate;
}

@ =
void Tables::Columns::log(table_column *tc) {
	LOG("'%W'/", Nouns::nominative_singular(tc->name));
	if (tc->kind_stored_in_column == NULL) LOG("unknown");
	else LOG("%u", tc->kind_stored_in_column);
}

@h Creation.
Columns are created with a name, which is assumed here to be not the name
of any existing column.

=
table_column *Tables::Columns::new_table_column(wording W) {
	table_column *tc = CREATE(table_column);
	tc->name = NULL;
	tc->kind_stored_in_column = NULL;
	tc->table_from_which_kind_inferred = NULL;
	if (Wordings::nonempty(W)) { /* always happens unless recovering from a problem */
		tc->name = Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			TABLE_COLUMN_MC, Rvalues::from_table_column(tc),
			Task::language_of_syntax());
		word_assemblage wa =
			PreformUtilities::merge(<table-column-name-construction>, 0,
				WordAssemblages::from_wording(W));
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			TABLE_COLUMN_MC, Rvalues::from_table_column(tc),
			Task::language_of_syntax());
	}
	tc->compilation_data = RTTableColumns::new_compilation_data(tc);
	tc->listed_in_predicate = Tables::Relations::make_listed_in_predicate(tc);
	return tc;
}

@ The author can demand with a "translates as" sentence that a given
table should have an identifier given to it which is accessible to Inter:

=
void Tables::Columns::translates(wording W, parse_node *p2) {
	if (<s-value>(W)) {
		table_column *tc = Rvalues::to_table_column(<<rp>>);
		if (tc) {
			RTTableColumns::translate(tc, Node::get_text(p2));
			return;
		}
	}
	LOG("Tried %W\n", W);
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_TranslatesNonTableColumn),
		"this is not the name of a table column",
		"so cannot be translated.");
}

@h Kind.
Keeping track of the kind of the entries in a column is a little tricky.
Columns are created early in Inform's run, before the full hierarchy of kinds
is in place; so TC structures tend to record a |NULL| kind for a while, and
are then corrected later. Moreover, they're sometimes revised in the light
of evidence, if the kind has to be inferred from the table's initial entries.
So we can't just set the kind once at creation time.

This has a knock-on effect on the predicate associated with the column,
because the kind of term $A$ in ${\it listed}_C(A, T)$ must match the kind
of entry in the column $C$.

=
kind *Tables::Columns::get_kind(table_column *tc) {
	return tc->kind_stored_in_column;
}

kind *Tables::Columns::to_kind(table_column *tc) {
	return Kinds::unary_con(CON_table_column, tc->kind_stored_in_column);
}

void Tables::Columns::set_kind(table_column *tc, table *t, kind *K) {
	if (Kinds::get_construct(K) == CON_description)
			@<Issue a problem message for a description heading@>;
	if (Kinds::eq(tc->kind_stored_in_column, K)) {
		LOGIF(TABLES, "Table column $C continues to have kind %u, according to $B\n",
			tc, K, t);
	} else {
		LOGIF(TABLES, "Table column $C set to kind %u, according to $B\n",
			tc, K, t);
		tc->kind_stored_in_column = K;
	}
	tc->table_from_which_kind_inferred = t;
	if ((K_understanding) && (Kinds::eq(K, K_understanding)))
		Tables::Relations::supply_kind_for_listed_in_tc(tc->listed_in_predicate, K_snippet);
	else Tables::Relations::supply_kind_for_listed_in_tc(tc->listed_in_predicate, K);
}

@<Issue a problem message for a description heading@> =
	Problems::quote_kind(4, K);
	Problems::quote_kind(5, K);
	Problems::quote_table(6, t);
	StandardProblems::table_problem(_p_(PM_TableColumnDescription),
		t, tc, NULL,
		"In %1, you've written the heading of the column '%2' to say that each entry "
		"should be %4. But descriptions aren't allowed as table entries - tables "
		"have to hold values, not descriptions of values.");

@h Discovering columns.
New TCs aren't declared ("Density is a table column."): they are discovered
by looking through the column-heading lines of tables. Each one makes:

=
typedef struct table_column_usage {
	struct table_column *column_identity;
	struct parse_node *entries; /* initial contents of this column in the table */
	struct wording kind_declaration_text; /* if specified */
	int actual_constant_entries; /* how many entries have explicitly been given */
	struct parse_node *observed_constant_cell; /* first one spotted */
	int kind_name_entries; /* how many entries read, say, "a rulebook" */
	struct parse_node *observed_kind_cell; /* first one spotted */
	struct table_column_usage_compilation_data compilation_data;
} table_column_usage;

@ Each piece of heading text is passed to the following routine in turn:

=
table_column_usage Tables::Columns::add_to_table(wording W, table *t) {
	wording EXPW = EMPTY_WORDING;
	table_column_usage tcu;
	table_column *tc = Tables::Columns::find_table_column(W, t, &EXPW);
	for (int i=0; i<t->no_columns; i++)
		if (t->columns[i].column_identity == tc) {
			Problems::quote_wording(4, W);
			StandardProblems::table_problem(_p_(PM_DuplicateColumnName),
				t, NULL, NULL,
				"In %1, the column name %4 cannot be used, because there's already "
				"a column of the same name. (You can't have two columns with the "
				"same name in the same table.)");
		}
	tcu.column_identity = tc;
	tcu.entries = Diagrams::new_PROPER_NOUN(W);
	tcu.kind_declaration_text = EXPW;
	tcu.actual_constant_entries = 0;
	tcu.observed_constant_cell = NULL;
	tcu.kind_name_entries = 0;
	tcu.observed_kind_cell = NULL;
	tcu.compilation_data = RTTables::new_tcu_compilation_data(t);

	return tcu;
}

@ The syntax for table column headings is little complicated:

@d EXISTING_TC 1               /* one seen before in another table, with a kind given */
@d EXISTING_TC_WITHOUT_KIND 2  /* one seen before in another table */
@d NEW_TC 3                    /* never seen before, with a kind explicitly given */
@d NEW_TC_WITHOUT_KIND 4       /* never seen before, with no specified kind */
@d NEW_TC_TOPIC 5              /* a topic column, a specialised form of text */
@d NEW_TC_PROBLEM 6            /* (something went wrong, so Inform can ignore this) */

@ The heading of a table column is the text in its entry in the first
(titling-only) row of the table. Usually that consists only of the column's
name, but optionally the kind can also be supplied in brackets -- Inform
otherwise infers the kind from the contents below. The kind will subsequently
be parsed using |<k-kind-articled>|, but for timing reasons that happens later,
so the grammar below allows any text in the brackets. A "topic" column
needs special handling since it also overrides kind inference, making
what looks like text into grammar for parsing.

=
<table-column-heading> ::=
	( *** ) |                               ==> @<Issue PM_TableColumnBracketed problem@>
	topic ( ... ) |                         ==> @<Issue PM_TopicText problem@>
	<s-table-column-name> ( {...} ) |       ==> { EXISTING_TC, RP[1] }
	<table-column-heading-bare> ( {...} ) | ==> { (R[1] == NEW_TC_PROBLEM)?R[1]:NEW_TC, - }
	<s-table-column-name> |                 ==> { EXISTING_TC_WITHOUT_KIND, RP[1] }
	<table-column-heading-bare>             ==> { pass 1 }

<table-column-heading-bare> ::=
	<article> |                             ==> @<Issue PM_TableColumnArticle problem@>
	{topic} |                               ==> { NEW_TC_TOPIC, - }
	{<property-name>} |                     ==> { NEW_TC_WITHOUT_KIND, - }
	{<s-constant-value>} |                  ==> @<Issue PM_TableColumnAlready problem@>
	...                                     ==> { NEW_TC_WITHOUT_KIND, - }
	
@<Issue PM_TableColumnArticle problem@> =
	Problems::quote_wording(4, W);
	StandardProblems::table_problem(_p_(PM_TableColumnArticle),
		table_being_examined, NULL, table_cell_node,
		"In %1, the column name %3 cannot be used, because there would be too "
		"much ambiguity arising from its ordinary meaning as an article. (It "
		"would be quite awkward talking about the '%4 entry', for example.)");
	==> { NEW_TC_PROBLEM, - };

@<Issue PM_TableColumnAlready problem@> =
	StandardProblems::table_problem(_p_(PM_TableColumnAlready),
		table_being_examined, NULL, table_cell_node,
		"In %1, the column name %3 cannot be used, because it already means "
		"something else.");
	==> { NEW_TC_PROBLEM, - };

@<Issue PM_TopicText problem@> =
	StandardProblems::table_problem(_p_(PM_TopicText),
		table_being_examined, NULL, table_cell_node,
		"In %1, the column name 'topic' is not allowed to have a clarifying kind "
		"in brackets after it. Just say 'topic' and leave it at that.");
	==> { NEW_TC_PROBLEM, - };

@<Issue PM_TableColumnBracketed problem@> =
	StandardProblems::table_problem(_p_(PM_TableColumnBracketed),
		table_being_examined, NULL, table_cell_node,
		"In %1, the column name %3 cannot be used, because it is in brackets. "
		"(Perhaps you intended to use the brackets to give the kind of the "
		"entries, but forgot to put a name before the opening bracket.)");
	==> { NEW_TC_PROBLEM, - };

@ When a column is found with a name not seen before -- say, "merit points"
-- the following grammar is used to construct a proper noun to refer to this
column; thus, "merit points column".

=
<table-column-name-construction> ::=
	... column

@ And here's where we use the grammar above. We parse the heading text and
return the TC it refers to, creating it if necessary; and we also return the
text of any explicit kind declaration used within it.

=
table_column *Tables::Columns::find_table_column(wording W, table *t, wording *EXPW) {
	table_cell_node = Diagrams::new_PROPER_NOUN(W);
	table_cell_row = -1;
	table_cell_col = -1;
	table_being_examined = t;
	*EXPW = EMPTY_WORDING;
	<table-column-heading>(W);
	table_column *tc = NULL;
	kind *K = NULL;
	switch (<<r>>) {
		case EXISTING_TC_WITHOUT_KIND:
			*EXPW = Wordings::new(-1, -1);
			tc = Rvalues::to_table_column(<<rp>>);
			break;
		case EXISTING_TC:
			*EXPW = GET_RW(<table-column-heading>, 1);
			tc = Rvalues::to_table_column(<<rp>>);
			break;
		case NEW_TC_TOPIC: K = K_understanding; break;
		case NEW_TC: *EXPW = GET_RW(<table-column-heading>, 1); break;
		case NEW_TC_WITHOUT_KIND: break;
		case NEW_TC_PROBLEM: return NULL;
	}
	@<Make a try at identifying the any named kind, even though it probably won't work@>;
	if (tc == NULL) @<Create a new table column with this name@>;
	if (K) Tables::Columns::set_kind(tc, t, K);
	return tc;
}

@ If the heading is something like "population (number)", the following will
correctly identify "number", because that's a kind which exists very early in
Inform's run. Something like "lucky charm (thing)" won't work, because "thing"
hasn't been created yet; but we'll catch it later.

@<Make a try at identifying the any named kind, even though it probably won't work@> =
	if ((K == NULL) && (Wordings::nonempty(*EXPW)) && (<k-kind-articled>(*EXPW))) {
		K = <<rp>>; *EXPW = EMPTY_WORDING;
	}

@<Create a new table column with this name@> =
	W = GET_RW(<table-column-heading-bare>, 1);
	if (Assertions::Creator::vet_name(W)) tc = Tables::Columns::new_table_column(W);
	else return NULL;

@h Checking kind consistency.
Well, and now it's later. First, the following is called on each usage of a
column in turn:

=
void Tables::Columns::check_explicit_headings(table *t, int i, table_column_usage *tcu) {
	kind *K = Tables::Columns::get_kind(tcu->column_identity);
	if (Wordings::nonempty(tcu->kind_declaration_text)) {
		kind *EK = NULL;
		if (<k-kind-articled>(tcu->kind_declaration_text)) {
			EK = <<rp>>;
			LOGIF(TABLES, "$B col %d '%W' claims %u\n", t, i, tcu->kind_declaration_text, EK);
			if (K == NULL)
				Tables::Columns::set_kind(tcu->column_identity, t, EK);
			else if (!(Kinds::eq(K, EK)))
				@<Issue a problem message for a heading inconsistency@>;
		} else @<Issue a problem message for an incomprehensible column heading@>;
	} else {
		LOGIF(TABLES, "Column %d has no explicit kind named in $B\n", i, t);
	}
}

@<Issue a problem message for a heading inconsistency@> =
	Problems::quote_kind(4, EK);
	Problems::quote_kind(5, K);
	Problems::quote_table(6, tcu->column_identity->table_from_which_kind_inferred);
	StandardProblems::table_problem(_p_(PM_TableColumnInconsistent),
		t, tcu->column_identity, tcu->entries,
		"In %1, you've written the heading of the column %3 to say that each entry "
		"should be %4. But a column with the same name also appears in %6, and each "
		"entry there is %5. Inform doesn't allow this - the same column name always "
		"has to have the same kind of entry, whichever tables it appears in.");

@<Issue a problem message for an incomprehensible column heading@> =
	StandardProblems::table_problem(_p_(PM_TableColumnBrackets),
		t, tcu->column_identity, tcu->entries,
		"In %1, I can't use the column heading %3. Brackets are only allowed in "
		"table column names when giving the kind of value which will be stored in "
		"the column. So 'poems (text)' is legal, but not 'poems (chiefly lyrical)'.");

@ Secondly, the actual entries are checked in turn, and their kinds passed
to the following routine. Again, "topic" columns are a complication, since
their kind is ostensibly |K_understanding| but the actual entries must be
|K_text|.

=
void Tables::Columns::note_kind(table *t, int i, table_column_usage *tcu,
	parse_node *cell, kind *K, int generic) {
	if (generic) {
		tcu->kind_name_entries++;
		if (tcu->observed_kind_cell == NULL) tcu->observed_kind_cell = cell;
		if (tcu->kind_name_entries == 2)
			@<Issue a problem for a second kind name in the column@>
		else if (tcu->actual_constant_entries > 0)
			@<Issue a problem for a kind name lower in the column than a value@>
		else {
			kind *CK = Tables::Columns::get_kind(tcu->column_identity);
			if (CK == NULL) {
				Tables::Columns::set_kind(tcu->column_identity, t, K);
				return;
			} else if (Kinds::eq(K, CK) == FALSE)
				@<Issue a problem for an inconsistent kind for this column@>;
		}
	} else {
		tcu->actual_constant_entries++;
		if (tcu->observed_constant_cell == NULL) tcu->observed_constant_cell = cell;
		if (tcu->kind_name_entries > 0)
			@<Issue a problem for a value lower in the column than a kind name@>;
	}
	kind *CK = Kinds::weaken(Tables::Columns::get_kind(tcu->column_identity), K_object);
	K = Kinds::weaken(K, K_object);
	if ((global_pass_state.pass >= 2) && (CK) && (Kinds::Behaviour::definite(CK) == FALSE))
		CK = NULL;
	if (CK == NULL) {
		Tables::Columns::set_kind(tcu->column_identity, t, K);
	} else {
		int allow_refinement = TRUE;
		if ((K_understanding) && (Kinds::eq(CK, K_understanding))) {
			CK = K_text; /* make sure the entries are texts... */
			allow_refinement = FALSE; /* ...and don't allow any change to the kind */
		}
		if (Kinds::eq(K, CK) == FALSE) {
			kind *max_K = Latticework::join(K, CK);
			if (Kinds::Behaviour::definite(max_K) == FALSE) {
				Problems::quote_kind(4, K);
				Problems::quote_kind(5, CK);
				if (t == tcu->column_identity->table_from_which_kind_inferred)
					@<Issue a problem for kind mismatch within column@>
				else
					@<Issue a problem for kind mismatch between columns of the same name@>;
				allow_refinement = FALSE;
			}
			if (allow_refinement)
				Tables::Columns::set_kind(tcu->column_identity, t, max_K);
		}
	}
}

@<Issue a problem for a kind name lower in the column than a value@> =
	int quoted_col = i + 1; /* i.e., counting from 1 */
	Problems::quote_number(4, &quoted_col);
	Problems::quote_number(5, &table_cell_row);
	Problems::quote_source(6, tcu->observed_constant_cell);
	StandardProblems::table_problem(_p_(PM_TableKindBelowValue),
		t, tcu->column_identity, cell,
		"In %1, column %4 (%2), the entry %3 (row %5) is the name of a kind. "
		"This isn't a specific value. You're allowed to write in the name "
		"of a kind like this if the column otherwise has blank entries - to "
		"tell Inform what might eventually go there - but here the column "
		"already contains a genuine value higher up: %6. %P"
		"So the kind name has to go. You can either let me deduce the kind by "
		"myself, working it out from the actual values in the column, or you "
		"can put the kind in brackets after the column's name, at the top.)");

@<Issue a problem for a second kind name in the column@> =
	int quoted_col = i + 1; /* i.e., counting from 1 */
	Problems::quote_number(4, &quoted_col);
	Problems::quote_number(5, &table_cell_row);
	Problems::quote_source(6, tcu->observed_kind_cell);
	StandardProblems::table_problem(_p_(PM_TableKindTwice),
		t, tcu->column_identity, cell,
		"In %1, column %4 (%2), the entry %3 (row %5) is the name of a kind. "
		"This isn't a specific value. You're allowed to write in the name "
		"of a kind like this if the column starts out with blank entries - to "
		"tell me what might eventually go there - but only once; and "
		"this is the second time. (The first was %6.)");

@<Issue a problem for a value lower in the column than a kind name@> =
	int quoted_col = i + 1; /* i.e., counting from 1 */
	Problems::quote_number(4, &quoted_col);
	Problems::quote_number(5, &table_cell_row);
	Problems::quote_source(6, tcu->observed_kind_cell);
	StandardProblems::table_problem(_p_(PM_TableValueBelowKind),
		t, tcu->column_identity, cell,
		"In %1, column %4 (%2), the entry %3 (row %5) is a genuine, non-blank "
		"entry: it's a specific value. That's fine, of course - the whole "
		"idea of a table is to contain values - but this is a column which "
		"already contains a name of a kind: %6. %P"
		"Names of kinds are only allowed at the top of otherwise blank columns: "
		"they tell me what might eventually go there. So the kind name has to go. "
		"You can replace it with a blank '--', and then either let me deduce the "
		"kind by myself, working it out from the actual values in the column, or "
		"you can put the kind in brackets after the column's name, at the top.)");

@<Issue a problem for kind mismatch within column@> =
	int quoted_col = i + 1; /* i.e., counting from 1 */
	Problems::quote_number(6, &quoted_col);
	Problems::quote_number(7, &table_cell_row);
	StandardProblems::table_problem(_p_(PM_TableIncompatibleEntry),
		t, tcu->column_identity, cell,
		"In %1, column %6 (%2), the entry %3 (row %7) doesn't fit what I know "
		"about '%2' - it's %4, whereas I think every entry ought to be %5.");

@<Issue a problem for kind mismatch between columns of the same name@> =
	int quoted_col = i + 1; /* i.e., counting from 1 */
	Problems::quote_table(6, tcu->column_identity->table_from_which_kind_inferred);
	Problems::quote_wording(7, Nouns::nominative_singular(tcu->column_identity->name));
	Problems::quote_number(8, &quoted_col);
	Problems::quote_number(9, &table_cell_row);
	StandardProblems::table_problem(_p_(PM_TableIncompatibleEntry2),
		t, tcu->column_identity, cell,
		"In %1, column %8 (%2), the entry %3 (row %9) has the wrong kind to be in "
		"the '%2' column - it's %4, whereas I think every entry ought to be %5. %P"
		"The entries under a given column name must be blanks or values of the same "
		"kind as each other, and this applies even to columns in different tables "
		"if they have the same name. Compare the table %6, where there's also a "
		"column called '%7'.");

@ Relatedly, but visible only if there are no entries so that the above never
happens:

@<Issue a problem for an inconsistent kind for this column@> =
	Problems::quote_table(6, tcu->column_identity->table_from_which_kind_inferred);
	Problems::quote_wording(7, Nouns::nominative_singular(tcu->column_identity->name));
	Problems::quote_kind(4, K);
	Problems::quote_kind(5, CK);
	StandardProblems::table_problem(_p_(PM_TableColumnIncompatible),
		t, tcu->column_identity, cell,
		"In %1, the column '%2' is declared as holding %4, but when the same "
		"column appeared in table %6, the contents were said there to be %5. %P"
		"The entries under a given column name must be values of the same "
		"kind as each other, and this applies even to columns in different tables "
		"if they have the same name.");

@ Thirdly and lastly:

=
void Tables::Columns::approve_kind(table *t, int i, table_column_usage *tcu) {
	kind *K = Tables::Columns::get_kind(tcu->column_identity);
	LOGIF(TABLES, "Column %d '%W' has kind %u with data:\n$T",
		i, Nouns::nominative_singular(tcu->column_identity->name), K, tcu->entries);
	if ((Kinds::get_construct(K) == CON_list_of) &&
		(Kinds::eq(Kinds::unary_construction_material(K), K_nil))) {
		StandardProblems::table_problem(_p_(PM_TableColumnEmptyLists),
			t, NULL, tcu->entries,
			"In %1, the column %3 seems to consist only of empty lists. "
			"This means that I can't tell what kind of value it should hold - "
			"are they to be lists of numbers, for instance, or lists of texts, "
			"or some other possibility? Either one of the entries must contain a "
			"non-empty list - so that I can deduce the answer by looking at what "
			"is in it - or else the column heading must say, e.g., by calling it "
			"'exceptions (list of texts)' with the kind of value in brackets after "
			"the name.");
	}
	if (K == NULL) {
		int quoted_col = i + 1; /* i.e., counting from 1 */
		Problems::quote_number(4, &quoted_col);
		StandardProblems::table_problem(_p_(PM_TableKindlessColumn),
			t, tcu->column_identity, NULL,
			"Column %4 (%2) of %1 contains no values and doesn't tell me "
			"anything about its kind%S.%L, "
			"which means that I don't know how to deal with it. You should "
			"either put a value into the column somewhere, or else write "
			"the kind in as part of the heading: '%2 (a number)', say.");
		Tables::Columns::set_kind(tcu->column_identity, t, K_number);
	}
}
