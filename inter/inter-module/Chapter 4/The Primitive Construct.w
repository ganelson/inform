[Inter::Primitive::] The Primitive Construct.

Defining the primitive construct.

@

@e PRIMITIVE_IST

=
void Inter::Primitive::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		PRIMITIVE_IST,
		L"primitive (!%i+) (%c+) -> (%C+)",
		&Inter::Primitive::read,
		NULL,
		&Inter::Primitive::verify,
		&Inter::Primitive::write,
		NULL,
		NULL,
		NULL,
		NULL,
		I"primitive", I"primitives");
	IC->usage_permissions = OUTSIDE_OF_PACKAGES;
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
inter_error_message *Inter::Primitive::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	inter_error_message *E = Inter::Defn::vet_level(IRS, PRIMITIVE_IST, ilp->indent_level, eloc);
	if (E) return E;

	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_symbol *prim_name = Inter::Textual::new_symbol(eloc, Inter::Bookmarks::scope(IRS), ilp->mr.exp[0], &E);
	if (E) return E;

	inter_frame F = Inter::Frame::fill_1(IRS, PRIMITIVE_IST, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, prim_name), eloc, (inter_t) ilp->indent_level);

	text_stream *in = ilp->mr.exp[1];
	match_results mr2 = Regexp::create_mr();
	while (Regexp::match(&mr2, in, L" *(%i+) *(%c*)")) {
		inter_t lcat = Inter::Primitive::category(eloc, mr2.exp[0], &E);
		if (E) return E;
		if (lcat == 0) break;
		if (Inter::Frame::extend(&F, (inter_t) 1) == FALSE) internal_error("can't extend");
		F.data[F.extent - 1] = lcat;
		Str::copy(in, mr2.exp[1]);
	}

	inter_t rcat = Inter::Primitive::category(eloc, ilp->mr.exp[2], &E);
	if (E) return E;
	if (Inter::Frame::extend(&F, (inter_t) 1) == FALSE) internal_error("can't extend");
	F.data[F.extent - 1] = rcat;

	E = Inter::Defn::verify_construct(F); if (E) return E;
	Inter::Frame::insert(F, IRS);
	return NULL;
}

inter_t Inter::Primitive::category(inter_error_location *eloc, text_stream *T, inter_error_message **E) {
	*E = NULL;
	if (Str::eq(T, I"void")) return 0;
	if (Str::eq(T, I"val")) return VAL_PRIM_CAT;
	if (Str::eq(T, I"ref")) return REF_PRIM_CAT;
	if (Str::eq(T, I"lab")) return LAB_PRIM_CAT;
	if (Str::eq(T, I"code")) return CODE_PRIM_CAT;
	*E = Inter::Errors::quoted(I"no such category", T, eloc);
	return VAL_PRIM_CAT;
}

void Inter::Primitive::write_category(OUTPUT_STREAM, inter_t cat) {
	switch (cat) {
		case VAL_PRIM_CAT: WRITE("val"); break;
		case REF_PRIM_CAT: WRITE("ref"); break;
		case LAB_PRIM_CAT: WRITE("lab"); break;
		case CODE_PRIM_CAT: WRITE("code"); break;
		case 0: WRITE("void"); break;
		default: internal_error("bad category");
	}
}

inter_error_message *Inter::Primitive::verify(inter_frame P) {
	if (P.extent < MIN_EXTENT_PRIM_IFR) return Inter::Frame::error(&P, I"p extent wrong", NULL);
	inter_error_message *E = Inter::Verify::defn(P, DEFN_PRIM_IFLD); if (E) return E;
	inter_symbol *prim_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PRIM_IFLD);
	if ((prim_name == NULL) || (Str::get_first_char(prim_name->symbol_name) != '!'))
		return Inter::Frame::error(&P, I"primitive not beginning with '!'", NULL);
	int voids = 0, args = 0;
	for (int i=CAT_PRIM_IFLD; i<P.extent-1; i++) {
		if (P.data[i] == 0) voids++;
		args++;
	}
	if ((voids > 1) || ((voids == 1) && (args > 1)))
		return Inter::Frame::error(&P, I"if used on the left, 'void' must be the only argument", NULL);
	return NULL;
}

inter_error_message *Inter::Primitive::write(OUTPUT_STREAM, inter_frame P) {
	inter_symbol *prim_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_PRIM_IFLD);
	if (prim_name) {
		WRITE("primitive %S", prim_name->symbol_name);
		int cats = 0;
		for (int i=CAT_PRIM_IFLD; i<P.extent-1; i++) {
			WRITE(" ");
			Inter::Primitive::write_category(OUT, P.data[i]);
			cats++;
		}
		if (cats == 0) WRITE(" void");
		WRITE(" -> ");
		Inter::Primitive::write_category(OUT, P.data[P.extent-1]);
	} else return Inter::Frame::error(&P, I"cannot write primitive", NULL);
	return NULL;
}

int Inter::Primitive::arity(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(prim);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.extent - CAT_PRIM_IFLD - 1;
}

inter_t Inter::Primitive::operand_category(inter_symbol *prim, int i) {
	if (prim == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(prim);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[CAT_PRIM_IFLD + i];
}

inter_t Inter::Primitive::result_category(inter_symbol *prim) {
	if (prim == NULL) return 0;
	inter_frame D = Inter::Symbols::defining_frame(prim);
	if (Inter::Frame::valid(&D) == FALSE) return 0;
	return D.data[D.extent - 1];
}
