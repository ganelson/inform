[CMemoryModel::] C Memory Model.

How arrays of all kinds are stored in C.

@h Setting up the model.

=
void CMemoryModel::initialise(code_generation_target *cgt) {
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
	int next_node_is_a_ref;
} C_generation_memory_model_data;

void CMemoryModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(memdata.himem) = 0;
	C_GEN_DATA(memdata.array_name) = Str::new();
	C_GEN_DATA(memdata.entry_count) = 0;
	C_GEN_DATA(memdata.next_node_is_a_ref) = FALSE;
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
"word". (For C, always 4, which is always |sizeof(i7val)|.) Conversion between
a word stored in memory and an Inter value must be faithful in both directions.
(e) Words can be stored at any byte position, and not only at (say) multiples
of 2 or 4.
(f) Arrays in memory are free to contain a mixture of bytes and words: some do.
(g) Data may be written in byte form and read back in word form, or vice versa.

We will manage that with a single C array.

@ Declaring that array is our main task in this section.

=
void CMemoryModel::begin(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7byte i7_initial_memory[] = {\n");
	for (int i=0; i<64; i++) WRITE("0, "); WRITE("/* header */\n");
	C_GEN_DATA(memdata.himem) += 64;
	CodeGen::deselect(gen, saved);
}

@ We will end the array with two dummy bytes (which should never be accessed)
just in case, and to ensure that it is never empty, which would be illegal
in C.

=
void CMemoryModel::end(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
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
void i7_initialise_state(i7process *proc);
=

= (text to inform7_clib.c)
i7byte i7_initial_memory[];
void i7_initialise_state(i7process *proc) {
	if (proc->state.memory != NULL) free(proc->state.memory);
	i7byte *mem = calloc(i7_static_himem, sizeof(i7byte));
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
    
	proc->state.i7_object_tree_parent  = calloc(i7_max_objects, sizeof(i7val));
	proc->state.i7_object_tree_child   = calloc(i7_max_objects, sizeof(i7val));
	proc->state.i7_object_tree_sibling = calloc(i7_max_objects, sizeof(i7val));
	
	if ((proc->state.i7_object_tree_parent == NULL) ||
		(proc->state.i7_object_tree_child == NULL) ||
		(proc->state.i7_object_tree_sibling == NULL)) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_max_objects; i++) {
		proc->state.i7_object_tree_parent[i] = 0;
		proc->state.i7_object_tree_child[i] = 0;
		proc->state.i7_object_tree_sibling[i] = 0;
	}
	
	proc->state.variables = calloc(i7_no_variables, sizeof(i7val));
	if (proc->state.variables == NULL) { 
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_no_variables; i++)
		proc->state.variables[i] = i7_initial_variable_values[i];
}
=

@h Reading and writing memory.
Given the above array, it's easy to read and write bytes. Words are more
challenging since we need to pack and unpack them.

The following function reads a word which is in entry |array_index| (counting
0, 1, 2, ...) in the array which begins at the byte address |array_address|.

= (text to inform7_clib.h)
i7byte i7_read_byte(i7process *proc, i7val address);
i7val i7_read_word(i7process *proc, i7val array_address, i7val array_index);
=

= (text to inform7_clib.c)
i7byte i7_read_byte(i7process *proc, i7val address) {
	return proc->state.memory[address];
}

i7val i7_read_word(i7process *proc, i7val array_address, i7val array_index) {
	i7byte *data = proc->state.memory;
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	return             (i7val) data[byte_position + 3]      +
	            0x100*((i7val) data[byte_position + 2]) +
		      0x10000*((i7val) data[byte_position + 1]) +
		    0x1000000*((i7val) data[byte_position + 0]);
}
=

@ Packing, unlike unpacking, is done with macros so that it is possible to
express a packed word in constant context, which we will need later.

= (text to inform7_clib.h)
#define I7BYTE_0(V) ((V & 0xFF000000) >> 24)
#define I7BYTE_1(V) ((V & 0x00FF0000) >> 16)
#define I7BYTE_2(V) ((V & 0x0000FF00) >> 8)
#define I7BYTE_3(V)  (V & 0x000000FF)

void i7_write_byte(i7process *proc, i7val address, i7byte new_val);
i7val i7_write_word(i7process *proc, i7val array_address, i7val array_index, i7val new_val, int way);
=

= (text to inform7_clib.c)
void i7_write_byte(i7process *proc, i7val address, i7byte new_val) {
	proc->state.memory[address] = new_val;
}

i7byte i7_change_byte(i7process *proc, i7val address, i7byte new_val, int way) {
	i7byte old_val = i7_read_byte(proc, address);
	i7byte return_val = new_val;
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

i7val i7_write_word(i7process *proc, i7val array_address, i7val array_index, i7val new_val, int way) {
	i7byte *data = proc->state.memory;
	i7val old_val = i7_read_word(proc, array_address, array_index);
	i7val return_val = new_val;
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
void glulx_aloads(i7process *proc, i7val x, i7val y, i7val *z);
=

= (text to inform7_clib.c)
void glulx_aloads(i7process *proc, i7val x, i7val y, i7val *z) {
	if (z) *z = 0x100*((i7val) i7_read_byte(proc, x+2*y)) + ((i7val) i7_read_byte(proc, x+2*y+1));
}
=

@ A Glulx assembly opcode is provided for fast memory copies:

= (text to inform7_clib.h)
void glulx_mcopy(i7process *proc, i7val x, i7val y, i7val z);
void glulx_malloc(i7process *proc, i7val x, i7val y);
void glulx_mfree(i7process *proc, i7val x);
=

= (text to inform7_clib.c)
void glulx_mcopy(i7process *proc, i7val x, i7val y, i7val z) {
    if (z < y)
		for (i7val i=0; i<x; i++)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
    else
		for (i7val i=x-1; i>=0; i--)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
}

void glulx_malloc(i7process *proc, i7val x, i7val y) {
	printf("Unimplemented: glulx_malloc.\n");
	i7_fatal_exit(proc);
}

void glulx_mfree(i7process *proc, i7val x) {
	printf("Unimplemented: glulx_mfree.\n");
	i7_fatal_exit(proc);
}
=

@h Populating memory with arrays.
Inter supports four sorts of arrays, with behaviour as laid out in this 2x2 grid:
= (text)
			 | entries count 0, 1, 2,...	 | entry 0 is N, then entries count 1, 2, ..., N
-------------+-------------------------------+-----------------------------------------------
byte entries | BYTE_ARRAY_FORMAT             | BUFFER_ARRAY_FORMAT
-------------+-------------------------------+-----------------------------------------------
word entries | WORD_ARRAY_FORMAT             | TABLE_ARRAY_FORMAT
-------------+-------------------------------+-----------------------------------------------
=

=
int CMemoryModel::begin_array(code_generation_target *cgt, code_generation *gen,
	text_stream *array_name, inter_symbol *array_s, inter_tree_node *P, int format) {
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
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(cgt, OUT, array_name);
	WRITE(" %d /* = position in memory of %S array %S */\n",
		C_GEN_DATA(memdata.himem), format_name, array_name);
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
void CMemoryModel::array_entry(code_generation_target *cgt, code_generation *gen,
	text_stream *entry, int format) {
	generated_segment *saved = CodeGen::select(gen, c_mem_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	if ((format == TABLE_ARRAY_FORMAT) || (format == WORD_ARRAY_FORMAT))
		@<This is a word entry@>
	else
		@<This is a byte entry@>;
	CodeGen::deselect(gen, saved);
	C_GEN_DATA(memdata.entry_count)++;
}

@<This is a byte entry@> =
	WRITE("    (i7byte) %S, /* %d */\n", entry, C_GEN_DATA(memdata.himem));
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
void CMemoryModel::compile_literal_symbol(code_generation_target *cgt, code_generation *gen, inter_symbol *aliased, int unsub) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *S = CodeGen::CL::name(aliased);
	CodeGen::Targets::mangle(gen, OUT, S);
}

@ Alternatively, we can just specify how many entries there will be: they will
then be initialised to 0.

=
void CMemoryModel::array_entries(code_generation_target *cgt, code_generation *gen,
	int how_many, int plus_ips, int format) {
	if (plus_ips) how_many += 64;
	for (int i=0; i<how_many; i++) CMemoryModel::array_entry(cgt, gen, I"0", format);
}

@ When all the entries have been placed, the following is called. It does nothing
except to predeclare the extent constant, if one was used.

=
void CMemoryModel::end_array(code_generation_target *cgt, code_generation *gen, int format) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define xt_");
	CNamespace::mangle(cgt, OUT, C_GEN_DATA(memdata.array_name));
	WRITE(" %d\n", C_GEN_DATA(memdata.entry_count)-1);
	CodeGen::deselect(gen, saved);
}

@h Primitives for byte and word lookup.
The signatures here are:

= (text)
primitive !lookup val val -> val
primitive !lookupbyte val val -> val
=

=
int CMemoryModel::handle_store_by_ref(code_generation *gen, inter_tree_node *ref) {
	if (CodeGen::CL::node_is_ref_to(gen->from, ref, LOOKUP_BIP)) return TRUE;
	if (CodeGen::CL::node_is_ref_to(gen->from, ref, LOOKUPBYTE_BIP)) return TRUE;
	return FALSE;
}

int CMemoryModel::compile_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case LOOKUP_BIP:     if (CReferences::am_I_a_ref(gen)) @<Word value as reference@>
						     else @<Word value as value@>;
						     break;
		case LOOKUPBYTE_BIP: if (CReferences::am_I_a_ref(gen)) @<Byte value as reference@>
						     else @<Byte value as value@>; break;
		default:             return NOT_APPLICABLE;
	}
	return FALSE;
}

@<Word value as value@> =
	WRITE("i7_read_word(proc, "); INV_A1; WRITE(", "); INV_A2; WRITE(")");

@<Word value as reference@> =
	WRITE("i7_write_word(proc, "); INV_A1; WRITE(", "); INV_A2; WRITE(", ");
	
@<Byte value as value@> =
	WRITE("i7_read_byte(proc, "); INV_A1; WRITE(" + "); INV_A2; WRITE(")");
	
@<Byte value as reference@> =
	WRITE("i7_change_byte(proc, "); INV_A1; WRITE(" + "); INV_A2; WRITE(", ");
