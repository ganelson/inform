[InterWarehouse::] The Warehouse.

To manage the memory storage of inter code.

@h Introduction.
The data structure in this section may bring to mind the title of the Metallica
song "The Thing That Should Not Be", but it works. It's also better than it used
to be (which is more than you can say for Metallica).

Each inter tree needs to store data outside of its own //inter_tree_node// structures,
data which falls into two categories:

(*) Bytecode for instructions, each having a unique address.
(*) Resources such as texts and symbols tables, each having a unique ID number.

This data is held in the //inter_warehouse// connected to the tree. Each //inter_tree//
contains a pointer to its warehouse.

=
typedef struct inter_warehouse {
	/* bytecode storage */
	struct inter_warehouse_room *first_room;
	struct inter_warehouse_room *last_room;

	/* resource storage */
	inter_ti next_free_resource_ID;
	struct inter_warehouse_resource *stored_resources;
	inter_ti resources_capacity;

	CLASS_DEFINITION
} inter_warehouse;

@ An implementation secret, though, is that (in the present implementation, anyway)
there is only one warehouse. If there are multiple trees, they all share the use
of a single warehouse, though they don't know it. This would cause thread-safety
issues if Inter had any aspiration to be threaded, but it does not have. And this
single-warehouse design makes it much faster to carry out "transmigration" -- the
movement of branches of Inter from one tree to another -- since the associated
bytecode and resources do not need to be copied from one warehouse to another.

In this description we continue to talk about "a" warehouse, regardless of the
secret fact that there is only one.

=
inter_warehouse *the_only_warehouse = NULL;

inter_warehouse *InterWarehouse::new(void) {
	if (the_only_warehouse == NULL) {
		inter_warehouse *warehouse = CREATE(inter_warehouse);

		warehouse->first_room = NULL;
		warehouse->last_room = NULL;

		warehouse->next_free_resource_ID = 1;
		warehouse->stored_resources = NULL;
		warehouse->resources_capacity = 0;

		the_only_warehouse = warehouse;
	}
	return the_only_warehouse;
}

@h The resources.
The warehouse provides an array associating ID numbers with "resources": for
example, texts, or symbols tables. An ID is an unsigned integer with the lowest
legal ID being 1, so that 0 can safely be used to mean "no resource". Once
assigned, an ID is never reused.

Lookup needs tp be fast, so we store the list of resources as a flat array
which doubles in size each time its capacity is exceeded. This typically happens
about 10 times in a run of //inform7//, for example, to hold on the order of
100,000 resources.

=
typedef struct inter_warehouse_resource {
	struct general_pointer res;
	struct inter_package *resource_owner;
} inter_warehouse_resource;

@ =
inter_ti InterWarehouse::create_resource(inter_warehouse *warehouse) {
	if (warehouse->next_free_resource_ID >= warehouse->resources_capacity)
		@<Double the resource list capacity@>;
	inter_ti n = warehouse->next_free_resource_ID++;
	warehouse->stored_resources[n].res = NULL_GENERAL_POINTER;
	warehouse->stored_resources[n].resource_owner = NULL;
	return n;
}

@<Double the resource list capacity@> =
	inter_ti new_size = 128;
	while (new_size < 2*warehouse->resources_capacity) new_size = 2*new_size;

	LOGIF(INTER_MEMORY, "Giving warehouse %d resource list of size %d (up from %d)\n",
		warehouse->allocation_id, new_size, warehouse->resources_capacity);

	inter_warehouse_resource *storage = (inter_warehouse_resource *)
		Memory::calloc((int) new_size, sizeof(inter_warehouse_resource), INTER_LINKS_MREASON);
	inter_warehouse_resource *old = warehouse->stored_resources;
	for (inter_ti i=0; i<warehouse->resources_capacity; i++) storage[i] = old[i];
	if (warehouse->resources_capacity > 0)
		Memory::I7_free(old, INTER_LINKS_MREASON, (int) warehouse->resources_capacity);
	warehouse->stored_resources = storage;
	warehouse->resources_capacity = new_size;

@ Every resource is tied to a package which owns it. This is only in fact used to
determine the tree which owns it -- but we store the package, not the tree, because
when material transmigrates from one tree to another, the owning package can then
stay the same: it is just that //InterPackage::tree// will return a different
tree after the movement has taken place.

The following conveniently loops through all valid resource IDs for a given tree:

@d LOOP_OVER_RESOURCE_IDS(n, I)
	for (inter_ti n = 1; n < I->housed->next_free_resource_ID; n++)
		if ((I->housed->stored_resources[n].resource_owner == NULL) ||
			(InterPackage::tree(I->housed->stored_resources[n].resource_owner) == I))

@ So what can a resource be? The following types are supported, and can be
deduced by looking at what class is stored in the general pointer |res|; this
saves redundantly storing a type field in //inter_warehouse_resource//.

@e TEXT_IRSRC from 1
@e SYMBOLS_TABLE_IRSRC
@e NODE_LIST_IRSRC
@e PACKAGE_REF_IRSRC

=
inter_ti InterWarehouse::resource_type_code(inter_warehouse *warehouse, inter_ti n) {
	if ((n == 0) || (n >= warehouse->next_free_resource_ID)) internal_error("bad resource ID");
	switch (warehouse->stored_resources[n].res.run_time_type_code) {
		case text_stream_CLASS:         return TEXT_IRSRC;
		case inter_symbols_table_CLASS: return SYMBOLS_TABLE_IRSRC;
		case inter_node_list_CLASS:     return NODE_LIST_IRSRC;
		case inter_package_CLASS:       return PACKAGE_REF_IRSRC;
	}
	return 0;
}

int InterWarehouse::known_type_code(inter_warehouse *warehouse, inter_ti n) {
	if ((n == 0) || (n >= warehouse->next_free_resource_ID)) return 0;
	switch (warehouse->stored_resources[n].res.run_time_type_code) {
		case text_stream_CLASS:         return TEXT_IRSRC;
		case inter_symbols_table_CLASS: return SYMBOLS_TABLE_IRSRC;
		case inter_node_list_CLASS:     return NODE_LIST_IRSRC;
		case inter_package_CLASS:       return PACKAGE_REF_IRSRC;
	}
	return 0;
}

@ First, it can be a text:

=
inter_ti InterWarehouse::create_text(inter_warehouse *warehouse, inter_package *owner) {
	return InterWarehouse::create_ref(warehouse, STORE_POINTER_text_stream(Str::new()), owner);
}

inter_ti InterWarehouse::create_text_at(inter_bookmark *IBM) {
	return InterWarehouse::create_text(
		InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
}

text_stream *InterWarehouse::get_text(inter_warehouse *warehouse, inter_ti n) {
	general_pointer gp = InterWarehouse::get_ref(warehouse, n);
	if (gp.run_time_type_code != text_stream_CLASS) return NULL;
	return RETRIEVE_POINTER_text_stream(gp);
}

@ Second, a symbols table. Uniquely, this one does not specify an owning package
when the resource is created: that's because a package can only be made when a
symbols table for it already exists, so we need the table first. The owner is
therefore initially not set, and must be explicitly set after the package has
been created, using //InterWarehouse::set_symbols_table_owner//.

=
inter_ti InterWarehouse::create_symbols_table(inter_warehouse *warehouse) {
	inter_ti n = InterWarehouse::create_resource(warehouse);
	inter_symbols_table *new_table = InterSymbolsTable::new(n);
	return InterWarehouse::create_ref_at(warehouse, n,
		STORE_POINTER_inter_symbols_table(new_table), NULL);
}

void InterWarehouse::set_symbols_table_owner(inter_warehouse *warehouse, inter_ti n,
	inter_package *owner) {
	if (InterWarehouse::get_symbols_table(warehouse, n) == NULL)
		internal_error("not a symbols table");
	warehouse->stored_resources[n].resource_owner = owner;
}

inter_symbols_table *InterWarehouse::get_symbols_table(inter_warehouse *warehouse,
	inter_ti n) {
	general_pointer gp = InterWarehouse::get_ref(warehouse, n);
	if (gp.run_time_type_code != inter_symbols_table_CLASS) return NULL;
	return RETRIEVE_POINTER_inter_symbols_table(gp);
}

@ Third, a resource can be a package -- or, really, a pointer to a package, a
form of resource which allows bytecode to contain cross-references to packages.

This may as well be its own owner, since it can be valid only if the package
pointed to is in the same tree as the bytecode instruction using the resource.

=
inter_ti InterWarehouse::create_package(inter_warehouse *warehouse, inter_tree *I) {
	inter_ti n = InterWarehouse::create_resource(warehouse);
	inter_package *new_pack = InterPackage::new(I, n);
	return InterWarehouse::create_ref_at(warehouse, n, STORE_POINTER_inter_package(new_pack),
		new_pack);
}

inter_package *InterWarehouse::get_package(inter_warehouse *warehouse, inter_ti n) {
	general_pointer gp = InterWarehouse::get_ref(warehouse, n);
	if (gp.run_time_type_code != inter_package_CLASS) return NULL;
	return RETRIEVE_POINTER_inter_package(gp);
}

@ Finally, a node list.

=
inter_ti InterWarehouse::create_node_list(inter_warehouse *warehouse, inter_package *owner) {
	return InterWarehouse::create_ref(warehouse,
		STORE_POINTER_inter_node_list(InterNodeList::new()), owner);
}

inter_node_list *InterWarehouse::get_node_list(inter_warehouse *warehouse, inter_ti n) {
	general_pointer gp = InterWarehouse::get_ref(warehouse, n);
	if (gp.run_time_type_code != inter_node_list_CLASS) return NULL;
	return RETRIEVE_POINTER_inter_node_list(gp);
}

@ All of which use the following:

=
general_pointer InterWarehouse::get_ref(inter_warehouse *warehouse, inter_ti n) {
	if ((n == 0) || (n >= warehouse->next_free_resource_ID)) return NULL_GENERAL_POINTER;
	return warehouse->stored_resources[n].res;
}

inter_ti InterWarehouse::create_ref(inter_warehouse *warehouse, 
	general_pointer ref, inter_package *owner) {
	inter_ti n = InterWarehouse::create_resource(warehouse);
	return InterWarehouse::create_ref_at(warehouse, n, ref, owner);
}

inter_ti InterWarehouse::create_ref_at(inter_warehouse *warehouse, inter_ti n,
	general_pointer ref, inter_package *owner) {
	warehouse->stored_resources[n].res = ref;
	warehouse->stored_resources[n].resource_owner = owner;
	return n;
}

@h The bytecode storage.
Conceptually, a warehouse stores bytecode at (word) addresses which begin from 0.
Each instruction occupies a contiguous run of addresses. That all sounds like
a typical machine-code arrangement, but:

(a) the instructions themselves contain neither absolute addresses nor address
offsets -- they are oblivious to where they are stored, and refer to code
positions using labels instead;

(b) some storage may remain unused, and the addresses of instructions do not
correspond to their order in the code.

=
typedef struct inter_warehouse_room {
	struct inter_warehouse *owning_warehouse;
	int room_usage;
	int room_capacity;
	inter_ti *bytecode;
	struct inter_warehouse_room *next_room;
	CLASS_DEFINITION
} inter_warehouse_room;

@ The warehouse is divided into a series of rooms of steadily telescoping sizes.
Unless an improbably large demand is made for a very long single instruction,
they will typically look like:
= (text)
	room 0      addresses 0x000000 to 0x000fff (4K words)
	room 1      addresses 0x001000 to 0x002fff (8K words)
	room 2		addresses 0x003000 to 0x006fff (16K words)
	room 3      addresses 0x007000 to 0x00efff (32K words)
	...
=
though probably not with boundaries as neat as that, since there will be a
few words of unused space at the end of each room.

In a typical //inform7// run, we reach about the 9th room, so that the address
space amounts to around 2 million words.

@ A single instruction will occupy a contiguous run of addresses, and will
consist of a preframe (always |PREFRAME_SIZE| words) and then a frame (of
a variable size, though always at least 2 words). This will always lie
inside a single room: this is why, if we ask for an instruction with a
50000-word frame, we would force larger rooms to be created.

The following represents where an instruction is stored. The address of the
preframe will be |index| plus the sum of |room_usage| for previous rooms; the address
of the frame will be |PREFRAME_SIZE| more than that, since the frame always
immediately follows the preframe. |instruction| points to the first word of
the frame, and the |extent| is the size of the frame, so the size of the whole
instruction is |extent + PREFRAME_SIZE|.

Note that |instruction| and |extent| are both in principle redundant in this
structure. If you know |in_room| and |index| you know everything, because:
= (text as InC)
	W.instruction == W.in_room->bytecode + W.index + PREFRAME_SIZE
	W.extent == W.in_room->bytecode[W.index + PREFRAME_SKIP_AMOUNT] - PREFRAME_SIZE
=
But speed of access is so important that we store these two fields redundantly
in order to cache the results of those two calculations.

=
typedef struct warehouse_floor_space {
	struct inter_warehouse_room *in_room;
	int index;
	inter_ti *instruction;
	int extent;
} warehouse_floor_space;

@ We provide an API of just two functions to handle all this. Firstly,
//InterWarehouse::make_floor_space// makes room for an instruction of |n| words.
(This is the frame extent, and does not include the |PREFRAME_SIZE|.)

Note that this function always succeeds, because an internal error is thrown
if the system is out of memory.

=
warehouse_floor_space InterWarehouse::make_floor_space(inter_warehouse *warehouse, int n) {
	int total_extent = n + PREFRAME_SIZE;
	@<Make a new and bigger room if necessary@>;

	inter_warehouse_room *IS = warehouse->last_room;
	int at = IS->room_usage;
	for (int i=0; i<total_extent; i++) IS->bytecode[at + i] = 0;
	IS->bytecode[at + PREFRAME_SKIP_AMOUNT] = (inter_ti) total_extent;
	IS->room_usage += total_extent;

	warehouse_floor_space W;
	W.in_room = IS; W.index = at;
	if ((IS) && (at >= 0) && (at < IS->room_usage)) {
		W.instruction = &(IS->bytecode[at + PREFRAME_SIZE]);
		W.extent = ((int) IS->bytecode[at + PREFRAME_SKIP_AMOUNT]) - PREFRAME_SIZE;
	} else {
		W.instruction = NULL; W.extent = 0;
	}
	return W;
}

@<Make a new and bigger room if necessary@> =
	inter_warehouse_room *IS = warehouse->last_room;
	if ((IS == NULL) || (IS->room_usage + total_extent > IS->room_capacity)) {
		if (IS) IS->room_capacity = IS->room_usage;

		int new_capacity = 4096;
		if (IS) new_capacity = 2*IS->room_capacity;
		while (total_extent >= new_capacity) new_capacity = 2*new_capacity;
	
		inter_warehouse_room *new_room = CREATE(inter_warehouse_room);
		new_room->owning_warehouse = warehouse;
		new_room->room_usage = 0;
		new_room->room_capacity = new_capacity;
		new_room->bytecode = (inter_ti *)
			Memory::calloc(new_capacity, sizeof(inter_ti), INTER_BYTECODE_MREASON);
		LOGIF(INTER_MEMORY, "Created warehouse room %d with capacity %08x\n",
			new_room->allocation_id, new_room->room_capacity);
		if (IS) IS->next_room = new_room;
		else warehouse->first_room = new_room;
		warehouse->last_room = new_room;
	}

@ Secondly, //InterWarehouse::enlarge_floor_space// adds extra length to an
existing instruction -- which may involve moving its bytecode to a bigger room,
in the worst case, but is more typically very fast. Note that this function
may only be called on the floor space for the most-recently creates instruction,
so the floor space is guaranteed to be at the end of the space used in the
current room.

|by| cannot be negative (it is unsigned). The instruction therefore always
extends, not contracts. The values of the new words added are undefined:
they will very likely be 0 but do not rely upon this.

Note that this function always succeeds, because an internal error is thrown
if the system is out of memory.

=
warehouse_floor_space InterWarehouse::enlarge_floor_space(warehouse_floor_space FW,
	inter_ti by) {
	/* Have we already moved on to building further instructions? */
	if (FW.in_room->next_room) internal_error("too late to extend instruction");
		
	if (FW.in_room->room_usage + (int) by <= FW.in_room->room_capacity)
		@<The existing room already has sufficient capacity to accommodate the extra@>
	else
		@<The existing room is not big enough@>;

	return FW;
}

@<The existing room already has sufficient capacity to accommodate the extra@> =
	FW.in_room->bytecode[FW.index + PREFRAME_SKIP_AMOUNT] += by;
	FW.in_room->room_usage += by;
	FW.extent += by;

@<The existing room is not big enough@> =
	warehouse_floor_space new_W =
		InterWarehouse::make_floor_space(FW.in_room->owning_warehouse, FW.extent + (int) by);

	FW.in_room->room_usage = FW.index;
	FW.in_room->room_capacity = FW.index;

	@<Copy the bytecode for the preframe and frame to its new home@>;

@<Copy the bytecode for the preframe and frame to its new home@> =
	for (int i=0; i<PREFRAME_SIZE; i++)
		if (i != PREFRAME_SKIP_AMOUNT)
			new_W.in_room->bytecode[new_W.index + i] = FW.in_room->bytecode[FW.index + i];

	for (int i=0; i<new_W.extent; i++)
		if (i < FW.extent)
			new_W.instruction[i] = FW.instruction[i];
		else
			new_W.instruction[i] = 0;

	FW = new_W;
