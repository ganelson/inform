/* ------------------------------------------------------------------------- */
/*   "tables" :  Constructs the story file or module (the output) up to the  */
/*               end of dynamic memory, gluing together all the required     */
/*               tables.                                                     */
/*                                                                           */
/*   Part of Inform 6.34                                                     */
/*   copyright (c) Graham Nelson 1993 - 2020                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

uchar *zmachine_paged_memory;          /* Where we shall store the story file
                                          constructed (contains all of paged
                                          memory, i.e. all but code and the
                                          static strings: allocated only when
                                          we know how large it needs to be,
                                          at the end of the compilation pass */

/* In Glulx, zmachine_paged_memory contains all of RAM -- i.e. all but
   the header, the code, the static arrays, and the static strings. */

/* ------------------------------------------------------------------------- */
/*   Offsets of various areas in the Z-machine: these are set to nominal     */
/*   values before the compilation pass, and to their calculated final       */
/*   values only when construct_storyfile() happens.  These are then used to */
/*   backpatch the incorrect values now existing in the Z-machine which      */
/*   used these nominal values.                                              */
/*   Most of the nominal values are 0x800 because this is guaranteed to      */
/*   be assembled as a long constant if it's needed in code, since the       */
/*   largest possible value of scale_factor is 8 and 0x800/8 = 256.          */
/*                                                                           */
/*   In Glulx, I use 0x12345 instead of 0x800. This will always be a long    */
/*   (32-bit) constant, since there's no scale_factor.                       */
/* ------------------------------------------------------------------------- */

int32 code_offset,
      actions_offset,
      preactions_offset,
      dictionary_offset,
      adjectives_offset,
      variables_offset,
      strings_offset,
      class_numbers_offset,
      individuals_offset,
      identifier_names_offset,
      array_names_offset,
      prop_defaults_offset,
      prop_values_offset,
      static_memory_offset,
      attribute_names_offset,
      action_names_offset,
      fake_action_names_offset,
      routine_names_offset,
      constant_names_offset,
      routines_array_offset,
      constants_array_offset,
      routine_flags_array_offset,
      global_names_offset,
      global_flags_array_offset,
      array_flags_array_offset,
      static_arrays_offset;
int32 arrays_offset,
      object_tree_offset,
      grammar_table_offset,
      abbreviations_offset; /* Glulx */

int32 Out_Size, Write_Code_At, Write_Strings_At;
int32 RAM_Size, Write_RAM_At; /* Glulx */

/* ------------------------------------------------------------------------- */
/*   Story file header settings.   (Written to in "directs.c" and "asm.c".)  */
/* ------------------------------------------------------------------------- */

int release_number,                    /* Release number game is to have     */
    statusline_flag;                   /* Either TIME_STYLE or SCORE_STYLE   */

int serial_code_given_in_program       /* If TRUE, a Serial directive has    */
    = FALSE;                           /* specified this 6-digit serial code */
char serial_code_buffer[7];            /* (overriding the usual date-stamp)  */
int flags2_requirements[16];           /* An array of which bits in Flags 2 of
                                          the header will need to be set:
                                          e.g. if the save_undo / restore_undo
                                          opcodes are ever assembled, we have
                                          to set the "games want UNDO" bit.
                                          Values are 0 or 1.                 */

/* ------------------------------------------------------------------------- */
/*   Construct story/module file (up to code area start).                    */
/*                                                                           */
/*   (To understand what follows, you really need to look at the run-time    */
/*   system's specification, the Z-Machine Standards document.)              */
/* ------------------------------------------------------------------------- */

extern void write_serial_number(char *buffer)
{
    /*  Note that this function may require modification for "ANSI" compilers
        which do not provide the standard time functions: what is needed is
        the ability to work out today's date                                 */

    time_t tt;  tt=time(0);
    if (serial_code_given_in_program)
        strcpy(buffer, serial_code_buffer);
    else
#ifdef TIME_UNAVAILABLE
        sprintf(buffer,"970000");
#else
        strftime(buffer,10,"%y%m%d",localtime(&tt));
#endif
}

static void percentage(char *name, int32 x, int32 total)
{   printf("   %-20s %2d.%d%%\n",name,x*100/total,(x*1000/total)%10);
}

static char *version_name(int v)
{
  if (!glulx_mode) {
    switch(v)
    {   case 3: return "Standard";
        case 4: return "Plus";
        case 5: return "Advanced";
        case 6: return "Graphical";
        case 8: return "Extended";
    }
    return "experimental format";
  }
  else {
    return "Glulx";
  }
}

static int32 rough_size_of_paged_memory_z(void)
{
    /*  This function calculates a modest over-estimate of the amount of
        memory required to store the Z-machine's paged memory area
        (that is, everything up to the start of the code area).              */

    int32 total, i;

    ASSERT_ZCODE();

    total = 64                                                     /* header */
            + 2 + subtract_pointers(low_strings_top, low_strings)
                                                         /* low strings pool */
            + 6*32;                                   /* abbreviations table */

    total += 8;                                    /* header extension table */
    if (ZCODE_HEADER_EXT_WORDS>3) total += (ZCODE_HEADER_EXT_WORDS-3)*2;

    if (alphabet_modified) total += 78;               /* character set table */

    if (zscii_defn_modified)                    /* Unicode translation table */
        total += 2 + 2*zscii_high_water_mark;

    total += 2*((version_number==3)?31:63)        /* property default values */
            + no_objects*((version_number==3)?9:14)     /* object tree table */
            + properties_table_size            /* property values of objects */
            + (no_classes+1)*(module_switch?4:2)
                                               /* class object numbers table */
            + no_symbols*2                       /* names of numerous things */
            + individuals_length                 /* tables of prop variables */
            + dynamic_array_area_size;               /* variables and arrays */

    for (i=0; i<no_Inform_verbs; i++)
        total += 2 + 1 +                        /* address of grammar table, */
                                                  /* number of grammar lines */
                 ((grammar_version_number == 1)?
                  (8*Inform_verbs[i].lines):0);             /* grammar lines */

    if (grammar_version_number != 1)
        total += grammar_lines_top;            /* size of grammar lines area */

    total +=  2 + 4*no_adjectives                        /* adjectives table */
              + 2*no_actions                              /* action routines */
              + 2*no_grammar_token_routines;     /* general parsing routines */

    total += (subtract_pointers(dictionary_top, dictionary))  /* dictionary */
             + ((module_switch)?30:0);                        /* module map */

    total += static_array_area_size;                       /* static arrays */

    total += scale_factor*0x100            /* maximum null bytes before code */
            + 1000;             /* fudge factor (in case the above is wrong) */

    return(total);
}

static int32 rough_size_of_paged_memory_g(void)
{
    /*  This function calculates a modest over-estimate of the amount of
        memory required to store the machine's paged memory area
        (that is, everything past the start of RAM). */

    int32 total;

    ASSERT_GLULX();

    /* No header for us! */
    total = 1000; /* bit of a fudge factor */

    total += dynamic_array_area_size; /* arrays and global variables */

    total += no_objects * OBJECT_BYTE_LENGTH; /* object tables */
    total += properties_table_size; /* property tables */
    total += no_properties * 4; /* property defaults table */

    total += 4 + no_classes * 4; /* class prototype object numbers */

    total += 32; /* address/length of the identifier tables */
    total += no_properties * 4;
    total += (no_individual_properties-INDIV_PROP_START) * 4;
    total += (NUM_ATTR_BYTES*8) * 4;
    total += (no_actions + no_fake_actions) * 4;
    total += 4 + no_arrays * 4;

    total += 4 + no_Inform_verbs * 4; /* index of grammar tables */
    total += grammar_lines_top; /* grammar tables */

    total += 4 + no_actions * 4; /* actions functions table */

    total += 4;
    total += subtract_pointers(dictionary_top, dictionary);

    while (total % GPAGESIZE)
      total++;

    return(total);
}

static void construct_storyfile_z(void)
{   uchar *p;
    int32 i, j, k, l, mark, objs, strings_length, code_length,
          limit=0, excess=0, extend_offset=0, headerext_length=0;
    int32 globals_at=0, link_table_at=0, dictionary_at=0, actions_at=0, preactions_at=0,
          abbrevs_at=0, prop_defaults_at=0, object_tree_at=0, object_props_at=0,
          map_of_module=0, grammar_table_at=0, charset_at=0, headerext_at=0,
          terminating_chars_at=0, unicode_at=0, id_names_length=0,
          static_arrays_at=0;
    int skip_backpatching = FALSE;
    char *output_called = (module_switch)?"module":"story file";

    ASSERT_ZCODE();

    individual_name_strings =
        my_calloc(sizeof(int32), no_individual_properties,
            "identifier name strings");
    action_name_strings =
        my_calloc(sizeof(int32), no_actions + no_fake_actions,
            "action name strings");
    attribute_name_strings =
        my_calloc(sizeof(int32), 48,
            "attribute name strings");
    array_name_strings =
        my_calloc(sizeof(int32),
            no_symbols,
            "array name strings");

    write_the_identifier_names();

    /*  We now know how large the buffer to hold our construction has to be  */

    zmachine_paged_memory = my_malloc(rough_size_of_paged_memory_z(),
        "output buffer");

    /*  Foolish code to make this routine compile on all ANSI compilers      */

    p = (uchar *) zmachine_paged_memory;

    /*  In what follows, the "mark" will move upwards in memory: at various
        points its value will be recorded for milestones like
        "dictionary table start".  It begins at 0x40, just after the header  */

    mark = 0x40;

    /*  ----------------- Low Strings and Abbreviations -------------------- */

    p[mark]=0x80; p[mark+1]=0; mark+=2;        /* Start the low strings pool
                                         with a useful default string, "   " */

    for (i=0; i+low_strings<low_strings_top; mark++, i++) /* Low strings pool */
        p[0x42+i]=low_strings[i];

    abbrevs_at = mark;
    for (i=0; i<3*32; i++)                       /* Initially all 96 entries */
    {   p[mark++]=0; p[mark++]=0x20;                     /* are set to "   " */
    }
    for (i=0; i<no_abbreviations; i++)            /* Write any abbreviations */
    {   j=abbrev_values[i];                            /* into banks 2 and 3 */
        p[abbrevs_at+64+2*i]=j/256;               /* (bank 1 is reserved for */
        p[abbrevs_at+65+2*i]=j%256;                   /* "variable strings") */
    }

    /*  ------------------- Header extension table ------------------------- */

    headerext_at = mark;
    headerext_length = ZCODE_HEADER_EXT_WORDS;
    if (zscii_defn_modified) {
        /* Need at least 3 words for unicode table address */
        if (headerext_length < 3)
            headerext_length = 3;
    }
    if (ZCODE_HEADER_FLAGS_3) {
        /* Need at least 4 words for the flags-3 field (ZSpec 1.1) */
        if (headerext_length < 4)
            headerext_length = 4;
    }
    p[mark++] = 0; p[mark++] = headerext_length;
    for (i=0; i<headerext_length; i++)
    {   p[mark++] = 0; p[mark++] = 0;
    }

    /*  -------------------- Z-character set table ------------------------- */

    if (alphabet_modified)
    {   charset_at = mark;
        for (i=0;i<3;i++) for (j=0;j<26;j++)
        {   if (alphabet[i][j] == '~') p[mark++] = '\"';
            else p[mark++] = alphabet[i][j];
        }
    }

    /*  ------------------ Unicode translation table ----------------------- */

    unicode_at = 0;
    if (zscii_defn_modified)
    {   unicode_at = mark;
        p[mark++] = zscii_high_water_mark;
        for (i=0;i<zscii_high_water_mark;i++)
        {   j = zscii_to_unicode(155 + i);
            if (j < 0 || j > 0xFFFF) {
                error("Z-machine Unicode translation table cannot contain characters beyond $FFFF.");
            }
            p[mark++] = j/256; p[mark++] = j%256;
        }
    }

    /*  -------------------- Objects and Properties ------------------------ */

    /* The object table must be word-aligned. The Z-machine spec does not
       require this, but the RA__Pr() veneer routine does. See 
       http://inform7.com/mantis/view.php?id=1712.
    */
    while ((mark%2) != 0) p[mark++]=0;

    prop_defaults_at = mark;

    p[mark++]=0; p[mark++]=0;

    for (i=2; i< ((version_number==3)?32:64); i++)
    {   p[mark++]=prop_default_value[i]/256;
        p[mark++]=prop_default_value[i]%256;
    }

    object_tree_at = mark;

    mark += ((version_number==3)?9:14)*no_objects;

    object_props_at = mark;

    for (i=0; i<properties_table_size; i++)
        p[mark+i]=properties_table[i];

    for (i=0, objs=object_tree_at; i<no_objects; i++)
    {
        if (version_number == 3)
        {   p[objs]=objectsz[i].atts[0];
            p[objs+1]=objectsz[i].atts[1];
            p[objs+2]=objectsz[i].atts[2];
            p[objs+3]=objectsz[i].atts[3];
            p[objs+4]=objectsz[i].parent;
            p[objs+5]=objectsz[i].next;
            p[objs+6]=objectsz[i].child;
            p[objs+7]=mark/256;
            p[objs+8]=mark%256;
            objs+=9;
        }
        else
        {   p[objs]=objectsz[i].atts[0];
            p[objs+1]=objectsz[i].atts[1];
            p[objs+2]=objectsz[i].atts[2];
            p[objs+3]=objectsz[i].atts[3];
            p[objs+4]=objectsz[i].atts[4];
            p[objs+5]=objectsz[i].atts[5];
            p[objs+6]=(objectsz[i].parent)/256;
            p[objs+7]=(objectsz[i].parent)%256;
            p[objs+8]=(objectsz[i].next)/256;
            p[objs+9]=(objectsz[i].next)%256;
            p[objs+10]=(objectsz[i].child)/256;
            p[objs+11]=(objectsz[i].child)%256;
            if (!module_switch)
            {   p[objs+12]=mark/256;
                p[objs+13]=mark%256;
            }
            else
            {   p[objs+12]=objectsz[i].propsize/256;
                p[objs+13]=objectsz[i].propsize%256;
            }
            objs+=14;
        }
        mark+=objectsz[i].propsize;
    }

    /*  ----------- Table of Class Prototype Object Numbers ---------------- */

    class_numbers_offset = mark;
    for (i=0; i<no_classes; i++)
    {   p[mark++] = class_object_numbers[i]/256;
        p[mark++] = class_object_numbers[i]%256;
        if (module_switch)
        {   p[mark++] = class_begins_at[i]/256;
            p[mark++] = class_begins_at[i]%256;
        }
    }
    p[mark++] = 0;
    p[mark++] = 0;

    /*  ------------------- Table of Identifier Names ---------------------- */

    identifier_names_offset = mark;

    if (!module_switch)
    {   p[mark++] = no_individual_properties/256;
        p[mark++] = no_individual_properties%256;
        for (i=1; i<no_individual_properties; i++)
        {   p[mark++] = individual_name_strings[i]/256;
            p[mark++] = individual_name_strings[i]%256;
        }

        attribute_names_offset = mark;
        for (i=0; i<48; i++)
        {   p[mark++] = attribute_name_strings[i]/256;
            p[mark++] = attribute_name_strings[i]%256;
        }

        action_names_offset = mark;
        fake_action_names_offset = mark + 2*no_actions;
        for (i=0; i<no_actions + no_fake_actions; i++)
        {   p[mark++] = action_name_strings[i]/256;
            p[mark++] = action_name_strings[i]%256;
        }

        array_names_offset = mark;
        global_names_offset = mark + 2*no_arrays;
        routine_names_offset = global_names_offset + 2*no_globals;
        constant_names_offset = routine_names_offset + 2*no_named_routines;
        for (i=0; i<no_arrays + no_globals
                    + no_named_routines + no_named_constants; i++)
        {   if ((i == no_arrays) && (define_INFIX_switch == FALSE)) break;
            p[mark++] = array_name_strings[i]/256;
            p[mark++] = array_name_strings[i]%256;
        }

        id_names_length = (mark - identifier_names_offset)/2;
    }
    routine_flags_array_offset = mark;

    if (define_INFIX_switch)
    {   for (i=0, k=1, l=0; i<no_named_routines; i++)
        {   if (sflags[named_routine_symbols[i]] & STAR_SFLAG) l=l+k;
            k=k*2;
            if (k==256) { p[mark++] = l; k=1; l=0; }
        }
        if (k!=1) p[mark++]=l;
    }

    /*  ---------------- Table of Indiv Property Values -------------------- */

    individuals_offset = mark;
    for (i=0; i<individuals_length; i++)
        p[mark++] = individuals_table[i];

    /*  ----------------- Variables and Dynamic Arrays --------------------- */

    globals_at = mark;

    for (i=0; i<dynamic_array_area_size; i++)
        p[mark++] = dynamic_array_area[i];

    for (i=0; i<240; i++)
    {   j=global_initial_value[i];
        p[globals_at+i*2]   = j/256; p[globals_at+i*2+1] = j%256;
    }

    /*  ------------------ Terminating Characters Table -------------------- */

    if (version_number >= 5)
    {   terminating_chars_at = mark;
        for (i=0; i<no_termcs; i++) p[mark++] = terminating_characters[i];
        p[mark++] = 0;
    }

    /*  ------------------------ Grammar Table ----------------------------- */

    if (grammar_version_number > 2)
    {   warning("This version of Inform is unable to produce the grammar \
table format requested (producing number 2 format instead)");
        grammar_version_number = 2;
    }

    grammar_table_at = mark;

    mark = mark + no_Inform_verbs*2;

    for (i=0; i<no_Inform_verbs; i++)
    {   p[grammar_table_at + i*2] = (mark/256);
        p[grammar_table_at + i*2 + 1] = (mark%256);
        p[mark++] = Inform_verbs[i].lines;
        for (j=0; j<Inform_verbs[i].lines; j++)
        {   k = Inform_verbs[i].l[j];
            if (grammar_version_number == 1)
            {   int m, n;
                p[mark+7] = grammar_lines[k+1];
                for (m=1;m<=6;m++) p[mark + m] = 0;
                k = k + 2; m = 1; n = 0;
                while ((grammar_lines[k] != 15) && (m<=6))
                {   p[mark + m] = grammar_lines[k];
                    if (grammar_lines[k] < 180) n++;
                    m++; k = k + 3;
                }
                p[mark] = n;
                mark = mark + 8;
            }
            else
            {   int tok;
                p[mark++] = grammar_lines[k++];
                p[mark++] = grammar_lines[k++];
                for (;;)
                {   tok = grammar_lines[k++];
                    p[mark++] = tok;
                    if (tok == 15) break;
                    p[mark++] = grammar_lines[k++];
                    p[mark++] = grammar_lines[k++];
                }
            }
        }
    }

    /*  ------------------- Actions and Preactions ------------------------- */
    /*  (The term "preactions" is traditional: Inform uses the preactions    */
    /*  table for a different purpose than Infocom used to.)                 */
    /*  The values are written later, when the Z-code offset is known.       */
    /*  -------------------------------------------------------------------- */

    actions_at = mark;
    mark += no_actions*2;

    preactions_at = mark;
    if (grammar_version_number == 1)
        mark += no_grammar_token_routines*2;

    /*  ----------------------- Adjectives Table --------------------------- */

    if (grammar_version_number == 1)
    {   p[mark]=0; p[mark+1]=no_adjectives; mark+=2; /* To assist "infodump" */
        adjectives_offset = mark;
        dictionary_offset = mark + 4*no_adjectives;

        for (i=0; i<no_adjectives; i++)
        {   j = final_dict_order[adjectives[no_adjectives-i-1]]
                *((version_number==3)?7:9)
                + dictionary_offset + 7;
            p[mark++]=j/256; p[mark++]=j%256; p[mark++]=0;
            p[mark++]=(256-no_adjectives+i);
        }
    }
    else
    {   p[mark]=0; p[mark+1]=0; mark+=2;
        adjectives_offset = mark;
        dictionary_offset = mark;
    }

    /*  ------------------------- Dictionary ------------------------------- */

    dictionary_at=mark;

    dictionary[0]=3; dictionary[1]='.';        /* Non-space characters which */
                     dictionary[2]=',';                 /* force words apart */
                     dictionary[3]='"';

    dictionary[4]=(version_number==3)?7:9;           /* Length of each entry */
    dictionary[5]=(dict_entries/256);                   /* Number of entries */
    dictionary[6]=(dict_entries%256);

    for (i=0; i<7; i++) p[mark++] = dictionary[i];

    for (i=0; i<dict_entries; i++)
    {   k = 7 + i*((version_number==3)?7:9);
        j = mark + final_dict_order[i]*((version_number==3)?7:9);
        for (l = 0; l<((version_number==3)?7:9); l++)
            p[j++] = dictionary[k++];
    }
    mark += dict_entries * ((version_number==3)?7:9);

    /*  ------------------------- Module Map ------------------------------- */

    if (module_switch)
    {   map_of_module = mark;                             /* Filled in below */
        mark += 30;
    }

    /*  ------------------------ Static Arrays ----------------------------- */

    static_arrays_at = mark;
    for (i=0; i<static_array_area_size; i++)
        p[mark++] = static_array_area[i];
    
    /*  ----------------- A gap before the code area ----------------------- */
    /*  (so that it will start at an exact packed address and so that all    */
    /*  routine packed addresses are >= 256, hence long constants)           */
    /*  -------------------------------------------------------------------- */

    while ((mark%length_scale_factor) != 0) p[mark++]=0;
    while (mark < (scale_factor*0x100)) p[mark++]=0;
    if (oddeven_packing_switch)
        while ((mark%(scale_factor*2)) != 0) p[mark++]=0;

    if (mark > 0x0FFFE)
    {   error("This program has overflowed the maximum readable-memory \
size of the Z-machine format. See the memory map below: the start \
of the area marked \"above readable memory\" must be brought down to $FFFE \
or less.");
        memory_map_switch = TRUE;
        /* Backpatching the grammar tables requires us to trust some of the */
        /* addresses we've written into Z-machine memory, but they may have */
        /* been truncated to 16 bits, so we can't do it.                    */
        skip_backpatching = TRUE;
    }

    /*  -------------------------- Code Area ------------------------------- */
    /*  (From this point on we don't write any more into the "p" buffer.)    */
    /*  -------------------------------------------------------------------- */

    Write_Code_At = mark;
    if (!OMIT_UNUSED_ROUTINES) {
        code_length = zmachine_pc;
    }
    else {
        if (zmachine_pc != df_total_size_before_stripping)
            compiler_error("Code size does not match (zmachine_pc and df_total_size).");
        code_length = df_total_size_after_stripping;
    }
    mark += code_length;

    /*  ------------------ Another synchronising gap ----------------------- */

    if (oddeven_packing_switch)
    {   if (module_switch)
             while ((mark%(scale_factor*2)) != 0) mark++;
        else
             while ((mark%(scale_factor*2)) != scale_factor) mark++;
    }
    else
        while ((mark%scale_factor) != 0) mark++;

    /*  ------------------------- Strings Area ----------------------------- */

    Write_Strings_At = mark;
    strings_length = static_strings_extent;
    mark += strings_length;

    /*  --------------------- Module Linking Data -------------------------- */

    if (module_switch)
    {   link_table_at = mark; mark += link_data_size;
        mark += zcode_backpatch_size;
        mark += zmachine_backpatch_size;
    }

    /*  --------------------- Is the file too big? ------------------------- */

    Out_Size = mark;

    switch(version_number)
    {   case 3: excess = Out_Size-((int32) 0x20000L); limit = 128; break;
        case 4:
        case 5: excess = Out_Size-((int32) 0x40000L); limit = 256; break;
        case 6:
        case 7:
        case 8: excess = Out_Size-((int32) 0x80000L); limit = 512; break;
    }

    if (module_switch)
    {   excess = Out_Size-((int32) 0x10000L); limit=64;
    }

    if (excess > 0)
    {   char memory_full_error[80];
        sprintf(memory_full_error,
            "The %s exceeds version-%d limit (%dK) by %d bytes",
             output_called, version_number, limit, excess);
        fatalerror(memory_full_error);
    }

    /*  --------------------------- Offsets -------------------------------- */

    dictionary_offset = dictionary_at;
    variables_offset = globals_at;
    actions_offset = actions_at;
    preactions_offset = preactions_at;
    prop_defaults_offset = prop_defaults_at;
    prop_values_offset = object_props_at;
    static_memory_offset = grammar_table_at;
    grammar_table_offset = grammar_table_at;
    static_arrays_offset = static_arrays_at;

    if (extend_memory_map)
    {   extend_offset=256;
        if (no_objects+9 > extend_offset) extend_offset=no_objects+9;
        while ((extend_offset%length_scale_factor) != 0) extend_offset++;
        /* Not sure why above line is necessary, but oddeven_packing
         * will need extend_offset to be even */
        code_offset = extend_offset*scale_factor;
        if (oddeven_packing_switch)
            strings_offset = code_offset + scale_factor;
        else
            strings_offset = code_offset + (Write_Strings_At-Write_Code_At);

        /* With the extended memory model, need to specifically check that we
         * haven't overflowed the packed address range for routines or strings.
         * With the standard memory model, we only need the earlier total size
         * check.
         */
        excess = code_length + code_offset - (scale_factor*((int32) 0x10000L));
        if (excess > 0)
        {   char code_full_error[80];
            sprintf(code_full_error,
                "The code area limit has been exceeded by %d bytes",
                 excess);
            fatalerror(code_full_error);
        }

        excess = strings_length + strings_offset - (scale_factor*((int32) 0x10000L));
        if (excess > 0)
        {   char strings_full_error[140];
            if (oddeven_packing_switch)
                sprintf(strings_full_error,
                    "The strings area limit has been exceeded by %d bytes",
                     excess);
            else
                sprintf(strings_full_error,
                    "The code+strings area limit has been exceeded by %d bytes. \
 Try running Inform again with -B on the command line.",
                     excess);
            fatalerror(strings_full_error);
        }
    }
    else
    {   code_offset = Write_Code_At;
        strings_offset = Write_Strings_At;
    }

    /*  --------------------------- The Header ----------------------------- */

    for (i=0; i<=0x3f; i++) p[i]=0;             /* Begin with 64 blank bytes */

    p[0] = version_number;                                 /* Version number */
    p[1] = statusline_flag*2;          /* Bit 1 of Flags 1: statusline style */
    p[2] = (release_number/256);
    p[3] = (release_number%256);                                  /* Release */
    p[4] = (Write_Code_At/256);
    p[5] = (Write_Code_At%256);                       /* End of paged memory */
    if (version_number==6)
    {   j=code_offset/scale_factor;            /* Packed address of "Main__" */
        p[6]=(j/256); p[7]=(j%256);
    }
    else
    {   j=Write_Code_At+1;                       /* Initial PC value (bytes) */
        p[6]=(j/256); p[7]=(j%256);            /* (first opcode in "Main__") */
    }
    p[8] = (dictionary_at/256); p[9]=(dictionary_at%256);      /* Dictionary */
    p[10]=prop_defaults_at/256; p[11]=prop_defaults_at%256;       /* Objects */
    p[12]=(globals_at/256); p[13]=(globals_at%256);          /* Dynamic area */
    p[14]=(grammar_table_at/256);
    p[15]=(grammar_table_at%256);                                 /* Grammar */
    for (i=0, j=0, k=1;i<16;i++, k=k*2)         /* Flags 2 as needed for any */
        j+=k*flags2_requirements[i];            /* unusual opcodes assembled */
    p[16]=j/256; p[17]=j%256;
    write_serial_number((char *) (p+18)); /* Serial number: 6 chars of ASCII */
    p[24]=abbrevs_at/256;
    p[25]=abbrevs_at%256;                             /* Abbreviations table */
    p[26]=0; p[27]=0;            /* Length of file to be filled in "files.c" */
    p[28]=0; p[29]=0;                  /* Checksum to be filled in "files.c" */

    if (extend_memory_map)
    {   j=(Write_Code_At - extend_offset*scale_factor)/length_scale_factor;
        p[40]=j/256; p[41]=j%256;                         /* Routines offset */
        if (oddeven_packing_switch)
            j=(Write_Strings_At - extend_offset*scale_factor)/length_scale_factor;
        p[42]=j/256; p[43]=j%256;                        /* = Strings offset */
    }

    if (version_number >= 5)
    {   p[46] = terminating_chars_at/256;    /* Terminating characters table */
        p[47] = terminating_chars_at%256;
    }

    if (alphabet_modified)
    {   j = charset_at;
        p[52]=j/256; p[53]=j%256; }           /* Character set table address */

    j = headerext_at;
    p[54] = j/256; p[55] = j%256;          /* Header extension table address */

    p[60] = '0' + ((RELEASE_NUMBER/100)%10);
    p[61] = '.';
    p[62] = '0' + ((RELEASE_NUMBER/10)%10);
    p[63] = '0' + RELEASE_NUMBER%10;

    /*  ------------------------ Header Extension -------------------------- */

    /* The numbering in the spec is a little weird -- it's headerext_length
       words *after* the initial length word. We follow the spec numbering
       in this switch statement, so the count is 1-based. */
    for (i=1; i<=headerext_length; i++) {
        switch (i) {
        case 3:
            j = unicode_at;             /* Unicode translation table address */
            break;
        case 4:
            j = ZCODE_HEADER_FLAGS_3;                        /* Flags 3 word */
            break;
        default:
            j = 0;
            break;
        }
        p[headerext_at+2*i+0] = j / 256;
        p[headerext_at+2*i+1] = j % 256;
    }

    /*  ----------------- The Header: Extras for modules ------------------- */

    if (module_switch)
    {   p[0]=p[0]+64;
        p[1]=MODULE_VERSION_NUMBER;
        p[6]=map_of_module/256;
        p[7]=map_of_module%256;

        mark = map_of_module;                       /*  Module map format:   */

        p[mark++]=object_tree_at/256;               /*  0: Object tree addr  */
        p[mark++]=object_tree_at%256;
        p[mark++]=object_props_at/256;              /*  2: Prop values addr  */
        p[mark++]=object_props_at%256;
        p[mark++]=(Write_Strings_At/scale_factor)/256;  /*  4: Static strs   */
        p[mark++]=(Write_Strings_At/scale_factor)%256;
        p[mark++]=class_numbers_offset/256;         /*  6: Class nos addr    */
        p[mark++]=class_numbers_offset%256;
        p[mark++]=individuals_offset/256;           /*  8: Indiv prop values */
        p[mark++]=individuals_offset%256;
        p[mark++]=individuals_length/256;           /*  10: Length of table  */
        p[mark++]=individuals_length%256;
        p[mark++]=no_symbols/256;                   /*  12: No of symbols    */
        p[mark++]=no_symbols%256;
        p[mark++]=no_individual_properties/256;     /*  14: Max property no  */
        p[mark++]=no_individual_properties%256;
        p[mark++]=no_objects/256;                   /*  16: No of objects    */
        p[mark++]=no_objects%256;
        i = link_table_at;
        p[mark++]=i/256;                            /*  18: Import/exports   */
        p[mark++]=i%256;
        p[mark++]=link_data_size/256;               /*  20: Size of          */
        p[mark++]=link_data_size%256;
        i += link_data_size;
        p[mark++]=i/256;                            /*  22: Code backpatch   */
        p[mark++]=i%256;
        p[mark++]=zcode_backpatch_size/256;         /*  24: Size of          */
        p[mark++]=zcode_backpatch_size%256;
        i += zcode_backpatch_size;
        p[mark++]=i/256;                            /*  26: Image backpatch  */
        p[mark++]=i%256;
        p[mark++]=zmachine_backpatch_size/256;      /*  28: Size of          */
        p[mark++]=zmachine_backpatch_size%256;

        /*  Further space in this table is reserved for future use  */
    }

    /*  ---- Backpatch the Z-machine, now that all information is in ------- */

    if (!module_switch && !skip_backpatching)
    {   backpatch_zmachine_image_z();
        for (i=1; i<id_names_length; i++)
        {   int32 v = 256*p[identifier_names_offset + i*2]
                      + p[identifier_names_offset + i*2 + 1];
            if (v!=0) v += strings_offset/scale_factor;
            p[identifier_names_offset + i*2] = v/256;
            p[identifier_names_offset + i*2 + 1] = v%256;
        }

        mark = actions_at;
        for (i=0; i<no_actions; i++)
        {   j=action_byte_offset[i];
            if (OMIT_UNUSED_ROUTINES)
                j = df_stripped_address_for_address(j);
            j += code_offset/scale_factor;
            p[mark++]=j/256; p[mark++]=j%256;
        }

        if (grammar_version_number == 1)
        {   mark = preactions_at;
            for (i=0; i<no_grammar_token_routines; i++)
            {   j=grammar_token_routine[i];
                if (OMIT_UNUSED_ROUTINES)
                    j = df_stripped_address_for_address(j);
                j += code_offset/scale_factor;
                p[mark++]=j/256; p[mark++]=j%256;
            }
        }
        else
        {   for (l = 0; l<no_Inform_verbs; l++)
            {   k = grammar_table_at + 2*l;
                i = p[k]*256 + p[k+1];
                for (j = p[i++]; j>0; j--)
                {   int topbits; int32 value;
                    i = i + 2;
                    while (p[i] != 15)
                    {   topbits = (p[i]/0x40) & 3;
                        value = p[i+1]*256 + p[i+2];
                        switch(topbits)
                        {   case 1:
                                value = final_dict_order[value]
                                        *((version_number==3)?7:9)
                                        + dictionary_offset + 7;
                                break;
                            case 2:
                                if (OMIT_UNUSED_ROUTINES)
                                    value = df_stripped_address_for_address(value);
                                value += code_offset/scale_factor;
                                break;
                        }
                        p[i+1] = value/256; p[i+2] = value%256;
                        i = i + 3;
                    }
                    i++;
                }
            }
        }
    }

    /*  ---- From here on, it's all reportage: construction is finished ---- */

    if (statistics_switch)
    {   int32 k_long, rate; char *k_str="";
        k_long=(Out_Size/1024);
        if ((Out_Size-1024*k_long) >= 512) { k_long++; k_str=""; }
        else if ((Out_Size-1024*k_long) > 0) { k_str=".5"; }
        if (total_bytes_trans == 0) rate = 0;
        else rate=total_bytes_trans*1000/total_chars_trans;

        {   printf("In:\
%3d source code files            %6d syntactic lines\n\
%6d textual lines              %8ld characters ",
            total_input_files, no_syntax_lines,
            total_source_line_count, (long int) total_chars_read);
            if (character_set_unicode) printf("(UTF-8)\n");
            else if (character_set_setting == 0) printf("(plain ASCII)\n");
            else
            {   printf("(ISO 8859-%d %s)\n", character_set_setting,
                    name_of_iso_set(character_set_setting));
            }

            printf("Allocated:\n\
%6d symbols (maximum %4d)    %8ld bytes of memory\n\
Out:   Version %d \"%s\" %s %d.%c%c%c%c%c%c (%ld%sK long):\n",
                 no_symbols, MAX_SYMBOLS,
                 (long int) malloced_bytes,
                 version_number,
                 version_name(version_number),
                 output_called,
                 release_number, p[18], p[19], p[20], p[21], p[22], p[23],
                 (long int) k_long, k_str);

            printf("\
%6d classes (maximum %3d)        %6d objects (maximum %3d)\n\
%6d global vars (maximum 233)    %6d variable/array space (maximum %d)\n",
                 no_classes, MAX_CLASSES,
                 no_objects, ((version_number==3)?255:(MAX_OBJECTS-1)),
                 no_globals,
                 dynamic_array_area_size, MAX_STATIC_DATA);

            printf(
"%6d verbs (maximum %3d)          %6d dictionary entries (maximum %d)\n\
%6d grammar lines (version %d)    %6d grammar tokens (unlimited)\n\
%6d actions (maximum %3d)        %6d attributes (maximum %2d)\n\
%6d common props (maximum %2d)    %6d individual props (unlimited)\n",
                 no_Inform_verbs, MAX_VERBS,
                 dict_entries, MAX_DICT_ENTRIES,
                 no_grammar_lines, grammar_version_number,
                 no_grammar_tokens,
                 no_actions, MAX_ACTIONS,
                 no_attributes, ((version_number==3)?32:48),
                 no_properties-2, ((version_number==3)?30:62),
                 no_individual_properties - 64);

            if (track_unused_routines)
            {
                uint32 diff = df_total_size_before_stripping - df_total_size_after_stripping;
                printf(
"%6ld bytes of Z-code              %6ld unused bytes %s (%.1f%%)\n",
                 (long int) df_total_size_before_stripping, (long int) diff,
                 (OMIT_UNUSED_ROUTINES ? "stripped out" : "detected"),
                 100 * (float)diff / (float)df_total_size_before_stripping);
            }

            printf(
"%6ld characters used in text      %6ld bytes compressed (rate %d.%3ld)\n\
%6d abbreviations (maximum %d)   %6d routines (unlimited)\n\
%6ld instructions of Z-code       %6d sequence points\n\
%6ld bytes readable memory used (maximum 65536)\n\
%6ld bytes used in Z-machine      %6ld bytes free in Z-machine\n",
                 (long int) total_chars_trans,
                 (long int) total_bytes_trans,
                 (total_chars_trans>total_bytes_trans)?0:1,
                 (long int) rate,
                 no_abbreviations, MAX_ABBREVS,
                 no_routines,
                 (long int) no_instructions, no_sequence_points,
                 (long int) Write_Code_At,
                 (long int) Out_Size,
                 (long int)
                      (((long int) (limit*1024L)) - ((long int) Out_Size)));

        }
    }

    if (offsets_switch)
    {
        {   printf(
"\nOffsets in %s:\n\
%05lx Synonyms     %05lx Defaults     %05lx Objects    %05lx Properties\n\
%05lx Variables    %05lx Parse table  %05lx Actions    %05lx Preactions\n\
%05lx Adjectives   %05lx Dictionary   %05lx Code       %05lx Strings\n",
            output_called,
            (long int) abbrevs_at,
            (long int) prop_defaults_at,
            (long int) object_tree_at,
            (long int) object_props_at,
            (long int) globals_at,
            (long int) grammar_table_at,
            (long int) actions_at,
            (long int) preactions_at,
            (long int) adjectives_offset,
            (long int) dictionary_at,
            (long int) Write_Code_At,
            (long int) Write_Strings_At);
            if (module_switch)
                printf("%05lx Linking data\n",(long int) link_table_at);
        }
    }

    if (debugfile_switch)
    {   begin_writing_debug_sections();
        write_debug_section("abbreviations", 64);
        write_debug_section("abbreviations table", abbrevs_at);
        write_debug_section("header extension", headerext_at);
        if (alphabet_modified)
        {   write_debug_section("alphabets table", charset_at);
        }
        if (zscii_defn_modified)
        {   write_debug_section("Unicode table", unicode_at);
        }
        write_debug_section("property defaults", prop_defaults_at);
        write_debug_section("object tree", object_tree_at);
        write_debug_section("common properties", object_props_at);
        write_debug_section("class numbers", class_numbers_offset);
        write_debug_section("identifier names", identifier_names_offset);
        write_debug_section("individual properties", individuals_offset);
        write_debug_section("global variables", globals_at);
        write_debug_section("array space", globals_at+480);
        write_debug_section("grammar table", grammar_table_at);
        write_debug_section("actions table", actions_at);
        write_debug_section("parsing routines", preactions_at);
        write_debug_section("adjectives table", adjectives_offset);
        write_debug_section("dictionary", dictionary_at);
        write_debug_section("code area", Write_Code_At);
        write_debug_section("strings area", Write_Strings_At);
        end_writing_debug_sections(Out_Size);
    }

    if (memory_map_switch)
    {
        {
printf("Dynamic +---------------------+   00000\n");
printf("memory  |       header        |\n");
printf("        +---------------------+   00040\n");
printf("        |    abbreviations    |\n");
printf("        + - - - - - - - - - - +   %05lx\n", (long int) abbrevs_at);
printf("        | abbreviations table |\n");
printf("        +---------------------+   %05lx\n", (long int) headerext_at);
printf("        |  header extension   |\n");
            if (alphabet_modified)
            {
printf("        + - - - - - - - - - - +   %05lx\n", (long int) charset_at);
printf("        |   alphabets table   |\n");
            }
            if (zscii_defn_modified)
            {
printf("        + - - - - - - - - - - +   %05lx\n", (long int) unicode_at);
printf("        |    Unicode table    |\n");
            }
printf("        +---------------------+   %05lx\n",
                                          (long int) prop_defaults_at);
printf("        |  property defaults  |\n");
printf("        + - - - - - - - - - - +   %05lx\n", (long int) object_tree_at);
printf("        |       objects       |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) object_props_at);
printf("        | object short names, |\n");
printf("        | common prop values  |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) class_numbers_offset);
printf("        | class numbers table |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) identifier_names_offset);
printf("        | symbol names table  |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) individuals_offset);
printf("        | indiv prop values   |\n");
printf("        +---------------------+   %05lx\n", (long int) globals_at);
printf("        |  global variables   |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          ((long int) globals_at)+480L);
printf("        |       arrays        |\n");
printf("        +=====================+   %05lx\n",
                                          (long int) grammar_table_at);
printf("Readable|    grammar table    |\n");
printf("memory  + - - - - - - - - - - +   %05lx\n", (long int) actions_at);
printf("        |       actions       |\n");
printf("        + - - - - - - - - - - +   %05lx\n", (long int) preactions_at);
printf("        |   parsing routines  |\n");
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) adjectives_offset);
printf("        |     adjectives      |\n");
printf("        +---------------------+   %05lx\n", (long int) dictionary_at);
printf("        |     dictionary      |\n");
if (module_switch)
{
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) map_of_module);
printf("        | map of module addrs |\n");
}
if (static_array_area_size)
{
printf("        +---------------------+   %05lx\n", (long int) static_arrays_at);
printf("        |    static arrays    |\n");
}
printf("        +=====================+   %05lx\n", (long int) Write_Code_At);
printf("Above   |       Z-code        |\n");
printf("readable+---------------------+   %05lx\n",
                                          (long int) Write_Strings_At);
printf("memory  |       strings       |\n");
if (module_switch)
{
printf("        +=====================+   %05lx\n", (long int) link_table_at);
printf("        | module linking data |\n");
}
printf("        +---------------------+   %05lx\n", (long int) Out_Size);
        }
    }
    if (percentages_switch)
    {   printf("Approximate percentage breakdown of %s:\n",
                output_called);
        percentage("Z-code",             code_length,Out_Size);
        if (module_switch)
            percentage("Linking data",   link_data_size,Out_Size);
        percentage("Static strings",     strings_length,Out_Size);
        percentage("Dictionary",         Write_Code_At-dictionary_at,Out_Size);
        percentage("Objects",            globals_at-prop_defaults_at,Out_Size);
        percentage("Globals",            grammar_table_at-globals_at,Out_Size);
        percentage("Parsing tables",   dictionary_at-grammar_table_at,Out_Size);
        percentage("Header and synonyms", prop_defaults_at,Out_Size);
        percentage("Total of save area", grammar_table_at,Out_Size);
        percentage("Total of text",      total_bytes_trans,Out_Size);
    }
    if (frequencies_switch)
    {
        {   printf("How frequently abbreviations were used, and roughly\n");
            printf("how many bytes they saved:  ('_' denotes spaces)\n");
            for (i=0; i<no_abbreviations; i++)
            {   char abbrev_string[MAX_ABBREV_LENGTH];
                strcpy(abbrev_string,
                    (char *)abbreviations_at+i*MAX_ABBREV_LENGTH);
                for (j=0; abbrev_string[j]!=0; j++)
                    if (abbrev_string[j]==' ') abbrev_string[j]='_';
                printf("%10s %5d/%5d   ",abbrev_string,abbrev_freqs[i],
                    2*((abbrev_freqs[i]-1)*abbrev_quality[i])/3);
                if ((i%3)==2) printf("\n");
            }
            if ((i%3)!=0) printf("\n");
            if (no_abbreviations==0) printf("None were declared.\n");
        }
    }
}

static void construct_storyfile_g(void)
{   uchar *p;
    int32 i, j, k, l, mark, strings_length, limit;
    int32 globals_at, dictionary_at, actions_at, preactions_at,
          abbrevs_at, prop_defaults_at, object_tree_at, object_props_at,
          grammar_table_at, charset_at, headerext_at,
        unicode_at, arrays_at, static_arrays_at;
    int32 threespaces, code_length;
    char *output_called = (module_switch)?"module":"story file";

    ASSERT_GLULX();

    individual_name_strings =
        my_calloc(sizeof(int32), no_individual_properties,
            "identifier name strings");
    action_name_strings =
        my_calloc(sizeof(int32), no_actions + no_fake_actions,
            "action name strings");
    attribute_name_strings =
        my_calloc(sizeof(int32), NUM_ATTR_BYTES*8,
            "attribute name strings");
    array_name_strings =
        my_calloc(sizeof(int32), 
            no_symbols,
            "array name strings");

    write_the_identifier_names();
    threespaces = compile_string("   ", FALSE, FALSE);

    compress_game_text();

    /*  We now know how large the buffer to hold our construction has to be  */

    zmachine_paged_memory = my_malloc(rough_size_of_paged_memory_g(),
        "output buffer");

    /*  Foolish code to make this routine compile on all ANSI compilers      */

    p = (uchar *) zmachine_paged_memory;

    /*  In what follows, the "mark" will move upwards in memory: at various
        points its value will be recorded for milestones like
        "dictionary table start".  It begins at 0x40, just after the header  */

    /* Ok, our policy here will be to set the *_at values all relative
       to RAM. That's so we can write into zmachine_paged_memory[mark] 
       and actually hit what we're aiming at.
       All the *_offset values will be set to true Glulx machine
       addresses. */

    /* To get our bearings, figure out where the strings and code are. */
    /* We start with two words, which conventionally identify the 
       memory layout. This is why the code starts eight bytes after
       the header. */
    Write_Code_At = GLULX_HEADER_SIZE + GLULX_STATIC_ROM_SIZE;
    if (!OMIT_UNUSED_ROUTINES) {
        code_length = zmachine_pc;
    }
    else {
        if (zmachine_pc != df_total_size_before_stripping)
            compiler_error("Code size does not match (zmachine_pc and df_total_size).");
        code_length = df_total_size_after_stripping;
    }
    Write_Strings_At = Write_Code_At + code_length;
    strings_length = compression_table_size + compression_string_size;

    static_arrays_at = Write_Strings_At + strings_length;

    /* Now figure out where RAM starts. */
    Write_RAM_At = static_arrays_at + static_array_area_size;
    /* The Write_RAM_At boundary must be a multiple of GPAGESIZE. */
    while (Write_RAM_At % GPAGESIZE)
      Write_RAM_At++;

    /* Now work out all those RAM positions. */
    mark = 0;

    /*  ----------------- Variables and Dynamic Arrays --------------------- */

    globals_at = mark;
    for (i=0; i<no_globals; i++) {
      j = global_initial_value[i];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    arrays_at = mark;
    for (i=MAX_GLOBAL_VARIABLES*4; i<dynamic_array_area_size; i++)
        p[mark++] = dynamic_array_area[i];

    /* -------------------------- Dynamic Strings -------------------------- */

    abbrevs_at = mark;
    WriteInt32(p+mark, no_dynamic_strings);
    mark += 4;
    for (i=0; i<no_dynamic_strings; i++) {
      j = Write_Strings_At + compressed_offsets[threespaces-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    /* ---------------- Various Things I'm Not Sure About ------------------ */
    /* Actually, none of these are relevant to Glulx. */
    headerext_at = mark;
    charset_at = 0;
    if (alphabet_modified)
      charset_at = mark;
    unicode_at = 0;
    if (zscii_defn_modified)
      unicode_at = mark;

    /*  -------------------- Objects and Properties ------------------------ */

    object_tree_at = mark;

    object_props_at = mark + no_objects*OBJECT_BYTE_LENGTH;

    for (i=0; i<no_objects; i++) {
      int32 objmark = mark;
      p[mark++] = 0x70; /* type byte -- object */
      for (j=0; j<NUM_ATTR_BYTES; j++) {
        p[mark++] = objectatts[i*NUM_ATTR_BYTES+j];
      }
      for (j=0; j<6; j++) {
        int32 val = 0;
        switch (j) {
        case 0: /* next object in the linked list. */
          if (i == no_objects-1)
            val = 0;
          else
            val = Write_RAM_At + objmark + OBJECT_BYTE_LENGTH;
          break;
        case 1: /* hardware name address */
          val = Write_Strings_At + compressed_offsets[objectsg[i].shortname-1];
          break;
        case 2: /* property table address */
          val = Write_RAM_At + object_props_at + objectsg[i].propaddr;
          break;
        case 3: /* parent */
          if (objectsg[i].parent == 0)
            val = 0;
          else
            val = Write_RAM_At + object_tree_at +
              (OBJECT_BYTE_LENGTH*(objectsg[i].parent-1));
          break;
        case 4: /* sibling */
          if (objectsg[i].next == 0)
            val = 0;
          else
            val = Write_RAM_At + object_tree_at +
              (OBJECT_BYTE_LENGTH*(objectsg[i].next-1));
          break;
        case 5: /* child */
          if (objectsg[i].child == 0)
            val = 0;
          else
            val = Write_RAM_At + object_tree_at +
              (OBJECT_BYTE_LENGTH*(objectsg[i].child-1));
          break;
        }
        p[mark++] = (val >> 24) & 0xFF;
        p[mark++] = (val >> 16) & 0xFF;
        p[mark++] = (val >> 8) & 0xFF;
        p[mark++] = (val) & 0xFF;
      }

      for (j=0; j<GLULX_OBJECT_EXT_BYTES; j++) {
        p[mark++] = 0;
      }
    }

    if (object_props_at != mark)
      error("*** Object table was impossible length ***");

    for (i=0; i<properties_table_size; i++)
      p[mark+i]=properties_table[i];

    for (i=0; i<no_objects; i++) { 
      int32 tableaddr = object_props_at + objectsg[i].propaddr;
      int32 tablelen = ReadInt32(p+tableaddr);
      tableaddr += 4;
      for (j=0; j<tablelen; j++) {
        k = ReadInt32(p+tableaddr+4);
        k += (Write_RAM_At + object_props_at);
        WriteInt32(p+tableaddr+4, k);
        tableaddr += 10;
      }
    }

    mark += properties_table_size;

    prop_defaults_at = mark;
    for (i=0; i<no_properties; i++) {
      k = prop_default_value[i];
      WriteInt32(p+mark, k);
      mark += 4;
    }

    /*  ----------- Table of Class Prototype Object Numbers ---------------- */
    
    class_numbers_offset = mark;
    for (i=0; i<no_classes; i++) {
      j = Write_RAM_At + object_tree_at +
        (OBJECT_BYTE_LENGTH*(class_object_numbers[i]-1));
      WriteInt32(p+mark, j);
      mark += 4;
    }
    WriteInt32(p+mark, 0);
    mark += 4;

    /* -------------------- Table of Property Names ------------------------ */

    /* We try to format this bit with some regularity...
       address of common properties
       number of common properties
       address of indiv properties
       number of indiv properties (counted from INDIV_PROP_START)
       address of attributes
       number of attributes (always NUM_ATTR_BYTES*8)
       address of actions
       number of actions
    */

    identifier_names_offset = mark;
    mark += 32; /* eight pairs of values, to be filled in. */

    WriteInt32(p+identifier_names_offset+0, Write_RAM_At + mark);
    WriteInt32(p+identifier_names_offset+4, no_properties);
    for (i=0; i<no_properties; i++) {
      j = individual_name_strings[i];
      if (j)
        j = Write_Strings_At + compressed_offsets[j-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    WriteInt32(p+identifier_names_offset+8, Write_RAM_At + mark);
    WriteInt32(p+identifier_names_offset+12, 
      no_individual_properties-INDIV_PROP_START);
    for (i=INDIV_PROP_START; i<no_individual_properties; i++) {
      j = individual_name_strings[i];
      if (j)
        j = Write_Strings_At + compressed_offsets[j-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    WriteInt32(p+identifier_names_offset+16, Write_RAM_At + mark);
    WriteInt32(p+identifier_names_offset+20, NUM_ATTR_BYTES*8);
    for (i=0; i<NUM_ATTR_BYTES*8; i++) {
      j = attribute_name_strings[i];
      if (j)
        j = Write_Strings_At + compressed_offsets[j-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    WriteInt32(p+identifier_names_offset+24, Write_RAM_At + mark);
    WriteInt32(p+identifier_names_offset+28, no_actions + no_fake_actions);
    action_names_offset = mark;
    fake_action_names_offset = mark + 4*no_actions;
    for (i=0; i<no_actions + no_fake_actions; i++) {
      j = action_name_strings[i];
      if (j)
        j = Write_Strings_At + compressed_offsets[j-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }

    array_names_offset = mark;
    WriteInt32(p+mark, no_arrays);
    mark += 4;
    for (i=0; i<no_arrays; i++) {
      j = array_name_strings[i];
      if (j)
        j = Write_Strings_At + compressed_offsets[j-1];
      WriteInt32(p+mark, j);
      mark += 4;
    }    

    individuals_offset = mark;

    /*  ------------------------ Grammar Table ----------------------------- */

    if (grammar_version_number != 2)
    {   warning("This version of Inform is unable to produce the grammar \
table format requested (producing number 2 format instead)");
        grammar_version_number = 2;
    }

    grammar_table_at = mark;

    WriteInt32(p+mark, no_Inform_verbs);
    mark += 4;

    mark += no_Inform_verbs*4;

    for (i=0; i<no_Inform_verbs; i++) {
      j = mark + Write_RAM_At;
      WriteInt32(p+(grammar_table_at+4+i*4), j);
      p[mark++] = Inform_verbs[i].lines;
      for (j=0; j<Inform_verbs[i].lines; j++) {
        int tok;
        k = Inform_verbs[i].l[j];
        p[mark++] = grammar_lines[k++];
        p[mark++] = grammar_lines[k++];
        p[mark++] = grammar_lines[k++];
        for (;;) {
          tok = grammar_lines[k++];
          p[mark++] = tok;
          if (tok == 15) break;
          p[mark++] = grammar_lines[k++];
          p[mark++] = grammar_lines[k++];
          p[mark++] = grammar_lines[k++];
          p[mark++] = grammar_lines[k++];
        }
      }
    }

    /*  ------------------- Actions and Preactions ------------------------- */

    actions_at = mark;
    WriteInt32(p+mark, no_actions);
    mark += 4;
    mark += no_actions*4;
    /* Values to be written in later. */

    if (DICT_CHAR_SIZE != 1) {
      /* If the dictionary is Unicode, we'd like it to be word-aligned. */
      while (mark % 4)
        p[mark++]=0;
    }

    preactions_at = mark;
    adjectives_offset = mark;
    dictionary_offset = mark;

    /*  ------------------------- Dictionary ------------------------------- */

    dictionary_at = mark;

    WriteInt32(dictionary+0, dict_entries);
    for (i=0; i<4; i++) 
      p[mark+i] = dictionary[i];

    for (i=0; i<dict_entries; i++) {
      k = 4 + i*DICT_ENTRY_BYTE_LENGTH;
      j = mark + 4 + final_dict_order[i]*DICT_ENTRY_BYTE_LENGTH;
      for (l=0; l<DICT_ENTRY_BYTE_LENGTH; l++)
        p[j++] = dictionary[k++];
    }
    mark += 4 + dict_entries * DICT_ENTRY_BYTE_LENGTH;

    /*  -------------------------- All Data -------------------------------- */
    
    /* The end-of-RAM boundary must be a multiple of GPAGESIZE. */
    while (mark % GPAGESIZE)
      p[mark++]=0;

    RAM_Size = mark;

    Out_Size = Write_RAM_At + RAM_Size;
    limit=1024*1024;

    /*  --------------------------- Offsets -------------------------------- */

    dictionary_offset = Write_RAM_At + dictionary_at;
    variables_offset = Write_RAM_At + globals_at;
    arrays_offset = Write_RAM_At + arrays_at;
    actions_offset = Write_RAM_At + actions_at;
    preactions_offset = Write_RAM_At + preactions_at;
    prop_defaults_offset = Write_RAM_At + prop_defaults_at;
    object_tree_offset = Write_RAM_At + object_tree_at;
    prop_values_offset = Write_RAM_At + object_props_at;
    static_memory_offset = Write_RAM_At + grammar_table_at;
    grammar_table_offset = Write_RAM_At + grammar_table_at;
    abbreviations_offset = Write_RAM_At + abbrevs_at;

    code_offset = Write_Code_At;
    strings_offset = Write_Strings_At;
    static_arrays_offset = static_arrays_at;

    /*  --------------------------- The Header ----------------------------- */

    /*  ------ Backpatch the machine, now that all information is in ------- */

    if (!module_switch)
    {   backpatch_zmachine_image_g();

        mark = actions_at + 4;
        for (i=0; i<no_actions; i++) {
          j = action_byte_offset[i];
          if (OMIT_UNUSED_ROUTINES)
            j = df_stripped_address_for_address(j);
          j += code_offset;
          WriteInt32(p+mark, j);
          mark += 4;
        }

        for (l = 0; l<no_Inform_verbs; l++) {
          k = grammar_table_at + 4 + 4*l; 
          i = ((p[k] << 24) | (p[k+1] << 16) | (p[k+2] << 8) | (p[k+3]));
          i -= Write_RAM_At;
          for (j = p[i++]; j>0; j--) {
            int topbits; 
            int32 value;
            i = i + 3;
            while (p[i] != 15) {
              topbits = (p[i]/0x40) & 3;
              value = ((p[i+1] << 24) | (p[i+2] << 16) 
                | (p[i+3] << 8) | (p[i+4]));
              switch(topbits) {
              case 1:
                value = dictionary_offset + 4
                  + final_dict_order[value]*DICT_ENTRY_BYTE_LENGTH;
                break;
              case 2:
                if (OMIT_UNUSED_ROUTINES)
                  value = df_stripped_address_for_address(value);
                value += code_offset;
                break;
              }
              WriteInt32(p+(i+1), value);
              i = i + 5;
            }
            i++;
          }
        }

    }

    /*  ---- From here on, it's all reportage: construction is finished ---- */

    if (statistics_switch)
    {   int32 k_long, rate; char *k_str="";
        k_long=(Out_Size/1024);
        if ((Out_Size-1024*k_long) >= 512) { k_long++; k_str=""; }
        else if ((Out_Size-1024*k_long) > 0) { k_str=".5"; }
        if (strings_length == 0) rate = 0;
        else rate=strings_length*1000/total_chars_trans;

        {   printf("In:\
%3d source code files            %6d syntactic lines\n\
%6d textual lines              %8ld characters ",
            total_input_files, no_syntax_lines,
            total_source_line_count, (long int) total_chars_read);
            if (character_set_unicode) printf("(UTF-8)\n");
            else if (character_set_setting == 0) printf("(plain ASCII)\n");
            else
            {   printf("(ISO 8859-%d %s)\n", character_set_setting,
                    name_of_iso_set(character_set_setting));
            }

            {char serialnum[8];
            write_serial_number(serialnum);
            printf("Allocated:\n\
%6d symbols (maximum %4d)    %8ld bytes of memory\n\
Out:   %s %s %d.%c%c%c%c%c%c (%ld%sK long):\n",
                 no_symbols, MAX_SYMBOLS,
                 (long int) malloced_bytes,
                 version_name(version_number),
                 output_called,
                 release_number,
                 serialnum[0], serialnum[1], serialnum[2],
                 serialnum[3], serialnum[4], serialnum[5],
                 (long int) k_long, k_str);
            } 

            printf("\
%6d classes (maximum %3d)        %6d objects (maximum %3d)\n\
%6d global vars (maximum %3d)    %6d variable/array space (maximum %d)\n",
                 no_classes, MAX_CLASSES,
                 no_objects, MAX_OBJECTS,
                 no_globals, MAX_GLOBAL_VARIABLES,
                 dynamic_array_area_size, MAX_STATIC_DATA);

            printf(
"%6d verbs (maximum %3d)          %6d dictionary entries (maximum %d)\n\
%6d grammar lines (version %d)    %6d grammar tokens (unlimited)\n\
%6d actions (maximum %3d)        %6d attributes (maximum %2d)\n\
%6d common props (maximum %3d)   %6d individual props (unlimited)\n",
                 no_Inform_verbs, MAX_VERBS,
                 dict_entries, MAX_DICT_ENTRIES,
                 no_grammar_lines, grammar_version_number,
                 no_grammar_tokens,
                 no_actions, MAX_ACTIONS,
                 no_attributes, NUM_ATTR_BYTES*8,
                 no_properties, INDIV_PROP_START,
                 no_individual_properties - INDIV_PROP_START);

            if (track_unused_routines)
            {
                uint32 diff = df_total_size_before_stripping - df_total_size_after_stripping;
                printf(
"%6ld bytes of code                %6ld unused bytes %s (%.1f%%)\n",
                 (long int) df_total_size_before_stripping, (long int) diff,
                 (OMIT_UNUSED_ROUTINES ? "stripped out" : "detected"),
                 100 * (float)diff / (float)df_total_size_before_stripping);
            }

            printf(
"%6ld characters used in text      %6ld bytes compressed (rate %d.%3ld)\n\
%6d abbreviations (maximum %d)   %6d routines (unlimited)\n\
%6ld instructions of code         %6d sequence points\n\
%6ld bytes writable memory used   %6ld bytes read-only memory used\n\
%6ld bytes used in machine    %10ld bytes free in machine\n",
                 (long int) total_chars_trans,
                 (long int) strings_length,
                 (total_chars_trans>strings_length)?0:1,
                 (long int) rate,
                 no_abbreviations, MAX_ABBREVS,
                 no_routines,
                 (long int) no_instructions, no_sequence_points,
                 (long int) (Out_Size - Write_RAM_At),
                 (long int) Write_RAM_At,
                 (long int) Out_Size,
                 (long int)
                      (((long int) (limit*1024L)) - ((long int) Out_Size)));

        }
    }

    if (offsets_switch)
    {
        {   printf(
"\nOffsets in %s:\n\
%05lx Synonyms     %05lx Defaults     %05lx Objects    %05lx Properties\n\
%05lx Variables    %05lx Parse table  %05lx Actions    %05lx Preactions\n\
%05lx Adjectives   %05lx Dictionary   %05lx Code       %05lx Strings\n",
            output_called,
            (long int) abbrevs_at,
            (long int) prop_defaults_at,
            (long int) object_tree_at,
            (long int) object_props_at,
            (long int) globals_at,
            (long int) grammar_table_at,
            (long int) actions_at,
            (long int) preactions_at,
            (long int) adjectives_offset,
            (long int) dictionary_at,
            (long int) Write_Code_At,
            (long int) Write_Strings_At);
        }
    }

    if (debugfile_switch)
    {   begin_writing_debug_sections();
        write_debug_section("memory layout id", GLULX_HEADER_SIZE);
        write_debug_section("code area", Write_Code_At);
        write_debug_section("string decoding table", Write_Strings_At);
        write_debug_section("strings area",
                            Write_Strings_At + compression_table_size);
        write_debug_section("static array space", static_arrays_at);
        if (static_arrays_at + static_array_area_size < Write_RAM_At)
        {   write_debug_section
                ("zero padding", static_arrays_at + static_array_area_size);
        }
        if (globals_at)
        {   compiler_error("Failed assumption that globals are at start of "
                           "Glulx RAM");
        }
        write_debug_section("global variables", Write_RAM_At + globals_at);
        write_debug_section("array space", Write_RAM_At + arrays_at);
        write_debug_section("abbreviations table", Write_RAM_At + abbrevs_at);
        write_debug_section("object tree", Write_RAM_At + object_tree_at);
        write_debug_section("common properties",
                            Write_RAM_At + object_props_at);
        write_debug_section("property defaults",
                            Write_RAM_At + prop_defaults_at);
        write_debug_section("class numbers",
                            Write_RAM_At + class_numbers_offset);
        write_debug_section("identifier names",
                            Write_RAM_At + identifier_names_offset);
        write_debug_section("grammar table", Write_RAM_At + grammar_table_at);
        write_debug_section("actions table", Write_RAM_At + actions_at);
        write_debug_section("dictionary", Write_RAM_At + dictionary_at);
        if (MEMORY_MAP_EXTENSION)
        {   write_debug_section("zero padding", Out_Size);
        }
        end_writing_debug_sections(Out_Size + MEMORY_MAP_EXTENSION);
    }

    if (memory_map_switch)
    {

        {
printf("        +---------------------+   000000\n");
printf("Read-   |       header        |\n");
printf(" only   +=====================+   %06lx\n", (long int) GLULX_HEADER_SIZE);
printf("memory  |  memory layout id   |\n");
printf("        +---------------------+   %06lx\n", (long int) Write_Code_At);
printf("        |        code         |\n");
printf("        +---------------------+   %06lx\n",
  (long int) Write_Strings_At);
printf("        | string decode table |\n");
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) Write_Strings_At + compression_table_size);
printf("        |       strings       |\n");
            if (static_array_area_size)
            {
printf("        +---------------------+   %06lx\n", 
  (long int) (static_arrays_at));
printf("        |    static arrays    |\n");
            }
printf("        +=====================+   %06lx\n", 
  (long int) (Write_RAM_At+globals_at));
printf("Dynamic |  global variables   |\n");
printf("memory  + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+arrays_at));
printf("        |       arrays        |\n");
printf("        +---------------------+   %06lx\n",
  (long int) (Write_RAM_At+abbrevs_at));
printf("        | printing variables  |\n");
            if (alphabet_modified)
            {
printf("        + - - - - - - - - - - +   %06lx\n", 
  (long int) (Write_RAM_At+charset_at));
printf("        |   alphabets table   |\n");
            }
            if (zscii_defn_modified)
            {
printf("        + - - - - - - - - - - +   %06lx\n", 
  (long int) (Write_RAM_At+unicode_at));
printf("        |    Unicode table    |\n");
            }
printf("        +---------------------+   %06lx\n", 
  (long int) (Write_RAM_At+object_tree_at));
printf("        |       objects       |\n");
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+object_props_at));
printf("        |   property values   |\n");
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+prop_defaults_at));
printf("        |  property defaults  |\n");
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+class_numbers_offset));
printf("        | class numbers table |\n");
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+identifier_names_offset));
printf("        |   id names table    |\n");
printf("        +---------------------+   %06lx\n",
  (long int) (Write_RAM_At+grammar_table_at));
printf("        |    grammar table    |\n");
printf("        + - - - - - - - - - - +   %06lx\n", 
  (long int) (Write_RAM_At+actions_at));
printf("        |       actions       |\n");
printf("        +---------------------+   %06lx\n", 
  (long int) dictionary_offset);
printf("        |     dictionary      |\n");
            if (MEMORY_MAP_EXTENSION == 0)
            {
printf("        +---------------------+   %06lx\n", (long int) Out_Size);
            }
            else
            {
printf("        +=====================+   %06lx\n", (long int) Out_Size);
printf("Runtime |       (empty)       |\n");
printf("  extn  +---------------------+   %06lx\n", (long int) Out_Size+MEMORY_MAP_EXTENSION);
            }

        }

    }


    if (percentages_switch)
    {   printf("Approximate percentage breakdown of %s:\n",
                output_called);
        percentage("Code",               code_length,Out_Size);
        if (module_switch)
            percentage("Linking data",   link_data_size,Out_Size);
        percentage("Static strings",     strings_length,Out_Size);
        percentage("Dictionary",         Write_Code_At-dictionary_at,Out_Size);
        percentage("Objects",            globals_at-prop_defaults_at,Out_Size);
        percentage("Globals",            grammar_table_at-globals_at,Out_Size);
        percentage("Parsing tables",   dictionary_at-grammar_table_at,Out_Size);
        percentage("Header and synonyms", prop_defaults_at,Out_Size);
        percentage("Total of save area", grammar_table_at,Out_Size);
        percentage("Total of text",      strings_length,Out_Size);
    }
    if (frequencies_switch)
    {
        {   printf("How frequently abbreviations were used, and roughly\n");
            printf("how many bytes they saved:  ('_' denotes spaces)\n");
            for (i=0; i<no_abbreviations; i++)
            {   char abbrev_string[MAX_ABBREV_LENGTH];
                strcpy(abbrev_string,
                    (char *)abbreviations_at+i*MAX_ABBREV_LENGTH);
                for (j=0; abbrev_string[j]!=0; j++)
                    if (abbrev_string[j]==' ') abbrev_string[j]='_';
                printf("%10s %5d/%5d   ",abbrev_string,abbrev_freqs[i],
                    2*((abbrev_freqs[i]-1)*abbrev_quality[i])/3);
                if ((i%3)==2) printf("\n");
            }
            if ((i%3)!=0) printf("\n");
            if (no_abbreviations==0) printf("None were declared.\n");
        }
    }
}

extern void construct_storyfile(void)
{
  if (!glulx_mode)
    construct_storyfile_z();
  else
    construct_storyfile_g();
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_tables_vars(void)
{
    release_number = 1;
    statusline_flag = SCORE_STYLE;

    zmachine_paged_memory = NULL;

    if (!glulx_mode) {
      code_offset = 0x800;
      actions_offset = 0x800;
      preactions_offset = 0x800;
      dictionary_offset = 0x800;
      adjectives_offset = 0x800;
      variables_offset = 0;
      strings_offset = 0xc00;
      individuals_offset=0x800;
      identifier_names_offset=0x800;
      class_numbers_offset = 0x800;
      arrays_offset = 0x0800; /* only used in Glulx, but might as well set */
      static_arrays_offset = 0x0800;
    }
    else {
      code_offset = 0x12345;
      actions_offset = 0x12345;
      preactions_offset = 0x12345;
      dictionary_offset = 0x12345;
      adjectives_offset = 0x12345;
      variables_offset = 0x12345;
      arrays_offset = 0x12345;
      strings_offset = 0x12345;
      individuals_offset=0x12345;
      identifier_names_offset=0x12345;
      class_numbers_offset = 0x12345;
      static_arrays_offset = 0x12345;
    }
}

extern void tables_begin_pass(void)
{
}

extern void tables_allocate_arrays(void)
{
}

extern void tables_free_arrays(void)
{
    /*  Allocation for this array happens in construct_storyfile() above     */

    my_free(&zmachine_paged_memory,"output buffer");
}

/* ========================================================================= */
