/* dumb-pic.c
 * $Id: dumb-pic.c,v 1.3 1998/07/08 03:45:41 al Exp $
 *
 * Copyright 1997,1998 Alcibiades Petrofsky
 * <alcibiades@petrofsky.berkeley.ca.us>.
 * Any use permitted provided this notice stays intact.
 */
#include "dumb-frotz.h"

#define PIC_FILE_HEADER_FLAGS 1
#define PIC_FILE_HEADER_NUM_IMAGES 4
#define PIC_FILE_HEADER_ENTRY_SIZE 8
#define PIC_FILE_HEADER_VERSION 14

#define PIC_HEADER_NUMBER 0
#define PIC_HEADER_WIDTH 2
#define PIC_HEADER_HEIGHT 4

static struct {
  int z_num;
  int width;
  int height;
  int orig_width;
  int orig_height;
} *pict_info;
static int num_pictures = 0;

static unsigned char lookupb(unsigned char *p, int n) {return p[n];}
static unsigned short lookupw(unsigned char *p, int n)
{
  return (p[n + 1] << 8) | p[n];
}

void dumb_init_pictures (char *filename)
{
  FILE *file = NULL;
  int success = FALSE;
  unsigned char gheader[16];
  unsigned char *raw_info = NULL;
  int i, entry_size, flags;
  float x_scaler, y_scaler;

  do {
    if ((h_version != V6)
	|| !filename
	|| ((file = fopen (filename, "rb")) == NULL)
	|| (fread(&gheader, sizeof (gheader), 1, file) != 1))
      break;

    num_pictures = lookupw(gheader, PIC_FILE_HEADER_NUM_IMAGES);
    entry_size = lookupb(gheader, PIC_FILE_HEADER_ENTRY_SIZE);
    flags = lookupb(gheader, PIC_FILE_HEADER_FLAGS);

    raw_info = malloc(num_pictures * entry_size);

    if (fread(raw_info, num_pictures * entry_size, 1, file) != 1)
      break;

    pict_info = malloc((num_pictures + 1) * sizeof(*pict_info));
    pict_info[0].z_num = 0;
    pict_info[0].height = num_pictures;
    pict_info[0].width = lookupw(gheader, PIC_FILE_HEADER_VERSION);

    y_scaler = h_screen_rows / 200.0;
    x_scaler = h_screen_cols / ((flags & 0x08) ? 640.0 : 320.0);

    /* Copy and scale.  */
    for (i = 1; i <= num_pictures; i++) {
      unsigned char *p = raw_info + entry_size * (i - 1);
      pict_info[i].z_num = lookupw(p, PIC_HEADER_NUMBER);
      pict_info[i].orig_height = lookupw(p, PIC_HEADER_HEIGHT);
      pict_info[i].orig_width = lookupw(p, PIC_HEADER_WIDTH);
      pict_info[i].height = pict_info[i].orig_height * y_scaler + .5;
      pict_info[i].width = pict_info[i].orig_width * x_scaler + .5;
    }
    success = TRUE;
  } while (0);
  if (file)
    fclose(file);
  if (raw_info)
    free(raw_info);
  if (success)
    h_config |= CONFIG_PICTURES;
  else
    {
      h_flags &= ~GRAPHICS_FLAG;
      if (filename)
	fprintf(stderr, "Warning: could not read graphics file %s\n", filename);
    }
}

/* Convert a Z picture number to an index into pict_info.  */
static int z_num_to_index(int n)
{
  int i;
  for (i = 0; i <= num_pictures; i++)
    if (pict_info[i].z_num == n)
      return i;
  return -1;
}

bool os_picture_data(int num, int *height, int *width)
{
  int index;

  *height = 0;
  *width = 0;

  if (!pict_info)
    return FALSE;

  if ((index = z_num_to_index(num)) == -1)
    return FALSE;

  *height = pict_info[index].height;
  *width = pict_info[index].width;

  return TRUE;
}

void os_draw_picture (int num, int row, int col)
{
  int width, height, r, c;
  if (!os_picture_data(num, &height, &width) || !width || !height)
    return;
  col--, row--;
  /* Draw corners */
  dumb_set_picture_cell(row, col, '+');
  dumb_set_picture_cell(row, col + width - 1, '+');
  dumb_set_picture_cell(row + height - 1, col, '+');
  dumb_set_picture_cell(row + height - 1, col + width - 1, '+');
  /* sides */
  for (c = col + 1; c < col + width - 1; c++) {
    dumb_set_picture_cell(row, c, '-');
    dumb_set_picture_cell(row + height - 1, c, '-');
  }
  for (r = row + 1; r < row + height - 1; r++) {
    dumb_set_picture_cell(r, col, '|');
    dumb_set_picture_cell(r, col + width - 1, '|');
  }
  /* body, but for last line */
  for (r = row + 1; r < row + height - 2; r++)
    for (c = col + 1; c < col + width - 1; c++)
      dumb_set_picture_cell(r, c, ':');
  /* Last line of body, including picture number.  */
  if (height >= 3)
    for (c = col + width - 2; c > col; c--, (num /= 10))
      dumb_set_picture_cell(row + height - 2, c, num ? (num % 10 + '0') : ':');
}

int os_peek_colour (void) {return BLACK_COLOUR; }
