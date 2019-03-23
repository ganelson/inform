[Inter::Code::] The Code Construct.

Defining the Code construct.

@

@e CODE_IST

=
void Inter::Code::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		CODE_IST,
		L"code",
		&Inter::Code::read,
		NULL,
		&Inter::Code::verify,
		&Inter::Code::write,
		NULL,
		&Inter::Code::accept_child,
		&Inter::Code::no_more_children,
		&Inter::Code::show_dependencies,
		I"code", I"codes");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_CODE_IFLD 2
@d CODE_CODE_IFLD 3

@d EXTENT_CODE_IFR 4

=
inter_error_message *Inter::Code::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_error_message *E = Inter::Defn::vet_level(IRS, CODE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'code' used outside function", eloc);

	return Inter::Code::new(IRS, routine, ilp->indent_level, eloc);
}

inter_error_message *Inter::Code::new(inter_reading_state *IRS, inter_symbol *routine, int level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, CODE_IST, 0, Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Code::verify(inter_frame P) {
	if (P.extent != EXTENT_CODE_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	return NULL;
}

inter_error_message *Inter::Code::write(OUTPUT_STREAM, inter_frame P) {
	WRITE("code");
	return NULL;
}

void Inter::Code::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
}

inter_error_message *Inter::Code::accept_child(inter_frame P, inter_frame C) {
	if ((C.data[0] != INV_IST) && (C.data[0] != SPLAT_IST) && (C.data[0] != EVALUATION_IST) && (C.data[0] != LABEL_IST) && (C.data[0] != VAL_IST))
		return Inter::Frame::error(&C, I"only an inv, a val, a splat, a concatenate or a label can be below a code", NULL);
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_CODE_IFLD]), C, NULL);
	return NULL;
}

inter_error_message *Inter::Code::no_more_children(inter_frame P) {
	return NULL;
}

inter_frame_list *Inter::Code::code_list(inter_symbol *label_name) {
	if (label_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(label_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != CODE_IST) return NULL;
	return Inter::find_frame_list(D.repo_segment->owning_repo, D.data[CODE_CODE_IFLD]);
}

