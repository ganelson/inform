#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "glk.h"
#include "gi_debug.h"
#include "cheapglk.h"
#include "glkstart.h"

int gli_screenwidth = 80;
int gli_screenheight = 24; 
int gli_utf8output = FALSE;
int gli_utf8input = FALSE;
#if GIDEBUG_LIBRARY_SUPPORT
int gli_debugger = FALSE;
#endif /* GIDEBUG_LIBRARY_SUPPORT */

typedef struct dataresource_struct {
    int num;
    int isbinary;
    char *pathname;
    int len;
    void *ptr;
} dataresource_t;
static dataresource_t *dataresources = NULL;
static int numdataresources = 0, dataresource_size = 0;

static int inittime = FALSE;

int main(int argc, char *argv[])
{
    int ix, jx, val;
    int display_version = TRUE;

    int errflag = FALSE;
    glkunix_startup_t startdata;
    
    /* Test for compile-time errors. If one of these spouts off, you
        must edit glk.h and recompile. */
    if (sizeof(glui32) != 4) {
        printf("Compile-time error: glui32 is not a 32-bit value. Please fix glk.h.\n");
        return 1;
    }
    if ((glui32)(-1) < 0) {
        printf("Compile-time error: glui32 is not unsigned. Please fix glk.h.\n");
        return 1;
    }
    
    /* Now some argument-parsing. This is probably going to hurt. */
    startdata.argc = 0;
    startdata.argv = (char **)malloc(argc * sizeof(char *));
    
    /* Copy in the program name. */
    startdata.argv[startdata.argc] = argv[0];
    startdata.argc++;
    
    for (ix=1; ix<argc && !errflag; ix++) {
        glkunix_argumentlist_t *argform;
        int inarglist = FALSE;
        char *cx;
        
        for (argform = glkunix_arguments; 
            argform->argtype != glkunix_arg_End && !errflag; 
            argform++) {
            
            if (argform->name[0] == '\0') {
                if (argv[ix][0] != '-') {
                    startdata.argv[startdata.argc] = argv[ix];
                    startdata.argc++;
                    inarglist = TRUE;
                }
            }
            else if ((argform->argtype == glkunix_arg_NumberValue)
                && !strncmp(argv[ix], argform->name, strlen(argform->name))
                && (cx = argv[ix] + strlen(argform->name))
                && (atoi(cx) != 0 || cx[0] == '0')) {
                startdata.argv[startdata.argc] = argv[ix];
                startdata.argc++;
                inarglist = TRUE;
            }
            else if (!strcmp(argv[ix], argform->name)) {
                int numeat = 0;
                
                if (argform->argtype == glkunix_arg_ValueFollows) {
                    if (ix+1 >= argc) {
                        printf("%s: %s must be followed by a value\n\n", 
                            argv[0], argform->name);
                        errflag = TRUE;
                        break;
                    }
                    numeat = 2;
                }
                else if (argform->argtype == glkunix_arg_NoValue) {
                    numeat = 1;
                }
                else if (argform->argtype == glkunix_arg_ValueCanFollow) {
                    if (ix+1 < argc && argv[ix+1][0] != '-') {
                        numeat = 2;
                    }
                    else {
                        numeat = 1;
                    }
                }
                else if (argform->argtype == glkunix_arg_NumberValue) {
                    if (ix+1 >= argc
                        || (atoi(argv[ix+1]) == 0 && argv[ix+1][0] != '0')) {
                        printf("%s: %s must be followed by a number\n\n", 
                            argv[0], argform->name);
                        errflag = TRUE;
                        break;
                    }
                    numeat = 2;
                }
                else {
                    errflag = TRUE;
                    break;
                }
                
                for (jx=0; jx<numeat; jx++) {
                    startdata.argv[startdata.argc] = argv[ix];
                    startdata.argc++;
                    if (jx+1 < numeat)
                        ix++;
                }
                inarglist = TRUE;
                break;
            }
        }
        if (inarglist || errflag)
            continue;
            
        if (argv[ix][0] == '-') {
            if (!strcmp(argv[ix]+1, "dataresource")
                || !strcmp(argv[ix]+1, "dataresourcebin")
                || !strcmp(argv[ix]+1, "dataresourcetext")) {
                int isbinary = strcmp(argv[ix]+1, "dataresourcetext") != 0;
                ix++;
                if (ix >= argc) {
                    printf("%s: -dataresource option requires NUM:PATHNAME\n\n", argv[0]);
                    errflag = TRUE;
                    continue;
                }
                char *sep = strchr(argv[ix], ':');
                if (!sep || sep == argv[ix] || *(sep+1) == '\0') {
                    printf("%s: -dataresource option requires NUM:PATHNAME\n\n", argv[0]);
                    errflag = TRUE;
                    continue;
                }
                *sep = '\0';
                sep++;
                val = atoi(argv[ix]);
                if (!dataresources || dataresource_size == 0) {
                    dataresource_size = 4;
                    dataresources = (dataresource_t *)malloc(dataresource_size * sizeof(dataresource_t));
                }
                else if (numdataresources >= dataresource_size) {
                    dataresource_size *= 2;
                    dataresources = (dataresource_t *)realloc(dataresources, dataresource_size * sizeof(dataresource_t));
                }
                dataresources[numdataresources].num = val;
                dataresources[numdataresources].isbinary = isbinary;
                dataresources[numdataresources].pathname = strdup(sep);
                dataresources[numdataresources].ptr = NULL;
                dataresources[numdataresources].len = 0;
                numdataresources++;
                continue;
            }
            switch (argv[ix][1]) {
                case 'w':
                    val = 0;
                    if (argv[ix][2]) 
                        val = atoi(argv[ix]+2);
                    else {
                        ix++;
                        if (ix<argc) 
                            val = atoi(argv[ix]);
                    }
                    if (val < 8)
                        errflag = TRUE;
                    else
                        gli_screenwidth = val;
                    break;
                case 'h':
                    val = 0;
                    if (argv[ix][2]) 
                        val = atoi(argv[ix]+2);
                    else {
                        ix++;
                        if (ix<argc) 
                            val = atoi(argv[ix]);
                    }
                    if (val < 2)
                        errflag = TRUE;
                    else
                        gli_screenheight = val;
                    break;
                case 'u':
                    if (argv[ix][2]) {
                        if (argv[ix][2] == 'i') 
                            gli_utf8input = TRUE;
                        else if (argv[ix][2] == 'o')
                            gli_utf8output = TRUE;
                        else
                            errflag = TRUE;
                    }
                    else {
                        gli_utf8output = TRUE;
                        gli_utf8input = TRUE;
                    }
                    break;
                case 'q':
                    display_version = FALSE;
                    break;
#if GIDEBUG_LIBRARY_SUPPORT
                case 'D':
                    gli_debugger = TRUE;
                    break;
#endif /* GIDEBUG_LIBRARY_SUPPORT */
                default:
                    printf("%s: unknown option: %s\n\n", argv[0], argv[ix]);
                    errflag = TRUE;
                    break;
            }
        }
    }

    if (errflag) {
#if GIDEBUG_LIBRARY_SUPPORT
        char *debugoption = " -D";
#else  /* GIDEBUG_LIBRARY_SUPPORT */
        char *debugoption = "";
#endif /* GIDEBUG_LIBRARY_SUPPORT */
        printf("usage: %s -w WIDTH -h HEIGHT -u[i|o] -q%s\n", argv[0], debugoption);
        if (glkunix_arguments[0].argtype != glkunix_arg_End) {
            glkunix_argumentlist_t *argform;
            printf("game options:\n");
            for (argform = glkunix_arguments; 
                argform->argtype != glkunix_arg_End;
                argform++) {
                if (strlen(argform->name) == 0)
                    printf("  %s\n", argform->desc);
                else if (argform->argtype == glkunix_arg_ValueFollows)
                    printf("  %s val: %s\n", argform->name, argform->desc);
                else if (argform->argtype == glkunix_arg_NumberValue)
                    printf("  %s val: %s\n", argform->name, argform->desc);
                else if (argform->argtype == glkunix_arg_ValueCanFollow)
                    printf("  %s [val]: %s\n", argform->name, argform->desc);
                else
                    printf("  %s: %s\n", argform->name, argform->desc);
            }
        }
        printf("library options:\n");
        printf("  -w NUM, -h NUM: pretend to be running in a terminal window of this size (default 80x24)\n");
        printf("  -u: assume input and output are UTF-8 encoded (default: Latin-1)\n");
        printf("  -ui, -uo: set UTF-8 mode for input and output separately\n");
        printf("  -dataresource NUM:PATHNAME, -dataresourcebin NUM:PATHNAME, -dataresourcetext NUM:PATHNAME: tell where the data resource file with the given number can be read (default: search blorb if available)\n");
        printf("     (file is considered binary by default, or text if -dataresourcetext is used)\n");
        printf("  -q: don't display the \"Welcome to the Cheap Glk Implementation\" header line\n");
#if GIDEBUG_LIBRARY_SUPPORT
        printf("  -D: turn on debug console\n");
#endif /* GIDEBUG_LIBRARY_SUPPORT */
        printf("  -help: display this list\n");
        return 1;
    }
    
    /* Initialize things. */
    gli_initialize_misc();
    
    inittime = TRUE;
    if (!glkunix_startup_code(&startdata)) {
        glk_exit();
    }
    inittime = FALSE;

    if (display_version) {
        char *debugoption = "";
#if GIDEBUG_LIBRARY_SUPPORT
        if (gli_debugger)
            debugoption = " Debug support is on.";
#endif /* GIDEBUG_LIBRARY_SUPPORT */
        printf("Welcome to the Cheap Glk Implementation, library version %s.%s\n\n", 
            LIBRARY_VERSION, debugoption);
    }

    if (gli_debugger)
        gidebug_announce_cycle(gidebug_cycle_Start);

    glk_main();
    glk_exit();
    
    /* glk_exit() doesn't return, but the compiler may kvetch if main()
        doesn't seem to return a value. */
    return 0;
}

/* Get the data for data chunk num (as specified in command-line arguments,
   if any).
   The data is read from the given pathname and stashed in memory.
   This is memory-hoggish, but so is the rest of glk_stream_open_resource();
   see comments there.
   (You might wonder why we don't call gli_stream_open_pathname() and
   handle the file as a file-based stream. Turns out that doesn't work;
   the handling of unicode streams is subtly different for resource
   streams and the file-based code won't work. Oh well.)
*/
int gli_get_dataresource_info(int num, void **ptr, glui32 *len, int *isbinary)
{
    int ix;
    /* The dataresources array isn't sorted (or even checked for duplicates),
       so we search it linearly. There probably aren't a lot of entries. */
    for (ix=0; ix<numdataresources; ix++) {
        if (dataresources[ix].num == num) {
            *isbinary = dataresources[ix].isbinary;
            *ptr = NULL;
            *len = 0;
            if (dataresources[ix].ptr) {
                /* Already loaded. */
            }
            else {
                FILE *fl = fopen(dataresources[ix].pathname, "rb");
                if (!fl) {
                    gli_strict_warning("stream_open_resource: unable to read given pathname.");
                    return FALSE;
                }
                fseek(fl, 0, SEEK_END);
                dataresources[ix].len = ftell(fl);
                dataresources[ix].ptr = malloc(dataresources[ix].len+1);
                fseek(fl, 0, SEEK_SET);
                int got = fread(dataresources[ix].ptr, 1, dataresources[ix].len, fl);
                fclose(fl);
                if (got != dataresources[ix].len) {
                    gli_strict_warning("stream_open_resource: unable to read all resource data.");
                    return FALSE;
                }
            }
            *ptr = dataresources[ix].ptr;
            *len = dataresources[ix].len;
            return TRUE;
        }
    }

    return FALSE;
}

/* This opens a file for reading or writing. (You cannot open a file
   for appending using this call.)

   This should be used only by glkunix_startup_code(). 
*/
strid_t glkunix_stream_open_pathname_gen(char *pathname, glui32 writemode,
    glui32 textmode, glui32 rock)
{
    if (!inittime)
        return 0;
    return gli_stream_open_pathname(pathname, (writemode != 0), (textmode != 0), rock);
}

/* This opens a file for reading. It is a less-general form of 
   glkunix_stream_open_pathname_gen(), preserved for backwards 
   compatibility.

   This should be used only by glkunix_startup_code().
*/
strid_t glkunix_stream_open_pathname(char *pathname, glui32 textmode, 
    glui32 rock)
{
    if (!inittime)
        return 0;
    return gli_stream_open_pathname(pathname, FALSE, (textmode != 0), rock);
}
