/* ------------------------------------------------------------------------- */
/*   "errors" : Warnings, errors and fatal errors                            */
/*              (with error throwback code for RISC OS machines)             */
/*                                                                           */
/*   Part of Inform 6.41                                                     */
/*   copyright (c) Graham Nelson 1993 - 2022                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

#define ERROR_BUFLEN (256)
static char error_message_buff[ERROR_BUFLEN+4]; /* room for ellipsis */

/* ------------------------------------------------------------------------- */
/*   Error preamble printing.                                                */
/* ------------------------------------------------------------------------- */

ErrorPosition ErrorReport;             /*  Maintained by "lexer.c"           */

static char other_pos_buff[ERROR_BUFLEN+1];       /* Used by location_text() */

static void print_preamble(void)
{
    /*  Only really prints the preamble to an error or warning message:

        e.g.  "jigsaw.apollo", line 24:

        The format is controllable (from an ICL switch) since this assists
        the working of some development environments.                        */

    int j, with_extension_flag = FALSE; char *p;

    j = ErrorReport.file_number;
    if (j <= 0 || j > total_files) p = ErrorReport.source;
    else p = InputFiles[j-1].filename;

    if (!p) p = "";
    
    switch(error_format)
    {
        case 0:  /* RISC OS error message format */

            if (!(ErrorReport.main_flag)) printf("\"%s\", ", p);
            printf("line %d: ", ErrorReport.line_number);
            
            if (ErrorReport.orig_file) {
                char *op;
                if (ErrorReport.orig_file <= 0 || ErrorReport.orig_file > total_files)
                    op = ErrorReport.orig_source;
                else
                    op = InputFiles[ErrorReport.orig_file-1].filename;
                printf("(\"%s\"", op);
                if (ErrorReport.orig_line) {
                    printf(", %d", ErrorReport.orig_line);
                    if (ErrorReport.orig_char) {
                        printf(":%d", ErrorReport.orig_char);
                    }
                }
                printf("): ");
            }
            break;

        case 1:  /* Microsoft error message format */

            for (j=0; p[j]!=0; j++)
            {   if (p[j] == FN_SEP) with_extension_flag = TRUE;
                if (p[j] == '.') with_extension_flag = FALSE;
            }
            printf("%s", p);
            if (with_extension_flag) printf("%s", Source_Extension);
            printf("(%d)", ErrorReport.line_number);
            
            if (ErrorReport.orig_file) {
                char *op;
                if (ErrorReport.orig_file <= 0 || ErrorReport.orig_file > total_files)
                    op = ErrorReport.orig_source;
                else
                    op = InputFiles[ErrorReport.orig_file-1].filename;
                printf("|%s", op);
                if (ErrorReport.orig_line) {
                    printf("(%d", ErrorReport.orig_line);
                    if (ErrorReport.orig_char) {
                        printf(":%d", ErrorReport.orig_char);
                    }
                    printf(")");
                }
            }
            
            printf(": ");
            break;

        case 2:  /* Macintosh Programmer's Workshop error message format */

            printf("File \"%s\"; Line %d", p, ErrorReport.line_number);
            
            if (ErrorReport.orig_file) {
                char *op;
                if (ErrorReport.orig_file <= 0 || ErrorReport.orig_file > total_files)
                    op = ErrorReport.orig_source;
                else
                    op = InputFiles[ErrorReport.orig_file-1].filename;
                printf(": (\"%s\"", op);
                if (ErrorReport.orig_line) {
                    printf("; Line %d", ErrorReport.orig_line);
                    if (ErrorReport.orig_char) {
                        printf("; Char %d", ErrorReport.orig_char);
                    }
                }
                printf(")");
            }

            printf("\t# ");
            break;
    }
}

static char *location_text(brief_location report_line)
{
    int j;
    char *p;
    int len;

    /* Convert the location to a brief string. 
       (Some error messages need to report a secondary location.)
       This uses the static buffer other_pos_buff. */
    
    ErrorPosition errpos;
    errpos.file_number = -1;
    errpos.source = NULL;
    errpos.line_number = 0;
    errpos.main_flag = 0;
    errpos.orig_source = NULL;
    export_brief_location(report_line, &errpos);
    
    j = errpos.file_number;
    if (j <= 0 || j > total_files) p = errpos.source;
    else p = InputFiles[j-1].filename;
    
    if (!p && errpos.line_number == 0) {
        /* Special case */
        strcpy(other_pos_buff, "compiler setup");
        return other_pos_buff;
    }
    
    if (!p) p = "";

    len = 0;
    
    if (!(errpos.main_flag)) {
        snprintf(other_pos_buff+len, ERROR_BUFLEN-len,
                 "\"%s\", ", p);
        len = strlen(other_pos_buff);
    }
    snprintf(other_pos_buff+len, ERROR_BUFLEN-len,
             "line %d", errpos.line_number);

    return other_pos_buff;
}

static void ellipsize_error_message_buff(void)
{
    /* If the error buffer was actually filled up by a message, it was
       probably truncated too. Add an ellipsis, for which we left
       extra room. (Yes, yes; errors that are *exactly* 255 characters
       long will suffer an unnecessary ellipsis.) */
    if (strlen(error_message_buff) == ERROR_BUFLEN-1)
        strcat(error_message_buff, "...");
}

/* ------------------------------------------------------------------------- */
/*   Fatal errors (which have style 0)                                       */
/* ------------------------------------------------------------------------- */

extern void fatalerror(char *s)
{   print_preamble();

    printf("Fatal error: %s\n",s);
    if (no_compiler_errors > 0) print_sorry_message();

#ifdef ARC_THROWBACK
    throwback(0, s);
    throwback_end();
#endif
#ifdef MAC_FACE
    close_all_source();
    abort_transcript_file();
    free_arrays();
    longjmp(g_fallback, 1);
#endif
    exit(1);
}

extern void fatalerror_named(char *m, char *fn)
{   snprintf(error_message_buff, ERROR_BUFLEN, "%s \"%s\"", m, fn);
    ellipsize_error_message_buff();
    fatalerror(error_message_buff);
}

extern void memory_out_error(int32 size, int32 howmany, char *name)
{   if (howmany == 1)
        snprintf(error_message_buff, ERROR_BUFLEN,
            "Run out of memory allocating %d bytes for %s", size, name);
    else
        snprintf(error_message_buff, ERROR_BUFLEN,
            "Run out of memory allocating array of %dx%d bytes for %s",
                howmany, size, name);
    ellipsize_error_message_buff();
    fatalerror(error_message_buff);
}

/* ------------------------------------------------------------------------- */
/*   Survivable diagnostics:                                                 */
/*      compilation errors   style 1                                         */
/*      warnings             style 2                                         */
/*      linkage errors       style 3 (no longer used)                        */
/*      compiler errors      style 4 (these should never happen and          */
/*                                    indicate a bug in Inform)              */
/* ------------------------------------------------------------------------- */

int no_errors, no_warnings, no_suppressed_warnings, no_compiler_errors;

char *forerrors_buff;
int  forerrors_pointer;

static void message(int style, char *s)
{
    if (hash_printed_since_newline) printf("\n");
    hash_printed_since_newline = FALSE;
    print_preamble();
    switch(style)
    {   case 1: printf("Error: "); no_errors++; break;
        case 2: printf("Warning: "); no_warnings++; break;
        case 3: printf("Error:  [linking]  "); no_errors++; break;
        case 4: printf("*** Compiler error: ");
                no_compiler_errors++; break;
    }
    printf(" %s\n", s);
#ifdef ARC_THROWBACK
    throwback(((style <= 2) ? style : 1), s);
#endif
#ifdef MAC_FACE
    ProcessEvents (&g_proc);
    if (g_proc != true)
    {   free_arrays();
        close_all_source ();
        abort_transcript_file();
        longjmp (g_fallback, 1);
    }
#endif
    if ((!concise_switch) && (forerrors_pointer > 0) && (style <= 2))
    {   forerrors_buff[forerrors_pointer] = 0;
        sprintf(forerrors_buff+68,"  ...etc");
        printf("> %s\n",forerrors_buff);
    }
}

/* ------------------------------------------------------------------------- */
/*   Style 1: Error message routines                                         */
/* ------------------------------------------------------------------------- */

extern void error(char *s)
{   if (no_errors == MAX_ERRORS)
        fatalerror("Too many errors: giving up");
    message(1,s);
}

extern void error_named(char *s1, char *s2)
{   snprintf(error_message_buff, ERROR_BUFLEN,"%s \"%s\"",s1,s2);
    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void error_numbered(char *s1, int val)
{
    snprintf(error_message_buff, ERROR_BUFLEN,"%s %d.",s1,val);
    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void error_named_at(char *s1, char *s2, brief_location report_line)
{   int i;

    ErrorPosition E = ErrorReport;
    export_brief_location(report_line, &ErrorReport);

    snprintf(error_message_buff, ERROR_BUFLEN,"%s \"%s\"",s1,s2);
    ellipsize_error_message_buff();

    i = concise_switch; concise_switch = TRUE;
    error(error_message_buff);
    ErrorReport = E; concise_switch = i;
}

extern void no_such_label(char *lname)
{   error_named("No such label as",lname);
}

extern void ebf_error(char *s1, char *s2)
{   snprintf(error_message_buff, ERROR_BUFLEN, "Expected %s but found %s", s1, s2);
    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void ebf_symbol_error(char *s1, char *name, char *type, brief_location report_line)
{   snprintf(error_message_buff, ERROR_BUFLEN, "\"%s\" is a name already in use and may not be used as a %s (%s \"%s\" was defined at %s)", name, s1, type, name, location_text(report_line));
    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void char_error(char *s, int ch)
{   int32 uni;

    uni = iso_to_unicode(ch);

    if (character_set_unicode)
        snprintf(error_message_buff, ERROR_BUFLEN, "%s (unicode) $%04x", s, uni);
    else if (uni >= 0x100)
    {   snprintf(error_message_buff, ERROR_BUFLEN,
            "%s (unicode) $%04x = (ISO %s) $%02x", s, uni,
            name_of_iso_set(character_set_setting), ch);
    }
    else
        snprintf(error_message_buff, ERROR_BUFLEN, "%s (ISO Latin1) $%02x", s, uni);

    /* If the character set is set to Latin-1, and the char in question
       is a printable Latin-1 character, we print it in the error message.
       This conflates the source-text charset with the terminal charset,
       really, but it's not a big deal. */

    if (((uni>=32) && (uni<127))
        || (((uni >= 0xa1) && (uni <= 0xff))
        && (character_set_setting==1) && (!character_set_unicode))) 
    {   int curlen = strlen(error_message_buff);
        snprintf(error_message_buff+curlen, ERROR_BUFLEN-curlen,
            ", i.e., '%c'", uni);
    }

    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void unicode_char_error(char *s, int32 uni)
{
    if (uni >= 0x100)
        snprintf(error_message_buff, ERROR_BUFLEN, "%s (unicode) $%04x", s, uni);
    else
        snprintf(error_message_buff, ERROR_BUFLEN, "%s (ISO Latin1) $%02x", s, uni);

    /* See comment above. */

    if (((uni>=32) && (uni<127))
        || (((uni >= 0xa1) && (uni <= 0xff))
        && (character_set_setting==1) && (!character_set_unicode)))
    {   int curlen = strlen(error_message_buff);
        snprintf(error_message_buff+curlen, ERROR_BUFLEN-curlen,
            ", i.e., '%c'", uni);
    }

    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void error_max_dynamic_strings(int index)
{
    if (index >= 96 && !glulx_mode)
        snprintf(error_message_buff, ERROR_BUFLEN, "Only dynamic strings @(00) to @(95) may be used in Z-code");
    else if (MAX_DYNAMIC_STRINGS == 0)
        snprintf(error_message_buff, ERROR_BUFLEN, "Dynamic strings may not be used, because $MAX_DYNAMIC_STRINGS has been set to 0. Increase MAX_DYNAMIC_STRINGS.");
    else if (MAX_DYNAMIC_STRINGS == 32 && !glulx_mode)
        snprintf(error_message_buff, ERROR_BUFLEN, "Only dynamic strings @(00) to @(%02d) may be used, because $MAX_DYNAMIC_STRINGS has its default value of %d. Increase MAX_DYNAMIC_STRINGS.", MAX_DYNAMIC_STRINGS-1, MAX_DYNAMIC_STRINGS);
    else
        snprintf(error_message_buff, ERROR_BUFLEN, "Only dynamic strings @(00) to @(%02d) may be used, because $MAX_DYNAMIC_STRINGS has been set to %d. Increase MAX_DYNAMIC_STRINGS.", MAX_DYNAMIC_STRINGS-1, MAX_DYNAMIC_STRINGS);

    ellipsize_error_message_buff();
    error(error_message_buff);
}

extern void error_max_abbreviations(int index)
{
    /* This is only called for Z-code. */
    if (index >= 96)
        error("The number of abbreviations has exceeded 96, the limit in Z-code");
    else
        error("The number of abbreviations has exceeded MAX_ABBREVS. Increase MAX_ABBREVS.");
}

/* ------------------------------------------------------------------------- */
/*   Style 2: Warning message routines                                       */
/* ------------------------------------------------------------------------- */

extern void warning(char *s1)
{   if (nowarnings_switch) { no_suppressed_warnings++; return; }
    message(2,s1);
}

extern void warning_numbered(char *s1, int val)
{   if (nowarnings_switch) { no_suppressed_warnings++; return; }
    snprintf(error_message_buff, ERROR_BUFLEN,"%s %d.", s1, val);
    ellipsize_error_message_buff();
    message(2,error_message_buff);
}

extern void warning_named(char *s1, char *s2)
{
    if (nowarnings_switch) { no_suppressed_warnings++; return; }
    snprintf(error_message_buff, ERROR_BUFLEN,"%s \"%s\"", s1, s2);
    ellipsize_error_message_buff();
    message(2,error_message_buff);
}

extern void symtype_warning(char *context, char *name, char *type, char *wanttype)
{
    if (nowarnings_switch) { no_suppressed_warnings++; return; }
    if (name)
        snprintf(error_message_buff, ERROR_BUFLEN, "In %s, expected %s but found %s \"%s\"", context, wanttype, type, name);
    else
        snprintf(error_message_buff, ERROR_BUFLEN, "In %s, expected %s but found %s", context, wanttype, type);
    ellipsize_error_message_buff();
    message(2,error_message_buff);
}

extern void dbnu_warning(char *type, char *name, brief_location report_line)
{   int i;
    ErrorPosition E = ErrorReport;
    if (nowarnings_switch) { no_suppressed_warnings++; return; }
    export_brief_location(report_line, &ErrorReport);
    snprintf(error_message_buff, ERROR_BUFLEN, "%s \"%s\" declared but not used", type, name);
    ellipsize_error_message_buff();
    i = concise_switch; concise_switch = TRUE;
    message(2,error_message_buff);
    concise_switch = i;
    ErrorReport = E;
}

extern void uncalled_routine_warning(char *type, char *name, brief_location report_line)
{   int i;
    /* This is called for functions which have been detected by the
       track-unused-routines module. These will often (but not always)
       be also caught by dbnu_warning(), which tracks symbols rather
       than routine addresses. */
    ErrorPosition E = ErrorReport;
    if (nowarnings_switch) { no_suppressed_warnings++; return; }
    export_brief_location(report_line, &ErrorReport);
    if (OMIT_UNUSED_ROUTINES)
        snprintf(error_message_buff, ERROR_BUFLEN, "%s \"%s\" unused and omitted", type, name);
    else
        snprintf(error_message_buff, ERROR_BUFLEN, "%s \"%s\" unused (not omitted)", type, name);
    ellipsize_error_message_buff();
    i = concise_switch; concise_switch = TRUE;
    message(2,error_message_buff);
    concise_switch = i;
    ErrorReport = E;
}

extern void obsolete_warning(char *s1)
{   if (is_systemfile()==1) return;
    if (obsolete_switch || nowarnings_switch)
    {   no_suppressed_warnings++; return; }
    snprintf(error_message_buff, ERROR_BUFLEN, "Obsolete usage: %s",s1);
    ellipsize_error_message_buff();
    message(2,error_message_buff);
}

/* ------------------------------------------------------------------------- */
/*   Style 4: Compiler error message routines                                */
/* ------------------------------------------------------------------------- */

extern void print_sorry_message(void)
{   printf(
"***********************************************************************\n\
* 'Compiler errors' should never occur if Inform is working properly. *\n\
* This is version %d.%02d of Inform, dated %20s: so      *\n\
* if that was more than a year ago, there may be a more recent        *\n\
* version available, from which the problem may have been removed.    *\n\
* If not, please report this fault as an issue at                     *\n\
* https://github.com/DavidKinder/Inform6/ and if at all possible,     *\n\
* please include your source code, as faults such as these are rare   *\n\
* and often difficult to reproduce.  Sorry.                           *\n\
***********************************************************************\n",
    (RELEASE_NUMBER/100)%10, RELEASE_NUMBER%100, RELEASE_DATE);
}

extern int compiler_error(char *s)
{
    if (no_errors > 0) return FALSE;
    if (no_compiler_errors==MAX_ERRORS)
        fatalerror("Too many compiler errors: giving up");
    message(4,s);
    return TRUE;
}

extern int compiler_error_named(char *s1, char *s2)
{
    if (no_errors > 0) return FALSE;
    snprintf(error_message_buff, ERROR_BUFLEN, "%s \"%s\"",s1,s2);
    ellipsize_error_message_buff();
    compiler_error(error_message_buff);
    return TRUE;
}

/* ------------------------------------------------------------------------- */
/*   Code for the Acorn RISC OS operating system, donated by Robin Watts,    */
/*   to provide error throwback under the DDE environment                    */
/* ------------------------------------------------------------------------- */

#ifdef ARC_THROWBACK

#define DDEUtils_ThrowbackStart 0x42587
#define DDEUtils_ThrowbackSend  0x42588
#define DDEUtils_ThrowbackEnd   0x42589

#include "kernel.h"

extern void throwback_start(void)
{    _kernel_swi_regs regs;
     if (throwback_switch)
         _kernel_swi(DDEUtils_ThrowbackStart, &regs, &regs);
}

extern void throwback_end(void)
{   _kernel_swi_regs regs;
    if (throwback_switch)
        _kernel_swi(DDEUtils_ThrowbackEnd, &regs, &regs);
}

int throwback_started = FALSE;

extern void throwback(int severity, char * error)
{   _kernel_swi_regs regs;
    if (!throwback_started)
    {   throwback_started = TRUE;
        throwback_start();
    }
    if (throwback_switch)
    {   regs.r[0] = 1;
        if ((ErrorReport.file_number == -1)
            || (ErrorReport.file_number == 0))
            regs.r[2] = (int) (InputFiles[0].filename);
        else regs.r[2] = (int) (InputFiles[ErrorReport.file_number-1].filename);
        regs.r[3] = ErrorReport.line_number;
        regs.r[4] = (2-severity);
        regs.r[5] = (int) error;
       _kernel_swi(DDEUtils_ThrowbackSend, &regs, &regs);
    }
}

#endif

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_errors_vars(void)
{   forerrors_buff = NULL;
    no_errors = 0; no_warnings = 0; no_suppressed_warnings = 0;
    no_compiler_errors = 0;
}

extern void errors_begin_pass(void)
{   ErrorReport.line_number = 0;
    ErrorReport.file_number = -1;
    ErrorReport.source = "<no text read yet>";
    ErrorReport.main_flag = FALSE;
    ErrorReport.orig_source = NULL;
    ErrorReport.orig_file = 0;
    ErrorReport.orig_line = 0;
    ErrorReport.orig_char = 0;
}

extern void errors_allocate_arrays(void)
{   forerrors_buff = my_malloc(FORERRORS_SIZE, "errors buffer");
}

extern void errors_free_arrays(void)
{   my_free(&forerrors_buff, "errors buffer");
}

/* ========================================================================= */
