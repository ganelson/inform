[PrimitiveInstruction::] The Primitive Construct.

Defining the primitive construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PrimitiveInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PRIMITIVE_IST, I"primitive");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PRIM_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"primitive !IDENTIFIER TOKENS -> TOKEN");
	InterInstruction::data_extent_at_least(IC, 2);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PrimitiveInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PrimitiveInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PrimitiveInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |primitive| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by a variable number of
words depending on the length of the signature.

Note that |cat1 cat2 ... catN -> result| takes N+1 words, one for each primitive
category: but that |void -> result| takes only 1. (Thus the not-really-a-category
|void| is not stored when it is an argument, though it is stored -- as 0 -- when
it is the result: the result is always stored.) It follows that the shortest
possible signature, say |void -> void|, occupies 1 word, so the minimum extent of
a |primitive| instruction is 4.

@d DEFN_PRIM_IFLD      (DATA_IFLD + 0)
@d SIGNATURE_PRIM_IFLD (DATA_IFLD + 1)

=
inter_error_message *PrimitiveInstruction::new(inter_bookmark *IBM, inter_symbol *prim_name, 
	text_stream *from, text_stream *to, inter_ti level, inter_error_location *eloc) {

	inter_tree_node *F = Inode::new_with_1_data_field(IBM, PRIMITIVE_IST,
		/* DEFN_PRIM_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, prim_name),
		eloc, level);

	inter_error_message *E = NULL;
	text_stream *in = from;
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, in, L" *(%i+) *(%c*)")) {
		inter_ti lcat = PrimitiveInstruction::read_category(eloc, mr.exp[0], &E);
		if (E) break;
		if (lcat == 0) break;
		Inode::extend_instruction_by(F, 1);
		F->W.instruction[F->W.extent - 1] = lcat;
		Str::copy(in, mr.exp[1]);
	}
	Regexp::dispose_of(&mr);
	if (E) return E;

	inter_ti rcat = PrimitiveInstruction::read_category(eloc, to, &E);
	if (E) return E;
	Inode::extend_instruction_by(F, 1);
	F->W.instruction[F->W.extent - 1] = rcat;

	E = VerifyingInter::instruction(InterBookmark::package(IBM), F);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(F, IBM);

	return NULL;
}

@ Verification consists only of sanity checks.

=
void PrimitiveInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	inter_symbol *prim_name = PrimitiveInstruction::primitive(P);
	if ((prim_name == NULL) ||
		(Str::get_first_char(InterSymbol::identifier(prim_name)) != '!')) {
		*E = Inode::error(P, I"primitive name not beginning with '!'", NULL);
		return;
	}
	int voids = 0, args = 0;
	for (int i=SIGNATURE_PRIM_IFLD; i<P->W.extent-1; i++) {
		inter_ti prim_cat = P->W.instruction[i];
		if (PrimitiveInstruction::category_is_valid(prim_cat) == FALSE) {
			*E = Inode::error(P, I"unknown primitive category", NULL);
			return;
		}
		if (prim_cat == 0) voids++;
		args++;
	}
	if ((voids > 1) || ((voids == 1) && (args > 1))) {
		*E = Inode::error(P, I"if used on the left, 'void' must be the only argument", NULL);
		return;
	}
}

@h Creating from textual Inter syntax.

=
void PrimitiveInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *prim_name =
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), ilp->mr.exp[0], E);
	if (*E) return;
	*E = PrimitiveInstruction::new(IBM, prim_name, ilp->mr.exp[1], ilp->mr.exp[2],
		(inter_ti) ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void PrimitiveInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_symbol *prim_name = InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PRIM_IFLD);
	WRITE("primitive %S", InterSymbol::identifier(prim_name));
	for (int i=SIGNATURE_PRIM_IFLD; i<P->W.extent-1; i++) {
		WRITE(" ");
		PrimitiveInstruction::write_category(OUT, P->W.instruction[i]);
	}
	if (SIGNATURE_PRIM_IFLD == P->W.extent-1) WRITE(" void");
	WRITE(" -> ");
	PrimitiveInstruction::write_category(OUT, P->W.instruction[P->W.extent-1]);
}

@h Primitive categories.

@d VAL_PRIM_CAT 1
@d REF_PRIM_CAT 2
@d LAB_PRIM_CAT 3
@d CODE_PRIM_CAT 4

=
inter_ti PrimitiveInstruction::read_category(inter_error_location *eloc, text_stream *T,
	inter_error_message **E) {
	*E = NULL;
	if (Str::eq(T, I"void")) return 0;
	if (Str::eq(T, I"val")) return VAL_PRIM_CAT;
	if (Str::eq(T, I"ref")) return REF_PRIM_CAT;
	if (Str::eq(T, I"lab")) return LAB_PRIM_CAT;
	if (Str::eq(T, I"code")) return CODE_PRIM_CAT;
	*E = InterErrors::quoted(I"no such category", T, eloc);
	return VAL_PRIM_CAT;
}

void PrimitiveInstruction::write_category(OUTPUT_STREAM, inter_ti cat) {
	WRITE("%s", PrimitiveInstruction::cat_name(cat));
}

char *PrimitiveInstruction::cat_name(inter_ti cat) {
	switch (cat) {
		case REF_PRIM_CAT: return "ref";
		case VAL_PRIM_CAT: return "val";
		case LAB_PRIM_CAT: return "lab";
		case CODE_PRIM_CAT: return "code";
		case 0: return "void";
	}
	return "<unknown>";
}

int PrimitiveInstruction::category_is_valid(inter_ti cat) {
	switch (cat) {
		case VAL_PRIM_CAT: return TRUE;
		case REF_PRIM_CAT: return TRUE;
		case LAB_PRIM_CAT: return TRUE;
		case CODE_PRIM_CAT: return TRUE;
		case 0: return TRUE;
	}
	return FALSE;
}

@h Signature of a primitive.

=
int PrimitiveInstruction::arity(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.extent - SIGNATURE_PRIM_IFLD - 1;
}

inter_ti PrimitiveInstruction::operand_category(inter_symbol *prim, int i) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.instruction[SIGNATURE_PRIM_IFLD + i];
}

inter_ti PrimitiveInstruction::result_category(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_tree_node *D = InterSymbol::definition(prim);
	if (D == NULL) return 0;
	return D->W.instruction[D->W.extent - 1];
}

inter_symbol *PrimitiveInstruction::primitive(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, PRIMITIVE_IST)) return NULL;
	return InterSymbolsTable::symbol_from_ID_at_node(P, DEFN_PRIM_IFLD);
}
