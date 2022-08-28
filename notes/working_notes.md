# Ongoing work: a few notes

This rudimentary blog-like page is to provide brief notes on changes to the
Inform code base made between formal releases, and is only likely to be useful
to people experimenting with unreleased builds of Inform.

## Current status

The next formal release is v10.1.0. We are coming to the end of the beta period
for that, and are concentrating on bug fixes, improvements to compatibility
with old extensions, and making sure that concepts being introduced by 10.1
are set up in a way we can live with. Work also continues on the GUI apps,
notably the MacOS app, which is being modernised to support Dark Mode.

## News items

### Kit incremental rebuilding change (28 August 2022)

A snag emerged when building the new release 10.1.1 for Linux. Inbuild, the
build manager inside of Inform, automatically rebuilds kits from source if they
need it, and uses timestamps of files to determine this. If timestamps are
equal, Inbuild errs on the side of rebuilding, because timestamps are fairly
low in fidelity: either file might actually be newer.

Unfortunately, when Linux apps are sandboxed (i.e., are running in a sort of
protective enclosure for security reasons), the inside of the app installation
is reported to have timestamps which are all equal to each other. No doubt
there are good reasons for this, but it means Inbuild tried to rebuild each
kit inside of the app (so, `BasicInformKit` and so on). And this failed, because
the sandboxed directories are read-only. Inform therefore halted because the build
was thwarted.

The new rule is that a kit which is discovered from an internal nest is never
incrementally rebuilt, whatever timestamps might exist. There doesn't seem any
reason to restrict this rule to Linux: the internal nest inside the apps should
be read-only on all of them (and indeed the MacOS sandbox also enforces this).

### Release notes (8 August 2022)

Not a thrilling development, but we continue to get things organised ready for
formal releases of Inform from this repository. As part of that, the entire
[archive of release notes of past Inform releases](version_history.md) is now
converted to Markdown and migrated here.

In the past, changes to Inform were logged in a sort of ebook, and indeed this
could even be downloaded in ePub format. That was before we had this repository,
though, and the ebook is being discontinued. Release notes here are clearly
easier to maintain, and to link to commits and issues.

### State of Inform talk (30 July 2022)

[The text and slides](https://ganelson.github.io/inform-website/talks/2022/07/31/narrascope-iii.html)
from a talk about Inform at the Narrascope III conference give an outline of
expected future developments in the language.

### Memory saving under the Z-machine (17 July 2022)

When compiling to the Z-machine, Inform now adopts the I6 configuration option
$ZCODE_LESS_DICT_DATA=1, and consequently saves 1 byte per dictionary word.

### String escape notations in I6 syntax (30 June 2022)

I6 inclusions in source text, and kit sources, are run through an I6-to-Inter
compiler within the building module of inter, not through the regular I6 compiler.
Up to this point in the beta, the I6-to-Inter compiler recognised only a few
of the very basic string escapes, which led to Jira bug report I7-2156. This
particularly affects non-English IF writers, and especially translators making
language support kits.

This should all now work: see the new inform7 test case I6StringEscapes-G (the
2000th inform7 test case!) and the building-test module test case schemas for
a thorough exercise of these escapes.

For example, the following function included in I7 source text:

	Include (-
		[ Hyperdiacritical;
			print (char) '^', " might be a caret, who knows.^";
			print (address) 'x^', " might be an x', who knows.^";
			print (address) '^//', " might be a ', who knows.^";
			print (char) '@ss', " might be an @ss, who knows.^";
			print (address) 'x@ss', " might be an x@ss, who knows.^";
			print (char) '@{0041}', " might be an A, who knows.^";
			print (address) 'x@{0041}', " might be an xA, who knows.^";
			print "Les @oeuvres d'@AEsop en fran@,cais, mon @'el@`eve!^";
			print "Na@:ive readers of the New Yorker re@:elected Mr Clinton.^";
			print "Gau@ss first proved the Fundamental Theorem of Algebra.^";
			print "@'a@'e@'i@'o@'u@'y@'A@'E@'I@'O@'U@'Y@`a@`e@`i@`o@`u@`A@`E@`I@`O@`U@^a@^e@^i@^o@^u@^A@^E@^I@^O@^U@:a@:e@:i@:o@:u@:y@:A@:E@:I@:O@:U@:Y^";
			print "@~a@~n@~o@~A@~N@~O@,c@,C@\o@\O@ae@AE@et@Et@th@Th@LL@!!@??@<<@>>@ss@oa@oA@oe@OE^";
			print "So @{a9} is a copyright sign, and @{424} is a capital Cyrillic ef, and @{25B2} is a triangle^";
			print "Backslash: @@92 At sign: @@64 Caret: @@94 Tilde: @@126^";
		];
	-).

prints, if executed (on Glulx - the Z-machine does not support four of these Unicode characters):

	^ might be a caret, who knows.
	x' might be an x', who knows.
	' might be a ', who knows.
	ß might be an ß, who knows.
	xß might be an xß, who knows.
	A might be an A, who knows.
	xa might be an xA, who knows.
	Les œuvres d'Æsop en français, mon élève!
	Naïve readers of the New Yorker reëlected Mr Clinton.
	Gauß first proved the Fundamental Theorem of Algebra.
	áéíóúýÁÉÍÓÚÝàèìòùÀÈÌÒÙâêîôûÂÊÎÔÛäëïöüÿÄËÏÖÜŸ
	ãñõÃÑÕçÇøØæÆðÐþÎ£¡¿«»ßåÅœŒ
	So © is a copyright sign, and Ф is a capital Cyrillic ef, and ▲ is a triangle
	Backslash: \ At sign: @ Caret: ^ Tilde: ~

The syntax recognised for character, dictionary and string literals now matches
the syntax recognised by the main I6 compiler, except for one extension: the
I6-to-Inter compiler also allows "[unicode N]", where N is a decimal number,
to mean the character whose code point is N. The reason for this extension to
the syntax is that it means that:

	Include (-
		[ Diacritical;
			print "Ф is a capital Cyrillic ef, and ▲ is a triangle.^";
		];
	-).

will work the same way when run through I7 as the definition:

	[ Diacritical;
		print "Ф is a capital Cyrillic ef, and ▲ is a triangle.^";
	];

would work if found in the source code for a kit -- in both cases, the ef
and the triangle will be passed successfully through. Consistency between
inform7 and inter seems more important on this than consistency between inter
and inform6.

### Withdrawal of -kit, but not of -basic (27 June 2022)

Up to this point, the beta of inbuild (and hence also of inform7) had a
command-line switch "-kit". This told Inbuild that the named kit should be
included in any build of a project to be specified later on the command line.
For example,

	$ inbuild -kit BasicInformKit -kit MyMagicKit -build -project MyProject.inform

The convention was that if no "-kit" was supplied, then the project would
either include just BasicInformKit (if -basic was also given as an option)
or else BasicInformKit and CommandParserKit. (These would then cause
other kits to be included, such as WorldModelKit, and there would also be
a kit to support the language of play, such as EnglishLanguageKit.)

This worked, but was clumsy. Users of the Inform apps could only take advantage
by writing these command-line settings into both an "inform7-settings.txt" and
"inbuild-settings.txt" file, and even then this was finicky (see Jira bug I7-2161).
The command line is anyway not a good place to specify metadata which properly
belongs to a project, and also had no way to express version numbers for the
kits desired.

"-kit" has now been abolished. "-basic" remains, and works as before.

So how do you specify that a project expects to see a kit? The answer is to
place a suitable project_metadata.json file into the project's materials directory.
See [A Guide to Project Metadata](https://ganelson.github.io/inform/inbuild/M-agtpm.html).

### Incremental building of kits enabled (26 June 2022)

This is arguably a bug fix, but is not directly a fix of any currently open bug
in Jira (but see closed I7-2155). It was always intended that inbuild and
inform7 would incrementally build any kits they need in order to build Inform
projects: that has worked up to now with the standard kits, but in many
circumstances not with newly written kits, such as those intended to be used
with language extensions. (It's complicated: some ways of using inbuild did
in fact do this, but inform7 did not.)

This is now enabled. On the console (or in the app's Console pane), you will
now see lines like the following when a kit is being rebuilt by inform7 itself:

	(Building FrenchLanguageKit for architecture 16)
	(Building FrenchLanguageKit for architecture 16d)
	(Building FrenchLanguageKit for architecture 32)
	(Building FrenchLanguageKit for architecture 32d)

A side-effect of all this is that the output of inbuild -graph for a project
is now substantially longer. This is basically because a project does indeed
depend on lots of source files, and the new larger graph is a truer picture
than the old ones. But we may eventually work out more concise ways to print it.

### Language metadata respecified as JSON (23 June 2022)

As has been noticed already (see e.g. Jira bug I7-2155), the new Inbuild has
been fairly sketchy in its handling of language bundles, and of using Inform
to make non-English IF. In particular, language kits such as FrenchLanguageKit
(if provided) were not being loaded automatically and instead required -kit
to be used at the command line, or with a settings file; and even then,
EnglishLanguageKit was being loaded as well, causing definition clashes.

This should all now be resolved.

Language bundles have now been redesigned, and are documented in the Inbuild
manual, which has been rewritten today: see [A Guide to Language Bundles](https://ganelson.github.io/inform/inbuild/M-agtlb.html).
Like kits, language bundles are adopting the new JSON metadata format.

### Change of testing UUID (22 June 2022)

A change to the batch-testing tool Intest means that the UUID used for Inform
projects being tested is now 00000000-0000-0000-0000-000000000000: this is meant
to be a visibly bogus value, replacing 0B00B00D-3307-4688-B2D8-95DB962781B4.
UUIDs are in theory unique per project, but Intest operates Inform projects with
this single bogus UUID for every test case it runs.

As a result, all six inblorb test cases and 9 of the inform7 tests will fail
(1=Awkward 2=Audiovisual 3=Fancy-Z 4=Plain-Z 5=Plain 6=Ingredients 7=Fancy
8=Index-Card 9=Index-Card2) by showing a discrepancy on the UUID somewhere
unless you have pulled the latest Intest.

### Kit metadata respecified as JSON (4 June 2022)

Kits are new in 10.1, and are documented in the Inbuild manual, which has been
rewritten today: see [A Guide to Kits](https://ganelson.github.io/inform/inbuild/M-agtk.html).

The change today is that the "kit_metadata.txt" file has now changed format and
name, to become "kit_metadata.json". This JSON format is a work in progress and
is likely to become a uniform way to describe resources used by Inbuild (extensions,
language bundles, interpreters, website templates, and so on): the point of having
such a format is to prepare the way for Inbuild to understand remote resources
somewhere on the Internet. For now JSON metadata files exist only for kits, but
some of the plumbing has been put in for general resources to have them.

This required new APIs in the foundation library at the Inweb repository to
read, write and validate JSON files: see the new section [JSON](https://ganelson.github.io/inweb/foundation-module/4-jsn.html).
You'll therefore need to pull the latest Inweb in order to build the latest Inform.

The current set of requirements for what Inbuild will read as resource metadata is
at [inform7/Internal/Miscellany/metadata.jsonr](inform7/Internal/Miscellany/metadata.jsonr).
There are also a few semantic constraints: see [JSON Metadata](https://ganelson.github.io/inform/supervisor-module/2-jm.html).

### Versioning policy for the built-in kits (4 June 2022)

There are currently five kits supplied in the Inform installation: 

	WorldModelKit
	EnglishLanguageKit
	CommandParserKit
	BasicInformKit
	BasicInformExtrasKit

Up to now these had no version numbers, but we want to encourage all kits to
have semantic version numbers, so we should comply with that ourselves.

In practice these kits are tightly coupled to the main compiler: (a) many bug fixes
in Inform which users think of as compiler fixes are in fact changes to these kits;
and (b) in normal circumstances people will never want to use the kits from one
build with the compiler from another. So the most useful way to describe the version
of a built-in kit is to identify which compiler release it came with.

As a policy decision, the version numbers of these five kits are therefore going
to be the same as those of the main compiler. (Today, that's "10.1.0-beta+6V21".)

This is enforced by changes to the makescript used when updating the main compiler's
version number, which uses a new feature of the Inpolicy tool:

	inpolicy/Tangled/inpolicy -sync-kit-versions

For its implementation, see: [Kit Versioning](https://ganelson.github.io/inform/inpolicy/2-kv.html).

User-written kits not included in the Inform installation should not do this.
They won't be tied to particular compiler releases, and should have their own
semantic version numbers reflecting their own history of development.

### Incorporation of "6M62 Patches" (31 May 2022)

In recent years Inform users have been keeping an extension called "6M62 Patches",
which contained a small selection of bug fixes to the template files of Inform 6
code in build 6M62 (i.e., Inform version 9.3). Those template files have now
become kits, the Inform 6 code has become Inter code, and changes to the way the
"Include..." sentence works mean that "6M62 Patches" is not compatible with v10.1.

It would be easy enough to fix that, but there is now no need: all bug fixes
in "6M62 Patches" have been adopted in the kits for v10.1. Any old project which
included "6M62 Patches" can now stop doing so.

It was a real public service to create and maintain "6M62 Patches", and we thank
everyone who contributed to it: their work lives on.
