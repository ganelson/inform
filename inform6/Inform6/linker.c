/* ------------------------------------------------------------------------- */
/*   "linker" : For compiling and linking modules                            */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

memory_block link_data_area;
uchar *link_data_holding_area, *link_data_top;
                                          /*  Start, current top, size of    */
int32 link_data_size;                     /*  link data table being written  */
                                          /*  (holding import/export names)  */
extern int32 *action_symbol;

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

        /*  Additional marker values used in module backpatching  */

        case VARIABLE_MV:   return("global variable");
        case IDENT_MV:      return("prop identifier number");
        case ACTION_MV:     return("action");
        case OBJECT_MV:     return("internal object");

        /*  Record types in the import/export table (not really marker
            values at all)  */

        case EXPORT_MV:     return("Export   ");
        case EXPORTSF_MV:   return("Export sf");
        case EXPORTAC_MV:   return("Export ##");
        case IMPORT_MV:     return("Import   ");
    }
    return("** No such MV **");
}

/* ------------------------------------------------------------------------- */
/*   Import/export records                                                   */
/* ------------------------------------------------------------------------- */

typedef struct importexport_s
{   int module_value;
    int32 symbol_number;
    char symbol_type;
    int backpatch;
    int32 symbol_value;
    char *symbol_name;
} ImportExport;

static void describe_importexport(ImportExport *I)
{   printf("%8s %20s %04d %04x %s\n",
        describe_mv(I->module_value), I->symbol_name,
            I->symbol_number, I->symbol_value, typename(I->symbol_type));
}

/* ========================================================================= */
/*   Linking in external modules: this code is run when the external         */
/*   program hits a Link directive.                                          */
/* ------------------------------------------------------------------------- */
/*   This map is between global variable numbers in the module and in the    */
/*   external program: variables_map[n] will be the external global variable */
/*   no for module global variable no n.  (The entries [0] to [15] are not   */
/*   used.)                                                                  */
/* ------------------------------------------------------------------------- */

static int variables_map[256], actions_map[256];

int32 module_map[16];

ImportExport IE;

/* ------------------------------------------------------------------------- */
/*   These are offsets within the module:                                    */
/* ------------------------------------------------------------------------- */

static int32 m_code_offset, m_strs_offset, m_static_offset, m_dict_offset,
             m_vars_offset, m_objs_offset, m_props_offset, m_class_numbers,
             m_individuals_offset,         m_individuals_length;

static int m_no_objects, m_no_globals, p_no_globals, lowest_imported_global_no;

int32 *xref_table; int xref_top;
int32 *property_identifier_map;
int *accession_numbers_map;
int32 routine_replace[64],
      routine_replace_with[64]; int no_rr;

/* ------------------------------------------------------------------------- */
/*   Reading and writing bytes/words in the module (as loaded in), indexing  */
/*   via "marker addresses".                                                 */
/* ------------------------------------------------------------------------- */

static int32 read_marker_address(uchar *p, int size,
    int zmachine_area, int32 offset)
{
    /*  A routine to read the value referred to by the marker address
        (zmachine_area, offset): size is 1 for byte, 2 for word, and the
        module itself resides at p.                                          */

    int32 addr = 0;

    switch(zmachine_area)
    {
        case DYNAMIC_ARRAY_ZA:
            addr = m_vars_offset; break;
        case ZCODE_ZA:
            addr = m_code_offset; break;
        case STATIC_STRINGS_ZA:
            addr = m_strs_offset; break;
        case DICTIONARY_ZA:
            addr = m_dict_offset; break;
        case OBJECT_TREE_ZA:
            addr = m_objs_offset; break;
        case PROP_ZA:
            addr = m_props_offset; break;
        case INDIVIDUAL_PROP_ZA:
            addr = m_individuals_offset; break;
    }
    if (size == 1) return p[addr+offset];
    return 256*p[addr+offset] + p[addr+offset+1];
}

static void write_marker_address(uchar *p, int size,
    int zmachine_area, int32 offset, int32 value)
{
    /*  Similar, but to write to it.                                         */

    int32 addr = 0;

    switch(zmachine_area)
    {
        case DYNAMIC_ARRAY_ZA:
            addr = m_vars_offset; break;
        case ZCODE_ZA:
            addr = m_code_offset; break;
        case STATIC_STRINGS_ZA:
            addr = m_strs_offset; break;
        case DICTIONARY_ZA:
            addr = m_dict_offset; break;
        case OBJECT_TREE_ZA:
            addr = m_objs_offset; break;
        case PROP_ZA:
            addr = m_props_offset; break;
        case INDIVIDUAL_PROP_ZA:
            addr = m_individuals_offset; break;
    }
    if (size == 1) { p[addr+offset] = value%256; return; }
    p[addr+offset] = value/256;
    p[addr+offset+1] = value%256;
}

int m_read_pos;

static int get_next_record(uchar *p)
{   int i;
    int record_type = p[m_read_pos++];
    switch(record_type)
    {   case 0: break;
        case EXPORT_MV:
        case EXPORTSF_MV:
        case EXPORTAC_MV:
        case IMPORT_MV:
            IE.module_value = record_type;
            i=p[m_read_pos++]; IE.symbol_number = 256*i + p[m_read_pos++];
            IE.symbol_type = p[m_read_pos++];
            if (record_type != IMPORT_MV) IE.backpatch = p[m_read_pos++];
            i=p[m_read_pos++]; IE.symbol_value = 256*i + p[m_read_pos++];
            IE.symbol_name = (char *) (p+m_read_pos);
            m_read_pos += strlen((char *) (p+m_read_pos))+1;
            if (linker_trace_level >= 2) describe_importexport(&IE);
            break;
        default:
            printf("Marker value of %d\n", record_type);
            compiler_error("Link: illegal import/export marker value");
            return -1;
    }
    return record_type;
}

static char link_errorm[128];

static void accept_export(void)
{   int32 index, map_to = IE.symbol_value % 0x10000;
    index = symbol_index(IE.symbol_name, -1);

    xref_table[IE.symbol_number] = index;

    if (!(sflags[index] & UNKNOWN_SFLAG))
    {   if (IE.module_value == EXPORTAC_MV)
        {   if ((!(sflags[index] & ACTION_SFLAG))
                && (stypes[index] != FAKE_ACTION_T))
                link_error_named(
"action name clash with", IE.symbol_name);
        }
        else
        if (stypes[index] == IE.symbol_type)
        {   switch(IE.symbol_type)
            {   case CONSTANT_T:
                    if ((!(svals[index] == IE.symbol_value))
                        || (IE.backpatch != 0))
                        link_error_named(
"program and module give differing values of", IE.symbol_name);
                    break;
                case INDIVIDUAL_PROPERTY_T:
                    property_identifier_map[IE.symbol_value] = svals[index];
                    break;
                case ROUTINE_T:
                    if ((IE.module_value == EXPORTSF_MV)
                        && (sflags[index] & REPLACE_SFLAG))
                    break;
                default:
                    sprintf(link_errorm,
                        "%s '%s' in both program and module",
                        typename(IE.symbol_type), IE.symbol_name);
                    link_error(link_errorm);
                    break;
            }
        }
        else
        {   sprintf(link_errorm,
                    "'%s' has type %s in program but type %s in module",
                    IE.symbol_name, typename(stypes[index]),
                    typename(IE.symbol_type));
            link_error(link_errorm);
        }
    }
    else
    {   if (IE.module_value == EXPORTAC_MV)
        {   IE.symbol_value = no_actions;
            action_symbol[no_actions++] = index;
            if (linker_trace_level >= 4)
                printf("Creating action ##%s\n", (char *) symbs[index]);
        }
        else
        switch(IE.symbol_type)
        {   case ROUTINE_T:
                if ((IE.module_value == EXPORTSF_MV)
                    && (sflags[index] & REPLACE_SFLAG))
                {   routine_replace[no_rr] = IE.symbol_value;
                    routine_replace_with[no_rr++] = index;
                    return;
                }
                IE.symbol_value += (zmachine_pc/scale_factor);
                break;
            case OBJECT_T:
            case CLASS_T:
                IE.symbol_value += no_objects;
                break;
            case ARRAY_T:
                IE.symbol_value += dynamic_array_area_size - (MAX_GLOBAL_VARIABLES*2);
                break;
            case GLOBAL_VARIABLE_T:
                if (no_globals==233)
                {   link_error(
"failed because too many extra global variables needed");
                    return;
                }
                variables_map[16 + m_no_globals++] = 16 + no_globals;
                set_variable_value(no_globals, IE.symbol_value);
                IE.symbol_value = 16 + no_globals++;
                break;
            case INDIVIDUAL_PROPERTY_T:
                property_identifier_map[IE.symbol_value]
                    = no_individual_properties;
                IE.symbol_value = no_individual_properties++;

                if (debugfile_switch)
                {   debug_file_printf("<property>");
                    debug_file_printf
                        ("<identifier>%s</identifier>", IE.symbol_name);
                    debug_file_printf
                        ("<value>%d</value>", IE.symbol_value);
                    debug_file_printf("</property>");
                }

                break;
        }
        assign_symbol(index, IE.backpatch*0x10000 + IE.symbol_value,
            IE.symbol_type);
        if (IE.backpatch != 0) sflags[index] |= CHANGE_SFLAG;
        sflags[index] |= EXPORT_SFLAG;
        if (IE.module_value == EXPORTSF_MV)
            sflags[index] |= INSF_SFLAG;
        if (IE.module_value == EXPORTAC_MV)
            sflags[index] |= ACTION_SFLAG;
    }

    if (IE.module_value == EXPORTAC_MV)
    {   if (linker_trace_level >= 4)
            printf("Map %d '%s' to %d\n",
                IE.symbol_value, (char *) (symbs[index]), svals[index]);
        actions_map[map_to] = svals[index];
    }
}

static void accept_import(void)
{   int32 index;

    index = symbol_index(IE.symbol_name, -1);
    sflags[index] |= USED_SFLAG;
    xref_table[IE.symbol_number] = index;

    if (!(sflags[index] & UNKNOWN_SFLAG))
    {   switch (IE.symbol_type)
        {
            case GLOBAL_VARIABLE_T:
                if (stypes[index] != GLOBAL_VARIABLE_T)
                    link_error_named(
"module (wrongly) declared this a variable:", IE.symbol_name);
                variables_map[IE.symbol_value] = svals[index];
                if (IE.symbol_value < lowest_imported_global_no)
                    lowest_imported_global_no = IE.symbol_value;
                break;
            default:
                switch(stypes[index])
                {   case ATTRIBUTE_T:
                        link_error_named(
"this attribute is undeclared within module:", IE.symbol_name);; break;
                    case PROPERTY_T:
                        link_error_named(
"this property is undeclared within module:", IE.symbol_name); break;
                    case INDIVIDUAL_PROPERTY_T:
                    case ARRAY_T:
                    case ROUTINE_T:
                    case CONSTANT_T:
                    case OBJECT_T:
                    case CLASS_T:
                    case FAKE_ACTION_T:
                        break;
                    default:
                        link_error_named(
"this was referred to as a constant, but isn't:", IE.symbol_name);
                        break;
                }
                break;
        }
    }
    else
    {   switch (IE.symbol_type)
        {
            case GLOBAL_VARIABLE_T:
                if (stypes[index] != GLOBAL_VARIABLE_T)
                    link_error_named(
                "Module tried to import a Global variable not defined here:",
                        IE.symbol_name);
                variables_map[IE.symbol_value] = 16;
                if (IE.symbol_value < lowest_imported_global_no)
                    lowest_imported_global_no = IE.symbol_value;
                break;
        }
    }
}

static int32 backpatch_backpatch(int32 v)
{   switch(backpatch_marker)
    {
        /*  Backpatches made now which are final  */

        case OBJECT_MV:
            v += no_objects;
            backpatch_marker = NULL_MV;
            break;

        case ACTION_MV:
            if ((v<0) || (v>=256) || (actions_map[v] == -1))
            {   link_error("unmapped action number");
                printf("*** Link: unmapped action number %d ***", v);
                v = 0;
                break;
            }
            v = actions_map[v];
            backpatch_marker = NULL_MV;
            break;

        case IDENT_MV:
            {   int f = v & 0x8000;
                v = f + property_identifier_map[v-f];
                backpatch_marker = NULL_MV;
                break;
            }

        case VARIABLE_MV:
            backpatch_marker = NULL_MV;
            if (v < lowest_imported_global_no)
            {   v = v + p_no_globals; break;
            }
            if (variables_map[v] == -1)
            {   printf("** Unmapped variable %d! **\n", v);
                variables_map[v] = 16;
                link_error("unmapped variable error"); break;
            }
            v = variables_map[v];
            break;

        /*  Backpatch values which are themselves being backpatched  */

        case INDIVPT_MV:
            v += individuals_length;
            break;

        case SYMBOL_MV:
            v = xref_table[v];
            if ((v<0) || (v>=no_symbols))
            {   printf("** Symbol number %d cannot be crossreferenced **\n", v);
                link_error("symbol crossreference error"); v=0;
                break;
            }
            break;

        case STRING_MV:
            v += static_strings_extent/scale_factor;
            break;

        case IROUTINE_MV:
            {   int i;
                for (i=0;i<no_rr;i++)
                    if (v == routine_replace[i])
                    {   v = routine_replace_with[i];
                        backpatch_marker = SYMBOL_MV;
                        goto IR_Done;
                    }
                v += zmachine_pc/scale_factor;
            }
            IR_Done: break;

        case VROUTINE_MV:
            veneer_routine(v);
            break;

        case ARRAY_MV:
            if (v < (MAX_GLOBAL_VARIABLES*2))
            {   v = 2*(variables_map[v/2 + 16] - 16);
            }
            else
            {   v += dynamic_array_area_size - (MAX_GLOBAL_VARIABLES*2);
            }
            break;

        case DWORD_MV:
            v = accession_numbers_map[v];
            break;

        case INHERIT_MV:
            v += properties_table_size;
            break;

        case INHERIT_INDIV_MV:
            v += individuals_length;
            break;
    }
    return v;
}

static void backpatch_module_image(uchar *p,
    int marker_value, int zmachine_area, int32 offset)
{   int size = (marker_value>=0x80)?1:2; int32 v;
    marker_value &= 0x7f;

    backpatch_marker = marker_value;

    if (zmachine_area == PROP_DEFAULTS_ZA) return;

    if (linker_trace_level >= 3)
        printf("Backpatch %s area %d offset %04x size %d: ",
            describe_mv(marker_value), zmachine_area, offset, size);

    v = read_marker_address(p, size, zmachine_area, offset);
    if (linker_trace_level >= 3) printf("%04x ", v);

    v = backpatch_backpatch(v);

    write_marker_address(p, size, zmachine_area, offset, v);
    if (linker_trace_level >= 3) printf("%04x\n", v);
}

/* ------------------------------------------------------------------------- */
/*   The main routine: linking in a module with the given filename.          */
/* ------------------------------------------------------------------------- */

char current_module_filename[128];

void link_module(char *given_filename)
{   FILE *fin;
    int record_type;
    char filename[128];
    uchar *p, p0[64];
    int32 last, i, j, k, l, m, vn, len, size, link_offset, module_size, map,
          max_property_identifier, symbols_base = no_symbols;

    strcpy(current_module_filename, given_filename);

    /* (1) Load in the module to link */

    i = 0;
    do
    {   i = translate_link_filename(i, filename, given_filename);
        fin=fopen(filename,"rb");
    } while ((fin == NULL) && (i != 0));

    if (fin==NULL)
    {   error_named("Couldn't open module file", filename); return;
    }

    for (i=0;i<64;i++) p0[i]=fgetc(fin);

    vn = p0[0];
    if ((vn<65) || (vn>75))
    {   error_named("File isn't a module:", filename);
        fclose(fin); return;
    }

    if (vn != 64 + version_number)
    {   char ebuff[100];
        sprintf(ebuff,
           "module compiled as Version %d (so it can't link\
 into this V%d game):", vn-64, version_number);
        error_named(ebuff, filename);
        fclose(fin); return;
    }

    module_size     = (256*p0[26] + p0[27])*scale_factor;
    p = my_malloc(module_size + 16, "link module storage");
        /*  The + 16 allows for rounding errors  */

    for (k=0;k<64;k++) p[k] = p0[k];
    for (k=64;k<module_size;k++) p[k] = fgetc(fin);
    fclose(fin);

    if ((p0[52] != 0) || (p0[53] != 0))
    {   /*  Then the module contains a character set table  */
        if (alphabet_modified)
        {   k = FALSE; m = 256*p0[52] + p0[53];
            for (i=0;i<3;i++) for (j=0;j<26;j++)
            {   l = alphabet[i][j]; if (l == '~') l = '\"';
                if (l != p[m]) k = TRUE;
            }
            if (k)
        link_error("module and game both define non-standard character sets, \
but they disagree");
            k = FALSE;
        }
        else k = TRUE;
    }
    else
    {   if (alphabet_modified) k = TRUE;
        else k = FALSE;
    }
    if (k)
        link_error("module and game use different character sets");

    i = p[1];
    if (i > MODULE_VERSION_NUMBER)
        warning_named("module has a more advanced format than this release \
of the Inform 6 compiler knows about: it may not link in correctly", filename);

    /* (2) Calculate offsets: see the header-writing code in "tables.c"  */

    map             = (256*p[6] + p[7]);
    for (i=0; i<16; i++) module_map[i] = 256*p[map + i*2] + p[map + i*2 + 1];

    m_vars_offset   = (256*p[12] + p[13]);
    m_static_offset = (256*p[14] + p[15]);
    m_dict_offset   = (256*p[8] + p[9]);
    m_code_offset   = (256*p[4] + p[5]);

    /* (3) Read the "module map" table   */

    if (linker_trace_level>=4)
    {   printf("[Reading module map:\n");
        for (i=0; i<16; i++) printf("%04x ", module_map[i]);
        printf("]\n");
    }

    m_objs_offset        = module_map[0];
    m_props_offset       = module_map[1];
    m_strs_offset        = scale_factor*module_map[2];
    m_class_numbers      = module_map[3];
    m_individuals_offset = module_map[4];
    m_individuals_length = module_map[5];

    for (i=16;i<256;i++) variables_map[i] = -1;
    for (i=0;i<16;i++)  variables_map[i] = i;
    for (i=LOWEST_SYSTEM_VAR_NUMBER;i<256;i++) variables_map[i] = i;

    for (i=0;i<256;i++) actions_map[i] = -1;

    xref_table = my_calloc(sizeof(int32), module_map[6],
        "linker cross-references table");
    for (i=0;i<module_map[6];i++) xref_table[i] = -1;

    max_property_identifier = module_map[7];
    property_identifier_map = my_calloc(sizeof(int32), max_property_identifier,
        "property identifier map");
    for (i=0; i<max_property_identifier; i++)
        property_identifier_map[i] = i;

    m_no_objects         = module_map[8];
    link_offset          = module_map[9];

    m_no_globals = 0; p_no_globals = no_globals;
    lowest_imported_global_no=236;

    no_rr = 0;

    if ((linker_trace_level>=1) || transcript_switch)
    {   char link_banner[128];
        sprintf(link_banner,
            "[Linking release %d.%c%c%c%c%c%c of module '%s' (size %dK)]",
            p[2]*256 + p[3], p[18], p[19], p[20], p[21], p[22], p[23],
            filename, module_size/1024);
        if (linker_trace_level >= 1) printf("%s\n", link_banner);
        if (transcript_switch)
            write_to_transcript_file(link_banner);
    }

    /* (4) Merge in the dictionary */

    if (linker_trace_level >= 2)
        printf("Merging module's dictionary at %04x\n", m_dict_offset);
    k=m_dict_offset; k+=p[k]+1;
    len=p[k++];
    size = p[k]*256 + p[k+1]; k+=2;

    accession_numbers_map = my_calloc(sizeof(int), size,
        "dictionary accession numbers map");

    for (i=0;i<size;i++, k+=len)
    {   char word[10];
        word_to_ascii(p+k,word);
        if (linker_trace_level >= 3)
            printf("%03d %04x  '%s' %02x %02x %02x\n",i,k,
            word, p[k+len-3], p[k+len-2], p[k+len-1]);

        accession_numbers_map[i]
            = dictionary_add(word, p[k+len-3], p[k+len-2], p[k+len-1]);
    }

    /* (5) Run through import/export table  */

    m_read_pos = module_map[9];
    if (linker_trace_level>=2)
        printf("Import/export table is at byte offset %04x\n", m_read_pos);

    do
    {   record_type = get_next_record(p);
        if (((record_type == EXPORT_MV) || (record_type == EXPORTSF_MV))
            && (IE.symbol_type == INDIVIDUAL_PROPERTY_T))
        {   int32 si = symbol_index(IE.symbol_name, -1);
            property_identifier_map[IE.symbol_value] = svals[si];
        }
        switch(record_type)
        {   case EXPORT_MV:
            case EXPORTSF_MV:
            case EXPORTAC_MV:
                accept_export(); break;
            case IMPORT_MV:
                accept_import(); break;
        }
    } while (record_type != 0);

    if ((linker_trace_level >= 4) && (no_rr != 0))
    {   printf("Replaced routine addresses:\n");
        for (i=0; i<no_rr; i++)
        {   printf("Replace code offset %04x with %04x\n",
                routine_replace[i], routine_replace_with[i]);
        }
    }

    if (linker_trace_level >= 4)
    {   printf("Symbol cross-references table:\n");
        for (i=0; i<module_map[6]; i++)
        {   if (xref_table[i] != -1)
                printf("module %4d -> story file '%s'\n", i,
                    (char *) symbs[xref_table[i]]);
        }
    }

    if (linker_trace_level >= 4)
    {   printf("Action numbers map:\n");
        for (i=0; i<256; i++)
            if (actions_map[i] != -1)
                printf("%3d -> %3d\n", i, actions_map[i]);
    }

    if ((linker_trace_level >= 4) && (max_property_identifier > 72))
    {   printf("Property identifier number map:\n");
        for (i=72; i<max_property_identifier; i++)
        {   printf("module %04x -> program %04x\n",
                i, property_identifier_map[i]);
        }
    }

    /* (6) Backpatch the backpatch markers attached to exported symbols  */

    for (i=symbols_base; i<no_symbols; i++)
    {   if ((sflags[i] & CHANGE_SFLAG) && (sflags[i] & EXPORT_SFLAG))
        {   backpatch_marker = svals[i]/0x10000;
            j = svals[i] % 0x10000;

            j = backpatch_backpatch(j);

            svals[i] = backpatch_marker*0x10000 + j;
            if (backpatch_marker == 0) sflags[i] &= (~(CHANGE_SFLAG));
        }
    }

    /* (7) Run through the Z-code backpatch table  */

    for (i=module_map[11]; i<module_map[11]+module_map[12]; i += 3)
    {   int marker_value = p[i];
        int32 offset = 256*p[i+1] + p[i+2];

        switch(marker_value & 0x7f)
        {   case OBJECT_MV:
            case ACTION_MV:
            case IDENT_MV:
            case VARIABLE_MV:
                backpatch_module_image(p, marker_value, ZCODE_ZA, offset);
                break;
            default:
                backpatch_module_image(p, marker_value, ZCODE_ZA, offset);
                write_byte_to_memory_block(&zcode_backpatch_table,
                    zcode_backpatch_size++, backpatch_marker);
                write_byte_to_memory_block(&zcode_backpatch_table,
                    zcode_backpatch_size++, (offset + zmachine_pc)/256);
                write_byte_to_memory_block(&zcode_backpatch_table,
                    zcode_backpatch_size++, (offset + zmachine_pc)%256);
                break;
        }
    }

    /* (8) Run through the Z-machine backpatch table  */

    for (i=module_map[13]; i<module_map[13]+module_map[14]; i += 4)
    {   int marker_value = p[i], zmachine_area = p[i+1];
        int32 offset = 256*p[i+2] + p[i+3];

        switch(marker_value)
        {   case OBJECT_MV:
            case ACTION_MV:
            case IDENT_MV:
                backpatch_module_image(p, marker_value, zmachine_area, offset);
                break;
            default:
                backpatch_module_image(p, marker_value, zmachine_area, offset);
                switch(zmachine_area)
                {   case PROP_DEFAULTS_ZA:
                        break;
                    case PROP_ZA:
                        offset += properties_table_size; break;
                    case INDIVIDUAL_PROP_ZA:
                        offset += individuals_length; break;
                    case DYNAMIC_ARRAY_ZA:
                        if (offset < (MAX_GLOBAL_VARIABLES*2))
                        {   offset = 2*(variables_map[offset/2 + 16] - 16);
                        }
                        else
                        {   offset += dynamic_array_area_size - (MAX_GLOBAL_VARIABLES*2);
                        }
                        break;
                }
                backpatch_zmachine(backpatch_marker, zmachine_area, offset);
                break;
        }
    }

    /* (9) Adjust initial values of variables */

    if (linker_trace_level >= 3)
        printf("\nFinal variables map, Module -> Main:\n");

    for (i=16;i<255;i++)
        if (variables_map[i]!=-1)
        {   if (linker_trace_level>=2)
                printf("%d->%d  ",i,variables_map[i]);
            if (i<lowest_imported_global_no)
            {   int32 j = read_marker_address(p, 2,
                    DYNAMIC_ARRAY_ZA, 2*(i-16));
                set_variable_value(variables_map[i]-16, j);
                if (linker_trace_level>=2)
                    printf("(set var %d to %d) ",
                        variables_map[i], j);
            }
        }
    if (linker_trace_level>=2) printf("\n");

    /* (10) Glue in the dynamic array data */

    i = m_static_offset - m_vars_offset - MAX_GLOBAL_VARIABLES*2;
    if (dynamic_array_area_size + i >= MAX_STATIC_DATA)
        memoryerror("MAX_STATIC_DATA", MAX_STATIC_DATA);

    if (linker_trace_level >= 2)
        printf("Inserting dynamic array area, %04x to %04x, at %04x\n",
            m_vars_offset + MAX_GLOBAL_VARIABLES*2, m_static_offset,
            variables_offset + dynamic_array_area_size);
    for (k=0;k<i;k++)
    {   dynamic_array_area[dynamic_array_area_size+k]
            = p[m_vars_offset+MAX_GLOBAL_VARIABLES*2+k];
    }
    dynamic_array_area_size+=i;

    /* (11) Glue in the code area */

    if (linker_trace_level >= 2)
      printf("Inserting code area, %04x to %04x, at code offset %04x (+%04x)\n",
        m_code_offset, m_strs_offset, code_offset, zmachine_pc);

    for (k=m_code_offset;k<m_strs_offset;k++)
    {   if (temporary_files_switch)
        {   fputc(p[k],Temp2_fp);
            zmachine_pc++;
        }
        else
            write_byte_to_memory_block(&zcode_area, zmachine_pc++, p[k]);
    }

    /* (12) Glue in the static strings area */

    if (linker_trace_level >= 2)
        printf("Inserting strings area, %04x to %04x, \
at strings offset %04x (+%04x)\n",
        m_strs_offset, link_offset, strings_offset,
        static_strings_extent);
    for (k=m_strs_offset;k<link_offset;k++)
    {   if (temporary_files_switch)
        {   fputc(p[k], Temp1_fp);
            static_strings_extent++;
        }
        else
            write_byte_to_memory_block(&static_strings_area,
                    static_strings_extent++, p[k]);
    }

    /* (13) Append the class object-numbers table: note that modules
            provide extra information in this table */

    i = m_class_numbers;
    do
    {   j = p[i]*256 + p[i+1]; i+=2;
        if (j == 0) break;

        class_object_numbers[no_classes] = j + no_objects;
        j = p[i]*256 + p[i+1]; i+=2;
        class_begins_at[no_classes++] = j + properties_table_size;

    } while (TRUE);

    /* (14) Glue on the object tree */

    if ((linker_trace_level>=2) && (m_no_objects>0))
        printf("Joining on object tree of size %d\n", m_no_objects);

    for (i=0, k=no_objects, last=m_props_offset;i<m_no_objects;i++)
    {   objectsz[no_objects].atts[0]=p[m_objs_offset+14*i];
        objectsz[no_objects].atts[1]=p[m_objs_offset+14*i+1];
        objectsz[no_objects].atts[2]=p[m_objs_offset+14*i+2];
        objectsz[no_objects].atts[3]=p[m_objs_offset+14*i+3];
        objectsz[no_objects].atts[4]=p[m_objs_offset+14*i+4];
        objectsz[no_objects].atts[5]=p[m_objs_offset+14*i+5];
        objectsz[no_objects].parent =
            (p[m_objs_offset+14*i+6])*256+p[m_objs_offset+14*i+7];
        objectsz[no_objects].next =
            (p[m_objs_offset+14*i+8])*256+p[m_objs_offset+14*i+9];
        objectsz[no_objects].child =
            (p[m_objs_offset+14*i+10])*256+p[m_objs_offset+14*i+11];
        if (linker_trace_level>=4)
            printf("Module objects[%d] has %d,%d,%d\n",
                i,objectsz[no_objects].parent,
                objectsz[no_objects].next,objectsz[no_objects].child);
        if (objectsz[no_objects].parent == 0x7fff)
        {   objectsz[no_objects].parent = 1;
            if (objectsz[1].child == 0)
            {   objectsz[1].child = no_objects+1;
            }
            else
            {   int j1 = 0, j2 = objectsz[1].child;
                while (j2 != 0)
                {   j1 = j2;
                    j2 = objectsz[j2].next;
                }
                objectsz[j1].next = no_objects+1;
            }
            objectsz[no_objects].next = 0;
        }
        else
        if (objectsz[no_objects].parent>0) objectsz[no_objects].parent += k;
        if (objectsz[no_objects].next>0)   objectsz[no_objects].next   += k;
        if (objectsz[no_objects].child>0)  objectsz[no_objects].child  += k;
        objectsz[no_objects].propsize =
            (p[m_objs_offset+14*i+12])*256+p[m_objs_offset+14*i+13];
        last += objectsz[no_objects].propsize;
        if (linker_trace_level>=4)
            printf("Objects[%d] has %d,%d,%d\n",
                no_objects,objectsz[no_objects].parent,
                objectsz[no_objects].next,objectsz[no_objects].child);
        no_objects++;
    }

    /* (15) Glue on the properties */

    if (last>m_props_offset)
    {   i = m_static_offset - m_vars_offset - MAX_GLOBAL_VARIABLES*2;
        if (dynamic_array_area_size + i >= MAX_STATIC_DATA)
            memoryerror("MAX_STATIC_DATA", MAX_STATIC_DATA);

        if (linker_trace_level >= 2)
            printf("Inserting object properties area, %04x to %04x, at +%04x\n",
                m_props_offset, last, properties_table_size);
        for (k=0;k<last-m_props_offset;k++)
            properties_table[properties_table_size++] = p[m_props_offset+k];
    }

    /* (16) Bitwise OR Flags 2 (Z-machine requirements flags) */

    j = p[16]*256 + p[17];
    for (i=0, k=1;i<16;i++, k=k*2) flags2_requirements[i] |= ((j/k)%2);

    /* (17) Append the individual property values table */

    i = m_individuals_length;
    if (individuals_length + i >= MAX_INDIV_PROP_TABLE_SIZE)
        memoryerror("MAX_INDIV_PROP_TABLE_SIZE",
            MAX_INDIV_PROP_TABLE_SIZE);

    if (linker_trace_level >= 2)
      printf("Inserting individual prop tables area, %04x to %04x, at +%04x\n",
            m_individuals_offset, m_individuals_offset + i,
            individuals_length);
    for (k=0;k<i;k++)
    {   individuals_table[individuals_length + k]
            = p[m_individuals_offset + k];
    }
    individuals_length += i;

    /* (18) All done */

    if (linker_trace_level >= 2)
         printf("Link complete\n");

  my_free(&p, "link module storage");
  my_free(&xref_table, "linker cross-references table");
  my_free(&property_identifier_map, "property identifier map");
  my_free(&accession_numbers_map, "accession numbers map");
}

/* ========================================================================= */
/*   Writing imports, exports and markers to the link data table during      */
/*   module compilation                                                      */
/* ------------------------------------------------------------------------- */
/*   Writing to the link data table                                          */
/* ------------------------------------------------------------------------- */

static void write_link_byte(int x)
{   *link_data_top=(unsigned char) x; link_data_top++; link_data_size++;
    if (subtract_pointers(link_data_top,link_data_holding_area)
        >= MAX_LINK_DATA_SIZE)
    {   memoryerror("MAX_LINK_DATA_SIZE",MAX_LINK_DATA_SIZE);
    }
}

extern void flush_link_data(void)
{   int32 i, j;
    j = subtract_pointers(link_data_top, link_data_holding_area);
    if (temporary_files_switch)
        for (i=0;i<j;i++) fputc(link_data_holding_area[i], Temp3_fp);
    else
        for (i=0;i<j;i++)
            write_byte_to_memory_block(&link_data_area, link_data_size-j+i,
            link_data_holding_area[i]);
    link_data_top=link_data_holding_area;
}

static void write_link_word(int32 x)
{   write_link_byte(x/256); write_link_byte(x%256);
}

static void write_link_string(char *s)
{   int i;
    for (i=0; s[i]!=0; i++) write_link_byte(s[i]);
    write_link_byte(0);
}

/* ------------------------------------------------------------------------- */
/*   Exports and imports                                                     */
/* ------------------------------------------------------------------------- */

static void export_symbols(void)
{   int symbol_number;

    for (symbol_number = 0; symbol_number < no_symbols; symbol_number++)
    {   int export_flag = FALSE, import_flag = FALSE;

        if (stypes[symbol_number]==GLOBAL_VARIABLE_T)
        {   if (svals[symbol_number] < LOWEST_SYSTEM_VAR_NUMBER)
            {   if (sflags[symbol_number] & IMPORT_SFLAG)
                    import_flag = TRUE;
                else
                    if (!(sflags[symbol_number] & SYSTEM_SFLAG))
                        export_flag = TRUE;
            }
        }
        else
        {   if (!(sflags[symbol_number] & SYSTEM_SFLAG))
            {   if (sflags[symbol_number] & UNKNOWN_SFLAG)
                {   if (sflags[symbol_number] & IMPORT_SFLAG)
                        import_flag = TRUE;
                }
                else
                switch(stypes[symbol_number])
                {   case LABEL_T:
                    case ATTRIBUTE_T:
                    case PROPERTY_T:
                         /*  Ephemera  */
                         break;

                    default: export_flag = TRUE;
                }
            }
        }

        if (export_flag)
        {   if (linker_trace_level >= 1)
            {   IE.module_value = EXPORT_MV;
                IE.symbol_number = symbol_number;
                IE.symbol_type = stypes[symbol_number];
                IE.symbol_value = svals[symbol_number];
                IE.symbol_name = (char *) (symbs[symbol_number]);
                describe_importexport(&IE);
            }

            if (sflags[symbol_number] & ACTION_SFLAG)
                write_link_byte(EXPORTAC_MV);
            else
            if (sflags[symbol_number] & INSF_SFLAG)
                write_link_byte(EXPORTSF_MV);
            else
                write_link_byte(EXPORT_MV);

            write_link_word(symbol_number);
            write_link_byte(stypes[symbol_number]);
            if (sflags[symbol_number] & CHANGE_SFLAG)
                 write_link_byte(svals[symbol_number] / 0x10000);
            else write_link_byte(0);
            write_link_word(svals[symbol_number] % 0x10000);
            write_link_string((char *) (symbs[symbol_number]));
            flush_link_data();
        }

        if (import_flag)
        {   if (linker_trace_level >= 1)
            {   IE.module_value = IMPORT_MV;
                IE.symbol_number = symbol_number;
                IE.symbol_type = stypes[symbol_number];
                IE.symbol_value = svals[symbol_number];
                IE.symbol_name = (char *) (symbs[symbol_number]);
                describe_importexport(&IE);
            }

            write_link_byte(IMPORT_MV);
            write_link_word(symbol_number);
            write_link_byte(stypes[symbol_number]);
            write_link_word(svals[symbol_number]);
            write_link_string((char *) (symbs[symbol_number]));
            flush_link_data();
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Marking for later importation                                           */
/* ------------------------------------------------------------------------- */

int mv_vref=LOWEST_SYSTEM_VAR_NUMBER-1;

void import_symbol(int32 symbol_number)
{   sflags[symbol_number] |= IMPORT_SFLAG;
    switch(stypes[symbol_number])
    {   case GLOBAL_VARIABLE_T:
            assign_symbol(symbol_number, mv_vref--, stypes[symbol_number]);
            break;
    }
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_linker_vars(void)
{   link_data_size = 0;
    initialise_memory_block(&link_data_area);
}

extern void linker_begin_pass(void)
{   link_data_top = link_data_holding_area;
}

extern void linker_endpass(void)
{   export_symbols();
    write_link_byte(0);
    flush_link_data();
}

extern void linker_allocate_arrays(void)
{   if (!module_switch)
        link_data_holding_area
            = my_malloc(64, "link data holding area");
    else
        link_data_holding_area
            = my_malloc(MAX_LINK_DATA_SIZE, "link data holding area");
}

extern void linker_free_arrays(void)
{   my_free(&link_data_holding_area, "link data holding area");
    deallocate_memory_block(&link_data_area);
}

/* ========================================================================= */
