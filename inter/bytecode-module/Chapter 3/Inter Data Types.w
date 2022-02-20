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
@e FUNCTION_IDT
@e STRUCT_IDT
@e RELATION_IDT
@e DESCRIPTION_IDT
@e RULE_IDT
@e RULEBOOK_IDT

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
	Inter::Types::create(FUNCTION_IDT, I"function", -2147483648, 2147483647, FALSE);
	Inter::Types::create(STRUCT_IDT, I"struct", -2147483648, 2147483647, FALSE);
	Inter::Types::create(RELATION_IDT, I"relation", -2147483648, 2147483647, FALSE);
	Inter::Types::create(DESCRIPTION_IDT, I"description", -2147483648, 2147483647, FALSE);
	Inter::Types::create(RULE_IDT, I"rule", -2147483648, 2147483647, FALSE);
	Inter::Types::create(RULEBOOK_IDT, I"rulebook", -2147483648, 2147483647, FALSE);
}

int Inter::Types::is_base(inter_data_type *idt) {
	switch (idt->type_ID) {
		case LIST_IDT:
		case COLUMN_IDT:
		case TABLE_IDT:
		case FUNCTION_IDT:
		case STRUCT_IDT:
		case RELATION_IDT:
		case DESCRIPTION_IDT:
			return FALSE;
	}
	return TRUE;
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

inter_error_message *Inter::Types::validate_pair(inter_package *owner, inter_tree_node *P, int index, inter_type type) {
	inter_ti V1 = P->W.instruction[index];
	inter_ti V2 = P->W.instruction[index+1];
	inter_symbols_table *scope = InterPackage::scope(owner);
	if (scope == NULL) scope = Inode::globals(P);
	switch (V1) {
		case LITERAL_IVAL: {
			inter_data_type *idt = Inter::Types::data_format(type);
			if (idt) {
				long long int I = (signed_inter_ti) V2;
				if ((I < idt->min_value) || (I > idt->max_value)) return Inode::error(P, I"value out of range", NULL);
				return NULL;
			}
			return NULL;
		}
		case ALIAS_IVAL: {
			inter_symbol *symb = InterSymbolsTable::symbol_from_ID(scope, V2);
			if (symb == NULL) return Inode::error(P, I"no such symbol", NULL);
			if (InterSymbol::misc_but_undefined(symb)) return NULL;
			if (InterSymbol::defined_elsewhere(symb)) return NULL;
			if (Inter::Types::expresses_value(symb) == FALSE)
				return Inode::error(P, I"nonconstant symbol", InterSymbol::identifier(symb));
			inter_type symbol_type = Inter::Types::of_symbol(symb);
			return Inter::Types::can_be_used_as(symbol_type, type, InterSymbol::identifier(symb), Inode::get_error_location(P));
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

int Inter::Types::expresses_value(inter_symbol *symb) {
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D) {
		if (D->W.instruction[ID_IFLD] == KIND_IST)     return TRUE;
		if (D->W.instruction[ID_IFLD] == INSTANCE_IST) return TRUE;
		if (D->W.instruction[ID_IFLD] == CONSTANT_IST) return TRUE;
		if (D->W.instruction[ID_IFLD] == LOCAL_IST)    return TRUE;
		if (D->W.instruction[ID_IFLD] == VARIABLE_IST) return TRUE;
		if (D->W.instruction[ID_IFLD] == PROPERTY_IST) return TRUE;
	}
	return FALSE;
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

void Inter::Types::write_pair(OUTPUT_STREAM, inter_tree_node *F,
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

inter_error_message *Inter::Types::can_be_used_as(inter_type A, inter_type B,
	text_stream *S, inter_error_location *eloc) {
	inter_data_type *A_idt = Inter::Types::data_format(A);
	inter_data_type *B_idt = Inter::Types::data_format(A);

	if ((A_idt->type_ID == UNCHECKED_IDT) || (B_idt->type_ID == UNCHECKED_IDT))
		return NULL;

	if ((A_idt->type_ID == LIST_IDT) && (B_idt->type_ID == TEXT_IDT))
		return NULL; // so that two-element arrays can be used to implement I7 texts

	if (Inter::Types::is_base(A_idt) != Inter::Types::is_base(B_idt))
		@<Throw type mismatch error@>;

	if (Inter::Types::is_base(A_idt)) {
		inter_symbol *kind_symbol = B.conceptual_type;
		inter_symbol *kind_loc = A.conceptual_type;
		if ((kind_symbol) && (kind_loc) && (Inter::Kind::is_a(kind_loc, kind_symbol) == FALSE))
			@<Throw type mismatch error@>;
	} else {
		if (A_idt->type_ID != B_idt->type_ID)
			@<Throw type mismatch error@>;
		inter_error_message *operand_E = NULL;
		switch (A_idt->type_ID) {
			case LIST_IDT:
				operand_E = Inter::Types::can_be_used_as(Inter::Types::type_operand(A, 0),
					Inter::Types::type_operand(B, 0), S, eloc);
				if (operand_E) @<Throw type mismatch error@>;
				break;
		}
	}
	return NULL;
}

@<Throw type mismatch error@> =
	text_stream *err = Str::new();
	WRITE_TO(err, "value '%S' has kind ", S);
	Inter::Types::write_type(err, A);
	WRITE_TO(err, " which is not a ");
	Inter::Types::write_type(err, B);
	// WRITE_TO(STDERR, "%S: %S: %x, %x\n", err, S, A.underlying_data->type_ID, B.underlying_data->type_ID);
	return Inter::Errors::plain(err, eloc);

@ =
inter_type Inter::Types::of_symbol(inter_symbol *symb) {
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) return Inter::Types::untyped();
	if (InterSymbol::defined_elsewhere(symb)) return Inter::Types::untyped();
	if (D->W.instruction[ID_IFLD] == LOCAL_IST) return Inter::Local::type_of(symb);
	if (D->W.instruction[ID_IFLD] == CONSTANT_IST) return Inter::Constant::type_of(symb);
	if (D->W.instruction[ID_IFLD] == INSTANCE_IST) return Inter::Instance::type_of(symb);
	if (D->W.instruction[ID_IFLD] == VARIABLE_IST) return Inter::Variable::type_of(symb);
	if (D->W.instruction[ID_IFLD] == PROPERTY_IST) return Inter::Property::type_of(symb);
	return Inter::Types::untyped();
}

inter_error_message *Inter::Types::read_data_pair(text_stream *line, inter_error_location *eloc,
	inter_bookmark *IBM, inter_type it, text_stream *S, inter_ti *val1, inter_ti *val2,
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
		Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
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
		inter_data_type *idt = it.underlying_data;
		if ((idt) && ((N < idt->min_value) || (N > idt->max_value)))
			return Inter::Errors::quoted(I"value out of range", S, eloc);

		*val1 = LITERAL_IVAL; *val2 = (inter_ti) N;
		return NULL;
	}

	return Inter::Errors::quoted(I"unrecognised value", S, eloc);
}

@<Read symb@> =
	inter_data_type *idt = it.underlying_data;
	if ((Inter::Types::is_enumerated(idt)) &&
		(InterSymbol::is_defined(symb) == FALSE))
		return Inter::Errors::quoted(I"undefined symbol", S, eloc);
	inter_type symbol_type = Inter::Types::of_symbol(symb);
	if (symbol_type.underlying_data->type_ID != UNCHECKED_IDT) {
		inter_error_message *E = Inter::Types::can_be_used_as(symbol_type, it, S, eloc);
		if (E) return E;
	}
	Inter::Types::symbol_to_pair(I, pack, symb, val1, val2);
	return NULL;

@ =
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

=
int Inter::Types::pair_holds_symbol(inter_ti val1, inter_ti val2) {
	if (val1 == ALIAS_IVAL) return TRUE;
	return FALSE;
}

void Inter::Types::symbol_to_pair(inter_tree *I, inter_package *pack, inter_symbol *S,
	inter_ti *val1, inter_ti *val2) {
	if (S == NULL) internal_error("no symbol");
	*val1 = ALIAS_IVAL; *val2 = InterSymbolsTable::id_from_symbol(I, pack, S);
}

typedef struct inter_type {
	inter_data_type *underlying_data;
	inter_symbol *conceptual_type;
} inter_type;

inter_type Inter::Types::parse(inter_symbols_table *T, inter_error_location *eloc,
	text_stream *text, inter_error_message **E) {
	inter_type it;
	it.conceptual_type = NULL;
	it.underlying_data = unchecked_idt;
	if (Str::len(text) > 0) {
		it.conceptual_type = TextualInter::find_symbol_in_table(T, eloc, text, KIND_IST, E);
		if (it.conceptual_type)
			it.underlying_data = Inter::Kind::data_type(it.conceptual_type);
		else {
			it.underlying_data = Inter::Types::find_by_name(text);
			if (it.underlying_data == NULL) {
				*E = Inter::Errors::quoted(I"unrecognised data type", text, eloc);
				it.underlying_data = unchecked_idt;
			}
		}
	}
	return it;
}

inter_type Inter::Types::from_symbol(inter_symbol *S) {
	inter_type it;
	if (S) it.underlying_data = Inter::Kind::data_type(S);
	else it.underlying_data = unchecked_idt;
	it.conceptual_type = S;
	return it;
}

inter_symbol *Inter::Types::conceptual_type(inter_type it) {
	return it.conceptual_type;
}

inter_type Inter::Types::untyped(void) {
	return Inter::Types::from_symbol(NULL);
}

inter_data_type *Inter::Types::data_format(inter_type it) {
	return it.underlying_data;
}

int Inter::Types::type_arity(inter_type it) {
	return Inter::Kind::arity(Inter::Types::conceptual_type(it));
}

inter_type Inter::Types::type_operand(inter_type it, int n) {
	return Inter::Types::from_symbol(Inter::Kind::operand_symbol(Inter::Types::conceptual_type(it), n));
}

inter_type Inter::Types::from_TID(inter_tree_node *P, int field) {
	inter_type it;
	it.underlying_data = unchecked_idt;
	it.conceptual_type = InterSymbolsTable::symbol_from_ID_at_node(P, field);
	if (it.conceptual_type)
		it.underlying_data = Inter::Kind::data_type(it.conceptual_type);
	return it;
}

inter_ti Inter::Types::to_TID(inter_bookmark *IBM, inter_type it) {
	if (it.conceptual_type)
		return InterSymbolsTable::id_from_symbol_at_bookmark(IBM, it.conceptual_type);
	return 0;
}

void Inter::Types::verify_type_field(inter_package *owner, inter_tree_node *P,
	int field, int data_field, inter_error_message **E) {
	if (P->W.instruction[field]) {
		*E = Inter::Verify::symbol(owner, P, P->W.instruction[field], KIND_IST);
		if (*E) return;
		if (data_field >= 0) {
			inter_type type = Inter::Types::from_TID(P, field);
			*E = Inter::Types::validate_pair(owner, P, data_field, type);
			if (*E) return;
		}
	}
}

void Inter::Types::write_type_field(OUTPUT_STREAM, inter_tree_node *P, int field) {
	inter_type it = Inter::Types::from_TID(P, field);
	if (it.conceptual_type) {
		WRITE("("); TextualInter::write_symbol_from(OUT, P, field); WRITE(") ");
	} else if (it.underlying_data != unchecked_idt) {
		WRITE("(%S) ", it.underlying_data->reserved_word);
	}
}

void Inter::Types::write_type(OUTPUT_STREAM, inter_type type) {
	if (type.conceptual_type) {
		TextualInter::write_symbol(OUT, type.conceptual_type);
	} else if (type.underlying_data != unchecked_idt) {
		WRITE("%S", type.underlying_data->reserved_word);
	}
}
