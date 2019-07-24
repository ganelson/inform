[CodeGen::Uniqueness::] Uniqueness.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void CodeGen::Uniqueness::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"make-identifiers-unique", CodeGen::Uniqueness::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::Uniqueness::run_pipeline_stage(pipeline_step *step) {
	dictionary *D = Dictionaries::new(INITIAL_INTER_SYMBOLS_ID_RANGE, FALSE);
	Inter::traverse_tree(step->repository, CodeGen::Uniqueness::visitor, D, NULL, 0);
	return TRUE;
}

typedef struct uniqueness_count {
	int count;
	MEMORY_MANAGEMENT
} uniqueness_count;

void CodeGen::Uniqueness::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	dictionary *D = (dictionary *) state;
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *Q = Inter::Package::defined_by_frame(P);
		inter_symbols_table *ST = Inter::Packages::scope(Q);
		for (int i=0; i<ST->size; i++) {
			inter_symbol *S = ST->symbol_array[i];
			if ((S) && (S->equated_to == NULL) && (Inter::Symbols::get_flag(S, MAKE_NAME_UNIQUE))) {
				text_stream *N = S->symbol_name;
				uniqueness_count *U = NULL;
				if (Dictionaries::find(D, N)) {
					U = (uniqueness_count *) Dictionaries::read_value(D, N);
				} else {
					U = CREATE(uniqueness_count);
					U->count = 0;
					Dictionaries::create(D, N);
					Dictionaries::write_value(D, N, (void *) U);
				}
				U->count++;
				TEMPORARY_TEXT(T);
				WRITE_TO(T, "%S_U%d", N, U->count);
				Inter::Symbols::set_translate(S, T);
				DISCARD_TEXT(T);
				Inter::Symbols::clear_flag(S, MAKE_NAME_UNIQUE);
			}
		}
	}
}
