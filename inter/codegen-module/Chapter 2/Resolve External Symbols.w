[CodeGen::Externals::] Resolve External Symbols.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void CodeGen::Externals::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"resolve-external-symbols", CodeGen::Externals::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int resolution_failed = FALSE;
int CodeGen::Externals::run_pipeline_stage(pipeline_step *step) {
	inter_package *P = Inter::Packages::main(step->repository);
	if (P) {
		resolution_failed = FALSE;
		Inter::traverse_tree(step->repository, CodeGen::Externals::visitor, NULL, NULL, 0);
		LOGIF(EXTERNAL_SYMBOL_RESOLUTION, "\n\n");
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
		if (template_package) {
			inter_symbols_table *ST = Inter::Packages::scope(template_package);
			for (int i=0; i<ST->size; i++) {
				inter_symbol *S = ST->symbol_array[i];
				if ((S) && (S->equated_to) && (Inter::Symbols::get_flag(S, ALIAS_ONLY_BIT))) {
					LOGIF(EXTERNAL_SYMBOL_RESOLUTION, "Removing $3 as a template alias\n", S);
					ST->symbol_array[i] = NULL;
				}
			}
		}
		if (resolution_failed) internal_error("undefined external link(s)");
	}
	return TRUE;
}

@h The whole shebang.

=
void CodeGen::Externals::visitor(inter_tree *I, inter_frame P, void *state) {
	if (P.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *Q = Inter::Package::defined_by_frame(P);
		if (Inter::Packages::main(I) == Q) return;
		inter_symbols_table *ST = Inter::Packages::scope(Q);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((S) && (S->equated_to)) {
				inter_symbol *D = S;
				while ((D) && (D->equated_to)) D = D->equated_to;
				S->equated_to = D;
				Inter::Symbols::set_flag(D, EXTERN_TARGET_BIT);
				if (!Inter::Symbols::is_defined(D)) {
					LOG("In package $3:\n", Q->package_name);
					LOG("$3 == $3 which is undefined\n", S, D);
					WRITE_TO(STDERR, "Failed to resolve symbol: %S\n", D->symbol_name);
					resolution_failed = TRUE;
				}
			}
		}
	}
}
