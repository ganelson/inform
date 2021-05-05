[SynopticInstances::] Instances.

To compile the main/synoptic/instances submodule.

@ Before this runs, instance packages are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed a list |instance_nodes|
of packages of type |_instance|.

This section is a placeholder for now.

=
void SynopticInstances::compile(inter_tree *I, inter_tree_location_list *instance_nodes) {
	if (TreeLists::len(instance_nodes) > 0) {
		TreeLists::sort(instance_nodes, Synoptic::module_order);
	}
}
