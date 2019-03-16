Command-Line Usage.

A brief note on using Inform 7 at the command line.

@h Disclaimer.
This is not documentation on the Inform language or its user-interface apps:
it's a technical note on how the command-line tool inside those apps is called.

The |inform7| executable has a few ancillary functions, but basically it
takes natural language source text and compiles it to either "inter", an
intermediate-level code, or all the way to Inform 6 source code. In order
to run, it needs access to numerous resources, and many of its command-line
switches exist to specify where those are to be found.

If you are using Inform 7 at the command line, the executable should be
stored at |inform/inform7/Tangled/inform7|. In these notes we will assume
the current working directory is |inform|. To test that it has been built,
try:

	|inform7/Tangled/inform7 -help|

@h Basic usage.
The full range of options is complex, so it seems helpful to start by showing
what the Inform UI apps typically call when the user clicks "Go":

	|inform7/Tangled/inform7 -internal I -external E -project P -format=F|

for suitable pathnames |I|, |E|, |P| and a choice of |F|. To dispose of this
first, |-format=ulx| tells Inform to compile to the Glulx story file, and
|-format=z8| to (version 8 of) the Z-machine.

The project |P| is the directory holding the project to compile, such as
|Bronze.inform|. On MacOS, this will be a bundle, and will look like an
opaque binary file in the Finder, but it is a directory nevertheless.

The directories |I| and |E| tell Inform where to find its resources. Internal
means "inside the app" -- in other words, fixed material supplied with Inform
and always present; external means "outside the app", and is where the user
installs her own choice of extra resources.

@ If no |-external E| is given, Inform behaves as it would in a clean
installation with no external resources available.

If no |-internal I| is given on the command line, Inform 7 tries to find
out where it is installed in the file system. There is no completely foolproof,
cross-platform way to know this (on some Unixes, a program cannot determine
its own location), so Inform decides by the following set of rules:

(a) If the user, at the command line, specified |-at P|, for some path
|P|, then we use that.
(b) Otherwise, if the host operating system can indeed tell us where the
executable is, we use that. This is currently implemented only on MacOS,
Windows and Linux.
(c) Otherwise, if the environment variable |$INFORM7_PATH| exists and is
non-empty, we use that.
(d) And if all else fails, we assume that the location is |inform7|, with
respect to the current working directory.

The default value for |-internal| is then the subdirectory |Internal| of
this location: for example, |inform7/Internal|.

@ If the user of an Inform UI app clicks Release instead of Go, the
command-line switch |-release| is added to the above command. See the main
Inform documentation for what this does.

On some UI apps, there's a menu item "Release for testing...": this should
add |-debug| to |-release|, which causes Inform to include debugging commands
in the story file it generates. (Those commands are ordinarily suppressed
by |-release| to prevent story files accidentally being shipped with them
still in place.)

Similarly, the Settings pane in the app contains a checkbox for "Make
random outcomes predictable when testing": the app achieves this by adding
the switch |-rng| to the above command-line call.

@ If the app has a feature for systematically testing each example in an
extension project, then it should add the switch |-case A| when running
example A through inform7, |-case B| for B, and so on. This ensures that
if the compiler generates Problem messages (i,e., if those tests fail
to compile) then source-reference links will be to the right examples.

For ordinary, non-Extension, projects, this switch should not be used.

@ When the app installs a new extension (in the external area), or is run
for the first time, it should call Inform 7 to perform a "census" of the
available extensions. The compiler then looks through its internal and
external areas, and creates suitable HTML pages showing what it finds,
which it stores in a writeable area of the file system called the "transient"
directory.

The usage for this is:

	|inform7/Tangled/inform7 -internal I -external E -transient T -census|

(The caller has the obligation to provide the Transient directory.)

@h Experimental Inter features.
The options |-export X|, |-import X| and |-inter X| are not final, likely
to change, and not documented.

@h Testing and debugging switches.
The following switches are used only when testing or maintaining Inform,
and are unlikely to be useful to end users. Many of these are, however,
used in the Intest scripts for testing Inform 7 and Inblorb.

(a) |-clock| times the run.
(b) |-crash-all| performs a deliberate hard crash, dividing by zero, in
the event of any Problem message being issues -- this makes it easier to
obtain stack backtraces in a debugger.
(c) |-noindex| skips the production of an Index, which reduces file system
writes in a big testing run, and also saves a little time.
(d) |-noprogress| suppresses console output of the "++ 26% (Binding rulebooks)"
kind.
(e) |-sigils| causes each Problem message to be preceded in console output
by its "sigil", that is, its internal code. A typical sigil is
|PM_PropertyNameTooLong|, where the ubiquitous PM stands for "property
message".
(f) |-require-problem SIGIL| tells Inform to return an exit code of 0 if
exactly this problem message is produced, and 1 otherwise.

@h Prehistory.
Build 1A01 was the first rough draft of a completed compiler: but it did
not synchronise fully with the OS X Inform application until 1G22 and
private beta-testing did not begin until 1J34. Other milestones include
time (1B92), tables (1C86), component parts (1E60), indexing (1F46),
systematic memory allocation (1J53), pattern matching (1M11), the map index
(1P97), extension documentation support (1S39) and activities (1T89). The
first round of testing, a heroic effort by Emily Short and Sonja Kesserich,
came informally to an end at around the 1V50 build, after which a general
rewriting exercise began. Minor changes needed for David Kinder's Windows
port began to be made with 1W80, but the main aims were to increase speed
and to improve clarity of source code. Hashing algorithms adapted to
word-based syntax were introduced in 1Z50; the prototype parser was then
comprehensively rewritten using a unified system to handle ambiguities and
avoid blind alleys. A time trial of 2D52 against 1V59 on the same, very
large, source text showed a speed increase of a factor of four. A second
stage of rewriting, to generalise binary predicates and improve grammatical
accuracy, began with 2D70. By the time of the first public beta release,
3K27, the testing tool |inform-test| had been written (it subsequently
evolved into today's |intest|), and Emily Short's extensive suite of Examples
had been worked into the verification process for builds. The history since
3K27 is recorded in the published change log.
