[Inter::Textual::] Inter in Text Files.

To read inter from a textual file.

@h Reading textual inter.

=
int no_blank_lines_stacked = 0;

void Inter::Textual::read(inter_repository *I, filename *F) {
	LOGIF(INTER_FILE_READ, "(Reading textual inter file %f)\n", F);
	no_blank_lines_stacked = 0;
	inter_bookmark IBM = Inter::Bookmarks::at_start_of_this_repository(I);
	inter_error_location eloc = Inter::Errors::file_location(NULL, NULL);
	TextFiles::read(F, FALSE, "can't open inter file", FALSE, Inter::Textual::read_line, 0, &IBM);
	Inter::SymbolsTables::resolve_forward_references(I, &eloc);
	Inter::traverse_tree(I, Inter::Textual::lint_visitor, NULL, NULL, -PACKAGE_IST);
}

void Inter::Textual::lint_visitor(inter_repository *I, inter_frame P, void *state) {
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

inter_symbol *Inter::Textual::find_symbol(inter_repository *I, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_t construct, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_frame D = Inter::Symbols::defining_frame(symb);
	if (Inter::Symbols::is_extern(symb)) return symb;
	if (Inter::Symbols::is_predeclared(symb)) return symb;
	if (Inter::Frame::valid(&D) == FALSE) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D.data[ID_IFLD] != construct) && (Inter::Symbols::is_predeclared(symb) == FALSE)) {
		*E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_undefined_symbol(inter_bookmark *IBM, inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	if ((symb->definition_status != UNDEFINED_ISYMD) &&
		(Inter::Symbols::is_predeclared(symb) == FALSE) &&
		(Inter::Symbols::is_predeclared_local(symb) == FALSE)) {
		WRITE_TO(STDERR, "Ho! %S\n", symb->symbol_name);
		Inter::Defn::write_construct_text(STDERR, Inter::Symbols::defining_frame(symb));
		*E = Inter::Errors::quoted(I"symbol already defined", name, eloc);
		return NULL;
	}
	return symb;
}

inter_symbol *Inter::Textual::find_KOI(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_frame D = Inter::Symbols::defining_frame(symb);
	if (Inter::Frame::valid(&D) == FALSE) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D.data[ID_IFLD] != KIND_IST) &&
		(D.data[ID_IFLD] != INSTANCE_IST)) { *E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL; }
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
	inter_repository *I = (inter_repository *) vI;
	Inter::Textual::write(OUT, I, NULL, 1);
}

typedef struct textual_write_state {
	struct text_stream *to;
	int (*filter)(inter_frame, int);
	int pass;
} textual_write_state;

void Inter::Textual::write(OUTPUT_STREAM, inter_repository *I, int (*filter)(inter_frame, int), int pass) {
	if (I == NULL) { WRITE("<no-inter>\n"); return; }
	textual_write_state tws;
	tws.to = OUT;
	tws.filter = filter;
	tws.pass = pass;
	Inter::traverse_global_list(I, Inter::Textual::visitor, &tws, -PACKAGE_IST);
	Inter::traverse_tree(I, Inter::Textual::visitor, &tws, NULL, 0);
}
void Inter::Textual::visitor(inter_repository *I, inter_frame P, void *state) {
	textual_write_state *tws = (textual_write_state *) state;
	if ((tws->filter) && ((*(tws->filter))(P, tws->pass) == FALSE)) return;
	inter_error_message *E = Inter::Defn::write_construct_text(tws->to, P);
	if (E) Inter::Errors::issue(E);
}
