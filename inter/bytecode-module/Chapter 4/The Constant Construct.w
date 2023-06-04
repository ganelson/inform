[ConstantInstruction::] The Constant Construct.

Defining the constant construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void ConstantInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CONSTANT_IST, I"constant");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_CONST_IFLD, TYPE_CONST_IFLD);
	InterInstruction::specify_syntax(IC, I"constant MINTOKENS = TOKENS");
	InterInstruction::data_extent_at_least(IC, 3);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ConstantInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, ConstantInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, ConstantInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ConstantInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |comment| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by these fields. Note
that the data then occupies a varying number of further data pairs, depending on
the value of |FORMAT_CONST_IFLD|. As a result, the length of a |constant|
instruction can be any odd number of words from 5 upwards.

The simplest version, though, has a single value. The length is then 7 words.

@d DEFN_CONST_IFLD   (DATA_IFLD + 0)
@d TYPE_CONST_IFLD   (DATA_IFLD + 1)
@d FORMAT_CONST_IFLD (DATA_IFLD + 2)
@d DATA_CONST_IFLD   (DATA_IFLD + 3)

=
inter_error_message *ConstantInstruction::new(inter_bookmark *IBM, inter_symbol *S,
	inter_type type, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_5_data_fields(IBM, CONSTANT_IST,
		/* DEFN_CONST_IFLD: */   InterSymbolsTable::id_at_bookmark(IBM, S),
		/* TYPE_CONST_IFLD: */   InterTypes::to_TID_at(IBM, type),
		/* FORMAT_CONST_IFLD: */ CONST_LIST_FORMAT_NONE,
		/* DATA_CONST_IFLD: */   InterValuePairs::to_word1(val),
								 InterValuePairs::to_word2(val),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ All other forms have a flexible number of data pairs. The number of entries
can therefore be calculated as half of (the instruction extent minus |DATA_CONST_IFLD|).

@d CONST_LIST_FORMAT_NONE 0
@d CONST_LIST_FORMAT_WORDS 1
@d CONST_LIST_FORMAT_WORDS_BY_EXTENT 2
@d CONST_LIST_FORMAT_BYTES 3
@d CONST_LIST_FORMAT_BYTES_BY_EXTENT 4
@d CONST_LIST_FORMAT_B_WORDS 5
@d CONST_LIST_FORMAT_B_WORDS_BY_EXTENT 6
@d CONST_LIST_FORMAT_B_BYTES 7
@d CONST_LIST_FORMAT_B_BYTES_BY_EXTENT 8
@d CONST_LIST_FORMAT_GRAMMAR 9
@d CONST_LIST_FORMAT_INLINE 10
@d CONST_LIST_FORMAT_SUM 11
@d CONST_LIST_FORMAT_PRODUCT 12
@d CONST_LIST_FORMAT_DIFFERENCE 13
@d CONST_LIST_FORMAT_QUOTIENT 14
@d CONST_LIST_FORMAT_STRUCT 15

=
int ConstantInstruction::is_a_genuine_list_format(inter_ti format) {
	if ((format >= CONST_LIST_FORMAT_WORDS) &&
		(format <= CONST_LIST_FORMAT_INLINE))
		return TRUE;
	return FALSE;
}

int ConstantInstruction::is_a_byte_format(inter_ti format) {
	if ((format == CONST_LIST_FORMAT_BYTES) ||
		(format == CONST_LIST_FORMAT_BYTES_BY_EXTENT) ||
		(format == CONST_LIST_FORMAT_B_BYTES) ||
		(format == CONST_LIST_FORMAT_B_BYTES_BY_EXTENT))
		return TRUE;
	return FALSE;
}

int ConstantInstruction::is_a_by_extent_format(inter_ti format) {
	if ((format == CONST_LIST_FORMAT_WORDS_BY_EXTENT) ||
		(format == CONST_LIST_FORMAT_BYTES_BY_EXTENT) ||
		(format == CONST_LIST_FORMAT_B_WORDS_BY_EXTENT) ||
		(format == CONST_LIST_FORMAT_B_BYTES_BY_EXTENT))
		return TRUE;
	return FALSE;
}

int ConstantInstruction::is_a_bounded_format(inter_ti format) {
	if ((format >= CONST_LIST_FORMAT_B_WORDS) &&
		(format <= CONST_LIST_FORMAT_B_BYTES_BY_EXTENT))
		return TRUE;
	return FALSE;
}

@ Note that the |type| argument here should be that of the list, not of the entries.

=
inter_error_message *ConstantInstruction::new_list(inter_bookmark *IBM, inter_symbol *S,
	inter_type type, inter_ti format, int no_pairs, inter_pair *val_array, inter_ti level,
	inter_error_location *eloc) {
	if (format == CONST_LIST_FORMAT_NONE) internal_error("not a list");
	inter_tree_node *AP = Inode::new_with_3_data_fields(IBM, CONSTANT_IST,
		/* DEFN_CONST_IFLD: */   InterSymbolsTable::id_at_bookmark(IBM, S),
		/* TYPE_CONST_IFLD: */   InterTypes::to_TID_at(IBM, type),
		/* FORMAT_CONST_IFLD: */ (inter_ti) format,
		eloc, level);
	int pos = AP->W.extent;
	Inode::extend_instruction_by(AP, (inter_ti) (2*no_pairs));
	for (int i=0; i<no_pairs; i++, pos += 2) InterValuePairs::set(AP, pos, val_array[i]);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), AP);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(AP, IBM);
	return NULL;
}

void ConstantInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2)
		InterValuePairs::set(P, i,
			InterValuePairs::transpose(InterValuePairs::get(P, i), grid, grid_extent, E));
}

@ Verification consists only of sanity checks.

=
void ConstantInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	if ((P->W.extent % 2) != 1) {
		*E = Inode::error(P, I"extent not an odd number", NULL); return;
	}
	int data_fields = (P->W.extent - DATA_CONST_IFLD)/2;
	inter_ti format = P->W.instruction[FORMAT_CONST_IFLD];
	if ((format == CONST_LIST_FORMAT_NONE) && (data_fields != 1)) {
		*E = Inode::error(P, I"extent wrong", NULL); return;
	}

	*E = VerifyingInter::TID_field(owner, P, TYPE_CONST_IFLD);
	if (*E) return;
	
	if (format > CONST_LIST_FORMAT_STRUCT) {
		*E = Inode::error(P, I"no such constant format", NULL); return;
	}

	inter_type type = InterTypes::from_TID_in_field(P, TYPE_CONST_IFLD);
	if (format == CONST_LIST_FORMAT_STRUCT) {
		if (data_fields != InterTypes::type_arity(type)) {
			*E = Inode::error(P, I"extent not same as struct length", NULL); return;
		}
		for (int i=DATA_CONST_IFLD, counter = 0; i<P->W.extent; i=i+2) {
			inter_type field_type = InterTypes::type_operand(type, counter++);
			*E = VerifyingInter::data_pair_fields(owner, P, i, field_type);
			if (*E) return;
		}
	} else {
		inter_type verify_type = type;
		if (ConstantInstruction::is_a_genuine_list_format(format))
			verify_type = InterTypes::type_operand(type, 0);
		for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
			*E = VerifyingInter::data_pair_fields(owner, P, i, verify_type);
			if (*E) return;
		}
	}
}

@h Creating from textual Inter syntax.

=
void ConstantInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *name_text = ilp->mr.exp[0], *value_text = ilp->mr.exp[1];

	inter_type con_type;
	inter_symbol *con_name = NULL;
	@<Parse the type and name@>;
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), con_name);

	inter_pair *pairs = NULL;
	text_stream **tokens = NULL;
	inter_ti fmt = CONST_LIST_FORMAT_NONE;
	int capacity = 0, token_count = 0;
	text_stream *S = value_text;
	@<Tokenise the value@>;

	if (S) @<A single-token constant@>
	else @<A list-of-tokens constant@>

	if (token_count > 0) {
		Memory::I7_free(pairs, INTER_SYMBOLS_MREASON, capacity);
		Memory::I7_free(tokens, INTER_SYMBOLS_MREASON, capacity);
	}
}

@<Parse the type and name@> =
	text_stream *type_text = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, name_text, L"%((%c+)%) (%c+)")) {
		type_text = mr.exp[0];
		name_text = mr.exp[1];
	}
	con_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, type_text, E);
	if (*E == NULL)
		con_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, E);
	Regexp::dispose_of(&mr);

@<Tokenise the value@> =
	match_results mr2 = Regexp::create_mr();
	if (Regexp::match(&mr2, S, L"sum{ *(%c*?) *}")) fmt = CONST_LIST_FORMAT_SUM;
	else if (Regexp::match(&mr2, S, L"product{ *(%c*) *}")) fmt = CONST_LIST_FORMAT_PRODUCT;
	else if (Regexp::match(&mr2, S, L"difference{ *(%c*) *}")) fmt = CONST_LIST_FORMAT_DIFFERENCE;
	else if (Regexp::match(&mr2, S, L"quotient{ *(%c*) *}")) fmt = CONST_LIST_FORMAT_QUOTIENT;
	else if (Regexp::match(&mr2, S, L"grammar{ *(%c*) *}")) fmt = CONST_LIST_FORMAT_GRAMMAR;
	else if (Regexp::match(&mr2, S, L"inline{ *(%c*) *}")) fmt = CONST_LIST_FORMAT_INLINE;
	else if (Regexp::match(&mr2, S, L"{ *(%c*?) *}")) fmt = CONST_LIST_FORMAT_WORDS;
	else if (Regexp::match(&mr2, S, L"bytes{ *(%c*?) *}")) fmt = CONST_LIST_FORMAT_BYTES;
	else if (Regexp::match(&mr2, S, L"list of *(%c*?) bytes")) fmt = CONST_LIST_FORMAT_BYTES_BY_EXTENT;
	else if (Regexp::match(&mr2, S, L"list of *(%c*?) words")) fmt = CONST_LIST_FORMAT_WORDS_BY_EXTENT;
	else if (Regexp::match(&mr2, S, L"bounded { *(%c*?) *}")) fmt = CONST_LIST_FORMAT_B_WORDS;
	else if (Regexp::match(&mr2, S, L"bounded bytes{ *(%c*?) *}")) fmt = CONST_LIST_FORMAT_B_BYTES;
	else if (Regexp::match(&mr2, S, L"bounded list of *(%c*?) bytes")) fmt = CONST_LIST_FORMAT_B_BYTES_BY_EXTENT;
	else if (Regexp::match(&mr2, S, L"bounded list of *(%c*?) words")) fmt = CONST_LIST_FORMAT_B_WORDS_BY_EXTENT;
	else if (Regexp::match(&mr2, S, L"struct{ *(%c*?) *}")) fmt = CONST_LIST_FORMAT_STRUCT;
	if (fmt != CONST_LIST_FORMAT_NONE) {
		S = NULL;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c+?), *(%c+)")) {
			@<Add a token@>;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c+?) *")) @<Add a token@>;
		Regexp::dispose_of(&mr3);
	}

@<Add a token@> =
	if (token_count >= capacity) {
		int new_size = 16;
		while (token_count >= new_size) new_size = new_size * 4;
		inter_pair *enlarged_pairs = (inter_pair *)
			Memory::calloc(new_size, sizeof(inter_pair), INTER_SYMBOLS_MREASON);
		text_stream **enlarged_tokens = (text_stream **)
			Memory::calloc(new_size, sizeof(text_stream *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<new_size; i++)
			if (i < capacity) {
				enlarged_pairs[i] = pairs[i];
				enlarged_tokens[i] = tokens[i];
			} else {
				enlarged_pairs[i] = InterValuePairs::undef();
				enlarged_tokens[i] = NULL;
			}
		if (capacity > 0) {
			Memory::I7_free(pairs, INTER_SYMBOLS_MREASON, capacity);
			Memory::I7_free(tokens, INTER_SYMBOLS_MREASON, capacity);
		}
		capacity = new_size;
		pairs = enlarged_pairs;
		tokens = enlarged_tokens;
	}
	pairs[token_count] = InterValuePairs::undef();
	tokens[token_count++] = Str::duplicate(mr3.exp[0]);

@<A single-token constant@> =
	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, con_type, S, &val);
	if (*E == NULL)
		*E = ConstantInstruction::new(IBM, con_name, con_type, val,
			(inter_ti) ilp->indent_level, eloc);

@<A list-of-tokens constant@> =
	for (int i=0; i<token_count; i++) {
		inter_type term_type = con_type;
		if (ConstantInstruction::is_a_genuine_list_format(fmt))
			term_type = InterTypes::type_operand(con_type, 0);
		if (fmt == CONST_LIST_FORMAT_STRUCT)
			term_type = InterTypes::type_operand(con_type, i);
		*E = TextualInter::parse_pair(ilp->line, eloc, IBM, term_type, tokens[i], &(pairs[i]));
		if (*E) break;
	}
	if (*E == NULL)
		*E = ConstantInstruction::new_list(IBM, con_name, con_type, fmt, token_count, pairs,
			(inter_ti) ilp->indent_level, eloc);

@h Writing to textual Inter syntax.

=
void ConstantInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *con_name = ConstantInstruction::symbol(P);
	WRITE("constant ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_CONST_IFLD);
	WRITE("%S = ", InterSymbol::identifier(con_name));
	inter_ti fmt = P->W.instruction[FORMAT_CONST_IFLD];
	switch (fmt) {
		case CONST_LIST_FORMAT_SUM:               WRITE("sum"); break;
		case CONST_LIST_FORMAT_PRODUCT:           WRITE("product"); break;
		case CONST_LIST_FORMAT_DIFFERENCE:        WRITE("difference"); break;
		case CONST_LIST_FORMAT_QUOTIENT:          WRITE("quotient"); break;
		case CONST_LIST_FORMAT_GRAMMAR:           WRITE("grammar"); break;
		case CONST_LIST_FORMAT_INLINE:            WRITE("inline"); break;
		case CONST_LIST_FORMAT_STRUCT:            WRITE("struct"); break;
		case CONST_LIST_FORMAT_BYTES:             WRITE("bytes"); break;
		case CONST_LIST_FORMAT_WORDS_BY_EXTENT:   WRITE("list of "); break;
		case CONST_LIST_FORMAT_BYTES_BY_EXTENT:   WRITE("list of "); break;
		case CONST_LIST_FORMAT_B_WORDS:           WRITE("bounded "); break;
		case CONST_LIST_FORMAT_B_BYTES:           WRITE("bounded bytes"); break;
		case CONST_LIST_FORMAT_B_WORDS_BY_EXTENT: WRITE("bounded list of "); break;
		case CONST_LIST_FORMAT_B_BYTES_BY_EXTENT: WRITE("bounded list of "); break;
	}
	int braced = FALSE;
	if ((fmt != CONST_LIST_FORMAT_NONE) &&
		(ConstantInstruction::is_a_by_extent_format(fmt) == FALSE)) braced = TRUE;
	if (braced) WRITE("{");
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
		if (i > DATA_CONST_IFLD) WRITE(",");
		if (braced) WRITE(" ");
		TextualInter::write_pair(OUT, P, InterValuePairs::get(P, i));
	}
	if (braced) WRITE(" }");
	if (ConstantInstruction::is_a_by_extent_format(fmt)) {
		if (ConstantInstruction::is_a_byte_format(fmt)) WRITE(" bytes");
		else WRITE(" words");
	}
}

@h Access functions.

=
inter_symbol *ConstantInstruction::symbol(inter_tree_node *P) {
	if (Inode::is(P, CONSTANT_IST))
		return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_CONST_IFLD);
	return NULL;
}

inter_ti ConstantInstruction::list_format(inter_tree_node *P) {
	if (Inode::is(P, CONSTANT_IST))
		return P->W.instruction[FORMAT_CONST_IFLD];
	return CONST_LIST_FORMAT_NONE;
}

inter_pair ConstantInstruction::constant(inter_tree_node *P) {
	if ((Inode::is(P, CONSTANT_IST)) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE))
		return InterValuePairs::get(P, DATA_CONST_IFLD);
	return InterValuePairs::undef();
}

void ConstantInstruction::set_constant(inter_tree_node *P, inter_pair val) {
	if ((Inode::is(P, CONSTANT_IST)) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE))
		InterValuePairs::set(P, DATA_CONST_IFLD, val);
	else internal_error("tried to set value for non-constant");
}

void ConstantInstruction::set_type(inter_tree_node *P, inter_type type) {
	P->W.instruction[TYPE_CONST_IFLD] =
		InterTypes::to_TID(InterPackage::scope(Inode::get_package(P)), type);
}

int ConstantInstruction::list_len(inter_tree_node *P) {
	if ((P == NULL) || (Inode::isnt(P, CONSTANT_IST)) ||
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE))
		return 0;
	return (P->W.extent - DATA_CONST_IFLD)/2;
}

inter_pair ConstantInstruction::list_entry(inter_tree_node *P, int i) {
	if ((P == NULL) || (Inode::isnt(P, CONSTANT_IST)) ||
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE))
		return InterValuePairs::undef();
	int field = DATA_CONST_IFLD + i*2;
	if (field >= P->W.extent) InterValuePairs::undef();
	return InterValuePairs::get(P, field);
}

int ConstantInstruction::is_inline(inter_symbol *const_s) {
	if ((const_s) && (const_s->definition) &&
		(ConstantInstruction::list_format(const_s->definition) ==
			CONST_LIST_FORMAT_INLINE))
		return TRUE;
	return FALSE;
}

@h Definitional depth of a constant.
Constants given explicit values have depth 1. Constants defined as equal to
other constants have depth 1 more than those other constants. Constants equal
to lists have depth 1 more than the sum of the depths of the values in the
lists. For example, if:
= (text as Inter)
	constant x = 23
	constant y = x
	constant z = { x, y, 17 }
=
then |x| has depth 1, |y| has depth 1+1 = 2, and |z| has depth 1+(1+2+1) = 5.
It is a requirement that every constant must always have finite depth. The
point of this is to guarantee that if constant declarations are written in
ascending order of depth then no definition will refer to a constant yet to
be defined.

=
int ConstantInstruction::constant_depth(inter_symbol *con) {
	if (con == NULL) return 1;
	LOG_INDENT;
	int d = ConstantInstruction::constant_depth_r(con);
	LOGIF(CONSTANT_DEPTH_CALCULATION, "%S has depth %d\n", InterSymbol::identifier(con), d);
	LOG_OUTDENT;
	return d;
}
int ConstantInstruction::constant_depth_r(inter_symbol *con) {
	int total = 1;
	inter_tree_node *D = InterSymbol::definition(con);
	if ((Inode::is(D, CONSTANT_IST)))
		for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
			inter_pair val = InterValuePairs::get(D, i);
			if (InterValuePairs::is_symbolic(val)) {
				inter_symbol *alias = InterValuePairs::to_symbol_at(val, D);
				total += ConstantInstruction::constant_depth(alias);
			} else total++;
		}
	return total;
}

@h Direct evaluation.
Some numerical constants can be evaluated at compile-time: for example, given
= (text as Inter)
	constant x = 23
	constant y = x + 3
=
the following function would return 23 and 26 on |x| and |y| respectively. On
anything non-numerical the function aims to return 0, but this should probably
not be relied on.

=
int ConstantInstruction::evaluate_to_int(inter_symbol *S) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((Inode::is(P, CONSTANT_IST)) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE)) {
		inter_pair val = InterValuePairs::get(P, DATA_CONST_IFLD);
		if (InterValuePairs::is_number(val))
			return (int) InterValuePairs::to_number(val);
		if (InterValuePairs::is_symbolic(val)) {
			inter_symbols_table *scope = S->owning_table;
			inter_symbol *alias_to = InterValuePairs::to_symbol(val, scope);
			return InterSymbol::evaluate_to_int(alias_to);
		}
	}
	return -1;
}

inter_ti ConstantInstruction::evaluate(inter_symbols_table *T, inter_pair val) {
	if (InterValuePairs::is_number(val)) return InterValuePairs::to_number(val);
	if (InterValuePairs::is_symbolic(val)) {
		inter_symbol *aliased = InterValuePairs::to_symbol(val, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		inter_tree_node *D = aliased->definition;
		if (D == NULL) internal_error("undefined symbol");
		inter_ti fmt = D->W.instruction[FORMAT_CONST_IFLD];
		switch (fmt) {
			case CONST_LIST_FORMAT_NONE: {
				inter_pair dval = ConstantInstruction::constant(D);
				inter_ti e = ConstantInstruction::evaluate(InterPackage::scope_of(D), dval);
				return e;
			}
			case CONST_LIST_FORMAT_SUM:
			case CONST_LIST_FORMAT_PRODUCT:
			case CONST_LIST_FORMAT_DIFFERENCE:
			case CONST_LIST_FORMAT_QUOTIENT: {
				inter_ti result = 0;
				for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
					inter_pair operand = InterValuePairs::get(D, i);
					inter_ti extra =
						ConstantInstruction::evaluate(InterPackage::scope_of(D), operand);
					if (i == DATA_CONST_IFLD) result = extra;
					else {
						if (fmt == CONST_LIST_FORMAT_SUM) result = result + extra;
						if (fmt == CONST_LIST_FORMAT_PRODUCT) result = result * extra;
						if (fmt == CONST_LIST_FORMAT_DIFFERENCE) result = result - extra;
						if (fmt == CONST_LIST_FORMAT_QUOTIENT) result = result / extra;
					}
				}
				return result;
			}
		}
	}
	return 0;
}

@h Direct modification.
We can even change the value of a numerical constant.

=
int ConstantInstruction::set_int(inter_symbol *S, int N) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((Inode::is(P, CONSTANT_IST)) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE)) {
		inter_pair val = InterValuePairs::get(P, DATA_CONST_IFLD);
		if (InterValuePairs::is_number(val)) {
			ConstantInstruction::set_constant(P, InterValuePairs::number((inter_ti) N));
			return TRUE;
		}
		if (InterValuePairs::is_symbolic(val)) {
			inter_symbols_table *scope = S->owning_table;
			inter_symbol *alias_to = InterValuePairs::to_symbol(val, scope);
			InterSymbol::set_int(alias_to, N);
			return TRUE;
		}
	}
	return FALSE;
}
