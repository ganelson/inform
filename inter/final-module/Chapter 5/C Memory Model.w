[CMemoryModel::] C Memory Model.

How arrays of all kinds are stored in C.

@h Setting up the model.
The Inter semantics require that there be an area of byte-accessible memory:

(a) Byte-accessible memory must contain all of the arrays. These can but need
not have alignment gaps in between them. (For C, they do not.)
(b) "Addresses" in this memory identify individual byte positions in it. These
can but need not start at 0. (For C, they do.) They must not be too large to
fit into an Inter value.
(c) When an array name is compiled, its runtime value must be its address.
(d) When an Inter value is stored in byte-accessible memory, it occupies either
2 or 4 consecutive bytes, with the little end first. The result is called a
"word". (For C, always 4, which is always |sizeof(i7word_t)|.) Conversion between
a word stored in memory and an Inter value must be faithful in both directions.
(e) Words can be stored at any byte position, and not only at (say) multiples
of 2 or 4.
(f) Arrays in memory are free to contain a mixture of bytes and words: some do.
(g) Data may be written in byte form and read back in word form, or vice versa.

=
void CMemoryModel::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, WORD_TO_BYTE_MTID, CMemoryModel::word_to_byte);
	METHOD_ADD(gtr, BEGIN_ARRAY_MTID, CMemoryModel::begin_array);
	METHOD_ADD(gtr, ARRAY_ENTRY_MTID, CMemoryModel::array_entry);
	METHOD_ADD(gtr, END_ARRAY_MTID, CMemoryModel::end_array);
}

typedef struct C_generation_memory_model_data {
	int himem;                      /* 1 more than the largest legal byte address */
	struct text_stream *array_name; /* of the array currently being compiled */
	int entry_count;                /* within the array currently being compiled */
} C_generation_memory_model_data;

void CMemoryModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(memdata.himem) = 0;
	C_GEN_DATA(memdata.array_name) = Str::new();
	C_GEN_DATA(memdata.entry_count) = 0;
}

@ For a given process |proc|, the current contents of byte-addressable memory will
be an array called |proc->state.memory|; here, we will compile a single static array
|i7_initial_memory| holding the initial contents of this memory, so that a new
process can be initialised from that.

The first 64 bytes of memory are reserved for the "header". We don't write those
here, and instead blank them out to all 0s.

=
void CMemoryModel::begin(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_memory_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7byte_t i7_initial_memory[] = {\n");
	for (int i=0; i<64; i++) WRITE("0, "); WRITE("/* header */\n");
	C_GEN_DATA(memdata.himem) += 64;
	CodeGen::deselect(gen, saved);
}

@ And we must close that array declaration, too:

=
void CMemoryModel::end(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_memory_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("};\n");
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#define i7_static_himem %d\n", C_GEN_DATA(memdata.himem));
	CodeGen::deselect(gen, saved);
}

@ What goes into memory are arrays: memory is allocated only in the form of
such arrays, which are declared one at a time. See //Vanilla Constants//.


=
int CMemoryModel::begin_array(code_generator *gtr, code_generation *gen,
	text_stream *array_name, inter_symbol *array_s, inter_tree_node *P, int format,
	int zero_count, segmentation_pos *saved) {
	Str::clear(C_GEN_DATA(memdata.array_name));
	WRITE_TO(C_GEN_DATA(memdata.array_name), "%S", array_name);
	C_GEN_DATA(memdata.entry_count) = 0;
	if (ConstantInstruction::list_format(P) == CONST_LIST_FORMAT_GRAMMAR)
		@<Short-circuit the usual Vanilla algorithm by compiling the whole array now@>
	else
		@<Declare this array in concert with the usual Vanilla algorithm@>;
}

@ Command-grammar arrays are handled differently: note the return value |FALSE|,
which tells Vanilla not to call us again about this array.

@<Short-circuit the usual Vanilla algorithm by compiling the whole array now@> =
	if (saved) *saved = CodeGen::select(gen, c_verb_arrays_I7CGS);
	VanillaIF::verb_grammar(gtr, gen, array_s, P);
	return FALSE;

@<Declare this array in concert with the usual Vanilla algorithm@> =
	if (saved) *saved = CodeGen::select(gen, c_arrays_I7CGS);
	text_stream *format_name = I"unknown";
	@<Work out the format name@>;
	@<Define a constant for the byte address in memory where the array begins@>;
	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT))
		@<Place the extent entry N at index 0@>;
	for (int i=0; i<zero_count; i++) CMemoryModel::array_entry(gtr, gen, I"0", format);
	return TRUE;

@<Work out the format name@> =
	switch (format) {
		case BYTE_ARRAY_FORMAT: format_name = I"byte"; break;
		case WORD_ARRAY_FORMAT: format_name = I"word"; break;
		case BUFFER_ARRAY_FORMAT: format_name = I"buffer"; break;
		case TABLE_ARRAY_FORMAT: format_name = I"table"; break;
	}

@ Crucially, the array names are |#define| constants declared up near the top
of the source code: they are not variables with pointer types, or something
like that. This means they can legally be used as values elsewhere in memory,
or as initial values of variables, and so on.

Object, class and function names can also legally appear as array entries,
because they too are defined constants, equal to their IDs: see //C Object Model//.

@<Define a constant for the byte address in memory where the array begins@> =
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(gtr, OUT, array_name);
	WRITE(" %d /* = position in memory of %S array %S */\n",
		C_GEN_DATA(memdata.himem), format_name, array_name);
	if (array_s)
		SymbolAnnotation::set_i(array_s, C_ARRAY_ADDRESS_IANN,
			(inter_ti) C_GEN_DATA(memdata.himem));
	CodeGen::deselect(gen, saved);

@ Of course, right now we don't know |N|, the extent of the array. So we will
refer to this with a constant like |i7_mgl_myarray__xt| (XT meaning "extent"),
which we will retrospectively predefine when the array ends.

@<Place the extent entry N at index 0@> =
	TEMPORARY_TEXT(extname)
	CNamespace::mangle(gtr, extname, array_name);
	WRITE_TO(extname, "__xt");
	CMemoryModel::array_entry(gtr, gen, extname, format);
	DISCARD_TEXT(extname)

@ The call to //CMemoryModel::begin_array// is then followed by a series of calls to:

=
void CMemoryModel::array_entry(code_generator *gtr, code_generation *gen,
	text_stream *entry, int format) {
	segmentation_pos saved = CodeGen::select(gen, c_memory_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == WORD_ARRAY_FORMAT))
		@<This is a word entry@>
	else
		@<This is a byte entry@>;
	CodeGen::deselect(gen, saved);
	C_GEN_DATA(memdata.entry_count)++;
}

@<This is a byte entry@> =
	WRITE("    (i7byte_t) %S, /* %d */\n", entry, C_GEN_DATA(memdata.himem));
	C_GEN_DATA(memdata.himem) += 1;

@ Note that |I7BYTE_0| and so on are macros and not functions (see below): they
use only arithmetic operations which can be constant-folded by the C compiler,
and therefore if |X| is a valid constant-context expression in C then so is
|I7BYTE_0(X)|.

@<This is a word entry@> =
	WRITE("    I7BYTE_0(%S), I7BYTE_1(%S), I7BYTE_2(%S), I7BYTE_3(%S), /* %d */\n",
		entry, entry, entry, entry, C_GEN_DATA(memdata.himem));
	C_GEN_DATA(memdata.himem) += 4;

@ When all the entries have been placed, the following is called. It does nothing
except to predeclare the extent constant.

=
void CMemoryModel::end_array(code_generator *gtr, code_generation *gen, int format,
	int zero_count, segmentation_pos *saved) {
	segmentation_pos x_saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(gtr, OUT, C_GEN_DATA(memdata.array_name));
	WRITE("__xt %d\n", C_GEN_DATA(memdata.entry_count)-1);
	CodeGen::deselect(gen, x_saved);
	if (saved) CodeGen::deselect(gen, *saved);
}

@ The primitives for byte and word lookup have the signatures:

= (text)
primitive !lookup val val -> val
primitive !lookupbyte val val -> val
=

=
int CMemoryModel::handle_store_by_ref(code_generation *gen, inter_tree_node *ref) {
	if (ReferenceInstruction::node_is_ref_to(gen->from, ref, LOOKUP_BIP)) return TRUE;
	if (ReferenceInstruction::node_is_ref_to(gen->from, ref, LOOKUPBYTE_BIP)) return TRUE;
	return FALSE;
}

int CMemoryModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case LOOKUP_BIP:
			WRITE("i7_read_word(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
			break;
		case LOOKUPBYTE_BIP:
			WRITE("i7_read_byte(proc, "); VNODE_1C; WRITE(" + "); VNODE_2C; WRITE(")");
			break;
		default:
			return NOT_APPLICABLE;
	}
	return FALSE;
}

@ So, then, time to write some more of the C library. We are going to need to
define the macros |I7BYTE_0| to |I7BYTE_3|, and also the functions |i7_read_word|
and |i7_read_byte|, used just above. But we start with the function which resets
memory to its initial state when a process begins, and with the stack empty.

Note that we fill in ten bytes of the 64-byte header block of memory:

(*) The Release number as a big-endian 16-bit value at |0x34-0x35|;
(*) The Serial code as six ASCII characters (in practice digits) at |0x36-0x3B|.

We carefully defined those two constants, if they exist, before the inclusion point of
the C library in order that the conditional compilations in |i7_initialise_memory_and_stack|
will work correctly. See //CNamespace::declare_constant//.

The rest of the header area remains all zeros.

= (text to inform7_clib.h)
void *i7_calloc(i7process_t *proc, size_t how_many, size_t of_size);
void i7_initialise_memory_and_stack(i7process_t *proc);
=

= (text to inform7_clib.c)
void *i7_calloc(i7process_t *proc, size_t how_many, size_t of_size) {
	void *p = calloc(how_many, of_size);
	if (p == NULL) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	return p;
}

i7byte_t i7_initial_memory[];
void i7_initialise_memory_and_stack(i7process_t *proc) {
	if (proc->state.memory != NULL) free(proc->state.memory);

	i7byte_t *mem = i7_calloc(proc, i7_static_himem, sizeof(i7byte_t));
	for (int i=0; i<i7_static_himem; i++) mem[i] = i7_initial_memory[i];
    #ifdef i7_mgl_Release
    mem[0x34] = I7BYTE_2(i7_mgl_Release); mem[0x35] = I7BYTE_3(i7_mgl_Release);
    #endif
    #ifndef i7_mgl_Release
    mem[0x34] = I7BYTE_2(1); mem[0x35] = I7BYTE_3(1);
    #endif
    #ifdef i7_mgl_Serial
    char *p = i7_text_to_C_string(i7_mgl_Serial);
    for (int i=0; i<6; i++) mem[0x36 + i] = p[i];
    #endif
    #ifndef i7_mgl_Serial
    for (int i=0; i<6; i++) mem[0x36 + i] = '0';
    #endif

 	proc->state.memory = mem;
	proc->state.himem = i7_static_himem;
	proc->state.stack_pointer = 0;
}
=

@ The array |proc->state.memory| is of |i7byte_t| values, so it's easy to read
and write bytes. Words are more challenging since we need to pack and unpack them.

The |i7_read_word| function reads a word which is in word entry |array_index| (counting
0, 1, 2, ...) in the array which begins at the byte address |array_address|.

We can also read "short words", that is, 16-bit values.

= (text to inform7_clib.h)
i7byte_t i7_read_byte(i7process_t *proc, i7word_t address);
i7word_t i7_read_sword(i7process_t *proc, i7word_t array_address, i7word_t array_index);
i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index);
=

= (text to inform7_clib.c)
i7byte_t i7_read_byte(i7process_t *proc, i7word_t address) {
	return proc->state.memory[address];
}

i7word_t i7_read_sword(i7process_t *proc, i7word_t array_address, i7word_t array_index) {
	i7byte_t *data = proc->state.memory;
	int byte_position = array_address + 2*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	return             (i7word_t) data[byte_position + 1]  +
	            0x100U*((i7word_t) data[byte_position + 0]);
}

i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index) {
	i7byte_t *data = proc->state.memory;
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	return             (i7word_t) data[byte_position + 3]  +
	            0x100U*((i7word_t) data[byte_position + 2]) +
		      0x10000U*((i7word_t) data[byte_position + 1]) +
		    0x1000000U*((i7word_t) data[byte_position + 0]);
}
=

@ Writing values is again easy for bytes, but harder for words since they must
be broken up into bytes written in sequence.

Note that we make use of macros and not functions so that it is possible to
express the fragments of a packed word in constant context: this is essential
for our array initialisations.

Note that short words do not need to be written.

= (text to inform7_clib.h)
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

void i7_write_byte(i7process_t *proc, i7word_t address, i7byte_t new_val);
void i7_write_word(i7process_t *proc, i7word_t address, i7word_t array_index,
	i7word_t new_val);
=

= (text to inform7_clib.c)
void i7_write_byte(i7process_t *proc, i7word_t address, i7byte_t new_val) {
	proc->state.memory[address] = new_val;
}

void i7_write_word(i7process_t *proc, i7word_t address, i7word_t array_index,
	i7word_t new_val) {
	int byte_position = address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	proc->state.memory[byte_position]   = I7BYTE_0(new_val);
	proc->state.memory[byte_position+1] = I7BYTE_1(new_val);
	proc->state.memory[byte_position+2] = I7BYTE_2(new_val);
	proc->state.memory[byte_position+3] = I7BYTE_3(new_val);
}
=

@ =
void CMemoryModel::word_to_byte(code_generator *gtr, code_generation *gen,
	OUTPUT_STREAM, text_stream *val, int b) {
	WRITE("I7BYTE_%d(%S)", b, val);
}

@ The seven primitive operations on storage need to be implemented for byte
and word lookups by the following pair of functions. Note that if |way| is
|i7_lvalue_SET| then |i7_change_byte| is equivalent to |i7_write_byte| and
|i7_change_word| to |i7_write_word|, except that they return the value as set.

= (text to inform7_clib.h)
i7byte_t i7_change_byte(i7process_t *proc, i7word_t address, i7byte_t new_val, int way);
i7word_t i7_change_word(i7process_t *proc, i7word_t array_address, i7word_t array_index,
	i7word_t new_val, int way);
=

= (text to inform7_clib.c)
i7byte_t i7_change_byte(i7process_t *proc, i7word_t address, i7byte_t new_val, int way) {
	i7byte_t old_val = i7_read_byte(proc, address);
	i7byte_t return_val = new_val;
	switch (way) {
		case i7_lvalue_PREDEC:   return_val = old_val-1;   new_val = old_val-1; break;
		case i7_lvalue_POSTDEC:  return_val = old_val; new_val = old_val-1; break;
		case i7_lvalue_PREINC:   return_val = old_val+1;   new_val = old_val+1; break;
		case i7_lvalue_POSTINC:  return_val = old_val; new_val = old_val+1; break;
		case i7_lvalue_SETBIT:   new_val = old_val | new_val; return_val = new_val; break;
		case i7_lvalue_CLEARBIT: new_val = old_val &(~new_val); return_val = new_val; break;
	}
	i7_write_byte(proc, address, new_val);
	return return_val;
}

i7word_t i7_change_word(i7process_t *proc, i7word_t array_address, i7word_t array_index,
	i7word_t new_val, int way) {
	i7byte_t *data = proc->state.memory;
	i7word_t old_val = i7_read_word(proc, array_address, array_index);
	i7word_t return_val = new_val;
	switch (way) {
		case i7_lvalue_PREDEC:   return_val = old_val-1;   new_val = old_val-1; break;
		case i7_lvalue_POSTDEC:  return_val = old_val; new_val = old_val-1; break;
		case i7_lvalue_PREINC:   return_val = old_val+1;   new_val = old_val+1; break;
		case i7_lvalue_POSTINC:  return_val = old_val; new_val = old_val+1; break;
		case i7_lvalue_SETBIT:   new_val = old_val | new_val; return_val = new_val; break;
		case i7_lvalue_CLEARBIT: new_val = old_val &(~new_val); return_val = new_val; break;
	}
	i7_write_word(proc, array_address, array_index, new_val);
	return return_val;
}
=

@ The stack is very simple; it can be pushed or pulled, but there's otherwise
no access to it.

= (text to inform7_clib.h)
void i7_debug_stack(char *N);
i7word_t i7_pull(i7process_t *proc);
void i7_push(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
void i7_debug_stack(char *N) {
	#ifdef I7_LOG_STACK_STATE
	printf("Called %s: stack %d ", N, proc->state.stack_pointer);
	for (int i=0; i<proc->state.stack_pointer; i++)
		printf("%d -> ", proc->state.stack[i]);
	printf("\n");
	#endif
}

i7word_t i7_pull(i7process_t *proc) {
	if (proc->state.stack_pointer <= 0) {
		printf("Stack underflow\n");
		i7_fatal_exit(proc);
	}
	return proc->state.stack[--(proc->state.stack_pointer)];
}

void i7_push(i7process_t *proc, i7word_t x) {
	if (proc->state.stack_pointer >= I7_ASM_STACK_CAPACITY) {
		printf("Stack overflow\n");
		i7_fatal_exit(proc);
	}
	proc->state.stack[proc->state.stack_pointer++] = x;
}
=

@ When processes are running, they take periodic "snapshots" of their states
so that these can if necessary be returned to. (For IF works, this is how the
UNDO command works; snapshots are taken once each turn.)

Taking a snapshot, or restoring the state from an existing snapshot, inevitably
means making a copy of state data. This has to be a deep copy, because the
|i7state_t| structure is really just a collection of pointers to arrays in
memory; copying only the pointers would not be good enough.

For the same reason, an |i7state_t| cannot simply be discarded without causing
a memory leak, so we provide a destructor function.

= (text to inform7_clib.h)
void i7_copy_state(i7process_t *proc, i7state_t *to, i7state_t *from);
void i7_destroy_state(i7process_t *proc, i7state_t *s);
=

= (text to inform7_clib.c)
void i7_copy_state(i7process_t *proc, i7state_t *to, i7state_t *from) {
	to->himem = from->himem;
	to->memory = i7_calloc(proc, i7_static_himem, sizeof(i7byte_t));
	for (int i=0; i<i7_static_himem; i++) to->memory[i] = from->memory[i];
	for (int i=0; i<I7_TMP_STORAGE_CAPACITY; i++) to->tmp[i] = from->tmp[i];
	to->stack_pointer = from->stack_pointer;
	for (int i=0; i<from->stack_pointer; i++) to->stack[i] = from->stack[i];
	to->object_tree_parent  = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	to->object_tree_child   = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	to->object_tree_sibling = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));

	for (int i=0; i<i7_max_objects; i++) {
		to->object_tree_parent[i] = from->object_tree_parent[i];
		to->object_tree_child[i] = from->object_tree_child[i];
		to->object_tree_sibling[i] = from->object_tree_sibling[i];
	}
	to->variables = i7_calloc(proc, i7_no_variables, sizeof(i7word_t));
	for (int i=0; i<i7_no_variables; i++) to->variables[i] = from->variables[i];
	to->current_output_stream_ID = from->current_output_stream_ID;
}

void i7_destroy_state(i7process_t *proc, i7state_t *s) {
	free(s->memory);
	s->himem = 0;
	s->stack_pointer = 0;
	free(s->object_tree_parent);
	free(s->object_tree_child);
	free(s->object_tree_sibling);
	free(s->variables);
}
=

@ Destroying a snapshot is then a simple matter of destroying the state
stored inside it:

= (text to inform7_clib.h)
void i7_destroy_snapshot(i7process_t *proc, i7snapshot_t *unwanted);
void i7_destroy_latest_snapshot(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_destroy_snapshot(i7process_t *proc, i7snapshot_t *unwanted) {
	i7_destroy_state(proc, &(unwanted->then));
	unwanted->valid = 0;
}

void i7_destroy_latest_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid)
		i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	proc->snapshot_pos = will_be;
}
=

@ To take a snapshot, we copy the process's current state in the next free
slot in the ring buffer of snapshots held by the process; the net effect is
that it stores the most recent |I7_MAX_SNAPSHOTS| snapshots, silently discarding
any older ones, but without leaking memory.

= (text to inform7_clib.h)
void i7_save_snapshot(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_save_snapshot(i7process_t *proc) {
	if (proc->snapshots[proc->snapshot_pos].valid)
		i7_destroy_snapshot(proc, &(proc->snapshots[proc->snapshot_pos]));
	proc->snapshots[proc->snapshot_pos] = i7_new_snapshot();
	proc->snapshots[proc->snapshot_pos].valid = 1;
	i7_copy_state(proc, &(proc->snapshots[proc->snapshot_pos].then), &(proc->state));
	int was = proc->snapshot_pos;
	proc->snapshot_pos++;
	if (proc->snapshot_pos == I7_MAX_SNAPSHOTS) proc->snapshot_pos = 0;
}
=

@ The function |i7_has_snapshot| tests whether the process has at least one
valid snapshot to revert to:

= (text to inform7_clib.h)
int i7_has_snapshot(i7process_t *proc);
void i7_restore_snapshot(i7process_t *proc);
void i7_restore_snapshot_from(i7process_t *proc, i7snapshot_t *ss);
=

= (text to inform7_clib.c)
int i7_has_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	return proc->snapshots[will_be].valid;
}
=

And |i7_restore_snapshot| restores the state of the process to that of the
most recent snapshot, winding backwards through the ring buffer, so that it's
then possible to restore again to go back another step, and so on:

= (text to inform7_clib.c)
void i7_restore_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid == 0) {
		printf("Restore impossible\n");
		i7_fatal_exit(proc);
	}
	i7_destroy_state(proc, &(proc->state));
	i7_copy_state(proc, &(proc->state), &(proc->snapshots[will_be].then));
	i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	int was = proc->snapshot_pos;
	proc->snapshot_pos = will_be;
}
=
