/* ------------------------------------------------------------------------- */
/*   "verbs" :  Manages actions and grammar tables; parses the directives    */
/*              Verb and Extend.                                             */
/*                                                                           */
/*   Part of Inform 6.41                                                     */
/*   copyright (c) Graham Nelson 1993 - 2022                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

int grammar_version_number;            /* 1 for pre-Inform 6.06 table format */
int32 grammar_version_symbol;          /* Index of "Grammar__Version"
                                          within symbols table               */

/* ------------------------------------------------------------------------- */
/*   Actions.                                                                */
/* ------------------------------------------------------------------------- */
/*   Array defined below:                                                    */
/*                                                                           */
/*    actioninfo actions[n]               Symbol table index and byte offset */
/*                                        of the ...Sub routine              */
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
/*           Inform verb is essentially a list of grammar lines.             */
/*           (Calling them "English verbs" is of course out of date. Read    */
/*           this as jargon for "dict words which are verbs".                */
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
/*   The format of this list is a sequence of variable-length records:       */
/*                                                                           */
/*     Byte offset to start of next record  (1 byte)                         */
/*     Inform verb number this word corresponds to  (2 bytes)                */
/*     The English verb-word (reduced to lower case), null-terminated        */
/* ------------------------------------------------------------------------- */

static char *English_verb_list;       /* Allocated to English_verb_list_size */
static memory_list English_verb_list_memlist;

static int English_verb_list_size;     /* Size of the list in bytes          */

static char *English_verbs_given;      /* Allocated to verbs_given_pos
                                          (Used only within make_verb())     */
static memory_list English_verbs_given_memlist;

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

  int32   *adjectives; /* Allocated to no_adjectives */
  static memory_list adjectives_memlist;

  static uchar *adjective_sort_code; /* Allocated to no_adjectives*DICT_WORD_BYTES */
  static memory_list adjective_sort_code_memlist;

/* ------------------------------------------------------------------------- */
/*   Tracing for compiler maintenance                                        */
/* ------------------------------------------------------------------------- */

static char *find_verb_by_number(int num);

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
    if (flags) printf(" (reversed)");
    printf("\n");
}

extern void list_verb_table(void)
{
    int verb, lx;
    printf("Grammar table: %d verbs\n", no_Inform_verbs);
    for (verb=0; verb<no_Inform_verbs; verb++) {
        char *verbword = find_verb_by_number(verb);
        printf("Verb '%s'\n", verbword);
        for (lx=0; lx<Inform_verbs[verb].lines; lx++) {
            int mark = Inform_verbs[verb].l[lx];
            switch (grammar_version_number) {
            case 1:
                list_grammar_line_v1(mark);
                break;
            case 2:
                list_grammar_line_v2(mark);
                break;
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/*   Actions.                                                                */
/* ------------------------------------------------------------------------- */

static void new_action(char *b, int c)
{
    /*  Called whenever a new action (or fake action) is created (either
        by using make_action above, or the Fake_Action directive).
        At present just a hook for some tracing code.                        */

    if (printactions_switch)
        printf("Action '%s' is numbered %d\n",b,c);
}

/* Note that fake actions are numbered from a high base point upwards;
   real actions are numbered from 0 upward in GV2.                           */

extern void make_fake_action(void)
{   int i;
    char action_sub[MAX_IDENTIFIER_LENGTH+4];
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    get_next_token();
    if (token_type != SYMBOL_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_error("new fake action name", token_text);
        panic_mode_error_recovery(); return;
    }
    /* Action symbols (including fake_actions) may collide with other kinds of symbols. So we don't check that. */

    snprintf(action_sub, MAX_IDENTIFIER_LENGTH+4, "%s__A", token_text);
    i = symbol_index(action_sub, -1);

    if (!(symbols[i].flags & UNKNOWN_SFLAG))
    {   discard_token_location(beginning_debug_location);
        /* The user didn't know they were defining FOO__A, but they were and it's a problem. */
        ebf_symbol_error("new fake action name", action_sub, typename(symbols[i].type), symbols[i].line);
        panic_mode_error_recovery(); return;
    }

    assign_symbol(i, ((grammar_version_number==1)?256:4096)+no_fake_actions++,
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

    char action_sub[MAX_IDENTIFIER_LENGTH+4];
    int j;
    assembly_operand AO;

    snprintf(action_sub, MAX_IDENTIFIER_LENGTH+4, "%s__A", name);
    j = symbol_index(action_sub, -1);

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
        ensure_memory_list_available(&actions_memlist, no_actions+1);
        new_action(name, no_actions);
        actions[no_actions].symbol = j;
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
    char action_name[MAX_IDENTIFIER_LENGTH+4];
    char action_sub[MAX_IDENTIFIER_LENGTH+4];

    for (i=0; i<no_actions; i++)
    {   strcpy(action_name, symbols[actions[i].symbol].name);
        action_name[strlen(action_name) - 3] = '\0'; /* remove "__A" */
        strcpy(action_sub, action_name);
        strcat(action_sub, "Sub");
        j = symbol_index(action_sub, -1);
        if (symbols[j].flags & UNKNOWN_SFLAG)
        {
            error_named_at("No ...Sub action routine found for action:", action_name, symbols[actions[i].symbol].line);
        }
        else
        if (symbols[j].type != ROUTINE_T)
        {
            error_named_at("No ...Sub action routine found for action:", action_name, symbols[actions[i].symbol].line);
            error_named_at("-- ...Sub symbol found, but not a routine:", action_sub, symbols[j].line);
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

static int make_adjective(char *English_word)
{
    /*  Returns adjective number of the English word supplied, creating
        a new adjective number if need be.

        Note that (partly for historical reasons) adjectives are numbered
        from 0xff downwards.  (And partly to make them stand out as tokens.)

        This routine is used only in grammar version 1: the corresponding
        table is left empty in GV2.                                          */

    int i; 
    uchar new_sort_code[MAX_DICT_WORD_BYTES];

    if (no_adjectives >= 255) {
        error("Grammar version 1 cannot support more than 255 prepositions");
        return 0;
    }
    if (ZCODE_LESS_DICT_DATA && !glulx_mode) {
        /* We need to use #dict_par3 for the preposition number. */
        error("Grammar version 1 cannot be used with ZCODE_LESS_DICT_DATA");
        return 0;
    }
    ensure_memory_list_available(&adjectives_memlist, no_adjectives+1);
    ensure_memory_list_available(&adjective_sort_code_memlist, (no_adjectives+1) * DICT_WORD_BYTES);

    dictionary_prepare(English_word, new_sort_code);
    for (i=0; i<no_adjectives; i++)
        if (compare_sorts(new_sort_code,
          adjective_sort_code+i*DICT_WORD_BYTES) == 0)
            return(0xff-i);
    adjectives[no_adjectives]
        = dictionary_add(English_word,8,0,0xff-no_adjectives);
    copy_sorts(adjective_sort_code+no_adjectives*DICT_WORD_BYTES,
        new_sort_code);
    return(0xff-no_adjectives++);
}

/* ------------------------------------------------------------------------- */
/*   Parsing routines.                                                       */
/* ------------------------------------------------------------------------- */

static int make_parsing_routine(int32 routine_address)
{
    /*  This routine is used only in grammar version 1: the corresponding
        table is left empty in GV2.                                          */

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

static int find_or_renumber_verb(char *English_verb, int *new_number)
{
    /*  If new_number is null, returns the Inform-verb number which the
     *  given English verb causes, or -1 if the given verb is not in the
     *  dictionary                     */

    /*  If new_number is non-null, renumbers the Inform-verb number which
     *  English_verb matches in English_verb_list to account for the case
     *  when we are extending a verb.  Returns 0 if successful, or -1 if
     *  the given verb is not in the dictionary (which shouldn't happen as
     *  get_verb has already run) */

    char *p;
    p=English_verb_list;
    while (p < English_verb_list+English_verb_list_size)
    {   if (strcmp(English_verb, p+3) == 0)
        {   if (new_number)
            {   p[1] = (*new_number)/256;
                p[2] = (*new_number)%256;
                return 0;
            }
            return(256*((uchar)p[1]))+((uchar)p[2]);
        }
        p=p+(uchar)p[0];
    }
    return(-1);
}

static char *find_verb_by_number(int num)
{
    /*  Find the English verb string with the given verb number. */
    char *p;
    p=English_verb_list;
    while (p < English_verb_list+English_verb_list_size)
    {
        int val = (p[1] << 8) | p[2];
        if (val == num) {
            return p+3;
        }
        p=p+(uchar)p[0];
    }
    return "???";
}

static void register_verb(char *English_verb, int number)
{
    /*  Registers a new English verb as referring to the given Inform-verb
        number.  (See comments above for format of the list.)                */
    char *top;
    int entrysize;

    if (find_or_renumber_verb(English_verb, NULL) != -1)
    {   error_named("Two different verb definitions refer to", English_verb);
        return;
    }

    /* We set a hard limit of MAX_VERB_WORD_SIZE=120 because the
       English_verb_list table stores length in a leading byte. (We could
       raise that to 250, really, but there's little point when
       MAX_DICT_WORD_SIZE is 40.) */
    entrysize = strlen(English_verb)+4;
    if (entrysize > MAX_VERB_WORD_SIZE+4)
        error_numbered("Verb word is too long -- max length is", MAX_VERB_WORD_SIZE);
    ensure_memory_list_available(&English_verb_list_memlist, English_verb_list_size + entrysize);
    top = English_verb_list + English_verb_list_size;
    English_verb_list_size += entrysize;

    top[0] = entrysize;
    top[1] = number/256;
    top[2] = number%256;
    strcpy(top+3, English_verb);
}

static int get_verb(void)
{
    /*  Look at the last-read token: if it's the name of an English verb
        understood by Inform, in double-quotes, then return the Inform-verb
        that word refers to: otherwise give an error and return -1.          */

    int j;

    if ((token_type == DQ_TT) || (token_type == SQ_TT))
    {   j = find_or_renumber_verb(token_text, NULL);
        if (j==-1)
            error_named("There is no previous grammar for the verb",
                token_text);
        return j;
    }

    ebf_error("an English verb in quotes", token_text);

    return -1;
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

static int grammar_line(int verbnum, int line)
{
    /*  Parse a grammar line, to be written into grammar_lines[] starting
        at grammar_lines_top. grammar_lines_top is left at the end
        of the new line.

        This stores the line position in Inform_verbs[verbnum].l[line].
        (It does not increment Inform_verbs[verbnum].lines; the caller
        must do that.)

        Syntax: * <token1> ... <token-n> -> <action>

        is compiled to a table in the form:

                <action number : word>
                <token 1> ... <token n> <ENDIT>

        where <ENDIT> is the byte 15, and each <token> is 3 bytes long.

        If grammar_version_number is 1, the token holds

                <bytecode> 00 00

        and otherwise a GV2 token.

        Return TRUE if grammar continues after the line, FALSE if the
        directive comes to an end.                                           */

    int j, bytecode, mark; int32 wordcode;
    int grammar_token, slash_mode, last_was_slash;
    int reverse_action, TOKEN_SIZE;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    get_next_token();
    if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
    {   discard_token_location(beginning_debug_location);
        return FALSE;
    }
    if (!((token_type == SEP_TT) && (token_value == TIMES_SEP)))
    {   discard_token_location(beginning_debug_location);
        ebf_error("'*' divider", token_text);
        panic_mode_error_recovery();
        return FALSE;
    }

    mark = grammar_lines_top;

    ensure_grammar_lines_available(verbnum, line+1);
    Inform_verbs[verbnum].l[line] = mark;

    if (!glulx_mode) {
        mark = mark + 2;
        TOKEN_SIZE = 3;
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
            ebf_error("'->' clause", token_text);
            return FALSE;
        }
        if ((token_type == SEP_TT) && (token_value == ARROW_SEP))
        {   if (last_was_slash && (grammar_token>0))
                ebf_error("grammar token", token_text);
            break;
        }

        if (!last_was_slash) slash_mode = FALSE;
        if ((token_type == SEP_TT) && (token_value == DIVIDE_SEP))
        {   if (grammar_version_number == 1)
                error("'/' can only be used with Library 6/3 or later");
            if (last_was_slash)
                ebf_error("grammar token or '->'", token_text);
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
                 bytecode = make_adjective(token_text);
             else
             {   bytecode = 0x42;
                 wordcode = dictionary_add(token_text, 8, 0, 0);
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
                         ebf_error("routine name after 'noun='", token_text);
                         panic_mode_error_recovery();
                         return FALSE;
                     }
                     if (grammar_version_number == 1)
                         bytecode
                             = 16 + make_parsing_routine(symbols[token_value].value);
                     else
                     {   bytecode = 0x83;
                         wordcode = symbols[token_value].value;
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
are using Library 6/3 or later");
                 else { bytecode=1; wordcode=9; } }
        else if ((token_type==DIR_KEYWORD_TT)&&(token_value==SCOPE_DK))
             {
                 /*  scope = <routine> */

                 get_next_token();
                 if (!((token_type==SEP_TT)&&(token_value==SETEQUALS_SEP)))
                 {   discard_token_location(beginning_debug_location);
                     ebf_error("'=' after 'scope'", token_text);
                     panic_mode_error_recovery();
                     return FALSE;
                 }

                 get_next_token();
                 if ((token_type != SYMBOL_TT)
                     || (symbols[token_value].type != ROUTINE_T))
                 {   discard_token_location(beginning_debug_location);
                     ebf_error("routine name after 'scope='", token_text);
                     panic_mode_error_recovery();
                     return FALSE;
                 }

                 if (grammar_version_number == 1)
                     bytecode = 80 +
                         make_parsing_routine(symbols[token_value].value);
                 else { bytecode = 0x85; wordcode = symbols[token_value].value; }
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
                         bytecode = 48 +
                             make_parsing_routine(symbols[token_value].value);
                     else { bytecode = 0x86; wordcode = symbols[token_value].value; }
                 }
                 symbols[token_value].flags |= USED_SFLAG;
             }

        grammar_token++; no_grammar_tokens++;
        if ((grammar_version_number == 1) && (grammar_token > 6))
        {   if (grammar_token == 7)
                warning("Grammar line cut short: you can only have up to 6 \
tokens in any line (unless you're compiling with library 6/3 or later)");
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
                grammar_lines[mark++] = wordcode/256;
                grammar_lines[mark++] = wordcode%256;
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
    grammar_lines[mark++] = 15;
    grammar_lines_top = mark;

    dont_enter_into_symbol_table = TRUE;
    get_next_token();
    dont_enter_into_symbol_table = FALSE;

    if (token_type != DQ_TT)
    {   discard_token_location(beginning_debug_location);
        ebf_error("name of new or existing action", token_text);
        panic_mode_error_recovery();
        return FALSE;
    }

    {   assembly_operand AO = action_of_name(token_text);
        j = AO.value;
        if (j >= ((grammar_version_number==1)?256:4096))
            error_named("This is a fake action, not a real one:", token_text);
    }

    reverse_action = FALSE;
    get_next_token();
    if ((token_type == DIR_KEYWORD_TT) && (token_value == REVERSE_DK))
    {   if (grammar_version_number == 1)
            error("'reverse' actions can only be used with \
Library 6/3 or later");
        reverse_action = TRUE;
    }
    else put_token_back();

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

extern void make_verb(void)
{
    /*  Parse an entire Verb ... directive.                                  */

    int Inform_verb, meta_verb_flag=FALSE, verb_equals_form=FALSE;

    int no_given = 0, verbs_given_pos = 0;
    int i, pos;

    directive_keywords.enabled = TRUE;

    get_next_token();

    if ((token_type == DIR_KEYWORD_TT) && (token_value == META_DK))
    {   meta_verb_flag = TRUE;
        get_next_token();
    }

    while ((token_type == DQ_TT) || (token_type == SQ_TT))
    {
        int len = strlen(token_text) + 1;
        ensure_memory_list_available(&English_verbs_given_memlist, verbs_given_pos + len);
        strcpy(English_verbs_given+verbs_given_pos, token_text);
        verbs_given_pos += len;
        no_given++;
        get_next_token();
    }

    if (no_given == 0)
    {   ebf_error("English verb in quotes", token_text);
        panic_mode_error_recovery(); return;
    }

    if ((token_type == SEP_TT) && (token_value == SETEQUALS_SEP))
    {   verb_equals_form = TRUE;
        get_next_token();
        Inform_verb = get_verb();
        if (Inform_verb == -1) return;
        get_next_token();
        if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
            ebf_error("';' after English verb", token_text);
    }
    else
    {   verb_equals_form = FALSE;
        if (!glulx_mode && no_Inform_verbs >= 255) {
            error("Z-code is limited to 255 verbs.");
            panic_mode_error_recovery(); return;
        }
        ensure_memory_list_available(&Inform_verbs_memlist, no_Inform_verbs+1);
        Inform_verb = no_Inform_verbs;
        Inform_verbs[no_Inform_verbs].lines = 0;
        Inform_verbs[no_Inform_verbs].size = 4;
        Inform_verbs[no_Inform_verbs].l = my_malloc(sizeof(int) * Inform_verbs[no_Inform_verbs].size, "grammar lines for one verb");
    }

    for (i=0, pos=0; i<no_given; i++) {
        char *wd = English_verbs_given+pos;
        dictionary_add(wd,
            0x41 + ((meta_verb_flag)?0x02:0x00),
            (glulx_mode)?(0xffff-Inform_verb):(0xff-Inform_verb), 0);
        register_verb(wd, Inform_verb);
        pos += (strlen(wd) + 1);
    }

    if (!verb_equals_form)
    {   int lines = 0;
        put_token_back();
        while (grammar_line(no_Inform_verbs, lines++)) ;
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

#define EXTEND_REPLACE 1
#define EXTEND_FIRST   2
#define EXTEND_LAST    3

extern void extend_verb(void)
{
    /*  Parse an entire Extend ... directive.                                */

    int Inform_verb = -1, k, l, lines, extend_mode;

    directive_keywords.enabled = TRUE;
    directives.enabled = FALSE;

    get_next_token();
    if ((token_type == DIR_KEYWORD_TT) && (token_value == ONLY_DK))
    {
        if (!glulx_mode && no_Inform_verbs >= 255) {
            error("Z-code is limited to 255 verbs.");
            panic_mode_error_recovery(); return;
        }
        ensure_memory_list_available(&Inform_verbs_memlist, no_Inform_verbs+1);
        l = -1;
        while (get_next_token(),
               ((token_type == DQ_TT) || (token_type == SQ_TT)))
        {   Inform_verb = get_verb();
            if (Inform_verb == -1) return;
            if ((l!=-1) && (Inform_verb!=l))
              warning_named("Verb disagrees with previous verbs:", token_text);
            l = Inform_verb;
            dictionary_set_verb_number(token_text,
              (glulx_mode)?(0xffff-no_Inform_verbs):(0xff-no_Inform_verbs));
            /* make call to renumber verb in English_verb_list too */
            if (find_or_renumber_verb(token_text, &no_Inform_verbs) == -1)
              warning_named("Verb to extend not found in English_verb_list:",
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
        Inform_verb = no_Inform_verbs++;
    }
    else
    {   Inform_verb = get_verb();
        if (Inform_verb == -1) return;
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
        {   ebf_error("'replace', 'last', 'first' or '*'", token_text);
            extend_mode = EXTEND_LAST;
        }
    }

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
    } while (grammar_line(Inform_verb, lines++));

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

    directive_keywords.enabled = FALSE;
    directives.enabled = TRUE;
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_verbs_vars(void)
{
    no_fake_actions = 0;
    no_actions = 0;
    no_grammar_lines = 0;
    no_grammar_tokens = 0;
    English_verb_list_size = 0;

    Inform_verbs = NULL;
    actions = NULL;
    grammar_lines = NULL;
    grammar_token_routine = NULL;
    adjectives = NULL;
    adjective_sort_code = NULL;
    English_verb_list = NULL;
    English_verbs_given = NULL;

    if (!glulx_mode)
        grammar_version_number = 1;
    else
        grammar_version_number = 2;
}

extern void verbs_begin_pass(void)
{
    no_Inform_verbs=0; no_adjectives=0;
    no_grammar_token_routines=0;
    no_actions=0;

    no_fake_actions=0;
    grammar_lines_top = 0;
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
    
    initialise_memory_list(&grammar_token_routine_memlist,
        sizeof(int32), 50, (void**)&grammar_token_routine,
        "grammar token routines");

    initialise_memory_list(&adjectives_memlist,
        sizeof(int32), 50, (void**)&adjectives,
        "adjectives");
    initialise_memory_list(&adjective_sort_code_memlist,
        sizeof(uchar), 50*DICT_WORD_BYTES, (void**)&adjective_sort_code,
        "adjective sort codes");

    initialise_memory_list(&English_verb_list_memlist,
        sizeof(char), 2048, (void**)&English_verb_list,
        "register of verbs");

    initialise_memory_list(&English_verbs_given_memlist,
        sizeof(char), 80, (void**)&English_verbs_given,
        "verb words within a single definition");
}

extern void verbs_free_arrays(void)
{
    int ix;
    for (ix=0; ix<no_Inform_verbs; ix++)
    {
        my_free(&Inform_verbs[ix].l, "grammar lines for one verb");
    }
    deallocate_memory_list(&Inform_verbs_memlist);
    deallocate_memory_list(&grammar_lines_memlist);
    deallocate_memory_list(&actions_memlist);
    deallocate_memory_list(&grammar_token_routine_memlist);
    deallocate_memory_list(&adjectives_memlist);
    deallocate_memory_list(&adjective_sort_code_memlist);
    deallocate_memory_list(&English_verb_list_memlist);
    deallocate_memory_list(&English_verbs_given_memlist);
}

/* ========================================================================= */
