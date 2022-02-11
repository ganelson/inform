[TextualInter::] Inter in Text Files.

To read a tree from a file written in the plain text version of Inter.

@h Reading textual inter.
The test group |:syntax| of Inter test cases may be useful in checking
the code below. Anyway, here we import the content of the file |F| into the
tree |I|.

=
void TextualInter::read(inter_tree *I, filename *F) {
	LOGIF(INTER_FILE_READ, "Reading textual inter file %f\n", F);
	irl_state irl;
	irl.no_blank_lines_stacked = 0;
	inter_bookmark IBM = InterBookmark::at_start_of_this_repository(I);
	irl.write_pos = &IBM;
	TextFiles::read(F, FALSE, "can't open inter file", FALSE,
		TextualInter::read_line, 0, &irl);
	TextualInter::resolve_forward_references(I);
	InterConstruct::tree_lint(I);
	Primitives::index_primitives_in_tree(I);
}

@ This fussy little mechanism passes each line of the text file to
//TextualInter::parse_single_line//, except that it omits any run of blank
lines at the end. (Most text files technically have one blank line at the end
without anyone realising it.) By blank, we mean completely devoid of characters:
a line containing spaces or tabs is not blank in this sense.

=
typedef struct irl_state {
	int no_blank_lines_stacked;
	struct inter_bookmark *write_pos;
} irl_state;

void TextualInter::read_line(text_stream *line, text_file_position *tfp, void *state) {
	irl_state *irl = (irl_state *) state;
	inter_error_location eloc = Inter::Errors::file_location(line, tfp);
	if (Str::len(line) == 0) { irl->no_blank_lines_stacked++; return; }
	for (int i=0; i<irl->no_blank_lines_stacked; i++) {
		inter_error_location b_eloc = Inter::Errors::file_location(I"", tfp);
		inter_error_message *E =
			TextualInter::parse_single_line(Str::new(), &b_eloc, irl->write_pos);
		if (E) Inter::Errors::issue(E);
	}
	irl->no_blank_lines_stacked = 0;
	inter_error_message *E =
		TextualInter::parse_single_line(line, &eloc, irl->write_pos);
	if (E) Inter::Errors::issue(E);
}

@ The following is called not only by the above but also when creating primitives.
See //building: Inter Primitives//.

=
typedef struct inter_line_parse {
	struct text_stream *line;
	struct match_results mr;
	struct inter_annotation_set set;
	int indent_level;
} inter_line_parse;

inter_error_message *TextualInter::parse_single_line(text_stream *line,
	inter_error_location *eloc, inter_bookmark *write_pos) {
	inter_line_parse ilp;
	ilp.line = line;
	ilp.mr = Regexp::create_mr();
	ilp.set = SymbolAnnotation::new_annotation_set();
	ilp.indent_level = 0;
	@<Find indentation@>;

	if (ilp.indent_level == 0) TextualInter::set_latest_block_package(NULL);

	@<If the indentation is now lower than expected, move the write position up the tree@>;
	@<Parse any annotations at the end of the line@>;
	
	return InterConstruct::match(&ilp, eloc, write_pos);
}

@ We are a bit aggressive in requiring the Python-style indentation at the start
of each line to be made of tabs, not spaces. If we intended textual Inter to be
a programming language for humans to use, we might be more accommodating. But it's
really an interchange format for programs to use.

A blank line is treated as a comment, so we rewrite it with the explicit |#|
notation. If it is printed back, it will actually be printed back as empty
anyway -- see //Inter::Comment::write//. So nobody will ever know our little
deception.

@<Find indentation@> =
	LOOP_THROUGH_TEXT(P, ilp.line) {
		wchar_t c = Str::get(P);
		if (c == '\t') ilp.indent_level++;
		else if (c == ' ') return Inter::Errors::plain(
			I"spaces (rather than tabs) at beginning of line", eloc);
		else break;
	}
	Str::trim_white_space(ilp.line);
	if (Str::len(ilp.line) == 0) PUT_TO(ilp.line, '#');

@ So suppose the write position is in a package where the contents are at
level 7 in the tree hierarchy, but we seem to be reading a line with indentation
5, and which therefore wants to put an instruction in at level 5. This means it
is intended not for the current package but for the parent of the parent of
that package, so we take two steps upwards in the tree.

After doing all this, then, the write position is in the correct package for
where the node is asking to go. (And if the indentation was 0, that will be the
root package of the tree.)

@<If the indentation is now lower than expected, move the write position up the tree@> =
	while ((InterBookmark::package(write_pos)) &&
		(InterPackage::is_a_root_package(InterBookmark::package(write_pos)) == FALSE) &&
		(ilp.indent_level <= InterBookmark::baseline(write_pos)))
		InterBookmark::move_into_package(write_pos,
			InterPackage::parent(InterBookmark::package(write_pos)));

@ A line ending, e.g., |... _bar _foo=2| has those annotations parsed and trimmed
away. The result of the parsing goes into the annotation set |ilp.set|. Note
that we do nothing with that result here -- it will be up to the |CONSTRUCT_READ_MTID|
method for the construct used on the line to make use of the set, or not, as it
pleases.

@<Parse any annotations at the end of the line@> =
	int quoted = FALSE, cutoff = -1;
	for (int i = 0; i < Str::len(ilp.line); i++) {
		wchar_t c = Str::get_at(ilp.line, i);
		if (c == '"') quoted = quoted?FALSE:TRUE;
		else if (c == '\\') i++;
		else if ((quoted == FALSE) && (i > 0) &&
			(Characters::is_whitespace(Str::get_at(ilp.line, i-1))) &&
			(c == '_') && (Str::get_at(ilp.line, i+1) == '_')) {
			if (cutoff == -1) cutoff = i-1;
			TEMPORARY_TEXT(annot)
			while ((i < Str::len(ilp.line)) &&
				((quoted) ||
					(Characters::is_whitespace(Str::get_at(ilp.line, i)) == FALSE))) {
				c = Str::get_at(ilp.line, i);
				if ((c == '"') && (Str::get_at(ilp.line, i-1) != '\\'))
					quoted = quoted?FALSE:TRUE;
				PUT_TO(annot, c);
				i++;
			}
			inter_error_message *E = NULL;
			inter_annotation IA = SymbolAnnotation::read_annotation(
				InterBookmark::tree(write_pos), annot, eloc, &E);
			if (E) return E;
			SymbolAnnotation::write_to_set(IA.annot->iatype, &(ilp.set), IA);
			DISCARD_TEXT(annot)
		}
	}
	if (cutoff >= 0) Str::put_at(ilp.line, cutoff, 0);

@h Writing textual inter.
This more or less reverses the above process:

=
void TextualInter::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_tree *I = (inter_tree *) vI;
	TextualInter::write(OUT, I, NULL, 1);
}

typedef struct textual_write_state {
	struct text_stream *to;
	int (*filter)(inter_tree_node, int);
	int pass;
} textual_write_state;

void TextualInter::write(OUTPUT_STREAM, inter_tree *I, int (*filter)(inter_tree_node, int), int pass) {
	if (I == NULL) { WRITE("<no-inter>\n"); return; }
	textual_write_state tws;
	tws.to = OUT;
	tws.filter = filter;
	tws.pass = pass;
	InterTree::traverse_root_only(I, TextualInter::visitor, &tws, -PACKAGE_IST);
	InterTree::traverse(I, TextualInter::visitor, &tws, NULL, 0);
}
void TextualInter::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	textual_write_state *tws = (textual_write_state *) state;
	if ((tws->filter) && ((*(tws->filter))(*P, tws->pass) == FALSE)) return;
	inter_error_message *E = InterConstruct::write_construct_text(tws->to, P);
	if (E) Inter::Errors::issue(E);
}

@ =
inter_symbol *TextualInter::new_symbol(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb) {
		if (InterSymbol::misc_but_undefined(symb)) return symb;
		*E = Inter::Errors::quoted(I"symbol already exists", name, eloc);
		return NULL;
	}
	return InterSymbolsTable::symbol_from_name_creating(T, name);
}

void TextualInter::write_symbol(OUTPUT_STREAM, inter_symbol *symb) {
	if (Wiring::is_wired(symb)) {
		InterSymbolsTable::write_symbol_URL(OUT, Wiring::cable_end(symb));
	} else if (symb) {
		WRITE("%S", symb->symbol_name);
	} else {
		WRITE("<invalid-symbol>");
	}
}

void TextualInter::write_symbol_from(OUTPUT_STREAM, inter_tree_node *P, int field) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_not_following(
		InterPackage::scope_of(P), P->W.instruction[field]);
	TextualInter::write_symbol(OUT, S);
}

inter_symbol *TextualInter::find_symbol(inter_bookmark *IBM, inter_error_location *eloc, text_stream *name, inter_ti construct, inter_error_message **E) {
	inter_symbols_table *T = InterBookmark::scope(IBM);
	*E = NULL;
	inter_symbol *symb = NULL;
	if (Str::get_first_char(name) == '/') {
		symb = InterSymbolsTable::URL_to_symbol(InterBookmark::tree(IBM), name);
		if (symb == NULL) {
			TEMPORARY_TEXT(leaf)
			LOOP_THROUGH_TEXT(pos, name) {
				wchar_t c = Str::get(pos);
				if (c == '/') Str::clear(leaf);
				else PUT_TO(leaf, c);
			}
			if (Str::len(leaf) == 0) {
				*E = Inter::Errors::quoted(I"URL ends in '/'", name, eloc);
				return NULL;
			}
			symb = InterSymbolsTable::symbol_from_name(T, leaf);
			if (!((symb) && (Wiring::is_wired_to_name(symb)) && (Str::eq(Wiring::wired_to_name(symb), name)))) {			
				symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), leaf);
				Wiring::wire_to_name(symb, name);
			}
			DISCARD_TEXT(leaf)
		}
	} else {
		symb = InterSymbolsTable::symbol_from_name(T, name);
	}
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	if (construct == 0) return symb;
	inter_tree_node *D = InterSymbol::definition(symb);
	if (InterSymbol::defined_elsewhere(symb)) return symb;
	if (InterSymbol::misc_but_undefined(symb)) return symb;
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != construct) && (InterSymbol::misc_but_undefined(symb) == FALSE)) {
		*E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}
	return symb;
}

inter_symbol *TextualInter::find_global_symbol(inter_bookmark *IBM, inter_error_location *eloc, text_stream *name, inter_ti construct, inter_error_message **E) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_symbols_table *T = InterTree::global_scope(I);
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = InterSymbol::definition(symb);
	if (InterSymbol::defined_elsewhere(symb)) return symb;
	if (InterSymbol::misc_but_undefined(symb)) return symb;
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != construct) && (InterSymbol::misc_but_undefined(symb) == FALSE)) {
		*E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}
	return symb;
}

inter_symbol *TextualInter::find_KOI(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = Inter::Errors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) { *E = Inter::Errors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != KIND_IST) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST)) { *E = Inter::Errors::quoted(I"symbol of wrong type", name, eloc); return NULL; }
	return symb;
}

inter_data_type *TextualInter::data_type(inter_error_location *eloc, text_stream *name, inter_error_message **E) {
	inter_data_type *idt = Inter::Types::find_by_name(name);
	if (idt == NULL) *E = Inter::Errors::quoted(I"no such data type", name, eloc);
	return idt;
}

@h Forward references.

=
void TextualInter::resolve_forward_references(inter_tree *I) {
	inter_error_location eloc = Inter::Errors::file_location(NULL, NULL);
	InterTree::traverse(I, TextualInter::rfr_visitor, &eloc, NULL, PACKAGE_IST);
}

void TextualInter::rfr_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_location *eloc = (inter_error_location *) state;
	inter_package *pack = InterPackage::at_this_head(P);
	if (pack == NULL) internal_error("no package defined here");
	inter_symbols_table *T = InterPackage::scope(pack);
	if (T == NULL) internal_error("package with no symbols");
	for (int i=0; i<T->symbol_array_size; i++) {
		inter_symbol *symb = T->symbol_array[i];
		if (Wiring::is_wired_to_name(symb)) {
			text_stream *N = Wiring::wired_to_name(symb);
			if (InterSymbol::is_plug(symb)) continue;
			inter_symbol *S_to = InterSymbolsTable::URL_to_symbol(InterPackage::tree(pack), N);
			if (S_to == NULL) S_to = InterSymbolsTable::symbol_from_name(T, N);
			if (S_to == NULL) Inter::Errors::issue(Inter::Errors::quoted(I"unable to locate symbol", N, eloc));
			else if (InterSymbol::is_socket(symb))
				Wiring::make_socket_to(symb, S_to);
			else Wiring::wire_to(symb, S_to);
		}
	}
}

inter_package *latest_block_package = NULL;

void TextualInter::set_latest_block_package(inter_package *F) {
	latest_block_package = F;
}

inter_package *TextualInter::get_latest_block_package(void) {
	return latest_block_package;
}
