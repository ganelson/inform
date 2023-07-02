/* unixstrt.c: Unix-specific code for Glulxe.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include <stdlib.h>
#include <string.h>
#include "glk.h"
#include "gi_blorb.h"
#include "glulxe.h"
#include "unixstrt.h"
#include "glkstart.h" /* This comes with the Glk library. */

#if VM_DEBUGGER
/* This header file may come with the Glk library. If it doesn't, comment
   out VM_DEBUGGER in glulxe.h -- you won't be able to use debugging. */
#include "gi_debug.h" 
#endif /* VM_DEBUGGER */

static void glkunix_game_select(glui32 selector, glui32 arg0, glui32 arg1, glui32 arg2);
static void glkunix_game_start(void);
static void glkunix_game_autorestore(void);

/* The only command-line arguments are the filename and the number of
   undo states. And the profiling switch, if that's compiled in. The
   only *three* command-line arguments are...

   You may wonder why there's no argument for a save file to autorestore
   at startup. That would be nice; unfortunately it can't work. A Glulx
   game expects to set up its Glk environment (@setiosys, open windows,
   etc) before handling a "restore" command. It can't pick up from a
   restored state without that environment in place.
*/
glkunix_argumentlist_t glkunix_arguments[] = {

  { "--undo", glkunix_arg_ValueFollows, "Number of undo states to store." },
  { "--rngseed", glkunix_arg_ValueFollows, "Fix initial RNG if nonzero." },

#if GLKUNIX_AUTOSAVE_FEATURES
  { "--autosave", glkunix_arg_NoValue, "Autosave every turn." },
  { "--autorestore", glkunix_arg_NoValue, "Autorestore at launch." },
  { "--autodir", glkunix_arg_ValueFollows, "Directory for autosave/restore files (default: .)." },
  { "--autoname", glkunix_arg_ValueFollows, "Base filename for autosave/restore (default: autosave)." },
  { "--autoskiparrange", glkunix_arg_NoValue, "Don't autosave on arrange events." },
#endif /* GLKUNIX_AUTOSAVE_FEATURES */

#if VM_PROFILING
  { "--profile", glkunix_arg_ValueFollows, "Generate profiling information to a file." },
  { "--profcalls", glkunix_arg_NoValue, "Include what-called-what details in profiling. (Slow!)" },
#endif /* VM_PROFILING */

#if VM_DEBUGGER
  { "--gameinfo", glkunix_arg_ValueFollows, "Read debug information from a file." },
  { "--cpu", glkunix_arg_NoValue, "Display CPU usage of each command (debug)." },
  { "--starttrap", glkunix_arg_NoValue, "Enter debug mode at startup time (debug)." },
  { "--quittrap", glkunix_arg_NoValue, "Enter debug mode at quit time (debug)." },
  { "--crashtrap", glkunix_arg_NoValue, "Enter debug mode on any fatal error (debug)." },
#endif /* VM_DEBUGGER */

  { "", glkunix_arg_ValueFollows, "filename: The game file to load." },

  { NULL, glkunix_arg_End, NULL }
};

int glkunix_startup_code(glkunix_startup_t *data)
{
  /* It turns out to be more convenient if we return TRUE from here, even 
     when an error occurs, and display an error in glk_main(). */
  int ix;
  char *filename = NULL;
  char *gameinfofilename = NULL;
  int gameinfoloaded = FALSE;
  int pref_autosave = FALSE;
  int pref_autorestore = FALSE;
  unsigned char buf[12];
  int res;

  /* Parse out the arguments. They've already been checked for validity,
     and the library-specific ones stripped out.
     As usual for Unix, the zeroth argument is the executable name. */
  for (ix=1; ix<data->argc; ix++) {

    if (!strcmp(data->argv[ix], "--undo")) {
      ix++;
      if (ix<data->argc) {
        char *endptr = NULL;
        int val = strtol(data->argv[ix], &endptr, 10);
        if (*endptr) {
          init_err = "--undo must be a number.";
          return TRUE;
        }
        max_undo_level = val;
      }
      continue;
    }

    if (!strcmp(data->argv[ix], "--rngseed")) {
      ix++;
      if (ix<data->argc) {
        char *endptr = NULL;
        int val = strtol(data->argv[ix], &endptr, 10);
        if (*endptr) {
          init_err = "--rngseed must be a number.";
          return TRUE;
        }
        init_rng_seed = val;
      }
      continue;
    }

#if GLKUNIX_AUTOSAVE_FEATURES
    if (!strcmp(data->argv[ix], "--autosave")) {
      pref_autosave = TRUE;
      continue;
    }
    if (!strcmp(data->argv[ix], "--autorestore")) {
      pref_autorestore = TRUE;
      continue;
    }
    if (!strcmp(data->argv[ix], "--autodir")) {
      ix++;
      if (ix<data->argc) {
        pref_autosavedir = data->argv[ix];
      }
      continue;
    }
    if (!strcmp(data->argv[ix], "--autoname")) {
      ix++;
      if (ix<data->argc) {
        pref_autosavename = data->argv[ix];
      }
      continue;
    }
    if (!strcmp(data->argv[ix], "--autoskiparrange")) {
      pref_autosave_skiparrange = TRUE;
      continue;
    }
#endif /* GLKUNIX_AUTOSAVE_FEATURES */

#if VM_PROFILING
    if (!strcmp(data->argv[ix], "--profile")) {
      ix++;
      if (ix<data->argc) {
        strid_t profstr = glkunix_stream_open_pathname_gen(data->argv[ix], TRUE, FALSE, 1);
        if (!profstr) {
          init_err = "Unable to open profile output file.";
          init_err2 = data->argv[ix];
          return TRUE;
        }
        setup_profile(profstr, NULL);
      }
      continue;
    }
    if (!strcmp(data->argv[ix], "--profcalls")) {
      profile_set_call_counts(TRUE);
      continue;
    }
#endif /* VM_PROFILING */

#if VM_DEBUGGER
    if (!strcmp(data->argv[ix], "--gameinfo")) {
      ix++;
      if (ix<data->argc) {
        gameinfofilename = data->argv[ix];
      }
      continue;
    }
    if (!strcmp(data->argv[ix], "--cpu")) {
      debugger_track_cpu(TRUE);
      continue;
    }
    if (!strcmp(data->argv[ix], "--starttrap")) {
      debugger_set_start_trap(TRUE);
      continue;
    }
    if (!strcmp(data->argv[ix], "--quittrap")) {
      debugger_set_quit_trap(TRUE);
      continue;
    }
    if (!strcmp(data->argv[ix], "--crashtrap")) {
      debugger_set_crash_trap(TRUE);
      continue;
    }
#endif /* VM_DEBUGGER */

    if (filename) {
      init_err = "You must supply exactly one game file.";
      return TRUE;
    }
    filename = data->argv[ix];
  }

  if (!filename) {
    init_err = "You must supply the name of a game file.";
    return TRUE;
  }
    
  gamefile = glkunix_stream_open_pathname(filename, FALSE, 1);
  if (!gamefile) {
    init_err = "The game file could not be opened.";
    init_err2 = filename;
    return TRUE;
  }

#if GLKUNIX_AUTOSAVE_FEATURES
  if (pref_autosave || pref_autorestore) {
    set_library_start_hook(glkunix_game_start);
    if (pref_autorestore)
      set_library_autorestore_hook(glkunix_game_autorestore);
    if (pref_autosave)
      set_library_select_hook(glkunix_game_select);
  }
#endif /* GLKUNIX_AUTOSAVE_FEATURES */

#if VM_DEBUGGER
  if (gameinfofilename) {
    strid_t debugstr = glkunix_stream_open_pathname_gen(gameinfofilename, FALSE, FALSE, 1);
    if (!debugstr) {
      nonfatal_warning("Unable to open gameinfo file for debug data.");
    }
    else {
      int bres = debugger_load_info_stream(debugstr);
      glk_stream_close(debugstr, NULL);
      if (!bres)
        nonfatal_warning("Unable to parse game info.");
      else
        gameinfoloaded = TRUE;
    }
  }

  /* Report debugging available, whether a game info file is loaded or not. */
  gidebug_debugging_available(debugger_cmd_handler, debugger_cycle_handler);
#endif /* VM_DEBUGGER */

  /* Now we have to check to see if it's a Blorb file. */

  glk_stream_set_position(gamefile, 0, seekmode_Start);
  res = glk_get_buffer_stream(gamefile, (char *)buf, 12);
  if (!res) {
    init_err = "The data in this stand-alone game is too short to read.";
    return TRUE;
  }
    
  if (buf[0] == 'G' && buf[1] == 'l' && buf[2] == 'u' && buf[3] == 'l') {
    /* Load game directly from file. */
    locate_gamefile(FALSE);

    return TRUE;
  }
  else if (buf[0] == 'F' && buf[1] == 'O' && buf[2] == 'R' && buf[3] == 'M'
    && buf[8] == 'I' && buf[9] == 'F' && buf[10] == 'R' && buf[11] == 'S') {
    /* Load game from a chunk in the Blorb file. */
    locate_gamefile(TRUE);

#if VM_DEBUGGER
    /* Load the debug info from the Blorb, if it wasn't loaded from a file. */
    if (!gameinfoloaded) {
      glui32 giblorb_ID_Dbug = giblorb_make_id('D', 'b', 'u', 'g');
      giblorb_err_t err;
      giblorb_result_t blorbres;
      err = giblorb_load_chunk_by_type(giblorb_get_resource_map(), 
        giblorb_method_FilePos, 
        &blorbres, giblorb_ID_Dbug, 0);
      if (!err) {
        int bres = debugger_load_info_chunk(gamefile, blorbres.data.startpos, blorbres.length);
        if (!bres)
          nonfatal_warning("Unable to parse game info.");
        else
          gameinfoloaded = TRUE;
      }
    }
#endif /* VM_DEBUGGER */
    return TRUE;
  }
  else {
    init_err = "This is neither a Glulx game file nor a Blorb file "
      "which contains one.";
    return TRUE;
  }
}

/* The following only make sense when compiled with a Glk library which offers autosave/autorestore hooks. */

#ifdef GLKUNIX_AUTOSAVE_FEATURES

static void glkunix_game_start()
{
  unsigned char buf[64];
  glk_stream_set_position(gamefile, gamefile_start, seekmode_Start);
  glui32 res = glk_get_buffer_stream(gamefile, (char *)buf, 64);
  if (res == 0) {
    fatal_error("Unable to read game file.");
    return;
  }

  glkunix_set_autosave_signature(buf, res);
}

/* This is the library_select_hook, which will be called every time glk_select() is invoked.
 */
static void glkunix_game_select(glui32 selector, glui32 arg0, glui32 arg1, glui32 arg2)
{
  glui32 lasteventtype = glkunix_get_last_event_type();
  
  /* Do not autosave if we've just started up or autorestored, or if the last event was a rearrange event. (We get rearranges in clusters, and they don't change anything interesting anyhow.) */
  if (lasteventtype == 0xFFFFFFFF
    || lasteventtype == 0xFFFFFFFE)
    return;

  if (pref_autosave_skiparrange && lasteventtype == evtype_Arrange)
    return;
  
  glkunix_do_autosave(selector, arg0, arg1, arg2);
}

static void glkunix_game_autorestore()
{
  int res = glkunix_do_autorestore();
  if (!res)
    fatal_error("Autorestore failed.");
}

#endif /* GLKUNIX_AUTOSAVE_FEATURES */
