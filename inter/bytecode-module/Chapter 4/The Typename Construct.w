[Inter::Typename::] The Typename Construct.

Defining the typename construct.

@

@e TYPENAME_IST

=
void Inter::Typename::define(void) {
	inter_construct *IC = InterConstruct::create_construct(TYPENAME_IST, I"typename");
	InterConstruct::defines_symbol_in_fields(IC, DEFN_TYPENAME_IFLD, -1);
	InterConstruct::specify_syntax(IC, I"typename IDENTIFIER TOKEN TOKENS");
	InterConstruct::fix_instruction_length_between(IC,
		MIN_EXTENT_TYPENAME_IFR, UNLIMITED_INSTRUCTION_FRAME_LENGTH);
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Typename::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Typename::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Typename::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Typename::write);
}

@

@d DEFN_TYPENAME_IFLD 2
@d ENUM_RANGE_TYPENAME_IFLD 3
@d NO_INSTANCES_TYPENAME_IFLD 4
@d SUPER_TYPENAME_IFLD 5
@d PERM_LIST_TYPENAME_IFLD 6
@d PLIST_TYPENAME_IFLD 7
@d CONSTRUCTOR_TYPENAME_IFLD 8
@d OPERANDS_TYPENAME_IFLD 9

@d MIN_EXTENT_TYPENAME_IFR 9

=
void Inter::Typename::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, TYPENAME_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *symb = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	inter_semisimple_type_description parsed_description;
	InterTypes::initialise_isstd(&parsed_description);
	inter_symbol *super_s = NULL;
	
	if (Str::eq(ilp->mr.exp[1], I"<=")) {
		super_s = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[2], TYPENAME_IST, E);
		if ((*E == NULL) &&
			(InterTypes::is_enumerated(InterTypes::from_type_name(super_s)) == FALSE))
			{ *E = InterErrors::quoted(I"not a type which can have subtypes", ilp->mr.exp[2], eloc); return; }
		parsed_description.constructor_code = ENUM_ITCONC;
		parsed_description.arity = 0;
	} else if (Str::eq(ilp->mr.exp[1], I"=")) {
		*E = InterTypes::parse_semisimple(ilp->mr.exp[2], InterBookmark::scope(IBM), eloc, &parsed_description);
	} else {
		*E = InterErrors::quoted(I"expected '=' or '<='", ilp->mr.exp[1], eloc);
	}
	
	if (*E == NULL)
		*E = Inter::Typename::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, symb),
			parsed_description.constructor_code,
			(super_s)?(InterSymbolsTable::id_from_symbol_at_bookmark(IBM, super_s)):0,
			parsed_description.arity, parsed_description.operand_TIDs, (inter_ti) ilp->indent_level, eloc);
	InterTypes::dispose_of_isstd(&parsed_description);
}

inter_error_message *Inter::Typename::new(inter_bookmark *IBM, inter_ti SID, inter_ti constructor, inter_ti SUP,
	int arity, inter_ti *operands, inter_ti level, inter_error_location *eloc) {
	if (InterTypes::is_valid_constructor_code(constructor) == FALSE)
		internal_error("constructor out of range");

	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_ti L1 = InterWarehouse::create_node_list(warehouse, InterBookmark::package(IBM));
	inter_ti L2 = InterWarehouse::create_node_list(warehouse, InterBookmark::package(IBM));
	inter_tree_node *P = Inode::new_with_7_data_fields(IBM,
		TYPENAME_IST, SID, 0, 0, SUP, L1, L2,
		constructor, eloc, level);
	if (arity > 0) {
		Inode::extend_instruction_by(P, (inter_ti) arity);
		for (int i=0; i<arity; i++) P->W.instruction[OPERANDS_TYPENAME_IFLD+i] = operands[i];
	}
	inter_error_message *E = Inter::Verify::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::Typename::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PERM_LIST_TYPENAME_IFLD] = grid[P->W.instruction[PERM_LIST_TYPENAME_IFLD]];
	P->W.instruction[PLIST_TYPENAME_IFLD] = grid[P->W.instruction[PLIST_TYPENAME_IFLD]];
}

void Inter::Typename::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.instruction[ENUM_RANGE_TYPENAME_IFLD] != 0) {
		inter_symbol *typename_s = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[DEFN_TYPENAME_IFLD]);
		if ((typename_s == NULL) ||
			(InterTypes::is_enumerated(InterTypes::from_type_name(typename_s)) == FALSE))
			{ *E = Inode::error(P, I"spurious extent in non-enumeration", NULL); return; }
	}
	if (P->W.instruction[SUPER_TYPENAME_IFLD] != 0) {
		*E = Inter::Verify::SID_field(owner, P, SUPER_TYPENAME_IFLD, TYPENAME_IST); if (*E) return;
		inter_symbol *super_s = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[SUPER_TYPENAME_IFLD]);
		if (InterTypes::is_enumerated(InterTypes::from_type_name(super_s)) == FALSE)
			{ *E = Inode::error(P, I"subtype of nonenumerated type", NULL); return; }
	}
	*E = Inter::Verify::constructor_field(P, CONSTRUCTOR_TYPENAME_IFLD); if (*E) return;
	inter_type type = InterTypes::from_constructor_code(P->W.instruction[CONSTRUCTOR_TYPENAME_IFLD]);
	int arity = P->W.extent - MIN_EXTENT_TYPENAME_IFR;
	for (int i=0; i<arity; i++) {
		*E = Inter::Verify::TID_field(owner, P, OPERANDS_TYPENAME_IFLD + i);
		if (*E) return;
	}
	if (InterTypes::arity_is_possible(type, arity) == FALSE) {
		text_stream *err = Str::new();
		WRITE_TO(err, "typename definition has arity %d, which is impossible for ", arity);
		InterTypes::write_type(err, type);
		*E = Inode::error(P, err, NULL);
		return;
	}
}

inter_ti Inter::Typename::permissions_list(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return D->W.instruction[PERM_LIST_TYPENAME_IFLD];
}

inter_ti Inter::Typename::properties_list(inter_symbol *inst_name) {
	if (inst_name == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(inst_name);
	if (D == NULL) return 0;
	return D->W.instruction[PLIST_TYPENAME_IFLD];
}

void Inter::Typename::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *symb = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_TYPENAME_IFLD);
	if (symb) {
		WRITE("typename %S ", InterSymbol::identifier(symb));
		if (P->W.instruction[SUPER_TYPENAME_IFLD]) {
			inter_symbol *super = InterSymbolsTable::symbol_from_ID_at_node(P, SUPER_TYPENAME_IFLD);
			WRITE("<= %S", InterSymbol::identifier(super));
		} else {
			WRITE("= ");
			InterTypes::write_typename_definition(OUT, symb);
		}
	} else { *E = Inode::error(P, I"cannot write typename", NULL); return; }
	SymbolAnnotation::write_annotations(OUT, P, symb);
}

void Inter::Typename::new_instance(inter_symbol *typename_s, inter_symbol *inst_name) {
	if (typename_s == NULL) return;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return;
	D->W.instruction[NO_INSTANCES_TYPENAME_IFLD]++;
	inter_symbol *S = Inter::Typename::super(typename_s);
	if (S) Inter::Typename::new_instance(S, inst_name);
}

int Inter::Typename::instance_count(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return (int) D->W.instruction[NO_INSTANCES_TYPENAME_IFLD];
}

int Inter::Typename::arity(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return D->W.extent - MIN_EXTENT_TYPENAME_IFR;
}

inter_type Inter::Typename::operand_type(inter_symbol *typename_s, int i) {
	if (typename_s == NULL) return InterTypes::unchecked();
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return InterTypes::unchecked();
	if (i >= D->W.extent - MIN_EXTENT_TYPENAME_IFR) return InterTypes::unchecked();
	inter_ti TID = D->W.instruction[OPERANDS_TYPENAME_IFLD + i];
	inter_symbols_table *T = InterPackage::scope_of(D);
	return InterTypes::from_TID(T, TID);
}

inter_ti Inter::Typename::constructor(inter_symbol *typename_s) {
	if (typename_s == NULL) return UNCHECKED_ITCONC;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return UNCHECKED_ITCONC;
	return D->W.instruction[CONSTRUCTOR_TYPENAME_IFLD];
}

inter_ti Inter::Typename::next_enumerated_value(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return ++(D->W.instruction[ENUM_RANGE_TYPENAME_IFLD]);
}

inter_symbol *Inter::Typename::super(inter_symbol *typename_s) {
	if (typename_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(D, SUPER_TYPENAME_IFLD);
}

int Inter::Typename::is(inter_symbol *typename_s) {
	if (typename_s == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return FALSE;
	if (D->W.instruction[ID_IFLD] == TYPENAME_IST) return TRUE;
	return FALSE;
}

int Inter::Typename::is_a(inter_symbol *typename1_s, inter_symbol *typename2_s) {
	inter_type type1 = InterTypes::from_type_name(typename1_s);
	inter_type type2 = InterTypes::from_type_name(typename2_s);
	if ((InterTypes::is_unchecked(type1)) || (InterTypes::is_unchecked(type2))) return TRUE;
	while (typename1_s) {
		if (typename1_s == typename2_s) return TRUE;
		typename1_s = Inter::Typename::super(typename1_s);
	}
	return FALSE;
}
