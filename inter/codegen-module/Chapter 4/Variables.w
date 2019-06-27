[CodeGen::Var::] Variables.

To generate the initial state of storage for variables.

@h Storage.

=
void CodeGen::Var::knowledge(code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	inter_repository *I = gen->from;
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == VARIABLE_IST) {
			inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
			if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) == 1) {
				WRITE("Global %S = ", CodeGen::name(var_name));
				CodeGen::literal(gen, NULL, Inter::Packages::scope_of(P), P.data[VAL1_VAR_IFLD], P.data[VAL2_VAR_IFLD], FALSE);
				WRITE(";\n");
			}
		}
	int k = 0;
	WRITE("Array Global_Vars -->\n");
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == VARIABLE_IST) {
			inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
			if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
				WRITE("  (");
				inter_symbols_table *globals = Inter::Packages::scope_of(P);
				CodeGen::literal(gen, NULL, globals, P.data[VAL1_VAR_IFLD], P.data[VAL2_VAR_IFLD], FALSE);
				WRITE(") ! -->%d = %S (%S)\n", k, CodeGen::name(var_name), var_name->symbol_name);
				k++;
			}
		}
	if (k < 2) WRITE("  NULL NULL");
	WRITE(";\n");
}

void CodeGen::Var::set_translates(inter_repository *I) {
	inter_frame P;
	int k = 0;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == VARIABLE_IST) {
			inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
			if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
				if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
					text_stream *S = Str::new();
					WRITE_TO(S, "(Global_Vars-->%d)", k);
					Inter::Symbols::set_translate(var_name, S);
				}
				k++;
			}
		}
}
