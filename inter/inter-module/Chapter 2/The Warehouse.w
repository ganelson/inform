[Inter::Warehouse::] The Warehouse.

To manage the memory storage of inter code.

@

=
typedef struct inter_warehouse {
	struct filename *origin_file;
	struct inter_warehouse_room *first_room;
	int size;
	int capacity;
	struct inter_resource_holder *stored_resources;
	MEMORY_MANAGEMENT
} inter_warehouse;

@

@e NO_IRSRC from 0
@e STRING_IRSRC
@e SYMBOLS_TABLE_IRSRC
@e FRAME_LIST_IRSRC
@e PACKAGE_IRSRC
@e REF_IRSRC

=
typedef struct inter_resource_holder {
	int irsrc;
	struct inter_package *owning_package;
	struct inter_symbols_table *stored_symbols_table;
	struct inter_frame_list *stored_frame_list;
	struct inter_package *stored_package;
	struct text_stream *stored_text_stream;
	void *stored_ref;
} inter_resource_holder;

typedef struct inter_warehouse_room {
	struct inter_warehouse *owning_warehouse;
	inter_t index_offset;
	int size;
	int capacity;
	inter_t *bytecode;
	struct inter_warehouse_room *next_room;
	MEMORY_MANAGEMENT
} inter_warehouse_room;

@ =
inter_warehouse *the_only_warehouse = NULL;

inter_warehouse *Inter::Warehouse::new(void) {
	if (the_only_warehouse == NULL) {
		inter_warehouse *warehouse = CREATE(inter_warehouse);
		warehouse->origin_file = NULL;
		warehouse->first_room = Inter::Warehouse::new_room(warehouse, 4096, NULL);
		warehouse->size = 1;
		warehouse->capacity = 0;
		warehouse->stored_resources = NULL;
		the_only_warehouse = warehouse;
	}
	return the_only_warehouse;
}

inter_warehouse_room *Inter::Warehouse::new_room(inter_warehouse *owner, int capacity, inter_warehouse_room *prec) {
	inter_warehouse_room *IS = CREATE(inter_warehouse_room);
	IS->owning_warehouse = owner;
	IS->index_offset = (prec)?(prec->index_offset + (inter_t) prec->capacity):0;
	IS->size = 0;
	IS->capacity = capacity;
	IS->bytecode = (inter_t *)
		Memory::I7_calloc(capacity, sizeof(inter_t), INTER_BYTECODE_MREASON);
	LOGIF(INTER_MEMORY, "Created repository %d segment %d with capacity %d\n",
		owner->allocation_id, IS->allocation_id, IS->capacity);
	return IS;
}

typedef struct warehouse_floor_space {
	struct inter_warehouse_room *repo_segment;
	int index;
	inter_t *data;
	int extent;
} warehouse_floor_space;

warehouse_floor_space Inter::Warehouse::find_room_in_room(inter_warehouse_room *IS, int n) {
	if ((IS->size < 0) || (IS->size > IS->capacity)) internal_error("bad segment");
	if (IS->next_room != NULL) internal_error("nonfinal segment");
	if (IS->size + n + PREFRAME_SIZE > IS->capacity) {
		int next_size = Inter::Warehouse::enlarge_size(IS->capacity, n + PREFRAME_SIZE);
		IS->capacity = IS->size;
		IS->next_room = Inter::Warehouse::new_room(IS->owning_warehouse, next_size, IS);
		IS = IS->next_room;
	}

	int at = IS->size, this_piece = PREFRAME_SIZE + n;
	for (int i=0; i<this_piece; i++) IS->bytecode[at + i] = 0;
	IS->bytecode[at + PREFRAME_SKIP_AMOUNT] = (inter_t) this_piece;
	IS->size += this_piece;

	warehouse_floor_space W;
	W.repo_segment = IS; W.index = at;
	if ((IS) && (at >= 0) && (at < IS->size)) {
		W.data = &(IS->bytecode[at + PREFRAME_SIZE]);
		W.extent = ((int) IS->bytecode[at + PREFRAME_SKIP_AMOUNT]) - PREFRAME_SIZE;
	} else {
		W.data = NULL; W.extent = 0;
	}
	return W;
}

int Inter::Warehouse::enlarge_size(int n, int at_least) {
	int next_size = 2*n;
	if (next_size < 128) next_size = 128;
	while (n + at_least > next_size) next_size = 2*next_size;
	return next_size;
}

inter_tree_node *Inter::Warehouse::find_room(inter_warehouse *warehouse, inter_tree *I,
	int n, inter_error_location *eloc, inter_package *owner) {
	if (warehouse == NULL) internal_error("no warehouse");
	if (I == NULL) internal_error("no tree supplied");
	inter_warehouse_room *IS = warehouse->first_room;
	while (IS->next_room) IS = IS->next_room;
	warehouse_floor_space W = Inter::Warehouse::find_room_in_room(IS, n);
	inter_tree_node *F = Inter::Tree::new_node(I, W);
	Inter::Node::set_metadata(F, PREFRAME_ORIGIN, Inter::Warehouse::store_origin(warehouse, eloc));
	Inter::Node::attach_package(F, owner);
	return F;
}

inter_t Inter::Warehouse::create_resource(inter_warehouse *warehouse) {
	if (warehouse->size >= warehouse->capacity) {
		int new_size = 128;
		while (new_size < 2*warehouse->capacity) new_size = 2*new_size;

		LOGIF(INTER_MEMORY, "Giving warehouse %d frame list of size %d (up from %d)\n",
			warehouse->allocation_id, new_size, warehouse->capacity);

		inter_resource_holder *storage = (inter_resource_holder *) Memory::I7_calloc(new_size, sizeof(inter_resource_holder), INTER_LINKS_MREASON);
		inter_resource_holder *old = warehouse->stored_resources;
		for (int i=0; i<warehouse->capacity; i++) storage[i] = old[i];
		if (warehouse->capacity > 0)
			Memory::I7_free(old, INTER_LINKS_MREASON, warehouse->capacity);
		warehouse->stored_resources = storage;
		warehouse->capacity = new_size;
	}
	int n = warehouse->size ++;
	warehouse->stored_resources[n].irsrc = NO_IRSRC;
	warehouse->stored_resources[n].owning_package = NULL;
	warehouse->stored_resources[n].stored_symbols_table = NULL;
	warehouse->stored_resources[n].stored_ref = NULL;
	warehouse->stored_resources[n].stored_package = NULL;
	warehouse->stored_resources[n].stored_text_stream = NULL;
	warehouse->stored_resources[n].stored_frame_list = NULL;
	return (inter_t) n;
}

inter_t Inter::Warehouse::store_origin(inter_warehouse *warehouse, inter_error_location *eloc) {
	if (eloc) {
		if (eloc->error_interb) {
			warehouse->origin_file = eloc->error_interb;
			return (inter_t) (0x10000000 + eloc->error_offset);
		}
		if (eloc->error_tfp) {
			warehouse->origin_file = eloc->error_tfp->text_file_filename;
			return (inter_t) (eloc->error_tfp->line_count);
		}
	}
	return 0;
}

typedef struct inter_error_stash {
	struct inter_error_location stashed_eloc;
	struct text_file_position stashed_tfp;
	MEMORY_MANAGEMENT
} inter_error_stash;

inter_error_location *Inter::Warehouse::retrieve_origin(inter_warehouse *warehouse, inter_t C) {
	if ((warehouse) && (warehouse->origin_file)) {
		inter_error_stash *stash = CREATE(inter_error_stash);
		stash->stashed_tfp = TextFiles::nowhere();
		if (C < 0x10000000) {
			text_file_position *tfp = &(stash->stashed_tfp);
			tfp->text_file_filename = warehouse->origin_file;
			tfp->line_count = (int) C;
			stash->stashed_eloc = Inter::Errors::file_location(NULL, tfp);
		} else {
			stash->stashed_eloc = Inter::Errors::interb_location(warehouse->origin_file, (size_t) (C - 0x10000000));
		}
		return &(stash->stashed_eloc);
	}
	return NULL;
}

inter_symbols_table *Inter::Warehouse::get_symbols_table(inter_warehouse *warehouse, inter_t n) {
	if (n >= (inter_t) warehouse->size) return NULL;
	if (n == 0) return NULL;
	return warehouse->stored_resources[n].stored_symbols_table;
}

inter_t Inter::Warehouse::create_symbols_table(inter_warehouse *warehouse) {
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_symbols_table == NULL) {
		warehouse->stored_resources[n].irsrc = SYMBOLS_TABLE_IRSRC;
		warehouse->stored_resources[n].stored_symbols_table = Inter::SymbolsTables::new();
		warehouse->stored_resources[n].stored_symbols_table->n_index = (int) n;
	}
	return n;
}

void Inter::Warehouse::attribute_resource(inter_warehouse *warehouse, inter_t n, inter_package *owner) {
	if (n >= (inter_t) warehouse->size) internal_error("out of range");
	warehouse->stored_resources[n].owning_package = owner;
}

text_stream *Inter::Warehouse::get_text(inter_warehouse *warehouse, inter_t n) {
	if (n >= (inter_t) warehouse->size) return NULL;
	return warehouse->stored_resources[n].stored_text_stream;
}

inter_t Inter::Warehouse::create_text(inter_warehouse *warehouse, inter_package *owner) {
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_text_stream == NULL) {
		warehouse->stored_resources[n].irsrc = STRING_IRSRC;
		warehouse->stored_resources[n].stored_text_stream = Str::new();
		warehouse->stored_resources[n].owning_package = owner;
	}
	return n;
}

inter_package *Inter::Warehouse::get_package(inter_warehouse *warehouse, inter_t n) {
	if (n >= (inter_t) warehouse->size) return NULL;
	if (n == 0) return NULL;
	return warehouse->stored_resources[n].stored_package;
}

inter_t Inter::Warehouse::create_package(inter_warehouse *warehouse, inter_tree *I) {
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	if (warehouse->stored_resources[n].stored_package == NULL) {
		warehouse->stored_resources[n].irsrc = PACKAGE_IRSRC;
		warehouse->stored_resources[n].stored_package = Inter::Packages::new(I, n);
		warehouse->stored_resources[n].owning_package =
			warehouse->stored_resources[n].stored_package;
	}
	return n;
}

void *Inter::Warehouse::get_ref(inter_warehouse *warehouse, inter_t n) {
	if (n >= (inter_t) warehouse->size) return NULL;
	return warehouse->stored_resources[n].stored_ref;
}

inter_t Inter::Warehouse::create_ref(inter_warehouse *warehouse) {
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	warehouse->stored_resources[n].irsrc = REF_IRSRC;
	warehouse->stored_resources[n].stored_ref = NULL;
	return n;
}

inter_frame_list *Inter::Warehouse::get_frame_list(inter_warehouse *warehouse, inter_t N) {
	if (warehouse == NULL) return NULL;
	int n = (int) N;
	if (n >= warehouse->size) return NULL;
	return warehouse->stored_resources[n].stored_frame_list;
}

inter_t Inter::Warehouse::create_frame_list(inter_warehouse *warehouse) {
	inter_t n = Inter::Warehouse::create_resource(warehouse);
	warehouse->stored_resources[n].irsrc = FRAME_LIST_IRSRC;
	warehouse->stored_resources[n].stored_frame_list = Inter::Lists::new();
	return n;
}

void Inter::Warehouse::set_ref(inter_warehouse *warehouse, inter_t n, void *ref) {
	if (n >= (inter_t) warehouse->size) return;
	warehouse->stored_resources[n].stored_ref = ref;
}
