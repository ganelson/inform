[ConstantInstruction::] The Constant Construct.

Defining the constant construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void ConstantInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(CONSTANT_IST, I"constant");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_CONST_IFLD, TYPE_CONST_IFLD);
	InterInstruction::specify_syntax(IC, I"constant TOKENS = TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 5, UNLIMITED_INSTRUCTION_FRAME_LENGTH);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_ANNOTATIONS_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ConstantInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, ConstantInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, ConstantInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ConstantInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |comment| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by these fields. Note
that the data then occupies a varying number of further data pairs, depending on
the value of |FORMAT_CONST_IFLD|. As a result, the length of a |constant|
instruction can be any odd number of words from 5 upwards.

The simplest version, though, has a single value. The length is then 7 words.

@d DEFN_CONST_IFLD 2
@d TYPE_CONST_IFLD 3
@d FORMAT_CONST_IFLD 4
@d DATA_CONST_IFLD 5

=
inter_error_message *ConstantInstruction::new(inter_bookmark *IBM, inter_symbol *S,
	inter_type type, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_5_data_fields(IBM, CONSTANT_IST,
		/* DEFN_CONST_IFLD: */   InterSymbolsTable::id_from_symbol_at_bookmark(IBM, S),
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

Note that the |type| argument here should be that of the list, not of the entries.

@d CONST_LIST_FORMAT_NONE 0
@d CONST_LIST_FORMAT_COLLECTION 1
@d CONST_LIST_FORMAT_SUM 2
@d CONST_LIST_FORMAT_PRODUCT 3
@d CONST_LIST_FORMAT_DIFFERENCE 4
@d CONST_LIST_FORMAT_QUOTIENT 5
@d CONST_LIST_FORMAT_STRUCT 6

=
inter_error_message *ConstantInstruction::new_list(inter_bookmark *IBM, inter_symbol *S,
	inter_type type, int format, int no_pairs, inter_pair *val_array, inter_ti level,
	inter_error_location *eloc) {
	if (format == CONST_LIST_FORMAT_NONE) internal_error("not a list");
	inter_tree_node *AP = Inode::new_with_3_data_fields(IBM, CONSTANT_IST,
		/* DEFN_CONST_IFLD: */   InterSymbolsTable::id_from_symbol_at_bookmark(IBM, S),
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
	if ((P->W.extent % 2) != 1) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = VerifyingInter::TID_field(owner, P, TYPE_CONST_IFLD);
	if (*E) return;
	inter_type it = InterTypes::from_TID_in_field(P, TYPE_CONST_IFLD);
	switch (P->W.instruction[FORMAT_CONST_IFLD]) {
		case CONST_LIST_FORMAT_NONE:
			if (P->W.extent != DATA_CONST_IFLD + 2) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			*E = VerifyingInter::data_pair_fields(owner, P, DATA_CONST_IFLD, it);
			if (*E) return;
			break;
		case CONST_LIST_FORMAT_SUM:
		case CONST_LIST_FORMAT_PRODUCT:
		case CONST_LIST_FORMAT_DIFFERENCE:
		case CONST_LIST_FORMAT_QUOTIENT:
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				*E = VerifyingInter::data_pair_fields(owner, P, i, it);
				if (*E) return;
			}
			break;
		case CONST_LIST_FORMAT_COLLECTION: {
			inter_type conts_type = InterTypes::type_operand(it, 0);
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				*E = VerifyingInter::data_pair_fields(owner, P, i, conts_type); if (*E) return;
			}
			break;
		}
		case CONST_LIST_FORMAT_STRUCT: {
			int arity = InterTypes::type_arity(it);
			int given = (P->W.extent - DATA_CONST_IFLD)/2;
			if (arity != given) { *E = Inode::error(P, I"extent not same size as struct definition", NULL); return; }
			for (int i=DATA_CONST_IFLD, counter = 0; i<P->W.extent; i=i+2) {
				inter_type conts_type = InterTypes::type_operand(it, counter++);
				*E = VerifyingInter::data_pair_fields(owner, P, i, conts_type); if (*E) return;
			}
			break;
		}
	}
}

@

=
void ConstantInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *kind_text = NULL, *name_text = ilp->mr.exp[0];
	match_results mr3 = Regexp::create_mr();
	if (Regexp::match(&mr3, name_text, L"%((%c+)%) (%c+)")) {
		kind_text = mr3.exp[0];
		name_text = mr3.exp[1];
	}

	inter_type con_type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, kind_text, E);
	if (*E) return;

	inter_symbol *con_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, E);
	if (*E) return;

	SymbolAnnotation::copy_set_to_symbol(&(ilp->set), con_name);

	text_stream *S = ilp->mr.exp[1];

	match_results mr2 = Regexp::create_mr();
	inter_ti op = 0;
	if (Regexp::match(&mr2, S, L"sum{ (%c*) }")) op = CONST_LIST_FORMAT_SUM;
	else if (Regexp::match(&mr2, S, L"product{ (%c*) }")) op = CONST_LIST_FORMAT_PRODUCT;
	else if (Regexp::match(&mr2, S, L"difference{ (%c*) }")) op = CONST_LIST_FORMAT_DIFFERENCE;
	else if (Regexp::match(&mr2, S, L"quotient{ (%c*) }")) op = CONST_LIST_FORMAT_QUOTIENT;
	if (op != 0) {
		inter_tree_node *P =
			Inode::new_with_3_data_fields(IBM, CONSTANT_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_name), InterTypes::to_TID_at(IBM, con_type), op, eloc, (inter_ti) ilp->indent_level);
		*E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
		if (*E) return;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
			if (ConstantInstruction::append(ilp->line, eloc, IBM, con_type, P, mr3.exp[0], E) == FALSE)
				return;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
			if (ConstantInstruction::append(ilp->line, eloc, IBM, con_type, P, mr3.exp[0], E) == FALSE)
				return;
		}
		NodePlacement::move_to_moving_bookmark(P, IBM);
		return;
	}

	if (Regexp::match(&mr2, S, L"{ }")) {
		inter_ti form = CONST_LIST_FORMAT_COLLECTION;
		inter_tree_node *P =
			Inode::new_with_3_data_fields(IBM, CONSTANT_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_name), InterTypes::to_TID_at(IBM, con_type), form, eloc, (inter_ti) ilp->indent_level);
		*E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
		if (*E) return;
		NodePlacement::move_to_moving_bookmark(P, IBM);
		return;
	}

	if (Regexp::match(&mr2, S, L"{ (%c*) }")) {
		inter_type conts_type = InterTypes::type_operand(con_type, 0);
		inter_ti form = CONST_LIST_FORMAT_COLLECTION;
		inter_tree_node *P =
			Inode::new_with_3_data_fields(IBM, CONSTANT_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_name), InterTypes::to_TID_at(IBM, con_type), form, eloc, (inter_ti) ilp->indent_level);
		*E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
		if (*E) return;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
			if (ConstantInstruction::append(ilp->line, eloc, IBM, conts_type, P, mr3.exp[0], E) == FALSE)
				return;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
			if (ConstantInstruction::append(ilp->line, eloc, IBM, conts_type, P, mr3.exp[0], E) == FALSE)
				return;
		}
		NodePlacement::move_to_moving_bookmark(P, IBM);
		return;
	}

	if (Regexp::match(&mr2, S, L"struct{ (%c*) }")) {
		inter_tree_node *P =
			 Inode::new_with_3_data_fields(IBM, CONSTANT_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_name), InterTypes::to_TID_at(IBM, con_type), CONST_LIST_FORMAT_STRUCT, eloc, (inter_ti) ilp->indent_level);
		int arity = InterTypes::type_arity(con_type);
		int counter = 0;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
			inter_type conts_type = InterTypes::type_operand(con_type, counter++);
			if (ConstantInstruction::append(ilp->line, eloc, IBM, conts_type, P, mr3.exp[0], E) == FALSE)
				return;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
			inter_type conts_type = InterTypes::type_operand(con_type, counter++);
			if (ConstantInstruction::append(ilp->line, eloc, IBM, conts_type, P, mr3.exp[0], E) == FALSE)
				return;
		}
		if (counter != arity)
			{ *E = InterErrors::quoted(I"wrong size", S, eloc); return; }
		*E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (*E) return;
		NodePlacement::move_to_moving_bookmark(P, IBM);
		return;
	}

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, con_type, S, &val);
	if (*E) return;

	*E = ConstantInstruction::new(IBM, con_name, con_type, val, (inter_ti) ilp->indent_level, eloc);
}

int ConstantInstruction::append(text_stream *line, inter_error_location *eloc, inter_bookmark *IBM, inter_type conts_type, inter_tree_node *P, text_stream *S, inter_error_message **E) {
	*E = NULL;
	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(line, eloc, IBM, conts_type, S, &val);
	if (*E) return FALSE;
	Inode::extend_instruction_by(P, 2);
	InterValuePairs::set(P, P->W.extent-2, val);
	return TRUE;
}

void ConstantInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *con_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_CONST_IFLD);
	int hex = FALSE;
	if (SymbolAnnotation::get_b(con_name, HEX_IANN)) hex = TRUE;
	if (con_name) {
		WRITE("constant ");
		TextualInter::write_optional_type_marker(OUT, P, TYPE_CONST_IFLD);
		WRITE("%S = ", InterSymbol::identifier(con_name));
		switch (P->W.instruction[FORMAT_CONST_IFLD]) {
			case CONST_LIST_FORMAT_NONE:
				TextualInter::write_pair(OUT, P, InterValuePairs::get(P, DATA_CONST_IFLD), hex);
				break;
			case CONST_LIST_FORMAT_SUM:			
			case CONST_LIST_FORMAT_PRODUCT:
			case CONST_LIST_FORMAT_DIFFERENCE:
			case CONST_LIST_FORMAT_QUOTIENT:
			case CONST_LIST_FORMAT_COLLECTION: {
				if (P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_SUM) WRITE("sum");
				if (P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_PRODUCT) WRITE("product");
				if (P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_DIFFERENCE) WRITE("difference");
				if (P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_QUOTIENT) WRITE("quotient");
				WRITE("{");
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					TextualInter::write_pair(OUT, P, InterValuePairs::get(P, i), hex);
				}
				WRITE(" }");
				break;
			}
			case CONST_LIST_FORMAT_STRUCT: {
				WRITE("struct{");
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					TextualInter::write_pair(OUT, P, InterValuePairs::get(P, i), hex);
				}
				WRITE(" }");
				break;
			}
		}
		SymbolAnnotation::write_annotations(OUT, P, con_name);
	} else {
		*E = Inode::error(P, I"constant can't be written", NULL);
		return;
	}
}

inter_package *ConstantInstruction::code_block(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.instruction[ID_IFLD] != CONSTANT_IST) return NULL;
	if (D->W.instruction[FORMAT_CONST_IFLD] != CONST_LIST_FORMAT_NONE) return NULL;
	inter_pair val = InterValuePairs::get(D, DATA_CONST_IFLD);
	return InterValuePairs::to_package(Inode::tree(D), val);
}

int ConstantInstruction::is_routine(inter_symbol *con_symbol) {
	if (ConstantInstruction::code_block(con_symbol)) return TRUE;
	return FALSE;
}

inter_symbols_table *ConstantInstruction::local_symbols(inter_symbol *con_symbol) {
	return InterPackage::scope(ConstantInstruction::code_block(con_symbol));
}

int ConstantInstruction::char_acceptable(int c) {
	if ((c < 0x20) && (c != 0x09) && (c != 0x0a)) return FALSE;
	return TRUE;
}

int ConstantInstruction::constant_depth(inter_symbol *con) {
	LOG_INDENT;
	int d = ConstantInstruction::constant_depth_r(con);
	LOGIF(CONSTANT_DEPTH_CALCULATION, "%S has depth %d\n", InterSymbol::identifier(con), d);
	LOG_OUTDENT;
	return d;
}
int ConstantInstruction::constant_depth_r(inter_symbol *con) {
	if (con == NULL) return 1;
	inter_tree_node *D = InterSymbol::definition(con);
	if (D->W.instruction[ID_IFLD] != CONSTANT_IST) return 1;
	if (D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE) {
		inter_pair val = InterValuePairs::get(D, DATA_CONST_IFLD);
		if (InterValuePairs::is_symbolic(val)) {
			inter_symbol *alias = InterValuePairs::to_symbol_at(val, D);
			return ConstantInstruction::constant_depth(alias) + 1;
		}
		return 1;
	}
	if ((D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_SUM) ||
		(D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_PRODUCT) ||
		(D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_DIFFERENCE) ||
		(D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_QUOTIENT)) {
		int total = 0;
		for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
			inter_pair val = InterValuePairs::get(D, i);
			if (InterValuePairs::is_symbolic(val)) {
				inter_symbol *alias = InterValuePairs::to_symbol_at(val, D);
				total += ConstantInstruction::constant_depth(alias);
			} else total++;
		}
		return 1 + total;
	}
	return 1;
}

inter_ti ConstantInstruction::evaluate(inter_symbols_table *T, inter_pair val) {
	if (InterValuePairs::is_number(val)) return InterValuePairs::to_number(val);
	if (InterValuePairs::is_symbolic(val)) {
		inter_symbol *aliased = InterValuePairs::to_symbol(val, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		inter_tree_node *D = aliased->definition;
		if (D == NULL) internal_error("undefined symbol");
		switch (D->W.instruction[FORMAT_CONST_IFLD]) {
			case CONST_LIST_FORMAT_NONE: {
				inter_pair dval = InterValuePairs::get(D, DATA_CONST_IFLD);
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
					inter_ti extra = ConstantInstruction::evaluate(InterPackage::scope_of(D), operand);
					if (i == DATA_CONST_IFLD) result = extra;
					else {
						if (D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_SUM) result = result + extra;
						if (D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_PRODUCT) result = result * extra;
						if (D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_DIFFERENCE) result = result - extra;
						if (D->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_QUOTIENT) result = result / extra;
					}
				}
				return result;
			}
		}
	}
	return 0;
}

int ConstantInstruction::evaluate_to_int(inter_symbol *S) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
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

int ConstantInstruction::set_int(inter_symbol *S, int N) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) &&
		(P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(P->W.instruction[FORMAT_CONST_IFLD] == CONST_LIST_FORMAT_NONE)) {
		inter_pair val = InterValuePairs::get(P, DATA_CONST_IFLD);
		if (InterValuePairs::is_number(val)) {
			InterValuePairs::set(P, DATA_CONST_IFLD, InterValuePairs::number((inter_ti) N));
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
