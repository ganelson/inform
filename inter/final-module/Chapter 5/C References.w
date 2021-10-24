[CReferences::] C References.

How changes to storage objects are translated into C.

@ References identify storage objects which are being written to or otherwise
modified, rather than having their current contents read.

There are seven possible ways to modify something identified by a reference,
and we need constants to identify these ways in the code we generate:

= (text to inform7_clib.h)
#define i7_lvalue_SET 1
#define i7_lvalue_PREDEC 2
#define i7_lvalue_POSTDEC 3
#define i7_lvalue_PREINC 4
#define i7_lvalue_POSTINC 5
#define i7_lvalue_SETBIT 6
#define i7_lvalue_CLEARBIT 7
=

@ Those seven ways correspond to seven Inter primitives, with the following
signatures:
= (text)
primitive !store         ref val -> val
primitive !preincrement  ref -> val
primitive !postincrement ref -> val
primitive !predecrement  ref -> val
primitive !postdecrement ref -> val
primitive !setbit        ref val -> void
primitive !clearbit      ref val -> void
=
Since C functions can have their return values freely ignored, we will in fact
implement |!setbit| and |!clearbit| as if they too had the signature
|ref val -> val|.

For all these primitives, then, the first operand A1 is a |ref|, and the following
function should be used to generate from it:

=
void CReferences::A1_as_ref(code_generation *gen, inter_tree_node *P) {
	C_GEN_DATA(memdata.next_node_is_a_ref) = TRUE;
	Vanilla::node(gen, InterTree::first_child(P));
	C_GEN_DATA(memdata.next_node_is_a_ref) = FALSE;
}

@ That sets a temporary mode which is immediately detected and cleared by
the generator for whatever A1 actually is. That generator is expected to call
this function to detect whether it's a ref. In this mode, A1 is compiled not
to a valid C expression to evaluate the contents of A1, but instead to a
function call which will modify A1, and which is missing one or two final
arguments.

Note that the mode is auto-exited at once. This is all a bit clumsy, but is
correct.

=
int CReferences::am_I_a_ref(code_generation *gen) {
	int answer = C_GEN_DATA(memdata.next_node_is_a_ref);
	C_GEN_DATA(memdata.next_node_is_a_ref) = FALSE;
	return answer;
}

@ So, then, here goes:

=
int CReferences::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	text_stream *store_form = NULL;
	switch (bip) {
		case STORE_BIP:			store_form = I"i7_lvalue_SET"; break;
		case PREINCREMENT_BIP:	store_form = I"i7_lvalue_PREINC"; break;
		case POSTINCREMENT_BIP:	store_form = I"i7_lvalue_POSTINC"; break;
		case PREDECREMENT_BIP:	store_form = I"i7_lvalue_PREDEC"; break;
		case POSTDECREMENT_BIP:	store_form = I"i7_lvalue_POSTDEC"; break;
		case SETBIT_BIP:		store_form = I"i7_lvalue_SETBIT"; break;
		case CLEARBIT_BIP:		store_form = I"i7_lvalue_CLEARBIT"; break;
		default: return NOT_APPLICABLE;
	}
	if (store_form) @<This does indeed modify a value by reference@>;
	return FALSE;
}

@ Some storage objects, like variables, can be generated to C code which works
in either an lvalue or rvalue context. For example, the Inter variable |frog|
generates just as the C variable |i7_mgl_frog|.[1] It's then fine to generate
code like either |10 + i7_mgl_frog|, where it is used in a |val| context, or
like |i7_mgl_frog++|, where it is used in a |ref| context.

But other storage objects are not so lucky, and those need to generate to
different function calls, one used in a |ref| setting, one used in a |val|.
That's what is done by the "A1 as ref" mode set up above.

[1] In real life, do not mangle frogs. See C. S. Lewis, "Perelandra", 1943.

@<This does indeed modify a value by reference@> =
	inter_tree_node *ref = InterTree::first_child(P);
	if ((CMemoryModel::handle_store_by_ref(gen, ref)) ||
		(CObjectModel::handle_store_by_ref(gen, ref))) {
		@<Handle the ref using the incomplete-function mode@>;
	} else {
		@<Handle the ref with C code working either as lvalue or rvalue@>;
	}

@<Handle the ref using the incomplete-function mode@> =
	WRITE("("); CReferences::A1_as_ref(gen, P);
	if (bip == STORE_BIP) { VNODE_2C; } else { WRITE("0"); }
	WRITE(", %S", store_form);
	if (Inter::Reference::node_is_ref_to(gen->from, ref, PROPERTYVALUE_BIP))
		WRITE(", i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE");
	WRITE("))");

@<Handle the ref with C code working either as lvalue or rvalue@> =
	switch (bip) {
		case PREINCREMENT_BIP:	WRITE("++("); VNODE_1C; WRITE(")"); break;
		case POSTINCREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")++"); break;
		case PREDECREMENT_BIP:	WRITE("--("); VNODE_1C; WRITE(")"); break;
		case POSTDECREMENT_BIP:	WRITE("("); VNODE_1C; WRITE(")--"); break;
		case STORE_BIP:			WRITE("("); VNODE_1C; WRITE(" = "); VNODE_2C; WRITE(")"); break;
		case SETBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" | "); VNODE_2C; break;
		case CLEARBIT_BIP:		VNODE_1C; WRITE(" = "); VNODE_1C; WRITE(" &~ ("); VNODE_2C; WRITE(")"); break;
	}

@

= (text to inform7_clib.h)
char *i7_read_string(i7process_t *proc, i7word_t S);
void i7_write_string(i7process_t *proc, i7word_t S, char *A);
i7word_t *i7_read_list(i7process_t *proc, i7word_t S, int *N);
void i7_write_list(i7process_t *proc, i7word_t S, i7word_t *A, int L);
=

= (text to inform7_clib.c)
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
=
