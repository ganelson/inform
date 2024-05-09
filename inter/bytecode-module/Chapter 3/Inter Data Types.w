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

@ These are the constructor IDs. Note that changing any of these values would
invalidate existing Inter binary files, necessitating a bump of //The Inter Version//.

@e UNCHECKED_ITCONC from 1
@e INT32_ITCONC
@e INT16_ITCONC
@e INT8_ITCONC
@e INT2_ITCONC
@e REAL_ITCONC
@e TEXT_ITCONC
@e ENUM_ITCONC
@e LIST_ITCONC
@e ACTIVITY_ITCONC
@e COLUMN_ITCONC
@e TABLE_ITCONC
@e FUNCTION_ITCONC
@e STRUCT_ITCONC
@e RELATION_ITCONC
@e DESCRIPTION_ITCONC
@e RULE_ITCONC
@e RULEBOOK_ITCONC
@e EQUATED_ITCONC

@e UNARY_COV_ITCONC
@e UNARY_CON_ITCONC
@e BINARY_COV_COV_ITCONC
@e BINARY_COV_CON_ITCONC
@e BINARY_CON_COV_ITCONC
@e BINARY_CON_CON_ITCONC

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
	InterTypes::init_con(REAL_ITCONC,        I"real",        -2147483648, 2147483647, FALSE,  TRUE, 0);
	InterTypes::init_con(TEXT_ITCONC,        I"text",        -2147483648, 2147483647, FALSE,  TRUE, 0);
	InterTypes::init_con(ENUM_ITCONC,        I"enum",        -2147483648, 2147483647,  TRUE,  TRUE, 0);
	InterTypes::init_con(LIST_ITCONC,        I"list",        -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(ACTIVITY_ITCONC,    I"activity",    -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(COLUMN_ITCONC,      I"column",      -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(TABLE_ITCONC,       I"table",       -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(FUNCTION_ITCONC,    I"function",    -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(STRUCT_ITCONC,      I"struct",      -2147483648, 2147483647, FALSE, FALSE, 0);
	InterTypes::init_con(RELATION_ITCONC,    I"relation",    -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(DESCRIPTION_ITCONC, I"description", -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(RULE_ITCONC,        I"rule",        -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(RULEBOOK_ITCONC,    I"rulebook",    -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(EQUATED_ITCONC,     I"",            -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(UNARY_COV_ITCONC,   I"unary-cov",   -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(UNARY_CON_ITCONC,   I"unary-con",   -2147483648, 2147483647, FALSE, FALSE, 1);
	InterTypes::init_con(BINARY_COV_COV_ITCONC, I"binary-cov-cov", -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(BINARY_COV_CON_ITCONC, I"binary-cov-con", -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(BINARY_CON_COV_ITCONC, I"binary-con-cov", -2147483648, 2147483647, FALSE, FALSE, 2);
	InterTypes::init_con(BINARY_CON_CON_ITCONC, I"binary-con-con", -2147483648, 2147483647, FALSE, FALSE, 2);
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
	IDT->arity = arity;

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
		type.underlying_constructor = TypenameInstruction::constructor(S);
		type.type_name = S;
		return type;
	}
	return InterTypes::unchecked();
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
inter_type InterTypes::unchecked(void) {
	return InterTypes::from_constructor_code(UNCHECKED_ITCONC);
}

int InterTypes::is_unchecked(inter_type type) {
	if (InterTypes::constructor_code(type) == UNCHECKED_ITCONC) return TRUE;
	return FALSE;
}

@ Access to the arity and operands depends on whether there's a typename or not:
only with a typename can we have an arity other than the default (e.g. a
|FUNCTION_ITCONC| with arity 5) or operands other than |unchecked|.

=
int InterTypes::arity_is_possible(inter_type type, int arity) {
	inter_type_constructor *itc = InterTypes::constructor(type);
	if (itc->arity == (int) arity) return TRUE;
	if (itc->constructor_ID == TABLE_ITCONC)
		if (arity == 0) return TRUE;
	if ((itc->constructor_ID == FUNCTION_ITCONC) ||
		(itc->constructor_ID == RULE_ITCONC) ||
		(itc->constructor_ID == STRUCT_ITCONC)) {
		if (itc->arity <= (int) arity) return TRUE;
	}
	return FALSE;
}

int InterTypes::type_arity(inter_type type) {
	inter_symbol *type_name = InterTypes::type_name(type);
	if (type_name) return TypenameInstruction::arity(type_name);
	return InterTypes::constructor(type)->arity;
}

inter_type InterTypes::type_operand(inter_type type, int n) {
	inter_symbol *type_name = InterTypes::type_name(type);
	if (type_name) return TypenameInstruction::operand_type(InterTypes::type_name(type), n);
	return InterTypes::unchecked();
}

@h Converting inter_type to TID.

=
inter_type InterTypes::from_TID(inter_symbols_table *T, inter_ti TID) {
	if (TID >= SYMBOL_BASE_VAL)
		return InterTypes::from_type_name(InterSymbolsTable::symbol_from_ID(T, TID));
	if (InterTypes::is_valid_constructor_code(TID))
		return InterTypes::from_constructor_code(TID);
	return InterTypes::unchecked();
}

inter_type InterTypes::from_TID_in_field(inter_tree_node *P, int field) {
	return InterTypes::from_TID(InterPackage::scope(Inode::get_package(P)),
		P->W.instruction[field]);
}

@h Converting TID to inter_type.

=
inter_ti InterTypes::to_TID(inter_symbols_table *T, inter_type type) {
	if (type.type_name)
		return InterSymbolsTable::id_from_symbol_in_table(T, type.type_name);
	return type.underlying_constructor;
}

inter_ti InterTypes::to_TID_at(inter_bookmark *IBM, inter_type type) {
	if (type.type_name)
		return InterSymbolsTable::id_at_bookmark(IBM, type.type_name);
	return type.underlying_constructor;
}

@h Parsing from text.
The data structure //inter_semisimple_type_description// exists as a way of
holding the results of the function //InterTypes::parse_semisimple// -- see
below. It's made convoluted by the remote but theoretical need to handle an
arbitrarily large number of type operands. No human user of Inter would ever
write a type exceeding about 10 operands, but we want to avoid any maxima in
Inter because it's primarily designed as a language for programs to write.

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

@ After a call to //InterTypes::parse_semisimple// the following should be used
to dispose of the structure. Of course, almost always it does nothing, but it
prevents a memory leak if really large results were returned.

=
void InterTypes::dispose_of_isstd(inter_semisimple_type_description *results) {
	results->constructor_code = UNCHECKED_ITCONC;
	results->arity = 0;
	@<Free operand memory@>;
}

@<Free operand memory@> =
	if (results->capacity > DEFAULT_SIZE_OF_ISSTD_OPERAND_ARRAY)
		Memory::I7_array_free(results->operand_TIDs, INTER_BYTECODE_MREASON,
			results->capacity, sizeof(inter_ti));

@ Here goes, then:

=
inter_error_message *InterTypes::parse_semisimple(text_stream *text, inter_symbols_table *T,
	inter_error_location *eloc, inter_semisimple_type_description *results) {
	results->constructor_code = UNCHECKED_ITCONC;
	results->arity = 0;
	inter_error_message *E = NULL;
	match_results mr = Regexp::create_mr();
	
	@<Parse rulebook syntax@>;
	@<Parse list syntax@>;
	@<Parse activity syntax@>;
	@<Parse column syntax@>;
	@<Parse table syntax@>;
	@<Parse description syntax@>;
	@<Parse relation syntax@>;
	@<Parse rule or function syntax@>;
	@<Parse struct syntax@>;
	@<Parse generic unary or binary syntax@>;
	@<Parse bare constructor-name syntax@>;
	@<Parse bare typename syntax@>;

	Regexp::dispose_of(&mr);
	return InterErrors::quoted(I"no such data type", text, eloc);
}

@<Parse rulebook syntax@> =	
	if (Regexp::match(&mr, text, U"rulebook of (%C+)")) {
		results->constructor_code = RULEBOOK_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse list syntax@> =
	if (Regexp::match(&mr, text, U"list of (%C+)")) {
		results->constructor_code = LIST_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse activity syntax@> =
	if (Regexp::match(&mr, text, U"activity on (%C+)")) {
		results->constructor_code = ACTIVITY_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse column syntax@> =
	if (Regexp::match(&mr, text, U"column of (%C+)")) {
		results->constructor_code = COLUMN_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse table syntax@> =
	if (Regexp::match(&mr, text, U"table of (%C+)")) {
		results->constructor_code = TABLE_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse description syntax@> =
	if (Regexp::match(&mr, text, U"description of (%C+)")) {
		results->constructor_code = DESCRIPTION_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse relation syntax@> =
	if (Regexp::match(&mr, text, U"relation of (%C+) to (%C+)")) {
		results->constructor_code = RELATION_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, X_type);
		if (E == NULL) {
			inter_type Y_type = InterTypes::parse_simple(T, eloc, mr.exp[1], &E);
			InterTypes::add_operand_to_isstd(results, T, Y_type);
		} else {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::unchecked());
		}
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse rule or function syntax@> =
	if ((Regexp::match(&mr, text, U"(function) (%c+?) -> (%c+)")) ||
		(Regexp::match(&mr, text, U"(rule) (%c+?) -> (%c+)"))) {
		if (Str::eq(mr.exp[0], I"function")) results->constructor_code = FUNCTION_ITCONC;
		else results->constructor_code = RULE_ITCONC;
		text_stream *from = mr.exp[1];
		text_stream *to = mr.exp[2];
		inter_error_message *returned_E = NULL;
		if (Str::eq(from, I"void")) {
			InterTypes::add_operand_to_isstd(results, T,
				InterTypes::from_constructor_code(VOID_ITCONC));
		} else {
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, from, U" *(%C+) *(%c*)")) {
				inter_type arg_type = InterTypes::parse_simple(T, eloc, mr3.exp[0], &E);
				InterTypes::add_operand_to_isstd(results, T, arg_type);
				if ((E) && (returned_E == NULL)) returned_E = E;
				Str::copy(from, mr3.exp[1]);
			}
		}
		if (Str::eq(to, I"void")) {
			InterTypes::add_operand_to_isstd(results, T,
				InterTypes::from_constructor_code(VOID_ITCONC));
		} else {
			inter_type res_type = InterTypes::parse_simple(T, eloc, to, &E);
			if ((E) && (returned_E == NULL)) returned_E = E;
			InterTypes::add_operand_to_isstd(results, T, res_type);
		}
		Regexp::dispose_of(&mr);
		return returned_E;
	}

@<Parse struct syntax@> =
	if (Regexp::match(&mr, text, U"struct (%c+)")) {
		results->constructor_code = STRUCT_ITCONC;
		text_stream *elements = mr.exp[0];
		inter_error_message *returned_E = NULL;
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, elements, U" *(%C+) *(%c*)")) {
			inter_type arg_type = InterTypes::parse_simple(T, eloc, mr3.exp[0], &E);
			if ((E) && (returned_E == NULL)) returned_E = E;
			Str::copy(elements, mr3.exp[1]);
			InterTypes::add_operand_to_isstd(results, T, arg_type);
		}
		Regexp::dispose_of(&mr);
		return returned_E;
	}

@<Parse generic unary or binary syntax@> =
	if (Regexp::match(&mr, text, U"unary-cov (%C+)")) {
		results->constructor_code = UNARY_COV_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}
	if (Regexp::match(&mr, text, U"unary-con (%C+)")) {
		results->constructor_code = UNARY_CON_ITCONC;
		inter_type conts_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, conts_type);
		Regexp::dispose_of(&mr);
		return E;
	}
	if (Regexp::match(&mr, text, U"binary-cov-cov (%C+) and (%C+)")) {
		results->constructor_code = BINARY_COV_COV_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, X_type);
		if (E == NULL) {
			inter_type Y_type = InterTypes::parse_simple(T, eloc, mr.exp[1], &E);
			InterTypes::add_operand_to_isstd(results, T, Y_type);
		} else {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::unchecked());
		}
		Regexp::dispose_of(&mr);
		return E;
	}
	if (Regexp::match(&mr, text, U"binary-cov-con (%C+) and (%C+)")) {
		results->constructor_code = BINARY_COV_CON_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, X_type);
		if (E == NULL) {
			inter_type Y_type = InterTypes::parse_simple(T, eloc, mr.exp[1], &E);
			InterTypes::add_operand_to_isstd(results, T, Y_type);
		} else {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::unchecked());
		}
		Regexp::dispose_of(&mr);
		return E;
	}
	if (Regexp::match(&mr, text, U"binary-con-cov (%C+) and (%C+)")) {
		results->constructor_code = BINARY_CON_COV_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, X_type);
		if (E == NULL) {
			inter_type Y_type = InterTypes::parse_simple(T, eloc, mr.exp[1], &E);
			InterTypes::add_operand_to_isstd(results, T, Y_type);
		} else {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::unchecked());
		}
		Regexp::dispose_of(&mr);
		return E;
	}
	if (Regexp::match(&mr, text, U"binary-con-con (%C+) and (%C+)")) {
		results->constructor_code = BINARY_CON_CON_ITCONC;
		inter_type X_type = InterTypes::parse_simple(T, eloc, mr.exp[0], &E);
		InterTypes::add_operand_to_isstd(results, T, X_type);
		if (E == NULL) {
			inter_type Y_type = InterTypes::parse_simple(T, eloc, mr.exp[1], &E);
			InterTypes::add_operand_to_isstd(results, T, Y_type);
		} else {
			InterTypes::add_operand_to_isstd(results, T, InterTypes::unchecked());
		}
		Regexp::dispose_of(&mr);
		return E;
	}

@<Parse bare constructor-name syntax@> =
	inter_type_constructor *itc = InterTypes::constructor_from_name(text);
	if (itc) {
		results->constructor_code = itc->constructor_ID;
		if (itc->constructor_ID == VOID_ITCONC)
			return InterErrors::quoted(I"'void' cannot be used as a type", text, eloc);
		Regexp::dispose_of(&mr);
		return NULL;
	}

@<Parse bare typename syntax@> =
	inter_symbol *typename_s = NULL;
	if (Str::get_first_char(text) == '/') {
		typename_s = InterSymbolsTable::wire_to_URL(
			InterPackage::tree(InterSymbolsTable::package(T)), text, T);
		if (typename_s == NULL)
			return InterErrors::quoted(I"no typename at this URL", text, eloc);
	} else {
		typename_s = TextualInter::find_symbol_in_table(T, eloc, text, TYPENAME_IST, &E);
	}
	if (typename_s) {
		results->constructor_code = EQUATED_ITCONC;
		InterTypes::add_operand_to_isstd(results, T, InterTypes::from_type_name(typename_s));
		Regexp::dispose_of(&mr);
		return NULL;
	}
	if (E) {
		Regexp::dispose_of(&mr);
		return E;
	}

@ Sometimes we want to allow only a simple type, and if so then we can return
an //inter_type//, which is less fuss. But we still write this as a wrapper
around the full //InterTypes::parse_semisimple// so that it can produce a
useful error message in response to a semisimple but not simple piece of syntax.

=
inter_type InterTypes::parse_simple(inter_symbols_table *T, inter_error_location *eloc,
	text_stream *text, inter_error_message **E) {
	if (Str::len(text) > 0) {
		inter_semisimple_type_description parsed_description;
		InterTypes::initialise_isstd(&parsed_description);
		*E = InterTypes::parse_semisimple(text, T, eloc, &parsed_description);
		if (*E) return InterTypes::unchecked();
		if (parsed_description.constructor_code == EQUATED_ITCONC) {
			inter_type type = InterTypes::from_TID(T, parsed_description.operand_TIDs[0]);
			InterTypes::dispose_of_isstd(&parsed_description);
			return type;
		}
		int over_complex = FALSE;
		for (int i=0; i<parsed_description.arity; i++)
			if (parsed_description.operand_TIDs[i] != UNCHECKED_ITCONC)
				over_complex = TRUE;
		if (over_complex)  {
			InterTypes::dispose_of_isstd(&parsed_description);
			*E = InterErrors::quoted(I"type too complex", text, eloc);
			return InterTypes::unchecked();
		}
		inter_type type = InterTypes::from_constructor_code(parsed_description.constructor_code);
		InterTypes::dispose_of_isstd(&parsed_description);
		return type;
	}
	return InterTypes::unchecked();
}

@h Writing to text.
We offer two functions here so that it's possible to force a typename to print
its full definition out: otherwise printing the typename |K_whatever| would
just print that name, |K_whatever|.

=
void InterTypes::write_type(OUTPUT_STREAM, inter_type type) {
	if (type.type_name) {
		InterSymbolsTable::write_symbol_URL(OUT, type.type_name);
	} else {
		InterTypes::write_type_longhand(OUT, type);
	}
}

void InterTypes::write_typename_definition(OUTPUT_STREAM, inter_symbol *type_name) {
	InterTypes::write_type_longhand(OUT, InterTypes::from_type_name(type_name));
}

@ Both of which use this:

=
void InterTypes::write_type_longhand(OUTPUT_STREAM, inter_type type) {
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
		case ACTIVITY_ITCONC:
			WRITE(" on ");
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
		case UNARY_COV_ITCONC:
		case UNARY_CON_ITCONC:
			InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
			break;
		case BINARY_COV_COV_ITCONC:
		case BINARY_CON_COV_ITCONC:
		case BINARY_COV_CON_ITCONC:
		case BINARY_CON_CON_ITCONC:
			InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
			WRITE(" and ");
			InterTypes::write_type(OUT, InterTypes::type_operand(type, 0));
			break;
	}
}

@h Typechecking.
These are easy enough:

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


int InterTypes::unsigned_literal_is_in_range(long long int N, inter_type type) {
	inter_type_constructor *itc = InterTypes::constructor(type);
	if ((N < 0) || (N > itc->max_value - itc->min_value)) return FALSE;
	return TRUE;
}

@ This is what matters: whether we allow a value of type |A| to be used where
a value of type |B| is expected.

Anything can be used as |unchecked|, and |unchecked| can be used as anything.

Otherwise, they must both be base types, or both constructed: and then we
split into four cases as to whether they are the same or different.

=
inter_error_message *InterTypes::can_be_used_as(inter_type A, inter_type B,
	text_stream *S, inter_error_location *eloc) {
	inter_type_constructor *A_itc = InterTypes::constructor(A);
	inter_type_constructor *B_itc = InterTypes::constructor(B);

	if ((A_itc->constructor_ID == UNCHECKED_ITCONC) ||
		(B_itc->constructor_ID == UNCHECKED_ITCONC))
		return NULL;

	if (A_itc->is_base != B_itc->is_base) @<Throw type mismatch error@>;

	if (A_itc->is_base) {
		if (A_itc->constructor_ID != B_itc->constructor_ID) @<Different base@>
		else @<Same base@>;
	} else {
		if (A_itc->constructor_ID != B_itc->constructor_ID) @<Different proper constructor@>
		else @<Same proper constructor@>;
	}
}

@ This expresses that |int2 <= int8 <= int16 <= int32|.

@<Different base@> =
	switch (A_itc->constructor_ID) {
		case INT2_ITCONC:
			if ((B_itc->constructor_ID == INT8_ITCONC) ||
				(B_itc->constructor_ID == INT16_ITCONC) ||
				(B_itc->constructor_ID == INT32_ITCONC)) return NULL;
			break;
		case INT8_ITCONC:
			if ((B_itc->constructor_ID == INT16_ITCONC) ||
				(B_itc->constructor_ID == INT32_ITCONC)) return NULL;
			break;
		case INT16_ITCONC:
			if (B_itc->constructor_ID == INT32_ITCONC) return NULL;
			break;		
	}
	@<Throw type mismatch error@>;

@ Enumerated types, if named, can be declared as subtypes of each other. This
is used by Inform to make the enumerated type for "vehicle" a subtype of the
enumerated type for "thing", for example.

@<Same base@> =
	if (A_itc->constructor_ID == ENUM_ITCONC) {
		inter_symbol *typenameB_s = B.type_name;
		inter_symbol *typenameA_s = A.type_name;
		if ((typenameB_s) && (typenameA_s) &&
			(TypenameInstruction::is_a(typenameA_s, typenameB_s) == FALSE))
			@<Throw type mismatch error@>;
	}
	return NULL;

@ Different proper constructors never match.

@<Different proper constructor@> =
	@<Throw type mismatch error@>;

@ If the same proper constructor is used, the question is then whether the
operands match. For example, |list of int2| can be used as |list of int32|
but not vice versa: that's a covariant operand. But |function int2 -> text|
cannot be used as |function int32 -> text|, it's the other way around: that
is an example of contravariance. In the simple type system of Inter, only
function arguments are contravariant.

@<Same proper constructor@> =
	inter_error_message *operand_E = NULL;
	switch (A_itc->constructor_ID) {
		case STRUCT_ITCONC:
		case FUNCTION_ITCONC:
		case UNARY_COV_ITCONC:
		case UNARY_CON_ITCONC:
		case BINARY_COV_COV_ITCONC:
		case BINARY_COV_CON_ITCONC:
		case BINARY_CON_COV_ITCONC:
		case BINARY_CON_CON_ITCONC: {			
			inter_symbol *typename_A = A.type_name;
			inter_symbol *typename_B = B.type_name;
			if ((typename_A) && (typename_B)) {
				if (InterTypes::type_arity(A) != InterTypes::type_arity(B))
					@<Throw type mismatch error@>;
				int arity = InterTypes::type_arity(A);
				for (int i=0; i<arity; i++) {
					int covariant = TRUE;
					if ((A_itc->constructor_ID == FUNCTION_ITCONC) && (i<arity-1))
						covariant = FALSE;
					if (A_itc->constructor_ID == UNARY_CON_ITCONC)
						covariant = FALSE;
					if ((A_itc->constructor_ID == BINARY_CON_COV_ITCONC) && (i == 0))
						covariant = FALSE;
					if ((A_itc->constructor_ID == BINARY_COV_CON_ITCONC) && (i == 1))
						covariant = FALSE;
					if (A_itc->constructor_ID == BINARY_CON_CON_ITCONC)
						covariant = FALSE;
					if (covariant)
						operand_E = InterTypes::can_be_used_as(InterTypes::type_operand(A, i),
							InterTypes::type_operand(B, i), S, eloc);
					else
						operand_E = InterTypes::can_be_used_as(InterTypes::type_operand(B, i),
							InterTypes::type_operand(A, i), S, eloc);
					if (operand_E) @<Throw type mismatch error@>;
				}
			}
			break;
		}
		default:
			for (int i=0; i<A_itc->arity; i++) {
				operand_E = InterTypes::can_be_used_as(InterTypes::type_operand(A, i),
					InterTypes::type_operand(B, i), S, eloc);
				if (operand_E) @<Throw type mismatch error@>;
			}
			break;
	}
	return NULL;

@<Throw type mismatch error@> =
	text_stream *err = Str::new();
	WRITE_TO(err, "value '%S' has type ", S);
	InterTypes::write_type(err, A);
	WRITE_TO(err, " which is not a ");
	InterTypes::write_type(err, B);
	return InterErrors::plain(err, eloc);

@h The type of a defined symbol.
Note that a typename can be used as a value, and that if so, its type is |unchecked|.

=
inter_type InterTypes::of_symbol(inter_symbol *symb) {
	if (symb == NULL) return InterTypes::unchecked();
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) return InterTypes::unchecked();
	if (InterSymbol::defined_elsewhere(symb)) return InterTypes::unchecked();
	inter_construct *IC = NULL;
	if (InterInstruction::get_construct(D, &IC)) return InterTypes::unchecked();
	if (IC->TID_field >= 0) return InterTypes::from_TID_in_field(D, IC->TID_field);
	return InterTypes::unchecked();
}

int InterTypes::expresses_value(inter_symbol *symb) {
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D) {
		inter_construct *IC = NULL;
		if (InterInstruction::get_construct(D, &IC)) return FALSE;
		if (IC->construct_ID == TYPENAME_IST) return TRUE;
		if (IC->TID_field >= 0) return TRUE;
	}
	return FALSE;
}
