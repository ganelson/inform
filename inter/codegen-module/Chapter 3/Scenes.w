[SynopticScenes::] Scenes.

To renumber the scenes and construct suitable functions and arrays.

@ Before this runs, instances of scenes are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed a list |scene_nodes|
of instances having the kind |K_scene|.

=
void SynopticScenes::renumber(inter_tree *I, inter_tree_location_list *scene_nodes) {
	if (TreeLists::len(scene_nodes) > 0) {
		TreeLists::sort(scene_nodes, Synoptic::module_order);
//		for (int i=0; i<TreeLists::len(scene_nodes); i++) {
//			inter_package *pack = Inter::Package::defined_by_frame(scene_nodes->list[i].node);
//			text_stream *name = Metadata::read_optional_textual(pack, I"^name");
//			LOG("scene %d: %S\n", i, name);
//		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e SHOWSCENESTATUS_SYNID
@e DETECTSCENECHANGE_SYNID

=
int SynopticScenes::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case SHOWSCENESTATUS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SHOWSCENESTATUS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case DETECTSCENECHANGE_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the DETECTSCENECHANGE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Add a body of code to the SHOWSCENESTATUS function@> =
	for (int i=0; i<TreeLists::len(scene_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(scene_nodes->list[i].node);
		inter_symbol *ssf_s = Metadata::read_symbol(pack, I"^scene_status_fn");
		Produce::inv_call(I, ssf_s);
	}

@ There is one argument, |chs|: the number of iterations so far. Iterations
occur because each set of scene changes could change the circumstances in such
a way that other scene changes are now required (through external conditions,
not through anchors); we don't want this to lock up, so we will cap recursion.
Within the routine, a second local variable, |ch|, is a flag indicating
whether any change in status has or has not occurred.


@d MAX_SCENE_CHANGE_ITERATION 20

@<Add a body of code to the DETECTSCENECHANGE function@> =
	inter_symbol *chs_s = Synoptic::get_local(I, I"chs");
	inter_symbol *Again_l = Produce::reserve_label(I, I".Again");
	inter_symbol *CScene_l = Produce::reserve_label(I, I".CScene");
	Produce::place_label(I, Again_l);
	for (int i=0; i<TreeLists::len(scene_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(scene_nodes->list[i].node);
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
