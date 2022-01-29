[Inter::Kind::] The Kind Construct.

Defining the kind construct.

@

@e KIND_IST

=
void Inter::Kind::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		KIND_IST,
		L"kind (%i+) (%c+)",
		I"kind", I"kinds");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Kind::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Kind::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Kind::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Kind::write);
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
void Inter::Kind::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IBM, KIND_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *symb = Inter::Textual::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	match_results mr2 = Regexp::create_mr();
	inter_data_type *idt = NULL;
	int constructor = BASE_ICON;
	int arity = 0;
	inter_ti operands[MAX_ICON_OPERANDS];
	inter_symbol *super_kind = NULL;
	for (int i=0; i<MAX_ICON_OPERANDS; i++) operands[i] = 0;
	if (Regexp::match(&mr2, ilp->mr.exp[1], L"<= (%i+)")) {
		super_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		idt = Inter::Kind::data_type(super_kind);
		if (Inter::Types::is_enumerated(idt) == FALSE)
			{ *E = Inter::Errors::quoted(I"not a kind which can have subkinds", mr2.exp[0], eloc); return; }
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"rulebook of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"list", E);
		if (*E) return;
		constructor = RULEBOOK_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"list of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"list", E);
		if (*E) return;
		constructor = LIST_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"relation of (%i+) to (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"relation", E);
		if (*E) return;
		constructor = RELATION_ICON;
		inter_symbol *X_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		inter_symbol *Y_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[1], KIND_IST, E);
		if (*E) return;
		operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, X_kind);
		operands[1] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, Y_kind);
		arity = 2;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"column of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"column", E);
		if (*E) return;
		constructor = COLUMN_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, conts_kind); arity = 1;
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"description of (%i+)")) {
		idt = Inter::Textual::data_type(eloc, I"description", E);
		if (*E) return;
		constructor = DESCRIPTION_ICON;
		inter_symbol *conts_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr2.exp[0], KIND_IST, E);
		if (*E) return;
		operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, conts_kind); arity = 1;
	} else if ((Regexp::match(&mr2, ilp->mr.exp[1], L"(function) (%c+) -> (%i+)")) ||
			(Regexp::match(&mr2, ilp->mr.exp[1], L"(rule) (%c+) -> (%i+)"))) {
		idt = Inter::Textual::data_type(eloc, I"routine", E);
		if (*E) return;
		if (Str::eq(mr2.exp[0], I"function")) constructor = FUNCTION_ICON;
		else constructor = RULE_ICON;
		text_stream *from = mr2.exp[1];
		text_stream *to = mr2.exp[2];
		if (Str::eq(from, I"void")) {
			if (arity >= MAX_ICON_OPERANDS) { *E = Inter::Errors::plain(I"too many args", eloc); return; }
			operands[arity++] = 0;
		} else {
			match_results mr3 = Regexp::create_mr();
			while (Regexp::match(&mr3, from, L" *(%i+) *(%c*)")) {
				inter_symbol *arg_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr3.exp[0], KIND_IST, E);
				if (*E) return;
				Str::copy(from, mr3.exp[1]);
				if (arity >= MAX_ICON_OPERANDS) { *E = Inter::Errors::plain(I"too many args", eloc); return; }
				operands[arity++] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, arg_kind);
			}
		}
		if (Str::eq(to, I"void")) {
			if (arity >= MAX_ICON_OPERANDS) { *E = Inter::Errors::plain(I"too many args", eloc); return; }
			operands[arity++] = 0;
		} else {
			inter_symbol *res_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), to, KIND_IST, E);
			if (*E) return;
			if (arity >= MAX_ICON_OPERANDS) { *E = Inter::Errors::plain(I"too many args", eloc); return; }
			operands[arity++] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, res_kind);
		}
	} else if (Regexp::match(&mr2, ilp->mr.exp[1], L"struct (%c+)")) {
		idt = Inter::Textual::data_type(eloc, I"struct", E);
		if (*E) return;
		constructor = STRUCT_ICON;
		text_stream *elements = mr2.exp[0];
		match_results mr3 = Regexp::create_mr();
		while (Regexp::match(&mr3, elements, L" *(%i+) *(%c*)")) {
			inter_symbol *arg_kind = Inter::Textual::find_symbol(InterBookmark::tree(IBM), eloc, InterBookmark::scope(IBM), mr3.exp[0], KIND_IST, E);
			if (*E) return;
			Str::copy(elements, mr3.exp[1]);
			if (arity >= MAX_ICON_OPERANDS) { *E = Inter::Errors::plain(I"too many args", eloc); return; }
			operands[arity++] = InterSymbolsTables::id_from_IRS_and_symbol(IBM, arg_kind);
		}
	} else {
		idt = Inter::Textual::data_type(eloc, ilp->mr.exp[1], E);
		if (*E) return;
	}
	if (idt == NULL) internal_error("null IDT");

	*E = Inter::Kind::new(IBM, InterSymbolsTables::id_from_IRS_and_symbol(IBM, symb), idt->type_ID,
		(super_kind)?(InterSymbolsTables::id_from_IRS_and_symbol(IBM, super_kind)):0,
		constructor, arity, operands, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::Kind::new(inter_bookmark *IBM, inter_ti SID, inter_ti TID, inter_ti SUP,
	int constructor, int arity, inter_ti *operands, inter_ti level, inter_error_location *eloc) {
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_ti L1 = Inter::Warehouse::create_frame_list(warehouse);
	inter_ti L2 = Inter::Warehouse::create_frame_list(warehouse);
	Inter::Warehouse::attribute_resource(warehouse, L1, InterBookmark::package(IBM));
	Inter::Warehouse::attribute_resource(warehouse, L2, InterBookmark::package(IBM));
	inter_tree_node *P = Inode::new_with_8_data_fields(IBM,
		KIND_IST, SID, TID, 0, 0, SUP, L1, L2,
		(inter_ti) constructor, eloc, level);
	if (arity > 0) {
		if (Inode::add_data_fields(P, (inter_ti) arity) == FALSE)
			return Inter::Errors::plain(I"can't extend", eloc);
		for (int i=0; i<arity; i++) P->W.data[OPERANDS_KIND_IFLD+i] = operands[i];
	}
	inter_error_message *E = Inter::Defn::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Kind::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.data[PERM_LIST_KIND_IFLD] = grid[P->W.data[PERM_LIST_KIND_IFLD]];
	P->W.data[PLIST_KIND_IFLD] = grid[P->W.data[PLIST_KIND_IFLD]];
}

void Inter::Kind::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent < MIN_EXTENT_KIND_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_KIND_IFLD); if (*E) return;
	*E = Inter::Verify::data_type(P, DATA_TYPE_KIND_IFLD); if (*E) return;
	if (P->W.data[ENUM_RANGE_KIND_IFLD] != 0) {
		inter_symbol *the_kind = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P->W.data[DEFN_KIND_IFLD]);
		if ((the_kind == NULL) ||
			(Inter::Types::is_enumerated(Inter::Types::find_by_ID(P->W.data[DATA_TYPE_KIND_IFLD])) == FALSE))
			{ *E = Inode::error(P, I"spurious extent in non-enumeration", NULL); return; }
	}
	if (P->W.data[SUPER_KIND_IFLD] != 0) {
		*E = Inter::Verify::symbol(owner, P, P->W.data[SUPER_KIND_IFLD], KIND_IST); if (*E) return;
		inter_symbol *super_kind = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(owner), P->W.data[SUPER_KIND_IFLD]);
		if (Inter::Types::is_enumerated(Inter::Kind::data_type(super_kind)) == FALSE)
			{ *E = Inode::error(P, I"subkind of nonenumerated kind", NULL); return; }
	}
	int arity = P->W.extent - MIN_EXTENT_KIND_IFR;
	switch (P->W.data[CONSTRUCTOR_KIND_IFLD]) {
		case BASE_ICON: if (arity != 0) { *E = Inode::error(P, I"spurious kc operand", NULL); return; }
			break;
		case LIST_ICON:
		case RULEBOOK_ICON:
			if (arity != 1) { *E = Inode::error(P, I"wrong list arity", NULL); return; }
			if (P->W.data[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD], KIND_IST); if (*E) return;
			break;
		case COLUMN_ICON: if (arity != 1) { *E = Inode::error(P, I"wrong col arity", NULL); return; }
			if (P->W.data[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD], KIND_IST); if (*E) return;
			break;
		case DESCRIPTION_ICON: if (arity != 1) { *E = Inode::error(P, I"wrong desc arity", NULL); return; }
			if (P->W.data[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD], KIND_IST); if (*E) return;
			break;
		case RELATION_ICON: if (arity != 2) { *E = Inode::error(P, I"wrong relation arity", NULL); return; }
			if (P->W.data[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD], KIND_IST); if (*E) return;
			if (P->W.data[OPERANDS_KIND_IFLD+1] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD+1], KIND_IST); if (*E) return;
			break;
		case FUNCTION_ICON:
		case RULE_ICON:
			if (arity < 2) { *E = Inode::error(P, I"function arity too low", NULL); return; }
			for (int i=0; i<arity; i++) {
				if (P->W.data[OPERANDS_KIND_IFLD + i] == 0) {
					if (!(((i == 0) && (arity == 2)) || (i == arity - 1)))
						{ *E = Inode::error(P, I"no listed kind", NULL); return; }
				} else {
					*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD + i], KIND_IST);
					if (*E) return;
				}
			}
			break;
		case STRUCT_ICON:
			if (arity == 0) { *E = Inode::error(P, I"struct arity too low", NULL); return; }
			for (int i=0; i<arity; i++) {
				*E = Inter::Verify::symbol(owner, P, P->W.data[OPERANDS_KIND_IFLD + i], KIND_IST);
				if (*E) return;
			}
			break;
		default: { *E = Inode::error(P, I"unknown constructor", NULL); return; }
	}
}

inter_ti Inter::Kind::permissions_list(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return 0;
	return D->W.data[PERM_LIST_KIND_IFLD];
}

inter_ti Inter::Kind::properties_list(inter_symbol *inst_name) {
	if (inst_name == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(inst_name);
	if (D == NULL) return 0;
	return D->W.data[PLIST_KIND_IFLD];
}

void Inter::Kind::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *symb = InterSymbolsTables::symbol_from_frame_data(P, DEFN_KIND_IFLD);
	inter_data_type *idt = Inter::Types::find_by_ID(P->W.data[DATA_TYPE_KIND_IFLD]);
	if ((symb) && (idt)) {
		WRITE("kind %S ", symb->symbol_name);
		if (P->W.data[SUPER_KIND_IFLD]) {
			inter_symbol *super = InterSymbolsTables::symbol_from_frame_data(P, SUPER_KIND_IFLD);
			WRITE("<= %S", super->symbol_name);
		} else {
			switch (P->W.data[CONSTRUCTOR_KIND_IFLD]) {
				case BASE_ICON: WRITE("%S", idt->reserved_word); break;
				case LIST_ICON: {
					inter_symbol *conts_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("list of %S", conts_kind->symbol_name);
					break;
				}
				case RULEBOOK_ICON: {
					inter_symbol *conts_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("rulebook of %S", conts_kind->symbol_name);
					break;
				}
				case COLUMN_ICON: {
					inter_symbol *conts_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("column of %S", conts_kind->symbol_name);
					break;
				}
				case DESCRIPTION_ICON: {
					inter_symbol *conts_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					WRITE("description of %S", conts_kind->symbol_name);
					break;
				}
				case RELATION_ICON: {
					inter_symbol *X_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD);
					inter_symbol *Y_kind = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD+1);
					WRITE("relation of %S to %S", X_kind->symbol_name, Y_kind->symbol_name);
					break;
				}
				case FUNCTION_ICON:
				case RULE_ICON: {
					if (P->W.data[CONSTRUCTOR_KIND_IFLD] == FUNCTION_ICON)
						WRITE("function");
					else
						WRITE("rule");
					int arity = P->W.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						WRITE(" ");
						if (i == arity - 1) WRITE("-> ");
						if (P->W.data[OPERANDS_KIND_IFLD + i] == 0) {
							WRITE("void");
						} else {
							inter_symbol *K = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
							WRITE("%S", K->symbol_name);
						}
					}
					break;
				}
				case STRUCT_ICON: {
					WRITE("struct");
					int arity = P->W.extent - MIN_EXTENT_KIND_IFR;
					for (int i=0; i<arity; i++) {
						inter_symbol *K = InterSymbolsTables::symbol_from_frame_data(P, OPERANDS_KIND_IFLD + i);
						WRITE(" %S", K->symbol_name);
					}
					break;
				}
				default: { *E = Inode::error(P, I"cannot write kind", NULL); return; }
					break;
			}
		}
	} else { *E = Inode::error(P, I"cannot write kind", NULL); return; }
	Inter::Symbols::write_annotations(OUT, P, symb);
}

void Inter::Kind::new_instance(inter_symbol *kind_symbol, inter_symbol *inst_name) {
	if (kind_symbol == NULL) return;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return;
	D->W.data[NO_INSTANCES_KIND_IFLD]++;
	inter_symbol *S = Inter::Kind::super(kind_symbol);
	if (S) Inter::Kind::new_instance(S, inst_name);
}

int Inter::Kind::instance_count(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return 0;
	return (int) D->W.data[NO_INSTANCES_KIND_IFLD];
}

int Inter::Kind::constructor(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return 0;
	return (int) D->W.data[CONSTRUCTOR_KIND_IFLD];
}

int Inter::Kind::arity(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return 0;
	return D->W.extent - MIN_EXTENT_KIND_IFR;
}

inter_symbol *Inter::Kind::operand_symbol(inter_symbol *kind_symbol, int i) {
	if (kind_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return NULL;
	if (i >= D->W.extent - MIN_EXTENT_KIND_IFR) return NULL;
	inter_ti CID = D->W.data[OPERANDS_KIND_IFLD + i];
	inter_symbols_table *T = Inter::Packages::scope_of(D);
	return InterSymbolsTables::symbol_from_id(T, CID);
}

inter_data_type *Inter::Kind::data_type(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return NULL;
	return Inter::Types::find_by_ID(D->W.data[DATA_TYPE_KIND_IFLD]);
}

inter_ti Inter::Kind::next_enumerated_value(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return 0;
	return ++(D->W.data[ENUM_RANGE_KIND_IFLD]);
}

inter_symbol *Inter::Kind::super(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return NULL;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return NULL;
	return InterSymbolsTables::symbol_from_frame_data(D, SUPER_KIND_IFLD);
}

int Inter::Kind::is(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return FALSE;
	inter_tree_node *D = Inter::Symbols::definition(kind_symbol);
	if (D == NULL) return FALSE;
	if (D->W.data[ID_IFLD] == KIND_IST) return TRUE;
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
