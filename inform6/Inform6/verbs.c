/* ------------------------------------------------------------------------- */
/*   "verbs" :  Manages actions and grammar tables; parses the directives    */
/*              Verb and Extend.                                             */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
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
/*    int32   action_byte_offset[n]       The (byte) offset in the Z-machine */
/*                                        code area of the ...Sub routine    */
/*                                        for action n.  (NB: This is left   */
/*                                        blank until the end of the         */
/*                                        compilation pass.)                 */
/*    int32   action_symbol[n]            The symbol table index of the n-th */
/*                                        action's name.                     */
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
/*     Inform verb number this word corresponds to  (1 byte)                 */
/*     The English verb-word (reduced to lower case), null-terminated        */
/* ------------------------------------------------------------------------- */

static char *English_verb_list,        /* First byte of first record         */
            *English_verb_list_top;    /* Next byte free for new record      */

static int English_verb_list_size;     /* Size of the list in bytes
                                          (redundant but convenient)         */

/* ------------------------------------------------------------------------- */
/*   Arrays used by this file                                                */
/* ------------------------------------------------------------------------- */

  verbt   *Inform_verbs;
  uchar   *grammar_lines;
  int32    grammar_lines_top;
  int      no_grammar_lines, no_grammar_tokens;

  int32   *action_byte_offset,
          *action_symbol,
          *grammar_token_routine,
          *adjectives;
  static uchar *adjective_sort_code;

/* ------------------------------------------------------------------------- */
/*   Tracing for compiler maintenance                                        */
/* ------------------------------------------------------------------------- */

extern void list_verb_table(void)
{   int i;
    for (i=0; i<no_Inform_verbs; i++)
        printf("Verb %2d has %d lines\n", i, Inform_verbs[i].lines);
}

/* ------------------------------------------------------------------------- */
/*   Actions.                                                                */
/* ------------------------------------------------------------------------- */

static void new_action(char *b, int c)
{
    /*  Called whenever a new action (or fake action) is created (either
        by using make_action above, or the Fake_Action directive, or by
        the linker).  At present just a hook for some tracing code.          */

    if (printprops_switch)
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

    snprintf(action_sub, MAX_IDENTIFIER_LENGTH+4, "%s__A", token_text);
    i = symbol_index(action_sub, -1);

    if (!(sflags[i] & UNKNOWN_SFLAG))
    {   discard_token_location(beginning_debug_location);
        ebf_error("new fake action name", token_text);
        panic_mode_error_recovery(); return;
    }

    assign_symbol(i, ((grammar_version_number==1)?256:4096)+no_fake_actions++,
        FAKE_ACTION_T);

    new_action(token_text, i);

    if (debugfile_switch)
    {   debug_file_printf("<fake-action>");
        debug_file_printf("<identifier>##%s</identifier>", token_text);
        debug_file_printf("<value>%d</value>", svals[i]);
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

    if (stypes[j] == FAKE_ACTION_T)
    {   INITAO(&AO);
        AO.value = svals[j];
        if (!glulx_mode)
          AO.type = LONG_CONSTANT_OT;
        else
          set_constant_ot(&AO);
        sflags[j] |= USED_SFLAG;
        return AO;
    }

    if (sflags[j] & UNKNOWN_SFLAG)
    {
        if (no_actions>=MAX_ACTIONS) memoryerror("MAX_ACTIONS",MAX_ACTIONS);
        new_action(name, no_actions);
        action_symbol[no_actions] = j;
        assign_symbol(j, no_actions++, CONSTANT_T);
        sflags[j] |= ACTION_SFLAG;
    }
    sflags[j] |= USED_SFLAG;

    INITAO(&AO);
    AO.value = svals[j];
    AO.marker = ACTION_MV;
    if (!glulx_mode) {
      AO.type = (module_switch)?LONG_CONSTANT_OT:SHORT_CONSTANT_OT;
      if (svals[j] >= 256) AO.type = LONG_CONSTANT_OT;
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

    if (module_switch)
        for (i=0; i<no_actions; i++) action_byte_offset[i] = 0;
    else
    for (i=0; i<no_actions; i++)
    {   strcpy(action_name, (char *) symbs[action_symbol[i]]);
        action_name[strlen(action_name) - 3] = '\0'; /* remove "__A" */
        strcpy(action_sub, action_name);
        strcat(action_sub, "Sub");
        j = symbol_index(action_sub, -1);
        if (sflags[j] & UNKNOWN_SFLAG)
        {
            error_named_at("No ...Sub action routine found for action:", action_name, slines[action_symbol[i]]);
        }
        else
        if (stypes[j] != ROUTINE_T)
        {
            error_named_at("No ...Sub action routine found for action:", action_name, slines[action_symbol[i]]);
            error_named_at("-- ...Sub symbol found, but not a routine:", action_sub, slines[j]);
        }
        else
        {   action_byte_offset[i] = svals[j];
            sflags[j] |= USED_SFLAG;
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

    if (no_adjectives >= MAX_ADJECTIVES)
        memoryerror("MAX_ADJECTIVES", MAX_ADJECTIVES);

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

    grammar_token_routine[l] = routine_address;
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
    while (p < English_verb_list_top)
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

static void register_verb(char *English_verb, int number)
{
    /*  Registers a new English verb as referring to the given Inform-verb
        number.  (See comments above for format of the list.)                */

    if (find_or_renumber_verb(English_verb, NULL) != -1)
    {   error_named("Two different verb definitions refer to", English_verb);
        return;
    }

    English_verb_list_size += strlen(English_verb)+4;
    if (English_verb_list_size >= MAX_VERBSPACE)
        memoryerror("MAX_VERBSPACE", MAX_VERBSPACE);

    English_verb_list_top[0] = 4+strlen(English_verb);
    English_verb_list_top[1] = number/256;
    English_verb_list_top[2] = number%256;
    strcpy(English_verb_list_top+3, English_verb);
    English_verb_list_top += English_verb_list_top[0];
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

static int grammar_line(int verbnum, int line)
{
    /*  Parse a grammar line, to be written into grammar_lines[mark] onward.

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

    /*  Have we run out of lines or token space?  */

    if (line >= MAX_LINES_PER_VERB)
    {   discard_token_location(beginning_debug_location);
        error("Too many lines of grammar for verb. This maximum is built \
into Inform, so suggest rewriting grammar using general parsing routines");
        return(FALSE);
    }

    /*  Internally, a line can be up to 3*32 + 1 + 2 = 99 bytes long  */
    /*  In Glulx, that's 5*32 + 4 = 164 bytes */

    mark = grammar_lines_top;
    if (!glulx_mode) {
        if (mark + 100 >= MAX_LINESPACE)
        {   discard_token_location(beginning_debug_location);
            memoryerror("MAX_LINESPACE", MAX_LINESPACE);
        }
    }
    else {
        if (mark + 165 >= MAX_LINESPACE)
        {   discard_token_location(beginning_debug_location);
            memoryerror("MAX_LINESPACE", MAX_LINESPACE);
        }
    }

    Inform_verbs[verbnum].l[line] = mark;

    if (!glulx_mode) {
        mark = mark + 2;
        TOKEN_SIZE = 3;
    }
    else {
        mark = mark + 3;
        TOKEN_SIZE = 5;
    }

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
                         || (stypes[token_value] != ROUTINE_T))
                     {   discard_token_location(beginning_debug_location);
                         ebf_error("routine name after 'noun='", token_text);
                         panic_mode_error_recovery();
                         return FALSE;
                     }
                     if (grammar_version_number == 1)
                         bytecode
                             = 16 + make_parsing_routine(svals[token_value]);
                     else
                     {   bytecode = 0x83;
                         wordcode = svals[token_value];
                     }
                     sflags[token_value] |= USED_SFLAG;
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
                     || (stypes[token_value] != ROUTINE_T))
                 {   discard_token_location(beginning_debug_location);
                     ebf_error("routine name after 'scope='", token_text);
                     panic_mode_error_recovery();
                     return FALSE;
                 }

                 if (grammar_version_number == 1)
                     bytecode = 80 +
                         make_parsing_routine(svals[token_value]);
                 else { bytecode = 0x85; wordcode = svals[token_value]; }
                 sflags[token_value] |= USED_SFLAG;
             }
        else if ((token_type == SEP_TT) && (token_value == SETEQUALS_SEP))
             {   discard_token_location(beginning_debug_location);
                 error("'=' is only legal here as 'noun=Routine'");
                 panic_mode_error_recovery();
                 return FALSE;
             }
        else {   /*  <attribute>  or  <general-parsing-routine>  tokens      */

                 if ((token_type != SYMBOL_TT)
                     || ((stypes[token_value] != ATTRIBUTE_T)
                         && (stypes[token_value] != ROUTINE_T)))
                 {   discard_token_location(beginning_debug_location);
                     error_named("No such grammar token as", token_text);
                     panic_mode_error_recovery();
                     return FALSE;
                 }
                 if (stypes[token_value]==ATTRIBUTE_T)
                 {   if (grammar_version_number == 1)
                         bytecode = 128 + svals[token_value];
                     else { bytecode = 4; wordcode = svals[token_value]; }
                 }
                 else
                 {   if (grammar_version_number == 1)
                         bytecode = 48 +
                             make_parsing_routine(svals[token_value]);
                     else { bytecode = 0x86; wordcode = svals[token_value]; }
                 }
                 sflags[token_value] |= USED_SFLAG;
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

    char *English_verbs_given[32]; int no_given = 0, i;

    directive_keywords.enabled = TRUE;

    get_next_token();

    if ((token_type == DIR_KEYWORD_TT) && (token_value == META_DK))
    {   meta_verb_flag = TRUE;
        get_next_token();
    }

    while ((token_type == DQ_TT) || (token_type == SQ_TT))
    {   English_verbs_given[no_given++] = token_text;
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
    {   Inform_verb = no_Inform_verbs;
        if (no_Inform_verbs == MAX_VERBS)
            memoryerror("MAX_VERBS",MAX_VERBS);
    }

    for (i=0; i<no_given; i++)
    {   dictionary_add(English_verbs_given[i],
            0x41 + ((meta_verb_flag)?0x02:0x00),
            (glulx_mode)?(0xffff-Inform_verb):(0xff-Inform_verb), 0);
        register_verb(English_verbs_given[i], Inform_verb);
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
    {   l = -1;
        if (no_Inform_verbs == MAX_VERBS)
            memoryerror("MAX_VERBS", MAX_VERBS);
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

        Inform_verbs[no_Inform_verbs] = Inform_verbs[Inform_verb];
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
    {   if (extend_mode == EXTEND_FIRST)
            for (k=l; k>0; k--)
                 Inform_verbs[Inform_verb].l[k+lines]
                     = Inform_verbs[Inform_verb].l[k-1+lines];
    } while (grammar_line(Inform_verb, lines++));

    if (extend_mode == EXTEND_FIRST)
    {   Inform_verbs[Inform_verb].lines = l+lines-1;
        for (k=0; k<l; k++)
            Inform_verbs[Inform_verb].l[k+lines-1]
                = Inform_verbs[Inform_verb].l[k+lines];
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
    action_byte_offset = NULL;
    grammar_token_routine = NULL;
    adjectives = NULL;
    adjective_sort_code = NULL;
    English_verb_list = NULL;

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
    Inform_verbs          = my_calloc(sizeof(verbt),   MAX_VERBS, "verbs");
    grammar_lines         = my_malloc(MAX_LINESPACE, "grammar lines");
    action_byte_offset    = my_calloc(sizeof(int32),   MAX_ACTIONS, "actions");
    action_symbol         = my_calloc(sizeof(int32),   MAX_ACTIONS,
                                "action symbols");
    grammar_token_routine = my_calloc(sizeof(int32),   MAX_ACTIONS,
                                "grammar token routines");
    adjectives            = my_calloc(sizeof(int32),   MAX_ADJECTIVES,
                                "adjectives");
    adjective_sort_code   = my_calloc(DICT_WORD_BYTES, MAX_ADJECTIVES,
                                "adjective sort codes");

    English_verb_list     = my_malloc(MAX_VERBSPACE, "register of verbs");
    English_verb_list_top = English_verb_list;
}

extern void verbs_free_arrays(void)
{
    my_free(&Inform_verbs, "verbs");
    my_free(&grammar_lines, "grammar lines");
    my_free(&action_byte_offset, "actions");
    my_free(&action_symbol, "action symbols");
    my_free(&grammar_token_routine, "grammar token routines");
    my_free(&adjectives, "adjectives");
    my_free(&adjective_sort_code, "adjective sort codes");
    my_free(&English_verb_list, "register of verbs");
}

/* ========================================================================= */
