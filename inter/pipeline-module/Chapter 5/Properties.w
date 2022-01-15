[SynopticProperties::] Properties.

To compile the main/synoptic/properties submodule.

@ Our inventory |inv| already contains a list |inv->property_nodes| of all packages
in the tree with type |_property|.

=
void SynopticProperties::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->property_nodes) > 0) @<Assign unique property ID numbers@>;
	@<Define CCOUNT_PROPERTY@>;
}

@ Each property package contains a numeric constant with the symbol name |property_id|.
We want to ensure that these ID numbers are contiguous from 0 and never duplicated,
so we change the values of these constants accordingly.

@<Assign unique property ID numbers@> =
	TreeLists::sort(inv->property_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<TreeLists::len(inv->property_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->property_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"property_id");
		D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
	}

@<Define CCOUNT_PROPERTY@> =
	inter_name *iname = HierarchyLocations::iname(I, CCOUNT_PROPERTY_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(inv->property_nodes)));
