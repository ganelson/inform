[SynopticInstances::] Instances.

To renumber the instances and construct suitable functions and arrays.

@ Before this runs, instance packages are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed a list |instance_nodes|
of packages of type |_instance|.

=
void SynopticInstances::renumber(inter_tree *I, inter_tree_location_list *instance_nodes) {
	if (TreeLists::len(instance_nodes) > 0) {
		TreeLists::sort(instance_nodes, Synoptic::module_order);
//		for (int i=0; i<TreeLists::len(instance_nodes); i++) {
//			inter_package *pack = Inter::Package::defined_by_frame(instance_nodes->list[i].node);
//			inter_tree_node *D = Synoptic::get_definition(pack, I"scene_id");
//			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
//		}
	}
}
