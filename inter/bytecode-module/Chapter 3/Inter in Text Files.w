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
	inter_error_location eloc = InterErrors::file_location(line, tfp);
	if (Str::len(line) == 0) { irl->no_blank_lines_stacked++; return; }
	for (int i=0; i<irl->no_blank_lines_stacked; i++) {
		inter_error_location b_eloc = InterErrors::file_location(I"", tfp);
		inter_error_message *E =
			TextualInter::parse_single_line(Str::new(), &b_eloc, irl->write_pos);
		if (E) InterErrors::issue(E);
	}
	irl->no_blank_lines_stacked = 0;
	inter_error_message *E =
		TextualInter::parse_single_line(line, &eloc, irl->write_pos);
	if (E) InterErrors::issue(E);
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
		else if (c == ' ') return InterErrors::plain(
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

@h Utility functions for parsing construct lines.
First, the following tries to make a symbol with a given name in the given
scope; the name must currently be free, or an error is generated.

=
inter_symbol *TextualInter::new_symbol(inter_error_location *eloc, inter_symbols_table *T,
	text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *S = InterSymbolsTable::symbol_from_name(T, name);
	if (S) {
		if (InterSymbol::misc_but_undefined(S)) return S;
		*E = InterErrors::quoted(I"symbol already exists", name, eloc);
		return NULL;
	}
	return InterSymbolsTable::symbol_from_name_creating(T, name);
}

@ Second, this attempts to match a name against a symbol in the scope local to
the bookmark |IBM|. If it exists, we return it, though if |construct| is non-zero
then we first check if it is defined by an instruction of that type. (This
enables us to tell if it's, e.g., a variable, defined by |VARIABLE_IST| instruction.)

=
inter_symbol *TextualInter::find_symbol(inter_bookmark *IBM, inter_error_location *eloc,
	text_stream *name, inter_ti construct, inter_error_message **E) {
	return TextualInter::find_symbol_in_table(InterBookmark::scope(IBM), eloc, name, construct, E);
}
inter_symbol *TextualInter::find_symbol_in_table(inter_symbols_table *T, inter_error_location *eloc,
	text_stream *name, inter_ti construct, inter_error_message **E) {
	*E = NULL;
	inter_symbol *S = NULL;
	if (Str::get_first_char(name) == '/')
		@<Search using URL conventions@>
	else
		S = InterSymbolsTable::symbol_from_name(T, name);
	if (S == NULL) {
		*E = InterErrors::quoted(I"no such symbol", name, eloc); return NULL;
	}
	if (construct != 0) @<Check that it is defined by the correct construct@>;
	return S;
}

@ Using a URL allows an instruction to refer to a symbol in another package.
If this has already been created, all well and good, but it may be a forward
reference, or even a reference to something in another tree which is to be
linked in later on. So if we see a URL which does not (yet) exist, we wire
a plug to it. For example, given |/some/enchanted/evening|, we make a local
symbol |evening ~~> "/some/enchanted/evening"|. This is then fixed up when we
resolve forward references at the end of the parsing process -- see below.

@<Search using URL conventions@> =
	S = InterSymbolsTable::URL_to_symbol(InterPackage::tree(InterSymbolsTable::package(T)), name);
	if (S == NULL) {
		TEMPORARY_TEXT(leaf)
		LOOP_THROUGH_TEXT(pos, name) {
			wchar_t c = Str::get(pos);
			if (c == '/') Str::clear(leaf);
			else PUT_TO(leaf, c);
		}
		if (Str::len(leaf) == 0) {
			*E = InterErrors::quoted(I"URL ends in '/'", name, eloc);
			return NULL;
		}
		S = InterSymbolsTable::symbol_from_name(T, leaf);
		if (!((S) && (Wiring::is_wired_to_name(S)) &&
				(Str::eq(Wiring::wired_to_name(S), name)))) {			
			S = InterSymbolsTable::create_with_unique_name(T, leaf);
			Wiring::wire_to_name(S, name);
		}
		DISCARD_TEXT(leaf)
	}

@ This check is not foolproof. In particular, it is fooled by forward references.
But it really doesn't need to catch every possible error; this is Inter, not Inform.

@<Check that it is defined by the correct construct@> =
	inter_tree_node *D = InterSymbol::definition(S);
	if (InterSymbol::defined_elsewhere(S)) return S;
	if (InterSymbol::misc_but_undefined(S)) return S;
	if (D == NULL) {
		*E = InterErrors::quoted(I"undefined symbol", name, eloc); return NULL;
	}
	if ((D->W.instruction[ID_IFLD] != construct) &&
		(InterSymbol::misc_but_undefined(S) == FALSE)) {
		*E = InterErrors::quoted(I"symbol of wrong type", name, eloc); return NULL;
	}

@ This simpler version checks the global symbols for the tree, rather than the local
package, and does not allow URL references. (Of course they could only consist of
the same name with a single slash in front anyway, so this is no loss.) Here they
cannot be forward references to symbols not yet created.

=
inter_symbol *TextualInter::find_global_symbol(inter_bookmark *IBM, inter_error_location *eloc,
	text_stream *name, inter_ti construct, inter_error_message **E) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_symbols_table *T = InterTree::global_scope(I);
	*E = NULL;
	inter_symbol *S = InterSymbolsTable::symbol_from_name(T, name);
	if (S == NULL) {
		*E = InterErrors::quoted(I"no such symbol", name, eloc); return NULL;
	}
	if (construct != 0) @<Check that it is defined by the correct construct@>;
	return S;
}

@h Forward references.
Because of the way we temporarily wire symbols to URLs when their references
cannot be resolved, the above process leaves us with a tree in which those
symbols are still left dangling. This is where we fix things:

=
void TextualInter::resolve_forward_references(inter_tree *I) {
	inter_error_location eloc = InterErrors::file_location(NULL, NULL);
	InterTree::traverse(I, TextualInter::rfr_visitor, &eloc, NULL, PACKAGE_IST);
}

void TextualInter::rfr_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_error_location *eloc = (inter_error_location *) state;
	inter_package *pack = InterPackage::at_this_head(P);
	if (pack == NULL) internal_error("no package defined here");
	inter_symbols_table *T = InterPackage::scope(pack);
	if (T == NULL) internal_error("package with no symbols");
	for (int i=0; i<T->symbol_array_size; i++) {
		inter_symbol *S = T->symbol_array[i];
		if (Wiring::is_wired_to_name(S)) {
			if (InterSymbol::is_plug(S)) continue;
			@<This is a forward reference wiring@>;
		}
	}
}

@ The unexpected case here is where our unresolved symbol |S| is itself a socket,
having been declared by a line of Inter like
= (text as Inter)
	socket hypothetical ~~> /ultima/thule
=
at a position in the text file where |/ultima/thule| has not yet been defined.
This then becomes that most heretical thing, a socket wired to a name:
= (text as Inter)
	socket hypothetical ~~> "/ultima/thule"
=
...until we correct that heresy here by calling //Wiring::make_socket_to//.
(It was already a socket: but now it's a socket to |S_to|.)

@<This is a forward reference wiring@> =
	text_stream *N = Wiring::wired_to_name(S);
	inter_symbol *S_to;
	if (Str::get_first_char(N) == '/')
		S_to = InterSymbolsTable::URL_to_symbol(InterPackage::tree(pack), N);
	else
		S_to = InterSymbolsTable::symbol_from_name(T, N);
	if (S_to == NULL)
		InterErrors::issue(InterErrors::quoted(I"unable to locate symbol", N, eloc));
	else if (InterSymbol::is_socket(S))
		Wiring::make_socket_to(S, S_to);
	else
		Wiring::wire_to(S, S_to);

@h Writing textual inter.
This more or less reverses the above process. Note that we do not write the
|version| pseudo-construct, which would indicate the version number of Inter
used; that's a bit of a choice, but in the end it makes testing slightly easier
if we don't, because otherwise many test cases would need changing whenever
//The Inter Version// does.

This is a point of difference with binary Inter files, though, which are all
required to embed their specification version numbers.

=
void TextualInter::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_tree *I = (inter_tree *) vI;
	TextualInter::write(OUT, I, NULL);
}

typedef struct textual_write_state {
	struct text_stream *to;
	int (*filter)(inter_tree_node *);
} textual_write_state;

@ If the function |filter| is provided then we only write those nodes passing
the filter test.

=
void TextualInter::write(OUTPUT_STREAM, inter_tree *I, int (*filter)(inter_tree_node *)) {
	if (I == NULL) { WRITE("<no-inter>\n"); return; }
	textual_write_state tws;
	tws.to = OUT;
	tws.filter = filter;
	InterTree::traverse_root_only(I, TextualInter::visitor, &tws, -PACKAGE_IST);
	InterTree::traverse(I, TextualInter::visitor, &tws, NULL, 0);
}
void TextualInter::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	textual_write_state *tws = (textual_write_state *) state;
	if ((tws->filter) && ((*(tws->filter))(P) == FALSE)) return;
	inter_error_message *E = InterConstruct::write_construct_text(tws->to, P);
	if (E) InterErrors::issue(E);
}

@h Utility functions for writing construct lines.

=
void TextualInter::write_symbol(OUTPUT_STREAM, inter_symbol *S) {
	if (Wiring::is_wired(S)) {
		InterSymbolsTable::write_symbol_URL(OUT, Wiring::cable_end(S));
	} else if (S) {
		WRITE("%S", InterSymbol::identifier(S));
	} else {
		WRITE("<invalid-symbol>");
	}
}

void TextualInter::write_symbol_from(OUTPUT_STREAM, inter_tree_node *P, int field) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_not_following(
		InterPackage::scope_of(P), P->W.instruction[field]);
	TextualInter::write_symbol(OUT, S);
}

@h Notation for text literals.

=
void TextualInter::write_text(OUTPUT_STREAM, text_stream *S) {
	LOOP_THROUGH_TEXT(P, S) {
		wchar_t c = Str::get(P);
		if (c == 9) { WRITE("\\t"); continue; }
		if (c == 10) { WRITE("\\n"); continue; }
		if (c == '"') { WRITE("\\\""); continue; }
		if (c == '\\') { WRITE("\\\\"); continue; }
		PUT(c);
	}
}

inter_error_message *TextualInter::parse_literal_text(text_stream *parsed_text,
	text_stream *S, int from, int to, inter_error_location *eloc) {
	inter_error_message *E = NULL;
	int literal_mode = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		if ((pos.index < from) || (pos.index > to)) continue;
		int c = (int) Str::get(pos);
		if (literal_mode == FALSE) {
			if (c == '\\') { literal_mode = TRUE; continue; }
		} else {
			switch (c) {
				case '\\': break;
				case '"': break;
				case 't': c = 9; break;
				case 'n': c = 10; break;
				default: E = InterErrors::plain(I"no such backslash escape", eloc); break;
			}
		}
		if (Inter::Constant::char_acceptable(c) == FALSE)
			E = InterErrors::quoted(I"bad character in text", S, eloc);
		PUT_TO(parsed_text, c);
		literal_mode = FALSE;
	}
	if (E) Str::clear(parsed_text);
	return E;
}

@h Notation for value pairs.
See //Inter Value Pairs//. The printing and parsing functions are shown here
in an interleaved form, to keep each notation together. Both have a simple
outer structure:

=
void TextualInter::write_pair(OUTPUT_STREAM, inter_tree_node *P, inter_pair pair, int hex) {
	inter_tree *I = Inode::tree(P);

	     if (InterValuePairs::is_number(pair))         @<Print numeric literal syntax@>
	else if (InterValuePairs::is_text(pair))           @<Print text literal syntax@>
	else if (InterValuePairs::is_real(pair))           @<Print real literal syntax@>
	else if (InterValuePairs::is_singular_dword(pair)) @<Print singular dword syntax@>
	else if (InterValuePairs::is_plural_dword(pair))   @<Print plural dword syntax@>
	else if (InterValuePairs::is_glob(pair))           @<Print glob syntax@>
	else if (InterValuePairs::is_undef(pair))          @<Print undef syntax@>
	else if (InterValuePairs::is_symbolic(pair))       @<Print symbol name syntax@>
	else WRITE("<invalid-value-type>");
}

inter_error_message *TextualInter::parse_pair(text_stream *line, inter_error_location *eloc,
	inter_bookmark *IBM, inter_type type_wanted, text_stream *S, inter_pair *pair) {
	inter_symbols_table *scope = InterBookmark::scope(IBM);
	inter_tree *I = InterBookmark::tree(IBM);

	wchar_t first_char = Str::get_first_char(S);
	wchar_t last_char = Str::get_last_char(S);
	int is_identifier = FALSE;
	if (Characters::isalpha(first_char)) {
		is_identifier = TRUE;
		LOOP_THROUGH_TEXT(pos, S)
			if ((Characters::isalpha(Str::get(pos)) == FALSE) &&
				(Characters::isdigit(Str::get(pos)) == FALSE) &&
				(Str::get(pos) != '_'))
				is_identifier = FALSE;
	}
	int quoted_from = -1, quoted_to = -1;
	if (last_char == '"') {
		for (int i=0; i<Str::len(S); i++)
			if (Str::get_at(S, i) == '"') {
				quoted_from = i+1;
				quoted_to = Str::len(S)-2;
				if (quoted_from > quoted_to)
					return InterErrors::quoted(I"mismatched quotes", S, eloc);
				break;
			}
	}

	@<Parse numeric literal syntax@>;
	@<Parse text literal syntax@>;
	@<Parse real literal syntax@>;
	@<Parse singular dword syntax@>;
	@<Parse plural dword syntax@>;
	@<Parse glob syntax@>;
	@<Parse symbol name syntax@>;
	@<Parse undef syntax@>;

	return InterErrors::quoted(I"unrecognised value", S, eloc);
}

@ Literal numbers can be parsed in (signed) decimal, (unsigned) hexadecimal
or (unsigned) binary, but cannot be printed back in binary.

@<Print numeric literal syntax@> =
	if (hex) WRITE("0x%x", InterValuePairs::to_number(pair));
	else WRITE("%d", InterValuePairs::to_number(pair));

@<Parse numeric literal syntax@> =
	wchar_t c = first_char;
	if ((c == '-') || (Characters::isdigit(c))) {
		int sign = 1, base = 10, from = 0;
		if (Str::prefix_eq(S, I"-", 1)) { sign = -1; from = 1; }
		if (Str::prefix_eq(S, I"0b", 2)) { base = 2; from = 2; }
		if (Str::prefix_eq(S, I"0x", 2)) { base = 16; from = 2; }
		long long int N = 0;
		LOOP_THROUGH_TEXT(pos, S) {
			if (pos.index < from) continue;
			int c = Str::get(pos), d = 0;
			if ((c >= 'a') && (c <= 'z')) d = c-'a'+10;
			else if ((c >= 'A') && (c <= 'Z')) d = c-'A'+10;
			else if ((c >= '0') && (c <= '9')) d = c-'0';
			else return InterErrors::quoted(I"bad digit", S, eloc);
			if (d > base)
				return InterErrors::quoted(I"bad digit for this number base", S, eloc);
			N = base*N + (long long int) d;
			if (pos.index > 34) return InterErrors::quoted(I"value out of range", S, eloc);
		}
		N = sign*N;
		if (InterTypes::literal_is_in_range(N, type_wanted) == FALSE)
			return InterErrors::quoted(I"value out of range", S, eloc);
		*pair = InterValuePairs::number((inter_ti) N);
		return NULL;
	}

@ Literal text is written in double quotes: see the functions above for the
rules on escape characters inside.

@<Print text literal syntax@> =
	WRITE("\"");
	TextualInter::write_text(OUT, InterValuePairs::to_text(I, pair));
	WRITE("\"");

@<Parse text literal syntax@> =
	if (quoted_from == 1) {
		TEMPORARY_TEXT(text)
		inter_error_message *E =
			TextualInter::parse_literal_text(text, S, quoted_from, quoted_to, eloc);
		*pair = InterValuePairs::from_text(IBM, text);
		DISCARD_TEXT(text)
		return E;
	}

@ Real numbers are written thus: |r"3.14159"|.

@<Print real literal syntax@> =
	WRITE("r\"");
	TextualInter::write_text(OUT, InterValuePairs::to_textual_real(I, pair));
	WRITE("\"");

@<Parse real literal syntax@> =
	if ((quoted_from == 2) && (Str::begins_with_wide_string(S, L"r"))) {
		TEMPORARY_TEXT(text)
		inter_error_message *E =
			TextualInter::parse_literal_text(text, S, quoted_from, quoted_to, eloc);
		*pair = InterValuePairs::real_from_I6_notation(IBM, text);
		DISCARD_TEXT(text)
		return E;
	}

@ Dictionary words are like literal text, but prefaced by |dw| or |dwp|. For
example, |dw"xyzzy"| or |dwp"fruits"|.

@<Print singular dword syntax@> =
	WRITE("dw\"");
	TextualInter::write_text(OUT, InterValuePairs::to_dictionary_word(I, pair));
	WRITE("\"");

@<Parse singular dword syntax@> =
	if ((quoted_from == 3) && (Str::begins_with_wide_string(S, L"dw"))) {
		TEMPORARY_TEXT(text)
		inter_error_message *E =
			TextualInter::parse_literal_text(text, S, quoted_from, quoted_to, eloc);
		*pair = InterValuePairs::from_singular_dword(IBM, text);
		DISCARD_TEXT(text)
		return E;
	}

@<Print plural dword syntax@> =
	WRITE("dwp\"");
	TextualInter::write_text(OUT, InterValuePairs::to_dictionary_word(I, pair));
	WRITE("\"");

@<Parse plural dword syntax@> =
	if ((quoted_from == 4) && (Str::begins_with_wide_string(S, L"dwp"))) {
		TEMPORARY_TEXT(text)
		inter_error_message *E =
			TextualInter::parse_literal_text(text, S, quoted_from, quoted_to, eloc);
		*pair = InterValuePairs::from_plural_dword(IBM, text);
		DISCARD_TEXT(text)
		return E;
	}

@ Globs should never be talked about at all, but if they were, they would be
written |glob"..."|, with the same escaping rules as literal text.

@<Print glob syntax@> =
	WRITE("glob\"");
	TextualInter::write_text(OUT, InterValuePairs::to_glob_text(I, pair));
	WRITE("\"");

@<Parse glob syntax@> =
	if ((quoted_from == 5) && (Str::begins_with_wide_string(S, L"glob"))) {
		TEMPORARY_TEXT(text)
		inter_error_message *E =
			TextualInter::parse_literal_text(text, S, quoted_from, quoted_to, eloc);
		*pair = InterValuePairs::glob(IBM, text);
		DISCARD_TEXT(text)
		return E;
	}

@ Symbol names can either be bare identifiers, in the current package, or can be
given as URLs. Note that they are created tentatively if they do not already exist,
in order for forward references to be read in by a one-pass assembler such as the
one above.

@<Print symbol name syntax@> =
	TextualInter::write_symbol(OUT,
		InterValuePairs::to_symbol_not_following(pair, InterPackage::scope_of(P)));

@<Parse symbol name syntax@> =
	if (first_char == '/') {
		inter_symbol *symb = InterSymbolsTable::URL_to_symbol(I, S);
		if (symb == NULL) {
			TEMPORARY_TEXT(leaf)
			LOOP_THROUGH_TEXT(pos, S) {
				wchar_t c = Str::get(pos);
				if (c == '/') Str::clear(leaf);
				else PUT_TO(leaf, c);
			}
			if (Str::len(leaf) == 0) return InterErrors::quoted(I"URL ends in '/'", S, eloc);
			symb = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), leaf);
			if (!((symb) && (Wiring::is_wired_to_name(symb)) &&
				(Str::eq(Wiring::wired_to_name(symb), S)))) {			
				symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), leaf);
				Wiring::wire_to_name(symb, S);
			}
			DISCARD_TEXT(leaf)
		}
		@<Use this symb as the result@>;
	}
	if (is_identifier) {
		inter_symbol *symb = InterSymbolsTable::symbol_from_name(scope, S);
		if (symb) @<Use this symb as the result@>;
		symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), S);
		*pair = InterValuePairs::symbolic(IBM, symb);
		InterSymbol::set_flag(symb, SPECULATIVE_ISYMF);
		return NULL;
	}

@<Use this symb as the result@> =
	if ((InterTypes::is_enumerated(type_wanted)) && (InterSymbol::is_defined(symb) == FALSE))
		return InterErrors::quoted(I"undefined symbol", S, eloc);
	inter_type symbol_type = InterTypes::of_symbol(symb);
	inter_error_message *E = InterTypes::can_be_used_as(symbol_type, type_wanted, S, eloc);
	if (E) return E;
	*pair = InterValuePairs::symbolic(IBM, symb);
	return NULL;

@ Note that the undef syntax is not a valid identifier, since it begins |!|.
This choice of character is meant to give it a dangerous aspect.

@<Print undef syntax@> =
	WRITE("!undef");

@<Parse undef syntax@> =
	if (Str::eq(S, I"!undef")) {
		*pair = InterValuePairs::undef();
		return NULL;
	}

@h Bracketed type markers.
The following prints out the bracketed type markers used in textual Inter,
but printing nothing in the case where the type is unchecked and the value is
therefore used typelessly.

=
void TextualInter::write_optional_type_marker(OUTPUT_STREAM, inter_tree_node *P, int field) {
	inter_type type = InterTypes::from_TID_in_field(P, field);
	if (type.type_name) {
		WRITE("("); TextualInter::write_symbol_from(OUT, P, field); WRITE(") ");
	} else if (InterTypes::is_unchecked(type) == FALSE) {
		WRITE("("); InterTypes::write_type(OUT, type); WRITE(") ");
	}
}
