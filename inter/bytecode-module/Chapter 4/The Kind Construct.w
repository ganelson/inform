[Inter::Kind::] The Kind Construct.

Defining the kind construct.

@

@e KIND_IST

=
void Inter::Kind::define(void) {
	inter_construct *IC = InterConstruct::create_construct(KIND_IST, I"kind");
	InterConstruct::specify_syntax(IC, I"kind IDENTIFIER TOKENS");
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Kind::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Kind::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Kind::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Kind::write);
}

@

@d DEFN_KIND_IFLD 2
@d ENUM_RANGE_KIND_IFLD 3
@d NO_INSTANCES_KIND_IFLD 4
@d SUPER_KIND_IFLD 5
@d PERM_LIST_KIND_IFLD 6
@d PLIST_KIND_IFLD 7
@d CONSTRUCTOR_KIND_IFLD 8
@d OPERANDS_KIND_IFLD 9

@d MIN_EXTENT_KIND_IFR 9

=
void Inter::Kind::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, KIND_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *symb = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	inter_semisimple_type_description parsed_description;
	InterTypes::initialise_isstd(&parsed_description);
	match_results mr2 = Regexp::create_mr();
	inter_symbol *super_kind = NULL;
	if (Regexp::match(&mr2, ilp->mr.exp[1], L"<= (%i+)")) {
		super_kind = TextualInter::find_symbol(IBM, eloc, mr2.exp[0], KIND_IST, E);
		if ((*E == NULL) &&
			(InterTypes::is_enumerated(InterTypes::from_type_name(super_kind)) == FALSE))
			{ *E = Inter::Errors::quoted(I"not a kind which can have subkinds", mr2.exp[0], eloc); return; }
		parsed_description.constructor_code = ENUM_ITCONC;
		parsed_description.arity = 0;
	} else {
		*E = InterTypes::parse_semisimple(ilp->mr.exp[1], InterBookmark::scope(IBM), eloc, &parsed_description);
	}
	Regexp::dispose_of(&mr2);
	
	if (*E == NULL)
		*E = Inter::Kind::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, symb),
			parsed_description.constructor_code,
			(super_kind)?(InterSymbolsTable::id_from_symbol_at_bookmark(IBM, super_kind)):0,
			parsed_description.arity, parsed_description.operand_TIDs, (inter_ti) ilp->indent_level, eloc);
	InterTypes::dispose_of_isstd(&parsed_description);
}

inter_error_message *Inter::Kind::new(inter_bookmark *IBM, inter_ti SID, inter_ti constructor, inter_ti SUP,
	int arity, inter_ti *operands, inter_ti level, inter_error_location *eloc) {
	if (InterTypes::is_valid_constructor_code(constructor) == FALSE)
		internal_error("constructor out of range");

	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_ti L1 = InterWarehouse::create_node_list(warehouse, InterBookmark::package(IBM));
	inter_ti L2 = InterWarehouse::create_node_list(warehouse, InterBookmark::package(IBM));
	inter_tree_node *P = Inode::new_with_7_data_fields(IBM,
		KIND_IST, SID, 0, 0, SUP, L1, L2,
		constructor, eloc, level);
	if (arity > 0) {
		Inode::extend_instruction_by(P, (inter_ti) arity);
		for (int i=0; i<arity; i++) P->W.instruction[OPERANDS_KIND_IFLD+i] = operands[i];
	}
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Kind::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PERM_LIST_KIND_IFLD] = grid[P->W.instruction[PERM_LIST_KIND_IFLD]];
	P->W.instruction[PLIST_KIND_IFLD] = grid[P->W.instruction[PLIST_KIND_IFLD]];
}

void Inter::Kind::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent < MIN_EXTENT_KIND_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_KIND_IFLD); if (*E) return;
	if (P->W.instruction[ENUM_RANGE_KIND_IFLD] != 0) {
		inter_symbol *the_kind = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[DEFN_KIND_IFLD]);
		if ((the_kind == NULL) ||
			(InterTypes::is_enumerated(InterTypes::from_type_name(the_kind)) == FALSE))
			{ *E = Inode::error(P, I"spurious extent in non-enumeration", NULL); return; }
	}
	if (P->W.instruction[SUPER_KIND_IFLD] != 0) {
		*E = Inter::Verify::symbol(owner, P, P->W.instruction[SUPER_KIND_IFLD], KIND_IST); if (*E) return;
		inter_symbol *super_kind = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[SUPER_KIND_IFLD]);
		if (InterTypes::is_enumerated(InterTypes::from_type_name(super_kind)) == FALSE)
			{ *E = Inode::error(P, I"subkind of nonenumerated kind", NULL); return; }
	}
	*E = Inter::Verify::constructor_code(P, CONSTRUCTOR_KIND_IFLD); if (*E) return;
	int arity = P->W.extent - MIN_EXTENT_KIND_IFR;
	switch (P->W.instruction[CONSTRUCTOR_KIND_IFLD]) {
		case EQUATED_ITCONC:
			if (arity != 1) { *E = Inode::error(P, I"wrong equated arity", NULL); return; }
			if (P->W.instruction[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no equated kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD]); if (*E) return;
			break;
		case LIST_ITCONC:
		case RULEBOOK_ITCONC:
			if (arity != 1) { *E = Inode::error(P, I"wrong list arity", NULL); return; }
			if (P->W.instruction[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD]); if (*E) return;
			break;
		case COLUMN_ITCONC: if (arity != 1) { *E = Inode::error(P, I"wrong col arity", NULL); return; }
			if (P->W.instruction[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD]); if (*E) return;
			break;
		case DESCRIPTION_ITCONC: if (arity != 1) { *E = Inode::error(P, I"wrong desc arity", NULL); return; }
			if (P->W.instruction[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD]); if (*E) return;
			break;
		case RELATION_ITCONC: if (arity != 2) { *E = Inode::error(P, I"wrong relation arity", NULL); return; }
			if (P->W.instruction[OPERANDS_KIND_IFLD] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD]); if (*E) return;
			if (P->W.instruction[OPERANDS_KIND_IFLD+1] == 0) { *E = Inode::error(P, I"no listed kind", NULL); return; }
			*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD+1]); if (*E) return;
			break;
		case FUNCTION_ITCONC:
		case RULE_ITCONC:
			if (arity < 2) { *E = Inode::error(P, I"function arity too low", NULL); return; }
			for (int i=0; i<arity; i++) {
				if (P->W.instruction[OPERANDS_KIND_IFLD + i] == 0) {
					if (!(((i == 0) && (arity == 2)) || (i == arity - 1)))
						{ *E = Inode::error(P, I"no listed kind", NULL); return; }
				} else {
					*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD + i]);
					if (*E) return;
				}
			}
			break;
		case STRUCT_ITCONC:
			if (arity == 0) { *E = Inode::error(P, I"struct arity too low", NULL); return; }
			for (int i=0; i<arity; i++) {
				*E = Inter::Verify::TID(owner, P, P->W.instruction[OPERANDS_KIND_IFLD + i]);
				if (*E) return;
			}
			break;
		default: if (arity != 0) {
			WRITE_TO(STDERR, "constructor is %08x\n", P->W.instruction[CONSTRUCTOR_KIND_IFLD]);
			*E = Inode::error(P, I"spurious kc operand", NULL); return; }
			break;
	}
}

inter_ti Inter::Kind::permissions_list(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return 0;
	return D->W.instruction[PERM_LIST_KIND_IFLD];
}

inter_ti Inter::Kind::properties_list(inter_symbol *inst_name) {
	if (inst_name == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(inst_name);
	if (D == NULL) return 0;
	return D->W.instruction[PLIST_KIND_IFLD];
}

void Inter::Kind::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *symb = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_KIND_IFLD);
	if (symb) {
		WRITE("kind %S ", InterSymbol::identifier(symb));
		if (P->W.instruction[SUPER_KIND_IFLD]) {
			inter_symbol *super = InterSymbolsTable::symbol_from_ID_at_node(P, SUPER_KIND_IFLD);
			WRITE("<= %S", InterSymbol::identifier(super));
		} else {
			InterTypes::write_type_name_definition(OUT, symb);
		}
	} else { *E = Inode::error(P, I"cannot write kind", NULL); return; }
	SymbolAnnotation::write_annotations(OUT, P, symb);
}

void Inter::Kind::new_instance(inter_symbol *kind_symbol, inter_symbol *inst_name) {
	if (kind_symbol == NULL) return;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return;
	D->W.instruction[NO_INSTANCES_KIND_IFLD]++;
	inter_symbol *S = Inter::Kind::super(kind_symbol);
	if (S) Inter::Kind::new_instance(S, inst_name);
}

int Inter::Kind::instance_count(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return 0;
	return (int) D->W.instruction[NO_INSTANCES_KIND_IFLD];
}

int Inter::Kind::arity(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return 0;
	return D->W.extent - MIN_EXTENT_KIND_IFR;
}

inter_type Inter::Kind::operand_type(inter_symbol *kind_symbol, int i) {
	if (kind_symbol == NULL) return InterTypes::untyped();
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return InterTypes::untyped();
	if (i >= D->W.extent - MIN_EXTENT_KIND_IFR) return InterTypes::untyped();
	inter_ti TID = D->W.instruction[OPERANDS_KIND_IFLD + i];
	inter_symbols_table *T = InterPackage::scope_of(D);
	return InterTypes::from_TID(T, TID);
}

inter_ti Inter::Kind::constructor(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return UNCHECKED_ITCONC;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return UNCHECKED_ITCONC;
	return D->W.instruction[CONSTRUCTOR_KIND_IFLD];
}

inter_ti Inter::Kind::next_enumerated_value(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return 0;
	return ++(D->W.instruction[ENUM_RANGE_KIND_IFLD]);
}

inter_symbol *Inter::Kind::super(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(D, SUPER_KIND_IFLD);
}

int Inter::Kind::is(inter_symbol *kind_symbol) {
	if (kind_symbol == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(kind_symbol);
	if (D == NULL) return FALSE;
	if (D->W.instruction[ID_IFLD] == KIND_IST) return TRUE;
	return FALSE;
}

int Inter::Kind::is_a(inter_symbol *K1, inter_symbol *K2) {
	inter_type type1 = InterTypes::from_type_name(K1);
	inter_type type2 = InterTypes::from_type_name(K2);
	if ((InterTypes::is_untyped(type1)) || (InterTypes::is_untyped(type2))) return TRUE;
	while (K1) {
		if (K1 == K2) return TRUE;
		K1 = Inter::Kind::super(K1);
	}
	return FALSE;
}
