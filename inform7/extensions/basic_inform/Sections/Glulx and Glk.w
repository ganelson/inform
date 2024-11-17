Glulx and Glk.

Support for Glulx and Glk interpreter systems.

@ =
Part Four - Glulx and Glk (for Glulx only)

@h Version numbering.

=
Chapter - Version numbers

To decide which number is the major version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 0)) -).
To decide which number is the minor version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 1)) -).
To decide which number is the patch version of (V - version number):
	(- (VERSION_NUMBER_TY_Extract({V}, 2)) -).

@h Feature testing.
These phrases let us test for various interpreter features.
While most features can use the generic functions, a few need special handling,
and so individual phrases are defined for them.

=
Chapter - Glk and Glulx feature testing

Definition: a glk feature is supported rather than unsupported if I6 routine
	"GlkFeatureTest" says so (it is supported by the interpreter).

To decide what version number is the glk version number/--
	(documented at ph_glkversion):
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glk_Gestalts-->gestalt_Version) -).

Definition: a glulx feature is supported rather than unsupported if I6 routine
	"GlulxFeatureTest" says so (it is supported by the interpreter).

To decide what version number is the glulx version number/--:
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glulx_Gestalts-->GLULX_GESTALT_GlulxVersion) -).

To decide what version number is the interpreter version number/--:
	(- VERSION_NUMBER_TY_NewFromPacked(Cached_Glulx_Gestalts-->GLULX_GESTALT_TerpVersion) -).

@h Glk windows.
Minimal support for Glk windows. Other extensions may extend the kind.

=
Chapter - Glk windows

A Glk window is a kind of abstract object.
The glk window kind is accessible to Inter as "K_Glk_Window".
The specification of a glk window is "Models the Glk window system."

A glk window has a glk window type called the window type.
The window type property translates into Inter as "glk_window_type".

A glk window has a number called the rock number.
The rock number property translates into Inter as "glk_rock".

A glk window has a number called the glk window handle.
The glk window handle property translates into Inter as "glk_ref".

Definition: a glk window is on-screen rather than off-screen if the glk window handle of it is not 0.

@ Setting window types is quite verbose, so we have some subkinds to make it easier.

=
A graphics window is a kind of glk window.
The window type of a graphics window is graphics window type.
A text buffer window is a kind of glk window.
The window type of a text buffer window is text buffer window type.
A text grid window is a kind of glk window.
The window type of a text grid window is text grid window type.

@ Create objects for each of the built in windows.

=
The main window is a text buffer window.
The main window object is accessible to Inter as "Main_Window".

The status window is a text grid window.
The status window object is accessible to Inter as "Status_Window".

The quote window is a text buffer window.
The quote window object is accessible to Inter as "Quote_Window".

@h Basic window functions.
Some basic Glk window functions will be supported out of the box, but others will
require extensions.

=
Section - Glk windows

To clear (win - a glk window)
	(documented at ph_glkwindowclear):
	(- WindowClear({win}); -).

To focus (win - a glk window)
	(documented at ph_glkwindowfocus):
	(- WindowFocus({win}); -).

To decide what number is the height of (win - a glk window)
	(documented at ph_glkwindowheight):
	(- WindowGetSize({win}, 1) -).

To decide what number is the width of (win - a glk window)
	(documented at ph_glkwindowwidth):
	(- WindowGetSize({win}, 0) -).

To set (win - a glk window) cursor to row (row - a number) and/-- column/col (col - a number)
	(documented at ph_glksetcursor):
	(- WindowMoveCursor({win}, {col}, {row}); -).

@h Glk events.
Glk events can be handled with the glk event handling rules.

=
Chapter - Glk events

To decide what glk event is (evtype - glk event type) glk event:
	(- GLK_EVENT_TY_New({-new: glk event}, {evtype}) -).

To decide what glk event is a/-- character event with (C - unicode character):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, 0, MapUnicodeToGlkKeyCode({C})) -).
To decide what glk event is a/-- character event with (C - unicode character) in (win - glk window)
	(documented at ph_glkcharacterevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, {win}, MapUnicodeToGlkKeyCode({C})) -).

To decide what glk event is a/-- line event with (T - text):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, 0, 0, 0, {-by-reference:T}) -).
To decide what glk event is a/-- line event with (T - text) in (win - glk window)
	(documented at ph_glklineevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, {win}, 0, 0, {-by-reference:T}) -).

To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/--:
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/-- in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number) in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).

To decide what glk event is a/-- hyperlink event for/of/with (val - number):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, 0, {val}) -).
To decide what glk event is a/-- hyperlink event for/of/with (val - number) in (win - glk window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, {win}, {val}) -).

To decide what glk event type is type of (ev - glk event)
	(documented at ph_glkeventtype):
	(- GLK_EVENT_TY_Type({ev}) -).

To decide what glk window is window of (ev - glk event)
	(documented at ph_glkeventwindow):
	(- GLK_EVENT_TY_Window({ev}) -).

To decide what unicode character is the character value of (ev - glk event)
	(documented at ph_glkeventcharactervalue):
	(- GLK_EVENT_TY_Value1({ev}, evtype_CharInput) -).

To decide what number is the x coordinate of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}, evtype_MouseInput) -).
To decide what number is the y coordinate of (ev - glk event):
	(- GLK_EVENT_TY_Value2({ev}) -).
To decide what number is the row of (ev - glk event):
	(- GLK_EVENT_TY_Value2({ev}) -).
To decide what number is the column/col of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}, evtype_MouseInput) -).

To decide what number is the hyperlink value of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}, evtype_Hyperlink) -).

To decide what text is the text of (ev - glk event)
	(documented at ph_glkeventtextvalue):
	(- GLK_EVENT_TY_Text({ev}, {-new: text}) -).

@ And now the glk event handling rules themselves.

=
The glk event handling rules is a glk event type based rulebook.
The glk event handling rules is accessible to Inter as "GLK_EVENT_HANDLING_RB".

The glk event handling rulebook has a glk event called the event.

The current glk event initialiser is a glk event variable.
The current glk event initialiser variable is defined by Inter as "current_glk_event".

Very first glk event handling rule for a glk event type
	(this is the set glk event processing variables rule):
	now the event is the current glk event initialiser.

To handle (ev - glk event):
	(- GLK_EVENT_TY_Handle_Instead({ev}); rtrue; -).

Glk event handling rule for a screen resize event (this is the redraw the status line rule):
	redraw the status window;

@h Suspending input.
These properties and phrases allow the author to suspend and resume input requests.

=
Chapter - Suspending and resuming input

A glk window has a text input status.
The text input status property translates into Inter as "text_input_status".
A glk window can be requesting hyperlink input.
The requesting hyperlink input property translates into Inter as "requesting_hyperlink".
A glk window can be requesting mouse input.
The requesting mouse input property translates into Inter as "requesting_mouse".

To suspend text input in (win - a glk window), without input echoing:
	(- SuspendTextInput({win}, {phrase options}); -).

To resume text input in (win - a glk window):
	(- ResumeTextInput({win}); -).

To decide what text is the current line input of (w - glk window):
	(- WindowBufferCopyToText({w}, {-new:text}) -).

To set the current line input of (w - glk window) to (t - text):
	(- WindowBufferSet({w}, {-by-reference:t}); -).

@h Glk object recovery.
These rules are a low level system for managing Glk references. When a Glulx
game restarts and restores, the current Glk IO state is not reset. All the old
windows, sound channels etc. will be kept as they were, even though the game file
might be expecting a different state. This extension allows Inform 7 game files
to ensure that the IO state is as it should be. It does this in three stages:

(a) The "reset glk references rules" is run. Rules should be added to reset all
Glk references as if none existed.

(b) The "identify glk windows rules" etc. are run. These rulebooks will be run
once for each Glk IO object which currently exists. Objects can be identified
through the current glk object rock number and current glk object reference
number variables.

(c) The "glk object updating rules" is run. Rules should be added to correct the
Glk IO state by, for example, closing windows which shouldn't exist, and opening
windows which should but currently do not.

=
Chapter - Glk object recovery

The current glk object rock number is a number that varies.
The current glk object rock number variable translates into Inter as "current_glk_object_rock".
The current glk object reference number is a number that varies.
The current glk object reference number variable translates into Inter as "current_glk_object_reference".

The reset glk references rules is a rulebook.
The reset glk references rules is accessible to Inter as "RESET_GLK_REFERENCES_RB".
The identify glk windows rules is a rulebook.
The identify glk windows rules is accessible to Inter as "IDENTIFY_WINDOWS_RB".
The identify glk streams rules is a rulebook.
The identify glk streams rules is accessible to Inter as "IDENTIFY_STREAMS_RB".
The identify glk filerefs rules is a rulebook.
The identify glk filerefs rules is accessible to Inter as "IDENTIFY_FILEREFS_RB".
The identify glk sound channels rules is a rulebook.
The identify glk sound channels rules is accessible to Inter as "IDENTIFY_SCHANNELS_RB".
The glk object updating rules is a rulebook.
The glk object updating rules is accessible to Inter as "GLK_OBJECT_UPDATING_RB".

@ And the standard rules, which may be replaced by extensions.

=
The reset glk references for built in objects rule is listed first in the reset glk references rules.
The reset glk references for built in objects rule translates into Inter as "RESET_GLK_REFERENCES_R".

The cache gestalts rule is listed in the reset glk references rules.
The cache gestalts rule translates into Inter as "CACHE_GESTALTS_R".

The identify built in windows rule is listed first in the identify glk windows rules.
The identify built in windows rule translates into Inter as "IDENTIFY_WINDOWS_R".

The identify built in streams rule is listed first in the identify glk streams rules.
The identify built in streams rule translates into Inter as "IDENTIFY_STREAMS_R".

The identify built in filerefs rule is listed first in the identify glk filerefs rules.
The identify built in filerefs rule translates into Inter as "IDENTIFY_FILEREFS_R".

The identify built in sound channels rule is listed first in the identify glk sound channels rules.
The identify built in sound channels rule translates into Inter as "IDENTIFY_SCHANNELS_R".

The stop built in sound channels rule is listed in the glk object updating rules.
The stop built in sound channels rule translates into Inter as "STOP_SCHANNELS_R".
