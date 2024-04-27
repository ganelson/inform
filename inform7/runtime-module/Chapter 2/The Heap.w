[TheHeap::] The Heap.

Texts, lists and other flexibly-sized structures make use of a pool of
run-time storage called "the heap".

@ Though we call it a "heap", the layout and policy of how this memory is
handled at runtime is not our business here: all of that is delegated to
kit-defined code in //BasicInformKit: Flex//.

This means the Inform compiler itself can be blissfully ignorant of all that,
though it does need to decide how much memory to allocate:

=
int total_heap_allocation = 0;

void TheHeap::ensure_basic_heap_present(void) {
	total_heap_allocation += 256; /* enough for the initial free-space block */
}

@ By now, we know that we need at least |total_heap_allocation| bytes on the
heap, but the initial heap size has to be a power of 2, so we compute the
smallest such which is big enough. On Glulx, we then multiply by 4: one factor
of 2 is because the word size is twice as much -- words are 4-byte, not 2-byte
as on the Z-machine -- while the other is, basically, because we can, and
because we want to store text in particular using 2-byte characters (capable
of storing Unicode) rather than 1-byte characters as on the Z-machine. Glulx
has essentially no memory constraints compared with the Z-machine.

=
void TheHeap::compile_configuration(void) {
	int max_heap = 1;
	if (total_heap_allocation < global_compilation_settings.dynamic_memory_allocation)
		total_heap_allocation = global_compilation_settings.dynamic_memory_allocation;
	while (max_heap < total_heap_allocation) max_heap = max_heap*2;
	inter_name *iname = Hierarchy::find(MEMORY_HEAP_SIZE_HL);
	if (TargetVMs::is_16_bit(Task::vm()))
		Emit::numeric_constant(iname, (inter_ti) max_heap);
	else
		Emit::numeric_constant(iname, (inter_ti) (4*max_heap));
	Hierarchy::make_available(iname);
	LOG("Providing for a total heap of %d, given requirement of %d\n",
		max_heap, total_heap_allocation);
}

@ The following should be called when we want to create a block value, such as
a text or list, which can be used either globally or temporarily when a
function runs. For more on the latter, see //imperative: Stack Frames//.

It increases the heap size estimate accordingly, and returns a convenient
structure to describe the new value -- recording its kind and its position
in the local M-stack frame. The |stack_offset| should be -1 for a global value,
which is then not stored on the stack.

=
typedef struct heap_allocation {
	struct kind *allocated_kind;
	int stack_offset;
} heap_allocation;

@ We want to make an estimate of the likely size needs of such a value if placed
on the heap -- its exact size needs if it is fixed in size, and a reasonable
overestimate of typical usage if it is flexible.

The |multiplier| is used when we need to calculate the size of, say, a list of
20 texts; it would then, of course, be 20. Any |stack_offset| is simply passed
through to the returned record; we don't understand any of that here.

=
heap_allocation TheHeap::make_allocation(kind *K, int multiplier,
	int stack_offset) {
	if (Kinds::Behaviour::uses_block_values(K) == FALSE)
		internal_error("unable to allocate heap storage for this kind of value");

	int estimate = 2 + Kinds::Behaviour::get_short_block_size(K);
	if (Kinds::Behaviour::get_flexible_long_block_size(K) > 0)
		estimate += Kinds::Behaviour::get_flexible_long_block_size(K);
	else
		estimate += Kinds::Behaviour::get_long_block_size(K);

	total_heap_allocation += (estimate + 8)*multiplier;

	heap_allocation ha;
	ha.allocated_kind = K;
	ha.stack_offset = stack_offset;
	return ha;
}

@ That is usually followed quickly by call to this function, which compiles
runtime code to create the value:

=
void TheHeap::emit_allocation(heap_allocation ha) {
	if (ha.stack_offset >= 0) {
		inter_name *iname = Hierarchy::find(CREATEPVONSTACK_HL);
		EmitCode::call(iname);
		EmitCode::down();
		EmitCode::val_number((inter_ti) ha.stack_offset);
		RTKindIDs::emit_strong_ID_as_val(ha.allocated_kind);
		EmitCode::up();
	} else {
		inter_name *iname = Hierarchy::find(CREATEPV_HL);
		EmitCode::call(iname);
		EmitCode::down();
		RTKindIDs::emit_strong_ID_as_val(ha.allocated_kind);
		EmitCode::up();
	}
}

@ It's not quite true that the Inform compiler knows nothing about the structure
of data managed at runtime, because it does have to compile suitable constant
lists, texts and such. Those occur in a "block" whose header conforms to the
following format, but which then continues differently according to the kind
of value being stored: see //Enclosures// for more.

These constants, and the logic below, must therefore match the understandings
in //BasicInformKit: Flex//.

@d BLK_FLAG_MULTIPLE  0x00000001
@d BLK_FLAG_WORD      0x00000004
@d BLK_FLAG_RESIDENT  0x00000008
@d BLK_FLAG_TRUNCMULT 0x00000010

=
void TheHeap::emit_block_value_header(kind *K, int individual, int size) {
	if (individual == FALSE) EmitArrays::numeric_entry(0);
	int n = 0, c = 1, w = 4;
	if (TargetVMs::is_16_bit(Task::vm())) w = 2;
	while (c < (size + 3)*w) { n++; c = c*2; }
	int flags = BLK_FLAG_RESIDENT + BLK_FLAG_WORD;
	if (Kinds::get_construct(K) == CON_list_of) flags += BLK_FLAG_TRUNCMULT;
	if (Kinds::get_construct(K) == CON_relation) flags += BLK_FLAG_MULTIPLE;
	if (TargetVMs::is_16_bit(Task::vm()))
		EmitArrays::numeric_entry((inter_ti) (0x100*n + flags));
	else
		EmitArrays::numeric_entry((inter_ti) (0x1000000*n + 0x10000*flags));
	EmitArrays::iname_entry(RTKindIDs::weak_iname(K));

	EmitArrays::iname_entry(Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
}
