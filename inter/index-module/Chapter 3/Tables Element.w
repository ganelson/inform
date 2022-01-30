[TablesElement::] Tables Element.

To write the Tables element (Tb) in the index.

@ This is arranged as a sequence of "blocks" of tables, where each block
corresponds to one of the compilation modules: thus, all the tables in the
main source text, all the tables in the Standard Rules, and so on.

=
void TablesElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->table_nodes, MakeSynopticModuleStage::category_order);

	inter_package *current_mod = NULL; int mc = 0, first_ext = TRUE;
	inter_ti cat = 1, open_cat = 0;
	for (inter_ti with_cat = 1; with_cat <= 3; with_cat++) {
		inter_package *table_pack;
		LOOP_OVER_INVENTORY_PACKAGES(table_pack, i, inv->table_nodes) {
			inter_package *mod = MakeSynopticModuleStage::module_containing(table_pack->package_head);
			if (mod) {
				cat = Metadata::read_optional_numeric(mod, I"^category");
				if (cat == with_cat) {
					if ((mc == 0) || (mod != current_mod)) {
						@<Close block of tables@>;
						mc++; current_mod = mod;
						@<Open block of tables@>;
					}
					@<Index this table@>;
				}
			}
		}
	}
	@<Close block of tables@>;
}

@ Tables inside extensions are often used just for the storage needed to manage
back-of-house algorithms, so to speak, and they aren't intended for the end
user to poke around with; that's certainly true of the tables in the Standard
Rules, which of course are always present. So these are hidden by default.

@<Open block of tables@> = 
	if (cat > 1) {
		if (first_ext) { 
			HTML_OPEN("p");
			IndexUtilities::extra_link(OUT, 2);
			if (mc > 1) Localisation::roman(OUT, LD, I"Index.Elements.Tb.ShowExtensionTables");
			else Localisation::roman(OUT, LD, I"Index.Elements.Tb.ShowOnlyExtensionTables");
			HTML_CLOSE("p");
			first_ext = FALSE;
		}
		IndexUtilities::extra_div_open(OUT, 2, 1, "e0e0e0");		
		HTML_OPEN("p");
		WRITE("<i>%S</i>", Metadata::read_textual(mod, I"^title"));
		HTML_CLOSE("p");
	}
	open_cat = cat;
	HTML::begin_plain_html_table(OUT);

@<Close block of tables@> =
	if (mc > 0) {
		HTML::end_html_table(OUT);
		if (open_cat > 1) IndexUtilities::extra_div_close(OUT, "e0e0e0");
	}

@<Index this table@> =
	int defines = (int) Metadata::read_optional_numeric(table_pack, I"^defines");
	@<Produce a row about the name and extent of the table@>;
	int col = 0;
	inter_package *usage_pack;
	LOOP_THROUGH_SUBPACKAGES(usage_pack, table_pack, I"_table_column_usage") {
		@<Produce a row for this table usage@>;
		col++;
	}

@<Produce a row about the name and extent of the table@> =
	HTML::first_html_column_spaced(OUT, 0);
	@<Table name column@>;
	HTML::next_html_column_spaced(OUT, 0);
	@<Table extent column@>;
	HTML::end_html_row(OUT);

@<Table name column@> =
	WRITE("<b>%S</b>", Metadata::read_textual(table_pack, I"^printed_name"));
	int ntc = 0;
	inter_package *cont_pack;
	LOOP_THROUGH_SUBPACKAGES(cont_pack, table_pack, I"_table_contribution") {
		if (ntc++ > 0) WRITE(" +");
		IndexUtilities::link_package(OUT, cont_pack);
	}

@<Table extent column@> =
	int nc = InterTree::no_subpackages(table_pack, I"_table_column_usage");
	int nr = (int) Metadata::read_numeric(table_pack, I"^rows");
	int nb = (int) Metadata::read_numeric(table_pack, I"^blank_rows");
	text_stream *for_each = Metadata::read_optional_textual(table_pack, I"^blank_rows_for_each");

	WRITE("<i>");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (defines) {
		if (nr == 1) Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Definition", nr);
		else Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Definitions", nr);
	} else {
		if (nc == 1) Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Column", nc);
		else Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Columns", nc);
		WRITE(" x ");
		if (nr == 1) Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Row", nr);
		else Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Rows", nr);
	}
	if (nb > 0) {
		WRITE(" (");
		Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Blank", nb);
		if (Str::len(for_each) > 0) {
			WRITE(", ");
			Localisation::roman_t(OUT, LD, I"Index.Elements.Tb.BlankEach", for_each);
		}
		WRITE(")");
	}
	HTML_CLOSE("span");
	WRITE("</i>");

@<Produce a row for this table usage@> =
	inter_tree_node *ID = Synoptic::get_definition(usage_pack, I"column_identity");
	inter_symbol *id_s = NULL;
	if (ID->W.instruction[DATA_CONST_IFLD] == ALIAS_IVAL)
		id_s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(usage_pack),
			ID->W.instruction[DATA_CONST_IFLD+1]);
	if (id_s == NULL) internal_error("column_identity not an ALIAS_IVAL");
	inter_package *col_pack = Inter::Packages::container(id_s->definition);
	HTML::first_html_column(OUT, 0);
	WRITE("&nbsp;&nbsp;");
	Localisation::roman_i(OUT, LD, I"Index.Elements.Tb.Col", col+1);
	WRITE(":&nbsp;&nbsp;");
	@<Give usage details@>;
	HTML::next_html_column(OUT, 0);
	@<Give purpose details@>;
	HTML::end_html_row(OUT);

@<Give usage details@> =
	text_stream *CW = Metadata::read_optional_textual(col_pack, I"^name");
	if ((defines) && (col == 0)) {
		WRITE("%S", Metadata::read_optional_textual(table_pack, I"^defines_text"));
		int at = (int) Metadata::read_optional_numeric(table_pack, I"^defines_at");
		IndexUtilities::link(OUT, at);
	} else {
		if (defines) {
			Localisation::italic(OUT, LD, I"Index.Elements.Tb.Sets");
			WRITE(" ");
		}
		WRITE("%S&nbsp;", CW);
		TEMPORARY_TEXT(TEMP)
		if (defines) WRITE_TO(TEMP, "%S", CW);
		else Localisation::roman_t(TEMP, LD, I"Index.Elements.Tb.Entry", CW);
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
	}

@<Give purpose details@> =
	if ((defines) && (col == 0)) {
		Localisation::italic(OUT, LD, I"Index.Elements.Tb.Names");
	} else if (defines) {
		Localisation::roman_t(OUT, LD, I"Index.Elements.Tb.Property",
			Metadata::read_optional_textual(col_pack, I"^contents"));
	} else {
		Localisation::roman_t(OUT, LD, I"Index.Elements.Tb.Of",
			Metadata::read_optional_textual(col_pack, I"^contents"));
	}
