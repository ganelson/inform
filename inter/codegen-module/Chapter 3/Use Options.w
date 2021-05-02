[SynopticUseOptions::] Use Options.

To renumber the properties and construct suitable functions and arrays.

@ As this is called, //Synoptic Utilities// has already formed a list |use_option_nodes|
of packages of type |_use_option|.

=
void SynopticUseOptions::renumber(inter_tree *I) {
	if (TreeLists::len(use_option_nodes) > 0) {
		TreeLists::sort(use_option_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(use_option_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(use_option_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"use_option_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e NO_USE_OPTIONS_SYNID
@e TESTUSEOPTION_SYNID
@e PRINT_USE_OPTION_SYNID

=
int SynopticUseOptions::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case NO_USE_OPTIONS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define NO_USE_OPTIONS@>;
			break;
		case TESTUSEOPTION_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the TESTUSEOPTION function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case PRINT_USE_OPTION_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the PRINT_USE_OPTION function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Define NO_USE_OPTIONS@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(use_option_nodes), &IBM);

@<Add a body of code to the TESTUSEOPTION function@> =
	inter_symbol *UO_s = Synoptic::get_local(I, I"UO");
	for (int i=0; i<TreeLists::len(use_option_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(use_option_nodes->list[i].node);
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		if (set) {
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, UO_s);
					Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) i);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);
		}
	}
	Produce::rfalse(I);

@<Add a body of code to the PRINT_USE_OPTION function@> =
	inter_symbol *UO_s = Synoptic::get_local(I, I"UO");
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, UO_s);
		Produce::code(I);
		Produce::down(I);
			for (int i=0; i<TreeLists::len(use_option_nodes); i++) {
				inter_package *pack = Inter::Package::defined_by_frame(use_option_nodes->list[i].node);
				text_stream *printed_name = Metadata::read_textual(pack, I"^printed_name");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) i);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, PRINT_BIP);
						Produce::down(I);
							Produce::val_text(I, printed_name);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		Produce::up(I);
	Produce::up(I);
