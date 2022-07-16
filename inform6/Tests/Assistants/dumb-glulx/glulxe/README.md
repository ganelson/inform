# Glulxe: the Glulx VM interpreter

- Version 0.6.0
- Designed by Andrew Plotkin <erkyrath@eblong.com>
- [Glulx home page][glulx]

[glulx]: http://eblong.com/zarf/glulx/index.html
[glk]: http://eblong.com/zarf/glk/index.html

## Compiling

Since this is a Glk program, it must be built with a Glk library. See
the [Glk home page][glk].

The Unix Makefile that comes with this package is designed to link any
of the Unix libraries (CheapGlk, GlkTerm, RemGlk, etc.) You'll have to go
into the Makefile and set three variables to find the library. There are
instructions at the top of the Makefile. Then just type

    make glulxe

That should suffice. When the program is built, type

    ./glulxe filename.ulx

where "filename.ulx" is a Glulx game file to execute.

To build this program with a Mac or Windows interface, or any other 
interface, you'll need the appropriate Glk library.

This program supports floating-point operations, which are implemented
using the standard C99 math functions. The Makefile uses "-lm" to link
these in. If your platform does not support these functions, you can
comment out the "#define FLOAT_SUPPORT" line in glulxe.h.

If you define the VM_DEBUGGER symbol (uncomment the "#define VM_DEBUGGER"
line in glulxe.h), you must include the libxml2 library. See the
XMLLIB definition in the Makefile.

## Autosave

This interpreter supports autosave if the Glk library does. Currently
only two do: RemGlk and IosGlk. (The latter is no longer supported on
modern iOS, so RemGlk is your only real option.)

The --autosave option tells the interpreter to write out autosave
files at the end of each turn. The --autorestore tells it to load
those files at startup time, thus starting the game where it was last
autosaved. Note that --autosave will overwrite the autosave files if
present, but you should not use --autorestore unless the files exist.

There are two autosave files, by default kept in the current directory
and named "autosave.json" and "autosave.glksave". You can change the
directory with --autodir and the base filename with --autoname.

In some contexts it is useful for every game to have a unique autosave
location. You can do this by giving an --autoname value with a hash
mark, e.g.:

    ./glulxe --autosave --autoname auto-# filename.ulx

The # character will be replaced with a (long) hex string that
uniquely identifies the game file. (Pretty uniquely, at least. It's
not a cryptographically strong hash.)

Autosave covers two slightly different scenarios:

### Hedging against the possibility of process termination

This was how the iOS interpreters work (worked). The app would start
and run normally, but it *could* be killed at any time (when in the
background). Therefore, we autosave every turn. At startup time, if
autosave files exist, we restore them and continue play.

To operate in this mode in a Unix environment:

    ./glulxe --autosave --autoskiparrange filename.ulx

The --autosave argument causes an autosave every turn. The
--autoskiparrange argument skips this on Arrange (window resize)
events. (We may get several Arrange events in a row, and they don't
represent progress that a player would care about losing.)

When relaunching, if autosave files exist, do:

    ./glulxe --autosave --autoskiparrange --autorestore -autometrics filename.ulx

The --autorestore arguments loads the autosave. The -autometrics
argument (a RemGlk argument, hence the single dash) tells RemGlk to
skip the step of waiting for an Init event with metrics. (This is not
needed because the game will already be in progress. But you can send
a normal Arrange event if you think your window size might be
different from the autosave state.)

### Single-turn operation

This mode allows you to play a game without keeping a long-term process
active. On every player input, the interpreter will launch, autorestore,
process the input, autosave, and exit.

To operate in this mode in a Unix environment:

    ./glulxe --autosave -singleturn filename.ulx

The -singleturn argument (a RemGlk argument) tells the interpreter to
exit as soon as an output stanza is generated. When you pass in the
initial Init event, the interpreter will process the start-of-game
activity, display the initial window state, and exit.

When relaunching, if autosave files exist, do:

    ./glulxe --autosave --autorestore -singleturn -autometrics filename.ulx

You should only do this when the UI has a player input ready to process.
Launch the game and pass in the input. The interpreter will process it,
display the update, and then (without delay) exit.

## Version

0.6.0 (Jun 25, 2022):
- Added @hasundo and @discardundo opcodes. (Glulx spec 3.1.3.)
- Added autosave support to the Unix startup code. (Previously the
  autosave support only existed in the iOS startup code, which was
  ObjC.) Autosave now works with the RemGlk library.
- Added an --undo argument to set the number of undo states.
- Fixed a bug where accelerated functions could write error messages
  to Glk regardless of the current I/O system.
- Added array bounds checking on stack access.
- Added a guard against too-deep recursion when creating the string
  cache.

0.5.4 (Jan 23, 2017):

- Added an internal debugger. Compile with "#define VM_DEBUGGER" 
  (and a debug-supporting Glk library) to use it.
- Expanded the TOLERATE_SUPERGLUS_BUG behavior to tolerate more
  Superglus game files.

0.5.3 (Oct 25, 2016):

- Turn on SERIALIZE_CACHE_RAM in the default build. This speeds up
  save and save-undo operations.
- Other tweaks to speed up launch, restart, restore, etc.
- Fixed a bug where accelerated functions were not being autosaved.
  (Only relevant for iOS, currently.)
- When profiling, restore/restore-undo operations will now fail
  (and the game will continue) instead of causing a fatal error.
- Added a build option to tolerate the Superglus bug where (very old)
  game files would try to write to memory address zero. (Not on by
  default.)
- Switched from my old ad-hoc license to the MIT license.

0.5.2 (Mar 27, 2014):

- Added acceleration functions 8 through 13, which work correctly when
  NUM_ATTR_BYTES is changed.

0.5.1 (Mar 10, 2013):

- Fixed a bug in glkop.c that prevented get_buffer_stream() from
  working right.
- Updated profile-analyze.py to understand the upcoming, updated I6
  debug file format. (See http://inform7.com/mantis/view.php?id=1073)
  The old format is still supported.

0.5.0 (Oct 18, 2012):

- Turned on memory-range checking in the default build. (Should have
  done this years ago.)
- Fixed a bug where @setmemsize could crash an open char memory stream
  or char line input request.
- Updated glkop.c to handle arrays of Glk objects. (This is needed to
  support glk_schannel_play_multi().)
- Added hooks for the library to execute at startup and select time.
- Added a hook which allows the library to get and pass on a game ID
  string.
- Clean up all memory allocation when the VM exits.

0.4.7 (Oct 10, 2011):

- Abstracted powf() to an osdepend wrapper. (Needed for Windows.)
- Fixed a @ceil bug, for some C math libraries.
- Improved the profiling system in several ways.
- Fixed a bug in glkop.c dispatching, to do with optional array
  arguments.

0.4.6 (Aug 17, 2010):

- Added floating-point math feature.
- Updated winstart.c. (Thanks David Kinder.)
- Fixed @random even more, on Windows.
- @verify works right on game files with extended memory.
- @getiosys works right when the two store operands are different
  variable types. (E.g., one local and one global.)

0.4.5 (Nov 23, 2009):

- VERIFY_MEMORY_ACCESS now detects writes to the ROM section of memory.
- Fixed off-by-eight bug in @astorebit and @aloadbit with negative bit
  numbers.
- Fixed an obscure bug with division and modulo of $80000000. (Thanks 
  Evin Robertson.)
- Fixed an extremely obscure problem with changing I/O mode in the middle
  of printing a number.
- Glk array/string operations are now checked for memory overflows
  (though not for ROM writing). This generates a warning at present;
  in the future, it will be a fatal error.
- Better fix for the @random bug.

0.4.4 (Mar 11, 2009):

- Added profiling code, which is turned off by default. To compile it 
  in, define VM_PROFILING in Makefile or in glulxe.h.
- Added function-accleration feature.
- Fixed bug where @random 0 was returning only positive numbers.

0.4.3 (Jan 23, 2008):

- Verify the presence of Unicode calls in the Glk library at runtime.
  (Thanks Simon Baldwin.)
- Added a compile-time option to check for invalid memory accesses.
  (This is slower, but safer. Define VERIFY_MEMORY_ACCESS in Makefile
  or in glulxe.h. Thanks Evin Robertson.)
- Fixed a memory leak of undo states. (Thanks Matthew Wightman.)
- Fixed a linked-list handling error for Glk unicode arrays. (Thanks
  David Kinder.)

0.4.2 (Feb 15, 2007):

- Fixed a bug that preventing compiling with old (pre-Unicode) Glk
  libraries.

0.4.1 (Feb 11, 2007):

- Added array copy and heap allocation functionality. (Glulx spec 
  3.1.0.)

0.4.0 (Aug 13, 2006):

- Added Unicode functionality. (Glulx spec 3.0.0.)

0.3.5 (Aug 24, 2000):

- Fixed El-Stupido bug in the modulo opcode.

0.3.4 (Jul 11, 2000):

- Finally supports string arguments to Glk calls.

0.3.3 (Mar 29, 2000):

- Added setiosys, getiosys opcodes.
- Fixed bug in binarysearch.

0.3.2 (Feb 21, 2000):

- Added search, jumpabs, callf, and gestalt opcodes.

0.3.1 (Aug 23, 1999):

- Startup code now handles Blorb files correctly.

0.3.0 (Aug 17, 1999):

- Added support for compressed strings.

0.2.2 (Jun 15, 1999):

- Another pre-release version.

0.2.0 (May 30, 1999):

- A pre-release version.

## Permissions

The source code in this package is copyright 1999-2016 by Andrew Plotkin.
It is distributed under the MIT license; see the "[LICENSE][]" file.

[LICENSE]: ./LICENSE
