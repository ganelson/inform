[InterSymbol::] Symbols.

To manage named symbols in inter code.

@h Symbols themselves.

=
typedef struct inter_symbol {
	inter_ti symbol_ID;
	struct inter_symbols_table *owning_table;
	struct text_stream *symbol_name;
	struct inter_tree_node *definition;
	struct wiring_data wiring;
	int symbol_status;
	struct inter_annotation_set ann_set;
	struct text_stream *translate_text;
	int link_time;
	struct inter_symbol *linked_to;
	struct general_pointer translation_data;
} inter_symbol;

@ =
inter_symbol *InterSymbol::new(text_stream *name, inter_symbols_table *T, inter_ti ID) {
	if (Str::len(name) == 0) internal_error("symbol cannot have empty text as identifier");
	inter_symbol *symb = CREATE(inter_symbol);
	symb->owning_table = T;
	symb->symbol_ID = ID;
	symb->symbol_status = 0;
	InterSymbol::set_type(symb, MISC_ISYMT);
	InterSymbol::set_scope(symb, PUBLIC_ISYMS);
	symb->symbol_name = Str::duplicate(name);
	InterSymbol::undefine(symb);
	symb->ann_set = Inter::Annotations::new_set();
	symb->wiring = Wiring::new_wiring_data(symb);
	symb->translate_text = NULL;
	symb->link_time = 0;
	symb->linked_to = NULL;
	symb->translation_data = NULL_GENERAL_POINTER;
	if (Metadata::valid_key(name)) {
		InterSymbol::set_flag(symb, METADATA_KEY_BIT);
		InterSymbol::set_scope(symb, PRIVATE_ISYMS);
	}
	LOGIF(INTER_SYMBOLS, "Created symbol $3 in $4\n", symb, T);

	return symb;
}

inter_package *InterSymbol::package(inter_symbol *S) {
	if (S == NULL) return NULL;
	return InterSymbolsTable::package(S->owning_table);
}

int InterSymbol::is_metadata_key(inter_symbol *S) {
	return InterSymbol::get_flag(S, METADATA_KEY_BIT);
}

int InterSymbol::get_type(inter_symbol *S) {
	return S->symbol_status & SYMBOL_TYPE_MASK_ISYMT;
}

int InterSymbol::get_scope(inter_symbol *S) {
	return S->symbol_status & SYMBOL_SCOPE_MASK_ISYMT;
}

void InterSymbol::set_type(inter_symbol *S, int V) {
	S->symbol_status = S->symbol_status - (S->symbol_status & SYMBOL_TYPE_MASK_ISYMT) + V;
}

void InterSymbol::set_scope(inter_symbol *S, int V) {
	S->symbol_status = S->symbol_status - (S->symbol_status & SYMBOL_SCOPE_MASK_ISYMT) + V;
}

void InterSymbol::log(OUTPUT_STREAM, void *vs) {
	inter_symbol *S = (inter_symbol *) vs;
	if (S == NULL) WRITE("<no-symbol>");
	else {
		InterSymbolsTable::write_symbol_URL(DL, S);
		WRITE("{%d}", S->symbol_ID - SYMBOL_BASE_VAL);
		if (Str::len(S->translate_text) > 0) WRITE("'%S'", S->translate_text);
	}
}

int InterSymbol::sort_number(const inter_symbol *S) {
	if (S == NULL) return 0;
	return 100000 * (S->owning_table->allocation_id) + (int) (S->symbol_ID);
}

@ =
int InterSymbol::is_stored_in_data(inter_ti val1, inter_ti val2) {
	if (val1 == ALIAS_IVAL) return TRUE;
	return FALSE;
}

void InterSymbol::to_data(inter_tree *I, inter_package *pack, inter_symbol *S, inter_ti *val1, inter_ti *val2) {
	if (S == NULL) internal_error("no symbol");
	*val1 = ALIAS_IVAL; *val2 = InterSymbolsTable::id_from_symbol(I, pack, S);
}

@ =
void InterSymbol::write_declaration(OUTPUT_STREAM, inter_symbol *mark, int N) {
	for (int L=0; L<N; L++) WRITE("\t");
	WRITE("symbol ");
	switch (InterSymbol::get_scope(mark)) {
		case PRIVATE_ISYMS: WRITE("private"); break;
		case PUBLIC_ISYMS: WRITE("public"); break;
		case EXTERNAL_ISYMS: WRITE("external"); break;
		case PLUG_ISYMS: WRITE("plug"); break;
		case SOCKET_ISYMS: WRITE("socket"); break;
		default: internal_error("unknown symbol type"); break;
	}
	WRITE(" ");
	switch (InterSymbol::get_type(mark)) {
		case LABEL_ISYMT: WRITE("label"); break;
		case MISC_ISYMT: WRITE("misc"); break;
		case PACKAGE_ISYMT: WRITE("package"); break;
		case PTYPE_ISYMT: WRITE("packagetype"); break;
		default: internal_error("unknown symbol type"); break;
	}
	WRITE(" %S", mark->symbol_name);
	if (InterSymbol::get_flag(mark, MAKE_NAME_UNIQUE)) WRITE("*");
	if (Wiring::is_wired_to_name(mark)) {
		WRITE(" --? %S", Wiring::wired_to_name(mark));
	}
	text_stream *trans_name = InterSymbol::get_translate(mark);
	if (Str::len(trans_name) > 0)
		WRITE(" `%S`", trans_name);
	if (Wiring::is_wired(mark)) {
		WRITE(" --> ");
		InterSymbolsTable::write_symbol_URL(OUT, Wiring::wired_to(mark));
	}
}

void InterSymbol::define(inter_symbol *S, inter_tree_node *P) {
	if (S == NULL) internal_error("tried to define null symbol");
	S->definition = P;
}

inter_tree_node *InterSymbol::definition(inter_symbol *S) {
	if (S == NULL) internal_error("tried to find definition of null symbol");
	return S->definition;
}

int InterSymbol::is_defined(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::definition(S)) return TRUE;
	return FALSE;
}

int InterSymbol::evaluate_to_int(inter_symbol *S) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P->W.instruction[DATA_CONST_IFLD] == LITERAL_IVAL)) {
		return (int) P->W.instruction[DATA_CONST_IFLD + 1];
	}
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P->W.instruction[DATA_CONST_IFLD] == ALIAS_IVAL)) {
		inter_symbols_table *scope = S->owning_table;
		inter_symbol *alias_to = InterSymbolsTable::symbol_from_ID(scope, P->W.instruction[DATA_CONST_IFLD + 1]);
		return InterSymbol::evaluate_to_int(alias_to);
	}
	return -1;
}

void InterSymbol::set_int(inter_symbol *S, int N) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P->W.instruction[DATA_CONST_IFLD] == LITERAL_IVAL)) {
		P->W.instruction[DATA_CONST_IFLD + 1] = (inter_ti) N;
		return;
	}
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P->W.instruction[DATA_CONST_IFLD] == ALIAS_IVAL)) {
		inter_symbols_table *scope = S->owning_table;
		inter_symbol *alias_to = InterSymbolsTable::symbol_from_ID(scope, P->W.instruction[DATA_CONST_IFLD + 1]);
		InterSymbol::set_int(alias_to, N);
		return;
	}
	if (P == NULL) LOG("Synbol $3 is undefined\n", S);
	LOG("Synbol $3 cannot be set to %d\n", S, N);
	internal_error("unable to set symbol");
}

void InterSymbol::strike_definition(inter_symbol *S) {
	if (S) {
		inter_tree_node *D = InterSymbol::definition(S);
		if (D) NodePlacement::remove(D);
		InterSymbol::undefine(S);
	}
}

void InterSymbol::undefine(inter_symbol *S) {
	if (S == NULL) internal_error("tried to undefine null symbol");
	S->definition = NULL;
}

void InterSymbol::clear_transient_flags(inter_symbol *symb) {
	symb->symbol_status = (symb->symbol_status) & NONTRANSIENT_SYMBOL_BITS;
}

int InterSymbol::get_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	return (symb->symbol_status & f)?TRUE:FALSE;
}

void InterSymbol::set_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	symb->symbol_status = symb->symbol_status | f;
}

void InterSymbol::clear_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	if (symb->symbol_status & f) symb->symbol_status = symb->symbol_status - f;
}

void InterSymbol::set_translate(inter_symbol *symb, text_stream *S) {
	if (symb == NULL) internal_error("no symbol");
	symb->translate_text = Str::duplicate(S);
}

text_stream *InterSymbol::get_translate(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->translate_text;
}

void InterSymbol::annotate(inter_symbol *symb, inter_annotation IA) {
	if (symb == NULL) internal_error("annotated null symbol");
	Inter::Annotations::add_to_set(&(symb->ann_set), IA);
}

void InterSymbol::unannotate(inter_symbol *symb, inter_ti annot_ID) {
	if (symb == NULL) internal_error("annotated null symbol");
	Inter::Annotations::remove_from_set(&(symb->ann_set), annot_ID);
}

void InterSymbol::annotate_i(inter_symbol *symb, inter_ti annot_ID, inter_ti n) {
	inter_annotation IA = Inter::Annotations::from_bytecode(annot_ID, n);
	InterSymbol::annotate(symb, IA);
}

int InterSymbol::read_annotation(const inter_symbol *symb, inter_ti ID) {
	inter_annotation *IA = Inter::Annotations::find(&(symb->ann_set), ID);
	if (IA) return (int) IA->annot_value;
	return -1;
}

text_stream *InterSymbol::read_annotation_t(inter_symbol *symb, inter_tree *I, inter_ti ID) {
	inter_annotation *IA = Inter::Annotations::find(&(symb->ann_set), ID);
	if (IA) return InterWarehouse::get_text(InterTree::warehouse(I), IA->annot_value);
	return NULL;
}

void InterSymbol::annotate_t(inter_tree *I, inter_package *owner, inter_symbol *symb, inter_ti annot_ID, text_stream *S) {
	inter_ti n = InterWarehouse::create_text(InterTree::warehouse(I), owner);
	Str::copy(InterWarehouse::get_text(InterTree::warehouse(I), n), S);
	inter_annotation IA = Inter::Annotations::from_bytecode(annot_ID, n);
	InterSymbol::annotate(symb, IA);
}

void InterSymbol::write_annotations(OUTPUT_STREAM, inter_tree_node *F, inter_symbol *symb) {
	if (symb) Inter::Annotations::write_set(OUT, &(symb->ann_set), F);
}

void InterSymbol::transpose_annotations(inter_symbol *symb, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	if (symb) Inter::Annotations::transpose_set(&(symb->ann_set), grid, grid_extent, E);
}

@ =
int InterSymbol::is_predeclared(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) != PUBLIC_ISYMS) return FALSE;
	if (InterSymbol::get_type(S) != MISC_ISYMT) return FALSE;
	if (InterSymbol::is_defined(S)) return FALSE;
	return TRUE;
}

int InterSymbol::is_predeclared_local(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) != PRIVATE_ISYMS) return FALSE;
	if (InterSymbol::get_type(S) != MISC_ISYMT) return FALSE;
	if (InterSymbol::is_defined(S)) return FALSE;
	return TRUE;
}

int InterSymbol::is_undefined_private(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) != PRIVATE_ISYMS) return FALSE;
	if (InterSymbol::is_defined(S)) return FALSE;
	return TRUE;
}

int InterSymbol::is_extern(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) == EXTERNAL_ISYMS) return TRUE;
	if (InterSymbol::get_scope(S) == PLUG_ISYMS) return TRUE;
	return FALSE;
}

void InterSymbol::extern(inter_symbol *S) {
	InterSymbol::set_scope(S, EXTERNAL_ISYMS);
	InterSymbol::set_type(S, MISC_ISYMT);
	S->definition = NULL;
}

int InterSymbol::is_label(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) != PRIVATE_ISYMS) return FALSE;
	if (InterSymbol::get_type(S) != LABEL_ISYMT) return FALSE;
	return TRUE;
}

void InterSymbol::label(inter_symbol *S) {
	if (Str::get_first_char(S->symbol_name) != '.') {
		LOG("Name is %S\n", S->symbol_name);
		internal_error("not a label name");
	}
	InterSymbol::set_scope(S, PRIVATE_ISYMS);
	InterSymbol::set_type(S, LABEL_ISYMT);
	S->definition = NULL;
}

void InterSymbol::local(inter_symbol *S) {
	InterSymbol::set_scope(S, PRIVATE_ISYMS);
	InterSymbol::set_type(S, MISC_ISYMT);
	S->definition = NULL;
}

int InterSymbol::is_local(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::get_scope(S) != PRIVATE_ISYMS) return FALSE;
	if (InterSymbol::get_type(S) != MISC_ISYMT) return FALSE;
	return TRUE;
}

int InterSymbol::is_connector(inter_symbol *S) {
	if ((S) && ((InterSymbol::get_scope(S) == PLUG_ISYMS) ||
		(InterSymbol::get_scope(S) == SOCKET_ISYMS)))
		return TRUE;
	return FALSE;
}

text_stream *InterSymbol::name(inter_symbol *symb) {
	if (symb == NULL) return NULL;
	if (InterSymbol::get_translate(symb)) return InterSymbol::get_translate(symb);
	return symb->symbol_name;
}
