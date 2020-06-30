[Inode::] Inter Nodes.

To create nodes of inter code, and manage everything about them except their
tree locations.

@h Bytecode definition.

@d inter_ti unsigned int
@d signed_inter_ti int

=
typedef struct inter_tree_node {
	struct inter_tree *tree;
	struct inter_package *package;
	struct inter_tree_node *parent_itn;
	struct inter_tree_node *first_child_itn;
	struct inter_tree_node *last_child_itn;
	struct inter_tree_node *previous_itn;
	struct inter_tree_node *next_itn;
	struct warehouse_floor_space W;
} inter_tree_node;

inter_tree_node *Inode::new(inter_tree *I, warehouse_floor_space W) {
	inter_tree_node *itn = CREATE(inter_tree_node);
	itn->tree = I;
	itn->package = NULL;
	itn->parent_itn = NULL;
	itn->first_child_itn = NULL;
	itn->last_child_itn = NULL;
	itn->previous_itn = NULL;
	itn->next_itn = NULL;
	itn->W = W;
	return itn;
}

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
inter_ti Inode::get_metadata(inter_tree_node *F, int at) {
	if (F == NULL) return 0;
	return F->W.repo_segment->bytecode[F->W.index + at];
}

void Inode::set_metadata(inter_tree_node *F, int at, inter_ti V) {
	if (F) F->W.repo_segment->bytecode[F->W.index + at] = V;
}

inter_warehouse *Inode::warehouse(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->W.repo_segment->owning_warehouse;
}

inter_symbols_table *Inode::ID_to_symbols_table(inter_tree_node *F, inter_ti ID) {
	return Inter::Warehouse::get_symbols_table(Inode::warehouse(F), ID);
}

text_stream *Inode::ID_to_text(inter_tree_node *F, inter_ti ID) {
	return Inter::Warehouse::get_text(Inode::warehouse(F), ID);
}

inter_package *Inode::ID_to_package(inter_tree_node *F, inter_ti ID) {
	if (ID == 0) return NULL; // yes?
	return Inter::Warehouse::get_package(Inode::warehouse(F), ID);
}

inter_node_list *Inode::ID_to_frame_list(inter_tree_node *F, inter_ti N) {
	return Inter::Warehouse::get_frame_list(Inode::warehouse(F), N);
}

void *Inode::ID_to_ref(inter_tree_node *F, inter_ti N) {
	return Inter::Warehouse::get_ref(Inode::warehouse(F), N);
}

inter_symbols_table *Inode::globals(inter_tree_node *F) {
	if (F) return Inter::Tree::global_scope(F->tree);
	return NULL;
}

int Inode::eq(inter_tree_node *F1, inter_tree_node *F2) {
	if ((F1 == NULL) || (F2 == NULL)) {
		if (F1 == F2) return TRUE;
		return FALSE;
	}
	if (F1->W.repo_segment != F2->W.repo_segment) return FALSE;
	if (F1->W.index != F2->W.index) return FALSE;
	return TRUE;
}

@ =
inter_tree_node *Inode::root_frame(inter_warehouse *warehouse, inter_tree *I) {
	inter_tree_node *P = Inter::Warehouse::find_room(warehouse, I, 2, NULL, NULL);
	P->W.data[ID_IFLD] = (inter_ti) NOP_IST;
	P->W.data[LEVEL_IFLD] = 0;
	return P;
}

inter_tree_node *Inode::fill_0(inter_bookmark *IBM, int S, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 2, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	return P;
}

inter_tree_node *Inode::fill_1(inter_bookmark *IBM, int S, inter_ti V, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 3, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V;
	return P;
}

inter_tree_node *Inode::fill_2(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 4, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	return P;
}

inter_tree_node *Inode::fill_3(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 5, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	return P;
}

inter_tree_node *Inode::fill_4(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 6, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	return P;
}

inter_tree_node *Inode::fill_5(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 7, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	P->W.data[DATA_IFLD + 4] = V5;
	return P;
}

inter_tree_node *Inode::fill_6(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 8, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	P->W.data[DATA_IFLD + 4] = V5;
	P->W.data[DATA_IFLD + 5] = V6;
	return P;
}

inter_tree_node *Inode::fill_7(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6, inter_ti V7, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 9, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	P->W.data[DATA_IFLD + 4] = V5;
	P->W.data[DATA_IFLD + 5] = V6;
	P->W.data[DATA_IFLD + 6] = V7;
	return P;
}

inter_tree_node *Inode::fill_8(inter_bookmark *IBM, int S, inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6, inter_ti V7, inter_ti V8, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::find_room(Inter::Tree::warehouse(I), I, 10, eloc, Inter::Bookmarks::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	P->W.data[DATA_IFLD + 4] = V5;
	P->W.data[DATA_IFLD + 5] = V6;
	P->W.data[DATA_IFLD + 6] = V7;
	P->W.data[DATA_IFLD + 7] = V8;
	return P;
}

@ =
int Inode::extend(inter_tree_node *F, inter_ti by) {
	if (by == 0) return TRUE;
	if ((F->W.index + F->W.extent + PREFRAME_SIZE < F->W.repo_segment->size) ||
		(F->W.repo_segment->next_room)) return FALSE;
		
	if (F->W.repo_segment->size + (int) by <= F->W.repo_segment->capacity) {	
		Inode::set_metadata(F, PREFRAME_SKIP_AMOUNT,
			Inode::get_metadata(F, PREFRAME_SKIP_AMOUNT) + by);
		F->W.repo_segment->size += by;
		F->W.extent += by;
		return TRUE;
	}

	int next_size = Inter::Warehouse::enlarge_size(F->W.repo_segment->capacity, F->W.extent + PREFRAME_SIZE + (int) by);

	F->W.repo_segment->next_room = Inter::Warehouse::new_room(F->W.repo_segment->owning_warehouse,
		next_size, F->W.repo_segment);

	warehouse_floor_space W = Inter::Warehouse::find_room_in_room(F->W.repo_segment->next_room, F->W.extent + (int) by);

	F->W.repo_segment->size = F->W.index;
	F->W.repo_segment->capacity = F->W.index;

	inter_ti a = Inode::get_metadata(F, PREFRAME_VERIFICATION_COUNT);
	inter_ti b = Inode::get_metadata(F, PREFRAME_ORIGIN);
	inter_ti c = Inode::get_metadata(F, PREFRAME_COMMENT);

	F->W.index = W.index;
	F->W.repo_segment = W.repo_segment;
	for (int i=0; i<W.extent; i++)
		if (i < F->W.extent)
			W.data[i] = F->W.data[i];
		else
			W.data[i] = 0;
	F->W.data = W.data;
	F->W.extent = W.extent;

	Inode::set_metadata(F, PREFRAME_VERIFICATION_COUNT, a);
	Inode::set_metadata(F, PREFRAME_ORIGIN, b);
	Inode::set_metadata(F, PREFRAME_COMMENT, c);
	return TRUE;
}

inter_ti Inode::vcount(inter_tree_node *F) {
	inter_ti v = Inode::get_metadata(F, PREFRAME_VERIFICATION_COUNT);
	Inode::set_metadata(F, PREFRAME_VERIFICATION_COUNT, v + 1);
	return v;
}

inter_ti Inode::to_index(inter_tree_node *F) {
	if ((F->W.repo_segment == NULL) || (F->W.index < 0)) internal_error("no index for null frame");
	return (F->W.repo_segment->index_offset) + (inter_ti) (F->W.index);
}

@

=
inter_error_location *Inode::retrieve_origin(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return Inter::Warehouse::retrieve_origin(Inode::warehouse(F), Inode::get_metadata(F, PREFRAME_ORIGIN));
}

inter_error_message *Inode::error(inter_tree_node *F, text_stream *err, text_stream *quote) {
	inter_error_message *iem = CREATE(inter_error_message);
	inter_error_location *eloc = Inode::retrieve_origin(F);
	if (eloc)
		iem->error_at = *eloc;
	else
		iem->error_at = Inter::Errors::file_location(NULL, NULL);
	iem->error_body = err;
	iem->error_quote = quote;
	return iem;
}

inter_ti Inode::get_comment(inter_tree_node *F) {
	if (F) return Inode::get_metadata(F, PREFRAME_COMMENT);
	return 0;
}

void Inode::attach_comment(inter_tree_node *F, inter_ti ID) {
	if (F) Inode::set_metadata(F, PREFRAME_COMMENT, ID);
}

inter_package *Inode::get_package(inter_tree_node *F) {
	if (F) return F->package;
	return NULL;
}

inter_ti Inode::get_package_alt(inter_tree_node *X) {
	inter_tree_node *F = X;
	while (TRUE) {
		F = Inter::Tree::parent(F);
		if (F == NULL) break;
		if (F->W.data[ID_IFLD] == PACKAGE_IST)
			return F->W.data[PID_PACKAGE_IFLD];
	}
	return 0;
}

void Inode::attach_package(inter_tree_node *F, inter_package *pack) {
	if (F) F->package = pack;
}

