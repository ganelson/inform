[SynopticInstances::] Instances.

To compile the main/synoptic/instances submodule.

@ Before this runs, instance packages are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed a list |instance_nodes|
of packages of type |_instance|.

This section is a placeholder for now.

=
void SynopticInstances::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->instance_nodes) > 0) {
		TreeLists::sort(inv->instance_nodes, Synoptic::module_order);
	}
	@<Define SHOWMEINSTANCEDETAILS function@>
}

@<Define SHOWMEINSTANCEDETAILS function@> =
	inter_name *iname = HierarchyLocations::find(I, SHOWMEINSTANCEDETAILS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *which_s = Synoptic::local(I, I"which", NULL);
	inter_symbol *na_s = Synoptic::local(I, I"na", NULL);
	inter_symbol *t_0_s = Synoptic::local(I, I"t_0", NULL);
	for (int i=0; i<TreeLists::len(inv->instance_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->instance_nodes->list[i].node);
		inter_symbol *showme_s = Metadata::read_optional_symbol(pack, I"^showme_fn");
		if (showme_s) {
			Produce::inv_primitive(I, STORE_BIP);
			Produce::down(I);
				Produce::ref_symbol(I, K_value, na_s);
				Produce::inv_call(I, showme_s);
				Produce::down(I);
					Produce::val_symbol(I, K_value, which_s);
					Produce::val_symbol(I, K_value, na_s);
					Produce::val_symbol(I, K_value, t_0_s);
				Produce::up(I);
			Produce::up(I);
		}
	}	
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);		
		Produce::val_symbol(I, K_value, na_s);
	Produce::up(I);		
	Synoptic::end_function(I, iname);
