[Inter::DefaultValue::] The DefaultValue Construct.

Defining the defaultvalue construct.

@

@e DEFAULTVALUE_IST

=
void Inter::DefaultValue::define(void) {
	inter_construct *IC = InterConstruct::create_construct(DEFAULTVALUE_IST, I"defaultvalue");
	InterConstruct::specify_syntax(IC, I"defaultvalue IDENTIFIER = TOKENS");
	InterConstruct::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::DefaultValue::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::DefaultValue::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::DefaultValue::write);
}

@

@d KIND_DEF_IFLD 2
@d VAL1_DEF_IFLD 3
@d VAL2_DEF_IFLD 4

@d EXTENT_DEF_IFR 5

=
void Inter::DefaultValue::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, DEFAULTVALUE_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *con_kind = TextualInter::find_symbol(IBM, eloc, ilp->mr.exp[0], KIND_IST, E);
	if (*E) return;

	inter_ti con_val1 = 0;
	inter_ti con_val2 = 0;
	*E = Inter::Types::read(ilp->line, eloc, IBM, con_kind, ilp->mr.exp[1], &con_val1, &con_val2, InterBookmark::scope(IBM));
	if (*E) return;

	*E = Inter::DefaultValue::new(IBM, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, con_kind), con_val1, con_val2, (inter_ti) ilp->indent_level, eloc);
}

inter_error_message *Inter::DefaultValue::new(inter_bookmark *IBM, inter_ti KID, inter_ti val1, inter_ti val2, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, DEFAULTVALUE_IST, KID, val1, val2, eloc, level);
	inter_error_message *E = InterConstruct::verify_construct(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void Inter::DefaultValue::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_DEF_IFR) *E = Inode::error(P, I"extent wrong", NULL);
	else *E = Inter::Verify::symbol(owner, P, P->W.instruction[KIND_DEF_IFLD], KIND_IST);
}

void Inter::DefaultValue::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *con_kind = InterSymbolsTable::symbol_from_ID_at_node(P, KIND_DEF_IFLD);
	if (con_kind) {
		WRITE("defaultvalue %S = ", InterSymbol::identifier(con_kind));
		Inter::Types::write(OUT, P, con_kind,
			P->W.instruction[VAL1_DEF_IFLD], P->W.instruction[VAL1_DEF_IFLD+1], InterPackage::scope_of(P), FALSE);
	} else {
		*E = Inode::error(P, I"defaultvalue can't be written", NULL);
	}
}
