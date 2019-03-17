/* gi_debug.c: Debug feature layer for Glk API.
    gi_debug version 0.9.5.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glk/

    This file is copyright 2014-7 by Andrew Plotkin. It is
    distributed under the MIT license; see the "LICENSE" file.
*/

#include "glk.h"
#include "gi_debug.h"

#ifndef NULL
#define NULL 0
#endif

static gidebug_cmd_handler debug_cmd_handler = NULL;
static gidebug_cycle_handler debug_cycle_handler = NULL;

void gidebug_debugging_available(gidebug_cmd_handler cmdhandler, gidebug_cycle_handler cyclehandler)
{
    debug_cmd_handler = cmdhandler;
    debug_cycle_handler = cyclehandler;
}

int gidebug_debugging_is_available()
{
    return (debug_cmd_handler != NULL);
}

void gidebug_announce_cycle(gidebug_cycle cycle)
{
    if (debug_cycle_handler)
        debug_cycle_handler(cycle);
}

int gidebug_perform_command(char *cmd)
{
    if (!gidebug_debugging_is_available()) {
#if GIDEBUG_LIBRARY_SUPPORT
        gidebug_output("The interpreter does not have a debug feature.");
#endif /* GIDEBUG_LIBRARY_SUPPORT */
        return 1;
    }

    return debug_cmd_handler(cmd);
}

