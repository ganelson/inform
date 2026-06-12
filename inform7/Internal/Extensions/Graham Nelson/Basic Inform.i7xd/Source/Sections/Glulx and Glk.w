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

Note that the name of the Glk window kind is `IO window`. This allows us to
design some phrases to be platform agnostic (with Z-Machine windows).

=
Chapter - Glk windows

An IO window is a kind of abstract object.
The IO window kind is accessible to Inter as "K_Glk_Window".
The specification of an IO window is "Models the Glk window system."

An IO window has a glk window type called the window type.
The window type property translates into Inter as "glk_window_type".

An IO window has a number called the rock number.
The rock number property translates into Inter as "glk_rock".

An IO window has a number called the glk window handle.
The glk window handle property translates into Inter as "glk_ref".

Definition: an IO window is on-screen rather than off-screen if the glk window handle of it is not 0.

@ Setting window types is quite verbose, so we have some subkinds to make it easier.

=
A graphics window is a kind of IO window.
The window type of a graphics window is graphics window type.
A text buffer window is a kind of IO window.
The window type of a text buffer window is text buffer window type.
A text grid window is a kind of IO window.
The window type of a text grid window is text grid window type.

@ Create objects for each of the built in windows.

=
The main window is a text buffer window.
The main window object is accessible to Inter as "Main_Window".

The status window is a text grid window.
The status window object is accessible to Inter as "Status_Window".

The boxed quotation window is a text buffer window.
The boxed quotation window object is accessible to Inter as "Quote_Window".

@h Glk events.
Glk events are now represented with an I7 (block value) kind.
They can be requested with the waiting for a Glk event activity, and handled with
the glk event handling rules.

=
Chapter - Glk events

Definition: a glk event type is windowed if
	it is character event or
	it is line event or
	it is mouse event or
	it is hyperlink event.

Definition: a glk event is windowed if the type of it is windowed.

To decide what glk event is (evtype - glk event type) glk event:
	(- GLK_EVENT_TY_New({-new: glk event}, {evtype}) -).

To decide what glk event is a/-- character event for/of/with (C - unicode character):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, 0, MapUnicodeToGlkKeyCode({C})) -).
To decide what glk event is a/-- character event for/of/with (C - unicode character) in (win - IO window)
	(documented at ph_glkcharacterevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_CharInput, {win}, MapUnicodeToGlkKeyCode({C})) -).

To decide what glk event is a/-- line event for/of/with (T - text):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, 0, 0, 0, {-by-reference:T}) -).
To decide what glk event is a/-- line event for/of/with (T - text) in (win - IO window)
	(documented at ph_glklineevent):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_LineInput, {win}, 0, 0, {-by-reference:T}) -).

To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/--:
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with x (x - number) and/-- y (y - a number) coordinates/-- in (win - IO window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, 0, {x}, {y}) -).
To decide what glk event is a/-- mouse event for/of/with row (y - number) and/-- column/col (x - a number) in (win - IO window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_MouseInput, {win}, {x}, {y}) -).

To decide what glk event is a/-- hyperlink event for/of/with (val - hyperlink token):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, 0, {val}) -).
To decide what glk event is a/-- hyperlink event for/of/with (val - hyperlink token) in (win - IO window):
	(- GLK_EVENT_TY_New({-new: glk event}, evtype_Hyperlink, {win}, {val}) -).

To decide what glk event type is type of (ev - glk event)
	(documented at ph_glkeventtype):
	(- GLK_EVENT_TY_Type({ev}) -).

To decide what IO window is window of (ev - glk event)
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

To decide what hyperlink token is the hyperlink token value of (ev - glk event):
	(- GLK_EVENT_TY_Value1({ev}, evtype_Hyperlink) -).

To decide what text is the text of (ev - glk event)
	(documented at ph_glkeventtextvalue):
	(- GLK_EVENT_TY_Text({ev}, {-new: text}) -).

@ The waiting for a glk event activity allows you to wait for a specific Glk event type. It is
also designed such that calls to Glk events can be safely nested.

=
Section - Requesting and handling events

Waiting for a glk event of something is an activity on glk event types.
The waiting for a glk event activity is accessible to Inter as "GLK_EVENT_WAITING_ACT".

To wait for (evtype - glk event type):
	(- GLK_EVENT_TY_Wait_For({evtype}); -).

To wait for (evtype - glk event type) in (win - IO window):
	(- GLK_EVENT_TY_Wait_For({evtype}, {win}); -).

To decide what glk event is the next (evtype - glk event type) to occur:
	(- GLK_EVENT_TY_Wait_For({evtype}, 0, 0, {-new: glk event}); -).

To decide what glk event is the next (evtype - glk event type) to occur in (win - IO window):
	(- GLK_EVENT_TY_Wait_For({evtype}, {win}, 0, {-new: glk event}); -).

Before waiting for a glk event (this is the draw the status window before waiting for a Glk event rule):
	draw the status window;

The request keyboard input rule is listed last in the before waiting for a glk event rules.
The request keyboard input rule translates into Inter as "REQUEST_KEYBOARD_INPUT_R".

The manually echo line input rule is listed in the after waiting for a glk event rules.
The manually echo line input rule translates into Inter as "MANUALLY_ECHO_LINE_INPUT_R".

The normalise line input whitespace rule is listed in the after waiting for a glk event rules.
The normalise line input whitespace rule translates into Inter as "NORMALISE_LINE_INPUT_R".

@ A couple of phrases for timer events

=
To request timer events every (N - number) milliseconds
	(documented at ph_requesttimer):
	(- glk_request_timer_events({N}); -).

To cancel timer events
	(documented at ph_canceltimer):
	(- glk_request_timer_events(0); -).

@ Events are handled within glk_select through the glk event handling rules.
Note that these rules can be run more than once per waiting activity.

=
The glk event handling rules is a glk event type based rulebook.
The glk event handling rules is accessible to Inter as "GLK_EVENT_HANDLING_RB".

The glk event handling rulebook has a glk event called the event.

The current glk event initialiser is a glk event variable.
The current glk event initialiser variable is defined by Inter as "current_glk_event".

Very first glk event handling rule for a glk event type
	(this is the set glk event processing variables rule):
	now the event is the current glk event initialiser.

To replace current event with (ev - glk event):
	(- GLK_EVENT_TY_Replace_Current({ev}); rtrue; -).

Glk event handling rule for a screen resize event (this is the redraw the status window after the screen is resized rule):
	draw the status window;

@h Hyperlinks.
A simple framework for handling hyperlinks in an interoperable manner.

Hyperlink tags represent each kind of hyperlink that we might want to use.

Hyperlink tokens then combine a hyperlink tag with a value.

=
Chapter - Hyperlinks

To decide what hyperlink token is hyperlink token of (T - hyperlink tag) for/of/with (V - value of kind K):
	(- HYPERLINK_TOKEN_TY_New({T}, {-by-reference:V}, {-strong-kind:K}); -).

To decide what hyperlink token is hyperlink token of (T - hyperlink tag):
	(- HYPERLINK_TOKEN_TY_New({T}, 0, NUMBER_TY); -).

To decide what hyperlink tag is the tag of (tag - hyperlink token):
	(- HYPERLINK_TOKEN_TY_Tag({tag}) -).

To decide what K is the value of (tag - hyperlink token) as a/an (name of kind of value K):
	(- HYPERLINK_TOKEN_TY_Value({tag}) -).

To say link to (T - hyperlink token):
	(- if (Cached_Glk_Gestalts-->gestalt_Hyperlinks) { glk_set_hyperlink({T}); } -).

To say end link:
	(- if (Cached_Glk_Gestalts-->gestalt_Hyperlinks) { glk_set_hyperlink(0); } -).

@ The hyperlink handling rules are how hyperlinks will generally be handled.
The hyperlink token will be automatically processed for the author.

The hyperlink printing rules are for saying a hyperlink token (without
actually generating a hyperlink).

=
The hyperlink handling rules is a hyperlink tag based rulebook.
The hyperlink handling rules is accessible to Inter as "HYPERLINK_HANDLING_RB".

The hyperlink handling rulebook has a hyperlink token called the outcome.

The current hyperlink token is a hyperlink token variable.
The current hyperlink token variable is defined by Inter as "current_hyperlink_token".

Very first hyperlink handling rule for a hyperlink tag
	(this is the set hyperlink handling variables rule):
	now the outcome is the current hyperlink token.

The handle hyperlinks rule is listed in the glk event handling rules.
The handle hyperlinks rule is defined by Inter as "HANDLE_HYPERLINK_R".

The hyperlink printing rules is a hyperlink tag based rulebook.
The hyperlink printing rules is accessible to Inter as "HYPERLINK_REPRESENTATION_RB".
The hyperlink printing rules have default success.

Last hyperlink printing rule for a hyperlink tag (called T) (this is the default hyperlink printing rule):
	say "hyperlink token of [T]";

@ And some built-in hyperlink tags:

- A command replacement hyperlink replaces the entire pending line input with
  a specified text and then submits it, as if the player pressed enter.
- A command appendment hyperlink suspends line input, adds its text to the
  current line input, and then resumes line input.
- A keypress hyperlink converts a hyperlink event into a character event, for
  the specified unicode character.
- A rule hyperlink runs a rule when clicked; that in turn allows you to run any
  other code you like.

=
Command replacement is a hyperlink tag.
The command replacement value is accessible to Inter as "hyperlink_replace".

To decide what hyperlink token is command replacement hyperlink token for (T - text):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_replace, {-by-reference:T}, TEXT_TY); -).

To say link to command (T - text):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_replace, {-by-reference:T}, TEXT_TY, 1); -).

Hyperlink handling rule for command replacement (this is the command replacement hyperlink rule):
	suspend text input in the main window, without input echoing;
	replace current event with a line event with (value of outcome as a text);

Hyperlink printing rule for command replacement (this is the command replacement representation rule):
	say "command replacement hyperlink token for '[value of current hyperlink token as a text]'";

Command appendment is a hyperlink tag.
The command appendment value is accessible to Inter as "hyperlink_append".

To decide what hyperlink token is command appendment hyperlink token for (T - text):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_append, {-by-reference:T}, TEXT_TY); -).

To say link to type (T - text):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_append, {-by-reference:T}, TEXT_TY, 1); -).

Hyperlink handling rule for command appendment (this is the command appendment hyperlink rule):
	suspend text input in the main window, without input echoing;
	let current input be the current line input of the main window;
	set the current line input of the main window to "[unless current input is empty][current input] [end if][value of outcome as a text]";
	resume text input in the main window;

Hyperlink printing rule for command appendment (this is the command appendment representation rule):
	say "command appendment hyperlink token for '[value of current hyperlink token as a text]'";

Keypress hyperlink is a hyperlink tag.
The keypress hyperlink value is accessible to Inter as "hyperlink_keypress".

To decide what hyperlink token is keypress hyperlink token for (C - unicode character):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_keypress, {-by-reference:C}, UNICODE_CHARACTER_TY); -).

To say link to press (C - unicode character):
	say link to keypress hyperlink token for C;

Hyperlink handling rule for a keypress hyperlink (this is the keypress hyperlink rule):
	replace current event with a character event with (value of outcome as a unicode character);

Hyperlink printing rule for keypress hyperlink (this is the keypress hyperlink printing rule):
	say "keypress hyperlink token for [value of current hyperlink token as a unicode character]";

Rule hyperlink is a hyperlink tag.
The rule hyperlink value is accessible to Inter as "hyperlink_rule".

To decide what hyperlink token is rule hyperlink token for (R - rule):
	(- HYPERLINK_TOKEN_TY_New(hyperlink_rule, {-by-reference:R}, RULE_TY); -).

To say link to follow (R - rule):
	say link to rule hyperlink token for R;

Hyperlink handling rule for a rule hyperlink (this is the rule hyperlink rule):
	follow value of outcome as a rule;

Hyperlink printing rule for rule hyperlink (this is the rule hyperlink printing rule):
	say "rule hyperlink token for [value of current hyperlink token as a rule]";

Hyperlink printing rule for null hyperlink (this is the null hyperlink printing rule):
	say "null hyperlink token";

@h Suspending input.
These properties and phrases allow the author to suspend and resume input requests.

=
Chapter - Suspending and resuming input

An IO window has a text input status.
The text input status property translates into Inter as "text_input_status".
An IO window can be requesting mouse input.
The requesting mouse input property translates into Inter as "requesting_mouse".

To suspend text input, without input echoing
	(documented at ph_suspendtextinput):
	(- SuspendTextInput(active_window, {phrase options}); -).

To suspend text input in (win - IO window), without input echoing:
	(- SuspendTextInput({win}, {phrase options}); -).

To resume text input
	(documented at ph_resumetextinput):
	(- ResumeTextInput(active_window); -).

To resume text input in (win - IO window):
	(- ResumeTextInput({win}); -).

To decide what text is the current line input of (w - IO window):
	(- WindowBufferCopyToText({w}, {-new:text}) -).

To set the current line input of (w - IO window) to (t - text):
	(- WindowBufferSet({w}, {-by-reference:t}); -).

@h External Files.
Inform has a quirky level of support for file-handling, which comes out of what
the Glulx virtual machine will support.

See test case `BIP-Files-G`, which has no Z-machine counterpart.

=
Chapter - External Files

Section 1 - Files of Text

To write (T - text) to (FN - external file)
	(documented at ph_writetext):
	(- FileIO_PutContents({FN}, {T}, false); -).
To append (T - text) to (FN - external file)
	(documented at ph_appendtext):
	(- FileIO_PutContents({FN}, {T}, true); -).
To say text of (FN - external file)
	(documented at ph_saytext):
	(- FileIO_PrintContents({FN}); say__p = 1; -).

@ See test case `BIP-FilesOfTables-G`, which has no Z-machine counterpart.

=
Section 2 - Files of Data

To read (filename - external file) into (T - table name)
	(documented at ph_readtable):
	(- FileIO_GetTable({filename}, {T}); -).
To write (filename - external file) from (T - table name)
	(documented at ph_writetable):
	(- FileIO_PutTable({filename}, {T}); -).

@ These are hardly used phrases which are difficult to test convincingly
in our framework, since they defend against independent Inform programs
simultaneously trying to access the same file.

=
Section 3 - File Handling

To decide if (filename - external file) exists
	(documented at ph_fileexists):
	(- (FileIO_Exists({filename}, false)) -).
To decide if ready to read (filename - external file)
	(documented at ph_fileready):
	(- (FileIO_Ready({filename}, false)) -).
To mark (filename - external file) as ready to read
	(documented at ph_markfileready):
	(- FileIO_MarkReady({filename}, true); -).
To mark (filename - external file) as not ready to read
	(documented at ph_markfilenotready):
	(- FileIO_MarkReady({filename}, false); -).

@h Glk object recovery.
These rules are a low level system for managing Glk references. When a Glulx
game restarts and restores, the current Glk IO state is not reset. All the old
windows, sound channels etc. will be kept as they were, even though the game file
might be expecting a different state. This extension allows Inform 7 game files
to ensure that the IO state is as it should be. It does this in three stages:

- The "reset glk references rules" is run. Rules should be added to reset all
Glk references as if none existed.

- The "identify glk windows rules" etc. are run. These rulebooks will be run
once for each Glk IO object which currently exists. Objects can be identified
through the current glk object rock number and current glk object reference
number variables.

- The "glk object updating rules" is run. Rules should be added to correct the
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
