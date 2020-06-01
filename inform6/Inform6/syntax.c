/* ------------------------------------------------------------------------- */
/*   "syntax" : Syntax analyser and compiler                                 */
/*                                                                           */
/*   Part of Inform 6.34                                                     */
/*   copyright (c) Graham Nelson 1993 - 2020                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

static char *lexical_source;

int no_syntax_lines;                                  /*  Syntax line count  */

static void begin_syntax_line(int statement_mode)
{   no_syntax_lines++;
    next_token_begins_syntax_line = TRUE;

    clear_expression_space();
    if (statement_mode)
    {   statements.enabled = TRUE;
        conditions.enabled = TRUE;
        local_variables.enabled = TRUE;
        system_functions.enabled = TRUE;

        misc_keywords.enabled = FALSE;
        directive_keywords.enabled = FALSE;
        directives.enabled = FALSE;
        segment_markers.enabled = FALSE;
        opcode_names.enabled = FALSE;
    }
    else
    {   directives.enabled = TRUE;
        segment_markers.enabled = TRUE;

        statements.enabled = FALSE;
        misc_keywords.enabled = FALSE;
        directive_keywords.enabled = FALSE;
        local_variables.enabled = FALSE;
        system_functions.enabled = FALSE;
        conditions.enabled = FALSE;
        opcode_names.enabled = FALSE;
    }

    sequence_point_follows = TRUE;

    if (debugfile_switch)
    {   get_next_token();
        statement_debug_location = get_token_location();
        put_token_back();
    }
}

extern void panic_mode_error_recovery(void)
{
    /* Consume tokens until the next semicolon (or end of file).
       This is typically called after a syntax error, in hopes of
       getting parsing back on track. */

    while ((token_type != EOF_TT)
           && ((token_type != SEP_TT)||(token_value != SEMICOLON_SEP)))

        get_next_token();
}

extern void get_next_token_with_directives(void)
{
    /* A higher-level version of get_next_token(), which detects and
       obeys directives such as #ifdef/#ifnot/#endif. (The # sign is
       required in this case.)

       This is called while parsing a long construct, such as Class or
       Object, where we want to support internal #ifdefs. (Although
       function-parsing predates this and doesn't make use of it.)

       (Technically this permits *any* #-directive, which means you
       can define global variables or properties or what-have-you in
       the middle of an object. You can do that in the middle of an
       object, too. Don't. It's about as well-supported as Wile E.
       Coyote one beat before the plummet-lines kick in.) */

    int directives_save, segment_markers_save, statements_save;

    while (TRUE)
    {
        get_next_token();

        /* If the first token is not a '#', return it directly. */
        if ((token_type != SEP_TT) || (token_value != HASH_SEP))
            return;

        /* Save the lexer flags, and set up for directive parsing. */
        directives_save = directives.enabled;
        segment_markers_save = segment_markers.enabled;
        statements_save = statements.enabled;

        directives.enabled = TRUE;
        segment_markers.enabled = FALSE;
        statements.enabled = FALSE;
        conditions.enabled = FALSE;
        local_variables.enabled = FALSE;
        misc_keywords.enabled = FALSE;
        system_functions.enabled = FALSE;

        get_next_token();

        if ((token_type == SEP_TT) && (token_value == OPEN_SQUARE_SEP))
        {   error("It is illegal to nest a routine inside an object using '#['");
            return;
        }

        if (token_type == DIRECTIVE_TT)
            parse_given_directive(TRUE);
        else
        {   ebf_error("directive", token_text);
            return;
        }

        /* Restore all the lexer flags. (We are squashing several of them
           into a single save variable, which I think is safe because that's
           what CKnight did.)
        */
        directive_keywords.enabled = FALSE;
        directives.enabled = directives_save;
        segment_markers.enabled = segment_markers_save;
        statements.enabled =
            conditions.enabled =
            local_variables.enabled =
            misc_keywords.enabled = 
            system_functions.enabled = statements_save;
    }
}

extern void parse_program(char *source)
{
    lexical_source = source;
    while (parse_directive(FALSE)) ;
}

extern int parse_directive(int internal_flag)
{
    /*  Internal_flag is FALSE if the directive is encountered normally,
        TRUE if encountered with a # prefix inside a routine or object
        definition.

        Returns: TRUE if program continues, FALSE if end of file reached.    */

    int routine_symbol, rep_symbol;
    int is_renamed;

    begin_syntax_line(FALSE);
    get_next_token();

    if (token_type == EOF_TT) return(FALSE);

    if ((token_type == SEP_TT) && (token_value == HASH_SEP))
        get_next_token();

    if ((token_type == SEP_TT) && (token_value == OPEN_SQUARE_SEP))
    {   if (internal_flag)
        {   error("It is illegal to nest routines using '#['");
            return(TRUE);
        }

        directives.enabled = FALSE;
        directive_keywords.enabled = FALSE;
        segment_markers.enabled = FALSE;

        /* The upcoming symbol is a definition; don't count it as a
           top-level reference *to* the function. */
        df_dont_note_global_symbols = TRUE;
        get_next_token();
        df_dont_note_global_symbols = FALSE;
        if ((token_type != SYMBOL_TT)
            || ((!(sflags[token_value] & UNKNOWN_SFLAG))
                && (!(sflags[token_value] & REPLACE_SFLAG))))
        {   ebf_error("routine name", token_text);
            return(FALSE);
        }

        routine_symbol = token_value;

        rep_symbol = routine_symbol;
        is_renamed = find_symbol_replacement(&rep_symbol);

        if ((sflags[routine_symbol] & REPLACE_SFLAG) 
            && !is_renamed && (is_systemfile()))
        {   /* The function is definitely being replaced (system_file
               always loses priority in a replacement) but is not
               being renamed to something else. Skip its definition
               entirely. */
            dont_enter_into_symbol_table = TRUE;
            do
            {   get_next_token();
            } while (!((token_type == EOF_TT)
                     || ((token_type==SEP_TT)
                         && (token_value==CLOSE_SQUARE_SEP))));
            dont_enter_into_symbol_table = FALSE;
            if (token_type == EOF_TT) return FALSE;
        }
        else
        {   /* Parse the function definition and assign its symbol. */
            assign_symbol(routine_symbol,
                parse_routine(lexical_source, FALSE,
                    (char *) symbs[routine_symbol], FALSE, routine_symbol),
                ROUTINE_T);
            slines[routine_symbol] = routine_starts_line;
        }

        if (is_renamed) {
            /* This function was subject to a "Replace X Y" directive.
               The first time we see a definition for symbol X, we
               copy it to Y -- that's the "original" form of the
               function. */
            if (svals[rep_symbol] == 0) {
                assign_symbol(rep_symbol, svals[routine_symbol], ROUTINE_T);
            }
        }

        get_next_token();
        if ((token_type != SEP_TT) || (token_value != SEMICOLON_SEP))
        {   ebf_error("';' after ']'", token_text);
            put_token_back();
        }
        return TRUE;
    }

    if ((token_type == SYMBOL_TT) && (stypes[token_value] == CLASS_T))
    {   if (internal_flag)
        {   error("It is illegal to nest an object in a routine using '#classname'");
            return(TRUE);
        }
        sflags[token_value] |= USED_SFLAG;
        make_object(FALSE, NULL, -1, -1, svals[token_value]);
        return TRUE;
    }

    if (token_type != DIRECTIVE_TT)
    {   /* If we're internal, we expect only a directive here. If
           we're top-level, the possibilities are broader. */
        if (internal_flag)
            ebf_error("directive", token_text);
        else
            ebf_error("directive, '[' or class name", token_text);
        panic_mode_error_recovery();
        return TRUE;
    }

    return !(parse_given_directive(internal_flag));
}

static int switch_sign(void)
{
    if ((token_type == SEP_TT)&&(token_value == COLON_SEP))   return 1;
    if ((token_type == SEP_TT)&&(token_value == COMMA_SEP))   return 2;
    if ((token_type==MISC_KEYWORD_TT)&&(token_value==TO_MK))  return 3;
    return 0;
}

static assembly_operand spec_stack[32];
static int spec_type[32];

static void compile_alternatives_z(assembly_operand switch_value, int n,
    int stack_level, int label, int flag)
{   switch(n)
    {   case 1:
            assemblez_2_branch(je_zc, switch_value,
                spec_stack[stack_level],
                label, flag); return;
        case 2:
            assemblez_3_branch(je_zc, switch_value,
                spec_stack[stack_level], spec_stack[stack_level+1],
                label, flag); return;
        case 3:
            assemblez_4_branch(je_zc, switch_value,
                spec_stack[stack_level], spec_stack[stack_level+1],
                spec_stack[stack_level+2],
                label, flag); return;
    }
}

static void compile_alternatives_g(assembly_operand switch_value, int n,
    int stack_level, int label, int flag)
{   
    int the_zc = (flag) ? jeq_gc : jne_gc;

    if (n == 1) {
      assembleg_2_branch(the_zc, switch_value,
        spec_stack[stack_level],
        label); 
    }
    else {
      error("*** Cannot generate multi-equality tests in Glulx ***");
    }
}

static void compile_alternatives(assembly_operand switch_value, int n,
    int stack_level, int label, int flag)
{
  if (!glulx_mode)
    compile_alternatives_z(switch_value, n, stack_level, label, flag);
  else
    compile_alternatives_g(switch_value, n, stack_level, label, flag);
}

static void parse_switch_spec(assembly_operand switch_value, int label,
    int action_switch)
{
    int i, j, label_after = -1, spec_sp = 0;
    int max_equality_args = ((!glulx_mode) ? 3 : 1);

    sequence_point_follows = FALSE;

    do
    {   if (spec_sp == 32)
        {   error("At most 32 values can be given in a single 'switch' case");
            panic_mode_error_recovery();
            return;
        }

        if (action_switch)
        {   get_next_token();
            if (token_type == SQ_TT || token_type == DQ_TT) {
                ebf_error("action (or fake action) name", token_text);
                continue;
            }
            spec_stack[spec_sp] = action_of_name(token_text);

            if (spec_stack[spec_sp].value == -1)
            {   spec_stack[spec_sp].value = 0;
                ebf_error("action (or fake action) name", token_text);
            }
        }
        else
            spec_stack[spec_sp] =
      code_generate(parse_expression(CONSTANT_CONTEXT), CONSTANT_CONTEXT, -1);

        misc_keywords.enabled = TRUE;
        get_next_token();
        misc_keywords.enabled = FALSE;

        spec_type[spec_sp++] = switch_sign();
        switch(spec_type[spec_sp-1])
        {   case 0:
                if (action_switch)
                    ebf_error("',' or ':'", token_text);
                else ebf_error("',', ':' or 'to'", token_text);
                panic_mode_error_recovery();
                return;
            case 1: goto GenSpecCode;
            case 3: if (label_after == -1) label_after = next_label++;
        }
     } while(TRUE);

     GenSpecCode:

     if ((spec_sp > max_equality_args) && (label_after == -1))
         label_after = next_label++;

     if (label_after == -1)
     {   compile_alternatives(switch_value, spec_sp, 0, label, FALSE); return;
     }

     for (i=0; i<spec_sp;)
     {
         j=i; while ((j<spec_sp) && (spec_type[j] != 3)) j++;

         if (j > i)
         {   if (j-i > max_equality_args) j=i+max_equality_args;

             if (j == spec_sp)
                 compile_alternatives(switch_value, j-i, i, label, FALSE);
             else
                 compile_alternatives(switch_value, j-i, i, label_after, TRUE);

             i=j;
         }
         else
         {   
           if (!glulx_mode) {
             if (i == spec_sp - 2)
             {   assemblez_2_branch(jl_zc, switch_value, spec_stack[i],
                     label, TRUE);
                 assemblez_2_branch(jg_zc, switch_value, spec_stack[i+1],
                     label, TRUE);
             }
             else
             {   assemblez_2_branch(jl_zc, switch_value, spec_stack[i],
                     next_label, TRUE);
                 assemblez_2_branch(jg_zc, switch_value, spec_stack[i+1],
                     label_after, FALSE);
                 assemble_label_no(next_label++);
             }
           }
           else {
             if (i == spec_sp - 2)
             {   assembleg_2_branch(jlt_gc, switch_value, spec_stack[i],
                     label);
                 assembleg_2_branch(jgt_gc, switch_value, spec_stack[i+1],
                     label);
             }
             else
             {   assembleg_2_branch(jlt_gc, switch_value, spec_stack[i],
                     next_label);
                 assembleg_2_branch(jle_gc, switch_value, spec_stack[i+1],
                     label_after);
                 assemble_label_no(next_label++);
             }
           }
           i = i+2;
         }
     }

     assemble_label_no(label_after);
}

extern int32 parse_routine(char *source, int embedded_flag, char *name,
    int veneer_flag, int r_symbol)
{   int32 packed_address; int i; int debug_flag = FALSE;
    int switch_clause_made = FALSE, default_clause_made = FALSE,
        switch_label = 0;
    debug_location_beginning beginning_debug_location =
        get_token_location_beginning();

    /*  (switch_label needs no initialisation here, but it prevents some
        compilers from issuing warnings)   */

    if ((source != lexical_source) || (veneer_flag))
    {   lexical_source = source;
        restart_lexer(lexical_source, name);
    }

    no_locals = 0;

    for (i=0;i<MAX_LOCAL_VARIABLES-1;i++) local_variables.keywords[i] = "";

    do
    {   statements.enabled = TRUE;
        dont_enter_into_symbol_table = TRUE;
        get_next_token();
        dont_enter_into_symbol_table = FALSE;
        if ((token_type == SEP_TT) && (token_value == TIMES_SEP)
            && (no_locals == 0) && (!debug_flag))
        {   debug_flag = TRUE; continue;
        }

        if (token_type != DQ_TT)
        {   if ((token_type == SEP_TT)
                && (token_value == SEMICOLON_SEP)) break;
            ebf_error("local variable name or ';'", token_text);
            panic_mode_error_recovery();
            break;
        }

        if (strlen(token_text) > MAX_IDENTIFIER_LENGTH)
        {   error_named("Local variable identifier too long:", token_text);
            panic_mode_error_recovery();
            break;
        }

        if (no_locals == MAX_LOCAL_VARIABLES-1)
        {   error_numbered("Too many local variables for a routine; max is",
                MAX_LOCAL_VARIABLES-1);
            panic_mode_error_recovery();
            break;
        }

        for (i=0;i<no_locals;i++)
            if (strcmpcis(token_text, local_variables.keywords[i])==0)
                error_named("Local variable defined twice:", token_text);
        local_variables.keywords[no_locals++] = token_text;
    } while(TRUE);

    construct_local_variable_tables();

    if ((trace_fns_setting==3)
        || ((trace_fns_setting==2) && (veneer_mode==FALSE))
        || ((trace_fns_setting==1) && (is_systemfile()==FALSE)))
        debug_flag = TRUE;
    if ((embedded_flag == FALSE) && (veneer_mode == FALSE) && debug_flag)
        sflags[r_symbol] |= STAR_SFLAG;

    packed_address = assemble_routine_header(no_locals, debug_flag,
        name, embedded_flag, r_symbol);

    do
    {   begin_syntax_line(TRUE);

        get_next_token();

        if (token_type == EOF_TT)
        {   ebf_error("']'", token_text);
            assemble_routine_end
                (embedded_flag,
                 get_token_location_end(beginning_debug_location));
            put_token_back();
            break;
        }

        if ((token_type == SEP_TT)
            && (token_value == CLOSE_SQUARE_SEP))
        {   if (switch_clause_made && (!default_clause_made))
                assemble_label_no(switch_label);
            directives.enabled = TRUE;
            sequence_point_follows = TRUE;
            get_next_token();
            assemble_routine_end
                (embedded_flag,
                 get_token_location_end(beginning_debug_location));
            put_token_back();
            break;
        }

        if ((token_type == STATEMENT_TT) && (token_value == SDEFAULT_CODE))
        {   if (default_clause_made)
                error("Multiple 'default' clauses defined in same 'switch'");
            default_clause_made = TRUE;

            if (switch_clause_made)
            {   if (!execution_never_reaches_here)
                {   sequence_point_follows = FALSE;
                    if (!glulx_mode)
                        assemblez_0((embedded_flag)?rfalse_zc:rtrue_zc);
                    else
                        assembleg_1(return_gc, 
                            ((embedded_flag)?zero_operand:one_operand));
                }
                assemble_label_no(switch_label);
            }
            switch_clause_made = TRUE;

            get_next_token();
            if ((token_type == SEP_TT) &&
                (token_value == COLON_SEP)) continue;
            ebf_error("':' after 'default'", token_text);
            panic_mode_error_recovery();
            continue;
        }

        /*  Only check for the form of a case switch if the initial token
            isn't double-quoted text, as that would mean it was a print_ret
            statement: this is a mild ambiguity in the grammar. 
            Action statements also cannot be cases. */

        if ((token_type != DQ_TT) && (token_type != SEP_TT))
        {   get_next_token();
            if (switch_sign() > 0)
            {   assembly_operand AO;
                if (default_clause_made)
                    error("'default' must be the last 'switch' case");

                if (switch_clause_made)
                {   if (!execution_never_reaches_here)
                    {   sequence_point_follows = FALSE;
                        if (!glulx_mode)
                            assemblez_0((embedded_flag)?rfalse_zc:rtrue_zc);
                        else
                            assembleg_1(return_gc, 
                                ((embedded_flag)?zero_operand:one_operand));
                    }
                    assemble_label_no(switch_label);
                }

                switch_label = next_label++;
                switch_clause_made = TRUE;
                put_token_back(); put_token_back();

                if (!glulx_mode) {
                    INITAOTV(&AO, VARIABLE_OT, 249);
                }
                else {
                    INITAOTV(&AO, GLOBALVAR_OT, MAX_LOCAL_VARIABLES+6); /* sw__var */
                }
                parse_switch_spec(AO, switch_label, TRUE);

                continue;
            }
            else
            {   put_token_back(); put_token_back(); get_next_token();
                sequence_point_follows = TRUE;
            }
        }

        parse_statement(-1, -1);

    } while (TRUE);

    return packed_address;
}

extern void parse_code_block(int break_label, int continue_label,
    int switch_rule)
{   int switch_clause_made = FALSE, default_clause_made = FALSE, switch_label = 0,
        unary_minus_flag;

    begin_syntax_line(TRUE);
    get_next_token();

    if (token_type == SEP_TT && token_value == OPEN_BRACE_SEP)
    {   do
        {   begin_syntax_line(TRUE);
            get_next_token();
            if (token_type == SEP_TT && token_value == CLOSE_BRACE_SEP)
            {   if (switch_clause_made && (!default_clause_made))
                    assemble_label_no(switch_label);
                return;
            }
            if (token_type == EOF_TT)
            {   ebf_error("'}'", token_text); return; }

            if (switch_rule != 0)
            {
                /*  Within a 'switch' block  */

                if ((token_type==STATEMENT_TT)&&(token_value==SDEFAULT_CODE))
                {   if (default_clause_made)
                error("Multiple 'default' clauses defined in same 'switch'");
                    default_clause_made = TRUE;

                    if (switch_clause_made)
                    {   if (!execution_never_reaches_here)
                        {   sequence_point_follows = FALSE;
                            assemble_jump(break_label);
                        }
                        assemble_label_no(switch_label);
                    }
                    switch_clause_made = TRUE;

                    get_next_token();
                    if ((token_type == SEP_TT) &&
                        (token_value == COLON_SEP)) continue;
                    ebf_error("':' after 'default'", token_text);
                    panic_mode_error_recovery();
                    continue;
                }

                /*  Decide: is this an ordinary statement, or the start
                    of a new case?  */

                if (token_type == DQ_TT) goto NotASwitchCase;

                unary_minus_flag
                    = ((token_type == SEP_TT)&&(token_value == MINUS_SEP));
                if (unary_minus_flag) get_next_token();

                /*  Now read the token _after_ any possible constant:
                    if that's a 'to', ',' or ':' then we have a case  */

                misc_keywords.enabled = TRUE;
                get_next_token();
                misc_keywords.enabled = FALSE;

                if (switch_sign() > 0)
                {   assembly_operand AO;

                    if (default_clause_made)
                        error("'default' must be the last 'switch' case");

                    if (switch_clause_made)
                    {   if (!execution_never_reaches_here)
                        {   sequence_point_follows = FALSE;
                            assemble_jump(break_label);
                        }
                        assemble_label_no(switch_label);
                    }

                    switch_label = next_label++;
                    switch_clause_made = TRUE;
                    put_token_back(); put_token_back();
                    if (unary_minus_flag) put_token_back();

                    AO = temp_var1;
                    parse_switch_spec(AO, switch_label, FALSE);
                    continue;
                }
                else
                {   put_token_back(); put_token_back();
                    if (unary_minus_flag) put_token_back();
                    get_next_token();
                }
            }

            if ((switch_rule != 0) && (!switch_clause_made))
                ebf_error("switch value", token_text);

            NotASwitchCase:
            sequence_point_follows = TRUE;
            parse_statement(break_label, continue_label);
        }
        while(TRUE);
    }

    if (switch_rule != 0)
        ebf_error("braced code block after 'switch'", token_text);

    parse_statement(break_label, continue_label);
    return;
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_syntax_vars(void)
{
}

extern void syntax_begin_pass(void)
{   no_syntax_lines = 0;
}

extern void syntax_allocate_arrays(void)
{
}

extern void syntax_free_arrays(void)
{
}

/* ========================================================================= */
