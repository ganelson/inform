#ifndef BLORBLOW_H
#define BLORBLOW_H

/* blorblow.h: Low-level header file for Blorb library, version 1.0.2.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/blorb/index.html
    
    This header is generally of interest only to the Blorb library code
    itself (blorblib.c); it defines things internal to the library. 
    An interpreter shouldn't have to include this file. The only time you
    might need to include this is if you're writing a Blorb file analysis
    tool (such as blorbscan), or a transformation tool, or some such thing. 
*/

/* More four-byte constants. */

#define bb_ID_FORM (bb_make_id('F', 'O', 'R', 'M'))
#define bb_ID_IFRS (bb_make_id('I', 'F', 'R', 'S'))
#define bb_ID_RIdx (bb_make_id('R', 'I', 'd', 'x'))
#define bb_ID_IFhd (bb_make_id('I', 'F', 'h', 'd'))
#define bb_ID_Reso (bb_make_id('R', 'e', 's', 'o'))
#define bb_ID_Loop (bb_make_id('L', 'o', 'o', 'p'))
#define bb_ID_RelN (bb_make_id('R', 'e', 'l', 'N'))
#define bb_ID_Plte (bb_make_id('P', 'l', 't', 'e'))

/* bb_chunkdesc_t: Describes one chunk of the Blorb file. */
typedef struct bb_chunkdesc_struct {
    uint32 type;
    uint32 len;
    uint32 startpos; /* start of chunk header */
    uint32 datpos; /* start of data (either startpos or startpos+8) */
    
    void *ptr; /* pointer to malloc'd data, if loaded */
    int auxdatnum; /* entry in the auxsound/auxpict array; -1 if none.
        This only applies to chunks that represent resources;  */
    
} bb_chunkdesc_t;

/* bb_resdesc_t: Describes one resource in the Blorb file. */
typedef struct bb_resdesc_struct {
    uint32 usage;
    int resnum;
    int chunknum;
} bb_resdesc_t;

/* bb_map_t: Holds the complete description of an open Blorb file. */
struct bb_map_struct {
    uint32 inited; /* holds bb_Inited_Magic if the map structure is valid */
    FILE *file;
    
    int numchunks;
    bb_chunkdesc_t *chunks; /* list of chunk descriptors */
    
    int numresources;
    bb_resdesc_t *resources; /* list of resource descriptors */
    bb_resdesc_t **ressorted; /* list of pointers to descriptors 
        in map->resources -- sorted by usage and resource number. */
    
    bb_zheader_t *zheader;
    int releasenum; 
    bb_resolution_t *resolution;
    int palettechunk; /* chunk number of palette, or -1 if there is none. */
    bb_palette_t *palette;
    bb_aux_sound_t *auxsound; /* extra information about sounds */
    bb_aux_pict_t *auxpict; /* extra information about pictures */
};

#define bb_Inited_Magic (0xB7012BED) 

extern char *bb_id_to_string(uint32 id);

#endif /* BLORBLOW_H */
