[Inter::] Inter in Memory.

To store bytecode-like intermediate code in memory.

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
@d PREFRAME_PACKAGE 4
@d PREFRAME_PARENT 5
@d PREFRAME_FIRST_CHILD 6
@d PREFRAME_LAST_CHILD 7
@d PREFRAME_PREVIOUS 8
@d PREFRAME_NEXT 9
@d PREFRAME_GLOBALS 10
@d PREFRAME_SIZE 11

=
typedef struct inter_tree {
	struct inter_warehouse *warehouse;
	struct inter_frame root_definition_frame;
	struct inter_package *root_package;
	struct inter_package *main_package;
	MEMORY_MANAGEMENT
} inter_tree;

@ =
inter_tree *Inter::create(void) {
	inter_tree *I = CREATE(inter_tree);
	I->main_package = NULL;

	I->warehouse = Inter::Warehouse::new();
	inter_t N = Inter::create_symbols_table(I);
	I->root_package = Inter::get_package(I, Inter::create_package(I));
	I->root_definition_frame = Inter::Frame::root_frame(I);
	Inter::Packages::make_rootlike(I->root_package);
	Inter::Packages::set_scope(I->root_package, Inter::get_symbols_table(I, N));
	return I;
}

inter_warehouse *Inter::warehouse(inter_tree *I) {
	return I->warehouse;
}

inter_t Inter::create_symbols_table(inter_tree *I) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_symbols_table == NULL) {
		warehouse->stored_resources[n].stored_symbols_table = Inter::SymbolsTables::new();
		warehouse->stored_resources[n].stored_symbols_table->n_index = (int) n;
	}
	return n;
}

inter_symbols_table *Inter::get_global_symbols(inter_tree *I) {
	return Inter::Packages::scope(I->root_package);
}

inter_symbols_table *Inter::get_symbols_table(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_symbols_table(Inter::warehouse(I), n);
}

inter_t Inter::create_package(inter_tree *I) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_package == NULL) {
		warehouse->stored_resources[n].stored_package = Inter::Packages::new(I, n);
	}
	return n;
}

inter_package *Inter::get_package(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_package(Inter::warehouse(I), n);
}

inter_t Inter::create_text(inter_tree *I) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_text_stream == NULL) {
		warehouse->stored_resources[n].stored_text_stream = Str::new();
	}
	return n;
}

text_stream *Inter::get_text(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_text(Inter::warehouse(I), n);
}

inter_t Inter::create_ref(inter_tree *I) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	warehouse->stored_resources[n].stored_ref = NULL;
	return n;
}

void *Inter::get_ref(inter_tree *I, inter_t n) {
	return Inter::Warehouse::get_ref(Inter::warehouse(I), n);
}

void Inter::set_ref(inter_tree *I, inter_t n, void *ref) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	if (n >= (inter_t) warehouse->size) return;
	warehouse->stored_resources[n].stored_ref = ref;
}

inter_frame_list *Inter::new_frame_list(void) {
	inter_frame_list *ifl = CREATE(inter_frame_list);
	ifl->spare_storage = NULL;
	ifl->storage_used = 0;
	ifl->storage_capacity = 0;
	ifl->first_in_ifl = NULL;
	ifl->last_in_ifl = NULL;
	return ifl;
}

inter_t Inter::create_frame_list(inter_tree *I) {
	inter_warehouse *warehouse = Inter::warehouse(I);
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	warehouse->stored_resources[n].stored_frame_list = CREATE(inter_frame_list);
	warehouse->stored_resources[n].stored_frame_list->spare_storage = NULL;
	warehouse->stored_resources[n].stored_frame_list->storage_used = 0;
	warehouse->stored_resources[n].stored_frame_list->storage_capacity = 0;
	warehouse->stored_resources[n].stored_frame_list->first_in_ifl = NULL;
	warehouse->stored_resources[n].stored_frame_list->last_in_ifl = NULL;
	return n;
}

typedef struct inter_frame_list {
	int storage_used;
	int storage_capacity;
	struct inter_frame_list_entry *spare_storage;
	struct inter_frame_list_entry *first_in_ifl;
	struct inter_frame_list_entry *last_in_ifl;
	MEMORY_MANAGEMENT
} inter_frame_list;

typedef struct inter_frame_list_entry {
	struct inter_frame listed_frame;
	struct inter_frame_list_entry *next_in_ifl;
	struct inter_frame_list_entry *prev_in_ifl;
	MEMORY_MANAGEMENT
} inter_frame_list_entry;

@

@d LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
	for (inter_frame_list_entry *F##_entry = (ifl)?(ifl->first_in_ifl):NULL; F##_entry; F##_entry = F##_entry->next_in_ifl)
		if (Inter::Frame::valid(((F = F##_entry->listed_frame), &F)))

=
inter_frame_list *Inter::find_frame_list(inter_tree *I, inter_t N) {
	if (I == NULL) return NULL;
	return Inter::Warehouse::get_frame_list(Inter::warehouse(I), N);
}

inter_frame Inter::first_child(inter_frame P) {
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		return F;
	return Inter::Frame::around(NULL, -1);
}

inter_frame Inter::second_child(inter_frame P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 2)
			return F;
	return Inter::Frame::around(NULL, -1);
}

inter_frame Inter::third_child(inter_frame P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 3)
			return F;
	return Inter::Frame::around(NULL, -1);
}

inter_frame Inter::fourth_child(inter_frame P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 4)
			return F;
	return Inter::Frame::around(NULL, -1);
}

inter_frame Inter::fifth_child(inter_frame P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 5)
			return F;
	return Inter::Frame::around(NULL, -1);
}

inter_frame Inter::sixth_child(inter_frame P) {
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P)
		if (++c == 6)
			return F;
	return Inter::Frame::around(NULL, -1);
}

void Inter::add_to_frame_list(inter_frame_list *FL, inter_frame F) {
	if (Inter::Frame::valid(&F) == FALSE) internal_error("linked imvalid frame");
	if (FL == NULL) internal_error("bad frame list");
	if (FL->storage_used >= FL->storage_capacity) {
		int new_size = 128;
		while (new_size < 2*FL->storage_capacity) new_size = 2*new_size;

		inter_frame_list_entry *storage = (inter_frame_list_entry *) Memory::I7_calloc(new_size, sizeof(inter_frame_list_entry), INTER_LINKS_MREASON);
		FL->spare_storage = storage;
		FL->storage_used = 0;
		FL->storage_capacity = new_size;
	}

	inter_frame_list_entry *entry = &(FL->spare_storage[FL->storage_used ++]);
	entry->listed_frame = F;
	entry->next_in_ifl = NULL;
	entry->prev_in_ifl = FL->last_in_ifl;
	if (FL->last_in_ifl) FL->last_in_ifl->next_in_ifl = entry;
	FL->last_in_ifl = entry;
	if (FL->first_in_ifl == NULL) FL->first_in_ifl = entry;
}

typedef struct inter_error_stash {
	struct inter_error_location stashed_eloc;
	struct text_file_position stashed_tfp;
	MEMORY_MANAGEMENT
} inter_error_stash;

void Inter::traverse_global_list(inter_tree *from, void (*visitor)(inter_tree *, inter_frame, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(P, (from->root_definition_frame)) {
		if ((filter == 0) ||
			((filter > 0) && (P.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (P.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, P, state);
	}
}

void Inter::set_mask(inter_tree *I, inter_package *mp) {
	if (mp) {
		while (mp) {
			inter_package *par = Inter::Packages::parent(mp);
			if (par) par->mask_down = mp;
			mp = par;
		}
	} else {
		mp = Inter::Packages::main(I);
		while (mp->mask_down) {
			inter_package *ch = mp->mask_down;
			mp->mask_down = NULL;
			mp = ch;
		}
	}
}

void Inter::traverse_tree(inter_tree *from, void (*visitor)(inter_tree *, inter_frame, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Inter::Packages::main(from);
	if (mp) {
		while (mp->mask_down) {
			inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
			mp = mp->mask_down;
			if ((filter == 0) ||
				((filter > 0) && (D.data[ID_IFLD] == (inter_t) filter)) ||
				((filter < 0) && (D.data[ID_IFLD] != (inter_t) -filter)))
				(*visitor)(from, D, state);
			Inter::traverse_tree_r(from, D, visitor, state, filter);
		}
		inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
		if ((filter == 0) ||
			((filter > 0) && (D.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (D.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, D, state);
		Inter::traverse_tree_r(from, D, visitor, state, filter);
	}
}
void Inter::traverse_tree_r(inter_tree *from, inter_frame P, void (*visitor)(inter_tree *, inter_frame, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (C.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, C, state);
		Inter::traverse_tree_r(from, C, visitor, state, filter);
	}
}
