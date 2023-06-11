Using Inbuild.

An introduction to the use of Inbuild on the command line.

@h What Inbuild is.
Inbuild is a rudimentary build and package manager for the Inform tools.
It consists of a large part of the front end of the Inform 7 compiler,
together with a command-line interface to access its functions. Because
it doesn't contain the middle or back ends of Inform 7, it cannot itself
compile Inform projects. But it can issue shell commands which have
this effect. When used that way, it's a little like the traditional Unix
build tool |make|.

It can also be used in |make| scripts itself. Inbuild returns an exit code
of 0 if successful, or else it throws errors to |stderr| and returns 1
if unsuccessful.

@h Installation.
When it runs, Inbuild needs to know where it is installed in the file
system. There is no completely foolproof, cross-platform way to know this
(on some Unixes, a program cannot determine its own location), so Inbuild
decides by the following set of rules:

(a) If the user, at the command line, specified |-at P|, for some path
|P|, then we use that.
(b) Otherwise, if the host operating system can indeed tell us where the
executable is, we use that. This is currently implemented only on MacOS,
Windows and Linux.
(c) Otherwise, if the environment variable |$INBUILD_PATH| exists and is
non-empty, we use that.
(d) And if all else fails, we assume that the location is |inbuild|, with
respect to the current working directory.

@h Basic concepts.
Inbuild manages "copies". A copy is an instance in the file system of an
asset like an Inform project, an extension, a kit of Inter code, and so on.
Those categories are called "genres". Any given copy will be a copy of
what is called an "edition", which in turn is a version of a "work".

For example, perhaps the user has two copies of version 3 of the extension
Locksmith by Emily Short, in different places in the file system, and also
a further copy of version 4. These are three different "copies", but only two
different "editions", and all are of the same "work". A work -- in this case,
Locksmith by Emily Short -- is identified by its title, author name and
genre -- in this case, an Inform extension.

@ Inbuild has a plethora of command-line options, but at its most basic, the
user should specify what to do and then give a list of things to do it to.
For example, here we run |-inspect| on a single copy, and get a one-line
description of what it is:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect 'inform7/Internal/Extensions/Emily Short/Locksmith.i7x'
	extension: Locksmith by Emily Short v12 in directory inform7/Internal/Extensions/Emily Short
=
This is reassuring -- the file which looks as if it ought to be a copy of
Locksmith actually is. Inbuild always looks at the contents of something,
and doesn't trust its location as any indication of what it is. For
example:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect junk/Mystery.i7x
	extension: Complex Listing by Emily Short v9 in directory junk.
=
If Inbuild can see that something is damaged in some way, it will report that.
For example,
= (text as ConsoleText)
	extension: Skeleton Keys by Emily Short - 1 error
	    1. extension misworded: the opening line does not end 'begin(s) here'
=
Only superficial problems can be spotted so far in advance of actually using
the software, but it's still helpful.

@h Graphs.
More ambitiously, we can look at the "graph" of a copy.
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -graph 'Basic Help Menu.i7x'
	[c0] Basic Help Menu by Emily Short
	  --use---> [c26] Menus by Emily Short v3
	    --use---> [c34] Basic Screen Effects by Emily Short v8
=
The graph begins at the copy we asked for, and then continues through arrows
to other copies. It gives a systematic answer to the question "how do I
build or use this?". There are two kinds of arrows, use arrows and build
arrows. A use arrow from A to B means that you need to have B installed
in order to be able to use A. The above example, then, tells us that we need
Menus in order to use Basic Help Menu, and we need Basic Screen Effects in
order to use Menus.

@ Now suppose we have an Inform project called |Menu Time.inform|, whose
source text is as follows:
= (text as Inform 7)
	Include Basic Help Menu by Emily Short.
	
	The French Laundry is a room.
=
Once again, we can inspect this:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect 'Menu Time.inform'
	projectbundle: Menu Time.inform at path Menu Time.inform
=
We can also use |-graph|, but the output from this is surprisingly long,
because an innocent-looking source text like the above depends on many other
resources.
= (text as ConsoleText)
	[f59] Menu Time.inform/Build/output.ulx
	  --build-> [f58] Menu Time.inform/Build/auto.inf
	    --build-> [f57] Menu Time.inform/Build/auto.inf
	      --build-> [c0] Menu Time.inform
	        --build-> [c53] Basic Help Menu by Emily Short
	          --use---> [c47] Menus by Emily Short v3
	            --use---> [c55] Basic Screen Effects by Emily Short v8
	        --build-> [f1] Menu Time.inform/Source/story.ni
	        --build-> [c12] BasicInformKit
=
...and so on. What's going on here is that if the user wants to compile the
source text, that will (by default) mean making a story file in Glulx format,
called |output.ulx|, which sits inside the project bundle. So that is the top
node. Note that it is a "file node", not a "copy node", as we can see from the
|f| not |c| in its node number. This means that |output.ulx| is not a kind of
resource managed by Inbuild (like an extension, pr a project): it's just a
plain old file.

There's then a build arrow to another file called |auto.inf|. That's because
in order to build |output.ulx|, we first need |auto.inf| to exist. This is
a file in Inform 6 format. Something unexpected then happens: a further arrow
appears, and connects to another |auto.inf|. There aren't really two files
here: this is a device to capture the fact that generating |auto.inf| is a
two-stage process, with the intermediate results between the two stages
being held in memory rather than in a file. (These stages are, first,
converting I7 source text to inter code, and then code-generating that
inter code to I6.) Finally, though, we have a build arrow leading to the
place we might have expected to start: the |Menu Time.inform| project.

And that is where the graph branches outwards, because we need many
different resources in order to build |Menu Time.inform|. We finally see
that we need Basic Help Menu, and because that uses two other extensions
in turn, we'll need both of those as well. We need the actual file which
holds the source text inside the project bundle, |story.ni|. And then
we need various build-in extensions and kits, the first of which is
|BasicInformKit|, and that turns out to need lots of files to exist.

@ The full |-graph| is not always what we want to see. Often all we really
want to know is: what do I need to use, or to build, something?

The command |-use-needs| applied to our example extension gives:
= (text as ConsoleText)
	extension: Basic Help Menu by Emily Short
	  extension: Menus by Emily Short v3
	    extension: Basic Screen Effects by Emily Short v8
=
and applied to our example story gives just:
= (text as ConsoleText)
	projectbundle: Menu Time.inform
=
That's because once Menu Time is built, nothing else is needed to use it.
On the other hand, |-build-needs| has the opposite effect. Applied to the
extension, we get:
= (text as ConsoleText)
	extension: Basic Help Menu by Emily Short
=
because extensions need no building, so certainly nothing else is needed
to build them. But |-build-needs| on our story produces:
= (text as ConsoleText)
	projectbundle: Menu Time.inform
	  extension: Basic Help Menu by Emily Short
	    extension: Menus by Emily Short v3
	      extension: Basic Screen Effects by Emily Short v8
	  kit: BasicInformKit
	    extension: Basic Inform by Graham Nelson v1
	    extension: English Language by Graham Nelson v1
	  kit: CommandParserKit
	    kit: WorldModelKit
	      extension: Standard Rules by Graham Nelson v6
	    extension: Standard Rules by Graham Nelson v6
	  language: English
	    kit: EnglishLanguageKit
	      extension: English Language by Graham Nelson v1
=
And there it is: six extensions, four kits and one natural language definition
are needed. Two of the extensions are listed twice: that's because they are
each needed for two different reasons.

@ The version numbers listed above do not mean that only those exact versions
will do: they mean that this is (the best) version Inbuild has access to.
They're given because two different versions of the same extension might
make different choices about which other extensions to include. We can say
that version 3 of Menus wants to have Basic Screen Effects, but maybe someday
there will be a version 4 which doesn't need it.

Another issue to watch out for is that a copy may use different other copies
when compiled to different virtual machines. For example, an extension can
contain a heading of material "for Glulx only", and that heading might
comtain a line which includes another extension X. If so, then we use X on
Glulx but not on other architectures. We can also flag material as being for
release only, or for debugging only.

Inbuild accepts the same command-line options as |inform7| does to specify
these: |-debug| for debugging features, |-release| for a release run, and
|-format=X| to select a virtual machine. (See the |inform7| documentation.)

@ Now suppose that the project asks for something impossible, with a line
such as:

>> Include Xylophones by Jimmy Stewart.

No such extension exists. If we look at the graph, or the |-build-needs| list
for the project, we see that it includes:
= (text as ConsoleText)
	missing extension: Xylophones by Jimmy Stewart, any version will do
=
If we had instead written:

>> Include version 6.2 of Xylophones by Jimmy Stewart.

we would see:
= (text as ConsoleText)
	missing extension: Xylophones by Jimmy Stewart, need version in range [6.2,7-A)
=
This slightly arcane mathematical notation means that Inform would accept any
version from 6.2 upwards, provided it still begins with a 6. This is a change
over pre-2020 versions of Inform, and has been brought about by the adoption
of the semantic version number standard.

Inbuild can list missing resources with |-use-missing| and |-build-missing|
respectively. At present, it has no means of fetching missing resources from
any central repository.

@ Finally, |-build-locate| and |-use-locate| are identical to |-build-needs|
and |-use-needs|, except that they print a list of the file system paths at
which the relevant resources have been found. This can be useful if you're
managing a complex mass of extensions, and aren't sure (say) which actual copy
of Xylophones inbuild proposes to use, and from where.

@h Building.
The graph for a copy tells Inbuild not only what is necessary for a build,
but also how to perform that build.

As noted above, not everything needs building. Extensions do not, in particular,
so running |-build| on one will do nothing. Kits do need building: what this
does is to "assimilate" the Inform 6-notation source files inside the kit into
binary files of Inter, one for each possible architecture.

But building is mostly done with projects. If we run:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -build Example.inform
=
then Inbuild will first build everything needed to build the Example story
file, including everything needed to use the things needed to build it, and
so on; and then will build Example itself. As with the Unix utility |make|,
this is an incremental process, and looks at the timestamps of files to see
which steps are needed and which are not. If all the kits needed by Example
are up to date, then the kits will not be rebuilt, and so on. If the same
project is built twice in a row, and nothing about it has changed since
the first time, the second |-build| does nothing.

Inbuild uses the graph to work out what needs to be done, and then issues
a series of shell commands to other Inform tools. If any of those commands
fail (returning a non-zero exit code) then the build process halts at once.

As noted above, the |-release| switch tells Inbuild that we want to go all
the way to a release of the project, not just a build. This makes a more
extensive graph, and is likely to mean that the final step followed by
Inbuild is a call to |inblorb|, the releasing tool for Inform.
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -release -build Example.inform
=
Using the |-rebuild| command performs a build in a way which isn't incremental:
timestamps of files are ignored and everything is remade from scratch.

@ It takes a certain trust to just let Inbuild rip, and if you don't feel that
trust, adding the |-dry| switch causes shell commands to be printed out but
not actually executed -- a dry run. If you are debugging Inbuild, you may
also want to look at the copious output produced when |-build-trace| is used.
These are not commands: they simply modify the behaviour of |-build| and
|-rebuild|.

Inbuild uses a handful of standard Unix shell commands, but it also uses
|inform7|, |inform6|, |inblorb| and |inter|. To do that, it needs to know
where they are installed. By default, Inbuild assumes they are in the same
folder as Inbuild itself, side by side. If not, you can use |-tools P| to
specify path |P| as the home of the other Intools.

@h Specifying what to act on.
In all of the examples above, Inbuild is given just one copy to act on.
(That action may end up involving lots of other copies, but only one is
mentioned on the command line.) In fact it's legal to give a list of
copies to work on, one at a time, except that only one of those copies
can be an Inform project. Multiple extensions, or kits, are fine.

We can also tell Inbuild to work on everything it finds in a given directory
|D| using |-contents-of D|:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect -contents-of inform7/Internal/Inter
	kit: EnglishLanguageKit at path inform7/Internal/Inter/EnglishLanguageKit
	kit: CommandParserKit at path inform7/Internal/Inter/CommandParserKit
	...
=
For compatibility with the |inform7| command line syntax, we can also specify
the project target using |-project|:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -build -project Example.inform
=
But this is quite unnecessary: the effect is the same as if |-project| had
been missed out.

@ Listing filenames or pathnames of copies on the command line, or using the
|-contents-of D| switch, is only possible if we know where in the file system
these copies are; and sometimes we do not.

If we instead specify |-matching R|, where |R| is a list of requirements,
Inbuild will act on every copy it can find which matches that. For example,
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect -matching 'genre=kit'
=
lists all the kits which Inbuild can see; and
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect -matching 'genre=extension,author=Eric Eve'
=
lists all extensions by Eric Eve which Inbuild can see. The legal clauses to
specify are |title|, |author|, |genre| and |version|. Note that |version=5.1.1|
would match version numbers 5.1.1, 5.1.2, 5.2.0, etc., but not 6 or above:
again, this is following semver conventions. (Extensions giving their version
numbers in the old-fashioned format "N/YYMMDD" are read as if N.0.YYMMDD, with
the release date being treated as a patch number: see the Inform language
documentation for examples.)

To specify an explicit maximum and minimum version number, use |max| and |min|. For example:
= (text as ConsoleText)
	-matching 'genre=extension,author=Emily Short,title=Locksmith,min=6.1-alpha.2,max=17.2'
=
@h Nests and searches.
When searching with |-matching R|, or indeed when running Inform and needing
to find certain resources, Inbuild looks inside what are called "nests".

A nest is a directory with structured subdirectories, which correspond to
the genres of copies put into them. For example, in the standard distribution
of Inform as a command-line tool, the path |inform7/Internal| is a nest:
this contains the extensions, kits and so on which are built in to Inform
when it's used as an app.

Inbuild recognises the following subdirectories of a nest as significant:
= (text)
	Templates
	Pipelines
	Inter
	Languages
	Extensions
=
Other subdirectories can also exist, and Inbuild ignores those. The above
five containers hold website templates (used by Inblorb), Inter pipelines,
kits, language definitions, and extensions. In the case of extensions, where
there may be very many in total, a further level of subdirectory is used
for the author's name. Thus:
= (text)
	Extensions/Emily Short/Locksmith.i7x
=
(In some early releases of Inform 7, it was legal for this file not to have
the |.i7x| extension: but now it is compulsory.)

As of 2020, nests can contain multiple versions of the same work. To do
this, they should have a filename (or pathname) which ends with |-vN|, where
|N| is semantic version number but with any dots replaced by underscores.
Thus, we can have e.g.:
= (text)
	Extensions/Emily Short/Locksmith-v3_2.i7x
	Extensions/Emily Short/Locksmith-v4_0_0-prealpha_13.i7x
=
co-existing side by side. If the user asks to

>> Include Locksmith by Emily Short.

then version |4.0.0-prealpha.13| will be chosen, as the one with highest
precedence in this nest (but see below for how Inbuild chooses between
versions in the same nest). But if the user asks for

>> Include version 3 Locksmith by Emily Short.

then version |3.2| is the winner, as the highest-numbered extension in the
nest with the right major version number (3).

@ In most runs of the Inform compiler, three nests are used: the "internal"
one, so-called, which holds built-in extensions and is read-only; the
"external" one, which will be somewhere outside of the Inform GUI app, and
will hold additional extensions downloaded by the user; and the Materials
folder for an Inform project, which is a nest all by itself.

Inbuild looks for these as follows:
(a) |-internal N| tells Inbuild the path |N| for the internal nest; if this
is not given, the default is |inform7/Internal|.
(b) |-external N| tells Inbuild the path |N| for the external nest; if this
is not given, the default depends on the host operating system. For example,
on MacOS it will be |~/Library/Inform| (which is what the Inform GUI app
uses too if it is not sandboxed: if it is indeed sandboxed, then it will
have a deliberately obfuscated location which MacOS does not want tools
like ours to access externally).
(c) The Materials nest is always the Materials folder associated with the
project Inbuild is working on; if it isn't working on a project, then this
nest is of course not present.

In addition, extra nests can be specified with |-nest N|.

@ When Inbuild searches for some resource needed by Inform -- let's continue
to use the Locksmith extension as an example -- it always has some range of
version numbers in mind: it will only accept a version in that range. (The
range can be unlimited, in which case any version is acceptable.)

This may well produce multiple results: as noted above, we might have multiple
copies of Locksmith around. Inbuild first reduces the list to just those
whose version lies in the acceptable range. It then applies the following
rules:
(1) A copy in the Materials nest takes precedence over all others.
(2) Otherwise, all other copies take precedence over those in the
internal nest.
(3) Otherwise, semantic version number rules are used to determine which
copy had precedence.

Suppose the Materials folder for our project contains |Locksmith-v3_2.i7x|,
while the external folder contains |Locksmith-v3_3.i7x| and |Locksmith-v4.i7x|.
Then the sentence:

>> Include Locksmith by Emily Short.

would result in |Locksmith-v3_2.i7x| from Materials being used, even though
there's a later version in the external area: Materials always wins. But

>> Include version 4 of Locksmith by Emily Short.

would use |Locksmith-v4.i7x| from the external area, because the copy in the
Materials folder doesn't qualify.

@h Copy, sync and archive.
Clerical work is generally best done automatically, and Inbuild offers some
useful filing commands.

The command |-copy-to N| makes a duplicate copy in the nest |N|. For example:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect junk/Mystery.i7x
	extension: Complex Listing by Emily Short v9 in directory junk.
	$ inbuild/Tangled/inbuild -copy-to MyNest junk/Mystery.i7x
	cp -f 'junk/Mystery.i7x' 'MyNest/Extensions/Emily Short/Complex Listing-v9.i7x'
=
Note that Inbuild replies to the |-copy-to N| command by executing a shell
command to copy what is, in this case, a single file. As when building, the
|-dry| option puts Inbuild into dry-run mode, where it prints the commands it
would like to execute but doesn't execute them.

The command |-sync-to N| is similar, but will overwrite any existing copy
already in |N|, rather than producing an error if a collision occurs.

@ If the version numbers are not wanted in the filenames which |-copy-to|
and |-sync-to| write to, set |-no-versions-in-filenames|:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -inspect junk/Mystery.i7x
	extension: Complex Listing by Emily Short v9 in directory junk.
	$ inbuild/Tangled/inbuild -no-versions-in-filenames -copy-to MyNest junk/Mystery.i7x
	cp -f 'junk/Mystery.i7x' 'MyNest/Extensions/Emily Short/Complex Listing.i7x'
=

@ The |-archive-to N| command performs |-sync-to N| on any resource needed
to build the copy it is working on (with one exception, for technical reasons:
the configuration file telling Inform how to use the English natural language).

This is really only useful for Inform projects, and the abbreviated form
|-archive| performs |-archive-to| to the Materials folder for a project.
The net effect of this is that all extensions needed to build a story file
are gathered, with their correct versions, into the Materials folder; this
means that if the project and its Materials are moved to a different user's
computer, where a quite different set of extensions may be installed, then
the project will still work exactly as it originally did.
