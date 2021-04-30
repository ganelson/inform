[SynopticRules::] Rules.

To renumber the rulebooks and construct suitable functions and arrays.

@ Before this runs, rulebook packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |rulebook_nodes|
of packages of type |_rulebook|.

=
void SynopticRules::renumber(inter_tree *I, inter_tree_location_list *rulebook_nodes) {
	if (TreeLists::len(rulebook_nodes) > 0) {
		TreeLists::sort(rulebook_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"rulebook_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
}

@ There are also resources to create in the |synoptic| module:

@e NUMBER_RULEBOOKS_CREATED_SYNID
@e RULEBOOKNAMES_SYNID
@e ECONOMY_RULEBOOKNAMES_SYNID
@e RULEBOOK_VAR_CREATORS_SYNID
@e SLOW_LOOKUP_SYNID
@e RULEBOOKS_ARRAY_SYNID
@e RULEPRINTINGRULE_SYNID
@e ECONOMY_RULEPRINTINGRULE_SYNID

=
int SynopticRules::redefine(inter_tree *I, inter_tree_node *P, inter_symbol *con_s, int synid) {
	inter_package *pack = Inter::Packages::container(P);
	inter_tree_node *Q = NULL;
	inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
	switch (synid) {
		case NUMBER_RULEBOOKS_CREATED_SYNID:
			Inter::Symbols::strike_definition(con_s);
			@<Define NUMBER_RULEBOOKS_CREATED@>;
			break;
		case RULEBOOKNAMES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new RulebookNames array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case ECONOMY_RULEBOOKNAMES_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the economy version of the new RulebookNames array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case RULEBOOK_VAR_CREATORS_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new rulebook_var_creators array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case SLOW_LOOKUP_SYNID: {
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the SlowLookup function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case RULEBOOKS_ARRAY_SYNID:
			Inter::Symbols::strike_definition(con_s);
			Q = Synoptic::begin_array(con_s, &IBM);
			@<Define the new rulebooks_array array as Q@>;
			Synoptic::end_array(Q, &IBM);
			break;
		case RULEPRINTINGRULE_SYNID: {
			int economy = FALSE;
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the RULEPRINTINGRULE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		case ECONOMY_RULEPRINTINGRULE_SYNID: {
			int economy = TRUE;
			packaging_state save = Synoptic::begin_redefining_function(&IBM, I, P);
			@<Add a body of code to the RULEPRINTINGRULE function@>;
			Synoptic::end_redefining_function(I, save);
			break;
		}
		default: return FALSE;
	}
	return TRUE;
}

@<Define NUMBER_RULEBOOKS_CREATED@> =
	Synoptic::def_numeric_constant(con_s, (inter_ti) TreeLists::len(rulebook_nodes), &IBM);

@<Define the new RulebookNames array as Q@> =
	for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
		text_stream *name = Metadata::read_textual(pack, I"^printed_name");
		Synoptic::textual_entry(Q, name);
	}

@<Define the economy version of the new RulebookNames array as Q@> =
	Synoptic::numeric_entry(Q, 0);
	Synoptic::numeric_entry(Q, 0);

@<Define the new rulebook_var_creators array as Q@> =
	for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
		if (vc_s) Synoptic::symbol_entry(Q, vc_s);
		else Synoptic::numeric_entry(Q, 0);
	}

@<Define the new rulebooks_array array as Q@> =
	for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
		inter_symbol *fn_s = Metadata::read_symbol(pack, I"^run_fn");
		Synoptic::symbol_entry(Q, fn_s);
	}
	Synoptic::numeric_entry(Q, 0);

@<Add a body of code to the SlowLookup function@> =
	inter_symbol *rb_s = Synoptic::get_local(I, I"rb");

	Produce::inv_primitive(I, SWITCH_BIP);
	Produce::down(I);
		Produce::val_symbol(I, K_value, rb_s);
		Produce::code(I);
		Produce::down(I);
		for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
			inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
			if (vc_s) {
				Produce::inv_primitive(I, CASE_BIP);
				Produce::down(I);
					Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) i);
					Produce::code(I);
					Produce::down(I);
						Produce::inv_primitive(I, RETURN_BIP);
						Produce::down(I);
							Produce::val_symbol(I, K_value, vc_s);
						Produce::up(I);
					Produce::up(I);
				Produce::up(I);
			}
		}
		Produce::up(I);
	Produce::up(I);
	Produce::inv_primitive(I, RETURN_BIP);
	Produce::down(I);
		Produce::val(I, K_value, LITERAL_IVAL, 0);
	Produce::up(I);

@<Add a body of code to the RULEPRINTINGRULE function@> =
	inter_symbol *R_s = Synoptic::get_local(I, I"R");
	inter_symbol *rba_s = Synoptic::get_local(I, I"rba");

	Produce::inv_primitive(I, IFELSE_BIP);
	Produce::down(I);
		Produce::inv_primitive(I, AND_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, GE_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, R_s);
				Produce::val(I, K_value, LITERAL_IVAL, 0);
			Produce::up(I);
			Produce::inv_primitive(I, LT_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, R_s);
				Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) TreeLists::len(rulebook_nodes));
			Produce::up(I);
		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			@<Print a rulebook name@>;
		Produce::up(I);
		Produce::code(I);
		Produce::down(I);
			@<Print a rule name@>;
		Produce::up(I);
	Produce::up(I);

@<Print a rulebook name@> =
	if (economy) {
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I"(rulebook ");
		Produce::up(I);
		Produce::inv_primitive(I, PRINTNUMBER_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, R_s);
		Produce::up(I);
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I")");
		Produce::up(I);
	} else {
		Produce::inv_primitive(I, PRINTSTRING_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, LOOKUP_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, rba_s);
				Produce::val_symbol(I, K_value, R_s);
			Produce::up(I);
		Produce::up(I);
	}

@<Print a rule name@> =
	if (economy) {
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I"(rule at address ");
		Produce::up(I);
		Produce::inv_primitive(I, PRINTNUMBER_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, R_s);
		Produce::up(I);
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I")");
		Produce::up(I);
	} else {
		for (int i=0; i<TreeLists::len(rule_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(rule_nodes->list[i].node);
			text_stream *name = Metadata::read_textual(pack, I"^printed_name");
			inter_symbol *rule_s = Metadata::read_symbol(pack, I"^value");
			if (Str::len(name) == 0) continue;
			Produce::inv_primitive(I, IF_BIP);
			Produce::down(I);
				Produce::inv_primitive(I, EQ_BIP);
				Produce::down(I);
					Produce::val_symbol(I, K_value, R_s);
					Produce::val_symbol(I, K_value, rule_s);
				Produce::up(I);
				Produce::code(I);
				Produce::down(I);
					Produce::inv_primitive(I, PRINT_BIP);
					Produce::down(I);
						Produce::val_text(I, name);
					Produce::up(I);
					Produce::rtrue(I);
				Produce::up(I);
			Produce::up(I);
		}
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I"(nameless rule at address ");
		Produce::up(I);
		Produce::inv_primitive(I, PRINTNUMBER_BIP);
		Produce::down(I);
			Produce::val_symbol(I, K_value, R_s);
		Produce::up(I);
		Produce::inv_primitive(I, PRINT_BIP);
		Produce::down(I);
			Produce::val_text(I, I")");
		Produce::up(I);
	}
