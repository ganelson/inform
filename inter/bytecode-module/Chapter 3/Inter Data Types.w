[InterTypes::] Inter Data Types.

A primitive notion of data type, below the level of kinds.

@h Constructors.
Abstractly, an Inter type is a combination of a "constructor" and 0 or more
"operand types", the number depending on which constructor is used. If this
is 0, type is a "base" constructor.

Constructors are identified textually by keywords, such as |int32|, and also
by "constructor ID" numbers, such as |INT32_ITCONC|. This one is a base;
whereas |list|, for example, is not -- |list of int32| is a valid type, with
1 type operand, but |list| alone is not sufficient to specify a type.

@ The set of valid constructor IDs is fixed and it is here:

@e UNCHECKED_ITCONC from 1
@e INT32_ITCONC
@e INT16_ITCONC
@e INT8_ITCONC
@e INT2_ITCONC
@e TEXT_ITCONC
@e ENUM_ITCONC
@e LIST_ITCONC
@e COLUMN_ITCONC
@e TABLE_ITCONC
@e FUNCTION_ITCONC
@e STRUCT_ITCONC
@e RELATION_ITCONC
@e DESCRIPTION_ITCONC
@e RULE_ITCONC
@e RULEBOOK_ITCONC
@e EQUATED_ITCONC
@e VOID_ITCONC

@d MIN_INTER_TYPE_CONSTRUCTOR UNCHECKED_ITCONC
@d MAX_INTER_TYPE_CONSTRUCTOR VOID_ITCONC

=
int InterTypes::is_valid_constructor_code(inter_ti constructor) {
	if ((constructor < MIN_INTER_TYPE_CONSTRUCTOR) ||
		(constructor > MAX_INTER_TYPE_CONSTRUCTOR)) return FALSE;
	return TRUE;
}

@ Clearly we need to store some metadata about what these constructor IDs
mean, and we do that with a simple lookup array large enough to hold all
valid constructor codes as indexes:

=
typedef struct inter_type_constructor {
	inter_ti constructor_ID;
	struct text_stream *constructor_keyword;
	long long int min_value;
	long long int max_value;
	int is_enumerated;
	int is_base;
	int arity;
} inter_type_constructor;

inter_type_constructor inter_type_constructors[MAX_INTER_TYPE_CONSTRUCTOR + 1];

@ That array initially contains undetermined data, of course, so we need to
initialise it:

=
void InterTypes::initialise_constructors(void) {
	InterTypes::init_con(UNCHECKED_ITCONC,   I"unchecked",   -2147483648, 2147483647, FALSE,  TRUE, 0);
	InterTypes::init_con(INT32_ITCONC,       I"int32",       -2147483648, 2147483647, FALSE,  TRUE, 0);
	InterTypes::init_con(INT16_ITCONC,       I"int16",            -32768,      32767, FALSE,  TRUE, 0);
	InterTypes::init_con(INT8_ITCONC,        I"int8",               -128,        127, FALSE,  TRUE, 0);
	InterTypes::init_con(INT2_ITCONC,        I"int2",                  0,          1, FALSE,  TRUE, 0);
	InterTypes::init_con(TEXT_ITCONC,        I"text",        -2147483648, 2147483647, FALSE,  TRUE, 0);
	InterTypes::init_con(ENUM_ITCONC,        I"enum",                  0, 2147483647,  TRUE,  TRUE, 0);
	InterTypes::init_con(LIST_ITCONC,        I"list",        -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(COLUMN_ITCONC,      I"column",      -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(TABLE_ITCONC,       I"table",       -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(FUNCTION_ITCONC,    I"function",    -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(STRUCT_ITCONC,      I"struct",      -2147483648, 2147483647, FALSE, FALSE, 0);
	InterTypes::init_con(RELATION_ITCONC,    I"relation",    -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(DESCRIPTION_ITCONC, I"description", -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(RULE_ITCONC,        I"rule",        -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(RULEBOOK_ITCONC,    I"rulebook",    -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(EQUATED_ITCONC,     I"",            -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(VOID_ITCONC,        I"void",                  1,          0, FALSE,  TRUE, 0);
}

@ Where:

=
inter_type_constructor *InterTypes::init_con(inter_ti ID, text_stream *name,
	int range_from, int range_to, int en, int base, int arity) {
	if (InterTypes::is_valid_constructor_code(ID) == FALSE)
		internal_error("constructor ID out of range");

	inter_type_constructor *IDT = &(inter_type_constructors[ID]);
	IDT->constructor_ID = ID;
	IDT->constructor_keyword = Str::duplicate(name);
	IDT->min_value = range_from;
	IDT->max_value = range_to;
	IDT->is_enumerated = en;
	IDT->is_base = base;

	return IDT;
}

@ Assuming that has been done, it is safe to call these lookup functions. Note
that it's fine for textual lookups to be relatively slow.

=
inter_type_constructor *InterTypes::constructor_from_ID(inter_ti ID) {
	if (InterTypes::is_valid_constructor_code(ID)) return &(inter_type_constructors[ID]);
	return NULL;
}

inter_type_constructor *InterTypes::constructor_from_name(text_stream *name) {
	for (inter_ti ID = MIN_INTER_TYPE_CONSTRUCTOR; ID <= MAX_INTER_TYPE_CONSTRUCTOR; ID++) {
		inter_type_constructor *itc = &(inter_type_constructors[ID]);
		if (Str::eq(itc->constructor_keyword, name))
			return itc;
	}
	return NULL;
}

@h Simple types and type names.
We need to represent types very economically in terms of memory. In principle,
the set of abstract types is infinite (consider for example |int32|, |list of int32|,
|list of list of int32|, ...), so there is no limit to the memory which might
be required.

We use the following representations, starting with the most concise:

(1) A "TID", or type ID, is a single |inter_ti| value, often stored as a field
in the bytecode for some instruction. For example, a |VARIABLE_IST| instruction
includes a field holding the TID of its variable's type. This can only represent
simple descriptions (see below), and you need to know what package a TID
came from (i.e., what symbols table was in use there) to unravel it.

(2) An //inter_type// is a lightweight structure intended for passing around
the functions in this section. It can also only represent simple descriptions -- in
fact, TIDs and |inter_type|s can faithfully be converted back and forth -- but
has the advantage that you don't need any package context to understand it.
Arguably this should be called |inter_simple_type_description|, but this is the
one we use most often, so brevity is good.

(3) An //inter_semisimple_type_description// is a much larger structure used only
when parsing Inter code from text -- so in a regular Inform 7 compilation run, no
such structures will ever exist. This is still limited, but to the larger
set of semi-simple type descriptions.

The following definitions look circular, but are not:[1]

(*) A "simple type description" is either a constructor for which all type
operands are |unchecked|, such as |int32| or |list of unchecked|, or else a
"type name".

(*) A "semi-simple type description" is either a constructor for which all
type operands are simple, or else a "type name".

(*) A "type name" is a name defined with a specific semi-simple type description.

[1] Because the hierarchy of definitions of type names must be well-founded.
You cannot define |K_apple| to equal |K_pear| and vice versa. Each type name
must be defined in terms of a finite number of simple types, once all type
name substitution has been performed, and no type name can ever lead back to
itself.

@ By using type names we can (indirectly) represent any abstract type using
any of the representations above. For example, |list of list of int32| is neither
simple nor semi-simple, but we can get to it by:

(1) Defining |K_list_of_int32| as a type name for |list of int32|, which is
semi-simple.

(2) Defining |K_list_of_list_of_int32| as a type name for |list of K_list_of_int32|,
which is semi-simple.

And we now have |K_list_of_list_of_int32|, which is simple since it is a bare
type name, and so can be stored in an //inter_type// or a TID.

@ So, then, this holds any simple type description:

=
typedef struct inter_type {
	inter_ti underlying_constructor;
	inter_symbol *type_name;
} inter_type;

@ Since there are two possibilities, there are two functions to construct these:

=
inter_type InterTypes::from_constructor_code(inter_ti constructor_code) {
	if (InterTypes::is_valid_constructor_code(constructor_code) == FALSE)
		internal_error("invalid constructor code");
	inter_type type;
	type.underlying_constructor = constructor_code;
	type.type_name = NULL;
	return type;
}

inter_type InterTypes::from_type_name(inter_symbol *S) {
	if (S) {
		inter_type type;
		type.underlying_constructor = Inter::Kind::constructor(S);
		type.type_name = S;
		return type;
	}
	return InterTypes::untyped();
}

@ Reading those back:

=
inter_symbol *InterTypes::type_name(inter_type type) {
	return type.type_name;
}

inter_type_constructor *InterTypes::constructor(inter_type type) {
	inter_type_constructor *itc = InterTypes::constructor_from_ID(type.underlying_constructor);
	if (itc == NULL) itc = InterTypes::constructor_from_ID(UNCHECKED_ITCONC);
	return itc;
}

inter_ti InterTypes::constructor_code(inter_type type) {
	return InterTypes::constructor(type)->constructor_ID;
}

@ In some ways the most useful simple type is |unchecked|. This declares that
all type-checking rules are waived for the data being described. A program
in which all data is |unchecked| is a program with no type-checking at all.

=
inter_type InterTypes::untyped(void) {
	return InterTypes::from_constructor_code(UNCHECKED_ITCONC);
}

int InterTypes::is_untyped(inter_type type) {
	if (InterTypes::constructor_code(type) == UNCHECKED_ITCONC) return TRUE;
	return FALSE;
}

@

=
int InterTypes::type_arity(inter_type type) {
	inter_symbol *type_name = InterTypes::type_name(type);
	if (type_name) return Inter::Kind::arity(type_name);
	return InterTypes::constructor(type)->arity;
}

inter_type InterTypes::type_operand(inter_type type, int n) {
	inter_symbol *type_name = InterTypes::type_name(type);
	if (type_name) return Inter::Kind::operand_type(InterTypes::type_name(type), n);
	return InterTypes::untyped();
}

@h Converting inter_type to TID and vice versa.

=
inter_type InterTypes::from_TID(inter_symbols_table *T, inter_ti TID) {
	if (TID >= SYMBOL_BASE_VAL)
		return InterTypes::from_type_name(InterSymbolsTable::symbol_from_ID(T, TID));
	if (InterTypes::is_valid_constructor_code(TID))
		return InterTypes::from_constructor_code(TID);
	return InterTypes::untyped();
}

inter_type InterTypes::from_TID_in_field(inter_tree_node *P, int field) {
	return InterTypes::from_TID(InterPackage::scope(Inode::get_package(P)), P->W.instruction[field]);
}

@ =
inter_ti InterTypes::to_TID(inter_symbols_table *T, inter_type type) {
	if (type.type_name)
		return InterSymbolsTable::id_from_symbol_in_table(T, type.type_name);
	return type.underlying_constructor;
}

inter_ti InterTypes::to_TID_wrt_bookmark(inter_bookmark *IBM, inter_type type) {
	if (type.type_name)
		return InterSymbolsTable::id_from_symbol_at_bookmark(IBM, type.type_name);
	return type.underlying_constructor;
}

@h Parsing from text.

@d DEFAULT_SIZE_OF_ISSTD_OPERAND_ARRAY 32

=
typedef struct inter_semisimple_type_description {
	inter_ti constructor_code;
	int arity;
	int capacity;
	inter_ti default_operand_TIDs[DEFAULT_SIZE_OF_ISSTD_OPERAND_ARRAY];
	inter_ti *operand_TIDs;
} inter_semisimple_type_description;

void InterTypes::initialise_isstd(inter_semisimple_type_description *results) {
	results->constructor_code = UNCHECKED_ITCONC;
	results->arity = 0;
	results->capacity = DEFAULT_SIZE_OF_ISSTD_OPERAND_ARRAY;
	results->operand_TIDs = results->default_operand_TIDs;
}

void InterTypes::add_operand_to_isstd(inter_semisimple_type_description *results,
	inter_symbols_table *T, inter_type type) {
	inter_ti TID = InterTypes::to_TID(T, type);
	if (results->arity >= results->capacity) {
		inter_ti *extended = (inter_ti *) Memory::calloc(2*results->capacity, sizeof(inter_ti),
			INTER_BYTECODE_MREASON);
		for (int i=0; i<2*results->capacity; i++)
			if (i < results->capacity)
				extended[i] = results->operand_TIDs[i];
			else
				extended[i] = 0;
		@<Free operand memory@>;
		results->capacity = 2*results->capacity;
		results->operand_TIDs = extended;
	}
	results->operand_TIDs[(results->arity)++] = TID;	
}

@ =
void InterTypes::dispose_of_isstd(inter_semisimple_type_description *results) {
	results->constructor_code = UNCHECKED_ITCONC;
	results->arity = 0;
	@<Free operand memory@>;
}

@<Free operand memory@> =
	if (results->capacity > DEFAULT_SIZE_OF_ISSTD_OPERAND_ARRAY)
		Memory::I7_array_free(results->operand_TIDs, INTER_BYTECODE_MREASON,
			results->capacity, sizeof(inter_ti));

@ =
inter_error_message *InterTypes::parse_semisimple(text_stream *text, inter_symbols_table *T,
	inter_error_location *eloc, inter_semisimple_type_description *results) {
	results->constructor_code = UNCHECKED_ITCONC;
	results->arity = 0;
	inter_error_message *E = NULL;
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, text, L"rulebook of (%C+)")) {
		results->constructor_code = RULEBOOK_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr2.exp[0], &E);
		if (E) return E;
		InterTypes::add_operand_to_isstd(results, T, conts_type);
	} else if (Regexp::match(&mr2, text, L"list of (%C+)")) {
		results->constructor_code = LIST_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr2.exp[0], &E);
		if (E) return E;
		InterTypes::add_operand_to_isstd(results, T, conts_type);
	} else if (Regexp::match(&mr2, text, L"relation of (%C+) to (%C+)")) {
		results->constructor_code = RELATION_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr2.exp[0], &E);
		if (E) return E;
		inter_type Y_type = InterTypes::parse_simple(T, eloc, mr2.exp[1], &E);
		if (E) return E;
		InterTypes::add_operand_to_isstd(results, T, X_type);
		InterTypes::add_operand_to_isstd(results, T, Y_type);
	} else if (Regexp::match(&mr2, text, L"column of (%C+)")) {
		results->constructor_code = COLUMN_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr2.exp[0], &E);
		if (E) return E;
		InterTypes::add_operand_to_isstd(results, T, conts_type);
	} else if (Regexp::match(&mr2, text, L"description of (%C+)")) {
		results->constructor_code = DESCRIPTION_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr2.exp[0], &E);
		if (E) return E;
		InterTypes::add_operand_to_isstd(results, T, conts_type);
	} else if ((Regexp::match(&mr2, text, L"(function) (%c+) -> (%i+)")) ||
			(Regexp::match(&mr2, text, L"(rule) (%c+) -> (%i+)"))) {
		if (Str::eq(mr2.exp[0], I"function")) results->constructor_code = FUNCTION_ITCONC;
		else results->constructor_code = RULE_ITCONC;
		text_stream *from = mr2.exp[1];
		text_stream *to = mr2.exp[2];
		if (Str::eq(from, I"void")) {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::from_constructor_code(VOID_ITCONC));
		} else {
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, from, L" *(%C+) *(%c*)")) {
				inter_type arg_type = InterTypes::parse_simple(T, eloc, mr3.exp[0], &E);
				if (E) return E;
				Str::copy(from, mr3.exp[1]);
				InterTypes::add_operand_to_isstd(results, T, arg_type);
			}
		}
		if (Str::eq(to, I"void")) {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::from_constructor_code(VOID_ITCONC));
		} else {
			inter_type res_type = InterTypes::parse_simple(T, eloc, to, &E);
			if (E) return E;
			InterTypes::add_operand_to_isstd(results, T, res_type);
		}
	} else if (Regexp::match(&mr2, text, L"struct (%c+)")) {
		results->constructor_code = STRUCT_ITCONC;
		text_stream *elements = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, elements, L" *(%C+) *(%c*)")) {
			inter_type arg_type = InterTypes::parse_simple(T, eloc, mr3.exp[0], &E);
			if (E) return E;
			Str::copy(elements, mr3.exp[1]);
			InterTypes::add_operand_to_isstd(results, T, arg_type);
		}
	} else {
		inter_type_constructor *itc = InterTypes::constructor_from_name(text);
		if (itc) {
			results->constructor_code = itc->constructor_ID;
			return NULL;
		}
		inter_symbol *K = TextualInter::find_symbol_in_table(T, eloc, text, KIND_IST, &E);
		if (E) return E;
		if (K) {
			results->constructor_code = EQUATED_ITCONC;
			InterTypes::add_operand_to_isstd(results, T, InterTypes::from_type_name(K));
			return NULL;
		}
		return Inter::Errors::quoted(I"no such data type", text, eloc);
	}
	return NULL;
}

inter_type InterTypes::parse_simple(inter_symbols_table *T, inter_error_location *eloc,
	text_stream *text, inter_error_message **E) {
	if (Str::len(text) > 0) {
		inter_semisimple_type_description parsed_description;
		InterTypes::initialise_isstd(&parsed_description);
		*E = InterTypes::parse_semisimple(text, T, eloc, &parsed_description);
		if (*E) return InterTypes::untyped();
		if (parsed_description.constructor_code == VOID_ITCONC) {
			*E = Inter::Errors::quoted(I"'void' cannot be used as a type", text, eloc);
			return InterTypes::untyped();
		}
		if (parsed_description.constructor_code == EQUATED_ITCONC) {
			inter_type type = InterTypes::from_TID(T, parsed_description.operand_TIDs[0]);
			InterTypes::dispose_of_isstd(&parsed_description);
			return type;
		}
		if (parsed_description.arity > 0)  {
			InterTypes::dispose_of_isstd(&parsed_description);
			*E = Inter::Errors::quoted(I"type too complex", text, eloc);
			return InterTypes::untyped();
		}
		inter_type type = InterTypes::from_constructor_code(parsed_description.constructor_code);
		InterTypes::dispose_of_isstd(&parsed_description);
		return type;
	}
	return InterTypes::untyped();
}

@h Writing to text.

=
void InterTypes::write_optional_type_marker(OUTPUT_STREAM, inter_tree_node *P, int field) {
	inter_type type = InterTypes::from_TID_in_field(P, field);
	if (type.type_name) {
		WRITE("("); TextualInter::write_symbol_from(OUT, P, field); WRITE(") ");
	} else if (InterTypes::is_untyped(type) == FALSE) {
		WRITE("("); InterTypes::write_type(OUT, type); WRITE(") ");
	}
}

void InterTypes::write_type_in_field(OUTPUT_STREAM, inter_tree_node *P, int field) {
	InterTypes::write_type(OUT, InterTypes::from_TID_in_field(P, field));
}

void InterTypes::write_type(OUTPUT_STREAM, inter_type type) {
	if (type.type_name) {
		TextualInter::write_symbol(OUT, type.type_name);
	} else {
		inter_type_constructor *itc = InterTypes::constructor(type);
		WRITE("%S", itc->constructor_keyword);
		switch (itc->constructor_ID) {
			case EQUATED_ITCONC:
				InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
				break;
			case DESCRIPTION_ITCONC:
			case COLUMN_ITCONC:
			case RULEBOOK_ITCONC:
			case LIST_ITCONC:
				WRITE(" of ");
				InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
				break;
			case RELATION_ITCONC:
				WRITE(" of ");
				InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
				WRITE(" to ");
				InterTypes::write_type(OUT, InterTypes::type_operand(type, 1));
				break;
			case FUNCTION_ITCONC:
			case RULE_ITCONC: {
				int arity = InterTypes::type_arity(type);
				for (int i=0; i<arity; i++) {
					WRITE(" ");
					if (i == arity - 1) WRITE("-> ");
					InterTypes::write_type(OUT, InterTypes::type_operand(type, i));
				}
				break;
			}
			case STRUCT_ITCONC: {
				int arity = InterTypes::type_arity(type);
				for (int i=0; i<arity; i++) {
					WRITE(" ");
					InterTypes::write_type(OUT, InterTypes::type_operand(type, i));
				}
				break;
			}
		}		
	}
}

void InterTypes::write_type_name_definition(OUTPUT_STREAM, inter_symbol *type_name) {
	inter_type_constructor *itc = InterTypes::constructor_from_ID(Inter::Kind::constructor(type_name));
	if (itc == NULL) { WRITE("<bad-constructor>"); return; }
	WRITE("%S", itc->constructor_keyword);
	switch (itc->constructor_ID) {
		case EQUATED_ITCONC:
			InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, 0));
			break;
		case DESCRIPTION_ITCONC:
		case COLUMN_ITCONC:
		case RULEBOOK_ITCONC:
		case LIST_ITCONC:
			WRITE(" of ");
			InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, 0));
			break;
		case RELATION_ITCONC:
			WRITE(" of ");
			InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, 0));
			WRITE(" to ");
			InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, 1));
			break;
		case FUNCTION_ITCONC:
		case RULE_ITCONC: {
			int arity = Inter::Kind::arity(type_name);
			for (int i=0; i<arity; i++) {
				WRITE(" ");
				if (i == arity - 1) WRITE("-> ");
				InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, i));
			}
			break;
		}
		case STRUCT_ITCONC: {
			int arity = Inter::Kind::arity(type_name);
			for (int i=0; i<arity; i++) {
				WRITE(" ");
				InterTypes::write_type(OUT, Inter::Kind::operand_type(type_name, i));
			}
			break;
		}
	}		
}

@h Typechecking.

=
int InterTypes::is_enumerated(inter_type type) {
	inter_type_constructor *itc = InterTypes::constructor(type);
	if (itc->is_enumerated) return TRUE;
	return FALSE;
}

int InterTypes::literal_is_in_range(long long int N, inter_type type) {
	inter_type_constructor *itc = InterTypes::constructor(type);
	if ((N < itc->min_value) || (N > itc->max_value)) return FALSE;
	return TRUE;
}

inter_error_message *InterTypes::can_be_used_as(inter_type A, inter_type B,
	text_stream *S, inter_error_location *eloc) {
	inter_type_constructor *A_itc = InterTypes::constructor(A);
	inter_type_constructor *B_itc = InterTypes::constructor(B);

	if ((A_itc->constructor_ID == UNCHECKED_ITCONC) || (B_itc->constructor_ID == UNCHECKED_ITCONC))
		return NULL;

	if ((A_itc->constructor_ID == LIST_ITCONC) && (B_itc->constructor_ID == TEXT_ITCONC))
		return NULL; // so that two-element arrays can be used to implement I7 texts

	if (A_itc->is_base != B_itc->is_base)
		@<Throw type mismatch error@>;

	if (A_itc->is_base) {
		inter_symbol *kind_symbol = B.type_name;
		inter_symbol *kind_loc = A.type_name;
		if ((kind_symbol) && (kind_loc) && (Inter::Kind::is_a(kind_loc, kind_symbol) == FALSE))
			@<Throw type mismatch error@>;
	} else {
		if (A_itc->constructor_ID != B_itc->constructor_ID)
			@<Throw type mismatch error@>;
		inter_error_message *operand_E = NULL;
		switch (A_itc->constructor_ID) {
			case LIST_ITCONC:
				operand_E = InterTypes::can_be_used_as(InterTypes::type_operand(A, 0),
					InterTypes::type_operand(B, 0), S, eloc);
				if (operand_E) @<Throw type mismatch error@>;
				break;
		}
	}
	return NULL;
}

@<Throw type mismatch error@> =
	text_stream *err = Str::new();
	WRITE_TO(err, "value '%S' has kind ", S);
	InterTypes::write_type(err, A);
	WRITE_TO(err, " which is not a ");
	InterTypes::write_type(err, B);
	return Inter::Errors::plain(err, eloc);

@h The type of a defined symbol.

=
inter_type InterTypes::of_symbol(inter_symbol *symb) {
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) return InterTypes::untyped();
	if (InterSymbol::defined_elsewhere(symb)) return InterTypes::untyped();
	if (D->W.instruction[ID_IFLD] == LOCAL_IST) return Inter::Local::type_of(symb);
	if (D->W.instruction[ID_IFLD] == CONSTANT_IST) return Inter::Constant::type_of(symb);
	if (D->W.instruction[ID_IFLD] == INSTANCE_IST) return Inter::Instance::type_of(symb);
	if (D->W.instruction[ID_IFLD] == VARIABLE_IST) return Inter::Variable::type_of(symb);
	if (D->W.instruction[ID_IFLD] == PROPERTY_IST) return Inter::Property::type_of(symb);
	return InterTypes::untyped();
}

int InterTypes::expresses_value(inter_symbol *symb) {
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
