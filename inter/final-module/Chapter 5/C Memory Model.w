[CMemoryModel::] C Memory Model.

How arrays of all kinds are stored in C.

@h Setting up the model.

=
void CMemoryModel::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, BEGIN_ARRAY_MTID, CMemoryModel::begin_array);
	METHOD_ADD(cgt, ARRAY_ENTRY_MTID, CMemoryModel::array_entry);
	METHOD_ADD(cgt, COMPILE_LITERAL_SYMBOL_MTID, CMemoryModel::compile_literal_symbol);
	METHOD_ADD(cgt, ARRAY_ENTRIES_MTID, CMemoryModel::array_entries);
	METHOD_ADD(cgt, END_ARRAY_MTID, CMemoryModel::end_array);
}

typedef struct C_generation_memory_model_data {
	int himem; /* high point of memory: 1 more than the largest legal address */
	struct text_stream *array_name;
	int entry_count;
} C_generation_memory_model_data;

void CMemoryModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(memdata.himem) = 0;
	C_GEN_DATA(memdata.array_name) = Str::new();
	C_GEN_DATA(memdata.entry_count) = 0;
}

@h Byte-addressable memory.
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

We will manage that with a single C array.

@ Declaring that array is our main task in this section.

=
void CMemoryModel::begin(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7byte_t i7_initial_memory[] = {\n");
	for (int i=0; i<64; i++) WRITE("0, "); WRITE("/* header */\n");
	C_GEN_DATA(memdata.himem) += 64;
	CodeGen::deselect(gen, saved);
}

@ We will end the array with two dummy bytes (which should never be accessed)
just in case, and to ensure that it is never empty, which would be illegal
in C.

=
void CMemoryModel::end(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("0, 0 };\n");
	
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("#define i7_static_himem %d\n", C_GEN_DATA(memdata.himem));
	CodeGen::deselect(gen, saved);
}

@

= (text to inform7_clib.h)
void i7_initialise_state(i7process_t *proc);
=

= (text to inform7_clib.c)
i7byte_t i7_initial_memory[];
void i7_initialise_state(i7process_t *proc) {
	if (proc->state.memory != NULL) free(proc->state.memory);
	i7byte_t *mem = calloc(i7_static_himem, sizeof(i7byte_t));
	if (mem == NULL) { 
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	proc->state.memory = mem;
	proc->state.himem = i7_static_himem;
	for (int i=0; i<i7_static_himem; i++) mem[i] = i7_initial_memory[i];
    #ifdef i7_mgl_Release
    mem[0x34] = I7BYTE_2(i7_mgl_Release);
    mem[0x35] = I7BYTE_3(i7_mgl_Release);
    #endif
    #ifndef i7_mgl_Release
    mem[0x34] = I7BYTE_2(1);
    mem[0x35] = I7BYTE_3(1);
    #endif
    #ifdef i7_mgl_Serial
    char *p = i7_text_of_string(i7_mgl_Serial);
    for (int i=0; i<6; i++) mem[0x36 + i] = p[i];
    #endif
    #ifndef i7_mgl_Serial
    for (int i=0; i<6; i++) mem[0x36 + i] = '0';
    #endif
    proc->state.stack_pointer = 0;
    
	proc->state.object_tree_parent  = calloc(i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_child   = calloc(i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_sibling = calloc(i7_max_objects, sizeof(i7word_t));
	
	if ((proc->state.object_tree_parent == NULL) ||
		(proc->state.object_tree_child == NULL) ||
		(proc->state.object_tree_sibling == NULL)) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_max_objects; i++) {
		proc->state.object_tree_parent[i] = 0;
		proc->state.object_tree_child[i] = 0;
		proc->state.object_tree_sibling[i] = 0;
	}
	
	proc->state.variables = calloc(i7_no_variables, sizeof(i7word_t));
	if (proc->state.variables == NULL) { 
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_no_variables; i++)
		proc->state.variables[i] = i7_initial_variable_values[i];
}
=

@ And now some deep copy functions. The above structures are full of pointers
to arrays, so a simple copy will only duplicate those pointers, not the data
in the arrays they point to. Similarly, we can't just throw away an |i7state_t|
value without causing a memory leak, so we need explicit destructors.

= (text to inform7_clib.h)
void i7_copy_state(i7process_t *proc, i7state_t *to, i7state_t *from);
void i7_destroy_state(i7process_t *proc, i7state_t *s);
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

void i7_copy_state(i7process_t *proc, i7state_t *to, i7state_t *from) {
	to->himem = from->himem;
	to->memory = i7_calloc(proc, i7_static_himem, sizeof(i7byte_t));
	for (int i=0; i<i7_static_himem; i++) to->memory[i] = from->memory[i];
	to->tmp = from->tmp;
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

= (text to inform7_clib.h)
void i7_destroy_snapshot(i7process_t *proc, i7snapshot_t *old);
void i7_save_snapshot(i7process_t *proc);
int i7_has_snapshot(i7process_t *proc);
void i7_restore_snapshot(i7process_t *proc);
void i7_restore_snapshot_from(i7process_t *proc, i7snapshot_t *ss);
void i7_destroy_latest_snapshot(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_destroy_snapshot(i7process_t *proc, i7snapshot_t *old) {
	i7_destroy_state(proc, &(old->then));
	old->valid = 0;
}

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

int i7_has_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	return proc->snapshots[will_be].valid;
}

void i7_destroy_latest_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid)
		i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	proc->snapshot_pos = will_be;
}

void i7_restore_snapshot(i7process_t *proc) {
	int will_be = proc->snapshot_pos - 1;
	if (will_be < 0) will_be = I7_MAX_SNAPSHOTS - 1;
	if (proc->snapshots[will_be].valid == 0) {
		printf("Restore impossible\n");
		i7_fatal_exit(proc);
	}
	i7_restore_snapshot_from(proc, &(proc->snapshots[will_be]));
	i7_destroy_snapshot(proc, &(proc->snapshots[will_be]));
	int was = proc->snapshot_pos;
	proc->snapshot_pos = will_be;
}

void i7_restore_snapshot_from(i7process_t *proc, i7snapshot_t *ss) {
	i7_destroy_state(proc, &(proc->state));
	i7_copy_state(proc, &(proc->state), &(ss->then));
}
=

@h Reading and writing memory.
Given the above array, it's easy to read and write bytes. Words are more
challenging since we need to pack and unpack them.

The following function reads a word which is in entry |array_index| (counting
0, 1, 2, ...) in the array which begins at the byte address |array_address|.

= (text to inform7_clib.h)
i7byte_t i7_read_byte(i7process_t *proc, i7word_t address);
i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index);
=

= (text to inform7_clib.c)
i7byte_t i7_read_byte(i7process_t *proc, i7word_t address) {
	return proc->state.memory[address];
}

i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index) {
	i7byte_t *data = proc->state.memory;
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	return             (i7word_t) data[byte_position + 3]      +
	            0x100*((i7word_t) data[byte_position + 2]) +
		      0x10000*((i7word_t) data[byte_position + 1]) +
		    0x1000000*((i7word_t) data[byte_position + 0]);
}
=

@ Packing, unlike unpacking, is done with macros so that it is possible to
express a packed word in constant context, which we will need later.

= (text to inform7_clib.h)
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

void i7_write_byte(i7process_t *proc, i7word_t address, i7byte_t new_val);
i7word_t i7_write_word(i7process_t *proc, i7word_t array_address, i7word_t array_index, i7word_t new_val, int way);
=

= (text to inform7_clib.c)
void i7_write_byte(i7process_t *proc, i7word_t address, i7byte_t new_val) {
	proc->state.memory[address] = new_val;
}

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

i7word_t i7_write_word(i7process_t *proc, i7word_t array_address, i7word_t array_index, i7word_t new_val, int way) {
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
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	data[byte_position]   = I7BYTE_0(new_val);
	data[byte_position+1] = I7BYTE_1(new_val);
	data[byte_position+2] = I7BYTE_2(new_val);
	data[byte_position+3] = I7BYTE_3(new_val);
	return return_val;
}
=

@ "Short" 16-bit numbers can also be accessed:

= (text to inform7_clib.h)
void glulx_aloads(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
=

= (text to inform7_clib.c)
void glulx_aloads(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = 0x100*((i7word_t) i7_read_byte(proc, x+2*y)) + ((i7word_t) i7_read_byte(proc, x+2*y+1));
}
=

@ A Glulx assembly opcode is provided for fast memory copies:

= (text to inform7_clib.h)
void glulx_mcopy(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
void glulx_malloc(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_mfree(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
void glulx_mcopy(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
    if (z < y)
		for (i7word_t i=0; i<x; i++)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
    else
		for (i7word_t i=x-1; i>=0; i--)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
}

void glulx_malloc(i7process_t *proc, i7word_t x, i7word_t y) {
	printf("Unimplemented: glulx_malloc.\n");
	i7_fatal_exit(proc);
}

void glulx_mfree(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: glulx_mfree.\n");
	i7_fatal_exit(proc);
}
=

@h Populating memory with arrays.

=
int CMemoryModel::begin_array(code_generator *cgt, code_generation *gen,
	text_stream *array_name, inter_symbol *array_s, inter_tree_node *P, int format, segmentation_pos *saved) {
	if (saved) {
		int choice = c_arrays_at_eof_I7CGS;
		if ((array_s) && (Inter::Symbols::read_annotation(array_s, VERBARRAY_IANN) == 1))
			choice = c_verbs_at_eof_I7CGS;
		*saved = CodeGen::select(gen, choice);
	}
	Str::clear(C_GEN_DATA(memdata.array_name));
	WRITE_TO(C_GEN_DATA(memdata.array_name), "%S", array_name);
	C_GEN_DATA(memdata.entry_count) = 0;

	if ((array_s) && (Inter::Symbols::read_annotation(array_s, VERBARRAY_IANN) == 1)) {
		CLiteralsModel::verb_grammar(cgt, gen, array_s, P);
		return FALSE;
	}

	text_stream *format_name = I"unknown";
	@<Work out the format name@>;
	@<Define a constant for the byte address in memory where the array begins@>;
	if ((format == TABLE_ARRAY_FORMAT) || (format == BUFFER_ARRAY_FORMAT))
		@<Place the extent entry N at index 0@>;
	return TRUE;
}

@<Work out the format name@> =
	switch (format) {
		case BYTE_ARRAY_FORMAT: format_name = I"byte"; break;
		case WORD_ARRAY_FORMAT: format_name = I"word"; break;
		case BUFFER_ARRAY_FORMAT: format_name = I"buffer"; break;
		case TABLE_ARRAY_FORMAT: format_name = I"table"; break;
	}

@ Crucially, the array names are |#define| constants declared up at the top
of the source code: they are not variables with pointer types, or something
like that. This means they can legally be used as values elsewhere in memory,
or as initial values of variables, and so on.

Object, class and function names can also legally appear as array entries,
because they too are defined constants, equal to their IDs: see //C Object Model//.

@<Define a constant for the byte address in memory where the array begins@> =
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(cgt, OUT, array_name);
	WRITE(" %d /* = position in memory of %S array %S */\n",
		C_GEN_DATA(memdata.himem), format_name, array_name);
	if (array_s)
		Inter::Symbols::annotate_i(array_s, C_ARRAY_ADDRESS_IANN, (inter_ti) C_GEN_DATA(memdata.himem));
	CodeGen::deselect(gen, saved);

@ Of course, right now we don't know |N|, the extent of the array. So we will
refer to this with a constant like |xt_myarray|, which we will retrospectively
predefine when the array ends.

@<Place the extent entry N at index 0@> =
	TEMPORARY_TEXT(extname)
	WRITE_TO(extname, "xt_");
	CNamespace::mangle(cgt, extname, array_name);
	CMemoryModel::array_entry(cgt, gen, extname, format);
	DISCARD_TEXT(extname)

@ The call to |CMemoryModel::begin_array| is then followed by a series of calls to:

=
void CMemoryModel::array_entry(code_generator *cgt, code_generation *gen,
	text_stream *entry, int format) {
	segmentation_pos saved = CodeGen::select(gen, c_mem_I7CGS);
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

@ Now we see why it was important for |I7BYTE_0| and so on to be macros: they
use only arithmetic operations which can be constant-folded by the C compiler,
and therefore if |X| is a valid constant-context expression in C then so is
|I7BYTE_0(X)|.

@<This is a word entry@> =
	WRITE("    I7BYTE_0(%S), I7BYTE_1(%S), I7BYTE_2(%S), I7BYTE_3(%S), /* %d */\n",
		entry, entry, entry, entry, C_GEN_DATA(memdata.himem));
	C_GEN_DATA(memdata.himem) += 4;

@

=
void CMemoryModel::compile_literal_symbol(code_generator *cgt, code_generation *gen, inter_symbol *aliased) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *S = Inter::Symbols::name(aliased);
	Generators::mangle(gen, OUT, S);
}

@ Alternatively, we can just specify how many entries there will be: they will
then be initialised to 0.

=
void CMemoryModel::array_entries(code_generator *cgt, code_generation *gen,
	int how_many, int format) {
	for (int i=0; i<how_many; i++) CMemoryModel::array_entry(cgt, gen, I"0", format);
}

@ When all the entries have been placed, the following is called. It does nothing
except to predeclare the extent constant, if one was used.

=
void CMemoryModel::end_array(code_generator *cgt, code_generation *gen, int format, segmentation_pos *saved) {
	segmentation_pos x_saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define xt_");
	CNamespace::mangle(cgt, OUT, C_GEN_DATA(memdata.array_name));
	WRITE(" %d\n", C_GEN_DATA(memdata.entry_count)-1);
	CodeGen::deselect(gen, x_saved);
	if (saved) CodeGen::deselect(gen, *saved);
}

@h Primitives for byte and word lookup.
The signatures here are:

= (text)
primitive !lookup val val -> val
primitive !lookupbyte val val -> val
=

=
int CMemoryModel::handle_store_by_ref(code_generation *gen, inter_tree_node *ref) {
	if (Inter::Reference::node_is_ref_to(gen->from, ref, LOOKUP_BIP)) return TRUE;
	if (Inter::Reference::node_is_ref_to(gen->from, ref, LOOKUPBYTE_BIP)) return TRUE;
	return FALSE;
}

int CMemoryModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case LOOKUP_BIP:     WRITE("i7_read_word(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")");
						     break;
		case LOOKUPBYTE_BIP: WRITE("i7_read_byte(proc, "); VNODE_1C; WRITE(" + "); VNODE_2C; WRITE(")");
							 break;
		default:             return NOT_APPLICABLE;
	}
	return FALSE;
}
