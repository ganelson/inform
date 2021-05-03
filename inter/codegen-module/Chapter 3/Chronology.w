[SynopticChronology::] Chronology.

To construct suitable functions and arrays to manage past-tense references in code.

@ Before this runs, relation packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |relation_nodes|
of packages of type |_relation|.

=
void SynopticChronology::renumber(inter_tree *I, inter_tree_location_list *past_tense_action_nodes) {
	if (TreeLists::len(past_tense_action_nodes) > 0) {
		TreeLists::sort(past_tense_action_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(past_tense_action_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(past_tense_action_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"pap_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
	if (TreeLists::len(past_tense_condition_nodes) > 0) {
		TreeLists::sort(past_tense_condition_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(past_tense_condition_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(past_tense_condition_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"ptc_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}

	inter_name *iname = HierarchyLocations::find(I, NO_PAST_TENSE_CONDS_HL);
	SynopticChronology::numeric_constant(I, iname, (inter_ti) TreeLists::len(past_tense_condition_nodes));
}

inter_name *SynopticChronology::numeric_constant(inter_tree *I, inter_name *con_iname, inter_ti val) {
	packaging_state save = Packaging::enter_home_of(con_iname);
	inter_symbol *con_s = Produce::define_symbol(con_iname);
	Produce::guard(Inter::Constant::new_numerical(Packaging::at(I),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), con_s),
		InterSymbolsTables::id_from_IRS_and_symbol(Packaging::at(I), unchecked_kind_symbol),
		LITERAL_IVAL, val, Produce::baseline(Packaging::at(I)), NULL));
	Packaging::exit(I, save);
	return con_iname;
}

@ There are also resources to create in the |synoptic| module:

@e TIMEDEVENTSTABLE_SYNID
@e TIMEDEVENTTIMESTABLE_SYNID
@e PASTACTIONSI6ROUTINES_SYNID
@e NO_PAST_TENSE_CONDS_SYNID
@e NO_PAST_TENSE_ACTIONS_SYNID
@e TESTSINGLEPASTSTATE_SYNID

=
int SynopticChronology::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case TIMEDEVENTSTABLE_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define TIMEDEVENTSTABLE@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case TIMEDEVENTTIMESTABLE_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define TIMEDEVENTTIMESTABLE@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case PASTACTIONSI6ROUTINES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define PASTACTIONSI6ROUTINES@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case NO_PAST_TENSE_CONDS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define NO_PAST_TENSE_CONDS@>;
			break;
		case NO_PAST_TENSE_ACTIONS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define NO_PAST_TENSE_ACTIONS@>;
			break;
		case TESTSINGLEPASTSTATE_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the TESTSINGLEPASTSTATE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@ Timed events are stored in two simple arrays, processed by run-time code.

@<Define TIMEDEVENTSTABLE@> =
	int when_count = 0;
	for (int i=0; i<TreeLists::len(rule_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rule_nodes->list[i].node);
		if (Metadata::exists(pack, I"^timed")) {
			inter_symbol *rule_s = Metadata::read_symbol(pack, I"^value");
			if (Metadata::exists(pack, I"^timed_for")) {
				Synoptic::symbol_entry(Q, rule_s);
			} else when_count++;
		}
	}
	for (int i=0; i<when_count+1; i++) {
		Synoptic::numeric_entry(Q, 0);
		Synoptic::numeric_entry(Q, 0);
	}

@<Define TIMEDEVENTTIMESTABLE@> =
	int when_count = 0;
	for (int i=0; i<TreeLists::len(rule_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rule_nodes->list[i].node);
		if (Metadata::exists(pack, I"^timed")) {
			if (Metadata::exists(pack, I"^timed_for")) {
				inter_ti t = Metadata::read_optional_numeric(pack, I"^timed_for");
				Synoptic::numeric_entry(Q, t);
			} else when_count++;
		}
	}
	for (int i=0; i<when_count+1; i++) {
		Synoptic::numeric_entry(Q, 0);
		Synoptic::numeric_entry(Q, 0);
	}

@<Define PASTACTIONSI6ROUTINES@> =
	for (int i=0; i<TreeLists::len(past_tense_action_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(past_tense_action_nodes->list[i].node);
		inter_symbol *fn_s = Metadata::read_symbol(pack, I"^value");
		if (fn_s == NULL) internal_error("no pap_fn");
		Synoptic::symbol_entry(Q, fn_s);
	}
	Synoptic::numeric_entry(Q, 0);
	Synoptic::numeric_entry(Q, 0);

@<Define NO_PAST_TENSE_CONDS@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(past_tense_condition_nodes), &IBM);

@<Define NO_PAST_TENSE_ACTIONS@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(past_tense_action_nodes), &IBM);

@<Add a body of code to the TESTSINGLEPASTSTATE function@> =
	inter_symbol *past_flag_s = Synoptic::get_local(I,I"past_flag");
	inter_symbol *pt_s = Synoptic::get_local(I,I"pt");
	inter_symbol *turn_end_s = Synoptic::get_local(I,I"turn_end");
	inter_symbol *wanted_s = Synoptic::get_local(I,I"wanted");
	inter_symbol *old_s = Synoptic::get_local(I,I"old");
	inter_symbol *new_s = Synoptic::get_local(I,I"new");
	inter_symbol *trips_s = Synoptic::get_local(I,I"trips");
	inter_symbol *consecutives_s = Synoptic::get_local(I,I"consecutives");
	inter_symbol *prcr_s = Synoptic::get_local(I,I"prcr");
	inter_symbol *pacr_s = Synoptic::get_local(I,I"pacr");
	Produce::inv_primitive(I, IFELSE_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, past_flag_s);
		Produce::code(I);
		Produce::down(I);
			@<Unpack the past@>;
		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			@<Unpack the present@>;
			@<Swizzle@>;
			@<Repack the present@>;
		Produce::up(I);
	Produce::up(I);
	@<Answer the question posed@>;

@<Unpack the past@> =
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, new_s);
		Produce::inv_primitive(I, BITWISEAND_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, LOOKUP_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, pacr_s);
				Produce::val_symbol(I, K_value, pt_s);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 1);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, trips_s);
		Produce::inv_primitive(I, DIVIDE_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, BITWISEAND_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, LOOKUP_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, pacr_s);
					Produce::val_symbol(I, K_value, pt_s);
				Produce::up(I);
				Produce::val(I, K_value, LITERAL_IVAL, 0xFE);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 2);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, consecutives_s);
		Produce::inv_primitive(I, DIVIDE_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, BITWISEAND_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, LOOKUP_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, pacr_s);
					Produce::val_symbol(I, K_value, pt_s);
				Produce::up(I);
				Produce::val(I, K_value, LITERAL_IVAL, 0xFF00);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 0x100);
		Produce::up(I);
	Produce::up(I);

@<Unpack the present@> =
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, old_s);
		Produce::inv_primitive(I, BITWISEAND_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, LOOKUP_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, prcr_s);
				Produce::val_symbol(I, K_value, pt_s);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 1);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, trips_s);
		Produce::inv_primitive(I, DIVIDE_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, BITWISEAND_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, LOOKUP_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, prcr_s);
					Produce::val_symbol(I, K_value, pt_s);
				Produce::up(I);
				Produce::val(I, K_value, LITERAL_IVAL, 0xFE);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 2);
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::ref_symbol(I, K_value, consecutives_s);
		Produce::inv_primitive(I, DIVIDE_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, BITWISEAND_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, LOOKUP_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, prcr_s);
					Produce::val_symbol(I, K_value, pt_s);
				Produce::up(I);
				Produce::val(I, K_value, LITERAL_IVAL, 0xFF00);
			Produce::up(I);
			Produce::val(I, K_value, LITERAL_IVAL, 0x100);
		Produce::up(I);
	Produce::up(I);

@<Repack the present@> =
	Produce::inv_primitive(I, STORE_BIP);
	Produce::down(I);
		Produce::inv_primitive(I, LOOKUPREF_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, prcr_s);
			Produce::val_symbol(I, K_value, pt_s);
		Produce::up(I);
		Produce::inv_primitive(I, PLUS_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, new_s);
			Produce::inv_primitive(I, PLUS_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, TIMES_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, trips_s);
					Produce::val(I, K_value, LITERAL_IVAL, 0x02);
				Produce::up(I);
				Produce::inv_primitive(I, TIMES_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, consecutives_s);
					Produce::val(I, K_value, LITERAL_IVAL, 0x100);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

@<Swizzle@> =
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, pt_s);
		Produce::code(I);
		Produce::down(I);
			for (int i=0; i<TreeLists::len(past_tense_condition_nodes); i++) {
				inter_package *pack = Inter::Package::defined_by_frame(past_tense_condition_nodes->list[i].node);
				inter_symbol *fn_s = Metadata::read_symbol(pack, I"^value");
				if (fn_s == NULL) internal_error("no pcon_fn");
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) i);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, STORE_BIP);
						Produce::down(I);
							Produce::ref_symbol(I, K_value, new_s);
							Produce::inv_call(I, fn_s);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
			Produce::inv_primitive(I, DEFAULT_BIP);
			Produce::down(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, I"*** No such past tense condition ***\n");
					Produce::up(I);
					Produce::inv_primitive(I, STORE_BIP);
					Produce::down(I);
						Produce::ref_symbol(I, K_value, new_s);
						Produce::val(I, K_value, LITERAL_IVAL, 0);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, IFELSE_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, new_s);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, old_s);
					Produce::val(I, K_value, LITERAL_IVAL, 0);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, POSTINCREMENT_BIP);
					Produce::down(I);
						Produce::ref_symbol(I, K_value, trips_s);
					Produce::up(I);
					Produce::inv_primitive(I, IF_BIP);
					Produce::down(I);
						Produce::inv_primitive(I, GT_BIP);
						Produce::down(I);
							Produce::val_symbol(I, K_value, trips_s);
							Produce::val(I, K_value, LITERAL_IVAL, 127);
						Produce::up(I);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_primitive(I, STORE_BIP);
							Produce::down(I);
								Produce::ref_symbol(I, K_value, trips_s);
								Produce::val(I, K_value, LITERAL_IVAL, 127);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);

			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, turn_end_s);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, POSTINCREMENT_BIP);
					Produce::down(I);
						Produce::ref_symbol(I, K_value, consecutives_s);
					Produce::up(I);
					Produce::inv_primitive(I, IF_BIP);
					Produce::down(I);
						Produce::inv_primitive(I, GT_BIP);
						Produce::down(I);
							Produce::val_symbol(I, K_value, consecutives_s);
							Produce::val(I, K_value, LITERAL_IVAL, 127);
						Produce::up(I);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_primitive(I, STORE_BIP);
							Produce::down(I);
								Produce::ref_symbol(I, K_value, consecutives_s);
								Produce::val(I, K_value, LITERAL_IVAL, 127);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);

		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, STORE_BIP);
			Produce::down(I);
				Produce::ref_symbol(I, K_value, consecutives_s);
				Produce::val(I, K_value, LITERAL_IVAL, 0);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

@<Answer the question posed@> =
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, wanted_s);
		Produce::code(I);
		Produce::down(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 0);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, IF_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, new_s);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_primitive(I, RETURN_BIP);
							Produce::down(I);
								Produce::val_symbol(I, K_value, new_s);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 1);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, IF_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, new_s);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_primitive(I, RETURN_BIP);
							Produce::down(I);
								Produce::val_symbol(I, K_value, trips_s);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 2);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, IF_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, new_s);
						Produce::code(I);
						Produce::down(I);
							Produce::inv_primitive(I, RETURN_BIP);
							Produce::down(I);
								Produce::inv_primitive(I, PLUS_BIP); /* Plus one because we count the current turn */
								Produce::down(I);
									Produce::val_symbol(I, K_value, consecutives_s);
									Produce::val(I, K_value, LITERAL_IVAL, 1);
								Produce::up(I);
							Produce::up(I);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 4);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, RETURN_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, new_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 5);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, RETURN_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, trips_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val(I, K_value, LITERAL_IVAL, 6);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, RETURN_BIP);
					Produce::down(I);
						Produce::val_symbol(I, K_value, consecutives_s);
					Produce::up(I);
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	Produce::up(I);

	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, LITERAL_IVAL, 0);
	Produce::up(I);
