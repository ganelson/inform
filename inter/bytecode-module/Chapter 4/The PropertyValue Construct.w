[PropertyValueInstruction::] The PropertyValue Construct.

Defining the propertyvalue construct.

@


=
void PropertyValueInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PROPERTYVALUE_IST, I"propertyvalue");
	InterInstruction::specify_syntax(IC, I"propertyvalue IDENTIFIER IDENTIFIER = TOKENS");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_PVAL_IFR, EXTENT_PVAL_IFR);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PropertyValueInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PropertyValueInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PropertyValueInstruction::write);
}

@

@d PROP_PVAL_IFLD 2
@d OWNER_PVAL_IFLD 3
@d DVAL1_PVAL_IFLD 4
@d DVAL2_PVAL_IFLD 5

@d EXTENT_PVAL_IFR 6

=
void PropertyValueInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *prop_name = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[0], PROPERTY_IST, E);
	if (*E) return;
	inter_symbol *owner_name = PropertyValueInstruction::parse_owner(eloc, InterBookmark::scope(IBM), ilp->mr.exp[1], E);
	if (*E) return;

	inter_ti plist_ID;
	if (TypenameInstruction::is(owner_name)) plist_ID = TypenameInstruction::properties_list(owner_name);
	else plist_ID = InstanceInstruction::properties_list(owner_name);
	inter_node_list *FL = InterWarehouse::get_node_list(InterBookmark::warehouse(IBM), plist_ID);
	if (FL == NULL) internal_error("no properties list");

	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_X = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PVAL_IFLD);
		if (prop_X == prop_name)
			{ *E = InterErrors::quoted(I"property already given", ilp->mr.exp[0], eloc); return; }
	}

	inter_type val_type = InterTypes::of_symbol(prop_name);
	inter_pair con_val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, val_type, ilp->mr.exp[2], &con_val);
	if (*E) return;

	*E = PropertyValueInstruction::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prop_name), InterSymbolsTable::id_from_symbol_at_bookmark(IBM, owner_name),
		con_val, (inter_ti) ilp->indent_level, eloc);
}

inter_symbol *PropertyValueInstruction::parse_owner(inter_error_location *eloc, inter_symbols_table *T, text_stream *name, inter_error_message **E) {
	*E = NULL;
	inter_symbol *symb = InterSymbolsTable::symbol_from_name(T, name);
	if (symb == NULL) { *E = InterErrors::quoted(I"no such symbol", name, eloc); return NULL; }
	inter_tree_node *D = InterSymbol::definition(symb);
	if (D == NULL) { *E = InterErrors::quoted(I"undefined symbol", name, eloc); return NULL; }
	if ((D->W.instruction[ID_IFLD] != TYPENAME_IST) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST)) { *E = InterErrors::quoted(I"symbol of wrong type", name, eloc); return NULL; }
	return symb;
}

int PropertyValueInstruction::permitted(inter_tree_node *F, inter_package *pack, inter_symbol *owner, inter_symbol *prop_name) {
	inter_ti plist_ID;
	if (TypenameInstruction::is(owner)) plist_ID = TypenameInstruction::permissions_list(owner);
	else plist_ID = InstanceInstruction::permissions_list(owner);
	inter_node_list *FL = Inode::ID_to_frame_list(F, plist_ID);
	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		inter_symbol *prop_allowed = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
		if (prop_allowed == prop_name)
			return TRUE;
	}
	inter_symbol *inst_kind;
	if (TypenameInstruction::is(owner)) inst_kind = TypenameInstruction::super(owner);
	else inst_kind = InstanceInstruction::kind_of(owner);
	while (inst_kind) {
		inter_node_list *FL =
			Inode::ID_to_frame_list(F, TypenameInstruction::permissions_list(inst_kind));
		if (FL == NULL) internal_error("no permissions list");
		inter_tree_node *X;
		LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
			inter_symbol *prop_allowed = InterSymbolsTable::symbol_from_ID_at_node(X, PROP_PERM_IFLD);
			if (prop_allowed == prop_name)
				return TRUE;
		}
		inst_kind = TypenameInstruction::super(inst_kind);
	}
	return FALSE;
}

inter_error_message *PropertyValueInstruction::new(inter_bookmark *IBM, inter_ti PID, inter_ti OID,
	inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM, PROPERTYVALUE_IST,
		PID, OID, InterValuePairs::to_word1(val), InterValuePairs::to_word2(val), eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void PropertyValueInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, PROP_PVAL_IFLD, PROPERTY_IST); if (*E) return;
	*E = VerifyingInter::POID_field(owner, P, OWNER_PVAL_IFLD); if (*E) return;

	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[PROP_PVAL_IFLD]);;
	inter_symbol *owner_name = InterSymbolsTable::symbol_from_ID(InterPackage::scope(owner), P->W.instruction[OWNER_PVAL_IFLD]);;

	if (PropertyValueInstruction::permitted(P, owner, owner_name, prop_name) == FALSE) {
		text_stream *err = Str::new();
		WRITE_TO(err, "no permission for '%S' have this property", InterSymbol::identifier(owner_name));
		*E = Inode::error(P, err, InterSymbol::identifier(prop_name)); return;
	}

	inter_ti plist_ID;
	if (TypenameInstruction::is(owner_name)) plist_ID = TypenameInstruction::properties_list(owner_name);
	else plist_ID = InstanceInstruction::properties_list(owner_name);

	inter_node_list *FL = Inode::ID_to_frame_list(P, plist_ID);
	if (FL == NULL) internal_error("no properties list");

	inter_tree_node *X;
	LOOP_THROUGH_INTER_NODE_LIST(X, FL) {
		if (X->W.instruction[PROP_PVAL_IFLD] == P->W.instruction[PROP_PVAL_IFLD]) { *E = Inode::error(P, I"duplicate property value", NULL); return; }
		if (X->W.instruction[OWNER_PVAL_IFLD] != P->W.instruction[OWNER_PVAL_IFLD]) { *E = Inode::error(P, I"instance property list malformed", NULL); return; }
	}

	InterNodeList::add(FL, P);
}

void PropertyValueInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *prop_name = InterSymbolsTable::symbol_from_ID_at_node(P, PROP_PVAL_IFLD);
	inter_symbol *owner_name = InterSymbolsTable::symbol_from_ID_at_node(P, OWNER_PVAL_IFLD);
	if ((prop_name) && (owner_name)) {
		WRITE("propertyvalue %S %S = ", InterSymbol::identifier(prop_name), InterSymbol::identifier(owner_name));
		TextualInter::write_pair(OUT, P, InterValuePairs::get(P, DVAL1_PVAL_IFLD), FALSE);
	} else { *E = Inode::error(P, I"cannot write propertyvalue", NULL); return; }
}
