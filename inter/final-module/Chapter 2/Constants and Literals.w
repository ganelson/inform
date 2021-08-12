[CodeGen::CL::] Constants and Literals.

To generate final code for constants, including arrays.

@

=
int the_quartet_found = FALSE;
int box_mode = FALSE, printing_mode = FALSE;

void CodeGen::CL::prepare(code_generation *gen) {
	the_quartet_found = FALSE;
	box_mode = FALSE; printing_mode = FALSE;
	InterTree::traverse(gen->from, CodeGen::CL::quartet_visitor, NULL, NULL, CONSTANT_IST);
}

void CodeGen::CL::quartet_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_symbol *con_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	if ((Str::eq(con_name->symbol_name, I"thedark")) ||
		(Str::eq(con_name->symbol_name, I"InformLibrary")) ||
		(Str::eq(con_name->symbol_name, I"InformParser")) ||
		(Str::eq(con_name->symbol_name, I"Compass")))
		the_quartet_found = TRUE;
}

int CodeGen::CL::quartet_present(void) {
	return the_quartet_found;
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
void CodeGen::CL::constant(code_generation *gen, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	inter_symbol *con_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);

	if (Inter::Symbols::read_annotation(con_name, INLINE_ARRAY_IANN) == 1) return;
	if (Inter::Symbols::read_annotation(con_name, ACTION_IANN) == 1) return;

	if (Inter::Symbols::read_annotation(con_name, FAKE_ACTION_IANN) == 1) {
		text_stream *fa = Str::duplicate(con_name->symbol_name);
		Str::delete_first_character(fa);
		Str::delete_first_character(fa);
		CodeGen::Targets::new_fake_action(gen, fa);
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

	if (Inter::Symbols::read_annotation(con_name, OBJECT_IANN) > 0) return;
	
	if (Str::eq(con_name->symbol_name, I"Release")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Release ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Story")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Global Story = ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"Serial")) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
		WRITE("Serial ");
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), val1, val2, FALSE);
		WRITE(";\n");
		return;
	}

	if (Str::eq(con_name->symbol_name, I"UUID_ARRAY")) {
		inter_ti ID = P->W.data[DATA_CONST_IFLD];
		text_stream *S = Inode::ID_to_text(P, ID);
		CodeGen::Targets::begin_array(gen, I"UUID_ARRAY", BYTE_ARRAY_FORMAT);
		TEMPORARY_TEXT(content)
		WRITE_TO(content, "UUID://");
		for (int i=0, L=Str::len(S); i<L; i++) WRITE_TO(content, "%c", Characters::toupper(Str::get_at(S, i)));
		WRITE_TO(content, "//");
		TEMPORARY_TEXT(length)
		WRITE_TO(length, "%d", (int) Str::len(content));
		CodeGen::Targets::array_entry(gen, length, BYTE_ARRAY_FORMAT);
		DISCARD_TEXT(length)
		LOOP_THROUGH_TEXT(pos, content) {
			TEMPORARY_TEXT(ch)
			WRITE_TO(ch, "'%c'", Str::get(pos));
			CodeGen::Targets::array_entry(gen, ch, BYTE_ARRAY_FORMAT);
			DISCARD_TEXT(ch)
		}
		DISCARD_TEXT(content)
		CodeGen::Targets::end_array(gen, BYTE_ARRAY_FORMAT);
		return;
	}

	if (Inter::Constant::is_routine(con_name)) {
		inter_package *code_block = Inter::Constant::code_block(con_name);
		CodeGen::Targets::begin_function(2, gen, con_name);
		void_level = Inter::Defn::get_level(P) + 2;
		inter_tree_node *D = Inter::Packages::definition(code_block);
		CodeGen::FC::frame(gen, D);
		CodeGen::Targets::end_function(2, gen, con_name);
		return;
	}
	switch (P->W.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_INDIRECT_TEXT: {
			inter_ti ID = P->W.data[DATA_CONST_IFLD];
			text_stream *S = Inode::ID_to_text(P, ID);
			CodeGen::Targets::begin_constant(gen, CodeGen::CL::name(con_name), TRUE, FALSE);
			WRITE("\"%S\"", S);
			CodeGen::Targets::end_constant(gen, CodeGen::CL::name(con_name), FALSE);
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
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) {
				WRITE("Verb "); do_not_bracket = TRUE; unsub = TRUE;
				if (Inter::Symbols::read_annotation(con_name, METAVERB_IANN) == 1) WRITE("meta ");
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					WRITE(" ");
					CodeGen::CL::literal(gen, con_name, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], unsub);
				}
				WRITE(";");
			} else {
				CodeGen::Targets::begin_array(gen, CodeGen::CL::name(con_name), format);
				if (hang_one) CodeGen::Targets::array_entry(gen, I"1", format);
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					if (P->W.data[i] != DIVIDER_IVAL) {
						TEMPORARY_TEXT(entry)
						CodeGen::select_temporary(gen, entry);
	//					if ((do_not_bracket == FALSE) && (P->W.data[i] != DIVIDER_IVAL)) WRITE("(");
						CodeGen::CL::literal(gen, con_name, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], unsub);
	//					if ((do_not_bracket == FALSE) && (P->W.data[i] != DIVIDER_IVAL)) WRITE(")");
						CodeGen::deselect_temporary(gen);
						CodeGen::Targets::array_entry(gen, entry, format);
						DISCARD_TEXT(entry)
					}
				}
				CodeGen::Targets::end_array(gen, format);
			}
			WRITE("\n");
			break;
		}
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST: {
			int depth = CodeGen::CL::constant_depth(con_name);
			if (depth > 1) {
				LOGIF(CONSTANT_DEPTH_CALCULATION,
					"Con %S has depth %d\n", con_name->symbol_name, depth);
				CodeGen::CL::constant_depth(con_name);
			}
			generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::basic_constant_segment(gen, depth));
			text_stream *OUT = CodeGen::current(gen);
			CodeGen::Targets::begin_constant(gen, CodeGen::CL::name(con_name), TRUE, FALSE);
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
				CodeGen::CL::literal(gen, con_name, Inter::Packages::scope_of(P), P->W.data[i], P->W.data[i+1], FALSE);
				if (bracket) WRITE(")");
			}
			CodeGen::Targets::end_constant(gen, CodeGen::CL::name(con_name), FALSE);
			CodeGen::deselect(gen, saved);
			break;
		}
		case CONSTANT_DIRECT: {
			int depth = CodeGen::CL::constant_depth(con_name);
			if (depth > 1) LOGIF(CONSTANT_DEPTH_CALCULATION,
				"Con %S has depth %d\n", con_name->symbol_name, depth);
			generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::basic_constant_segment(gen, depth));
			CodeGen::Targets::begin_constant(gen, CodeGen::CL::name(con_name), TRUE, ifndef_me);
			inter_ti val1 = P->W.data[DATA_CONST_IFLD];
			inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
			CodeGen::CL::literal(gen, con_name, Inter::Packages::scope_of(P), val1, val2, FALSE);
			CodeGen::Targets::end_constant(gen, CodeGen::CL::name(con_name), ifndef_me);
			CodeGen::deselect(gen, saved);
			break;
		}
		default: internal_error("ungenerated constant format");
	}
}

int CodeGen::CL::constant_depth(inter_symbol *con) {
	LOG_INDENT;
	int d = CodeGen::CL::constant_depth_inner(con);
	LOGIF(CONSTANT_DEPTH_CALCULATION, "%S has depth %d\n", con->symbol_name, d);
	LOG_OUTDENT;
	return d;
}
int CodeGen::CL::constant_depth_inner(inter_symbol *con) {
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
			return CodeGen::CL::constant_depth(alias) + 1;
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
				total += CodeGen::CL::constant_depth(alias);
			} else total++;
		}
		return 1 + total;
	}
	return 1;
}

typedef struct text_literal_holder {
	struct text_stream *definition_code;
	struct text_stream *literal_content;
	CLASS_DEFINITION
} text_literal_holder;

text_stream *CodeGen::CL::literal_text_at(code_generation *gen, text_stream *S) {
	text_literal_holder *tlh = CREATE(text_literal_holder);
	tlh->definition_code = Str::new();
	tlh->literal_content = S;
	return tlh->definition_code;
}

int CodeGen::CL::compare_tlh(const void *elem1, const void *elem2) {
	const text_literal_holder **e1 = (const text_literal_holder **) elem1;
	const text_literal_holder **e2 = (const text_literal_holder **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting text literals");
	text_stream *s1 = (*e1)->literal_content;
	text_stream *s2 = (*e2)->literal_content;
	return Str::cmp(s1, s2);
}

void CodeGen::CL::sort_literals(code_generation *gen) {
	int no_tlh = NUMBER_CREATED(text_literal_holder);
	text_literal_holder **sorted = (text_literal_holder **)
			(Memory::calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
	int i = 0;
	text_literal_holder *tlh;
	LOOP_OVER(tlh, text_literal_holder) sorted[i++] = tlh;

	qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *), CodeGen::CL::compare_tlh);
	for (int i=0; i<no_tlh; i++) {
		text_literal_holder *tlh = sorted[i];
		generated_segment *saved = CodeGen::select(gen, CodeGen::Targets::tl_segment(gen));
		text_stream *TO = CodeGen::current(gen);
		WRITE_TO(TO, "%S", tlh->definition_code);
		CodeGen::deselect(gen, saved);
	}
}

void CodeGen::CL::enter_box_mode(void) {
	box_mode = TRUE;
}

void CodeGen::CL::exit_box_mode(void) {
	box_mode = FALSE;
}

void CodeGen::CL::enter_print_mode(void) {
	printing_mode = TRUE;
}

void CodeGen::CL::exit_print_mode(void) {
	printing_mode = FALSE;
}

void CodeGen::CL::literal(code_generation *gen, inter_symbol *con_name, inter_symbols_table *T, inter_ti val1, inter_ti val2, int unsub) {
	inter_tree *I = gen->from;
	text_stream *OUT = CodeGen::current(gen);
	if (val1 == LITERAL_IVAL) {
		int hex = FALSE;
		if ((con_name) && (Inter::Annotations::find(&(con_name->ann_set), HEX_IANN))) hex = TRUE;
		CodeGen::Targets::compile_literal_number(gen, val2, hex);
	} else if (Inter::Symbols::is_stored_in_data(val1, val2)) {
		inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, T);
		if (aliased == NULL) internal_error("bad aliased symbol");
		if (aliased == verb_directive_divider_symbol) WRITE("\n\t*");
		else if (aliased == verb_directive_reverse_symbol) WRITE("reverse");
		else if (aliased == verb_directive_slash_symbol) WRITE("/");
		else if (aliased == verb_directive_result_symbol) WRITE("->");
		else if (aliased == verb_directive_special_symbol) WRITE("special");
		else if (aliased == verb_directive_number_symbol) WRITE("number");
		else if (aliased == verb_directive_noun_symbol) WRITE("noun");
		else if (aliased == verb_directive_multi_symbol) WRITE("multi");
		else if (aliased == verb_directive_multiinside_symbol) WRITE("multiinside");
		else if (aliased == verb_directive_multiheld_symbol) WRITE("multiheld");
		else if (aliased == verb_directive_held_symbol) WRITE("held");
		else if (aliased == verb_directive_creature_symbol) WRITE("creature");
		else if (aliased == verb_directive_topic_symbol) WRITE("topic");
		else if (aliased == verb_directive_multiexcept_symbol) WRITE("multiexcept");
		else {
			if ((unsub) && (Inter::Symbols::read_annotation(aliased, SCOPE_FILTER_IANN) == 1))
				WRITE("scope=");
			if ((unsub) && (Inter::Symbols::read_annotation(aliased, NOUN_FILTER_IANN) == 1))
				WRITE("noun=");
			text_stream *S = CodeGen::CL::name(aliased);
			if ((unsub) && (Str::begins_with_wide_string(S, L"##"))) {
				LOOP_THROUGH_TEXT(pos, S)
					if (pos.index >= 2)
						PUT(Str::get(pos));
			} else {
				CodeGen::Targets::mangle(gen, OUT, S);
			}
		}
	} else if (val1 == DIVIDER_IVAL) {
		text_stream *divider_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		WRITE(" ! %S\n\t", divider_text);
	} else if (val1 == REAL_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		WRITE("$%S", glob_text);
	} else if (val1 == DWORD_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		CodeGen::Targets::compile_dictionary_word(gen, glob_text, FALSE);
	} else if (val1 == PDWORD_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		CodeGen::Targets::compile_dictionary_word(gen, glob_text, TRUE);
	} else if (val1 == LITERAL_TEXT_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		CodeGen::Targets::compile_literal_text(gen, glob_text, printing_mode, box_mode);
	} else if (val1 == GLOB_IVAL) {
		text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
		WRITE("%S", glob_text);
	} else internal_error("unimplemented direct constant");
}

text_stream *CodeGen::CL::name(inter_symbol *symb) {
	if (symb == NULL) return NULL;
	if (Inter::Symbols::get_translate(symb)) return Inter::Symbols::get_translate(symb);
	return symb->symbol_name;
}

@ =
int CodeGen::CL::node_is_ref_to(inter_tree *I, inter_tree_node *P, inter_ti seek_bip) {
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
