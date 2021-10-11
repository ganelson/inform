[I6TargetVariables::] Inform 6 Global Variables.

To declare global variables, using a mixture of I6 Globals and array entries.

@ =
void I6TargetVariables::create_generator(code_generator *cgt) {
	METHOD_ADD(cgt, DECLARE_VARIABLES_MTID, I6TargetVariables::declare_variables);
	METHOD_ADD(cgt, EVALUATE_VARIABLE_MTID, I6TargetVariables::evaluate_variable);
}

@ In an ideal world we would implement all Inter global variables using |Global|,
thus making them I6 global variables as well. But when I6 compiles to the Z-machine
VM, there's an absolute limit of 240 globals, so we do not live in an ideal world.
As a compromise, we make all the kit-declared variables use |Global| (for speed)
and have all of the rest use entries in an array called |Global_Vars|, at the cost
of a lookup whenever we read or write them.

=
void I6TargetVariables::declare_variables(code_generator *cgt, code_generation *gen,
	linked_list *L) {
	int k = 1;
	inter_symbol *var_name;
	LOOP_OVER_LINKED_LIST(var_name, inter_symbol, L) {
		inter_tree_node *P = var_name->definition;
		inter_ti v1 = P->W.data[VAL1_VAR_IFLD], v2 = P->W.data[VAL2_VAR_IFLD];
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			if (k == 1) @<Begin the array@>;
			@<Variables created by Inform 7 source text all go into the array@>;
		} else {
			@<Variables created by kits all become Globals in I6@>;
		}
	}
	if (k > 1) @<End the array@>;
}

@<Begin the array@> =
	segmentation_pos saved = CodeGen::select(gen, globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Array Global_Vars --> 0\n");
	CodeGen::deselect(gen, saved);

@<Variables created by Inform 7 source text all go into the array@> =
	Inter::Symbols::annotate_i(var_name, I6_GLOBAL_OFFSET_IANN, (inter_ti) k);
	segmentation_pos saved = CodeGen::select(gen, globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("  (");
	CodeGen::pair(gen, P, v1, v2);
	WRITE(") ! -->%d = %S (%S)\n", k,
		Inter::Symbols::name(var_name), var_name->symbol_name);
	CodeGen::deselect(gen, saved);
	k++;

@<End the array@> =
	segmentation_pos saved = CodeGen::select(gen, globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);

@<Variables created by kits all become Globals in I6@> =
	segmentation_pos saved = CodeGen::select(gen, globals_directives_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Global %S = ", Inter::Symbols::name(var_name));
	CodeGen::pair(gen, P, v1, v2);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);

@ And the following is called when we want to compile an lvalue or rvalue for
the variable (lvalue in the case of |as_reference| being set).

=
void I6TargetVariables::evaluate_variable(code_generator *cgt, code_generation *gen,
	inter_symbol *var_name, int as_reference) {
	text_stream *OUT = CodeGen::current(gen);
	int k = Inter::Symbols::read_annotation(var_name, I6_GLOBAL_OFFSET_IANN);
	if (k > 0) WRITE("(Global_Vars-->%d)", k);
	else WRITE("%S", Inter::Symbols::name(var_name));
}
