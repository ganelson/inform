/* This is a library of C code to support Inter code compiled to ANSI C. It was
   generated mechanically from the Inter source code, so to change this material,
   edit that and not this file. */

#ifndef I7_CLIB_C_INCLUDED
#define I7_CLIB_C_INCLUDED 1
i7state_t i7_new_state(void) {
	i7state_t S;
	S.memory = NULL;
	S.himem = 0;
	S.stack_pointer = 0;
	S.object_tree_parent = NULL; S.object_tree_child = NULL; S.object_tree_sibling = NULL;
	S.variables = NULL;
	S.seed = i7_initial_rng_seed();
	return S;
}

i7snapshot_t i7_new_snapshot(void) {
	i7snapshot_t SS;
	SS.valid = 0;
	SS.then = i7_new_state();
	return SS;
}

i7process_t i7_new_process(void) {
	i7process_t proc;
	proc.state = i7_new_state();
	for (int i=0; i<I7_MAX_SNAPSHOTS; i++) proc.snapshots[i] = i7_new_snapshot();
	proc.snapshot_pos = 0;
	proc.receiver = i7_default_receiver;
	proc.send_count = 0;
	proc.sender = i7_default_sender;
	proc.stylist = i7_default_stylist;
	proc.glk_implementation = i7_default_glk;
	proc.use_UTF8 = 1;
	i7_initialise_miniglk_data(&proc);
	return proc;
}
void i7_default_receiver(int id, wchar_t c, char *style) {
	if (id == I7_BODY_TEXT_ID) fputc(c, stdout);
}

char i7_default_sender_buffer[256];
char *i7_default_sender(int count) {
	int pos = 0;
	while (1) {
		int c = getchar();
		if ((c == EOF) || (c == '\n') || (c == '\r')) break;
		if (pos < 255) i7_default_sender_buffer[pos++] = c;
	}
	i7_default_sender_buffer[pos++] = 0;
	return i7_default_sender_buffer;
}
int i7_default_main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_run_process(&proc);
	if (proc.termination_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return proc.termination_code;
}
void i7_set_process_receiver(i7process_t *proc,
	void (*receiver)(int id, wchar_t c, char *style), int UTF8) {
	proc->receiver = receiver;
	proc->use_UTF8 = UTF8;
}
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count)) {
	proc->sender = sender;
}
void i7_set_process_stylist(i7process_t *proc,
	void (*stylist)(struct i7process_t *proc, i7word_t which, i7word_t what)) {
	proc->stylist = stylist;
}
void i7_set_process_glk_implementation(i7process_t *proc,
	void (*glk_implementation)(struct i7process_t *proc, i7word_t glk_api_selector,
		i7word_t varargc, i7word_t *z)) {
	proc->glk_implementation = glk_implementation;
}
i7word_t i7_fn_Main(i7process_t *proc);
int i7_run_process(i7process_t *proc) {
	int tc = setjmp(proc->execution_env);
	if (tc) {
		if (tc == 2) proc->termination_code = 0; /* terminated mid-stream but benignly */
		else proc->termination_code = tc; /* terminated mid-stream with a fatal error */
    } else {
		i7_initialise_memory_and_stack(proc);
		i7_initialise_variables(proc);
		i7_empty_object_tree(proc);
		i7_initialiser(proc);
		i7_initialise_object_tree(proc);
		i7_initialise_miniglk(proc);
		i7_fn_Main(proc);
		proc->termination_code = 0; /* terminated because the program completed */
    }
    return proc->termination_code;
}

void i7_fatal_exit(i7process_t *proc) {
//  Uncomment the next line to force a crash so that the stack can be inspected in a debugger
//	int x = 0; printf("%d", 1/x);
	longjmp(proc->execution_env, 1);
}

void i7_benign_exit(i7process_t *proc) {
	longjmp(proc->execution_env, 2);
}
void i7_initialise_variables(i7process_t *proc) {
	proc->state.variables = i7_calloc(proc, i7_no_variables, sizeof(i7word_t));
	for (int i=0; i<i7_no_variables; i++)
		proc->state.variables[i] = i7_initial_variable_values[i];
}
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
	            0x100*((i7word_t) data[byte_position + 0]);
}

i7word_t i7_read_word(i7process_t *proc, i7word_t array_address, i7word_t array_index) {
	i7byte_t *data = proc->state.memory;
	int byte_position = array_address + 4*array_index;
	if ((byte_position < 0) || (byte_position >= i7_static_himem)) {
		printf("Memory access out of range: %d\n", byte_position);
		i7_fatal_exit(proc);
	}
	return             (i7word_t) data[byte_position + 3]  +
	            0x100*((i7word_t) data[byte_position + 2]) +
		      0x10000*((i7word_t) data[byte_position + 1]) +
		    0x1000000*((i7word_t) data[byte_position + 0]);
}
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
void i7_opcode_call(i7process_t *proc, i7word_t fn_ref, i7word_t varargc, i7word_t *z) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	for (int i=0; i<varargc; i++) args[i] = i7_pull(proc);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, varargc);
	if (z) *z = rv;
}
void i7_opcode_copy(i7process_t *proc, i7word_t x, i7word_t *y) {
	if (y) *y = x;
}
void i7_opcode_aload(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = i7_read_word(proc, x, y);
}

void i7_opcode_aloads(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = i7_read_sword(proc, x, y);
}

void i7_opcode_aloadb(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = i7_read_byte(proc, x+y);
}
void i7_opcode_shiftl(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	i7word_t value = 0;
	if ((y >= 0) && (y < 32)) value = (x << y);
	if (z) *z = value;
}

void i7_opcode_ushiftr(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	i7word_t value = 0;
	if ((y >= 0) && (y < 32)) value = (x >> y);
	if (z) *z = value;
}
int i7_opcode_jeq(i7process_t *proc, i7word_t x, i7word_t y) {
	if (x == y) return 1;
	return 0;
}

int i7_opcode_jleu(i7process_t *proc, i7word_t x, i7word_t y) {
	unsigned_i7word_t ux, uy;
	*((i7word_t *) &ux) = x; *((i7word_t *) &uy) = y;
	if (ux <= uy) return 1;
	return 0;
}

int i7_opcode_jnz(i7process_t *proc, i7word_t x) {
	if (x != 0) return 1;
	return 0;
}

int i7_opcode_jz(i7process_t *proc, i7word_t x) {
	if (x == 0) return 1;
	return 0;
}
void i7_opcode_nop(i7process_t *proc) {
}

void i7_opcode_quit(i7process_t *proc) {
	i7_fatal_exit(proc);
}

void i7_opcode_verify(i7process_t *proc, i7word_t *z) {
	if (z) *z = 0;
}
#ifdef i7_mgl_DealWithUndo
i7word_t i7_fn_DealWithUndo(i7process_t *proc);
#endif

void i7_opcode_restoreundo(i7process_t *proc, i7word_t *x) {
	if (i7_has_snapshot(proc)) {
		i7_restore_snapshot(proc);
		if (x) *x = 0;
		#ifdef i7_mgl_DealWithUndo
		i7_fn_DealWithUndo(proc);
		#endif
	} else {
		if (x) *x = 1;
	}
}

void i7_opcode_saveundo(i7process_t *proc, i7word_t *x) {
	i7_save_snapshot(proc);
	if (x) *x = 0;
}

void i7_opcode_hasundo(i7process_t *proc, i7word_t *x) {
	i7word_t rv = 0; if (i7_has_snapshot(proc)) rv = 1;
	if (x) *x = rv;
}

void i7_opcode_discardundo(i7process_t *proc) {
	i7_destroy_latest_snapshot(proc);
}
void i7_opcode_restart(i7process_t *proc) {
	printf("(RESTART is not implemented on this C program.)\n");
}

void i7_opcode_restore(i7process_t *proc, i7word_t x, i7word_t *y) {
	printf("(RESTORE is not implemented on this C program.)\n");
}

void i7_opcode_save(i7process_t *proc, i7word_t x, i7word_t *y) {
	printf("(SAVE is not implemented on this C program.)\n");
}
void i7_opcode_streamnum(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void i7_opcode_streamchar(i7process_t *proc, i7word_t x) {
	i7_print_char(proc, x);
}

void i7_opcode_streamunichar(i7process_t *proc, i7word_t x) {
	i7_print_char(proc, x);
}

void i7_opcode_binarysearch(i7process_t *proc, i7word_t key, i7word_t keysize,
	i7word_t start, i7word_t structsize, i7word_t numstructs, i7word_t keyoffset,
	i7word_t options, i7word_t *s1) {

	if (s1 == NULL) return; /* Do not spend any time if the result is to be ignored */


	/* If the key size is 4 or fewer, copy it directly into the keybuf array */
	unsigned char keybuf[4];
    if (options & serop_KeyIndirect) {
		if (keysize <= 4)
		    for (int ix=0; ix<keysize; ix++)
		        keybuf[ix] = i7_read_byte(proc, key + ix);
	} else {
		switch (keysize) {
    		case 4:
				keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key);
				keybuf[2] = I7BYTE_2(key); keybuf[3] = I7BYTE_3(key); break;
			case 2:
				keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key); break;
    		case 1:
     		    keybuf[0] = key; break;
        }
    }

	i7word_t bot = 0, top = numstructs; /* Initial search range, including bot but not top */
	while (bot < top) { /* I.e., while the search range is not empty */
		/* Find the structure at the midpoint of the search range */
		i7word_t val = (top+bot) / 2;
		i7word_t addr = start + val * structsize;

		/* Compute cmp = 0 if the key matches this, -1 if it precedes, 1 if it follows */
		int cmp = 0;
		if (keysize <= 4) {
			for (int ix=0; (!cmp) && ix<keysize; ix++) {
				unsigned char byte = i7_read_byte(proc, addr + keyoffset + ix);
				unsigned char byte2 = keybuf[ix];
				if (byte < byte2) cmp = -1;
				else if (byte > byte2) cmp = 1;
			}
		} else {
			for (int ix=0; (!cmp) && ix<keysize; ix++) {
				unsigned char byte  = i7_read_byte(proc, addr + keyoffset + ix);
				unsigned char byte2 = i7_read_byte(proc, key + ix);
				if (byte < byte2) cmp = -1;
				else if (byte > byte2) cmp = 1;
			}
		}

		if (cmp == 0) {
			/* Success! */
			if (options & serop_ReturnIndex) *s1 = val; else *s1 = addr;
			return;
		}

		if (cmp < 0) bot = val+1; /* Chop search range to the second half */
		else top = val; /* Chop search range to the first half */
	}

	/* Failure! */
	if (options & serop_ReturnIndex) *s1 = -1; else *s1 = 0;
}
void i7_opcode_mcopy(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
    if (z < y)
		for (i7word_t i=0; i<x; i++)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
    else
		for (i7word_t i=x-1; i>=0; i--)
			i7_write_byte(proc, z+i, i7_read_byte(proc, y+i));
}

void i7_opcode_mzero(i7process_t *proc, i7word_t x, i7word_t y) {
	for (i7word_t i=0; i<x; i++) i7_write_byte(proc, y+i, 0);
}

void i7_opcode_malloc(i7process_t *proc, i7word_t x, i7word_t y) {
	printf("Unimplemented: i7_opcode_malloc.\n");
	i7_fatal_exit(proc);
}

void i7_opcode_mfree(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: i7_opcode_mfree.\n");
	i7_fatal_exit(proc);
}
i7rngseed_t i7_initial_rng_seed(void) {
	i7rngseed_t seed;
	seed.A = 1;
	seed.interval = 0;
	seed.counter = 0;
	return seed;
}

void i7_opcode_random(i7process_t *proc, i7word_t x, i7word_t *y) {
	uint32_t rawvalue = 0;
	if (proc->state.seed.interval != 0) {
	    rawvalue = proc->state.seed.counter++;
	    if (proc->state.seed.counter == proc->state.seed.interval) proc->state.seed.counter = 0;
	} else {
	    proc->state.seed.A = 0x015a4e35L * proc->state.seed.A + 1;
	    rawvalue = (proc->state.seed.A >> 16) & 0x7fff;
	}
	uint32_t value;
	if (x == 0) value = rawvalue;
	else if (x >= 1) value = rawvalue % (uint32_t) (x);
	else value = -(rawvalue % (uint32_t) (-x));
	*y = (i7word_t) value;
}

void i7_opcode_setrandom(i7process_t *proc, i7word_t s) {
    if (s == 0) {
		proc->state.seed.A = (uint32_t) time(NULL);
		proc->state.seed.interval = 0;
    } else if (s < 1000) {
		proc->state.seed.interval = s;
		proc->state.seed.counter = 0;
    } else {
		proc->state.seed.A = s;
		proc->state.seed.interval = 0;
    }
}

i7word_t i7_random(i7process_t *proc, i7word_t x) {
	i7word_t r;
	i7_opcode_random(proc, x, &r);
	return r+1;
}
void i7_opcode_setiosys(i7process_t *proc, i7word_t x, i7word_t y) {
}
void i7_opcode_gestalt(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	int r = 0;
	switch (x) {
		case 0: r = 0x00030103; break; /* Say that the Glulx version is v3.1.3 */
		case 1: r = 1;          break; /* Say that the interpreter version is 1 */
		case 2: r = 0;          break; /* We do not (yet) support @setmemsize */
		case 3: r = 1;          break; /* We do support UNDO */
		case 4: if (y == 2) r = 1;     /* We do support Glk */
				       else r = 0;     /* But not any other I/O system */
			    break;
		case 5: r = 1;          break; /* We do support Unicode operations */
		case 6: r = 1;          break; /* We do support @mzero and @mcopy */
		case 7: r = 0;          break; /* We do not (yet) support @malloc or @mfree */
		case 8: r = 0;          break; /* Since we do not support @malloc */
		case 9: r = 0;          break; /* We do not support @accelfunc pr @accelparam */
		case 10: r = 0;         break; /* And therefore provide none of their accelerants */
		case 11: r = 1;         break; /* We do support floating-point maths operations */
		case 12: r = 1;         break; /* We do support @hasundo and @discardundo */
	}
	if (z) *z = r;
}
void i7_opcode_add(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x + y;
}
void i7_opcode_sub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x - y;
}
void i7_opcode_neg(i7process_t *proc, i7word_t x, i7word_t *y) {
	if (y) *y = -x;
}
void i7_opcode_mul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x * y;
}

void i7_opcode_div(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay;
	if (x < 0) {
		ax = (-x);
		if (y < 0) {
			ay = (-y);
			result = ax / ay;
		} else {
			ay = y;
			result = -(ax / ay);
		}
	} else {
		ax = x;
		if (y < 0) {
			ay = (-y);
			result = -(ax / ay);
		} else {
			ay = y;
			result = ax / ay;
		}
	}
	if (z) *z = result;
}

void i7_opcode_mod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay = (y < 0)?(-y):y;
	if (x < 0) {
		ax = (-x);
		result = -(ax % ay);
	} else {
		ax = x;
		result = ax % ay;
	}
	if (z) *z = result;
}

i7word_t i7_div(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	i7_opcode_div(proc, x, y, &z);
	return z;
}

i7word_t i7_mod(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	i7_opcode_mod(proc, x, y, &z);
	return z;
}
void i7_opcode_fadd(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) + i7_decode_float(y));
}
void i7_opcode_fsub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) - i7_decode_float(y));
}
void i7_opcode_fmul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) * i7_decode_float(y));
}
void i7_opcode_fdiv(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = i7_encode_float(i7_decode_float(x) / i7_decode_float(y));
}
void i7_opcode_fmod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z, i7word_t *w) {
	float fx = i7_decode_float(x), fy = i7_decode_float(y);
	float fquot = fmodf(fx, fy);
	i7word_t quot = i7_encode_float(fquot);
	i7word_t rem = i7_encode_float((fx-fquot) / fy);
	if (rem == 0x0 || rem == 0x80000000) {
		/* When the quotient is zero, the sign has been lost in the
		 shuffle. We'll set that by hand, based on the original arguments. */
		rem = (x ^ y) & 0x80000000;
	}
	if (z) *z = quot;
	if (w) *w = rem;
}

void i7_opcode_floor(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(floorf(i7_decode_float(x)));
}
void i7_opcode_ceil(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(ceilf(i7_decode_float(x)));
}

void i7_opcode_ftonumn(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = i7_decode_float(x);
	i7word_t result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7word_t) (roundf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7word_t) (roundf(fx));
	}
	*y = result;
}

void i7_opcode_ftonumz(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = i7_decode_float(x);
 	i7word_t result;
	if (!signbit(fx)) {
		if (isnan(fx) || isinf(fx) || (fx > 2147483647.0))
			result = 0x7FFFFFFF;
		else
			result = (i7word_t) (truncf(fx));
	}
	else {
		if (isnan(fx) || isinf(fx) || (fx < -2147483647.0))
			result = 0x80000000;
		else
			result = (i7word_t) (truncf(fx));
	}
	*y = result;
}

void i7_opcode_numtof(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float((float) x);
}
void i7_opcode_exp(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(expf(i7_decode_float(x)));
}
void i7_opcode_log(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(logf(i7_decode_float(x)));
}
void i7_opcode_pow(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (i7_decode_float(x) == 1.0f)
		*z = i7_encode_float(1.0f);
	else if ((i7_decode_float(y) == 0.0f) || (i7_decode_float(y) == -0.0f))
		*z = i7_encode_float(1.0f);
	else if ((i7_decode_float(x) == -1.0f) && isinf(i7_decode_float(y)))
		*z = i7_encode_float(1.0f);
	else
		*z = i7_encode_float(powf(i7_decode_float(x), i7_decode_float(y)));
}
void i7_opcode_sqrt(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(sqrtf(i7_decode_float(x)));
}
void i7_opcode_sin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(sinf(i7_decode_float(x)));
}
void i7_opcode_cos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(cosf(i7_decode_float(x)));
}
void i7_opcode_tan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(tanf(i7_decode_float(x)));
}

void i7_opcode_asin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(asinf(i7_decode_float(x)));
}
void i7_opcode_acos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(acosf(i7_decode_float(x)));
}
void i7_opcode_atan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = i7_encode_float(atanf(i7_decode_float(x)));
}
int i7_opcode_jfeq(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
	int result;
	if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
		/* The delta is NaN, which can never match. */
		result = 0;
	} else if ((x == 0x7F800000 || x == 0xFF800000)
			&& (y == 0x7F800000 || y == 0xFF800000)) {
		/* Both are infinite. Opposite infinities are never equal,
		even if the difference is infinite, so this is easy. */
		result = (x == y);
	} else {
		float fx = i7_decode_float(y) - i7_decode_float(x);
		float fy = fabs(i7_decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (result) return 1;
	return 0;
}

int i7_opcode_jfne(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
	int result;
	if ((z & 0x7F800000) == 0x7F800000 && (z & 0x007FFFFF) != 0) {
		/* The delta is NaN, which can never match. */
		result = 0;
	} else if ((x == 0x7F800000 || x == 0xFF800000)
			&& (y == 0x7F800000 || y == 0xFF800000)) {
		/* Both are infinite. Opposite infinities are never equal,
		even if the difference is infinite, so this is easy. */
		result = (x == y);
	} else {
		float fx = i7_decode_float(y) - i7_decode_float(x);
		float fy = fabs(i7_decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (!result) return 1;
	return 0;
}

int i7_opcode_jfge(i7process_t *proc, i7word_t x, i7word_t y) {
	if (i7_decode_float(x) >= i7_decode_float(y)) return 1;
	return 0;
}

int i7_opcode_jflt(i7process_t *proc, i7word_t x, i7word_t y) {
	if (i7_decode_float(x) < i7_decode_float(y)) return 1;
	return 0;
}

int i7_opcode_jisinf(i7process_t *proc, i7word_t x) {
    if (x == 0x7F800000 || x == 0xFF800000) return 1;
	return 0;
}

int i7_opcode_jisnan(i7process_t *proc, i7word_t x) {
    if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
	return 0;
}
char *i7_texts[];
char *i7_text_to_C_string(i7word_t str) {
	return i7_texts[str - I7VAL_STRINGS_BASE];
}
void i7_print_dword(i7process_t *proc, i7word_t at) {
	for (i7byte_t i=1; i<=9; i++) {
		i7byte_t c = i7_read_byte(proc, at+i);
		if (c == 0) break;
		i7_print_char(proc, c);
	}
}
i7word_t i7_metaclass(i7process_t *proc, i7word_t id) {
	if (id <= 0) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) return i7_mgl_Routine;
	if (id >= I7VAL_STRINGS_BASE) return i7_mgl_String;
	return i7_metaclass_of[id];
}
int i7_ofclass(i7process_t *proc, i7word_t id, i7word_t cl_id) {
	if ((id <= 0) || (cl_id <= 0)) return 0;
	if (id >= I7VAL_FUNCTIONS_BASE) {
		if (cl_id == i7_mgl_Routine) return 1;
		return 0;
	}
	if (id >= I7VAL_STRINGS_BASE) {
		if (cl_id == i7_mgl_String) return 1;
		return 0;
	}
	if (id == i7_mgl_Class) {
		if (cl_id == i7_mgl_Class) return 1;
		return 0;
	}
	if (cl_id == i7_mgl_Object) {
		if (i7_metaclass_of[id] == i7_mgl_Object) return 1;
		return 0;
	}
	int cl_found = i7_class_of[id];
	while (cl_found != i7_mgl_Class) {
		if (cl_id == cl_found) return 1;
		cl_found = i7_class_of[cl_found];
	}
	return 0;
}
void i7_empty_object_tree(i7process_t *proc) {
	proc->state.object_tree_parent  = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_child   = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	proc->state.object_tree_sibling = i7_calloc(proc, i7_max_objects, sizeof(i7word_t));
	for (int i=0; i<i7_max_objects; i++) {
		proc->state.object_tree_parent[i] = 0;
		proc->state.object_tree_child[i] = 0;
		proc->state.object_tree_sibling[i] = 0;
	}
}
i7_property_set i7_properties[i7_max_objects];

i7word_t i7_prop_len(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr_array) {
	i7word_t pr = i7_read_word(proc, pr_array, 1);
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return 4*i7_properties[(int) obj].len[(int) pr];
}

i7word_t i7_prop_addr(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr_array) {
	i7word_t pr = i7_read_word(proc, pr_array, 1);
	if ((obj <= 0) || (obj >= i7_max_objects) ||
		(pr < 0) || (pr >= i7_no_property_ids)) return 0;
	return i7_properties[(int) obj].address[(int) pr];
}

int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t pr_array) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].address[(int) prop_id] != 0) return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}
void i7_move(i7process_t *proc, i7word_t obj, i7word_t to) {
	if ((obj <= 0) || (obj >= i7_max_objects)) return;
	int p = proc->state.object_tree_parent[obj];
	if (p) {
		if (proc->state.object_tree_child[p] == obj) {
			proc->state.object_tree_child[p] = proc->state.object_tree_sibling[obj];
		} else {
			int c = proc->state.object_tree_child[p];
			while (c != 0) {
				if (proc->state.object_tree_sibling[c] == obj) {
					proc->state.object_tree_sibling[c] = proc->state.object_tree_sibling[obj];
					break;
				}
				c = proc->state.object_tree_sibling[c];
			}
		}
	}
	proc->state.object_tree_parent[obj] = to;
	proc->state.object_tree_sibling[obj] = 0;
	if (to) {
		proc->state.object_tree_sibling[obj] = proc->state.object_tree_child[to];
		proc->state.object_tree_child[to] = obj;
	}
}
i7word_t i7_parent(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_parent[id];
}
i7word_t i7_child(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_child[id];
}
i7word_t i7_children(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	i7word_t c=0;
	for (int i=0; i<i7_max_objects; i++)
		if (proc->state.object_tree_parent[i] == id)
			c++;
	return c;
}
i7word_t i7_sibling(i7process_t *proc, i7word_t id) {
	if (i7_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.object_tree_sibling[id];
}
int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2) {
	if (i7_metaclass(proc, obj1) != i7_mgl_Object) return 0;
	if (obj2 == 0) return 0;
	if (proc->state.object_tree_parent[obj1] == obj2) return 1;
	return 0;
}
i7word_t i7_read_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (i7_properties[(int) owner_id].address[(int) prop_id] == 0) {
		owner_id = i7_class_of[owner_id];
		if (owner_id == i7_mgl_Class) return 0;
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	return i7_read_word(proc, address, 0);
}

void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array, i7word_t val) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	if (address) i7_write_word(proc, address, 0, val);
	else {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
}

i7word_t i7_change_prop_value(i7process_t *proc, i7word_t obj, i7word_t pr,
	i7word_t to, int way) {
	i7word_t val = i7_read_prop_value(proc, obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:
			i7_write_prop_value(proc, obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:
			new_val = val-1; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:
			new_val = val; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_PREINC:
			new_val = val+1; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_POSTINC:
			new_val = val; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_SETBIT:
			new_val = val | new_val; i7_write_prop_value(proc, obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT:
			new_val = val &(~new_val); i7_write_prop_value(proc, obj, pr, new_val); break;
	}
	return new_val;
}
int i7_provides_gprop_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
	if (K == i7_mgl_OBJECT_TY) {
		if ((((obj) && ((i7_metaclass(proc, obj) == i7_mgl_Object)))) &&
			(((i7_read_word(proc, pr, 0) == 2) || (i7_provides(proc, obj, pr)))))
			return 1;
	} else {
		if ((((obj >= 1)) && ((obj <= i7_read_word(proc, i7_mgl_value_ranges, K))))) {
			i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
			if (((holder) && ((i7_provides(proc, holder, pr))))) return 1;
		}
	}
	return 0;
}

i7word_t i7_read_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
	i7word_t val = 0;
    if ((K == i7_mgl_OBJECT_TY)) {
    	return (i7word_t) i7_read_prop_value(proc, obj, pr);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        return (i7word_t) i7_read_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE));
    }
	return val;
}

void i7_write_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t val, i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        i7_write_prop_value(proc, obj, pr, val);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        i7_write_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE), val);
    }
}

void i7_change_gprop_value_inner(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t val, i7word_t form,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges,
	i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        i7_change_prop_value(proc, obj, pr, val, form);
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        i7_change_word(proc,
        	i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE), val, form);
    }
}
i7word_t i7_call_0(i7process_t *proc, i7word_t id) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(proc, id, args, 0);
}
i7word_t i7_call_1(i7process_t *proc, i7word_t id, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(proc, id, args, 1);
}
i7word_t i7_call_2(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(proc, id, args, 2);
}
i7word_t i7_call_3(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(proc, id, args, 3);
}
i7word_t i7_call_4(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3, i7word_t v4) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(proc, id, args, 4);
}
i7word_t i7_call_5(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3, i7word_t v4, i7word_t v5) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(proc, id, args, 5);
}
i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 0);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 1);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 2);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 3);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}
void i7_print_C_string(i7process_t *proc, char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char(proc, (i7word_t) c_string[i]);
}

void i7_print_decimal(i7process_t *proc, i7word_t x) {
	char room[32];
	sprintf(room, "%d", (int) x);
	i7_print_C_string(proc, room);
}

void i7_print_object(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void i7_print_box(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit(proc);
}
void i7_print_char(i7process_t *proc, i7word_t x) {
	if (x == 13) x = 10;
	i7_push(proc, x);
	i7word_t current = 0;
	i7_opcode_glk(proc, i7_glk_stream_get_current, 0, &current);
	i7_push(proc, current);
	i7_opcode_glk(proc, i7_glk_put_char_stream, 2, NULL);
}
void i7_styling(i7process_t *proc, i7word_t which, i7word_t what) {
	(proc->stylist)(proc, which, what);
}
void i7_opcode_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc,
	i7word_t *z) {
	(proc->glk_implementation)(proc, glk_api_selector, varargc, z);
}
void i7_default_glk(i7process_t *proc, i7word_t selector, i7word_t varargc, i7word_t *z) {
	i7_debug_stack("i7_opcode_glk");
	i7word_t a[5] = { 0, 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7word_t v = i7_pull(proc);
		if (argc < 5) a[argc++] = v;
		varargc--;
	}

	int rv = 0;
	switch (selector) {
		case i7_glk_gestalt:
			rv = i7_miniglk_gestalt(proc, a[0]); break;

		/* Characters */
		case i7_glk_char_to_lower:
			rv = i7_miniglk_char_to_lower(proc, a[0]); break;
		case i7_glk_char_to_upper:
			rv = i7_miniglk_char_to_upper(proc, a[0]); break;

		/* File handling */
		case i7_glk_fileref_create_by_name:
			rv = i7_miniglk_fileref_create_by_name(proc, a[0], a[1], a[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_miniglk_fileref_does_file_exist(proc, a[0]); break;
		/* And we ignore: */
		case i7_glk_fileref_destroy: rv = 0; break;
		case i7_glk_fileref_iterate: rv = 0; break;

		/* Stream handling */
		case i7_glk_stream_get_position:
			rv = i7_miniglk_stream_get_position(proc, a[0]); break;
		case i7_glk_stream_close:
			i7_miniglk_stream_close(proc, a[0], a[1]); break;
		case i7_glk_stream_set_current:
			i7_miniglk_stream_set_current(proc, a[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_miniglk_stream_get_current(proc); break;
		case i7_glk_stream_open_memory:
			rv = i7_miniglk_stream_open_memory(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_miniglk_stream_open_memory_uni(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_stream_open_file:
			rv = i7_miniglk_stream_open_file(proc, a[0], a[1], a[2]); break;
		case i7_glk_stream_set_position:
			i7_miniglk_stream_set_position(proc, a[0], a[1], a[2]); break;
		case i7_glk_put_char_stream:
			i7_miniglk_put_char_stream(proc, a[0], a[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_miniglk_get_char_stream(proc, a[0]); break;
		/* And we ignore: */
		case i7_glk_stream_iterate: rv = 0; break;

		/* Window handling */
		case i7_glk_window_open:
			rv = i7_miniglk_window_open(proc, a[0], a[1], a[2], a[3], a[4]); break;
		case i7_glk_set_window:
			rv = i7_miniglk_set_window(proc, a[0]); break;
		case i7_glk_window_get_size:
			rv = i7_miniglk_window_get_size(proc, a[0], a[1], a[2]); break;
		/* And we ignore: */
		case i7_glk_window_iterate: rv = 0; break;
		case i7_glk_window_move_cursor: rv = 0; break;

		/* Event handling */
		case i7_glk_request_line_event:
			rv = i7_miniglk_request_line_event(proc, a[0], a[1], a[2], a[3]); break;
		case i7_glk_select:
			rv = i7_miniglk_select(proc, a[0]); break;

		/* Other selectors we recognise, but then ignore: */
		case i7_glk_set_style: rv = 0; break;
		case i7_glk_stylehint_set: rv = 0; break;
		case i7_glk_schannel_create: rv = 0; break;
		case i7_glk_schannel_iterate: rv = 0; break;

		default:
			printf("Unimplemented Glk selector: %d.\n", selector);
			i7_fatal_exit(proc);
			break;
	}
	if (z) *z = rv;
}

i7word_t i7_miniglk_gestalt(i7process_t *proc, i7word_t g) {
	switch (g) {
		case i7_gestalt_Version:
		case i7_gestalt_CharInput:
		case i7_gestalt_LineInput:
		case i7_gestalt_Unicode:
		case i7_gestalt_UnicodeNorm:
			return 1;
		case i7_gestalt_CharOutput:
			return i7_gestalt_CharOutput_CannotPrint;
		case i7_gestalt_MouseInput:
		case i7_gestalt_Timer:
		case i7_gestalt_Graphics:
		case i7_gestalt_DrawImage:
		case i7_gestalt_Sound:
		case i7_gestalt_SoundVolume:
		case i7_gestalt_SoundNotify:
		case i7_gestalt_Hyperlinks:
		case i7_gestalt_HyperlinkInput:
		case i7_gestalt_SoundMusic:
		case i7_gestalt_GraphicsTransparency:
		case i7_gestalt_LineInputEcho:
		case i7_gestalt_LineTerminators:
		case i7_gestalt_LineTerminatorKey:
		case i7_gestalt_DateTime:
		case i7_gestalt_Sound2:
		case i7_gestalt_ResourceStream:
		case i7_gestalt_GraphicsCharInput:
			return 0;
	}
	return 0;
}

i7word_t i7_miniglk_char_to_lower(i7process_t *proc, i7word_t c) {
	if (((c >= 0x41) && (c <= 0x5A)) ||
		((c >= 0xC0) && (c <= 0xD6)) ||
		((c >= 0xD8) && (c <= 0xDE))) c += 32;
	return c;
}

i7word_t i7_miniglk_char_to_upper(i7process_t *proc, i7word_t c) {
	if (((c >= 0x61) && (c <= 0x7A)) ||
		((c >= 0xE0) && (c <= 0xF6)) ||
		((c >= 0xF8) && (c <= 0xFE))) c -= 32;
	return c;
}
void i7_initialise_miniglk_data(i7process_t *proc) {
	proc->miniglk = malloc(sizeof(miniglk_data));
	if (proc->miniglk == NULL) {
		printf("Memory allocation failed\n");
		exit(1);
	}
	proc->miniglk->no_files = 0;
	proc->miniglk->stdout_stream_id = 0;
	proc->miniglk->stderr_stream_id = 1;
	proc->miniglk->no_windows = 1;
	proc->miniglk->rb_back = 0;
	proc->miniglk->rb_front = 0;
	proc->miniglk->no_line_events = 0;
}

void i7_initialise_miniglk(i7process_t *proc) {
	for (int i=0; i<I7_MINIGLK_MAX_STREAMS; i++)
		proc->miniglk->memory_streams[i] = i7_mg_new_stream(proc, NULL, 0);
	i7_mg_stream_t stdout_stream = i7_mg_new_stream(proc, stdout, 0);
	stdout_stream.active = 1;
	stdout_stream.encode_UTF8 = 1;
	proc->miniglk->memory_streams[proc->miniglk->stdout_stream_id] = stdout_stream;
	i7_mg_stream_t stderr_stream = i7_mg_new_stream(proc, stderr, 0);
	stderr_stream.active = 1;
	stderr_stream.encode_UTF8 = 1;
	proc->miniglk->memory_streams[proc->miniglk->stderr_stream_id] = stderr_stream;
	i7_miniglk_stream_set_current(proc, proc->miniglk->stdout_stream_id);
}
int i7_mg_new_file(i7process_t *proc) {
	if (proc->miniglk->no_files >= I7_MINIGLK_MAX_FILES) {
		fprintf(stderr, "Out of files\n"); i7_fatal_exit(proc);
	}
	int id = proc->miniglk->no_files++;
	proc->miniglk->files[id].usage = 0;
	proc->miniglk->files[id].name = 0;
	proc->miniglk->files[id].rock = 0;
	proc->miniglk->files[id].handle = NULL;
	proc->miniglk->files[id].leafname[0] = 0;
	return id;
}

int i7_mg_fseek(i7process_t *proc, int id, int pos, int origin) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	return fseek(proc->miniglk->files[id].handle, pos, origin);
}

int i7_mg_ftell(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	int t = ftell(proc->miniglk->files[id].handle);
	return t;
}

int i7_mg_fopen(i7process_t *proc, int id, int mode) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle) {
		fprintf(stderr, "File already open\n"); i7_fatal_exit(proc);
	}
	char *c_mode = "r";
	switch (mode) {
		case i7_filemode_Write: c_mode = "w"; break;
		case i7_filemode_Read: c_mode = "r"; break;
		case i7_filemode_ReadWrite: c_mode = "r+"; break;
		case i7_filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen(proc->miniglk->files[id].leafname, c_mode);
	if (h == NULL) return 0;
	proc->miniglk->files[id].handle = h;
	if (mode == i7_filemode_WriteAppend) i7_mg_fseek(proc, id, 0, SEEK_END);
	return 1;
}

void i7_mg_fclose(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	fclose(proc->miniglk->files[id].handle);
	proc->miniglk->files[id].handle = NULL;
}


void i7_mg_fputc(i7process_t *proc, int c, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	fputc(c, proc->miniglk->files[id].handle);
}

int i7_mg_fgetc(i7process_t *proc, int id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle == NULL) {
		fprintf(stderr, "File not open\n"); i7_fatal_exit(proc);
	}
	int c = fgetc(proc->miniglk->files[id].handle);
	return c;
}
i7word_t i7_miniglk_fileref_create_by_name(i7process_t *proc, i7word_t usage,
	i7word_t name, i7word_t rock) {
	int id = i7_mg_new_file(proc);
	proc->miniglk->files[id].usage = usage;
	proc->miniglk->files[id].name = name;
	proc->miniglk->files[id].rock = rock;
	char *L = proc->miniglk->files[id].leafname;
	for (int i=0; i<I7_MINIGLK_LEAFNAME_LENGTH; i++) {
		L[i] = i7_read_byte(proc, name+1+i);
		if (L[i] == 0) break;
	}
	L[127] = 0;
	sprintf(L + strlen(L), ".glkdata");
	return id;
}

i7word_t i7_miniglk_fileref_does_file_exist(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_FILES)) {
		fprintf(stderr, "Bad file ID\n"); i7_fatal_exit(proc);
	}
	if (proc->miniglk->files[id].handle) return 1;
	if (i7_mg_fopen(proc, id, i7_filemode_Read)) {
		i7_mg_fclose(proc, id); return 1;
	}
	return 0;
}
i7_mg_stream_t i7_mg_new_stream(i7process_t *proc, FILE *F, int win_id) {
	i7_mg_stream_t S;
	S.to_file = F;
	S.to_file_id = -1;
	S.to_memory = NULL;
	S.memory_used = 0;
	S.memory_capacity = 0;
	S.write_here_on_closure = 0;
	S.write_limit = 0;
	S.previous_id = 0;
	S.active = 0;
	S.encode_UTF8 = 0;
	S.char_size = 4;
	S.chars_read = 0;
	S.read_position = 0;
	S.end_position = 0;
	S.owned_by_window_id = win_id;
	S.style[0] = 0;
	S.fixed_pitch = 0;
	S.composite_style[0] = 0;
	return S;
}

i7word_t i7_mg_open_stream(i7process_t *proc, FILE *F, int win_id) {
	for (int i=0; i<I7_MINIGLK_MAX_STREAMS; i++)
		if (proc->miniglk->memory_streams[i].active == 0) {
			proc->miniglk->memory_streams[i] = i7_mg_new_stream(proc, F, win_id);
			proc->miniglk->memory_streams[i].active = 1;
			proc->miniglk->memory_streams[i].previous_id =
				proc->state.current_output_stream_ID;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	return 0;
}
i7word_t i7_miniglk_stream_open_memory(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != i7_filemode_Write) {
		fprintf(stderr, "Only file mode Write supported, not %d\n", fmode);
		i7_fatal_exit(proc);
	}
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].write_here_on_closure = buffer;
	proc->miniglk->memory_streams[id].write_limit = (size_t) len;
	proc->miniglk->memory_streams[id].char_size = 1;
	proc->state.current_output_stream_ID = id;
	return id;
}

i7word_t i7_miniglk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer,
	i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != i7_filemode_Write) {
		fprintf(stderr, "Only file mode Write supported, not %d\n", fmode);
		i7_fatal_exit(proc);
	}
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].write_here_on_closure = buffer;
	proc->miniglk->memory_streams[id].write_limit = (size_t) len;
	proc->miniglk->memory_streams[id].char_size = 4;
	proc->state.current_output_stream_ID = id;
	return id;
}

i7word_t i7_miniglk_stream_open_file(i7process_t *proc, i7word_t fileref,
	i7word_t usage, i7word_t rock) {
	i7word_t id = i7_mg_open_stream(proc, NULL, 0);
	proc->miniglk->memory_streams[id].to_file_id = fileref;
	if (i7_mg_fopen(proc, fileref, usage) == 0) return 0;
	return id;
}

void i7_miniglk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos,
	i7word_t seekmode) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case i7_seekmode_Start: origin = SEEK_SET; break;
			case i7_seekmode_Current: origin = SEEK_CUR; break;
			case i7_seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit(proc);
		}
		i7_mg_fseek(proc, S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n");
		i7_fatal_exit(proc);
	}
}

i7word_t i7_miniglk_stream_get_position(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7word_t) i7_mg_ftell(proc, S->to_file_id);
	}
	return (i7word_t) S->memory_used;
}
i7word_t i7_miniglk_stream_get_current(i7process_t *proc) {
	return proc->state.current_output_stream_ID;
}

void i7_miniglk_stream_set_current(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	proc->state.current_output_stream_ID = id;
}
void i7_mg_put_to_stream(i7process_t *proc, i7word_t rock, wchar_t c) {
	i7_mg_stream_t *S =
		&(proc->miniglk->memory_streams[proc->state.current_output_stream_ID]);
	if (proc->receiver == NULL) fputc(c, stdout);
	(proc->receiver)(rock, c, S->composite_style);
}

void i7_miniglk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x) {
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[stream_id]);
	if (S->to_file) {
		int win_id = S->owned_by_window_id;
		int rock = -1;
		if (win_id >= 1) rock = i7_mg_get_window_rock(proc, win_id);
		unsigned int c = (unsigned int) x;
		if (proc->use_UTF8) {
			if (c >= 0x800) {
				i7_mg_put_to_stream(proc, rock, 0xE0 + (c >> 12));
				i7_mg_put_to_stream(proc, rock, 0x80 + ((c >> 6) & 0x3f));
				i7_mg_put_to_stream(proc, rock, 0x80 + (c & 0x3f));
			} else if (c >= 0x80) {
				i7_mg_put_to_stream(proc, rock, 0xC0 + (c >> 6));
				i7_mg_put_to_stream(proc, rock, 0x80 + (c & 0x3f));
			} else i7_mg_put_to_stream(proc, rock, (int) c);
		} else {
			i7_mg_put_to_stream(proc, rock, (int) c);
		}
	} else if (S->to_file_id >= 0) {
		i7_mg_fputc(proc, (int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) {
				fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
			}
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

i7word_t i7_miniglk_get_char_stream(i7process_t *proc, i7word_t stream_id) {
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_mg_fgetc(proc, S->to_file_id);
	}
	return 0;
}

void i7_miniglk_stream_close(i7process_t *proc, i7word_t id, i7word_t result) {
	if ((id < 0) || (id >= I7_MINIGLK_MAX_STREAMS)) {
		fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(proc); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(proc); }
	i7_mg_stream_t *S = &(proc->miniglk->memory_streams[id]);
	if (S->active == 0) {
		fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(proc);
	}
	if (proc->state.current_output_stream_ID == id)
		proc->state.current_output_stream_ID = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(proc, S->write_here_on_closure, i, S->to_memory[i]);
				else
					i7_write_word(proc, S->write_here_on_closure, i, 0);
		} else {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_byte(proc, S->write_here_on_closure + i, S->to_memory[i]);
				else
					i7_write_byte(proc, S->write_here_on_closure + i, 0);
		}
	}
	if (result == -1) {
		i7_push(proc, S->chars_read);
		i7_push(proc, S->memory_used);
	} else if (result != 0) {
		i7_write_word(proc, result, 0, S->chars_read);
		i7_write_word(proc, result, 1, S->memory_used);
	}
	if (S->to_file_id >= 0) i7_mg_fclose(proc, S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

i7word_t i7_miniglk_window_open(i7process_t *proc, i7word_t split, i7word_t method,
	i7word_t size, i7word_t wintype, i7word_t rock) {
	if (proc->miniglk->no_windows >= 128) {
		fprintf(stderr, "Out of windows\n"); i7_fatal_exit(proc);
	}
	int id = proc->miniglk->no_windows++;
	proc->miniglk->windows[id].type = wintype;
	proc->miniglk->windows[id].stream_id = i7_mg_open_stream(proc, stdout, id);
	proc->miniglk->windows[id].rock = rock;
	return id;
}

i7word_t i7_miniglk_set_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= proc->miniglk->no_windows)) {
		fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	i7_miniglk_stream_set_current(proc, proc->miniglk->windows[id].stream_id);
	return 0;
}

i7word_t i7_mg_get_window_rock(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= proc->miniglk->no_windows)) {
		fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc);
	}
	return proc->miniglk->windows[id].rock;
}

i7word_t i7_miniglk_window_get_size(i7process_t *proc, i7word_t id, i7word_t a1,
	i7word_t a2) {
	if (a1) i7_write_word(proc, a1, 0, 80);
	if (a2) i7_write_word(proc, a2, 0, 8);
	return 0;
}
void i7_mg_add_event_to_buffer(i7process_t *proc, i7_mg_event_t e) {
	proc->miniglk->events_ring_buffer[proc->miniglk->rb_front] = e;
	proc->miniglk->rb_front++;
	if (proc->miniglk->rb_front == I7_MINIGLK_RING_BUFFER_SIZE)
		proc->miniglk->rb_front = 0;
}

i7_mg_event_t *i7_mg_get_event_from_buffer(i7process_t *proc) {
	if (proc->miniglk->rb_front == proc->miniglk->rb_back) return NULL;
	i7_mg_event_t *e = &(proc->miniglk->events_ring_buffer[proc->miniglk->rb_back]);
	proc->miniglk->rb_back++;
	if (proc->miniglk->rb_back == I7_MINIGLK_RING_BUFFER_SIZE)
		proc->miniglk->rb_back = 0;
	return e;
}
i7word_t i7_miniglk_select(i7process_t *proc, i7word_t structure) {
	i7_mg_event_t *e = i7_mg_get_event_from_buffer(proc);
	if (e == NULL) {
		fprintf(stderr, "No events available to select\n"); i7_fatal_exit(proc);
	}
	if (structure == -1) {
		i7_push(proc, e->type);
		i7_push(proc, e->win_id);
		i7_push(proc, e->val1);
		i7_push(proc, e->val2);
	} else {
		if (structure) {
			i7_write_word(proc, structure, 0, e->type);
			i7_write_word(proc, structure, 1, e->win_id);
			i7_write_word(proc, structure, 2, e->val1);
			i7_write_word(proc, structure, 3, e->val2);
		}
	}
	return 0;
}

i7word_t i7_miniglk_request_line_event(i7process_t *proc, i7word_t window_id,
	i7word_t buffer, i7word_t max_len, i7word_t init_len) {
	i7_mg_event_t e;
	e.type = i7_evtype_LineInput;
	e.win_id = window_id;
	e.val1 = 1;
	e.val2 = 0;
	wchar_t c; int pos = init_len;
	if (proc->sender == NULL) i7_benign_exit(proc);
	char *s = (proc->sender)(proc->send_count++);
	int i = 0;
	while (1) {
		c = s[i++];
		if ((c == EOF) || (c == 0) || (c == '\n') || (c == '\r')) break;
		if (pos < max_len) i7_write_byte(proc, buffer + pos++, c);
	}
	if (pos < max_len) i7_write_byte(proc, buffer + pos, 0);
	else i7_write_byte(proc, buffer + max_len-1, 0);
	e.val1 = pos;
	i7_mg_add_event_to_buffer(proc, e);
	if (proc->miniglk->no_line_events++ == 1000) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n");
		exit(0);
	}
	return 0;
}

i7word_t i7_fn_TEXT_TY_CharacterLength(i7process_t *proc, i7word_t i7_mgl_local_txt,
	i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dsize,
	i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp, i7word_t i7_mgl_local_r);
i7word_t i7_fn_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect,
	i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes,
	i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags,
	i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
void i7_default_stylist(i7process_t *proc, i7word_t which, i7word_t what) {
	i7_mg_stream_t *S =
		&(proc->miniglk->memory_streams[proc->state.current_output_stream_ID]);
	if (which == 1) {
		S->fixed_pitch = what;
	} else {
		S->style[0] = 0;
		switch (what) {
			case 0: break;
			case 1: sprintf(S->style, "bold"); break;
			case 2: sprintf(S->style, "italic"); break;
			case 3: sprintf(S->style, "reverse"); break;
			default: {
			    #ifdef i7_mgl_BASICINFORMKIT
				int L =
					i7_fn_TEXT_TY_CharacterLength(proc, what, 0, 0, 0, 0, 0, 0);
				if (L > 127) L = 127;
				for (int i=0; i<L; i++) S->style[i] =
					i7_fn_BlkValueRead(proc, what, i, 0, 0, 0, 0, 0, 0, 0);
				S->style[L] = 0;
				#endif
			}
		}
	}
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (S->composite_style[0])
			sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}
i7word_t i7_encode_float(i7float_t val) {
    i7word_t res;
    *(i7float_t *)(&res) = val;
    return res;
}

i7float_t i7_decode_float(i7word_t val) {
    i7float_t res;
    *(i7word_t *)(&res) = val;
    return res;
}
i7word_t i7_read_variable(i7process_t *proc, i7word_t var_id) {
	return proc->state.variables[var_id];
}
void i7_write_variable(i7process_t *proc, i7word_t var_id, i7word_t val) {
	proc->state.variables[var_id] = val;
}
i7word_t i7_fn_TEXT_TY_Transmute(i7process_t *proc, i7word_t i7_mgl_local_txt);
i7word_t i7_fn_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect,
	i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes,
	i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags,
	i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
i7word_t i7_fn_BlkValueWrite(i7process_t *proc, i7word_t i7_mgl_local_to,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_val,
	i7word_t i7_mgl_local_do_not_indirect, i7word_t i7_mgl_local_long_block,
	i7word_t i7_mgl_local_chunk_size_in_bytes, i7word_t i7_mgl_local_header_size_in_bytes,
	i7word_t i7_mgl_local_flags, i7word_t i7_mgl_local_entry_size_in_bytes,
	i7word_t i7_mgl_local_seek_byte_position);
i7word_t i7_fn_TEXT_TY_CharacterLength(i7process_t *proc,
	i7word_t i7_mgl_local_txt, i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i,
	i7word_t i7_mgl_local_dsize, i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp,
	i7word_t i7_mgl_local_r);

char *i7_read_string(i7process_t *proc, i7word_t S) {
	#ifdef i7_mgl_BASICINFORMKIT
	i7_fn_TEXT_TY_Transmute(proc, S);
	int L = i7_fn_TEXT_TY_CharacterLength(proc, S, 0, 0, 0, 0, 0, 0);
	char *A = malloc(L + 1);
	if (A == NULL) {
		fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
	}
	for (int i=0; i<L; i++)
		A[i] = i7_fn_BlkValueRead(proc, S, i, 0, 0, 0, 0, 0, 0, 0);
	A[L] = 0;
	return A;
	#endif
	#ifndef i7_mgl_BASICINFORMKIT
	return NULL;
	#endif
}

void i7_write_string(i7process_t *proc, i7word_t S, char *A) {
	#ifdef i7_mgl_BASICINFORMKIT
	i7_fn_TEXT_TY_Transmute(proc, S);
	i7_fn_BlkValueWrite(proc, S, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	if (A) {
		int L = strlen(A);
		for (int i=0; i<L; i++)
			i7_fn_BlkValueWrite(proc, S, i, A[i], 0, 0, 0, 0, 0, 0, 0);
	}
	#endif
}
i7word_t i7_fn_LIST_OF_TY_GetLength(i7process_t *proc, i7word_t i7_mgl_local_list);
i7word_t i7_fn_LIST_OF_TY_SetLength(i7process_t *proc, i7word_t i7_mgl_local_list,
	i7word_t i7_mgl_local_newsize, i7word_t i7_mgl_local_this_way_only,
	i7word_t i7_mgl_local_truncation_end, i7word_t i7_mgl_local_no_items,
	i7word_t i7_mgl_local_ex, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dv);
i7word_t i7_fn_LIST_OF_TY_GetItem(i7process_t *proc, i7word_t i7_mgl_local_list,
	i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_forgive, i7word_t i7_mgl_local_no_items);
i7word_t i7_fn_LIST_OF_TY_PutItem(i7process_t *proc, i7word_t i7_mgl_local_list,
	i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_v, i7word_t i7_mgl_local_no_items,
	i7word_t i7_mgl_local_nv);

i7word_t *i7_read_list(i7process_t *proc, i7word_t S, int *N) {
	#ifdef i7_mgl_BASICINFORMKIT
	int L = i7_fn_LIST_OF_TY_GetLength(proc, S);
	i7word_t *A = calloc(L + 1, sizeof(i7word_t));
	if (A == NULL) {
		fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
	}
	for (int i=0; i<L; i++) A[i] = i7_fn_LIST_OF_TY_GetItem(proc, S, i+1, 0, 0);
	A[L] = 0;
	if (N) *N = L;
	return A;
	#endif
	#ifndef i7_mgl_BASICINFORMKIT
	return NULL;
	#endif
}

void i7_write_list(i7process_t *proc, i7word_t S, i7word_t *A, int L) {
	#ifdef i7_mgl_BASICINFORMKIT
	i7_fn_LIST_OF_TY_SetLength(proc, S, L, 0, 0, 0, 0, 0, 0);
	if (A) {
		for (int i=0; i<L; i++)
			i7_fn_LIST_OF_TY_PutItem(proc, S, i+1, A[i], 0, 0);
	}
	#endif
}
#ifdef i7_mgl_TryAction
i7word_t i7_fn_TryAction(i7process_t *proc, i7word_t i7_mgl_local_req,
	i7word_t i7_mgl_local_by, i7word_t i7_mgl_local_ac, i7word_t i7_mgl_local_n,
	i7word_t i7_mgl_local_s, i7word_t i7_mgl_local_stora, i7word_t i7_mgl_local_smeta,
	i7word_t i7_mgl_local_tbits, i7word_t i7_mgl_local_saved_command,
	i7word_t i7_mgl_local_text_of_command);
i7word_t i7_try(i7process_t *proc, i7word_t action_id, i7word_t n, i7word_t s) {
	return i7_fn_TryAction(proc, 0, 0, action_id, n, s, 0, 0, 0, 0, 0);
}
#endif
#endif
