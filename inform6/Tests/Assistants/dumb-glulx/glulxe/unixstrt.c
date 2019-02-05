/* unixstrt.c: Unix-specific code for Glulxe.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include <string.h>
#include "glk.h"
#include "glulxe.h"
#include "glkstart.h" /* This comes with the Glk library. */

/* The only command-line argument is the filename. And the profiling switch,
   if that's compiled in. The only *two* command-line arguments are... 

   You may wonder why there's no argument for a save file to autorestore
   at startup. That would be nice; unfortunately it can't work. A Glulx
   game expects to set up its Glk environment (@setiosys, open windows,
   etc) before handling a "restore" command. It can't pick up from a
   restored state without that environment in place.
*/
glkunix_argumentlist_t glkunix_arguments[] = {

#if VM_PROFILING
  { "--profile", glkunix_arg_ValueFollows, "Generate profiling information to a file." },
#endif /* VM_PROFILING */

  { "", glkunix_arg_ValueFollows, "filename: The game file to load." },

  { NULL, glkunix_arg_End, NULL }
};

int glkunix_startup_code(glkunix_startup_t *data)
{
  /* It turns out to be more convenient if we return TRUE from here, even 
     when an error occurs, and display an error in glk_main(). */
  int ix;
  char *filename = NULL;
  unsigned char buf[12];
  int res;

  /* Parse out the arguments. They've already been checked for validity,
     and the library-specific ones stripped out.
     As usual for Unix, the zeroth argument is the executable name. */
  for (ix=1; ix<data->argc; ix++) {

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
#endif /* VM_PROFILING */

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

  /* Now we have to check to see if it's a Blorb file. */

  glk_stream_set_position(gamefile, 0, seekmode_Start);
  res = glk_get_buffer_stream(gamefile, (char *)buf, 12);
  if (!res) {
    init_err = "The data in this stand-alone game is too short to read.";
    return TRUE;
  }
    
  if (buf[0] == 'G' && buf[1] == 'l' && buf[2] == 'u' && buf[3] == 'l') {
    locate_gamefile(FALSE);
    return TRUE;
  }
  else if (buf[0] == 'F' && buf[1] == 'O' && buf[2] == 'R' && buf[3] == 'M'
    && buf[8] == 'I' && buf[9] == 'F' && buf[10] == 'R' && buf[11] == 'S') {
    locate_gamefile(TRUE);
    return TRUE;
  }
  else {
    init_err = "This is neither a Glulx game file nor a Blorb file "
      "which contains one.";
    return TRUE;
  }
}

