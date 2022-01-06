[SynopticVerbs::] Verbs.

To compile the main/synoptic/verbs submodule.

@ Our inventory |inv| already contains a list |inv->verb_form_nodes| of all packages
in the tree with type |_verb_form|.

=
void SynopticVerbs::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (TreeLists::len(inv->verb_form_nodes) > 0)
		TreeLists::sort(inv->verb_form_nodes, SynopticVerbs::form_order);	
	@<Define TABLEOFVERBS array@>;
}

@ Note that we sort these in a special order: by source category first (i.e., source
text, then built-in extensions, then other extensions) and then in order of creation
within the compiler. This doesn't vastly matter, though.

=
int SynopticVerbs::form_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = MakeSynopticModuleStage::module_containing(P1);
	inter_package *mod2 = MakeSynopticModuleStage::module_containing(P2);
	inter_ti C1 = Metadata::read_optional_numeric(mod1, I"^category");
	inter_ti C2 = Metadata::read_optional_numeric(mod2, I"^category");
	int d = ((int) C2) - ((int) C1); /* larger values sort earlier */
	if (d != 0) return d;
	
	inter_ti S1 = Metadata::read_optional_numeric(Inter::Packages::container(P1), I"^verb_sorting");
	inter_ti S2 = Metadata::read_optional_numeric(Inter::Packages::container(P2), I"^verb_sorting");
	d = ((int) S1) - ((int) S2); /* smaller values sort earlier */
	if (d != 0) return d;
		
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

@<Define TABLEOFVERBS array@> =
	inter_name *iname = HierarchyLocations::find(I, TABLEOFVERBS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<TreeLists::len(inv->verb_form_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->verb_form_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^verb_value");
		Synoptic::symbol_entry(vc_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);
