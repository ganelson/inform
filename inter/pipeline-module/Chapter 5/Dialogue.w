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
	@<Define DIALOGUECHOICES array@>;
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
			inter_symbol *filter = Metadata::optional_symbol(pack, I"^beat_data");
			if (filter) Synoptic::symbol_entry(filter);
			else internal_error("no beat data");
		}
	}
	Synoptic::end_array(I);

	Produce::numeric_constant(I, HierarchyLocations::iname(I, NO_DIALOGUE_BEATS_HL),
		K_value, (inter_ti) count);

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

	Produce::numeric_constant(I, HierarchyLocations::iname(I, NO_DIALOGUE_LINES_HL),
		K_value, (inter_ti) count);

@<Define DIALOGUECHOICES array@> =
	inter_ti count = 0;
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_choice")) count++;
	}
	
	inter_name *iname = HierarchyLocations::iname(I, DIALOGUECHOICES_HL);
	Synoptic::begin_array(I, step, iname);
	Synoptic::numeric_entry(count);
	if (count == 0) Synoptic::numeric_entry(0);
	for (int i=0; i<InterNodeList::array_len(inv->instance_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack, I"^is_dialogue_choice")) {
			inter_symbol *filter = Metadata::optional_symbol(pack, I"^choice_data");
			if (filter) Synoptic::symbol_entry(filter);
			else internal_error("no line data");
		}
	}
	Synoptic::end_array(I);

	Produce::numeric_constant(I, HierarchyLocations::iname(I, NO_DIALOGUE_CHOICES_HL),
		K_value, (inter_ti) count);
