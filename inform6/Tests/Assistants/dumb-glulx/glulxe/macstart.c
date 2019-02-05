/* macstart.c: Macintosh-specific code for Glulxe.
 */

#include "glk.h"
#include "gi_dispa.h"
#include "gi_blorb.h"
#include "glulxe.h"

#include "macglk_startup.h" /* This comes with the MacGlk library. */

static OSType gamefile_types[2] = {'UlxG', 'IFRS'};
extern strid_t gamefile; /* This is defined in glulxe.h. */
extern glui32 gamefile_start, gamefile_len; /* Ditto. */
extern char *init_err, *init_err2;

static Boolean startup_when_selected(FSSpec *file, OSType filetype);
static Boolean startup_when_builtin(void);

Boolean macglk_startup_code(macglk_startup_t *data)
{
  giblorb_err_t err;
  
  data->app_creator = 'gUlx';
  data->startup_model = macglk_model_ChooseOrBuiltIn;
  data->gamefile_types = gamefile_types;
  data->num_gamefile_types = 2;
  data->savefile_type = 'IFZS';
  data->datafile_type = 'UlxD';
  data->gamefile = &gamefile;
  data->when_selected = &startup_when_selected;
  data->when_builtin = &startup_when_builtin;
  
  return TRUE;
}

static Boolean startup_when_selected(FSSpec *file, OSType filetype)
{
    if (filetype == 'UlxG') {
        return locate_gamefile(FALSE);
    }
    else if (filetype == 'IFRS') {
        return locate_gamefile(TRUE);
    }
    else {
        init_err = "This is neither a Glulx game file nor a Blorb file which contains one.";
        return FALSE;
    }
}

static Boolean startup_when_builtin()
{
    unsigned char buf[12];
    int res;

    glk_stream_set_position(gamefile, 0, seekmode_Start);
    res = glk_get_buffer_stream(gamefile, (char *)buf, 12);
    if (!res) {
        init_err = "The data in this stand-alone game is too short to read.";
        return FALSE;
    }
    
    if (buf[0] == 'G' && buf[1] == 'l' && buf[2] == 'u' && buf[3] == 'l') {
        return locate_gamefile(FALSE);
    }
    else if (buf[0] == 'F' && buf[1] == 'O' && buf[2] == 'R' && buf[3] == 'M'
        && buf[8] == 'I' && buf[9] == 'F' && buf[10] == 'R' && buf[11] == 'S') {
        return locate_gamefile(TRUE);
    }
    else {
        init_err = "This is neither a Glulx game file nor a Blorb file which contains one.";
        return FALSE;
    }
}

