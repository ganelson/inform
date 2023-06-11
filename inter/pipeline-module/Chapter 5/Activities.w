[SynopticActivities::] Activities.

To compile the main/synoptic/activities submodule.

@ Our inventory |inv| already contains a list |inv->activity_nodes| of all packages
in the tree with type |_activity|.

=
void SynopticActivities::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->activity_nodes) > 0) @<Assign unique activity ID numbers@>;
	@<Define ACTIVITY_AFTER_RULEBOOKS array@>;
	@<Define ACTIVITY_BEFORE_RULEBOOKS array@>;
	@<Define ACTIVITY_FOR_RULEBOOKS array@>;
	@<Define ACTIVITY_VAR_CREATORS array@>;
	@<Define ACTIVITY_FLAGS array@>;
}

@ Each activity package contains a numeric constant with the symbol name |activity_id|.
We want to ensure that these ID numbers are contiguous from 0 and never duplicated,
so we change the values of these constants accordingly.

In addition, each activity has an ID used to identify itself as the owner of a slate
of variables, and we set this to the activity ID plus 10000. (This scheme assumes
there are never more than 10000 rules, or 10000 activities, or 10000 actions.)

@<Assign unique activity ID numbers@> =
	InterNodeList::array_sort(inv->activity_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"activity_id");
		ConstantInstruction::set_constant(D, InterValuePairs::number((inter_ti) i));
		D = Synoptic::get_optional_definition(pack, I"var_id");
		if (D) ConstantInstruction::set_constant(D,
			InterValuePairs::number((inter_ti) i+10000));
	}

@<Define ACTIVITY_AFTER_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIVITY_AFTER_RULEBOOKS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::required_symbol(pack, I"^after_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_BEFORE_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIVITY_BEFORE_RULEBOOKS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::required_symbol(pack, I"^before_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_FOR_RULEBOOKS array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIVITY_FOR_RULEBOOKS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::required_symbol(pack, I"^for_rulebook");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_VAR_CREATORS array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIVITY_VAR_CREATORS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::optional_symbol(pack, I"^var_creator");
		if (vc_s) Synoptic::symbol_entry(vc_s);
		else Synoptic::numeric_entry(0);
	}
	Synoptic::end_array(I);

@<Define ACTIVITY_FLAGS array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIVITY_FLAGS_HL);
	Synoptic::begin_byte_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->activity_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->activity_nodes->list[i].node);
		inter_ti flags = 0;
		if (Metadata::read_numeric(pack, I"^used_by_future")) flags += 1;
		if (Metadata::read_numeric(pack, I"^hide_in_debugging")) flags += 2;
		Synoptic::numeric_entry(flags);
	}
	Synoptic::end_array(I);
