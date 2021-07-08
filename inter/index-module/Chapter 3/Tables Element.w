[TablesElement::] Tables Element.

To write the Tables element (Tb) in the index.

@h Indexing.
Tables inside extensions are often used just for the storage needed to manage
back-of-house algorithms, so to speak, and they aren't intended for the end
user to poke around with; that's certainly true of the tables in the Standard
Rules, which of course are always present. So these are hidden by default.

=
void TablesElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->table_nodes, Synoptic::category_order);

	inter_package *current_mod = NULL; int mc = 0, first_ext = TRUE;
	inter_ti cat = 1, open_cat = 0;
	for (inter_ti with_cat = 1; with_cat <= 3; with_cat++) {
		for (int i=0; i<TreeLists::len(inv->table_nodes); i++) {
			inter_package *mod = Synoptic::module_containing(inv->table_nodes->list[i].node);
			if (mod == NULL) continue;
			cat = Metadata::read_optional_numeric(mod, I"^category");
			if (cat == with_cat) {
				if ((mc == 0) || (mod != current_mod)) {
					@<Close block of tables@>;
					mc++; current_mod = mod;
					@<Open block of tables@>;
				}
				inter_package *pack = Inter::Package::defined_by_frame(inv->table_nodes->list[i].node);
				@<Index this table@>;
			}
		}
	}
	@<Close block of tables@>;
}

@<Open block of tables@> = 
	if (cat > 1) {
		if (first_ext) { 
			HTML_OPEN("p");
			IndexUtilities::extra_link(OUT, 2);
			if (mc > 1) WRITE("Show tables inside extensions too");
			else WRITE("Show tables inside extensions (there are none in the main text)");
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

@ The following probably ought to use a multiplication sign rather than a
Helvetica-style lower case "x", but life is full of compromises.

@<Index this table@> =
	HTML::first_html_column_spaced(OUT, 0);
	WRITE("<b>%S</b>", Metadata::read_textual(pack, I"^printed_name"));
	int ntc = 0;
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == PackageTypes::get(I, I"_table_contribution")) {
				if (ntc++ > 0) WRITE(" +");
				int at = (int) Metadata::read_optional_numeric(entry, I"^at");
				IndexUtilities::link(OUT, at);
			}
		}
	}
	HTML::next_html_column_spaced(OUT, 0);

	int nc = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == PackageTypes::get(I, I"_table_column_usage"))
				nc++;
		}
	}
	int nr = (int) Metadata::read_numeric(pack, I"^rows");
	int nb = (int) Metadata::read_numeric(pack, I"^blank_rows");
	int defines = (int) Metadata::read_optional_numeric(pack, I"^defines");
	text_stream *for_each = Metadata::read_optional_textual(pack, I"^blank_rows_for_each");

	WRITE("<i>");
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	if (defines) {
		WRITE("%d definition%s", nr, (nr == 1)?"":"s");
	} else {
		WRITE("%d column%s x %d row%s", nc, (nc == 1)?"":"s", nr, (nr == 1)?"":"s");
	}
	if (nb > 0) {
		WRITE(" (%d blank", nb);
		if (Str::len(for_each) > 0) WRITE(", one for each %S", for_each);
		WRITE(")");
	}
	HTML_CLOSE("span");
	WRITE("</i>");

	HTML::end_html_row(OUT);

	int col = 0;
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == PackageTypes::get(I, I"_table_column_usage")) {
				inter_tree_node *ID = Synoptic::get_definition(entry, I"column_identity");
				inter_symbol *id_s = NULL;
				if (ID->W.data[DATA_CONST_IFLD] == ALIAS_IVAL)
					id_s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(entry), ID->W.data[DATA_CONST_IFLD+1]);
				if (id_s == NULL) internal_error("column_identity not an ALIAS_IVAL");
				inter_package *col_pack = Inter::Packages::container(id_s->definition);
				HTML::first_html_column(OUT, 0);
				WRITE("&nbsp;&nbsp;col %d:&nbsp;&nbsp;", col+1);
				@<Give column details@>;
				HTML::next_html_column(OUT, 0);
				@<Give column 2 details@>;
				HTML::end_html_row(OUT);
				col++;
			}
		}
	}

@<Give column details@> =
	text_stream *CW = Metadata::read_optional_textual(col_pack, I"^name");
	if ((defines) && (col == 0)) {
		WRITE("%S", Metadata::read_optional_textual(pack, I"^defines_text"));
		int at = (int) Metadata::read_optional_numeric(pack, I"^defines_at");
		IndexUtilities::link(OUT, at);
	} else {
		if (defines) WRITE("<i>sets</i> ");
		WRITE("%S&nbsp;", CW);
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP, "%S", CW);
		if (defines == FALSE) WRITE_TO(TEMP, " entry");
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
	}

@<Give column 2 details@> =
	if ((defines) && (col == 0)) {
		WRITE("<i>names</i>");
	} else if (defines) {
		WRITE("%S property", Metadata::read_optional_textual(col_pack, I"^contents"));
	} else {
		WRITE("of %S", Metadata::read_optional_textual(col_pack, I"^contents"));
	}
