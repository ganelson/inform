[CodeGen::Var::] Variables.

To generate the initial state of storage for variables.

@ =
int variables_written = FALSE, prepare_counter = 0, knowledge_counter = 0;
void CodeGen::Var::prepare(code_generation *gen) {
	variables_written = FALSE;
	prepare_counter = 0;
	knowledge_counter = 0;
	Inter::Tree::traverse(gen->from, CodeGen::Var::visitor1, gen, NULL, VARIABLE_IST);
}

void CodeGen::Var::visitor1(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *var_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	prepare_counter = CodeGen::Targets::prepare_variable(gen, P, var_name, prepare_counter);
}

void CodeGen::Var::knowledge(code_generation *gen) {
	if (variables_written == FALSE) {
		variables_written = TRUE;
		Inter::Tree::traverse(gen->from, CodeGen::Var::visitor2, gen, NULL, VARIABLE_IST);
	}
}

void CodeGen::Var::visitor2(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *var_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
	knowledge_counter = CodeGen::Targets::declare_variable(gen, P, var_name, knowledge_counter, prepare_counter);
}
