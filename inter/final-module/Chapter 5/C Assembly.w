[CAssembly::] C Assembly.

The problem of assembly language.

@

=
void CAssembly::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, INVOKE_OPCODE_MTID, CAssembly::assembly);
}

void CAssembly::initialise_data(code_generation *gen) {
}

void CAssembly::begin(code_generation *gen) {
	CAssembly::initialise_data(gen);
}

void CAssembly::end(code_generation *gen) {
}


@

= (text to inform7_clib.h)
void i7_debug_stack(char *N);
i7word_t i7_pull(i7process_t *proc);
void i7_push(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
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
=

@

=
void CAssembly::assembly(code_generator *cgt, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense, int void_context) {
	text_stream *OUT = CodeGen::current(gen);

	int vararg_operands_from = 0, vararg_operands_to = 0, hacky_extras = FALSE;
	int store_this_operand[MAX_OPERANDS_IN_INTER_ASSEMBLY];
	for (int i=0; i<16; i++) store_this_operand[i] = FALSE;

	if (Str::eq(opcode, I"@read_gprop")) { store_this_operand[4] = TRUE; hacky_extras = TRUE;
		C_GEN_DATA(objdata.value_property_holders_needed) = TRUE;
	}
	if (Str::eq(opcode, I"@write_gprop")) { hacky_extras = TRUE;
		C_GEN_DATA(objdata.value_property_holders_needed) = TRUE;
	}

	if (Str::eq(opcode, I"@acos")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@add")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@aload")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@aloadb")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@aloads")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@asin")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@atan")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@binarysearch")) store_this_operand[8] = TRUE;
	if (Str::eq(opcode, I"@ceil")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@call")) {
		store_this_operand[3] = TRUE;
		vararg_operands_from = 2; vararg_operands_to = operand_count-1;
	}
	if (Str::eq(opcode, I"@copy")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@cos")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@div")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@exp")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@fadd")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@fdiv")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@floor")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@fmod")) {
		store_this_operand[3] = TRUE;
		store_this_operand[4] = TRUE;
	}
	if (Str::eq(opcode, I"@fmul")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@fsub")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@ftonumn")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@ftonumz")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@gestalt")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@glk")) {
		store_this_operand[3] = TRUE;
		vararg_operands_from = 2; vararg_operands_to = operand_count-1;
	}
	if (Str::eq(opcode, I"@hasundo")) store_this_operand[1] = TRUE;
	if (Str::eq(opcode, I"@log")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@mod")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@mul")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@neg")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@numtof")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@pow")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@random")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@restoreundo")) store_this_operand[1] = TRUE;
	if (Str::eq(opcode, I"@saveundo")) store_this_operand[1] = TRUE;
	if (Str::eq(opcode, I"@shiftl")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@sin")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@sqrt")) store_this_operand[2] = TRUE;
	if (Str::eq(opcode, I"@sub")) store_this_operand[3] = TRUE;
	if (Str::eq(opcode, I"@tan")) store_this_operand[2] = TRUE;

	if (Str::eq(opcode, I"@xfunction")) {
		store_this_operand[3] = TRUE;
		vararg_operands_from = 2; vararg_operands_to = operand_count-1;
	}

	int pushed_result = FALSE;
	int num = 1;
	if (Str::eq(opcode, I"@return")) {
		WRITE("return (");
	} else {
		if (label_sense != NOT_APPLICABLE) WRITE("if (");
		CNamespace::mangle_opcode(cgt, OUT, opcode);
		WRITE("(proc");
		num = 0;
	}

	for (int opc = 1; opc <= operand_count; opc++) {
		if (opc > num) WRITE(", ");
		TEMPORARY_TEXT(write_to)
		CodeGen::select_temporary(gen, write_to);
		Vanilla::node(gen, operands[opc-1]);
		CodeGen::deselect_temporary(gen);
		if (store_this_operand[opc]) {
			if (Str::eq(write_to, I"i7_mgl_sp")) { WRITE("&(proc->state.tmp)", write_to); pushed_result = TRUE; }
			else if (Str::eq(write_to, I"0")) WRITE("NULL");
			else WRITE("&%S", write_to);
		} else {
			if (Str::eq(write_to, I"i7_mgl_sp")) { WRITE("i7_pull(proc)"); }
			else WRITE("%S", write_to);
		}
		DISCARD_TEXT(write_to)
	}
	if (hacky_extras) WRITE(", i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE");
	WRITE(")");
	if (label_sense != NOT_APPLICABLE) {
		if (label_sense == FALSE) WRITE(" == FALSE");
		WRITE(") goto ");
		if (label == NULL) internal_error("no branch label");
		Vanilla::node(gen, label);
	}
	if (pushed_result) WRITE("; i7_push(proc, proc->state.tmp)");

	if (void_context) WRITE(";\n");
}

@

= (text to inform7_clib.h)
void glulx_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p, i7word_t *val,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE);
int i7_provides_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE);
void glulx_read_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p, i7word_t *val,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE);
void glulx_write_gprop(i7process_t *proc, i7word_t K, i7word_t obj, i7word_t p, i7word_t val, i7word_t form,
	i7word_t i7_mgl_OBJECT_TY, i7word_t i7_mgl_value_ranges, i7word_t i7_mgl_value_property_holders, i7word_t i7_mgl_A_door_to, i7word_t i7_mgl_COL_HSIZE);
=

= (text to inform7_clib.c)
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
=

@

= (text to inform7_clib.h)
void glulx_accelfunc(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_accelparam(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_copy(i7process_t *proc, i7word_t x, i7word_t *y);
void glulx_gestalt(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
int glulx_jeq(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_nop(i7process_t *proc);
int glulx_jleu(i7process_t *proc, i7word_t x, i7word_t y);
int glulx_jnz(i7process_t *proc, i7word_t x);
int glulx_jz(i7process_t *proc, i7word_t x);
void glulx_quit(i7process_t *proc);
void glulx_setiosys(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_streamchar(i7process_t *proc, i7word_t x);
void glulx_streamnum(i7process_t *proc, i7word_t x);
void glulx_streamstr(i7process_t *proc, i7word_t x);
void glulx_streamunichar(i7process_t *proc, i7word_t x);
void glulx_ushiftr(i7process_t *proc, i7word_t x, i7word_t y, i7word_t z);
void glulx_aload(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void glulx_aloadb(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
#define serop_KeyIndirect (0x01)
#define serop_ZeroKeyTerminates (0x02)
#define serop_ReturnIndex (0x04)
void glulx_binarysearch(i7process_t *proc, i7word_t key, i7word_t keysize, i7word_t start, i7word_t structsize,
	i7word_t numstructs, i7word_t keyoffset, i7word_t options, i7word_t *s1);
void glulx_shiftl(i7process_t *proc, i7word_t x, i7word_t y, i7word_t *z);
void glulx_restoreundo(i7process_t *proc, i7word_t *x);
void glulx_saveundo(i7process_t *proc, i7word_t *x);
void glulx_restart(i7process_t *proc);
void glulx_restore(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_save(i7process_t *proc, i7word_t x, i7word_t y);
void glulx_verify(i7process_t *proc, i7word_t x);
void glulx_hasundo(i7process_t *proc, i7word_t *x);
void glulx_discardundo(i7process_t *proc);
=

= (text to inform7_clib.c)
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
	unsigned_i7word_t ux, uy;
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
=
