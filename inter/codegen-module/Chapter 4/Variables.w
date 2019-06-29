[CodeGen::Var::] Variables.

To generate the initial state of storage for variables.

@h Storage.

=
int variables_written = FALSE, prepare_counter = 0;
void CodeGen::Var::prepare(code_generation *gen) {
	variables_written = FALSE;
	inter_repository *I = gen->from;
	prepare_counter = 0;
	if (I) {
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == VARIABLE_IST) {
				inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
				prepare_counter = CodeGen::Targets::prepare_variable(gen, P, var_name, prepare_counter);
			}
	}
}

void CodeGen::Var::knowledge(code_generation *gen) {
	if (variables_written == FALSE) {
		variables_written = TRUE;
		inter_repository *I = gen->from;
		inter_frame P;
		int k = 0;
		LOOP_THROUGH_FRAMES(P, I)
			if (P.data[ID_IFLD] == VARIABLE_IST) {
				inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
				k = CodeGen::Targets::declare_variable(gen, P, var_name, k, prepare_counter);
			}
	}
}
