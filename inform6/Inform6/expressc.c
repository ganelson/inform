/* ------------------------------------------------------------------------- */
/*   "expressc" :  The expression code generator                             */
/*                                                                           */
/*   Part of Inform 6.34                                                     */
/*   copyright (c) Graham Nelson 1993 - 2020                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

int vivc_flag;                      /*  TRUE if the last code-generated
                                        expression produced a "value in void
                                        context" error: used to help the syntax
                                        analyser recover from unknown-keyword
                                        errors, since unknown keywords are
                                        treated as yet-to-be-defined constants
                                        and thus as values in void context  */

/* These data structures are global, because they're too useful to be
   static. */
assembly_operand stack_pointer, temp_var1, temp_var2, temp_var3,
  temp_var4, zero_operand, one_operand, two_operand, three_operand,
  four_operand, valueless_operand;

static void make_operands(void)
{
  if (!glulx_mode) {
    INITAOTV(&stack_pointer, VARIABLE_OT, 0);
    INITAOTV(&temp_var1, VARIABLE_OT, 255);
    INITAOTV(&temp_var2, VARIABLE_OT, 254);
    INITAOTV(&temp_var3, VARIABLE_OT, 253);
    INITAOTV(&temp_var4, VARIABLE_OT, 252);
    INITAOTV(&zero_operand, SHORT_CONSTANT_OT, 0);
    INITAOTV(&one_operand, SHORT_CONSTANT_OT, 1);
    INITAOTV(&two_operand, SHORT_CONSTANT_OT, 2);
    INITAOTV(&three_operand, SHORT_CONSTANT_OT, 3);
    INITAOTV(&four_operand, SHORT_CONSTANT_OT, 4);
    INITAOTV(&valueless_operand, OMITTED_OT, 0);
  }
  else {
    INITAOTV(&stack_pointer, LOCALVAR_OT, 0);
    INITAOTV(&temp_var1, GLOBALVAR_OT, MAX_LOCAL_VARIABLES+0);
    INITAOTV(&temp_var2, GLOBALVAR_OT, MAX_LOCAL_VARIABLES+1);
    INITAOTV(&temp_var3, GLOBALVAR_OT, MAX_LOCAL_VARIABLES+2);
    INITAOTV(&temp_var4, GLOBALVAR_OT, MAX_LOCAL_VARIABLES+3);
    INITAOTV(&zero_operand, ZEROCONSTANT_OT, 0);
    INITAOTV(&one_operand, BYTECONSTANT_OT, 1);
    INITAOTV(&two_operand, BYTECONSTANT_OT, 2);
    INITAOTV(&three_operand, BYTECONSTANT_OT, 3);
    INITAOTV(&four_operand, BYTECONSTANT_OT, 4);
    INITAOTV(&valueless_operand, OMITTED_OT, 0);
  }
}

/* ------------------------------------------------------------------------- */
/*  The table of conditionals. (Only used in Glulx)                          */

#define ZERO_CC (500)
#define EQUAL_CC (502)
#define LT_CC (504)
#define GT_CC (506)
#define HAS_CC (508)
#define IN_CC (510)
#define OFCLASS_CC (512)
#define PROVIDES_CC (514)

#define FIRST_CC (500)
#define LAST_CC (515)

typedef struct condclass_s {
  int32 posform; /* Opcode for the conditional in its positive form. */
  int32 negform; /* Opcode for the conditional in its negated form. */
} condclass;

condclass condclasses[] = {
  { jz_gc, jnz_gc },
  { jeq_gc, jne_gc },
  { jlt_gc, jge_gc },
  { jgt_gc, jle_gc },
  { -1, -1 },
  { -1, -1 },
  { -1, -1 },
  { -1, -1 }
};

/* ------------------------------------------------------------------------- */
/*  The table of operators.

    The ordering in this table is not significant except that it must match
    the #define's in "header.h"                                              */

operator operators[NUM_OPERATORS] =
{
                         /* ------------------------ */
                         /*  Level 0:  ,             */
                         /* ------------------------ */

  { 0, SEP_TT, COMMA_SEP,       IN_U, L_A, 0, -1, -1, 0, 0, "comma" },

                         /* ------------------------ */
                         /*  Level 1:  =             */
                         /* ------------------------ */

  { 1, SEP_TT, SETEQUALS_SEP,   IN_U, R_A, 1, -1, -1, 1, 0,
      "assignment operator '='" },

                         /* ------------------------ */
                         /*  Level 2:  ~~  &&  ||    */
                         /* ------------------------ */

  { 2, SEP_TT, LOGAND_SEP,      IN_U, L_A, 0, -1, -1, 0, LOGOR_OP,
      "logical conjunction '&&'" },
  { 2, SEP_TT, LOGOR_SEP,       IN_U, L_A, 0, -1, -1, 0, LOGAND_OP,
      "logical disjunction '||'" },
  { 2, SEP_TT, LOGNOT_SEP,     PRE_U, R_A, 0, -1, -1, 0, LOGNOT_OP,
      "logical negation '~~'" },

                         /* ------------------------ */
                         /*  Level 3:  ==  ~=        */
                         /*            >  >=  <  <=  */
                         /*            has  hasnt    */
                         /*            in  notin     */
                         /*            provides      */
                         /*            ofclass       */
                         /* ------------------------ */

  { 3,     -1, -1,                -1, 0, 0, 400 + jz_zc, ZERO_CC+0, 0, NONZERO_OP,
      "expression used as condition then negated" },
  { 3,     -1, -1,                -1, 0, 0, 800 + jz_zc, ZERO_CC+1, 0, ZERO_OP,
      "expression used as condition" },
  { 3, SEP_TT, CONDEQUALS_SEP,  IN_U, 0, 0, 400 + je_zc, EQUAL_CC+0, 0, NOTEQUAL_OP,
      "'==' condition" },
  { 3, SEP_TT, NOTEQUAL_SEP,    IN_U, 0, 0, 800 + je_zc, EQUAL_CC+1, 0, CONDEQUALS_OP,
      "'~=' condition" },
  { 3, SEP_TT, GE_SEP,          IN_U, 0, 0, 800 + jl_zc, LT_CC+1, 0, LESS_OP,
      "'>=' condition" },
  { 3, SEP_TT, GREATER_SEP,     IN_U, 0, 0, 400 + jg_zc, GT_CC+0, 0, LE_OP,
      "'>' condition" },
  { 3, SEP_TT, LE_SEP,          IN_U, 0, 0, 800 + jg_zc, GT_CC+1, 0, GREATER_OP,
      "'<=' condition" },
  { 3, SEP_TT, LESS_SEP,        IN_U, 0, 0, 400 + jl_zc, LT_CC+0, 0, GE_OP,
      "'<' condition" },
  { 3, CND_TT, HAS_COND,        IN_U, 0, 0, 400 + test_attr_zc, HAS_CC+0, 0, HASNT_OP,
      "'has' condition" },
  { 3, CND_TT, HASNT_COND,      IN_U, 0, 0, 800 + test_attr_zc, HAS_CC+1, 0, HAS_OP,
      "'hasnt' condition" },
  { 3, CND_TT, IN_COND,         IN_U, 0, 0, 400 + jin_zc, IN_CC+0, 0, NOTIN_OP,
      "'in' condition" },
  { 3, CND_TT, NOTIN_COND,      IN_U, 0, 0, 800 + jin_zc, IN_CC+1, 0, IN_OP,
      "'notin' condition" },
  { 3, CND_TT, OFCLASS_COND,    IN_U, 0, 0, 600, OFCLASS_CC+0, 0, NOTOFCLASS_OP,
      "'ofclass' condition" },
  { 3, CND_TT, PROVIDES_COND,   IN_U, 0, 0, 601, PROVIDES_CC+0, 0, NOTPROVIDES_OP,
      "'provides' condition" },
  { 3,     -1, -1,                -1, 0, 0, 1000, OFCLASS_CC+1, 0, OFCLASS_OP,
      "negated 'ofclass' condition" },
  { 3,     -1, -1,                -1, 0, 0, 1001, PROVIDES_CC+1, 0, PROVIDES_OP,
      "negated 'provides' condition" },

                         /* ------------------------ */
                         /*  Level 4:  or            */
                         /* ------------------------ */

  { 4, CND_TT, OR_COND,         IN_U, L_A, 0, -1, -1, 0, 0, "'or'" },

                         /* ------------------------ */
                         /*  Level 5:  +  binary -   */
                         /* ------------------------ */

  { 5, SEP_TT, PLUS_SEP,        IN_U, L_A, 0, add_zc, add_gc, 0, 0, "'+'" },
  { 5, SEP_TT, MINUS_SEP,       IN_U, L_A, 0, sub_zc, sub_gc, 0, 0, "'-'" },

                         /* ------------------------ */
                         /*  Level 6:  *  /  %       */
                         /*            &  |  ~       */
                         /* ------------------------ */

  { 6, SEP_TT, TIMES_SEP,       IN_U, L_A, 0, mul_zc, mul_gc, 0, 0, "'*'" },
  { 6, SEP_TT, DIVIDE_SEP,      IN_U, L_A, 0, div_zc, div_gc, 0, 0, "'/'" },
  { 6, SEP_TT, REMAINDER_SEP,   IN_U, L_A, 0, mod_zc, mod_gc, 0, 0,
      "remainder after division '%'" },
  { 6, SEP_TT, ARTAND_SEP,      IN_U, L_A, 0, and_zc, bitand_gc, 0, 0,
      "bitwise AND '&'" },
  { 6, SEP_TT, ARTOR_SEP,       IN_U, L_A, 0, or_zc, bitor_gc, 0, 0,
      "bitwise OR '|'" },
  { 6, SEP_TT, ARTNOT_SEP,     PRE_U, R_A, 0, -1, bitnot_gc, 0, 0,
      "bitwise NOT '~'" },

                         /* ------------------------ */
                         /*  Level 7:  ->  -->       */
                         /* ------------------------ */

  { 7, SEP_TT, ARROW_SEP,       IN_U, L_A, 0, -1, -1, 0, 0,
      "byte array operator '->'" },
  { 7, SEP_TT, DARROW_SEP,      IN_U, L_A, 0, -1, -1, 0, 0,
      "word array operator '-->'" },

                         /* ------------------------ */
                         /*  Level 8:  unary -       */
                         /* ------------------------ */

  { 8, SEP_TT, UNARY_MINUS_SEP, PRE_U, R_A, 0, -1, neg_gc, 0, 0,
      "unary minus" },

                         /* ------------------------ */
                         /*  Level 9:  ++  --        */
                         /*  (prefix or postfix)     */
                         /* ------------------------ */

  { 9, SEP_TT, INC_SEP,         PRE_U, R_A, 2, -1, -1, 1, 0,
      "pre-increment operator '++'" },
  { 9, SEP_TT, POST_INC_SEP,   POST_U, R_A, 3, -1, -1, 1, 0,
      "post-increment operator '++'" },
  { 9, SEP_TT, DEC_SEP,         PRE_U, R_A, 4, -1, -1, 1, 0,
      "pre-decrement operator '--'" },
  { 9, SEP_TT, POST_DEC_SEP,   POST_U, R_A, 5, -1, -1, 1, 0,
      "post-decrement operator '--'" },

                         /* ------------------------ */
                         /*  Level 10: .&  .#        */
                         /*            ..&  ..#      */
                         /* ------------------------ */

  {10, SEP_TT, PROPADD_SEP,     IN_U, L_A, 0, -1, -1, 0, 0,
      "property address operator '.&'" },
  {10, SEP_TT, PROPNUM_SEP,     IN_U, L_A, 0, -1, -1, 0, 0,
      "property length operator '.#'" },
  {10, SEP_TT, MPROPADD_SEP,    IN_U, L_A, 0, -1, -1, 0, 0,
      "individual property address operator '..&'" },
  {10, SEP_TT, MPROPNUM_SEP,    IN_U, L_A, 0, -1, -1, 0, 0,
      "individual property length operator '..#'" },

                         /* ------------------------ */
                         /*  Level 11:  function (   */
                         /* ------------------------ */

  {11, SEP_TT, OPENB_SEP,       IN_U, L_A, 0, -1, -1, 1, 0,
      "function call" },

                         /* ------------------------ */
                         /*  Level 12:  .  ..        */
                         /* ------------------------ */

  {12, SEP_TT, MESSAGE_SEP,     IN_U, L_A, 0, -1, -1, 0, 0,
      "individual property selector '..'" },
  {12, SEP_TT, PROPERTY_SEP,    IN_U, L_A, 0, -1, -1, 0, 0,
      "property selector '.'" },

                         /* ------------------------ */
                         /*  Level 13:  ::           */
                         /* ------------------------ */

  {13, SEP_TT, SUPERCLASS_SEP,  IN_U, L_A, 0, -1, -1, 0, 0,
      "superclass operator '::'" },

                         /* ------------------------ */
                         /*  Miscellaneous operators */
                         /*  generated at lvalue     */
                         /*  checking time           */
                         /* ------------------------ */

  { 1,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ->   =   */
      "byte array entry assignment" },
  { 1,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      -->  =   */
      "word array entry assignment" },
  { 1,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ..   =   */
      "individual property assignment" },
  { 1,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      .    =   */
      "common property assignment" },

  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   ++ ->       */
      "byte array entry preincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   ++ -->      */
      "word array entry preincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   ++ ..       */
      "individual property preincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   ++ .        */
      "common property preincrement" },

  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   -- ->       */
      "byte array entry predecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   -- -->      */
      "word array entry predecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   -- ..       */
      "individual property predecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   -- .        */
      "common property predecrement" },

  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ->  ++   */
      "byte array entry postincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      --> ++   */
      "word array entry postincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ..  ++   */
      "individual property postincrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      .   ++   */
      "common property postincrement" },

  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ->  --   */
      "byte array entry postdecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      --> --   */
      "word array entry postdecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      ..  --   */
      "individual property postdecrement" },
  { 9,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*      .   --   */
      "common property postdecrement" },

  {11,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   x.y(args)   */
      "call to common property" },
  {11,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0, /*   x..y(args)  */
      "call to individual property" },

                         /* ------------------------ */
                         /*  And one Glulx-only op   */
                         /*  which just pushes its   */
                         /*  argument on the stack,  */
                         /*  unchanged.              */
                         /* ------------------------ */

  {14,     -1, -1,              -1,   -1,  0, -1, -1, 1, 0,     
      "push on stack" }
};

/* --- Condition annotater ------------------------------------------------- */

static void annotate_for_conditions(int n, int a, int b)
{   int i, opnum = ET[n].operator_number;

    ET[n].label_after = -1;
    ET[n].to_expression = FALSE;
    ET[n].true_label = a;
    ET[n].false_label = b;

    if (ET[n].down == -1) return;

    if ((operators[opnum].precedence == 2)
        || (operators[opnum].precedence == 3))
    {   if ((a == -1) && (b == -1))
        {   if (opnum == LOGAND_OP)
            {   b = next_label++;
                ET[n].false_label = b;
                ET[n].to_expression = TRUE;
            }
            else
            {   a = next_label++;
                ET[n].true_label = a;
                ET[n].to_expression = TRUE;
            }
        }
    }

    switch(opnum)
    {   case LOGAND_OP:
            if (b == -1)
            {   b = next_label++;
                ET[n].false_label = b;
                ET[n].label_after = b;
            }
            annotate_for_conditions(ET[n].down, -1, b);
            if (b == ET[n].label_after)
                 annotate_for_conditions(ET[ET[n].down].right, a, -1);
            else annotate_for_conditions(ET[ET[n].down].right, a, b);
            return;
        case LOGOR_OP:
            if (a == -1)
            {   a = next_label++;
                ET[n].true_label = a;
                ET[n].label_after = a;
            }
            annotate_for_conditions(ET[n].down, a, -1);
            if (a == ET[n].label_after)
                 annotate_for_conditions(ET[ET[n].down].right, -1, b);
            else annotate_for_conditions(ET[ET[n].down].right, a, b);
            return;
    }

    i = ET[n].down;
    while (i != -1)
    {   annotate_for_conditions(i, -1, -1); i = ET[i].right; }
}

/* --- Code generator ------------------------------------------------------ */

static void value_in_void_context_z(assembly_operand AO)
{   char *t;

    ASSERT_ZCODE(); 
 
    switch(AO.type)
    {   case LONG_CONSTANT_OT:
        case SHORT_CONSTANT_OT:
            t = "<constant>";
            if (AO.marker == SYMBOL_MV)
                t = (char *) (symbs[AO.value]);
            break;
        case VARIABLE_OT:
            t = variable_name(AO.value);
            break;
        default:
            compiler_error("Unable to print value in void context");
            t = "<expression>";
            break;
    }
    vivc_flag = TRUE;

    if (strcmp(t, "print_paddr") == 0)
    obsolete_warning("ignoring 'print_paddr': use 'print (string)' instead");
    else
    if (strcmp(t, "print_addr") == 0)
    obsolete_warning("ignoring 'print_addr': use 'print (address)' instead");
    else
    if (strcmp(t, "print_char") == 0)
    obsolete_warning("ignoring 'print_char': use 'print (char)' instead");
    else
    ebf_error("expression with side-effects", t);
}

static void write_result_z(assembly_operand to, assembly_operand from)
{   if (to.value == from.value) return;
    if (to.value == 0) assemblez_1(push_zc, from);
    else               assemblez_store(to, from);
}

static void pop_zm_stack(void)
{   assembly_operand st;
    if (version_number < 5) assemblez_0(pop_zc);
    else
    {   INITAOTV(&st, VARIABLE_OT, 0);
        assemblez_1_branch(jz_zc, st, -2, TRUE);
    }
}

static void access_memory_z(int oc, assembly_operand AO1, assembly_operand AO2,
    assembly_operand AO3)
{   int vr = 0;

    assembly_operand zero_ao, max_ao, size_ao, en_ao, type_ao, an_ao,
        index_ao;
    int x = 0, y = 0, byte_flag = FALSE, read_flag = FALSE, from_module = FALSE;

    if (AO1.marker == ARRAY_MV || AO1.marker == STATIC_ARRAY_MV)
    {   
        INITAO(&zero_ao);

        if ((oc == loadb_zc) || (oc == storeb_zc)) byte_flag=TRUE;
        else byte_flag = FALSE;
        if ((oc == loadb_zc) || (oc == loadw_zc)) read_flag=TRUE;
        else read_flag = FALSE;

        zero_ao.type = SHORT_CONSTANT_OT;
        zero_ao.value = 0;

        size_ao = zero_ao; size_ao.value = -1;
        for (x=0; x<no_arrays; x++)
        {   if (((AO1.marker == ARRAY_MV) == (!array_locs[x]))
                && (AO1.value == svals[array_symbols[x]]))
            {   size_ao.value = array_sizes[x]; y=x;
            }
        }
        
        if (array_locs[y] && !read_flag) {
            error("Cannot write to a static array");
        }

        if (size_ao.value==-1) 
            from_module=TRUE;
        else {
            from_module=FALSE;
            type_ao = zero_ao; type_ao.value = array_types[y];

            if ((!is_systemfile()))
            {   if (byte_flag)
                {
                    if ((array_types[y] == WORD_ARRAY)
                        || (array_types[y] == TABLE_ARRAY))
                        warning("Using '->' to access a --> or table array");
                }
                else
                {
                    if ((array_types[y] == BYTE_ARRAY)
                        || (array_types[y] == STRING_ARRAY))
                    warning("Using '-->' to access a -> or string array");
                }
            }
        }
    }


    if ((!runtime_error_checking_switch) || (veneer_mode))
    {   if ((oc == loadb_zc) || (oc == loadw_zc))
            assemblez_2_to(oc, AO1, AO2, AO3);
        else
            assemblez_3(oc, AO1, AO2, AO3);
        return;
    }

    /* If we recognise AO1 as arising textually from a declared
       array, we can check bounds explicitly. */

    if ((AO1.marker == ARRAY_MV || AO1.marker == STATIC_ARRAY_MV) && (!from_module))
    {   
        int passed_label = next_label++, failed_label = next_label++,
            final_label = next_label++; 
        /* Calculate the largest permitted array entry + 1
           Here "size_ao.value" = largest permitted entry of its own kind */
        max_ao = size_ao;

        if (byte_flag
            && ((array_types[y] == WORD_ARRAY)
                || (array_types[y] == TABLE_ARRAY)))
        {   max_ao.value = size_ao.value*2 + 1;
            type_ao.value += 8;
        }
        if ((!byte_flag)
            && ((array_types[y] == BYTE_ARRAY)
                || (array_types[y] == STRING_ARRAY) 
                || (array_types[y] == BUFFER_ARRAY)))
        {   if ((size_ao.value % 2) == 0)
                 max_ao.value = size_ao.value/2 - 1;
            else max_ao.value = (size_ao.value-1)/2;
            type_ao.value += 16;
        }
        max_ao.value++;

        if (size_ao.value >= 256) size_ao.type = LONG_CONSTANT_OT;
        if (max_ao.value >= 256) max_ao.type = LONG_CONSTANT_OT;

        /* Can't write to the size entry in a string or table */
        if (((array_types[y] == STRING_ARRAY)
             || (array_types[y] == TABLE_ARRAY))
            && (!read_flag))
        {   if ((array_types[y] == TABLE_ARRAY) && byte_flag)
                zero_ao.value = 2;
            else zero_ao.value = 1;
        }

        en_ao = zero_ao; en_ao.value = ABOUNDS_RTE;
        switch(oc) { case loadb_zc:  en_ao.value = ABOUNDS_RTE; break;
                     case loadw_zc:  en_ao.value = ABOUNDS_RTE+1; break;
                     case storeb_zc: en_ao.value = ABOUNDS_RTE+2; break;
                     case storew_zc: en_ao.value = ABOUNDS_RTE+3; break; }

        index_ao = AO2;
        if ((AO2.type == VARIABLE_OT)&&(AO2.value == 0))
        {   assemblez_store(temp_var2, AO2);
            assemblez_store(AO2, temp_var2);
            index_ao = temp_var2;
        }
        assemblez_2_branch(jl_zc, index_ao, zero_ao, failed_label, TRUE);
        assemblez_2_branch(jl_zc, index_ao, max_ao, passed_label, TRUE);
        assemble_label_no(failed_label);
        an_ao = zero_ao; an_ao.value = y;
        assemblez_6(call_vn2_zc, veneer_routine(RT__Err_VR), en_ao,
            index_ao, size_ao, type_ao, an_ao);

        /* We have to clear any of AO1, AO2, AO3 off the stack if
           present, so that we can achieve the same effect on the stack
           that executing the opcode would have had */

        if ((AO1.type == VARIABLE_OT) && (AO1.value == 0)) pop_zm_stack();
        if ((AO2.type == VARIABLE_OT) && (AO2.value == 0)) pop_zm_stack();
        if ((AO3.type == VARIABLE_OT) && (AO3.value == 0))
        {   if ((oc == loadb_zc) || (oc == loadw_zc))
            {   assemblez_store(AO3, zero_ao);
            }
            else pop_zm_stack();
        }
        assemblez_jump(final_label);

        assemble_label_no(passed_label);
        if ((oc == loadb_zc) || (oc == loadw_zc))
            assemblez_2_to(oc, AO1, AO2, AO3);
        else
            assemblez_3(oc, AO1, AO2, AO3);
        assemble_label_no(final_label);
        return;
    }

    /* Otherwise, compile a call to the veneer which verifies that
       the proposed read/write is within dynamic Z-machine memory. */

    switch(oc) { case loadb_zc: vr = RT__ChLDB_VR; break;
                 case loadw_zc: vr = RT__ChLDW_VR; break;
                 case storeb_zc: vr = RT__ChSTB_VR; break;
                 case storew_zc: vr = RT__ChSTW_VR; break;
                 default: compiler_error("unknown array opcode");
    }

    if ((oc == loadb_zc) || (oc == loadw_zc))
        assemblez_3_to(call_vs_zc, veneer_routine(vr), AO1, AO2, AO3);
    else
        assemblez_4(call_vn_zc, veneer_routine(vr), AO1, AO2, AO3);
}

static assembly_operand check_nonzero_at_runtime_z(assembly_operand AO1,
        int error_label, int rte_number)
{   assembly_operand AO2, AO3;
    int check_sp = FALSE, passed_label, failed_label, last_label;
    if (veneer_mode) return AO1;

    /*  Assemble to code to check that the operand AO1 is ofclass Object:
        if it is, execution should continue and the stack should be
        unchanged.  Otherwise, call the veneer's run-time-error routine
        with the given error number, and then: if the label isn't -1,
        switch execution to this label, with the value popped from
        the stack if it was on the stack in the first place;
        if the label is -1, either replace the top of the stack with
        the constant 2, or return the operand (short constant) 2.

        The point of 2 is that object 2 is the class-object Object
        and therefore has no parent, child or sibling, so that the
        built-in tree functions will safely return 0 on this object. */

    /*  Sometimes we can already see that the object number is valid. */
    if (((AO1.type == LONG_CONSTANT_OT) || (AO1.type == SHORT_CONSTANT_OT))
        && (AO1.marker == 0) && (AO1.value >= 1) && (AO1.value < no_objects))
        return AO1;

    passed_label = next_label++;
    failed_label = next_label++;
    INITAOTV(&AO2, LONG_CONSTANT_OT, actual_largest_object_SC);
    AO2.marker = INCON_MV;
    INITAOTV(&AO3, SHORT_CONSTANT_OT, 5);

    if ((rte_number == IN_RTE) || (rte_number == HAS_RTE)
        || (rte_number == PROPERTY_RTE) || (rte_number == PROP_NUM_RTE)
        || (rte_number == PROP_ADD_RTE))
    {   /* Allow classes */
        AO3.value = 1;
        if ((AO1.type == VARIABLE_OT) && (AO1.value == 0))
        {   /* That is, if AO1 is the stack pointer */
            check_sp = TRUE;
            assemblez_store(temp_var2, AO1);
            assemblez_store(AO1, temp_var2);
            assemblez_2_branch(jg_zc, AO3, temp_var2, failed_label, TRUE);
            assemblez_2_branch(jg_zc, temp_var2, AO2, passed_label, FALSE);
        }
        else
        {   assemblez_2_branch(jg_zc, AO3, AO1, failed_label, TRUE);
            assemblez_2_branch(jg_zc, AO1, AO2, passed_label, FALSE);
        }
    }
    else
    {   if ((AO1.type == VARIABLE_OT) && (AO1.value == 0))
        {   /* That is, if AO1 is the stack pointer */
            check_sp = TRUE;
            assemblez_store(temp_var2, AO1);
            assemblez_store(AO1, temp_var2);
            assemblez_2_branch(jg_zc, AO3, temp_var2, failed_label, TRUE);
            assemblez_2_branch(jg_zc, temp_var2, AO2, failed_label, TRUE);
            AO3.value = 1;
            assemblez_2_branch(jin_zc, temp_var2, AO3, passed_label, FALSE);
        }
        else
        {   assemblez_2_branch(jg_zc, AO3, AO1, failed_label, TRUE);
            assemblez_2_branch(jg_zc, AO1, AO2, failed_label, TRUE);
            AO3.value = 1;
            assemblez_2_branch(jin_zc, AO1, AO3, passed_label, FALSE);
        }
    }

    assemble_label_no(failed_label);
    INITAOTV(&AO2, SHORT_CONSTANT_OT, rte_number);
    if (version_number >= 5)
      assemblez_3(call_vn_zc, veneer_routine(RT__Err_VR), AO2, AO1);
    else
      assemblez_3_to(call_zc, veneer_routine(RT__Err_VR), AO2, AO1, temp_var2);

    if (error_label != -1)
    {   /* Jump to the error label */
        if (error_label == -3) assemblez_0(rfalse_zc);
        else if (error_label == -4) assemblez_0(rtrue_zc);
        else assemblez_jump(error_label);
    }
    else
    {   if (check_sp)
        {   /* Push the short constant 2 */
            INITAOTV(&AO2, SHORT_CONSTANT_OT, 2);
            assemblez_store(AO1, AO2);
        }
        else
        {   /* Store either short constant 2 or the operand's value in
               the temporary variable */
            INITAOTV(&AO2, SHORT_CONSTANT_OT, 2);
            AO3 = temp_var2; assemblez_store(AO3, AO2);
            last_label = next_label++;
            assemblez_jump(last_label);
            assemble_label_no(passed_label);
            assemblez_store(AO3, AO1);
            assemble_label_no(last_label);
            return AO3;
        }
    }
    assemble_label_no(passed_label);
    return AO1;
}

static void compile_conditional_z(int oc,
    assembly_operand AO1, assembly_operand AO2, int label, int flag)
{   assembly_operand AO3; int the_zc, error_label = label,
    va_flag = FALSE, va_label = 0;

    ASSERT_ZCODE(); 

    if (oc<200)
    {   if ((runtime_error_checking_switch) && (oc == jin_zc))
        {   if (flag) error_label = next_label++;
            AO1 = check_nonzero_at_runtime(AO1, error_label, IN_RTE);
        }
        if ((runtime_error_checking_switch) && (oc == test_attr_zc))
        {   if (flag) error_label = next_label++;
            AO1 = check_nonzero_at_runtime(AO1, error_label, HAS_RTE);
            switch(AO2.type)
            {   case SHORT_CONSTANT_OT:
                case LONG_CONSTANT_OT:
                    if (AO2.marker == 0)
                    {   if ((AO2.value < 0) || (AO2.value > 47))
                error("'has'/'hasnt' applied to illegal attribute number");
                        break;
                    }
                case VARIABLE_OT:
                {   int pa_label = next_label++, fa_label = next_label++;
                    assembly_operand en_ao, zero_ao, max_ao;
                    assemblez_store(temp_var1, AO1);
                    if ((AO1.type == VARIABLE_OT)&&(AO1.value == 0))
                        assemblez_store(AO1, temp_var1);
                    assemblez_store(temp_var2, AO2);
                    if ((AO2.type == VARIABLE_OT)&&(AO2.value == 0))
                        assemblez_store(AO2, temp_var2);
                    INITAOT(&zero_ao, SHORT_CONSTANT_OT);
                    zero_ao.value = 0; 
                    max_ao = zero_ao; max_ao.value = 48;
                    assemblez_2_branch(jl_zc,temp_var2,zero_ao,fa_label,TRUE);
                    assemblez_2_branch(jl_zc,temp_var2,max_ao,pa_label,TRUE);
                    assemble_label_no(fa_label);
                    en_ao = zero_ao; en_ao.value = 19;
                    assemblez_4(call_vn_zc, veneer_routine(RT__Err_VR),
                        en_ao, temp_var1, temp_var2);
                    va_flag = TRUE; va_label = next_label++;
                    assemblez_jump(va_label);
                    assemble_label_no(pa_label);
                }
            }
        }
        assemblez_2_branch(oc, AO1, AO2, label, flag);
        if (error_label != label) assemble_label_no(error_label);
        if (va_flag) assemble_label_no(va_label);
        return;
    }

    INITAOTV(&AO3, VARIABLE_OT, 0);

    the_zc = (version_number == 3)?call_zc:call_vs_zc;
    if (oc == 201)
    assemblez_3_to(the_zc, veneer_routine(OP__Pr_VR), AO1, AO2, AO3);
    else
    assemblez_3_to(the_zc, veneer_routine(OC__Cl_VR), AO1, AO2, AO3);

    assemblez_1_branch(jz_zc, AO3, label, !flag);
}

static void value_in_void_context_g(assembly_operand AO)
{   char *t;

    ASSERT_GLULX(); 

    switch(AO.type)
    {   case CONSTANT_OT:
        case HALFCONSTANT_OT:
        case BYTECONSTANT_OT:
        case ZEROCONSTANT_OT:
            t = "<constant>";
            if (AO.marker == SYMBOL_MV)
                t = (char *) (symbs[AO.value]);
            break;
        case GLOBALVAR_OT:
        case LOCALVAR_OT:
            t = variable_name(AO.value);
            break;
        default:
            compiler_error("Unable to print value in void context");
            t = "<expression>";
            break;
    }
    vivc_flag = TRUE;

    ebf_error("expression with side-effects", t);
}

static void write_result_g(assembly_operand to, assembly_operand from)
{   if (to.value == from.value && to.type == from.type) return;
    assembleg_store(to, from);
}

static void access_memory_g(int oc, assembly_operand AO1, assembly_operand AO2,
    assembly_operand AO3)
{   int vr = 0;
    int data_len, read_flag; 
    assembly_operand zero_ao, max_ao, size_ao, en_ao, type_ao, an_ao,
        index_ao, five_ao;
    int passed_label, failed_label, final_label, x = 0, y = 0;

    if ((oc == aloadb_gc) || (oc == astoreb_gc)) data_len = 1;
    else if ((oc == aloads_gc) || (oc == astores_gc)) data_len = 2;
    else data_len = 4;

    if ((oc == aloadb_gc) || (oc == aloads_gc) || (oc == aload_gc)) 
      read_flag = TRUE;
    else 
      read_flag = FALSE;

    if (AO1.marker == ARRAY_MV || AO1.marker == STATIC_ARRAY_MV)
    {   
        INITAO(&zero_ao);

        size_ao = zero_ao; size_ao.value = -1;
        for (x=0; x<no_arrays; x++)
        {   if (((AO1.marker == ARRAY_MV) == (!array_locs[x]))
                && (AO1.value == svals[array_symbols[x]]))
            {   size_ao.value = array_sizes[x]; y=x;
            }
        }
        if (size_ao.value==-1) compiler_error("Array size can't be found");

        type_ao = zero_ao; type_ao.value = array_types[y];

        if (array_locs[y] && !read_flag) {
            error("Cannot write to a static array");
        }

        if ((!is_systemfile()))
        {   if (data_len == 1)
            {
                if ((array_types[y] == WORD_ARRAY)
                    || (array_types[y] == TABLE_ARRAY))
                    warning("Using '->' to access a --> or table array");
            }
            else
            {
                if ((array_types[y] == BYTE_ARRAY)
                    || (array_types[y] == STRING_ARRAY))
                 warning("Using '-->' to access a -> or string array");
            }
        }
    }


    if ((!runtime_error_checking_switch) || (veneer_mode))
    {
        assembleg_3(oc, AO1, AO2, AO3);
        return;
    }

    /* If we recognise AO1 as arising textually from a declared
       array, we can check bounds explicitly. */

    if (AO1.marker == ARRAY_MV || AO1.marker == STATIC_ARRAY_MV)
    {   
        /* Calculate the largest permitted array entry + 1
           Here "size_ao.value" = largest permitted entry of its own kind */
        max_ao = size_ao;
        if (data_len == 1
            && ((array_types[y] == WORD_ARRAY)
                || (array_types[y] == TABLE_ARRAY)))
        {   max_ao.value = size_ao.value*4 + 3;
            type_ao.value += 8;
        }
        if (data_len == 4
            && ((array_types[y] == BYTE_ARRAY)
                || (array_types[y] == STRING_ARRAY)
                || (array_types[y] == BUFFER_ARRAY)))
        {   max_ao.value = (size_ao.value-3)/4;
            type_ao.value += 16;
        }
        max_ao.value++;

        /* Can't write to the size entry in a string or table */
        if (((array_types[y] == STRING_ARRAY)
             || (array_types[y] == TABLE_ARRAY))
            && (!read_flag))
        {   if ((array_types[y] == TABLE_ARRAY) && data_len == 1)
                zero_ao.value = 4;
            else zero_ao.value = 1;
        }

        en_ao = zero_ao; en_ao.value = ABOUNDS_RTE;

        switch(oc) { case aloadb_gc:  en_ao.value = ABOUNDS_RTE; break;
                     case aload_gc:  en_ao.value = ABOUNDS_RTE+1; break;
                     case astoreb_gc: en_ao.value = ABOUNDS_RTE+2; break;
                     case astore_gc: en_ao.value = ABOUNDS_RTE+3; break; }

        set_constant_ot(&zero_ao);
        set_constant_ot(&size_ao);
        set_constant_ot(&max_ao);
        set_constant_ot(&type_ao);
        set_constant_ot(&en_ao);

        /* If we recognize A02 as a constant, we can do the test right
           now. */
        if (is_constant_ot(AO2.type) && AO2.marker == 0) {
            if (AO2.value < zero_ao.value || AO2.value >= max_ao.value) {
              error("Array reference is out-of-bounds");
            }
            assembleg_3(oc, AO1, AO2, AO3);
            return;
        }

        passed_label = next_label++; 
        failed_label = next_label++;
        final_label = next_label++;

        index_ao = AO2;
        if ((AO2.type == LOCALVAR_OT)&&(AO2.value == 0))
        {   assembleg_store(temp_var2, AO2); /* ### could peek */
            assembleg_store(AO2, temp_var2);
            index_ao = temp_var2;
        }
        assembleg_2_branch(jlt_gc, index_ao, zero_ao, failed_label);
        assembleg_2_branch(jlt_gc, index_ao, max_ao, passed_label);
        assemble_label_no(failed_label);

        an_ao = zero_ao; an_ao.value = y;
        set_constant_ot(&an_ao);
        five_ao = zero_ao; five_ao.value = 5;
        set_constant_ot(&five_ao);

        /* Call the error veneer routine. */
        assembleg_store(stack_pointer, an_ao);
        assembleg_store(stack_pointer, type_ao);
        assembleg_store(stack_pointer, size_ao);
        assembleg_store(stack_pointer, index_ao);
        assembleg_store(stack_pointer, en_ao);
        assembleg_3(call_gc, veneer_routine(RT__Err_VR),
            five_ao, zero_operand);

        /* We have to clear any of AO1, AO2, AO3 off the stack if
           present, so that we can achieve the same effect on the stack
           that executing the opcode would have had */

        if ((AO1.type == LOCALVAR_OT) && (AO1.value == 0)) 
            assembleg_2(copy_gc, stack_pointer, zero_operand);
        if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0)) 
            assembleg_2(copy_gc, stack_pointer, zero_operand);
        if ((AO3.type == LOCALVAR_OT) && (AO3.value == 0))
        {   if ((oc == aloadb_gc) || (oc == aload_gc))
            {   assembleg_store(AO3, zero_ao);
            }
            else assembleg_2(copy_gc, stack_pointer, zero_operand);
        }
        assembleg_jump(final_label);

        assemble_label_no(passed_label);
        assembleg_3(oc, AO1, AO2, AO3);
        assemble_label_no(final_label);
        return;
    }

    /* Otherwise, compile a call to the veneer which verifies that
       the proposed read/write is within dynamic Z-machine memory. */

    switch(oc) { 
        case aloadb_gc: vr = RT__ChLDB_VR; break;
        case aload_gc: vr = RT__ChLDW_VR; break;
        case astoreb_gc: vr = RT__ChSTB_VR; break;
        case astore_gc: vr = RT__ChSTW_VR; break;
        default: compiler_error("unknown array opcode");
    }

    if ((oc == aloadb_gc) || (oc == aload_gc)) 
      assembleg_call_2(veneer_routine(vr), AO1, AO2, AO3);
    else
      assembleg_call_3(veneer_routine(vr), AO1, AO2, AO3, zero_operand);
}

static assembly_operand check_nonzero_at_runtime_g(assembly_operand AO1,
        int error_label, int rte_number)
{
  assembly_operand AO, AO2, AO3;
  int ln;
  int check_sp = FALSE, passed_label, failed_label, last_label;

  if (veneer_mode) 
    return AO1;

  /*  Assemble to code to check that the operand AO1 is ofclass Object:
      if it is, execution should continue and the stack should be
      unchanged.  Otherwise, call the veneer's run-time-error routine
      with the given error number, and then: if the label isn't -1,
      switch execution to this label, with the value popped from
      the stack if it was on the stack in the first place;
      if the label is -1, either replace the top of the stack with
      the constant symbol (class-object) Object.

      The Object has no parent, child or sibling, so that the
      built-in tree functions will safely return 0 on this object. */

  /*  Sometimes we can already see that the object number is valid. */
  if (AO1.marker == OBJECT_MV && 
    ((AO1.value >= 1) && (AO1.value <= no_objects))) {
    return AO1;
  }

  passed_label = next_label++;
  failed_label = next_label++;  

  if ((AO1.type == LOCALVAR_OT) && (AO1.value == 0) && (AO1.marker == 0)) {
    /* That is, if AO1 is the stack pointer */
    check_sp = TRUE;
    assembleg_store(temp_var2, stack_pointer);
    assembleg_store(stack_pointer, temp_var2);
    AO = temp_var2;
  }
  else {
    AO = AO1;
  }
  
  if ((rte_number == IN_RTE) || (rte_number == HAS_RTE)
    || (rte_number == PROPERTY_RTE) || (rte_number == PROP_NUM_RTE)
    || (rte_number == PROP_ADD_RTE)) {   
    /* Allow classes */
    /* Test if zero... */
    assembleg_1_branch(jz_gc, AO, failed_label);
    /* Test if first byte is 0x70... */
    assembleg_3(aloadb_gc, AO, zero_operand, stack_pointer);
    INITAO(&AO3);
    AO3.value = 0x70; /* type byte -- object */
    set_constant_ot(&AO3);
    assembleg_2_branch(jeq_gc, stack_pointer, AO3, passed_label);
  }
  else {
    /* Test if zero... */
    assembleg_1_branch(jz_gc, AO, failed_label);
    /* Test if first byte is 0x70... */
    assembleg_3(aloadb_gc, AO, zero_operand, stack_pointer);
    INITAO(&AO3);
    AO3.value = 0x70; /* type byte -- object */
    set_constant_ot(&AO3);
    assembleg_2_branch(jne_gc, stack_pointer, AO3, failed_label);
    /* Test if inside the "Class" object... */
    INITAOTV(&AO3, BYTECONSTANT_OT, GOBJFIELD_PARENT());
    assembleg_3(aload_gc, AO, AO3, stack_pointer);
    ln = symbol_index("Class", -1);
    AO3.value = svals[ln];
    AO3.marker = OBJECT_MV;
    AO3.type = CONSTANT_OT;
    assembleg_2_branch(jne_gc, stack_pointer, AO3, passed_label);
  }
  
  assemble_label_no(failed_label);
  INITAO(&AO2);
  AO2.value = rte_number; 
  set_constant_ot(&AO2);
  assembleg_call_2(veneer_routine(RT__Err_VR), AO2, AO1, zero_operand);
  
  if (error_label != -1) {
    /* Jump to the error label */
    if (error_label == -3) assembleg_1(return_gc, zero_operand);
    else if (error_label == -4) assembleg_1(return_gc, one_operand);
    else assembleg_jump(error_label);
  }
  else {
    /* Build the symbol for "Object" */
    ln = symbol_index("Object", -1);
    AO2.value = svals[ln];
    AO2.marker = OBJECT_MV;
    AO2.type = CONSTANT_OT;
    if (check_sp) {
      /* Push "Object" */
      assembleg_store(AO1, AO2);
    }
    else {
      /* Store either "Object" or the operand's value in the temporary
         variable. */
      assembleg_store(temp_var2, AO2);
      last_label = next_label++;
      assembleg_jump(last_label);
      assemble_label_no(passed_label);
      assembleg_store(temp_var2, AO1);
      assemble_label_no(last_label);
      return temp_var2;
    }
  }
    
  assemble_label_no(passed_label);
  return AO1;
}

static void compile_conditional_g(condclass *cc,
    assembly_operand AO1, assembly_operand AO2, int label, int flag)
{   assembly_operand AO4; 
    int the_zc, error_label = label,
    va_flag = FALSE, va_label = 0;

    ASSERT_GLULX(); 

    the_zc = (flag ? cc->posform : cc->negform);

    if (the_zc == -1) {
      switch ((cc-condclasses)*2 + 500) {

      case HAS_CC:
        if (runtime_error_checking_switch) {
          if (flag) 
            error_label = next_label++;
          AO1 = check_nonzero_at_runtime(AO1, error_label, HAS_RTE);
          if (is_constant_ot(AO2.type) && AO2.marker == 0) {
            if ((AO2.value < 0) || (AO2.value >= NUM_ATTR_BYTES*8)) {
              error("'has'/'hasnt' applied to illegal attribute number");
            }
          }
          else {
            int pa_label = next_label++, fa_label = next_label++;
            assembly_operand en_ao, max_ao;

            if ((AO1.type == LOCALVAR_OT) && (AO1.value == 0)) {
              if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0)) {
                assembleg_2(stkpeek_gc, zero_operand, temp_var1);
                assembleg_2(stkpeek_gc, one_operand, temp_var2);
              }
              else {
                assembleg_2(stkpeek_gc, zero_operand, temp_var1);
                assembleg_store(temp_var2, AO2);
              }
            }
            else {
              assembleg_store(temp_var1, AO1);
              if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0)) {
                assembleg_2(stkpeek_gc, zero_operand, temp_var2);
              }
              else {
                assembleg_store(temp_var2, AO2);
              }
            }

            INITAO(&max_ao);
            max_ao.value = NUM_ATTR_BYTES*8;
            set_constant_ot(&max_ao);
            assembleg_2_branch(jlt_gc, temp_var2, zero_operand, fa_label);
            assembleg_2_branch(jlt_gc, temp_var2, max_ao, pa_label);
            assemble_label_no(fa_label);
            INITAO(&en_ao);
            en_ao.value = 19; /* INVALIDATTR_RTE */
            set_constant_ot(&en_ao);
            assembleg_store(stack_pointer, temp_var2);
            assembleg_store(stack_pointer, temp_var1);
            assembleg_store(stack_pointer, en_ao);
            assembleg_3(call_gc, veneer_routine(RT__Err_VR),
              three_operand, zero_operand);
            va_flag = TRUE; 
            va_label = next_label++;
            assembleg_jump(va_label);
            assemble_label_no(pa_label);
          }
        }
        if (is_constant_ot(AO2.type) && AO2.marker == 0) {
          AO2.value += 8;
          set_constant_ot(&AO2);
        }
        else {
          INITAO(&AO4);
          AO4.value = 8;
          AO4.type = BYTECONSTANT_OT;
          if ((AO1.type == LOCALVAR_OT) && (AO1.value == 0)) {
            if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0)) 
              assembleg_0(stkswap_gc);
            assembleg_3(add_gc, AO2, AO4, stack_pointer);
            assembleg_0(stkswap_gc);
          }
          else {
            assembleg_3(add_gc, AO2, AO4, stack_pointer);
          }
          AO2 = stack_pointer;
        }
        assembleg_3(aloadbit_gc, AO1, AO2, stack_pointer);
        the_zc = (flag ? jnz_gc : jz_gc);
        AO1 = stack_pointer;
        break;

      case IN_CC:
        if (runtime_error_checking_switch) {
          if (flag) 
            error_label = next_label++;
          AO1 = check_nonzero_at_runtime(AO1, error_label, IN_RTE);
        }
        INITAO(&AO4);
        AO4.value = GOBJFIELD_PARENT();
        AO4.type = BYTECONSTANT_OT;
        assembleg_3(aload_gc, AO1, AO4, stack_pointer);
        AO1 = stack_pointer;
        the_zc = (flag ? jeq_gc : jne_gc);
        break;

      case OFCLASS_CC:
        assembleg_call_2(veneer_routine(OC__Cl_VR), AO1, AO2, stack_pointer);
        the_zc = (flag ? jnz_gc : jz_gc);
        AO1 = stack_pointer;
        break;

      case PROVIDES_CC:
        assembleg_call_2(veneer_routine(OP__Pr_VR), AO1, AO2, stack_pointer);
        the_zc = (flag ? jnz_gc : jz_gc);
        AO1 = stack_pointer;
        break;

      default:
        error("condition not yet supported in Glulx");
        return;
      }
    }

    if (the_zc == jnz_gc || the_zc == jz_gc)
      assembleg_1_branch(the_zc, AO1, label);
    else
      assembleg_2_branch(the_zc, AO1, AO2, label);
    if (error_label != label) assemble_label_no(error_label);
    if (va_flag) assemble_label_no(va_label);
}

static void value_in_void_context(assembly_operand AO)
{
  if (!glulx_mode)
    value_in_void_context_z(AO);
  else
    value_in_void_context_g(AO);
}


extern assembly_operand check_nonzero_at_runtime(assembly_operand AO1,
  int error_label, int rte_number)
{
  if (!glulx_mode)
    return check_nonzero_at_runtime_z(AO1, error_label, rte_number);
  else
    return check_nonzero_at_runtime_g(AO1, error_label, rte_number);
}

static void generate_code_from(int n, int void_flag)
{
    /*  When void, this must not leave anything on the stack. */

    int i, j, below, above, opnum, arity; assembly_operand Result;

    below = ET[n].down; above = ET[n].up;
    if (below == -1)
    {   if ((void_flag) && (ET[n].value.type != OMITTED_OT))
            value_in_void_context(ET[n].value);
        return;
    }

    opnum = ET[n].operator_number;

    if (opnum == COMMA_OP)
    {   generate_code_from(below, TRUE);
        generate_code_from(ET[below].right, void_flag);
        ET[n].value = ET[ET[below].right].value;
        goto OperatorGenerated;
    }

    if ((opnum == LOGAND_OP) || (opnum == LOGOR_OP))
    {   generate_code_from(below, FALSE);
        generate_code_from(ET[below].right, FALSE);
        goto OperatorGenerated;
    }

    if (opnum == -1)
    {
        /*  Signifies a SETEQUALS_OP which has already been done */

        ET[n].down = -1; return;
    }

    /*  Note that (except in the cases of comma and logical and/or) it
        is essential to code generate the operands right to left, because
        of the peculiar way the Z-machine's stack works:

            @sub sp sp -> a;

        (for instance) pulls to the first operand, then the second.  So

            @mul a 2 -> sp;
            @add b 7 -> sp;
            @sub sp sp -> a;

        calculates (b+7)-(a*2), not the other way around (as would be more
        usual in stack machines evaluating expressions written in reverse
        Polish notation).  (Basically this is because the Z-machine was
        designed to implement a LISP-like language naturally expressed
        in forward Polish notation: (PLUS 3 4), for instance.)               */

    /*  And the Glulx machine follows the Z-machine in this respect. */

    i=below; arity = 0;
    while (i != -1)
    {   i = ET[i].right; arity++;
    }
    for (j=arity;j>0;j--)
    {   int k = 1;
        i = below;
        while (k<j)
        {   k++; i = ET[i].right;
        }
        generate_code_from(i, FALSE);
    }


    /*  Check this again, because code generation lower down may have
        stubbed it into -1  */

    if (ET[n].operator_number == -1)
    {   ET[n].down = -1; return;
    }

  if (!glulx_mode) {

    if (operators[opnum].opcode_number_z >= 400)
    {
        /*  Conditional terms such as '==': */

        int a = ET[n].true_label, b = ET[n].false_label,
            branch_away, branch_other,
            make_jump_away = FALSE, make_branch_label = FALSE;
        int oc = operators[opnum].opcode_number_z-400, flag = TRUE;

        if (oc >= 400) { oc = oc - 400; flag = FALSE; }

        if ((oc == je_zc) && (arity == 2))
        {   i = ET[ET[n].down].right;
            if ((ET[i].value.value == zero_operand.value)
                && (ET[i].value.type == zero_operand.type))
                oc = jz_zc;
        }

        /*  If the condition has truth state flag, branch to
            label a, and if not, to label b.  Possibly one of a, b
            equals -1, meaning "continue from this instruction".

            branch_away is the label which is a branch away (the one
            which isn't immediately after) and flag is the truth
            state to branch there.

            Note that when multiple instructions are needed (because
            of the use of the 'or' operator) the branch_other label
            is created if need be.
        */

        /*  Reduce to the case where the branch_away label does exist:  */

        if (a == -1) { a = b; b = -1; flag = !flag; }

        branch_away = a; branch_other = b;
        if (branch_other != -1) make_jump_away = TRUE;

        if ((((oc != je_zc)&&(arity > 2)) || (arity > 4)) && (flag == FALSE))
        {
            /*  In this case, we have an 'or' situation where multiple
                instructions are needed and where the overall condition
                is negated.  That is, we have, e.g.

                   if not (A cond B or C or D) then branch_away

                which we transform into

                   if (A cond B) then branch_other
                   if (A cond C) then branch_other
                   if not (A cond D) then branch_away
                  .branch_other                                          */

            if (branch_other == -1)
            {   branch_other = next_label++; make_branch_label = TRUE;
            }
        }

        if (oc == jz_zc)
            assemblez_1_branch(jz_zc, ET[below].value, branch_away, flag);
        else
        {   assembly_operand left_operand;

            if (arity == 2)
                compile_conditional_z(oc, ET[below].value,
                    ET[ET[below].right].value, branch_away, flag);
            else
            {   /*  The case of a condition using "or".
                    First: if the condition tests the stack pointer,
                    and it can't always be done in a single test, move
                    the value off the stack and into temporary variable
                    storage.  */

                if (((ET[below].value.type == VARIABLE_OT)
                     && (ET[below].value.value == 0))
                    && ((oc != je_zc) || (arity>4)) )
                {   INITAOTV(&left_operand, VARIABLE_OT, 255);
                    assemblez_store(left_operand, ET[below].value);
                }
                else left_operand = ET[below].value;
                i = ET[below].right; arity--;

                /*  "left_operand" now holds the quantity to be tested;
                    "i" holds the right operand reached so far;
                    "arity" the number of right operands.  */

                while (i != -1)
                {   if ((oc == je_zc) && (arity>1))
                    {
                        /*  je_zc is an especially good case since the
                            Z-machine implements "or" for up to three
                            right operands automatically, though it's an
                            especially bad case to generate code for!  */

                        if (arity == 2)
                        {   assemblez_3_branch(je_zc,
                              left_operand, ET[i].value,
                              ET[ET[i].right].value, branch_away, flag);
                            i = ET[i].right; arity--;
                        }
                        else
                        {   if ((arity == 3) || flag)
                              assemblez_4_branch(je_zc, left_operand,
                                ET[i].value,
                                ET[ET[i].right].value,
                                ET[ET[ET[i].right].right].value,
                                branch_away, flag);
                            else
                              assemblez_4_branch(je_zc, left_operand,
                                ET[i].value,
                                ET[ET[i].right].value,
                                ET[ET[ET[i].right].right].value,
                                branch_other, !flag);
                            i = ET[ET[i].right].right; arity -= 2;
                        }
                    }
                    else
                    {   /*  Otherwise we can compare the left_operand with
                            only one right operand at the time.  There are
                            two cases: it's the last right operand, or it
                            isn't.  */

                        if ((arity == 1) || flag)
                            compile_conditional_z(oc, left_operand,
                                ET[i].value, branch_away, flag);
                        else
                            compile_conditional_z(oc, left_operand,
                                ET[i].value, branch_other, !flag);
                    }
                    i = ET[i].right; arity--;
                }

            }
        }

        /*  NB: These two conditions cannot both occur, fortunately!  */

        if (make_branch_label) assemble_label_no(branch_other);
        if (make_jump_away) assemblez_jump(branch_other);

        goto OperatorGenerated;
    }

  }
  else {
    if (operators[opnum].opcode_number_g >= FIRST_CC 
      && operators[opnum].opcode_number_g <= LAST_CC) {
      /*  Conditional terms such as '==': */

      int a = ET[n].true_label, b = ET[n].false_label;
      int branch_away, branch_other, flag,
        make_jump_away = FALSE, make_branch_label = FALSE;
      int ccode = operators[opnum].opcode_number_g;
      condclass *cc = &condclasses[(ccode-FIRST_CC) / 2];
      flag = (ccode & 1) ? 0 : 1;

      /*  If the comparison is "equal to (constant) 0", change it
          to the simple "zero" test. Unfortunately, this doesn't
          work for the commutative form "(constant) 0 is equal to". 
          At least I don't think it does. */

      if ((cc == &condclasses[1]) && (arity == 2)) {
        i = ET[ET[n].down].right;
        if ((ET[i].value.value == 0)
          && (ET[i].value.marker == 0) 
          && is_constant_ot(ET[i].value.type)) {
          cc = &condclasses[0];
        }
      }

      /*  If the condition has truth state flag, branch to
          label a, and if not, to label b.  Possibly one of a, b
          equals -1, meaning "continue from this instruction".
          
          branch_away is the label which is a branch away (the one
          which isn't immediately after) and flag is the truth
          state to branch there.

          Note that when multiple instructions are needed (because
          of the use of the 'or' operator) the branch_other label
          is created if need be.
      */
      
      /*  Reduce to the case where the branch_away label does exist:  */

      if (a == -1) { a = b; b = -1; flag = !flag; }

      branch_away = a; branch_other = b;
      if (branch_other != -1) make_jump_away = TRUE;
      
      if ((arity > 2) && (flag == FALSE)) {
        /*  In this case, we have an 'or' situation where multiple
            instructions are needed and where the overall condition
            is negated.  That is, we have, e.g.
            
            if not (A cond B or C or D) then branch_away
            
            which we transform into
            
            if (A cond B) then branch_other
            if (A cond C) then branch_other
            if not (A cond D) then branch_away
            .branch_other                                          */
        
        if (branch_other == -1) {
          branch_other = next_label++; make_branch_label = TRUE;
        }
      }

      if (cc == &condclasses[0]) {
        assembleg_1_branch((flag ? cc->posform : cc->negform), 
          ET[below].value, branch_away);
      }
      else {
        if (arity == 2) {
          compile_conditional_g(cc, ET[below].value,
            ET[ET[below].right].value, branch_away, flag);
        }
        else {
          /*  The case of a condition using "or".
              First: if the condition tests the stack pointer,
              and it can't always be done in a single test, move
              the value off the stack and into temporary variable
              storage.  */

          assembly_operand left_operand;
          if (((ET[below].value.type == LOCALVAR_OT)
            && (ET[below].value.value == 0))) {
            assembleg_store(temp_var1, ET[below].value);
            left_operand = temp_var1;
          }
          else {
            left_operand = ET[below].value;
          }
          i = ET[below].right; 
          arity--;

          /*  "left_operand" now holds the quantity to be tested;
              "i" holds the right operand reached so far;
              "arity" the number of right operands.  */

          while (i != -1) {
            /*  We can compare the left_operand with
            only one right operand at the time.  There are
            two cases: it's the last right operand, or it
            isn't.  */

            if ((arity == 1) || flag)
              compile_conditional_g(cc, left_operand,
            ET[i].value, branch_away, flag);
            else
              compile_conditional_g(cc, left_operand,
            ET[i].value, branch_other, !flag);

            i = ET[i].right; 
            arity--;
          }
        }
      }
      
      /*  NB: These two conditions cannot both occur, fortunately!  */
      
      if (make_branch_label) assemble_label_no(branch_other);
      if (make_jump_away) assembleg_jump(branch_other);
      
      goto OperatorGenerated;
    }

  }

    /*  The operator is now definitely one which produces a value  */

    if (void_flag && (!(operators[opnum].side_effect)))
        error_named("Evaluating this has no effect:",
            operators[opnum].description);

    /*  Where shall we put the resulting value? (In Glulx, this could 
        be smarter, and peg the result into ZEROCONSTANT.) */

    if (void_flag) Result = temp_var1;  /*  Throw it away  */
    else
    {   if ((above != -1) && (ET[above].operator_number == SETEQUALS_OP))
        {
            /*  If the node above is "set variable equal to", then
                make that variable the place to put the result, and
                delete the SETEQUALS_OP node since its effect has already
                been accomplished.  */

            ET[above].operator_number = -1;
            Result = ET[ET[above].down].value;
            ET[above].value = Result;
        }
        else Result = stack_pointer;  /*  Otherwise, put it on the stack  */
    }

  if (!glulx_mode) {

    if (operators[opnum].opcode_number_z != -1)
    {
        /*  Operators directly translatable into Z-code opcodes: infix ops
            take two operands whereas pre/postfix operators take only one */

        if (operators[opnum].usage == IN_U)
        {   int o_n = operators[opnum].opcode_number_z;
            if (runtime_error_checking_switch && (!veneer_mode)
                && ((o_n == div_zc) || (o_n == mod_zc)))
            {   assembly_operand by_ao, error_ao; int ln;
                by_ao = ET[ET[below].right].value;
                if ((by_ao.value != 0) && (by_ao.marker == 0)
                    && ((by_ao.type == SHORT_CONSTANT_OT)
                        || (by_ao.type == LONG_CONSTANT_OT)))
                    assemblez_2_to(o_n, ET[below].value,
                        by_ao, Result);
                else
                {
                    assemblez_store(temp_var1, ET[below].value);
                    assemblez_store(temp_var2, by_ao);
                    ln = next_label++;
                    assemblez_1_branch(jz_zc, temp_var2, ln, FALSE);
                    INITAOT(&error_ao, SHORT_CONSTANT_OT);
                    error_ao.value = DBYZERO_RTE;
                    assemblez_2(call_vn_zc, veneer_routine(RT__Err_VR),
                        error_ao);
                    assemblez_inc(temp_var2);
                    assemble_label_no(ln);
                    assemblez_2_to(o_n, temp_var1, temp_var2, Result);
                }
            }
            else {
            assemblez_2_to(o_n, ET[below].value,
                ET[ET[below].right].value, Result);
            }
        }
        else
            assemblez_1_to(operators[opnum].opcode_number_z, ET[below].value,
                Result);
    }
    else
    switch(opnum)
    {   case ARROW_OP:
             access_memory_z(loadb_zc, ET[below].value,
                                     ET[ET[below].right].value, Result);
             break;
        case DARROW_OP:
             access_memory_z(loadw_zc, ET[below].value,
                                     ET[ET[below].right].value, Result);
             break;
        case UNARY_MINUS_OP:
             assemblez_2_to(sub_zc, zero_operand, ET[below].value, Result);
             break;
        case ARTNOT_OP:
             assemblez_1_to(not_zc, ET[below].value, Result);
             break;

        case PROP_ADD_OP:
             {   assembly_operand AO = ET[below].value;
                 if (runtime_error_checking_switch && (!veneer_mode))
                     AO = check_nonzero_at_runtime(AO, -1, PROP_ADD_RTE);
                 assemblez_2_to(get_prop_addr_zc, AO,
                     ET[ET[below].right].value, temp_var1);
                 if (!void_flag) write_result_z(Result, temp_var1);
             }
             break;

        case PROP_NUM_OP:
             {   assembly_operand AO = ET[below].value;
                 if (runtime_error_checking_switch && (!veneer_mode))
                     AO = check_nonzero_at_runtime(AO, -1, PROP_NUM_RTE);
                 assemblez_2_to(get_prop_addr_zc, AO,
                     ET[ET[below].right].value, temp_var1);
                 assemblez_1_branch(jz_zc, temp_var1, next_label++, TRUE);
                 assemblez_1_to(get_prop_len_zc, temp_var1, temp_var1);
                 assemble_label_no(next_label-1);
                 if (!void_flag) write_result_z(Result, temp_var1);
             }
             break;

        case PROPERTY_OP:
             {   assembly_operand AO = ET[below].value;

                 if (runtime_error_checking_switch && (!veneer_mode))
                       assemblez_3_to(call_vs_zc, veneer_routine(RT__ChPR_VR),
                         AO, ET[ET[below].right].value, temp_var1);
                 else
                 assemblez_2_to(get_prop_zc, AO,
                     ET[ET[below].right].value, temp_var1);
                 if (!void_flag) write_result_z(Result, temp_var1);
             }
             break;

        case MESSAGE_OP:
             j=1; AI.operand[0] = veneer_routine(RV__Pr_VR);
             goto GenFunctionCallZ;
        case MPROP_ADD_OP:
             j=1; AI.operand[0] = veneer_routine(RA__Pr_VR);
             goto GenFunctionCallZ;
        case MPROP_NUM_OP:
             j=1; AI.operand[0] = veneer_routine(RL__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_SETEQUALS_OP:
             j=1; AI.operand[0] = veneer_routine(WV__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_INC_OP:
             j=1; AI.operand[0] = veneer_routine(IB__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_DEC_OP:
             j=1; AI.operand[0] = veneer_routine(DB__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_POST_INC_OP:
             j=1; AI.operand[0] = veneer_routine(IA__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_POST_DEC_OP:
             j=1; AI.operand[0] = veneer_routine(DA__Pr_VR);
             goto GenFunctionCallZ;
        case SUPERCLASS_OP:
             j=1; AI.operand[0] = veneer_routine(RA__Sc_VR);
             goto GenFunctionCallZ;
        case PROP_CALL_OP:
             j=1; AI.operand[0] = veneer_routine(CA__Pr_VR);
             goto GenFunctionCallZ;
        case MESSAGE_CALL_OP:
             j=1; AI.operand[0] = veneer_routine(CA__Pr_VR);
             goto GenFunctionCallZ;


        case FCALL_OP:
             j = 0;

             if ((ET[below].value.type == VARIABLE_OT)
                 && (ET[below].value.value >= 256))
             {   int sf_number = ET[below].value.value - 256;

                 i = ET[below].right;
                 if (i == -1)
                 {   error("Argument to system function missing");
                     AI.operand[0] = one_operand;
                     AI.operand_count = 1;
                 }
                 else
                 {   j=0;
                     while (i != -1) { j++; i = ET[i].right; }

                     if (((sf_number != INDIRECT_SYSF) &&
                         (sf_number != RANDOM_SYSF) && (j > 1))
                         || ((sf_number == INDIRECT_SYSF) && (j>7)))
                     {   j=1;
                         error("System function given with too many arguments");
                     }
                     if (sf_number != RANDOM_SYSF)
                     {   int jcount;
                         i = ET[below].right;
                         for (jcount = 0; jcount < j; jcount++)
                         {   AI.operand[jcount] = ET[i].value;
                             i = ET[i].right;
                         }
                         AI.operand_count = j;
                     }
                 }
                 AI.store_variable_number = Result.value;
                 AI.branch_label_number = -1;

                 switch(sf_number)
                 {   case RANDOM_SYSF:
                         if (j>1)
                         {  assembly_operand AO, AO2; int arg_c, arg_et;
                            INITAOTV(&AO, SHORT_CONSTANT_OT, j);
                            INITAOT(&AO2, LONG_CONSTANT_OT);
                            AO2.value = begin_word_array();
                            AO2.marker = ARRAY_MV;

                            for (arg_c=0, arg_et = ET[below].right;arg_c<j;
                                 arg_c++, arg_et = ET[arg_et].right)
                            {   if (ET[arg_et].value.type == VARIABLE_OT)
              error("Only constants can be used as possible 'random' results");
                                array_entry(arg_c, FALSE, ET[arg_et].value);
                            }
                            finish_array(arg_c, FALSE);

                            assemblez_1_to(random_zc, AO, temp_var1);
                            assemblez_dec(temp_var1);
                            assemblez_2_to(loadw_zc, AO2, temp_var1, Result);
                         }
                         else
                         assemblez_1_to(random_zc,
                             ET[ET[below].right].value, Result);
                         break;

                     case PARENT_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                                AO = check_nonzero_at_runtime(AO, -1,
                                    PARENT_RTE);
                            assemblez_1_to(get_parent_zc, AO, Result);
                         }
                         break;

                     case ELDEST_SYSF:
                     case CHILD_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                               AO = check_nonzero_at_runtime(AO, -1,
                               (sf_number==CHILD_SYSF)?CHILD_RTE:ELDEST_RTE);
                            assemblez_objcode(get_child_zc,
                               AO, Result, -2, TRUE);
                         }
                         break;

                     case YOUNGER_SYSF:
                     case SIBLING_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                               AO = check_nonzero_at_runtime(AO, -1,
                               (sf_number==SIBLING_SYSF)
                                   ?SIBLING_RTE:YOUNGER_RTE);
                            assemblez_objcode(get_sibling_zc,
                               AO, Result, -2, TRUE);
                         }
                         break;

                     case INDIRECT_SYSF:
                         j=0; i = ET[below].right;
                         goto IndirectFunctionCallZ;

                     case CHILDREN_SYSF:
                         {  assembly_operand AO;
                             AO = ET[ET[below].right].value;
                             if (runtime_error_checking_switch)
                                 AO = check_nonzero_at_runtime(AO, -1,
                                     CHILDREN_RTE);
                             assemblez_store(temp_var1, zero_operand);
                             assemblez_objcode(get_child_zc,
                                 AO, stack_pointer, next_label+1, FALSE);
                             assemble_label_no(next_label);
                             assemblez_inc(temp_var1);
                             assemblez_objcode(get_sibling_zc,
                                 stack_pointer, stack_pointer,
                                 next_label, TRUE);
                             assemble_label_no(next_label+1);
                             assemblez_store(temp_var2, stack_pointer);
                             if (!void_flag) write_result_z(Result, temp_var1);
                             next_label += 2;
                         }
                         break;

                     case YOUNGEST_SYSF:
                         {  assembly_operand AO;
                             AO = ET[ET[below].right].value;
                             if (runtime_error_checking_switch)
                                 AO = check_nonzero_at_runtime(AO, -1,
                                     YOUNGEST_RTE);
                             assemblez_objcode(get_child_zc,
                                 AO, temp_var1, next_label+1, FALSE);
                             assemblez_1(push_zc, temp_var1);
                             assemble_label_no(next_label);
                             assemblez_store(temp_var1, stack_pointer);
                             assemblez_objcode(get_sibling_zc,
                                 temp_var1, stack_pointer, next_label, TRUE);
                             assemble_label_no(next_label+1);
                             if (!void_flag) write_result_z(Result, temp_var1);
                             next_label += 2;
                         }
                         break;

                     case ELDER_SYSF:
                         assemblez_store(temp_var1, ET[ET[below].right].value);
                         if (runtime_error_checking_switch)
                             check_nonzero_at_runtime(temp_var1, -1,
                                 ELDER_RTE);
                         assemblez_1_to(get_parent_zc, temp_var1, temp_var3);
                         assemblez_1_branch(jz_zc, temp_var3,next_label+1,TRUE);
                         assemblez_store(temp_var2, temp_var3);
                         assemblez_store(temp_var3, zero_operand);
                         assemblez_objcode(get_child_zc,
                             temp_var2, temp_var2, next_label, TRUE);
                         assemble_label_no(next_label++);
                         assemblez_2_branch(je_zc, temp_var1, temp_var2,
                             next_label, TRUE);
                         assemblez_store(temp_var3, temp_var2);
                         assemblez_objcode(get_sibling_zc,
                             temp_var2, temp_var2, next_label - 1, TRUE);
                         assemble_label_no(next_label++);
                         if (!void_flag) write_result_z(Result, temp_var3);
                         break;

                     case METACLASS_SYSF:
                         assemblez_2_to((version_number==3)?call_zc:call_vs_zc,
                             veneer_routine(Metaclass_VR),
                             ET[ET[below].right].value, Result);
                         break;

                     case GLK_SYSF: 
                         error("The glk() system function does not exist in Z-code");
                         break;
                 }
                 break;
             }

             GenFunctionCallZ:

             i = below;

             IndirectFunctionCallZ:

             while ((i != -1) && (j<8))
             {   AI.operand[j++] = ET[i].value;
                 i = ET[i].right;
             }

             if ((j > 4) && (version_number == 3))
             {   error("A function may be called with at most 3 arguments");
                 j = 4;
             }
             if ((j==8) && (i != -1))
             {   error("A function may be called with at most 7 arguments");
             }

             AI.operand_count = j;

             if ((void_flag) && (version_number >= 5))
             {   AI.store_variable_number = -1;
                 switch(j)
                 {   case 1: AI.internal_number = call_1n_zc; break;
                     case 2: AI.internal_number = call_2n_zc; break;
                     case 3: case 4: AI.internal_number = call_vn_zc; break;
                     case 5: case 6: case 7: case 8:
                         AI.internal_number = call_vn2_zc; break;
                 }
             }
             else
             {   AI.store_variable_number = Result.value;
                 if (version_number == 3)
                     AI.internal_number = call_zc;
                 else
                 switch(j)
                 {   case 1: AI.internal_number = call_1s_zc; break;
                     case 2: AI.internal_number = call_2s_zc; break;
                     case 3: case 4: AI.internal_number = call_vs_zc; break;
                     case 5: case 6: case 7: case 8:
                         AI.internal_number = call_vs2_zc; break;
                 }
             }

             AI.branch_label_number = -1;
             assemblez_instruction(&AI);
             break;

        case SETEQUALS_OP:
             assemblez_store(ET[below].value,
                 ET[ET[below].right].value);
             if (!void_flag) write_result_z(Result, ET[below].value);
             break;

        case PROPERTY_SETEQUALS_OP:
             if (!void_flag)
             {   if (runtime_error_checking_switch)
                     assemblez_4_to(call_zc, veneer_routine(RT__ChPS_VR),
                         ET[below].value, ET[ET[below].right].value,
                         ET[ET[ET[below].right].right].value, Result);
                 else
                 {   assemblez_store(temp_var1,
                         ET[ET[ET[below].right].right].value);
                     assemblez_3(put_prop_zc, ET[below].value,
                         ET[ET[below].right].value,
                         temp_var1);
                     write_result_z(Result, temp_var1);
                 }
             }
             else
             {   if (runtime_error_checking_switch && (!veneer_mode))
                     assemblez_4(call_vn_zc, veneer_routine(RT__ChPS_VR),
                         ET[below].value, ET[ET[below].right].value,
                         ET[ET[ET[below].right].right].value);
                 else assemblez_3(put_prop_zc, ET[below].value,
                     ET[ET[below].right].value,
                     ET[ET[ET[below].right].right].value);
             }
             break;
        case ARROW_SETEQUALS_OP:
             if (!void_flag)
             {   assemblez_store(temp_var1,
                     ET[ET[ET[below].right].right].value);
                 access_memory_z(storeb_zc, ET[below].value,
                     ET[ET[below].right].value,
                     temp_var1);
                 write_result_z(Result, temp_var1);
             }
             else access_memory_z(storeb_zc, ET[below].value,
                     ET[ET[below].right].value,
                     ET[ET[ET[below].right].right].value);
             break;

        case DARROW_SETEQUALS_OP:
             if (!void_flag)
             {   assemblez_store(temp_var1,
                     ET[ET[ET[below].right].right].value);
                 access_memory_z(storew_zc, ET[below].value,
                     ET[ET[below].right].value,
                     temp_var1);
                 write_result_z(Result, temp_var1);
             }
             else
                 access_memory_z(storew_zc, ET[below].value,
                     ET[ET[below].right].value,
                     ET[ET[ET[below].right].right].value);
             break;

        case INC_OP:
             assemblez_inc(ET[below].value);
             if (!void_flag) write_result_z(Result, ET[below].value);
             break;
        case DEC_OP:
             assemblez_dec(ET[below].value);
             if (!void_flag) write_result_z(Result, ET[below].value);
             break;
        case POST_INC_OP:
             if (!void_flag) write_result_z(Result, ET[below].value);
             assemblez_inc(ET[below].value);
             break;
        case POST_DEC_OP:
             if (!void_flag) write_result_z(Result, ET[below].value);
             assemblez_dec(ET[below].value);
             break;

        case ARROW_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadb_zc, temp_var1, temp_var2, temp_var3);
             assemblez_inc(temp_var3);
             access_memory_z(storeb_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case ARROW_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadb_zc, temp_var1, temp_var2, temp_var3);
             assemblez_dec(temp_var3);
             access_memory_z(storeb_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case ARROW_POST_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadb_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_inc(temp_var3);
             access_memory_z(storeb_zc, temp_var1, temp_var2, temp_var3);
             break;

        case ARROW_POST_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadb_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_dec(temp_var3);
             access_memory_z(storeb_zc, temp_var1, temp_var2, temp_var3);
             break;

        case DARROW_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadw_zc, temp_var1, temp_var2, temp_var3);
             assemblez_inc(temp_var3);
             access_memory_z(storew_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case DARROW_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadw_zc, temp_var1, temp_var2, temp_var3);
             assemblez_dec(temp_var3);
             access_memory_z(storew_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case DARROW_POST_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadw_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_inc(temp_var3);
             access_memory_z(storew_zc, temp_var1, temp_var2, temp_var3);
             break;

        case DARROW_POST_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             access_memory_z(loadw_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_dec(temp_var3);
             access_memory_z(storew_zc, temp_var1, temp_var2, temp_var3);
             break;

        case PROPERTY_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             assemblez_2_to(get_prop_zc, temp_var1, temp_var2, temp_var3);
             assemblez_inc(temp_var3);
             if (runtime_error_checking_switch && (!veneer_mode))
                  assemblez_4(call_vn_zc, veneer_routine(RT__ChPS_VR),
                         temp_var1, temp_var2, temp_var3);
             else assemblez_3(put_prop_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case PROPERTY_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             assemblez_2_to(get_prop_zc, temp_var1, temp_var2, temp_var3);
             assemblez_dec(temp_var3);
             if (runtime_error_checking_switch && (!veneer_mode))
                  assemblez_4(call_vn_zc, veneer_routine(RT__ChPS_VR),
                         temp_var1, temp_var2, temp_var3);
             else assemblez_3(put_prop_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             break;

        case PROPERTY_POST_INC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             assemblez_2_to(get_prop_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_inc(temp_var3);
             if (runtime_error_checking_switch && (!veneer_mode))
                  assemblez_4(call_vn_zc, veneer_routine(RT__ChPS_VR),
                         temp_var1, temp_var2, temp_var3);
             else assemblez_3(put_prop_zc, temp_var1, temp_var2, temp_var3);
             break;

        case PROPERTY_POST_DEC_OP:
             assemblez_store(temp_var1, ET[below].value);
             assemblez_store(temp_var2, ET[ET[below].right].value);
             assemblez_2_to(get_prop_zc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_z(Result, temp_var3);
             assemblez_dec(temp_var3);
             if (runtime_error_checking_switch && (!veneer_mode))
                  assemblez_4(call_vn_zc, veneer_routine(RT__ChPS_VR),
                         temp_var1, temp_var2, temp_var3);
             else assemblez_3(put_prop_zc, temp_var1, temp_var2, temp_var3);
             break;

        default:
            printf("** Trouble op = %d i.e. '%s' **\n",
                opnum, operators[opnum].description);
            compiler_error("Expr code gen: Can't generate yet");
    }
  }
  else {
    assembly_operand AO, AO2;
    if (operators[opnum].opcode_number_g != -1)
    {
        /*  Operators directly translatable into opcodes: infix ops
            take two operands whereas pre/postfix operators take only one */

        if (operators[opnum].usage == IN_U)
        {   int o_n = operators[opnum].opcode_number_g;
            if (runtime_error_checking_switch && (!veneer_mode)
                && ((o_n == div_gc) || (o_n == mod_gc)))
            {   assembly_operand by_ao, error_ao; int ln;
                by_ao = ET[ET[below].right].value;
                if ((by_ao.value != 0) && (by_ao.marker == 0)
                    && is_constant_ot(by_ao.type))
                    assembleg_3(o_n, ET[below].value,
                        by_ao, Result);
                else
                {   assembleg_store(temp_var1, ET[below].value);
                    assembleg_store(temp_var2, by_ao);
                    ln = next_label++;
                    assembleg_1_branch(jnz_gc, temp_var2, ln);
                    INITAO(&error_ao);
                    error_ao.value = DBYZERO_RTE;
                    set_constant_ot(&error_ao);
                    assembleg_call_1(veneer_routine(RT__Err_VR),
                      error_ao, zero_operand);
                    assembleg_store(temp_var2, one_operand);
                    assemble_label_no(ln);
                    assembleg_3(o_n, temp_var1, temp_var2, Result);
                }
            }
            else
            assembleg_3(o_n, ET[below].value,
                ET[ET[below].right].value, Result);
        }
        else
            assembleg_2(operators[opnum].opcode_number_g, ET[below].value,
                Result);
    }
    else
    switch(opnum)
    {

        case PUSH_OP:
             if (ET[below].value.type == Result.type
               && ET[below].value.value == Result.value
               && ET[below].value.marker == Result.marker)
               break;
             assembleg_2(copy_gc, ET[below].value, Result);
             break;

        case UNARY_MINUS_OP:
             assembleg_2(neg_gc, ET[below].value, Result);
             break;
        case ARTNOT_OP:
             assembleg_2(bitnot_gc, ET[below].value, Result);
             break;

        case ARROW_OP:
             access_memory_g(aloadb_gc, ET[below].value,
                                      ET[ET[below].right].value, Result);
             break;
        case DARROW_OP:
             access_memory_g(aload_gc, ET[below].value,
                                     ET[ET[below].right].value, Result);
             break;

        case SETEQUALS_OP:
             assembleg_store(ET[below].value,
                 ET[ET[below].right].value);
             if (!void_flag) write_result_g(Result, ET[below].value);
             break;

        case ARROW_SETEQUALS_OP:
             if (!void_flag)
             {   assembleg_store(temp_var1,
                     ET[ET[ET[below].right].right].value);
                 access_memory_g(astoreb_gc, ET[below].value,
                     ET[ET[below].right].value,
                     temp_var1);
                 write_result_g(Result, temp_var1);
             }
             else access_memory_g(astoreb_gc, ET[below].value,
                     ET[ET[below].right].value,
                     ET[ET[ET[below].right].right].value);
             break;

        case DARROW_SETEQUALS_OP:
             if (!void_flag)
             {   assembleg_store(temp_var1,
                     ET[ET[ET[below].right].right].value);
                 access_memory_g(astore_gc, ET[below].value,
                     ET[ET[below].right].value,
                     temp_var1);
                 write_result_g(Result, temp_var1);
             }
             else
                 access_memory_g(astore_gc, ET[below].value,
                     ET[ET[below].right].value,
                     ET[ET[ET[below].right].right].value);
             break;

        case INC_OP:
             assembleg_inc(ET[below].value);
             if (!void_flag) write_result_g(Result, ET[below].value);
             break;
        case DEC_OP:
             assembleg_dec(ET[below].value);
             if (!void_flag) write_result_g(Result, ET[below].value);
             break;
        case POST_INC_OP:
             if (!void_flag) write_result_g(Result, ET[below].value);
             assembleg_inc(ET[below].value);
             break;
        case POST_DEC_OP:
             if (!void_flag) write_result_g(Result, ET[below].value);
             assembleg_dec(ET[below].value);
             break;

        case ARROW_INC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aloadb_gc, temp_var1, temp_var2, temp_var3);
             assembleg_inc(temp_var3);
             access_memory_g(astoreb_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             break;

        case ARROW_DEC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aloadb_gc, temp_var1, temp_var2, temp_var3);
             assembleg_dec(temp_var3);
             access_memory_g(astoreb_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             break;

        case ARROW_POST_INC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aloadb_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             assembleg_inc(temp_var3);
             access_memory_g(astoreb_gc, temp_var1, temp_var2, temp_var3);
             break;

        case ARROW_POST_DEC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aloadb_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             assembleg_dec(temp_var3);
             access_memory_g(astoreb_gc, temp_var1, temp_var2, temp_var3);
             break;

        case DARROW_INC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aload_gc, temp_var1, temp_var2, temp_var3);
             assembleg_inc(temp_var3);
             access_memory_g(astore_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             break;

        case DARROW_DEC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aload_gc, temp_var1, temp_var2, temp_var3);
             assembleg_dec(temp_var3);
             access_memory_g(astore_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             break;

        case DARROW_POST_INC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aload_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             assembleg_inc(temp_var3);
             access_memory_g(astore_gc, temp_var1, temp_var2, temp_var3);
             break;

        case DARROW_POST_DEC_OP:
             assembleg_store(temp_var1, ET[below].value);
             assembleg_store(temp_var2, ET[ET[below].right].value);
             access_memory_g(aload_gc, temp_var1, temp_var2, temp_var3);
             if (!void_flag) write_result_g(Result, temp_var3);
             assembleg_dec(temp_var3);
             access_memory_g(astore_gc, temp_var1, temp_var2, temp_var3);
             break;

        case PROPERTY_OP:
        case MESSAGE_OP:
             AO = veneer_routine(RV__Pr_VR);
             goto TwoArgFunctionCall;
        case MPROP_ADD_OP:
        case PROP_ADD_OP:
             AO = veneer_routine(RA__Pr_VR);
             goto TwoArgFunctionCall;
        case MPROP_NUM_OP:
        case PROP_NUM_OP:
             AO = veneer_routine(RL__Pr_VR);
             goto TwoArgFunctionCall;

        case PROP_CALL_OP:
        case MESSAGE_CALL_OP:
             AO2 = veneer_routine(CA__Pr_VR);
             i = below;
             goto DoFunctionCall;

        case MESSAGE_INC_OP:
        case PROPERTY_INC_OP:
             AO = veneer_routine(IB__Pr_VR);
             goto TwoArgFunctionCall;
        case MESSAGE_DEC_OP:
        case PROPERTY_DEC_OP:
             AO = veneer_routine(DB__Pr_VR);
             goto TwoArgFunctionCall;
        case MESSAGE_POST_INC_OP:
        case PROPERTY_POST_INC_OP:
             AO = veneer_routine(IA__Pr_VR);
             goto TwoArgFunctionCall;
        case MESSAGE_POST_DEC_OP:
        case PROPERTY_POST_DEC_OP:
             AO = veneer_routine(DA__Pr_VR);
             goto TwoArgFunctionCall;
        case SUPERCLASS_OP:
             AO = veneer_routine(RA__Sc_VR);
             goto TwoArgFunctionCall;

             TwoArgFunctionCall:
             {
               assembly_operand AO2 = ET[below].value;
               assembly_operand AO3 = ET[ET[below].right].value;
               if (void_flag)
                 assembleg_call_2(AO, AO2, AO3, zero_operand);
               else
                 assembleg_call_2(AO, AO2, AO3, Result);
             }
             break;

        case PROPERTY_SETEQUALS_OP:
        case MESSAGE_SETEQUALS_OP:
             if (runtime_error_checking_switch && (!veneer_mode))
                 AO = veneer_routine(RT__ChPS_VR);
               else
                 AO = veneer_routine(WV__Pr_VR);

             {
               assembly_operand AO2 = ET[below].value;
               assembly_operand AO3 = ET[ET[below].right].value;
               assembly_operand AO4 = ET[ET[ET[below].right].right].value;
               if (AO4.type == LOCALVAR_OT && AO4.value == 0) {
                 /* Rightmost is on the stack; reduce to previous case. */
                 if (AO2.type == LOCALVAR_OT && AO2.value == 0) {
                   if (AO3.type == LOCALVAR_OT && AO3.value == 0) {
                     /* both already on stack. */
                   }
                   else {
                     assembleg_store(stack_pointer, AO3);
                     assembleg_0(stkswap_gc);
                   }
                 }
                 else {
                   if (AO3.type == LOCALVAR_OT && AO3.value == 0) {
                     assembleg_store(stack_pointer, AO2);
                   }
                   else {
                     assembleg_store(stack_pointer, AO3);
                     assembleg_store(stack_pointer, AO2);
                   }
                 }
               }
               else {
                 /* We have to get the rightmost on the stack, below the 
                    others. */
                 if (AO3.type == LOCALVAR_OT && AO3.value == 0) {
                   if (AO2.type == LOCALVAR_OT && AO2.value == 0) {
                     assembleg_store(stack_pointer, AO4);
                     assembleg_2(stkroll_gc, three_operand, one_operand);
                   }
                   else {
                     assembleg_store(stack_pointer, AO4);
                     assembleg_0(stkswap_gc);
                     assembleg_store(stack_pointer, AO2); 
                   }
                 }
                 else {
                   if (AO2.type == LOCALVAR_OT && AO2.value == 0) {
                     assembleg_store(stack_pointer, AO4);
                     assembleg_store(stack_pointer, AO3);
                     assembleg_2(stkroll_gc, three_operand, two_operand);
                   }
                   else {
                     assembleg_store(stack_pointer, AO4);
                     assembleg_store(stack_pointer, AO3);
                     assembleg_store(stack_pointer, AO2);
                   }
                 }
               }
               if (void_flag)
                 assembleg_3(call_gc, AO, three_operand, zero_operand);
               else
                 assembleg_3(call_gc, AO, three_operand, Result);
             }
             break;

        case FCALL_OP:
             j = 0;

             if (ET[below].value.type == SYSFUN_OT)
             {   int sf_number = ET[below].value.value;

                 i = ET[below].right;
                 if (i == -1)
                 {   error("Argument to system function missing");
                     AI.operand[0] = one_operand;
                     AI.operand_count = 1;
                 }
                 else
                 {   j=0;
                     while (i != -1) { j++; i = ET[i].right; }

                     if (((sf_number != INDIRECT_SYSF) &&
                         (sf_number != GLK_SYSF) &&
                         (sf_number != RANDOM_SYSF) && (j > 1)))
                     {   j=1;
                         error("System function given with too many arguments");
                     }
                     if (sf_number != RANDOM_SYSF)
                     {   int jcount;
                         i = ET[below].right;
                         for (jcount = 0; jcount < j; jcount++)
                         {   AI.operand[jcount] = ET[i].value;
                             i = ET[i].right;
                         }
                         AI.operand_count = j;
                     }
                 }

                 switch(sf_number)
                 {
                     case RANDOM_SYSF:
                         if (j>1)
                         {  assembly_operand AO, AO2; 
                            int arg_c, arg_et;
                            INITAO(&AO);
                            AO.value = j; 
                            set_constant_ot(&AO);
                            INITAOTV(&AO2, CONSTANT_OT, begin_word_array());
                            AO2.marker = ARRAY_MV;

                            for (arg_c=0, arg_et = ET[below].right;arg_c<j;
                                 arg_c++, arg_et = ET[arg_et].right)
                            {   if (ET[arg_et].value.type == LOCALVAR_OT
                                    || ET[arg_et].value.type == GLOBALVAR_OT)
              error("Only constants can be used as possible 'random' results");
                                array_entry(arg_c, FALSE, ET[arg_et].value);
                            }
                            finish_array(arg_c, FALSE);

                            assembleg_2(random_gc, AO, stack_pointer);
                            assembleg_3(aload_gc, AO2, stack_pointer, Result);
                         }
                         else {
                           assembleg_2(random_gc,
                             ET[ET[below].right].value, stack_pointer);
                           assembleg_3(add_gc, stack_pointer, one_operand,
                             Result);
                         }
                         break;

                     case PARENT_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                                AO = check_nonzero_at_runtime(AO, -1,
                                    PARENT_RTE);
                            INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_PARENT());
                            assembleg_3(aload_gc, AO, AO2, Result);
                         }
                         break;

                     case ELDEST_SYSF:
                     case CHILD_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                               AO = check_nonzero_at_runtime(AO, -1,
                               (sf_number==CHILD_SYSF)?CHILD_RTE:ELDEST_RTE);
                            INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_CHILD());
                            assembleg_3(aload_gc, AO, AO2, Result);
                         }
                         break;

                     case YOUNGER_SYSF:
                     case SIBLING_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                               AO = check_nonzero_at_runtime(AO, -1,
                               (sf_number==SIBLING_SYSF)
                                   ?SIBLING_RTE:YOUNGER_RTE);
                            INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_SIBLING());
                            assembleg_3(aload_gc, AO, AO2, Result);
                         }
                         break;

                     case CHILDREN_SYSF:
                         {  assembly_operand AO;
                            AO = ET[ET[below].right].value;
                            if (runtime_error_checking_switch)
                                AO = check_nonzero_at_runtime(AO, -1,
                                    CHILDREN_RTE);
                            INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_CHILD());
                            assembleg_store(temp_var1, zero_operand);
                            assembleg_3(aload_gc, AO, AO2, temp_var2);
                            AO2.value = GOBJFIELD_SIBLING();
                            assemble_label_no(next_label);
                            assembleg_1_branch(jz_gc, temp_var2, next_label+1);
                            assembleg_3(add_gc, temp_var1, one_operand, 
                              temp_var1);
                            assembleg_3(aload_gc, temp_var2, AO2, temp_var2);
                            assembleg_0_branch(jump_gc, next_label);
                            assemble_label_no(next_label+1);
                            next_label += 2;
                            if (!void_flag) 
                              write_result_g(Result, temp_var1);
                         }
                         break;

                     case INDIRECT_SYSF: 
                         i = ET[below].right;
                         goto IndirectFunctionCallG;

                     case GLK_SYSF: 
                         AO2 = veneer_routine(Glk__Wrap_VR);
                         i = ET[below].right;
                         goto DoFunctionCall;

                     case METACLASS_SYSF:
                         assembleg_call_1(veneer_routine(Metaclass_VR),
                             ET[ET[below].right].value, Result);
                         break;

                     case YOUNGEST_SYSF:
                         AO = ET[ET[below].right].value;
                         if (runtime_error_checking_switch)
                           AO = check_nonzero_at_runtime(AO, -1,
                             YOUNGEST_RTE);
                         INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_CHILD());
                         assembleg_3(aload_gc, AO, AO2, temp_var1);
                         AO2.value = GOBJFIELD_SIBLING();
                         assembleg_1_branch(jz_gc, temp_var1, next_label+1);
                         assemble_label_no(next_label);
                         assembleg_3(aload_gc, temp_var1, AO2, temp_var2);
                         assembleg_1_branch(jz_gc, temp_var2, next_label+1);
                         assembleg_store(temp_var1, temp_var2);
                         assembleg_0_branch(jump_gc, next_label);
                         assemble_label_no(next_label+1);
                         if (!void_flag) 
                           write_result_g(Result, temp_var1);
                         next_label += 2;
                         break;

                     case ELDER_SYSF: 
                         AO = ET[ET[below].right].value;
                         if (runtime_error_checking_switch)
                           AO = check_nonzero_at_runtime(AO, -1,
                             YOUNGEST_RTE);
                         assembleg_store(temp_var3, AO);
                         INITAOTV(&AO2, BYTECONSTANT_OT, GOBJFIELD_PARENT());
                         assembleg_3(aload_gc, temp_var3, AO2, temp_var1);
                         assembleg_1_branch(jz_gc, temp_var1, next_label+2);
                         AO2.value = GOBJFIELD_CHILD();
                         assembleg_3(aload_gc, temp_var1, AO2, temp_var1);
                         assembleg_1_branch(jz_gc, temp_var1, next_label+2);
                         assembleg_2_branch(jeq_gc, temp_var3, temp_var1, 
                           next_label+1);
                         assemble_label_no(next_label);
                         AO2.value = GOBJFIELD_SIBLING();
                         assembleg_3(aload_gc, temp_var1, AO2, temp_var2);
                         assembleg_2_branch(jeq_gc, temp_var3, temp_var2,
                           next_label+2);
                         assembleg_store(temp_var1, temp_var2);
                         assembleg_0_branch(jump_gc, next_label);
                         assemble_label_no(next_label+1);
                         assembleg_store(temp_var1, zero_operand);
                         assemble_label_no(next_label+2);
                         if (!void_flag)
                           write_result_g(Result, temp_var1);
                         next_label += 3;
                         break;

                     default:
                         error("*** system function not implemented ***");
                         break;

                 }
                 break;
             }

             i = below;

             IndirectFunctionCallG:

             /* Get the function address. */
             AO2 = ET[i].value;
             i = ET[i].right;

             DoFunctionCall:

             {
               /* If all the function arguments are in local/global
                  variables, we have to push them all on the stack.
                  If all of them are on the stack, we have to do nothing.
                  If some are and some aren't, we have a hopeless mess,
                  and we should throw a compiler error.
               */

               int onstack = 0;
               int offstack = 0;

               /* begin part of patch G03701 */
               int nargs = 0;
               j = i;
               while (j != -1) {
                 nargs++;
                 j = ET[j].right;
               }

               if (nargs==0) {
                 assembleg_2(callf_gc, AO2, void_flag ? zero_operand : Result);
               } else if (nargs==1) {
                 assembleg_call_1(AO2, ET[i].value, void_flag ? zero_operand : Result);
               } else if (nargs==2) {
                 assembly_operand o1 = ET[i].value;
                 assembly_operand o2 = ET[ET[i].right].value;
                 assembleg_call_2(AO2, o1, o2, void_flag ? zero_operand : Result);
               } else if (nargs==3) {
                 assembly_operand o1 = ET[i].value;
                 assembly_operand o2 = ET[ET[i].right].value;
                 assembly_operand o3 = ET[ET[ET[i].right].right].value;
                 assembleg_call_3(AO2, o1, o2, o3, void_flag ? zero_operand : Result);
               } else {

                 j = 0;
                 while (i != -1) {
                     if (ET[i].value.type == LOCALVAR_OT 
                       && ET[i].value.value == 0) {
                       onstack++;
                     }
                     else {
                       assembleg_store(stack_pointer, ET[i].value);
                       offstack++;
                     }
                     i = ET[i].right;
                     j++;
                 }

                 if (onstack && offstack)
                     error("*** Function call cannot be generated with mixed arguments ***");
                 if (offstack > 1)
                     error("*** Function call cannot be generated with more than one nonstack argument ***");

                 INITAO(&AO);
                 AO.value = j;
                 set_constant_ot(&AO);

                 if (void_flag)
                   assembleg_3(call_gc, AO2, AO, zero_operand);
                 else
                   assembleg_3(call_gc, AO2, AO, Result);

               } /* else nargs>=4 */
             } /* DoFunctionCall: */

             break;

        default:
            printf("** Trouble op = %d i.e. '%s' **\n",
                opnum, operators[opnum].description);
            compiler_error("Expr code gen: Can't generate yet");
    }
  }

    ET[n].value = Result;

    OperatorGenerated:

    if (!glulx_mode) {

        if (ET[n].to_expression)
        {
            if (void_flag) {
                warning("Logical expression has no side-effects");
                if (ET[n].true_label != -1)
                    assemble_label_no(ET[n].true_label);
                else
                    assemble_label_no(ET[n].false_label);
            }
            else if (ET[n].true_label != -1)
            {   assemblez_1(push_zc, zero_operand);
                assemblez_jump(next_label++);
                assemble_label_no(ET[n].true_label);
                assemblez_1(push_zc, one_operand);
                assemble_label_no(next_label-1);
            }
            else
            {   assemblez_1(push_zc, one_operand);
                assemblez_jump(next_label++);
                assemble_label_no(ET[n].false_label);
                assemblez_1(push_zc, zero_operand);
                assemble_label_no(next_label-1);
            }
            ET[n].value = stack_pointer;
        }
        else
            if (ET[n].label_after != -1)
                assemble_label_no(ET[n].label_after);

    }
    else {

        if (ET[n].to_expression)
        {   
            if (void_flag) {
                warning("Logical expression has no side-effects");
                if (ET[n].true_label != -1)
                    assemble_label_no(ET[n].true_label);
                else
                    assemble_label_no(ET[n].false_label);
            }
            else if (ET[n].true_label != -1)
            {   assembleg_store(stack_pointer, zero_operand);
                assembleg_jump(next_label++);
                assemble_label_no(ET[n].true_label);
                assembleg_store(stack_pointer, one_operand);
                assemble_label_no(next_label-1);
            }
            else
            {   assembleg_store(stack_pointer, one_operand);
                assembleg_jump(next_label++);
                assemble_label_no(ET[n].false_label);
                assembleg_store(stack_pointer, zero_operand);
                assemble_label_no(next_label-1);
            }
            ET[n].value = stack_pointer;
        }
        else
            if (ET[n].label_after != -1)
                assemble_label_no(ET[n].label_after);

    }

    ET[n].down = -1;
}

assembly_operand code_generate(assembly_operand AO, int context, int label)
{
    /*  Used in three contexts: VOID_CONTEXT, CONDITION_CONTEXT and
            QUANTITY_CONTEXT.

        If CONDITION_CONTEXT, then compile code branching to label number
            "label" if the condition is false: there's no return value.
        (Except that if label is -3 or -4 (internal codes for rfalse and
        rtrue rather than branch) then this is for branching when the
        condition is true.  This is used for optimising code generation
        for "if" statements.)

        Otherwise return the assembly operand containing the result
        (probably the stack pointer variable but not necessarily:
         e.g. is would be short constant 2 from the expression "j++, 2")     */

    vivc_flag = FALSE;

    if (AO.type != EXPRESSION_OT)
    {   switch(context)
        {   case VOID_CONTEXT:
                value_in_void_context(AO);
                AO.type = OMITTED_OT;
                AO.value = 0;
                break;
            case CONDITION_CONTEXT:
                if (!glulx_mode) {
                  if (label < -2) assemblez_1_branch(jz_zc, AO, label, FALSE);
                  else assemblez_1_branch(jz_zc, AO, label, TRUE);
                }
                else {
                  if (label < -2) 
                    assembleg_1_branch(jnz_gc, AO, label);
                  else 
                    assembleg_1_branch(jz_gc, AO, label);
                }
                AO.type = OMITTED_OT;
                AO.value = 0;
                break;
        }
        return AO;
    }

    if (expr_trace_level >= 2)
    {   printf("Raw parse tree:\n"); show_tree(AO, FALSE);
    }

    if (context == CONDITION_CONTEXT)
    {   if (label < -2) annotate_for_conditions(AO.value, label, -1);
        else annotate_for_conditions(AO.value, -1, label);
    }
    else annotate_for_conditions(AO.value, -1, -1);

    if (expr_trace_level >= 1)
    {   printf("Code generation for expression in ");
        switch(context)
        {   case VOID_CONTEXT: printf("void"); break;
            case CONDITION_CONTEXT: printf("condition"); break;
            case QUANTITY_CONTEXT: printf("quantity"); break;
            case ASSEMBLY_CONTEXT: printf("assembly"); break;
            case ARRAY_CONTEXT: printf("array initialisation"); break;
            default: printf("* ILLEGAL *"); break;
        }
        printf(" context with annotated tree:\n");
        show_tree(AO, TRUE);
    }

    generate_code_from(AO.value, (context==VOID_CONTEXT));
    return ET[AO.value].value;
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_expressc_vars(void)
{   make_operands();
}

extern void expressc_begin_pass(void)
{
}

extern void expressc_allocate_arrays(void)
{
}

extern void expressc_free_arrays(void)
{
}

/* ========================================================================= */
