[AppendInstruction::] The Append Construct.

Defining the append construct.

@h Definition.
For what this does and why it is used, see //inter: Data Packages in Textual Inter//.
But please use it as little as possible: in an ideal world it would be abolished.

=
void AppendInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(APPEND_IST, I"append");
	InterInstruction::specify_syntax(IC, I"append IDENTIFIER TEXT");
	InterInstruction::fix_instruction_length_between(IC, 4, 4);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, AppendInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, AppendInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, AppendInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, AppendInstruction::write);
}

@h Instructions.
In bytecode, the frame of an |append| instruction is laid out with the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|, followed by:

@d SYMBOL_APPEND_IFLD 2
@d CONTENT_APPEND_IFLD 3

=
inter_error_message *AppendInstruction::new(inter_bookmark *IBM, inter_symbol *S,
	text_stream *append_text, inter_ti level, struct inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, APPEND_IST,
		/* SYMBOL_APPEND_IFLD:  */ InterSymbolsTable::id_at_bookmark(IBM, S), 
		/* CONTENT_APPEND_IFLD: */ InterWarehouse::create_text_at(IBM, append_text),
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void AppendInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[CONTENT_APPEND_IFLD] = grid[P->W.instruction[CONTENT_APPEND_IFLD]];
}

@ Verification consists of sanity checks followed by some cross-referencing.

=
void AppendInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, SYMBOL_APPEND_IFLD, INVALID_IST);
	if (*E) return;
	*E = VerifyingInter::text_field(owner, P, CONTENT_APPEND_IFLD);
	if (*E) return;

	inter_symbol *S = InterSymbolsTable::symbol_from_ID_at_node(P, SYMBOL_APPEND_IFLD);
	text_stream *content = Inode::ID_to_text(P, P->W.instruction[CONTENT_APPEND_IFLD]);
	SymbolAnnotation::set_t(P->tree, P->package, S, APPEND_IANN, content);
}

@h Creating from textual Inter syntax.

=
void AppendInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *identifier = ilp->mr.exp[0], *content = ilp->mr.exp[1];

	inter_symbol *S = InterSymbolsTable::symbol_from_name(InterBookmark::scope(IBM), identifier);
	if (S == NULL) { *E = InterErrors::quoted(I"no such identifier", identifier, eloc); return; }

	TEMPORARY_TEXT(raw)
	*E = TextualInter::parse_literal_text(raw, content, 0, Str::len(content), eloc);
	if (*E == NULL) *E = AppendInstruction::new(IBM, S, raw, (inter_ti) ilp->indent_level, eloc);
	DISCARD_TEXT(content)
}

@h Writing to textual Inter syntax.

=
void AppendInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_at_node(P, SYMBOL_APPEND_IFLD);
	text_stream *content = Inode::ID_to_text(P, P->W.instruction[CONTENT_APPEND_IFLD]);
	WRITE("append %S ", InterSymbol::identifier(S));
	TextualInter::write_text(OUT, content);
}
