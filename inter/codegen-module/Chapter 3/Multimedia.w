[SynopticMultimedia::] Multimedia.

To construct suitable functions and arrays for figures, sounds, and external files.

@ Before this runs, instances of these are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed lists of |sound_nodes|
of instances having the kind |K_sound_name|, and so on.

=
void SynopticMultimedia::renumber(inter_tree *I) {
	if (TreeLists::len(figure_nodes) > 0) {
		TreeLists::sort(figure_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(sound_nodes) > 0) {
		TreeLists::sort(sound_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(file_nodes) > 0) {
		TreeLists::sort(file_nodes, Synoptic::module_order);
	}
}

@ There are also resources to create in the |synoptic| module:

@e RESOURCEIDSOFFIGURES_SYNID
@e RESOURCEIDSOFSOUNDS_SYNID
@e NO_EXTERNAL_FILES_SYNID
@e TABLEOFEXTERNALFILES_SYNID

=
int SynopticMultimedia::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case RESOURCEIDSOFFIGURES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new RESOURCEIDSOFFIGURES array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case RESOURCEIDSOFSOUNDS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new RESOURCEIDSOFSOUNDS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case NO_EXTERNAL_FILES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define NO_EXTERNAL_FILES@>;
			break;
		case TABLEOFEXTERNALFILES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new TABLEOFEXTERNALFILES array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		default: return FALSE;
	}
	return TRUE;
}

@<Define the new RESOURCEIDSOFFIGURES array as Q@> =
	Synoptic::numeric_entry(Q, 0);
	for (int i=0; i<TreeLists::len(figure_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(figure_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(Q, id);
	}
	Synoptic::numeric_entry(Q, 0);

@<Define the new RESOURCEIDSOFSOUNDS array as Q@> =
	Synoptic::numeric_entry(Q, 0);
	for (int i=0; i<TreeLists::len(sound_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(sound_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(Q, id);
	}
	Synoptic::numeric_entry(Q, 0);

@<Define NO_EXTERNAL_FILES@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(file_nodes), &IBM);

@<Define the new TABLEOFEXTERNALFILES array as Q@> =
	Synoptic::numeric_entry(Q, 0);
	for (int i=0; i<TreeLists::len(file_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(file_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^file_value");
		Synoptic::symbol_entry(Q, vc_s);
	}
	Synoptic::numeric_entry(Q, 0);
