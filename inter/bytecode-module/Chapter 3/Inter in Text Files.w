[Inter::Textual::] Inter in Text Files.

To read inter from a textual file.

@h Reading textual inter.

=
int no_blank_lines_stacked = 0;

void Inter::Textual::read(inter_tree *I, filename *F) {
	LOGIF(INTER_FILE_READ, "(Reading textual inter file %f)\n", F);
	no_blank_lines_stacked = 0;
	inter_bookmark IBM = InterBookmark::at_start_of_this_repository(I);
	inter_error_location eloc = Inter::Errors::file_location(NULL, NULL);
	TextFiles::read(F, FALSE, "can't open inter file", FALSE, Inter::Textual::read_line, 0, &IBM);
	Inter::Textual::resolve_forward_references(I, &eloc);
	InterTree::traverse(I, Inter::Textual::lint_visitor, NULL, NULL, -PACKAGE_IST);
	Primitives::index_primitives_in_tree(I);
}

void Inter::Textual::lint_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_message *E = Inter::Defn::verify_children_inner(P);
	if (E) Inter::Errors::issue(E);
}

inter_symbol *Inter::Textual::new_symbol(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb) {
		if (InterSymbol::misc_public_and_undefined(symb)) {
			InterSymbol::undefine(symb);
			return symb;
		}
		*E = Inter::Errors::quoted(I"symbol already exists", name, eloc);
		return NULL;
	}
	return InterSymbolsTable::symbol_from_name_creating(T, name);
}

inter_symbol *Inter::Textual::find_symbol(inter_tree *I, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_ti construct, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = InterSymbol::definition(symb);
	if (InterSymbol::defined_elsewhere(symb)) return symb;
	if (InterSymbol::misc_public_and_undefined(symb)) return symb;
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != construct) && (InterSymbol::misc_public_and_undefined(symb) == FALSE)) {
		*E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_undefined_symbol(inter_bookmark *IBM, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	if ((InterSymbol::is_defined(symb)) &&
		(InterSymbol::misc_public_and_undefined(symb) == FALSE) &&
		(InterSymbol::misc_private_and_undefined(symb) == FALSE)) {
		WRITE_TO(STDERR, "Ho! %S\n", symb->symbol_name);
		inter_tree_node *D = InterSymbol::definition(symb);
		Inter::Defn::write_construct_text(STDERR, D);
		*E = Inter::Errors::quoted(I"symbol already defined", name, eloc);
		return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_KOI(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != KIND_IST) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST)) { *E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL; }
	return symb;
}

inter_data_type *Inter::Textual::data_type(inter_error_location *eloc, text_stream *name, inter_error_message **E) {
	inter_data_type *idt = Inter::Types::find_by_name(name);
	if (idt == NULL) *E = Inter::Errors::quoted(I"no such data type", name, eloc);
	return idt;
}

void Inter::Textual::read_line(text_stream *line, text_file_position *tfp, void *state) {
	inter_bookmark *IBM = (inter_bookmark *) state;
	inter_error_location eloc = Inter::Errors::file_location(line, tfp);
	if (Str::len(line) == 0) { no_blank_lines_stacked++; return; }
	for (int i=0; i<no_blank_lines_stacked; i++) {
		inter_error_location b_eloc = Inter::Errors::file_location(I"", tfp);
		inter_error_message *E = Inter::Defn::read_construct_text(I"", &b_eloc, IBM);
		if (E) Inter::Errors::issue(E);
	}
	no_blank_lines_stacked = 0;
	inter_error_message *E = Inter::Defn::read_construct_text(line, &eloc, IBM);
	if (E) Inter::Errors::issue(E);
}

@h Writing textual inter.

=
void Inter::Textual::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_tree *I = (inter_tree *) vI;
	Inter::Textual::write(OUT, I, NULL, 1);
}

typedef struct textual_write_state {
	struct text_stream *to;
	int (*filter)(inter_tree_node, int);
	int pass;
} textual_write_state;

void Inter::Textual::write(OUTPUT_STREAM, inter_tree *I, int (*filter)(inter_tree_node, int), int pass) {
	if (I == NULL) { WRITE("<no-inter>\n"); return; }
	textual_write_state tws;
	tws.to = OUT;
	tws.filter = filter;
	tws.pass = pass;
	InterTree::traverse_root_only(I, Inter::Textual::visitor, &tws, -PACKAGE_IST);
	InterTree::traverse(I, Inter::Textual::visitor, &tws, NULL, 0);
}
void Inter::Textual::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	textual_write_state *tws = (textual_write_state *) state;
	if ((tws->filter) && ((*(tws->filter))(*P, tws->pass) == FALSE)) return;
	inter_error_message *E = Inter::Defn::write_construct_text(tws->to, P);
	if (E) Inter::Errors::issue(E);
}

@h Forward references.

=
void Inter::Textual::resolve_forward_references(inter_tree *I, inter_error_location *eloc) {
	InterTree::traverse(I, Inter::Textual::rfr_visitor, eloc, NULL, PACKAGE_IST);
}

void Inter::Textual::rfr_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_location *eloc = (inter_error_location *) state;
	inter_package *pack = InterPackage::at_this_head(P);
	if (pack == NULL) internal_error("no package defined here");
	inter_symbols_table *T = InterPackage::scope(pack);
	if (T == NULL) internal_error("package with no symbols");
	for (int i=0; i<T->symbol_array_size; i++) {
		inter_symbol *symb = T->symbol_array[i];
		if (Wiring::is_wired_to_name(symb)) {
			text_stream *N = Wiring::wired_to_name(symb);
			if (InterSymbol::get_scope(symb) == PLUG_ISYMS) continue;
			inter_symbol *S_to = InterSymbolsTable::URL_to_symbol(InterPackage::tree(pack), N);
			if (S_to == NULL) S_to = InterSymbolsTable::symbol_from_name(T, N);
			if (S_to == NULL) Inter::Errors::issue(Inter::Errors::quoted(I"unable to locate symbol", N, eloc));
			else if (InterSymbol::get_scope(symb) == SOCKET_ISYMS)
				Wiring::convert_to_socket(symb, S_to);
			else Wiring::wire_to(symb, S_to);
		}
	}
}

