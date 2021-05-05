[SynopticRules::] Rules.

To compile the main/synoptic/rules and main/synoptic/rulebooks submodules.

@ Before this runs, rulebook packages are scattered all over the Inter tree.
We must allocate each one a unique ID.

As this is called, //Synoptic Utilities// has already formed a list |rulebook_nodes|
of packages of type |_rulebook|; and similarly for |rule_nodes|.

=
void SynopticRules::compile(inter_tree *I) {
	if (TreeLists::len(rulebook_nodes) > 0) {
		TreeLists::sort(rulebook_nodes, Synoptic::module_order);
		for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
			inter_tree_node *D = Synoptic::get_definition(pack, I"rulebook_id");
			D->W.data[DATA_CONST_IFLD+1] = (inter_ti) i;
		}
	}
	int economy = FALSE;
	inter_symbol *me_s = InterSymbolsTables::url_name_to_symbol(I, NULL,
		I"/main/completion/basics/^memory_economy");
	if (me_s) economy = Inter::Symbols::evaluate_to_int(me_s);
	else internal_error("no me_s");
	@<Define NUMBER_RULEBOOKS_CREATED@>;
	@<Define RulebookNames array@>;
	if (economy) @<Define SlowLookup function@>
	else @<Define rulebook_var_creators array@>;
	@<Define rulebooks_array array@>;
	@<Define RULEPRINTINGRULE function@>;
}

@<Define NUMBER_RULEBOOKS_CREATED@> =
	inter_name *iname = HierarchyLocations::find(I, NUMBER_RULEBOOKS_CREATED_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (TreeLists::len(rulebook_nodes)));

@<Define RulebookNames array@> =
	inter_name *iname = HierarchyLocations::find(I, RULEBOOKNAMES_HL);
	Synoptic::begin_array(I, iname);
	if (economy) {
		Synoptic::numeric_entry(0);
		Synoptic::numeric_entry(0);
	} else {
		for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
			inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
			text_stream *name = Metadata::read_textual(pack, I"^printed_name");
			Synoptic::textual_entry(name);
		}
	}
	Synoptic::end_array(I);

@<Define rulebook_var_creators array@> =
	inter_name *iname = HierarchyLocations::find(I, RULEBOOK_VAR_CREATORS_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
		inter_symbol *vc_s = Metadata::read_optional_symbol(pack, I"^var_creator");
		if (vc_s) Synoptic::symbol_entry(vc_s);
		else Synoptic::numeric_entry(0);
	}
	Synoptic::end_array(I);

@<Define rulebooks_array array@> =
	inter_name *iname = HierarchyLocations::find(I, RULEBOOKS_ARRAY_HL);
	Synoptic::begin_array(I, iname);
	for (int i=0; i<TreeLists::len(rulebook_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(rulebook_nodes->list[i].node);
		inter_symbol *fn_s = Metadata::read_symbol(pack, I"^run_fn");
		Synoptic::symbol_entry(fn_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@<Define SlowLookup function@> =
	inter_name *iname = HierarchyLocations::find(I, SLOW_LOOKUP_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *rb_s = Synoptic::local(I, I"rb", NULL);

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
	Synoptic::end_function(I, iname);

@<Define RULEPRINTINGRULE function@> =
	inter_name *iname = HierarchyLocations::find(I, RULEPRINTINGRULE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *R_s = Synoptic::local(I, I"R", NULL);

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
	Synoptic::end_function(I, iname);

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
				Produce::val_iname(I, K_value, HierarchyLocations::find(I, RULEBOOKNAMES_HL));
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
