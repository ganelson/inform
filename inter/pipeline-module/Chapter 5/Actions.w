[SynopticActions::] Actions.

To compile the main/synoptic/actions submodule.

@ Our inventory |inv| already contains a list |inv->action_nodes| of all packages
in the tree with type |_action|.

=
void SynopticActions::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->action_nodes) > 0) @<Assign unique action ID numbers@>;
	@<Define CCOUNT_ACTION_NAME@>;
	@<Define AD_RECORDS@>;
	if (InterNodeList::array_len(inv->action_nodes) > 0) {
		@<Define ACTIONHAPPENED array@>;
		@<Define ACTIONCODING array@>;
		@<Define ACTIONDATA array@>;
	}
	@<Define DB_ACTION_DETAILS function@>;
}

@ Each action package contains a numeric constant with the symbol name |action_id|.
We want to ensure that these ID numbers are contiguous from 0 and never duplicated,
so we change the values of these constants accordingly.

In addition, each action has an ID used to identify itself as the owner of a slate
of variables, and we set this to the action ID plus 20000. (This scheme assumes
there are never more than 10000 rules, or 10000 activities, or 10000 actions.)

@<Assign unique action ID numbers@> =
	InterNodeList::array_sort(inv->action_nodes, MakeSynopticModuleStage::module_order);
	for (int i=0; i<InterNodeList::array_len(inv->action_nodes); i++) {
		inter_package *pack =
			PackageInstruction::at_this_head(inv->action_nodes->list[i].node);
LOG("Spotted %d: $6\n", i, pack);
		inter_tree_node *D = Synoptic::get_definition(pack, I"action_id");
		ConstantInstruction::set_constant(D, InterValuePairs::number((inter_ti) i));
		D = Synoptic::get_optional_definition(pack, I"var_id");
		if (D) ConstantInstruction::set_constant(D,
			InterValuePairs::number((inter_ti) i+20000));
	}

@<Define CCOUNT_ACTION_NAME@> =
	inter_name *iname = HierarchyLocations::iname(I, CCOUNT_ACTION_NAME_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) InterNodeList::array_len(inv->action_nodes));

@<Define AD_RECORDS@> =
	inter_name *iname = HierarchyLocations::iname(I, AD_RECORDS_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) InterNodeList::array_len(inv->action_nodes));

@<Define ACTIONHAPPENED array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIONHAPPENED_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<=(InterNodeList::array_len(inv->action_nodes)/16); i++)
		Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define ACTIONCODING array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIONCODING_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->action_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->action_nodes->list[i].node);
		inter_symbol *double_sharp_s = Metadata::optional_symbol(pack, I"^double_sharp");
		inter_ti no = Metadata::read_optional_numeric(pack, I"^no_coding");
		if ((no) || (double_sharp_s == NULL)) Synoptic::numeric_entry(0);
		else Synoptic::symbol_entry(double_sharp_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@ The access possibilities for the noun and second are as follows:

@d UNRESTRICTED_ACCESS 1 /* question not meaningful, e.g. for a number */
@d DOESNT_REQUIRE_ACCESS 2 /* actor need not be able to touch this object */
@d REQUIRES_ACCESS 3 /* actor must be able to touch this object */
@d REQUIRES_POSSESSION 4 /* actor must be carrying this object */

@<Define ACTIONDATA array@> =
	inter_name *iname = HierarchyLocations::iname(I, ACTIONDATA_HL);
	Synoptic::begin_bounded_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->action_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->action_nodes->list[i].node);
		inter_symbol *double_sharp_s = Metadata::optional_symbol(pack, I"^double_sharp");
		if (Metadata::read_optional_numeric(pack, I"^action_assimilated")) {
			if (double_sharp_s) Synoptic::symbol_entry(double_sharp_s);
			else Synoptic::numeric_entry(0);
			Synoptic::numeric_entry(0x38); /* out of world, can have noun, can have second */
			Synoptic::numeric_entry(0);
			Synoptic::numeric_entry(0);
			Synoptic::numeric_entry(0);
		} else {
			Synoptic::symbol_entry(double_sharp_s);
			inter_ti out_of_world = Metadata::read_numeric(pack, I"^out_of_world");
			inter_ti requires_light = Metadata::read_numeric(pack, I"^requires_light");
			inter_ti can_have_noun = Metadata::read_numeric(pack, I"^can_have_noun");
			inter_ti can_have_second = Metadata::read_numeric(pack, I"^can_have_second");
			inter_ti noun_access = Metadata::read_numeric(pack, I"^noun_access");
			inter_ti second_access = Metadata::read_numeric(pack, I"^second_access");
			inter_symbol *noun_kind = Metadata::required_symbol(pack, I"^noun_kind");
			inter_symbol *second_kind = Metadata::required_symbol(pack, I"^second_kind");
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
			Synoptic::numeric_entry(bitmap);
			Synoptic::symbol_entry(noun_kind);
			Synoptic::symbol_entry(second_kind);
			inter_symbol *vc_s = Metadata::optional_symbol(pack, I"^var_creator");
			if (vc_s) Synoptic::symbol_entry(vc_s);
			else Synoptic::numeric_entry(0);
		}
		Synoptic::numeric_entry((inter_ti) (20000 + i));
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define DB_ACTION_DETAILS function@> =
	inter_name *iname = HierarchyLocations::iname(I, DB_ACTION_DETAILS_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *act_s = Synoptic::local(I, I"act", NULL);
	inter_symbol *n_s = Synoptic::local(I, I"n", NULL);
	inter_symbol *s_s = Synoptic::local(I, I"s", NULL);
	inter_symbol *for_say_s = Synoptic::local(I, I"for_say", NULL);
	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, act_s);
		Produce::code(I);
		Produce::down(I);

	for (int i=0; i<InterNodeList::array_len(inv->action_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->action_nodes->list[i].node);
		inter_symbol *debug_fn_s = Metadata::optional_symbol(pack, I"^debug_fn");
		inter_symbol *double_sharp_s = Metadata::optional_symbol(pack, I"^double_sharp");
		if (double_sharp_s) {
			Produce::inv_primitive(I, CASE_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, double_sharp_s);
				Produce::code(I);
				Produce::down(I);
					if (debug_fn_s) {
						Produce::inv_call_symbol(I, debug_fn_s);
						Produce::down(I);
							Produce::val_symbol(I, K_value, n_s);
							Produce::val_symbol(I, K_value, s_s);
							Produce::val_symbol(I, K_value, for_say_s);					
						Produce::up(I);
					} else {
						Produce::inv_primitive(I, PRINT_BIP);
						Produce::down(I);
							TEMPORARY_TEXT(S)
							WRITE_TO(S, "performing kit action %S",
								InterSymbol::identifier(double_sharp_s));
							Produce::val_text(I, S);
							DISCARD_TEXT(S)						
						Produce::up(I);
					}
				Produce::up(I);
			Produce::up(I);
		}
	}

		Produce::up(I);
	Produce::up(I);
	Synoptic::end_function(I, step, iname);
