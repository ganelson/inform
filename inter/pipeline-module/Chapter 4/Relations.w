[SynopticRelations::] Relations.

To compile the main/synoptic/relations submodule.

@ Before this runs, relation packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |relation_nodes|
of packages of type |_relation|.

=
void SynopticRelations::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->relation_nodes) > 0) {
		TreeLists::sort(inv->relation_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->relation_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"relation_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
	@<Define CCOUNT_BINARY_PREDICATE@>;
	@<Define CREATEDYNAMICRELATIONS function@>;
	@<Define ITERATERELATIONS function@>;
	@<Define RPROPERTY function@>;
}

@<Define CCOUNT_BINARY_PREDICATE@> =
	inter_name *iname = HierarchyLocations::find(I, CCOUNT_BINARY_PREDICATE_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(inv->relation_nodes)));

@<Define CREATEDYNAMICRELATIONS function@> =
	inter_name *iname = HierarchyLocations::find(I, CREATEDYNAMICRELATIONS_HL);
	Synoptic::begin_function(I, iname);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->relation_nodes->list[i].node);
		inter_symbol *creator_s = Metadata::read_optional_symbol(pack, I"^creator");
		if (creator_s) Produce::inv_call(I, creator_s);
	}
	Synoptic::end_function(I, iname);

@<Define ITERATERELATIONS function@> =
	inter_name *iname = HierarchyLocations::find(I, ITERATERELATIONS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *callback_s = Synoptic::local(I, I"callback", NULL);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->relation_nodes->list[i].node);
		inter_symbol *rel_s = Metadata::read_optional_symbol(pack, I"^value");
		if (rel_s) {
			Produce::inv_primitive(I, INDIRECT1V_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, callback_s);
				Produce::val_symbol(I, K_value, rel_s);
			Produce::up(I);
		}
	}
	Synoptic::end_function(I, iname);

@<Define RPROPERTY function@> =
	inter_name *iname = HierarchyLocations::find(I, RPROPERTY_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *obj_s = Synoptic::local(I, I"obj", NULL);
	inter_symbol *cl_s = Synoptic::local(I, I"cl", NULL);
	inter_symbol *pr_s = Synoptic::local(I, I"pr", NULL);
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
					inter_symbol *OBJECT_TY_s = EmitInterSchemas::find_identifier_text(I, I"OBJECT_TY", NULL, NULL);
					Produce::val_symbol(I, K_value, OBJECT_TY_s);
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
	Synoptic::end_function(I, iname);
