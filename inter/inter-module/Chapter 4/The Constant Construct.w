[Inter::Constant::] The Constant Construct.

Defining the constant construct.

@

@e CONSTANT_IST

=
void Inter::Constant::define(void) {
	Inter::Defn::create_construct(
		CONSTANT_IST,
		L"constant (%C+) (%i+) = (%c+)",
		&Inter::Constant::read,
		NULL,
		&Inter::Constant::verify,
		&Inter::Constant::write,
		NULL,
		NULL,
		NULL,
		NULL,
		&Inter::Constant::show_dependencies,
		I"constant", I"constants");
}

@

@d DEFN_CONST_IFLD 2
@d KIND_CONST_IFLD 3
@d FORMAT_CONST_IFLD 4
@d DATA_CONST_IFLD 5

@d CONSTANT_DIRECT 0
@d CONSTANT_INDIRECT_LIST 1
@d CONSTANT_SUM_LIST 2
@d CONSTANT_PRODUCT_LIST 3
@d CONSTANT_DIFFERENCE_LIST 4
@d CONSTANT_QUOTIENT_LIST 5
@d CONSTANT_INDIRECT_TEXT 6
@d CONSTANT_ROUTINE 7
@d CONSTANT_STRUCT 8

=
inter_error_message *Inter::Constant::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, CONSTANT_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *con_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	for (int i=0; i<ilp->no_annotations; i++)
		Inter::Symbols::annotate(IRS->read_into, con_name, ilp->annotations[i]);

	inter_symbol *con_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[1], KIND_IST, &E);
	if (E) return E;
	text_stream *S = ilp->mr.exp[2];

	inter_data_type *idt = Inter::Kind::data_type(con_kind);
	match_results mr2 = Regexp::create_mr();
	inter_t op = 0;
	if (Regexp::match(&mr2, S, L"sum{ (%c*) }")) op = CONSTANT_SUM_LIST;
	else if (Regexp::match(&mr2, S, L"product{ (%c*) }")) op = CONSTANT_PRODUCT_LIST;
	else if (Regexp::match(&mr2, S, L"difference{ (%c*) }")) op = CONSTANT_DIFFERENCE_LIST;
	else if (Regexp::match(&mr2, S, L"quotient{ (%c*) }")) op = CONSTANT_QUOTIENT_LIST;
	if (op != 0) {
		inter_frame P =
			Inter::Frame::fill_3(IRS, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), op, eloc, (inter_t) ilp->indent_level);
		E = Inter::Defn::verify_construct(P);
		if (E) return E;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
			if (Inter::Constant::append(ilp->line, eloc, IRS, con_kind, &P, mr3.exp[0], &E) == FALSE)
				return E;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
			if (Inter::Constant::append(ilp->line, eloc, IRS, con_kind, &P, mr3.exp[0], &E) == FALSE)
				return E;
		}
		Inter::Frame::insert(P, IRS);
		return NULL;
	}

	if ((idt) && ((idt->type_ID == LIST_IDT) || (idt->type_ID == COLUMN_IDT))) {
		inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
		if (conts_kind) {
			match_results mr2 = Regexp::create_mr();
			inter_t form = 0;
			if (Regexp::match(&mr2, S, L"{ (%c*) }")) form = CONSTANT_INDIRECT_LIST;
			else if (Regexp::match(&mr2, S, L"sum{ (%c*) }")) form = CONSTANT_SUM_LIST;
			else if (Regexp::match(&mr2, S, L"product{ (%c*) }")) form = CONSTANT_PRODUCT_LIST;
			else if (Regexp::match(&mr2, S, L"difference{ (%c*) }")) form = CONSTANT_DIFFERENCE_LIST;
			else if (Regexp::match(&mr2, S, L"quotient{ (%c*) }")) form = CONSTANT_QUOTIENT_LIST;
			if (form != 0) {
				inter_frame P =
					Inter::Frame::fill_3(IRS, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), form, eloc, (inter_t) ilp->indent_level);
				E = Inter::Defn::verify_construct(P);
				if (E) return E;
				text_stream *conts = mr2.exp[0];
				match_results mr3 = Regexp::create_mr();
				while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
					if (Inter::Constant::append(ilp->line, eloc, IRS, conts_kind, &P, mr3.exp[0], &E) == FALSE)
						return E;
					Str::copy(conts, mr3.exp[1]);
				}
				if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
					if (Inter::Constant::append(ilp->line, eloc, IRS, conts_kind, &P, mr3.exp[0], &E) == FALSE)
						return E;
				}
				Inter::Frame::insert(P, IRS);
				return NULL;
			}
		}
	}

	if ((idt) && (idt->type_ID == STRUCT_IDT)) {
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, S, L"{ (%c*) }")) {
			inter_frame P =
				 Inter::Frame::fill_3(IRS, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), CONSTANT_STRUCT, eloc, (inter_t) ilp->indent_level);
			int arity = Inter::Kind::arity(con_kind);
			int counter = 0;
			text_stream *conts = mr2.exp[0];
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
				if (Inter::Constant::append(ilp->line, eloc, IRS, conts_kind, &P, mr3.exp[0], &E) == FALSE)
					return E;
				Str::copy(conts, mr3.exp[1]);
			}
			if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
				if (Inter::Constant::append(ilp->line, eloc, IRS, conts_kind, &P, mr3.exp[0], &E) == FALSE)
					return E;
			}
			if (counter != arity)
				return Inter::Errors::quoted(I"wrong size", S, eloc);
			E = Inter::Defn::verify_construct(P); if (E) return E;
			Inter::Frame::insert(P, IRS);
			return NULL;
		}
	}

	if ((idt) && (idt->type_ID == TABLE_IDT)) {
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, S, L"{ (%c*) }")) {
			inter_frame P =
				Inter::Frame::fill_3(IRS, CONSTANT_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), CONSTANT_INDIRECT_LIST, eloc, (inter_t) ilp->indent_level);
			E = Inter::Defn::verify_construct(P);
			if (E) return E;
			text_stream *conts = mr2.exp[0];
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
				if (Inter::Constant::append(ilp->line, eloc, IRS, NULL, &P, mr3.exp[0], &E) == FALSE)
					return E;
				Str::copy(conts, mr3.exp[1]);
			}
			if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
				if (Inter::Constant::append(ilp->line, eloc, IRS, NULL, &P, mr3.exp[0], &E) == FALSE)
					return E;
			}
			Inter::Frame::insert(P, IRS);
			return NULL;
		}
	}

	if ((idt) && (idt->type_ID == TEXT_IDT)) {
		if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
			TEMPORARY_TEXT(parsed_text);
			E = Inter::Constant::parse_text(parsed_text, S, 1, Str::len(S)-2, eloc);
			inter_t ID = 0;
			if (E == NULL) {
				ID = Inter::create_text(IRS->read_into);
				Str::copy(Inter::get_text(IRS->read_into, ID), parsed_text);
			}
			DISCARD_TEXT(parsed_text);
			if (E) return E;
			return Inter::Constant::new_textual(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), ID, (inter_t) IRS->latest_indent, eloc);
		}
	}

	if ((idt) && (idt->type_ID == ROUTINE_IDT)) {
		inter_symbol *block_name = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), S, PACKAGE_IST, &E);
		if (E) return E;
		return Inter::Constant::new_function(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, block_name), (inter_t) IRS->latest_indent, eloc);
	}

	inter_t con_val1 = 0;
	inter_t con_val2 = 0;

	if (Str::eq(S, I"0")) { con_val1 = LITERAL_IVAL; con_val2 = 0; }
	else {
		E = Inter::Types::read(ilp->line, eloc, IRS->read_into, IRS->current_package, con_kind, S, &con_val1, &con_val2, Inter::Bookmarks::scope(IRS));
		if (E) return E;
	}

	return Inter::Constant::new_numerical(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_name), Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, con_kind), con_val1, con_val2, (inter_t) IRS->latest_indent, eloc);
}

inter_error_message *Inter::Constant::parse_text(text_stream *parsed_text, text_stream *S, int from, int to, inter_error_location *eloc) {
	inter_error_message *E = NULL;
	int literal_mode = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		if ((pos.index < from) || (pos.index > to)) continue;
		int c = (int) Str::get(pos);
		if (literal_mode == FALSE) {
			if (c == '\\') { literal_mode = TRUE; continue; }
		} else {
			switch (c) {
				case '\\': break;
				case '"': break;
				case 't': c = 9; break;
				case 'n': c = 10; break;
				default: E = Inter::Errors::plain(I"no such backslash escape", eloc); break;
			}
		}
		if (Inter::Constant::char_acceptable(c) == FALSE) E = Inter::Errors::quoted(I"bad character in text", S, eloc);
		PUT_TO(parsed_text, c);
		literal_mode = FALSE;
	}
	if (E) Str::clear(parsed_text);
	return E;
}

void Inter::Constant::write_text(OUTPUT_STREAM, text_stream *S) {
	LOOP_THROUGH_TEXT(P, S) {
		wchar_t c = Str::get(P);
		if (c == 9) { WRITE("\\t"); continue; }
		if (c == 10) { WRITE("\\n"); continue; }
		if (c == '"') { WRITE("\\\""); continue; }
		if (c == '\\') { WRITE("\\\\"); continue; }
		PUT(c);
	}
}

inter_error_message *Inter::Constant::new_numerical(inter_reading_state *IRS, inter_t SID, inter_t KID, inter_t val1, inter_t val2, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_5(IRS,
		CONSTANT_IST, SID, KID, CONSTANT_DIRECT, val1, val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Constant::new_textual(inter_reading_state *IRS, inter_t SID, inter_t KID, inter_t TID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS,
		CONSTANT_IST, SID, KID, CONSTANT_INDIRECT_TEXT, TID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Constant::new_function(inter_reading_state *IRS, inter_t SID, inter_t KID, inter_t BID, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS,
		CONSTANT_IST, SID, KID, CONSTANT_ROUTINE, BID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

int Inter::Constant::append(text_stream *line, inter_error_location *eloc, inter_reading_state *IRS, inter_symbol *conts_kind, inter_frame *P, text_stream *S, inter_error_message **E) {
	*E = NULL;
	inter_t con_val1 = 0;
	inter_t con_val2 = 0;
	if (conts_kind == NULL) {
		inter_symbol *tc = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), S, CONSTANT_IST, E);
		if (*E) return FALSE;
		if (Inter::Kind::constructor(Inter::Constant::kind_of(tc)) == COLUMN_ICON) {
			Inter::Symbols::to_data(IRS->read_into, IRS->current_package, tc, &con_val1, &con_val2);
		} else {
			*E = Inter::Errors::quoted(I"not a table column constant", S, eloc);
			return FALSE;
		}
	} else {
		*E = Inter::Types::read(line, eloc, IRS->read_into, IRS->current_package, conts_kind, S, &con_val1, &con_val2, Inter::Bookmarks::scope(IRS));
		if (*E) return FALSE;
	}
	if (Inter::Frame::extend(P, 2) == FALSE) { *E = Inter::Errors::quoted(I"list too long", S, eloc); return FALSE; }
	P->data[P->extent-2] = con_val1;
	P->data[P->extent-1] = con_val2;
	return TRUE;
}

inter_error_message *Inter::Constant::verify(inter_frame P) {
	inter_error_message *E = Inter::Verify::defn(P, DEFN_CONST_IFLD); if (E) return E;
	E = Inter::Verify::symbol(P, P.data[KIND_CONST_IFLD], KIND_IST); if (E) return E;
	inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_CONST_IFLD);
	switch (P.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_DIRECT:
			if (P.extent != DATA_CONST_IFLD + 2) return Inter::Frame::error(&P, I"extent wrong", NULL);
			E = Inter::Verify::value(P, DATA_CONST_IFLD, con_kind); if (E) return E;
			break;
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST:
			if ((P.extent % 2) != 1) return Inter::Frame::error(&P, I"extent wrong", NULL);
			for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
				E = Inter::Verify::value(P, i, con_kind); if (E) return E;
			}
			break;
		case CONSTANT_INDIRECT_LIST: {
			if ((P.extent % 2) != 1) return Inter::Frame::error(&P, I"extent wrong", NULL);
			inter_data_type *idt = Inter::Kind::data_type(con_kind);
			if ((idt) && ((idt->type_ID == LIST_IDT) || (idt->type_ID == COLUMN_IDT))) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
				if (Inter::Kind::is(conts_kind) == FALSE) return Inter::Frame::error(&P, I"not a kind", (conts_kind)?(conts_kind->symbol_name):NULL);
				for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
					E = Inter::Verify::value(P, i, conts_kind); if (E) return E;
				}
			} else if ((idt) && (idt->type_ID == TABLE_IDT)) {
				for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
					inter_t V1 = P.data[i];
					inter_t V2 = P.data[i+1];
					inter_symbol *K = Inter::Types::value_to_constant_symbol_kind(P.repo_segment->owning_repo, Inter::Packages::scope_of(P), V1, V2);
					if (Inter::Kind::constructor(K) != COLUMN_ICON) return Inter::Frame::error(&P, I"not a table column constant", NULL);
				}
			} else {
				return Inter::Frame::error(&P, I"not a list", con_kind->symbol_name);
			}
			break;
		}
		case CONSTANT_STRUCT: {
			if ((P.extent % 2) != 1) return Inter::Frame::error(&P, I"extent odd", NULL);
			inter_data_type *idt = Inter::Kind::data_type(con_kind);
			if ((idt) && (idt->type_ID == STRUCT_IDT)) {
				int arity = Inter::Kind::arity(con_kind);
				int given = (P.extent - DATA_CONST_IFLD)/2;
				if (arity != given) return Inter::Frame::error(&P, I"extent not same size as struct definition", NULL);
				for (int i=DATA_CONST_IFLD, counter = 0; i<P.extent; i=i+2) {
					inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
					if (Inter::Kind::is(conts_kind) == FALSE) return Inter::Frame::error(&P, I"not a kind", (conts_kind)?(conts_kind->symbol_name):NULL);
					E = Inter::Verify::value(P, i, conts_kind); if (E) return E;
				}
			} else {
				return Inter::Frame::error(&P, I"not a struct", NULL);
			}
			break;
		}
		case CONSTANT_INDIRECT_TEXT:
			if (P.extent != DATA_CONST_IFLD + 1) return Inter::Frame::error(&P, I"extent wrong", NULL);
			inter_t ID = P.data[DATA_CONST_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			if (S == NULL) return Inter::Frame::error(&P, I"no text in comment", NULL);
			LOOP_THROUGH_TEXT(pos, S)
				if (Inter::Constant::char_acceptable(Str::get(pos)) == FALSE)
					return Inter::Frame::error(&P, I"bad character in text", NULL);
			break;
		case CONSTANT_ROUTINE:
			if (P.extent != DATA_CONST_IFLD + 1) return Inter::Frame::error(&P, I"extent wrong", NULL);
			E = Inter::Verify::symbol(P, P.data[DATA_CONST_IFLD], PACKAGE_IST); if (E) return E;
			break;
	}
	return NULL;
}

inter_error_message *Inter::Constant::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_CONST_IFLD);
	int hex = FALSE;
	for (int i=0; i<con_name->no_symbol_annotations; i++)
		if (con_name->symbol_annotations[i].annot->annotation_ID == HEX_IANN)
			hex = TRUE;
	if ((con_name) && (con_kind)) {
		WRITE("constant %S %S = ", con_name->symbol_name, con_kind->symbol_name);
		switch (P.data[FORMAT_CONST_IFLD]) {
			case CONSTANT_DIRECT:
				Inter::Types::write(OUT, P.repo_segment->owning_repo, con_kind,
					P.data[DATA_CONST_IFLD], P.data[DATA_CONST_IFLD+1], Inter::Packages::scope_of(P), hex);
				break;
			case CONSTANT_SUM_LIST:			
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST:
			case CONSTANT_INDIRECT_LIST: {
				if (P.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) WRITE("sum");
				if (P.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) WRITE("product");
				if (P.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) WRITE("difference");
				if (P.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) WRITE("quotient");
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
				WRITE("{");
				for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					Inter::Types::write(OUT, P.repo_segment->owning_repo, conts_kind, P.data[i], P.data[i+1], Inter::Packages::scope_of(P), hex);
				}
				WRITE(" }");
				break;
			}
			case CONSTANT_STRUCT: {
				WRITE("{");
				for (int i=DATA_CONST_IFLD, counter = 0; i<P.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
					Inter::Types::write(OUT, P.repo_segment->owning_repo, conts_kind, P.data[i], P.data[i+1], Inter::Packages::scope_of(P), hex);
				}
				WRITE(" }");
				break;
			}
			case CONSTANT_INDIRECT_TEXT:
				WRITE("\"");
				inter_t ID = P.data[DATA_CONST_IFLD];
				text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
				Inter::Constant::write_text(OUT, S);
				WRITE("\"");
				break;
			case CONSTANT_ROUTINE: {
				inter_symbol *block = Inter::SymbolsTables::symbol_from_frame_data(P, DATA_CONST_IFLD);
				WRITE("%S", block->symbol_name);
				break;
			}
		}
		Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, con_name);
	} else {
		return Inter::Frame::error(&P, I"constant can't be written", NULL);
	}
	return NULL;
}

void Inter::Constant::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	if (con_name) {
		inter_symbol *con_kind = Inter::SymbolsTables::symbol_from_frame_data(P, KIND_CONST_IFLD);
		if (con_kind) (*callback)(con_name, con_kind, state);
		switch (P.data[FORMAT_CONST_IFLD]) {
			case CONSTANT_DIRECT: {
				inter_t v1 = P.data[DATA_CONST_IFLD], v2 = P.data[DATA_CONST_IFLD+1];
				@<Callback on symbol if one is observed in this value@>;
				break;
			}
			case CONSTANT_SUM_LIST:
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST:
			case CONSTANT_INDIRECT_LIST:
			case CONSTANT_STRUCT: {
				for (int i=DATA_CONST_IFLD; i<P.extent; i=i+2) {
					inter_t v1 = P.data[i], v2 = P.data[i+1];
					@<Callback on symbol if one is observed in this value@>;
				}
				break;
			}
			case CONSTANT_ROUTINE: {
				inter_symbol *block = Inter::SymbolsTables::symbol_from_frame_data(P, DATA_CONST_IFLD);
				if (block) (*callback)(con_name, block, state);
				break;
			}
		}
	}
}

@<Callback on symbol if one is observed in this value@> =
	inter_symbol *S = Inter::SymbolsTables::symbol_from_data_pair_and_frame(v1, v2, P);
	if (S) (*callback)(con_name, S, state);

@ =
inter_symbol *Inter::Constant::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != CONSTANT_IST) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, KIND_CONST_IFLD);
}

inter_symbol *Inter::Constant::code_block(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != CONSTANT_IST) return NULL;
	if (D.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, DATA_CONST_IFLD);
}

int Inter::Constant::is_routine(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return FALSE;
	inter_frame D = Inter::Symbols::defining_frame(con_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return FALSE;
	if (D.data[ID_IFLD] != CONSTANT_IST) return FALSE;
	if (D.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) return FALSE;
	return TRUE;
}

inter_symbols_table *Inter::Constant::local_symbols(inter_symbol *con_symbol) {
	inter_symbol *block = Inter::Constant::code_block(con_symbol);
	if (block == NULL) return NULL;
	return Inter::Package::local_symbols(block);
}

int Inter::Constant::char_acceptable(int c) {
	if ((c < 0x20) && (c != 0x09) && (c != 0x0a)) return FALSE;
	return TRUE;
}
