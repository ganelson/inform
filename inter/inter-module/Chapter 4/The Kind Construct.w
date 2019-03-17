[Inter::Kind::] The Kind Construct.

Defining the kind construct.

@

@e KIND_IST

=
void Inter::Kind::define(void) {
	Inter::Defn::create_construct(
		KIND_IST,
		L"kind (%i+) (%c+)",
		&Inter::Kind::read,
		NULL,
		&Inter::Kind::verify,
		&Inter::Kind::write,
		NULL,
		NULL,
		NULL,
		&Inter::Kind::show_dependencies,
		I"kind", I"kinds");
}

@

@d DEFN_KIND_IFLD 2
@d DATA_TYPE_KIND_IFLD 3
@d ENUM_RANGE_KIND_IFLD 4
@d NO_INSTANCES_KIND_IFLD 5
@d SUPER_KIND_IFLD 6
@d PERM_LIST_KIND_IFLD 7
@d PLIST_KIND_IFLD 8
@d CONSTRUCTOR_KIND_IFLD 9
@d OPERANDS_KIND_IFLD 10

@d MIN_EXTENT_KIND_IFR 10

@e BASE_ICON from 1
@e LIST_ICON
@e COLUMN_ICON
@e FUNCTION_ICON
@e RELATION_ICON
@e RULE_ICON
@e RULEBOOK_ICON
@e STRUCT_ICON
@e DESCRIPTION_ICON

@d MAX_ICON_OPERANDS 128

=
inter_error_message *Inter::Kind::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, KIND_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *symb = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	match_results mr2 = Regexp::create_mr();
	inter_data_type *idt = NULL;
	int constructor = BASE_ICON;
	int arity = 0;
	inter_t operands[MAX_ICON_OPERANDS];
	inter_symbol *super_kind = NULL;
	for (int i=0; i<MAX_ICON_OPERANDS; i++) operands[i] = 0;
	if (Regexp::match(&mr2, ilp->mr.exp[1], L"<= (%i+)")) {
		super_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		idt = Inter::Kind::data_type(super_kind);
		if (Inter::Types::is_enumerated(idt) == FALSE)
			return Inter::Errors::quoted(I"not a kind which can have subkinds", mr2.exp[0], eloc);
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"rulebook of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"list", &E);
		if (E) return E;
		constructor = RULEBOOK_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"list of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"list", &E);
		if (E) return E;
		constructor = LIST_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"relation of (%i+) to (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"relation", &E);
		if (E) return E;
		constructor = RELATION_ICON;
		inter_symbol *X_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		inter_symbol *Y_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[1], KIND_IST, &E);
		if (E) return E;
		operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, X_kind);
		operands[1] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, Y_kind);
		arity = 2;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"column of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"column", &E);
		if (E) return E;
		constructor = COLUMN_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"description of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"description", &E);
		if (E) return E;
		constructor = DESCRIPTION_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr2.exp[0], KIND_IST, &E);
		if (E) return E;
		operands[0] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, conts_kind); arity = 1;
	} else if ((Regexp::match(&mr2, ilp->mr.exp[1], L"(function) (%c+) -> (%i+)")) ||
			(Regexp::match(&mr2, ilp->mr.exp[1], L"(rule) (%c+) -> (%i+)"))) {
		idt = Inter::Textual::data_type(eloc, I"routine", &E);
		if (E) return E;
		if (Str::eq(mr2.exp[0], I"function")) constructor = FUNCTION_ICON;
		else constructor = RULE_ICON;
		text_stream *from = mr2.exp[1];
		text_stream *to = mr2.exp[2];
		if (Str::eq(from, I"void")) {
			if (arity >= MAX_ICON_OPERANDS) return Inter::Errors::plain(I"too many args", eloc);
			operands[arity++] = 0;
		} else {
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, from, L" *(%i+) *(%c*)")) {
				inter_symbol *arg_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr3.exp[0], KIND_IST, &E);
				if (E) return E;
				Str::copy(from, mr3.exp[1]);
				if (arity >= MAX_ICON_OPERANDS) return Inter::Errors::plain(I"too many args", eloc);
				operands[arity++] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, arg_kind);
			}
		}
		if (Str::eq(to, I"void")) {
			if (arity >= MAX_ICON_OPERANDS) return Inter::Errors::plain(I"too many args", eloc);
			operands[arity++] = 0;
		} else {
			inter_symbol *res_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), to, KIND_IST, &E);
			if (E) return E;
			if (arity >= MAX_ICON_OPERANDS) return Inter::Errors::plain(I"too many args", eloc);
			operands[arity++] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, res_kind);
		}
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"struct (%c+)")) {
		idt = Inter::Textual::data_type(eloc, I"struct", &E);
		if (E) return E;
		constructor = STRUCT_ICON;
		text_stream *elements = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, elements, L" *(%i+) *(%c*)")) {
			inter_symbol *arg_kind = Inter::Textual::find_symbol(IRS->read_into, eloc, Inter::Bookmarks::scope(IRS), mr3.exp[0], KIND_IST, &E);
			if (E) return E;
			Str::copy(elements, mr3.exp[1]);
			if (arity >= MAX_ICON_OPERANDS) return Inter::Errors::plain(I"too many args", eloc);
			operands[arity++] = Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, arg_kind);
		}
	} else {
		idt = Inter::Textual::data_type(eloc, ilp->mr.exp[1], &E);
		if (E) return E;
	}
	if (idt == NULL) internal_error("null IDT");

	return Inter::Kind::new(IRS, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, symb), idt->type_ID,
		(super_kind)?(Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, super_kind)):0,
		constructor, arity, operands, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Kind::new(inter_reading_state *IRS, inter_t SID, inter_t TID, inter_t SUP,
	int constructor, int arity, inter_t *operands, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_8(IRS,
		KIND_IST, SID, TID, 0, 0, SUP, Inter::create_frame_list(IRS->read_into), Inter::create_frame_list(IRS->read_into),
		(inter_t) constructor, eloc, level);
	if (arity > 0) {
		if (Inter::Frame::extend(&P, (inter_t) arity) == FALSE)
			return Inter::Errors::plain(I"can't extend", eloc);
		for (int i=0; i<arity; i++) P.data[OPERANDS_KIND_IFLD+i] = operands[i];
	}
	Inter::check_segments(IRS->read_into);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Kind::verify(inter_frame P) {
	if (P.extent < MIN_EXTENT_KIND_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_KIND_IFLD); if (E) return E;
	E = Inter::Verify::data_type(P, DATA_TYPE_KIND_IFLD); if (E) return E;
	if (P.data[ENUM_RANGE_KIND_IFLD] != 0) {
		inter_symbol *the_kind = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
		if ((the_kind == NULL) ||
			(Inter::Types::is_enumerated(Inter::Types::find_by_ID(P.data[DATA_TYPE_KIND_IFLD])) == FALSE))
			return Inter::Frame::error(&P, I"spurious extent in non-enumeration", NULL);
	}
	if (P.data[SUPER_KIND_IFLD] != 0) {
		E = Inter::Verify::symbol(P, P.data[SUPER_KIND_IFLD], KIND_IST); if (E) return E;
		inter_symbol *super_kind = Inter::SymbolsTables::symbol_from_frame_data(P, SUPER_KIND_IFLD);
		if (Inter::Types::is_enumerated(Inter::Kind::data_type(super_kind)) == FALSE)
			return Inter::Frame::error(&P, I"subkind of nonenumerated kind", NULL);
	}
	int arity = P.extent - MIN_EXTENT_KIND_IFR;
	switch (P.data[CONSTRUCTOR_KIND_IFLD]) {
		case BASE_ICON: if (arity != 0) return Inter::Frame::error(&P, I"spurious kc operand", NULL);
			break;
		case LIST_ICON:
		case RULEBOOK_ICON:
			if (arity != 1) return Inter::Frame::error(&P, I"wrong list arity", NULL);
			if (P.data[OPERANDS_KIND_IFLD] == 0) return Inter::Frame::error(&P, I"no listed kind", NULL);
			E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD], KIND_IST); if (E) return E;
			break;
		case COLUMN_ICON: if (arity != 1) return Inter::Frame::error(&P, I"wrong col arity", NULL);
			if (P.data[OPERANDS_KIND_IFLD] == 0) return Inter::Frame::error(&P, I"no listed kind", NULL);
			E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD], KIND_IST); if (E) return E;
			break;
		case DESCRIPTION_ICON: if (arity != 1) return Inter::Frame::error(&P, I"wrong desc arity", NULL);
			if (P.data[OPERANDS_KIND_IFLD] == 0) return Inter::Frame::error(&P, I"no listed kind", NULL);
			E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD], KIND_IST); if (E) return E;
			break;
		case RELATION_ICON: if (arity != 2) return Inter::Frame::error(&P, I"wrong relation arity", NULL);
			if (P.data[OPERANDS_KIND_IFLD] == 0) return Inter::Frame::error(&P, I"no listed kind", NULL);
			E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD], KIND_IST); if (E) return E;
			if (P.data[OPERANDS_KIND_IFLD+1] == 0) return Inter::Frame::error(&P, I"no listed kind", NULL);
			E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD+1], KIND_IST); if (E) return E;
			break;
		case FUNCTION_ICON:
		case RULE_ICON:
			if (arity < 2) return Inter::Frame::error(&P, I"function arity too low", NULL);
			for (int i=0; i<arity; i++) {
				if (P.data[OPERANDS_KIND_IFLD + i] == 0) {
					if (!(((i == 0) && (arity == 2)) || (i == arity - 1)))
						return Inter::Frame::error(&P, I"no listed kind", NULL);
				} else {
					E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD + i], KIND_IST);
					if (E) return E;
				}
			}
			break;
		case STRUCT_ICON:
			if (arity == 0) return Inter::Frame::error(&P, I"struct arity too low", NULL);
			for (int i=0; i<arity; i++) {
				E = Inter::Verify::symbol(P, P.data[OPERANDS_KIND_IFLD + i], KIND_IST);
				if (E) return E;
			}
			break;
		default: return Inter::Frame::error(&P, I"unknown constructor", NULL);
	}

	return NULL;
}

inter_t Inter::Kind::permissions_list(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PERM_LIST_KIND_IFLD];
}

inter_t Inter::Kind::properties_list(inter_symbol *inst_name) {
	if (inst_name == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(inst_name);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[PLIST_KIND_IFLD];
}

inter_error_message *Inter::Kind::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
	inter_data_type *idt = Inter::Types::find_by_ID(P.data[DATA_TYPE_KIND_IFLD]);
	if ((symb) && (idt)) {
		WRITE("kind %S ", symb->symbol_name);
		if (P.data[SUPER_KIND_IFLD]) {
			inter_symbol *super = Inter::SymbolsTables::symbol_from_frame_data(P, SUPER_KIND_IFLD);
			WRITE("<= %S", super->symbol_name);
		} else {
			switch (P.data[CONSTRUCTOR_KIND_IFLD]) {
				case BASE_ICON: WRITE("%S", idt->reserved_word); break;
				case LIST_ICON: {
					inter_symbol *conts_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("list of %S", conts_kind->symbol_name);
					break;
				}
				case RULEBOOK_ICON: {
					inter_symbol *conts_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("rulebook of %S", conts_kind->symbol_name);
					break;
				}
				case COLUMN_ICON: {
					inter_symbol *conts_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("column of %S", conts_kind->symbol_name);
					break;
				}
				case DESCRIPTION_ICON: {
					inter_symbol *conts_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("description of %S", conts_kind->symbol_name);
					break;
				}
				case RELATION_ICON: {
					inter_symbol *X_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					inter_symbol *Y_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD+1);
					WRITE("relation of %S to %S", X_kind->symbol_name, Y_kind->symbol_name);
					break;
				}
				case FUNCTION_ICON:
				case RULE_ICON: {
					if (P.data[CONSTRUCTOR_KIND_IFLD] == FUNCTION_ICON)
						WRITE("function");
					else
						WRITE("rule");
					int arity = P.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						WRITE(" ");
						if (i == arity - 1) WRITE("-> ");
						if (P.data[OPERANDS_KIND_IFLD + i] == 0) {
							WRITE("void");
						} else {
							inter_symbol *K = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
							WRITE("%S", K->symbol_name);
						}
					}
					break;
				}
				case STRUCT_ICON: {
					WRITE("struct");
					int arity = P.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						inter_symbol *K = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
						WRITE(" %S", K->symbol_name);
					}
					break;
				}
				default: return Inter::Frame::error(&P, I"cannot write kind", NULL);
					break;
			}
		}
	} else return Inter::Frame::error(&P, I"cannot write kind", NULL);
	Inter::Symbols::write_annotations(OUT, P.repo_segment->owning_repo, symb);
	return NULL;
}

void Inter::Kind::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_symbol *symb = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
	inter_data_type *idt = Inter::Types::find_by_ID(P.data[DATA_TYPE_KIND_IFLD]);
	if ((symb) && (idt)) {
		if (P.data[SUPER_KIND_IFLD]) {
			inter_symbol *super = Inter::SymbolsTables::symbol_from_frame_data(P, SUPER_KIND_IFLD);
			if (super) (*callback)(symb, super, state);
		} else {
			switch (P.data[CONSTRUCTOR_KIND_IFLD]) {
				case RULEBOOK_ICON:
				case LIST_ICON:
				case COLUMN_ICON:
				case DESCRIPTION_ICON: {
					inter_symbol *conts_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					if (conts_kind) (*callback)(symb, conts_kind, state);
					break;
				}
				case RELATION_ICON: {
					inter_symbol *X_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					inter_symbol *Y_kind = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD+1);
					if (X_kind) (*callback)(symb, X_kind, state);
					if (Y_kind) (*callback)(symb, Y_kind, state);
					break;
				}
				case FUNCTION_ICON:
				case RULE_ICON: {
					int arity = P.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						if (P.data[OPERANDS_KIND_IFLD + i] != 0) {
							inter_symbol *K = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
							if (K) (*callback)(symb, K, state);
						}
					}
					break;
				}
				case STRUCT_ICON: {
					int arity = P.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						inter_symbol *K = Inter::SymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
						if (K) (*callback)(symb, K, state);
					}
					break;
				}
			}
		}
	}
}

void Inter::Kind::new_instance(inter_symbol *kind_symbol, inter_symbol *inst_name) {
	if (kind_symbol == NULL) return;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return;
	D.data[NO_INSTANCES_KIND_IFLD]++;
	inter_symbol *S = Inter::Kind::super(kind_symbol);
	if (S) Inter::Kind::new_instance(S, inst_name);
}

int Inter::Kind::instance_count(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return (int) D.data[NO_INSTANCES_KIND_IFLD];
}

int Inter::Kind::constructor(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return (int) D.data[CONSTRUCTOR_KIND_IFLD];
}

int Inter::Kind::arity(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.extent - MIN_EXTENT_KIND_IFR;
}

inter_symbol *Inter::Kind::operand_symbol(inter_symbol *kind_symbol, int i) {
	if (kind_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (i >= D.extent - MIN_EXTENT_KIND_IFR) return NULL;
	inter_t CID = D.data[OPERANDS_KIND_IFLD + i];
	return Inter::SymbolsTables::symbol_from_id(Inter::Packages::scope_of(D), CID);
}

inter_data_type *Inter::Kind::data_type(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	return Inter::Types::find_by_ID(D.data[DATA_TYPE_KIND_IFLD]);
}

inter_t Inter::Kind::next_enumerated_value(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return ++(D.data[ENUM_RANGE_KIND_IFLD]);
}

inter_symbol *Inter::Kind::super(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	return Inter::SymbolsTables::symbol_from_frame_data(D, SUPER_KIND_IFLD);
}

int Inter::Kind::is(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return FALSE;
	inter_frame D = Inter::Symbols::defining_frame(kind_symbol);
	if (Inter::Frame::valid(&D) == FALSE) return FALSE;
	if (D.data[ID_IFLD] == KIND_IST) return TRUE;
	return FALSE;
}

int Inter::Kind::is_a(inter_symbol *K1, inter_symbol *K2) {
	inter_data_type *idt1 = Inter::Kind::data_type(K1);
	inter_data_type *idt2 = Inter::Kind::data_type(K2);
	if ((idt1 == unchecked_idt) || (idt2 == unchecked_idt)) return TRUE;
	while (K1) {
		if (K1 == K2) return TRUE;
		K1 = Inter::Kind::super(K1);
	}
	return FALSE;
}
