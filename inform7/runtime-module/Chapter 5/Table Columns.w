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
	int translated;
	struct text_stream *translated_name;
	struct inter_name *translated_iname;
} table_column_compilation_data;

table_column_compilation_data RTTableColumns::new_compilation_data(table_column *tc) {
	table_column_compilation_data tccd;
	tccd.where_from = current_sentence;
	tccd.tc_package = NULL;
	tccd.id_iname = NULL;
	tccd.translated = FALSE;
	tccd.translated_name = NULL;
	tccd.translated_iname = NULL;
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

inter_name *RTTableColumns::id_translated(table_column *tc) {
	if (Str::len(tc->compilation_data.translated_name) == 0) return NULL;
	if (tc->compilation_data.translated_iname == NULL) {
		tc->compilation_data.translated_iname = InterNames::explicitly_named(
			tc->compilation_data.translated_name, RTTableColumns::package(tc));
		Hierarchy::make_available(tc->compilation_data.translated_iname);
	}
	return tc->compilation_data.translated_iname;
}

void RTTableColumns::translate(table_column *tc, wording W) {
	if (tc->compilation_data.translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatesTableColumnAlready),
			"this table column has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	tc->compilation_data.translated = TRUE;
	tc->compilation_data.translated_name = Str::new();
	WRITE_TO(tc->compilation_data.translated_name, "%N", Wordings::first_wn(W));
}

@h Compilation of table columns.
Column IDs will be numbers at runtime, but we can't allocate them here, because
they need to be unique across the whole program. So we compile references only
to the column-ID constant, and let the linker choose a value for that.

=
void RTTableColumns::compile(void) {
	table_column *tc;
	LOOP_OVER(tc, table_column) {
		package_request *pack = RTTableColumns::package(tc);
		Emit::numeric_constant(RTTableColumns::id_iname(tc), 0); /* placeholder value */
		inter_name *kind_iname = Hierarchy::make_iname_in(TABLE_COLUMN_KIND_MD_HL, pack);
		RTKindIDs::define_constant_as_strong_id(kind_iname, Tables::Columns::get_kind(tc));
		Hierarchy::apply_metadata_from_raw_wording(pack,
			TABLE_COLUMN_NAME_MD_HL, Nouns::nominative_singular(tc->name));
		TEMPORARY_TEXT(conts)
		Kinds::Textual::write_plural(conts, Tables::Columns::get_kind(tc));
		Hierarchy::apply_metadata(pack, TABLE_COLUMN_CONTENTS_MD_HL, conts);
		DISCARD_TEXT(conts)
		inter_name *translated = RTTableColumns::id_translated(tc);
		if (translated) Emit::iname_constant(translated, K_value, RTTableColumns::id_iname(tc));
	}
}
