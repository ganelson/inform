[SynopticDialogue::] Dialogue.

To compile the main/synoptic/dialogue submodule.

@ Our inventory |inv| already contains a list |inv->instance_nodes| of all packages
in the tree with type |_instance|.

For the moment, at least, it seems too ambitious to dynamically renumber instances
in the linking stage. Until then, this section is something of a placeholder,
making only a debugging function.

=
void SynopticDialogue::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->instance_nodes) > 0)
		InterNodeList::array_sort(inv->instance_nodes, MakeSynopticModuleStage::module_order);
	@<Define DIALOGUEBEATS array@>;
	@<Define DIALOGUELINES array@>;
}

@<Define DIALOGUEBEATS array@> =
	inter_ti count = 0;
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_beat")) count++;
	}
	
	inter_name *iname = HierarchyLocations::iname(I, DIALOGUEBEATS_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(count);
	if (count == 0) Synoptic::numeric_entry(0);
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_beat")) {
			inter_symbol *filter = Metadata::optional_symbol(pack, I"^available");
			if (filter) Synoptic::symbol_entry(filter);
			else Synoptic::numeric_entry(0);
			inter_symbol *rel = Metadata::optional_symbol(pack, I"^relevant");
			if (rel) Synoptic::symbol_entry(rel);
			else Synoptic::numeric_entry(0);
			inter_symbol *str = Metadata::optional_symbol(pack, I"^structure");
			if (str) Synoptic::symbol_entry(str);
			else Synoptic::numeric_entry(0);
		}
	}
	Synoptic::end_array(I);

@<Define DIALOGUELINES array@> =
	inter_ti count = 0;
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_line")) count++;
	}
	
	inter_name *iname = HierarchyLocations::iname(I, DIALOGUELINES_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(count);
	if (count == 0) Synoptic::numeric_entry(0);
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_line")) {
			inter_symbol *filter = Metadata::optional_symbol(pack, I"^line_data");
			if (filter) Synoptic::symbol_entry(filter);
			else internal_error("no line data");
		}
	}
	Synoptic::end_array(I);
