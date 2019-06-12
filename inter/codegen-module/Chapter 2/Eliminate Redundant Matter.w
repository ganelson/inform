[CodeGen::Eliminate::] Eliminate Redundant Matter.

To reconcile clashes between assimilated and originally generated verbs.

@h Pipeline stage.

=
void CodeGen::Eliminate::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"eliminate-redundant-code", CodeGen::Eliminate::run_pipeline_stage, NO_STAGE_ARG);
}

int CodeGen::Eliminate::run_pipeline_stage(pipeline_step *step) {
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
			inter_package *needed = NULL;
			inter_symbol *cb = Inter::Constant::code_block(to);
			LOG("To $3 cb $3\n", to, cb);
			if (cb) needed = Inter::Package::which(cb);
			else needed = to->owning_table->owning_package;
			CodeGen::Eliminate::require(needed, to);
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
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_to_phrase"))) {
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
				if (Str::eq(package_name->symbol_name, I"SL_Score_Moves_B"))
					CodeGen::Eliminate::require(which, NULL);
			}
		}
	}
	LOOP_THROUGH_FRAMES(P, I) {
		if (P.data[ID_IFLD] == PACKAGE_IST) {
			inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PACKAGE_IFLD);
			inter_package *which = Inter::Package::which(package_name);
			if ((which) && ((which->package_flags & USED_PACKAGE_FLAG) == 0)) {
				LOG("Not used: $6\n", which);
			}
		}
		if (P.data[ID_IFLD] == VARIABLE_IST) {
			inter_package *outer = Inter::Packages::container(P);
			if ((outer) && (CodeGen::Eliminate::gone(outer->package_name))) {
				inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
				LOG("Striking variable $3\n", var_name);
				Inter::Symbols::strike_definition(var_name);
				Inter::Symbols::remove_from_table(var_name);
				continue;
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
