[Inter::Evaluation::] The Evaluation Construct.

Defining the Evaluation construct.

@

@e EVALUATION_IST

=
void Inter::Evaluation::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		EVALUATION_IST,
		L"evaluation",
		I"evaluation", I"evaluations");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
	IC->children_field = CODE_EVAL_IFLD;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Evaluation::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Evaluation::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Evaluation::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Evaluation::verify_children);
}

@

@d BLOCK_EVAL_IFLD 2
@d CODE_EVAL_IFLD 3

@d EXTENT_EVAL_IFR 4

=
void Inter::Evaluation::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IRS, EVALUATION_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'evaluation' used outside function", eloc); return; }

	*E = Inter::Evaluation::new(IRS, routine, ilp->indent_level, eloc);
}

inter_error_message *Inter::Evaluation::new(inter_reading_state *IRS, inter_symbol *routine, int level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_2(IRS, EVALUATION_IST, 0,
		Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Evaluation::verify(inter_construct *IC, inter_frame P, inter_error_message **E) {
	if (P.extent != EXTENT_EVAL_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
}

void Inter::Evaluation::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	WRITE("evaluation");
}

void Inter::Evaluation::verify_children(inter_construct *IC, inter_frame P, inter_error_message **E) {
	inter_frame_list *ifl = Inter::Defn::list_of_children(P);
	inter_frame C;
	LOOP_THROUGH_INTER_FRAME_LIST(C, ifl) {
		if ((C.data[0] != INV_IST) && (C.data[0] != SPLAT_IST) && (C.data[0] != VAL_IST) && (C.data[0] != LABEL_IST) && (C.data[0] != EVALUATION_IST)) {
			*E = Inter::Frame::error(&C, I"only an inv, a splat, a val, or a label can be below an evaluation", NULL);
			return;
		}
	}
}

inter_frame_list *Inter::Evaluation::concatenate_list(inter_symbol *label_name) {
	if (label_name == NULL) return NULL;
	inter_frame D = Inter::Symbols::defining_frame(label_name);
	if (Inter::Frame::valid(&D) == FALSE) return NULL;
	if (D.data[ID_IFLD] != EVALUATION_IST) return NULL;
	return Inter::find_frame_list(D.repo_segment->owning_repo, D.data[CODE_EVAL_IFLD]);
}
