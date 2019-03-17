CheapGlk: Cheapass Implementation of the Glk API.

CheapGlk Library: version 1.0.6.
Glk API which this implements: version 0.7.5.
Designed by Andrew Plotkin <erkyrath@eblong.com>
http://eblong.com/zarf/glk/index.html

This is source code for the simplest possible implementation of the Glk
API. It uses stdio.h calls (fopen, putc, getc), but not any of the
curses.h calls (which handle cursor movement and unbuffered keyboard
input.) So there's no way it can support multiple windows, or a status
bar. In fact, this library only allows you to create *one* window at a
time, and that must be a TextBuffer. Fortunately -- well, deliberately
-- TextBuffer windows are very simple; all the library has to be able to
do is printf() straight to stdout.

* Command-line arguments:

CheapGlk can accept command-line arguments both for itself and on behalf
of the underlying program. These are the arguments the library accepts
itself:

    -w NUM, -h NUM: These set the screen width and height manually. This
is only used when trying to "clear" the screen (by printing a bunch of
newlines.)

    -ui: Assume that stdin contains UTF-8 encoded text.
    -uo: Generate UTF-8 encoded text on stdout.
    -u: Both of the above.

    -q: Don't display the "Welcome to CheapGlk" banner before the game.

    -D: Consider "/" to be a debug command prefix; all /commands are
        passed to the game debugger (if it has one).

* Notes on building this mess:

See the top of the Makefile for comments on installation.

When you compile a Glk program and link it with GlkTerm, you must supply
one more file: you must define a function called glkunix_startup_code(),
and an array glkunix_arguments[]. These set up various Unix-specific
options used by the Glk library. There is a sample "glkstart.c" file
included in this package; you should modify it to your needs.

The glkunix_arguments[] array is a list of command-line arguments that
your program can accept. The library will sort these out of the command
line and pass them on to your code. The array structure looks like this:

typedef struct glkunix_argumentlist_struct {
    char *name;
    int argtype;
    char *desc;
} glkunix_argumentlist_t;

extern glkunix_argumentlist_t glkunix_arguments[];

In each entry, name is the option as it would appear on the command line
(including the leading dash, if any.) The desc is a description of the
argument; this is used when the library is printing a list of options.
And argtype is one of the following constants:

    glkunix_arg_NoValue: The argument appears by itself.
    glkunix_arg_ValueFollows: The argument must be followed by another
argument (the value).
    glkunix_arg_ValueCanFollow: The argument may be followed by a value,
optionally. (If the next argument starts with a dash, it is taken to be
a new argument, not the value of this one.)
    glkunix_arg_NumberValue: The argument must be followed by a number,
which may be the next argument or part of this one. (That is, either
"-width 20" or "-width20" will be accepted.)
    glkunix_arg_End: The glkunix_arguments[] array must be terminated
with an entry containing this value.

To accept arbitrary arguments which lack dashes, specify a name of ""
and an argtype of glkunix_arg_ValueFollows.

If you don't care about command-line arguments, you must still define an
empty arguments list, as follows:

glkunix_argumentlist_t glkunix_arguments[] = {
    { NULL, glkunix_arg_End, NULL }
};

Here is a more complete sample list:

glkunix_argumentlist_t glkunix_arguments[] = {
    { "", glkunix_arg_ValueFollows, "filename: The game file to load."
},
    { "-hum", glkunix_arg_ValueFollows, "-hum NUM: Hum some NUM." },
    { "-bom", glkunix_arg_ValueCanFollow, "-bom [ NUM ]: Do a bom (on
the NUM, if given)." },
    { "-goo", glkunix_arg_NoValue, "-goo: Find goo." },
    { "-wob", glkunix_arg_NumberValue, "-wob NUM: Wob NUM times." },
    { NULL, glkunix_arg_End, NULL }
};

This would match the arguments "thingfile -goo -wob8 -bom -hum song".

After the library parses the command line, it does various occult
rituals of initialization, and then calls glkunix_startup_code().

int glkunix_startup_code(glkunix_startup_t *data);

This should return TRUE if everything initializes properly. If it
returns FALSE, the library will shut down without ever calling your
glk_main() function.

The data structure looks like this:

typedef struct glkunix_startup_struct {
    int argc;
    char **argv;
} glkunix_startup_t;

The fields are a standard Unix (argc, argv) list, which contain the
arguments you requested from the command line. In deference to custom,
argv[0] is always the program name.

You can put other startup code in glkunix_startup_code(). This should
generally be limited to finding and opening data files. There are a few
Unix Glk library functions which are convenient for this purpose:

strid_t glkunix_stream_open_pathname(char *pathname, glui32 textmode, 
    glui32 rock);

This opens an arbitrary file, in read-only mode. Note that this function
is *only* available during glkunix_startup_code(). It is inherent
non-portable; it should not and cannot be called from inside glk_main().

void glkunix_set_base_file(char *filename);

This sets the library's idea of the "current directory" for the executing
program. The argument should be the name of a file (not a directory).
When this is set, fileref_create_by_name() will create files in the same
directory as that file, and create_by_prompt() will base default filenames
off of the file. If this is not called, the library works in the Unix
current working directory, and picks reasonable default defaults.

* Notes on the source code:

Functions which begin with glk_ are, of course, Glk API functions. These
are declared in glk.h.

Functions which begin with gli_ are internal to the CheapGlk library
implementation. They don't exist in every Glk library, because different
libraries implement things in different ways. (In fact, they may be
declared differently, or have different meanings, in different Glk
libraries.) These gli_ functions (and other internal constants and
structures) are declared in cheapglk.h.

The files gi_dispa.c and gi_dispa.h are the Glk dispatch layer.
gi_blorb.c,h are the Blorb utility functions, and gi_debug.c,h are
the debug console interface.

As you can see from the code, I've kept a policy of catching every error
that I can possibly catch, and printing visible warnings.

This code should be portable to any C environment which has an ANSI
stdio library. The likely trouble spots are glk_fileref_delete_file()
and glk_fileref_does_file_exist() -- I've implemented them with the
Unix calls unlink() and stat() respectively.

The character-encoding problem is pretty much ignored here (like most
of the more complicated Glk issues.) By default, this reads and writes
the Latin-1 charset. If you use the -u switch, it reads and writes
UTF-8 instead. Most modern terminal windows can do UTF-8. (If you're
using the Terminal app on a Mac, be sure to *uncheck* the "Use option
key as meta key" preference.)

* Version History

1.0.6:
    Declared support for Glk spec 0.7.5.
    Added support for a "debug console". If the -D option is given, lines
    beginning with "/" are considered debug commands. (This is not
    interesting unless the interpreter is compiled with debug support.)

1.0.5:
    Text-mode Unicode file streams are now read and written in UTF-8
    (Glk 0.7.5, although that won't be formalized until 1.0.6).
    Fixed a struct initialization bug in gli_date_to_tm(). (I think this
    caused no problems in practice.)
    Added an optional timegm() function that you can compile in if your
    platform lacks it. (#define NO_TIMEGM_AVAIL)
    Removed old, deprecated tmpnam() call.

1.0.4:
    Updated the Blorb-resource functions to understand FORM chunks
    (Glk 0.7.4 amendment).
    Added stub for autosave/autorestore hooks. (This library does not
    support autosave, however.)

1.0.3:
    Added the Blorb-resource functions (Glk 0.7.4).
    External filenames now follow the new spec recommendations: standard
    filename suffixes, and removing more questionable characters in
    fileref_create_by_name().

1.0.2:
    Added Windows patches for the date-time code.
    Fixed a bug with reading and writing to the same file without a
    reposition operation in between.
    In gi_dispa.c, fixed a notation that was preventing stream_open_memory
    and stream_open_memory_uni from accepting a null array argument.
    Fixed get_line_stream() to include the terminal null when reading
    from a Unicode stream.
    Added stubs for the improved sound functions (Glk 0.7.3).

1.0.1:
    Added the date-time functions (Glk 0.7.2).
    Fixed bugs in Unicode normalization and case-changing (thanks David 
    Fletcher and David Kinder).

1.0.0:
    Support for all the Glk 0.7.1 features that can be supported.
    (Meaning, the Unicode normalization calls.)
    Added -q option to silence banner.
    The library now exits cleanly if stdin closes.
    Added glkunix_stream_open_pathname_gen(), a more general form of
    the pathname opening function in the startup code. (This is needed
    for profiling improvements.)

0.9.1:
    Fixed file-creation bug in glk_stream_open_file().
    Fixed readcount bug in gli_get_line().
    Fixed argument parsing bug ("-w 120" was handled wrong).
    Fixed potential buffer overflow in glk_fileref_create_by_name().

0.9.0:
    Upgraded to Glk API version 0.7.0; added the Unicode functions.
    Added the -u option.

0.8.7:
    Upgraded to Glk API version 0.6.1; i.e., a couple of new gestalt
    selectors.
    Fixed dispatch bug for glk_get_char_stream.

0.8.6:
    Upgraded to Glk API version 0.6.0; i.e., stubs for hyperlinks.

0.8.5:
    Added a fflush(stdout) before input. This shouldn't be necessary in
    ANSI C, according to Stevens, but it seems to be on the Acorn.
    Added glkunix_set_base_file().

0.8.4:
    Added the ability to open a Blorb file, although the library never
    makes use of it. (This allows an interpreter to read a game file
    from Blorb.)

0.8.3:
    Upgraded to Glk API version 0.5.2; i.e., stubs for sound code.
    Made the license a bit friendlier.

0.8.2:
    Fixed a leak (stream objects were never unregistered).
    Added more consistency-checking to the disprock values.

0.8.1:
    Upgraded to Glk API version 0.5.1; i.e., stubs for graphics code.

0.8:
    Upgraded to Glk API version 0.5; added dispatch layer code.

0.7:
    The one true Unix Glk Makefile system.
    Startup code and command-line argument system.

0.5: Alpha release.

* Permissions

The CheapGlk, GiDispa, and GiBlorb libraries, as well as the glk.h header
file, are copyright 1998-2016 by Andrew Plotkin. The GiDebug library is
copyright 2014-2017 by Andrew Plotkin. All are distributed under the MIT
license; see the "LICENSE" file.
