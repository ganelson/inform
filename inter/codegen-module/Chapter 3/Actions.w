[SynopticActions::] Actions.

To renumber the actions and construct suitable functions and arrays.

@ Before this runs, action packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |action_nodes|
of packages of type |_action|.

@ The access possibilities for the noun and second are as follows:

@d UNRESTRICTED_ACCESS 1 /* question not meaningful, e.g. for a number */
@d DOESNT_REQUIRE_ACCESS 2 /* actor need not be able to touch this object */
@d REQUIRES_ACCESS 3 /* actor must be able to touch this object */
@d REQUIRES_POSSESSION 4 /* actor must be carrying this object */


=
void SynopticActions::renumber(inter_tree *I, inter_tree_location_list *action_nodes) {
	if (TreeLists::len(action_nodes) > 0) {
		TreeLists::sort(action_nodes, SynopticActions::cmp);
		for (int i=0; i<TreeLists::len(action_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(action_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"action_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
			D = Synoptic::get_optional_definition(pack, I"var_id");
			if (D) D->W.data[DATA_CONST_IFLD+1] = (inter_ti) (20000 + i);
		}
	}
}

int SynopticActions::cmp(const void *ent1, const void *ent2) {
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

@e CCOUNT_ACTION_NAME_SYNID
@e ACTIONCODING_SYNID
@e ACTIONDATA_SYNID
@e ACTIONHAPPENED_SYNID
@e AD_RECORDS_SYNID
@e DB_ACTION_DETAILS_SYNID

=
int SynopticActions::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case CCOUNT_ACTION_NAME_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define CCOUNT_ACTION_NAME@>;
			break;
		case ACTIONCODING_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIONCODING array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIONDATA_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_table_array(con_s, &IBM);
			@<Define the new ACTIONDATA array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ACTIONHAPPENED_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new ACTIONHAPPENED array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case AD_RECORDS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define AD_RECORDS@>;
			break;
		case DB_ACTION_DETAILS_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the DB_ACTION_DETAILS function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Define CCOUNT_ACTION_NAME@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(action_nodes), &IBM);

@<Define the new ACTIONCODING array as Q@> =
	for (int i=0; i<TreeLists::len(action_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(action_nodes->list[i].node);
		inter_symbol *double_sharp_s = Metadata::read_optional_symbol(pack, I"^double_sharp");
		inter_ti no = Metadata::read_optional_numeric(pack, I"^no_coding");
		if ((no) || (double_sharp_s == NULL)) Synoptic::numeric_entry(Q, 0);
		else Synoptic::symbol_entry(Q, double_sharp_s);
	}

@<Define the new ACTIONHAPPENED array as Q@> =
	for (int i=0; i<=(TreeLists::len(action_nodes)/16); i++)
		Synoptic::numeric_entry(Q, 0);

@<Define the new ACTIONDATA array as Q@> =
	for (int i=0; i<TreeLists::len(action_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(action_nodes->list[i].node);
		inter_symbol *double_sharp_s = Metadata::read_optional_symbol(pack, I"^double_sharp");
		if (double_sharp_s == NULL) {
			Synoptic::numeric_entry(Q, 0);
			Synoptic::numeric_entry(Q, 0);
			Synoptic::numeric_entry(Q, 0);
			Synoptic::numeric_entry(Q, 0);
			Synoptic::numeric_entry(Q, 0);
		} else {
			Synoptic::symbol_entry(Q, double_sharp_s);
			inter_ti out_of_world = Metadata::read_numeric(pack, I"^out_of_world");
			inter_ti requires_light = Metadata::read_numeric(pack, I"^requires_light");
			inter_ti can_have_noun = Metadata::read_numeric(pack, I"^can_have_noun");
			inter_ti can_have_second = Metadata::read_numeric(pack, I"^can_have_second");
			inter_ti noun_access = Metadata::read_numeric(pack, I"^noun_access");
			inter_ti second_access = Metadata::read_numeric(pack, I"^second_access");
			inter_symbol *noun_kind = Metadata::read_symbol(pack, I"^noun_kind");
			inter_symbol *second_kind = Metadata::read_symbol(pack, I"^second_kind");
			int mn = 0, ms = 0, ml = 0, mnp = 1, msp = 1, hn = 0, hs = 0;
			if (requires_light) ml = 1;
			if (noun_access == REQUIRES_ACCESS) mn = 1;
			if (second_access == REQUIRES_ACCESS) ms = 1;
			if (noun_access == REQUIRES_POSSESSION) { mn = 1; hn = 1; }
			if (second_access == REQUIRES_POSSESSION) { ms = 1; hs = 1; }
			if (can_have_noun == 0) mnp = 0;
			if (can_have_second == 0) msp = 0;
			inter_ti bitmap = (inter_ti) (mn + ms*0x02 + ml*0x04 + mnp*0x08 +
				msp*0x10 + (out_of_world?1:0)*0x20 + hn*0x40 + hs*0x80);
			Synoptic::numeric_entry(Q, bitmap);
			Synoptic::symbol_entry(Q, noun_kind);
			Synoptic::symbol_entry(Q, second_kind);
			inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
			if (vc_s) Synoptic::symbol_entry(Q, vc_s);
			else Synoptic::numeric_entry(Q, 0);
		}
		Synoptic::numeric_entry(Q, (inter_ti) (20000 + i));
	}

@<Define AD_RECORDS@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(action_nodes), &IBM);

@<Add a body of code to the DB_ACTION_DETAILS function@> =
	inter_symbol *act_s = Synoptic::get_local(I, I"act");
	inter_symbol *n_s = Synoptic::get_local(I, I"n");
	inter_symbol *s_s = Synoptic::get_local(I, I"s");
	inter_symbol *for_say_s = Synoptic::get_local(I, I"for_say");
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, act_s);
		Produce::code(I);
		Produce::down(I);

	for (int i=0; i<TreeLists::len(action_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(action_nodes->list[i].node);
		inter_symbol *double_sharp_s = Metadata::read_optional_symbol(pack, I"^double_sharp");
		if (double_sharp_s) {
			inter_symbol *debug_fn_s = Metadata::read_symbol(pack, I"^debug_fn");
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, double_sharp_s);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_call(I, debug_fn_s);
					Produce::down(I);
						Produce::val_symbol(I, K_value, n_s);
						Produce::val_symbol(I, K_value, s_s);
						Produce::val_symbol(I, K_value, for_say_s);					
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		}
	}

		Produce::up(I);
	Produce::up(I);
