/* ------------------------------------------------------------------------- */
/*   Header file for Inform:  Z-machine ("Infocom" format) compiler          */
/*                                                                           */
/*                              Inform 6.33                                  */
/*                                                                           */
/*   This header file and the others making up the Inform source code are    */
/*   copyright (c) Graham Nelson 1993 - 2016                                 */
/*                                                                           */
/*   Manuals for this language are available from the IF-Archive at          */
/*   http://www.ifarchive.org/                                               */
/*                                                                           */
/*   For notes on how this program may legally be used, see the Designer's   */
/*   Manual introduction.  (Any recreational use is fine, and so is some     */
/*   commercial use.)                                                        */
/*                                                                           */
/*   For detailed documentation on how this program internally works, and    */
/*   how to port it to a new environment, see the Technical Manual.          */
/*                                                                           */
/*   *** To compile this program in one of the existing ports, you must      */
/*       at least change the machine definition (on the next page).          */
/*       In most cases no other work will be needed. ***                     */
/*                                                                           */
/*   Contents:                                                               */
/*                                                                           */
/*       Machine/host OS definitions (in alphabetical order)                 */
/*       Default definitions                                                 */
/*       Standard ANSI inclusions, macro definitions, structures             */
/*       Definitions of internal code numbers                                */
/*       Extern declarations for linkage (in alphabetical order of file)     */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#define RELEASE_DATE "5th March 2016"
#define RELEASE_NUMBER 1634
#define GLULX_RELEASE_NUMBER 38
#define MODULE_VERSION_NUMBER 1
#define VNUMBER RELEASE_NUMBER

/* N indicates an intermediate release for Inform 7 */
/*#define RELEASE_SUFFIX "N"*/

/* ------------------------------------------------------------------------- */
/*   Our host machine or OS for today is...                                  */
/*                                                                           */
/*   [ Inform should compile (possibly with warnings) and work safely        */
/*     if you just:                                                          */
/*                                                                           */
/*     #define AMIGA       -  for the Commodore Amiga under SAS/C            */
/*     #define ARCHIMEDES  -  for Acorn RISC OS machines under Norcroft C    */
/*     #define ATARIST     -  for the Atari ST                               */
/*     #define BEOS        -  for the BeBox                                  */
/*     #define LINUX       -  for Linux under gcc (essentially as Unix)      */
/*     #define MACINTOSH   -  for the Apple Mac under Think C or Codewarrior */
/*     #define MAC_MPW     -  for MPW under Codewarrior (and maybe Think C)  */
/*     #define OS2         -  for OS/2 32-bit mode under IBM's C Set++       */
/*     #define OSX         -  for the Apple Mac with OS X (another Unix)     */
/*     #define PC          -  for 386+ IBM PCs, eg. Microsoft Visual C/C++   */
/*     #define PC_QUICKC   -  for small IBM PCs under QuickC                 */
/*     #define PC_WIN32    -  for Borland C++ or Microsoft Visual C++        */
/*     #define UNIX        -  for Unix under gcc (or big IBM PC under djgpp) */
/*     #define UNIX64      -  for 64-bit Unix under gcc                      */
/*     #define VMS         -  for VAX or ALPHA under DEC C, but not VAX C    */
/*                                                                           */
/*     In most cases executables are already available at                    */
/*     http://www.ifarchive.org/, and these are sometimes enhanced with      */
/*     e.g. windowed interfaces whose source is not archived with the        */
/*     main Inform source.]                                                  */
/*                                                                           */
/*   (If no machine is defined, then cautious #defines will be made.  In     */
/*   most cases, porting to a new machine is a matter of carefully filling   */
/*   out a block of definitions like those below.)                           */
/* ------------------------------------------------------------------------- */

/* #define UNIX */

/* ------------------------------------------------------------------------- */
/*   The first task is to include the ANSI header files, and typedef         */
/*   suitable 32-bit integer types.                                          */
/* ------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <time.h>
#include <limits.h>
#include <math.h>

#ifndef VAX
#if   SCHAR_MAX >= 0x7FFFFFFFL && SCHAR_MIN <= -0x7FFFFFFFL
      typedef signed char       int32;
      typedef unsigned char     uint32;
#elif SHRT_MAX >= 0x7FFFFFFFL  && SHRT_MIN <= -0x7FFFFFFFL
      typedef signed short int  int32;
      typedef unsigned short int uint32;
#elif INT_MAX >= 0x7FFFFFFFL   && INT_MIN <= -0x7FFFFFFFL
      typedef signed int        int32;
      typedef unsigned int      uint32;
#elif LONG_MAX >= 0x7FFFFFFFL  && LONG_MIN <= -0x7FFFFFFFL
      typedef signed long int   int32;
      typedef unsigned long int uint32;
#else
#error No type large enough to support 32-bit integers.
#endif
#else
      /*  VAX C does not provide these limit constants, contrary to ANSI  */
      typedef int int32;
      typedef unsigned int uint32;
#endif

/* ------------------------------------------------------------------------- */
/*   The next part of this file contains blocks of definitions, one for      */
/*   each port, of machine or OS-dependent constants needed by Inform.       */
/*                                                                           */
/*   1. MACHINE_STRING should be set to the name of the machine or OS.       */
/*                                                                           */
/*   2. Some miscellaneous #define options (set if the constant is           */
/*   defined, otherwise not set):                                            */
/*                                                                           */
/*   USE_TEMPORARY_FILES - use scratch files for workspace, not memory,      */
/*                         by default                                        */
/*   PROMPT_INPUT        - prompt input (don't use Unix-style command line)  */
/*   TIME_UNAVAILABLE    - don't use ANSI time routines to work out today's  */
/*                         date                                              */
/*   CHAR_IS_UNSIGNED    - if on your compiler the type "char" is unsigned   */
/*                         by default, you should define this                */
/*   HAS_REALPATH        - the POSIX realpath() function is available to     */
/*                         find the absolute path to a file                  */
/*                                                                           */
/*   3. An estimate of the typical amount of memory likely to be free        */
/*   should be given in DEFAULT_MEMORY_SIZE.                                 */
/*   For most modern machines, HUGE_SIZE is the appropriate setting, but     */
/*   some older micros may benefit from SMALL_SIZE.                          */
/* ------------------------------------------------------------------------- */

#define LARGE_SIZE   1
#define SMALL_SIZE   2
#define HUGE_SIZE    3

/* ------------------------------------------------------------------------- */
/*   4. Filenaming definitions:                                              */
/*                                                                           */
/*   It's assumed that the host OS has the concept of subdirectories and     */
/*   has "pathnames", that is, filenames giving a chain of subdirectories    */
/*   divided by the FN_SEP (filename separator) character: e.g. for Unix     */
/*   FN_SEP is defined below as '/' and a typical name is                    */
/*                         "users/graham/jigsaw.z5".                         */
/*   White space is not allowed in filenames, and nor is the special         */
/*   character FN_ALT, which unless defined here will be a comma and will    */
/*   be used to separate alternative locations in a path variable.           */
/*                                                                           */
/*   If NO_FILE_EXTENSIONS is undefined then the OS allows "file extensions" */
/*   of 1 to 3 alphanumeric characters like ".txt" (for text files), ".z5"   */
/*   (for game files), etc., to indicate the file's type (and, crucially,    */
/*   regards the same filename but with different extensions -- e.g.,        */
/*   "frog.amp" and "frog.lil" -- as being different names).                 */
/*   (The file extensions defined below are widely accepted, so please use   */
/*   them unless there's a good reason why not.)                             */
/*                                                                           */
/*   You should then define STANDARD_DIRECTORIES (you can define it anyway)  */
/*   in which case Inform will expect by default that files are sorted out   */
/*   by being put into suitable directories (e.g., a "games" directory for   */
/*   story files).                                                           */
/*                                                                           */
/*   If it's convenient for your port you can alter the detailed definitions */
/*   which these broad settings make.  Be careful if NO_FILE_EXTENSIONS      */
/*   is set without STANDARD_DIRECTORIES, as then Inform may                 */
/*   overwrite its source with object code.                                  */
/*                                                                           */
/*   5. Filenames (or code related to filenames) for the three temporary     */
/*   files.  These only exist during compilation (and only if -F1 is set).   */
/*   Temporary_Name is the body of a filename to use                         */
/*   (if you don't set this, it becomes "Inftemp") and Temporary_Directory   */
/*   is the directory path for the files to go in (which can be altered on   */
/*   the command line).  On some multi-tasking OSs these filenames ought to  */
/*   include a number uniquely identifying the process: to indicate this,    */
/*   define INCLUDE_TASK_ID and provide some code...                         */
/*                                                                           */
/*       #define INCLUDE_TASK_ID                                             */
/*       #ifdef INFORM_FILE                                                  */
/*       static int32 unique_task_id(void)                                   */
/*       {   ...some code returning your task ID...                          */
/*       }                                                                   */
/*       #endif                                                              */
/*                                                                           */
/*   6. Any other definitions specific to the OS or machine.                 */
/*   (In particular DEFAULT_ERROR_FORMAT is 0 on most machines and 1 on PCs; */
/*   it controls the style of error messages, which is important for some    */
/*   error-throwback debugging tools.)                                       */
/* ------------------------------------------------------------------------- */

/* ========================================================================= */
/*   The blocks now follow in alphabetical order.                            */
/* ------------------------------------------------------------------------- */
/*   AMIGA block                                                             */
/* ------------------------------------------------------------------------- */
#ifdef AMIGA
/* 1 */
#define MACHINE_STRING   "Amiga"
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#define __USE_SYSBASE
#include <proto/exec.h>
#define INCLUDE_TASK_ID
#define Temporary_Directory "T:"
#ifdef MAIN_INFORM_FILE
static int32 unique_task_id(void)
{   return (int32)FindTask(NULL);
}
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   ARCHIMEDES block: Acorn/RISC OS settings                                */
/* ------------------------------------------------------------------------- */
#ifdef ARCHIMEDES
/* 1 */
#define MACHINE_STRING   "RISC OS"
/* 2 */
#define CHAR_IS_UNSIGNED
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '.'
#define STANDARD_DIRECTORIES
#define NO_FILE_EXTENSIONS
#define Source_Directory "inform"
#define ICL_Directory "ICL"
/* 5 */
#define ENABLE_TEMPORARY_PATH
#define Temporary_Directory "ram:"
/* 6 */
#define ARC_THROWBACK
#endif
/* ------------------------------------------------------------------------- */
/*   Atari ST block                                                          */
/* ------------------------------------------------------------------------- */
#ifdef ATARIST
/* 1 */
#define MACHINE_STRING   "Atari ST"
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#ifndef TOSFS
#define Temporary_Directory "/tmp"
#define INCLUDE_TASK_ID
#ifdef MAIN_INFORM_FILE
static int32 unique_task_id(void)
{   return (int32)getpid();
}
#endif
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   BEOS block                                                              */
/* ------------------------------------------------------------------------- */
#ifdef BEOS
/* 1 */
#define MACHINE_STRING   "BeOS"
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
#define FILE_EXTENSIONS
/* 5 */
#define Temporary_Directory "/tmp"
#endif
/* ------------------------------------------------------------------------- */
/*   LINUX block                                                             */
/* ------------------------------------------------------------------------- */
#ifdef LINUX
/* 1 */
#define MACHINE_STRING   "Linux"
/* 2 */
#define HAS_REALPATH
/* 3 */
#define DEFAULT_MEMORY_SIZE HUGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#define Temporary_Directory "/tmp"
/* 6 */
#define PATHLEN 8192
#endif
/* ------------------------------------------------------------------------- */
/*   Macintosh block                                                         */
/* ------------------------------------------------------------------------- */
#ifdef MAC_MPW
#define MACINTOSH
#endif

#ifdef MACINTOSH
/* 1 */
#ifdef MAC_MPW
#define MACHINE_STRING   "Macintosh Programmer's Workshop"
#else
#define MACHINE_STRING   "Macintosh"
#endif
/* 2 */
#ifdef MAC_FACE
#define EXTERNAL_SHELL
#endif
#ifndef MAC_FACE
#ifndef MAC_MPW
#define PROMPT_INPUT
#endif
#endif
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP           ':'
#ifdef MAC_MPW
#define Include_Extension ".h"
#endif
/* 6 */
#ifdef MAC_FACE
#include "TB Inform.h"
#endif
#ifdef MAC_MPW
#include <CursorCtl.h>
#define DEFAULT_ERROR_FORMAT 2
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   OS/2 block                                                              */
/* ------------------------------------------------------------------------- */
#ifdef OS2
/* 1 */
#define MACHINE_STRING   "OS/2"
/* 2 */
#define CHAR_IS_UNSIGNED
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
#endif
/* ------------------------------------------------------------------------- */
/*   OSX block                                                              */
/* ------------------------------------------------------------------------- */
#ifdef OSX
/* 1 */
#define MACHINE_STRING   "Mac OS X"
/* 2 */
#define HAS_REALPATH
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#define Temporary_Directory "/tmp"
#define INCLUDE_TASK_ID
#define _POSIX_C_SOURCE 199506L
#define _XOPEN_SOURCE 500
#ifdef MAIN_INFORM_FILE
#include <sys/types.h>
#include <unistd.h>
static int32 unique_task_id(void)
{   return (int32)getpid();
}
#endif
/* 6 */
#define PATHLEN 8192
#endif
/* ------------------------------------------------------------------------- */
/*   PC and PC_QUICKC block                                                  */
/* ------------------------------------------------------------------------- */
#ifdef PC_QUICKC
#define PC
#endif

#ifdef PC
/* 1 */
#define MACHINE_STRING   "PC"
/* 2 */
#define USE_TEMPORARY_FILES
/* 3 */
#ifdef PC_QUICKC
#define DEFAULT_MEMORY_SIZE SMALL_SIZE
#else
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
#endif
/* 4 */
#define FN_SEP '\\'
/* 6 */
#define DEFAULT_ERROR_FORMAT 1
#endif
/* ------------------------------------------------------------------------- */
/*   PC_WIN32 block                                                          */
/* ------------------------------------------------------------------------- */
#ifdef PC_WIN32
/* 1 */
#define MACHINE_STRING   "Win32"
/* 2 */
#define HAS_REALPATH
/* 3 */
#define DEFAULT_MEMORY_SIZE HUGE_SIZE
/* 4 */
#define FN_SEP '\\'
/* 6 */
#define DEFAULT_ERROR_FORMAT 1
#define PATHLEN 512
#ifdef _MSC_VER /* Microsoft Visual C++ */
#define snprintf _snprintf
#define isnan _isnan
#define isinf(x) (!_isnan(x) && !_finite(x))
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   UNIX block                                                              */
/* ------------------------------------------------------------------------- */
#ifdef UNIX
/* 1 */
#define MACHINE_STRING   "Unix"
/* 2 */
#define USE_TEMPORARY_FILES
#define HAS_REALPATH
/* 3 */
#define DEFAULT_MEMORY_SIZE HUGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#define PATHLEN 512
#define Temporary_Directory "/tmp"
#define INCLUDE_TASK_ID
#ifdef MAIN_INFORM_FILE
static int32 unique_task_id(void)
{   return (int32)getpid();
}
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   UNIX64 block                                                            */
/* ------------------------------------------------------------------------- */
#ifdef UNIX64
/* 1 */
#ifndef MACHINE_STRING
#define MACHINE_STRING   "Unix"
#endif
/* 2 */
#define USE_TEMPORARY_FILES
#define HAS_REALPATH
/* 3 */
#define DEFAULT_MEMORY_SIZE HUGE_SIZE
/* 4 */
#define FN_SEP '/'
/* 5 */
#define Temporary_Directory "/tmp"
#define PATHLEN 512
#define INCLUDE_TASK_ID
#ifdef MAIN_INFORM_FILE
static int32 unique_task_id(void)
{   return (int32)getpid();
}
#endif
#endif
/* ------------------------------------------------------------------------- */
/*   VMS (Dec VAX and Alpha) block                                           */
/* ------------------------------------------------------------------------- */
#ifdef __VMS
#define VMS
#endif

#ifdef VMS
/* 1 */
#ifdef __ALPHA
#define MACHINE_STRING   "Alpha/VMS"
#else
#define MACHINE_STRING   "VAX/VMS"
#endif
/* 2 */
#define CHAR_IS_UNSIGNED
/* 3 */
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
/* 4 */
#define FN_SEP '/'
#define Code_Extension   ".zip"
#define V4Code_Extension ".zip"
#define V5Code_Extension ".zip"
#define V6Code_Extension ".zip"
#define V7Code_Extension ".zip"
#define V8Code_Extension ".zip"
#endif
/* ========================================================================= */
/* Default settings:                                                         */
/* ------------------------------------------------------------------------- */

#ifndef NO_FILE_EXTENSIONS
#define FILE_EXTENSIONS
#endif

#ifndef Transcript_File
#ifdef FILE_EXTENSIONS
#define Transcript_File "gametext.txt"
#else
#define Transcript_File "gametext"
#endif
#endif
#ifndef Debugging_File
#ifdef FILE_EXTENSIONS
#define Debugging_File "gameinfo.dbg"
#else
#define Debugging_File "gamedebug"
#endif
#endif

#ifdef FILE_EXTENSIONS
#ifndef Source_Extension
#define Source_Extension  ".inf"
#endif
#ifndef Include_Extension
#define Include_Extension ".h"
#endif
#ifndef Code_Extension
#define Code_Extension    ".z3"
#endif
#ifndef V4Code_Extension
#define V4Code_Extension  ".z4"
#endif
#ifndef V5Code_Extension
#define V5Code_Extension  ".z5"
#endif
#ifndef V6Code_Extension
#define V6Code_Extension  ".z6"
#endif
#ifndef V7Code_Extension
#define V7Code_Extension  ".z7"
#endif
#ifndef V8Code_Extension
#define V8Code_Extension  ".z8"
#endif
#ifndef GlulxCode_Extension
#define GlulxCode_Extension  ".ulx"
#endif
#ifndef Module_Extension
#define Module_Extension  ".m5"
#endif
#ifndef ICL_Extension
#define ICL_Extension     ".icl"
#endif

#else

#define Source_Extension  ""
#define Include_Extension ""
#define Code_Extension    ""
#define V4Code_Extension  ""
#define V5Code_Extension  ""
#define V6Code_Extension  ""
#define V7Code_Extension  ""
#define V8Code_Extension  ""
#define GlulxCode_Extension  ""
#define Module_Extension  ""
#define ICL_Extension     ""
#endif

#ifdef STANDARD_DIRECTORIES
#ifndef Source_Directory
#define Source_Directory  "source"
#endif
#ifndef Include_Directory
#define Include_Directory "library"
#endif
#ifndef Code_Directory
#define Code_Directory    "games"
#endif
#ifndef Module_Directory
#define Module_Directory  "modules"
#endif
#ifndef Temporary_Directory
#define Temporary_Directory ""
#endif
#ifndef ICL_Directory
#define ICL_Directory     ""
#endif

#else

#ifndef Source_Directory
#define Source_Directory  ""
#endif
#ifndef Include_Directory
#define Include_Directory ""
#endif
#ifndef Code_Directory
#define Code_Directory    ""
#endif
#ifndef Module_Directory
#define Module_Directory  ""
#endif
#ifndef Temporary_Directory
#define Temporary_Directory ""
#endif
#ifndef ICL_Directory
#define ICL_Directory     ""
#endif
#endif

#ifndef FN_SEP
#define FN_SEP '/'
#endif

#ifndef FN_ALT
#define FN_ALT ','
#endif

#ifndef PATHLEN
#define PATHLEN 128
#endif

#ifndef Temporary_File
#define Temporary_File "Inftemp"
#endif

#ifndef DEFAULT_ERROR_FORMAT
#define DEFAULT_ERROR_FORMAT 0
#endif

#ifndef DEFAULT_MEMORY_SIZE
#define DEFAULT_MEMORY_SIZE LARGE_SIZE
#endif

#ifndef CHAR_IS_UNSIGNED
    typedef unsigned char uchar;
#else
    typedef char uchar;
#endif

#if defined(__GNUC__) || defined(__clang__)
#define NORETURN __attribute__((__noreturn__))
#endif /* defined(__GNUC__) || defined(__clang__) */

#ifndef NORETURN
#define NORETURN
#endif

/* ------------------------------------------------------------------------- */
/*   A macro (rather than constant) definition:                              */
/* ------------------------------------------------------------------------- */

#ifdef PC_QUICKC
    void _huge * halloc(long, size_t);
    void hfree(void *);
#define subtract_pointers(p1,p2) (long)((char _huge *)p1-(char _huge *)p2)
#else
#define subtract_pointers(p1,p2) (((char *) p1)-((char *) p2))
#endif

/* ------------------------------------------------------------------------- */
/*   SEEK_SET is a constant which should be defined in the ANSI header files */
/*   but which is not present in some implementations: it's used as a        */
/*   parameter for "fseek", defined in "stdio".  In pre-ANSI C, the value    */
/*   0 was used as a parameter instead, hence the definition below.          */
/* ------------------------------------------------------------------------- */

#ifndef SEEK_SET
#define SEEK_SET 0
#endif

/* ------------------------------------------------------------------------- */
/*   A large block of #define'd constant values follows.                     */
/* ------------------------------------------------------------------------- */

#define TRUE -1
#define FALSE 0

/* These checked the glulx_mode global during development, but are no
   longer needed. */
#define ASSERT_ZCODE() (0)
#define ASSERT_GLULX() (0)


#define ReadInt32(ptr)                               \
  (   (((int32)(((uchar *)(ptr))[0])) << 24)         \
    | (((int32)(((uchar *)(ptr))[1])) << 16)         \
    | (((int32)(((uchar *)(ptr))[2])) <<  8)         \
    | (((int32)(((uchar *)(ptr))[3]))      ) )

#define ReadInt16(ptr)                               \
  (   (((int32)(((uchar *)(ptr))[0])) << 8)          \
    | (((int32)(((uchar *)(ptr))[1]))     ) )

#define WriteInt32(ptr, val)                         \
  ((ptr)[0] = (uchar)(((int32)(val)) >> 24),         \
   (ptr)[1] = (uchar)(((int32)(val)) >> 16),         \
   (ptr)[2] = (uchar)(((int32)(val)) >>  8),         \
   (ptr)[3] = (uchar)(((int32)(val))      ) )

#define WriteInt16(ptr, val)                         \
  ((ptr)[0] = (uchar)(((int32)(val)) >> 8),          \
   (ptr)[1] = (uchar)(((int32)(val))     ) )

/* ------------------------------------------------------------------------- */
/*   If your compiler doesn't recognise \t, and you use ASCII, you could     */
/*   define T_C as (char) 9; failing that, it _must_ be defined as ' '       */
/*   (space) and is _not_ allowed to be 0 or any recognisable character.     */
/* ------------------------------------------------------------------------- */

#define TAB_CHARACTER '\t'

/* ------------------------------------------------------------------------- */
/*   Maxima.                                                                 */
/* ------------------------------------------------------------------------- */

#define  MAX_ERRORS            100
#define  MAX_IDENTIFIER_LENGTH  32
#define  MAX_ABBREV_LENGTH      64
#define  MAX_DICT_WORD_SIZE     40
#define  MAX_DICT_WORD_BYTES    (40*4)
#define  MAX_NUM_ATTR_BYTES     39

#define  VENEER_CONSTRAINT_ON_CLASSES_Z       256
#define  VENEER_CONSTRAINT_ON_IP_TABLE_SIZE_Z 128
#define  VENEER_CONSTRAINT_ON_CLASSES_G       32768
#define  VENEER_CONSTRAINT_ON_IP_TABLE_SIZE_G 32768
#define  VENEER_CONSTRAINT_ON_CLASSES  \
  (glulx_mode ? VENEER_CONSTRAINT_ON_CLASSES_G  \
              : VENEER_CONSTRAINT_ON_CLASSES_Z)
#define  VENEER_CONSTRAINT_ON_IP_TABLE_SIZE  \
  (glulx_mode ? VENEER_CONSTRAINT_ON_IP_TABLE_SIZE_G  \
              : VENEER_CONSTRAINT_ON_IP_TABLE_SIZE_Z)

#define  GLULX_HEADER_SIZE 36
/* Number of bytes in the header. */
#define  GLULX_STATIC_ROM_SIZE 24
/* Number of bytes in the Inform-specific block right after the header. */
#define  GPAGESIZE 256
/* All Glulx memory boundaries must be multiples of GPAGESIZE. */

/* In many places the compiler encodes a source-code location (file and
   line number) into an int32 value. The encoded value looks like
   file_number + FILE_LINE_SCALE_FACTOR*line_number. This will go
   badly if a source file has more than FILE_LINE_SCALE_FACTOR lines,
   of course. But this value is roughly eight million, which is a lot
   of lines. 

   There is also potential trouble if we have more than 512 source files;
   perhaps 256, depending on signedness issues. However, there are other
   spots in the compiler that assume no more than 255 source files, so
   we'll stick with this for now.
*/
#define  FILE_LINE_SCALE_FACTOR  (0x800000L)

/* ------------------------------------------------------------------------- */
/*   Structure definitions (there are a few others local to files)           */
/* ------------------------------------------------------------------------- */

typedef struct assembly_operand_t
{   int   type;
    int32 value;
    int   symtype;   /* 6.30 */
    int   symflags;  /* 6.30 */
    int   marker;
} assembly_operand;

#define INITAOTV(aop, typ, val) ((aop)->type=(typ), (aop)->value=(val), (aop)->marker=0, (aop)->symtype=0, (aop)->symflags=0)
#define INITAOT(aop, typ) INITAOTV(aop, typ, 0)
#define INITAO(aop) INITAOTV(aop, 0, 0)

#define  MAX_LINES_PER_VERB 32
typedef struct verbt {
    int lines;
    int l[MAX_LINES_PER_VERB];
} verbt;

typedef struct prop {
    uchar l, num;
    assembly_operand ao[32];
} prop;

/* Only one of this object. */
typedef struct fpropt {
    uchar atts[6];
    int l;
    prop pp[64];
} fpropt;

typedef struct objecttz {
    uchar atts[6];
    int parent, next, child;
    int propsize;
} objecttz;

typedef struct propg {
    int num;
    int continuation; 
    int flags;
    int32 datastart;
    int32 datalen;
} propg;

/* Only one of this object. */
typedef struct fproptg {
    uchar atts[MAX_NUM_ATTR_BYTES]; 
    int numprops;
    propg *props;
    int propdatasize;
    assembly_operand *propdata;
    int32 finalpropaddr;
} fproptg;

typedef struct objecttg {
    /* attributes are stored in a separate array */
    int32 shortname;
    int32 parent, next, child;
    int32 propaddr;
    int32 propsize;
} objecttg;

typedef struct maybe_file_position_S
{   int valid;
    fpos_t position;
} maybe_file_position;

typedef struct debug_location_s
{   int32 file_index;
    int32 beginning_byte_index;
    int32 end_byte_index;
    int32 beginning_line_number;
    int32 end_line_number;
    int32 beginning_character_number;
    int32 end_character_number;
} debug_location;

typedef struct debug_locations_s
{   debug_location location;
    struct debug_locations_s *next;
    int reference_count;
} debug_locations;

typedef struct debug_location_beginning_s
{   debug_locations *head;
    int32 beginning_byte_index;
    int32 beginning_line_number;
    int32 beginning_character_number;
} debug_location_beginning;

typedef struct keyword_group_s
{   char *keywords[120];
    int change_token_type;
    int enabled;
    int case_sensitive;
} keyword_group;

typedef struct token_data_s
{   char *text;
    int32 value; /* ###-long */
    int type;
    int symtype;  /* 6.30 */
    int symflags;   /* 6.30 */
    int marker;
    debug_location location;
} token_data;

typedef struct FileId_s                 /*  Source code file identifier:     */
{   char *filename;                     /*  The filename (after translation) */
    FILE *handle;                       /*  Handle of file (when open), or
                                            NULL when closed                 */
} FileId;

typedef struct ErrorPosition_s
{   int  file_number;
    char *source;
    int  line_number;
    int  main_flag;
} ErrorPosition;

/*  A memory block can hold at most ALLOC_CHUNK_SIZE * 72:  */

extern int ALLOC_CHUNK_SIZE;

typedef struct memory_block_s
{   int chunks;
    int extent_of_last;
    uchar *chunk[72];
    int write_pos;
} memory_block;

/* This serves for both Z-code and Glulx instructions. Glulx doesn't use
   the text, store_variable_number, branch_label_number, or branch_flag
   fields. */
typedef struct assembly_instruction_t
{   int internal_number;
    int store_variable_number;
    int32 branch_label_number;
    int branch_flag;
    char *text;
    int operand_count;
    assembly_operand operand[8];
} assembly_instruction;

typedef struct expression_tree_node_s
{
    /*  Data used in tree construction                                       */

    int up, down, right;
    int operator_number;         /* Only meaningful for non-leaves           */
    assembly_operand value;      /* Only meaningful for leaves               */

    /*  Attributes synthesised during code generation                        */

    int must_produce_value;      /* e.g. FALSE in a void context             */

    int label_after;             /* -1, or "put this label after code"       */
    int to_expression;           /* TRUE if a condition used as numeric val  */
    int true_label;              /* On condition "true", jump to this (or keep
                                    going if -1)                             */
    int false_label;             /* Likewise if the condition is "false".    */

} expression_tree_node;

typedef struct operator_s
{   int precedence;                     /*  Level 0 to 13 (13 is highest)  */
    int token_type;                     /*  Lexical token type  */
    int token_value;                    /*  Lexical token value  */
    int usage;                          /*  Infix (IN_U), prefix or postfix */
    int associativity;                  /*  Left (L_A), right (R_A)
                                            or 0 for "it is an error to
                                            implicitly associate this"  */
    int requires_lvalue;                /*  TRUE if the first operand must
                                            be an "lvalue" (the name of some
                                            storage object, such as a variable
                                            or an array entry)  */
    int opcode_number_z;                /*  Translation number (see below)  */
    int opcode_number_g;                /*  Translation number (see below)  */
    int side_effect;                    /*  TRUE if evaluating the operator
                                            has potential side-effects in
                                            terms of changing the Z-machine  */
    int negation;                       /*  0 for an unconditional operator,
                                            otherwise the negation operator  */
    char *description;                  /*  Text describing the operator
                                            for error messages and tracing  */
} operator;

/*  The translation number of an operator is as follows:

    Z-code:
        an internal opcode number if the operator can be translated
            directly to a single Z-machine opcode;
        400+n if it can be translated to branch opcode n;
        800+n if to the negated form of branch opcode n;
            (using n = 200, 201 for two conditions requiring special
            translation)
        -1 otherwise
    Glulx:
        an internal opcode number if the operator can be translated
            directly to a single Glulx opcode;
        FIRST_CC to LAST_CC if it is a condition;
        -1 otherwise                                                         */

/* ------------------------------------------------------------------------- */
/*   Assembly operand types.                                                 */
/* ------------------------------------------------------------------------- */

/* For Z-machine... */

#define LONG_CONSTANT_OT   0    /* General constant */
#define SHORT_CONSTANT_OT  1    /* Constant in range 0 to 255 */
#define VARIABLE_OT        2    /* Variable (global, local or sp) */
#define OMITTED_OT         3    /* Value used in type field to indicate
                                   that no operand is supplied */
#define EXPRESSION_OT      4    /* Meaning: to determine this value, run code
                                   equivalent to the expression tree whose
                                   root node-number is the value given       */

/* For Glulx... */

/* #define OMITTED_OT      3 */ /* Same as above */
/* #define EXPRESSION_OT   4 */ /* Same as above */
#define CONSTANT_OT        5    /* Four-byte constant */
#define HALFCONSTANT_OT    6    /* Two-byte constant */
#define BYTECONSTANT_OT    7    /* One-byte constant */
#define ZEROCONSTANT_OT    8    /* Constant zero (no bytes of data) */
#define SYSFUN_OT          9    /* System function value */
#define DEREFERENCE_OT     10   /* Value at this address */
#define GLOBALVAR_OT       11   /* Global variable */
#define LOCALVAR_OT        12   /* Local variable or sp */

/* ------------------------------------------------------------------------- */
/*   Internal numbers representing assemble-able Z-opcodes                   */
/* ------------------------------------------------------------------------- */

#define je_zc 0
#define jl_zc 1
#define jg_zc 2
#define dec_chk_zc 3
#define inc_chk_zc 4
#define jin_zc 5
#define test_zc 6
#define or_zc 7
#define and_zc 8
#define test_attr_zc 9
#define set_attr_zc 10
#define clear_attr_zc 11
#define store_zc 12
#define insert_obj_zc 13
#define loadw_zc 14
#define loadb_zc 15
#define get_prop_zc 16
#define get_prop_addr_zc 17
#define get_next_prop_zc 18
#define add_zc 19
#define sub_zc 20
#define mul_zc 21
#define div_zc 22
#define mod_zc 23
#define call_zc 24
#define storew_zc 25
#define storeb_zc 26
#define put_prop_zc 27
#define sread_zc 28
#define print_char_zc 29
#define print_num_zc 30
#define random_zc 31
#define push_zc 32
#define pull_zc 33
#define split_window_zc 34
#define set_window_zc 35
#define output_stream_zc 36
#define input_stream_zc 37
#define sound_effect_zc 38
#define jz_zc 39
#define get_sibling_zc 40
#define get_child_zc 41
#define get_parent_zc 42
#define get_prop_len_zc 43
#define inc_zc 44
#define dec_zc 45
#define print_addr_zc 46
#define remove_obj_zc 47
#define print_obj_zc 48
#define ret_zc 49
#define jump_zc 50
#define print_paddr_zc 51
#define load_zc 52
#define not_zc 53
#define rtrue_zc 54
#define rfalse_zc 55
#define print_zc 56
#define print_ret_zc 57
#define nop_zc 58
#define save_zc 59
#define restore_zc 60
#define restart_zc 61
#define ret_popped_zc 62
#define pop_zc 63
#define quit_zc 64
#define new_line_zc 65
#define show_status_zc 66
#define verify_zc 67
#define call_2s_zc 68
#define call_vs_zc 69
#define aread_zc 70
#define call_vs2_zc 71
#define erase_window_zc 72
#define erase_line_zc 73
#define set_cursor_zc 74
#define get_cursor_zc 75
#define set_text_style_zc 76
#define buffer_mode_zc 77
#define read_char_zc 78
#define scan_table_zc 79
#define call_1s_zc 80
#define call_2n_zc 81
#define set_colour_zc 82
#define throw_zc 83
#define call_vn_zc 84
#define call_vn2_zc 85
#define tokenise_zc 86
#define encode_text_zc 87
#define copy_table_zc 88
#define print_table_zc 89
#define check_arg_count_zc 90
#define call_1n_zc 91
#define catch_zc 92
#define piracy_zc 93
#define log_shift_zc 94
#define art_shift_zc 95
#define set_font_zc 96
#define save_undo_zc 97
#define restore_undo_zc 98
#define draw_picture_zc 99
#define picture_data_zc 100
#define erase_picture_zc 101
#define set_margins_zc 102
#define move_window_zc 103
#define window_size_zc 104
#define window_style_zc 105
#define get_wind_prop_zc 106
#define scroll_window_zc 107
#define pop_stack_zc 108
#define read_mouse_zc 109
#define mouse_window_zc 110
#define push_stack_zc 111
#define put_wind_prop_zc 112
#define print_form_zc 113
#define make_menu_zc 114
#define picture_table_zc 115
#define print_unicode_zc 116
#define check_unicode_zc 117


/* ------------------------------------------------------------------------- */
/*   Internal numbers representing assemble-able Glulx opcodes               */
/* ------------------------------------------------------------------------- */

#define nop_gc 0
#define add_gc 1
#define sub_gc 2
#define mul_gc 3
#define div_gc 4
#define mod_gc 5
#define neg_gc 6
#define bitand_gc 7
#define bitor_gc 8
#define bitxor_gc 9
#define bitnot_gc 10
#define shiftl_gc 11
#define sshiftr_gc 12
#define ushiftr_gc 13
#define jump_gc 14
#define jz_gc 15
#define jnz_gc 16
#define jeq_gc 17
#define jne_gc 18
#define jlt_gc 19
#define jge_gc 20
#define jgt_gc 21
#define jle_gc 22
#define jltu_gc 23
#define jgeu_gc 24
#define jgtu_gc 25
#define jleu_gc 26
#define call_gc 27
#define return_gc 28
#define catch_gc 29
#define throw_gc 30
#define tailcall_gc 31
#define copy_gc 32
#define copys_gc 33
#define copyb_gc 34
#define sexs_gc 35
#define sexb_gc 36
#define aload_gc 37
#define aloads_gc 38
#define aloadb_gc 39
#define aloadbit_gc 40
#define astore_gc 41
#define astores_gc 42
#define astoreb_gc 43
#define astorebit_gc 44
#define stkcount_gc 45
#define stkpeek_gc 46
#define stkswap_gc 47
#define stkroll_gc 48
#define stkcopy_gc 49
#define streamchar_gc 50
#define streamnum_gc 51
#define streamstr_gc 52
#define gestalt_gc 53
#define debugtrap_gc 54
#define getmemsize_gc 55
#define setmemsize_gc 56
#define jumpabs_gc 57
#define random_gc 58
#define setrandom_gc 59
#define quit_gc 60
#define verify_gc 61
#define restart_gc 62
#define save_gc 63
#define restore_gc 64
#define saveundo_gc 65
#define restoreundo_gc 66
#define protect_gc 67
#define glk_gc 68
#define getstringtbl_gc 69
#define setstringtbl_gc 70
#define getiosys_gc 71
#define setiosys_gc 72
#define linearsearch_gc 73
#define binarysearch_gc 74
#define linkedsearch_gc 75
#define callf_gc 76
#define callfi_gc 77
#define callfii_gc 78
#define callfiii_gc 79
#define streamunichar_gc 80
#define mzero_gc 81
#define mcopy_gc 82
#define malloc_gc 83
#define mfree_gc 84
#define accelfunc_gc 85
#define accelparam_gc 86
#define numtof_gc 87
#define ftonumz_gc 88
#define ftonumn_gc 89
#define ceil_gc 90
#define floor_gc 91
#define fadd_gc 92
#define fsub_gc 93
#define fmul_gc 94
#define fdiv_gc 95
#define fmod_gc 96
#define sqrt_gc 97
#define exp_gc 98
#define log_gc 99
#define pow_gc 100
#define sin_gc 101
#define cos_gc 102
#define tan_gc 103
#define asin_gc 104
#define acos_gc 105
#define atan_gc 106
#define atan2_gc 107
#define jfeq_gc 108
#define jfne_gc 109
#define jflt_gc 110
#define jfle_gc 111
#define jfgt_gc 112
#define jfge_gc 113
#define jisnan_gc 114
#define jisinf_gc 115

/* ------------------------------------------------------------------------- */
/*   Index numbers into the keyword group "opcode_macros_g" (see "lexer.c")  */
/* ------------------------------------------------------------------------- */

#define pull_gm   0
#define push_gm   1


#define SYMBOL_TT    0                      /* value = index in symbol table */
#define NUMBER_TT    1                      /* value = the number            */
#define DQ_TT        2                      /* no value                      */
#define SQ_TT        3                      /* no value                      */
#define SEP_TT       4                      /* value = the _SEP code         */
#define EOF_TT       5                      /* no value                      */

#define STATEMENT_TT      100               /* a statement keyword           */
#define SEGMENT_MARKER_TT 101               /* with/has/class etc.           */
#define DIRECTIVE_TT      102               /* a directive keyword           */
#define CND_TT            103               /* in/has/etc.                   */
#define SYSFUN_TT         105               /* built-in function             */
#define LOCAL_VARIABLE_TT 106               /* local variable                */
#define OPCODE_NAME_TT    107               /* opcode name                   */
#define MISC_KEYWORD_TT   108               /* keyword like "char" used in
                                               syntax for a statement        */
#define DIR_KEYWORD_TT    109               /* keyword like "meta" used in
                                               syntax for a directive        */
#define TRACE_KEYWORD_TT  110               /* keyword used in debugging     */
#define SYSTEM_CONSTANT_TT 111              /* such as "code_offset"         */
#define OPCODE_MACRO_TT   112               /* fake opcode for compatibility */

#define OP_TT        200                    /* value = operator no           */
#define ENDEXP_TT    201                    /* no value                      */
#define SUBOPEN_TT   202                    /* ( used for subexpr            */
#define SUBCLOSE_TT  203                    /* ) used to close subexp        */
#define LARGE_NUMBER_TT 204                 /* constant not in range 0-255   */
#define SMALL_NUMBER_TT 205                 /* constant in range 0-255       */
/* In Glulx, that's the range -0x8000 to 0x7fff instead. */
#define VARIABLE_TT  206                    /* variable name                 */
#define DICTWORD_TT  207                    /* literal 'word'                */
#define ACTION_TT    208                    /* action name                   */

#define VOID_CONTEXT       1
#define CONDITION_CONTEXT  2
#define CONSTANT_CONTEXT   3
#define QUANTITY_CONTEXT   4
#define ACTION_Q_CONTEXT   5
#define ASSEMBLY_CONTEXT   6
#define ARRAY_CONTEXT      7
#define FORINIT_CONTEXT    8
#define RETURN_Q_CONTEXT   9

#define LOWEST_SYSTEM_VAR_NUMBER 249        /* globals 249 to 255 are used
                                               in compiled code (Z-code 
                                               only; in Glulx, the range can
                                               change) */

/* ------------------------------------------------------------------------- */
/*   Symbol flag definitions (in no significant order)                       */
/* ------------------------------------------------------------------------- */

#define UNKNOWN_SFLAG  1
#define REPLACE_SFLAG  2
#define USED_SFLAG     4
#define DEFCON_SFLAG   8
#define STUB_SFLAG     16
#define IMPORT_SFLAG   32
#define EXPORT_SFLAG   64
#define ALIASED_SFLAG  128

#define CHANGE_SFLAG   256
#define SYSTEM_SFLAG   512
#define INSF_SFLAG     1024
#define UERROR_SFLAG   2048
#define ACTION_SFLAG   4096
#define REDEFINABLE_SFLAG  8192
#define STAR_SFLAG    16384

/* ------------------------------------------------------------------------- */
/*   Symbol type definitions                                                 */
/* ------------------------------------------------------------------------- */

#define ROUTINE_T             1
#define LABEL_T               2
#define GLOBAL_VARIABLE_T     3
#define ARRAY_T               4
#define CONSTANT_T            5
#define ATTRIBUTE_T           6
#define PROPERTY_T            7
#define INDIVIDUAL_PROPERTY_T 8
#define OBJECT_T              9
#define CLASS_T               10
#define FAKE_ACTION_T         11

/* ------------------------------------------------------------------------- */
/*   Statusline_flag values                                                  */
/* ------------------------------------------------------------------------- */

#define SCORE_STYLE          0
#define TIME_STYLE           1

/* ------------------------------------------------------------------------- */
/*   Inform keyword definitions                                              */
/* ------------------------------------------------------------------------- */

/*  Index numbers into the keyword group "directives" (see "lexer.c")  */

#define ABBREVIATE_CODE  0
#define ARRAY_CODE       1
#define ATTRIBUTE_CODE   2
#define CLASS_CODE       3
#define CONSTANT_CODE    4
#define DEFAULT_CODE     5
#define DICTIONARY_CODE  6
#define END_CODE         7
#define ENDIF_CODE       8
#define EXTEND_CODE      9
#define FAKE_ACTION_CODE 10
#define GLOBAL_CODE      11
#define IFDEF_CODE       12
#define IFNDEF_CODE      13
#define IFNOT_CODE       14
#define IFV3_CODE        15
#define IFV5_CODE        16
#define IFTRUE_CODE      17
#define IFFALSE_CODE     18
#define IMPORT_CODE      19
#define INCLUDE_CODE     20
#define LINK_CODE        21
#define LOWSTRING_CODE   22
#define MESSAGE_CODE     23
#define NEARBY_CODE      24
#define OBJECT_CODE      25
#define PROPERTY_CODE    26
#define RELEASE_CODE     27
#define REPLACE_CODE     28
#define SERIAL_CODE      29
#define SWITCHES_CODE    30
#define STATUSLINE_CODE  31
#define STUB_CODE        32
#define SYSTEM_CODE      33
#define TRACE_CODE       34
#define UNDEF_CODE       35
#define VERB_CODE        36
#define VERSION_CODE     37
#define ZCHARACTER_CODE  38

#define OPENBLOCK_CODE   100
#define CLOSEBLOCK_CODE  101

/*  Index numbers into the keyword group "statements" (see "lexer.c")  */

#define BOX_CODE         0
#define BREAK_CODE       1
#define CONTINUE_CODE    2
#define SDEFAULT_CODE    3
#define DO_CODE          4
#define ELSE_CODE        5
#define FONT_CODE        6
#define FOR_CODE         7
#define GIVE_CODE        8
#define IF_CODE          9
#define INVERSION_CODE   10
#define JUMP_CODE        11
#define MOVE_CODE        12
#define NEW_LINE_CODE    13
#define OBJECTLOOP_CODE  14
#define PRINT_CODE       15
#define PRINT_RET_CODE   16
#define QUIT_CODE        17
#define READ_CODE        18
#define REMOVE_CODE      19
#define RESTORE_CODE     20
#define RETURN_CODE      21
#define RFALSE_CODE      22
#define RTRUE_CODE       23
#define SAVE_CODE        24
#define SPACES_CODE      25
#define STRING_CODE      26
#define STYLE_CODE       27
#define SWITCH_CODE      28
#define UNTIL_CODE       29
#define WHILE_CODE       30

#define ASSIGNMENT_CODE  100
#define FUNCTION_CODE    101

/*  Index numbers into the keyword group "conditions" (see "lexer.c")  */

#define HAS_COND         0
#define HASNT_COND       1
#define IN_COND          2
#define NOTIN_COND       3
#define OFCLASS_COND     4
#define OR_COND          5
#define PROVIDES_COND    6

/*  Index numbers into the keyword group "segment_markers" (see "lexer.c")  */

#define CLASS_SEGMENT    0
#define HAS_SEGMENT      1
#define PRIVATE_SEGMENT  2
#define WITH_SEGMENT     3

/*  Index numbers into the keyword group "misc_keywords" (see "lexer.c")  */

#define CHAR_MK          0
#define NAME_MK          1
#define THE_MK           2
#define A_MK             3
#define AN_MK            4
#define CAP_THE_MK       5
#define NUMBER_MK        6
#define ROMAN_MK         7
#define REVERSE_MK       8
#define BOLD_MK          9
#define UNDERLINE_MK    10
#define FIXED_MK        11
#define ON_MK           12
#define OFF_MK          13
#define TO_MK           14
#define ADDRESS_MK      15
#define STRING_MK       16
#define OBJECT_MK       17
#define NEAR_MK         18
#define FROM_MK         19
#define PROPERTY_MK     20
#define CAP_A_MK        21

/*  Index numbers into the keyword group "directive_keywords" (see "lexer.c")  */

#define ALIAS_DK         0
#define LONG_DK          1
#define ADDITIVE_DK      2
#define SCORE_DK         3
#define TIME_DK          4
#define NOUN_DK          5
#define HELD_DK          6
#define MULTI_DK         7
#define MULTIHELD_DK     8
#define MULTIEXCEPT_DK   9
#define MULTIINSIDE_DK  10
#define CREATURE_DK     11
#define SPECIAL_DK      12
#define NUMBER_DK       13
#define SCOPE_DK        14
#define TOPIC_DK        15
#define REVERSE_DK      16
#define META_DK         17
#define ONLY_DK         18
#define REPLACE_DK      19
#define FIRST_DK        20
#define LAST_DK         21
#define STRING_DK       22
#define TABLE_DK        23
#define BUFFER_DK       24
#define DATA_DK         25
#define INITIAL_DK      26
#define INITSTR_DK      27
#define WITH_DK         28
#define PRIVATE_DK      29
#define HAS_DK          30
#define CLASS_DK        31
#define ERROR_DK        32
#define FATALERROR_DK   33
#define WARNING_DK      34
#define TERMINATING_DK  35

/*  Index numbers into the keyword group "trace_keywords" (see "lexer.c")  */

#define DICTIONARY_TK    0
#define SYMBOLS_TK       1
#define OBJECTS_TK       2
#define VERBS_TK         3
#define ASSEMBLY_TK      4
#define EXPRESSIONS_TK   5
#define LINES_TK         6
#define TOKENS_TK        7
#define LINKER_TK        8
#define ON_TK            9
#define OFF_TK          10

/*  Index numbers into the keyword group "system_constants" (see "lexer.c")  */

#define NO_SYSTEM_CONSTANTS   62

#define adjectives_table_SC   0
#define actions_table_SC      1
#define classes_table_SC      2
#define identifiers_table_SC  3
#define preactions_table_SC   4
#define version_number_SC     5
#define largest_object_SC     6
#define strings_offset_SC     7
#define code_offset_SC        8
#define dict_par1_SC          9
#define dict_par2_SC         10
#define dict_par3_SC         11
#define actual_largest_object_SC 12
#define static_memory_offset_SC 13
#define array_names_offset_SC 14
#define readable_memory_offset_SC 15
#define cpv__start_SC        16
#define cpv__end_SC          17
#define ipv__start_SC        18
#define ipv__end_SC          19
#define array__start_SC      20
#define array__end_SC        21

#define lowest_attribute_number_SC    22
#define highest_attribute_number_SC   23
#define attribute_names_array_SC      24

#define lowest_property_number_SC     25
#define highest_property_number_SC    26
#define property_names_array_SC       27

#define lowest_action_number_SC       28
#define highest_action_number_SC      29
#define action_names_array_SC         30

#define lowest_fake_action_number_SC  31
#define highest_fake_action_number_SC 32
#define fake_action_names_array_SC    33

#define lowest_routine_number_SC      34
#define highest_routine_number_SC     35
#define routines_array_SC             36
#define routine_names_array_SC        37
#define routine_flags_array_SC        38

#define lowest_global_number_SC       39
#define highest_global_number_SC      40
#define globals_array_SC              41
#define global_names_array_SC         42
#define global_flags_array_SC         43

#define lowest_array_number_SC        44
#define highest_array_number_SC       45
#define arrays_array_SC               46
#define array_names_array_SC          47
#define array_flags_array_SC          48

#define lowest_constant_number_SC     49
#define highest_constant_number_SC    50
#define constants_array_SC            51
#define constant_names_array_SC       52

#define lowest_class_number_SC        53
#define highest_class_number_SC       54
#define class_objects_array_SC        55

#define lowest_object_number_SC       56
#define highest_object_number_SC      57

#define oddeven_packing_SC            58

#define grammar_table_SC              59     /* Glulx-only */
#define dictionary_table_SC           60     /* Glulx-only */
#define dynam_string_table_SC         61     /* Glulx-only */


/*  Index numbers into the keyword group "system_functions" (see "lexer.c")  */

#define NUMBER_SYSTEM_FUNCTIONS 12

#define CHILD_SYSF       0
#define CHILDREN_SYSF    1
#define ELDER_SYSF       2
#define ELDEST_SYSF      3
#define INDIRECT_SYSF    4
#define PARENT_SYSF      5
#define RANDOM_SYSF      6
#define SIBLING_SYSF     7
#define YOUNGER_SYSF     8
#define YOUNGEST_SYSF    9
#define METACLASS_SYSF  10
#define GLK_SYSF        11     /* Glulx-only */

/*  Index numbers into the operators group "separators" (see "lexer.c")  */

#define NUMBER_SEPARATORS 49

#define ARROW_SEP        0
#define DARROW_SEP       1
#define DEC_SEP          2
#define MINUS_SEP        3
#define INC_SEP          4
#define PLUS_SEP         5
#define TIMES_SEP        6
#define DIVIDE_SEP       7
#define REMAINDER_SEP    8
#define LOGOR_SEP        9
#define ARTOR_SEP       10
#define LOGAND_SEP      11
#define ARTAND_SEP      12
#define LOGNOT_SEP      13
#define NOTEQUAL_SEP    14
#define ARTNOT_SEP      15
#define CONDEQUALS_SEP  16
#define SETEQUALS_SEP   17
#define GE_SEP          18
#define GREATER_SEP     19
#define LE_SEP          20
#define LESS_SEP        21
#define OPENB_SEP       22
#define CLOSEB_SEP      23
#define COMMA_SEP       24
#define PROPADD_SEP     25
#define PROPNUM_SEP     26
#define MPROPADD_SEP    27
#define MPROPNUM_SEP    28
#define MESSAGE_SEP     29
#define PROPERTY_SEP    30
#define SUPERCLASS_SEP  31
#define COLON_SEP       32
#define AT_SEP          33
#define SEMICOLON_SEP   34
#define OPEN_SQUARE_SEP 35
#define CLOSE_SQUARE_SEP 36
#define OPEN_BRACE_SEP  37
#define CLOSE_BRACE_SEP 38
#define DOLLAR_SEP      39
#define NBRANCH_SEP     40
#define BRANCH_SEP      41
#define HASHADOLLAR_SEP 42
#define HASHGDOLLAR_SEP 43
#define HASHNDOLLAR_SEP 44
#define HASHRDOLLAR_SEP 45
#define HASHWDOLLAR_SEP 46
#define HASHHASH_SEP    47
#define HASH_SEP        48

#define UNARY_MINUS_SEP 100
#define POST_INC_SEP    101
#define POST_DEC_SEP    102

/* ------------------------------------------------------------------------- */
/*   Internal numbers used to refer to operators (in expressions)            */
/*   (must correspond to entries in the operators table in "express.c")      */
/* ------------------------------------------------------------------------- */

#define NUM_OPERATORS 68

#define PRE_U          1
#define IN_U           2
#define POST_U         3

#define R_A            1
#define L_A            2

#define COMMA_OP       0
#define SETEQUALS_OP   1
#define LOGAND_OP      2
#define LOGOR_OP       3
#define LOGNOT_OP      4

#define ZERO_OP        5
#define NONZERO_OP     6
#define CONDEQUALS_OP  7
#define NOTEQUAL_OP    8
#define GE_OP          9
#define GREATER_OP    10
#define LE_OP         11
#define LESS_OP       12
#define HAS_OP        13
#define HASNT_OP      14
#define IN_OP         15
#define NOTIN_OP      16
#define OFCLASS_OP    17
#define PROVIDES_OP   18
#define NOTOFCLASS_OP  19
#define NOTPROVIDES_OP 20
#define OR_OP         21

#define PLUS_OP       22
#define MINUS_OP      23
#define TIMES_OP      24
#define DIVIDE_OP     25
#define REMAINDER_OP  26
#define ARTAND_OP     27
#define ARTOR_OP      28
#define ARTNOT_OP     29
#define ARROW_OP      30
#define DARROW_OP     31
#define UNARY_MINUS_OP 32
#define INC_OP        33
#define POST_INC_OP   34
#define DEC_OP        35
#define POST_DEC_OP   36
#define PROP_ADD_OP   37
#define PROP_NUM_OP   38
#define MPROP_ADD_OP  39
#define MPROP_NUM_OP  40
#define FCALL_OP      41
#define MESSAGE_OP    42
#define PROPERTY_OP   43
#define SUPERCLASS_OP 44

#define ARROW_SETEQUALS_OP   45
#define DARROW_SETEQUALS_OP  46
#define MESSAGE_SETEQUALS_OP 47
#define PROPERTY_SETEQUALS_OP 48

#define ARROW_INC_OP   49
#define DARROW_INC_OP  50
#define MESSAGE_INC_OP 51
#define PROPERTY_INC_OP 52

#define ARROW_DEC_OP   53
#define DARROW_DEC_OP  54
#define MESSAGE_DEC_OP 55
#define PROPERTY_DEC_OP 56

#define ARROW_POST_INC_OP   57
#define DARROW_POST_INC_OP  58
#define MESSAGE_POST_INC_OP 59
#define PROPERTY_POST_INC_OP 60

#define ARROW_POST_DEC_OP   61
#define DARROW_POST_DEC_OP  62
#define MESSAGE_POST_DEC_OP 63
#define PROPERTY_POST_DEC_OP 64

#define PROP_CALL_OP 65
#define MESSAGE_CALL_OP 66

#define PUSH_OP 67 /* Glulx only */

/* ------------------------------------------------------------------------- */
/*   The five types of compiled array                                        */
/* ------------------------------------------------------------------------- */

#define BYTE_ARRAY      0
#define WORD_ARRAY      1
#define STRING_ARRAY    2
#define TABLE_ARRAY     3
#define BUFFER_ARRAY    4

/* ------------------------------------------------------------------------- */
/*   Internal numbers used to refer to veneer routines                       */
/*   (must correspond to entries in the table in "veneer.c")                 */
/* ------------------------------------------------------------------------- */

#define VENEER_ROUTINES 48

#define Box__Routine_VR    0

#define R_Process_VR       1
#define DefArt_VR          2
#define InDefArt_VR        3
#define CDefArt_VR         4
#define CInDefArt_VR       5
#define PrintShortName_VR  6
#define EnglishNumber_VR   7
#define Print__Pname_VR    8

#define WV__Pr_VR          9
#define RV__Pr_VR         10
#define CA__Pr_VR         11
#define IB__Pr_VR         12
#define IA__Pr_VR         13
#define DB__Pr_VR         14
#define DA__Pr_VR         15
#define RA__Pr_VR         16
#define RL__Pr_VR         17
#define RA__Sc_VR         18
#define OP__Pr_VR         19
#define OC__Cl_VR         20

#define Copy__Primitive_VR 21
#define RT__Err_VR         22
#define Z__Region_VR       23
#define Unsigned__Compare_VR 24
#define Metaclass_VR      25
#define CP__Tab_VR        26
#define Cl__Ms_VR         27
#define RT__ChT_VR        28
#define RT__ChR_VR        29
#define RT__ChG_VR        30
#define RT__ChGt_VR       31
#define RT__ChPS_VR       32
#define RT__ChPR_VR       33 
#define RT__TrPS_VR       34
#define RT__ChLDB_VR      35
#define RT__ChLDW_VR      36
#define RT__ChSTB_VR      37
#define RT__ChSTW_VR      38
#define RT__ChPrintC_VR   39
#define RT__ChPrintA_VR   40
#define RT__ChPrintS_VR   41
#define RT__ChPrintO_VR   42

/* Glulx-only veneer routines */
#define OB__Move_VR       43
#define OB__Remove_VR     44
#define Print__Addr_VR    45
#define Glk__Wrap_VR      46
#define Dynam__String_VR  47

/* ------------------------------------------------------------------------- */
/*   Run-time-error numbers (must correspond with RT__Err code in veneer)    */
/* ------------------------------------------------------------------------- */

#define IN_RTE             2
#define HAS_RTE            3
#define PARENT_RTE         4
#define ELDEST_RTE         5
#define CHILD_RTE          6
#define YOUNGER_RTE        7
#define SIBLING_RTE        8
#define CHILDREN_RTE       9
#define YOUNGEST_RTE      10
#define ELDER_RTE         11
#define OBJECTLOOP_RTE    12
#define OBJECTLOOP2_RTE   13
#define GIVE_RTE          14
#define REMOVE_RTE        15
#define MOVE1_RTE         16
#define MOVE2_RTE         17
/* 18 = creating a loop in object tree */
/* 19 = giving a non-existent attribute */
#define DBYZERO_RTE       20
#define PROP_ADD_RTE      21
#define PROP_NUM_RTE      22
#define PROPERTY_RTE      23
/* 24 = reading with -> out of range */
/* 25 = reading with --> out of range */
/* 26 = writing with -> out of range */
/* 27 = writing with --> out of range */
#define ABOUNDS_RTE       28
/* similarly 29, 30, 31 */
#define OBJECTLOOP_BROKEN_RTE 32
/* 33 = print (char) out of range */
/* 34 = print (address) out of range */
/* 35 = print (string) out of range */
/* 36 = print (object) out of range */

/* ------------------------------------------------------------------------- */
/*   Z-region areas (used to refer to module positions in markers)           */
/* ------------------------------------------------------------------------- */

#define LOW_STRINGS_ZA         1
#define PROP_DEFAULTS_ZA       2
#define OBJECT_TREE_ZA         3
#define PROP_ZA                4
#define CLASS_NUMBERS_ZA       5
#define INDIVIDUAL_PROP_ZA     6
#define DYNAMIC_ARRAY_ZA       7 /* Z-code only */
#define GRAMMAR_ZA             8
#define ACTIONS_ZA             9
#define PREACTIONS_ZA         10
#define ADJECTIVES_ZA         11
#define DICTIONARY_ZA         12
#define ZCODE_ZA              13
#define STATIC_STRINGS_ZA     14
#define LINK_DATA_ZA          15

#define SYMBOLS_ZA            16

#define ARRAY_ZA              17 /* Glulx only */
#define GLOBALVAR_ZA          18 /* Glulx only */

/* ------------------------------------------------------------------------- */
/*   "Marker values", used for backpatching and linkage                      */
/* ------------------------------------------------------------------------- */

#define NULL_MV                0     /* Null */

/* Marker values used in backpatch areas: */

#define DWORD_MV               1     /* Dictionary word address */
#define STRING_MV              2     /* Static string */
#define INCON_MV               3     /* "Hardware" constant (table address) */
#define IROUTINE_MV            4     /* Call to internal routine */
#define VROUTINE_MV            5     /* Call to veneer routine */
#define ARRAY_MV               6     /* Ref to internal array address */
#define NO_OBJS_MV             7     /* Ref to number of game objects */
#define INHERIT_MV             8     /* Inherited property value */
#define INHERIT_INDIV_MV       9     /* Inherited indiv property value */
#define MAIN_MV               10     /* "Main" routine */
#define SYMBOL_MV             11     /* Forward ref to unassigned symbol */

/* Additional marker values used in module backpatch areas: */
/* (In Glulx, OBJECT_MV and VARIABLE_MV are used in backpatching, even
   without modules.) */

#define VARIABLE_MV           12     /* Global variable */
#define IDENT_MV              13     /* Property identifier number */
#define INDIVPT_MV            14     /* Individual prop table address */
#define ACTION_MV             15     /* Action number */
#define OBJECT_MV             16     /* Ref to internal object number */

#define LARGEST_BPATCH_MV     16     /* Larger marker values are never written
                                        to backpatch tables */

/* Value indicating an imported symbol record: */

#define IMPORT_MV             32

/* Values indicating an exported symbol record: */

#define EXPORT_MV             33     /* Defined ordinarily */
#define EXPORTSF_MV           34     /* Defined in a system file */
#define EXPORTAC_MV           35     /* Action name */

/* Values used only in branch backpatching: */
/* ###-I've rearranged these, so that BRANCH_MV can be last; Glulx uses the
   whole range from BRANCH_MV to BRANCHMAX_MV. */

#define LABEL_MV              36     /* Ditto: marks "jump" operands */
#define DELETED_MV            37     /* Ditto: marks bytes deleted from code */
#define BRANCH_MV             38     /* Used in "asm.c" for routine coding */
#define BRANCHMAX_MV          58     /* In fact, the range BRANCH_MV to 
                                        BRANCHMAX_MV all means the same thing.
                                        The position within the range means
                                        how far back from the label to go
                                        to find the opmode byte to modify. */

/* ========================================================================= */
/*   Initialisation extern definitions                                       */
/*                                                                           */
/*   Note that each subsystem in Inform provides four routines to keep       */
/*   track of variables and data structures:                                 */
/*                                                                           */
/*       init_*_vars      should set variables to initial values (they must  */
/*                        not be initialised directly in their declarations  */
/*                        as Inform may need to compile several times in a   */
/*                        row)                                               */
/*                                                                           */
/*       *_begin_pass     any variable/array initialisation that needs to    */
/*                        happen at the start of the pass through the source */
/*                                                                           */
/*       *_allocate_arrays   should use my_malloc/my_calloc (see memory.c)   */
/*                        to allocate any arrays or workspace needed         */
/*                                                                           */
/*       *_free_arrays    should use my_free to free all memory allocated    */
/*                        (with one exception in "text.c")                   */
/*                                                                           */
/* ========================================================================= */

                                      /* > READ INFORM SOURCE                */

                                      /* My Source Book                      */

extern void init_arrays_vars(void);   /* arrays: construct tableaux          */
extern void init_asm_vars(void);      /* asm: assemble even rare or v6 codes */
extern void init_bpatch_vars(void);   /* bpatch: backpatches code            */
extern void init_chars_vars(void);    /* chars: translate character sets     */
extern void init_directs_vars(void);  /* directs: ponder directives          */
extern void init_errors_vars(void);   /* errors: issue diagnostics           */
extern void init_expressc_vars(void); /* expressc: compile expressions       */
extern void init_expressp_vars(void); /* expressp: parse expressions         */
extern void init_files_vars(void);    /* files: handle files                 */
    /* void init_vars(void);             inform: decide what to do           */
extern void init_lexer_vars(void);    /* lexer: lexically analyse source     */
extern void init_linker_vars(void);   /* linker: link in pre-compiled module */
extern void init_memory_vars(void);   /* memory: manage memory settings      */
extern void init_objects_vars(void);  /* objects: cultivate object tree      */
extern void init_states_vars(void);   /* states: translate statements to code*/
extern void init_symbols_vars(void);  /* symbols: construct symbols table    */
extern void init_syntax_vars(void);   /* syntax: parse the program           */
extern void init_tables_vars(void);   /* tables: glue tables into the output */
extern void init_text_vars(void);     /* text: encode text and dictionary    */
extern void init_veneer_vars(void);   /* veneer: compile a layer of code     */
extern void init_verbs_vars(void);    /* verbs: lay out grammar              */

extern void files_begin_prepass(void);  /*  These routines initialise just   */
extern void lexer_begin_prepass(void);  /*  enough to begin loading source   */

extern void arrays_begin_pass(void);
extern void asm_begin_pass(void);
extern void bpatch_begin_pass(void);
extern void chars_begin_pass(void);
extern void directs_begin_pass(void);
extern void errors_begin_pass(void);
extern void expressc_begin_pass(void);
extern void expressp_begin_pass(void);
extern void files_begin_pass(void);
    /* void begin_pass(void); */
extern void lexer_begin_pass(void);
extern void linker_begin_pass(void);
extern void memory_begin_pass(void);
extern void objects_begin_pass(void);
extern void states_begin_pass(void);
extern void symbols_begin_pass(void);
extern void syntax_begin_pass(void);
extern void tables_begin_pass(void);
extern void text_begin_pass(void);
extern void veneer_begin_pass(void);
extern void verbs_begin_pass(void);

extern void lexer_endpass(void);
extern void linker_endpass(void);

extern void arrays_allocate_arrays(void);
extern void asm_allocate_arrays(void);
extern void bpatch_allocate_arrays(void);
extern void chars_allocate_arrays(void);
extern void directs_allocate_arrays(void);
extern void errors_allocate_arrays(void);
extern void expressc_allocate_arrays(void);
extern void expressp_allocate_arrays(void);
extern void files_allocate_arrays(void);
    /* void allocate_arrays(void); */
extern void lexer_allocate_arrays(void);
extern void linker_allocate_arrays(void);
extern void memory_allocate_arrays(void);
extern void objects_allocate_arrays(void);
extern void states_allocate_arrays(void);
extern void symbols_allocate_arrays(void);
extern void syntax_allocate_arrays(void);
extern void tables_allocate_arrays(void);
extern void text_allocate_arrays(void);
extern void veneer_allocate_arrays(void);
extern void verbs_allocate_arrays(void);

extern void arrays_free_arrays(void);
extern void asm_free_arrays(void);
extern void bpatch_free_arrays(void);
extern void chars_free_arrays(void);
extern void directs_free_arrays(void);
extern void errors_free_arrays(void);
extern void expressc_free_arrays(void);
extern void expressp_free_arrays(void);
extern void files_free_arrays(void);
    /* void free_arrays(void); */
extern void lexer_free_arrays(void);
extern void linker_free_arrays(void);
extern void memory_free_arrays(void);
extern void objects_free_arrays(void);
extern void states_free_arrays(void);
extern void symbols_free_arrays(void);
extern void syntax_free_arrays(void);
extern void tables_free_arrays(void);
extern void text_free_arrays(void);
extern void veneer_free_arrays(void);
extern void verbs_free_arrays(void);

/* ========================================================================= */
/*   Remaining extern definitions are given by file in alphabetical order    */
/* ------------------------------------------------------------------------- */
/*   Extern definitions for "arrays"                                         */
/* ------------------------------------------------------------------------- */

extern int no_globals, no_arrays;
extern int dynamic_array_area_size;
extern int *dynamic_array_area;
extern int32 *global_initial_value;
extern int32 *array_symbols;
extern int  *array_sizes, *array_types;

extern void make_global(int array_flag, int name_only);
extern void set_variable_value(int i, int32 v);
extern void check_globals(void);
extern int32 begin_table_array(void);
extern int32 begin_word_array(void);
extern void array_entry(int32 i, assembly_operand VAL);
extern void finish_array(int32 i);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "asm"                                            */
/* ------------------------------------------------------------------------- */

extern memory_block zcode_area;
extern int32 zmachine_pc;

extern int32 no_instructions;
extern int   sequence_point_follows;
extern int   uses_unicode_features, uses_memheap_features, 
    uses_acceleration_features, uses_float_features;
extern debug_location statement_debug_location;
extern int   execution_never_reaches_here;
extern int   *variable_usage;
extern int   next_label, no_sequence_points;
extern int32 *variable_tokens;
extern assembly_instruction AI;
extern int32 *named_routine_symbols;

extern void print_operand(assembly_operand o);
extern char *variable_name(int32 i);
extern void set_constant_ot(assembly_operand *AO);
extern int  is_constant_ot(int otval);
extern int  is_variable_ot(int otval);
extern void assemblez_instruction(assembly_instruction *a);
extern void assembleg_instruction(assembly_instruction *a);
extern void assemble_label_no(int n);
extern void assemble_jump(int n);
extern void define_symbol_label(int symbol);
extern int32 assemble_routine_header(int no_locals, int debug_flag,
    char *name, int embedded_flag, int the_symbol);
extern void assemble_routine_end(int embedded_flag, debug_locations locations);

extern void assemblez_0(int internal_number);
extern void assemblez_0_to(int internal_number, assembly_operand o1);
extern void assemblez_0_branch(int internal_number, int label, int flag);
extern void assemblez_1(int internal_number, assembly_operand o1);
extern void assemblez_1_to(int internal_number,
                       assembly_operand o1, assembly_operand st);
extern void assemblez_1_branch(int internal_number,
                       assembly_operand o1, int label, int flag);
extern void assemblez_objcode(int internal_number,
                       assembly_operand o1, assembly_operand st,
                       int label, int flag);
extern void assemblez_2(int internal_number,
                       assembly_operand o1, assembly_operand o2);
extern void assemblez_2_to(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand st);
extern void assemblez_2_branch(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       int label, int flag);
extern void assemblez_3(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3);
extern void assemblez_3_branch(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, int label, int flag);
extern void assemblez_3_to(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand st);
extern void assemblez_4(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4);
extern void assemblez_5(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4,
                       assembly_operand o5);
extern void assemblez_6(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4,
                       assembly_operand o5, assembly_operand o6);
extern void assemblez_4_branch(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4,
                       int label, int flag);
extern void assemblez_4_to(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4,
                       assembly_operand st);
extern void assemblez_5_to(int internal_number,
                       assembly_operand o1, assembly_operand o2,
                       assembly_operand o3, assembly_operand o4,
                       assembly_operand o5, assembly_operand st);

extern void assemblez_inc(assembly_operand o1);
extern void assemblez_dec(assembly_operand o1);
extern void assemblez_store(assembly_operand o1, assembly_operand o2);
extern void assemblez_jump(int n);

extern void assembleg_0(int internal_number);
extern void assembleg_1(int internal_number, assembly_operand o1);
extern void assembleg_2(int internal_number, assembly_operand o1,
  assembly_operand o2);
extern void assembleg_3(int internal_number, assembly_operand o1,
  assembly_operand o2, assembly_operand o3);
extern void assembleg_4(int internal_number, assembly_operand o1,
  assembly_operand o2, assembly_operand o3, assembly_operand o4);
extern void assembleg_5(int internal_number, assembly_operand o1,
  assembly_operand o2, assembly_operand o3, assembly_operand o4,
  assembly_operand o5);
extern void assembleg_0_branch(int internal_number,
  int label);
extern void assembleg_1_branch(int internal_number,
  assembly_operand o1, int label);
extern void assembleg_2_branch(int internal_number,
  assembly_operand o1, assembly_operand o2, int label);
extern void assembleg_call_1(assembly_operand oaddr, assembly_operand o1, 
  assembly_operand odest);
extern void assembleg_call_2(assembly_operand oaddr, assembly_operand o1, 
  assembly_operand o2, assembly_operand odest);
extern void assembleg_call_3(assembly_operand oaddr, assembly_operand o1, 
  assembly_operand o2, assembly_operand o3, assembly_operand odest);
extern void assembleg_inc(assembly_operand o1);
extern void assembleg_dec(assembly_operand o1);
extern void assembleg_store(assembly_operand o1, assembly_operand o2);
extern void assembleg_jump(int n);

extern void parse_assembly(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "bpatch"                                         */
/* ------------------------------------------------------------------------- */

extern memory_block zcode_backpatch_table, zmachine_backpatch_table;
extern int32 zcode_backpatch_size, zmachine_backpatch_size;
extern int   backpatch_marker, backpatch_error_flag;

extern int32 backpatch_value(int32 value);
extern void  backpatch_zmachine_image_z(void);
extern void  backpatch_zmachine_image_g(void);
extern void  backpatch_zmachine(int mv, int zmachine_area, int32 offset);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "chars"                                          */
/* ------------------------------------------------------------------------- */

extern uchar source_to_iso_grid[];
extern int32 iso_to_unicode_grid[];
extern int   character_digit_value[];
extern uchar alphabet[3][27];
extern int   alphabet_modified;
extern int   zscii_defn_modified;
extern int   zscii_high_water_mark;
extern char  alphabet_used[];
extern int   iso_to_alphabet_grid[];
extern int   zscii_to_alphabet_grid[];
extern int   textual_form_length;

extern int   iso_to_unicode(int iso);
extern int   unicode_to_zscii(int32 u);
extern int32 zscii_to_unicode(int z);
extern int32 text_to_unicode(char *text);
extern void  zscii_to_text(char *text, int zscii);
extern char *name_of_iso_set(int s);
extern void  change_character_set(void);
extern void  new_alphabet(char *text, int alphabet);
extern void  new_zscii_character(int32 unicode, int plus_flag);
extern void  new_zscii_finished(void);
extern void  map_new_zchar(int32 unicode);
extern void  make_lower_case(char *str);
extern void  make_upper_case(char *str);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "directs"                                        */
/* ------------------------------------------------------------------------- */

extern int32 routine_starts_line;

extern int  no_routines, no_named_routines, no_locals, no_termcs;
extern int  terminating_characters[];

extern int  parse_given_directive(int internal_flag);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "errors"                                         */
/* ------------------------------------------------------------------------- */

extern char *forerrors_buff;
extern int  forerrors_pointer;
extern int  no_errors, no_warnings, no_suppressed_warnings,
            no_link_errors, no_compiler_errors;

extern ErrorPosition ErrorReport;

extern void fatalerror(char *s) NORETURN;
extern void fatalerror_named(char *s1, char *s2) NORETURN;
extern void memory_out_error(int32 size, int32 howmany, char *name) NORETURN;
extern void memoryerror(char *s, int32 size) NORETURN;
extern void error(char *s);
extern void error_named(char *s1, char *s2);
extern void error_numbered(char *s1, int val);
extern void error_named_at(char *s1, char *s2, int32 report_line);
extern void ebf_error(char *s1, char *s2);
extern void char_error(char *s, int ch);
extern void unicode_char_error(char *s, int32 uni);
extern void no_such_label(char *lname);
extern void warning(char *s);
extern void warning_numbered(char *s1, int val);
extern void warning_named(char *s1, char *s2);
extern void dbnu_warning(char *type, char *name, int32 report_line);
extern void uncalled_routine_warning(char *type, char *name, int32 report_line);
extern void obsolete_warning(char *s1);
extern void link_error(char *s);
extern void link_error_named(char *s1, char *s2);
extern int  compiler_error(char *s);
extern int  compiler_error_named(char *s1, char *s2);
extern void print_sorry_message(void);

#ifdef ARC_THROWBACK
extern int  throwback_switch;

extern void throwback(int severity, char * error);
extern void throwback_start(void);
extern void throwback_end(void);
#endif

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "expressc"                                       */
/* ------------------------------------------------------------------------- */

extern int vivc_flag;
extern operator operators[];

extern assembly_operand stack_pointer, temp_var1, temp_var2, temp_var3, 
    temp_var4, zero_operand, one_operand, two_operand, three_operand,
    four_operand, valueless_operand;

assembly_operand code_generate(assembly_operand AO, int context, int label);
assembly_operand check_nonzero_at_runtime(assembly_operand AO1, int label,
       int rte_number);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "expressp"                                       */
/* ------------------------------------------------------------------------- */

extern int system_function_usage[];
extern expression_tree_node *ET;

extern int z_system_constant_list[];
extern int glulx_system_constant_list[];

extern int32 value_of_system_constant(int t);
extern void clear_expression_space(void);
extern void show_tree(assembly_operand AO, int annotate);
extern assembly_operand parse_expression(int context);
extern int test_for_incdec(assembly_operand AO);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "files"                                          */
/* ------------------------------------------------------------------------- */

extern int  input_file;
extern FileId *InputFiles;

extern FILE *Temp1_fp, *Temp2_fp, *Temp3_fp;
extern char Temp1_Name[], Temp2_Name[], Temp3_Name[];
extern int32 total_chars_read;

extern void open_temporary_files(void);
extern void check_temp_files(void);
extern void remove_temp_files(void);

extern void open_transcript_file(char *what_of);
extern void write_to_transcript_file(char *text);
extern void close_transcript_file(void);
extern void abort_transcript_file(void);

extern void nullify_debug_file_position(maybe_file_position *position);

extern void begin_debug_file(void);

extern void debug_file_printf(const char*format, ...);
extern void debug_file_print_with_entities(const char*string);
extern void debug_file_print_base_64_triple
    (uchar first, uchar second, uchar third);
extern void debug_file_print_base_64_pair(uchar first, uchar second);
extern void debug_file_print_base_64_single(uchar first);

extern void write_debug_location(debug_location location);
extern void write_debug_locations(debug_locations locations);
extern void write_debug_optional_identifier(int32 symbol_index);
extern void write_debug_symbol_backpatch(int32 symbol_index);
extern void write_debug_symbol_optional_backpatch(int32 symbol_index);
extern void write_debug_object_backpatch(int32 object_number);
extern void write_debug_packed_code_backpatch(int32 offset);
extern void write_debug_code_backpatch(int32 offset);
extern void write_debug_global_backpatch(int32 offset);
extern void write_debug_array_backpatch(int32 offset);
extern void write_debug_grammar_backpatch(int32 offset);

extern void begin_writing_debug_sections(void);
extern void write_debug_section(const char*name, int32 beginning_address);
extern void end_writing_debug_sections(int32 end_address);

extern void write_debug_undef(int32 symbol_index);

extern void end_debug_file(void);

extern void add_to_checksum(void *address);

extern void load_sourcefile(char *story_name, int style);
extern int file_load_chars(int file_number, char *buffer, int length);
extern void close_all_source(void);

extern void output_file(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "inform"                                         */
/* ------------------------------------------------------------------------- */

extern char Code_Name[];
extern int endofpass_flag;

extern int version_number,  instruction_set_number, extend_memory_map;
extern int32 scale_factor,  length_scale_factor;

extern int WORDSIZE, INDIV_PROP_START, 
    OBJECT_BYTE_LENGTH, DICT_ENTRY_BYTE_LENGTH, DICT_ENTRY_FLAG_POS;
extern int32 MAXINTWORD;

extern int asm_trace_level, line_trace_level,     expr_trace_level,
    linker_trace_level,     tokens_trace_level;

extern int
    bothpasses_switch,      concise_switch,
    economy_switch,         frequencies_switch,
    ignore_switches_switch, listobjects_switch,   debugfile_switch,
    listing_switch,         memout_switch,        printprops_switch,
    offsets_switch,         percentages_switch,   obsolete_switch,
    transcript_switch,      statistics_switch,    optimise_switch,
    version_set_switch,     nowarnings_switch,    hash_switch,
    memory_map_switch,      module_switch,        temporary_files_switch,
    define_DEBUG_switch,    define_USE_MODULES_switch, define_INFIX_switch,
    runtime_error_checking_switch;

extern int oddeven_packing_switch;

extern int glulx_mode, compression_switch;
extern int32 requested_glulx_version;

extern int error_format,    store_the_text,       asm_trace_setting,
    double_space_setting,   trace_fns_setting,    character_set_setting,
    character_set_unicode;

extern char Debugging_Name[];
extern char Transcript_Name[];
extern char Language_Name[];
extern char Charset_Map[];

extern char banner_line[];

extern void select_version(int vn);
extern void switches(char *, int);
extern int translate_in_filename(int last_value, char *new_name, char *old_name,
    int same_directory_flag, int command_line_flag);
extern void translate_out_filename(char *new_name, char *old_name);
extern int translate_link_filename(int last_value,
    char *new_name, char *old_name);
extern void translate_temp_filename(int i);

#ifdef ARCHIMEDES
extern char *riscos_file_type(void);
#endif

/* For the benefit of the MAC_FACE port these are declared extern, though
   unused outside "inform" in the compiler itself */

extern void allocate_arrays(void);
extern void free_arrays(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "lexer"                                          */
/* ------------------------------------------------------------------------- */

extern int  hash_printed_since_newline;
extern int  total_source_line_count;
extern int  dont_enter_into_symbol_table;
extern int  return_sp_as_variable;
extern int  next_token_begins_syntax_line;
extern char **local_variable_texts;

extern int32 token_value;
extern int   token_type;
extern char *token_text;

extern debug_location get_token_location(void);
extern debug_locations get_token_locations(void);
extern debug_location_beginning get_token_location_beginning(void);
extern void discard_token_location(debug_location_beginning beginning);
extern debug_locations get_token_location_end(debug_location_beginning beginning);

extern void describe_token(token_data t);

extern void construct_local_variable_tables(void);
extern void declare_systemfile(void);
extern int  is_systemfile(void);
extern void report_errors_at_current_line(void);
extern debug_location get_current_debug_location(void);
extern debug_location get_error_report_debug_location(void);
extern int32 get_current_line_start(void);

extern void put_token_back(void);
extern void get_next_token(void);
extern void restart_lexer(char *lexical_source, char *name);

extern keyword_group directives, statements, segment_markers,
       conditions, system_functions, local_variables, opcode_names,
       misc_keywords, directive_keywords, trace_keywords, system_constants,
       opcode_macros;

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "linker"                                         */
/* ------------------------------------------------------------------------- */

extern memory_block link_data_area;
extern int32 link_data_size;
extern char  current_module_filename[];

extern char *describe_mv(int mval);
extern void  write_link_marker(int zmachine_area, int32 offset,
                 assembly_operand op);
extern void  flush_link_data(void);
extern void  import_symbol(int32 symbol_number);
extern void  export_symbol(int32 symbol_number);
extern void  export_symbol_name(int32 i);
extern void  link_module(char *filename);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "memory"                                         */
/* ------------------------------------------------------------------------- */

extern int32 malloced_bytes;

extern int MAX_QTEXT_SIZE,  MAX_SYMBOLS,    HASH_TAB_SIZE,   MAX_DICT_ENTRIES,
           MAX_OBJECTS,     MAX_ACTIONS,    MAX_ADJECTIVES,   MAX_ABBREVS,
           MAX_STATIC_DATA,      MAX_PROP_TABLE_SIZE,   SYMBOLS_CHUNK_SIZE,
           MAX_EXPRESSION_NODES, MAX_LABELS,            MAX_LINESPACE,
           MAX_LOW_STRINGS,      MAX_CLASSES,           MAX_VERBS,
           MAX_VERBSPACE,        MAX_ARRAYS,            MAX_INCLUSION_DEPTH,
           MAX_SOURCE_FILES;

extern int32 MAX_STATIC_STRINGS, MAX_ZCODE_SIZE, MAX_LINK_DATA_SIZE,
           MAX_TRANSCRIPT_SIZE,  MAX_INDIV_PROP_TABLE_SIZE,
           MAX_NUM_STATIC_STRINGS, MAX_UNICODE_CHARS,
           MAX_STACK_SIZE, MEMORY_MAP_EXTENSION;

extern int32 MAX_OBJ_PROP_COUNT, MAX_OBJ_PROP_TABLE_SIZE;
extern int MAX_LOCAL_VARIABLES, MAX_GLOBAL_VARIABLES;
extern int DICT_WORD_SIZE, DICT_CHAR_SIZE, DICT_WORD_BYTES;
extern int ZCODE_HEADER_EXT_WORDS, ZCODE_HEADER_FLAGS_3;
extern int NUM_ATTR_BYTES, GLULX_OBJECT_EXT_BYTES;
extern int WARN_UNUSED_ROUTINES, OMIT_UNUSED_ROUTINES;

/* These macros define offsets that depend on the value of NUM_ATTR_BYTES.
   (Meaningful only for Glulx.) */
/* GOBJFIELD: word offsets of various elements in the object structure. */
#define GOBJFIELD_CHAIN()    (1+((NUM_ATTR_BYTES)/4))
#define GOBJFIELD_NAME()     (2+((NUM_ATTR_BYTES)/4))
#define GOBJFIELD_PROPTAB()  (3+((NUM_ATTR_BYTES)/4))
#define GOBJFIELD_PARENT()   (4+((NUM_ATTR_BYTES)/4))
#define GOBJFIELD_SIBLING()  (5+((NUM_ATTR_BYTES)/4))
#define GOBJFIELD_CHILD()    (6+((NUM_ATTR_BYTES)/4))

extern void *my_malloc(int32 size, char *whatfor);
extern void my_realloc(void *pointer, int32 oldsize, int32 size, 
    char *whatfor);
extern void *my_calloc(int32 size, int32 howmany, char *whatfor);
extern void my_recalloc(void *pointer, int32 size, int32 oldhowmany, 
    int32 howmany, char *whatfor);
extern void my_free(void *pointer, char *whatitwas);

extern void set_memory_sizes(int size_flag);
extern void adjust_memory_sizes(void);
extern void memory_command(char *command);
extern void print_memory_usage(void);

extern void initialise_memory_block(memory_block *MB);
extern void deallocate_memory_block(memory_block *MB);
extern int  read_byte_from_memory_block(memory_block *MB, int32 index);
extern void write_byte_to_memory_block(memory_block *MB,
    int32 index, int value);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "objects"                                        */
/* ------------------------------------------------------------------------- */

extern int no_attributes, no_properties;
extern int no_individual_properties;
extern int individuals_length;
extern uchar *individuals_table;
extern int no_classes, no_objects;
extern objecttz *objectsz;
extern objecttg *objectsg;
extern uchar *objectatts;
extern int *class_object_numbers;
extern int32 *class_begins_at;

extern int32 *prop_default_value;
extern int *prop_is_long;
extern int *prop_is_additive;
extern char *properties_table;
extern int properties_table_size;

extern void make_attribute(void);
extern void make_property(void);
extern void make_object(int nearby_flag,
    char *textual_name, int specified_parent, int specified_class,
    int instance_of);
extern void make_class(char *metaclass_name);
extern int  object_provides(int obj, int id);
extern void list_object_tree(void);
extern void write_the_identifier_names(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "symbols"                                        */
/* ------------------------------------------------------------------------- */

extern int no_named_constants;
extern int no_symbols;
extern int32 **symbs;
extern int32 *svals;
extern int   *smarks;
extern int32 *slines;
extern int   *sflags;
#ifdef VAX
  extern char *stypes;
#else
  extern signed char *stypes;
#endif
extern maybe_file_position *symbol_debug_backpatch_positions;
extern maybe_file_position *replacement_debug_backpatch_positions;
extern int32 *individual_name_strings;
extern int32 *attribute_name_strings;
extern int32 *action_name_strings;
extern int32 *array_name_strings;
extern int track_unused_routines;
extern int df_dont_note_global_symbols;
extern uint32 df_total_size_before_stripping;
extern uint32 df_total_size_after_stripping;

extern char *typename(int type);
extern int hash_code_from_string(char *p);
extern int strcmpcis(char *p, char *q);
extern int symbol_index(char *lexeme_text, int hashcode);
extern void end_symbol_scope(int k);
extern void describe_symbol(int k);
extern void list_symbols(int level);
extern void assign_marked_symbol(int index, int marker, int32 value, int type);
extern void assign_symbol(int index, int32 value, int type);
extern void issue_unused_warnings(void);
extern void add_symbol_replacement_mapping(int original, int renamed);
extern int find_symbol_replacement(int *value);
extern void df_note_function_start(char *name, uint32 address, 
    int embedded_flag, int32 source_line);
extern void df_note_function_end(uint32 endaddress);
extern void df_note_function_symbol(int symbol);
extern void locate_dead_functions(void);
extern uint32 df_stripped_address_for_address(uint32);
extern uint32 df_stripped_offset_for_code_offset(uint32, int *);
extern void df_prepare_function_iterate(void);
extern uint32 df_next_function_iterate(int *);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "syntax"                                         */
/* ------------------------------------------------------------------------- */

extern int   no_syntax_lines;

extern void  panic_mode_error_recovery(void);
extern void  get_next_token_with_directives(void);
extern int   parse_directive(int internal_flag);
extern void  parse_program(char *source);
extern int32 parse_routine(char *source, int embedded_flag, char *name,
                 int veneer_flag, int r_symbol);
extern void  parse_code_block(int break_label, int continue_label,
                 int switch_rule);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "states"                                         */
/* ------------------------------------------------------------------------- */

extern void  match_close_bracket(void);
extern void  parse_statement(int break_label, int continue_label);
extern int   parse_label(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "tables"                                         */
/* ------------------------------------------------------------------------- */

extern uchar *zmachine_paged_memory;
extern int32
    code_offset,            actions_offset,       preactions_offset,
    dictionary_offset,      strings_offset,       adjectives_offset,
    variables_offset,       class_numbers_offset, individuals_offset,
   identifier_names_offset, prop_defaults_offset, prop_values_offset,
    static_memory_offset,   array_names_offset,   attribute_names_offset,
    action_names_offset,    fake_action_names_offset,
    routine_names_offset,   routines_array_offset, routine_flags_array_offset,
    global_names_offset,    global_flags_array_offset,
    array_flags_array_offset, constant_names_offset, constants_array_offset;
extern int32
    arrays_offset, object_tree_offset, grammar_table_offset,
    abbreviations_offset;    /* For Glulx */

extern int32 Out_Size,      Write_Code_At,        Write_Strings_At;
extern int32 RAM_Size,      Write_RAM_At;    /* For Glulx */

extern int release_number, statusline_flag;
extern int flags2_requirements[];
extern int serial_code_given_in_program;
extern char serial_code_buffer[];

extern void construct_storyfile(void);
extern void write_serial_number(char *buffer);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "text"                                           */
/* ------------------------------------------------------------------------- */

extern uchar *low_strings, *low_strings_top;
extern char  *all_text,    *all_text_top;

extern int   no_abbreviations;
extern int   abbrevs_lookup_table_made, is_abbreviation;
extern uchar *abbreviations_at;
extern int  *abbrev_values;
extern int  *abbrev_quality;
extern int  *abbrev_freqs;

extern int32 total_chars_trans, total_bytes_trans,
             zchars_trans_in_last_string;
extern int   put_strings_in_low_memory;
extern int   dict_entries;
extern uchar *dictionary, *dictionary_top;
extern int   *final_dict_order;

extern memory_block static_strings_area;
extern int32 static_strings_extent;

/* And now, a great many declarations for dealing with Glulx string
   compression. */

extern int32 no_strings, no_dynamic_strings;
extern int no_unicode_chars;

#define MAX_DYNAMIC_STRINGS (64)

typedef struct unicode_usage_s unicode_usage_t;
struct unicode_usage_s {
  int32 ch;
  unicode_usage_t *next;  
};

extern unicode_usage_t *unicode_usage_entries;

/* This is the maximum number of (8-bit) bytes that can encode a single
   Huffman entity. Four should be plenty, unless someone starts encoding
   an ideographic language. */
#define MAXHUFFBYTES (4)

typedef struct huffbitlist_struct {
  uchar b[MAXHUFFBYTES];
} huffbitlist_t;
typedef struct huffentity_struct {
  int count;
  int type;
  union {
    int branch[2];
    unsigned char ch;
    int val;
  } u;
  int depth;
  int32 addr;
  huffbitlist_t bits;
} huffentity_t;

extern huffentity_t *huff_entities;

extern int32 compression_table_size, compression_string_size;
extern int32 *compressed_offsets;
extern int no_huff_entities;
extern int huff_abbrev_start, huff_dynam_start, huff_unicode_start;
extern int huff_entity_root;

extern void  compress_game_text(void);

/* end of the Glulx string compression stuff */

extern void  ao_free_arrays(void);
extern int32 compile_string(char *b, int in_low_memory, int is_abbrev);
extern uchar *translate_text(uchar *p, uchar *p_limit, char *s_text);
extern void  optimise_abbreviations(void);
extern void  make_abbreviation(char *text);
extern void  show_dictionary(void);
extern void  word_to_ascii(uchar *p, char *result);
extern void  write_dictionary_to_transcript(void);
extern void  sort_dictionary(void);
extern void  dictionary_prepare(char *dword, uchar *optresult);
extern int   dictionary_add(char *dword, int x, int y, int z);
extern void  dictionary_set_verb_number(char *dword, int to);
extern int   compare_sorts(uchar *d1, uchar *d2);
extern void  copy_sorts(uchar *d1, uchar *d2);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "veneer"                                         */
/* ------------------------------------------------------------------------- */

extern int  veneer_mode;
extern int32 veneer_routine_address[];

extern void compile_initial_routine(void);
extern assembly_operand veneer_routine(int code);
extern void compile_veneer(void);

/* ------------------------------------------------------------------------- */
/*   Extern definitions for "verbs"                                          */
/* ------------------------------------------------------------------------- */

extern int no_adjectives, no_Inform_verbs, no_grammar_token_routines,
           no_fake_actions, no_actions, no_grammar_lines, no_grammar_tokens,
           grammar_version_number;
extern int32 grammar_version_symbol;
extern verbt *Inform_verbs;
extern uchar *grammar_lines;
extern int32 grammar_lines_top;
extern int32 *action_byte_offset,
             *grammar_token_routine,
             *adjectives;

extern void find_the_actions(void);
extern void make_fake_action(void);
extern assembly_operand action_of_name(char *name);
extern void make_verb(void);
extern void extend_verb(void);
extern void list_verb_table(void);

/* ========================================================================= */
