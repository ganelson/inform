[Inter::Primitive::] The Primitive Construct.

Defining the primitive construct.

@

@e PRIMITIVE_IST

=
void Inter::Primitive::define(void) {
	inter_construct *IC = InterConstruct::create_construct(PRIMITIVE_IST, I"primitive");
	InterConstruct::specify_syntax(IC, I"primitive !IDENTIFIER TOKENS -> TOKEN");
	InterConstruct::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Primitive::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Primitive::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Primitive::write);
}

@

@d DEFN_PRIM_IFLD 2
@d CAT_PRIM_IFLD 3

@d MIN_EXTENT_PRIM_IFR 4

@d VAL_PRIM_CAT 1
@d REF_PRIM_CAT 2
@d LAB_PRIM_CAT 3
@d CODE_PRIM_CAT 4

=
void Inter::Primitive::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = InterConstruct::check_level_in_package(IBM, PRIMITIVE_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (SymbolAnnotation::nonempty(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_symbol *prim_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;

	inter_tree_node *F = Inode::new_with_1_data_field(IBM, PRIMITIVE_IST, InterSymbolsTable::id_from_symbol_at_bookmark(IBM, prim_name), eloc, (inter_ti) ilp->indent_level);

	text_stream *in = ilp->mr.exp[1];
	match_results mr2 = Regexp::create_mr();
	while (Regexp::match(&mr2, in, L" *(%i+) *(%c*)")) {
		inter_ti lcat = Inter::Primitive::category(eloc, mr2.exp[0], E);
		if (*E) return;
		if (lcat == 0) break;
		Inode::extend_instruction_by(F, 1);
		F->W.instruction[F->W.extent - 1] = lcat;
		Str::copy(in, mr2.exp[1]);
	}

	inter_ti rcat = Inter::Primitive::category(eloc, ilp->mr.exp[2], E);
	if (*E) return;
	Inode::extend_instruction_by(F, 1);
	F->W.instruction[F->W.extent - 1] = rcat;

	*E = InterConstruct::verify_construct(InterBookmark::package(IBM), F); if (*E) return;
	NodePlacement::move_to_moving_bookmark(F, IBM);
}

inter_ti Inter::Primitive::category(inter_error_location *eloc, text_stream *T, inter_error_message **E) {
	*E = NULL;
	if (Str::eq(T, I"void")) return 0;
	if (Str::eq(T, I"val")) return VAL_PRIM_CAT;
	if (Str::eq(T, I"ref")) return REF_PRIM_CAT;
	if (Str::eq(T, I"lab")) return LAB_PRIM_CAT;
	if (Str::eq(T, I"code")) return CODE_PRIM_CAT;
	*E = Inter::Errors::quoted(I"no such category", T, eloc);
	return VAL_PRIM_CAT;
}

void Inter::Primitive::write_category(OUTPUT_STREAM, inter_ti cat) {
	switch (cat) {
		case VAL_PRIM_CAT: WRITE("val"); break;
		case REF_PRIM_CAT: WRITE("ref"); break;
		case LAB_PRIM_CAT: WRITE("lab"); break;
		case CODE_PRIM_CAT: WRITE("code"); break;
		case 0: WRITE("void"); break;
		default: internal_error("bad category");
	}
}

void Inter::Primitive::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent < MIN_EXTENT_PRIM_IFR) { *E = Inode::error(P, I"primitive extent wrong", NULL); return; }
	*E = Inter::Verify::defn(owner, P, DEFN_PRIM_IFLD); if (*E) return;
	inter_symbol *prim_name = InterSymbolsTable::symbol_from_ID(Inode::globals(P), P->W.instruction[DEFN_PRIM_IFLD]);
	if ((prim_name == NULL) || (Str::get_first_char(prim_name->symbol_name) != '!'))
		{ *E = Inode::error(P, I"primitive not beginning with '!'", NULL); return; }
	int voids = 0, args = 0;
	for (int i=CAT_PRIM_IFLD; i<P->W.extent-1; i++) {
		if (P->W.instruction[i] == 0) voids++;
		args++;
	}
	if ((voids > 1) || ((voids == 1) && (args > 1)))
		{ *E = Inode::error(P, I"if used on the left, 'void' must be the only argument", NULL); return; }
}

void Inter::Primitive::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *prim_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PRIM_IFLD);
	if (prim_name) {
		WRITE("primitive %S", prim_name->symbol_name);
		int cats = 0;
		for (int i=CAT_PRIM_IFLD; i<P->W.extent-1; i++) {
			WRITE(" ");
			Inter::Primitive::write_category(OUT, P->W.instruction[i]);
			cats++;
		}
		if (cats == 0) WRITE(" void");
		WRITE(" -> ");
		Inter::Primitive::write_category(OUT, P->W.instruction[P->W.extent-1]);
	} else { *E = Inode::error(P, I"cannot write primitive", NULL); return; }
}

int Inter::Primitive::arity(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.extent - CAT_PRIM_IFLD - 1;
}

inter_ti Inter::Primitive::operand_category(inter_symbol *prim, int i) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.instruction[CAT_PRIM_IFLD + i];
}

inter_ti Inter::Primitive::result_category(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.instruction[D->W.extent - 1];
}
