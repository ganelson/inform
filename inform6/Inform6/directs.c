/* ------------------------------------------------------------------------- */
/*   "directs" : Directives (# commands)                                     */
/*                                                                           */
/*   Part of Inform 6.42                                                     */
/*   copyright (c) Graham Nelson 1993 - 2024                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

int no_routines,                   /* Number of routines compiled so far     */
    no_named_routines,             /* Number not embedded in objects         */
    no_termcs;                     /* Number of terminating characters       */
int terminating_characters[32];

brief_location routine_starts_line; /* Source code location where the current
                                      routine starts.  (Useful for reporting
                                      "unused variable" warnings on the start
                                      line rather than the end line.)        */

static int constant_made_yet;      /* Have any constants been defined yet?   */

#define MAX_IFDEF_STACK (32)
static int ifdef_stack[MAX_IFDEF_STACK], ifdef_sp;

/* ------------------------------------------------------------------------- */

static int ebf_error_recover(char *s1)
{
    /* Display an "expected... but found (current token)" error, then
       skim forward to the next semicolon and return FALSE. This is
       such a common case in parse_given_directive() that it's worth a
       utility function. You will see many error paths that look like:
          return ebf_error_recover(...);
    */
    ebf_curtoken_error(s1);
    panic_mode_error_recovery();
    return FALSE;
}

static int ebf_symbol_error_recover(char *s1, char *type, brief_location report_line)
{
    /* Same for ebf_symbol_error(). */
    ebf_symbol_error(s1, token_text, type, report_line);
    panic_mode_error_recovery();
    return FALSE;
}

/* ------------------------------------------------------------------------- */

extern int parse_given_directive(int internal_flag)
{   /*  Internal_flag is FALSE if the directive is encountered normally,
        TRUE if encountered with a # prefix inside a routine or object
        definition.

        Returns: FALSE if program continues, TRUE if end of file reached.    */

    int *trace_level = NULL; int32 i, j, k, n, flag;
    const char *constant_name;
    debug_location_beginning beginning_debug_location;

    if (internal_flag)
    {
        /* Only certain directives, such as #ifdef, are permitted within
           a routine or object definition. In older versions of Inform,
           nearly any directive was accepted, but this was -- to quote
           an old code comment -- "about as well-supported as Wile E. 
           Coyote one beat before the plummet-lines kick in." */
        
        if (token_value != IFV3_CODE && token_value != IFV5_CODE
            && token_value != IFDEF_CODE && token_value != IFNDEF_CODE
            && token_value != IFTRUE_CODE && token_value != IFFALSE_CODE
            && token_value != IFNOT_CODE && token_value != ENDIF_CODE
            && token_value != MESSAGE_CODE && token_value != ORIGSOURCE_CODE
            && token_value != TRACE_CODE) {
            char *dirname = directives.keywords[token_value];
            error_named("Cannot nest this directive inside a routine or object:", dirname);
            panic_mode_error_recovery(); return FALSE;
        }
    }
    
    switch(token_value)
    {

    /* --------------------------------------------------------------------- */
    /*   Abbreviate "string1" ["string2" ...]                                */
    /* --------------------------------------------------------------------- */

    case ABBREVIATE_CODE:

        do
        {  get_next_token();
           if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
               return FALSE;

           if (!glulx_mode && no_abbreviations==96)
           {   error_max_abbreviations(no_abbreviations);
               panic_mode_error_recovery(); return FALSE;
           }
           if (!glulx_mode && no_abbreviations==MAX_ABBREVS)
           {   error_max_abbreviations(no_abbreviations);
               /* This is no longer a memoryerror(); MAX_ABBREVS is an authoring decision for Z-code games. */
               panic_mode_error_recovery(); return FALSE;
           }

           if (abbrevs_lookup_table_made)
           {   error("All abbreviations must be declared together");
               panic_mode_error_recovery(); return FALSE;
           }
           if (token_type != DQ_TT)
           {   return ebf_error_recover("abbreviation string");
           }
           make_abbreviation(token_text);
        } while (TRUE);

    /* --------------------------------------------------------------------- */
    /*   Array <arrayname> [static] <array specification>                    */
    /* --------------------------------------------------------------------- */

    case ARRAY_CODE: make_array(); break;                  /* See "arrays.c" */

    /* --------------------------------------------------------------------- */
    /*   Attribute newname [alias oldname]                                   */
    /* --------------------------------------------------------------------- */

    case ATTRIBUTE_CODE:
        make_attribute(); break;                          /* See "objects.c" */

    /* --------------------------------------------------------------------- */
    /*   Class classname ...                                                 */
    /* --------------------------------------------------------------------- */

    case CLASS_CODE: 
        make_class(NULL);                                 /* See "objects.c" */
        return FALSE;

    /* --------------------------------------------------------------------- */
    /*   Constant newname [[=] value] [, ...]                                */
    /* --------------------------------------------------------------------- */

    case CONSTANT_CODE:
        constant_made_yet=TRUE;

      ParseConstantSpec:
        get_next_token(); i = token_value;
        beginning_debug_location = get_token_location_beginning();

        if (token_type != SYMBOL_TT)
        {   discard_token_location(beginning_debug_location);
            return ebf_error_recover("new constant name");
        }

        if (!(symbols[i].flags & (UNKNOWN_SFLAG + REDEFINABLE_SFLAG)))
        {   discard_token_location(beginning_debug_location);
            return ebf_symbol_error_recover("new constant name", typename(symbols[i].type), symbols[i].line);
        }

        assign_symbol(i, 0, CONSTANT_T);
        constant_name = token_text;

        get_next_token();

        if ((token_type == SEP_TT) && (token_value == COMMA_SEP))
        {   if (debugfile_switch && !(symbols[i].flags & REDEFINABLE_SFLAG))
            {   debug_file_printf("<constant>");
                debug_file_printf("<identifier>%s</identifier>", constant_name);
                write_debug_symbol_optional_backpatch(i);
                write_debug_locations(get_token_location_end(beginning_debug_location));
                debug_file_printf("</constant>");
            }
            goto ParseConstantSpec;
        }

        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
        {   if (debugfile_switch && !(symbols[i].flags & REDEFINABLE_SFLAG))
            {   debug_file_printf("<constant>");
                debug_file_printf("<identifier>%s</identifier>", constant_name);
                write_debug_symbol_optional_backpatch(i);
                write_debug_locations(get_token_location_end(beginning_debug_location));
                debug_file_printf("</constant>");
            }
            return FALSE;
        }

        if (!((token_type == SEP_TT) && (token_value == SETEQUALS_SEP)))
            put_token_back();

        {   assembly_operand AO = parse_expression(CONSTANT_CONTEXT);
            if (AO.marker != 0)
            {   assign_marked_symbol(i, AO.marker, AO.value,
                    CONSTANT_T);
                symbols[i].flags |= CHANGE_SFLAG;
                if (i == grammar_version_symbol)
                    error(
                "Grammar__Version must be given an explicit constant value");
            }
            else
            {   assign_symbol(i, AO.value, CONSTANT_T);
                if (i == grammar_version_symbol)
                {   if ((grammar_version_number != AO.value)
                        && (no_fake_actions > 0))
                        error(
                "Once a fake action has been defined it is too late to \
change the grammar version. (If you are using the library, move any \
Fake_Action directives to a point after the inclusion of \"Parser\".)");
                    grammar_version_number = AO.value;
                }
            }
        }

        if (debugfile_switch && !(symbols[i].flags & REDEFINABLE_SFLAG))
        {   debug_file_printf("<constant>");
            debug_file_printf("<identifier>%s</identifier>", constant_name);
            write_debug_symbol_optional_backpatch(i);
            write_debug_locations
                (get_token_location_end(beginning_debug_location));
            debug_file_printf("</constant>");
        }

        get_next_token();
        if ((token_type == SEP_TT) && (token_value == COMMA_SEP))
            goto ParseConstantSpec;
        put_token_back();
        break;

    /* --------------------------------------------------------------------- */
    /*   Default constantname integer                                        */
    /* --------------------------------------------------------------------- */

    case DEFAULT_CODE:
        get_next_token();
        if (token_type != SYMBOL_TT)
            return ebf_error_recover("name");

        i = -1;
        if (symbols[token_value].flags & UNKNOWN_SFLAG)
        {   i = token_value;
            symbols[i].flags |= DEFCON_SFLAG;
        }

        get_next_token();
        if (!((token_type == SEP_TT) && (token_value == SETEQUALS_SEP)))
            put_token_back();

        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            if (i != -1)
            {   if (AO.marker != 0)
                {   assign_marked_symbol(i, AO.marker, AO.value,
                        CONSTANT_T);
                    symbols[i].flags |= CHANGE_SFLAG;
                }
                else assign_symbol(i, AO.value, CONSTANT_T);
            }
        }

        break;

    /* --------------------------------------------------------------------- */
    /*   Dictionary 'word'                                                   */
    /*   Dictionary 'word' val1                                              */
    /*   Dictionary 'word' val1 val3                                         */
    /* --------------------------------------------------------------------- */

    case DICTIONARY_CODE:
        /* In Inform 5, this directive had the form
             Dictionary SYMBOL "word";
           This was deprecated as of I6 (if not earlier), and is no longer
           supported at all. The current form just creates a dictionary word,
           with the given values for dict_par1 and dict_par3. If the word
           already exists, the values are bit-or'd in with the existing
           values.
           (We don't offer a way to set dict_par2, because that is entirely
           reserved for the verb number. Or'ing values into it would create
           garbage.)
         */
        get_next_token();
        if (token_type != SQ_TT && token_type != DQ_TT)
            return ebf_error_recover("dictionary word");

        {
            char *wd = token_text;
            int val1 = 0;
            int val3 = 0;

            get_next_token();
            if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) {
                put_token_back();
            }
            else {
                assembly_operand AO;
                put_token_back();
                AO = parse_expression(CONSTANT_CONTEXT);
                if (AO.marker != 0)
                    error("A definite value must be given as a Dictionary flag");
                else
                    val1 = AO.value;

                get_next_token();
                if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) {
                    put_token_back();
                }
                else {
                    assembly_operand AO;
                    put_token_back();
                    if (ZCODE_LESS_DICT_DATA && !glulx_mode)
                        warning("The third dictionary field will be ignored because ZCODE_LESS_DICT_DATA is set");
                    AO = parse_expression(CONSTANT_CONTEXT);
                    if (AO.marker != 0)
                        error("A definite value must be given as a Dictionary flag");
                    else
                        val3 = AO.value;
                }
            }

            if (!glulx_mode) {
                if ((val1 & ~0xFF) || (val3 & ~0xFF)) {
                    warning("Dictionary flag values cannot exceed $FF in Z-code");
                }
            }
            else {
                if ((val1 & ~0xFFFF) || (val3 & ~0xFFFF)) {
                    warning("Dictionary flag values cannot exceed $FFFF in Glulx");
                }
            }

            dictionary_add(wd, val1, 0, val3);
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   End                                                                 */
    /* --------------------------------------------------------------------- */

    case END_CODE: return(TRUE);

    case ENDIF_CODE:
        if (ifdef_sp == 0) error("'Endif' without matching 'If...'");
        else ifdef_sp--;
        break;

    /* --------------------------------------------------------------------- */
    /*   Extend ...                                                          */
    /* --------------------------------------------------------------------- */

    case EXTEND_CODE: extend_verb(); return FALSE;         /* see "tables.c" */

    /* --------------------------------------------------------------------- */
    /*   Fake_Action name                                                    */
    /* --------------------------------------------------------------------- */

    case FAKE_ACTION_CODE:
        make_fake_action(); break;                          /* see "verbs.c" */

    /* --------------------------------------------------------------------- */
    /*   Global <variablename> [ [=] <value> ]                               */
    /* --------------------------------------------------------------------- */

    case GLOBAL_CODE: make_global(); break;                /* See "arrays.c" */

    /* --------------------------------------------------------------------- */
    /*   If...                                                               */
    /*                                                                       */
    /*   Note that each time Inform tests an If... condition, it stacks the  */
    /*   result (TRUE or FALSE) on ifdef_stack: thus, the top of this stack  */
    /*   reveals what clause of the current If... is being compiled:         */
    /*                                                                       */
    /*               If...;  ...  Ifnot;  ...  Endif;                        */
    /*   top of stack:       TRUE        FALSE                               */
    /*                                                                       */
    /*   This is used to detect "two Ifnots in same If" errors.              */
    /* --------------------------------------------------------------------- */

    case IFDEF_CODE:
        flag = TRUE;
        goto DefCondition;
    case IFNDEF_CODE:
        flag = FALSE;

      DefCondition:
        get_next_token();
        if (token_type != SYMBOL_TT)
            return ebf_error_recover("symbol name");

        /* Special case: a symbol of the form "VN_nnnn" is considered
           defined if the compiler version number is at least nnnn.
           Compiler version numbers look like "1640" for Inform 6.40;
           see RELEASE_NUMBER.
           ("VN_nnnn" isn't a real symbol and can't be used in other
           contexts.) */
        if ((token_text[0] == 'V')
            && (token_text[1] == 'N')
            && (token_text[2] == '_')
            && (strlen(token_text)==7))
        {
            char *endstr;
            i = strtol(token_text+3, &endstr, 10);
            if (*endstr == '\0') {
                /* All characters after the underscore were digits */
                if (VNUMBER < i) flag = (flag)?FALSE:TRUE;
                goto HashIfCondition;
            }
        }

        if (symbols[token_value].flags & UNKNOWN_SFLAG) flag = (flag)?FALSE:TRUE;
        else symbols[token_value].flags |= USED_SFLAG;
        goto HashIfCondition;

    case IFNOT_CODE:
        if (ifdef_sp == 0)
            error("'Ifnot' without matching 'If...'");
        else
        if (!(ifdef_stack[ifdef_sp-1]))
            error("Second 'Ifnot' for the same 'If...' condition");
        else
        {   dont_enter_into_symbol_table = -2; n = 1;
            directives.enabled = TRUE;
            do
            {
                release_token_texts();
                get_next_token();
                if (token_type == EOF_TT)
                {   error("End of file reached in code 'If...'d out");
                    directives.enabled = FALSE;
                    return TRUE;
                }
                if (token_type == DIRECTIVE_TT)
                {
                    switch(token_value)
                    {   case ENDIF_CODE:
                            n--; break;
                        case IFV3_CODE:
                        case IFV5_CODE:
                        case IFDEF_CODE:
                        case IFNDEF_CODE:
                        case IFTRUE_CODE:
                        case IFFALSE_CODE:
                            n++; break;
                        case IFNOT_CODE:
                            if (n == 1)
                            {   error(
                              "Second 'Ifnot' for the same 'If...' condition");
                                break;
                            }
                    }
                }
            } while (n > 0);
            ifdef_sp--; 
            dont_enter_into_symbol_table = FALSE;
            directives.enabled = FALSE;
        }
        break;

    case IFV3_CODE:
        flag = FALSE;
        if (!glulx_mode && version_number <= 3) flag = TRUE;
        goto HashIfCondition;

    case IFV5_CODE:
        flag = TRUE;
        if (!glulx_mode && version_number <= 3) flag = FALSE;
        goto HashIfCondition;

    case IFTRUE_CODE:
        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            if (AO.marker != 0)
            {   error("This condition can't be determined");
                flag = 0;
            }
            else flag = (AO.value != 0);
        }
        goto HashIfCondition;

    case IFFALSE_CODE:
        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            if (AO.marker != 0)
            {   error("This condition can't be determined");
                flag = 1;
            }
            else flag = (AO.value == 0);
        }
        goto HashIfCondition;

    HashIfCondition:
        get_next_token();
        if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
            return ebf_error_recover("semicolon after 'If...' condition");

        if (ifdef_sp >= MAX_IFDEF_STACK) {
            error("'If' directives nested too deeply");
            panic_mode_error_recovery(); return FALSE;
        }
        
        if (flag)
        {   ifdef_stack[ifdef_sp++] = TRUE; return FALSE; }
        else
        {   dont_enter_into_symbol_table = -2; n = 1;
            directives.enabled = TRUE;
            do
            {
                release_token_texts();
                get_next_token();
                if (token_type == EOF_TT)
                {   error("End of file reached in code 'If...'d out");
                    directives.enabled = FALSE;
                    return TRUE;
                }
                if (token_type == DIRECTIVE_TT)
                {
                    switch(token_value)
                    {   case ENDIF_CODE:
                            n--; break;
                        case IFV3_CODE:
                        case IFV5_CODE:
                        case IFDEF_CODE:
                        case IFNDEF_CODE:
                        case IFTRUE_CODE:
                        case IFFALSE_CODE:
                            n++; break;
                        case IFNOT_CODE:
                            if (n == 1)
                            {   ifdef_stack[ifdef_sp++] = FALSE;
                                n--; break;
                            }
                    }
                }
            } while (n > 0);
            directives.enabled = FALSE;
            dont_enter_into_symbol_table = FALSE;
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   Import global <varname> [, ...]                                     */
    /* --------------------------------------------------------------------- */

    case IMPORT_CODE:
        error("The 'Import' directive is no longer supported.");
        break;

    /* --------------------------------------------------------------------- */
    /*   Include "[>]filename"                                               */
    /*                                                                       */
    /* The ">" character means to load the file from the same directory as   */
    /* the current file, instead of relying on the include path.             */
    /* --------------------------------------------------------------------- */

    case INCLUDE_CODE:
        get_next_token();
        if (token_type != DQ_TT)
            return ebf_error_recover("filename in double-quotes");

        {   char *name = token_text;

            get_next_token();
            if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
                ebf_curtoken_error("semicolon ';' after Include filename");

            if (strcmp(name, "language__") == 0)
                 load_sourcefile(Language_Name, 0);
            else if (name[0] == '>')
                 load_sourcefile(name+1, 1);
            else load_sourcefile(name, 0);
            return FALSE;
        }

    /* --------------------------------------------------------------------- */
    /*   Link "filename"                                                     */
    /* --------------------------------------------------------------------- */

    case LINK_CODE:
        get_next_token();
        error("The 'Link' directive is no longer supported.");
        break;

    /* --------------------------------------------------------------------- */
    /*   Lowstring constantname "text of string"                             */
    /* --------------------------------------------------------------------- */
    /* Unlike most constant creations, these do not require backpatching:    */
    /* the low strings always occupy a table at a fixed offset in the        */
    /* Z-machine (after the abbreviations table has finished, at 0x100).     */
    /* --------------------------------------------------------------------- */

    case LOWSTRING_CODE:
        if (glulx_mode) {
            error("The LowString directive has no meaning in Glulx.");
            panic_mode_error_recovery(); return FALSE;
        }
        get_next_token(); i = token_value;
        if (token_type != SYMBOL_TT)
            return ebf_error_recover("new low string name");
        if (!(symbols[i].flags & UNKNOWN_SFLAG))
            return ebf_symbol_error_recover("new low string name", typename(symbols[i].type), symbols[i].line);

        get_next_token();
        if (token_type != DQ_TT)
            return ebf_error_recover("literal string in double-quotes");

        assign_symbol(i, compile_string(token_text, STRCTX_LOWSTRING), CONSTANT_T);
        break;

    /* --------------------------------------------------------------------- */
    /*   Message | "information"                                             */
    /*           | error "error message"                                     */
    /*           | fatalerror "fatal error message"                          */
    /*           | warning "warning message"                                 */
    /* --------------------------------------------------------------------- */

    case MESSAGE_CODE:
        directive_keywords.enabled = TRUE;
        get_next_token();
        directive_keywords.enabled = FALSE;
        if (token_type == DQ_TT)
        {   int i;
            if (hash_printed_since_newline) printf("\n");
            for (i=0; token_text[i]!=0; i++)
            {   if (token_text[i] == '^') printf("\n");
                else
                if (token_text[i] == '~') printf("\"");
                else printf("%c", token_text[i]);
            }
            printf("\n");
            break;
        }
        if ((token_type == DIR_KEYWORD_TT) && (token_value == ERROR_DK))
        {   get_next_token();
            if (token_type != DQ_TT)
            {   return ebf_error_recover("error message in double-quotes");
            }
            error(token_text); break;
        }
        if ((token_type == DIR_KEYWORD_TT) && (token_value == FATALERROR_DK))
        {   get_next_token();
            if (token_type != DQ_TT)
            {   return ebf_error_recover("fatal error message in double-quotes");
            }
            fatalerror(token_text); break;
        }
        if ((token_type == DIR_KEYWORD_TT) && (token_value == WARNING_DK))
        {   get_next_token();
            if (token_type != DQ_TT)
            {   return ebf_error_recover("warning message in double-quotes");
            }
            warning(token_text); break;
        }
        return ebf_error_recover("a message in double-quotes, 'error', 'fatalerror' or 'warning'");
        break;

    /* --------------------------------------------------------------------- */
    /*   Nearby objname "short name" ...                                     */
    /* --------------------------------------------------------------------- */

    case NEARBY_CODE:
        make_object(TRUE, NULL, -1, -1, -1);
        return FALSE;                                     /* See "objects.c" */

    /* --------------------------------------------------------------------- */
    /*   Object objname "short name" ...                                     */
    /* --------------------------------------------------------------------- */

    case OBJECT_CODE:
        make_object(FALSE, NULL, -1, -1, -1);
        return FALSE;                                     /* See "objects.c" */

    /* --------------------------------------------------------------------- */
    /*   Origsource <file>                                                   */
    /*   Origsource <file> <line>                                            */
    /*   Origsource <file> <line> <char>                                     */
    /*   Origsource                                                          */
    /*                                                                       */
    /*   The first three forms declare that all following lines are derived  */
    /*   from the named Inform 7 source file (with an optional line number   */
    /*   and character number). This will be reported in error messages and  */
    /*   in debug output. The declaration holds through the next Origsource  */
    /*   directive (but does not apply to included files).                   */
    /*                                                                       */
    /*   The fourth form, with no arguments, clears the declaration.         */
    /*                                                                       */
    /*   Unlike the Include directive, Origsource does not open the named    */
    /*   file or even verify that it exists. The filename is treated as an   */
    /*   opaque string.                                                      */
    /* --------------------------------------------------------------------- */

    case ORIGSOURCE_CODE:
        {
            char *origsource_file = NULL;
            int32 origsource_line = 0;
            int32 origsource_char = 0;

            /* Parse some optional tokens followed by a mandatory semicolon. */

            get_next_token();
            if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))) {
                if (token_type != DQ_TT) {
                    return ebf_error_recover("a file name in double-quotes");
                }
                origsource_file = token_text;

                get_next_token();
                if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))) {
                    if (token_type != NUMBER_TT) {
                        return ebf_error_recover("a file line number");
                    }
                    origsource_line = token_value;
                    if (origsource_line < 0)
                        origsource_line = 0;

                    get_next_token();
                    if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))) {
                        if (token_type != NUMBER_TT) {
                            return ebf_error_recover("a file line number");
                        }
                        origsource_char = token_value;
                        if (origsource_char < 0)
                            origsource_char = 0;
                        
                        get_next_token();
                    }
                }
            }

            put_token_back();

            set_origsource_location(origsource_file, origsource_line, origsource_char);
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   Property [long] [additive] name                                     */
    /*   Property [long] [additive] name alias oldname                       */
    /*   Property [long] [additive] name defaultvalue                        */
    /*   Property [long] individual name                                     */
    /* --------------------------------------------------------------------- */

    case PROPERTY_CODE: make_property(); break;           /* See "objects.c" */

    /* --------------------------------------------------------------------- */
    /*   Release <number>                                                    */
    /* --------------------------------------------------------------------- */

    case RELEASE_CODE:
        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            if (AO.marker != 0)
                error("A definite value must be given as release number");
            else
                release_number = AO.value;
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   Replace routine [routinename]                                       */
    /* --------------------------------------------------------------------- */

    case REPLACE_CODE:
        /* You can also replace system functions normally implemented in     */
        /* the "hardware" of the Z-machine, like "random()":                 */

        system_functions.enabled = TRUE;
        directives.enabled = FALSE;
        directive_keywords.enabled = FALSE;

        /* Don't count the upcoming symbol as a top-level reference
           *to* the function. */
        df_dont_note_global_symbols = TRUE;
        get_next_token();
        df_dont_note_global_symbols = FALSE;
        if (token_type == SYSFUN_TT)
        {   if (system_function_usage[token_value] == 1)
                error("You can't 'Replace' a system function already used");
            else system_function_usage[token_value] = 2;
            get_next_token();
            if (!((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)))
            {
                error("You can't give a 'Replace'd system function a new name");
                panic_mode_error_recovery(); return FALSE;
            }
            return FALSE;
        }

        if (token_type != SYMBOL_TT)
            return ebf_error_recover("name of routine to replace");
        if (!(symbols[token_value].flags & UNKNOWN_SFLAG))
            return ebf_error_recover("name of routine not yet defined");

        symbols[token_value].flags |= REPLACE_SFLAG;

        /* If a second symbol is provided, it will refer to the
           original (replaced) definition of the routine. */
        i = token_value;

        system_functions.enabled = FALSE;
        df_dont_note_global_symbols = TRUE;
        get_next_token();
        df_dont_note_global_symbols = FALSE;
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP))
        {   return FALSE;
        }

        if (token_type != SYMBOL_TT || !(symbols[token_value].flags & UNKNOWN_SFLAG))
            return ebf_error_recover("semicolon ';' or new routine name");

        /* Define the original-form symbol as a zero constant. Its
           value will be overwritten later, when we define the
           replacement. */
        assign_symbol(token_value, 0, CONSTANT_T);
        add_symbol_replacement_mapping(i, token_value);

        break;

    /* --------------------------------------------------------------------- */
    /*   Serial "yymmdd"                                                     */
    /* --------------------------------------------------------------------- */

    case SERIAL_CODE:
        get_next_token();
        if ((token_type != DQ_TT) || (strlen(token_text)!=6))
        {   error("The serial number must be a 6-digit date in double-quotes");
            panic_mode_error_recovery(); return FALSE;
        }
        for (i=0; i<6; i++) if (isdigit(token_text[i])==0)
        {   error("The serial number must be a 6-digit date in double-quotes");
            panic_mode_error_recovery(); return FALSE;
        }
        strcpy(serial_code_buffer, token_text);
        serial_code_given_in_program = TRUE;
        break;

    /* --------------------------------------------------------------------- */
    /*   Statusline score/time                                               */
    /* --------------------------------------------------------------------- */

    case STATUSLINE_CODE:
        directive_keywords.enabled = TRUE;
        get_next_token();
        directive_keywords.enabled = FALSE;
        if ((token_type != DIR_KEYWORD_TT)
            || ((token_value != SCORE_DK) && (token_value != TIME_DK)))
            return ebf_error_recover("'score' or 'time' after 'statusline'");
        if (token_value == SCORE_DK) statusline_flag = SCORE_STYLE;
        else statusline_flag = TIME_STYLE;
        break;

    /* --------------------------------------------------------------------- */
    /*   Stub routinename number-of-locals                                   */
    /* --------------------------------------------------------------------- */

    case STUB_CODE:
        /* The upcoming symbol is a definition; don't count it as a
           top-level reference *to* the stub function. */
        df_dont_note_global_symbols = TRUE;
        get_next_token();
        df_dont_note_global_symbols = FALSE;
        if (token_type != SYMBOL_TT)
            return ebf_error_recover("routine name to stub");

        i = token_value; flag = FALSE;

        if (symbols[i].flags & UNKNOWN_SFLAG)
        {   symbols[i].flags |= STUB_SFLAG;
            flag = TRUE;
        }

        get_next_token(); k = token_value;
        if (token_type != NUMBER_TT)
            return ebf_error_recover("number of local variables");
        if ((k>4) || (k<0))
        {   error("Must specify 0 to 4 local variables for 'Stub' routine");
            k = 0;
        }

        if (flag)
        {
            /*  Give these parameter-receiving local variables names
                for the benefit of the debugging information file,
                and for assembly tracing to look sensible.
                (We don't set local_variable.keywords because we're not
                going to be parsing any code.)                               */

            clear_local_variables();
            if (k >= 1) add_local_variable("dummy1");
            if (k >= 2) add_local_variable("dummy2");
            if (k >= 3) add_local_variable("dummy3");
            if (k >= 4) add_local_variable("dummy4");

            assign_symbol(i,
                assemble_routine_header(FALSE, symbols[i].name, FALSE, i),
                ROUTINE_T);

            /*  Ensure the return value of a stubbed routine is false,
                since this is necessary to make the library work properly    */

            if (!glulx_mode)
                assemblez_0(rfalse_zc);
            else
                assembleg_1(return_gc, zero_operand);

            /*  Inhibit "local variable unused" warnings  */

            for (i=1; i<=k; i++) variables[i].usage = 1;
            sequence_point_follows = FALSE;
            assemble_routine_end(FALSE, get_token_locations());
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   Switches switchblock                                                */
    /* (this directive is ignored if the -i switch was set at command line)  */
    /* --------------------------------------------------------------------- */

    case SWITCHES_CODE:
        dont_enter_into_symbol_table = TRUE;
        get_next_token();
        dont_enter_into_symbol_table = FALSE;
        if (token_type != UQ_TT)
            return ebf_error_recover("string of switches");
        if (!ignore_switches_switch)
        {
            if (constant_made_yet) {
                error("A 'Switches' directive must must come before the first constant definition");
                break;
            }
            if (no_routines > 1)
            {
                /* The built-in Main__ routine is number zero. */
                error("A 'Switches' directive must come before the first routine definition.");
                break;
            }
            obsolete_warning("the Switches directive is deprecated and may produce incorrect results. Use command-line arguments or header comments.");
            switches(token_text, 0);                       /* see "inform.c" */
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   System_file                                                         */
    /*                                                                       */
    /* Some files are declared as "system files": this information is used   */
    /* by Inform only to skip the definition of a routine X if the designer  */
    /* has indicated his intention to Replace X.                             */
    /* --------------------------------------------------------------------- */

    case SYSTEM_CODE:
        declare_systemfile(); break;                        /* see "files.c" */

    /* --------------------------------------------------------------------- */
    /*   Trace dictionary   [on/NUM]                                         */
    /*         objects      [on/NUM]                                         */
    /*         symbols      [on/NUM]                                         */
    /*         verbs        [on/NUM]                                         */
    /*                      [on/off/NUM]      {same as "assembly"}           */
    /*         assembly     [on/off/NUM]                                     */
    /*         expressions  [on/off/NUM]                                     */
    /*         lines        [on/off/NUM]      {not supported}                */
    /*         tokens       [on/off/NUM]                                     */
    /*         linker       [on/off/NUM]      {not supported}                */
    /*                                                                       */
    /* The first four trace commands immediately display a compiler table.   */
    /* The rest set or clear an ongoing trace.                               */
    /* --------------------------------------------------------------------- */

    case TRACE_CODE:
        directives.enabled = FALSE;
        trace_keywords.enabled = TRUE;
        get_next_token();
        trace_keywords.enabled = FALSE;
        directives.enabled = TRUE;
        
        if ((token_type == SEP_TT) && (token_value == SEMICOLON_SEP)) {
            /* "Trace;" */
            put_token_back();
            i = ASSEMBLY_TK;
            trace_level = &asm_trace_level;
            j = 1;
            goto HandleTraceKeyword;
        }
        if (token_type == NUMBER_TT) {
            /* "Trace NUM;" */
            i = ASSEMBLY_TK;
            trace_level = &asm_trace_level;
            j = token_value;
            goto HandleTraceKeyword;
        }

        /* Anything else must be "Trace KEYWORD..." Remember that
           'on' and 'off' are trace keywords. */
        
        if (token_type != TRACE_KEYWORD_TT)
            return ebf_error_recover("debugging keyword");

        trace_keywords.enabled = TRUE;

        /* Note that "Trace verbs" doesn't affect list_verbs_setting.
           It shows the grammar at this point in the code. Setting
           list_verbs_setting shows the grammar at the end of 
           compilation.
           Same goes for "Trace dictionary" and list_dict_setting, etc. */
        
        i = token_value;

        switch(i)
        {
        case ASSEMBLY_TK:
            trace_level = &asm_trace_level;  break;
        case EXPRESSIONS_TK:
            trace_level = &expr_trace_level; break;
        case TOKENS_TK:
            trace_level = &tokens_trace_level; break;
        case DICTIONARY_TK:
        case SYMBOLS_TK:
        case OBJECTS_TK:
        case VERBS_TK:
            /* show a table rather than changing any trace level */
            trace_level = NULL; break;
        case LINES_TK:
            /* never implememented */
            trace_level = NULL; break;
        case LINKER_TK:
            /* no longer implememented */
            trace_level = NULL; break;
        default:
            /* default to "Trace assembly" */
            put_token_back();
            trace_level = &asm_trace_level; break;
        }
        
        j = 1;
        get_next_token();
        if ((token_type == SEP_TT) &&
            (token_value == SEMICOLON_SEP))
        {   put_token_back();
        }
        else if (token_type == NUMBER_TT)
        {   j = token_value;
        }
        else if ((token_type == TRACE_KEYWORD_TT) && (token_value == ON_TK))
        {   j = 1;
        }
        else if ((token_type == TRACE_KEYWORD_TT) && (token_value == OFF_TK))
        {   j = 0;
        }
        else
        {   put_token_back();
        }

        trace_keywords.enabled = FALSE;

        HandleTraceKeyword:

        if (i == LINES_TK || i == LINKER_TK) {
            warning_named("Trace option is not supported:", trace_keywords.keywords[i]);
            break;
        }
        
        if (trace_level == NULL && j == 0) {
            warning_named("Trace directive to display table at 'off' level has no effect: table", trace_keywords.keywords[i]);
            break;
        }
        
        switch(i)
        {   case DICTIONARY_TK: show_dictionary(j);  break;
            case OBJECTS_TK:    list_object_tree();  break;
            case SYMBOLS_TK:    list_symbols(j);     break;
            case VERBS_TK:      list_verb_table();   break;
            default:
                if (trace_level)
                    *trace_level = j;
                break;
        }
        break;

    /* --------------------------------------------------------------------- */
    /*   Undef symbol                                                        */
    /* --------------------------------------------------------------------- */

    case UNDEF_CODE:
        get_next_token();
        if (token_type != SYMBOL_TT)
            return ebf_error_recover("symbol name");

        if (symbols[token_value].flags & UNKNOWN_SFLAG)
        {   break; /* undef'ing an undefined constant is okay */
        }

        if (symbols[token_value].type != CONSTANT_T)
        {   error_named("Cannot Undef a symbol which is not a defined constant:", symbols[token_value].name);
            break;
        }

        if (debugfile_switch)
        {   write_debug_undef(token_value);
        }
        /* We remove it from the symbol table. But previous uses of the symbol
           were valid, so we don't set neverused true. We also mark it
           USED so that it can't trigger "symbol not used" warnings. */
        end_symbol_scope(token_value, FALSE);
        symbols[token_value].flags |= USED_SFLAG;
        break;

    /* --------------------------------------------------------------------- */
    /*   Verb ...                                                            */
    /* --------------------------------------------------------------------- */

    case VERB_CODE: make_verb(); return FALSE;             /* see "tables.c" */

    /* --------------------------------------------------------------------- */
    /*   Version <number>                                                    */
    /* --------------------------------------------------------------------- */

    case VERSION_CODE:

        {   assembly_operand AO;
            AO = parse_expression(CONSTANT_CONTEXT);
            /* If a version has already been set on the command line,
               that overrides this. */
            if (version_set_switch)
            {
              warning("The Version directive was overridden by a command-line argument.");
              break;
            }

            if (AO.marker != 0)
            {
              error("A definite value must be given as version number.");
              break;
            }
            else if (no_routines > 1)
            {
              /* The built-in Main__ routine is number zero. */
              error("A 'Version' directive must come before the first routine definition.");
              break;
            }
            else if (glulx_mode) 
            {
              warning("The Version directive does not work in Glulx. Use \
-vX.Y.Z instead, as either a command-line argument or a header comment.");
              break;
            }
            else
            {
                int debtok;
                i = AO.value;
                if ((i<3) || (i>8))
                {   error("The version number must be in the range 3 to 8");
                    break;
                }
                obsolete_warning("the Version directive is deprecated and may produce incorrect results. Use -vN instead, as either a command-line argument or a header comment.");
                select_version(i);
                /* We must now do a small dance to reset the DICT_ENTRY_BYTES
                   constant, which was defined at startup based on the Z-code
                   version.
                   The calculation here is repeated from select_target(). */
                DICT_ENTRY_BYTE_LENGTH = ((version_number==3)?7:9) - (ZCODE_LESS_DICT_DATA?1:0);
                debtok = get_symbol_index("DICT_ENTRY_BYTES");
                if (debtok >= 0 && !(symbols[debtok].flags & UNKNOWN_SFLAG))
                {
                    if (!(symbols[debtok].flags & REDEFINABLE_SFLAG))
                    {
                        warning("The DICT_ENTRY_BYTES symbol is not marked redefinable");
                    }
                    /* Redefine the symbol... */
                    assign_symbol(debtok, DICT_ENTRY_BYTE_LENGTH, CONSTANT_T);
                }
            }
        }
        break;                                             /* see "inform.c" */

    /* --------------------------------------------------------------------- */
    /*   Zcharacter table <num> ...                                          */
    /*   Zcharacter table + <num> ...                                        */
    /*   Zcharacter <string> <string> <string>                               */
    /*   Zcharacter <char>                                                   */
    /* --------------------------------------------------------------------- */

    case ZCHARACTER_CODE:

        if (glulx_mode) {
            error("The Zcharacter directive has no meaning in Glulx.");
            panic_mode_error_recovery(); return FALSE;
        }

        directive_keywords.enabled = TRUE;
        get_next_token();
        directive_keywords.enabled = FALSE;

        switch(token_type)
        {   case DQ_TT:
                new_alphabet(token_text, 0);
                get_next_token();
                if (token_type != DQ_TT)
                    return ebf_error_recover("double-quoted alphabet string");
                new_alphabet(token_text, 1);
                get_next_token();
                if (token_type != DQ_TT)
                    return ebf_error_recover("double-quoted alphabet string");
                new_alphabet(token_text, 2);
            break;

            case SQ_TT:
                map_new_zchar(text_to_unicode(token_text));
                if (token_text[textual_form_length] != 0)
                    return ebf_error_recover("single character value");
            break;

            case DIR_KEYWORD_TT:
            switch(token_value)
            {   case TABLE_DK:
                {   int plus_flag = FALSE;
                    get_next_token();
                    if ((token_type == SEP_TT) && (token_value == PLUS_SEP))
                    {   plus_flag = TRUE;
                        get_next_token();
                    }
                    while ((token_type!=SEP_TT) || (token_value!=SEMICOLON_SEP))
                    {   switch(token_type)
                        {   case NUMBER_TT:
                                new_zscii_character(token_value, plus_flag);
                                plus_flag = TRUE; break;
                            case SQ_TT:
                                new_zscii_character(text_to_unicode(token_text),
                                    plus_flag);
                                if (token_text[textual_form_length] != 0)
                                    return ebf_error_recover("single character value");
                                plus_flag = TRUE;
                                break;
                            default:
                                return ebf_error_recover("character or Unicode number");
                        }
                        get_next_token();
                    }
                    if (plus_flag) new_zscii_finished();
                    put_token_back();
                }
                    break;
                case TERMINATING_DK:
                    get_next_token();
                    while ((token_type!=SEP_TT) || (token_value!=SEMICOLON_SEP))
                    {   switch(token_type)
                        {   case NUMBER_TT:
                                terminating_characters[no_termcs++]
                                    = token_value;
                                break;
                            default:
                                return ebf_error_recover("ZSCII number");
                        }
                        get_next_token();
                    }
                    put_token_back();
                    break;
                default:
                    return ebf_error_recover("'table', 'terminating', \
a string or a constant");
            }
                break;
            default:
                return ebf_error_recover("three alphabet strings, \
a 'table' or 'terminating' command or a single character");
        }
        break;

    /* ===================================================================== */

    }

    /* We are now at the end of a syntactically valid directive. It
       should be terminated by a semicolon. */

    get_next_token();
    if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
    {   ebf_curtoken_error("';'");
        /* Put the non-semicolon back. We will continue parsing from
           that point, in hope that it's the start of a new directive.
           (This recovers cleanly from a missing semicolon at the end
           of a directive. It's not so clean if the directive *does*
           end with a semicolon, but there's extra garbage before it.) */
        put_token_back();
    }
    return FALSE;
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_directs_vars(void)
{
}

extern void directs_begin_pass(void)
{   no_routines = 0;
    no_named_routines = 0;
    no_termcs = 0;
    constant_made_yet = FALSE;
    ifdef_sp = 0;
}

extern void directs_allocate_arrays(void)
{
}

extern void directs_free_arrays(void)
{
}

/* ========================================================================= */
