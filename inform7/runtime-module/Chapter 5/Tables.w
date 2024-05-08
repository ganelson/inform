[RTTables::] Tables.

To compile the tables submodule for a compilation unit, which contains
_table packages containing _table_column_usage subpackages.

@h Compilation data for tables.
Each |table| object contains this data:

=
typedef struct table_compilation_data {
	struct package_request *table_package;
	struct inter_name *table_identifier;
	struct wording name_for_metadata;
	struct parse_node *where_created;
	int translated;
	struct text_stream *translated_name;
	struct inter_name *translated_iname;
} table_compilation_data;

table_compilation_data RTTables::new_table(parse_node *PN, table *t, wording W) {
	table_compilation_data tcd;
	tcd.table_package = NULL;
	tcd.table_identifier = NULL;
	tcd.name_for_metadata = W;
	tcd.where_created = PN;
	tcd.translated = FALSE;
	tcd.translated_name = NULL;
	tcd.translated_iname = NULL;
	return tcd;
}

package_request *RTTables::package(table *t) {
	if (t->compilation_data.table_package == NULL)
		t->compilation_data.table_package =
			Hierarchy::local_package_to(TABLES_HAP, t->compilation_data.where_created);
	return t->compilation_data.table_package;
}

inter_name *RTTables::identifier(table *t) {
	if (t->compilation_data.table_identifier == NULL)
		t->compilation_data.table_identifier =
			Hierarchy::make_iname_in(TABLE_DATA_HL, RTTables::package(t));
	return t->compilation_data.table_identifier;
}

inter_name *RTTables::id_translated(table *t) {
	if (Str::len(t->compilation_data.translated_name) == 0) return NULL;
	if (t->compilation_data.translated_iname == NULL) {
		t->compilation_data.translated_iname = InterNames::explicitly_named(
			t->compilation_data.translated_name, RTTables::package(t));
		Hierarchy::make_available(t->compilation_data.translated_iname);
	}
	return t->compilation_data.translated_iname;
}

void RTTables::translate(table *t, wording W) {
	if (t->compilation_data.translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatesTableAlready),
			"this table has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	t->compilation_data.translated = TRUE;
	t->compilation_data.translated_name = Str::new();
	WRITE_TO(t->compilation_data.translated_name, "%N", Wordings::first_wn(W));
}

@h Compilation of tables.

=
void RTTables::compile(void) {
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "table '%W'", t->compilation_data.name_for_metadata);
			Sequence::queue(&RTTables::compilation_agent, STORE_POINTER_table(t), desc);
		}
}

void RTTables::compilation_agent(compilation_subtask *ct) {
	table *t = RETRIEVE_POINTER_table(ct->data);
	current_sentence = t->table_created_at->source_table;
	int blanks_array_hwm = 0; /* the high water mark of storage used in the blanks array */
	@<Compile the run-time storage for the table@>;
	@<Compile metadata for the table@>;
	@<Compile the blanks bitmap table@>;
	Hierarchy::apply_metadata_from_iname(RTTables::package(t), TABLE_VALUE_MD_HL,
		RTTables::identifier(t));
	if (t == TheScore::ranking_table())
		Hierarchy::apply_metadata_from_number(RTTables::package(t), RANKING_TABLE_MD_HL, 1);
	inter_name *translated = RTTables::id_translated(t);
	if (translated) Emit::iname_constant(translated, K_value, RTTables::identifier(t));
}

@<Compile the run-time storage for the table@> =
	int words_used = 0;
	current_sentence = t->table_created_at->source_table;
	@<Compile the outer table array@>;
	t->approximate_array_space_needed = words_used;

@ At run time, the data in T is essentially stored as a table of column
tables, one for each column. A column table begins with a word identifying
the table column number (so that two columns both called "price" in
different tables will have the same identifying value heading their column
tables), together with special bits set to indicate that exotic types of
data are stored inside. Thus if T has C columns, the column tables are
found at |T-->1|, |T-->2|, ..., |T-->C|.

@<Compile the outer table array@> =
	for (int j=0; j<t->no_columns; j++) {
		@<Compile the inner table array for column j@>;
	}
	packaging_state save = EmitArrays::begin_bounded(RTTables::identifier(t), K_value);
	for (int j=0; j<t->no_columns; j++) {
		EmitArrays::iname_entry(RTTables::tcu_iname(&(t->columns[j])));
	}
	EmitArrays::end(save);
	words_used += t->no_columns + 1;

@ Each column table |C| has its identifying number and bitmap combined in
|C-->1| (the ID occupies the lower bits), a pointer to its blanks storage
in |C-->2|, and its actual data in |C-->3|, |C-->4|, ..., |C-->(R+2)|,
where R is the number of rows.

The contents of a cell are not just its value but also an indication of
whether or not it is formally blank, which often makes it impossible to
store in a single virtual machine word. In those situations we also store
a single bit in the "blanks array" which records whether the cell is blank
or not.

@<Compile the inner table array for column j@> =
	packaging_state save = EmitArrays::begin_bounded(RTTables::tcu_iname(&(t->columns[j])), K_value);

	table_column *tc = t->columns[j].column_identity;
	LOGIF(TABLES, "Compiling column: $C\n", tc);

	kind *K = Tables::Columns::get_kind(tc);
	int bits = 0; /* bitmap of some properties of the column */
	@<Write the bitmap and blank-offset words@>;

	int e = 0; /* which bit we're up to within the current byte of the blanks array */

	for (parse_node *cell = t->columns[j].entries->down; cell; cell = cell->next) {
		@<Write a cell value for the initial contents of this cell@>;
		@<Allocate one bit in the blanks array, if needed@>;
		words_used++;
	}
	int blank_count = t->blank_rows;
	if ((blank_count == 0) && (t->columns[j].entries->down == NULL)) blank_count = 1;
	for (int br = 0; br < blank_count; br++) {
		@<Write a cell value for a blank cell@>;
		@<Allocate one bit in the blanks array, if needed@>;
		words_used++;
	}
	@<Pad out the blanks array as needed@>;

	EmitArrays::end(save);
	LOGIF(TABLES, "Done column: $C\n", tc);

@ In this part of the code we're carefully keeping track of how much blank
array storage we need (perhaps none!), but not compiling it. The sole aim
is to make sure |blanks_array_hwm| has the correct value at the beginning of
each column needing blank bits.

@<Allocate one bit in the blanks array, if needed@> =
	if ((bits & TB_COLUMN_NOBLANKBITS) == 0) {
		e++; if ((e % 8) == 0) blanks_array_hwm++;
	}

@<Pad out the blanks array as needed@> =
	if ((bits & TB_COLUMN_NOBLANKBITS) == 0) {
		if ((e % 8) != 0) blanks_array_hwm++; /* pad out a partial byte with zero bits */
	}

@ The table column array begins with two words: a bitmap giving some minimal
idea of what can safely be done with values, and then an address within the
blanks bitmap array (if this is needed).

A weakness of this scheme occurs if column ID numbers ever grow large enough
to collide with the bits used here: at present, that would need 412 different
table column names, which is dangerously plausible. We should fix this.

The following flags are also defined in |Tables.i6t| and must agree with
the values given there.

@d TB_COLUMN_REAL			0x8000
@d TB_COLUMN_SIGNED			0x4000
@d TB_COLUMN_TOPIC			0x2000
@d TB_COLUMN_DONTSORTME		0x1000
@d TB_COLUMN_NOBLANKBITS	0x0800
@d TB_COLUMN_CANEXCHANGE	0x0400
@d TB_COLUMN_ALLOCATED		0x0200

@<Write the bitmap and blank-offset words@> =
	if (Kinds::Behaviour::can_exchange(K)) 					  bits += TB_COLUMN_CANEXCHANGE;
	if ((Kinds::Behaviour::uses_signed_comparisons(K)) ||
		 (Kinds::FloatingPoint::uses_floating_point(K)))	  bits += TB_COLUMN_SIGNED;
	if (Kinds::FloatingPoint::uses_floating_point(K)) 		  bits += TB_COLUMN_REAL;
	if (Kinds::Behaviour::uses_block_values(K)) 		      bits += TB_COLUMN_ALLOCATED;

	if ((K_understanding) && (Kinds::eq(K, K_understanding))) bits = TB_COLUMN_TOPIC;

	if (RTTables::requires_blanks_bitmap(K) == FALSE) 		  bits += TB_COLUMN_NOBLANKBITS;
	if (t->preserve_row_order_at_run_time) 					  bits += TB_COLUMN_DONTSORTME;

	inter_name *bits_iname = Hierarchy::make_iname_in(COLUMN_BITS_HL,
		RTTables::tcu_package(&(t->columns[j])));
	Emit::numeric_constant(bits_iname, (inter_ti) bits);
	EmitArrays::iname_entry(bits_iname);
	inter_name *identity_iname = Hierarchy::make_iname_in(COLUMN_IDENTITY_HL,
		RTTables::tcu_package(&(t->columns[j])));
	Emit::iname_constant(identity_iname, K_value, RTTableColumns::id_iname(tc));
	if (bits & TB_COLUMN_NOBLANKBITS) {
		EmitArrays::null_entry();
	} else {
		inter_name *blanks_iname = Hierarchy::make_iname_in(COLUMN_BLANKS_HL,
			RTTables::tcu_package(&(t->columns[j])));
		Emit::numeric_constant(blanks_iname, (inter_ti) blanks_array_hwm);
		EmitArrays::iname_entry(blanks_iname);
	}
	words_used += 2;

@ The cell can only contain a generic value in the case of column 1 of a table
used to define new kinds; in this case it doesn't matter what we write, but
|nothing| has the virtue of being typesafe.

@<Write a cell value for the initial contents of this cell@> =
	current_sentence = cell;
	if (Annotations::read_int(cell, table_cell_unspecified_ANNOT)) {
		@<Write a cell value for a blank cell@>;
	} else {
		#ifdef IF_MODULE
		if (bits & TB_COLUMN_TOPIC) {
			wording W = Node::get_text(cell);
			EmitArrays::generic_entry(CompileRvalues::compile_understanding(W));
		} else {
		#endif
			parse_node *val = Node::get_evaluation(cell);
			if (Specifications::is_kind_like(val)) EmitArrays::numeric_entry(0);
			else if (val == NULL) internal_error("Valueless cell");
			else CompileValues::to_array_entry_of_kind(val, K);
		#ifdef IF_MODULE
		}
		#endif
	}
	words_used++;

@ As we've noted, our storage for a cell is both the array value we write here
and also a separate bit in the blanks array. In practice, though, it's inefficient
to look up two parallel structures each time we want to access the cell. So a
blank cell is represented as both the value |TABLE_NOVALUE|, chosen so that it
is very unlikely ever to occur as a genuine table value (currently it's the
picturesque hexadecimal value |0xDEADCE11|), and also as a blank bit set in
the blanks array. This makes a negative check -- that something is not blank
-- very quick, since only in the very rare case when the value does coincide
with |TABLE_NOVALUE| do we need to check the blanks array. A positive check
necessarily takes longer, but this cannot be helped.

With some kinds it is possible to prove that |TABLE_NOVALUE| cannot be a legal
value, and then space in the blanks array isn't needed: this is when the
|TB_COLUMN_NOBLANKBITS| flag is set. These kinds include all enumerated kinds
and also object numbers. (The latter are enumerated in the Z-machine but not
in Glulx: however, |TABLE_NOVALUE| is so large a number that it can never be
an object reference value in any story file smaller than 3.5 GB, and in
practice I6 and I7 are not capable of generating story files above 2 GB in any
case.)

@<Write a cell value for a blank cell@> =
	if (t->fill_in_blanks == FALSE) EmitArrays::iname_entry(Hierarchy::find(TABLE_NOVALUE_HL));
	else DefaultValues::array_entry(K, EMPTY_WORDING, "table entry");

@<Compile the blanks bitmap table@> =
	for (int j=0; j<t->no_columns; j++) {
		table_column *tc = t->columns[j].column_identity;
		if (RTTables::requires_blanks_bitmap(Tables::Columns::get_kind(tc)) == FALSE)
			continue;
		inter_name *iname = Hierarchy::make_iname_in(COLUMN_BLANK_DATA_HL,
			RTTables::tcu_package(&(t->columns[j])));
		packaging_state save = EmitArrays::begin_byte(iname, K_number);
		int current_bit = 1, byte_so_far = 0;
		@<Compile blank bits for entries from the source text@>;
		@<Compile blank bits for additional blank rows@>;
		if (current_bit != 1) @<Ship the current byte of the blanks table@>;
		EmitArrays::end(save);
	}

@<Compile blank bits for entries from the source text@> =
	parse_node *cell;
	for (cell = t->columns[j].entries->down; cell; cell = cell->next) {
		if ((Annotations::read_int(cell, table_cell_unspecified_ANNOT))
			&& (t->fill_in_blanks == FALSE))
			byte_so_far += current_bit;
		current_bit = current_bit*2;
		if (current_bit == 256) @<Ship the current byte of the blanks table@>;
	}

@<Compile blank bits for additional blank rows@> =
	int k;
	for (k = 0; k < t->blank_rows; k++) {
		byte_so_far += current_bit;
		current_bit = current_bit*2;
		if (current_bit == 256) @<Ship the current byte of the blanks table@>;
	}

@<Ship the current byte of the blanks table@> =
	EmitArrays::numeric_entry((inter_ti) byte_so_far);
	byte_so_far = 0; current_bit = 1;

@<Compile metadata for the table@> =
	Hierarchy::apply_metadata_from_wording(RTTables::package(t),
		TABLE_NAME_MD_HL, t->compilation_data.name_for_metadata);
	inter_name *iname = Hierarchy::make_iname_in(TABLE_ID_HL, RTTables::package(t));
	Emit::numeric_constant(iname, 0);
	TEMPORARY_TEXT(S)
	WRITE_TO(S, "%+W", Node::get_text(t->headline_fragment));
	Hierarchy::apply_metadata(RTTables::package(t), TABLE_PNAME_MD_HL, S);
	DISCARD_TEXT(S)
	for (table_contribution *tc = t->table_created_at; tc; tc = tc->next) {
		package_request *R =
			Hierarchy::package_within(TABLE_CONTRIBUTION_HAP,
				RTTables::package(t));
		Hierarchy::apply_metadata_from_number(R, TABLE_CONTRIBUTION_AT_MD_HL,
			(inter_ti) Wordings::first_wn(Node::get_text(tc->source_table)));
	}
	Hierarchy::apply_metadata_from_number(RTTables::package(t),
		TABLE_ROWS_MD_HL, (inter_ti) Tables::get_no_rows(t));
	Hierarchy::apply_metadata_from_number(RTTables::package(t),
		TABLE_BLANK_ROWS_MD_HL, (inter_ti) t->blank_rows);
	if (Wordings::nonempty(t->blank_rows_for_each_text))
		Hierarchy::apply_metadata_from_raw_wording(RTTables::package(t),
			TABLE_BLANK_ROWS_FOR_MD_HL, t->blank_rows_for_each_text);
	if (t->first_column_by_definition) {
		Hierarchy::apply_metadata_from_number(RTTables::package(t),
			TABLE_DEFINES_MD_HL, 1);
		Hierarchy::apply_metadata_from_raw_wording(RTTables::package(t),
			TABLE_DEFINES_TEXT_MD_HL, Node::get_text(t->where_used_to_define));
		Hierarchy::apply_metadata_from_number(RTTables::package(t),
			TABLE_DEFINES_AT_MD_HL,
			(inter_ti) Wordings::first_wn(Node::get_text(t->where_used_to_define)));
	}

@ The issue here is whether the value |IMPROBABLE_VALUE| can, despite its
improbability, be valid for this kind. If we can prove that it is not, we
should return |FALSE|; if in any doubt, we must return |TRUE|.

=
int RTTables::requires_blanks_bitmap(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_object(K)) return FALSE;
	if (Kinds::Behaviour::is_an_enumeration(K)) return FALSE;
	return TRUE;
}

@h Compilation data for table column usages.
Each |table_column_usage| object contains this data:

=
typedef struct table_column_usage_compilation_data {
	struct table *owning_table;
	struct package_request *tcu_package;
	struct inter_name *tcu_iname; /* for the array holding this at run-time */
} table_column_usage_compilation_data;

table_column_usage_compilation_data RTTables::new_tcu_compilation_data(table *t) {
	table_column_usage_compilation_data tcucd;
	tcucd.owning_table = t;
	tcucd.tcu_package = NULL;
	tcucd.tcu_iname = NULL;
	return tcucd;
}

@ And each gives rise to a subpackage of the package for the table it appears in:

=
package_request *RTTables::tcu_package(table_column_usage *tcu) {
	if (tcu->compilation_data.tcu_package == NULL)
		tcu->compilation_data.tcu_package =
			Hierarchy::package_within(TABLE_COLUMN_USAGES_HAP,
				RTTables::package(tcu->compilation_data.owning_table));
	return tcu->compilation_data.tcu_package;
}

inter_name *RTTables::tcu_iname(table_column_usage *tcu) {
	if (tcu->compilation_data.tcu_iname == NULL)
		tcu->compilation_data.tcu_iname =
			Hierarchy::make_iname_in(COLUMN_DATA_HL, RTTables::tcu_package(tcu));
	return tcu->compilation_data.tcu_iname;
}

@h Kinds as tables.

=
table *RTTables::table_defining_this(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->named_values_created_with_table;
}

void RTTables::defines(table *t, kind *K) {
	if (K == NULL) internal_error("no such kind");
	K->construct->named_values_created_with_table = t;
}
