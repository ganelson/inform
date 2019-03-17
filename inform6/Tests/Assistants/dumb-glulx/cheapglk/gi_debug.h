#ifndef _GI_DEBUG_H
#define _GI_DEBUG_H

/* gi_debug.h: Debug feature layer for Glk API.
    gi_debug version 0.9.5.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glk/

    This file is copyright 2014-7 by Andrew Plotkin. It is
    distributed under the MIT license; see the "LICENSE" file.

    ------------------------------------------------

    The debug module allows a Glk library to send out-of-band debug
    commands to the game program it's linked to. The program returns
    debug output to the library, which can then display it.

    (Note: 98% of the time, the "game program" is an IF interpreter
    such as Glulxe. In such cases, debug commands are handled by the
    interpreter; they do *not* get passed through to the interpreted
    game file. Debug commands may do things like pause, inspect, or
    change the state of the interpreted game.)

    As with all UI decision, the interface of the debug feature is
    left up to the Glk library. Abstractly, we imagine a "debug
    console" window with its own input line and scrolling text output.

    (If at all possible, avoid trying to parse debug commands out of
    regular game input! The CheapGlk library does this, but that's
    because it's cheap. It's much better to provide a separate window
    outside the regular game UI.)

    * Configuration

    The debug feature is cooperative: both the library and the game
    must support it for debug commands to work. This requires a dance
    of #ifdefs to make sure that everything builds in all
    configurations.

    (This is why the gi_debug.c and .h files are so tiny! All they do
    is glue together Glk library and game (interpreter) code.)

    Library side: If the library supports debugging, the
    GIDEBUG_LIBRARY_SUPPORT #define in this header (gi_debug.h) will
    be present (not commented out). By doing this, the library
    declares that it offers the functions gidebug_output() and
    gidebug_pause().

    Older Glk libraries do not include this header at all. Therefore,
    a game (interpreter) should have its own configuration option.
    For example, in Glulxe, you define VM_DEBUGGER when compiling with
    a library that has this header and GIDEBUG_LIBRARY_SUPPORT defined.
    When building with an older library (or a library which comments
    out the GIDEBUG_LIBRARY_SUPPORT line), you don't define VM_DEBUGGER,
    and then the interpreter does not attempt to call debug APIs.

    Game (interpreter) side: If the interpreter supports debug commands,
    it should call gidebug_debugging_available() in its startup code.
    (See unixstrt.c in the Glulxe source.) If it does not do this, the
    library knows that debug commands cannot be handled; it should
    disable or hide the "debug console" UI.

    * Game responsibilities

    When the game calls gidebug_debugging_available(), it passes two
    callbacks: one to handle debug commands, and one to be notified
    at various points in the game's life-cycle. (See below.)

    The command callback should execute the command. The syntax of
    debug commands is entirely up to the game. Any results should be
    reported via gidebug_output(), which will display them in the
    debug console.

    The cycle callback is optional. The game might use it to compute
    command timing and report it via gidebug_output().

    The game may call gidebug_output() at any time; it doesn't have to
    be the result of a command. For example, a game crash message could
    be reported this way. However, remember that not all Glk libraries
    support the debug console; even if it exists, the player might not
    be watching it. Assume that game authors know about the debug system,
    but players in general do not.

    The game may call gidebug_pause() to stop execution for debugging.
    (Glulxe does this on any crash, or if the game hits a @debugtrap
    opcode.) This function accepts and executes debugging commands
    until the user signals that it's time to continue execution.

    * Library responsibilities

    The library must implement gidebug_output(), to send a line of
    text to the debug console, and gidebug_pause(), to stop and handle
    debug commands, as described above.

    When the user enters a command in the debug console, the library
    should pass it (as a string) to gidebug_perform_command(). It
    will be relayed to the game's command callback.

    The library should call gidebug_announce_cycle() at various points
    in the game's life-cycle. The argument will be relayed to the
    game's cycle callback.

    The library should call and pass...

    - gidebug_cycle_Start: just before glk_main() begins
    - gidebug_cycle_End: when glk_exit() is called or glk_main() returns
    - gidebug_cycle_InputWait: when glk_select() begins
    - gidebug_cycle_InputAccept: when glk_select() returns
    - gidebug_cycle_DebugPause: when gidebug_pause() begins
    - gidebug_cycle_DebugUnpause: when gidebug_pause() ends
    
*/


/* Uncomment if the library supports a UI for debug commands.
   Comment it out if the library doesn't. */
#define GIDEBUG_LIBRARY_SUPPORT (1)

typedef enum gidebug_cycle_enum {
    gidebug_cycle_Start        = 1,
    gidebug_cycle_End          = 2,
    gidebug_cycle_InputWait    = 3,
    gidebug_cycle_InputAccept  = 4,
    gidebug_cycle_DebugPause   = 5,
    gidebug_cycle_DebugUnpause = 6,
} gidebug_cycle;

typedef int (*gidebug_cmd_handler)(char *text);
typedef void (*gidebug_cycle_handler)(int cycle);

/* The gidebug-layer functions are always available (assuming this header
   exists!) The game should have a compile-time option (e.g. VM_DEBUGGER)
   so as not to rely on this header. */

/* The game calls this if it offers debug commands. (The library may
   or may not make use of them.)

   The cmdhandler argument must be a function that accepts a debug
   command (a UTF-8 string) and executes it, displaying output via
   gidebug_output(). The function should return nonzero for a "continue"
   command (only relevant inside gidebug_pause()).

   The cyclehandler argument should be a function to be notified
   when the game starts, stops, and blocks for input. (This is optional;
   pass NULL if not needed.)
*/
extern void gidebug_debugging_available(gidebug_cmd_handler cmdhandler, gidebug_cycle_handler cyclehandler);

/* The library calls this to check whether the game accepts debug commands.
   (Returns nonzero if the game has called gidebug_debugging_available().
   If this returns zero, the library should disable or hide the debug
   console.)
*/
extern int gidebug_debugging_is_available(void);

/* The library calls this when the user enters a command in the debug
   console. The command will be passed along to the game's cmdhandler,
   if one was supplied. This will return nonzero for a "continue"
   command (only relevant inside gidebug_pause()).

   This may only be called when the game is waiting for input! This
   means one of two circumstances: while inside glk_select(), or
   while inside gidebug_pause(). If you call it at any other time,
   you've made some kind of horrible threading mistake.
*/
extern int gidebug_perform_command(char *cmd);

/* The library calls this at various points in the game's life-cycle.
   The argument will be passed along to the game's cyclehandler,
   if one was supplied.
*/
extern void gidebug_announce_cycle(gidebug_cycle cycle);

#if GIDEBUG_LIBRARY_SUPPORT

/* These functions must be implemented in the library. (If the library
   has declared debug support.) */

/* Send a line of text to the debug console. The text will be a single line
   (no newlines), in UTF-8. 
*/
extern void gidebug_output(char *text);

/* Block and wait for debug commands. The library should accept debug
   commands and pass them to gidebug_perform_command(), repeatedly,
   until that function returns nonzero. It may also stop of its own
   accord (say, when an "unpause" menu item is triggered).

   This should call gidebug_announce_cycle(gidebug_cycle_DebugPause)
   upon entry, and the same with gidebug_cycle_DebugUnpause upon exit.
*/
extern void gidebug_pause(void);

#endif /* GIDEBUG_LIBRARY_SUPPORT */

#endif /* _GI_DEBUG_H */
