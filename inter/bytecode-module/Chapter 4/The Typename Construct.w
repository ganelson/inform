[TypenameInstruction::] The Typename Construct.

Defining the typename construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void TypenameInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(TYPENAME_IST, I"typename");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_TYPENAME_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"typename IDENTIFIER TOKEN TOKENS");
	InterInstruction::data_extent_at_least(IC, 7);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, TypenameInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, TypenameInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, TypenameInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, TypenameInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |typename| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by these. The eventual
length is flexible: there can be any number of operands from 0 upwards.

@d DEFN_TYPENAME_IFLD         (DATA_IFLD + 0)
@d ENUM_RANGE_TYPENAME_IFLD   (DATA_IFLD + 1)
@d NO_INSTANCES_TYPENAME_IFLD (DATA_IFLD + 2)
@d SUPER_TYPENAME_IFLD        (DATA_IFLD + 3)
@d PERM_LIST_TYPENAME_IFLD    (DATA_IFLD + 4)
@d PLIST_TYPENAME_IFLD        (DATA_IFLD + 5)
@d CONSTRUCTOR_TYPENAME_IFLD  (DATA_IFLD + 6)
@d OPERANDS_TYPENAME_IFLD     (DATA_IFLD + 7)

=
inter_error_message *TypenameInstruction::new(inter_bookmark *IBM, inter_symbol *typename_s,
	inter_ti constructor, inter_symbol *super_s,
	int arity, inter_ti *operands, inter_ti level, inter_error_location *eloc) {
	inter_ti super_SID = 0;
	if (super_s) super_SID = InterSymbolsTable::id_at_bookmark(IBM, super_s);
	inter_package *pack = InterBookmark::package(IBM);
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_tree_node *P = Inode::new_with_7_data_fields(IBM, TYPENAME_IST,
		/* DEFN_TYPENAME_IFLD: */         InterSymbolsTable::id_at_bookmark(IBM, typename_s),
		/* ENUM_RANGE_TYPENAME_IFLD: */   0,
		/* NO_INSTANCES_TYPENAME_IFLD: */ 0,
		/* SUPER_TYPENAME_IFLD: */        super_SID,
		/* PERM_LIST_TYPENAME_IFLD: */    InterWarehouse::create_node_list(warehouse, pack),
		/* PLIST_TYPENAME_IFLD: */        InterWarehouse::create_node_list(warehouse, pack),
		/* CONSTRUCTOR_TYPENAME_IFLD: */  constructor,
		eloc, level);
	if (arity > 0) {
		Inode::extend_instruction_by(P, (inter_ti) arity);
		for (int i=0; i<arity; i++)
			P->W.instruction[OPERANDS_TYPENAME_IFLD+i] = operands[i];
	}
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void TypenameInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PERM_LIST_TYPENAME_IFLD] = grid[P->W.instruction[PERM_LIST_TYPENAME_IFLD]];
	P->W.instruction[PLIST_TYPENAME_IFLD] = grid[P->W.instruction[PLIST_TYPENAME_IFLD]];
}

@ Verification consists only of sanity checks.

=
void TypenameInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	inter_symbol *typename_s = TypenameInstruction::typename(P);
	if ((P->W.instruction[ENUM_RANGE_TYPENAME_IFLD] > 0) &&
		(InterTypes::is_enumerated(InterTypes::from_type_name(typename_s)) == FALSE)) {
		*E = Inode::error(P, I"spurious extent in non-enumeration", NULL);
		return;
	}
	if (P->W.instruction[SUPER_TYPENAME_IFLD] != 0) {
		*E = VerifyingInter::SID_field(owner, P, SUPER_TYPENAME_IFLD, TYPENAME_IST);
		if (*E) return;
		inter_symbol *super_s = TypenameInstruction::super(typename_s);
		if (InterTypes::is_enumerated(InterTypes::from_type_name(super_s)) == FALSE) {
			*E = Inode::error(P, I"subtype of nonenumerated type", NULL);
			return;
		}
	}
	*E = VerifyingInter::node_list_field(owner, P, PERM_LIST_TYPENAME_IFLD);
	if (*E) return;
	*E = VerifyingInter::node_list_field(owner, P, PLIST_TYPENAME_IFLD);
	if (*E) return;
	*E = VerifyingInter::constructor_field(P, CONSTRUCTOR_TYPENAME_IFLD);
	if (*E) return;
	inter_type type =
		InterTypes::from_constructor_code(TypenameInstruction::constructor(typename_s));
	int arity = P->W.extent - OPERANDS_TYPENAME_IFLD;
	for (int i=0; i<arity; i++) {
		*E = VerifyingInter::TID_field(owner, P, OPERANDS_TYPENAME_IFLD + i);
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

@h Creating from textual Inter syntax.

=
void TypenameInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *typename_text = ilp->mr.exp[0];
	text_stream *operator_text = ilp->mr.exp[1];
	text_stream *defn_text = ilp->mr.exp[2];
	inter_symbol *symb = 
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), typename_text, E);
	if (*E) return;

	inter_semisimple_type_description parsed_description;
	InterTypes::initialise_isstd(&parsed_description);
	inter_symbol *super_s = NULL;
	
	if (Str::eq(operator_text, I"<=")) {
		super_s = TextualInter::find_symbol(IBM, eloc, defn_text, TYPENAME_IST, E);
		if ((*E == NULL) &&
			(InterTypes::is_enumerated(InterTypes::from_type_name(super_s)) == FALSE)) {
				*E = InterErrors::quoted(I"not a type which can have subtypes", defn_text, eloc);
				return;
		}
		parsed_description.constructor_code = ENUM_ITCONC;
		parsed_description.arity = 0;
	} else if (Str::eq(operator_text, I"=")) {
		*E = InterTypes::parse_semisimple(ilp->mr.exp[2], InterBookmark::scope(IBM),
			eloc, &parsed_description);
	} else {
		*E = InterErrors::quoted(I"expected '=' or '<='", operator_text, eloc);
	}
	
	if (*E == NULL)
		*E = TypenameInstruction::new(IBM, symb, parsed_description.constructor_code,
			super_s, parsed_description.arity, parsed_description.operand_TIDs,
			(inter_ti) ilp->indent_level, eloc);
	InterTypes::dispose_of_isstd(&parsed_description);
}

@h Writing to textual Inter syntax.

=
void TypenameInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *typename_s = TypenameInstruction::typename(P);
	WRITE("typename %S ", InterSymbol::identifier(typename_s));
	inter_symbol *super = TypenameInstruction::super(typename_s);
	if (super) {
		WRITE("<= ");
		TextualInter::write_symbol_from(OUT, P, SUPER_TYPENAME_IFLD);
	} else {
		WRITE("= ");
		InterTypes::write_typename_definition(OUT, typename_s);
	}
}

@h Access functions.

=
inter_symbol *TypenameInstruction::typename(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, TYPENAME_IST)) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_TYPENAME_IFLD);
}

inter_symbol *TypenameInstruction::super(inter_symbol *typename_s) {
	if (typename_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(D, SUPER_TYPENAME_IFLD);
}

inter_node_list *TypenameInstruction::permissions_list(inter_symbol *typename_s) {
	if (typename_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return NULL;
	return Inode::ID_to_frame_list(D, D->W.instruction[PERM_LIST_TYPENAME_IFLD]);
}

inter_node_list *TypenameInstruction::properties_list(inter_symbol *typename_s) {
	if (typename_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return NULL;
	return Inode::ID_to_frame_list(D, D->W.instruction[PLIST_TYPENAME_IFLD]);
}

@ The definition of the semisimple type:

=
inter_ti TypenameInstruction::constructor(inter_symbol *typename_s) {
	if (typename_s == NULL) return UNCHECKED_ITCONC;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return UNCHECKED_ITCONC;
	return D->W.instruction[CONSTRUCTOR_TYPENAME_IFLD];
}

int TypenameInstruction::arity(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return D->W.extent - OPERANDS_TYPENAME_IFLD;
}

inter_type TypenameInstruction::operand_type(inter_symbol *typename_s, int i) {
	if (typename_s == NULL) return InterTypes::unchecked();
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return InterTypes::unchecked();
	if (i >= D->W.extent - OPERANDS_TYPENAME_IFLD) return InterTypes::unchecked();
	inter_ti TID = D->W.instruction[OPERANDS_TYPENAME_IFLD + i];
	inter_symbols_table *T = InterPackage::scope_of(D);
	return InterTypes::from_TID(T, TID);
}

@ Enumeration counter, relevant only when the typename is enumerated:

=
inter_ti TypenameInstruction::next_enumerated_value(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return ++(D->W.instruction[ENUM_RANGE_TYPENAME_IFLD]);
}

@ For an enumerated typename, if a new instance is created, this is called:

=
void TypenameInstruction::new_instance(inter_symbol *typename_s, inter_symbol *inst_name) {
	if (typename_s == NULL) return;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return;
	D->W.instruction[NO_INSTANCES_TYPENAME_IFLD]++;
	inter_symbol *S = TypenameInstruction::super(typename_s);
	if (S) TypenameInstruction::new_instance(S, inst_name);
}

int TypenameInstruction::instance_count(inter_symbol *typename_s) {
	if (typename_s == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (D == NULL) return 0;
	return (int) D->W.instruction[NO_INSTANCES_TYPENAME_IFLD];
}

@h Two tests.

=
int TypenameInstruction::is(inter_symbol *typename_s) {
	if (typename_s == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(typename_s);
	if (Inode::is(D, TYPENAME_IST)) return TRUE;
	return FALSE;
}

int TypenameInstruction::is_a(inter_symbol *typename1_s, inter_symbol *typename2_s) {
	inter_type type1 = InterTypes::from_type_name(typename1_s);
	inter_type type2 = InterTypes::from_type_name(typename2_s);
	if ((InterTypes::is_unchecked(type1)) || (InterTypes::is_unchecked(type2)))
		return TRUE;
	while (typename1_s) {
		if (typename1_s == typename2_s) return TRUE;
		typename1_s = TypenameInstruction::super(typename1_s);
	}
	return FALSE;
}
