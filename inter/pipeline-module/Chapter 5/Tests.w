[SynopticTests::] Tests.

To compile the main/synoptic/tests submodule.

@ As this is called, //Synoptic Utilities// has already formed a list of packages
of type |_test|.

=
void SynopticTests::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->test_nodes) > 0) {
		TreeLists::sort(inv->test_nodes, MakeSynopticModuleStage::module_order);
	}

	@<Define TESTSCRIPTSUB function@>;
}

@<Define TESTSCRIPTSUB function@> =
	inter_name *iname = HierarchyLocations::find(I, TESTSCRIPTSUB_HL);
	Synoptic::begin_function(I, iname);
	if (TreeLists::len(inv->test_nodes) == 0) {
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I">--> No test scripts exist for this game.\n");
		Produce::up(I);
	} else {
		Produce::inv_primitive(I, SWITCH_BIP);
		Produce::down(I);
			Produce::val_iname(I, K_value, HierarchyLocations::find(I, SPECIAL_WORD_HL));
			Produce::code(I);
			Produce::down(I);
				for (int i=0; i<TreeLists::len(inv->test_nodes); i++) {
					inter_package *pack = Inter::Package::defined_by_frame(inv->test_nodes->list[i].node);
					text_stream *name = Metadata::read_textual(pack, I"^name");
					inter_ti len = Metadata::read_numeric(pack, I"^length");
					inter_symbol *text_s = Synoptic::get_symbol(pack, I"script");
					inter_symbol *req_s = Synoptic::get_symbol(pack, I"requirements");
					Produce::inv_primitive(I, CASE_BIP);
					Produce::down(I);
						Produce::val_dword(I, name);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_call_iname(I, HierarchyLocations::find(I, TESTSTART_HL));
							Produce::down(I);
								Produce::val_symbol(I, K_value, text_s);
								Produce::val_symbol(I, K_value, req_s);
								Produce::val(I, K_value, LITERAL_IVAL, len);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				}
				Produce::inv_primitive(I, DEFAULT_BIP);
				Produce::down(I);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, PRINT_BIP);
						Produce::down(I);
							Produce::val_text(I, I">--> The following tests are available:\n");
						Produce::up(I);
						for (int i=0; i<TreeLists::len(inv->test_nodes); i++) {
							inter_package *pack =
								Inter::Package::defined_by_frame(inv->test_nodes->list[i].node);
							text_stream *name = Metadata::read_textual(pack, I"^name");
							TEMPORARY_TEXT(T)
							WRITE_TO(T, "'test %S'\n", name);
							Produce::inv_primitive(I, PRINT_BIP);
							Produce::down(I);
								Produce::val_text(I, T);
							Produce::up(I);
							DISCARD_TEXT(T)
						}
						Produce::inv_primitive(I, PRINT_BIP);
						Produce::down(I);
							Produce::val_text(I, I"\n");
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	}
	Synoptic::end_function(I, step, iname);
