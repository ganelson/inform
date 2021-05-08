[SynopticProperties::] Properties.

To compile the main/synoptic/properties submodule.

@ Before this runs, property packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |property_nodes|
of packages of type |_activity|.

=
void SynopticProperties::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->property_nodes) > 0) {
		TreeLists::sort(inv->property_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->property_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->property_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"property_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
	@<Define CCOUNT_PROPERTY@>;
}

@<Define CCOUNT_PROPERTY@> =
	inter_name *iname = HierarchyLocations::find(I, CCOUNT_PROPERTY_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(inv->property_nodes)));
