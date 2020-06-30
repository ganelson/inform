[Inter::Textual::] Inter in Text Files.

To read inter from a textual file.

@h Reading textual inter.

=
int no_blank_lines_stacked = 0;

void Inter::Textual::read(inter_tree *I, filename *F) {
	LOGIF(INTER_FILE_READ, "(Reading textual inter file %f)\n", F);
	default_ptree = I;
	no_blank_lines_stacked = 0;
	inter_bookmark IBM = Inter::Bookmarks::at_start_of_this_repository(I);
	inter_error_location eloc = Inter::Errors::file_location(NULL, NULL);
	TextFiles::read(F, FALSE, "can't open inter file", FALSE, Inter::Textual::read_line, 0, &IBM);
	Inter::SymbolsTables::resolve_forward_references(I, &eloc);
	default_ptree = NULL;
	Inter::Tree::traverse(I, Inter::Textual::lint_visitor, NULL, NULL, -PACKAGE_IST);
	Primitives::scan_tree(I);
}

void Inter::Textual::lint_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_message *E = Inter::Defn::verify_children_inner(P);
	if (E) Inter::Errors::issue(E);
}

inter_symbol *Inter::Textual::new_symbol(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb) {
		if (Inter::Symbols::is_predeclared(symb)) {
			Inter::Symbols::undefine(symb);
			return symb;
		}
		*E = Inter::Errors::quoted(I"symbol already exists", name, eloc);
		return NULL;
	}
	return Inter::SymbolsTables::symbol_from_name_creating(T, name);
}

inter_symbol *Inter::Textual::find_symbol(inter_tree *I, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_ti construct, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = Inter::Symbols::definition(symb);
	if (Inter::Symbols::is_extern(symb)) return symb;
	if (Inter::Symbols::is_predeclared(symb)) return symb;
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.data[ID_IFLD] != construct) && (Inter::Symbols::is_predeclared(symb) == FALSE)) {
		*E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_undefined_symbol(inter_bookmark *IBM, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	if ((Inter::Symbols::is_defined(symb)) &&
		(Inter::Symbols::is_predeclared(symb) == FALSE) &&
		(Inter::Symbols::is_predeclared_local(symb) == FALSE)) {
		WRITE_TO(STDERR, "Ho! %S\n", symb->symbol_name);
		inter_tree_node *D = Inter::Symbols::definition(symb);
		Inter::Defn::write_construct_text(STDERR, D);
		*E = Inter::Errors::quoted(I"symbol already defined", name, eloc);
		return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_KOI(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = Inter::Symbols::definition(symb);
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.data[ID_IFLD] != KIND_IST) &&
		(D->W.data[ID_IFLD] != INSTANCE_IST)) { *E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL; }
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
	Inter::Tree::traverse_root_only(I, Inter::Textual::visitor, &tws, -PACKAGE_IST);
	Inter::Tree::traverse(I, Inter::Textual::visitor, &tws, NULL, 0);
}
void Inter::Textual::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	textual_write_state *tws = (textual_write_state *) state;
	if ((tws->filter) && ((*(tws->filter))(*P, tws->pass) == FALSE)) return;
	inter_error_message *E = Inter::Defn::write_construct_text(tws->to, P);
	if (E) Inter::Errors::issue(E);
}
