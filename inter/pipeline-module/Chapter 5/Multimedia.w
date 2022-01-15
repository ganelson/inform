[SynopticMultimedia::] Multimedia.

To compile the main/synoptic/multimedia submodule.

@ Our inventory |inv| already contains a list |inv->figure_nodes| of all packages
in the tree with type |_instance| which are of the kind |K_figure_name|, and
similarly for sounds and files. (These do not have ID numbers here because they
already have |instance_id| values by virtue of being instances. Resource ID
numbers are a little different, and are pooled between sounds and figures:
these are assigned by the //inform7// compiler, not here.)

=
void SynopticMultimedia::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->figure_nodes) > 0)
		TreeLists::sort(inv->figure_nodes, MakeSynopticModuleStage::module_order);
	if (TreeLists::len(inv->sound_nodes) > 0)
		TreeLists::sort(inv->sound_nodes, MakeSynopticModuleStage::module_order);
	if (TreeLists::len(inv->file_nodes) > 0)
		TreeLists::sort(inv->file_nodes, MakeSynopticModuleStage::module_order);
	@<Define RESOURCEIDSOFFIGURES array@>;
	@<Define RESOURCEIDSOFSOUNDS array@>;
	@<Define NO_EXTERNAL_FILES@>;
	@<Define TABLEOFEXTERNALFILES array@>;
}

@<Define RESOURCEIDSOFFIGURES array@> =
	inter_name *iname = HierarchyLocations::iname(I, RESOURCEIDSOFFIGURES_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(inv->figure_nodes); i++) {
		inter_package *pack =
			Inter::Package::defined_by_frame(inv->figure_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(id);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define RESOURCEIDSOFSOUNDS array@> =
	inter_name *iname = HierarchyLocations::iname(I, RESOURCEIDSOFSOUNDS_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(inv->sound_nodes); i++) {
		inter_package *pack =
			Inter::Package::defined_by_frame(inv->sound_nodes->list[i].node);
		inter_ti id = Metadata::read_numeric(pack, I"^resource_id");
		Synoptic::numeric_entry(id);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define NO_EXTERNAL_FILES@> =
	inter_name *iname = HierarchyLocations::iname(I, NO_EXTERNAL_FILES_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) TreeLists::len(inv->file_nodes));

@<Define TABLEOFEXTERNALFILES array@> =
	inter_name *iname =
		HierarchyLocations::iname(I, TABLEOFEXTERNALFILES_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(0);
	for (int i=0; i<TreeLists::len(inv->file_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->file_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^file_value");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);
