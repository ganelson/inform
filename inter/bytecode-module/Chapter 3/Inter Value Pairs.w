[InterValuePairs::] Inter Value Pairs.

Two consecutive bytecode words are used to store a single value in binary Inter.

@ About time to define the types we're using to represent Inter words in C.
It turns out to be more convenient to define these by what amounts to |#define|
than to use |typedef|.

@d inter_ti unsigned int
@d signed_inter_ti int

@ A constant value in Inter code is represented by a pair of |inter_ti| values.
Note that changing any of these values would invalidate existing Inter binary
files: that would necessitate a bump of //The Inter Version//.

@e LITERAL_IVAL from 0x10000
@e LITERAL_TEXT_IVAL
@e REAL_IVAL
@e ALIAS_IVAL
@e UNDEF_IVAL
@e DWORD_IVAL
@e PDWORD_IVAL
@e GLOB_IVAL

=
typedef struct inter_pair {
	inter_ti data_format;
	inter_ti data_content;
} inter_pair;

@ Instructions which contain such values in their bytecode always store pairs in
two consecutive fields, so:

=
inter_pair InterValuePairs::get(inter_tree_node *P, int field) {
	inter_pair pair;
	pair.data_format = P->W.instruction[field];
	pair.data_content = P->W.instruction[field+1];
	return pair;
}

void InterValuePairs::set(inter_tree_node *P, int field, inter_pair pair) {
	P->W.instruction[field] = pair.data_format;
	P->W.instruction[field+1] = pair.data_content;
}

inter_ti InterValuePairs::to_word1(inter_pair pair) {
	return pair.data_format;
}
inter_ti InterValuePairs::to_word2(inter_pair pair) {
	return pair.data_content;
}

inter_pair InterValuePairs::undef(void) {
	inter_pair pair;
	pair.data_format = UNDEF_IVAL;
	pair.data_content = 0;
	return pair;
}

int InterValuePairs::is_undef(inter_pair pair) {
	if (pair.data_format == UNDEF_IVAL) return TRUE;
	return FALSE;
}

inter_pair InterValuePairs::number(inter_ti N) {
	inter_pair pair;
	pair.data_format = LITERAL_IVAL;
	pair.data_content = N;
	return pair;
}

int InterValuePairs::is_number(inter_pair pair) {
	if (pair.data_format == LITERAL_IVAL) return TRUE;
	return FALSE;
}

int InterValuePairs::is_zero(inter_pair pair) {
	if ((pair.data_format == LITERAL_IVAL) &&
		(pair.data_content == 0)) return TRUE;
	return FALSE;
}

int InterValuePairs::is_one(inter_pair pair) {
	if ((pair.data_format == LITERAL_IVAL) &&
		(pair.data_content == 1)) return TRUE;
	return FALSE;
}

inter_ti InterValuePairs::to_number(inter_pair pair) {
	if (pair.data_format == LITERAL_IVAL) return pair.data_content;
	return 0;
}

@ Real numbers, which Inter stores in a textual way:

=
inter_pair InterValuePairs::real(inter_tree *I, double g) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I),
		InterBookmark::package(Packaging::at(I)));
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	if (g > 0) WRITE_TO(text_storage, "+");
	WRITE_TO(text_storage, "%g", g);
	inter_pair pair;
	pair.data_format = REAL_IVAL;
	pair.data_content = ID;
	return pair;
}

int InterValuePairs::is_real(inter_pair pair) {
	if (pair.data_format == REAL_IVAL) return TRUE;
	return FALSE;
}

inter_pair InterValuePairs::from_real_text(inter_tree *I, text_stream *S) {
	return InterValuePairs::from_real_text_at(I, InterBookmark::package(Packaging::at(I)), S);
}
inter_pair InterValuePairs::from_real_text_at(inter_tree *I, inter_package *pack,
	text_stream *S) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(text_storage, Str::get(pos));
	inter_pair pair;
	pair.data_format = REAL_IVAL;
	pair.data_content = ID;
	return pair;
}

text_stream *InterValuePairs::real_to_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_real(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Dictionary words, singular and plural:

=
inter_pair InterValuePairs::from_singular_dword(inter_tree *I, text_stream *word) {
	return InterValuePairs::from_singular_dword_at(I, InterBookmark::package(Packaging::at(I)), word);
}
inter_pair InterValuePairs::from_singular_dword_at(inter_tree *I, inter_package *pack,
	text_stream *word) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	inter_pair pair;
	pair.data_format = DWORD_IVAL;
	pair.data_content = ID;
	return pair;
}

int InterValuePairs::is_dword(inter_pair pair) {
	if ((pair.data_format == DWORD_IVAL) || (pair.data_format == PDWORD_IVAL)) return TRUE;
	return FALSE;
}

int InterValuePairs::is_singular_dword(inter_pair pair) {
	if (pair.data_format == DWORD_IVAL) return TRUE;
	return FALSE;
}

int InterValuePairs::is_plural_dword(inter_pair pair) {
	if (pair.data_format == PDWORD_IVAL) return TRUE;
	return FALSE;
}

text_stream *InterValuePairs::dword_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_dword(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

inter_pair InterValuePairs::from_plural_dword(inter_tree *I, text_stream *word) {
	return InterValuePairs::from_plural_dword_at(I, InterBookmark::package(Packaging::at(I)), word);
}
inter_pair InterValuePairs::from_plural_dword_at(inter_tree *I, inter_package *pack,
	text_stream *word) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	inter_pair pair;
	pair.data_format = PDWORD_IVAL;
	pair.data_content = ID;
	return pair;
}

@ Text:

=
inter_pair InterValuePairs::from_text(inter_tree *I, text_stream *text) {
	return InterValuePairs::from_text_at(I, InterBookmark::package(Packaging::at(I)), text);
}
inter_pair InterValuePairs::from_text_at(inter_tree *I, inter_package *pack, text_stream *text) {
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, text);
	inter_pair pair;
	pair.data_format = LITERAL_TEXT_IVAL;
	pair.data_content = ID;
	return pair;
}

int InterValuePairs::is_text(inter_pair pair) {
	if (pair.data_format == LITERAL_TEXT_IVAL) return TRUE;
	return FALSE;
}

text_stream *InterValuePairs::to_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_text(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

int InterValuePairs::is_glob(inter_pair pair) {
	if (pair.data_format == GLOB_IVAL) return TRUE;
	return FALSE;
}

text_stream *InterValuePairs::to_glob_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_glob(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Printing out a pair in textual Inter syntax:

=
void InterValuePairs::write(OUTPUT_STREAM, inter_tree_node *F,
	inter_pair pair, inter_symbols_table *scope, int hex_flag) {
	switch (pair.data_format) {
		case LITERAL_IVAL:
			if (hex_flag) WRITE("0x%x", pair.data_content);
			else WRITE("%d", pair.data_content); break;
		case REAL_IVAL:
			WRITE("r\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("\"");
			break;
		case LITERAL_TEXT_IVAL:
			WRITE("\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("\"");
			break;
		case ALIAS_IVAL: {
			inter_symbol *symb = InterSymbolsTable::symbol_from_ID_not_following(scope, pair.data_content);
			TextualInter::write_symbol(OUT, symb);
			break;
		}
		case UNDEF_IVAL: WRITE("undef"); break;
		case GLOB_IVAL:
			WRITE("&\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("\"");
			break;
		case DWORD_IVAL:
			WRITE("dw'");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("'");
			break;
		case PDWORD_IVAL:
			WRITE("dwp'");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("'");
			break;
		default: WRITE("<invalid-value-type>"); break;
	}
}

@ =
inter_pair InterValuePairs::read_int_in_I6_notation(text_stream *S) {
	int sign = 1, base = 10, from = 0;
	if (Str::prefix_eq(S, I"-", 1)) { sign = -1; from = 1; }
	if (Str::prefix_eq(S, I"$", 1)) { base = 16; from = 1; }
	if (Str::prefix_eq(S, I"$$", 2)) { base = 2; from = 2; }
	long long int N = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		if (pos.index < from) continue;
		int c = Str::get(pos), d = 0;
		if ((c >= 'a') && (c <= 'z')) d = c-'a'+10;
		else if ((c >= 'A') && (c <= 'Z')) d = c-'A'+10;
		else if ((c >= '0') && (c <= '9')) d = c-'0';
		else return InterValuePairs::undef();
		if (d > base) return InterValuePairs::undef();
		N = base*N + (long long int) d;
		if (pos.index > 34) return InterValuePairs::undef();
	}
	return InterValuePairs::number((inter_ti) (sign*N));
}

@

=
int InterValuePairs::holds_symbol(inter_pair pair) {
	if (pair.data_format == ALIAS_IVAL) return TRUE;
	return FALSE;
}

inter_symbol *InterValuePairs::symbol_from_data_pair(inter_pair pair,
	inter_symbols_table *T) {
	if (pair.data_format == ALIAS_IVAL) return InterSymbolsTable::symbol_from_ID(T, pair.data_content);
	return NULL;
}

inter_symbol *InterValuePairs::symbol_from_data_pair_at_node(inter_pair pair,
	inter_tree_node *P) {
	return InterValuePairs::symbol_from_data_pair(pair, InterPackage::scope_of(P));
}

inter_pair InterValuePairs::from_symbol(inter_tree *I, inter_package *pack, inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	inter_pair pair;
	pair.data_format = ALIAS_IVAL;
	pair.data_content = InterSymbolsTable::id_from_symbol(I, pack, S);
	return pair;
}

inter_error_message *InterValuePairs::parse(text_stream *line, inter_error_location *eloc,
	inter_bookmark *IBM, inter_type type_wanted, text_stream *S, inter_pair *pair,
	inter_symbols_table *scope) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);

	if (Str::eq(S, I"undef")) {
		pair->data_format = UNDEF_IVAL; pair->data_content = 0; return NULL;
	}
	if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		pair->data_format = LITERAL_TEXT_IVAL; pair->data_content = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), pair->data_content);
		return Inter::Constant::parse_text(glob_storage, S, 1, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"r\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		pair->data_format = REAL_IVAL; pair->data_content = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), pair->data_content);
		return Inter::Constant::parse_text(glob_storage, S, 2, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"&\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		pair->data_format = GLOB_IVAL; pair->data_content = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), pair->data_content);
		return Inter::Constant::parse_text(glob_storage, S, 2, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"dw'")) && (Str::ends_with_wide_string(S, L"'"))) {
		pair->data_format = DWORD_IVAL; pair->data_content = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), pair->data_content);
		return Inter::Constant::parse_text(glob_storage, S, 3, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"dwp'")) && (Str::ends_with_wide_string(S, L"'"))) {
		pair->data_format = PDWORD_IVAL; pair->data_content = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), pair->data_content);
		return Inter::Constant::parse_text(glob_storage, S, 4, Str::len(S)-2, eloc);
	}
	if (Str::get_first_char(S) == '/') {
		inter_symbol *symb = InterSymbolsTable::URL_to_symbol(I, S);
		if (symb == NULL) {
			TEMPORARY_TEXT(leaf)
			LOOP_THROUGH_TEXT(pos, S) {
				wchar_t c = Str::get(pos);
				if (c == '/') Str::clear(leaf);
				else PUT_TO(leaf, c);
			}
			if (Str::len(leaf) == 0) return Inter::Errors::quoted(I"URL ends in '/'", S, eloc);
			symb = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), leaf);
			if (!((symb) && (Wiring::is_wired_to_name(symb)) && (Str::eq(Wiring::wired_to_name(symb), S)))) {			
				symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), leaf);
				Wiring::wire_to_name(symb, S);
			}
			DISCARD_TEXT(leaf)
		}
		@<Read symb@>;
	}
	int ident = FALSE;
	if (Characters::isalpha(Str::get_first_char(S))) {
		ident = TRUE;
		LOOP_THROUGH_TEXT(pos, S)
			if ((Characters::isalpha(Str::get(pos)) == FALSE) &&
				(Characters::isdigit(Str::get(pos)) == FALSE) &&
				(Str::get(pos) != '_'))
				ident = FALSE;
	}
	if (ident) {
		inter_symbol *symb = InterSymbolsTable::symbol_from_name(scope, S);
		if (symb) @<Read symb@>;
		symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), S);
		*pair = InterValuePairs::from_symbol(I, pack, symb);
		InterSymbol::set_flag(symb, SPECULATIVE_ISYMF);
		return NULL;
	}

	wchar_t c = Str::get_first_char(S);
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
			else return Inter::Errors::quoted(I"bad digit", S, eloc);
			if (d > base) return Inter::Errors::quoted(I"bad digit for this number base", S, eloc);
			N = base*N + (long long int) d;
			if (pos.index > 34) return Inter::Errors::quoted(I"value out of range", S, eloc);
		}
		N = sign*N;
		if (InterTypes::literal_is_in_range(N, type_wanted) == FALSE)
			return Inter::Errors::quoted(I"value out of range", S, eloc);

		pair->data_format = LITERAL_IVAL; pair->data_content = (inter_ti) N;
		return NULL;
	}

	return Inter::Errors::quoted(I"unrecognised value", S, eloc);
}

@<Read symb@> =
	if ((InterTypes::is_enumerated(type_wanted)) && (InterSymbol::is_defined(symb) == FALSE))
		return Inter::Errors::quoted(I"undefined symbol", S, eloc);
	inter_type symbol_type = InterTypes::of_symbol(symb);
	inter_error_message *E = InterTypes::can_be_used_as(symbol_type, type_wanted, S, eloc);
	if (E) return E;
	*pair = InterValuePairs::from_symbol(I, pack, symb);
	return NULL;

@ =
inter_pair InterValuePairs::transpose(inter_pair pair, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	switch (pair.data_format) {
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case LITERAL_TEXT_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
			pair.data_content = grid[pair.data_content];
			break;
	}
	return pair;
}

inter_error_message *InterValuePairs::verify(inter_package *owner, inter_tree_node *P,
	inter_pair pair, inter_type type) {
	inter_symbols_table *scope = InterPackage::scope(owner);
	if (scope == NULL) scope = Inode::globals(P);
	switch (pair.data_format) {
		case LITERAL_IVAL: {
			long long int I = (signed_inter_ti) pair.data_content;
			if (InterTypes::literal_is_in_range(I, type) == FALSE)
				return Inode::error(P, I"value out of range", NULL);
			return NULL;
		}
		case ALIAS_IVAL: {
			inter_symbol *symb = InterSymbolsTable::symbol_from_ID(scope, pair.data_content);
			if (symb == NULL) return Inode::error(P, I"no such symbol", NULL);
			if (InterSymbol::misc_but_undefined(symb)) return NULL;
			if (InterSymbol::defined_elsewhere(symb)) return NULL;
			if (InterTypes::expresses_value(symb) == FALSE)
				return Inode::error(P, I"nonconstant symbol", InterSymbol::identifier(symb));
			inter_type symbol_type = InterTypes::of_symbol(symb);
			return InterTypes::can_be_used_as(symbol_type, type, InterSymbol::identifier(symb), Inode::get_error_location(P));
		}
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case LITERAL_TEXT_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
		case UNDEF_IVAL:
			return NULL;
	}
	return Inode::error(P, I"value of unknown category", NULL);
}
