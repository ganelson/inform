/* files.c: Glulxe file-handling code.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "gi_blorb.h"
#include "glulxe.h"

/* is_gamefile_valid():
   Check guess what.
*/
int is_gamefile_valid()
{
  unsigned char buf[8];
  int res;
  glui32 version;

  glk_stream_set_position(gamefile, gamefile_start, seekmode_Start);
  res = glk_get_buffer_stream(gamefile, (char *)buf, 8);

  if (res != 8) {
    fatal_error("This is too short to be a valid Glulx file.");
    return FALSE;
  }

  if (buf[0] != 'G' || buf[1] != 'l' || buf[2] != 'u' || buf[3] != 'l') {
    fatal_error("This is not a valid Glulx file.");
    return FALSE;
  }

  /* We support version 2.0 through 3.1.*. */

  version = Read4(buf+4);
  if (version < 0x20000) {
    fatal_error("This Glulx file is too old a version to execute.");
    return FALSE;
  }
  if (version >= 0x30200) {
    fatal_error("This Glulx file is too new a version to execute.");
    return FALSE;
  }

  return TRUE;
}

/* locate_gamefile: 
   Given that gamefile contains a Glk stream, which may be a Glulx
   file or a Blorb archive containing one, locate the beginning and
   end of the Glulx data.
*/
int locate_gamefile(int isblorb)
{
  if (!isblorb) {
    /* The simple case. A bare Glulx file was opened, so we don't use
       Blorb at all. */
    gamefile_start = 0;
    glk_stream_set_position(gamefile, 0, seekmode_End);
    gamefile_len = glk_stream_get_position(gamefile);
    return TRUE;
  }
  else {
    /* A Blorb file. We now have to open it and find the Glulx chunk. */
    giblorb_err_t err;
    giblorb_result_t blorbres;
    giblorb_map_t *map;

    err = giblorb_set_resource_map(gamefile);
    if (err) {
      init_err = "This Blorb file seems to be invalid.";
      return FALSE;
    }
    map = giblorb_get_resource_map();
    err = giblorb_load_resource(map, giblorb_method_FilePos, 
      &blorbres, giblorb_ID_Exec, 0);
    if (err) {
      init_err = "This Blorb file does not contain an executable Glulx chunk.";
      return FALSE;
    }
    if (blorbres.chunktype != giblorb_make_id('G', 'L', 'U', 'L')) {
      init_err = "This Blorb file contains an executable chunk, but it is not a Glulx file.";
      return FALSE;
    }
    gamefile_start = blorbres.data.startpos;
    gamefile_len = blorbres.length;
    return TRUE;
  }
}

