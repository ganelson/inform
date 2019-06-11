[Inter::Reference::] The Reference Construct.

Defining the Reference construct.

@

@e REFERENCE_IST

=
void Inter::Reference::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		REFERENCE_IST,
		L"reference",
		&Inter::Reference::read,
		NULL,
		&Inter::Reference::verify,
		&Inter::Reference::write,
		NULL,
		&Inter::Reference::list_of_children,
		&Inter::Reference::accept_child,
		&Inter::Reference::no_more_children,
		&Inter::Reference::show_dependencies,
		I"reference", I"references");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_RCE_IFLD 2
@d CODE_RCE_IFLD 3

@d EXTENT_RCE_IFR 4

=
inter_error_message *Inter::Reference::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);

	inter_error_message *E = Inter::Defn::vet_level(IRS, REFERENCE_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'reference' used outside function", eloc);

	return Inter::Reference::new(IRS, routine, ilp->indent_level, eloc);
}

inter_error_message *Inter::Reference::new(inter_reading_state *IRS, inter_symbol *routine, int level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, REFERENCE_IST, 0,
		Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Reference::verify(inter_frame P) {
	if (P.extent != EXTENT_RCE_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	return NULL;
}

inter_error_message *Inter::Reference::write(OUTPUT_STREAM, inter_frame P) {
	WRITE("reference");
	return NULL;
}

void Inter::Reference::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
}

inter_frame_list *Inter::Reference::list_of_children(inter_frame P) {
	if (Inter::Frame::valid(&P) == FALSE) return NULL;
	if (P.data[ID_IFLD] != REF_IST) return NULL;
	return Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCE_IFLD]);
}

inter_error_message *Inter::Reference::accept_child(inter_frame P, inter_frame C) {
	if ((C.data[0] != INV_IST) && (C.data[0] != REF_IST) && (C.data[0] != SPLAT_IST) && (C.data[0] != VAL_IST) && (C.data[0] != LABEL_IST))
		return Inter::Frame::error(&C, I"only an inv, a ref, a splat, a val, or a label can be below a reference", NULL);
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[CODE_RCE_IFLD]), C, NULL);
	return NULL;
}

inter_error_message *Inter::Reference::no_more_children(inter_frame P) {
	return NULL;
}

inter_frame_list *Inter::Reference::reference_list(inter_symbol *label_name) {
	if (label_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(label_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != REFERENCE_IST) return NULL;
	return Inter::find_frame_list(D.repo_segment->owning_repo, D.data[CODE_RCE_IFLD]);
}
