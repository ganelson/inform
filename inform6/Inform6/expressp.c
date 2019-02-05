/* ------------------------------------------------------------------------- */
/*   "expressp" :  The expression parser                                     */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

/* --- Interface to lexer -------------------------------------------------- */

static char separators_to_operators[103];
static char conditionals_to_operators[7];
static char token_type_allowable[301];

#define NOT_AN_OPERATOR (char) 0x7e

static void make_lexical_interface_tables(void)
{   int i;
    for (i=0;i<103;i++)
        separators_to_operators[i] = NOT_AN_OPERATOR;
    for (i=0;i<NUM_OPERATORS;i++)
        if (operators[i].token_type == SEP_TT)
            separators_to_operators[operators[i].token_value] = i;

    for (i=0;i<7;i++)  /*  7 being the size of keyword_group "conditions"  */
        conditionals_to_operators[i] = NOT_AN_OPERATOR;
    for (i=0;i<NUM_OPERATORS;i++)
        if (operators[i].token_type == CND_TT)
            conditionals_to_operators[operators[i].token_value] = i;

    for (i=0;i<301;i++) token_type_allowable[i] = 0;

    token_type_allowable[VARIABLE_TT] = 1;
    token_type_allowable[SYSFUN_TT] = 1;
    token_type_allowable[DQ_TT] = 1;
    token_type_allowable[DICTWORD_TT] = 1;
    token_type_allowable[SUBOPEN_TT] = 1;
    token_type_allowable[SUBCLOSE_TT] = 1;
    token_type_allowable[SMALL_NUMBER_TT] = 1;
    token_type_allowable[LARGE_NUMBER_TT] = 1;
    token_type_allowable[ACTION_TT] = 1;
    token_type_allowable[SYSTEM_CONSTANT_TT] = 1;
    token_type_allowable[OP_TT] = 1;
}

static token_data current_token, previous_token, heldback_token;

static int comma_allowed, arrow_allowed, superclass_allowed,
           bare_prop_allowed,
           array_init_ambiguity, action_ambiguity,
           etoken_count, inserting_token, bracket_level;

extern int *variable_usage;

int system_function_usage[32];

static int get_next_etoken(void)
{   int v, symbol = 0, mark_symbol_as_used = FALSE,
        initial_bracket_level = bracket_level;

    etoken_count++;

    if (inserting_token)
    {   current_token = heldback_token;
        inserting_token = FALSE;
    }
    else
    {   get_next_token();
        current_token.text = token_text;
        current_token.value = token_value;
        current_token.type = token_type;
        current_token.marker = 0;
        current_token.symtype = 0;
        current_token.symflags = -1;
    }

    switch(current_token.type)
    {   case LOCAL_VARIABLE_TT:
            current_token.type = VARIABLE_TT;
            variable_usage[current_token.value] = TRUE;
            break;

        case DQ_TT:
            current_token.marker = STRING_MV;
            break;

        case SQ_TT:
            {   int32 unicode = text_to_unicode(token_text);
                if (token_text[textual_form_length] == 0)
                {
                    if (!glulx_mode) {
                        current_token.value = unicode_to_zscii(unicode);
                        if (current_token.value == 5)
                        {   unicode_char_error("Character can be printed \
but not used as a value:", unicode);
                            current_token.value = '?';
                        }
                        if (current_token.value >= 0x100)
                            current_token.type = LARGE_NUMBER_TT;
                        else current_token.type = SMALL_NUMBER_TT;
                    }
                    else {
                        current_token.value = unicode;
                        if (current_token.value >= 0x8000
                          || current_token.value < -0x8000) 
                            current_token.type = LARGE_NUMBER_TT;
                        else current_token.type = SMALL_NUMBER_TT;
                    }
                }
                else
                {   current_token.type = DICTWORD_TT;
                    current_token.marker = DWORD_MV;
                }
            }
            break;

        case SYMBOL_TT:
        ReceiveSymbol:
            symbol = current_token.value;

            mark_symbol_as_used = TRUE;

            v = svals[symbol];

            current_token.symtype = stypes[symbol];
            current_token.symflags = sflags[symbol];
            switch(stypes[symbol])
            {   case ROUTINE_T:
                    current_token.marker = IROUTINE_MV;
                    break;
                case GLOBAL_VARIABLE_T:
                    current_token.marker = VARIABLE_MV;
                    break;
                case OBJECT_T:
                case CLASS_T:
                    /* All objects must be backpatched in Glulx. */
                    if (module_switch || glulx_mode)
                        current_token.marker = OBJECT_MV;
                    break;
                case ARRAY_T:
                    current_token.marker = ARRAY_MV;
                    break;
                case INDIVIDUAL_PROPERTY_T:
                    if (module_switch) current_token.marker = IDENT_MV;
                    break;
                case CONSTANT_T:
                    if (sflags[symbol] & (UNKNOWN_SFLAG + CHANGE_SFLAG))
                    {   current_token.marker = SYMBOL_MV;
                        if (module_switch) import_symbol(symbol);
                        v = symbol;
                    }
                    else current_token.marker = 0;
                    break;
                case LABEL_T:
                    error_named("Label name used as value:", token_text);
                    break;
                default:
                    current_token.marker = 0;
                    break;
            }
            if (sflags[symbol] & SYSTEM_SFLAG)
                current_token.marker = 0;

            current_token.value = v;

            if (!glulx_mode) {
                if (((current_token.marker != 0)
                  && (current_token.marker != VARIABLE_MV))
                  || (v < 0) || (v > 255))
                    current_token.type = LARGE_NUMBER_TT;
                else current_token.type = SMALL_NUMBER_TT;
            }
            else {
                if (((current_token.marker != 0)
                  && (current_token.marker != VARIABLE_MV))
                  || (v < -0x8000) || (v >= 0x8000)) 
                    current_token.type = LARGE_NUMBER_TT;
                else current_token.type = SMALL_NUMBER_TT;
            }

            if (stypes[symbol] == GLOBAL_VARIABLE_T)
            {   current_token.type = VARIABLE_TT;
                variable_usage[current_token.value] = TRUE;
            }
            break;

        case NUMBER_TT:
            if (!glulx_mode) {
                if (current_token.value >= 256)
                    current_token.type = LARGE_NUMBER_TT;
                else
                    current_token.type = SMALL_NUMBER_TT;
            }
            else {
                if (current_token.value < -0x8000 
                  || current_token.value >= 0x8000)
                    current_token.type = LARGE_NUMBER_TT;
                else
                    current_token.type = SMALL_NUMBER_TT;
            }
            break;

        case SEP_TT:
            switch(current_token.value)
            {   case ARROW_SEP:
                    if (!arrow_allowed)
                        current_token.type = ENDEXP_TT;
                    break;

                case COMMA_SEP:
                    if ((bracket_level==0) && (!comma_allowed))
                        current_token.type = ENDEXP_TT;
                    break;

                case SUPERCLASS_SEP:
                    if ((bracket_level==0) && (!superclass_allowed))
                        current_token.type = ENDEXP_TT;
                    break;

                case GREATER_SEP:
                    get_next_token();
                    if ((token_type == SEP_TT)
                        &&((token_value == SEMICOLON_SEP)
                           || (token_value == GREATER_SEP)))
                        current_token.type = ENDEXP_TT;
                    put_token_back();
                    break;

                case OPENB_SEP:
                    bracket_level++;
                    if (expr_trace_level>=3)
                    { printf("Previous token type = %d\n",previous_token.type);
                      printf("Previous token val  = %d\n",previous_token.value);
                    }
                    if ((previous_token.type == OP_TT)
                        || (previous_token.type == SUBOPEN_TT)
                        || (previous_token.type == ENDEXP_TT)
                        || (array_init_ambiguity)
                        || ((bracket_level == 1) && (action_ambiguity)))
                        current_token.type = SUBOPEN_TT;
                    else
                    {   inserting_token = TRUE;
                        heldback_token = current_token;
                        current_token.text = "<call>";
                        bracket_level--;
                    }
                    break;

                case CLOSEB_SEP:
                    bracket_level--;
                    if (bracket_level < 0)
                        current_token.type = ENDEXP_TT;
                    else current_token.type = SUBCLOSE_TT;
                    break;

                case SEMICOLON_SEP:
                    current_token.type = ENDEXP_TT; break;

                case MINUS_SEP:
                    if ((previous_token.type == OP_TT)
                        || (previous_token.type == SUBOPEN_TT)
                        || (previous_token.type == ENDEXP_TT))
                    current_token.value = UNARY_MINUS_SEP; break;

                case INC_SEP:
                    if ((previous_token.type == VARIABLE_TT)
                        || (previous_token.type == SUBCLOSE_TT)
                        || (previous_token.type == LARGE_NUMBER_TT)
                        || (previous_token.type == SMALL_NUMBER_TT))
                    current_token.value = POST_INC_SEP; break;

                case DEC_SEP:
                    if ((previous_token.type == VARIABLE_TT)
                        || (previous_token.type == SUBCLOSE_TT)
                        || (previous_token.type == LARGE_NUMBER_TT)
                        || (previous_token.type == SMALL_NUMBER_TT))
                    current_token.value = POST_DEC_SEP; break;

                case HASHHASH_SEP:
                    token_text = current_token.text + 2;

                    ActionUsedAsConstant:

                    current_token.type = ACTION_TT;
                    current_token.text = token_text;
                    current_token.value = 0;
                    current_token.marker = ACTION_MV;

                    break;

                case HASHADOLLAR_SEP:
                obsolete_warning("'#a$Act' is now superseded by '##Act'");
                    token_text = current_token.text + 3;
                    goto ActionUsedAsConstant;

                case HASHGDOLLAR_SEP:

                /* This form generates the position of a global variable
                   in the global variables array. So Glob is the same as
                   #globals_array --> #g$Glob                                */

                    current_token.text += 3;
                    current_token.type = SYMBOL_TT;
                    symbol = symbol_index(current_token.text, -1);
                    if (stypes[symbol] != GLOBAL_VARIABLE_T) {
                        ebf_error(
                        "global variable name after '#g$'",
                        current_token.text);
                        current_token.value = 0;
                        current_token.type = SMALL_NUMBER_TT;
                        current_token.marker = 0;
                        break;
                    }
                    mark_symbol_as_used = TRUE;
                    current_token.value = svals[symbol] - MAX_LOCAL_VARIABLES;
                    current_token.marker = 0;
                    if (!glulx_mode) {
                        if (current_token.value >= 0x100)
                            current_token.type = LARGE_NUMBER_TT;
                        else current_token.type = SMALL_NUMBER_TT;
                    }
                    else {
                        if (current_token.value >= 0x8000
                          || current_token.value < -0x8000) 
                            current_token.type = LARGE_NUMBER_TT;
                        else current_token.type = SMALL_NUMBER_TT;
                    }
                    break;

                case HASHNDOLLAR_SEP:

                /* This form is still needed for constants like #n$a (the
                   dictionary address of the word "a"), since 'a' means
                   the ASCII value of 'a'                                    */

                    if (strlen(token_text) > 4)
                        obsolete_warning(
                            "'#n$word' is now superseded by ''word''");
                    current_token.type  = DICTWORD_TT;
                    current_token.value = 0;
                    current_token.text  = token_text + 3;
                    current_token.marker = DWORD_MV;
                    break;

                case HASHRDOLLAR_SEP:

                /*  This form -- #r$Routinename, to return the routine's     */
                /*  packed address -- is needed far less often in Inform 6,  */
                /*  where just giving the name Routine returns the packed    */
                /*  address.  But it's used in a lot of Inform 5 code.       */

                    obsolete_warning(
                        "'#r$Routine' can now be written just 'Routine'");
                    current_token.text += 3;
                    current_token.type = SYMBOL_TT;
                    current_token.value = symbol_index(current_token.text, -1);
                    goto ReceiveSymbol;

                case HASHWDOLLAR_SEP:
                    error("The obsolete '#w$word' construct has been removed");
                    break;

                case HASH_SEP:
                    system_constants.enabled = TRUE;
                    get_next_token();
                    system_constants.enabled = FALSE;
                    if (token_type != SYSTEM_CONSTANT_TT)
                    {   ebf_error(
                        "'r$', 'n$', 'g$' or internal Inform constant name after '#'",
                        token_text);
                        break;
                    }
                    else
                    {   current_token.type   = token_type;
                        current_token.value  = token_value;
                        current_token.text   = token_text;
                        current_token.marker = INCON_MV;
                    }
                    break;
            }
            break;

        case CND_TT:
            v = conditionals_to_operators[current_token.value];
            if (v != NOT_AN_OPERATOR)
            {   current_token.type = OP_TT; current_token.value = v;
            }
            break;
    }

    if (current_token.type == SEP_TT)
    {   v = separators_to_operators[current_token.value];
        if (v != NOT_AN_OPERATOR)
        {   if ((veneer_mode)
                || ((v!=MESSAGE_OP) && (v!=MPROP_NUM_OP) && (v!=MPROP_NUM_OP)))
            {   current_token.type = OP_TT; current_token.value = v;
                if (array_init_ambiguity &&
                    ((v==MINUS_OP) || (v==UNARY_MINUS_OP)) &&
                    (initial_bracket_level == 0) &&
                    (etoken_count != 1))
                warning("Without bracketing, the minus sign '-' is ambiguous");
            }
        }
    }

    /*  A feature of Inform making it annoyingly hard to parse left-to-right
        is that there is no clear delimiter for expressions; that is, the
        legal syntax often includes sequences of expressions with no
        intervening markers such as commas.  We therefore need to use some
        internal context to determine whether an end is in sight...          */

    if (token_type_allowable[current_token.type]==0)
    {   if (expr_trace_level >= 3)
        {   printf("Discarding as not allowable: '%s' ", current_token.text);
            describe_token(current_token);
            printf("\n");
        }
        current_token.type = ENDEXP_TT;
    }
    else
    if ((!((initial_bracket_level > 0)
           || (previous_token.type == ENDEXP_TT)
           || ((previous_token.type == OP_TT)
               && (operators[previous_token.value].usage != POST_U))
           || (previous_token.type == SYSFUN_TT)))
        && ((current_token.type != OP_TT)
            || (operators[current_token.value].usage == PRE_U)))
    {   if (expr_trace_level >= 3)
        {   printf("Discarding as no longer part: '%s' ", current_token.text);
            describe_token(current_token);
            printf("\n");
        }
        current_token.type = ENDEXP_TT;
    }
    else
    {   if (mark_symbol_as_used) sflags[symbol] |= USED_SFLAG;
        if (expr_trace_level >= 3)
        {   printf("Expr token = '%s' ", current_token.text);
            describe_token(current_token);
            printf("\n");
        }
    }

    if ((previous_token.type == ENDEXP_TT)
        && (current_token.type == ENDEXP_TT)) return FALSE;

    previous_token = current_token;

    return TRUE;
}

/* --- Operator precedences ------------------------------------------------ */

#define LOWER_P   101
#define EQUAL_P   102
#define GREATER_P 103

#define e1        1       /* Missing operand error                */
#define e2        2       /* Unexpected close bracket             */
#define e3        3       /* Missing operator error               */
#define e4        4       /* Expression ends with an open bracket */
#define e5        5       /* Associativity illegal error          */

const int prec_table[] = {

/* a .......... (         )           end       op          term             */

/* b  (    */   LOWER_P,  e3,         LOWER_P,  LOWER_P,    e3,
/* .  )    */   EQUAL_P,  GREATER_P,  e2,       GREATER_P,  GREATER_P,
/* .  end  */   e4,       GREATER_P,  e1,       GREATER_P,  GREATER_P,
/* .  op   */   LOWER_P,  GREATER_P,  LOWER_P,  -1,         GREATER_P,
/* .  term */   LOWER_P,  e3,         LOWER_P,  LOWER_P,    e3

};

static int find_prec(token_data a, token_data b)
{
    /*  We are comparing the precedence of tokens  a  and  b
        (where a occurs to the left of b).  If the expression is correct,
        the only possible values are GREATER_P, LOWER_P or EQUAL_P;
        if it is malformed then one of e1 to e5 results.

        Note that this routine is not symmetrical and that the relation
        is not trichotomous.

        If a and b are equal (and aren't brackets), then

            a LOWER_P a     if a right-associative
            a GREATER_P a   if a left-associative
    */

    int i, j, l1, l2;

    switch(a.type)
    {   case SUBOPEN_TT:  i=0; break;
        case SUBCLOSE_TT: i=1; break;
        case ENDEXP_TT:   i=2; break;
        case OP_TT:       i=3; break;
        default:          i=4; break;
    }
    switch(b.type)
    {   case SUBOPEN_TT:  i+=0; break;
        case SUBCLOSE_TT: i+=5; break;
        case ENDEXP_TT:   i+=10; break;
        case OP_TT:       i+=15; break;
        default:          i+=20; break;
    }

    j = prec_table[i]; if (j != -1) return j;

    l1 = operators[a.value].precedence;
    l2 = operators[b.value].precedence;
    if (operators[b.value].usage == PRE_U) return LOWER_P;
    if (operators[a.value].usage == POST_U) return GREATER_P;

    /*  Anomalous rule to resolve the function call precedence, which is
        different on the right from on the left, e.g., in:

                 alpha.beta(gamma)
                 beta(gamma).alpha
    */

    if ((l1 == 11) && (l2 > 11)) return GREATER_P;

    if (l1 < l2)  return LOWER_P;
    if (l1 > l2)  return GREATER_P;
    switch(operators[a.value].associativity)
    {   case L_A: return GREATER_P;
        case R_A: return LOWER_P;
        case 0:   return e5;
    }
    return GREATER_P;
}

/* --- Converting token to operand ----------------------------------------- */

/* Must match the switch statement below */
int z_system_constant_list[] =
    { adjectives_table_SC,
      actions_table_SC,
      classes_table_SC,
      identifiers_table_SC,
      preactions_table_SC,
      largest_object_SC,
      strings_offset_SC,
      code_offset_SC,
      actual_largest_object_SC,
      static_memory_offset_SC,
      array_names_offset_SC,
      readable_memory_offset_SC,
      cpv__start_SC,
      cpv__end_SC,
      ipv__start_SC,
      ipv__end_SC,
      array__start_SC,
      array__end_SC,
      highest_attribute_number_SC,
      attribute_names_array_SC,
      highest_property_number_SC,
      property_names_array_SC,
      highest_action_number_SC,
      action_names_array_SC,
      highest_fake_action_number_SC,
      fake_action_names_array_SC,
      highest_routine_number_SC,
      routine_names_array_SC,
      routines_array_SC,
      routine_flags_array_SC,
      highest_global_number_SC,
      global_names_array_SC,
      globals_array_SC,
      global_flags_array_SC,
      highest_array_number_SC,
      array_names_array_SC,
      array_flags_array_SC,
      highest_constant_number_SC,
      constant_names_array_SC,
      highest_class_number_SC,
      class_objects_array_SC,
      highest_object_number_SC,
      -1 };

static int32 value_of_system_constant_z(int t)
{   switch(t)
    {   case adjectives_table_SC:
            return adjectives_offset;
        case actions_table_SC:
            return actions_offset;
        case classes_table_SC:
            return class_numbers_offset;
        case identifiers_table_SC:
            return identifier_names_offset;
        case preactions_table_SC:
            return preactions_offset;
        case largest_object_SC:
            return 256 + no_objects - 1;
        case strings_offset_SC:
            return strings_offset/scale_factor;
        case code_offset_SC:
            return code_offset/scale_factor;
        case actual_largest_object_SC:
            return no_objects;
        case static_memory_offset_SC:
            return static_memory_offset;
        case array_names_offset_SC:
            return array_names_offset;
        case readable_memory_offset_SC:
            return Write_Code_At;
        case cpv__start_SC:
            return prop_values_offset;
        case cpv__end_SC:
            return class_numbers_offset;
        case ipv__start_SC:
            return individuals_offset;
        case ipv__end_SC:
            return variables_offset;
        case array__start_SC:
            return variables_offset + (MAX_GLOBAL_VARIABLES*WORDSIZE);
        case array__end_SC:
            return static_memory_offset;

        case highest_attribute_number_SC:
            return no_attributes-1;
        case attribute_names_array_SC:
            return attribute_names_offset;

        case highest_property_number_SC:
            return no_individual_properties-1;
        case property_names_array_SC:
            return identifier_names_offset + 2;

        case highest_action_number_SC:
            return no_actions-1;
        case action_names_array_SC:
            return action_names_offset;

        case highest_fake_action_number_SC:
            return ((grammar_version_number==1)?256:4096) + no_fake_actions-1;
        case fake_action_names_array_SC:
            return fake_action_names_offset;

        case highest_routine_number_SC:
            return no_named_routines-1;
        case routine_names_array_SC:
            return routine_names_offset;
        case routines_array_SC:
            return routines_array_offset;
        case routine_flags_array_SC:
            return routine_flags_array_offset;
        case highest_global_number_SC:
            return 16 + no_globals-1;
        case global_names_array_SC:
            return global_names_offset;
        case globals_array_SC:
            return variables_offset;
        case global_flags_array_SC:
            return global_flags_array_offset;
        case highest_array_number_SC:
            return no_arrays-1;
        case array_names_array_SC:
            return array_names_offset;
        case array_flags_array_SC:
            return array_flags_array_offset;
        case highest_constant_number_SC:
            return no_named_constants-1;
        case constant_names_array_SC:
            return constant_names_offset;
        case highest_class_number_SC:
            return no_classes-1;
        case class_objects_array_SC:
            return class_numbers_offset;
        case highest_object_number_SC:
            return no_objects-1;
    }

    error_named("System constant not implemented in Z-code",
        system_constants.keywords[t]);

    return(0);
}

/* Must match the switch statement below */
int glulx_system_constant_list[] =
    { classes_table_SC,
      identifiers_table_SC,
      array_names_offset_SC,
      cpv__start_SC,
      cpv__end_SC,
      dictionary_table_SC,
      dynam_string_table_SC,
      grammar_table_SC,
      actions_table_SC,
      globals_array_SC,
      highest_class_number_SC,
      highest_object_number_SC,
      -1 };

static int32 value_of_system_constant_g(int t)
{ 
  switch (t) {
  case classes_table_SC:
    return Write_RAM_At + class_numbers_offset;
  case identifiers_table_SC:
    return Write_RAM_At + identifier_names_offset;
  case array_names_offset_SC:
    return Write_RAM_At + array_names_offset;
  case cpv__start_SC:
    return prop_defaults_offset;
  case cpv__end_SC:
    return Write_RAM_At + class_numbers_offset;
  case dictionary_table_SC:
    return dictionary_offset;
  case dynam_string_table_SC:
    return abbreviations_offset;
  case grammar_table_SC:
    return grammar_table_offset;
  case actions_table_SC:
    return actions_offset;
  case globals_array_SC:
    return variables_offset;
  case highest_class_number_SC:
    return no_classes-1;
  case highest_object_number_SC:
    return no_objects-1;
  }

  error_named("System constant not implemented in Glulx",
    system_constants.keywords[t]);

  return 0;
}

extern int32 value_of_system_constant(int t)
{
  if (!glulx_mode)
    return value_of_system_constant_z(t);
  else
    return value_of_system_constant_g(t);    
}

static int evaluate_term(token_data t, assembly_operand *o)
{
    /*  If the given token is a constant, evaluate it into the operand.
        For now, the identifiers are considered variables.

        Returns FALSE if it fails to understand type. */

    int32 v;

    o->marker = t.marker;
    o->symtype = t.symtype;
    o->symflags = t.symflags;

    switch(t.type)
    {   case LARGE_NUMBER_TT:
             v = t.value;
             if (!glulx_mode) {
                 if (v < 0) v = v + 0x10000;
                 o->type = LONG_CONSTANT_OT;
                 o->value = v;
             }
             else {
                 o->value = v;
                 o->type = CONSTANT_OT;
             }
             return(TRUE);
        case SMALL_NUMBER_TT:
             v = t.value;
             if (!glulx_mode) {
                 if (v < 0) v = v + 0x10000;
                 o->type = SHORT_CONSTANT_OT;
                 o->value = v;
             }
             else {
                 o->value = v;
                 set_constant_ot(o);
             }
             return(TRUE);
        case DICTWORD_TT:
             /*  Find the dictionary address, adding to dictionary if absent */
             if (!glulx_mode) 
                 o->type = LONG_CONSTANT_OT;
             else
                 o->type = CONSTANT_OT;
             o->value = dictionary_add(t.text, 0x80, 0, 0);
             return(TRUE);
        case DQ_TT:
             /*  Create as a static string  */
             if (!glulx_mode) 
                 o->type = LONG_CONSTANT_OT;
             else
                 o->type = CONSTANT_OT;
             o->value = compile_string(t.text, FALSE, FALSE);
             return(TRUE);
        case VARIABLE_TT:
             if (!glulx_mode) {
                 o->type = VARIABLE_OT;
             }
             else {
                 if (t.value >= MAX_LOCAL_VARIABLES) {
                     o->type = GLOBALVAR_OT;
                 }
                 else {
                     /* This includes "local variable zero", which is really
                        the stack-pointer magic variable. */
                     o->type = LOCALVAR_OT;
                 }
             }
             o->value = t.value;
             return(TRUE);
        case SYSFUN_TT:
             if (!glulx_mode) {
                 o->type = VARIABLE_OT;
                 o->value = t.value + 256;
             }
             else {
                 o->type = SYSFUN_OT;
                 o->value = t.value;
             }
             system_function_usage[t.value] = 1;
             return(TRUE);
        case ACTION_TT:
             *o = action_of_name(t.text);
             return(TRUE);
        case SYSTEM_CONSTANT_TT:
             /*  Certain system constants depend only on the
                 version number and need no backpatching, as they
                 are known in advance.  We can therefore evaluate
                 them immediately.  */
             if (!glulx_mode) {
                 o->type = LONG_CONSTANT_OT;
                 switch(t.value)
                 {   
                 case version_number_SC:
                     o->type = SHORT_CONSTANT_OT;
                     o->marker = 0;
                     v = version_number; break;
                 case dict_par1_SC:
                     o->type = SHORT_CONSTANT_OT;
                     o->marker = 0;
                     v = (version_number==3)?4:6; break;
                 case dict_par2_SC:
                     o->type = SHORT_CONSTANT_OT;
                     o->marker = 0;
                     v = (version_number==3)?5:7; break;
                 case dict_par3_SC:
                     o->type = SHORT_CONSTANT_OT;
                     o->marker = 0;
                     v = (version_number==3)?6:8; break;
                 case lowest_attribute_number_SC:
                 case lowest_action_number_SC:
                 case lowest_routine_number_SC:
                 case lowest_array_number_SC:
                 case lowest_constant_number_SC:
                 case lowest_class_number_SC:
                     o->type = SHORT_CONSTANT_OT; o->marker = 0; v = 0; break;
                 case lowest_object_number_SC:
                 case lowest_property_number_SC:
                     o->type = SHORT_CONSTANT_OT; o->marker = 0; v = 1; break;
                 case lowest_global_number_SC:
                     o->type = SHORT_CONSTANT_OT; o->marker = 0; v = 16; break;
                 case lowest_fake_action_number_SC:
                     o->type = LONG_CONSTANT_OT; o->marker = 0;
                     v = ((grammar_version_number==1)?256:4096); break;
                 case oddeven_packing_SC:
                     o->type = SHORT_CONSTANT_OT; o->marker = 0;
                     v = oddeven_packing_switch; break;
                 default:
                     v = t.value;
                     o->marker = INCON_MV;
                     break;
                 }
                 o->value = v;
             }
             else {
                 o->type = CONSTANT_OT;
                 switch(t.value)
                 {
                 /* The three dict_par flags point at the lower byte
                    of the flag field, because the library is written
                    to expect one-byte fields, even though the compiler
                    generates a dictionary with room for two. */
                 case dict_par1_SC:
                     o->type = BYTECONSTANT_OT;
                     o->marker = 0;
                     v = DICT_ENTRY_FLAG_POS+1;
                     break;
                 case dict_par2_SC:
                     o->type = BYTECONSTANT_OT;
                     o->marker = 0;
                     v = DICT_ENTRY_FLAG_POS+3;
                     break;
                 case dict_par3_SC:
                     o->type = BYTECONSTANT_OT;
                     o->marker = 0;
                     v = DICT_ENTRY_FLAG_POS+5;
                     break;

                 case lowest_attribute_number_SC:
                 case lowest_action_number_SC:
                 case lowest_routine_number_SC:
                 case lowest_array_number_SC:
                 case lowest_constant_number_SC:
                 case lowest_class_number_SC:
                     o->type = BYTECONSTANT_OT;
                     o->marker = 0;
                     v = 0;
                     break;
                 case lowest_object_number_SC:
                 case lowest_property_number_SC:
                     o->type = BYTECONSTANT_OT;
                     o->marker = 0;
                     v = 1;
                     break;
 
                 /* ###fix: need to fill more of these in! */

                 default:
                     v = t.value;
                     o->marker = INCON_MV;
                     break;
                 }
                 o->value = v;
             }
             return(TRUE);
        default:
             return(FALSE);
    }
}

/* --- Emitter ------------------------------------------------------------- */

expression_tree_node *ET;
static int ET_used;

extern void clear_expression_space(void)
{   ET_used = 0;
}

static assembly_operand *emitter_stack;
static int *emitter_markers;
static int *emitter_bracket_counts;

#define FUNCTION_VALUE_MARKER 1
#define ARGUMENT_VALUE_MARKER 2
#define OR_VALUE_MARKER 3

static int emitter_sp;

static int is_property_t(int symbol_type)
{   return ((symbol_type == PROPERTY_T) || (symbol_type == INDIVIDUAL_PROPERTY_T));
}

static void mark_top_of_emitter_stack(int marker, token_data t)
{   if (emitter_sp < 1)
    {   compiler_error("SR error: Attempt to add a marker to the top of an empty emitter stack");
        return;
    }
    if (expr_trace_level >= 2)
    {   printf("Marking top of emitter stack (which is ");
        print_operand(emitter_stack[emitter_sp-1]);
        printf(") as ");
        switch(marker)
        {
            case FUNCTION_VALUE_MARKER:
                printf("FUNCTION");
                break;
            case ARGUMENT_VALUE_MARKER:
                printf("ARGUMENT");
                break;
            case OR_VALUE_MARKER:
                printf("OR_VALUE");
                break;
            default:
                printf("UNKNOWN");
                break;
        }
        printf("\n");
    }
    if (emitter_markers[emitter_sp-1])
    {   if (marker == ARGUMENT_VALUE_MARKER)
        {
            warning("Ignoring spurious leading comma");
            return;
        }
        error_named("Missing operand for", t.text);
        if (emitter_sp == MAX_EXPRESSION_NODES)
            memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
        emitter_markers[emitter_sp] = 0;
        emitter_bracket_counts[emitter_sp] = 0;
        emitter_stack[emitter_sp] = zero_operand;
        emitter_sp++;
    }
    emitter_markers[emitter_sp-1] = marker;
}

static void add_bracket_layer_to_emitter_stack(int depth)
{   /* There's no point in tracking bracket layers that don't fence off any values. */
    if (emitter_sp < depth + 1) return;
    if (expr_trace_level >= 2)
        printf("Adding bracket layer\n");
    ++emitter_bracket_counts[emitter_sp-depth-1];
}

static void remove_bracket_layer_from_emitter_stack()
{   /* Bracket layers that don't fence off any values will not have been tracked. */
    if (emitter_sp < 2) return;
    if (expr_trace_level >= 2)
        printf("Removing bracket layer\n");
    if (emitter_bracket_counts[emitter_sp-2] <= 0)
    {   compiler_error("SR error: Attempt to remove a nonexistent bracket layer from the emitter stack");
        return;
    }
    --emitter_bracket_counts[emitter_sp-2];
}

static void emit_token(token_data t)
{   assembly_operand o1, o2; int arity, stack_size, i;
    int op_node_number, operand_node_number, previous_node_number;
    int32 x = 0;

    if (expr_trace_level >= 2)
    {   printf("Output: %-19s%21s ", t.text, "");
        for (i=0; i<emitter_sp; i++)
        {   print_operand(emitter_stack[i]); printf(" ");
            if (emitter_markers[i] == FUNCTION_VALUE_MARKER) printf(":FUNCTION ");
            if (emitter_markers[i] == ARGUMENT_VALUE_MARKER) printf(":ARGUMENT ");
            if (emitter_markers[i] == OR_VALUE_MARKER) printf(":OR ");
            if (emitter_bracket_counts[i]) printf(":BRACKETS(%d) ", emitter_bracket_counts[i]);
        }
        printf("\n");
    }

    if (t.type == SUBOPEN_TT) return;

    stack_size = 0;
    while ((stack_size < emitter_sp) &&
           !emitter_markers[emitter_sp-stack_size-1] &&
           !emitter_bracket_counts[emitter_sp-stack_size-1])
        stack_size++;

    if (t.type == SUBCLOSE_TT)
    {   if (stack_size < emitter_sp && emitter_bracket_counts[emitter_sp-stack_size-1])
        {   if (stack_size == 0)
            {   error("No expression between brackets '(' and ')'");
                emitter_stack[emitter_sp] = zero_operand;
                emitter_markers[emitter_sp] = 0;
                emitter_bracket_counts[emitter_sp] = 0;
                ++emitter_sp;
            }
            else if (stack_size < 1)
                compiler_error("SR error: emitter stack empty in subexpression");
            else if (stack_size > 1)
                compiler_error("SR error: emitter stack overfull in subexpression");
            remove_bracket_layer_from_emitter_stack();
        }
        return;
    }

    if (t.type != OP_TT)
    {   emitter_markers[emitter_sp] = 0;
        emitter_bracket_counts[emitter_sp] = 0;

        if (emitter_sp == MAX_EXPRESSION_NODES)
            memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
        if (!evaluate_term(t, &(emitter_stack[emitter_sp++])))
            compiler_error_named("Emit token error:", t.text);
        return;
    }

    /* A comma is argument-separating if it follows an argument (or a function
       call, since we ignore spurious leading commas in function argument lists)
       with no intervening brackets.  Function calls are variadic, so we don't
       apply argument-separating commas. */
    if (t.value == COMMA_OP &&
        stack_size < emitter_sp &&
        (emitter_markers[emitter_sp-stack_size-1] == ARGUMENT_VALUE_MARKER ||
         emitter_markers[emitter_sp-stack_size-1] == FUNCTION_VALUE_MARKER) &&
        !emitter_bracket_counts[emitter_sp-stack_size-1])
    {   if (expr_trace_level >= 2)
            printf("Treating comma as argument-separating\n");
        return;
    }

    if (t.value == OR_OP)
        return;

    arity = 1;
    if (t.value == FCALL_OP)
    {   if (expr_trace_level >= 3)
        {   printf("FCALL_OP finds marker stack: ");
            for (x=0; x<emitter_sp; x++) printf("%d ", emitter_markers[x]);
            printf("\n");
        }
        if (emitter_markers[emitter_sp-1] == ARGUMENT_VALUE_MARKER)
            warning("Ignoring spurious trailing comma");
        while (emitter_markers[emitter_sp-arity] != FUNCTION_VALUE_MARKER)
        {
            if ((glulx_mode &&
                 emitter_stack[emitter_sp-arity].type == SYSFUN_OT) ||
                (!glulx_mode &&
                 emitter_stack[emitter_sp-arity].type == VARIABLE_OT &&
                 emitter_stack[emitter_sp-arity].value >= 256 &&
                 emitter_stack[emitter_sp-arity].value < 288))
            {   int index = emitter_stack[emitter_sp-arity].value;
                if(!glulx_mode)
                    index -= 256;
                if(index >= 0 && index < NUMBER_SYSTEM_FUNCTIONS)
                    error_named("System function name used as a value:", system_functions.keywords[index]);
                else
                    compiler_error("Found unnamed system function used as a value");
                emitter_stack[emitter_sp-arity] = zero_operand;
            }
            ++arity;
        }
    }
    else
    {   arity = 1;
        if (operators[t.value].usage == IN_U) arity = 2;

        if (operators[t.value].precedence == 3)
        {   arity = 2;
            x = emitter_sp-1;
            if(!emitter_markers[x] && !emitter_bracket_counts[x])
            {   for (--x; emitter_markers[x] == OR_VALUE_MARKER && !emitter_bracket_counts[x]; --x)
                {   ++arity;
                    ++stack_size;
                }
                for (;x >= 0 && !emitter_markers[x] && !emitter_bracket_counts[x]; --x)
                    ++stack_size;
            }
        }

        if (arity > stack_size)
        {   error_named("Missing operand for", t.text);
            while (arity > stack_size)
            {   if (emitter_sp == MAX_EXPRESSION_NODES)
                    memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
                emitter_markers[emitter_sp] = 0;
                emitter_bracket_counts[emitter_sp] = 0;
                emitter_stack[emitter_sp] = zero_operand;
                emitter_sp++;
                stack_size++;
            }
        }
    }

    /* pseudo-typecheck in 6.30 */
    for (i = 1; i <= arity; i++)
    {
        o1 = emitter_stack[emitter_sp - i];
        if (is_property_t(o1.symtype) ) {
            switch(t.value) 
            {
                case FCALL_OP:
                case SETEQUALS_OP: case NOTEQUAL_OP: 
                case CONDEQUALS_OP: 
                case PROVIDES_OP: case NOTPROVIDES_OP:
                case PROP_ADD_OP: case PROP_NUM_OP:
                case SUPERCLASS_OP:
                case MPROP_ADD_OP: case MESSAGE_OP:
                case PROPERTY_OP:
                    if (i < arity) break;
                case GE_OP: case LE_OP:
                    if ((i < arity) && (o1.symflags & STAR_SFLAG)) break;
                default:
                    warning("Property name in expression is not qualified by object");
            }
        } /* if (is_property_t */
    }

    switch(arity)
    {   case 1:
            o1 = emitter_stack[emitter_sp - 1];
            if ((o1.marker == 0) && is_constant_ot(o1.type))
            {   switch(t.value)
                {   case UNARY_MINUS_OP: x = -o1.value; goto FoldConstant;
                    case ARTNOT_OP: 
                         if (!glulx_mode)
                             x = (~o1.value) & 0xffff;
                         else
                             x = (~o1.value) & 0xffffffff;
                         goto FoldConstant;
                    case LOGNOT_OP:
                        if (o1.value != 0) x=0; else x=1;
                        goto FoldConstant;
                }
            }
            break;

        case 2:
            o1 = emitter_stack[emitter_sp - 2];
            o2 = emitter_stack[emitter_sp - 1];

            if ((o1.marker == 0) && (o2.marker == 0)
                && is_constant_ot(o1.type) && is_constant_ot(o2.type))
            {
                int32 ov1, ov2;
                if (glulx_mode)
                { ov1 = o1.value;
                  ov2 = o2.value;
                }
                else
                { ov1 = (o1.value >= 0x8000) ? (o1.value - 0x10000) : o1.value;
                  ov2 = (o2.value >= 0x8000) ? (o2.value - 0x10000) : o2.value;
                }

                switch(t.value)
                {
                    case PLUS_OP: x = ov1 + ov2; goto FoldConstantC;
                    case MINUS_OP: x = ov1 - ov2; goto FoldConstantC;
                    case TIMES_OP: x = ov1 * ov2; goto FoldConstantC;
                    case DIVIDE_OP:
                    case REMAINDER_OP:
                        if (ov2 == 0)
                          error("Division of constant by zero");
                        else
                        if (t.value == DIVIDE_OP) {
                          if (ov2 < 0) {
                            ov1 = -ov1;
                            ov2 = -ov2;
                          }
                          if (ov1 >= 0) 
                            x = ov1 / ov2;
                          else
                            x = -((-ov1) / ov2);
                        }
                        else {
                          if (ov2 < 0) {
                            ov2 = -ov2;
                          }
                          if (ov1 >= 0) 
                            x = ov1 % ov2;
                          else
                            x = -((-ov1) % ov2);
                        }
                        goto FoldConstant;
                    case ARTAND_OP: x = o1.value & o2.value; goto FoldConstant;
                    case ARTOR_OP: x = o1.value | o2.value; goto FoldConstant;
                    case CONDEQUALS_OP:
                        if (o1.value == o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case NOTEQUAL_OP:
                        if (o1.value != o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case GE_OP:
                        if (o1.value >= o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case GREATER_OP:
                        if (o1.value > o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case LE_OP:
                        if (o1.value <= o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case LESS_OP:
                        if (o1.value < o2.value) x = 1; else x = 0;
                        goto FoldConstant;
                    case LOGAND_OP:
                        if ((o1.value != 0) && (o2.value != 0)) x=1; else x=0;
                        goto FoldConstant;
                    case LOGOR_OP:
                        if ((o1.value != 0) || (o2.value != 0)) x=1; else x=0;
                        goto FoldConstant;
                }

            }
    }

    op_node_number = ET_used++;
    if (op_node_number == MAX_EXPRESSION_NODES)
        memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);

    ET[op_node_number].operator_number = t.value;
    ET[op_node_number].up = -1;
    ET[op_node_number].down = -1;
    ET[op_node_number].right = -1;

    /*  This statement is redundant, but prevents compilers from wrongly
        issuing a "used before it was assigned a value" error:  */
    previous_node_number = 0;

    for (i = emitter_sp-arity; i != emitter_sp; i++)
    {
        if (expr_trace_level >= 3)
            printf("i=%d, emitter_sp=%d, arity=%d, ETU=%d\n",
                i, emitter_sp, arity, ET_used);
        if (emitter_stack[i].type == EXPRESSION_OT)
            operand_node_number = emitter_stack[i].value;
        else
        {   operand_node_number = ET_used++;
            if (operand_node_number == MAX_EXPRESSION_NODES)
                memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
            ET[operand_node_number].down = -1;
            ET[operand_node_number].value = emitter_stack[i];
        }
        ET[operand_node_number].up = op_node_number;
        ET[operand_node_number].right = -1;
        if (i == emitter_sp - arity)
        {   ET[op_node_number].down = operand_node_number;
        }
        else
        {   ET[previous_node_number].right = operand_node_number;
        }
        previous_node_number = operand_node_number;
    }

    emitter_sp = emitter_sp - arity + 1;

    emitter_stack[emitter_sp - 1].type = EXPRESSION_OT;
    emitter_stack[emitter_sp - 1].value = op_node_number;
    emitter_stack[emitter_sp - 1].marker = 0;
    emitter_markers[emitter_sp - 1] = 0;
    emitter_bracket_counts[emitter_sp - 1] = 0;
    /* Remove the marker for the brackets implied by operator precedence */
    remove_bracket_layer_from_emitter_stack();

    return;

    FoldConstantC:

    /* In Glulx, skip this test; we can't check out-of-range errors 
       for 32-bit arithmetic. */

    if (!glulx_mode && ((x<-32768) || (x > 32767)))
    {   char folding_error[40];
        int32 ov1 = (o1.value >= 0x8000) ? (o1.value - 0x10000) : o1.value;
        int32 ov2 = (o2.value >= 0x8000) ? (o2.value - 0x10000) : o2.value;
        switch(t.value)
        {
            case PLUS_OP:
                sprintf(folding_error, "%d + %d = %d", ov1, ov2, x);
                break;
            case MINUS_OP:
                sprintf(folding_error, "%d - %d = %d", ov1, ov2, x);
                break;
            case TIMES_OP:
                sprintf(folding_error, "%d * %d = %d", ov1, ov2, x);
                break;
        }
        error_named("Signed arithmetic on compile-time constants overflowed \
the range -32768 to +32767:", folding_error);
    }

    FoldConstant:

    if (!glulx_mode) {
        while (x < 0) x = x + 0x10000;
        x = x & 0xffff;
    }
    else {
        x = x & 0xffffffff;
    }

    emitter_sp = emitter_sp - arity + 1;

    if (!glulx_mode) {
        if (x<256)
            emitter_stack[emitter_sp - 1].type = SHORT_CONSTANT_OT;
        else emitter_stack[emitter_sp - 1].type = LONG_CONSTANT_OT;
    }
    else {
        if (x == 0)
            emitter_stack[emitter_sp - 1].type = ZEROCONSTANT_OT;
        else if (x >= -128 && x <= 127) 
            emitter_stack[emitter_sp - 1].type = BYTECONSTANT_OT;
        else if (x >= -32768 && x <= 32767) 
            emitter_stack[emitter_sp - 1].type = HALFCONSTANT_OT;
        else
            emitter_stack[emitter_sp - 1].type = CONSTANT_OT;
    }

    emitter_stack[emitter_sp - 1].value = x;
    emitter_stack[emitter_sp - 1].marker = 0;
    emitter_markers[emitter_sp - 1] = 0;
    emitter_bracket_counts[emitter_sp - 1] = 0;

    if (expr_trace_level >= 2)
    {   printf("Folding constant to: ");
        print_operand(emitter_stack[emitter_sp - 1]);
        printf("\n");
    }

    /* Remove the marker for the brackets implied by operator precedence */
    remove_bracket_layer_from_emitter_stack();
    return;
}

/* --- Pretty printing ----------------------------------------------------- */

static void show_node(int n, int depth, int annotate)
{   int j;
    for (j=0; j<2*depth+2; j++) printf(" ");

    if (ET[n].down == -1)
    {   print_operand(ET[n].value);
        if (annotate && (ET[n].value.marker != 0))
            printf(" [%s]", describe_mv(ET[n].value.marker));
        printf("\n");
    }
    else
    {   printf("%s ", operators[ET[n].operator_number].description);
        j = operators[ET[n].operator_number].precedence;
        if ((annotate) && ((j==2) || (j==3)))
        {   printf(" %d|%d ", ET[n].true_label, ET[n].false_label);
            if (ET[n].label_after != -1) printf(" def %d after ",
                ET[n].label_after);
            if (ET[n].to_expression) printf(" con to expr ");
        }
        printf("\n");
        show_node(ET[n].down, depth+1, annotate);
    }

    if (ET[n].right != -1) show_node(ET[n].right, depth, annotate);
}

extern void show_tree(assembly_operand AO, int annotate)
{   if (AO.type == EXPRESSION_OT) show_node(AO.value, 0, annotate);
    else
    {   printf("Constant: "); print_operand(AO);
        if (annotate && (AO.marker != 0))
            printf(" [%s]", describe_mv(AO.marker));
        printf("\n");
    }
}

/* --- Lvalue transformations ---------------------------------------------- */

/* This only gets called in Z-code, since Glulx doesn't distinguish
   individual property operators from general ones. */
static void check_property_operator(int from_node)
{   int below = ET[from_node].down;
    int opnum = ET[from_node].operator_number;

    ASSERT_ZCODE();

    if (veneer_mode) return;

    if ((below != -1) && (ET[below].right != -1))
    {   int n = ET[below].right, flag = FALSE;

        if ((ET[n].down == -1)
                && ((ET[n].value.type == LONG_CONSTANT_OT)
                    || (ET[n].value.type == SHORT_CONSTANT_OT))
                && ((ET[n].value.value > 0) && (ET[n].value.value < 64))
                && ((!module_switch) || (ET[n].value.marker == 0)))
            flag = TRUE;

        if (!flag)
        {   switch(opnum)
            {   case PROPERTY_OP: opnum = MESSAGE_OP; break;
                case PROP_ADD_OP: opnum = MPROP_ADD_OP; break;
                case PROP_NUM_OP: opnum = MPROP_NUM_OP; break;
            }
        }

        ET[from_node].operator_number = opnum;
    }

    if (below != -1)
        check_property_operator(below);
    if (ET[from_node].right != -1)
        check_property_operator(ET[from_node].right);
}

static void check_lvalues(int from_node)
{   int below = ET[from_node].down;
    int opnum = ET[from_node].operator_number, opnum_below;
    int lvalue_form, i, j = 0;

    if (below != -1)
    {
        if ((opnum == FCALL_OP) && (ET[below].down != -1))
        {   opnum_below = ET[below].operator_number;
            if ((opnum_below == PROPERTY_OP) || (opnum_below == MESSAGE_OP))
            {   i = ET[ET[from_node].down].right;
                ET[from_node].down = ET[below].down;
                ET[ET[below].down].up = from_node;
                ET[ET[ET[below].down].right].up = from_node;
                ET[ET[ET[below].down].right].right = i;
                opnum = PROP_CALL_OP;
                ET[from_node].operator_number = opnum;
            }
        }

        if (operators[opnum].requires_lvalue)
        {   opnum_below = ET[below].operator_number;

            if (ET[below].down == -1)
            {   if (!is_variable_ot(ET[below].value.type))
                {   error("'=' applied to undeclared variable");
                    goto LvalueError;
                }
            }
            else
            { lvalue_form=0;
              switch(opnum)
              { case SETEQUALS_OP:
                switch(opnum_below)
                { case ARROW_OP:    lvalue_form = ARROW_SETEQUALS_OP; break;
                  case DARROW_OP:   lvalue_form = DARROW_SETEQUALS_OP; break;
                  case MESSAGE_OP:  lvalue_form = MESSAGE_SETEQUALS_OP; break;
                  case PROPERTY_OP: lvalue_form = PROPERTY_SETEQUALS_OP; break;
                }
                break;
                case INC_OP:
                switch(opnum_below)
                { case ARROW_OP:    lvalue_form = ARROW_INC_OP; break;
                  case DARROW_OP:   lvalue_form = DARROW_INC_OP; break;
                  case MESSAGE_OP:  lvalue_form = MESSAGE_INC_OP; break;
                  case PROPERTY_OP: lvalue_form = PROPERTY_INC_OP; break;
                }
                break;
                case POST_INC_OP:
                switch(opnum_below)
                { case ARROW_OP:    lvalue_form = ARROW_POST_INC_OP; break;
                  case DARROW_OP:   lvalue_form = DARROW_POST_INC_OP; break;
                  case MESSAGE_OP:  lvalue_form = MESSAGE_POST_INC_OP; break;
                  case PROPERTY_OP: lvalue_form = PROPERTY_POST_INC_OP; break;
                }
                break;
                case DEC_OP:
                switch(opnum_below)
                { case ARROW_OP:    lvalue_form = ARROW_DEC_OP; break;
                  case DARROW_OP:   lvalue_form = DARROW_DEC_OP; break;
                  case MESSAGE_OP:  lvalue_form = MESSAGE_DEC_OP; break;
                  case PROPERTY_OP: lvalue_form = PROPERTY_DEC_OP; break;
                }
                break;
                case POST_DEC_OP:
                switch(opnum_below)
                { case ARROW_OP:    lvalue_form = ARROW_POST_DEC_OP; break;
                  case DARROW_OP:   lvalue_form = DARROW_POST_DEC_OP; break;
                  case MESSAGE_OP:  lvalue_form = MESSAGE_POST_DEC_OP; break;
                  case PROPERTY_OP: lvalue_form = PROPERTY_POST_DEC_OP; break;
                }
                break;
              }
              if (lvalue_form == 0)
              {   error_named("'=' applied to",
                      (char *) operators[opnum_below].description);
                  goto LvalueError;
              }

              /*  Transform  from_node                     from_node
                               |      \                       | \\\  \
                             below    value       to                 value
                               | \\\
              */

              ET[from_node].operator_number = lvalue_form;
              i = ET[below].down;
              ET[from_node].down = i;
              while (i != -1)
              {   ET[i].up = from_node;
                  j = i;
                  i = ET[i].right;
              }
              ET[j].right = ET[below].right;
            }
        }
        check_lvalues(below);
    }
    if (ET[from_node].right != -1)
        check_lvalues(ET[from_node].right);
    return;

    LvalueError:
    ET[from_node].down = -1;
    ET[from_node].value = zero_operand;
    if (ET[from_node].right != -1)
        check_lvalues(ET[from_node].right);
}

/* --- Tree surgery for conditionals --------------------------------------- */

static void negate_condition(int n)
{   int i;

    if (ET[n].right != -1) negate_condition(ET[n].right);
    if (ET[n].down == -1) return;
    i = operators[ET[n].operator_number].negation;
    if (i!=0) ET[n].operator_number = i;
    if (operators[i].precedence==2) negate_condition(ET[n].down);
}

static void delete_negations(int n, int context)
{
    /*  Recursively apply

            ~~(x && y)   =   ~~x || ~~y
            ~~(x || y)   =   ~~x && ~~y
            ~~(x == y)   =   x ~= y

        (etc) to delete the ~~ operator from the tree.  Since this is
        depth first, the ~~ being deleted has no ~~s beneath it, which
        is important to make "negate_condition" work.                        */

    int i;

    if (ET[n].right != -1) delete_negations(ET[n].right, context);
    if (ET[n].down == -1) return;
    delete_negations(ET[n].down, context);

    if (ET[n].operator_number == LOGNOT_OP)
    {   negate_condition(ET[n].down);
        ET[n].operator_number
            = ET[ET[n].down].operator_number;
        ET[n].down = ET[ET[n].down].down;
        i = ET[n].down;
        while(i != -1) { ET[i].up = n; i = ET[i].right; }
    }
}

static void insert_exp_to_cond(int n, int context)
{
    /*  Insert a ~= test when an expression is used as a condition.

        Check for possible confusion over = and ==, e.g. "if (a = 1) ..."    */

    int new, i;

    if (ET[n].right != -1) insert_exp_to_cond(ET[n].right, context);

    if (ET[n].down == -1)
    {   if (context==CONDITION_CONTEXT)
        {   new = ET_used++;
            if (new == MAX_EXPRESSION_NODES)
                memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
            ET[new] = ET[n];
            ET[n].down = new; ET[n].operator_number = NONZERO_OP;
            ET[new].up = n; ET[new].right = -1;
        }
        return;
    }

    switch(operators[ET[n].operator_number].precedence)
    {   case 3:                                 /* Conditionals have level 3 */
            context = QUANTITY_CONTEXT;
            break;
        case 2:                                 /* Logical operators level 2 */
            context = CONDITION_CONTEXT;
            break;
        case 1:                                 /* Forms of '=' have level 1 */
            if (context == CONDITION_CONTEXT)
                warning("'=' used as condition: '==' intended?");
        default:
            if (context != CONDITION_CONTEXT) break;

            new = ET_used++;
            if (new == MAX_EXPRESSION_NODES)
                memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
            ET[new] = ET[n];
            ET[n].down = new; ET[n].operator_number = NONZERO_OP;
            ET[new].up = n; ET[new].right = -1;

            i = ET[new].down;
            while (i!= -1) { ET[i].up = new; i = ET[i].right; }
            context = QUANTITY_CONTEXT; n = new;
    }

    insert_exp_to_cond(ET[n].down, context);
}

static unsigned int etoken_num_children(int n)
{
    int count = 0;
    int i;
    i = ET[n].down;
    if (i == -1) { return 0; }
    do {
        count++;
        i = ET[i].right;
    } while (i!=-1);
    return count;
}

static void func_args_on_stack(int n, int context)
{
  /* Make sure that the arguments of every function-call expression
     are stored to the stack. If any aren't (ie, if any arguments are
     constants or variables), cover them with push operators. 
     (The very first argument does not need to be so treated, because
     it's the function address, not a function argument. We also
     skip the treatment for most system functions.) */

  int new, pn, fnaddr, opnum;

  ASSERT_GLULX();

  if (ET[n].right != -1) 
    func_args_on_stack(ET[n].right, context);
  if (ET[n].down == -1) {
    pn = ET[n].up;
    if (pn != -1) {
      opnum = ET[pn].operator_number;
      if (opnum == FCALL_OP
        || opnum == MESSAGE_CALL_OP
        || opnum == PROP_CALL_OP) {
        /* If it's an FCALL, get the operand which contains the function 
           address (or system-function number) */
        if (opnum == MESSAGE_CALL_OP 
          || opnum == PROP_CALL_OP
          || ((fnaddr=ET[pn].down) != n
            && (ET[fnaddr].value.type != SYSFUN_OT
              || ET[fnaddr].value.value == INDIRECT_SYSF
              || ET[fnaddr].value.value == GLK_SYSF))) {
        if (etoken_num_children(pn) > (unsigned int)(opnum == FCALL_OP ? 4:3)) {
          new = ET_used++;
          if (new == MAX_EXPRESSION_NODES)
            memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
          ET[new] = ET[n];
          ET[n].down = new; 
          ET[n].operator_number = PUSH_OP;
          ET[new].up = n; 
          ET[new].right = -1;
        }
        }
      }
    }
    return;
  }

  func_args_on_stack(ET[n].down, context);
}

static assembly_operand check_conditions(assembly_operand AO, int context)
{   int n;

    if (AO.type != EXPRESSION_OT)
    {   if (context != CONDITION_CONTEXT) return AO;
        n = ET_used++;
        if (n == MAX_EXPRESSION_NODES)
            memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
        ET[n].down = -1;
        ET[n].up = -1;
        ET[n].right = -1;
        ET[n].value = AO;
        INITAOT(&AO, EXPRESSION_OT);
        AO.value = n;
    }

    insert_exp_to_cond(AO.value, context);
    delete_negations(AO.value, context);

    if (glulx_mode)
        func_args_on_stack(AO.value, context);

    return AO;
}

/* --- Shift-reduce parser ------------------------------------------------- */

static int sr_sp;
static token_data *sr_stack;

extern assembly_operand parse_expression(int context)
{
    /*  Parses an expression, evaluating it as a constant if possible.

        Possible contexts are:

            VOID_CONTEXT        the expression is used as a statement, so that
                                its value will be thrown away and it only
                                needs to exist for any resulting side-effects
                                (function calls and assignments)

            CONDITION_CONTEXT   the result must be a condition

            CONSTANT_CONTEXT    there is required to be a constant result
                                (so that, for instance, comma becomes illegal)

            QUANTITY_CONTEXT    the default: a quantity is to be specified

            ACTION_Q_CONTEXT    like QUANTITY_CONTEXT, but postfixed brackets
                                at the top level do not indicate function call:
                                used for e.g.
                                   <Insert button (random(pocket1, pocket2))>

            RETURN_Q_CONTEXT    like QUANTITY_CONTEXT, but a single property
                                name does not generate a warning

            ASSEMBLY_CONTEXT    a quantity which cannot use the '->' operator
                                (needed for assembly language to indicate
                                store destinations)

            FORINIT_CONTEXT     a quantity which cannot use an (unbracketed)
                                '::' operator

            ARRAY_CONTEXT       like CONSTANT_CONTEXT, but where an unbracketed
                                minus sign is ambiguous, and brackets always
                                indicate subexpressions, not function calls

        Return value: an assembly operand.

        If the type is OMITTED_OT, then the expression has no resulting value.

        If the type is EXPRESSION_OT, then the value will need to be
        calculated at run-time by code compiled from the expression tree
        whose root node-number is the operand value.

        Otherwise the assembly operand is the value of the expression, which
        is constant and thus known at compile time.

        If an error has occurred in the expression, which recovery from was
        not possible, then the return is (short constant) 0.  This should
        minimise the chance of a cascade of further error messages.
    */

    token_data a, b, pop; int i;
    assembly_operand AO;

    superclass_allowed = (context != FORINIT_CONTEXT);
    if (context == FORINIT_CONTEXT) context = VOID_CONTEXT;

    comma_allowed = (context == VOID_CONTEXT);
    arrow_allowed = (context != ASSEMBLY_CONTEXT);
    bare_prop_allowed = (context == RETURN_Q_CONTEXT);
    array_init_ambiguity = ((context == ARRAY_CONTEXT) ||
        (context == ASSEMBLY_CONTEXT));

    action_ambiguity = (context == ACTION_Q_CONTEXT);

    if (context == ASSEMBLY_CONTEXT) context = QUANTITY_CONTEXT;
    if (context == ACTION_Q_CONTEXT) context = QUANTITY_CONTEXT;
    if (context == RETURN_Q_CONTEXT) context = QUANTITY_CONTEXT;
    if (context == ARRAY_CONTEXT) context = CONSTANT_CONTEXT;

    etoken_count = 0;
    inserting_token = FALSE;

    emitter_sp = 0;
    bracket_level = 0;

    previous_token.text = "$";
    previous_token.type = ENDEXP_TT;
    previous_token.value = 0;

    sr_sp = 1;
    sr_stack[0] = previous_token;

    AO = zero_operand;

    statements.enabled = FALSE;
    directives.enabled = FALSE;

    if (get_next_etoken() == FALSE)
    {   ebf_error("expression", token_text);
        return AO;
    }

    do
    {   if (expr_trace_level >= 2)
        {   printf("Input: %-20s", current_token.text);
            for (i=0; i<sr_sp; i++) printf("%s ", sr_stack[i].text);
            printf("\n");
        }
        if (expr_trace_level >= 3) printf("ET_used = %d\n", ET_used);

        if (sr_sp == 0)
        {   compiler_error("SR error: stack empty");
            return(AO);
        }

        a = sr_stack[sr_sp-1]; b = current_token;

        if ((a.type == ENDEXP_TT) && (b.type == ENDEXP_TT))
        {   if (emitter_sp == 0)
            {   compiler_error("SR error: emitter stack empty");
                return AO;
            }
            if (emitter_sp > 1)
            {   compiler_error("SR error: emitter stack overfull");
                return AO;
            }

            AO = emitter_stack[0];
            if (AO.type == EXPRESSION_OT)
            {   if (expr_trace_level >= 3)
                {   printf("Tree before lvalue checking:\n");
                    show_tree(AO, FALSE);
                }
                if (!glulx_mode)
                    check_property_operator(AO.value);
                check_lvalues(AO.value);
                ET[AO.value].up = -1;
            }
            else {
                if ((context != CONSTANT_CONTEXT) && is_property_t(AO.symtype) 
                    && (arrow_allowed) && (!bare_prop_allowed))
                    warning("Bare property name found. \"self.prop\" intended?");
            }

            check_conditions(AO, context);

            if (context == CONSTANT_CONTEXT)
                if (!is_constant_ot(AO.type))
                {   AO = zero_operand;
                    ebf_error("constant", "<expression>");
                }
            put_token_back();

            return(AO);
        }

        switch(find_prec(a,b))
        {
            case e5:                 /* Associativity error                  */
                error_named("Brackets mandatory to clarify order of:",
                    a.text);

            case LOWER_P:
            case EQUAL_P:
                if (sr_sp == MAX_EXPRESSION_NODES)
                    memoryerror("MAX_EXPRESSION_NODES", MAX_EXPRESSION_NODES);
                sr_stack[sr_sp++] = b;
                switch(b.type)
                {
                    case SUBOPEN_TT:
                        if (sr_sp >= 2 && sr_stack[sr_sp-2].type == OP_TT && sr_stack[sr_sp-2].value == FCALL_OP)
                            mark_top_of_emitter_stack(FUNCTION_VALUE_MARKER, b);
                        else
                            add_bracket_layer_to_emitter_stack(0);
                        break;
                    case OP_TT:
                        switch(b.value){
                            case OR_OP:
                                if (sr_stack[sr_sp-2].type == OP_TT &&
                                    operators[sr_stack[sr_sp-2].value].precedence == 3)
                                    mark_top_of_emitter_stack(OR_VALUE_MARKER, b);
                                else
                                {   error("'or' not between values to the right of a condition");
                                    /* Convert to + for error recovery purposes */
                                    sr_stack[sr_sp-1].value = PLUS_OP;
                                }
                                break;
                            case COMMA_OP:
                                {
                                    /* A comma separates arguments only if the shallowest open bracket belongs to a function call. */
                                    int shallowest_open_bracket_index = sr_sp - 2;
                                    while (shallowest_open_bracket_index > 0 && sr_stack[shallowest_open_bracket_index].type != SUBOPEN_TT)
                                        --shallowest_open_bracket_index;
                                    if (shallowest_open_bracket_index > 0 &&
                                        sr_stack[shallowest_open_bracket_index-1].type == OP_TT &&
                                        sr_stack[shallowest_open_bracket_index-1].value == FCALL_OP)
                                    {   mark_top_of_emitter_stack(ARGUMENT_VALUE_MARKER, b);
                                        break;
                                    }
                                    /* Non-argument-separating commas get treated like any other operator; we fall through to the default case. */
                                }
                            default:
                                {
                                    /* Add a marker for the brackets implied by operator precedence */
                                    int operands_on_left = (operators[b.value].usage == PRE_U) ? 0 : 1;
                                    add_bracket_layer_to_emitter_stack(operands_on_left);
                                }
                        }
                }
                get_next_etoken();
                break;
            case GREATER_P:
                do
                {   pop = sr_stack[sr_sp - 1];
                    emit_token(pop);
                    sr_sp--;
                } while (find_prec(sr_stack[sr_sp-1], pop) != LOWER_P);
                break;

            case e1:                 /* Missing operand error                */
                error_named("Missing operand after", a.text);
                put_token_back();
                current_token.type = NUMBER_TT;
                current_token.value = 0;
                current_token.marker = 0;
                current_token.text = "0";
                break;

            case e2:                 /* Unexpected close bracket             */
                error("Found '(' without matching ')'");
                get_next_etoken();
                break;

            case e3:                 /* Missing operator error               */
                error("Missing operator: inserting '+'");
                put_token_back();
                current_token.type = OP_TT;
                current_token.value = PLUS_OP;
                current_token.marker = 0;
                current_token.text = "+";
                break;

            case e4:                 /* Expression ends with an open bracket */
                error("Found '(' without matching ')'");
                sr_sp--;
                break;

        }
    }
    while (TRUE);
}

/* --- Test for simple ++ or -- usage: used to optimise "for" loop code ---- */

extern int test_for_incdec(assembly_operand AO)
{   int s = 0;
    if (AO.type != EXPRESSION_OT) return 0;
    if (ET[AO.value].down == -1) return 0;
    switch(ET[AO.value].operator_number)
    {   case INC_OP:      s = 1; break;
        case POST_INC_OP: s = 1; break;
        case DEC_OP:      s = -1; break;
        case POST_DEC_OP: s = -1; break;
    }
    if (s==0) return 0;
    if (ET[ET[AO.value].down].down != -1) return 0;
    if (!is_variable_ot(ET[ET[AO.value].down].value.type)) return 0;
    return s*(ET[ET[AO.value].down].value.value);
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_expressp_vars(void)
{   int i;
    /* make_operands(); */
    make_lexical_interface_tables();
    for (i=0;i<32;i++) system_function_usage[i] = 0;
}

extern void expressp_begin_pass(void)
{
}

extern void expressp_allocate_arrays(void)
{   ET = my_calloc(sizeof(expression_tree_node), MAX_EXPRESSION_NODES,
        "expression parse trees");
    emitter_markers = my_calloc(sizeof(int), MAX_EXPRESSION_NODES,
        "emitter markers");
    emitter_bracket_counts = my_calloc(sizeof(int), MAX_EXPRESSION_NODES,
        "emitter bracket layer counts");
    emitter_stack = my_calloc(sizeof(assembly_operand), MAX_EXPRESSION_NODES,
        "emitter stack");
    sr_stack = my_calloc(sizeof(token_data), MAX_EXPRESSION_NODES,
        "shift-reduce parser stack");
}

extern void expressp_free_arrays(void)
{   my_free(&ET, "expression parse trees");
    my_free(&emitter_markers, "emitter markers");
    my_free(&emitter_bracket_counts, "emitter bracket layer counts");
    my_free(&emitter_stack, "emitter stack");
    my_free(&sr_stack, "shift-reduce parser stack");
}

/* ========================================================================= */
