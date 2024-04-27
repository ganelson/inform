[CUtilities::] C Utility Functions.

Rounding out the C library with a few functions intended for external code to use.

@ We will frequently need to reinterpret |i7word_t| values as |i7float_t|,
or vice versa. The following functions must be perfect inverses of each other.

= (text to inform7_clib.h)
i7word_t i7_encode_float(i7float_t val);
i7float_t i7_decode_float(i7word_t val);
=

= (text to inform7_clib.c)
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
=

@ These two functions allow external C code to read to, or write from, an
Inform 7 variable inside a currently running process.

= (text to inform7_clib.h)
i7word_t i7_read_variable(i7process_t *proc, i7word_t var_id);
void i7_write_variable(i7process_t *proc, i7word_t var_id, i7word_t val);
=

= (text to inform7_clib.c)
i7word_t i7_read_variable(i7process_t *proc, i7word_t var_id) {
	return proc->state.variables[var_id];
}
void i7_write_variable(i7process_t *proc, i7word_t var_id, i7word_t val) {
	proc->state.variables[var_id] = val;
}
=

@ Text values extracted from such variables would be difficult to interpret
from the outside because of the complex way in which text is stored within an
Inform 7 process, so the following functions allow text inside the process
to be converted to or from null-terminated C strings.

= (text to inform7_clib.h)
char *i7_read_string(i7process_t *proc, i7word_t S);
void i7_write_string(i7process_t *proc, i7word_t S, char *A);
=

= (text to inform7_clib.c)
i7word_t i7_fn_TEXT_TY_Transmute(i7process_t *proc, i7word_t i7_mgl_local_txt);
i7word_t i7_fn_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect);
i7word_t i7_fn_BlkValueWrite(i7process_t *proc, i7word_t i7_mgl_local_to,
	i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_val,
	i7word_t i7_mgl_local_do_not_indirect);
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
		A[i] = i7_fn_BlkValueRead(proc, S, i, 0);
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
	i7_fn_BlkValueWrite(proc, S, 0, 0, 0);
	if (A) {
		int L = strlen(A);
		for (int i=0; i<L; i++)
			i7_fn_BlkValueWrite(proc, S, i, A[i], 0);
	}
	#endif
}
=

@ And similarly for list values, which we convert to and from C arrays.

= (text to inform7_clib.h)
i7word_t *i7_read_list(i7process_t *proc, i7word_t S, int *N);
void i7_write_list(i7process_t *proc, i7word_t S, i7word_t *A, int L);
=

= (text to inform7_clib.c)
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
=

@ Lastly, this function allows an action to be tried -- something which is only
meaningful in an Inform project which uses WorldModelKit: it will fail in a
Basic Inform only project.

= (text to inform7_clib.h)
i7word_t i7_try(i7process_t *proc, i7word_t action_id, i7word_t n, i7word_t s);
=

= (text to inform7_clib.c)
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
=

@ Because the C library file and its header are both wrapped inside conditional
compilations to guard against errors if they are included more than once, those
conditionals both need to be ended. So this is the bottom of both files: finis.

= (text to inform7_clib.h)
#endif
=

= (text to inform7_clib.c)
#endif
=
