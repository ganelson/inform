[SynopticScenes::] Scenes.

To compile the main/synoptic/scenes submodule.

@ Before this runs, instances of scenes are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed a list |scene_nodes|
of instances having the kind |K_scene|.

=
void SynopticScenes::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->scene_nodes) > 0) {
		TreeLists::sort(inv->scene_nodes, Synoptic::module_order);
	}
	@<Define SHOWSCENESTATUS function@>;
	@<Define DETECTSCENECHANGE function@>;
}

@<Define SHOWSCENESTATUS function@> =
	inter_name *iname = HierarchyLocations::find(I, SHOWSCENESTATUS_HL);
	Synoptic::begin_function(I, iname);
	for (int i=0; i<TreeLists::len(inv->scene_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->scene_nodes->list[i].node);
		inter_symbol *ssf_s = Metadata::read_symbol(pack, I"^scene_status_fn");
		Produce::inv_call(I, ssf_s);
	}
	Synoptic::end_function(I, iname);

@ There is one argument, |chs|: the number of iterations so far. Iterations
occur because each set of scene changes could change the circumstances in such
a way that other scene changes are now required (through external conditions,
not through anchors); we don't want this to lock up, so we will cap recursion.
Within the routine, a second local variable, |ch|, is a flag indicating
whether any change in status has or has not occurred.


@d MAX_SCENE_CHANGE_ITERATION 20

@<Define DETECTSCENECHANGE function@> =
	inter_name *iname = HierarchyLocations::find(I, DETECTSCENECHANGE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *chs_s = Synoptic::local(I, I"chs", NULL);
	inter_symbol *Again_l = Produce::reserve_label(I, I".Again");
	inter_symbol *CScene_l = Produce::reserve_label(I, I".CScene");
	Produce::place_label(I, Again_l);
	for (int i=0; i<TreeLists::len(inv->scene_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->scene_nodes->list[i].node);
		inter_symbol *scf_s = Metadata::read_symbol(pack, I"^scene_change_fn");
		Produce::inv_primitive(I, IF_BIP);
		Produce::down(I);
			Produce::inv_call(I, scf_s);
			Produce::code(I);
			Produce::down(I);
				Produce::inv_primitive(I, JUMP_BIP);
				Produce::down(I);
					Produce::lab(I, CScene_l);
				Produce::up(I);				
			Produce::up(I);
		Produce::up(I);
	}
	Produce::rfalse(I);

	Produce::place_label(I, CScene_l);

	Produce::inv_primitive(I, IF_BIP);
	Produce::down(I);
		Produce::inv_primitive(I, GT_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, chs_s);
			Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) MAX_SCENE_CHANGE_ITERATION);
		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, PRINT_BIP);
			Produce::down(I);
				Produce::val_text(I, I">--> The scene change machinery is stuck.\n");
			Produce::up(I);
			Produce::rtrue(I);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, PREINCREMENT_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, chs_s);
	Produce::up(I);
	Produce::inv_primitive(I, JUMP_BIP);
	Produce::down(I);
		Produce::lab(I, Again_l);
	Produce::up(I);				
	Synoptic::end_function(I, iname);