/* ------------------------------------------------------------------------- */
/*   "verbs" :  Manages actions and grammar tables; parses the directives    */
/*              Verb and Extend.                                             */
/*                                                                           */
/*   Part of Inform 6.43                                                     */
/*   copyright (c) Graham Nelson 1993 - 2024                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

/* ------------------------------------------------------------------------- */
/*   Grammar version.                                                        */
/* ------------------------------------------------------------------------- */
/* The grammar version is handled in a somewhat messy way. It can be:
     1 for pre-Inform 6.06 table format
     2 for modern Inform format
     
   The default is 1 for Z-code (for backwards compatibility), 2 for Glulx.
   This can be altered by the $GRAMMAR_VERSION compiler setting, and
   then altered again during compilation by a "Constant Grammar__Version"
   directive. (Note double underscore.)

   Typically the library has a "Constant Grammar__Version 2;" line to
   ensure we get the modern version for both VMs.

   (Note also the $GRAMMAR_META_FLAG setting, which lets us indicate
   which actions are meta, rather than relying on dict word flags.)
 */
int grammar_version_number;
int32 grammar_version_symbol;          /* Index of "Grammar__Version"
                                          within symbols table               */

/* ------------------------------------------------------------------------- */
/*   Actions.                                                                */
/* ------------------------------------------------------------------------- */
/*   Array defined below:                                                    */
/*                                                                           */
/*    actioninfo actions[n]               Symbol table index and byte offset */
/*                                        of the ...Sub routine              */
/*                                                                           */
/*   If GRAMMAR_META_FLAG is set, we need to reorder actions[] to put meta   */
/*   actions at the top. We don't try to sort the table in place, though.    */
/*   We just create this two-way index remapping table:                      */
/*                                                                           */
/*    actionsort sorted_actions[]         Table mapping internal action      */
/*                                        indexes to final action indexes    */
/* ------------------------------------------------------------------------- */

int no_actions,                        /* Number of actions made so far      */
    no_fake_actions;                   /* Number of fake actions made so far */

/* ------------------------------------------------------------------------- */
/*   Adjectives.  (The term "adjective" is traditional; they are mainly      */
/*                prepositions, such as "onto".)                             */
/* ------------------------------------------------------------------------- */
/*   Arrays defined below:                                                   */
/*                                                                           */
/*    int32 adjectives[n]                 Byte address of dictionary entry   */
/*                                        for the nth adjective              */
/*    dict_word adjective_sort_code[n]    Dictionary sort code of nth adj    */
/* ------------------------------------------------------------------------- */

int no_adjectives;                     /* Number of adjectives made so far   */

/* ------------------------------------------------------------------------- */
/*   Verbs.  Note that Inform-verbs are not quite the same as English verbs: */
/*           for example the English verbs "take" and "drop" both normally   */
/*           correspond in a game's dictionary to the same Inform verb.  An  */
/*           Inform verb (I-verb) is essentially a list of grammar lines.    */
/*           An English verb (E-verb, although of course it might not be     */
/*           English!) is a dict word which is known to be a verb.           */
/*           Each E-verb's #dict_par2 field contains the I-verb index that   */
/*           it corresponds to.                                              */
/* ------------------------------------------------------------------------- */
/*   Arrays defined below:                                                   */
/*                                                                           */
/*    verbt Inform_verbs[n]               The n-th grammar line sequence:    */
/*                                        see "header.h" for the definition  */
/*                                        of the typedef struct verbt        */
/*    int32 grammar_token_routine[n]      The byte offset from start of code */
/*                                        area of the n-th one               */
/* ------------------------------------------------------------------------- */

int no_Inform_verbs,                   /* Number of Inform-verbs made so far */
    no_grammar_token_routines;         /* Number of routines given in tokens */

/* ------------------------------------------------------------------------- */
/*   We keep a list of English verb-words known (e.g. "take" or "eat") and   */
/*   which Inform-verbs they correspond to.  (This list is needed for some   */
/*   of the grammar extension operations.)                                   */
/* ------------------------------------------------------------------------- */

typedef struct English_verb_s {
    int textpos;  /* in English_verbs_text */
    int dictword; /* dict word accession num */
    int verbnum;  /* in Inform_verbs */
} English_verb_t;

static English_verb_t *English_verbs;
static memory_list English_verbs_memlist;
static int English_verbs_count;

static char *English_verbs_text;     /* Allocated to English_verbs_text_size */
static memory_list English_verbs_text_memlist;
static int English_verbs_text_size;

/* ------------------------------------------------------------------------- */
/*   Arrays used by this file                                                */
/* ------------------------------------------------------------------------- */

  verbt   *Inform_verbs;  /* Allocated up to no_Inform_verbs */
  static memory_list Inform_verbs_memlist;
  uchar   *grammar_lines; /* Allocated to grammar_lines_top */
  static memory_list grammar_lines_memlist;
  int32    grammar_lines_top;
  int      no_grammar_lines, no_grammar_tokens;

  actioninfo *actions; /* Allocated to no_actions */
  memory_list actions_memlist;
  int32   *grammar_token_routine; /* Allocated to no_grammar_token_routines */
  static memory_list grammar_token_routine_memlist;
  actionsort *sorted_actions; /* only used if GRAMMAR_META_FLAG */
  int no_meta_actions; /* only used if GRAMMAR_META_FLAG */

  int32   *adjectives; /* Allocated to no_adjectives */
  static memory_list adjectives_memlist;

  static uchar *adjective_sort_code; /* Allocated to no_adjectives*DICT_WORD_BYTES, except it's sometimes no_adjectives+1 because we can bump it tentatively */
  static memory_list adjective_sort_code_memlist;

  static memory_list action_symname_memlist; /* Used for temporary symbols */

/* ------------------------------------------------------------------------- */
/*   Grammar version                                                         */
/* ------------------------------------------------------------------------- */

/* Set grammar_version_number, or report an error if the number is not
   valid for the current VM. */
void set_grammar_version(int val)
{
    if (!glulx_mode) {
        if (val != 1 && val != 2 && val != 3) {
            error("Z-code only supports grammar version 1, 2, or 3.");
            return;
        }
    }
    else {
        if (val != 2) {
            error("Glulx only supports grammar version 2.");
            return;
        }
    }
    
    grammar_version_number = val;
    /* We also have to adjust the symbol value. */
    symbols[grammar_version_symbol].value = val;
}

/* ------------------------------------------------------------------------- */
/*   Tracing for compiler maintenance                                        */
/* ------------------------------------------------------------------------- */

static void print_verbs_by_number(int num);

static void list_grammar_line_v1(int mark)
{
    int action, actsym;
    int ix, len;
    char *str;

    /* There is no GV1 for Glulx. */
    if (glulx_mode)
        return;
    
    action = (grammar_lines[mark] << 8) | (grammar_lines[mark+1]);
    mark += 2;
    
    printf("  *");
    while (grammar_lines[mark] != 15) {
        uchar tok = grammar_lines[mark];
        mark += 3;
        
        switch (tok) {
        case 0:
            printf(" noun");
            break;
        case 1:
            printf(" held");
            break;
        case 2:
            printf(" multi");
            break;
        case 3:
            printf(" multiheld");
            break;
        case 4:
            printf(" multiexcept");
            break;
        case 5:
            printf(" multiinside");
            break;
        case 6:
            printf(" creature");
            break;
        case 7:
            printf(" special");
            break;
        case 8:
            printf(" number");
            break;
        default:
            if (tok >= 16 && tok < 48) {
                printf(" noun=%d", tok-16);
            }
            else if (tok >= 48 && tok < 80) {
                printf(" routine=%d", tok-48);
            }
            else if (tok >= 80 && tok < 128) {
                printf(" scope=%d", tok-80);
            }
            else if (tok >= 128 && tok < 160) {
                printf(" attr=%d", tok-128);
            }
            else if (tok >= 160) {
                printf(" prep=%d", tok);
            }
            else {
                printf(" ???");
            }
        }
    }

    printf(" -> ");
    actsym = actions[action].symbol;
    str = (symbols[actsym].name);
    len = strlen(str) - 3;   /* remove "__A" */
    for (ix=0; ix<len; ix++) putchar(str[ix]);
    if (actions[action].meta) printf(" (meta)");
    printf("\n");
}

static void list_grammar_line_v2(int mark)
{
    int action, flags, actsym;
    int ix, len;
    char *str;
    
    if (!glulx_mode) {
        action = (grammar_lines[mark] << 8) | (grammar_lines[mark+1]);
        flags = (action & 0x400);
        action &= 0x3FF;
        mark += 2;
    }
    else {
        action = (grammar_lines[mark] << 8) | (grammar_lines[mark+1]);
        mark += 2;
        flags = grammar_lines[mark++];
    }
    
    printf("  *");
    while (grammar_lines[mark] != 15) {
        int toktype, tokdat, tokalt;
        if (!glulx_mode) {
            toktype = grammar_lines[mark] & 0x0F;
            tokalt = (grammar_lines[mark] >> 4) & 0x03;
            mark += 1;
            tokdat = (grammar_lines[mark] << 8) | (grammar_lines[mark+1]);
            mark += 2;
        }
        else {
            toktype = grammar_lines[mark] & 0x0F;
            tokalt = (grammar_lines[mark] >> 4) & 0x03;
            mark += 1;
            tokdat = (grammar_lines[mark] << 24) | (grammar_lines[mark+1] << 16) | (grammar_lines[mark+2] << 8) | (grammar_lines[mark+3]);
            mark += 4;
        }

        if (tokalt == 3 || tokalt == 1)
            printf(" /");
                
        switch (toktype) {
        case 1:
            switch (tokdat) {
            case 0: printf(" noun"); break;
            case 1: printf(" held"); break;
            case 2: printf(" multi"); break;
            case 3: printf(" multiheld"); break;
            case 4: printf(" multiexcept"); break;
            case 5: printf(" multiinside"); break;
            case 6: printf(" creature"); break;
            case 7: printf(" special"); break;
            case 8: printf(" number"); break;
            case 9: printf(" topic"); break;
            default: printf(" ???"); break;
            }
            break;
        case 2:
            printf(" '");
            print_dict_word(tokdat);
            printf("'");
            break;
        case 3:
            printf(" noun=%d", tokdat);
            break;
        case 4:
            printf(" attr=%d", tokdat);
            break;
        case 5:
            printf(" scope=%d", tokdat);
            break;
        case 6:
            printf(" routine=%d", tokdat);
            break;
        default:
            printf(" ???%d:%d", toktype, tokdat);
            break;
        }
    }
    printf(" -> ");
    actsym = actions[action].symbol;
    str = (symbols[actsym].name);
    len = strlen(str) - 3;   /* remove "__A" */
    for (ix=0; ix<len; ix++) putchar(str[ix]);
    if (actions[action].meta) printf(" (meta)");
    if (flags) printf(" (reversed)");
    printf("\n");
}

static void list_grammar_line_v3(int mark)
{
    int action, flags, actsym, tokcount;
    int ix, len, tx;
    char *str;
    
    /* There is no GV3 for Glulx. */
    if (glulx_mode)
        return;
    
    action = (grammar_lines[mark] << 8) | (grammar_lines[mark+1]);
    flags = (action & 0x400);
    tokcount = (action >> 11) & 0x1F;
    action &= 0x3FF;
    mark += 2;
    
    printf("  *");
    for (tx=0; tx<tokcount; tx++) {
        int toktype, tokdat, tokalt;
        toktype = grammar_lines[mark] & 0x0F;
        tokalt = (grammar_lines[mark] >> 4) & 0x03;
        mark += 1;
        tokdat = grammar_lines[mark];
        mark += 1;

        if (tokalt == 3 || tokalt == 1)
            printf(" /");
                
        switch (toktype) {
        case 1:
            switch (tokdat) {
            case 0: printf(" noun"); break;
            case 1: printf(" held"); break;
            case 2: printf(" multi"); break;
            case 3: printf(" multiheld"); break;
            case 4: printf(" multiexcept"); break;
            case 5: printf(" multiinside"); break;
            case 6: printf(" creature"); break;
            case 7: printf(" special"); break;
            case 8: printf(" number"); break;
            case 9: printf(" topic"); break;
            default: printf(" ???"); break;
            }
            break;
        case 2:
            printf(" '");
            print_dict_word(adjectives[tokdat]);
            printf("'");
            break;
        case 3:
            printf(" noun=%d", tokdat);
            break;
        case 4:
            printf(" attr=%d", tokdat);
            break;
        case 5:
            printf(" scope=%d", tokdat);
            break;
        case 6:
            printf(" routine=%d", tokdat);
            break;
        default:
            printf(" ???%d:%d", toktype, tokdat);
            break;
        }
    }
    printf(" -> ");
    actsym = actions[action].symbol;
    str = (symbols[actsym].name);
    len = strlen(str) - 3;   /* remove "__A" */
    for (ix=0; ix<len; ix++) putchar(str[ix]);
    if (actions[action].meta) printf(" (meta)");
    if (flags) printf(" (reversed)");
    printf("\n");
}

extern void list_verb_table(void)
{
    int verb, lx;
    printf("Grammar table: %d verbs\n", no_Inform_verbs);
    for (verb=0; verb<no_Inform_verbs; verb++) {
        printf("Verb");
        print_verbs_by_number(verb);
        printf("\n");
        for (lx=0; lx<Inform_verbs[verb].lines; lx++) {
            int mark = Inform_verbs[verb].l[lx];
            switch (grammar_version_number) {
            case 1:
                list_grammar_line_v1(mark);
                break;
            case 2:
                list_grammar_line_v2(mark);
                break;
            case 3:
                list_grammar_line_v3(mark);
                break;
            }
        }
    }
}

extern void list_action_table(void)
{
    int ix;
    printf("Action table: %d actions, %d fake actions\n", no_actions, no_fake_actions);
    for (ix=0; ix<no_actions; ix++) {
        int internal = ix;
        if (sorted_actions)
            internal = sorted_actions[ix].external_to_int;
        printf("%d: %s", ix, symbols[actions[internal].symbol].name);
        if (actions[internal].meta)
            printf(" (meta)");
        if (sorted_actions)
            printf(" (originally numbered %d)", internal);
        printf("\n");
    }
    /* Fake action names don't get recorded anywhere, so we can't list
       them. */
}

/* ------------------------------------------------------------------------- */
/*   Actions.                                                                */
/* ------------------------------------------------------------------------- */

static void new_action(char *b, int c)
{
    /*  Called whenever a new action (or fake action) is created (either
        by using make_action above, or the Fake_Action directive).
        At present just a hook for some tracing code.                        */

    if (printactions_switch > 1)
        printf("%s: Action '%s' is numbered %d\n", current_location_text(), b, c);
}

/* Note that fake actions are numbered from a high base point upwards;
   real actions are numbered from 0 upward in GV2/3.                         */

extern int lowest_fake_action(void)
{
    if (grammar_version_number == 1)
        return 256;
    else if (grammar_version_number == 2)
        return 4096;
    else if (grammar_version_number == 3)
        return 4096;
    compiler_error("invalid grammar version");
    return 0;
}

extern void make_fake_action(void)
{   char *action_sub;
    int i;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    get_next_token();
    if (token_type != SYMBOL_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_curtoken_error("new fake action name");
        panic_mode_error_recovery(); return;
    }

    /* Enough space for "token__A". */
    ensure_memory_list_available(&action_symname_memlist, strlen(token_text)+4);
    action_sub = action_symname_memlist.data;
    strcpy(action_sub, token_text);
    strcat(action_sub, "__A");
    
    /* Action symbols (including fake_actions) may collide with other kinds of symbols. So we don't check that. */

    i = symbol_index(action_sub, -1, NULL);

    if (!(symbols[i].flags & UNKNOWN_SFLAG))
    {   discard_token_location(beginning_debug_location);
        /* The user didn't know they were defining FOO__A, but they were and it's a problem. */
        ebf_symbol_error("new fake action name", action_sub, typename(symbols[i].type), symbols[i].line);
        panic_mode_error_recovery(); return;
    }

    assign_symbol(i, lowest_fake_action()+no_fake_actions++,
        FAKE_ACTION_T);

    new_action(token_text, i);

    if (debugfile_switch)
    {   debug_file_printf("<fake-action>");
        debug_file_printf("<identifier>##%s</identifier>", token_text);
        debug_file_printf("<value>%d</value>", symbols[i].value);
        get_next_token();
        write_debug_locations
            (get_token_location_end(beginning_debug_location));
        put_token_back();
        debug_file_printf("</fake-action>");
    }

    return;
}

extern assembly_operand action_of_name(char *name)
{
    /*  Returns the action number of the given name, creating it as a new
        action name if it isn't already known as such.                       */

    char *action_sub;
    int j;
    assembly_operand AO;

    /* Enough space for "name__A". */
    ensure_memory_list_available(&action_symname_memlist, strlen(name)+4);
    action_sub = action_symname_memlist.data;
    strcpy(action_sub, name);
    strcat(action_sub, "__A");
    
    j = symbol_index(action_sub, -1, NULL);

    if (symbols[j].type == FAKE_ACTION_T)
    {   INITAO(&AO);
        AO.value = symbols[j].value;
        if (!glulx_mode)
          AO.type = LONG_CONSTANT_OT;
        else
          set_constant_ot(&AO);
        symbols[j].flags |= USED_SFLAG;
        return AO;
    }

    if (symbols[j].flags & UNKNOWN_SFLAG)
    {
        if (no_actions >= lowest_fake_action()) {
            if (grammar_version_number == 1) {
                error_named("Cannot create action (grammar version 1 is limited to 256):", name);
            }
            else {
                /* Note that we'll never reach this limit in Z-code (see below), but it still applies in Glulx because we run into the fake action values. */
                error_named("Cannot create action (grammar is limited to 4096):", name);
            }
            INITAO(&AO);
            return AO;
        }
        if (!glulx_mode && no_actions >= 1024) {
            /* Z grammar tokens store the action number in a 10-bit field, so we have this additional limit. */
            error_named("Cannot create action (Z-machine grammar is limited to 1024):", name);
            INITAO(&AO);
            return AO;
        }

        ensure_memory_list_available(&actions_memlist, no_actions+1);
        new_action(name, no_actions);
        actions[no_actions].symbol = j;
        actions[no_actions].meta = FALSE;
        actions[no_actions].byte_offset = 0; /* fill in later */
        assign_symbol(j, no_actions++, CONSTANT_T);
        symbols[j].flags |= ACTION_SFLAG;
    }
    symbols[j].flags |= USED_SFLAG;

    INITAO(&AO);
    AO.value = symbols[j].value;
    AO.marker = ACTION_MV;
    if (!glulx_mode) {
      AO.type = SHORT_CONSTANT_OT;
      if (symbols[j].value >= 256) AO.type = LONG_CONSTANT_OT;
    }
    else {
      AO.type = CONSTANT_OT;
    }
    return AO;
}

extern void find_the_actions(void)
{   int i; int32 j;

    for (i=0; i<no_actions; i++)
    {
        /* The name looks like "action__A". We're going to convert that to
           "actionSub". Allocate enough space for both. */
        int namelen = strlen(symbols[actions[i].symbol].name);
        char *action_sub, *action_name;
        ensure_memory_list_available(&action_symname_memlist, 2*(namelen+1));
        action_sub = action_symname_memlist.data;
        action_name = (char *)action_symname_memlist.data + (namelen+1);
        
        strcpy(action_name, symbols[actions[i].symbol].name);
        action_name[namelen - 3] = '\0'; /* remove "__A" */
        strcpy(action_sub, action_name);
        strcat(action_sub, "Sub");
        j = symbol_index(action_sub, -1, NULL);
        if (symbols[j].flags & UNKNOWN_SFLAG)
        {
            error_named_at("No ...Sub action routine found for action:", action_name, symbols[actions[i].symbol].line);
        }
        else if (symbols[j].type != ROUTINE_T)
        {
            ebf_symbol_error("action's ...Sub routine", action_sub, typename(symbols[j].type), symbols[j].line);
        }
        else
        {   actions[i].byte_offset = symbols[j].value;
            symbols[j].flags |= USED_SFLAG;
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Adjectives.                                                             */
/* ------------------------------------------------------------------------- */

static int make_adjective_v1(char *English_word)
{
    /*  Returns adjective number of the English word supplied, creating
        a new adjective number if need be.

        Note that (partly for historical reasons) adjectives are numbered
        from 0xff downwards.  (And partly to make them stand out as tokens.)

        This routine is used only in grammar version 1: the corresponding
        table is left empty in GV2. For GV3, see below.                      */

    uchar *new_sort_code;
    int i; 

    if (no_adjectives >= 255) {
        error("Grammar version 1 cannot support more than 255 prepositions");
        return 0;
    }
    if (ZCODE_LESS_DICT_DATA && !glulx_mode) {
        /* We need to use #dict_par3 for the preposition number. */
        error("Grammar version 1 cannot be used with ZCODE_LESS_DICT_DATA");
        return 0;
    }

    /* Allocate the extra space even though we might not need it. We'll use
       the prospective new adjective_sort_code slot as a workspace. */
    ensure_memory_list_available(&adjectives_memlist, no_adjectives+1);
    ensure_memory_list_available(&adjective_sort_code_memlist, (no_adjectives+1) * DICT_WORD_BYTES);

    new_sort_code = adjective_sort_code+no_adjectives*DICT_WORD_BYTES;
    dictionary_prepare(English_word, new_sort_code);
    for (i=0; i<no_adjectives; i++)
        if (compare_sorts(new_sort_code,
          adjective_sort_code+i*DICT_WORD_BYTES) == 0)
            return(0xff-i);
    adjectives[no_adjectives]
        = dictionary_add(English_word,PREP_DFLAG,0,0xff-no_adjectives);
    return(0xff-no_adjectives++);
}

static int make_adjective_v3(char* English_word)
{
    /*  Returns adjective number of the English word supplied, creating
        a new adjective number if need be.

        Adjectives are numbered from 0 upwards.
 
        This routine is used only in grammar version 3.
    */

    int l;
    int32 dict_address;

    if (no_adjectives >= 255) {
        error("Grammar version 3 cannot support more than 255 prepositions");
        return 0;
    }

    dict_address = dictionary_add(English_word, PREP_DFLAG, 0, 0);
    for (l = 0; l < no_adjectives; l++)
        if (adjectives[l] == dict_address)
            return l;

    ensure_memory_list_available(&adjectives_memlist, no_adjectives + 1);

    adjectives[no_adjectives] = dict_address;
    return(no_adjectives++);
}


/* ------------------------------------------------------------------------- */
/*   Parsing routines.                                                       */
/* ------------------------------------------------------------------------- */

static int make_parsing_routine(int32 routine_address)
{
    /*  This routine is used only in grammar version 1 and 3: the
        corresponding table is left empty in GV2.                            */

    int l;
    for (l=0; l<no_grammar_token_routines; l++)
        if (grammar_token_routine[l] == routine_address)
            return l;

    ensure_memory_list_available(&grammar_token_routine_memlist, no_grammar_token_routines+1);
    
    grammar_token_routine[no_grammar_token_routines] = routine_address;
    return(no_grammar_token_routines++);
}

/* ------------------------------------------------------------------------- */
/*   The English-verb list.                                                  */
/* ------------------------------------------------------------------------- */

static int find_verb_entry(int dictword)
{
    /*  Returns the English-verb index which matches the given dict word,
     *  or -1 if not found. */
    int ix;
    for (ix=0; ix<English_verbs_count; ix++) {
        if (English_verbs[ix].dictword == dictword) {
            return ix;
        }
    }
    return -1;
}

static int renumber_verb(int dictword, int new_number)
{
    /*  Renumbers the Inform-verb number which English_verb matches in
     *  English_verbs to account for the case when we are
     *  extending a verb. Returns 0 if successful, or -1 if the given
     *  verb is not in the dictionary (which shouldn't happen as
     *  get_existing_verb() has already run). */
    int ix;
    for (ix=0; ix<English_verbs_count; ix++) {
        if (English_verbs[ix].dictword == dictword) {
            English_verbs[ix].verbnum = new_number;
            return 0;
        }
    }
    return(-1);
}

static void print_verbs_by_number(int num)
{
    /*  Print all English verb strings with the given verb number. */
    int ix;
    int count = 0;
    for (ix=0; ix<English_verbs_count; ix++) {
        if (English_verbs[ix].verbnum == num) {
            char *str = English_verbs[ix].textpos + English_verbs_text;
            printf(" '%s'", str);
            count++;
        }
    }
    if (!count)
        printf(" <none>");
}

static int get_existing_verb(int *dictref)
{
    /*  Look at the last-read token: if it's the name of an English verb
        understood by Inform, in double-quotes, then return the Inform-verb
        that word refers to: otherwise give an error and return -1.
        Optionally also return the dictionary word index in dictref.
    */

    int j, evnum, dictword;

    if (dictref)
        *dictref = -1;

    if ((token_type != DQ_TT) && (token_type != SQ_TT)) {
        ebf_curtoken_error("an English verb in quotes");
        return -1;
    }

    dictword = dictionary_find(token_text);
    if (dictword < 0) {
        error_named("There is no previous grammar for the verb",
            token_text);
        return -1;
    }
    
    evnum = find_verb_entry(dictword);
    j = (evnum < 0) ? -1 : English_verbs[evnum].verbnum;
    if (j < 0) {
        error_named("There is no previous grammar for the verb",
            token_text);
        return -1;
    }
    
    if (dictref)
        *dictref = dictword;
    return j;
}

void locate_dead_grammar_lines()
{
    /* Run through the grammar table and check whether each entry is
       associated with a verb word. (Some might have been detached by
       "Extend only".)
    */
    int verb;
    int ix;

    for (verb=0; verb<no_Inform_verbs; verb++) {
        Inform_verbs[verb].used = FALSE;
    }
    
    for (ix=0; ix<English_verbs_count; ix++) {
        verb = English_verbs[ix].verbnum;
        if (verb < 0 || verb >= no_Inform_verbs) {
            char *str = English_verbs[ix].textpos + English_verbs_text;
            error_named("An entry in the English verb list had an invalid verb number", str);
        }
        else {
            Inform_verbs[verb].used = TRUE;
        }
    }

    for (verb=0; verb<no_Inform_verbs; verb++) {
        if (!Inform_verbs[verb].used) {
            warning_at("Verb declaration no longer has any verbs associated. Use \"Extend replace\" instead of \"Extend only\"?", Inform_verbs[verb].line);
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Grammar lines for Verb/Extend directives.                               */
/* ------------------------------------------------------------------------- */

static void ensure_grammar_lines_available(int verbnum, int num)
{
    /* Note that the size field always starts positive. */
    if (num > Inform_verbs[verbnum].size) {
        int newsize = 2*num+4;
        my_realloc(&Inform_verbs[verbnum].l, sizeof(int) * Inform_verbs[verbnum].size, sizeof(int) * newsize, "grammar lines for one verb");
        Inform_verbs[verbnum].size = newsize;
    }
}

static int grammar_line(int verbnum, int allmeta, int line)
{
    /*  Parse a grammar line, to be written into grammar_lines[] starting
        at grammar_lines_top. grammar_lines_top is left at the end
        of the new line.

        This stores the line position in Inform_verbs[verbnum].l[line].
        (It does not increment Inform_verbs[verbnum].lines; the caller
        must do that.)

        Syntax: * <token1> ... <token-n> -> <action>

        is compiled to a table in the form:

                <action : word>
                <token 1> ... <token n> <ENDIT>

        where <ENDIT> is the byte 15, and each <token> is 2 or 3 bytes
        long. The action word contains the action number (bottom 10 bits)
        and the "reverse" flag (bit 10).

        The token format is:

                <bytecode> 00    00     [GV1]
                <bytecode> <dat> <dat>  [GV2]
                <bytecode> <dat>        [GV3]

        If grammar_version_number is 3, we omit the <ENDIT> and instead
        encode the token count in the top 5 bits of the action word.
        Also, tokens only have one byte of data; we store adjective
        and parsing routine index numbers instead of addresses.

        Return TRUE if grammar continues after the line, FALSE if the
        directive comes to an end.                                           */

    int j, bytecode, mark; int32 wordcode;
    int grammar_token, slash_mode, last_was_slash;
    int reverse_action, meta_action, TOKEN_SIZE;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    get_next_token();
    if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
    {   discard_token_location(beginning_debug_location);
        return FALSE;
    }
    if (!((token_type == SEP_TT) && (token_value == TIMES_SEP)))
    {   discard_token_location(beginning_debug_location);
        ebf_curtoken_error("'*' divider");
        panic_mode_error_recovery();
        return FALSE;
    }

    mark = grammar_lines_top;

    ensure_grammar_lines_available(verbnum, line+1);
    Inform_verbs[verbnum].l[line] = mark;

    if (!glulx_mode) {
        mark = mark + 2;
        TOKEN_SIZE = (grammar_version_number == 3) ? 2 : 3;
    }
    else {
        mark = mark + 3;
        TOKEN_SIZE = 5;
    }
    ensure_memory_list_available(&grammar_lines_memlist, mark);

    grammar_token = 0; last_was_slash = TRUE; slash_mode = FALSE;
    no_grammar_lines++;

    do
    {   get_next_token();
        bytecode = 0; wordcode = 0;
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
        {   discard_token_location(beginning_debug_location);
            ebf_curtoken_error("'->' clause");
            return FALSE;
        }
        if ((token_type == SEP_TT) && (token_value == ARROW_SEP))
        {   if (last_was_slash && (grammar_token>0))
                ebf_curtoken_error("grammar token");
            break;
        }

        if (!last_was_slash) slash_mode = FALSE;
        if ((token_type == SEP_TT) && (token_value == DIVIDE_SEP))
        {   if (grammar_version_number == 1)
                error("'/' can only be used with grammar version 2 or later");
            if (last_was_slash)
                ebf_curtoken_error("grammar token or '->'");
            else
            {   last_was_slash = TRUE;
                slash_mode = TRUE;
                if (((grammar_lines[mark-TOKEN_SIZE]) & 0x0f) != 2)
                    error("'/' can only be applied to prepositions");
                grammar_lines[mark-TOKEN_SIZE] |= 0x20;
                continue;
            }
        }
        else last_was_slash = FALSE;

        if ((token_type == DQ_TT) || (token_type == SQ_TT))
        {    if (grammar_version_number == 1)
             {   bytecode = make_adjective_v1(token_text);
             }
             else if (grammar_version_number == 2)
             {   bytecode = 0x42;
                 wordcode = dictionary_add(token_text, PREP_DFLAG, 0, 0);
             }
             else if (grammar_version_number == 3)
             {   bytecode = 0x42;
                 wordcode = make_adjective_v3(token_text);
             }
        }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==NOUN_DK))
             {   get_next_token();
                 if ((token_type == SEP_TT) && (token_value == SETEQUALS_SEP))
                 {
                     /*  noun = <routine>                                    */

                     get_next_token();
                     if ((token_type != SYMBOL_TT)
                         || (symbols[token_value].type != ROUTINE_T))
                     {   discard_token_location(beginning_debug_location);
                         ebf_curtoken_error("routine name after 'noun='");
                         panic_mode_error_recovery();
                         return FALSE;
                     }
                     if (grammar_version_number == 1)
                     {   bytecode = 16 +
                             make_parsing_routine(symbols[token_value].value);
                     }
                     else if (grammar_version_number == 2)
                     {   bytecode = 0x83;
                         wordcode = symbols[token_value].value;
                     }
                     else if (grammar_version_number == 3)
                     {   bytecode = 0x83;
                         wordcode = make_parsing_routine(symbols[token_value].value);
                     }
                     symbols[token_value].flags |= USED_SFLAG;
                 }
                 else
                 {   put_token_back();
                     if (grammar_version_number == 1) bytecode=0;
                     else { bytecode = 1; wordcode = 0; }
                 }
             }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==HELD_DK))
             {   if (grammar_version_number==1) bytecode=1;
                 else { bytecode=1; wordcode=1; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==MULTI_DK))
             {   if (grammar_version_number==1) bytecode=2;
                 else { bytecode=1; wordcode=2; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==MULTIHELD_DK))
             {   if (grammar_version_number==1) bytecode=3;
                 else { bytecode=1; wordcode=3; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==MULTIEXCEPT_DK))
             {   if (grammar_version_number==1) bytecode=4;
                 else { bytecode=1; wordcode=4; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==MULTIINSIDE_DK))
             {   if (grammar_version_number==1) bytecode=5;
                 else { bytecode=1; wordcode=5; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==CREATURE_DK))
             {   if (grammar_version_number==1) bytecode=6;
                 else { bytecode=1; wordcode=6; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==SPECIAL_DK))
             {   if (grammar_version_number==1) bytecode=7;
                 else { bytecode=1; wordcode=7; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==NUMBER_DK))
             {   if (grammar_version_number==1) bytecode=8;
                 else { bytecode=1; wordcode=8; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==TOPIC_DK))
             {   if (grammar_version_number==1)
                     error("The 'topic' token is only available if you \
are using grammar version 2 or later");
                 else { bytecode=1; wordcode=9; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==SCOPE_DK))
             {
                 /*  scope = <routine> */

                 get_next_token();
                 if (!((token_type==SEP_TT)&&(token_value==SETEQUALS_SEP)))
                 {   discard_token_location(beginning_debug_location);
                     ebf_curtoken_error("'=' after 'scope'");
                     panic_mode_error_recovery();
                     return FALSE;
                 }

                 get_next_token();
                 if ((token_type != SYMBOL_TT)
                     || (symbols[token_value].type != ROUTINE_T))
                 {   discard_token_location(beginning_debug_location);
                     ebf_curtoken_error("routine name after 'scope='");
                     panic_mode_error_recovery();
                     return FALSE;
                 }

                 if (grammar_version_number == 1)
                 {   bytecode = 80 +
                         make_parsing_routine(symbols[token_value].value);
                 }
                 else if (grammar_version_number == 2)
                 {   bytecode = 0x85;
                     wordcode = symbols[token_value].value;
                 }
                 else if (grammar_version_number == 3)
                 {   bytecode = 0x85;
                     wordcode = make_parsing_routine(symbols[token_value].value);
                 }
                 symbols[token_value].flags |= USED_SFLAG;
             }
        else if ((token_type == SEP_TT) && (token_value == SETEQUALS_SEP))
             {   discard_token_location(beginning_debug_location);
                 error("'=' is only legal here as 'noun=Routine'");
                 panic_mode_error_recovery();
                 return FALSE;
             }
        else {   /*  <attribute>  or  <general-parsing-routine>  tokens      */

                 if ((token_type != SYMBOL_TT)
                     || ((symbols[token_value].type != ATTRIBUTE_T)
                         && (symbols[token_value].type != ROUTINE_T)))
                 {   discard_token_location(beginning_debug_location);
                     error_named("No such grammar token as", token_text);
                     panic_mode_error_recovery();
                     return FALSE;
                 }
                 if (symbols[token_value].type==ATTRIBUTE_T)
                 {   if (grammar_version_number == 1)
                         bytecode = 128 + symbols[token_value].value;
                     else { bytecode = 4; wordcode = symbols[token_value].value; }
                 }
                 else
                 {   if (grammar_version_number == 1)
                     {   bytecode = 48 +
                             make_parsing_routine(symbols[token_value].value);
                     }
                     else if (grammar_version_number == 2)
                     {   bytecode = 0x86;
                         wordcode = symbols[token_value].value;
                     }
                     else if (grammar_version_number == 3)
                     {   bytecode = 0x86;
                         wordcode = make_parsing_routine(symbols[token_value].value);
                     }
                 }
                 symbols[token_value].flags |= USED_SFLAG;
             }

        grammar_token++; no_grammar_tokens++;
        if ((grammar_version_number == 1) && (grammar_token > 6))
        {   if (grammar_token == 7)
                warning("Grammar line cut short: you can only have up to 6 \
tokens in any line (for grammar version 1)");
        }
        else if ((grammar_version_number == 3) && (grammar_token > 31))
        {
            if (grammar_token == 32)
                warning("Grammar line cut short: you can only have up to 31 \
tokens in any line (for grammar version 3)");
        }        
        else
        {   if (slash_mode)
            {   if (bytecode != 0x42)
                    error("'/' can only be applied to prepositions");
                bytecode |= 0x10;
            }
            ensure_memory_list_available(&grammar_lines_memlist, mark+5);
            grammar_lines[mark++] = bytecode;
            if (!glulx_mode) {
                if (grammar_version_number == 3) {
                    grammar_lines[mark++] = (wordcode & 0xFF);
                }
                else {
                    grammar_lines[mark++] = wordcode/256;
                    grammar_lines[mark++] = wordcode%256;
                }
            }
            else {
                grammar_lines[mark++] = ((wordcode >> 24) & 0xFF);
                grammar_lines[mark++] = ((wordcode >> 16) & 0xFF);
                grammar_lines[mark++] = ((wordcode >> 8) & 0xFF);
                grammar_lines[mark++] = ((wordcode) & 0xFF);
            }
        }

    } while (TRUE);

    ensure_memory_list_available(&grammar_lines_memlist, mark+1);
    if (grammar_version_number != 3) {
        grammar_lines[mark++] = 15; /* ENDIT */
    }
    grammar_lines_top = mark;

    dont_enter_into_symbol_table = TRUE;
    get_next_token();
    dont_enter_into_symbol_table = FALSE;

    if (token_type != UQ_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_curtoken_error("name of new or existing action");
        panic_mode_error_recovery();
        return FALSE;
    }

    {   assembly_operand AO = action_of_name(token_text);
        j = AO.value; /* the action number */
        if (j >= lowest_fake_action())
            error_named("This is a fake action, not a real one:", token_text);
    }

    reverse_action = FALSE;
    /* allmeta is set if this is a "Verb meta" declaration; that is, all
       actions mentioned are implicitly meta. */
    meta_action = allmeta;

    while (TRUE) {
        get_next_token();
        if ((token_type == DIR_KEYWORD_TT) && (token_value == REVERSE_DK))
        {
            if (grammar_version_number == 1)
                error("'reverse' actions can only be used with grammar version 2 or later");
            reverse_action = TRUE;
        }
        else if ((token_type == DIR_KEYWORD_TT) && (token_value == META_DK))
        {
            if (!GRAMMAR_META_FLAG)
                error("$GRAMMAR_META_FLAG must be set before marking individual actions as 'meta'");
            meta_action = TRUE;
        }
        else
        {
            break;
        }
    }
    put_token_back();

    if (meta_action) {
        if (j >= 0 && j < no_actions) {
            actions[j].meta = TRUE;
        }
    }

    mark = Inform_verbs[verbnum].l[line];

    if (debugfile_switch)
    {   debug_file_printf("<table-entry>");
        debug_file_printf("<type>grammar line</type>");
        debug_file_printf("<address>");
        write_debug_grammar_backpatch(mark);
        debug_file_printf("</address>");
        debug_file_printf("<end-address>");
        write_debug_grammar_backpatch(grammar_lines_top);
        debug_file_printf("</end-address>");
        write_debug_locations
            (get_token_location_end(beginning_debug_location));
        debug_file_printf("</table-entry>");
    }

    ensure_memory_list_available(&grammar_lines_memlist, mark+3);
    if (!glulx_mode) {
        if (grammar_version_number == 3)
            j = j + (grammar_token << 11);
        if (reverse_action)
            j = j + 0x400;
        grammar_lines[mark++] = j/256;
        grammar_lines[mark++] = j%256;
    }
    else {
        grammar_lines[mark++] = ((j >> 8) & 0xFF);
        grammar_lines[mark++] = ((j) & 0xFF);
        grammar_lines[mark++] = (reverse_action ? 1 : 0);
    }

    return TRUE;
}

/* ------------------------------------------------------------------------- */
/*   The Verb directive:                                                     */
/*                                                                           */
/*       Verb [meta] "word-1" ... "word-n" | = "existing-English-verb"       */
/*                                         | <grammar-line-1> ... <g-line-n> */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#define EXTEND_REPLACE 1
#define EXTEND_FIRST   2
#define EXTEND_LAST    3

static void do_extend_verb(int Inform_verb, int extend_mode);

extern void make_verb(void)
{
    /*  Parse an entire Verb ... directive.                                  */
    
    int Inform_verb, meta_verb_flag=FALSE, verb_equals_form=FALSE;
    int first_given_verb = English_verbs_count;
    int firsttime = TRUE;
    int ix;

    directive_keywords.enabled = TRUE;
    /* TODO: We should really turn off directive_keywords for all exit paths.
       Currently we don't bother after an error. */

    get_next_token();

    if ((token_type == DIR_KEYWORD_TT) && (token_value == META_DK))
    {   meta_verb_flag = TRUE;
        get_next_token();
    }

    while ((token_type == DQ_TT) || (token_type == SQ_TT))
    {
        int wordlen, textpos, dictword, evnum;
        char *tmpstr;

        int flags = VERB_DFLAG
            + (DICT_TRUNCATE_FLAG ? NONE_DFLAG : TRUNC_DFLAG)
            + (meta_verb_flag ? META_DFLAG : NONE_DFLAG);
        dictword = dictionary_add(token_text, flags, 0, 0);

        evnum = find_verb_entry(dictword);
        if (evnum >= 0)
        {
            /* The word already has a verb definition.
               
               We can accept this as an "Extend last" if this is the
               first given word, and all following words (through the *)
               have the same definition. */
            int foundverb = English_verbs[evnum].verbnum;
            if (firsttime) {
                get_next_token();
                while ((token_type == DQ_TT) || (token_type == SQ_TT)) {
                    int dictword2 = dictionary_add(token_text, flags, 0, 0);
                    int evnum2 = find_verb_entry(dictword2);
                    int foundverb2 = (evnum2 < 0) ? -1 : English_verbs[evnum2].verbnum;
                    if (foundverb2 != foundverb) {
                        foundverb = -1; /* mismatch or not found */
                        break;
                    }
                    get_next_token();
                }
                if (foundverb >= 0
                    && ((token_type == SEP_TT) && (token_value == TIMES_SEP))) {
                    tmpstr = English_verbs[evnum].textpos + English_verbs_text;
                    warning_fmt("This verb definition refers to \"%s\", which has already been defined. Use \"Extend last\" instead.", tmpstr);

                    put_token_back();
                    
                    /* Keyword settings used in extend_verb() */
                    directive_keywords.enabled = TRUE;
                    directives.enabled = FALSE;

                    do_extend_verb(foundverb, EXTEND_LAST);

                    directive_keywords.enabled = FALSE;
                    directives.enabled = TRUE;
                    return;
                }
                put_token_back();
            }

            /* Not a valid "Extend last". Complain and continue. */
            tmpstr = English_verbs[evnum].textpos + English_verbs_text;
            error_named("Two different verb definitions refer to", tmpstr);
            
            firsttime = FALSE;
            get_next_token();
            continue;
        }

        /* Brand-new verb word. */
        wordlen = strlen(token_text);
        textpos = English_verbs_text_size;
        ensure_memory_list_available(&English_verbs_text_memlist, English_verbs_text_size + (wordlen+1));
        strcpy(English_verbs_text+textpos, token_text);
        English_verbs_text_size += (wordlen+1);
        
        ensure_memory_list_available(&English_verbs_memlist, English_verbs_count+1);
        English_verbs[English_verbs_count].textpos = textpos;
        English_verbs[English_verbs_count].verbnum = -1;
        English_verbs[English_verbs_count].dictword = dictword;
        English_verbs_count++;
        
        firsttime = FALSE;
        get_next_token();
    }
    
    /* The E-verbs defined in this directive run from first_given_verb
       to English_verbs_count. */

    if (first_given_verb == English_verbs_count)
    {   /* No E-verbs given at all! */
        ebf_curtoken_error("English verb in quotes");
        panic_mode_error_recovery(); return;
    }

    if ((token_type == SEP_TT) && (token_value == SETEQUALS_SEP))
    {   /* Define those E-verbs to match an existing I-verb. */
        verb_equals_form = TRUE;
        get_next_token();
        Inform_verb = get_existing_verb(NULL);
        if (Inform_verb == -1)
            return; /* error already printed */
        get_next_token();
        if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
            ebf_curtoken_error("';' after English verb");
    }
    else
    {   /* Define those E-verbs to be a brand-new I-verb. */
        verb_equals_form = FALSE;
        if (!glulx_mode && no_Inform_verbs >= 255) {
            error("Z-code is limited to 255 verbs.");
            panic_mode_error_recovery(); return;
        }
        if (no_Inform_verbs >= 65535) {
            error("Inform is limited to 65535 verbs.");
            panic_mode_error_recovery(); return;
        }
        ensure_memory_list_available(&Inform_verbs_memlist, no_Inform_verbs+1);
        Inform_verb = no_Inform_verbs;
        Inform_verbs[no_Inform_verbs].lines = 0;
        Inform_verbs[no_Inform_verbs].size = 4;
        Inform_verbs[no_Inform_verbs].l = my_malloc(sizeof(int) * Inform_verbs[no_Inform_verbs].size, "grammar lines for one verb");
        Inform_verbs[no_Inform_verbs].line = get_brief_location(&ErrorReport);
        Inform_verbs[no_Inform_verbs].used = FALSE;
    }

    /* Inform_verb is now the I-verb which those E-verbs should invoke. */

    for (ix=first_given_verb; ix<English_verbs_count; ix++) {
        English_verbs[ix].verbnum = Inform_verb;
        dictionary_set_verb_number(English_verbs[ix].dictword, Inform_verb);
    }

    if (!verb_equals_form)
    {   int lines = 0;
        put_token_back();
        while (grammar_line(no_Inform_verbs, meta_verb_flag, lines++)) ;
        Inform_verbs[no_Inform_verbs++].lines = --lines;
    }

    directive_keywords.enabled = FALSE;
}

/* ------------------------------------------------------------------------- */
/*   The Extend directive:                                                   */
/*                                                                           */
/*      Extend | only "verb-1" ... "verb-n"  |             <grammar-lines>   */
/*             | "verb"                      | "replace"                     */
/*                                           | "first"                       */
/*                                           | "last"                        */
/*                                                                           */
/* ------------------------------------------------------------------------- */

extern void extend_verb(void)
{
    /*  Parse an entire Extend ... directive.                                */

    int Inform_verb = -1, k, l, extend_mode;

    directive_keywords.enabled = TRUE;
    directives.enabled = FALSE;

    get_next_token();
    if ((token_type == DIR_KEYWORD_TT) && (token_value == ONLY_DK))
    {
        if (!glulx_mode && no_Inform_verbs >= 255) {
            error("Z-code is limited to 255 verbs.");
            panic_mode_error_recovery(); return;
        }
        if (no_Inform_verbs >= 65535) {
            error("Inform is limited to 65535 verbs.");
            panic_mode_error_recovery(); return;
        }
        ensure_memory_list_available(&Inform_verbs_memlist, no_Inform_verbs+1);
        l = -1;
        while (get_next_token(),
               ((token_type == DQ_TT) || (token_type == SQ_TT)))
        {
            int dictword;
            Inform_verb = get_existing_verb(&dictword);
            if (Inform_verb == -1)
                return; /* error already printed */
            /* dictword is the dict index number of token_text */
            if ((l!=-1) && (Inform_verb!=l))
              warning_named("Verb disagrees with previous verbs:", token_text);
            l = Inform_verb;
            dictionary_set_verb_number(dictword, no_Inform_verbs);
            /* make call to renumber verb in English_verbs too */
            if (renumber_verb(dictword, no_Inform_verbs) == -1)
              warning_named("Verb to extend not found in English_verbs:",
                 token_text);
        }

        /*  Copy the old Inform-verb into a new one which the list of
            English-verbs given have had their dictionary entries modified
            to point to                                                      */
        /*  (We are copying entry Inform_verb to no_Inform_verbs here.) */

        l = Inform_verbs[Inform_verb].lines; /* number of lines to copy */
        
        Inform_verbs[no_Inform_verbs].lines = l;
        Inform_verbs[no_Inform_verbs].size = l+4;
        Inform_verbs[no_Inform_verbs].l = my_malloc(sizeof(int) * Inform_verbs[no_Inform_verbs].size, "grammar lines for one verb");
        for (k=0; k<l; k++)
            Inform_verbs[no_Inform_verbs].l[k] = Inform_verbs[Inform_verb].l[k];
        Inform_verbs[no_Inform_verbs].line = get_brief_location(&ErrorReport);
        Inform_verbs[no_Inform_verbs].used = FALSE;
        Inform_verb = no_Inform_verbs++;
    }
    else
    {   Inform_verb = get_existing_verb(NULL);
        if (Inform_verb == -1)
            return; /* error already printed */
        get_next_token();
    }

    /*  Inform_verb now contains the number of the Inform-verb to extend...  */

    extend_mode = EXTEND_LAST;
    if ((token_type == SEP_TT) && (token_value == TIMES_SEP))
        put_token_back();
    else
    {   extend_mode = 0;
        if ((token_type == DIR_KEYWORD_TT) && (token_value == REPLACE_DK))
            extend_mode = EXTEND_REPLACE;
        if ((token_type == DIR_KEYWORD_TT) && (token_value == FIRST_DK))
            extend_mode = EXTEND_FIRST;
        if ((token_type == DIR_KEYWORD_TT) && (token_value == LAST_DK))
            extend_mode = EXTEND_LAST;

        if (extend_mode==0)
        {   ebf_curtoken_error("'replace', 'last', 'first' or '*'");
            extend_mode = EXTEND_LAST;
        }
    }

    do_extend_verb(Inform_verb, extend_mode);

    directive_keywords.enabled = FALSE;
    directives.enabled = TRUE;
}

static void do_extend_verb(int Inform_verb, int extend_mode)
{
    /* The execution of Extend. This is called both from extend_verb()
       and from the implicit-extend case of make_verb(). */
    
    int k, l, lines;
    
    l = Inform_verbs[Inform_verb].lines;
    lines = 0;
    if (extend_mode == EXTEND_LAST) lines=l;
    do
    {
        if (extend_mode == EXTEND_FIRST) {
            ensure_grammar_lines_available(Inform_verb, l+lines+1);
            for (k=l; k>0; k--)
                 Inform_verbs[Inform_verb].l[k+lines]
                     = Inform_verbs[Inform_verb].l[k-1+lines];
        }
    } while (grammar_line(Inform_verb, FALSE, lines++));

    if (extend_mode == EXTEND_FIRST)
    {
        ensure_grammar_lines_available(Inform_verb, l+lines+1);
        Inform_verbs[Inform_verb].lines = l+lines-1;
        for (k=0; k<l; k++) {
            Inform_verbs[Inform_verb].l[k+lines-1]
                = Inform_verbs[Inform_verb].l[k+lines];
        }
    }
    else Inform_verbs[Inform_verb].lines = --lines;
}


/* ------------------------------------------------------------------------- */
/*   Action table sorter.                                                    */
/*   This is only invoked if GRAMMAR_META_FLAG is set. It creates a new      */
/*   ordering for actions in which the meta entries are all first.           */
/* ------------------------------------------------------------------------- */

extern void sort_actions(void)
{
    int ix, pos;
    
    sorted_actions = my_malloc(sizeof(actionsort) * no_actions, "sorted action table");

    /* No fancy sorting algorithm. We just go through the actions table
       twice. */

    pos = 0;
    
    for (ix=0; ix<no_actions; ix++) {
        if (actions[ix].meta) {
            sorted_actions[ix].internal_to_ext = pos;
            sorted_actions[pos].external_to_int = ix;
            pos++;
        }
    }
    
    no_meta_actions = pos;
    
    for (ix=0; ix<no_actions; ix++) {
        if (!actions[ix].meta) {
            sorted_actions[ix].internal_to_ext = pos;
            sorted_actions[pos].external_to_int = ix;
            pos++;
        }
    }

    if (pos != no_actions) {
        compiler_error("action sorting length mismatch");
    }
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_verbs_vars(void)
{
    no_fake_actions = 0;
    no_actions = 0;
    no_meta_actions = -1;
    no_grammar_lines = 0;
    no_grammar_tokens = 0;
    English_verbs_count = 0;
    English_verbs_text_size = 0;

    Inform_verbs = NULL;
    actions = NULL;
    grammar_lines = NULL;
    grammar_token_routine = NULL;
    adjectives = NULL;
    adjective_sort_code = NULL;
    English_verbs = NULL;
    English_verbs_text = NULL;

    /* Set the default grammar version value (will be adjusted later) */
    if (!glulx_mode)
        grammar_version_number = 1;
    else
        grammar_version_number = 2;
    /* This is set at allocate_arrays time */
    grammar_version_symbol = -1;
}

extern void verbs_begin_pass(void)
{
    no_Inform_verbs=0; no_adjectives=0;
    no_grammar_token_routines=0;
    no_actions=0;

    no_fake_actions=0;
    grammar_lines_top = 0;

    /* Set the version requested by compiler setting (with validity check) */
    if (!glulx_mode)
        set_grammar_version(GRAMMAR_VERSION_z);
    else
        set_grammar_version(GRAMMAR_VERSION_g);
}

extern void verbs_allocate_arrays(void)
{
    initialise_memory_list(&Inform_verbs_memlist,
        sizeof(verbt), 128, (void**)&Inform_verbs,
        "verbs");
    
    initialise_memory_list(&grammar_lines_memlist,
        sizeof(uchar), 4000, (void**)&grammar_lines,
        "grammar lines");
    
    initialise_memory_list(&actions_memlist,
        sizeof(actioninfo), 128, (void**)&actions,
        "actions");

    sorted_actions = NULL;
    
    initialise_memory_list(&grammar_token_routine_memlist,
        sizeof(int32), 50, (void**)&grammar_token_routine,
        "grammar token routines");

    initialise_memory_list(&adjectives_memlist,
        sizeof(int32), 50, (void**)&adjectives,
        "adjectives");
    initialise_memory_list(&adjective_sort_code_memlist,
        sizeof(uchar), 50*DICT_WORD_BYTES, (void**)&adjective_sort_code,
        "adjective sort codes");

    initialise_memory_list(&action_symname_memlist,
        sizeof(uchar), 32, NULL,
        "action temporary symbols");
    
    initialise_memory_list(&English_verbs_memlist,
        sizeof(English_verb_t), 256, (void**)&English_verbs,
        "register of verbs");

    initialise_memory_list(&English_verbs_text_memlist,
        sizeof(char), 2048, (void**)&English_verbs_text,
        "text of registered verbs");
    
}

extern void verbs_free_arrays(void)
{
    int ix;
    for (ix=0; ix<no_Inform_verbs; ix++)
    {
        my_free(&Inform_verbs[ix].l, "grammar lines for one verb");
    }
    if (sorted_actions)
    {
        my_free(&sorted_actions, "sorted action table");
    }
    deallocate_memory_list(&Inform_verbs_memlist);
    deallocate_memory_list(&grammar_lines_memlist);
    deallocate_memory_list(&actions_memlist);
    deallocate_memory_list(&grammar_token_routine_memlist);
    deallocate_memory_list(&adjectives_memlist);
    deallocate_memory_list(&adjective_sort_code_memlist);
    deallocate_memory_list(&action_symname_memlist);
    deallocate_memory_list(&English_verbs_memlist);
    deallocate_memory_list(&English_verbs_text_memlist);
}

/* ========================================================================= */
