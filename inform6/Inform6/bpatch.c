/* ------------------------------------------------------------------------- */
/*   "bpatch" : Keeps track of, and finally acts on, backpatch markers,      */
/*              correcting symbol values not known at compilation time       */
/*                                                                           */
/*   Part of Inform 6.41                                                     */
/*   copyright (c) Graham Nelson 1993 - 2022                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

uchar *staticarray_backpatch_table; /* Allocated to staticarray_backpatch_size */
memory_list staticarray_backpatch_table_memlist;
uchar *zmachine_backpatch_table; /* Allocated to zmachine_backpatch_size */
memory_list zmachine_backpatch_table_memlist;
uchar *zcode_backpatch_table; /* Allocated to zcode_backpatch_size */
memory_list zcode_backpatch_table_memlist;
int32 zcode_backpatch_size, staticarray_backpatch_size,
    zmachine_backpatch_size;

/* ------------------------------------------------------------------------- */
/*   Marker values                                                           */
/* ------------------------------------------------------------------------- */

extern char *describe_mv(int mval)
{   switch(mval)
    {   case NULL_MV:       return("null");

        /*  Marker values used in ordinary story file backpatching  */

        case DWORD_MV:      return("dictionary word");
        case STRING_MV:     return("string literal");
        case INCON_MV:      return("system constant");
        case IROUTINE_MV:   return("routine");
        case VROUTINE_MV:   return("veneer routine");
        case ARRAY_MV:      return("internal array");
        case NO_OBJS_MV:    return("the number of objects");
        case INHERIT_MV:    return("inherited common p value");
        case INDIVPT_MV:    return("indiv prop table address");
        case INHERIT_INDIV_MV: return("inherited indiv p value");
        case MAIN_MV:       return("ref to Main");
        case SYMBOL_MV:     return("ref to symbol value");

        /*  Additional marker values used in Glulx backpatching
            (IDENT_MV is not really used at all any more) */

        case VARIABLE_MV:   return("global variable");
        case IDENT_MV:      return("prop identifier number");
        case ACTION_MV:     return("action");
        case OBJECT_MV:     return("internal object");

    }
    return("** No such MV **");
}

/* ------------------------------------------------------------------------- */
/*   The mending operation                                                   */
/* ------------------------------------------------------------------------- */

int backpatch_marker, backpatch_size, backpatch_error_flag;

static int32 backpatch_value_z(int32 value)
{   /*  Corrects the quantity "value" according to backpatch_marker  */

    ASSERT_ZCODE();

    if (bpatch_trace_setting)
        printf("BP %s applied to %04x giving ",
            describe_mv(backpatch_marker), value);

    switch(backpatch_marker)
    {   case STRING_MV:
            value += strings_offset/scale_factor; break;
        case ARRAY_MV:
            value += variables_offset; break;
        case STATIC_ARRAY_MV:
            value += static_arrays_offset; break;
        case IROUTINE_MV:
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset/scale_factor;
            break;
        case VROUTINE_MV:
            if ((value<0) || (value>=VENEER_ROUTINES))
            {
                if (compiler_error
                    ("Backpatch veneer routine number out of range"))
                {   printf("Illegal BP veneer routine number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            value = veneer_routine_address[value]; 
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset/scale_factor;
            break;
        case NO_OBJS_MV:
            value = no_objects; break;
        case INCON_MV:
            if ((value<0) || (value>=NO_SYSTEM_CONSTANTS))
            {
                if (compiler_error
                    ("Backpatch system constant number out of range"))
                {   printf("Illegal BP system constant number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            value = value_of_system_constant(value); break;
        case DWORD_MV:
            value = dictionary_offset + 7 +
                    final_dict_order[value]*(DICT_ENTRY_BYTE_LENGTH);
            break;
        case ACTION_MV:
            break;
        case INHERIT_MV:
            value = 256*zmachine_paged_memory[value + prop_values_offset]
                    + zmachine_paged_memory[value + prop_values_offset + 1];
            break;
        case INHERIT_INDIV_MV:
            value = 256*zmachine_paged_memory[value
                        + individuals_offset]
                    + zmachine_paged_memory[value
                        + individuals_offset + 1];
            break;
        case INDIVPT_MV:
            value += individuals_offset;
            break;
        case MAIN_MV:
            value = symbol_index("Main", -1);
            if (symbols[value].type != ROUTINE_T)
                error("No 'Main' routine has been defined");
            symbols[value].flags |= USED_SFLAG;
            value = symbols[value].value;
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset/scale_factor;
            break;
        case SYMBOL_MV:
            if ((value<0) || (value>=no_symbols))
            {
                if (compiler_error("Backpatch symbol number out of range"))
                {   printf("Illegal BP symbol number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            if (symbols[value].flags & UNKNOWN_SFLAG)
            {   if (!(symbols[value].flags & UERROR_SFLAG))
                {   symbols[value].flags |= UERROR_SFLAG;
                    error_named_at("No such constant as",
                        symbols[value].name, symbols[value].line);
                }
            }
            else
            if (symbols[value].flags & CHANGE_SFLAG)
            {   symbols[value].flags &= (~(CHANGE_SFLAG));
                backpatch_marker = (symbols[value].marker);
                if ((backpatch_marker < 0)
                    || (backpatch_marker > LARGEST_BPATCH_MV))
                {
                    compiler_error_named(
                        "Illegal backpatch marker attached to symbol",
                        symbols[value].name);
                    backpatch_error_flag = TRUE;
                }
                else
                    symbols[value].value = backpatch_value_z((symbols[value].value) % 0x10000);
            }

            symbols[value].flags |= USED_SFLAG;
            {   int t = symbols[value].type;
                value = symbols[value].value;
                switch(t)
                {   case ROUTINE_T: 
                        if (OMIT_UNUSED_ROUTINES)
                            value = df_stripped_address_for_address(value);
                        value += code_offset/scale_factor; 
                        break;
                    case ARRAY_T: value += variables_offset; break;
                    case STATIC_ARRAY_T: value += static_arrays_offset; break;
                }
            }
            break;
        default:
            if (compiler_error("Illegal backpatch marker"))
            {   printf("Illegal backpatch marker %d value %04x\n",
                    backpatch_marker, value);
                backpatch_error_flag = TRUE;
            }
            break;
    }

    if (bpatch_trace_setting) printf(" %04x\n", value);

    return(value);
}

static int32 backpatch_value_g(int32 value)
{   /*  Corrects the quantity "value" according to backpatch_marker  */
    int32 valaddr;

    ASSERT_GLULX();

    if (bpatch_trace_setting)
        printf("BP %s applied to %04x giving ",
            describe_mv(backpatch_marker), value);

    switch(backpatch_marker)
    {
        case STRING_MV:
            if (value <= 0 || value > no_strings)
              compiler_error("Illegal string marker.");
            value = strings_offset + compressed_offsets[value-1]; break;
        case IROUTINE_MV:
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset;
            break;
        case ARRAY_MV:
            value += arrays_offset; break;
        case STATIC_ARRAY_MV:
            value += static_arrays_offset; break;
        case VARIABLE_MV:
            value = variables_offset + (4*value); break;
        case OBJECT_MV:
            value = object_tree_offset + (OBJECT_BYTE_LENGTH*(value-1)); 
            break;
        case VROUTINE_MV:
            if ((value<0) || (value>=VENEER_ROUTINES))
            {
                if (compiler_error
                    ("Backpatch veneer routine number out of range"))
                {   printf("Illegal BP veneer routine number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            value = veneer_routine_address[value];
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset;
            break;
        case NO_OBJS_MV:
            value = no_objects; break;
        case INCON_MV:
            if ((value<0) || (value>=NO_SYSTEM_CONSTANTS))
            {
                if (compiler_error
                    ("Backpatch system constant number out of range"))
                {   printf("Illegal BP system constant number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            value = value_of_system_constant(value); break;
        case DWORD_MV:
            value = dictionary_offset + 4 
              + final_dict_order[value]*DICT_ENTRY_BYTE_LENGTH;
            break;
        case ACTION_MV:
            break;
        case INHERIT_MV:
            valaddr = (prop_values_offset - Write_RAM_At) + value;
            value = ReadInt32(zmachine_paged_memory + valaddr);
            break;
        case INHERIT_INDIV_MV:
            error("*** No individual property storage in Glulx ***");
            break;
        case INDIVPT_MV:
            value += individuals_offset;
            break;
        case MAIN_MV:
            value = symbol_index("Main", -1);
            if (symbols[value].type != ROUTINE_T)
                error("No 'Main' routine has been defined");
            symbols[value].flags |= USED_SFLAG;
            value = symbols[value].value;
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset;
            break;
        case SYMBOL_MV:
            if ((value<0) || (value>=no_symbols))
            {
                if (compiler_error("Backpatch symbol number out of range"))
                {   printf("Illegal BP symbol number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            if (symbols[value].flags & UNKNOWN_SFLAG)
            {   if (!(symbols[value].flags & UERROR_SFLAG))
                {   symbols[value].flags |= UERROR_SFLAG;
                    error_named_at("No such constant as",
                        symbols[value].name, symbols[value].line);
                }
            }
            else
            if (symbols[value].flags & CHANGE_SFLAG)
            {   symbols[value].flags &= (~(CHANGE_SFLAG));
                backpatch_marker = symbols[value].marker;
                if ((backpatch_marker < 0)
                    || (backpatch_marker > LARGEST_BPATCH_MV))
                {
                    compiler_error_named(
                        "Illegal backpatch marker attached to symbol",
                        symbols[value].name);
                    backpatch_error_flag = TRUE;
                }
                else
                    symbols[value].value = backpatch_value_g(symbols[value].value);
            }

            symbols[value].flags |= USED_SFLAG;
            {   int t = symbols[value].type;
                value = symbols[value].value;
                switch(t)
                {
                    case ROUTINE_T:
                        if (OMIT_UNUSED_ROUTINES)
                            value = df_stripped_address_for_address(value);
                        value += code_offset;
                        break;
                    case ARRAY_T: value += arrays_offset; break;
                    case STATIC_ARRAY_T: value += static_arrays_offset; break;
                    case OBJECT_T:
                    case CLASS_T:
                      value = object_tree_offset + 
                        (OBJECT_BYTE_LENGTH*(value-1)); 
                      break;
                    case ATTRIBUTE_T:
                      /* value is unchanged */
                      break;
                    case CONSTANT_T:
                    case INDIVIDUAL_PROPERTY_T:
                    case PROPERTY_T:
                      /* value is unchanged */
                      break;
                    default:
                      error("*** Illegal backpatch marker in forward-declared \
symbol");
                      break;
                }
            }
            break;
        default:
            if (compiler_error("Illegal backpatch marker"))
            {   printf("Illegal backpatch marker %d value %04x\n",
                    backpatch_marker, value);
                backpatch_error_flag = TRUE;
            }
            break;
    }

    if (bpatch_trace_setting) printf(" %04x\n", value);

    return(value);
}

extern int32 backpatch_value(int32 value)
{
  if (!glulx_mode)
    return backpatch_value_z(value);
  else
    return backpatch_value_g(value);
}

static void backpatch_zmachine_z(int mv, int zmachine_area, int32 offset)
{   
    if (mv == OBJECT_MV) return;
    if (mv == IDENT_MV) return;
    if (mv == ACTION_MV) return;

    if (bpatch_trace_setting >= 2)
        printf("BP added: MV %d ZA %d Off %04x\n", mv, zmachine_area, offset);

    ensure_memory_list_available(&zmachine_backpatch_table_memlist, zmachine_backpatch_size+4);
    zmachine_backpatch_table[zmachine_backpatch_size++] = mv;
    zmachine_backpatch_table[zmachine_backpatch_size++] = zmachine_area;
    zmachine_backpatch_table[zmachine_backpatch_size++] = offset/256;
    zmachine_backpatch_table[zmachine_backpatch_size++] = offset%256;
}

static void backpatch_zmachine_g(int mv, int zmachine_area, int32 offset)
{   
    if (mv == IDENT_MV) return;
    if (mv == ACTION_MV) return;

/* The backpatch table format for Glulx:
   First, the marker byte.
   Then, the zmachine area being patched.
   Then the four-byte address.
*/

    if (bpatch_trace_setting >= 2)
        printf("BP added: MV %d ZA %d Off %06x\n", mv, zmachine_area, offset);

    ensure_memory_list_available(&zmachine_backpatch_table_memlist, zmachine_backpatch_size+6);
    zmachine_backpatch_table[zmachine_backpatch_size++] = mv;
    zmachine_backpatch_table[zmachine_backpatch_size++] = zmachine_area;
    zmachine_backpatch_table[zmachine_backpatch_size++] = (offset >> 24) & 0xFF;
    zmachine_backpatch_table[zmachine_backpatch_size++] = (offset >> 16) & 0xFF;
    zmachine_backpatch_table[zmachine_backpatch_size++] = (offset >> 8) & 0xFF;
    zmachine_backpatch_table[zmachine_backpatch_size++] = (offset) & 0xFF;
}

extern void backpatch_zmachine(int mv, int zmachine_area, int32 offset)
{
  if (!glulx_mode)
    backpatch_zmachine_z(mv, zmachine_area, offset);
  else
    backpatch_zmachine_g(mv, zmachine_area, offset);
}

extern void backpatch_zmachine_image_z(void)
{   int bm = 0, zmachine_area; int32 offset, value, addr = 0;
    ASSERT_ZCODE();
    backpatch_error_flag = FALSE;
    while (bm < zmachine_backpatch_size)
    {   backpatch_marker
            = zmachine_backpatch_table[bm];
        zmachine_area
            = zmachine_backpatch_table[bm+1];
        offset
          = 256*zmachine_backpatch_table[bm+2]
            + zmachine_backpatch_table[bm+3];
        bm += 4;

        switch(zmachine_area)
        {   case PROP_DEFAULTS_ZA:   addr = prop_defaults_offset; break;
            case PROP_ZA:            addr = prop_values_offset; break;
            case INDIVIDUAL_PROP_ZA: addr = individuals_offset; break;
            case DYNAMIC_ARRAY_ZA:   addr = variables_offset; break;
            case STATIC_ARRAY_ZA:    addr = static_arrays_offset; break;
            default:
                if (compiler_error("Illegal area to backpatch"))
                    backpatch_error_flag = TRUE;
        }
        addr += offset;

        value = 256*zmachine_paged_memory[addr]
                + zmachine_paged_memory[addr+1];
        value = backpatch_value_z(value);
        zmachine_paged_memory[addr] = value/256;
        zmachine_paged_memory[addr+1] = value%256;

        if (backpatch_error_flag)
        {   backpatch_error_flag = FALSE;
            printf("*** MV %d ZA %d Off %04x ***\n",
                backpatch_marker, zmachine_area, offset);
        }
    }
}

extern void backpatch_zmachine_image_g(void)
{   int bm = 0, zmachine_area; int32 offset, value, addr = 0;
    ASSERT_GLULX();
    backpatch_error_flag = FALSE;
    while (bm < zmachine_backpatch_size)
    {   backpatch_marker
            = zmachine_backpatch_table[bm];
        zmachine_area
            = zmachine_backpatch_table[bm+1];
        offset = zmachine_backpatch_table[bm+2];
        offset = (offset << 8) |
          zmachine_backpatch_table[bm+3];
        offset = (offset << 8) |
          zmachine_backpatch_table[bm+4];
        offset = (offset << 8) |
          zmachine_backpatch_table[bm+5];
        bm += 6;

            switch(zmachine_area) {   
        case PROP_DEFAULTS_ZA:   addr = prop_defaults_offset+4; break;
        case PROP_ZA:            addr = prop_values_offset; break;
        case INDIVIDUAL_PROP_ZA: addr = individuals_offset; break;
        case DYNAMIC_ARRAY_ZA:   addr = arrays_offset; break;
        case GLOBALVAR_ZA:       addr = variables_offset; break;
        /* STATIC_ARRAY_ZA is in ROM and therefore not handled here */
        default:
            if (compiler_error("Illegal area to backpatch"))
              backpatch_error_flag = TRUE;
        }
        addr = addr + offset - Write_RAM_At;

        value = (zmachine_paged_memory[addr] << 24)
                | (zmachine_paged_memory[addr+1] << 16)
                | (zmachine_paged_memory[addr+2] << 8)
                | (zmachine_paged_memory[addr+3]);
        value = backpatch_value_g(value);
        zmachine_paged_memory[addr] = (value >> 24) & 0xFF;
        zmachine_paged_memory[addr+1] = (value >> 16) & 0xFF;
        zmachine_paged_memory[addr+2] = (value >> 8) & 0xFF;
        zmachine_paged_memory[addr+3] = (value) & 0xFF;

        if (backpatch_error_flag)
        {   backpatch_error_flag = FALSE;
            printf("*** MV %d ZA %d Off %04x ***\n",
                backpatch_marker, zmachine_area, offset);
        }
    }
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_bpatch_vars(void)
{   zcode_backpatch_table = NULL;
    staticarray_backpatch_table = NULL;
    zmachine_backpatch_table = NULL;
}

extern void bpatch_begin_pass(void)
{   zcode_backpatch_size = 0;
    staticarray_backpatch_size = 0;
    zmachine_backpatch_size = 0;
}

extern void bpatch_allocate_arrays(void)
{
    initialise_memory_list(&zcode_backpatch_table_memlist,
        sizeof(uchar), 128, (void**)&zcode_backpatch_table,
        "code backpatch table");
    initialise_memory_list(&staticarray_backpatch_table_memlist,
        sizeof(uchar), 128, (void**)&staticarray_backpatch_table,
        "static array backpatch table");
    initialise_memory_list(&zmachine_backpatch_table_memlist,
        sizeof(uchar), 128, (void**)&zmachine_backpatch_table,
        "machine backpatch table");
}

extern void bpatch_free_arrays(void)
{   deallocate_memory_list(&zcode_backpatch_table_memlist);
    deallocate_memory_list(&staticarray_backpatch_table_memlist);
    deallocate_memory_list(&zmachine_backpatch_table_memlist);
}

/* ========================================================================= */
