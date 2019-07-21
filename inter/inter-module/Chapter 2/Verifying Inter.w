[Inter::Verify::] Verifying Inter.

Verifying that a chunk of inter is correct and consistent.

@ =
inter_error_message *Inter::Verify::defn(inter_package *owner, inter_frame P, int index) {
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::Frame::globals(&P);
	inter_symbol *S = Inter::SymbolsTables::unequated_symbol_from_id(T, P.data[index]);
	if (S == NULL) return Inter::Frame::error(&P, I"no symbol for ID (case 1)", NULL);
	if (S->equated_to) {
		LOG("This is $6 but %S equates to a symbol in $6\n",
			Inter::Packages::container(P), S->symbol_name, Inter::Packages::container(S->equated_to->definition));
		return Inter::Frame::error(&P, I"symbol defined outside its native scope", S->symbol_name);
	}
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Frame::valid(&D) == FALSE) Inter::Symbols::define(S, P);
	else if (Inter::Frame::eq(&D, &P) == FALSE) {
		if (Inter::Symbols::is_predeclared(S)) {
			Inter::Symbols::define(S, P);
			return NULL;
		}
		return Inter::Frame::error(&P, I"duplicated symbol", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::local_defn(inter_frame P, int index, inter_symbols_table *T) {
	inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, P.data[index]);
	if (S == NULL) return Inter::Frame::error(&P, I"no symbol for ID (case 2)", NULL);
	if ((S->definition_status != UNDEFINED_ISYMD) &&
		(Inter::Symbols::is_predeclared_local(S) == FALSE))
		return Inter::Frame::error(&P, I"duplicated symbol", S->symbol_name);
	Inter::Symbols::define(S, P);
	return NULL;
}

inter_error_message *Inter::Verify::symbol(inter_package *owner, inter_frame P, inter_t ID, inter_t construct) {
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::Frame::globals(&P);
	inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, ID);
	if (S == NULL) return Inter::Frame::error(&P, I"no symbol for ID (case 3)", NULL);
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (Inter::Frame::valid(&D) == FALSE) return Inter::Frame::error(&P, I"undefined symbol", S->symbol_name);
	if ((D.data[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inter::Frame::error(&P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::global_symbol(inter_frame P, inter_t ID, inter_t construct) {
	inter_symbol *S = Inter::SymbolsTables::symbol_from_id(Inter::Frame::globals(&P), ID);
	if (S == NULL) { internal_error("IO"); return Inter::Frame::error(&P, I"3no symbol for ID", NULL); }
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (Inter::Frame::valid(&D) == FALSE) return Inter::Frame::error(&P, I"undefined symbol", S->symbol_name);
	if ((D.data[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inter::Frame::error(&P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::local_symbol(inter_frame P, inter_t ID, inter_t construct, inter_symbols_table *T) {
	inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, ID);
	if (S == NULL) return Inter::Frame::error(&P, I"4no symbol for ID", NULL);
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (Inter::Frame::valid(&D) == FALSE) return Inter::Frame::error(&P, I"undefined symbol", S->symbol_name);
	if ((D.data[ID_IFLD] != construct) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) {
		return Inter::Frame::error(&P, I"symbol of wrong type", S->symbol_name);
	}
	return NULL;
}

inter_error_message *Inter::Verify::symbol_KOI(inter_package *owner, inter_frame P, inter_t ID) {
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::Frame::globals(&P);
	inter_symbol *S = Inter::SymbolsTables::symbol_from_id(T, ID);
	if (S == NULL) return Inter::Frame::error(&P, I"5no symbol for ID", NULL);
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Symbols::is_extern(S)) return NULL;
	if (Inter::Symbols::is_predeclared(S)) return NULL;
	if (Inter::Frame::valid(&D) == FALSE) return Inter::Frame::error(&P, I"undefined symbol", S->symbol_name);
	if ((D.data[ID_IFLD] != KIND_IST) &&
		(Inter::Symbols::is_extern(S) == FALSE) &&
		(D.data[ID_IFLD] != INSTANCE_IST) &&
		(Inter::Symbols::is_predeclared(S) == FALSE)) return Inter::Frame::error(&P, I"symbol of wrong type", S->symbol_name);
	return NULL;
}

inter_error_message *Inter::Verify::data_type(inter_frame P, int index) {
	inter_t ID = P.data[index];
	inter_data_type *idt = Inter::Types::find_by_ID(ID);
	if (idt == NULL) return Inter::Frame::error(&P, I"unknown data type", NULL);
	return NULL;
}

inter_error_message *Inter::Verify::value(inter_package *owner, inter_frame P, int index, inter_symbol *kind_symbol) {
	inter_symbols_table *T = Inter::Packages::scope(owner);
	if (T == NULL) T = Inter::Frame::globals(&P);
	if (kind_symbol == NULL) return Inter::Frame::error(&P, I"unknown kind for value", NULL);
	inter_t V1 = P.data[index];
	inter_t V2 = P.data[index+1];
	return Inter::Types::verify(P, kind_symbol, V1, V2, T);
}

inter_error_message *Inter::Verify::local_value(inter_frame P, int index, inter_symbol *kind_symbol, inter_symbols_table *T) {
	if (kind_symbol == NULL) return Inter::Frame::error(&P, I"unknown kind for value", NULL);
	inter_t V1 = P.data[index];
	inter_t V2 = P.data[index+1];
	return Inter::Types::verify(P, kind_symbol, V1, V2, T);
}

void Inter::Verify::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_frame *F = (inter_frame *) vI;
	if (F == NULL) { WRITE("<no frame>"); return; }
	if (F->repo_segment)
		WRITE("%d.%05d -> ", F->repo_segment->allocation_id, F->index);
	WRITE("%d {", F->extent);
	for (int i=0; i<F->extent; i++) WRITE(" %08x", F->data[i]);
	WRITE(" }");
}
