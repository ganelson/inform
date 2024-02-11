/* ------------------------------------------------------------------------- */
/*   "objects" :  [1] the object-maker, which constructs objects and enters  */
/*                    them into the tree, given a low-level specification;   */
/*                                                                           */
/*                [2] the parser of Object/Nearby/Class directives, which    */
/*                    checks syntax and translates such directives into      */
/*                    specifications for the object-maker.                   */
/*                                                                           */
/*   Part of Inform 6.42                                                     */
/*   copyright (c) Graham Nelson 1993 - 2024                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

/* ------------------------------------------------------------------------- */
/*   Objects.                                                                */
/* ------------------------------------------------------------------------- */

int no_objects;                        /* Number of objects made so far      */

static int no_embedded_routines;       /* Used for naming routines which
                                          are given as property values: these
                                          are called EmbeddedRoutine__1, ... */

static fpropt full_object;             /* "fpropt" is a typedef for a struct
                                          containing an array to hold the
                                          attribute and property values of
                                          a single object.  We only keep one
                                          of these, for the current object
                                          being made, and compile it into
                                          Z-machine tables when each object
                                          definition is complete, since
                                          sizeof(fpropt) is about 6200 bytes */
static fproptg full_object_g;          /* Equivalent for Glulx. This object
                                          is very small, since the large arrays
                                          are allocated dynamically as
                                          memory-lists                       */

static char *shortname_buffer;         /* Text buffer to hold the short name
                                          (which is read in first, but
                                          written almost last)               */
static memory_list shortname_buffer_memlist;

static int parent_of_this_obj;

static memory_list current_object_name; /* The name of the object currently
                                           being defined.                    */

static int current_classname_symbol;    /* The symbol index of the class
                                           currently being defined.
                                           For error-checking and printing
                                           names of embedded routines only.  */

static memory_list embedded_function_name; /* Temporary storage for inline
                                              function name in property.     */

/* ------------------------------------------------------------------------- */
/*   Classes.                                                                */
/* ------------------------------------------------------------------------- */
/*   Arrays defined below:                                                   */
/*                                                                           */
/*    classinfo class_info[]              Object number and prop offset      */
/*    int   classes_to_inherit_from[]     The list of classes to inherit     */
/*                                        from as taken from the current     */
/*                                        Nearby/Object/Class definition     */
/* ------------------------------------------------------------------------- */

int        no_classes;                 /* Number of class defns made so far  */

static int current_defn_is_class,      /* TRUE if current Nearby/Object/Class
                                          defn is in fact a Class definition */
           no_classes_to_inherit_from; /* Number of classes in the list
                                          of classes to inherit in the
                                          current Nearby/Object/Class defn   */

/* ------------------------------------------------------------------------- */
/*   Making attributes and properties.                                       */
/* ------------------------------------------------------------------------- */

int no_attributes,                 /* Number of attributes defined so far    */
    no_properties;                 /* Number of properties defined so far,
                                      plus 1 (properties are numbered from
                                      1 and Inform creates "name" and two
                                      others itself, so the variable begins
                                      the compilation pass set to 4)         */

/* Print a PROPS trace line. The f flag is 0 for an attribute, 1 for
   a common property, 2 for an individual property. */
static void trace_s(char *name, int32 number, int f)
{   char *stype = "";
    if (!printprops_switch) return;
    if (f == 0) stype = "Attr";
    else if (f == 1) stype = "Prop";
    else if (f == 2) stype = "Indiv";
    printf("%-5s  %02ld  ", stype, (long int) number);
    if (f != 1) printf("  ");
    else      printf("%s%s",(commonprops[number].is_long)?"L":" ",
                            (commonprops[number].is_additive)?"A":" ");
    printf("  %-24s  (%s)\n", name, current_location_text());
}

extern void make_attribute(void)
{   int i; char *name;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

 if (!glulx_mode) { 
    if (no_attributes==((version_number==3)?32:48))
    {   discard_token_location(beginning_debug_location);
        if (version_number==3)
            error("All 32 attributes already declared (compile as Advanced \
game to get an extra 16)");
        else
            error("All 48 attributes already declared");
        panic_mode_error_recovery();
        put_token_back();
        return;
    }
 }
 else {
    if (no_attributes==NUM_ATTR_BYTES*8) {
      discard_token_location(beginning_debug_location);
      error_fmt(
        "All %d attributes already declared -- increase NUM_ATTR_BYTES to use \
more", 
        NUM_ATTR_BYTES*8);
      panic_mode_error_recovery(); 
      put_token_back();
      return;
    }
 }

    get_next_token();
    i = token_value; name = token_text;
    /* We hold onto token_text through the end of this Property directive, which should be okay. */
    if (token_type != SYMBOL_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_curtoken_error("new attribute name");
        panic_mode_error_recovery(); 
        put_token_back();
        return;
    }
    if (!(symbols[i].flags & UNKNOWN_SFLAG))
    {   discard_token_location(beginning_debug_location);
        ebf_symbol_error("new attribute name", token_text, typename(symbols[i].type), symbols[i].line);
        panic_mode_error_recovery(); 
        put_token_back();
        return;
    }

    directive_keywords.enabled = TRUE;
    get_next_token();
    directive_keywords.enabled = FALSE;

    if ((token_type == DIR_KEYWORD_TT) && (token_value == ALIAS_DK))
    {   get_next_token();
        if (!((token_type == SYMBOL_TT)
              && (symbols[token_value].type == ATTRIBUTE_T)))
        {   discard_token_location(beginning_debug_location);
            ebf_curtoken_error("an existing attribute name after 'alias'");
            panic_mode_error_recovery();
            put_token_back();
            return;
        }
        assign_symbol(i, symbols[token_value].value, ATTRIBUTE_T);
        symbols[token_value].flags |= ALIASED_SFLAG;
        symbols[i].flags |= ALIASED_SFLAG;
    }
    else
    {   assign_symbol(i, no_attributes++, ATTRIBUTE_T);
        put_token_back();
    }

    if (debugfile_switch)
    {   debug_file_printf("<attribute>");
        debug_file_printf("<identifier>%s</identifier>", name);
        debug_file_printf("<value>%d</value>", symbols[i].value);
        write_debug_locations(get_token_location_end(beginning_debug_location));
        debug_file_printf("</attribute>");
    }

    trace_s(name, symbols[i].value, 0);
    return;
}

/* Format:
   Property [long] [additive] name
   Property [long] [additive] name alias oldname
   Property [long] [additive] name defaultvalue
   Property [long] individual name
 */
extern void make_property(void)
{   int32 default_value, i;
    int keywords, prevkeywords;
    char *name;
    int namelen;
    int additive_flag, indiv_flag;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    /* The next bit is tricky. We want to accept any number of the keywords
       "long", "additive", "individual" before the property name. But we
       also want to accept "Property long" -- that's a legitimate
       property name.
       The solution is to keep track of which keywords we've seen in
       a bitmask, and another for one token previous. That way we
       can back up one token if there's no name visible. */
    keywords = prevkeywords = 0;
    do
    {   directive_keywords.enabled = TRUE;
        get_next_token();
        if ((token_type == DIR_KEYWORD_TT) && (token_value == LONG_DK)) {
            prevkeywords = keywords;
            keywords |= 1;
        }
        else if ((token_type == DIR_KEYWORD_TT) && (token_value == ADDITIVE_DK)) {
            prevkeywords = keywords;
            keywords |= 2;
        }
        else if ((token_type == DIR_KEYWORD_TT) && (token_value == INDIVIDUAL_DK)) {
            prevkeywords = keywords;
            keywords |= 4;
        }
        else {
            break;
        }
    } while (TRUE);
    
    /* Re-parse the name with keywords turned off. (This allows us to
       accept a property name like "table".) */
    put_token_back();
    directive_keywords.enabled = FALSE;
    get_next_token();

    if (token_type != SYMBOL_TT && keywords) {
        /* This can't be a name. Try putting back the last keyword. */
        keywords = prevkeywords;
        put_token_back();
        put_token_back();
        get_next_token();
    }

    additive_flag = indiv_flag = FALSE;
    if (keywords & 1)
        obsolete_warning("all properties are now automatically 'long'");
    if (keywords & 2)
        additive_flag = TRUE;
    if (keywords & 4)
        indiv_flag = TRUE;
    
    i = token_value; name = token_text;
    /* We hold onto token_text through the end of this Property directive, which should be okay. */
    if (token_type != SYMBOL_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_curtoken_error("new property name");
        panic_mode_error_recovery();
        put_token_back();
        return;
    }
    if (!(symbols[i].flags & UNKNOWN_SFLAG))
    {   discard_token_location(beginning_debug_location);
        ebf_symbol_error("new property name", token_text, typename(symbols[i].type), symbols[i].line);
        panic_mode_error_recovery();
        put_token_back();
        return;
    }

    if (indiv_flag) {
        int this_identifier_number;
        
        if (additive_flag)
        {   error("'individual' incompatible with 'additive'");
            panic_mode_error_recovery();
            put_token_back();
            return;
        }

        this_identifier_number = no_individual_properties++;
        assign_symbol(i, this_identifier_number, INDIVIDUAL_PROPERTY_T);
        if (debugfile_switch) {
            debug_file_printf("<property>");
            debug_file_printf
                ("<identifier>%s</identifier>", name);
            debug_file_printf
                ("<value>%d</value>", this_identifier_number);
            debug_file_printf("</property>");
        }
        trace_s(name, symbols[i].value, 2);
        return;        
    }

    directive_keywords.enabled = TRUE;
    get_next_token();
    directive_keywords.enabled = FALSE;

    namelen = strlen(name);
    if (namelen > 3 && strcmp(name+namelen-3, "_to") == 0) {
        /* Direction common properties "n_to", etc are compared in some
           libraries. They have STAR_SFLAG to tell us to skip a warning. */
        symbols[i].flags |= STAR_SFLAG;
    }

    /* Now we might have "alias" or a default value (but not both). */

    if ((token_type == DIR_KEYWORD_TT) && (token_value == ALIAS_DK))
    {   discard_token_location(beginning_debug_location);
        if (additive_flag)
        {   error("'alias' incompatible with 'additive'");
            panic_mode_error_recovery();
            put_token_back();
            return;
        }
        get_next_token();
        if (!((token_type == SYMBOL_TT)
            && (symbols[token_value].type == PROPERTY_T)))
        {   ebf_curtoken_error("an existing property name after 'alias'");
            panic_mode_error_recovery();
            put_token_back();
            return;
        }

        assign_symbol(i, symbols[token_value].value, PROPERTY_T);
        trace_s(name, symbols[i].value, 1);
        symbols[token_value].flags |= ALIASED_SFLAG;
        symbols[i].flags |= ALIASED_SFLAG;
        return;
    }

    /* We now know we're allocating a new common property. Make sure 
       there's room. */
    if (!glulx_mode) {
        if (no_properties==((version_number==3)?32:64))
        {   discard_token_location(beginning_debug_location);
            /* The maximum listed here includes "name" but not the 
               unused zero value or the two hidden properties (class
               inheritance and indiv table). */
            if (version_number==3)
                error("All 29 properties already declared (compile as \
Advanced game to get 32 more)");
            else
                error("All 61 properties already declared");
            panic_mode_error_recovery();
            put_token_back();
            return;
        }
    }
    else {
        if (no_properties==INDIV_PROP_START) {
            discard_token_location(beginning_debug_location);
            error_fmt(
                "All %d properties already declared (increase INDIV_PROP_START to get more)",
                INDIV_PROP_START-3);
            panic_mode_error_recovery(); 
            put_token_back();
            return;
        }
    }

    default_value = 0;
    put_token_back();

    if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
    {
        assembly_operand AO = parse_expression(CONSTANT_CONTEXT);
        default_value = AO.value;
        if (AO.marker != 0)
            backpatch_zmachine(AO.marker, PROP_DEFAULTS_ZA, 
                (no_properties-1) * WORDSIZE);
    }

    commonprops[no_properties].default_value = default_value;
    commonprops[no_properties].is_long = TRUE;
    commonprops[no_properties].is_additive = additive_flag;

    assign_symbol(i, no_properties++, PROPERTY_T);

    if (debugfile_switch)
    {   debug_file_printf("<property>");
        debug_file_printf("<identifier>%s</identifier>", name);
        debug_file_printf("<value>%d</value>", symbols[i].value);
        write_debug_locations
            (get_token_location_end(beginning_debug_location));
        debug_file_printf("</property>");
    }

    trace_s(name, symbols[i].value, 1);
}

/* ------------------------------------------------------------------------- */
/*   Properties.                                                             */
/* ------------------------------------------------------------------------- */

commonpropinfo *commonprops;            /* Info about common properties
                                           (fixed allocation of 
                                           INDIV_PROP_START entries) */

uchar *properties_table;               /* Holds the table of property values
                                          (holding one block for each object
                                          and coming immediately after the
                                          object tree in Z-memory)           */
memory_list properties_table_memlist;
int properties_table_size;             /* Number of bytes in this table      */

/* ------------------------------------------------------------------------- */
/*   Individual properties                                                   */
/*                                                                           */
/*   Each new i.p. name is given a unique number.  These numbers start from  */
/*   72, since 0 is reserved as a null, 1 to 63 refer to common properties   */
/*   and 64 to 71 are kept for methods of the metaclass Class (for example,  */
/*   64 is "create").                                                        */
/*                                                                           */
/*   An object provides individual properties by having property 3 set to a  */
/*   non-zero value, which must be a byte address of a table in the form:    */
/*                                                                           */
/*       <record-1> ... <record-n> 00 00                                     */
/*                                                                           */
/*   where a <record> looks like                                             */
/*                                                                           */
/*       <identifier>              <size>  <up to 255 bytes of data>         */
/*       or <identifier + 0x8000>                                            */
/*       ----- 2 bytes ----------  1 byte  <size> number of bytes            */
/*                                                                           */
/*   The <identifier> part is the number allocated to the name of what is    */
/*   being provided.  The top bit of this word is set to indicate that       */
/*   although the individual property is being provided, it is provided      */
/*   only privately (so that it is inaccessible except to the object's own   */
/*   embedded routines).                                                     */
/*                                                                           */
/*   In Glulx: i-props are numbered from INDIV_PROP_START+8 up. And all      */
/*   properties, common and individual, are stored in the same table.        */
/* ------------------------------------------------------------------------- */

       int no_individual_properties;   /* Actually equal to the next
                                          identifier number to be allocated,
                                          so this is initially 72 even though
                                          none have been made yet.           */
static int individual_prop_table_size; /* Size of the table of individual
                                          properties so far for current obj  */
       uchar *individuals_table;       /* Table of records, each being the
                                          i.p. table for an object           */
       memory_list individuals_table_memlist;
       int i_m;                        /* Write mark position in the above   */
       int individuals_length;         /* Extent of individuals_table        */

/* ------------------------------------------------------------------------- */
/*   Arrays used by this file                                                */
/* ------------------------------------------------------------------------- */

objecttz     *objectsz;              /* Allocated to no_objects; Z-code only */
memory_list objectsz_memlist;
objecttg     *objectsg;              /* Allocated to no_objects; Glulx only  */
static memory_list objectsg_memlist;
uchar        *objectatts;            /* Allocated to no_objects; Glulx only  */
static memory_list objectatts_memlist;
static int   *classes_to_inherit_from; /* Allocated to no_classes_to_inherit_from */
static memory_list classes_to_inherit_from_memlist;
classinfo    *class_info;            /* Allocated up to no_classes           */
memory_list   class_info_memlist;

/* ------------------------------------------------------------------------- */
/*   Tracing for compiler maintenance                                        */
/* ------------------------------------------------------------------------- */

extern void list_object_tree(void)
{   int i;
    printf("Object tree:\n");
    printf("obj name                             par nxt chl:\n");
    for (i=0; i<no_objects; i++) {
        if (!glulx_mode) {
            int sym = objectsz[i].symbol;
            char *symname = ((sym > 0) ? symbols[sym].name : "...");
            printf("%3d %-32s %3d %3d %3d\n",
                i+1, symname,
                objectsz[i].parent, objectsz[i].next, objectsz[i].child);
        }
        else {
            int sym = objectsg[i].symbol;
            char *symname = ((sym > 0) ? symbols[sym].name : "...");
            printf("%3d %-32s %3d %3d %3d\n",
                i+1, symname,
                objectsg[i].parent, objectsg[i].next, objectsg[i].child);
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Object and class manufacture begins here.                               */
/*                                                                           */
/*   These definitions have headers (parsed far, far below) and a series     */
/*   of segments, introduced by keywords and optionally separated by commas. */
/*   Each segment has its own parsing routine.  Note that when errors are    */
/*   detected, parsing continues rather than being abandoned, which assists  */
/*   a little in "error recovery" (i.e. in stopping lots more errors being   */
/*   produced for essentially the same mistake).                             */
/* ------------------------------------------------------------------------- */

/* ========================================================================= */
/*   [1]  The object-maker: builds an object from a specification, viz.:     */
/*                                                                           */
/*           full_object,                                                    */
/*           shortname_buffer,                                               */
/*           parent_of_this_obj,                                             */
/*           current_defn_is_class (flag)                                    */
/*           classes_to_inherit_from[], no_classes_to_inherit_from,          */
/*           individual_prop_table_size (to date  )                          */
/*                                                                           */
/*   For efficiency's sake, the individual properties table has already been */
/*   created (as far as possible, i.e., all except for inherited individual  */
/*   properties); unless the flag is clear, in which case the actual         */
/*   definition did not specify any individual properties.                   */
/* ========================================================================= */
/*   Property inheritance from classes.                                      */
/* ------------------------------------------------------------------------- */

static void property_inheritance_z(void)
{
    /*  Apply the property inheritance rules to full_object, which should
        initially be complete (i.e., this routine takes place after the whole
        Nearby/Object/Class definition has been parsed through).

        On exit, full_object contains the final state of the properties to
        be written.                                                          */

    int i, j, k, kmax, class, mark,
        prop_number, prop_length, prop_in_current_defn;
    uchar *class_prop_block;

    ASSERT_ZCODE();

    for (class=0; class<no_classes_to_inherit_from; class++)
    {
        j=0;
        mark = class_info[classes_to_inherit_from[class] - 1].begins_at;
        class_prop_block = (properties_table + mark);

        while (class_prop_block[j]!=0)
        {   if (version_number == 3)
            {   prop_number = class_prop_block[j]%32;
                prop_length = 1 + class_prop_block[j++]/32;
            }
            else
            {   prop_number = class_prop_block[j]%64;
                prop_length = 1 + class_prop_block[j++]/64;
                if (prop_length > 2)
                    prop_length = class_prop_block[j++]%64;
            }

            /*  So we now have property number prop_number present in the
                property block for the class being read: its bytes are

                class_prop_block[j, ..., j + prop_length - 1]

                Question now is: is there already a value given in the
                current definition under this property name?                 */

            prop_in_current_defn = FALSE;

            kmax = full_object.l;
            if (kmax > 64)
                fatalerror("More than 64 property entries in an object");

            for (k=0; k<kmax; k++)
                if (full_object.pp[k].num == prop_number)
                {   prop_in_current_defn = TRUE;

                    /*  (Note that the built-in "name" property is additive) */

                    if ((prop_number==1) || (commonprops[prop_number].is_additive))
                    {
                        /*  The additive case: we accumulate the class
                            property values onto the end of the full_object
                            property                                         */

                        for (i=full_object.pp[k].l;
                             i<full_object.pp[k].l+prop_length/2; i++)
                        {
                            if (i >= 32)
                            {   error("An additive property has inherited \
so many values that the list has overflowed the maximum 32 entries");
                                break;
                            }
                            if ((version_number==3) && i >= 4)
                            {   error("An additive property has inherited \
so many values that the list has overflowed the maximum 4 entries");
                                break;
                            }
                            INITAOTV(&full_object.pp[k].ao[i], LONG_CONSTANT_OT, mark + j);
                            j += 2;
                            full_object.pp[k].ao[i].marker = INHERIT_MV;
                        }
                        full_object.pp[k].l += prop_length/2;
                    }
                    else
                        /*  The ordinary case: the full_object property
                            values simply overrides the class definition,
                            so we skip over the values in the class table    */

                        j+=prop_length;

                    if (prop_number==3)
                    {   int y, z, class_block_offset;

                        /*  Property 3 holds the address of the table of
                            instance variables, so this is the case where
                            the object already has instance variables in its
                            own table but must inherit some more from the
                            class  */

                        class_block_offset = class_prop_block[j-2]*256
                                             + class_prop_block[j-1];

                        z = class_block_offset;
                        while ((individuals_table[z]!=0)||(individuals_table[z+1]!=0))
                        {   int already_present = FALSE, l;
                            for (l = full_object.pp[k].ao[0].value; l < i_m;
                                 l = l + 3 + individuals_table[l + 2])
                                if (individuals_table[l] == individuals_table[z]
                                    && individuals_table[l + 1] == individuals_table[z+1])
                                {   already_present = TRUE; break;
                                }
                            if (already_present == FALSE)
                            {
                                ensure_memory_list_available(&individuals_table_memlist, i_m+3+individuals_table[z+2]);
                                individuals_table[i_m++] = individuals_table[z];
                                individuals_table[i_m++] = individuals_table[z+1];
                                individuals_table[i_m++] = individuals_table[z+2];
                                for (y=0;y < individuals_table[z+2]/2;y++)
                                {   individuals_table[i_m++] = (z+3+y*2)/256;
                                    individuals_table[i_m++] = (z+3+y*2)%256;
                                    backpatch_zmachine(INHERIT_INDIV_MV,
                                        INDIVIDUAL_PROP_ZA, i_m-2);
                                }
                            }
                            z += individuals_table[z+2] + 3;
                        }
                        individuals_length = i_m;
                    }

                    /*  For efficiency we exit the loop now (this property
                        number has been dealt with)                          */

                    break;
                }

            if (!prop_in_current_defn)
            {
                /*  The case where the class defined a property which wasn't
                    defined at all in full_object: we copy out the data into
                    a new property added to full_object                      */

                k=full_object.l++;
                if (k >= 64)
                    fatalerror("More than 64 property entries in an object");
                full_object.pp[k].num = prop_number;
                full_object.pp[k].l = prop_length/2;
                for (i=0; i<prop_length/2; i++)
                {
                    INITAOTV(&full_object.pp[k].ao[i], LONG_CONSTANT_OT, mark + j);
                    j+=2;
                    full_object.pp[k].ao[i].marker = INHERIT_MV;
                }

                if (prop_number==3)
                {   int y, z, class_block_offset;

                    /*  Property 3 holds the address of the table of
                        instance variables, so this is the case where
                        the object had no instance variables of its own
                        but must inherit some more from the class  */

                    if (individual_prop_table_size++ == 0)
                    {   full_object.pp[k].num = 3;
                        full_object.pp[k].l = 1;
                        INITAOTV(&full_object.pp[k].ao[0], LONG_CONSTANT_OT, individuals_length);
                        full_object.pp[k].ao[0].marker = INDIVPT_MV;
                        i_m = individuals_length;
                    }
                    class_block_offset = class_prop_block[j-2]*256
                                         + class_prop_block[j-1];

                    z = class_block_offset;
                    while ((individuals_table[z]!=0)||(individuals_table[z+1]!=0))
                    {
                        ensure_memory_list_available(&individuals_table_memlist, i_m+3+individuals_table[z+2]);
                        individuals_table[i_m++] = individuals_table[z];
                        individuals_table[i_m++] = individuals_table[z+1];
                        individuals_table[i_m++] = individuals_table[z+2];
                        for (y=0;y < individuals_table[z+2]/2;y++)
                        {   individuals_table[i_m++] = (z+3+y*2)/256;
                            individuals_table[i_m++] = (z+3+y*2)%256;
                            backpatch_zmachine(INHERIT_INDIV_MV,
                                INDIVIDUAL_PROP_ZA, i_m-2);
                        }
                        z += individuals_table[z+2] + 3;
                    }
                    individuals_length = i_m;
                }
            }
        }
    }

    if (individual_prop_table_size > 0)
    {
        ensure_memory_list_available(&individuals_table_memlist, i_m+2);

        individuals_table[i_m++] = 0;
        individuals_table[i_m++] = 0;
        individuals_length += 2;
    }
}

static void property_inheritance_g(void)
{
  /*  Apply the property inheritance rules to full_object, which should
      initially be complete (i.e., this routine takes place after the whole
      Nearby/Object/Class definition has been parsed through).
      
      On exit, full_object contains the final state of the properties to
      be written. */

  int i, j, k, class, num_props,
    prop_number, prop_length, prop_flags, prop_in_current_defn;
  int32 mark, prop_addr;
  uchar *cpb, *pe;

  ASSERT_GLULX();

  for (class=0; class<no_classes_to_inherit_from; class++) {
    mark = class_info[classes_to_inherit_from[class] - 1].begins_at;
    cpb = (properties_table + mark);
    /* This now points to the compiled property-table for the class.
       We'll have to go through and decompile it. (For our sins.) */
    num_props = ReadInt32(cpb);
    for (j=0; j<num_props; j++) {
      pe = cpb + 4 + j*10;
      prop_number = ReadInt16(pe);
      pe += 2;
      prop_length = ReadInt16(pe);
      pe += 2;
      prop_addr = ReadInt32(pe);
      pe += 4;
      prop_flags = ReadInt16(pe);
      pe += 2;

      /*  So we now have property number prop_number present in the
          property block for the class being read. Its bytes are
          cpb[prop_addr ... prop_addr + prop_length - 1]
          Question now is: is there already a value given in the
          current definition under this property name? */

      prop_in_current_defn = FALSE;

      for (k=0; k<full_object_g.numprops; k++) {
        if (full_object_g.props[k].num == prop_number) {
          prop_in_current_defn = TRUE;
          break;
        }
      }

      if (prop_in_current_defn) {
        if ((prop_number==1)
          || (prop_number < INDIV_PROP_START 
            && commonprops[prop_number].is_additive)) {
          /*  The additive case: we accumulate the class
              property values onto the end of the full_object
              properties. Remember that k is still the index number
              of the first prop-block matching our property number. */
          int prevcont;
          if (full_object_g.props[k].continuation == 0) {
            full_object_g.props[k].continuation = 1;
            prevcont = 1;
          }
          else {
            prevcont = full_object_g.props[k].continuation;
            for (k++; k<full_object_g.numprops; k++) {
              if (full_object_g.props[k].num == prop_number) {
                prevcont = full_object_g.props[k].continuation;
              }
            }
          }
          k = full_object_g.numprops++;
          ensure_memory_list_available(&full_object_g.props_memlist, k+1);
          full_object_g.props[k].num = prop_number;
          full_object_g.props[k].flags = 0;
          full_object_g.props[k].datastart = full_object_g.propdatasize;
          full_object_g.props[k].continuation = prevcont+1;
          full_object_g.props[k].datalen = prop_length;
          
          ensure_memory_list_available(&full_object_g.propdata_memlist, full_object_g.propdatasize + prop_length);
          for (i=0; i<prop_length; i++) {
            int ppos = full_object_g.propdatasize++;
            INITAOTV(&full_object_g.propdata[ppos], CONSTANT_OT, prop_addr + 4*i);
            full_object_g.propdata[ppos].marker = INHERIT_MV;
          }
        }
        else {
          /*  The ordinary case: the full_object_g property
              values simply overrides the class definition,
              so we skip over the values in the class table. */
        }
      }
          else {
            /*  The case where the class defined a property which wasn't
                defined at all in full_object_g: we copy out the data into
                a new property added to full_object_g. */
            k = full_object_g.numprops++;
            ensure_memory_list_available(&full_object_g.props_memlist, k+1);
            full_object_g.props[k].num = prop_number;
            full_object_g.props[k].flags = prop_flags;
            full_object_g.props[k].datastart = full_object_g.propdatasize;
            full_object_g.props[k].continuation = 0;
            full_object_g.props[k].datalen = prop_length;

            ensure_memory_list_available(&full_object_g.propdata_memlist, full_object_g.propdatasize + prop_length);
            for (i=0; i<prop_length; i++) {
              int ppos = full_object_g.propdatasize++;
              INITAOTV(&full_object_g.propdata[ppos], CONSTANT_OT, prop_addr + 4*i);
              full_object_g.propdata[ppos].marker = INHERIT_MV; 
            }
          }

    }
  }
  
}

/* ------------------------------------------------------------------------- */
/*   Construction of Z-machine-format property blocks.                       */
/* ------------------------------------------------------------------------- */

static int write_properties_between(int mark, int from, int to)
{   int j, k, prop_number;

    for (prop_number=to; prop_number>=from; prop_number--)
    {   for (j=0; j<full_object.l; j++)
        {   if ((full_object.pp[j].num == prop_number)
                && (full_object.pp[j].l != 100))
            {
                int prop_length = 2*full_object.pp[j].l;
                ensure_memory_list_available(&properties_table_memlist, mark+2+prop_length);
                if (version_number == 3)
                    properties_table[mark++] = prop_number + (prop_length - 1)*32;
                else
                {   switch(prop_length)
                    {   case 1:
                          properties_table[mark++] = prop_number; break;
                        case 2:
                          properties_table[mark++] = prop_number + 0x40; break;
                        default:
                          properties_table[mark++] = prop_number + 0x80;
                          properties_table[mark++] = prop_length + 0x80; break;
                    }
                }

                for (k=0; k<full_object.pp[j].l; k++)
                {
                    if (k >= 32) {
                        /* We catch this earlier, but we'll check again to avoid overflowing ao[] */
                        error("Too many values for Z-machine property");
                        break;
                    }
                    if (full_object.pp[j].ao[k].marker != 0)
                        backpatch_zmachine(full_object.pp[j].ao[k].marker,
                            PROP_ZA, mark);
                    properties_table[mark++] = full_object.pp[j].ao[k].value/256;
                    properties_table[mark++] = full_object.pp[j].ao[k].value%256;
                }
            }
        }
    }

    ensure_memory_list_available(&properties_table_memlist, mark+1);
    properties_table[mark++]=0;
    return(mark);
}

static int write_property_block_z(char *shortname)
{
    /*  Compile the (now complete) full_object properties into a
        property-table block at "p" in Inform's memory.
        "shortname" is the object's short name, if specified; otherwise
        NULL.

        Return the number of bytes written to the block.                     */

    int32 mark = properties_table_size, i;

    /* printf("Object at %04x\n", mark); */

    if (shortname != NULL)
    {
        /* The limit of 510 bytes, or 765 Z-characters, is a Z-spec limit. */
        i = translate_text(510,shortname,STRCTX_OBJNAME);
        if (i < 0) {
            error ("Short name of object exceeded 765 Z-characters");
            i = 0;
        }
        ensure_memory_list_available(&properties_table_memlist, mark+1+i);
        memcpy(properties_table + mark+1, translated_text, i);
        properties_table[mark] = i/2;
        mark += i+1;
    }
    if (current_defn_is_class)
    {   mark = write_properties_between(mark,3,3);
        ensure_memory_list_available(&properties_table_memlist, mark+6);
        for (i=0;i<6;i++)
            properties_table[mark++] = full_object.atts[i];
        ensure_memory_list_available(&class_info_memlist, no_classes+1);
        class_info[no_classes++].begins_at = mark;
    }

    mark = write_properties_between(mark, 1, (version_number==3)?31:63);

    i = mark - properties_table_size;
    properties_table_size = mark;

    return(i);
}

static int gpropsort(void *ptr1, void *ptr2)
{
  propg *prop1 = ptr1;
  propg *prop2 = ptr2;
  
  if (prop2->num == -1)
    return -1;
  if (prop1->num == -1)
    return 1;
  if (prop1->num < prop2->num)
    return -1;
  if (prop1->num > prop2->num)
    return 1;

  return (prop1->continuation - prop2->continuation);
}

static int32 write_property_block_g(void)
{
  /*  Compile the (now complete) full_object properties into a
      property-table block at "p" in Inform's memory. 
      Return the number of bytes written to the block. 
      In Glulx, the shortname property isn't used here; it's already
      been compiled into an ordinary string. */

  int32 i;
  int ix, jx, kx, totalprops;
  int32 mark = properties_table_size;
  int32 datamark;

  if (current_defn_is_class) {
    ensure_memory_list_available(&properties_table_memlist, mark+NUM_ATTR_BYTES);
    for (i=0;i<NUM_ATTR_BYTES;i++)
      properties_table[mark++] = full_object_g.atts[i];
    ensure_memory_list_available(&class_info_memlist, no_classes+1);
    class_info[no_classes++].begins_at = mark;
  }

  qsort(full_object_g.props, full_object_g.numprops, sizeof(propg), 
    (int (*)(const void *, const void *))(&gpropsort));

  full_object_g.finalpropaddr = mark;

  totalprops = 0;

  for (ix=0; ix<full_object_g.numprops; ix=jx) {
    int propnum = full_object_g.props[ix].num;
    if (propnum == -1)
        break;
    for (jx=ix; 
        jx<full_object_g.numprops && full_object_g.props[jx].num == propnum;
        jx++);
    totalprops++;
  }

  /* Write out the number of properties in this table. */
  ensure_memory_list_available(&properties_table_memlist, mark+4);
  WriteInt32(properties_table+mark, totalprops);
  mark += 4;

  datamark = mark + 10*totalprops;

  for (ix=0; ix<full_object_g.numprops; ix=jx) {
    int propnum = full_object_g.props[ix].num;
    int flags = full_object_g.props[ix].flags;
    int totallen = 0;
    int32 datamarkstart = datamark;
    if (propnum == -1)
      break;
    for (jx=ix; 
        jx<full_object_g.numprops && full_object_g.props[jx].num == propnum;
        jx++) {
      int32 datastart = full_object_g.props[jx].datastart;
      ensure_memory_list_available(&properties_table_memlist, datamark+4*full_object_g.props[jx].datalen);
      for (kx=0; kx<full_object_g.props[jx].datalen; kx++) {
        int32 val = full_object_g.propdata[datastart+kx].value;
        WriteInt32(properties_table+datamark, val);
        if (full_object_g.propdata[datastart+kx].marker != 0)
          backpatch_zmachine(full_object_g.propdata[datastart+kx].marker,
            PROP_ZA, datamark);
        totallen++;
        datamark += 4;
      }
    }
    ensure_memory_list_available(&properties_table_memlist, mark+10);
    WriteInt16(properties_table+mark, propnum);
    mark += 2;
    WriteInt16(properties_table+mark, totallen);
    mark += 2;
    WriteInt32(properties_table+mark, datamarkstart); 
    mark += 4;
    WriteInt16(properties_table+mark, flags);
    mark += 2;
  }

  mark = datamark;

  i = mark - properties_table_size;
  properties_table_size = mark;
  return i;
}

/* ------------------------------------------------------------------------- */
/*   The final stage in Nearby/Object/Class definition processing.           */
/* ------------------------------------------------------------------------- */

static void manufacture_object_z(void)
{   int i, j;

    segment_markers.enabled = FALSE;
    directives.enabled = TRUE;

    ensure_memory_list_available(&objectsz_memlist, no_objects+1);

    objectsz[no_objects].symbol = full_object.symbol;
    
    property_inheritance_z();

    objectsz[no_objects].parent = parent_of_this_obj;
    objectsz[no_objects].next = 0;
    objectsz[no_objects].child = 0;

    if ((parent_of_this_obj > 0) && (parent_of_this_obj != 0x7fff))
    {   i = objectsz[parent_of_this_obj-1].child;
        if (i == 0)
            objectsz[parent_of_this_obj-1].child = no_objects + 1;
        else
        {   while(objectsz[i-1].next != 0) i = objectsz[i-1].next;
            objectsz[i-1].next = no_objects+1;
        }
    }

        /*  The properties table consists simply of a sequence of property
            blocks, one for each object in order of definition, exactly as
            it will appear in the final Z-machine.                           */

    j = write_property_block_z(shortname_buffer);

    objectsz[no_objects].propsize = j;

    if (current_defn_is_class)
        for (i=0;i<6;i++) objectsz[no_objects].atts[i] = 0;
    else
        for (i=0;i<6;i++)
            objectsz[no_objects].atts[i] = full_object.atts[i];

    no_objects++;
}

static void manufacture_object_g(void)
{   int32 i, j;

    segment_markers.enabled = FALSE;
    directives.enabled = TRUE;

    ensure_memory_list_available(&objectsg_memlist, no_objects+1);
    ensure_memory_list_available(&objectatts_memlist, no_objects+1);
    
    objectsg[no_objects].symbol = full_object_g.symbol;
    
    property_inheritance_g();

    objectsg[no_objects].parent = parent_of_this_obj;
    objectsg[no_objects].next = 0;
    objectsg[no_objects].child = 0;

    if ((parent_of_this_obj > 0) && (parent_of_this_obj != 0x7fffffff))
    {   i = objectsg[parent_of_this_obj-1].child;
        if (i == 0)
            objectsg[parent_of_this_obj-1].child = no_objects + 1;
        else
        {   while(objectsg[i-1].next != 0) i = objectsg[i-1].next;
            objectsg[i-1].next = no_objects+1;
        }
    }

    objectsg[no_objects].shortname = compile_string(shortname_buffer,
      STRCTX_OBJNAME);

        /*  The properties table consists simply of a sequence of property
            blocks, one for each object in order of definition, exactly as
            it will appear in the final machine image.                      */

    j = write_property_block_g();

    objectsg[no_objects].propaddr = full_object_g.finalpropaddr;

    objectsg[no_objects].propsize = j;

    if (current_defn_is_class)
        for (i=0;i<NUM_ATTR_BYTES;i++) 
            objectatts[no_objects*NUM_ATTR_BYTES+i] = 0;
    else
        for (i=0;i<NUM_ATTR_BYTES;i++)
            objectatts[no_objects*NUM_ATTR_BYTES+i] = full_object_g.atts[i];

    no_objects++;
}


/* ========================================================================= */
/*   [2]  The Object/Nearby/Class directives parser: translating the syntax  */
/*        into object specifications and then triggering off the above.      */
/* ========================================================================= */
/*   Properties ("with" or "private") segment.                               */
/* ------------------------------------------------------------------------- */

static int *defined_this_segment;
static long defined_this_segment_size; /* calloc size */
static int def_t_s;

static void ensure_defined_this_segment(int newsize)
{
    int oldsize = defined_this_segment_size;
    defined_this_segment_size = newsize;
    my_recalloc(&defined_this_segment, sizeof(int), oldsize,
        defined_this_segment_size, "defined this segment table");
}

static void properties_segment_z(int this_segment)
{
    /*  Parse through the "with" part of an object/class definition:

        <prop-1> <values...>, <prop-2> <values...>, ..., <prop-n> <values...>

        This routine also handles "private", with this_segment being equal
        to the token value for the introductory word ("private" or "with").  */


    int   i, property_name_symbol, property_number=0, next_prop=0, length,
          individual_property, this_identifier_number;

    do
    {   get_next_token_with_directives();
        if ((token_type == SEGMENT_MARKER_TT)
            || (token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   put_token_back(); return;
        }

        if (token_type != SYMBOL_TT)
        {   ebf_curtoken_error("property name");
            return;
        }

        individual_property = (symbols[token_value].type != PROPERTY_T);

        if (individual_property)
        {   if (symbols[token_value].flags & UNKNOWN_SFLAG)
            {   this_identifier_number = no_individual_properties++;
                assign_symbol(token_value, this_identifier_number,
                    INDIVIDUAL_PROPERTY_T);

                if (debugfile_switch)
                {   debug_file_printf("<property>");
                    debug_file_printf
                        ("<identifier>%s</identifier>", token_text);
                    debug_file_printf
                        ("<value>%d</value>", this_identifier_number);
                    debug_file_printf("</property>");
                }

                trace_s(token_text, symbols[token_value].value, 2);
            }
            else
            {   if (symbols[token_value].type==INDIVIDUAL_PROPERTY_T)
                    this_identifier_number = symbols[token_value].value;
                else
                {   ebf_symbol_error("property name", token_text, typename(symbols[token_value].type), symbols[token_value].line);
                    return;
                }
            }

            if (def_t_s >= defined_this_segment_size)
                ensure_defined_this_segment(def_t_s*2);
            defined_this_segment[def_t_s++] = token_value;

            if (individual_prop_table_size++ == 0)
            {
                int k=full_object.l++;
                if (k >= 64)
                    fatalerror("More than 64 property entries in an object");
                full_object.pp[k].num = 3;
                full_object.pp[k].l = 1;
                INITAOTV(&full_object.pp[k].ao[0], LONG_CONSTANT_OT, individuals_length);
                full_object.pp[k].ao[0].marker = INDIVPT_MV;

                i_m = individuals_length;
            }
            ensure_memory_list_available(&individuals_table_memlist, i_m+3);
            individuals_table[i_m] = this_identifier_number/256;
            if (this_segment == PRIVATE_SEGMENT)
                individuals_table[i_m] |= 0x80;
            individuals_table[i_m+1] = this_identifier_number%256;
            individuals_table[i_m+2] = 0;
        }
        else
        {   if (symbols[token_value].flags & UNKNOWN_SFLAG)
            {   error_named("No such property name as", token_text);
                return;
            }
            if (this_segment == PRIVATE_SEGMENT)
                error_named("Property should be declared in 'with', \
not 'private':", token_text);
            if (def_t_s >= defined_this_segment_size)
                ensure_defined_this_segment(def_t_s*2);
            defined_this_segment[def_t_s++] = token_value;
            property_number = symbols[token_value].value;

            next_prop=full_object.l++;
            if (next_prop >= 64)
                fatalerror("More than 64 property entries in an object");
            full_object.pp[next_prop].num = property_number;
        }

        for (i=0; i<(def_t_s-1); i++)
            if (defined_this_segment[i] == token_value)
            {   error_named("Property given twice in the same declaration:",
                    symbols[token_value].name);
            }
            else
            if (symbols[defined_this_segment[i]].value == symbols[token_value].value)
            {
                error_fmt(
                    "Property given twice in the same declaration, because \
the names \"%s\" and \"%s\" actually refer to the same property",
                    symbols[defined_this_segment[i]].name,
                    symbols[token_value].name);
            }

        property_name_symbol = token_value;
        symbols[token_value].flags |= USED_SFLAG;

        length=0;
        do
        {   assembly_operand AO;
            get_next_token_with_directives();
            if ((token_type == EOF_TT)
                || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
                || ((token_type == SEP_TT) && (token_value == COMMA_SEP)))
                break;

            if (token_type == SEGMENT_MARKER_TT) { put_token_back(); break; }

            if ((!individual_property) && (property_number==1)
                && ((token_type != SQ_TT) || (strlen(token_text) <2 )) 
                && (token_type != DQ_TT)
                )
                warning ("'name' property should only contain dictionary words");

            if ((token_type == SEP_TT) && (token_value == OPEN_SQUARE_SEP))
            {
                char *prefix, *sep, *sym;
                sym = symbols[property_name_symbol].name;
                if (current_defn_is_class)
                {
                    prefix = symbols[current_classname_symbol].name;
                    sep = "::";
                }
                else
                {
                    prefix = current_object_name.data;
                    sep = ".";
                }
                ensure_memory_list_available(&embedded_function_name, strlen(prefix)+strlen(sep)+strlen(sym)+1);
                sprintf(embedded_function_name.data, "%s%s%s", prefix, sep, sym);

                /* parse_routine() releases lexer text! */
                AO.value = parse_routine(NULL, TRUE, embedded_function_name.data, FALSE, -1);
                AO.type = LONG_CONSTANT_OT;
                AO.marker = IROUTINE_MV;

                directives.enabled = FALSE;
                segment_markers.enabled = TRUE;

                statements.enabled = FALSE;
                misc_keywords.enabled = FALSE;
                local_variables.enabled = FALSE;
                system_functions.enabled = FALSE;
                conditions.enabled = FALSE;
            }
            else

            /*  A special rule applies to values in double-quotes of the
                built-in property "name", which always has number 1: such
                property values are dictionary entries and not static
                strings                                                      */

            if ((!individual_property) &&
                (property_number==1) && (token_type == DQ_TT))
            {   AO.value = dictionary_add(token_text, 0x80, 0, 0);
                AO.type = LONG_CONSTANT_OT;
                AO.marker = DWORD_MV;
            }
            else
            {   if (length!=0)
                {
                    if ((token_type == SYMBOL_TT)
                        && (symbols[token_value].type==PROPERTY_T))
                    {
                        /*  This is not necessarily an error: it's possible
                            to imagine a property whose value is a list
                            of other properties to look up, but far more
                            likely that a comma has been omitted in between
                            two property blocks                              */

                        warning_named(
               "Missing ','? Property data seems to contain the property name",
                            token_text);
                    }
                }

                /*  An ordinary value, then:                                 */

                put_token_back();
                AO = parse_expression(ARRAY_CONTEXT);
            }

            /* length is in bytes here, but we report the limit in words. */

            if (length == 64)
            {   error_named("Limit (of 32 values) exceeded for property",
                    symbols[property_name_symbol].name);
                break;
            }

            if ((version_number==3) && (!individual_property) && length == 8)
            {   error_named("Limit (of 4 values) exceeded for property",
                    symbols[property_name_symbol].name);
                break;
            }
            
            if (individual_property)
            {   if (AO.marker != 0)
                    backpatch_zmachine(AO.marker, INDIVIDUAL_PROP_ZA,
                        i_m+3+length);
                ensure_memory_list_available(&individuals_table_memlist, i_m+3+length+2);
                individuals_table[i_m+3+length++] = AO.value/256;
                individuals_table[i_m+3+length++] = AO.value%256;
            }
            else
            {   full_object.pp[next_prop].ao[length/2] = AO;
                length = length + 2;
            }

        } while (TRUE);

        /*  People rarely do, but it is legal to declare a property without
            a value at all:

                with  name "fish", number, time_left;

            in which case the properties "number" and "time_left" are
            created as in effect variables and initialised to zero.          */

        if (length == 0)
        {   if (individual_property)
            {
                ensure_memory_list_available(&individuals_table_memlist, i_m+3+length+2);
                individuals_table[i_m+3+length++] = 0;
                individuals_table[i_m+3+length++] = 0;
            }
            else
            {
                INITAOTV(&full_object.pp[next_prop].ao[0], LONG_CONSTANT_OT, 0);
                length = 2;
            }
        }

        if (individual_property)
        {
            ensure_memory_list_available(&individuals_table_memlist, individuals_length+length+3);
            individuals_table[i_m + 2] = length;
            individuals_length += length+3;
            i_m = individuals_length;
        }
        else
            full_object.pp[next_prop].l = length/2;

        if ((token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   put_token_back(); return;
        }

    } while (TRUE);
}


static void properties_segment_g(int this_segment)
{
    /*  Parse through the "with" part of an object/class definition:

        <prop-1> <values...>, <prop-2> <values...>, ..., <prop-n> <values...>

        This routine also handles "private", with this_segment being equal
        to the token value for the introductory word ("private" or "with").  */


    int   i, next_prop,
          individual_property, this_identifier_number;
    int32 property_name_symbol, property_number, length;

    do
    {   get_next_token_with_directives();
        if ((token_type == SEGMENT_MARKER_TT)
            || (token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   put_token_back(); return;
        }

        if (token_type != SYMBOL_TT)
        {   ebf_curtoken_error("property name");
            return;
        }

        individual_property = (symbols[token_value].type != PROPERTY_T);

        if (individual_property)
        {   if (symbols[token_value].flags & UNKNOWN_SFLAG)
            {   this_identifier_number = no_individual_properties++;
                assign_symbol(token_value, this_identifier_number,
                    INDIVIDUAL_PROPERTY_T);

                if (debugfile_switch)
                {   debug_file_printf("<property>");
                    debug_file_printf
                        ("<identifier>%s</identifier>", token_text);
                    debug_file_printf
                        ("<value>%d</value>", this_identifier_number);
                    debug_file_printf("</property>");
                }

                trace_s(token_text, symbols[token_value].value, 2);
            }
            else
            {   if (symbols[token_value].type==INDIVIDUAL_PROPERTY_T)
                    this_identifier_number = symbols[token_value].value;
                else
                {   ebf_symbol_error("property name", token_text, typename(symbols[token_value].type), symbols[token_value].line);
                    return;
                }
            }

            if (def_t_s >= defined_this_segment_size)
                ensure_defined_this_segment(def_t_s*2);
            defined_this_segment[def_t_s++] = token_value;
            property_number = symbols[token_value].value;

            next_prop=full_object_g.numprops++;
            ensure_memory_list_available(&full_object_g.props_memlist, next_prop+1);
            full_object_g.props[next_prop].num = property_number;
            full_object_g.props[next_prop].flags = 
              ((this_segment == PRIVATE_SEGMENT) ? 1 : 0);
            full_object_g.props[next_prop].datastart = full_object_g.propdatasize;
            full_object_g.props[next_prop].continuation = 0;
            full_object_g.props[next_prop].datalen = 0;
        }
        else
        {   if (symbols[token_value].flags & UNKNOWN_SFLAG)
            {   error_named("No such property name as", token_text);
                return;
            }
            if (this_segment == PRIVATE_SEGMENT)
                error_named("Property should be declared in 'with', \
not 'private':", token_text);

            if (def_t_s >= defined_this_segment_size)
                ensure_defined_this_segment(def_t_s*2);
            defined_this_segment[def_t_s++] = token_value;
            property_number = symbols[token_value].value;

            next_prop=full_object_g.numprops++;
            ensure_memory_list_available(&full_object_g.props_memlist, next_prop+1);
            full_object_g.props[next_prop].num = property_number;
            full_object_g.props[next_prop].flags = 0;
            full_object_g.props[next_prop].datastart = full_object_g.propdatasize;
            full_object_g.props[next_prop].continuation = 0;
            full_object_g.props[next_prop].datalen = 0;
        }

        for (i=0; i<(def_t_s-1); i++)
            if (defined_this_segment[i] == token_value)
            {   error_named("Property given twice in the same declaration:",
                    symbols[token_value].name);
            }
            else
            if (symbols[defined_this_segment[i]].value == symbols[token_value].value)
            {
                error_fmt(
                    "Property given twice in the same declaration, because \
the names \"%s\" and \"%s\" actually refer to the same property",
                    symbols[defined_this_segment[i]].name,
                    symbols[token_value].name);
            }

        property_name_symbol = token_value;
        symbols[token_value].flags |= USED_SFLAG;

        length=0;
        do
        {   assembly_operand AO;
            get_next_token_with_directives();
            if ((token_type == EOF_TT)
                || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
                || ((token_type == SEP_TT) && (token_value == COMMA_SEP)))
                break;

            if (token_type == SEGMENT_MARKER_TT) { put_token_back(); break; }

            if ((!individual_property) && (property_number==1)
                && ((token_type != SQ_TT) || (strlen(token_text) <2 )) 
                && (token_type != DQ_TT)
                )
                warning ("'name' property should only contain dictionary words");

            if ((token_type == SEP_TT) && (token_value == OPEN_SQUARE_SEP))
            {
                char *prefix, *sep, *sym;
                sym = symbols[property_name_symbol].name;
                if (current_defn_is_class)
                {
                    prefix = symbols[current_classname_symbol].name;
                    sep = "::";
                }
                else
                {
                    prefix = current_object_name.data;
                    sep = ".";
                }
                ensure_memory_list_available(&embedded_function_name, strlen(prefix)+strlen(sep)+strlen(sym)+1);
                sprintf(embedded_function_name.data, "%s%s%s", prefix, sep, sym);

                INITAOT(&AO, CONSTANT_OT);
                /* parse_routine() releases lexer text! */
                AO.value = parse_routine(NULL, TRUE, embedded_function_name.data, FALSE, -1);
                AO.marker = IROUTINE_MV;

                directives.enabled = FALSE;
                segment_markers.enabled = TRUE;

                statements.enabled = FALSE;
                misc_keywords.enabled = FALSE;
                local_variables.enabled = FALSE;
                system_functions.enabled = FALSE;
                conditions.enabled = FALSE;
            }
            else

            /*  A special rule applies to values in double-quotes of the
                built-in property "name", which always has number 1: such
                property values are dictionary entries and not static
                strings                                                      */

            if ((!individual_property) &&
                (property_number==1) && (token_type == DQ_TT))
            {   AO.value = dictionary_add(token_text, 0x80, 0, 0);
                AO.type = CONSTANT_OT; 
                AO.marker = DWORD_MV;
            }
            else
            {   if (length!=0)
                {
                    if ((token_type == SYMBOL_TT)
                        && (symbols[token_value].type==PROPERTY_T))
                    {
                        /*  This is not necessarily an error: it's possible
                            to imagine a property whose value is a list
                            of other properties to look up, but far more
                            likely that a comma has been omitted in between
                            two property blocks                              */

                        warning_named(
               "Missing ','? Property data seems to contain the property name",
                            token_text);
                    }
                }

                /*  An ordinary value, then:                                 */

                put_token_back();
                AO = parse_expression(ARRAY_CONTEXT);
            }

            if (length == 32768) /* VENEER_CONSTRAINT_ON_PROP_TABLE_SIZE? */
            {   error_named("Limit (of 32768 values) exceeded for property",
                    symbols[property_name_symbol].name);
                break;
            }

            ensure_memory_list_available(&full_object_g.propdata_memlist, full_object_g.propdatasize+1);

            full_object_g.propdata[full_object_g.propdatasize++] = AO;
            length += 1;

        } while (TRUE);

        /*  People rarely do, but it is legal to declare a property without
            a value at all:

                with  name "fish", number, time_left;

            in which case the properties "number" and "time_left" are
            created as in effect variables and initialised to zero.          */

        if (length == 0)
        {
            assembly_operand AO;
            INITAOTV(&AO, CONSTANT_OT, 0);
            ensure_memory_list_available(&full_object_g.propdata_memlist, full_object_g.propdatasize+1);
            full_object_g.propdata[full_object_g.propdatasize++] = AO;
            length += 1;
        }

        full_object_g.props[next_prop].datalen = length;

        if ((token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   put_token_back(); return;
        }

    } while (TRUE);
}

static void properties_segment(int this_segment)
{
  if (!glulx_mode)
    properties_segment_z(this_segment);
  else
    properties_segment_g(this_segment);
}

/* ------------------------------------------------------------------------- */
/*   Attributes ("has") segment.                                             */
/* ------------------------------------------------------------------------- */

static void attributes_segment(void)
{
    /*  Parse through the "has" part of an object/class definition:

        [~]<attribute-1> [~]<attribute-2> ... [~]<attribute-n>               */

    int attribute_number, truth_state, bitmask;
    uchar *attrbyte;
    do
    {   truth_state = TRUE;

        ParseAttrN:

        get_next_token_with_directives();
        if ((token_type == SEGMENT_MARKER_TT)
            || (token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   if (!truth_state)
                ebf_curtoken_error("attribute name after '~'");
            put_token_back(); return;
        }
        if ((token_type == SEP_TT) && (token_value == COMMA_SEP)) return;

        if ((token_type == SEP_TT) && (token_value == ARTNOT_SEP))
        {   truth_state = !truth_state; goto ParseAttrN;
        }

        if ((token_type != SYMBOL_TT)
            || (symbols[token_value].type != ATTRIBUTE_T))
        {   ebf_curtoken_error("name of an already-declared attribute");
            return;
        }

        attribute_number = symbols[token_value].value;
        symbols[token_value].flags |= USED_SFLAG;

        if (!glulx_mode) {
            bitmask = (1 << (7-attribute_number%8));
            attrbyte = &(full_object.atts[attribute_number/8]);
        }
        else {
            /* In Glulx, my prejudices rule, and therefore bits are numbered
               from least to most significant. This is the opposite of the
               way the Z-machine works. */
            bitmask = (1 << (attribute_number%8));
            attrbyte = &(full_object_g.atts[attribute_number/8]);
        }

        if (truth_state)
            *attrbyte |= bitmask;     /* Set attribute bit */
        else
            *attrbyte &= ~bitmask;    /* Clear attribute bit */

    } while (TRUE);
}

/* ------------------------------------------------------------------------- */
/*   Classes ("class") segment.                                              */
/* ------------------------------------------------------------------------- */

static void add_class_to_inheritance_list(int class_number)
{
    int i;

    /*  The class number is actually the class's object number, which needs
        to be translated into its actual class number:                       */

    for (i=0;i<no_classes;i++)
        if (class_number == class_info[i].object_number)
        {   class_number = i+1;
            break;
        }

    /*  Remember the inheritance list so that property inheritance can
        be sorted out later on, when the definition has been finished:       */

    ensure_memory_list_available(&classes_to_inherit_from_memlist, no_classes_to_inherit_from+1);

    classes_to_inherit_from[no_classes_to_inherit_from++] = class_number;

    /*  Inheriting attributes from the class at once:                        */

    if (!glulx_mode) {
        for (i=0; i<6; i++)
            full_object.atts[i]
                |= properties_table[class_info[class_number-1].begins_at - 6 + i];
    }
    else {
        for (i=0; i<NUM_ATTR_BYTES; i++)
            full_object_g.atts[i]
                |= properties_table[class_info[class_number-1].begins_at 
                    - NUM_ATTR_BYTES + i];
    }
}

static void classes_segment(void)
{
    /*  Parse through the "class" part of an object/class definition:

        <class-1> ... <class-n>                                              */

    do
    {   get_next_token_with_directives();
        if ((token_type == SEGMENT_MARKER_TT)
            || (token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   put_token_back(); return;
        }
        if ((token_type == SEP_TT) && (token_value == COMMA_SEP)) return;

        if ((token_type != SYMBOL_TT)
            || (symbols[token_value].type != CLASS_T))
        {   ebf_curtoken_error("name of an already-declared class");
            return;
        }
        if (current_defn_is_class && token_value == current_classname_symbol)
        {   error("A class cannot inherit from itself");
            return;
        }

        symbols[token_value].flags |= USED_SFLAG;
        add_class_to_inheritance_list(symbols[token_value].value);
    } while (TRUE);
}

/* ------------------------------------------------------------------------- */
/*   Parse the body of a Nearby/Object/Class definition.                     */
/* ------------------------------------------------------------------------- */

static void parse_body_of_definition(void)
{   int commas_in_row;

    def_t_s = 0;

    do
    {   commas_in_row = -1;
        do
        {   get_next_token_with_directives(); commas_in_row++;
        } while ((token_type == SEP_TT) && (token_value == COMMA_SEP));

        if (commas_in_row>1)
            error("Two commas ',' in a row in object/class definition");

        if ((token_type == EOF_TT)
            || ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
        {   if (commas_in_row > 0)
                error("Object/class definition finishes with ','");
            if (token_type == EOF_TT)
                error("Object/class definition incomplete (no ';') at end of file");
            break;
        }

        if (token_type != SEGMENT_MARKER_TT)
        {   error_named("Expected 'with', 'has' or 'class' in \
object/class definition but found", token_text);
            break;
        }
        else
        switch(token_value)
        {   case WITH_SEGMENT:
                properties_segment(WITH_SEGMENT);
                break;
            case PRIVATE_SEGMENT:
                properties_segment(PRIVATE_SEGMENT);
                break;
            case HAS_SEGMENT:
                attributes_segment();
                break;
            case CLASS_SEGMENT:
                classes_segment();
                break;
        }

    } while (TRUE);

}

/* ------------------------------------------------------------------------- */
/*   Class directives:                                                       */
/*                                                                           */
/*        Class <name>  <body of definition>                                 */
/* ------------------------------------------------------------------------- */

static void initialise_full_object(void)
{
  int i;
  if (!glulx_mode) {
    full_object.symbol = 0;
    full_object.l = 0;
    full_object.atts[0] = 0;
    full_object.atts[1] = 0;
    full_object.atts[2] = 0;
    full_object.atts[3] = 0;
    full_object.atts[4] = 0;
    full_object.atts[5] = 0;
  }
  else {
    full_object_g.symbol = 0;
    full_object_g.numprops = 0;
    full_object_g.propdatasize = 0;
    for (i=0; i<NUM_ATTR_BYTES; i++)
      full_object_g.atts[i] = 0;
  }
}

extern void make_class(char * metaclass_name)
{   int n, duplicates_to_make = 0, class_number = no_objects+1,
        metaclass_flag = (metaclass_name != NULL);
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    current_defn_is_class = TRUE; no_classes_to_inherit_from = 0;
    individual_prop_table_size = 0;

    ensure_memory_list_available(&class_info_memlist, no_classes+1);

    if (no_classes==VENEER_CONSTRAINT_ON_CLASSES)
        fatalerror("Inform's maximum possible number of classes (whatever \
amount of memory is allocated) has been reached. If this causes serious \
inconvenience, please contact the maintainers.");

    directives.enabled = FALSE;

    if (metaclass_flag)
    {   token_text = metaclass_name;
        token_value = symbol_index(token_text, -1, NULL);
        token_type = SYMBOL_TT;
    }
    else
    {   get_next_token();
        if (token_type != SYMBOL_TT)
        {   discard_token_location(beginning_debug_location);
            ebf_curtoken_error("new class name");
            panic_mode_error_recovery();
            return;
        }
        if (!(symbols[token_value].flags & UNKNOWN_SFLAG))
        {   discard_token_location(beginning_debug_location);
            ebf_symbol_error("new class name", token_text, typename(symbols[token_value].type), symbols[token_value].line);
            panic_mode_error_recovery();
            return;
        }
    }

    /*  Each class also creates a modest object representing itself:         */

    ensure_memory_list_available(&shortname_buffer_memlist, strlen(token_text)+1);
    strcpy(shortname_buffer, token_text);

    assign_symbol(token_value, class_number, CLASS_T);
    current_classname_symbol = token_value;

    if (!glulx_mode) {
        if (metaclass_flag) symbols[token_value].flags |= SYSTEM_SFLAG;
    }
    else {
        /*  In Glulx, metaclasses have to be backpatched too! So we can't 
            mark it as "system", but we should mark it "used". */
        if (metaclass_flag) symbols[token_value].flags |= USED_SFLAG;
    }

    /*  "Class" (object 1) has no parent, whereas all other classes are
        the children of "Class".                                             */

    if (metaclass_flag) parent_of_this_obj = 0;
    else parent_of_this_obj = 1;

    class_info[no_classes].object_number = class_number;
    class_info[no_classes].symbol = current_classname_symbol;
    class_info[no_classes].begins_at = 0;

    initialise_full_object();

    /*  Give the class the (nameless in Inform syntax) "inheritance" property
        with value its own class number.  (This therefore accumulates onto
        the inheritance property of any object inheriting from the class,
        since property 2 is always set to "additive" -- see below)           */

    if (!glulx_mode) {
      full_object.symbol = current_classname_symbol;
      full_object.l = 1;
      full_object.pp[0].num = 2;
      full_object.pp[0].l = 1;
      INITAOTV(&full_object.pp[0].ao[0], LONG_CONSTANT_OT, no_objects + 1);
      full_object.pp[0].ao[0].marker = OBJECT_MV;
    }
    else {
      full_object_g.symbol = current_classname_symbol;
      full_object_g.numprops = 1;
      ensure_memory_list_available(&full_object_g.props_memlist, 1);
      full_object_g.props[0].num = 2;
      full_object_g.props[0].flags = 0;
      full_object_g.props[0].datastart = 0;
      full_object_g.props[0].continuation = 0;
      full_object_g.props[0].datalen = 1;
      full_object_g.propdatasize = 1;
      ensure_memory_list_available(&full_object_g.propdata_memlist, 1);
      INITAOTV(&full_object_g.propdata[0], CONSTANT_OT, no_objects + 1);
      full_object_g.propdata[0].marker = OBJECT_MV;
    }

    if (!metaclass_flag)
    {   get_next_token();
        if ((token_type == SEP_TT) && (token_value == OPENB_SEP))
        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            if (AO.marker != 0)
            {   error("Duplicate-number not known at compile time");
                n=0;
            }
            else
                n = AO.value;
            if ((n<0) || (n>10000))
            {   error("The number of duplicates must be 0 to 10000");
                n=0;
            }

            /*  Make one extra duplicate, since the veneer routines need
                always to keep an undamaged prototype for the class in stock */

            duplicates_to_make = n + 1;

            match_close_bracket();
        } else put_token_back();

        /*  Parse the body of the definition:                                */

        parse_body_of_definition();
    }

    if (debugfile_switch)
    {   debug_file_printf("<class>");
        debug_file_printf("<identifier>%s</identifier>", shortname_buffer);
        debug_file_printf("<class-number>%d</class-number>", no_classes);
        debug_file_printf("<value>");
        write_debug_object_backpatch(no_objects + 1);
        debug_file_printf("</value>");
        write_debug_locations
            (get_token_location_end(beginning_debug_location));
        debug_file_printf("</class>");
    }

    if (!glulx_mode)
      manufacture_object_z();
    else
      manufacture_object_g();

    if (individual_prop_table_size >= VENEER_CONSTRAINT_ON_IP_TABLE_SIZE)
        error("This class is too complex: it now carries too many properties. \
You may be able to get round this by declaring some of its property names as \
\"common properties\" using the 'Property' directive.");

    if (duplicates_to_make > 0)
    {
        int namelen = strlen(shortname_buffer);
        char *duplicate_name = my_malloc(namelen+16, "temporary storage for object duplicate names");
        strcpy(duplicate_name, shortname_buffer);
        for (n=1; (duplicates_to_make--) > 0; n++)
        {
            sprintf(duplicate_name+namelen, "_%d", n);
            make_object(FALSE, duplicate_name, class_number, class_number, -1);
        }
        my_free(&duplicate_name, "temporary storage for object duplicate names");
    }

    /* Finished building the class. */
    current_classname_symbol = 0;
}

/* ------------------------------------------------------------------------- */
/*   Object/Nearby directives:                                               */
/*                                                                           */
/*       Object  <name-1> ... <name-n> "short name"  [parent]  <body of def> */
/*                                                                           */
/*       Nearby  <name-1> ... <name-n> "short name"  <body of definition>    */
/* ------------------------------------------------------------------------- */

static int end_of_header(void)
{   if (((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
        || ((token_type == SEP_TT) && (token_value == COMMA_SEP))
        || (token_type == SEGMENT_MARKER_TT)) return TRUE;
    return FALSE;
}

extern void make_object(int nearby_flag,
    char *textual_name, int specified_parent, int specified_class,
    int instance_of)
{
    /*  Ordinarily this is called with nearby_flag TRUE for "Nearby",
        FALSE for "Object"; and textual_name NULL, specified_parent and
        specified_class both -1.  The next three arguments are used when
        the routine is called for class duplicates manufacture (see above).
        The last is used to create instances of a particular class.  */

    int i, tree_depth, internal_name_symbol = 0;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    directives.enabled = FALSE;

    ensure_memory_list_available(&current_object_name, 32);
    sprintf(current_object_name.data, "nameless_obj__%d", no_objects+1);

    current_defn_is_class = FALSE;

    no_classes_to_inherit_from=0;

    individual_prop_table_size = 0;

    if (nearby_flag) tree_depth=1; else tree_depth=0;

    if (specified_class != -1) goto HeaderPassed;

    get_next_token();

    /*  Read past and count a sequence of "->"s, if any are present          */

    if ((token_type == SEP_TT) && (token_value == ARROW_SEP))
    {   if (nearby_flag)
          error("The syntax '->' is only used as an alternative to 'Nearby'");

        while ((token_type == SEP_TT) && (token_value == ARROW_SEP))
        {   tree_depth++;
            get_next_token();
        }
    }

    ensure_memory_list_available(&shortname_buffer_memlist, 2);
    sprintf(shortname_buffer, "?");

    segment_markers.enabled = TRUE;

    /*  This first word is either an internal name, or a textual short name,
        or the end of the header part                                        */

    if (end_of_header()) goto HeaderPassed;

    if (token_type == DQ_TT) textual_name = token_text;
    else
    {   if (token_type != SYMBOL_TT) {
            ebf_curtoken_error("name for new object or its textual short name");
        }
        else if (!(symbols[token_value].flags & UNKNOWN_SFLAG)) {
            ebf_symbol_error("new object", token_text, typename(symbols[token_value].type), symbols[token_value].line);
        }
        else
        {   internal_name_symbol = token_value;
            ensure_memory_list_available(&current_object_name, strlen(token_text)+1);
            strcpy(current_object_name.data, token_text);
        }
    }

    /*  The next word is either a parent object, or
        a textual short name, or the end of the header part                  */

    get_next_token_with_directives();
    if (end_of_header()) goto HeaderPassed;

    if (token_type == DQ_TT)
    {   if (textual_name != NULL)
            error("Two textual short names given for only one object");
        else
            textual_name = token_text;
    }
    else
    {   if ((token_type != SYMBOL_TT)
            || (symbols[token_value].flags & UNKNOWN_SFLAG))
        {   if (textual_name == NULL)
                ebf_curtoken_error("parent object or the object's textual short name");
            else
                ebf_curtoken_error("parent object");
        }
        else goto SpecParent;
    }

    /*  Finally, it's possible that there is still a parent object           */

    get_next_token();
    if (end_of_header()) goto HeaderPassed;

    if (specified_parent != -1)
        ebf_curtoken_error("body of object definition");
    else
    {   SpecParent:
        if ((symbols[token_value].type == OBJECT_T)
            || (symbols[token_value].type == CLASS_T))
        {   specified_parent = symbols[token_value].value;
            symbols[token_value].flags |= USED_SFLAG;
        }
        else ebf_curtoken_error("name of (the parent) object");
    }

    /*  Now it really has to be the body of the definition.                  */

    get_next_token_with_directives();
    if (end_of_header()) goto HeaderPassed;

    ebf_curtoken_error("body of object definition");

    HeaderPassed:
    if (specified_class == -1) put_token_back();

    if (internal_name_symbol > 0)
        assign_symbol(internal_name_symbol, no_objects + 1, OBJECT_T);

    if (textual_name == NULL)
    {
        if (internal_name_symbol > 0) {
            ensure_memory_list_available(&shortname_buffer_memlist, strlen(symbols[internal_name_symbol].name)+4);
            sprintf(shortname_buffer, "(%s)",
                symbols[internal_name_symbol].name);
        }
        else {
            ensure_memory_list_available(&shortname_buffer_memlist, 32);
            sprintf(shortname_buffer, "(%d)", no_objects+1);
        }
    }
    else
    {
        if (!glulx_mode) {
            /* This check is only advisory. It's possible that a string of less than 765 characters will encode to more than 510 bytes. We'll double-check in write_property_block_z(). */
            if (strlen(textual_name)>765)
                error("Short name of object (in quotes) exceeded 765 Z-characters");
            ensure_memory_list_available(&shortname_buffer_memlist, 766);
            strncpy(shortname_buffer, textual_name, 765);
        }
        else {
            ensure_memory_list_available(&shortname_buffer_memlist, strlen(textual_name)+1);
            strcpy(shortname_buffer, textual_name);
        }
    }

    if (specified_parent != -1)
    {   if (tree_depth > 0)
            error("Use of '->' (or 'Nearby') clashes with giving a parent");
        parent_of_this_obj = specified_parent;
    }
    else
    {   parent_of_this_obj = 0;
        if (tree_depth>0)
        {
            /*  We have to set the parent object to the most recently defined
                object at level (tree_depth - 1) in the tree.

                A complication is that objects are numbered 1, 2, ... in the
                Z-machine (and in the objects[].parent, etc., fields) but
                0, 1, 2, ... internally (and as indices to object[]).        */

            for (i=no_objects-1; i>=0; i--)
            {   int j = i, k = 0;

                /*  Metaclass or class objects cannot be '->' parents:  */
                if (i<4)
                    continue;

                if (!glulx_mode) {
                    if (objectsz[i].parent == 1)
                        continue;
                    while (objectsz[j].parent != 0)
                    {   j = objectsz[j].parent - 1; k++; }
                }
                else {
                    if (objectsg[i].parent == 1)
                        continue;
                    while (objectsg[j].parent != 0)
                    {   j = objectsg[j].parent - 1; k++; }
                }

                if (k == tree_depth - 1)
                {   parent_of_this_obj = i+1;
                    break;
                }
            }
            if (parent_of_this_obj == 0)
            {   if (tree_depth == 1)
    error("'->' (or 'Nearby') fails because there is no previous object");
                else
    error("'-> -> ...' fails because no previous object is deep enough");
            }
        }
    }

    initialise_full_object();
    if (!glulx_mode)
        full_object.symbol = internal_name_symbol;
    else
        full_object_g.symbol = internal_name_symbol;

    if (instance_of != -1) add_class_to_inheritance_list(instance_of);

    if (specified_class == -1) parse_body_of_definition();
    else add_class_to_inheritance_list(specified_class);

    if (debugfile_switch)
    {   debug_file_printf("<object>");
        if (internal_name_symbol > 0)
        {   debug_file_printf("<identifier>%s</identifier>",
                 current_object_name.data);
        } else
        {   debug_file_printf
                ("<identifier artificial=\"true\">%s</identifier>",
                 current_object_name.data);
        }
        debug_file_printf("<value>");
        write_debug_object_backpatch(no_objects + 1);
        debug_file_printf("</value>");
        write_debug_locations
            (get_token_location_end(beginning_debug_location));
        debug_file_printf("</object>");
    }

    if (!glulx_mode)
      manufacture_object_z();
    else
      manufacture_object_g();
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_objects_vars(void)
{
    properties_table = NULL;
    individuals_table = NULL;
    commonprops = NULL;
    shortname_buffer = NULL;
    
    objectsz = NULL;
    objectsg = NULL;
    objectatts = NULL;
    classes_to_inherit_from = NULL;
    class_info = NULL;

    full_object_g.props = NULL;    
    full_object_g.propdata = NULL;    
}

extern void objects_begin_pass(void)
{
    properties_table_size=0;

    /* The three predefined common properties: */
    /* (Entry 0 is not used.) */

    /* "name" */
    commonprops[1].default_value = 0;
    commonprops[1].is_long = TRUE;
    commonprops[1].is_additive = TRUE;

    /* class inheritance property */
    commonprops[2].default_value = 0;
    commonprops[2].is_long = TRUE;
    commonprops[2].is_additive = TRUE;

    /* instance variables table address */
    /* (This property is only meaningful in Z-code; in Glulx its entry is
       reserved but never used.) */
    commonprops[3].default_value = 0;
    commonprops[3].is_long = TRUE;
    commonprops[3].is_additive = FALSE;
                                         
    no_properties = 4;

    if (debugfile_switch)
    {
        /* These two properties are not symbols, so they won't be emitted
           by emit_debug_information_for_predefined_symbol(). Do it
           manually. */
        debug_file_printf("<property>");
        debug_file_printf
            ("<identifier artificial=\"true\">inheritance class</identifier>");
        debug_file_printf("<value>2</value>");
        debug_file_printf("</property>");
        debug_file_printf("<property>");
        debug_file_printf
            ("<identifier artificial=\"true\">instance variables table address "
             "(Z-code)</identifier>");
        debug_file_printf("<value>3</value>");
        debug_file_printf("</property>");
    }

    if (define_INFIX_switch) no_attributes = 1;
    else no_attributes = 0;

    no_objects = 0;
    /* Setting the info for object zero is probably a relic of very old code, but we do it. */
    if (!glulx_mode) {
        ensure_memory_list_available(&objectsz_memlist, 1);
        objectsz[0].parent = 0; objectsz[0].child = 0; objectsz[0].next = 0;
        no_individual_properties=72;
    }
    else {
        ensure_memory_list_available(&objectsg_memlist, 1);
        objectsg[0].parent = 0; objectsg[0].child = 0; objectsg[0].next = 0;
        no_individual_properties = INDIV_PROP_START+8;
    }
    no_classes = 0;
    current_classname_symbol = 0;

    no_embedded_routines = 0;

    individuals_length=0;
}

extern void objects_allocate_arrays(void)
{
    objectsz = NULL;
    objectsg = NULL;
    objectatts = NULL;

    commonprops = my_calloc(sizeof(commonpropinfo), INDIV_PROP_START,
                                "common property info");

    initialise_memory_list(&class_info_memlist,
        sizeof(classinfo), 64, (void**)&class_info,
        "class info");
    initialise_memory_list(&classes_to_inherit_from_memlist,
        sizeof(int),       64, (void**)&classes_to_inherit_from,
        "inherited classes list");

    initialise_memory_list(&properties_table_memlist,
        sizeof(uchar), 10000, (void**)&properties_table,
        "properties table");
    initialise_memory_list(&individuals_table_memlist,
        sizeof(uchar), 10000, (void**)&individuals_table,
        "individual properties table");

    defined_this_segment_size = 128;
    defined_this_segment  = my_calloc(sizeof(int), defined_this_segment_size,
                                "defined this segment table");

    initialise_memory_list(&current_object_name,
        sizeof(char), 32, NULL,
        "object name currently being defined");
    initialise_memory_list(&shortname_buffer_memlist,
        sizeof(char), 768, (void**)&shortname_buffer,
        "textual name of object currently being defined");
    initialise_memory_list(&embedded_function_name,
        sizeof(char), 32, NULL,
        "temporary storage for inline function name");
    
    if (!glulx_mode) {
      initialise_memory_list(&objectsz_memlist,
          sizeof(objecttz), 256, (void**)&objectsz,
          "z-objects");
    }
    else {
      initialise_memory_list(&objectsg_memlist,
          sizeof(objecttg), 256, (void**)&objectsg,
          "g-objects");
      initialise_memory_list(&objectatts_memlist,
          NUM_ATTR_BYTES, 256, (void**)&objectatts,
          "g-attributes");
      initialise_memory_list(&full_object_g.props_memlist,
          sizeof(propg), 64, (void**)&full_object_g.props,
          "object property list");
      initialise_memory_list(&full_object_g.propdata_memlist,
          sizeof(assembly_operand), 1024, (void**)&full_object_g.propdata,
          "object property data table");
    }
}

extern void objects_free_arrays(void)
{
    my_free(&commonprops, "common property info");
    
    deallocate_memory_list(&current_object_name);
    deallocate_memory_list(&shortname_buffer_memlist);
    deallocate_memory_list(&embedded_function_name);
    deallocate_memory_list(&objectsz_memlist);
    deallocate_memory_list(&objectsg_memlist);
    deallocate_memory_list(&objectatts_memlist);
    deallocate_memory_list(&class_info_memlist);
    deallocate_memory_list(&classes_to_inherit_from_memlist);

    deallocate_memory_list(&properties_table_memlist);
    deallocate_memory_list(&individuals_table_memlist);

    my_free(&defined_this_segment,"defined this segment table");

    if (!glulx_mode) {
        deallocate_memory_list(&full_object_g.props_memlist);
        deallocate_memory_list(&full_object_g.propdata_memlist);
    }
    
}

/* ========================================================================= */
