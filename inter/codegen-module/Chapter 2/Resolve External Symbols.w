[CodeGen::Externals::] Resolve External Symbols.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void CodeGen::Externals::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"resolve-external-symbols", CodeGen::Externals::run_pipeline_stage, NO_STAGE_ARG);
}

int CodeGen::Externals::run_pipeline_stage(pipeline_step *step) {
	CodeGen::Externals::resolve(step->repository);
	return TRUE;
}

@h The whole shebang.

=
int resolution_failed = FALSE;
void CodeGen::Externals::resolve(inter_repository *I) {
	inter_package *P = Inter::Packages::main(I);
	if (P) {
		resolution_failed = FALSE;
		CodeGen::Externals::resolve_r(P->child_package);
		LOG("\n\n");
		inter_symbols_table *ST = Inter::Packages::scope(P);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((S) && (S->equated_to)) {
				LOGIF(EXTERNAL_SYMBOL_RESOLUTION, "Removing $3 as a main indirection intermediate\n", S);
				ST->symbol_array[i] = NULL;
			} else if ((S) && (Inter::Symbols::get_flag(S, EXTERN_TARGET_BIT) == FALSE) && (!Inter::Symbols::is_defined(S))) {
				LOGIF(EXTERNAL_SYMBOL_RESOLUTION, "Removing $3 as undefined and not an extern target\n", S);
				ST->symbol_array[i] = NULL;
			}
		}
		if (resolution_failed) internal_error("undefined external link(s)");
	}
}

@ =
void CodeGen::Externals::resolve_r(inter_package *P) {
	for (inter_package *Q = P; Q; Q = Q->next_package) {
		inter_symbols_table *ST = Inter::Packages::scope(Q);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((S) && (S->equated_to)) {
				inter_symbol *D = S;
				while ((D) && (D->equated_to)) D = D->equated_to;
				S->equated_to = D;
				Inter::Symbols::set_flag(D, EXTERN_TARGET_BIT);
				if (!Inter::Symbols::is_defined(D)) {
					LOG("$3 == $3 which is undefined\n", S, D);
					WRITE_TO(STDERR, "Failed to resolve symbol: %S\n", D->symbol_name);
					resolution_failed = TRUE;
				}
			}
		}
		if (Q->child_package) CodeGen::Externals::resolve_r(Q->child_package);
	}
}
