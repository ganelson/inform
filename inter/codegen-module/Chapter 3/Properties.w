[SynopticProperties::] Properties.

To renumber the properties and construct suitable functions and arrays.

@ Before this runs, property packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |property_nodes|
of packages of type |_activity|.

=
void SynopticProperties::renumber(inter_tree *I, inter_tree_location_list *property_nodes) {
	if (TreeLists::len(property_nodes) > 0) {
		TreeLists::sort(property_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(property_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(property_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"property_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e CCOUNT_PROPERTY_SYNID

=
int SynopticProperties::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case CCOUNT_PROPERTY_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define CCOUNT_PROPERTY@>;
			break;
		default: return FALSE;
	}
	return TRUE;
}

@<Define CCOUNT_PROPERTY@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(property_nodes), &IBM);
