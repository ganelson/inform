[CodeGen::Externals::] Resolve External Symbols.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void CodeGen::Externals::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"resolve-external-symbols", CodeGen::Externals::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::Externals::run_pipeline_stage(pipeline_step *step) {
	Inter::Connectors::stecker(step->ephemera.repository);
	int resolution_failed = FALSE;
	InterTree::traverse(step->ephemera.repository, CodeGen::Externals::visitor, &resolution_failed, NULL, PACKAGE_IST);
	if (resolution_failed) internal_error("undefined external link(s)");
	return TRUE;
}

void CodeGen::Externals::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	int *fail_flag = (int *) state;
	inter_package *Q = Inter::Package::defined_by_frame(P);
	if (Site::connectors_package(I) == Q) return;
	inter_symbols_table *ST = Inter::Packages::scope(Q);
	for (int i=0; i<ST->size; i++) {
		inter_symbol *S = ST->symbol_array[i];
		if ((S) && (S->equated_to)) {
			inter_symbol *D = S;
			while ((D) && (D->equated_to)) D = D->equated_to;
			S->equated_to = D;
			if (!Inter::Symbols::is_defined(D)) {
				inter_symbol *socket = Inter::Connectors::find_socket(I, D->symbol_name);
				if (socket) {
					D = socket->equated_to;
					S->equated_to = D;
				}
			}
			if (!Inter::Symbols::is_defined(D)) {
				if (Inter::Symbols::get_scope(D) != PLUG_ISYMS) {
					if (D == S) {
					LOG("$3 is undefined\n", S);
					WRITE_TO(STDERR, "Failed to resolve symbol: %S (in ",
						S->symbol_name, D->symbol_name);
					} else {
						LOG("$3 == $3 which is undefined\n", S, D);
						WRITE_TO(STDERR, "Failed to resolve symbol: %S -> %S (in ",
							S->symbol_name, D->symbol_name);
					}
					Inter::Packages::write_url_name(STDERR, S->owning_table->owning_package);
					if (D != S) {
						WRITE_TO(STDERR, "\n   --> "); Inter::Packages::write_url_name(STDERR, D->owning_table->owning_package);
					}
					WRITE_TO(STDERR, ")\n");
					if (fail_flag) *fail_flag = TRUE;
				}
			}
		}
	}
}
