/* glkstart.h: Unix-specific header file for GlkTerm, CheapGlk, and XGlk
        (Unix implementations of the Glk API).
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/glk/index.html
*/

/* This header defines an interface that must be used by program linked
    with the various Unix Glk libraries -- at least, the three I wrote.
    (I encourage anyone writing a Unix Glk library to use this interface,
    but it's not part of the Glk spec.)
    
    Because Glk is *almost* perfectly portable, this interface *almost*
    doesn't have to exist. In practice, it's small.
*/

#ifndef GT_START_H
#define GT_START_H

/* We define our own TRUE and FALSE and NULL, because ANSI
    is a strange world. */
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

#define glkunix_arg_End (0)
#define glkunix_arg_ValueFollows (1)
#define glkunix_arg_NoValue (2)
#define glkunix_arg_ValueCanFollow (3)
#define glkunix_arg_NumberValue (4)

typedef struct glkunix_argumentlist_struct {
    char *name;
    int argtype;
    char *desc;
} glkunix_argumentlist_t;

typedef struct glkunix_startup_struct {
    int argc;
    char **argv;
} glkunix_startup_t;

extern glkunix_argumentlist_t glkunix_arguments[];

extern int glkunix_startup_code(glkunix_startup_t *data);

extern void glkunix_set_base_file(char *filename);
extern strid_t glkunix_stream_open_pathname_gen(char *pathname, 
    glui32 writemode, glui32 textmode, glui32 rock);
extern strid_t glkunix_stream_open_pathname(char *pathname, glui32 textmode, 
    glui32 rock);

#endif /* GT_START_H */

