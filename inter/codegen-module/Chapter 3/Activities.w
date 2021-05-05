[SynopticActivities::] Activities.

To renumber the activities and construct suitable functions and arrays.

@ Before this runs, activity packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |activity_nodes|
of packages of type |_activity|.

=
void SynopticActivities::compile(inter_tree *I, inter_tree_location_list *activity_nodes) {
	if (TreeLists::len(activity_nodes) > 0) {
		TreeLists::sort(activity_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(activity_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"activity_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
			D = Synoptic::get_optional_definition(pack, I"var_id");
			if (D) D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (10000 + i);
		}
	}
	@<Define ACTIVITY_AFTER_RULEBOOKS array@>;
	@<Define ACTIVITY_ATB_RULEBOOKS array@>;
	@<Define ACTIVITY_BEFORE_RULEBOOKS array@>;
	@<Define ACTIVITY_FOR_RULEBOOKS array@>;
	@<Define ACTIVITY_VAR_CREATORS array@>;
}

@<Define ACTIVITY_AFTER_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::find(I, ACTIVITY_AFTER_RULEBOOKS_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^after_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_ATB_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::find(I, ACTIVITY_ATB_RULEBOOKS_HL);
	Produce::annotate_iname_i(iname, BYTEARRAY_IANN, 1);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_ti ubf = Metadata::read_numeric(pack, I"^used_by_future");
		Synoptic::numeric_entry(ubf);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_BEFORE_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::find(I, ACTIVITY_BEFORE_RULEBOOKS_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^before_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_FOR_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::find(I, ACTIVITY_FOR_RULEBOOKS_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^for_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_VAR_CREATORS array@> =
	inter_name *iname = HierarchyLocations::find(I, ACTIVITY_VAR_CREATORS_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
		if (vc_s) Synoptic::symbol_entry(vc_s);
		else Synoptic::numeric_entry(0);
	}
	Synoptic::end_array(I);
