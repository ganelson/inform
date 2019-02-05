[CodeGen::Uniqueness::] Uniqueness.

To make sure certain symbol names translate into globally unique target symbols.

@h The whole shebang.

=
void CodeGen::Uniqueness::ensure(inter_repository *I) {
	inter_package *P = Inter::Packages::main(I);
	if (P) {
		dictionary *D = Dictionaries::new(INITIAL_INTER_SYMBOLS_ID_RANGE, FALSE);
		CodeGen::Uniqueness::ensure_r(P, D);
	}
}

@ =
typedef struct uniqueness_count {
	int count;
	MEMORY_MANAGEMENT
} uniqueness_count;

@ =
void CodeGen::Uniqueness::ensure_r(inter_package *P, dictionary *D) {
	for (inter_package *Q = P; Q; Q = Q->next_package) {
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
		if (Q->child_package) CodeGen::Uniqueness::ensure_r(Q->child_package, D);
	}
}
