#ifndef I7_CLIB_C_INCLUDED
#define I7_CLIB_C_INCLUDED 1

i7state i7_new_state(void) {
	i7state S;
	S.memory = NULL;
	S.himem = 0;
	S.tmp = 0;
	S.stack_pointer = 0;
	S.i7_object_tree_parent = NULL;
	S.i7_object_tree_child = NULL;
	S.i7_object_tree_sibling = NULL;
	S.variables = NULL;
	return S;
}

void i7_copy_state(i7process_t *proc, i7state *to, i7state *from) {
	to->himem = from->himem;
	to->memory = calloc(i7_static_himem, sizeof(i7byte_t));
	if (to->memory == NULL) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_static_himem; i++) to->memory[i] = from->memory[i];
	to->tmp = from->tmp;
	to->stack_pointer = from->stack_pointer;
	for (int i=0; i<from->stack_pointer; i++) to->stack[i] = from->stack[i];
	to->i7_object_tree_parent  = calloc(i7_max_objects, sizeof(i7word_t));
	to->i7_object_tree_child   = calloc(i7_max_objects, sizeof(i7word_t));
	to->i7_object_tree_sibling = calloc(i7_max_objects, sizeof(i7word_t));

	if ((to->i7_object_tree_parent == NULL) ||
		(to->i7_object_tree_child == NULL) ||
		(to->i7_object_tree_sibling == NULL)) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_max_objects; i++) {
		to->i7_object_tree_parent[i] = from->i7_object_tree_parent[i];
		to->i7_object_tree_child[i] = from->i7_object_tree_child[i];
		to->i7_object_tree_sibling[i] = from->i7_object_tree_sibling[i];
	}
	to->variables = calloc(i7_no_variables, sizeof(i7word_t));
	if (to->variables == NULL) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_no_variables; i++)
		to->variables[i] = from->variables[i];
}

void i7_destroy_state(i7process_t *proc, i7state *s) {
	free(s->memory);
	s->himem = 0;
	free(s->i7_object_tree_parent);
	free(s->i7_object_tree_child);
	free(s->i7_object_tree_sibling);
	s->stack_pointer = 0;
	free(s->variables);
}

void i7_destroy_snapshot(i7process_t *proc, i7snapshot *old) {
	i7_destroy_state(proc, &(old->then));
	old->valid = 0;
}

i7snapshot i7_new_snapshot(void) {
	i7snapshot SS;
	SS.valid = 0;
	SS.then = i7_new_state();
	return SS;
}

i7process_t i7_new_process(void) {
	i7process_t proc;
	proc.state = i7_new_state();
	for (int i=0; i<I7_MAX_SNAPSHOTS; i++) proc.snapshots[i] = i7_new_snapshot();
	proc.just_undid = 0;
	proc.snapshot_pos = 0;
	proc.receiver = i7_default_receiver;
	proc.send_count = 0;
	proc.sender = i7_default_sender;
	proc.use_UTF8 = 1;
	proc.communicator = i7_default_communicator;
	return proc;
}

i7word_t i7_default_communicator(i7process_t *proc, char *id, int argc, i7word_t *args) {
	printf("No communicator: external function calls not allowed from thus process\n");
	i7_fatal_exit(proc);
	return 0;
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
//	if (setjmp(proc->snapshots[was].env)) fprintf(stdout, "*** Restore! %d ***\n", proc->just_undid);
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
//	longjmp(proc->snapshots[was].env, 1);
}

void i7_restore_snapshot_from(i7process_t *proc, i7snapshot *ss) {
	i7_destroy_state(proc, &(proc->state));
	i7_copy_state(proc, &(proc->state), &(ss->then));
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

int default_main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_run_process(&proc);
	if (proc.termination_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return proc.termination_code;
}

i7word_t fn_i7_mgl_Main(i7process_t *proc);
int i7_run_process(i7process_t *proc) {
	int tc = setjmp(proc->execution_env);
	if (tc) {
		if (tc == 2) tc = 0;
		proc->termination_code = tc; /* terminated abnormally */
    } else {
		i7_initialise_state(proc);
		i7_initializer(proc);
		i7_initialise_streams(proc);
		fn_i7_mgl_Main(proc);
		proc->termination_code = 0; /* terminated normally */
    }
    return proc->termination_code;
}
void i7_set_process_receiver(i7process_t *proc, void (*receiver)(int id, wchar_t c, char *style), int UTF8) {
	proc->receiver = receiver;
	proc->use_UTF8 = UTF8;
}
void i7_set_process_sender(i7process_t *proc, char *(*sender)(int count)) {
	proc->sender = sender;
}
void i7_set_process_communicator(i7process_t *proc, i7word_t (*communicator)(i7process_t *proc, char *id, int argc, i7word_t *args)) {
	proc->communicator = communicator;
}

void i7_fatal_exit(i7process_t *proc) {
//	int x = 0; printf("%d", 1/x);
	longjmp(proc->execution_env, 1);
}

void i7_benign_exit(i7process_t *proc) {
	longjmp(proc->execution_env, 2);
}


i7word_t fn_i7_mgl_TEXT_TY_Transmute(i7process_t *proc, i7word_t i7_mgl_local_txt);
i7word_t fn_i7_mgl_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from, i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect, i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes, i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags, i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
i7word_t fn_i7_mgl_BlkValueWrite(i7process_t *proc, i7word_t i7_mgl_local_to, i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_val, i7word_t i7_mgl_local_do_not_indirect, i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes, i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags, i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
i7word_t fn_i7_mgl_TEXT_TY_CharacterLength(i7process_t *proc, i7word_t i7_mgl_local_txt, i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dsize, i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp, i7word_t i7_mgl_local_r);

char *i7_read_string(i7process_t *proc, i7word_t S) {
	fn_i7_mgl_TEXT_TY_Transmute(proc, S);
	int L = fn_i7_mgl_TEXT_TY_CharacterLength(proc, S, 0, 0, 0, 0, 0, 0);
	char *A = malloc(L + 1);
	if (A == NULL) {
		fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
	}
	for (int i=0; i<L; i++) A[i] = fn_i7_mgl_BlkValueRead(proc, S, i, 0, 0, 0, 0, 0, 0, 0);
	A[L] = 0;
	return A;
}

void i7_write_string(i7process_t *proc, i7word_t S, char *A) {
	fn_i7_mgl_TEXT_TY_Transmute(proc, S);
	fn_i7_mgl_BlkValueWrite(proc, S, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	if (A) {
		int L = strlen(A);
		for (int i=0; i<L; i++) fn_i7_mgl_BlkValueWrite(proc, S, i, A[i], 0, 0, 0, 0, 0, 0, 0);
	}
}

i7word_t fn_i7_mgl_LIST_OF_TY_GetLength(i7process_t *proc, i7word_t i7_mgl_local_list);
i7word_t fn_i7_mgl_LIST_OF_TY_SetLength(i7process_t *proc, i7word_t i7_mgl_local_list, i7word_t i7_mgl_local_newsize, i7word_t i7_mgl_local_this_way_only, i7word_t i7_mgl_local_truncation_end, i7word_t i7_mgl_local_no_items, i7word_t i7_mgl_local_ex, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dv);
i7word_t fn_i7_mgl_LIST_OF_TY_GetItem(i7process_t *proc, i7word_t i7_mgl_local_list, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_forgive, i7word_t i7_mgl_local_no_items);
i7word_t fn_i7_mgl_LIST_OF_TY_PutItem(i7process_t *proc, i7word_t i7_mgl_local_list, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_v, i7word_t i7_mgl_local_no_items, i7word_t i7_mgl_local_nv);

i7word_t *i7_read_list(i7process_t *proc, i7word_t S, int *N) {
	int L = fn_i7_mgl_LIST_OF_TY_GetLength(proc, S);
	i7word_t *A = calloc(L + 1, sizeof(i7word_t));
	if (A == NULL) {
		fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc);
	}
	for (int i=0; i<L; i++) A[i] = fn_i7_mgl_LIST_OF_TY_GetItem(proc, S, i+1, 0, 0);
	A[L] = 0;
	if (N) *N = L;
	return A;
}

void i7_write_list(i7process_t *proc, i7word_t S, i7word_t *A, int L) {
	fn_i7_mgl_LIST_OF_TY_SetLength(proc, S, L, 0, 0, 0, 0, 0, 0);
	if (A) {
		for (int i=0; i<L; i++)
			fn_i7_mgl_LIST_OF_TY_PutItem(proc, S, i+1, A[i], 0, 0);
	}
}
i7word_t i7_read_variable(i7process_t *proc, i7word_t var_id) {
	return proc->state.variables[var_id];
}
void i7_write_variable(i7process_t *proc, i7word_t var_id, i7word_t val) {
	proc->state.variables[var_id] = val;
}
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

	proc->state.i7_object_tree_parent  = calloc(i7_max_objects, sizeof(i7word_t));
	proc->state.i7_object_tree_child   = calloc(i7_max_objects, sizeof(i7word_t));
	proc->state.i7_object_tree_sibling = calloc(i7_max_objects, sizeof(i7word_t));

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

	proc->state.variables = calloc(i7_no_variables, sizeof(i7word_t));
	if (proc->state.variables == NULL) {
		printf("Memory allocation failed\n");
		i7_fatal_exit(proc);
	}
	for (int i=0; i<i7_no_variables; i++)
		proc->state.variables[i] = i7_initial_variable_values[i];
}
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
void glulx_aloads(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = 0x100*((i7word_t) i7_read_byte(proc, x+2*y)) + ((i7word_t) i7_read_byte(proc, x+2*y+1));
}
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
// i7word_t i7_mgl_sp = 0;

void i7_debug_stack(char *N) {
//	printf("Called %s: stack %d ", N, proc->state.stack_pointer);
//	for (int i=0; i<proc->state.stack_pointer; i++) printf("%d -> ", proc->state.stack[i]);
//	printf("\n");
}

i7word_t i7_pull(i7process_t *proc) {
	if (proc->state.stack_pointer <= 0) { printf("Stack underflow\n"); int x = 0; printf("%d", 1/x); return (i7word_t) 0; }
	return proc->state.stack[--(proc->state.stack_pointer)];
}

void i7_push(i7process_t *proc, i7word_t x) {
	if (proc->state.stack_pointer >= I7_ASM_STACK_CAPACITY) { printf("Stack overflow\n"); return; }
	proc->state.stack[proc->state.stack_pointer++] = x;
}
void glulx_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr, i7word_t *val,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE) {
	if (K == i7_mgl_OBJECT_TY) {
		if (((obj) && ((fn_i7_mgl_metaclass(proc, obj) == i7_mgl_Object)))) {
			if (((i7_read_word(proc, pr, 0) == 2) || (i7_provides(proc, obj, pr)))) {
				if (val) *val = 1;
			} else {
				if (val) *val = 0;
			}
		} else {
			if (val) *val = 0;
		}
	} else {
		if ((((obj >= 1)) && ((obj <= i7_read_word(proc, i7_mgl_value_ranges, K))))) {
			i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
			if (((holder) && ((i7_provides(proc, holder, pr))))) {
				if (val) *val = 1;
			} else {
				if (val) *val = 0;
			}
		} else {
			if (val) *val = 0;
		}
	}
}

int i7_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE) {
	i7word_t val = 0;
	glulx_provides_gprop(proc, K, obj, pr, &val, i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE);
	return val;
}

void glulx_read_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr, i7word_t *val,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        if ((i7_read_word(proc, pr, 0) == 2)) {
            if ((i7_has(proc, obj, pr))) {
                if (val) *val =  1;
            } else {
            	if (val) *val =  0;
            }
        } else {
//	        if ((pr == i7_mgl_A_door_to)) {
//	            if (val) *val = (i7word_t) i7_mcall_0(proc, obj, pr);
//	        } else {
		        if (val) *val = (i7word_t) i7_read_prop_value(proc, obj, pr);
//		    }
		}
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        if (val) *val = (i7word_t) i7_read_word(proc, i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE));
    }
}

i7word_t i7_read_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE) {
	i7word_t val = 0;
	glulx_read_gprop(proc, K, obj, pr, &val, i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE);
	return val;
}

void glulx_write_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr, i7word_t val, i7word_t form,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE) {
    if ((K == i7_mgl_OBJECT_TY)) {
        if ((i7_read_word(proc, pr, 0) == 2)) {
            if (val) {
                i7_change_prop_value(proc, K, obj, pr, 1, form);
            } else {
                i7_change_prop_value(proc, K, obj, pr, 0, form);
            }
        } else {
            (i7_change_prop_value(proc, K, obj, pr, val, form));
        }
    } else {
        i7word_t holder = i7_read_word(proc, i7_mgl_value_property_holders, K);
        (i7_write_word(proc, i7_read_prop_value(proc, holder, pr), (obj + i7_mgl_COL_HSIZE), val, form));
    }
}
void glulx_xfunction(i7process_t *proc, i7word_t selector, i7word_t varargc, i7word_t *z) {
	if (proc->communicator == NULL) {
		if (z) *z = 0;
	} else {
		i7word_t args[10] = { 0, 0, 0, 0, 0 }, argc = 0;
		while (varargc > 0) {
			i7word_t v = i7_pull(proc);
			if (argc < 10) args[argc++] = v;
			varargc--;
		}
		i7word_t rv = (proc->communicator)(proc, i7_text_of_string(selector), argc, args);
		if (z) *z = rv;
	}
}

void glulx_accelfunc(i7process_t *proc, i7word_t x, i7word_t y) { /* Intentionally ignore */
}

void glulx_accelparam(i7process_t *proc, i7word_t x, i7word_t y) { /* Intentionally ignore */
}

void glulx_copy(i7process_t *proc, i7word_t x, i7word_t *y) {
	i7_debug_stack("glulx_copy");
	if (y) *y = x;
}

void glulx_gestalt(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = 1;
}

int glulx_jeq(i7process_t *proc, i7word_t x, i7word_t y) {
	if (x == y) return 1;
	return 0;
}

void glulx_nop(i7process_t *proc) {
}

int glulx_jleu(i7process_t *proc, i7word_t x, i7word_t y) {
	i7uval ux, uy;
	*((i7word_t *) &ux) = x; *((i7word_t *) &uy) = y;
	if (ux <= uy) return 1;
	return 0;
}

int glulx_jnz(i7process_t *proc, i7word_t x) {
	if (x != 0) return 1;
	return 0;
}

int glulx_jz(i7process_t *proc, i7word_t x) {
	if (x == 0) return 1;
	return 0;
}

void glulx_quit(i7process_t *proc) {
	i7_fatal_exit(proc);
}

void glulx_setiosys(i7process_t *proc, i7word_t x, i7word_t y) {
	// Deliberately ignored: we are using stdout, not glk
}

void glulx_streamchar(i7process_t *proc, i7word_t x) {
	i7_print_char(proc, x);
}

void glulx_streamnum(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void glulx_streamstr(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: glulx_streamstr.\n");
	i7_fatal_exit(proc);
}

void glulx_streamunichar(i7process_t *proc, i7word_t x) {
	i7_print_char(proc, x);
}

void glulx_ushiftr(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
	printf("Unimplemented: glulx_ushiftr.\n");
	i7_fatal_exit(proc);
}

void glulx_aload(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	printf("Unimplemented: glulx_aload\n");
	i7_fatal_exit(proc);
}

void glulx_aloadb(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	printf("Unimplemented: glulx_aloadb\n");
	i7_fatal_exit(proc);
}

void fetchkey(i7process_t *proc, unsigned char *keybuf, i7word_t key, i7word_t keysize, i7word_t options)
{
  int ix;

  if (options & serop_KeyIndirect) {
    if (keysize <= 4) {
      for (ix=0; ix<keysize; ix++)
        keybuf[ix] = i7_read_byte(proc, key + ix);
    }
  }
  else {
    switch (keysize) {
    case 4:
		keybuf[0] = I7BYTE_0(key);
		keybuf[1] = I7BYTE_1(key);
		keybuf[2] = I7BYTE_2(key);
		keybuf[3] = I7BYTE_3(key);
      break;
    case 2:
		keybuf[0]  = I7BYTE_0(key);
		keybuf[1] = I7BYTE_1(key);
      break;
    case 1:
      keybuf[0]   = key;
      break;
    }
  }
}

void glulx_binarysearch(i7process_t *proc, i7word_t key, i7word_t keysize, i7word_t start, i7word_t structsize,
	i7word_t numstructs, i7word_t keyoffset, i7word_t options, i7word_t *s1) {
	if (s1 == NULL) return;
  unsigned char keybuf[4];
  unsigned char byte, byte2;
  i7word_t top, bot, val, addr;
  int ix;
  int retindex = ((options & serop_ReturnIndex) != 0);

  fetchkey(proc, keybuf, key, keysize, options);

  bot = 0;
  top = numstructs;
  while (bot < top) {
    int cmp = 0;
    val = (top+bot) / 2;
    addr = start + val * structsize;

    if (keysize <= 4) {
      for (ix=0; (!cmp) && ix<keysize; ix++) {
        byte = i7_read_byte(proc, addr + keyoffset + ix);
        byte2 = keybuf[ix];
        if (byte < byte2)
          cmp = -1;
        else if (byte > byte2)
          cmp = 1;
      }
    }
    else {
       for (ix=0; (!cmp) && ix<keysize; ix++) {
        byte = i7_read_byte(proc, addr + keyoffset + ix);
        byte2 = i7_read_byte(proc, key + ix);
        if (byte < byte2)
          cmp = -1;
        else if (byte > byte2)
          cmp = 1;
      }
    }

    if (!cmp) {
      if (retindex)
        *s1 = val;
      else
        *s1 = addr;
    	return;
    }

    if (cmp < 0) {
      bot = val+1;
    }
    else {
      top = val;
    }
  }

  if (retindex)
    *s1 = -1;
  else
    *s1 = 0;
}

void glulx_shiftl(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	printf("Unimplemented: glulx_shiftl\n");
	i7_fatal_exit(proc);
}

#ifdef i7_mgl_DealWithUndo
i7word_t fn_i7_mgl_DealWithUndo(i7process_t *proc);
#endif

void glulx_restoreundo(i7process_t *proc, i7word_t *x) {
	proc->just_undid = 1;
	if (i7_has_snapshot(proc)) {
		i7_restore_snapshot(proc);
		if (x) *x = 0;
		#ifdef i7_mgl_DealWithUndo
		fn_i7_mgl_DealWithUndo(proc);
		#endif
	} else {
		if (x) *x = 1;
	}
}

void glulx_saveundo(i7process_t *proc, i7word_t *x) {
	proc->just_undid = 0;
	i7_save_snapshot(proc);
	if (x) *x = 0;
}

void glulx_hasundo(i7process_t *proc, i7word_t *x) {
	i7word_t rv = 0; if (i7_has_snapshot(proc)) rv = 1;
	if (x) *x = rv;
}

void glulx_discardundo(i7process_t *proc) {
	i7_destroy_latest_snapshot(proc);
}

void glulx_restart(i7process_t *proc) {
	printf("Unimplemented: glulx_restart\n");
	i7_fatal_exit(proc);
}

void glulx_restore(i7process_t *proc, i7word_t x, i7word_t y) {
	printf("Unimplemented: glulx_restore\n");
	i7_fatal_exit(proc);
}

void glulx_save(i7process_t *proc, i7word_t x, i7word_t y) {
	printf("Unimplemented: glulx_save\n");
	i7_fatal_exit(proc);
}

void glulx_verify(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: glulx_verify\n");
	i7_fatal_exit(proc);
}
/* Return a random number in the range 0 to 2^32-1. */
uint32_t i7_random() {
	return (random() << 16) ^ random();
}

void glulx_random(i7process_t *proc, i7word_t x, i7word_t *y) {
	uint32_t value;
	if (x == 0) value = i7_random();
	else if (x >= 1) value = i7_random() % (uint32_t) (x);
	else value = -(i7_random() % (uint32_t) (-x));
	*y = (i7word_t) value;
}

i7word_t fn_i7_mgl_random(i7process_t *proc, i7word_t x) {
	i7word_t r;
	glulx_random(proc, x, &r);
	return r+1;
}

/* Set the random-number seed; zero means use as random a source as
   possible. */
void glulx_setrandom(i7process_t *proc, i7word_t s) {
	uint32_t seed;
	*((i7word_t *) &seed) = s;
	if (seed == 0) seed = time(NULL);
	srandom(seed);
}
void glulx_add(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x + y;
}

void glulx_sub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x - y;
}

void glulx_neg(i7process_t *proc, i7word_t x, i7word_t *y) {
	if (y) *y = -x;
}

void glulx_mul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (z) *z = x * y;
}

void glulx_div(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay;
	/* Since C doesn't guarantee the results of division of negative
	   numbers, we carefully convert everything to positive values
	   first. They have to be unsigned values, too, otherwise the
	   0x80000000 case goes wonky. */
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

i7word_t glulx_div_r(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	glulx_div(proc, x, y, &z);
	return z;
}

void glulx_mod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (y == 0) { printf("Division of %d by 0\n", x); i7_fatal_exit(proc); return; }
	int result, ax, ay;
	if (y < 0) {
		ay = -y;
	} else {
		ay = y;
	}
	if (x < 0) {
		ax = (-x);
		result = -(ax % ay);
	} else {
		ax = x;
		result = ax % ay;
	}
	if (z) *z = result;
}

i7word_t glulx_mod_r(i7process_t *proc, i7word_t x, i7word_t y) {
	i7word_t z;
	glulx_mod(proc, x, y, &z);
	return z;
}

i7word_t encode_float(gfloat32 val) {
    i7word_t res;
    *(gfloat32 *)(&res) = val;
    return res;
}

gfloat32 decode_float(i7word_t val) {
    gfloat32 res;
    *(i7word_t *)(&res) = val;
    return res;
}

void glulx_exp(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(expf(decode_float(x)));
}

void glulx_fadd(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = encode_float(decode_float(x) + decode_float(y));
}

void glulx_fdiv(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = encode_float(decode_float(x) / decode_float(y));
}

void glulx_floor(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(floorf(decode_float(x)));
}

void glulx_fmod(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z, i7word_t *w) {
	float fx = decode_float(x);
	float fy = decode_float(y);
	float fquot = fmodf(fx, fy);
	i7word_t quot = encode_float(fquot);
	i7word_t rem = encode_float((fx-fquot) / fy);
	if (rem == 0x0 || rem == 0x80000000) {
		/* When the quotient is zero, the sign has been lost in the
		 shuffle. We'll set that by hand, based on the original
		 arguments. */
		rem = (x ^ y) & 0x80000000;
	}
	if (z) *z = quot;
	if (w) *w = rem;
}

void glulx_fmul(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = encode_float(decode_float(x) * decode_float(y));
}

void glulx_fsub(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	*z = encode_float(decode_float(x) - decode_float(y));
}

void glulx_ftonumn(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = decode_float(x);
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

void glulx_ftonumz(i7process_t *proc, i7word_t x, i7word_t *y) {
	float fx = decode_float(x);
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

void glulx_numtof(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float((float) x);
}

int glulx_jfeq(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
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
		float fx = decode_float(y) - decode_float(x);
		float fy = fabs(decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (result) return 1;
	return 0;
}

int glulx_jfne(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z) {
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
		float fx = decode_float(y) - decode_float(x);
		float fy = fabs(decode_float(z));
		result = (fx <= fy && fx >= -fy);
	}
	if (!result) return 1;
	return 0;
}

int glulx_jfge(i7process_t *proc, i7word_t x, i7word_t y) {
	if (decode_float(x) >= decode_float(y)) return 1;
	return 0;
}

int glulx_jflt(i7process_t *proc, i7word_t x, i7word_t y) {
	if (decode_float(x) < decode_float(y)) return 1;
	return 0;
}

int glulx_jisinf(i7process_t *proc, i7word_t x) {
    if (x == 0x7F800000 || x == 0xFF800000) return 1;
	return 0;
}

int glulx_jisnan(i7process_t *proc, i7word_t x) {
    if ((x & 0x7F800000) == 0x7F800000 && (x & 0x007FFFFF) != 0) return 1;
	return 0;
}

void glulx_log(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(logf(decode_float(x)));
}

void glulx_acos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(acosf(decode_float(x)));
}

void glulx_asin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(asinf(decode_float(x)));
}

void glulx_atan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(atanf(decode_float(x)));
}

void glulx_ceil(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(ceilf(decode_float(x)));
}

void glulx_cos(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(cosf(decode_float(x)));
}

void glulx_pow(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z) {
	if (decode_float(x) == 1.0f)
		*z = encode_float(1.0f);
	else if ((decode_float(y) == 0.0f) || (decode_float(y) == -0.0f))
		*z = encode_float(1.0f);
	else if ((decode_float(x) == -1.0f) && isinf(decode_float(y)))
		*z = encode_float(1.0f);
	else
		*z = encode_float(powf(decode_float(x), decode_float(y)));
}

void glulx_sin(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(sinf(decode_float(x)));
}

void glulx_sqrt(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(sqrtf(decode_float(x)));
}

void glulx_tan(i7process_t *proc, i7word_t x, i7word_t *y) {
	*y = encode_float(tanf(decode_float(x)));
}
i7word_t fn_i7_mgl_metaclass(i7process_t *proc, i7word_t id) {
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
#define I7_MAX_PROPERTY_IDS 1000
typedef struct i7_property_set {
	i7word_t address[I7_MAX_PROPERTY_IDS];
	i7word_t len[I7_MAX_PROPERTY_IDS];
} i7_property_set;
i7_property_set i7_properties[i7_max_objects];

void i7_write_prop_value(i7process_t *proc, i7word_t owner_id, i7word_t pr_array, i7word_t val) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
	i7word_t address = i7_properties[(int) owner_id].address[(int) prop_id];
	if (address) i7_write_word(proc, address, 0, val, i7_lvalue_SET);
	else {
		printf("impossible property write (%d, %d)\n", owner_id, prop_id);
		i7_fatal_exit(proc);
	}
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

i7word_t i7_change_prop_value(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t pr, i7word_t to, int way) {
	i7word_t val = i7_read_prop_value(proc, obj, pr), new_val = val;
	switch (way) {
		case i7_lvalue_SET:      i7_write_prop_value(proc, obj, pr, to); new_val = to; break;
		case i7_lvalue_PREDEC:   new_val = val-1; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_POSTDEC:  new_val = val; i7_write_prop_value(proc, obj, pr, val-1); break;
		case i7_lvalue_PREINC:   new_val = val+1; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_POSTINC:  new_val = val; i7_write_prop_value(proc, obj, pr, val+1); break;
		case i7_lvalue_SETBIT:   new_val = val | new_val; i7_write_prop_value(proc, obj, pr, new_val); break;
		case i7_lvalue_CLEARBIT: new_val = val &(~new_val); i7_write_prop_value(proc, obj, pr, new_val); break;
	}
	return new_val;
}

void i7_give(i7process_t *proc, i7word_t owner, i7word_t prop, i7word_t val) {
	i7_write_prop_value(proc, owner, prop, val);
}

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
int i7_has(i7process_t *proc, i7word_t obj, i7word_t attr) {
	if (i7_read_prop_value(proc, obj, attr)) return 1;
	return 0;
}

int i7_provides(i7process_t *proc, i7word_t owner_id, i7word_t pr_array) {
	i7word_t prop_id = i7_read_word(proc, pr_array, 1);
	if ((owner_id <= 0) || (owner_id >= i7_max_objects) ||
		(prop_id < 0) || (prop_id >= i7_no_property_ids)) return 0;
	while (owner_id != 1) {
		if (i7_properties[(int) owner_id].address[(int) prop_id] != 0)
			return 1;
		owner_id = i7_class_of[owner_id];
	}
	return 0;
}

int i7_in(i7process_t *proc, i7word_t obj1, i7word_t obj2) {
	if (fn_i7_mgl_metaclass(proc, obj1) != i7_mgl_Object) return 0;
	if (obj2 == 0) return 0;
	if (proc->state.i7_object_tree_parent[obj1] == obj2) return 1;
	return 0;
}

i7word_t fn_i7_mgl_parent(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_parent[id];
}
i7word_t fn_i7_mgl_child(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_child[id];
}
i7word_t fn_i7_mgl_children(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	i7word_t c=0;
	for (int i=0; i<i7_max_objects; i++) if (proc->state.i7_object_tree_parent[i] == id) c++;
	return c;
}
i7word_t fn_i7_mgl_sibling(i7process_t *proc, i7word_t id) {
	if (fn_i7_mgl_metaclass(proc, id) != i7_mgl_Object) return 0;
	return proc->state.i7_object_tree_sibling[id];
}

void i7_move(i7process_t *proc, i7word_t obj, i7word_t to) {
	if ((obj <= 0) || (obj >= i7_max_objects)) return;
	int p = proc->state.i7_object_tree_parent[obj];
	if (p) {
		if (proc->state.i7_object_tree_child[p] == obj) {
			proc->state.i7_object_tree_child[p] = proc->state.i7_object_tree_sibling[obj];
		} else {
			int c = proc->state.i7_object_tree_child[p];
			while (c != 0) {
				if (proc->state.i7_object_tree_sibling[c] == obj) {
					proc->state.i7_object_tree_sibling[c] = proc->state.i7_object_tree_sibling[obj];
					break;
				}
				c = proc->state.i7_object_tree_sibling[c];
			}
		}
	}
	proc->state.i7_object_tree_parent[obj] = to;
	proc->state.i7_object_tree_sibling[obj] = 0;
	if (to) {
		proc->state.i7_object_tree_sibling[obj] = proc->state.i7_object_tree_child[to];
		proc->state.i7_object_tree_child[to] = obj;
	}
}
i7word_t i7_call_0(i7process_t *proc, i7word_t fn_ref) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(proc, fn_ref, args, 0);
}

i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 0);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_1(i7process_t *proc, i7word_t fn_ref, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(proc, fn_ref, args, 1);
}

i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 1);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_2(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(proc, fn_ref, args, 2);
}

i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 2);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_3(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(proc, fn_ref, args, 3);
}

i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 3);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_4(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(proc, fn_ref, args, 4);
}

i7word_t i7_call_5(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4, i7word_t v5) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(proc, fn_ref, args, 5);
}

void glulx_call(i7process_t *proc, i7word_t fn_ref, i7word_t varargc, i7word_t *z) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	for (int i=0; i<varargc; i++) args[i] = i7_pull(proc);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, varargc);
	if (z) *z = rv;
}
#ifdef i7_mgl_TryAction
i7word_t fn_i7_mgl_TryAction(i7process_t *proc, i7word_t i7_mgl_local_req, i7word_t i7_mgl_local_by, i7word_t i7_mgl_local_ac, i7word_t i7_mgl_local_n, i7word_t i7_mgl_local_s, i7word_t i7_mgl_local_stora, i7word_t i7_mgl_local_smeta, i7word_t i7_mgl_local_tbits, i7word_t i7_mgl_local_saved_command, i7word_t i7_mgl_local_text_of_command);
i7word_t i7_try(i7process_t *proc, i7word_t action_id, i7word_t n, i7word_t s) {
	return fn_i7_mgl_TryAction(proc, 0, 0, action_id, n, s, 0, 0, 0, 0, 0);
}
#endif
void i7_print_dword(i7process_t *proc, i7word_t at) {
	for (i7byte_t i=1; i<=9; i++) {
		i7byte_t c = i7_read_byte(proc, at+i);
		if (c == 0) break;
		i7_print_char(proc, c);
	}
}

char *dqs[];
char *i7_text_of_string(i7word_t str) {
	return dqs[str - I7VAL_STRINGS_BASE];
}
#define I7_MAX_STREAMS 128

i7_stream i7_memory_streams[I7_MAX_STREAMS];

i7word_t fn_i7_mgl_TEXT_TY_CharacterLength(i7process_t *proc, i7word_t i7_mgl_local_txt, i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dsize, i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp, i7word_t i7_mgl_local_r);
i7word_t fn_i7_mgl_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from, i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect, i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes, i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags, i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
void i7_style(i7process_t *proc, i7word_t what_v) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	S->style[0] = 0;
	switch (what_v) {
		case 0: break;
		case 1: sprintf(S->style, "bold"); break;
		case 2: sprintf(S->style, "italic"); break;
		case 3: sprintf(S->style, "reverse"); break;
		default: {
			int L = fn_i7_mgl_TEXT_TY_CharacterLength(proc, what_v, 0, 0, 0, 0, 0, 0);
			if (L > 127) L = 127;
			for (int i=0; i<L; i++) S->style[i] = fn_i7_mgl_BlkValueRead(proc, what_v, i, 0, 0, 0, 0, 0, 0, 0);
			S->style[L] = 0;
		}
	}
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (strlen(S->style) > 0) sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}

void i7_font(i7process_t *proc, int what) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	S->fixed_pitch = what;
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (strlen(S->style) > 0) sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}

i7_fileref filerefs[128 + 32];
int i7_no_filerefs = 0;

i7word_t i7_do_glk_fileref_create_by_name(i7process_t *proc, i7word_t usage, i7word_t name, i7word_t rock) {
	if (i7_no_filerefs >= 128) {
		fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	}
	int id = i7_no_filerefs++;
	filerefs[id].usage = usage;
	filerefs[id].name = name;
	filerefs[id].rock = rock;
	filerefs[id].handle = NULL;
	for (int i=0; i<128; i++) {
		i7byte_t c = i7_read_byte(proc, name+1+i);
		filerefs[id].leafname[i] = c;
		if (c == 0) break;
	}
	filerefs[id].leafname[127] = 0;
	sprintf(filerefs[id].leafname + strlen(filerefs[id].leafname), ".glkdata");
	return id;
}

int i7_fseek(i7process_t *proc, int id, int pos, int origin) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	return fseek(filerefs[id].handle, pos, origin);
}

int i7_ftell(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	int t = ftell(filerefs[id].handle);
	return t;
}

int i7_fopen(i7process_t *proc, int id, int mode) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle) { fprintf(stderr, "File already open\n"); i7_fatal_exit(proc); }
	char *c_mode = "r";
	switch (mode) {
		case filemode_Write: c_mode = "w"; break;
		case filemode_Read: c_mode = "r"; break;
		case filemode_ReadWrite: c_mode = "r+"; break;
		case filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen(filerefs[id].leafname, c_mode);
	if (h == NULL) return 0;
	filerefs[id].handle = h;
	if (mode == filemode_WriteAppend) i7_fseek(proc, id, 0, SEEK_END);
	return 1;
}

void i7_fclose(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	fclose(filerefs[id].handle);
	filerefs[id].handle = NULL;
}


i7word_t i7_do_glk_fileref_does_file_exist(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle) return 1;
	if (i7_fopen(proc, id, filemode_Read)) {
		i7_fclose(proc, id); return 1;
	}
	return 0;
}

void i7_fputc(i7process_t *proc, int c, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	fputc(c, filerefs[id].handle);
}

int i7_fgetc(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	int c = fgetc(filerefs[id].handle);
	return c;
}

i7word_t i7_stdout_id = 0, i7_stderr_id = 1;

i7word_t i7_do_glk_stream_get_current(i7process_t *proc) {
	return proc->state.i7_str_id;
}

void i7_do_glk_stream_set_current(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	proc->state.i7_str_id = id;
}

i7_stream i7_new_stream(i7process_t *proc, FILE *F, int win_id) {
	i7_stream S;
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
void i7_initialise_streams(i7process_t *proc) {
	for (int i=0; i<I7_MAX_STREAMS; i++) i7_memory_streams[i] = i7_new_stream(proc, NULL, 0);
	i7_memory_streams[i7_stdout_id] = i7_new_stream(proc, stdout, 0);
	i7_memory_streams[i7_stdout_id].active = 1;
	i7_memory_streams[i7_stdout_id].encode_UTF8 = 1;
	i7_memory_streams[i7_stderr_id] = i7_new_stream(proc, stderr, 0);
	i7_memory_streams[i7_stderr_id].active = 1;
	i7_memory_streams[i7_stderr_id].encode_UTF8 = 1;
	i7_do_glk_stream_set_current(proc, i7_stdout_id);
}

i7word_t i7_open_stream(i7process_t *proc, FILE *F, int win_id) {
	for (int i=0; i<I7_MAX_STREAMS; i++)
		if (i7_memory_streams[i].active == 0) {
			i7_memory_streams[i] = i7_new_stream(proc, F, win_id);
			i7_memory_streams[i].active = 1;
			i7_memory_streams[i].previous_id = proc->state.i7_str_id;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	return 0;
}

i7word_t i7_do_glk_stream_open_memory(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(proc); }
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 1;
	proc->state.i7_str_id = id;
	return id;
}

i7word_t i7_do_glk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(proc); }
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 4;
	proc->state.i7_str_id = id;
	return id;
}

i7word_t i7_do_glk_stream_open_file(i7process_t *proc, i7word_t fileref, i7word_t usage, i7word_t rock) {
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].to_file_id = fileref;
	if (i7_fopen(proc, fileref, usage) == 0) return 0;
	return id;
}

void i7_do_glk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos, i7word_t seekmode) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case seekmode_Start: origin = SEEK_SET; break;
			case seekmode_Current: origin = SEEK_CUR; break;
			case seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit(proc);
		}
		i7_fseek(proc, S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n"); i7_fatal_exit(proc);
	}
}

i7word_t i7_do_glk_stream_get_position(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7word_t) i7_ftell(proc, S->to_file_id);
	}
	return (i7word_t) S->memory_used;
}

void i7_do_glk_stream_close(i7process_t *proc, i7word_t id, i7word_t result) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(proc); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->active == 0) { fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(proc); }
	if (proc->state.i7_str_id == id) proc->state.i7_str_id = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(proc, S->write_here_on_closure, i, S->to_memory[i], i7_lvalue_SET);
				else
					i7_write_word(proc, S->write_here_on_closure, i, 0, i7_lvalue_SET);
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
		i7_write_word(proc, result, 0, S->chars_read, i7_lvalue_SET);
		i7_write_word(proc, result, 1, S->memory_used, i7_lvalue_SET);
	}
	if (S->to_file_id >= 0) i7_fclose(proc, S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

i7_winref winrefs[128];
int i7_no_winrefs = 1;

i7word_t i7_do_glk_window_open(i7process_t *proc, i7word_t split, i7word_t method, i7word_t size, i7word_t wintype, i7word_t rock) {
	if (i7_no_winrefs >= 128) {
		fprintf(stderr, "Out of windows\n"); i7_fatal_exit(proc);
	}
	int id = i7_no_winrefs++;
	winrefs[id].type = wintype;
	winrefs[id].stream_id = i7_open_stream(proc, stdout, id);
	winrefs[id].rock = rock;
	return id;
}

i7word_t i7_stream_of_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= i7_no_winrefs)) { fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc); }
	return winrefs[id].stream_id;
}

i7word_t i7_rock_of_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= i7_no_winrefs)) { fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc); }
	return winrefs[id].rock;
}

void i7_to_receiver(i7process_t *proc, i7word_t rock, wchar_t c) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	if (proc->receiver == NULL) fputc(c, stdout);
	(proc->receiver)(rock, c, S->composite_style);
}

void i7_do_glk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file) {
		int win_id = S->owned_by_window_id;
		int rock = -1;
		if (win_id >= 1) rock = i7_rock_of_window(proc, win_id);
		unsigned int c = (unsigned int) x;
		if (proc->use_UTF8) {
			if (c >= 0x800) {
				i7_to_receiver(proc, rock, 0xE0 + (c >> 12));
				i7_to_receiver(proc, rock, 0x80 + ((c >> 6) & 0x3f));
				i7_to_receiver(proc, rock, 0x80 + (c & 0x3f));
			} else if (c >= 0x80) {
				i7_to_receiver(proc, rock, 0xC0 + (c >> 6));
				i7_to_receiver(proc, rock, 0x80 + (c & 0x3f));
			} else i7_to_receiver(proc, rock, (int) c);
		} else {
			i7_to_receiver(proc, rock, (int) c);
		}
	} else if (S->to_file_id >= 0) {
		i7_fputc(proc, (int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) { fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc); }
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

i7word_t i7_do_glk_get_char_stream(i7process_t *proc, i7word_t stream_id) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_fgetc(proc, S->to_file_id);
	}
	return 0;
}

void i7_print_char(i7process_t *proc, i7word_t x) {
	if (x == 13) x = 10;
	i7_do_glk_put_char_stream(proc, proc->state.i7_str_id, x);
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
i7_glk_event i7_events_ring_buffer[32];
int i7_rb_back = 0, i7_rb_front = 0;

i7_glk_event *i7_next_event(i7process_t *proc) {
	if (i7_rb_front == i7_rb_back) return NULL;
	i7_glk_event *e = &(i7_events_ring_buffer[i7_rb_back]);
	i7_rb_back++; if (i7_rb_back == 32) i7_rb_back = 0;
	return e;
}

void i7_make_event(i7process_t *proc, i7_glk_event e) {
	i7_events_ring_buffer[i7_rb_front] = e;
	i7_rb_front++; if (i7_rb_front == 32) i7_rb_front = 0;
}

i7word_t i7_do_glk_select(i7process_t *proc, i7word_t structure) {
	i7_glk_event *e = i7_next_event(proc);
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
			i7_write_word(proc, structure, 0, e->type, i7_lvalue_SET);
			i7_write_word(proc, structure, 1, e->win_id, i7_lvalue_SET);
			i7_write_word(proc, structure, 2, e->val1, i7_lvalue_SET);
			i7_write_word(proc, structure, 3, e->val2, i7_lvalue_SET);
		}
	}
	return 0;
}

int i7_no_lr = 0;
i7word_t i7_do_glk_request_line_event(i7process_t *proc, i7word_t window_id, i7word_t buffer, i7word_t max_len, i7word_t init_len) {
	i7_glk_event e;
	e.type = evtype_LineInput;
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
	if (pos < max_len) i7_write_byte(proc, buffer + pos, 0); else i7_write_byte(proc, buffer + max_len-1, 0);
	e.val1 = pos;
	i7_make_event(proc, e);
	if (i7_no_lr++ == 1000) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n"); exit(0);
	}
	return 0;
}


void glulx_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc, i7word_t *z) {
	i7_debug_stack("glulx_glk");
	i7word_t args[5] = { 0, 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7word_t v = i7_pull(proc);
		if (argc < 5) args[argc++] = v;
		varargc--;
	}

	int rv = 0;
	switch (glk_api_selector) {
		case i7_glk_gestalt:
			rv = 1; break;
		case i7_glk_window_iterate:
			rv = 0; break;
		case i7_glk_window_open:
			rv = i7_do_glk_window_open(proc, args[0], args[1], args[2], args[3], args[4]); break;
		case i7_glk_set_window:
			i7_do_glk_stream_set_current(proc, i7_stream_of_window(proc, args[0])); break;
		case i7_glk_stream_iterate:
			rv = 0; break;
		case i7_glk_fileref_iterate:
			rv = 0; break;
		case i7_glk_stylehint_set:
			rv = 0; break;
		case i7_glk_schannel_iterate:
			rv = 0; break;
		case i7_glk_schannel_create:
			rv = 0; break;
		case i7_glk_set_style:
			rv = 0; break;
		case i7_glk_window_move_cursor:
			rv = 0; break;
		case i7_glk_stream_get_position:
			rv = i7_do_glk_stream_get_position(proc, args[0]); break;
		case i7_glk_window_get_size:
			if (args[0]) i7_write_word(proc, args[0], 0, 80, i7_lvalue_SET);
			if (args[1]) i7_write_word(proc, args[1], 0, 8, i7_lvalue_SET);
			rv = 0; break;
		case i7_glk_request_line_event:
			rv = i7_do_glk_request_line_event(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_select:
			rv = i7_do_glk_select(proc, args[0]); break;
		case i7_glk_stream_close:
			i7_do_glk_stream_close(proc, args[0], args[1]); break;
		case i7_glk_stream_set_current:
			i7_do_glk_stream_set_current(proc, args[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_do_glk_stream_get_current(proc); break;
		case i7_glk_stream_open_memory:
			rv = i7_do_glk_stream_open_memory(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_do_glk_stream_open_memory_uni(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_fileref_create_by_name:
			rv = i7_do_glk_fileref_create_by_name(proc, args[0], args[1], args[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_do_glk_fileref_does_file_exist(proc, args[0]); break;
		case i7_glk_stream_open_file:
			rv = i7_do_glk_stream_open_file(proc, args[0], args[1], args[2]); break;
		case i7_glk_fileref_destroy:
			rv = 0; break;
		case i7_glk_char_to_lower:
			rv = args[0];
			if (((rv >= 0x41) && (rv <= 0x5A)) ||
				((rv >= 0xC0) && (rv <= 0xD6)) ||
				((rv >= 0xD8) && (rv <= 0xDE))) rv += 32;
			break;
		case i7_glk_char_to_upper:
			rv = args[0];
			if (((rv >= 0x61) && (rv <= 0x7A)) ||
				((rv >= 0xE0) && (rv <= 0xF6)) ||
				((rv >= 0xF8) && (rv <= 0xFE))) rv -= 32;
			break;
		case i7_glk_stream_set_position:
			i7_do_glk_stream_set_position(proc, args[0], args[1], args[2]); break;
		case i7_glk_put_char_stream:
			i7_do_glk_put_char_stream(proc, args[0], args[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_do_glk_get_char_stream(proc, args[0]); break;
		default:
			printf("Unimplemented: glulx_glk %d.\n", glk_api_selector); i7_fatal_exit(proc);
			break;
	}
	if (z) *z = rv;
}

void i7_print_name(i7process_t *proc, i7word_t x) {
	fn_i7_mgl_PrintShortName(proc, x, 0);
}

void i7_print_object(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void i7_print_box(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit(proc);
}

i7word_t fn_i7_mgl_pending_boxed_quotation(i7process_t *proc) {
	return 0;
}
#endif
