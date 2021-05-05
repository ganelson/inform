[SynopticMultimedia::] Multimedia.

To compile the main/synoptic/multimedia submodule.

@ Before this runs, instances of figures, sounds and external files are scattered
all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed lists of |sound_nodes|
of instances having the kind |K_sound_name|, and so on.

=
void SynopticMultimedia::compile(inter_tree *I) {
	if (TreeLists::len(figure_nodes) > 0) {
		TreeLists::sort(figure_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(sound_nodes) > 0) {
		TreeLists::sort(sound_nodes, Synoptic::module_order);
	}
	if (TreeLists::len(file_nodes) > 0) {
		TreeLists::sort(file_nodes, Synoptic::module_order);
	}
	@<Define RESOURCEIDSOFFIGURES array@>;
	@<Define RESOURCEIDSOFSOUNDS array@>;
	@<Define NO_EXTERNAL_FILES@>;
	@<Define TABLEOFEXTERNALFILES array@>;
}

@<Define RESOURCEIDSOFFIGURES array@> =
	inter_name *iname = HierarchyLocations::find(I, RESOURCEIDSOFFIGURES_HL);
	Synoptic::begin_array(I, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(figure_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(figure_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(id);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define RESOURCEIDSOFSOUNDS array@> =
	inter_name *iname = HierarchyLocations::find(I, RESOURCEIDSOFSOUNDS_HL);
	Synoptic::begin_array(I, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(sound_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(sound_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(id);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define NO_EXTERNAL_FILES@> =
	inter_name *iname = HierarchyLocations::find(I, NO_EXTERNAL_FILES_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) TreeLists::len(file_nodes));

@<Define TABLEOFEXTERNALFILES array@> =
	inter_name *iname = HierarchyLocations::find(I, TABLEOFEXTERNALFILES_HL);
	Synoptic::begin_array(I, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(file_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(file_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^file_value");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);
