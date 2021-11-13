[SynopticChronology::] Chronology.

To compile the main/synoptic/chronology submodule.

@ The purpose of all this is to keep track of the state of things so that it
will be possible in future to ask questions concerning the past.

Before this runs, past tense action and condition packages are scattered all
over the Inter tree. Each needs its own set of unique IDs.

=
void SynopticChronology::compile(inter_tree *I, tree_inventory *inv) {
	if (TreeLists::len(inv->action_history_condition_nodes) > 0) {
		TreeLists::sort(inv->action_history_condition_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->action_history_condition_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->action_history_condition_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"ahc_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
	if (TreeLists::len(inv->past_tense_condition_nodes) > 0) {
		TreeLists::sort(inv->past_tense_condition_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(inv->past_tense_condition_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(inv->past_tense_condition_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"ptc_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}

	@<Define NO_PAST_TENSE_CONDS@>;
	@<Define NO_PAST_TENSE_ACTIONS@>;
	
	@<Define TIMEDEVENTSTABLE@>;
	@<Define TIMEDEVENTTIMESTABLE@>;
	
	@<Define PASTACTIONSI6ROUTINES@>;
	@<Define TESTSINGLEPASTSTATE@>;
}

@<Define NO_PAST_TENSE_CONDS@> =
	inter_name *iname = HierarchyLocations::find(I, NO_PAST_TENSE_CONDS_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) TreeLists::len(inv->past_tense_condition_nodes));

@<Define NO_PAST_TENSE_ACTIONS@> =
	inter_name *iname = HierarchyLocations::find(I, NO_PAST_TENSE_ACTIONS_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) TreeLists::len(inv->action_history_condition_nodes));

@<Define TIMEDEVENTSTABLE@> =
	inter_name *iname = HierarchyLocations::find(I, TIMEDEVENTSTABLE_HL);
	Produce::annotate_iname_i(iname, TABLEARRAY_IANN, 1);
	Synoptic::begin_array(I, iname);
	int when_count = 0;
	for (int i=0; i<TreeLists::len(inv->rule_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->rule_nodes->list[i].node);
		if (Metadata::exists(pack, I"^timed")) {
			inter_symbol *rule_s = Metadata::read_symbol(pack, I"^value");
			if (Metadata::exists(pack, I"^timed_for")) {
				Synoptic::symbol_entry(rule_s);
			} else when_count++;
		}
	}
	for (int i=0; i<when_count+1; i++) {
		Synoptic::numeric_entry(0);
		Synoptic::numeric_entry(0);
	}	
	Synoptic::end_array(I);

@<Define TIMEDEVENTTIMESTABLE@> =
	inter_name *iname = HierarchyLocations::find(I, TIMEDEVENTTIMESTABLE_HL);
	Produce::annotate_iname_i(iname, TABLEARRAY_IANN, 1);
	Synoptic::begin_array(I, iname);
	int when_count = 0;
	for (int i=0; i<TreeLists::len(inv->rule_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->rule_nodes->list[i].node);
		if (Metadata::exists(pack, I"^timed")) {
			if (Metadata::exists(pack, I"^timed_for")) {
				inter_ti t = Metadata::read_optional_numeric(pack, I"^timed_for");
				Synoptic::numeric_entry(t);
			} else when_count++;
		}
	}
	for (int i=0; i<when_count+1; i++) {
		Synoptic::numeric_entry(0);
		Synoptic::numeric_entry(0);
	}
	Synoptic::end_array(I);

@<Define PASTACTIONSI6ROUTINES@> =
	inter_name *iname = HierarchyLocations::find(I, PASTACTIONSI6ROUTINES_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(inv->action_history_condition_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->action_history_condition_nodes->list[i].node);
		inter_symbol *fn_s = Metadata::read_symbol(pack, I"^value");
		if (fn_s == NULL) internal_error("no pap_fn");
		Synoptic::symbol_entry(fn_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define TESTSINGLEPASTSTATE@> =
	inter_name *iname = HierarchyLocations::find(I, TESTSINGLEPASTSTATE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *past_flag_s = Synoptic::local(I, I"past_flag", NULL);
	inter_symbol *pt_s = Synoptic::local(I, I"pt", NULL);
	inter_symbol *turn_end_s = Synoptic::local(I, I"turn_end", NULL);
	inter_symbol *wanted_s = Synoptic::local(I, I"wanted", NULL);
	inter_symbol *old_s = Synoptic::local(I, I"old", NULL);
	inter_symbol *new_s = Synoptic::local(I, I"new", NULL);
	inter_symbol *trips_s = Synoptic::local(I, I"trips", NULL);
	inter_symbol *consecutives_s = Synoptic::local(I, I"consecutives", NULL);

	if (TreeLists::len(inv->past_tense_condition_nodes) > 0) {
		inter_symbol *prcr_s = InterNames::to_symbol(HierarchyLocations::find(I, PRESENT_CHRONOLOGICAL_RECORD_HL));
		inter_symbol *pacr_s = InterNames::to_symbol(HierarchyLocations::find(I, PAST_CHRONOLOGICAL_RECORD_HL));

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
	} else {
		Produce::rfalse(I);
	}

	Synoptic::end_function(I, iname);

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
		Produce::reference(I);
		Produce::down(I);
			Produce::inv_primitive(I, LOOKUP_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, prcr_s);
				Produce::val_symbol(I, K_value, pt_s);
			Produce::up(I);
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
			for (int i=0; i<TreeLists::len(inv->past_tense_condition_nodes); i++) {
				inter_package *pack = Inter::Package::defined_by_frame(inv->past_tense_condition_nodes->list[i].node);
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
								Produce::inv_primitive(I, PLUS_BIP); /* +1 counting the current turn */
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
