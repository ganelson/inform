[Inode::] Inter Nodes.

To create nodes of inter code, and manage everything about them except their
tree locations.

@ It's essential to be able to walk an Inter tree quickly, while movements
of nodes within the tree are relatively uncommon. So we provide every
imaginatble link. Suppose the structure is:
= (text)
	A
		B
		C
			D
		E
=
Then the links are:
= (text)
				 |	of A	B		C		D		E
	-------------+--------------------------------------
	parent		 |	NULL	A		A		C		A
	first_child	 |	B		NULL	D		NULL	NULL
	last_child   |  E		NULL	D		NULL	NULL
	previous     |  NULL	NULL	B		NULL	C
	next         |  NULL	C		E		NULL	NULL
=
Each node also knows the tree and the package it belongs to. We really aren't
concerned about memory consumption here. The Inter trees we deal with will be
large (typically 400,000 nodes), so on a 64-bit processor we might be looking
at 250 MB of memory here, and that can probably be doubled when the warehouse
memory consumption is also considered. But this is no longer prohibitive: speed
of access matters more.

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

@ Do not call this directly in order to create a node.

=
inter_tree_node *Inode::new_node_structure(inter_tree *I, warehouse_floor_space W) {
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

@ Instead, call one of the following. This of course should be called once
only per tree, and is called by //InterTree::new// anyway.

=
inter_tree_node *Inode::new_root_node(inter_warehouse *warehouse, inter_tree *I) {
	inter_tree_node *P = Inter::Warehouse::new_node(warehouse, I, 2, NULL, NULL);
	P->W.data[ID_IFLD] = (inter_ti) NOP_IST;
	P->W.data[LEVEL_IFLD] = 0;
	return P;
}

@ More generally: the content of a node is an instruction stored as bytecode
in memory. (Perhaps wordcode would be more accurate: it's a series of words.)
Words 0 and 1 have the same meaning for all instructions; everything from 2
onwards is data whose meaning differs between instructions. (Indeed, some
instructions have no data at all, and thus occupy only 2 words.)

The ID is an enumeration of |*_IST|: it marks which instruction this is.

The level is the depth of this node in the tree, where the root node is 0,
its children are level 1, their children level 2, and so on.

@d ID_IFLD 0
@d LEVEL_IFLD 1
@d DATA_IFLD 2

@ These functions should be called only by the creator functions for the
Inter instructions. Code which is generating Inter to do something should not
call those creator functions, not these.

=
inter_tree_node *Inode::new_with_0_data_fields(inter_bookmark *IBM, int S,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 2,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	return P;
}

inter_tree_node *Inode::new_with_1_data_field(inter_bookmark *IBM, int S,
	inter_ti V, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 3,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V;
	return P;
}

inter_tree_node *Inode::new_with_2_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 4,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	return P;
}

inter_tree_node *Inode::new_with_3_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 5,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	return P;
}

inter_tree_node *Inode::new_with_4_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_error_location *eloc,
	inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 6,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	return P;
}

inter_tree_node *Inode::new_with_5_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 7,
		eloc, InterBookmark::package(IBM));
	P->W.data[ID_IFLD] = (inter_ti) S;
	P->W.data[LEVEL_IFLD] = level;
	P->W.data[DATA_IFLD] = V1;
	P->W.data[DATA_IFLD + 1] = V2;
	P->W.data[DATA_IFLD + 2] = V3;
	P->W.data[DATA_IFLD + 3] = V4;
	P->W.data[DATA_IFLD + 4] = V5;
	return P;
}

inter_tree_node *Inode::new_with_6_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 8,
		eloc, InterBookmark::package(IBM));
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

inter_tree_node *Inode::new_with_7_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
	inter_ti V7, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 9,
		eloc, InterBookmark::package(IBM));
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

inter_tree_node *Inode::new_with_8_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
		inter_ti V7, inter_ti V8, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inter::Warehouse::new_node(InterTree::warehouse(I), I, 10,
		eloc, InterBookmark::package(IBM));
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

@h Bytecode in memory.




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
	return F->W.in_room->bytecode[F->W.index + at];
}

void Inode::set_metadata(inter_tree_node *F, int at, inter_ti V) {
	if (F) F->W.in_room->bytecode[F->W.index + at] = V;
}

inter_warehouse *Inode::warehouse(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->W.in_room->owning_warehouse;
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
	if (F) return InterTree::global_scope(F->tree);
	return NULL;
}

int Inode::eq(inter_tree_node *F1, inter_tree_node *F2) {
	if ((F1 == NULL) || (F2 == NULL)) {
		if (F1 == F2) return TRUE;
		return FALSE;
	}
	if (F1->W.in_room != F2->W.in_room) return FALSE;
	if (F1->W.index != F2->W.index) return FALSE;
	return TRUE;
}


@ =
int Inode::extend(inter_tree_node *F, inter_ti by) {
	if (by == 0) return TRUE;
	if ((F->W.index + F->W.extent + PREFRAME_SIZE < F->W.in_room->size) ||
		(F->W.in_room->next_room)) return FALSE;
		
	if (F->W.in_room->size + (int) by <= F->W.in_room->capacity) {	
		Inode::set_metadata(F, PREFRAME_SKIP_AMOUNT,
			Inode::get_metadata(F, PREFRAME_SKIP_AMOUNT) + by);
		F->W.in_room->size += by;
		F->W.extent += by;
		return TRUE;
	}

	int next_size = Inter::Warehouse::enlarge_size(F->W.in_room->capacity, F->W.extent + PREFRAME_SIZE + (int) by);

	F->W.in_room->next_room = Inter::Warehouse::new_room(F->W.in_room->owning_warehouse,
		next_size, F->W.in_room);

	warehouse_floor_space W = Inter::Warehouse::find_room_in_room(F->W.in_room->next_room, F->W.extent + (int) by);

	F->W.in_room->size = F->W.index;
	F->W.in_room->capacity = F->W.index;

	inter_ti a = Inode::get_metadata(F, PREFRAME_VERIFICATION_COUNT);
	inter_ti b = Inode::get_metadata(F, PREFRAME_ORIGIN);
	inter_ti c = Inode::get_metadata(F, PREFRAME_COMMENT);

	F->W.index = W.index;
	F->W.in_room = W.in_room;
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
	if ((F->W.in_room == NULL) || (F->W.index < 0)) internal_error("no index for null frame");
	return (F->W.in_room->index_offset) + (inter_ti) (F->W.index);
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
		F = InterTree::parent(F);
		if (F == NULL) break;
		if (F->W.data[ID_IFLD] == PACKAGE_IST)
			return F->W.data[PID_PACKAGE_IFLD];
	}
	return 0;
}

void Inode::attach_package(inter_tree_node *F, inter_package *pack) {
	if (F) F->package = pack;
}

