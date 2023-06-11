[SynopticUseOptions::] Use Options.

To compile the main/synoptic/use_options submodule.

@ Our inventory |inv| already contains a list |inv->use_option_nodes| of all packages
in the tree with type |_use_option|.

=
void SynopticUseOptions::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->use_option_nodes) > 0) @<Assign unique use option ID numbers@>;
	@<Define NO_USE_OPTIONS@>;
	@<Define TESTUSEOPTION function@>;
	@<Define PRINT_USE_OPTION function@>;
	@<Define USE_OPTION_VALUES array@>;
}

@ Each use option package contains a numeric constant with the symbol name
|use_option_id|. We want to ensure that these ID numbers are contiguous from 0
and never duplicated, so we change the values of these constants accordingly.

@<Assign unique use option ID numbers@> =
	InterNodeList::array_sort(inv->use_option_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<InterNodeList::array_len(inv->use_option_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->use_option_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"use_option_id");
		ConstantInstruction::set_constant(D, InterValuePairs::number((inter_ti) i));
	}

@<Define NO_USE_OPTIONS@> =
	inter_name *iname = HierarchyLocations::iname(I, NO_USE_OPTIONS_HL);
	Produce::numeric_constant(I, iname, K_value,
		(inter_ti) (InterNodeList::array_len(inv->use_option_nodes)));

@ A relatively late addition to the design of use options was to make them
values at runtime, of the kind "use option". We need to provide two functions:
one to test whether a given use option is currently set, one to print the
name of a given use option.

@<Define TESTUSEOPTION function@> =
	inter_name *iname = HierarchyLocations::iname(I, TESTUSEOPTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *UO_s = Synoptic::local(I, I"UO", NULL);
	for (int i=0; i<InterNodeList::array_len(inv->use_option_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->use_option_nodes->list[i].node);
		inter_ti set = Metadata::read_numeric(pack, I"^active");
		if (set) {
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, UO_s);
					Produce::val(I, K_value, InterValuePairs::number((inter_ti) i));
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);
		}
	}
	Produce::rfalse(I);
	Synoptic::end_function(I, step, iname);

@<Define PRINT_USE_OPTION function@> =
	inter_name *iname = HierarchyLocations::iname(I, PRINT_USE_OPTION_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *UO_s = Synoptic::local(I, I"UO", NULL);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, UO_s);
		Produce::code(I);
		Produce::down(I);
			for (int i=0; i<InterNodeList::array_len(inv->use_option_nodes); i++) {
				inter_package *pack =
					PackageInstruction::at_this_head(inv->use_option_nodes->list[i].node);
				text_stream *printed_name = Metadata::required_textual(pack, I"^printed_name");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val(I, K_value, InterValuePairs::number((inter_ti) i));
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
	Synoptic::end_function(I, step, iname);

@<Define USE_OPTION_VALUES array@> =
	inter_name *iname = HierarchyLocations::iname(I, USE_OPTION_VALUES_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->use_option_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->use_option_nodes->list[i].node);
		inter_ti cv = Metadata::read_numeric(pack, I"^configured_value");
		Synoptic::numeric_entry(cv);
	}
	Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);
