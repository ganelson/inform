[SynopticActivities::] Activities.

To renumber the activities and construct suitable functions and arrays.

@ Before this runs, activity packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |activity_nodes|
of packages of type |_activity|.

=
void SynopticActivities::renumber(inter_tree *I, inter_tree_location_list *activity_nodes) {
	if (TreeLists::len(activity_nodes) > 0) {
		TreeLists::sort(activity_nodes, SynopticActivities::cmp);
		for (int i=0; i<TreeLists::len(activity_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"activity_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
			D = Synoptic::get_optional_definition(pack, I"var_id");
			if (D) D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (10000 + i);
		}
	}
}

int SynopticActivities::cmp(const void *ent1, const void *ent2) {
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
	return E1->sort_key - E2->sort_key; /* smaller values sort earlier */
}

@ There are also resources to create in the |synoptic| module:

@e ACTIVITY_AFTER_RULEBOOKS_SYNID
@e ACTIVITY_ATB_RULEBOOKS_SYNID
@e ACTIVITY_BEFORE_RULEBOOKS_SYNID
@e ACTIVITY_FOR_RULEBOOKS_SYNID
@e ACTIVITY_VAR_CREATORS_SYNID

=
int SynopticActivities::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case ACTIVITY_AFTER_RULEBOOKS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIVITY_AFTER_RULEBOOKS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIVITY_ATB_RULEBOOKS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_byte_array(con_s, &IBM);
			@<Define the new ACTIVITY_ATB_RULEBOOKS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIVITY_BEFORE_RULEBOOKS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIVITY_BEFORE_RULEBOOKS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIVITY_FOR_RULEBOOKS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIVITY_FOR_RULEBOOKS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIVITY_VAR_CREATORS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIVITY_VAR_CREATORS array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		default: return FALSE;
	}
	return TRUE;
}

@<Define the new ACTIVITY_AFTER_RULEBOOKS array as Q@> =
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^after_rulebook");
		Synoptic::symbol_entry(Q, vc_s);
	}

@<Define the new ACTIVITY_ATB_RULEBOOKS array as Q@> =
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_ti ubf = Metadata::read_numeric(pack, I"^used_by_future");
		Synoptic::numeric_entry(Q, ubf);
	}

@<Define the new ACTIVITY_BEFORE_RULEBOOKS array as Q@> =
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^before_rulebook");
		Synoptic::symbol_entry(Q, vc_s);
	}

@<Define the new ACTIVITY_FOR_RULEBOOKS array as Q@> =
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_symbol(pack, I"^for_rulebook");
		Synoptic::symbol_entry(Q, vc_s);
	}

@<Define the new ACTIVITY_VAR_CREATORS array as Q@> =
	for (int i=0; i<TreeLists::len(activity_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(activity_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
		if (vc_s) Synoptic::symbol_entry(Q, vc_s);
		else Synoptic::numeric_entry(Q, 0);
	}

