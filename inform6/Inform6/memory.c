/* ------------------------------------------------------------------------- */
/*   "memory" : Memory management and ICL memory setting commands            */
/*                                                                           */
/*   Part of Inform 6.42                                                     */
/*   copyright (c) Graham Nelson 1993 - 2024                                 */
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
int ZCODE_HEADER_EXT_WORDS; /* (zcode 1.0) requested header extension size */
int ZCODE_HEADER_FLAGS_3; /* (zcode 1.1) value to place in Flags 3 word */
int ZCODE_LESS_DICT_DATA; /* (zcode) use 2 data bytes per dict word instead of 3 */
int ZCODE_MAX_INLINE_STRING; /* (zcode) length of string literals that can be inlined */
int NUM_ATTR_BYTES;
int GLULX_OBJECT_EXT_BYTES; /* (glulx) extra bytes for each object record */
int32 MAX_STACK_SIZE;
int32 MEMORY_MAP_EXTENSION;
int WARN_UNUSED_ROUTINES; /* 0: no, 1: yes except in system files, 2: yes always */
int OMIT_UNUSED_ROUTINES; /* 0: no, 1: yes */
int STRIP_UNREACHABLE_LABELS; /* 0: no, 1: yes (default) */
int OMIT_SYMBOL_TABLE; /* 0: no, 1: yes */
int LONG_DICT_FLAG_BUG; /* 0: no bug, 1: bug (default for historic reasons) */
int TRANSCRIPT_FORMAT; /* 0: classic, 1: prefixed */

/* The way memory sizes are set causes great nuisance for those parameters
   which have different defaults under Z-code and Glulx. We have to get
   the defaults right whether the user sets "-G $HUGE" or "$HUGE -G". 
   And an explicit value set by the user should override both defaults. */
static int DICT_WORD_SIZE_z, DICT_WORD_SIZE_g;
static int NUM_ATTR_BYTES_z, NUM_ATTR_BYTES_g;
static int MAX_DYNAMIC_STRINGS_z, MAX_DYNAMIC_STRINGS_g;

/* ------------------------------------------------------------------------- */
/*   Memory control from the command line                                    */
/* ------------------------------------------------------------------------- */

static void list_memory_sizes(void)
{   printf("+--------------------------------------+\n");
    printf("|  %25s = %-7s |\n","Memory setting","Value");
    printf("+--------------------------------------+\n");
    printf("|  %25s = %-7d |\n","MAX_ABBREVS",MAX_ABBREVS);
    printf("|  %25s = %-7d |\n","NUM_ATTR_BYTES",NUM_ATTR_BYTES);
    printf("|  %25s = %-7d |\n","DICT_WORD_SIZE",DICT_WORD_SIZE);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","DICT_CHAR_SIZE",DICT_CHAR_SIZE);
    printf("|  %25s = %-7d |\n","MAX_DYNAMIC_STRINGS",MAX_DYNAMIC_STRINGS);
    printf("|  %25s = %-7d |\n","HASH_TAB_SIZE",HASH_TAB_SIZE);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_HEADER_EXT_WORDS",ZCODE_HEADER_EXT_WORDS);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_HEADER_FLAGS_3",ZCODE_HEADER_FLAGS_3);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_LESS_DICT_DATA",ZCODE_LESS_DICT_DATA);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_MAX_INLINE_STRING",ZCODE_MAX_INLINE_STRING);
    printf("|  %25s = %-7d |\n","INDIV_PROP_START", INDIV_PROP_START);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MEMORY_MAP_EXTENSION",
        MEMORY_MAP_EXTENSION);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","GLULX_OBJECT_EXT_BYTES",
        GLULX_OBJECT_EXT_BYTES);
    if (glulx_mode)
      printf("|  %25s = %-7ld |\n","MAX_STACK_SIZE",
           (long int) MAX_STACK_SIZE);
    printf("|  %25s = %-7d |\n","TRANSCRIPT_FORMAT",TRANSCRIPT_FORMAT);
    printf("|  %25s = %-7d |\n","WARN_UNUSED_ROUTINES",WARN_UNUSED_ROUTINES);
    printf("|  %25s = %-7d |\n","OMIT_UNUSED_ROUTINES",OMIT_UNUSED_ROUTINES);
    printf("|  %25s = %-7d |\n","STRIP_UNREACHABLE_LABELS",STRIP_UNREACHABLE_LABELS);
    printf("|  %25s = %-7d |\n","OMIT_SYMBOL_TABLE",OMIT_SYMBOL_TABLE);
    printf("|  %25s = %-7d |\n","LONG_DICT_FLAG_BUG",LONG_DICT_FLAG_BUG);
    printf("+--------------------------------------+\n");
}

extern void set_memory_sizes(void)
{
    HASH_TAB_SIZE      = 512;
    DICT_CHAR_SIZE = 1;
    DICT_WORD_SIZE_z = 6;
    DICT_WORD_SIZE_g = 9;
    NUM_ATTR_BYTES_z = 6;
    NUM_ATTR_BYTES_g = 7;
    MAX_ABBREVS = 64;
    MAX_DYNAMIC_STRINGS_z = 32;
    MAX_DYNAMIC_STRINGS_g = 100;
    /* Backwards-compatible behavior: allow for a unicode table
       whether we need one or not. The user can set this to zero if
       there's no unicode table. */
    ZCODE_HEADER_EXT_WORDS = 3;
    ZCODE_HEADER_FLAGS_3 = 0;
    ZCODE_LESS_DICT_DATA = 0;
    ZCODE_MAX_INLINE_STRING = 32;
    GLULX_OBJECT_EXT_BYTES = 0;
    MEMORY_MAP_EXTENSION = 0;
    /* We estimate the default Glulx stack size at 4096. That's about
       enough for 90 nested function calls with 8 locals each -- the
       same capacity as the Z-Spec's suggestion for Z-machine stack
       size. Note that Inform 7 wants more stack; I7-generated code
       sets MAX_STACK_SIZE to 65536 by default. */
    MAX_STACK_SIZE = 4096;
    OMIT_UNUSED_ROUTINES = 0;
    WARN_UNUSED_ROUTINES = 0;
    STRIP_UNREACHABLE_LABELS = 1;
    OMIT_SYMBOL_TABLE = 0;
    LONG_DICT_FLAG_BUG = 1;
    TRANSCRIPT_FORMAT = 0;

    adjust_memory_sizes();
}

extern void adjust_memory_sizes()
{
  if (!glulx_mode) {
    DICT_WORD_SIZE = DICT_WORD_SIZE_z;
    NUM_ATTR_BYTES = NUM_ATTR_BYTES_z;
    MAX_DYNAMIC_STRINGS = MAX_DYNAMIC_STRINGS_z;
    INDIV_PROP_START = 64;
  }
  else {
    DICT_WORD_SIZE = DICT_WORD_SIZE_g;
    NUM_ATTR_BYTES = NUM_ATTR_BYTES_g;
    MAX_DYNAMIC_STRINGS = MAX_DYNAMIC_STRINGS_g;
    INDIV_PROP_START = 256;
  }
}

static void explain_parameter(char *command)
{   printf("\n");
    if (strcmp(command,"HASH_TAB_SIZE")==0)
    {   printf(
"  HASH_TAB_SIZE is the size of the hash tables used for the heaviest \n\
  symbols banks.\n");
        return;
    }
    if (strcmp(command,"DICT_WORD_SIZE")==0)
    {   printf(
"  DICT_WORD_SIZE is the number of characters in a dictionary word. In \n\
  Z-code this is always 6 (only 4 are used in v3 games). In Glulx it \n\
  can be any number.\n");
        return;
    }
    if (strcmp(command,"DICT_CHAR_SIZE")==0)
    {   printf(
"  DICT_CHAR_SIZE is the byte size of one character in the dictionary. \n\
  (This is only meaningful in Glulx, since Z-code has compressed dictionary \n\
  words.) It can be either 1 (the default) or 4 (to enable full Unicode \n\
  input.)\n");
        return;
    }
    if (strcmp(command,"NUM_ATTR_BYTES")==0)
    {   printf(
"  NUM_ATTR_BYTES is the space used to store attribute flags. Each byte \n\
  stores eight attributes. In Z-code this is always 6 (only 4 are used in \n\
  v3 games). In Glulx it can be any number which is a multiple of four, \n\
  plus three.\n");
        return;
    }
    if (strcmp(command,"ZCODE_HEADER_EXT_WORDS")==0)
    {   printf(
"  ZCODE_HEADER_EXT_WORDS is the number of words in the Z-code header \n\
  extension table (Z-Spec 1.0). The -W switch also sets this. It defaults \n\
  to 3, but can be set higher. (It can be set lower if no Unicode \n\
  translation table is created.)\n");
        return;
    }
    if (strcmp(command,"ZCODE_HEADER_FLAGS_3")==0)
    {   printf(
"  ZCODE_HEADER_FLAGS_3 is the value to store in the Flags 3 word of the \n\
  header extension table (Z-Spec 1.1).\n");
        return;
    }
    if (strcmp(command,"ZCODE_LESS_DICT_DATA")==0)
    {   printf(
"  ZCODE_LESS_DICT_DATA, if set, provides each dict word with two data bytes\n\
  rather than three. (Z-code only.)\n");
        return;
    }
    if (strcmp(command,"ZCODE_MAX_INLINE_STRING")==0)
    {   printf(
"  ZCODE_MAX_INLINE_STRING is the length beyond which string literals cannot\n\
  be inlined in assembly opcodes. (Z-code only.)\n");
        return;
    }
    if (strcmp(command,"GLULX_OBJECT_EXT_BYTES")==0)
    {   printf(
"  GLULX_OBJECT_EXT_BYTES is an amount of additional space to add to each \n\
  object record. It is initialized to zero bytes, and the game is free to \n\
  use it as desired. (This is only meaningful in Glulx, since Z-code \n\
  specifies the object structure.)\n");
        return;
    }
    if (strcmp(command,"MAX_ABBREVS")==0)
    {   printf(
"  MAX_ABBREVS is the maximum number of declared abbreviations.  It is not \n\
  allowed to exceed 96 in Z-code. (This is not meaningful in Glulx, where \n\
  there is no limit on abbreviations.)\n");
        return;
    }
    if (strcmp(command,"MAX_DYNAMIC_STRINGS")==0)
    {   printf(
"  MAX_DYNAMIC_STRINGS is the maximum number of string substitution variables\n\
  (\"@00\" or \"@(0)\").  It is not allowed to exceed 96 in Z-code.\n");
        return;
    }
    if (strcmp(command,"INDIV_PROP_START")==0)
    {   printf(
"  Properties 1 to INDIV_PROP_START-1 are common properties; individual\n\
  properties are numbered INDIV_PROP_START and up.\n");
        return;
    }
    if (strcmp(command,"MAX_STACK_SIZE")==0)
    {
        printf(
"  MAX_STACK_SIZE is the maximum size (in bytes) of the interpreter stack \n\
  during gameplay. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MEMORY_MAP_EXTENSION")==0)
    {
        printf(
"  MEMORY_MAP_EXTENSION is the number of bytes (all zeroes) to map into \n\
  memory after the game file. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"TRANSCRIPT_FORMAT")==0)
    {
        printf(
"  TRANSCRIPT_FORMAT, if set to 1, adjusts the gametext.txt transcript for \n\
  easier machine processing; each line will be prefixed by its context.\n");
        return;
    }
    if (strcmp(command,"WARN_UNUSED_ROUTINES")==0)
    {
        printf(
"  WARN_UNUSED_ROUTINES, if set to 2, will display a warning for each \n\
  routine in the game file which is never called. (This includes \n\
  routines called only from uncalled routines, etc.) If set to 1, will warn \n\
  only about functions in game code, not in the system library.\n");
        return;
    }
    if (strcmp(command,"OMIT_UNUSED_ROUTINES")==0)
    {
        printf(
"  OMIT_UNUSED_ROUTINES, if set to 1, will avoid compiling unused routines \n\
  into the game file.\n");
        return;
    }
    if (strcmp(command,"STRIP_UNREACHABLE_LABELS")==0)
    {
        printf(
"  STRIP_UNREACHABLE_LABELS, if set to 1, will skip labels in unreachable \n\
  statements. Jumping to a skipped label is an error. If 0, all labels \n\
  will be compiled, at the cost of less optimized code. The default is 1.\n");
        return;
    }
    if (strcmp(command,"OMIT_SYMBOL_TABLE")==0)
    {
        printf(
"  OMIT_SYMBOL_TABLE, if set to 1, will skip compiling debug symbol names \n\
  into the game file.\n");
        return;
    }
    if (strcmp(command,"LONG_DICT_FLAG_BUG")==0)
    {
        printf(
"  LONG_DICT_FLAG_BUG, if set to 0, will fix the old bug which ignores \n\
  the '//p' flag in long dictionary words. If 1, the buggy behavior is \n\
  retained.\n");
        return;
    }
    if (strcmp(command,"SERIAL")==0)
    {
        printf(
"  SERIAL, if set, will be used as the six digit serial number written into \n\
  the header of the output file.\n");
        return;
    }

    printf("No such memory setting as \"%s\"\n",command);

    return;
}

/* Parse a decimal number as an int32. Return true if a valid number
   was found; otherwise print a warning and return false.

   Anything over nine digits is considered an overflow; we report a
   warning but return +/- 999999999 (and true). This is not entirely
   clever about leading zeroes ("0000000001" is treated as an
   overflow) but this is better than trying to detect genuine
   overflows in a long.

   (Some Glulx settings might conceivably want to go up to $7FFFFFFF,
   which is a ten-digit number, but we're not going to allow that
   today.)

   This used to rely on atoi(), and we retain the atoi() behavior of
   ignoring garbage characters after a valid decimal number.
 */
static int parse_memory_setting(char *str, char *label, int32 *result)
{
    char *cx = str;
    char *ex;
    long val;

    *result = 0;

    while (*cx == ' ') cx++;

    val = strtol(cx, &ex, 10);    

    if (ex == cx) {
        printf("Bad numerical setting in $ command \"%s=%s\"\n",
            label, str);
        return 0;
    }

    if (*cx == '-') {
        if (ex > cx+10) {
            val = -999999999;
            printf("Numerical setting underflowed in $ command \"%s=%s\" (limiting to %ld)\n",
                label, str, val);
        }
    }
    else {
        if (ex > cx+9) {
            val = 999999999;
            printf("Numerical setting overflowed in $ command \"%s=%s\" (limiting to %ld)\n",
                label, str, val);
        }
    }

    *result = (int32)val;
    return 1;
}

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
        if ((ix == 0 && isdigit(command[ix]))
            || !(isalnum(command[ix]) || command[ix] == '_')) {
            printf("Attempt to define invalid symbol: %s\n", command);
            return;
        }
    }

    if (valpos) {
        if (!parse_memory_setting(valpos, command, &value)) {
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
        printf("  ACTIONS: show actions defined\n");
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
   comment.

   (Unix-style command-line options are converted to dollar-sign format
   before being sent here.)

   The name of this function is outdated. Many of these settings are not
   really about memory allocation.
*/
extern void memory_command(char *command)
{   int i, k, flag=0; int32 j;

    for (k=0; command[k]!=0; k++)
        if (islower(command[k])) command[k]=toupper(command[k]);

    if (command[0]=='?') { explain_parameter(command+1); return; }
    if (command[0]=='#') { add_predefined_symbol(command+1); return; }
    if (command[0]=='!') { set_trace_option(command+1); return; }

    if (strcmp(command, "HUGE")==0
        || strcmp(command, "LARGE")==0
        || strcmp(command, "SMALL")==0) {
        if (!nowarnings_switch)
            printf("The Inform 6 memory size commands (\"SMALL, LARGE, HUGE\") are no longer needed and has been withdrawn.\n");
        return;
    }
    
    if (strcmp(command, "LIST")==0)  { list_memory_sizes(); return; }
    
    for (i=0; command[i]!=0; i++)
    {   if (command[i]=='=')
        {   command[i]=0;
            if (!parse_memory_setting(command+i+1, command, &j)) {
                return;
            }
            if (strcmp(command,"BUFFER_LENGTH")==0)
                flag=2;
            if (strcmp(command,"MAX_QTEXT_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_SYMBOLS")==0)
                flag=3;
            if (strcmp(command,"MAX_BANK_SIZE")==0)
                flag=2;
            if (strcmp(command,"SYMBOLS_CHUNK_SIZE")==0)
                flag=3;
            if (strcmp(command,"BANK_CHUNK_SIZE")==0)
                flag=2;
            if (strcmp(command,"HASH_TAB_SIZE")==0)
                HASH_TAB_SIZE=j, flag=1;
            if (strcmp(command,"MAX_OBJECTS")==0)
                flag=3;
            if (strcmp(command,"MAX_ACTIONS")==0)
                flag=3;
            if (strcmp(command,"MAX_ADJECTIVES")==0)
                flag=3;
            if (strcmp(command,"MAX_DICT_ENTRIES")==0)
                flag=3;
            if (strcmp(command,"DICT_WORD_SIZE")==0) 
            {   DICT_WORD_SIZE=j, flag=1;
                DICT_WORD_SIZE_g=DICT_WORD_SIZE_z=j;
            }
            if (strcmp(command,"DICT_CHAR_SIZE")==0)
                DICT_CHAR_SIZE=j, flag=1;
            if (strcmp(command,"NUM_ATTR_BYTES")==0) 
            {   NUM_ATTR_BYTES=j, flag=1;
                NUM_ATTR_BYTES_g=NUM_ATTR_BYTES_z=j;
            }
            if (strcmp(command,"ZCODE_HEADER_EXT_WORDS")==0)
                ZCODE_HEADER_EXT_WORDS=j, flag=1;
            if (strcmp(command,"ZCODE_HEADER_FLAGS_3")==0)
                ZCODE_HEADER_FLAGS_3=j, flag=1;
            if (strcmp(command,"ZCODE_LESS_DICT_DATA")==0)
                ZCODE_LESS_DICT_DATA=j, flag=1;
            if (strcmp(command,"ZCODE_MAX_INLINE_STRING")==0)
                ZCODE_MAX_INLINE_STRING=j, flag=1;
            if (strcmp(command,"GLULX_OBJECT_EXT_BYTES")==0)
                GLULX_OBJECT_EXT_BYTES=j, flag=1;
            if (strcmp(command,"MAX_STATIC_DATA")==0)
                flag=3;
            if (strcmp(command,"MAX_OLDEPTH")==0)
                flag=2;
            if (strcmp(command,"MAX_ROUTINES")==0)
                flag=2;
            if (strcmp(command,"MAX_GCONSTANTS")==0)
                flag=2;
            if (strcmp(command,"MAX_PROP_TABLE_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_FORWARD_REFS")==0)
                flag=2;
            if (strcmp(command,"STACK_SIZE")==0)
                flag=2;
            if (strcmp(command,"STACK_LONG_SLOTS")==0)
                flag=2;
            if (strcmp(command,"STACK_SHORT_LENGTH")==0)
                flag=2;
            if (strcmp(command,"MAX_ABBREVS")==0)
                MAX_ABBREVS=j, flag=1;
            if (strcmp(command,"MAX_DYNAMIC_STRINGS")==0)
            {   MAX_DYNAMIC_STRINGS=j, flag=1;
                MAX_DYNAMIC_STRINGS_g=MAX_DYNAMIC_STRINGS_z=j;
            }
            if (strcmp(command,"MAX_ARRAYS")==0)
                flag=3;
            if (strcmp(command,"MAX_EXPRESSION_NODES")==0)
                flag=3;
            if (strcmp(command,"MAX_VERBS")==0)
                flag=3;
            if (strcmp(command,"MAX_VERBSPACE")==0)
                flag=3;
            if (strcmp(command,"MAX_LABELS")==0)
                flag=3;
            if (strcmp(command,"MAX_LINESPACE")==0)
                flag=3;
            if (strcmp(command,"MAX_NUM_STATIC_STRINGS")==0)
                flag=3;
            if (strcmp(command,"MAX_STATIC_STRINGS")==0)
                flag=3;
            if (strcmp(command,"MAX_ZCODE_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_LINK_DATA_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_LOW_STRINGS")==0)
                flag=3;
            if (strcmp(command,"MAX_TRANSCRIPT_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_CLASSES")==0)
                flag=3;
            if (strcmp(command,"MAX_INCLUSION_DEPTH")==0)
                flag=3;
            if (strcmp(command,"MAX_SOURCE_FILES")==0)
                flag=3;
            if (strcmp(command,"MAX_INDIV_PROP_TABLE_SIZE")==0)
                flag=3;
            if (strcmp(command,"INDIV_PROP_START")==0)
                INDIV_PROP_START=j, flag=1;
            if (strcmp(command,"MAX_OBJ_PROP_TABLE_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_OBJ_PROP_COUNT")==0)
                flag=3;
            if (strcmp(command,"MAX_LOCAL_VARIABLES")==0)
                flag=3;
            if (strcmp(command,"MAX_GLOBAL_VARIABLES")==0)
                flag=3;
            if (strcmp(command,"ALLOC_CHUNK_SIZE")==0)
                flag=3;
            if (strcmp(command,"MAX_UNICODE_CHARS")==0)
                flag=3;
            if (strcmp(command,"MAX_STACK_SIZE")==0)
            {
                MAX_STACK_SIZE=j, flag=1;
                /* Adjust up to a 256-byte boundary. */
                MAX_STACK_SIZE = (MAX_STACK_SIZE + 0xFF) & (~0xFF);
            }
            if (strcmp(command,"MEMORY_MAP_EXTENSION")==0)
            {
                MEMORY_MAP_EXTENSION=j, flag=1;
                /* Adjust up to a 256-byte boundary. */
                MEMORY_MAP_EXTENSION = (MEMORY_MAP_EXTENSION + 0xFF) & (~0xFF);
            }
            if (strcmp(command,"TRANSCRIPT_FORMAT")==0)
            {
                TRANSCRIPT_FORMAT=j, flag=1;
                if (TRANSCRIPT_FORMAT > 1 || TRANSCRIPT_FORMAT < 0)
                    TRANSCRIPT_FORMAT = 1;
            }
            if (strcmp(command,"WARN_UNUSED_ROUTINES")==0)
            {
                WARN_UNUSED_ROUTINES=j, flag=1;
                if (WARN_UNUSED_ROUTINES > 2 || WARN_UNUSED_ROUTINES < 0)
                    WARN_UNUSED_ROUTINES = 2;
            }
            if (strcmp(command,"OMIT_UNUSED_ROUTINES")==0)
            {
                OMIT_UNUSED_ROUTINES=j, flag=1;
                if (OMIT_UNUSED_ROUTINES > 1 || OMIT_UNUSED_ROUTINES < 0)
                    OMIT_UNUSED_ROUTINES = 1;
            }
            if (strcmp(command,"STRIP_UNREACHABLE_LABELS")==0)
            {
                STRIP_UNREACHABLE_LABELS=j, flag=1;
                if (STRIP_UNREACHABLE_LABELS > 1 || STRIP_UNREACHABLE_LABELS < 0)
                    STRIP_UNREACHABLE_LABELS = 1;
            }
            if (strcmp(command,"OMIT_SYMBOL_TABLE")==0)
            {
                OMIT_SYMBOL_TABLE=j, flag=1;
                if (OMIT_SYMBOL_TABLE > 1 || OMIT_SYMBOL_TABLE < 0)
                    OMIT_SYMBOL_TABLE = 1;
            }
            if (strcmp(command,"LONG_DICT_FLAG_BUG")==0)
            {
                LONG_DICT_FLAG_BUG=j, flag=1;
                if (LONG_DICT_FLAG_BUG > 1 || LONG_DICT_FLAG_BUG < 0)
                    LONG_DICT_FLAG_BUG = 1;
            }
            if (strcmp(command,"SERIAL")==0)
            {
                if (j >= 0 && j <= 999999)
                {
                    sprintf(serial_code_buffer,"%06d",j);
                    serial_code_given_in_program = TRUE;
                    flag=1;
                }
            }

            if (flag==0)
                printf("No such memory setting as \"%s\"\n", command);
            if (flag==2 && !nowarnings_switch)
                printf("The Inform 5 memory setting \"%s\" has been withdrawn.\n", command);
            if (flag==3 && !nowarnings_switch)
                printf("The Inform 6 memory setting \"%s\" is no longer needed and has been withdrawn.\n", command);
            return;
        }
    }
    printf("No such memory $ command as \"%s\"\n",command);
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
