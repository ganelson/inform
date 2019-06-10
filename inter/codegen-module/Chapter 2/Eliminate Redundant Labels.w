[CodeGen::Labels::] Eliminate Redundant Labels.

To reconcile clashes between assimilated and originally generated verbs.

@h Pipeline stage.

=
void CodeGen::Labels::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"eliminate-redundant-labels", CodeGen::Labels::run_pipeline_stage, NO_STAGE_ARG);
}

int CodeGen::Labels::run_pipeline_stage(pipeline_step *step) {
	CodeGen::Labels::go(step->repository);
	return TRUE;
}

@h Running.

=
void CodeGen::Labels::go(inter_repository *I) {

	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I) {
		if (P.data[ID_IFLD] == PACKAGE_IST) {
			inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
			inter_package *which = Inter::Package::which(package_name);
			if (which) {
				inter_symbol *ptype = Inter::Packages::type(which);
				if ((ptype) && (Str::eq(ptype->symbol_name, I"_code"))) {
					LOG("Code block $3\n", package_name);
				}
			}
		}
	}

}
