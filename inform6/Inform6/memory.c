/* ------------------------------------------------------------------------- */
/*   "memory" : Memory management, trace options, and ICL dollar commands    */
/*                                                                           */
/*   Part of Inform 6.44                                                     */
/*   copyright (c) Graham Nelson 1993 - 2025                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

size_t malloced_bytes=0;               /* Total amount of memory allocated   */

/* Wrappers for malloc(), realloc(), etc.

   Note that all of these functions call fatalerror_memory_out() on failure.
   This is a fatal error and does not return. However, we check my_malloc()
   return values anyway as a matter of good habit.
 */

#ifdef PC_QUICKC

extern void *my_malloc(size_t size, char *whatfor)
{   char _huge *c;
    if (memout_switch)
        printf("Allocating %ld bytes for %s\n",size,whatfor);
    if (size==0) return(NULL);
    c=(char _huge *)halloc(size,1);
    malloced_bytes+=size;
    if (c==0) fatalerror_memory_out(size, 1, whatfor);
    return(c);
}

extern void my_realloc(void *pointer, size_t oldsize, size_t size, 
    char *whatfor)
{   char _huge *c;
    if (size==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=halloc(size,1);
    malloced_bytes+=(size-oldsize);
    if (c==0) fatalerror_memory_out(size, 1, whatfor);
    if (memout_switch)
        printf("Increasing allocation from %ld to %ld bytes for %s was (%08lx) now (%08lx)\n",
            (long int) oldsize, (long int) size, whatfor,
            (long int) (*(int **)pointer), 
            (long int) c);
    memcpy(c, *(int **)pointer, MIN(oldsize, size));
    hfree(*(int **)pointer);
    *(int **)pointer = c;
}

extern void *my_calloc(size_t size, size_t howmany, char *whatfor)
{   void _huge *c;
    if (memout_switch)
        printf("Allocating %d bytes: array (%ld entries size %ld) for %s\n",
            size*howmany,howmany,size,whatfor);
    if ((size*howmany) == 0) return(NULL);
    c=(void _huge *)halloc(howmany*size,1);
    malloced_bytes+=size*howmany;
    if (c==0) fatalerror_memory_out(size, howmany, whatfor);
    return(c);
}

extern void my_recalloc(void *pointer, size_t size, size_t oldhowmany, 
    int32 howmany, char *whatfor)
{   void _huge *c;
    if (size*howmany==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=(void _huge *)halloc(size*howmany,1);
    malloced_bytes+=size*(howmany-oldhowmany);
    if (c==0) fatalerror_memory_out(size, howmany, whatfor);
    if (memout_switch)
        printf("Increasing allocation from %ld to %ld bytes: array (%ld entries size %ld) for %s was (%08lx) now (%08lx)\n",
            ((long int)size) * ((long int)oldhowmany),
            ((long int)size) * ((long int)howmany),
            (long int)howmany, (long int)size, whatfor,
            (long int) *(int **)pointer, (long int) c);
    memcpy(c, *(int **)pointer, MIN(size*oldhowmany, size*howmany));
    hfree(*(int **)pointer);
    *(int **)pointer = c;
}

#else

extern void *my_malloc(size_t size, char *whatfor)
{   char *c;
    if (size==0) return(NULL);
    c=malloc(size);
    malloced_bytes+=size;
    if (c==0) fatalerror_memory_out(size, 1, whatfor);
    if (memout_switch)
        printf("Allocating %ld bytes for %s at (%p)\n",
            (long int) size, whatfor, c);
    return(c);
}

extern void my_realloc(void *pointer, size_t oldsize, size_t size, 
    char *whatfor)
{   void *c;
    if (size==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=realloc(*(int **)pointer,  size);
    malloced_bytes+=(size-oldsize);
    if (c==0) fatalerror_memory_out(size, 1, whatfor);
    if (memout_switch)
        printf("Increasing allocation from %ld to %ld bytes for %s was (%p) now (%p)\n",
            (long int) oldsize, (long int) size, whatfor, pointer, c);
    *(int **)pointer = c;
}

extern void *my_calloc(size_t size, size_t howmany, char *whatfor)
{   void *c;
    if (size*howmany==0) return(NULL);
    c=calloc(howmany, size);
    malloced_bytes+=size*howmany;
    if (c==0) fatalerror_memory_out(size, howmany, whatfor);
    if (memout_switch)
        printf("Allocating %ld bytes: array (%ld entries size %ld) \
for %s at (%p)\n",
            ((long int)size) * ((long int)howmany),
            (long int)howmany,(long int)size, whatfor, c);
    return(c);
}

extern void my_recalloc(void *pointer, size_t size, size_t oldhowmany, 
    size_t howmany, char *whatfor)
{   void *c;
    if (size*howmany==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=realloc(*(int **)pointer, size*howmany);
    if (howmany > oldhowmany)
        memset((char *)c+size*oldhowmany, 0, size*(howmany-oldhowmany));
    malloced_bytes+=size*(howmany-oldhowmany);
    if (c==0) fatalerror_memory_out(size, howmany, whatfor);
    if (memout_switch)
        printf("Increasing allocation from %ld to %ld bytes: array (%ld entries size %ld) for %s was (%p) now (%p)\n",
            ((long int)size) * ((long int)oldhowmany),
            ((long int)size) * ((long int)howmany),
            (long int)howmany, (long int)size, whatfor,
            pointer, c);
    *(int **)pointer = c;
}

#endif

extern void my_free(void *pointer, char *whatitwas)
{
    if (*(int **)pointer != NULL)
    {   if (memout_switch)
            printf("Freeing memory for %s at (%p)\n",
                whatitwas, pointer);
#ifdef PC_QUICKC
        hfree(*(int **)pointer);
#else
        free(*(int **)pointer);
#endif
        *(int **)pointer = NULL;
    }
}

/* ------------------------------------------------------------------------- */
/*   A dynamic memory array. This grows as needed (but never shrinks).       */
/*   Call ensure_memory_list_available(N) before accessing array item N-1.   */
/*                                                                           */
/*   whatfor must be a static string describing the list. initalloc is       */
/*   (optionally) the number of items to allocate right away.                */
/*                                                                           */
/*   You typically initialise this with extpointer referring to an array of  */
/*   structs or whatever type you need. Whenever the memory list grows, the  */
/*   external array will be updated to refer to the new data.                */
/*                                                                           */
/*   Add "#define DEBUG_MEMLISTS" to allocate exactly the number of items    */
/*   needed, rather than increasing allocations exponentially. This is very  */
/*   slow but it lets us track down array overruns.                          */
/* ------------------------------------------------------------------------- */

void initialise_memory_list(memory_list *ML, size_t itemsize, size_t initalloc, void **extpointer, char *whatfor)
{
    #ifdef DEBUG_MEMLISTS
    initalloc = 0;          /* No initial allocation */
    #endif
    
    ML->whatfor = whatfor;
    ML->itemsize = itemsize;
    ML->count = 0;
    ML->data = NULL;
    ML->extpointer = extpointer;

    if (initalloc) {
        ML->count = initalloc;
        ML->data = my_calloc(ML->itemsize, ML->count, ML->whatfor);
        if (ML->data == NULL) return;
    }

    if (ML->extpointer)
        *(ML->extpointer) = ML->data;
}

void deallocate_memory_list(memory_list *ML)
{
    ML->itemsize = 0;
    ML->count = 0;
    
    if (ML->data)
        my_free(&(ML->data), ML->whatfor);

    if (ML->extpointer)
        *(ML->extpointer) = NULL;
    ML->extpointer = NULL;
}

/* After this is called, at least count items will be available in the list.
   That is, you can freely access array[0] through array[count-1]. */
void ensure_memory_list_available(memory_list *ML, size_t count)
{
    size_t oldcount;
    
    if (ML->itemsize == 0) {
        /* whatfor is also null! */
        compiler_error("memory: attempt to access uninitialized memory_list");
        return;
    }

    if (ML->count >= count) {
        return;
    }

    oldcount = ML->count;
    ML->count = 2*count+8;  /* Allow headroom for future growth */
    
    #ifdef DEBUG_MEMLISTS
    ML->count = count;      /* No headroom */
    #endif
    
    if (ML->data == NULL)
        ML->data = my_calloc(ML->itemsize, ML->count, ML->whatfor);
    else
        my_recalloc(&(ML->data), ML->itemsize, oldcount, ML->count, ML->whatfor);
    if (ML->data == NULL) return;

    if (ML->extpointer)
        *(ML->extpointer) = ML->data;
}

/* ------------------------------------------------------------------------- */
/*   Where the memory settings are declared as variables                     */
/* ------------------------------------------------------------------------- */

int HASH_TAB_SIZE;
int MAX_ABBREVS;
int MAX_DYNAMIC_STRINGS;
int MAX_LOCAL_VARIABLES;
int DICT_WORD_SIZE; /* number of characters in a dict word */
int DICT_CHAR_SIZE; /* (glulx) 1 for one-byte chars, 4 for Unicode chars */
int DICT_WORD_BYTES; /* DICT_WORD_SIZE*DICT_CHAR_SIZE */
int GRAMMAR_META_FLAG; /* indicate which actions are meta */
int ZCODE_HEADER_EXT_WORDS; /* (zcode 1.0) requested header extension size */
int ZCODE_HEADER_FLAGS_3; /* (zcode 1.1) value to place in Flags 3 word */
int ZCODE_FILE_END_PADDING; /* 0: no, 1: yes (default) */
int ZCODE_LESS_DICT_DATA; /* (zcode) use 2 data bytes per dict word instead of 3 */
int ZCODE_MAX_INLINE_STRING; /* (zcode) length of string literals that can be inlined */
int ZCODE_COMPACT_GLOBALS; /* (zcode) move all globals to the beginning of the globals segment and begin arrays right after them */
int NUM_ATTR_BYTES;
int GLULX_OBJECT_EXT_BYTES; /* (glulx) extra bytes for each object record */
int32 MAX_STACK_SIZE;
int32 MEMORY_MAP_EXTENSION;
int WARN_UNUSED_ROUTINES; /* 0: no, 1: yes except in system files, 2: yes always */
int OMIT_UNUSED_ROUTINES; /* 0: no, 1: yes */
int STRIP_UNREACHABLE_LABELS; /* 0: no, 1: yes (default) */
int OMIT_SYMBOL_TABLE; /* 0: no, 1: yes */
int DICT_IMPLICIT_SINGULAR; /* 0: no, 1: yes */
int DICT_TRUNCATE_FLAG; /* 0: no, 1: yes */
int LONG_DICT_FLAG_BUG; /* 0: no bug, 1: bug (default for historic reasons) */
int TRANSCRIPT_FORMAT; /* 0: classic, 1: prefixed */

/* ------------------------------------------------------------------------- */
/*   Memory control from the command line                                    */
/* ------------------------------------------------------------------------- */


static void add_predefined_symbol(char *command)
{
    int ix;
    
    int value = 0;
    char *valpos = NULL;
    
    for (ix=0; command[ix]; ix++) {
        if (command[ix] == '=') {
            valpos = command+(ix+1);
            command[ix] = '\0';
            break;
        }
    }
    
    for (ix=0; command[ix]; ix++) {
        if ((ix == 0 && isdigit((uchar)command[ix]))
            || !(isalnum((uchar)command[ix]) || command[ix] == '_')) {
            printf("Attempt to define invalid symbol: %s\n", command);
            return;
        }
    }

    if (valpos) {
        if (!parse_numeric_setting(valpos, command, &value)) {
            return;
        };
    }

    add_config_symbol_definition(command, value);
}

static void set_trace_option(char *command)
{
    char *cx;
    int value;

    /* Parse options of the form STRING or STRING=NUM. (The $! has already been eaten.) If the string is null or empty, show help. */
    
    if (!command || *command == '\0') {
        printf("The full list of trace options:\n\n");
        printf("  ACTIONS: show all actions\n");
        printf("    ACTIONS=2: also list them as they are defined\n");
        printf("  ASM: trace assembly (same as -a)\n");
        printf("    ASM=2: also show hex dumps\n");
        printf("    ASM=3: also show branch optimization info\n");
        printf("    ASM=4: more verbose branch info\n");
        printf("  BPATCH: show backpatch results\n");
        printf("    BPATCH=2: also show markers added\n");
        printf("  DICT: display the dictionary table\n");
        printf("    DICT=2: also the byte encoding of entries\n");
        printf("  EXPR: show expression trees\n");
        printf("    EXPR=2: more verbose\n");
        printf("    EXPR=3: even more verbose\n");
        printf("  FILES: show files opened\n");
        printf("  FINDABBREVS: show selection decisions during abbreviation optimization\n    (only meaningful with -u)\n");
        printf("    FINDABBREVS=2: also show three-letter-block decisions\n");
        printf("  FREQ: show how efficient abbreviations were (same as -f)\n    (only meaningful with -e)\n");
        printf("  MAP: print memory map of the virtual machine (same as -z)\n");
        printf("    MAP=2: also show percentage of VM that each segment occupies\n");
        printf("    MAP=3: also show number of bytes that each segment occupies\n");
        printf("  MEM: show internal memory allocations\n");
        printf("  OBJECTS: display the object table\n");
        printf("  PROPS: show attributes and properties defined\n");
        printf("  RUNTIME: show game function calls at runtime (same as -g)\n");
        printf("    RUNTIME=2: also show library calls (not supported in Glulx)\n");
        printf("    RUNTIME=3: also show veneer calls (not supported in Glulx)\n");
        printf("  STATS: give compilation statistics (same as -s)\n");
        printf("  SYMBOLS: display the symbol table\n");
        printf("    SYMBOLS=2: also show compiler-defined symbols\n");
        printf("  SYMDEF: show when symbols are noticed and defined\n");
        printf("  TOKENS: show token lexing\n");
        printf("    TOKENS=2: also show token types\n");
        printf("    TOKENS=3: also show lexical context\n");
        printf("  VERBS: display the verb grammar table\n");
        return;
    }

    for (cx=command; *cx && *cx != '='; cx++) {
        if (!(*cx >= 'A' && *cx <= 'Z')) {
            printf("Invalid $! trace command \"%s\"\n", command);
            return;
        }
    }

    value = 1;
    if (*cx == '=') {
        char *ex;
        value = strtol(cx+1, &ex, 10);
        
        if (ex == cx+1 || *ex != '\0' || value < 0) {
            printf("Bad numerical setting in $! trace command \"%s\"\n", command);
            return;
        }
        
        *cx = '\0';
    }

    /* We accept some reasonable synonyms, including plausible singular/plural confusion. */
    
    if (strcmp(command, "ASSEMBLY")==0 || strcmp(command, "ASM")==0) {
        asm_trace_setting = value;
    }
    else if (strcmp(command, "ACTION")==0 || strcmp(command, "ACTIONS")==0) {
        printactions_switch = value;
    }
    else if (strcmp(command, "BPATCH")==0 || strcmp(command, "BACKPATCH")==0) {
        bpatch_trace_setting = value;
    }
    else if (strcmp(command, "DICTIONARY")==0 || strcmp(command, "DICT")==0) {
        list_dict_setting = value;
    }
    else if (strcmp(command, "EXPR")==0 || strcmp(command, "EXPRESSION")==0 || strcmp(command, "EXPRESSIONS")==0) {
        expr_trace_setting = value;
    }
    else if (strcmp(command, "FILE")==0 || strcmp(command, "FILES")==0) {
        files_trace_setting = value;
    }
    else if (strcmp(command, "FINDABBREV")==0 || strcmp(command, "FINDABBREVS")==0) {
        optabbrevs_trace_setting = value;
    }
    else if (strcmp(command, "FREQUENCY")==0 || strcmp(command, "FREQUENCIES")==0 || strcmp(command, "FREQ")==0) {
        frequencies_setting = value;
    }
    else if (strcmp(command, "MAP")==0) {
        memory_map_setting = value;
    }
    else if (strcmp(command, "MEM")==0 || strcmp(command, "MEMORY")==0) {
        memout_switch = value;
    }
    else if (strcmp(command, "OBJECTS")==0 || strcmp(command, "OBJECT")==0 || strcmp(command, "OBJS")==0 || strcmp(command, "OBJ")==0) {
        list_objects_setting = value;
    }
    else if (strcmp(command, "PROP")==0 || strcmp(command, "PROPERTY")==0 || strcmp(command, "PROPS")==0 || strcmp(command, "PROPERTIES")==0) {
        printprops_switch = value;
    }
    else if (strcmp(command, "RUNTIME")==0) {
        trace_fns_setting = value;
    }
    else if (strcmp(command, "STATISTICS")==0 || strcmp(command, "STATS")==0 || strcmp(command, "STAT")==0) {
        statistics_switch = value;
    }
    else if (strcmp(command, "SYMBOLS")==0 || strcmp(command, "SYMBOL")==0) {
        list_symbols_setting = value;
    }
    else if (strcmp(command, "SYMDEF")==0 || strcmp(command, "SYMBOLDEF")==0) {
        symdef_trace_setting = value;
    }
    else if (strcmp(command, "TOKEN")==0 || strcmp(command, "TOKENS")==0) {
        tokens_trace_setting = value;
    }
    else if (strcmp(command, "VERBS")==0 || strcmp(command, "VERB")==0) {
        list_verbs_setting = value;
    }
    else {
        printf("Unrecognized $! trace command \"%s\"\n", command);
    }
}

/* Handle a dollar-sign command option: $LIST, $FOO=VAL, and so on.
   The option may come from the command line, an ICL file, or a header
   comment. The optprec argument distinguishes header comments
   (HEADCOM_OPTPREC) from the command line (CMDLINE_OPTPREC).

   (Unix-style command-line options are converted to dollar-sign format
   before being sent here.)
*/
extern void execute_dollar_command(char *command, int optprec)
{   int i, k;

    /* Upper-case the command, or the part of the command up to the equal
       sign. (For $foo=val, the variable name is case-folded but the value
       is not.) (Most values are numbers but we support string options now.)
    */
    for (k=0; command[k] != 0 && command[k] != '='; k++) {
        if (islower((uchar)command[k]))
            command[k]=toupper((uchar)command[k]);
    }

    if (command[0]=='?') { explain_compiler_option(command+1); return; }
    if (command[0]=='#') { add_predefined_symbol(command+1); return; }
    if (command[0]=='!') { set_trace_option(command+1); return; }

    if (strcmp(command, "HUGE")==0
        || strcmp(command, "LARGE")==0
        || strcmp(command, "SMALL")==0) {
        if (!nowarnings_switch)
            printf("The Inform 6 memory size commands (\"SMALL, LARGE, HUGE\") are no longer needed and has been withdrawn.\n");
        return;
    }
    
    if (strcmp(command, "LIST")==0) {
        list_compiler_options();
        return;
    }
    
    for (i=0; command[i]!=0; i++)
    {   if (command[i]=='=')
        {
            command[i]=0;
            set_compiler_option(command, command+i+1, optprec);
            return;
        }
    }
    printf("No such $ command as \"%s\"\n",command);
}

extern void print_memory_usage(void)
{
    printf("Properties table used %d\n",
        properties_table_size);
    printf("Allocated a total of %ld bytes of memory\n",
        (long int) malloced_bytes);
}

/* ========================================================================= */
/*   Data structure management routines                                      */
/* ------------------------------------------------------------------------- */

extern void init_memory_vars(void)
{   malloced_bytes = 0;
}

extern void memory_begin_pass(void) { }

extern void memory_allocate_arrays(void) { }

extern void memory_free_arrays(void) { }

/* ========================================================================= */
