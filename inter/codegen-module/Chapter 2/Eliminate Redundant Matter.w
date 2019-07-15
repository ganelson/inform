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
inter_symbol *CodeGen::Eliminate::endpoint(inter_symbol *to) {
	while ((to) && (to->equated_to)) to = to->equated_to;
	return to;
}

void CodeGen::Eliminate::require(inter_package *pack, inter_symbol *witness, text_stream *reason) {
	if ((pack->package_flags) & USED_PACKAGE_FLAG) return;
	pack->package_flags |= USED_PACKAGE_FLAG;
	if (witness) LOG("Need $6 because of $3 (because %S)\n", pack, witness, reason);
	else LOG("Need $6 (because %S)\n", pack, reason);
	int template_mode = FALSE;
	if (Str::eq(pack->package_name->symbol_name, I"template")) template_mode = TRUE;
	inter_symbols_table *tab = Inter::Packages::scope(pack);
	for (int i=0; i<tab->size; i++) {
		inter_symbol *symb = tab->symbol_array[i];
		if ((symb) && (symb->equated_to)) {
			inter_symbol *to = CodeGen::Eliminate::endpoint(symb);
			inter_package *needed = to->owning_table->owning_package;
//			inter_package *needed = NULL;
//			inter_symbol *cb = Inter::Constant::code_block(to);
			// LOG("To $3 cb $3\n", to, cb);
//			if (cb) needed = Inter::Package::which(cb);
//			else needed = to->owning_table->owning_package;
			int follow = TRUE;
			if (template_mode) {
				inter_symbol *ptype = Inter::Packages::type(needed);
				if ((ptype) && (Str::eq(ptype->symbol_name, I"_function")))
					follow = FALSE;
			}
			if (follow)
				CodeGen::Eliminate::require(needed, pack->package_name, I"it's an external symbol");
		}
	}
	inter_symbol *ptype = Inter::Packages::type(pack);
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_function"))) {
		inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *P = Inter::Package::defined_by_frame(C);
				CodeGen::Eliminate::require(P, pack->package_name, I"it's a _function block");
			}
		}
	}
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_action"))) {
		inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *P = Inter::Package::defined_by_frame(C);
				CodeGen::Eliminate::require(P, pack->package_name, I"it's an _action subpackage");
			}
		}
	}
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_to_phrase"))) {
		inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *P = Inter::Package::defined_by_frame(C);
				LOG_INDENT;
				CodeGen::Eliminate::require(P, pack->package_name, I"it's a to phrase subpackage");
				LOG_OUTDENT;
			}
		}
	}
}

int notes_made = 0, log_elims = FALSE;

int elims_made = FALSE;
void CodeGen::Eliminate::go(inter_repository *I) {
	inter_symbol *Main_block = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/main/template/functions/Main_fn");
	inter_package *Main_package = Inter::Package::which(Main_block);
	if (Main_package == NULL) {
		LOG("Eliminate failed: can't find Main code block\n");
		return;
	}
	elims_made = TRUE;
	LOG("Go...\n");
	CodeGen::Eliminate::require(Main_package, NULL, I"it's Main!");
	CodeGen::Eliminate::require_these_too(Inter::Packages::main(I));
	CodeGen::Eliminate::eliminate_unused(Inter::Packages::main(I));
	Inter::traverse_tree(I, CodeGen::Eliminate::variable_visitor, NULL, NULL, 0);
}

void CodeGen::Eliminate::require_these_too(inter_package *pack) {
	inter_symbol *ptype = Inter::Packages::type(pack);
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_action"))) {
		CodeGen::Eliminate::require(pack, NULL, I"it's an _action package");
	}
	if ((ptype) && (Str::eq(ptype->symbol_name, I"_command"))) {
		CodeGen::Eliminate::require(pack, NULL, I"it's a _command package");
	}
	if (Str::eq(pack->package_name->symbol_name, I"SL_Score_Moves_fn"))
		CodeGen::Eliminate::require(pack, NULL, I"it's the score/moves exception");
	if (Str::eq(pack->package_name->symbol_name, I"SL_Score_Moves_B"))
		CodeGen::Eliminate::require(pack, NULL, I"it's the score/moves exception");
	inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *P = Inter::Package::defined_by_frame(C);
			CodeGen::Eliminate::require_these_too(P);
		}
	}
}

void CodeGen::Eliminate::eliminate_unused(inter_package *pack) {
	if ((pack) && ((pack->package_flags & USED_PACKAGE_FLAG) == 0)) {
		inter_symbol *ptype = Inter::Packages::type(pack);
		LOG("Not used: $3 type %S\n", pack->package_name, ptype->symbol_name);
		if ((ptype) && (Str::eq(ptype->symbol_name, I"_function"))) {
			inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
			LOG("Striking function $3\n", pack->package_name);
			Inter::Frame::remove_from_tree(D);
			return;
		}
//		CodeGen::Eliminate::remove_package(pack);
	} else {
		inter_symbol *ptype = Inter::Packages::type(pack);
		LOG("Used: $3 type %S\n", pack->package_name, ptype->symbol_name);
	}
	inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *P = Inter::Package::defined_by_frame(C);
			CodeGen::Eliminate::eliminate_unused(P);
		}
	}
}

void CodeGen::Eliminate::variable_visitor(inter_repository *I, inter_frame P, void *state) {
	if (P.data[ID_IFLD] == VARIABLE_IST) {
		inter_package *outer = Inter::Packages::container(P);
		if ((outer) && (CodeGen::Eliminate::gone(outer->package_name))) {
			inter_symbol *var_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_VAR_IFLD);
			LOG("Striking variable $3\n", var_name);
			Inter::Symbols::strike_definition(var_name);
			Inter::Symbols::remove_from_table(var_name);
		}
	}
}

void CodeGen::Eliminate::remove_package(inter_package *pack) {
	if (pack) {
		inter_frame D = Inter::Symbols::defining_frame(pack->package_name);
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *P = Inter::Package::defined_by_frame(C);
				if ((P) && ((P->package_flags & USED_PACKAGE_FLAG) != 0)) {
					LOG("Warning: eliminating necessary $6\n", P);
				}
			}
		}
	}
}

int CodeGen::Eliminate::gone(inter_symbol *code_block) {
//	inter_package *which = Inter::Package::which(code_block);
//	if ((elims_made) && (which) && ((which->package_flags & USED_PACKAGE_FLAG) == 0))
//		return TRUE;
	return FALSE;
}
