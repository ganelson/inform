/* ------------------------------------------------------------------------- */
/*   "inform" :  The top level of Inform: switches, pathnames, filenaming    */
/*               conventions, ICL (Inform Command Line) files, main          */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#define MAIN_INFORM_FILE
#include "header.h"

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

int32 requested_glulx_version;

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

  while (isdigit(*cx))
    major = major*10 + ((*cx++)-'0');
  if (*cx == '.') {
    cx++;
    while (isdigit(*cx))
      minor = minor*10 + ((*cx++)-'0');
    if (*cx == '.') {
      cx++;
      while (isdigit(*cx))
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
    INDIV_PROP_START = 64;

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
    if (MAX_LOCAL_VARIABLES != 16) {
      MAX_LOCAL_VARIABLES = 16;
      fatalerror("You cannot change MAX_LOCAL_VARIABLES in Z-code");
    }
    if (MAX_GLOBAL_VARIABLES != 240) {
      MAX_GLOBAL_VARIABLES = 240;
      fatalerror("You cannot change MAX_GLOBAL_VARIABLES in Z-code");
    }
    if (MAX_VERBS > 255) {
      MAX_VERBS = 255;
      fatalerror("MAX_VERBS can only go above 255 when Glulx is used");
    }
  }
  else {
    /* Glulx */
    WORDSIZE = 4;
    MAXINTWORD = 0x7FFFFFFF;
    INDIV_PROP_START = 256; /* This could be a memory setting */
    scale_factor = 0; /* It should never even get used in Glulx */

    if (NUM_ATTR_BYTES % 4 != 3) {
      NUM_ATTR_BYTES += (3 - (NUM_ATTR_BYTES % 4)); 
      warning_numbered("NUM_ATTR_BYTES must be a multiple of four, plus three. Increasing to", NUM_ATTR_BYTES);
    }

    if (DICT_CHAR_SIZE != 1 && DICT_CHAR_SIZE != 4) {
      DICT_CHAR_SIZE = 4;
      warning_numbered("DICT_CHAR_SIZE must be either 1 or 4. Setting to", DICT_CHAR_SIZE);
    }
  }

  if (MAX_LOCAL_VARIABLES >= 120) {
    MAX_LOCAL_VARIABLES = 119;
    warning("MAX_LOCAL_VARIABLES cannot exceed 119; resetting to 119");
    /* This is because the keyword table in the lexer only has 120
       entries. */
  }
  if (DICT_WORD_SIZE > MAX_DICT_WORD_SIZE) {
    DICT_WORD_SIZE = MAX_DICT_WORD_SIZE;
    warning_numbered(
      "DICT_WORD_SIZE cannot exceed MAX_DICT_WORD_SIZE; resetting", 
      MAX_DICT_WORD_SIZE);
    /* MAX_DICT_WORD_SIZE can be increased in header.h without fear. */
  }
  if (NUM_ATTR_BYTES > MAX_NUM_ATTR_BYTES) {
    NUM_ATTR_BYTES = MAX_NUM_ATTR_BYTES;
    warning_numbered(
      "NUM_ATTR_BYTES cannot exceed MAX_NUM_ATTR_BYTES; resetting",
      MAX_NUM_ATTR_BYTES);
    /* MAX_NUM_ATTR_BYTES can be increased in header.h without fear. */
  }

  /* Set up a few more variables that depend on the above values */

  if (!targ) {
    /* Z-machine */
    DICT_WORD_BYTES = DICT_WORD_SIZE;
    /* The Z-code generator doesn't use the following variables, although 
       it would be a little cleaner if it did. */
    OBJECT_BYTE_LENGTH = 0;
    DICT_ENTRY_BYTE_LENGTH = (version_number==3)?7:9;
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
}

/* ------------------------------------------------------------------------- */
/*   Tracery: output control variables                                       */
/* ------------------------------------------------------------------------- */

int asm_trace_level,     /* trace assembly: 0 for off, 1 for assembly
                            only, 2 for full assembly tracing with hex dumps */
    line_trace_level,    /* line tracing: 0 off, 1 on                        */
    expr_trace_level,    /* expression tracing: 0 off, 1 full, 2 brief       */
    linker_trace_level,  /* set by -y: 0 to 4 levels of tracing              */
    tokens_trace_level;  /* lexer output tracing: 0 off, 1 on                */

/* ------------------------------------------------------------------------- */
/*   On/off switch variables (by default all FALSE); other switch settings   */
/* ------------------------------------------------------------------------- */

int bothpasses_switch,              /* -b */
    concise_switch,                 /* -c */
    economy_switch,                 /* -e */
    frequencies_switch,             /* -f */
    ignore_switches_switch,         /* -i */
    listobjects_switch,             /* -j */
    debugfile_switch,               /* -k */
    listing_switch,                 /* -l */
    memout_switch,                  /* -m */
    printprops_switch,              /* -n */
    offsets_switch,                 /* -o */
    percentages_switch,             /* -p */
    obsolete_switch,                /* -q */
    transcript_switch,              /* -r */
    statistics_switch,              /* -s */
    optimise_switch,                /* -u */
    version_set_switch,             /* -v */
    nowarnings_switch,              /* -w */
    hash_switch,                    /* -x */
    memory_map_switch,              /* -z */
    oddeven_packing_switch,         /* -B */
    define_DEBUG_switch,            /* -D */
    temporary_files_switch,         /* -F */
    module_switch,                  /* -M */
    runtime_error_checking_switch,  /* -S */
    define_USE_MODULES_switch,      /* -U */
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
    asm_trace_setting,              /* set by -a and -t: value of
                                       asm_trace_level to use when tracing */
    double_space_setting,           /* set by -d: 0, 1 or 2 */
    trace_fns_setting,              /* set by -g: 0, 1 or 2 */
    linker_trace_setting,           /* set by -y: ditto for linker_... */
    store_the_text;                 /* when set, record game text to a chunk
                                       of memory (used by both -r & -k) */
static int r_e_c_s_set;             /* has -S been explicitly set? */

int glulx_mode;                     /* -G */

static void reset_switch_settings(void)
{   asm_trace_setting=0;
    linker_trace_level=0;
    tokens_trace_level=0;

    store_the_text = FALSE;

    bothpasses_switch = FALSE;
    concise_switch = FALSE;
    double_space_setting = 0;
    economy_switch = FALSE;
    frequencies_switch = FALSE;
    trace_fns_setting = 0;
    ignore_switches_switch = FALSE;
    listobjects_switch = FALSE;
    debugfile_switch = FALSE;
    listing_switch = FALSE;
    memout_switch = FALSE;
    printprops_switch = FALSE;
    offsets_switch = FALSE;
    percentages_switch = FALSE;
    obsolete_switch = FALSE;
    transcript_switch = FALSE;
    statistics_switch = FALSE;
    optimise_switch = FALSE;
    version_set_switch = FALSE;
    nowarnings_switch = FALSE;
    hash_switch = FALSE;
    memory_map_switch = FALSE;
    oddeven_packing_switch = FALSE;
    define_DEBUG_switch = FALSE;
#ifdef USE_TEMPORARY_FILES
    temporary_files_switch = TRUE;
#else
    temporary_files_switch = FALSE;
#endif
    define_USE_MODULES_switch = FALSE;
    module_switch = FALSE;
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
    init_linker_vars();
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
    line_trace_level = 0; expr_trace_level = 0;
    asm_trace_level = asm_trace_setting;
    linker_trace_level = linker_trace_setting;
    if (listing_switch) line_trace_level=1;

    lexer_begin_pass();
    linker_begin_pass();
    memory_begin_pass();
    objects_begin_pass();
    states_begin_pass();
    symbols_begin_pass();
    syntax_begin_pass();
    tables_begin_pass();
    text_begin_pass();
    veneer_begin_pass();
    verbs_begin_pass();

    if (!module_switch)
    {
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
    linker_allocate_arrays();
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
    linker_free_arrays();
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
static char Module_Path[PATHLEN];
static char Temporary_Path[PATHLEN];
static char current_source_path[PATHLEN];
       char Debugging_Name[PATHLEN];
       char Transcript_Name[PATHLEN];
       char Language_Name[PATHLEN];
       char Charset_Map[PATHLEN];
static char ICL_Path[PATHLEN];

static void set_path_value(char *path, char *value)
{   int i, j;

    for (i=0, j=0;;)
    {   if ((value[j] == FN_ALT) || (value[j] == 0))
        {   if ((value[j] == FN_ALT)
                && (path != Source_Path) && (path != Include_Path)
                && (path != ICL_Path) && (path != Module_Path))
            {   printf("The character '%c' is used to divide entries in a list \
of possible locations, and can only be used in the Include_Path, Source_Path, \
Module_Path or ICL_Path variables. Other paths are for output only.", FN_ALT);
                exit(1);
            }
            if ((path != Debugging_Name) && (path != Transcript_Name)
                 && (path != Language_Name) && (path != Charset_Map)
                 && (i>0) && (isalnum(path[i-1]))) path[i++] = FN_SEP;
            path[i++] = value[j++];
            if (i == PATHLEN-1) {
                printf("A specified path is longer than %d characters.\n",
                    PATHLEN-1);
                exit(1);
            }
            if (value[j-1] == 0) return;
        }
        else path[i++] = value[j++];
    }
}

static void set_default_paths(void)
{
    set_path_value(Source_Path,     Source_Directory);
    set_path_value(Include_Path,    Include_Directory);
    set_path_value(Code_Path,       Code_Directory);
    set_path_value(Module_Path,     Module_Directory);
    set_path_value(ICL_Path,        ICL_Directory);
    set_path_value(Temporary_Path,  Temporary_Directory);
    set_path_value(Debugging_Name,  Debugging_File);
    set_path_value(Transcript_Name, Transcript_File);
    set_path_value(Language_Name,   "English");
    set_path_value(Charset_Map,     "");
}

static void set_path_command(char *command)
{   int i, j; char *path_to_set = NULL, *new_value;
    for (i=0; (command[i]!=0) && (command[i]!='=');i++) ;

    if (command[i]==0) { new_value=command; path_to_set=Include_Path; }
    else
    {   char pathname[PATHLEN];
        if (i>=PATHLEN) i=PATHLEN-1;
        new_value = command+i+1;
        for (j=0;j<i;j++)
            if (isupper(command[j])) pathname[j]=tolower(command[j]);
            else pathname[j]=command[j];
        pathname[j]=0;

        if (strcmp(pathname, "source_path")==0)  path_to_set=Source_Path;
        if (strcmp(pathname, "include_path")==0) path_to_set=Include_Path;
        if (strcmp(pathname, "code_path")==0)    path_to_set=Code_Path;
        if (strcmp(pathname, "module_path")==0)  path_to_set=Module_Path;
        if (strcmp(pathname, "icl_path")==0)     path_to_set=ICL_Path;
        if (strcmp(pathname, "temporary_path")==0) path_to_set=Temporary_Path;
        if (strcmp(pathname, "debugging_name")==0) path_to_set=Debugging_Name;
        if (strcmp(pathname, "transcript_name")==0) path_to_set=Transcript_Name;
        if (strcmp(pathname, "language_name")==0) path_to_set=Language_Name;
        if (strcmp(pathname, "charset_map")==0) path_to_set=Charset_Map;

        if (path_to_set == NULL)
        {   printf("No such path setting as \"%s\"\n", pathname);
            exit(1);
        }
    }

    set_path_value(path_to_set, new_value);
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

extern int translate_link_filename(int last_value,
    char *new_name, char *old_name)
{   char *prefix_path = NULL;
    char *extension;

    if (contains_separator(old_name)==0)
        if (Module_Path[0]!=0)
            prefix_path = Module_Path;

#ifdef FILE_EXTENSIONS
    extension = check_extension(old_name, Module_Extension);
#else
    extension = "";
#endif

    return write_translated_name(new_name, old_name,
               prefix_path, last_value, extension);
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
    if (module_switch)
    {   extension = Module_Extension;
        if (Module_Path[0]!=0) prefix_path = Module_Path;
    }
    else
    {
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
    }

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
    int save_mm = module_switch, x;

    module_switch = FALSE;

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
"Filenames given in the game source (with commands like Include \"name\" and\n\
Link \"name\") are also translated by the rules below.\n\n");

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
"       Temporary file (out)   temporary_path      %s\n\
       ICL command file (in)  icl_path            %s\n\
       Module (in & out)      module_path         %s\n\n",
   name_or_unset(Temporary_Path),
   name_or_unset(ICL_Path), name_or_unset(Module_Path));

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
   in the path variable.\n\
   (Modules are written to the first alternative in the module_path list;\n\
   it is an error to give alternatives at all for purely output paths.)\n\n",
   FN_ALT);

#ifdef FILE_EXTENSIONS
    printf("3. The following file extensions are added:\n\n\
      Source code:     %s\n\
      Include files:   %s\n\
      Story files:     %s (Version 3), %s (v4), %s (v5, the default),\n\
                       %s (v6), %s (v7), %s (v8), %s (Glulx)\n\
      Temporary files: .tmp\n\
      Modules:         %s\n\n",
      Source_Extension, Include_Extension,
      Code_Extension, V4Code_Extension, V5Code_Extension, V6Code_Extension,
      V7Code_Extension, V8Code_Extension, GlulxCode_Extension, 
      Module_Extension);
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

    translate_in_filename(0, new_name, "frotz", 0, 1);
    printf("2. \"inform -M frotz\"\n\
  the source code is read from \"%s\"\n",
        new_name);
    module_switch = TRUE;
    convert_filename_flag = TRUE;
    translate_out_filename(new_name, "frotz");
    printf("  and a module is compiled to \"%s\".\n\n", new_name);

    module_switch = FALSE;

    sprintf(old_name, "demos%cplugh", FN_SEP);
    printf("3. \"inform %s\"\n", old_name);
    translate_in_filename(0, new_name, old_name, 0, 1);
    printf("  the source code is read from \"%s\"\n", new_name);
    sprintf(old_name, "demos%cplugh", FN_SEP);
    convert_filename_flag = TRUE;
    translate_out_filename(new_name, old_name);
    printf("  and a story file is compiled to \"%s\".\n\n", new_name);

    printf("4. \"inform plover my_demo\"\n");
    translate_in_filename(0, new_name, "plover", 0, 1);
    printf("  the source code is read from \"%s\"\n", new_name);
    convert_filename_flag = FALSE;
    translate_out_filename(new_name, "my_demo");
    printf("  and a story file is compiled to \"%s\".\n\n", new_name);

    strcpy(old_name, Source_Path);
    sprintf(new_name, "%cnew%cold%crecent%cold%cancient",
        FN_ALT, FN_ALT, FN_SEP, FN_ALT, FN_SEP);
    printf("5. \"inform +source_path=%s zooge\"\n", new_name);
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
    module_switch = save_mm;
}

/* ------------------------------------------------------------------------- */
/*  Naming temporary files                                                   */
/*       (Arguably temporary files should be made using "tmpfile" in         */
/*        the ANSI C library, but many supposed ANSI libraries lack it.)     */
/* ------------------------------------------------------------------------- */

extern void translate_temp_filename(int i)
{   char *p = NULL;
    switch(i)
    {   case 1: p=Temp1_Name; break;
        case 2: p=Temp2_Name; break;
        case 3: p=Temp3_Name; break;
    }
    if (strlen(Temporary_Path)+strlen(Temporary_File)+6 >= PATHLEN) {
        printf ("Temporary_Path is too long.\n");
        exit(1);
    }
    sprintf(p,"%s%s%d", Temporary_Path, Temporary_File, i);
#ifdef INCLUDE_TASK_ID
    sprintf(p+strlen(p), "_proc%08lx", (long int) unique_task_id());
#endif
#ifdef FILE_EXTENSIONS
    sprintf(p+strlen(p), ".tmp");
#endif
}

#ifdef ARCHIMEDES
static char riscos_ft_buffer[4];

extern char *riscos_file_type(void)
{
    if (riscos_file_type_format == 1)
    {   if (module_switch) return("data");
        return("11A");
    }

    if (module_switch) return("075");

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

    find_the_actions();
    issue_unused_warnings();
    compile_veneer();

    lexer_endpass();
    if (module_switch) linker_endpass();

    close_all_source();
    if (hash_switch && hash_printed_since_newline) printf("\n");

    if (temporary_files_switch)
    {   if (module_switch) flush_link_data();
        check_temp_files();
    }
    sort_dictionary();
    if (track_unused_routines)
        locate_dead_functions();
    construct_storyfile();
}

int output_has_occurred;

static void rennab(int32 time_taken)
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
        printf("Completed in %ld seconds\n", (long int) time_taken);
}

/* ------------------------------------------------------------------------- */
/*   The compiler abstracted to a routine.                                   */
/* ------------------------------------------------------------------------- */

static int execute_icl_header(char *file1);

static int compile(int number_of_files_specified, char *file1, char *file2)
{   int32 time_start;

    if (execute_icl_header(file1))
      return 1;

    select_target(glulx_mode);

    if (define_INFIX_switch && glulx_mode) {
        printf("Infix (-X) facilities are not available in Glulx: \
disabling -X switch\n");
        define_INFIX_switch = FALSE;
    }

    if (module_switch && glulx_mode) {
        printf("Modules are not available in Glulx: \
disabling -M switch\n");
        module_switch = FALSE;
    }

    if (define_INFIX_switch && module_switch)
    {   printf("Infix (-X) facilities are not available when compiling \
modules: disabling -X switch\n");
        define_INFIX_switch = FALSE;
    }
    if (runtime_error_checking_switch && module_switch)
    {   printf("Strict checking (-S) facilities are not available when \
compiling modules: disabling -S switch\n");
        runtime_error_checking_switch = FALSE;
    }

    time_start=time(0); no_compilations++;

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

    if (transcript_switch)
    {   write_dictionary_to_transcript();
        close_transcript_file();
    }

    if (no_errors==0) { output_file(); output_has_occurred = TRUE; }
    else { output_has_occurred = FALSE; }

    if (debugfile_switch)
    {   end_debug_file();
    }

    if (temporary_files_switch && (no_errors>0)) remove_temp_files();

    free_arrays();

    rennab((int32) (time(0)-time_start));

    if (optimise_switch) optimise_abbreviations();

    if (store_the_text) my_free(&all_text,"transcription text");

    return (no_errors==0)?0:1;
}

/* ------------------------------------------------------------------------- */
/*   The command line interpreter                                            */
/* ------------------------------------------------------------------------- */

static void cli_print_help(int help_level)
{
    printf(
"\nThis program is a compiler of Infocom format (also called \"Z-machine\")\n\
story files: copyright (c) Graham Nelson 1993 - 2016.\n\n");

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
  +PATH=dir     change the PATH to this directory\n\n\
  $...          one of the following memory commands:\n");
  printf(
"     $list            list current memory allocation settings\n\
     $huge            make standard \"huge game\" settings %s\n\
     $large           make standard \"large game\" settings %s\n\
     $small           make standard \"small game\" settings %s\n\
     $?SETTING        explain briefly what SETTING is for\n\
     $SETTING=number  change SETTING to given number\n\n\
  (filename)    read in a list of commands (in the format above)\n\
                from this \"setup file\"\n\n",
    (DEFAULT_MEMORY_SIZE==HUGE_SIZE)?"(default)":"",
    (DEFAULT_MEMORY_SIZE==LARGE_SIZE)?"(default)":"",
    (DEFAULT_MEMORY_SIZE==SMALL_SIZE)?"(default)":"");

#ifndef PROMPT_INPUT
    printf("For example: \"inform -dexs $huge curses\".\n\n");
#endif

    printf(
"For fuller information, see the Inform Designer's Manual.\n");

       return;
   }

   /* The -h1 (filenaming) help information: */

   if (help_level == 1) { help_on_filenames(); return; }

   /* The -h2 (switches) help information: */

   printf("Help on the full list of legal switch commands:\n\n\
  a   trace assembly-language (without hex dumps; see -t)\n\
  c   more concise error messages\n\
  d   contract double spaces after full stops in text\n\
  d2  contract double spaces after exclamation and question marks, too\n\
  e   economy mode (slower): make use of declared abbreviations\n");

   printf("\
  f   frequencies mode: show how useful abbreviations are\n\
  g   traces calls to functions (except in the library)\n\
  g2  traces calls to all functions\n\
  h   print this information\n");

   printf("\
  i   ignore default switches set within the file\n\
  j   list objects as constructed\n\
  k   output Infix debugging information to \"%s\" (and switch -D on)\n\
  l   list every statement run through Inform\n\
  m   say how much memory has been allocated\n\
  n   print numbers of properties, attributes and actions\n",
          Debugging_Name);
   printf("\
  o   print offset addresses\n\
  p   give percentage breakdown of story file\n\
  q   keep quiet about obsolete usages\n\
  r   record all the text to \"%s\"\n\
  s   give statistics\n\
  t   trace assembly-language (with full hex dumps; see -a)\n",
      Transcript_Name);

   printf("\
  u   work out most useful abbreviations (very very slowly)\n\
  v3  compile to version-3 (\"Standard\") story file\n\
  v4  compile to version-4 (\"Plus\") story file\n\
  v5  compile to version-5 (\"Advanced\") story file: the default\n\
  v6  compile to version-6 (graphical) story file\n\
  v8  compile to version-8 (expanded \"Advanced\") story file\n\
  w   disable warning messages\n\
  x   print # for every 100 lines compiled\n\
  y   trace linking system\n\
  z   print memory map of the Z-machine\n\n");

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
#ifdef USE_TEMPORARY_FILES
printf("  F0  use extra memory rather than temporary files\n");
#else
printf("  F1  use temporary files to reduce memory consumption\n");
#endif
printf("  G   compile a Glulx game file\n");
printf("  H   use Huffman encoding to compress Glulx strings\n");
printf("  M   compile as a Module for future linking\n");

#ifdef ARCHIMEDES
printf("\
  R0  use filetype 060 + version number for games (default)\n\
  R1  use official Acorn filetype 11A for all games\n");
#endif
printf("  S   compile strict error-checking at run-time (on by default)\n");
#ifdef ARC_THROWBACK
printf("  T   enable throwback of errors in the DDE\n");
#endif
printf("  U   insert \"Constant USE_MODULES;\" automatically\n");
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
        case 'a': asm_trace_setting = 1; break;
        case 'b': bothpasses_switch = state; break;
        case 'c': concise_switch = state; break;
        case 'd': switch(p[i+1])
                  {   case '1': double_space_setting=1; s=2; break;
                      case '2': double_space_setting=2; s=2; break;
                      default: double_space_setting=1; break;
                  }
                  break;
        case 'e': economy_switch = state; break;
        case 'f': frequencies_switch = state; break;
        case 'g': switch(p[i+1])
                  {   case '1': trace_fns_setting=1; s=2; break;
                      case '2': trace_fns_setting=2; s=2; break;
                      default: trace_fns_setting=1; break;
                  }
                  break;
        case 'h': switch(p[i+1])
                  {   case '1': cli_print_help(1); s=2; break;
                      case '2': cli_print_help(2); s=2; break;
                      case '0': s=2;
                      default:  cli_print_help(0); break;
                  }
                  break;
        case 'i': ignore_switches_switch = state; break;
        case 'j': listobjects_switch = state; break;
        case 'k': if (cmode == 0)
                      error("The switch '-k' can't be set with 'Switches'");
                  else
                  {   debugfile_switch = state;
                      if (state) define_DEBUG_switch = TRUE;
                  }
                  break;
        case 'l': listing_switch = state; break;
        case 'm': memout_switch = state; break;
        case 'n': printprops_switch = state; break;
        case 'o': offsets_switch = state; break;
        case 'p': percentages_switch = state; break;
        case 'q': obsolete_switch = state; break;
        case 'r': if (cmode == 0)
                      error("The switch '-r' can't be set with 'Switches'");
                  else
                      transcript_switch = state; break;
        case 's': statistics_switch = state; break;
        case 't': asm_trace_setting=2; break;
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
        case 'y': s=2; linker_trace_setting=p[i+1]-'0'; break;
        case 'z': memory_map_switch = state; break;
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
        case 'F': if (cmode == 0) {
                      error("The switch '-F' can't be set with 'Switches'");
                      break;
                  }
                  switch(p[i+1])
                  {   case '0': s=2; temporary_files_switch = FALSE; break;
                      case '1': s=2; temporary_files_switch = TRUE; break;
                      default:  temporary_files_switch = state; break;
                  }
                  break;
        case 'M': module_switch = state;
                  if (state && (r_e_c_s_set == FALSE))
                      runtime_error_checking_switch = FALSE;
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
                  else
                  {   glulx_mode = state;
                      adjust_memory_sizes();
                  }
                  break;
        case 'H': compression_switch = state; break;
        case 'U': define_USE_MODULES_switch = state; break;
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

    if (optimise_switch && (!store_the_text))
    {   store_the_text=TRUE;
#ifdef PC_QUICKC
        if (memout_switch)
            printf("Allocation %ld bytes for transcription text\n",
                (long) MAX_TRANSCRIPT_SIZE);
        all_text = halloc(MAX_TRANSCRIPT_SIZE,1);
        malloced_bytes += MAX_TRANSCRIPT_SIZE;
        if (all_text==NULL)
         fatalerror("Can't hallocate memory for transcription text.  Darn.");
#else
        all_text=my_malloc(MAX_TRANSCRIPT_SIZE,"transcription text");
#endif
    }
}

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

static void execute_icl_command(char *p);

static int execute_icl_header(char *argname)
{
  FILE *command_file;
  char cli_buff[256], fw[256];
  int line = 0;
  int errcount = 0;
  int i;
  char filename[PATHLEN]; 
  int x = 0;

  do
    {   x = translate_in_filename(x, filename, argname, 0, 1);
        command_file = fopen(filename,"r");
    } while ((command_file == NULL) && (x != 0));
  if (!command_file) {
    /* Fail silently. The regular compiler will try to open the file
       again, and report the problem. */
    return 0;
  }

  while (feof(command_file)==0) {
    if (fgets(cli_buff,256,command_file)==0) break;
    line++;
    if (!(cli_buff[0] == '!' && cli_buff[1] == '%'))
      break;
    i = copy_icl_word(cli_buff+2, fw, 256);
    if (icl_command(fw)) {
      execute_icl_command(fw);
      copy_icl_word(cli_buff+2 + i, fw, 256);
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
{   char cli_buff[256], fw[256];
    int i, x, line = 0;
    printf("[Running ICL file '%s']\n", filename);

    while (feof(command_file)==0)
    {   if (fgets(cli_buff,256,command_file)==0) break;
        line++;
        i = copy_icl_word(cli_buff, fw, 256);
        if (icl_command(fw))
        {   execute_icl_command(fw);
            copy_icl_word(cli_buff + i, fw, 256);
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
                            copy_icl_word(cli_buff + i, fw, 256);
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

static void execute_icl_command(char *p)
{   char filename[PATHLEN], cli_buff[256];
    FILE *command_file;

    switch(p[0])
    {   case '+': set_path_command(p+1); break;
        case '-': switches(p,1); break;
        case '$': memory_command(p+1); break;
        case '(': strcpy(cli_buff,p+1); cli_buff[strlen(cli_buff)-1]=0;
                  {   int x = 0;
                      do
                      {   x = translate_icl_filename(x, filename, cli_buff);
                          command_file = fopen(filename,"r");
                      } while ((command_file == NULL) && (x != 0));
                  }
                  if (command_file == NULL)
                      printf("Error in ICL: Couldn't open command file '%s'\n",
                          filename);
                  else
                  {   run_icl_file(filename, command_file);
                      fclose(command_file);
                  }
                  break;
    }
}

/* ------------------------------------------------------------------------- */
/*   Opening and closing banners                                             */
/* ------------------------------------------------------------------------- */

char banner_line[80];

static void banner(void)
{
    sprintf(banner_line, "Inform %d.%d%d",
        (VNUMBER/100)%10, (VNUMBER/10)%10, VNUMBER%10);
#ifdef RELEASE_SUFFIX
    strcat(banner_line, RELEASE_SUFFIX);
#endif
#ifdef MACHINE_STRING
    sprintf(banner_line+strlen(banner_line), " for %s", MACHINE_STRING);
#endif
    sprintf(banner_line+strlen(banner_line), " (%s)", RELEASE_DATE);
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
        if (icl_command(argv[i]))
            execute_icl_command(argv[i]);
        else
            switch(++cli_files_specified)
            {   case 1: cli_file1 = argv[i]; break;
                case 2: cli_file2 = argv[i]; break;
                default:
                    printf("Command line error: unknown parameter '%s'\n",
                        argv[i]); return;
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

    set_memory_sizes(DEFAULT_MEMORY_SIZE); set_default_paths();
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
