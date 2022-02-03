[Inter::Verify::] Verifying Inter.

Verifying that a chunk of inter is correct and consistent.

@ =
inter_error_message *Inter::Verify::defn(inter_package *owner, inter_tree_node *P, int index) {
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_not_equating(T, P->W.instruction[index]);
	if (S == NULL) return Inode::error(P, I"no symbol for ID (case 1)", NULL);
	if (Wiring::is_wired(S)) {
		inter_symbol *E = Wiring::cable_end(S);
		LOG("This is $6 but $3 is wired to $3 in $6\n",
			InterPackage::container(P), S, E, InterPackage::container(E->definition));
		return Inode::error(P, I"symbol defined outside its native scope", S->symbol_name);
	}
	inter_tree_node *D = Inter::Symbols::definition(S);
	if (D == NULL) Inter::Symbols::define(S, P);
	else if (Inode::same_instruction(D, P) == FALSE) {
		if (Inter::Symbols::is_predeclared(S)) {
			Inter::Symbols::define(S, P);
			return NULL;
		}
		LOG("So S ---> %S\n", S->translate_text);
		return Inode::error(P, I"duplicated symbol", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::local_defn(inter_tree_node *P, int index, inter_symbols_table *T) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, P->W.instruction[index]);
	if (S == NULL) return Inode::error(P, I"no symbol for ID (case 2)", NULL);
	if ((Inter::Symbols::is_defined(S)) &&
		(Inter::Symbols::is_predeclared_local(S) == FALSE))
		return Inode::error(P, I"duplicated local symbol", S->symbol_name);
	Inter::Symbols::define(S, P);
	return NULL;
}

inter_error_message *Inter::Verify::symbol(inter_package *owner, inter_tree_node *P, inter_ti ID, inter_ti construct) {
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, ID);
	if (S == NULL) return Inode::error(P, I"no symbol for ID (case 3)", NULL);
	inter_tree_node *D = Inter::Symbols::definition(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined symbol", S->symbol_name);
	if ((D->W.instruction[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inode::error(P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::global_symbol(inter_tree_node *P, inter_ti ID, inter_ti construct) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(Inode::globals(P), ID);
	if (S == NULL) { internal_error("IO"); return Inode::error(P, I"3no symbol for ID", NULL); }
	inter_tree_node *D = Inter::Symbols::definition(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined symbol", S->symbol_name);
	if ((D->W.instruction[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inode::error(P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::local_symbol(inter_tree_node *P, inter_ti ID, inter_ti construct, inter_symbols_table *T) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, ID);
	if (S == NULL) return Inode::error(P, I"4no symbol for ID", NULL);
	inter_tree_node *D = Inter::Symbols::definition(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined symbol", S->symbol_name);
	if ((D->W.instruction[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inode::error(P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::symbol_KOI(inter_package *owner, inter_tree_node *P, inter_ti ID) {
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, ID);
	if (S == NULL) return Inode::error(P, I"5no symbol for ID", NULL);
	inter_tree_node *D = Inter::Symbols::definition(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined symbol", S->symbol_name);
	if ((D->W.instruction[ID_IFLD] != KIND_IST) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) return Inode::error(P, I"symbol of wrong type", S->symbol_name);
	return NULL;
}

inter_error_message *Inter::Verify::data_type(inter_tree_node *P, int index) {
	inter_ti ID = P->W.instruction[index];
	inter_data_type *idt = Inter::Types::find_by_ID(ID);
	if (idt == NULL) return Inode::error(P, I"unknown data type", NULL);
	return NULL;
}

inter_error_message *Inter::Verify::value(inter_package *owner, inter_tree_node *P, int index, inter_symbol *kind_symbol) {
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	if (kind_symbol == NULL) return Inode::error(P, I"unknown kind for value", NULL);
	inter_ti V1 = P->W.instruction[index];
	inter_ti V2 = P->W.instruction[index+1];
	return Inter::Types::verify(P, kind_symbol, V1, V2, T);
}

inter_error_message *Inter::Verify::local_value(inter_tree_node *P, int index, inter_symbol *kind_symbol, inter_symbols_table *T) {
	if (kind_symbol == NULL) return Inode::error(P, I"unknown kind for value", NULL);
	inter_ti V1 = P->W.instruction[index];
	inter_ti V2 = P->W.instruction[index+1];
	return Inter::Types::verify(P, kind_symbol, V1, V2, T);
}

void Inter::Verify::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_tree_node *F = (inter_tree_node *) vI;
	if (F == NULL) { WRITE("<no frame>"); return; }
	WRITE("%05d -> ", F->W.index);
	WRITE("%d {", F->W.extent);
	for (int i=0; i<F->W.extent; i++) WRITE(" %08x", F->W.instruction[i]);
	WRITE(" }");
}
