[Inter::Frame::] Frames.

To manage frames, which are windows into Inter storage.

@h Frames.

=
typedef struct inter_frame {
	struct inter_repository_segment *repo_segment;
	int index;
	inter_t *data;
	int extent;
} inter_frame;

@ =
inter_frame Inter::Frame::around(inter_repository_segment *IS, int index) {
	inter_frame F;
	F.repo_segment = IS; F.index = index;
	if ((IS) && (index >= 0) && (index < IS->size)) {
		F.data = &(IS->bytecode[index + PREFRAME_SIZE]);
		F.extent = ((int) IS->bytecode[index]) - PREFRAME_SIZE;
	} else {
		F.data = NULL; F.extent = 0;
	}
	return F;
}

int Inter::Frame::valid(inter_frame *F) {
	if ((F == NULL) || (F->repo_segment == NULL) || (F->index < 0) || (F->data == NULL) || (F->extent <= 0)) return FALSE;
	return TRUE;
}

int Inter::Frame::included(inter_frame *F) {
	if (F == NULL) return FALSE;
	inter_package *pack = Inter::Packages::container_p(F);
	if ((pack) && (((pack->package_flags) & (EXCLUDE_PACKAGE_FLAG)))) return FALSE;
	return TRUE;
}

int Inter::Frame::eq(inter_frame *F1, inter_frame *F2) {
	if ((F1 == NULL) || (F2 == NULL)) {
		if (F1 == F2) return TRUE;
		return FALSE;
	}
	if (F1->repo_segment != F2->repo_segment) return FALSE;
	if (F1->index != F2->index) return FALSE;
	return TRUE;
}

@ =
inter_frame Inter::Frame::fill_0(inter_reading_state *IRS, int S, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 2, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	return P;
}

inter_frame Inter::Frame::fill_1(inter_reading_state *IRS, int S, inter_t V, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 3, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V;
	return P;
}

inter_frame Inter::Frame::fill_2(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 4, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	return P;
}

inter_frame Inter::Frame::fill_3(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 5, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	return P;
}

inter_frame Inter::Frame::fill_4(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 6, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	P.data[DATA_IFLD + 3] = V4;
	return P;
}

inter_frame Inter::Frame::fill_5(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 7, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	P.data[DATA_IFLD + 3] = V4;
	P.data[DATA_IFLD + 4] = V5;
	return P;
}

inter_frame Inter::Frame::fill_6(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 8, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	P.data[DATA_IFLD + 3] = V4;
	P.data[DATA_IFLD + 4] = V5;
	P.data[DATA_IFLD + 5] = V6;
	return P;
}

inter_frame Inter::Frame::fill_7(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_t V7, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 9, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	P.data[DATA_IFLD + 3] = V4;
	P.data[DATA_IFLD + 4] = V5;
	P.data[DATA_IFLD + 5] = V6;
	P.data[DATA_IFLD + 6] = V7;
	return P;
}

inter_frame Inter::Frame::fill_8(inter_reading_state *IRS, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_t V7, inter_t V8, inter_error_location *eloc, inter_t level) {
	inter_frame P = Inter::find_room(IRS->read_into, 10, eloc, IRS->current_package);
	P.data[ID_IFLD] = (inter_t) S;
	P.data[LEVEL_IFLD] = level;
	P.data[DATA_IFLD] = V1;
	P.data[DATA_IFLD + 1] = V2;
	P.data[DATA_IFLD + 2] = V3;
	P.data[DATA_IFLD + 3] = V4;
	P.data[DATA_IFLD + 4] = V5;
	P.data[DATA_IFLD + 5] = V6;
	P.data[DATA_IFLD + 6] = V7;
	P.data[DATA_IFLD + 7] = V8;
	return P;
}

@ =
int Inter::Frame::extend(inter_frame *F, inter_t by) {
	if (by == 0) return TRUE;
	if ((F->index + F->extent + PREFRAME_SIZE < F->repo_segment->size) ||
		(F->repo_segment->next_repo_segment)) return FALSE;
	if (F->repo_segment->size + (int) by <= F->repo_segment->capacity) {
		F->repo_segment->bytecode[F->index] += by;
		F->repo_segment->size += by;
		F->extent += by;
		return TRUE;
	}

	int next_size = Inter::enlarge_size(F->repo_segment->capacity, F->extent + PREFRAME_SIZE + (int) by);

	F->repo_segment->next_repo_segment = Inter::create_segment(next_size, F->repo_segment->owning_repo);

	inter_frame XF = Inter::find_room_in_segment(F->repo_segment->next_repo_segment, F->extent + (int) by);

	F->repo_segment->size = F->index;
	F->repo_segment->capacity = F->index;

	XF.repo_segment->bytecode[XF.index + PREFRAME_VERIFICATION_COUNT] = F->repo_segment->bytecode[F->index + PREFRAME_VERIFICATION_COUNT];
	XF.repo_segment->bytecode[XF.index + PREFRAME_ORIGIN] = F->repo_segment->bytecode[F->index + PREFRAME_ORIGIN];
	XF.repo_segment->bytecode[XF.index + PREFRAME_COMMENT] = F->repo_segment->bytecode[F->index + PREFRAME_COMMENT];
	XF.repo_segment->bytecode[XF.index + PREFRAME_PACKAGE] = F->repo_segment->bytecode[F->index + PREFRAME_PACKAGE];

	F->index = XF.index;
	F->repo_segment = XF.repo_segment;
	for (int i=0; i<XF.extent; i++)
		if (i < F->extent)
			XF.data[i] = F->data[i];
		else
			XF.data[i] = 0;
	F->data = XF.data;
	F->extent = XF.extent;

	return TRUE;
}

@

@d LOOP_THROUGH_FRAMES(P, I)
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(I->sequence)))

=
int trace_inter_insertion = FALSE;

void Inter::Frame::insert(inter_frame F, inter_reading_state *at) {
	inter_repository *I = F.repo_segment->owning_repo;
	LOGIF(INTER_FRAMES, "I%d: Insert frame %F\n", I->allocation_id, F);
	if (trace_inter_insertion) Inter::Defn::write_construct_text(DL, F);
	Inter::add_to_frame_list(&(I->sequence), F, at);
}

inter_symbols_table *Inter::Frame::global_symbols(inter_frame F) {
	if (Inter::Frame::valid(&F))
		return Inter::get_global_symbols(F.repo_segment->owning_repo);
	return NULL;
}

inter_error_location *Inter::Frame::retrieve_origin(inter_frame *F) {
	if (Inter::Frame::valid(F) == FALSE) return NULL;
	return Inter::retrieve_origin(F->repo_segment->owning_repo, F->repo_segment->bytecode[F->index + PREFRAME_ORIGIN]);
}

inter_error_message *Inter::Frame::error(inter_frame *F, text_stream *err, text_stream *quote) {
	inter_error_message *iem = CREATE(inter_error_message);
	inter_error_location *eloc = Inter::Frame::retrieve_origin(F);
	if (eloc)
		iem->error_at = *eloc;
	else
		iem->error_at = Inter::Errors::file_location(NULL, NULL);
	iem->error_body = err;
	iem->error_quote = quote;
	return iem;
}

inter_t Inter::Frame::get_comment(inter_frame F) {
	if (F.repo_segment) {
		return F.repo_segment->bytecode[F.index + PREFRAME_COMMENT];
	}
	return 0;
}

void Inter::Frame::attach_comment(inter_frame F, inter_t ID) {
	if ((ID) && (F.repo_segment)) {
		F.repo_segment->bytecode[F.index + PREFRAME_COMMENT] = ID;
	}
}

inter_t Inter::Frame::get_package(inter_frame F) {
	if (F.repo_segment) {
		return F.repo_segment->bytecode[F.index + PREFRAME_PACKAGE];
	}
	return 0;
}

inter_t Inter::Frame::get_package_p(inter_frame *F) {
	if (F->repo_segment) {
		return F->repo_segment->bytecode[F->index + PREFRAME_PACKAGE];
	}
	return 0;
}

void Inter::Frame::attach_package(inter_frame F, inter_t ID) {
	if ((ID) && (F.repo_segment)) {
		F.repo_segment->bytecode[F.index + PREFRAME_PACKAGE] = ID;
	}
}
