#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> /* for unlink() */
#include <sys/stat.h> /* for stat() */
#include "glk.h"
#include "cheapglk.h"

/* This file implements filerefs as they work in a stdio system: a
    fileref contains a pathname, a text/binary flag, and a file
    type.
*/

/* Linked list of all filerefs */
static fileref_t *gli_filereflist = NULL; 

#define BUFLEN (256)
static char workingdir[BUFLEN] = ".";

fileref_t *gli_new_fileref(char *filename, glui32 usage, glui32 rock)
{
    fileref_t *fref = (fileref_t *)malloc(sizeof(fileref_t));
    if (!fref)
        return NULL;
    
    fref->magicnum = MAGIC_FILEREF_NUM;
    fref->rock = rock;
    
    fref->filename = malloc(1 + strlen(filename));
    strcpy(fref->filename, filename);
    
    fref->textmode = ((usage & fileusage_TextMode) != 0);
    fref->filetype = (usage & fileusage_TypeMask);
    
    fref->prev = NULL;
    fref->next = gli_filereflist;
    gli_filereflist = fref;
    if (fref->next) {
        fref->next->prev = fref;
    }
    
    if (gli_register_obj)
        fref->disprock = (*gli_register_obj)(fref, gidisp_Class_Fileref);
    else
        fref->disprock.ptr = NULL;

    return fref;
}

void gli_delete_fileref(fileref_t *fref)
{
    fileref_t *prev, *next;
    
    if (gli_unregister_obj) {
        (*gli_unregister_obj)(fref, gidisp_Class_Fileref, fref->disprock);
        fref->disprock.ptr = NULL;
    }
        
    fref->magicnum = 0;
    
    if (fref->filename) {
        free(fref->filename);
        fref->filename = NULL;
    }
    
    prev = fref->prev;
    next = fref->next;
    fref->prev = NULL;
    fref->next = NULL;

    if (prev)
        prev->next = next;
    else
        gli_filereflist = next;
    if (next)
        next->prev = prev;
    
    free(fref);
}

void glk_fileref_destroy(fileref_t *fref)
{
    if (!fref) {
        gli_strict_warning("fileref_destroy: invalid ref");
        return;
    }
    gli_delete_fileref(fref);
}

static char *gli_suffix_for_usage(glui32 usage)
{
    switch (usage & fileusage_TypeMask) {
        case fileusage_Data:
            return ".glkdata";
        case fileusage_SavedGame:
            return ".glksave";
        case fileusage_Transcript:
        case fileusage_InputRecord:
            return ".txt";
        default:
            return "";
    }
}

frefid_t glk_fileref_create_temp(glui32 usage, glui32 rock)
{
    char filename[BUFLEN];
    fileref_t *fref;
    
    sprintf(filename, "/tmp/glktempfref-XXXXXX");
    mktemp(filename);
    
    fref = gli_new_fileref(filename, usage, rock);
    if (!fref) {
        gli_strict_warning("fileref_create_temp: unable to create fileref.");
        return NULL;
    }
    
    return fref;
}

frefid_t glk_fileref_create_from_fileref(glui32 usage, frefid_t oldfref,
    glui32 rock)
{
    fileref_t *fref; 

    if (!oldfref) {
        gli_strict_warning("fileref_create_from_fileref: invalid ref");
        return NULL;
    }

    fref = gli_new_fileref(oldfref->filename, usage, rock);
    if (!fref) {
        gli_strict_warning("fileref_create_from_fileref: unable to create fileref.");
        return NULL;
    }
    
    return fref;
}

frefid_t glk_fileref_create_by_name(glui32 usage, char *name,
    glui32 rock)
{
    fileref_t *fref;
    char buf[BUFLEN];
    char buf2[2*BUFLEN+10];
    int len;
    char *cx;
    char *suffix;
    
    /* The new spec recommendations: delete all characters in the
       string "/\<>:|?*" (including quotes). Truncate at the first
       period. Change to "null" if there's nothing left. Then append
       an appropriate suffix: ".glkdata", ".glksave", ".txt".
    */
    
    for (cx=name, len=0; (*cx && *cx!='.' && len<BUFLEN-1); cx++) {
        switch (*cx) {
            case '"':
            case '\\':
            case '/':
            case '>':
            case '<':
            case ':':
            case '|':
            case '?':
            case '*':
                break;
            default:
                buf[len++] = *cx;
        }
    }
    buf[len] = '\0';

    if (len == 0) {
        strcpy(buf, "null");
        len = strlen(buf);
    }
    
    suffix = gli_suffix_for_usage(usage);
    sprintf(buf2, "%s/%s%s", workingdir, buf, suffix);

    fref = gli_new_fileref(buf2, usage, rock);
    if (!fref) {
        gli_strict_warning("fileref_create_by_name: unable to create fileref.");
        return NULL;
    }
    
    return fref;
}

frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode,
    glui32 rock)
{
    fileref_t *fref;
    char buf[BUFLEN];
    char newbuf[2*BUFLEN+10];
    char *res;
    char *cx;
    int val, gotdot;
    char *prompt, *prompt2;
    
    switch (usage & fileusage_TypeMask) {
        case fileusage_SavedGame:
            prompt = "Enter saved game";
            break;
        case fileusage_Transcript:
            prompt = "Enter transcript file";
            break;
        case fileusage_InputRecord:
            prompt = "Enter command record file";
            break;
        case fileusage_Data:
        default:
            prompt = "Enter data file";
            break;
    }
    
    if (fmode == filemode_Read)
        prompt2 = "to load";
    else
        prompt2 = "to store";
    
    printf("%s %s: ", prompt, prompt2);
    
    res = fgets(buf, BUFLEN-1, stdin);
    if (!res) {
        printf("\n<end of input>\n");
        glk_exit();
    }

    /* Trim whitespace from end and beginning. */

    val = strlen(buf);
    while (val 
        && (buf[val-1] == '\n' 
            || buf[val-1] == '\r' 
            || buf[val-1] == ' '))
        val--;
    buf[val] = '\0';
    
    for (cx = buf; *cx == ' '; cx++) { }
    
    val = strlen(cx);
    if (!val) {
        /* The player just hit return. It would be nice to provide a
            default value, but this implementation is too cheap. */
        return NULL;
    }

    if (cx[0] == '/')
        strcpy(newbuf, cx);
    else
        sprintf(newbuf, "%s/%s", workingdir, cx);

    /* If there is no dot-suffix, add a standard one. */
    val = strlen(newbuf);
    gotdot = FALSE;
    while (val && (buf[val-1] != '/')) {
        if (buf[val-1] == '.') {
            gotdot = TRUE;
            break;
        }
        val--;
    }
    if (!gotdot) {
        char *suffix = gli_suffix_for_usage(usage);
        strcat(newbuf, suffix);
    }
    
    fref = gli_new_fileref(newbuf, usage, rock);
    if (!fref) {
        gli_strict_warning("fileref_create_by_prompt: unable to create fileref.");
        return NULL;
    }
    
    return fref;
}

frefid_t glk_fileref_iterate(fileref_t *fref, glui32 *rock)
{
    if (!fref) {
        fref = gli_filereflist;
    }
    else {
        fref = fref->next;
    }
    
    if (fref) {
        if (rock)
            *rock = fref->rock;
        return fref;
    }
    
    if (rock)
        *rock = 0;
    return NULL;
}

glui32 glk_fileref_get_rock(fileref_t *fref)
{
    if (!fref) {
        gli_strict_warning("fileref_get_rock: invalid ref.");
        return 0;
    }
    
    return fref->rock;
}

glui32 glk_fileref_does_file_exist(fileref_t *fref)
{
    struct stat buf;
    
    if (!fref) {
        gli_strict_warning("fileref_does_file_exist: invalid ref");
        return FALSE;
    }
    
    /* This is sort of Unix-specific, but probably any stdio library
        will implement at least this much of stat(). */
    
    if (stat(fref->filename, &buf))
        return 0;
    
    if (S_ISREG(buf.st_mode))
        return 1;
    else
        return 0;
}

void glk_fileref_delete_file(fileref_t *fref)
{
    if (!fref) {
        gli_strict_warning("fileref_delete_file: invalid ref");
        return;
    }
    
    /* If you don't have the unlink() function, obviously, change it
        to whatever file-deletion function you do have. */
        
    unlink(fref->filename);
}

/* This should only be called from startup code. */
void glkunix_set_base_file(char *filename)
{
    int ix;
  
    for (ix=strlen(filename)-1; ix >= 0; ix--) 
        if (filename[ix] == '/')
            break;

    if (ix >= 0) {
        /* There is a slash. */
        strncpy(workingdir, filename, ix);
        workingdir[ix] = '\0';
        ix++;
    }
    else {
        /* No slash, just a filename. */
        ix = 0;
    }
}

