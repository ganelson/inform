[CodeGen::ReconcileVerbs::] Reconcile Verbs.

To reconcile clashes between assimilated and originally generated verbs.

@h Pipeline stage.

=
void CodeGen::ReconcileVerbs::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"reconcile-verbs", CodeGen::ReconcileVerbs::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::ReconcileVerbs::run_pipeline_stage(pipeline_step *step) {
	CodeGen::ReconcileVerbs::reconcile(step->repository);
	return TRUE;
}

@h Parsing.

=
void CodeGen::ReconcileVerbs::reconcile(inter_tree *I) {
	dictionary *observed_verbs = Dictionaries::new(1024, TRUE);
	Inter::Tree::traverse(I, CodeGen::ReconcileVerbs::visitor1, observed_verbs, NULL, 0);
	Inter::Tree::traverse(I, CodeGen::ReconcileVerbs::visitor2, observed_verbs, NULL, 0);
}

void CodeGen::ReconcileVerbs::visitor1(inter_tree *I, inter_tree_node *P, void *v_state) {
	dictionary *observed_verbs = (dictionary *) v_state;
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if ((Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) &&
			(Inter::Symbols::read_annotation(con_name, METAVERB_IANN) != 1))
			@<Attend to the verb@>;
	}
}


void CodeGen::ReconcileVerbs::visitor2(inter_tree *I, inter_tree_node *P, void *v_state) {
	dictionary *observed_verbs = (dictionary *) v_state;
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if ((Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) &&
			(Inter::Symbols::read_annotation(con_name, METAVERB_IANN) == 1))
			@<Attend to the verb@>;
	}
}

@<Attend to the verb@> =
	if (P->W.extent > DATA_CONST_IFLD+1) {
		inter_ti V1 = P->W.data[DATA_CONST_IFLD], V2 = P->W.data[DATA_CONST_IFLD+1];
		if (V1 == DWORD_IVAL) {
			text_stream *glob_text = Inter::Warehouse::get_text(Inter::Tree::warehouse(I), V2);
			if (Dictionaries::find(observed_verbs, glob_text)) {
				TEMPORARY_TEXT(nv)
				WRITE_TO(nv, "!%S", glob_text);
				Str::clear(glob_text);
				Str::copy(glob_text, nv);
				DISCARD_TEXT(nv)
			}
			Dictionaries::create(observed_verbs, glob_text);
		}
	}
