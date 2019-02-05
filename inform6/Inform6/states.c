/* ------------------------------------------------------------------------- */
/*   "states" :  Statement translator                                        */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

static int match_colon(void)
{   get_next_token();
    if (token_type == SEP_TT)
    {   if (token_value == SEMICOLON_SEP)
            warning("Unlike C, Inform uses ':' to divide parts \
of a 'for' loop specification: replacing ';' with ':'");
        else
        if (token_value != COLON_SEP)
        {   ebf_error("':'", token_text);
            panic_mode_error_recovery();
            return(FALSE);
        }
    }
    else
    {   ebf_error("':'", token_text);
        panic_mode_error_recovery();
        return(FALSE);
    }
    return(TRUE);
}

static void match_open_bracket(void)
{   get_next_token();
    if ((token_type == SEP_TT) && (token_value == OPENB_SEP)) return;
    put_token_back();
    ebf_error("'('", token_text);
}

extern void match_close_bracket(void)
{   get_next_token();
    if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP)) return;
    put_token_back();
    ebf_error("')'", token_text);
}

static void parse_action(void)
{   int level = 1, args = 0, codegen_action;
    assembly_operand AO, AO2, AO3, AO4, AO5;

    /* An action statement has the form <ACTION NOUN SECOND, ACTOR>
       or <<ACTION NOUN SECOND, ACTOR>>. It simply compiles into a call
       to R_Process() with those four arguments. (The latter form,
       with double brackets, means "return true afterwards".)

       The R_Process() function should be supplied by the library, 
       although a stub is defined in the veneer.

       The NOUN, SECOND, and ACTOR arguments are optional. If not
       supplied, R_Process() will be called with fewer arguments. 
       (But if you supply ACTOR, it must be preceded by a comma.
       <ACTION, ACTOR> is equivalent to <ACTION 0 0, ACTOR>.)

       To complicate life, the ACTION argument may be a bare action
       name or a parenthesized expression. (So <Take> is equivalent
       to <(##Take)>.) We have to peek at the first token, checking
       whether it's an open-paren, to distinguish these cases.

       You may ask why the ACTOR argument is last; the "natural"
       Inform ordering would be "<floyd, take ball>". True! Sadly,
       Inform's lexer isn't smart enough to parse this consistently,
       so we can't do it.
    */

    dont_enter_into_symbol_table = TRUE;
    get_next_token();
    if ((token_type == SEP_TT) && (token_value == LESS_SEP))
    {   level = 2; get_next_token();
    }
    dont_enter_into_symbol_table = FALSE;

    /* Peek at the next token; see if it's an open-paren. */
    if ((token_type==SEP_TT) && (token_value==OPENB_SEP))
    {   put_token_back();
        AO2 = parse_expression(ACTION_Q_CONTEXT);
        codegen_action = TRUE;
    }
    else
    {   codegen_action = FALSE;
        AO2 = action_of_name(token_text);
    }

    get_next_token();
    AO3 = zero_operand;
    AO4 = zero_operand;
    AO5 = zero_operand;
    if (!((token_type == SEP_TT) && (token_value == GREATER_SEP || token_value == COMMA_SEP)))
    {   put_token_back();
        args = 1;
        AO3 = parse_expression(ACTION_Q_CONTEXT);

        get_next_token();
    }
    if (!((token_type == SEP_TT) && (token_value == GREATER_SEP || token_value == COMMA_SEP)))
    {   put_token_back();
        args = 2;
        AO4 = parse_expression(QUANTITY_CONTEXT);
        get_next_token();
    }
    if (!((token_type == SEP_TT) && (token_value == GREATER_SEP || token_value == COMMA_SEP)))
    {
        ebf_error("',' or '>'", token_text);
    }

    if ((token_type == SEP_TT) && (token_value == COMMA_SEP))
    {
        if (!glulx_mode && (version_number < 4))
        {
            error("<x, y> syntax is not available in Z-code V3 or earlier");
        }
        args = 3;
        AO5 = parse_expression(QUANTITY_CONTEXT);
        get_next_token();
        if (!((token_type == SEP_TT) && (token_value == GREATER_SEP)))
        {
            ebf_error("'>'", token_text);
        }
    }

    if (level == 2)
    {   get_next_token();
        if (!((token_type == SEP_TT) && (token_value == GREATER_SEP)))
        {   put_token_back();
            ebf_error("'>>'", token_text);
        }
    }

    if (!glulx_mode) {

      AO = veneer_routine(R_Process_VR);

      switch(args)
      {   case 0:
            if (codegen_action) AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
            if (version_number>=5)
                assemblez_2(call_2n_zc, AO, AO2);
            else
            if (version_number==4)
                assemblez_2_to(call_vs_zc, AO, AO2, temp_var1);
            else
                assemblez_2_to(call_zc, AO, AO2, temp_var1);
            break;
          case 1:
            AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
            if (codegen_action) AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
            if (version_number>=5)
                assemblez_3(call_vn_zc, AO, AO2, AO3);
            else
            if (version_number==4)
                assemblez_3_to(call_vs_zc, AO, AO2, AO3, temp_var1);
            else
                assemblez_3_to(call_zc, AO, AO2, AO3, temp_var1);
            break;
          case 2:
            AO4 = code_generate(AO4, QUANTITY_CONTEXT, -1);
            AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
            if (codegen_action) AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
            if (version_number>=5)
                assemblez_4(call_vn_zc, AO, AO2, AO3, AO4);
            else
            if (version_number==4)
                assemblez_4_to(call_vs_zc, AO, AO2, AO3, AO4, temp_var1);
            else
                assemblez_4(call_zc, AO, AO2, AO3, AO4);
            break;
          case 3:
            AO5 = code_generate(AO5, QUANTITY_CONTEXT, -1);
            AO4 = code_generate(AO4, QUANTITY_CONTEXT, -1);
            AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
            if (codegen_action) AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
            if (version_number>=5)
                assemblez_5(call_vn2_zc, AO, AO2, AO3, AO4, AO5);
            else
            if (version_number==4)
                assemblez_5_to(call_vs2_zc, AO, AO2, AO3, AO4, AO5, temp_var1);
            /* if V3 or earlier, we've already displayed an error */
            break;
            break;
      }

      if (level == 2) assemblez_0(rtrue_zc);

    }
    else {

      AO = veneer_routine(R_Process_VR);

      switch (args) {

      case 0:
        if (codegen_action) 
          AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
        assembleg_call_1(AO, AO2, zero_operand);
        break;

      case 1:
        AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
        if (codegen_action)
          AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
        assembleg_call_2(AO, AO2, AO3, zero_operand);
        break;

      case 2:
        AO4 = code_generate(AO4, QUANTITY_CONTEXT, -1);
        AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
        if (codegen_action) 
          AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
        assembleg_call_3(AO, AO2, AO3, AO4, zero_operand);
        break;

      case 3:
        AO5 = code_generate(AO5, QUANTITY_CONTEXT, -1);
        if (!((AO5.type == LOCALVAR_OT) && (AO5.value == 0)))
            assembleg_store(stack_pointer, AO5);
        AO4 = code_generate(AO4, QUANTITY_CONTEXT, -1);
        if (!((AO4.type == LOCALVAR_OT) && (AO4.value == 0)))
            assembleg_store(stack_pointer, AO4);
        AO3 = code_generate(AO3, QUANTITY_CONTEXT, -1);
        if (!((AO3.type == LOCALVAR_OT) && (AO3.value == 0)))
            assembleg_store(stack_pointer, AO3);
        if (codegen_action) 
          AO2 = code_generate(AO2, QUANTITY_CONTEXT, -1);
        if (!((AO2.type == LOCALVAR_OT) && (AO2.value == 0)))
          assembleg_store(stack_pointer, AO2);
        assembleg_3(call_gc, AO, four_operand, zero_operand);
        break;
      }

      if (level == 2) 
        assembleg_1(return_gc, one_operand);

    }
}

extern int parse_label(void)
{
    get_next_token();

    if ((token_type == SYMBOL_TT) &&
        (stypes[token_value] == LABEL_T))
    {   sflags[token_value] |= USED_SFLAG;
        return(svals[token_value]);
    }

    if ((token_type == SYMBOL_TT) && (sflags[token_value] & UNKNOWN_SFLAG))
    {   assign_symbol(token_value, next_label, LABEL_T);
        define_symbol_label(token_value);
        next_label++;
        sflags[token_value] |= CHANGE_SFLAG + USED_SFLAG;
        return(svals[token_value]);
    }

    ebf_error("label name", token_text);
    return 0;
}

static void parse_print_z(int finally_return)
{   int count = 0; assembly_operand AO;

    /*  print <printlist> -------------------------------------------------- */
    /*  print_ret <printlist> ---------------------------------------------- */
    /*  <literal-string> --------------------------------------------------- */
    /*                                                                       */
    /*  <printlist> is a comma-separated list of items:                      */
    /*                                                                       */
    /*       <literal-string>                                                */
    /*       <other-expression>                                              */
    /*       (char) <expression>                                             */
    /*       (address) <expression>                                          */
    /*       (string) <expression>                                           */
    /*       (a) <expression>                                                */
    /*       (the) <expression>                                              */
    /*       (The) <expression>                                              */
    /*       (name) <expression>                                             */
    /*       (number) <expression>                                           */
    /*       (property) <expression>                                         */
    /*       (<routine>) <expression>                                        */
    /*       (object) <expression>     (for use in low-level code only)      */
    /* --------------------------------------------------------------------- */

    do
    {   AI.text = token_text;
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) break;
        switch(token_type)
        {   case DQ_TT:
              if (strlen(token_text) > 32)
              {   INITAOT(&AO, LONG_CONSTANT_OT);
                  AO.marker = STRING_MV;
                  AO.value  = compile_string(token_text, FALSE, FALSE);
                  assemblez_1(print_paddr_zc, AO);
                  if (finally_return)
                  {   get_next_token();
                      if ((token_type == SEP_TT)
                          && (token_value == SEMICOLON_SEP))
                      {   assemblez_0(new_line_zc);
                          assemblez_0(rtrue_zc);
                          return;
                      }
                      put_token_back();
                  }
                  break;
              }
              if (finally_return)
              {   get_next_token();
                  if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
                  {   assemblez_0(print_ret_zc); return;
                  }
                  put_token_back();
              }
              assemblez_0(print_zc);
              break;

            case SEP_TT:
              if (token_value == OPENB_SEP)
              {   misc_keywords.enabled = TRUE;
                  get_next_token();
                  get_next_token();
                  if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                  {   assembly_operand AO1;

                      put_token_back(); put_token_back();
                      local_variables.enabled = FALSE;
                      get_next_token();
                      misc_keywords.enabled = FALSE;
                      local_variables.enabled = TRUE;

                      if ((token_type == STATEMENT_TT)
                          &&(token_value == STRING_CODE))
                      {   token_type = MISC_KEYWORD_TT;
                          token_value = STRING_MK;
                      }

                      switch(token_type)
                      {
                        case MISC_KEYWORD_TT:
                          switch(token_value)
                          {   case CHAR_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintC_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  assemblez_1(print_char_zc, AO1);
                                  goto PrintTermDone;
                              case ADDRESS_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintA_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  assemblez_1(print_addr_zc, AO1);
                                  goto PrintTermDone;
                              case STRING_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintS_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  assemblez_1(print_paddr_zc, AO1);
                                  goto PrintTermDone;
                              case OBJECT_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintO_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  assemblez_1(print_obj_zc, AO1);
                                  goto PrintTermDone;
                              case THE_MK:
                                  AO = veneer_routine(DefArt_VR);
                                  goto PrintByRoutine;
                              case AN_MK:
                              case A_MK:
                                  AO = veneer_routine(InDefArt_VR);
                                  goto PrintByRoutine;
                              case CAP_THE_MK:
                                  AO = veneer_routine(CDefArt_VR);
                                  goto PrintByRoutine;
                              case CAP_A_MK:
                                  AO = veneer_routine(CInDefArt_VR);
                                  goto PrintByRoutine;
                              case NAME_MK:
                                  AO = veneer_routine(PrintShortName_VR);
                                  goto PrintByRoutine;
                              case NUMBER_MK:
                                  AO = veneer_routine(EnglishNumber_VR);
                                  goto PrintByRoutine;
                              case PROPERTY_MK:
                                  AO = veneer_routine(Print__Pname_VR);
                                  goto PrintByRoutine;
                              default:
               error_named("A reserved word was used as a print specification:",
                                      token_text);
                          }
                          break;

                        case SYMBOL_TT:
                          if (sflags[token_value] & UNKNOWN_SFLAG)
                          {   INITAOT(&AO, LONG_CONSTANT_OT);
                              AO.value = token_value;
                              AO.marker = SYMBOL_MV;
                          }
                          else
                          {   INITAOT(&AO, LONG_CONSTANT_OT);
                              AO.value = svals[token_value];
                              AO.marker = IROUTINE_MV;
                              if (stypes[token_value] != ROUTINE_T)
                                ebf_error("printing routine name", token_text);
                          }
                          sflags[token_value] |= USED_SFLAG;

                          PrintByRoutine:

                          get_next_token();
                          if (version_number >= 5)
                            assemblez_2(call_2n_zc, AO,
                              code_generate(parse_expression(QUANTITY_CONTEXT),
                                QUANTITY_CONTEXT, -1));
                          else if (version_number == 4)
                            assemblez_2_to(call_vs_zc, AO,
                              code_generate(parse_expression(QUANTITY_CONTEXT),
                                QUANTITY_CONTEXT, -1), temp_var1);
                          else
                            assemblez_2_to(call_zc, AO,
                              code_generate(parse_expression(QUANTITY_CONTEXT),
                                QUANTITY_CONTEXT, -1), temp_var1);
                          goto PrintTermDone;

                        default: ebf_error("print specification", token_text);
                          get_next_token();
                          assemblez_1(print_num_zc,
                          code_generate(parse_expression(QUANTITY_CONTEXT),
                                QUANTITY_CONTEXT, -1));
                          goto PrintTermDone;
                      }
                  }
                  put_token_back(); put_token_back(); put_token_back();
                  misc_keywords.enabled = FALSE;
                  assemblez_1(print_num_zc,
                      code_generate(parse_expression(QUANTITY_CONTEXT),
                          QUANTITY_CONTEXT, -1));
                  break;
              }

            default:
              put_token_back(); misc_keywords.enabled = FALSE;
              assemblez_1(print_num_zc,
                  code_generate(parse_expression(QUANTITY_CONTEXT),
                      QUANTITY_CONTEXT, -1));
              break;
        }

        PrintTermDone: misc_keywords.enabled = FALSE;

        count++;
        get_next_token();
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) break;
        if ((token_type != SEP_TT) || (token_value != COMMA_SEP))
        {   ebf_error("comma", token_text);
            panic_mode_error_recovery(); return;
        }
        else get_next_token();
    } while(TRUE);

    if (count == 0) ebf_error("something to print", token_text);
    if (finally_return)
    {   assemblez_0(new_line_zc);
        assemblez_0(rtrue_zc);
    }
}

static void parse_print_g(int finally_return)
{   int count = 0; assembly_operand AO, AO2;

    /*  print <printlist> -------------------------------------------------- */
    /*  print_ret <printlist> ---------------------------------------------- */
    /*  <literal-string> --------------------------------------------------- */
    /*                                                                       */
    /*  <printlist> is a comma-separated list of items:                      */
    /*                                                                       */
    /*       <literal-string>                                                */
    /*       <other-expression>                                              */
    /*       (char) <expression>                                             */
    /*       (address) <expression>                                          */
    /*       (string) <expression>                                           */
    /*       (a) <expression>                                                */
    /*       (A) <expression>                                                */
    /*       (the) <expression>                                              */
    /*       (The) <expression>                                              */
    /*       (name) <expression>                                             */
    /*       (number) <expression>                                           */
    /*       (property) <expression>                                         */
    /*       (<routine>) <expression>                                        */
    /*       (object) <expression>     (for use in low-level code only)      */
    /* --------------------------------------------------------------------- */

    do
    {   
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) break;
        switch(token_type)
        {   case DQ_TT:
              /* We can't compile a string into the instruction,
                 so this always goes into the string area. */
              {   INITAOT(&AO, CONSTANT_OT);
                  AO.marker = STRING_MV;
                  AO.value  = compile_string(token_text, FALSE, FALSE);
                  assembleg_1(streamstr_gc, AO);
                  if (finally_return)
                  {   get_next_token();
                      if ((token_type == SEP_TT)
                          && (token_value == SEMICOLON_SEP))
                      {   INITAOTV(&AO, BYTECONSTANT_OT, 0x0A);
                          assembleg_1(streamchar_gc, AO); 
                          INITAOTV(&AO, BYTECONSTANT_OT, 1);
                          assembleg_1(return_gc, AO); 
                          return;
                      }
                      put_token_back();
                  }
                  break;
              }
              break;

            case SEP_TT:
              if (token_value == OPENB_SEP)
              {   misc_keywords.enabled = TRUE;
                  get_next_token();
                  get_next_token();
                  if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                  {   assembly_operand AO1;
                      int ln, ln2;

                      put_token_back(); put_token_back();
                      local_variables.enabled = FALSE;
                      get_next_token();
                      misc_keywords.enabled = FALSE;
                      local_variables.enabled = TRUE;

                      if ((token_type == STATEMENT_TT)
                          &&(token_value == STRING_CODE))
                      {   token_type = MISC_KEYWORD_TT;
                          token_value = STRING_MK;
                      }

                      switch(token_type)
                      {
                        case MISC_KEYWORD_TT:
                          switch(token_value)
                          {   case CHAR_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintC_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  if ((AO1.type == LOCALVAR_OT) && (AO1.value == 0))
                                  {   assembleg_2(stkpeek_gc, zero_operand, 
                                      stack_pointer);
                                  }
                                  INITAOTV(&AO2, HALFCONSTANT_OT, 0x100);
                                  assembleg_2_branch(jgeu_gc, AO1, AO2, 
                                      ln = next_label++);
                                  ln2 = next_label++;
                                  assembleg_1(streamchar_gc, AO1);
                                  assembleg_jump(ln2);
                                  assemble_label_no(ln);
                                  assembleg_1(streamunichar_gc, AO1);
                                  assemble_label_no(ln2);
                                  goto PrintTermDone;
                              case ADDRESS_MK:
                                  if (runtime_error_checking_switch)
                                      AO = veneer_routine(RT__ChPrintA_VR);
                                  else
                                      AO = veneer_routine(Print__Addr_VR);
                                  goto PrintByRoutine;
                              case STRING_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintS_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  assembleg_1(streamstr_gc, AO1);
                                  goto PrintTermDone;
                              case OBJECT_MK:
                                  if (runtime_error_checking_switch)
                                  {   AO = veneer_routine(RT__ChPrintO_VR);
                                      goto PrintByRoutine;
                                  }
                                  get_next_token();
                                  AO1 = code_generate(
                                      parse_expression(QUANTITY_CONTEXT),
                                      QUANTITY_CONTEXT, -1);
                                  INITAOT(&AO2, BYTECONSTANT_OT);
                                  AO2.value = GOBJFIELD_NAME();
                                  assembleg_3(aload_gc, AO1, AO2, 
                                    stack_pointer);
                                  assembleg_1(streamstr_gc, stack_pointer);
                                  goto PrintTermDone;
                              case THE_MK:
                                  AO = veneer_routine(DefArt_VR);
                                  goto PrintByRoutine;
                              case AN_MK:
                              case A_MK:
                                  AO = veneer_routine(InDefArt_VR);
                                  goto PrintByRoutine;
                              case CAP_THE_MK:
                                  AO = veneer_routine(CDefArt_VR);
                                  goto PrintByRoutine;
                              case CAP_A_MK:
                                  AO = veneer_routine(CInDefArt_VR);
                                  goto PrintByRoutine;
                              case NAME_MK:
                                  AO = veneer_routine(PrintShortName_VR);
                                  goto PrintByRoutine;
                              case NUMBER_MK:
                                  AO = veneer_routine(EnglishNumber_VR);
                                  goto PrintByRoutine;
                              case PROPERTY_MK:
                                  AO = veneer_routine(Print__Pname_VR);
                                  goto PrintByRoutine;
                              default:
               error_named("A reserved word was used as a print specification:",
                                      token_text);
                          }
                          break;

                        case SYMBOL_TT:
                          if (sflags[token_value] & UNKNOWN_SFLAG)
                          {   INITAOT(&AO, CONSTANT_OT);
                              AO.value = token_value;
                              AO.marker = SYMBOL_MV;
                          }
                          else
                          {   INITAOT(&AO, CONSTANT_OT);
                              AO.value = svals[token_value];
                              AO.marker = IROUTINE_MV;
                              if (stypes[token_value] != ROUTINE_T)
                                ebf_error("printing routine name", token_text);
                          }
                          sflags[token_value] |= USED_SFLAG;

                          PrintByRoutine:

                          get_next_token();
                          INITAOT(&AO2, ZEROCONSTANT_OT);
                          assembleg_call_1(AO,
                            code_generate(parse_expression(QUANTITY_CONTEXT),
                              QUANTITY_CONTEXT, -1),
                            AO2);
                          goto PrintTermDone;

                        default: ebf_error("print specification", token_text);
                          get_next_token();
                          assembleg_1(streamnum_gc,
                          code_generate(parse_expression(QUANTITY_CONTEXT),
                                QUANTITY_CONTEXT, -1));
                          goto PrintTermDone;
                      }
                  }
                  put_token_back(); put_token_back(); put_token_back();
                  misc_keywords.enabled = FALSE;
                  assembleg_1(streamnum_gc,
                      code_generate(parse_expression(QUANTITY_CONTEXT),
                          QUANTITY_CONTEXT, -1));
                  break;
              }

            default:
              put_token_back(); misc_keywords.enabled = FALSE;
              assembleg_1(streamnum_gc,
                  code_generate(parse_expression(QUANTITY_CONTEXT),
                      QUANTITY_CONTEXT, -1));
              break;
        }

        PrintTermDone: misc_keywords.enabled = FALSE;

        count++;
        get_next_token();
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) break;
        if ((token_type != SEP_TT) || (token_value != COMMA_SEP))
        {   ebf_error("comma", token_text);
            panic_mode_error_recovery(); return;
        }
        else get_next_token();
    } while(TRUE);

    if (count == 0) ebf_error("something to print", token_text);
    if (finally_return)
    {
        INITAOTV(&AO, BYTECONSTANT_OT, 0x0A);
        assembleg_1(streamchar_gc, AO); 
        INITAOTV(&AO, BYTECONSTANT_OT, 1);
        assembleg_1(return_gc, AO); 
    }
}

static void parse_statement_z(int break_label, int continue_label)
{   int ln, ln2, ln3, ln4, flag;
    assembly_operand AO, AO2, AO3, AO4;
    debug_location spare_debug_location1, spare_debug_location2;

    ASSERT_ZCODE();

    if ((token_type == SEP_TT) && (token_value == PROPERTY_SEP))
    {   /*  That is, a full stop, signifying a label  */

        get_next_token();
        if (token_type == SYMBOL_TT)
        {
            if (sflags[token_value] & UNKNOWN_SFLAG)
            {   assign_symbol(token_value, next_label, LABEL_T);
                sflags[token_value] |= USED_SFLAG;
                assemble_label_no(next_label);
                define_symbol_label(token_value);
                next_label++;
            }
            else
            {   if (stypes[token_value] != LABEL_T) goto LabelError;
                if (sflags[token_value] & CHANGE_SFLAG)
                {   sflags[token_value] &= (~(CHANGE_SFLAG));
                    assemble_label_no(svals[token_value]);
                    define_symbol_label(token_value);
                }
                else error_named("Duplicate definition of label:", token_text);
            }

            get_next_token();
            if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
            {   ebf_error("';'", token_text);
                put_token_back(); return;
            }

            /*  Interesting point of Inform grammar: a statement can only
                consist solely of a label when it is immediately followed
                by a "}".                                                    */

            get_next_token();
            if ((token_type == SEP_TT) && (token_value == CLOSE_BRACE_SEP))
            {   put_token_back(); return;
            }
            statement_debug_location = get_token_location();
            parse_statement(break_label, continue_label);
            return;
        }
        LabelError: ebf_error("label name", token_text);
    }

    if ((token_type == SEP_TT) && (token_value == HASH_SEP))
    {   parse_directive(TRUE);
        parse_statement(break_label, continue_label); return;
    }

    if ((token_type == SEP_TT) && (token_value == AT_SEP))
    {   parse_assembly(); return;
    }

    if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) return;

    if (token_type == DQ_TT)
    {   parse_print_z(TRUE); return;
    }

    if ((token_type == SEP_TT) && (token_value == LESS_SEP))
    {   parse_action(); goto StatementTerminator; }

    if (token_type == EOF_TT)
    {   ebf_error("statement", token_text); return; }

    if (token_type != STATEMENT_TT)
    {   put_token_back();
        AO = parse_expression(VOID_CONTEXT);
        code_generate(AO, VOID_CONTEXT, -1);
        if (vivc_flag) { panic_mode_error_recovery(); return; }
        goto StatementTerminator;
    }

    statements.enabled = FALSE;

    switch(token_value)
    {
    /*  -------------------------------------------------------------------- */
    /*  box <string-1> ... <string-n> -------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case BOX_CODE:
             if (version_number == 3)
                 warning("The 'box' statement has no effect in a version 3 game");
             INITAOT(&AO3, LONG_CONSTANT_OT);
                 AO3.value = begin_table_array();
                 AO3.marker = ARRAY_MV;
                 ln = 0; ln2 = 0;
                 do
                 {   get_next_token();
                     if ((token_type==SEP_TT)&&(token_value==SEMICOLON_SEP))
                         break;
                     if (token_type != DQ_TT)
                         ebf_error("text of box line in double-quotes",
                             token_text);
                     {   int i, j;
                         for (i=0, j=0; token_text[i] != 0; j++)
                             if (token_text[i] == '@')
                             {   if (token_text[i+1] == '@')
                                 {   i = i + 2;
                                     while (isdigit(token_text[i])) i++;
                                 }
                                 else
                                 {   i++;
                                     if (token_text[i] != 0) i++;
                                     if (token_text[i] != 0) i++;
                                 }
                             }
                             else i++;
                         if (j > ln2) ln2 = j;
                     }
                     put_token_back();
                     array_entry(ln++,parse_expression(CONSTANT_CONTEXT));
                 } while (TRUE);
                 finish_array(ln);
                 if (ln == 0)
                     error("No lines of text given for 'box' display");

                 if (version_number == 3) return;

                 INITAOTV(&AO2, SHORT_CONSTANT_OT, ln2);
                 INITAOTV(&AO4, VARIABLE_OT, 255);
                 assemblez_3_to(call_vs_zc, veneer_routine(Box__Routine_VR),
                     AO2, AO3, AO4);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  break -------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case BREAK_CODE:
                 if (break_label == -1)
                 error("'break' can only be used in a loop or 'switch' block");
                 else
                     assemblez_jump(break_label);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  continue ----------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case CONTINUE_CODE:
                 if (continue_label == -1)
                 error("'continue' can only be used in a loop block");
                 else
                     assemblez_jump(continue_label);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  do <codeblock> until (<condition>) --------------------------------- */
    /*  -------------------------------------------------------------------- */

        case DO_CODE:
                 assemble_label_no(ln = next_label++);
                 ln2 = next_label++; ln3 = next_label++;
                 parse_code_block(ln3, ln2, 0);
                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT)
                     && (token_value == UNTIL_CODE))
                 {   assemble_label_no(ln2);
                     match_open_bracket();
                     AO = parse_expression(CONDITION_CONTEXT);
                     match_close_bracket();
                     code_generate(AO, CONDITION_CONTEXT, ln);
                 }
                 else error("'do' without matching 'until'");

                 assemble_label_no(ln3);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  font on/off -------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case FONT_CODE:
                 misc_keywords.enabled = TRUE;
                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || ((token_value != ON_MK)
                         && (token_value != OFF_MK)))
                 {   ebf_error("'on' or 'off'", token_text);
                     panic_mode_error_recovery();
                     break;
                 }

                 if (version_number >= 5)
                 {   /* Use the V5 @set_font opcode, setting font 4
                        (for font off) or 1 (for font on). */
                     INITAOT(&AO, SHORT_CONSTANT_OT);
                     if (token_value == ON_MK)
                         AO.value = 1;
                     else
                         AO.value = 4;
                     assemblez_1_to(set_font_zc, AO, temp_var1);
                     break;
                 }

                 /* Set the fixed-pitch header bit. */
                 INITAOTV(&AO, SHORT_CONSTANT_OT, 0);
                 INITAOTV(&AO2, SHORT_CONSTANT_OT, 8);
                 INITAOTV(&AO3, VARIABLE_OT, 255);
                 assemblez_2_to(loadw_zc, AO, AO2, AO3);

                 if (token_value == ON_MK)
                 {   INITAOTV(&AO4, LONG_CONSTANT_OT, 0xfffd);
                     assemblez_2_to(and_zc, AO4, AO3, AO3);
                 }
                 else
                 {   INITAOTV(&AO4, SHORT_CONSTANT_OT, 2);
                     assemblez_2_to(or_zc, AO4, AO3, AO3);
                 }

                 assemblez_3(storew_zc, AO, AO2, AO3);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  for (<initialisation> : <continue-condition> : <updating>) --------- */
    /*  -------------------------------------------------------------------- */

        /*  Note that it's legal for any or all of the three sections of a
            'for' specification to be empty.  This 'for' implementation
            often wastes 3 bytes with a redundant branch rather than keep
            expression parse trees for long periods (as previous versions
            of Inform did, somewhat crudely by simply storing the textual
            form of a 'for' loop).  It is adequate for now.                  */

        case FOR_CODE:
                 match_open_bracket();
                 get_next_token();

                 /*  Initialisation code  */

                 if (!((token_type==SEP_TT)&&(token_value==COLON_SEP)))
                 {   put_token_back();
                     if (!((token_type==SEP_TT)&&(token_value==SUPERCLASS_SEP)))
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = get_token_location();
                         code_generate(parse_expression(FORINIT_CONTEXT),
                             VOID_CONTEXT, -1);
                     }
                     get_next_token();
                     if ((token_type==SEP_TT)&&(token_value == SUPERCLASS_SEP))
                     {   get_next_token();
                         if ((token_type==SEP_TT)&&(token_value == CLOSEB_SEP))
                         {   assemble_label_no(ln = next_label++);
                             ln2 = next_label++;
                             parse_code_block(ln2, ln, 0);
                             sequence_point_follows = FALSE;
                             if (!execution_never_reaches_here)
                                 assemblez_jump(ln);
                             assemble_label_no(ln2);
                             return;
                         }
                         AO.type = OMITTED_OT;
                         goto ParseUpdate;
                     }
                     put_token_back();
                     if (!match_colon()) break;
                 }

                 get_next_token();
                 AO.type = OMITTED_OT;
                 if (!((token_type==SEP_TT)&&(token_value==COLON_SEP)))
                 {   put_token_back();
                     spare_debug_location1 = get_token_location();
                     AO = parse_expression(CONDITION_CONTEXT);
                     if (!match_colon()) break;
                 }
                 get_next_token();

                 ParseUpdate:
                 AO2.type = OMITTED_OT; flag = 0;
                 if (!((token_type==SEP_TT)&&(token_value==CLOSEB_SEP)))
                 {   put_token_back();
                     spare_debug_location2 = get_token_location();
                     AO2 = parse_expression(VOID_CONTEXT);
                     match_close_bracket();
                     flag = test_for_incdec(AO2);
                 }

                 ln = next_label++;
                 ln2 = next_label++;
                 ln3 = next_label++;

                 if ((AO2.type == OMITTED_OT) || (flag != 0))
                 {
                     assemble_label_no(ln);
                     if (flag==0) assemble_label_no(ln2);

                     /*  The "finished yet?" condition  */

                     if (AO.type != OMITTED_OT)
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = spare_debug_location1;
                         code_generate(AO, CONDITION_CONTEXT, ln3);
                     }

                 }
                 else
                 {
                     /*  This is the jump which could be avoided with the aid
                         of long-term expression storage  */

                     sequence_point_follows = FALSE;
                     assemblez_jump(ln2);

                     /*  The "update" part  */

                     assemble_label_no(ln);
                     sequence_point_follows = TRUE;
                     statement_debug_location = spare_debug_location2;
                     code_generate(AO2, VOID_CONTEXT, -1);

                     assemble_label_no(ln2);

                     /*  The "finished yet?" condition  */

                     if (AO.type != OMITTED_OT)
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = spare_debug_location1;
                         code_generate(AO, CONDITION_CONTEXT, ln3);
                     }
                 }

                 if (flag != 0)
                 {
                     /*  In this optimised case, update code is at the end
                         of the loop block, so "continue" goes there  */

                     parse_code_block(ln3, ln2, 0);
                     assemble_label_no(ln2);

                     sequence_point_follows = TRUE;
                     statement_debug_location = spare_debug_location2;
                     if (flag > 0)
                     {   INITAOTV(&AO3, SHORT_CONSTANT_OT, flag);
                         if (module_switch
                             && (flag>=MAX_LOCAL_VARIABLES) && (flag<LOWEST_SYSTEM_VAR_NUMBER))
                             AO3.marker = VARIABLE_MV;
                         assemblez_1(inc_zc, AO3);
                     }
                     else
                     {   INITAOTV(&AO3, SHORT_CONSTANT_OT, -flag);
                         if ((module_switch) && (flag>=MAX_LOCAL_VARIABLES)
                             && (flag<LOWEST_SYSTEM_VAR_NUMBER))
                             AO3.marker = VARIABLE_MV;
                         assemblez_1(dec_zc, AO3);
                     }
                     assemblez_jump(ln);
                 }
                 else
                 {
                     /*  In the unoptimised case, update code is at the
                         start of the loop block, so "continue" goes there  */

                     parse_code_block(ln3, ln, 0);
                     if (!execution_never_reaches_here)
                     {   sequence_point_follows = FALSE;
                         assemblez_jump(ln);
                     }
                 }

                 assemble_label_no(ln3);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  give <expression> [~]attr [, [~]attr [, ...]] ---------------------- */
    /*  -------------------------------------------------------------------- */

        case GIVE_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                          QUANTITY_CONTEXT, -1);
                 if ((AO.type == VARIABLE_OT) && (AO.value == 0))
                 {   INITAOTV(&AO, SHORT_CONSTANT_OT, 252);
                     if (version_number != 6) assemblez_1(pull_zc, AO);
                     else assemblez_0_to(pull_zc, AO);
                     AO.type = VARIABLE_OT;
                 }

                 do
                 {   get_next_token();
                     if ((token_type == SEP_TT)&&(token_value == SEMICOLON_SEP))
                         return;
                     if ((token_type == SEP_TT)&&(token_value == ARTNOT_SEP))
                         ln = clear_attr_zc;
                     else
                     {   if ((token_type == SYMBOL_TT)
                             && (stypes[token_value] != ATTRIBUTE_T))
                           warning_named("This is not a declared Attribute:",
                             token_text);
                         ln = set_attr_zc;
                         put_token_back();
                     }
                     AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                               QUANTITY_CONTEXT, -1);
                     if (runtime_error_checking_switch)
                     {   ln2 = (ln==set_attr_zc)?RT__ChG_VR:RT__ChGt_VR;
                         if (version_number >= 5)
                             assemblez_3(call_vn_zc, veneer_routine(ln2),
                             AO, AO2);
                         else
                         {   
                             assemblez_3_to(call_zc, veneer_routine(ln2),
                                 AO, AO2, temp_var1);
                         }
                     }
                     else
                         assemblez_2(ln, AO, AO2);
                 } while(TRUE);

    /*  -------------------------------------------------------------------- */
    /*  if (<condition>) <codeblock> [else <codeblock>] -------------------- */
    /*  -------------------------------------------------------------------- */

        case IF_CODE:
                 flag = FALSE;
                 ln2 = 0;

                 match_open_bracket();
                 AO = parse_expression(CONDITION_CONTEXT);
                 match_close_bracket();

                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT)&&(token_value == RTRUE_CODE))
                     ln = -4;
                 else
                 if ((token_type == STATEMENT_TT)&&(token_value == RFALSE_CODE))
                     ln = -3;
                 else
                 {   put_token_back();
                     ln = next_label++;
                 }

                 code_generate(AO, CONDITION_CONTEXT, ln);

                 if (ln >= 0) parse_code_block(break_label, continue_label, 0);
                 else
                 {   get_next_token();
                     if ((token_type != SEP_TT)
                         || (token_value != SEMICOLON_SEP))
                     {   ebf_error("';'", token_text);
                         put_token_back();
                     }
                 }

                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT) && (token_value == ELSE_CODE))
                 {   flag = TRUE;
                     if (ln >= 0)
                     {   ln2 = next_label++;
                         if (!execution_never_reaches_here)
                         {   sequence_point_follows = FALSE;
                             assemblez_jump(ln2);
                         }
                     }
                 }
                 else put_token_back();

                 if (ln >= 0) assemble_label_no(ln);

                 if (flag)
                 {   parse_code_block(break_label, continue_label, 0);
                     if (ln >= 0) assemble_label_no(ln2);
                 }

                 return;

    /*  -------------------------------------------------------------------- */
    /*  inversion ---------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case INVERSION_CODE:
                 INITAOTV(&AO, SHORT_CONSTANT_OT, 0);
                 INITAOT(&AO2, SHORT_CONSTANT_OT);

                 AO2.value  = 60;
                 assemblez_2_to(loadb_zc, AO, AO2, temp_var1);
                 assemblez_1(print_char_zc, temp_var1);
                 AO2.value  = 61;
                 assemblez_2_to(loadb_zc, AO, AO2, temp_var1);
                 assemblez_1(print_char_zc, temp_var1);
                 AO2.value  = 62;
                 assemblez_2_to(loadb_zc, AO, AO2, temp_var1);
                 assemblez_1(print_char_zc, temp_var1);
                 AO2.value  = 63;
                 assemblez_2_to(loadb_zc, AO, AO2, temp_var1);
                 assemblez_1(print_char_zc, temp_var1);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  jump <label> ------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case JUMP_CODE:
                 assemblez_jump(parse_label());
                 break;

    /*  -------------------------------------------------------------------- */
    /*  move <expression> to <expression> ---------------------------------- */
    /*  -------------------------------------------------------------------- */

        case MOVE_CODE:
                 misc_keywords.enabled = TRUE;
                 AO = parse_expression(QUANTITY_CONTEXT);

                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || (token_value != TO_MK))
                 {   ebf_error("'to'", token_text);
                     panic_mode_error_recovery();
                     return;
                 }

                 AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 AO = code_generate(AO, QUANTITY_CONTEXT, -1);
                 if ((runtime_error_checking_switch) && (veneer_mode == FALSE))
                 {   if (version_number >= 5)
                         assemblez_3(call_vn_zc, veneer_routine(RT__ChT_VR),
                             AO, AO2);
                     else
                     {   assemblez_3_to(call_zc, veneer_routine(RT__ChT_VR),
                             AO, AO2, temp_var1);
                     }
                 }
                 else
                     assemblez_2(insert_obj_zc, AO, AO2);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  new_line ----------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case NEW_LINE_CODE:  assemblez_0(new_line_zc); break;

    /*  -------------------------------------------------------------------- */
    /*  objectloop (<initialisation>) <codeblock> -------------------------- */
    /*  -------------------------------------------------------------------- */

        case OBJECTLOOP_CODE:

                 match_open_bracket();
                 get_next_token();
                 INITAOT(&AO, VARIABLE_OT);
                 if (token_type == LOCAL_VARIABLE_TT)
                     AO.value = token_value;
                 else
                 if ((token_type == SYMBOL_TT) &&
                     (stypes[token_value] == GLOBAL_VARIABLE_T))
                     AO.value = svals[token_value];
                 else
                 {   ebf_error("'objectloop' variable", token_text);
                     panic_mode_error_recovery(); break;
                 }
                 if ((module_switch) && (AO.value >= MAX_LOCAL_VARIABLES)
                     && (AO.value < LOWEST_SYSTEM_VAR_NUMBER))
                     AO.marker = VARIABLE_MV;
                 misc_keywords.enabled = TRUE;
                 get_next_token(); flag = TRUE;
                 misc_keywords.enabled = FALSE;
                 if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                     flag = FALSE;

                 ln = 0;
                 if ((token_type == MISC_KEYWORD_TT)
                     && (token_value == NEAR_MK)) ln = 1;
                 if ((token_type == MISC_KEYWORD_TT)
                     && (token_value == FROM_MK)) ln = 2;
                 if ((token_type == CND_TT) && (token_value == IN_COND))
                 {   get_next_token();
                     get_next_token();
                     if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                         ln = 3;
                     put_token_back();
                     put_token_back();
                 }

                 if (ln > 0)
                 {   /*  Old style (Inform 5) objectloops: note that we
                         implement objectloop (a in b) in the old way since
                         this runs through objects in a different order from
                         the new way, and there may be existing Inform code
                         relying on this.                                    */
                     assembly_operand AO4;
                     INITAO(&AO4);

                     sequence_point_follows = TRUE;
                     AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                         QUANTITY_CONTEXT, -1);
                     match_close_bracket();
                     if (ln == 1)
                     {   INITAOTV(&AO3, VARIABLE_OT, 0);
                         if (runtime_error_checking_switch)
                                 AO2 = check_nonzero_at_runtime(AO2, -1,
                                     OBJECTLOOP_RTE);
                         assemblez_1_to(get_parent_zc, AO2, AO3);
                         assemblez_objcode(get_child_zc, AO3, AO3, -2, TRUE);
                         AO2 = AO3;
                     }
                     if (ln == 3)
                     {   INITAOTV(&AO3, VARIABLE_OT, 0);
                         if (runtime_error_checking_switch)
                         {   AO4 = AO2;
                             AO2 = check_nonzero_at_runtime(AO2, -1,
                                 CHILD_RTE);
                         }
                         assemblez_objcode(get_child_zc, AO2, AO3, -2, TRUE);
                         AO2 = AO3;
                     }
                     assemblez_store(AO, AO2);
                     assemblez_1_branch(jz_zc, AO, ln2 = next_label++, TRUE);
                     assemble_label_no(ln4 = next_label++);
                     parse_code_block(ln2, ln3 = next_label++, 0);
                     sequence_point_follows = FALSE;
                     assemble_label_no(ln3);
                     if (runtime_error_checking_switch)
                     {   AO2 = check_nonzero_at_runtime(AO, ln2,
                              OBJECTLOOP2_RTE);
                         if ((ln == 3)
                             && ((AO4.type != VARIABLE_OT)||(AO4.value != 0))
                             && ((AO4.type != VARIABLE_OT)
                                 ||(AO4.value != AO.value)))
                         {   assembly_operand en_ao;
                             INITAOTV(&en_ao, SHORT_CONSTANT_OT, OBJECTLOOP_BROKEN_RTE);
                             assemblez_2_branch(jin_zc, AO, AO4,
                                 next_label, TRUE);
                             assemblez_3(call_vn_zc, veneer_routine(RT__Err_VR),
                                 en_ao, AO);
                             assemblez_jump(ln2);
                             assemble_label_no(next_label++);
                         }
                     }
                     else AO2 = AO;
                     assemblez_objcode(get_sibling_zc, AO2, AO, ln4, TRUE);
                     assemble_label_no(ln2);
                     return;
                 }

                 sequence_point_follows = TRUE;
                 INITAOTV(&AO2, SHORT_CONSTANT_OT, 1);
                 assemblez_store(AO, AO2);

                 assemble_label_no(ln = next_label++);
                 ln2 = next_label++;
                 ln3 = next_label++;
                 if (flag)
                 {   put_token_back();
                     put_token_back();
                     sequence_point_follows = TRUE;
                     code_generate(parse_expression(CONDITION_CONTEXT),
                         CONDITION_CONTEXT, ln3);
                     match_close_bracket();
                 }
                 parse_code_block(ln2, ln3, 0);

                 sequence_point_follows = FALSE;
                 assemble_label_no(ln3);
                 assemblez_inc(AO);
                 INITAOTV(&AO2, LONG_CONSTANT_OT, no_objects);
                 AO2.marker = NO_OBJS_MV;
                 assemblez_2_branch(jg_zc, AO, AO2, ln2, TRUE);
                 assemblez_jump(ln);
                 assemble_label_no(ln2);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  (see routine above) ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case PRINT_CODE:
            get_next_token();
            parse_print_z(FALSE); return;
        case PRINT_RET_CODE:
            get_next_token();
            parse_print_z(TRUE); return;

    /*  -------------------------------------------------------------------- */
    /*  quit --------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case QUIT_CODE:      assemblez_0(quit_zc); break;

    /*  -------------------------------------------------------------------- */
    /*  read <expression> <expression> [<Routine>] ------------------------- */
    /*  -------------------------------------------------------------------- */

        case READ_CODE:
                 INITAOTV(&AO, VARIABLE_OT, 252);
                 assemblez_store(AO,
                     code_generate(parse_expression(QUANTITY_CONTEXT),
                                   QUANTITY_CONTEXT, -1));
                 if (version_number > 3)
                 {   INITAOTV(&AO3, SHORT_CONSTANT_OT, 1);
                     INITAOTV(&AO4, SHORT_CONSTANT_OT, 0);
                     assemblez_3(storeb_zc, AO, AO3, AO4);
                 }
                 AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                           QUANTITY_CONTEXT, -1);

                 get_next_token();
                 if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
                     put_token_back();
                 else
                 {   if (version_number == 3)
                         error(
"In Version 3 no status-line drawing routine can be given");
                     else
                     {   assembly_operand AO5;
                         /* Move the temp4 (buffer) value to the stack,
                            since the routine might alter temp4. */
                         assemblez_store(stack_pointer, AO);
                         AO = stack_pointer;
                         put_token_back();
                         AO5 = parse_expression(CONSTANT_CONTEXT);

                         if (version_number >= 5)
                             assemblez_1(call_1n_zc, AO5);
                         else
                             assemblez_1_to(call_zc, AO5, temp_var1);
                     }
                 }

                 if (version_number > 4)
                 {   assemblez_2_to(aread_zc, AO, AO2, temp_var1);
                 }
                 else assemblez_2(sread_zc, AO, AO2);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  remove <expression> ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case REMOVE_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 if ((runtime_error_checking_switch) && (veneer_mode == FALSE))
                 {   if (version_number >= 5)
                         assemblez_2(call_2n_zc, veneer_routine(RT__ChR_VR),
                             AO);
                     else
                     {   assemblez_2_to(call_zc, veneer_routine(RT__ChR_VR),
                             AO, temp_var1);
                     }
                 }
                 else
                     assemblez_1(remove_obj_zc, AO);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  restore <label> ---------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RESTORE_CODE:
                 if (version_number < 5)
                     assemblez_0_branch(restore_zc, parse_label(), TRUE);
                 else
                 {   INITAOTV(&AO2, SHORT_CONSTANT_OT, 2);
                     assemblez_0_to(restore_zc, temp_var1);
                     assemblez_2_branch(je_zc, temp_var1, AO2, parse_label(), TRUE);
                 }
                 break;

    /*  -------------------------------------------------------------------- */
    /*  return [<expression>] ---------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RETURN_CODE:
                 get_next_token();
                 if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
                 {   assemblez_0(rtrue_zc); return; }
                 put_token_back();
                 AO = code_generate(parse_expression(RETURN_Q_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 if ((AO.type == SHORT_CONSTANT_OT) && (AO.value == 0)
                     && (AO.marker == 0))
                 {   assemblez_0(rfalse_zc); break; }
                 if ((AO.type == SHORT_CONSTANT_OT) && (AO.value == 1)
                     && (AO.marker == 0))
                 {   assemblez_0(rtrue_zc); break; }
                 if ((AO.type == VARIABLE_OT) && (AO.value == 0))
                 {   assemblez_0(ret_popped_zc); break; }
                 assemblez_1(ret_zc, AO);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  rfalse ------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RFALSE_CODE:  assemblez_0(rfalse_zc); break;

    /*  -------------------------------------------------------------------- */
    /*  rtrue -------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RTRUE_CODE:   assemblez_0(rtrue_zc); break;

    /*  -------------------------------------------------------------------- */
    /*  save <label> ------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case SAVE_CODE:
                 if (version_number < 5)
                     assemblez_0_branch(save_zc, parse_label(), TRUE);
                 else
                 {   INITAOTV(&AO, VARIABLE_OT, 255);
                     assemblez_0_to(save_zc, AO);
                     assemblez_1_branch(jz_zc, AO, parse_label(), FALSE);
                 }
                 break;

    /*  -------------------------------------------------------------------- */
    /*  spaces <expression> ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case SPACES_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 INITAOTV(&AO2, VARIABLE_OT, 255);

                 assemblez_store(AO2, AO);

                 INITAOTV(&AO, SHORT_CONSTANT_OT, 32);
                 INITAOTV(&AO3, SHORT_CONSTANT_OT, 1);

                 assemblez_2_branch(jl_zc, AO2, AO3, ln = next_label++, TRUE);
                 assemble_label_no(ln2 = next_label++);
                 assemblez_1(print_char_zc, AO);
                 assemblez_dec(AO2);
                 assemblez_1_branch(jz_zc, AO2, ln2, FALSE);
                 assemble_label_no(ln);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  string <expression> <literal-string> ------------------------------- */
    /*  -------------------------------------------------------------------- */

        case STRING_CODE:
                 INITAOTV(&AO, SHORT_CONSTANT_OT, 0);
                 INITAOTV(&AO2, SHORT_CONSTANT_OT, 12);
                 INITAOTV(&AO3, VARIABLE_OT, 252);
                 assemblez_2_to(loadw_zc, AO, AO2, AO3);
                 AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 get_next_token();
                 if (token_type == DQ_TT)
                 {   INITAOT(&AO4, LONG_CONSTANT_OT);
                     AO4.value = compile_string(token_text, TRUE, TRUE);
                 }
                 else
                 {   put_token_back();
                     AO4 = parse_expression(CONSTANT_CONTEXT);
                 }
                 assemblez_3(storew_zc, AO3, AO2, AO4);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  style roman/reverse/bold/underline/fixed --------------------------- */
    /*  -------------------------------------------------------------------- */

        case STYLE_CODE:
                 if (version_number==3)
                 {   error(
"The 'style' statement cannot be used for Version 3 games");
                     panic_mode_error_recovery();
                     break;
                 }

                 misc_keywords.enabled = TRUE;
                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || ((token_value != ROMAN_MK)
                         && (token_value != REVERSE_MK)
                         && (token_value != BOLD_MK)
                         && (token_value != UNDERLINE_MK)
                         && (token_value != FIXED_MK)))
                 {   ebf_error(
"'roman', 'bold', 'underline', 'reverse' or 'fixed'",
                         token_text);
                     panic_mode_error_recovery();
                     break;
                 }

                 INITAOT(&AO, SHORT_CONSTANT_OT);
                 switch(token_value)
                 {   case ROMAN_MK: AO.value = 0; break;
                     case REVERSE_MK: AO.value = 1; break;
                     case BOLD_MK: AO.value = 2; break;
                     case UNDERLINE_MK: AO.value = 4; break;
                     case FIXED_MK: AO.value = 8; break;
                 }
                 assemblez_1(set_text_style_zc, AO); break;

    /*  -------------------------------------------------------------------- */
    /*  switch (<expression>) <codeblock> ---------------------------------- */
    /*  -------------------------------------------------------------------- */

        case SWITCH_CODE:
                 match_open_bracket();
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 match_close_bracket();

                 INITAOTV(&AO2, VARIABLE_OT, 255);
                 assemblez_store(AO2, AO);

                 parse_code_block(ln = next_label++, continue_label, 1);
                 assemble_label_no(ln);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  while (<condition>) <codeblock> ------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case WHILE_CODE:
                 assemble_label_no(ln = next_label++);
                 match_open_bracket();

                 code_generate(parse_expression(CONDITION_CONTEXT),
                     CONDITION_CONTEXT, ln2 = next_label++);
                 match_close_bracket();

                 parse_code_block(ln2, ln, 0);
                 sequence_point_follows = FALSE;
                 assemblez_jump(ln);
                 assemble_label_no(ln2);
                 return;

    /*  -------------------------------------------------------------------- */

        case SDEFAULT_CODE:
                 error("'default' without matching 'switch'"); break;
        case ELSE_CODE:
                 error("'else' without matching 'if'"); break;
        case UNTIL_CODE:
                 error("'until' without matching 'do'");
                 panic_mode_error_recovery(); return;
    }

    StatementTerminator:

    get_next_token();
    if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
    {   ebf_error("';'", token_text);
        put_token_back();
    }
}

static void parse_statement_g(int break_label, int continue_label)
{   int ln, ln2, ln3, ln4, flag, onstack;
    assembly_operand AO, AO2, AO3, AO4;
    debug_location spare_debug_location1, spare_debug_location2;

    ASSERT_GLULX();

    if ((token_type == SEP_TT) && (token_value == PROPERTY_SEP))
    {   /*  That is, a full stop, signifying a label  */

        get_next_token();
        if (token_type == SYMBOL_TT)
        {
            if (sflags[token_value] & UNKNOWN_SFLAG)
            {   assign_symbol(token_value, next_label, LABEL_T);
                sflags[token_value] |= USED_SFLAG;
                assemble_label_no(next_label);
                define_symbol_label(token_value);
                next_label++;
            }
            else
            {   if (stypes[token_value] != LABEL_T) goto LabelError;
                if (sflags[token_value] & CHANGE_SFLAG)
                {   sflags[token_value] &= (~(CHANGE_SFLAG));
                    assemble_label_no(svals[token_value]);
                    define_symbol_label(token_value);
                }
                else error_named("Duplicate definition of label:", token_text);
            }

            get_next_token();
            if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
            {   ebf_error("';'", token_text);
                put_token_back(); return;
            }

            /*  Interesting point of Inform grammar: a statement can only
                consist solely of a label when it is immediately followed
                by a "}".                                                    */

            get_next_token();
            if ((token_type == SEP_TT) && (token_value == CLOSE_BRACE_SEP))
            {   put_token_back(); return;
            }
            /* The following line prevents labels from influencing the positions
               of sequence points. */
            statement_debug_location = get_token_location();
            parse_statement(break_label, continue_label);
            return;
        }
        LabelError: ebf_error("label name", token_text);
    }

    if ((token_type == SEP_TT) && (token_value == HASH_SEP))
    {   parse_directive(TRUE);
        parse_statement(break_label, continue_label); return;
    }

    if ((token_type == SEP_TT) && (token_value == AT_SEP))
    {   parse_assembly(); return;
    }

    if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) return;

    if (token_type == DQ_TT)
    {   parse_print_g(TRUE); return;
    }

    if ((token_type == SEP_TT) && (token_value == LESS_SEP))
    {   parse_action(); goto StatementTerminator; }

    if (token_type == EOF_TT)
    {   ebf_error("statement", token_text); return; }

    if (token_type != STATEMENT_TT)
    {   put_token_back();
        AO = parse_expression(VOID_CONTEXT);
        code_generate(AO, VOID_CONTEXT, -1);
        if (vivc_flag) { panic_mode_error_recovery(); return; }
        goto StatementTerminator;
    }

    statements.enabled = FALSE;

    switch(token_value)
    {

    /*  -------------------------------------------------------------------- */
    /*  box <string-1> ... <string-n> -------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case BOX_CODE:
            INITAOT(&AO3, CONSTANT_OT);
                 AO3.value = begin_table_array();
                 AO3.marker = ARRAY_MV;
                 ln = 0; ln2 = 0;
                 do
                 {   get_next_token();
                     if ((token_type==SEP_TT)&&(token_value==SEMICOLON_SEP))
                         break;
                     if (token_type != DQ_TT)
                         ebf_error("text of box line in double-quotes",
                             token_text);
                     {   int i, j;
                         for (i=0, j=0; token_text[i] != 0; j++)
                             if (token_text[i] == '@')
                             {   if (token_text[i+1] == '@')
                                 {   i = i + 2;
                                     while (isdigit(token_text[i])) i++;
                                 }
                                 else
                                 {   i++;
                                     if (token_text[i] != 0) i++;
                                     if (token_text[i] != 0) i++;
                                 }
                             }
                             else i++;
                         if (j > ln2) ln2 = j;
                     }
                     put_token_back();
                     array_entry(ln++,parse_expression(CONSTANT_CONTEXT));
                 } while (TRUE);
                 finish_array(ln);
                 if (ln == 0)
                     error("No lines of text given for 'box' display");

                 INITAO(&AO2);
                 AO2.value = ln2; set_constant_ot(&AO2);
                 assembleg_call_2(veneer_routine(Box__Routine_VR),
                     AO2, AO3, zero_operand);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  break -------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case BREAK_CODE:
                 if (break_label == -1)
                 error("'break' can only be used in a loop or 'switch' block");
                 else
                     assembleg_jump(break_label);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  continue ----------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case CONTINUE_CODE:
                 if (continue_label == -1)
                 error("'continue' can only be used in a loop block");
                 else
                     assembleg_jump(continue_label);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  do <codeblock> until (<condition>) --------------------------------- */
    /*  -------------------------------------------------------------------- */

        case DO_CODE:
                 assemble_label_no(ln = next_label++);
                 ln2 = next_label++; ln3 = next_label++;
                 parse_code_block(ln3, ln2, 0);
                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT)
                     && (token_value == UNTIL_CODE))
                 {   assemble_label_no(ln2);
                     match_open_bracket();
                     AO = parse_expression(CONDITION_CONTEXT);
                     match_close_bracket();
                     code_generate(AO, CONDITION_CONTEXT, ln);
                 }
                 else error("'do' without matching 'until'");

                 assemble_label_no(ln3);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  font on/off -------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case FONT_CODE:
                 misc_keywords.enabled = TRUE;
                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || ((token_value != ON_MK)
                         && (token_value != OFF_MK)))
                 {   ebf_error("'on' or 'off'", token_text);
                     panic_mode_error_recovery();
                     break;
                 }

                 /* Call glk_set_style(normal or preformatted) */
                 INITAO(&AO);
                 AO.value = 0x0086;
                 set_constant_ot(&AO);
                 if (token_value == ON_MK)
                   AO2 = zero_operand;
                 else 
                   AO2 = two_operand;
                 assembleg_call_2(veneer_routine(Glk__Wrap_VR), 
                   AO, AO2, zero_operand);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  for (<initialisation> : <continue-condition> : <updating>) --------- */
    /*  -------------------------------------------------------------------- */

        /*  Note that it's legal for any or all of the three sections of a
            'for' specification to be empty.  This 'for' implementation
            often wastes 3 bytes with a redundant branch rather than keep
            expression parse trees for long periods (as previous versions
            of Inform did, somewhat crudely by simply storing the textual
            form of a 'for' loop).  It is adequate for now.                  */

        case FOR_CODE:
                 match_open_bracket();
                 get_next_token();

                 /*  Initialisation code  */

                 if (!((token_type==SEP_TT)&&(token_value==COLON_SEP)))
                 {   put_token_back();
                     if (!((token_type==SEP_TT)&&(token_value==SUPERCLASS_SEP)))
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = get_token_location();
                         code_generate(parse_expression(FORINIT_CONTEXT),
                             VOID_CONTEXT, -1);
                     }
                     get_next_token();
                     if ((token_type==SEP_TT)&&(token_value == SUPERCLASS_SEP))
                     {   get_next_token();
                         if ((token_type==SEP_TT)&&(token_value == CLOSEB_SEP))
                         {   assemble_label_no(ln = next_label++);
                             ln2 = next_label++;
                             parse_code_block(ln2, ln, 0);
                             sequence_point_follows = FALSE;
                             if (!execution_never_reaches_here)
                                 assembleg_jump(ln);
                             assemble_label_no(ln2);
                             return;
                         }
                         AO.type = OMITTED_OT;
                         goto ParseUpdate;
                     }
                     put_token_back();
                     if (!match_colon()) break;
                 }

                 get_next_token();
                 AO.type = OMITTED_OT;
                 if (!((token_type==SEP_TT)&&(token_value==COLON_SEP)))
                 {   put_token_back();
                     spare_debug_location1 = get_token_location();
                     AO = parse_expression(CONDITION_CONTEXT);
                     if (!match_colon()) break;
                 }
                 get_next_token();

                 ParseUpdate:
                 AO2.type = OMITTED_OT; flag = 0;
                 if (!((token_type==SEP_TT)&&(token_value==CLOSEB_SEP)))
                 {   put_token_back();
                     spare_debug_location2 = get_token_location();
                     AO2 = parse_expression(VOID_CONTEXT);
                     match_close_bracket();
                     flag = test_for_incdec(AO2);
                 }

                 ln = next_label++;
                 ln2 = next_label++;
                 ln3 = next_label++;

                 if ((AO2.type == OMITTED_OT) || (flag != 0))
                 {
                     assemble_label_no(ln);
                     if (flag==0) assemble_label_no(ln2);

                     /*  The "finished yet?" condition  */

                     if (AO.type != OMITTED_OT)
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = spare_debug_location1;
                         code_generate(AO, CONDITION_CONTEXT, ln3);
                     }

                 }
                 else
                 {
                     /*  This is the jump which could be avoided with the aid
                         of long-term expression storage  */

                     sequence_point_follows = FALSE;
                     assembleg_jump(ln2);

                     /*  The "update" part  */

                     assemble_label_no(ln);
                     sequence_point_follows = TRUE;
                     statement_debug_location = spare_debug_location2;
                     code_generate(AO2, VOID_CONTEXT, -1);

                     assemble_label_no(ln2);

                     /*  The "finished yet?" condition  */

                     if (AO.type != OMITTED_OT)
                     {   sequence_point_follows = TRUE;
                         statement_debug_location = spare_debug_location1;
                         code_generate(AO, CONDITION_CONTEXT, ln3);
                     }
                 }

                 if (flag != 0)
                 {
                     /*  In this optimised case, update code is at the end
                         of the loop block, so "continue" goes there  */

                     parse_code_block(ln3, ln2, 0);
                     assemble_label_no(ln2);

                     sequence_point_follows = TRUE;
                     statement_debug_location = spare_debug_location2;
                     if (flag > 0)
                     {   INITAO(&AO3);
                         AO3.value = flag;
                         if (AO3.value >= MAX_LOCAL_VARIABLES)
                           AO3.type = GLOBALVAR_OT;
                         else
                           AO3.type = LOCALVAR_OT;
                         assembleg_3(add_gc, AO3, one_operand, AO3);
                     }
                     else
                     {   INITAO(&AO3);
                         AO3.value = -flag;
                         if (AO3.value >= MAX_LOCAL_VARIABLES)
                           AO3.type = GLOBALVAR_OT;
                         else
                           AO3.type = LOCALVAR_OT;
                         assembleg_3(sub_gc, AO3, one_operand, AO3);
                     }
                     assembleg_jump(ln);
                 }
                 else
                 {
                     /*  In the unoptimised case, update code is at the
                         start of the loop block, so "continue" goes there  */

                     parse_code_block(ln3, ln, 0);
                     if (!execution_never_reaches_here)
                     {   sequence_point_follows = FALSE;
                         assembleg_jump(ln);
                     }
                 }

                 assemble_label_no(ln3);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  give <expression> [~]attr [, [~]attr [, ...]] ---------------------- */
    /*  -------------------------------------------------------------------- */

        case GIVE_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                          QUANTITY_CONTEXT, -1);
                 if ((AO.type == LOCALVAR_OT) && (AO.value == 0))
                     onstack = TRUE;
                 else
                     onstack = FALSE;

                 do
                 {   get_next_token();
                     if ((token_type == SEP_TT) 
                       && (token_value == SEMICOLON_SEP)) {
                         if (onstack) {
                           assembleg_2(copy_gc, stack_pointer, zero_operand);
                         }
                         return;
                     }
                     if ((token_type == SEP_TT)&&(token_value == ARTNOT_SEP))
                         ln = 0;
                     else
                     {   if ((token_type == SYMBOL_TT)
                             && (stypes[token_value] != ATTRIBUTE_T))
                           warning_named("This is not a declared Attribute:",
                             token_text);
                         ln = 1;
                         put_token_back();
                     }
                     AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                               QUANTITY_CONTEXT, -1);
                     if (runtime_error_checking_switch && (!veneer_mode))
                     {   ln2 = (ln ? RT__ChG_VR : RT__ChGt_VR);
                         if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0)) {
                           /* already on stack */
                         }
                         else {
                           assembleg_store(stack_pointer, AO2);
                         }
                         if (onstack)
                           assembleg_2(stkpeek_gc, one_operand, stack_pointer);
                         else
                           assembleg_store(stack_pointer, AO);
                         assembleg_3(call_gc, veneer_routine(ln2), two_operand,
                           zero_operand);
                     }
                     else {
                         if (is_constant_ot(AO2.type) && AO2.marker == 0) {
                           AO2.value += 8;
                           set_constant_ot(&AO2);
                         }
                         else {
                           INITAOTV(&AO3, BYTECONSTANT_OT, 8);
                           assembleg_3(add_gc, AO2, AO3, stack_pointer);
                           AO2 = stack_pointer;
                         }
                         if (onstack) {
                           if ((AO2.type == LOCALVAR_OT) && (AO2.value == 0))
                             assembleg_2(stkpeek_gc, one_operand, 
                               stack_pointer);
                           else
                             assembleg_2(stkpeek_gc, zero_operand, 
                               stack_pointer);
                         }
                         if (ln) 
                           AO3 = one_operand;
                         else
                           AO3 = zero_operand;
                         assembleg_3(astorebit_gc, AO, AO2, AO3);
                     }
                 } while(TRUE);

    /*  -------------------------------------------------------------------- */
    /*  if (<condition>) <codeblock> [else <codeblock>] -------------------- */
    /*  -------------------------------------------------------------------- */

        case IF_CODE:
                 flag = FALSE;
                 ln2 = 0;

                 match_open_bracket();
                 AO = parse_expression(CONDITION_CONTEXT);
                 match_close_bracket();

                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT)&&(token_value == RTRUE_CODE))
                     ln = -4;
                 else
                 if ((token_type == STATEMENT_TT)&&(token_value == RFALSE_CODE))
                     ln = -3;
                 else
                 {   put_token_back();
                     ln = next_label++;
                 }

                 code_generate(AO, CONDITION_CONTEXT, ln);

                 if (ln >= 0) parse_code_block(break_label, continue_label, 0);
                 else
                 {   get_next_token();
                     if ((token_type != SEP_TT)
                         || (token_value != SEMICOLON_SEP))
                     {   ebf_error("';'", token_text);
                         put_token_back();
                     }
                 }

                 statements.enabled = TRUE;
                 get_next_token();
                 if ((token_type == STATEMENT_TT) && (token_value == ELSE_CODE))
                 {   flag = TRUE;
                     if (ln >= 0)
                     {   ln2 = next_label++;
                         if (!execution_never_reaches_here)
                         {   sequence_point_follows = FALSE;
                             assembleg_jump(ln2);
                         }
                     }
                 }
                 else put_token_back();

                 if (ln >= 0) assemble_label_no(ln);

                 if (flag)
                 {   parse_code_block(break_label, continue_label, 0);
                     if (ln >= 0) assemble_label_no(ln2);
                 }

                 return;

    /*  -------------------------------------------------------------------- */
    /*  inversion ---------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case INVERSION_CODE:
                 INITAOTV(&AO2, DEREFERENCE_OT, GLULX_HEADER_SIZE+8);
                 assembleg_2(copyb_gc, AO2, stack_pointer);
                 assembleg_1(streamchar_gc, stack_pointer);
                 AO2.value  = GLULX_HEADER_SIZE+9; 
                 assembleg_2(copyb_gc, AO2, stack_pointer);
                 assembleg_1(streamchar_gc, stack_pointer);
                 AO2.value  = GLULX_HEADER_SIZE+10; 
                 assembleg_2(copyb_gc, AO2, stack_pointer);
                 assembleg_1(streamchar_gc, stack_pointer);
                 AO2.value  = GLULX_HEADER_SIZE+11; 
                 assembleg_2(copyb_gc, AO2, stack_pointer);
                 assembleg_1(streamchar_gc, stack_pointer);

                 if (/* DISABLES CODE */ (0)) {
                     INITAO(&AO);
                     AO.value = '(';
                     set_constant_ot(&AO);
                     assembleg_1(streamchar_gc, AO);
                     AO.value = 'G';
                     set_constant_ot(&AO);
                     assembleg_1(streamchar_gc, AO);

                     AO2.value  = GLULX_HEADER_SIZE+12; 
                     assembleg_2(copyb_gc, AO2, stack_pointer);
                     assembleg_1(streamchar_gc, stack_pointer);
                     AO2.value  = GLULX_HEADER_SIZE+13; 
                     assembleg_2(copyb_gc, AO2, stack_pointer);
                     assembleg_1(streamchar_gc, stack_pointer);
                     AO2.value  = GLULX_HEADER_SIZE+14; 
                     assembleg_2(copyb_gc, AO2, stack_pointer);
                     assembleg_1(streamchar_gc, stack_pointer);
                     AO2.value  = GLULX_HEADER_SIZE+15; 
                     assembleg_2(copyb_gc, AO2, stack_pointer);
                     assembleg_1(streamchar_gc, stack_pointer);

                     AO.marker = 0;
                     AO.value = ')';
                     set_constant_ot(&AO);
                     assembleg_1(streamchar_gc, AO);
                 }

                 break;

    /*  -------------------------------------------------------------------- */
    /*  jump <label> ------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case JUMP_CODE:
                 assembleg_jump(parse_label());
                 break;

    /*  -------------------------------------------------------------------- */
    /*  move <expression> to <expression> ---------------------------------- */
    /*  -------------------------------------------------------------------- */

        case MOVE_CODE:
                 misc_keywords.enabled = TRUE;
                 AO = parse_expression(QUANTITY_CONTEXT);

                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || (token_value != TO_MK))
                 {   ebf_error("'to'", token_text);
                     panic_mode_error_recovery();
                     return;
                 }

                 AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 AO = code_generate(AO, QUANTITY_CONTEXT, -1);
                 if ((runtime_error_checking_switch) && (veneer_mode == FALSE))
                     assembleg_call_2(veneer_routine(RT__ChT_VR), AO, AO2,
                         zero_operand);
                 else
                     assembleg_call_2(veneer_routine(OB__Move_VR), AO, AO2,
                         zero_operand);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  new_line ----------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case NEW_LINE_CODE:  
              INITAOTV(&AO, BYTECONSTANT_OT, 0x0A);
              assembleg_1(streamchar_gc, AO); 
              break;

    /*  -------------------------------------------------------------------- */
    /*  objectloop (<initialisation>) <codeblock> -------------------------- */
    /*  -------------------------------------------------------------------- */

        case OBJECTLOOP_CODE:

                 match_open_bracket();
                 get_next_token();
                 if (token_type == LOCAL_VARIABLE_TT) {
                     INITAOTV(&AO, LOCALVAR_OT, token_value);
                 }
                 else if ((token_type == SYMBOL_TT) &&
                   (stypes[token_value] == GLOBAL_VARIABLE_T)) {
                     INITAOTV(&AO, GLOBALVAR_OT, svals[token_value]);
                 }
                 else {
                     ebf_error("'objectloop' variable", token_text);
                     panic_mode_error_recovery(); 
                     break;
                 }
                 misc_keywords.enabled = TRUE;
                 get_next_token(); flag = TRUE;
                 misc_keywords.enabled = FALSE;
                 if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                     flag = FALSE;

                 ln = 0;
                 if ((token_type == MISC_KEYWORD_TT)
                     && (token_value == NEAR_MK)) ln = 1;
                 if ((token_type == MISC_KEYWORD_TT)
                     && (token_value == FROM_MK)) ln = 2;
                 if ((token_type == CND_TT) && (token_value == IN_COND))
                 {   get_next_token();
                     get_next_token();
                     if ((token_type == SEP_TT) && (token_value == CLOSEB_SEP))
                         ln = 3;
                     put_token_back();
                     put_token_back();
                 }

                 if (ln != 0) {
                   /*  Old style (Inform 5) objectloops: note that we
                       implement objectloop (a in b) in the old way since
                       this runs through objects in a different order from
                       the new way, and there may be existing Inform code
                       relying on this.                                    */
                     assembly_operand AO4, AO5;
                     INITAO(&AO5);

                     sequence_point_follows = TRUE;
                     AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                         QUANTITY_CONTEXT, -1);
                     match_close_bracket();
                     if (ln == 1) {
                         if (runtime_error_checking_switch)
                             AO2 = check_nonzero_at_runtime(AO2, -1,
                                 OBJECTLOOP_RTE);
                         INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_PARENT());
                         assembleg_3(aload_gc, AO2, AO4, stack_pointer);
                         INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_CHILD());
                         assembleg_3(aload_gc, stack_pointer, AO4, stack_pointer);
                         AO2 = stack_pointer;
                     }
                     else if (ln == 3) {
                         if (runtime_error_checking_switch) {
                             AO5 = AO2;
                             AO2 = check_nonzero_at_runtime(AO2, -1,
                                 CHILD_RTE);
                         }
                         INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_CHILD());
                         assembleg_3(aload_gc, AO2, AO4, stack_pointer);
                         AO2 = stack_pointer;
                     }
                     else {
                         /* do nothing */
                     }
                     assembleg_store(AO, AO2);
                     assembleg_1_branch(jz_gc, AO, ln2 = next_label++);
                     assemble_label_no(ln4 = next_label++);
                     parse_code_block(ln2, ln3 = next_label++, 0);
                     sequence_point_follows = FALSE;
                     assemble_label_no(ln3);
                     if (runtime_error_checking_switch) {
                         AO2 = check_nonzero_at_runtime(AO, ln2,
                              OBJECTLOOP2_RTE);
                         if ((ln == 3)
                             && ((AO5.type != LOCALVAR_OT)||(AO5.value != 0))
                             && ((AO5.type != LOCALVAR_OT)||(AO5.value != AO.value)))
                         {   assembly_operand en_ao;
                             INITAO(&en_ao);
                             en_ao.value = OBJECTLOOP_BROKEN_RTE;
                             set_constant_ot(&en_ao);
                             INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_PARENT());
                             assembleg_3(aload_gc, AO, AO4, stack_pointer);
                             assembleg_2_branch(jeq_gc, stack_pointer, AO5, 
                                 next_label);
                             assembleg_call_2(veneer_routine(RT__Err_VR),
                                 en_ao, AO, zero_operand);
                             assembleg_jump(ln2);
                             assemble_label_no(next_label++);
                         }
                     }
                     else {
                         AO2 = AO;
                     }
                     INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_SIBLING());
                     assembleg_3(aload_gc, AO2, AO4, AO);
                     assembleg_1_branch(jnz_gc, AO, ln4);
                     assemble_label_no(ln2);
                     return;
                 }

                 sequence_point_follows = TRUE;
                 ln = symbol_index("Class", -1);
                 INITAOT(&AO2, CONSTANT_OT);
                 AO2.value = svals[ln];
                 AO2.marker = OBJECT_MV;
                 assembleg_store(AO, AO2);

                 assemble_label_no(ln = next_label++);
                 ln2 = next_label++;
                 ln3 = next_label++;
                 if (flag)
                 {   put_token_back();
                     put_token_back();
                     sequence_point_follows = TRUE;
                     code_generate(parse_expression(CONDITION_CONTEXT),
                         CONDITION_CONTEXT, ln3);
                     match_close_bracket();
                 }
                 parse_code_block(ln2, ln3, 0);

                 sequence_point_follows = FALSE;
                 assemble_label_no(ln3);
                 INITAOTV(&AO4, BYTECONSTANT_OT, GOBJFIELD_CHAIN());
                 assembleg_3(aload_gc, AO, AO4, AO);
                 assembleg_1_branch(jnz_gc, AO, ln);
                 assemble_label_no(ln2);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  (see routine above) ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case PRINT_CODE:
            get_next_token();
            parse_print_g(FALSE); return;
        case PRINT_RET_CODE:
            get_next_token();
            parse_print_g(TRUE); return;

    /*  -------------------------------------------------------------------- */
    /*  quit --------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case QUIT_CODE:
                 assembleg_0(quit_gc); break;

    /*  -------------------------------------------------------------------- */
    /*  remove <expression> ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case REMOVE_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 if ((runtime_error_checking_switch) && (veneer_mode == FALSE))
                     assembleg_call_1(veneer_routine(RT__ChR_VR), AO,
                         zero_operand);
                 else
                     assembleg_call_1(veneer_routine(OB__Remove_VR), AO,
                         zero_operand);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  return [<expression>] ---------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RETURN_CODE:
          get_next_token();
          if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) {
            assembleg_1(return_gc, one_operand); 
            return; 
          }
          put_token_back();
          AO = code_generate(parse_expression(RETURN_Q_CONTEXT),
            QUANTITY_CONTEXT, -1);
          assembleg_1(return_gc, AO);
          break;

    /*  -------------------------------------------------------------------- */
    /*  rfalse ------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RFALSE_CODE:   
          assembleg_1(return_gc, zero_operand); 
          break;

    /*  -------------------------------------------------------------------- */
    /*  rtrue -------------------------------------------------------------- */
    /*  -------------------------------------------------------------------- */

        case RTRUE_CODE:   
          assembleg_1(return_gc, one_operand); 
          break;

    /*  -------------------------------------------------------------------- */
    /*  spaces <expression> ------------------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case SPACES_CODE:
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);

                 assembleg_store(temp_var1, AO);

                 INITAO(&AO);
                 AO.value = 32; set_constant_ot(&AO);

                 assembleg_2_branch(jlt_gc, temp_var1, one_operand, 
                     ln = next_label++);
                 assemble_label_no(ln2 = next_label++);
                 assembleg_1(streamchar_gc, AO);
                 assembleg_dec(temp_var1);
                 assembleg_1_branch(jnz_gc, temp_var1, ln2);
                 assemble_label_no(ln);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  string <expression> <literal-string> ------------------------------- */
    /*  -------------------------------------------------------------------- */

        case STRING_CODE:
                 AO2 = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 get_next_token();
                 if (token_type == DQ_TT)
                 {   INITAOT(&AO4, CONSTANT_OT);
                     AO4.value = compile_string(token_text, TRUE, TRUE);
                     AO4.marker = STRING_MV;
                 }
                 else
                 {   put_token_back();
                     AO4 = parse_expression(CONSTANT_CONTEXT);
                 }
                 assembleg_call_2(veneer_routine(Dynam__String_VR),
                   AO2, AO4, zero_operand);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  style roman/reverse/bold/underline/fixed --------------------------- */
    /*  -------------------------------------------------------------------- */

        case STYLE_CODE:
                 misc_keywords.enabled = TRUE;
                 get_next_token();
                 misc_keywords.enabled = FALSE;
                 if ((token_type != MISC_KEYWORD_TT)
                     || ((token_value != ROMAN_MK)
                         && (token_value != REVERSE_MK)
                         && (token_value != BOLD_MK)
                         && (token_value != UNDERLINE_MK)
                         && (token_value != FIXED_MK)))
                 {   ebf_error(
"'roman', 'bold', 'underline', 'reverse' or 'fixed'",
                         token_text);
                     panic_mode_error_recovery();
                     break;
                 }

                 /* Call glk_set_style() */

                 INITAO(&AO);
                 AO.value = 0x0086;
                 set_constant_ot(&AO);
                 switch(token_value)
                 {   case ROMAN_MK:
                     default: 
                         AO2 = zero_operand; /* normal */
                         break;
                     case REVERSE_MK: 
                         INITAO(&AO2);
                         AO2.value = 5; /* alert */
                         set_constant_ot(&AO2);
                         break;
                     case BOLD_MK: 
                         INITAO(&AO2);
                         AO2.value = 4; /* subheader */
                         set_constant_ot(&AO2);
                         break;
                     case UNDERLINE_MK: 
                         AO2 = one_operand; /* emphasized */
                         break;
                     case FIXED_MK: 
                         AO2 = two_operand; /* preformatted */
                         break;
                 }
                 assembleg_call_2(veneer_routine(Glk__Wrap_VR), 
                   AO, AO2, zero_operand);
                 break;

    /*  -------------------------------------------------------------------- */
    /*  switch (<expression>) <codeblock> ---------------------------------- */
    /*  -------------------------------------------------------------------- */

        case SWITCH_CODE:
                 match_open_bracket();
                 AO = code_generate(parse_expression(QUANTITY_CONTEXT),
                     QUANTITY_CONTEXT, -1);
                 match_close_bracket();

                 assembleg_store(temp_var1, AO); 

                 parse_code_block(ln = next_label++, continue_label, 1);
                 assemble_label_no(ln);
                 return;

    /*  -------------------------------------------------------------------- */
    /*  while (<condition>) <codeblock> ------------------------------------ */
    /*  -------------------------------------------------------------------- */

        case WHILE_CODE:
                 assemble_label_no(ln = next_label++);
                 match_open_bracket();

                 code_generate(parse_expression(CONDITION_CONTEXT),
                     CONDITION_CONTEXT, ln2 = next_label++);
                 match_close_bracket();

                 parse_code_block(ln2, ln, 0);
                 sequence_point_follows = FALSE;
                 assembleg_jump(ln);
                 assemble_label_no(ln2);
                 return;

    /*  -------------------------------------------------------------------- */

        case SDEFAULT_CODE:
                 error("'default' without matching 'switch'"); break;
        case ELSE_CODE:
                 error("'else' without matching 'if'"); break;
        case UNTIL_CODE:
                 error("'until' without matching 'do'");
                 panic_mode_error_recovery(); return;

    /*  -------------------------------------------------------------------- */

    /* And a useful default, which will never be triggered in a complete
       Inform compiler, but which is important in development. */

        default:
          error("*** Statement code gen: Can't generate yet ***\n");
          panic_mode_error_recovery(); return;
    }

    StatementTerminator:

    get_next_token();
    if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
    {   ebf_error("';'", token_text);
        put_token_back();
    }
}

extern void parse_statement(int break_label, int continue_label)
{
  if (!glulx_mode)
    parse_statement_z(break_label, continue_label);
  else
    parse_statement_g(break_label, continue_label);
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_states_vars(void)
{
}

extern void states_begin_pass(void)
{
}

extern void states_allocate_arrays(void)
{
}

extern void states_free_arrays(void)
{
}

/* ========================================================================= */
