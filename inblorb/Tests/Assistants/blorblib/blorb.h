#ifndef BLORB_H
#define BLORB_H

/* blorb.h: Header file for Blorb library, version 1.0.2.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/blorb/index.html
    
    This is the header that a Z-machine interpreter should include.
    It defines everything that the interpreter has to know.
*/

/* Things you (the porter) have to edit: */

/* As you might expect, uint32 must be a 32-bit unsigned numeric type,
    and uint16 a 16-bit unsigned numeric type. You should also uncomment
    exactly one of the two ENDIAN definitions. */
    
/* #define BLORB_BIG_ENDIAN */
#define BLORB_LITTLE_ENDIAN
typedef unsigned long uint32;
typedef unsigned short uint16;

/* End of things you have to edit. */

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

/* Error type and error codes */
typedef int bb_err_t;

#define bb_err_None (0)
#define bb_err_CompileTime (1)
#define bb_err_Alloc (2)
#define bb_err_Read (3)
#define bb_err_NotAMap (4)
#define bb_err_Format (5)
#define bb_err_NotFound (6)

/* Methods for loading a chunk */
#define bb_method_DontLoad (0)
#define bb_method_Memory (1)
#define bb_method_FilePos (2)

/* Four-byte constants */

#define bb_make_id(c1, c2, c3, c4)  \
    (((c1) << 24) | ((c2) << 16) | ((c3) << 8) | (c4))

#define bb_ID_Snd       (bb_make_id('S', 'n', 'd', ' '))
#define bb_ID_Exec      (bb_make_id('E', 'x', 'e', 'c'))
#define bb_ID_Pict      (bb_make_id('P', 'i', 'c', 't'))
#define bb_ID_Copyright (bb_make_id('(', 'c', ')', ' '))
#define bb_ID_AUTH      (bb_make_id('A', 'U', 'T', 'H'))
#define bb_ID_ANNO      (bb_make_id('A', 'N', 'N', 'O'))

/* bb_result_t: Result when you try to load a chunk. */
typedef struct bb_result_struct {
    int chunknum; /* The chunk number (for use in bb_unload_chunk(), etc.) */
    union {
        void *ptr; /* A pointer to the data (if you used bb_method_Memory) */
        uint32 startpos; /* The position in the file (if you used bb_method_FilePos) */
    } data;
    uint32 length; /* The length of the data */
} bb_result_t;

/* bb_aux_sound_t: Extra data which may be associated with a sound. */
typedef struct bb_aux_sound_struct {
    char repeats;
} bb_aux_sound_t;

/* bb_aux_pict_t: Extra data which may be associated with an image. */
typedef struct bb_aux_pict_struct {
    uint32 ratnum, ratden;
    uint32 minnum, minden;
    uint32 maxnum, maxden;
} bb_aux_pict_t;

/* bb_resolution_t: The global resolution data. */
typedef struct bb_resolution_struct {
    uint32 px, py;
    uint32 minx, miny;
    uint32 maxx, maxy;
} bb_resolution_t;

/* bb_color_t: Guess what. */
typedef struct bb_color_struct {
    unsigned char red, green, blue;
} bb_color_t;

/* bb_palette_t: The palette data. */
typedef struct bb_palette_struct {
    int isdirect; 
    union {
        int depth; /* The depth (if isdirect is TRUE). Either 16 or 32. */
        struct {
            int numcolors;
            bb_color_t *colors;
        } table; /* The list of colors (if isdirect is FALSE). */
    } data;
} bb_palette_t;

/* bb_zheader_t: Information to identify a Z-code file. */
typedef struct bb_zheader_struct {
    uint16 releasenum; /* Bytes $2-3 of header. */
    char serialnum[6]; /* Bytes $12-17 of header. */
    uint16 checksum; /* Bytes $1C-1D of header. */
    /* The initpc field is not used by Blorb. */
} bb_zheader_t;

/* bb_map_t: Holds the complete description of an open Blorb file. 
    This type is opaque for normal interpreter use. */
typedef struct bb_map_struct bb_map_t;

/* Function declarations. These functions are of fairly general use;
    they would apply to any Blorb file. */

extern bb_err_t bb_create_map(FILE *file, bb_map_t **newmap);
extern bb_err_t bb_destroy_map(bb_map_t *map);

extern char *bb_err_to_string(bb_err_t err);

extern bb_err_t bb_load_chunk_by_type(bb_map_t *map, int method, 
    bb_result_t *res, uint32 chunktype, int count);
extern bb_err_t bb_load_chunk_by_number(bb_map_t *map, int method, 
    bb_result_t *res, int chunknum);
extern bb_err_t bb_unload_chunk(bb_map_t *map, int chunknum);

extern bb_err_t bb_load_resource(bb_map_t *map, int method, 
    bb_result_t *res, uint32 usage, int resnum);
extern bb_err_t bb_count_resources(bb_map_t *map, uint32 usage,
    int *num, int *min, int *max);

/* More function declarations. These functions are more or less
    specific to the Z-machine's use of Blorb. */

extern uint16 bb_get_release_num(bb_map_t *map);
extern bb_zheader_t *bb_get_zheader(bb_map_t *map);
extern bb_resolution_t *bb_get_resolution(bb_map_t *map);
extern bb_err_t bb_get_palette(bb_map_t *map, bb_palette_t **res);
extern bb_err_t bb_load_resource_pict(bb_map_t *map, int method, 
    bb_result_t *res, int resnum, bb_aux_pict_t **auxdata);
extern bb_err_t bb_load_resource_snd(bb_map_t *map, int method, 
    bb_result_t *res, int resnum, bb_aux_sound_t **auxdata);

#endif /* BLORB_H */
