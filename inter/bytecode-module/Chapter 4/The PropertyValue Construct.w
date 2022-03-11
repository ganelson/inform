[PropertyValueInstruction::] The PropertyValue Construct.

Defining the propertyvalue construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PropertyValueInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PROPERTYVALUE_IST, I"propertyvalue");
	InterInstruction::specify_syntax(IC, I"propertyvalue IDENTIFIER IDENTIFIER = TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 6, 6);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PropertyValueInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PropertyValueInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PropertyValueInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |propertyvalue| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d PROP_PVAL_IFLD 2
@d OWNER_PVAL_IFLD 3
@d VAL1_PVAL_IFLD 4
@d VAL2_PVAL_IFLD 5

=
inter_error_message *PropertyValueInstruction::new(inter_bookmark *IBM,
	inter_symbol *prop_s, inter_symbol *owner_s, inter_pair val, inter_ti level,
	inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, PROPERTYVALUE_IST,
		/* PROP_PVAL_IFLD: */  InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prop_s),
		/* OWNER_PVAL_IFLD: */ InterSymbolsTable::id_from_symbol_at_bookmark(IBM, owner_s),
		/* VAL1_PVAL_IFLD: */  InterValuePairs::to_word1(val),
		/* VAL2_PVAL_IFLD: */  InterValuePairs::to_word2(val),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification begins with sanity checks, but then also adds the new property
value to the list of properties of the owner.

=
void PropertyValueInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, PROP_PVAL_IFLD, PROPERTY_IST);
	if (*E) return;
	*E = VerifyingInter::POID_field(owner, P, OWNER_PVAL_IFLD);
	if (*E) return;

	inter_symbol *prop_s = PropertyValueInstruction::property(P);
	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_PVAL_IFLD, InterTypes::unchecked());
	if (*E) return;

	inter_symbol *owner_s = PropertyValueInstruction::owner(P);

	if (PropertyValueInstruction::permitted(P, owner, owner_s, prop_s) == FALSE) {
		text_stream *err = Str::new();
		WRITE_TO(err, "no permission for '%S' have this property",
			InterSymbol::identifier(owner_s));
		*E = Inode::error(P, err, InterSymbol::identifier(prop_s));
		return;
	}

	inter_node_list *FL;
	if (TypenameInstruction::is(owner_s))
		FL = TypenameInstruction::properties_list(owner_s);
	else
		FL = InstanceInstruction::properties_list(owner_s);
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL)
		if (PropertyValueInstruction::property(X) == prop_s) {
			*E = Inode::error(P, I"duplicate property value", NULL);
			return;
		}

	InterNodeList::add(FL, P);
}

int PropertyValueInstruction::permitted(inter_tree_node *F, inter_package *pack,
	inter_symbol *owner, inter_symbol *prop_s) {
	if (InstanceInstruction::is(owner)) {
		inter_node_list *FL = InstanceInstruction::permissions_list(owner);
		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, FL)
			if (PermissionInstruction::property(X) == prop_s)
				return TRUE;
		owner = InstanceInstruction::typename(owner);
	}
	while (owner) {
		inter_node_list *FL = TypenameInstruction::permissions_list(owner);
		if (FL == NULL) internal_error("no permissions list");
		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, FL)
			if (PermissionInstruction::property(X) == prop_s)
				return TRUE;
		owner = TypenameInstruction::super(owner);
	}
	return FALSE;
}

@h Creating from textual Inter syntax.

=
void PropertyValueInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *prop_name = ilp->mr.exp[0], *owner_name = ilp->mr.exp[1];
	inter_symbol *prop_s = TextualInter::find_symbol(IBM, eloc, prop_name, PROPERTY_IST, E);
	if (*E) return;
	inter_symbol *owner_s = PropertyValueInstruction::parse_owner(eloc,
		InterBookmark::scope(IBM), owner_name, E);
	if (*E) return;

	inter_type val_type = InterTypes::of_symbol(prop_s);
	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, val_type, ilp->mr.exp[2], &val);
	if (*E) return;

	*E = PropertyValueInstruction::new(IBM, prop_s, owner_s, val,
		(inter_ti) ilp->indent_level, eloc);
}

inter_symbol *PropertyValueInstruction::parse_owner(inter_error_location *eloc,
	inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) {
		*E = InterErrors::quoted(I"no such symbol", name, eloc);
		return NULL;
	}
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) {
		*E = InterErrors::quoted(I"undefined symbol", name, eloc);
		return NULL;
	}
	if ((D->W.instruction[ID_IFLD] != TYPENAME_IST) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST)) {
		*E = InterErrors::quoted(I"owner not an instance or enumerated type", name, eloc);
		return NULL;
	}
	return symb;
}

@h Writing to textual Inter syntax.

=
void PropertyValueInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *prop_s = PropertyValueInstruction::property(P);
	inter_symbol *owner_s = PropertyValueInstruction::owner(P);
	WRITE("propertyvalue %S %S = ",
		InterSymbol::identifier(prop_s), InterSymbol::identifier(owner_s));
	TextualInter::write_pair(OUT, P, PropertyValueInstruction::value(P), FALSE);
}

@h Access functions.

=
inter_symbol *PropertyValueInstruction::property(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != PROPERTYVALUE_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, PROP_PVAL_IFLD);
}

inter_symbol *PropertyValueInstruction::owner(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != PROPERTYVALUE_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, OWNER_PVAL_IFLD);
}

inter_pair PropertyValueInstruction::value(inter_tree_node *P) {
	if (P == NULL) return InterValuePairs::undef();
	if (P->W.instruction[ID_IFLD] != PROPERTYVALUE_IST) return InterValuePairs::undef();
	return InterValuePairs::get(P, VAL1_PVAL_IFLD);
}
