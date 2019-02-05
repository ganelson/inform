/* main.c: Glulxe top-level code.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"

int vm_exited_cleanly = TRUE;
strid_t gamefile = NULL; /* The stream containing the Glulx file. */
glui32 gamefile_start = 0; /* The position within the stream. (This will not 
    be zero if the Glulx file is a chunk inside a Blorb archive.) */
glui32 gamefile_len = 0; /* The length within the stream. */
char *init_err = NULL;
char *init_err2 = NULL;

/* The library_start_hook is called at the beginning of glk_main. This
   is not normally necessary -- the library can do all its setup work
   before calling glk_main -- but iosglk has some weird cases which
   require it. */
static void (*library_start_hook)(void) = NULL;
/* The library_autorestore_hook is called right after the VM's initial
   setup. This is an appropriate time to autorestore an initial game
   state, if the library has that capability. (Currently, only iosglk
   does.) */
static void (*library_autorestore_hook)(void) = NULL;

static winid_t get_error_win(void);
static void stream_hexnum(glsi32 val);

/* glk_main():
   The top-level routine. This does everything, and consequently is
   very simple. 
*/
void glk_main()
{
  vm_exited_cleanly = FALSE;
  
  if (library_start_hook)
    library_start_hook();
  
  if (init_err) {
    fatal_error_2(init_err, init_err2);
    return;
  }

  if (!is_gamefile_valid()) {
    /* The fatal error has already been displayed. */
    return;
  }

  glulx_setrandom(0);
#ifdef FLOAT_SUPPORT
  if (!init_float()) {
    return;
  }
#endif /* FLOAT_SUPPORT */
  if (!init_dispatch()) {
    return;
  }
  if (!init_profile()) {
    return;
  }

  setup_vm();
  if (library_autorestore_hook)
    library_autorestore_hook();
  execute_loop();
  finalize_vm();

  gamefile = NULL;
  gamefile_start = 0;
  gamefile_len = 0;
  init_err = NULL;
  vm_exited_cleanly = TRUE;
  
  profile_quit();
  glk_exit();
}

void set_library_start_hook(void (*func)(void))
{
  library_start_hook = func;
}

void set_library_autorestore_hook(void (*func)(void))
{
  library_autorestore_hook = func;
}

/* get_error_win():
   Return a window in which to display errors. The first time this is called,
   it creates a new window; after that it returns the window it first
   created.
*/
static winid_t get_error_win()
{
  static winid_t errorwin = NULL;

  if (!errorwin) {
    winid_t rootwin = glk_window_get_root();
    if (!rootwin) {
      errorwin = glk_window_open(0, 0, 0, wintype_TextBuffer, 1);
    }
    else {
      errorwin = glk_window_open(rootwin, winmethod_Below | winmethod_Fixed, 
        3, wintype_TextBuffer, 0);
    }
    if (!errorwin)
      errorwin = rootwin;
  }

  return errorwin;
}

/* fatal_error_handler():
   Display an error in the error window, and then exit.
*/
void fatal_error_handler(char *str, char *arg, int useval, glsi32 val)
{
  winid_t win = get_error_win();
  if (win) {
    glk_set_window(win);
    glk_put_string("Glulxe fatal error: ");
    glk_put_string(str);
    if (arg || useval) {
      glk_put_string(" (");
      if (arg)
        glk_put_string(arg);
      if (arg && useval)
        glk_put_string(" ");
      if (useval)
        stream_hexnum(val);
      glk_put_string(")");
    }
    glk_put_string("\n");
  }
  glk_exit();
}

/* nonfatal_warning_handler():
   Display a warning in the error window, and then continue.
*/
void nonfatal_warning_handler(char *str, char *arg, int useval, glsi32 val)
{
  winid_t win = get_error_win();
  if (win) {
    strid_t oldstr = glk_stream_get_current();
    glk_set_window(win);
    glk_put_string("Glulxe warning: ");
    glk_put_string(str);
    if (arg || useval) {
      glk_put_string(" (");
      if (arg)
        glk_put_string(arg);
      if (arg && useval)
        glk_put_string(" ");
      if (useval)
        stream_hexnum(val);
      glk_put_string(")");
    }
    glk_put_string("\n");
    glk_stream_set_current(oldstr);
  }
}

/* stream_hexnum():
   Write a signed integer to the current Glk output stream.
*/
static void stream_hexnum(glsi32 val)
{
  char buf[16];
  glui32 ival;
  int ix;

  if (val == 0) {
    glk_put_char('0');
    return;
  }

  if (val < 0) {
    glk_put_char('-');
    ival = -val;
  }
  else {
    ival = val;
  }

  ix = 0;
  while (ival != 0) {
    buf[ix] = (ival % 16) + '0';
    if (buf[ix] > '9')
      buf[ix] += ('A' - ('9' + 1));
    ix++;
    ival /= 16;
  }

  while (ix) {
    ix--;
    glk_put_char(buf[ix]);
  }
}

