[Inter::Types::] Inter Data Types.

A primitive notion of data type, below the level of kinds.

@ 

@d inter_ti unsigned int
@d signed_inter_ti int

=
typedef struct inter_data_type {
	inter_ti type_ID;
	struct text_stream *reserved_word;
	long long int min_value;
	long long int max_value;
	int enumerated;
	CLASS_DEFINITION
} inter_data_type;

inter_data_type *int32_idt = NULL;
inter_data_type *unchecked_idt = NULL;

@ =
dictionary *idt_lookup = NULL;

inter_data_type *Inter::Types::create(inter_ti ID, text_stream *name, int A, int B, int en) {
	inter_data_type *IDT = CREATE(inter_data_type);
	IDT->type_ID = ID;
	IDT->reserved_word = Str::duplicate(name);
	IDT->min_value = A;
	IDT->max_value = B;
	IDT->enumerated = en;

	if (idt_lookup == NULL) idt_lookup = Dictionaries::new(128, FALSE);
	Dictionaries::create(idt_lookup, name);
	Dictionaries::write_value(idt_lookup, name, (void *) IDT);

	return IDT;
}

int Inter::Types::is_enumerated(inter_data_type *idt) {
	if ((idt) && (idt->enumerated)) return TRUE;
	return FALSE;
}

inter_data_type *Inter::Types::find_by_ID(inter_ti ID) {
	inter_data_type *IDT;
	LOOP_OVER(IDT, inter_data_type)
		if (ID == IDT->type_ID)
			return IDT;
	return NULL;
}

inter_data_type *Inter::Types::find_by_name(text_stream *name) {
	dict_entry *de = Dictionaries::find(idt_lookup, name);
	if (de) return (inter_data_type *) Dictionaries::read_value(idt_lookup, name);
	return NULL;
}

inter_ti Inter::Types::transpose_value(inter_ti V1, inter_ti V2, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	switch (V1) {
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case LITERAL_TEXT_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
		case DIVIDER_IVAL:
			V2 = grid[V2];
			break;
	}
	return V2;
}

inter_error_message *Inter::Types::verify(inter_tree_node *P, inter_symbol *kind_symbol, inter_ti V1, inter_ti V2, inter_symbols_table *scope) {
	switch (V1) {
		case LITERAL_IVAL: {
			inter_data_type *idt = Inter::Kind::data_type(kind_symbol);
			if (idt) {
				long long int I = (signed_inter_ti) V2;
				if ((I < idt->min_value) || (I > idt->max_value)) return Inode::error(P, I"value out of range", NULL);
				return NULL;
			}
			return NULL;
		}
		case ALIAS_IVAL: {
			inter_symbol *symb = InterSymbolsTable::symbol_from_ID(scope, V2);
			if (symb == NULL) {
				LOG("No such symbol when verifying memory inter\n");
				LOG("V2 is %08x\n", V2);
				LOG("IST is $4\n", scope);
				LOG("(did you forget to make the package type enclosing?)\n");
				return Inode::error(P, I"no such symbol", NULL);
			}
			if (InterSymbol::misc_but_undefined(symb)) return NULL;
			if (InterSymbol::defined_elsewhere(symb)) return NULL;
			inter_tree_node *D = InterSymbol::definition(symb);
			if (D == NULL) return Inode::error(P, I"undefined symbol", InterSymbol::identifier(symb));

			inter_data_type *idt = Inter::Kind::data_type(kind_symbol);
			if (idt == unchecked_idt) return NULL;

			inter_symbol *ckind_symbol = NULL;
			if (D->W.instruction[ID_IFLD] == INSTANCE_IST) ckind_symbol = Inter::Instance::kind_of(symb);
			else if (D->W.instruction[ID_IFLD] == CONSTANT_IST) ckind_symbol = Inter::Constant::kind_of(symb);
			else if (D->W.instruction[ID_IFLD] == LOCAL_IST) ckind_symbol = Inter::Local::kind_of(symb);
			else if (D->W.instruction[ID_IFLD] == VARIABLE_IST) ckind_symbol = Inter::Variable::kind_of(symb);
			else if (D->W.instruction[ID_IFLD] == PROPERTY_IST) ckind_symbol = Inter::Property::kind_of(symb);
			else return Inode::error(P, I"nonconstant symbol", InterSymbol::identifier(symb));
			if (Inter::Kind::is_a(ckind_symbol, kind_symbol) == FALSE) {
				LOG("cks %S, ks %S\n", InterSymbol::identifier(ckind_symbol), InterSymbol::identifier(kind_symbol));
				return Inode::error(P, I"value of wrong kind", InterSymbol::identifier(symb));
			}
			return NULL;
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

inter_symbol *Inter::Types::value_to_constant_symbol_kind(inter_symbols_table *T, inter_ti V1, inter_ti V2) {
	inter_symbol *symb = InterSymbolsTable::symbol_from_data_pair(V1, V2, T);
	if (symb) {
		inter_tree_node *D = InterSymbol::definition(symb);
		if (D == NULL) return NULL;
		inter_symbol *ckind_symbol = NULL;
		if (D->W.instruction[ID_IFLD] == INSTANCE_IST) ckind_symbol = Inter::Instance::kind_of(symb);
		else if (D->W.instruction[ID_IFLD] == CONSTANT_IST) ckind_symbol = Inter::Constant::kind_of(symb);
		return ckind_symbol;
	}
	return NULL;
}

@

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

void Inter::Types::write(OUTPUT_STREAM, inter_tree_node *F, inter_symbol *kind_symbol,
	inter_ti V1, inter_ti V2, inter_symbols_table *scope, int hex_flag) {
	switch (V1) {
		case LITERAL_IVAL:
			if (hex_flag) WRITE("0x%x", V2);
			else WRITE("%d", V2); break;
		case REAL_IVAL:
			WRITE("r\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("\"");
			break;
		case LITERAL_TEXT_IVAL:
			WRITE("\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("\"");
			break;
		case ALIAS_IVAL: {
			inter_symbol *symb = InterSymbolsTable::symbol_from_ID_not_following(scope, V2);
			TextualInter::write_symbol(OUT, symb);
			break;
		}
		case UNDEF_IVAL: WRITE("undef"); break;
		case GLOB_IVAL:
			WRITE("&\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("\"");
			break;
		case DWORD_IVAL:
			WRITE("dw'");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("'");
			break;
		case PDWORD_IVAL:
			WRITE("dwp'");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("'");
			break;
		case DIVIDER_IVAL:
			WRITE("^\"");
			Inter::Constant::write_text(OUT, Inode::ID_to_text(F, V2));
			WRITE("\"");
			break;
		default: WRITE("<invalid-value-type>"); break;
	}
}

inter_error_message *Inter::Types::read(text_stream *line, inter_error_location *eloc, inter_bookmark *IBM, inter_symbol *kind_symbol, text_stream *S, inter_ti *val1, inter_ti *val2, inter_symbols_table *scope) {
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
	inter_data_type *idt = int32_idt;
	if (kind_symbol) idt = Inter::Kind::data_type(kind_symbol);
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
		Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
		return NULL;
	}
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(scope, S);
	if (symb) {
		inter_tree_node *D = InterSymbol::definition(symb);
		if (InterSymbol::misc_but_undefined(symb)) {
			Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
			return NULL;
		}
		if (InterSymbol::defined_elsewhere(symb)) {
			Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
			return NULL;
		}
		if (D == NULL) return Inter::Errors::quoted(I"undefined symbol", S, eloc);
		if (D->W.instruction[ID_IFLD] == LOCAL_IST) {
			inter_symbol *kind_loc = Inter::Local::kind_of(symb);
			if (Inter::Kind::is_a(kind_loc, kind_symbol) == FALSE) {
				text_stream *err = Str::new();
				WRITE_TO(err, "local has kind %S which is not a %S",
					InterSymbol::identifier(kind_loc),
					InterSymbol::identifier(kind_symbol));
				return Inter::Errors::quoted(err, S, eloc);
			}
			Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
			return NULL;
		}
		if (D->W.instruction[ID_IFLD] == CONSTANT_IST) {
			inter_symbol *kind_const = Inter::Constant::kind_of(symb);
			if (Inter::Kind::is_a(kind_const, kind_symbol) == FALSE) return Inter::Errors::quoted(I"symbol has the wrong kind", S, eloc);
			Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
			return NULL;
		}
	}
	if (Inter::Types::is_enumerated(idt)) {
		inter_error_message *E;
		inter_symbol *symb = TextualInter::find_symbol(IBM, eloc, S, INSTANCE_IST, &E);
		if (E) return E;
		inter_tree_node *D = InterSymbol::definition(symb);
		if (D == NULL) return Inter::Errors::quoted(I"undefined symbol", S, eloc);
		inter_symbol *kind_const = Inter::Instance::kind_of(symb);
		if (Inter::Kind::is_a(kind_const, kind_symbol) == FALSE) return Inter::Errors::quoted(I"symbol has the wrong kind", S, eloc);
		Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
		Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
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
		if ((idt) && ((N < idt->min_value) || (N > idt->max_value)))
			return Inter::Errors::quoted(I"value out of range", S, eloc);

		*val1 = LITERAL_IVAL; *val2 = (inter_ti) N;
		return NULL;
	}

	int ident = TRUE;
	LOOP_THROUGH_TEXT(pos, S)
		if ((Characters::isalpha(Str::get(pos)) == FALSE) &&
			(Characters::isdigit(Str::get(pos)) == FALSE) &&
			(Str::get(pos) != '_'))
			ident = FALSE;

	if (ident) {
		inter_symbol *symb = InterSymbolsTable::create_with_unique_name(InterBookmark::scope(IBM), S);
		Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
		InterSymbol::set_flag(symb, SPECULATIVE_ISYMF);
		return NULL;
	}

	return Inter::Errors::quoted(I"unrecognised value", S, eloc);
}

int Inter::Types::read_int_in_I6_notation(text_stream *S, inter_ti *val1, inter_ti *val2) {
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

@e UNCHECKED_IDT from 0x60000000
@e INT32_IDT
@e INT16_IDT
@e INT8_IDT
@e INT2_IDT
@e ENUM_IDT
@e LIST_IDT
@e COLUMN_IDT
@e TABLE_IDT
@e TEXT_IDT
@e ROUTINE_IDT
@e STRUCT_IDT
@e RELATION_IDT
@e DESCRIPTION_IDT

=
void Inter::Types::create_all(void) {
	unchecked_idt = Inter::Types::create(UNCHECKED_IDT, I"unchecked", -2147483648, 2147483647, FALSE);
	int32_idt = Inter::Types::create(INT32_IDT, I"int32", -2147483648, 2147483647, FALSE);
	Inter::Types::create(INT16_IDT, I"int16", -32768, 32767, FALSE);
	Inter::Types::create(INT8_IDT, I"int8", -128, 127, FALSE);
	Inter::Types::create(INT2_IDT, I"int2", 0, 1, FALSE);
	Inter::Types::create(ENUM_IDT, I"enum", 0, 2147483647, TRUE);
	Inter::Types::create(LIST_IDT, I"list", -2147483648, 2147483647, FALSE);
	Inter::Types::create(COLUMN_IDT, I"column", -2147483648, 2147483647, FALSE);
	Inter::Types::create(TABLE_IDT, I"table", -2147483648, 2147483647, FALSE);
	Inter::Types::create(TEXT_IDT, I"text", -2147483648, 2147483647, FALSE);
	Inter::Types::create(ROUTINE_IDT, I"routine", -2147483648, 2147483647, FALSE);
	Inter::Types::create(STRUCT_IDT, I"struct", -2147483648, 2147483647, FALSE);
	Inter::Types::create(RELATION_IDT, I"relation", -2147483648, 2147483647, FALSE);
	Inter::Types::create(DESCRIPTION_IDT, I"description", -2147483648, 2147483647, FALSE);
}

@

=
int Inter::Types::pair_holds_symbol(inter_ti val1, inter_ti val2) {
	if (val1 == ALIAS_IVAL) return TRUE;
	return FALSE;
}

void Inter::Types::symbol_to_pair(inter_tree *I, inter_package *pack, inter_symbol *S, inter_ti *val1, inter_ti *val2) {
	if (S == NULL) internal_error("no symbol");
	*val1 = ALIAS_IVAL; *val2 = InterSymbolsTable::id_from_symbol(I, pack, S);
}

