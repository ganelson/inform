[SynopticResponses::] Responses.

To compile the main/synoptic/responses submodule.

@ Response packages are scattered all over the Inter tree. Each one contains
these metadata constants:

(*) |^group|, textual, which describes the origin.
(*) |^marker|, numeric, from 0 to 25: whether this is (A), (B), ..., (Z);
(*) |^rule|, symbol, the rule to which this is a response.
(*) |^value|, symbol, the text for the response at start of play.

Our inventory |inv| already contains a list |inv->response_nodes| of all packages
in the tree with type |_response|.

=
void SynopticResponses::compile(inter_tree *I, pipeline_step *step, tree_inventory *inv) {
	if (InterNodeList::array_len(inv->response_nodes) > 0) @<Assign unique response ID numbers@>;
	@<Define NO_RESPONSES@>;
	@<Define ResponseTexts array@>;
	@<Define ResponseDivisions array@>;
	@<Define PrintResponse function@>;
}

@ Each response package contains a numeric constant with the symbol name |response_id|.
We want to ensure that these ID numbers are contiguous from 1 and never duplicated,
so we change the values of these constants accordingly. These will be the enumerated
values at runtime of the kind |K_response|.

@<Assign unique response ID numbers@> =
	for (int i=0; i<InterNodeList::array_len(inv->response_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->response_nodes->list[i].node);
		inter_tree_node *D = Synoptic::get_definition(pack, I"response_id");
		ConstantInstruction::set_constant(D, InterValuePairs::number((inter_ti) i+1));
	}

@<Define NO_RESPONSES@> =
	inter_name *iname = HierarchyLocations::iname(I, NO_RESPONSES_HL);
	Produce::numeric_constant(I, iname, K_value, (inter_ti) (InterNodeList::array_len(inv->response_nodes)));

@ This is the critical array which connects a response ID to the current value
of the text of that response.

@<Define ResponseTexts array@> =
	inter_name *iname = HierarchyLocations::iname(I, RESPONSETEXTS_HL);
	Synoptic::begin_array(I, step, iname);
	for (int i=0; i<InterNodeList::array_len(inv->response_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->response_nodes->list[i].node);
		inter_symbol *value_s = Metadata::required_symbol(pack, I"^value");
		Synoptic::symbol_entry(value_s);
	}
	Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@ The following array is used only by the testing command RESPONSES, which
prints out all known responses, divided up by the extensions containing the
rules which produce them.

The format is triples |(group, from, to)| where |group| is a textual
description of the origin of the set (e.g., an extension name), and |from|
and |to| are an inclusive range of response ID numbers.

The triple |(0, 0, 0)| ends the array.

@<Define ResponseDivisions array@> =
	inter_name *iname = HierarchyLocations::iname(I, RESPONSEDIVISIONS_HL);
	Synoptic::begin_array(I, step, iname);
	text_stream *current_group = NULL; int start_pos = -1;
	for (int i=0; i<InterNodeList::array_len(inv->response_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->response_nodes->list[i].node);
		text_stream *group = Metadata::required_textual(pack, I"^group");
		if (Str::ne(group, current_group)) {
			if (start_pos >= 0) {
				Synoptic::textual_entry(current_group);
				Synoptic::numeric_entry((inter_ti) start_pos + 1);
				Synoptic::numeric_entry((inter_ti) i);
			}
			current_group = group;
			start_pos = i;
		}
	}
	if (start_pos >= 0) {
		Synoptic::textual_entry(current_group);
		Synoptic::numeric_entry((inter_ti) start_pos + 1);
		Synoptic::numeric_entry((inter_ti) InterNodeList::array_len(inv->response_nodes));
	}
	Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::numeric_entry(0);
	Synoptic::end_array(I);

@ Finally, a function used when printing values of the |K_response| kind;
the main compiler created this as a mostly empty function with two local
variables -- |R|, the ID for the response we should print, and |RPR|, the
address of a function for printing rule names.

This is in effect a big switch statement, so it's not fast; but being a print
function it doesn't need to be.

The only reason this is a function at all, rather than using far more
efficient array lookups, is that we have to guard accessible memory space on
the Z-machine, where such an array could consume over 1K, but where memory for
code is less limited.

@<Define PrintResponse function@> =
	inter_name *iname = HierarchyLocations::iname(I, PRINT_RESPONSE_HL);
	Synoptic::begin_function(I, iname);
	inter_symbol *R_s = Synoptic::local(I, I"R", NULL);

	for (int i=0; i<InterNodeList::array_len(inv->response_nodes); i++) {
		inter_package *pack = PackageInstruction::at_this_head(inv->response_nodes->list[i].node);
		inter_ti m = Metadata::read_numeric(pack, I"^marker");
		inter_symbol *rule_s = Metadata::required_symbol(pack, I"^value");
		Produce::inv_primitive(I, IF_BIP);
		Produce::down(I);
			Produce::inv_primitive(I, EQ_BIP);
			Produce::down(I);
				Produce::val_symbol(I, K_value, R_s);
				Produce::val(I, K_value, InterValuePairs::number((inter_ti) i+1));
			Produce::up(I);
			Produce::code(I);
			Produce::down(I);
				Produce::inv_call_iname(I, HierarchyLocations::iname(I, RULEPRINTINGRULE_HL));
				Produce::down(I);
					Produce::val_symbol(I, K_value, rule_s);
				Produce::up(I);
				Produce::inv_primitive(I, PRINT_BIP);
				Produce::down(I);
					Produce::val_text(I, I" response (");
				Produce::up(I);
				Produce::inv_primitive(I, PRINTCHAR_BIP);
				Produce::down(I);
					Produce::val(I, K_value, InterValuePairs::number((inter_ti) ('A' + m)));
				Produce::up(I);
				Produce::inv_primitive(I, PRINT_BIP);
				Produce::down(I);
					Produce::val_text(I, I")");
				Produce::up(I);
			Produce::up(I);
		Produce::up(I);
	}
	Synoptic::end_function(I, step, iname);
