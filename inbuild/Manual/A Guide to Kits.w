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
BasicInformKit + Architecture32Kit + EnglishLanguageKit + WorldModelKit + CommandParserKit
=
That's for a 32-bit target, such as when Inform projects are compiled for Glulx:
the alternative is to swap |Architecture16Kit| for |Architecture32Kit|.

However, if the "Basic Inform" checkbox is ticked on the Settings panel for
the project, the kits will instead be:
= (text)
BasicInformKit + Architecture32Kit + EnglishLanguageKit
=
And these are also the defaults when Inform projects are compiled from the command
line, with the optional |-basic| switch forcing us into the second case. As a
first step, then, let us see why these are the defaults.

@ BasicInformKit is absolutely obligatory. No Inform project can ever compile
without it: it contains essential functions such as |BlkValueCreate| or |IntegerDivide|.
Inbuild therefore makes every Inform project have BasicInformKit as a dependency.

Inbuild also makes each project dependent on the language kit for whatever language
bundle it is using. So if French is the language of play, the default configurations
become:
= (text)
BasicInformKit + Architecture32Kit + FrenchLanguageKit + WorldModelKit + CommandParserKit
BasicInformKit + Architecture32Kit + FrenchLanguageKit
=
Projects can specify their own unusual choices of kits using a project_metadata.json
file: see //A Guide to Project Metadata// for more on this. But assuming they
don't do this, Inbuild will always go for one of these defaults. By default it
assumes it is making an interactive fiction of some kind and therefore goes
for the non-Basic default, unless explicitly told not to -- by using |-basic| on
the command line, or by checking the "Basic Inform" checkbox in the apps.

@ Kits have the ability to specify that other kits are automatically added to
the project in an ITTT, "if-this-then-that", way. As we shall see, every kit
contains a file called |kit_metadata.json| describing its needs. The metadata
for CommandParserKit includes:
= (text)
    {
        "need": {
            "type": "kit",
            "title": "WorldModelKit"
        }
    }
=
Never mind the JSON syntax (all that punctuation) for now: what this is saying
is that CommandParserKit always needs WorldModelKit in order to function.
This means that any project depending on CommandParserKit automatically depends
on WorldModelKit too.

For example, this can be used to say "unless we have kit MarthaKit, include
GeorgeKit":
= (text)
	{
        "unless": {
            "type": "kit",
            "title": "MarthaKit"
        },
        "need": {
            "type": "kit",
            "title": "GeorgeKit"
        }
    }
=
Inbuild acts on this by checking to see if |MarthaKit| is not present, and
in that case |GeorgeKit| is automatically added instead. (Positive conditions
can also be made, with "if" instead of "unless".)

@ Kits can also use their metadata to specify that associated extensions should
automatically be loaded into the project.[1] For example, the |kit_metadata.json|
for BasicInformKit includes the lines:
= (text)
	{
        "need": {
            "type": "extension",
            "title": "Basic Inform",
            "author": "Graham Nelson"
        }
    }
=
...and similarly for another extension called English Language.

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
	  kit: Architecture32Kit
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

@ Using project metadata (see //A Guide to Project Metadata//) alternative
or additional kits can be required. Note that if this is done then CommandParserKit
and (in consequence) WorldModelKit are no longer auto-included.

For example, if BalloonKit is specified, then we will end up with:
= (text)
BasicInformKit + Architecture32Kit + EnglishLanguageKit + BalloonKit
=
But if CommandParserKit and BalloonKit are both specified, then:
= (text)
BasicInformKit + Architecture32Kit + EnglishLanguageKit + WorldModelKit + CommandParserKit + BalloonKit
=
If so, then when we next look at the build requirements for the project, we see:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -project 'French Laundry.inform' -build-needs
	projectbundle: French Laundry.inform
	  kit: BasicInformKit
		extension: Basic Inform by Graham Nelson v1
		extension: English Language by Graham Nelson v1
	  kit: Architecture32Kit
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

@ The metadata file at |BalloonKit/kit_metadata.json| is required to exist in
order for Inbuild to recognise this as being a kit at all; even if it doesn't
say very much, as in this example. This is (almost) minimal:
= (text)
{
    "is": {
        "type": "kit",
        "title": "BalloonKit",
        "author": "Jacques-Étienne Montgolfier"
        "version": "3.2.7"
    }
}
=
This is a JSON-format file: JSON, standing for Javascript Object Notation, is
now nothing really to do with the language Javascript and has instead become
an Internet standard for small packets of descriptive data, like ours. Many
full descriptions of JSON are available, but here are some brief notes:

(*) This is a UTF-8 plain text file. The acute accent in "Jacques-Étienne Montgolfier"
causes no problems, but quoted text is well advised to confine itself to the Unicode
Basic Multilingual Plane characters (with code-points 0 to 65535). Inside
quotation marks, |\n| and |\t| can be used for newlines and tabs, but a kit
shouldn't ever need them. |\uDDDD| can be used to mean "the Unicode character
whose code is |DDDD| in hexadecimal".

(*) Braces |{| and |}| begin and end "objects". The whole set of metadata on
the kit is such an object, so the file has to open and close with |{| and |}|.
Inside such braces, we have a list of named values, divided by commas. Each
entry takes the form |"name": value|. The name is in quotes, but the value
will only be quoted if it happens to be a string.

(*) Square brackets |[| and |]| begin and end lists, with the entries in the
list divided by commas. For example, |[ 1, 2, 17 ]| is a valid list of three
numbers.

(*) Numbers are written in decimal, possibly with a minus sign: for example,
|24| or |-120|. (JSON also allows floating-point numbers, which Inbuild does
read, and stores to double precision, but kit metadata never needs these.)

(*) The special notations |true| and |false| are used for so-called boolean
values, i.e., those which are either true or false.

(*) The special notation |null| is used to mean "I am not saying what this is",
but kit metadata never needs this.

(*) JSON files are forbidden to contain comments, and Inbuild is very strict
about what hierarchies of objects it will read without errors.

@ Looking again at the minimal example, what do we have?
= (text)
{
    "is": {
        "type": "kit",
        "title": "BalloonKit",
        "author": "Jacques-Étienne Montgolfier"
        "version": "3.2.7"
    }
}
=
The metadata is one big object. That object has a single named value, |"is"|.

The value of |"is"| is another object -- hence the second pair of |{| ... |}| after
the colon. This second object gives the identity of the kit -- says what it is,
in other words. That has four values:

(1) |"type"|, which has to be |"kit"|;
(2) |"title"|, which has to match the kit's name -- Inbuild will throw an error
if BalloonKit's metadata file claims that its title is actually |"AerostatiqueKit"|;
(3) |"author"|, which is optional, but which if given should follow the usual
conventions for author names of Inform extensions; and
(4) |"version"|, which is also optional, but whose use is strongly recommended.
This has to be a semantic version number. This follows Inbuild's usual semantic
version numbering conventions, so for example |"5"| and |"1.5.6-alpha.12"| would
both be valid. Note that in JSON terms it's a string, despite the word "number"
in the phrase "semantic version number", so it goes in double-quotes. This is
the version number which Inbuild will use to resolve dependencies. If a project
needs v1.7 or better, for example, Inbuild will not allow it to use
version 1.5.6-alpha.12 of a kit.

@ To make for a more interesting demonstration, now suppose that the kit
wants to require the use of an associated extension. We extend the metadata file to:
= (text)
{
    "is": {
        "type": "kit",
        "title": "BalloonKit",
        "author": "Jacques-Étienne Montgolfier"
        "version": "3.2.7"
    },
    "needs": [
		{
			"need": {
				"type": "extension",
				"title": "Party Balloons",
				"author": "Joseph-Michel Montgolfier"
			}
		}
    ]
}
=
Now our metadata object has a second named value, |"needs"|. This has to be
a list, which in JSON is written in square brackets |[ X, Y, Z, ... ]|. Here
the list has just one entry, in fact. The entries in the list all have to be
objects, which can have three possible values:

(1) |"if"|, saying that the dependency is conditional on another kit being used --
see above for examples;
(2) |"unless"|, similarly but making the condition on another kit not being used;
(3) |"need"|, which says what the dependency is on.

The |"if"| and |"unless"| clauses are optional. (And only one can be given.)
The |"need"| clause is compulsory. This can say that the kit needs another
kit (there are examples above), but in this case it says the kit needs a
particular extension to be present.

We can see an effect at once:
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
Note that this text does not explicitly say "Include Party Balloons by Joseph-Michel
Montgolfier" -- it doesn't need to: the extension is automatically included by
the kit.

And now Inbuild is happier:
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

@h Other ingredients of the kit metadata file.
As noted above, |kit_metadata.json| must be a valid JSON file which encodes a
single object. The following are the legal member names; only |"is"| is mandatory,
and the rest sensibly default if not given.

(*) |"is"|, an object identifying what kit this is. See above.

(*) |"needs"|, a list of objects each of which specifies a possibly conditional
dependency on other resources. See above.

(*) |"compatibility"|, a string which describes which architectures or final targets
the kit is compatible with. By default, Inbuild assumes it will work with anything,
equivalent to |"compatibility": "all"|. In general, it's best to stick to purely
architectural constraints (i.e. 16 or 32 bit, with or without debugging support)
and not to constrain the final target unless really necessary. But the following
are all legal:
= (text)
	"compatibility": "for 16-bit with debugging only"
	"compatibility": "not for 32-bit"
	"compatibility": "for Inform6 version 8"
	"compatibility": "not for C"
=

(*) |"activates"| is a list of strings describing optional features of the Inform
compiler to switch on if this kit is being used. The feature names are the names
of features inside the compiler, and this is not the place to document that. See
the implementation at //arch: Feature Manager//. But in general, unless you are
performing wild experiments with new features inside the compiler, you will never
need |"activates"|. It really exists for the benefit of the built-in kits. For
example, WorldModelKit does the following:
= (text)
	"activates": [ "interactive fiction", "multimedia" ]
=

(*) |"deactivates"| is a similar list describing what to turn off.

(*) |"kit-details"| is a set of oddball settings which make sense only for kits.
The reason these are hived off in their own sub-object is so that the same
basic file format can be used for JSON describing other resources, too.
|"kit-details"| can only legally be used if the |"type"| in the |"is"| object
is set to |"kit"|.

@ The |"kit-details"| object can contain the following, all of which are
optional. Only the first is likely to be useful for a kit other than one of
those built in to the Inform installation.

(*) |"provides-kinds"| is a list of strings. These are the names of Neptune
files to read in. Neptune is a mini-language for setting up kinds and kind
constructors inside the Inform compiler: see //kinds: A Brief Guide to Neptune//
for much more on this. Each named file |F| should be placed as |BalloonKit/kinds/F|.
For example, WorldModelKit does this:
= (text)
"provides-kinds": [ "Actions.neptune", "Times.neptune", "Scenes.neptune", "Figures.neptune", "Sounds.neptune" ]
=

(*) |"has-priority"| is a number, from 0 to 100. This is used only to decide
whose wishes get priority when Inbuild is performing if-this-then-that
decisions to sort out which kits are present in a project. The default is 10,
and for almost all kits it should stay that way. Lower-numbered kits have
"more important" wishes than higher-numbered ones.

(*) |"defines-Main"| is a boolean, so its value has to be |true| or |false|.
If it isn't given, the value will be |false|. This is useful only for the
built-in kits supplied with Inform, and indicates whether or not they define
a |Main| function in Inter.

(*) |"indexes-with-structure"| is a string. This is useful only for the
built-in kits supplied with Inform, and indicates which structure file should
be used to generate the Index of a project. (There are two versions of the
index, one for Basic Inform projects, the other for interactive-fiction ones.)

(*) |"inserts-source-text"| is a string. This sneakily allows a sentence of
Inform 7 source text to be inserted into any project using the kit. Its use
is very much a last resort: if at all possible, put such material in an
associated extension, and then auto-include that extension using a |"needs"|
dependency (see above). But, for example:
= (text)
	"inserts-source-text": "Use maximum inflation level of 20."
=

@ Here are a few footnotes on how Inbuild resolves the "needs" requirements
of multiple kits, which may clarify what happens in apparently ambiguous
situations.

(*) Needs are considered only for kits which are loaded. There is no way to
make BalloonKit parasitically attach to all projects by giving it a rule
saying in effect "unless you have BalloonKit then you need BalloonKit",
because although you could write such a rule, it would only be processed
when BalloonKit had already loaded -- and would then have no effect.

(*) A kit cannot be unloaded once loaded. So "needs" rules can only cause
extra kits to be added. It follows that there can never be a loop caused
by kits repeatedly loading and unloading each other through irresolvable
constraints. But it also follows that the outcome in such a case can depend
on the order in which rules are considered.

(*) Positive needs using "if" (or unconditional needs) are considered first,
and only then negative ones using "unless". Within each category, kits have
their needs looked at in order of their priority numbers (see above).

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
