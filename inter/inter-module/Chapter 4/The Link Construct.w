[Inter::Link::] The Link Construct.

Defining the link construct.

@

@e LINK_IST

=
void Inter::Link::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		LINK_IST,
		L"link (%i+) \"(%c*)\" \"(%c*)\" \"(%c*)\" \"(%c*)\"",
		I"link", I"links");
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Link::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Link::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Link::write);
}

@

@d STAGE_LINK_IFLD 2
@d SEGMENT_LINK_IFLD 3
@d PART_LINK_IFLD 4
@d TO_RAW_LINK_IFLD 5
@d TO_SEGMENT_LINK_IFLD 6
@d REF_LINK_IFLD 7

@d EXTENT_LINK_IFR 8

@d EARLY_LINK_STAGE 1
@d BEFORE_LINK_STAGE 2
@d INSTEAD_LINK_STAGE 3
@d AFTER_LINK_STAGE 4

=
void Inter::Link::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = Inter::Defn::vet_level(IRS, LINK_IST, ilp->indent_level, eloc);
	if (*E) return;

	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	inter_t stage = 0;
	text_stream *stage_text = ilp->mr.exp[0];
	if (Str::eq(stage_text, I"early")) stage = EARLY_LINK_STAGE;
	else if (Str::eq(stage_text, I"before")) stage = BEFORE_LINK_STAGE;
	else if (Str::eq(stage_text, I"instead")) stage = INSTEAD_LINK_STAGE;
	else if (Str::eq(stage_text, I"after")) stage = AFTER_LINK_STAGE;
	else { *E = Inter::Errors::plain(I"no such stage name is supported", eloc); return; }

	inter_t SIDS[5];
	SIDS[0] = stage;
	for (int i=1; i<=4; i++) {
		SIDS[i] = Inter::create_text(IRS->read_into);
		*E = Inter::Constant::parse_text(Inter::get_text(IRS->read_into, SIDS[i]), ilp->mr.exp[i], 0, Str::len(ilp->mr.exp[i]), eloc);
		if (*E) return;
	}

	*E = Inter::Link::new(IRS, SIDS[0], SIDS[1], SIDS[2], SIDS[3], SIDS[4], 0, (inter_t) ilp->indent_level, eloc);
}

inter_error_message *Inter::Link::new(inter_reading_state *IRS,
	inter_t stage, inter_t text1, inter_t text2, inter_t text3, inter_t text4, inter_t ref, inter_t level,
	struct inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_6(IRS, LINK_IST, stage, text1, text2, text3, text4, ref, eloc, level);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Link::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_LINK_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }

	if ((P.data[STAGE_LINK_IFLD] != EARLY_LINK_STAGE) &&
		(P.data[STAGE_LINK_IFLD] != BEFORE_LINK_STAGE) &&
		(P.data[STAGE_LINK_IFLD] != INSTEAD_LINK_STAGE) &&
		(P.data[STAGE_LINK_IFLD] != AFTER_LINK_STAGE))
		{ *E = Inter::Frame::error(&P, I"bad stage marker on link", NULL); return; }
	if (P.data[SEGMENT_LINK_IFLD] == 0) { *E = Inter::Frame::error(&P, I"no segment text", NULL); return; }
	if (P.data[PART_LINK_IFLD] == 0) { *E = Inter::Frame::error(&P, I"no part text", NULL); return; }
	if (P.data[TO_RAW_LINK_IFLD] == 0) { *E = Inter::Frame::error(&P, I"no to-raw text", NULL); return; }
	if (P.data[TO_SEGMENT_LINK_IFLD] == 0) { *E = Inter::Frame::error(&P, I"no to-segment text", NULL); return; }
}

void Inter::Link::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	WRITE("link ");
	switch (P.data[STAGE_LINK_IFLD]) {
		case EARLY_LINK_STAGE: WRITE("early"); break;
		case BEFORE_LINK_STAGE: WRITE("before"); break;
		case INSTEAD_LINK_STAGE: WRITE("instead"); break;
		case AFTER_LINK_STAGE: WRITE("after"); break;
	}
	for (int i=SEGMENT_LINK_IFLD; i<=TO_SEGMENT_LINK_IFLD; i++) {
		WRITE(" \"");
		text_stream *S = Inter::get_text(P.repo_segment->owning_repo, P.data[i]);
		Inter::Constant::write_text(OUT, S);
		WRITE("\"");
	}
}
