[SynopticRelations::] Relations.

To renumber the relations and construct suitable functions and arrays.

@ Before this runs, relation packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |relation_nodes|
of packages of type |_relation|.

=
void SynopticRelations::renumber(inter_tree *I, inter_tree_location_list *relation_nodes) {
	if (TreeLists::len(relation_nodes) > 0) {
		TreeLists::sort(relation_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(relation_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(relation_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"relation_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e CCOUNT_BINARY_PREDICATE_SYNID
@e CREATEDYNAMICRELATIONS_SYNID
@e ITERATERELATIONS_SYNID
@e RPROPERTY_SYNID

=
int SynopticRelations::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case CCOUNT_BINARY_PREDICATE_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define CCOUNT_BINARY_PREDICATE@>;
			break;
		case CREATEDYNAMICRELATIONS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the CREATEDYNAMICRELATIONS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case ITERATERELATIONS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the ITERATERELATIONS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case RPROPERTY_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the RPROPERTY function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Define CCOUNT_BINARY_PREDICATE@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(relation_nodes), &IBM);

@<Add a body of code to the CREATEDYNAMICRELATIONS function@> =
	for (int i=0; i<TreeLists::len(relation_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(relation_nodes->list[i].node);
		inter_symbol *creator_s = Metadata::read_optional_symbol(pack, I"^creator");
		if (creator_s) Produce::inv_call(I, creator_s);
	}

@<Add a body of code to the ITERATERELATIONS function@> =
	inter_symbol *callback_s = Synoptic::get_local(I, I"callback");
	for (int i=0; i<TreeLists::len(relation_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(relation_nodes->list[i].node);
		inter_symbol *rel_s = Metadata::read_symbol(pack, I"^value");
		Produce::inv_primitive(I, INDIRECT1V_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, callback_s);
			Produce::val_symbol(I, K_value, rel_s);
		Produce::up(I);
	}

@<Add a body of code to the RPROPERTY function@> =
	inter_symbol *obj_s = Synoptic::get_local(I, I"obj");
	inter_symbol *cl_s = Synoptic::get_local(I, I"cl");
	inter_symbol *pr_s = Synoptic::get_local(I, I"pr");
	Produce::inv_primitive(I, IF_BIP);
	Produce::down(I);
		Produce::inv_primitive(I, OFCLASS_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, obj_s);
			Produce::val_symbol(I, K_value, cl_s);
		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, RETURN_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, PROPERTYVALUE_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, obj_s);
					Produce::val_symbol(I, K_value, pr_s);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, LITERAL_IVAL, 0);
	Produce::up(I);
