#include "glk.h"
#include "gi_blorb.h"

/* We'd like to be able to deal with game files in Blorb files, even
   if we never load a sound or image. So we're willing to set a map
   here. */

static giblorb_map_t *blorbmap = 0; /* NULL */

giblorb_err_t giblorb_set_resource_map(strid_t file)
{
  giblorb_err_t err;
  
  err = giblorb_create_map(file, &blorbmap);
  if (err) {
    blorbmap = 0; /* NULL */
    return err;
  }
  
  return giblorb_err_None;
}

giblorb_map_t *giblorb_get_resource_map()
{
  return blorbmap;
}
