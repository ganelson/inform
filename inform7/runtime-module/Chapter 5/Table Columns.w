[RTTableColumns::] Table Columns.

To compile the table_columns submodule for a compilation unit, which contains
_table_column packages.

@h Compilation data for table columns.
Each |table_column| object contains this data:

=
typedef struct table_column_compilation_data {
	struct parse_node *where_from;
	struct package_request *tc_package;
	struct inter_name *id_iname;
} table_column_compilation_data;

table_column_compilation_data RTTableColumns::new_compilation_data(table_column *tc) {
	table_column_compilation_data tccd;
	tccd.where_from = current_sentence;
	tccd.tc_package = NULL;
	tccd.id_iname = NULL;
	return tccd;
}

package_request *RTTableColumns::package(table_column *tc) {
	if (tc->compilation_data.tc_package == NULL)
		tc->compilation_data.tc_package =
			Hierarchy::local_package_to(TABLE_COLUMNS_HAP, tc->compilation_data.where_from);
	return tc->compilation_data.tc_package;
}

inter_name *RTTableColumns::id_iname(table_column *tc) {
	if (tc->compilation_data.id_iname == NULL)
		tc->compilation_data.id_iname =
			Hierarchy::make_iname_in(TABLE_COLUMN_ID_HL, RTTableColumns::package(tc));
	return tc->compilation_data.id_iname;
}

@h Compilation of table columns.
Column IDs will be numbers at runtime, but we can't allocate them here, because
they need to be unique across the whole program. So we compile references only
to the column-ID constant, and let the linker choose a value for that.

=
void RTTableColumns::compile(void) {
	table_column *tc;
	LOOP_OVER(tc, table_column) {
		Emit::numeric_constant(RTTableColumns::id_iname(tc), 0); /* placeholder value */
		inter_name *kind_iname = Hierarchy::make_iname_in(TABLE_COLUMN_KIND_MD_HL,
			RTTableColumns::package(tc));
		RTKindIDs::define_constant_as_strong_id(kind_iname, Tables::Columns::get_kind(tc));
	}
}
