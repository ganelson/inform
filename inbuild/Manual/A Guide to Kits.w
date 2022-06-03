A Guide to Kits.

Provisional documentation on how to make and build new kits.

@h Historical note.
Inform 7 projects have always needed an underpinning of low-level code, in the
same way that all C programs can use standard library functions like |printf|.
In builds from 2016 and earlier, this standard low-level code was provided as
a set of "template files" with filenames like |Mathematics.i6t|, all written
in Inform 6. During compilation, an I7 source text would be compiled down to
one wodge of I6 code, then standing I6 code from files like |Mathematics.i6t|
would be spliced in, and the result would, of course, be an I6 program.

With the arrival of Inter and the possibility of compiling to, say, C instead
of I6 code, this all conceptually changed. Instead of an undifferentiated mass of
template files, that standing material was grouped together into multiple "kits".
(The material formerly in "Mathematics.i6t" now lives on inside BasicInformKit.)

Moreover, that material is still written in Inform 6 syntax, or very nearly so.
What happens to it is completely different -- it is compiled first to Inter, and
then to whatever we like, which may or may not be Inform 6 code -- but in
practice it is not hard to convert template files to become new kits. The
notes in this section are provisional documentation on how to make and use
non-standard kits, that is, kits not supplied with the standard Inform apps.

@h Exactly how kit dependencies are worked out.
Inbuild is in charge of deciding which kits a project will use, just as it also
decides which extensions. For an English-language work of interactive
fiction being made with the Inform apps, the kits will always be:
= (text)
BasicInformKit + EnglishLanguageKit + WorldModelKit + CommandParserKit
=
However, if the "Basic Inform" checkbox is ticked on the Settings panel for
the project, the kits will instead be:
= (text)
BasicInformKit + EnglishLanguageKit + BasicInformExtrasKit
=
And these are also the defaults when Inform projects are compiled from the command
line, with the optional |-basic| switch forcing us into the second case. As a
first step, then, let us see why these are the defaults.

@ BasicInformKit is absolutely obligatory. No Inform project can ever compile
without it: it contains essential functions such as |BlkValueCreate| or |IntegerDivide|.
Inbuild therefore makes every Inform project have BasicInformKit as a dependency.

Inbuild also makes each project dependent on the language kit for whatever language
bundle it is using. The name of the necessary kit can be specified in the language
bundle's |about.txt| file -- see //supervisor: Language Services// -- or, if the
|about.txt| doesn't specify one, it's made by adding |LanguageKit| to the language's
name. So if the French language bundle is used, then the default configurations
become:
= (text)
BasicInformKit + FrenchLanguageKit + WorldModelKit + CommandParserKit
BasicInformKit + FrenchLanguageKit + BasicInformExtrasKit
=

Next, Inbuild adds a dependency on any kit which is named at the command line
using the |-kit| switch. Note that this exists as a command-line switch for
both |inbuild| and |inform7|.

Finally, Inbuild adds an automatic dependency on CommandParserKit if neither
the |-kit| nor |-basic| switches have been used. The practical effect of that
rule is that Inform by default assumes it is making an interactive fiction
of some kind, unless explicitly told not to -- by using |-basic| or |-kit|,
or by checking the "Basic Inform" checkbox in the apps.[1]

[1] Checking this box equates to |-basic|, which in turn is equivalent
to specifying |-kit BasicInformKit|.

@ Kits have the ability to specify that other kits are automatically added to
the project in an ITTT, "if-this-then-that", way. As we shall see, every kit
contains a file called |kit_metadata.json| describing its needs. The metadata
for CommandParserKit includes:
= (text)
dependency: if CommandParserKit then WorldModelKit
=
This means that any project depending on CommandParserKit automatically depends
on WorldModelKit too. BasicInformKit uses this facility as well, but in a
negative way. Its own metadata file says:
= (text)
dependency: if not WorldModelKit then BasicInformExtrasKit
=
It follows that if WorldModelKit is not present, then BasicInformExtrasKit is
automatically added instead.

@ Kits can also use their metadata to specify that associated extensions should
automatically be loaded into the project.[1] For example, the |kit_metadata.json|
for BasicInformKit includes the lines:
= (text)
extension: Basic Inform by Graham Nelson
extension: English Language by Graham Nelson
=

[1] This in fact is the mechanism by which Inform decides which extensions
should be implicitly included in a project. Other extensions are included only
because of explicit "Include..." sentences in the source text.

@ As an example, suppose we have a minimal Inform story called "French Laundry",
whose source text reads just "The French Laundry is a room." Running Inbuild
with the |-build-needs| option shows what is needed to build this project:

= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project 'French Laundry.inform' -build-needs
	projectbundle: French Laundry.inform
	  kit: BasicInformKit
		extension: Basic Inform by Graham Nelson v1
		extension: English Language by Graham Nelson v1
	  kit: CommandParserKit
		extension: Standard Rules by Graham Nelson v6
		kit: WorldModelKit
		  extension: Standard Rules by Graham Nelson v6
	  language: English
		kit: EnglishLanguageKit
		  extension: English Language by Graham Nelson v1
=
The effect of some of the rules above can be seen here. EnglishLanguageKit is
included because of the use of the English language. WorldModelKit is included
only because CommandParserKit is there. And the kits between them call for
three extensions to be auto-included: Basic Inform, English Language and the
Standard Rules.

As this shows, the same kit or extension may be needed for multiple reasons.
But it is only included once, of course.

@ At the command line, either for Inbuild or Inform7, the |-kit| switch
can specify alternative kit(s) to use. Note that if any use is made of |-kit|
then CommandParserKit and (in consequence) WorldModelKit are no longer auto-included.
For example, if |-kit BalloonKit| is specified, then we will end up with:
= (text)
BasicInformKit + EnglishLanguageKit + BalloonKit + BasicInformExtrasKit
=
But if |-kit CommandParserKit -kit BalloonKit| is specified, then:
= (text)
BasicInformKit + EnglishLanguageKit + WorldModelKit + CommandParserKit + BalloonKit
=

It may seem that if Inform is being used inside the apps, then there is no way to
specify non-standard kits. Since the user isn't using the command line, how can
the user specify a |-kit|? However, a feature of Inform new in 2022 gets around
this. Additional command-line switches for |inbuild| or for |inform7| can be
placed in the Materials directory for an Inform project, in files called
|inbuild-setting.txt| and |inform7-settings.txt|.

For example, suppose we set both[1] of these files to be:
= (text)
-kit CommandParserKit
-kit BalloonKit
=
And put the following into place:
= (text)
Exotic.inform
Exotic.materials
	inbuild-settings.txt
	inform7-settings.txt
	Inter
		BalloonKit
			...
	...
=
BalloonKit has to be a properly set up kit -- see below; but if so, then when
we next look at the build requirements for the project, we see:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project 'French Laundry.inform' -build-needs
	projectbundle: French Laundry.inform
	  kit: BasicInformKit
		extension: Basic Inform by Graham Nelson v1
		extension: English Language by Graham Nelson v1
	  kit: CommandParserKit
		extension: Standard Rules by Graham Nelson v6
		kit: WorldModelKit
		  extension: Standard Rules by Graham Nelson v6
	  kit: BalloonKit
	  language: English
		kit: EnglishLanguageKit
		  extension: English Language by Graham Nelson v1
=
So now BalloonKit is indeed a dependency.

See //inbuild: Manual// for the full story on where the compiler expects to
find kits, but basically, they're managed much the way extensions are.

[1] Both, so that whether the executable looking at the project is inbuild or
inform7, it will use the same set of kits. You want this.

@ So, then, what actually is a kit? It is stored as a directory whose name is
the name of the kit: in the case of our example, that will be |BalloonKit|.
This directory contains:

(*) Source code. In fact, a kit is also an Inweb literate program, though it
is always a deliberately simple one. (Being Inweb-compatible is very convenient,
since it means it can be woven into website form. See //BasicInformKit// for
an example of the result.) It is simple because it provides only a |Contents.w|
page and a |Sections| subdirectory -- it has no manual, chapters, figures,
sounds or other paraphernalia.

(*) A file called |kit_metadata.json| describing the kit, its version and its
dependencies.

(*) Compiled binary Inter files -- but only once the kit has been built. These
always have filenames in the shape |arch-A.interb|, where |A| is an architecture;
in that way, a kit can contain binary Inter to suit several different architectures.
For example, |arch-16d.interb| or |arch-32.interb|.

@ The source code is written in Inform 6 syntax.[1] This means that to create or
edit kits, you need to be able to write Inform 6 code, but it's a very simple
language to learn if all you're doing is writing functions, variables and arrays.

For |BalloonKit|, the contents page |BalloonKit/Contents.w| will be:
= (text)
Title: BalloonKit
Author: Joseph-Michel Montgolfier 
Purpose: Inter-level support for inflating rubber-lined pockets of air.

Sections
	Inflation
=
So there will be just one section, |BalloonKit/Sections/Inflation.w|, which
will read:
= (text)
	Inflation.

	Vital Inter-level support for those balloons.

	@h Inflation function.

	=
	Constant MAX_SAFE_INFLATION_PUFFS 5;

	[ InflateBalloon N i;
		if (N > MAX_SAFE_INFLATION_PUFFS) N = MAX_SAFE_INFLATION_PUFFS;
		for (i=0: i<N: i++) {
			print "Huff... ";
		}
		print "It's inflated!^";
	];
=
Note the very simple Inweb-style markup here. We do not use any of the fancier
features of literate programming (definitions, paragraph macros, and so on),
because the kit assimilator can only perform very simple tangling, and is not
nearly as strong as the full Inweb tangler.[2]

[1] It would have been conceivable to write such code directly as textual Inter,
but the experience would have been painful. Even in its textual form, Inter is not
very legible, and it is highly verbose.

[2] At some point it may be developed out a little, but there's no great need.

@ The metadata file at |BalloonKit/kit_metadata.json| is going to be simple:
= (text)
extension: Party Balloons by Joseph-Michel Montgolfier
=
In fact we don't really need this line at all (a kit does not need to have any
associated extensions), but it makes for a more interesting demonstration. We
can see an effect at once:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project 'French Laundry.inform' -build-needs
	projectbundle: French Laundry.inform
	  ...
	  kit: BalloonKit
		missing extension: Party Balloons by Joseph-Michel Montgolfier, any version will do
	  ...
=
This will, in fact, now fail to build, because Inform needs an extension which
it has not got. So suppose we provide one:
= (text as Inform 7)
Version 2 of Party Balloons by Joseph-Michel Montgolfier begins here.

To perform an inflation with (N - a number) puff/puffs: (- InflateBalloon({N}); -).

Party Balloons ends here.
=
and place this file at:
= (text)
French Laundry.materials/Extensions/Joseph-Michel Montgolfier/Party Balloons.i7x
=
To make use of this, we'll change the French Laundry source text to:
= (text as Inform 7)
The French Laundry is a room. "This fancy Sonoma restaurant has, for some reason,
become a haunt of the pioneers of aeronautics."

When play begins:
	perform an inflation with 3 puffs.
=

Now Inbuild is happier:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project 'French Laundry.inform' -build-needs
	projectbundle: French Laundry.inform
	  ...
	  kit: BalloonKit
		extension: Party Balloons by Joseph-Michel Montgolfier v2
	  ...
=

@ The whole point of a kit is to be precompiled code, so we had better compile it.
There are several ways to do this. One is to tell Inbuild directly:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -build 'French Laundry.materials/Inter/BalloonKit'
=
This then issues a series of commands to the //inter// tool, which actually 
performs the work, compiling the kit for each architecture in turn. (These
commands are echoed to the console, so you can see exactly what is done, and
indeed you could always build the kit by hand using //inter// and not Inbuild.)

In fact, though, Inbuild can also make its own mind up about when a kit needs
to be compiled. Rather than build the kit, we can build the story:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project French\ Laundry.inform -build
=
If BalloonKit needs building first, either because it has never been compiled or
because the source code for the kit has changed since it was last compiled,
then it will be built as part of the process; and if not, not.

And this incremental building is also what happens if the "French Laundry"
project is compiled in the Inform apps, by clicking "Go" in the usual way. Any
of its kits which need rebuilding are automatically rebuilt as part of the process.

@h Full specification of the kit metadata file.
This is a UTF-8 encoded Unicode text file, consisting of a sequence of commands
in any order, one per line. No commands are compulsory. An empty file is legal.

Blank lines are ignored, as are lines whose first non-white-space character is |#|,
which are considered comments.

@ |version: V| gives the kit's version number. This follows Inbuild's usual semantic
version numbering conventions, so for example:
= (text)
	version: 5
	version: 1.5.6-alpha.12
=
This is the version number which Inbuild will use to resolve dependencies. If a
project needs v1.7 or better, for example, Inbuild will not allow it to use
version 1.5.6-alpha.12 of a kit.

@ |compatibility: C| allows us to say which architectures or final targets
the kit is compatible with. By default, Inbuild assumes it will work with anything,
equivalent to |compatibility: all|. But for example:
= (text)
	compatibility: for 16-bit with debugging only
	compatibility: not for 32-bit
	compatibility: for Inform6 version 8
	compatibility: not for C
=
In general, it's best to stick to architectural constraints (i.e. 16 or 32 bit,
with or without debugging support) and not to constrain the final target unless
really necessary.

@ |defines Main: yes| or |defines Main: no|. The default is |no|, so use this
only to specify that the kit contains within it a definition of the |Main|
function. But only the shipped-with-Inform kits should ever do this.

@ |natural language: yes| or |natural language: no|. The default is |no|; use
this only to say that the kit is a language support kit, like EnglishLanguageKit.

@ |insert: X|. This sneakily allows a sentence of Inform 7 source text to be
inserted into any project using the kit. For example:
= (text)
	insert: Use maximum inflation level of 20.
=
But in general it's better not to use this at all, and to put any such material
in an associated extension which is automatically included.

@ |kinds: F|, where |F| is the name of a Neptune file. Neptune is a mini-language
for setting up kinds and kind constructors inside the compiler: see
//kinds: A Brief Guide to Neptune// for much more on this. The file |F| should
be placed as |BalloonKit/kinds/F|. For example:
= (text)
kinds: Protocols.neptune
kinds: Core.neptune
=

@ |extension: E|, where |E| is the name of an extension. A version number
can optionally be given, too. For example:
= (text)
extension: Party Balloons by Joseph-Michel Montgolfier
extension: version 2.1 of Party Balloons by Joseph-Michel Montgolfier
=
Inbuild will now automatically include this extension if it can find it; if
not, the build will halt. Compatibility with the version number is done by
semantic version numbering rules, so v2.1.67 would be fine, but not v2.2, v1,
v3, and so forth. Note that kits can mandate multiple extensions, not just one.

@ |activate: F| and |deactivate: F|. This says that if the kit is present, then
a given feature inside the compiler |F| should be switched on or off. For
example, the metadata for CommandParserKit includes:
= (text)
activate: command
=
which enables command grammar to be part of the Inform language. WorldModelKit
more ambitiously says:
= (text)
activate: interactive fiction
activate: multimedia
=
It is these activation lines, in WorldModelKit and CommandParserKit, which cause
the Inform language to have IF-specific features during a compilation. Without
them, the language would just be Basic Inform.

The feature names |F| are the names of plugins inside the compiler, and this is
not the place to document that. See the implementation at //core: Plugins//.
But in general, unless you are performing wild experiments with new language
features inside the compiler, never use |activate| or |deactivate|.

@ |dependency: if X then Y| and |dependency: if not X then Y|. This specifies
dependencies between kits; often |X| or |Y| will be the kit you are currently
defining, but not necessarily. Rules are considered for all kits currently loaded.
For example, this is part of the metadata for CommandParserKit:
= (text)
dependency: if CommandParserKit then WorldModelKit
=
A few points to note:
(*) Rules are considered only for kits which are loaded. There is no way to
make BalloonKit parasitically attach to all projects by giving it the rule
|if not BalloonKit then BalloonKit|, because this rule will only be looked at
if BalloonKit has already loaded.
(*) The outcome cannot be |... then not Y|; once loaded, a kit cannot be
unloaded. So these dependency rules can only cause extra kits to be added.
(*) Positive rules |if ...| are considered first, and only then negative ones
|if not ...|. Within each category, kits have their rules looked at in order
of their priority (see below).
(*) Version number requirements cannot be specified for either |X| or |Y|
at present.

@ |priority: N|, where |N| is a number from 0 to 100. This is used only to
decide whose wishes get priority when Inbuild is performing if-this-then-that
decisions to sort out which kits are present in a project. The default is 10,
and for almost all kits it should stay that way. Lower-numbered kits have
"more important" wishes than higher-numbered ones.

@ |index from: C| can change the structure of the Index for a project using
this kit, but in practice this should be done only by BasicInformKit or by
WorldModelKit. (There are two versions of the index, one for Basic Inform
projects, the other for interactive-fiction ones.)

@h Future directions.
It will be noted that a kit can include an extension automatically, but not
vice versa. Indeed, at present there is no way for Inform 7 source text to ask
for a kit to be included. This limitation is intentional for now.

A likely future development is that extensions will be made more powerful
by breaking the current requirement that every extension is a single file of
I7 source text. It seems possible that in future, an extension might be a
small package which could also include, for example, an accompanying kit.
But this has yet to be worked out, and involves questions of how Inbuild,
and the apps, the Public Library, and so on, would deal with all of that.
In the mean time, it seems premature to commit to any model.
