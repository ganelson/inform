Command-Line Usage.

A brief note on using Inform 7 at the command line.

@h Disclaimer.
This is not documentation on the Inform language or its user-interface apps:
it's a technical note on how the command-line tool inside those apps is called.

The |inform7| executable has a few ancillary functions, but basically it
takes natural language source text and compiles it to either "Inter", an
intermediate-level code, or all the way to Inform 6 source code. In order
to run, it needs access to numerous resources, and many of its command-line
switches exist to specify where those are to be found.

If you are using Inform 7 at the command line, things are usually set up so
that Inform 7 is installed in the directory |inform7| with respect to your
current working directory. |inform7| is a composite of various files, and
the executable inside is at |inform7/Tangled/inform7|. To test that it has
been built successfully, try:
= (text as ConsoleText)
	$ inform7/Tangled/inform7 -help

@ When it runs, Inform 7 needs to know where it is installed in the file
system. There is no completely foolproof, cross-platform way to know this
(on some Unixes, a program cannot determine its own location), so Inbuild
decides by the following set of rules:

(a) If the user, at the command line, specified |-at P|, for some path
|P|, then we use that.
(b) Otherwise, if the host operating system can indeed tell us where the
executable is, we use that. This is currently implemented only on MacOS,
Windows and Linux.
(c) Otherwise, if the environment variable |$INFORM7_PATH| exists and is
non-empty, we use that.
(d) And if all else fails, we assume that the location is indeed |inform7|,
with respect to the current working directory.

@h How the UI apps call Inform 7.
The full range of options is complex, so it seems helpful to start by showing
what the Inform UI apps typically call when the user clicks "Go":
= (text as ConsoleText)
	$ inform7/Tangled/inform7 -internal I -external E -project P -format=F
=
for suitable pathnames |I|, |E|, |P| and a choice of |F|.

The format |F| can have quite a complex syntax. It takes the form of a
sequence of criteria divided by slashes. The first will be the name of the
language which //inform7// is writing as its output; the second will be the
architecture used. Thus, |inform6/32d| means "32-bit Inform 6 code with
debugging enabled", and this in practice is what the Inform UI apps make
when Glulx is the preferred virtual machine, as it is by default. But other
alternatives are available at the command line, and it's also possible for
|-format| to specify a semantic version number for the target, or some
compilation options. See //arch// for a fuller description.

In previous releases of Inform, |-format=F| had a cruder syntax in which only
|-format=ulx|, |-format=z5| and |-format=z8| were allowed. Those are still
recognised, but deprecated. Inform will print a warning about this and supply
the equivalent modern notation if one is used.

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

It is possible to specify additional sources of extensions and other
resources with |-nest N| for some directory |N|: for a fuller explanation,
see the Inbuild documentation.

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

@ The Inter code generated by Inform 7 makes use of "kits" of pre-compiled
Inter code, which have to be merged in. This process is carried out by a copy
of the Inter tool inside |inform7|, and the choice of which kits are needed is
managed by Inbuild. The |inform7| command line allows this process to be
customised. In particular, |-basic| will cause Inform to compile
a "basic" project with no command parser or world model, and in general no
interactive fiction-related infrastructure: it converts Inform into a
general-purpose programming language. For examples of Basic Inform programs,
see the test cases in |inform7/Tests/Test Basic|.

|-basic| is actually just an abbreviation for |-kit BasicInformKit|, and
other kits can also be included. See //inbuild// for more on kits.

The three commands |-pipeline|, |-pipeline-file| and |-variable| control
the way Inter performs code-generation on the output from |inform7|. Again,
these needn't be used in normal circumstances, because the defaults are fine.
They have the same meaning as for the |inter| tool, so see its documentation
for more.

@ The switch |-source F| tells Inform to read source text from the file |F|
rather than from its normal location inside the project bundle. Note that if
this switch is used from within the GUI app, by means of a settings file (see
below), then on some platforms there may be permissions errors if |F| does
not lie inside the bundle or Materials folder -- in particular, sandboxing
for the Mac App Store editions of the executables has this effect.

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
= (text as ConsoleText)
	$ inform7/Tangled/inform7 -internal I -external E -transient T -census
=
(The caller has the obligation to provide the Transient directory.)

@h Using Inform 7 without projects.
To users of Inform UI apps, projects seem essential. On Mac OS, they are
sealed boxes, looking like files in the Finder, but on all platforms they
are in reality directories, containing not only the source code but also a
variety of other things.

But it is also perfectly possible to use Inform 7 on isolated, single files of
source code, rather as a C compiler might work on a single source file for
a simple program. At its simplest, for example:
= (text as ConsoleText)
	$ ls
	helloworld.i7
	$ cat helloworld.i7
	To begin:
	    say "Hello world."
	$ inform7/Tangled/inform7 -basic helloworld.i7
	Inform 7 v10.1.0 has started.
	I've now read your source text, which is 5 words long.
	I've also read Basic Inform by Graham Nelson, which is 7687 words long.
	I've also read English Language by Graham Nelson, which is 2328 words long.

	  The 5-word source text has successfully been translated. There were 0 rooms
	  and 0 things.
	Inform 7 has finished.
	$ ls
	helloworld.i6       helloworld.i7
=
(This was a Basic Inform program, hence |-basic|.) That produced quite a bit of
console chatter: the traditional Unix doctrine is that command-line tools should
shut up when they operate without errors -- "silence is golden", as the usual
slogan has it. Use |-silence| to impose this on Inform:
= (text as ConsoleText)
	$ ls
	helloworld.i7
	$ cat helloworld.i7
	To begin:
	    say "Hello world."
	$ inform7/Tangled/inform7 -basic -silence helloworld.i7
	$ ls
	helloworld.i6       helloworld.i7
=
In |-silence| mode, any problem messages will also be rendered in a conventional
Unix style, opening with |filename:line:| for the convenience of text editors
or IDEs which throw back to source lines where errors occur.

As can be seen, |helloworld.i7| was translated to |helloworld.i6|, and no other
files were written: no Index, no Problems report page. This is because the options
|-no-index| and |-no-problems| were automatically engaged. |-log nothing| was
also implied, and no debugging log was produced. (All of these could be reactivated
by command line settings, however.)

The output file can be specified with the traditional Unix compiler switch |-o|
for "output":
= (text as ConsoleText)
	$ inform7/Tangled/inform7 -basic -silence helloworld.i7 -o my-fancy-file.txt
	$ ls
	helloworld.i7       my-fancy-file.txt
=
The default output filename is the source filename but with the file extension
changed from |i7| to whatever is standard for the format being output. For
example,
= (text as ConsoleText)
	$ inform7/Tangled/inform7 -basic -silence helloworld.i7 -format=C
	$ ls
	helloworld.c        helloworld.i7
=

@h Testing and debugging switches.
The following switches are used only when testing or maintaining Inform,
and are unlikely to be useful to end users. Many of these are, however,
used in the Intest scripts for testing Inform 7 and Inblorb.

(a) |-crash-all| performs a deliberate hard crash, dividing by zero, in
the event of any Problem message being issues -- this makes it easier to
obtain stack backtraces in a debugger.
(b) |-no-index| skips the production of an Index, which reduces file system
writes in a big testing run, and also saves a little time.
(c) |-no-progress| suppresses console output of the "++ 26% (Binding rulebooks)"
kind.
(d) |-sigils| causes each Problem message to be preceded in console output
by its "sigil", that is, its internal code. A typical sigil is
|PM_PropertyNameTooLong|, where the ubiquitous PM stands for "problem
message".
(e) |-require-problem SIGIL| tells Inform to return an exit code of 0 if
exactly this problem message is produced, and 1 otherwise.

@h Expert settings file.
Ordinarily, when the user clicks (say) "Go", the GUI app calls the inform7
executable with various command-line settings to perform the actual work.
The user has had no way to change those settings, except indirectly by e.g.
clicking the checkbox to do with random number generation on the Settings
pane. But that's the exception.

A new feature of |inform7| in 2020 is that it looks in the Materials folder
for an optional file called |inform7-settings.txt|. This is a sort of expert
settings file, and consists of a list of additional command-line arguments
(one per line): those are read exactly as if they had been passed on the
command line. In particular, you could write:
= (text)
	-kit BasicInformKit
=
and then the project will be Basic Inform, not regular Inform.

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
