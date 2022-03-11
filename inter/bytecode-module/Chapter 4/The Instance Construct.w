[InstanceInstruction::] The Instance Construct.

Defining the instance construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void InstanceInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(INSTANCE_IST, I"instance");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_INST_IFLD, TYPE_INST_IFLD);
	InterInstruction::specify_syntax(IC, I"instance IDENTIFIER TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 8, 8);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, InstanceInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, InstanceInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, InstanceInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, InstanceInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |instance| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d DEFN_INST_IFLD 2
@d TYPE_INST_IFLD 3
@d VAL1_INST_IFLD 4
@d VAL2_INST_IFLD 5
@d PROP_LIST_INST_IFLD 6
@d PERM_LIST_INST_IFLD 7

=
inter_error_message *InstanceInstruction::new(inter_bookmark *IBM, inter_symbol *S,
	inter_symbol *typename_s, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_tree_node *P = Inode::new_with_6_data_fields(IBM, INSTANCE_IST,
		/* DEFN_INST_IFLD: */      InterSymbolsTable::id_from_symbol_at_bookmark(IBM, S),
		/* TYPE_INST_IFLD: */      InterSymbolsTable::id_from_symbol_at_bookmark(IBM, typename_s),
		/* VAL1_INST_IFLD: */      InterValuePairs::to_word1(val),
		/* VAL2_INST_IFLD: */      InterValuePairs::to_word2(val),
		/* PROP_LIST_INST_IFLD: */ InterWarehouse::create_node_list(warehouse, pack),
		/* PERM_LIST_INST_IFLD: */ InterWarehouse::create_node_list(warehouse, pack),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void InstanceInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PROP_LIST_INST_IFLD] = grid[P->W.instruction[PROP_LIST_INST_IFLD]];
	P->W.instruction[PERM_LIST_INST_IFLD] = grid[P->W.instruction[PERM_LIST_INST_IFLD]];
}

@ Verification does more than making sanity checks: it also calculates and sets
the enumerated value of the instance (if it is not already set), and notifies
the typename_s that it has a new instance.

=
void InstanceInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, TYPE_INST_IFLD, TYPENAME_IST);
	if (*E) return;
	*E = VerifyingInter::node_list_field(owner, P, PROP_LIST_INST_IFLD);
	if (*E) return;
	*E = VerifyingInter::node_list_field(owner, P, PERM_LIST_INST_IFLD);
	if (*E) return;

	inter_symbol *typename_s = InterSymbolsTable::symbol_from_ID_at_node(P, TYPE_INST_IFLD);
	inter_type inst_type = InterTypes::from_type_name(typename_s);
	if (InterTypes::is_enumerated(inst_type)) {
		if (InterValuePairs::is_undef(InterValuePairs::get(P, VAL1_INST_IFLD)))
			InterValuePairs::set(P, VAL1_INST_IFLD,
				InterValuePairs::number(TypenameInstruction::next_enumerated_value(typename_s)));
	} else {
		*E = Inode::error(P, I"not a kind which has instances", NULL); return;
	}

	*E = VerifyingInter::data_pair_fields(owner, P, VAL1_INST_IFLD, inst_type);
	if (*E) return;

	inter_symbol *instance_s = InstanceInstruction::instance(P);
	TypenameInstruction::new_instance(typename_s, instance_s);
}

@h Creating from textual Inter syntax.

=
void InstanceInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *instance_s =
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	inter_symbol *typename_s = NULL;
	inter_pair val = InterValuePairs::undef();
	@<Parse the typename and enumerated value, if given@>;
	if (*E) return;

	inter_type inst_type = InterTypes::from_type_name(typename_s);
	if (InterTypes::is_enumerated(inst_type) == FALSE) {
		*E = InterErrors::quoted(I"not a kind which has instances", ilp->mr.exp[1], eloc);
		return;
	}

	*E = InstanceInstruction::new(IBM, instance_s, typename_s, val,
		(inter_ti) ilp->indent_level, eloc);
}

@<Parse the typename and enumerated value, if given@> =
	text_stream *ktext = ilp->mr.exp[1], *vtext = NULL;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, ktext, L"(%i+) = (%c+)")) {
		ktext = mr.exp[0]; vtext = mr.exp[1];
	}
	typename_s = TextualInter::find_symbol(IBM, eloc, ktext, TYPENAME_IST, E);
	if ((*E == NULL) && (vtext)) {
		*E = TextualInter::parse_pair(ilp->line, eloc, IBM, InterTypes::unchecked(),
			vtext, &val);
		if (*E) return;
	}
	Regexp::dispose_of(&mr);

@h Writing to textual Inter syntax.

=
void InstanceInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *instance_s = InstanceInstruction::instance(P);
	inter_symbol *typename_s = InterSymbolsTable::symbol_from_ID_at_node(P, TYPE_INST_IFLD);
	WRITE("instance %S %S = ", InterSymbol::identifier(instance_s), InterSymbol::identifier(typename_s));
	TextualInter::write_pair(OUT, P, InterValuePairs::get(P, VAL1_INST_IFLD), FALSE);
	SymbolAnnotation::write_annotations(OUT, P, instance_s);
}

@h Access functions.

=
inter_symbol *InstanceInstruction::instance(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (P->W.instruction[ID_IFLD] != INSTANCE_IST) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_INST_IFLD);
}

int InstanceInstruction::is(inter_symbol *instance_s) {
	if (instance_s == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(instance_s);
	if (D == NULL) return FALSE;
	if (D->W.instruction[ID_IFLD] == INSTANCE_IST) return TRUE;
	return FALSE;
}

inter_symbol *InstanceInstruction::typename(inter_symbol *instance_s) {
	return InterTypes::type_name(InterTypes::of_symbol(instance_s));
}

inter_pair InstanceInstruction::enumerated_value(inter_symbol *instance_s) {
	if (instance_s == NULL) return InterValuePairs::undef();
	inter_tree_node *D = InterSymbol::definition(instance_s);
	if (D == NULL) return InterValuePairs::undef();
	return InterValuePairs::get(D, VAL1_INST_IFLD);
}

inter_node_list *InstanceInstruction::permissions_list(inter_symbol *instance_s) {
	if (instance_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(instance_s);
	if (D == NULL) return NULL;
	return Inode::ID_to_frame_list(D, D->W.instruction[PERM_LIST_INST_IFLD]);
}

inter_node_list *InstanceInstruction::properties_list(inter_symbol *instance_s) {
	if (instance_s == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(instance_s);
	if (D == NULL) return NULL;
	return Inode::ID_to_frame_list(D, D->W.instruction[PROP_LIST_INST_IFLD]);
}
