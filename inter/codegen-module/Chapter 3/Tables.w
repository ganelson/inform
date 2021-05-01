[SynopticTables::] Tables.

To renumber the tables and construct suitable functions and arrays.

@ Before this runs, table packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |table_nodes|
of packages of type |_table|.

=
void SynopticTables::renumber(inter_tree *I, inter_tree_location_list *table_nodes) {
	if (TreeLists::len(table_nodes) > 0) {
		TreeLists::sort(table_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(table_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(table_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"table_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (i + 1);
		}
	}
	if (TreeLists::len(table_column_nodes) > 0) {
		TreeLists::sort(table_column_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(table_column_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(table_column_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"table_column_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (i + 100);
		}
	}
	if (TreeLists::len(table_column_usage_nodes) > 0) {
		TreeLists::sort(table_column_usage_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(table_column_usage_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(table_column_usage_nodes->list[i].node);
			inter_tree_node *ID = Synoptic::get_definition(pack, I"column_identity");
			inter_symbol *id_s = NULL;
			if (ID->W.data[DATA_CONST_IFLD] == ALIAS_IVAL)
				id_s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack), ID->W.data[DATA_CONST_IFLD+1]);
			if (id_s == NULL) internal_error("column_identity not an ALIAS_IVAL");
			ID = Inter::Symbols::definition(id_s);
			inter_tree_node *D = Synoptic::get_definition(pack, I"column_bits");
			D->W.data[DATA_CONST_IFLD+1] += ID->W.data[DATA_CONST_IFLD+1];
		}
	}
}

@ 

@e TABLEOFTABLES_SYNID
@e PRINT_TABLE_SYNID
@e TC_KOV_SYNID
@e TB_BLANKS_SYNID

=
int SynopticTables::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case TABLEOFTABLES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new TABLEOFTABLES array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case PRINT_TABLE_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the PRINT_TABLE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case TC_KOV_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the TC_KOV function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case TB_BLANKS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_byte_array(con_s, &IBM);
			@<Define the new TB_BLANKS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		default: return FALSE;
	}
	return TRUE;
}

@<Define the new TABLEOFTABLES array as Q@> =
	inter_symbol *empty_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), I"empty");
	if (empty_s == NULL) internal_error("not set up with empty");
	Synoptic::symbol_entry(Q, empty_s);
	for (int i=0; i<TreeLists::len(table_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(table_nodes->list[i].node);
		inter_symbol *value_s = Metadata::read_symbol(pack, I"^value");
		Synoptic::symbol_entry(Q, value_s);
	}
	Synoptic::numeric_entry(Q, 0);
	Synoptic::numeric_entry(Q, 0);

@<Add a body of code to the PRINT_TABLE function@> =
	inter_symbol *T_s = Synoptic::get_local(I, I"T");
	inter_symbol *empty_s = Synoptic::get_local(I, I"empty");
	if (empty_s == NULL) internal_error("not set up with empty");
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, T_s);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, empty_s);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, I"(the empty table)");
					Produce::up(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);

		for (int i=0; i<TreeLists::len(table_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(table_nodes->list[i].node);
			inter_symbol *value_s = Metadata::read_symbol(pack, I"^value");
			text_stream *printed_name = Metadata::read_textual(pack, I"^printed_name");
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, value_s);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, printed_name);
					Produce::up(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);
		}

			Produce::inv_primitive(I, DEFAULT_BIP);
			Produce::down(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, I"** No such table **");
					Produce::up(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

@<Add a body of code to the TC_KOV function@> =
	inter_symbol *tc_s = Synoptic::get_local(I, I"tc");
	inter_symbol *unk_s = Synoptic::get_local(I, I"unk");
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, tc_s);
		Produce::code(I);
		Produce::down(I);

	for (int i=0; i<TreeLists::len(table_column_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(table_column_nodes->list[i].node);
		inter_symbol *tc_kind = Metadata::read_symbol(pack, I"^column_kind");
		Produce::inv_primitive(I, CASE_BIP);
		Produce::down(I);
			Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) (i + 100));
			Produce::code(I);
			Produce::down(I);
				Produce::inv_primitive(I, RETURN_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, tc_kind);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	}

		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, unk_s);
	Produce::up(I);

@<Define the new TB_BLANKS array as Q@> =
	inter_ti hwm = 0;
	for (int i=0; i<TreeLists::len(table_column_usage_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(table_column_usage_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_optional_definition(pack, I"column_blanks");
		if (D) {
			D->W.data[DATA_CONST_IFLD+1] = hwm;
			inter_tree_node *B = Synoptic::get_definition(pack, I"^column_blank_data");
			for (int i=DATA_CONST_IFLD; i<B->W.extent; i=i+2) {
				Synoptic::numeric_entry(Q, B->W.data[i+1]);
				hwm++;
			}
		}
	}
	Synoptic::numeric_entry(Q, 0);
	Synoptic::numeric_entry(Q, 0);
