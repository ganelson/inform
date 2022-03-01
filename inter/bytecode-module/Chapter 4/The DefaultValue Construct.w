[DefaultValueInstruction::] The DefaultValue Construct.

Defining the defaultvalue construct.

@


=
void DefaultValueInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(DEFAULTVALUE_IST, I"defaultvalue");
	InterInstruction::specify_syntax(IC, I"defaultvalue TOKEN = TOKENS");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_DEF_IFR, EXTENT_DEF_IFR);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, DefaultValueInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, DefaultValueInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, DefaultValueInstruction::write);
}

@

@d KIND_DEF_IFLD 2
@d VAL1_DEF_IFLD 3
@d VAL2_DEF_IFLD 4

@d EXTENT_DEF_IFR 5

=
void DefaultValueInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *con_kind = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[0], TYPENAME_IST, E);
	if (*E) return;

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, InterTypes::from_type_name(con_kind), ilp->mr.exp[1], &val);
	if (*E) return;

	*E = DefaultValueInstruction::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_kind), val, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *DefaultValueInstruction::new(inter_bookmark *IBM, inter_ti KID, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, DEFAULTVALUE_IST, KID, InterValuePairs::to_word1(val), InterValuePairs::to_word2(val), eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void DefaultValueInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, KIND_DEF_IFLD, TYPENAME_IST);
}

void DefaultValueInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *con_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_DEF_IFLD);
	if (con_kind) {
		WRITE("defaultvalue %S = ", InterSymbol::identifier(con_kind));
		TextualInter::write_pair(OUT, P, InterValuePairs::get(P, VAL1_DEF_IFLD), FALSE);
	} else {
		*E = Inode::error(P, I"defaultvalue can't be written", NULL);
	}
}
