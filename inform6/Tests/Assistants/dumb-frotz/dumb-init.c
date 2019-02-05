/* dumb-init.c
 * $Id: dumb-init.c,v 1.4 1998/07/08 03:45:40 al Exp $
 *
 * Copyright 1997,1998 Alva Petrofsky <alva@petrofsky.berkeley.ca.us>.
 * Any use permitted provided this notice stays intact.
 */

#include "dumb-frotz.h"

static char usage[] = "\
\n\
FROTZ V2.32 - interpreter for all Infocom games. Complies with standard\n\
1.0 of Graham Nelson's specification. Written by Stefan Jokisch in 1995-7.\n\
\n\
DUMB-FROTZ V2.32R1 - port for all platforms.  Somewhat complies with standard\n\
9899 of ISO's specification.  Written by Alembic Petrofsky in 1997-8.\n\
\n\
Syntax: frotz [options] story-file [graphics-file]\n\
\n\
  -a      watch attribute setting\n\
  -A      watch attribute testing\n\
  -d xxx  write profiling info to stderr after game ends\n\
             (xxx = path to gameinfo.dbg)\n\
  -D xxx  write profiling info to xxx instead of stderr\n\
  -h #    screen height\n\
  -i      ignore runtime errors\n\
  -I #    interpreter number to report to game\n\
  -o      watch object movement\n\
  -O      watch object locating\n\
  -p      alter piracy opcode\n\
  -P      transliterate latin1 to plain ASCII\n\
  -R xxx  do runtime setting \\xxx before starting\n\
            (this option can be used multiple times)\n\
  -s #    random number seed value\n\
  -S #    transscript width\n\
  -t      set Tandy bit\n\
  -u #    slots for multiple undo\n\
  -w #    screen width\n\
  -x      expand abbreviations g/x/z\n\
\n\
While running, enter \"\\help\" to list the runtime escape sequences.\n\
";

/* A unix-like getopt, but with the names changed to avoid any problems.  */
static int zoptind = 1;
static int zoptopt = 0;
static char *zoptarg = NULL;
static int zgetopt (int argc, char *argv[], const char *options)
{
    static pos = 1;
    const char *p;
    if (zoptind >= argc || argv[zoptind][0] != '-' || argv[zoptind][1] == 0)
	return EOF;
    zoptopt = argv[zoptind][pos++];
    zoptarg = NULL;
    if (argv[zoptind][pos] == 0)
	{ pos = 1; zoptind++; }
    p = strchr (options, zoptopt);
    if (zoptopt == ':' || p == NULL) {
	fputs ("illegal option -- ", stderr);
	goto error;
    } else if (p[1] == ':')
	if (zoptind >= argc) {
	    fputs ("option requires an argument -- ", stderr);
	    goto error;
	} else {
	    zoptarg = argv[zoptind];
	    if (pos != 1)
		zoptarg += pos;
	    pos = 1; zoptind++;
	}
    return zoptopt;
error:
    fputc (zoptopt, stderr);
    fputc ('\n', stderr);
    return '?';
}/* zgetopt */

static int user_screen_width = 75;
static int user_screen_height = 240;
static int user_interpreter_number = -1;
static int user_random_seed = -1;
static int user_tandy_bit = 0;
static char *graphics_filename = NULL;
static bool plain_ascii = FALSE;

void os_process_arguments(int argc, char *argv[]) 
{
    int c;

    /* Parse the options */
    do {
	c = zgetopt(argc, argv, "aAd:D:h:iI:oOpPs:R:S:tu:w:x");
	switch(c) {
	  case 'a': option_attribute_assignment = 1; break;
	  case 'A': option_attribute_testing = 1; break;
	  case 'd': option_profiling = 1; prof_init(zoptarg); break;
	  case 'D': prof_dest(zoptarg); break;
      case 'h': user_screen_height = atoi(zoptarg); break;
	  case 'i': option_ignore_errors = 1; break;
	  case 'I': user_interpreter_number = atoi(zoptarg); break;
	  case 'o': option_object_movement = 1; break;
	  case 'O': option_object_locating = 1; break;
	  case 'p': option_piracy = 1; break;
	  case 'P': plain_ascii = 1; break;
	  case 'R': dumb_handle_setting(zoptarg, FALSE, TRUE); break;
	  case 's': user_random_seed = atoi(zoptarg); break;
	  case 'S': option_script_cols = atoi(zoptarg); break;
	  case 't': user_tandy_bit = 1; break;
	  case 'u': option_undo_slots = atoi(zoptarg); break;
	  case 'w': user_screen_width = atoi(zoptarg); break;
	  case 'x': option_expand_abbreviations = 1; break;
	}
    } while (c != EOF);

    if (((argc - zoptind) != 1) && ((argc - zoptind) != 2)) {
	puts(usage);
	exit(1);
    }
    story_name = argv[zoptind++];
    if (zoptind < argc)
      graphics_filename = argv[zoptind++];
}

void os_init_screen(void)
{
  if (h_version == V3 && user_tandy_bit)
      h_config |= CONFIG_TANDY;

  if (h_version >= V5 && option_undo_slots == 0)
      h_flags &= ~UNDO_FLAG;

  h_screen_rows = user_screen_height;
  h_screen_cols = user_screen_width;
  h_screen_cols_wide = user_screen_width;

  if (user_interpreter_number > 0)
    h_interpreter_number = user_interpreter_number;
  else {
    /* Use ms-dos for v6 (because that's what most people have the
     * graphics files for), but don't use it for v5 (or Beyond Zork
     * will try to use funky characters).  */
    h_interpreter_number = h_version == 6 ? INTERP_MSDOS : INTERP_DEC_20;
  }
  h_interpreter_version = 'F';

  dumb_init_input();
  dumb_init_output();
  dumb_init_pictures(graphics_filename);
}

int os_random_seed (void)
{
  if (user_random_seed == -1)
    /* Use the epoch as seed value */
    return (time(0) & 0x7fff);
  else return user_random_seed;
}

void os_restart_game (int stage) {}

void os_fatal (const char *s)
{
  fprintf(stderr, "\nFatal error: %s\n", s);
  exit(1);
}
