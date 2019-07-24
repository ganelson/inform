[Inter::Frame::] Frames.

To manage frames, which are windows into Inter storage.

@h Bytecode definition.

@d inter_t unsigned int
@d signed_inter_t int

@h Chunks.

@d IST_SIZE 100

@d SYMBOL_BASE_VAL 0x40000000

@d PREFRAME_SKIP_AMOUNT 0
@d PREFRAME_VERIFICATION_COUNT 1
@d PREFRAME_ORIGIN 2
@d PREFRAME_COMMENT 3
@d PREFRAME_SIZE 4

@h Frames.

=
typedef struct inter_frame_XYZZY {
	struct inter_tree_node *node;
} inter_frame_XYZZY;

@ =
inter_t Inter::Frame::get_metadata(inter_frame *F, int at) {
	if (F == NULL) return 0;
	return F->node->W.repo_segment->bytecode[F->node->W.index + at];
}

void Inter::Frame::set_metadata(inter_frame *F, int at, inter_t V) {
	if (F) F->node->W.repo_segment->bytecode[F->node->W.index + at] = V;
}

inter_warehouse *Inter::Frame::warehouse(inter_frame *F) {
	if (F == NULL) return NULL;
	return F->node->W.repo_segment->owning_warehouse;
}

inter_tree_node *Inter::Frame::node(inter_frame *F) {
	if (F == NULL) return NULL;
	return F->node;
}

inter_symbols_table *Inter::Frame::ID_to_symbols_table(inter_frame *F, inter_t ID) {
	return Inter::Warehouse::get_symbols_table(Inter::Frame::warehouse(F), ID);
}

text_stream *Inter::Frame::ID_to_text(inter_frame *F, inter_t ID) {
	return Inter::Warehouse::get_text(Inter::Frame::warehouse(F), ID);
}

inter_package *Inter::Frame::ID_to_package(inter_frame *F, inter_t ID) {
	if (ID == 0) return NULL; // yes?
	return Inter::Warehouse::get_package(Inter::Frame::warehouse(F), ID);
}

inter_frame_list *Inter::Frame::ID_to_frame_list(inter_frame *F, inter_t N) {
	return Inter::Warehouse::get_frame_list(Inter::Frame::warehouse(F), N);
}

void *Inter::Frame::ID_to_ref(inter_frame *F, inter_t N) {
	return Inter::Warehouse::get_ref(Inter::Frame::warehouse(F), N);
}

inter_symbols_table *Inter::Frame::globals(inter_frame *F) {
	if (Inter::Frame::valid(F)) {
		inter_tree_node *itn = Inter::Frame::node(F);
		return Inter::get_global_symbols(itn->tree);
	}
	return NULL;
}

int Inter::Frame::valid(inter_frame *F) {
	if ((F == NULL) || (F->node->W.repo_segment == NULL) || (F->node->W.index < 0) || (F->node->W.data == NULL) || (F->node->W.extent <= 0)) return FALSE;
	return TRUE;
}

int Inter::Frame::eq(inter_frame *F1, inter_frame *F2) {
	if ((F1 == NULL) || (F2 == NULL)) {
		if (F1 == F2) return TRUE;
		return FALSE;
	}
	if (F1->node->W.repo_segment != F2->node->W.repo_segment) return FALSE;
	if (F1->node->W.index != F2->node->W.index) return FALSE;
	return TRUE;
}

@ =
inter_frame *Inter::Frame::root_frame(inter_warehouse *warehouse, inter_tree *I) {
	inter_frame *P = Inter::Warehouse::find_room(warehouse, I, 2, NULL, NULL);
	P->node->W.data[ID_IFLD] = (inter_t) NOP_IST;
	P->node->W.data[LEVEL_IFLD] = 0;
	return P;
}

inter_frame *Inter::Frame::fill_0(inter_bookmark *IBM, int S, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 2, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	return P;
}

inter_frame *Inter::Frame::fill_1(inter_bookmark *IBM, int S, inter_t V, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 3, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V;
	return P;
}

inter_frame *Inter::Frame::fill_2(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 4, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	return P;
}

inter_frame *Inter::Frame::fill_3(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 5, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	return P;
}

inter_frame *Inter::Frame::fill_4(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 6, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	P->node->W.data[DATA_IFLD + 3] = V4;
	return P;
}

inter_frame *Inter::Frame::fill_5(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 7, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	P->node->W.data[DATA_IFLD + 3] = V4;
	P->node->W.data[DATA_IFLD + 4] = V5;
	return P;
}

inter_frame *Inter::Frame::fill_6(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 8, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	P->node->W.data[DATA_IFLD + 3] = V4;
	P->node->W.data[DATA_IFLD + 4] = V5;
	P->node->W.data[DATA_IFLD + 5] = V6;
	return P;
}

inter_frame *Inter::Frame::fill_7(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_t V7, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 9, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	P->node->W.data[DATA_IFLD + 3] = V4;
	P->node->W.data[DATA_IFLD + 4] = V5;
	P->node->W.data[DATA_IFLD + 5] = V6;
	P->node->W.data[DATA_IFLD + 6] = V7;
	return P;
}

inter_frame *Inter::Frame::fill_8(inter_bookmark *IBM, int S, inter_t V1, inter_t V2, inter_t V3, inter_t V4, inter_t V5, inter_t V6, inter_t V7, inter_t V8, inter_error_location *eloc, inter_t level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_frame *P = Inter::Warehouse::find_room(Inter::warehouse(I), I, 10, eloc, Inter::Bookmarks::package(IBM));
	P->node->W.data[ID_IFLD] = (inter_t) S;
	P->node->W.data[LEVEL_IFLD] = level;
	P->node->W.data[DATA_IFLD] = V1;
	P->node->W.data[DATA_IFLD + 1] = V2;
	P->node->W.data[DATA_IFLD + 2] = V3;
	P->node->W.data[DATA_IFLD + 3] = V4;
	P->node->W.data[DATA_IFLD + 4] = V5;
	P->node->W.data[DATA_IFLD + 5] = V6;
	P->node->W.data[DATA_IFLD + 6] = V7;
	P->node->W.data[DATA_IFLD + 7] = V8;
	return P;
}

@ =
int Inter::Frame::extend(inter_frame *F, inter_t by) {
	if (by == 0) return TRUE;
	if ((F->node->W.index + F->node->W.extent + PREFRAME_SIZE < F->node->W.repo_segment->size) ||
		(F->node->W.repo_segment->next_room)) return FALSE;
		
	inter_tree_node *itn = Inter::Frame::node(F);
		
	if (F->node->W.repo_segment->size + (int) by <= F->node->W.repo_segment->capacity) {	
		Inter::Frame::set_metadata(F, PREFRAME_SKIP_AMOUNT,
			Inter::Frame::get_metadata(F, PREFRAME_SKIP_AMOUNT) + by);
		F->node->W.repo_segment->size += by;
		F->node->W.extent += by;
//		itn->content = *F;
		return TRUE;
	}

	int next_size = Inter::Warehouse::enlarge_size(F->node->W.repo_segment->capacity, F->node->W.extent + PREFRAME_SIZE + (int) by);

	F->node->W.repo_segment->next_room = Inter::Warehouse::new_room(F->node->W.repo_segment->owning_warehouse,
		next_size, F->node->W.repo_segment);

	warehouse_floor_space W = Inter::Warehouse::find_room_in_room(F->node->W.repo_segment->next_room, F->node->W.extent + (int) by);

	F->node->W.repo_segment->size = F->node->W.index;
	F->node->W.repo_segment->capacity = F->node->W.index;

	inter_t a = Inter::Frame::get_metadata(F, PREFRAME_VERIFICATION_COUNT);
	inter_t b = Inter::Frame::get_metadata(F, PREFRAME_ORIGIN);
	inter_t c = Inter::Frame::get_metadata(F, PREFRAME_COMMENT);

	F->node->W.index = W.index;
	F->node->W.repo_segment = W.repo_segment;
	for (int i=0; i<W.extent; i++)
		if (i < F->node->W.extent)
			W.data[i] = F->node->W.data[i];
		else
			W.data[i] = 0;
	F->node->W.data = W.data;
	F->node->W.extent = W.extent;

	Inter::Frame::set_metadata(F, PREFRAME_VERIFICATION_COUNT, a);
	Inter::Frame::set_metadata(F, PREFRAME_ORIGIN, b);
	Inter::Frame::set_metadata(F, PREFRAME_COMMENT, c);
	return TRUE;
}

inter_t Inter::Frame::vcount(inter_frame *F) {
	inter_t v = Inter::Frame::get_metadata(F, PREFRAME_VERIFICATION_COUNT);
	Inter::Frame::set_metadata(F, PREFRAME_VERIFICATION_COUNT, v + 1);
	return v;
}

inter_t Inter::Frame::to_index(inter_frame *F) {
	if ((F->node->W.repo_segment == NULL) || (F->node->W.index < 0)) internal_error("no index for null frame");
	return (F->node->W.repo_segment->index_offset) + (inter_t) (F->node->W.index);
}

@

=
int trace_inter_insertion = FALSE;

void Inter::Frame::insert(inter_frame *F, inter_bookmark *at) {
	if (F == NULL) internal_error("no frame to insert");
	if (at == NULL) internal_error("nowhere to insert");
	inter_package *pack = Inter::Bookmarks::package(at);
	inter_tree *I = pack->stored_in;
	LOGIF(INTER_FRAMES, "Insert frame %F\n", *F);
	if (trace_inter_insertion) Inter::Defn::write_construct_text(DL, F);
	inter_t F_level = F->node->W.data[LEVEL_IFLD];
	if (F_level == 0) {
		Inter::Frame::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, I->root_definition_frame);
		if ((Inter::Bookmarks::get_placement(at) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			Inter::Bookmarks::set_ref(at, F);
		}
	} else {
		if (Inter::Bookmarks::get_placement(at) == NOWHERE_ICPLACEMENT) internal_error("bad wrt");
		if ((Inter::Bookmarks::get_placement(at) == AFTER_ICPLACEMENT) ||
			(Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT)) {
			while (F_level < Inter::Bookmarks::get_ref(at)->node->W.data[LEVEL_IFLD]) {
				inter_frame *R = Inter::Bookmarks::get_ref(at);
				inter_frame *PR = Inter::get_parent(R);
				if (PR == NULL) internal_error("bubbled up out of tree");
				Inter::Bookmarks::set_ref(at, PR);
			}
			if (F_level > Inter::Bookmarks::get_ref(at)->node->W.data[LEVEL_IFLD] + 1) internal_error("bubbled down off of tree");
			if (F_level == Inter::Bookmarks::get_ref(at)->node->W.data[LEVEL_IFLD] + 1) {
				if (Inter::Bookmarks::get_placement(at) == IMMEDIATELY_AFTER_ICPLACEMENT) {
					Inter::Frame::place(F, AS_FIRST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
					Inter::Bookmarks::set_placement(at, AFTER_ICPLACEMENT);
				} else {
					Inter::Frame::place(F, AS_LAST_CHILD_OF_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
				}
			} else {
				Inter::Frame::place(F, AFTER_ICPLACEMENT, Inter::Bookmarks::get_ref(at));
			}
			Inter::Bookmarks::set_ref(at, F);
			return;
		}
		Inter::Frame::place(F, Inter::Bookmarks::get_placement(at), Inter::Bookmarks::get_ref(at));
	}
}

inter_error_location *Inter::Frame::retrieve_origin(inter_frame *F) {
	if (Inter::Frame::valid(F) == FALSE) return NULL;
	return Inter::Warehouse::retrieve_origin(Inter::Frame::warehouse(F), Inter::Frame::get_metadata(F, PREFRAME_ORIGIN));
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

inter_t Inter::Frame::get_comment(inter_frame *F) {
	if (F) return Inter::Frame::get_metadata(F, PREFRAME_COMMENT);
	return 0;
}

void Inter::Frame::attach_comment(inter_frame *F, inter_t ID) {
	if (F) Inter::Frame::set_metadata(F, PREFRAME_COMMENT, ID);
}

inter_package *Inter::Frame::get_package(inter_frame *F) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		return itn->package;
	}
	return NULL;
}

inter_t Inter::Frame::get_package_alt(inter_frame *X) {
	inter_frame *F = X;
	while (TRUE) {
		F = Inter::get_parent(F);
		if (F == NULL) break;
		if (F->node->W.data[ID_IFLD] == PACKAGE_IST)
			return F->node->W.data[PID_PACKAGE_IFLD];
	}
	return 0;
}

void Inter::Frame::backtrace(OUTPUT_STREAM, inter_frame *F) {
	inter_frame *X = F;
	int n = 0;
	while (TRUE) {
		X = Inter::get_parent(X);
		if (X == NULL) break;
		n++;
	}
	for (int i = n; i >= 0; i--) {
		inter_frame *X = F;
		int m = 0;
		while (TRUE) {
			inter_frame *Y = Inter::get_parent(X);
			if (Y == NULL) break;
			if (m == i) {
				WRITE("%2d. ", (n-i));
				if (i == 0) WRITE("** "); else WRITE("   ");
				Inter::Defn::write_construct_text_allowing_nop(OUT, X);
				break;
			}
			X = Y;
			m++;
		}
	}
	LOOP_THROUGH_INTER_CHILDREN(C, F) {
		WRITE("%2d.    ", (n+1));
		Inter::Defn::write_construct_text_allowing_nop(OUT, C);
	}
}		

void Inter::Frame::attach_package(inter_frame *F, inter_package *pack) {
	if (F) {
		inter_tree_node *itn = Inter::Frame::node(F);
		itn->package = pack;
	}
}

@d LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_frame *F = Inter::get_first_child(P); F; F = Inter::get_next(F))

@d PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
	for (inter_frame *F = Inter::get_first_child(P), *FN = F?(Inter::get_next(F)):NULL;
		F; F = FN, FN = FN?(Inter::get_next(FN)):NULL)

@

@e BEFORE_ICPLACEMENT from 0
@e AFTER_ICPLACEMENT
@e IMMEDIATELY_AFTER_ICPLACEMENT
@e AS_FIRST_CHILD_OF_ICPLACEMENT
@e AS_LAST_CHILD_OF_ICPLACEMENT
@e NOWHERE_ICPLACEMENT

=
void Inter::Frame::remove_from_tree(inter_frame *P) {
	Inter::Frame::place(P, NOWHERE_ICPLACEMENT, NULL);
}

void Inter::Frame::place(inter_frame *C, int how, inter_frame *R) {
	@<Extricate C from its current tree position@>;
	switch (how) {
		case NOWHERE_ICPLACEMENT:
			return;
		case AS_FIRST_CHILD_OF_ICPLACEMENT:
			@<Make C the first child of R@>;
			break;
		case AS_LAST_CHILD_OF_ICPLACEMENT:
			@<Make C the last child of R@>;
			break;
		case AFTER_ICPLACEMENT:
		case IMMEDIATELY_AFTER_ICPLACEMENT:
			@<Insert C after R@>;
			break;
		case BEFORE_ICPLACEMENT:
			@<Insert C before R@>;
			break;
		default:
			internal_error("unimplemented");
	}
}

@<Extricate C from its current tree position@> =
	inter_frame *OP = Inter::get_parent(C);
	if (OP) {
		if (Inter::Frame::node(Inter::get_first_child(OP)) == Inter::Frame::node(C))
			Inter::set_first_child(OP, Inter::get_next(C));
		if (Inter::Frame::node(Inter::get_last_child(OP)) == Inter::Frame::node(C))
			Inter::set_last_child(OP, Inter::get_previous(C));
	}
	inter_frame *OB = Inter::get_previous(C);
	inter_frame *OD = Inter::get_next(C);
	if (OB) {
		Inter::set_next(OB, OD);
	}
	if (OD) {
		Inter::set_previous(OD, OB);
	}
	Inter::set_parent(C, NULL);
	Inter::set_previous(C, NULL);
	Inter::set_next(C, NULL);

@<Make C the first child of R@> =
	Inter::set_parent(C, R);
	inter_frame *D = Inter::get_first_child(R);
	if (D == NULL) {
		Inter::set_last_child(R, C);
		Inter::set_next(C, NULL);
	} else {
		Inter::set_previous(D, C);
		Inter::set_next(C, D);
	}
	Inter::set_first_child(R, C);

@<Make C the last child of R@> =
	Inter::set_parent(C, R);
	inter_frame *B = Inter::get_last_child(R);
	if (B == NULL) {
		Inter::set_first_child(R, C);
		Inter::set_previous(C, NULL);
	} else {
		Inter::set_next(B, C);
		Inter::set_previous(C, B);
	}
	Inter::set_last_child(R, C);

@<Insert C after R@> =
	inter_frame *P = Inter::get_parent(R);
	if (P == NULL) internal_error("can't move C after R when R is nowhere");
	Inter::set_parent(C, P);
	if (Inter::Frame::node(Inter::get_last_child(P)) == Inter::Frame::node(R))
		Inter::set_last_child(P, C);
	else {
		inter_frame *D = Inter::get_next(R);
		if (D == NULL) internal_error("inter tree broken");
		Inter::set_next(C, D);
		Inter::set_previous(D, C);
	}
	Inter::set_next(R, C);
	Inter::set_previous(C, R);

@<Insert C before R@> =
	inter_frame *P = Inter::get_parent(R);
	if (P == NULL) internal_error("can't move C before R when R is nowhere");
	Inter::set_parent(C, P);
	if (Inter::Frame::node(Inter::get_first_child(P)) == Inter::Frame::node(R))
		Inter::set_first_child(P, C);
	else {
		inter_frame *B = Inter::get_previous(R);
		if (B == NULL) internal_error("inter tree broken");
		Inter::set_previous(C, B);
		Inter::set_next(B, C);
	}
	Inter::set_next(C, R);
	Inter::set_previous(R, C);
