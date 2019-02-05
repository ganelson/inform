/* blorbscan.c: Blorb file analysis tool, version 1.0.2.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://www.eblong.com/zarf/blorb/index.html
    
    This is a nifty little tool which sucks any and all information out of
    a Blorb file. It doesn't do it in a particularly elegant way; it pulls
    a lot of information directly out of the bb_map_t structure, which is
    normally opaque. (It can do this because it #includes "blorblow.h".)
    
    So don't take this file as sample code, ok?
*/

#include <stdio.h>
#include <stdlib.h>
#include "blorb.h"
#include "blorblow.h"

void analyze_file(FILE *fl);

static int opt_chunks = FALSE;
static int opt_resources = FALSE;
static int opt_split = FALSE;
static int opt_byusage = FALSE;
static int opt_palette = FALSE;
static int opt_resolution = FALSE;
static int opt_extras = FALSE;
static int opt_release = FALSE;
static int opt_zheader = FALSE;

int main(int argc, char *argv[])
{
    int ix;
    char *filename = NULL;
    FILE *fl;
    int err = FALSE;
    int anyopts = FALSE;
    
    for (ix=1; ix<argc; ix++) {
        if (argv[ix][0] == '-') {
            char *cx = argv[ix];
            for (cx++; *cx; cx++) {
                switch (*cx) {
                    case 'c':
                        opt_chunks = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'r':
                        opt_resources = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'u':
                        opt_byusage = TRUE;
                        anyopts = TRUE;
                        break;
                    case 's':
                        opt_split = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'p':
                        opt_palette = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'x':
                        opt_extras = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'n':
                        opt_release = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'z':
                        opt_zheader = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'w':
                        opt_resolution = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'A':
                        opt_chunks = TRUE;
                        opt_resources = TRUE;
                        opt_byusage = TRUE;
                        opt_palette = TRUE;
                        opt_zheader = TRUE;
                        opt_resolution = TRUE;
                        opt_extras = TRUE;
                        opt_release = TRUE;
                        anyopts = TRUE;
                        break;
                    case 'h':
                    case '?':
                        err = TRUE;
                        break;
                    default:
                        err = TRUE;
                        printf("unknown option: -%c\n", *cx);
                        break;
                }
            }
        }
        else {
            if (!filename)
                filename = argv[ix];
            else
                err = TRUE;
        }
    }

    if (!anyopts) {
        opt_resources = TRUE;
    }

    if (!filename || err) {
        printf("usage: %s [ -urscnzwpxA ] filename\n", argv[0]);
        printf("  -u: count resources by usage\n");
        printf("  -r: list resources (the default)\n");
        printf("  -s: split out resources into separate files\n");
        printf("  -c: list chunks\n");
        printf("  -n: show release number\n");
        printf("  -z: show z-code header info\n");
        printf("  -w: show window resolution hints\n");
        printf("  -p: show palette hints\n");
        printf("  -x: show extras (author, annotation, copyright)\n");
        printf("  -A: all of the above (except -s)\n");
        return 0;
    }
    
    fl = fopen(filename, "rb");
    if (!fl) {
        printf("Unable to open file.\n");
        return 0;
    }

    printf("Reading \"%s\"...\n\n", filename);
    
    analyze_file(fl);
    
    fclose(fl);
    return 0;
}

void analyze_file(FILE *fl)
{
    bb_map_t *map;
    bb_err_t err;
    int ix;

    err = bb_create_map(fl, &map);
    if (err) {
        printf("Cannot create map: %s\n", bb_err_to_string(err));
        return;
    }
    
    if (opt_byusage) {
        int num, min, max;
        
        err = bb_count_resources(map, bb_ID_Exec, &num, &min, &max);
        if (!err) {
            if (num == 0)
                printf("No '%s' resources\n", bb_id_to_string(bb_ID_Exec));
            else
                printf("%d '%s' resources (numbered from %d to %d)\n",
                    num, bb_id_to_string(bb_ID_Exec), min, max);
        }
        else {
            printf("Cannot count '%s' resources: %s\n", 
                bb_id_to_string(bb_ID_Exec), bb_err_to_string(err));
        }
        
        err = bb_count_resources(map, bb_ID_Snd, &num, &min, &max);
        if (!err) {
            if (num == 0)
                printf("No '%s' resources\n", bb_id_to_string(bb_ID_Snd));
            else
                printf("%d '%s' resources (numbered from %d to %d)\n",
                    num, bb_id_to_string(bb_ID_Snd), min, max);
        }
        else {
            printf("Cannot count '%s' resources: %s\n", 
                bb_id_to_string(bb_ID_Snd), bb_err_to_string(err));
        }
        
        err = bb_count_resources(map, bb_ID_Pict, &num, &min, &max);
        if (!err) {
            if (num == 0)
                printf("No '%s' resources\n", bb_id_to_string(bb_ID_Pict));
            else
                printf("%d '%s' resources (numbered from %d to %d)\n",
                    num, bb_id_to_string(bb_ID_Pict), min, max);
        }
        else {
            printf("Cannot count '%s' resources: %s\n", 
                bb_id_to_string(bb_ID_Pict), bb_err_to_string(err));
        }
        
        printf("\n");
    }
    
    if (opt_resources) {
        printf("List of resources:\n");
        
        for (ix=0; ix<map->numresources; ix++) {
            bb_chunkdesc_t *chu;
            printf("Usage '%s' number %d: chunk %d", 
                bb_id_to_string(map->resources[ix].usage),
                map->resources[ix].resnum, map->resources[ix].chunknum);
            chu = &(map->chunks[map->resources[ix].chunknum]);
            switch (map->resources[ix].usage) {
                case bb_ID_Pict:
                    if (chu->auxdatnum >= 0) {
                        bb_aux_pict_t *aux = &(map->auxpict[chu->auxdatnum]);
                        printf(" (std = %g", (double)aux->ratnum / (double)aux->ratden);
                        if (aux->minnum || aux->minden)
                            printf(", min = %g", (double)aux->minnum / (double)aux->minden);
                        if (aux->maxnum || aux->maxden)
                            printf(", min = %g", (double)aux->maxnum / (double)aux->maxden);
                        printf(")");
                    }
                    break;
                case bb_ID_Snd:
                    if (chu->auxdatnum >= 0) {
                        bb_aux_sound_t *aux = &(map->auxsound[chu->auxdatnum]);
                        printf(" (repeats = %s)", (aux->repeats ? "1" : "infinite"));
                    }
                    break;
            }
            printf("\n");
        }

        printf("\n");
    }
    
    if (opt_split) {
        printf("Writing resources to individual files...\n\n");

        for (ix=0; ix<map->numresources; ix++) {
            bb_result_t res;
            char outfname[64];
            sprintf(outfname, "chu_%c%d", (map->resources[ix].usage >> 24) & 0xff,
                map->resources[ix].resnum);
            err = bb_load_chunk_by_number(map, bb_method_FilePos, &res, 
                map->resources[ix].chunknum);
            if (err) {
                printf("Cannot load chunk: %s\n", bb_err_to_string(err));
            }
            else {
                FILE *outfl;
                fseek(map->file, res.data.startpos, 0);
                outfl = fopen(outfname, "wb");
                if (outfl) {
                    int ch, jx;
                    for (jx=0; jx<res.length; jx++) {
                        ch = getc(map->file);
                        if (ch == EOF)
                            break;
                        putc(ch, outfl);
                    }
                    fclose(outfl);
                }
            }
        }
    }
    
    if (opt_chunks) {
        printf("List of chunks:\n");
        
        for (ix=0; ix<map->numchunks; ix++) {
            printf("Chunk %d: type '%s', starts at %d, length %d.\n", ix, 
                bb_id_to_string(map->chunks[ix].type), map->chunks[ix].startpos,
                map->chunks[ix].len);
        }

        printf("\n");
    }
    
    if (opt_release) {
        printf("Release number: %d\n\n", bb_get_release_num(map));
    }
    
    if (opt_zheader) {
        bb_zheader_t *head = bb_get_zheader(map);
        if (!head) {
            printf("No Z-code header info.\n");
        }
        else {
            int jx;
            printf("Release %d.\nSerial number ", head->releasenum);
            for (jx=0; jx<6; jx++)
                printf("%c", head->serialnum[jx]);
            printf(".\nChecksum %x.\n", head->checksum);
        }
        
        printf("\n");
    }
    
    if (opt_resolution) {
        bb_resolution_t *reso = bb_get_resolution(map);
        if (!reso) {
            printf("No window size data.\n");
        }
        else {
            printf("Window size: standard %d by %d; min %d by %d; max %d by %d.\n",
                reso->px, reso->py, reso->minx, reso->miny, reso->maxx, reso->maxy);
        }
        
        printf("\n");
    }
    
    if (opt_palette) {
        bb_palette_t *pal;
        err = bb_get_palette(map, &pal);
        if (err)
            printf("Cannot load palette data: %s\n", bb_err_to_string(err));
        else {
            if (!pal)
                printf("No palette/color depth data.\n");
            else {
                if (pal->isdirect) {
                    printf("Preferred color depth: %d bits per pixel.\n",
                        pal->data.depth);
                }
                else {
                    printf("Preferred color palette (R,G,B):");
                    for (ix=0; ix<pal->data.table.numcolors; ix++) {
                        bb_color_t *col = &(pal->data.table.colors[ix]);
                        printf(" (%d,%d,%d)", col->red, col->green, col->blue);
                    }
                    printf("\n");
                }
            }
        }
        
        printf("\n");
    }
    
    if (opt_extras) {
        bb_result_t res;
        
        err = bb_load_chunk_by_type(map, bb_method_Memory, &res, 
            bb_ID_Copyright, 0);
        if (!err) {
            printf("Copyright chunk: ");
            fwrite(res.data.ptr, 1, res.length, stdout);
            printf("\n");
        }
        else if (err == bb_err_NotFound)
            printf("No copyright chunk.\n");
        else
            printf("Cannot load copyright chunk: %s\n", bb_err_to_string(err));
        
        err = bb_load_chunk_by_type(map, bb_method_Memory, &res, 
            bb_ID_AUTH, 0);
        if (!err) {
            printf("Author chunk: ");
            fwrite(res.data.ptr, 1, res.length, stdout);
            printf("\n");
        }
        else if (err == bb_err_NotFound)
            printf("No author chunk.\n");
        else
            printf("Cannot load author chunk: %s\n", bb_err_to_string(err));
        
        err = bb_load_chunk_by_type(map, bb_method_Memory, &res, 
            bb_ID_ANNO, 0);
        if (!err) {
            printf("Annotation chunk: ");
            fwrite(res.data.ptr, 1, res.length, stdout);
            printf("\n");
        }
        else if (err == bb_err_NotFound)
            printf("No annotation chunk.\n");
        else
            printf("Cannot load annotation chunk: %s\n", bb_err_to_string(err));
        
        printf("\n");
    }
    
    err = bb_destroy_map(map);
    if (err) {
        printf("Cannot destroy map: %s\n", bb_err_to_string(err));
        return;
    }
}

