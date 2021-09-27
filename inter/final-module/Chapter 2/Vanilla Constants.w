[VanillaConstants::] Vanilla Constants.

How the vanilla code generation strategy handles constants, including literal
texts, lists, and arrays.

@

=
void VanillaConstants::constant(code_generation *gen, inter_tree_node *P) {
	inter_symbol *con_name =
		InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	if (con_name == NULL) internal_error("no constant");
	if (con_name->metadata_key == FALSE) {
		if (Inter::Symbols::read_annotation(con_name, ACTION_IANN) == 1)  {
			@<Declare this constant as an action name@>;
		} else if (Inter::Symbols::read_annotation(con_name, FAKE_ACTION_IANN) == 1) {
			@<Declare this constant as a fake action name@>;
		} else if (Inter::Symbols::read_annotation(con_name, VENEER_IANN) > 0) {
			;
		} else if (Inter::Symbols::read_annotation(con_name, OBJECT_IANN) > 0) {
			@<Declare this constant as a pseudo-object@>;
		} else if (Inter::Constant::is_routine(con_name)) {
			@<Declare this constant as a function@>;
		} else if (Str::eq(con_name->symbol_name, I"UUID_ARRAY")) {
			@<Declare this constant as the special UUID string array@>;
		} else switch (P->W.data[FORMAT_CONST_IFLD]) {
			case CONSTANT_INDIRECT_TEXT: @<Declare this as a textual constant@>; break;
			case CONSTANT_INDIRECT_LIST: @<Declare this as a list constant@>; break;
			case CONSTANT_SUM_LIST:
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST: @<Declare this as a computed constant@>; break;
			case CONSTANT_DIRECT: @<Declare this as an explicit constant@>; break;
			default: internal_error("ungenerated constant format");
		}
	}
}

@<Declare this constant as an action name@> =
	text_stream *fa = Str::duplicate(con_name->symbol_name);
	Str::delete_first_character(fa);
	Str::delete_first_character(fa);
	Generators::new_action(gen, fa, TRUE);

@<Declare this constant as a fake action name@> =
	text_stream *fa = Str::duplicate(con_name->symbol_name);
	Str::delete_first_character(fa);
	Str::delete_first_character(fa);
	Generators::new_action(gen, fa, FALSE);

@<Declare this constant as a pseudo-object@> =
	Generators::pseudo_object(gen, Inter::Symbols::name(con_name));

@<Declare this constant as a function@> =
	inter_package *code_block = Inter::Constant::code_block(con_name);
	inter_tree_node *D = Inter::Packages::definition(code_block);
	Generators::declare_function(gen, con_name, D);

@<Declare this constant as the special UUID string array@> =
	inter_ti ID = P->W.data[DATA_CONST_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	segmentation_pos saved;
	Generators::begin_array(gen, I"UUID_ARRAY", NULL, NULL, BYTE_ARRAY_FORMAT, &saved);
	TEMPORARY_TEXT(content)
	WRITE_TO(content, "UUID://");
	for (int i=0, L=Str::len(S); i<L; i++)
		WRITE_TO(content, "%c", Characters::toupper(Str::get_at(S, i)));
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
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, &saved);

@<Declare this as a textual constant@> =
	inter_ti ID = P->W.data[DATA_CONST_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	VanillaConstants::literal_text_at(gen, S, con_name);

@<Declare this as a list constant@> =
	int format = WORD_ARRAY_FORMAT, hang_one = FALSE;
	int do_not_bracket = FALSE;
	int X = (P->W.extent - DATA_CONST_IFLD)/2;
	if (X == 1) do_not_bracket = TRUE;
	if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) format = BYTE_ARRAY_FORMAT;
	if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) {
		format = TABLE_ARRAY_FORMAT;
		if (P->W.extent - DATA_CONST_IFLD == 2) { format = WORD_ARRAY_FORMAT; hang_one = TRUE; }
	}
	if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1)
		format = BUFFER_ARRAY_FORMAT;
	segmentation_pos saved;
	if (Generators::begin_array(gen, Inter::Symbols::name(con_name), con_name, P, format, &saved)) {
		if (hang_one) Generators::array_entry(gen, I"1", format);
		int entry_count = 0;
		for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2)
			if (P->W.data[i] != DIVIDER_IVAL)
				entry_count++;
		if (hang_one) entry_count++;
		inter_ti e = 0; int ips = FALSE;
		if ((entry_count == 1) && (Inter::Symbols::read_annotation(con_name, ASSIMILATED_IANN) >= 0)) {
			inter_ti val1 = P->W.data[DATA_CONST_IFLD], val2 = P->W.data[DATA_CONST_IFLD+1];
			e = Inter::Constant::evaluate(Inter::Packages::scope_of(P), val1, val2, &ips);
		}
		if (e > 1) {
			LOG("Entry count 1 on %S masks %d blanks\n", Inter::Symbols::name(con_name), e);
			Generators::array_entries(gen, (int) e, ips, format);
		} else {
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				if (P->W.data[i] != DIVIDER_IVAL) {
					TEMPORARY_TEXT(entry)
					CodeGen::select_temporary(gen, entry);
					CodeGen::pair(gen, P, P->W.data[i], P->W.data[i+1]);
					CodeGen::deselect_temporary(gen);
					Generators::array_entry(gen, entry, format);
					DISCARD_TEXT(entry)
				}
			}
		}
		Generators::end_array(gen, format, &saved);
	}

@<Declare this as a computed constant@> =
	Generators::declare_constant(gen, Inter::Symbols::name(con_name), con_name, COMPUTED_GDCFORM, P, NULL, FALSE);

@<Declare this as an explicit constant@> =
	int ifndef_me = FALSE;
	if ((Str::eq(con_name->symbol_name, I"WORDSIZE")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_ZCODE")) ||
		(Str::eq(con_name->symbol_name, I"INDIV_PROP_START")) ||
		(Str::eq(con_name->symbol_name, I"TARGET_GLULX")) ||
		(Str::eq(con_name->symbol_name, I"DICT_WORD_SIZE")) ||
		(Str::eq(con_name->symbol_name, I"DEBUG")) ||
		(Str::eq(con_name->symbol_name, I"cap_short_name")))
		ifndef_me = TRUE;
	Generators::declare_constant(gen, Inter::Symbols::name(con_name), con_name, DATA_GDCFORM, P, NULL, ifndef_me);

@

=
void VanillaConstants::definition_value(code_generation *gen, int form, inter_tree_node *P,
	inter_symbol *con_name, text_stream *val) {
	text_stream *OUT = CodeGen::current(gen);
	switch (form) {
		case RAW_GDCFORM:
			if (Str::len(val) > 0) {
				WRITE("%S", val);
			} else {
				Generators::compile_literal_number(gen, 1, FALSE);
			}
			break;
		case DATA_GDCFORM: {
			inter_ti val1 = P->W.data[DATA_CONST_IFLD];
			inter_ti val2 = P->W.data[DATA_CONST_IFLD + 1];
			if ((val1 == LITERAL_IVAL) && (Inter::Symbols::read_annotation(con_name, HEX_IANN)))
				Generators::compile_literal_number(gen, val2, TRUE);
			else
				CodeGen::pair(gen, P, val1, val2);
			break;
		}
		case COMPUTED_GDCFORM: {
			WRITE("(");
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				if (i>DATA_CONST_IFLD) {
					if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) WRITE(" + ");
					if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) WRITE(" * ");
					if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) WRITE(" - ");
					if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) WRITE(" / ");
				}
				int bracket = TRUE;
				if ((P->W.data[i] == LITERAL_IVAL) ||
					(Inter::Symbols::is_stored_in_data(P->W.data[i], P->W.data[i+1]))) bracket = FALSE;
				if (bracket) WRITE("(");
				CodeGen::pair(gen, P, P->W.data[i], P->W.data[i+1]);
				if (bracket) WRITE(")");
			}
			WRITE(")");
			break;
		}
		case LITERAL_TEXT_GDCFORM:
			Generators::compile_literal_text(gen, val, FALSE);
			break;
	}
}

@h Text literals.

=
typedef struct text_literal_holder {
	struct text_stream *literal_content;
	struct inter_symbol *con_name;
	CLASS_DEFINITION
} text_literal_holder;

void VanillaConstants::literal_text_at(code_generation *gen, text_stream *S,
	inter_symbol *con_name) {
	text_literal_holder *tlh = CREATE(text_literal_holder);
	tlh->literal_content = S;
	tlh->con_name = con_name;
	ADD_TO_LINKED_LIST(tlh, text_literal_holder, gen->text_literals);
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
	int no_tlh = LinkedLists::len(gen->text_literals);
	if (no_tlh > 0) {
		text_literal_holder **sorted = (text_literal_holder **)
			(Memory::calloc(no_tlh, sizeof(text_literal_holder *), CODE_GENERATION_MREASON));
		int i = 0;
		text_literal_holder *tlh;
		LOOP_OVER_LINKED_LIST(tlh, text_literal_holder, gen->text_literals)
			sorted[i++] = tlh;
		qsort(sorted, (size_t) no_tlh, sizeof(text_literal_holder *), VanillaConstants::compare_tlh);
		for (int i=0; i<no_tlh; i++) {
			text_literal_holder *tlh = sorted[i];
			Generators::declare_constant(gen, Inter::Symbols::name(tlh->con_name), tlh->con_name, LITERAL_TEXT_GDCFORM, tlh->con_name->definition, tlh->literal_content, FALSE);
		}
	}
}
