[CompileConditions::] Compile Conditions.

To compile Inter code to test a condition.

@ In fact almost all of the work is delegated to more potent routines elsewhere.
Much of //Chapter 4: Propositions// is really dedicated to this.

=
void CompileConditions::compile(value_holster *VH, parse_node *cond) {
	if (PluginCalls::compile_condition(VH, cond)) return;
	switch (Node::get_type(cond)) {
		case TEST_PROPOSITION_NT:
			CompilePropositions::to_test_as_condition(NULL,
				Specifications::to_proposition(cond));
			break;
		case LOGICAL_TENSE_NT:
			Chronology::compile_past_tense_condition(VH, cond);
			break;
		case LOGICAL_NOT_NT: @<Compile a logical negation@>; break;
		case LOGICAL_AND_NT: case LOGICAL_OR_NT: @<Compile a logical operator@>; break;
		case TEST_VALUE_NT:
			if (Specifications::is_description(cond)) {
				/* purely for problem recovery: */
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1); 
			} else {
				CompileValues::to_code_val(cond->down);
			}
			break;
		case TEST_PHRASE_OPTION_NT: @<Compile a phrase option test@>; break;
	}
}

@ An easy case, running straight out to Inter operators:

@<Compile a logical negation@> =
	if (Node::no_children(cond) != 1)
		internal_error("Compiled malformed LOGICAL_NOT_NT");
	Produce::inv_primitive(Emit::tree(), NOT_BIP);
	Produce::down(Emit::tree());
		CompileValues::to_code_val(cond->down);
	Produce::up(Emit::tree());

@ An easy case, running straight out to Inter operators:

@<Compile a logical operator@> =
	if (Node::no_children(cond) != 2)
		internal_error("Compiled malformed logical operator");
	parse_node *left_operand = cond->down;
	parse_node *right_operand = cond->down->next;
	if ((left_operand == NULL) || (right_operand == NULL))
		internal_error("Compiled CONDITION/AND with LHS operands");

	if (Node::is(cond, LOGICAL_AND_NT)) Produce::inv_primitive(Emit::tree(), AND_BIP);
	if (Node::is(cond, LOGICAL_OR_NT)) Produce::inv_primitive(Emit::tree(), OR_BIP);
	Produce::down(Emit::tree());
		CompileValues::to_code_val(left_operand);
		CompileValues::to_code_val(right_operand);
	Produce::up(Emit::tree());

@ Phrase options are stored as bits in a 16-bit map, so that each individual
option is a power of two from $2^0$ to $2^15$. We test if this is valid by
performing logical-and against the Inter local variable |phrase_options|, which
exists if and only if the enclosing Inter routine takes phrase options. The
type-checker won't allow these specifications to be compiled anywhere else.

@<Compile a phrase option test@> =
	Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
	Produce::down(Emit::tree());
		local_variable *po = LocalVariables::options_parameter();
		if (po == NULL) internal_error("no phrase options exist in this frame");
		inter_symbol *po_s = LocalVariables::declare(po);
		Produce::val_symbol(Emit::tree(), K_value, po_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
			(inter_ti) Annotations::read_int(cond, phrase_option_ANNOT));
	Produce::up(Emit::tree());
