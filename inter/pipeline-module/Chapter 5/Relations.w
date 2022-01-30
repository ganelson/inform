[SynopticRelations::] Relations.

To compile the main/synoptic/relations submodule.

@ Our inventory |inv| already contains a list |inv->relation_nodes| of all packages
in the tree with type |_relation|.

=
void SynopticRelations::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->relation_nodes) > 0) @<Assign unique relation ID numbers@>;
	@<Define CCOUNT_BINARY_PREDICATE@>;
	@<Define CREATEDYNAMICRELATIONS function@>;
	@<Define ITERATERELATIONS function@>;
	@<Define RPROPERTY function@>;
}

@ Each relation package contains a numeric constant with the symbol name |relation_id|.
We want to ensure that these ID numbers are contiguous from 0 and never duplicated,
so we change the values of these constants accordingly.

@<Assign unique relation ID numbers@> =
	TreeLists::sort(inv->relation_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = InterPackage::at_this_head(inv->relation_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"relation_id");
		D->W.instruction[DATA_CONST_IFLD+1] = (inter_ti) i;
	}

@<Define CCOUNT_BINARY_PREDICATE@> =
	inter_name *iname = HierarchyLocations::iname(I, CCOUNT_BINARY_PREDICATE_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(inv->relation_nodes)));

@<Define CREATEDYNAMICRELATIONS function@> =
	inter_name *iname = HierarchyLocations::iname(I, CREATEDYNAMICRELATIONS_HL);
	Synoptic::begin_function(I, iname);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = InterPackage::at_this_head(inv->relation_nodes->list[i].node);
		inter_symbol *creator_s = Metadata::read_optional_symbol(pack, I"^creator");
		if (creator_s) Produce::inv_call_symbol(I, creator_s);
	}
	Synoptic::end_function(I, step, iname);

@<Define ITERATERELATIONS function@> =
	inter_name *iname = HierarchyLocations::iname(I, ITERATERELATIONS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *callback_s = Synoptic::local(I, I"callback", NULL);
	for (int i=0; i<TreeLists::len(inv->relation_nodes); i++) {
		inter_package *pack = InterPackage::at_this_head(inv->relation_nodes->list[i].node);
		inter_symbol *rel_s = Metadata::read_optional_symbol(pack, I"^value");
		if (rel_s) {
			Produce::inv_primitive(I, INDIRECT1V_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, callback_s);
				Produce::val_symbol(I, K_value, rel_s);
			Produce::up(I);
		}
	}
	Synoptic::end_function(I, step, iname);

@<Define RPROPERTY function@> =
	inter_name *iname = HierarchyLocations::iname(I, RPROPERTY_HL);
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
					inter_symbol *OBJECT_TY_s =
						IdentifierFinders::find(I, I"OBJECT_TY",
							IdentifierFinders::common_names_only());
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
	Synoptic::end_function(I, step, iname);
