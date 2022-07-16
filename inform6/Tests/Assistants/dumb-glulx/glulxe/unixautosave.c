/* unixautosave.c: Unix-specific autosave code for Glulxe.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include <stdio.h>
#include <string.h>
#include "glulxe.h"
#include "unixstrt.h"
#include "gi_dispa.h"
#include "gi_blorb.h"
#include "glkstart.h" /* This comes with the Glk library. */

/* The following code only makes sense when compiled with a Glk library which offers autosave/autorestore hooks. */

#ifdef GLKUNIX_AUTOSAVE_FEATURES

char *pref_autosavedir = ".";
char *pref_autosavename = "autosave";
int pref_autosave_skiparrange = FALSE;

/* This is only needed for autorestore. (Defined in glkop.c.) */
extern gidispatch_rock_t glulxe_classtable_register_existing(void *obj, glui32 objclass, glui32 dispid);

/* This structure contains VM state which is not stored in a normal save file, but which is needed for an autorestore.
 
    (The reason it's not stored in a normal save file is that it's useless unless you serialize the entire Glk state along with the VM. Glulx normally doesn't do that, but for an autosave, we do.)
 */

typedef struct extra_glk_obj_id_entry_struct {
    glui32 objclass;
    glui32 tag;
    glui32 dispid;
} extra_glk_obj_id_entry_t;

typedef struct extra_glulx_accel_entry_struct {
    glui32 index;
    glui32 addr;
} extra_glulx_accel_entry_t;

typedef struct extra_glulx_accel_param_struct {
    glui32 param;
} extra_glulx_accel_param_t;

typedef struct extra_state_data_struct {
    glui32 active;
    glui32 protectstart, protectend;
    glui32 iosys_mode, iosys_rock;
    glui32 stringtable;
    glui32 accel_param_count;
    extra_glulx_accel_param_t *accel_params;
    glui32 accel_func_count;
    extra_glulx_accel_entry_t *accel_funcs;
    glui32 gamefiletag;
    glui32 id_map_list_count;
    extra_glk_obj_id_entry_t *id_map_list;
} extra_state_data_t;

static void stash_extra_state(extra_state_data_t *state);
static void recover_extra_state(extra_state_data_t *state);

static extra_state_data_t *extra_state_data_alloc(void);
static void extra_state_data_free(extra_state_data_t *);
static int extra_state_serialize(glkunix_serialize_context_t, void *);
static int extra_state_serialize_accel_param(glkunix_serialize_context_t, void *);
static int extra_state_serialize_accel_func(glkunix_serialize_context_t, void *);
static int extra_state_serialize_obj_id_entry(glkunix_serialize_context_t, void *);
static int extra_state_unserialize(glkunix_unserialize_context_t, void *);
static int extra_state_unserialize_accel_param(glkunix_unserialize_context_t, void *);
static int extra_state_unserialize_accel_func(glkunix_unserialize_context_t, void *);
static int extra_state_unserialize_obj_id_entry(glkunix_unserialize_context_t, void *);

static char *game_signature = NULL;
static char *autosave_basepath = NULL;

/* Take a chunk of data (the first 64 bytes of the game file, which makes a good signature) and convert it to a hex string. This will be used as part of the filename for autosave.
 */
void glkunix_set_autosave_signature(unsigned char *buf, glui32 len)
{
    static char *hexdigits = "0123456789abcdef";
    
    game_signature = glulx_malloc(2*len+1);
    for (int ix=0; ix<len; ix++) {
        unsigned char ch = buf[ix];
        game_signature[2*ix] = hexdigits[(ch >> 4) & 0x0F];
        game_signature[2*ix+1] = hexdigits[(ch) & 0x0F];
    }
    game_signature[2*len] = '\0';
}

/* Construct the pathname for autosaving this game. Returns a statically allocated string; the caller should append a filename suffix to that.
   This looks at the autosavedir and autosavename preferences. If autosavename contains a "#" character, the game signature is substituted.
 */
static char *get_autosave_basepath(void)
{
    if (autosave_basepath == NULL) {
        /* First time through we figure out where to save. */
        char *basename = pref_autosavename;
        char *hashpos = strchr(pref_autosavename, '#');
        if (hashpos && game_signature) {
            /* Substitute the game signature for the hash. */
            int len = strlen(pref_autosavename) - 1 + strlen(game_signature) + 1;
            int pos = (hashpos - pref_autosavename);
            basename = glulx_malloc(len);
            strncpy(basename, pref_autosavename, pos);
            strcpy(basename+pos, game_signature);
            strcat(basename, pref_autosavename+pos+1);
            if (strlen(basename) != len-1) {
                /* shouldn't happen */
                fatal_error("autosavename interpolation came out wrong");
                return NULL;
            }
        }
        
        int buflen = strlen(pref_autosavedir) + 1 + strlen(basename) + 1;
        autosave_basepath = glulx_malloc(buflen);
        sprintf(autosave_basepath, "%s/%s", pref_autosavedir, basename);
        
        if (basename != pref_autosavename)
            glulx_free(basename);
    }

    return autosave_basepath;
}

/* Backtrack through the current opcode (at prevpc), and figure out whether its input arguments are on the stack or not. This will be important when setting up the saved VM state for restarting its opcode.
 
    The opmodes argument must be an array int[3]. Returns TRUE on success.
 */
static int parse_partial_operand(int *opmodes)
{
    glui32 addr = prevpc;
    
    /* Fetch the opcode number. */
    glui32 opcode = Mem1(addr);
    addr++;
    if (opcode & 0x80) {
        /* More than one-byte opcode. */
        if (opcode & 0x40) {
            /* Four-byte opcode */
            opcode &= 0x3F;
            opcode = (opcode << 8) | Mem1(addr);
            addr++;
            opcode = (opcode << 8) | Mem1(addr);
            addr++;
            opcode = (opcode << 8) | Mem1(addr);
            addr++;
        }
        else {
            /* Two-byte opcode */
            opcode &= 0x7F;
            opcode = (opcode << 8) | Mem1(addr);
            addr++;
        }
    }
    
    if (opcode != 0x130) { /* op_glk */
        /* Error: parsed wrong opcode */
        return FALSE;
    }
    
    /* @glk has operands LLS. */
    opmodes[0] = Mem1(addr) & 0x0F;
    opmodes[1] = (Mem1(addr) >> 4) & 0x0F;
    opmodes[2] = Mem1(addr+1) & 0x0F;
    
    return TRUE;
}

void glkunix_do_autosave(glui32 selector, glui32 arg0, glui32 arg1, glui32 arg2)
{
    char *basepath = get_autosave_basepath();
    if (!basepath)
        return;
    /* Space for the base plus a file suffix. */
    char *pathname = glulx_malloc(strlen(basepath) + 16);
    if (!pathname)
        return;
    
    /* When the save file is autorestored, the VM will restart the @glk opcode. That means that the Glk argument (the event structure address) must be waiting on the stack. Possibly also the @glk opcode's operands -- these might or might not have come off the stack. */
    int res;
    int opmodes[3];
    res = parse_partial_operand(opmodes);
    if (!res) {
        glulx_free(pathname);
        return;
    }

    sprintf(pathname, "%s.glksave", basepath);
    strid_t savefile = glkunix_stream_open_pathname_gen(pathname, TRUE, FALSE, 1);
    if (!savefile) {
        glulx_free(pathname);
        return;
    }
        
    /* Push all the necessary arguments for the @glk opcode. */
    glui32 origstackptr = stackptr;
    int stackvals = 0;

    if (selector == 0x00C0) {
        /* The event structure address: */
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, arg0); /* eventaddr */
        stackptr += 4;
    }
    else if (selector == 0x0062) {
        /* The three arguments: */
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, arg2); /* rock */
        stackptr += 4;
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, arg1); /* fmode */
        stackptr += 4;
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, arg0); /* usage */
        stackptr += 4;
    }
    else {
        fatal_error("Autosave with unrecognized glk selector.");
    }
    
    if (opmodes[1] == 8) {
        /* The number of Glk arguments (1): */
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, 1);
        stackptr += 4;
    }
    if (opmodes[0] == 8) {
        /* The Glk call selector (0x00C0 or 0x0062): */
        stackvals++;
        if (stackptr+4 > stacksize)
            fatal_error("Stack overflow in autosave callstub.");
        StkW4(stackptr, selector);
        stackptr += 4;
    }
    
    /* Push a temporary callstub which contains the *last* PC -- the address of the @glk(select) invocation. */
    if (stackptr+16 > stacksize)
        fatal_error("Stack overflow in autosave callstub.");
    StkW4(stackptr+0, 0);
    StkW4(stackptr+4, 0);
    StkW4(stackptr+8, prevpc);
    StkW4(stackptr+12, frameptr);
    stackptr += 16;
    
    res = perform_save(savefile);
    
    stackptr -= 16; // discard the temporary callstub
    stackptr -= 4 * stackvals; // discard the temporary arguments
    if (origstackptr != stackptr)
        fatal_error("Stack pointer mismatch in autosave");
    
    glk_stream_close(savefile, NULL);
    savefile = NULL;

    if (res) {
        glulx_free(pathname);
        return;
    }

    extra_state_data_t *extra_state = extra_state_data_alloc();
    if (!extra_state) {
        glulx_free(pathname);
        return;
    }
    stash_extra_state(extra_state);

    sprintf(pathname, "%s.json", basepath);
    strid_t jsavefile = glkunix_stream_open_pathname_gen(pathname, TRUE, FALSE, 1);
    if (!jsavefile) {
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return;
    }

    glkunix_save_library_state(jsavefile, jsavefile, extra_state_serialize, extra_state);

    glk_stream_close(jsavefile, NULL);
    jsavefile = NULL;
    
    extra_state_data_free(extra_state);
    extra_state = NULL;

    /* We could write those files to temporary paths and then rename them into place. That would be safer. */

    glulx_free(pathname);
    pathname = NULL;
}

int glkunix_do_autorestore()
{
    char *basepath = get_autosave_basepath();
    if (!basepath)
        return FALSE;
    /* Space for the base plus a file suffix. */
    char *pathname = glulx_malloc(strlen(basepath) + 16);
    if (!pathname)
        return FALSE;

    extra_state_data_t *extra_state = extra_state_data_alloc();
    if (!extra_state) {
        glulx_free(pathname);
        return FALSE;
    }

    sprintf(pathname, "%s.json", basepath);
    strid_t jsavefile = glkunix_stream_open_pathname_gen(pathname, FALSE, FALSE, 1);
    if (!jsavefile) {
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return FALSE;
    }
    
    glkunix_library_state_t library_state = glkunix_load_library_state(jsavefile, extra_state_unserialize, extra_state);

    glk_stream_close(jsavefile, NULL);
    jsavefile = NULL;
    
    if (!library_state) {
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return FALSE;
    }
    
    sprintf(pathname, "%s.glksave", basepath);
    strid_t savefile = glkunix_stream_open_pathname_gen(pathname, FALSE, FALSE, 1);
    if (!savefile) {
        glkunix_library_state_free(library_state);
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return FALSE;
    }
        
    glui32 res = perform_restore(savefile, TRUE);
    glk_stream_close(savefile, NULL);
    savefile = NULL;

    if (res) {
        glkunix_library_state_free(library_state);
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return FALSE;
    }

    pop_callstub(0);
    /* This should leave the PC on the @glk opcode that executed glk_select or glk_fileref_create_by_prompt. */

    /* Annoyingly, the update_from_library_state we're about to do will close the currently-open gamefile. We'll recover it immediately, in recover_extra_state(). */

    res = glkunix_update_from_library_state(library_state);
    if (!res) {
        glkunix_library_state_free(library_state);
        extra_state_data_free(extra_state);
        glulx_free(pathname);
        return FALSE;
    }

    recover_extra_state(extra_state);

    /* Clean up. */
    
    glkunix_library_state_free(library_state);
    library_state = NULL;

    extra_state_data_free(extra_state);
    extra_state = NULL;

    glulx_free(pathname);
    pathname = NULL;

    return TRUE;
}

static glui32 tmp_accel_func_count;
static glui32 tmp_accel_func_size;
static extra_glulx_accel_entry_t *tmp_accel_funcs;

static void stash_one_accel_func(glui32 index, glui32 addr)
{
    if (tmp_accel_func_count >= tmp_accel_func_size) {
        if (tmp_accel_funcs == NULL) {
            tmp_accel_func_size = 4;
            tmp_accel_funcs = glulx_malloc(tmp_accel_func_size * sizeof(extra_glulx_accel_entry_t));
        }
        else {
            tmp_accel_func_size = 2 * tmp_accel_func_count + 4;
            tmp_accel_funcs = glulx_realloc(tmp_accel_funcs, tmp_accel_func_size * sizeof(extra_glulx_accel_entry_t));
        }
    }

    tmp_accel_funcs[tmp_accel_func_count].index = index;
    tmp_accel_funcs[tmp_accel_func_count].addr = addr;
    tmp_accel_func_count++;
}

/* Copy extra chunks of the VM state into the (static) extra_state object. This is information needed by autosave, but not included in the regular save process.
 */
static void stash_extra_state(extra_state_data_t *state)
{
    glui32 count;
    
    state->active = TRUE;
    
    state->protectstart = protectstart;
    state->protectend = protectend;
    stream_get_iosys(&state->iosys_mode, &state->iosys_rock);
    state->stringtable = stream_get_table();

    count = accel_get_param_count();
    state->accel_param_count = count;
    state->accel_params = glulx_malloc(count * sizeof(extra_glulx_accel_param_t));
    for (int ix=0; ix<count; ix++) {
        state->accel_params[ix].param = accel_get_param(ix);
    }

    tmp_accel_func_count = 0;
    tmp_accel_func_size = 0;
    tmp_accel_funcs = NULL;

    accel_iterate_funcs(&stash_one_accel_func);
    
    state->accel_func_count = tmp_accel_func_count;
    state->accel_funcs = tmp_accel_funcs;
    tmp_accel_funcs = NULL;

    if (gamefile) {
        state->gamefiletag = glkunix_stream_get_updatetag(gamefile);
    }

    count = 0;
    for (winid_t tmpwin = glk_window_iterate(NULL, NULL); tmpwin; tmpwin = glk_window_iterate(tmpwin, NULL))
        count++;
    for (strid_t tmpstr = glk_stream_iterate(NULL, NULL); tmpstr; tmpstr = glk_stream_iterate(tmpstr, NULL))
        count++;
    for (frefid_t tmpfref = glk_fileref_iterate(NULL, NULL); tmpfref; tmpfref = glk_fileref_iterate(tmpfref, NULL))
        count++;

    state->id_map_list_count = count;
    if (count) {
        state->id_map_list = glulx_malloc(count * sizeof(extra_glk_obj_id_entry_t));
    }
    
    glui32 ix = 0;
    for (winid_t tmpwin = glk_window_iterate(NULL, NULL); tmpwin; tmpwin = glk_window_iterate(tmpwin, NULL)) {
        state->id_map_list[ix].objclass = gidisp_Class_Window;
        state->id_map_list[ix].tag = glkunix_window_get_updatetag(tmpwin);
        state->id_map_list[ix].dispid = find_id_for_window(tmpwin);
        ix++;
    }
    for (strid_t tmpstr = glk_stream_iterate(NULL, NULL); tmpstr; tmpstr = glk_stream_iterate(tmpstr, NULL)) {
        state->id_map_list[ix].objclass = gidisp_Class_Stream;
        state->id_map_list[ix].tag = glkunix_stream_get_updatetag(tmpstr);
        state->id_map_list[ix].dispid = find_id_for_stream(tmpstr);
        ix++;
    }
    for (frefid_t tmpfref = glk_fileref_iterate(NULL, NULL); tmpfref; tmpfref = glk_fileref_iterate(tmpfref, NULL)) {
        state->id_map_list[ix].objclass = gidisp_Class_Fileref;
        state->id_map_list[ix].tag = glkunix_fileref_get_updatetag(tmpfref);
        state->id_map_list[ix].dispid = find_id_for_fileref(tmpfref);
        ix++;
    }

    if (ix != state->id_map_list_count)
        fatal_error("stash_extra_state: Glk object count mismatch");
}

/* Copy chunks of VM state out of the extra_state object.
 */
static void recover_extra_state(extra_state_data_t *state)
{
    if (!state->active) {
        return;
    }

    protectstart = state->protectstart;
    protectend = state->protectend;
    stream_set_iosys(state->iosys_mode, state->iosys_rock);
    stream_set_table(state->stringtable);

    if (state->accel_params) {
        for (int ix=0; ix<state->accel_param_count; ix++) {
            accel_set_param(ix, state->accel_params[ix].param);
        }
    }

    if (state->accel_funcs) {
        for (int ix=0; ix<state->accel_func_count; ix++) {
            accel_set_func(state->accel_funcs[ix].index, state->accel_funcs[ix].addr);
        }
    }

    if (state->id_map_list) {
        for (int ix=0; ix<state->id_map_list_count; ix++) {
            extra_glk_obj_id_entry_t *entry = &state->id_map_list[ix];
            
            switch (entry->objclass) {
                
            case gidisp_Class_Window: {
                    winid_t win = glkunix_window_find_by_updatetag(entry->tag);
                    if (!win) {
                        nonfatal_warning_i("Could not find window for tag", entry->tag);
                        break;
                    }
                    glkunix_window_set_dispatch_rock(win, glulxe_classtable_register_existing(win, entry->objclass, entry->dispid));
                }
                break;
                
            case gidisp_Class_Stream: {
                    strid_t str = glkunix_stream_find_by_updatetag(entry->tag);
                    if (!str) {
                        nonfatal_warning_i("Could not find stream for tag", entry->tag);
                        break;
                    }
                    glkunix_stream_set_dispatch_rock(str, glulxe_classtable_register_existing(str, entry->objclass, entry->dispid));
                }
                break;
                
            case gidisp_Class_Fileref: {
                    frefid_t fref = glkunix_fileref_find_by_updatetag(entry->tag);
                    if (!fref) {
                        nonfatal_warning_i("Could not find fileref for tag", entry->tag);
                        break;
                    }
                    glkunix_fileref_set_dispatch_rock(fref, glulxe_classtable_register_existing(fref, entry->objclass, entry->dispid));
                }
                break;
                
            }
        }
    }

    if (state->gamefiletag) {
        gamefile = glkunix_stream_find_by_updatetag(state->gamefiletag);

        if (giblorb_get_resource_map()) {
            /* It's inefficient to throw away the blorb chunk map, which we just loaded, and then recreate it. Oh well. */
            giblorb_err_t err;
            err = giblorb_unset_resource_map();
            if (err)
                fatal_error("Unable to clear blorb map");
            err = giblorb_set_resource_map(gamefile);
            if (err)
                fatal_error("Unable to reset blorb map");
        }
    }
}

static extra_state_data_t *extra_state_data_alloc()
{
    extra_state_data_t *state = glulx_malloc(sizeof(extra_state_data_t));
    if (!state)
        return NULL;

    /* Everything gets initialized to zero/null */
    memset(state, 0, sizeof(extra_state_data_t));
    state->active = FALSE;
    state->accel_param_count = 0;
    state->accel_params = NULL;
    state->accel_func_count = 0;
    state->accel_funcs = NULL;
    state->id_map_list_count = 0;
    state->id_map_list = NULL;

    return state;
}

static void extra_state_data_free(extra_state_data_t *state)
{
    if (state->accel_params) {
        glulx_free(state->accel_params);
        state->accel_params = NULL;
    }
    if (state->accel_funcs) {
        glulx_free(state->accel_funcs);
        state->accel_funcs = NULL;
    }
    if (state->id_map_list) {
        glulx_free(state->id_map_list);
        state->id_map_list = NULL;
    }
    state->active = FALSE;

    glulx_free(state);
}

static int extra_state_serialize(glkunix_serialize_context_t ctx, void *rock)
{
    extra_state_data_t *state = rock;

    if (state->active) {
        glkunix_serialize_uint32(ctx, "glulx_extra_state", 1);

        glkunix_serialize_uint32(ctx, "glulx_protectstart", state->protectstart);
        glkunix_serialize_uint32(ctx, "glulx_protectend", state->protectend);
        glkunix_serialize_uint32(ctx, "glulx_iosys_mode", state->iosys_mode);
        glkunix_serialize_uint32(ctx, "glulx_iosys_rock", state->iosys_rock);
        glkunix_serialize_uint32(ctx, "glulx_stringtable", state->stringtable);
        
        if (state->accel_params) {
            glkunix_serialize_object_list(ctx, "glulx_accel_params", extra_state_serialize_accel_param, state->accel_param_count, sizeof(extra_glulx_accel_param_t), state->accel_params);
        }

        if (state->accel_funcs) {
            glkunix_serialize_object_list(ctx, "glulx_accel_funcs", extra_state_serialize_accel_func, state->accel_func_count, sizeof(extra_glulx_accel_entry_t), state->accel_funcs);
        }

        glkunix_serialize_uint32(ctx, "glulx_gamefiletag", state->gamefiletag);
        
        if (state->id_map_list) {
            glkunix_serialize_object_list(ctx, "glulx_id_map_list", extra_state_serialize_obj_id_entry, state->id_map_list_count, sizeof(extra_glk_obj_id_entry_t), state->id_map_list);
        }

    }
    
    return TRUE;
}

static int extra_state_serialize_accel_param(glkunix_serialize_context_t ctx, void *rock)
{
    extra_glulx_accel_param_t *param = rock;
    glkunix_serialize_uint32(ctx, "param", param->param);
    return TRUE;
}

static int extra_state_serialize_accel_func(glkunix_serialize_context_t ctx, void *rock)
{
    extra_glulx_accel_entry_t *entry = rock;
    glkunix_serialize_uint32(ctx, "index", entry->index);
    glkunix_serialize_uint32(ctx, "addr", entry->addr);
    return TRUE;
}

static int extra_state_serialize_obj_id_entry(glkunix_serialize_context_t ctx, void *rock)
{
    extra_glk_obj_id_entry_t *obj = rock;
    glkunix_serialize_uint32(ctx, "objclass", obj->objclass);
    glkunix_serialize_uint32(ctx, "tag", obj->tag);
    glkunix_serialize_uint32(ctx, "dispid", obj->dispid);
    return TRUE;
}

static int extra_state_unserialize(glkunix_unserialize_context_t ctx, void *rock)
{
    extra_state_data_t *state = (extra_state_data_t *)rock;
    
    glui32 val;
    
    if (!glkunix_unserialize_uint32(ctx, "glulx_extra_state", &val))
        return FALSE;
    if (!val)
        return FALSE;

    glkunix_unserialize_uint32(ctx, "glulx_protectstart", &state->protectstart);
    glkunix_unserialize_uint32(ctx, "glulx_protectend", &state->protectend);
    glkunix_unserialize_uint32(ctx, "glulx_iosys_mode", &state->iosys_mode);
    glkunix_unserialize_uint32(ctx, "glulx_iosys_rock", &state->iosys_rock);
    glkunix_unserialize_uint32(ctx, "glulx_stringtable", &state->stringtable);

    glkunix_unserialize_context_t array;
    int count;
    
    if (glkunix_unserialize_list(ctx, "glulx_accel_params", &array, &count)) {
        if (count) {
            state->accel_param_count = count;
            state->accel_params = glulx_malloc(count * sizeof(extra_glulx_accel_param_t));
            memset(state->accel_params, 0, count * sizeof(extra_glulx_accel_param_t));
            if (!glkunix_unserialize_object_list_entries(array, extra_state_unserialize_accel_param, count, sizeof(extra_glulx_accel_param_t), state->accel_params))
                return FALSE;
        }
    }
    
    if (glkunix_unserialize_list(ctx, "glulx_accel_funcs", &array, &count)) {
        if (count) {
            state->accel_func_count = count;
            state->accel_funcs = glulx_malloc(count * sizeof(extra_glulx_accel_entry_t));
            memset(state->accel_funcs, 0, count * sizeof(extra_glulx_accel_entry_t));
            if (!glkunix_unserialize_object_list_entries(array, extra_state_unserialize_accel_func, count, sizeof(extra_glulx_accel_entry_t), state->accel_funcs))
                return FALSE;
        }
    }
    
    glkunix_unserialize_uint32(ctx, "glulx_gamefiletag", &state->gamefiletag);

    if (glkunix_unserialize_list(ctx, "glulx_id_map_list", &array, &count)) {
        if (count) {
            state->id_map_list_count = count;
            state->id_map_list = glulx_malloc(count * sizeof(extra_glk_obj_id_entry_t));
            memset(state->id_map_list, 0, count * sizeof(extra_glk_obj_id_entry_t));
            if (!glkunix_unserialize_object_list_entries(array, extra_state_unserialize_obj_id_entry, count, sizeof(extra_glk_obj_id_entry_t), state->id_map_list))
                return FALSE;
        }
    }

    state->active = TRUE;
    
    return TRUE;
}

static int extra_state_unserialize_accel_param(glkunix_unserialize_context_t ctx, void *rock)
{
    extra_glulx_accel_param_t *param = rock;
    glkunix_unserialize_uint32(ctx, "param", &param->param);
    return TRUE;
}

static int extra_state_unserialize_accel_func(glkunix_unserialize_context_t ctx, void *rock)
{
    extra_glulx_accel_entry_t *entry = rock;
    glkunix_unserialize_uint32(ctx, "index", &entry->index);
    glkunix_unserialize_uint32(ctx, "addr", &entry->addr);
    return TRUE;
}

static int extra_state_unserialize_obj_id_entry(glkunix_unserialize_context_t ctx, void *rock)
{
    extra_glk_obj_id_entry_t *obj = rock;
    glkunix_unserialize_uint32(ctx, "objclass", &obj->objclass);
    glkunix_unserialize_uint32(ctx, "tag", &obj->tag);
    glkunix_unserialize_uint32(ctx, "dispid", &obj->dispid);
    return TRUE;
}

#endif /* GLKUNIX_AUTOSAVE_FEATURES */
