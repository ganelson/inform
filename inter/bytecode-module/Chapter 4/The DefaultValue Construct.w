[DefaultValueInstruction::] The DefaultValue Construct.

Defining the defaultvalue construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void DefaultValueInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(DEFAULTVALUE_IST, I"defaultvalue");
	InterInstruction::specify_syntax(IC, I"defaultvalue TOKEN = TOKENS");
	InterInstruction::fix_instruction_length_between(IC, 5, 5);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, DefaultValueInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, DefaultValueInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, DefaultValueInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |defaultvalue| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d TYPE_DEF_IFLD 2
@d VAL1_DEF_IFLD 3
@d VAL2_DEF_IFLD 4

=
inter_error_message *DefaultValueInstruction::new(inter_bookmark *IBM,
	inter_symbol *typename, inter_pair val, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, DEFAULTVALUE_IST,
		/* TYPE_DEF_IFLD: */ InterSymbolsTable::id_from_symbol_at_bookmark(IBM, typename),
		/* VAL1_DEF_IFLD: */ InterValuePairs::to_word1(val),
		/* VAL2_DEF_IFLD: */ InterValuePairs::to_word2(val),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks. Note that the |TYPE_DEF_IFLD|
field must contain a valid symbol ID -- of a |typename| -- and cannot be a more
general TID. So you cannot have an instruction setting the default value of,
say, |int32|.

=
void DefaultValueInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, TYPE_DEF_IFLD, TYPENAME_IST);
}

@h Creating from textual Inter syntax.

=
void DefaultValueInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *typename =
		TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[0], TYPENAME_IST, E);
	if (*E) return;

	inter_pair val = InterValuePairs::undef();
	*E = TextualInter::parse_pair(ilp->line, eloc, IBM, InterTypes::from_type_name(typename),
		ilp->mr.exp[1], &val);
	if (*E) return;

	*E = DefaultValueInstruction::new(IBM, typename, val, (inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void DefaultValueInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *typename = InterSymbolsTable::symbol_from_ID_at_node(P, TYPE_DEF_IFLD);
	WRITE("defaultvalue %S = ", InterSymbol::identifier(typename));
	TextualInter::write_pair(OUT, P, InterValuePairs::get(P, VAL1_DEF_IFLD), FALSE);
}
