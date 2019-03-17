/* operand.c: Glulxe code for instruction operands, reading and writing.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"
#include "opcodes.h"

/* ### We could save a few cycles per operand by generating a function for
   each operandlist type. */

/* fast_operandlist[]:
   This is a handy array in which to look up operandlists quickly.
   It stores the operandlists for the first 128 opcodes, which are
   the ones used most frequently.
*/
operandlist_t *fast_operandlist[0x80];

/* The actual immutable structures which lookup_operandlist()
   returns. */
static operandlist_t list_none = { 0, 4, NULL };

static int array_S[1] = { modeform_Store };
static operandlist_t list_S = { 1, 4, array_S };
static int array_LS[2] = { modeform_Load, modeform_Store };
static operandlist_t list_LS = { 2, 4, array_LS };
static int array_LLS[3] = { modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLS = { 3, 4, array_LLS };
static int array_LLLS[4] = { modeform_Load, modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLLS = { 4, 4, array_LLLS };
static int array_LLLLS[5] = { modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLLLS = { 5, 4, array_LLLLS };
/* static int array_LLLLLS[6] = { modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLLLLS = { 6, 4, array_LLLLLS }; */ /* not currently used */
static int array_LLLLLLS[7] = { modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLLLLLS = { 7, 4, array_LLLLLLS };
static int array_LLLLLLLS[8] = { modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Load, modeform_Store };
static operandlist_t list_LLLLLLLS = { 8, 4, array_LLLLLLLS };

static int array_L[1] = { modeform_Load };
static operandlist_t list_L = { 1, 4, array_L };
static int array_LL[2] = { modeform_Load, modeform_Load };
static operandlist_t list_LL = { 2, 4, array_LL };
static int array_LLL[3] = { modeform_Load, modeform_Load, modeform_Load };
static operandlist_t list_LLL = { 3, 4, array_LLL };
static operandlist_t list_2LS = { 2, 2, array_LS };
static operandlist_t list_1LS = { 2, 1, array_LS };
static int array_LLLL[4] = { modeform_Load, modeform_Load, modeform_Load, modeform_Load };
static operandlist_t list_LLLL = { 4, 4, array_LLLL };
static int array_SL[2] = { modeform_Store, modeform_Load };
static operandlist_t list_SL = { 2, 4, array_SL };
static int array_SS[2] = { modeform_Store, modeform_Store };
static operandlist_t list_SS = { 2, 4, array_SS };
static int array_LLSS[4] = { modeform_Load, modeform_Load, modeform_Store, modeform_Store };
static operandlist_t list_LLSS = { 4, 4, array_LLSS };

/* init_operands():
   Set up the fast-lookup array of operandlists. This is called just
   once, when the terp starts up. 
*/
void init_operands()
{
  int ix;
  for (ix=0; ix<0x80; ix++)
    fast_operandlist[ix] = lookup_operandlist(ix);
}

/* lookup_operandlist():
   Return the operandlist for a given opcode. For opcodes in the range
   00..7F, it's faster to use the array fast_operandlist[]. 
*/
operandlist_t *lookup_operandlist(glui32 opcode)
{
  switch (opcode) {
  case op_nop: 
    return &list_none;

  case op_add:
  case op_sub:
  case op_mul:
  case op_div:
  case op_mod:
  case op_bitand:
  case op_bitor:
  case op_bitxor:
  case op_shiftl:
  case op_sshiftr:
  case op_ushiftr:
    return &list_LLS;

  case op_neg:
  case op_bitnot:
    return &list_LS;

  case op_jump:
  case op_jumpabs:
    return &list_L;
  case op_jz:
  case op_jnz:
    return &list_LL;
  case op_jeq:
  case op_jne:
  case op_jlt:
  case op_jge:
  case op_jgt:
  case op_jle:
  case op_jltu:
  case op_jgeu:
  case op_jgtu:
  case op_jleu:
    return &list_LLL;

  case op_call:
    return &list_LLS;
  case op_return:
    return &list_L;
  case op_catch:
    return &list_SL;
  case op_throw:
    return &list_LL;
  case op_tailcall:
    return &list_LL;

  case op_sexb:
  case op_sexs:
    return &list_LS;

  case op_copy:
    return &list_LS;
  case op_copys:
    return &list_2LS;
  case op_copyb:
    return &list_1LS;
  case op_aload:
  case op_aloads:
  case op_aloadb:
  case op_aloadbit:
    return &list_LLS;
  case op_astore:
  case op_astores:
  case op_astoreb:
  case op_astorebit:
    return &list_LLL;

  case op_stkcount:
    return &list_S;
  case op_stkpeek:
    return &list_LS;
  case op_stkswap: 
    return &list_none;
  case op_stkroll:
    return &list_LL;
  case op_stkcopy:
    return &list_L;

  case op_streamchar:
  case op_streamunichar:
  case op_streamnum:
  case op_streamstr:
    return &list_L;
  case op_getstringtbl:
    return &list_S;
  case op_setstringtbl:
    return &list_L;
  case op_getiosys:
    return &list_SS;
  case op_setiosys:
    return &list_LL;

  case op_random:
    return &list_LS;
  case op_setrandom:
    return &list_L;

  case op_verify:
    return &list_S;
  case op_restart:
    return &list_none;
  case op_save:
  case op_restore:
    return &list_LS;
  case op_saveundo:
  case op_restoreundo:
    return &list_S;
  case op_protect:
    return &list_LL;

  case op_quit:
    return &list_none;

  case op_gestalt:
    return &list_LLS;

  case op_debugtrap: 
    return &list_L;

  case op_getmemsize:
    return &list_S;
  case op_setmemsize:
    return &list_LS;

  case op_linearsearch:
    return &list_LLLLLLLS;
  case op_binarysearch:
    return &list_LLLLLLLS;
  case op_linkedsearch:
    return &list_LLLLLLS;

  case op_glk:
    return &list_LLS;

  case op_callf:
    return &list_LS;
  case op_callfi:
    return &list_LLS;
  case op_callfii:
    return &list_LLLS;
  case op_callfiii:
    return &list_LLLLS;

  case op_mzero:
    return &list_LL;
  case op_mcopy:
    return &list_LLL;
  case op_malloc:
    return &list_LS;
  case op_mfree:
    return &list_L;

  case op_accelfunc:
  case op_accelparam:
    return &list_LL;

#ifdef FLOAT_SUPPORT

  case op_numtof:
  case op_ftonumz:
  case op_ftonumn:
  case op_ceil:
  case op_floor:
  case op_sqrt:
  case op_exp:
  case op_log:
    return &list_LS;
  case op_fadd:
  case op_fsub:
  case op_fmul:
  case op_fdiv:
  case op_pow:
  case op_atan2:
    return &list_LLS;
  case op_fmod:
    return &list_LLSS;
  case op_sin:
  case op_cos:
  case op_tan:
  case op_asin:
  case op_acos:
  case op_atan:
    return &list_LS;
  case op_jfeq:
  case op_jfne:
    return &list_LLLL;
  case op_jflt:
  case op_jfle:
  case op_jfgt:
  case op_jfge:
    return &list_LLL;
  case op_jisnan:
  case op_jisinf:
    return &list_LL;

#endif /* FLOAT_SUPPORT */

#ifdef GLULX_EXTEND_OPERANDS
  GLULX_EXTEND_OPERANDS
#endif /* GLULX_EXTEND_OPERANDS */

  default: 
    return NULL;
  }
}

/* parse_operands():
   Read the list of operands of an instruction, and put the values
   in args. This assumes that the PC is at the beginning of the
   operand mode list (right after an opcode number.) Upon return,
   the PC will be at the beginning of the next instruction.

   This also assumes that args points at an allocated array of 
   MAX_OPERANDS oparg_t structures.
*/
void parse_operands(oparg_t *args, operandlist_t *oplist)
{
  int ix;
  oparg_t *curarg;
  int numops = oplist->num_ops;
  int argsize = oplist->arg_size;
  glui32 modeaddr = pc;
  int modeval;

  pc += (numops+1) / 2;

  for (ix=0, curarg=args; ix<numops; ix++, curarg++) {
    int mode;
    glui32 value;
    glui32 addr;

    curarg->desttype = 0;

    if ((ix & 1) == 0) {
      modeval = Mem1(modeaddr);
      mode = (modeval & 0x0F);
    }
    else {
      mode = ((modeval >> 4) & 0x0F);
      modeaddr++;
    }

    if (oplist->formlist[ix] == modeform_Load) {

      switch (mode) {

      case 8: /* pop off stack */
        if (stackptr < valstackbase+4) {
          fatal_error("Stack underflow in operand.");
        }
        stackptr -= 4;
        value = Stk4(stackptr);
        break;

      case 0: /* constant zero */
        value = 0;
        break;

      case 1: /* one-byte constant */
        /* Sign-extend from 8 bits to 32 */
        value = (glsi32)(signed char)(Mem1(pc));
        pc++;
        break;

      case 2: /* two-byte constant */
        /* Sign-extend the first byte from 8 bits to 32; the subsequent
           byte must not be sign-extended. */
        value = (glsi32)(signed char)(Mem1(pc));
        pc++;
        value = (value << 8) | (glui32)(Mem1(pc));
        pc++;
        break;

      case 3: /* four-byte constant */
        /* Bytes must not be sign-extended. */
        value = Mem4(pc);
        pc += 4;
        break;

      case 15: /* main memory RAM, four-byte address */
        addr = Mem4(pc);
        addr += ramstart;
        pc += 4;
        goto MainMemAddr; 

      case 14: /* main memory RAM, two-byte address */
        addr = (glui32)Mem2(pc);
        addr += ramstart;
        pc += 2;
        goto MainMemAddr; 

      case 13: /* main memory RAM, one-byte address */
        addr = (glui32)(Mem1(pc));
        addr += ramstart;
        pc++;
        goto MainMemAddr; 
        
      case 7: /* main memory, four-byte address */
        addr = Mem4(pc);
        pc += 4;
        goto MainMemAddr;

      case 6: /* main memory, two-byte address */
        addr = (glui32)Mem2(pc);
        pc += 2;
        goto MainMemAddr;

      case 5: /* main memory, one-byte address */
        addr = (glui32)(Mem1(pc));
        pc++;
        /* fall through */

      MainMemAddr:
        /* cases 5, 6, 7, 13, 14, 15 all wind up here. */
        if (argsize == 4) {
          value = Mem4(addr);
        }
        else if (argsize == 2) {
          value = Mem2(addr);
        }
        else {
          value = Mem1(addr);
        }
        break;

      case 11: /* locals, four-byte address */
        addr = Mem4(pc);
        pc += 4;
        goto LocalsAddr;

      case 10: /* locals, two-byte address */
        addr = (glui32)Mem2(pc);
        pc += 2;
        goto LocalsAddr; 

      case 9: /* locals, one-byte address */
        addr = (glui32)(Mem1(pc));
        pc++;
        /* fall through */

      LocalsAddr:
        /* cases 9, 10, 11 all wind up here. It's illegal for addr to not
           be four-byte aligned, but we don't check this explicitly. 
           A "strict mode" interpreter probably should. It's also illegal
           for addr to be less than zero or greater than the size of
           the locals segment. */
        addr += localsbase;
        if (argsize == 4) {
          value = Stk4(addr);
        }
        else if (argsize == 2) {
          value = Stk2(addr);
        }
        else {
          value = Stk1(addr);
        }
        break;

      default:
        value = 0;
        fatal_error("Unknown addressing mode in load operand.");
      }

      curarg->value = value;

    }
    else {  /* modeform_Store */
      switch (mode) {

      case 0: /* discard value */
        curarg->desttype = 0;
        curarg->value = 0;
        break;

      case 8: /* push on stack */
        curarg->desttype = 3;
        curarg->value = 0;
        break;

      case 15: /* main memory RAM, four-byte address */
        addr = Mem4(pc);
        addr += ramstart;
        pc += 4;
        goto WrMainMemAddr; 

      case 14: /* main memory RAM, two-byte address */
        addr = (glui32)Mem2(pc);
        addr += ramstart;
        pc += 2;
        goto WrMainMemAddr; 

      case 13: /* main memory RAM, one-byte address */
        addr = (glui32)(Mem1(pc));
        addr += ramstart;
        pc++;
        goto WrMainMemAddr; 

      case 7: /* main memory, four-byte address */
        addr = Mem4(pc);
        pc += 4;
        goto WrMainMemAddr;

      case 6: /* main memory, two-byte address */
        addr = (glui32)Mem2(pc);
        pc += 2;
        goto WrMainMemAddr;

      case 5: /* main memory, one-byte address */
        addr = (glui32)(Mem1(pc));
        pc++;
        /* fall through */

      WrMainMemAddr:
        /* cases 5, 6, 7 all wind up here. */
        curarg->desttype = 1;
        curarg->value = addr;
        break;

      case 11: /* locals, four-byte address */
        addr = Mem4(pc);
        pc += 4;
        goto WrLocalsAddr;

      case 10: /* locals, two-byte address */
        addr = (glui32)Mem2(pc);
        pc += 2;
        goto WrLocalsAddr; 

      case 9: /* locals, one-byte address */
        addr = (glui32)(Mem1(pc));
        pc++;
        /* fall through */

      WrLocalsAddr:
        /* cases 9, 10, 11 all wind up here. It's illegal for addr to not
           be four-byte aligned, but we don't check this explicitly. 
           A "strict mode" interpreter probably should. It's also illegal
           for addr to be less than zero or greater than the size of
           the locals segment. */
        curarg->desttype = 2;
        /* We don't add localsbase here; the store address for desttype 2
           is relative to the current locals segment, not an absolute
           stack position. */
        curarg->value = addr;
        break;

      case 1:
      case 2:
      case 3:
        fatal_error("Constant addressing mode in store operand.");

      default:
        fatal_error("Unknown addressing mode in store operand.");
      }
    }
  }
}

/* store_operand():
   Store a result value, according to the desttype and destaddress given.
   This is usually used to store the result of an opcode, but it's also
   used by any code that pulls a call-stub off the stack.
*/
void store_operand(glui32 desttype, glui32 destaddr, glui32 storeval)
{
  switch (desttype) {

  case 0: /* do nothing; discard the value. */
    return;

  case 1: /* main memory. */
    MemW4(destaddr, storeval);
    return;

  case 2: /* locals. */
    destaddr += localsbase;
    StkW4(destaddr, storeval);
    return;

  case 3: /* push on stack. */
    if (stackptr+4 > stacksize) {
      fatal_error("Stack overflow in store operand.");
    }
    StkW4(stackptr, storeval);
    stackptr += 4;
    return;

  default:
    fatal_error("Unknown destination type in store operand.");

  }
}

void store_operand_s(glui32 desttype, glui32 destaddr, glui32 storeval)
{
  storeval &= 0xFFFF;

  switch (desttype) {

  case 0: /* do nothing; discard the value. */
    return;

  case 1: /* main memory. */
    MemW2(destaddr, storeval);
    return;

  case 2: /* locals. */
    destaddr += localsbase;
    StkW2(destaddr, storeval);
    return;

  case 3: /* push on stack. A four-byte value is actually pushed. */
    if (stackptr+4 > stacksize) {
      fatal_error("Stack overflow in store operand.");
    }
    StkW4(stackptr, storeval);
    stackptr += 4;
    return;

  default:
    fatal_error("Unknown destination type in store operand.");

  }
}

void store_operand_b(glui32 desttype, glui32 destaddr, glui32 storeval)
{
  storeval &= 0xFF;

  switch (desttype) {

  case 0: /* do nothing; discard the value. */
    return;

  case 1: /* main memory. */
    MemW1(destaddr, storeval);
    return;

  case 2: /* locals. */
    destaddr += localsbase;
    StkW1(destaddr, storeval);
    return;

  case 3: /* push on stack. A four-byte value is actually pushed. */
    if (stackptr+4 > stacksize) {
      fatal_error("Stack overflow in store operand.");
    }
    StkW4(stackptr, storeval);
    stackptr += 4;
    return;

  default:
    fatal_error("Unknown destination type in store operand.");

  }
}
