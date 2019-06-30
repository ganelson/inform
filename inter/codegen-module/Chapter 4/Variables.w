[CodeGen::Var::] Variables.

To generate the initial state of storage for variables.

@ =
int variables_written = FALSE, prepare_counter = 0;
void CodeGen::Var::prepare(code_generation *gen) {
	variables_written = FALSE;
	prepare_counter = 0;
	Inter::Packages::traverse(gen, CodeGen::Var::visitor1, NULL);
}

void CodeGen::Var::visitor1(code_generation *gen, inter_frame P, void *state) {
	if (P.data[ID_IFLD] == VARIABLE_IST) {
		inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
		prepare_counter = CodeGen::Targets::prepare_variable(gen, P, var_name, prepare_counter);
	}
}

void CodeGen::Var::knowledge(code_generation *gen) {
	if (variables_written == FALSE) {
		variables_written = TRUE;
		int k = 0;
		Inter::Packages::traverse(gen, CodeGen::Var::visitor2, (void *) &k);
	}
}

void CodeGen::Var::visitor2(code_generation *gen, inter_frame P, void *state) {
	if (P.data[ID_IFLD] == VARIABLE_IST) {
		int *k = (int *) state;
		inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
		*k = CodeGen::Targets::declare_variable(gen, P, var_name, *k, prepare_counter);
	}
}
