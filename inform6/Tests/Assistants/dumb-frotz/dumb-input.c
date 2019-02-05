/* dumb-input.c
 * $Id: dumb-input.c,v 1.5 1998/07/08 03:45:40 al Exp $
 * Copyright 1997,1998 Alpine Petrofsky <alpine@petrofsky.berkeley.ca.us>.
 * Any use permitted provided this notice stays intact.
 */

#include "dumb-frotz.h"

static char runtime_usage[] =
  "DUMB-FROTZ runtime help:\n"
  "  General Commands:\n"
  "    \\help    Show this message.\n"
  "    \\set     Show the current values of runtime settings.\n"
  "    \\s       Show the current contents of the whole screen.\n"
  "    \\d       Discard the part of the input before the cursor.\n"
  "    \\wN      Advance clock N/10 seconds, possibly causing the current\n"
  "                and subsequent inputs to timeout.\n"
  "    \\w       Advance clock by the amount of real time since this input\n"
  "                started (times the current speed factor).\n"
  "    \\t       Advance clock just enough to timeout the current input\n"
  "  Reverse-Video Display Method Settings:\n"
  "    \\rn   none    \\rc   CAPS    \\rd   doublestrike    \\ru   underline\n"
  "    \\rbC  show rv blanks as char C (orthogonal to above modes)\n"
  "  Output Compression Settings:\n"
  "    \\cn      none: show whole screen before every input.\n"
  "    \\cm      max: show only lines that have new nonblank characters.\n"
  "    \\cs      spans: like max, but emit a blank line between each span of\n"
  "                screen lines shown.\n"
  "    \\chN     Hide top N lines (orthogonal to above modes).\n"
  "  Misc Settings:\n"
  "    \\sfX     Set speed factor to X.  (0 = never timeout automatically).\n"
  "    \\mp      Toggle use of MORE prompts\n"
  "    \\ln      Toggle display of line numbers.\n"
  "    \\lt      Toggle display of the line type identification chars.\n"
  "    \\vb      Toggle visual bell.\n"
  "    \\pb      Toggle display of picture outline boxes.\n"
  "    (Toggle commands can be followed by a 1 or 0 to set value ON or OFF.)\n"
  "  Character Escapes:\n"
  "    \\\\  backslash    \\#  backspace    \\[  escape    \\_  return\n"
  "    \\< \\> \\^ \\.  cursor motion        \\1 ..\\0  f1..f10\n"
  "    \\D ..\\X   Standard Frotz hotkeys.  Use \\H (help) to see the list.\n"
  "  Line Type Identification Characters:\n"
  "    Input lines:\n"
  "      untimed  timed\n"
  "      >        T      A regular line-oriented input\n"
  "      )        t      A single-character input\n"
  "      }        D      A line input with some input before the cursor.\n"
  "                         (Use \\d to discard it.)\n"
  "    Output lines:\n"
  "      ]     Output line that contains the cursor.\n"
  "      .     A blank line emitted as part of span compression.\n"
  "            (blank) Any other output line.\n"
;

static float speed = 1;
static bool do_more_prompts = FALSE; /* GN */

enum input_type {
  INPUT_CHAR,
  INPUT_LINE,
  INPUT_LINE_CONTINUED,
};

/* get a character.  Exit with no fuss on EOF.  */
static int xgetchar(void)
{
  int c = getchar();
  if (c == EOF) {
    if (feof(stdin)) {
    /* GN  fprintf(stderr, "\nEOT\n"); */
      if (option_profiling)
        prof_report();
      exit(0);
    }
    os_fatal(strerror(errno));
  }
  return c;
}

/* Read one line, including the newline, into s.  Safely avoids buffer
 * overruns (but that's kind of pointless because there are several
 * other places where I'm not so careful).  */
static void my_getline(char *s)
{
  int c;
  char *p = s;
  while (p < s + INPUT_BUFFER_SIZE - 1)
    if ((*p++ = xgetchar()) == '\n') {
      *p = '\0';
      return;
    }
  p[-1] = '\n';
  p[0] = '\0';
  while ((c = xgetchar()) != '\n')
    ;
  printf("Line too long, truncated to %s\n", s - INPUT_BUFFER_SIZE);
}

/* Translate in place all the escape characters in s.  */
static void translate_special_chars(char *s)
{
  char *src = s, *dest = s;
  while (*src)
    switch(*src++) {
    default: *dest++ = src[-1]; break;
    case '\n': *dest++ = ZC_RETURN; break;
    case '\\':
      switch (*src++) {
      case '\n': *dest++ = ZC_RETURN; break;
      case '\\': *dest++ = '\\'; break;
      case '?': *dest++ = ZC_BACKSPACE; break;
      case '[': *dest++ = ZC_ESCAPE; break;
      case '_': *dest++ = ZC_RETURN; break;
      case '^': *dest++ = ZC_ARROW_UP; break;
      case '.': *dest++ = ZC_ARROW_DOWN; break;
      case '<': *dest++ = ZC_ARROW_LEFT; break;
      case '>': *dest++ = ZC_ARROW_RIGHT; break;
      case 'R': *dest++ = ZC_HKEY_RECORD; break;
      case 'P': *dest++ = ZC_HKEY_PLAYBACK; break;
      case 'S': *dest++ = ZC_HKEY_SEED; break;
      case 'U': *dest++ = ZC_HKEY_UNDO; break;
      case 'N': *dest++ = ZC_HKEY_RESTART; break;
      case 'X': *dest++ = ZC_HKEY_QUIT; break;
      case 'D': *dest++ = ZC_HKEY_DEBUG; break;
      case 'H': *dest++ = ZC_HKEY_HELP; break;
      case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9':
	*dest++ = ZC_FKEY_MIN + src[-1] - '0' - 1; break;
      case '0': *dest++ = ZC_FKEY_MIN + 9; break;
      default:
	fprintf(stderr, "DUMB-FROTZ: unknown escape char: %c\n", src[-1]);
	fprintf(stderr, "Enter \\help to see the list\n");
      }
    }
  *dest = '\0';
}


/* The time in tenths of seconds that the user is ahead of z time.  */
static int time_ahead = 0;

/* Called from os_read_key and os_read_line if they have input from
 * a previous call to dumb_read_line.
 * Returns TRUE if we should timeout rather than use the read-ahead.
 * (because the user is further ahead than the timeout).  */
static bool check_timeout(int timeout)
{
  if ((timeout == 0) || (timeout > time_ahead))
    time_ahead = 0;
  else
    time_ahead -= timeout;
  return time_ahead != 0;
}

/* If val is '0' or '1', set *var accordingly, otherwise toggle it.  */
static void toggle(bool *var, char val)
{
  *var = val == '1' || (val != '0' && !*var);
}

/* Handle input-related user settings and call dumb_output_handle_setting.  */
bool dumb_handle_setting(const char *setting, bool show_cursor, bool startup)
{
  if (!strncmp(setting, "sf", 2)) {
    speed = atof(&setting[2]);
    printf("Speed Factor %g\n", speed);
  } else if (!strncmp(setting, "mp", 2)) {
    toggle(&do_more_prompts, setting[2]);
    printf("More prompts %s\n", do_more_prompts ? "ON" : "OFF");
  } else {
    if (!strcmp(setting, "set")) {
      printf("Speed Factor %g\n", speed);
      printf("More Prompts %s\n", do_more_prompts ? "ON" : "OFF");
    }
    return dumb_output_handle_setting(setting, show_cursor, startup);
  }
  return TRUE;
}

/* Read a line, processing commands (lines that start with a backslash
 * (that isn't the start of a special character)), and write the
 * first non-command to s.
 * Return true if timed-out.  */
static bool dumb_read_line(char *s, char *prompt, bool show_cursor,
			   int timeout, enum input_type type,
			   zchar *continued_line_chars)
{
  time_t start_time;

  if (timeout) {
    if (time_ahead >= timeout) {
      time_ahead -= timeout;
      return TRUE;
    }
    timeout -= time_ahead;
    start_time = time(0);
  }
  time_ahead = 0;

  dumb_show_screen(show_cursor);
  for (;;) {
    char *command;
    if (prompt)
      fputs(prompt, stdout);
    else
      dumb_show_prompt(show_cursor, (timeout ? "tTD" : ")>}")[type]);
    my_getline(s);
    if ((s[0] != '\\') || ((s[1] != '\0') && !islower(s[1]))) {
      /* Is not a command line.  */
      translate_special_chars(s);
      if (timeout) {
	int elapsed = (time(0) - start_time) * 10 * speed;
	if (elapsed > timeout) {
	  time_ahead = elapsed - timeout;
	  return TRUE;
	}
      }
      return FALSE;
    }
    /* Commands.  */

    /* Remove the \ and the terminating newline.  */
    command = s + 1;
    command[strlen(command) - 1] = '\0';
    
    if (!strcmp(command, "t")) {
      if (timeout) {
	time_ahead = 0;
	s[0] = '\0';
	return TRUE;
      }
    } else if (*command == 'w') {
      if (timeout) {
	int elapsed = atoi(&command[1]);
	time_t now = time(0);
	if (elapsed == 0)
	  elapsed = (now - start_time) * 10 * speed;
	if (elapsed >= timeout) {
	  time_ahead = elapsed - timeout;
	  s[0] = '\0';
	  return TRUE;
	}
	timeout -= elapsed;
	start_time = now;
      }
    } else if (!strcmp(command, "d")) {
      if (type != INPUT_LINE_CONTINUED)
	fprintf(stderr, "DUMB-FROTZ: No input to discard\n");
      else {
	dumb_discard_old_input(strlen(continued_line_chars));
	continued_line_chars[0] = '\0';
	type = INPUT_LINE;
      }
    } else if (!strcmp(command, "help")) {
      if (!do_more_prompts)
	fputs(runtime_usage, stdout);
      else {
	char *current_page, *next_page;
	current_page = next_page = runtime_usage;
	for (;;) {
	  int i;
	  for (i = 0; (i < h_screen_rows - 2) && *next_page; i++)
	    next_page = strchr(next_page, '\n') + 1;
	  printf("%.*s", next_page - current_page, current_page);
	  current_page = next_page;
	  if (!*current_page)
	    break;
	  printf("HELP: Type <return> for more, or q <return> to stop: ");
	  my_getline(s);
	  if (!strcmp(s, "q\n"))
	    break;
	}
      }
    } else if (!strcmp(command, "s")) {
	dumb_dump_screen();
    } else if (!dumb_handle_setting(command, show_cursor, FALSE)) {
      fprintf(stderr, "DUMB-FROTZ: unknown command: %s\n", s);
      fprintf(stderr, "Enter \\help to see the list of commands\n");
    }
  }
}

/* Read a line that is not part of z-machine input (more prompts and
 * filename requests).  */
static void dumb_read_misc_line(char *s, char *prompt)
{
  dumb_read_line(s, prompt, 0, 0, 0, 0);
  /* Remove terminating newline */
  s[strlen(s) - 1] = '\0';
}

/* For allowing the user to input in a single line keys to be returned
 * for several consecutive calls to read_char, with no screen update
 * in between.  Useful for traversing menus.  */
static char read_key_buffer[INPUT_BUFFER_SIZE];

/* Similar.  Useful for using function key abbreviations.  */
static char read_line_buffer[INPUT_BUFFER_SIZE];

zchar os_read_key (int timeout, bool show_cursor)
{
  char c;
  int timed_out;

  /* Discard any keys read for line input.  */
  read_line_buffer[0] = '\0';

  if (read_key_buffer[0] == '\0') {
    timed_out = dumb_read_line(read_key_buffer, NULL, show_cursor, timeout,
			       INPUT_CHAR, NULL);
    /* An empty input line is reported as a single CR.
     * If there's anything else in the line, we report only the line's
     * contents and not the terminating CR.  */
    if (strlen(read_key_buffer) > 1)
      read_key_buffer[strlen(read_key_buffer) - 1] = '\0';
  } else
    timed_out = check_timeout(timeout);
    
  if (timed_out)
    return ZC_TIME_OUT;

  c = read_key_buffer[0];
  memmove(read_key_buffer, read_key_buffer + 1, strlen(read_key_buffer));

  /* TODO: error messages for invalid special chars.  */

  return c;
}

zchar os_read_line (int max, zchar *buf, int timeout, int width, int continued)
{
  char *p;
  int terminator;
  static bool timed_out_last_time;
  int timed_out;

  /* Discard any keys read for single key input.  */
  read_key_buffer[0] = '\0';

  /* After timing out, discard any further input unless we're continuing.  */
  if (timed_out_last_time && !continued)
    read_line_buffer[0] = '\0';

  if (read_line_buffer[0] == '\0')
    timed_out = dumb_read_line(read_line_buffer, NULL, TRUE, timeout,
			       buf[0] ? INPUT_LINE_CONTINUED : INPUT_LINE,
			       buf);
  else
    timed_out = check_timeout(timeout);
  
  if (timed_out) {
    timed_out_last_time = TRUE;
    return ZC_TIME_OUT;
  }
    
  /* find the terminating character.  */
  for (p = read_line_buffer;; p++) {
    if (is_terminator(*p)) {
      terminator = *p;
      *p++ = '\0';
      break;
    }
  }

  /* TODO: Truncate to width and max.  */

  /* copy to screen */
  dumb_display_user_input(read_line_buffer);

  /* copy to the buffer and save the rest for next time.  */
  strcat(buf, read_line_buffer);
  p = read_line_buffer + strlen(read_line_buffer) + 1;
  memmove(read_line_buffer, p, strlen(p) + 1);
    
  /* If there was just a newline after the terminating character,
   * don't save it.  */
  if ((read_line_buffer[0] == '\r') && (read_line_buffer[1] == '\0'))
    read_line_buffer[0] = '\0';

  timed_out_last_time = FALSE;
  return terminator;
}

int os_read_file_name (char *file_name, const char *default_name, int flag)
{
  char buf[INPUT_BUFFER_SIZE], prompt[INPUT_BUFFER_SIZE];
  FILE *fp;

  sprintf(prompt, "Please enter a filename [%s]: ", default_name);
  dumb_read_misc_line(buf, prompt);
  if (strlen(buf) > MAX_FILE_NAME) {
    printf("Filename too long\n");
    return FALSE;
  }

  strcpy (file_name, buf[0] ? buf : default_name);

  /* Warn if overwriting a file.  */
  if ((flag == FILE_SAVE || flag == FILE_SAVE_AUX || flag == FILE_RECORD)
      && ((fp = fopen(file_name, "rb")) != NULL)) {
    fclose (fp);
    dumb_read_misc_line(buf, "Overwrite existing file? ");
    return(tolower(buf[0]) == 'y');
  }
  return TRUE;
}

void os_more_prompt (void)
{
  if (do_more_prompts) {
    char buf[INPUT_BUFFER_SIZE];
    dumb_read_misc_line(buf, "***MORE***");
  } else
    dumb_elide_more_prompt();
}

void dumb_init_input(void)
{
  if ((h_version >= V4) && (speed != 0))
    h_config |= CONFIG_TIMEDINPUT;

  if (h_version >= V5)
    h_flags &= ~(MOUSE_FLAG | MENU_FLAG);
}
