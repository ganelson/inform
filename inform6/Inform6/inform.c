/* ------------------------------------------------------------------------- */
/*   "inform" :  The top level of Inform: switches, pathnames, filenaming    */
/*               conventions, ICL (Inform Command Line) files, main          */
/*                                                                           */
/*   Part of Inform 6.43                                                     */
/*   copyright (c) Graham Nelson 1993 - 2025                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#define MAIN_INFORM_FILE
#include "header.h"

#define CMD_BUF_SIZE (256)

/* ------------------------------------------------------------------------- */
/*   Compiler progress                                                       */
/* ------------------------------------------------------------------------- */

static int no_compilations;

int endofpass_flag;      /* set to TRUE when an "end" directive is reached
                            (the inputs routines insert one into the stream
                            if necessary)                                    */

/* ------------------------------------------------------------------------- */
/*   Version control                                                         */
/* ------------------------------------------------------------------------- */

int version_number,      /* 3 to 8 (Z-code)                                  */
    instruction_set_number,
                         /* 3 to 6: versions 7 and 8 use instruction set of
                            version 5                                        */
    extend_memory_map;   /* extend using function- and string-offsets        */
int32 scale_factor,      /* packed address multiplier                        */
    length_scale_factor; /* length-in-header multiplier                      */

int32 requested_glulx_version; /* version requested via -v switch            */
int32 final_glulx_version;     /* requested version combined with game
                                  feature requirements                       */

extern void select_version(int vn)
{   version_number = vn;
    extend_memory_map = FALSE;
    if ((version_number==6)||(version_number==7)) extend_memory_map = TRUE;

    scale_factor = 4;
    if (version_number==3) scale_factor = 2;
    if (version_number==8) scale_factor = 8;

    length_scale_factor = scale_factor;
    if ((version_number==6)||(version_number==7)) length_scale_factor = 8;

    instruction_set_number = version_number;
    if ((version_number==7)||(version_number==8)) instruction_set_number = 5;
}

static int select_glulx_version(char *str)
{
  /* Parse an "X.Y.Z" style version number, and store it for later use. */
  char *cx = str;
  int major=0, minor=0, patch=0;

  while (isdigit((uchar)*cx))
    major = major*10 + ((*cx++)-'0');
  if (*cx == '.') {
    cx++;
    while (isdigit((uchar)*cx))
      minor = minor*10 + ((*cx++)-'0');
    if (*cx == '.') {
      cx++;
      while (isdigit((uchar)*cx))
        patch = patch*10 + ((*cx++)-'0');
    }
  }

  requested_glulx_version = ((major & 0x7FFF) << 16) 
    + ((minor & 0xFF) << 8) 
    + (patch & 0xFF);
  return (cx - str);
}

/* ------------------------------------------------------------------------- */
/*   Target: variables which vary between the Z-machine and Glulx            */
/* ------------------------------------------------------------------------- */

int   WORDSIZE;            /* Size of a machine word: 2 or 4 */
int32 MAXINTWORD;          /* 0x7FFF or 0x7FFFFFFF */

/* The first property number which is an individual property. The
   eight class-system i-props (create, recreate, ... print_to_array)
   are numbered from INDIV_PROP_START to INDIV_PROP_START+7.
*/
int INDIV_PROP_START;

/* The length of an object, as written in tables.c. It's easier to define
   it here than to repeat the same expression all over the source code.
   Not used in Z-code. 
*/
int OBJECT_BYTE_LENGTH;
/* The total length of a dict entry, in bytes. Not used in Z-code. 
*/
int DICT_ENTRY_BYTE_LENGTH;
/* The position in a dict entry that the flag values begin.
   Not used in Z-code. 
*/
int DICT_ENTRY_FLAG_POS;

static void select_target(int targ)
{
  if (!targ) {
    /* Z-machine */
    WORDSIZE = 2;
    MAXINTWORD = 0x7FFF;

    MAX_LOCAL_VARIABLES = 16; /* including "sp" */

    if (INDIV_PROP_START != 64) {
        INDIV_PROP_START = 64;
        fatalerror("You cannot change INDIV_PROP_START in Z-code");
    }
    if (DICT_WORD_SIZE != 6) {
      DICT_WORD_SIZE = 6;
      fatalerror("You cannot change DICT_WORD_SIZE in Z-code");
    }
    if (DICT_CHAR_SIZE != 1) {
      DICT_CHAR_SIZE = 1;
      fatalerror("You cannot change DICT_CHAR_SIZE in Z-code");
    }
    if (NUM_ATTR_BYTES != 6) {
      NUM_ATTR_BYTES = 6;
      fatalerror("You cannot change NUM_ATTR_BYTES in Z-code");
    }
  }
  else {
    /* Glulx */
    WORDSIZE = 4;
    MAXINTWORD = 0x7FFFFFFF;
    scale_factor = 0; /* It should never even get used in Glulx */

    /* This could really be 120, since the practical limit is the size
       of local_variables.keywords. But historically it's been 119. */
    MAX_LOCAL_VARIABLES = 119; /* including "sp" */

    if (INDIV_PROP_START < 256) {
        INDIV_PROP_START = 256;
        warning_fmt("INDIV_PROP_START should be at least 256 in Glulx; setting to %d", INDIV_PROP_START);
    }

    if (NUM_ATTR_BYTES % 4 != 3) {
      NUM_ATTR_BYTES += (3 - (NUM_ATTR_BYTES % 4)); 
      warning_fmt("NUM_ATTR_BYTES must be a multiple of four, plus three; increasing to %d", NUM_ATTR_BYTES);
    }

    if (DICT_CHAR_SIZE != 1 && DICT_CHAR_SIZE != 4) {
      DICT_CHAR_SIZE = 4;
      warning_fmt("DICT_CHAR_SIZE must be either 1 or 4; setting to %d", DICT_CHAR_SIZE);
    }
  }

  if (MAX_LOCAL_VARIABLES > MAX_KEYWORD_GROUP_SIZE) {
    compiler_error("MAX_LOCAL_VARIABLES cannot exceed MAX_KEYWORD_GROUP_SIZE");
    MAX_LOCAL_VARIABLES = MAX_KEYWORD_GROUP_SIZE;
  }

  if (NUM_ATTR_BYTES > MAX_NUM_ATTR_BYTES) {
    NUM_ATTR_BYTES = MAX_NUM_ATTR_BYTES;
    warning_fmt(
      "NUM_ATTR_BYTES cannot exceed MAX_NUM_ATTR_BYTES; resetting to %d",
      MAX_NUM_ATTR_BYTES);
    /* MAX_NUM_ATTR_BYTES can be increased in header.h without fear. */
  }

  /* Set up a few more variables that depend on the above values */

  if (!targ) {
    /* Z-machine */
    DICT_WORD_BYTES = DICT_WORD_SIZE;
    OBJECT_BYTE_LENGTH = 0;
    DICT_ENTRY_BYTE_LENGTH = ((version_number==3)?7:9) - (ZCODE_LESS_DICT_DATA?1:0);
    DICT_ENTRY_FLAG_POS = 0;
  }
  else {
    /* Glulx */
    OBJECT_BYTE_LENGTH = (1 + (NUM_ATTR_BYTES) + 6*4 + (GLULX_OBJECT_EXT_BYTES));
    DICT_WORD_BYTES = DICT_WORD_SIZE*DICT_CHAR_SIZE;
    if (DICT_CHAR_SIZE == 1) {
      DICT_ENTRY_BYTE_LENGTH = (7+DICT_WORD_BYTES);
      DICT_ENTRY_FLAG_POS = (1+DICT_WORD_BYTES);
    }
    else {
      DICT_ENTRY_BYTE_LENGTH = (12+DICT_WORD_BYTES);
      DICT_ENTRY_FLAG_POS = (4+DICT_WORD_BYTES);
    }
  }

  if (!targ) {
    /* Z-machine */
    /* The Z-machine's 96 abbreviations are used for these two purposes.
       Make sure they are set consistently. If exactly one has been
       set non-default, set the other to match. */
    if (MAX_DYNAMIC_STRINGS == 32 && MAX_ABBREVS != 64) {
        MAX_DYNAMIC_STRINGS = 96 - MAX_ABBREVS;
    }
    if (MAX_ABBREVS == 64 && MAX_DYNAMIC_STRINGS != 32) {
        MAX_ABBREVS = 96 - MAX_DYNAMIC_STRINGS;
    }
    if (MAX_ABBREVS + MAX_DYNAMIC_STRINGS != 96
        || MAX_ABBREVS < 0
        || MAX_DYNAMIC_STRINGS < 0) {
      warning("MAX_ABBREVS plus MAX_DYNAMIC_STRINGS must be 96 in Z-code; resetting both");
      MAX_DYNAMIC_STRINGS = 32;
      MAX_ABBREVS = 64;
    }
  }
}

/* ------------------------------------------------------------------------- */
/*   Tracery: output control variables                                       */
/*   (These are initially set to foo_trace_setting, but the Trace directive  */
/*   can change them on the fly)                                             */
/* ------------------------------------------------------------------------- */

int asm_trace_level,     /* trace assembly: 0 for off, 1 for assembly
                            only, 2 for full assembly tracing with hex dumps,
                            3 for branch shortening info, 4 for verbose
                            branch info                                      */
    expr_trace_level,    /* expression tracing: 0 off, 1 on, 2/3 more        */
    tokens_trace_level;  /* lexer output tracing: 0 off, 1 on, 2/3 more      */

/* ------------------------------------------------------------------------- */
/*   On/off switch variables (by default all FALSE); other switch settings   */
/*   (Some of these have become numerical settings now)                      */
/* ------------------------------------------------------------------------- */

int concise_switch,                 /* -c */
    economy_switch,                 /* -e */
    frequencies_setting,            /* $!FREQ, -f */
    ignore_switches_switch,         /* -i */
    debugfile_switch,               /* -k */
    memout_switch,                  /* $!MEM */
    printprops_switch,              /* $!PROPS */
    printactions_switch,            /* $!ACTIONS */
    obsolete_switch,                /* -q */
    transcript_switch,              /* -r */
    statistics_switch,              /* $!STATS, -s */
    optimise_switch,                /* -u */
    version_set_switch,             /* -v */
    nowarnings_switch,              /* -w */
    hash_switch,                    /* -x */
    memory_map_setting,             /* $!MAP, -z */
    oddeven_packing_switch,         /* -B */
    define_DEBUG_switch,            /* -D */
    runtime_error_checking_switch,  /* -S */
    define_INFIX_switch;            /* -X */
#ifdef ARC_THROWBACK
int throwback_switch;               /* -T */
#endif
#ifdef ARCHIMEDES
int riscos_file_type_format;        /* set by -R */
#endif
int compression_switch;             /* set by -H */
int character_set_setting,          /* set by -C0 through -C9 */
    character_set_unicode,          /* set by -Cu */
    error_format,                   /* set by -E */
    asm_trace_setting,              /* $!ASM, -a: initial value of
                                       asm_trace_level */
    bpatch_trace_setting,           /* $!BPATCH */
    symdef_trace_setting,           /* $!SYMDEF */
    expr_trace_setting,             /* $!EXPR: initial value of
                                       expr_trace_level */
    tokens_trace_setting,           /* $!TOKENS: initial value of
                                       tokens_trace_level */
    optabbrevs_trace_setting,       /* $!FINDABBREVS */
    double_space_setting,           /* set by -d: 0, 1 or 2 */
    trace_fns_setting,              /* $!RUNTIME, -g: 0, 1, 2, or 3 */
    files_trace_setting,            /* $!FILES */
    list_verbs_setting,             /* $!VERBS */
    list_dict_setting,              /* $!DICT */
    list_objects_setting,           /* $!OBJECTS */
    list_symbols_setting,           /* $!SYMBOLS */
    store_the_text;                 /* when set, record game text to a chunk
                                       of memory (used by -u) */
static int r_e_c_s_set;             /* has -S been explicitly set? */

int glulx_mode;                     /* -G */

static void reset_switch_settings(void)
{   asm_trace_setting = 0;
    tokens_trace_setting = 0;
    expr_trace_setting = 0;
    bpatch_trace_setting = 0;
    symdef_trace_setting = 0;
    list_verbs_setting = 0;
    list_dict_setting = 0;
    list_objects_setting = 0;
    list_symbols_setting = 0;

    store_the_text = FALSE;

    concise_switch = FALSE;
    double_space_setting = 0;
    economy_switch = FALSE;
    files_trace_setting = 0;
    frequencies_setting = 0;
    trace_fns_setting = 0;
    ignore_switches_switch = FALSE;
    debugfile_switch = FALSE;
    memout_switch = 0;
    printprops_switch = 0;
    printactions_switch = 0;
    obsolete_switch = FALSE;
    transcript_switch = FALSE;
    statistics_switch = FALSE;
    optimise_switch = FALSE;
    optabbrevs_trace_setting = 0;
    version_set_switch = FALSE;
    nowarnings_switch = FALSE;
    hash_switch = FALSE;
    memory_map_setting = 0;
    oddeven_packing_switch = FALSE;
    define_DEBUG_switch = FALSE;
#ifdef ARC_THROWBACK
    throwback_switch = FALSE;
#endif
    runtime_error_checking_switch = TRUE;
    r_e_c_s_set = FALSE;
    define_INFIX_switch = FALSE;
#ifdef ARCHIMEDES
    riscos_file_type_format = 0;
#endif
    error_format=DEFAULT_ERROR_FORMAT;

    character_set_setting = 1;         /* Default is ISO Latin-1 */
    character_set_unicode = FALSE;

    compression_switch = TRUE;
    glulx_mode = FALSE;
    requested_glulx_version = 0;
    final_glulx_version = 0;

    /* These aren't switches, but for clarity we reset them too. */
    asm_trace_level = 0;
    expr_trace_level = 0;
    tokens_trace_level = 0;
}

/* ------------------------------------------------------------------------- */
/*   Number of files given as command line parameters (0, 1 or 2)            */
/* ------------------------------------------------------------------------- */

static int cli_files_specified,
           convert_filename_flag;

char Source_Name[PATHLEN];             /* Processed name of first input file */
char Code_Name[PATHLEN];               /* Processed name of output file      */

static char *cli_file1, *cli_file2;    /* Unprocessed (and unsafe to alter)  */

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

static void init_vars(void)
{
    init_arrays_vars();
    init_asm_vars();
    init_bpatch_vars();
    init_chars_vars();
    init_directs_vars();
    init_errors_vars();
    init_expressc_vars();
    init_expressp_vars();
    init_files_vars();
    init_lexer_vars();
    init_memory_vars();
    init_objects_vars();
    init_states_vars();
    init_symbols_vars();
    init_syntax_vars();
    init_tables_vars();
    init_text_vars();
    init_veneer_vars();
    init_verbs_vars();
}

static void begin_pass(void)
{
    arrays_begin_pass();
    asm_begin_pass();
    bpatch_begin_pass();
    chars_begin_pass();
    directs_begin_pass();
    errors_begin_pass();
    expressc_begin_pass();
    expressp_begin_pass();
    files_begin_pass();

    endofpass_flag = FALSE;
    expr_trace_level = expr_trace_setting;
    asm_trace_level = asm_trace_setting;
    tokens_trace_level = tokens_trace_setting;

    lexer_begin_pass();
    memory_begin_pass();
    objects_begin_pass();
    states_begin_pass();
    symbols_begin_pass();
    syntax_begin_pass();
    tables_begin_pass();
    text_begin_pass();
    veneer_begin_pass();
    verbs_begin_pass();

    /*  Compile a Main__ routine (see "veneer.c")  */
    
    compile_initial_routine();
    
    /*  Make the four metaclasses: Class must be object number 1, so
        it must come first  */
    
    veneer_mode = TRUE;
    
    make_class("Class");
    make_class("Object");
    make_class("Routine");
    make_class("String");
    
    veneer_mode = FALSE;
}

extern void allocate_arrays(void)
{
    arrays_allocate_arrays();
    asm_allocate_arrays();
    bpatch_allocate_arrays();
    chars_allocate_arrays();
    directs_allocate_arrays();
    errors_allocate_arrays();
    expressc_allocate_arrays();
    expressp_allocate_arrays();
    files_allocate_arrays();

    lexer_allocate_arrays();
    memory_allocate_arrays();
    objects_allocate_arrays();
    states_allocate_arrays();
    symbols_allocate_arrays();
    syntax_allocate_arrays();
    tables_allocate_arrays();
    text_allocate_arrays();
    veneer_allocate_arrays();
    verbs_allocate_arrays();
}

extern void free_arrays(void)
{
    /*  One array may survive this routine, all_the_text (used to hold
        game text until the abbreviations optimiser begins work on it): this
        array (if it was ever allocated) is freed at the top level.          */

    arrays_free_arrays();
    asm_free_arrays();
    bpatch_free_arrays();
    chars_free_arrays();
    directs_free_arrays();
    errors_free_arrays();
    expressc_free_arrays();
    expressp_free_arrays();
    files_free_arrays();

    lexer_free_arrays();
    memory_free_arrays();
    objects_free_arrays();
    states_free_arrays();
    symbols_free_arrays();
    syntax_free_arrays();
    tables_free_arrays();
    text_free_arrays();
    veneer_free_arrays();
    verbs_free_arrays();
}

/* ------------------------------------------------------------------------- */
/*    Name translation code for filenames                                    */
/* ------------------------------------------------------------------------- */

static char Source_Path[PATHLEN];
static char Include_Path[PATHLEN];
static char Code_Path[PATHLEN];
static char current_source_path[PATHLEN];
       char Debugging_Name[PATHLEN];
       char Transcript_Name[PATHLEN];
       char Language_Name[PATHLEN];
       char Charset_Map[PATHLEN];
static char ICL_Path[PATHLEN];

/* Set one of the above Path buffers to the given location, or list of
   locations. (A list is comma-separated, and only accepted for Source_Path,
   Include_Path, ICL_Path.)
*/
static void set_path_value(char *path, char *value)
{   int i, j;

    for (i=0, j=0;;)
    {
        if (i >= PATHLEN-1) {
            printf("A specified path is longer than %d characters.\n",
                PATHLEN-1);
            exit(1);
        }
        if ((value[j] == FN_ALT) || (value[j] == 0))
        {   if ((value[j] == FN_ALT)
                && (path != Source_Path) && (path != Include_Path)
                && (path != ICL_Path))
            {   printf("The character '%c' is used to divide entries in a list \
of possible locations, and can only be used in the Include_Path, Source_Path \
or ICL_Path variables. Other paths are for output only.\n", FN_ALT);
                exit(1);
            }
            if ((path != Debugging_Name) && (path != Transcript_Name)
                 && (path != Language_Name) && (path != Charset_Map)
                 && (i>0) && (isalnum((uchar)path[i-1]))) path[i++] = FN_SEP;
            path[i++] = value[j++];
            if (value[j-1] == 0) return;
        }
        else path[i++] = value[j++];
    }
}

/* Prepend the given location or list of locations to one of the above
   Path buffers. This is only permitted for Source_Path, Include_Path, 
   ICL_Path.

   An empty field (in the comma-separated list) means the current
   directory. If the Path buffer is entirely empty, we assume that
   we want to search both value and the current directory, so
   the result will be "value,".
*/
static void prepend_path_value(char *path, char *value)
{
    int i, j;
    int oldlen = strlen(path);
    int newlen;
    char new_path[PATHLEN];

    if ((path != Source_Path) && (path != Include_Path)
        && (path != ICL_Path))
    {   printf("The character '+' is used to add to a list \
of possible locations, and can only be used in the Include_Path, Source_Path \
or ICL_Path variables. Other paths are for output only.\n");
        exit(1);
    }

    for (i=0, j=0;;)
    {
        if (i >= PATHLEN-1) {
            printf("A specified path is longer than %d characters.\n",
                PATHLEN-1);
            exit(1);
        }
        if ((value[j] == FN_ALT) || (value[j] == 0))
        {   if ((path != Debugging_Name) && (path != Transcript_Name)
                 && (path != Language_Name) && (path != Charset_Map)
                 && (i>0) && (isalnum((uchar)new_path[i-1]))) new_path[i++] = FN_SEP;
            new_path[i++] = value[j++];
            if (value[j-1] == 0) {
                newlen = i-1;
                break;
            }
        }
        else new_path[i++] = value[j++];
    }

    if (newlen+1+oldlen >= PATHLEN-1) {
        printf("A specified path is longer than %d characters.\n",
            PATHLEN-1);
        exit(1);
    }

    i = newlen;
    new_path[i++] = FN_ALT;
    for (j=0; j<oldlen;)
        new_path[i++] = path[j++];
    new_path[i] = 0;
    
    strcpy(path, new_path);
}

static void set_default_paths(void)
{
    set_path_value(Source_Path,     Source_Directory);
    set_path_value(Include_Path,    Include_Directory);
    set_path_value(Code_Path,       Code_Directory);
    set_path_value(ICL_Path,        ICL_Directory);
    set_path_value(Debugging_Name,  Debugging_File);
    set_path_value(Transcript_Name, Transcript_File);
    set_path_value(Language_Name,   Default_Language);
    set_path_value(Charset_Map,     "");
}

/* Parse a path option which looks like "dir", "+dir", "pathname=dir",
   or "+pathname=dir". If there is no "=", we assume "include_path=...".
   If the option begins with a "+" the directory is prepended to the
   existing path instead of replacing it.
*/
static void set_path_command(char *command)
{   int i, j; char *path_to_set = NULL;
    int prepend = 0;

    if (command[0] == '+') {
        prepend = 1;
        command++;
    }

    for (i=0; (command[i]!=0) && (command[i]!='=');i++) ;

    path_to_set=Include_Path; 

    if (command[i] == '=') { 
        char pathname[PATHLEN];
        if (i>=PATHLEN) i=PATHLEN-1;
        for (j=0;j<i;j++) {
            char ch = command[j];
            if (isupper(ch)) ch=tolower(ch);
            pathname[j]=ch;
        }
        pathname[j]=0;
        command = command+i+1;

        path_to_set = NULL;
        if (strcmp(pathname, "source_path")==0)  path_to_set=Source_Path;
        if (strcmp(pathname, "include_path")==0) path_to_set=Include_Path;
        if (strcmp(pathname, "code_path")==0)    path_to_set=Code_Path;
        if (strcmp(pathname, "icl_path")==0)     path_to_set=ICL_Path;
        if (strcmp(pathname, "debugging_name")==0) path_to_set=Debugging_Name;
        if (strcmp(pathname, "transcript_name")==0) path_to_set=Transcript_Name;
        if (strcmp(pathname, "language_name")==0) path_to_set=Language_Name;
        if (strcmp(pathname, "charset_map")==0) path_to_set=Charset_Map;

        if (path_to_set == NULL)
        {   printf("No such path setting as \"%s\"\n", pathname);
            exit(1);
        }
    }

    if (!prepend)
        set_path_value(path_to_set, command);
    else
        prepend_path_value(path_to_set, command);
}

static int contains_separator(char *name)
{   int i;
    for (i=0; name[i]!=0; i++)
        if (name[i] == FN_SEP) return 1;
    return 0;
}

static int write_translated_name(char *new_name, char *old_name,
                                 char *prefix_path, int start_pos,
                                 char *extension)
{   int x;
    if (strlen(old_name)+strlen(extension) >= PATHLEN) {
        printf("One of your filenames is longer than %d characters.\n", PATHLEN);
        exit(1);
    }
    if (prefix_path == NULL)
    {   sprintf(new_name,"%s%s", old_name, extension);
        return 0;
    }
    strcpy(new_name, prefix_path + start_pos);
    for (x=0; (new_name[x]!=0) && (new_name[x]!=FN_ALT); x++) ;
    if (new_name[x] == 0) start_pos = 0; else start_pos += x+1;
    if (x+strlen(old_name)+strlen(extension) >= PATHLEN) {
        printf("One of your pathnames is longer than %d characters.\n", PATHLEN);
        exit(1);
    }
    sprintf(new_name + x, "%s%s", old_name, extension);
    return start_pos;
}

#ifdef FILE_EXTENSIONS
static char *check_extension(char *name, char *extension)
{   int i;

    /* If a filename ends in '.', remove the dot and add no file extension: */
    i = strlen(name)-1;
    if (name[i] == '.') { name[i]=0; return ""; }

    /* Remove the new extension if it's already got one: */

    for (; (i>=0) && (name[i]!=FN_SEP); i--)
        if (name[i] == '.') return "";
    return extension;
}
#endif

/* ------------------------------------------------------------------------- */
/*    Three translation routines have to deal with path variables which may  */
/*    contain alternative locations separated by the FN_ALT character.       */
/*    These have the protocol:                                               */
/*                                                                           */
/*        int translate_*_filename(int last_value, ...)                      */
/*                                                                           */
/*    and should first be called with last_value equal to 0.  If the         */
/*    translated filename works, fine.  Otherwise, if the returned integer   */
/*    was zero, the caller knows that no filename works and can issue an     */
/*    error message.  If it was non-zero, the caller should pass it on as    */
/*    the last_value again.                                                  */
/*                                                                           */
/*    As implemented below, last_value is the position in the path variable  */
/*    string at which the next directory name to try begins.                 */
/* ------------------------------------------------------------------------- */

extern int translate_in_filename(int last_value,
    char *new_name, char *old_name,
    int same_directory_flag, int command_line_flag)
{   char *prefix_path = NULL;
    char *extension;
    int add_path_flag = 1;
    int i;

    if ((same_directory_flag==0)
        && (contains_separator(old_name)==1)) add_path_flag=0;

    if (add_path_flag==1)
    {   if (command_line_flag == 0)
        {   /* File is opened as a result of an Include directive */

            if (same_directory_flag==1)
                prefix_path = current_source_path;
            else
                if (Include_Path[0]!=0) prefix_path = Include_Path;
        }
        /* Main file being opened from the command line */

        else if (Source_Path[0]!=0) prefix_path = Source_Path;
    }

#ifdef FILE_EXTENSIONS
    /* Which file extension is expected? */

    if ((command_line_flag==1)||(same_directory_flag==1))
        extension = Source_Extension;
    else
        extension = Include_Extension;

    extension = check_extension(old_name, extension);
#else
    extension = "";
#endif

    last_value = write_translated_name(new_name, old_name,
                     prefix_path, last_value, extension);

    /* Set the "current source path" (for use of Include ">...") */

    if (command_line_flag==1)
    {   strcpy(current_source_path, new_name);
        for (i=strlen(current_source_path)-1;
             ((i>0)&&(current_source_path[i]!=FN_SEP));i--) ;

        if (i!=0) current_source_path[i+1] = 0; /* Current file in subdir   */
        else current_source_path[0] = 0;        /* Current file at root dir */
    }

    return last_value;
}

static int translate_icl_filename(int last_value,
    char *new_name, char *old_name)
{   char *prefix_path = NULL;
    char *extension = "";

    if (contains_separator(old_name)==0)
        if (ICL_Path[0]!=0)
            prefix_path = ICL_Path;

#ifdef FILE_EXTENSIONS
    extension = check_extension(old_name, ICL_Extension);
#endif

    return write_translated_name(new_name, old_name,
               prefix_path, last_value, extension);
}

extern void translate_out_filename(char *new_name, char *old_name)
{   char *prefix_path;
    char *extension = "";
    int i;

    /* If !convert_filename_flag, then the old_name is just the <file2>
       parameter on the Inform command line, which we leave alone. */

    if (!convert_filename_flag)
    {   strcpy(new_name, old_name); return;
    }

    /* Remove any pathname or extension in <file1>. */

    if (contains_separator(old_name)==1)
    {   for (i=strlen(old_name)-1; (i>0)&&(old_name[i]!=FN_SEP) ;i--) { };
        if (old_name[i]==FN_SEP) i++;
        old_name += i;
    }
#ifdef FILE_EXTENSIONS
    for (i=strlen(old_name)-1; (i>=0)&&(old_name[i]!='.') ;i--) ;
    if (old_name[i] == '.') old_name[i] = 0;
#endif

    prefix_path = NULL;
    
    if (!glulx_mode) {
        switch(version_number)
        {   case 3: extension = Code_Extension;   break;
            case 4: extension = V4Code_Extension; break;
            case 5: extension = V5Code_Extension; break;
            case 6: extension = V6Code_Extension; break;
            case 7: extension = V7Code_Extension; break;
            case 8: extension = V8Code_Extension; break;
        }
    }
    else {
        extension = GlulxCode_Extension;
    }
    if (Code_Path[0]!=0) prefix_path = Code_Path;

#ifdef FILE_EXTENSIONS
    extension = check_extension(old_name, extension);
#endif

    write_translated_name(new_name, old_name, prefix_path, 0, extension);
}

static char *name_or_unset(char *p)
{   if (p[0]==0) return "(unset)";
    return p;
}

static void help_on_filenames(void)
{   char old_name[PATHLEN];
    char new_name[PATHLEN];
    int x;

    printf("Help information on filenames:\n\n");

    printf(
"The command line can take one of two forms:\n\n\
  inform [commands...] <file1>\n\
  inform [commands...] <file1> <file2>\n\n\
Inform translates <file1> into a source file name (see below) for its input.\n\
<file2> is usually omitted: if so, the output filename is made from <file1>\n\
by cutting out the name part and translating that (see below).\n\
If <file2> is given, however, the output filename is set to just <file2>\n\
(not altered in any way).\n\n");

    printf(
"Filenames given in the game source (with commands like Include \"name\")\n\
are also translated by the rules below.\n\n");

    printf(
"Rules of translation:\n\n\
Inform translates plain filenames (such as \"xyzzy\") into full pathnames\n\
(such as \"adventure%cgames%cxyzzy\") according to the following rules.\n\n\
1. If the name contains a '%c' character (so it's already a pathname), it\n\
   isn't changed.\n\n", FN_SEP, FN_SEP, FN_SEP);

    printf(
"   [Exception: when the name is given in an Include command using the >\n\
   form (such as Include \">prologue\"), the \">\" is replaced by the path\n\
   of the file doing the inclusion");
#ifdef FILE_EXTENSIONS
                          printf(" and a suitable file extension is added");
#endif
    printf(".]\n\n");

    printf(
"   Filenames must never contain double-quotation marks \".  To use filenames\n\
   which contain spaces, write them in double-quotes: for instance,\n\n\
   \"inform +code_path=\"Jigsaw Final Version\" jigsaw\".\n\n");

    printf(
"2. The file is looked for at a particular \"path\" (the filename of a\n\
   directory), depending on what kind of file it is.\n\n\
       File type              Name                Current setting\n\n\
       Source code (in)       source_path         %s\n\
       Include file (in)      include_path        %s\n\
       Story file (out)       code_path           %s\n",
   name_or_unset(Source_Path), name_or_unset(Include_Path),
   name_or_unset(Code_Path));

    printf(
"       ICL command file (in)  icl_path            %s\n\n",
   name_or_unset(ICL_Path));

    printf(
"   If the path is unset, then the current working directory is used (so\n\
   the filename doesn't change): if, for instance, include_path is set to\n\
   \"backup%coldlib\" then when \"parser\" is included it is looked for at\n\
   \"backup%coldlib%cparser\".\n\n\
   The paths can be set or unset on the Inform command line by, eg,\n\
   \"inform +code_path=finished jigsaw\" or\n\
   \"inform +include_path= balances\" (which unsets include_path).\n\n",
        FN_SEP, FN_SEP, FN_SEP);

    printf(
"   The four input path variables can be set to lists of alternative paths\n\
   separated by '%c' characters: these alternatives are always tried in\n\
   the order they are specified in, that is, left to right through the text\n\
   in the path variable.\n\n",
   FN_ALT);
    printf(
"   If two '+' signs are used (\"inform ++include_path=dir jigsaw\") then\n\
   the path or paths are added to the existing list.\n\n");
    printf(
"   (It is an error to give alternatives at all for purely output paths.)\n\n");

#ifdef FILE_EXTENSIONS
    printf("3. The following file extensions are added:\n\n\
      Source code:     %s\n\
      Include files:   %s\n\
      Story files:     %s (Version 3), %s (v4), %s (v5, the default),\n\
                       %s (v6), %s (v7), %s (v8), %s (Glulx)\n\n",
      Source_Extension, Include_Extension,
      Code_Extension, V4Code_Extension, V5Code_Extension, V6Code_Extension,
      V7Code_Extension, V8Code_Extension, GlulxCode_Extension);
    printf("\
   except that any extension you give (on the command line or in a filename\n\
   used in a program) will override these.  If you give the null extension\n\
   \".\" then Inform uses no file extension at all (removing the \".\").\n\n");
#endif

    printf("Names of four individual files can also be set using the same\n\
  + command notation (though they aren't really pathnames).  These are:\n\n\
      transcript_name  (text written by -r switch): now \"%s\"\n\
      debugging_name   (data written by -k switch): now \"%s\"\n\
      language_name    (library file defining natural language of game):\n\
                       now \"%s\"\n\
      charset_map      (file for character set mapping): now \"%s\"\n\n",
    Transcript_Name, Debugging_Name, Language_Name, Charset_Map);

    translate_in_filename(0, new_name, "rezrov", 0, 1);
    printf("Examples: 1. \"inform rezrov\"\n\
  the source code is read from \"%s\"\n",
        new_name);
    convert_filename_flag = TRUE;
    translate_out_filename(new_name, "rezrov");
    printf("  and a story file is compiled to \"%s\".\n\n", new_name);

    sprintf(old_name, "demos%cplugh", FN_SEP);
    printf("2. \"inform %s\"\n", old_name);
    translate_in_filename(0, new_name, old_name, 0, 1);
    printf("  the source code is read from \"%s\"\n", new_name);
    sprintf(old_name, "demos%cplugh", FN_SEP);
    convert_filename_flag = TRUE;
    translate_out_filename(new_name, old_name);
    printf("  and a story file is compiled to \"%s\".\n\n", new_name);

    printf("3. \"inform plover my_demo\"\n");
    translate_in_filename(0, new_name, "plover", 0, 1);
    printf("  the source code is read from \"%s\"\n", new_name);
    convert_filename_flag = FALSE;
    translate_out_filename(new_name, "my_demo");
    printf("  and a story file is compiled to \"%s\".\n\n", new_name);

    strcpy(old_name, Source_Path);
    sprintf(new_name, "%cnew%cold%crecent%cold%cancient",
        FN_ALT, FN_ALT, FN_SEP, FN_ALT, FN_SEP);
    printf("4. \"inform +source_path=%s zooge\"\n", new_name);
    printf(
"   Note that four alternative paths are given, the first being the empty\n\
   path-name (meaning: where you are now).  Inform looks for the source code\n\
   by trying these four places in turn, stopping when it finds anything:\n\n");

    set_path_value(Source_Path, new_name);
    x = 0;
    do
    {   x = translate_in_filename(x, new_name, "zooge", 0, 1);
        printf("     \"%s\"\n", new_name);
    } while (x != 0);
    strcpy(Source_Path, old_name);
}

#ifdef ARCHIMEDES
static char riscos_ft_buffer[4];

extern char *riscos_file_type(void)
{
    if (riscos_file_type_format == 1)
    {
        return("11A");
    }

    sprintf(riscos_ft_buffer, "%03x", 0x60 + version_number);
    return(riscos_ft_buffer);
}
#endif

/* ------------------------------------------------------------------------- */
/*   The compilation pass                                                    */
/* ------------------------------------------------------------------------- */

static void run_pass(void)
{
    lexer_begin_prepass();
    files_begin_prepass();
    load_sourcefile(Source_Name, 0);

    begin_pass();

    parse_program(NULL);

    ensure_builtin_globals();
    find_the_actions();
    issue_unused_warnings();
    compile_veneer();

    lexer_endpass();

    issue_debug_symbol_warnings();
    
    close_all_source();
    if (hash_switch && hash_printed_since_newline) printf("\n");

    sort_dictionary();
    if (GRAMMAR_META_FLAG)
        sort_actions();
    if (track_unused_routines)
        locate_dead_functions();
    locate_dead_grammar_lines();
    construct_storyfile();
}

int output_has_occurred;

static void rennab(float time_taken)
{   /*  rennab = reverse of banner  */
    int t = no_warnings + no_suppressed_warnings;

    if (memout_switch) print_memory_usage();

    if ((no_errors + t)!=0)
    {   printf("Compiled with ");
        if (no_errors > 0)
        {   printf("%d error%s", no_errors,(no_errors==1)?"":"s");
            if (t > 0) printf(" and ");
        }
        if (no_warnings > 0)
            printf("%d warning%s", t, (t==1)?"":"s");
        if (no_suppressed_warnings > 0)
        {   if (no_warnings > 0)
                printf(" (%d suppressed)", no_suppressed_warnings);
            else
            printf("%d suppressed warning%s", no_suppressed_warnings,
                (no_suppressed_warnings==1)?"":"s");
        }
        if (output_has_occurred == FALSE) printf(" (no output)");
        printf("\n");
    }

    if (no_compiler_errors > 0) print_sorry_message();

    if (statistics_switch)
    {
        /* Print the duration to a sensible number of decimal places.
           (We aim for three significant figures.) */
        if (time_taken >= 10.0)
            printf("Completed in %.1f seconds\n", time_taken);
        else if (time_taken >= 1.0)
            printf("Completed in %.2f seconds\n", time_taken);
        else
            printf("Completed in %.3f seconds\n", time_taken);
    }
}

/* ------------------------------------------------------------------------- */
/*   The compiler abstracted to a routine.                                   */
/* ------------------------------------------------------------------------- */

static int execute_icl_header(char *file1);

static int compile(int number_of_files_specified, char *file1, char *file2)
{
    TIMEVALUE time_start, time_end;
    float duration;

    if (execute_icl_header(file1))
      return 1;

    select_target(glulx_mode);

    if (define_INFIX_switch && glulx_mode) {
        printf("Infix (-X) facilities are not available in Glulx: \
disabling -X switch\n");
        define_INFIX_switch = FALSE;
    }

    TIMEVALUE_NOW(&time_start);
    
    no_compilations++;

    strcpy(Source_Name, file1); convert_filename_flag = TRUE;
    strcpy(Code_Name, file1);
    if (number_of_files_specified == 2)
    {   strcpy(Code_Name, file2); convert_filename_flag = FALSE;
    }

    init_vars();

    if (debugfile_switch) begin_debug_file();

    allocate_arrays();

    if (transcript_switch) open_transcript_file(Source_Name);

    run_pass();

    if (no_errors==0) { output_file(); output_has_occurred = TRUE; }
    else { output_has_occurred = FALSE; }

    if (transcript_switch)
    {   write_dictionary_to_transcript();
        close_transcript_file();
    }

    if (debugfile_switch)
    {   end_debug_file();
    }

    if (optimise_switch) {
        /* Pull out all_text so that it will not be freed. */
        extract_all_text();
    }

    free_arrays();

    TIMEVALUE_NOW(&time_end);
    duration = TIMEVALUE_DIFFERENCE(&time_start, &time_end);
    
    rennab(duration);

    if (optimise_switch) {
        optimise_abbreviations();
        ao_free_arrays();
    }

    return (no_errors==0)?0:1;
}

/* ------------------------------------------------------------------------- */
/*   The command line interpreter                                            */
/* ------------------------------------------------------------------------- */

static void cli_print_help(int help_level)
{
    printf(
"\nThis program is a compiler of Infocom format (also called \"Z-machine\")\n\
story files, as well as \"Glulx\" story files:\n\
Copyright (c) Graham Nelson 1993 - 2025.\n\n");

   /* For people typing just "inform", a summary only: */

   if (help_level==0)
   {

#ifndef PROMPT_INPUT
  printf("Usage: \"inform [commands...] <file1> [<file2>]\"\n\n");
#else
  printf("When run, Inform prompts you for commands (and switches),\n\
which are optional, then an input <file1> and an (optional) output\n\
<file2>.\n\n");
#endif

  printf(
"<file1> is the Inform source file of the game to be compiled. <file2>,\n\
if given, overrides the filename Inform would normally use for the\n\
compiled output.  Try \"inform -h1\" for file-naming conventions.\n\n\
One or more words can be supplied as \"commands\". These may be:\n\n\
  -switches     a list of compiler switches, 1 or 2 letter\n\
                (see \"inform -h2\" for the full range)\n\n\
  +dir          set Include_Path to this directory\n\
  ++dir         add this directory to Include_Path\n\
  +PATH=dir     change the PATH to this directory\n\
  ++PATH=dir    add this directory to the PATH\n\n\
  $...          one of the following configuration commands:\n");
  
  printf(
"     $list            list current settings\n\
     $?SETTING        explain briefly what SETTING is for\n\
     $SETTING=number  change SETTING to given number\n\
     $!TRACEOPT       set trace option TRACEOPT\n\
                      (or $!TRACEOPT=2, 3, etc for more tracing;\n\
                      $! by itself to list all trace options)\n\
     $#SYMBOL=number  define SYMBOL as a constant in the story\n\n");

  printf(
"  (filename)    read in a list of commands (in the format above)\n\
                from this \"setup file\"\n\n");

  printf("Alternate command-line formats for the above:\n\
  --help                 (this page)\n\
  --path PATH=dir        (set path)\n\
  --addpath PATH=dir     (add to path)\n\
  --list                 (list current settings)\n\
  --helpopt SETTING      (explain setting)\n\
  --opt SETTING=number   (change setting)\n\
  --helptrace            (list all trace options)\n\
  --trace TRACEOPT       (set trace option)\n\
  --trace TRACEOPT=num   (more tracing)\n\
  --define SYMBOL=number (define constant)\n\
  --config filename      (read setup file)\n\n");

#ifndef PROMPT_INPUT
    printf("For example: \"inform -dexs curses\".\n\n");
#endif

    printf(
"For fuller information, see the Inform Designer's Manual.\n");

       return;
   }

   /* The -h1 (filenaming) help information: */

   if (help_level == 1) { help_on_filenames(); return; }

   /* The -h2 (switches) help information: */

   printf("Help on the full list of legal switch commands:\n\n\
  a   trace assembly-language\n\
  a2  trace assembly with hex dumps\n\
  c   more concise error messages\n\
  d   contract double spaces after full stops in text\n\
  d2  contract double spaces after exclamation and question marks, too\n\
  e   economy mode (slower): make use of declared abbreviations\n");

   printf("\
  f   frequencies mode: show how useful abbreviations are\n\
  g   traces calls to all game functions\n\
  g2  traces calls to all game and library functions\n\
  g3  traces calls to all functions (including veneer)\n\
  h   print general help information\n\
  h1  print help information on filenames and path options\n\
  h2  print help information on switches (this page)\n");

   printf("\
  i   ignore default switches set within the file\n\
  k   output debugging information to \"%s\"\n",
          Debugging_Name);
   printf("\
  q   keep quiet about obsolete usages\n\
  r   record all the text to \"%s\"\n\
  s   give statistics\n",
      Transcript_Name);

   printf("\
  u   work out most useful abbreviations (very very slowly)\n\
  v3  compile to version-3 (\"Standard\"/\"ZIP\") story file\n\
  v4  compile to version-4 (\"Plus\"/\"EZIP\") story file\n\
  v5  compile to version-5 (\"Advanced\"/\"XZIP\") story file: the default\n\
  v6  compile to version-6 (graphical/\"YZIP\") story file\n\
  v7  compile to version-7 (expanded \"Advanced\") story file\n\
  v8  compile to version-8 (expanded \"Advanced\") story file\n\
  w   disable warning messages\n\
  x   print # for every 100 lines compiled\n\
  z   print memory map of the virtual machine\n\n");

printf("\
  B   use big memory model (for large V6/V7 files)\n\
  C0  text character set is plain ASCII only\n\
  Cu  text character set is UTF-8\n\
  Cn  text character set is ISO 8859-n (n = 1 to 9)\n\
      (1 to 4, Latin1 to Latin4; 5, Cyrillic; 6, Arabic;\n\
       7, Greek; 8, Hebrew; 9, Latin5.  Default is -C1.)\n");
printf("  D   insert \"Constant DEBUG;\" automatically\n");
printf("  E0  Archimedes-style error messages%s\n",
      (error_format==0)?" (current setting)":"");
printf("  E1  Microsoft-style error messages%s\n",
      (error_format==1)?" (current setting)":"");
printf("  E2  Macintosh MPW-style error messages%s\n",
      (error_format==2)?" (current setting)":"");
printf("  G   compile a Glulx game file\n");
printf("  H   use Huffman encoding to compress Glulx strings\n");

#ifdef ARCHIMEDES
printf("\
  R0  use filetype 060 + version number for games (default)\n\
  R1  use official Acorn filetype 11A for all games\n");
#endif
printf("  S   compile strict error-checking at run-time (on by default)\n");
#ifdef ARC_THROWBACK
printf("  T   enable throwback of errors in the DDE\n");
#endif
printf("  V   print the version and date of this program\n");
printf("  Wn  header extension table is at least n words (n = 3 to 99)\n");
printf("  X   compile with INFIX debugging facilities present\n");
  printf("\n");
}

extern void switches(char *p, int cmode)
{   int i, s=1, state;
    /* Here cmode is 0 if switches list is from a "Switches" directive
       and 1 if from a "-switches" command-line or ICL list */

    if (cmode==1)
    {   if (p[0]!='-')
        {   printf(
                "Ignoring second word which should be a -list of switches.\n");
            return;
        }
    }
    for (i=cmode; p[i]!=0; i+=s, s=1)
    {   state = TRUE;
        if (p[i] == '~')
        {   state = FALSE;
            i++;
        }
        switch(p[i])
        {
        case 'a': switch(p[i+1])
                  {   case '1': asm_trace_setting=1; s=2; break;
                      case '2': asm_trace_setting=2; s=2; break;
                      case '3': asm_trace_setting=3; s=2; break;
                      case '4': asm_trace_setting=4; s=2; break;
                      default: asm_trace_setting=1; break;
                  }
                  break;
        case 'c': concise_switch = state; break;
        case 'd': switch(p[i+1])
                  {   case '1': double_space_setting=1; s=2; break;
                      case '2': double_space_setting=2; s=2; break;
                      default: double_space_setting=1; break;
                  }
                  break;
        case 'e': economy_switch = state; break;
        case 'f': frequencies_setting = (state?1:0); break;
        case 'g': switch(p[i+1])
                  {   case '1': trace_fns_setting=1; s=2; break;
                      case '2': trace_fns_setting=2; s=2; break;
                      case '3': trace_fns_setting=3; s=2; break;
                      default: trace_fns_setting=1; break;
                  }
                  break;
        case 'h': switch(p[i+1])
                  {   case '1': cli_print_help(1); s=2; break;
                      case '2': cli_print_help(2); s=2; break;
                      case '0': s=2; /* Fall through */
                      default:  cli_print_help(0); break;
                  }
                  break;
        case 'i': ignore_switches_switch = state; break;
        case 'k': if (cmode == 0)
                      error("The switch '-k' can't be set with 'Switches'");
                  else
                      debugfile_switch = state;
                  break;
        case 'q': obsolete_switch = state; break;
        case 'r': if (cmode == 0)
                      error("The switch '-r' can't be set with 'Switches'");
                  else
                      transcript_switch = state;
                  break;
        case 's': statistics_switch = state; break;
        case 'u': if (cmode == 0) {
                      error("The switch '-u' can't be set with 'Switches'");
                      break;
                  }
                  optimise_switch = state; break;
        case 'v': if (glulx_mode) { s = select_glulx_version(p+i+1)+1; break; }
                  if ((cmode==0) && (version_set_switch)) { s=2; break; }
                  version_set_switch = TRUE; s=2;
                  switch(p[i+1])
                  {   case '3': select_version(3); break;
                      case '4': select_version(4); break;
                      case '5': select_version(5); break;
                      case '6': select_version(6); break;
                      case '7': select_version(7); break;
                      case '8': select_version(8); break;
                      default:  printf("-v must be followed by 3 to 8\n");
                                version_set_switch=0; s=1;
                                break;
                  }
                  if ((version_number < 5) && (r_e_c_s_set == FALSE))
                      runtime_error_checking_switch = FALSE;
                  break;
        case 'w': nowarnings_switch = state; break;
        case 'x': hash_switch = state; break;
        case 'z': memory_map_setting = (state ? 1 : 0); break;
        case 'B': oddeven_packing_switch = state; break;
        case 'C': s=2;
                  if (p[i+1] == 'u') {
                      character_set_unicode = TRUE;
                      /* Leave the set_setting on Latin-1, because that 
                         matches the first block of Unicode. */
                      character_set_setting = 1;
                  }
                  else 
                  {   character_set_setting=p[i+1]-'0';
                      if ((character_set_setting < 0)
                          || (character_set_setting > 9))
                      {   printf("-C must be followed by 'u' or 0 to 9. Defaulting to ISO-8859-1.\n");
                          character_set_unicode = FALSE;
                          character_set_setting = 1;
                      }
                  }
                  if (cmode == 0) change_character_set();
                  break;
        case 'D': define_DEBUG_switch = state; break;
        case 'E': switch(p[i+1])
                  {   case '0': s=2; error_format=0; break;
                      case '1': s=2; error_format=1; break;
                      case '2': s=2; error_format=2; break;
                      default:  error_format=1; break;
                  }
                  break;
#ifdef ARCHIMEDES
        case 'R': switch(p[i+1])
                  {   case '0': s=2; riscos_file_type_format=0; break;
                      case '1': s=2; riscos_file_type_format=1; break;
                      default:  riscos_file_type_format=1; break;
                  }
                  break;
#endif
#ifdef ARC_THROWBACK
        case 'T': throwback_switch = state; break;
#endif
        case 'S': runtime_error_checking_switch = state;
                  r_e_c_s_set = TRUE; break;
        case 'G': if (cmode == 0)
                      error("The switch '-G' can't be set with 'Switches'");
                  else if (version_set_switch)
                      error("The '-G' switch cannot follow the '-v' switch");
                  else
                  {   glulx_mode = state;
                      adjust_memory_sizes();
                  }
                  break;
        case 'H': compression_switch = state; break;
        case 'V': exit(0); break;
        case 'W': if ((p[i+1]>='0') && (p[i+1]<='9'))
                  {   s=2; ZCODE_HEADER_EXT_WORDS = p[i+1]-'0';
                      if ((p[i+2]>='0') && (p[i+2]<='9'))
                      {   s=3; ZCODE_HEADER_EXT_WORDS *= 10;
                          ZCODE_HEADER_EXT_WORDS += p[i+2]-'0';
                      }
                  }
                  break;
        case 'X': define_INFIX_switch = state; break;
        default:
          printf("Switch \"-%c\" unknown (try \"inform -h2\" for the list)\n",
              p[i]);
          break;
        }
    }

    if (optimise_switch)
    {
        /* store_the_text is equivalent to optimise_switch; -u sets both.
           We could simplify this. */
        store_the_text=TRUE;
    }
}

/* Check whether the string looks like an ICL command. */
static int icl_command(char *p)
{   if ((p[0]=='+')||(p[0]=='-')||(p[0]=='$')
        || ((p[0]=='(')&&(p[strlen(p)-1]==')')) ) return TRUE;
    return FALSE;
}

static void icl_error(char *filename, int line)
{   printf("Error in ICL file '%s', line %d:\n", filename, line);
}

static void icl_header_error(char *filename, int line)
{   printf("Error in ICL header of file '%s', line %d:\n", filename, line);
}

static int copy_icl_word(char *from, char *to, int max)
{
    /*  Copies one token from 'from' to 'to', null-terminated:
        returns the number of chars in 'from' read past (possibly 0).  */

    int i, j, quoted_mode, truncated;

    i = 0; truncated = 0;
    while ((from[i] == ' ') || (from[i] == TAB_CHARACTER)
           || (from[i] == (char) 10) || (from[i] == (char) 13)) i++;

    if (from[i] == '!')
    {   while (from[i] != 0) i++;
        to[0] = 0; return i;
    }

    for (quoted_mode = FALSE, j=0;;)
    {   if (from[i] == 0) break;
        if (from[i] == 10) break;
        if (from[i] == 13) break;
        if (from[i] == TAB_CHARACTER) break;
        if ((from[i] == ' ') && (!quoted_mode)) break;
        if (from[i] == '\"') { quoted_mode = !quoted_mode; i++; }
        else to[j++] = from[i++];
        if (j == max) {
            j--;
            truncated = 1;
        }
    }
    to[j] = 0;
    if (truncated == 1)
        printf("The following parameter has been truncated:\n%s\n", to);
    return i;
}

/* Copy a string, converting to uppercase. The to array should be
   (at least) max characters. Result will be null-terminated, so
   at most max-1 characters will be copied. 
*/
static int strcpyupper(char *to, char *from, int max)
{
    int ix;
    for (ix=0; ix<max-1; ix++) {
        char ch = from[ix];
        if (islower(ch)) ch = toupper(ch);
        to[ix] = ch;
    }
    to[ix] = 0;
    return ix;
}

static void execute_icl_command(char *p);
static int execute_dashdash_command(char *p, char *p2);

/* Open a file and see whether the initial lines match the "!% ..." format
   used for ICL commands. Stop when we reach a line that doesn't.
   
   This does not do line break conversion. It just reads to the next
   \n (and ignores \r as whitespace). Therefore it will work on Unix and
   DOS source files, but fail to cope with Mac-Classic (\r) source files.
   I am not going to worry about this, because files from the Mac-Classic
   era shouldn't have "!%" lines; that convention was invented well after
   Mac switched over to \n format.
 */
static int execute_icl_header(char *argname)
{
  FILE *command_file;
  char cli_buff[CMD_BUF_SIZE], fw[CMD_BUF_SIZE];
  int line = 0;
  int errcount = 0;
  int i;
  char filename[PATHLEN]; 
  int x = 0;

  do
    {   x = translate_in_filename(x, filename, argname, 0, 1);
        command_file = fopen(filename,"rb");
    } while ((command_file == NULL) && (x != 0));
  if (!command_file) {
    /* Fail silently. The regular compiler will try to open the file
       again, and report the problem. */
    return 0;
  }

  while (feof(command_file)==0) {
    if (fgets(cli_buff,CMD_BUF_SIZE,command_file)==0) break;
    line++;
    if (!(cli_buff[0] == '!' && cli_buff[1] == '%'))
      break;
    i = copy_icl_word(cli_buff+2, fw, CMD_BUF_SIZE);
    if (icl_command(fw)) {
      execute_icl_command(fw);
      copy_icl_word(cli_buff+2 + i, fw, CMD_BUF_SIZE);
      if ((fw[0] != 0) && (fw[0] != '!')) {
        icl_header_error(filename, line);
        errcount++;
        printf("expected comment or nothing but found '%s'\n", fw);
      }
    }
    else {
      if (fw[0]!=0) {
        icl_header_error(filename, line);
        errcount++;
        printf("Expected command or comment but found '%s'\n", fw);
      }
    }
  }
  fclose(command_file);

  return (errcount==0)?0:1;
}


static void run_icl_file(char *filename, FILE *command_file)
{   char cli_buff[CMD_BUF_SIZE], fw[CMD_BUF_SIZE];
    int i, x, line = 0;
    printf("[Running ICL file '%s']\n", filename);

    while (feof(command_file)==0)
    {   if (fgets(cli_buff,CMD_BUF_SIZE,command_file)==0) break;
        line++;
        i = copy_icl_word(cli_buff, fw, CMD_BUF_SIZE);
        if (icl_command(fw))
        {   execute_icl_command(fw);
            copy_icl_word(cli_buff + i, fw, CMD_BUF_SIZE);
            if ((fw[0] != 0) && (fw[0] != '!'))
            {   icl_error(filename, line);
                printf("expected comment or nothing but found '%s'\n", fw);
            }
        }
        else
        {   if (strcmp(fw, "compile")==0)
            {   char story_name[PATHLEN], code_name[PATHLEN];
                i += copy_icl_word(cli_buff + i, story_name, PATHLEN);
                i += copy_icl_word(cli_buff + i, code_name, PATHLEN);

                if (code_name[0] != 0) x=2;
                else if (story_name[0] != 0) x=1;
                else x=0;

                switch(x)
                {   case 0: icl_error(filename, line);
                            printf("No filename given to 'compile'\n");
                            break;
                    case 1: printf("[Compiling <%s>]\n", story_name);
                            compile(x, story_name, code_name);
                            break;
                    case 2: printf("[Compiling <%s> to <%s>]\n",
                                story_name, code_name);
                            compile(x, story_name, code_name);
                            copy_icl_word(cli_buff + i, fw, CMD_BUF_SIZE);
                            if (fw[0]!=0)
                            {   icl_error(filename, line);
                        printf("Expected comment or nothing but found '%s'\n",
                                fw);
                            }
                            break;
                }
            }
            else
            if (fw[0]!=0)
            {   icl_error(filename, line);
                printf("Expected command or comment but found '%s'\n", fw);
            }
        }
    }
}

/* This should only be called if the argument has been verified to be
   an ICL command, e.g. by checking icl_command().
*/
static void execute_icl_command(char *p)
{   char filename[PATHLEN], cli_buff[CMD_BUF_SIZE];
    FILE *command_file;
    int len;
    
    switch(p[0])
    {   case '+': set_path_command(p+1); break;
        case '-': switches(p,1); break;
        case '$': memory_command(p+1); break;
        case '(': len = strlen(p);
                  if (p[len-1] != ')') {
                      printf("Error in ICL: (command) missing closing paren\n");
                      break;
                  }
                  len -= 2; /* omit parens */
                  if (len > CMD_BUF_SIZE-1) len = CMD_BUF_SIZE-1;
                  strncpy(cli_buff, p+1, len);
                  cli_buff[len]=0;
                  {   int x = 0;
                      do
                      {   x = translate_icl_filename(x, filename, cli_buff);
                          command_file = fopen(filename,"r");
                      } while ((command_file == NULL) && (x != 0));
                  }
                  if (command_file == NULL) {
                      printf("Error in ICL: Couldn't open command file '%s'\n",
                          filename);
                      break;
                  }
                  run_icl_file(filename, command_file);
                  fclose(command_file);
                  break;
    }
}

/* Convert a --command into the equivalent ICL command and call 
   execute_icl_command(). The dashes have already been stripped.

   The second argument is the following command-line argument 
   (or NULL if there was none). This may or may not be consumed.
   Returns TRUE if it was.
*/
static int execute_dashdash_command(char *p, char *p2)
{
    char cli_buff[CMD_BUF_SIZE];
    int consumed2 = FALSE;
    
    if (!strcmp(p, "help")) {
        strcpy(cli_buff, "-h");
    }
    else if (!strcmp(p, "list")) {
        strcpy(cli_buff, "$LIST");
    }
    else if (!strcmp(p, "size")) {
        consumed2 = TRUE;
        /* We accept these arguments even though they've been withdrawn. */
        if (!(p2 && (!strcmpcis(p2, "HUGE") || !strcmpcis(p2, "LARGE") || !strcmpcis(p2, "SMALL")))) {
            printf("--size must be followed by \"huge\", \"large\", or \"small\"\n");
            return consumed2;
        }
        strcpy(cli_buff, "$");
        strcpyupper(cli_buff+1, p2, CMD_BUF_SIZE-1);
    }
    else if (!strcmp(p, "opt")) {
        consumed2 = TRUE;
        if (!p2 || !strchr(p2, '=')) {
            printf("--opt must be followed by \"setting=number\"\n");
            return consumed2;
        }
        strcpy(cli_buff, "$");
        strcpyupper(cli_buff+1, p2, CMD_BUF_SIZE-1);
    }
    else if (!strcmp(p, "helpopt")) {
        consumed2 = TRUE;
        if (!p2) {
            printf("--helpopt must be followed by \"setting\"\n");
            return consumed2;
        }
        strcpy(cli_buff, "$?");
        strcpyupper(cli_buff+2, p2, CMD_BUF_SIZE-2);
    }
    else if (!strcmp(p, "define")) {
        consumed2 = TRUE;
        if (!p2) {
            printf("--define must be followed by \"symbol=number\"\n");
            return consumed2;
        }
        strcpy(cli_buff, "$#");
        strcpyupper(cli_buff+2, p2, CMD_BUF_SIZE-2);
    }
    else if (!strcmp(p, "path")) {
        consumed2 = TRUE;
        if (!p2 || !strchr(p2, '=')) {
            printf("--path must be followed by \"name=path\"\n");
            return consumed2;
        }
        snprintf(cli_buff, CMD_BUF_SIZE, "+%s", p2);
    }
    else if (!strcmp(p, "addpath")) {
        consumed2 = TRUE;
        if (!p2 || !strchr(p2, '=')) {
            printf("--addpath must be followed by \"name=path\"\n");
            return consumed2;
        }
        snprintf(cli_buff, CMD_BUF_SIZE, "++%s", p2);
    }
    else if (!strcmp(p, "config")) {
        consumed2 = TRUE;
        if (!p2) {
            printf("--config must be followed by \"file.icl\"\n");
            return consumed2;
        }
        snprintf(cli_buff, CMD_BUF_SIZE, "(%s)", p2);
    }
    else if (!strcmp(p, "trace")) {
        consumed2 = TRUE;
        if (!p2) {
            printf("--trace must be followed by \"traceopt\" or \"traceopt=N\"\n");
            return consumed2;
        }
        snprintf(cli_buff, CMD_BUF_SIZE, "$!%s", p2);
    }
    else if (!strcmp(p, "helptrace")) {
        strcpy(cli_buff, "$!");
    }
    else {
        printf("Option \"--%s\" unknown (try \"inform -h\")\n", p);
        return FALSE;
    }

    execute_icl_command(cli_buff);
    return consumed2;
}

/* ------------------------------------------------------------------------- */
/*   Opening and closing banners                                             */
/* ------------------------------------------------------------------------- */

char banner_line[CMD_BUF_SIZE];

/* We store the banner text for use elsewhere (see files.c).
*/
static void banner(void)
{
    int len;
    snprintf(banner_line, CMD_BUF_SIZE, "Inform %d.%d%d",
        (VNUMBER/100)%10, (VNUMBER/10)%10, VNUMBER%10);
#ifdef RELEASE_SUFFIX
    len = strlen(banner_line);
    snprintf(banner_line+len, CMD_BUF_SIZE-len, "%s", RELEASE_SUFFIX);
#endif
#ifdef MACHINE_STRING
    len = strlen(banner_line);
    snprintf(banner_line+len, CMD_BUF_SIZE-len, " for %s", MACHINE_STRING);
#endif
    len = strlen(banner_line);
    snprintf(banner_line+len, CMD_BUF_SIZE-len, " (%s)", RELEASE_DATE);
    
    printf("%s\n", banner_line);
}

/* ------------------------------------------------------------------------- */
/*   Input from the outside world                                            */
/* ------------------------------------------------------------------------- */

#ifdef PROMPT_INPUT
static void read_command_line(int argc, char **argv)
{   int i;
    char buffer1[PATHLEN], buffer2[PATHLEN], buffer3[PATHLEN];
    i=0;
    printf("Source filename?\n> ");
    while (gets(buffer1)==NULL); cli_file1=buffer1;
    printf("Output filename (RETURN for the same)?\n> ");
    while (gets(buffer2)==NULL); cli_file2=buffer2;
    cli_files_specified=1;
    if (buffer2[0]!=0) cli_files_specified=2;
    do
    {   printf("List of commands (RETURN to finish; \"-h\" for help)?\n> ");
        while (gets(buffer3)==NULL); execute_icl_command(buffer3);
    } while (buffer3[0]!=0);
}
#else
static void read_command_line(int argc, char **argv)
{   int i;
    if (argc==1) switches("-h",1);

    for (i=1, cli_files_specified=0; i<argc; i++)
        if (argv[i][0] == '-' && argv[i][1] == '-') {
            char *nextarg = NULL;
            int consumed2;
            if (i+1 < argc) nextarg = argv[i+1];
            consumed2 = execute_dashdash_command(argv[i]+2, nextarg);
            if (consumed2 && i+1 < argc) {
                i++;
            }
        }
        else if (icl_command(argv[i])) {
            execute_icl_command(argv[i]);
        }
        else {
            switch(++cli_files_specified)
            {   case 1: cli_file1 = argv[i]; break;
                case 2: cli_file2 = argv[i]; break;
                default:
                    printf("Command line error: unknown parameter '%s'\n",
                        argv[i]); return;
            }
        }
}
#endif

/* ------------------------------------------------------------------------- */
/*   M A I N : An outer shell for machine-specific quirks                    */
/*   Omitted altogether if EXTERNAL_SHELL is defined, as for instance is     */
/*   needed for the Macintosh front end.                                     */
/* ------------------------------------------------------------------------- */

#ifdef EXTERNAL_SHELL
extern int sub_main(int argc, char **argv);
#else

static int sub_main(int argc, char **argv);
#ifdef MAC_MPW
int main(int argc, char **argv, char *envp[])
#else
int main(int argc, char **argv)
#endif
{   int rcode;
#ifdef MAC_MPW
    InitCursorCtl((acurHandle)NULL); Show_Cursor(WATCH_CURSOR);
#endif
    rcode = sub_main(argc, argv);
#ifdef ARC_THROWBACK
    throwback_end();
#endif
    return rcode;
}

#endif

/* ------------------------------------------------------------------------- */
/*   M A I N  II:  Starting up ICL with the command line                     */
/* ------------------------------------------------------------------------- */

#ifdef EXTERNAL_SHELL
extern int sub_main(int argc, char **argv)
#else
static int sub_main(int argc, char **argv)
#endif
{   int return_code;

#ifdef MAC_FACE
    ProcessEvents (&g_proc);
    if (g_proc != true)
    {   free_arrays();
        if (store_the_text) my_free(&all_text,"transcription text");
        longjmp (g_fallback, 1);
    }
#endif

    banner();

    set_memory_sizes(); set_default_paths();
    reset_switch_settings(); select_version(5);

    cli_files_specified = 0; no_compilations = 0;
    cli_file1 = "source"; cli_file2 = "output";

    read_command_line(argc, argv);

    if (cli_files_specified > 0)
    {   return_code = compile(cli_files_specified, cli_file1, cli_file2);

        if (return_code != 0) return(return_code);
    }

    if (no_compilations == 0)
        printf("\n[No compilation requested]\n");
    if (no_compilations > 1)
        printf("[%d compilations completed]\n", no_compilations);

    return(0);
}

/* ========================================================================= */
