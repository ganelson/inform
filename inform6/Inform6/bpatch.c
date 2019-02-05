/* ------------------------------------------------------------------------- */
/*   "bpatch" : Keeps track of, and finally acts on, backpatch markers,      */
/*              correcting symbol values not known at compilation time       */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

memory_block zcode_backpatch_table, zmachine_backpatch_table;
int32 zcode_backpatch_size, zmachine_backpatch_size;

/* ------------------------------------------------------------------------- */
/*   The mending operation                                                   */
/* ------------------------------------------------------------------------- */

int backpatch_marker, backpatch_size, backpatch_error_flag;

static int32 backpatch_value_z(int32 value)
{   /*  Corrects the quantity "value" according to backpatch_marker  */

    ASSERT_ZCODE();

    if (asm_trace_level >= 4)
        printf("BP %s applied to %04x giving ",
            describe_mv(backpatch_marker), value);

    switch(backpatch_marker)
    {   case STRING_MV:
            value += strings_offset/scale_factor; break;
        case ARRAY_MV:
            value += variables_offset; break;
        case IROUTINE_MV:
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset/scale_factor;
            break;
        case VROUTINE_MV:
            if ((value<0) || (value>=VENEER_ROUTINES))
            {   if (no_link_errors > 0) break;
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
            {   if (no_link_errors > 0) break;
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
                    final_dict_order[value]*((version_number==3)?7:9);
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
            if (stypes[value] != ROUTINE_T)
                error("No 'Main' routine has been defined");
            sflags[value] |= USED_SFLAG;
            value = svals[value];
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset/scale_factor;
            break;
        case SYMBOL_MV:
            if ((value<0) || (value>=no_symbols))
            {   if (no_link_errors > 0) break;
                if (compiler_error("Backpatch symbol number out of range"))
                {   printf("Illegal BP symbol number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            if (sflags[value] & UNKNOWN_SFLAG)
            {   if (!(sflags[value] & UERROR_SFLAG))
                {   sflags[value] |= UERROR_SFLAG;
                    error_named_at("No such constant as",
                        (char *) symbs[value], slines[value]);
                }
            }
            else
            if (sflags[value] & CHANGE_SFLAG)
            {   sflags[value] &= (~(CHANGE_SFLAG));
                backpatch_marker = (svals[value]/0x10000);
                if ((backpatch_marker < 0)
                    || (backpatch_marker > LARGEST_BPATCH_MV))
                {
                    if (no_link_errors == 0)
                    {   compiler_error_named(
                        "Illegal backpatch marker attached to symbol",
                        (char *) symbs[value]);
                        backpatch_error_flag = TRUE;
                    }
                }
                else
                    svals[value] = backpatch_value_z((svals[value]) % 0x10000);
            }

            sflags[value] |= USED_SFLAG;
            {   int t = stypes[value];
                value = svals[value];
                switch(t)
                {   case ROUTINE_T: 
                        if (OMIT_UNUSED_ROUTINES)
                            value = df_stripped_address_for_address(value);
                        value += code_offset/scale_factor; 
                        break;
                    case ARRAY_T: value += variables_offset; break;
                }
            }
            break;
        default:
            if (no_link_errors > 0) break;
            if (compiler_error("Illegal backpatch marker"))
            {   printf("Illegal backpatch marker %d value %04x\n",
                    backpatch_marker, value);
                backpatch_error_flag = TRUE;
            }
            break;
    }

    if (asm_trace_level >= 4) printf(" %04x\n", value);

    return(value);
}

static int32 backpatch_value_g(int32 value)
{   /*  Corrects the quantity "value" according to backpatch_marker  */
    int32 valaddr;

    ASSERT_GLULX();

    if (asm_trace_level >= 4)
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
        case VARIABLE_MV:
            value = variables_offset + (4*value); break;
        case OBJECT_MV:
            value = object_tree_offset + (OBJECT_BYTE_LENGTH*(value-1)); 
            break;
        case VROUTINE_MV:
            if ((value<0) || (value>=VENEER_ROUTINES))
            {   if (no_link_errors > 0) break;
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
            {   if (no_link_errors > 0) break;
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
            if (stypes[value] != ROUTINE_T)
                error("No 'Main' routine has been defined");
            sflags[value] |= USED_SFLAG;
            value = svals[value];
            if (OMIT_UNUSED_ROUTINES)
                value = df_stripped_address_for_address(value);
            value += code_offset;
            break;
        case SYMBOL_MV:
            if ((value<0) || (value>=no_symbols))
            {   if (no_link_errors > 0) break;
                if (compiler_error("Backpatch symbol number out of range"))
                {   printf("Illegal BP symbol number: %d\n", value);
                    backpatch_error_flag = TRUE;
                }
                value = 0;
                break;
            }
            if (sflags[value] & UNKNOWN_SFLAG)
            {   if (!(sflags[value] & UERROR_SFLAG))
                {   sflags[value] |= UERROR_SFLAG;
                    error_named_at("No such constant as",
                        (char *) symbs[value], slines[value]);
                }
            }
            else
            if (sflags[value] & CHANGE_SFLAG)
            {   sflags[value] &= (~(CHANGE_SFLAG));
                backpatch_marker = smarks[value];
                if ((backpatch_marker < 0)
                    || (backpatch_marker > LARGEST_BPATCH_MV))
                {
                    if (no_link_errors == 0)
                    {   compiler_error_named(
                        "Illegal backpatch marker attached to symbol",
                        (char *) symbs[value]);
                        backpatch_error_flag = TRUE;
                    }
                }
                else
                    svals[value] = backpatch_value_g(svals[value]);
            }

            sflags[value] |= USED_SFLAG;
            {   int t = stypes[value];
                value = svals[value];
                switch(t)
                {
                    case ROUTINE_T:
                        if (OMIT_UNUSED_ROUTINES)
                            value = df_stripped_address_for_address(value);
                        value += code_offset;
                        break;
                    case ARRAY_T: value += arrays_offset; break;
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
            if (no_link_errors > 0) break;
            if (compiler_error("Illegal backpatch marker"))
            {   printf("Illegal backpatch marker %d value %04x\n",
                    backpatch_marker, value);
                backpatch_error_flag = TRUE;
            }
            break;
    }

    if (asm_trace_level >= 4) printf(" %04x\n", value);

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
{   if (module_switch)
    {   if (zmachine_area == PROP_DEFAULTS_ZA) return;
    }
    else
    {   if (mv == OBJECT_MV) return;
        if (mv == IDENT_MV) return;
        if (mv == ACTION_MV) return;
    }

    /* printf("MV %d ZA %d Off %04x\n", mv, zmachine_area, offset); */

    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, mv);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, zmachine_area);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, offset/256);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, offset%256);
}

static void backpatch_zmachine_g(int mv, int zmachine_area, int32 offset)
{   if (module_switch)
    {   if (zmachine_area == PROP_DEFAULTS_ZA) return;
    }
    else
    {   if (mv == IDENT_MV) return;
        if (mv == ACTION_MV) return;
    }

/* The backpatch table format for Glulx:
   First, the marker byte.
   Then, the zmachine area being patched.
   Then the four-byte address.
*/

/*    printf("+MV %d ZA %d Off %06x\n", mv, zmachine_area, offset);  */

    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, mv);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, zmachine_area);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, (offset >> 24) & 0xFF);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, (offset >> 16) & 0xFF);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, (offset >> 8) & 0xFF);
    write_byte_to_memory_block(&zmachine_backpatch_table,
        zmachine_backpatch_size++, (offset) & 0xFF);
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
            = read_byte_from_memory_block(&zmachine_backpatch_table, bm);
        zmachine_area
            = read_byte_from_memory_block(&zmachine_backpatch_table, bm+1);
        offset
          = 256*read_byte_from_memory_block(&zmachine_backpatch_table,bm+2)
            + read_byte_from_memory_block(&zmachine_backpatch_table, bm+3);
        bm += 4;

        switch(zmachine_area)
        {   case PROP_DEFAULTS_ZA:   addr = prop_defaults_offset; break;
            case PROP_ZA:            addr = prop_values_offset; break;
            case INDIVIDUAL_PROP_ZA: addr = individuals_offset; break;
            case DYNAMIC_ARRAY_ZA:   addr = variables_offset; break;
            default:
                if (no_link_errors == 0)
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
            if (no_link_errors == 0)
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
            = read_byte_from_memory_block(&zmachine_backpatch_table, bm);
        zmachine_area
            = read_byte_from_memory_block(&zmachine_backpatch_table, bm+1);
        offset = read_byte_from_memory_block(&zmachine_backpatch_table, bm+2);
        offset = (offset << 8) |
          read_byte_from_memory_block(&zmachine_backpatch_table, bm+3);
        offset = (offset << 8) |
          read_byte_from_memory_block(&zmachine_backpatch_table, bm+4);
        offset = (offset << 8) |
          read_byte_from_memory_block(&zmachine_backpatch_table, bm+5);
            bm += 6;

        /* printf("-MV %d ZA %d Off %06x\n", backpatch_marker, zmachine_area, offset);  */

            switch(zmachine_area) {   
        case PROP_DEFAULTS_ZA:   addr = prop_defaults_offset+4; break;
        case PROP_ZA:            addr = prop_values_offset; break;
        case INDIVIDUAL_PROP_ZA: addr = individuals_offset; break;
        case ARRAY_ZA:           addr = arrays_offset; break;
        case GLOBALVAR_ZA:       addr = variables_offset; break;
        default:
          if (no_link_errors == 0)
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
            if (no_link_errors == 0)
                printf("*** MV %d ZA %d Off %04x ***\n",
                    backpatch_marker, zmachine_area, offset);
        }
    }
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_bpatch_vars(void)
{   initialise_memory_block(&zcode_backpatch_table);
    initialise_memory_block(&zmachine_backpatch_table);
}

extern void bpatch_begin_pass(void)
{   zcode_backpatch_size = 0;
    zmachine_backpatch_size = 0;
}

extern void bpatch_allocate_arrays(void)
{
}

extern void bpatch_free_arrays(void)
{   deallocate_memory_block(&zcode_backpatch_table);
    deallocate_memory_block(&zmachine_backpatch_table);
}

/* ========================================================================= */
