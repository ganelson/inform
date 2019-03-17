#ifndef _GI_DISPA_H
#define _GI_DISPA_H

/* gi_dispa.h: Header file for dispatch layer of Glk API, version 0.7.5.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glk/index.html

    This file is copyright 1998-2017 by Andrew Plotkin. It is
    distributed under the MIT license; see the "LICENSE" file.
*/

/* These constants define the classes of opaque objects. It's a bit ugly
    to put them in this header file, since more classes may be added in
    the future. But if you find yourself stuck with an obsolete version
    of this file, adding new class definitions will be easy enough -- 
    they will be numbered sequentially, and the numeric constants can be 
    found in the Glk specification. */
#define gidisp_Class_Window (0)
#define gidisp_Class_Stream (1)
#define gidisp_Class_Fileref (2)
#define gidisp_Class_Schannel (3)

typedef union gluniversal_union {
    glui32 uint; /* Iu */
    glsi32 sint; /* Is */
    void *opaqueref; /* Qa, Qb, Qc... */
    unsigned char uch; /* Cu */
    signed char sch; /* Cs */
    char ch; /* Cn */
    char *charstr; /* S */
    glui32 *unicharstr; /* U */
    void *array; /* all # arguments */
    glui32 ptrflag; /* [ ... ] or *? */
} gluniversal_t;

/* Some well-known structures:
    event_t : [4IuQaIuIu]
    stream_result_t : [2IuIu] 
*/

typedef struct gidispatch_function_struct {
    glui32 id;
    void *fnptr;
    char *name;
} gidispatch_function_t;

typedef struct gidispatch_intconst_struct {
    char *name;
    glui32 val;
} gidispatch_intconst_t;

typedef union glk_objrock_union {
    glui32 num;
    void *ptr;
} gidispatch_rock_t;

/* The following functions are part of the Glk library itself, not the dispatch
    layer (whose code is in gi_dispa.c). These functions are necessarily
    implemented in platform-dependent code. 
*/
extern void gidispatch_set_object_registry(
    gidispatch_rock_t (*regi)(void *obj, glui32 objclass), 
    void (*unregi)(void *obj, glui32 objclass, gidispatch_rock_t objrock));
extern gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass);
extern void gidispatch_set_retained_registry(
    gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode), 
    void (*unregi)(void *array, glui32 len, char *typecode, 
        gidispatch_rock_t objrock));

/* This function is also part of the Glk library, but it only exists
    on libraries that support autorestore. (Only iosglk, currently.)
    Only call this if GIDISPATCH_AUTORESTORE_REGISTRY is defined.
*/
#define GIDISPATCH_AUTORESTORE_REGISTRY
extern void gidispatch_set_autorestore_registry(
    long (*locatearr)(void *array, glui32 len, char *typecode,
        gidispatch_rock_t objrock, int *elemsizeref),
    gidispatch_rock_t (*restorearr)(long bufkey, glui32 len,
        char *typecode, void **arrayref));

/* The following functions make up the Glk dispatch layer. Although they are
    distributed as part of each Glk library (linked into the library file),
    their code is in gi_dispa.c, which is platform-independent and identical
    in every Glk library. 
*/
extern void gidispatch_call(glui32 funcnum, glui32 numargs, 
    gluniversal_t *arglist);
extern char *gidispatch_prototype(glui32 funcnum);
extern glui32 gidispatch_count_classes(void);
extern gidispatch_intconst_t *gidispatch_get_class(glui32 index);
extern glui32 gidispatch_count_intconst(void);
extern gidispatch_intconst_t *gidispatch_get_intconst(glui32 index);
extern glui32 gidispatch_count_functions(void);
extern gidispatch_function_t *gidispatch_get_function(glui32 index);
extern gidispatch_function_t *gidispatch_get_function_by_id(glui32 id);

#define GI_DISPA_GAME_ID_AVAILABLE
/* These function is not part of Glk dispatching per se; they allow the
   game to provide an identifier string for the Glk library to use.
   The functions themselves are in gi_dispa.c.

   The game should test ifdef GI_DISPA_GAME_ID_AVAILABLE to ensure that
   these functions exist. (They are a late addition to gi_dispa.c, so
   older Glk library distributions will lack them.)
*/
#ifdef GI_DISPA_GAME_ID_AVAILABLE
extern void gidispatch_set_game_id_hook(char *(*hook)(void));
extern char *gidispatch_get_game_id(void);
#endif /* GI_DISPA_GAME_ID_AVAILABLE */

#endif /* _GI_DISPA_H */
