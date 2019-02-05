#ifndef _GI_BLORB_H
#define _GI_BLORB_H

/* gi_blorb.h: Blorb library layer for Glk API.
    gi_blorb version 1.4.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/glk/index.html

    This file is copyright 1998-2000 by Andrew Plotkin. You may copy,
    distribute, and incorporate it into your own programs, by any means
    and under any conditions, as long as you do not modify it. You may
    also modify this file, incorporate it into your own programs,
    and distribute the modified version, as long as you retain a notice
    in your program or documentation which mentions my name and the URL
    shown above.
*/

/* Error type and error codes */
typedef glui32 giblorb_err_t;
#define giblorb_err_None (0)
#define giblorb_err_CompileTime (1)
#define giblorb_err_Alloc (2)
#define giblorb_err_Read (3)
#define giblorb_err_NotAMap (4)
#define giblorb_err_Format (5)
#define giblorb_err_NotFound (6)

/* Methods for loading a chunk */
#define giblorb_method_DontLoad (0)
#define giblorb_method_Memory (1)
#define giblorb_method_FilePos (2)

/* Four-byte constants */

#define giblorb_make_id(c1, c2, c3, c4)  \
    (((c1) << 24) | ((c2) << 16) | ((c3) << 8) | (c4))

#define giblorb_ID_Snd       (giblorb_make_id('S', 'n', 'd', ' '))
#define giblorb_ID_Exec      (giblorb_make_id('E', 'x', 'e', 'c'))
#define giblorb_ID_Pict      (giblorb_make_id('P', 'i', 'c', 't'))
#define giblorb_ID_Copyright (giblorb_make_id('(', 'c', ')', ' '))
#define giblorb_ID_AUTH      (giblorb_make_id('A', 'U', 'T', 'H'))
#define giblorb_ID_ANNO      (giblorb_make_id('A', 'N', 'N', 'O'))

/* giblorb_map_t: Holds the complete description of an open Blorb 
    file. This type is opaque for normal interpreter use. */
typedef struct giblorb_map_struct giblorb_map_t;

/* giblorb_result_t: Result when you try to load a chunk. */
typedef struct giblorb_result_struct {
    glui32 chunknum; /* The chunk number (for use in 
        giblorb_unload_chunk(), etc.) */
    union {
        void *ptr; /* A pointer to the data (if you used 
            giblorb_method_Memory) */
        glui32 startpos; /* The position in the file (if you 
            used giblorb_method_FilePos) */
    } data;
    glui32 length; /* The length of the data */
    glui32 chunktype; /* The type of the chunk. */
} giblorb_result_t;

extern giblorb_err_t giblorb_create_map(strid_t file, 
    giblorb_map_t **newmap);
extern giblorb_err_t giblorb_destroy_map(giblorb_map_t *map);

extern giblorb_err_t giblorb_load_chunk_by_type(giblorb_map_t *map, 
    glui32 method, giblorb_result_t *res, glui32 chunktype, 
    glui32 count);
extern giblorb_err_t giblorb_load_chunk_by_number(giblorb_map_t *map, 
    glui32 method, giblorb_result_t *res, glui32 chunknum);
extern giblorb_err_t giblorb_unload_chunk(giblorb_map_t *map, 
    glui32 chunknum);

extern giblorb_err_t giblorb_load_resource(giblorb_map_t *map, 
    glui32 method, giblorb_result_t *res, glui32 usage, 
    glui32 resnum);
extern giblorb_err_t giblorb_count_resources(giblorb_map_t *map, 
    glui32 usage, glui32 *num, glui32 *min, glui32 *max);

/* The following functions are part of the Glk library itself, not 
    the Blorb layer (whose code is in gi_blorb.c). These functions 
    are necessarily implemented in platform-dependent code. 
*/
extern giblorb_err_t giblorb_set_resource_map(strid_t file);
extern giblorb_map_t *giblorb_get_resource_map(void);

#endif /* _GI_BLORB_H */
