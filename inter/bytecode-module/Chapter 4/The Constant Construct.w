[Inter::Constant::] The Constant Construct.

Defining the constant construct.

@

@e CONSTANT_IST

=
void Inter::Constant::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		CONSTANT_IST,
		L"constant (%C+) (%i+) = (%c+)",
		I"constant", I"constants");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Constant::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Constant::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Constant::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Constant::write);
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
void Inter::Constant::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, CONSTANT_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *con_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	Inter::Annotations::copy_set_to_symbol(&(ilp->set), con_name);

	inter_symbol *con_kind = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), ilp->mr.exp[1], KIND_IST, E);
	if (*E) return;
	text_stream *S = ilp->mr.exp[2];

	inter_data_type *idt = Inter::Kind::data_type(con_kind);

	match_results mr2 = Regexp::create_mr();
	inter_ti op = 0;
	if (Regexp::match(&mr2, S, L"sum{ (%c*) }")) op = CONSTANT_SUM_LIST;
	else if (Regexp::match(&mr2, S, L"product{ (%c*) }")) op = CONSTANT_PRODUCT_LIST;
	else if (Regexp::match(&mr2, S, L"difference{ (%c*) }")) op = CONSTANT_DIFFERENCE_LIST;
	else if (Regexp::match(&mr2, S, L"quotient{ (%c*) }")) op = CONSTANT_QUOTIENT_LIST;
	if (op != 0) {
		inter_tree_node *P =
			Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), op, eloc, (inter_ti) ilp->indent_level);
		*E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
		if (*E) return;
		text_stream *conts = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
			if (Inter::Constant::append(ilp->line, eloc, IBM, con_kind, P, mr3.exp[0], E) == FALSE)
				return;
			Str::copy(conts, mr3.exp[1]);
		}
		if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
			if (Inter::Constant::append(ilp->line, eloc, IBM, con_kind, P, mr3.exp[0], E) == FALSE)
				return;
		}
		Inter::Bookmarks::insert(IBM, P);
		return;
	}

	if ((idt) && ((idt->type_ID == LIST_IDT) || (idt->type_ID == COLUMN_IDT))) {
		inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
		if (conts_kind) {
			match_results mr2 = Regexp::create_mr();
			inter_ti form = 0;
			if (Regexp::match(&mr2, S, L"{ (%c*) }")) form = CONSTANT_INDIRECT_LIST;
			else if (Regexp::match(&mr2, S, L"sum{ (%c*) }")) form = CONSTANT_SUM_LIST;
			else if (Regexp::match(&mr2, S, L"product{ (%c*) }")) form = CONSTANT_PRODUCT_LIST;
			else if (Regexp::match(&mr2, S, L"difference{ (%c*) }")) form = CONSTANT_DIFFERENCE_LIST;
			else if (Regexp::match(&mr2, S, L"quotient{ (%c*) }")) form = CONSTANT_QUOTIENT_LIST;
			if (form != 0) {
				inter_tree_node *P =
					Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), form, eloc, (inter_ti) ilp->indent_level);
				*E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
				if (*E) return;
				text_stream *conts = mr2.exp[0];
				match_results mr3 = Regexp::create_mr();
				while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
					if (Inter::Constant::append(ilp->line, eloc, IBM, conts_kind, P, mr3.exp[0], E) == FALSE)
						return;
					Str::copy(conts, mr3.exp[1]);
				}
				if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
					if (Inter::Constant::append(ilp->line, eloc, IBM, conts_kind, P, mr3.exp[0], E) == FALSE)
						return;
				}
				Inter::Bookmarks::insert(IBM, P);
				return;
			}
		}
	}

	if ((idt) && (idt->type_ID == STRUCT_IDT)) {
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, S, L"{ (%c*) }")) {
			inter_tree_node *P =
				 Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), CONSTANT_STRUCT, eloc, (inter_ti) ilp->indent_level);
			int arity = Inter::Kind::arity(con_kind);
			int counter = 0;
			text_stream *conts = mr2.exp[0];
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
				if (Inter::Constant::append(ilp->line, eloc, IBM, conts_kind, P, mr3.exp[0], E) == FALSE)
					return;
				Str::copy(conts, mr3.exp[1]);
			}
			if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
				if (Inter::Constant::append(ilp->line, eloc, IBM, conts_kind, P, mr3.exp[0], E) == FALSE)
					return;
			}
			if (counter != arity)
				{ *E = Inter::Errors::quoted(I"wrong size", S, eloc); return; }
			*E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (*E) return;
			Inter::Bookmarks::insert(IBM, P);
			return;
		}
	}

	if ((idt) && (idt->type_ID == TABLE_IDT)) {
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, S, L"{ (%c*) }")) {
			inter_tree_node *P =
				Inode::fill_3(IBM, CONSTANT_IST, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), CONSTANT_INDIRECT_LIST, eloc, (inter_ti) ilp->indent_level);
			*E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
			if (*E) return;
			text_stream *conts = mr2.exp[0];
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, conts, L"(%c*?), (%c+)")) {
				if (Inter::Constant::append(ilp->line, eloc, IBM, NULL, P, mr3.exp[0], E) == FALSE)
					return;
				Str::copy(conts, mr3.exp[1]);
			}
			if (Regexp::match(&mr3, conts, L" *(%c*?) *")) {
				if (Inter::Constant::append(ilp->line, eloc, IBM, NULL, P, mr3.exp[0], E) == FALSE)
					return;
			}
			Inter::Bookmarks::insert(IBM, P);
			return;
		}
	}

	if ((idt) && (idt->type_ID == TEXT_IDT)) {
		if ((Str::begins_with_wide_string(S, L"\"")) && (Str::ends_with_wide_string(S, L"\""))) {
			TEMPORARY_TEXT(parsed_text)
			*E = Inter::Constant::parse_text(parsed_text, S, 1, Str::len(S)-2, eloc);
			inter_ti ID = 0;
			if (*E == NULL) {
				ID = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::package(IBM));
				Str::copy(Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(IBM), ID), parsed_text);
			}
			DISCARD_TEXT(parsed_text)
			if (*E) return;
			*E = Inter::Constant::new_textual(IBM, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), ID, (inter_ti) ilp->indent_level, eloc);
			return;
		}
	}

	if ((idt) && (idt->type_ID == ROUTINE_IDT)) {
		inter_package *block = Inter::Packages::by_name(Inter::Bookmarks::package(IBM), S);
		if (block == NULL) {
			*E = Inter::Errors::quoted(I"no such code block", S, eloc); return;
		}
		*E = Inter::Constant::new_function(IBM, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), block, (inter_ti) ilp->indent_level, eloc);
		return;
	}

	inter_ti con_val1 = 0;
	inter_ti con_val2 = 0;

	if (Str::eq(S, I"0")) { con_val1 = LITERAL_IVAL; con_val2 = 0; }
	else {
		*E = Inter::Types::read(ilp->line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), con_kind, S, &con_val1, &con_val2, Inter::Bookmarks::scope(IBM));
		if (*E) return;
	}

	*E = Inter::Constant::new_numerical(IBM, InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_name), InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_kind), con_val1, con_val2, (inter_ti) ilp->indent_level, eloc);
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

inter_error_message *Inter::Constant::new_numerical(inter_bookmark *IBM, inter_ti SID, inter_ti KID, inter_ti val1, inter_ti val2, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_5(IBM,
		CONSTANT_IST, SID, KID, CONSTANT_DIRECT, val1, val2, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

inter_error_message *Inter::Constant::new_textual(inter_bookmark *IBM, inter_ti SID, inter_ti KID, inter_ti TID, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_4(IBM,
		CONSTANT_IST, SID, KID, CONSTANT_INDIRECT_TEXT, TID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

inter_error_message *Inter::Constant::new_function(inter_bookmark *IBM, inter_ti SID, inter_ti KID, inter_package *block, inter_ti level, inter_error_location *eloc) {
	inter_ti BID = block->index_n;
	inter_tree_node *P = Inode::fill_4(IBM,
		CONSTANT_IST, SID, KID, CONSTANT_ROUTINE, BID, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P); if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

int Inter::Constant::append(text_stream *line, inter_error_location *eloc, inter_bookmark *IBM, inter_symbol *conts_kind, inter_tree_node *P, text_stream *S, inter_error_message **E) {
	*E = NULL;
	inter_ti con_val1 = 0;
	inter_ti con_val2 = 0;
	if (conts_kind == NULL) {
		inter_symbol *tc = Inter::Textual::find_symbol(Inter::Bookmarks::tree(IBM), eloc, Inter::Bookmarks::scope(IBM), S, CONSTANT_IST, E);
		if (*E) return FALSE;
		if (Inter::Kind::constructor(Inter::Constant::kind_of(tc)) == COLUMN_ICON) {
			Inter::Symbols::to_data(Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), tc, &con_val1, &con_val2);
		} else {
			*E = Inter::Errors::quoted(I"not a table column constant", S, eloc);
			return FALSE;
		}
	} else {
		*E = Inter::Types::read(line, eloc, Inter::Bookmarks::tree(IBM), Inter::Bookmarks::package(IBM), conts_kind, S, &con_val1, &con_val2, Inter::Bookmarks::scope(IBM));
		if (*E) return FALSE;
	}
	if (Inode::extend(P, 2) == FALSE) { *E = Inter::Errors::quoted(I"list too long", S, eloc); return FALSE; }
	P->W.data[P->W.extent-2] = con_val1;
	P->W.data[P->W.extent-1] = con_val2;
	return TRUE;
}

void Inter::Constant::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_ROUTINE)
		P->W.data[DATA_CONST_IFLD] = grid[P->W.data[DATA_CONST_IFLD]];

	switch (P->W.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_DIRECT:
			P->W.data[DATA_CONST_IFLD+1] = Inter::Types::transpose_value(P->W.data[DATA_CONST_IFLD], P->W.data[DATA_CONST_IFLD+1], grid, grid_extent, E);
			break;
		case CONSTANT_INDIRECT_TEXT:
			P->W.data[DATA_CONST_IFLD] = grid[P->W.data[DATA_CONST_IFLD]];
			break;
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST:
		case CONSTANT_INDIRECT_LIST:
		case CONSTANT_STRUCT:
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				P->W.data[i+1] = Inter::Types::transpose_value(P->W.data[i], P->W.data[i+1], grid, grid_extent, E);
			}
			break;
	}
}

void Inter::Constant::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = Inter::Verify::defn(owner, P, DEFN_CONST_IFLD); if (*E) return;
	*E = Inter::Verify::symbol(owner, P, P->W.data[KIND_CONST_IFLD], KIND_IST); if (*E) return;
	inter_symbol *con_kind = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P->W.data[KIND_CONST_IFLD]);
	switch (P->W.data[FORMAT_CONST_IFLD]) {
		case CONSTANT_DIRECT:
			if (P->W.extent != DATA_CONST_IFLD + 2) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			*E = Inter::Verify::value(owner, P, DATA_CONST_IFLD, con_kind); if (*E) return;
			break;
		case CONSTANT_SUM_LIST:
		case CONSTANT_PRODUCT_LIST:
		case CONSTANT_DIFFERENCE_LIST:
		case CONSTANT_QUOTIENT_LIST:
			if ((P->W.extent % 2) != 1) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
				*E = Inter::Verify::value(owner, P, i, con_kind); if (*E) return;
			}
			break;
		case CONSTANT_INDIRECT_LIST: {
			if ((P->W.extent % 2) != 1) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			inter_data_type *idt = Inter::Kind::data_type(con_kind);
			if ((idt) && ((idt->type_ID == LIST_IDT) || (idt->type_ID == COLUMN_IDT))) {
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
				if (Inter::Kind::is(conts_kind) == FALSE) { *E = Inode::error(P, I"not a kind", (conts_kind)?(conts_kind->symbol_name):NULL); return; }
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					*E = Inter::Verify::value(owner, P, i, conts_kind); if (*E) return;
				}
			} else if ((idt) && (idt->type_ID == TABLE_IDT)) {
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					inter_ti V1 = P->W.data[i];
					inter_ti V2 = P->W.data[i+1];
					inter_symbol *K = Inter::Types::value_to_constant_symbol_kind(Inter::Packages::scope(owner), V1, V2);
					if (Inter::Kind::constructor(K) != COLUMN_ICON) { *E = Inode::error(P, I"not a table column constant", NULL); return; }
				}
			} else {
				{ *E = Inode::error(P, I"not a list", con_kind->symbol_name); return; }
			}
			break;
		}
		case CONSTANT_STRUCT: {
			if ((P->W.extent % 2) != 1) { *E = Inode::error(P, I"extent odd", NULL); return; }
			inter_data_type *idt = Inter::Kind::data_type(con_kind);
			if ((idt) && (idt->type_ID == STRUCT_IDT)) {
				int arity = Inter::Kind::arity(con_kind);
				int given = (P->W.extent - DATA_CONST_IFLD)/2;
				if (arity != given) { *E = Inode::error(P, I"extent not same size as struct definition", NULL); return; }
				for (int i=DATA_CONST_IFLD, counter = 0; i<P->W.extent; i=i+2) {
					inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
					if (Inter::Kind::is(conts_kind) == FALSE) { *E = Inode::error(P, I"not a kind", (conts_kind)?(conts_kind->symbol_name):NULL); return; }
					*E = Inter::Verify::value(owner, P, i, conts_kind); if (*E) return;
				}
			} else {
				{ *E = Inode::error(P, I"not a struct", NULL); return; }
			}
			break;
		}
		case CONSTANT_INDIRECT_TEXT:
			if (P->W.extent != DATA_CONST_IFLD + 1) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			inter_ti ID = P->W.data[DATA_CONST_IFLD];
			text_stream *S = Inode::ID_to_text(P, ID);
			if (S == NULL) { *E = Inode::error(P, I"no text in comment", NULL); return; }
			LOOP_THROUGH_TEXT(pos, S)
				if (Inter::Constant::char_acceptable(Str::get(pos)) == FALSE)
					{ *E = Inode::error(P, I"bad character in text", NULL); return; }
			break;
		case CONSTANT_ROUTINE:
			if (P->W.extent != DATA_CONST_IFLD + 1) { *E = Inode::error(P, I"extent wrong", NULL); return; }
			break;
	}
}

void Inter::Constant::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *con_name = InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	inter_symbol *con_kind = InterSymbolsTables::symbol_from_frame_data(P, KIND_CONST_IFLD);
	int hex = FALSE;
	if (Inter::Annotations::find(&(con_name->ann_set), HEX_IANN)) hex = TRUE;
	if ((con_name) && (con_kind)) {
		WRITE("constant %S %S = ", con_name->symbol_name, con_kind->symbol_name);
		switch (P->W.data[FORMAT_CONST_IFLD]) {
			case CONSTANT_DIRECT:
				Inter::Types::write(OUT, P, con_kind,
					P->W.data[DATA_CONST_IFLD], P->W.data[DATA_CONST_IFLD+1], Inter::Packages::scope_of(P), hex);
				break;
			case CONSTANT_SUM_LIST:			
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST:
			case CONSTANT_INDIRECT_LIST: {
				if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_SUM_LIST) WRITE("sum");
				if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_PRODUCT_LIST) WRITE("product");
				if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIFFERENCE_LIST) WRITE("difference");
				if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_QUOTIENT_LIST) WRITE("quotient");
				inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, 0);
				WRITE("{");
				for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					Inter::Types::write(OUT, P, conts_kind, P->W.data[i], P->W.data[i+1], Inter::Packages::scope_of(P), hex);
				}
				WRITE(" }");
				break;
			}
			case CONSTANT_STRUCT: {
				WRITE("{");
				for (int i=DATA_CONST_IFLD, counter = 0; i<P->W.extent; i=i+2) {
					if (i > DATA_CONST_IFLD) WRITE(",");
					WRITE(" ");
					inter_symbol *conts_kind = Inter::Kind::operand_symbol(con_kind, counter++);
					Inter::Types::write(OUT, P, conts_kind, P->W.data[i], P->W.data[i+1], Inter::Packages::scope_of(P), hex);
				}
				WRITE(" }");
				break;
			}
			case CONSTANT_INDIRECT_TEXT:
				WRITE("\"");
				inter_ti ID = P->W.data[DATA_CONST_IFLD];
				text_stream *S = Inode::ID_to_text(P, ID);
				Inter::Constant::write_text(OUT, S);
				WRITE("\"");
				break;
			case CONSTANT_ROUTINE: {
				inter_package *block = Inode::ID_to_package(P, P->W.data[DATA_CONST_IFLD]);
				WRITE("%S", Inter::Packages::name(block));
				break;
			}
		}
		Inter::Symbols::write_annotations(OUT, P, con_name);
	} else {
		*E = Inode::error(P, I"constant can't be written", NULL);
		return;
	}
}

inter_symbol *Inter::Constant::kind_of(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != CONSTANT_IST) return NULL;
	return InterSymbolsTables::symbol_from_frame_data(D, KIND_CONST_IFLD);
}

inter_package *Inter::Constant::code_block(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(con_symbol);
	if (D == NULL) return NULL;
	if (D->W.data[ID_IFLD] != CONSTANT_IST) return NULL;
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) return NULL;
	return Inode::ID_to_package(D, D->W.data[DATA_CONST_IFLD]);
}

int Inter::Constant::is_routine(inter_symbol *con_symbol) {
	if (con_symbol == NULL) return FALSE;
	inter_tree_node *D = Inter::Symbols::definition(con_symbol);
	if (D == NULL) return FALSE;
	if (D->W.data[ID_IFLD] != CONSTANT_IST) return FALSE;
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) return FALSE;
	return TRUE;
}

inter_symbols_table *Inter::Constant::local_symbols(inter_symbol *con_symbol) {
	return Inter::Packages::scope(Inter::Constant::code_block(con_symbol));
}

int Inter::Constant::char_acceptable(int c) {
	if ((c < 0x20) && (c != 0x09) && (c != 0x0a)) return FALSE;
	return TRUE;
}

int Inter::Constant::constant_depth(inter_symbol *con) {
	LOG_INDENT;
	int d = Inter::Constant::constant_depth_r(con);
	LOGIF(CONSTANT_DEPTH_CALCULATION, "%S has depth %d\n", con->symbol_name, d);
	LOG_OUTDENT;
	return d;
}
int Inter::Constant::constant_depth_r(inter_symbol *con) {
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
			return Inter::Constant::constant_depth(alias) + 1;
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
				total += Inter::Constant::constant_depth(alias);
			} else total++;
		}
		return 1 + total;
	}
	return 1;
}

inter_ti Inter::Constant::evaluate(inter_symbols_table *T, inter_ti val1, inter_ti val2) {
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
				inter_ti e = Inter::Constant::evaluate(Inter::Packages::scope_of(D), dval1, dval2);
				return e;
			}
			case CONSTANT_SUM_LIST:
			case CONSTANT_PRODUCT_LIST:
			case CONSTANT_DIFFERENCE_LIST:
			case CONSTANT_QUOTIENT_LIST: {
				inter_ti result = 0;
				for (int i=DATA_CONST_IFLD; i<D->W.extent; i=i+2) {
					inter_ti extra = Inter::Constant::evaluate(Inter::Packages::scope_of(D), D->W.data[i], D->W.data[i+1]);
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
