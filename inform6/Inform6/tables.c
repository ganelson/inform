/* ------------------------------------------------------------------------- */
/*   "tables" :  Constructs the story file (the output) up to the end        */
/*               of dynamic memory, gluing together all the required         */
/*               tables.                                                     */
/*                                                                           */
/*   Part of Inform 6.43                                                     */
/*   copyright (c) Graham Nelson 1993 - 2025                                 */
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

int zcode_compact_globals_adjustment; 

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
/*   Construct story file (up to code area start).                           */
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
    if (serial_code_given_in_program) {
        strcpy(buffer, serial_code_buffer);
    }
    else {
#ifdef TIME_UNAVAILABLE
        sprintf(buffer,"970000");
#else
        /* Write a six-digit date, null-terminated. Fall back to "970000"
           if that fails. */
        int len = strftime(buffer,7,"%y%m%d",localtime(&tt));
        if (len != 6)
            sprintf(buffer,"970000");
#endif
    }
}

static char percentage_buffer[64];

static char *show_percentage(int32 x, int32 total)
{
    if (memory_map_setting < 2) {
        percentage_buffer[0] = '\0';
    }
    else if (x == 0) {
        sprintf(percentage_buffer, "  ( --- )");
    }
    else if (memory_map_setting < 3) {
        sprintf(percentage_buffer, "  (%.1f %%)", (float)x * 100.0 / (float)total);
    }
    else {
        sprintf(percentage_buffer, "  (%.1f %%, %d bytes)", (float)x * 100.0 / (float)total, x);
    }
    return percentage_buffer;
}

static char *version_name(int v)
{
  if (!glulx_mode) {
    switch(v)
    {   case 3: return "Standard";
        case 4: return "Plus";
        case 5: return "Advanced";
        case 6: return "Graphical";
        case 7: return "Extended Alternate";
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
            + 2 + low_strings_top
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
            + (no_classes+1)*2
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

    total += (dictionary_top)                            /* dictionary size */
             + (0);                                           /* module map */

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

    total += no_globals * 4; /* global variables */
    total += dynamic_array_area_size; /* arrays */

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
    total += dictionary_top;

    while (total % GPAGESIZE)
      total++;

    return(total);
}

static void construct_storyfile_z(void)
{   uchar *p;
    int32 i, j, k, l, mark, objs, strings_length, code_length,
          limit=0, excess=0, extend_offset=0, headerext_length=0;
    int32 globals_at=0, dictionary_at=0, actions_at=0, preactions_at=0,
          abbrevs_at=0, prop_defaults_at=0, object_tree_at=0, object_props_at=0,
          grammar_table_at=0, charset_at=0, headerext_at=0,
          terminating_chars_at=0, unicode_at=0, id_names_length=0,
          arrays_at, static_arrays_at=0;
    int32 rough_size;
    int skip_backpatching = FALSE;
    char *output_called = "story file";

    ASSERT_ZCODE();

    if (!OMIT_SYMBOL_TABLE) {
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
    }

    /*  We now know how large the buffer to hold our construction has to be  */

    rough_size = rough_size_of_paged_memory_z();
    zmachine_paged_memory = my_malloc(rough_size, "output buffer");

    /*  Foolish code to make this routine compile on all ANSI compilers      */

    p = (uchar *) zmachine_paged_memory;

    /*  In what follows, the "mark" will move upwards in memory: at various
        points its value will be recorded for milestones like
        "dictionary table start".  It begins at 0x40, just after the header  */

    for (mark=0; mark<0x40; mark++)
        p[mark] = 0x0;

    /*  ----------------- Low Strings and Abbreviations -------------------- */

    p[mark]=0x80; p[mark+1]=0; mark+=2;        /* Start the low strings pool
                                         with a useful default string, "   " */

    for (i=0; i<low_strings_top; mark++, i++)  /* Low strings pool */
        p[0x42+i]=low_strings[i];

    abbrevs_at = mark;
    
    if (MAX_ABBREVS + MAX_DYNAMIC_STRINGS != 96)
        fatalerror("MAX_ABBREVS + MAX_DYNAMIC_STRINGS is not 96");
    
    /* Initially all 96 entries are set to "   ". (We store half of 0x40,
       the address of the "   " we wrote above.) */
    for (i=0; i<3*32; i++)
    {   p[mark++]=0; p[mark++]=0x20;
    }
    
    /* Entries from 0 to MAX_DYNAMIC_STRINGS (default 32) are "variable 
       strings". Write the abbreviations after these. */
    k = abbrevs_at+2*MAX_DYNAMIC_STRINGS;
    for (i=0; i<no_abbreviations; i++)
    {   j=abbreviations[i].value;
        p[k++]=j/256;
        p[k++]=j%256;
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
       require this, but the RA__Pr() veneer routine does.
    */
    while ((mark%2) != 0) p[mark++]=0;

    prop_defaults_at = mark;

    p[mark++]=0; p[mark++]=0;

    for (i=2; i< ((version_number==3)?32:64); i++)
    {   p[mark++]=commonprops[i].default_value/256;
        p[mark++]=commonprops[i].default_value%256;
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
            p[objs+12]=mark/256;
            p[objs+13]=mark%256;
            objs+=14;
        }
        mark+=objectsz[i].propsize;
    }

    /*  ----------- Table of Class Prototype Object Numbers ---------------- */

    class_numbers_offset = mark;
    for (i=0; i<no_classes; i++)
    {   p[mark++] = class_info[i].object_number/256;
        p[mark++] = class_info[i].object_number%256;
    }
    p[mark++] = 0;
    p[mark++] = 0;

    /*  ------------------- Table of Identifier Names ---------------------- */

    identifier_names_offset = mark;

    if (!OMIT_SYMBOL_TABLE)
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
        {
            int ax = i;
            if (i<no_actions && GRAMMAR_META_FLAG)
                ax = sorted_actions[i].external_to_int;
            j = action_name_strings[ax];
            p[mark++] = j/256;
            p[mark++] = j%256;
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
    else {
        attribute_names_offset = mark;
        action_names_offset = mark;
        fake_action_names_offset = mark;
        array_names_offset = mark;
        global_names_offset = mark;
        routine_names_offset = mark;
        constant_names_offset = mark;
        id_names_length = 0;
    }
    
    routine_flags_array_offset = mark;

    if (define_INFIX_switch)
    {   for (i=0, k=1, l=0; i<no_named_routines; i++)
        {   if (symbols[named_routine_symbols[i]].flags & STAR_SFLAG) l=l+k;
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

    if (ZCODE_COMPACT_GLOBALS) {
        for (i = 0; i < no_globals; i++) {
            j = global_initial_value[i].value;
            p[mark++] = j / 256; p[mark++] = j % 256;
        }

        arrays_at = mark;
        for (i = (MAX_ZCODE_GLOBAL_VARS * WORDSIZE); i < dynamic_array_area_size; i++)
            p[mark++] = dynamic_array_area[i];

        /* When arrays move up we need a adjustment value to use when backkpatching */
        zcode_compact_globals_adjustment = ((MAX_ZCODE_GLOBAL_VARS - no_globals) * WORDSIZE);
    }
    else
    {
        for (i = 0; i < dynamic_array_area_size; i++)
            p[mark++] = dynamic_array_area[i];

        for (i = 0; i < 240; i++)
        {
            j = global_initial_value[i].value;
            p[globals_at + i * 2] = j / 256; p[globals_at + i * 2 + 1] = j % 256;
        }
        arrays_at = globals_at + (MAX_ZCODE_GLOBAL_VARS * WORDSIZE);
        zcode_compact_globals_adjustment = 0;
    }

    /*  ------------------ Terminating Characters Table -------------------- */

    if (version_number >= 5)
    {   terminating_chars_at = mark;
        for (i=0; i<no_termcs; i++) p[mark++] = terminating_characters[i];
        p[mark++] = 0;
    }

    /*  ------------------------ Static Memory ----------------------------- */

    /* Ensure that static memory begins at least 480 bytes after the globals.
       There's normally 240 globals, but with ZCODE_COMPACT_GLOBALS it
       might be less. */

    if (mark < globals_at+480)
        mark = globals_at+480;

    /*  ------------------------ Grammar Table ----------------------------- */

    grammar_table_at = mark;

    mark = mark + no_Inform_verbs*2;

    for (i=0; i<no_Inform_verbs; i++)
    {   p[grammar_table_at + i*2] = (mark/256);
        p[grammar_table_at + i*2 + 1] = (mark%256);
        if (!Inform_verbs[i].used) {
            /* This verb was marked unused at locate_dead_grammar_lines()
               time. Omit the grammar lines. */
            p[mark++] = 0;
            continue;
        }
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
            else if (grammar_version_number == 2)
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
            else if (grammar_version_number == 3)
            {
                int no_tok, l;
                p[mark++] = grammar_lines[k++];
                p[mark++] = grammar_lines[k++];
                no_tok = ((p[mark - 2] & 0xF8) >> 3);
                for (l = 0; l < no_tok; l++)
                {
                    p[mark++] = grammar_lines[k++];
                    p[mark++] = grammar_lines[k++];
                }
            }
            else
            {
                error("invalid grammar version for Z-code");
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
    if (grammar_version_number == 1 || grammar_version_number == 3)
        mark += no_grammar_token_routines*2;

    /*  ----------------------- Adjectives Table --------------------------- */

    if (grammar_version_number == 1)
    {   p[mark]=0; p[mark+1]=no_adjectives; mark+=2; /* To assist "infodump" */
        adjectives_offset = mark;
        dictionary_offset = mark + 4*no_adjectives;

        for (i=0; i<no_adjectives; i++)
        {   j = final_dict_order[adjectives[no_adjectives-i-1]]
                *DICT_ENTRY_BYTE_LENGTH
                + dictionary_offset + 7;
            p[mark++]=j/256; p[mark++]=j%256; p[mark++]=0;
            p[mark++]=(256-no_adjectives+i);
        }
    }
    else if (grammar_version_number == 2)
    {   p[mark]=0; p[mark+1]=0; mark+=2;
        adjectives_offset = mark;
        dictionary_offset = mark;
    }
    else if (grammar_version_number == 3)
    {
        p[mark] = 0; p[mark + 1] = no_adjectives; mark += 2;
        adjectives_offset = mark;       /* adjectives_offset points at start of
                                           data, not at length of table word */
        dictionary_offset = mark + 2 * no_adjectives;
        for (i = 0; i < no_adjectives; i++)
        {
            j = final_dict_order[adjectives[i]]
                * DICT_ENTRY_BYTE_LENGTH
                + dictionary_offset + 7;
            p[mark++] = j / 256; p[mark++] = j % 256;
        }
    }

    /*  ------------------------- Dictionary ------------------------------- */

    dictionary_at=mark;

    dictionary[0]=3; dictionary[1]='.';        /* Non-space characters which */
                     dictionary[2]=',';                 /* force words apart */
                     dictionary[3]='"';

    dictionary[4]=DICT_ENTRY_BYTE_LENGTH;           /* Length of each entry */
    dictionary[5]=(dict_entries/256);                   /* Number of entries */
    dictionary[6]=(dict_entries%256);

    for (i=0; i<7; i++) p[mark++] = dictionary[i];

    for (i=0; i<dict_entries; i++)
    {   k = 7 + i*DICT_ENTRY_BYTE_LENGTH;
        j = mark + final_dict_order[i]*DICT_ENTRY_BYTE_LENGTH;
        for (l = 0; l<DICT_ENTRY_BYTE_LENGTH; l++)
            p[j++] = dictionary[k++];
    }
    mark += dict_entries * DICT_ENTRY_BYTE_LENGTH;

    /*  ------------------------- Module Map ------------------------------- */

    /* (no longer used) */

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
        memory_map_setting = 1;
        /* Backpatching the grammar tables requires us to trust some of the */
        /* addresses we've written into Z-machine memory, but they may have */
        /* been truncated to 16 bits, so we can't do it.                    */
        skip_backpatching = TRUE;
    }

    /*  -------------------------- Code Area ------------------------------- */
    /*  (From this point on we don't write any higher into the "p" buffer.)  */
    /*  -------------------------------------------------------------------- */

    if (mark > rough_size)
        compiler_error("Paged size exceeds rough estimate.");

    Write_Code_At = mark;
    if (!OMIT_UNUSED_ROUTINES) {
        code_length = zmachine_pc;
    }
    else {
        if ((uint32)zmachine_pc != df_total_size_before_stripping)
            compiler_error("Code size does not match (zmachine_pc and df_total_size).");
        code_length = df_total_size_after_stripping;
    }
    mark += code_length;

    /*  ------------------ Another synchronising gap ----------------------- */

    if (oddeven_packing_switch)
    {   
        while ((mark%(scale_factor*2)) != scale_factor) mark++;
    }
    else
        while ((mark%scale_factor) != 0) mark++;

    /*  ------------------------- Strings Area ----------------------------- */

    Write_Strings_At = mark;
    strings_length = static_strings_extent;
    mark += strings_length;

    /*  --------------------- Module Linking Data -------------------------- */

    /* (no longer used) */

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

    if (excess > 0)
    {
        fatalerror_fmt(
            "The %s exceeds version-%d limit (%dK) by %d bytes",
             output_called, version_number, limit, excess);
    }

    /*  --------------------------- Offsets -------------------------------- */

    dictionary_offset = dictionary_at;
    variables_offset = globals_at;
    arrays_offset = arrays_at;
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
        {
            fatalerror_fmt(
                "The code area limit has been exceeded by %d bytes",
                 excess);
        }

        excess = strings_length + strings_offset - (scale_factor*((int32) 0x10000L));
        if (excess > 0)
        {
            if (oddeven_packing_switch)
                fatalerror_fmt(
                    "The strings area limit has been exceeded by %d bytes",
                     excess);
            else
                fatalerror_fmt(
                    "The code+strings area limit has been exceeded by %d bytes. \
 Try running Inform again with -B on the command line.",
                     excess);
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
    p[15]=(grammar_table_at%256);                             /* Static area */
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

    /* (no longer used) */

    /*  ---- Backpatch the Z-machine, now that all information is in ------- */

    if (!skip_backpatching)
    {   backpatch_zmachine_image_z();

        /* The symbol name, action, and grammar tables must be backpatched specially. */
        
        if (!OMIT_SYMBOL_TABLE) {
            for (i=1; i<id_names_length; i++)
            {   int32 v = 256*p[identifier_names_offset + i*2]
                    + p[identifier_names_offset + i*2 + 1];
                if (v!=0) v += strings_offset/scale_factor;
                p[identifier_names_offset + i*2] = v/256;
                p[identifier_names_offset + i*2 + 1] = v%256;
            }
        }

        mark = actions_at;
        for (i=0; i<no_actions; i++)
        {
            int ax = i;
            if (GRAMMAR_META_FLAG)
                ax = sorted_actions[i].external_to_int;
            j=actions[ax].byte_offset;
            if (OMIT_UNUSED_ROUTINES)
                j = df_stripped_address_for_address(j);
            j += code_offset/scale_factor;
            p[mark++]=j/256; p[mark++]=j%256;
        }

        if (grammar_version_number == 1)
        {
            /* backpatch the grammar routine addresses (in preactions) */
            mark = preactions_at;
            for (i=0; i<no_grammar_token_routines; i++)
            {   j=grammar_token_routine[i];
                if (OMIT_UNUSED_ROUTINES)
                    j = df_stripped_address_for_address(j);
                j += code_offset/scale_factor;
                p[mark++]=j/256; p[mark++]=j%256;
            }
            if (GRAMMAR_META_FLAG) {
                /* backpatch the action numbers */
                for (l = 0; l<no_Inform_verbs; l++)
                {
                    int linecount;
                    k = grammar_table_at + 2*l;
                    i = p[k]*256 + p[k+1];
                    linecount = p[i++];
                    for (j=0; j<linecount; j++) {
                        int action = p[i+7];
                        action = sorted_actions[action].internal_to_ext;
                        p[i+7] = action;
                        i += 8;
                    }
                }
            }
        }
        else if (grammar_version_number == 3)
        {
            /* backpatch the grammar routine addresses (in preactions) */
            mark = preactions_at;
            for (i=0; i<no_grammar_token_routines; i++)
            {   j=grammar_token_routine[i];
                if (OMIT_UNUSED_ROUTINES)
                    j = df_stripped_address_for_address(j);
                j += code_offset/scale_factor;
                p[mark++]=j/256; p[mark++]=j%256;
            }
            if (GRAMMAR_META_FLAG) {
                /* backpatch the action numbers */
                for (l = 0; l<no_Inform_verbs; l++)
                {
                    int linecount;
                    k = grammar_table_at + 2*l;
                    i = p[k]*256 + p[k+1];
                    linecount = p[i++];
                    for (j=0; j<linecount; j++)
                    {   int word = p[i]*256 + p[i+1];
                        int action = word & 0x03FF;
                        int flags = word & 0x0400;
                        int tokcount = (word >> 11) & 0x1F;
                        if (action >= 0 && action < no_actions) {
                            action = sorted_actions[action].internal_to_ext;
                            word = flags | action | (tokcount << 11);
                            p[i] = word/256; p[i+1] = word%256;
                        }
                        i = i + 2 + 2*tokcount;
                    }
                }
            }
        }
        else if (grammar_version_number == 2)
        {
            for (l = 0; l<no_Inform_verbs; l++)
            {
                int linecount;
                k = grammar_table_at + 2*l;
                i = p[k]*256 + p[k+1];
                linecount = p[i++];
                for (j=0; j<linecount; j++)
                {   if (GRAMMAR_META_FLAG) {
                        /* backpatch the action number */
                        int word = p[i]*256 + p[i+1];
                        int action = word & 0x03FF;
                        int flags = word & 0xFC00;
                        if (action >= 0 && action < no_actions) {
                            action = sorted_actions[action].internal_to_ext;
                            word = flags | action;
                            p[i] = word/256; p[i+1] = word%256;
                        }
                    }
                    i = i + 2;
                    /* backpatch the grammar routine addresses (in tokens) */
                    while (p[i] != 15)
                    {   int topbits = (p[i]/0x40) & 3;
                        int32 value = p[i+1]*256 + p[i+2];
                        switch(topbits)
                        {   case 1:
                                value = final_dict_order[value]
                                        *DICT_ENTRY_BYTE_LENGTH
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
        else {
            fatalerror_fmt(
                "Invalid grammar version: %d", grammar_version_number);
        }
    }

    /*  ---- From here on, it's all reportage: construction is finished ---- */

    if (debugfile_switch)
    {
        write_debug_information_for_actions();
        
        begin_writing_debug_sections();
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

    if (memory_map_setting)
    {
        int32 addr;
        {
printf("Dynamic +---------------------+   00000\n");
printf("memory  |       header        |   %s\n",
    show_percentage(0x40, Out_Size));
printf("        +---------------------+   00040\n");
printf("        |    abbreviations    |   %s\n",
    show_percentage(abbrevs_at-0x40, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n", (long int) abbrevs_at);
printf("        | abbreviations table |   %s\n",
    show_percentage(headerext_at-abbrevs_at, Out_Size));
printf("        +---------------------+   %05lx\n", (long int) headerext_at);
addr = (alphabet_modified ? charset_at : (zscii_defn_modified ? unicode_at : prop_defaults_at));
printf("        |  header extension   |   %s\n",
    show_percentage(addr-headerext_at, Out_Size));
            if (alphabet_modified)
            {
printf("        + - - - - - - - - - - +   %05lx\n", (long int) charset_at);
addr = (zscii_defn_modified ? unicode_at : prop_defaults_at);
printf("        |   alphabets table   |   %s\n",
    show_percentage(addr-charset_at, Out_Size));
            }
            if (zscii_defn_modified)
            {
printf("        + - - - - - - - - - - +   %05lx\n", (long int) unicode_at);
printf("        |    Unicode table    |   %s\n",
    show_percentage(prop_defaults_at-unicode_at, Out_Size));
            }
printf("        +---------------------+   %05lx\n",
                                          (long int) prop_defaults_at);
printf("        |  property defaults  |   %s\n",
    show_percentage(object_tree_at-prop_defaults_at, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n", (long int) object_tree_at);
printf("        |       objects       |   %s\n",
    show_percentage(object_props_at-object_tree_at, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) object_props_at);
printf("        | object short names, |\n");
printf("        | common prop values  |   %s\n",
    show_percentage(class_numbers_offset-object_props_at, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) class_numbers_offset);
printf("        | class numbers table |   %s\n",
    show_percentage(identifier_names_offset-class_numbers_offset, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) identifier_names_offset);
printf("        | symbol names table  |   %s\n",
    show_percentage(individuals_offset-identifier_names_offset, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) individuals_offset);
printf("        | indiv prop values   |   %s\n",
    show_percentage(globals_at-individuals_offset, Out_Size));
printf("        +---------------------+   %05lx\n", (long int) globals_at);
printf("        |  global variables   |   %s\n",
    show_percentage(480, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          ((long int) globals_at)+480L);
printf("        |       arrays        |   %s\n",
    show_percentage(grammar_table_at-(globals_at+480), Out_Size));
printf("        +=====================+   %05lx\n",
                                          (long int) grammar_table_at);
printf("Readable|    grammar table    |   %s\n",
    show_percentage(actions_at-grammar_table_at, Out_Size));
printf("memory  + - - - - - - - - - - +   %05lx\n", (long int) actions_at);
printf("        |       actions       |   %s\n",
    show_percentage(preactions_at-actions_at, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n", (long int) preactions_at);
printf("        |   parsing routines  |   %s\n",
    show_percentage(adjectives_offset-preactions_at, Out_Size));
printf("        + - - - - - - - - - - +   %05lx\n",
                                          (long int) adjectives_offset);
printf("        |     adjectives      |   %s\n",
    show_percentage(dictionary_at-adjectives_offset, Out_Size));
printf("        +---------------------+   %05lx\n", (long int) dictionary_at);
addr = (static_array_area_size ? static_arrays_at : Write_Code_At);
printf("        |     dictionary      |   %s\n",
    show_percentage(addr-dictionary_at, Out_Size));
if (static_array_area_size)
{
printf("        +---------------------+   %05lx\n", (long int) static_arrays_at);
printf("        |    static arrays    |   %s\n",
    show_percentage(Write_Code_At-static_arrays_at, Out_Size));
}
printf("        +=====================+   %05lx\n", (long int) Write_Code_At);
printf("Above   |       Z-code        |   %s\n",
    show_percentage(Write_Strings_At-Write_Code_At, Out_Size));
printf("readable+---------------------+   %05lx\n",
                                          (long int) Write_Strings_At);
addr = (Out_Size);
printf("memory  |       strings       |   %s\n",
    show_percentage(addr-Write_Strings_At, Out_Size));
printf("        +---------------------+   %05lx\n", (long int) Out_Size);
        }
    }
}

static void construct_storyfile_g(void)
{   uchar *p;
    int32 i, j, k, l, mark, strings_length;
    int32 globals_at, dictionary_at, actions_at, preactions_at,
          abbrevs_at, prop_defaults_at, object_tree_at, object_props_at,
          grammar_table_at, arrays_at, static_arrays_at;
    int32 threespaces, code_length;
    int32 rough_size;

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
    threespaces = compile_string("   ", STRCTX_GAME);

    compress_game_text();

    /*  We now know how large the buffer to hold our construction has to be  */

    rough_size = rough_size_of_paged_memory_g();
    zmachine_paged_memory = my_malloc(rough_size, "output buffer");

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
        if ((uint32)zmachine_pc != df_total_size_before_stripping)
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
      j = global_initial_value[i].value;
      WriteInt32(p+mark, j);
      mark += 4;
    }

    arrays_at = mark;
    for (i=0; i<dynamic_array_area_size; i++)
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
      k = commonprops[i].default_value;
      WriteInt32(p+mark, k);
      mark += 4;
    }

    /*  ----------- Table of Class Prototype Object Numbers ---------------- */
    
    class_numbers_offset = mark;
    for (i=0; i<no_classes; i++) {
      j = Write_RAM_At + object_tree_at +
        (OBJECT_BYTE_LENGTH*(class_info[i].object_number-1));
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

    if (!OMIT_SYMBOL_TABLE) {
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
        int ax = i;
        if (i<no_actions && GRAMMAR_META_FLAG)
          ax = sorted_actions[i].external_to_int;
        j = action_name_strings[ax];
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
    }
    else {
      identifier_names_offset = mark;
      action_names_offset = mark;
      fake_action_names_offset = mark;
      array_names_offset = mark;
    }

    individuals_offset = mark;

    /*  ------------------------ Grammar Table ----------------------------- */

    grammar_table_at = mark;

    WriteInt32(p+mark, no_Inform_verbs);
    mark += 4;

    mark += no_Inform_verbs*4;

    for (i=0; i<no_Inform_verbs; i++) {
      j = mark + Write_RAM_At;
      WriteInt32(p+(grammar_table_at+4+i*4), j);
      if (!Inform_verbs[i].used) {
          /* This verb was marked unused at locate_dead_grammar_lines()
             time. Omit the grammar lines. */
          p[mark++] = 0;
          continue;
      }
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

    if (RAM_Size > rough_size)
        compiler_error("RAM size exceeds rough estimate.");
    
    Out_Size = Write_RAM_At + RAM_Size;

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

    if (TRUE)
    {   backpatch_zmachine_image_g();

        /* The action and grammar tables must be backpatched specially. */
        
        mark = actions_at + 4;
        for (i=0; i<no_actions; i++) {
          int ax = i;
          if (GRAMMAR_META_FLAG)
            ax = sorted_actions[i].external_to_int;
          j = actions[ax].byte_offset;
          if (OMIT_UNUSED_ROUTINES)
            j = df_stripped_address_for_address(j);
          j += code_offset;
          WriteInt32(p+mark, j);
          mark += 4;
        }

        for (l = 0; l<no_Inform_verbs; l++) {
          int linecount;
          k = grammar_table_at + 4 + 4*l; 
          i = ((p[k] << 24) | (p[k+1] << 16) | (p[k+2] << 8) | (p[k+3]));
          i -= Write_RAM_At;
          linecount = p[i++];
          for (j=0; j<linecount; j++) {
            if (GRAMMAR_META_FLAG) {
              /* backpatch the action number */
              int action = (p[i+0] << 8) | (p[i+1]);
              action = sorted_actions[action].internal_to_ext;
              p[i+0] = (action >> 8) & 0xFF;
              p[i+1] = (action & 0xFF);
            }
            i = i + 3;
            while (p[i] != 15) {
              int topbits = (p[i]/0x40) & 3;
              int32 value = ((p[i+1] << 24) | (p[i+2] << 16) 
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

    if (debugfile_switch)
    {
        write_debug_information_for_actions();
        
        begin_writing_debug_sections();
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

    if (memory_map_setting)
    {
        int32 addr;
        {
printf("        +---------------------+   000000\n");
printf("Read-   |       header        |   %s\n",
    show_percentage(GLULX_HEADER_SIZE, Out_Size));
printf(" only   +=====================+   %06lx\n", (long int) GLULX_HEADER_SIZE);
printf("memory  |  memory layout id   |   %s\n",
    show_percentage(Write_Code_At-GLULX_HEADER_SIZE, Out_Size));
printf("        +---------------------+   %06lx\n", (long int) Write_Code_At);
printf("        |        code         |   %s\n",
    show_percentage(Write_Strings_At-Write_Code_At, Out_Size));
printf("        +---------------------+   %06lx\n",
  (long int) Write_Strings_At);
printf("        | string decode table |   %s\n",
    show_percentage(compression_table_size, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) Write_Strings_At + compression_table_size);
addr = (static_array_area_size ? static_arrays_at : Write_RAM_At+globals_at);
printf("        |       strings       |   %s\n",
    show_percentage(addr-(Write_Strings_At + compression_table_size), Out_Size));
            if (static_array_area_size)
            {
printf("        +---------------------+   %06lx\n", 
  (long int) (static_arrays_at));
printf("        |    static arrays    |   %s\n",
    show_percentage(Write_RAM_At+globals_at-static_arrays_at, Out_Size));
            }
printf("        +=====================+   %06lx\n", 
  (long int) (Write_RAM_At+globals_at));
printf("Dynamic |  global variables   |   %s\n",
    show_percentage(arrays_at-globals_at, Out_Size));
printf("memory  + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+arrays_at));
printf("        |       arrays        |   %s\n",
    show_percentage(abbrevs_at-arrays_at, Out_Size));
printf("        +---------------------+   %06lx\n",
  (long int) (Write_RAM_At+abbrevs_at));
printf("        | printing variables  |   %s\n",
    show_percentage(object_tree_at-abbrevs_at, Out_Size));
printf("        +---------------------+   %06lx\n", 
  (long int) (Write_RAM_At+object_tree_at));
printf("        |       objects       |   %s\n",
    show_percentage(object_props_at-object_tree_at, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+object_props_at));
printf("        |   property values   |   %s\n",
    show_percentage(prop_defaults_at-object_props_at, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+prop_defaults_at));
printf("        |  property defaults  |   %s\n",
    show_percentage(class_numbers_offset-prop_defaults_at, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+class_numbers_offset));
printf("        | class numbers table |   %s\n",
    show_percentage(identifier_names_offset-class_numbers_offset, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n",
  (long int) (Write_RAM_At+identifier_names_offset));
printf("        |   id names table    |   %s\n",
    show_percentage(grammar_table_at-identifier_names_offset, Out_Size));
printf("        +---------------------+   %06lx\n",
  (long int) (Write_RAM_At+grammar_table_at));
printf("        |    grammar table    |   %s\n",
    show_percentage(actions_at-grammar_table_at, Out_Size));
printf("        + - - - - - - - - - - +   %06lx\n", 
  (long int) (Write_RAM_At+actions_at));
printf("        |       actions       |   %s\n",
    show_percentage(dictionary_offset-(Write_RAM_At+actions_at), Out_Size));
printf("        +---------------------+   %06lx\n", 
  (long int) dictionary_offset);
printf("        |     dictionary      |   %s\n",
    show_percentage(Out_Size-dictionary_offset, Out_Size));
            if (MEMORY_MAP_EXTENSION == 0)
            {
printf("        +---------------------+   %06lx\n", (long int) Out_Size);
            }
            else
            {
printf("        +=====================+   %06lx\n", (long int) Out_Size);
printf("Runtime |       (empty)       |\n");   /* no percentage */
printf("  extn  +---------------------+   %06lx\n", (long int) Out_Size+MEMORY_MAP_EXTENSION);
            }

        }

    }
}

static void display_frequencies()
{
    int i, j;
    
    printf("How frequently abbreviations were used, and roughly\n");
    printf("how many bytes they saved:  ('_' denotes spaces)\n");
    
    for (i=0; i<no_abbreviations; i++) {
        int32 saving;
        char *astr;
        if (!glulx_mode)
            saving = 2*((abbreviations[i].freq-1)*abbreviations[i].quality)/3;
        else
            saving = (abbreviations[i].freq-1)*abbreviations[i].quality;

        astr = abbreviation_text(i);
        /* Print the abbreviation text, left-padded to ten spaces, with
           spaces replaced by underscores. */
        for (j=strlen(astr); j<10; j++) {
            putchar(' ');
        }
        for (j=0; astr[j]; j++) {
            putchar(astr[j] == ' ' ? '_' : astr[j]);
        }
        
        printf(" %5d/%5d   ", abbreviations[i].freq, saving);
        
        if ((i%3)==2) printf("\n");
    }
    if ((i%3)!=0) printf("\n");
    
    if (no_abbreviations==0) printf("None were declared.\n");
}

static void display_statistics_z()
{
    int32 k_long, rate;
    char *k_str = "";
    uchar *p = (uchar *) zmachine_paged_memory;
    char *output_called = "story file";
    int globcount;
    int limit = 0;

    /* Yeah, we're repeating this calculation from construct_storyfile_z() */
    switch(version_number)
    {   case 3: limit = 128; break;
        case 4:
        case 5: limit = 256; break;
        case 6:
        case 7:
        case 8: limit = 512; break;
    }

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
%6d symbols                    %8ld bytes of memory\n\
Out:   Version %d \"%s\" %s %d.%c%c%c%c%c%c (%ld%sK long):\n",
               no_symbols,
               (long int) malloced_bytes,
               version_number,
               version_name(version_number),
               output_called,
               release_number, p[18], p[19], p[20], p[21], p[22], p[23],
               (long int) k_long, k_str);

        if (version_number <= 3 && ZCODE_COMPACT_GLOBALS)
            globcount = no_globals - (7+zcode_user_global_start_no);
        else            
            globcount = no_globals - zcode_user_global_start_no;
        
        printf("\
%6d classes                      %6d objects\n\
%6d global vars (maximum 233)    %6d variable/array space\n",
               no_classes,
               no_objects,
               globcount,
               dynamic_array_area_size);

        printf(
               "%6d verbs                        %6d dictionary entries\n\
%6d grammar lines (version %d)    %6d grammar tokens (unlimited)\n\
%6d actions                      %6d attributes (maximum %2d)\n\
%6d common props (maximum %2d)    %6d individual props (unlimited)\n",
               no_Inform_verbs,
               dict_entries,
               no_grammar_lines, grammar_version_number,
               no_grammar_tokens,
               no_actions,
               no_attributes, ((version_number==3)?32:48),
               no_properties-3, ((version_number==3)?29:61),
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

static void display_statistics_g()
{
    int32 k_long, rate;
    char *k_str = "";
    int32 limit = 1024*1024;
    int32 strings_length = compression_table_size + compression_string_size;
    char *output_called = "story file";
    
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
%6d symbols                    %8ld bytes of memory\n\
Out:   %s %s %d.%c%c%c%c%c%c (%ld%sK long):\n",
                   no_symbols,
                   (long int) malloced_bytes,
                   version_name(version_number),
                   output_called,
                   release_number,
                   serialnum[0], serialnum[1], serialnum[2],
                   serialnum[3], serialnum[4], serialnum[5],
                   (long int) k_long, k_str);
        } 

        printf("\
%6d classes                      %6d objects\n\
%6d global vars                  %6d variable/array space\n",
               no_classes,
               no_objects,
               no_globals,
               dynamic_array_area_size);

        printf(
               "%6d verbs                        %6d dictionary entries\n\
%6d grammar lines (version %d)    %6d grammar tokens (unlimited)\n\
%6d actions                      %6d attributes (maximum %2d)\n\
%6d common props (maximum %3d)   %6d individual props (unlimited)\n",
               no_Inform_verbs,
               dict_entries,
               no_grammar_lines, grammar_version_number,
               no_grammar_tokens,
               no_actions,
               no_attributes, NUM_ATTR_BYTES*8,
               no_properties-3, INDIV_PROP_START-3,
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


extern void construct_storyfile(void)
{
    if (!glulx_mode)
        construct_storyfile_z();
    else
        construct_storyfile_g();

    /* Display all the trace/stats info that came out of compilation.

       (Except for the memory map, which uses a bunch of local variables
       from construct_storyfile_z/g(), so it's easier to do that inside
       that function.)
    */
    
    if (frequencies_setting)
        display_frequencies();

    if (list_symbols_setting)
        list_symbols(list_symbols_setting);
    
    if (list_dict_setting)
        show_dictionary(list_dict_setting);
    
    if (list_verbs_setting)
        list_verb_table();

    if (printactions_switch)
        list_action_table();

    if (list_objects_setting)
        list_object_tree();
    
    if (statistics_switch) {
        if (!glulx_mode)
            display_statistics_z();
        else
            display_statistics_g();
    }
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
      arrays_offset = 0x0800;
      static_arrays_offset = 0x0800;
      zcode_compact_globals_adjustment = 0;
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
      zcode_compact_globals_adjustment = -1;
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
