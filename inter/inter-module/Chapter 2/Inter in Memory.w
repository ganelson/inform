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
@d PREFRAME_SIZE 10

=
typedef struct inter_repository {
	int ref;
	struct inter_repository_segment *first_repo_segment;
	int size;
	int capacity;
	struct inter_resource_holder *stored_resources;
	struct filename *origin_file;
	struct inter_frame_list global_material;
	struct inter_repository *main_repo;
	struct inter_package *main_package;
	MEMORY_MANAGEMENT
} inter_repository;

typedef struct inter_resource_holder {
	struct inter_symbols_table *stored_symbols_table;
	struct inter_frame_list stored_frame_list;
	struct inter_package *stored_package;
	struct text_stream *stored_text_stream;
	void *stored_ref;
} inter_resource_holder;

typedef struct inter_frame_list {
	int storage_used;
	int storage_capacity;
	struct inter_frame_list_entry *spare_storage;
	struct inter_frame_list_entry *first_in_ifl;
	struct inter_frame_list_entry *last_in_ifl;
} inter_frame_list;

typedef struct inter_frame_list_entry {
	struct inter_frame listed_frame;
	struct inter_frame_list_entry *next_in_ifl;
	struct inter_frame_list_entry *prev_in_ifl;
} inter_frame_list_entry;

typedef struct inter_repository_segment {
	struct inter_repository *owning_repo;
	inter_t index_offset;
	int size;
	int capacity;
	inter_t *bytecode;
	struct inter_repository_segment *next_repo_segment;
	MEMORY_MANAGEMENT
} inter_repository_segment;

@ =
inter_repository *Inter::create(int ref, int capacity) {
	inter_repository *I = CREATE(inter_repository);
	I->ref = ref;
	I->first_repo_segment = Inter::create_segment(capacity, I, NULL);
	I->size = 1;
	I->capacity = 0;
	I->stored_resources = NULL;
	I->origin_file = NULL;
	Inter::create_symbols_table(I);
	I->global_material.spare_storage = NULL;
	I->global_material.storage_used = 0;
	I->global_material.storage_capacity = 0;
	I->main_repo = NULL;
	I->main_package = NULL;
	return I;
}

inter_repository_segment *Inter::create_segment(int capacity, inter_repository *owner, inter_repository_segment *prec) {
	inter_repository_segment *IS = CREATE(inter_repository_segment);
	IS->index_offset = (prec)?(prec->index_offset + (inter_t) prec->capacity):0;
	IS->owning_repo = owner;
	IS->size = 0;
	IS->capacity = capacity;
	IS->bytecode = (inter_t *)
		Memory::I7_calloc(capacity, sizeof(inter_t), INTER_BYTECODE_MREASON);
	LOGIF(INTER_MEMORY, "Created repository %d segment %d with capacity %d\n",
		owner->allocation_id, IS->allocation_id, IS->capacity);
	return IS;
}

int Inter::enlarge_size(int n, int at_least) {
	int next_size = 2*n;
	if (next_size < 128) next_size = 128;
	while (n + at_least > next_size) next_size = 2*next_size;
	return next_size;
}

inter_frame Inter::find_room(inter_repository *I, int n, inter_error_location *eloc, inter_package *owner) {
	if (I == NULL) internal_error("no repository");
	inter_repository_segment *IS = I->first_repo_segment;
	while (IS->next_repo_segment) IS = IS->next_repo_segment;
	inter_frame F = Inter::find_room_in_segment(IS, n);
	F.repo_segment->bytecode[F.index + PREFRAME_ORIGIN] = Inter::store_origin(I, eloc);
	Inter::Frame::attach_package(F, Inter::Packages::to_PID(owner));
	return F;
}

void Inter::dump_segments(OUTPUT_STREAM, inter_repository *I) {
	for (inter_repository_segment *J = I->first_repo_segment; J; J = J->next_repo_segment) {
		WRITE("%08x: size %d capacity %d: ", (long int) J, J->size, J->capacity);
		for (int i=0; i<J->size; i++) {
			WRITE("%08x ", J->bytecode[i]);
		}
		WRITE("\n");
	}
}

void Inter::check_segments(inter_repository *I) {
	for (inter_repository_segment *J = I->first_repo_segment; J; J = J->next_repo_segment) {
		if ((J->size > 0) && (J->bytecode[0] == 0)) {
			WRITE_TO(STDERR, "Repository segment %d is corrupt\n", J->allocation_id);
			internal_error("segment corrupt");
		}
	}
}

inter_frame Inter::find_room_in_segment(inter_repository_segment *IS, int n) {
	if ((IS->size < 0) || (IS->size > IS->capacity)) internal_error("bad segment");
	if (IS->next_repo_segment != NULL) internal_error("nonfinal segment");
	if (IS->size + n + PREFRAME_SIZE > IS->capacity) {
		int next_size = Inter::enlarge_size(IS->capacity, n + PREFRAME_SIZE);
		IS->capacity = IS->size;
		IS->next_repo_segment = Inter::create_segment(next_size, IS->owning_repo, IS);
		IS = IS->next_repo_segment;
		Inter::check_segments(IS->owning_repo);
	}

	int at = IS->size;
	IS->bytecode[at + PREFRAME_SKIP_AMOUNT] = (inter_t) (n + PREFRAME_SIZE);
	IS->bytecode[at + PREFRAME_VERIFICATION_COUNT] = 0;
	IS->bytecode[at + PREFRAME_ORIGIN] = 0;
	IS->bytecode[at + PREFRAME_COMMENT] = 0;
	IS->bytecode[at + PREFRAME_PACKAGE] = 0;
	IS->bytecode[at + PREFRAME_PARENT] = 0;
	IS->bytecode[at + PREFRAME_FIRST_CHILD] = 0;
	IS->bytecode[at + PREFRAME_LAST_CHILD] = 0;
	IS->bytecode[at + PREFRAME_PREVIOUS] = 0;
	IS->bytecode[at + PREFRAME_NEXT] = 0;
	for (int i=0; i<n; i++) IS->bytecode[at + PREFRAME_SIZE + i] = 0;
	IS->size += n + PREFRAME_SIZE;
	inter_frame F = Inter::Frame::around(IS, at);
	return F;
}

inter_t Inter::create_resource(inter_repository *I) {
	if (I == NULL) internal_error("no repository");
	if (I->size >= I->capacity) {
		int new_size = 128;
		while (new_size < 2*I->capacity) new_size = 2*new_size;

		LOGIF(INTER_MEMORY, "Giving repository %d frame list of size %d (up from %d)\n",
			I->allocation_id, new_size, I->capacity);

		inter_resource_holder *storage = (inter_resource_holder *) Memory::I7_calloc(new_size, sizeof(inter_resource_holder), INTER_LINKS_MREASON);
		inter_resource_holder *old = I->stored_resources;
		for (int i=0; i<I->capacity; i++) storage[i] = old[i];
		if (I->capacity > 0)
			Memory::I7_free(old, INTER_LINKS_MREASON, I->capacity);
		I->stored_resources = storage;
		I->capacity = new_size;
	}
	int n = I->size ++;
	I->stored_resources[n].stored_symbols_table = NULL;
	I->stored_resources[n].stored_ref = NULL;
	I->stored_resources[n].stored_package = NULL;
	I->stored_resources[n].stored_text_stream = NULL;
	I->stored_resources[n].stored_frame_list.spare_storage = NULL;
	I->stored_resources[n].stored_frame_list.storage_used = 0;
	I->stored_resources[n].stored_frame_list.storage_capacity = 0;
	I->stored_resources[n].stored_frame_list.first_in_ifl = NULL;
	I->stored_resources[n].stored_frame_list.last_in_ifl = NULL;
	return (inter_t) n;
}

inter_t Inter::create_symbols_table(inter_repository *I) {
	inter_t n = Inter::create_resource(I);
	if (I->stored_resources[n].stored_symbols_table == NULL) {
		I->stored_resources[n].stored_symbols_table = Inter::SymbolsTables::new();
		I->stored_resources[n].stored_symbols_table->n_index = (int) n;
	}
	return n;
}

inter_symbols_table *Inter::get_global_symbols(inter_repository *I) {
	return Inter::get_symbols_table(I, 1);
}

inter_symbols_table *Inter::get_symbols_table(inter_repository *I, inter_t n) {
	if (n >= (inter_t) I->size) return NULL;
	if (n == 0) return NULL;
	return I->stored_resources[n].stored_symbols_table;
}

inter_t Inter::create_package(inter_repository *I) {
	inter_t n = Inter::create_resource(I);
	if (I->stored_resources[n].stored_package == NULL) {
		I->stored_resources[n].stored_package = Inter::Packages::new(I, n);
	}
	return n;
}

inter_package *Inter::get_package(inter_repository *I, inter_t n) {
	if (n >= (inter_t) I->size) return NULL;
	if (n == 0) return NULL;
	return I->stored_resources[n].stored_package;
}

inter_t Inter::create_text(inter_repository *I) {
	inter_t n = Inter::create_resource(I);
	if (I->stored_resources[n].stored_text_stream == NULL) {
		I->stored_resources[n].stored_text_stream = Str::new();
	}
	return n;
}

text_stream *Inter::get_text(inter_repository *I, inter_t n) {
	if (n >= (inter_t) I->size) return NULL;
	return I->stored_resources[n].stored_text_stream;
}

inter_t Inter::create_ref(inter_repository *I) {
	inter_t n = Inter::create_resource(I);
	I->stored_resources[n].stored_ref = NULL;
	return n;
}

void *Inter::get_ref(inter_repository *I, inter_t n) {
	if (n >= (inter_t) I->size) return NULL;
	return I->stored_resources[n].stored_ref;
}

void Inter::set_ref(inter_repository *I, inter_t n, void *ref) {
	if (n >= (inter_t) I->size) return;
	I->stored_resources[n].stored_ref = ref;
}

inter_t Inter::create_frame_list(inter_repository *I) {
	return Inter::create_resource(I);
}

@

@d LOOP_THROUGH_INTER_FRAME_LIST(F, ifl)
	for (inter_frame_list_entry *F##_entry = (ifl)?(ifl->first_in_ifl):NULL; F##_entry; F##_entry = F##_entry->next_in_ifl)
		if (Inter::Frame::valid(((F = F##_entry->listed_frame), &F)))

=
inter_frame_list *Inter::find_frame_list(inter_repository *I, inter_t N) {
	if (I == NULL) return NULL;
	int n = (int) N;
	if (n >= I->size) return NULL;
	return &(I->stored_resources[n].stored_frame_list);
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

inter_t Inter::store_origin(inter_repository *I, inter_error_location *eloc) {
	if (eloc) {
		if (eloc->error_interb) {
			I->origin_file = eloc->error_interb;
			return (inter_t) (0x10000000 + eloc->error_offset);
		}
		if (eloc->error_tfp) {
			I->origin_file = eloc->error_tfp->text_file_filename;
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

inter_error_location *Inter::retrieve_origin(inter_repository *I, inter_t C) {
	if ((I) && (I->origin_file)) {
		inter_error_stash *stash = CREATE(inter_error_stash);
		stash->stashed_tfp = TextFiles::nowhere();
		if (C < 0x10000000) {
			text_file_position *tfp = &(stash->stashed_tfp);
			tfp->text_file_filename = I->origin_file;
			tfp->line_count = (int) C;
			stash->stashed_eloc = Inter::Errors::file_location(NULL, tfp);
		} else {
			stash->stashed_eloc = Inter::Errors::interb_location(I->origin_file, (size_t) (C - 0x10000000));
		}
		return &(stash->stashed_eloc);
	}
	return NULL;
}

void Inter::traverse_global_list(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state, int filter) {
	inter_frame P;
	LOOP_THROUGH_INTER_FRAME_LIST(P, (&(from->global_material))) {
		if ((filter == 0) ||
			((filter > 0) && (P.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (P.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, P, state);
	}
}

void Inter::traverse_tree(inter_repository *from, void (*visitor)(inter_repository *, inter_frame, void *), void *state, inter_package *mp, int filter) {
	if (mp == NULL) mp = Inter::Packages::main(from);
	if (mp) {
		inter_frame D = Inter::Symbols::defining_frame(mp->package_name);
		if ((filter == 0) ||
			((filter > 0) && (D.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (D.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, D, state);
		Inter::traverse_tree_r(from, D, visitor, state, filter);
	}
}
void Inter::traverse_tree_r(inter_repository *from, inter_frame P, void (*visitor)(inter_repository *, inter_frame, void *), void *state, int filter) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((filter == 0) ||
			((filter > 0) && (C.data[ID_IFLD] == (inter_t) filter)) ||
			((filter < 0) && (C.data[ID_IFLD] != (inter_t) -filter)))
			(*visitor)(from, C, state);
		Inter::traverse_tree_r(from, C, visitor, state, filter);
	}
}
