[CodeGen::Inspection::] Inspect Plugs.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void CodeGen::Inspection::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"inspect-plugs", CodeGen::Inspection::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::Inspection::run_pipeline_stage(pipeline_step *step) {
	Inter::Connectors::stecker(step->repository);
	int resolution_failed = FALSE;
	Inter::Tree::traverse(step->repository, CodeGen::Inspection::visitor, &resolution_failed, NULL, PACKAGE_IST);
	if (resolution_failed) internal_error("loose plug(s)");
	return TRUE;
}

void CodeGen::Inspection::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	int *fail_flag = (int *) state;
	inter_package *Q = Inter::Package::defined_by_frame(P);
	if (Site::connectors_package(I) == Q) return;
	inter_symbols_table *ST = Inter::Packages::scope(Q);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		if ((S) && (S->equated_to) && (Inter::Symbols::get_scope(S->equated_to) == PLUG_ISYMS)) {
			if (!(Inter::Symbols::get_flag(S->equated_to, ERROR_ISSUED_MARK_BIT))) {
				Inter::Symbols::set_flag(S->equated_to, ERROR_ISSUED_MARK_BIT);
				LOG("$3 == $3 which is a loose plug, seeking %S\n", S, S->equated_to, S->equated_to->equated_name);
				WRITE_TO(STDERR, "Failed to connect plug to: %S\n", S->equated_to->equated_name);
				if (fail_flag) *fail_flag = TRUE;
			}
		}
	}
}
