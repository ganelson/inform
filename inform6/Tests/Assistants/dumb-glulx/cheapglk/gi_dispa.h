#ifndef _GI_DISPA_H
#define _GI_DISPA_H

/* gi_dispa.h: Header file for dispatch layer of Glk API, version 0.7.0.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/glk/index.html

    This file is copyright 1998-2004 by Andrew Plotkin. You may copy,
    distribute, and incorporate it into your own programs, by any means
    and under any conditions, as long as you do not modify it. You may
    also modify this file, incorporate it into your own programs,
    and distribute the modified version, as long as you retain a notice
    in your program or documentation which mentions my name and the URL
    shown above.
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

#endif /* _GI_DISPA_H */
