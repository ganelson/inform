[CodeGen::Eliminate::] Eliminate Redundant Matter.

To reconcile clashes between assimilated and originally generated verbs.

@h Pipeline stage.

=
void CodeGen::Eliminate::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"eliminate-redundant-code", CodeGen::Eliminate::run_pipeline_stage, NO_STAGE_ARG);
}

int CodeGen::Eliminate::run_pipeline_stage(stage_step *step) {
	CodeGen::Eliminate::go(step->repository);
	return TRUE;
}

@h Parsing.

=
void CodeGen::Eliminate::require(inter_package *pack, inter_symbol *witness) {
	if ((pack->package_flags) & USED_PACKAGE_FLAG) return;
	pack->package_flags |= USED_PACKAGE_FLAG;
	if (witness) LOG("Need $6 because of $3\n", pack, witness); else LOG("Need $6\n", pack);
	inter_symbols_table *tab = Inter::Packages::scope(pack);
	for (int i=0; i<tab->size; i++) {
		inter_symbol *symb = tab->symbol_array[i];
		if ((symb) && (symb->equated_to)) {
			inter_symbol *to = symb->equated_to;
			CodeGen::Eliminate::require(to->owning_table->owning_package, to);
		}
	}
	inter_symbol *ptype = Inter::Packages::type(pack);
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_function"))) {
		for (inter_package *P = pack->child_package; P; P = P->next_package) {
			CodeGen::Eliminate::require(P, NULL);
		}
	}
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_action"))) {
		for (inter_package *P = pack->child_package; P; P = P->next_package) {
			CodeGen::Eliminate::require(P, NULL);
		}
	}
}

int notes_made = 0, log_elims = FALSE;

int elims_made = FALSE;
void CodeGen::Eliminate::go(inter_repository *I) {
	elims_made = TRUE;
	inter_symbol *Main_block = Inter::SymbolsTables::symbol_from_name_in_template(I, I"Main_B");
	inter_package *Main_package = Inter::Package::which(Main_block);
	if (Main_package == NULL) {
		LOG("Eliminate failed: can't find Main code block\n");
		return;
	}
	CodeGen::Eliminate::require(Main_package, NULL);
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I) {
		if (P.data[ID_IFLD] == PACKAGE_IST) {
			inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
			inter_package *which = Inter::Package::which(package_name);
			if (which) {
				inter_symbol *ptype = Inter::Packages::type(which);
				if ((ptype) && (Str::eq(ptype->symbol_name, I"_action"))) {
					CodeGen::Eliminate::require(which, NULL);
				}
				if ((ptype) && (Str::eq(ptype->symbol_name, I"_command"))) {
					CodeGen::Eliminate::require(which, NULL);
				}
			}
		}
	}
	LOOP_THROUGH_FRAMES(P, I) {
		if (P.data[ID_IFLD] == PACKAGE_IST) {
			inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
			inter_package *which = Inter::Package::which(package_name);
			if (which) {
				if ((which->package_flags & USED_PACKAGE_FLAG) == 0) {
					LOG("Not used: $6\n", which);
				}
			}
		}
	}
}

int CodeGen::Eliminate::gone(inter_symbol *code_block) {
	inter_package *which = Inter::Package::which(code_block);
	if ((elims_made) && (which) && ((which->package_flags & USED_PACKAGE_FLAG) == 0))
		return TRUE;
	return FALSE;
}

void CodeGen::Eliminate::keep(inter_repository *I, text_stream *N) {
	inter_symbol *S = Inter::SymbolsTables::symbol_from_name_in_main_or_basics(I, N);
	if (S) Inter::Symbols::set_flag(S, USED_MARK_BIT);
}

void CodeGen::Eliminate::note(inter_symbol *S, inter_symbol *T, void *state) {
	inter_repository *I = (inter_repository *) state;
	inter_symbol *Tdash = Inter::SymbolsTables::symbol_from_name_in_main_or_basics(I, T->symbol_name);
	if (Tdash) {
		Inter::Symbols::set_flag(Tdash, USED_MARK_BIT);
	} else {
		Inter::Symbols::set_flag(T, USED_MARK_BIT);
	}
	notes_made++;
}
