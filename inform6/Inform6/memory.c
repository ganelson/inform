/* ------------------------------------------------------------------------- */
/*   "memory" : Memory management and ICL memory setting commands            */
/*              (For "memoryerror", see "errors.c")                          */
/*                                                                           */
/*   Part of Inform 6.33                                                     */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#include "header.h"

int32 malloced_bytes=0;                /* Total amount of memory allocated   */

#ifdef PC_QUICKC

extern void *my_malloc(int32 size, char *whatfor)
{   char _huge *c;
    if (memout_switch)
        printf("Allocating %ld bytes for %s\n",size,whatfor);
    if (size==0) return(NULL);
    c=(char _huge *)halloc(size,1); malloced_bytes+=size;
    if (c==0) memory_out_error(size, 1, whatfor);
    return(c);
}

extern void my_realloc(void *pointer, int32 oldsize, int32 size, 
    char *whatfor)
{   char _huge *c;
    if (size==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=halloc(size,1); malloced_bytes+=size;
    if (c==0) memory_out_error(size, 1, whatfor);
    if (memout_switch)
        printf("Increasing allocation to %ld bytes for %s was (%08lx) \
now (%08lx)\n",
            (long int) size,whatfor,(long int) (*(int **)pointer), 
            (long int) c);
    memcpy(c, *(int **)pointer, MIN(oldsize, size));
    hfree(*(int **)pointer);
    *(int **)pointer = c;
}

extern void *my_calloc(int32 size, int32 howmany, char *whatfor)
{   void _huge *c;
    if (memout_switch)
        printf("Allocating %d bytes: array (%ld entries size %ld) for %s\n",
            size*howmany,howmany,size,whatfor);
    if ((size*howmany) == 0) return(NULL);
    c=(void _huge *)halloc(howmany*size,1); malloced_bytes+=size*howmany;
    if (c==0) memory_out_error(size, howmany, whatfor);
    return(c);
}

extern void my_recalloc(void *pointer, int32 size, int32 oldhowmany, 
    int32 howmany, char *whatfor)
{   void _huge *c;
    if (size*howmany==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=(void _huge *)halloc(size*howmany,1); malloced_bytes+=size*howmany;
    if (c==0) memory_out_error(size, howmany, whatfor);
    if (memout_switch)
        printf("Increasing allocation to %ld bytes: array (%ld entries size %ld) \
for %s was (%08lx) now (%08lx)\n",
            ((long int)size) * ((long int)howmany),
            (long int)howmany,(long int)size,whatfor,
            (long int) *(int **)pointer, (long int) c);
    memcpy(c, *(int **)pointer, MIN(size*oldhowmany, size*howmany));
    hfree(*(int **)pointer);
    *(int **)pointer = c;
}

#else

extern void *my_malloc(int32 size, char *whatfor)
{   char *c;
    if (size==0) return(NULL);
    c=malloc((size_t) size); malloced_bytes+=size;
    if (c==0) memory_out_error(size, 1, whatfor);
    if (memout_switch)
        printf("Allocating %ld bytes for %s at (%08lx)\n",
            (long int) size,whatfor,(long int) c);
    return(c);
}

extern void my_realloc(void *pointer, int32 oldsize, int32 size, 
    char *whatfor)
{   void *c;
    if (size==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=realloc(*(int **)pointer, (size_t) size); malloced_bytes+=size;
    if (c==0) memory_out_error(size, 1, whatfor);
    if (memout_switch)
        printf("Increasing allocation to %ld bytes for %s was (%08lx) \
now (%08lx)\n",
            (long int) size,whatfor,(long int) (*(int **)pointer), 
            (long int) c);
    *(int **)pointer = c;
}

extern void *my_calloc(int32 size, int32 howmany, char *whatfor)
{   void *c;
    if (size*howmany==0) return(NULL);
    c=calloc(howmany,(size_t) size); malloced_bytes+=size*howmany;
    if (c==0) memory_out_error(size, howmany, whatfor);
    if (memout_switch)
        printf("Allocating %ld bytes: array (%ld entries size %ld) \
for %s at (%08lx)\n",
            ((long int)size) * ((long int)howmany),
            (long int)howmany,(long int)size,whatfor,
            (long int) c);
    return(c);
}

extern void my_recalloc(void *pointer, int32 size, int32 oldhowmany, 
    int32 howmany, char *whatfor)
{   void *c;
    if (size*howmany==0) {
        my_free(pointer, whatfor);
        return;
    }
    c=realloc(*(int **)pointer, (size_t)size*(size_t)howmany); 
    malloced_bytes+=size*howmany;
    if (c==0) memory_out_error(size, howmany, whatfor);
    if (memout_switch)
        printf("Increasing allocation to %ld bytes: array (%ld entries size %ld) \
for %s was (%08lx) now (%08lx)\n",
            ((long int)size) * ((long int)howmany),
            (long int)howmany,(long int)size,whatfor,
            (long int) *(int **)pointer, (long int) c);
    *(int **)pointer = c;
}

#endif

extern void my_free(void *pointer, char *whatitwas)
{
    if (*(int **)pointer != NULL)
    {   if (memout_switch)
            printf("Freeing memory for %s at (%08lx)\n",
                whatitwas, (long int) (*(int **)pointer));
#ifdef PC_QUICKC
        hfree(*(int **)pointer);
#else
        free(*(int **)pointer);
#endif
        *(int **)pointer = NULL;
    }
}

/* ------------------------------------------------------------------------- */
/*   Extensible blocks of memory, providing a kind of RAM disc as an         */
/*   alternative to the temporary files option                               */
/* ------------------------------------------------------------------------- */

static char chunk_name_buffer[60];
static char *chunk_name(memory_block *MB, int no)
{   char *p = "(unknown)";
    if (MB == &static_strings_area) p = "static strings area";
    if (MB == &zcode_area)          p = "Z-code area";
    if (MB == &link_data_area)      p = "link data area";
    if (MB == &zcode_backpatch_table) p = "Z-code backpatch table";
    if (MB == &zmachine_backpatch_table) p = "Z-machine backpatch table";
    sprintf(chunk_name_buffer, "%s chunk %d", p, no);
    return(chunk_name_buffer);
}

extern void initialise_memory_block(memory_block *MB)
{   int i;
    MB->chunks = 0;
    for (i=0; i<72; i++) MB->chunk[i] = NULL;
    MB->extent_of_last = 0;
    MB->write_pos = 0;
}

extern void deallocate_memory_block(memory_block *MB)
{   int i;
    for (i=0; i<72; i++)
        if (MB->chunk[i] != NULL)
            my_free(&(MB->chunk[i]), chunk_name(MB, i));
    MB->chunks = 0;
    MB->extent_of_last = 0;
}

extern int read_byte_from_memory_block(memory_block *MB, int32 index)
{   uchar *p;
    p = MB->chunk[index/ALLOC_CHUNK_SIZE];
    if (p == NULL)
    {   compiler_error_named("memory: read from unwritten byte in",
            chunk_name(MB, index/ALLOC_CHUNK_SIZE));
        return 0;
    }
    return p[index % ALLOC_CHUNK_SIZE];
}

extern void write_byte_to_memory_block(memory_block *MB, int32 index, int value)
{   uchar *p; int ch = index/ALLOC_CHUNK_SIZE;
    if (ch < 0)
    {   compiler_error_named("memory: negative index to", chunk_name(MB, 0));
        return;
    }
    if (ch >= 72) memoryerror("ALLOC_CHUNK_SIZE", ALLOC_CHUNK_SIZE);

    if (MB->chunk[ch] == NULL)
    {   int i;
        MB->chunk[ch] = my_malloc(ALLOC_CHUNK_SIZE, chunk_name(MB, ch));
        p = MB->chunk[ch];
        for (i=0; i<ALLOC_CHUNK_SIZE; i++) p[i] = 255;
    }

    p = MB->chunk[ch];
    p[index % ALLOC_CHUNK_SIZE] = value;
}

/* ------------------------------------------------------------------------- */
/*   Where the memory settings are declared as variables                     */
/* ------------------------------------------------------------------------- */

int MAX_QTEXT_SIZE;
int MAX_SYMBOLS;
int SYMBOLS_CHUNK_SIZE;
int HASH_TAB_SIZE;
int MAX_OBJECTS;
int MAX_ARRAYS;
int MAX_ACTIONS;
int MAX_ADJECTIVES;
int MAX_DICT_ENTRIES;
int MAX_STATIC_DATA;
int MAX_PROP_TABLE_SIZE;
int MAX_ABBREVS;
int MAX_EXPRESSION_NODES;
int MAX_VERBS;
int MAX_VERBSPACE;
int MAX_LABELS;
int MAX_LINESPACE;
int32 MAX_STATIC_STRINGS;
int32 MAX_ZCODE_SIZE;
int MAX_LOW_STRINGS;
int32 MAX_TRANSCRIPT_SIZE;
int MAX_CLASSES;
int32 MAX_LINK_DATA_SIZE;
int MAX_INCLUSION_DEPTH;
int MAX_SOURCE_FILES;
int32 MAX_INDIV_PROP_TABLE_SIZE;
int32 MAX_OBJ_PROP_TABLE_SIZE;
int MAX_OBJ_PROP_COUNT;
int MAX_LOCAL_VARIABLES;
int MAX_GLOBAL_VARIABLES;
int DICT_WORD_SIZE; /* number of characters in a dict word */
int DICT_CHAR_SIZE; /* (glulx) 1 for one-byte chars, 4 for Unicode chars */
int DICT_WORD_BYTES; /* DICT_WORD_SIZE*DICT_CHAR_SIZE */
int ZCODE_HEADER_EXT_WORDS; /* (zcode 1.0) requested header extension size */
int ZCODE_HEADER_FLAGS_3; /* (zcode 1.1) value to place in Flags 3 word */
int NUM_ATTR_BYTES;
int GLULX_OBJECT_EXT_BYTES; /* (glulx) extra bytes for each object record */
int32 MAX_NUM_STATIC_STRINGS;
int32 MAX_UNICODE_CHARS;
int32 MAX_STACK_SIZE;
int32 MEMORY_MAP_EXTENSION;
int ALLOC_CHUNK_SIZE;
int WARN_UNUSED_ROUTINES; /* 0: no, 1: yes except in system files, 2: yes always */
int OMIT_UNUSED_ROUTINES; /* 0: no, 1: yes */

/* The way memory sizes are set causes great nuisance for those parameters
   which have different defaults under Z-code and Glulx. We have to get
   the defaults right whether the user sets "-G $HUGE" or "$HUGE -G". 
   And an explicit value set by the user should override both defaults. */
static int32 MAX_ZCODE_SIZE_z, MAX_ZCODE_SIZE_g;
static int MAX_PROP_TABLE_SIZE_z, MAX_PROP_TABLE_SIZE_g;
static int MAX_GLOBAL_VARIABLES_z, MAX_GLOBAL_VARIABLES_g;
static int MAX_LOCAL_VARIABLES_z, MAX_LOCAL_VARIABLES_g;
static int DICT_WORD_SIZE_z, DICT_WORD_SIZE_g;
static int NUM_ATTR_BYTES_z, NUM_ATTR_BYTES_g;
static int ALLOC_CHUNK_SIZE_z, ALLOC_CHUNK_SIZE_g;

/* ------------------------------------------------------------------------- */
/*   Memory control from the command line                                    */
/* ------------------------------------------------------------------------- */

static void list_memory_sizes(void)
{   printf("+--------------------------------------+\n");
    printf("|  %25s = %-7s |\n","Memory setting","Value");
    printf("+--------------------------------------+\n");
    printf("|  %25s = %-7d |\n","MAX_ABBREVS",MAX_ABBREVS);
    printf("|  %25s = %-7d |\n","MAX_ACTIONS",MAX_ACTIONS);
    printf("|  %25s = %-7d |\n","MAX_ADJECTIVES",MAX_ADJECTIVES);
    printf("|  %25s = %-7d |\n","ALLOC_CHUNK_SIZE",ALLOC_CHUNK_SIZE);
    printf("|  %25s = %-7d |\n","MAX_ARRAYS",MAX_ARRAYS);
    printf("|  %25s = %-7d |\n","NUM_ATTR_BYTES",NUM_ATTR_BYTES);
    printf("|  %25s = %-7d |\n","MAX_CLASSES",MAX_CLASSES);
    printf("|  %25s = %-7d |\n","MAX_DICT_ENTRIES",MAX_DICT_ENTRIES);
    printf("|  %25s = %-7d |\n","DICT_WORD_SIZE",DICT_WORD_SIZE);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","DICT_CHAR_SIZE",DICT_CHAR_SIZE);
    printf("|  %25s = %-7d |\n","MAX_EXPRESSION_NODES",MAX_EXPRESSION_NODES);
    printf("|  %25s = %-7d |\n","MAX_GLOBAL_VARIABLES",MAX_GLOBAL_VARIABLES);
    printf("|  %25s = %-7d |\n","HASH_TAB_SIZE",HASH_TAB_SIZE);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_HEADER_EXT_WORDS",ZCODE_HEADER_EXT_WORDS);
    if (!glulx_mode)
      printf("|  %25s = %-7d |\n","ZCODE_HEADER_FLAGS_3",ZCODE_HEADER_FLAGS_3);
    printf("|  %25s = %-7d |\n","MAX_INCLUSION_DEPTH",MAX_INCLUSION_DEPTH);
    printf("|  %25s = %-7d |\n","MAX_INDIV_PROP_TABLE_SIZE",
        MAX_INDIV_PROP_TABLE_SIZE);
    printf("|  %25s = %-7d |\n","MAX_LABELS",MAX_LABELS);
    printf("|  %25s = %-7d |\n","MAX_LINESPACE",MAX_LINESPACE);
    printf("|  %25s = %-7d |\n","MAX_LINK_DATA_SIZE",MAX_LINK_DATA_SIZE);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MAX_LOCAL_VARIABLES",MAX_LOCAL_VARIABLES);
    printf("|  %25s = %-7d |\n","MAX_LOW_STRINGS",MAX_LOW_STRINGS);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MEMORY_MAP_EXTENSION",
        MEMORY_MAP_EXTENSION);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MAX_NUM_STATIC_STRINGS",
        MAX_NUM_STATIC_STRINGS);
    printf("|  %25s = %-7d |\n","MAX_OBJECTS",MAX_OBJECTS);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","GLULX_OBJECT_EXT_BYTES",
        GLULX_OBJECT_EXT_BYTES);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MAX_OBJ_PROP_COUNT",
        MAX_OBJ_PROP_COUNT);
    if (glulx_mode)
      printf("|  %25s = %-7d |\n","MAX_OBJ_PROP_TABLE_SIZE",
        MAX_OBJ_PROP_TABLE_SIZE);
    printf("|  %25s = %-7d |\n","MAX_PROP_TABLE_SIZE",MAX_PROP_TABLE_SIZE);
    printf("|  %25s = %-7d |\n","MAX_QTEXT_SIZE",MAX_QTEXT_SIZE);
    printf("|  %25s = %-7d |\n","MAX_SOURCE_FILES",MAX_SOURCE_FILES);
    if (glulx_mode)
      printf("|  %25s = %-7ld |\n","MAX_STACK_SIZE",
           (long int) MAX_STACK_SIZE);
    printf("|  %25s = %-7d |\n","MAX_STATIC_DATA",MAX_STATIC_DATA);
    printf("|  %25s = %-7ld |\n","MAX_STATIC_STRINGS",
           (long int) MAX_STATIC_STRINGS);
    printf("|  %25s = %-7d |\n","MAX_SYMBOLS",MAX_SYMBOLS);
    printf("|  %25s = %-7d |\n","SYMBOLS_CHUNK_SIZE",SYMBOLS_CHUNK_SIZE);
    printf("|  %25s = %-7ld |\n","MAX_TRANSCRIPT_SIZE",
           (long int) MAX_TRANSCRIPT_SIZE);
    if (glulx_mode)
      printf("|  %25s = %-7ld |\n","MAX_UNICODE_CHARS",
           (long int) MAX_UNICODE_CHARS);
    printf("|  %25s = %-7d |\n","WARN_UNUSED_ROUTINES",WARN_UNUSED_ROUTINES);
    printf("|  %25s = %-7d |\n","OMIT_UNUSED_ROUTINES",OMIT_UNUSED_ROUTINES);
    printf("|  %25s = %-7d |\n","MAX_VERBS",MAX_VERBS);
    printf("|  %25s = %-7d |\n","MAX_VERBSPACE",MAX_VERBSPACE);
    printf("|  %25s = %-7ld |\n","MAX_ZCODE_SIZE",
           (long int) MAX_ZCODE_SIZE);
    printf("+--------------------------------------+\n");
}

extern void set_memory_sizes(int size_flag)
{
    if (size_flag == HUGE_SIZE)
    {
        MAX_QTEXT_SIZE  = 4000;
        MAX_SYMBOLS     = 10000;

        SYMBOLS_CHUNK_SIZE = 5000;
        HASH_TAB_SIZE      = 512;

        MAX_OBJECTS = 640;

        MAX_ACTIONS      = 200;
        MAX_ADJECTIVES   = 50;
        MAX_DICT_ENTRIES = 2000;
        MAX_STATIC_DATA  = 10000;

        MAX_PROP_TABLE_SIZE_z = 30000;
        MAX_PROP_TABLE_SIZE_g = 60000;

        MAX_ABBREVS = 64;

        MAX_EXPRESSION_NODES = 100;
        MAX_VERBS = 200;
        MAX_VERBSPACE = 4096;
        MAX_LABELS = 1000;
        MAX_LINESPACE = 16000;

        MAX_STATIC_STRINGS = 8000;
        MAX_ZCODE_SIZE_z = 20000;
        MAX_ZCODE_SIZE_g = 40000;
        MAX_LINK_DATA_SIZE = 2000;

        MAX_LOW_STRINGS = 2048;

        MAX_TRANSCRIPT_SIZE = 200000;
        MAX_NUM_STATIC_STRINGS = 20000;

        MAX_CLASSES = 64;

        MAX_OBJ_PROP_COUNT = 128;
        MAX_OBJ_PROP_TABLE_SIZE = 4096;

        MAX_INDIV_PROP_TABLE_SIZE = 15000;
        MAX_ARRAYS = 128;

        MAX_GLOBAL_VARIABLES_z = 240;
        MAX_GLOBAL_VARIABLES_g = 512;
        
        ALLOC_CHUNK_SIZE_z = 8192;
        ALLOC_CHUNK_SIZE_g = 32768;
    }
    if (size_flag == LARGE_SIZE)
    {
        MAX_QTEXT_SIZE  = 4000;
        MAX_SYMBOLS     = 6400;

        SYMBOLS_CHUNK_SIZE = 5000;
        HASH_TAB_SIZE      = 512;

        MAX_OBJECTS = 512;

        MAX_ACTIONS      = 200;
        MAX_ADJECTIVES   = 50;
        MAX_DICT_ENTRIES = 1300;
        MAX_STATIC_DATA  = 10000;

        MAX_PROP_TABLE_SIZE_z = 15000;
        MAX_PROP_TABLE_SIZE_g = 30000;

        MAX_ABBREVS = 64;

        MAX_EXPRESSION_NODES = 100;
        MAX_VERBS = 140;
        MAX_VERBSPACE = 4096;
        MAX_LINESPACE = 10000;

        MAX_LABELS = 1000;
        MAX_STATIC_STRINGS = 8000;
        MAX_ZCODE_SIZE_z = 20000;
        MAX_ZCODE_SIZE_g = 40000;
        MAX_LINK_DATA_SIZE = 2000;

        MAX_LOW_STRINGS = 2048;

        MAX_TRANSCRIPT_SIZE = 200000;
        MAX_NUM_STATIC_STRINGS = 20000;

        MAX_CLASSES = 64;

        MAX_OBJ_PROP_COUNT = 64;
        MAX_OBJ_PROP_TABLE_SIZE = 2048;

        MAX_INDIV_PROP_TABLE_SIZE = 10000;
        MAX_ARRAYS = 128;

        MAX_GLOBAL_VARIABLES_z = 240;
        MAX_GLOBAL_VARIABLES_g = 512;
        
        ALLOC_CHUNK_SIZE_z = 8192;
        ALLOC_CHUNK_SIZE_g = 16384;
    }
    if (size_flag == SMALL_SIZE)
    {
        MAX_QTEXT_SIZE  = 4000;
        MAX_SYMBOLS     = 3000;

        SYMBOLS_CHUNK_SIZE = 2500;
        HASH_TAB_SIZE      = 512;

        MAX_OBJECTS = 300;

        MAX_ACTIONS      = 200;
        MAX_ADJECTIVES   = 50;
        MAX_DICT_ENTRIES = 700;
        MAX_STATIC_DATA  = 10000;

        MAX_PROP_TABLE_SIZE_z = 8000;
        MAX_PROP_TABLE_SIZE_g = 16000;

        MAX_ABBREVS = 64;

        MAX_EXPRESSION_NODES = 40;
        MAX_VERBS = 110;
        MAX_VERBSPACE = 2048;
        MAX_LINESPACE = 10000;
        MAX_LABELS = 1000;

        MAX_STATIC_STRINGS = 8000;
        MAX_ZCODE_SIZE_z = 10000;
        MAX_ZCODE_SIZE_g = 20000;
        MAX_LINK_DATA_SIZE = 1000;

        MAX_LOW_STRINGS = 1024;

        MAX_TRANSCRIPT_SIZE = 100000;
        MAX_NUM_STATIC_STRINGS = 10000;

        MAX_CLASSES = 32;

        MAX_OBJ_PROP_COUNT = 64;
        MAX_OBJ_PROP_TABLE_SIZE = 1024;

        MAX_INDIV_PROP_TABLE_SIZE = 5000;
        MAX_ARRAYS = 64;

        MAX_GLOBAL_VARIABLES_z = 240;
        MAX_GLOBAL_VARIABLES_g = 256;
        
        ALLOC_CHUNK_SIZE_z = 8192;
        ALLOC_CHUNK_SIZE_g = 8192;
    }

    /* Regardless of size_flag... */
    MAX_SOURCE_FILES = 256;
    MAX_INCLUSION_DEPTH = 5;
    MAX_LOCAL_VARIABLES_z = 16;
    MAX_LOCAL_VARIABLES_g = 32;
    DICT_CHAR_SIZE = 1;
    DICT_WORD_SIZE_z = 6;
    DICT_WORD_SIZE_g = 9;
    NUM_ATTR_BYTES_z = 6;
    NUM_ATTR_BYTES_g = 7;
    /* Backwards-compatible behavior: allow for a unicode table
       whether we need one or not. The user can set this to zero if
       there's no unicode table. */
    ZCODE_HEADER_EXT_WORDS = 3;
    ZCODE_HEADER_FLAGS_3 = 0;
    GLULX_OBJECT_EXT_BYTES = 0;
    MAX_UNICODE_CHARS = 64;
    MEMORY_MAP_EXTENSION = 0;
    /* We estimate the default Glulx stack size at 4096. That's about
       enough for 90 nested function calls with 8 locals each -- the
       same capacity as the Z-Spec's suggestion for Z-machine stack
       size. Note that Inform 7 wants more stack; I7-generated code
       sets MAX_STACK_SIZE to 65536 by default. */
    MAX_STACK_SIZE = 4096;
    OMIT_UNUSED_ROUTINES = 0;
    WARN_UNUSED_ROUTINES = 0;

    adjust_memory_sizes();
}

extern void adjust_memory_sizes()
{
  if (!glulx_mode) {
    MAX_ZCODE_SIZE = MAX_ZCODE_SIZE_z;
    MAX_PROP_TABLE_SIZE = MAX_PROP_TABLE_SIZE_z;
    MAX_GLOBAL_VARIABLES = MAX_GLOBAL_VARIABLES_z;
    MAX_LOCAL_VARIABLES = MAX_LOCAL_VARIABLES_z;
    DICT_WORD_SIZE = DICT_WORD_SIZE_z;
    NUM_ATTR_BYTES = NUM_ATTR_BYTES_z;
    ALLOC_CHUNK_SIZE = ALLOC_CHUNK_SIZE_z;
  }
  else {
    MAX_ZCODE_SIZE = MAX_ZCODE_SIZE_g;
    MAX_PROP_TABLE_SIZE = MAX_PROP_TABLE_SIZE_g;
    MAX_GLOBAL_VARIABLES = MAX_GLOBAL_VARIABLES_g;
    MAX_LOCAL_VARIABLES = MAX_LOCAL_VARIABLES_g;
    DICT_WORD_SIZE = DICT_WORD_SIZE_g;
    NUM_ATTR_BYTES = NUM_ATTR_BYTES_g;
    ALLOC_CHUNK_SIZE = ALLOC_CHUNK_SIZE_g;
  }
}

static void explain_parameter(char *command)
{   printf("\n");
    if (strcmp(command,"MAX_QTEXT_SIZE")==0)
    {   printf(
"  MAX_QTEXT_SIZE is the maximum length of a quoted string.  Increasing\n\
   by 1 costs 5 bytes (for lexical analysis memory).  Inform automatically\n\
   ensures that MAX_STATIC_STRINGS is at least twice the size of this.");
        return;
    }
    if (strcmp(command,"MAX_SYMBOLS")==0)
    {   printf(
"  MAX_SYMBOLS is the maximum number of symbols - names of variables, \n\
  objects, routines, the many internal Inform-generated names and so on.\n");
        return;
    }
    if (strcmp(command,"SYMBOLS_CHUNK_SIZE")==0)
    {   printf(
"  The symbols names are stored in memory which is allocated in chunks \n\
  of size SYMBOLS_CHUNK_SIZE.\n");
        return;
    }
    if (strcmp(command,"HASH_TAB_SIZE")==0)
    {   printf(
"  HASH_TAB_SIZE is the size of the hash tables used for the heaviest \n\
  symbols banks.\n");
        return;
    }
    if (strcmp(command,"MAX_OBJECTS")==0)
    {   printf(
"  MAX_OBJECTS is the maximum number of objects.  (If compiling a version-3 \n\
  game, 255 is an absolute maximum in any event.)\n");
        return;
    }
    if (strcmp(command,"MAX_ACTIONS")==0)
    {   printf(
"  MAX_ACTIONS is the maximum number of actions - that is, routines such as \n\
  TakeSub which are referenced in the grammar table.\n");
        return;
    }
    if (strcmp(command,"MAX_ADJECTIVES")==0)
    {   printf(
"  MAX_ADJECTIVES is the maximum number of different \"adjectives\" in the \n\
  grammar table.  Adjectives are misleadingly named: they are words such as \n\
  \"in\", \"under\" and the like.\n");
        return;
    }
    if (strcmp(command,"MAX_DICT_ENTRIES")==0)
    {   printf(
"  MAX_DICT_ENTRIES is the maximum number of words which can be entered \n\
  into the game's dictionary.  It costs 29 bytes to increase this by one.\n");
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
    if (strcmp(command,"GLULX_OBJECT_EXT_BYTES")==0)
    {   printf(
"  GLULX_OBJECT_EXT_BYTES is an amount of additional space to add to each \n\
  object record. It is initialized to zero bytes, and the game is free to \n\
  use it as desired. (This is only meaningful in Glulx, since Z-code \n\
  specifies the object structure.)\n");
        return;
    }
    if (strcmp(command,"MAX_STATIC_DATA")==0)
    {   printf(
"  MAX_STATIC_DATA is the size of an array of integers holding initial \n\
  values for arrays and strings stored as ASCII inside the Z-machine.  It \n\
  should be at least 1024 but seldom needs much more.\n");
        return;
    }
    if (strcmp(command,"MAX_PROP_TABLE_SIZE")==0)
    {   printf(
"  MAX_PROP_TABLE_SIZE is the number of bytes allocated to hold the \n\
  properties table.\n");
        return;
    }
    if (strcmp(command,"MAX_ABBREVS")==0)
    {   printf(
"  MAX_ABBREVS is the maximum number of declared abbreviations.  It is not \n\
  allowed to exceed 64.\n");
        return;
    }
    if (strcmp(command,"MAX_ARRAYS")==0)
    {   printf(
"  MAX_ARRAYS is the maximum number of declared arrays.\n");
        return;
    }
    if (strcmp(command,"MAX_EXPRESSION_NODES")==0)
    {   printf(
"  MAX_EXPRESSION_NODES is the maximum number of nodes in the expression \n\
  evaluator's storage for parse trees.  In effect, it measures how \n\
  complicated algebraic expressions are allowed to be.  Increasing it by \n\
  one costs about 80 bytes.\n");
        return;
    }
    if (strcmp(command,"MAX_VERBS")==0)
    {   printf(
"  MAX_VERBS is the maximum number of verbs (such as \"take\") which can be \n\
  defined, each with its own grammar.  To increase it by one costs about\n\
  128 bytes.  A full game will contain at least 100.\n");
        return;
    }
    if (strcmp(command,"MAX_VERBSPACE")==0)
    {   printf(
"  MAX_VERBSPACE is the size of workspace used to store verb words, so may\n\
  need increasing in games with many synonyms: unlikely to exceed 4K.\n");
        return;
    }
    if (strcmp(command,"MAX_LABELS")==0)
    {   printf(
"  MAX_LABELS is the maximum number of label points in any one routine.\n\
  (If the -k debugging information switch is set, MAX_LABELS is raised to\n\
  a minimum level of 2000, as about twice the normal number of label points\n\
  are needed to generate tables of how source code corresponds to positions\n\
  in compiled code.)");
        return;
    }
    if (strcmp(command,"MAX_LINESPACE")==0)
    {   printf(
"  MAX_LINESPACE is the size of workspace used to store grammar lines, so \n\
  may need increasing in games with complex or extensive grammars.\n");
        return;
    }
    if (strcmp(command,"MAX_STATIC_STRINGS")==0)
    {
        printf(
"  MAX_STATIC_STRINGS is the size in bytes of a buffer to hold compiled\n\
  strings before they're written into longer-term storage.  2000 bytes is \n\
  plenty, allowing string constants of up to about 3000 characters long.\n\
  Inform automatically ensures that this is at least twice the size of\n\
  MAX_QTEXT_SIZE, to be on the safe side.");
        return;
    }
    if (strcmp(command,"MAX_ZCODE_SIZE")==0)
    {
        printf(
"  MAX_ZCODE_SIZE is the size in bytes of a buffer to hold compiled \n\
  code for a single routine.  (It applies to both Z-code and Glulx, \n\
  despite the name.)  As a guide, the longest library routine is \n\
  about 6500 bytes long in Z-code; about twice that in Glulx.");
        return;
    }
    if (strcmp(command,"MAX_LINK_DATA_SIZE")==0)
    {
        printf(
"  MAX_LINK_DATA_SIZE is the size in bytes of a buffer to hold module \n\
  link data before it's written into longer-term storage.  2000 bytes \n\
  is plenty.");
        return;
    }
    if (strcmp(command,"MAX_LOW_STRINGS")==0)
    {   printf(
"  MAX_LOW_STRINGS is the size in bytes of a buffer to hold all the \n\
  compiled \"low strings\" which are to be written above the synonyms table \n\
  in the Z-machine.  1024 is plenty.\n");
        return;
    }
    if (strcmp(command,"MAX_TRANSCRIPT_SIZE")==0)
    {   printf(
"  MAX_TRANSCRIPT_SIZE is only allocated for the abbreviations optimisation \n\
  switch, and has the size in bytes of a buffer to hold the entire text of\n\
  the game being compiled: it has to be enormous, say 100000 to 200000.\n");
        return;
    }
    if (strcmp(command,"MAX_CLASSES")==0)
    {   printf(
"  MAX_CLASSES maximum number of object classes which can be defined.  This\n\
  is cheap to increase.\n");
        return;
    }
    if (strcmp(command,"MAX_INCLUSION_DEPTH")==0)
    {   printf(
"  MAX_INCLUSION_DEPTH is the number of nested includes permitted.\n");
        return;
    }
    if (strcmp(command,"MAX_SOURCE_FILES")==0)
    {   printf(
"  MAX_SOURCE_FILES is the number of source files that can be read in the \n\
  compilation.\n");
        return;
    }
    if (strcmp(command,"MAX_INDIV_PROP_TABLE_SIZE")==0)
    {   printf(
"  MAX_INDIV_PROP_TABLE_SIZE is the number of bytes allocated to hold the \n\
  table of ..variable values.\n");
        return;
    }
    if (strcmp(command,"MAX_OBJ_PROP_COUNT")==0)
    {   printf(
"  MAX_OBJ_PROP_COUNT is the maximum number of properties a single object \n\
  can have. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MAX_OBJ_PROP_TABLE_SIZE")==0)
    {   printf(
"  MAX_OBJ_PROP_TABLE_SIZE is the number of words allocated to hold a \n\
  single object's properties. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MAX_LOCAL_VARIABLES")==0)
    {   printf(
"  MAX_LOCAL_VARIABLES is the number of local variables (including \n\
  arguments) allowed in a procedure. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MAX_GLOBAL_VARIABLES")==0)
    {   printf(
"  MAX_GLOBAL_VARIABLES is the number of global variables allowed in the \n\
  program. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MAX_NUM_STATIC_STRINGS")==0)
    {
        printf(
"  MAX_NUM_STATIC_STRINGS is the maximum number of compiled strings \n\
  allowed in the program. (Glulx only)\n");
        return;
    }
    if (strcmp(command,"MAX_UNICODE_CHARS")==0)
    {
        printf(
"  MAX_UNICODE_CHARS is the maximum number of different Unicode characters \n\
  (beyond the Latin-1 range, $00..$FF) which the game text can use. \n\
  (Glulx only)\n");
        return;
    }
    if (strcmp(command,"ALLOC_CHUNK_SIZE")==0)
    {
        printf(
"  ALLOC_CHUNK_SIZE is a base unit of Inform's internal memory allocation \n\
  for various structures.\n");
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

extern void memory_command(char *command)
{   int i, k, flag=0; int32 j;

    for (k=0; command[k]!=0; k++)
        if (islower(command[k])) command[k]=toupper(command[k]);

    if (command[0]=='?') { explain_parameter(command+1); return; }

    if (strcmp(command, "HUGE")==0) { set_memory_sizes(HUGE_SIZE); return; }
    if (strcmp(command, "LARGE")==0) { set_memory_sizes(LARGE_SIZE); return; }
    if (strcmp(command, "SMALL")==0) { set_memory_sizes(SMALL_SIZE); return; }
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
            {   MAX_QTEXT_SIZE=j, flag=1;
                if (2*MAX_QTEXT_SIZE > MAX_STATIC_STRINGS)
                    MAX_STATIC_STRINGS = 2*MAX_QTEXT_SIZE;
            }
            if (strcmp(command,"MAX_SYMBOLS")==0)
                MAX_SYMBOLS=j, flag=1;
            if (strcmp(command,"MAX_BANK_SIZE")==0)
                flag=2;
            if (strcmp(command,"SYMBOLS_CHUNK_SIZE")==0)
                SYMBOLS_CHUNK_SIZE=j, flag=1;
            if (strcmp(command,"BANK_CHUNK_SIZE")==0)
                flag=2;
            if (strcmp(command,"HASH_TAB_SIZE")==0)
                HASH_TAB_SIZE=j, flag=1;
            if (strcmp(command,"MAX_OBJECTS")==0)
                MAX_OBJECTS=j, flag=1;
            if (strcmp(command,"MAX_ACTIONS")==0)
                MAX_ACTIONS=j, flag=1;
            if (strcmp(command,"MAX_ADJECTIVES")==0)
                MAX_ADJECTIVES=j, flag=1;
            if (strcmp(command,"MAX_DICT_ENTRIES")==0)
                MAX_DICT_ENTRIES=j, flag=1;
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
            if (strcmp(command,"GLULX_OBJECT_EXT_BYTES")==0)
                GLULX_OBJECT_EXT_BYTES=j, flag=1;
            if (strcmp(command,"MAX_STATIC_DATA")==0)
                MAX_STATIC_DATA=j, flag=1;
            if (strcmp(command,"MAX_OLDEPTH")==0)
                flag=2;
            if (strcmp(command,"MAX_ROUTINES")==0)
                flag=2;
            if (strcmp(command,"MAX_GCONSTANTS")==0)
                flag=2;
            if (strcmp(command,"MAX_PROP_TABLE_SIZE")==0)
            {   MAX_PROP_TABLE_SIZE=j, flag=1;
                MAX_PROP_TABLE_SIZE_g=MAX_PROP_TABLE_SIZE_z=j;
            }
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
            if (strcmp(command,"MAX_ARRAYS")==0)
                MAX_ARRAYS=j, flag=1;
            if (strcmp(command,"MAX_EXPRESSION_NODES")==0)
                MAX_EXPRESSION_NODES=j, flag=1;
            if (strcmp(command,"MAX_VERBS")==0)
                MAX_VERBS=j, flag=1;
            if (strcmp(command,"MAX_VERBSPACE")==0)
                MAX_VERBSPACE=j, flag=1;
            if (strcmp(command,"MAX_LABELS")==0)
                MAX_LABELS=j, flag=1;
            if (strcmp(command,"MAX_LINESPACE")==0)
                MAX_LINESPACE=j, flag=1;
            if (strcmp(command,"MAX_NUM_STATIC_STRINGS")==0)
                MAX_NUM_STATIC_STRINGS=j, flag=1;
            if (strcmp(command,"MAX_STATIC_STRINGS")==0)
            {   MAX_STATIC_STRINGS=j, flag=1;
                if (2*MAX_QTEXT_SIZE > MAX_STATIC_STRINGS)
                    MAX_STATIC_STRINGS = 2*MAX_QTEXT_SIZE;
            }
            if (strcmp(command,"MAX_ZCODE_SIZE")==0)
            {   MAX_ZCODE_SIZE=j, flag=1;
                MAX_ZCODE_SIZE_g=MAX_ZCODE_SIZE_z=j;
            }
            if (strcmp(command,"MAX_LINK_DATA_SIZE")==0)
                MAX_LINK_DATA_SIZE=j, flag=1;
            if (strcmp(command,"MAX_LOW_STRINGS")==0)
                MAX_LOW_STRINGS=j, flag=1;
            if (strcmp(command,"MAX_TRANSCRIPT_SIZE")==0)
                MAX_TRANSCRIPT_SIZE=j, flag=1;
            if (strcmp(command,"MAX_CLASSES")==0)
                MAX_CLASSES=j, flag=1;
            if (strcmp(command,"MAX_INCLUSION_DEPTH")==0)
                MAX_INCLUSION_DEPTH=j, flag=1;
            if (strcmp(command,"MAX_SOURCE_FILES")==0)
                MAX_SOURCE_FILES=j, flag=1;
            if (strcmp(command,"MAX_INDIV_PROP_TABLE_SIZE")==0)
                MAX_INDIV_PROP_TABLE_SIZE=j, flag=1;
            if (strcmp(command,"MAX_OBJ_PROP_TABLE_SIZE")==0)
                MAX_OBJ_PROP_TABLE_SIZE=j, flag=1;
            if (strcmp(command,"MAX_OBJ_PROP_COUNT")==0)
                MAX_OBJ_PROP_COUNT=j, flag=1;
            if (strcmp(command,"MAX_LOCAL_VARIABLES")==0)
            {   MAX_LOCAL_VARIABLES=j, flag=1;
                MAX_LOCAL_VARIABLES_g=MAX_LOCAL_VARIABLES_z=j;
            }
            if (strcmp(command,"MAX_GLOBAL_VARIABLES")==0)
            {   MAX_GLOBAL_VARIABLES=j, flag=1;
                MAX_GLOBAL_VARIABLES_g=MAX_GLOBAL_VARIABLES_z=j;
            }
            if (strcmp(command,"ALLOC_CHUNK_SIZE")==0)
            {   ALLOC_CHUNK_SIZE=j, flag=1;
                ALLOC_CHUNK_SIZE_g=ALLOC_CHUNK_SIZE_z=j;
            }
            if (strcmp(command,"MAX_UNICODE_CHARS")==0)
                MAX_UNICODE_CHARS=j, flag=1;
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
            if (flag==2)
            printf("The Inform 5 memory setting \"%s\" has been withdrawn.\n\
It should be safe to omit it (putting nothing in its place).\n", command);
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
