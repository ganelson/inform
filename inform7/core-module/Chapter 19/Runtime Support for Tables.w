[Tables::Support::] Runtime Support for Tables.

To compile run-time data structures holding tables.

@h Compiling tables.

=
void Tables::Support::compile(void) {
	@<Compile the data structures for entry storage@>;
	@<Compile the blanks bitmap table@>;
	@<Compile the Table of Tables@>;
	Tables::Columns::compile_run_time_support();
}

@<Compile the data structures for entry storage@> =
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	int blanks_array_hwm = 0; /* the high water mark of storage used in the blanks array */
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE)
			@<Compile the run-time storage for the table@>;
	END_COMPILATION_MODE;

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
	packaging_state save = Emit::named_table_array_begin(Tables::identifier(t), K_value);
	for (int j=0; j<t->no_columns; j++) {
		Emit::array_iname_entry(t->columns[j].tcu_iname);
	}
	Emit::array_end(save);
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
	packaging_state save = Emit::named_table_array_begin(t->columns[j].tcu_iname, K_value);

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

	Emit::array_end(save);
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
	if (Kinds::Behaviour::can_exchange(K)) 						bits += TB_COLUMN_CANEXCHANGE;
	if ((Kinds::Behaviour::uses_signed_comparisons(K)) ||
		 (Kinds::FloatingPoint::uses_floating_point(K)))		bits += TB_COLUMN_SIGNED;
	if (Kinds::FloatingPoint::uses_floating_point(K)) 			bits += TB_COLUMN_REAL;
	if (Kinds::Behaviour::uses_pointer_values(K)) 				bits += TB_COLUMN_ALLOCATED;

	if ((K_understanding) && (Kinds::Compare::eq(K, K_understanding)))  bits = TB_COLUMN_TOPIC;

	if (Kinds::Behaviour::requires_blanks_bitmap(K) == FALSE) 	bits += TB_COLUMN_NOBLANKBITS;
	if (t->preserve_row_order_at_run_time) 						bits += TB_COLUMN_DONTSORTME;

	Emit::array_numeric_entry((inter_t) (Tables::Columns::get_id(tc) + bits));
	if (bits & TB_COLUMN_NOBLANKBITS)
		Emit::array_null_entry();
	else
		Emit::array_numeric_entry((inter_t) blanks_array_hwm);
	words_used += 2;

@ The cell can only contain a generic value in the case of column 1 of a table
used to define new kinds; in this case it doesn't matter what we write, but
|nothing| has the virtue of being typesafe.

@<Write a cell value for the initial contents of this cell@> =
	current_sentence = cell;
	if (ParseTree::int_annotation(cell, table_cell_unspecified_ANNOT)) {
		@<Write a cell value for a blank cell@>;
	} else {
		#ifdef IF_MODULE
		if (bits & TB_COLUMN_TOPIC) {
			inter_t v1 = 0, v2 = 0;
			PL::Parsing::compile_understanding(&v1, &v2, ParseTree::get_text(cell), TRUE);
			Emit::array_generic_entry(v1, v2);
		} else {
		#endif
			parse_node *val = ParseTree::get_evaluation(cell);
			if (Specifications::is_kind_like(val)) Emit::array_numeric_entry(0);
			else if (val == NULL) internal_error("Valueless cell");
			else Specifications::Compiler::emit_constant_to_kind(val, K);
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
	if (t->fill_in_blanks == FALSE) Emit::array_iname_entry(Hierarchy::find(TABLE_NOVALUE_HL));
	else Kinds::RunTime::emit_default_value(K, EMPTY_WORDING, "table entry");

@<Compile the blanks bitmap table@> =
	inter_name *iname = Hierarchy::find(TB_BLANKS_HL);
	packaging_state save = Emit::named_byte_array_begin(iname, K_number);
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			current_sentence = t->table_created_at->source_table;
			for (int j=0; j<t->no_columns; j++) {
				table_column *tc = t->columns[j].column_identity;
				if (Kinds::Behaviour::requires_blanks_bitmap(Tables::Columns::get_kind(tc)) == FALSE)
					continue;
				int current_bit = 1, byte_so_far = 0;
				@<Compile blank bits for entries from the source text@>;
				@<Compile blank bits for additional blank rows@>;
				if (current_bit != 1) @<Ship the current byte of the blanks table@>;
			}
		}
	Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);

@<Compile blank bits for entries from the source text@> =
	parse_node *cell;
	for (cell = t->columns[j].entries->down; cell; cell = cell->next) {
		if ((ParseTree::int_annotation(cell, table_cell_unspecified_ANNOT))
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
	Emit::array_numeric_entry((inter_t) byte_so_far);
	byte_so_far = 0; current_bit = 1;

@ We need a default value for the "table" kind, but it's not obvious what
it should be. So |TheEmptyTable| is a stunted form of the above data
structure: a table with no columns and no rows, which would otherwise be
against the rules. (The Template file "Tables.i6t" defines it.)

@<Compile the Table of Tables@> =
	inter_name *iname = Hierarchy::find(TABLEOFTABLES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	Emit::array_iname_entry(Hierarchy::find(EMPTY_TABLE_HL));
	table *t;
	LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			Emit::array_iname_entry(Tables::identifier(t));
		}
	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);

@ The following allows tables to be said: it's a routine which switches on
table values and prints the (title-cased) name of the one which matches.

=
void Tables::Support::compile_print_table_names(void) {
	table *t;
	inter_name *iname = Kinds::Behaviour::get_iname(K_table);
	packaging_state save = Routines::begin(iname);
	inter_symbol *T_s = LocalVariables::add_named_call_as_symbol(I"T");
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, T_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_table, Hierarchy::find(THEEMPTYTABLE_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						Produce::val_text(Emit::tree(), I"(the empty table)");
					Produce::up(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

		LOOP_OVER(t, table)
		if (t->amendment_of == FALSE) {
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_table, Tables::identifier(t));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						TEMPORARY_TEXT(S);
						WRITE_TO(S, "%+W", ParseTree::get_text(t->headline_fragment));
						Produce::val_text(Emit::tree(), S);
						DISCARD_TEXT(S);
					Produce::up(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}

			Produce::inv_primitive(Emit::tree(), DEFAULT_BIP);
			Produce::down(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Produce::down(Emit::tree());
						Produce::val_text(Emit::tree(), I"** No such table **");
					Produce::up(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);
}
