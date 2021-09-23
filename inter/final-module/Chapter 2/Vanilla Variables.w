[VanillaVariables::] Vanilla Variables.

How the vanilla code generation strategy handles variables.

@ =
int variables_written = FALSE, prepare_counter = 0, knowledge_counter = 0;
void VanillaVariables::prepare(code_generation *gen) {
	variables_written = FALSE;
	prepare_counter = 0;
	knowledge_counter = 0;
	InterTree::traverse(gen->from, VanillaVariables::visitor1, gen, NULL, VARIABLE_IST);
}

void VanillaVariables::visitor1(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *var_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	prepare_counter = Generators::prepare_variable(gen, P, var_name, prepare_counter);
}

void VanillaVariables::variable(code_generation *gen, inter_tree_node *P) {
	if (variables_written == FALSE) {
		variables_written = TRUE;
		InterTree::traverse(gen->from, VanillaVariables::visitor2, gen, NULL, VARIABLE_IST);
	}
}

void VanillaVariables::visitor2(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *var_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	knowledge_counter = Generators::declare_variable(gen, P, var_name, knowledge_counter, prepare_counter);
}

void VanillaVariables::consolidate(code_generation *gen) {
}
