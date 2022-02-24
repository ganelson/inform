[InterValuePairs::] Inter Value Pairs.

Two consecutive bytecode words are used to store a single value in binary Inter.

@ About time to define the types we're using to represent Inter words in C.
It turns out to be more convenient to define these by what amounts to |#define|
than to use |typedef|.

@d inter_ti unsigned int
@d signed_inter_ti int

@ A constant value in Inter code is represented by a pair of |inter_ti| values.

@e LITERAL_IVAL from 0x10000
@e LITERAL_TEXT_IVAL
@e REAL_IVAL
@e ALIAS_IVAL
@e UNDEF_IVAL
@e DWORD_IVAL
@e PDWORD_IVAL
@e GLOB_IVAL
@e DIVIDER_IVAL

=
typedef struct inter_pair {
	inter_ti data_format;
	inter_ti data_content;
} inter_pair;

@ Instructions which contain such values in their bytecode always store pairs in
two consecutive fields, so:

=
inter_pair InterValuePairs::in_field(inter_tree_node *P, int field) {
	inter_pair pair;
	pair.data_format = P->W.instruction[field];
	pair.data_content = P->W.instruction[field+1];
	return pair;
}

void InterValuePairs::to_field(inter_tree_node *P, int field, inter_pair pair) {
	P->W.instruction[field] = pair.data_format;
	P->W.instruction[field+1] = pair.data_content;
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
		case DIVIDER_IVAL:
			WRITE("^\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, pair.data_content));
			WRITE("\"");
			break;
		default: WRITE("<invalid-value-type>"); break;
	}
}

@ =
int InterValuePairs::read_int_in_I6_notation(text_stream *S, inter_ti *val1, inter_ti *val2) {
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
		else return FALSE;
		if (d > base) return FALSE;
		N = base*N + (long long int) d;
		if (pos.index > 34) return FALSE;
	}
	N = sign*N;

	*val1 = LITERAL_IVAL; *val2 = (inter_ti) N;
	return TRUE;
}

@

=
int InterValuePairs::holds_symbol(inter_ti val1, inter_ti val2) {
	if (val1 == ALIAS_IVAL) return TRUE;
	return FALSE;
}

void InterValuePairs::from_symbol(inter_tree *I, inter_package *pack, inter_symbol *S,
	inter_ti *val1, inter_ti *val2) {
	if (S == NULL) internal_error("no symbol");
	*val1 = ALIAS_IVAL; *val2 = InterSymbolsTable::id_from_symbol(I, pack, S);
}

inter_error_message *InterValuePairs::parse(text_stream *line, inter_error_location *eloc,
	inter_bookmark *IBM, inter_type type_wanted, text_stream *S, inter_ti *val1, inter_ti *val2,
	inter_symbols_table *scope) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);

	if (Str::eq(S, I"undef")) {
		*val1 = UNDEF_IVAL; *val2 = 0; return NULL;
	}
	if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		*val1 = LITERAL_TEXT_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(glob_storage, S, 1, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"r\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		*val1 = REAL_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(glob_storage, S, 2, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"&\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		*val1 = GLOB_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(glob_storage, S, 2, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"dw'")) && (Str::ends_with_wide_string(S, L"'"))) {
		*val1 = DWORD_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(glob_storage, S, 3, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"dwp'")) && (Str::ends_with_wide_string(S, L"'"))) {
		*val1 = PDWORD_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *glob_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(glob_storage, S, 4, Str::len(S)-2, eloc);
	}
	if ((Str::begins_with_wide_string(S, L"^\"")) && (Str::ends_with_wide_string(S, L"\""))) {
		*val1 = DIVIDER_IVAL; *val2 = InterWarehouse::create_text(InterTree::warehouse(I), pack);
		text_stream *divider_storage = InterWarehouse::get_text(InterTree::warehouse(I), *val2);
		return Inter::Constant::parse_text(divider_storage, S, 2, Str::len(S)-2, eloc);
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
		InterValuePairs::from_symbol(I, pack, symb, val1, val2);
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

		*val1 = LITERAL_IVAL; *val2 = (inter_ti) N;
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
	InterValuePairs::from_symbol(I, pack, symb, val1, val2);
	return NULL;

@ =
inter_pair InterValuePairs::transpose(inter_pair pair, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	switch (pair.data_format) {
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case LITERAL_TEXT_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
		case DIVIDER_IVAL:
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
		case DIVIDER_IVAL:
			return NULL;
	}
	return Inode::error(P, I"value of unknown category", NULL);
}
