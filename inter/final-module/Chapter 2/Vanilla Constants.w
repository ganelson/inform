[VanillaConstants::] Vanilla Constants.

How the vanilla code generation strategy handles constants, including literal
texts, lists, and arrays.

@

=
void VanillaConstants::constant(code_generation *gen, inter_tree_node *P) {
	inter_symbol *con_name =
		InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	if (con_name == NULL) internal_error("no constant");
	if (con_name->metadata_key) return;
	inter_tree *I = gen->from;
	if (Inter::Packages::container(P) == Site::main_package_if_it_exists(I)) {
		WRITE_TO(STDERR, "Bad constant: %S\n", con_name->symbol_name);
		internal_error("constant defined in main");
	}
	if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
		inter_ti ID = P->W.data[DATA_CONST_IFLD];
		text_stream *S = VanillaConstants::literal_text_at(gen,
			Inode::ID_to_text(P, ID));
		CodeGen::select_temporary(gen, S);
		VanillaConstants::constant_inner(gen, P);
		CodeGen::deselect_temporary(gen);
	} else {
		VanillaConstants::constant_inner(gen, P);
	}
}

void VanillaConstants::prepare(code_generation *gen) {
}

@ There's a contrivance here to get around an awkward point of I6 syntax:
an array written in the form
= (text as Inform 6)
	Array X table 20;
=
makes a table with 20 entries, not a table with one entry whose initial value
is 20. We instead compile this as
= (text as Inform 6)
	Array X --> 1 20;
=

=
void VanillaConstants::constant_inner(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_symbol *con_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);

	if (Inter::Symbols::read_annotation(con_name, ACTION_IANN) == 1)  {
		text_stream *fa = Str::duplicate(con_name->symbol_name);
		Str::delete_first_character(fa);
		Str::delete_first_character(fa);
		Generators::new_action(gen, fa, TRUE);
		return;
	}

	if (Inter::Symbols::read_annotation(con_name, FAKE_ACTION_IANN) == 1) {
		text_stream *fa = Str::duplicate(con_name->symbol_name);
		Str::delete_first_character(fa);
		Str::delete_first_character(fa);
		Generators::new_action(gen, fa, FALSE);
		return;
	}

	int ifndef_me = FALSE;
	if (Inter::Symbols::read_annotation(con_name, VENEER_IANN) > 0) return;
	if ((Str::eq(con_name->symbol_name, I"WORDSIZE")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_ZCODE")) ||
		(Str::eq(con_name->symbol_name, I"INDIV_PROP_START")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_GLULX")) ||
		(Str::eq(con_name->symbol_name, I"DICT_WORD_SIZE")) ||
		(Str::eq(con_name->symbol_name, I"DEBUG")) ||
		(Str::eq(con_name->symbol_name, I"cap_short_name")))
		ifndef_me = TRUE;

	if (Inter::Symbols::read_annotation(con_name, OBJECT_IANN) > 0) {
		return;
	}
	
	if (Str::eq(con_name->symbol_name, I"UUID_ARRAY")) {
		inter_ti ID = P->W.data[DATA_CONST_IFLD];
		text_stream *S = Inode::ID_to_text(P, ID);
		Generators::begin_array(gen, I"UUID_ARRAY", NULL, NULL, BYTE_ARRAY_FORMAT);
		TEMPORARY_TEXT(content)
		WRITE_TO(content, "UUID://");
		for (int i=0, L=Str::len(S); i<L; i++) WRITE_TO(content, "%c", Characters::toupper(Str::get_at(S, i)));
		WRITE_TO(content, "//");
		TEMPORARY_TEXT(length)
		WRITE_TO(length, "%d", (int) Str::len(content));
		Generators::array_entry(gen, length, BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(length)
		LOOP_THROUGH_TEXT(pos, content) {
			TEMPORARY_TEXT(ch)
			WRITE_TO(ch, "'%c'", Str::get(pos));
			Generators::array_entry(gen, ch, BYTE_ARRAY_FORMAT);
			DISCARD_TEXT(ch)
		}
		DISCARD_TEXT(content)
		Generators::end_array(gen, BYTE_ARRAY_FORMAT);
		return;
	}

	if (Inter::Constant::is_routine(con_name)) {
		inter_package *code_block = Inter::Constant::code_block(con_name);
		inter_tree_node *D = Inter::Packages::definition(code_block);
		Generators::declare_function(gen, con_name, D);
		return;
	}
	switch (P->W.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_INDIRECT_TEXT: {
			inter_ti ID = P->W.data[DATA_CONST_IFLD];
			text_stream *S = Inode::ID_to_text(P, ID);
			if (Generators::begin_constant(gen, CodeGen::name(con_name), con_name, P, TRUE, FALSE)) {
				Generators::compile_literal_text(gen, S, FALSE, FALSE, FALSE);
				Generators::end_constant(gen, CodeGen::name(con_name), FALSE);
			}
			break;
		}
		case CONSTANT_INDIRECT_LIST: {
			int format = WORD_ARRAY_FORMAT, hang_one = FALSE;
			int do_not_bracket = FALSE, unsub = FALSE;
			int X = (P->W.extent - DATA_CONST_IFLD)/2;
			if (X == 1) do_not_bracket = TRUE;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) format = BYTE_ARRAY_FORMAT;
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) {
				format = TABLE_ARRAY_FORMAT;
				if (P->W.extent - DATA_CONST_IFLD == 2) { format = WORD_ARRAY_FORMAT; hang_one = TRUE; }
			}
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1)
				format = BUFFER_ARRAY_FORMAT;
			if (Generators::begin_array(gen, CodeGen::name(con_name), con_name, P, format)) {
				if (hang_one) Generators::array_entry(gen, I"1", format);
				int entry_count = 0;
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2)
					if (P->W.data[i] != DIVIDER_IVAL)
						entry_count++;
				if (hang_one) entry_count++;
				inter_ti e = 0; int ips = FALSE;
				if ((entry_count == 1) && (Inter::Symbols::read_annotation(con_name, ASSIMILATED_IANN) >= 0)) {
					inter_ti val1 = P->W.data[DATA_CONST_IFLD], val2 = P->W.data[DATA_CONST_IFLD+1];
					e = VanillaConstants::evaluate(gen, Inter::Packages::scope_of(P), val1, val2, &ips);
				}
				if (e > 1) {
					LOG("Entry count 1 on %S masks %d blanks\n", CodeGen::name(con_name), e);
					Generators::array_entries(gen, (int) e, ips, format);
				} else {
					for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
						if (P->W.data[i] != DIVIDER_IVAL) {
							TEMPORARY_TEXT(entry)
							CodeGen::select_temporary(gen, entry);
							VanillaConstants::literal(gen, con_name, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], unsub);
							CodeGen::deselect_temporary(gen);
							Generators::array_entry(gen, entry, format);
							DISCARD_TEXT(entry)
						}
					}
				}
				Generators::end_array(gen, format);
			}
			WRITE("\n");
			break;
		}
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST: {
			int depth = VanillaConstants::constant_depth(con_name);
			if (depth > 1) {
				LOGIF(CONSTANT_DEPTH_CALCULATION,
					"Con %S has depth %d\n", con_name->symbol_name, depth);
				VanillaConstants::constant_depth(con_name);
			}
			generated_segment *saved = CodeGen::select(gen, Generators::basic_constant_segment(gen, con_name, depth));
			text_stream *OUT = CodeGen::current(gen);
			if (Generators::begin_constant(gen, CodeGen::name(con_name), con_name, P, TRUE, FALSE)) {
				WRITE("(");
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					if (i>DATA_CONST_IFLD) {
						if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) WRITE(" + ");
						if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) WRITE(" * ");
						if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) WRITE(" - ");
						if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) WRITE(" / ");
					}
					int bracket = TRUE;
					if ((P->W.data[i] == LITERAL_IVAL) || (Inter::Symbols::is_stored_in_data(P->W.data[i], P->W.data[i+1]))) bracket = FALSE;
					if (bracket) WRITE("(");
					VanillaConstants::literal(gen, con_name, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], FALSE);
					if (bracket) WRITE(")");
				}
				WRITE(")");
				Generators::end_constant(gen, CodeGen::name(con_name), FALSE);
			}
			CodeGen::deselect(gen, saved);
			break;
		}
		case CONSTANT_DIRECT: {
			int depth = VanillaConstants::constant_depth(con_name);
			if (depth > 1) LOGIF(CONSTANT_DEPTH_CALCULATION,
				"Con %S has depth %d\n", con_name->symbol_name, depth);
			generated_segment *saved = CodeGen::select(gen, Generators::basic_constant_segment(gen, con_name, depth));
			if (Generators::begin_constant(gen, CodeGen::name(con_name), con_name, P, TRUE, ifndef_me)) {
				inter_ti val1 = P->W.data[DATA_CONST_IFLD];
				inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
				VanillaConstants::literal(gen, con_name, Inter::Packages::scope_of(P), val1, val2, FALSE);
				Generators::end_constant(gen, CodeGen::name(con_name), ifndef_me);
			}
			CodeGen::deselect(gen, saved);
			break;
		}
		default: internal_error("ungenerated constant format");
	}
}

int VanillaConstants::constant_depth(inter_symbol *con) {
	LOG_INDENT;
	int d = VanillaConstants::constant_depth_inner(con);
	LOGIF(CONSTANT_DEPTH_CALCULATION, "%S has depth %d\n", con->symbol_name, d);
	LOG_OUTDENT;
	return d;
}
int VanillaConstants::constant_depth_inner(inter_symbol *con) {
	if (con == NULL) return 1;
	inter_tree_node *D = Inter::Symbols::definition(con);
	if (D->W.data[ID_IFLD] != CONSTANT_IST) return 1;
	if (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) {
		inter_ti val1 = D->W.data[DATA_CONST_IFLD];
		inter_ti val2 = D->W.data[DATA_CONST_IFLD + 1];
		if (val1 == ALIAS_IVAL) {
			inter_symbol *alias =
				InterSymbolsTables::symbol_from_data_pair_and_table(
					val1, val2, Inter::Packages::scope(D->package));
			return VanillaConstants::constant_depth(alias) + 1;
		}
		return 1;
	}
	if ((D->W.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) ||
		(D->W.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) ||
		(D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) ||
		(D->W.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST)) {
		int total = 0;
		for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
			inter_ti val1 = D->W.data[i];
			inter_ti val2 = D->W.data[i + 1];
			if (val1 == ALIAS_IVAL) {
				inter_symbol *alias =
					InterSymbolsTables::symbol_from_data_pair_and_table(
						val1, val2, Inter::Packages::scope(D->package));
				total += VanillaConstants::constant_depth(alias);
			} else total++;
		}
		return 1 + total;
	}
	return 1;
}

void VanillaConstants::val_to_text(code_generation *gen, inter_bookmark *IBM, inter_ti val1, inter_ti val2) {
	text_stream *OUT = CodeGen::current(gen);
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *symb = InterSymbolsTables::symbol_from_data_pair_and_table(
			val1, val2, Inter::Bookmarks::scope(IBM));
		if (symb == NULL) internal_error("bad symbol");
		Generators::mangle(gen, OUT, CodeGen::name(symb));
	} else {
		switch (val1) {
			case UNDEF_IVAL:
				internal_error("value undefined");
			case LITERAL_IVAL:
			case LITERAL_TEXT_IVAL:
			case GLOB_IVAL:
			case DWORD_IVAL:
			case REAL_IVAL:
			case PDWORD_IVAL:
				VanillaConstants::literal(gen, NULL, NULL, val1, val2, FALSE);
				break;
		}
	}
}

typedef struct text_literal_holder {
	struct text_stream *definition_code;
	struct text_stream *literal_content;
	CLASS_DEFINITION
} text_literal_holder;

text_stream *VanillaConstants::literal_text_at(code_generation *gen, text_stream *S) {
	text_literal_holder *tlh = CREATE(text_literal_holder);
	tlh->definition_code = Str::new();
	tlh->literal_content = S;
	return tlh->definition_code;
}

int VanillaConstants::compare_tlh(const void *elem1, const void *elem2) {
	const text_literal_holder **e1 = (const text_literal_holder **) elem1;
	const text_literal_holder **e2 = (const text_literal_holder **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting text literals");
	text_stream *s1 = (*e1)->literal_content;
	text_stream *s2 = (*e2)->literal_content;
	return Str::cmp(s1, s2);
}

void VanillaConstants::consolidate(code_generation *gen) {
	int no_tlh = NUMBER_CREATED(text_literal_holder);
	text_literal_holder **sorted = (text_literal_holder **)
			(Memory::calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
	int i = 0;
	text_literal_holder *tlh;
	LOOP_OVER(tlh, text_literal_holder) sorted[i++] = tlh;

	qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *), VanillaConstants::compare_tlh);
	for (int i=0; i<no_tlh; i++) {
		text_literal_holder *tlh = sorted[i];
		generated_segment *saved = CodeGen::select(gen, Generators::tl_segment(gen));
		text_stream *TO = CodeGen::current(gen);
		WRITE_TO(TO, "%S", tlh->definition_code);
		CodeGen::deselect(gen, saved);
	}
}

void VanillaConstants::enter_box_mode(code_generation *gen) {
	gen->literal_text_mode = 1;
}

void VanillaConstants::exit_box_mode(code_generation *gen) {
	gen->literal_text_mode = 0;
}

void VanillaConstants::enter_print_mode(code_generation *gen) {
	gen->literal_text_mode = 2;
}

void VanillaConstants::exit_print_mode(code_generation *gen) {
	gen->literal_text_mode = 0;
}

inter_ti VanillaConstants::evaluate(code_generation *gen, inter_symbols_table *T, inter_ti val1, inter_ti val2, int *ips) {
	if (val1 == LITERAL_IVAL) return val2;
	if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		inter_tree_node *D = aliased->definition;
		if (D == NULL) internal_error("undefined symbol");
		switch (D->W.data[FORMAT_CONST_IFLD]) {
			case CONSTANT_DIRECT: {
				inter_ti dval1 = D->W.data[DATA_CONST_IFLD];
				inter_ti dval2 = D->W.data[DATA_CONST_IFLD + 1];
				inter_ti e = VanillaConstants::evaluate(gen, Inter::Packages::scope_of(D), dval1, dval2, ips);
				if (e == 0) {
					text_stream *S = CodeGen::name(aliased);
					if (Str::eq(S, I"INDIV_PROP_START")) *ips = TRUE;
				}
				LOG("Eval const $3 = %d\n", aliased, e);
				return e;
			}
			case CONSTANT_SUM_LIST:
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST: {
				inter_ti result = 0;
				for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
					inter_ti extra = VanillaConstants::evaluate(gen, Inter::Packages::scope_of(D), D->W.data[i], D->W.data[i+1], ips);
					if (i == DATA_CONST_IFLD) result = extra;
					else {
						if (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) result = result + extra;
						if (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) result = result * extra;
						if (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) result = result - extra;
						if (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) result = result / extra;
					}
				}
				return result;
			}
		}
	}
	return 0;
}

void VanillaConstants::nonliteral(code_generation *gen, inter_symbol *con_name) {
	text_stream *OUT = CodeGen::current(gen);
	Generators::mangle(gen, OUT, CodeGen::name(con_name));
}

void VanillaConstants::literal(code_generation *gen, inter_symbol *con_name, inter_symbols_table *T, inter_ti val1, inter_ti val2, int unsub) {
	inter_tree *I = gen->from;
	text_stream *OUT = CodeGen::current(gen);
	if (val1 == LITERAL_IVAL) {
		int hex = FALSE;
		if ((con_name) && (Inter::Annotations::find(&(con_name->ann_set), HEX_IANN))) hex = TRUE;
		Generators::compile_literal_number(gen, val2, hex);
	} else if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		Generators::compile_literal_symbol(gen, aliased, unsub);
	} else if (val1 == DIVIDER_IVAL) {
		text_stream *divider_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		WRITE(" ! %S\n\t", divider_text);
	} else if (val1 == REAL_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		Generators::compile_literal_real(gen, glob_text);
	} else if (val1 == DWORD_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		Generators::compile_dictionary_word(gen, glob_text, FALSE);
	} else if (val1 == PDWORD_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		Generators::compile_dictionary_word(gen, glob_text, TRUE);
	} else if (val1 == LITERAL_TEXT_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		Generators::compile_literal_text(gen, glob_text, (gen->literal_text_mode == 2)?TRUE:FALSE,
			(gen->literal_text_mode == 1)?TRUE:FALSE, TRUE);
	} else if (val1 == GLOB_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		WRITE("%S", glob_text);
	} else internal_error("unimplemented direct constant");
}

@ =
int VanillaConstants::node_is_ref_to(inter_tree *I, inter_tree_node *P, inter_ti seek_bip) {
	int reffed = FALSE;
	while (P->W.data[ID_IFLD] == REFERENCE_IST) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (P->W.data[ID_IFLD] == INV_IST) {
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(P);
			inter_ti bip = Primitives::to_bip(I, prim);
			if ((bip == seek_bip) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}
