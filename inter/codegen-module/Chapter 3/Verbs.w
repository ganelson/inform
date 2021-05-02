[SynopticVerbs::] Verbs.

To construct suitable functions and arrays for verbs.

@ Before this runs, instances of these are scattered all over the Inter tree.

As this is called, //Synoptic Utilities// has already formed lists of |verb_form_nodes|
of instances having the kind |K_verb|.

=
void SynopticVerbs::renumber(inter_tree *I) {
	if (TreeLists::len(verb_form_nodes) > 0) {
		TreeLists::sort(verb_form_nodes, SynopticVerbs::form_order);
	}
}

int SynopticVerbs::form_order(const void *ent1, const void *ent2) {
	itl_entry *E1 = (itl_entry *) ent1;
	itl_entry *E2 = (itl_entry *) ent2;
	if (E1 == E2) return 0;
	inter_tree_node *P1 = E1->node;
	inter_tree_node *P2 = E2->node;
	inter_package *mod1 = Synoptic::module_containing(P1);
	inter_package *mod2 = Synoptic::module_containing(P2);
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

@ There is also one resource to create in the |synoptic| module:

@e TABLEOFVERBS_SYNID

=
int SynopticVerbs::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case TABLEOFVERBS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new TABLEOFVERBS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		default: return FALSE;
	}
	return TRUE;
}

@<Define the new TABLEOFVERBS array as Q@> =
	for (int i=0; i<TreeLists::len(verb_form_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(verb_form_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^verb_value");
		Synoptic::symbol_entry(Q, vc_s);
	}
	Synoptic::numeric_entry(Q, 0);
